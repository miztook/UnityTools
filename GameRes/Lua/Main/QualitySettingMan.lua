local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UserData = require "Data.UserData".Instance()

local QualitySettingMan = Lplus.Class("QualitySettingMan")
local def = QualitySettingMan.define

local FpsTables = {}
local CurFrameCount = 0
local LastFPSTime = 0
local CanSetHighFrameRate = false


local instance = nil

def.static("=>",QualitySettingMan).Instance = function()
	if not instance then
		instance = QualitySettingMan()
	end
	return instance
end

--获取地图偏移量
def.method("=>","table").GetDeviceLevel = function(self)
	local DeviceLevel = nil 
	local ret, msg, result = pcall(dofile, "Configs/DeviceLevelCfg.lua")
	if ret then
		DeviceLevel = result
	else
		warn(msg)
	end	
	return DeviceLevel
end

def.method("=>", "number").GetRecommendLevel = function(self)
	local recommendLevel = 0
	local deviceModel = SystemInfo.deviceModel
   	local dataList = self:GetDeviceLevel()
	if recommendLevel == 0 then
		if _G.IsAndroid() then  -- android
            local deviceModel = SystemInfo.deviceModel
           	local dataList = self:GetDeviceLevel()
           	for k,j in pairs(dataList.android) do
           		if string.find(deviceModel,k) then 
           			recommendLevel = dataList.android[k]
           			break
           		end
           	end
           	if recommendLevel ~= 0 and recommendLevel ~= nil then 
           		warn(" deviceModel recommendLevel ",deviceModel,recommendLevel)
           		return recommendLevel 
            end

            local processorCount = SystemInfo.processorCount
            local processorFrequency = SystemInfo.processorFrequency
            if processorFrequency >= 2000 then
            	if processorCount >= 8 then   
            		recommendLevel = 3 
            	elseif processorCount >= 4 then 
            		recommendLevel = 2
            	else
            		recommendLevel = 1
            	end
            elseif processorFrequency >= 1500 and processorFrequency < 2000 then
                if processorCount >= 8 then   
            		recommendLevel = 3 
            	elseif processorCount >= 4 then 
            		recommendLevel = 2
            	else
            		recommendLevel = 1
            	end
            else 
            	recommendLevel = 1
            end
            warn("processorCount,processorFrequency,recommendLevel ",processorCount,processorFrequency,recommendLevel)
            return recommendLevel
		elseif _G.IsIOS() then  -- iOS
            local deviceModel = SystemInfo.deviceModel
            local dataList = self:GetDeviceLevel()

           	recommendLevel = dataList.ios[deviceModel]
           	if recommendLevel == nil then 
				warn("Other platform:", deviceModel,1)
           		return 1
           	else
           		warn("ios DeviceModel:", deviceModel, recommendLevel)
           		return recommendLevel
           	end
        else
        	recommendLevel = 3
        	warn("Windows:", deviceModel, recommendLevel)
        end
	end

	return recommendLevel
end

local QualitySettings =
{
	[1] = { 
			PostProcessLevel = 0,
			ShadowLevel = 0,
			CharacterLevel = 0,
			SceneDetailLevel = 0,
			FxLevel = 0,

			DofOn = false,
			PostProcessFogOn = false,
			WaterReflectionOn = false,
			WeatherOn = false,
			DetailSoundOn = false,
			FPSLimit = 30,
		  },

	[2] = { 
			PostProcessLevel = 1,
			ShadowLevel = 1,
			CharacterLevel = 1,
			SceneDetailLevel = 1,
			FxLevel = 1,

			DofOn = false,
			PostProcessFogOn = false,
			WaterReflectionOn = false,
			WeatherOn = true,
			DetailSoundOn = false,
			FPSLimit = 30,
		  },

	[3] = { 
			PostProcessLevel = 2,
			ShadowLevel = 1,
			CharacterLevel = 2,
			SceneDetailLevel = 2,
			FxLevel = 2,

			DofOn = false,
			PostProcessFogOn = false,
			WaterReflectionOn = false,
			WeatherOn = true,
			DetailSoundOn = true,
			FPSLimit = 30,
		},

	[4] = { 
			PostProcessLevel = 3,
			ShadowLevel = 2,
			CharacterLevel = 2,
			SceneDetailLevel = 2,
			FxLevel = 2,

			DofOn = true,
			PostProcessFogOn = false,
			WaterReflectionOn = false,
			WeatherOn = true,
			DetailSoundOn = true,
			FPSLimit = 30,
		},
}

def.method().DecideQualityLevel = function(self)

	--根据机型设置 在后处理等级2的时候，使用简化版BloomHD，目标是保证等级2的帧率
	self:SetSimpleBloomHDParams(2, 4)

	--默认开启，对效率影响不大
	self:EnableWeatherEffect(true)
	self:EnableDetailFootStepSound(true)

	--控制高帧率显示
	if _G.IsAndroid() then  -- android
	
	elseif _G.IsIOS() then  -- iOS

	else  --
		self:UpdateCanSetHighRate(true)
	end

	if self:HasFieldInUserData() then
		self:SetQualityConfigFromUserData()
		return
	end

	--没有userdata，使用推荐位
	local recommendLv = self:GetRecommendLevel()
	self:SetWholeQualityLevel(recommendLv)
	self:ApplyChanges()

	if recommendLv >= 1 and recommendLv <= 4 then
		local setting = QualitySettings[recommendLv]

		self:EnableDOF(setting.DofOn)
		self:EnablePostProcessFog(setting.PostProcessFogOn)
		self:EnableWaterReflection(setting.WaterReflectionOn)
		self:SetFPSLimit(setting.FPSLimit)
	end

	--推荐高帧率
	if _G.IsAndroid() then  -- android
	
	elseif _G.IsIOS() then  -- iOS

	else  --
		self:SetFPSLimit(60)
	end

end

def.method().UpdateQualityLevel = function(self)
	-- 策略：根据FPS进行调整；每秒统计一下帧率，每5秒根据平均帧率，调整一次LOD
	--       每切换一个场景后，从高往低进行调整
	local n = Time.frameCount - CurFrameCount
    local dt = Time.time - LastFPSTime
    FpsTables[#FpsTables+1] = n/dt
    CurFrameCount = Time.frameCount
	LastFPSTime = Time.time

	local fpscount = #FpsTables
	if fpscount == 5 then
		local total = 0
		for _,v in ipairs(FpsTables) do
			total = total + v
		end
		local fps = total/fpscount
		if fps < 15 then
			self:DecreaseQualityLevel()
		end
		FpsTables = {}
	end
end

def.method("boolean").UpdateCanSetHighRate = function(self, isCan)
    CanSetHighFrameRate = isCan
end

def.method("=>", "boolean").CanSetHighFrameRate = function(self)
    return CanSetHighFrameRate
end

def.method().DecreaseQualityLevel = function (self)
	-- body
end

--总体等级 低 中 高 最高 自定义
def.method("number").SetWholeQualityLevel = function (self, level)
	
	if level == 1 then

		self:SetPostProcessLevel(QualitySettings[1].PostProcessLevel)
		self:SetShadowLevel(QualitySettings[1].ShadowLevel)
		self:SetCharacterLevel(QualitySettings[1].CharacterLevel)
		self:SetSceneDetailLevel(QualitySettings[1].SceneDetailLevel)
		self:SetFxLevel(QualitySettings[1].FxLevel)

	elseif level == 2 then

		self:SetPostProcessLevel(QualitySettings[2].PostProcessLevel)
		self:SetShadowLevel(QualitySettings[2].ShadowLevel)
		self:SetCharacterLevel(QualitySettings[2].CharacterLevel)
		self:SetSceneDetailLevel(QualitySettings[2].SceneDetailLevel)
		self:SetFxLevel(QualitySettings[2].FxLevel)

	elseif level == 3 then

		self:SetPostProcessLevel(QualitySettings[3].PostProcessLevel)
		self:SetShadowLevel(QualitySettings[3].ShadowLevel)
		self:SetCharacterLevel(QualitySettings[3].CharacterLevel)
		self:SetSceneDetailLevel(QualitySettings[3].SceneDetailLevel)
		self:SetFxLevel(QualitySettings[3].FxLevel)

	elseif level == 4 then

		self:SetPostProcessLevel(QualitySettings[4].PostProcessLevel)
		self:SetShadowLevel(QualitySettings[4].ShadowLevel)
		self:SetCharacterLevel(QualitySettings[4].CharacterLevel)
		self:SetSceneDetailLevel(QualitySettings[4].SceneDetailLevel)
		self:SetFxLevel(QualitySettings[4].FxLevel)

	end
	
end

def.method("=>", "number").GetWholeQualityLevel = function (self)
	local postprocessLevel = self:GetPostProcessLevel()
	local shadowLevel = self:GetShadowLevel()
	local characterLevel = self:GetCharacterLevel()
	local scenedetailLevel = self:GetSceneDetailLevel()
	local fxLevel = self:GetFxLevel()

	return self:CalcWholeQualityLevel(postprocessLevel, shadowLevel, characterLevel, scenedetailLevel, fxLevel)
end

def.method("number", "number", "number", "number", "number", "=>", "number").CalcWholeQualityLevel = function (self, postprocessLevel, shadowLevel, characterLevel, scenedetailLevel, fxLevel)
	local wholeLevel = 0

	if QualitySettings[1].PostProcessLevel == postprocessLevel and
			QualitySettings[1].ShadowLevel == shadowLevel and
			QualitySettings[1].CharacterLevel == characterLevel and
			QualitySettings[1].SceneDetailLevel == scenedetailLevel and
			QualitySettings[1].FxLevel == fxLevel then
		wholeLevel = 1
	elseif QualitySettings[2].PostProcessLevel == postprocessLevel and
			QualitySettings[2].ShadowLevel == shadowLevel and
			QualitySettings[2].CharacterLevel == characterLevel and
			QualitySettings[2].SceneDetailLevel == scenedetailLevel and
			QualitySettings[2].FxLevel == fxLevel then
		wholeLevel = 2
	elseif QualitySettings[3].PostProcessLevel == postprocessLevel and
			QualitySettings[3].ShadowLevel == shadowLevel and
			QualitySettings[3].CharacterLevel == characterLevel and
			QualitySettings[3].SceneDetailLevel == scenedetailLevel and
			QualitySettings[3].FxLevel == fxLevel then
		wholeLevel = 3
	elseif QualitySettings[4].PostProcessLevel == postprocessLevel and
			QualitySettings[4].ShadowLevel == shadowLevel and
			QualitySettings[4].CharacterLevel == characterLevel and
			QualitySettings[4].SceneDetailLevel == scenedetailLevel and
			QualitySettings[4].FxLevel == fxLevel then
		wholeLevel = 4
	end
	
	return wholeLevel
end


--后处理 0,1,2
def.method("number").SetPostProcessLevel = function (self, level)
	GameUtil.SetPostProcessLevel(level)
end

def.method("=>", "number").GetPostProcessLevel = function (self)
	return GameUtil.GetPostProcessLevel()
end

--阴影 0,1,2
def.method("number").SetShadowLevel = function (self, level)
	GameUtil.SetShadowLevel(level)

	local bEnableShadow = level < 1      --阴影片是否开启

	if game._HostPlayer ~= nil then
		game._HostPlayer:EnableShadow(bEnableShadow)
	end

	if game._CurWorld ~= nil then
		local playerObjMap = game._CurWorld._PlayerMan._ObjMap
		for _,v in pairs(playerObjMap) do
			if v ~= nil then
				v:EnableShadow(bEnableShadow)
			end
		end
	end
end

def.method("=>", "number").GetShadowLevel = function (self)
	return GameUtil.GetShadowLevel()
end

--角色质量 0,1,2
def.method("number").SetCharacterLevel = function (self, level)
	GameUtil.SetCharacterLevel(level)
end

def.method("=>", "number").GetCharacterLevel = function (self)
	return GameUtil.GetCharacterLevel()
end

--场景细节 0,1,2
def.method("number").SetSceneDetailLevel = function (self, level)
	GameUtil.SetSceneDetailLevel(level)
end

def.method("=>", "number").GetSceneDetailLevel = function (self)
	return GameUtil.GetSceneDetailLevel()
end

--特效等级
def.method("number").SetFxLevel = function (self, level)
	GameUtil.SetFxLevel(level)

	if level == 0 then 
		GameUtil.SetActiveFxMaxCount(20)
	elseif level == 1 then
		GameUtil.SetActiveFxMaxCount(25)
	else
		GameUtil.SetActiveFxMaxCount(30)
	end
end

def.method("=>", "number").GetFxLevel = function (self)
	return GameUtil.GetFxLevel()
end

--景深效果
def.method("=>", "boolean").IsUseDOF = function (self)
	return GameUtil.IsUseDOF()
end

def.method("boolean").EnableDOF = function (self, enable)
	GameUtil.EnableDOF(enable)
end

--高级雾效
def.method("=>", "boolean").IsUsePostProcessFog = function (self)
	return GameUtil.IsUsePostProcessFog()
end

def.method("boolean").EnablePostProcessFog = function (self, enable)
	GameUtil.EnablePostProcessFog(enable)
end

--水面反射
def.method("=>", "boolean").IsUseWaterReflection = function (self)
	return GameUtil.IsUseWaterReflection()
end

def.method("boolean").EnableWaterReflection = function (self, enable)
	GameUtil.EnableWaterReflection(enable)
end

--天气效果
def.method("=>", "boolean").IsUseWeatherEffect = function (self)
	return GameUtil.IsUseWeatherEffect()
end

def.method("boolean").EnableWeatherEffect = function (self, enable)
	GameUtil.EnableWeatherEffect(enable)
end

def.method("number", "number").SetSimpleBloomHDParams = function (self, level, iteration)
	GameUtil.SetSimpleBloomHDParams(level, iteration)
end

--细节脚步音效
def.method("=>", "boolean").IsUseDetailFootStepSound = function (self)
	return GameUtil.IsUseDetailFootStepSound()
end

def.method("boolean").EnableDetailFootStepSound = function (self, enable)
	GameUtil.EnableDetailFootStepSound(enable)
end

--FPS限制
def.method("=>", "number").GetFPSLimit = function (self)
	return GameUtil.GetFPSLimit()
end

def.method("number").SetFPSLimit = function (self, fps)
	GameUtil.SetFPSLimit(fps)
end

def.method().ApplyChanges = function (self)
	GameUtil.ApplyGfxConfig()
end

def.method().SaveQualityConfigToUserData = function (self)
	UserData:SetField(EnumDef.LocalFields.PostProcessLevel, self:GetPostProcessLevel())
	UserData:SetField(EnumDef.LocalFields.ShadowLevel, self:GetShadowLevel())
	UserData:SetField(EnumDef.LocalFields.CharacterLevel, self:GetCharacterLevel())
	UserData:SetField(EnumDef.LocalFields.SceneDetailLevel, self:GetSceneDetailLevel())
	UserData:SetField(EnumDef.LocalFields.FxLevel, self:GetFxLevel())

	if self:IsUseDOF() then
		UserData:SetField(EnumDef.LocalFields.IsUseDOF, 1)
	else
		UserData:SetField(EnumDef.LocalFields.IsUseDOF, 0)
	end

	if self:IsUsePostProcessFog() then
		UserData:SetField(EnumDef.LocalFields.IsUsePostProcessFog, 1)
	else
		UserData:SetField(EnumDef.LocalFields.IsUsePostProcessFog, 0)
	end

	if self:IsUseWaterReflection() then
		UserData:SetField(EnumDef.LocalFields.IsUseWaterReflection, 1)
	else
		UserData:SetField(EnumDef.LocalFields.IsUseWaterReflection, 0)
	end

	UserData:SetField(EnumDef.LocalFields.FPSLimit, self:GetFPSLimit())
end

def.method("=>", "boolean").HasFieldInUserData = function(self)
		
	return (nil ~= UserData:GetField(EnumDef.LocalFields.PostProcessLevel) and
		nil ~= UserData:GetField(EnumDef.LocalFields.ShadowLevel) and
		nil ~= UserData:GetField(EnumDef.LocalFields.CharacterLevel) and
		nil ~= UserData:GetField(EnumDef.LocalFields.SceneDetailLevel) and
		nil ~= UserData:GetField(EnumDef.LocalFields.FxLevel) and
		nil ~= UserData:GetField(EnumDef.LocalFields.IsUseDOF) and 
		nil ~= UserData:GetField(EnumDef.LocalFields.IsUsePostProcessFog) and 
		nil ~= UserData:GetField(EnumDef.LocalFields.IsUseWaterReflection) and 
		nil ~= UserData:GetField(EnumDef.LocalFields.FPSLimit))
end

def.method().SetQualityConfigFromUserData = function (self)
	local level, value = nil, nil

	level = UserData:GetField(EnumDef.LocalFields.PostProcessLevel)
	if level ~= nil then
		self:SetPostProcessLevel(level)
	end

	level = UserData:GetField(EnumDef.LocalFields.ShadowLevel)
	if level ~= nil then
		self:SetShadowLevel(level)
	end 

	level = UserData:GetField(EnumDef.LocalFields.CharacterLevel)
	if level ~= nil then
		self:SetCharacterLevel(level)
	end

	level = UserData:GetField(EnumDef.LocalFields.SceneDetailLevel)
	if level ~= nil then
		self:SetSceneDetailLevel(level)
	end

	level = UserData:GetField(EnumDef.LocalFields.FxLevel)
	if level ~= nil then
		self:SetFxLevel(level)
	end

	value = UserData:GetField(EnumDef.LocalFields.IsUseDOF)
	if value ~= nil then
		if value ~= 0 then
			self:EnableDOF(true)
		else
			self:EnableDOF(false)
		end
	end

	value = UserData:GetField(EnumDef.LocalFields.IsUsePostProcessFog)
	if value ~= nil then
		if value ~= 0 then
			self:EnablePostProcessFog(true)
		else
			self:EnablePostProcessFog(false)
		end
	end

	value = UserData:GetField(EnumDef.LocalFields.IsUseWaterReflection)
	if value ~= nil then
		if value ~= 0 then
			self:EnableWaterReflection(true)
		else
			self:EnableWaterReflection(false)
		end
	end

	value = UserData:GetField(EnumDef.LocalFields.FPSLimit)
	if value ~= nil then
		self:SetFPSLimit(value)
	end

	self:ApplyChanges()			--应用修改
end

QualitySettingMan.Commit()
return QualitySettingMan