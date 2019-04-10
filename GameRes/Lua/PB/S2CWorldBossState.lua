--
-- S2CWorldBossState   世界Boss状态
--

local PBHelper = require "Network.PBHelper"

-- 读取所有世界boss状态
local function OnS2CWorldBossState(sender, msg)
    -- print_r(msg.data)
    -- warn("S2CWorldBossState msg.data == ", #msg.data)    
    game._CWorldBossMan:ChangeWorldBossState(msg)
end
PBHelper.AddHandler("S2CWorldBossState", OnS2CWorldBossState)


-- 击杀世界boss获得奖励通知
local function OnS2CWorldBossRewardInfo(sender, msg)
    -- warn("S2CWorldBossRewardInfo msg.RemainDropCount == ", msg.BossId, msg.RemainDropCount) 
    -- [21011] = "今日掉落次数已用完",
    if msg.RemainDropCount <= 0 then
        game._GUIMan: ShowTipText(StringTable.Get(21011),false) 
    end
    game._GUIMan:Open("CPanelUIWorldBossReward", msg)
end
PBHelper.AddHandler("S2CWorldBossRewardInfo", OnS2CWorldBossRewardInfo)

-- 世界boss个人剩余掉落次数
local function OnS2CWorldBossPersonalLeftDropCount(sender, msg)
    -- print_r(msg.data)
    game._CWorldBossMan:SetWorldBossPersonalLeftDropCount(msg)
end
PBHelper.AddHandler("S2CWorldBossPersonalLeftDropCount", OnS2CWorldBossPersonalLeftDropCount)

-- 返回精英Boss击杀状态信息
local function OnS2CEliteBossKillStateInfo(sender, msg)
    -- print_r(msg.data)
    -- warn("S2CEliteBossKillStateInfo msg.data == ", #msg.EliteBossInfoList)    
    game._CWorldBossMan:ChangeEliteBossKillState(msg)
end
PBHelper.AddHandler("S2CEliteBossKillStateInfo", OnS2CEliteBossKillStateInfo)


-- 返回精英Boss地图存活信息
local function OnS2CEliteBossMapStateInfo(sender, msg)
    -- print_r(msg.data)
    -- warn("S2CEliteBossMapStateInfo msg.data == ", msg.MapTid, #msg.EliteBossInfoList)    
    game._CWorldBossMan:ChangeEliteBossMapState(msg)
end
PBHelper.AddHandler("S2CEliteBossMapStateInfo", OnS2CEliteBossMapStateInfo)