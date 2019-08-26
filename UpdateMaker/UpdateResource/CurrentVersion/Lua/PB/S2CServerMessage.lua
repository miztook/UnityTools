--
-- S2CServerMessage
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local ServerMessageBase = require "PB.data".ServerMessageBase

local ServerMessageQuest = require "PB.data".ServerMessageQuest

local ESystemNotifyDisplayType = require "PB.Template".SystemNotify.SystemNotifyDisplayType
local ESyncChannel = require "PB.Template".SystemNotify.ESyncChannel

local function OnServerMessage(sender, protocol)
	game._GUIMan:ShowErrorCodeMsg(protocol.MessageId, protocol.Params)
	
	--服务器登录异常初始化处理
	--[[
		ServerMessageBase.AuthFailed = 11
		ServerMessageBase.MultiLogin = 12
		ServerMessageBase.ServerOverload = 13
		ServerMessageBase.GameServerNotExist = 14
		ServerMessageBase.AccountLengthInvalid = 15
        ServerMessageBase.RoleNameLengthInvalid = 16
	]]

	--出现异常 停止自动化
	if protocol.MessageId == ServerMessageQuest.QuestPredecessorQuestNotFinished then
	  	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	   	CQuestAutoMan.Instance():Stop()
	   	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	   	CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
	elseif protocol.MessageId == ServerMessageBase.OnAnotherDeviceLogin then
		game._AnotherDeviceLogined = true
	elseif protocol.MessageId == ServerMessageBase.NameInvalid or
		   protocol.MessageId == ServerMessageBase.RoleNameLengthInvalid or
		   protocol.MessageId == ServerMessageBase.ProfessionInvalid or
		   protocol.MessageId == ServerMessageBase.GenderInvalid or
		   protocol.MessageId == ServerMessageBase.FaceInvalid then
		-- 创建角色失败，平台SDK打点
		local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
		CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Create_Role_Fail)
	elseif protocol.MessageId == ServerMessageBase.RoleGetFaild or
		   protocol.MessageId == ServerMessageBase.RoleInvalid or
		   protocol.MessageId == ServerMessageBase.RoleIsExsisted or
		   protocol.MessageId == ServerMessageBase.GameServerNotExist then
		-- 进入游戏失败，平台SDK打点
		local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
		CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Role_Login_Fail)
   	end

	local errorWhenBeforeEnterMap = (protocol.MessageId > ServerMessageBase.SystemErrorStart  and protocol.MessageId < ServerMessageBase.SystemErrorEnd) or (game._HostPlayer == nil and protocol.MessageId == ServerMessageBase.Failed)
	if errorWhenBeforeEnterMap then
		--断连的话走断线重连逻辑，客户端不需要处理
		ClearScreenFade()
	end
	--登录困难触发转圈界面关闭
	game._GUIMan:CloseCircle()
end

PBHelper.AddHandler("S2CServerMessage", OnServerMessage)

local function OnS2CSendScrollMessage(sender, protocol)
	game._GUIMan:OpenSpecialTopTips(protocol.Content)
end

PBHelper.AddHandler("S2CSendScrollMessage", OnS2CSendScrollMessage)

local function OnS2CSystemAnnounce(sender, protocol)
	local EAnnounceType = require "PB.data".EAnnounceType
	if protocol.AnnounceType == EAnnounceType.AnnounceType_GuildMachining then
		local msg = string.format(StringTable.Get(22810), protocol.OperatorName, RichTextTools.GetItemNameRichText(protocol.Param1, 1, false))
		game._GUIMan:OpenSpecialTopTips(msg)
	elseif protocol.AnnounceType == EAnnounceType.AnnounceType_EquipInforce then
		local msg = string.format(StringTable.Get(22811), protocol.OperatorName, RichTextTools.GetItemNameRichText(protocol.Param1, 1, false), protocol.Param2)
		game._GUIMan:OpenSpecialTopTips(msg)
	elseif protocol.AnnounceType == EAnnounceType.AnnounceType_FinishDungeon then
		local msg = string.format(StringTable.Get(22812), protocol.OperatorName, CElementData.GetTemplate("Instance", protocol.Param1).TextDisplayName)
		game._GUIMan:OpenSpecialTopTips(msg)
	end
end

PBHelper.AddHandler("S2CSystemAnnounce", OnS2CSystemAnnounce)