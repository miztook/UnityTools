--
-- S2CChallenge
-- 
local PBHelper = require "Network.PBHelper"

local function OnChallenge(sender,msg)
	local nonce = msg.Nonce
	local account = game._NetMan._UserName
    local md5 = game._NetMan._AccountSaltPasswordMd5

    if GameUtil.GetRuntimePlatform() ~= EnumDef.RuntimePlatform.WindowsEditor then
    	local protoVersion = require "PB.Template".TemplateVersion().CurrentTemplateVersion
    	if protoVersion ~= msg.DataVersion then
    		MsgBox.ShowMsgBox(string.format(StringTable.Get(11), protoVersion, msg.DataVersion), StringTable.Get(8), MsgBoxType.MBBT_OK)
    	end
    end

    --假设Key不为空，则发送重连协议
    if string.len(game._KeyNonce) == 0 then
		local C2SResponse = require "PB.net".C2SResponse
		local msg = C2SResponse()
		msg.Account = account
	    msg.HmacMd5 = GameUtil.HMACMD5ComputeHash(md5, nonce)
	    msg.DeviceUniqueId = ""
	    PBHelper.Send(msg)
	else
		local protocol = (require "PB.net".C2SReconnect)()
		protocol.key = game._KeyNonce
		if #game._AccountInfo._RoleList > 0 then
			local roleIndex  = game._AccountInfo._CurrentSelectRoleIndex
			local roleId = 0
			if roleIndex ~= 0 then
				roleId = game._AccountInfo._RoleList[roleIndex].Id
			end
			protocol.roleId = roleId
		end
		protocol.accountName = account
		PBHelper.Send(protocol)
	end
end

PBHelper.AddHandler("S2CChallenge", OnChallenge)

local function OnS2CReconnectResult(sender, msg)
	if msg.result then
		game._GUIMan:Close("CPanelCircle")
		MsgBox.CloseAll()		
	else
		game:ReturnLoginStage()
	end

	--重连打断自动寻路
	if(game._HostPlayer ~= nil and game._HostPlayer._IsAutoPathing) then
    	game._HostPlayer: SetAutoPathing(false)
    	game._HostPlayer: SetTransPortalState(false)
    end
    --清除entity, 停止自动战斗
    if(game._CurWorld ~= nil) then
    	local CAutoFight = require "ObjHdl.CAutoFight"
		CAutoFight.Instance():Stop()

    	game._CurWorld:Release(false, false)
    end
end
PBHelper.AddHandler("S2CReconnectResult", OnS2CReconnectResult)
