--
--成就通信 by luee 2017.1.12
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

--上限发送的成就列表
local function OnS2CAchievementList(sender, msg)
	--warn("!!!!!!!!!!!!!!!!!!!!!!!!!!OnS2CAchievementList")
	for _,v in ipairs(msg.Achieves) do
		game._AcheivementMan: ChangeAchievementState(v)
	end		
end
PBHelper.AddHandler("S2CAchieveList", OnS2CAchievementList)

--完成成就
local function OnS2CAchivementFinish(sender,msg)
	game._AcheivementMan:FinishAchievement(msg.Tid)
end
PBHelper.AddHandler("S2CAchieveInc", OnS2CAchivementFinish)

--领取奖励
local function OnS2CGetAchievementReward(sender,msg)
	game._AcheivementMan:RevGetReward(msg.Tid, msg.errorCode)
end
PBHelper.AddHandler("S2CAchieveDrawRet", OnS2CGetAchievementReward)