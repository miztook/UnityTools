--
-- S2CChallenge
-- 
local PBHelper = require "Network.PBHelper"

local function OnChallenge(sender,msg)
	local account = game._NetMan._UserName
    local md5 = game._NetMan._AccountSaltPasswordMd5

    local accesstoken = CPlatformSDKMan.Instance():GetAccessToken()
    local channelType = CPlatformSDKMan.Instance():GetChannelType()
    local param1 = CPlatformSDKMan.Instance():GetC2SResponseParam1()

    local EDeviceType = require "PB.data".EDeviceType
    local deviceType = EDeviceType.EDeviceType_default
    
    --补充检查
    --[[
    if IsNilOrEmptyString(emulatorStr) then
    	if GameUtil.ExistDirOnSDCard("/Android/data/com.bluestacks.home") or GameUtil.ExistDirOnSDCard("/Android/data/com.bluestacks.settings") then
    		emulatorStr = "BlueStacks";
    	end
    end
    ]]

    if _G.IsAndroid() then
	    deviceType = EDeviceType.EDeviceType_AOS
	    local emulatorStr = GameUtil.GetEmulatorName()
    	--print("获得模拟器名称 ： ", emulatorStr)
	    if emulatorStr == "GoogleSdk" then
            deviceType = EDeviceType.EDeviceType_GoogleSdk
        elseif emulatorStr == "GenyMotion" then
            deviceType = EDeviceType.EDeviceType_GenyMotion
        elseif emulatorStr == "GoldFish" then
            deviceType = EDeviceType.EDeviceType_GoldFish
        elseif emulatorStr == "Vbox" then
            deviceType = EDeviceType.EDeviceType_Vbox
        elseif emulatorStr == "Nox" then
            deviceType = EDeviceType.EDeviceType_Nox
        elseif emulatorStr == "Andy" then
            deviceType = EDeviceType.EDeviceType_Andy
        elseif emulatorStr == "QEMU" then
            deviceType = EDeviceType.EDeviceType_QEMU
        elseif emulatorStr == "BlueStacks" then
            deviceType = EDeviceType.EDeviceType_BlueStacks
        elseif emulatorStr == "AndroidEmulator" then
            deviceType = EDeviceType.EDeviceType_AndroidEmulator
        end
    elseif _G.IsIOS() then
	    deviceType = EDeviceType.EDeviceType_IOS
	elseif _G.IsWin() then
		deviceType = EDeviceType.EDeviceType_WIN
    end

	local accounttoken = ""
	local UserData = require "Data.UserData"
	local lastAccount = UserData.Instance():GetCfg(EnumDef.LocalFields.LastUseAccount, "Account")
	if lastAccount ~= nil and lastAccount == account then
		-- 这次登录账号与本地记录的最新登录账号一致
		local token = UserData.Instance():GetCfg(EnumDef.LocalFields.LastUseAccount, "AccountToken")
		if token ~= nil then
			accounttoken = token
		end

		warn("use lastAccount token:", token)
	end

	do -- send protocol
		warn("account:", account)

		local C2SResponse = require "PB.net".C2SResponse
		local msg = C2SResponse()
		msg.Account = account
	    msg.HmacMd5 = GameUtil.HMACMD5ComputeHash(md5, accounttoken)
	    msg.DeviceUniqueId = GameUtil.GetOpenUDID()
	    msg.Channel = channelType
	    msg.AccessToken = accesstoken
	    msg.AccountToken = accounttoken
	    msg.DeviceType = deviceType
	    if not IsNilOrEmptyString(param1) then
	    	msg.Param1 = param1
	    end

	    msg.Device = _G.ResponseDevice
	    msg.OS = _G.ResponseOSVersion
	    msg.MAC = _G.ResponseMACString

	    PBHelper.Send(msg)
	end
end

PBHelper.AddHandler("S2CChallenge", OnChallenge)

local function OnS2CReconnectResult(sender, msg)
	game:OnReconnectResult()
	if msg.result then
		game._GUIMan:CloseCircle()
		MsgBox.ClearAllBoxes()	
	else
		game:LogoutAccount()
	end
end
PBHelper.AddHandler("S2CReconnectResult", OnS2CReconnectResult)

-- SDK服务器验证（暂定是验证成功不发这条消息）
local function OnS2CLoginVerifyRes(sender, msg)
	warn("LoginVerifyRes ResCode:", msg.ResCode, " ResType:", msg.ResType)
	local ESdkVerifyResType = require "PB.net".S2CLoginVerifyRes.ESdkVerifyResType
	if msg.ResType == ESdkVerifyResType.ESdkVerifyResType_Success then
		-- 验证成功，不作处理
		return
	end

	-- 验证失败，直接登出
	local title = StringTable.Get(32100)
	local content = ""
	if msg.ResType == ESdkVerifyResType.ESdkVerifyResType_BadRequest then
		content = StringTable.Get(32101)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_Unauthenticated then
		content = StringTable.Get(32102)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_NotAcceptable then
		content = StringTable.Get(32103)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_TimedOut then
		content = StringTable.Get(32104)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_InvalidMessageBox then
		content = StringTable.Get(32105)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_InternalServerError then
		content = StringTable.Get(32106)
	elseif msg.ResType == ESdkVerifyResType.ESdkVerifyResType_ServiceUnavailable then
		content = StringTable.Get(32107)
	else
		content = "Unknown Error: " .. msg.ResCode
	end
	MsgBox.ShowMsgBox(content, title, 0, MsgBoxType.MBBT_OK, function()
		CPlatformSDKMan.Instance():LogoutDirectly()
	end)
end
PBHelper.AddHandler("S2CLoginVerifyRes", OnS2CLoginVerifyRes)
