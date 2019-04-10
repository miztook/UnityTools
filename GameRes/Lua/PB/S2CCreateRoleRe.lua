--
-- S2CCreateRoleRe
--

local PBHelper = require "Network.PBHelper"

local function OnCreateRoleRe(sender, msg)
	--warn("OnCreateRoleRe", msg.BriefRoleInfo.Id, msg.BriefRoleInfo.Name, #game._AccountInfo._RoleList)
	local role_list = game._AccountInfo._RoleList
	role_list[#role_list + 1] =  msg.BriefRoleInfo	

	local select_index = #role_list
	game._AccountInfo._CurrentSelectRoleIndex = select_index

	CPlatformSDKMan.Instance():UploadRoleInfoWhenCreate(msg.BriefRoleInfo.Id, msg.BriefRoleInfo.Name, msg.BriefRoleInfo.Level, msg.ZoneId, msg.BriefRoleInfo.GuildName, LuaUInt64.ToDouble(msg.RoleCreateTime))

	game:SendSelectRole(msg.BriefRoleInfo.Id)
	game._GUIMan:Close("CPanelCreateRole")
end

PBHelper.AddHandler("S2CCreateRoleRe", OnCreateRoleRe)