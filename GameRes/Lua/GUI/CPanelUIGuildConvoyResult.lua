--
--公会护送结束界面
--
--【孟令康】
--
--2018年04月26日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUIGuildConvoyResult = Lplus.Extend(CPanelBase, "CPanelUIGuildConvoyResult")
local def = CPanelUIGuildConvoyResult.define

def.field("table")._RewardData = nil

def.field("table")._Guild_Icon_Image = nil
def.field("userdata")._Guild_Level_Num = nil
def.field("userdata")._Guild_Name = nil
def.field("userdata")._Lab_Guild_Num = nil
def.field("userdata")._Lab_Rank_Num = nil
def.field("userdata")._Bar_Hp = nil
def.field("userdata")._Lab_Hp_Num = nil
def.field("userdata")._Lab_Progress_Num = nil
def.field("userdata")._RewardList = nil

local instance = nil
def.static("=>", CPanelUIGuildConvoyResult).Instance = function()
	if not instance then
		instance = CPanelUIGuildConvoyResult()
		instance._PrefabPath = PATH.UI_Guild_Convoy_Result
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitObject()
	self:OnInit()
end

def.method("table").ShowDamage = function(self, damageDatas)
	local data = {}
	local damageData = damageDatas
	local totalHp = 0
	for i, v in ipairs(damageData) do
		totalHp = totalHp + v.Damage
	end
	data._TotalHP = totalHp
	data._Info = damageData
	game._GUIMan:Open("CPanelUIDamage", data)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	GUI.SetText(self._Lab_Rank_Num, string.format(StringTable.Get(20071), data.Rank))
	if data.IsAttacker then
		GUI.SetText(self._Guild_Name, StringTable.Get(8082))
	else
		GUI.SetText(self._Guild_Name, StringTable.Get(8081))		
	end
	self._RewardData = GUITools.GetRewardList(data.RewardId, false)
	self._RewardList:SetItemCount(#self._RewardData)
	GUI.SetText(self._Lab_Hp_Num, math.ceil(data.HpPercent * 100) .. "%")
	self._Bar_Hp.size = data.HpPercent
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Continue" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Rank" then
		self:OnBtnRank()
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "RewardList" then
    	index = index + 1
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local data = self._RewardData[index]
        if data.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(item, data.Data.Id, data.Data.Count)
        else
            local setting = {
                [EItemIconTag.Bind] = (data.BindType == 2),
                [EItemIconTag.Number] = data.Data.Count,
            }
            IconTools.InitItemIconNew(item, data.Data.Id, setting, EItemLimitCheck.AllCheck)
        end
    end
end

-- 选中列表按钮
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "RewardList" then
    	index = index + 1
		local itemTid = self._RewardData[index].Data.Id
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
    end
end

def.method().OnInitObject = function(self)
	self._Guild_Icon_Image = {}
	self._Guild_Icon_Image[1] = self:GetUIObject("Img_Flag_Bg")
	self._Guild_Icon_Image[2] = self:GetUIObject("Img_Flag_Flower_1")
	self._Guild_Icon_Image[3] = self:GetUIObject("Img_Flag_Flower_2")
	self._Guild_Level_Num = self:GetUIObject("Guild_Level_Num")
	self._Guild_Name = self:GetUIObject("Guild_Name")
	self._Lab_Guild_Num = self:GetUIObject("Lab_Guild_Num")
	self._Lab_Rank_Num = self:GetUIObject("Lab_Rank_Num")
	self._Bar_Hp = self:GetUIObject("Bar_Hp"):GetComponent(ClassType.Scrollbar)
	self._Lab_Hp_Num = self:GetUIObject("Lab_Hp_Num")
	self._Lab_Progress_Num = self:GetUIObject("Lab_Progress_Num")
	self._RewardList = self:GetUIObject("RewardList"):GetComponent(ClassType.GNewList)
end

def.method().OnInit = function(self)
	game._GuildMan:SetGuildUseIcon(self._Guild_Icon_Image)
	GUI.SetText(self._Lab_Guild_Num, game._HostPlayer._Guild._GuildName)
	GUI.SetText(self._Guild_Level_Num, tostring(game._HostPlayer._Guild._GuildLevel))
end

def.method().OnBtnRank = function(self)
	self:OnC2SGuildConvoyRankInfo()
end

-- 查看伤害排名
def.method().OnC2SGuildConvoyRankInfo = function(self)
	local protocol = (require "PB.net".C2SGuildConvoyRankInfo)()
	PBHelper.Send(protocol)
end

CPanelUIGuildConvoyResult.Commit()
return CPanelUIGuildConvoyResult