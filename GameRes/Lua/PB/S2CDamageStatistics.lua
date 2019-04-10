-- 伤害统计相关
--

-- EDamageStatisticsOpt_default 			= 0;
-- EDamageStatisticsOpt_dungeonNormalEnd 	= 1; // 副本结束
-- EDamageStatisticsOpt_boss  				= 2; // boss
-- EDamageStatisticsOpt_dungeonRealTime 	= 3; // 副本实时伤害统计

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local EDamageStatisticsOpt = require "PB.data".EDamageStatisticsOpt
local CPanelDungeonEnd = require"GUI.CPanelDungeonEnd"
local EDamageStatisticsOptType = require "PB.data".EDamageStatisticsOptType
local EDamageStatisticTitleType = require "PB.data".EDamageStatisticTitleType

-- 伤害统计
local function OnDamageStatistics( sender, msg )
	--warn("msg.opt:", msg.opt, "optType:", msg.optType, "titleType:", msg.titleType)
	if msg.opt == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonRealTime then
		-- 副本实时伤害统计
		local CPanelMinimap = require "GUI.CPanelMinimap"
		if CPanelMinimap ~= nil then
			if msg.optType == EDamageStatisticsOptType.EDamageStatisticsOptType_reset then
				-- 重置数据，不切换至雷达图
				CPanelMinimap.Instance():ClearDamageInfo(false) -- 先清空旧数据

				-- 切换标题
				local title_type = -1
				if msg.titleType == EDamageStatisticTitleType.Dungeon then
					title_type = 1
				elseif msg.titleType == EDamageStatisticTitleType.DungeonBoss then
					title_type = 2
				end
				CPanelMinimap.Instance():ChangeDamageTitle(title_type)
			end

			for _, v in ipairs(msg.damageStatistics) do
				CPanelMinimap.Instance():HandleDamageStatistics(v.statisticDatas, msg.opt)
			end
		end

	elseif msg.opt == EDamageStatisticsOpt.EDamageStatisticsOpt_boss then
		-- 世界Boss
		local CPanelMinimap = require "GUI.CPanelMinimap"
		if CPanelMinimap ~= nil then
			-- print("msg.optType", msg.optType)
			if msg.optType == EDamageStatisticsOptType.EDamageStatisticsOptType_reset then
				-- 重置数据，切换至雷达图
				CPanelMinimap.Instance():ClearDamageInfo(true)
			elseif msg.optType == EDamageStatisticsOptType.EDamageStatisticsOptType_update then
				CPanelMinimap.Instance():ChangeDamageTitle(3)
				for _, v in ipairs(msg.damageStatistics) do
					CPanelMinimap.Instance():HandleDamageStatistics(v.statisticDatas, msg.opt)
				end
			end

		end
	-- 副本结算
	elseif msg.opt == EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonNormalEnd then 
		--副本伤害信息
		local data = {}
		data._Data = msg.damageStatistics
		local mapTid = game._CurWorld._WorldInfo.MapTid
		data._Type = EnumDef.DungeonEndType.InstanceType
		if mapTid == CSpecialIdMan.Get("TowerDungeonID") then 
			data._Type = EnumDef.DungeonEndType.TrialType
		end
		CPanelDungeonEnd.Instance():ShowInstancePlayer(data)
		-- game._GUIMan:Open("CPanelDungeonPlayer", data)
	-- 1v1 结算
	elseif msg.opt == EDamageStatisticsOpt.EDamageStatisticsOpt_1v1 then 
		local data = {}
		data._Data = msg.damageStatistics
		data._Type = EnumDef.DungeonEndType.ArenaOneType
		CPanelDungeonEnd.Instance():ShowArenaOnePlayer(data)
	elseif msg.opt == EDamageStatisticsOpt.EDamageStatisticsOpt_pvp3v3 then
		local data = {}
		data._Data = msg.damageStatistics
		data._Type = EnumDef.DungeonEndType.ArenaThreeType
		CPanelDungeonEnd.Instance():ShowArenaThreePlayer(data)
	end
end
PBHelper.AddHandler("S2CDamageStatistics",OnDamageStatistics)