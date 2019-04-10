
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelChangeName = Lplus.Extend(CPanelBase, 'CPanelChangeName')
local PBHelper = require "Network.PBHelper"
local def = CPanelChangeName.define
 
def.field('userdata')._LabDes = nil
def.field('userdata')._CostItem = nil
def.field("number")._TotalNum = 0
def.field("number")._CostNum = 0
def.field("userdata")._InputField = nil 
def.field("number")._CostTid = 0

local instance = nil
def.static('=>', CPanelChangeName).Instance = function ()
	if not instance then
        instance = CPanelChangeName()
        instance._PrefabPath = PATH.UI_ChangeName
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end

local function CheckName(self,text)
    if IsNilOrEmptyString(text) then 
        game._GUIMan:ShowTipText(StringTable.Get(310),false)
        return false
    end
    local Length = GameUtil.GetStringLength(text)
    -- 最短字符定为 4, 最长字符定为 14
    if Length < GlobalDefinition.MinRoleNameLength or Length > GlobalDefinition.MaxRoleNameLength then
        game._GUIMan:ShowTipText(StringTable.Get(311),false)
        return false
    end
    local FilterMgr = require "Utility.BadWordsFilter".Filter
    local strMsg = FilterMgr.FilterName(text)
    if strMsg ~= text then
        game._GUIMan:ShowTipText(StringTable.Get(30317),false)
        return false
    end
    return true
end


def.override().OnCreate = function(self)
    self._LabDes = self:GetUIObject("Lab_Des")
    self._CostItem = self:GetUIObject("MaterialIcon")
    self._InputField = self:GetUIObject("InputField"):GetComponent(ClassType.InputField)
end

-- panelData = {CostTid ,CostNum,Name,LimitNum,CallBack}
def.override("dynamic").OnData = function(self,data)
    local costTid = tonumber(CElementData.GetSpecialIdTemplate(495).Value)
    local str = string.format(StringTable.Get(31501), game._HostPlayer._InfoData._Name )
    GUI.SetText(self._LabDes,str)
    self._CostNum = 1
    self._CostTid = costTid
    self._TotalNum = game._HostPlayer._Package._NormalPack:GetItemCount(self._CostTid)
    IconTools.InitMaterialIconNew(self._CostItem, self._CostTid, self._CostNum)

end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Ok" then 
        if self._CostNum <= self._TotalNum then
            if not CheckName(self,self._InputField.text) then return end
            local C2SChangeNameReq = require "PB.net".C2SChangeNameReq
            local protocol = C2SChangeNameReq()
            local net = require "PB.net"
            protocol.NewName = self._InputField.text
            PBHelper.Send(protocol)
            game._GUIMan:CloseByScript(self)
        else
            local itemTemp = CElementData.GetItemTemplate(self._CostTid)
            if itemTemp ~= nil then
                local text = string.format(StringTable.Get(309),itemTemp.TextDisplayName)
                game._GUIMan:ShowTipText(text,false) 
                -- game._GUIMan:CloseByScript(self)
            end
        end
    elseif id == "Btn_Material" then
        CItemTipMan.ShowItemTips(self._CostTid, TipsPopFrom.OTHER_PANEL, self._CostItem, TipPosition.FIX_POSITION)
    elseif id == "Btn_Cancel" or id == "Btn_Close" then 
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnDestroy = function(self)
    instance = nil 
end

CPanelChangeName.Commit()
return CPanelChangeName