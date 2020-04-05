--
-- gp_test
-- 
local PBHelper = require "Network.PBHelper"

local function on_enter_world( sender,msg )
	warn("gp_self_enter_world", msg.world_id, msg.world_tid, msg.line_id)
end

PBHelper.AddHandler("gp_self_enter_world",on_enter_world)
