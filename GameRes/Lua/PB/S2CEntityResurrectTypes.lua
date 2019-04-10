--
-- S2CEntityResurrectTypes
--

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local PBHelper = require "Network.PBHelper"

local function OnEntityResurrectTypes(sender, msg)
	local CElementData = require "Data.CElementData"
	local EResurrectType = require "PB.net".ResurrectType
	local EntityType = require"PB.data".EntityType

	local buttonList = {}

	for i = 1, #msg.ResurrentTypes do
        local idx = msg.ResurrentTypes[i]
		if EResurrectType.AccpetHelp ~= idx then
			-- 救援复活 废除
        	buttonList[#buttonList+1] = idx
        end
    end
--[[
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker then
		if CPanelTracker.Instance():IsShow() then
			CPanelTracker.Instance():ShowSelfPanel(false)
		else
			-- 任务界面没有打开
			CPanelTracker.Instance():SetMinStatus(true)
		end
	end
]]
	local killerName = ""
	if msg.KillserData.EntityType == EntityType.Role or 
	   msg.KillserData.EntityType == EntityType.PlayerMirror then
		--warn("EntityType : Role")
		killerName = msg.KillserData.Name
	elseif msg.KillserData.EntityType == EntityType.Monster then
		--warn("EntityType : Monster")
		local obj = CElementData.GetTemplate("Monster", msg.KillserData.Tid)
		if obj then
			killerName = obj.TextDisplayName
		end
	elseif msg.KillserData.EntityType == EntityType.Npc then
		--warn("EntityType : Npc")
		local obj = CElementData.GetTemplate("Npc", msg.KillserData.Tid)
		if obj then
			killerName = obj.Name
		end
	end

	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local charge = CSpecialIdMan.Get("ResurrentCharge")
	local cost = tonumber(charge)
	cost = cost*(msg.ReviveMaxTimes - msg.ReviveLeftTimes + 1)

--[[
	warn("CountDownMax = ", msg.Countdown)
	warn("SceneId = ", msg.SceneId)
	warn("RegionId = ", msg.RegionId)
	warn("ReviveLeftTimes = ", msg.ReviveLeftTimes)
	warn("ReviveMaxTimes = ", msg.ReviveMaxTimes)
	warn("cost = ", cost)
	warn("buttonList Count = ", #buttonList)
]]
	-- 复活类型大于0
	local param = 
	{
		CountDownMax = msg.Countdown,
		SceneId = msg.SceneId,
		RegionId = msg.RegionId,
		KillerName = killerName,
		ReviveLeftTimes = msg.ReviveLeftTimes,
		ReviveMaxTimes = msg.ReviveMaxTimes,
		Cost = cost,
		ButtonList = buttonList,
	}
	
	-- game._GUIMan:CloseSubPanelLayer()
	game._GUIMan:CloseToMain()
	
	local CPanelUIRevive = require "GUI.CPanelUIRevive"
	CPanelUIRevive.Instance():SetData(param)
	game._GUIMan:Open("CPanelUIRevive", param)

	-- if CPanelUIRevive.Instance():IsShow() then
	-- 	CPanelUIRevive.Instance():UpdatePanel(param)
	-- else
	-- 	game._GUIMan:CloseSubPanelLayer()
	-- 	game._GUIMan:Open("CPanelUIRevive", param)
	-- end

	local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
	local event = NotifyPowerSavingEvent()
	event.Type = "Dead"
	CGame.EventManager:raiseEvent(nil, event)

end

PBHelper.AddHandler("S2CEntityResurrectTypes", OnEntityResurrectTypes)

--[[
enum ResurrectType
{
	ResurrectType_default = 0;
	AccpetHelp = 1;			//救援复活
	InPlaceFree = 2;		//原地复活免费
	InPlaceCharge = 3;		//原地复活收费
	SafeResurrent = 4;		//就近复活：最近的复活点（大世界）
	AutoRevive 		= 5;	//自动复活，到时间原地自己活
	ReviveLimited	= 6;	//不能复活
}
]]