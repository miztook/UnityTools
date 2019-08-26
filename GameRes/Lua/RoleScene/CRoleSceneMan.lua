-- 创建/选择角色场景管理器

local Lplus = require "Lplus"
local CRoleSceneMan = Lplus.Class("CRoleSceneMan")
local def = CRoleSceneMan.define

local CCreateRoleSceneUnit = require "RoleScene.CRoleSceneUnit".CCreateRoleSceneUnit
local CSelectRoleSceneUnit = require "RoleScene.CRoleSceneUnit".CSelectRoleSceneUnit

def.field(CCreateRoleSceneUnit)._CreateRoleScene = nil
def.field(CSelectRoleSceneUnit)._SelectRoleScene = nil
-- 创建角色相关
def.field("number")._CurProfId = 0
def.field("number")._CameraType = 0 -- 当前相机类型
def.field("boolean")._IsSkipCG = false
def.field("number")._AutoReturnLoginTimer = 0
def.field("boolean")._Is2ReturnLogin = false
-- cfg
def.field("table")._BGMPathCfg = nil
def.field("table")._SkillAudioPathCfg = nil
-- 开关
def.field("boolean")._IsSplitProfScene = true -- 是否拆分职业场景

def.static("=>", CRoleSceneMan).new = function ()
	local obj = CRoleSceneMan()
	return obj
end

-- 初始化静态数据
def.method().Init = function (self)
	self._BGMPathCfg = 
	{
		"Lobby_Character/Character/Warrior", --PATH.BGM_Warrior_Theme, 
		"Lobby_Character/Character/Priest", --PATH.BGM_Priest_Theme, 
		"Lobby_Character/Character/Assassin", --PATH.BGM_Assassin_Theme,
		"Lobby_Character/Character/Archer", --PATH.BGM_Archer_Theme,
		"Lobby_Character/Character/Lancer", --PATH.BGM_Lancer_Theme,
	}

	self._SkillAudioPathCfg =
	{
		"lobby_character_warrior", --PATH.Skill_Warrior_Lobby,
		"lobby_character_priest", --PATH.Skill_Priest_Lobby,
		"lobby_character_assassin", --PATH.Skill_Assassin_Lobby,
		"lobby_character_archer", --PATH.Skill_Archer_Lobby,
		"lobby_character_lancer", --PATH.Skill_Lancer_Lobby,
	}
end

------------------------------ 创建角色相关 start -----------------------------
-- 进入创建角色
def.method().EnterRoleCreateStage = function (self)
	self:Cleanup()
	self._CurProfId = 0

	-- 初始化敏感字
	local FilterMgr = require "Utility.BadWordsFilter".Filter
	FilterMgr.Init()

	local randomList = {}
    local options = GameConfig.Get("FuncOpenOption")
	for _, prof in pairs(EnumDef.Profession) do
		if prof ~= EnumDef.Profession.Lancer or not options.HideLancer then
			table.insert(randomList, prof)
		end
	end
	local profession = randomList[math.random(1, #randomList)]
	self._CreateRoleScene = CCreateRoleSceneUnit.new()
	local path = nil
	if self._IsSplitProfScene then
		path = string.format("Assets/Outputs/Scenes/CreatCharacter_%d.prefab", profession)
	else
		path = PATH.CreateRoleScene
	end
	self._CreateRoleScene:LoadScene(path, function()
		if self._IsSplitProfScene then
			self._CreateRoleScene:InitSingleScene(profession)
		else
			self._CreateRoleScene:InitBigScene()
		end

		game._GUIMan:Close("CPanelServerSelect")
		game._GUIMan:Close("CPanelUIServerQueue")
		game._GUIMan:Close("CPanelLogin")
		game._GUIMan:CloseCircle()
		game._GUIMan:Open("CPanelCreateRole", profession)

		local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
		CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Start_Create_Role)
	end)

	game._CurGameStage = _G.GameStage.CreateRoleStage
end

def.method("=>", "number").GetCurProfId = function (self)
	return self._CurProfId
end

-- 切换创建职业
-- @param profId:选择的职业 callback:CG播放结束后回调
def.method("number", "function").SelectProfession = function (self, profId, callback)
	if self._CreateRoleScene ~= nil then
		if self._CreateRoleScene:IsLoadingScene() then
			warn("Why SelectProfession when scene loading, current profId:", self._CurProfId, debug.traceback())
			return
		end
		if self._IsSplitProfScene then
			-- 删除旧场景
			self._CreateRoleScene:Destroy()
			self._CreateRoleScene = nil
		end
	end

	local originProfId = self._CurProfId
	self._CurProfId = profId
	if self._IsSplitProfScene then
		-- 需要单独加载各个职业的场景
		self._CreateRoleScene = CCreateRoleSceneUnit.new()
		local path = string.format("Assets/Outputs/Scenes/CreatCharacter_%d.prefab", profId)
		GameUtil.EnableBlockCanvas(true)
		self._CreateRoleScene:LoadScene(path, function()
			GameUtil.EnableBlockCanvas(false)
			self._CreateRoleScene:InitSingleScene(profId) -- 初始化
			self:StartRoleCreateScene(profId, callback)
		end)
	else
		if self._CreateRoleScene ~= nil then
			-- 修改当前节点的设置
			self._CreateRoleScene:HideProfessionRoot(originProfId)
			self._CreateRoleScene:ChangeCurNode(profId)
		end
		self:StartRoleCreateScene(profId, callback)
	end
end

def.method("number", "function").StartRoleCreateScene = function (self, profId, callback)
	if self._CreateRoleScene == nil then return end

	self._CameraType = EnumDef.ECreateRoleCamType.Job
	self._CreateRoleScene:InitProfessionNode()
	self._CreateRoleScene:EnableModelRotate(false)
	-- CG
	self._IsSkipCG = false
	CGMan.StopCG()
	local function OnCGFinish()
		if self._CreateRoleScene == nil then return end
		if self._IsSkipCG then return end

		-- CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.CreateRole, false)
		self._CreateRoleScene:EnableModelRotate(true)
		if callback ~= nil then
			callback()
		end
	end

	local cgPath = ""
	if self._IsSplitProfScene then
		cgPath = string.format("Assets/Outputs/CG/CreatCharacter_%d/Creat_Job%d_show.prefab", profId, profId)
	else
		cgPath = string.format("Assets/Outputs/CG/CreatCharacter/Creat_Job%d_show.prefab", profId)
	end
	CGMan.PlayCG(cgPath, OnCGFinish, 0, true)
	--播放角色主题音乐
	-- CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.CreateRole, true)
	CSoundMan.Instance():PlayBackgroundMusic(self._BGMPathCfg[profId], 0)
	CSoundMan.Instance():Play2DAudio(self._SkillAudioPathCfg[profId], 0)

end

-- 跳过职业展示CG
def.method().SkipCG = function (self)
	if self._CreateRoleScene == nil then return end
	
	--CG
	self._IsSkipCG = true
	CGMan.StopCG()

	self._CreateRoleScene:EnableModelRotate(true)
	self._CreateRoleScene:ResetProfessionBG()
	self._CreateRoleScene:ResetCamera()
	--停止技能音乐
	CSoundMan.Instance():Stop2DAudio(self._SkillAudioPathCfg[self._CurProfId], "")
	-- CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.CreateRole, false)
end

local function SetCreateCamera(self, curCamType, destCamType)
	if self._CreateRoleScene == nil then return end

	local function GetCamAniAndSpeed(curCamType, destCamType)
		local aniName = ""
		local speed = 0
		if curCamType ~= destCamType then
			local temp = curCamType * destCamType
			if temp == EnumDef.ECreateRoleCamType.Body * EnumDef.ECreateRoleCamType.Halfbody then
				aniName = "cameratostand"
				if curCamType < destCamType then
					-- 动画正向播放
					speed = 1
				else
					-- 反向
					speed = -1
				end
			elseif temp == EnumDef.ECreateRoleCamType.Face * EnumDef.ECreateRoleCamType.Halfbody then
				aniName = "cameratoface"
				if curCamType < destCamType then
					-- 动画反向播放
					speed = -1
				else
					-- 正向
					speed = 1
				end
			elseif temp == EnumDef.ECreateRoleCamType.Face * EnumDef.ECreateRoleCamType.Body then
				aniName = "camerafaceback"
				if curCamType < destCamType then
					-- 动画正向播放
					speed = 1
				else
					-- 反向
					speed = -1
				end
			elseif temp == EnumDef.ECreateRoleCamType.Job * EnumDef.ECreateRoleCamType.Halfbody then
				aniName = "cameragoclose"
				if curCamType < destCamType then
					-- 动画反向播放
					speed = -1
				else
					-- 正向
					speed = 1
				end
			elseif temp == EnumDef.ECreateRoleCamType.Face * EnumDef.ECreateRoleCamType.Job then
				aniName = "cameragoface"
				if curCamType < destCamType then
					-- 动画反向播放
					speed = -1
				else
					-- 正向
					speed = 1
				end
			end
		end
		return aniName, speed
	end

	local camAniName, speed = GetCamAniAndSpeed(curCamType, destCamType)
	self._CreateRoleScene:DoCameraMove(camAniName, speed)
	if curCamType == EnumDef.ECreateRoleCamType.Job or destCamType == EnumDef.ECreateRoleCamType.Job then
		self._CreateRoleScene:EnableCloseBG(curCamType == EnumDef.ECreateRoleCamType.Job)
	end
end

-- 聚焦模型
def.method().FocusModel = function (self)
	if self._CreateRoleScene == nil then return end

	self._CreateRoleScene:ResetModelRotate(false)
	-- 相机
	local curCamType = self._CameraType
	local destCamType = EnumDef.ECreateRoleCamType.Halfbody
	self._CameraType = destCamType
	SetCreateCamera(self, curCamType, destCamType)
end

-- 切换创建模型外观
def.method("boolean", "boolean", "number", "number").ChangeModelExterior = function (self, isColor, isHair, colorId, id)
	if self._CreateRoleScene == nil then return end

	if isColor then
		if isHair then
			-- 换发色
			self._CreateRoleScene:ChangeHairColor(self._CurProfId, colorId)
		else
			-- 换肤色
			self._CreateRoleScene:ChangeSkinColor(self._CurProfId, colorId)
		end
	else
		if isHair then
			-- 换发型
			self._CreateRoleScene:ChangeHair(self._CurProfId, id, colorId)
		else
			-- 换脸型
			self._CreateRoleScene:ChangeFace(self._CurProfId, id, colorId)
		end
	end
end

-- 切换创建角色的镜头位置
def.method("number").ChangeCreateCamera = function (self, destCamType)
	if self._CreateRoleScene == nil then return end
	if self._CameraType == destCamType then return end

	local curCamType = self._CameraType
	self._CameraType = destCamType
	SetCreateCamera(self, curCamType, destCamType)
end

-- 重置创建角色场景
def.method().ResetRoleCreateScene = function (self)
	if self._CreateRoleScene == nil then return end
	
	self._CreateRoleScene:ResetModelRotate(false)
	-- 还原外观
	self._CreateRoleScene:ChangeHair(self._CurProfId, 1, 1)
	self._CreateRoleScene:ChangeFace(self._CurProfId, 1, 1)
	-- 相机
	if self._CameraType == EnumDef.ECreateRoleCamType.Body then
		-- GameUtil.EnableBlockCanvas(true)
		StartScreenFade(0, 1, 0.1, function ()
			StartScreenFade(1, 0, 0.1, nil)
			self._CreateRoleScene:ResetCamera()
			self._CreateRoleScene:ResetCloseBG()
			-- GameUtil.EnableBlockCanvas(false)
		end)
	else
		SetCreateCamera(self, self._CameraType, EnumDef.ECreateRoleCamType.Job)
	end
	self._CameraType = EnumDef.ECreateRoleCamType.Job
end

def.method("string", "number", "number", "number", "number").SendC2SRoleCreate = function (self, name, faceId, hairId, skinColroId, hairColroId)
	local protocol = GetC2SProtocol("C2SRoleCreate")
	protocol.Name = name
	protocol.Profession = self._CurProfId
	protocol.Gender = Profession2Gender[self._CurProfId]
	protocol.Face.FacialId = faceId
	protocol.Face.HairstyleId = hairId
	protocol.Face.SkinColorId = skinColroId
	protocol.Face.HairColorId = hairColroId
	SendProtocol(protocol)
	-- 平台SDK打点
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Create_Role)
end

------------------------------ 创建角色相关 end -----------------------------

------------------------------ 选择角色相关 start -----------------------------
def.method("number").EnterRoleSelectStage = function (self, roleIndex)
	if game._AccountInfo == nil then
		warn("EnterRoleSelectStage failed, account info got nil", debug.traceback())
		return
	end

	local length = #game._AccountInfo._RoleList
	if length > 0 then
		self:Cleanup()

		self._SelectRoleScene = CSelectRoleSceneUnit.new()
		self._SelectRoleScene:LoadScene(PATH.LoginSceneNew, function()
			self._SelectRoleScene:InitScene()

			game._GUIMan:Close("CPanelServerSelect")
			game._GUIMan:Close("CPanelUIServerQueue")
			game._GUIMan:Close("CPanelLogin")
			game._GUIMan:CloseCircle()
			game._GUIMan:Open("CPanelSelectRole", roleIndex)
		end)
		self:AddAutoReturnLoginTimer()
		game._CurGameStage = _G.GameStage.SelectRoleStage
	else
		self:EnterRoleCreateStage()
	end
end

-- 切换角色
def.method("number", "number").ChangeRole = function (self, originIndex, roleIndex)
	if self._SelectRoleScene == nil then return end

	self._SelectRoleScene:LoadPlayerModel(roleIndex)
	if originIndex > 0 then
		self._SelectRoleScene:MoveCamera(originIndex, roleIndex)
	end
end

-- 重置选择角色场景
def.method("number").ResetRoleSelectScene = function (self, roleIndex)
	if self._SelectRoleScene == nil then return end
	
	self._SelectRoleScene:DestroyAllModels()
	self._SelectRoleScene:ResetCamera(roleIndex)
end

def.method().RemoveAutoReturnLoginTimer = function(self)
	if self._AutoReturnLoginTimer ~= 0 then
		_G.RemoveGlobalTimer(self._AutoReturnLoginTimer)
		self._AutoReturnLoginTimer = 0
	end
end

def.method().AddAutoReturnLoginTimer = function(self)
	self:RemoveAutoReturnLoginTimer()
	local autoReturnLoginTime = 900 -- 自动返回登录时间，15分钟
	self._AutoReturnLoginTimer = _G.AddGlobalTimer(autoReturnLoginTime, true, function()
		-- 闲置超时，返回登录界面
		game._GUIMan:Close("CPanelSelectRole")
		game:LogoutAccount()
		self._Is2ReturnLogin = true
	end)
end
------------------------------ 选择角色相关 end -----------------------------

def.method().Cleanup = function(self)
	self:RemoveAutoReturnLoginTimer()
	self._Is2ReturnLogin = false

	-- CPanelCreateRole/CPanelSelectRole 必须和下面的 _CreateRoleScene / _CreateRoleScene 配对销毁
	-- 否则，界面中动态加载的角色模型就不会走正常的缓冲逻辑
	game._GUIMan:Close("CPanelCreateRole")
	game._GUIMan:Close("CPanelSelectRole")

	if self._CreateRoleScene ~= nil then
		self._CreateRoleScene:Destroy()
		self._CreateRoleScene = nil

		CGMan.StopCG()
		CSoundMan.Instance():StopBackgroundMusic()
	end
	if self._SelectRoleScene ~= nil then
		self._SelectRoleScene:Destroy()
		self._SelectRoleScene = nil
	end
end

CRoleSceneMan.Commit()
return CRoleSceneMan