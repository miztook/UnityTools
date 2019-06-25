--
-- S2CDeleteRoleRe
--

local PBHelper = require "Network.PBHelper"
local ROLE_VAILD = require "PB.data".ERoleVaild

local function OnDeleteRoleRe(sender, protocol)
	-- warn("OnDeleteRoleRe", protocol.RoleId, protocol.RoleVaild, game._NetMan._UserName)
	local role_list = game._AccountInfo._RoleList

	for i = #role_list, 1, -1 do
		local v = role_list[i]
		if v.Id == protocol.RoleId then
			v.RoleVaild = protocol.RoleVaild
			v.ExpiredTime = protocol.ExpiredTime

			local UserData = require "Data.UserData".Instance()
			local account_name = game._NetMan._UserName
			local roleInfoList = UserData:GetCfg(EnumDef.LocalFields.QuickEnterGameRoleInfo, account_name)
			if roleInfoList ~= nil then
				-- 删除快速进入的角色信息
				for i= #roleInfoList, 1, -1 do
					local roleInfo = roleInfoList[i]
					if roleInfo.RoleId == protocol.RoleId then
						table.remove(roleInfoList, i)
						break
					end
				end
			end
			--角色被删除了
			if protocol.RoleVaild == ROLE_VAILD.Invaild then
				table.remove(role_list, i)

				-- 删除最近登录的对应角色信息
				local roleList = UserData:GetCfg(EnumDef.LocalFields.RecentLoginRoleInfo, account_name)
				if roleList ~= nil then
					for i= #roleList, 1, -1 do
						local roleInfo = roleList[i]
						if roleInfo.roleId == protocol.RoleId then
							table.remove(roleList, i)
							break
						end
					end
				end
			end

			if #role_list <= 0 then
				game._RoleSceneMan:EnterRoleCreateStage()
			else
				-- game._GUIMan:Close("CPanelLoading")
				-- game._GUIMan:Close("CPanelLogin")
				-- game._GUIMan:Close("CPanelCreateRole")

				-- game._GUIMan:CloseCircle()

				local CPanelSelectRole = require"GUI.CPanelSelectRole"
				if CPanelSelectRole and CPanelSelectRole.Instance():IsShow() then
					CPanelSelectRole.Instance():RoleDeleteFromServer(i, protocol.RoleVaild)
				end
			end
			break
		end
	end
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