local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CStateMachine = require "FSM.CStateMachine"
local CElementData = require "Data.CElementData"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CSkillSealInfo = require "Skill.CSkillSealInfo"
local ObjectInfoList = require "Object.ObjectInfoList"
local CSharpEnum = require "Main.CSharpEnum"
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = require "Quest.CQuest"
local QuestDef = require "Quest.QuestDef"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CTransManage = require "Main.CTransManage"
local CNpc = Lplus.Extend(CNonPlayerCreature, "CNpc")
local def = CNpc.define

def.field("dynamic")._NpcTemplate = nil
def.field("boolean")._IsInService = false
def.field("function")._OnUpdateQuestInfo = nil
def.field("string")._CurOverheadModelPath = ""
def.field("userdata")._StandBehaviourComp = nil
def.field("table")._OrignalDir = nil
def.field("boolean")._ServiceOpenFlag = true
def.field("table")._FirstQuestInfo = nil  -- 优先级最高的任务信息


def.static("=>", CNpc).new = function ()
	local obj = CNpc()
	obj._CurLogoType = -2
	obj._FSM = CStateMachine.new()
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._SealInfo = CSkillSealInfo.new(obj)
	obj._SkillHdl = CObjectSkillHdl.new(obj)
	obj._FadeOutWhenLeave = true
	return obj
end

def.override("table").Init = function (self, info)
	CNonPlayerCreature.Init(self, info.MonsterInfo)
	self._NpcTemplate = CElementData.GetNpcTemplate(info.NpcTid)
	self._ServiceOpenFlag = info.ServiceOpenFlag
	self._InfoData._Name = self._NpcTemplate.TextOverlayDisplayName
end

def.method().ListenToEvent = function(self)
	local UpdateQuestInfo = function(sender, event)
		self:OnQuestStatusChange()
	end
	local HostPlayerLevelChangeEvent = require "Events.HostPlayerLevelChangeEvent"
	CGame.EventManager:addHandler(HostPlayerLevelChangeEvent, UpdateQuestInfo)

	self._OnUpdateQuestInfo = UpdateQuestInfo
end

def.method().UnlistentToEvent = function (self)
	if self._OnUpdateQuestInfo == nil then return end

	local HostPlayerLevelChangeEvent = require "Events.HostPlayerLevelChangeEvent"
	CGame.EventManager:removeHandler(HostPlayerLevelChangeEvent, self._OnUpdateQuestInfo)

	self._OnUpdateQuestInfo = nil
end

def.override().OnModelLoaded = function(self)
	CNonPlayerCreature.OnModelLoaded(self)
	self:OnQuestStatusChange()
	self:ListenToQuestChangeEvent()
	self:ListenToEvent()

	--关闭castShadow
	self:EnableCastShadows(false)

	self:EnableShadow(self._MonsterTemplate.IsShowShadow)
end

def.override("=>", "string").GetRelationWithHost = function(self)  -- 仇恨列表 > 队伍 > 阵营 > 公会 > PK关系 
	-- 先做仇恨列表判断，如果在仇恨列表中，即为敌人
	local hp = game._HostPlayer
	if hp:IsEntityHate(self._ID) then
		return RelationDesc[2]
	end
	-- 阵营 势力关系判断
	local relation, IsZYFriend = CEntity.GetRelationWith(self, hp)
	if IsZYFriend then 	-- 如果有阵营，判断阵营是否友好和敌对
		-- warn("=================lidaming=====================")
		if relation == "Enemy" or relation == "Friendly" then
			return relation
		end
	end
    return RelationDesc[1]
end


def.override("=>","string").GetEntityColorName = function(self)
	local name = self._InfoData._Name
	local relation = self:GetRelationWithHost()
	if relation == "Neutral" then
		name = "<color=#E7CF89>"..name.."</color>"
	elseif relation == "Friendly" then
		name = "<color=white>"..name.."</color>"
	elseif relation == "Enemy" then
		name = "<color=#FA3319>"..name.."</color>"
	end
    return name
end

def.override().OnPateCreate = function(self)
	CNonPlayerCreature.OnPateCreate(self)
	if self._TopPate == nil then return end

	self._TopPate:SetVisible(true)
	self._TopPate:SetHPLineIsShow(false, EnumDef.HPColorType.None)
	self._TopPate:UpdateName(true)
	self:OnQuestStatusChange()
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._NpcTemplate ~= nil then
		return self._NpcTemplate.Id
	else
		warn("can not get npc's tid")
		return 0
	end
end

--检测站立动画有无其他配置动画名称（Npc有重载）
def.override("=>","string").GetStandAnimationName = function(self)
	local animation ,_ = self:GetAnimationName(EnumDef.CLIP.COMMON_STAND)
	return animation
end

-- npc模板中的替换动画数据 覆盖所关联的monster数据(服务器覆盖模板)
def.override("string","=>","string","boolean").GetAnimationName = function (self,Aniname)
    local isReplace = false
    if self._AnimationReplaceTable ~= nil then 
	    local newAniName = self._AnimationReplaceTable[Aniname]
    	if newAniName then
        	isReplace = true
        	return newAniName,isReplace
    	end
	end
	if self._NpcTemplate ~= nil then 
		if self._NpcTemplate.new1 ~= nil and self._NpcTemplate.new1 ~= "" and self._NpcTemplate.old1 ~= nil and self._NpcTemplate.old1 ~= ""  then 
			if Aniname == self._NpcTemplate.old1 then 
				isReplace = true
	    		return self._NpcTemplate.new1 ,isReplace
	    	end
	    else
	    	local monsterId = self._NpcTemplate.AssociatedMonsterId
	    	local monsterTem = CElementData.GetMonsterTemplate(monsterId)
	    	if monsterTem ~= nil then 
				if monsterTem.new1 ~= nil and monsterTem.new1 ~= "" and monsterTem.old1 ~= nil and monsterTem.old1 ~= ""  then 
					if Aniname == monsterTem.old1 then 
						isReplace = true
	    				return monsterTem.new1,isReplace
	    			end
				end
	    	end
	    end
    end
    return Aniname,isReplace
end

def.override("=>", "string").GetTitle = function(self)
	local str = ""
	if self._NpcTemplate.Title ~= nil then
		str = self._NpcTemplate.Title
	end
	return str
end

-- 通过场景的图标去确定服务类型，这种数据索引方式不合适
-- 需要重新进行梳理
-- added by lijian
local MapIcon2LogpType =
{
	Map_Img_Shop = 3, --EnumDef.EntityLogoType.Shop,
	Map_Img_Fight = 4, --EnumDef.EntityLogoType.Fight,
	Map_Img_Store = 5, --EnumDef.EntityLogoType.Store,
	Map_Img_Skill = 6, --EnumDef.EntityLogoType.Skill,
}

local function GetNpcServiceLogoType(self)
	local logo = EnumDef.EntityLogoType.None
	local MapBasicConfig = require "Data.MapBasicConfig" 
	local _, npcMapInfoList = MapBasicConfig.GetEntityInfo("Npc", self:GetTemplateId())
	if npcMapInfoList ~= nil and #npcMapInfoList > 0 then
		local icon = ""
		if npcMapInfoList[1].MapIcon ~= nil then
			icon = npcMapInfoList[1].MapIcon
		end
		if MapIcon2LogpType[icon] ~= nil then
			logo = MapIcon2LogpType[icon]
		end
	end

	return logo
end

local function RemoveIconModel(self)
	if not IsNil(self._IconModel) then
		Object.Destroy(self._IconModel)
		self._IconModel = nil
		self._CurOverheadModelPath = ""
	end
end

def.override().OnQuestStatusChange = function (self)
	local showQuestModel, curLogoType = self:CheckAndUpdateQuestStatus()
	if not showQuestModel then
		-- 如果不显示任务状态模型，也不显示任务对话图标，显示NPC服务标识
		if curLogoType == EnumDef.EntityLogoType.None then
			curLogoType = GetNpcServiceLogoType(self)
		end
	end
	
	if self._CurLogoType ~= curLogoType and self._TopPate ~= nil then
		self._TopPate:OnLogoChange(curLogoType)
    end
end

-- 检查当前NPC是否有可领取/进行中/可交付的任务，如果有 更新头顶模型
def.method("=>", "boolean", "number").CheckAndUpdateQuestStatus = function (self)
	local firstQuest = CQuest.Instance():GetNPCFirstQuest(self._NpcTemplate)
	local questType = 0
	local questStatus = 0
	if firstQuest ~= nil then
		questType = firstQuest[3]
		questStatus = firstQuest[2]
	end 
	self._FirstQuestInfo = firstQuest

	--判断有无赏金服务
	--local isHasCyclicQuestServer = false

	local pathName = ""
	local logoType = EnumDef.EntityLogoType.None
	-- 如果第一个是交付任务，显示头顶叹号
	if questStatus == QuestDef.QuestFunc.CanDeliver then
		pathName = "Model_QuestCanDeliver" .. questType
	-- 检查当前对象是否是任务交谈目标
	elseif CQuest.Instance():IsMyConversationTarget(self:GetTemplateId()) or CQuest.Instance():IsMyBuyTarget(self:GetTemplateId()) then
		logoType = EnumDef.EntityLogoType.Talk
	-- 如果第一个是领取任务，显示头顶叹号
	elseif questStatus == QuestDef.QuestFunc.CanProvide then
		pathName = "Model_QuestCanProvide" .. questType
	elseif questStatus == QuestDef.QuestFunc.GoingOn then
		pathName = "Model_QuestInProgress" .. questType
	-- elseif isHasCyclicQuestServer then
	-- 	local QuestDef = require "Quest.QuestDef"
	-- 	pathName = "Model_QuestCanProvide" .. QuestDef.QuestType.Reward
	else
		--判断有无随机任务服务
		local QuestUtil = require "Quest.QuestUtil"
		local isHasQuestRandGroupServer = QuestUtil.HasQuestRandGroupServer(self._NpcTemplate)
		if isHasQuestRandGroupServer then
			pathName = "Model_QuestCanProvide5"
		end
	end


					


	--self._TopPate:OnLogoChange(logoType)
	if pathName ~= self._CurOverheadModelPath then
		RemoveIconModel(self)
		self._CurOverheadModelPath = pathName

		if pathName == nil or pathName == "" then
			return false, logoType
		end

		if PATH[pathName] ~= nil then
			local function loaded(res)
				if pathName == "" or res == nil or self._IsReleased then return end
				self:AddLoadedCallback(function(p)
					local obj = self:GetGameObject()
					if IsNil(obj) then return end
					if self._CurOverheadModelPath == "" or self._CurOverheadModelPath ~= pathName then return end
					self._IconModel = Object.Instantiate(res)
					GameUtil.SetLayerRecursively(self._IconModel, EnumDef.RenderLayer.EntityAttached)
					self._IconModel:SetActive(true)
					self._IconModel:SetParent(obj)
					-- 显示在名字上面
					local offset = 2.8
					if self._TopPate ~= nil and not IsNil(self._TopPate._PateObj) then
						local hudft = self._TopPate._PateObj:GetComponent(ClassType.CHUDFollowTarget)
						if hudft ~= nil then
							offset = hudft.Offset.y + 0.4
						end
					end
					self._IconModel.localRotation = Quaternion.identity
					self._IconModel.localPosition = Vector3.New(0, offset, 0)

					local ani = self._IconModel:GetComponent(ClassType.Animation)
					if ani ~= nil then
						ani:Play("chusheng")
						ani:PlayQueued("daiji")
					end
				end)
			end
			GameUtil.AsyncLoad(PATH[pathName], loaded)
		end
	end

	return (pathName ~= "" and pathName ~= nil), logoType
end

def.override().OnClick = function (self)
	if not self:CanHostNaviTo() then return end

	CEntity.OnClick(self)
	local hostplayer = game._HostPlayer
	hostplayer:UpdateTargetInfo(self, true)

	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CDungeonAutoMan.Instance():Stop()
	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Stop()
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	CAutoFightMan.Instance():Pause(_G.PauseMask.ManualControl)

	local function sucessCb()
		CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
		local ophdl = game._HostPlayer._OpHdl
		ophdl._SwitchAutoModeWhenEnd = true
        ophdl:TalkToServerNpc(self, nil)
    end

	local function failedCb()
		CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
	end

    local targetPos = self:GetPos()
    game:NavigatToPos(targetPos, _G.NAV_OFFSET + self:GetRadius(), sucessCb, failedCb)
end

def.override("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	CEntity.UpdateCombatState(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	if is_in_combat_state then
		local hdl = game._HostPlayer._OpHdl
		local curSerNpc = hdl:GetCurServiceNPC()
		if curSerNpc ~= nil and curSerNpc._ID == self._ID then
			game._GUIMan:ShowTipText(StringTable.Get(19413), false)
			hdl:EndNPCService(nil)
		end
	else
		if not self._IsInCombatState then
			self._SkillHdl:StopGfxPlay(EnumDef.EntityGfxClearType.BackToPeace)
		end
	end
end

def.override("=>", "string").GetModelPath = function (self)
	return self._NpcTemplate.ModelAssetPath
end

def.override("=>", "number").GetRadius = function(self)
    return 0.63
end

def.override("=>", "number").GetFaction = function(self)
    return self._NpcTemplate.OverlayFactionId
end

def.override("=>", "number").GetReputation = function(self)
    return self._NpcTemplate.ReputationId
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.NPC
end

-- def.override("=>", "boolean").CanBeSelected = function(self)
--     return self._InfoData._CanBeSelect 
-- end

def.override("=>", "boolean").IsNeedHideHpBarAndName = function(self)
    return self:GetMonsterTemplate().BirthHideHpBarAndName
end

def.override("=>", "userdata").RequireStandBehaviourComp = function (self)
	if not self._Model._GameObject.activeSelf then
		warn("RequireStandBehaviourComp failed, model gameobject is inactive, npc id:", self._ID, debug.traceback())
		return nil
	end

	if self._StandBehaviourComp == nil then 
		self._StandBehaviourComp = self._Model._GameObject:GetComponent(ClassType.NpcStandBehaviour)
		if self._StandBehaviourComp == nil then
			self._StandBehaviourComp = self._Model._GameObject:AddComponent(ClassType.NpcStandBehaviour)
		end

		if self._StandBehaviourComp ~= nil then
			local standAniName = self:GetStandAnimationName()
			self._StandBehaviourComp:Init(standAniName)
		end
	end

	return self._StandBehaviourComp
end

def.override("=>", "userdata").GetStandBehaviourComp = function (self)
	return self._StandBehaviourComp
end

def.method("=>", "boolean").IsBattleUseServer = function(self)
    local services = self._NpcTemplate.Services
	for i, v in ipairs(services) do
		local service = CElementData.GetServiceTemplate(v.Id)
		if service.IsBattleUse then
			return true
		end
	end
	return false
end

def.method("function").EnterService = function(self, cb)
	-- 播放服务音效
	-- TODO:
	self._IsInService = true

	self:AddLoadedCallback(function()
			if not self._IsInService or self._IsReleased then return end
			local function DoControlNpc()
				local comp = self:RequireStandBehaviourComp()
				if comp ~= nil then
					comp:StartNpcTalk()
				end

				if cb ~= nil then cb() end
			end

			-- 朝向主角
			if self._NpcTemplate.IsClickTurn then
				self._OrignalDir = self:GetDir()
				local dir = game._HostPlayer:GetPos() - self:GetPos()
				GameUtil.AddTurnBehavior(self._GameObject, dir, 300, DoControlNpc, false, 0)
			else
				DoControlNpc()
			end
		end)
end

def.method().ExitService = function(self)
	if self._OrignalDir ~= nil then
		if self._GameObject ~= nil then
			GameUtil.AddTurnBehavior(self._GameObject, self._OrignalDir, 300, nil, false, 0)
		end
		self._OrignalDir = nil
	end
	
	self._IsInService = false
end

def.method("=>", "table").GetFirstQuestInfo = function (self)
	return self._FirstQuestInfo
end
	
def.override().Release = function (self)
	local hdl = game._HostPlayer._OpHdl
	local curSerNpc = hdl:GetCurServiceNPC()
	if curSerNpc ~= nil and curSerNpc._ID == self._ID then	
		hdl:EndNPCService(nil)
	end
	
	self._FirstQuestInfo = nil

	RemoveIconModel(self)

	self:UnlistentToEvent()

	CEntity.Release(self)
	--game._GUIMan:Close("CNpcShortCut")
	game:RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogEnd, self)
end

CNpc.Commit()
return CNpc