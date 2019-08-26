--
-- CG管理器
--
-- Created: 2016年11月22日
-- Modified:  2019年04月20日 - 系统重构
--
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local NotifyCGEvent = require "Events.NotifyCGEvent"
local PBHelper = require "Network.PBHelper"

local _CurCgId = 0
local _CurCgPath = nil
local _CurCgPriority = 0
local _CurAudioPath = nil
local _EndCallback = nil

-- 发送CG事件
local function SendCGEvent(type, id)
	local event = NotifyCGEvent()
	event.Type = type
	event.Id = id
	CGame.EventManager:raiseEvent(nil, event)
end

local function _OnStart()
	if _CurCgId > 0 then
		SendCGEvent("start", _CurCgId)
	end

	if not IsNilOrEmptyString(_CurAudioPath) then
		--CSoundMan.Instance():SetSoundBGMVolume(0, true)
    	--CSoundMan.Instance():SetSoundEffectVolume(0)
		CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.CG, true)
		CSoundMan.Instance():Play2DAudio(_CurAudioPath, 1)
	end
end

local function _OnFinish()
	if _EndCallback ~= nil then
		_EndCallback()
	end

	if _CurCgId > 0 then
		SendCGEvent("end", _CurCgId)
		local protocol = (require "PB.net".C2SFinishCgEvent)()
		protocol.CgEventId = _CurCgId
		PBHelper.Send(protocol)
	end

	if not IsNilOrEmptyString(_CurAudioPath) then
		CSoundMan.Instance():Stop2DAudio(_CurAudioPath,"")
--		CSoundMan.Instance():SetSoundBGMVolume(1, true)
--    	CSoundMan.Instance():SetSoundEffectVolume(1)
		CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.CG, false)
	end

	_CurCgId = 0
	_CurCgPath = nil
	_CurCgPriority = 0
	_CurAudioPath = nil
	_EndCallback = nil

	_G.IsCGPlaying = false
end

-- 直接跳过CG影片的情况
local function CanPlayVideo()
	return game._CPowerSavingMan:IsSleeping()
end

local function IsVideo(path)
	if IsNilOrEmptyString(path) then return false end
	local lpath = string.lower(path)
	return string.find(lpath, ".mp4") ~= nil 
end

local function _PlayCG(path, cb, priority, canSkip)
	if CanPlayVideo() then return end  -- 直接跳过CG影片的情况

	local cgId = 0
	local audioPath = nil
	if path ~= nil and type(path) == "number" then
		local asset = CElementData.GetTemplate("Asset", path)
		if asset ~= nil then
			cgId = path
			audioPath = asset.AudioAssetPath
			path = asset.Path
		end
	end

	if path == nil or type(path) ~= "string" then
		return 
	end

	if _CurCgPath == path or _CurCgPriority > priority then
		return
	end

	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetPipelineBreakPoint(
		PlatformSDKDef.PipelinePointType.PlayCG,
		cgId)

	-- 其他cg正在播放，先停掉
	if _CurCgPath ~= nil then
		GameUtil.StopCG()
	end

	_CurCgId = cgId
	_CurAudioPath = audioPath

	_G.IsCGPlaying = true

	_CurCgPath = path
	_CurCgPriority = priority or 0
	canSkip = canSkip or false
	_EndCallback = cb

	-- 非常不好的特殊逻辑  -- comment by lijian
	-- 新手副本CG ID未2，服务器行为树控制播放，在播放时关闭Loading界面
	if cgId == BeginnerDungeonCgId then
		local function startCb()
			game._GUIMan:Close("CPanelLoading")
		end
		GameUtil.PlayCG(path, _CurCgPriority, startCb, canSkip)
	else
		GameUtil.PlayCG(path, _CurCgPriority, nil, canSkip)
	end
end

-- CG停止:手动停止当前播放所有CG
local function _StopCG()
	GameUtil.StopCG()
end

-- 断线重连清空缓存
local function _Reset()
	GameUtil.StopCG()
	_CurCgId = 0
	_CurCgPath = nil
	_CurCgPriority = 0
	_CurAudioPath = nil
	_EndCallback = nil
	_G.IsCGPlaying = false
end

_G.CGMan =
{
	PlayCG = _PlayCG,
	StopCG = _StopCG,
	OnStart = _OnStart,
	OnFinish = _OnFinish,

	Reset = _Reset,
}
