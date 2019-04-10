local Lplus = require "Lplus"
local CPageInteractive = Lplus.Class("CPageInteractive")
local def = CPageInteractive.define

local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local CElementSkill = require "Data.CElementSkill"
local ChatManager = require "Chat.ChatManager"

def.field(CPanelBase)._Root = nil
def.field("userdata")._Panel = nil

def.field("table")._TableInteractiveSkillID = nil     --交互技能TableID
def.field("boolean")._IsActive = false					--是否交互中						                       
def.field("number")._CDTimerID = 0					--交互时间的Timer	
def.field("number")._CDTime = 0 					--交互CD

local MAX_INTERACTIVE_SKILL_NUM = 8 -- 最大交互技能数量
local POS_BASE_NUM = 100 -- 技能位置基数

local instance = nil
def.static(CPanelBase, "userdata","=>", CPageInteractive).new = function(root, panel)
	if instance == nil then
		instance = CPageInteractive()
		instance._Root = root
		instance._Panel = panel
		instance:InitTableData()
	end
	return instance
end

--初始化交互数据
def.method().InitTableData = function (self)
	if self._TableInteractiveSkillID ~= nil then return end

	self._TableInteractiveSkillID = {}

	local hp = game._HostPlayer
	local learnedSkills = hp._UserSkillMap
	for _,v in ipairs(learnedSkills) do
		if v ~= nil then
			local conditionData = hp:GetSkillLearnConditionTemp(v.SkillId)
			if conditionData ~= nil and conditionData.MainUIPos > POS_BASE_NUM then
				local index = conditionData.MainUIPos - POS_BASE_NUM
				if index <= MAX_INTERACTIVE_SKILL_NUM then
					local skillLearnTemp = hp:GetSkillLearnConditionTemp(v.SkillId)
					if skillLearnTemp ~= nil then
						self._TableInteractiveSkillID[index] = 
						{
							_SkillID = v.SkillId,
							_Describe = skillLearnTemp.SkillDescription,
							_Talk = skillLearnTemp.SkillLevelUpDescription,
						}
						local img_skill_icon = self._Root:GetUIObject("Img_Interactive_"..index)
						GUITools.SetSkillIcon(img_skill_icon, v.Skill.IconName)
					end
				end
			end
		end
	end

	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	self._CDTime = CSpecialIdMan.Get("InteractiveCDTime")
end

local function ClearCD()
	instance._IsActive = false
	if instance._CDTimerID ~= 0 then
		_G.RemoveGlobalTimer(instance._CDTimerID)
		instance._CDTimerID  = 0
	end
end

def.method("boolean").SetVisible = function(self,isVisble)
	if not IsNil(self._Panel) then
		self._Panel:SetActive(isVisble) 
	end
end

--点击交互技能按钮
def.method("number").ClickSkillBtn = function(self, index)
	local host = game._HostPlayer
	if host:IsInServerCombatState()then
		game._GUIMan:ShowTipText(StringTable.Get(139), false)
		return 
	end

	if self._IsActive then 
		game._GUIMan:ShowTipText(StringTable.Get(21101), false)
		return 
	end
	
	if self._TableInteractiveSkillID == nil or table.nums(self._TableInteractiveSkillID) <= 0 then 
		-- FlashTip("职业："..host._InfoData._Prof.."没有交互动作","tip",5)	
		warn("Empty interactive skill, wrong prof:"  .. host._InfoData._Prof)
		return 
	end
	
	local interactiveData = self._TableInteractiveSkillID[index]
	if interactiveData == nil then 
		-- FlashTip("第"..index.."个交互动作错误","tip",2)	
		warn("Interactive skill data got nil, wrong index:", index)
		return 
	end 

	--[[
	local target = host:GetCurrentTarget()
     
    local strInteractive = ""   
    local playerName = RichTextTools.GetHostPlayerNameRichText(false)  
    if not IsNil(target) then
  		local dir = target:GetPos() - host:GetPos()
		host:SetDir(dir) 
		local targetName = RichTextTools.GetElsePlayerNameRichText(target._InfoData._Name, false)   
		strInteractive = string.format(interactiveData._Talk, playerName,targetName)
    else
    	strInteractive = string.format(interactiveData._Describe, playerName)
    end

	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelCurrent, strInteractive, false)
	]]

    local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CDungeonAutoMan.Instance():Stop()
	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Stop()
	local CAutoFightMan = require "ObjHdl.CAutoFightMan"
    CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)

	local hostskillhdl = host._SkillHdl
	local skill_id = interactiveData._SkillID
	hostskillhdl: CastSkill(skill_id,false)	


	--self._IsActive = true


	--self._CDTimerID = _G.AddGlobalTimer(self._CDTime, true, ClearCD)		
end

--[[
def.method().BrokenInteractive = function(self)
	ClearCD()	
end
--]]

def.method().Destroy = function (self)
	if self._CDTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._CDTimerID)
		self._CDTimerID  = 0
	end
	self._Root = nil
	self._Panel = nil
	self._TableInteractiveSkillID = nil

	instance = nil
end

CPageInteractive.Commit()
return CPageInteractive