
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelReputationTips = Lplus.Extend(CPanelBase, 'CPanelReputationTips')
local def = CPanelReputationTips.define
 
def.field('table')._Lab_ReputationLvNames = nil
def.field('table')._Lab_ReputationLvValues = nil
def.field('userdata')._FramePosition = nil
local instance = nil
def.static('=>', CPanelReputationTips).Instance = function ()
	if not instance then
        instance = CPanelReputationTips()
        instance._PrefabPath = PATH.UI_ReputationLvTips
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._FramePosition = self:GetUIObject("Frame_Position")
    self._Lab_ReputationLvNames = {}
    for i = 1,5 do
        self._Lab_ReputationLvNames[i] = self: GetUIObject("Lab_ReputationLvName"..i)
    end

    self._Lab_ReputationLvValues = {}
    for i = 1,5 do
        self._Lab_ReputationLvValues[i] = self: GetUIObject("Lab_ReputationLvValue"..i)
    end
end

def.override("dynamic").OnData = function(self, data) 
    -- for i = 1,5 do
    --     self._Lab_ReputationLvValues[i] = self: GetUIObject("Lab_ReputationLvValue"..i)
    --     GUI.SetText(self._Lab_ReputationLvValues[i],name)
    -- end
    local template = CElementData.GetTemplate("Reputation", data._RepID)
    GUI.SetText(self._Lab_ReputationLvValues[1],tostring(GUITools.FormatNumber(template.ReputationLevelExp1)))
    GUI.SetText(self._Lab_ReputationLvValues[2],tostring(GUITools.FormatNumber(template.ReputationLevelExp2)))
    GUI.SetText(self._Lab_ReputationLvValues[3],tostring(GUITools.FormatNumber(template.ReputationLevelExp3)))
    GUI.SetText(self._Lab_ReputationLvValues[4],tostring(GUITools.FormatNumber(template.ReputationLevelExp4)))
    GUI.SetText(self._Lab_ReputationLvValues[5],tostring(GUITools.FormatNumber(template.ReputationLevelExp5)))

    --GameUtil.SetTipsPosition(data._Obj,self._FramePosition)
end

def.method().Hide = function(self)

end
CPanelReputationTips.Commit()
return CPanelReputationTips