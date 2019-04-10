
require "Data.ClientDef"

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelLoading = require "GUI.CPanelLoading"
local CPowerSavingMan = require "Main.CPowerSavingMan"
local QualitySettingMan = require "Main.QualitySettingMan"
local CTeamMan = require "Team.CTeamMan"
local CPath = require "Path.CPath"

local just_for_scene_test = false
local mem_hook_time = 0

_G.logc2s = false
_G._TotalSendProtoCount = 0
_G.logs2c = false
_G._TotalRecvProtoCount = 0
_G.canSendPing = false
_G.canAutoReconnect = true
_G.monsterMove = true
_G.monsterStopMove = true

_G.lastIsStop = false
_G.lastHostPosX, _G.lastHostPosZ = 0, 0
_G.lastDestPosX, _G.lastDestPosZ = 0, 0
_G.isplayingCG = false

function _G.IsAndroid()
	return Application.platform == EnumDef.RuntimePlatform.Android
end

function _G.IsIOS()
	return Application.platform == EnumDef.RuntimePlatform.IPhonePlayer
end

function _G.IsWin()
	local p = Application.platform
	return p == EnumDef.RuntimePlatform.WindowsEditor or p == EnumDef.RuntimePlatform.WindowsPlayer
end

function _G.GetDebugLineInfo(stack)

    local info = debug.getinfo(stack, "Sl") 
    if info == nil then return "" end
    return string.format("[ %s, %d ]", info.source or "", info.currentline)
	--[[
	local ret = ""
    for level = 2, 10 do
        -- 打印堆栈每一层
        local info = debug.getinfo( level, "nSl") 
        if info == nil then break end
        ret = ret .. string.format("[ file: %s, line: %d ]\n", info.source or "", info.currentline)
    end
    return ret
    ]]
end

function _G.StartGame()
	print("InitGame")
	game:Init()

	print("StartGame")
	game:Start()
end

function _G.ReleaseGame()
	game:Release()
	print("ReleaseGame")
end

function _G.PauseGame()
	print("PauseGame")
	game:SaveUserDataToFile()
end

function _G.MemoryHook(tickTime)
	mem_hook_time = tickTime
	local MemLeakDetector = require "Profiler.CMemLeakDetector"
	MemLeakDetector.StartRecordAlloc(false)
end

function _G.TickGame(dt)
	if mem_hook_time > 0 then
		mem_hook_time = mem_hook_time - 1
		if mem_hook_time == 0 then
			local MemLeakDetector = require "Profiler.CMemLeakDetector"
			MemLeakDetector.StopRecordAllocAndDumpStat()
		end
	end

	game:Tick(dt)

	if game._NetMan ~= nil and game._NetMan._GameSession ~= nil and _G.canSendPing then
		game._NetMan._GameSession:CheckConnection(10)	--检查是否10秒内收到了服务器响应
	end

end

function _G.LateTickGame(dt)

end

function _G.AddGlobalTimer(ttl, once, cb)
	return TimerUtil.AddGlobalTimer(ttl, once, cb, _G.GetDebugLineInfo(3))
end

function _G.RemoveGlobalTimer(id)
	TimerUtil.RemoveGlobalTimer(id)
end

function _G.GetHostActiveEventCount()
	if game._HostPlayer == nil or game._HostPlayer._SkillHdl == nil or game._HostPlayer._SkillHdl._ActiveEventList == nil then
		return 0 
	end
	local eventList = game._HostPlayer._SkillHdl._ActiveEventList
	local count = 0
	for _, v in pairs(eventList) do
		count = count + 1
	end
	return count
end

function _G.GetHandlerTotalCount()
	return CGame.EventManager:getHandlerTotalCount()
end

function _G.ProcessProtocol(id, buffer, isSpecial, isSimple)
	isSimple = isSimple or _G.isplayingCG

	game._NetMan:ProcessProtocol(id, buffer, isSpecial, isSimple)
end

function _G.ClearProtocol(id, buffer, isSpecial, isSimple)
	local net = require "PB.net"
	if id == net.S2C_PROTOC_TYPE.SPT_SERVER_MESSAGE or id == net.S2C_PROTOC_TYPE.SPT_LOGOUT_ACCOUNT then
		game._NetMan:ProcessProtocol(id, buffer, isSpecial, isSimple)
	end
end

function _G.__GetTableSize(table)
	local count = 0
	for _, v in pairs(table) do
		count = count + 1
	end
	return count
end

function _G.__PrintTable(table)
	local count = 0
	for k, v in pairs(table) do
		if v ~= nil then
			count = count + 1
			print(k, v)
		end
	end
	return count
end

-- CG停止移动
function _G.OnCGStopBehaviour()
	CGMan.StopBehaviour()
end

-- CG开始
function _G.OnCGStart(name, videoName)
	--warn("OnCGStart", name, videoName, CGMan.GetAudioNameByVideoName(videoName))

	CPath.Instance():PausePathDungeon()
	CSoundMan.Instance():Play2DAudio(CGMan.GetAudioNameByVideoName(videoName), 1)

	if not IsNilOrEmptyString(videoName) then
		_G.isplayingCG = true

		CSoundMan.Instance():SetSoundBGMVolume(0, true)
    	CSoundMan.Instance():SetSoundEffectVolume(0)
	end
end

-- CG结束调用
function _G.OnCGFinish(name, videoName)
	--warn("OnCGFinish", name, videoName, CGMan.GetAudioNameByVideoName(videoName))

	_G.isplayingCG = false

	CGMan.Finish(name)
	CPath.Instance():ReStartPathDungeon()
	CSoundMan.Instance():Stop2DAudio(CGMan.GetAudioNameByVideoName(videoName),"")

	if not IsNilOrEmptyString(videoName) then
		CSoundMan.Instance():SetSoundBGMVolume(1, true)
    	CSoundMan.Instance():SetSoundEffectVolume(1)
    end
end

function _G.GetGameDataSendFilter()
	return { }
end

function _G.OnClickGround(pos)
	if just_for_scene_test then 
		warn(pos)
		return 
	end
	game:OnClickGround(pos)
	game:RaiseNotifyClickEvent("Ground")

	--warn("random test",math.random(1,4))
end

function _G.BeginSleeping()
	game._CPowerSavingMan:BeginSleeping()
end

function _G.OnSingleDrag(delta)

end

function _G.OnTwoFingersDrag(delta)
	--delta > 10 || delta < -10

	if delta > 10 then
		game:SetTwoFingerDrag(false)
	elseif delta < -10 then
		game:SetTwoFingerDrag(true)
	end
end

function _G.OnSyncLog(log_str)
	game:OnUnityLog(log_str)
end

--function _G.NotifyClick(obj)
--	game:RaiseNotifyClickEvent(obj)
--end

function _G.OnTraceBack()
	warn(debug.traceback())
end

function _G.OnJoystickPressEvent(x, y)
	game:OnJoystickPressEvent(x, y)
end

function _G.OnInputKeyCode(keycode)

	local base = 48
    local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
    local CAutoFightMan = require "ObjHdl.CAutoFightMan"
    local hp = game._HostPlayer
	--键盘数字0-9

	if keycode == base + 0 then
		game:DebugString("showui 1")
	elseif keycode == base + 1 then
		CPanelSkillSlot.Instance():CastSkillByIndex(2)
	elseif keycode == base + 2 then
		CPanelSkillSlot.Instance():CastSkillByIndex(3)
	elseif keycode == base + 3 then
		CPanelSkillSlot.Instance():CastSkillByIndex(4)
	elseif keycode == base + 4 then
		CPanelSkillSlot.Instance():CastSkillByIndex(5)
	elseif keycode == base + 5 then
		CPanelSkillSlot.Instance():CastSkillByIndex(6)	
	elseif keycode == base + 6 then
		CPanelSkillSlot.Instance():OnToggle("Tog_AutoFight", not CPanelSkillSlot.Instance()._ToggleAutoFight.isOn)
	elseif keycode == base + 7 then
		CPanelSkillSlot.Instance()._ShortcutComp:OnClick()
	elseif keycode == base + 8 then
		CPanelSkillSlot.Instance()._HawkEyeComp:OnClick()
	elseif keycode == base + 9 then
		game:DebugString("showui 0")
	end

	--功能键
	if keycode == 32 then		--空格
		CPanelSkillSlot.Instance():CastSkillByIndex(1)
	elseif keycode == 308 then		--左alt
		CPanelSkillSlot.Instance():CastSkillByIndex(7)
	elseif keycode == 96 then    --`
		if not game._RegionLimit._LimitUseBlood then -- 地图限制禁止使用药瓶
	        local hp = game._HostPlayer
	    	local equip_drug_id = hp:GetEquipedPotion()
			local normalPack = hp._Package._NormalPack
			local drug = normalPack:GetItem(equip_drug_id)
			if drug ~= nil then
				drug:Use()
			end
    	end
	elseif keycode == 27 then    --Esc Android 后退

		if not game._GUIMan:HandleEscapeKey() then
			--warn("OnInputKeyCode..true")
			game:QuitGame()
		end
	end

	--game:DebugString(cmd)
end

function _G.OnDoubleInputKeyCode(keycode)
	--warn("OnDoubleInputKeyCode")
	if keycode == 27 then    --Esc Android 后退
		game:QuitGame()
	end
end

function _G.IsUseRealTimeShadowInLogin()
	return true
end

function _G.IsUseBloomHDInLogin()
	--local level = QualitySettingMan.Instance():GetRecommendLevel()
	--return level > 2
	return true
end

function _G.GetHandlerTotalCount()
	return CGame.EventManager:getHandlerTotalCount()
end

function _G.FlashTip(tip, category, duration)
	tip = tip or "FlashTip"

	game._GUIMan:ShowTipText(tip, false)
end

function _G.SceneTest()
	just_for_scene_test = true
	game:StartTestScene()
end

--语音 offline
function _G.Voice_OnApplyMessageKeyComplete(code)
	VoiceUtil.OffLine_StartRecording()   
    VoiceUtil.OffLine_StopRecording(nil)
end

function _G.Voice_OnUploadReccordFileComplete(code, filepath, fileId)
	-- warn("_G.Voice_OnUploadReccordFileComplete", filepath, fileId)
	if fileId ~= "" then
		local VoiveSeconds = VoiceUtil.OffLine_GetVoiceFileSeconds()
		-- warn("Upload game._IsSystemVoice == ", game._IsSystemVoice)
		if game._IsSystemVoice == true then			
			local CPanelChatNew = require 'GUI.CPanelChatNew'
			CPanelChatNew.Instance():OnSendVoiceMsg(fileId, VoiveSeconds)
		end
	end
end

function _G.Voice_OnDownloadRecordFileComplete(code, filepath, fileId)
	-- warn("_G.Voice_OnDownloadRecordFileComplete", filepath, fileId)
	if fileId ~= "" then
		-- warn("Download game._IsSystemPlayVoice == ", game._IsSystemPlayVoice)
		if game._IsSystemPlayVoice == true then			
			local ChatManager = require 'Chat.ChatManager'
			ChatManager.Instance():OnPlayVoice(fileId)
		elseif game._IsSystemPlayVoice == false then
			local CFriendMan = require 'Main.CFriendMan'
			game._CFriendMan:OnPlayVoice(fileId)
		end
		
	end
end

function  _G.Voice_OnPlayRecordFileComplete(code, filepath)
	--warn("_G.Voice_OnPlayRecordFileComplete", filepath)
	CSoundMan.Instance():SetSoundBGMVolume(1, true)
end

function _G.Voice_OnRecordingFileComplete(code)
	warn("_G.Voice_OnRecordingFileComplete")
end

function _G.Voice_OnSpeechToTextComplete(code, fileId, textResult)
	warn("_G.Voice_OnSpeechToTextComplete", textResult)
end

--小队，国战
function _G.Voice_OnJoinRoomComplete(code, roomName, memberID)
	warn("_G.Voice_OnJoinRoomComplete", roomName, memberID)
end

function _G.Voice_OnQuitRoomComplete(code, roomName, memberID)
	warn("_G.Voice_OnQuitRoomComplete", roomName, memberID)
end

function _G.OnPhotoCameraFileResult(filename)
	warn("_G.OnPhotoCameraFileResult", filename)

	if filename ~= nil and filename ~= "" then
		local CPanelSetHead = require 'GUI.CPanelSetHead'
		CPanelSetHead.Instance():SetIconPathFromFile(filename)
	end
end

--_G.GameProfiler = require "Utility.GameProfiler"

_G.EVENT =
{
    NONE = 0,

    CONNECTED = 1,
    DISCONNECTED = 2,
    ACCEPTED = 3,
    CLOSED = 4,
    CONNECT_FAILED = 5,
}

_G.MsgBoxDisconnectShow = false

function _G.OnConnectionEvent(eventCode)
	if eventCode == EVENT.CONNECTED then
		warn("网络连接成功")

		local callback = function()	
			if not game._IsReconnecting then
				game._GUIMan:CloseCircle()
				--MsgBox.CloseAll()
			end
		end
		_G.AddGlobalTimer(5, true, callback)

	elseif eventCode == EVENT.DISCONNECTED then
		warn("网络断开连接")

		game._NetMan:Close()			--主动断开连接

		--关闭所有MsgBox		
		game._GUIMan:CloseCircle()
		MsgBox.CloseAll()

		if game._AnotherDeviceLogined then
			
			-- 顶号重新登录
			local callback = function()
				game:ReturnLoginStage()
				_G.MsgBoxDisconnectShow = false
			end

			_G.MsgBoxDisconnectShow = true
			local title, msg, closeType = StringTable.GetMsg(79)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, callback, nil, nil, MsgBoxPriority.Disconnect)
			
			game:RaiseDisconnectEvent()
			ClearScreenFade()
		else
			if _G.canAutoReconnect then

				--当在登录界面时忽略网络断连消息
				local loginPanel = require "GUI.CPanelLogin".Instance()
				if IsNil(loginPanel._Panel) or not loginPanel:IsShow() then

					game:RaiseDisconnectEvent()
					ClearScreenFade()

					_G.AddGlobalTimer(5, true, function() 
						game:AutoReconnect() 
					end)
				end
			end
		end
	elseif eventCode == EVENT.CLOSED then
		warn("网络关闭")
		-- 平台SDK打点
		local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
		CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_User_Login_Fail)

		game._GUIMan:CloseCircle()
		MsgBox.CloseAll()

	elseif eventCode == EVENT.CONNECT_FAILED then
		warn("网络连接失败")
		if _G.ReconnectTimerId == 0 and not _G.MsgBoxDisconnectShow then 		--重连中忽略连接错误消息
			-- 平台SDK打点
			local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
			CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_User_Login_Fail)
			
			--延迟1s加载
			local callback = function()	
				game._GUIMan:CloseCircle()
				MsgBox.CloseAll()
			end

			do
				local message = ""
				local ServerMessageBase = require "PB.data".ServerMessageBase
				local CElementData = require "Data.CElementData"
				local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.ConnectedFailed)
				if template == nil then
					message = "连接失败"
				else
					message = template.TextContent
				end
				game._GUIMan:ShowCircle(message, false)
			end
			_G.AddGlobalTimer(1.5, true, callback)
		end
	end
end

function _G.LogMemory(tag)
	GameUtil.LogMemoryInfo(tag)
end

function _G.TODO(msg)
	if msg == nil or type(msg) ~= "string" then
		msg = StringTable.Get(16)
	end
	game._GUIMan:ShowTipText(msg, false)
end

function _G.GetAllTeamMember()
	local ids = {}
	local memberList = CTeamMan.Instance():GetMemberList()
	local objMap = game._CurWorld._PlayerMan._ObjMap
	for i,v in pairs(memberList) do
		if v._ID ~= game._HostPlayer._ID then
			table.insert(ids, objMap[v._ID])
		end
	end
	GameUtil.GetAllTeamMember(ids)
end

function _G.GetLuaMemory()
	collectgarbage("collect")
	return collectgarbage("count")
end

function _G.GetDesignWidthAndHeight()
	return 1920, 1080
end

function _G.ChangeCombatStateImmediately(go, isInCombat)
	if IsNil(go) then return end
	local ani = go:GetComponent(ClassType.AnimationUnit)
	if IsNil(ani) then return end
	if isInCombat then
		ani:PlayAnimation(EnumDef.CLIP.BATTLE_STAND, 0.1, false, 0, false, 1)
		GameUtil.ChangeAttach(go, EnumDef.HangPoint.HangPoint_WeaponBack1, EnumDef.HangPoint.HangPoint_WeaponLeft)
		GameUtil.ChangeAttach(go, EnumDef.HangPoint.HangPoint_WeaponBack2, EnumDef.HangPoint.HangPoint_WeaponRight)
	else
		ani:PlayAnimation(EnumDef.CLIP.COMMON_STAND, 0.1, false, 0, false, 1)
		GameUtil.ChangeAttach(go, EnumDef.HangPoint.HangPoint_WeaponLeft, EnumDef.HangPoint.HangPoint_WeaponBack1)
		GameUtil.ChangeAttach(go, EnumDef.HangPoint.HangPoint_WeaponRight, EnumDef.HangPoint.HangPoint_WeaponBack2)
	end
end

local c2s_ping_protocol = nil
local time_point = nil
function _G.SendProtocol_Ping(timestamp)
	if not _G.canSendPing then return end

	if c2s_ping_protocol == nil then
		local C2SPING = require "PB.net".C2SPING
		c2s_ping_protocol = C2SPING()
		local TimePoint = require "PB.net".TimePoint
		time_point = TimePoint()
		local PING_POINT = require "PB.net".PING_POINT
		time_point.PingPoint = PING_POINT.PING_POINT_CLIENT_CSHARP
	end
	time_point.Timestamp = timestamp 
	table.remove(c2s_ping_protocol.TimeList, 1)
	table.insert(c2s_ping_protocol.TimeList, time_point)
	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(c2s_ping_protocol)
end

local c2s_rolemove_protocol = nil 
function _G.SendProtocol_RoleMove(commandTick, entityId, interval, timestamp, mapId, stopflag, isDest, posX, posZ, oriX, oriZ, dirX, dirZ, destPosX, destPosZ)
	if mapId == 0 or game._NetMan._Paused then return end        --_Paused可能在切图loading中，这时不发送移动协议

	if c2s_rolemove_protocol == nil then
		local C2SRoleMove = require "PB.net".C2SRoleMove
		c2s_rolemove_protocol = C2SRoleMove()
	end

	c2s_rolemove_protocol.CommandTick = commandTick
	c2s_rolemove_protocol.EntityId = entityId
	c2s_rolemove_protocol.IntervalTime = interval
	c2s_rolemove_protocol.Timestamp = timestamp
	c2s_rolemove_protocol.MapId = mapId
	c2s_rolemove_protocol.StopFlag = stopflag
	c2s_rolemove_protocol.IsUseDestPosition = isDest

	c2s_rolemove_protocol.Position.x = posX
	c2s_rolemove_protocol.Position.y = 0
	c2s_rolemove_protocol.Position.z = posZ

	c2s_rolemove_protocol.Orientation.x = oriX
	c2s_rolemove_protocol.Orientation.y = 0
	c2s_rolemove_protocol.Orientation.z = oriZ

	c2s_rolemove_protocol.MoveDirection.x = dirX
	c2s_rolemove_protocol.MoveDirection.y = 0
	c2s_rolemove_protocol.MoveDirection.z = dirZ

	c2s_rolemove_protocol.DestPosition.x = destPosX
	c2s_rolemove_protocol.DestPosition.y = 0
	c2s_rolemove_protocol.DestPosition.z = destPosZ

	--warn("RoleMove mapId: ", mapId)

	_G.lastIsStop = stopflag
	_G.lastHostPosX, _G.lastHostPosZ = posX, posZ
	_G.lastDestPosX, _G.lastDestPosZ = destPosX, destPosZ


	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(c2s_rolemove_protocol)
	--warn("SendProtocol_RoleMove", Time.time, stopflag, posX, posZ, destPosX, destPosZ)
end

local c2s_skillmoveturn_protocol = nil 
function _G.SendProtocol_SkillMoveTurn(curPosX, curPosZ, curDirX, curDirZ, destPosX, destPosZ)
	if c2s_skillmoveturn_protocol == nil then
		local C2SSkillMoveTurn = require "PB.net".C2SSkillMoveTurn
		c2s_skillmoveturn_protocol = C2SSkillMoveTurn()
	end

	c2s_skillmoveturn_protocol.CurPosition.x = curPosX
	c2s_skillmoveturn_protocol.CurPosition.y = 0
	c2s_skillmoveturn_protocol.CurPosition.z = curPosZ

	c2s_skillmoveturn_protocol.CurOrientation.x = curDirX
	c2s_skillmoveturn_protocol.CurOrientation.y = 0
	c2s_skillmoveturn_protocol.CurOrientation.z = curDirZ

	c2s_skillmoveturn_protocol.DestPosition.x = destPosX
	c2s_skillmoveturn_protocol.DestPosition.y = 0
	c2s_skillmoveturn_protocol.DestPosition.z = destPosZ

	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(c2s_skillmoveturn_protocol)
end


-- MoveType == 0 碰上了
-- MoveType == 1 重新开始冲锋了
function _G.SendProtocol_EntityCollide(colliderId, movetype)
	local msg = CreateEmptyProtocol("C2SEntityCollide")
	local hp = game._HostPlayer
	msg.EntityId = hp._ID
	msg.ColliderId = colliderId
	local pos = hp:GetPos()
	msg.Position.x = pos.x
	msg.Position.z = pos.z			
	msg.MoveType = movetype
	SendProtocol2Server(msg)
	--warn("SendEntityCollidePrtc", colliderId, movetype, pos.x, pos.z)
end

function _G.StartScreenFade(from, to, duration, callback)
	if duration <= 0 then return end

	GameUtil.StartScreenFade(from, to, duration)
	if callback ~= nil then
		local function cb( ... )
			callback()
		end
		_G.AddGlobalTimer(duration, true, cb)
	end
end

function _G.ClearScreenFade()
	GameUtil.ClearScreenFadeEffect()
end

function _G.IsLoadingUI()
	local panel_loading = CPanelLoading.Instance()
	return panel_loading._IsLoading or panel_loading:IsShow() 
	--or C3V3LoadingPanel.Instance():IsShow()
end

-- 检查是否能进入近景相机
function _G.TryEnterNearCam()
	if game ~= nil and game._GUIMan ~= nil and game._HostPlayer ~= nil then
		local hp = game._HostPlayer
		if hp:IsDead() or hp:IsInServerCombatState() or hp:IsModelChanged() or hp:IsBodyPartChanged() or hp:IsOnRide() then return end

		local cur_fsm_state = hp:GetCurStateType()
		if cur_fsm_state == FSM_STATE_TYPE.MOVE then return end

		if hp:IsInCanNotInterruptSkill() then return end

		if hp:IsInCanInterruptSkill() then
			hp._SkillHdl:StopCurActiveSkill(true)
		end

		-- 停止NPC服务
		hp._OpHdl:EndNPCService(nil)
		-- 停止休闲状态
		hp:SetPauseIdleState(true)
		-- 停止寻路
		hp:StopAutoFollow()

		GameUtil.SetNearCamProfCfg(hp:IsOnRide())
		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.NEAR)
		game._GUIMan:Open("CPanelUINearCam", nil)
		game._IsInNearCam = true
	end
end

function _G.OpenOrCloseUIPanel(panelName, isOpen)
	if game == nil or game._GUIMan == nil then return end
	if isOpen then
		game._GUIMan:Open(panelName, nil)
	else
		game._GUIMan:Close(panelName)
	end
end

--function _G.OnTuneUIAspect(aspect_type)
--	if game == nil or game._GUIMan == nil then return end

--    --game._GUIMan:Open(panelName, nil)
--    --还没写完

--end

--判断是否可以忽略碰撞，和hostplayer的关系
function _G.CanSkipCollision(go)	
	return false
end

--UI Adapt二次修改安全区 
function _G.ConfirmSafeArea(x, y, z, w, dev_mod)
	warn("[UI] ConfirmSafeArea ("..x.." , "..y..", ".. z..", "..w..") on: "..dev_mod)
	if string.find(dev_mod, "HUAWEI") ~= nil then
		x=0
		y=0
		z=0
		w=0
	end

	return x, y, z, w
end


_G.CurrentWeather = 1

_G.WeatherType =
{
    WeatherType_Morning = 0,
    WeatherType_Day = 1,
    WeatherType_Dusk = 2,
    WeatherType_Night = 3,
    WeatherType_Rain = 4,
    WeatherType_Snow = 5
}

function _G.ChangeCurrentWeather(weatherType)
	-- body
	_G.CurrentWeather = weatherType
	--warn("weather  changed!!!!")
end

_G.ShadowTemplate = nil