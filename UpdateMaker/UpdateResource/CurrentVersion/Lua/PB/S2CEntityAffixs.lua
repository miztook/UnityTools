--
--S2CEntityAffixs 同步怪物词缀
--
local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CEntityAffixs(sender,protocol)
--warn("=============OnS2CEntityAffixs=============")
	local monster = game._CurWorld:FindObject( protocol.EntityId )
	if monster ~= nil then
		monster:SetAffixIds( protocol.Affixs )
		monster:ResetAffix()
	end
end
PBHelper.AddHandler("S2CEntityAffixs", OnS2CEntityAffixs)