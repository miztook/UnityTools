 local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CModel = require "Object.CModel"
local CEntityMan = require "Main.CEntityMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CStateMachine = require "FSM.CStateMachine"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFxObject = require "Fx.CFxObject"

local CMineral = Lplus.Extend(CEntity, "CMineral")
local def = CMineral.define

def.field("dynamic")._MineralTemplate = nil
def.field("number")._TimerId_Animation = 0
def.field("number")._TimerId_Gfx = 0
def.field("number")._TimerId_Sound = 0
def.field("boolean")._CanGather = false
def.field("boolean")._GatherFlag = false
def.field("boolean")._IsFixed = false
def.field(CFxObject)._GfxObject = nil
def.field(CFxObject)._GfxGatherObject = nil


def.static("=>", CMineral).new = function ()
	local obj = CMineral()
	obj._CurLogoType = -2
	obj._FSM = CStateMachine.new()
	return obj
end

def.override("table").Init = function(self, info)
	local entity_info = info.EntityInfo
	CEntity.Init(self, entity_info)
	self._MineralTemplate = CElementData.GetMineTemplate(info.MineTid)
	self:SetGatherFlag(info.GatherFlag)
	self:SetCanGather(not self._GatherFlag)
	self._IsFixed = info.IsFixed
	self:SetCampId(info.CampId)
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._MineralTemplate ~= nil then
		return self._MineralTemplate.Id
	else
		warn("can not get mineral's tid")
		return 0
	end
end

def.method().UpdateCanGatherGfx = function(self)
	if self:GetCanGather() and self:JudgeGatherCount() then
		--可采集特效Path, 对应的字段就这个 DisappearAssetPath ，如有修改再提
		local assetPath = self._MineralTemplate.DisappearAssetPath
		if assetPath ~= nil and self._GfxObject == nil then
		    local parent = self._GameObject
		    if self._MineralTemplate.ManualID ~= 0 then
		       parent = parent:FindChild("wanwuzhicaiji(Clone)/Bone035")
		    end

			self._GfxObject = CFxMan.Instance():PlayAsChild(assetPath, parent, Vector3.zero, Quaternion.identity, -1, false, -1, EnumDef.CFxPriority.Always)
		end
	else
		if self._GfxObject ~= nil then
			self._GfxObject:Stop()
			self._GfxObject = nil
		end
	end
end

def.method("=>","boolean").JudgeGatherCount = function(self)
    --大于被采集次数
    if game._HostPlayer:GetGatherNum(self:GetTemplateId()) >= self._MineralTemplate.GatherNum and self._MineralTemplate.GatherNum ~= 0 then 
    	return false
    end
    return true
end

def.override("=>", "number").GetEntityBodyScale = function(self)	
    return self._MineralTemplate.BodyScale
end

def.method("boolean").SetGatherFlag = function(self, bGatherFlag)
	self._GatherFlag = bGatherFlag
	--不要写在这里 单独调用
	--self:UpdateCanGatherGfx()
end

def.method("boolean").SetCanGather = function(self, bCanGather)
	if self._CanGather == bCanGather then return end
	self._CanGather = bCanGather
	--不要写在这里 单独调用
	--self:UpdateCanGatherGfx()
end

def.method("=>","boolean").GetCanGather = function(self)
	return ((self._GatherFlag == false) and self._CanGather)
end

def.override().CreatePate = function (self)
	local CItemTopPate = require "GUI.CPate".CItemTopPate
	local pate = CItemTopPate.new()
	self._TopPate = pate

	local callback = function()
		self:OnPateCreate()
	end

	pate:Create(self, callback)
end

def.override().OnPateCreate = function (self)
	CEntity.OnPateCreate(self)
	self:OnQuestStatusChange()
end

def.virtual().Load = function (self)
	if self._MineralTemplate == nil then
		warn("CMineral mineTemplate is nil, id")
		return 
	end

	local mine_asset_path = self._MineralTemplate.ModelAssetPath
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
				self:OnModelLoaded()				
				GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.Clickable)
				
				if  self._Model and self._Model:HasAnimation(EnumDef.CLIP.COMMON_STAND) then
					self:Stand()
				end

				if self._InitPos then
					if not self._IsFixed then
						self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
					end
					self._GameObject.position = self._InitPos
				end

				-- 都是朝向，感觉和self._InitDir是重合的 added by lijian
				if self._InitRotation then
					local rot = self._InitRotation
					self._GameObject.rotation = Quaternion.Euler(rot.x, rot.y, rot.z)
				end			

				-- 调整Body大小
				local scale = self._MineralTemplate.BodyScale
				if scale > 0 then
					GameUtil.SetMineObjectScale(self._GameObject, scale)				
				else
					warn("DataError: MineralTemplate.BodyScale == 0 , tid = ", self._MineralTemplate.Id)
				end

				self:UpdateCanGatherGfx()		
			end
		end
	end

	m:Load(mine_asset_path, on_model_loaded )
end

def.method().UpdateHeight = function (self)
	if self._InitPos and self._GameObject then
		if not self._IsFixed then
			self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
		end
		self._GameObject.position = self._InitPos
	end
end

def.override().OnModelLoaded = function (self)
	CEntity.OnModelLoaded(self)
	self:OnQuestStatusChange()
	self:ListenToQuestChangeEvent()
end

def.override().OnQuestStatusChange = function (self)
	if self._TopPate ~= nil then
		local curLogoType = EnumDef.EntityLogoType.None
		local CQuest = require "Quest.CQuest"

		local bIsMyGatherTarget = CQuest.Instance():IsMyGatherTarget(self:GetTemplateId())
		if bIsMyGatherTarget then
			curLogoType = EnumDef.EntityLogoType.Gather
		end

		--如果可以采集打钩 则 肯定可以采集
		if self._MineralTemplate.IsCanGather then
			self:SetCanGather(true)
		else
			--如果不能采集，则判断是否和任务有关联
			if CQuest.Instance():IsMyGatherTarget(self:GetTemplateId()) then
				self:SetCanGather(true)
			else
				self:SetCanGather(false)
			end
		end
		self:UpdateCanGatherGfx()

		self._TopPate:SetVisible(self._CanGather)

		if self._CurLogoType ~= curLogoType then
        	self._TopPate:OnLogoChange(curLogoType)
        end
    end
end

def.override().OnClick = function (self)
	if not self._CanGather then
		return
	end

	local hp = game._HostPlayer
	if self._CampId ~= 0 and hp._CampId ~= self._CampId then
		game._GUIMan:ShowTipText(StringTable.Get(558), false)
		return
	end

    if not self:JudgeGatherCount() then
    	game._GUIMan:ShowTipText(StringTable.Get(503), false)
    	return
    end

	hp:UpdateTargetInfo(self, true)
	local function sucessCb()
		CEntity.OnClick(self)
		local hostskillhdl = hp._SkillHdl
		local skill_id = self._MineralTemplate.SkillId
		hostskillhdl:CastSkill(skill_id, false)
		hp:SetMineGatherId(self._ID)
    end

    local targetPos = self:GetPos()
    game:NavigatToPos(targetPos, _G.NAV_OFFSET + self:GetRadius(), sucessCb, nil)
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.MINE
end

def.override("=>", "number").GetRadius = function(self)
    return self._MineralTemplate.CollisionRadius * self._MineralTemplate.BodyScale
end

def.override("number").DoDisappearEffect = function (self, leaveType)
	if leaveType == EnumDef.SightUpdateType.GatherDestory then
		do -- Gfx
			local assetPath = self._MineralTemplate.EffectAssetPath
			local function DoLogic( self )
				if IsNilOrEmptyString(assetPath) then return end
				self._GfxGatherObject = CFxMan.Instance():PlayAsChild(assetPath, self:GetGameObject(), Vector3.zero, Quaternion.identity, self._MineralTemplate.EffectDuration / 1000, true, -1, EnumDef.CFxPriority.Always)
				self._TimerId_Gfx = 0
			end

			if self._MineralTemplate.EffectDelay > 0 then
				if self._TimerId_Gfx ~= 0 then
					_G.RemoveGlobalTimer(self._TimerId_Gfx)
					self._TimerId_Gfx = 0 
				end

				self._TimerId_Gfx = _G.AddGlobalTimer(self._MineralTemplate.EffectDelay / 1000, true, function()
					DoLogic( self )
				end)
			else
				DoLogic( self )
			end
		end

		do -- Sound
			local assetPath = self._MineralTemplate.AudioAssetPath
			local function DoLogic( self )
				if IsNilOrEmptyString(assetPath) then return end
				CSoundMan.Instance():Play3DAudio(assetPath, self:GetPos(), 0)
				self._TimerId_Sound = 0
			end

			if self._MineralTemplate.AudioDelay > 0 then

				if self._TimerId_Sound ~= 0 then
					_G.RemoveGlobalTimer(self._TimerId_Sound)
					self._TimerId_Sound = 0 
				end

				self._TimerId_Sound = _G.AddGlobalTimer(self._MineralTemplate.AudioDelay / 1000, true, function()
					DoLogic( self )
				end)
			else
				DoLogic( self )
			end
		end

		do  -- Animation
			local function DoLogic( self )
				if self._MineralTemplate.Animation == nil then return end
				self:PlayAnimation(self._MineralTemplate.Animation, 0, false, -1, 1)
				self._TimerId_Animation = 0 
			end

			if self._MineralTemplate.AnimationDelay > 0 then
				if self._TimerId_Animation ~= 0 then
					_G.RemoveGlobalTimer(self._TimerId_Animation)
					self._TimerId_Animation = 0 
				end

				self._TimerId_Animation = _G.AddGlobalTimer(self._MineralTemplate.AnimationDelay / 1000, true, function()
					DoLogic( self )
				end)
			else
				DoLogic( self )
			end
		end
	end
end

-- 设置entity阵营ID
def.override("number").SetCampId = function (self, campId)
    self._CampId = campId
end

def.override("=>", "boolean").IsMineral = function (self)
    return true 
end

def.override().Release = function (self)
	if self._GfxObject ~= nil then
		self._GfxObject:Stop()
		self._GfxObject = nil
	end

	if self._GfxGatherObject ~= nil then
		self._GfxGatherObject:Stop()
		self._GfxGatherObject = nil
	end

	CEntity.Release(self)
end

CMineral.Commit()
return CMineral