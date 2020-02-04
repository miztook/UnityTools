--
-- S2CEntityDisappear
--

local PBHelper = require "Network.PBHelper"
local CEntityMan = require "Main.CEntityMan"
--local EntityStatis = require "Profiler.CEntityStatistics"
local CPanelPVPHead = require "GUI.CPanelPVPHead"
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
        local EntityType = EnumDef.EntityType
		for i,v in ipairs(msg.EntityIdList) do
            local entityType = IDMan.GetEntityType(v)            
    		local man = game._CurWorld:DispatchManager(v)
			if man ~= nil then
                -- PlayerMan里面会做特殊处理（carelist）
                if entityType ~= EntityType.Role then
    				local leaveType = Util.CalcSightUpdateType(msg.SightUpdateData.updateType, msg.SightUpdateData.updateReason)
				    man:Remove(v, leaveType)
                end
				FireEvent(v)
			end

			-- 监听事件 不要直接加在这里  -- added by Jerry
			if CPanelPVPHead.Instance():IsShow() then 
				CPanelPVPHead.Instance():Update3V3MemberOffline(v)
			end
		end

	end
end

PBHelper.AddHandler("S2CEntityDisappear", OnEntityDisappear)