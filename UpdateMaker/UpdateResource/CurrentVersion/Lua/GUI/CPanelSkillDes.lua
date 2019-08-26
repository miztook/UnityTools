
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelSkillDes = Lplus.Extend(CPanelBase, 'CPanelSkillDes')
local def = CPanelSkillDes.define

def.field("userdata")._ImgBg = nil 
def.field("userdata")._LabName = nil 
def.field("userdata")._LabDes = nil 

local instance = nil
def.static('=>', CPanelSkillDes).Instance = function ()
	if not instance then
        instance = CPanelSkillDes()
        instance._PrefabPath = PATH.UI_SkillDes
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
-- local panelData = 
--     {
--         SkillName,
--         SkillDes ,
--         TargetObj ,
--     }

def.override().OnCreate = function(self)
	self._ImgBg  = self:GetUIObject("Img_BG")
	self._LabName = self:GetUIObject("Lab_SkillName")
	self._LabDes = self:GetUIObject("Lab_SkillDes")
end

def.override("dynamic").OnData = function(self, data)
	GUI.SetText(self._LabName,data.SkillName)
	GUI.SetText(self._LabDes,data.SkillDes)
	GameUtil.SetTipsPosition(data.TargetObj, self._ImgBg) 
end

def.override().OnDestroy = function(self)
	instance = nil 
end

CPanelSkillDes.Commit()
return CPanelSkillDes