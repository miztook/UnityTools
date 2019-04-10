local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CTeamInviteCache(sender,protocol)
	--warn("=============OnS2CTeamInviteCache=============")
	local CTeamMan = require "Team.CTeamMan"
	CTeamMan.Instance():SyncInviteCache(protocol.roleIds)
end
PBHelper.AddHandler("S2CTeamInviteCache", OnS2CTeamInviteCache)