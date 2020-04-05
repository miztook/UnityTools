local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EquipDevEvent = require "Events.EquipDevEvent"
local UseItemEvent = require "Events.UseItemEvent"
local BAGTYPE = require "PB.net".BAGTYPE

local RaiseEvent = function(protocol)
    local event = EquipDevEvent()
    event._Msg = protocol
    CGame.EventManager:raiseEvent(nil, event)
end

--重铸结果
local function OnItemRebuildResult(sender, protocol)
	local pack = game._HostPlayer._Package._EquipPack
	local Item = pack:GetItemBySlot(protocol.Index)
	if Item == nil then return end
	
	Item:SetNewEquipAttrs(protocol.Attrs)
	RaiseEvent(protocol)
end

PBHelper.AddHandler("S2CItemRebuildResult", OnItemRebuildResult)

local hintImgPath = _G.CommonAtlasDir.."Icon/UserTips/Img_NewTips_NewSkill2.png"

--使用物品失败返回错误码对应提示
local ServerMessageId = require "PB.data".ServerMessageId
local function OnItemUseResultCode(code)
	if code == ServerMessageId.ItemUseCoolDown then
		game._GUIMan:ShowTipText(StringTable.Get(19503), false)
	elseif code == ServerMessageId.Failed then
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
	else
		OnItemUseResultCode(msg.result)
	end
end
PBHelper.AddHandler("S2CItemUseResult", OnS2CItemUseResult)