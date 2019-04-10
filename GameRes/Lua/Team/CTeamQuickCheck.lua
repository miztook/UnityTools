local Lplus = require "Lplus"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CTeamMan = require "Team.CTeamMan"
local CTeamQuickCheck = Lplus.Class("CTeamQuickCheck")
local def = CTeamQuickCheck.define

local teamQuickConfig = nil

--local targetTab = nil 	--计算数据
 
def.static("=>", "table").Get = function()
	if teamQuickConfig == nil then
		local ret, msg, result = pcall(dofile, "Configs/QuickTeamCfg.lua")
		if ret then
			teamQuickConfig = result
		else
			warn(msg)
		end
	end
	
	return teamQuickConfig
end

--检查任务获得后 是否快捷组队提示
def.static("number","=>","table").CheckQuestQuickTeam = function(questId)
	local targetTab = {}
	local config = CTeamQuickCheck.Get()
	if not CTeamMan.Instance():InTeam() and config.QuestTrigger[questId] ~= nil then
		targetTab[questId] = config.QuestTrigger[questId]
	end
	return targetTab
end

--检查区域后 是否快捷组队提示
def.static("number","=>","table").CheckRegionQuickTeam = function(regionId)
	local sceneId = game._CurWorld._WorldInfo.SceneTid
	local targetTab = {}
	local config = CTeamQuickCheck.Get()
	if not CTeamMan.Instance():InTeam() and config.RegionTrigger[sceneId] ~= nil and config.RegionTrigger[sceneId][regionId] ~= nil then
				-- 999999 特殊值 无任何任务也可以弹出
		if config.RegionTrigger[sceneId][regionId][999999] ~= nil then
			targetTab[999999] = config.RegionTrigger[sceneId][regionId][999999]
		end 
		
		for _,v in pairs(CQuest.Instance()._InProgressQuestMap) do
			if CQuest.Instance():IsQuestInProgress(v.Id) and config.RegionTrigger[sceneId][regionId][v.Id] ~= nil then
				targetTab[v.Id] = config.RegionTrigger[sceneId][regionId][v.Id]
			end
		end
	end

	return targetTab
end

CTeamQuickCheck.Commit()
return CTeamQuickCheck