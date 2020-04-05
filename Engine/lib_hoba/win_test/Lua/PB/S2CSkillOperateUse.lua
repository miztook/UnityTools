 --
-- S2CSkillOperateUse
--

local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CSkillOperateUse(sender,protocol)
--warn("=============OnS2CSkillOperateUse=============")
	if protocol.SkillId and protocol.SkillId > 0 then
		game._HostPlayer:UseSkill(protocol.SkillId)
	end
end
PBHelper.AddHandler("S2CSkillOperateUse", OnS2CSkillOperateUse)