--[[----------------------------------------------
         		货币消耗
          				--- by luee 2017.4.26
--------------------------------------------------]]
local Lplus = require "Lplus"
local CUseDiamondMan = Lplus.Class("CUseDiamondMan")
local def = CUseDiamondMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local EResourceType = require "PB.data".EResourceType

local ComeType = nil --扣除来源
local UseType = nil  --扣除类型
local ItemData = nil --购买物品结构
local DiamondCount = nil --砖石数量
local BuyCount = nil-- 购买的数量
local BuyItemID = nil --购买的ID
local Table_IgnoreTips = {} --忽略列表，针对不同功能和UI做保存
local event_CallbackOK = nil  		--OK的回调函数
local event_CallbackCancel = nil	--cancel的回调函数
local UseCount = 0  --货币使用次数，极限情况下好几次使用，涉及到关闭和回调，必须全部执行完


local SPECIAL_PANEL = {""} --需要特殊操作的界面


local instance = nil
def.static("=>",CUseDiamondMan).Instance = function()
	if not instance then
		instance = CUseDiamondMan()
		UseCount = 0
	end
	
	return instance
end

--------------------------------------私有接口------------------------------------------
--功能是否是特殊操作界面
local function CheckComeType(ComePanel)
	if SPECIAL_PANEL == nil then return false end

	for _,v in ipairs(SPECIAL_PANEL) do
		if v == ComePanel then
			return true
		end
	end

	return false
end

--扣除类型 EResourceType.ResourceTypeDiamond  砖石 EResourceType.ResourceTypeBindDiamond 绑定砖石 EResourceType.ResourceTypeTypeGold 金币
--检查砖石 -1 购买类型错误，直接退出 0 = 可以购买 1= 可以购买，但是需要兑换  2= 没钱，充钱！
local function CheckDiamond(nType,nDiamond)
	local bindDiamond = game._HostPlayer._Package._BindDiamondCount --绑定砖石
	local haveDiamond = game._AccountInfo._Diamond --账号里面的砖石
	local totalGold = game._HostPlayer._Package._GoldCoinCount --包包里面的金币

	if nType == EResourceType.ResourceTypeBindDiamond then --扣绑定砖石，可以非绑定补充
		if nDiamond > bindDiamond + haveDiamond then
			return 2,-1 --充钱！！！
		else	
			if nDiamond > bindDiamond then
				return 1,nDiamond - bindDiamond--砖石兑换！！
			else
				return 0,0 --满足条件，买买买
			end
		end
	elseif nType == EResourceType.ResourceTypeGold then --金币
		if totalGold >= nDiamond then
			return 0,0
		else
			game._GUIMan: ShowTipText(StringTable.Get(253),true)
			return -1,-1
		end
	elseif nType == EResourceType.ResourceTypeDiamond then--只能砖石
		if nDiamond > haveDiamond then return 2,-1 end
		return 0 ,0
	end

	return -1,-1
end	

local function ChangeDiamond(nCount)
	
end

--使用钻石
local function UseDiamoid()
	local panelData = nil
	--warn("ComeType",ComeType)
	if CheckComeType(ComeType) then --特殊界面，强制确认
		panelData = 
		{
			_PanelType = 1,
			_Item = ItemData,
			_tips = false,
			_Diamond = DiamondCount,
			_BuyCount = BuyCount,
			_BuyItemID = BuyItemID,
			_ComeType = ComeType,
			_UseType = UseType,
		}	
	elseif Table_IgnoreTips[ComeType] ~= nil and Table_IgnoreTips[ComeType] then --点击了跳过UI，所以判断一下购买条件
		local ntype,nCount = CheckDiamond(UseType, DiamondCount)
		
		if ntype == 0 then--直接买买买
			if event_CallbackOK then
				event_CallbackOK()
			return end
		elseif ntype == 1 then --兑换绑定砖石
			if Table_IgnoreTips["ChangeDiamond"] ~= nil and Table_IgnoreTips["ChangeDiamond"] then
				 ChangeDiamond(nCount)
			else
				panelData = 
				{
					_PanelType = 2,
					_tips = true,
					_Diamond = nCount,
					_ComeType = "ChangeDiamond",
				}	
			end			
		elseif ntype == 2 then--钱不够。充钱去！
			panelData = 
			{
				_PanelType = 3,
				_ComeType = "BuyDiamond",
				_tips = false,
			}
		end
	else--默认状态
		panelData = 
		{
			_PanelType = 1,
			_Item = ItemData,
			_tips = true,
			_Diamond = DiamondCount,
			_BuyCount = BuyCount,
			_BuyItemID = BuyItemID,
			_ComeType = ComeType,
			_UseType = UseType,
		}
	end
	game._GUIMan:Open("CPanelUseDiamond", panelData)
end

local function ClearData()
	ItemData = nil
	ComeType = nil 
	UseType = nil 
	DiamondCount = nil 
 	event_CallbackOK = nil  		
	event_CallbackCancel = nil
	BuyCount = nil
	BuyItemID = nil
end

local function CancelBuy()
	--warn("??????????????CancelBuy")
 	if event_CallbackCancel ~= nil then
 		event_CallbackCancel()
 	end
end

local function ConfigBuy()
	--warn("??????????????ConfigBuy")
	if event_CallbackOK ~= nil then
		event_CallbackOK()
	end
end

-------------------------------------对外接口-------------------------------------------
--[[购买物品扣除砖石
strComeType     --调用来源，Panel的名字
ItemID          --物品ID
Count,		    --物品个数
CallBackOK,	    --确认回调
CallBackCancel  --取消回调
--]]
def.method("string","number","number","function","function").BuyItemUseDiamond = function(self,strComeType,ItemID,Count,CallBackOK,CallBackCancel)
	--warn("BuyItemUseDiamond")
	if ItemID <= 0 or Count <= 0 then 	
		FlashTip("货币使用错误ID："..ItemID.."扣除数量："..Count,"tip",3)
	return end
	local itemTemplate = CElementData.GetItemTemplate(ItemID)
	if itemTemplate == nil then
		FlashTip("物品模板错误ID："..ItemID,"tip",3)	
	return end
	UseCount = UseCount + 1
	ItemData = 
	{
		_ItemName = itemTemplate.Name,
		_ItemCount = Count,
		_QualityIdex = itemTemplate.InitQuality
	}
	ComeType = strComeType
	UseType = EResourceType.ResourceTypeBindDiamond
	DiamondCount = 0
	BuyItemID = nil
	BuyCount = nil
	event_CallbackOK = CallBackOK
	event_CallbackCancel = CallBackCancel
	UseDiamoid()
end

--[[根据消耗类型直接扣砖石
strComeType     --调用来源，Panel的名字
nType          	--消耗类型 --扣除类型 EResourceType
nDiamond,		--消耗钻石
CallBackOK,	    --确认回调
CallBackCancel  --取消回调
--]]
def.method("string","number","number","function","function").DirectlyUseDiamond = function(self,strComeType,nType,nDiamond,CallBackOK,CallBackCancel)
	--warn("DirectlyUseDiamond")
	if nType < 0 or nDiamond <= 0 then 
		FlashTip("货币使用错误Type："..nType.."扣除金额："..nDiamond,"tip",3)
	return end
	UseCount = UseCount + 1
	ItemData = nil
	ComeType = strComeType
	UseType = nType
	DiamondCount = nDiamond
	event_CallbackOK = CallBackOK
	event_CallbackCancel = CallBackCancel
	UseDiamoid()
end

--[[直接扣除货币，但是要显示ITEM信息的交易，类似拍卖行，交易所。有自己的金额控制
strComeType     --调用来源，Panel的名字
nType          	--消耗类型 --扣除类型 EResourceType
nDiamond,		--消耗钻石
CallBackOK,	    --确认回调
CallBackCancel  --取消回调
itemID			--购买的道具ID  -1 没有ID，直接扣
Count,		    --物品个数      -1 没有数量 直接扣
--]]

def.method("string","number","number","function","function","number","number").DirectlyUseDiamondBuyItem = function(self,strComeType,nType,nDiamond,CallBackOK,CallBackCancel,itemID,Count)
	if nType < 0 or nDiamond <= 0 then 
		FlashTip("货币使用错误Type："..nType.."扣除金额："..nDiamond,"tip",3)
	return end

	if itemID <= 0 or  Count <= 0 then
		FlashTip("道具购买错误ItmeID："..itemID.."个数："..Count,"tip",3)
	return end
	UseCount = UseCount + 1
	if Count > 0 then
		BuyCount = Count
	else
		BuyCount = nil
	end

	if itemID > 0 then
		BuyItemID = itemID
	else
		BuyItemID = nil
	end	
     
    self: DirectlyUseDiamond(strComeType,nType,nDiamond,CallBackOK,CallBackCancel)
end

--根据功能和UI忽略提示
def.method("string","boolean").SetIgnore = function(self,strComeType,isIgnoreTips)
	if strComeType == nil or strComeType == "" then return end

	Table_IgnoreTips[strComeType] = isIgnoreTips
end


--界面操作状态 true = 确认  false = 取消
def.method("boolean").ConfigEvent = function(self,isConfig)	
	if UseCount <= 0 then return end

	if isConfig then
		ConfigBuy()
	else
		CancelBuy()
	end

	ClearData()
	UseCount = UseCount - 1
end

--是不是最后一次操作
def.method("=>","number").GetUseCount = function(self)
	return UseCount
end

def.method("number","number","=>","number","number").ClickConfigCheck = function(self,nType,nDiamond)
	return CheckDiamond(nType,nDiamond)
end

def.method().Close = function(self)
	game._GUIMan:Close("CPanelUseDiamond")
	ClearData()
end

def.method("string","=>","boolean").IsSpecialTips = function(self,ComeType)
	return CheckComeType(ComeType)
end

--------------------------------C2S------------------------------------------
def.method("number").C2SChangeDiamond = function(self,nDiamond)
	ChangeDiamond(nDiamond)
end

def.method().BuyDiamond = function(self)
	
end

CUseDiamondMan.Commit()
return CUseDiamondMan