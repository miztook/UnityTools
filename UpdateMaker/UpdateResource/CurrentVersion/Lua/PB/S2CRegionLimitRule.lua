-- 场景限制

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local RegionLimitChangeEvent = require "Events.RegionLimitChangeEvent"

-- 针对HostPlayer的场景限制
local function OnRegionLimitRule(sender, protocol)
	game._RegionLimit:Set(protocol)

	local event = RegionLimitChangeEvent()
	CGame.EventManager:raiseEvent(nil, event)
end
PBHelper.AddHandler("S2CRegionLimitRule", OnRegionLimitRule)

-- 针对视野范围内其他玩家的场景限制
local function OnAoiRegionLimitRule(sender, protocol)
	if protocol.RoleId == nil then return end
	local else_player = game._CurWorld._PlayerMan:Get(protocol.RoleId)
	if else_player == nil then
		warn("S2CAoiRegionLimitRule RoleId must be a CElsePlayer Id, wrong id:", protocol.RoleId)
		return
	end
	else_player._IsForbidRescue = protocol.ForbidRescue == true
end
PBHelper.AddHandler("S2CAoiRegionLimitRule", OnAoiRegionLimitRule)