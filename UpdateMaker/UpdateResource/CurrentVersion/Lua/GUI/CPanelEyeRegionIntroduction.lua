
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelEyeRegionIntroduction = Lplus.Extend(CPanelBase, 'CPanelEyeRegionIntroduction')
local def = CPanelEyeRegionIntroduction.define

def.field("userdata")._LabInstruction = nil 
def.field("table")._SingleTemp = nil 
def.field("table")._MultiplayerTemp = nil 
def.field("table")._SingleData = nil
def.field("table")._MultiplayerData = nil
def.field("userdata")._LabCount = nil 

local instance = nil
def.static('=>', CPanelEyeRegionIntroduction).Instance = function ()
	if not instance then
        instance = CPanelEyeRegionIntroduction()
        instance._PrefabPath = PATH.UI_EyeRegionIntroduction
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._LabInstruction = self:GetUIObject("Lab_Introduction")
    self._LabCount = self:GetUIObject("Lab_Count")
end

def.override("dynamic").OnData = function(self,data)
    local singleInstruction = CSpecialIdMan.Get("EyeRegionSingle")
    local multiplayerInstruction = CSpecialIdMan.Get("EyeRegionMultiPlayer")
    local singleId = CSpecialIdMan.Get("EyeRegionSingleFuncId")
    local multiplayerId = CSpecialIdMan.Get("EyeRegionMultiPlayerFuncId")
    self._SingleData = game._CCalendarMan:GetCalendarDataByID(tonumber(singleId))
    self._MultiplayerData = game._CCalendarMan:GetCalendarDataByID(tonumber(multiplayerId))
    self._SingleTemp = CElementData.GetTemplate("DungeonIntroductionPopup", singleInstruction)
    self._MultiplayerTemp = CElementData.GetTemplate("DungeonIntroductionPopup", multiplayerInstruction)
    GUI.SetText(self._LabInstruction,self._SingleTemp.Introduction)
    if  self._SingleData == nil or self._MultiplayerData == nil then 
        warn("Get Calendar data is nil ")
        return
    end
    if self._SingleData._PlayCurNum == 0 then
        -- 剩余次数变红
        GUI.SetText(self._LabCount, string.format(StringTable.Get(20081), self._SingleData._PlayCurNum, self._SingleData._PlayMaxNum))
    elseif self._SingleData._PlayCurNum > 0 then
        -- 剩余次数大于初始最大次数时变绿
        GUI.SetText(self._LabCount, string.format(StringTable.Get(20082), self._SingleData._PlayCurNum, self._SingleData._PlayMaxNum))
    end

end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if id == 'Rdo_Single' then
        GUI.SetText(self._LabInstruction,self._SingleTemp.Introduction)
        if self._SingleData._PlayCurNum == 0 then
            -- 剩余次数变红
            GUI.SetText(self._LabCount, string.format(StringTable.Get(20081), self._SingleData._PlayCurNum, self._SingleData._PlayMaxNum))
        elseif self._SingleData._PlayCurNum > 0 then
            -- 剩余次数大于初始最大次数时变绿
            GUI.SetText(self._LabCount, string.format(StringTable.Get(20082), self._SingleData._PlayCurNum, self._SingleData._PlayMaxNum))
        else
            GUI.SetText(self._LabCount, self._SingleData._PlayCurNum.."/"..self._SingleData._PlayMaxNum)
        end
    elseif id == "Rdo_Multiplayer" then 
        GUI.SetText(self._LabInstruction,self._MultiplayerTemp.Introduction)
        warn("pppppppppppppp",self._MultiplayerData._PlayCurNum,self._MultiplayerData._PlayMaxNum)
        if self._MultiplayerData._PlayCurNum == 0 then
            -- 剩余次数变红
            GUI.SetText(self._LabCount, string.format(StringTable.Get(20081), self._MultiplayerData._PlayCurNum, self._MultiplayerData._PlayMaxNum))
        elseif self._MultiplayerData._PlayCurNum > 0 then
            -- 剩余次数大于初始最大次数时变绿
            GUI.SetText(self._LabCount, string.format(StringTable.Get(20082), self._MultiplayerData._PlayCurNum, self._MultiplayerData._PlayMaxNum))
        else
            GUI.SetText(self._LabCount, self._MultiplayerData._PlayCurNum.."/"..self._MultiplayerData._PlayMaxNum)
        end
    end
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Close' then
        game._GUIMan:CloseByScript(self) 
    end

end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelEyeRegionIntroduction.Commit()
return CPanelEyeRegionIntroduction