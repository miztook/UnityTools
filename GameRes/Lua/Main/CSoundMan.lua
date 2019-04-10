local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local UserDataIns = require "Data.UserData".Instance()
local MapBasicConfig = require "Data.MapBasicConfig"
local CSoundMan = Lplus.Class("CSoundMan")
local def = CSoundMan.define

_G.SOUND_TYPES = 
{
	GUI = "ui",
	ENVIRONMENT = "enviroment",
	BACKGROUND = "background",
}

def.field("boolean")._IsBgmChangeWaiting = false
def.field("number")._TimerId4BgmChange = 0
def.field("boolean")._IsEnvMusicChangeWaiting = false
def.field("number")._TimerId4EnvMusicChange = 0
def.field("boolean")._IsWeatherMusicChangeWaiting = false
def.field("number")._TimerId4WeatherMusicChange = 0

local instance = nil

def.static("=>",CSoundMan).Instance = function()
	if not instance then
		instance = CSoundMan()
	end
	return instance
end

def.method("boolean", "boolean").Init = function(self, bOnBgm, bOnEffect)
	--初始化声音，默认开启，以后服务器下发用户数据是否开启
	--self:EnableBackgroundMusic(bOnBgm)
	--self:EnableEffectAudio(bOnEffect)

	do 
		local val = UserDataIns:GetField(EnumDef.LocalFields.BGMSysVolume)
		if val == nil then
			val = 1
		end
		self:SetBGMSysVolume(val)
		
		if bOnBgm then
			self:SetSoundBGMVolume(1, false)
		else
			self:SetSoundBGMVolume(0, false)
		end
	end

	do
		local val = UserDataIns:GetField(EnumDef.LocalFields.EffectSysVolume)
		if val == nil then
			val = 1
		end
		self:SetEffectSysVolume(val)
		self:SetCutSceneSysVolume(val)

		if bOnEffect then
			self:SetSoundEffectVolume(1)
			self:SetSoundCutSceneVolume(1)
		else
			self:SetSoundEffectVolume(0)
			self:SetSoundCutSceneVolume(0)
		end
	end

end

-- 游戏模块直接调整音量
local function ModifyByGame(v)
	if game._CPowerSavingMan ~= nil and game._CPowerSavingMan:IsSleeping() then
		v=v*0
		return v
	end
	return v
end

--背景音乐
def.method("number", "boolean").SetSoundBGMVolume = function(self, v, isImmediate)
	GameUtil.SetSoundBGMVolume(ModifyByGame(v), isImmediate)
end

def.method("number").SetBGMSysVolume = function (self, v)
	GameUtil.SetBGMSysVolume(v)
end

def.method("=>", "number").GetBGMSysVolume = function (self)
	return GameUtil.GetBGMSysVolume()
end

--音效
def.method("number").SetSoundEffectVolume = function(self, v)
	GameUtil.SetSoundEffectVolume(ModifyByGame(v))
end

def.method("number").SetEffectSysVolume = function (self, v)
	return GameUtil.SetEffectSysVolume(v)
end

def.method("=>", "number").GetEffectSysVolume = function (self)
	return GameUtil.GetEffectSysVolume()
end

--CG
def.method("number").SetSoundCutSceneVolume = function(self, v)
	GameUtil.SetCutSceneVolume(ModifyByGame(v))
end

def.method("number").SetCutSceneSysVolume = function (self, v)
	return GameUtil.SetCutSceneSysVolume(v)
end

def.method("=>", "number").GetCutSceneSysVolume = function (self)
	return GameUtil.GetCutSceneSysVolume()
end

--心跳濒死声音
def.method("=>", "number").GetHealthVolume = function (self)
	return GameUtil.GetHealthVolume()
end

def.method("number").SetHealthVolume = function(self, v)
	GameUtil.SetHealthVolume(v)
end


def.method("number").ChangeBackgroundMusic = function(self, fadeTime)
	if fadeTime > 0 then
		self._IsBgmChangeWaiting = true
		self._TimerId4BgmChange = _G.AddGlobalTimer(fadeTime, true, function()
        	
        	self:ChangeBackgroundMusicImp()
			self._IsBgmChangeWaiting = false
    	end)
	else
		if self._IsBgmChangeWaiting then
			if self._TimerId4BgmChange ~= 0 then
				_G.RemoveGlobalTimer(self._TimerId4BgmChange)
		        self._TimerId4BgmChange = 0
			end
		end
		
		self:ChangeBackgroundMusicImp()
		self._IsBgmChangeWaiting = false

	end
end

def.method("number").ChangeEnvironmentMusic = function(self, fadeTime)
	if fadeTime > 0 then
		self._IsEnvMusicChangeWaiting = true
		self._TimerId4EnvMusicChange = _G.AddGlobalTimer(fadeTime, true, function()
        	
        	self:ChangeEnvironmentMusicImp()
			self._IsEnvMusicChangeWaiting = false
    	end)
	else
		if self._IsEnvMusicChangeWaiting then
			if self._TimerId4EnvMusicChange ~= 0 then
				_G.RemoveGlobalTimer(self._TimerId4EnvMusicChange)
		        self._TimerId4EnvMusicChange = 0
			end
		end
		
		self:ChangeEnvironmentMusicImp()
		self._IsEnvMusicChangeWaiting = false

	end
end

def.method().ChangeBackgroundMusicImp = function(self)
	local sceneTid = game._CurWorld._WorldInfo.SceneTid
	local hp = game._HostPlayer
	--local sceneInfo = _G.MapBasicInfoTable[sceneTid]
	local sceneInfo = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid)
    if sceneInfo == nil then return end

	local regionIds = hp._CurrentRegionIds
	local regionCount = #regionIds
	local bgmName = ""
	local isServerCombatState = hp:IsInServerCombatState()
	
	if isServerCombatState then
		local destRegionId = 0
		for i = 1, regionCount do
			for _, w in pairs(sceneInfo.Region) do
				for k, x in pairs(w) do
					if k == regionIds[i] then
						local region = x
						if not IsNilOrEmptyString(region.BattleMusic) and k > destRegionId then
							bgmName = region.BattleMusic
							destRegionId = k
						end
					end
				end
			end
		end
	end

	if IsNilOrEmptyString(bgmName) then
		local destRegionId = 0
		for i = 1, regionCount do
			for _, w in pairs(sceneInfo.Region) do
				for k, x in pairs(w) do
					if k == regionIds[i] then
						local region = x
						if not IsNilOrEmptyString(region.BackgroundMusic) and k > destRegionId then
							bgmName = region.BackgroundMusic
							destRegionId = k
						end				
					end
				end
			end
		end
	end

	if IsNilOrEmptyString(bgmName) then
		if isServerCombatState then
			bgmName = sceneInfo.BattleMusic
		end

		if IsNilOrEmptyString(bgmName) then
			bgmName = sceneInfo.BackgroundMusic
		end
	end

	--warn("regionIds  count = ", #regionIds, "bgmName = ", bgmName)
	self:PlayBackgroundMusic(bgmName, 2)
end

def.method().ChangeEnvironmentMusicImp = function(self)
	local sceneTid = game._CurWorld._WorldInfo.SceneTid
	local hp = game._HostPlayer
	--local sceneInfo = _G.MapBasicInfoTable[sceneTid]
	local sceneInfo = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid)

	local regionIds = hp._CurrentRegionIds
	local regionCount = #regionIds
	local envName = sceneInfo.EnvironmentMusic

	local destRegionId = 0
	for i = 1, regionCount do
		for _, w in ipairs(sceneInfo.Region) do
			for k, x in pairs(w) do
				if k == regionIds[i] then
					local region = x
					if not IsNilOrEmptyString(region.EnvironmentMusic) and k > destRegionId then
						envName = region.EnvironmentMusic
						destRegionId = k
					end
				end
			end
		end
	end

	--warn("regionIds  count = ", #regionIds, "bgmName = ", bgmName)
	self:PlayEnvironmentMusic(envName, 2)
end

def.method("string", "number").PlayBackgroundMusic = function(self, bgmName, fadeInTime)
    if not IsNilOrEmptyString(bgmName) then
	    GameUtil.PlayBackgroundMusic(bgmName, fadeInTime)
	else
		GameUtil.PlayBackgroundMusic("", 0)
    end
end

def.method().StopBackgroundMusic = function(self)
	GameUtil.PlayBackgroundMusic("", 0)
end

def.method("string", "number").PlayEnvironmentMusic = function(self, envName, fadeInTime)
	if not IsNilOrEmptyString(envName) then
	    GameUtil.PlayEnvironmentMusic(envName, fadeInTime)
	else
		GameUtil.PlayEnvironmentMusic("", 0)
    end
end

def.method().StopEnvironmentMusic = function (self)
	GameUtil.PlayEnvironmentMusic("", 0)
end

def.method("string","table", "number", "=>", "string").Play3DAudio = function( self, soundName, pos, priority)
	return GameUtil.Play3DAudio(soundName, pos, priority)
end

def.method("string","userdata", "number", "=>", "string").PlayAttached3DAudio = function( self, soundName, attachedGo, priority)
	return GameUtil.PlayAttached3DAudio(soundName, attachedGo, priority)
end

def.method("string","table", "number").Play3DVoice = function( self, soundName, pos, priority)
	GameUtil.Play3DVoice(soundName, pos, priority)
end

def.method("string","table", "number").Play3DShout = function( self, soundName, pos, priority)
	GameUtil.Play3DShout(soundName, pos, priority)
end

def.method("string", "string").Stop3DAudio = function(self, soundName, as_name)
	GameUtil.Stop3DAudio(soundName, as_name)
end

def.method("string", "string").Stop2DAudio = function(self, soundName, as_name)
	GameUtil.Stop2DAudio(soundName, as_name)
end

def.method("string", "number").Play2DAudio = function( self, soundName, priority)
	GameUtil.Play2DAudio(soundName, priority)
end

def.method("string", "number").Play2DHeartBeat = function( self, soundName, priority)
	GameUtil.Play2DHeartBeat(soundName, priority)
end

def.method().Reset = function(self)
	GameUtil.ResetSoundMan()
end

CSoundMan.Commit()
return CSoundMan
