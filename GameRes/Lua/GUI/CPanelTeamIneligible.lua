local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local EMatchTeamErrorCode = require "PB.data".EMatchTeamErrorCode
local CTeamMan = require "Team.CTeamMan"
local CPanelBase = require "GUI.CPanelBase"

local CPanelTeamIneligible = Lplus.Extend(CPanelBase, "CPanelTeamIneligible")
local def = CPanelTeamIneligible.define
local instance = nil

def.field(CTeamMan)._TeamMan = nil
def.field("userdata")._List = nil          -- Userdatas
def.field("table")._ListData = BlankTable

def.static('=>', CPanelTeamIneligible).Instance = function ()
	if not instance then
        instance = CPanelTeamIneligible()
        instance._PrefabPath = PATH.UI_TeamIneligible
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._TeamMan = CTeamMan.Instance()
    self._List = self:GetUIObject("List_Group"):GetComponent(ClassType.GNewList)
end

def.override("dynamic").OnData = function(self, data)
    self._ListData = {}

    if data ~= nil then
        for i,v in ipairs(data) do
            local map = {}
            map.MemberInfo = v.memberInfo
            map.Reason = ""

            local err = v.err
            if err == EMatchTeamErrorCode.EMatchTeamMemOffline then
                map.Reason = StringTable.Get(22073)
            elseif err == EMatchTeamErrorCode.EMatchTeamMemLowLevel then
                map.Reason = StringTable.Get(22074)
            elseif err == EMatchTeamErrorCode.EMatchTeamMemDeath then
                map.Reason = StringTable.Get(22075)
            elseif err == EMatchTeamErrorCode.EMatchTeamMemInInstance then
                map.Reason = StringTable.Get(22076)
            elseif err == EMatchTeamErrorCode.EMatchInMassacre then
                map.Reason = StringTable.Get(22077)
            end

            table.insert(self._ListData, map)
        end
    end

    self:UpdateItemList()
end

def.method().UpdateItemList = function(self)
    local count = #self._ListData
    self._List:SetItemCount( count )
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    end
end
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Group" then
        local data = self._ListData[idx]
        local memberInfo = data.MemberInfo
        local reason = data.Reason

        local Img_Head = item:FindChild("Img_Head")
        local Lab_Name = item:FindChild("Lab_Name")
        local Lab_Lv = item:FindChild("Lab_Lv")
        local Lab_Reason = item:FindChild("Lab_Reason")

        local prof_template = CElementData.GetProfessionTemplate(memberInfo.Profession)
        GUITools.SetProfSymbolIcon(Img_Head, prof_template.SymbolAtlasPath)
        GUI.SetText(Lab_Name, memberInfo.Name)
        GUI.SetText(Lab_Lv, string.format(StringTable.Get(10641), memberInfo.Level))
        GUI.SetText(Lab_Reason, reason)
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local idx = index + 1
    if id == "List_Group" then
        if id_btn == "Btn_Kick" then
            local data = self._ListData[idx]
            local memberInfo = data.MemberInfo
            local memberId = memberInfo.RoleId

            self._TeamMan:KickMemberDirectly( memberId )
            table.remove(self._ListData, idx)
            self:UpdateItemList()
        end
    end
end

def.override().OnDestroy = function(self)

end

CPanelTeamIneligible.Commit()
return CPanelTeamIneligible