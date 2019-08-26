local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"
local SkillEnergyType = require "PB.Template".Skill.SkillEnergyType
local SkillCategory = require "PB.Template".Skill.SkillCategory
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CHUDShortcutComp = require "GUI.Component.CHUDShortcutComp"
local CHUDSkillChargeComp = require "GUI.Component.CHUDSkillChargeComp"
local CHUDDrugUseComp = require "GUI.Component.CHUDDrugUseComp"
local CHUDHawkEyeComp = require "GUI.Component.CHUDHawkEyeComp"

local CPanelSkillSlot = Lplus.Extend(CPanelBase, "CPanelSkillSlot")
local def = CPanelSkillSlot.define

def.field("table")._SkillSlotInfo = BlankTable
def.field("table")._ComboSkillInfo = BlankTable
def.field("table")._MainSkillLearnLvs = BlankTable
def.field("boolean")._TransformSkillsEnable = false

def.field(CHUDShortcutComp)._ShortcutComp = nil
def.field(CHUDSkillChargeComp)._SkillChargeComp = nil
def.field(CHUDDrugUseComp)._DrugUseComp = nil
def.field(CHUDHawkEyeComp)._HawkEyeComp = nil

def.field("userdata")._BtnJumpObj = nil
def.field("userdata")._ToggleAutoFight = nil
def.field("userdata")._ToggleAutoFightObj = nil
def.field("userdata")._SKillChangeBtn = nil
def.field("boolean")._IsPlayingAutoGfx = false

def.field("number")._NormalAttLaterTimer = 0
def.field("number")._NormalAttPushTimer = 0

local NEW_ROLE_UNLOCKED = 79
local BTN_JUMP_UNLOCKED = 61

local NormalAttckIdx = 1
local CriticalAttckIdx = 6
local JumpSkillIdx = 7

local SkillFuncId = 7
local RuneFuncId = 9
local MasteryFuncId = 64

local instance = nil
def.final("=>", CPanelSkillSlot).Instance = function()
	if instance == nil then
		instance = CPanelSkillSlot()
		instance._PrefabPath = PATH.Panel_SkillSlot
        instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

local function OnSkillCDEvent(sender, event)
     instance:UpdateSkillCDInfo()
	 instance._DrugUseComp:UpdateCDInfo()
	 instance:UpdateCriticalAttckAvailableGfx()
end

local function OnNotifyPropEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		if game._HostPlayer._ID == event.ObjID then
			instance:UpdateAutoFightState()
			instance:UpdateSkillEnableState()
			instance:UpdateCriticalAttckAvailableGfx()
		end
	end
end

local function OnSkillStateUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateSkillEnableState()
		instance:UpdateCriticalAttckAvailableGfx()
	end
end

local function OnChargeEvent(sender, event)
     instance._SkillChargeComp:Update(event.SkillId, event.Is2StartCharging, event.BeginTime, event.MaxChargeTime)
end

local function OnNotifyFunctionEvent(sender, event)
	if instance then
		if event.FunID == EnumDef.EGuideTriggerFunTag.AutoFight then
			if not IsNil(instance._ToggleAutoFightObj) then
				instance._ToggleAutoFightObj:SetActive(true)
			end
		elseif event.FunID == NEW_ROLE_UNLOCKED then
			instance:UpdateTiroState(true)	
			instance:UpdateSkillLockState(0)
		elseif event.FunID == SkillFuncId or event.FunID == RuneFuncId or event.FunID == MasteryFuncId then  -- 讨厌的魔数！！！！
		    local CSkillUtil = require "Skill.CSkillUtil"
		    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp()) 
		end
	end
end

local function OnPackageChange(sender, event)
	 instance._DrugUseComp:Update()
end

local function OnGainNewSkill(sender, event)
	local id = event.SkillId
	 if instance._TransformSkillsEnable and id ~= -1 then
		return
	end

	instance:UpdateSkillLockState(id)

	local hp = game._HostPlayer
	if id ~= -1 then
		local lct = hp:GetSkillLearnConditionTemp(event.SkillId)
		if lct ~= nil then
			local curSkillSlotInfo = instance._SkillSlotInfo[lct.MainUIPos]
			if curSkillSlotInfo ~= nil then
				GameUtil.PlayUISfx(PATH.UIFX_SkillNewGot, curSkillSlotInfo.GameObject, instance._Panel, 3)
			end
		end
	end
end

local function OnSkillTriggerEvent(sender, event)
	 instance:TriggerComboSkill(event._StateId, event._SkillId, event._IsBegin)	 
end

local function OnChangeShapeEvent(sender, event)
	instance:UpdateAutoFightState()
	instance._DrugUseComp:UpdateDrugForbiddenState()
	instance:UpdateTransformSkill()
end

local function OnUIShortCutEvent( sender, event )
    if instance == nil then return end
    if event._Type == EnumDef.EShortCutEventType.DialogStart
        or event._Type == EnumDef.EShortCutEventType.GatherStart 
        or event._Type == EnumDef.EShortCutEventType.RescueStart then    
        instance._ShortcutComp:Show(event._Type, event._Data)
    elseif event._Type == EnumDef.EShortCutEventType.DialogEnd then
        instance._ShortcutComp:Hide(event._Type, event._Data)
    elseif event._Type == EnumDef.EShortCutEventType.HawkEyeOpen then
        instance._HawkEyeComp:HawkEyeOpen(event._Data)
    elseif event._Type == EnumDef.EShortCutEventType.HawkEyeClose then
        instance._HawkEyeComp:HawkEyeClose()
    elseif event._Type == EnumDef.EShortCutEventType.HawkEyeActive then
        instance._HawkEyeComp:HawkEyeActive(event._Data.useTime)
    elseif event._Type == EnumDef.EShortCutEventType.HawkEyeDeactive then
        instance._HawkEyeComp:HawkEyeDeactive()
    end
end

def.override().OnCreate = function (self)
	self._ShortcutComp = CHUDShortcutComp.new(self)
	self._SkillChargeComp = CHUDSkillChargeComp.new(self)
	self._DrugUseComp = CHUDDrugUseComp.new(self)
	self._HawkEyeComp = CHUDHawkEyeComp.new(self)

	self._BtnJumpObj = self:GetUIObject("Btn_Jump")

    self._SKillChangeBtn = self:GetUIObject("Btn_ChangeTarget")
    self._ToggleAutoFightObj = self:GetUIObject("Tog_AutoFight")
    self._ToggleAutoFight = self._ToggleAutoFightObj:GetComponent(ClassType.Toggle)
end

local function change_button_icon(info, icon)
	if info ~= nil and not IsNil(info.GameObject) then
		-- 先不检查 info.SkillTemplate, 无意义
		if icon == "" or icon == nil then return end

		local img = info.UIObjects.ImgSkillIcon
		if not IsNil(img) then
			img:SetActive(true)
			GUITools.SetSkillIcon(img, icon)
		end
	end
end

local function TriggerAllPreStateComboSkill(self)
	local hp = game._HostPlayer
	local buffStates = hp._BuffStates
	if buffStates and #buffStates > 0 then
	    for i,v in ipairs(buffStates) do
	        self:TriggerComboSkill(v._ID, 0, true)
	        v:UpdateEnduringEvent()
	    end
	end
end

def.override('dynamic').OnData = function(self, data)
	CPanelBase.OnData(self, data)
	self:BuildSkillSlotInfo()
	local isUnlock = game._CFunctionMan:IsUnlockByFunTid(NEW_ROLE_UNLOCKED)
	self:UpdateTiroState(isUnlock)
	self:UpdateSkillLockState(0)
	self:UpdateTransformSkill()
	self:UpdateSkillCDInfo()
	self:UpdateSkillEnableState()  -- 释放条件不满足，置灰
	self:UpdateCriticalAttckAvailableGfx()
	self._DrugUseComp:UpdateCDInfo()
	self._DrugUseComp:Update()
	self._DrugUseComp:UpdateDrugForbiddenState()
	self:UpdateAutoFightState()

	do
		CGame.EventManager:addHandler('SkillCDEvent', OnSkillCDEvent)	
		CGame.EventManager:addHandler('NotifyPropEvent', OnNotifyPropEvent)
		CGame.EventManager:addHandler('NotifyChargeEvent', OnChargeEvent)	
		CGame.EventManager:addHandler('PackageChangeEvent', OnPackageChange)
		CGame.EventManager:addHandler('GainNewSkillEvent', OnGainNewSkill)
		CGame.EventManager:addHandler('ChangeShapeEvent', OnChangeShapeEvent)
		CGame.EventManager:addHandler('SkillTriggerEvent', OnSkillTriggerEvent)
		CGame.EventManager:addHandler('NotifyFunctionEvent', OnNotifyFunctionEvent)
		CGame.EventManager:addHandler('UIShortCutEvent', OnUIShortCutEvent)
		CGame.EventManager:addHandler('SkillStateUpdateEvent', OnSkillStateUpdateEvent)
	end
	
	TriggerAllPreStateComboSkill(self)

	local CHawkeyeEffectMan = require "Main.CHawkeyeEffectMan"
	CHawkeyeEffectMan.Instance():UpdateHawkeye()
end

local function GatherMainSkillLearnLvs()
	local hp = game._HostPlayer
	if hp == nil or hp._InfoData == nil then return end

	local lvs = instance._MainSkillLearnLvs
	if #lvs > 0 then return end
	local all = hp:GetAllSkillLearnConditionTemps()
	local EnumLearnType = require "PB.Template".SkillLearnCondition.EnumLearnType
	for i,v in pairs(all) do
		if v.MainUIPos > 0 and v.MainUIPos <= 8 and lvs[v.MainUIPos] == nil and v.RoleLearnType == EnumLearnType.Level then
			lvs[v.MainUIPos] = v.RoleLearnParam
		end
	end
end

local buttons = {"Btn_SkillNormalAttack", "Btn_SkillConventional1", "Btn_SkillConventional2", "Btn_SkillConventional3", "Btn_SkillConventional4", "Btn_SkillUnique", "Btn_Jump"}
def.method().BuildSkillSlotInfo = function(self)
	GatherMainSkillLearnLvs()

	if self._SkillSlotInfo == nil then
		self._SkillSlotInfo = {}
	end

	if #self._SkillSlotInfo == 0 then
		for i,v in ipairs(buttons) do
			if self._SkillSlotInfo[i] == nil then
				self._SkillSlotInfo[i] = {}	
			end

			local btn = self:GetUIObject(v)
			self._SkillSlotInfo[i].GameObject = btn
			self._SkillSlotInfo[i].UIObjects = {}
			local uis = self._SkillSlotInfo[i].UIObjects
			-- 缓存一下，免得每次都Find
			uis.ImgSkillIcon = GUITools.GetChild(btn, 0) 
			GUI.SetAlpha(uis.ImgSkillIcon, 255)
			uis.ImgLock  = GUITools.GetChild(btn, 1) 
			uis.ImgCoolDown = GUITools.GetChild(btn, 2) 
			uis.ImgAccumulateCount = GUITools.GetChild(btn, 3)
			uis.LabLockLevel = GUITools.GetChild(btn, 4) 
			uis.LabAccumulateCount = GUITools.GetChild(btn, 5) 
			uis.LabCDTime = GUITools.GetChild(btn, 6) 
			uis.BlackCoolDown = GUITools.GetChild(btn, 7) 
			uis.GfxRoot = btn:FindChild("Img_Bg") 

			if uis.LabLockLevel ~= nil then
				local isLock = false
				if self._MainSkillLearnLvs[i] ~= nil then
					isLock = true
					GUI.SetText(uis.LabLockLevel, string.format(StringTable.Get(10714), tostring(self._MainSkillLearnLvs[i])))
				else
					GUI.SetText(uis.LabLockLevel, "")
				end
				uis.LabLockLevel:SetActive(isLock)
				uis.ImgLock:SetActive(isLock)
			end

			self._SkillSlotInfo[i].AccumulateCount = -1
		end
	end
end

def.method("number").UpdateSkillLockState = function(self, curSkillId)
	local hp = game._HostPlayer
	
	local updateAll = (curSkillId <= 0)
	if updateAll then
		self._ComboSkillInfo = {}
		for i, v in pairs(self._SkillSlotInfo) do
			v.ActiveComboSkill = nil
			hp:UpdateValidSkillInfo(i, 0)
		end
	end

	local skills = hp._UserSkillMap
	for k,v in ipairs(skills) do
		local skillId = v.SkillId
		if skillId == curSkillId or updateAll then   -- curSkillId <= 0 全刷一遍
			local lct = hp:GetSkillLearnConditionTemp(skillId)
			if lct ~= nil then
				if lct.ComboStateId <= 0 and lct.ComboSkillId == 0 then -- 非连击技能
					local slotInfo = self._SkillSlotInfo[lct.MainUIPos]
					if slotInfo ~= nil then
						slotInfo.SkillTemplate = v.Skill
						local imgLock = slotInfo.UIObjects.ImgLock
						if imgLock ~= nil then
							imgLock:SetActive(false)
						end
						local labLockLevel = slotInfo.UIObjects.LabLockLevel
						if labLockLevel ~= nil then
							labLockLevel:SetActive(false)
						end
						change_button_icon(slotInfo, slotInfo.SkillTemplate.IconName)
						hp:UpdateValidSkillInfo(lct.MainUIPos, v.Skill.Id)				
					end
				else  -- 连击技能
					
					if self._ComboSkillInfo[skillId] == nil then
						self._ComboSkillInfo[skillId] = {Pos = lct.MainUIPos, PreStateID = lct.ComboStateId, PreSkillID = lct.ComboSkillId, Duration = lct.ComboDuration, SkillTemplate = v.Skill, IsOn = false}								
					end
				end
			end
		end
	end
end

-- 新手副本解锁状态
def.method("boolean").UpdateTiroState = function(self, isUnlock)
	if not self:IsShow() then return end

	for i = 2, CriticalAttckIdx do
		local skillSlotInfo = self._SkillSlotInfo[i]
		if skillSlotInfo and skillSlotInfo.UIObjects then
			skillSlotInfo.SkillTemplate = nil
			local slot_obj = skillSlotInfo.UIObjects
			local pos = isUnlock and Vector3.New(0, 9, 0) or Vector3.zero			
			slot_obj.ImgLock.localPosition = pos
			slot_obj.ImgLock:SetActive(true)
			slot_obj.LabLockLevel:SetActive(isUnlock)
			slot_obj.ImgSkillIcon:SetActive(false)
			slot_obj.ImgCoolDown:SetActive(false)
			slot_obj.LabCDTime:SetActive(false)
			slot_obj.BlackCoolDown:SetActive(false)
			GameUtil.StopUISfx(PATH.UIFX_CriticalAttckAvailable, skillSlotInfo.GameObject)
			GameUtil.StopUISfx(PATH.UIFX_ConnectedSkillAttck, skillSlotInfo.GameObject)
		end
	end	
end

local function GetComboSkillInfo(self, skill_id)	
	local combos = self._ComboSkillInfo
	for k,v in pairs(combos) do
		if v.PreSkillID == skill_id then return v end
	end
	return nil
end

def.method("number", "string").ChangeSkillIconByBuffEvent = function(self, skillId, icon)
	if not self:IsShow() then return end

	local slot_infos = self._SkillSlotInfo
	for _,v in pairs(slot_infos) do
		if v ~= nil and v.SkillTemplate ~= nil and skillId == v.SkillTemplate.Id then
			if icon == "" then
				icon = v.SkillTemplate.IconName
			end
			change_button_icon(v, icon)
			break
		end
	end
end

-- 更新点击状态
def.method().UpdateSkillEnableState = function(self)
	local slot_infos = self._SkillSlotInfo
	if slot_infos == nil then return end
	local hp = game._HostPlayer
	local energy_type, cur_energy, _ = hp:GetEnergy()
	for i,v in ipairs(slot_infos) do
		local temp = nil
		if self._TransformSkillsEnable then
			local idList = hp:GetTransformSkills()
			if idList ~= nil and idList[i] ~= nil then
				temp = CElementSkill.Get(idList[i])
			end
		end
		if temp == nil then
			temp = v.ActiveComboSkill or v.SkillTemplate
		end

		if v.GameObject ~= nil and temp ~= nil then
			local enable = true
			local skillId = temp.Id
			if temp.EnergyValue > 0 then
				enable = (temp.EnergyType == energy_type and cur_energy >= temp.EnergyValue)				
			end
			-- 检查下技能的可用情况
			if enable then enable = hp:CanCastSkill(skillId) end
			local img = v.UIObjects.ImgSkillIcon
			GameUtil.MakeImageGray(img, not enable)
		end
	end
end

-- 刷新toggle
def.method().UpdateAutoFightState = function(self)
	if self._ToggleAutoFightObj == nil then return end

	local hp = game._HostPlayer
	local isUnlock = game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.AutoFight)
	local isSkillValid = not hp:IsModelChangedInData()
	if not isSkillValid then
		local skillList = hp:GetTransformSkills()
		if skillList ~= nil then
			for i,v in ipairs(skillList) do
				if v > 0 then isSkillValid = true end
				break
			end
		end
	end
	local isAutoFightActive = isUnlock and isSkillValid and (not game:IsCurMapForbidAutofight())
	if not isAutoFightActive then
		CAutoFightMan.Instance():Stop()
	end
	self._ToggleAutoFightObj:SetActive(isAutoFightActive)
	self._SKillChangeBtn:SetActive(isSkillValid)
end

local bigger_scale = Vector3.New(1.3, 1.3, 1.3)
def.method().UpdateSkillCDInfo = function(self)
	local hp = game._HostPlayer
	local CDHdl = hp._CDHdl
	local slot_infos = self._SkillSlotInfo

	for i,v in ipairs(slot_infos) do
		if v.GameObject ~= nil and v.SkillTemplate ~= nil then
			local skillTemp = nil			
			if self._TransformSkillsEnable then
				local idList = hp:GetTransformSkills()
				if idList ~= nil and idList[i] ~= nil then	
					skillTemp = CElementSkill.Get(idList[i])	
				end
			else
				skillTemp = v.ActiveComboSkill or v.SkillTemplate
			end

			local cdid = 0
			if skillTemp ~= nil then
				cdid = skillTemp.CooldownId
			end

			local cd_image = v.UIObjects.ImgCoolDown		
			if not IsNil(cd_image) and cdid > 0 then
				local cd_time = v.UIObjects.LabCDTime
				local charge_lab = v.UIObjects.LabAccumulateCount
				local charge_img = v.UIObjects.ImgAccumulateCount
				local black = v.UIObjects.BlackCoolDown

				if CDHdl:IsCoolingDown(cdid) then
					if cd_image then
						local elapsed, max = CDHdl:GetCurInfo(cdid)
						local function cb()
							-- 暂时屏蔽跳跃
							if i ~= JumpSkillIdx and not self._TransformSkillsEnable then						
								GameUtil.PlayUISfx(PATH.UIFX_SkillCoolDown, v.GameObject, self._Panel, 2)
								-- if black then black:SetActive(false) end										
							else
								GUI.SetAlpha(v.UIObjects.ImgSkillIcon, 255)							
							end						
						end
						GameUtil.AddCooldownComponent(cd_image, elapsed, max, cd_time, cb, false)
						if i == JumpSkillIdx then
							GameUtil.AddCooldownComponent(charge_img, elapsed, max, cd_time, nil, false)
							GUI.SetAlpha(v.UIObjects.ImgSkillIcon, 128)
						end

						if black then black:SetActive(true) end						
					end

					if charge_lab ~= nil then
						charge_lab:SetActive(false)
						charge_img:SetActive(false)
						v.AccumulateCount = 0
					end
				else
					cd_image:SetActive(false)					
					if not IsNil(cd_time) then
						GUI.SetText(cd_time, "")
					end
					if charge_lab ~= nil then
						local accumulateCount = CDHdl:GetAccumulateCount(cdid)

						local maxCount = 1
						local cooldown = CElementData.GetTemplate("Cooldown", cdid)
						if cooldown ~= nil then maxCount = cooldown.MaxAccumulateCount end
						if maxCount >= 2 and accumulateCount >= 1 then
							charge_lab:SetActive(true)
							charge_img:SetActive(true)
							--charge_lab:GetComponent(ClassType.Text).text = tostring(accumulateCount)
							GUI.SetText(charge_lab, tostring(accumulateCount))
							if v.AccumulateCount ~= -1 and accumulateCount > v.AccumulateCount then
								GUITools.DoScale(charge_img, bigger_scale, 0.3, function()
									GUITools.DoScale(charge_img, Vector3.one, 0.3, nil)
								end)
								GUITools.DoScale(charge_lab, bigger_scale, 0.3, function()
									GUITools.DoScale(charge_lab, Vector3.one, 0.3, nil)
								end)
							end

							v.AccumulateCount = accumulateCount
						else
							charge_lab:SetActive(false)
							charge_img:SetActive(false)
							v.AccumulateCount = 0
						end
					end

					if black then black:SetActive(false) end					
				end
			end
		end
	end
end

local function ClearComboSkill(self, comboSkillInfo)
	local uiPosIdx = comboSkillInfo.Pos
	local curInfo = self._SkillSlotInfo[uiPosIdx]
	if curInfo == nil or curInfo.SkillTemplate == nil then 
		return 
	end
	GameUtil.StopUISfx(PATH.UIFX_ConnectedSkillAttck, curInfo.GameObject)

	local hp = game._HostPlayer
	-- 变身技能中 不再清qte技能icon
	if self._TransformSkillsEnable then
		local idList = hp:GetTransformSkills()
		local isValidTransformSkill = (idList ~= nil and idList[uiPosIdx] ~= nil and idList[uiPosIdx] > 0)
		-- 处于变身中 但是对应位置没有技能
		if not isValidTransformSkill then
			change_button_icon(curInfo, curInfo.SkillTemplate.IconName)
		end
	else
		change_button_icon(curInfo, curInfo.SkillTemplate.IconName)
	end
	
	comboSkillInfo.IsOn = false
	curInfo.ActiveComboSkill = nil
	if curInfo.ComboClearTimer ~= nil and curInfo.ComboClearTimer ~= 0 then
		hp:RemoveTimer(curInfo.ComboClearTimer)
		curInfo.ComboClearTimer = 0
	end

	hp:UpdateValidSkillInfo(uiPosIdx, curInfo.SkillTemplate.Id)

	self:UpdateSkillCDInfo()
end

local function ShowComboSkill(self, comboSkillInfo, showCountDown)
	local uiPosIdx = comboSkillInfo.Pos
	local curInfo = self._SkillSlotInfo[uiPosIdx]
	local hp = game._HostPlayer
	if curInfo == nil or comboSkillInfo.SkillTemplate == nil then return end
	
	if not IsNil(curInfo.GameObject) then
		local cd_image = curInfo.UIObjects.ImgCoolDown
		if not IsNil(cd_image) and cd_image.activeSelf then
			cd_image:SetActive(false)
		end
	end
	local cd_label = curInfo.UIObjects.LabCDTime
	if not IsNil(cd_label) then
		--cd_label:GetComponent(ClassType.Text).text = ""
		GUI.SetText(cd_label, "")
	end

	-- TODO: 触发连击技能暂时不做能量消耗检查
	-- 更换技能图标
	change_button_icon(curInfo, comboSkillInfo.SkillTemplate.IconName)
	curInfo.ActiveComboSkill = comboSkillInfo.SkillTemplate
	comboSkillInfo.IsOn = true

	-- 显示Combo倒计时
	if showCountDown then
		local duration = comboSkillInfo.Duration/1000
		curInfo.ComboClearTimer = game._HostPlayer:AddTimer(duration, true, function()
				curInfo.ComboClearTimer = 0
				ClearComboSkill(self, comboSkillInfo)				
				hp:UpdateActiveSkillList(curInfo.SkillTemplate.Id, false)
			end)
	end

	hp:UpdateValidSkillInfo(uiPosIdx, curInfo.ActiveComboSkill.Id)
	self:UpdateSkillCDInfo()
end

def.override("string", "boolean").OnToggle = function(self, id, isOn)	
	if id == "Tog_AutoFight" then
		local hp = game._HostPlayer

		if hp:IsDead() then
		 	game._GUIMan:ShowTipText(StringTable.Get(30103), false)
		 	self._ToggleAutoFight.isOn = false
		    return
		end

		if isOn then			
			CAutoFightMan.Instance():Start()
			local mode, param = EnumDef.AutoFightType.WorldFight, 0
			if CQuestAutoMan.Instance():IsOn() then
				--TODO: 如果自动任务开启时，且当前任务未杀怪时，是否应该切换到 Quest 模式？
				mode = EnumDef.AutoFightType.QuestFight
				param = CQuestAutoMan.Instance():GetCurQuestId()    
	        end

			CAutoFightMan.Instance():SetMode(mode, param, true)	
		else
			CAutoFightMan.Instance():Stop()	
		end
		-- 需要判断玩家是否在跟随玩家
		local CTeamMan = require "Team.CTeamMan"
		if CTeamMan.Instance():IsFollowing()then
			hp:StopAutoFollow()
		end
	end
end

-- 变身技能触发
def.method().UpdateTransformSkill = function(self)
	if not self:IsShow() then return end

	local hp = game._HostPlayer
	local idList = hp:GetTransformSkills()
	local changed = (idList ~= nil and #idList > 0)
	if not changed and not self._TransformSkillsEnable then return end

	local isUnlock = game._CFunctionMan:IsUnlockByFunTid(BTN_JUMP_UNLOCKED)
	self._BtnJumpObj:SetActive(not changed and isUnlock)

	self._TransformSkillsEnable = changed

	if changed then 
		for i, v in ipairs(idList) do		
			local curInfo = self._SkillSlotInfo[i]
			if v > 0 then
				-- 清理CD和特效
				curInfo.UIObjects.ImgCoolDown:SetActive(false)
				GameUtil.StopUISfx(PATH.UIFX_ConnectedSkillAttck, curInfo.GameObject)		
				GUI.SetText(curInfo.UIObjects.LabCDTime, "")
				local changedSkillTemp = CElementSkill.Get(v)	
				if changedSkillTemp ~= nil then
					change_button_icon(curInfo, changedSkillTemp.IconName)
				end
				hp:UpdateValidSkillInfo(i, v)
			else
				GUITools.SetUIActive(curInfo.GameObject, false)
			end	 
		end	
		self:UpdateSkillCDInfo()
	else  -- 状态结束，清除连击技能
		for i, v in pairs(self._SkillSlotInfo) do
			if v.SkillTemplate ~= nil then
				change_button_icon(v, v.SkillTemplate.IconName)
				hp:UpdateValidSkillInfo(i, v.SkillTemplate.Id)
			end
			GUITools.SetUIActive(v.GameObject, true)
		end
	 	self:UpdateSkillLockState(0)
	 	self:UpdateSkillCDInfo()
	 	TriggerAllPreStateComboSkill(self)
	end
end

-- Combo技能释放成功后，清除当前显示的Combo技能
def.method("number").OnSkillPerformed = function(self, skillId)
	local clear_qte_state = false
	local infos = self._SkillSlotInfo
	for i,v in ipairs(infos) do
		local skill = v.SkillTemplate
		-- 使用任何技能（常规技能、终极技能），则退出QTE过程
		if skill ~= nil and skill.Id == skillId and (skill.Category == SkillCategory.Routine or skill.Category == SkillCategory.Ultimate) then
			clear_qte_state = true
			break
		end
	end

	local combos = self._ComboSkillInfo
	for k,v in pairs(combos) do
		if v.IsOn and (skillId == v.SkillTemplate.Id or clear_qte_state) and v.PreSkillID ~= 0 then
			ClearComboSkill(self, v)			
		end
	end
end

-- 此UI状态的开启关闭，必须通过AutoFightMan，保证逻辑与状态的一致  added by lijian
def.method("boolean").SyncAutoFightUIState = function(self, isOn)
	if self._ToggleAutoFightObj == nil then return end

	if self._ToggleAutoFight.isOn ~= isOn then
		self._ToggleAutoFight.isOn = isOn
	end

	if isOn == self._IsPlayingAutoGfx then return end

	local hintPoint = self._ToggleAutoFightObj:FindChild("Img_Bg")		
	if hintPoint ~= nil then
		if isOn then	      
			GameUtil.PlayUISfx(PATH.UIFX_AutoFightTag, hintPoint, hintPoint, -1)
		else
			GameUtil.StopUISfx(PATH.UIFX_AutoFightTag, hintPoint)
		end		
	end
	self._IsPlayingAutoGfx = isOn
end

def.method("number", "number", "boolean").TriggerComboSkill = function(self, triggerStateId, triggerSkillId, isBeginning)
	local combos = self._ComboSkillInfo
	if combos == nil then return end
	local hp = game._HostPlayer
	local CDHdl = hp._CDHdl
	if isBeginning then  -- 技能或者状态开始，触发连击技能		
		for k,v in pairs(combos) do
			--if v.IsOn == nil or not v.IsOn then
				local state_data = CElementData.GetTemplate("State", triggerStateId)
				if state_data and v.PreStateID ~= 0 and v.PreSkillID == 0 and state_data.StateGroupId == v.PreStateID then -- 状态触发
					-- 当自身有指定状态时，触发【技能切换】,倒计时不生效
					ShowComboSkill(self, v, false)
					local curInfo = self._SkillSlotInfo[v.Pos]
					GameUtil.PlayUISfx(PATH.UIFX_SkillChanged, curInfo.GameObject, curInfo.GameObject, 5)
				elseif v.PreSkillID ~= 0 and triggerSkillId == v.PreSkillID then  -- 技能触发
					-- 使用指定技能后，触发【技能QTE】,显示倒计时提示
					-- 使用指定技能后，触发【技能切换】,指定状态消失时，切回默认技能,倒计时不生效
					hp:UpdateActiveSkillList(triggerSkillId, true)
					local showCountDown = (triggerSkillId ~= 0)
					ShowComboSkill(self, v, showCountDown)
					local curInfo = self._SkillSlotInfo[v.Pos]
					GameUtil.PlayUISfx(PATH.UIFX_ConnectedSkillAttck, curInfo.GameObject, curInfo.GameObject, v.Duration/1000)
				end				
			--end
		end
	else  -- 状态结束，清除连击技能
		for k,v in pairs(combos) do
			if v.IsOn then
				local state_data = CElementData.GetTemplate("State", triggerStateId)		
				if IsNil(state_data) then
					warn("error occur in TriggerComboSkill triggerStateId  = "..tostring(triggerStateId), debug.traceback())
					return
				end 
				
				if v.PreStateID ~= 0 and state_data.StateGroupId == v.PreStateID then
					ClearComboSkill(self, v)
				end
			end
		end
	end
end

local function FindSlotIndexByName(id)
	local index = -1
	for i, v in ipairs(buttons) do
		if id == v then
			index = i
			break
		end
	end

	return index
end

def.method().UpdateCriticalAttckAvailableGfx = function(self)
	local hp = game._HostPlayer
	local curSkillSlotInfo = self._SkillSlotInfo[CriticalAttckIdx]
	local criticalAttckTemp = curSkillSlotInfo.SkillTemplate
	
	if criticalAttckTemp == nil then return end
	
	local enable = true
	if criticalAttckTemp.EnergyValue > 0 then
		local energy_type, cur_energy, _ = hp:GetEnergy()
		enable = (criticalAttckTemp.EnergyType == energy_type and cur_energy >= criticalAttckTemp.EnergyValue)
	end

	-- 检查下技能的可用情况
	if enable then 
		enable = hp:CanCastSkill(criticalAttckTemp.Id) 
	end
	
	-- 检查技能CD	
	if enable then
		local cdId = criticalAttckTemp.CooldownId
		if cdId > 0 then
			enable = not hp._CDHdl:IsCoolingDown(cdId)
		end
	end

	local oldState = GameUtil.IsPlayingUISfx(PATH.UIFX_CriticalAttckAvailable, curSkillSlotInfo.GameObject, curSkillSlotInfo.GameObject)
	if enable == oldState then return end

	if enable then
		GameUtil.PlayUISfx(PATH.UIFX_CriticalAttckAvailable, curSkillSlotInfo.GameObject, curSkillSlotInfo.GameObject, -1)
	else
		GameUtil.StopUISfx(PATH.UIFX_CriticalAttckAvailable, curSkillSlotInfo.GameObject)
	end
end

def.method("number").PlaySkillBtnClickGfx = function(self, index)
	local skill_icon = self._SkillSlotInfo[index].GameObject
	if self._SkillSlotInfo[index] ~= nil then 
		local gfxRoot =  self._SkillSlotInfo[index].UIObjects.GfxRoot
		if gfxRoot ~= nil then
			-- 普攻
			if index == NormalAttckIdx then
				GameUtil.PlayUISfx(PATH.UIFX_ClickSimpleAttck, gfxRoot, gfxRoot, 2)
			-- 必杀
			elseif index == CriticalAttckIdx then
				GameUtil.PlayUISfx(PATH.UIFX_ClickCriticalAttck, gfxRoot, gfxRoot, 2)
			else
				GameUtil.PlayUISfx(PATH.UIFX_ClickSkillAttck, gfxRoot, gfxRoot, 2)
			end
		end
	end		
end

def.override("string").OnButtonSlide = function(self, id)
	if id == "Btn_Item" then
		self._DrugUseComp:OpenItemsList()
	end
end

local function CastSkill(self, index)
	local hp = game._HostPlayer

	local skillTemp = nil
	-- 变身技能 启用
	if self._TransformSkillsEnable then
		local idList = hp:GetTransformSkills()
		if idList ~= nil and idList[index] ~= nil then		
			skillTemp = CElementSkill.Get(idList[index])
		end				
	else
		local curSlotInfo = self._SkillSlotInfo[index]
		if curSlotInfo == nil then 
			game._GUIMan:ShowTipText(StringTable.Get(111), false)
			return 
		end
		skillTemp = curSlotInfo.ActiveComboSkill or curSlotInfo.SkillTemplate
	end

	if skillTemp == nil then
		game._GUIMan:ShowTipText(StringTable.Get(111), false) 
		return 
	end

	local cdid = skillTemp.CooldownId
	if cdid > 0 and hp._CDHdl:IsCoolingDown(cdid) then
		game._GUIMan:ShowTipText(StringTable.Get(101), false) 
		return 
	end

	if not game._IsUsingJoyStick and CAutoFightMan.Instance():HasTarget() and CAutoFightMan.Instance():OnManualSkill(skillTemp.Id) then
		return 
	end			

	self:PlaySkillBtnClickGfx(index)

	if skillTemp.Category == SkillCategory.Dodge then  --闪身
		local pos = hp:GetPos() + hp:GetDir()
		hp._SkillHdl:Roll(pos)
		return
	end
	hp._SkillHdl:CastSkill(skillTemp.Id, false)
end

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Item" or string.find(id, "Btn_Drug_Item_") then
		self._DrugUseComp:OnClick(id)
	elseif id == "Btn_ChangeTarget" then
		local CTargetDetector = require "ObjHdl.CTargetDetector"
		CTargetDetector.Instance():ChangeTarget()	
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
    elseif id == 'Btn_Talk' then 
    	self._ShortcutComp:OnClick()
    elseif id == 'Chk_Eye' then
    	game._HostPlayer:StopAutoFollow()
    	self._HawkEyeComp:OnClick()
	else
		if id == 'Btn_Jump' and game._RegionLimit._LimitDodge then
			-- 地图限制禁止闪避
			game._GUIMan:ShowTipText(StringTable.Get(15555), false)
			return
		end

		local hp = game._HostPlayer
		if hp:IsDead() then
		 	game._GUIMan:ShowTipText(StringTable.Get(30103), false)		 	
		    return
		end
		
		local index = FindSlotIndexByName(id)
		if index == -1 then 
			game._GUIMan:ShowTipText(StringTable.Get(111), false)
			return 
		end

		CastSkill(self, index)
	end
end

local interval = 0.3
def.override("string").OnPointerDown = function(self, id)
    if id == "Btn_SkillNormalAttack" then
    	local function AttCallFunc()
			CastSkill(self, 1)
    	end

    	if self._NormalAttLaterTimer > 0 then
    		_G.RemoveGlobalTimer(self._NormalAttLaterTimer)
    		self._NormalAttLaterTimer = 0
    	end

    	self._NormalAttLaterTimer = _G.AddGlobalTimer(interval, true, function()
	    	if self._NormalAttPushTimer > 0 then
	    		_G.RemoveGlobalTimer(self._NormalAttPushTimer)
	    		self._NormalAttPushTimer = 0
	    	end
			self._NormalAttPushTimer = _G.AddGlobalTimer(interval, false, AttCallFunc)    		
    	end)
    end   
end

def.override("string").OnPointerUp = function(self, id)
	if id == "Btn_SkillNormalAttack" then
    	if self._NormalAttLaterTimer > 0 then
    		_G.RemoveGlobalTimer(self._NormalAttLaterTimer)
    		self._NormalAttLaterTimer = 0
    	end

    	if self._NormalAttPushTimer > 0 then
    		_G.RemoveGlobalTimer(self._NormalAttPushTimer)
    		self._NormalAttPushTimer = 0
    	end
    end
end

def.method().HideBtnTalk = function(self)
	if not self:IsShow() then return end

    self._ShortcutComp:Hide(0, nil)
end

def.method("number").CastSkillByIndex = function(self, index)
	CastSkill(self, index)
end

def.method().Cleanup = function (self)
	self._MainSkillLearnLvs = {}
	self._IsPlayingAutoGfx = false
	self._SkillSlotInfo = {}  -- 清理掉 combo的 缓存
	self._ComboSkillInfo = {}

	if self._NormalAttLaterTimer > 0 then
		_G.RemoveGlobalTimer(self._NormalAttLaterTimer)
		self._NormalAttLaterTimer = 0
	end

	if self._NormalAttPushTimer > 0 then
		_G.RemoveGlobalTimer(self._NormalAttPushTimer)
		self._NormalAttPushTimer = 0
	end

	if self._DrugUseComp ~= nil then
		self._DrugUseComp:Clear()
	end
	if self._SkillChargeComp ~= nil then
		self._SkillChargeComp:Clear()
	end	
	if self._ShortcutComp ~= nil then
		self._ShortcutComp:Clear()
	end
	if self._HawkEyeComp ~= nil then
		self._HawkEyeComp:Clear()
	end
end

def.override().OnHide = function (self)
    CPanelBase.OnHide(self)
	CGame.EventManager:removeHandler('SkillCDEvent', OnSkillCDEvent)	
	CGame.EventManager:removeHandler('NotifyPropEvent', OnNotifyPropEvent)
	CGame.EventManager:removeHandler('NotifyChargeEvent', OnChargeEvent)	
	CGame.EventManager:removeHandler('PackageChangeEvent', OnPackageChange)
	CGame.EventManager:removeHandler('GainNewSkillEvent', OnGainNewSkill)
	CGame.EventManager:removeHandler('ChangeShapeEvent', OnChangeShapeEvent)
	CGame.EventManager:removeHandler('UIShortCutEvent', OnUIShortCutEvent)
	CGame.EventManager:removeHandler('SkillTriggerEvent', OnSkillTriggerEvent)
	CGame.EventManager:removeHandler('NotifyFunctionEvent', OnNotifyFunctionEvent)	
	CGame.EventManager:removeHandler('SkillStateUpdateEvent', OnSkillStateUpdateEvent)
	
	self:Cleanup()
end

def.override().OnDestroy = function (self)
	if self._DrugUseComp ~= nil then
		self._DrugUseComp:Release()
		self._DrugUseComp = nil
	end
	if self._SkillChargeComp ~= nil then
		self._SkillChargeComp:Release()
		self._SkillChargeComp = nil
	end
	if self._ShortcutComp ~= nil then
		self._ShortcutComp:Release()
		self._ShortcutComp = nil
	end
	if self._HawkEyeComp ~= nil then
		self._HawkEyeComp:Release()
		self._HawkEyeComp = nil
	end

	self._BtnJumpObj = nil
	self._ToggleAutoFight = nil
	self._ToggleAutoFightObj = nil
	self._SKillChangeBtn = nil
end

CPanelSkillSlot.Commit()
return CPanelSkillSlot
