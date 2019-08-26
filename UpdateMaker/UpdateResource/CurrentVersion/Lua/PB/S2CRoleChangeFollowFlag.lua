local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CRoleChangeFollowFlag(sender,protocol)
--warn("=============OnS2CRoleChangeFollowFlag=============")
	local hp = game._HostPlayer
	hp:CancelSyncPosWhenMove( protocol.FollowFlag )
end
PBHelper.AddHandler("S2CRoleChangeFollowFlag", OnS2CRoleChangeFollowFlag)