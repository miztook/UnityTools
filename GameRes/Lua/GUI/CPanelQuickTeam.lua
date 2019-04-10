local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelQuickTeam = Lplus.Extend(CPanelBase, 'CPanelQuickTeam')
local def = CPanelQuickTeam.define

def.field('userdata')._LabMessage = nil
def.field("number")._TargetRoomId = 0
def.field("table")._RoomIds = BlankTable
--本地local记录数据 
--local RoomIds = {}

local instance = nil
def.static('=>', CPanelQuickTeam).Instance = function()
    if not instance then
        instance = CPanelQuickTeam()
        instance._PrefabPath = PATH.UI_QuickTeam
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._LabMessage = self:GetUIObject('Lab_Message')
end

def.override("dynamic").OnData = function (self,data)
    for k,v in pairs(data) do
        self._RoomIds[#self._RoomIds+1] = v
    end
    self:ResetPanel()
end

def.method().ResetPanel = function (self)
    if #self._RoomIds > 0 then
        self._TargetRoomId = self._RoomIds[1]
    end

    local name = ""
    local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", self._TargetRoomId)
    if teamRoomConfig == nil then
        name = StringTable.Get(22401)
    else
        name = teamRoomConfig.DisplayName
    end

    GUI.SetText(self._LabMessage, string.format(StringTable.Get(19157),name))
end
def.override("string").OnClick = function(self, id)
    if id == 'Btn_Yes' then
        self._RoomIds = {}
        game._GUIMan:Open("CPanelUITeamCreate", {TargetMatchId =self._TargetRoomId})
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        if #self._RoomIds > 1 then
            table.remove(self._RoomIds, 1)
            self:ResetPanel()
        else
            self._RoomIds = {}
            game._GUIMan:CloseByScript(self)
        end
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)

end

CPanelQuickTeam.Commit()
return CPanelQuickTeam