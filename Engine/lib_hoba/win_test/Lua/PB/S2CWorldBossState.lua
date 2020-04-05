--
-- S2CWorldBossState   世界Boss状态
--


local PBHelper = require "Network.PBHelper"


-- 读取世界boss状态
local function OnS2CWorldBossState(sender, msg)
    -- warn("S2CWorldBossState Reason == ", msg.Reason, "OpenTime == ", msg.OpenTime)
    local param = 
    {
        ActivityId = msg.ActivityId,
        Reason = msg.Reason,
        OpenTime = msg.OpenTime,
        CloseTime = msg.CloseTime,
        IsDeath = msg.IsDeath, 
    }
    --print_r(param)
    game._GUIMan:Open("CPanelWorldBoss", param)


end
PBHelper.AddHandler("S2CWorldBossState", OnS2CWorldBossState)