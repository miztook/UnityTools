--
-- S2CBackpackEquipInfo
--

local PBHelper = require "Network.PBHelper"
local net = require "PB.net"
local Data = require "PB.data"
local CUIMan = require "GUI.CUIMan"
local CElementData = require "Data.CElementData"
local CInventory = require "Package.CInventory"
local EItemOptLockType = require "PB.data".EItemOptLockType
local CPanelEquipHint = require "GUI.CPanelEquipHint"

local function OnUpdateItemInfo(sender, protocol)
	local hp = game._HostPlayer
	local package = hp._Package
	local normalPack = package._NormalPack
	local data = protocol.UpdateItems
	
	local function SendPackageChangeNotify(tidList,decomposedSlots)
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    event.PackageType = protocol.BagType
	    
		if tidList ~= nil then
	    	event.ItemTids = tidList
		end
		if decomposedSlots ~= nil then 
			event.DecomposedSlots = decomposedSlots
		end
	    CGame.EventManager:raiseEvent(nil, event)
	end

	-- 装备红点刷新检测
	local function SendEquipRetDotUpdateNotify()
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local EquipRetDotUpdateEvent = require "Events.EquipRetDotUpdateEvent"
	    local event = EquipRetDotUpdateEvent()

	    CGame.EventManager:raiseEvent(nil, event)
	end
	-- 宠物红点刷新
	local function SendPetRetDotUpdateNotify()
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PetRetDotUpdateEvent = require "Events.PetRetDotUpdateEvent"
	    local event = PetRetDotUpdateEvent()

	    CGame.EventManager:raiseEvent(nil, event)
	end

	if protocol.BagType == net.BAGTYPE.BACKPACK then
		local tids = {}
		local decomposedSlots  = {}
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_PACK
		local have_new_got = false
		for i,v in ipairs(data) do
			if v ~= nil then
				local item = CInventory.CreateItem(v.UpdateItem)
				-- 弹出app弹窗
				if v.UpdateItem.ItemData ~= nil then 
					game:OnAppMsgBoxStatic(EnumDef.TriggerTag.GetIDItem, v.UpdateItem.ItemData.Tid)
					game:OnAppMsgBoxStatic(EnumDef.TriggerTag.GetQualityItem, item._Quality)
				end
				if v.UpdateItem.ItemData.Tid == 0 and v.Cause == Data.EItemConsumeCause.ItemConsumeItemDecompose then 
					table.insert(decomposedSlots,v.UpdateItem.Index)
				end
				if data[i].Src ~=  Data.ENUM_ITEM_SRC.EQUIP_TAKEOFF 
				and data[i].Src ~= Data.ENUM_ITEM_SRC.STORAGEPACK 
				and data[i].Src ~= Data.ENUM_ITEM_SRC.OPEN_BOX 
				and data[i].Src ~= Data.ENUM_ITEM_SRC.NULL 
				and data[i].Src ~= Data.ENUM_ITEM_SRC.ADMIN
				and data[i].Src ~= Data.ENUM_ITEM_SRC.CHARM_TAKEOFF then 
					local nCurBagCount = normalPack:GetItemCountBySlot(v.UpdateItem.Index)
					local nDelta = v.UpdateItem.ItemData.Count - nCurBagCount
					if nDelta > 0 then -- 道具增加了
						if data[i].Src ~=  Data.ENUM_ITEM_SRC.SPRINTGIFT and 
						data[i].Src ~=  Data.ENUM_ITEM_SRC.PETDROP and
						data[i].Src ~=  Data.ENUM_ITEM_SRC.CHARM_COMPOSE then
							game._GUIMan:ShowMoveItemTextTips(v.UpdateItem.ItemData.Tid,false,nDelta, true)
						end
						-- 获得物品发送系统消息提示
						local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
						local ChatManager = require "Chat.ChatManager"
						local ItemName = RichTextTools.GetItemNameRichText(v.UpdateItem.ItemData.Tid, 1,true)  -- item._Template.TextDisplayName 
						local msg = nil
						if data[i].Src == Data.ENUM_ITEM_SRC.LOOT then
							-- msg = string.format(StringTable.Get(13034), nDelta, ItemName)
							msg = StringTable.Format_AB_BA(StringTable.Get(13034), nDelta, ItemName)
						elseif data[i].Src == Data.ENUM_ITEM_SRC.ITEM_DECOMPOSE then
							-- 物品分解已有提示
							msg = nil
						elseif data[i].Src == Data.ENUM_ITEM_SRC.ITEM_COMPOSE then
							-- 物品合成提示
							-- warn("lidaming ============>>> ndalte ", nDelta, ItemName)
							msg = string.format(StringTable.Get(13049), ItemName, nDelta)
						else
							msg = string.format(StringTable.Get(13032), ItemName, GUITools.FormatMoney(nDelta))    				
						end
						if msg ~= nil then
							ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 2, v.UpdateItem.ItemData,nil)
						end
					end
				end
				
				item._IsNewGot = (v.Src ~= Data.ENUM_ITEM_SRC.NULL) and(v.Src ~= Data.ENUM_ITEM_SRC.STORAGEPACK) and (v.Src ~= Data.ENUM_ITEM_SRC.EQUIP_TAKEOFF)
				if item._IsNewGot then
					have_new_got = true
				end
				item._PackageType = packageType
				
				--------------- 应 review 要求添加 begin---------------
				if normalPack._ItemSet ~= nil then
					-- 未新开格子 不显示new
					local index = 0
					for i, v in ipairs(normalPack._ItemSet) do
						if v._Slot == item._Slot then
							index = i
							break
						end
					end
					
					if index > 0 and normalPack._ItemSet[index] and item._Tid == 0 then
						if normalPack._ItemSet[index]._Tid == hp:GetEquipedPotion()	then
							hp:Try2EquipDrug()
						end
					end
				end
				------------- 应 review 要求添加 end--------------------



				normalPack:UpdateItem(item)
				normalPack:SortItemList()

				-- 药品自动装备
				if item._Tid ~= 0 and item:IsPotion() then
					-- 药水功能开启					
					-- if game._CFunctionMan:IsUnlockByFunTid(62) then
						local equip_drug_id = hp:GetEquipedPotion()
						-- 用光
						if equip_drug_id > 0 and normalPack:GetItemCount(equip_drug_id) == 0 then
							hp:Try2EquipDrug()
						-- 未装备
						else
							if equip_drug_id <= 0 then
								hp:Try2EquipDrug()
							end
						end
					-- end
				end


				tids[#tids + 1] = v.UpdateItem.ItemData.Tid
			end
		end

		if have_new_got and game._CurWorld ~= nil and game._CurWorld._IsReady then
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Msg_Get, 0)
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
		SendPackageChangeNotify(tids,decomposedSlots)
		local CPanelMainChat = require "GUI.CPanelMainChat"
		local last = normalPack:GetEmptySlotNum()
		CPanelMainChat.Instance():SetBagCapacityLast( (normalPack._EffectSize - last) /normalPack._EffectSize)

		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local NotifyBagCapacityEvent = require "Events.NotifyBagCapacityEvent"
		local event = NotifyBagCapacityEvent()
		event.Value=(normalPack._EffectSize - last) /normalPack._EffectSize
		CGame.EventManager:raiseEvent(nil, event)

		-- 装备红点刷新检测
		SendEquipRetDotUpdateNotify()
		-- 宠物红点刷新检测
		SendPetRetDotUpdateNotify()	
	elseif protocol.BagType == net.BAGTYPE.ROLE_EQUIP then
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK
		for i,v in ipairs(data) do
			local item = CInventory.CreateItem(v.UpdateItem)
			item._PackageType = packageType
			package._EquipPack:UpdateItem(item)
			local inforceLv = (item._Tid > 0 and item._InforceLevel > 0) and item._InforceLevel or 0
			hp:UpdateEquipments(item._Slot, item._Tid, inforceLv)
		end
		SendPackageChangeNotify()
		
		-- 装备红点刷新检测
		SendEquipRetDotUpdateNotify()	
	elseif protocol.BagType == net.BAGTYPE.STORAGEPACK then 
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_STORAGE
		for i,v in ipairs(data) do
			local item = CInventory.CreateItem(v.UpdateItem)
			item._PackageType = packageType
			package._StoragePack:UpdateItem(item)
			package._StoragePack:SortItemList()
		end
		SendPackageChangeNotify()
	elseif protocol.BagType == net.BAGTYPE.QUESTPACK then 
		local packageType = IVTRTYPE_ENUM.IVTRTYPE_TASKITEM
		for i,v in ipairs(data) do
			local item = CInventory.CreateItem(v.UpdateItem)
			item._PackageType = packageType
			package._TaskItemPack:UpdateItem(item)
			package._TaskItemPack:SortItemList()
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
		SendPackageChangeNotify()
	end
end

PBHelper.AddHandler("S2CUpdateItemInfo", OnUpdateItemInfo)

--穿上
local function OnS2CEquipPuton(sender,protocol)
	local player = game._CurWorld:FindObject(protocol.RoleId)
	if player == nil then return end
	player:UpdateEquipments(protocol.CellDB.Index, protocol.CellDB.ItemData.Tid,protocol.CellDB.ItemData.InforceLevel)
end
PBHelper.AddHandler("S2CEquipPuton", OnS2CEquipPuton)

--脱下
local function OnS2CEquipTakeoff(sender,protocol)
--warn("=============OnS2CEquipTakeoff=============")
	local player = game._CurWorld:FindObject(protocol.RoleId)
	if player == nil then return end

	player:UpdateEquipments(protocol.Index, 0,0)
end
PBHelper.AddHandler("S2CEquipTakeoff", OnS2CEquipTakeoff)

--锁定或是解锁Item
local function OnS2CItem(sender,protocol)
	if protocol.ResCode ~= 0 then warn("protocol.ResCode   ==== " ,protocol.ResCode) return end 
	local state = false
	if protocol.OptType == EItemOptLockType.EItemOptLockType_Unlock then 
		state = false
	elseif protocol.OptType == EItemOptLockType.EItemOptLockType_Lock then  
		state = true
	end
	local itemSets = nil 
	if protocol.BagType == net.BAGTYPE.BACKPACK then 
		itemSets = game._HostPlayer._Package._NormalPack._ItemSet
	elseif protocol.BagType == net.BAGTYPE.STORAGEPACK then 
		itemSets = game._HostPlayer._Package._StoragePack._ItemSet
	elseif protocol.BagType == net.BAGTYPE.ROLE_EQUIP then
		itemSets = game._HostPlayer._Package._EquipPack._ItemSet
	end
	for i,v in ipairs(itemSets) do
		if v._Slot == protocol.Index then
			v._IsLock = state

            local Lplus = require "Lplus"
		    local CGame = Lplus.ForwardDeclare("CGame")
            local ItemLockEvent = require "Events.ItemLockEvent"
            local event = ItemLockEvent()
            event._IsLock = state
            event._BagType = protocol.BagType
            event._Slot = protocol.Index
            CGame.EventManager:raiseEvent(nil, event)
		end
	end
	CPanelEquipHint.Instance():S2CLockItem(protocol)
end
PBHelper.AddHandler("S2CItemOptLock", OnS2CItem)
