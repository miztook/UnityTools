--
-- CG管理器
--
-- 2016年11月22日
--
local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local NotifyCGEvent = require "Events.NotifyCGEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"

local PBHelper = require "Network.PBHelper"
-- 当前播放CG的Id列表
local cgId = {}
-- 播放结束调的Lua函数
local callback = {}
-- mp4对应的id列表
local cgVideoToAudio = {}
-- 默认视频播放CG
local _CommonVideoPath = "Assets/Outputs/CG/City01/CG_CommonVideo.prefab"

-- 发送CG结束事件
local function SendCGEvent(type, id)
	local event = NotifyCGEvent()
	event.Type = type
	if id == nil then
		warn("The id is nil:", debug.traceback())
		id = 0
	end
	event.Id = id
	CGame.EventManager:raiseEvent(nil, event)
end
-- 获取CG名字
local function GetCGName(path)
	local pathReverse = string.reverse(path)
	local start1, stop1 = string.find(pathReverse, "/")
	local start2, stop2 = string.find(path, "%.")
	local len = string.len(path)
	return string.sub(path, len - start1 + 2, start2 - 1)
end

-- 直接跳过CG影片的情况
local function CanPlayVideo()
	return game._CPowerSavingMan:IsSleeping()
end

local function _Finish(name)
	if callback[name] then
		callback[name]()
	end
	if game:IsInGame() then
		CAutoFightMan.Instance():Restart(_G.PauseMask.CGPlaying)
		CDungeonAutoMan.Instance():Restart(_G.PauseMask.CGPlaying)
		CQuestAutoMan.Instance():Restart(_G.PauseMask.CGPlaying)	
	end

	if cgId[name] then
		SendCGEvent("end", cgId[name])
		local protocol = (require "PB.net".C2SFinishCgEvent)()
		protocol.CgEventId = cgId[name]
		PBHelper.Send(protocol)
		callback[name] = nil
		cgId[name] = nil
	end
end

local function _PlayByNameEx(path, cb, priority, can_skip)
	local isVideo = (string.find(path, ".mp4") ~= nil)
	local name = ""
	if isVideo then
		name = path
	else
		name = GetCGName(path)
	end
	cgId[name] = 0
	callback[name] = cb
	if priority == nil then
		priority = 0
	end

	--warn("_PlayByName CG "..name)
	if isVideo then
		if CanPlayVideo() then
			SendCGEvent("start", 0)
			_Finish(name)
		else
			GameUtil.PlayCG(_CommonVideoPath, priority, path)
			SendCGEvent("start", 0)
		end
	else
		--warn("priority "..tostring(priority))

		GameUtil.PlayCG(path, priority, can_skip)
		SendCGEvent("start", 0)
	end

end

-- CG播放
-- path:目前暂且是cg全路径Assets..
-- cb：回调函数,默认为nil
local function _PlayByName(path, cb, priority)
	_PlayByNameEx(path, cb, priority, false)
end

local function _StopBehaviour()
	if not game:IsInGame() then return end
	
	local hp = game._HostPlayer
	if hp ~= nil then
		hp:StopNaviCal()
		CQuestAutoMan.Instance():Pause(_G.PauseMask.CGPlaying)  -- 自动任务完全停止
		CAutoFightMan.Instance():Pause(_G.PauseMask.CGPlaying)
		CDungeonAutoMan.Instance():Pause(_G.PauseMask.CGPlaying)
	end
end

local function _PlayById(id, cb, priority)
	if id == nil or id == 0 or type(id) ~= "number" then
		warn("id == nil or type is not number", debug.traceback())
		return
	end
	local asset = CElementData.GetTemplate("Asset", id)
	if asset == nil then
		warn("asset == nil", debug.traceback())
		return
	end
	local path = asset.Path
	if path == nil then
		warn("error id path is nil")
		return
	end
	local isVideo = (string.find(path, ".mp4") ~= nil)
	local name = ""
	if isVideo then
		name = "CG_CommonVideo"
		cgVideoToAudio[path] = asset.AudioAssetPath
	else
		name = GetCGName(path)
	end
	cgId[name] = id
	callback[name] = cb

	if priority == nil then priority = 0 end
	-- 非常不好的特殊逻辑  -- comment by lijian
	-- 新手副本CG ID未4，服务器行为树控制播放，在播放时关闭Loading界面
	print("_PlayById CG", id)
	if id == BeginnerDungeonCgId then
		if not isVideo then warn("ERROR BeginnerDungeon Cg type") end
		local function cb( ... )
			game._GUIMan:Close("CPanelLoading")
		end
		GameUtil.PlayCG(_CommonVideoPath, priority, path, cb)
	else

		--warn("_PlayById CG "..name)
		if isVideo then
			if CanPlayVideo() then
				SendCGEvent("start", cgId[name])
				_Finish(name)
			else
				GameUtil.PlayCG(_CommonVideoPath, priority, path)
				SendCGEvent("start", cgId[name])
			end
		else
			GameUtil.PlayCG(path, priority)
			SendCGEvent("start", cgId[name])	
		end

	end

end

local function _GetAudioNameByVideoName(videoName)
	if videoName == nil then return "" end
	return cgVideoToAudio[videoName] or ""
end

-- CG停止:手动停止当前播放所有CG
local function _StopCG()
	GameUtil.StopCG()
end

-- 断线重连清空缓存
local function _StopAndClearCG()
	cgVideoToAudio = {}
	cgId = {}
	callback = {}
	GameUtil.StopCG()
end

local function ReplayById(id)
	if id == nil or id == 0 or type(id) ~= "number" then
		warn("id == nil or type is not number", debug.traceback())
		return
	end
	local asset = CElementData.GetTemplate("Asset", id)
	if asset == nil then
		warn("asset == nil", debug.traceback())
		return
	end
	local path = asset.Path
	if path == nil then
		warn("error id path is nil")
		return
	end
	GameUtil.ReplayCG(path)	
end

-- 副本断线重连
local function _RestartCG(data)
	for i, v in ipairs(data) do
		ReplayById(v.cgId)
	end
end

local function _IsPlaying()
	return GameUtil.IsCGPlaying()
end

_G.CGMan =
{
	PlayByName = _PlayByName,
	PlayByNameEx = _PlayByNameEx,
	PlayById = _PlayById,
	StopBehaviour = _StopBehaviour,
	Finish = _Finish,
	StopCG = _StopCG,
	StopAndClearCG = _StopAndClearCG,
	RestartCG = _RestartCG,
	IsPlaying = _IsPlaying,
	GetAudioNameByVideoName = _GetAudioNameByVideoName,
}
