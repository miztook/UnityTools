local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"

local CPanelUIPetFreeConfirm = Lplus.Extend(CPanelBase, 'CPanelUIPetFreeConfirm')
local def = CPanelUIPetFreeConfirm.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._PetData = nil
def.field("userdata")._ItemList = nil
def.field("table")._RecycleList = BlankTable

local instance = nil
def.static('=>', CPanelUIPetFreeConfirm).Instance = function ()
    if not instance then
        instance = CPanelUIPetFreeConfirm()
        instance._PrefabPath = PATH.UI_PetFreeConfirm
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
    self._ItemList = self:GetUIObject('List_Item'):GetComponent(ClassType.GNewList)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PetData = data
        end

        CPanelBase.OnData(self,data)
    end

    self._RecycleList = CPetUtility.CalcRecycleList(self._PetData)
    self._ItemList:SetItemCount( #self._RecycleList )

    local title, msg, closeType = StringTable.GetMsg(34)
    msg = string.format(msg, self._PetData:GetStage(), 
                             RichTextTools.GetPetNickNameRichText(self._PetData._Tid, self._PetData._NickName, false),
                             tostring(self._PetData._Level))

    local lab_title = self:GetUIObject('Lab_MsgTitle')
    local lab_msg = self:GetUIObject('Lab_Message')
    GUI.SetText(lab_title, title)
    GUI.SetText(lab_msg, msg)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        local itemInfo = self._RecycleList[idx]
        local setting =
        {
            [EItemIconTag.Number] = itemInfo.Count,
        }
        IconTools.InitItemIconNew(item:FindChild("ItemIconNew"), itemInfo.Tid, setting)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        local itemInfo = self._RecycleList[idx]
        CItemTipMan.ShowItemTips(itemInfo.Tid, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 item,
                                 TipPosition.FIX_POSITION)
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Yes' then
        CPetUtility.SendC2SPetSetFree(self._PetData._ID)
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
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

CPanelUIPetFreeConfirm.Commit()
return CPanelUIPetFreeConfirm