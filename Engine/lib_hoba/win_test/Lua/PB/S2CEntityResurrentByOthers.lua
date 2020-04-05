--
-- S2CEntityResurrentByOthers
--

local PBHelper = require "Network.PBHelper"

local function OnS2CEntityResurrentByOthers(sender, protocol)
--warn("==========S2C::OnS2CEntityResurrentByOthers==============")
	--warn("protocol.DeathState = ", protocol.DeathState)
	local object = game._CurWorld:FindObject(protocol.EntityId)
	if object == nil then return end

	object._DeathState = protocol.DeathState
	
	local objType = object:GetObjectType()
	local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
	if objType == OBJ_TYPE.ELSEPLAYER then
		object:SendPropChangeEvent("Rescue")
	end

	if protocol.EntityId == game._HostPlayer._ID then
		local CPanelRevive = require "GUI.CPanelRevive"
		if CPanelRevive.Instance():IsShow() then
			CPanelRevive.Instance():SetEnableAcceptBtn(true)
		end
	end
end

PBHelper.AddHandler("S2CEntityResurrentByOthers", OnS2CEntityResurrentByOthers)