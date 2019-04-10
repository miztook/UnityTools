local Lplus = require "Lplus"
local CPageTowerDungeon = Lplus.Class("CPageTowerDungeon")
local def = CPageTowerDungeon.define

local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType

def.field("table")._Panel = nil
def.field("boolean")._PageInited = false -- 面板是否已初始化
-- 界面
def.field("userdata")._Lab_PassTime = nil
def.field("userdata")._Lab_PassFloor = nil

def.field("table")._MoneyRewardsData = BlankTable
def.field("table")._RewardsData = BlankTable
def.field("number")._DungeonTId = 0

def.static("table", "=>", CPageTowerDungeon).new = function(panel_script)
	local obj = CPageTowerDungeon()
	obj._Panel = panel_script
	return obj
end

def.method().Init = function (self)
	self._Lab_PassTime = self._Panel:GetUIObject("Lab_PassTimeVal")
	self._Lab_PassFloor = self._Panel:GetUIObject("Lab_PassFloorVal")

	local btn_rank = self._Panel:GetUIObject("Btn_Rank")
	GUITools.SetUIActive(btn_rank, true)
	local btn_shop = self._Panel:GetUIObject("Btn_Shop")
	GUITools.SetUIActive(btn_shop, false)

	local CSpecialIdMan = require "Data.CSpecialIdMan"
	self._DungeonTId = CSpecialIdMan.Get("TowerDungeonID")
	local instanceTemp = CElementData.GetInstanceTemplate(self._DungeonTId)
	if instanceTemp ~= nil then
		if instanceTemp.RewardId <= 0 then
			warn("Reward template get nil on page TowerDungeon, wrong tid:" .. instanceTemp.RewardId)
		else
			local rewardList = GUITools.GetRewardList(instanceTemp.RewardId, true)
			for _, v in ipairs(rewardList) do
				if v.IsTokenMoney then
					table.insert(self._MoneyRewardsData, v.Data)
				else
					table.insert(self._RewardsData, v)
				end
			end
		end
	end
end

def.method("dynamic").Show = function(self,Data)
	if not self._PageInited then
        -- 第一次打开，初始化
		self:Init()
		self._PageInited = true
	end
	self._Panel:ShowDungeonInfo(self._DungeonTId)
	self._Panel:SetMoneyRewards(self._MoneyRewardsData) -- 设置货币奖励
	self._Panel:SetRewardsList(self._RewardsData) -- 设置物品列表奖励

	--时间,层数
	local nTime, nFloor = game._DungeonMan:GetTowerDungeonData()
	-- local maxFloor = CSpecialIdMan.Get("MaxTowerDungeonFloor")
	GUI.SetText(self._Lab_PassFloor, tostring(nFloor))
	GUI.SetText(self._Lab_PassTime, GUITools.FormatTimeSpanFromSeconds(nTime))
end

def.method("string").OnPanelClick = function (self, id)
	if string.find(id, "Btn_Rank") then
		-- 打开排行榜
		game._GUIMan:Open("CPanelRanking", 13)
	elseif string.find(id, "Btn_Shop") then
		-- 打开商店
		local data =
		{
			OpenType = 1,
			ShopId = ENpcSaleServiceType.NpcSale_Rune
		}
		game._GUIMan:Open("CPanelNpcShop", data)
	end
end

def.method("=>", "number").GetCurDungeonId = function (self)
	return self._DungeonTId
end

def.method("=>", "table").GetDungeonRewardData = function (self)
	return self._RewardsData
end

def.method("number").UpdateLockStatus = function (self, unlockTid)
end

def.method().Hide = function(self)
end

def.method().Destroy = function (self)
	self:Hide()
	self._Panel = nil
	self._PageInited = false

	self._Lab_PassTime = nil
	self._Lab_PassFloor = nil
end

CPageTowerDungeon.Commit()
return CPageTowerDungeon