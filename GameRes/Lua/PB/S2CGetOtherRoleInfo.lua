local PBHelper = require "Network.PBHelper"
local CPanelFriendFight = require "GUI.CPanelFriendFight"

--完成成就
local function S2CGetOtherRoleInfo(sender,msg)
	--warn("S2CGetOtherRoleInfo", msg.Result)

	if msg.Result ~= 0 then
		game._GUIMan:ShowTipText(StringTable.Get(30100), false)
		return
	end
	local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
	local curType = msg.InfoType
	local roleId = msg.RoleId


	if curType == EOtherRoleInfoType.RoleInfo_Detail then
		game._GUIMan:Open("CPanelOtherPlayerProperty", { RoleId = roleId, Info = msg.OtherRoleInfo})
	elseif curType == EOtherRoleInfoType.RoleInfo_Simple then
		local MenuComponents = require "GUI.MenuComponents"
		
        local hp = game._HostPlayer
        local myTeamId = hp._TeamId
        local targetTeamId = msg.SimpleRoleInfo.TeamId
        local targetguildID = msg.SimpleRoleInfo.guildID
        local orignType = msg.Mark

        local comps = {}

        if orignType == EnumDef.GetTargetInfoOriginType.Chat then
        	comps = {
                --根据不同逻辑insert到这个table里
                MenuComponents.SeePlayerInfoComponent.new(roleId),
                MenuComponents.ChatComponent.new(roleId),
                MenuComponents.AddFriendComponent.new(roleId),
                MenuComponents.AddBlackListComponent.new(roleId),
                MenuComponents.InviteMemberComponent.new(roleId, myTeamId, targetTeamId),
	            MenuComponents.ApplyInTeamComponent.new(roleId, myTeamId, targetTeamId),
            }
        elseif orignType == EnumDef.GetTargetInfoOriginType.Guild then
        	local member = game._GuildMan:GetGuildMemberInfo(roleId)
        	if member ~= nil then
        		local CGuildMember = require "Guild.CGuildMember"
        		comps = CGuildMember.GetMenuList(member, myTeamId, targetTeamId)
        	end
        elseif orignType == EnumDef.GetTargetInfoOriginType.Friend then
        	     --根据不同逻辑insert到这个table里
        	     comps = {
			                MenuComponents.ChatComponent.new(roleId),
			                MenuComponents.SeePlayerInfoComponent.new(roleId),
				            MenuComponents.AddFriendComponent.new(roleId),
				            MenuComponents.DeleteFriendComponent.new(roleId),
				            MenuComponents.AddBlackListComponent.new(roleId),
				            -- MenuComponents.RemoveBlackListComponent.new(roleId),
				            -- MenuComponents.RemoveRecentChatComponent.new(roleId),
				            MenuComponents.InviteMemberComponent.new(roleId,myTeamId, targetTeamId),
				            MenuComponents.ApplyInTeamComponent.new(roleId,myTeamId, targetTeamId),
			            }
		elseif orignType == EnumDef.GetTargetInfoOriginType.FriendApply then
			comps = {
		                MenuComponents.ChatComponent.new(roleId),
		                MenuComponents.SeePlayerInfoComponent.new(roleId),
			            MenuComponents.AddBlackListComponent.new(roleId),
			            MenuComponents.RemoveBlackListComponent.new(roleId),
			            -- MenuComponents.RemoveRecentChatComponent.new(roleId),
			            MenuComponents.InviteMemberComponent.new(roleId,myTeamId, targetTeamId),
			            MenuComponents.ApplyInTeamComponent.new(roleId,myTeamId, targetTeamId),
		            }
		 elseif orignType == EnumDef.GetTargetInfoOriginType.RecentList then
        	     --根据不同逻辑insert到这个table里
        	     comps = {
			                MenuComponents.SeePlayerInfoComponent.new(roleId),
				            MenuComponents.AddFriendComponent.new(roleId),
				            MenuComponents.DeleteFriendComponent.new(roleId),
				            MenuComponents.AddBlackListComponent.new(roleId),
				            MenuComponents.RemoveBlackListComponent.new(roleId),
				            MenuComponents.InviteMemberComponent.new(roleId,myTeamId, targetTeamId),
				            MenuComponents.ApplyInTeamComponent.new(roleId,myTeamId, targetTeamId),
				            MenuComponents.RemoveRecentChatComponent.new(roleId),
				           }
		elseif orignType == EnumDef.GetTargetInfoOriginType.DungeonEnd then
        	     --根据不同逻辑insert到这个table里
        	     comps = {
				            MenuComponents.ChatComponent.new(roleId),
				            MenuComponents.AddFriendComponent.new(roleId),
				            MenuComponents.DeleteFriendComponent.new(roleId),
				            MenuComponents.AddBlackListComponent.new(roleId),
				           }
        else
	        comps = 
	        {
	            MenuComponents.SeePlayerInfoComponent.new(roleId),
	            MenuComponents.ChatComponent.new(roleId),
	            MenuComponents.AddFriendComponent.new(roleId),
	            MenuComponents.InviteMemberComponent.new(roleId, myTeamId, targetTeamId),
	            MenuComponents.ApplyInTeamComponent.new(roleId, myTeamId, targetTeamId),
	        }
	    end

        MenuList.Show(comps,nil,nil)
    elseif curType == EOtherRoleInfoType.RoleInfo_Assist then
    	CPanelFriendFight.Instance():S2CGetOtherRoleInfo(msg)
	end
end
PBHelper.AddHandler("S2CGetOtherRoleInfo", S2CGetOtherRoleInfo)