--
-- 公会技能升级
--
--【孟令康】
--
-- 2018年04月12日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local GuildBuildingType = require "PB.data".GuildBuildingType
local CElementSkill = require "Data.CElementSkill"
local CCommonBtn = require "GUI.CCommonBtn"

local CPanelUIGuildSkillLvUp = Lplus.Extend(CPanelBase, "CPanelUIGuildSkillLvUp")
local def = CPanelUIGuildSkillLvUp.define

def.field("table")._Data = nil
def.field("table")._Building_Info = nil

def.field("userdata")._Lab_Title = nil
def.field("userdata")._Skill_Icon = nil
def.field("userdata")._Lab_Level_2 = nil
def.field("userdata")._Frame_Learn = nil
def.field("userdata")._Lab_Des = nil
def.field("userdata")._Lab_Effect0 = nil
def.field("userdata")._Frame_Level = nil
def.field("userdata")._Lab_Effect_Now = nil
def.field("userdata")._Lab_Effect_Next = nil
def.field("userdata")._Frame_Active = nil
def.field("userdata")._Lab_Effect1 = nil
--def.field("userdata")._Icon_Money0 = nil
--def.field("userdata")._Lab_Money0 = nil
--def.field("userdata")._Icon_Money1 = nil
--def.field("userdata")._Lab_Money1 = nil
--def.field("userdata")._Icon_Money2 = nil
--def.field("userdata")._Lab_Money2 = nil
def.field(CCommonBtn)._Btn_Learn = nil
def.field(CCommonBtn)._Btn_Level = nil
def.field(CCommonBtn)._Btn_Active = nil
--def.field("userdata")._Btn_Learn = nil
--def.field("userdata")._Btn_Level = nil
--def.field("userdata")._Btn_Active = nil

local instance = nil
def.static("=>", CPanelUIGuildSkillLvUp).Instance = function()
	if not instance then
		instance = CPanelUIGuildSkillLvUp()
		instance._PrefabPath = PATH.UI_Guild_Skill_LvUp
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local OnNotifyGuildEvent = function(sender, event)
	if not IsNil(instance._Panel) then
		if event.Type == "SkillLevelUp" then
			game._GUIMan:Close("CPanelUIGuildSkillLvUp")
		elseif event.Type == "BuffOpen" then
			game._GUIMan:Close("CPanelUIGuildSkillLvUp")
		elseif event.Type == "BuffSet" then
			game._GUIMan:Close("CPanelUIGuildSkillLvUp")
		end
	end
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInit()
	self:OnInitUIObject()
	CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Data = data
	local template = data._Data
	GUI.SetText(self._Lab_Title, template.Name)
	local talentId = 0
	if data._Type == "Active" then
		talentId = template.BuffId
	else
		talentId = template.SkillId
	end
	local talent = CElementData.GetTemplate("Talent", talentId)
	GUITools.SetSkillIcon(self._Skill_Icon, talent.Icon)
	GUI.SetText(self._Lab_Level_2, tostring(data._Level))
	local moneyValue = game._GuildMan:GetMoneyValueByTid(template.MoneyType)
    local btn_1 = self:GetUIObject("Btn_Learn")
    local btn_2 = self:GetUIObject("Btn_Level")
    local btn_3 = self:GetUIObject("Btn_Active")
	if data._Type == "Learn" then
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = template.MoneyType,
            [EnumDef.CommonBtnParam.MoneyCost] = template.SkillLevelUps[1].CostMoney   
        }
        self._Btn_Learn = CCommonBtn.new(btn_1, setting)
		self._Frame_Learn:SetActive(true)
		self._Frame_Level:SetActive(false)
		self._Frame_Active:SetActive(false)
		btn_1:SetActive(true)
		btn_2:SetActive(false)
		btn_3:SetActive(false)

		local value = CElementSkill.GetSkillLevelUpValue(talentId, 1, 1, true)
		GUI.SetText(self._Lab_Effect0, template.Description .. "+" .. value )

	elseif data._Type == "Level" then
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = template.MoneyType,
            [EnumDef.CommonBtnParam.MoneyCost] = template.SkillLevelUps[data._Level + 1].CostMoney
        }
        self._Btn_Level = CCommonBtn.new(btn_2, setting)
		self._Frame_Learn:SetActive(false)
		self._Frame_Level:SetActive(true)
		self._Frame_Active:SetActive(false)
		btn_1:SetActive(false)
		btn_2:SetActive(true)
		btn_3:SetActive(false)

		local nowValue = CElementSkill.GetSkillLevelUpValue(talentId, 1, data._Level, true)
		GUI.SetText(self._Lab_Effect_Now, template.Description .. "+" .. nowValue)
		local nextValue = CElementSkill.GetSkillLevelUpValue(talentId, 1, data._Level + 1, true)
		GUI.SetText(self._Lab_Effect_Next, template.Description .. "+" .. nextValue)	
	elseif data._Type == "Active" then
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = template.MoneyType,
            [EnumDef.CommonBtnParam.MoneyCost] = template.BuffLevelUps[data._Level].CostMoney
        }
        self._Btn_Active = CCommonBtn.new(btn_3, setting)
		self._Frame_Learn:SetActive(false)
		self._Frame_Level:SetActive(false)
		self._Frame_Active:SetActive(true)
		btn_1:SetActive(false)
		btn_2:SetActive(false)
		btn_3:SetActive(true)

		local value = CElementSkill.GetSkillLevelUpValue(talentId, 1, data._Level, true)
		GUI.SetText(self._Lab_Effect1, template.Description .. "+" .. value)
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    if self._Btn_Learn ~= nil then
        self._Btn_Learn:Destroy()
        self._Btn_Learn = nil
    end
    if self._Btn_Level ~= nil then
        self._Btn_Level:Destroy()
        self._Btn_Level = nil
    end
    if self._Btn_Active ~= nil then
        self._Btn_Active:Destroy()
        self._Btn_Active = nil
    end
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Learn" then
		self:OnBtnLearn()
	elseif id == "Btn_Level" then
		self:OnBtnLevel()
	elseif id == "Btn_Active" then
		self:OnBtnActive()
	end
end

-- 初始化模板信息等
def.method().OnInit = function(self)
	self._Building_Info = game._HostPlayer._Guild._BuildingList[GuildBuildingType.Laboratory]
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._Lab_Title = self:GetUIObject("Lab_Title")
	self._Skill_Icon = self:GetUIObject("Skill_Icon")
	self._Lab_Level_2 = self:GetUIObject("Lab_Level_2")
	self._Frame_Learn = self:GetUIObject("Frame_Learn")
	self._Lab_Des = self:GetUIObject("Lab_Des")
	self._Lab_Effect0 = self:GetUIObject("Lab_Effect0")
	self._Frame_Level = self:GetUIObject("Frame_Level")
	self._Lab_Effect_Now = self:GetUIObject("Lab_Effect_Now")
	self._Lab_Effect_Next = self:GetUIObject("Lab_Effect_Next")
	self._Frame_Active = self:GetUIObject("Frame_Active")
	self._Lab_Effect1 = self:GetUIObject("Lab_Effect1")
--	self._Icon_Money0 = self:GetUIObject("Icon_Money0")
--	self._Lab_Money0 = self:GetUIObject("Lab_Money0")
--	self._Icon_Money1 = self:GetUIObject("Icon_Money1")
--	self._Lab_Money1 = self:GetUIObject("Lab_Money1")
--	self._Icon_Money2 = self:GetUIObject("Icon_Money2")
--	self._Lab_Money2 = self:GetUIObject("Lab_Money2")
end

def.method().OnBtnLearn = function(self)
	local data = self._Data
	local moneyValue = game._HostPlayer._InfoData._RoleResources[data._Data.MoneyType]
	if moneyValue < data._Data.SkillLevelUps[data._Level + 1].CostMoney then
		local money = CElementData.GetTemplate("Money", data._Data.MoneyType)
		game._GUIMan:ShowTipText(string.format(StringTable.Get(893), money.TextDisplayName), true)
	elseif self._Building_Info._BuildingLevel < data._Data.SkillLevelUps[data._Level + 1].BuildLevel then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(851), StringTable.Get(843)), true)
	else
		self:OnC2SGuildSkillLevelUp(data._Data.SkillId)
	end
end

def.method().OnBtnLevel = function(self)
	local data = self._Data
	local moneyValue = game._HostPlayer._InfoData._RoleResources[data._Data.MoneyType]
	if moneyValue < data._Data.SkillLevelUps[data._Level + 1].CostMoney then
		local money = CElementData.GetTemplate("Money", data._Data.MoneyType)
		game._GUIMan:ShowTipText(string.format(StringTable.Get(893), money.TextDisplayName), true)
	elseif self._Building_Info._BuildingLevel < data._Data.SkillLevelUps[data._Level + 1].BuildLevel then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(851), StringTable.Get(843)), true)
	else
		self:OnC2SGuildSkillLevelUp(data._Data.SkillId)
	end
end

def.method().OnBtnActive = function(self)
	local data = self._Data
	if game._HostPlayer._Guild._Fund < data._Data.BuffLevelUps[data._Level].CostMoney then
		game._GUIMan:ShowTipText(StringTable.Get(844), true)
	else
		if game._HostPlayer:IsInGlobalZone() then
	        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
	        return
	    end
		self:OnC2SGuildBuffOpen(data._Data.BuffId)
	end
end

-- 公会技能升级（个人）
def.method("number").OnC2SGuildSkillLevelUp = function(self, skillId)
	local protocol = (require "PB.net".C2SGuildSkillLevelUp)()
	protocol.SkillID = skillId
	PBHelper.Send(protocol)
end

-- 公会Buff开启
def.method("number").OnC2SGuildBuffOpen = function(self, skillId)
	local protocol = (require "PB.net".C2SGuildBuffOpen)()
	protocol.SkillID = skillId
	PBHelper.Send(protocol)
end

CPanelUIGuildSkillLvUp.Commit()
return CPanelUIGuildSkillLvUp