
--
-- S2CCampUpdate  阵营信息更新
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnS2CCampUpdate(sender, msg)
     local NotifyPropEvent = require "Events.NotifyPropEvent"
	local event = NotifyPropEvent()

    local hp = game._HostPlayer
    if msg.EntityID ~= nil and msg.EntityID == hp._ID then
        hp._InfoData._CampId = msg.CampId
        local players = game._CurWorld._PlayerMan._ObjMap
        for _,v in pairs(players) do
            if v._TopPate ~= nil then
                v._TopPate:UpdateName(true)
                v:UpdateTopPateRescue()
            end
        end
        event.ObjID = 0
    else
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:SetCampId(msg.CampId)		    
        end
        event.ObjID = msg.EntityID
    end
    
	event.Type = ""
	CGame.EventManager:raiseEvent(nil, event)
    -- 	刷新选中目标
    local curTarget = hp._CurTarget
    if msg.EntityID == hp._ID or (curTarget ~= nil and msg.EntityID == curTarget._ID) then
        hp:UpdateTargetSelected()
        --local is_locked = hp._IsTargetLocked
        --CFxMan.Instance():OnTargetSelected(curTarget, is_locked)
    end

end
PBHelper.AddHandler("S2CCampUpdate", OnS2CCampUpdate)