--
-- S2CEntityResurrectTypes
--

local PBHelper = require "Network.PBHelper"

local function OnEntityResurrectTypes(sender, msg)

	local EResurrectType = require "PB.net".ResurrectType

	local bInPlaceFree 				= false
	local bInPlaceCharge 			= false
	local bSafeResurrent 			= false
	local bExitResurrent			= false
	local bInstanceSafeResurrent	= false

	for i = 1, #msg.ResurrentTypes do  
        local idx = msg.ResurrentTypes[i]

        if EResurrectType.InPlaceFree == idx then
        	bInPlaceFree = true
        elseif EResurrectType.InPlaceCharge == idx then
        	bInPlaceCharge = true
        elseif EResurrectType.SafeResurrent == idx then
        	bSafeResurrent = true
        end
    end  
	
	local param = 
	{
		countDownMax = msg.Countdown,
		daySurrentTimes = msg.DaySurrentTimes,
		instanceSurrentTimes = msg.InstanceSurrentTimes,
		cost = msg.Cost,
		resurrectPositionName = msg.ResurrectPositionName,

		ButtonNeedShow = 
		{
			bInPlaceFree = bInPlaceFree,
			bInPlaceCharge = bInPlaceCharge,
			bSafeResurrent = bSafeResurrent,
		}
	}

	game._GUIMan:Open("CPanelRevive",param)
end

PBHelper.AddHandler("S2CEntityResurrectTypes", OnEntityResurrectTypes)

--[[
enum ResurrectType
{

	AccpetHelp				//救援复活
	InPlaceFree				//原地复活免费
	InPlaceCharge			//原地复活收费
	SafeResurrent			//就近复活：最近的复活点（大世界）
	ExitResurrent			//退出副本复活（副本）
	InstanceSafeResurrent	//就近复活：最近的复活点（副本）
}
]]