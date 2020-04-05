--
-- S2CBackpackEquipInfo
--

local PBHelper = require "Network.PBHelper"
local net = require "PB.net"
local Data = require "PB.data"
local CUIMan = require "GUI.CUIMan"
local CElementData = require "Data.CElementData"
local CInventory = require "Package.CInventory"

local function OnUpdateItemInfo(sender, protocol)
	local package = game._HostPlayer._Package
	local normalPack = package._NormalPack
	local data = protocol.UpdateItems
	
	if protocol.BagType == net.BAGTYPE.BACKPACK then
		local tids = {}
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_PACK
		for i,v in ipairs(data) do
			local item = CInventory.CreateItem(v.UpdateItem)
			item._IsNewGot = (v.Src ~= Data.ENUM_ITEM_SRC.NULL)
			item._PackageType = packageType
			normalPack:UpdateItem(item)
			normalPack:SortItemList()

			tids[#tids + 1] = v.UpdateItem.ItemData.Tid
		end
		
		do
			local Lplus = require "Lplus"
			local CGame = Lplus.ForwardDeclare("CGame")
			local GainNewItemEvent = require "Events.GainNewItemEvent"
			for _, v in ipairs(protocol.UpdateItems) do
				do
					local event = GainNewItemEvent()
					event.ItemUpdateInfo = v
					event.BagType = protocol.BagType
					CGame.EventManager:raiseEvent(nil, event)
				end
			end
		end
	elseif protocol.BagType == net.BAGTYPE.ROLE_EQUIP then
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK
		for i,v in ipairs(data) do
			local item = CInventory.CreateItem(v.UpdateItem)
			item._PackageType = packageType
			package._EquipPack:UpdateItem(item)
		end

		
	else
		-- TODO
	end	
	
	do
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    event.PackageType = protocol.BagType
	    event.ItemTids = tids
	    CGame.EventManager:raiseEvent(nil, event)
	end
end

PBHelper.AddHandler("S2CUpdateItemInfo", OnUpdateItemInfo)