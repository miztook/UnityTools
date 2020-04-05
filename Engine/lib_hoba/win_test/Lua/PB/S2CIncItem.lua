--
-- S2CIncItem
--

local PBHelper = require "Network.PBHelper"

local function OnIncreaseItem( sender,msg )
	local pack = game._HostPlayer._Package._NormalIvtrs[msg.Location]
	if pack == nil then
		return
	end

	local idx = msg.Index + 1
	local item = pack._ItemSet[idx]
	if item == nil then
		--itemTid, expire_date, normal_count, bind_count,state,content
		--item = CreateItem(msg.ItemTid, 0, msg.IncCount, 0, 1, msg.Content)
		TODO("功能未实现")
		if item == nil then return end
		pack._ItemCount = pack._ItemCount + 1
	else
		item._NormalCount = mag.IncCount + item._NormalCount
	end

	pack:SetItem(idx, item)

	do
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    local net = require "PB.net"
	    event.PackageType = net.BAGTYPE.BACKPACK
	    CGame.EventManager:raiseEvent(nil, event)
	end
end

PBHelper.AddHandler("S2CIncItem", OnIncreaseItem)