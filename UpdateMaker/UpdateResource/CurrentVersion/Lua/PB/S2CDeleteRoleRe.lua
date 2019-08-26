--
-- S2CDeleteRoleRe
--

local PBHelper = require "Network.PBHelper"
local ROLE_VAILD = require "PB.data".ERoleVaild

local function OnDeleteRoleRe(sender, protocol)
	-- warn("OnDeleteRoleRe", protocol.RoleId, protocol.RoleVaild, game._NetMan._UserName)
	game:DeleteRole(protocol.RoleId, protocol.RoleVaild, protocol.ExpiredTime)
end

PBHelper.AddHandler("S2CDeleteRoleRe", OnDeleteRoleRe)

local function OnS2CRoleRecoverRes(sender, protocol)
	local role_list = game._AccountInfo._RoleList

	for i, v in ipairs(role_list) do
		if v.Id == protocol.RoleId then
			v.RoleVaild = ROLE_VAILD.Vaild
			v.ExpiredTime = 0

			local CPanelSelectRole = require"GUI.CPanelSelectRole"
			if CPanelSelectRole.Instance():IsShow() then
				CPanelSelectRole.Instance():FreshReCoverRoleShow(i)
			end
			break 
		end
	end	
end

PBHelper.AddHandler("S2CRoleRecoverRes", OnS2CRoleRecoverRes)