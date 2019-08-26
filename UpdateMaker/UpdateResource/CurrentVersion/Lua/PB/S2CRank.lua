local PBHelper = require "Network.PBHelper"
local CPanelRanking = require "GUI.CPanelRanking"

local function OnS2CRankGetData(sender,msg)
	if CPanelRanking.Instance():IsShow() then 
		CPanelRanking.Instance():LoadRankDataFromSer(msg.Infos, msg.RankId,msg.RoleRank )
	end
end
PBHelper.AddHandler("S2CRankGetData", OnS2CRankGetData)
