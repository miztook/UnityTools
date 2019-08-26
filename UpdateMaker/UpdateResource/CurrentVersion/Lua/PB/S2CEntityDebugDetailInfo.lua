--
-- S2CEntityDebugDetailInfo  2017.11.24 --- LDM
--

local PBHelper = require "Network.PBHelper"

local function OnEntityDebugDetailInfo(sender, msg)
    -- warn("lidaming msg.EntityDebugInfos == ", #msg.EntityDebugInfos)
	for _,k in pairs(msg.EntityDebugInfos) do        
        if k.EntityId == nil then return end
        local entity = game._CurWorld:FindObject(k.EntityId)
        if entity == nil then return end
        entity._InitPos = k.ServerPosition
        -- local serverPosX = string.format("%.2f", k.ServerPosition.x)
        -- local serverPosZ = string.format("%.2f", k.ServerPosition.z)
        -- local serverPosY = string.format("%.2f", k.ServerPosition.y)
        -- local serverPos = serverPosX .. "," .. serverPosZ .. "," .. serverPosY
        -- local text = ""
        -- if tonumber(entity:GetTemplateId()) ~= 0 then
        --     text = tostring(entity:GetTemplateId()) .. ", ClientPos:".. clientPos .. ", ServerPos:".. serverPos
        -- else
        --     text = entity._ID .. ", ClientPos:".. clientPos .. ", ServerPos:".. serverPos
        -- end
        -- warn("lidaming serverPos == ".. serverPos)
        -- -- entity:ShowPopText(true, text, 10)
        -- if entity._TopPate ~= nil then
        --     entity._TopPate:UpdateName(true)
        -- end
    end
    
end
PBHelper.AddHandler("S2CEntityDebugDetailInfo", OnEntityDebugDetailInfo)

 