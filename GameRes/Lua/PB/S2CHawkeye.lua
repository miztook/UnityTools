--
-- S2CHawkeye
-- 
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CHawkeyeEffectMan = require "Main.CHawkeyeEffectMan"

local function OnHawkeyeState(sender, msg)
	--print( "OnHawkeyeState",msg.errorCode,msg.enabel )
	if msg.errorCode == 0 then
		CHawkeyeEffectMan.Instance():EnableHawkeyeState(msg.enabel, -1)
	else
		--TODO("鹰眼模式开启失败 - " .. msg.errorCode)
		game._GUIMan:ShowErrorTipText(msg.errorCode)
	end
end

PBHelper.AddHandler("S2CHawkeyeState", OnHawkeyeState)

local function OnHawkeyeInfo(sender, msg)
	local man = CHawkeyeEffectMan.Instance()
	man:UpdateHawkeyeInfo(msg.remainCount, msg.regions)
	man:EnableHawkeyeState(msg.enabel, msg.enableTime)

	if msg.status > 0 then
		EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeOpen, msg)
	elseif msg.status == 0 then
		EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeClose, nil)		
	end
end

PBHelper.AddHandler("S2CHawkeyeInfo", OnHawkeyeInfo)

local function OnHawkeyeMapInfo(sender, msg)
	local CPanelMap = require "GUI.CPanelMap"	
 	CPanelMap.Instance():ShowEyeRegions( msg )
end

PBHelper.AddHandler("S2CHawkeyeMapInfo", OnHawkeyeMapInfo)

local function OnS2COpenMemoryEffect(sender, msg)
	--print("OnS2COpenMemoryEffect", msg.Id)
	GameUtil.ChangeSceneWeatherByMemory( msg.Id )
end

PBHelper.AddHandler("S2COpenMemoryEffect", OnS2COpenMemoryEffect)

