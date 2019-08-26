
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local QualitySettingMan = require "Main.QualitySettingMan"

local FPSAdapter = Lplus.Class("FPSAdapter")
local def = FPSAdapter.define

local LowFPSLastSecond = 0
local LastCheckTime = 0
local LastCheckFrameCount = 0
local QualityPrams = {}
local CurLevel = 0

--[[
-高度雾 + DOF + WaterReflection
-阴影Shadow开关
-Fx特效等级
-分块加载等级 （0 1 2，越小越重要） 
-QualitySettings.blendWeights & Shader.globalMaximumLOD  （0 1 2，越小消耗越少）
-QualitySettings.masterTextureLimit (0 原始大小， 1 mipmap第一级，2 mipmap第二级)
-BloomHD迭代次数 
-修改各Layer的剔除距离
-BloomHD开关
-分辨率按照等级进行调整，不在是默认的1920*1080
]]

def.static().SyncSettings = function()
	--warn("SyncSettings", debug.traceback())
	local qualityMan = QualitySettingMan.Instance()
	QualityPrams.PPL = qualityMan:GetPostProcessLevel()
	QualityPrams.ShadowLevel = qualityMan:GetShadowLevel()
	QualityPrams.CharacterLevel = qualityMan:GetCharacterLevel()
	QualityPrams.SceneDetailLevel = qualityMan:GetSceneDetailLevel()
	QualityPrams.FxLevel = qualityMan:GetFxLevel()
	QualityPrams.DOFEnabled = qualityMan:IsUseDOF()
	QualityPrams.PPFogEnabled = qualityMan:IsUsePostProcessFog()
	QualityPrams.IsUseWaterReflection = qualityMan:IsUseWaterReflection()
end


local SkyBoxName = "Circulationsphere(Clone)"

local function DoSth2IncreaseFPS()
	if CurLevel == 4 then return end -- 已经是最低了，调无可调，换机器吧！！！

	local qualityMan = QualitySettingMan.Instance()

	if CurLevel == 0 then
		-- 关高度雾 DOF WaterReflection
		-- 关闭实时阴影
		-- 特效LOD等级切换至L0
		-- 分块加载等级切换至0
		-- QualitySettings.blendWeights 切换至 TwoBones
		-- BloomHD切换至简化模式
		if qualityMan:IsUsePostProcessFog() then
			qualityMan:EnablePostProcessFog(false)
		end

		if qualityMan:IsUseDOF() then
			qualityMan:EnableDOF(false)
		end

		if qualityMan:IsUseWaterReflection() then
			qualityMan:EnableWaterReflection(false)
		end

		if qualityMan:GetShadowLevel() > 0 then
			qualityMan:SetShadowLevel(0)
		end

		if qualityMan:GetFxLevel() > 0 then
			qualityMan:SetFxLevel(0)
		end

		if qualityMan:GetSceneDetailLevel() > 0 then
			qualityMan:SetSceneDetailLevel(0)
		end

		if qualityMan:GetCharacterLevel() > 1 then
			qualityMan:SetCharacterLevel(1)
			-- TODO: Character Shader LOD 200 效果太差
		end

		if qualityMan:GetPostProcessLevel() == 2 then
			qualityMan:SetPostProcessLevel(1) 
			qualityMan:SetSimpleBloomHDParams(2, 4)
		end

		GameUtil.ApplyGfxConfig()

		-- 调整MainCamera ClipPlane & Culling Distance
		-- QualitySettings.masterTextureLimit  最高设为Mipmap 1级
		game:SetMainCameraLevel(3)

		local skyBox = GameObject.Find(SkyBoxName)
		if skyBox ~= nil then
			GameUtil.SetLayerRecursively(skyBox, EnumDef.RenderLayer.Unblockable)  -- 暂时使用这一层
		end

		if GameUtil.GetMasterTextureLimit() == 0 then
			GameUtil.ChangeMasterTextureLimit(1)   -- 降至原来的1/4
		end

		CurLevel = 1
	elseif CurLevel == 1 then
		-- BloomHD调整迭代参数 4 2
		-- Shader.globalMaximumLOD 切换至 200
		if qualityMan:GetPostProcessLevel() == 1 then
			qualityMan:SetSimpleBloomHDParams(4, 2)
			GameUtil.ApplyGfxConfig()
		end

		if qualityMan:GetCharacterLevel() > 0 then
			qualityMan:SetCharacterLevel(0)
			-- TODO: Character Shader LOD 200 效果太差
		end
		game:SetMainCameraLevel(2)

		CurLevel = 2
	elseif CurLevel == 2 then
		-- 关闭后处理
		-- 调整MainCamera ClipPlane & Culling Distance
		local ppl = qualityMan:GetPostProcessLevel() 
		if ppl >= 0 and ppl <= 2 then
			qualityMan:SetPostProcessLevel(3)  -- 关闭
			GameUtil.ApplyGfxConfig()
		end

		game:SetMainCameraLevel(1)

		CurLevel = 3
	end

	--warn("Change FPS level to " .. tostring(CurLevel))
end

local function ResetParams()
	LastCheckFrameCount = 0
	LastCheckTime = 0
	LastCheckFrameCount = 0
	LowFPSLastSecond = 0
end

def.static().Tick = function()
	-- 只在游戏中才进行检测
	if game._CurGameStage ~= _G.GameStage.InGameStage then return end
	-- Loading过程中不做检测
	if game:IsLoading() then return end
	-- 可能在画质设置中
	local CPanelUISetting = require "GUI.CPanelUISetting"
	if CPanelUISetting.Instance():IsShow() then return end
	-- 数据尚未初始化
	if QualityPrams.PPL == nil then return end

	if LastCheckFrameCount == 0 then
		LastCheckTime = Time.time
		LastCheckFrameCount = Time.frameCount
	else
		local curTime = Time.time
		local curFrameCount = Time.frameCount
		local deltaTime = (curTime - LastCheckTime)
		local fps = (curFrameCount - LastCheckFrameCount) / deltaTime
		if fps < 25 then
			LowFPSLastSecond = LowFPSLastSecond + deltaTime
		else
			LowFPSLastSecond = 0
		end

		--warn("fps =", fps, " LastSecond", LowFPSLastSecond)
	end

	if LowFPSLastSecond > 3 then
		DoSth2IncreaseFPS()
		ResetParams()
	end
end

def.static().Revert = function()
	ResetParams()
	CurLevel = 0

	if QualityPrams.PPL == nil then return end

	local qualityMan = QualitySettingMan.Instance()
	if qualityMan:GetPostProcessLevel() ~= QualityPrams.PPL then
		qualityMan:SetPostProcessLevel(QualityPrams.PPL) 
		qualityMan:SetSimpleBloomHDParams(2, 4)
	end
	if qualityMan:GetShadowLevel() ~= QualityPrams.ShadowLevel then
		qualityMan:SetShadowLevel(QualityPrams.ShadowLevel)
	end
	if qualityMan:GetCharacterLevel() ~= QualityPrams.CharacterLevel then
		qualityMan:SetCharacterLevel(QualityPrams.CharacterLevel)
	end
	if qualityMan:GetSceneDetailLevel() ~= QualityPrams.SceneDetailLevel then
		qualityMan:SetSceneDetailLevel(QualityPrams.SceneDetailLevel)
	end
	if qualityMan:GetFxLevel() ~= QualityPrams.FxLevel then
		qualityMan:SetFxLevel(QualityPrams.FxLevel)
	end
	if qualityMan:IsUseDOF() ~= QualityPrams.DOFEnabled then
		qualityMan:EnableDOF(QualityPrams.DOFEnabled)
	end
	if qualityMan:IsUsePostProcessFog() ~= QualityPrams.PPFogEnabled then
		qualityMan:EnablePostProcessFog(QualityPrams.PPFogEnabled)
	end
	if qualityMan:IsUseWaterReflection() ~= QualityPrams.IsUseWaterReflection then
		qualityMan:EnableWaterReflection(QualityPrams.IsUseWaterReflection)
	end
	GameUtil.ApplyGfxConfig()

	local QualitySettingMan = require "Main.QualitySettingMan"
	local lv = QualitySettingMan.Instance():GetRecommendLevel()
    game:SetMainCameraLevel(lv)

	local skyBox = GameObject.Find(SkyBoxName)
	if skyBox ~= nil then
		GameUtil.SetLayerRecursively(skyBox, EnumDef.RenderLayer.Background)
	end

	GameUtil.ChangeMasterTextureLimit(0)
	--warn("Do Revert End")
end

def.static("number").Debug = function(lv)
	FPSAdapter.Revert()
	CurLevel = 0
	if lv == 1 then
		DoSth2IncreaseFPS()
	elseif lv == 2 then
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
	elseif lv == 3 then
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
	elseif lv == 4 then
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
		DoSth2IncreaseFPS()
	end
end

FPSAdapter.Commit()
return FPSAdapter