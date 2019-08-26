local Lplus = require "Lplus"
local CPageGilliam = Lplus.Class("CPageGilliam")
local def = CPageGilliam.define

local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local EInstanceType = require "PB.Template".Instance.EInstanceType
local EInstanceDifficultyMode = require "PB.Template".Instance.EInstanceDifficultyMode

def.field("table")._Panel = nil
-- 数据
def.field("table")._GilliamInfo = BlankTable
def.field("number")._SelectedMode = -1 -- 选中的难度
-- 通用
def.field("table")._RewardsData = BlankTable

def.static("table", "=>", CPageGilliam).new = function(panel_script)
	local obj = CPageGilliam()
	obj._Panel = panel_script
	obj:Init()
	return obj
end

def.method().Init = function(self)
	local allTId = game._DungeonMan:GetAllDungeonInfo()
	for i,v in ipairs(allTId) do
		local template = CElementData.GetTemplate("Instance", v)
		if template.InstanceType == EInstanceType.INSTANCE_GILLIAM then
			-- 奇利恩类型
			local mode = template.InstanceDifficultyMode
			local info = 
			{
				Id = template.Id,
				RewardId = template.RewardId,
			}
			self._GilliamInfo[mode] = info
		end
	end
end

------------------------------以下方法不能删除--------------------------------
def.method("dynamic").Show = function(self, data)
	local desMode = -1
	if type(data) == "number" then
		desMode = data
	end
	local selectedMode = self._Panel:GetDifficultyMode(self._GilliamInfo, self._SelectedMode, desMode)
	self:ChooseMode(selectedMode)
end

def.method("string", "boolean").OnPanelToggle = function(self, id, checked)
	if id == "Rdo_Normal" and self._SelectedMode ~= EInstanceDifficultyMode.NORMAL then
		self:ChooseMode(EInstanceDifficultyMode.NORMAL)
	elseif id == "Rdo_Difficult" and self._SelectedMode ~= EInstanceDifficultyMode.DIFFICULT then
		self:ChooseMode(EInstanceDifficultyMode.DIFFICULT)
	elseif id == "Rdo_Nightmare" and self._SelectedMode ~= EInstanceDifficultyMode.NIGHTMARE then
		self:ChooseMode(EInstanceDifficultyMode.NIGHTMARE)
	elseif id == "Rdo_Hell" and self._SelectedMode ~= EInstanceDifficultyMode.HELL then
		self:ChooseMode(EInstanceDifficultyMode.HELL)
	elseif id == "Rdo_Purgatory" and self._SelectedMode ~= EInstanceDifficultyMode.PURGATORY then
		self:ChooseMode(EInstanceDifficultyMode.PURGATORY)
	end
end

def.method("string").OnPanelClick = function(self, id)
end

def.method("=>", "number").GetCurDungeonId = function (self)
	if self._GilliamInfo[self._SelectedMode] ~= nil then
		return self._GilliamInfo[self._SelectedMode].Id
	else
		return 0
	end
end

def.method("=>", "table").GetDungeonRewardData = function (self)
	return self._RewardsData
end

def.method("number").UpdateLockStatus = function (self, unlockTid)
	if unlockTid <= 0 then return end

	local template = CElementData.GetInstanceTemplate(unlockTid)
	if template == nil then return end

	if template.InstanceType ~= EInstanceType.INSTANCE_GILLIAM then return end

    self._Panel:PlayDiffcultyUnlockSfx(template.InstanceDifficultyMode)
    game._DungeonMan:SaveUIFxStatusToUserData(unlockTid, false)
end

def.method().Hide = function(self)
	self._RewardsData = {}
end

def.method().Destroy = function (self)
	self:Hide()
	self._GilliamInfo = {}
	self._SelectedMode = -1
end
----------------------------------------------------------------------------------
-- 选中难度
def.method("number").ChooseMode = function(self, selectedMode)
	self._SelectedMode = selectedMode
	local info = self._GilliamInfo[selectedMode]
	if info ~= nil then
		self._Panel:ShowDungeonInfo(info.Id)
		if info.RewardId > 0 then
			local rewardList = GUITools.GetRewardList(info.RewardId, true)
			local moneyRewardList = {}
			self._RewardsData = {}
			for _, v in ipairs(rewardList) do
				if v.IsTokenMoney then
					table.insert(moneyRewardList, v.Data)
				else
					table.insert(self._RewardsData, v)
				end
			end
			self._Panel:SetMoneyRewards(moneyRewardList) -- 设置货币奖励
			self._Panel:SetRewardsList(self._RewardsData) -- 设置物品列表奖励
		end
	end
end

CPageGilliam.Commit()
return CPageGilliam