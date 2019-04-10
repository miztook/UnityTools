--
-- S2CChangeMainCamera 调整跟随相机
--
local PBHelper = require "Network.PBHelper"

local function OnS2CChangeMainCamera(sender,msg)
	warn("OnS2CChangeMainCamera opt:", msg.opt)
	if msg.opt == 0 then
		-- 调整参数
		GameUtil.SetDestDistOffsetAndDestPitchDeg(msg.offsetDist, msg.pitchDegDest, msg.offsetDistSpeed, msg.pitchDegDestSpeed)
	elseif msg.opt == 1 then
		-- 转向某个单位
		local entity = game._CurWorld:FindObject(msg.entityId)
		if entity ~= nil then
			local x, z = entity:GetPosXZ()
			GameUtil.QuickRecoverCamToDest(x, z)
		end
	end
end
PBHelper.AddHandler("S2CChangeMainCamera", OnS2CChangeMainCamera)
