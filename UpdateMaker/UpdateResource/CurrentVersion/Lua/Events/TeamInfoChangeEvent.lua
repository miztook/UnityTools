local Lplus = require "Lplus"
local TeamInfoChangeEvent = Lplus.Class("TeamInfoChangeEvent")
local def = TeamInfoChangeEvent.define
--[[
	message TeamInfoChange_s2cd
	{
		enum TYPE
		{
			TYPE_HP 				 = 1;
			TYPE_ONOFFLINE			 = 2;
			TYPE_MAP_INFO 			 = 3;
			TYPE_LEVEL 				 = 4;
			TYPE_FOLLOW 			 = 5;
			TYPE_FIGHTSCORE			 = 6; // 战斗力变化
			TYPE_BOUNTY				 = 7; // 赏金模式
		}
		required TYPE  type 							 = 1;
		optional TeamHpInfo_s2cd 	   hpInfo 			 = 2;
		optional TeamOffLineInfo_s2cd  onOffLine 		 = 3;
		optional TeamMemberMapInfo     mapInfo		     = 4;
		optional TeamLevelInfo_s2c     levelInfo 		 = 5;
		optional TeamFollowInfo 	   followInfo 		 = 6;
		optional TeamFightScoreInfo	   fightScoreInfo 	 = 7;
		optional TeamBountyInfo		   bountyInfo		 = 8;
	}

	require "PB.net".TeamInfoChange_s2cd.TYPE
	TeamInfoChangeType = 
    {
        ResetAllMember  = 0,    --全部刷新，包括队伍成
        Hp              = 1,    --血量变化
        OnOffLine       = 2,    --在线状态
        MapInfo         = 3,    --地图线路变化
        Level           = 4,    --等级变化
        Follow          = 5,    --跟随
        FightScore      = 6,    --战斗力变化
        Bounty          = 7,    --赏金模式
        MatchState      = 8,    --匹配状态变化
    },
]]

def.field("number")._Type = 0
def.field("table")._ChangeInfo = nil

TeamInfoChangeEvent.Commit()
return TeamInfoChangeEvent