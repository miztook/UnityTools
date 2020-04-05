--
--S2CActivity 日常活动
--
local PBHelper = require "Network.PBHelper"

--上线发送的活跃度值和活动数据
local function OnS2CActivityList(sender, msg)
	-- warn("---------------OnS2CActivityList---------------", msg.Liveness)
	game._CalenderMan: LoadActivityState(msg)
end
PBHelper.AddHandler("S2CActivityList", OnS2CActivityList)

--更新活跃度和活动数据
local function OnS2CActivityUpdate(sender,msg)    
	-- warn("---------------OnS2CActivityUpdate---------------", msg.Liveness)
	game._CalenderMan: ChangeActivityState(msg)
end
PBHelper.AddHandler("S2CActivityUpdate", OnS2CActivityUpdate)

--领取活跃度奖励
local function OnS2CActivityEnable(sender,msg)
	game._CalenderMan: ActivityEnable(msg.ActivityId, msg.IsActivity)
end
PBHelper.AddHandler("S2CActivityEnable", OnS2CActivityEnable)