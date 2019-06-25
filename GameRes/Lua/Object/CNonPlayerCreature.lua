local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local ObjectInfoList = require "Object.ObjectInfoList"
local CElementData = require "Data.CElementData"
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality

local CGame = Lplus.ForwardDeclare("CGame")
local CModel = require "Object.CModel"

local CNonPlayerCreature = Lplus.Extend(CEntity, "CNonPlayerCreature")
local def = CNonPlayerCreature.define

def.field("table")._AffixNames = BlankTable
def.field("userdata")._IconModel = nil
def.field("table")._MonsterTemplate = nil 

-- info is MonsterInfo
def.override("table").Init = function(self, info)
	local creature_info = info.CreatureInfo
	local entity_info = creature_info.MovableInfo.EntityInfo
	CEntity.Init(self, entity_info)
	self._MonsterTemplate = CElementData.GetMonsterTemplate(info.MonsterTid)
	self._InfoData = ObjectInfoList.CNPCInfo()

	self._InfoData._TID = info.MonsterTid
	self._InfoData._Name = creature_info.Name
	self._InfoData._Level = creature_info.Level

	self._InfoData._CurShield = creature_info.ShieldValue
	self._InfoData._MaxHp = creature_info.MaxHp
	self._InfoData._CurrentHp = creature_info.CurrentHp
	self._InfoData._MaxStamina = creature_info.MaxStamina
	self._InfoData._CurrentStamina = creature_info.CurrentStamina
	self._CampId = creature_info.CampId

	if info.OwnerName ~= nil then
		self._InfoData._OwnerName = info.OwnerName
	end

	if info.CreaterId ~= nil then
		self._InfoData._CreaterId = info.CreaterId
	end

	self._InfoData._AffixIds = creature_info.AffixIds
	self._EnemyCampTable = creature_info.EnemyCampList

	self._IsInCombatState = creature_info.CombatState
	self:UpdateSealInfo(creature_info.BaseStates)
	self:SetCurrentTargetId(creature_info.CurrentTargetId)
	self:InitStates(creature_info.BuffStates)
	self:InitMagicControls(creature_info.MagicControlStates)	
	self:InitAnimationTable(creature_info.AnimationInfos)
end

def.virtual("=>", "string").GetModelPath = function (self)
	return ""
end

def.override("=>", "number").GetRenderLayer = function (self)
    return EnumDef.RenderLayer.NPC
end

def.virtual("=>", "boolean").HasMutipleProgress = function(self)
	return self._MonsterTemplate.MonsterQuality == EMonsterQuality.LEADER or 
		   self._MonsterTemplate.MonsterQuality == EMonsterQuality.BEHEMOTH or
		   self._MonsterTemplate.MonsterQuality == EMonsterQuality.ELITE_BOSS
end

def.virtual("=>","number").GetMonsterQuality = function(self)
	return self._MonsterTemplate.MonsterQuality
end

-- 隐身技能出场
def.method("=>","boolean", "number").GetBirthStealthInfo = function (self)
    if self._MonsterTemplate.BirthSkillId > 0 then
    	local skillTemp = self:GetEntitySkill(self._MonsterTemplate.BirthSkillId)
    	if skillTemp ~= nil then    		
    		for _, v in ipairs(skillTemp.Performs) do
    			for _, unit in ipairs(v.ExecutionUnits) do
    				if unit.Event.Cloak._is_present_in_parent then
						local total = unit.Event.Cloak.FadeinDuration + unit.Event.Cloak.KeepDuration + unit.Event.Cloak.FadeoutDuration
    					return true, total
    				end
    			end    			
    		end
    	end    	
   	end
   	return false, 0 
end

def.override("number", "=>", "string").GetAudioResPathByType = function (self, audio_type) 
    local ret = ""
    if self._MonsterTemplate then
    	if audio_type == EnumDef.EntityAudioType.DeadAudio then
    		ret = self._MonsterTemplate.DeadAudioResPath
    	elseif audio_type == EnumDef.EntityAudioType.HurtAudio then
    		ret = self._MonsterTemplate.HurtAudioResPath 
    	else
    		warn("error occur in GetAudioResPathByType -> an error type : "..tostring(audio_type))
    	end	
    end
    return ret
end


def.override("boolean").Stealth = function(self, on)	
    CEntity.Stealth(self, on)  
    self:AddLoadedCallback(function()   
		    if not on then
		    	self:GetCurModel()._GameObject:SetActive(true)
		    	self:Stand()
		    end
    	end)
end


def.virtual("number").Load = function (self, enterType)
	local model_path = self:GetModelPath()
	
	local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
	self._Model = m
	
	local on_model_loaded = function(ret)
		if ret then
			if self._IsReleased then
				m:Destroy()
			else
				self:AddObjectComponent(false, 0.4)  -- self:GetRadius()
				GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.NPC)	

				-- 调整Body大小
				local scale = self._MonsterTemplate.BodyScale
				if scale > 0 then
					self._GameObject.localScale = Vector3.one * scale
				else
					warn("DataError: MonsterTemplate.BodyScale == 0 , tid = ", self._MonsterTemplate.Id)
				end

				self._IsReady = true			

				if enterType == EnumDef.SightUpdateType.NewBorn and self._MonsterTemplate.BirthSkillId > 0 then
					-- 如果有出生技能，将模型置于出生动画第一帧
					self:PlayAnimation(EnumDef.CLIP.BORN, 0, false, 0, 0)
				end
				self:OnModelLoaded()
				
				--if self._MonsterTemplate.IsShowShadow then
				--	self:EnableShadow(true)	
				--end

				-- 上面有top pate 的处理
				if enterType == EnumDef.SightUpdateType.NewBorn and self._MonsterTemplate.BirthSkillId > 0 then
					-- 这里存在前规则，必须是上来就立即隐身才符合逻辑  -- added by Jerry
					local isStealth, lastTime = self:GetBirthStealthInfo()  
					if isStealth then
						self:Stealth(true)  -- Stealth中包含了左右Renderer的处理，包括影子
						self:AddTimer(lastTime/1000, true ,function()
						        self:Stealth(false)
						    end)
					end
				else
					if self:GetCurStateType() == FSM_STATE_TYPE.NONE then
						self:Stand()	
					end
				end
			end
		else
			warn("Failed to load model with path = " .. model_path)
		end
	end

	if model_path ~= "" then
		m:Load(model_path, on_model_loaded)
	else
		warn("Data Error: NPC's model path is empty")
	end
end

def.override().OnClick = function (self)
	if not self:CanBeSelected() then return end

	CEntity.OnClick(self)
	local hostplayer = game._HostPlayer
	hostplayer:UpdateTargetInfo(self, true)
end

def.override().CreatePate = function (self)
	local CNPCTopPate = require "GUI.CPate".CNPCTopPate
	local pate = CNPCTopPate.new()
	self._TopPate = pate
--	local callback = function()
--		self:OnPateCreate()
--		--self._TopPate:OnTitleNameChange(true,"测试头衔牛不牛")
--	end

	pate:Init(self, nil, false)
	self:OnPateCreate()
end

def.override().OnPateCreate = function(self)
	CEntity.OnPateCreate(self)
	if self._TopPate == nil then return end

	self._TopPate:MarkAsValid(true)
	if not self:IsVisible() then 
		self._TopPate:SetVisible(false)
	end
	self._TopPate:UpdateName(true)
	local titleStr = self:GetTitle()
	if titleStr ~= "" then
		self._TopPate:OnTitleNameChange(true, titleStr) 
	end
end

def.virtual("=>", "string").GetTitle = function(self)
	local str = ""
	if self._MonsterTemplate ~= nil then
		if self._MonsterTemplate.Title ~= nil then
			str = self._MonsterTemplate.Title
		end
	end

	--如果有所属玩家的话 显示所属玩家 不显示头衔
	if str == "" and self._InfoData._OwnerName ~= nil and self._InfoData._OwnerName~= "" then
		str = self._InfoData._OwnerName..StringTable.Get(22)
	end
	return str
end

def.virtual("table").SetAffixIds = function(self, affixIds)
	self._InfoData._AffixIds = affixIds
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._MonsterTemplate == nil then 
		warn("self._MonsterTemplate is nil", debug.traceback())
		return 0
	end
	
	return self._MonsterTemplate.Id
end

def.virtual("=>", "table").GetMonsterTemplate = function(self)
	return self._MonsterTemplate
end

def.override("string","=>","string","boolean").GetAnimationName = function (self,nowAniname)
	local isReplace = false
    if self._AnimationReplaceTable ~= nil then 
	    local newAniName = self._AnimationReplaceTable[nowAniname]
    	if newAniName then
        	isReplace = true
        	return newAniName,isReplace
    	end
	end
	if self._MonsterTemplate and self._MonsterTemplate.new1 ~= nil and self._MonsterTemplate.new1 ~= "" and self._MonsterTemplate.old1 ~= nil
	and self._MonsterTemplate.old1 ~= ""  then 
		if nowAniname == self._MonsterTemplate.old1 then 
			isReplace = true
    		return self._MonsterTemplate.new1,isReplace
    	end
    end
    return nowAniname,isReplace
end

def.override("=>","number","number").GetBaseSpeedAndFightSpeed = function(self)
    return self._MonsterTemplate.MoveSpeed,self._MonsterTemplate.DefaultFightMoveSpeed
end

def.virtual("=>", "number").GetLevel = function(self)
	return self._InfoData._Level
end

def.virtual().ResetAffix = function(self)
	--warn("ResetAffix .. count= ", #self._InfoData._AffixIds)
	if #self._InfoData._AffixIds > 0 then
		self._AffixNames = {}

		for i,id in ipairs(self._InfoData._AffixIds) do
			local nameId = id * GlobalDefinition.MonsterLevelPropertyIdStep + 1
			local data = CElementData.GetTemplate("MonsterAffix", nameId)
			if data then 
				local name = data.Name
				local map = {}
				map.Name = name

				local dataId = id * GlobalDefinition.MonsterLevelPropertyIdStep + self._InfoData._Level
				data = CElementData.GetTemplate("MonsterAffix", dataId)
				map.Data = data

				local talentData = CElementData.GetTemplate("Talent", data.TalentId)
				map.IconPath = talentData.Icon
				map.TalentData = talentData
				table.insert(self._AffixNames, map)
			end
		end
	end
end

def.virtual("=>", "table").GetAffix = function(self)
	if #self._AffixNames == 0 then
		self:ResetAffix()
	end

	return self._AffixNames
end

CNonPlayerCreature.Commit()
return CNonPlayerCreature