local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"
local DynamicText = require "Utility.DynamicText"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPageSkillInfo = require "GUI.CPageSkillInfo"     
local CPageSkillRune = require "GUI.CPageSkillRune"     
local CPageWingSoul = require "GUI.CPageWingSoul"
local CPageSkillMastery = require "GUI.CPageSkillMastery"

local CPanelUISkill = Lplus.Extend(CPanelBase, "CPanelUISkill")
local def = CPanelUISkill.define
local CSkillUtil = require "Skill.CSkillUtil"

def.field(CFrameCurrency)._Frame_Money = nil 					-- 通用货币界面
def.field("userdata")._Frame_TopTabs = nil

-- 信息
def.field(CPageSkillInfo)._InfoPage = nil
def.field("userdata")._Tab_Skill_Toggle = nil
def.field("userdata")._Img_RedPoint_Info = nil

-- 符文
def.field(CPageSkillRune)._RunePage = nil
def.field("userdata")._Tab_Rune_Toggle = nil
def.field("userdata")._Img_RedPoint_Rune = nil

-- 专精
def.field(CPageSkillMastery)._MasteryPage = nil
def.field("userdata")._Tab_Mastery_Toggle = nil
def.field("userdata")._Img_RedPoint_Mastery = nil

-- 秘晶
def.field(CPageWingSoul)._SoulPage = nil
def.field("userdata")._Tab_Soul_Toggle = nil
def.field("userdata")._Img_RedPoint_Soul = nil

-- 页签
def.field("userdata")._Tab_Skill = nil
def.field("userdata")._Tab_Rune = nil

-- 挂点
def.field("userdata")._Frame_Skill = nil

def.field("number")._SelectedTab = 0							-- 0:初次打开;1:技能升级;2:纹章;3:专精;4:秘晶
def.field("number")._SelectedSkillIndex = 1						-- 当前选中技能

local ETabType =
{
	Skill = 1, 	-- 升级
	Rune = 2, 	-- 纹章
	Mastery = 3, 	-- 专精
	Soul = 4, 	-- 秘晶
}

local instance = nil
def.static("=>", CPanelUISkill).Instance = function ()
	if instance == nil then
		instance = CPanelUISkill()
		instance._PrefabPath = PATH.UI_Skill
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end
----------------------------------------------------------------------
-------------------------货币、事件监听-------------------------------
----------------------------------------------------------------------

local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local OnNotifyMoneyChangeEvent = function(sender, event)
    if instance ~= nil then
	 	if instance._SelectedTab == ETabType.Skill then
	 		instance._InfoPage:Update()
	 	elseif instance._SelectedTab == ETabType.Mastery then
	 		instance._MasteryPage:Update()
	 	end
    end
end

local PackageChangeEvent = require "Events.PackageChangeEvent"
local OnPackageChangeEvent = function(sender, event)
	if instance ~= nil then
		if instance._SelectedTab == ETabType.Rune then
	 		instance._RunePage:Update()
	 	elseif instance._SelectedTab == ETabType.Mastery then
	 		instance._MasteryPage:Update()
	 	end
	end
end

local SkillLevelUpEvent = require "Events.SkillLevelUpEvent"
local function OnSkillLevelUp(sender, event)
    if instance ~= nil then
		 if instance._SelectedTab == ETabType.Skill then
	 		instance._InfoPage:Update()
	 	end
	end
end

local GainNewSkillEvent = require "Events.GainNewSkillEvent"
local function OnGainNewSkill(sender, event)
	if instance ~= nil then
	    if instance._SelectedTab == ETabType.Skill then
	 		instance._InfoPage:OnLearnNewSkill(event.SkillId)
	 	end
	end
end

local NotifyRuneEvent = require "Events.NotifyRuneEvent"
local function OnNotifyRuneEvent(sender, event)
	if instance ~= nil then
		if event.Type == "Config" then
			if instance._SelectedTab == ETabType.Rune then
				instance._RunePage:OnChangeRuneConfig()
	 			instance._RunePage:Update()
	 		end
		end
	end
end
local NotifyPropEvent = require "Events.NotifyPropEvent"
local OnNotifyPropEvent = function(sender, event)
	if game._HostPlayer._ID ~= event.ObjID and event.ObjID ~= 0 then 
		return
	end
	if instance._SelectedTab == ETabType.Skill then
		instance._InfoPage:Update()
	elseif instance._SelectedTab == ETabType.Rune then
		instance._RunePage:Update()
	end
end
local HostPlayerLevelChangeEvent = require "Events.HostPlayerLevelChangeEvent"
local OnHostPlayerLevelChangeEvent = function(sender, event)
	if instance ~= nil and instance:IsShow() then
		if instance._SelectedTab == ETabType.Skill then
	 		instance._InfoPage:Update()
		elseif instance._SelectedTab == ETabType.Rune then
	 		instance._RunePage:Update()
	 	end
	end
end
local UseItemEvent = require "Events.UseItemEvent"
local function OnUseItemEvent(sender, event)
	--学习、升级纹章
	if sender.itemType == 5 then
		if sender.result then
			if instance ~= nil then
				if instance._SelectedTab == ETabType.Rune then
			 		instance._RunePage:OnUseItemEvent(sender.itemTid)
			 	end
			end
		end
	end
end

----------------------------------------------------------------------
-------------------------货币、事件监听-------------------------------
----------------------------------------------------------------------
-- 当创建
def.override().OnCreate = function(self)
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
	self._Frame_TopTabs = self:GetUIObject("Frame_TopTabs")
	self:GetUIObject("Frame_Center"):SetActive(true)
	self:GetUIObject("Frame_R"):SetActive(true)
	self:GetUIObject("Frame_L"):SetActive(true)

	self:InitMastery()
	self:InitSoul()

	self:InitUIObject()

	self:GetUIObject("Frame_RuneInfo"):SetActive(false)

	self:HideAllPages()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
	local toggle = ClassType.Toggle
	self._Tab_Skill = self:GetUIObject("Tab_Skill")
	self._Tab_Skill_Toggle = self._Tab_Skill:GetComponent(toggle)
	self._Tab_Rune = self:GetUIObject("Tab_Rune")
	self._Tab_Rune_Toggle = self._Tab_Rune:GetComponent(toggle)

	-- 添加技能界面背景
	self._Frame_Skill = self:GetUIObject("Frame_Skill")
	GameUtil.PlayUISfx(PATH.UIFX_Jinengjiemian_bg, self._Frame_Skill, self._Frame_Skill, -1)
end

def.method().InitMastery = function(self)
	local tabMastery = self:GetUIObject("Tab_Prof")
	self._Tab_Mastery_Toggle = tabMastery:GetComponent(ClassType.Toggle)
	self._Img_RedPoint_Mastery = tabMastery:FindChild("RedPoint")
end

def.method().InitSoul = function(self)
	local tab_soul = self:GetUIObject("Tab_Soul")
	self._Tab_Soul_Toggle = tab_soul:GetComponent(ClassType.Toggle)
	self._Img_RedPoint_Soul = tab_soul:FindChild("RedPoint")
end

def.method().HideAllPages = function(self)
	-- 隐藏Mastery节点
	self:GetUIObject("Frame_Prof"):SetActive(false)
    self:GetUIObject("Frame_ProfInfo"):SetActive(false)
    self:GetUIObject("Frame_ProfTip_Bg"):SetActive(false)
	
	-- 隐藏WingSoul节点
    self:GetUIObject("Frame_Soul_C"):SetActive(false)
    self:GetUIObject("Frame_Soul_L"):SetActive(false)
    self:GetUIObject("Frame_SoulInfo"):SetActive(false)
end

-- 当接收数据
def.override("dynamic").OnData = function(self, data)
	CPanelBase.OnData(self,data)
	--GameUtil.LayoutTopTabs(self._Frame_TopTabs)
	if data == nil or data._PageTag == "Tab_Skill" then
		self:OnTabSkill()
	elseif data._PageTag == "Tab_Prof" then
		self:OnTabMastery()
	elseif data._PageTag == "Tab_Rune" then
		local tid = tonumber(data._Tid) or -1
		self:OnTabRune( tid )
	elseif data._PageTag == "Tab_Soul" then
		self:OnTabSoul()
	else
		warn("Params error when open PanelSkill ", debug.traceback())
	end
	
	self:UpdateTabRedDotState()
	
    if self:IsShow() then
    	CGame.EventManager:addHandler(NotifyMoneyChangeEvent, OnNotifyMoneyChangeEvent)
    	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
        CGame.EventManager:addHandler(SkillLevelUpEvent, OnSkillLevelUp)
        CGame.EventManager:addHandler(GainNewSkillEvent, OnGainNewSkill)
        CGame.EventManager:addHandler(NotifyRuneEvent, OnNotifyRuneEvent)
        CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyPropEvent)
		CGame.EventManager:addHandler(UseItemEvent, OnUseItemEvent)
		CGame.EventManager:addHandler(HostPlayerLevelChangeEvent, OnHostPlayerLevelChangeEvent)
    end
end

-- Button点击
def.override("string").OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if self._Frame_Money:OnClick(id) then return end

	if id == "Btn_Back" then
		self:TryCloseSoul(function()
			game._GUIMan:CloseByScript(self)
		end)
    elseif id == 'Btn_Exit' then
		self:TryCloseSoul(function()
			game._GUIMan:CloseSubPanelLayer()
		end)
	else
		if self._SelectedTab == ETabType.Skill then
			self._InfoPage:OnClick(id)
		elseif self._SelectedTab == ETabType.Rune then
			self._RunePage:OnClick(id)
		elseif self._SelectedTab == ETabType.Soul then
			self._SoulPage:OnClick(id)
		elseif self._SelectedTab == ETabType.Mastery then
			self._MasteryPage:OnClick(id)
		end
	end
end
-- 页签切换
def.override("string", "boolean").OnToggle = function(self, id, checked)	
	if id == "Tab_Skill" then		
		self:TryCloseSoul(function()
			self:OnTabSkill()
		end)
	elseif id == "Tab_Rune" then
		self:TryCloseSoul(function()
			self:OnTabRune(-1)
		end)
	elseif id == "Tab_Prof" then	
		self:TryCloseSoul(function()
			self:OnTabMastery()
		end)
	elseif id == "Tab_Soul" then
		self:OnTabSoul()
	else
		if self._SelectedTab == ETabType.Soul then
			self._SoulPage:OnToggle(id, checked)
		elseif self._SelectedTab == ETabType.Mastery then
			self._MasteryPage:OnToggle(id, checked)
		end
	end
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	if self._RunePage ~= nil and self._SelectedTab == ETabType.Rune then
		self._RunePage:OnDOTComplete(go_name, dot_id)
	end
end

def.method().OnTabSkill = function(self)
	if self._SelectedTab == ETabType.Skill then
		return
	end

	self._Tab_Skill_Toggle.isOn = true

	if self._InfoPage == nil then
		self._InfoPage = CPageSkillInfo.new(self)
	end

	self._SelectedTab = ETabType.Skill
	self:ClearTabObj(ETabType.Skill)

	self._InfoPage:Show()
end

def.method("number").OnTabRune = function(self,tid)
	if self._SelectedTab == ETabType.Rune then
		return
	end

	self._Tab_Rune_Toggle.isOn = true

	if self._RunePage == nil then
		self._RunePage = CPageSkillRune.new(self)
	end

	self._SelectedTab = ETabType.Rune
	self:ClearTabObj(ETabType.Rune)

	self._RunePage:Show(tid)
end

def.method().OnTabMastery = function(self)
	if self._SelectedTab == ETabType.Mastery then
		return
	end

	if self._MasteryPage == nil then
		self._MasteryPage = CPageSkillMastery.new(self)
	end

	self._SelectedTab = ETabType.Mastery
	self:ClearTabObj(ETabType.Mastery)

	self._MasteryPage:Show()
end

def.method().OnTabSoul = function(self)
	if self._SelectedTab == ETabType.Soul then return end

	if self._SoulPage == nil then
		self._SoulPage = CPageWingSoul.new(self)
	end

	self._SelectedTab = ETabType.Soul
	self:ClearTabObj(ETabType.Soul)

	self._SoulPage:Show(nil)
end

def.method("number").ClearTabObj = function(self, tab_type)
	-- skill
	if self._InfoPage ~= nil and tab_type ~= ETabType.Skill then
		self._InfoPage:Hide()
	end
	self._Tab_Skill_Toggle.isOn = (tab_type == ETabType.Skill)

	-- rune
	if self._RunePage ~= nil and tab_type ~= ETabType.Rune then
		self._RunePage:Hide()
	end
	self._Tab_Rune_Toggle.isOn = (tab_type == ETabType.Rune)

	-- mastery
	if self._MasteryPage ~= nil and tab_type ~= ETabType.Mastery then
		self._MasteryPage:Hide()
	end
	self._Tab_Mastery_Toggle.isOn = (tab_type == ETabType.Mastery)
	
	-- soul
	if self._SoulPage ~= nil and tab_type ~= ETabType.Soul then
		self._SoulPage:Hide()
	end
	self._Tab_Soul_Toggle.isOn = (tab_type == ETabType.Soul)
end

def.method().UpdatePageSkillMastery = function(self)
	if self._SelectedTab ~= ETabType.Mastery then
		return
	end

	if self._MasteryPage ~= nil then
		self._MasteryPage:Update()
	end

	self:UpdateTabMasteryRedDotState()
end

def.method().UpdateTabMasteryRedDotState = function(self)
	self._Img_RedPoint_Mastery:SetActive(CSkillUtil.IsMasteryCanLvUp())
end

-- 红点提示
def.method().UpdateTabRedDotState = function(self)
	local userSkillMap = game._HostPlayer._UserSkillMap

	local red_dot_skill = self._Tab_Skill:FindChild("RedPoint")
	if not IsNil(red_dot_skill) then
		if CSkillUtil.IsSkillCanLvUp() then
			red_dot_skill:SetActive(true)
		else
			red_dot_skill:SetActive(false)
		end
	end

	local red_dot_rune = self._Tab_Rune:FindChild("RedPoint")
	if not IsNil(red_dot_rune) then	
		if CSkillUtil.IsRuneCanLvUp() then
			red_dot_rune:SetActive(true)
		else
			red_dot_rune:SetActive(false)
		end
	end

	self:UpdateTabMasteryRedDotState()
	self:UpdateTabSoulRedDotState()
end


--初始化List
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if self._SelectedTab == ETabType.Mastery then
		if self._MasteryPage ~= nil then
			self._MasteryPage:OnInitItem(item, id, index)
		end
	end
end

---------------------------------- 秘晶页签 start ------------------------------------
def.method().UpdateTabSoulRedDotState = function(self)
	self._Img_RedPoint_Soul:SetActive(CSkillUtil.IsSoulCanLvUp())
end

def.method("function").TryCloseSoul = function(self, callback)
	if self._SelectedTab == ETabType.Soul then
		self._SoulPage:TryHidePage(function(isSucceed)
			if isSucceed then
				if callback ~= nil then
					callback()
				end
			else
				-- 离开秘晶页签失败
				self._Tab_Soul_Toggle.isOn = true
			end
		end)
	else
		if callback ~= nil then
			callback()
		end
	end
end

def.method("number", "dynamic").UpdateSoulShow = function(self, updateType, param)
	if self._SelectedTab ~= ETabType.Soul then return end

	if updateType == 0 then
		-- 整体数据推送
		self._SoulPage:Show(nil)
	elseif updateType == 1 then
		-- 获得天赋点
		self._SoulPage:OnTalentGetPoint()
	elseif updateType == 2 then
		-- 选中天赋页
		self._SoulPage:OnWingTalentSelect(param)
	elseif updateType == 3 then
		-- 天赋点分配
		self._SoulPage:OnWingTalentPointChange()
	elseif updateType == 4 then
		-- 天赋页洗点
		self._SoulPage:OnWingTalentPointWash(param)
	end
	self:UpdateTabSoulRedDotState()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())
end
---------------------------------- 秘晶页签 end ------------------------------------

-- 当摧毁的时候
def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	if self._InfoPage ~= nil then
		self._InfoPage:Destroy()
		self._InfoPage = nil
	end
	if self._RunePage ~= nil then
		self._RunePage:Destroy()
		self._RunePage = nil
	end
	if self._MasteryPage ~= nil then
		self._MasteryPage:Destroy()
		self._MasteryPage = nil
	end
	if self._SoulPage ~= nil then
		self._SoulPage:Destroy()
		self._SoulPage = nil
	end
	CGame.EventManager:removeHandler(NotifyMoneyChangeEvent, OnNotifyMoneyChangeEvent)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
	CGame.EventManager:removeHandler(SkillLevelUpEvent, OnSkillLevelUp)
	CGame.EventManager:removeHandler(GainNewSkillEvent, OnGainNewSkill)
	CGame.EventManager:removeHandler(NotifyRuneEvent, OnNotifyRuneEvent)
	CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyPropEvent)
	CGame.EventManager:removeHandler(UseItemEvent, OnUseItemEvent)
	CGame.EventManager:removeHandler(HostPlayerLevelChangeEvent, OnHostPlayerLevelChangeEvent)
	instance = nil
end

CPanelUISkill.Commit()
return CPanelUISkill