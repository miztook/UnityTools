local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CGame = Lplus.ForwardDeclare("CGame")

local function OnS2CCountGroupReset(sender,msg)
	if msg.cgs == nil then return end
	CQuest.Instance():OnS2CCountGroupReset(msg.cgs)
	-- 重置当前所有次数。   -- lidaming  2018/06/26
	-- warn("lidaming S2CCountGroupReset ====>>> ", msg.cgs.Tid, msg.cgs.BuyCount, msg.cgs.Count)

	if game._CCountGroupMan._CountGroupData ~= nil then
		for i,v in pairs(game._CCountGroupMan._CountGroupData) do
			if v.Tid == msg.cgs.Tid then 
				v.Count = msg.cgs.Count
				v.BuyCount = msg.cgs.BuyCount
			end 
		end

		local  CountGroupUpdateEvent = require "Events.CountGroupUpdateEvent"
        local event = CountGroupUpdateEvent()
        event._CountGroupTid = msg.cgs.Tid
        CGame.EventManager:raiseEvent(nil, event) 
	end
end
PBHelper.AddHandler("S2CCountGroupReset", OnS2CCountGroupReset)
