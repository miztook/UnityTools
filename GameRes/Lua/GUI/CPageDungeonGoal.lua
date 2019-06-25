local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local EObjType = require "PB.data".EObjType
local QuestDef = require "Quest.QuestDef"
local CFxObject = require "Fx.CFxObject"
local MapBasicConfig = require "Data.MapBasicConfig" 

local CPageDungeonGoal = Lplus.Class("CPageDungeonGoal")
local def = CPageDungeonGoal.define

def.field("table")._Parent = function() return {} end
def.field("userdata")._Panel = nil
def.field(CFxObject)._RegionSfx = nil
def.field("userdata")._ImgClick = nil 
def.field("userdata")._ImgEffect1 = nil
def.field("userdata")._ImgEffect2 = nil
def.field("userdata")._LabDungeonTime = nil
def.field("userdata")._LabDungeonTimeTip = nil
def.field("userdata")._FrameTime = nil
def.field("table")._TableGoalItem = nil --副本目标
def.field("number")._DungeonTimerID = 0 --副本timerID
def.field("number")._DungeonEndTime = 0 --副本结束时间戳
def.field("number")._DungeonEndPeriod = 0 --副本计时类型
def.field("number")._DungeonGoalTimer = 0 -- 副本目标倒计时
-- 副本事件倒计时相关
def.field("userdata")._FrameCountdown = nil
def.field("userdata")._LabDungeonCountdown = nil
def.field("userdata")._LabDungeonCountdownTitle = nil
def.field("number")._DungeonCountdownTimerID = 0 -- 倒计时TimerID
def.field("number")._DungeonCountdownEndTime = 0 -- 倒计时结束时间戳(秒)
def.field("string")._DungeonCountdownInfo = "" -- 倒计时显示信息
-- 公会战场专属
def.field("userdata")._Guild_Battle = nil
def.field("userdata")._Target_Content = nil
def.field("userdata")._Kill_Content = nil
def.field("userdata")._Dead_Content = nil
def.field("userdata")._Guild_Time = nil
def.field("userdata")._Guild_RefreshTime = nil
def.field("userdata")._Time_Content = nil
def.field("number")._RefreshTimer = 0
def.field("number")._TimeShowType = 0
def.field("number")._EndTime = 0

local dungeonGoal = nil --副本目标
--local mapInfo = nil

local instance = nil
def.static("table", "userdata", "=>", CPageDungeonGoal).new = function(parent, panel)
	if instance == nil then
		instance = CPageDungeonGoal()
		instance._Panel = panel
		instance._Parent = parent
		-- 初始化
		instance:Init()
	end

--[[	if mapInfo == nil then
		mapInfo = require "Data.MapBasicConfig".Get()
	end--]]
	return instance
end

local function InitGoalItem()
	if instance._TableGoalItem ~= nil then return end

	instance._TableGoalItem = {}
	local goalPanel = instance._Panel:FindChild("Item")
	for i=1,5 do
		instance._TableGoalItem[i] = goalPanel:FindChild("Fram_Targets"..i)
		if not IsNil(instance._TableGoalItem[i]) then
			instance._TableGoalItem[i]: SetActive(false)
		end
	end
end

def.method().Init = function(self)
	self._LabDungeonTime = self._Panel:FindChild("Item/Fram_Time/Lab_Time")
	self._LabDungeonTimeTip = self._Panel:FindChild("Item/Fram_Time/Lab_TimeTip")
	self._FrameTime  = self._Panel:FindChild("Item/Fram_Time")

	self._FrameCountdown = self._Panel:FindChild("Item/Frame_Countdown")
	self._LabDungeonCountdown = self._Panel:FindChild("Item/Frame_Countdown/Lab_Countdown")
	self._LabDungeonCountdownTitle = self._Panel:FindChild("Item/Frame_Countdown/Lab_CountdownTitle")
	self._ImgClick = self._Panel:FindChild("Item/ImageClick")
    self._ImgEffect1 = self._Panel:FindChild("Item/Img_EffectFinish1")
    self._ImgEffect2 = self._Panel:FindChild("Item/Img_EffectFinish2")

	self._Guild_Battle = self._Parent:GetUIObject("Guild_Battle")
	self._Target_Content = self._Parent:GetUIObject("Target_Content")	
	self._Kill_Content = self._Parent:GetUIObject("Kill_Content")
	self._Dead_Content = self._Parent:GetUIObject("Dead_Content")
	self._Guild_Time = self._Parent:GetUIObject("GuildTime")
    self._Guild_RefreshTime = self._Parent:GetUIObject("GuildRefreshTime")
	self._Time_Content = self._Parent:GetUIObject("Time_Content")
end

-- 从组队切换到副本任务
def.method().Show = function(self)
	if game._GuildMan:IsGuildBattleScene() then
		self._Guild_Battle:SetActive(true)
		self._Guild_Time:SetActive(true)
        self._Guild_RefreshTime:SetActive(self._EndTime > GameUtil.GetServerTime()/1000)
		self._Panel:SetActive(false)
		local guildBattle = CElementData.GetTemplate("GuildBattle", 1)
		GUI.SetText(self._Target_Content, guildBattle.Content)
		self:UpdateGuildBattle()
	else
		self._Guild_Time:SetActive(false)
        self._Guild_RefreshTime:SetActive(false)
		self._Guild_Battle:SetActive(false)
		self._Panel:SetActive(true)
	end
 	dungeonGoal = game._DungeonMan:GetDungeonGoal()
	InitGoalItem()

	self:OnAddInstanceTimer() 
	self:OnAddDungeonCountdown()
    self:OnAddGuildBattleTimer()

	if dungeonGoal ~= nil then
		self:InitDungeonGoalPanel()	--有副本目标显示副本目标
	else
		self:InitMapShow() --没有副本目标。显示地图信息
	end	

	self:ShowDungeonGoalUIFX(QuestDef.UIFxEventType.InProgress) --显示任务正在进行中的特效

	self._ImgClick:SetActive(CDungeonAutoMan.Instance():IsOn())
end

-- 更新公会战场左侧面板信息
def.method().UpdateGuildBattle = function(self)
	GUI.SetText(self._Kill_Content, tostring(game._GuildMan._KillNum))
	GUI.SetText(self._Dead_Content, tostring(game._GuildMan._DeathNum))
end

local textColor = Color.New(1, 1, 1, 1)
def.method("number","table").SetGoalShow = function(self,nIndex,goalData)
	--[[目标描述
		EDUNGEONGOAL_KILLMONSTER 			= 1; // 杀怪
		EDUNGEONGOAL_GATHER 				= 2; // 采集
		EDUNGEONGOAL_ENTERREGION 			= 3; // 进入区域
		EDUNGEONGOAL_TALK 					= 4; // 交谈
	]]
	
	if IsNil(self._TableGoalItem[nIndex]) then 
		warn("TableGoalItem的",nIndex,"Is nil")
		return 
	end
	self._TableGoalItem[nIndex]:SetActive(true)
	local labDescribe = self._TableGoalItem[nIndex]:FindChild("Lab_Desc")
	if not IsNil(labDescribe) then	
		labDescribe:SetActive(true)
		local strDescrip = CElementData.GetTextTemplate(goalData.TextID)
		if strDescrip ~= nil and strDescrip.TextContent ~= nil then
			GUI.SetText(labDescribe, strDescrip.TextContent)
		else
			GUI.SetText(labDescribe, dungeonGoal.Description)
		end

		GameUtil.SetTextColor(labDescribe:GetComponent(ClassType.Text), textColor)
	end

	--warn("//"..dungeonGoal.CurC    ount.."//"..dungeonGoal.MaxCount)
	-- 副本目标时间
	local labNum = self._TableGoalItem[nIndex]:FindChild("Lab_Num")
	local labTime = self._TableGoalItem[nIndex]:FindChild("Lab_Time")
	labTime:SetActive(false)
	-- warn("goalData.GoalType == EObjType.ObjType_WaitTime ",goalData.GoalType )
	if goalData.GoalType == EObjType.ObjType_WaitTime then
		labNum:SetActive(false)
		labTime:SetActive(true)
		if self._DungeonGoalTimer ~= 0 then
			_G.RemoveGlobalTimer(self._DungeonGoalTimer)
        	self._DungeonGoalTimer = 0
		end
		-- warn("goalData.CreatTime ",goalData.CreatTime)
		local endTime = goalData.CreatTime + goalData.TemplateId
		local remainTime = 0
		local function callback()
			remainTime = endTime - GameUtil.GetServerTime()/1000 
			-- warn("remainTime   ",remainTime) 
			local strTime = GUITools.FormatTimeFromSecondsToZero(false, remainTime)
			GUI.SetText(labTime,strTime)
			if remainTime <= 0 then 
				_G.RemoveGlobalTimer(self._DungeonGoalTimer)
	        	self._DungeonGoalTimer = 0
			end
		end
		self._DungeonGoalTimer = _G.AddGlobalTimer(1,false,callback)
 	return end
	--目标当前个数 /目标最大个数
	local strNum = string.format(StringTable.Get(557),goalData.CurCount,goalData.MaxCount)
	if not IsNil(labNum) then
		labNum: SetActive(true)
		GUI.SetText(labNum,strNum)
		GameUtil.SetTextColor(labNum:GetComponent(ClassType.Text), textColor)
	end
end

def.method().InitDungeonGoalPanel = function (self)
	local dungeonPanel = self._Panel:FindChild("Item")
	if(not IsNil(dungeonPanel)) then
		dungeonGoal = game._DungeonMan:GetDungeonGoal() --没完成的第一条目标
		if(dungeonGoal == nil) then
			warn("CPageDungeonGoal: 副本目标错误！！")
			local CPanelTracker = require "GUI.CPanelTracker"
			CPanelTracker.Instance():OpenDungeonUI(false)
			return
		end

		local dungeonID = game._DungeonMan:GetDungeonID()
		if(dungeonID <= 0 ) then
			warn("CPageDungeonGoal:副本ID错误!!ID:",dungeonID)
			local CPanelTracker = require "GUI.CPanelTracker"
			CPanelTracker.Instance():OpenDungeonUI(false)
			return
		end

		--副本图标
		local dungeonInfo = CElementData.GetInstanceTemplate(dungeonID) 
		--local icon = dungeonPanel:FindChild("Img_Icon")
		--GUITools.SetSprite(icon,dungeonInfo.IconPath)

		--副本名字
		local textType = ClassType.Text
		local labName = dungeonPanel:FindChild("Lab_Name")
		if(labName ~= nil) then
			local strName = string.format(StringTable.Get(546) ,dungeonInfo.TextDisplayName)
			labName :SetActive(true)
			GUI.SetText(labName, strName)
		end

		if self._TableGoalItem == nil then
			warn("CPageDungeonGoal:  副本目标预设错误")
			return
		end

		for i,v in ipairs(self._TableGoalItem) do
			if not IsNil(v) then
				v: SetActive(false)
			end
		end

		local allGoals = game._DungeonMan:GetAllDungeonGoal()
		for i,v in ipairs(allGoals) do
			self: SetGoalShow(i,v)
		end

		self:AddRegionSfx(dungeonGoal)
	end	
end

def.method("table").AddRegionSfx = function(self, GoalData)
	if GoalData.GoalType ~= 3 then 
		return
	end
	if GoalData.Param ~= 1 then
		return
	end


	--local pos = mapInfo[game._CurWorld._WorldInfo.SceneTid].Region[2][GoalData.TemplateId]	
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(game._CurWorld._WorldInfo.SceneTid)
	local pos = map.Region[2][GoalData.TemplateId]	
	if self._RegionSfx == nil then
		self._RegionSfx = CFxMan.Instance():Play(PATH.Etc_Mubiaodidianbiaoji, pos, Quaternion.identity, -1, -1, EnumDef.CFxPriority.Always)
	end
end

def.method("table").RemoveRegionSfx = function(self, GoalData)
	if GoalData.GoalType ~= 3 then
		return
	end
	if self._RegionSfx ~= nil then		
		CFxMan.Instance():Stop(self._RegionSfx)
		self._RegionSfx = nil
	end
end

--地图信息显示
def.method().InitMapShow = function(self)
	--副本名字
	if IsNil(self._TableGoalItem[1]) then return end
	local dungeonPanel = self._TableGoalItem[1]
	self._TableGoalItem[1]: SetActive(true)
	local textType = ClassType.Text
	local labName = self._Panel:FindChild("Item/Lab_Name")
	local labDescribe = dungeonPanel:FindChild("Lab_Desc")
	
	local labNum = dungeonPanel:FindChild("Lab_Num")
	local nMapID = game._CurWorld._WorldInfo.MapTid
    local worldData = CElementData.GetMapTemplate(nMapID)
    if worldData ~= nil  then
    	if not IsNil(labName) then
    		GUI.SetText(labName, worldData.TextDisplayName)
    	end

    	if not IsNil(labDescribe) then
    		labDescribe: SetActive(false)
    		-- GUI.SetText(labDescribe, worldData.Remarks)
    		-- GameUtil.SetTextColor(labDescribe:GetComponent(ClassType.Text), textColor)
    	end
    	if not IsNil(labNum) then
    		labNum: SetActive(false)
    	end
	end
end

local textColorGot = Color.New(133/255, 210/255, 24/255, 1)
def.method("number").UpdateDungeonGoalPanel = function(self,nIndex)
 	if self._TableGoalItem == nil then return end  --界面没有初始化完毕。等待show的时候再刷新一次
 	dungeonGoal = game._DungeonMan: GetDungeonGoalByIndex(nIndex)
	if(dungeonGoal == nil) then
		warn("副本目标错误！！")
		local CPanelTracker = require "GUI.CPanelTracker"
		CPanelTracker.Instance():OpenDungeonUI(false)
		return
	end

	local dungeonID = game._DungeonMan:GetDungeonID()
	if(dungeonID <= 0 ) then
		warn("副本ID错误！！")
		local CPanelTracker = require "GUI.CPanelTracker"
		CPanelTracker.Instance():OpenDungeonUI(false)
		return
	end

	if IsNil(self._TableGoalItem[nIndex]) then
		warn("Index:"..nIndex.."的任务更新失败")
		return
	end

	local dungeonPanel = self._TableGoalItem[nIndex]

	--目标当前个数
	local labDescribe = dungeonPanel:FindChild("Lab_Desc")

	local labNum = dungeonPanel:FindChild("Lab_Num")
	local strNum = string.format(StringTable.Get(557),dungeonGoal.CurCount,dungeonGoal.MaxCount)
	if not IsNil(labNum) then
		GUI.SetText(labNum, strNum)
	end
	if dungeonGoal.CurCount >= dungeonGoal.MaxCount then
		GameUtil.SetTextColor(labDescribe:GetComponent(ClassType.Text), textColorGot)
		GameUtil.SetTextColor(labNum:GetComponent(ClassType.Text), textColorGot)
	end

	self:RemoveRegionSfx(dungeonGoal)
end

--显示副本目标怪进度特效
def.method("number").ShowDungeonGoalUIFX = function(self, stateType)
    if stateType == QuestDef.UIFxEventType.InProgress then
        if not IsNil(self._ImgClick) then
            --任务选中特效 
	        local anchor_up = self._ImgClick:FindChild("Fx_Up")
	        local anchor_down = self._ImgClick:FindChild("Fx_Down")
	        if anchor_up ~= nil and anchor_down~= nil then
                GameUtil.PlayUISfx(PATH.UIFX_QuestN_Current_Mission_1, anchor_up, anchor_up, -1)
                GameUtil.PlayUISfx(PATH.UIFX_QuestN_Current_Mission_2, anchor_down, anchor_down, -1)
            end
		        self._ImgClick: SetActive(false)
	        end
    elseif stateType == QuestDef.UIFxEventType.ObjectCountChange then
        local anchor_mid = self._Panel:FindChild("Item")
        GameUtil.PlayUISfx(PATH.UIFX_QuestN_Mission_Change, anchor_mid, anchor_mid, 0.5)
        if self._ImgEffect1 ~= nil then
	        self._ImgEffect1:SetActive(true)
	        self._ImgEffect2:SetActive(true)
	        local img_fx1 = self._ImgEffect1:GetComponent(ClassType.DOTweenAnimation)
	        local img_fx2 = self._ImgEffect2:GetComponent(ClassType.DOTweenAnimation)
	        img_fx1:DORestart(false)
	        img_fx2:DORestart(false)
	    end
    elseif stateType == QuestDef.UIFxEventType.Completed then
        local anchor_mid = self._Panel:FindChild("Item")
        GameUtil.PlayUISfx(PATH.UIFX_QuestN_Mission_Complete, anchor_mid, anchor_mid, -1)
    end
end

--副本目标的锁定IMG显示状态
def.method("boolean").SyncAutoDungeonUIState = function(self, isClick)
	if not IsNil(self._ImgClick) then
		self._ImgClick: SetActive(isClick)
	end	

	--warn("SyncAutoDungeonUIState", isClick, debug.traceback())

	if isClick then
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
		
	    local CPanelGuide = require "GUI.CPanelGuide"
	    local panel = CPanelGuide.Instance()
	    if panel ~= nil and panel:IsShow() then
	        local CGuideMan = require "Guide.CGuideMan"
	        local guideConfig = CGuideMan.GetGuideMain()
	        local BigStepConfig = guideConfig[game._CGuideMan._CurGuideID]
	        local SmallStepConfig = BigStepConfig.Steps[game._CGuideMan._CurGuideStep]

	        if BigStepConfig ~= nil and SmallStepConfig.NextStepTriggerParam ~= nil then
	            local GuideEvent = require "Events.GuideEvent"
	            local CGame = Lplus.ForwardDeclare("CGame")
	            local event = GuideEvent()
	            event._Type = EnumDef.EGuideType.Main_NextStep
	            event._ID = game._CGuideMan._CurGuideID
	            event._Param = SmallStepConfig.NextStepTriggerParam
	            event._BehaviourID = EnumDef.EGuideBehaviourID.OnClickTargetList
	            CGame.EventManager:raiseEvent(nil, event)
	        end
	    end

        local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
	    local panelTrigger = CPanelGuideTrigger.Instance()
	    if panelTrigger ~= nil and panelTrigger:IsShow() and game._CGuideMan._CurGuideTrigger ~= nil then
	        local CGuideMan = require "Guide.CGuideMan"
	        local guideConfig = CGuideMan.GetGuideTrigger()
	        local BigStepConfig = guideConfig[game._CGuideMan._CurGuideTrigger._ID]
	        local SmallStepConfig = BigStepConfig.Steps[game._CGuideMan._CurGuideTrigger._Step]

	        if BigStepConfig ~= nil and SmallStepConfig.NextStepTriggerParam ~= nil then
	            local GuideEvent = require "Events.GuideEvent"
	            local CGame = Lplus.ForwardDeclare("CGame")
	            local event = GuideEvent()
	            event._Type = EnumDef.EGuideType.Trigger_Start
	            event._ID = game._CGuideMan._CurGuideTrigger._ID
	            event._Param = SmallStepConfig.NextStepTriggerParam
	            event._BehaviourID = EnumDef.EGuideBehaviourID.OnClickTargetList
	            CGame.EventManager:raiseEvent(nil, event)
	        end
	    end
	end
end

--删除副本倒计时
local function OnRemoveInstanceTimer()
	if instance._DungeonTimerID ~= 0 then
        _G.RemoveGlobalTimer(instance._DungeonTimerID)
        instance._DungeonTimerID = 0
    end	

    if not IsNil(instance._LabDungeonTime) then
    	instance._FrameTime:SetActive(false)
    	instance._LabDungeonTime: SetActive(false)
    	instance._LabDungeonTimeTip: SetActive(false)
    end
end

--副本倒计时
def.method("number", "number").AddInstanceTimer = function(self, nTime, period)
	self._DungeonEndTime = nTime
	self._DungeonEndPeriod = period
	-- if self._DungeonEndTime <= 0 then return end

	self:OnAddInstanceTimer()
end


-- 设置剩余时间
-- endTime: 结束时间戳(s)
-- showType: 0 祭品倒计时，1 高级祭品倒计时，2 祭坛激活倒计时
def.method("number", "number").SetLeftTime = function (self, endTime, showType)
	self._EndTime = endTime
	self._TimeShowType = showType
	if self._Parent:IsShow() then
		if self._EndTime <= 0 then return end

	    local time = self._EndTime - GameUtil.GetServerTime() / 1000
	    if time <= 0 then
		    self:CloseCountDownTime()
		    return
	    end

	    self:RemoveCountDownTimer()
        self._Guild_RefreshTime:SetActive(true)
	    -- 倒计时标题
	    local titleStr = ""
	    if self._TimeShowType == 0 then
		    -- 祭品倒计时
		    titleStr = StringTable.Get(31600)
	    elseif self._TimeShowType == 1 then
		    -- 高级祭品倒计时
		    titleStr = StringTable.Get(31601)
	    elseif self._TimeShowType == 2 then
		    -- 祭坛激活倒计时
		    titleStr = StringTable.Get(31602)
	    end
	    GUI.SetText(self._Guild_RefreshTime, titleStr)
	    local timeStr = GUITools.FormatTimeFromSecondsToZero(true, time)
        local lab_time = self._Guild_RefreshTime:FindChild("Time_Content")
	    GUI.SetText(lab_time, timeStr)
	    self._RefreshTimer = _G.AddGlobalTimer(1, false, function()
		    time = time - 1
		    if time > 0 then
			    local timeStr = GUITools.FormatTimeFromSecondsToZero(true, time)
			    GUI.SetText(lab_time, timeStr)
		    else
			    self:CloseCountDownTime()
		    end
	    end)
	end
end

-- 关闭倒计时
def.method().CloseCountDownTime = function(self)
	self:RemoveCountDownTimer()
    self._Guild_RefreshTime:SetActive(false)
end

def.method().RemoveCountDownTimer = function (self)
	if self._RefreshTimer ~= 0 then
		_G.RemoveGlobalTimer(self._RefreshTimer)
		self._RefreshTimer = 0
	end
end

def.method().OnAddInstanceTimer = function(self)
	if self._DungeonEndTime <= 0 then
		self._FrameTime:SetActive(false)
		self._LabDungeonTime: SetActive(false)
		self._LabDungeonTimeTip:SetActive(false)
		self._Guild_Time:SetActive(false)
		return
	end
   
   	OnRemoveInstanceTimer()  
    if not IsNil(self._LabDungeonTime) then
    	self._FrameTime:SetActive(true)
		self._LabDungeonTime: SetActive(true)
		self._LabDungeonTimeTip:SetActive(true)
		self._Guild_Time:SetActive(true)
		if self._DungeonEndPeriod == 0 then
			GUI.SetText(self._Guild_Time, StringTable.Get(8101))
		else
			GUI.SetText(self._Guild_Time, StringTable.Get(8102))			
		end
	end	

    if instance._DungeonTimerID == 0 then
        local callback = function()    
        	local time = (instance._DungeonEndTime - GameUtil.GetServerTime())/1000     
        	time = math.round(time)       

        	if time <= 0 then
                OnRemoveInstanceTimer()
            return end

           	local strTime = GUITools.FormatTimeFromSecondsToZero(false, time)
           	if time > 60 then
           		strTime = "<color=#7DDC37>"..strTime.."</color>"
           	else
           		strTime = "<color=#FF0000>"..strTime.."</color>"
           	end 
           	--strTime = StringTable.Get(702)..strTime
            GUI.SetText(instance._LabDungeonTime, strTime)
            GUI.SetText(self._Time_Content, strTime)          
        end
        instance._DungeonTimerID = _G.AddGlobalTimer(1, false, callback)
    end
end

local function RemoveDungeonCountdownTimer(self)
	if self._DungeonCountdownTimerID ~= 0 then
		_G.RemoveGlobalTimer(self._DungeonCountdownTimerID)
		self._DungeonCountdownTimerID = 0
	end

	if self._FrameCountdown.activeSelf then
		self._FrameCountdown:SetActive(false)
	end
	self._DungeonCountdownEndTime = 0
	self._DungeonCountdownInfo = ""
end

-- 添加副本事件倒计时
def.method("number", "string").AddDungeonCountdown = function(self, endTime, infoStr)
    warn("=======AddDungeonCountdown endTime:" .. endTime, ", infoStr:" .. infoStr)
	if endTime == 0 then
		-- 结束时间为0时，关闭倒计时
		RemoveDungeonCountdownTimer(self)
		return
	end

	self._DungeonCountdownEndTime = endTime
	self._DungeonCountdownInfo = infoStr

	self:OnAddDungeonCountdown()
end

def.method().OnAddDungeonCountdown = function(self)
	if self._DungeonCountdownEndTime == 0 then return end

	local leftTime = self._DungeonCountdownEndTime - GameUtil.GetServerTime() / 1000
	if leftTime <= 0 then
		if self._FrameCountdown.activeSelf then
			self._FrameCountdown:SetActive(false)
		end
		return
	end

	if not self._FrameCountdown.activeSelf then
		self._FrameCountdown:SetActive(true)
	end
	GUI.SetText(self._LabDungeonCountdownTitle, self._DungeonCountdownInfo)

	if self._DungeonCountdownTimerID == 0 then
		local callback = function()    
			local time = instance._DungeonCountdownEndTime - GameUtil.GetServerTime() / 1000     
			time = math.round(time)       

			if time <= 0 then
				RemoveDungeonCountdownTimer(self)
				return
			end

			local strTime = GUITools.FormatTimeFromSecondsToZero(false, time)
			if time > 60 then
				strTime = "<color=#7DDC37>"..strTime.."</color>"
			else
				strTime = "<color=#FF0000>"..strTime.."</color>"
			end 
			GUI.SetText(instance._LabDungeonCountdown, strTime)
		end
		self._DungeonCountdownTimerID = _G.AddGlobalTimer(1, false, callback)
	end
end

def.method().OnAddGuildBattleTimer = function(self)
    local time = self._EndTime - GameUtil.GetServerTime() / 1000
	if time <= 0 then
		self:CloseCountDownTime()
		return
	end
    local timeStr = GUITools.FormatTimeFromSecondsToZero(true, time)
    local lab_time = self._Guild_RefreshTime:FindChild("Time_Content")
	GUI.SetText(lab_time, timeStr)
    if self._RefreshTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RefreshTimer)
    end
	self._RefreshTimer = _G.AddGlobalTimer(1, false, function()
		time = time - 1
		if time > 0 then
			local timeStr = GUITools.FormatTimeFromSecondsToZero(true, time)
			GUI.SetText(lab_time, timeStr)
		else
			self:CloseCountDownTime()
		end
	end)
end

def.method().Hide = function(self)
	if self._Panel ~= nil then
		self._Panel:SetActive(false)
	end
	if not IsNil(self._Guild_Time) then
		self._Guild_Battle:SetActive(false)
		self._Guild_Time:SetActive(false)
	end
	if self._DungeonGoalTimer ~= 0 then 
		_G.RemoveGlobalTimer(self._DungeonGoalTimer)
		self._DungeonGoalTimer = 0
	end
	local CPanelTracker = require "GUI.CPanelTracker"
	CPanelTracker.Instance(): ResetDungeonShow()
	OnRemoveInstanceTimer()
	RemoveDungeonCountdownTimer(self)
    self:RemoveCountDownTimer()
	if self._DungeonEndTime <= GameUtil.GetServerTime() then 
		self._DungeonEndTime = 0
		self._DungeonEndPeriod = 0
	end
    if self._EndTime <= GameUtil.GetServerTime()/1000 then
        self._EndTime = 0
    end
    self._TimeShowType = 0
end

def.method().Destroy = function (self)
	self:Hide()
	dungeonGoal = nil
	self._TableGoalItem = nil
	self._Panel = nil
	self._ImgClick = nil
	self._ImgEffect1 = nil
	self._ImgEffect2 = nil
	self._LabDungeonTime = nil
	self._LabDungeonTimeTip = nil
	self._FrameTime = nil 
	self._Guild_Battle = nil
	self._Target_Content = nil
	self._Kill_Content = nil
	self._Dead_Content = nil
	self._Guild_Time = nil
	self._Time_Content = nil
	self._FrameCountdown = nil
	self._LabDungeonCountdown = nil
	self._LabDungeonCountdownTitle = nil

	instance = nil
end


CPageDungeonGoal.Commit()
return CPageDungeonGoal