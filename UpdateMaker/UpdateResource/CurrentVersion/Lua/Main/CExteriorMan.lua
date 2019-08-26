-- 外观管理

local Lplus = require "Lplus"
local CExteriorMan = Lplus.Class("CExteriorMan")
local def = CExteriorMan.define

def.field("number")._EnterCamType = 0 -- 打开类型
def.field("boolean")._IsInExterior = false

local EXTERIOR_FUNC_TID = 20 	-- 外观的教学功能Tid
local HORSE_FUNC_TID = 21 		-- 坐骑的教学功能Tid
local WING_FUNC_TID = 23 		-- 翅膀的教学功能Tid

local instance = nil
def.static("=>", CExteriorMan).Instance = function ()
	if instance == nil then
		instance = CExteriorMan()
		instance._IsInExterior = false
	end
	return instance
end

def.static("number", "number").ChangeCamParams = function (camType, horseId)
	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
	local yaw, pitch, distance, height, min_distance = 0, 0, 0, 0, 0
	local hp = game._HostPlayer
	local prof = hp._InfoData._Prof
	if camType == EnumDef.CamExteriorType.Ride then
		if horseId > 0 then
			yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamHorseParams(prof, horseId)
		else
			-- 默认值
			yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamHorseDefaultParams(prof)
		end
	elseif camType == EnumDef.CamExteriorType.Wing then
		yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamWingParams(prof)
	elseif camType == EnumDef.CamExteriorType.Armor then
		yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamDressParams(prof, EnumDef.PlayerDressPart.Body)
	elseif camType == EnumDef.CamExteriorType.Helmet then
		yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamDressParams(prof, EnumDef.PlayerDressPart.Head)
	elseif camType == EnumDef.CamExteriorType.Weapon then
		yaw, pitch, distance, height, min_distance = ModuleProfDiffConfig.GetExteriorCamDressParams(prof, EnumDef.PlayerDressPart.Weapon)
	end
	GameUtil.SetExteriorCamParams(yaw, pitch, distance, height, min_distance)
end

def.method("=>", "boolean").CanEnter = function (self)
	if self._IsInExterior then
		warn("Can not enter, aleady in exterior", debug.traceback())
		return false
	end
	local funcTid = self:GetFuncTid()
	if not game._CFunctionMan:IsUnlockByFunTid(funcTid) then
		-- 功能未解锁
		game._CGuideMan:OnShowTipByFunUnlockConditions(0, funcTid)
		return false
	end
	-- local EWorldType = require "PB.Template".Map.EWorldType
	-- if game._DungeonMan:InDungeon() then
	-- 	-- 副本、角斗场、竞技场中
	-- 	-- game._CurMapType == EWorldType.Pharse then		-- 相位中
	-- 	game._GUIMan:ShowTipText(StringTable.Get(22100), false)
	-- 	return false
	-- end
	local hp = game._HostPlayer
	if hp:IsInServerCombatState() then
		-- 战斗状态
		game._GUIMan:ShowTipText(StringTable.Get(22103), false)
		return false
	end
	if hp:IsDead() then
		-- 死亡
		game._GUIMan:ShowTipText(StringTable.Get(30103), false)
		return false
	end
	if hp:IsInCanNotInterruptSkill() then
		-- 技能中
		game._GUIMan:ShowTipText(StringTable.Get(22103), false)
		return false
	end
	if hp:IsModelChanged() or hp:IsBodyPartChanged() then
		-- 变身中
		game._GUIMan:ShowTipText(StringTable.Get(22104), false)
		return false
	end
	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if game._GUIMan:IsUIForbid(CPanelUIExterior.Instance()) then
		-- 场景限制
		return false
	end
	return true
end

-- 进入外观
-- @param data
--        Type:打开类型(EnumDef.CamExteriorType)
--        UIData:界面数据
def.method("dynamic").Enter = function (self, data)
	if not self:CanEnter() then
		local CGuideMan = require "Guide.CGuideMan"
		local guideConfig = CGuideMan.GetGuideMain()
	    local BigStepConfig = guideConfig[game._CGuideMan._CurGuideID]
	    if BigStepConfig ~= nil then
			local SmallStepConfig = BigStepConfig.Steps[game._CGuideMan._CurGuideStep]
			if SmallStepConfig ~= nil and SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelUIExterior" then
				game._CGuideMan:JumpCurGuide()
			end
		end
	 	return 
	end
	
	local hp = game._HostPlayer
	if hp:IsInCanInterruptSkill() then
		-- 中断特殊技能
		hp._SkillHdl:StopCurActiveSkill(true)
	end

	local CTargetDetector = require "ObjHdl.CTargetDetector"
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	local CPath = require "Path.CPath"
	local CWingsMan = require "Wings.CWingsMan"
	local CDressMan = require "Dress.CDressMan"
	local CQuestAutoGather = require "Quest.CQuestAutoGather"

	-- 关闭目标检测
	CTargetDetector.Instance():Stop()
	-- 停止NPC服务
	hp._OpHdl:EndNPCService(nil)
	-- 停止寻路
	hp:StopNaviCal()
	-- 停止组队跟随
	hp:StopAutoFollow()
	
	-- 停止任务自动化
	CQuestAutoMan.Instance():Pause(_G.PauseMask.UIShown)
	-- 停止副本自动化
	CDungeonAutoMan.Instance():Pause(_G.PauseMask.UIShown)
	-- 停止自动战斗
	CAutoFightMan.Instance():Pause(_G.PauseMask.UIShown)
	-- 停止副本寻路
	CPath.Instance():PausePathDungeon()
	-- 停止自动采集
	CQuestAutoGather.Instance():Stop()
	
	-- 停止休闲状态
	hp:SetPauseIdleState(true)

	self._IsInExterior = true
	self._EnterCamType = EnumDef.CamExteriorType.Ride -- 默认打开坐骑
	local uiData = nil
	if data ~= nil then
		if data.UIData ~= nil then
			uiData = data.UIData
		end
		if type(data.Type) == "number" then
			self._EnterCamType = data.Type
		end
	end
	if self._EnterCamType ~= EnumDef.CamExteriorType.Ride then
		-- 只要不是进入坐骑界面就下马
		hp:UnRide()
	end
	-- 相机参数
	CExteriorMan.ChangeCamParams(self._EnterCamType, hp:GetCurrentHorseId())
	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.EXTERIOR, true, nil, 1, nil)
	self:SetLayersVisible(false)
	-- 预加载数据
	CDressMan.Instance():PreloadAllDress()
	CWingsMan.Instance():PreloadAllWings()

	-- 隐藏主界面
	game._GUIMan:SetMainUIMoveToHide(true, function ()
		game._GUIMan:Open("CPanelUIExterior", uiData)
	end)
end

local function OnQuitComplete()
	local CTargetDetector = require "ObjHdl.CTargetDetector"
	-- 恢复目标检测
	CTargetDetector.Instance():Start()

	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	local CPath = require "Path.CPath"
	CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
	CDungeonAutoMan.Instance():Restart(_G.PauseMask.UIShown)
	CAutoFightMan.Instance():Restart(_G.PauseMask.UIShown)
	CPath.Instance():ReStartPathDungeon()
	-- 开启休闲状态
	game._HostPlayer:SetPauseIdleState(false)
end

def.method().Quit = function (self)
	if not self._IsInExterior then
		-- warn("Quit Exterior failed, not in exterior", debug.traceback())
		return
	end

	self._IsInExterior = false
	self._EnterCamType = 0
	-- 同步外观信息
	local hp = game._HostPlayer
	hp:SyncAllExterior()
	-- 退出外观相机前，立即恢复跟随相机的视心高度
	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
	local heightOffsetMin, heightOffsetMax = ModuleProfDiffConfig.GetFollowCamViewPointHeightOffsetInterval(hp._InfoData._Prof, game._HostPlayer:IsServerMounting())
	GameUtil.SetGameCamHeightOffsetInterval(heightOffsetMin, heightOffsetMax, true)

	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.EXTERIOR, true, nil, 2, function()
		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
	end )
	self:SetLayersVisible(true)

	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if CPanelUIExterior.Instance():IsShow() then
		CPanelUIExterior.Instance():DoQuitTween()
	else
		self:OnQuitTweenComplete()
		warn("CPanelUIExterior did not show when quit Exterior", debug.traceback())
	end

	local CGuideMan = require "Guide.CGuideMan"
	local guideConfig = CGuideMan.GetGuideMain()
    local BigStepConfig = guideConfig[game._CGuideMan._CurGuideID]
    if BigStepConfig ~= nil then
		local SmallStepConfig = BigStepConfig.Steps[game._CGuideMan._CurGuideStep]
		if SmallStepConfig ~= nil and SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelUIExterior" then
			game._CGuideMan:JumpCurGuide()
		end
	end
end

def.method("boolean").SetLayersVisible = function (self, bVisible)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Fx, bVisible)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, bVisible)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, bVisible)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, bVisible)
    game:SetTopPateVisible(bVisible)
end

-- 退出动效完成回调，或者界面未打开时退出外观直接调
def.method().OnQuitTweenComplete = function (self)
	game._GUIMan:Close("CPanelUIExterior")
	game._GUIMan:SetMainUIMoveToHide(false, OnQuitComplete)
end

def.method("=>", "number").GetEnterCamType = function (self)
	return self._EnterCamType
end

def.method("=>", "boolean").GetState = function (self)
	return self._IsInExterior
end

def.method("=>", "number").GetFuncTid = function (self)
	return 20
end

def.method().Reset = function (self)
	self._IsInExterior = false
end

-- 是否显示主界面红点
def.method("=>", "boolean").IsShowRedPoint = function (self)
	local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
	if exteriorMap ~= nil then
		for key, pageMap in pairs(exteriorMap) do
			if (key == "Ride" and game._CFunctionMan:IsUnlockByFunTid(HORSE_FUNC_TID)) or
			   (key == "Wing" and game._CFunctionMan:IsUnlockByFunTid(WING_FUNC_TID)) then
				-- 不检查时装的红点
				for _, status in pairs(pageMap) do
					if status ~= nil then
						return true
					end
				end
			end
		end
	end
	return false
end

CExteriorMan.Commit()
return CExteriorMan