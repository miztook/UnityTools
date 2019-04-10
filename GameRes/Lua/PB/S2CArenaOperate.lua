local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"

--------------------1v1--------------------

local function OnS2CJJC1x1State(sender, msg)
	game._CArenaMan:OnS2C1V1State(msg)
end
PBHelper.AddHandler("S2CJJC1x1State", OnS2CJJC1x1State)

local function OnS2CJJC1x1Reward(sender, msg)
	game._CArenaMan:OnS2C1V1Reward(msg)
end
PBHelper.AddHandler("S2CJJC1x1Reward", OnS2CJJC1x1Reward)

local function OnS2CJJC1x1Info(sender, msg)
	game._CArenaMan:OnS2C1V1Info(msg)
end

PBHelper.AddHandler("S2CJJC1x1Info", OnS2CJJC1x1Info)

--------------------1v1--------------------

--------------------3v3--------------------


--3V3正式开始
local function Start3V3Arena(sender, msg)
	game._CArenaMan:OnS2CStart3V3()
end
PBHelper.AddHandler("S2CArenaStart",Start3V3Arena)

--3V3结束
local function End3V3Arena(sender, msg)
	game._HostPlayer: Set3v3RoomID(0) 
end
PBHelper.AddHandler("S2CArenaEnd",End3V3Arena)


--3V3结算
local function On3V3ArenaReward(sender, msg)
	game._CArenaMan:OnS2C3V3Reward(msg)
end
PBHelper.AddHandler("S2CArenaReward",On3V3ArenaReward)


-----------------------3v3End----------------------------

-- 断线重连后3v3 和1v1 无畏战场、头像和界面 显示内容
-- 在3v3 中一个队友断线 重连后其他队员也发送该条消息 但是收到的只是该下线队员的相关消息
local function OnDungeonAdditionInfo(sender, msg)
	game._CArenaMan:OnS2CDungeonAdditionInfo(msg)
end
PBHelper.AddHandler("S2CDungeonAdditionInfo",OnDungeonAdditionInfo)

----------------------------------断线重连 返回的3v3和无畏战场匹配状态-------------------------------
local function OnS2CMatchRestoreData(sender, msg)
	game._CArenaMan:OnS2CMatchRestoreData(msg)
end
PBHelper.AddHandler("S2CMatchRestoreData",OnS2CMatchRestoreData)