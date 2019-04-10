--
-- S2CRoleLevelUp
--
local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnRoleLevelUp(sender, msg)
	local entity = game._CurWorld:FindObject(msg.EntityId)
	if entity == nil then 
		--warn("can not find entity with id " .. msg.EntityId .. " when S2CRoleLevelUp")
		return 
	end

	entity:OnLevelUp(msg.CurrentLevel, msg.CurrentExp, msg.CurrentParagonLevel, msg.CurrentParagonExp)
 
	if entity:IsHostPlayer() then
		-- 系统聊天频道 -->>> 角色等级提升 主角提示 
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		local ChatManager = require "Chat.ChatManager"
		local Stringmsg = string.format(StringTable.Get(13026), msg.CurrentLevel)
		ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, Stringmsg, false, 0, nil,nil)
		-- 上传角色信息到平台
		game._HostPlayer:UpdateLevelMTime(LuaUInt64.ToDouble(msg.LastLevelMTime))
		CPlatformSDKMan.Instance():UploadRoleInfo(EnumDef.UploadRoleInfoType.RoleInfoChange)
	end
end

PBHelper.AddHandler("S2CRoleLevelUp", OnRoleLevelUp)

--提升等级的功能解锁提示
local function OnS2CGuideCheckFunctionUnlock(sender, msg)
	local PlayerGuidLevelUp = require "Events.PlayerGuidLevelUp"
	local event = PlayerGuidLevelUp()
	CGame.EventManager:raiseEvent(nil, event)
end

PBHelper.AddHandler("S2CGuideCheckFunctionUnlock", OnS2CGuideCheckFunctionUnlock)