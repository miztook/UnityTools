local PBHelper = require "Network.PBHelper"
local CInventory = require "Package.CInventory"

-- 上线同步任务Item信息
local function OnQuestPackInfo(sender, protocol)
	local pack = game._HostPlayer._Package._TaskItemPack
	if pack ~= nil then
		pack._EffectSize = protocol.BagData.CurrentUnlockNum
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_STORAGE
		for i,v in ipairs(protocol.BagData.Items) do
			local item = CInventory.CreateItem(v)
			item._PackageType = packageType
			pack:UpdateItem(item)
			pack:SortItemList()
		end
	end
end

PBHelper.AddHandler("S2CQuestPackInfo", OnQuestPackInfo)