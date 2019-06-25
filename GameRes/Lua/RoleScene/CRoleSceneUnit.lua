-- 角色场景单位

local Lplus = require "Lplus"

local CRoleSceneUnit = Lplus.Class("CRoleSceneUnit")
do
	local def = CRoleSceneUnit.define

	def.field("userdata")._Scene = nil -- 场景物体
	def.field("string")._ScenePath = ""
	def.field("boolean")._IsLoadingScene = false -- 是否正在加载场景
	def.field("boolean")._Is2Destroy = false -- 是否要销毁

	def.method("=>", "boolean").IsLoadingScene = function (self)
		return self._IsLoadingScene
	end

	-- 读取场景
	def.method("string", "function").LoadScene = function (self, path, callback)
		if self._IsLoadingScene then return end

		self._IsLoadingScene = true
		Application.backgroundLoadingPriority = EnumDef.ThreadPriority.High
		GameUtil.AsyncLoad(path, function(mapres)
				Application.backgroundLoadingPriority = EnumDef.ThreadPriority.Normal
				self._IsLoadingScene = false

				if mapres == nil then
					warn("LoadScene failed, map resource got nil, wrong path:" .. path)
					return
				end

				if self._Is2Destroy then return end

				if self:CanInstantiate() then
					StartScreenFade(0, 1, 0.5, function()
						StartScreenFade(1, 0, 1, nil)

						if self._Is2Destroy then return end

						self._ScenePath = path
						self._Scene = Object.Instantiate(mapres)
						if callback ~= nil then
							callback()
						end
					end)
				end
			end)
	end

	def.virtual("=>", "boolean").CanInstantiate = function (self)
		return true
	end

	def.virtual().Destroy = function (self)
		self._Is2Destroy = true
	end

	CRoleSceneUnit.Commit()
end

local CCreateRoleSceneUnit = Lplus.Extend(CRoleSceneUnit, "CCreateRoleSceneUnit")
do
	local OutwardUtil = require "Utility.OutwardUtil"

	local def = CCreateRoleSceneUnit.define

	def.field("table")._SceneGOTable = BlankTable
	def.field("table")._CurNodeGOTable = BlankTable
	def.field("string")._CurBGIdleAniName = ""
	def.field("number")._CameraAnimationTimer = 0
	def.field("number")._CloseBGTimer = 0
	def.field("number")._RandomAnimationTimer = 0 --随机动画timer
	-- 常量
	def.field("table")._ModelPath = BlankTable
	def.field("table")._BGAnimationPath = BlankTable
	def.field("table")._BGIdleAniName = BlankTable
	def.field("string")._LightPath = "Lights/DirectionalLight_Player"
	def.field("string")._CameraPath = "MainAnimator/CameraAnimator/Camera"
	def.field("string")._CloseBGOnPath = "MainAnimator/CameraAnimator/CloseBGon"
	def.field("string")._CloseBGOffPath = "MainAnimator/CameraAnimator/CloseBGoff"

	def.final("=>", CCreateRoleSceneUnit).new = function ()
		local obj = CCreateRoleSceneUnit()
		obj:InitConstTableValue()
		return obj
	end

	def.method().InitConstTableValue = function (self)
		self._BGAnimationPath = 
		{
			"MainAnimator/BGAnimator/BGAnimation_Hum",
			"MainAnimator/BGAnimator/BGAnimation_Ali",
			"MainAnimator/BGAnimator/BGAnimation_cas",
			"",
			"MainAnimator/BGAnimator/BGAnimation_aliL",
		}

		self._ModelPath = 
		{	
			"MainAnimator/Character/CharacterRoot/humwarrior_m_create",
			"MainAnimator/Character/CharacterRoot/alipriest_f_create",
			"MainAnimator/Character/CharacterRoot/casassassin_m_create",
			"MainAnimator/Character/CharacterRoot/sprarcher_f_create",
			"MainAnimator/Character/CharacterRoot/alilancer_f_create",
		}

		self._BGIdleAniName = 
		{
			"idle_BG_Hum",
			"idle_BG_ali",
			"idle_BG_cas",
			"",
			"idle_BG_aliL",
		}
	end

	local function InitSceneInternal(self, node, profId)
		if IsNil(node) then return nil end

		node:SetActive(false)
		local close_bg_on_gameobject = node:FindChild(self._CloseBGOnPath)
		if not IsNil(close_bg_on_gameobject) then
			close_bg_on_gameobject:SetActive(false)
		end
		local close_bg_off_gameobject = node:FindChild(self._CloseBGOffPath)
		if not IsNil(close_bg_off_gameobject) then
			close_bg_off_gameobject:SetActive(false)
		end
		local goTable = 
		{
			_Root = node,
			_CameraAnimation = node:GetChild(0),
			_Model= node:FindChild(self._ModelPath[profId]),
			_StopBGAnimation = node:FindChild(self._BGAnimationPath[profId]),
			_PlayerLight = node:FindChild(self._LightPath),
			_CloseBGOn = close_bg_on_gameobject,
			_CloseBGOff = close_bg_off_gameobject,
		}

		--fix
		do --not _G.IsUseRealTimeShadowInLogin() then
			local obj = goTable._PlayerLight
			if obj ~= nil then
				GameUtil.EnableLightShadow(obj, false)
			end
		end
		do 
			local obj = goTable._Root:FindChild(self._CameraPath)
			if obj ~= nil then

				GameUtil.FixCameraSetting(obj)

				local enable = _G.IsUseBloomHDInLogin()
				GameUtil.EnableBloomHD(obj, enable)

				local cam = obj:GetComponent(ClassType.Camera)
				if cam ~= nil then
				 	cam.useOcclusionCulling = false
				end
			end
		end
		return goTable
	end

	-- 初始化大场景
	def.method().InitBigScene = function (self)
		local scene = self._Scene
		if IsNil(scene) then return end
		
		self._SceneGOTable = {}
		for i = 1, GlobalDefinition.ProfessionCount do
			local child = scene:GetChild(i-1)
			self._SceneGOTable[i] = InitSceneInternal(self, child, i)
		end
	end

	-- 初始化单个职业场景
	def.method("number").InitSingleScene = function (self, profId)
		local scene = self._Scene
		if IsNil(scene) then return end
		
		local child = scene:GetChild(0)
		self._CurNodeGOTable = InitSceneInternal(self, child, profId)
	end

	-- 设置当前职业节点的物体表
	def.method("number").ChangeCurNode = function (self, profId)
		if profId <= 0 then return end

		self._CurNodeGOTable = self._SceneGOTable[profId]
		self._CurBGIdleAniName = self._BGIdleAniName[profId]
	end

	-- 隐藏职业的根节点
	def.method("number").HideProfessionRoot = function (self, profId)
		local sceneTable = self._SceneGOTable[profId]
		if sceneTable == nil then return end

		sceneTable._Root:SetActive(false)
	end

	-- 初始化职业节点
	def.method().InitProfessionNode = function (self)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		GameUtil.SetSceneEffect(sceneTable._Root)
		sceneTable._Model.localRotation = Quaternion.identity
	end

	-- 重置模型旋转
	def.method("boolean").ResetModelRotate = function (self, isImmediately)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		if isImmediately then
			sceneTable._Model.localRotation = Quaternion.identity
		else
			GameUtil.DoLocalRotateQuaternion(sceneTable._Model, Quaternion.Euler(0, 0, 0), 1, EnumDef.Ease.Linear, nil)
		end
	end

	-- 设置模型是否能旋转
	def.method("boolean").EnableModelRotate = function (self, enable)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		GameUtil.EnableRotate(sceneTable._Model, enable)
	end

	-- 开启模型休闲动作
	def.method().StartModelIdle = function (self)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		if self._RandomAnimationTimer ~= 0 then
			_G.RemoveGlobalTimer(self._RandomAnimationTimer)
			self._RandomAnimationTimer = 0
		end
		local standAnimation = sceneTable._Model:GetComponent(ClassType.Animation)		
		if standAnimation == nil then return end
		standAnimation:Play("create_stand")
		local nStandTime = standAnimation:GetClip("create_stand").length
		local nIdleTime = standAnimation:GetClip("create_idle1").length
		local function callback()
			if IsNil(standAnimation) then return end

			standAnimation:Play("create_idle1")
			--UnityUtil.PlayAnimation(sceneTable._Model, "create_idle1", 1)	
			--standAnimation:PlayQueued("create_stand")
			
			local function cb()
				if IsNil(standAnimation) then return end
				standAnimation:Play("create_stand")
				self._RandomAnimationTimer = _G.AddGlobalTimer(2*nStandTime, true, callback)
			end
			self._RandomAnimationTimer = _G.AddGlobalTimer(nIdleTime, true, cb)
		end

		self._RandomAnimationTimer = _G.AddGlobalTimer(nStandTime, true, callback)
	end

	-- 更换脸型
	def.method("number", "number", "number").ChangeFace = function (self, profId, index, skinColroId)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local model = sceneTable._Model
		OutwardUtil.ChangeFaceWhenCreate(model, profId, index, function()
			-- 设置肤色
			OutwardUtil.ChangeSkinColor(model, profId, skinColroId)
		end)
	end

	-- 更换发型
	def.method("number", "number", "number").ChangeHair = function (self, profId, index, hairColroId)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local model = sceneTable._Model
		OutwardUtil.ChangeHairWhenCreate(model, profId, index, function()
			-- 设置发色
			OutwardUtil.ChangeHairColor(model, profId, hairColroId)
		end)
	end

	-- 更换肤色
	def.method("number", "number").ChangeSkinColor = function (self, profId, index)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local model = sceneTable._Model
		OutwardUtil.ChangeSkinColor(model, profId, index)
	end

	-- 更换发色
	def.method("number", "number").ChangeHairColor = function (self, profId, index)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local model = sceneTable._Model
		OutwardUtil.ChangeHairColor(model, profId, index)
	end


	-- 镜头移动
	def.method("string", "number").DoCameraMove = function (self, camAniName, speed)
		if IsNilOrEmptyString(camAniName) then return end
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end
		local camAni = sceneTable._CameraAnimation:GetComponent(ClassType.Animation)
		if camAni == nil then return end

		UnityUtil.PlayAnimation(sceneTable._CameraAnimation, camAniName, speed)
		local cameraTime = camAni:GetClip(camAniName).length
		if cameraTime > 0 then
			if self._CameraAnimationTimer ~= 0 then
				_G.RemoveGlobalTimer(self._CameraAnimationTimer)
				self._CameraAnimationTimer = 0
			end
			self._CameraAnimationTimer = _G.AddGlobalTimer(cameraTime, true, function()
				GameUtil.EnableBlockCanvas(false)
			end)
			GameUtil.EnableBlockCanvas(true) -- 阻挡UI点击
		end
	end

	-- 检查背景板的显示
	def.method("boolean").EnableCloseBG = function (self, enable)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end
		local close_bg_on_gameobject = sceneTable._CloseBGOn
		if enable then
			if not IsNil(close_bg_on_gameobject) then
				close_bg_on_gameobject:SetActive(true)
			end
		else
			if not IsNil(close_bg_on_gameobject) then
				close_bg_on_gameobject:SetActive(false)
			end
			local close_bg_off_gameobject = sceneTable._CloseBGOff
			if not IsNil(close_bg_off_gameobject) then
				close_bg_off_gameobject:SetActive(true)
			end
			if self._CloseBGTimer ~= 0 then
				_G.RemoveGlobalTimer(self._CloseBGTimer)
				self._CloseBGTimer = 0
			end
			-- 延迟1s打开
			self._CloseBGTimer = _G.AddGlobalTimer(1, true, function ()
				if not IsNil(close_bg_off_gameobject) then
					close_bg_off_gameobject:SetActive(false)
				end
			end)
		end
	end

	-- 重置职业镜头
	def.method().ResetCamera = function (self)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local cameraAnimation = sceneTable._CameraAnimation
		if not IsNil(cameraAnimation) then
			UnityUtil.PlayAnimation(cameraAnimation, "camerastay", 1)
		end
	end

	def.method().ResetProfessionBG = function (self)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end
		
		local stopBGAnimation = sceneTable._StopBGAnimation
		if not IsNil(stopBGAnimation) then
			UnityUtil.PlayAnimation(stopBGAnimation, self._CurBGIdleAniName, 1)
		end
	end

	def.method().ResetCloseBG = function (self)
		local sceneTable = self._CurNodeGOTable
		if sceneTable == nil then return end

		local close_bg_on_gameobject = sceneTable._CloseBGOn
		if not IsNil(close_bg_on_gameobject) then
			close_bg_on_gameobject:SetActive(false)
		end
	end

	def.override().Destroy = function(self)
		CRoleSceneUnit.Destroy(self)
		if self._RandomAnimationTimer ~= 0 then
			_G.RemoveGlobalTimer(self._RandomAnimationTimer)
			self._RandomAnimationTimer = 0
		end
		if self._CameraAnimationTimer ~= 0 then
			_G.RemoveGlobalTimer(self._CameraAnimationTimer)
			self._CameraAnimationTimer = 0
		end
		if self._CloseBGTimer ~= 0 then
			_G.RemoveGlobalTimer(self._CloseBGTimer)
			self._CloseBGTimer = 0
		end
		self._SceneGOTable = {}
		self._CurNodeGOTable = {}

		if not IsNil(self._Scene) then
			Object.Destroy(self._Scene)
			self._Scene = nil
		end

		if not IsNilOrEmptyString(self._ScenePath) then
			GameUtil.UnloadBundle("scenes")
			GameUtil.UnloadBundleOfAsset(self._ScenePath)
		end
		self._ScenePath = ""
	end

	CCreateRoleSceneUnit.Commit()
end

local CSelectRoleSceneUnit = Lplus.Extend(CRoleSceneUnit, "CSelectRoleSceneUnit")
do
	local def = CSelectRoleSceneUnit.define

	def.field("userdata")._AnimationClip = nil -- 角色切换的镜头动画
	def.field("table")._TablePlayerModel = BlankTable -- 角色模型
	def.field("table")._TableModelPos = BlankTable -- 模型位置节点
	-- 常量
	def.field("string")._ModelPosPathPrefix = "SelectChar_animator/SelectChar_CharPos" -- 模型放置位置路径前缀
	def.field("string")._SceneAnimationPath = "SelectChar_animator" -- 场景动画物体路径
	def.field("string")._SceneLightPath = "Background/DirectionalLight_Player" -- 场景灯光物体路径
	def.field("string")._SceneCameraPath = "SelectChar_animator/SelectChar_CharCamera/Main Camera/CharacterCamera" -- 场景相机物体路径
	def.field("string")._SceneSmokePath = "Background/scene_selectcharacter_smoke" -- 场景烟雾物体路径
	def.field("string")._CameraLoopAnimationFormat = "SlctChar_char%dloop" -- 相机循环动画名字格式
	def.field("string")._CameraChangeAnimationFormat = "SlctChar_char%dto%d" -- 相机改变动画名字格式

	--[[
	local SMOKE1 = "Background/scene_selectcharacter_smoke/smoke03 (1)"
	local SMOKE2 = "Background/scene_selectcharacter_smoke/huijin"
	local SMOKE3 = "Background/scene_selectcharacter_smoke/huoxing"
	local SMOKE4 = "Background/scene_selectcharacter_smoke/glow"
	local SMOKE5 = "Background/scene_selectcharacter_smoke/line"
	local SMOKE6 = "Background/scene_selectcharacter_smoke/nongdu"
	local SMOKE7 = "Background/scene_selectcharacter_smoke/smoke01"
	local SMOKE8 = "Background/scene_selectcharacter_smoke/smoke04_01"
	]]

	def.final("=>", CSelectRoleSceneUnit).new = function ()
		local obj = CSelectRoleSceneUnit()
		return obj
	end

	def.override("=>", "boolean").CanInstantiate = function (self)
		return game._AccountInfo ~= nil
	end

	def.method().InitScene = function (self)
		local scene = self._Scene
		if IsNil(scene) then return end

		GameUtil.SetSceneEffect(scene)
		for i = 1, GlobalDefinition.MaxRoleCount do
			self._TableModelPos[i] = scene:FindChild(self._ModelPosPathPrefix..i)
		end
		self._AnimationClip = scene:FindChild(self._SceneAnimationPath):GetComponent(ClassType.Animation)

		--fix
		do
			local obj = scene:FindChild(self._SceneLightPath)
			if not IsNil(obj) then
				local enable = _G.IsUseRealTimeShadowInLogin()
				GameUtil.EnableLightShadow(obj, enable)
			end
		end
		do
			local obj = scene:FindChild(self._SceneCameraPath)
			if not IsNil(obj) then
				GameUtil.FixCameraSetting(obj)

				local enable = _G.IsUseBloomHDInLogin()
				GameUtil.EnableBloomHD(obj, enable)

				local cam = obj:GetComponent(ClassType.Camera)
				if cam ~= nil then
				 	cam.useOcclusionCulling = false
				end
			end
		end

		--屏蔽smoke
		do 
			local obj = scene:FindChild(self._SceneSmokePath)
			if obj ~= nil then obj:SetActive(false) end
		end
	end

	local function GetWalkAniSpeed(prof)
		local speed = 1
		if prof == EnumDef.Profession.Warrior then
			speed = 0.692
		elseif prof == EnumDef.Profession.Aileen then
			speed = 0.6
		elseif prof == EnumDef.Profession.Assassin then
			speed = 0.55
		elseif prof == EnumDef.Profession.Archer then
			speed = 0.57
		elseif prof == EnumDef.Profession.Lancer then
			speed = 0.6
		end
		return speed
	end

	def.method("number").LoadPlayerModel = function (self, roleIndex)
		if roleIndex <= 0 then return end
		if self._TablePlayerModel[roleIndex] ~= nil then return end

		local roleData = game._AccountInfo._RoleList[roleIndex]
		if roleData == nil then return end

		local Util = require "Utility.Util"
		local profId = roleData.Profession
		local modelAssetPath = Util.GetPlayerBaseModelAssetPath(profId, Profession2Gender[profId])
		if IsNilOrEmptyString(modelAssetPath) then
			error("LoadPlayerModel failed, modelAssetPath got nil, wrong profId:", profId)
			return
		end

		local CModel = require "Object.CModel"
		local playerModel = CModel.new()
		local function OnLoad()
			if playerModel == nil then return end
			local go = playerModel:GetGameObject()
			if IsNil(go) then return end
			if roleData == nil then return end

			-- 设置物体
			if not IsNil(self._TableModelPos[roleIndex]) then
				go:SetParent(self._TableModelPos[roleIndex])
			end
			go.localPosition = Vector3.zero
			go.localScale = Vector3.zero -- 暂时先隐藏，等整体加载完毕再显示
			go.localRotation = Quaternion.identity
			-- 设置动画
			local nSpeed = GetWalkAniSpeed(roleData.Profession)
			if playerModel:HasAnimation(EnumDef.CLIP.COMMON_WALK) then
				playerModel:PlayAnimation(EnumDef.CLIP.COMMON_WALK, 0, false, 0, nSpeed)
			else
				playerModel:PlayAnimation(EnumDef.CLIP.COMMON_RUN, 0, false, 0, nSpeed)
			end

			local ModelParams = require "Object.ModelParams"
			local param = ModelParams.new()
			param:MakeParam(roleData.Exterior, roleData.Profession)
			-- param._IsChangeWing = false -- 不显示翅膀

			playerModel._Params = ModelParams.new()
			playerModel._Params._Prof = roleData.Profession
			playerModel:UpdateWithModelParams(param, function()
				if not IsNil(go) then
					go.localScale = Vector3.one
					GameUtil.SetLayerRecursively(go, EnumDef.RenderLayer.Player)
				end

				local wingModel = playerModel:GetAttach("WingHP")
				if wingModel ~= nil then
					wingModel:PlayAnimation(EnumDef.CLIP.WING_COMMON_STAND, 0, false, 0, 1) -- 翅膀通用站立动作
					GameUtil.EnableLockWingYZRotation(true, wingModel:GetGameObject(), go) -- 锁定翅膀YZ轴旋转
				end
			end)
		end

		playerModel:Load(modelAssetPath, function(ret)
			if ret then
				OnLoad()
			else
				warn("LoadPlayerModel failed to load model, path:", modelAssetPath)
			end
		end)
		self._TablePlayerModel[roleIndex] = playerModel
	end

	def.method().DestroyAllModels = function(self)
		for i, v in pairs(self._TablePlayerModel) do
			local wingModel = v:GetAttach("WingHP")
			if wingModel ~= nil then
				GameUtil.EnableLockWingYZRotation(false, wingModel:GetGameObject(), nil) -- 解锁翅膀YZ轴旋转
			end
			v:Destroy()
		end
		self._TablePlayerModel = {}
	end

	def.method("number", "number").MoveCamera = function (self, from, to)
		if IsNil(self._AnimationClip) then return end

		local camChangeAniName = string.format(self._CameraChangeAnimationFormat, from, to)
		self._AnimationClip:Play(camChangeAniName, PlayMode.StopSameLayer) 
	end

	def.method("number").ResetCamera = function (self, index)
		if IsNil(self._AnimationClip) then return end
		
		local camLoopAniName = string.format(self._CameraLoopAnimationFormat, index)
		self._AnimationClip:Play(camLoopAniName, PlayMode.StopSameLayer)
	end

	def.override().Destroy = function(self)
		CRoleSceneUnit.Destroy(self)
		self:DestroyAllModels()
		self._AnimationClip = nil
		self._TableModelPos = {}

		if not IsNil(self._Scene) then
			Object.Destroy(self._Scene)
			self._Scene = nil
		end

		if not IsNilOrEmptyString(self._ScenePath) then
			GameUtil.UnloadBundle("scenes")
			GameUtil.UnloadBundleOfAsset(self._ScenePath)
		end
		self._ScenePath = ""
	end

	CSelectRoleSceneUnit.Commit()
end

return
{
	CCreateRoleSceneUnit = CCreateRoleSceneUnit,
	CSelectRoleSceneUnit = CSelectRoleSceneUnit,
}