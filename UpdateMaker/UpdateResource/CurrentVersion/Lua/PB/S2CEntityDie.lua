local PBHelper = require "Network.PBHelper"

-- 击杀消息需要发送系统和战斗频道提示  killer 击杀者   entity 被杀
local function SendMsgToSysteamChannel(KillerID, EntityID)
    local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
	local CElementData = require "Data.CElementData"
	local EPkMode = require "PB.data".EPkMode

	local object = game._CurWorld:FindObject(EntityID) 
	local killerobject = game._CurWorld:FindObject(KillerID) 
	local EvilNum = tonumber(CElementData.GetSpecialIdTemplate(173).Value)
	if object ~= nil and killerobject ~= nil then
		local msg = nil
		if object._ID == game._HostPlayer._ID then
			if killerobject:IsRole() and killerobject:GetPkMode() == EPkMode.EPkMode_Massacre then
				msg = string.format(StringTable.Get(13044), killerobject._InfoData._Name, GUITools.FormatNumber(EvilNum))
			-- else
			-- 	msg = string.format(StringTable.Get(13046), killerobject._InfoData._Name)
			end

		elseif killerobject._ID == game._HostPlayer._ID then
			if object:IsRole() and killerobject:GetPkMode() == EPkMode.EPkMode_Massacre then
				msg = string.format(StringTable.Get(13033), object._InfoData._Name, GUITools.FormatNumber(EvilNum))
			-- else
			-- 	msg = string.format(StringTable.Get(13043), object._InfoData._Name)
			end
		end

		if msg ~= nil then
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelCombat, msg, false, 0, nil,nil)
		end
	end
end

local function OnEntityDie(sender, protocol)
	local object = game._CurWorld:FindObject(protocol.EntityId) 
	if object ~= nil then
		object:OnDie(protocol.Killer, protocol.ElementType, protocol.HitType, protocol.IsPlayAnimation)

		local objType = object:GetObjectType()
    	local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
    	if objType == OBJ_TYPE.ELSEPLAYER then
    		object:UpdateTopPate(EnumDef.PateChangeType.Rescue)
		end

		-- 发送消息提示
		SendMsgToSysteamChannel(protocol.Killer, protocol.EntityId)
	end
end

PBHelper.AddHandler("S2CEntityDie",OnEntityDie)