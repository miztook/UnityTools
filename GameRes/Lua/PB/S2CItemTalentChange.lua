--
-- S2CItemTalentChange
--
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local net = require "PB.net"
local PBHelper = require "Network.PBHelper"

local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end

--协议名称
local function OnS2CItemTalentChange(sender,protocol)
--warn("=============OnC2SItemTalentChange=============")
	local pack = game._HostPlayer._Package._EquipPack
	local Item = pack:GetItemBySlot(protocol.Index)
	if Item == nil then return end
	
	Item:SetLegendId(protocol.TalentId)
	Item:SetLegendLevel(protocol.TalentLevel)

	local EquipTalentChangeEvent = require "Events.EquipTalentChangeEvent"
    local event = EquipTalentChangeEvent()
    CGame.EventManager:raiseEvent(nil, event)

	SendFlashMsg(StringTable.Get(10939))
end
PBHelper.AddHandler("S2CItemTalentChange", OnS2CItemTalentChange)