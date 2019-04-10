local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBattleMiddle = require"GUI.CPanelBattleMiddle"
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
local EMatchType = require "PB.net".EMatchType
local PBHelper = require "Network.PBHelper"

--活动开启状态
local function OnS2CMatchActivityState(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateActivityState(msg.IsOpen)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3ActivityState(msg.IsOpen)
	end
end
PBHelper.AddHandler("S2CMatchActivityState", OnS2CMatchActivityState)

-- 信息
local function OnS2CMatchData(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateDataRes(msg)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3PlayerInfo(msg)
	end
end
PBHelper.AddHandler("S2CMatchData", OnS2CMatchData)

--副本匹配列表数据
local function OnS2CDungeonMatchList(sender, msg)
    CPVEAutoMatch.Instance():OnS2CMatchList(msg)
end
PBHelper.AddHandler("S2CMatchGetMatchList", OnS2CDungeonMatchList)

--请求匹配
local function OnS2CMatching(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateMatching()
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3Matcihing()
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        CPVEAutoMatch.Instance():OnS2CMatching(msg)
	end
	
end
PBHelper.AddHandler("S2CMatching", OnS2CMatching)

--匹配成功后返回匹配结果
local function OnS2CMatchResult(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateMatchResult(msg)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3MatchResult(msg)
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        local CTeamMan = require "Team.CTeamMan"
        local roomID = msg.TeamDungeonInfo.RoomId
        local targetID = msg.TargetId
        local callback = function(val)
            local C2SMatchEnterConfirm = require "PB.net".C2SMatchEnterConfirm
            local protocol = C2SMatchEnterConfirm()
            protocol.MatchType = EMatchType.EMatchType_Dungeon
            protocol.RoomId = roomID
            protocol.Confirm = val
            protocol.TargetId = targetID
            SendProtocol(protocol)
        end
        local deadLine = msg.TeamDungeonInfo.DeadLine - GameUtil.GetServerTime()/1000
        local dungeonID = CTeamMan.Instance():ExchangeToDungeonId(msg.TargetId)
        local param = {Duration = deadLine, DungeonId = dungeonID, CallBack = callback, MatchList = msg.TeamDungeonInfo.MemberList}
	    game._GUIMan:Open("CPanelUITeamConfirm", param)
	end
end
PBHelper.AddHandler("S2CMatchResult", OnS2CMatchResult)

--取消匹配结果(被动取消和主动取消)
local function OnS2CMatchCancelRes(sender, msg)
	if msg == nil or msg.RoleId == nil then return end
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateCancelRes(msg)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3CancelMatch(msg)
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        CPVEAutoMatch.Instance():OnS2CMatchCancle(msg)
        local CTeamMan = require "Team.CTeamMan"
        CTeamMan.Instance():OnS2CTeamPrepareResult(false)
	end
end
PBHelper.AddHandler("S2CMatchCancelRes", OnS2CMatchCancelRes)

-- 玩家进入确认
local function OnS2CMatchEnterConfirm(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateEnterConfirm(msg.RoleId)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2CConfigEnter3V3(msg)
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        local CTeamMan = require "Team.CTeamMan"
        CTeamMan.Instance():OnS2CTeamMemberConfirmed(msg.RoleId)
	end
	game._CArenaMan:OnS2CEliminateEnterConfirm(msg.RoleId)
end
PBHelper.AddHandler("S2CMatchEnterConfirm", OnS2CMatchEnterConfirm)

--加载loading
local function OnS2CMatchStartLoading(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateStartLoading()
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3StartLoading(msg)
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        CPVEAutoMatch.Instance():OnMatchStartLoading()
	end
end
PBHelper.AddHandler("S2CMatchStartLoading",OnS2CMatchStartLoading)

--匹配未成功，返回到匹配主界面()
local function OnS2CMatchBackToMatching(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Eliminate then
		game._CArenaMan:OnS2CEliminateBackToMatching(msg)
	elseif msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3BackToMatching(msg)
    elseif msg.MatchType == EMatchType.EMatchType_Dungeon then
        local CTeamMan = require "Team.CTeamMan"
        CTeamMan.Instance():OnS2CTeamPrepareResult(false)
	end
end
PBHelper.AddHandler("S2CMatchBackToMatching",OnS2CMatchBackToMatching)

--地图加载进度
local function OnS2CMatchMapLoadProgress(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3MapProgress(msg)
	end
end 
PBHelper.AddHandler("S2CMatchMapLoadProgress",OnS2CMatchMapLoadProgress)

local function OnS2CMatchFriendInfo(sender, msg)
	if msg.MatchType == EMatchType.EMatchType_Arena then
		game._CArenaMan:OnS2C3V3FriendInfo(msg.Datas)
	end
end
PBHelper.AddHandler("S2CMatchFriendInfo",OnS2CMatchFriendInfo)



