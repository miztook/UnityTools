--
-- S2CEntityDisappear
--

local PBHelper = require "Network.PBHelper"
local CEntityMan = require "Main.CEntityMan"
local EntityStatis = require "Profiler.CEntityStatistics"
local Util = require "Utility.Util"

local function FireEvent(id)
	local Lplus = require "Lplus"
	local CGame = Lplus.ForwardDeclare("CGame")
	local EntityDisappearEvent = require "Events.EntityDisappearEvent"
	local e = EntityDisappearEvent()
	e._ObjectID = id
	CGame.EventManager:raiseEvent(nil, e)
end

local function OnEntityDisappear( sender,msg )
	if msg.EntityIdList ~= nil and #msg.EntityIdList > 0 then	
		local npcMan = game._CurWorld._NPCMan

		for i,v in ipairs(msg.EntityIdList) do
			local man = game._CurWorld:DispatchManager(v)
			if man ~= nil then

				-- for jira 3588
				if man == npcMan then
					local monster = man._ObjMap[v]
					if monster ~= nil and monster._MonsterTemplate ~= nil then
						local tid = monster._MonsterTemplate.Id
						if tid == 22200 then
							warn("TERA-3588: 怪物22200离开地图了")
						end
					end
				end

				EntityStatis.Unregister(v)
				local leaveType = Util.CalcSightUpdateType(msg.SightUpdateData.type, msg.SightUpdateData.reason)
				man:Remove(v, leaveType)
				FireEvent(v)
			end
		end
	end
end

PBHelper.AddHandler("S2CEntityDisappear", OnEntityDisappear)