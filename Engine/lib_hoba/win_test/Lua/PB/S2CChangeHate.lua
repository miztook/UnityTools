--
-- S2CChangeHate
--

local PBHelper = require "Network.PBHelper"

local function OnS2CChangeHate(sender, msg)
    if msg.OptCode ~= nil and msg.EntityID ~= nil then
    	local hp = game._HostPlayer
        hp:SetEntityHate(msg.OptCode, msg.EntityID)

		local playerMan = game._CurWorld._PlayerMan._ObjMap
		for _,v in pairs(playerMan) do
			v:UpdateTopPateHpLine()
	    end

		local monsterMan = game._CurWorld._NPCMan._ObjMap
		for _,v in pairs(monsterMan) do
			if hp:IsEntityHate(v._ID) then
				v:OnBattleTopChange(true)
			else
				v:OnBattleTopChange(false)
			end
	    end
    end
end
PBHelper.AddHandler("S2CChangeHate", OnS2CChangeHate)