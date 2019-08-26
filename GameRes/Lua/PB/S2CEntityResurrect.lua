--
-- S2CEntityResurrect
--

local PBHelper = require "Network.PBHelper"

local function OnEntityResurrect(sender, protocol)
	-- warn("收到复活协议， id : ", protocol.EntityId)

	local object = game._CurWorld:FindObject(protocol.EntityId)
	if object == nil then
		-- error("Entity resurrect failed, can not find entity with Id:" .. protocol.EntityId)
		return
	end
	-- warn("收到复活协议, object name : ", object:GetEntityColorName())

	object:SetPos(protocol.Pos)
	object:SetDir(Vector3.New(protocol.Orientation.x, 0, protocol.Orientation.z))
	object:OnResurrect()
	if object:IsHostPlayer() then
		local EResurrectType = require "PB.net".ResurrectType
		if EResurrectType.SafeResurrent == protocol.ResurrentType and protocol.IsClickSafeResurrent then
			-- 安全复活
			if not game._HostPlayer:InDungeon() and game._PlayerStrongMan:GetShowPlayerStrongPanelState() then 
				game._GUIMan:Open("CPanelStrong",nil)
			end
		end
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Resurrect, 0)
	end
end

PBHelper.AddHandler("S2CEntityResurrect", OnEntityResurrect)

--[[

enum ResurrectType
{
	ToResurrectPos = 0;
	AccpetHelp = 1;			//救援复活
	InPlaceFree = 2;		//原地复活免费
	SafeResurrent = 4;		//安全复活
}

]]