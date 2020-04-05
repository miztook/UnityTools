--
-- S2CCreateRoleRe
--

local PBHelper = require "Network.PBHelper"

local function OnCreateRoleRe(sender, msg)
	--warn("OnCreateRoleRe", msg.BriefRoleInfo.Id, msg.BriefRoleInfo.Name, #game._AccountInfo._RoleList)
	local role_list = game._AccountInfo._RoleList
	role_list[#role_list + 1] =  msg.BriefRoleInfo
	game._GUIMan:Close("CPanelCreateRole")
	local select_index = #role_list
	game:EnterRoleSelectStage(select_index)
end

PBHelper.AddHandler("S2CCreateRoleRe", OnCreateRoleRe)