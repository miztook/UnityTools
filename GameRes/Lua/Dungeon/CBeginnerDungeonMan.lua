-- 新手副本管理
-- 2018/9/19

local Lplus = require "Lplus"
local CBeginnerDungeonMan = Lplus.Class("CBeginnerDungeonMan")
local def = CBeginnerDungeonMan.define

local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CPath = require "Path.CPath"

def.field("number")._AnimationEntityID = 0
def.field("userdata")._CameraAnimationPrafab = nil
def.field("number")._CameraAnimationTimerID = 0
def.field("number")._JumpGuideCountdownTimerID = 0

local ENTER_ANIMATION_NAME = "Dn00_bftbirth_go"
local PAUSE_ANIMATION_NAME = "Dn00_bftbirth_pause"
local JUMP_GUIDE_STEP = 70
local GUIDE_COUNT_DOWN = 5
local SLOWDOWN_SPEED = 0.02
local CAMERA_RECOVER_DURATION = 0.1

local GUIDE_CAMERA_TYPE = 2

local instance = nil
def.static("=>", CBeginnerDungeonMan).Instance = function ()
	if instance == nil then
		instance = CBeginnerDungeonMan()
	end
	return instance
end

def.method("number", "string", "number").TriggerBossEnterAnimation = function (self, entityId, aniName, camType)
	local animationEntity = game._CurWorld:FindObject(entityId) 
	if animationEntity == nil then 
		warn("CBeginnerDungeonMan Error:  <TriggerBossEnterAnimation>----> BOSS is nil. EntityId:", entityId)	
		return
	end

	self._AnimationEntityID = entityId
	game._HostPlayer:StopNaviCal()
	CAutoFightMan.Instance():Pause(_G.PauseMask.BossEnterAnim)
	CDungeonAutoMan.Instance():Pause(_G.PauseMask.BossEnterAnim)
	CPath.Instance():PausePathDungeon()
	local function cb(prefab)
		if IsNil(prefab) then
			warn("CBeginnerDungeonMan Error: <TriggerBossEnterAnimation>----> AnimationPrefab is nil")
			return
		end
		animationEntity:AddLoadedCallback(function(nTID)
			game._GUIMan:SetMainUIMoveToHide(true, nil)
			local isJumpGuide = camType == GUIDE_CAMERA_TYPE
			local uiData =
			{
				IsJumpGuide = isJumpGuide,
				BossTitle = animationEntity:GetTitle(),
				BossName = animationEntity._InfoData._Name
			}
			game._GUIMan:Open("CPanelUIBeginnerDungeonBoss", uiData)
			game:SetTopPateVisible(false)

			local pos = animationEntity:GetPos()
			local bossRotaion = animationEntity:GetGameObject().forward
			local temScale = Vector3.one
			if animationEntity:IsMonster() then
				temScale = Vector3.one * animationEntity._MonsterTemplate.BodyScale
			end
			self._CameraAnimationPrafab = Object.Instantiate(prefab)
			self._CameraAnimationPrafab.position = pos
			self._CameraAnimationPrafab.forward = bossRotaion
			self._CameraAnimationPrafab.localScale = temScale

			local aniPrefab = self._CameraAnimationPrafab:GetChild(0)
			local parentObj = aniPrefab:FindChild("CamPos")
			if IsNil(parentObj) then
				--warn("Error:  <BOSSEnterMapAnimation>----> CamPos is nil")
				parentObj = self._CameraAnimationPrafab
			end

			GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.BOSS, parentObj, 0, nil)

			local camAnimation = aniPrefab:GetComponent(ClassType.Animation)
			if isJumpGuide then
				-- 闪身教学
				camAnimation:Play(ENTER_ANIMATION_NAME)
				camAnimation:PlayQueued(PAUSE_ANIMATION_NAME)
			else
				camAnimation:Play()
			end

			if self._CameraAnimationTimerID == 0 then
				local function OnAnimationEnd()
					if isJumpGuide then
						-- 闪身教学
						self:StartJumpGuide()
					else
						if camType == 1 then
							-- 相机立刻回正
							self:FinishCameraAnimation()
						else
							GameUtil.StartBossCamMove(function ()
								self:FinishCameraAnimation()
							end)
						end
					end
				end
				local animationTime = camAnimation.clip.length
				self._CameraAnimationTimerID = _G.AddGlobalTimer(animationTime, true, OnAnimationEnd)
			end
		end)
	end
	local strCamAnimationPath = "Assets/Outputs/CGAnimator/" .. aniName
	GameUtil.AsyncLoad(strCamAnimationPath, cb, false, "cg")
end

def.method().StartJumpGuide = function (self)
	-- 显示闪身技能按钮
	local CPanelUIBeginnerDungeonBoss = require "GUI.CPanelUIBeginnerDungeonBoss"
	CPanelUIBeginnerDungeonBoss.Instance():ShowBtnJump()
	-- 开启闪身教学
	game._CGuideMan:OnServer(JUMP_GUIDE_STEP)
	-- 开启慢镜
	if self._JumpGuideCountdownTimerID == 0 then
		self._JumpGuideCountdownTimerID = _G.AddGlobalTimer(GUIDE_COUNT_DOWN, true, function()
			self:FinishJumpGuide()
		end)
	end
end

def.method().FinishJumpGuide = function (self)
	-- 恢复界面
	game._GUIMan:Close("CPanelUIBeginnerDungeonBoss")
	game:SetTopPateVisible(true)
	game._GUIMan:SetMainUIMoveToHide(false, nil)
	game._CGuideMan:OnServer(JUMP_GUIDE_STEP)
	CPath.Instance():ReStartPathDungeon()
	-- 恢复镜头
	GameUtil.StartBossCamMove(CAMERA_RECOVER_DURATION, function()
		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
		GameUtil.SetCamToDefault(true, true, false, false)
	end)
	-- 关闭慢镜

	-- 现在逻辑是教学中断自动化，包括自动战斗 自动副本 自动任务
	-- 这里不用单独处理

	self:CleanUpAnimation()
end

def.method().PassCameraAnimation = function(self)
	if self._AnimationEntityID > 0 then
		local EType = require "PB.data".EClickFlag 
		local protocol = GetC2SProtocol("C2SClickFlag")
		protocol.flag = EType.EClickFlag_endCameraAnimation
		protocol.entityId = self._AnimationEntityID
		SendProtocol(protocol)
	end
end

-- 普通相机动画
def.method().FinishCameraAnimation = function (self)
	-- 恢复界面
	game._GUIMan:Close("CPanelUIBeginnerDungeonBoss")
	game:SetTopPateVisible(true)
	game._GUIMan:SetMainUIMoveToHide(false, nil)
	-- 恢复镜头
	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
	GameUtil.SetCamToDefault(true, true, false, false)
	-- 重启战斗
	CAutoFightMan.Instance():Restart(_G.PauseMask.BossEnterAnim)
	CDungeonAutoMan.Instance():Restart(_G.PauseMask.BossEnterAnim)
	CPath.Instance():ReStartPathDungeon()

	self:CleanUpAnimation()
end

def.method().CleanUpAnimation = function (self)
	self._AnimationEntityID = 0
	
	if not IsNil(self._CameraAnimationPrafab) then
		self._CameraAnimationPrafab:Destroy()
		self._CameraAnimationPrafab = nil
	end
	if self._CameraAnimationTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._CameraAnimationTimerID)
		self._CameraAnimationTimerID = 0
	end
	if self._JumpGuideCountdownTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._JumpGuideCountdownTimerID)
		self._JumpGuideCountdownTimerID = 0
	end
end

def.method().Cleanup = function (self)
	self:CleanUpAnimation()
end

CBeginnerDungeonMan.Commit()
return CBeginnerDungeonMan