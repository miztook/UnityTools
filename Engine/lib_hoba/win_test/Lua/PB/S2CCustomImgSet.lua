--
-- S2CCustomImgSet
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnS2CCustomImgSet(sender, msg)
    -- warn("OnS2CCustomImgSet  msg.CustomImgSet = ", msg.CustomImgSet , "msg.EntityID == ", msg.EntityID)
    local game = game
    local hp = game._HostPlayer

    --头像服和游戏服 头像数据通信之后可更新头像。
    local NotifyPropEvent = require "Events.NotifyPropEvent"
    local event = NotifyPropEvent()

    if msg.EntityID == hp._ID then
        hp:SetCustomImg(msg.CustomImgSet)
    else
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:SetCustomImg(msg.CustomImgSet)
        end
    end
    event.ObjID = msg.EntityID	
    event.Type = ""
    CGame.EventManager:raiseEvent(nil, event)

end
PBHelper.AddHandler("S2CCustomImgSet", OnS2CCustomImgSet)