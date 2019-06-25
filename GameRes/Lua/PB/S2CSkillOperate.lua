--
--S2CSkillOperate
--

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CElementSkill = require "Data.CElementSkill"
local ErrorCode = require "PB.net".S2CSkillOperateErrorCode
local ENUM_SKILLPROPERTY = require "PB.data".ENUM_SKILLPROPERTY
local CElementData = require "Data.CElementData"
local DoSkillChange = require "Skill.CSkillUtil".MakeUniqueSkillData
local EnumLearnType = require "PB.Template".SkillLearnCondition.EnumLearnType	

local function PopChatMsg(str)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
	local msg = str    
	if msg ~= nil then
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
    end
end

local function OnSkillError(errorCode)
	if errorCode == ErrorCode.OK then
		--成功
	elseif errorCode == ErrorCode.SKILL_NOT_FIND then
		game._GUIMan:ShowTipText(StringTable.Get(121), false)
	elseif errorCode == ErrorCode.SKILL_NOT_LEARN then
		game._GUIMan:ShowTipText(StringTable.Get(111), false)	

	elseif errorCode == ErrorCode.SKILL_LEVELUP_NEXT_LEVEL_NOT_FIND then
		game._GUIMan:ShowTipText(StringTable.Get(122), false)	
	elseif errorCode == ErrorCode.SKILL_LEVELUP_GOLD_NOT_ENOUGH then
		game._GUIMan:ShowTipText(StringTable.Get(123), false)
	elseif errorCode == ErrorCode.SKILL_LEVELUP_TEMPLATE_NOT_FIND then
		game._GUIMan:ShowTipText(StringTable.Get(124), false)
	end
end

local function OnNotifyRuneEvent(eventType)
	local NotifyRuneEvent = require "Events.NotifyRuneEvent"
	local event = NotifyRuneEvent()
	event.Type = eventType
	CGame.EventManager:raiseEvent(nil, event)

	-- 纹章可以改变CD数据
	local SkillCDEvent = require "Events.SkillCDEvent"
	local event = SkillCDEvent()
	CGame.EventManager:raiseEvent(nil, event)
end

--初始接收技能数据(只接收改变的数据)
local function OnS2CSkillOperateInfo(sender, msg)
	local hp = game._HostPlayer
	if msg.roleId ~= hp._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			if object == nil then return end

			local skills = {}
			for i,v in ipairs(msg.skillInfoRe.SkillInfoDatas) do				
				skills[#skills + 1] = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, TalentAdditionLevel = v.TalentAdditionLevel, Skill = DoSkillChange(v, object) }
			end
			object._UserSkillMap = skills
		end
	else	
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			hp._ActiveRuneConfigId = msg.skillInfoRe.ActivityConfigId
			local skills = {}
			for i,v in ipairs(msg.skillInfoRe.SkillInfoDatas) do			
				skills[#skills + 1] = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, 
				Skill = DoSkillChange(v), TalentAdditionLevel = v.TalentAdditionLevel, SkillRuneInfoDatas = v.SkillRuneInfoDatas }
			end
			game:InitHostPlayerSkill(skills)
			
			local CSkillUtil = require "Skill.CSkillUtil"
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())
		end
	end
end

PBHelper.AddHandler("S2CSkillOperateInfo", OnS2CSkillOperateInfo)

-- 遗忘技能
local function OnS2CSkillRemove(sender, msg)
	local skillRemove = {}
	for i, v in ipairs(msg.SkillIds) do
		skillRemove[v] = v
	end

	local UserSkillMap = game._HostPlayer._UserSkillMap
	local skillNew = {}
	for k,v in pairs(UserSkillMap) do
		if skillRemove[v.SkillId] == nil then
			skillNew[#skillNew + 1] = v
		end
	end
	game:InitHostPlayerSkill(skillNew)
	local GainNewSkillEvent = require "Events.GainNewSkillEvent"
	local e = GainNewSkillEvent()
	e.SkillId = -1
	CGame.EventManager:raiseEvent(nil, e)
end

PBHelper.AddHandler("S2CSkillRemove", OnS2CSkillRemove)

local function OnS2CSkillOperateLearn(sender, msg)
	local game = game
	local hp = game._HostPlayer
	if msg.roleId ~= hp._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i,v in ipairs(msg.skillLearnRe.SkillInfoDatas) do
				local userSkillMap = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, TalentAdditionLevel = v.TalentAdditionLevel,Skill = DoSkillChange(v, object) }
				table.insert(object._UserSkillMap, userSkillMap)
			end
		end
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			for i,v in ipairs(msg.skillLearnRe.SkillInfoDatas) do
				local userSkillMap = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, TalentAdditionLevel = v.TalentAdditionLevel,
				Skill = DoSkillChange(v) , SkillRuneInfoDatas = v.SkillRuneInfoDatas }
				table.insert(hp._UserSkillMap, userSkillMap)
				hp._MainSkillLearnState[v.SkillId] = true
				
				--给予提示
				if not game:IsInBeginnerDungeon() then
					local skillLearnTemp = hp:GetSkillLearnConditionTemp(v.SkillId)		
					if skillLearnTemp and skillLearnTemp.RoleLearnType == EnumLearnType.Level then
						local CGameTipsQueue = require "GUI.CGameTipsQueue"
						game._CGameTipsQ:ShowNewSkillTip(v.SkillId)
					end
				end

				local GainNewSkillEvent = require "Events.GainNewSkillEvent"
				local e = GainNewSkillEvent()
				e.SkillId = v.SkillId
				CGame.EventManager:raiseEvent(nil, e)
			end

			local CSkillUtil = require "Skill.CSkillUtil"
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateLearn", OnS2CSkillOperateLearn)

local function OnS2CSkillOperateLevelUp(sender, msg)
	local game = game
	local hp = game._HostPlayer
	if msg.roleId ~= hp._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i,v in ipairs(object._UserSkillMap) do
				for j,w in ipairs(msg.skillLevelUpRe.SkillInfoDatas) do
					if v.SkillId == w.SkillId then
						v.SkillId = w.SkillId
						v.SkillLevel = w.SkillLevel
						v.TalentAdditionLevel = w.TalentAdditionLevel
						v.Skill = DoSkillChange(w, object)
						return
					end
				end
			end
		end
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			for i,v in ipairs(hp._UserSkillMap) do
				for j,w in ipairs(msg.skillLevelUpRe.SkillInfoDatas) do
					if v.SkillId == w.SkillId then
						v.SkillId = w.SkillId
						v.SkillLevel = w.SkillLevel
						v.TalentAdditionLevel = w.TalentAdditionLevel
						v.Skill = DoSkillChange(w)

						if not msg.IsLevelUpAll and not msg.IsModifyByTalent then
							local skill = CElementSkill.Get(w.SkillId)
							if skill ~= nil then
								PopChatMsg(string.format(StringTable.Get(117), skill.Name, v.SkillLevel))
							end
						end					
					end
				end
			end

			if msg.IsLevelUpAll	then
				PopChatMsg(StringTable.Get(118))
			end
			
			if not msg.IsModifyByTalent then
				game._GUIMan:ShowTipText(StringTable.Get(120), false)
			end

			local SkillLevelUpEvent = require "Events.SkillLevelUpEvent"
			local e = SkillLevelUpEvent()
			CGame.EventManager:raiseEvent(nil, e)
		end
		local CSkillUtil = require "Skill.CSkillUtil"
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())		
	end
end
PBHelper.AddHandler("S2CSkillOperateLevelUp", OnS2CSkillOperateLevelUp)

local function OnS2CSkillOperateRune(sender, msg)
	local hp = game._HostPlayer
	if msg.roleId ~= hp._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i, v in ipairs(msg.skillRuneRe.SkillInfoDatas) do
				local skillData = hp:GetSkillData(v.SkillId)
				if skillData ~= nil then
					skillData.Skill = DoSkillChange(v)
					skillData.SkillRuneInfoDatas = v.SkillRuneInfoDatas
				end
			end
		end
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			for i, v in ipairs(msg.skillRuneRe.SkillInfoDatas) do
				local skillData = hp:GetSkillData(v.SkillId)
				if skillData ~= nil then
					skillData.Skill = DoSkillChange(v)
					skillData.SkillRuneInfoDatas = v.SkillRuneInfoDatas
				end
			end
			-- 穿戴纹章不在聊天框中显示
			-- local rune = CElementSkill.GetRune(msg.skillRuneRe.runeId)
			-- if msg.IsActive and rune then
			-- 	PopChatMsg(string.format(StringTable.Get(119), rune.Name))
			-- end
			
			OnNotifyRuneEvent("Level")
			OnNotifyRuneEvent("Config")

			
		end

		local CSkillUtil = require "Skill.CSkillUtil"
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())		
	end
end
PBHelper.AddHandler("S2CSkillOperateRune", OnS2CSkillOperateRune)

local function OnS2CSkillOperateRuneConfig(sender, msg)
	local hp = game._HostPlayer
	if msg.roleId ~= hp._ID then
		--服务器这里会等效于有人更改激活符文
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then			
			hp._ActiveRuneConfigId = msg.skillRuneConfigRe.ActivityConfigId
			for i, v in ipairs(msg.skillRuneConfigRe.SkillInfoDatas) do
				local skillData = hp:GetSkillData(v.SkillId)
				if skillData ~= nil then
					skillData.Skill = DoSkillChange(v)
					skillData.SkillRuneInfoDatas = v.SkillRuneInfoDatas
				end
			end
			if msg.IsActive then
				OnNotifyRuneEvent("Config")
			end
			local CSkillUtil = require "Skill.CSkillUtil"
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())			

			if msg.IsActive then
				local config_level = ""
				if msg.skillRuneConfigRe.ActivityConfigId == 0 then
					config_level = "I"
				elseif msg.skillRuneConfigRe.ActivityConfigId == 1 then
					config_level = "II"
				else
					config_level = "III"
				end		
				PopChatMsg(string.format(StringTable.Get(169), config_level))
			end
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateRuneConfig", OnS2CSkillOperateRuneConfig)

local function OnS2CSkillPerformFailed(sender, msg)
	-- 其它玩家应该没有，因为如果释放不出来，不会广播给周围人 只会在本地看到
	local host = game._HostPlayer
	if msg.roleId == host._ID then
		host._SkillHdl:OnSkillFailed(msg.skillId, msg.position)

		local CSkillUtil = require "Skill.CSkillUtil"
		local err_content = CSkillUtil.GetSkillFailedCodeEx(msg.ret)
		print("SkillPerformFailed RrrCode = ".. msg.ret .. " ErrContent = ".. err_content.." SkillId = ".. msg.skillId)
		if msg.ret == 8 then
			local pos = host:GetPos()
			print("InvalidDistance Check! HostPlayer Pos:", pos.x, pos.z)
			print("InvalidDistance Check! Last SyncPos:", _G.lastIsStop, _G.lastHostPosX, _G.lastHostPosZ, _G.lastDestPosX, _G.lastDestPosZ)
		end

		--[[
		-- OnSkillFailed中会对自动换进行处理
		local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
		if CDungeonAutoMan.Instance():IsOn() then
			CDungeonAutoMan.Instance():ChangeGoal()
		end
		]]
	end
	
end
PBHelper.AddHandler("S2CSkillPerformFailed", OnS2CSkillPerformFailed)


local function OnS2CSkillMasterySyncInfo(sender, msg)
	local hp = game._HostPlayer
	hp:SetSkillMasteryInfoList(msg.SkillMasterys, msg.FightScore)

	local CPanelUISkill = require 'GUI.CPanelUISkill'
	if CPanelUISkill and CPanelUISkill.Instance():IsShow() then
		CPanelUISkill.Instance():UpdatePageSkillMastery()
	end
	local CSkillUtil = require "Skill.CSkillUtil"
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())	
end
PBHelper.AddHandler("S2CSkillMasterySyncInfo", OnS2CSkillMasterySyncInfo)

-- ResCode        = 2; //结果Code
-- Tid            = 3; //当前Tid  
-- NextTid        = 4; //下一级Tid  
local function OnS2CSkillMasteryUpgradeRes(sender, msg)
	if msg.ResCode ~= 0 then
		game._GUIMan:ShowErrorTipText(msg.ResCode)
		return 
	end

	game._HostPlayer:UpdateSkillMasteryInfo(msg)

	local panelUISkill = require 'GUI.CPanelUISkill'.Instance()
	if panelUISkill:IsShow() then
		panelUISkill:UpdatePageSkillMastery()
	end
	local CSkillUtil = require "Skill.CSkillUtil"
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())	


	local tmp = CElementData.GetSkillMasteryTemplate(msg.Tid)
	if tmp then
		PopChatMsg(string.format(StringTable.Get(170), tmp.Name))
		game._GUIMan:ShowTipText(string.format(StringTable.Get(170), tmp.Name), false)
	end
end
PBHelper.AddHandler("S2CSkillMasteryUpgradeRes", OnS2CSkillMasteryUpgradeRes)

