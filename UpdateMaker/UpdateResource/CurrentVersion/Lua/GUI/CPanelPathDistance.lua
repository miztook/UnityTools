local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelPathDistance = Lplus.Extend(CPanelBase, "CPanelPathDistance")
local def = CPanelPathDistance.define

def.field("userdata")._LabPathDistance = nil
def.field("userdata")._FrameMain = nil

local MAX_HINT_WIDTH = 272

local instance = nil
def.static("=>",CPanelPathDistance).Instance = function()
    if instance == nil then
        instance = CPanelPathDistance()
        instance._PrefabPath = PATH.UI_PathDistance
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._LabPathDistance = self:GetUIObject("Lab_Distance")
    self._FrameMain = self:GetUIObject("Frame_Main")
end

def.override("dynamic").OnData = function(self,data)
    if data == nil then
        game._GUIMan:Close(self)
    end
    local nRet = math.round(data.Value)
    GUI.SetText(self._LabPathDistance,string.format(StringTable.Get(30001),nRet))
    -- self._FrameMain.localPosition = data.Position
end

def.method("table").UpdateData = function(self,data)
    if self._FrameMain == nil then return end
    self._FrameMain:SetActive(true)
    -- self._FrameMain.localPosition = data.Position
    local nRet = math.round(data.Value)
    GUI.SetText(self._LabPathDistance,string.format(StringTable.Get(30001),nRet))
end

def.method().Clear = function(self)
    if self._FrameMain == nil then return end
    if self._FrameMain.activeSelf then 
        self._FrameMain:SetActive(false)
    end
end

def.override().OnDestroy = function(self)
    self._FrameMain = nil 
    self._LabPathDistance = nil 
    instance = nil 
end

CPanelPathDistance.Commit()
return CPanelPathDistance