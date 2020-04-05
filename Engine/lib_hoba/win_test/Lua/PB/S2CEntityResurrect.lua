--
-- S2CEntityResurrect
--

local PBHelper = require "Network.PBHelper"

local function OnEntityResurrect(sender, protocol)

	local object = game._CurWorld:FindObject(protocol.EntityId)
	if object == nil then return end
	
	local EDEATH_STATE = require "PB.net".DEATH_STATE    --死亡状态类型

	object._DeathState = EDEATH_STATE.LIVE
	object:Stand()
	object:EnableShadow(true)
	object:SetPos(protocol.Pos)
	object:SetDir(Vector3.New(protocol.Orientation.x, 0, protocol.Orientation.z))
	object:ResetCombatState()
	CFxMan.Instance():Play(PATH.Gfx_Resurrect, object:GetPos(), Quaternion.identity, -1, EnumDef.CFxPriority.Always)

	if object._ID ~= game._HostPlayer._ID then
		if object._TopPate ~= nil then
			object._TopPate:SetVisible(true)
			object:UpdateTopPate()
		end
	else
		game._GUIMan:Close("CPanelRevive")

		local iType = protocol.ResurrentType
		local EResurrectType = require "PB.net".ResurrectType

		if EResurrectType.InPlaceFree == iType or EResurrectType.InPlaceCharge == iType or EResurrectType.AccpetHelp == iType then
			-- do nothing
		elseif EResurrectType.SafeResurrent == iType or EResurrectType.InstanceSafeResurrent then
			GameUtil.QuickRecoverCam()
		elseif EResurrectType.ExitResurrent == iType then
			--退出副本 & 返回就近复活点
			GameUtil.QuickRecoverCam()		
		end

	   	local pointer = object._GameObject:FindChild("ForwardPointer")
		pointer:SetActive(true)

		local CVisualEffectMan = require "Effects.CVisualEffectMan"
		CVisualEffectMan.ShowDeadScreen(false)
	end
end

PBHelper.AddHandler("S2CEntityResurrect", OnEntityResurrect)

--[[

enum ResurrectType
{
	ToResurrectPos = 0;
	AccpetHelp = 1;			//救援复活
	InPlaceFree = 2;		//原地复活免费
	InPlaceCharge = 3;		//原地复活收费
	SafeResurrent = 4;		//就近复活：最近的复活点（大世界）
	ExitResurrent = 5;		//退出副本复活（副本）
	InstanceSafeResurrent = 6;//就近复活：最近的复活点（副本）
}

]]