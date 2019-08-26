
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelEquipChange = Lplus.Extend(CPanelBase, 'CPanelEquipChange')
local def = CPanelEquipChange.define

def.field("userdata")._LabFight = nil
def.field("table")._ItemSet = nil 
def.field("boolean")._IsShowBox = false           -- 替换装备中存在为穿戴的才会弹窗提示

local instance = nil
def.static('=>', CPanelEquipChange).Instance = function ()
    if not instance then
        instance = CPanelEquipChange()
        instance._PrefabPath = PATH.UI_EquipChange
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
    end
    return instance
end

local function SetEquipmentInfo(self,equipmentObj, equipPack, fightScore)
    if equipmentObj == nil then return end
    for i,item in ipairs( equipPack ) do
        local index = item._Slot
        
        local bGotEquip = item._Tid > 0
        local ui_equip = equipmentObj:FindChild("Equipment/".. EnumDef.RoleEquipSlotImg[index])

        local frame_setting =
        {
            [EFrameIconTag.EmptyEquip] = bGotEquip and -1 or item._Slot,
            [EFrameIconTag.ItemIcon] = bGotEquip,
        }
        IconTools.SetFrameIconTags(ui_equip, frame_setting)
        local star = 0 
        if bGotEquip then
            local setting =
            {
                [EItemIconTag.Bind] = item._IsBind,
                [EItemIconTag.ArrowUp] = item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_PACK,
                [EItemIconTag.Equip] = item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK,
                [EItemIconTag.Grade] = item._BaseAttrs.Star,

            }
            IconTools.InitItemIconNew(ui_equip, item._Tid, setting)
            if not self._IsShowBox and not item._IsBind then 
                self._IsShowBox = true
            end
        end
    end

    local labelScore = equipmentObj:FindChild("Img_FighScoreBG/Lab_FightScore_Data")
    GUI.SetText(labelScore, GUITools.FormatNumber(fightScore))
end

local function C2SPutOnEquip(self)
    for i,itemData in ipairs(self._ItemSet) do
        local bGotEquip = itemData._Tid > 0
        if bGotEquip then 
            if itemData._PackageType == IVTRTYPE_ENUM.IVTRTYPE_PACK then 
                local C2SEquipPuton = require "PB.net".C2SEquipPuton
                local protocol = C2SEquipPuton()
                protocol.Index = itemData._BagSlot
                --protocol.IsInherit = isInherit
                SendProtocol(protocol)
            end
        end
    end
end
 
def.override().OnCreate = function(self)
    self._LabFight = self:GetUIObject("Lab_oldFight")
end

def.override("dynamic").OnData = function(self,data)
    local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
    self._ItemSet = data.NewEquipBack
    self._IsShowBox = false
    GUI.SetText(self._LabFight,GUITools.FormatMoney(game._HostPlayer:GetHostFightScore()))
    SetEquipmentInfo(self,self._Panel, data.NewEquipBack,data.NewFightValue )
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Cancel' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Ok' then
        if not self._IsShowBox then 
            C2SPutOnEquip(self)
            game._GUIMan:CloseByScript(self)
        return end
        local function callback(value)
            if value then
                C2SPutOnEquip(self)
                game._GUIMan:CloseByScript(self)
            end
        end 
        local title, msg,closeType = StringTable.GetMsg(87)
        MsgBox.ShowMsgBox(msg,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
    end
end

def.override().OnDestroy = function(self)
    instance = nil 
end

CPanelEquipChange.Commit()
return CPanelEquipChange