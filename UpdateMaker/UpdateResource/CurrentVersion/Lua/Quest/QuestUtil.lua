local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CQuest = require "Quest.CQuest"
local QuestDef = require "Quest.QuestDef"

local QuestUtil = Lplus.Class("QuestUtil")
local def = QuestUtil.define

local reward_quest_npc_tid = 0
local activity_quest_npc_tid = 0
local function hasQuestRandGroupServer(npcTemplate)
	if type(npcTemplate) == "table" and npcTemplate ~= nil then
		if reward_quest_npc_tid == 0 then
			reward_quest_npc_tid = CSpecialIdMan.Get("RewardQuestNPCId")
		end
		if activity_quest_npc_tid == 0 then
			activity_quest_npc_tid = CSpecialIdMan.Get("ActivityQuestNPCId")
		end
		if npcTemplate.Id == reward_quest_npc_tid or npcTemplate.Id == activity_quest_npc_tid then
			for _, v in ipairs(npcTemplate.Services) do
				local serviceTemplate = CElementData.GetServiceTemplate(v.Id)
				if serviceTemplate ~= nil and serviceTemplate.QuestRandGroup._is_present_in_parent then
					--如果是随机任务服务 判断具体随机服务的类型
					local groupIds = string.split(serviceTemplate.QuestRandGroup.GroupIds, "*")
					local groupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(groupIds[1]))
					local countGroupId = 0
					if groupTemplate.QuestType == QuestDef.QuestType.Activity then
						countGroupId = CSpecialIdMan.Get("ActivityQuestCountGroupId")
					elseif groupTemplate.QuestType == QuestDef.QuestType.Reward then
						countGroupId = CSpecialIdMan.Get("RewardQuestCountGroupId")
					end
					if countGroupId > 0 then
						if not CQuest.Instance():IsHasQuestByType(groupTemplate.QuestType) then
							-- 当前任务列表中还没有这种类型的任务
							local totalNum, finishNum = 0, 0
							local group = CQuest.Instance()._CountGroupsQuestData[countGroupId]
							if group ~= nil then
								finishNum = group._Count
							end
							local template = CElementData.GetTemplate("CountGroup", countGroupId)
							if template ~= nil then
								totalNum = template.MaxCount
							end
							if finishNum < totalNum then
								-- 还没达到任务总数
								local isUse = game._HostPlayer._OpHdl:JudgeServiceOptionIsUse(serviceTemplate)
								local isLook = game._HostPlayer._OpHdl:JudgeServiceOption(serviceTemplate)
								if isUse and isLook then
									return true
								end
							end
						end
					end

					break
				end
			end
		end
	end
	return false
end

def.const("function").HasQuestRandGroupServer = hasQuestRandGroupServer

QuestUtil.Commit()
return QuestUtil