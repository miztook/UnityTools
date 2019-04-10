--
-- S2CHawkeye
-- 
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

local function OnHawkeyeState(sender, msg)
	print( "OnHawkeyeState",msg.errorCode,msg.enabel )
	if msg.errorCode == 0 then
		game._HostPlayer:SetHawkeyeState( msg.enabel,-1 )
	else
		--TODO("鹰眼模式开启失败 - " .. msg.errorCode)
		game._GUIMan:ShowErrorTipText(msg.errorCode)
	end
end

PBHelper.AddHandler("S2CHawkeyeState", OnHawkeyeState)

local function OnHawkeyeInfo(sender, msg)
	print( "OnHawkeyeInfo",msg.remainCount,msg.recoverTime,msg.enabel,msg.status )
	local hp = game._HostPlayer

	hp._HawkEyeCount = msg.remainCount
	hp:UpdateHawkEyeTargetPos( msg.regions,msg.status )
	hp:SetHawkeyeState( msg.enabel,msg.enableTime )

	if msg.status > 0 then
		game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeOpen, msg)
	elseif msg.status == 0 then
		game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeClose, nil)		
	end
end

PBHelper.AddHandler("S2CHawkeyeInfo", OnHawkeyeInfo)

local function OnHawkeyeMapInfo(sender, msg)
	--print( "OnHawkeyeMapInfo" )

	local CPanelMap = require "GUI.CPanelMap"	
 	CPanelMap.Instance():ShowEyeRegions( msg )
end

PBHelper.AddHandler("S2CHawkeyeMapInfo", OnHawkeyeMapInfo)

local function OnS2COpenMemoryEffect(sender, msg)
	print("OnS2COpenMemoryEffect", msg.Id)
	GameUtil.ChangeSceneWeatherByMemory( msg.Id )
end

PBHelper.AddHandler("S2COpenMemoryEffect", OnS2COpenMemoryEffect)

