local PBHelper = require "Network.PBHelper"

local function OnS2CArenaUserOnlineData(sender,msg)
	if game._HostPlayer ~= nil then
		game._HostPlayer:SetArenaDataInfo(msg)
	end
end
PBHelper.AddHandler("S2CArenaUserOnlineData", OnS2CArenaUserOnlineData)
local function OnS2CJJC1x1DetailInfo(send,msg)
	if game._HostPlayer ~= nil then
		game._HostPlayer:SetJJCScore(msg)
	end
end
PBHelper.AddHandler("S2CJJC1x1DetailInfo", OnS2CJJC1x1DetailInfo)

local function OnS2CEliminateScoreChange(send, msg)
    if game._HostPlayer ~= nil then
        game._HostPlayer:SetEliminateScore(msg.Score)
    end
end
PBHelper.AddHandler("S2CEliminateSync", OnS2CEliminateScoreChange)