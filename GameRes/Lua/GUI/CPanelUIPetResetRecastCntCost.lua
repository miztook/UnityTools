local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"

local CPanelUIPetResetRecastCntCost = Lplus.Extend(CPanelBase, 'CPanelUIPetResetRecastCntCost')
local def = CPanelUIPetResetRecastCntCost.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._PetData = nil
def.field("boolean")._EnoughMaterial = false
def.field("function")._CallBack = nil

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local instance = nil
def.static('=>', CPanelUIPetResetRecastCntCost).Instance = function ()
    if not instance then
        instance = CPanelUIPetResetRecastCntCost()
        instance._PrefabPath = PATH.UI_PetResetRecastCntCost
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PetData = data.data
            self._CallBack = data.callback
        end

        CPanelBase.OnData(self,data)
    end

    local title, msg, closeType = StringTable.GetMsg(89)

    local info = CPetUtility.GetRecastNeedInfo()
    local MaterialId = info[1]
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local MaterialHave = pack:GetItemCount( MaterialId )
    local MaterialNeed = info[2]
    self._EnoughMaterial = (MaterialHave >= MaterialNeed) 

    local template = CElementData.GetTemplate("Item", MaterialId)
    local name = RichTextTools.GetQualityText(self._PetData:GetNickName(), self._PetData:GetQuality()) .. string.format(StringTable.Get(19073), self._PetData:GetLevel())
    -- local lv = template.InitLevel
    local msgObj = self:GetUIObject('Lab_Message')
    -- local size = GUITools.GetTextSize(msgObj)
    
    -- if size ~= nil and lv > 0 then
    --     local strLv = string.format(StringTable.Get(19073), lv)
    --     strLv = GUITools.FormatRichTextSize(size-2, strLv)
    --     name = name..strLv
    -- end

    local starLevel = nil
    if self._PetData._Stage == 1 then
        starLevel = StringTable.Get(19161)
    elseif self._PetData._Stage == 2 then
        starLevel = StringTable.Get(19162)
    elseif self._PetData._Stage == 3 then
        starLevel = StringTable.Get(19163)
    elseif self._PetData._Stage == 4 then
        starLevel = StringTable.Get(19164)
    elseif self._PetData._Stage == 5 then
        starLevel = StringTable.Get(19165)
    else
        starLevel = StringTable.Get(19166)
    end

    local msg = string.format(msg, starLevel, name)
    GUI.SetText(self:GetUIObject('Lab_MsgTitle'), title)
    GUI.SetText(msgObj, msg)

    local item = self:GetUIObject('RecastNeed')
    -- local Img_Quality = item:FindChild("Img_Quality")
    -- local Img_ItemIcon = item:FindChild("Img_ItemIcon")
    -- local Lab_Lv = item:FindChild("Lab_Num")

    -- local strMaterialHave = RichTextTools.GetNeedColorText(tostring(MaterialHave), MaterialHave >= MaterialNeed)
    -- GUITools.SetIcon(Img_ItemIcon, template.IconAtlasPath)
    -- warn("=================>>>>", template.InitQuality)
    -- GUITools.SetGroupImg(Img_Quality, template.InitQuality)
    -- GUI.SetText(Lab_Lv, string.format("%s/%s", strMaterialHave, MaterialNeed))

    IconTools.InitMaterialIconNew(item, MaterialId, MaterialNeed)
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Yes' then
        if self._EnoughMaterial then
            if self._CallBack ~= nil then
                self._CallBack()
            end
        else
            SendFlashMsg(StringTable.Get(10901), false)
        end

        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        game._GUIMan:CloseByScript(self)
    elseif id == "RecastNeed" then
        local info = CPetUtility.GetPetResetRecastCountItem()
        local MaterialId = info[1]
        CItemTipMan.ShowItemTips(MaterialId, 
                             TipsPopFrom.OTHER_PANEL, 
                             self:GetUIObject('RecastNeed'), 
                             TipPosition.FIX_POSITION)
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelUIPetResetRecastCntCost.Commit()
return CPanelUIPetResetRecastCntCost