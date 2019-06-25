local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CStateMachine = require "FSM.CStateMachine"
local CElementData = require "Data.CElementData"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CSkillSealInfo = require "Skill.CSkillSealInfo"
local CSharpEnum = require "Main.CSharpEnum"
local CModel = require "Object.CModel"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFSMStateBase = require "FSM.CFSMStateBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPet = Lplus.Extend(CNonPlayerCreature, "CPet")
local def = CPet.define

def.field("dynamic")._PetTemplate = nil
def.field("dynamic")._AssociatedMonsterTemplate = nil 	-- 关联怪物
def.field("number")._OwnerId = 0	--主人ID
def.field("number")._IdleAnimationTimer = 0 --休闲动作待机timer
def.field("number")._IdleStateTimer = 0 --进入休闲状态timer
def.field("boolean")._IsIdleState = false   --休闲状态

def.static("=>", CPet).new = function ()
	local obj = CPet()
	obj._FSM = CStateMachine.new()
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._SealInfo = CSkillSealInfo.new(obj)
	obj._FadeOutWhenLeave = true
	return obj
end

def.override("table").Init = function (self, info)
	CNonPlayerCreature.Init(self, info.MonsterInfo)
	self:SetOwnerId(info.HostId)

	-- Set Owner PetInfo
	local table_Player = game._CurWorld._PlayerMan._ObjMap
	if next(table_Player) ~= nil then
		for _,v in pairs(table_Player) do
			if v._ID == info.HostId then
				v:SetPetId(self._ID)
			break
			end
		end
	end

	self._PetTemplate = CElementData.GetTemplate("Pet", info.PetTid)
	self._AssociatedMonsterTemplate = CElementData.GetTemplate("Monster", self._PetTemplate.AssociatedMonsterId)
	self._InfoData._Name = info.MonsterInfo.CreatureInfo.Name == "" and self._PetTemplate.Name or info.MonsterInfo.CreatureInfo.Name
end

def.override("number").Load = function (self, enterType)
	local model_path = self:GetModelPath()
	
	local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
	self._Model = m
	
	local on_model_loaded = function(ret)
		if ret then
			if self._IsReleased then
				m:Destroy()
			else
				self:AddObjectComponent(false, 0.4)
				self._IsReady = true

				local id = self:GetOwnerId()
				if id == game._HostPlayer._ID then
					GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.HostPlayer)
				elseif IDMan.ISROLEID(id) then
					GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.Player)
				else
					GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.NPC)
				end

				self:Stand()
				--self:EnableShadow(false)
				
				self:OnModelLoaded()
				self:SetColorName()

				self._GameObject.position = self._InitPos
				self:SetHeightOffset()

				-- 调整Body大小
				local scale = self._AssociatedMonsterTemplate.BodyScale
				if scale > 0 then
					self._GameObject.localScale = Vector3.one * scale
				else
					warn("DataError: Pet AssociatedMonsterTemplate.BodyScale == 0 , tid = ", self._AssociatedMonsterTemplate.Id)
				end

				--self._Model:SetVisible(self:IsCullingVisible())
			end
		else
			warn("Failed to load model with path = " .. model_path)
		end
	end

	if model_path ~= "" then
		m:Load(model_path, on_model_loaded)
	else
		warn("Data Error: Pet's model path is empty")
	end
end

def.override().OnModelLoaded = function(self)
	CNonPlayerCreature.OnModelLoaded(self)
	--castShadow
	self:EnableCastShadows(true)

	self:EnableShadow(false)
	self:BeginIdleState()
end

-- 设置宠物 高度偏移量，用于飞行类宠物 贴地高度偏移
def.method().SetHeightOffset = function(self)
	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
	local config = ModuleProfDiffConfig.GetModuleInfo("PetHeightOffset")

	local yOffset = 0
	if config ~= nil and config[self._PetTemplate.Id] ~= nil then
		local petOffsetInfo = config[self._PetTemplate.Id]
		local defaultOffsetY = petOffsetInfo.Default
		local Player = game._CurWorld:FindObject(self._OwnerId)
		
		if Player == nil then
			yOffset = defaultOffsetY
		else
			local prof = Player._InfoData._Prof
			if petOffsetInfo.OffsetY[prof] == nil then
				yOffset = defaultOffsetY
			else
				yOffset = petOffsetInfo.OffsetY[prof]
			end
		end
	end
	--刷新高度
	if self._GameObject then
		GameUtil.SetGameObjectYOffset(self._GameObject, yOffset)
		self._HeightOffsetY = yOffset
	end
end

def.override().OnPateCreate = function(self)
	CNonPlayerCreature.OnPateCreate(self)
	if self._TopPate == nil then return end
	
	self._TopPate:SetVisible(true)
	--self._TopPate:SetChildrenVisible(false, false)
	self._TopPate:SetHPLineIsShow(false,EnumDef.HPColorType.None)
	self._TopPate:SetStaLineIsShow(false)
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._PetTemplate ~= nil then
		return self._PetTemplate.Id
	else
		warn("can not get Pet's tid")
		return 0
	end
end

def.override().OnClick = function (self)
	CEntity.OnClick(self)
end

def.override("=>", "string").GetModelPath = function (self)
	return self._AssociatedMonsterTemplate.ModelAssetPath
end

def.override("=>", "number").GetRadius = function(self)
    return 0.5
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.PET
end

def.override("boolean").EnableCullingVisible = function (self, visible)
	if self._Model ~= nil and not self:IsLogicInvisible() then
		self._Model:SetVisible(visible)
	end

	if visible and not self._IsCullingVisible and not self:IsLogicInvisible() and self:GetCurStateType() == FSM_STATE_TYPE.IDLE then
		self:Stand()
	end
	self._IsCullingVisible = visible
	self:EnableShadow(self._IsEnableShadow)     --刷新
end

def.method("number").SetOwnerId = function(self, ownerId)
	self._OwnerId = ownerId
end

def.method("=>", "number").GetOwnerId = function(self)
	return self._OwnerId
end

def.method("string").UpdateName = function(self, name)
	self._InfoData._Name = name
end

def.method().SetColorName = function(self)
	local owner = game._CurWorld:FindObject( self:GetOwnerId() )
	if owner ~= nil then
		local colorname = owner:GetPetColorName(self._InfoData._Name)
		self._TopPate:SetName(colorname)
	end
end

def.method().PlayTalentAnimation = function(self)
    if not self._IsReady then return end

    local model = self:GetCurModel()
    if model ~= nil then
		model:PlayAnimation(EnumDef.CLIP.LEVELUP, 0, false, 0, 1)
		model:PlayAnimation(EnumDef.CLIP.COMMON_STAND, 0, true, 0, 1)
    end
end

def.method().PlayIdelAnimation = function(self)
	if not self._IsReady then return end

    local model = self:GetCurModel()
    if model ~= nil then
		model:PlayAnimation(EnumDef.CLIP.TALK_IDLE, 0, false, 0, 1)
		model:PlayAnimation(EnumDef.CLIP.COMMON_STAND, 0, true, 0, 1)
    end

    self:BeginIdleState()
end

def.override("boolean", "number", "number", "number", 'table').UpdateState = function(self, add, state_id, duration, originId, info)
    CEntity.UpdateState(self, add, state_id, duration, originId, info) 

    if add then
    	self:PlayTalentAnimation()
    end
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

def.override().BeginIdleState = function(self)
	if self:GetCurStateType() ~= FSM_STATE_TYPE.IDLE then return end
	local function callStateback()
		self:RemoveIdleStateTimer()
		self._IsIdleState = true
		self:StartIdleAnimation()
	end
	self:RemoveIdleStateTimer()
	self._IdleStateTimer = self:AddTimer(5, true, callStateback)
end

--进入休闲状态，开始逻辑操作
def.method().StartIdleAnimation = function(self)		
	local function callback()
		self:RemoveIdleAnimationTimer()
		self:PlayIdelAnimation()
	end
	self:RemoveIdleAnimationTimer()
	self._IdleAnimationTimer = self:AddTimer(5, true, callback)
end

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

def.method().ClearIdleState = function(self)
	self:RemoveIdleAnimationTimer()	
	self:RemoveIdleStateTimer()
	self._IsIdleState = false
end

def.override().Release = function (self)
	self:ClearIdleState()

	CEntity.Release(self)
	game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogEnd, self)
end

CPet.Commit()
return CPet