--
-- S2CItemDevResult
--
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local net = require "PB.net"
local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local EquipProcessingChangeEvent = require "Events.EquipProcessingChangeEvent"
local ERROR_CODE = require "PB.data".ServerMessageEquip
local BAGTYPE = require "PB.net".BAGTYPE
local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
local EItemDev = require "PB.data".ItemDev
local CElementData = require "Data.CElementData"

local function SendEquipProcessResult(devTpye, bSuccess)
    local str = string.format("%s%s", StringTable.Get(31350+devTpye-1), StringTable.Get(bSuccess and 10914 or 10915))
    TeraFuncs.SendFlashMsg(str)
end

local function SendMsgToSysteamChannel(msg)
    local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
    local ChatManager = require "Chat.ChatManager"

    ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
end

local function RaiseEvent(protocol)
	local event = EquipProcessingChangeEvent()
	event._Msg = protocol

    CGame.EventManager:raiseEvent(nil, event)
end

local function OnS2CItemDevResult(sender, protocol)
	-- warn("OnS2CItemDevResult--------------",protocol.devTpye, "ERROR_CODE = ", protocol.result)
    do  
        if protocol.BagType == BAGTYPE.ROLE_EQUIP and protocol.itemCell.Index == EEquipmentSlot.Weapon then
            local lv = protocol.itemCell.ItemData.InforceLevel
            
            local role = game._CurWorld:FindObject( protocol.RoleId )
            if role ~= nil then
                role:UpdateEquipments(protocol.itemCell.Index,protocol.itemCell.ItemData.Tid,lv)
                CPanelRoleInfo.Instance():UpdateWeaponFx()
            end
        end
    end

    if game._HostPlayer._ID ~= protocol.RoleId then return end

    if protocol.devTpye == EItemDev.REBUILDCONFIRM then
        --重铸保存
        SendMsgToSysteamChannel(StringTable.Get(31323))
    elseif protocol.devTpye == EItemDev.QUENCH then
        --淬火 
        SendMsgToSysteamChannel(StringTable.Get(31324))
    elseif protocol.devTpye == EItemDev.SURMOUNT then
        --突破
        SendMsgToSysteamChannel(StringTable.Get(31325))
    elseif protocol.devTpye == EItemDev.REFINE then
        --精炼
        local refineLv = protocol.itemCell.ItemData.RefineLevel
        local template = CElementData.GetTemplate("Item", protocol.itemCell.ItemData.Tid)
        if template == nil then return end
        
        local name = RichTextTools.GetQualityText(template.TextDisplayName, template.InitQuality)
        local str = string.format(StringTable.Get(31326), name, refineLv)

        SendMsgToSysteamChannel(str)
        --[[ 取消装备强化和转化的错误系统提示
    elseif protocol.devTpye == EItemDev.TALENTCHANGE then
        local template = CElementData.GetTemplate("Item", protocol.itemCell.ItemData.Tid)
        local name = RichTextTools.GetQualityText(template.TextDisplayName, template.InitQuality)
        local talentTemplate = CElementData.GetTemplate("Talent", protocol.itemCell.ItemData.TalentId)
        local talentName = RichTextTools.GetQualityText(talentTemplate.Name,talentTemplate.InitQuality)
        local str = string.format(StringTable.Get(31327), name, talentName)

        SendMsgToSysteamChannel(str)
    elseif protocol.devTpye == EItemDev.INFORCE then
        if protocol.result == ERROR_CODE.EquipInforceFaild or 
           protocol.result == ERROR_CODE.EquipInforceFaildDown then
            local inforceLevel = protocol.itemCell.ItemData.InforceLevel
            local template = CElementData.GetTemplate("Item", protocol.itemCell.ItemData.Tid)
            local name = RichTextTools.GetQualityText(template.TextDisplayName, template.InitQuality)
            -- local str = string.format(StringTable.Get(31329), name, inforceLevel)

            -- SendMsgToSysteamChannel(str)
        elseif protocol.result == ERROR_CODE.EquipInforceFaildButSafe then
            local template = CElementData.GetTemplate("Item", protocol.itemCell.ItemData.Tid)
            local name = RichTextTools.GetQualityText(template.TextDisplayName, template.InitQuality)
            local str = string.format(StringTable.Get(31330), name)

            SendMsgToSysteamChannel(str)
        else
            local inforceLevel = protocol.itemCell.ItemData.InforceLevel
            local template = CElementData.GetTemplate("Item", protocol.itemCell.ItemData.Tid)
            local name = RichTextTools.GetQualityText(template.TextDisplayName, template.InitQuality)
            local str = string.format(StringTable.Get(31328), name, inforceLevel)
            SendMsgToSysteamChannel(str)
        end
        ]]
    elseif protocol.devTpye == EItemDev.INHERIT then
        local str = StringTable.Get(31336)
        SendMsgToSysteamChannel(str)
    elseif protocol.devTpye == EItemDev.TALENTCHANGECONFIRM then
        --传奇属性保存
        SendMsgToSysteamChannel(StringTable.Get(31344))
    elseif protocol.devTpye == EItemDev.TALENTCHANGECANCEL then

    end

    if protocol.result ~= 0 and
       protocol.result ~= ERROR_CODE.EquipInforceFaild and
       protocol.result ~= ERROR_CODE.EquipInforceFaildButSafe and
       protocol.result ~= ERROR_CODE.EquipInforceFaildDown then
        game._GUIMan:ShowErrorCodeMsg(protocol.result, nil)
    end
        
    RaiseEvent(protocol)
end
PBHelper.AddHandler("S2CItemDevResult", OnS2CItemDevResult)