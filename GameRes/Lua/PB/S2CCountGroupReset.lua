local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CQuest = Lplus.ForwardDeclare("CQuest")

local function OnS2CCountGroupReset(sender,msg)
	CQuest.Instance():OnS2CCountGroupReset(msg.cgs)
	-- 重置当前所有次数。   -- lidaming  2018/06/26
	-- game._CountGroupData = msg.CountGroups
end
PBHelper.AddHandler("S2CCountGroupReset", OnS2CCountGroupReset)
