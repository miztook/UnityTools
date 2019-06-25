--
-- 公会技能
--
--【孟令康】
--
-- 2017年12月27日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local GuildBuildingType = require "PB.data".GuildBuildingType
local DynamicText = require "Utility.DynamicText"
local ChatManager = require "Chat.ChatManager"
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPanelUIGuildSkill = Lplus.Extend(CPanelBase, "CPanelUIGuildSkill")
local def = CPanelUIGuildSkill.define

def.field("number")._List_Type = ClassType.GNewListLoop

-- 个人贡献
def.field("number")._Contribute_Tid = 6
-- 公会资金
def.field("number")._Fund_Tid = 10

-- 当前选中技能
def.field("table")._Cur_Skill = nil
-- 当前选中BUFF
def.field("table")._Cur_Buff = nil
def.field("table")._Skill_Data = nil
def.field("table")._Buff_Data = nil
-- 是否是选择的常规技能
def.field("boolean")._Is_Skill = true
-- 是否是会长
def.field("boolean")._Is_Leader = false
def.field("table")._Building_Info = nil

def.field(CFrameCurrency)._Frame_Money = nil
--[[def.field("userdata")._Img_Diamond = nil
def.field("userdata")._Lab_Diamond = nil
def.field("userdata")._Img_Diamond_Lock = nil
def.field("userdata")._Lab_Diamond_Lock = nil]]
def.field("userdata")._Skill_List = nil
def.field("userdata")._Buff_List = nil
def.field("userdata")._Buff_ListGO = nil

local instance = nil
def.static("=>", CPanelUIGuildSkill).Instance = function()
	if not instance then
		instance = CPanelUIGuildSkill()
		instance._PrefabPath = PATH.UI_Guild_Skill
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local OnNotifyGuildEvent = function(sender, event)
	if not IsNil(instance._Panel) then
		if event.Type == "SkillLevelUp" then
			instance:OnUpdateGuildSkill(sender)
            instance:ShowGuildSkillUIFX(event.Param)
		elseif event.Type == "BuffOpen" then
			instance:OnUpdateGuildBuff(sender)
            
		elseif event.Type == "BuffSet" then
			instance:OnUpdateGuildBuffSet(sender)
		end
	end
end

-- 当创建
def.override().OnCreate = function(self)
    game._GuildMan:SendC2SGuildSkillInfo()
	self:OnInitUIObject()
	self:OnInit()
	CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._HelpUrlType = HelpPageUrlType.Guild_Skill
end

-- 当摧毁
def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if self._Frame_Money:OnClick(id) then return end
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
    	TODO(StringTable.Get(19))
    elseif id == "Btn_Diamond" then
		TODO(StringTable.Get(19))
	elseif id == "Btn_Diamond_Lock" then
		TODO(StringTable.Get(19))
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	if id == "Skill_List" then
		self:OnSetSingleSkill(item, index)
	elseif id == "Buff_List" then
		self:OnSetSingleBuff(item, index)
	end
end

--[[ 展示货币
def.method().OnShowMoney = function(self)
	GUITools.SetTokenMoneyIcon(self._Img_Diamond, self._Contribute_Tid)
	GUI.SetText(self._Lab_Diamond, tostring(game._GuildMan:GetMoneyValueByTid(self._Contribute_Tid)))
	GUITools.SetTokenMoneyIcon(self._Img_Diamond_Lock, self._Fund_Tid)
	GUI.SetText(self._Lab_Diamond_Lock, tostring(game._GuildMan:GetMoneyValueByTid(self._Fund_Tid)))
end]]

-- 展示单个技能
def.method("userdata", "number").OnSetSingleSkill = function(self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	local data = self._Skill_Data[index]
	local guildSkill = data._Data
	local talent = CElementData.GetTemplate("Talent", guildSkill.SkillId)
	local buildingName = self._Building_Info._BuildingName
	local skillLevel = data._Level
	if skillLevel == 0 then
		skillLevel = 1
	end
	local buildingLevel = guildSkill.SkillLevelUps[skillLevel].BuildLevel
	GUITools.SetSkillIcon(uiTemplate:GetControl(1), talent.Icon)
	GameUtil.MakeImageGray(uiTemplate:GetControl(1), not data._IsOwn)
	uiTemplate:GetControl(2):SetActive(not data._IsOwn)
	uiTemplate:GetControl(5):SetActive(data._IsOwn)
	GUI.SetText(uiTemplate:GetControl(6), guildSkill.Name)
	local needLearn = data._Level == 0	
	uiTemplate:GetControl(7):SetActive(not needLearn)
	GUI.SetText(uiTemplate:GetControl(8), tostring(data._Level))
	uiTemplate:GetControl(9):SetActive(data._Level == 0)
	local value = DynamicText.GetSkillLevelUpValue(guildSkill.SkillId, 1, data._Level, true)
	GUI.SetText(uiTemplate:GetControl(11), guildSkill.Description .. "+" .. value)
	uiTemplate:GetControl(12):SetActive((not needLearn) and (not data._IsMax))
	uiTemplate:GetControl(15):SetActive(needLearn)
	uiTemplate:GetControl(18):SetActive(not data._IsOwn)
	GUI.SetText(uiTemplate:GetControl(18), string.format(StringTable.Get(8012), buildingName, buildingLevel))
end

-- 展示单个Buff
def.method("userdata", "number").OnSetSingleBuff = function(self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	local data = self._Buff_Data[index]
	local guildBuff = data._Data
	local talent = CElementData.GetTemplate("Talent", guildBuff.BuffId)
	local isActive = data._Time > 0
	uiTemplate:GetControl(0):SetActive(not isActive)
	uiTemplate:GetControl(1):SetActive(isActive)
	uiTemplate:GetControl(2):SetActive(data._Auto_Flag)
    self:ShowGuildBuffUIFX(uiTemplate:GetControl(7), isActive)
	uiTemplate:GetControl(3):SetActive(not isActive)
	uiTemplate:GetControl(4):SetActive(isActive)
	uiTemplate:GetControl(10):SetActive(isActive)
	local isLeader = self._Is_Leader
	uiTemplate:GetControl(14):SetActive(not isActive and isLeader)
	uiTemplate:GetControl(18):SetActive(isActive and data._Auto_Flag and isLeader)
	uiTemplate:GetControl(23):SetActive(isActive and not data._Auto_Flag and isLeader)
	GUITools.SetSkillIcon(uiTemplate:GetControl(7), talent.Icon)
	GUI.SetText(uiTemplate:GetControl(9), guildBuff.Name)
	GUI.SetText(uiTemplate:GetControl(12), tostring(data._Level))
	local value = DynamicText.GetSkillLevelUpValue(guildBuff.BuffId, 1, data._Level, true)
	GUI.SetText(uiTemplate:GetControl(13), guildBuff.Description .. "+" .. value)
end

-- 选中列表
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	index = index + 1
	if id == "Skill_List" then
		if id_btn == "Btn_Learn" then
			local data = self._Skill_Data[index]
			data._Type = "Learn"
			game._GUIMan:Open("CPanelUIGuildSkillLvUp", data)
		elseif id_btn == "Btn_Upgrade" then
			local data = self._Skill_Data[index]
			data._Type = "Level"
			game._GUIMan:Open("CPanelUIGuildSkillLvUp", data)
		end
	elseif id == "Buff_List" then
		if id_btn == "Btn_Active" then
			local data = self._Buff_Data[index]
			data._Type = "Active"
			game._GUIMan:Open("CPanelUIGuildSkillLvUp", data)
		elseif id_btn == "Btn_Auto_Yes" then
			self:OnBtnCheckAuto(index)
		elseif id_btn == "Btn_Auto_No" then
			self:OnBtnCheckAuto(index)		
		end
	end
end

-- 初始化模板信息等
def.method().OnInit = function(self)
	local allSkill = GameUtil.GetAllTid("GuildSkill")
	self._Building_Info = game._HostPlayer._Guild._BuildingList[GuildBuildingType.Laboratory]
	self._Skill_Data = {}
	local buildingLevel = self._Building_Info._BuildingLevel
	for i = 1, #allSkill do
		self._Skill_Data[i] = {}
		local guildSkill = CElementData.GetTemplate("GuildSkill", allSkill[i])
		self._Skill_Data[i]._Data = guildSkill
		self._Skill_Data[i]._Level = 0	
		if guildSkill.SkillLevelUps[1].BuildLevel > buildingLevel then
			self._Skill_Data[i]._IsOwn = false
		else
			self._Skill_Data[i]._IsOwn = true
		end
		self._Skill_Data[i]._CanLearn = true
		self._Skill_Data[i]._IsMax = false
	end
	local allBuff = GameUtil.GetAllTid("GuildBuff")
	self._Buff_Data = {}
	for i = 1, #allBuff do
		self._Buff_Data[i] = {}
		self._Buff_Data[i]._Data = CElementData.GetTemplate("GuildBuff", allBuff[i])
		self._Buff_Data[i]._Level = 1
		self._Buff_Data[i]._IsOwn = false		
		self._Buff_Data[i]._Time = 0
		self._Buff_Data[i]._Auto_Flag = false
	end

	local data = game._HostPlayer._Guild._GuildSkill
	local buildingLevel = self._Building_Info._BuildingLevel
	for i = 1, #data._SkillData do
		for j = 1, #self._Skill_Data do	
			if data._SkillData[i].SkillId == self._Skill_Data[j]._Data.SkillId then
				self._Skill_Data[j]._Level = data._SkillData[i].SkillLevel
				local nextLevel = self._Skill_Data[j]._Level + 1
				if self._Skill_Data[j]._Data.SkillLevelUps[nextLevel] == nil then
					self._Skill_Data[j]._IsMax = true
				else
					self._Skill_Data[j]._CanLearn = buildingLevel >= self._Skill_Data[j]._Data.SkillLevelUps[nextLevel].BuildLevel					
				end
			end
		end
	end
	for i = 1, #data._BuffData do
		for j = 1, #self._Buff_Data do
			if data._BuffData[i].BuffId == self._Buff_Data[j]._Data.BuffId then
				self._Buff_Data[j]._Level = data._BuffData[i].BuffLevel
				self._Buff_Data[j]._IsOwn = true
				self._Buff_Data[j]._Auto_Flag = data._BuffData[i].AutoFlag
				self._Buff_Data[j]._Time = data._BuffData[i].DueTime
			end
		end
	end
	self._Skill_List:SetItemCount(#self._Skill_Data)
	self._Buff_List:SetItemCount(#self._Buff_Data)
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.GuildSkill)
	--[[self._Img_Diamond = self:GetUIObject("Img_Diamond")
	self._Lab_Diamond = self:GetUIObject("Lab_Diamond")
	self._Img_Diamond_Lock = self:GetUIObject("Img_Diamond_Lock")
	self._Lab_Diamond_Lock = self:GetUIObject("Lab_Diamond_Lock")]]
    self._Buff_ListGO = self:GetUIObject("Buff_List")
	self._Skill_List = self:GetUIObject("Skill_List"):GetComponent(self._List_Type)
	self._Buff_List = self:GetUIObject("Buff_List"):GetComponent(self._List_Type)

	local member = game._GuildMan:GetHostGuildMemberInfo()
	self._Is_Leader = (member ~= nil and member._RoleType == GuildMemberType.GuildLeader)

	--self:OnShowMoney()
end

def.method("number").ShowGuildSkillUIFX = function(self, skillID)
    local index = 0
    for i,v in ipairs(self._Skill_Data) do
        if v._Data.SkillId == skillID then
            index = i
        end
    end
    local item = self._Skill_List:GetItem(index > 0 and index - 1 or index)
    if item ~= nil then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local img_bg = uiTemplate:GetControl(1)
        GameUtil.PlayUISfx(PATH.UIFX_GuildSkillLevelUp, img_bg, img_bg, 3)
    end
end

-- 刷新技能信息
def.method("table").OnUpdateGuildSkill = function(self, data)
	local buildingLevel = self._Building_Info._BuildingLevel
	for i, v in ipairs(self._Skill_Data) do
		if v._Data.SkillId == data.SkillId then
			v._Level = data.SkillLevel
			local nextLevel = v._Level + 1
			if v._Data.SkillLevelUps[nextLevel] == nil then
				v._IsMax = true
			else
				v._CanLearn = buildingLevel >= v._Data.SkillLevelUps[nextLevel].BuildLevel
			end
			local msg = string.format(StringTable.Get(8105), v._Data.Name, data.SkillLevel)
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
		end
	end
	self._Skill_List:SetItemCount(#self._Skill_Data)
end

def.method("userdata", "boolean").ShowGuildBuffUIFX = function(self, img_bg, isShow)
    if isShow then
        GameUtil.StopUISfx(PATH.UIFX_GuildSkillBuffOn, img_bg)
        GameUtil.PlayUISfxClipped(PATH.UIFX_GuildSkillBuffOn, img_bg, img_bg, self._Buff_ListGO)
    else
        GameUtil.StopUISfx(PATH.UIFX_GuildSkillBuffOn, img_bg)
    end
end

-- 刷新Buff信息
def.method("table").OnUpdateGuildBuff = function(self, data)
	for i, v in ipairs(self._Buff_Data) do
		if v._Data.BuffId == data.BuffId then
			v._IsOwn = true
			v._Time = data.DueTime
		end
	end
	self._Buff_List:SetItemCount(#self._Buff_Data)
end

-- 刷新Buff设置
def.method("table").OnUpdateGuildBuffSet = function(self, data)
	for i, v in ipairs(self._Buff_Data) do
		if v._Data.BuffId == data.SkillID then
			v._Auto_Flag = data.AutoFlag
		end
	end
	self._Buff_List:SetItemCount(#self._Buff_Data)
end

-- 点击公会Buff设置
def.method("number").OnBtnCheckAuto = function(self, index)
	local data = self._Buff_Data[index]
	if game._HostPlayer._Guild._Fund < data._Data.BuffLevelUps[data._Level].CostMoney and not data._Auto_Flag then
		game._GUIMan:ShowTipText(StringTable.Get(844), true)
	elseif data._Time <= 0 then
		game._GUIMan:ShowTipText(StringTable.Get(850), true)
	else
		local autoFlag = not data._Auto_Flag
		local buffId = data._Data.BuffId
		self:OnC2SGuildBuffSet(autoFlag, buffId)
	end
end

-- 公会Buff设置
def.method("boolean", "number").OnC2SGuildBuffSet = function(self, autoFlag, skillId)
	local protocol = (require "PB.net".C2SGuildBuffSet)()
	protocol.AutoFlag = autoFlag
	protocol.SkillID = skillId
	PBHelper.Send(protocol)
end

CPanelUIGuildSkill.Commit()
return CPanelUIGuildSkill