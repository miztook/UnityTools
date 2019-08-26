--
-- S2CPKChangeMode
--
local PBHelper = require "Network.PBHelper"
local PK_RES_CODE = require "PB.net".PK_RES_CODE
local EPkMode = require "PB.data".EPkMode
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ChatManager = require "Chat.ChatManager"

local function OnPKChangeReturnCode(code)
	if code == PK_RES_CODE.PK_CODE_ROLE_LEVEL then
		game._GUIMan:ShowTipText(StringTable.Get(19301), false)
	elseif code == PK_RES_CODE.PK_CODE_CONFLIC then
		game._GUIMan:ShowTipText(StringTable.Get(19402), false)
    elseif code == PK_RES_CODE.PK_CODE_FIGHTING then
		game._GUIMan:ShowTipText(StringTable.Get(19403), false)
    elseif code == PK_RES_CODE.PK_CODE_SAMEMODE then
		game._GUIMan:ShowTipText(StringTable.Get(19407), false)
	elseif code == PK_RES_CODE.PK_CODE_CD then
		game._GUIMan:ShowTipText(StringTable.Get(19409), false)
	elseif code == PK_RES_CODE.PK_CODE_REGION then
		game._GUIMan:ShowTipText(StringTable.Get(19410), false)
	elseif code == PK_RES_CODE.PK_CODE_SCENE then
		game._GUIMan:ShowTipText(StringTable.Get(19411), false)
	elseif code == PK_RES_CODE.PK_CODE_TEAMGUILDLIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(19412), false)
	else
		warn("S2CPKChangeMode msg.ResCode == " ..code)
	end
end


local function OnS2CPkChangeMode(sender, msg)
    if msg.ResCode == PK_RES_CODE.PK_CODE_OK then
        local pkModeStr
        if msg.PkMode == EPkMode.EPkMode_Peace then
            pkModeStr = StringTable.Get(19404)
        elseif msg.PkMode == EPkMode.EPkMode_Guild then
            pkModeStr = StringTable.Get(19405)
        elseif msg.PkMode == EPkMode.EPkMode_Massacre then
            pkModeStr = StringTable.Get(19406)
        end        

		local hp = game._HostPlayer
		if msg.EntityId == hp._ID then
			local msgStr = string.format(StringTable.Get(19400),pkModeStr)
			game._GUIMan:ShowTipText(msgStr, true)
			hp._InfoData._PkMode = msg.PkMode
			local playerMap = game._CurWorld._PlayerMan._ObjMap
			for _, player in pairs(playerMap) do
				if player._TopPate ~= nil then
					player._TopPate:UpdateName(true)
					player:UpdatePetName()
					player:UpdateTopPate(EnumDef.PateChangeType.Rescue)
				end
		    end
		    --hp._TopPate:SetPKIconIsShow( hp:GetPkMode() == EPkMode.EPkMode_Massacre )
			hp:UpdateTopPate(EnumDef.PateChangeType.PKIcon)
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msgStr, false, 0, nil,nil)
		else
			local entity = game._CurWorld._PlayerMan._ObjMap[msg.EntityId]
			if entity then
				entity:SetPKMode(msg.PkMode)
				entity:UpdateTopPate(EnumDef.PateChangeType.PKIcon)
				-- if entity._TopPate then
				-- 	entity._TopPate:SetPKIconIsShow( entity:GetPkMode() == EPkMode.EPkMode_Massacre )
				-- end
			end
		end

		local EntityPKModeChangeEvent = require "Events.EntityPKModeChangeEvent"
		local event = EntityPKModeChangeEvent()
		event._EntityId = msg.EntityId
		CGame.EventManager:raiseEvent(nil, event)

		-- 	刷新选中目标
		hp:UpdateTargetSelected(msg.EntityId)
	else
		OnPKChangeReturnCode(msg.ResCode)
		return
	end

end

PBHelper.AddHandler("S2CPkChangeMode", OnS2CPkChangeMode)

--返回 主角的罪恶值   ElsePlayer的IsRedName
local function OnS2CPkUpdateEvil(sender, protocol)
	local hp = game._HostPlayer
	if protocol.EntityId ~= nil and protocol.EntityId == hp._ID then
		local nDelta = protocol.EvilNum - hp._InfoData._EvilNum
		if nDelta > 0 then -- 罪恶值增加了
			local msgStr = string.format(StringTable.Get(13038),nDelta)
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msgStr, false, 0, nil,nil)
		end
		hp._InfoData._EvilNum = protocol.EvilNum
		hp._TopPate:UpdateName(true)
		hp:UpdatePetName()

		-- 暂时只需要广播主角的
		local EntityEvilNumChangeEvent = require "Events.EntityEvilNumChangeEvent"
		local event = EntityEvilNumChangeEvent()
		-- event._EntityId = protocol.EntityId
		CGame.EventManager:raiseEvent(nil, event)
	else
		local player = game._CurWorld._PlayerMan._ObjMap[protocol.EntityId]
		if player ~= nil then
			player:SetEvilNum(protocol.IsRedName)
			player._InfoData._EvilNum = protocol.EvilNum
		end
	end
end
PBHelper.AddHandler("S2CPkUpdateEvil", OnS2CPkUpdateEvil)


-- 队伍内有成员改变PK模式
local function OnS2CPkTeamChangeMode(sender, msg)
	local CTeamMan = require "Team.CTeamMan"
	local entityName = CTeamMan.Instance():GetTeamMemberName(msg.EntityId)
	local PKModeStr = ""
	if msg.PkMode == EPkMode.EPkMode_Peace then
		PKModeStr = StringTable.Get(19404)
	elseif msg.PkMode == EPkMode.EPkMode_Guild then
		PKModeStr = StringTable.Get(19405)
	elseif msg.PkMode == EPkMode.EPkMode_Massacre then
		PKModeStr = StringTable.Get(19406)
	end

	local ChatContent = string.format(StringTable.Get(19414),entityName ,PKModeStr)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, ChatContent, false, 0, nil,nil)
end
PBHelper.AddHandler("S2CPkTeamChangeMode", OnS2CPkTeamChangeMode)