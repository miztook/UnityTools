
--
-- S2CCampUpdate  阵营信息更新
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local ECampUpdateType = require "PB.net".ECampUpdateType

local function OnS2CCampUpdate(sender, msg)
    -- warn("lidaming ----------> msg.UpdateType ==", msg.UpdateType, msg.EntityID, msg.CampId)
    -- 如果当前阵营类型为self，设置自己的阵营。
    if msg.UpdateType == ECampUpdateType.ECampUpdateType_SetSelf then
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:SetCampId(msg.CampId)		    
        end
    elseif msg.UpdateType == ECampUpdateType.ECampUpdateType_AddEnemy then
        -- 添加敌对阵营ID
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:AddEnemyCampId(msg.CampId)		    
        end
    elseif msg.UpdateType == ECampUpdateType.ECampUpdateType_RemoveEnemy then
        -- 移除敌对阵营ID
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:RemoveEnemyCampId(msg.CampId)		    
        end
    elseif msg.UpdateType == ECampUpdateType.ECampUpdateType_Clear then
        -- 清空敌对阵营ID
        local entity = game._CurWorld:FindObject(msg.EntityID)
        if entity then
            entity:ClearEnemyCampId(msg.CampId)		    
        end
    end
    -- 刷新当前世界所有玩家名字颜色   2018/06/08 lidaming
    -- 	刷新选中目标
    local hp = game._HostPlayer
    local curTarget = hp._CurTarget
    -- warn("lidaming hp._ID ==", hp._ID)
    if msg.EntityID == hp._ID then
        hp:UpdateTargetSelected()
        -- local is_locked = hp._IsTargetLocked
        -- CFxMan.Instance():OnTargetSelected(curTarget, is_locked)
        local playerMap = game._CurWorld._PlayerMan._ObjMap
        for _, player in pairs(playerMap) do
            if player._TopPate ~= nil then
                player._TopPate:UpdateName(true)
                player:UpdatePetName()
                player:UpdateTopPateRescue()
            end
        end
    end

end
PBHelper.AddHandler("S2CCampUpdate", OnS2CCampUpdate)