--
-- 支付
--

local PBHelper = require "Network.PBHelper"
--local CElementData = require "Data.CElementData"

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

--开启支付
local function OnS2CPurchaseProduct(sender,protocol)
	warn("=============OnS2CPurchaseProduct=============")
	local orderId = protocol.OrderId
	local purchaseType = protocol.Platform
	local productId = protocol.ProductId

	CPlatformSDKMan.Instance():DoPurchase(purchaseType, orderId, productId)
end
PBHelper.AddHandler("S2CPurchaseProduct", OnS2CPurchaseProduct)


--[[

--是否验证成功
local function OnS2CPurchaseVerifyRes(sender,protocol)
	warn("=============OnS2CPurchaseVerifyRes=============")
	local ErrorCode = protocol.ErrorCode
	
	local OrderId = protocol.OrderId
	local TransactionId = protocol.TransactionId
	local Platform = protocol.Platform

	if ErrorCode == 0 then
		warn("支付验单成功")
		MsgBox.ShowMsgBox("支付验单成功", "支付回调", 0, MsgBoxType.MBBT_OK)
	else
		warn("支付验单失败")
		MsgBox.ShowMsgBox("支付验单失败", "支付回调", 0, MsgBoxType.MBBT_OK)
	end
end
PBHelper.AddHandler("S2CPurchaseVerifyRes", OnS2CPurchaseVerifyRes)

]]