--
-- S2CHawkeye
-- 
local PBHelper = require "Network.PBHelper"

local function OnHawkeyeState(sender, msg)
	print( msg )
	if msg.errorCode == 0 then
		--TODO("鹰眼模式开启成功")
		if msg.enabel then
			game._HostPlayer:OnHawkeye()
			game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.Eye_Use,nil)
			print("EnumDef.EShortCutEventType.Eye_Use")
		else
			game._HostPlayer:OnHawkeyeOver()
			game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.Eye_UseOver,nil)
		end
else
		--TODO("鹰眼模式开启失败 - " .. msg.errorCode)
	end
end

PBHelper.AddHandler("S2CHawkeyeState", OnHawkeyeState)

local function OnHawkeyeInfo(sender, msg)
	game._HostPlayer._HawkEyeCount = msg.remainCount
	game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.Eye_Open,{on_click=function(count)game._HostPlayer:SendHawkeyeUseOrStop(count)end,count=msg.remainCount,recoverTime=msg.recoverTime})
end

PBHelper.AddHandler("S2CHawkeyeInfo", OnHawkeyeInfo)