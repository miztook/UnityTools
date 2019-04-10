--
-- S2CChangeHate
--

local PBHelper = require "Network.PBHelper"

local function OnS2CChangeHate(sender, msg)
    if msg.OptCode ~= nil and msg.EntityID ~= nil then
    	local hp = game._HostPlayer

    	if hp == nil then return end

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

		local EHateOpt = require "PB.net".HATE_OPT
		if msg.OptCode == EHateOpt.HATE_OPT_REMOVE then
			-- 解除仇恨，尝试关闭相机视角锁定状态
			game:UpdateCameraLockState(msg.EntityID, false)
		end
    end
end
PBHelper.AddHandler("S2CChangeHate", OnS2CChangeHate)