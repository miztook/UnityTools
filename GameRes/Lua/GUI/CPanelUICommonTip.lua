-- 出入的data需要满足以下格式。
--[[
    data = {
        _Obj = item,
        _Title = "",
        _Des = "",
    }
]]
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUICommonTip = Lplus.Extend(CPanelBase, 'CPanelUICommonTip')
local def = CPanelUICommonTip.define
 
def.field('userdata')._FramePosition = nil
def.field('userdata')._Lab_Des = nil
def.field("userdata")._Lab_Title = nil
local instance = nil
def.static('=>', CPanelUICommonTip).Instance = function ()
	if not instance then
        instance = CPanelUICommonTip()
        instance._PrefabPath = PATH.UI_CommonTips
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._FramePosition = self:GetUIObject("Frame_Position")
    self._Lab_Des = self:GetUIObject("Lab_Des")
    self._Lab_Title = self:GetUIObject("Lab_Title")
end

def.override("dynamic").OnData = function(self, data)
    GUI.SetText(self._Lab_Title, data._Title)
    GUI.SetText(self._Lab_Des, data._Des)
    if data._Obj ~= nil then
        GameUtil.SetTipsPosition(data._Obj,self._FramePosition)
    end
end

def.method().Hide = function(self)
    self._FramePosition = nil
	self._Lab_Des = nil
    self._Lab_Title = nil
end
CPanelUICommonTip.Commit()
return CPanelUICommonTip