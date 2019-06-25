--
--成就通信 by luee 2017.1.12
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

--发送的成就列表
local function OnS2CAchievementList(sender, msg)
	for _,v in ipairs(msg.Achieves) do
		local currParm = game._AcheivementMan:ChangeAchievementState(v)
		CPlatformSDKMan.Instance():UpdateGoogleAchieveData(v.GoogleAchieveId, currParm, v.IsFinish)
	end
	game._AcheivementMan:UpdateAdvancedGuideInfo()
	game._AcheivementMan:NeedShowRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())

    game._AcheivementMan:SortAchieveTable()
	game._AcheivementMan._HasGotAchieveDatas = true
    CPlatformSDKMan.Instance():CheckGoogleAchievementState()

	local CPanelUIManual = require "GUI.CPanelUIManual"
	if CPanelUIManual.Instance():IsShow() then 
        CPanelUIManual.Instance():FreshAchievementPage()
    end
end
PBHelper.AddHandler("S2CAchieveList", OnS2CAchievementList)

--完成成就
local function OnS2CAchivementFinish(sender,msg)
	local tid = msg.Tid
	game._AcheivementMan:FinishAchievement(tid, msg.FinishTime or 0)
	game._AcheivementMan:UpdateAdvancedGuideInfo()
	-- 弹出app弹窗
	game:OnAppMsgBoxStatic(EnumDef.TriggerTag.FinishAchievement, tid)
	local CPanelUIManual = require "GUI.CPanelUIManual"
	if CPanelUIManual.Instance():IsShow() then 
        CPanelUIManual.Instance():FreshAchievementPage()
	end
	
	local CElementData = require "Data.CElementData"
	local achievementTemp = CElementData.GetTemplate("Achievement", tid)
    if achievementTemp ~= nil then
	    local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	    local ChatManager = require "Chat.ChatManager"
	    local msgstr = string.format(StringTable.Get(13048), achievementTemp.Name)
	    if msgstr ~= nil and game._AcheivementMan:IsAchievementUseType(tid) then
		    ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msgstr, false, 0, nil,nil)
	    end
    end
	CPlatformSDKMan.Instance():UpdateGoogleAchieveData(msg.GoogleAchieveId, msg.ReachParm, true)
	CPlatformSDKMan.Instance():SetGoogleAchievementCompletionLevel(msg.GoogleAchieveId, msg.ReachParm)
	CPlatformSDKMan.Instance():CompleteGoogleAchievement(msg.GoogleAchieveId)
end
PBHelper.AddHandler("S2CAchieveInc", OnS2CAchivementFinish)

--领取奖励
local function OnS2CGetAchievementReward(sender,msg)
	game._AcheivementMan:RevGetReward(msg.Tid, msg.errorCode)
	game._AcheivementMan:UpdateAdvancedGuideInfo()
	
	local CPanelUIManual = require "GUI.CPanelUIManual"
	if CPanelUIManual.Instance():IsShow() then 
        CPanelUIManual.Instance():FreshAchievementRedPoint()
    end
end
PBHelper.AddHandler("S2CAchieveDrawRet", OnS2CGetAchievementReward)

local function OnS2CGetBatchAchievementReward(sender, msg)
    if msg.errorCode == 0 then
        game._AcheivementMan:RevBatchGetReward(msg.Tids)
    else
        game._GUIMan:ShowErrorTipText(msg.errorCode)
    end
end
PBHelper.AddHandler("S2CAchieveDrawBatchRet", OnS2CGetBatchAchievementReward)

--成就发生了改变
local function OnS2CChangeAchievement(sender,msg)
	for _,v in ipairs(msg.Achieves) do
		local currParm = game._AcheivementMan: ChangeAchievementState(v)
		CPlatformSDKMan.Instance():UpdateGoogleAchieveData(v.GoogleAchieveId, currParm, v.IsFinish)
		CPlatformSDKMan.Instance():SetGoogleAchievementCompletionLevel(v.GoogleAchieveId, currParm)
	end
	game._AcheivementMan:UpdateAdvancedGuideInfo()
    game._AcheivementMan:NeedShowRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
    game._AcheivementMan:SortAchieveTable()
end
PBHelper.AddHandler("S2CAchieveUpdate", OnS2CChangeAchievement)