--
-- S2CPKChangeMode
--
local PBHelper = require "Network.PBHelper"
local PK_RES_CODE = require "PB.net".PK_RES_CODE
local EPkMode = require "PB.data".EPkMode
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnPKChangeReturnCode(code)
	if code == PK_RES_CODE.PK_CODE_ROLE_LEVEL then
		game._GUIMan:ShowTipText(StringTable.Get(19401), false)
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
		warn("msg.ResCode == " ..code)
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

		local NotifyPropEvent = require "Events.NotifyPropEvent"
		local event = NotifyPropEvent()
		local game = game
		local hp = game._HostPlayer

		if msg.EntityId == hp._ID then
			local msgStr = string.format(StringTable.Get(19400),pkModeStr)
			game._GUIMan:ShowTipText(msgStr, true)
			hp._InfoData._PkMode = msg.PkMode
			local playerMap = game._CurWorld._PlayerMan._ObjMap
			for _, player in pairs(playerMap) do
				if player._TopPate ~= nil then
					player._TopPate:UpdateName(true)
					player:UpdateTopPateRescue()
				end
		    end
		    --hp._TopPate:SetPKIconIsShow( hp:GetPkMode() == EPkMode.EPkMode_Massacre )
		    hp:SendPropChangeEvent("PKIcon")
		else
			local entity = game._CurWorld:FindObject(msg.EntityId)
			if entity then
				entity:SetPKMode(msg.PkMode)
				entity:SendPropChangeEvent("PKIcon")
				-- if entity._TopPate then
				-- 	entity._TopPate:SetPKIconIsShow( entity:GetPkMode() == EPkMode.EPkMode_Massacre )
				-- end
			end
		end
		event.ObjID = msg.EntityId	
		event.Type = ""
		CGame.EventManager:raiseEvent(nil, event)

		-- 	刷新选中目标
		local curTarget = hp._CurTarget
		if msg.EntityId == hp._ID or (curTarget ~= nil and msg.EntityId == curTarget._ID) then
			hp:UpdateTargetSelected()
			--local is_locked = hp._IsTargetLocked
			--CFxMan.Instance():OnTargetSelected(curTarget, is_locked)
		end
	else
		OnPKChangeReturnCode(msg.ResCode)
		return
	end

end

PBHelper.AddHandler("S2CPkChangeMode", OnS2CPkChangeMode)

--返回 主角的罪恶值   ElsePlayer的IsRedName
local function OnS2CPkUpdateEvil(sender, protocol)
	local NotifyPropEvent = require "Events.NotifyPropEvent"
	local event = NotifyPropEvent()
	if protocol.EntityId ~= nil and protocol.EntityId == game._HostPlayer._ID then
		game._HostPlayer._InfoData._EvilNum = protocol.EvilNum
		game._HostPlayer._TopPate:UpdateName(true)
		event.ObjID = 0
	else
		local entity = game._CurWorld:FindObject(protocol.EntityId)
		entity:SetEvilNum(protocol.IsRedName)
		event.ObjID = protocol.EntityId
	end
	event.Type = ""
	CGame.EventManager:raiseEvent(nil, event)
end
PBHelper.AddHandler("S2CPkUpdateEvil", OnS2CPkUpdateEvil)