local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local ERROR_CODE = require "PB.data".ServerMessageEquip
local EquipProcessingChangeEvent = require "Events.EquipProcessingChangeEvent"

local function RaiseEquipProcessingChangeEvent()
	local event = EquipProcessingChangeEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

--协议名称
local function OnS2CItemRefine(sender,protocol)
--warn("=============OnS2CItemRefine=============", protocol.result)
	if protocol.result == 0 then
		local pack = game._HostPlayer._Package._EquipPack
		local itemData = pack:GetItemBySlot( protocol.Index )
		if itemData == nil then return end

		itemData:SetRefineLevel(protocol.RefineLevel)

		RaiseEquipProcessingChangeEvent()
		TeraFuncs.SendFlashMsg(StringTable.Get(10957), false)
	elseif protocol.result == ERROR_CODE.ItemRefineFaild then
		TeraFuncs.SendFlashMsg(StringTable.Get(10956), false)
		RaiseEquipProcessingChangeEvent()
	end
end
PBHelper.AddHandler("S2CItemRefine", OnS2CItemRefine)