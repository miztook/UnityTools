_G.TradingType = 
{
	BUY = 1,        --购买
	SELL = 2,       --出售
    COMPOSE = 3,    --合成
    DECOMPOSE = 4,  --分解
    USE = 5,        --使用
    BagBuyCell = 6  -- 背包购买格子
}

local _BuyOrSellItemPanel = function (itemID,unitPrice,maxNumber,callback,tradingType,moneyType)
	local data = {}
	data._ID = itemID 
	if not unitPrice then 
		data._UnitPrice = 0
	else
		data._UnitPrice = unitPrice
	end
	data._TradingType = tradingType 
	data._MaxNumber = maxNumber
	data._CallBack = callback
	data._MoneyType = moneyType
	game._GUIMan:Open("CPanelBuyOrSellItem",data)
end

local _ShowCommonOperate = function(purposeType, title, des, minValue, maxValue, price, costMoneyID, customData, okCallBack, failCallBack)
    local buyInfo = {}
    buyInfo._PurposeType = purposeType
    buyInfo._Title = title
    buyInfo._Des = des
    buyInfo._MinValue = minValue
    buyInfo._MaxValue = maxValue
    buyInfo._Price = price
    buyInfo._CostMoneyID = costMoneyID
    buyInfo._CustomData = customData
    buyInfo._OkCallBack = okCallBack
    buyInfo._FailCallBack = failCallBack
    game._GUIMan:Open("CPanelCommonOperate",buyInfo)
end

local BuyOrSellItemMan = 
{
	ShowBuyOrSellItemPanel = _BuyOrSellItemPanel,
    ShowCommonOperate = _ShowCommonOperate,
}
_G.BuyOrSellItemMan = BuyOrSellItemMan

-- return BuyOrSellItem