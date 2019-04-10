
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelAutoKillTips = Lplus.Extend(CPanelBase, 'CPanelAutoKillTips')
local def = CPanelAutoKillTips.define
 
def.field('userdata')._FramePosition = nil
def.field('userdata')._Lab_Des = nil
local instance = nil
def.static('=>', CPanelAutoKillTips).Instance = function ()
	if not instance then
        instance = CPanelAutoKillTips()
        instance._PrefabPath = PATH.UI_AutoKillTips
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._FramePosition = self:GetUIObject("Frame_Position")
    self._Lab_Des = self:GetUIObject("Lab_Des")
end

def.override("dynamic").OnData = function(self, data) 
    GameUtil.SetTipsPosition(data._Obj,self._FramePosition)
     
    GUI.SetText(self._Lab_Des, StringTable.Get(580))
end

def.method().Hide = function(self)
	self._Lab_Des = nil
end
CPanelAutoKillTips.Commit()
return CPanelAutoKillTips