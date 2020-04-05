 --
-- S2CInventoryInfo
--

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
	end
end

PBHelper.AddHandler("S2CBackpackInfo", OnBackpackInfo)