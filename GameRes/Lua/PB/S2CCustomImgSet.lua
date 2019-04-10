--
-- S2CCustomImgSet
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnS2CCustomImgSet(sender, msg)
    -- warn("OnS2CCustomImgSet  msg.CustomImgSet = ", msg.CustomImgSet , "msg.EntityID == ", msg.EntityID)
    local hp = game._HostPlayer
    local entity = game._CurWorld:FindObject(msg.EntityID)
    if entity then
        entity._InfoData._CustomImgSet = msg.CustomImgSet
    end
    -- if msg.EntityID == hp._ID then
    --     hp:SetCustomImg(msg.CustomImgSet)
    -- else
    --     local entity = game._CurWorld:FindObject(msg.EntityID)
    --     if entity then
    --         entity:SetCustomImg(msg.CustomImgSet)
    --     end
    -- end
    local EntityCustomImgChangeEvent = require "Events.EntityCustomImgChangeEvent"
    local event = EntityCustomImgChangeEvent()
    event._EntityId = msg.EntityID
    CGame.EventManager:raiseEvent(nil, event)

end
PBHelper.AddHandler("S2CCustomImgSet", OnS2CCustomImgSet)

local function OnS2CCustomImgCheckRes(sender, msg)
    warn("lidaming OnS2CCustomImgCheckRes  msg.ResCode = ", msg.ResCode , "msg.RoleId == ", msg.RoleId)
    local hp = game._HostPlayer

    --头像服和游戏服 头像数据通信之后可更新头像。
    local entity = game._CurWorld:FindObject(msg.RoleId)
    if entity then
        entity._InfoData._CustomImgSet = msg.ResCode
    end
    local EntityCustomImgChangeEvent = require "Events.EntityCustomImgChangeEvent"
    local event = EntityCustomImgChangeEvent()
    event._EntityId = msg.RoleId
    CGame.EventManager:raiseEvent(nil, event)

end
PBHelper.AddHandler("S2CCustomImgCheckRes", OnS2CCustomImgCheckRes)
