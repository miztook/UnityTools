local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UseItemEvent = require "Events.UseItemEvent"
local CPanelLottery = require"GUI.CPanelLottery"

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

local function OnS2CItemUseResult(sender, msg)
	if msg.result == 0 then
		local event = UseItemEvent()
		event._ID = msg.itemTid
		event._ItemType = msg.itemType
		CGame.EventManager:raiseEvent(msg, event)
		CPanelLottery.Instance()._UseItemId = msg.itemTid
	else
		-- OnItemUseResultCode(msg.result)
		game._GUIMan:ShowErrorCodeMsg(msg.result, nil)
	end
end
PBHelper.AddHandler("S2CItemUseResult", OnS2CItemUseResult)