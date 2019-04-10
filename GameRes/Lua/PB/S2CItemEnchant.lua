--
-- S2CEnchant   装备加工 --> 附魔
--

local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local ServerMessageEquip = require "PB.data".ServerMessageEquip
local CGame = Lplus.ForwardDeclare("CGame")
local EquipDevEvent = require "Events.EquipDevEvent"
local CElementData = require "Data.CElementData"
-- ItemEnchantReelDoNotUse 	= 800;		// 附魔卷轴不可用
-- 	ItemEnchantAttrTooLow 		= 801; 		// 附魔属性低于以前
-- 	ItemDoNotEnchant 			= 802; 		// 该装备不可附魔

local ResultCode = function(protocol, msg)
    local errorCode = ""
    if protocol.result == ServerMessageEquip.ItemEnchantReelDoNotUse then
        errorCode = msg..StringTable.Get(10930)
    elseif protocol.result == ServerMessageEquip.ItemEnchantAttrTooLow then
        errorCode = msg..StringTable.Get(10931)
    elseif protocol.result == ServerMessageEquip.ItemDoNotEnchant then
        errorCode = msg..StringTable.Get(10932)
    else
        errorCode = msg..StringTable.Get(10915)
    end
    game._GUIMan:ShowTipText(errorCode, false)
end

--附魔结果
local function OnS2CItemEnchant(sender, msg)
    -- warn("S2CItemEnchant msg.result == ", msg.result, msg.Index, msg.ReelTid, msg.Attr.index, msg.Attr.value)
    local cellUpType = msg.UpTpye
	local EEquipCellUpType = require "PB.data".EEquipCellUpType

	if msg.result ~= 0 then
        -- 附魔失败
        local failed = StringTable.Get(10926)..StringTable.Get(10915)..","
        ResultCode(msg, failed)
        if msg.result ~= ServerMessageEquip.ItemEnchantAttrTooLow then return end
    else
        local pack = game._HostPlayer._Package._EquipPack
        local Item = pack:GetItemBySlot(msg.Index)
        if Item == nil then return end
        -- warn("lidaming msg.AttrValue ------> ", msg.AttrValue)
        -- 附魔成功提示，并且刷新当前附魔属性
        local fightElement = CElementData.GetPropertyInfoById(msg.AttrIndex)

        local errorCode = StringTable.Get(10926)..StringTable.Get(10914)..","..string.format(StringTable.Get(10935), fightElement.Name , msg.AttrValue)
        game._GUIMan:ShowTipText(errorCode, false)

        --更新UI
        local CPanelUIEquip = require "GUI.CPanelUIEquip"
        if CPanelUIEquip.Instance():IsShow() then
            CPanelUIEquip.Instance():UpdatePanel()
        end
	end
end
PBHelper.AddHandler("S2CItemEnchant", OnS2CItemEnchant)