local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local EResourceType = require"PB.data".EResourceType
local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = Lplus.ForwardDeclare("CIvtrItem")
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageBattle = require"GUI.CPageBattle"
local BAGTYPE = require "PB.net".BAGTYPE
local EItemEventType = require"PB.data".EItemEventType
local net = require "PB.net"
local PBHelper = require "Network.PBHelper"
local EMachingOptType = require "PB.net".EMachingOptType
local EMachingType = require "PB.net".EMachingType

local bit = require "bit"

local ItemComponentType = 
{
	EquipOn  =  1,  --装备
	EquipOff =  2,  --卸下
	Decompose=  3,  --分解
	Sell     =  4,  --出售
	SendLink =  5,  --发送链接
	Use      = 6,   --使用
	Compose  = 7,   --合成
	Embed    = 8,   --镶嵌(神符) 
	TakeOff  = 9,   --拆除(神符) 
	Inherit  = 10,  --传承(装备)
	Process  = 11,  --加工
	TakeOut = 12 ,  --仓库中取出
	Deposit = 13, -- 存入从背包存入仓库
	ItemApproach = 14, -- 获取路径
	Potion  = 15 ,  --药品装备
	Buy = 16,       --药品购买
	Configuration = 17,-- 药品配置
    Devour = 18,    --神符吞噬
}

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

local ItemComponent = Lplus.Class("ItemComponent")
do
	local def = ItemComponent.define
	def.field("table")._Item = nil
	def.field("number")._Type = 0
	def.const("table").ItemComponentType = ItemComponentType

	def.virtual("=>","boolean").IsEnabled = function (self)
		return true
	end

	def.virtual().Do = function (self)
	end

	def.method("=>","boolean").IsUseComponent = function (self)
		return self._Type == ItemComponentType.Use
	end
	
	def.method("=>","boolean").IsApproachType = function(self)
		return self._Type == ItemComponentType.ItemApproach
	end

	def.method("=>","string").GetName = function (self)
		return StringTable.Get(11099 + self._Type)
	end

	ItemComponent.Commit()
end

local EquipOnComponent = Lplus.Extend(ItemComponent,"EquipOnComponent")
do
	local def = EquipOnComponent.define
	def.static("table","=>",EquipOnComponent).new = function (item)
		local obj = EquipOnComponent()
		obj._Item = item
		obj._Type = ItemComponentType.EquipOn
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType ~= IVTRTYPE_ENUM.IVTRTYPE_PACK  then return false end
		return true
	end

-- 装备按钮使用提示特殊处理
	def.override().Do = function (self)
		local item = self._Item
		if not item then return end

		local hp = game._HostPlayer
	    local itemTemplate = item._Template

	    if hp._InfoData._Level < itemTemplate.MinLevelLimit then
	    	game._GUIMan: ShowTipText(StringTable.Get(10700),false)
	        return 
	    end

	    if EnumDef.Profession2Mask[hp._InfoData._Prof] ~= bit.band(itemTemplate.ProfessionLimitMask, EnumDef.Profession2Mask[hp._InfoData._Prof] ) then
	        game._GUIMan: ShowTipText(StringTable.Get(10701), false)
	        return 
	    end 
	    if game._CArenaMan._IsMatchingBattle then 
	    	game._GUIMan: ShowTipText(StringTable.Get(27004), false)
	    	return
	    end	    
	    item:Use()
	end

	EquipOnComponent.Commit()
end

local EquipOffComponent = Lplus.Extend(ItemComponent,"EquipOffComponent")
do
	local def = EquipOffComponent.define

	def.static("table","=>",EquipOffComponent).new = function (item)
		local obj = EquipOffComponent()
		obj._Item = item
		obj._Type = ItemComponentType.EquipOff
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then return true end
		return false
	end

	def.override().Do = function (self)
		local item = self._Item
		if not item then return end
		if item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then
			local hp = game._HostPlayer

			-- if game._HostPlayer:IsInServerCombatState() then
   --  			game._GUIMan: ShowTipText(StringTable.Get(139), false)
   --  			return
			if hp._Package._NormalPack:IsFull() then
				local title, msg, closeType = StringTable.GetMsg(60)
				MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
				return
			end
			if game._CArenaMan._IsMatchingBattle then 
	    		game._GUIMan: ShowTipText(StringTable.Get(27004), false)
	    		return
	    	end	

	    	CSoundMan.Instance():Play2DAudio(EnumDef.UseItemAudioType[item._Template.AudioType], 0)    
			local C2SEquipTakeoff = require "PB.net".C2SEquipTakeoff
		    local protocol = C2SEquipTakeoff()
		    protocol.Slot = item._Slot

		    local PBHelper = require "Network.PBHelper"
		    PBHelper.Send(protocol)
		end
	end
	EquipOffComponent.Commit()
end

-- local ReinforceComponent = Lplus.Extend(ItemComponent,"ReinforceComponent")
-- do
-- 	local def = ReinforceComponent.define
	
-- 	def.static("table","=>",ReinforceComponent).new = function (item)
-- 		local obj = ReinforceComponent()
-- 		obj._Item = item
-- 		obj._Type = ItemComponentType.Use
-- 		return obj
-- 	end
-- 	def.override("=>","boolean").IsEnabled = function (self)
-- 		return self._Item ~= nil and self._Item:CanReinforce()
-- 	end

-- 	def.override().Do = function ( self )
-- 		game._GUIMan:Open("CPanelEquip", nil)
-- 	end

-- 	ReinforceComponent.Commit()
-- end

local UseComponent = Lplus.Extend(ItemComponent,"UseComponent")
do
	local def = UseComponent.define
	def.static("table","=>",UseComponent).new = function (item)
		local obj = UseComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Use
		return obj
	end

	def.override().Do = function ( self )
		self._Item:Use()
	end

	UseComponent.Commit()
end

local SellComponent = Lplus.Extend(ItemComponent,"SellComponent")
do
	local def = SellComponent.define

	def.static("table","=>",SellComponent).new = function (item)
		local obj = SellComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Sell
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		local item  = self._Item
		if not item then return false end
		if item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK   then 
			return false 
		else 
			return true 
		end	
	end

	def.override().Do = function (self)
		local item = self._Item
		if not item then return end
		if item:IsEquip() and item._IsLock then 
			game._GUIMan:ShowTipText(StringTable.Get(10078),false)
			return
		end

		local function callback1( count )
			local function callback2(value)
				if value then
					local net = require "PB.net"
				    local msg = net.C2SItemSell()
				    local ItemSellStruct = require"PB.net".ItemSellStruct  
				    local SellItem = ItemSellStruct()
                	SellItem.Index = item._Slot
                	SellItem.Count = count
                	table.insert(msg.Items,SellItem)
				    local PBHelper = require "Network.PBHelper"
				    PBHelper.Send(msg)
				    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Sell_Item, 0)
				end
			end
			if item._Quality >3 or item._Quality == 3 then 
				local text = "<color=#" .. EnumDef.Quality2ColorHexStr[item._Quality] ..">" .. item._Template.TextDisplayName .."</color>"
				local title, msg, closeType = StringTable.GetMsg(63)
				local str = string.format(msg, text)
				MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback2)			
			else
				callback2(true)
			end
		end
		if item._NormalCount == 1 then 
			callback1(item._NormalCount)
		elseif item._NormalCount > 1 then 
            local itemTemp = CElementData.GetItemTemplate(item._Tid)
            local des = string.format(StringTable.Get(22313),   "<color=#"..EnumDef.Quality2ColorHexStr[itemTemp.InitQuality] ..">" .. itemTemp.TextDisplayName .."</color>")
            BuyOrSellItemMan.ShowCommonOperate(TradingType.SELL,StringTable.Get(11103), des, 1, item._NormalCount, itemTemp.RecyclePriceInGold, EResourceType.ResourceTypeGold, nil, callback1)
		end
		
	end
	SellComponent.Commit()
end

local SendLinkComponent = Lplus.Extend(ItemComponent,"SendLinkComponent")
do
	local def = SendLinkComponent.define

	def.static("table","=>",SendLinkComponent).new = function (item)
		local obj = SendLinkComponent()
		obj._Item = item
		obj._Type = ItemComponentType.SendLink
		return obj
	end

	def.override().Do = function (self)
		local net = require "PB.net"	    
	    local param = {}
	    param.DataName = "ItemLinkInfo" 
	    param.item_data = self._Item
	    local bagType = net.BAGTYPE.BACKPACK
	    if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then
	    	bagType = net.BAGTYPE.ROLE_EQUIP
	    end
	    param.bag_type = bagType	    
	    	-- game._GUIMan:Close("CPanelRoleInfo")
		game._GUIMan:CloseSubPanelLayer()
		game._GUIMan:Open("CPanelChatNew", param)
	end

	SendLinkComponent.Commit()
end

local DecomposeComponent = Lplus.Extend(ItemComponent,"DecomposeComponent")
do
	local def = DecomposeComponent.define

	def.static("table","=>",DecomposeComponent).new = function (item)
		local obj = DecomposeComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Decompose
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then 
			return false 
		else
			return true
		end
	end

	def.override().Do = function (self)
		local param = {}
        param.item_data = self._Item
        param.cost_type = false
    	if self._Item:IsEquip() and self._Item._IsLock then 
			game._GUIMan:ShowTipText(StringTable.Get(10078),false)
			return
		end
		local callback = function(val)
			if val then       												
				local C2SItemMachining = require "PB.net".C2SItemMachining
				local protocol = C2SItemMachining()
				protocol.ItemMachiningId = self._Item._Template.ComposeId   --物品加工ID
				protocol.Count = 1                       -- 单个物品分解数量 默认为1
				protocol.MachingType = EMachingType.EMachingType_Normal    
				protocol.Slot = self._Item._Slot
				protocol.MachingOptType = EMachingOptType.EMachingOptType_Decompose
				PBHelper.Send(protocol)  							
			end
		end


		if self._Item._Quality >= 3 then    -- 3代表紫色。紫色以上品质的物品分解需要msgBox提示
			local title, msg, closeType = StringTable.GetMsg(14)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
		else
			callback(true)
		end
	end

	DecomposeComponent.Commit()
end

local ComposeComponent = Lplus.Extend(ItemComponent,"ComposeComponent")
do
	local def = ComposeComponent.define

	def.static("table","=>",ComposeComponent).new = function (item)
		local obj = ComposeComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Compose
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then 
			return false 
		else
			return true
		end
	end

	def.override().Do = function (self)
	    if self._Item:IsEquip() and self._Item._IsLock then 
			game._GUIMan:ShowTipText(StringTable.Get(10078),false)
			return
		end

        local callback = function(input_ProcessCount)
            local machiningId = 0
            local template = self._Item._Template
            if self._Item:CanCompose() then --合成
                machiningId = template.ComposeId
                if machiningId ~= 0 and input_ProcessCount ~= 0 then
                    local C2SItemMachining = require "PB.net".C2SItemMachining
                    local protocol = C2SItemMachining()
                    protocol.ItemMachiningId = machiningId   --物品加工ID
                    protocol.Count = input_ProcessCount                       --加工数量  先默认为1
                    protocol.MachingType = EMachingType.EMachingType_Normal
                    protocol.MachingOptType = EMachingOptType.EMachingOptType_Compose
                    PBHelper.Send(protocol)
                end
            else
                warn("COMPOSE ERRPR!!!")
            end    
        end

        local template_processItem = CElementData.GetTemplate("ItemMachining", self._Item._Template.ComposeId)
        local CostOneNeedNum = template_processItem.SrcItemData.SrcItems[1].ItemCount   --合成一个需要消耗的物品数量
        local CostOneNeedMoney = template_processItem.MoneyNum    --合成一个需要消耗的钱数   
        local normalPack = game._HostPlayer._Package._NormalPack
        local bagItemCount = normalPack:GetItemCount(self._Item._Tid)

        BuyOrSellItemMan.ShowCommonOperate(TradingType.COMPOSE,StringTable.Get(11106),"",1, 
        math.floor(bagItemCount/CostOneNeedNum),CostOneNeedMoney, template_processItem.MoneyId, self._Item, callback)
	end

	ComposeComponent.Commit()
end

local EmbedComponent = Lplus.Extend(ItemComponent,"EmbedComponent")
do
	local def = EmbedComponent.define

	def.field("function")._Action = nil

	def.static("table","=>",EmbedComponent).new = function (item)
		local obj = EmbedComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Embed
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return self._Item:IsCharm()
	end

	def.override().Do = function (self)
        local CPanelCharm = require "GUI.CPanelCharm"
        if CPanelCharm.Instance():IsShow() then
		    if self._Action ~= nil then
			    self._Action()
		    end
        else
            local charm_unlockID = 35
            if game._CFunctionMan:IsUnlockByFunTid(charm_unlockID) then
                local data = {pageType = 1, data = {itemID = self._Item._Tid, Slot = self._Item._Slot}}
                game._GUIMan:Open("CPanelCharm", data)
            else
                game._GUIMan:ShowTipText(StringTable.Get(23), false)
            end
        end
	end

	EmbedComponent.Commit()
end

local TakeOffComponent = Lplus.Extend(ItemComponent,"TakeOffComponent")
do
	local def = TakeOffComponent.define
	def.field("function")._Action = nil

	def.static("table","=>",TakeOffComponent).new = function (item)
		local obj = TakeOffComponent()
		obj._Item = item
		obj._Type = ItemComponentType.TakeOff
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return self._Item:IsCharm()
	end

	def.override().Do = function (self)
		if self._Action ~= nil then
			self._Action()
		end
	end

	TakeOffComponent.Commit()
end

local DevourComponent = Lplus.Extend(ItemComponent, "DevourComponent")
do
	local def = DevourComponent.define
	def.field("function")._Action = nil

	def.static("table","=>",DevourComponent).new = function (item)
		local obj = DevourComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Devour
		return obj
	end

	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return self._Item:IsCharm()
	end

	def.override().Do = function (self)
        local charm_max_level_specialID = 570
        local charm_max_level = tonumber(CElementData.GetSpecialIdTemplate(charm_max_level_specialID).Value)
        
        if self._Item._CharmItemTemplate ~= nil and self._Item._CharmItemTemplate.Level >= charm_max_level then
            game._GUIMan:ShowTipText(StringTable.Get(19355), false)
        else
            local CPanelCharm = require "GUI.CPanelCharm"
            if CPanelCharm.Instance():IsShow() then
		        if self._Action ~= nil then
			        self._Action()
		        end
            else
                local charm_unlockID = 35
                if game._CFunctionMan:IsUnlockByFunTid(charm_unlockID) then
                    local panel_data = {
                        pageType = 2,
                        data = {
                            itemID = self._Item._Tid,
                            Slot = self._Item._Slot,
                            ComposeType = 1
                        }
                    }
                    game._GUIMan:Open("CPanelCharm", panel_data)
                else
                    game._GUIMan:ShowTipText(StringTable.Get(23), false)
                end
            end
        
		    if self._Action ~= nil then
			    self._Action()
		    end
        end
        
	end

	DevourComponent.Commit()
end


local InheritComponent = Lplus.Extend(ItemComponent,"InheritComponent")
do
	local def = InheritComponent.define
	def.field("table")._EquipPackItem = nil
	def.static("table","=>",InheritComponent).new = function (item)
		local obj = InheritComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Inherit
		return obj
	end
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType ~= IVTRTYPE_ENUM.IVTRTYPE_PACK  then return false end
		local itemSet = game._HostPlayer._Package._EquipPack._ItemSet
		if not itemSet then 
			return false
		else
			for i,v in ipairs(itemSet) do
		        local itemTemplate = CElementData.GetItemTemplate(v._Tid)
		        if itemTemplate ~= nil and itemTemplate.Slot == self._Item._Template.Slot then --and self._Item._RebuildLuckyValue > 0 then
		        	self._EquipPackItem = v
		        	return true
		        end
			end
			return false
		end
	end
	def.override().Do = function (self)

		-- if self._EquipPackItem._RebuildLuckyValue > 0 then 
		-- 	local title, msg, closeType = StringTable.GetMsg(64)
		-- 	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val)
	 --                if val then
	 --                    local C2SItemInherit = require "PB.net".C2SItemInherit
		-- 		        local protocol = C2SItemInherit()
		-- 		        protocol.BagEquipIndex = self._Item._Slot
		-- 		        SendProtocol(protocol)
	 --                end
	 --            end)	
		-- else
			local title, msg, closeType = StringTable.GetMsg(65)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val)
	                if val then
	                    local C2SItemInherit = require "PB.net".C2SItemInherit
				        local protocol = C2SItemInherit()
				        protocol.BagEquipIndex = self._Item._Slot
				        SendProtocol(protocol)
	                end
	            end)
	    -- end	
	end
	InheritComponent.Commit()
end

local ProcessComponent = Lplus.Extend(ItemComponent,"ProcessComponent")
do
	local def = ProcessComponent.define
	def.static("table","=>",ProcessComponent).new = function (item)
		local obj = ProcessComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Process
		return obj

	end
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return true
	end
	def.override().Do = function (self)
		-- 添加点击效果
		if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Equip) then
			game._GUIMan: ShowTipText(StringTable.Get(20060),false)
		else
			local data = 
		    {
		        PackageType = BAGTYPE.BACKPACK,
		        UIEquipPageState = nil,
		        ItemData = self._Item,
		    }
			game._GUIMan:Open("CPanelUIEquipProcess", data)
		end
	end
	ProcessComponent.Commit()
end

local TakeOutComponent = Lplus.Extend(ItemComponent,"TakeOutComponent")
do
	local def = TakeOutComponent.define
	def.static("table","=>",TakeOutComponent).new = function (item)
		local obj = TakeOutComponent()
		obj._Item = item
		obj._Type = ItemComponentType.TakeOut
		return obj
	end
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return true
	end
	def.override().Do = function (self)
		--从仓库中取出
		local StoragePackChange = require "PB.net".C2SStoragePackChangeReq
		local protocol = StoragePackChange()
		protocol.ChangeType = net.StoragePackChangeType.Type_UnLoad 
		protocol.Index = self._Item._Slot
		PBHelper.Send(protocol)		
	end
	TakeOutComponent.Commit()
end

local DepositComponent = Lplus.Extend(ItemComponent,"DepositComponent")
do
	local def = DepositComponent.define
	def.static("table","=>",DepositComponent).new = function (item)
		local obj = DepositComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Deposit
		return obj
	end
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return true
	end
	def.override().Do = function (self)
	-- 存入仓库
		local StoragePackChange = require "PB.net".C2SStoragePackChangeReq
		local protocol = StoragePackChange()
		protocol.ChangeType = net.StoragePackChangeType.Type_Load 
		protocol.Index = self._Item._Slot
		PBHelper.Send(protocol)		
	end
	DepositComponent.Commit()
end

-- 弃用 将来
local ItemApproachComponent = Lplus.Extend(ItemComponent,"ItemApproachComponent")
do
	local def = ItemApproachComponent.define
	def.static("table","=>",ItemApproachComponent).new = function (item)
		local obj = ItemApproachComponent()
		obj._Item = item
		obj._Type = ItemComponentType.ItemApproach
		return obj
	end
	
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		return false
	end

	-- def.override().Do = function (self)
	-- 	local CItemHint = require"GUI.CPanelItemHint"
	-- 	CItemHint.Instance():ShowItemApproachPage()
	-- end

	ItemApproachComponent.Commit()
end

local PotionComponent = Lplus.Extend(ItemComponent,"PotionComponent")
do
	local def = PotionComponent.define
	def.static("table","=>",PotionComponent).new = function (item)
		local obj = PotionComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Potion
		return obj
	end
	
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then return false end
		return true
	end

	def.override().Do = function (self)
		local hp = game._HostPlayer
	    local itemTemplate = self._Item._Template
	    if itemTemplate and hp._InfoData._Level >= itemTemplate.MinLevelLimit then
		    local C2SCarryPotion = require "PB.net".C2SCarryPotion
		    local protocol = C2SCarryPotion()
		    protocol.Tid = self._Item._Tid
		    PBHelper.Send(protocol)
		else
			game._GUIMan:ShowTipText(StringTable.Get(30107), false)
		end
	end

	PotionComponent.Commit()
end

local BuyComponent = Lplus.Extend(ItemComponent,"BuyComponent")
do
	local def = BuyComponent.define
	def.static("table","=>",BuyComponent).new = function (item)
		local obj = BuyComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Buy
		return obj
	end
	
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then return false end
		return true
	end

	def.override().Do = function (self)
		local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType		
    	local panelData =
        {
            OpenType = 1,
            ShopId = 10,
			ItemId = self._Item._Tid,
        }
        game._GUIMan:Open("CPanelNpcShop",panelData)			   
	end

	BuyComponent.Commit()
end

local ConfigurationComponent = Lplus.Extend(ItemComponent,"ConfigurationComponent")
do
	local def = ConfigurationComponent.define
	def.static("table","=>",ConfigurationComponent).new = function (item)
		local obj = ConfigurationComponent()
		obj._Item = item
		obj._Type = ItemComponentType.Configuration
		return obj
	end
	
	def.override("=>","boolean").IsEnabled = function (self)
		if not self._Item then return false end
		if self._Item._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then return false end
		return true
	end

	def.override().Do = function (self)
		game._GUIMan:Open("CPanelUISetting", EnumDef.SettingPageType.BattleSetting)	
	end

	ConfigurationComponent.Commit()
end

-------------------------------------------------------------------------
return
{
	ItemComponent     = ItemComponent,
	EquipOnComponent  = EquipOnComponent,
	EquipOffComponent = EquipOffComponent,
	--ReinforceComponent = ReinforceComponent,
	DecomposeComponent = DecomposeComponent,
	UseComponent      = UseComponent,
	SellComponent     = SellComponent,
	ComposeComponent  = ComposeComponent,
	SendLinkComponent = SendLinkComponent,
	EmbedComponent = EmbedComponent,
	TakeOffComponent = TakeOffComponent,
    DevourComponent = DevourComponent,
	InheritComponent = InheritComponent,
	ProcessComponent = ProcessComponent,
	TakeOutComponent = TakeOutComponent,
	DepositComponent = DepositComponent,
	ItemApproachComponent = ItemApproachComponent,
	PotionComponent = PotionComponent,
	BuyComponent = BuyComponent,
	ConfigurationComponent = ConfigurationComponent,

	ItemComponentType = ItemComponentType,
	
}