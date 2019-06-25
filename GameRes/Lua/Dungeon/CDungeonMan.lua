--[[----------------------------------------------
         		 副本管理器
          				--- by luee 2016.12.28
--------------------------------------------------]]
local Lplus = require "Lplus"
local CDungeonMan = Lplus.Class("CDungeonMan")
local def = CDungeonMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelTracker = require "GUI.CPanelTracker"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CPanelMirrorArena = require"GUI.CPanelMirrorArena"
local CPage3V3 = require"GUI.CPage3V3"
local CPageBattle = require"GUI.CPageBattle"
local EInstanceType = require "PB.Template".Instance.EInstanceType
local EWorldType = require "PB.Template".Map.EWorldType
local EGoalType = require "PB.data".DungeonGoalType
local MapBasicConfig = require "Data.MapBasicConfig"
local CPath = require"Path.CPath"
local CBeginnerDungeonMan = require "Dungeon.CBeginnerDungeonMan"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CTeamMan = require "Team.CTeamMan"

def.field("number")._DungeonID = -1--非法值，不在副本的标志
def.field("number")._TowerDungeonFloor = 0 --爬塔层数
def.field("number")._TowerBestPassTime = 0 --爬塔最快通关时间
--快速匹配ID
def.field("number")._QuickMatchID = 0  			-- 快速匹配ID
def.field("number")._QuickMatchTargetId = 0		-- 快速匹配 副本ID

-- 3V3倒计时 记录系统时间
def.field("number")._3V3MatchingStartTime = 0
def.field("number")._3V3BanEndTime = 0
def.field("number")._BattleBanEndTime = 0

-- 无畏战场倒计时 记录系统时间
def.field("number")._BattleMatchingStartTime = 0

def.field("number")._TowerDungeonTID = 0 --爬塔试炼副本TID
def.field("number")._JJC1V1WorldTID = 0
def.field("number")._JJC3V3WorldTID = 0
def.field("number")._EliminateWorldID = 0

def.field("number")._InstanceEndTime = 0 
-- Boss进场动画
def.field("number")._BossAnimationTimer = 0
def.field("userdata")._CameraAnimationPrafab = nil
def.field("number")._CameraAnimationEntityID = 0 --播放镜头动画的个体ID
-- 远征
def.field("number")._CurExpeditionChapter = 0 				-- 当前远征的章节
def.field("number")._ExpeditionResetTime = 0 				-- 远征重置时间
def.field("table")._TableExpeditionAffixs = BlankTable 		-- 远征Boss词缀列表
def.field("table")._TableExpeditionChapterData = BlankTable -- 远征章节数据

def.field("number")._CurIntroductionTID = 0 -- 当前副本的介绍弹窗ID

--存储全部副本的模板信息
def.field("table")._TableAllDungeonInfo = BlankTable
--服务器同步的副本数据
def.field("table")._TableDungeonData = nil
--副本目标
def.field("table")._TableDungeonGoal = nil

def.static("=>", CDungeonMan).new = function()
    local obj = CDungeonMan()
	return obj
end

def.method().LoadAllDungeonData = function (self)
    self._TableAllDungeonInfo = {}
    local allInstance = GameUtil.GetAllTid("Instance")
    for _,v in ipairs(allInstance) do
        self._TableAllDungeonInfo[#self._TableAllDungeonInfo + 1] = v
    end
   
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	self._TowerDungeonTID = CSpecialIdMan.Get("TowerDungeonID")

	local temID1 = CSpecialIdMan.Get("ArenaSceneOne")
	self._JJC1V1WorldTID = CElementData.GetTemplate("Instance", temID1).AssociatedWorldId
	
	temID1 = CSpecialIdMan.Get("ArenaScene3V3")
	self._JJC3V3WorldTID = CElementData.GetTemplate("Instance", temID1).AssociatedWorldId
	temID1 = CSpecialIdMan.Get("EliminateScene")
	self._EliminateWorldID = CElementData.GetTemplate("Instance", temID1).AssociatedWorldId
	--self._BeginnerDungeonTID = CSpecialIdMan.Get("BeginnerDungeonId")
end

--获取所有副本数据(TId)
def.method("=>","table").GetAllDungeonInfo = function(self)
	return self._TableAllDungeonInfo
end

--是否在副本中
def.method("=>", "boolean").InDungeon = function(self)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid
	return  MapBasicConfig.GetMapType(nCurMapID) == EWorldType.Instance
end

--是否在相位中
def.method("=>","boolean").InPharse = function(self)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid
	return  MapBasicConfig.GetMapType(nCurMapID) == EWorldType.Pharse	
end

--是否在相位副本
def.method("=>","boolean").InImmediate = function(self)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid
	return  MapBasicConfig.GetMapType(nCurMapID) == EWorldType.Immediate
end

--添加副本数据
def.method("table").AddDungeonData = function(self, data)
	if(self._TableDungeonData == nil) then 
		self._TableDungeonData = {}
	end

	self._TableDungeonData[#self._TableDungeonData + 1] = data
end

--通过地图id获取副本数据
def.method("number", "=>", "table").GetDungeonDataByWorldId = function(self, id)
	for i, v in  ipairs(self._TableAllDungeonInfo) do
		local dungeon = CElementData.GetTemplate("Instance", v)
		if dungeon.AssociatedWorldId == id then
			return dungeon
		end
	end

	return nil
end

--通过副本ID，获得副本数据
def.method("number","=>","table").GetDungeonData = function(self, nInstanceID)
	if self._TableDungeonData == nil then return nil end
	for _,v in ipairs(self._TableDungeonData) do
		if( v.DungeonTId == nInstanceID) then
			return v
		end
	end

	return nil
end

--获取当前副本信息，如果不在副本或者副本错误就是NIL
def.method("=>","table").GetCurDungeonData = function(self)
	if not self: InDungeon() then return nil end

	return self: GetDungeonData(self._DungeonID)
end

--副本是否开启
def.method("number","=>","boolean").DungeonIsOpen = function(self, tid)
	local isOpen = false
	local dungeonTemplate = CElementData.GetInstanceTemplate(tid)
	if dungeonTemplate ~= nil then
		-- if dungeonTemplate.InstanceType == EInstanceType.INSTANCE_EXPEDITION then
		-- 	-- 远征数据单独取
		-- 	for _, chapterData in ipairs(self._TableExpeditionChapterData) do
		-- 		for _, dungeonData in ipairs(chapterData.dungeonDatas) do
		-- 			if dungeonData.dungeonTId == tid then
		-- 				isOpen = dungeonData.bOpen
		-- 				break
		-- 			end
		-- 		end
		-- 	end
		-- else
			local dungeonData = self:GetDungeonData(tid)
			if dungeonData ~= nil then
				isOpen = dungeonData.IsOpen
			end
		-- end
	end
	return isOpen
end

--改变副本数据
def.method("table").ChangeDungeonData = function(self,data)
	if self._TableDungeonData == nil then return end
	
	for _,v in ipairs(self._TableDungeonData) do
		if( v.DungeonTId == data.DungeonTId) then
			local oldStatus = v.IsOpen
			v.IsOpen = data.IsOpen
			v.PassTime = data.PassTime
			v.StarNum = data.StarNum
			v.RemainderTime = data.RemainderTime
			v.IsPlayEffects = data.IsPlayEffects
			v.DungeonFinishFlag = data.DungeonFinishFlag
			
			if not oldStatus and data.IsOpen then
				-- 从未解锁到解锁
				self:OnDungeonUnlock(v.DungeonTId)
			end
		end
	end
end

--获得第一个没有完成的副本目标
def.method("=>","table").GetDungeonGoal = function(self)
	if self._TableDungeonGoal == nil or #self._TableDungeonGoal <= 0 then 
		--print("self._TableDungeonGoal == nil or #self._TableDungeonGoal <= 0")
		return nil 
	end

	-- warn("?self._TableDungeonGoal-------------->",#self._TableDungeonGoal)
	--返回副本目标没完成的第一条！
	for i,v in ipairs(self._TableDungeonGoal) do
		-- warn(" i ",i)
		if v ~= nil then
			
			if v.CurCount < v.MaxCount then		
				return v  
			else
				--print("Dungeon Goal Data : GoalType "..v.GoalType .."Id  "..v.Id .."TemplateId  "..v.TemplateId .. "MaxCount  "..v.MaxCount .."CurCount "..v.CurCount)
			end
		end
	end

	return nil
end

--通过索引，获得某一个具体的副本目标
def.method("number","=>","table").GetDungeonGoalByIndex = function(self,nIndex)
	return self._TableDungeonGoal[nIndex]
end

--获得所有副本目标
def.method("=>","table").GetAllDungeonGoal = function(self)
	return self._TableDungeonGoal
end

--获取所有副本杀怪目标
def.method("=>","table").GetALLMonsterGoal = function(self)	
	if self._TableDungeonGoal == nil or #self._TableDungeonGoal <= 0 then 
		return nil 
	end
	
	local monstertable = nil
	-- warn("?self._TableDungeonGoal-------------->",#self._TableDungeonGoal)
	for i,v in ipairs(self._TableDungeonGoal) do
		if (v ~= nil) and (v.GoalType == EGoalType.EDUNGEONGOAL_KILLMONSTER) then
			if monstertable == nil then
				monstertable = {}
			end
			
			monstertable[#monstertable + 1] = v.TemplateId
		end
	end

	return monstertable	
end

--清空副本目标
def.method().ClearDungeonGoal = function(self)
	self._TableDungeonGoal = nil
end

--获得副本ID，如果是-1说明不在副本中
def.method("=>","number").GetDungeonID = function(self)
	return self._DungeonID 
end

--设置副本ID
def.method("number").SetDungeonID = function(self, nID)
	self._DungeonID = nID
end

--获取爬塔试炼副本信息（时间,层数）
def.method("=>","number","number").GetTowerDungeonData = function(self)
	return self._TowerBestPassTime, self._TowerDungeonFloor
end

def.method("number","=>","boolean").IsGoalTarget = function(self, nTID)
	local curGoal = self:GetDungeonGoal()
	if curGoal == nil then return false end

	return nTID == curGoal.TemplateId
end

--获得副本开启时间
def.method("number","=>","number").GetDungeonOpenByID = function(self,nDungeonID)
	return 0
end

--获取剩余次数
def.method("number","=>","number").GetRemainderCount = function(self, nDungeonID)
	local dungeonData = self:GetDungeonData(nDungeonID)
	if dungeonData == nil then return 0 end
	local dungeonTemplate = CElementData.GetTemplate("Instance", nDungeonID)
	if dungeonTemplate.CountGroupTid == 0 then 
		return 999
	else
		return dungeonData.RemainderTime
	end
end

--获取副本最大次数
def.method("number","=>","number").GetMaxRewardCount = function(self, nDungeonID)
	if nDungeonID <= 0 then return 0 end
	local dungeonTemplate = CElementData.GetTemplate("Instance", nDungeonID)
	if dungeonTemplate == nil then return 0 end
	
	return game._CCountGroupMan:OnCurMaxCount(dungeonTemplate.CountGroupTid)
end

-- 副本解锁
def.method("number").OnDungeonUnlock = function (self, tid)
	if tid <= 0 then return end

	local template = CElementData.GetTemplate("Instance", tid)
	if template == nil then return end

	local iType = template.InstanceType
	if iType == EInstanceType.INSTANCE_GILLIAM or				-- 奇利恩
	   iType == EInstanceType.INSTANCE_DRAGON or				-- 巨龙巢穴
	   iType == EInstanceType.INSTANCE_RUINS or					-- 遗迹普通
	   iType == EInstanceType.INSTANCE_RUINS_NIGHTMARE or		-- 遗迹噩梦
	   iType == EInstanceType.INSTANCE_EXPEDITION then 			-- 远征 
		self:SaveUIFxStatusToUserData(tid, true)
	end

	local  DungeonUnlockEvent = require "Events.DungeonUnlockEvent"
	local event = DungeonUnlockEvent()
	event._UnlockTid = tid
	CGame.EventManager:raiseEvent(nil, event) 
end

-- 保存解锁特效的播放状态到本地
def.method("number", "boolean").SaveUIFxStatusToUserData = function (self, tid, status)
	if tid <= 0 then return end

	local account = game._NetMan._UserName
	local UserData = require "Data.UserData"
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account)
	if accountInfo == nil then
		accountInfo = {}
	end
	local serverName = game._NetMan._ServerName
	if accountInfo[serverName] == nil then
		accountInfo[serverName] = {}
	end
	local roleId = game._HostPlayer._ID
	if accountInfo[serverName][roleId] == nil then
		accountInfo[serverName][roleId] = {}
	end
	local dungeonMap = accountInfo[serverName][roleId]["Dungeon"]
	if dungeonMap == nil then
		dungeonMap = {}
	end
	dungeonMap[tid] = status
	accountInfo[serverName][roleId]["Dungeon"] = dungeonMap

	UserData.Instance():SetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account, accountInfo)
end

-- 获取解锁特效是否需要播放
def.method("number", "=>", "boolean").IsUIFxNeedToPlay = function (self, tid)
	if tid <= 0 then return false end

	local account = game._NetMan._UserName
	local UserData = require "Data.UserData"
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account)
	if accountInfo ~= nil then
		local serverInfo = accountInfo[game._NetMan._ServerName]
		if serverInfo ~= nil then
			local roleInfo = serverInfo[game._HostPlayer._ID]
			if roleInfo ~= nil then
				local dungeonMap = roleInfo["Dungeon"]
				if dungeonMap ~= nil then
					local status = dungeonMap[tid]
					-- 状态被获取之后，删除对应本地记录
					if status ~= nil then
						dungeonMap[tid] = nil
						UserData.Instance():SetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account, accountInfo)
					end
					return status == true
				end
			end
		end
	end
	return false
end

--------------------------快捷匹配 逻辑块 Begin-------------------------

-- 开启便捷匹配 S2C同步  副本目标
def.method("number").StartQuickMatch = function(self, targetId)
	self:SetQuickMatchTargetId(targetId)
	local dungeonId = CTeamMan.Instance():ExchangeToDungeonId(self._QuickMatchTargetId)
	local dungeonTemplate = CElementData.GetInstanceTemplate(dungeonId)
	if dungeonTemplate then
		CPVPAutoMatch.Instance():InitMatchFunctionText(dungeonTemplate.TextDisplayName)
	end

	CPVPAutoMatch.Instance():Start(EnumDef.AutoMatchType.QuickMatch, nil, nil)
end

-- 关闭快捷匹配 S2C同步
def.method().StopQuickMatch = function(self)
-- warn("StopQuickMatch::关闭快捷匹配")
	CPVPAutoMatch.Instance():Stop()
	self:SetQuickMatchTargetId(0)
end

--------------------------快捷匹配 逻辑块 End--------------------------
--------------------------C2S--------------------------------
--[[
--快速匹配
def.method("number").QuickMatch = function(self,nInstanceID)
	local protocol = (require "PB.net".C2SQuickMatch)()
    protocol.reqQuickMatch.InstanceId = nInstanceID
    PBHelper.Send(protocol)
    self._QuickMatchID = nInstanceID
end
]]

-- 快捷匹配，开始，关闭
def.method("number", "boolean").SendC2SQuickMatchState = function (self, targetId, bState)
	local C2SQuickMatchState = require "PB.net".C2SQuickMatchState
	local protocol = C2SQuickMatchState()

	protocol.targetId = targetId
	protocol.bState = bState

	SendProtocol(protocol)
end

-- 快捷匹配成功后,确认和取消
def.method("number", "boolean").SendC2SQuickMatchConfirm = function (self, roomId, bConfirm)
	local C2SQuickMatchConfirm = require "PB.net".C2SQuickMatchConfirm
	local protocol = C2SQuickMatchConfirm()

	-- protocol.roomId = roomId
	protocol.bConfirm = bConfirm

	SendProtocol(protocol)
end

--进副本
def.method("number").TryEnterDungeon = function(self,nInstanceID)
 	local protocol = (require "PB.net".C2SEnterInstance)()
    protocol.reqEnterInstance.InstanceId = nInstanceID
    PBHelper.Send(protocol)
    
    local mapTemplate = CElementData.GetMapTemplate(nInstanceID)
	if mapTemplate == nil then return end

	local hp = game._HostPlayer
	if mapTemplate.AutoFightType == 0 then  -- 任务目标
		--do noting
	elseif mapTemplate.AutoFightType == 1 then	-- 副本目标
		CQuestAutoMan.Instance():Stop()
		CDungeonAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()
		hp:StopAutoTrans()
	elseif mapTemplate.AutoFightType == 2 then  -- 无目标
		CQuestAutoMan.Instance():Stop()
		CDungeonAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()
		hp:StopAutoTrans()
	end
end

def.method("table").OnEnterDungeon = function(self, msg)
	local instanceTid = msg.dungeonTId
	self:SetMatchID(0)	
	self:SetDungeonID(instanceTid)
	-- game:LuaEnterDungeonGC()
	local str = "Enter_Dungeon_ID:"..msg.dungeonTId
	CPlatformSDKMan.Instance():SetBreakPoint(str)
end

def.method("table").OnDungeonStart = function(self, msg)
	local instanceTid = msg.resEnterStart.InstanceTId
	if self._DungeonID ~= instanceTid then
		warn("DungeonID has error", self._DungeonID, instanceTid)
		return
	end

	self:SetInstanceEndTime(msg.resEnterStart.EndTime)
	CPanelTracker.Instance():AddDungeonTime(msg.resEnterStart.EndTime, 1)

	-- 副本断线重连CG处理
	local restartCgId = 0
	if #msg.cgDatas == 1 then
		restartCgId = msg.cgDatas[1].cgId
	elseif #msg.cgDatas > 1 then
		warn("Dont support when #msg.cgDatas > 1")
		restartCgId = msg.cgDatas[1].cgId
	end

	if restartCgId > 0 then
		CGMan.PlayCG(restartCgId, nil, 1, false)
	end

	-- 新手副本的特殊处理
	-- 新手本中断线，CG不会重新播放，通过此接口关闭Loading
	if game:IsInBeginnerDungeon() and not _G.IsCGPlaying then
		game._GUIMan:Close("CPanelLoading")
	end
end

--退出副本
def.method().TryExitDungeon = function(self)
    local protocol = (require "PB.net".C2SLeaveInstance)()
    protocol.reqLeaveInstance.InstanceId = 0
    PBHelper.Send(protocol)
end

local function ClearDungeonShow(self)
	self._DungeonID = -1
	self._CurIntroductionTID = 0

	self:ClearDungeonGoal()
	
	--关闭副本目标UI
	CPanelTracker.Instance():OpenDungeonUI(false)

	-- 清空右上角副本伤害统计
	local CPanelMinimap = require "GUI.CPanelMinimap"
	CPanelMinimap.Instance():ClearDungeonInfo()
	-- 关闭副本弹出的界面
	game._GUIMan:Close("CPanelUIDungeonIntroduction")
	game._GUIMan:Close("CPanelUIFullScreenTips")
	-- 关闭副本通用进度条
	local CPanelMainChat = require "GUI.CPanelMainChat"
	CPanelMainChat.Instance():HideDungeonCommonBar()
end

def.method().OnLeaveDungeon = function(self)
	if self._DungeonID <= 0 then
		warn("self._DungeonID is invaild, DungeonID = ", self._DungeonID)
		return
	end
	-- game:LuaLeaveDungeonGC()
	local str = "Leave_Dungeon_ID:"..self._DungeonID
	CPlatformSDKMan.Instance():SetBreakPoint(str)
	local mapTemplate = CElementData.GetMapTemplate(self._DungeonID)
	if mapTemplate.AutoFightType == 0 then  -- 任务目标
		-- 不做处理，维持现状
	elseif mapTemplate.AutoFightType == 1 then	-- 副本目标
		CAutoFightMan.Instance():Stop()
		CQuestAutoMan.Instance():Stop()
		CDungeonAutoMan.Instance():Stop()
	elseif mapTemplate.AutoFightType == 2 then  -- 无目标
		CAutoFightMan.Instance():Stop()
		CQuestAutoMan.Instance():Stop()
		CDungeonAutoMan.Instance():Stop()
	end

	local CExteriorMan = require "Main.CExteriorMan"
	CExteriorMan.Instance():Quit() -- 退出外观

	ClearDungeonShow(self)
end

def.method().PassBossCameraAnimation = function(self)
	local EType = require "PB.data".EClickFlag 
    local C2SClickFlag = require "PB.net".C2SClickFlag
    local protocol = C2SClickFlag()
    protocol.flag = EType.EClickFlag_endCameraAnimation
    protocol.entityId = self._CameraAnimationEntityID
	PBHelper.Send(protocol)
end

def.method().GoalToQuestFollow = function(self)
	local CQuest = require "Quest.CQuest"
	CQuest.Instance():QuestFollow(true,-1)
end

--请求远征数据
def.method().SendAskExpeditionData = function(self)
	local C2SExpedition = require "PB.net".C2SExpedition
	local Etype = require"PB.net".C2SExpedition.EExpeditionType
	local msg = C2SExpedition()
	msg.optType = Etype.EExpeditionType_getInfo
	
	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(msg)				
end
---------------------------------------S2C----------------------------------------------
--添加副本目标
def.method("table").AddDungeonGoal = function(self, data)
	self._TableDungeonGoal = {}

	for _,v in ipairs(data.Goals) do
		self._TableDungeonGoal[#self._TableDungeonGoal + 1 ] = 
			{
				SequenceId = data.Id,
				GoalType = v.GoalType,
				Id = v.Id,
				TemplateId = v.TemplateId,
				MaxCount = v.MaxCount,
				CurCount = v.CurCount,
				Description = v.Description,
				Param = v.Param,
				TextID = v.DescriptionTextId	,
				CreatTime = v.CreatTime,
			}
	end
	local str = " Dungeon_ID:" ..self._DungeonID .."__DungeonGoal_ID:" ..self._TableDungeonGoal[#self._TableDungeonGoal].SequenceId
	CPlatformSDKMan.Instance():SetBreakPoint(str)
	
	local instance = CElementData.GetTemplate("Instance", self._DungeonID)
	if instance ~= nil and (instance.InstanceType == EInstanceType.INSTANCE_NORMAL_MAP or instance.InstanceType == EInstanceType.INSTANCE_GUILDBASE ) then
		--初始化任务追踪界面
		local CPageQuest = require "GUI.CPageQuest"
		CPageQuest.Instance():AddSpecialDungeonGoal(self._TableDungeonGoal)

	else
		--打开副本目标UI
		CPanelTracker.Instance():OpenDungeonUI(true)
	end	
end

--改变副本目标
def.method("number","number").ChangeDungeonGoal = function(self,nID,nCur)
	if self._TableDungeonGoal == nil or #self._TableDungeonGoal < 0 then return end

	local nIndex = 1
	for i,v in ipairs(self._TableDungeonGoal) do
		if(v.Id == nID)then
			v.CurCount = nCur
			nIndex = i 
			break
		end
	end
	
	--刷新副本计数
	local instance = CElementData.GetTemplate("Instance", self._DungeonID)
	if instance ~= nil and (instance.InstanceType == EInstanceType.INSTANCE_NORMAL_MAP or instance.InstanceType == EInstanceType.INSTANCE_GUILDBASE ) then
		--初始化任务追踪界面
		local CPageQuest = require "GUI.CPageQuest"
		CPageQuest.Instance():UpdateSpecialDungeonGoal(nIndex)

	else
		CPanelTracker.Instance():UpdateDungeonGoalPanel(nIndex)
	end	
end

--副本全部完成
def.method().ReachAll = function(self)
	local CPageQuest = require "GUI.CPageQuest"
	CPageQuest.Instance():RemoveSpecialDungeonGoal()
end

-- 设置远征数据
def.method("table").SetExpetionData = function(self, serverInfo)
	self._CurExpeditionChapter = serverInfo.currChapter
	self._ExpeditionResetTime = serverInfo.restTimeSeconds

	-- self._TableExpeditionAffixs = {}
	-- for _, tid in ipairs(serverInfo.affixs) do
	-- 	table.insert(self._TableExpeditionAffixs, tid)
	-- end

	self._TableExpeditionChapterData = {}
	for _, chapterData in ipairs(serverInfo.chapterDatas) do
		table.insert(self._TableExpeditionChapterData, chapterData)
	end
end

---------------------------------------------------------------------------------------
def.method("=>","number").GetQuickMatchTargetId = function(self)
	return self._QuickMatchTargetId
end

def.method("number").SetQuickMatchTargetId = function(self, quickMatchTargetId)
	self._QuickMatchTargetId = quickMatchTargetId
end

def.method("=>", "boolean").IsQuickMatching = function(self)
	return self._QuickMatchTargetId > 0
end

--设置爬塔层数
def.method("number", "number").SetTowerFloorAndTime = function(self ,nFloor, nTime)
	self._TowerDungeonFloor = nFloor
	self._TowerBestPassTime = nTime
end

def.method("=>","number").GetMatchID = function(self)
	return self._QuickMatchID
end

def.method("number").SetMatchID = function(self, nInstanceID)
	self._QuickMatchID = nInstanceID
end

-- 3V3匹配时间计时器管理
def.method("number").MatchingTime3V3Man = function (self,startTime)
	self._3V3MatchingStartTime = GameUtil.GetServerTime()/1000 - startTime
end

def.method().Close3V3Matching = function(self)
	game._CArenaMan._IsMatching3V3 = false
end

--3v3禁止时间管理器
def.method("number").BanMatchingTime3V3Man = function (self,startTime)
	self._3V3BanEndTime = GameUtil.GetServerTime()/1000 + startTime
end

-- 无畏战场禁止时间管理器
def.method("number").BanMatchingTimeBattleMan = function (self,startTime)
	self._BattleBanEndTime = GameUtil.GetServerTime()/1000 + startTime
end

def.method().Close3V3Ban= function(self)
	game._CArenaMan._IsBanMatching3V3 = false
end

-- 无畏战场匹配时间计时器管理
def.method("number").MatchingTimeBattleMan = function (self,startTime)
	self._BattleMatchingStartTime = GameUtil.GetServerTime()/1000 - startTime
end

def.method().CloseBattleMatching = function(self)
	game._CArenaMan._IsMatchingBattle = false
end

def.method().FinishTriggerCameraAnimation = function(self)
	if self._CameraAnimationEntityID == 0 then return end

	game._GUIMan:Close("CPanelUIFullScreenTips")

	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
	GameUtil.SetCamToDefault(true, true, false, true)

	game:SetTopPateVisible(true)
	game._GUIMan:SetMainUIMoveToHide(false, nil)
	self._CameraAnimationEntityID = 0

	-- 重启战斗
	CDungeonAutoMan.Instance():Restart(_G.PauseMask.BossEnterAnim)
	CAutoFightMan.Instance():Restart(_G.PauseMask.BossEnterAnim)
	CPath.Instance():ReStartPathDungeon()

	if not IsNil(self._CameraAnimationPrafab) then
		self._CameraAnimationPrafab:Destroy()
		self._CameraAnimationPrafab = nil
	end

	if self._BossAnimationTimer ~= 0 then
		_G.RemoveGlobalTimer(self._BossAnimationTimer)
		self._BossAnimationTimer = 0
	end
end

--触发副本镜头动画 通过EneityID 找坐标的方法
def.method("number","string","boolean").TriggerCameraAnimation = function(self, nEnityID, strAniName, isImmediatelyFinish)
	local strCamAnimationPath = "Assets/Outputs/CGAnimator/"..strAniName
	local animationEntity = game._CurWorld:FindObject(nEnityID) 
	if animationEntity == nil then 
		warn("Error:  <CameraAnimation>----> BOSS is nil. EntityId:",nEnityID)	
		return
	end

	self._CameraAnimationEntityID = nEnityID
	game._HostPlayer:StopNaviCal()
	CAutoFightMan.Instance():Pause(_G.PauseMask.BossEnterAnim)
	CDungeonAutoMan.Instance():Pause(_G.PauseMask.BossEnterAnim)
	CPath.Instance():PausePathDungeon()

	local function cb(prefab)
		if self._CameraAnimationEntityID == 0 then
			return
		end

		if IsNil(prefab) then
			warn("Error: <CameraAnimation>----> AnimationPrefab is nil")
			-- self:FinishTriggerCameraAnimation()
			return
		end
		animationEntity:AddLoadedCallback(function(nTID)
			if self._CameraAnimationEntityID == 0 then
				return
			end
			
			-- StartScreenFade(0, 1, 0.5,function( )
				game._GUIMan:SetMainUIMoveToHide(true, nil)
			-- end)

			local uiData =
			{
				Type = 1,
				BossTitle = animationEntity:GetTitle(),
				BossName = animationEntity._InfoData._Name
			}
			game._GUIMan:Open("CPanelUIFullScreenTips", uiData)
			game:SetTopPateVisible(false)

			local pos = animationEntity:GetPos()
			local bossRotaion = animationEntity: GetGameObject().forward
			local temScale = Vector3.one
			if animationEntity:IsMonster() then
				temScale = Vector3.one * animationEntity._MonsterTemplate.BodyScale
			end
			self._CameraAnimationPrafab = Object.Instantiate(prefab)
			self._CameraAnimationPrafab.position = pos
			self._CameraAnimationPrafab.forward = bossRotaion
			self._CameraAnimationPrafab.localScale = temScale

			local aniPrefab = self._CameraAnimationPrafab:GetChild(0)
			local parentObj = aniPrefab:FindChild("CamPos")
			if IsNil(parentObj) then
				warn("Error:  <BOSSEnterMapAnimation>----> CamPos is nil")
				parentObj = self._CameraAnimationPrafab
			end 

			GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.BOSS, parentObj, 0, nil)

			local camAnimation = aniPrefab:GetComponent(ClassType.Animation)
			camAnimation:Play()

			if self._BossAnimationTimer ~= 0 then
				_G.RemoveGlobalTimer(self._BossAnimationTimer)
				self._BossAnimationTimer = 0
			end
			local function ClearAnimation()
				if self._BossAnimationTimer == 0 then return end

				if isImmediatelyFinish then
					-- 相机立即回正
					self:FinishTriggerCameraAnimation()
				else
					GameUtil.StartBossCamMove(function ()
						self:FinishTriggerCameraAnimation()
					end)
				end
			end
			local animationTime = camAnimation.clip.length
			self._BossAnimationTimer = _G.AddGlobalTimer(animationTime, true, ClearAnimation)	
		end)
	end
	GameUtil.AsyncLoad(strCamAnimationPath, cb)	
end

--BOSS入场处理
--@param camType 0:缓慢回正 1:立刻回正 2:闪避教学（新手本）
def.method("number","string","number").BOSSEnterAnimation = function(self, nEnityID, strAniName, camType)
	if game:IsInBeginnerDungeon() then
		-- 新手副本
		CBeginnerDungeonMan.Instance():TriggerBossEnterAnimation(nEnityID, strAniName, camType)
	else
		local isImmediatelyFinish = false
		if camType == 1 then
			-- 传 1 代表结束后相机立即回正
			isImmediatelyFinish = true
		end
		self:TriggerCameraAnimation(nEnityID, strAniName, isImmediatelyFinish)
	end
end

--BOSS入场完毕，重置状态
def.method().FinishBOSSEnterAnimation = function(self)
	if game:IsInBeginnerDungeon() then
		-- 新手副本
		CBeginnerDungeonMan.Instance():FinishCameraAnimation()
	else
		self:FinishTriggerCameraAnimation()
	end
end

--获得1V1场景ID
def.method("=>","number").Get1v1WorldTID =function(self)
	return self._JJC1V1WorldTID
end

--获得3V3场景ID
def.method("=>","number").Get3V3WorldTID = function(self)
	return self._JJC3V3WorldTID
end

-- 获得无畏战场场景ID 
def.method("=>","number").GetEliminateWorldTID = function(self)
	return self._EliminateWorldID
end

--获取远征当前章节
def.method("=>", "number").GetCurExpeditionChapter = function(self)
	return self._CurExpeditionChapter
end

--获取远征章节数据
def.method("=>", "table").GetExpeditionChapterData = function(self)
	return self._TableExpeditionChapterData
end

def.method("table").SetExpeditionAffixs = function (self, affixs)
	self._TableExpeditionAffixs = {}
	for _, id in ipairs(affixs) do
		table.insert(self._TableExpeditionAffixs, id)
	end
end

--获取远征Boss词缀
def.method("=>", "table").GetExpeditionAffixs = function(self)
	return self._TableExpeditionAffixs
end

--获取远征重置时间
def.method("=>", "number").GetExpeditionResetTime = function(self)
	return self._ExpeditionResetTime
end

--远征章节是否解锁
def.method("number", "=>", "boolean").IsChapterUnlock = function(self, id)
	local isUnlock = false
	if id > 0 then
		for _, chapterData in ipairs(self._TableExpeditionChapterData) do
			if chapterData.Id == id then
				local EExpeditionChapterState = require "PB.data".EExpeditionChapterState
				isUnlock = chapterData.chapterState ~= EExpeditionChapterState.EExpeditionChapterState_LevelLock
				break
			end
		end
	end
	return isUnlock
end

-- 设置副本倒计时时间 
def.method("number").SetInstanceEndTime = function(self,endTime)
	self._InstanceEndTime = endTime
end

def.method("=>","number").GetInstanceEndTime = function (self )
	return self._InstanceEndTime
end

def.method().ClearExpeditionData = function(self)
	self._CurExpeditionChapter = 0
	self._ExpeditionResetTime = 0
	self._TableExpeditionAffixs = {}
	self._TableExpeditionChapterData = {}
end

def.method("number").SetCurIntroductionPopupTID = function(self, tid)
	self._CurIntroductionTID = tid
end

def.method("=>", "number").GetCurIntroductionPopupTID = function(self)
	return self._CurIntroductionTID
end

def.method().Release = function(self)
	CBeginnerDungeonMan.Instance():Release()

	self._TableDungeonData = nil
	self._TableDungeonGoal = nil
	ClearDungeonShow(self)
	self:Close3V3Ban()
	self:Close3V3Matching()
	self:ClearExpeditionData()
	self._CameraAnimationEntityID = 0
end

CDungeonMan.Commit()
return CDungeonMan