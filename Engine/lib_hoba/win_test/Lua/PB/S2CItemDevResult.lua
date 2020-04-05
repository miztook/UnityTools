--
-- S2CItemDevResult
--
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local net = require "PB.net"

local PBHelper = require "Network.PBHelper"

local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end

local RaiseEvent = function(protocol, bIsRebuildSave)
	local EquipDevEvent = require "Events.EquipDevEvent"
    local event = EquipDevEvent()
    event._Msg = protocol
    event._IsRebuildSave = bIsRebuildSave or false
    CGame.EventManager:raiseEvent(nil, event)
end

local DoLogic = function(protocol, msg)
	if protocol.result then--装备养成 成功
		SendFlashMsg(msg.."成功")
	else--装备养成 失败
		SendFlashMsg(msg.."失败")
	end
end

local function OnS2CItemDevResult(sender, protocol)
	local EquipDevEvent = require "Events.EquipDevEvent"
    local event = EquipDevEvent()
    event._Msg = protocol

	local EItemDevType = require "PB.data".ItemDev
	if protocol.devTpye == EItemDevType.ENFORCE then-- 强化
		DoLogic(protocol, "强化")
	elseif protocol.devTpye == EItemDevType.REBUILD then-- 重铸
		DoLogic(protocol, "重铸")
		if protocol.result then
			RaiseEvent(protocol)
		end
	elseif protocol.devTpye == EItemDevType.REBUILDSAVE then
		DoLogic(protocol, "保存")
		if protocol.result then
			if protocol.itemCell == nil then return end

			local pack = game._HostPlayer._Package._EquipPack
			local itemData = pack:GetItemBySlot( protocol.itemCell.Index )
			if itemData == nil then return end

			itemData:CommitRecastConfirm()
			RaiseEvent(protocol, true)
		end
	elseif protocol.devTpye == EItemDevType.INHERIT then-- 继承

	end
end

PBHelper.AddHandler("S2CItemDevResult", OnS2CItemDevResult)