local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local UseItemEvent = require "Events.UseItemEvent"
local CPanelLottery = require"GUI.CPanelLottery"
local EItemType = require "PB.Template".Item.EItemType 

--使用物品失败返回错误码对应提示
local ServerMessageBase = require "PB.data".ServerMessageBase
local ServerMessageItem = require "PB.data".ServerMessageItem
local function OnItemUseResultCode(code)
	if code == ServerMessageItem.ItemUseCoolDown then
		game._GUIMan:ShowTipText(StringTable.Get(19503), false)
	elseif code == ServerMessageBase.Failed then
		game._GUIMan:ShowTipText("Failed", false)
	else
		warn("ItemUseResult msg.ResCode == " ..code)
	end
end

local function UseBagCoupon(itemid,count)
	local idList = string.split(CSpecialIdMan.Get("BackpackCouponId"),"*")
	for i,id in ipairs(idList) do 
		if itemid == tonumber(id) then 
			local temp = CElementData.GetItemTemplate(itemid)
			local totalCount = tonumber(temp.Type1Param1) * count
			local name = RichTextTools.GetQualityText(temp.TextDisplayName,temp.InitQuality)
			local msg = string.format(StringTable.Get(316),count,name,totalCount)
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Add_BagCell, 0)
			game._GUIMan:ShowTipText(msg, false)
		return end
	end
end

local function OnS2CItemUseResult(sender, msg)
	if msg.result == 0 then
		--更新万物志物品类型的次数组使用更新
		local itemTid = msg.itemTid
		local itemTemp = CElementData.GetItemTemplate(itemTid)
		if itemTemp.ItemType == EItemType.NoramlItem then
			game._CCountGroupMan:OnCountGroupChange(itemTemp.ItemUseCountGroupId,msg.Count )
		elseif itemTemp.ItemType == EItemType.Wanted then
		    local UserData = require "Data.UserData"
	    	UserData.Instance():SetField("LastWantedItemQuality", itemTemp.InitQuality)
			UserData.Instance():SaveDataToFile()
		end
		local event = UseItemEvent()
		event._ID = msg.itemTid
		event._ItemType = msg.itemType
		CGame.EventManager:raiseEvent(msg, event)
		CPanelLottery.Instance()._UseItemId = msg.itemTid
		UseBagCoupon(msg.itemTid,msg.Count)
	else
		-- OnItemUseResultCode(msg.result)
		game._GUIMan:ShowErrorCodeMsg(msg.result, nil)
	end
end
PBHelper.AddHandler("S2CItemUseResult", OnS2CItemUseResult)