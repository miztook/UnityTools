 --
-- S2CInventoryInfo
--

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local PBHelper = require "Network.PBHelper"
local CInventory = require "Package.CInventory"

local function OnBackpackInfo(sender, protocol)
	local pack = game._HostPlayer._Package._NormalPack
	if pack ~= nil then
		pack._EffectSize = protocol.BagData.CurrentUnlockNum
		--warn("_EffectSize =", pack._EffectSize)
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_PACK
		for i,v in ipairs(protocol.BagData.Items) do
			local item = CInventory.CreateItem(v)
			item._PackageType = packageType
			pack:UpdateItem(item)
			pack:SortItemList()
		end
		local CPanelMainChat = require "GUI.CPanelMainChat"
		CPanelMainChat.Instance():SetBagCapacityLast(#game._HostPlayer._Package._NormalPack._ItemSet / game._HostPlayer._Package._NormalPack._EffectSize )

		local NotifyBagCapacityEvent = require "Events.NotifyBagCapacityEvent"
		local event = NotifyBagCapacityEvent()
		event.Value=#game._HostPlayer._Package._NormalPack._ItemSet / game._HostPlayer._Package._NormalPack._EffectSize
		CGame.EventManager:raiseEvent(nil, event)

	end
end

PBHelper.AddHandler("S2CBackpackInfo", OnBackpackInfo)