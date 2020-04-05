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
local CPanelSkill = require "GUI.CPanelSkill"

--[[
local function TableToString(t)
	local str = ""
	for i,v in ipairs(t) do
		str = str .. " " .. tostring(v)
	end
	return str
end
]]

local DoSkillChange = require "Skill.CSkillUtil".MakeUniqueSkillData

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

local function FireHostSkillChangeEvent()
	local HostSkillInfoChangeEvent = require "Events.HostSkillInfoChangeEvent"
	local event = HostSkillInfoChangeEvent()
	CGame.EventManager:raiseEvent(nil, event)
end

--初始接收技能数据(只接收改变的数据)
local function OnS2CSkillOperateInfo(sender, msg)
	if msg.roleId ~= game._HostPlayer._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			if object == nil then return end

			local skills = {}
			for i,v in ipairs(msg.skillInfoRe.SkillInfoDatas) do				
				skills[#skills + 1] = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, Skill = DoSkillChange(v, object) }
			end
			object._UserSkillMap = skills
		end
	else	
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			game._HostPlayer._ActivityConfigId = msg.skillInfoRe.ActivityConfigId
			local skills = {}
			for i,v in ipairs(msg.skillInfoRe.SkillInfoDatas) do			
				skills[#skills + 1] = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, 
				Skill = DoSkillChange(v), SkillRuneInfoDatas = v.SkillRuneInfoDatas }
			end
			game:InitHostPlayerSkill(skills)
		end
	end
end

PBHelper.AddHandler("S2CSkillOperateInfo", OnS2CSkillOperateInfo)

local hintImgPath = _G.CommonAtlasDir.."Icon/UserTips/Img_Img_NewTips_NewSkill.png"
local function OnS2CSkillOperateLearn(sender, msg)
	if msg.roleId ~= game._HostPlayer._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i,v in ipairs(msg.skillLearnRe.SkillInfoDatas) do
				local userSkillMap = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, Skill = DoSkillChange(v, object) }
				table.insert(object._UserSkillMap, userSkillMap)
			end
		end

	else
		OnSkillError(msg.errorCode)
		local GainNewSkillEvent = require "Events.GainNewSkillEvent"
		if msg.errorCode == ErrorCode.OK then
			for i,v in ipairs(msg.skillLearnRe.SkillInfoDatas) do
				local userSkillMap = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, 
				Skill = DoSkillChange(v) , SkillRuneInfoDatas = v.SkillRuneInfoDatas }
				table.insert(game._HostPlayer._UserSkillMap, userSkillMap)

				--给予提示
				local iconImgPath = CElementSkill.GetSkillIconFullPath(v.SkillId)
				local text = CElementSkill.GetSkillName(v.SkillId)
				game._GUIMan:ShowOperationTips(iconImgPath, hintImgPath, text, 1, 0.5)

				local e = GainNewSkillEvent()
				e.SkillId = v.SkillId
				CGame.EventManager:raiseEvent(nil, e)
			end

			FireHostSkillChangeEvent()
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateLearn", OnS2CSkillOperateLearn)

local function OnS2CSkillOperateLevelUp(sender, msg)
	if msg.roleId ~= game._HostPlayer._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i,v in ipairs(object._UserSkillMap) do
				for j,w in ipairs(msg.skillLevelUpRe.SkillInfoDatas) do
					if v.SkillId == w.SkillId then
						v.SkillId = w.SkillId
						v.SkillLevel = w.SkillLevel
						v.Skill = DoSkillChange(w, object)
						return
					end
				end
			end
		end
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then

			for i,v in ipairs(game._HostPlayer._UserSkillMap) do
				for j,w in ipairs(msg.skillLevelUpRe.SkillInfoDatas) do
					if v.SkillId == w.SkillId then
						v.SkillId = w.SkillId
						v.SkillLevel = w.SkillLevel
						v.Skill = DoSkillChange(w)
					end
				end
			end
			
			game._GUIMan:ShowTipText(StringTable.Get(120), false)

			FireHostSkillChangeEvent()
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateLevelUp", OnS2CSkillOperateLevelUp)

local function OnS2CSkillOperateRune(sender, msg)
	if msg.roleId ~= game._HostPlayer._ID then
		if msg.errorCode == ErrorCode.OK then
			local object = game._CurWorld:FindObject(msg.roleId)
			for i,v in ipairs(object._UserSkillMap) do
				for j,w in ipairs(msg.skillRuneRe.SkillInfoDatas) do
					if v.SkillId == w.SkillId then
						v.Skill = DoSkillChange(w, object)
						return
					end
				end
			end	
		end
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			for i, v in ipairs(msg.skillRuneRe.SkillInfoDatas) do
				for j, w in ipairs(game._HostPlayer._UserSkillMap) do
					if v.SkillId == w.SkillId then
						w.Skill = DoSkillChange(v)
						w.SkillRuneInfoDatas = v.SkillRuneInfoDatas
					end
				end
			end
			if not IsNil(CPanelSkill.Instance()._Panel) then
				CPanelSkill.Instance():OnShowSkillRuneInfo()
			end
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateRune", OnS2CSkillOperateRune)

local function OnS2CSkillOperateRuneConfig(sender, msg)
	if msg.roleId ~= game._HostPlayer._ID then
		--服务器这里会等效于有人更改激活符文
	else
		OnSkillError(msg.errorCode)
		if msg.errorCode == ErrorCode.OK then
			game._HostPlayer._ActivityConfigId = msg.skillRuneConfigRe.ActivityConfigId
			for i, v in ipairs(msg.skillRuneConfigRe.SkillInfoDatas) do
				for j, w in ipairs(game._HostPlayer._UserSkillMap) do
					if v.SkillId == w.SkillId then
						w.Skill = DoSkillChange(v)
						w.SkillRuneInfoDatas = v.SkillRuneInfoDatas
					end
				end
			end
			if not IsNil(CPanelSkill.Instance()._Panel) then
				CPanelSkill.Instance():OnChangeRuneConfig()
				CPanelSkill.Instance():OnShowSkillRuneInfo()
			end
		end
	end
end
PBHelper.AddHandler("S2CSkillOperateRuneConfig", OnS2CSkillOperateRuneConfig)

local function OnS2CSkillPerformFailed(sender, msg)
	-- 其它玩家应该没有，因为如果释放不出来，不会广播给周围人 只会在本地看到
	if msg.roleId ~= game._HostPlayer._ID then
		 
	else
		local host = game._CurWorld:FindObject(msg.roleId)
		if host then
			host._SkillHdl:OnSkillFailed(msg.skillId, msg.position)
		end
	end
end
PBHelper.AddHandler("S2CSkillPerformFailed", OnS2CSkillPerformFailed)
