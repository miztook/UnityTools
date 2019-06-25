-- 全屏提示
-- 2018/8/20

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIFullScreenTips = Lplus.Extend(CPanelBase, "CPanelUIFullScreenTips")
local def = CPanelUIFullScreenTips.define

def.field("userdata")._Frame_BossEnter = nil       --BOSS入场Tips
def.field("userdata")._Btn_ShowPassBoss = nil
def.field("userdata")._Btn_PassBoss = nil
def.field("userdata")._Lab_BossTitle = nil       --BOSS称号
def.field("userdata")._Lab_BossName = nil        --BOSS名称

-- 打开类型
local EOpenType =
{
	BossEnter = 1,		-- Boss进场
}

local instance = nil
def.static("=>", CPanelUIFullScreenTips).Instance = function ()
	if not instance then
		instance = CPanelUIFullScreenTips()
		instance._PrefabPath = PATH.UI_FullScreenTips
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ForbidESC = true
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self._Frame_BossEnter = self:GetUIObject("Frame_BossEnter")
	self._Btn_ShowPassBoss = self:GetUIObject("Btn_ShowPassBoss")
	self._Btn_PassBoss = self:GetUIObject("Btn_PassBossAnimation")
	self._Lab_BossTitle = self:GetUIObject("Lab_BossTitle")
	self._Lab_BossName = self:GetUIObject("Lab_BossName")

	self._Frame_BossEnter:SetActive(true)
	GUITools.SetUIActive(self._Frame_BossEnter, false)
end

def.override("dynamic").OnData = function (self, data)
	if data == nil then
		warn("Can not Open CPanelUIFullScreenTips with no data", debug.traceback())
		return
	end
	if data.Type == EOpenType.BossEnter then
		-- Boss进场
		local title, name = "BossTitle", "BossName"
		if type(data.BossTitle) == "string" then
			title = data.BossTitle
		end
		if type(data.BossName) == "string" then
			name = data.BossName
		end
		self:ShowBossEnter(title, name)
	end
end

def.override("string").OnClick = function (self, id)
	if id == "Btn_ShowPassBoss" then
		-- 显示Boss进场跳过按钮
		GUITools.SetUIActive(self._Btn_PassBoss, true)
		GUITools.SetUIActive(self._Btn_ShowPassBoss, false)
	elseif id == "Btn_PassBossAnimation" then
		-- 跳过Boss进场
		game._DungeonMan:PassBossCameraAnimation()
	end
end

def.method("string", "string").ShowBossEnter = function (self, strTilte, strName)
	GUITools.SetUIActive(self._Frame_BossEnter, true)
	GUITools.SetUIActive(self._Btn_PassBoss, false)
	GUITools.SetUIActive(self._Btn_ShowPassBoss, true)
	GUI.SetText(self._Lab_BossTitle, strTilte)
	GUI.SetText(self._Lab_BossName, strName)
end

def.override().OnDestroy = function (self)
	self._Frame_BossEnter = nil
	self._Btn_ShowPassBoss = nil
	self._Btn_PassBoss = nil
	self._Lab_BossTitle = nil
	self._Lab_BossName = nil
end

CPanelUIFullScreenTips.Commit()
return CPanelUIFullScreenTips