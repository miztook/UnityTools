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

_G.SOUND_ENUM = 
{
	--BGM=1, SFX=2, CG= 3, UI=4
	CH = 
	{
		BGM=1,
		SFX=2,
		CG=3,
		UI=4
	},

	MIX_MODE = 
	{
		--Game=0,
		Danger=1,
		FSUI=2,
		CreateRole=4,
		Chat=8,
		CG=16,
		PS=32,	--power saving
	},

	--Channel Vol rate
	MIX_CFG = 
	{
		--[0] = {[1]=1, [2]=1, [3]=1, [4]=1},
		[1] = {[1]=0.35, [2]=0.35, [3]=1, [4]=1},
		[2] = {[1]=0.25, [2]=0.25, [3]=1, [4]=1},
		[4] = {[1]=0.25, [2]=1, [3]=1, [4]=1},
		[8] = {[1]=0, [2]=1, [3]=1, [4]=1},
		[16] = {[1]=0, [2]=0, [3]=1, [4]=1},
		[32] = {[1]=0, [2]=0, [3]=0, [4]=0},
	},
}

local instance = nil

def.static("=>",CSoundMan).Instance = function()
	if not instance then
		instance = CSoundMan()
	end
	return instance
end

--def.field("number")._SfxVolSetting = 1
--def.field("number")._BgmVolSetting = 1
--def.field("number")._CGVolSetting = 1

def.field("number")._ChatVoiceCount = 0

local _lastMix = {}
local _newMix = {}
local _mixModeList={32,16,8,4,2,1}

--0 game, 01 = fs, 10 cg
local _MixMode = 0

def.method("boolean", "boolean").Init = function(self, bOnBgm, bOnEffect)
	--初始化声音，默认开启，以后服务器下发用户数据是否开启
	--self:EnableBackgroundMusic(bOnBgm)
	--self:EnableEffectAudio(bOnEffect)
	self._ChatVoiceCount = 0
	_MixMode = 0
	for i = 1, SOUND_ENUM.CH.UI do
		_lastMix[i] = 0
	end

	do
		local val = UserDataIns:GetField(EnumDef.LocalFields.BGMSysVolume)
		if val == nil then
			val = 1
		end
		self:SetBGMSysVolume(val)
		
--		if bOnBgm then
--			self:SetSoundBGMVolume(1, false)
--		else
--			self:SetSoundBGMVolume(0, false)
--		end
	end

	do
		local val = UserDataIns:GetField(EnumDef.LocalFields.EffectSysVolume)
		if val == nil then
			val = 1
		end
		self:SetEffectSysVolume(val)
		self:SetCutSceneSysVolume(val)
		self:SetUISysVolume(val)

--		if bOnEffect then
--			SetSoundEffectVolume(self,1)
--			SetSoundCutSceneVolume(self,1)
--			SetSoundUIVolume(self,1)
--		else
--			SetSoundEffectVolume(self,0)
--			SetSoundCutSceneVolume(self,0)
--			SetSoundUIVolume(self,0)
--		end
	end

	self:ApplyMixMode()
end

def.method("number","boolean").SetMixMode = function(self, channel, flag)
	if flag then
		_MixMode = bit.bor(_MixMode, channel)
	else
		_MixMode = bit.band(_MixMode, bit.bnot(channel))
	end

	self:ApplyMixMode()
end

def.method("number","=>","boolean").CheckMixMode = function(self, channel)
	return bit.band(_MixMode, channel) ~= 0
end

def.method().AddChatVoiceCount = function(self)
	self._ChatVoiceCount = self._ChatVoiceCount + 1
	if self._ChatVoiceCount > 0 then
		self:SetMixMode(SOUND_ENUM.MIX_MODE.Chat, true)
	end
end

def.method().SubChatVoiceCount = function(self)
	self._ChatVoiceCount = self._ChatVoiceCount - 1
	if self._ChatVoiceCount <= 0 then
		self:SetMixMode(SOUND_ENUM.MIX_MODE.Chat, false)
	end
end

def.method().ApplyMixMode = function(self)
	for i = 1, SOUND_ENUM.CH.UI do
		_newMix[i] = 1
	end

	--对每个模式取最小值
	local cfg=nil
	local ch = 0
	for i = 1, #_mixModeList do
		ch=_mixModeList[i]
		if bit.band(_MixMode, ch) ~= 0 then
			cfg = SOUND_ENUM.MIX_CFG[ch]
			if cfg ~= nil then
				for k = 1, SOUND_ENUM.CH.UI do
					--warn("sound cfg "..ch..": "..cfg[k].." "..k)
					_newMix[k] = math.min(cfg[k], _newMix[k])
				end
			end
		end
	end

	for i = 1, SOUND_ENUM.CH.UI do
		if _newMix[i] ~= _lastMix[i] then
			_lastMix[i] = _newMix[i]

			if 	i==SOUND_ENUM.CH.BGM then
				GameUtil.SetSoundBGMVolume(_newMix[i], true)
			elseif 	i==SOUND_ENUM.CH.SFX then
				GameUtil.SetSoundEffectVolume(_newMix[i])
			elseif 	i==SOUND_ENUM.CH.CG then
				GameUtil.SetCutSceneVolume(_newMix[i])
			elseif 	i==SOUND_ENUM.CH.UI then
				GameUtil.SetUIVolume(_newMix[i])
			end
		end
	end
end

-- 根据游戏模式调整音量
local function ModifyByGame(self, v, channel)			--(float,int)
	return _newMix[channel] * v
end

--背景音乐
def.method("number").SetBGMSysVolume = function (self, v)
	GameUtil.SetBGMSysVolume(v)
end

def.method("=>", "number").GetBGMSysVolume = function (self)
	return GameUtil.GetBGMSysVolume()
end

--音效
def.method("number").SetEffectSysVolume = function (self, v)
	GameUtil.SetEffectSysVolume(v)
end

def.method("=>", "number").GetEffectSysVolume = function (self)
	return GameUtil.GetEffectSysVolume()
end

--CG

def.method("number").SetCutSceneSysVolume = function (self, v)
	GameUtil.SetCutSceneSysVolume(v)
end

def.method("=>", "number").GetCutSceneSysVolume = function (self)
	return GameUtil.GetCutSceneSysVolume()
end

--UI
def.method("number").SetUISysVolume = function (self, v)
	GameUtil.SetUISysVolume(v)
end

def.method("=>", "number").GetUISysVolume = function (self)
	return GameUtil.GetUISysVolume()
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

def.method("table").DebugMode = function( self, args)

		if #args>2 then
			SOUND_ENUM.MIX_CFG[2][1]=math.clamp(tonumber(args[2]),0,1)
			SOUND_ENUM.MIX_CFG[2][2]=math.clamp(tonumber(args[3]),0,1)
			warn("CSound set cfg "..SOUND_ENUM.MIX_CFG[2][1]..", "..SOUND_ENUM.MIX_CFG[2][2])
		elseif #args>1 then
			SOUND_ENUM.MIX_CFG[2][1]=math.clamp(tonumber(args[2]),0,1)
			SOUND_ENUM.MIX_CFG[2][2]=math.clamp(tonumber(args[2]),0,1)
			warn("CSound set cfg "..SOUND_ENUM.MIX_CFG[2][1]..", "..SOUND_ENUM.MIX_CFG[2][2])
		else
			warn("CSound mix ".._MixMode..", ".._newMix[1].._newMix[2].._newMix[3].._newMix[4]..", chat "..self._ChatVoiceCount)
		end

end

def.method().Reset = function(self)
	GameUtil.ResetSoundMan()
end

CSoundMan.Commit()
return CSoundMan
