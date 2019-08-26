local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'

local CPanelUISanctionPrompt = Lplus.Extend(CPanelBase, 'CPanelUISanctionPrompt')
local def = CPanelUISanctionPrompt.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合

local instance = nil
def.static('=>', CPanelUISanctionPrompt).Instance = function ()
    if not instance then
        instance = CPanelUISanctionPrompt()
        instance._PrefabPath = PATH.UI_SanctionPrompt
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
end

def.override("dynamic").OnData = function(self,data)
    local lab_title = self:GetUIObject('Lab_MsgTitle')
    local lab_msg1 = self:GetUIObject('Lab_Message1')
    local lab_msg2 = self:GetUIObject('Lab_Message2')

    warn("data.SanctionTime = ", data.SanctionTime)

    local title = StringTable.Get(34500)
    local time=string.gsub(data.SanctionTime,"-","/")
    local msg1 = StringTable.Get(34501)
    msg1 = string.format(msg1,time)
    local msg2 = StringTable.Get(34502)

    GUI.SetText(lab_title, title)
    GUI.SetText(lab_msg1, msg1)
    GUI.SetText(lab_msg2, msg2)

    CPanelBase.OnData(self,data)
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Yes' then
        game._GUIMan:CloseByScript(self)
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelUISanctionPrompt.Commit()
return CPanelUISanctionPrompt