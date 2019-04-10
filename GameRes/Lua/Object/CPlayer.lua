local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local CGame = Lplus.ForwardDeclare("CGame")
local CModel = require "Object.CModel"
local CElementData = require "Data.CElementData"
local CGuild = require "Guild.CGuild"
local EquipChangeCompleteEvent = require "Events.EquipChangeCompleteEvent"
local CElementSkill = require "Data.CElementSkill"
local OutwardUtil = require "Utility.OutwardUtil"
local EPkMode = require "PB.data".EPkMode
local CWingsMan = require "Wings.CWingsMan" 
local ECustomSet = require "PB.data".ECustomSet
local PBHelper = require "Network.PBHelper"
local Util = require "Utility.Util"
--local CEquipCell = require "Package.CEquipCell" 		--强化的格子信息
local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
local EDressType = require "PB.Template".Dress.eDressType
local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
local CDress = require "Dress.CDress"
local ModelParams = require "Object.ModelParams"
local CFxObject = require "Fx.CFxObject"

local CPlayer = Lplus.Extend(CEntity, "CPlayer")
local def = CPlayer.define

def.field("table")._ProfessionTemplate = nil
def.field("table")._Equipments = nil
def.field("table")._WingData = nil
def.field("function")._AllModelReadyCallback = nil
def.field("boolean")._IsModelHidden = false
def.field("number")._TeamId = 0
def.field(CGuild)._Guild = nil
def.field("userdata")._CombatStateChangeComp = nil
def.field("number")._CombatStateClearTimerId = 0
def.field("boolean")._IgnoreClientStateChange = false
def.field("number")._WeaponPosChangeTimerID = 0
def.field("number")._WeaponScaleChangeTimerID = 0
def.field("table")._CharmFiled = BlankTable 	--神符槽列表
def.field("boolean")._EnableDress = true 		--是否显示时装
def.field("table")._DressInfos = BlankTable		--时装信息表
def.field("boolean")._IsRedName = false 		--是否紫名
def.field(CModel)._MountModel = nil             --坐骑
def.field(CModel)._WingModel = nil              --翅膀
def.field("userdata")._HorseStandBehaviourComp = nil -- 坐骑站立行为控制组件
def.field("number")._MountTid = 0               --骑乘:>0  无骑乘:<=0,  表现
def.field("string")._MountBornMusic = ""
def.field("number")._MountBornAniTimer = 0 		--坐骑出生动画计时器
def.field("boolean")._IsMountingHorse = false   --服务器状态
def.field("boolean")._IsMountEnterSight = false --标志位，进入视野骑马，不能播特效
def.field("boolean")._IsAllowChangeHorse = true --是否允许更改坐骑模型 表现
def.field("boolean")._IsChangePose = false  --是否在战斗姿态
def.field("table")._ChangePoseDate = nil 		-- 姿态动作相关
def.field("table")._CurPartialShapes = nil
--def.field("table")._EquipCellInfo = BlankTable 	--装备位信息存储
def.field(ModelParams)._OutwardParams = nil 	--模型参数
def.field("number")._PetId = 0					--当前出站宠物ID
def.field(CFxObject)._LvUpFx = nil				--升级特效
def.field(CFxObject)._FightFx = nil 			--进战/出战特效
def.field(CFxObject)._MountHorseFx = nil 		--上下马特效
def.field(CFxObject)._ResurrectFx = nil 		--复活特效

def.field("number")._FacialId = 0				--初始脸型ID
def.field("number")._HairstyleId = 0			--初始发型ID

def.field("boolean")._IsWingModelVisible = true

local weapon_scale_in_hand = Vector3.one
local weapon_scale_on_back = Vector3.New(0.7, 0.7, 0.7)

-- 装备更改事件
local function raise_outwards_changed_event(self)
	if self:IsHostPlayer() then
		local event = EquipChangeCompleteEvent()
		event._PlayerId = self._ID
		CGame.EventManager:raiseEvent(nil, event)
	end
end

-- 时装更改事件
local function raise_dress_changed_event(self, dressSlot, bShow)
	if self:IsHostPlayer() then
		local ShowDressEvent = require "Events.ShowDressEvent"
		local event = ShowDressEvent()
		event._DressShowEnable = bShow
		event._DressSlot = dressSlot

		CGame.EventManager:raiseEvent(nil, event)
	end
end



def.override("table").Init = function(self, roleInfo)
	self:InitAnimationTable(roleInfo.CreatureInfo.Animations)
end

--[[ ---------------强化格子信息   Begin---------------]]
-- def.virtual("table").InitEquipCellInfo = function(self, equipCellInfoListDB)
-- 	if equipCellInfoListDB == nil then return end

-- 	--客户端先行处理，没有初始化格子问题
-- 	if #equipCellInfoListDB == 0 then
-- 		equipCellInfoListDB = {}
-- 		for i=1,8 do
-- 			table.insert(equipCellInfoListDB, {InforceLevel = 0, SurmountLevel = 0})
-- 		end
-- 	end

-- 	for i,infoDB in ipairs(equipCellInfoListDB) do
-- 		local data = self:CreateEquipCell( infoDB )
-- 		self._EquipCellInfo[#self._EquipCellInfo + 1] = data
-- 	end
-- end

-- def.method("table", "=>", "table").CreateEquipCell = function(self, equipCellInfoDB)
-- 	local data = CEquipCell.new()
-- 	if equipCellInfoDB ~= nil then
-- 		data._InforceLevel = equipCellInfoDB.InforceLevel
-- 		data._SurmountLevel = equipCellInfoDB.SurmountLevel
-- 	end 
-- 	return data
-- end

-- def.method("=>", "table").GetEquipCellInfo = function(self)
-- 	return self._EquipCellInfo
-- end

-- --获取部位的强化格子信息
-- def.method("number", "=>", "table").GetEquipCellInfoBySlot = function(self, equipSlot)
-- 	local equipCellList = self:GetEquipCellInfo()

-- 	return equipCellList[equipSlot]
-- end

-- --更新格子信息
-- def.method("table").UpdateEquipCellInfo = function(self, equipCellInfoDB)
-- 	local equipCellList = self:GetEquipCellInfo()

-- 	if equipCellList[equipCellInfoDB.Index + 1] == nil then
-- 		local data = self:CreateEquipCell(equipCellInfoDB)
-- 		equipCellList[equipCellInfoDB.Index + 1] = data
-- 	else
-- 		local data = equipCellList[equipCellInfoDB.Index + 1]
-- 		data._InforceLevel = equipCellInfoDB.InforceLevel
-- 		data._SurmountLevel = equipCellInfoDB.SurmountLevel
-- 	end
-- end
--[[ ---------------强化格子信息   End---------------]]

-- 是否在服务器战斗状态
def.override("=>", "boolean").IsInServerCombatState = function(self)
	return (self._IgnoreClientStateChange and self._IsInCombatState)
end

def.method("=>", "boolean").IsServerMounting = function(self)
	return self._IsMountingHorse
end

def.method("=>", "number").GetCurrentHorseId = function(self)
	return self._InfoData._HorseId
end

def.method("number").SetCurrentHorseId = function(self, horseId)
	self._InfoData._HorseId = horseId
end

-- 获取上马时的站立动作
def.override("=>", "string").GetRideStandAnimationName = function (self)
	if self:IsOnRide() then
		local template = CElementData.GetHorseTemplate(self._MountTid)
		if template ~= nil and not IsNilOrEmptyString(template.StandAnimName) then
			return template.StandAnimName
		end
	end
    return EnumDef.CLIP.RIDE_STAND
end

-- 获取上马时的跑动动作
def.override("=>", "string").GetRideRunAnimationName = function (self)
	if self:IsOnRide() then
		local template = CElementData.GetHorseTemplate(self._MountTid)
		if template ~= nil and not IsNilOrEmptyString(template.RunAnimName) then
			return template.RunAnimName
		end
	end
    return EnumDef.CLIP.RIDE_RUN
end

def.override("=>", "boolean").GetChangePoseState = function(self)
	return self._IsChangePose
end

def.method("table").SetChangePoseDate = function(self, data)
	self._ChangePoseDate = data
	self._IsChangePose = (data ~= nil)
end

def.method("number", "=>", "string").GetChangePoseData = function(self, ani_type)
	local ret = ""
	if ani_type ==  EnumDef.PostureType.StandAction then		
		if self._ChangePoseDate[1] and self._ChangePoseDate[1] ~= "" then
			ret = self._ChangePoseDate[1]
		end
	elseif ani_type ==  EnumDef.PostureType.FightStandAction then
		if self._ChangePoseDate[2] and self._ChangePoseDate[2] ~= "" then
			ret = self._ChangePoseDate[2]
		end
	elseif ani_type ==  EnumDef.PostureType.MoveAction then
		if self._ChangePoseDate[3] and self._ChangePoseDate[3] ~= "" then
			ret = self._ChangePoseDate[3]
		end
	elseif ani_type ==  EnumDef.PostureType.FightMoveAction then
		if self._ChangePoseDate[4] and self._ChangePoseDate[4] ~= "" then
			ret = self._ChangePoseDate[4]
		end
	else 
		warn("error type occur in GetChangePoseData ",debug.traceback())		
	end
	return ret
end

def.override( "=>", "string", "number").GetChangePoseHurtData = function(self)
	local hurt_ani = ""
	local hurt_actor = ""
	if self._ChangePoseDate[6] and self._ChangePoseDate[6] ~= "" then
		hurt_ani = self._ChangePoseDate[6]
	end

	if self._ChangePoseDate[7] and self._ChangePoseDate[7] ~= "" then
		hurt_actor = self._ChangePoseDate[7]
	end
	return hurt_ani, hurt_actor
end

--上下坐骑（服务器同步）
def.method("boolean").MountOn = function(self, bMountOn)
	--上马后设置，服务器同步
	self._IsMountingHorse = bMountOn

	if bMountOn then
		self:Ride(self:GetCurrentHorseId(), false)
	elseif self:IsOnRide() then
		self:UnRide()
	end
end

--检查服务器与客户端的上马状态，保证以服务器状态为准
def.method().CheckMountState = function(self)
	if self:IsInExterior() then return end

	local server_state = self:IsServerMounting()
	local client_state = self:IsOnRide()
	if server_state == client_state then return end

	if server_state then
		self:Ride(self:GetCurrentHorseId(), false)
	else
		self:UnRide()
	end
end

-- 清空上马后设置的状态
local function cleanup_player_mount_status(self)
	self:PlayMountFx()
	if self._MountModel ~= nil then
		self:ResetModelWhenRide(self._MountModel)

		local mount = self._MountModel:GetGameObject()
		if mount then GameUtil.RemoveFootStepTouch(mount) end

		self._MountModel:Destroy()
		self._MountModel = nil
	end
	self._HorseStandBehaviourComp = nil

	self:UpdateMountState()		--更新状态

	if self:IsHostPlayer() then
		--读取对应职业的正常相机视点高度区间
		local heightOffsetMin, heightOffsetMax = ModuleProfDiffConfig.GetFollowCamViewPointHeightOffsetInterval(self._InfoData._Prof, false)
		GameUtil.SetGameCamHeightOffsetInterval(heightOffsetMin, heightOffsetMax, false)
		local heightOffset = ModuleProfDiffConfig.GetCamViewPointDefaultHeightOffset(self._InfoData._Prof, false)
		GameUtil.SetGameCam2DHeightOffset(heightOffset)
		if self:IsInExterior() then
			-- 外观相机
			local _, _, _, heightOffset, _ = ModuleProfDiffConfig.GetExteriorCamHorseDefaultParams(self._InfoData._Prof)
			GameUtil.SetExteriorCamHeightOffset(heightOffset)
		end
	end

	GameUtil.EnableDressUnderSfx(self:GetOriModel():GetGameObject(), true) -- 恢复时装脚底特效
end

-- 移除坐骑出生动作计时器
local function remove_mount_born_ani_timer(self)
	if self._MountBornAniTimer ~= 0 then
		self:RemoveTimer(self._MountBornAniTimer)
		self._MountBornAniTimer = 0
	end
end

-- 上马（纯客户端表现）
def.override("number", "boolean").Ride = function (self, tid, isPlayBornAnim)
	if tid <= 0 then return end

	--重置客户端技能状态
	self:LeaveClientCombatState(true)

	if self._MountModel ~= nil and self._MountTid == tid then		--无需重新加载
		self:UpdateMountState()			--更新状态
		if isPlayBornAnim then
			self:StartMountBorn()
		end
	else
		local horseData = CElementData.GetTemplate("Horse", tid)
		if horseData == nil then return end

		-- self._IsAllowChangeHorse = false
		self._MountTid = tid
		self._MountBornMusic = horseData.BirthMusic
		local function load_mount_model()
			if self._MountTid == 0 then return end -- 加载过程中下马
			
			local model_asset_path = horseData.ModelAssetPath
			local model = CModel.new()
			model._ModelFxPriority = self:GetModelCfxPriority()
			model:Load(model_asset_path, function(ret)
				if self:GetCurModel() == nil or IsNil(self:GetCurModel()._GameObject) or IsNil(self:GetGameObject()) then
					--在坐骑模型加载过程中，玩家离开视野，本体Model销毁
					model:Destroy()
					return
				end

				if self._MountTid > 0 and self._MountTid ~= tid then
					-- 加载过程中切换了坐骑（非下马）
					model:Destroy()
					return
				end

				--释放原来的坐骑
				if self._MountModel ~= nil then
					--删除原来的mount model
					self:ResetModelWhenRide(self._MountModel)

					local mount = self._MountModel:GetGameObject()
					if mount then GameUtil.RemoveFootStepTouch(mount) end

					self._MountModel:Destroy()
					self._MountModel = nil
				end
				self._HorseStandBehaviourComp = nil

				-- self._IsAllowChangeHorse = true
				if not ret then
					warn("Fail to load mount model, asset path:" .. model_asset_path)
					self._MountTid = 0
					self._MountBornMusic = ""
					model:Destroy()
				else
					--挂上新的坐骑
					self._MountModel = model
					self._MountModel._GameObject.name = "MountModel"
					self._MountModel._GameObject:SetActive(true)

					self:OnLoadMount(self._MountModel)
					self:UpdateMountState()  		--更新状态
					if isPlayBornAnim then
						self:StartMountBorn()
					end

					-- 加载过程有可能下马
					if not self:IsOnRide() then
						cleanup_player_mount_status(self)
						remove_mount_born_ani_timer(self)
					else
						self:SetWingVisiState(not horseData.IsHideWing)
					end
				end				
			end)
		end

		self:AddLoadedCallback(load_mount_model)
	end
end

def.method().PlayMountFx = function(self)
	if self._MountHorseFx ~= nil then
		self._MountHorseFx:Stop()
	end
	self._MountHorseFx = CFxMan.Instance():PlayAsChild(PATH.Etc_MountHorse, self:GetGameObject(), Vector3.zero, Quaternion.identity, 3, false, -1, EnumDef.CFxPriority.Always)
end

def.method(CModel).OnLoadMount = function (self, mountModel)
	if mountModel == nil or IsNil(mountModel._GameObject) then
		error("Mount Model got nil On Load Mount")
		return
	end

    local mount = mountModel:GetGameObject()
    GameUtil.SetLayerRecursively(mount, self:GetRenderLayer())
    GameUtil.AddFootStepTouch(mount)

    --读取scale, 挂点配置
	local desInfo = ModuleProfDiffConfig.GetModuleInfo("HorseScale")
	
	local hpScale = Vector3.one
	local horseScale = Vector3.one

	local hpScaleInfo = desInfo.Hostplayer
	if hpScaleInfo ~= nil then
		local data = hpScaleInfo[self._MountTid]
		if data ~= nil then
			local scale = data[self._InfoData._Prof]
			if scale ~= nil then
				hpScale.x = scale
				hpScale.y = scale
				hpScale.z = scale
			end
		end
	end

	local horseScaleInfo = desInfo.Horse
	if horseScaleInfo ~= nil then
		local data = horseScaleInfo[self._MountTid]
		if data ~= nil then
			local scale = data[self._InfoData._Prof]
			horseScale.x = scale
			horseScale.y = scale
			horseScale.z = scale
		end
	end

    mount.parent = self._GameObject
    mount.localPosition =  Vector3.zero
    mount.localRotation = Quaternion.identity
    mount.localScale = horseScale

    --[[
    local player = self:GetCurModel()._GameObject
    player.localPosition = Vector3.zero
    player.localRotation = Quaternion.identity
    player.localScale = Vector3.one
    ]]

    --挂点
    local attachName = "HangPoint_Ride"
    local attachPointInfo = desInfo.AttachPoints
    if attachPointInfo ~= nil then
    	attachName = attachPointInfo[self._InfoData._Prof]
    end

    local hook_bone = mountModel:AttachModel(attachName, self:GetCurModel(), attachName, Vector3.zero, Quaternion.identity)
    if hook_bone ~= nil then
    	hook_bone.localScale = hpScale
    end

    if self._IsMountEnterSight == true then
    	-- 进入视野时已上马，不播特效
    	self._IsMountEnterSight = false
    elseif not self:IsInExterior() then
    	self:PlayMountFx()
    end

    if self:IsHostPlayer() then
		--读取对应职业的上马相机视点高度区间
		local heightOffsetMin, heightOffsetMax = ModuleProfDiffConfig.GetFollowCamViewPointHeightOffsetInterval(self._InfoData._Prof, true)
		GameUtil.SetGameCamHeightOffsetInterval(heightOffsetMin, heightOffsetMax, false)
		local heightOffset = ModuleProfDiffConfig.GetCamViewPointDefaultHeightOffset(self._InfoData._Prof, true)
		GameUtil.SetGameCam2DHeightOffset(heightOffset)
		if self:IsInExterior() then
			-- 外观相机
			local _, _, _, heightOffset, _ = ModuleProfDiffConfig.GetExteriorCamHorseParams(self._InfoData._Prof, self._MountTid)
			GameUtil.SetExteriorCamHeightOffset(heightOffset)
		end
    end

    -- 将武器瞬间放置到背上
    if not IsNil(self._CombatStateChangeComp) then
		self._CombatStateChangeComp:ChangeState(true, false, 0, 0)
	end
	-- 重新找坐骑站立组件
	self:RequireHorseStandBehaviourComp()

	-- 通过玩家数量控制逻辑来控制器显隐
	if not self:IsHostPlayer() then
	--	mountModel:SetVisible(self:IsCullingVisible())
	end

	GameUtil.EnableDressUnderSfx(self:GetOriModel():GetGameObject(), false) -- 隐藏时装脚底特效
end

def.override().UnRide = function (self)
    if self._MountTid <= 0 then 
    	return 
    end

	local oldTid = self._MountTid
	self._MountTid = 0
	self._MountBornMusic = ""

	if oldTid > 0 then
		local horseData = CElementData.GetTemplate("Horse", oldTid)
		if horseData ~= nil and horseData.IsHideWing then
			-- 恢复翅膀显示
			self:SetWingVisiState(true)
		end
	end
	local is_client_state = not self:IsInServerCombatState()
	cleanup_player_mount_status(self)
	remove_mount_born_ani_timer(self)
	self:UpdateCombatState(self._IsInCombatState, is_client_state, 0, true, false)	

	if self._CombatStateChangeComp and self._IsInCombatState then
    	self._CombatStateChangeComp:ChangeState(true, true, 0, 0)
    end
end

def.method().UpdateMountState = function (self)
   local bRide = self:IsOnRide()				--这时必须保证骑乘状态被正确设置

   --动作
    local state = self._FSM._CurState
    if state ~= nil then
        if state._Type == FSM_STATE_TYPE.MOVE or state._Type == FSM_STATE_TYPE.IDLE then
        	state:PlayMountStateAnimation(state._Type)
        end
    end
	self:UpdateWingAnimation()

    local go = self:GetGameObject()
    if go ~= nil then
		GameUtil.EnableGroundNormal(go, bRide)			--运用地面法向
	end

	--shadow, pate???
	local pate = self._TopPate
	if pate ~= nil then
		local follow = pate._FollowComponent 
		if follow ~= nil and self:GetCurModel() ~= nil and self:GetCurModel():GetGameObject() ~= nil then
			follow:AdjustOffset(self:GetCurModel():GetGameObject(), self:GetPateExtraHeight())
		end
	end

    if not bRide then
		--下马时，移动速度不同步，客户端需要先行重置
		self:UpdateAnimationSpeed()
	end
end

-- 骑马时重置玩家模型，方便直接切换坐骑模型
def.method(CModel).ResetModelWhenRide = function (self, mountModel)
	local desInfo = ModuleProfDiffConfig.GetModuleInfo("HorseScale")
    --挂点
    local attachName = "HangPoint_Ride"
    if desInfo ~= nil and desInfo.AttachPoints ~= nil then
    	attachName = desInfo.AttachPoints[self._InfoData._Prof]
    end

	local hp = mountModel:GetAttach(attachName)
    if hp ~= nil then 
        mountModel:Detach(attachName)       
		local m = self:GetOriModel()._GameObject
        m.parent = self._GameObject
        m.localPosition = Vector3.zero
        m.localRotation = Quaternion.identity       --miaoyu, 去掉地面法向
        m.localScale = Vector3.one
    end
end

def.override("=>", "userdata").RequireHorseStandBehaviourComp = function (self)
	local model = self._MountModel
	if model == nil then
		return nil
	end
	if IsNil(model._GameObject) or not model._GameObject.activeSelf then
		return nil
	end

	if self._HorseStandBehaviourComp == nil then 
		self._HorseStandBehaviourComp = model._GameObject:GetComponent(ClassType.HorseStandBehaviour)
		if self._HorseStandBehaviourComp == nil then
			self._HorseStandBehaviourComp = model._GameObject:AddComponent(ClassType.HorseStandBehaviour)
		end
		if self._HorseStandBehaviourComp ~= nil then
			local min_loop = 4 -- stand的最小循环次数
			local max_loop = 8 -- stand的最大循环次数
			local loop_interval = string.split(CSpecialIdMan.Get("HorseStandToIdleLoopInterval"), "*")
			if loop_interval ~= nil then
				if loop_interval[1] ~= nil then
					min_loop = tonumber(loop_interval[1])
				end
				if loop_interval[2] ~= nil then
					max_loop = tonumber(loop_interval[2])
				end
			end
			local standAniName = self:GetRideStandAnimationName()
			local host_gameobject = nil
			local host_model = self:GetOriModel()
			if host_model ~= nil then
				host_gameobject = host_model._GameObject
			end
			self._HorseStandBehaviourComp:Init(min_loop, max_loop, standAniName, host_gameobject)
		end
	end

	return self._HorseStandBehaviourComp
end

def.override("=>", "userdata").GetHorseStandBehaviourComp = function (self)
	return self._HorseStandBehaviourComp
end

def.method().StartMountBorn = function (self)
	if self._MountTid <= 0 or self._MountModel == nil then return end

	local comp = self:GetHorseStandBehaviourComp()
	if comp ~= nil then
		comp:StartBorn() -- 坐骑的出生动作
		CSoundMan.Instance():Play3DAudio(self._MountBornMusic, self:GetPos(), 0)
	end

	-- 人物动作
	local horseTemplate = CElementData.GetHorseTemplate(self._MountTid)
	local animation = horseTemplate.BornAnimName
	if self:HasAnimation(animation) then
		local fade_time = self:IsHostPlayer() and EnumDef.SkillFadeTime.HostOther or EnumDef.SkillFadeTime.MonsterOther
		if self:IsPlayingAnimation(animation) then
			-- 在坐骑上相同动作时不做融合，直接从头播放
			fade_time = 0
		end
		self:PlayAnimation(animation, fade_time, false, 0, 1)
	end
	remove_mount_born_ani_timer(self)
	local aniLength = self._MountModel:GetAniLength(EnumDef.CLIP.BORN)
	if aniLength > 0 then
		self._MountBornAniTimer = self:AddTimer(aniLength, true, function()
			-- 恢复坐骑站立的动作
			local aniname = self:GetRideStandAnimationName()
			local fade_time = self:IsHostPlayer() and EnumDef.SkillFadeTime.HostOther or EnumDef.SkillFadeTime.MonsterOther
			self:PlayAnimation(aniname, fade_time, false, 0, 1)
		end)
	end
end

-- 玩家初始化时设置影响外观的模型参数
def.method("table").SetOutwardDatas = function (self, exteriorInfo)
	-- 通常的
	self._FacialId = exteriorInfo.Face.FacialId
	self._HairstyleId = exteriorInfo.Face.HairstyleId
	self:SetCustomOutward(exteriorInfo.Face)
	-- 装备
	local equips = { ArmorTid = exteriorInfo.ArmorTId, WeaponTid = exteriorInfo.WeaponTId,WeaponInforceLv = exteriorInfo.WeaponInforceLevel}
	self:SetEquipsData(equips)
	-- 翅膀
	self:SetCurWingData(exteriorInfo.WingTId, exteriorInfo.WingTalentPageID, exteriorInfo.WingLevel)
	-- 时装
	self:SetDressEnable(exteriorInfo.DressFirstShow)
	self:SetDressInfos(exteriorInfo.DressWear)
end

--设置是否优先显示时装
def.method("boolean").SetDressEnable = function(self, bShow)
	--warn("SetDressEnable = ", bShow)
	-- if true then  -- 测试用
	-- 	self._EnableDress = true
	-- 	return
	-- end
	local oldSet = self._EnableDress
	self._EnableDress = bShow

	if self._IsReady and oldSet ~= bShow and self:HasDress() then
		local curParam = self:GetModelParams()
		local updateParam = ModelParams.GetUpdateParams(self._OutwardParams, curParam)
		self:UpdateOutward(updateParam, function()
			self:SetCurWeaponInfo()
			local go = self:GetGameObject()
			if not IsNil(go) then
				GameUtil.SetLayerRecursively(go, self:GetRenderLayer())
			end
			raise_dress_changed_event(self, -1, bShow)
		end)
	end
end

--获取是否优先显示时装
def.method("=>", "boolean").GetDressEnable = function(self)
	return self._EnableDress
end

--获取当前穿戴时装
def.method("=>", "table").GetCurDressInfos = function(self)
	return self._DressInfos
end

def.method("number", "=>", CDress).GetCurDressInfoByPart = function (self, part)
	return self._DressInfos[part]
end

-- 是否穿戴时装（和时装显隐无关）
def.method("=>", "boolean").HasDress = function (self)
	return next(self._DressInfos) ~= nil
end

--获取当前技能列表
def.override("=>", "table").GetUserSkillMap = function(self)
	return self._UserSkillMap
end

def.method("number", "=>", "table").GetSkillData = function(self, skillId)
    for i,v in ipairs(self._UserSkillMap) do
		if v.SkillId == skillId then
			return v
		end
	end
	return nil
end

-- 设置已穿戴的时装信息
def.method("table").SetDressInfos = function (self, dressInfo)
	if dressInfo == nil then return end

	self._DressInfos = {}
	for _, info in ipairs(dressInfo) do
		if info.Tid > 0 and info.InsId > 0 then
			local data = CDress.new(info)
			if data then
				local dressPart = Util.GetDressPartBySlot(data._DressSlot)
				-- warn("DB Dress Data tid:", data._Tid, "slot:", data._DressSlot)
				self._DressInfos[dressPart] = data
			end
		end
	end
end

--设置当前穿戴时装
def.method(CDress, "boolean").SetCurDressInfo = function(self, dressInfo, bIsPuton)
	if dressInfo == nil then return end

	local dressPart = Util.GetDressPartBySlot(dressInfo._DressSlot)
	if bIsPuton then
		self._DressInfos[dressPart] = dressInfo
	else
		self._DressInfos[dressPart] = nil
	end
	self:UpdateDressModel(dressInfo, bIsPuton)
end

--人物时装更新
def.method(CDress, "boolean").UpdateDressModel = function (self, dressInfo, bIsPuton)
	if self._IsModelHidden or self:IsBodyPartChanged() or dressInfo == nil then return end

	local slot = dressInfo._DressSlot
	local updateParam = ModelParams.new()
	updateParam._Prof = self._InfoData._Prof
	local bShow = self:GetDressEnable() or self:IsInExterior()
	updateParam._Is2ShowDress = bShow
	local callback = nil
	-- 不同时装部位的处理
	if slot == EDressType.Armor then
		-- 服饰
		local assetPath = ""
		if bIsPuton and bShow then
			-- 穿戴
			assetPath = dressInfo._Template.AssetPath1
			updateParam._DressColors[slot] = CDress.CopyColors(dressInfo)
		else
			-- 脱下，找装备外观路径
			assetPath = Util.GetArmorAssetPath(self._Equipments.ArmorTid, self._InfoData._Prof, self._InfoData._Gender)
		end
		if assetPath == self._OutwardParams._ArmorAssetPath and bShow then
			self:UpdateDressColors(slot, dressInfo._Colors)
			return
		end
		updateParam._ArmorAssetPath = assetPath
	elseif slot == EDressType.Hat then
		-- 帽子
		local assetPath = ""
		if bIsPuton and bShow then
			-- 穿戴
			assetPath = dressInfo._Template.AssetPath1
			updateParam._DressColors[slot] = CDress.CopyColors(dressInfo)
		else
			-- 脱下
			assetPath = OutwardUtil.Get(self._InfoData._Prof, "Hair", self._HairstyleId)
		end
		if assetPath == self._OutwardParams._HairstyleAssetPath and bShow then
			self:UpdateDressColors(slot, dressInfo._Colors)
			return
		end
		-- updateParam._HairColorId = self._OutwardParams._HairColorId
		updateParam._IsChangeHeadwear = true
		updateParam._HairstyleAssetPath = assetPath
	elseif slot == EDressType.Headdress then
		-- 头饰
		local assetPath = ""
		if bIsPuton and bShow then
			-- 穿戴
			assetPath = dressInfo._Template.AssetPath1
			updateParam._DressColors[slot] = CDress.CopyColors(dressInfo)
		end
		if assetPath == self._OutwardParams._HeadwearAssetPath and bShow then
			self:UpdateDressColors(slot, dressInfo._Colors)
			return
		end
		updateParam._IsChangeHeadwear = true
		updateParam._HeadwearAssetPath = assetPath
		updateParam._HairColorId = self._OutwardParams._HairColorId
		local originalHairPath = OutwardUtil.Get(self._InfoData._Prof, "Hair", self._HairstyleId)
		if self._OutwardParams._HairstyleAssetPath ~= originalHairPath then
			updateParam._HairstyleAssetPath = originalHairPath
		end
		callback = function ()
			local model = self:GetOriModel()
			if model == nil then return end
			local headwearModel = model:GetAttach("HeadwearHP")
			if headwearModel == nil or IsNil(headwearModel:GetGameObject()) then return end
			-- 设置层级
			GameUtil.SetLayerRecursively(headwearModel:GetGameObject(), self:GetRenderLayer())
		end
	elseif slot == EDressType.Weapon then
		-- 武器
		local assetPathL, assetPathR = "", ""
		if bIsPuton and bShow then
			-- 穿戴
			assetPathL, assetPathR = Util.GetWeaponDressAssetPaths(dressInfo._Tid)
			updateParam._DressColors[slot] = CDress.CopyColors(dressInfo)
		else
			-- 脱下
			assetPathL, assetPathR = Util.GetWeaponAssetPaths(self._Equipments.WeaponTid, self._InfoData._Prof, self._InfoData._Gender)
			updateParam._IsUpdateWeaponFx = true
			updateParam._WeaponFxPathLeftBack, updateParam._WeaponFxPathRightBack, updateParam._WeaponFxPathLeftHand, updateParam._WeaponFxPathRightHand = Util.GetWeaponFxPaths(self._Equipments.WeaponTid, self._Equipments.WeaponInforceLv)
		end
		if assetPathL == self._OutwardParams._WeaponAssetPathL and assetPathR == self._OutwardParams._WeaponAssetPathR then
			if bShow then
				-- 显示时装，更新颜色
				self:UpdateDressColors(slot, dressInfo._Colors)
			else
				-- 显示装备，更新特效
				self:UpdateWeaponFx()
			end
			return
		end
		updateParam._IsWeaponInHand = self:IsInCombatState() or self:IsDead()
		updateParam._WeaponAssetPathL, updateParam._WeaponAssetPathR = assetPathL, assetPathR

		callback = function()
			self:SetCurWeaponInfo()

			-- 设置层级
			if not IsNil(self._CurWeaponInfo[4]) then
				GameUtil.SetLayerRecursively(self._CurWeaponInfo[4], self:GetRenderLayer())
			end
			if not IsNil(self._CurWeaponInfo[5]) then
				GameUtil.SetLayerRecursively(self._CurWeaponInfo[5], self:GetRenderLayer())
			end
		end
	end

	--[[
	-- 更新参数
	if bIsPuton and bShow then
		self._OutwardParams._DressColors[slot] = CDress.CopyColors(dressInfo)
	else
		self._OutwardParams._DressColors[slot] = {}
	end
	--]]

	self:UpdateOutward(updateParam, function()
		if callback ~= nil then
			callback()
		end
		raise_dress_changed_event(self, slot, bShow)
	end)
end

-- 根据部位更改时装颜色
-- @param dyeIdList 染色Id列表，按照部位一到部位二排序，不需要染的补0
def.method("number", "table").UpdateDressColors = function (self, dressSlot, dyeIdList)
	if self:IsBodyPartChanged() or dyeIdList == nil then return end

	local bShow = self:GetDressEnable() or self:IsInExterior()
	if not bShow then return end

	local updateParam = ModelParams.new()
	updateParam._Prof = self._InfoData._Prof
	updateParam._Is2ShowDress = true
	local newColors = {}
	for _, dyeId in ipairs(dyeIdList) do
		newColors[#newColors+1] = dyeId
	end
	updateParam._DressColors[dressSlot] = newColors
	self:UpdateOutward(updateParam, function()
		raise_dress_changed_event(self, dressSlot, bShow)
	end)
end

-- 获取当前穿戴翅膀, 这里返回一个默认值
def.method("=>", "number").GetCurWingId = function(self)
	return self._WingData.WingId or 0
end

-- 获取当前穿戴翅膀, 这里返回一个默认值
def.method("=>", "number").GetCurWingLevel = function(self)
	return self._WingData.Level or 0
end

def.method("number").UpdateWingByPageId = function (self, pageId)
	self._WingData.PageId = pageId
	-- 更新模型
	local wingId = self:GetCurWingId()
	local wingLv = self:GetCurWingLevel()
	self:UpdateWingModel(wingId, wingLv, pageId)
end

--设置当前穿戴翅膀
def.method("number", "number", "number").SetCurWingData = function(self, wingId, pageId, wing_lvl)
	-- warn("SetCurWingData wingId:", wingId, "wingLv:", wing_lvl, "wingPageId:", pageId)
	if not self._WingData then
		self._WingData = {}	
	end
	--  传 -1 不更新
	if wingId ~= -1 then
		self._WingData.WingId = wingId
	end
	--  传 -1 不更新
	if pageId ~= -1 then
		self._WingData.PageId = pageId
	end

	self._WingData.Level = wing_lvl
end

--获取当前翅膀天赋页id
def.method("=>", "number").GetCurWingPageId = function(self)
	return self._WingData.PageId or 0
end

-- 翅膀的显隐设置
def.method("boolean").SetWingVisiState = function(self, state)
	if self._WingModel then
		local wing_go = self._WingModel:GetGameObject()
		if wing_go then
			wing_go:SetActive(state)
			self._IsWingModelVisible = state
		end
	end
end

-- 设置影响外观的装备的数据
def.method("table").SetEquipsData = function (self, equips)
	local armorTid = 0
	local weaponTid = 0
	local weaponInforceLv = 0
	if equips ~= nil then
		if type(equips.ArmorTid) == "number" then
			armorTid = equips.ArmorTid
		end
		if type(equips.WeaponTid) == "number" then
			weaponTid = equips.WeaponTid
		end
		if type(equips.WeaponInforceLv) == "number" then
			weaponInforceLv = equips.WeaponInforceLv
		end
	end

	self._Equipments =
	{
		ArmorTid = armorTid,
		WeaponTid = weaponTid,
		WeaponInforceLv = weaponInforceLv,
	}
end

def.method("table").ShowEquipments = function (self, equips)
	--warn("ShowEquipments", debug.traceback())
	if self._Equipments == nil then
		warn("Can not update equipment because equipment has not inited")
		return
	end

	local old_armor = self._Equipments.ArmorTid
	local old_weapon = self._Equipments.WeaponTid
	-- local old_wing = 0

	local armor = equips.ArmorTid
	local weapon = equips.WeaponTid
	local weaponInforceLv = equips.WeaponInforceLv
	if not self._IsModelHidden then
		if weapon ~= old_weapon then
			self:ChangeWeapon(weapon, false, weaponInforceLv)
		else
			if weaponInforceLv ~= self._Equipments.WeaponInforceLv then 
				self:UpdateWeaponInforceLv(weaponInforceLv)
			end
		end
		if armor ~= old_armor then
			self:ChangeArmor(armor) 
		end
	end
end

def.method("number", "number","number").UpdateEquipments = function(self, slot, tid,inforceLv)
	if slot == EEquipmentSlot.Weapon then
		-- warn("WeaponInforceLv   ",inforceLv)
		local equips = { ArmorTid = self._Equipments.ArmorTid, WeaponTid = tid,WeaponInforceLv = inforceLv}
		self:ShowEquipments(equips)
	elseif slot == EEquipmentSlot.Armor then
		local equips = { ArmorTid = tid, WeaponTid = self._Equipments.WeaponTid,WeaponInforceLv = self._Equipments.WeaponInforceLv}
		self:ShowEquipments(equips)
	end
end

def.virtual("=>", "number").GetLevel = function(self)
	return self._InfoData._Level
end

-- 获取武器的实例Id（测试用）
def.method("=>", "string").GetCurWeaponGUID = function (self)
--[[
	local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
	local itemData = self._Package._EquipPack._ItemSet[EEquipmentSlot.Weapon+1]
	if itemData ~= nil then
		return itemData._Guid
	else
		return ""
	end
]]
	return ""
end

-- 获取模型数据
def.method("=>", ModelParams).GetModelParams = function(self)
	local param = ModelParams.new()
	local prof = self._InfoData._Prof
	local gender = self._InfoData._Gender
	param._Prof = prof
	param._ModelAssetPath = Util.GetPlayerBaseModelAssetPath(prof, gender)

	param._Is2ShowDress = self:GetDressEnable()
	if param._Is2ShowDress then
		local allDressInfos = self:GetCurDressInfos()
		for _, data in pairs(allDressInfos) do
			-- 染色信息
			param._DressColors[data._DressSlot] = CDress.CopyColors(data)
		end
	end
	if self._Equipments ~= nil then
		param._IsWeaponInHand = self:IsInCombatState() or self:IsDead()

		local armorDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Body)
		param:SetArmorParam(self._Equipments.ArmorTid, armorDressInfo)
		local weaponDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Weapon)
		param:SetWeaponParam(self._Equipments.WeaponTid, self._Equipments.WeaponInforceLv, weaponDressInfo)
	end

	if self._OutwardParams ~= nil then
		-- 头部
		local headDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Head)
		param:SetHeadParam(self._HairstyleId, self._OutwardParams._HairColorId, headDressInfo)

		local faceAssetPath = OutwardUtil.Get(prof, "Face", self._FacialId)
		if type(faceAssetPath) == "string" then
			param._FacialAssetPath = faceAssetPath
		end
		param._SkinColorId = self._OutwardParams._SkinColorId
	end
	
	-- 翅膀
	param._IsChangeWing = true
	param._WingAssetPath = Util.GetWingAssetPath(self:GetCurWingId(), self:GetCurWingLevel(), self:GetCurWingPageId())

	return param
end

-- 根据参数更新外观
def.method(ModelParams, "function").UpdateOutward = function (self, updateParam, callback)
	if updateParam == nil then return end

	-- updateParam:PrintModelParams("UpdateOutward updateParam")
	self:AddLoadedCallback(function(player)
		if player._IsReleased then return end

		local model = player:GetOriModel()
		if model == nil then return end

		-- 更新本地保存参数
		player._OutwardParams:Update(updateParam)
		-- player._OutwardParams:PrintModelParams("UpdateOutward curParam")

		model:UpdateWithModelParams(updateParam, function()
			if callback ~= nil then
				callback()
			end
		end)
	end)
end

def.override("table", "function").ChangeAllPartShape = function(self, part_shape_map, callback)
	if part_shape_map == nil then return end

	self._CurPartialShapes = {}

	local weaponAssetPathL, weaponAssetPathR = "", ""
	if part_shape_map.WeaponTid ~= 0 then
		self._CurPartialShapes[EnumDef.EntityPart.Weapon] = part_shape_map.WeaponTid
		local prof = self._InfoData._Prof
		local gender = self._InfoData._Gender
		weaponAssetPathL, weaponAssetPathR = Util.GetWeaponAssetPaths(part_shape_map.WeaponTid, prof, gender)
	end

	local armorAssetPath = ""
	if part_shape_map.BodyAssetPath ~= "" then
		self._CurPartialShapes[EnumDef.EntityPart.Body] = part_shape_map.BodyAssetPath
		armorAssetPath = part_shape_map.BodyAssetPath
	end

	local hairAssetPath = ""
	if part_shape_map.HairAssetPath ~= "" then
		self._CurPartialShapes[EnumDef.EntityPart.Hair] = part_shape_map.HairAssetPath
		hairAssetPath = part_shape_map.HairAssetPath
	end

	local faceAssetPath = ""
	if part_shape_map.HeadAssetPath ~= "" then
		self._CurPartialShapes[EnumDef.EntityPart.Face] = part_shape_map.HeadAssetPath
		faceAssetPath = part_shape_map.HeadAssetPath
	end

	if weaponAssetPathL == "" and weaponAssetPathR == "" and armorAssetPath == "" and hairAssetPath == "" and faceAssetPath == "" then
		-- 没有变身
		warn("ChangeAllPartShape failed, all params got nothing")
		self._CurPartialShapes = nil
		return
	end

	local updateParam = self:GetModelParams()
	-- 重置无关参数
	updateParam._IsChangeWing = false
	updateParam._Is2ShowDress = false
	updateParam._DressColors = {}
	updateParam._SkinColorId = 0

	updateParam._ArmorAssetPath = armorAssetPath
	updateParam._WeaponAssetPathL, updateParam._WeaponAssetPathR = weaponAssetPathL, weaponAssetPathR
	updateParam._HairstyleAssetPath = hairAssetPath
	updateParam._FacialAssetPath = faceAssetPath

	self:UpdateOutward(updateParam, function ()
		self:SetCurWeaponInfo()
		GameUtil.SetLayerRecursively(self:GetOriModel():GetGameObject(), self:GetRenderLayer())
		-- 与范导新增规则 变身清除 受击rim效果
		local CVisualEffectMan = require "Effects.CVisualEffectMan"
		CVisualEffectMan.StopTwinkleWhiteEffect(self)

		if callback ~= nil then
			callback()
		end
	end)
end

-- 先没统计翅膀的变化
def.override("=>", "boolean").IsBodyPartChanged = function (self)    
    local curShapes = self._CurPartialShapes
	if curShapes == nil then return false end
	
	if curShapes[EnumDef.EntityPart.Body] and curShapes[EnumDef.EntityPart.Body] ~= 0 then
	    return true
	elseif curShapes[EnumDef.EntityPart.Face] and curShapes[EnumDef.EntityPart.Face] ~= 0 then
		return true
	elseif curShapes[EnumDef.EntityPart.Hair] and curShapes[EnumDef.EntityPart.Hair] ~= 0 then
		return true
	elseif curShapes[EnumDef.EntityPart.Weapon] and curShapes[EnumDef.EntityPart.Weapon] ~= 0 then
		return true
	end	 

	return false 
end

def.override("function").ResetPartShape = function(self, callback)
	-- 整体变身 不存在切换部分的情况
    if self:IsModelChanged() then
		warn("why total shape changed, still want to change part? ")
		return
	end

	local cur_model = self:GetCurModel()
	if self._IsReady and self._CurPartialShapes ~= nil then
		local param = self:GetModelParams()
		param._IsChangeWing = false -- 不设置会重新加载翅膀导致翅膀CModel的GameObject丢引用
		-- 身体
		local changed_armor_asset_id = self._CurPartialShapes[EnumDef.EntityPart.Body]
		if changed_armor_asset_id == nil then
			param._ArmorAssetPath = ""
		end

		-- 脸
		local changed_face_asset_id = self._CurPartialShapes[EnumDef.EntityPart.Face]
		if changed_face_asset_id == nil then
			param._FacialAssetPath = ""
		end 

		-- 头发
		local changed_hair_asset_id = self._CurPartialShapes[EnumDef.EntityPart.Hair]
		if changed_hair_asset_id == nil then
			param._HairstyleAssetPath = ""
		end

		-- 武器
		local change_weapon_tid = self._CurPartialShapes[EnumDef.EntityPart.Weapon]
		if change_weapon_tid == nil then
			param._WeaponAssetPathL, param._WeaponAssetPathR = "", ""
		end


		self:UpdateOutward(param, function ()
			self:SetCurWeaponInfo()
			GameUtil.SetLayerRecursively(self:GetOriModel():GetGameObject(), self:GetRenderLayer())
			if callback ~= nil then
				callback()
			end
			-- 与范导新增规则 变身清除 受击rim效果
			local CVisualEffectMan = require "Effects.CVisualEffectMan"
		 	CVisualEffectMan.StopTwinkleWhiteEffect(self)
		end)
	else
		-- 初始模型尚未加载完毕
		-- do nothing
	end
	self._CurPartialShapes = nil
end

local function GetWeaponHangPoint(isInHand)
	if isInHand then
		return "HangPoint_WeaponLeft", "HangPoint_WeaponRight"
	else
		return "HangPoint_WeaponBack1", "HangPoint_WeaponBack2"
	end
end

def.method("number", "boolean","number").ChangeWeapon = function (self, tid, change, weaponInforceLv)
	if self._IsModelHidden or tid < 0 then return end

	if not change then
		-- 非变身
		self._Equipments.WeaponTid = tid
		self._Equipments.WeaponInforceLv = weaponInforceLv
	end

	if self:IsBodyPartChanged() then
		raise_outwards_changed_event(self)
		return
	end

	local updateParam = ModelParams.new()
	updateParam._Prof = self._InfoData._Prof
	updateParam._Is2ShowDress = self:GetDressEnable()
	-- 武器模型
	updateParam._IsWeaponInHand = self:IsInCombatState() or self:IsDead()
	local weaponDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Weapon)
	updateParam:SetWeaponParam(tid, weaponInforceLv, weaponDressInfo)
	
	updateParam._GUID = "[Not UI]" .. self:GetCurWeaponGUID() -- 测试用

	self:UpdateOutward(updateParam, function ()
		self:SetCurWeaponInfo()
		-- 设置层级
		if not IsNil(self._CurWeaponInfo[4]) then
			GameUtil.SetLayerRecursively(self._CurWeaponInfo[4], self:GetRenderLayer())
		end
		if not IsNil(self._CurWeaponInfo[5]) then
			GameUtil.SetLayerRecursively(self._CurWeaponInfo[5], self:GetRenderLayer())
		end

		raise_outwards_changed_event(self)
	end)
end

-- 设置当前武器信息
def.method().SetCurWeaponInfo = function (self)
	local weaponLModel = self._Model:GetAttach("WeaponL")
	local weaponRModel = self._Model:GetAttach("WeaponR")
	self._CurWeaponInfo[1] = weaponLModel ~= nil
	self._CurWeaponInfo[2] = weaponRModel ~= nil
	self._CurWeaponInfo[3] = self:IsInCombatState() or self:IsDead() -- 武器是否在手中
	if weaponLModel == nil then
		self._CurWeaponInfo[4] = nil
	else
		self._CurWeaponInfo[4] = weaponLModel:GetGameObject()
	end
	if weaponRModel == nil then
		self._CurWeaponInfo[5] = nil
	else
		self._CurWeaponInfo[5] = weaponRModel:GetGameObject()
	end
	-- 设置大小
	local scale = weapon_scale_on_back
	if self._CurWeaponInfo[3] then
		scale = weapon_scale_in_hand
	end
	if not IsNil(self._CurWeaponInfo[4]) then
		self._CurWeaponInfo[4].localScale = scale
	end
	if not IsNil(self._CurWeaponInfo[5]) then
		self._CurWeaponInfo[5].localScale = scale
	end
end

def.method("number").UpdateWeaponInforceLv = function(self,value)
	-- warn("-----------------UpdateInfoceLv---------------value ==  " ,value)
	self._Equipments.WeaponInforceLv = value
	self:UpdateWeaponFx()
end

-- 更新武器特效
def.method().UpdateWeaponFx = function(self)
	local left_back_fx_path, right_back_fx_path, left_hand_fx_path, right_hand_fx_path = Util.GetWeaponFxPaths(self._Equipments.WeaponTid, self._Equipments.WeaponInforceLv)
	-- if left_hand_fx_path == self._OutwardParams._WeaponFxPathLeftBack and right_hand_fx_path == self._OutwardParams._WeaponFxPathRightBack then
	-- 	-- 特效参数没有改变
	-- 	return
	-- end

	local updateParam = ModelParams.new()
	updateParam._IsUpdateWeaponFx = true
	local bShow = self:GetDressEnable()
	local weaponDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Weapon)
	if not bShow or weaponDressInfo == nil then
		-- 不显示时装，或者没有武器时装
		updateParam._WeaponFxPathLeftBack, updateParam._WeaponFxPathRightBack = left_back_fx_path, right_back_fx_path
		updateParam._WeaponFxPathLeftHand, updateParam._WeaponFxPathRightHand = left_hand_fx_path, right_hand_fx_path
	end
	self:UpdateOutward(updateParam, function()
		-- 设置层级
		if not IsNil(self._CurWeaponInfo[4]) then
			GameUtil.SetLayerRecursively(self._CurWeaponInfo[4], self:GetRenderLayer())
		end
		if not IsNil(self._CurWeaponInfo[5]) then
			GameUtil.SetLayerRecursively(self._CurWeaponInfo[5], self:GetRenderLayer())
		end

		raise_outwards_changed_event(self)
	end)
end

-- 通过id 更新翅膀 换模型 
def.method("number", "number").SetWingById = function (self, id, level)
	if id > 0 then
		if id == self:GetCurWingId() then
			local grade_1 =  CWingsMan.Instance():CalcGradeByLevel(self:GetCurWingLevel())
			local grade_2 =  CWingsMan.Instance():CalcGradeByLevel(level)
			if grade_1 == grade_2 then return end
		end
	else
		id, level = 0, 0
	end
	self:SetCurWingData(id, -1, level)
	local pageId = self:GetCurWingPageId()
	self:UpdateWingModel(id, level, pageId)
end

local function GetWingHangPoint(isInHand)
	return "HangPoint_Wing"
end

def.method("number", "number", "number").UpdateWingModel = function (self, wingId, wingLv, wingPageId)
	-- if wingId > 0 then
		-- 更换翅膀
		if self._IsModelHidden then return end
	-- end

	local wingAssetPath = Util.GetWingAssetPath(wingId, wingLv, wingPageId)
	if wingAssetPath == self._OutwardParams._WingAssetPath then
		return
	end

	local updateParam = ModelParams.new()
	updateParam._IsChangeWing = true
	updateParam._WingAssetPath = wingAssetPath
	self:UpdateOutward(updateParam, function ()
		self:SetCurWingModel()

		if self._WingModel ~= nil then
			local go = self._WingModel:GetGameObject()
			if not IsNil(go) then
				GameUtil.SetLayerRecursively(go, self:GetRenderLayer())
			end
		end

		raise_outwards_changed_event(self) -- 发送换装事件
	end)
end

def.method().SetCurWingModel = function (self)
	local model = self:GetOriModel()
	if model ~= nil then
		self._WingModel = model:GetAttach("WingHP")
	end
end

-- 更新翅膀动画
def.override().UpdateWingAnimation = function (self)
	if self._WingModel == nil then return end

	local aniName = ""
	if self:IsOnRide() then
		aniName = EnumDef.CLIP.WING_COMMON_STAND -- 翅膀通用站立动作
	else
		local curState = self:GetCurStateType()
		if curState == FSM_STATE_TYPE.IDLE then
			if self:IsInCombatState() then
				aniName = EnumDef.CLIP.BATTLE_STAND
			else
				aniName = EnumDef.CLIP.COMMON_STAND
			end
		elseif curState == FSM_STATE_TYPE.MOVE then
			if self:IsInCombatState() then
				aniName = EnumDef.CLIP.BATTLE_RUN
			else
				aniName = EnumDef.CLIP.COMMON_RUN
			end
		elseif curState == FSM_STATE_TYPE.SKILL then
			if not self:IsInServerCombatState() and self._SkillHdl:IsInCommonOrLeisureSkill() then
				-- 不在服务器战斗状态，而且正释放通用技能或休闲技能
				aniName = EnumDef.CLIP.COMMON_STAND
			else
				aniName = EnumDef.CLIP.BATTLE_STAND
			end
		end
	end
	local fade_time = self:IsHostPlayer() and EnumDef.SkillFadeTime.HostOther or EnumDef.SkillFadeTime.MonsterOther
	self:PlayWingAnimation(aniName, fade_time, false, 0, 1, true)
end

def.override("string", "number", "boolean", "number", "number", "boolean").PlayWingAnimation = function (self, aniname, fade_time, is_queued, life_time, aniSpeed, is_lock_rotation)
	if self._WingModel == nil or IsNilOrEmptyString(aniname) then return end

	-- warn("PlayWingAnimation id:"..self._ID.." aniname:"..aniname.." fade_time:"..fade_time.." is_queued:"..tostring(is_queued).." life_time:"..life_time.." aniSpeed:"..aniSpeed.." is_lock_rotation:"..tostring(is_lock_rotation), debug.traceback())
	local wingModel = self._WingModel
	if wingModel:HasAnimation(aniname) then
		if is_lock_rotation then
			-- 检测翅膀旋转锁定
			local isPlayingCommon = wingModel:IsPlaying(EnumDef.CLIP.WING_COMMON_STAND) 
			if aniname == EnumDef.CLIP.WING_COMMON_STAND then
				if not isPlayingCommon then
					-- 锁定翅膀YZ轴旋转
					GameUtil.EnableLockWingYZRotation(true, wingModel:GetGameObject(), self:GetOriModel():GetGameObject())
				end
			else
				if isPlayingCommon then
					-- 解锁翅膀YZ轴旋转
					GameUtil.EnableLockWingYZRotation(false, wingModel:GetGameObject(), nil)				
				end
			end
		end
		local prof = self._InfoData._Prof
		if prof == EnumDef.Profession.Aileen or prof == EnumDef.Profession.Archer or prof == EnumDef.Profession.Lancer then
			if aniname == EnumDef.CLIP.BATTLE_STAND then
				-- 艾琳、弓箭手、枪骑士的战斗站立动作需要做特殊处理（相同动画融合）
				wingModel:CloneAnimationState(aniname)
			end
		end
		wingModel:PlayAnimation(aniname, fade_time, is_queued, life_time, aniSpeed)
	end
end

def.override("number", "=>", "string").GetAudioResPathByType = function (self, audio_type) 
    local ret = ""
    if self._ProfessionTemplate then
    	if audio_type == EnumDef.EntityAudioType.DeadAudio then
    		ret = self._ProfessionTemplate.DeadAudioResPath
    	elseif audio_type == EnumDef.EntityAudioType.HurtAudio then
    		ret = self._ProfessionTemplate.HurtAudioResPath 
    	else
    		warn("error occur in GetAudioResPathByType -> an error type : "..tostring(audio_type))
    	end	
    end
    return ret
end

-- 设置通常的外观的模型参数
def.method("table").SetCustomOutward = function (self, info)
	if info == nil then return end

	if self._OutwardParams == nil then
		self._OutwardParams = ModelParams.new()
	end
	local faceAssetPath = OutwardUtil.Get(self._InfoData._Prof, "Face", info.FacialId)
	if type(faceAssetPath) == "string" then
		self._OutwardParams._FacialAssetPath = faceAssetPath
	end
	local hairAssetPath = OutwardUtil.Get(self._InfoData._Prof, "Hair", info.HairstyleId)
	if type(hairAssetPath) == "string" then
		self._OutwardParams._HairstyleAssetPath = hairAssetPath
	end
	self._OutwardParams._SkinColorId = info.SkinColorId
	self._OutwardParams._HairColorId = info.HairColorId
end

def.method().RemoveCombatClearTimer = function (self)
    if self._CombatStateClearTimerId ~= 0 then
    	self:RemoveTimer(self._CombatStateClearTimerId)
    	self._CombatStateClearTimerId = 0
	end
end

def.method().EnterClientCombatState = function(self)
	-- 服务器战斗状态有效，忽略客户端状态
	if self._IgnoreClientStateChange then return end

	self:CheckMountState()
	self:RemoveCombatClearTimer()

	-- 空放技能进战，武器顺切至手上
    -- 如果当前处于非战斗状态，武器顺切至手上
    -- 如果当前处于战斗状态，拔剑过程中，需要顺切至手上
	if self._CombatStateChangeComp ~= nil then
    	self._CombatStateChangeComp:ChangeState(true, true, 0, 0)
    end

    local old_state = self._IsInCombatState
    self._IsInCombatState = true

	if not old_state then
		self:UpdateWingAnimation()
		if not self:IsInExterior() then
			self:PlayCurDressFightFx(EnumDef.PlayerDressPart.Weapon)
		end
	end
end

def.method("boolean").LeaveClientCombatState = function(self, ignoreLerp)
	-- 服务器战斗状态有效，忽略客户端状态
	if self._IgnoreClientStateChange then return end

	-- fight pose
	if self:GetChangePoseState() then 
		return
	end

	self:RemoveCombatClearTimer()

	-- 如果当前处于战斗状态，需要将武器收回到背上
	if self._IsInCombatState then
		if self._CombatStateChangeComp ~= nil then
			if ignoreLerp then
				self._CombatStateChangeComp:ChangeState(true, false, 0, 0)
			else
				local prof = self._InfoData._Prof
				local weapon_pos_change_time = WeaponChangeCfg[prof][3]
				local weapon_scale_change_time = WeaponChangeCfg[prof][2]
				if self._IsInCombatState then
			    	self._CombatStateChangeComp:ChangeState(false, false, weapon_scale_change_time, weapon_pos_change_time)
			    	CSoundMan.Instance():Play3DAudio(WeaponChangeSoundCfg[prof][1], self:GetPos(), 0)
			    end
			end
		end
		if not self:IsInExterior() then
			self:PlayCurDressFightFx(EnumDef.PlayerDressPart.Weapon)
		end
	end

	self._SkillHdl:StopGfxPlay(EnumDef.EntityGfxClearType.BackToPeace)
    self._IsInCombatState = false

	self:UpdateWingAnimation()
end

def.method().DelayLeaveClientCombatState = function(self)
	if not self._IsInCombatState then return end
	self:RemoveCombatClearTimer()
    self._CombatStateClearTimerId = self:AddTimer(5, true, function()
            if not self._IsReady or self._IsReleased or self:IsDead() then return end	    	
            self:LeaveClientCombatState(false)

            if self:IsHostPlayer() then
            	CSoundMan.Instance():ChangeBackgroundMusic(0)
            	self:BeginIdleState()
            end
        end)
end

def.method("boolean").ChangeWeaponHangpoint = function(self, isOnBack)
	self:RemoveCombatClearTimer()
	if not self._IgnoreClientStateChange then 
		self._IsInCombatState = not isOnBack
	end

	if self._CombatStateChangeComp ~= nil then
		self._CombatStateChangeComp:ChangeState(true, not isOnBack, 0, 0)
	end
end

def.method("boolean").EnterServerCombatState = function(self, ignoreLerp)
	local old_state = self._IsInCombatState
	self._IgnoreClientStateChange = true
    self._IsInCombatState = true

    self:CheckMountState()
    -- 进战不下马 武器不切换
    if self:IsOnRide() then
    	return
 	end

   	self:RemoveCombatClearTimer()
   	if not old_state then  -- 从非战斗状态到战斗状态
		if self._CombatStateChangeComp ~= nil then  
			-- 武器位置切换表现
	    	if ignoreLerp then  -- 不需要拔剑，顺切到手
	    		-- bool changeImmediatelly, bool is2Combat, float scaleChangeTime, float hangPointChangeTime
	        	self._CombatStateChangeComp:ChangeState(true, true, 0, 0)
	        else
				local prof = self._InfoData._Prof
	        	local weapon_pos_change_time = WeaponChangeCfg[prof][4]
	    		local weapon_scale_change_time = WeaponChangeCfg[prof][1]
	    		self._CombatStateChangeComp:ChangeState(false, true, weapon_scale_change_time, weapon_pos_change_time)
			    CSoundMan.Instance():Play3DAudio(WeaponChangeSoundCfg[prof][2], self:GetPos(), 0)
	        end
	    end
		self:UpdateWingAnimation()
	    self:PlayCurDressFightFx(EnumDef.PlayerDressPart.Weapon)
	end
end

def.method().LeaveServerCombatState = function(self)
	self._IgnoreClientStateChange = false
	-- 延时5s后 清理战斗表现
	self:DelayLeaveClientCombatState()
end

def.override("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignoreLerp, delay)
	if not self._IsReady then
		self._IsInCombatState = is_in_combat_state
		self._IgnoreClientStateChange = (not is_client_state and is_in_combat_state)
		return
	end
	
	-- TODO: 受控状态下尚未处理 by lj
	if IsNil(self._CombatStateChangeComp) then return end
	
	if is_client_state then
        if is_in_combat_state then 
        	-- 空放技能进战，无拔剑顺切
        	self:EnterClientCombatState()
        else
        	if not delay then
	        	-- 普通技能完后，播放休闲技能/通用技能，无收剑 顺切
	        	self:LeaveClientCombatState(true)
	        else
	        	self:DelayLeaveClientCombatState()
	        end
        end
	else
        if is_in_combat_state then 
        	-- 进仇恨列表，需要拔剑
        	-- 被攻击，无拔剑顺切
            self._SkillHdl:InterruptSpecialSkill()
        	self:EnterServerCombatState(ignoreLerp)
        else
        	-- 服务器脱战后，延时清状态，需要收剑
            self:LeaveServerCombatState()
        end
	end
end

-- 播放当前部位时装进战/脱战特效
def.method("number").PlayCurDressFightFx = function (self, dressPart)
	if not self:GetDressEnable() then return end

	local dressInfo = self:GetCurDressInfoByPart(dressPart)
	self:PlayDressFightFx(dressInfo)
end

-- 播放时装进战/脱战特效
def.method(CDress).PlayDressFightFx = function(self, dressInfo)
	if dressInfo == nil then return end

	if self._FightFx ~= nil then
		self._FightFx:Stop()
		self._FightFx = nil
	end
	local fightFx = CFxMan.Instance():PlayAsChild(dressInfo._Template.FightFxPath, self:GetGameObject(), Vector3.zero, Quaternion.identity, 3, true, -1, self:GetCfxPriority(EnumDef.CFxSubType.ClientFx))
	if fightFx ~= nil then
		local go = fightFx:GetGameObject()
		if not IsNil(go) then
			GameUtil.SetLayerRecursively(go, self:GetRenderLayer())
		end
	end

	self._FightFx = fightFx
end

def.virtual().BeginIdleState = function(self)
end

-- 进入已经死亡的状态
local function EnterDeadState(self)
	self:SetWingVisiState(false)
	-- Player死亡时，需要将武器放在手上（此时与战斗状态时，武器在手上没关系，美术动作这么做的）
	self:ChangeWeaponHangpoint(false)
end

def.override("number", "number", "number", "boolean").OnDie = function (self, killer_id, element_type, hit_type, play_ani)
	CEntity.OnDie(self, killer_id, element_type, hit_type, play_ani)
	EnterDeadState(self)
end

def.override().Dead = function (self)
	CEntity.Dead(self)
	EnterDeadState(self)
end

def.override().OnTransformerModelLoaded = function (self)
	if self._IsReleased then return end

	CEntity.OnTransformerModelLoaded(self)

	-- 下坐骑
    if self:IsOnRide() then
        self:UnRide()
    end

    local curState = self:IsInServerCombatState()

    if self._Model ~= nil and not self:IsDead() then
        if curState then
        	-- 服务器战斗状态中，延续该状态
            self:EnterServerCombatState(true)
        else
        	-- 服务器非战斗状态，客户端状态也清理
        	self:LeaveClientCombatState(true)
        end       
    end
end

def.override().ResetModelShape = function (self)
    if self._TransformID == 0 then
        warn("shape is original , not need to reset")
        return
    end 

    CEntity.ResetModelShape(self)

    local curState = self:IsInServerCombatState()

    if self._Model ~= nil and not self:IsDead() then
    	if curState then
        	-- 服务器战斗状态中，延续该状态
            self:EnterServerCombatState(true)
        else
        	-- 服务器非战斗状态，客户端状态也清理
        	self:LeaveClientCombatState(true)
        end      
    end 
end

def.override("table", "boolean").UpdateFightProperty = function(self, properties, isNotifyFightScore)
	CEntity.UpdateFightProperty(self, properties, isNotifyFightScore)
	
	local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY
	for i,v in ipairs(properties) do
		if v ~= nil and v.Index ~= nil and v.Value ~= nil then
			self._InfoData._FightProperty[v.Index] = {v.Value, 0}
		else
			warn("!!! empty property", v, v.Index, v.Value)
		end
	end

	self:UpdateTopPate(EnumDef.PateChangeType.HP)
	if self._TopPate ~= nil and self._InfoData._MaxStamina > 0 then
		self._TopPate:OnStaChange(self._InfoData._CurrentStamina / self._InfoData._MaxStamina)
	end
end

def.override("table", "boolean").UpdateFightProperty_Simple = function(self, properties, isNotifyFightScore)
    self:UpdateFightProperty(properties, isNotifyFightScore)

 --    local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY
	-- for i,v in ipairs(properties) do
	-- 	if v ~= nil and v.Index ~= nil and v.Value ~= nil then
	-- 		self._InfoData._FightProperty[v.Index] = {v.Value, 0}
	-- 	else
	-- 		warn("!!! empty property", v, v.Index, v.Value)
	-- 	end
	-- end
end

def.method("number").ChangeArmor = function(self, tid)	
	if self._IsModelHidden or tid < 0 then return end
	
	self._Equipments.ArmorTid = tid

	-- 只做数据更新
	if self:IsBodyPartChanged() then
		raise_outwards_changed_event(self)
		return
	end

	-- 更新模型
	local updateParam = ModelParams.new()
	updateParam._Prof = self._InfoData._Prof
	updateParam._Is2ShowDress = self:GetDressEnable()
	local armorDressInfo = self:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Body)
	updateParam:SetArmorParam(tid, armorDressInfo)
	self:UpdateOutward(updateParam, function ()
		raise_outwards_changed_event(self)
	end)
end

def.override("table", "number", "function", "function").Move = function (self, pos, offset, successcb, failcb)
	if self._SkillHdl:IsCastingSkill() then
		local skill_id, perform_idx = self._SkillHdl:GetCurSkillInfo()
		if skill_id > 0 and perform_idx > 0 then
			if CElementSkill.CanMoveWithSkill(skill_id, perform_idx) then
				GameUtil.AddMoveBehavior(self:GetGameObject(), pos, self:GetMoveSpeed(), nil, true)
			end
		end
	else
		self:NormalMove(pos, self:GetMoveSpeed(), offset, successcb, failcb)
	end
end

-- 获取主角的势力ID
def.override("=>", "number").GetFaction = function(self)
    return self._ProfessionTemplate.FactionId
end

--获取罪恶值
def.method("=>", "number").GetEvilValue = function(self)
	return self._InfoData._EvilNum
end
--获取PK模式
def.method("=>", "number").GetPkMode = function(self)
	return self._InfoData._PkMode
end

--获取是否杀戮
def.method("=>", "boolean").IsMassacre = function(self)
	return self._InfoData._PkMode == EPkMode.EPkMode_Massacre
end

--是否有公会
def.method("=>", "boolean").IsInGuild = function(self)
	if string.len(self._Guild._GuildName) == 0 then
		return false
	else
		return true
	end
end

--获取公会名字
def.method("=>", "string").GetGuildName = function(self)
	return self._Guild._GuildName
end

def.override("=>", "number").GetRadius = function (self)
	return self._ProfessionTemplate.CollisionRadius
end


local function GetLevelUpGfxH(prof )
	local y = 1       
	if prof == EnumDef.Profession.Warrior then
    	y = 1.35
	elseif prof == EnumDef.Profession.Aileen then
		y = 1
	elseif prof == EnumDef.Profession.Assassin then
    	y = 1.4
	elseif prof == EnumDef.Profession.Archer then
    	y = 1.4
	end
	return y
end


def.virtual("number", "number", "number", "number").OnLevelUp = function (self, currentLevel, currentExp, currentParagonLevel, currentParagonExp)	
	self._InfoData._Level = currentLevel
	self._InfoData._ParagonLevel = currentParagonLevel
	-- local localPos =Vector3.New(0,GetLevelUpGfxH(self._InfoData._Prof),0)
	local localPos = Vector3.zero -- 新的升级特效不修改高度
	if self._LvUpFx ~= nil then
		self._LvUpFx:Stop()
		self._LvUpFx = nil
	end
	self._LvUpFx = CFxMan.Instance():PlayAsChild(PATH.Gfx_LevelUp, self:GetGameObject(), localPos, Quaternion.identity, 6.5, true, -1, EnumDef.CFxPriority.Always)
	CSoundMan.Instance():Play3DAudio(PATH.GUISound_Effect_LevelUp, self:GetPos(), 0)
end

def.virtual().UpdateTopPateTitleName= function(self)
	if self._TopPate == nil then return end
	if self._InfoData._TitleName == "" then
		self._TopPate:OnTitleNameChange(false,self._InfoData._TitleName)
	else
		self._TopPate:OnTitleNameChange(true,self._InfoData._TitleName)
	end
end

def.virtual().UpdateTopPateGuildName= function(self)
	if self._TopPate == nil then return end
	if self._Guild._GuildName == "" then
		self._TopPate:OnGuildNameChange(false,self._Guild)
	else
		self._TopPate:OnGuildNameChange(true,self._Guild)
	end
end

def.virtual().UpdateTopPateGuildConvoy = function(self)
	if self._TopPate == nil then return end
	self._TopPate:OnGuildConvoyChange(self._InfoData._GuildConvoyFlag)
	if self._InfoData._GuildConvoyFlag < 2 then
		self._TopPate:SetPKIconIsShow(self:GetPkMode() == EPkMode.EPkMode_Massacre)
	end
end

def.virtual().UpdateTopPateRescue= function(self)
	if self._TopPate == nil then return end

	local curLogoType = EnumDef.EntityLogoType.None

	if self:CanRescue() and self:IsFriendly() then 
		curLogoType = EnumDef.EntityLogoType.Rescue
	end
    self._TopPate:OnLogoChange(curLogoType)
end

def.virtual().UpdateTopPateHpLine= function(self)
	if self._TopPate == nil then return end
end

def.virtual().UpdateTopPatePKIcon= function(self)
	if self._TopPate == nil then return end
	self._TopPate:SetPKIconIsShow( self:GetPkMode() == EPkMode.EPkMode_Massacre )
end

--是否敌对
def.virtual("=>", "boolean").IsHostile = function(self)
	return false
end

--是否友善
def.virtual("=>", "boolean").IsFriendly = function(self)
	return false
end

-- 返回角色称号ID 
def.virtual("=>", "number").GetDesignationId = function(self)
	return 0
end

def.override().OnPateCreate = function(self)
	CEntity.OnPateCreate(self)
	if self._TopPate == nil then return end

	self._TopPate:SetHPLineIsShow(true,EnumDef.HPColorType.Green)
	if self._Guild ~= nil and self:IsInGuild() then
		self._TopPate:OnGuildNameChange(true,self._Guild)
	end
	self:UpdateTopPateTitleName()
	self:UpdateTopPateGuildName()
	self:UpdateTopPateGuildConvoy()
	self:UpdateTopPateRescue()
	self:UpdateTopPateHpLine()
	self:UpdateTopPatePKIcon()
	self:UpdatePetName()
end

def.override().CreatePate = function (self)
	local CPlayerTopPate = require "GUI.CPate".CPlayerTopPate
	local pate = CPlayerTopPate.new()
	self._TopPate = pate
	local callback = function()
		self:OnPateCreate()
	end
	pate:Create(self, callback)
end

def.override("number").UpdateTopPate = function (self, updateType)
	CEntity.UpdateTopPate(self, updateType)
	if self._TopPate == nil then return end

	if updateType == EnumDef.PateChangeType.TitleName then
		self:UpdateTopPateTitleName()
	elseif updateType == EnumDef.PateChangeType.GuildName then
		self:UpdateTopPateGuildName()
	elseif updateType == EnumDef.PateChangeType.GuildConvoy then
		self:UpdateTopPateGuildConvoy()
	elseif updateType == EnumDef.PateChangeType.Rescue then
		self:UpdateTopPateRescue()
	elseif updateType == EnumDef.PateChangeType.HPLine then
		self:UpdateTopPateHpLine()
	elseif updateType == EnumDef.PateChangeType.PKIcon then
		self:UpdateTopPatePKIcon()
	end
end

def.override("=>", "boolean").IsRole = function (self)
    return true
end

--获取当前Entiy技能
def.override("number", "=>", "table").GetEntitySkill = function(self, skill_id)
    for i,v in ipairs(self._UserSkillMap) do
		if v.SkillId == skill_id then
			return v.Skill
		end
	end
	return nil
end

-- 返回值：energy type, cur_energy, max_energy
def.override("=>", "number", "number", "number").GetEnergy = function (self)
    if self._InfoData == nil then return -1, 0, 1 end
    
    local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	local SkillEnergyType = require "PB.Template".Skill.SkillEnergyType
    local prof = self._InfoData._Prof
    local energy_type = SkillEnergyType.EnergyTypeMana
    local curIdx, maxIdx = 0, 0

--[[
	if prof == EnumDef.Profession.Warrior then
    	energy_type = SkillEnergyType.EnergyTypeFury
    	curIdx, maxIdx = ENUM.CURRENTFURRY, ENUM.MAXFURY
	elseif prof == EnumDef.Profession.Aileen then
    	energy_type = SkillEnergyType.EnergyTypeMana
    	curIdx, maxIdx = ENUM.CURRENTMANA, ENUM.MAXMANA
	elseif prof == EnumDef.Profession.Assassin then
    	energy_type = SkillEnergyType.EnergyTypeCombo
    	curIdx, maxIdx = ENUM.CURRENTCOMBOPOINT, ENUM.MAXCOMBOPOINT
	elseif prof == EnumDef.Profession.Archer then
    	energy_type = SkillEnergyType.EnergyTypeArrow
    	curIdx, maxIdx = ENUM.CURRENTARROW, ENUM.MAXARROW
	end
]]

	curIdx, maxIdx = ENUM.CURRENTMANA, ENUM.MAXMANA
	if curIdx ~= 0 then
		local max = self._InfoData._FightProperty[maxIdx][1]

		if max <= 0 then max = 1 end
		return energy_type, self._InfoData._FightProperty[curIdx][1], max
	end

	return energy_type, 0, 1
end

-- 设置玩家自定义头像
--[[
def.virtual("number").SetCustomImg = function(self, CustomImg)	
	local path = ""
	if CustomImg == ECustomSet.ECustomSet_Defualt then 	--默认职业头像
		path = ""
		self._InfoData._CustomPicturePath = path
		self._InfoData._CustomImgSet = CustomImg
	elseif CustomImg == ECustomSet.ECustomSet_Review	--审核中
	or CustomImg == ECustomSet.ECustomSet_HaveSet then	--获取自定义头像
		warn("lidaming : Review or HaveSet!!!" , CustomImg)
		local callback = function(strFileName ,retCode, error)	
			if retCode == 0 then
				path =  GameUtil.GetCustomPicDir().."/"..self._ID
				local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
				local msg = C2SCustomImgSet()
				msg.CustomImgSet = ECustomSet.ECustomSet_HaveSet
				PBHelper.Send(msg)
				self._InfoData._CustomImgSet = ECustomSet.ECustomSet_HaveSet
			elseif retCode == 4 then  -- error: 1、参数不匹配 2、没有用户 3、审核中 4、审核未通过 5、文件不存在 6、md5一致
				local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
				local msg = C2SCustomImgSet()
				msg.CustomImgSet = ECustomSet.ECustomSet_Defualt
				PBHelper.Send(msg)
				path = ""
				self._InfoData._CustomImgSet = ECustomSet.ECustomSet_Defualt
			elseif retCode == 6 then
				path =  GameUtil.GetCustomPicDir().."/"..self._ID
				self._InfoData._CustomImgSet = CustomImg
			else
				warn("lidaming DownloadPicture callback retCode == ", retCode, "error == ", error)
				path = ""
				self._InfoData._CustomImgSet = CustomImg
			end				
			self._InfoData._CustomPicturePath = path	

			--头像服和游戏服 头像数据通信之后可更新头像。
			local NotifyPropEvent = require "Events.NotifyPropEvent"
			local event = NotifyPropEvent()
			event.ObjID = self._ID
			event.Type = "CustomImg"
			CGame.EventManager:raiseEvent(nil, event)				
		end
		GameUtil.DownloadPicture(tostring(self._ID), callback)						
	end			
end
]]

def.override("=>","number","number").GetBaseSpeedAndFightSpeed = function(self)
	local baseSpeed = 0 
	local fightSpeed = 0 
	if not self:IsModelChanged() then 
		baseSpeed = self._ProfessionTemplate.MoveSpeed
		fightSpeed = self._ProfessionTemplate.MoveSpeed
	else
		local monsterTid = self._TransformID
		local monsterData = CElementData.GetMonsterTemplate(monsterTid)
		if monsterData == nil then 
			return
		end
		baseSpeed = monsterData.MoveSpeed 
		fightSpeed = monsterData.FightMoveSpeed
	end
    return baseSpeed,fightSpeed
end

--计算马的基础速度
def.method("number","=>","number").GetHorseBaseSpeed = function (self,playerSpeed)
	local horseID = self:GetCurrentHorseId()
    local horseSpeed = playerSpeed + CElementData.GetHorseTemplate(horseID).AddSpeedRatio * playerSpeed
    return horseSpeed
end

def.override("string", "number", "boolean", "number","number").PlayMountAnimation = function(self, aniname, fade_time, is_queued, life_time,aniSpeed)
    if not self._IsReady then return end 
    if self:IsDead() and aniname ~= EnumDef.CLIP.COMMON_DIE then return end
    
    local model = self._MountModel
    if model ~= nil then
        model:PlayAnimation(aniname, fade_time, is_queued, life_time, aniSpeed)
    end
end

--是否是骑乘状态(表现)
def.override("=>", "boolean").IsOnRide = function (self)
    return self._MountTid > 0
end

--获得坐骑TID
def.override("=>", "number").GetMountTid = function (self)
    return self._MountTid
end

def.method("=>", "number").GetPateExtraHeight = function (self)
    local fHeight = 0
    if self:IsOnRide() then
        fHeight = 0.8
    end
    return fHeight
end

def.virtual().UpdateAnimationSpeed = function(self)
	if self:GetCurStateType() ~= FSM_STATE_TYPE.MOVE then return end
	if self:IsInCombatState() then
		local animation,ratePlay = self:CheckRunBattleAnimation(self._ProfessionTemplate.MoveSpeed)
		self:PlayAnimation(animation, 0.2, false, 0, ratePlay)
	else
		local animation,ratePlay = self:CheckRunAnimation(self._ProfessionTemplate.MoveSpeed,self._ProfessionTemplate.MoveSpeed)
		self:PlayAnimation(animation, 0.2, false, 0, ratePlay)
	end
end

def.override("number", "=>", "string", "string", "number").GetEntityFsmAnimation = function (self, fsm_type)
    local animation, wingAnimation = "", ""
    local rate = 1
    if fsm_type == FSM_STATE_TYPE.IDLE then 
		if not self:IsMagicControled() then -- 被魔法控制下不更新站立动作
			if self:IsInCombatState() then
				animation = EnumDef.CLIP.BATTLE_STAND
			else
				animation = EnumDef.CLIP.COMMON_STAND
			end

			if self:GetChangePoseState() then
				local data = nil
				if self:IsInCombatState() then
					data = self:GetChangePoseData(EnumDef.PostureType.FightStandAction)
				else
					data = self:GetChangePoseData(EnumDef.PostureType.StandAction)
				end

				if data and data ~= "" then
					animation = data
				end
			end
		end
    elseif fsm_type == FSM_STATE_TYPE.MOVE then
    	local baseSpeed,fightSpeed = self:GetBaseSpeedAndFightSpeed()     
        if self:IsInCombatState() then                   
            animation, rate = self:CheckRunBattleAnimation(fightSpeed)   
        else
            animation, rate = self:CheckRunAnimation(baseSpeed,fightSpeed)            
        end

        if self:GetChangePoseState() then  
    		local data = nil            
            if self:IsInCombatState() then
                data = self:GetChangePoseData(EnumDef.PostureType.FightMoveAction)
            else
                data = self:GetChangePoseData(EnumDef.PostureType.MoveAction)
            end
            if data and data ~= "" then
                animation = data
                wingAnimation = EnumDef.CLIP.WING_COMMON_STAND
                rate = 1
            end
        end
    else
        warn("only idle & move support in GetEntityFsmAnimation")
    end
    return animation, wingAnimation, rate
end

def.virtual("=>", "boolean").InTeam = function(self)
	return self._TeamId > 0
end

def.virtual("=>", "boolean").IsInExterior = function (self)
	return false
end

def.virtual("string", "=>","string").GetPetColorName = function(self, name)
	return name
end

--宠物ID设置
def.virtual("number").SetPetId = function(self, petId)
	self._PetId = petId
end

def.virtual("=>", "number").GetPetId = function(self)
	return self._PetId
end

def.override("table").SetPos = function(self, pos)
    CEntity.SetPos(self, pos)
end

def.override("table").SetDir = function(self, dir)
    CEntity.SetDir(self, dir)
end

def.virtual().UpdatePetName = function(self)
	if self._PetId > 0 then
		local pet = game._CurWorld:FindObject( self._PetId )
		if pet ~= nil and pet._TopPate ~= nil then
			local colorname = self:GetPetColorName(pet._InfoData._Name)
			pet._TopPate:SetName(colorname)
		end
	end
end

def.virtual("number").SetTeamId = function(self, teamId)
	self._TeamId = teamId
end

def.override("boolean").EnableShadow = function(self, on)
	if not self._IsReady then return end
    self._IsEnableShadow = on

	local realtime = GameUtil.GetShadowLevel() > 0
    if not realtime then
    	CEntity.DoEnableShadow(self, on)
    else
    	CEntity.DoEnableShadow(self, false)
    end
end

def.override().OnResurrect = function(self)
	local EDEATH_STATE = require "PB.net".DEATH_STATE    --死亡状态类型
	self._DeathState = EDEATH_STATE.LIVE
	self:ChangeWeaponHangpoint(true)
	self:Stand()
	self:SetWingVisiState(true)

	if self._ResurrectFx ~= nil then
		self._ResurrectFx:Stop()
	end
	self._ResurrectFx = CFxMan.Instance():PlayAsChild(PATH.Gfx_Resurrect, self:GetGameObject(), Vector3.zero, Quaternion.identity, 2, true, -1, EnumDef.CFxPriority.Always)
end

def.override().Release = function (self)
	self._AllModelReadyCallback = nil
	self._IsMountEnterSight = false

	if self._LvUpFx ~= nil then
		self._LvUpFx:Stop()
		self._LvUpFx = nil
	end
	if self._FightFx ~= nil then
		self._FightFx:Stop()
		self._FightFx = nil
	end
	if self._MountHorseFx ~= nil then
		self._MountHorseFx:Stop()
		self._MountHorseFx = nil
	end
	if self._ResurrectFx ~= nil then
		self._ResurrectFx:Stop()
		self._ResurrectFx = nil
	end
	
	if self._Model ~= nil and self._Model:GetGameObject() ~= nil then
		local obj = self._Model:GetGameObject()
		GameUtil.RemoveFootStepTouch(obj) 
	end
    
    remove_mount_born_ani_timer(self)
    if self._MountModel ~= nil then
    	local mount = self._MountModel:GetGameObject()
		if mount then GameUtil.RemoveFootStepTouch(mount) end

        self._MountModel:Destroy()
    	self._MountModel = nil
    end

    if self._WingModel ~= nil then
        self._WingModel:Destroy()
        self._WingModel = nil
    end    

    self._ChangePoseDate = nil
	CEntity.Release(self)
end

CPlayer.Commit()
return CPlayer