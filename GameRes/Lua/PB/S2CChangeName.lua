local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnS2CChangeNameRes(sender, protocol)	
	if protocol.ResCode == 0 then
		local object = game._CurWorld:FindObject(protocol.RoleId)
		if object ~= nil then
			object._InfoData._Name = protocol.NewName
			if object._TopPate ~= nil then
				object._TopPate:UpdateName(true)
			end

			local EntityNameChangeEvent = require "Events.EntityNameChangeEvent"
			local event = EntityNameChangeEvent()
			event._EntityId = protocol.RoleId
			CGame.EventManager:raiseEvent(nil, event)
		end
	else
		game._GUIMan:ShowErrorCodeMsg(protocol.ResCode, nil)
	end
end

PBHelper.AddHandler("S2CChangeNameRes", OnS2CChangeNameRes)