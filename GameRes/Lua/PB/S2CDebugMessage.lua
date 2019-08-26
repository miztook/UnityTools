--
-- S2CDebugMessage
--

local PBHelper = require "Network.PBHelper"

local function OnDebugMessage(sender, protocol)
	warn("OnDebugMessage", protocol.Message)
	FlashTip(protocol.Message, "tip", 1)
end

PBHelper.AddHandler("S2CDebugMessage", OnDebugMessage)


local function OnEntityDebugInfo(sender, msg)
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		local server_pos = Vector3.New(msg.Position.x, msg.Position.y, msg.Position.z)
		local local_pos = entity:GetPos()
		local oldname = entity._InfoData._Name
		local newName = tostring(server_pos) .. " " tostring(local_pos)
		entity._InfoData._Name = newName
		warn("OnEntityDebugInfo: " .. tostring(server_pos) .. " local_pos " .. tostring(local_pos))
	end
end

PBHelper.AddHandler("S2CEntityDebugInfo", OnEntityDebugInfo)