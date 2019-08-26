--
-- S2CSyncCareList
--

local PBHelper = require "Network.PBHelper"

local function OnSyncCarePlayerList( sender,msg )
    if game._CurWorld ~= nil and game._CurWorld._PlayerMan ~= nil then
        game._CurWorld._PlayerMan:UpdateCarePlayerList(msg.CareList, msg.RoleInfoList)
    end
end

PBHelper.AddHandler("S2CSyncCareList",OnSyncCarePlayerList)