--
-- S2CDeleteRoleRe
--

local PBHelper = require "Network.PBHelper"

local function OnDeleteRoleRe(sender, protocol)
	--warn("OnDeleteRoleRe", protocol.RoleId)
	local role_list = game._AccountInfo._RoleList

	local index = 0
	for i, v in ipairs(role_list) do
		if v.Id == protocol.RoleId then
			index = i
			table.remove(role_list, index)
			if #role_list <= 0 then
				game._GUIMan:Close("CPanelSelectRole")
				game:EnterRoleCreateStage()
			else
				game._GUIMan:Open("CPanelSelectRole",1)
			end
			return
		end
	end
end

PBHelper.AddHandler("S2CDeleteRoleRe", OnDeleteRoleRe)