local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CPageQuest = require "GUI.CPageQuest"
local CPageTeam = require "GUI.CPageTeam"
local CPageDungeonGoal = require "GUI.CPageDungeonGoal"
local CTeamMan = require "Team.CTeamMan"
local CPanelMap = require "GUI.CPanelMap"	
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local QuestDef = require "Quest.QuestDef"
local TeamMode = require "PB.data".TeamMode
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"

local CPanelTracker = Lplus.Extend(CPanelBase, "CPanelTracker")
local def = CPanelTracker.define

local PAGE = {QUEST_LIST = 0, TEAM_LIST = 1, DUNGEON_GOAL = 2} --筛选类型

def.field("number")._CurrentSubPanel = 1 --当前选中的子界面,1:任务 2:队伍 3:副本目标
def.field(CPageQuest)._QuestPage = nil  --任务页
def.field(CPageTeam)._TeamPage = nil    --队伍页
def.field(CPageDungeonGoal)._DungeonGoalPage = nil --副本目标 
def.field("userdata")._TogTeamLabel = nil 
def.field("userdata")._TogBtnQuest = nil 		--任务toggle
def.field("userdata")._TogBtnTeam  = nil 		--队伍toggle
def.field("userdata")._TogBtnDungeon = nil      --副本toggle
--def.field("userdata")._TogBtnDungeonGoal = nil  --副本目标BTN
def.field("number")._DungeonTime = 0 --副本时间
def.field("userdata")._BtnMax = nil --最大化按钮
def.field("table")._TogglePage = BlankTable

def.field("boolean")._IsInitDungeonShow = false
def.field("boolean")._IsSetMinWhenOpen = false -- 界面打开前是否被设置最小化
def.field("boolean")._IsInitDungeon = false -- 副本目标页是否初始化
def.field("boolean")._IsOpenDungeon = false -- 是否开启副本页
def.field("table")._HideObjGroup = BlankTable -- 需要隐藏的控件

-- 导航栏队伍相关 显隐控件
def.field("userdata")._Btn_AutoMatch = nil
def.field("userdata")._Btn_CreateTeam = nil
def.field("userdata")._Btn_JoinTeam = nil
def.field("userdata")._Btn_ManageTeam = nil
def.field("userdata")._Btn_Follow = nil
def.field("userdata")._Btn_Matching = nil
def.field("userdata")._Btn_Skip = nil
def.field("userdata")._Lab_MemberCount = nil
def.field("userdata")._Img_Matching = nil

def.field("userdata")._TeamApplyRedDotObj = nil -- 组队申请红点控件
def.field("table")._BtnFollowInfo = BlankTable	-- 组队跟随按钮信息

def.field("number")._EndTimeCache = 0
def.field("number")._EndDungeontimeCache = 0
def.field("number")._ShowType = 0
def.field("number")._EnterDungeonType = 0


local instance = nil
def.static("=>",CPanelTracker).Instance = function ()
	if not instance then
        instance = CPanelTracker()
        instance._PrefabPath = PATH.Panel_Main_QuestN
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()

		instance._QuestPage = CPageQuest.Instance()
	end
	return instance
end

local function OnTeamInfoChange(sender, event)
--队员成员数量变化，全部刷新时才变化
	if instance ~= nil then
        if event._Type == EnumDef.TeamInfoChangeType.ResetAllMember or event._Type == EnumDef.TeamInfoChangeType.MATCHSTATECHANGE or event._Type == EnumDef.TeamInfoChangeType.TeamMode then 
		    instance:UpdateTeamMemberCount()
        end
	end
end

local function OnMatchEventHandle(sender, event)
    if instance ~= nil then
        instance:UpdateTeamButtons()
    end
end

def.override().OnCreate = function(self)
	self._QuestPage:SetRoot(self:GetUIObject("List_Quest"))
	self._TeamPage = CPageTeam.new(self, self:GetUIObject("List_Team"))
	self._DungeonGoalPage = CPageDungeonGoal.new(self, self:GetUIObject("List_Dungeon"))

	self._TogBtnQuest = self:GetUIObject("Tg_Quest")
	self._TogBtnTeam = self:GetUIObject("Tg_Team")
	self._TogBtnDungeon = self:GetUIObject("Tg_Dungeon")
	self._BtnMax = self:GetUIObject("Img_OpenBG")

	if not IsNil(self._TogBtnDungeon) then
		self._TogBtnDungeon: SetActive(false)
	end

	self._HideObjGroup = {}
	table.insert(self._HideObjGroup, self:GetUIObject("Frame_ToolBar"))
	table.insert(self._HideObjGroup, self:GetUIObject("Frame_Lists"))
	table.insert(self._HideObjGroup, self:GetUIObject("Img_CloseBG"))

	self._TogglePage = {}
	self._TogglePage.Team = self._TogBtnTeam: GetComponent(ClassType.Toggle)
	self._TogglePage.Quest = self._TogBtnQuest: GetComponent(ClassType.Toggle)
	self._TogglePage.Dungeon = self._TogBtnDungeon :GetComponent(ClassType.Toggle)

	self._TeamApplyRedDotObj = self._TogBtnTeam:FindChild("RedPoint")

	-- 组队显隐控件
	self._Btn_AutoMatch = self:GetUIObject('Btn_AutoMatch')
    self._Btn_Matching = self:GetUIObject("Btn_Matching")
	self._Btn_CreateTeam = self:GetUIObject('Btn_CreateTeam')
	self._Btn_JoinTeam = self:GetUIObject('Btn_JoinTeam')
	self._Btn_ManageTeam = self:GetUIObject('Btn_ManageTeam')
	self._Btn_Follow = self:GetUIObject('Btn_Follow')
	self._Lab_MemberCount = self:GetUIObject("Lab_MemberCount")
	self._Img_Matching = self:GetUIObject("Img_Matching")
	self._Btn_Skip = self:GetUIObject("Btn_Skip")
	self._Btn_Skip:SetActive(false)
	self._BtnFollowInfo = {}
	self._BtnFollowInfo.Obj = self:GetUIObject("Btn_Follow")
	self._BtnFollowInfo.TextObj = self:GetUIObject("Lab_Follow")

	self:SwitchPage(PAGE.QUEST_LIST)
    --self._QuestPage:AddIdleTipTimer()
end

def.override("dynamic").OnData = function(self,data)
	if game._CurWorld ~= nil and game._CurWorld._WorldInfo ~= nil then
		local mapTid = game._CurWorld._WorldInfo.MapTid
		if game._DungeonMan:Get3V3WorldTID() == mapTid or game._DungeonMan:GetEliminateWorldTID() == mapTid
			or game._DungeonMan:Get1v1WorldTID() == mapTid then
		 	game._GUIMan:CloseByScript(self)
		 	return
		end
	end

	-- 更新 队伍成员数量
	self:UpdateTeamMemberCount()

	--副本中下线,或者中途打开界面，需要直接显示副本
	if(self._IsInitDungeon) then
		self: OpenDungeonUI(self._IsOpenDungeon)
		self._IsInitDungeon = false
	end

	if self._IsSetMinWhenOpen then
		self:ShowSelfPanel(false)
		self._IsSetMinWhenOpen = false
	end

	-- 初始化时调用 设置
	CRedDotMan.SaveModuleDataToUserData("TeamApply", false)
	-- 刷新 组队申请红点信息
	self:UpdateTeamRedDotState()
    if self._EndTimeCache ~= 0 then
        self:UpdateGuildBattleRefreshTime(self._EndTimeCache, self._ShowType)
        self._EndTimeCache = 0
        self._ShowType = 0
    end
    if self._EndDungeontimeCache ~= 0 then
        self:AddDungeonTime(self._EndDungeontimeCache, self._EnterDungeonType)
        self._EndDungeontimeCache = 0
        self._EnterDungeonType = 0
    end

	CGame.EventManager:addHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:addHandler('PVEMatchEvent', OnMatchEventHandle)
end

-- 恢复原样
def.method().ResetLayout = function(self)
	if IsNil(self._BtnMax) then return end

	self._BtnMax:SetActive(false)
	for k,v in pairs(self._HideObjGroup) do
		v:SetActive(true)
	end
end

def.method("boolean").ShowSpecialCameraUI = function(self,b)
	self._Btn_Skip:SetActive(b)
end

-- 刷新 组队申请红点信息
def.method().UpdateTeamRedDotState = function(self)
	local bShow = CRedDotMan.GetModuleDataToUserData("TeamApply") or false
	self._TeamApplyRedDotObj:SetActive(bShow)
end

def.method().UpdateFollowCoolingdownTime = function(self)
	local teamMan = CTeamMan.Instance()
	if self._CurrentSubPanel == PAGE.TEAM_LIST and teamMan:IsFollowClickCoolingdown() then
		local strTime = teamMan:GetFollowCoolingdownTime()
		GUI.SetText(self._BtnFollowInfo.TextObj, string.format(StringTable.Get(22021), strTime))
	end
end

def.method("boolean").DisableFollowButtonState = function(self, bDisable)
	if self._CurrentSubPanel == PAGE.TEAM_LIST then
		local enable = not bDisable
		GameUtil.SetButtonInteractable(self._BtnFollowInfo.Obj, enable)
	end
end

def.method().UpdateFollowCount = function(self)
	local teamMan = CTeamMan.Instance()
	if self._CurrentSubPanel == PAGE.TEAM_LIST and not teamMan:IsFollowClickCoolingdown() then
		local followedCnt = CTeamMan.Instance():GetTeamMemberFollowingCount()
		GUI.SetText(self._BtnFollowInfo.TextObj, string.format(StringTable.Get(230), followedCnt))
	end
end

def.method().DisableFollowButton = function(self)
	if self._BtnFollowInfo and self._BtnFollowInfo.Obj then
		self._BtnFollowInfo.Obj:SetActive(false)
	end
end

def.method().UpdateFollowButton = function(self)
	if self._CurrentSubPanel ~= PAGE.TEAM_LIST then return end

	local hp = game._HostPlayer
	local curFollowState = CTeamMan.Instance()._Team._FollowState
	local EFollowState = EnumDef.FollowState
	local teamMan = CTeamMan.Instance()

	self:DisableFollowButtonState( teamMan:IsFollowClickCoolingdown() )

	--没组队或者没队友 隐藏Button
	if curFollowState == EFollowState.No_Team or 
	   curFollowState == EFollowState.Leader_NoMember or 
	   self._CurrentSubPanel ~= PAGE.TEAM_LIST or 
	   curFollowState == EFollowState.In3V3Fight then
		self:DisableFollowButton()
		return
	end
	
	if curFollowState == EFollowState.Leader_Followed or curFollowState == EFollowState.Leader_None then
		--warn("Leader_Followed")
		self._BtnFollowInfo.Obj:SetActive(true)
		self:UpdateFollowCount()

	elseif curFollowState == EFollowState.Member_None then
		--warn("Member_None")
		self._BtnFollowInfo.Obj:SetActive(true)
		GUI.SetText(self._BtnFollowInfo.TextObj, StringTable.Get(233))

	elseif curFollowState == EFollowState.Member_Followed then
		--warn("Member_Followed")
		self._BtnFollowInfo.Obj:SetActive(true)
		GUI.SetText(self._BtnFollowInfo.TextObj, StringTable.Get(231))

	end
end

def.method().OnClickFollow = function(self)
	local teamMan = CTeamMan.Instance()
	if teamMan:IsTeamLeader() then
	-- 队长:召唤跟随
		-- warn("队长:召唤跟随")
		if not teamMan:IsFollowClickCoolingdown() then
			teamMan:OnClickFollowCoolingdown()
			teamMan:FollowLeader(true)
		else
			TeraFuncs.SendFlashMsg(StringTable.Get(19409), false)
		end
	else
	-- 队员:自动跟随
		-- warn("队员:自动跟随")
		teamMan:FollowLeader( not teamMan:IsFollowing())
	end
end

---------------------------------------------------------
--  更新队伍页签的按钮s，如果是团队，需要分一行/二行/三行
--  进行不同地显示，单行的时候该显示的按钮都显示，二行的
--  时候“匹配中“优先级要高于“管理团队”，三行只显示召集
---------------------------------------------------------
def.method().UpdateTeamButtons = function(self)
    local bInTeam = CTeamMan.Instance():InTeam()
    local is_matching = CPVEAutoMatch.Instance():IsMatching()
    local is_big_team = CTeamMan.Instance():IsBigTeam()

    self._Btn_AutoMatch:SetActive(false)
    self._Btn_Matching:SetActive(false)
    self._Btn_CreateTeam:SetActive(false)
    self._Btn_ManageTeam:SetActive(false)
    self._Btn_JoinTeam:SetActive(false)
    self._Lab_MemberCount:SetActive(bInTeam)
    self:UpdateFollowButton()
    if bInTeam then
        local list = CTeamMan.Instance():GetMemberList()
    	local count = #list
    	local maxCount = CTeamMan.Instance():GetMemberMax()
        local is_team_leader = CTeamMan.Instance():IsTeamLeader()

        local lab_manage = self._Btn_ManageTeam:FindChild("Img_BG/Lab_ManageTeam")
	    if is_team_leader then
	        GUI.SetText(lab_manage, StringTable.Get(is_big_team and 22052 or 22050))
	    else
	        GUI.SetText(lab_manage, StringTable.Get(is_big_team and 22053 or 22051))
	    end

        if is_big_team then
            if count < maxCount - 2 then    -- 两行以内
                if is_matching then
                    self._Btn_Matching:SetActive(true)
                else
                    self._Btn_ManageTeam:SetActive(true)
                    self._Btn_Matching:SetActive(false)
                end
                if count < maxCount - 5 then    -- 一行以内
                    self._Btn_ManageTeam:SetActive(true)
                end
            end
        else
            if is_matching then
                if count ~= maxCount then
                    if count < maxCount - 1 then
                        self._Btn_ManageTeam:SetActive(true)
                    end
                    self._Btn_Matching:SetActive(true)
                end
            else
                if count < maxCount then
                    self._Btn_ManageTeam:SetActive(true)
                end
            end
        end
        GUI.SetText(self._Lab_MemberCount, string.format(StringTable.Get(30314), count))
    else
        self._Btn_CreateTeam:SetActive(true)
        self._Btn_JoinTeam:SetActive(true)
        self._Btn_AutoMatch:SetActive(not is_matching)
        self._Btn_Matching:SetActive(is_matching)
    end
end

def.method().UpdateTeamMemberCount = function(self)
	if not self:IsShow() then return end
    self:UpdateTeamButtons()
	-- 刷新队伍页签
    self._TeamPage:UpdateAll()
end

def.method("number").SwitchPage = function(self, page)
	if IsNil(self._BtnMax) then return end
	self._CurrentSubPanel = page
	if page == PAGE.QUEST_LIST then
		self._TogglePage.Team.isOn = false
		self._TogglePage.Quest.isOn = true
		
		self._QuestPage:Show()
		self._TeamPage:Hide()
		self._DungeonGoalPage:Hide()
		game._CGuideMan:IsShowGuide(true,self._Panel.name)
	elseif page == PAGE.TEAM_LIST then
		self._TogglePage.Quest.isOn = false
		self._TogglePage.Dungeon.isOn = false
		self._TogglePage.Team.isOn = true

		self._QuestPage:Hide()
		self._DungeonGoalPage:Hide()
		self._TeamPage:Show()
		game._CGuideMan:IsShowGuide(false,self._Panel.name)
	elseif page == PAGE.DUNGEON_GOAL then
		self._TogglePage.Quest.isOn = false
		self._TogglePage.Team.isOn = false
		self._TogglePage.Dungeon.isOn = true

		self._QuestPage:Hide()
		self._TeamPage:Hide()
		self._DungeonGoalPage:Show()
		game._CGuideMan:IsShowGuide(true,self._Panel.name)
	end
	
	self:UpdateTeamMemberCount()
end

--重置副本的初始化标志。因为有的时候可能设置不正确。每次副本进入设置一下
def.method().ResetDungeonShow = function(self)
	self._IsInitDungeonShow = false
end

--副本页开启与关闭。这个不是主动操作，需要状态触发！！
def.method("boolean").OpenDungeonUI = function(self, isOpen)	
	if self._Panel == nil then 
		self._IsInitDungeon = true
		self._IsInitDungeonShow = false
		self._IsOpenDungeon = isOpen
		return 
	end

	-- 从任务状态切换过来时，停止自动化
	if isOpen and self._CurrentSubPanel == PAGE.QUEST_LIST then
		CQuestAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()	
		--CDungeonAutoMan.Instance():Stop()
	end

	if isOpen then
		if not self._IsInitDungeonShow then
			self._IsInitDungeonShow = true
			self._TogBtnQuest:SetActive(false)
			self._TogBtnDungeon: SetActive(true)
			
			if not (self._CurrentSubPanel == PAGE.TEAM_LIST) then
				self:SwitchPage(PAGE.DUNGEON_GOAL)	
			end
		else
			local dungeonGoal = game._DungeonMan:GetDungeonGoal()
			if dungeonGoal == nil then return end --没有副本目标，但是又要显示副本类型。这个时候UI不作处理

			self:ChangeDungeonGoalPanel()
	        self:ShowDungeonGoalUIFX(QuestDef.UIFxEventType.Completed)
		end	
	else
		if self._CurrentSubPanel == PAGE.DUNGEON_GOAL then
			self:SwitchPage(PAGE.QUEST_LIST)
		end
		
		self._TogBtnDungeon:SetActive(false)
		self._TogBtnQuest:SetActive(true)
		self._IsInitDungeonShow = false
	end
end

--刷新副本计数器
def.method("number").UpdateDungeonGoalPanel = function(self,nIndex)
	if self._Panel == nil then 
		self._IsInitDungeon = true
		self._IsOpenDungeon = true
	return end
	
	if self._DungeonGoalPage == nil then
		self._DungeonGoalPage = CPageDungeonGoal.new(self, self:GetUIObject("List_Dungeon"))
	end

	if self._DungeonGoalPage == nil then return end
	self._DungeonGoalPage:UpdateDungeonGoalPanel(nIndex)
    self:ShowDungeonGoalUIFX(QuestDef.UIFxEventType.ObjectCountChange)
end

def.method("number").ShowDungeonGoalUIFX = function(self, stateType)
    if self._Panel == nil or self._DungeonGoalPage == nil then return end
    self._DungeonGoalPage:ShowDungeonGoalUIFX(stateType)
end

--改变副本计数器显示
def.method().ChangeDungeonGoalPanel = function(self )
	self._DungeonGoalPage:InitDungeonGoalPanel()
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if id == "Tg_Team" then
		--1v1竞技场不准打开组队界面，临时的
		if game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get1v1WorldTID() then			
			return
		end

		local function OnClickTeam(bIsCurrentPanel)
			if not bIsCurrentPanel then return end
			--3V3竞技场不能操作组队
			if game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get3V3WorldTID() then	return end
			
			local hostPlayer = game._HostPlayer
			if not hostPlayer:InTeam() then
				TeamUtil.RequestTeamListInRoom(1)
				game._GUIMan:Open("CPanelUITeamCreate",nil)
			elseif bIsCurrentPanel then
				TeamUtil.RequestTeamEquipInfo()
			end
		end

		-- 处于当前页面
		if self._CurrentSubPanel == PAGE.TEAM_LIST then
			OnClickTeam(true)
		else
			self:SwitchPage(PAGE.TEAM_LIST)
			OnClickTeam(false)
		end
		
	elseif id == "Tg_Quest" then
		if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.TaskTrack) then
			return
		end
		-- 处于当前页面
		if self._CurrentSubPanel == PAGE.QUEST_LIST then
			game._GUIMan:Open("CPanelUIQuestList", nil)
		else
			self:SwitchPage(PAGE.QUEST_LIST)
		end
		-- if self._CurrentSubPanel == PAGE.QUEST_LIST then return end
		-- self:SwitchPage(PAGE.QUEST_LIST)
	elseif id == "Tg_Dungeon" then
		if self._CurrentSubPanel == PAGE.DUNGEON_GOAL then return end
		self._CurrentSubPanel = PAGE.DUNGEON_GOAL
		self:SwitchPage(PAGE.DUNGEON_GOAL)
		--warn("!!!!!!!!!!!!!!!!!!!!!!",debug.traceback())
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	local lua_index = index+1
	if id == "List_Quest" then
		if self._CurrentSubPanel == PAGE.QUEST_LIST then
			self._QuestPage:OnInitItem(item, lua_index)
			--warn("?????????????????OnInitItemNewList_Quest")
		end
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.TaskTrack) then
		warn("QuestPage failed to call OnSelectItem, bcz EnumDef.EGuideTriggerFunTag.TaskTrack Locked")
		return
	end
	local lua_index = index+1
	--warn(list.name.."___"..item.name)
	if id == "List_Quest" then
		
		if self._CurrentSubPanel == PAGE.QUEST_LIST then
    		-- CPanelMap.Instance():StopUpdateAutoPathing()
			self._QuestPage:OnSelectItem(item, lua_index)
		end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	local lua_index = index+1
	if id == "List_Quest" then
		if self._CurrentSubPanel == PAGE.QUEST_LIST then
			self._QuestPage:OnSelectItemButton(item, id_btn, lua_index)
		end
	end
end

def.override("string").OnClick = function(self, id)
	if id == "List_Dungeon" then
		if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.TaskTrack) then
			return
		end
		-- CPanelMap.Instance():StopUpdateAutoPathing()
		--停止跟随
  		game._HostPlayer:StopAutoFollow()
		CQuestAutoMan.Instance():Stop() 
		CAutoFightMan.Instance():Start()  
		CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, false) 
    	CDungeonAutoMan.Instance():Start()
	elseif id == "Btn_Follow" then
		if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.TaskTrack) then
			return
		end
		self:OnClickFollow()
	--[[
	elseif id == "Btn_UnFollow" then
		self:OnClickUnFollow()
	]]
--	elseif id == "Tab_MatchingInfo" then
--		local targetMatchId =  CTeamMan.Instance()._TargetMatchId
--		TeamUtil.RequestTeamListInRoom( targetMatchId )
--		game._GUIMan:Open("CPanelUITeamCreate", { TargetMatchId = targetMatchId })
	elseif string.find(id, "MemberItem") then
		TeamUtil.RequestTeamEquipInfo()
	elseif id == "Btn_JoinTeam" then
		TeamUtil.RequestTeamListInRoom(1)
		game._GUIMan:Open("CPanelUITeamCreate",nil)
	elseif id == "Btn_CreateTeam" then
		TeamUtil.CreateTeam(0, 0, "", 1, false, 0)
	elseif id == "Btn_ManageTeam" then
		TeamUtil.RequestTeamEquipInfo()
    elseif id == "Btn_AutoMatch" or id == "Btn_Matching" then
    	game._GUIMan:Open("CPanelUITeamMatchingBoard", nil)
	elseif id == "Btn_Skip" then
		game:CameraMoveEnd()
	end

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

-- 界面打开前设置界面最小化
def.method("boolean").SetMinStatus = function (self, is_set_min)
	self._IsSetMinWhenOpen = is_set_min
end

--锁定任务栏里面某一个toggle
def.method("string","boolean").SetToggleInteratable = function(self,strToggle,isLock)
	if strToggle == "Tg_Team" then
		GameUtil.SetButtonInteractable(self._TogBtnTeam, isLock)
	elseif strToggle == "Tg_Quest" then
		GameUtil.SetButtonInteractable(self._TogBtnQuest, isLock)
	elseif strToggle == "Tg_Dungeon" then
		GameUtil.SetButtonInteractable(self._TogBtnDungeon, isLock)
	end
end

--副本目标的锁定IMG显示状态
def.method("boolean").SyncAutoDungeonUIState = function(self, isClick)
	if self._DungeonGoalPage then
		self._DungeonGoalPage:SyncAutoDungeonUIState(isClick)	
	end
end

--设置副本时间 0:准备 1:开始
def.method("number", "number").AddDungeonTime = function(self, endTime, period)
	if self._DungeonGoalPage then
		self._DungeonGoalPage:AddInstanceTimer(endTime, period)
	end
end

def.method("number", "number").CacheDungeonCountdown = function(self, endTime, enterType)
    self._EndDungeontimeCache = endTime
    self._EnterDungeonType = enterType
end

--设置副本事件倒计时
def.method("number", "string").AddDungeonCountdown = function(self, endTime, infoStr)
	if self._DungeonGoalPage then
		self._DungeonGoalPage:AddDungeonCountdown(endTime, infoStr)
	end
end

def.method("number", "number").CacheEndTimeAndShowType = function(self, endTime, showType)
    self._EndTimeCache = endTime
    self._ShowType = showType
end

def.method("number", "number").UpdateGuildBattleRefreshTime = function(self, endTime, showType)
    if self._DungeonGoalPage ~= nil and game._GuildMan:IsGuildBattleScene() then
        self._DungeonGoalPage:SetLeftTime(endTime, showType)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	CGame.EventManager:removeHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:removeHandler('PVEMatchEvent', OnMatchEventHandle)
end

def.override().OnDestroy = function(self)
	if self._BtnFollowInfo.Obj then
		self._BtnFollowInfo.Obj:SetActive(false)
		self._BtnFollowInfo.Obj = nil
	end

	if self._QuestPage ~= nil then
		self._QuestPage:Destroy()
		self._QuestPage = nil
	end

	if self._TeamPage ~= nil then
		self._TeamPage:Destroy()
		self._TeamPage = nil
	end

	if self._DungeonGoalPage ~= nil then
		self._DungeonGoalPage:Destroy()
		self._DungeonGoalPage = nil
	end

	--self._TogTeamLabel = nil
	self._IsInitDungeonShow = false
	self._IsInitDungeon = false
	self._IsSetMinWhenOpen = false
	self._IsOpenDungeon = false
    self._EndTimeCache = 0
    self._ShowType = 0
    self._EndDungeontimeCache = 0
    self._EnterDungeonType = 0
	instance = nil
end

CPanelTracker.Commit()
return CPanelTracker