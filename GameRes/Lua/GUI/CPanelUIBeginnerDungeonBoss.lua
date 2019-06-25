-- 新手副本Boss
-- 2018/8/20

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIBeginnerDungeonBoss = Lplus.Extend(CPanelBase, "CPanelUIBeginnerDungeonBoss")
local def = CPanelUIBeginnerDungeonBoss.define

local CBeginnerDungeonMan = require "Dungeon.CBeginnerDungeonMan"

def.field("userdata")._Frame_Normal = nil
def.field("userdata")._Btn_ShowPassBoss = nil
def.field("userdata")._Btn_PassBoss = nil
def.field("userdata")._Frame_JumpGuide = nil
def.field("userdata")._Lab_BossTitle = nil       --BOSS称号
def.field("userdata")._Lab_BossName = nil        --BOSS名称
def.field("userdata")._Btn_JumpSkill = nil

local instance = nil
def.static("=>", CPanelUIBeginnerDungeonBoss).Instance = function ()
	if not instance then
		instance = CPanelUIBeginnerDungeonBoss()
		instance._PrefabPath = PATH.UI_BeginnerDungeonBoss
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ForbidESC = true
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self._Frame_Normal = self:GetUIObject("Frame_Normal")
	self._Btn_ShowPassBoss = self:GetUIObject("Btn_ShowPassBoss")
	self._Btn_PassBoss = self:GetUIObject("Btn_PassBossAnimation")
	self._Frame_JumpGuide = self:GetUIObject("Frame_JumpGuide")
	self._Lab_BossTitle = self:GetUIObject("Lab_BossTitle")
	self._Lab_BossName = self:GetUIObject("Lab_BossName")
	self._Btn_JumpSkill = self:GetUIObject("Btn_JumpSkill")
end

def.override("dynamic").OnData = function (self, data)
	if data == nil then
		warn("Can not Open CPanelUIBeginnerDungeonBoss without data", debug.traceback())
		return
	end

	GUITools.SetUIActive(self._Frame_JumpGuide, data.IsJumpGuide == true)
	GUITools.SetUIActive(self._Frame_Normal, data.IsJumpGuide == false)
	if data.IsJumpGuide then
		local title, name = "BossTitle", "BossName"
		if type(data.BossTitle) == "string" then
			title = data.BossTitle
		end
		if type(data.BossName) == "string" then
			name = data.BossName
		end
		self:ShowBossInfo(name, title)
	else
		GUITools.SetUIActive(self._Btn_ShowPassBoss, true)
		GUITools.SetUIActive(self._Btn_PassBoss, false)
	end
end

def.method("string", "string").ShowBossInfo = function (self, name, title)
	GUITools.SetUIActive(self._Btn_JumpSkill, false)
	GUI.SetText(self._Lab_BossTitle, title)
	GUI.SetText(self._Lab_BossName, name)
end

def.override("string").OnClick = function (self, id)
	if id == "Btn_JumpSkill" then
		-- 释放闪身技能
		local hp = game._HostPlayer
		local pos = hp:GetPos() + hp:GetDir()
		hp._SkillHdl:Roll(pos)
		-- 退出闪身教学
		CBeginnerDungeonMan.Instance():FinishJumpGuide()
	elseif id == "Btn_ShowPassBoss" then
		GUITools.SetUIActive(self._Btn_PassBoss, true)
		GUITools.SetUIActive(self._Btn_ShowPassBoss, false)
	elseif id == "Btn_PassBossAnimation" then
		CBeginnerDungeonMan.Instance():PassCameraAnimation()
	end
end

def.method().ShowBtnJump = function (self)
	GUITools.SetUIActive(self._Btn_JumpSkill, true)
end

def.override().OnDestroy = function (self)
	self._Frame_Normal = nil
	self._Btn_ShowPassBoss = nil
	self._Btn_PassBoss = nil
	self._Frame_JumpGuide = nil
	self._Lab_BossTitle = nil
	self._Lab_BossName = nil
	self._Btn_JumpSkill = nil
end

def.override("=>", "boolean").IsCountAsUI = function(self)
    return false
end

CPanelUIBeginnerDungeonBoss.Commit()
return CPanelUIBeginnerDungeonBoss