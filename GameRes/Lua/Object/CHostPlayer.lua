local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CPlayer = require "Object.CPlayer"
local CStateMachine = require "FSM.CStateMachine"
local CModel = require "Object.CModel"
local CHUDText = require "GUI.CHUDText"
local CGame = Lplus.ForwardDeclare("CGame")
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CHostSkillHdl = require "Skill.CHostSkillHdl"
local ObjectInfoList = require "Object.ObjectInfoList"
--local CHostAIHdl = require "AI.CHostAIHdl"
local JudgementHitType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitType
local CCooldownHdl = require "ObjHdl.CCooldownHdl"
local CHostOpHdl = require "ObjHdl.CHostOpHdl"
local CElementData = require "Data.CElementData"
local ObjectDieEvent = require "Events.ObjectDieEvent"
local EntityDisappearEvent = require "Events.EntityDisappearEvent"
local PackageChangeEvent = require "Events.PackageChangeEvent"
local CombatStateChangeEvent = require "Events.CombatStateChangeEvent"
local UserData = require "Data.UserData".Instance()

local SkillTriggerEvent = require "Events.SkillTriggerEvent"
local EWorldType = require "PB.Template".Map.EWorldType
local EPlaceType = require "PB.Template".SkillMastery.EPlaceType
local CSharpEnum = require "Main.CSharpEnum"
local CPackage = require "Package.CPackage"
local CPetPackage = require "Pet.CPetPackage"
local CGuild = require "Guild.CGuild"

local CTargetDetector = require "ObjHdl.CTargetDetector"
local EDEATH_STATE = require "PB.net".DEATH_STATE    --死亡状态类型
local NotifyEnterRegion = require "Events.NotifyEnterRegion"
local ECustomSet = require "PB.data".ECustomSet
local PBHelper = require "Network.PBHelper"
local CPanelUIHead = require "GUI.CPanelUIHead"
local CQuest = require "Quest.CQuest"
local CPanelInExtremis = require "GUI.CPanelInExtremis"
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CTeamQuickCheck = require "Team.CTeamQuickCheck"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFSMStateBase = require "FSM.CFSMStateBase"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local EquipRetDotUpdateEvent = require "Events.EquipRetDotUpdateEvent"
local PetRetDotUpdateEvent = require "Events.PetRetDotUpdateEvent"
local MapBasicConfig = require "Data.MapBasicConfig"
local CFxObject = require "Fx.CFxObject"

local CHostPlayer = Lplus.Extend(CPlayer, "CHostPlayer")
local def = CHostPlayer.define

def.field("boolean")._IsFollowingServer = false
def.field("boolean")._IsAutoPathing = false
def.field("table")._NavTargetPos = nil -- 
def.field("boolean")._IsTransPortal = false --传送门传送
def.field("boolean")._IsHaveTransOffset = false --传送是否有偏移

--def.field("number")._TargetDetectTimerID = 0
def.field(CHostOpHdl)._OpHdl = nil
def.field(CPackage)._Package = nil
def.field(CPetPackage)._PetPackage = nil

def.field("table")._CurrentRegionIds = BlankTable
def.field("boolean")._IsAutoFighting = false
def.field("table")._HorseListIds = BlankTable

def.field("table")._PetList = BlankTable			--宠物总列表		
def.field("table")._CurrentHelpPetList = BlankTable --助战宠物列表, list.count 为宠物开放槽个数, ID = 0 的宠物, 默认为 未设置
def.field("number")._CurrentFightPetId = 0			--当前出战宠物，

def.field("number")._EquipedPotionId = 0    		-- 0 no thing equiped
def.field("number")._3V3RoomID = 0    --3V3房间号
def.field("number")._EliminateRoomID = 0 -- 无畏战场房间号
def.field("number")._MineGatherId = 0       -- 正在采集的矿物ID 欢呼中也存在

def.field(CEntity)._CurTarget = nil        -- CHostPlayer
def.field("boolean")._IsTargetLocked = false    
def.field("table")._HatedEntityMap = BlankTable

-----------------------------------------------------------
-- 【主角技能相关信息】

-- 角色技能动态数据信息
-- { SkillId = id, SkillLevel = lv, TalentAdditionLevel = tlv, Skill = 修改后的模板数据, SkillRuneInfoDatas = 纹章数据}
--def.field("table")._UserSkillMap  -- 定义在基类中

-- 主角所属职业的技能学习条件
-- {技能1学习条件，技能2学习条件，... , 技能N学习条件}
def.field("table")._SkillLearnCondition = BlankTable

-- 主角所属职业的技能升级条件
-- {skillId1 = {学习条件}, skillId2 = {学习条件}, .. , skillIdn = {学习条件}}
def.field("table")._SkillLevelUpCondition = BlankTable

-- UI主技能列表
-- [槽1技能TID, 槽2技能TID, .. , 槽8技能TID]
def.field("table")._MainSkillIDList = nil

-- 主角技能学习状态
-- [槽1技能是否学习, 槽2技能是否学习, .. , 槽8技能是否学习]
def.field("table")._MainSkillLearnState = BlankTable

-- 变身技能
def.field("table")._ChangedSkillMap = nil
def.field("table")._ActivePreSkills = nil
--技能符文配置
def.field("number")._ActiveRuneConfigId = 0
----------------------------------------------------------

-- 操作事件缓存，可为技能或者移动
def.field("function")._CachedAction = nil 

def.field("number")._TimerNavMountHorse = 0 			--自动上马逻辑的tick timer
def.field("number")._TimerBloodDetect = 0 			--自动上马逻辑的tick timer
def.field("boolean")._CanNotifyErrorMountHorse = false 	--只有主动上马时才能给予反馈提示
def.field("table")._CheckDestPosition = nil 			--寻路上马

def.field("boolean")._IsHawkEyeEnable = false --是否鹰眼可以使用
def.field("boolean")._IsHawkEyeState = false --是否鹰眼开启
def.field("boolean")._IsHawkEyeEffectIsOver = true --是否鹰眼过度效果是否结束
def.field("number")._HawkEyeCount = 0
def.field("table")._TableHawkEyeTargetPos = nil
def.field("number")._TimerIdHawkEyeEffect = 0
def.field("number")._IdleAnimationTimer = 0 --休闲动作待机timer
def.field("number")._IdleStateTimer = 0 --进入休闲状态timer
def.field("boolean")._IsIdleState = false   --休闲状态
def.field("boolean")._IsRideBlur = false   -- 坐骑motion blur
def.field("table")._TableRandomTime = nil --待机随机时间
def.field("table")._SkillMasteryInfo = nil 
def.field("number")._MasteryFightScore = 0 
def.field("boolean")._IsForbidDrug = false

def.field("function")._OnObjectDisable = nil
def.field("function")._OnPackageUpdate = nil
def.field("function")._OnQuestCommon = nil
def.field("boolean")._ShowFightScoreBoard = true

-- 静态数据
def.field("boolean")._IsMedicalAutoUse = true -- 是否开启自动使用药水
def.field("boolean")._IsAutoUseLowLvDrug = true   -- 低等级还是高等级排序药水
def.field("number")._AutoUseDrugPercent = 0.5   -- 自动使用药水的血量（0.3/0.5/0.7）
def.field("boolean")._IsClickGroundMove = true     -- 是否开启点地移动

--李卓伦：红点需求，不刷新主界面了。暂时注释，怕又改回来 2018.05.30 
--李卓伦：红点需求，添加刷新主界面了。暂时解开注释，果然回来了 2018.08.27
def.field("function")._OnEquipRetDotUpdateEvent = nil
def.field("function")._OnPetRetDotUpdateEvent = nil

def.field("userdata")._BipSpine = nil
def.field(CFxObject)._TransOutFx = nil

def.field("number")._ServerZoneId = 0
def.field("number")._RoleCreateTime = 0 	-- 角色创建时间
def.field("number")._RoleLevelMTime = 0 	-- 角色等级变化时间

local CHECK_HORSE_DISTANCE = 18

def.static("=>", CHostPlayer).new = function ()
	local obj = CHostPlayer()
	obj._FSM = CStateMachine.new()
	obj._SkillHdl = CHostSkillHdl.new(obj)
	obj._CDHdl = CCooldownHdl.new(obj)
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._OpHdl = CHostOpHdl.new(obj)
	obj._InfoData = ObjectInfoList.CHostPlayerInfo()
	obj._Package = CPackage.new()
	obj._PetPackage = CPetPackage.new()
	obj._Guild = CGuild.new()
	obj:ListenEvents()
	obj._UserSkillMap = {}
	obj._CurWeaponInfo = {}
	return obj
end

def.override("table").Init = function (self, info)
	self._ID = info.Id

	--print("HostPlayer ID: ", self._ID)

	local hp_info = self._InfoData
	hp_info._Prof = info.Profession
	hp_info._Name = info.Name
	hp_info._Level = info.Level
	hp_info._Gender = info.Gender
	hp_info._Exp  = info.Exp
	hp_info._CurShield = info.ShieldValue
	hp_info._PkMode  = info.PkMode
	hp_info._EvilNum = info.EvilNum
	hp_info._CustomImgSet = info.CustomImgSet
	self._CampId = info.CampID
	hp_info._Arena3V3Stage = info.Stage
    hp_info._Arena3V3Star = info.StageStar
	hp_info._ArenaJJCScore = 0
    hp_info._EliminateScore = info.EliminateScore or 0
	hp_info._WorldChatCount = info.WorldChatCount
	hp_info._RoleResources = {}
	hp_info._GloryLevel  = info.GloryLevel
	self._EnemyCampTable = info.EnemyCampList
	hp_info._GuildConvoyFlag = info.GuildConvoyFlag
	for i,v in ipairs(info.RoleResources) do 
		hp_info._RoleResources[v.ResourceType] = v.Value
	end
	-- 隐藏获取自定义头像
	-- self:SetCustomImg(hp_info._CustomImgSet)
	self._DeathState = info.DeathState
	self._3V3RoomID = 0
    game._CAuctionUtil:SetAuctionRefCount(info.MarketRefCount)
	self._Package._GoldCoinCount = info.Gold
	self._Package._BindDiamondCount = info.BindDiamond
    self._Package._GreenDiamondCount = info.MarketDiamond
    self._IsInCombatState = info.CombatState
    self._IgnoreClientStateChange = info.CombatState
	do
		--pet
		self._PetPackage:Init(info.petCellInfo)
		--目前就一个出战宠物，所以写一个ID 以后是List后续修改
		local fightPetId = 0
		for i,v in ipairs(info.petCellInfo.fightCellDetails) do
			fightPetId = v
		end
		self:SetCurrentFightPetId(fightPetId)
		self:SetPetId(fightPetId)
		for i,v in ipairs(info.petCellInfo.helpCellDetails) do
			self:SetCurrentHelpPetList(v, i)
		end
	end

	game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold = info.Gold
	game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].BindDiamond = info.BindDiamond
	game._AccountInfo._Diamond = info.Diamond

	self:UpdateFightProperty(info.FightProperty, false)
	if info.Horse ~= nil then
		self._InfoData._HorseId = info.Horse.HorseID
		self._IsMountingHorse = info.Horse.IsOn
	else
		self._InfoData._HorseId = 0
		self._IsMountingHorse = false
	end


	self._ProfessionTemplate = CElementData.GetProfessionTemplate(self._InfoData._Prof)

	-- 同步加载问题
	self:InitMagicControls(info.MagicControlStates)

	-- 设置影响外观的模型参数，在加载模型前
	local exteriorInfo = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Exterior
	self:SetOutwardDatas(exteriorInfo)

	self:SetEquipedPotion(info.CurrPotionTid)

	self:Load()
	self:InitStates(info.BuffStates)
	self:UpdateSealInfo(info.BaseStates)
	self:InitGatherInfos(info.GatherInfos)
	self:InitStaticSkillData()

	--由于客户端以前实现的是空格子， 服务器已经优化成 Map
	--客户端没时间处理，暂时手动创建空格子，以适应原来逻辑，有时间时修改
	local CInventory = require "Package.CInventory"
	local equipPack = self._Package._EquipPack
	local packageType = IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK
	for i=1,8 do
		local itemTemp = {}
		itemTemp.ItemData = {}
		itemTemp.ItemData.Tid = 0
		itemTemp.Index = i-1
		local item = CInventory.CreateItem(itemTemp)
		item._PackageType = packageType
		equipPack:UpdateItem(item)
	end

	self._ShowFightScoreBoard = true

	self._ServerZoneId = info.ZoneId
	self._RoleCreateTime = LuaUInt64.ToDouble(info.RoleCreateTime)
	self._RoleLevelMTime = LuaUInt64.ToDouble(info.RoleLevelMTime)
end

--断线重连后调用
def.method("table").ResetServerState = function (self, info)
	--warn("断线重连后调用")
	self._ShowFightScoreBoard = true
	self:UpdateFightProperty(info.FightProperty, false)
	-- 骑乘信息
	self._CanNotifyErrorMountHorse = false
	if info.Horse ~= nil then
		self._InfoData._HorseId = info.Horse.HorseID
		self._IsMountingHorse = info.Horse.IsOn
	else
		self._InfoData._HorseId = 0
		self._IsMountingHorse = false
	end

	local oldDeadState = self:IsDead()
	self._DeathState = info.DeathState
	local newDeadState = self:IsDead()

	if oldDeadState ~= newDeadState then
		if newDeadState then
			-- 断线期间死亡
			self:Dead()
		else
			-- 断线期间复活
			self:OnResurrect()
		end
	end

	self:MountOn(self._IsMountingHorse)
	self:InitStates(info.BuffStates)
	self:SetEquipedPotion(info.CurrPotionTid)
    -- 初始化buff图标
    local CPanelUIHead = require 'GUI.CPanelUIHead'
    if CPanelUIHead and CPanelUIHead.Instance():IsShow() then
        CPanelUIHead.Instance():InitFrameBuff()
    end
    
	if not info.CombatState then
		self:LeaveClientCombatState(true)
	else
		self:EnterServerCombatState(true)
	end
end

def.method().ListenEvents = function(self)
	local function OnObjectDisable(sender, event)
	 	if self._CurTarget ~= nil and event._ObjectID == self._CurTarget._ID then				
			self:UpdateTargetInfo(nil, false)
			
			local target = CTargetDetector.Instance():Detect()
			self:UpdateTargetInfo(target, false)
	 	end
	end

	CGame.EventManager:addHandler(ObjectDieEvent, OnObjectDisable)	
	CGame.EventManager:addHandler(EntityDisappearEvent, OnObjectDisable)

	local function OnPackageUpdate(sender, event)
		local net = require "PB.net"

		if event.PackageType == net.BAGTYPE.BACKPACK then
			-- 普通背包

			-- 更新菜单红点
			do
				-- 飞翼养成
				local CWingsMan = require "Wings.CWingsMan"
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.WingDevelop, CWingsMan.Instance():IsShowRedPoint())
			end
		-- elseif event.PackageType == net.BAGTYPE.ROLE_EQUIP then
		-- 	-- 装备背包
		-- 	local template = require "PB.Template"
		-- 	local equipPack = self._Package._EquipPack
		-- 	local equips = {}
		-- 	local armoritem = equipPack:GetItemBySlot(template.Item.EquipmentSlot.Armor)
		-- 	if armoritem ~= nil then
		-- 		equips.ArmorTid = armoritem._Tid
		-- 	else
		-- 		equips.ArmorTid = 0
		-- 	end

		-- 	local weaponitem = equipPack:GetItemBySlot(template.Item.EquipmentSlot.Weapon)
		-- 	if weaponitem ~= nil then
		-- 		equips.WeaponTid = weaponitem._Tid
		-- 	else
		-- 		equips.WeaponTid = 0
		-- 	end

		-- 	self:ShowEquipments(equips)
		end
	end

	local function OnNotifyLeaveCurrentMap(sender, event)
		self:Stand()
	end

	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageUpdate)	

	self._OnObjectDisable = OnObjectDisable
	self._OnPackageUpdate = OnPackageUpdate

	--任务完成后 提示玩家组队
	local function OnQuestCommonEvent(sender, event)
		if event._Name == EnumDef.QuestEventNames.QUEST_RECIEVE then
			local targetRoomIDs = CTeamQuickCheck.CheckQuestQuickTeam(event._Data.Id)
			local count = 0  
			for k,v in pairs(targetRoomIDs) do  
			    count = count + 1  
			end  
			if count > 0 then
				-- print("====================")
				-- print_r(targetRoomIDs)
				game._GUIMan:Open("CPanelQuickTeam", targetRoomIDs)
			end
		end 
	end
	CGame.EventManager:addHandler("QuestCommonEvent", OnQuestCommonEvent)
	self._OnQuestCommon = OnQuestCommonEvent
end

def.method().UnlistenEvents = function(self)
	if self._OnObjectDisable ~= nil then
		CGame.EventManager:removeHandler(ObjectDieEvent, self._OnObjectDisable)	
		CGame.EventManager:removeHandler(EntityDisappearEvent, self._OnObjectDisable)
	end

	if self._OnPackageUpdate ~= nil then
		CGame.EventManager:removeHandler(PackageChangeEvent, self._OnPackageUpdate)
	end

	self._OnObjectDisable = nil
	self._OnPackageUpdate = nil

	if self._OnQuestCommon ~= nil then
		CGame.EventManager:removeHandler('QuestCommonEvent', self._OnQuestCommon)
	end
	self._OnQuestCommon = nil

	--李卓伦：红点需求，不刷新主界面了。暂时注释，怕又改回来 2018.05.30 
	--李卓伦：红点需求，添加刷新主界面了。暂时解开注释，果然回来了 2018.08.27
	--李卓伦：红点需求，装备红点需求删除。暂时删除，怕又加回来。2018.10.29
	if self._OnPetRetDotUpdateEvent ~= nil then
		CGame.EventManager:removeHandler(PetRetDotUpdateEvent, self._OnPetRetDotUpdateEvent)
	end
	self._OnPetRetDotUpdateEvent = nil
end

def.method().Load = function (self)
	self._OutwardParams = self:GetModelParams()

	local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
	self._Model = m
	m:LoadWithModelParams(self._OutwardParams, function()
			self:OnLoad()
		end)
end

def.method().OnLoad = function (self)
	if self._HUDText == nil then
		local CHUDText = require "GUI.CHUDText"
    	self._HUDText = CHUDText.new(self)
	end

	local go = self._Model._GameObject
	go.name = "Model"
	self:AddObjectComponent(true, 0.5)
	GameUtil.OnHostPlayerCreate(self._GameObject)

	GameUtil.AddFootStepTouch(go)

	GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.HostPlayer)

	self:SetCurWeaponInfo()
	self:SetCurWingModel()

	self._IsReady = true
	self:OnModelLoaded()	

	self._IsMountEnterSight = self:IsServerMounting()
	self:MountOn(self:IsServerMounting())

	self:StartAutoDetectTarget()
	--self:EnableShadow(true)

	self._CombatStateChangeComp = go:GetComponent(ClassType.CombatStateChangeBehaviour)
	if self._CombatStateChangeComp == nil then
		self._CombatStateChangeComp = go:AddComponent(ClassType.CombatStateChangeBehaviour)
	end
	self._CombatStateChangeComp:ChangeState(true, self._IsInCombatState, 0, 0)

	self:AddBloodDetecter()
	
	if self:IsDead() then
		-- Dead 方法有修改战斗状态的逻辑，注意时序
		self:Dead()		
	else
		self:Stand()
	end

	--李卓伦：红点需求，不刷新主界面了。暂时注释，怕又改回来 2018.05.30 
	--李卓伦：红点需求，添加刷新主界面了。暂时解开注释，果然回来了 2018.08.27
	--李卓伦：红点需求，装备红点需求删除。暂时删除，怕又加回来。2018.10.29
	local function DoPetRetDotUpdateEvent()
		local CPetUtility = require "Pet.CPetUtility"
		CPetUtility.UpdatePetRedDot()
	end
	local function OnPetRetDotUpdateEvent(sender, event)
		DoPetRetDotUpdateEvent()
	end
	DoPetRetDotUpdateEvent()
	CGame.EventManager:addHandler(PetRetDotUpdateEvent, OnPetRetDotUpdateEvent)
	self._OnPetRetDotUpdateEvent = OnPetRetDotUpdateEvent

	self:InitHostPlayerConfig()	
end

-- 模型加载完成后刷新脚底光圈
def.override().OnModelLoaded = function (self)
	CPlayer.OnModelLoaded(self)		

	self:EnableShadow(true)
end

def.method().InitHostPlayerConfig = function(self)
	-- 药水自动使用
    local isAutoUseHP = UserData:GetField(EnumDef.LocalFields.MedicialAutoUse)
    if isAutoUseHP == nil or type(isAutoUseHP) ~= "boolean" then
        isAutoUseHP = true
    end
    -- 药水使用是低等级还是高等级
    local autoUseLowLv = UserData:GetField(EnumDef.LocalFields.MedicialUseLower)
    if autoUseLowLv == nil or type(autoUseLowLv) ~= "boolean" then
        autoUseLowLv = true
    end
    -- 最小血量使用药水
    local minHPToUseMedic = UserData:GetField(EnumDef.LocalFields.MinHpValueToUseMedic)
    if minHPToUseMedic == nil or type(minHPToUseMedic) ~= "number" or minHPToUseMedic > 1 then
        minHPToUseMedic = 0.5
    end
    local isClickGroundMove = UserData:GetField(EnumDef.LocalFields.ClickGroundMove)
    if isClickGroundMove == nil or type(isClickGroundMove) ~= "boolean" then
        isClickGroundMove = true
    end
    self:UpdateHostPlayerConfig(isAutoUseHP, autoUseLowLv, minHPToUseMedic, isClickGroundMove)
end

def.method().SaveHostPlayerConfig = function(self)
    UserData:SetField(EnumDef.LocalFields.MedicialAutoUse, self._IsMedicalAutoUse)
    UserData:SetField(EnumDef.LocalFields.MedicialUseLower, self._IsAutoUseLowLvDrug)
    UserData:SetField(EnumDef.LocalFields.MinHpValueToUseMedic, self._AutoUseDrugPercent)
    UserData:SetField(EnumDef.LocalFields.ClickGroundMove, self._IsClickGroundMove)
end

def.method("boolean", "boolean", "number", "boolean").UpdateHostPlayerConfig = function(self, isAutoUseHP, isAutoUseLowLv, minHPToUseMedic, isClickGroundMove)
	self._IsMedicalAutoUse = isAutoUseHP
    self._IsAutoUseLowLvDrug = isAutoUseLowLv
    self._AutoUseDrugPercent = minHPToUseMedic
    self._IsClickGroundMove = isClickGroundMove
end

def.method("=>", "boolean", "boolean", "number", "boolean").GetHostPlayerConfig = function(self)
	return self._IsMedicalAutoUse, self._IsAutoUseLowLvDrug, self._AutoUseDrugPercent, self._IsClickGroundMove
end

def.override("number").SetMoveSpeed = function(self, speed)
    if self._InfoData ~= nil then
  		local curSpeed = self._InfoData._MoveSpeed
    	CEntity.SetMoveSpeed(self, speed)
    --[[
    	
        self._InfoData._MoveSpeed = speed
	]]
        if self._GameObject ~= nil then
            GameUtil.SetMoveBehaviorSpeed(self._GameObject, speed)
        end 

        if curSpeed	~= speed then
    		local cMap = require "GUI.CPanelMap"	      
        	if cMap.Instance():IsShow() then
        		cMap.Instance():ChangeAutoPathing()
        	end
    	end   	
    end
end

def.method().InitStaticSkillData = function(self)
	local prof = self._InfoData._Prof
	local CElementSkill = require "Data.CElementSkill"

	self._MainSkillIDList = {0, 0, 0, 0, 0, 0, 0, 0}
	local allSkillLearnCondition = GameUtil.GetAllTid("SkillLearnCondition")
	for i, v in ipairs(allSkillLearnCondition) do
		local learnCondition = CElementSkill.GetLearnCondition(v)
		if learnCondition.Profession == prof then
			self._SkillLearnCondition[learnCondition.SkillId] = learnCondition

			local index = learnCondition.SkillUIPos
			if index >= 1 and index <= 8 then
				self._MainSkillIDList[index] = learnCondition.SkillId
			end
		end
	end

	local tids = GameUtil.GetAllTid("SkillLevelUpCondition")
	for i, v in ipairs(tids) do
		local sluc = CElementSkill.GetLevelUpCondition(v)
		local isHostSkill = false
		local skillId = sluc.SkillId
		for _, w in ipairs(self._MainSkillIDList) do
			if skillId == w then
				isHostSkill = true
				break
			end
		end
		if isHostSkill then
			if self._SkillLevelUpCondition[skillId] == nil then
				self._SkillLevelUpCondition[skillId] = {}
			end
			local maps = self._SkillLevelUpCondition[skillId]
			maps[#maps + 1] = sluc
		end
	end
end

def.method("number", "=>", "table").GetSkillLearnConditionTemp = function (self, skillId)
	return self._SkillLearnCondition[skillId]
end

def.method("=>", "table").GetAllSkillLearnConditionTemps = function (self)
	return self._SkillLearnCondition
end

def.method("number", "=>", "table").GetSkillLevelUpConditionMap = function (self, skillId)
	return self._SkillLevelUpCondition[skillId]
end

def.override().OnPateCreate = function(self)
    CPlayer.OnPateCreate(self)
	if self._TopPate == nil then return end

	-- local Designation = game._DesignationMan:GetDesignationDataByID( game._DesignationMan:GetCurDesignation() )
	-- if Designation ~= nil then
	-- 	self._TopPate:OnTitleNameChange(true,Designation.Name)
	-- end
	self._TopPate:SetHPLineIsShow(self:In1V1Fight() or
								  self:In3V3Fight() or
								  self:InEliminateFight(), EnumDef.HPColorType.Green)
end

def.override().UpdateTopPateHpLine = function(self)
	if self._TopPate ~= nil then
		self._TopPate:SetHPLineIsShow(self:In1V1Fight() or
									  self:In3V3Fight() or
									  self:InEliminateFight(), EnumDef.HPColorType.Green)
	end
end

def.override().UpdateTopPateRescue= function(self)
    --主角不显示
end

def.override("number", "number", "boolean", "number").OnHurt = function(self, damage, attacker_id, is_critical_hit, elem_type)
	local hud_type = is_critical_hit and EnumDef.HUDType.under_attack_crit or EnumDef.HUDType.under_attack_normal
    if hud_type > -1 then
    	if self._HUDText == nil then
	        self._HUDText = CHUDText.new(self)
	    end
	    self._HUDText:Play(hud_type, -damage)
    end

	self._SkillHdl:OnHostBeHitted()
	if self._IsInCombatState then
		--战斗中 正在服务 并且 没有可以在战斗中使用的服务 则退出
		if self._OpHdl._CurServiceNPC ~= nil and not self._OpHdl._CurServiceNPC:IsBattleUseServer() then
			game._GUIMan:ShowTipText(StringTable.Get(19413), false)
			self._OpHdl:EndNPCService(nil)
		end
	end
end

def.method("table").InitGatherInfos = function (self, data)
	self._InfoData._GatherInfos = {}
	for i,v in pairs(data) do
		if v and v.MineTid and v.MineTid > 0 then
			self._InfoData._GatherInfos[v.MineTid] = v.GatherNum
		end
	end
end

def.method("number","number").AddGatherNum = function (self,mineTid,num)
	
	if self._InfoData._GatherInfos[mineTid] == nil then
		self._InfoData._GatherInfos[mineTid] = 0
	end
	self._InfoData._GatherInfos[mineTid] = self._InfoData._GatherInfos[mineTid] + num

	-- 判断更新是否可以改变可采集状态
	local mineobj = game._CurWorld._MineObjectMan:GetByTid(mineTid)
	if mineobj ~= nil then
		mineobj:UpdateCanGatherGfx()
	end
end

def.method("number","=>","number").GetGatherNum = function (self,mineTid)
	local num = self._InfoData._GatherInfos[mineTid]
	if num == nil then
		num = 0
	end
	return num 
end

--获得坐骑列表
def.method("=>", "table").GetHorseList = function (self)
	return self._HorseListIds
end

-- 血量检测timer
local NEW_ROLE_UNLOCKED = 79
def.method().AddBloodDetecter = function (self)
	-- 使用药品 血量检测
	local function Try2UseDrug()
	    -- 禁止使用药瓶	    
	    if game:IsCurMapForbidDrug() or not self._IsMedicalAutoUse then
	        return
	    end

	    -- 新手副本
	    if not game._CFunctionMan:IsUnlockByFunTid(NEW_ROLE_UNLOCKED) then
	    	return
	    end

	    if self:IsDead() then
	        return
	    end

	    if self:GetForbidDrugState() then
	    	return
	    end

	    local percent = self._InfoData._CurrentHp / self._InfoData._MaxHp
	    if percent < self._AutoUseDrugPercent  then
	        local normalPack = self._Package._NormalPack
	        local equip_drug_id = self:GetEquipedPotion()                
	        local drug = normalPack:GetItem(equip_drug_id)
	        if drug and drug:CanUse() == EnumDef.ItemUseReason.Success  then                               
	            if not self._CDHdl:IsCoolingDown(drug._CooldownId) then
	                drug:Use()
	            end
	        end    
	    end
	end

	-- remove
	if self._TimerBloodDetect > 0 then
		self:RemoveBloodDetecter()
	end

	self._TimerBloodDetect = self:AddTimer(1, false , Try2UseDrug)
end

-- 手动移除 正常销毁走统一的接口
def.method().RemoveBloodDetecter = function (self)
	self:RemoveTimer(self._TimerBloodDetect)
	self._TimerBloodDetect = 0
end

--初始化坐骑列表，服务器同步后会被重置
def.method("table").InitHorseList = function (self, data)
	self._HorseListIds = {}
	for i,v in ipairs(data) do
		table.insert(self._HorseListIds, v.HorseTID)
	end
end

--更新坐骑列表，增加or删除
def.method("boolean", "number").UpdateHorseList = function (self, bIsAdd, horseId)
	local index = table.indexof(self._HorseListIds, horseId)

	if bIsAdd then
		if not index then
			table.insert(self._HorseListIds, horseId)
		end
	else
		if index then
			table.remove(self._HorseListIds, index)
		end
	end
end

def.method("=>", "boolean").IsInCanNotInterruptSkill = function (self)
    local cur_fsm_state = self:GetCurStateType()
	if cur_fsm_state == FSM_STATE_TYPE.SKILL then 
		return not self._SkillHdl:IsInSkillCanInterruptByCombat()
	end

	return false
end

def.method("=>", "boolean").IsInCanInterruptSkill = function (self)
    local cur_fsm_state = self:GetCurStateType()
	if cur_fsm_state == FSM_STATE_TYPE.SKILL then 
		return self._SkillHdl:IsInSkillCanInterruptByCombat()
	end

	return false
end

--能否上马
def.override("=>", "boolean").CanRide = function (self)
    if (self:IsDead() or not self._IsReady) then
    	self._CanNotifyErrorMountHorse = false
        return false
    end

    local cur_fsm_state = self:GetCurStateType()
    if self:IsInServerCombatState() or self:IsInCanNotInterruptSkill() then
    	--战斗状态 或 非特殊技能，不能骑乘
		if self._CanNotifyErrorMountHorse then
			game._GUIMan:ShowTipText(StringTable.Get(15509), false)
			self._CanNotifyErrorMountHorse = false
		end
		return false
    end

	if cur_fsm_state == FSM_STATE_TYPE.BE_CONTROLLED or
	   cur_fsm_state == FSM_STATE_TYPE.DEAD or
	   self:IsMagicControled() then
		-- 受控、死亡、被魔法控制状态，不能骑乘
		if self._CanNotifyErrorMountHorse then
			game._GUIMan:ShowTipText(StringTable.Get(15508), false)
			self._CanNotifyErrorMountHorse = false
		end
		return false
	end

    if self:IsModelChanged() then
    	if self._CanNotifyErrorMountHorse then
    		--变身状态不能骑乘
    		game._GUIMan:ShowTipText(StringTable.Get(15554), false)
    		self._CanNotifyErrorMountHorse = false
    	end

    	return false
    end
    
    return true
end

--自动上马距离判定
def.method("table", "=>","boolean").CheckAutoHorse = function(self, checkpos)
	if checkpos == nil then 
		warn("CheckAutoHorse   null null null-----------------------")
		return false
	end

	local posX, posZ = self:GetPosXZ()
	local distance_sqr = SqrDistanceH(posX, posZ, checkpos.x, checkpos.z)
    if distance_sqr >= CHECK_HORSE_DISTANCE * CHECK_HORSE_DISTANCE then return true end

    return false
end

--寻路上马逻辑
def.method("table").NavMountHorseLogic = function (self, destPos)
	local bHasHorseSet = self:GetCurrentHorseId() > 0
	local bIsOn = self:IsServerMounting()

	self._CheckDestPosition = destPos
	local function RemoveTick()
		--warn("RemoveTick...")
		if self._TimerNavMountHorse ~= 0 then
			self:RemoveTimer(self._TimerNavMountHorse)
			self._TimerNavMountHorse = 0
			self._CheckDestPosition = nil
		end
	end

	local function tickMountLogic()
		bIsOn = self:IsServerMounting()
		-- if bIsOn or not self._IsAutoPathing then
		if not self._IsAutoPathing then
			RemoveTick()
			return
		end

		local bCanRideHorse = bHasHorseSet and not bIsOn and self:CanRide()
		if bCanRideHorse and self:CheckAutoHorse(self._CheckDestPosition) then
			SendHorseSetProtocol(-1, true)
		end
	end

	local function AddTick()
		--if self._TimerNavMountHorse > 0 then print("what ??? ") return end
        if self._TimerNavMountHorse ~= 0 then
			self:RemoveTimer(self._TimerNavMountHorse)
			self._TimerNavMountHorse = 0
        end
		-- do once first
		tickMountLogic()
		self._TimerNavMountHorse = self:AddTimer(1, false , tickMountLogic)
	end

	--监测寻路上马状态 tick
	--if not bHasHorseSet or bIsOn or not self._IsAutoPathing then
	if not bHasHorseSet or not self._IsAutoPathing then
		RemoveTick()
	else
		if self:CheckAutoHorse(self._CheckDestPosition) then
			AddTick()
		end
	end
end

def.method("table", "number").SetSkillMasteryInfoList = function (self, infos, fightScore)
	self._SkillMasteryInfo = infos
	self._MasteryFightScore = fightScore
end

def.method("=>","table", "number").GetSkillMasteryInfo = function (self)
	return self._SkillMasteryInfo, self._MasteryFightScore
end

def.method("table").UpdateSkillMasteryInfo = function (self, data)
	if not self._SkillMasteryInfo then return end
	for i = 1, #self._SkillMasteryInfo do
		if data.Tid == self._SkillMasteryInfo[i].NextTid then
		   self._SkillMasteryInfo[i].Tid = data.Tid
		   self._SkillMasteryInfo[i].NextTid = data.NextTid
		end
	end

	self._MasteryFightScore = data.FightScore
end

def.method("number","=>","number").GetTidInRolePackage = function (self,equipSlot)
	local itemSets = self._Package._EquipPack._ItemSet
	for i,v in ipairs(itemSets) do 
		if v._Slot == equipSlot then 
			if v._Tid > 0 then 
				return v._Tid 
			else
				return 0 
			end
		end
	end
	return 0 
end

-- 设置装备的药品
def.method("number").SetEquipedPotion = function (self, potion_id)
	self._EquipedPotionId = potion_id
end

def.method("=>",  "number").GetEquipedPotion = function (self)
	return self._EquipedPotionId
end

def.method("number", "boolean").UpdateActiveSkillList = function(self, skill_id, is_add)
	if not self._ActivePreSkills then
		self._ActivePreSkills = {}
	end

	local match = false
	for i = 1, #self._ActivePreSkills do 
		if self._ActivePreSkills[i] == skill_id and is_add then
			match = true
			break
		-- 删除单个元素 不倒置遍历了
		elseif self._ActivePreSkills[i] == skill_id and not is_add then
			table.remove(self._ActivePreSkills, i)
			return
		end
	end

	if not match then
		table.insert(self._ActivePreSkills, skill_id)
	end
end

def.method("number", "=>","boolean").HasActivePreSkill = function(self, skill_id)
	local ret = false
	if self._ActivePreSkills then
		for i = 1, #self._ActivePreSkills do 
			if self._ActivePreSkills[i] == skill_id then
				ret = true	
				break
			end
		end
	end
	return ret
end

def.override("table").UpdateTransformSkills = function(self, data)
	self._ChangedSkillMap = data
end

def.override("=>", "table").GetTransformSkills = function(self)
    return self._ChangedSkillMap
end

def.method("boolean").SetForbidDrugState = function(self, state)
	self._IsForbidDrug = state
end

def.method("=>", "boolean").GetForbidDrugState = function(self)
	return self._IsForbidDrug
end

def.method("number", "number").UpdateValidSkillInfo = function(self, pos, skillTid)
	if self._SkillHdl == nil then return end
    self._SkillHdl._ValidSkillsInfo[pos] = skillTid
end

--[[=========================================================================================]]
--[[ 宠物Begin ]]

def.method("number", "=>", "boolean").IsFightingPetById = function(self, petId)
	return self._CurrentFightPetId == petId
end
def.method("number", "=>", "boolean").IsHelpingPetById = function(self, petId)
	local bRet = false
	for i=1, #self._CurrentHelpPetList do
		if self._CurrentHelpPetList[i] == petId then
			bRet = true
			break
		end
	end

	return bRet
end

--获取当前出战的宠物ID
def.method("=>", "number").GetCurrentFightPetId = function(self)
	return self._CurrentFightPetId
end

--设置当前出战的宠物ID
def.method("number").SetCurrentFightPetId = function(self, petId)
	if self._CurrentFightPetId == petId then
		--warn("the same petId : SetCurrentFightPetId :", petId)
	else
		--warn("SetCurrentFightPetId  ", petId)
		self._CurrentFightPetId = petId
	end
end

--设置当前助战宠物
def.method("number", "number").SetCurrentHelpPetList = function(self, petId, index)
	if self._CurrentHelpPetList[index] ~= nil and self._CurrentHelpPetList[index] == petId then
		--warn("the same petId : SetCurrentHelpPetList : ", petId)
	else
		--warn("SetCurrentHelpPetList  ", index, petId)
		self._CurrentHelpPetList[index] = petId
	end
end

def.method("=>", "table").GetCurrentHelpPetList = function(self)
	return self._CurrentHelpPetList
end

def.method("number").RestPetById = function(self, petId)
	if petId == self:GetCurrentFightPetId() then
		--出战宠物  休息 = 0
		self:SetCurrentFightPetId(0)
	else
		--助战宠物  休息 = 0
		for i, oldID in ipairs(self:GetCurrentHelpPetList()) do
			if oldID == petId then
				self:SetCurrentHelpPetList(0, i)
				break
			end
		end
	end
end

--[[ 宠物End ]]
--[[=========================================================================================]]


--获取当前目标
def.method("=>", CEntity).GetCurrentTarget = function(self)
	return self._CurTarget
end
--是否处于自动战斗状态
def.method("=>", "boolean").IsAutoFighting = function(self)
	return self._IsAutoFighting
end
--主角释放技能
def.method("number", "=>", "boolean").UseSkill = function(self, skillId)
	if self._SkillHdl == nil or skillId == 0 then return false end
	return self._SkillHdl:CastSkill(skillId, false)
end
def.method("number", "=>", "boolean").HasEnoughGolds = function(self, needGolds)
    return self._Package._GoldCoinCount >= needGolds
end

def.method("number", "=>", "boolean").HasEnoughDiamonds = function(self, needDiamonds)
    return game._AccountInfo._Diamond + self._Package._BindDiamondCount >= needDiamonds
end

def.method("number", "=>", "boolean").HasEnoughBindDiamonds = function(self, needDiamonds)
    return self._Package._BindDiamondCount >= needDiamonds
end

def.method("number", "=>", "boolean").HasEnoughGreenDiamonds = function(self, needGDiamonds)
    return self._Package._GreenDiamondCount >= needGDiamonds
end

def.method("number", "=>", "number").GetMoneyCountByType = function(self, moneyType)
	local EResourceType = require "PB.data".EResourceType
	local iHave = 0

	if moneyType == EResourceType.ResourceTypeGold then
		iHave = self:GetGolds()
	elseif moneyType == EResourceType.ResourceTypeAllDiamond then
		iHave = self:GetAllDiamonds()
	elseif moneyType == EResourceType.ResourceTypeDiamond then
		iHave = self:GetDiamonds()
	elseif moneyType == EResourceType.ResourceTypeBindDiamond then
		iHave = self:GetBindDiamonds()
    elseif moneyType == EResourceType.ResourceTypeMarketDiamond then
        iHave = self:GetGreenDiamond()
	else
		iHave = self._InfoData._RoleResources[moneyType]
	end

	return iHave
end

def.method("number", "number", "=>", "boolean").HasEnoughTokenMoneyByType = function(self, moneyType, needCount)
    return self:GetMoneyCountByType(moneyType) >= needCount
end

def.method("=>", "number").GetDiamonds = function(self)
    return game._AccountInfo._Diamond
end

def.method("=>", "number").GetBindDiamonds = function(self)
    return self._Package._BindDiamondCount
end

def.method("=>", "number").GetGreenDiamond = function(self)
    return self._Package._GreenDiamondCount
end

def.method("=>", "number").GetAllDiamonds = function(self)
    return game._AccountInfo._Diamond + self._Package._BindDiamondCount
end

def.method("=>", "number").GetGolds = function(self)
    return self._Package._GoldCoinCount
end

def.method().StartAutoDetectTarget = function(self)
	CTargetDetector.Instance():Start()
end

def.method().StopAutoDetectTarget = function(self)
	CTargetDetector.Instance():Stop()
end

-- 游戏内重连成功后，需要重置的相关数据
def.method().Reset = function (self)
	self:StopAutoLogic()

	CAutoFightMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CQuestAutoMan.Instance():Stop()

    self:SetTransPortalState(false)
    self._OpHdl:EndNPCService(nil)
    self:UpdateTargetInfo(nil, false)
    CTargetDetector.Instance():Reset()

    -- TODO：需要确认游戏内重连，服务器同步了哪些信息 ！！！
    --[[
	_SkillHdl 
	_CDHdl 
	_HitEffectInfo 
	
	]]

    self._HatedEntityMap = {}
    self._CachedAction = nil
    self._ChangedSkillMap = nil
    self._ActivePreSkills = nil  
    self._MineGatherId = 0  
    self._IsForbidDrug = false  
    
end

-- 清理基于大世界的逻辑
def.method().HalfRelease = function (self)
	self:Reset()
	self:UnlistenEvents()
	CTargetDetector.Instance():Clear()
	--self:ClearEntityEffect() --只清理Rim效果是不可以的，所有的EntityEffect都应该清理掉
    if self._TopPate ~= nil then 
        self._TopPate:Release() 
        self._TopPate = nil
    end

    for i, v in ipairs(self._BuffStates) do
        v:Release()
    end
    self._BuffStates = {}

    if self._TransOutFx ~= nil then
    	self._TransOutFx:Stop()
    end

    if self._SealInfo then
        self._SealInfo:Release()
        self._SealInfo = nil
    end

    if self._MagicControlinfo then
        self._MagicControlinfo:Release()
        self._MagicControlinfo = nil
    end

    if self._SkillHdl then
        self._SkillHdl:Release()
        self._SkillHdl = nil
    end

    if self._CDHdl then
        self._CDHdl:Release()
        self._CDHdl = nil
    end

    self:EnableShadow(false)
    if self._IsStealth then
        self:Stealth(false)
    end
    
    if self._HUDText ~= nil then
        self._HUDText:Release()
        self._HUDText = nil
    end

    self:ClearIdleState()
    
    self._CurTarget = nil
    --self._TableEnterMapRegionTips = nil 
	-- 关闭濒死效果	
	--warn("TERA-3155 跟踪 - 濒死效果结束", num)
	if CPanelInExtremis.Instance():IsShow() then
		-- warn("lidaming3 --->>> TERA-3155 跟踪 - 濒死效果结束", num)
		game._GUIMan:Close("CPanelInExtremis")  -- 关闭濒死音乐的时候背景音乐还原。
		CSoundMan.Instance():SetHealthVolume(1)
		CSoundMan.Instance():Play2DHeartBeat("", 0)
	end
	
	self._SkillMasteryInfo = nil
	self._MasteryFightScore = 0

	self._MainSkillIDList = {}
	self._MainSkillLearnState = {}
	self._SkillLearnCondition = {}
	self._SkillLevelUpCondition = {}
end

def.override("table", "number", "number", "function", "function").NormalMove = function (self, pos, speed, offset, successcb, failcb)
	local CFSMHostMove = require "FSM.HostFSM.CFSMHostMove"
	local move = CFSMHostMove.new(self, pos, speed, offset, false, successcb, failcb)
	self:ChangeState(move)
end

def.override().Stand = function (self)
    local CFSMHostStand = require "FSM.HostFSM.CFSMHostStand"
    local stand = CFSMHostStand.new(self)
    stand._IsAniQueued = false
    self:ChangeState(stand)
end

def.override(CEntity, "number", "number", "function", "function").FollowTarget = function (self, target, maxdis, mindis, successcb, failcb)
	if not self:CanMove() then return end
	if target == nil or target:IsReleased() then return end
	local speed = self:GetMoveSpeed()
	local CFSMHostMove = require "FSM.HostFSM.CFSMHostMove"
	local move = CFSMHostMove.new(self, target, speed, 0, false, successcb, failcb)
	move._MaxDis = maxdis
	move._MinDis = mindis
	self:ChangeState(move)
end

def.method().OnJoystickDragEnd = function (self)
	if self:GetCurStateType() == FSM_STATE_TYPE.MOVE then
			self:StopNaviCal()
	elseif self:GetCurStateType() == FSM_STATE_TYPE.SKILL then
		if self._SkillHdl ~= nil then
			self._SkillHdl:OnJoystickDragEnd()
		end
	end
end

-- 显示异动导致的motion blur
def.method().ShowMoveBlurEffect = function(self)
	local blurSpeed = CSpecialIdMan.Get("BlurSpeed")
	if type(blurSpeed) ~= "number" then return end

	if self:GetMoveSpeed() < tonumber(blurSpeed) or self._IsRideBlur 
		or not self:IsOnRide() or self:GetCurStateType() ~= FSM_STATE_TYPE.MOVE then
		return
	end
end

-- 显示异动导致的motion blur
def.method().CloseMoveBlurEffect = function(self)
	self._IsRideBlur = false
end

-- ride blur condition check
def.method("=>", "boolean").IsNeedShowRideBlur = function(self)
	if self._IsRideBlur then return false end

	local blurSpeed = CSpecialIdMan.Get("BlurSpeed")
	if type(blurSpeed) ~= "number" then return false end

	return (self:GetMoveSpeed() >= tonumber(blurSpeed) and self:IsOnRide() and self:GetCurStateType() == FSM_STATE_TYPE.MOVE)
end

def.override("table").SkillMove = function (self, pos)
    if not self:CanMove() then
        return 
    end
	self._SkillHdl:SkillMove(pos, nil, nil)
end

def.override("=>", "boolean", "table").GetNormalMovingInfo = function(self)
	if self._FSM._CurState._Type == FSM_STATE_TYPE.MOVE then
		return true, self._FSM._CurState._TargetPos
	else
		return false, nil
	end
end

def.override("table", "number", "function", "function").Move = function (self, pos, offset, successcb, failcb)
	if not self:CanMove() then
		if self:GetCurStateType() == FSM_STATE_TYPE.BE_CONTROLLED then
			self._CachedAction = function()
					if pos then
						self:Move(pos, offset, successcb, failcb)
					end
				end
		end
		game._GUIMan:ShowTipText(StringTable.Get(600), false)
		return
	end

	if self._SkillHdl:IsCastingSkill() then
		self._SkillHdl:DoMove(pos, offset, successcb, failcb)
	else
		self:NormalMove(pos, self:GetMoveSpeed(), offset, successcb, failcb)
	end
end

def.method("table", "number", "function", "function").MoveAndDonotCareCollision = function (self, pos, offset, successcb, failcb)
	-- self:CanMove() 在调用前做判断
	
	if self._SkillHdl:IsCastingSkill() then
		self._SkillHdl:DoMove(pos, offset, successcb, failcb)
	else
		local CFSMHostMove = require "FSM.HostFSM.CFSMHostMove"
		local speed = self:GetMoveSpeed()
		local move = CFSMHostMove.new(self, pos, speed, offset, true, successcb, failcb)
		self:ChangeState(move)
	end
end

def.override("=>", "boolean").IsHostPlayer = function(self)
	return true
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.HOSTPLAYER
end

def.method("number").CancelTargetSelectedStatus = function(self, targetId)
	if self._CurTarget == nil then return end
	if self._CurTarget._ID == targetId then
		self:UpdateTargetInfo(nil, false)
	end
end

def.method(CEntity, "boolean").UpdateTargetInfo = function(self, target, is_locked)
	if self._CurTarget == target and self._IsTargetLocked then
		return
	end

	if target == nil or not target:CanBeSelected() then
		self._IsTargetLocked = false
		CFxMan.Instance():OnTargetSelected(nil, false)
		--关闭目标头像界面
		CPanelUIHead.Instance():CloseTargetHead()
		--退出锁定镜头
		game:UpdateCameraLockState(0, false)
		self._CurTarget = nil

	else
		local isSetCamToLock = false
		if (not self._IsTargetLocked and is_locked)			-- 自动锁定改为强锁
		or (is_locked and self._CurTarget ~= target) then	-- 强锁目标改变
			isSetCamToLock = true
		end

		self._IsTargetLocked = is_locked
		CFxMan.Instance():OnTargetSelected(target, is_locked)
		--打开目标头像界面
		--增加monster模板中,不能选中和显示血条。设计时:完全静态变量，游戏中不能被修改为显示
		if target ~= nil and not target:IsNeedHideHpBarAndName() then
			if self._CurTarget ~= target then 
				CPanelUIHead.Instance():CloseTargetHead()
			end
			CPanelUIHead.Instance():OpenTargetHead(target)
		else
			--关闭目标头像界面
			CPanelUIHead.Instance():CloseTargetHead()
		end
		self._CurTarget = target

		-- 3v3 场景中 更换目标
		if self:In3V3Fight() then 
			local CPanelPVPHead = require"GUI.CPanelPVPHead"
			if CPanelPVPHead.Instance():IsShow() then 
				CPanelPVPHead.Instance():Update3V3HostPlayerTarget(self._CurTarget._ID)
			end
		end

		if isSetCamToLock then
			game:UpdateCameraLockState(target._ID, true)		-- 尝试开启相机锁定状态
		end
	end
	if self:InEliminateFight() then 
		local CPanelPVPHead = require"GUI.CPanelPVPHead"
		if CPanelPVPHead.Instance():IsShow() then 
			CPanelPVPHead.Instance():ChangeBattleEnemy(self._CurTarget)
		end
	end
end

def.method().UpdateTargetSelected = function(self)
	-- 刷新选中目标
	local curTarget = self._CurTarget
	if curTarget ~= nil then
		CFxMan.Instance():OnTargetSelected(curTarget, self._IsTargetLocked)
	end
end

local event = nil
local function raiseCDEvent()
	if event == nil then
		local SkillCDEvent = require "Events.SkillCDEvent"
		event = SkillCDEvent()
	end
	CGame.EventManager:raiseEvent(nil, event)
end

def.override("number", "number", "number", "number").StartCooldown = function(self, cd_id, accumulate_count, elapsed_time, max_time)
	CEntity.StartCooldown(self, cd_id, accumulate_count, elapsed_time, max_time)
    raiseCDEvent()
end

def.override("number", "number", "number").Die = function (self, element_type, hit_type, corpse_stay_duration)
    local CFSMHostDead = require "FSM.HostFSM.CFSMHostDead"
    local dead = CFSMHostDead.new(self)
    self:ChangeState(dead)
    self._DeathState = EDEATH_STATE.DEATH
end

def.override("number", "number", "number", "boolean").OnDie = function (self, killer_id, element_type, hit_type, play_ani)
	--下马
	if self:IsOnRide() then
    	self:UnRide() 
    	SendHorseSetProtocol(-1, false)
    end

	CPlayer.OnDie(self, killer_id, element_type, hit_type, play_ani)

	-- 播放死亡音效（暂时写死播放濒死音效）
	--local assetPath = "Assets/Outputs/Sound/Effect/Near-Death.wav"
	-- local nearDeathEffect = CElementData.GetSpecialIdTemplate(217).Value
	-- local assetTemplate = CElementData.GetTemplate("Asset", tonumber(nearDeathEffect))
	-- if assetTemplate ~= nil then
	-- 	assetPath = assetTemplate.Path
	-- end
	--CSoundMan.Instance():Play2DAudio(PATH.GUISound_Effect_NearDeath, 0)

    self._OpHdl:EndNPCService(nil)

	self:StopAutoLogic()
	CAutoFightMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CQuestAutoMan.Instance():Stop()

	self:SetTransPortalState(false)

	--死亡，濒死效果显示时，直接关闭。
	if CPanelInExtremis.Instance():IsShow() then
		-- warn("lidaming2 --->>> TERA-3155 跟踪 - 濒死效果结束", num)
		game._GUIMan:Close("CPanelInExtremis")
		CSoundMan.Instance():SetHealthVolume(1)
		CSoundMan.Instance():Play2DHeartBeat("", 0)
	end
	--死亡关闭NPC对话
	local  CPanelDungeonNpcTalk  = require"GUI.CPanelDungeonNpcTalk"
	if CPanelDungeonNpcTalk.Instance():IsShow() then
		CPanelDungeonNpcTalk.Instance():HidePanelNotResetTracker()
	end
end

def.method().StopAutoLogic = function(self)
	-- 自动采集
	local CQuestAutoGather = require "Quest.CQuestAutoGather"
	CQuestAutoGather.Instance():Stop()

	-- 自动寻路
	self:StopAutoTrans()

	-- 停止组队跟随
	self:StopAutoFollow()
end

-- 停止组队跟随StopAutoLogic
def.method().StopAutoFollow = function(self)
	local CTeamMan = require "Team.CTeamMan"
	CTeamMan.Instance():StopFollow()
	CQuest.Instance():QuestFollow(false,-1)
end

def.method().StopAutoTrans = function(self)
	local CTransManage = require "Main.CTransManage"
    CTransManage.Instance():BrokenTrans()
end

def.method("=>", "boolean").GetHawkEyeState = function(self)
   return self._IsHawkEyeState
end

local function IsQuestOk(questId)
	if questId <= 0 then return true end

	return CQuest.Instance():IsQuestInProgress(questId) 
		or CQuest.Instance():IsQuestReady(questId) 
		or CQuest.Instance():IsQuestInProgressBySubID(questId) 
		or CQuest.Instance():IsQuestReadyBySubID(questId) 
end

--参数为是否变更区域判断 还是任务更新原地判断
def.method('boolean').JudgeIsUseHawEye = function (self,isChangeRegion)
	--如果不是区域变更询问，是任务变更询问，并且鹰眼按钮正在开启。则跳出。由玩家手动关闭
	if not isChangeRegion and self._IsHawkEyeEnable then
		return
	end
	local sceneId = game._CurWorld._WorldInfo.SceneTid
	--local scene = _G.MapBasicInfoTable[sceneId]
	local scene = MapBasicConfig.GetMapBasicConfigBySceneID(sceneId)
	if scene == nil then
		warn("Can not find scene data with id ==", sceneId, debug.traceback())
		return
	end

	local regions = scene.Region

	local mapTid = game._CurWorld._WorldInfo.MapTid
	local map = CElementData.GetMapTemplate(mapTid)
	--如果地图不是鹰眼地图 则不允许使用
	if map.IsCanHawkeye == nil or not map.IsCanHawkeye then
		self._IsHawkEyeEnable = false
		self:UpdateHawkeye()
		return
	end

	--判断万武志是否开启（开启条件之一）
	local function Hawkeye_callback( isEnable )
		--print("callback=",isEnable)
		self._IsHawkEyeEnable = isEnable
		self:UpdateHawkeye()
	end

	--如果区域是鹰眼区域 则允许使用
	for i,v in ipairs(self._CurrentRegionIds) do
		for j,w in pairs(regions) do
			for k, x in pairs(w) do
				if v == k then
					local noQuestLimit = (x.QuestID == nil)
					local isQuestOk = false
					if not noQuestLimit then
						for i,v in ipairs(x.QuestID) do
							isQuestOk = IsQuestOk(v)
							if isQuestOk == true then
								break
							end
						end
					end

					if x.IsCanHawkeye ~= nil and x.IsCanHawkeye and (noQuestLimit or isQuestOk ) then
						local ids = x.ManualID
						--如果没有配置解锁条件
						if x.ids == nil then
							Hawkeye_callback(true)
							return
						else
							game._CManualMan:SendC2SManualIsEyesShow( ids, Hawkeye_callback )
							return
						end
					end
				end
			end
		end
	end

    --没有鹰眼区域 不允许使用
	self._IsHawkEyeEnable = false
	self:UpdateHawkeye()
end

def.method().UpdateHawkeye = function (self)
	if self._IsHawkEyeEnable then
				--呼出鹰眼按钮
		local protocol = (require "PB.net".C2SHawkeyeInfo)()
		PBHelper.Send(protocol)
		--print("UseHawEye=====true")
	else
		game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeClose,nil)

		--如果出区域，但还是鹰眼视野
		-- if self._IsHawkEyeState then
	 --        local protocol = (require "PB.net".C2SHawkeyeState)()
	 --        protocol.enable = false --逻辑相反 非鹰眼模式 点击开启
	 --        PBHelper.Send(protocol)
		-- end 
		--print("UseHawEye=====false")
	end	
end

def.method("number").SendHawkeyeUseOrStop = function (self,count)
    if not self._IsHawkEyeEffectIsOver then
    	return 
    end
    if self:GetHawkEyeState() then 
        local protocol = (require "PB.net".C2SHawkeyeState)()
        protocol.enable = false --逻辑相反 非鹰眼模式 点击开启
        
        PBHelper.Send(protocol)
    else
        if count > 0 or count == -1 then  --客户端判定 是否有空余次数 或者 为-1 是无限次数
            local protocol = (require "PB.net".C2SHawkeyeState)()
            protocol.enable = true --逻辑相反 非鹰眼模式 点击开启
            PBHelper.Send(protocol)
        end
    end
end

def.method("boolean","number").SetHawkeyeState = function (self,isEnable,time)
    if self:GetHawkEyeState() == isEnable then
    	return 
    end
    if isEnable then
		self:StartHawkeye()
		game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeActive,{useTime = time})
	else
		self:FinishHawkeye()
		game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.HawkEyeDeactive,nil)
	end
end

def.method().StartHawkeye = function (self)
	self._HawkEyeCount = self._HawkEyeCount - 1
    self._IsHawkEyeState = true
    self._IsHawkEyeEffectIsOver = false
	CGMan.PlayByName("Assets/Outputs/CG/City01/CG_shenzhishijie.prefab", function()
		self._IsHawkEyeEffectIsOver = true
		end)

	if self._TimerIdHawkEyeEffect ~= 0 then
		self:RemoveTimer(self._TimerIdHawkEyeEffect)
	end
	--效果更改
	local CVisualEffectMan = require "Effects.CVisualEffectMan"
	CVisualEffectMan.EnableHawkeyeEffect(true)
	--warn("StartHawkeye", Time.time, debug.traceback())
end

def.method().FinishHawkeye = function (self)
	if self._IsHawkEyeState then
	    self._IsHawkEyeState = false
	    self._IsHawkEyeEffectIsOver = false

	    --效果更改
	    self._IsHawkEyeEffectIsOver = true
	    local CVisualEffectMan = require "Effects.CVisualEffectMan"  
		CVisualEffectMan.EnableHawkeyeEffect(false)   
		--warn("FinishHawkeye", Time.time, debug.traceback())
	end
end

def.method("table","number").UpdateHawkEyeTargetPos = function (self,regions,status)
	self._TableHawkEyeTargetPos = {}
	--print("regions=",#regions)
	local mapId = game._CurWorld._WorldInfo.SceneTid
	--local regionInfo = _G.MapBasicInfoTable[mapId].Region
	local regionInfo = MapBasicConfig.GetMapBasicConfigBySceneID(mapId).Region
	for k,v in ipairs(regions) do
		if v.regionId and v.regionId > 0 and regionInfo[2] ~= nil and regionInfo[2][v.regionId] ~= nil and v.type ~= 0 then
			self._TableHawkEyeTargetPos[v.regionId] = { pos=Vector3.New(v.posx,0,v.posz), type=v.type, status = status }
		end
	end

	--print_r(self._TableHawkEyeTargetPos)
end

def.method("number").RemoveEyeTargetPos = function (self,regionId)
	if self._TableHawkEyeTargetPos ~= nil then
		self._TableHawkEyeTargetPos[regionId] = nil
		--print_r(self._TableHawkEyeTargetPos)
	end
end

def.method("number").SetCamDistOnEnterRegion = function(self, region_id)
	local sceneId = game._CurWorld._WorldInfo.SceneTid
	--local scene = _G.MapBasicInfoTable[sceneId]
	local scene = MapBasicConfig.GetMapBasicConfigBySceneID(sceneId)
	local regions = scene.Region

	for _,w in pairs(regions) do
		for k,x in pairs(w) do
			if k == region_id then
				--w.CameraDistance = 30 
				--warn("distance", w.CameraDistance)
				if x.CameraDistance ~= nil and x.CameraDistance > 0 then
					GameUtil.SetGameCamOwnDestDistOffset(x.CameraDistance, false)	
				end
				break
			end
		end
	end
end

def.method("number").SetCamDistOnLeaveRegion = function(self, region_id)
	local sceneId = game._CurWorld._WorldInfo.SceneTid
	--local scene = _G.MapBasicInfoTable[sceneId]
	local scene = MapBasicConfig.GetMapBasicConfigBySceneID(sceneId)
	local regions = scene.Region

	for j,w in pairs(regions) do
		for k,x in pairs(w) do
			if k == region_id then
				if x.CameraDistance ~= nil and x.CameraDistance > 0 then
					-- 属于改动相机区域
					GameUtil.SetGameCamDefaultDestDistOffset(false)
				end
				break
			end
		end
	end
end

def.override("table", "table", "number", "table", "number", "boolean", "table").OnMove = function (self, curStepPos, facedir, movetype, movedir, speed, useDest, finalDstPos)
    curStepPos.y = GameUtil.GetMapHeight(curStepPos)

    if not self._IsReady then
        self._InitPos = curStepPos
        self._InitDir = facedir
        return
    end

    if self:IsDead() then return end
    if not self:CanMove() then return end

    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    if movetype == ENTITY_MOVE_TYPE.ForceSync then
    	self:SetPos(curStepPos)
        self:SetDir(facedir)
    elseif movetype == ENTITY_MOVE_TYPE.SkillMove then
    	-- do nothing
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then
    	self:NormalMove(curStepPos, speed, 0, nil, nil)
    end
end

-- HostPlayer主动停止，忽略正常停止协议
def.override("table", "table", "number").OnStopMove = function (self, cur_pos, facedir, movetype)
    -- if not self._IsReady or self:IsDead() then return end
    if not self._IsReady  then return end --死亡可以被移动
    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    if movetype == ENTITY_MOVE_TYPE.SkillMove then
        local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR        
        GameUtil.RemoveBehavior(self:GetGameObject(), BEHAVIOR.DASH)
    elseif movetype == ENTITY_MOVE_TYPE.ForceSync then
    	-- 强制拉回把 movebehavior  停一下 吸附发现有些问题
    	self:StopNaviCal()
        self:SetPos(cur_pos)
        -- self:SetDir(facedir)
    elseif movetype == ENTITY_MOVE_TYPE.MapTrans then --同地图传送
    	local CExteriorMan = require "Main.CExteriorMan"
       	CExteriorMan.Instance():Quit()
       	game:QuitNearCam()
       	
    	--warn("OnStopMove MapTrans @", Time.time)
		CAutoFightMan.Instance():Pause(_G.PauseMask.SameMapTrans)
		CQuestAutoMan.Instance():Pause(_G.PauseMask.SameMapTrans)
		CDungeonAutoMan.Instance():Pause(_G.PauseMask.SameMapTrans)

		GameUtil.EnableBlockCanvas(true) -- 屏蔽点击
		StartScreenFade(1, 0, 1, function()
			CAutoFightMan.Instance():Restart(_G.PauseMask.SameMapTrans)
			CQuestAutoMan.Instance():Restart(_G.PauseMask.SameMapTrans)
			CDungeonAutoMan.Instance():Restart(_G.PauseMask.SameMapTrans)

			GameUtil.EnableBlockCanvas(false)

			local CTransManage = require "Main.CTransManage"
        	CTransManage.Instance():ContinueTrans()
		end)
    	
       	--self:SetPos(cur_pos)
       	self:SetDir(facedir)

       	game:OnHostPlayerPosChange(cur_pos)

       	--同地图传送，清理资源
       	local sceneTid = game._CurWorld._WorldInfo.SceneTid
       	if sceneTid == GameUtil.GetCurrentSceneTid() then

       		game:CleanOnSceneChange()
       		game:LuaGC()
       		game:GC(true)
       	end
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then -- 暂时修改成这样
    		local function cb()
        		self:StopNaviCal()
		    end
		    self:Move(cur_pos, 0, cb, cb)
        --end
    elseif movetype == ENTITY_MOVE_TYPE.NpcTrans then --飞行传送
    	StartScreenFade(1, 0, 1,nil)
    	self:StopNaviCal()
       	--self:SetPos(cur_pos)
       	self:SetDir(facedir)

       	--同地图传送，清理资源
       	local sceneTid = game._CurWorld._WorldInfo.SceneTid
       	if sceneTid == GameUtil.GetCurrentSceneTid() then
       		game:CleanOnSceneChange()
       		game:LuaGC()
       		game:GC(true)
       	end

        game:OnHostPlayerPosChange(cur_pos)

        local CTransManage = require "Main.CTransManage"
        CTransManage.Instance():ContinueTrans()
        
        if self._TransOutFx ~= nil then
        	self._TransOutFx:Stop()
        end
		self._TransOutFx = CFxMan.Instance():PlayAsChild(PATH.Gfx_TransOut, self:GetGameObject(), Vector3.zero, Quaternion.identity, 2, true, -1, EnumDef.CFxPriority.Always)
        
    end
end

def.method("number", "number", "number").OnReceiveExp = function (self, offset, currentExp, currentParagonExp)
	local originExp = self._InfoData._Exp
	self._InfoData._Exp = currentExp
	self._InfoData._ParagonExp = currentParagonExp
	-- local strText = string.format(StringTable.Get(508),offset)
	-- game._GUIMan:ShowMoveTextTips(strText)
	game._GUIMan:ShowMoveItemTextTips(11,true,offset, false)

	local ExpUpdateEvent = require "Events.ExpUpdateEvent"
	local event = ExpUpdateEvent()
	event._OriginExp = originExp
	event._CurrentExp = currentExp
	CGame.EventManager:raiseEvent(nil, event)
end

def.override("number", "number", "number", "number").OnLevelUp = function (self, currentLevel, currentExp, currentParagonLevel, currentParagonExp)
	CPlayer.OnLevelUp(self, currentLevel, currentExp, currentParagonLevel, currentParagonExp)
	self._InfoData._Exp = currentExp
	self._InfoData._ParagonExp = currentParagonExp
	--OperationTip.ShowLvUpTip(currentLevel)
	game._CGameTipsQ:ShowLvUpTip(currentLevel)

	local HostPlayerLevelChangeEvent = require "Events.HostPlayerLevelChangeEvent"
	CGame.EventManager:raiseEvent(nil, HostPlayerLevelChangeEvent())
end

local function FindRegionIdx(self, region_id)
	for k, v in ipairs(self._CurrentRegionIds) do
		if v == region_id then
			return k
		end
	end
	return -1
end


def.method("number").EnterRegion = function(self, region_id)
	local index = FindRegionIdx(self, region_id)
	if index == -1 then
		table.insert(self._CurrentRegionIds, region_id)
	end
	--self:JudgeIsUseHawEye(true)
	self:SetCamDistOnEnterRegion(region_id)
	CSoundMan.Instance():ChangeBackgroundMusic(0)
	CSoundMan.Instance():ChangeEnvironmentMusic(0)
	
	local event = NotifyEnterRegion()
	event.RegionID = region_id
    event.IsEnter = true
	CGame.EventManager:raiseEvent(nil, event)

	local data = 
	{
		_type = 2,
		_RegionID = region_id
	}
	
	--self._TableEnterMapRegionTips =  data
	--local CPanelLoading = require "GUI.CPanelLoading"
	--if not CPanelLoading.Instance():IsShow() then

--		local CPanelEnterMapTips = require "GUI.CPanelEnterMapTips"
--		CPanelEnterMapTips.Instance():ShowEnterTips(data)

	game._CGameTipsQ:ShowMapTip(data)

		--self._TableEnterMapRegionTips = nil
	--end
	
	local targetRoomIDs = CTeamQuickCheck.CheckRegionQuickTeam(region_id)
	local count = 0  
	for k,v in pairs(targetRoomIDs) do  
	    count = count + 1  
	end  
	if count > 0 then
		game._GUIMan:Open("CPanelQuickTeam", targetRoomIDs)
	end
end

def.method("number").LeaveRegion = function(self, region_id)
	local index = FindRegionIdx(self, region_id)
	if index ~= -1 then
		table.remove(self._CurrentRegionIds, index)
	end
    local event = NotifyEnterRegion()
	event.RegionID = region_id
    event.IsEnter = false
	CGame.EventManager:raiseEvent(nil, event)

	--self:JudgeIsUseHawEye(true)
	self:RemoveEyeTargetPos(region_id)
	self:SetCamDistOnLeaveRegion(region_id)
	CSoundMan.Instance():ChangeBackgroundMusic(0)
	CSoundMan.Instance():ChangeEnvironmentMusic(0)
end

def.method("number").TryLockTarget = function(self, target_id)
	local target = game._CurWorld:FindObject(target_id)
	if target == nil then 
		return 
	end

	--warn("huangxin 111", target_id)
	if self._IsTargetLocked then return end
	--warn("huangxin 222")
	self:UpdateTargetInfo(target, true)
end

def.override("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	local old_server_combat_state = self:IsInServerCombatState()
	CPlayer.UpdateCombatState(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	
	-- 切换背景音乐
	if old_server_combat_state ~= self:IsInServerCombatState() then
		CSoundMan.Instance():ChangeBackgroundMusic(0)
	end

	local CombatStateChangeEvent = require "Events.CombatStateChangeEvent"
    local event = CombatStateChangeEvent()    
    event._IsInCombatState = is_in_combat_state
    event._CombatType = 1
    if is_client_state then
    	event._CombatType = 0
    end
    CGame.EventManager:raiseEvent(nil, event)

	-- warn("is_in_combat_state : ",is_in_combat_state)
	-- 主动锁定进战目标，结束当前NPC服务
	if is_in_combat_state and not is_client_state then
		-- self:TryLockTarget(origin_id)
		
		local CExteriorMan = require "Main.CExteriorMan"
		CExteriorMan.Instance():Quit() -- 退出外观

		-- self._OpHdl:EndNPCService()

		self: ClearIdleState()
	end
end

def.override("number").ChangeShape = function (self, monster_id)
	CPlayer.ChangeShape(self, monster_id)
	
	CAutoFightMan.Instance():Stop() 
	CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	local CExteriorMan = require "Main.CExteriorMan"
	CExteriorMan.Instance():Quit()
end

def.override().ResetModelShape = function (self)
	local transformId = self._TransformID
    if transformId == 0 then
        warn("shape is original , not need to reset")
        return
    end 

    CPlayer.ResetModelShape(self)

	CAutoFightMan.Instance():Stop() 
	CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
end



def.override("number", "number", "=>", "boolean").OnCollideWithOther = function(self, colliderId, collideEntityType)
    local isCollided = false

    local COLLIDE_ENTITY_TYPE = require "Main.CSharpEnum".COLLIDE_ENTITY_TYPE
    if collideEntityType == COLLIDE_ENTITY_TYPE.ONLYTARGET then
    	local curAttackTargetId = self._SkillHdl:GetCurAttackTargetId()
    
	    if curAttackTargetId ~= 0 and curAttackTargetId == colliderId then -- 只碰当前目标
			isCollided = true
		elseif curAttackTargetId == 0 and colliderId ~= 0 then
			local collider = game._CurWorld:FindObject(colliderId)				
			if collider ~= nil and collider:GetRelationWithHost() == "Enemy" then
				isCollided = true				
			end
		end
	else --if collideEntityType == COLLIDE_ENTITY_TYPE.ENEMY then
		local collider = game._CurWorld:FindObject(colliderId)				
		if collider ~= nil and collider:GetRelationWithHost() == "Enemy" then
			isCollided = true				
		end
	--else
	--	isCollided = true
	end

	if isCollided then
    	self._SkillHdl:TriggerEvents(TriggerType.Collision)
	end

	return isCollided
end

-- 碰撞是否为大型怪
def.override("number", "=>", "boolean").OnCollidingHuge = function(self, colliderId)
    local ret = false
    if colliderId > 0 then
    	local entity = game._CurWorld:FindObject(colliderId)	
    	if entity:GetObjectType() == OBJ_TYPE.MONSTER then
	    	if entity and not entity:IsReleased() and (entity._MonsterTemplate.BodySize == EnumDef.EMonsterBodySize.BODYSIZE_HUGE) then
		    	return true
	    	end
	    end
    end
    return ret
end

def.method("number", "boolean", "number", "=>", "boolean").HasEnoughSpace = function(self, tid, bIsBand, count)
	return self._Package._NormalPack:HasEnoughSpace(tid, bIsBand, count)
end

def.method("=>", "boolean").HasEmptySpace = function(self)
	return self._Package._NormalPack:HasEmptySpace()
end
--是否在副本中
def.method("=>", "boolean").InDungeon = function(self)
   return game._DungeonMan: InDungeon()
end

--是否在临时相位副本中
def.method("=>","boolean").InImmediate = function(self)
	 return game._DungeonMan: InImmediate()
end

--是否在相位
def.method("=>","boolean").InPharse = function(self)
	 return game._DungeonMan: InPharse()
end


--是否在大世界中
def.method("=>", "boolean").InWorld = function(self)
	local curMapType = game._CurMapType
	if curMapType == EWorldType.City or curMapType == EWorldType.Town then
		return true
	end
	return false
end

-- 是否在1v1竞技场
def.method("=>", "boolean").In1V1Fight = function(self)
	return game._DungeonMan:Get1v1WorldTID() == game._CurWorld._WorldInfo.SceneTid
end

--是否在3V3角斗场
def.method("=>","boolean").In3V3Fight = function(self)
	return game._DungeonMan:Get3V3WorldTID() == game._CurWorld._WorldInfo.SceneTid
end

-- 是否在无畏战场
def.method("=>","boolean").InEliminateFight = function(self)
	return game._DungeonMan:GetEliminateWorldTID() == game._CurWorld._WorldInfo.SceneTid
end

-- 此接口仅做 自动寻路标志显隐 & 内部属性更新
-- 真正的行动在CTransManage发起
def.method("boolean").SetAutoPathFlag = function(self, isAutoPath)
	if not isAutoPath then
    	self:HaveTransOffset(false)
	end
	self._IsAutoPathing = isAutoPath
	if self._TopPate ~= nil then
		self._TopPate:SetAutoPathingState(isAutoPath)
	end
end

--清除自动寻路目标位置
def.method().ClearAutoPathTargetPos = function(self)
	self._NavTargetPos = nil 
end

--设置传送门传送状态
def.method("boolean").SetTransPortalState = function(self,isPortal)
	self._IsTransPortal = isPortal
end

--获取传送门状态
def.method("=>","boolean").GetTransPortalState = function(self)
	return self._IsTransPortal
end

def.method("boolean").HaveTransOffset = function(self, isOffset)
	self._IsHaveTransOffset = isOffset
end

def.override("boolean", "number", "number", "number", 'table').UpdateState = function(self, add, state_id, duration, originId, info)
    CEntity.UpdateState(self, add, state_id, duration, originId, info) 
 
	local SkillTriggerEvent = require "Events.SkillTriggerEvent"
    local event = SkillTriggerEvent()
    event._StateId = state_id
    event._SkillId = 0
    event._IsBegin = add
    CGame.EventManager:raiseEvent(nil, event)

    -- local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
    -- CPanelSkillSlot.Instance():TriggerComboSkill(state_id, 0, add)
end

def.method("boolean", "=>", "table").GetNoEquipedPotions = function(self, needCount)	
	local EItemType = require "PB.Template".Item.EItemType
	local itemsList = self._Package._NormalPack:GetItemListByType(EItemType.Potion)	

	local hpLv = self._InfoData._Level
	local equipedPotion = self:GetEquipedPotion()
	local results = {}
	for i,v in ipairs(itemsList) do
		local tid = v._Tid
		if tid ~= equipedPotion  then -- 装备中
			local template = v._Template
			if template ~= nil and hpLv >= template.MinLevelLimit then -- 不能使用
				if results[tid] == nil then results[tid] = 0 end
				if needCount then
					results[tid] = results[tid] + v:GetCount()
				else
					results[tid] = 1
				end
			end
		end
	end

	local avalidPotions = {}
	if table.nums(results) >= 0 then
		if needCount then
			for k,v in pairs(results) do
				avalidPotions[#avalidPotions + 1] = {k, v}
			end

			local function SortFunc(itm1,itm2)
		    	if self._IsAutoUseLowLvDrug then
		    		return itm1[1] < itm2[1]
		    	else
		    		return itm1[1] > itm2[1]
		    	end
		    end
		    table.sort(avalidPotions, SortFunc)
		else
			for k,v in pairs(results) do
				avalidPotions[#avalidPotions + 1] = k
			end

			local function SortFunc(itm1,itm2)
		    	if self._IsAutoUseLowLvDrug then
		    		return itm1 < itm2
		    	else
		    		return itm1 > itm2
		    	end
		    end
		    table.sort(avalidPotions, SortFunc)
		end	
	    	    
	end

	return avalidPotions
end

local DiamondDrugTid = 2002
-- 自动装备随机的drug
def.method().Try2EquipDrug = function (self)	
    local avildPotions = self:GetNoEquipedPotions(false)
    for i,v in ipairs(avildPotions) do
    	if v ~= DiamondDrugTid then
			self:EquipDrugItem(v)
			return
		end
    end
end

-- 装备指定的drug
def.method("number").EquipDrugItem = function (self, item_id)	
	local equip_drug_id = self:GetEquipedPotion()		
	if item_id ~= equip_drug_id and self._Package._NormalPack:GetItemCount(item_id) > 0 then
		local C2SCarryPotion = require "PB.net".C2SCarryPotion
		local protocol = C2SCarryPotion()
		protocol.Tid = item_id
		PBHelper.Send(protocol)
	end
end

--所有仇恨列表
def.method("number", "number").SetEntityHate = function(self, hate_opt, entityId)
	local HATE_OPTION = require "PB.net".HATE_OPT
	--查看列表中有没有对应的entitid
	local index = table.indexof(self._HatedEntityMap, entityId)

	if hate_opt == HATE_OPTION.HATE_OPT_ADD then
		if not index then -- 如果没有对应的id就添加
			table.insert(self._HatedEntityMap, entityId)		

		end
	elseif hate_opt == HATE_OPTION.HATE_OPT_REMOVE then
		if index then  -- 如果有对应的id 就移除
			table.remove(self._HatedEntityMap, index)
		end
	end

	if entityId ~= self._ID then
		local entity = game._CurWorld:FindObject(entityId)
		if entity ~= nil and entity:IsRole() then
			-- 仇恨值变化只需要刷新名字颜色
			entity:SetPKMode(entity:GetPkMode())
			entity:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			if entity._TopPate ~= nil then
				entity._TopPate:UpdateName(true)
				entity:UpdatePetName()
				self:UpdateTargetSelected()
			end
		end
	end
end

def.method("number","=>","boolean").IsEntityHate = function(self , entityid)
	--查看列表中有没有对应的entitid
	local index = table.indexof(self._HatedEntityMap, entityid)
	if not index then -- 如果没有对应的id就添加
		return false
	end
	return true
end

def.method("=>", "table").GetHatedEntityList = function(self)
	return self._HatedEntityMap
end

def.method("=>", "boolean").IsCollectingMineral = function(self)
	if self._SkillHdl == nil then return false end

	return self._SkillHdl:IsCollectingMineral()
end

-- 返回战力
def.method("=>", "number").GetHostFightScore = function(self)
	if self._InfoData then
		local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
		return math.ceil(self._InfoData._FightProperty[ENUM.FIGHTSCORE][1])
	end
end

def.override("=>","string").GetEntityColorName = function(self)
	local name = self._InfoData._Name
	if self:GetEvilValue() >= 100 then
		return "<color=#C03DF6>"..name.."</color>"
	end	
	return "<color=#65D2FF>"..name.."</color>"
end

def.override("string", "=>","string").GetPetColorName = function(self, name)
	if self:GetEvilValue() >= 100 then
		return "<color=#C03DF6>"..name.."</color>"
	end	
	return "<color=#65D2FF>"..name.."</color>"
end

-- 返回荣耀等级
def.method("=>", "number").GetGloryLevel = function(self)
	if self._InfoData then
		return self._InfoData._GloryLevel
	end
end

-- 返回角色称号ID 
def.override("=>", "number").GetDesignationId = function(self)
	return game._DesignationMan:GetCurDesignation()
end

--tips战斗力滚动面板
def.method("number","table").ShowFightScoreUp = function(self, newVal, props)
	local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	local oldVal = math.ceil(self._InfoData._FightProperty[ENUM.FIGHTSCORE][1])

	if oldVal > 0 then
		local increaseVal = newVal - oldVal
		if increaseVal ~= 0 then
			game._CGameTipsQ:ShowFightScoreTip(oldVal, increaseVal, props)
		end
	end
end

--tips战斗力shuxing面板
def.method("number","=>","boolean").IsFSDetail = function(self, newVal)
	local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	if newVal ==ENUM.STRENGTH or newVal ==ENUM.DEXTERITY or newVal ==ENUM.INTELLIGENCE or newVal ==ENUM.VITALITY
		or newVal ==ENUM.MAXHP or newVal ==ENUM.ATTACK or newVal ==ENUM.DEFENSE or newVal ==ENUM.CRITICALLEVEL
	then
		return true
	end
	return false
end

local MinBGMVolume = nil
local HpMinValue = nil
def.method().NearDeathState = function(self)
	local info_data = self._InfoData
	local num = info_data._CurrentHp / info_data._MaxHp
	if MinBGMVolume == nil then
		MinBGMVolume = CElementData.GetSpecialIdTemplate(218).Value
	end
	if HpMinValue == nil then
		HpMinValue = tonumber(CElementData.GetSpecialIdTemplate(204).Value)
	end

	-- warn("lidaming ----------------> num ==", num)
	-- 如果主角的血低于20（特殊配置表ID为204的值）就显示一个濒死效果		
	if num ~= 0 and num <= HpMinValue then
		-- warn("lidaming --->>> TERA-3155 跟踪 - 濒死效果开始", num)
		if not CPanelInExtremis.Instance():IsShow() then
			game._GUIMan:Open("CPanelInExtremis",nil)
			--CSoundMan.Instance():SetSoundBGMVolume(tonumber(MinBGMVolume), true) -- 播放濒死音乐的时候背景音乐调小一半。
			CSoundMan.Instance():SetHealthVolume(0)
			CSoundMan.Instance():Play2DHeartBeat(PATH.GUISound_Effect_NearDeath, 0)
		end
	-- 如果主角的血为0，或者已经死亡，关闭濒死效果。
	elseif num >= 0 or self:IsDead() then
		-- warn("lidaming1 --->>> TERA-3155 跟踪 - 濒死效果结束", num)
		game._GUIMan:Close("CPanelInExtremis")  -- 关闭濒死音乐的时候背景音乐还原。	
		CSoundMan.Instance():SetHealthVolume(1)
		CSoundMan.Instance():Play2DHeartBeat(PATH.GUISound_Effect_NearDeathEnd, 0)	
	end
end

def.override("table", "boolean").UpdateFightProperty = function(self, properties, isNotifyFightScore)
    if self._InfoData == nil then return end

    local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY
    local hpChanged = false
	local FS_detail = {}
	local is_showFS=false
	local show_FS_value=0
    for k,v in pairs(properties) do
        if v.Index == ENUM_FIGHTPROPERTY.MAXHP or v.Index == ENUM_FIGHTPROPERTY.CURRENTHP then
        	hpChanged = true
        end

		--战力detail
		if isNotifyFightScore and self._ShowFightScoreBoard then
			if v.Index == nil then

			elseif v.Index == ENUM_FIGHTPROPERTY.FIGHTSCORE then
				--战斗力提升弹板提示
				show_FS_value = math.ceil(v.Value)
				is_showFS=true
			elseif self:IsFSDetail(v.Index) then
				local oldVal = math.ceil(self._InfoData._FightProperty[v.Index][1])
				table.insert(FS_detail, {["type"]=v.Index, ["a"]=oldVal, ["b"] = math.ceil(v.Value)})
			end
		end
    end

	if is_showFS then
		self:ShowFightScoreUp(show_FS_value, FS_detail)
	end
	
    CPlayer.UpdateFightProperty(self, properties, false)
    if hpChanged then
		self:NearDeathState()
	end
end

def.override().OnClick = function(self)
	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if self:IsInExterior() and CPanelUIExterior ~= nil then
		-- 外观界面，点击主角
		CPanelUIExterior.Instance():ClickHostPlayer()
	end
end

def.override().OnEnterPhysicalControled = function(self)
    CEntity.OnEnterPhysicalControled(self)

    self:SendBaseStateChangeEvent(true)
	local SkillStateUpdateEvent = require "Events.SkillStateUpdateEvent"
	CGame.EventManager:raiseEvent(nil, SkillStateUpdateEvent())
end

def.override().OnLeavePhysicalControled = function(self)
    CEntity.OnLeavePhysicalControled(self)
    
    if not self:IsMagicControled() then
        if self._CachedAction ~= nil then       
            self._CachedAction()
            self._CachedAction = nil
        end
		local SkillStateUpdateEvent = require "Events.SkillStateUpdateEvent"
		CGame.EventManager:raiseEvent(nil, SkillStateUpdateEvent())
    	self:SendBaseStateChangeEvent(false)
    end
end

-- 打断寻路位移
def.override().StopNaviCal = function (self)
    if self:GetCurStateType() == FSM_STATE_TYPE.SKILL then   -- 技能状态
        self:StopMovementLogic()
		self:SetAutoPathFlag(false)
    	local CPath = require "Path.CPath"
    	local CPanelMap = require "GUI.CPanelMap"
        if not CPath.Instance()._IsDungeonPath then
        	CPath.Instance():Hide()
        	CPanelMap.Instance():InterruptAutoPathing()
        end
        if self._SkillHdl ~= nil then
            self._SkillHdl:ClearSkillMoveState()
        end
    elseif self:IsPhysicalControled() or self:IsMagicControled() then  -- 受控状态
        -- Do nothing，控制状态开始结束时会自动处理
    else  -- 一般状态
    	local CPath = require "Path.CPath"
    	local CPanelMap = require "GUI.CPanelMap"
        if not CPath.Instance()._IsDungeonPath then
        	CPath.Instance():Hide()
        	CPanelMap.Instance():InterruptAutoPathing()
        end
        self:SetAutoPathFlag(false)
        self:Stand()
    end
end

def.override("=>", "number").GetRenderLayer = function (self)
    return EnumDef.RenderLayer.HostPlayer
end

--设置3V3ID
def.method("number").Set3v3RoomID = function(self,nRoomID)
	self._3V3RoomID = nRoomID
end

--获取3V3ID
def.method("=>","number").Get3V3RoomID = function(self)
	return self._3V3RoomID
end

-- 设置无畏战场Id
def.method("number").SetEliminateRoomID = function(self,nRoomID)
	self._EliminateRoomID = nRoomID
end

-- 设置正在采集的ID
def.method("number").SetMineGatherId= function(self, id)
    self._MineGatherId = id
end

-- 获取正在采集的ID
def.method("=>", "number").GetMineGatherId = function(self)
    return self._MineGatherId
end

--获取无畏战场ID
def.method("=>","number").GetEliminateRoomID = function(self)
	return self._EliminateRoomID
end

def.method().OnJumpToNewPos = function(self)
	-- 伤害数字存在延时，跳转后清空
	if self._HUDText ~= nil then
        self._HUDText:Clear()
    end
end

-- 与服务器同步所有外观信息 Add by Yao
def.method().SyncAllExterior = function (self)
	-- 坐骑
	local horseId = self:GetCurrentHorseId()
	if self:IsServerMounting() and horseId > 0 and self:CanRide() then
		self:Ride(horseId, false)
	elseif self:IsOnRide() then
		-- 服务器没上马，但表现是上了马
		if game._RegionLimit._LimitRide then
			-- 场景限制
			game._GUIMan:ShowTipText(StringTable.Get(15551), false)
		end
		self:UnRide()
	end
	self:UpdateCombatState(self:IsInServerCombatState(), true, 0, true, false)

	local ModelParams = require "Object.ModelParams"
	local curParam = self:GetModelParams()
	local updateParam = ModelParams.GetUpdateParams(self._OutwardParams, curParam)
	self:UpdateOutward(updateParam, function ()
		self:SetCurWeaponInfo()
		self:SetCurWingModel()
		GameUtil.SetLayerRecursively(self:GetOriModel():GetGameObject(), self:GetRenderLayer())
	end)
end

def.override("=>", "boolean").IsInExterior = function (self)
	local CExteriorMan = require "Main.CExteriorMan"
	return CExteriorMan.Instance():GetState()
end

def.method("table").SetArenaDataInfo = function (self,data)
	self._InfoData._Arena3V3Stage = data.Stage
	-- body
end
def.method("table").SetJJCScore = function (self,data)
	self._InfoData._ArenaJJCScore = data.Score
	-- body
end

def.method("number").SetEliminateScore = function(self, score)
    self._InfoData._EliminateScore = score
end

def.method("=>", "boolean").IsFollowingServer = function(self)
	return self._IsFollowingServer
end

def.method("boolean").CancelSyncPosWhenMove = function(self, canceled)
	self._IsFollowingServer = canceled

	GameUtil.EnableHostPosSyncWhenMove(not canceled)
	--warn("CancelSyncPosWhenMove", debug.traceback())
end

def.method("=>", "userdata").GetBipSpine = function (self)
	if self._BipSpine ~= nil then
		return self._BipSpine
	end

	if self._GameObject ~= nil then
		self._BipSpine = self._GameObject:FindChild("Model/Bip001/Bip001 Pelvis/Bip001 Spine/Bip001 Spine1") or self._GameObject
		return self._BipSpine
	end

	return nil
end

---------------------------------待机动作的检测 --by luee 2018.7.16--------------------------------------------------
--删除待机动作检测的timer
def.method().RemoveIdleAnimationTimer = function(self)
	if self._IdleAnimationTimer ~= 0 then
		self:RemoveTimer(self._IdleAnimationTimer)
        self._IdleAnimationTimer = 0
	end
end

--删除待机状态的检测
def.method().RemoveIdleStateTimer = function(self)
	if self._IdleStateTimer ~= 0 then
		self:RemoveTimer(self._IdleStateTimer)
        self._IdleStateTimer = 0	
	end
end

def.method("=>","number").GetIdleRandomTime = function(self)
	--数据只取一次，游戏中一直生效
	if self._TableRandomTime == nil or #self._TableRandomTime <= 0 then
		local CSpecialIdMan = require  "Data.CSpecialIdMan"
		local strTime = CSpecialIdMan.Get("IDLE_ANIMATION_TIME")
		local listStr = string.split(strTime, "*")
		self._TableRandomTime = {}
		for _,v in ipairs(listStr) do
			local nTime = tonumber(v)
			self._TableRandomTime[#self._TableRandomTime + 1] = nTime
		end
	end

	local index = math.random(1, #self._TableRandomTime)
	return self._TableRandomTime[index]
end 

def.method("=>","number").GetIdleSkillTid = function(self)
	local curProf = self._InfoData._Prof
	local SkillDef = require "Skill.SkillDef"

	local idex = math.random(1, 2)
	return SkillDef.IdleSkills[curProf][idex]
end

--进入休闲状态，开始逻辑操作
def.method().StartIdleAnimation = function(self)		
	if self:IsPhysicalControled() or self:IsMagicControled() then  -- 受控状态
		self:RemoveIdleAnimationTimer()
		return
	end

	local idleTime = self:GetIdleRandomTime()
	local time = 0
	local function callback( ... )
		if self:IsPhysicalControled() or self:IsMagicControled() then  -- 受控状态
			self:ClearIdleState()
			return
		end
		
		--骑马的时候，不做待机处理
		if self:IsOnRide() then
			self:ClearIdleState()
			return
		end

		time = time + 1
		if time > idleTime then
			self:RemoveIdleAnimationTimer()
			local skillTid = self:GetIdleSkillTid()
			--warn("skillTid---------------->",skillTid)
			self._SkillHdl:CastSkill(skillTid, false)			
		end
	end 

	self:RemoveIdleAnimationTimer()
	self._IdleAnimationTimer = self:AddTimer(1, false, callback)
end

def.method().ContinueIdleSkill = function(self)
	self:Stand()
	self._IsIdleState = true
	self:RemoveIdleStateTimer()
	self:StartIdleAnimation()
	--warn("ContinueIdleSkill---------------->")	
end

def.override().BeginIdleState = function(self)
	if self:IsOnRide()  or self:IsInServerCombatState() then
		self:ClearIdleState()
		return 
	end

	if self:GetCurStateType() ~= FSM_STATE_TYPE.IDLE then return end

	--如果正在外观或者近景，不管什么逻辑，都不执行
	local CExteriorMan = require "Main.CExteriorMan"
	local exterior_state = CExteriorMan.Instance():GetState()
	if exterior_state or game._IsInNearCam then
		self:ClearIdleState()
		return 		
	end

	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local stateTime = CSpecialIdMan.Get("IDLE_STATE_TIME")
	local time = 0
	local function callStateback()
			--骑马的时候，不进入待机状态
			if self:IsOnRide() then
				self:ClearIdleState()
				return
			end

			time = time + 1
			if time > stateTime then			 
				self:RemoveIdleStateTimer()	
				self._IsIdleState = true
				self:StartIdleAnimation()		
			end					
		end
	self:RemoveIdleStateTimer()
	self._IdleStateTimer = self:AddTimer(1, false, callStateback)
end

--状态机改变的地方
def.override(CFSMStateBase, "=>", "boolean").ChangeState = function(self, state)
	local oldType = self:GetCurStateType()
	CEntity.ChangeState(self, state)
	
	--切换到idel状态，开始timer
	if state._Type == FSM_STATE_TYPE.IDLE then
		if oldType ~= FSM_STATE_TYPE.IDLE then
			if self._IsIdleState then
				--已经进入了休闲状态
				self:RemoveIdleStateTimer()
				self:StartIdleAnimation()
			else
				--休闲状态检测
				self:BeginIdleState()
			end
		end
	else
		self:ClearIdleState()
	end

	return true
end

--下马的地方  如果是IDLE状态，重新激活
def.override().UnRide = function (self)
	CPlayer.UnRide(self)

	if self:GetCurStateType() == FSM_STATE_TYPE.IDLE then
		self:SetPauseIdleState(false)
	end

	--self:CloseMoveBlurEffect()
end

def.method().ClearIdleState = function(self)
	self:RemoveIdleAnimationTimer()	
	self:RemoveIdleStateTimer()
	self._IsIdleState = false
end

--设置暂停待机状态的地方 true = 暂停 false 恢复
def.method("boolean").SetPauseIdleState = function(self, isPause)
	if isPause then
		self:ClearIdleState()
		-- self:Stand()
	else
		self:BeginIdleState()
	end
end

-------------------------------------------------待机动作的检测 --by luee 2018.7.16-----------------------------------------------------

def.override().ReleaseBuffStates = function(self)
    CEntity.ReleaseBuffStates(self)
    
    --主角自己的buff
    local CPanelUIHead = require 'GUI.CPanelUIHead'
    if CPanelUIHead and CPanelUIHead.Instance():IsShow() then
        CPanelUIHead.Instance():ClearBuff()
    end
end

def.override().OnResurrect = function (self)
	CPlayer.OnResurrect(self)

	-- 打开任务面板（死亡时关闭了）
	local CPanelTracker = require "GUI.CPanelTracker"
	if self:InEliminateFight() then 
		if CPanelTracker and CPanelTracker.Instance():IsShow() then
			CPanelTracker.Instance():ShowSelfPanel(false)
		end
	else
		if CPanelTracker and CPanelTracker.Instance():IsShow() then
			CPanelTracker.Instance():ShowSelfPanel(true)
		end
	end
	game._GUIMan:Close("CPanelUIRevive")

	-- 恢复摄像机灰度
	GameUtil.SetCameraGreyOrNot(false)
end

def.override().OnTransformerModelLoaded = function (self)
	if self._IsReleased then return end
	CPlayer.OnTransformerModelLoaded(self)
end

def.override("number", "number").OnHPChange = function (self, hp, max_hp)
	CPlayer.OnHPChange(self, hp, max_hp)

	-- 更新主界面血量
	local CPanelUIHead = require "GUI.CPanelUIHead"
	if CPanelUIHead and CPanelUIHead.Instance():IsShow() then
		CPanelUIHead.Instance():UpdateHpInfo()
	end
	-- 触发血瓶教学
	local hpPercent = self._InfoData._CurrentHp / self._InfoData._MaxHp
	game._CGuideMan:GuideTrigger(EnumDef.EGuideBehaviourID.HPPercentLow, hpPercent)
	game._CGuideMan:GuideTrigger(EnumDef.EGuideBehaviourID.HPPercentHigh, hpPercent)
end

def.override("number").UpdateShield = function(self, val)
	CPlayer.UpdateShield(self, val)
	-- 更新主界面血量
	local CPanelUIHead = require "GUI.CPanelUIHead"
	if CPanelUIHead and CPanelUIHead.Instance():IsShow() then
		CPanelUIHead.Instance():UpdateHpInfo()
	end
end

def.method("function").AddCachedAction = function (self, action)
	self._CachedAction = action
end

def.method("=>", "boolean").HasCachedAction = function (self)
	return self._CachedAction ~= nil
end

def.method().DoCachedAction = function (self)
	local action = self._CachedAction
	if action ~= nil then
		self._CachedAction = nil  -- 先清空，再执行，防止action中调用相关逻辑，造成死循环
		action()
	end
end

def.method().CancelCachedAction = function (self)
	self._CachedAction = nil
end

def.method("number").UpdateLevelMTime = function (self, time)
	self._RoleLevelMTime = time
end

def.override().Release = function (self)
    if self._TimerNavMountHorse ~= 0 then
        self:RemoveTimer(self._TimerNavMountHorse)
        self._TimerNavMountHorse = 0
    end
	if not IsNil(self._GameObject) then
        GameUtil.OnHostPlayerDestroy()
    end

    CPlayer.Release(self)
    self._BipSpine = nil
   	self._TableRandomTime = nil
end

CHostPlayer.Commit()
return CHostPlayer