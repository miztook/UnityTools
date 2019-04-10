
BlankTable = function() return {} end

Object          = UnityEngine.Object
Application     = UnityEngine.Application
SystemInfo      = UnityEngine.SystemInfo
Time            = UnityEngine.Time
PlayMode        = UnityEngine.PlayMode
Resources       = UnityEngine.Resources

_G.SendProtocol = function(protocol)
	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(protocol)
end

_G.GetC2SProtocol = function(strProtocolName)
	local protocol = require "PB.net"[strProtocolName]
	return protocol()
end

_G.SendHorseSetProtocol = function(horseTid, isOn)
	local C2SHorseSet = require "PB.net".C2SHorseSet
	local protocol = C2SHorseSet()

	local EHorseOptType = require "PB.net".EHorseOptType
	if horseTid == -1 then
		if isOn then
			protocol.OptType = EHorseOptType.HorseOpt_Mount
		else
			protocol.OptType = EHorseOptType.HorseOpt_Unmount
		end
	else
		protocol.OptType = EHorseOptType.HorseOpt_Set
        protocol.HorseID = horseTid
	end
	
	SendProtocol(protocol)
end