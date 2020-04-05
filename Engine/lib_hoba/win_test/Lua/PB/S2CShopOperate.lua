local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local EShopResCode = require "PB.net".EShopResCode

local function OnShopResCode(code)
	if code == EShopResCode.ShopResCode_MoneyLimit then
		game._GUIMan:ShowTipText(StringTable.Get(260), true)
	elseif code == EShopResCode.ShopResCode_BagLimit then
		game._GUIMan:ShowTipText(StringTable.Get(256), true)
	elseif code == EShopResCode.ShopResCode_BuyTimesLimit then
		game._GUIMan:ShowTipText(StringTable.Get(264), true)
	elseif code == EShopResCode.ShopResCode_GuildLevelLimit then
		game._GUIMan:ShowTipText(StringTable.Get(263), true)
	elseif code == EShopResCode.ShopResCode_NotFindItem then
		game._GUIMan:ShowTipText(StringTable.Get(257), true)
	elseif code == EShopResCode.ShopResCode_PermissionLimit then
		game._GUIMan:ShowTipText(StringTable.Get(262), true)
	elseif code == EShopResCode.ShopResCode_Lock then
		game._GUIMan:ShowTipText(StringTable.Get(261), true)
	elseif code == EShopResCode.ShopResCode_NumLimit then
		game._GUIMan:ShowTipText(StringTable.Get(266), true)		
	end
end

local function OnS2CShopViewItemList(sender, msg)
	if msg.ResCode == EShopResCode.ShopResCode_Success then
		game._ShopMan:SendShopEvent(msg, "View")
	end
end
PBHelper.AddHandler("S2CShopViewItemList", OnS2CShopViewItemList)

local function OnS2CShopBuyItem(sender, msg)
	OnShopResCode(msg.ResCode)
	if msg.ResCode == EShopResCode.ShopResCode_Success then
		game._ShopMan:SendShopEvent(msg, "Buy")
	end
end
PBHelper.AddHandler("S2CShopBuyItem", OnS2CShopBuyItem)