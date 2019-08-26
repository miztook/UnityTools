-- 相机近景模式UI
-- 时间：2017/12/20
-- Add by Yao

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUINearCam = Lplus.Extend(CPanelBase, "CPanelUINearCam")
local def = CPanelUINearCam.define

def.field("userdata")._TweenMan = nil
def.field("userdata")._Frame_Control = nil
def.field("userdata")._Btn_ToExterior = nil
def.field("userdata")._Img_HideOther = nil
def.field("userdata")._Frame_ShowScreenShot = nil
def.field("userdata")._Img_ScreenShot = nil
def.field("userdata")._Btn_Yes = nil
def.field("userdata")._Btn_No = nil

def.field("boolean")._IsHidingOther = false
def.field("table")._InteractiveSkillIdMap = BlankTable

local MAX_INTERACTIVE_SKILL_NUM = 8 -- 最大交互技能数量
local POS_BASE_NUM = 100 -- 技能位置基数

local instance = nil
def.static("=>",CPanelUINearCam).Instance = function()
	if instance == nil then
		instance = CPanelUINearCam()
		instance._PrefabPath = PATH.UI_NearCam
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ClickInterval = 0.5
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._TweenMan = self._Panel:GetComponent(ClassType.DOTweenPlayer)
	self._Frame_Control = self:GetUIObject("Frame_Control")
	self._Btn_ToExterior = self:GetUIObject("Btn_ToExterior")
	self._Img_HideOther = self:GetUIObject("Img_HideOther")
	self._Frame_ShowScreenShot = self:GetUIObject("Frame_Show")
	self._Img_ScreenShot = self:GetUIObject("Img_ScreenShot")
	self._Btn_Yes = self:GetUIObject("Btn_Yes")
	self._Btn_No = self:GetUIObject("Btn_No")
	self._Frame_ShowScreenShot:SetActive(true)
	GUITools.SetUIActive(self._Frame_ShowScreenShot, false)
	local btn_photo = self:GetUIObject("Btn_Photo")
	GUITools.SetUIActive(btn_photo, false) -- 屏蔽保存相册功能

	self._InteractiveSkillIdMap = {}
	local hp = game._HostPlayer
	for _,v in ipairs(hp._UserSkillMap) do
		if v ~= nil then
			local conditionData = hp:GetSkillLearnConditionTemp(v.SkillId)
			if conditionData ~= nil and conditionData.MainUIPos > POS_BASE_NUM then
				local index = conditionData.MainUIPos - POS_BASE_NUM
				if index <= MAX_INTERACTIVE_SKILL_NUM then
					local skillLearnTemp = hp:GetSkillLearnConditionTemp(v.SkillId)
					if skillLearnTemp ~= nil then
						self._InteractiveSkillIdMap[index] = v.SkillId
					end
				end
			end
		end
	end
end

local function OnCombatStateChangeEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		if event._IsInCombatState and event._CombatType == 1 then
			-- 服务器进战
			game:QuitNearCam()
		end
	end
end

def.override("dynamic").OnData = function(self, data)
	local CExteriorMan = require "Main.CExteriorMan"
	local funcTid = CExteriorMan.Instance():GetFuncTid()
	local isUnlock = game._CFunctionMan:IsUnlockByFunTid(funcTid)
	GUITools.SetUIActive(self._Btn_ToExterior, isUnlock)
	self:UpdateHideOtherState()

	CGame.EventManager:addHandler("CombatStateChangeEvent", OnCombatStateChangeEvent)
end

def.override("string").OnClick = function (self, id)
	if string.find(id, "Btn_Back") then
		GameUtil.SetCamToDefault(false, false, true, true)
		game:QuitNearCam()
	elseif string.find(id, "Btn_Exit") then
		GameUtil.SetCamToDefault(false, false, true, true)
		game:QuitNearCam()
	elseif string.find(id, "Btn_ToExterior") then
		-- 到外观界面
		local CExteriorMan = require "Main.CExteriorMan"
		if CExteriorMan.Instance():CanEnter() then
			game._GUIMan:CloseByScript(self)
			GameUtil.SetCamToDefault(true, true, true, true)
			CExteriorMan.Instance():Enter(nil)
		end
	elseif string.find(id, "Btn_HideOther") then
		local oldState = self._IsHidingOther
		self._IsHidingOther = not oldState
		self:UpdateHideOtherState()
	elseif string.find(id, "Btn_Photo") then
		-- 截屏
		GameUtil.CaptureScreen()
		self:OnClickPhoto()
	elseif string.find(id, "Btn_Interactive_") then
		-- 交互技能
		local skillIndex = tonumber(string.sub(id, string.len("Btn_Interactive_")+1, -1))
		if skillIndex == nil then return end
		self:OnClickInteractiveSkill(skillIndex)

	--[[
	elseif string.find(id, "Btn_No") then
		-- 不保存截屏
		GUITools.SetUIActive(self._Frame_Control, true)
		GUITools.SetUIActive(self._Frame_ShowScreenShot, false)
		GameUtil.AbandonScreenShot()
	elseif string.find(id, "Btn_Yes") then
		-- 保存截屏
		local function SaveScreenShot()
			GUITools.SetUIActive(self._Frame_Control, true)
			GUITools.SetUIActive(self._Frame_ShowScreenShot, false)
			GameUtil.SaveScreenShot()
		end
		if GameUtil.HasPhotoPermission() then
			SaveScreenShot()
		else
			GameUtil.RequestPhotoPermission()
			if GameUtil.HasPhotoPermission() then
				SaveScreenShot()
			end
		end
		-- game._GUIMan:ShowTipText(StringTable.Get(864), false)
	--]]
	end
end

--DOTTween CallBack here
def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	CPanelBase.OnDOTComplete(self,go_name,dot_id)

	if dot_id == "1" then
		local function Show(ret)
			if ret then
				GUITools.SetUIActive(self._Frame_ShowScreenShot, true)
				GameUtil.ShowScreenShot(self._Img_ScreenShot)
				self._TweenMan:Restart("2")
				GameUtil.SaveScreenShot() -- 自动保存
			else
				-- 没有权限，直接恢复显示
				GUITools.SetUIActive(self._Frame_Control, true)
				GUITools.SetUIActive(self._Frame_ShowScreenShot, false)
			end
		end
		-- 检查权限
		if GameUtil.HasPhotoPermission() then
			Show(true)
		else
			GameUtil.RequestPhotoPermission()
			Show(GameUtil.HasPhotoPermission())
		end
	elseif dot_id == "2" then
		GUITools.SetUIActive(self._Frame_Control, true)
		GUITools.SetUIActive(self._Frame_ShowScreenShot, false)
		GameUtil.AbandonScreenShot() -- 删除Texture缓存
	end
end

def.method().OnClickPhoto = function (self)
	GUITools.SetUIActive(self._Frame_Control, false)
	self._TweenMan:Restart("1")
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_NearCamCapture, 0)
end

--点击交互技能按钮
def.method("number").OnClickInteractiveSkill = function(self, index)
	local hp = game._HostPlayer
	if hp:IsInServerCombatState()then
		game._GUIMan:ShowTipText(StringTable.Get(139), false)
		return 
	end
	if next(self._InteractiveSkillIdMap) == nil then
		warn("Empty interactive skill, wrong prof:"  .. hp._InfoData._Prof)
		return 
	end
	local skillId = self._InteractiveSkillIdMap[index]
	if skillId == nil then 
		warn("Skill id got nil, wrong index:", index)
		return 
	end

	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CDungeonAutoMan.Instance():Stop()
	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Stop()
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)

	hp._SkillHdl:CastSkill(skillId, false)

	GameUtil.EnableNearCamLookIK(false) -- 停止头部转向
	hp._SkillHdl:RegisterCallback(false, function()
		if not game._IsInNearCam then return end
		GameUtil.EnableNearCamLookIK(true) -- 恢复头部转向
	end)
end

def.method("boolean").EnableButtons = function (self, enable)
	GUITools.SetUIActive(self._Btn_Yes, enable)
	GUITools.SetUIActive(self._Btn_No, enable)
end

def.method().UpdateHideOtherState = function(self)
	local bVisible = not self._IsHidingOther
	local index = bVisible and 0 or 1
	GUITools.SetGroupImg(self._Img_HideOther, index)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, bVisible)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, bVisible)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, bVisible)
end

def.override().OnDestroy = function (self)
	CGame.EventManager:removeHandler("CombatStateChangeEvent", OnCombatStateChangeEvent)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, true)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, true)
	GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, true)

	game._IsInNearCam = false
	self._IsHidingOther = false

	self._TweenMan = nil
	self._Frame_Control = nil
	self._Btn_ToExterior = nil
	self._Frame_ShowScreenShot = nil
	self._Img_ScreenShot = nil
	self._Btn_Yes = nil
	self._Btn_No = nil

	GameUtil.AbandonScreenShot() -- 删除Texture缓存
end

CPanelUINearCam.Commit()
return CPanelUINearCam