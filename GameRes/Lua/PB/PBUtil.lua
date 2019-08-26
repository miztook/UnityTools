local Lplus = require "Lplus"
local net = require "PB.net"
local PBHelper = require "Network.PBHelper"

local PBUtil = Lplus.Class("PBUtil")
local def = PBUtil.define

local function sendSelectRoleProtocol(roleId)
	local protocol = net.C2SRoleSelect()
	protocol.RoleId = roleId
	PBHelper.Send(protocol)
	-- 平台SDK打点
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Role_Login)
end

--查询其他玩家信息
local function requestOtherPlayerInfo(nPlayerID, infoType, originType)
	local protocol = net.C2SGetOtherRoleInfo()
    protocol.RoleId = nPlayerID
    protocol.InfoType = infoType
    protocol.Mark = originType or -1

    PBHelper.Send(protocol)
end


local function requestRankReward()
	local protocol = net.C2SRankRewardGet()
	PBHelper.Send(protocol)
end

def.const("function").SendSelectRoleProtocol = sendSelectRoleProtocol
def.const("function").RequestOtherPlayerInfo = requestOtherPlayerInfo
def.const("function").RequestRankReward = requestRankReward

PBUtil.Commit()
return PBUtil