local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBattleMiddle = require"GUI.CPanelBattleMiddle"
local PBHelper = require "Network.PBHelper"

--正式开始
local function OnS2CEliminateStart(sender, msg)
	game._CArenaMan:OnS2CEliminateStart()
end
PBHelper.AddHandler("S2CEliminateStart",OnS2CEliminateStart)


-- 下线在上线先发S2CDungeonAdditionInfo 消息初始化信息 然后再发S2CEliminateInfo
local function OnS2CEliminateInfo(sender, msg)
	game._CArenaMan:OnS2CEliminateInfo(msg)
end
PBHelper.AddHandler("S2CEliminateInfo",OnS2CEliminateInfo)

--------------------------------------不同于1v1和3v3处理-------------------------------
--同步角色信息
local function OnS2CEliminateRoleInfos(sender, msg)
	game._CArenaMan:OnS2CEliminateRoleInfos(msg)
end
PBHelper.AddHandler("S2CEliminateRoleInfos", OnS2CEliminateRoleInfos)

--积分更新
local function OnS2CEliminateScoreUpdate(sender,msg)
	game._CArenaMan:OnS2CEliminateScoreUpdate(msg)
end
PBHelper.AddHandler("S2CEliminateScoreUpdate", OnS2CEliminateScoreUpdate)

--通知谁持有中心物件
local function OnS2CEliminateCenterItemUpdate(sender,msg)
	game._CArenaMan:OnS2CEliminateCenterItemUpdate(msg)
end
PBHelper.AddHandler("S2CEliminateCenterItemUpdate", OnS2CEliminateCenterItemUpdate)

-- 击杀通知
local function OnS2CEliminateKillInfo(sender,msg)
	game._CArenaMan:OnS2CEliminateKillInfo(msg)
end
PBHelper.AddHandler("S2CEliminateKillInfo", OnS2CEliminateKillInfo)

--结算
local function OnS2CEliminateReward(sender, msg)
	game._CArenaMan:OnS2CEliminateReward(msg)
end
PBHelper.AddHandler("S2CEliminateReward",OnS2CEliminateReward)
