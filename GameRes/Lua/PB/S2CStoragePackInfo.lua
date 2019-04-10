local PBHelper = require "Network.PBHelper"
local CInventory = require "Package.CInventory"
local CPageBag = require"GUI.CPageBag"
local CPanelRoleInfo = require"GUI.CPanelRoleInfo"

-- 上线同步仓库信息
local function OnStoragePackInfo(sender, protocol)
	local pack = game._HostPlayer._Package._StoragePack
	if pack ~= nil then
		pack._EffectSize = protocol.BagData.CurrentUnlockNum
		--warn("_EffectSize =", pack._EffectSize)
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_STORAGE
		for i,v in ipairs(protocol.BagData.Items) do
			local item = CInventory.CreateItem(v)
			item._PackageType = packageType
			pack:UpdateItem(item)
			pack:SortItemList()
		end
	end
end
PBHelper.AddHandler("S2CStoragePackInfo", OnStoragePackInfo)

--仓库装卸结果
local function OnStoragePackChangeRes(sender, protocol)
	if CPanelRoleInfo.Instance():IsShow() and CPanelRoleInfo.Instance()._CurPageType == CPanelRoleInfo.PageType.BAG then 
		if protocol.ErrorCode ~= 0 then 
			CPageBag.Instance():FailStorageActive(protocol.ErrorCode)
		end
	end
	-- body
end
PBHelper.AddHandler("S2CStoragePackChangeRes", OnStoragePackChangeRes)

--解锁结果
local function OnStoragePackUnlockRes ( sender, protocol )
	if CPanelRoleInfo.Instance():IsShow() and CPanelRoleInfo.Instance()._CurPageType == CPanelRoleInfo.PageType.BAG then 
		if protocol.ErrorCode == 0 then 
			CPageBag.Instance():UnlockStoragePage()
		else
			CPageBag.Instance():FailStorageActive(protocol.ErrorCode)
		end
	end
	-- body
end 
PBHelper.AddHandler("S2CStoragePackUnlockRes", OnStoragePackUnlockRes)
