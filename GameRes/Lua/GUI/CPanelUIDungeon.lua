--[[-----------------------------------------
    	综合副本界面
      		 ——by luee. 2017.7.26
 --------------------------------------------
]]
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIDungeon = Lplus.Extend(CPanelBase, 'CPanelUIDungeon')
local def = CPanelUIDungeon.define

local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CPageTowerDungeon = require "GUI.CPageTowerDungeon"
local CPageGilliam = require "GUI.CPageGilliam"
local CPageNormalDungeon = require "GUI.CPageNormalDungeon"
local CPageNightmareDungeon = require "GUI.CPageNightmareDungeon"
local CPageDragonNest = require "GUI.CPageDragonNest"
local CTeamMan = require "Team.CTeamMan"
local EAssistType = require "PB.Template".Instance.EAssistType
local EInstanceType = require "PB.Template".Instance.EInstanceType
local EInstanceDifficultyMode = require "PB.Template".Instance.EInstanceDifficultyMode
local EEnterCountDeductionType = require "PB.Template".Instance.EEnterCountDeductionType
local CQuest = require "Quest.CQuest"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local DungeonUnlockEvent = require "Events.DungeonUnlockEvent"
local CountGroupUpdateEvent = require "Events.CountGroupUpdateEvent"
local QuickMatchStateEvent = require "Events.QuickMatchStateEvent"


-- 所有界面通用
def.field(CFrameCurrency)._Frame_Money = nil
def.field("table")._FrameTable = BlankTable
def.field("userdata")._Lab_PanelTitle = nil
def.field("userdata")._Img_Line = nil
def.field("userdata")._Lab_DgnName = nil
def.field("userdata")._Lab_DgnMode = nil
def.field("userdata")._Lab_DgnDes = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._View_Reward = nil
def.field("userdata")._List_Reward = nil
def.field("userdata")._Lab_PlayDescription = nil
def.field("userdata")._Lab_NumLimit = nil
def.field("userdata")._Lab_LevelLimit = nil
def.field("userdata")._Lab_PropertyLimit = nil
def.field("userdata")._Lab_CurProperty = nil
def.field("userdata")._Lab_EnterTimeTitle = nil
def.field("userdata")._Lab_EnterTimeVal = nil
def.field("userdata")._Btn_Buy = nil
def.field("userdata")._Frame_Assist = nil
def.field("userdata")._IOSToggle_Assist = nil
def.field("userdata")._UITemplate_Assist = nil
def.field("userdata")._Frame_CantAssist = nil
def.field("userdata")._Btn_QuickJoin = nil
def.field("userdata")._Img_QuickJoin = nil
def.field("userdata")._Lab_QuickJoin = nil 				-- 前往组队 or 快速匹配
def.field("userdata")._Btn_Enter = nil
def.field("userdata")._Img_Enter = nil
-- 遗迹普通和遗迹噩梦用
def.field("userdata")._Frame_DungeonList = nil
def.field("userdata")._View_Dungeon = nil
def.field("userdata")._List_Dungeon = nil
-- 巨龙和奇利恩用
def.field("userdata")._Frame_Difficulty = nil
def.field("userdata")._RdoGroup_Difficulty = nil
def.field("table")._RdoTable_Difficulty = BlankTable
def.field("userdata")._Img_DragonNestBoss = nil
def.field("userdata")._Img_GilliamBoss = nil
-- 风暴试炼用
def.field("userdata")._Frame_TowerPassTime = nil
def.field("userdata")._Frame_TowerContent = nil

def.field("dynamic")._CurPageClass = nil				-- 当前页的类
def.field("table")._DungeonsTable = BlankTable			-- 所有副本的表
def.field("table")._PageTitleStrMap = BlankTable -- 各个页签的左上角标题字符串
def.field("number")._CurDungeonPage = 0 -- 当前页
def.field("number")._UISfxDuration = 1 -- 特效播放时间
def.field("boolean")._IsOpenAssist = true -- 是否开启助战

def.field("number")._FightScoreUpperLimitRate = 0 		-- 战力对比上限百分比
def.field("number")._FightScoreLowerLimitRate = 0 		-- 战力对比下限百分比

def.field("number")._GuideAssistQuestId = 0
def.field("number")._GuideAssistDungeonId = 0

local DungeonPage = 
{
	_NormalDungeon		= 1, -- 普通遗迹
	_NightmareDungeon	= 2, -- 噩梦遗迹
	_TowerDungeon		= 3, -- 试炼
	_DragonLair			= 4, -- 巨龙巢穴
	_Gilliam			= 5, -- 奇利恩
}

local ColorHexFormat =
{
	Green = "<color=#7BDC1C>%s</color>",
	Yellow = "<color=#FFF4AD>%s</color>",
	Red = "<color=#E2260C>%s</color>"
}

local function GetDifficultyText(mode)
	local str = "UnknownDifficulty"
	local difficulty2color =
	{
		[EInstanceDifficultyMode.NORMAL] = "<color=#5CBE37>%s</color>",		-- 绿色
		[EInstanceDifficultyMode.DIFFICULT] = "<color=#3990DA>%s</color>",	-- 蓝色
		[EInstanceDifficultyMode.NIGHTMARE] = "<color=#A436D7>%s</color>",	-- 紫色
		[EInstanceDifficultyMode.HELL] = "<color=#D78236>%s</color>",		-- 金色
		[EInstanceDifficultyMode.PURGATORY] = "<color=#DB2E1C>%s</color>"	-- 橙红
	}
	if difficulty2color[mode] ~= nil then
		str = string.format(difficulty2color[mode], StringTable.Get(960 + mode))
	end
	return str
end

local instance = nil
def.static('=>', CPanelUIDungeon).Instance = function ()
	if not instance then
		instance = CPanelUIDungeon()
		instance._PrefabPath = PATH.UI_Dungeon
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	for _, v in pairs(DungeonPage) do
		-- 页面内容
		local frameObj = nil
		if v == DungeonPage._NormalDungeon then
			frameObj = self:GetUIObject("Frame_NormalRuin")
		elseif v == DungeonPage._NightmareDungeon then
			frameObj = self:GetUIObject("Frame_NightmareRuin")
		elseif v == DungeonPage._TowerDungeon then
			frameObj = self:GetUIObject("Frame_Tower")
		elseif v == DungeonPage._DragonLair then
			frameObj = self:GetUIObject("Frame_DragonNest")
		elseif v == DungeonPage._Gilliam then
			frameObj = self:GetUIObject("Frame_Gilliam")
		end
		if not IsNil(frameObj) then
			frameObj:SetActive(false)
			self._FrameTable[v] = frameObj
		end
	end
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
	self._Lab_PanelTitle = self:GetUIObject("Lab_PanelTitle")
	self._Img_Line = self:GetUIObject("Img_Line")
	self._Lab_DgnName = self:GetUIObject("Lab_DgnName")
	self._Lab_DgnMode = self:GetUIObject("Lab_DgnMode")
	self._Lab_DgnDes = self:GetUIObject("Lab_DgnDes")
	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
	self._Lab_PlayDescription = self:GetUIObject("Lab_PlayDescription")
	self._Lab_NumLimit = self:GetUIObject("Lab_NumLimit")
	self._Lab_LevelLimit = self:GetUIObject("Lab_LevelLimit")
	self._Lab_PropertyLimit = self:GetUIObject("Lab_PropertyLimit")
	self._Lab_CurProperty = self:GetUIObject("Lab_CurProperty")
	self._Lab_EnterTimeTitle = self:GetUIObject("Lab_Title4")
	self._Lab_EnterTimeVal = self:GetUIObject("Lab_EnterTime")
	self._Btn_Buy = self:GetUIObject("Btn_Buy")
	self._Frame_Assist = self:GetUIObject("Frame_Assist")
	local obj_toggle_assist = self:GetUIObject("IOSToggle_Assist")
	GameUtil.RegisterUIEventHandler(self._Panel, obj_toggle_assist, ClassType.GNewIOSToggle) -- 注册点击事件 
	self._IOSToggle_Assist = obj_toggle_assist:GetComponent(ClassType.GNewIOSToggle)
	self._UITemplate_Assist = obj_toggle_assist:GetComponent(ClassType.UITemplate)
	self._Frame_CantAssist = self:GetUIObject("Frame_CantAssist")
	self._Btn_QuickJoin = self:GetUIObject("Btn_QuickJoin")
	self._Img_QuickJoin = self:GetUIObject("Img_QuickJoinBG")
	self._Img_QuickJoin:FindChild("Img_BtnFloatFx"):SetActive(false)
	self._Btn_Enter = self:GetUIObject("Btn_Enter")
	self._Img_Enter = self:GetUIObject("Img_EnterBG")
	self._Img_Enter:FindChild("Img_BtnFloatFx"):SetActive(false)
	self._Frame_DungeonList = self:GetUIObject("Frame_DungeonList")
	self._View_Dungeon = self:GetUIObject("View_Dungeon")
	self._List_Dungeon = self:GetUIObject("List_Dungeon"):GetComponent(ClassType.GNewList)
	self._Frame_Difficulty = self:GetUIObject("Frame_Difficulty")
	self._RdoGroup_Difficulty = self:GetUIObject("RdoGroup_Difficulty")
	self._Lab_QuickJoin = self:GetUIObject("Lab_QuickJoin")
	self._Img_GilliamBoss = self:GetUIObject("Img_GilliamBoss")
	self._Img_DragonNestBoss = self:GetUIObject("Img_DragonNestBoss")
	self._Frame_TowerPassTime = self:GetUIObject("Frame_TowerPassTime")
	self._Frame_TowerContent = self:GetUIObject("Frame_TowerContent")

	self._RdoTable_Difficulty =
	{
		[EInstanceDifficultyMode.NORMAL] = self:GetUIObject("Rdo_Normal"),
		[EInstanceDifficultyMode.DIFFICULT] = self:GetUIObject("Rdo_Difficult"),
		[EInstanceDifficultyMode.NIGHTMARE] = self:GetUIObject("Rdo_Nightmare"),
		[EInstanceDifficultyMode.HELL] = self:GetUIObject("Rdo_Hell"),
		[EInstanceDifficultyMode.PURGATORY] = self:GetUIObject("Rdo_Purgatory"),
	}
	-- 页签类
	-- self._NormalDungeonPage = CPageNormalDungeon.new(self)
	-- self._NightmareDungeonPage = CPageNightmareDungeon.new(self)
	-- self._TowerDungeonPage = CPageTowerDungeon.new(self)
	-- self._GilliamPage = CPageGilliam.new(self)
	-- self._DragonNestPage = CPageDragonNest.new(self)
	-- self._DungeonsTable =
	-- {
	-- 	[DungeonPage._NormalDungeon] = self._NormalDungeonPage,
	-- 	[DungeonPage._NightmareDungeon] = self._NightmareDungeonPage,
	-- 	[DungeonPage._TowerDungeon] = self._TowerDungeonPage,
	-- 	[DungeonPage._Gilliam] = self._GilliamPage,
	-- 	[DungeonPage._DragonLair] =  self._DragonNestPage,
	-- }
	self._DungeonsTable = {}

	self._PageTitleStrMap =
	{
		[DungeonPage._NormalDungeon] = StringTable.Get(918),
		[DungeonPage._NightmareDungeon] = StringTable.Get(919),
		[DungeonPage._TowerDungeon] = StringTable.Get(920),
		[DungeonPage._Gilliam] = StringTable.Get(922),
		[DungeonPage._DragonLair] = StringTable.Get(921),
	}
	self._CurPageClass = nil
	self._CurDungeonPage = 0

	local CSpecialIdMan = require "Data.CSpecialIdMan"
	local compareRange = string.split(CSpecialIdMan.Get("DungeonFightScoreCompareRange"), "*")
	if compareRange[1] ~= nil then
		self._FightScoreLowerLimitRate = tonumber(compareRange[1]) / 100
	end
	if compareRange[2] ~= nil then
		self._FightScoreUpperLimitRate = tonumber(compareRange[2]) / 100
	end
	self._GuideAssistDungeonId = CSpecialIdMan.Get("GuideAssistDungeonId")
	self._GuideAssistQuestId = CSpecialIdMan.Get("GuideAssistQuestId")
end

-- 监听副本解锁事件
local function OnDungeonUnlockEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		local dungeonTid = event._UnlockTid
		instance:OnDungeonUnlock(dungeonTid)
		instance:UpdateInfoBtnStatus(dungeonTid)
	end
end

-- 监听购买次数组事件
local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		if instance._CurPageClass ~= nil then
			local dungeon_id = instance._CurPageClass:GetCurDungeonId()
			instance:UpdateInfoEnterTime(dungeon_id)
		end
	end
end

local function OnQuickMatchStateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateQuickJoinState()
	end
end

-- @param data 副本ID
def.override("dynamic").OnData = function(self, data)
	CPanelBase.OnData(self,data)
	local dungeonType = DungeonPage._NormalDungeon -- 默认开启副本页面
	self._DungeonsTable[DungeonPage._NormalDungeon] = CPageNormalDungeon.new(self)
	local uiData = data
	if type(data) == "number" then
		local template = CElementData.GetInstanceTemplate(data)
		if template ~= nil then
			local iType = template.InstanceType
			if iType == EInstanceType.INSTANCE_GILLIAM then
				-- 奇利恩
				dungeonType = DungeonPage._Gilliam
				uiData = template.InstanceDifficultyMode
				self._DungeonsTable[dungeonType] = CPageGilliam.new(self)
				self._HelpUrlType = HelpPageUrlType.CalendarMan_Tyburn
			elseif iType == EInstanceType.INSTANCE_TOWER then
				-- 试炼
				dungeonType = DungeonPage._TowerDungeon
				self._DungeonsTable[dungeonType] = CPageTowerDungeon.new(self)
				self._HelpUrlType = HelpPageUrlType.CalendarMan_Windstorm
			elseif iType == EInstanceType.INSTANCE_DRAGON then
				-- 巨龙巢穴
				dungeonType = DungeonPage._DragonLair
				uiData = template.InstanceDifficultyMode
				self._DungeonsTable[dungeonType] = CPageDragonNest.new(self)
				self._HelpUrlType = HelpPageUrlType.CalendarMan_Dragon
			elseif iType == EInstanceType.INSTANCE_RUINS then
				-- 遗迹普通
				-- dungeonType = DungeonPage._NormalDungeon
				-- self._DungeonsTable[dungeonType] = CPageNormalDungeon.new(self)
				self._HelpUrlType = HelpPageUrlType.CalendarMan_Relic_Nor
			elseif iType == EInstanceType.INSTANCE_RUINS_NIGHTMARE then
				-- 遗迹噩梦
				dungeonType = DungeonPage._NightmareDungeon
				self._DungeonsTable[dungeonType] = CPageNightmareDungeon.new(self)
				self._HelpUrlType = HelpPageUrlType.CalendarMan_Relic_Hard
			end
		end
	end
	self:ShowFrame(dungeonType, uiData)
	self:UpdateQuickJoinState()

	CGame.EventManager:addHandler("DungeonUnlockEvent", OnDungeonUnlockEvent)
	CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:addHandler("QuickMatchStateEvent", OnQuickMatchStateEvent)
end

def.method("number", "dynamic").ShowFrame = function (self, nType, uiData)
	if self._DungeonsTable[nType] == nil then
		self._CurPageClass = nil
		warn("CPanelUIDungeon ShowFrame get invalid dungeon type:", nType)
		return
	end

	-- 隐藏旧界面
	if self._CurPageClass ~= nil then
		self._CurPageClass:Hide()
	end
	self:HandleUIChange(nType)

	-- 奇利恩或巨龙巢穴
	local hasDifficulty = nType == DungeonPage._Gilliam or nType == DungeonPage._DragonLair
	self._Frame_Difficulty:SetActive(hasDifficulty)
	-- self._Img_GilliamBoss:SetActive(nType == DungeonPage._Gilliam)
	-- self._Img_DragonNestBoss:SetActive(nType == DungeonPage._DragonLair)
	-- 播放特效
	if nType == DungeonPage._Gilliam then
		GameUtil.PlayUISfx(PATH.UIFX_DungeonGilliam, self._Img_GilliamBoss, self._Img_GilliamBoss, -1)
	elseif nType == DungeonPage._DragonLair then
		GameUtil.PlayUISfx(PATH.UIFX_DungeonDragon, self._Img_DragonNestBoss, self._Img_DragonNestBoss, -1)
	end
	-- 2018/06/14 wuyou新需求：风暴试炼不显示次数组购买按钮。
	-- 2019/06/13 yangzonghan新需求：奇利恩不显示次数组购买按钮。
	GUITools.SetUIActive(self._Btn_Buy, nType ~= DungeonPage._TowerDungeon and nType ~= DungeonPage._Gilliam)

	self._Frame_TowerPassTime:SetActive(nType == DungeonPage._TowerDungeon)
	self._Frame_TowerContent:SetActive(nType == DungeonPage._TowerDungeon)

	-- 遗迹普通或遗迹噩梦
	local isRuin = nType == DungeonPage._NormalDungeon or nType == DungeonPage._NightmareDungeon
	self._Frame_DungeonList:SetActive(isRuin)
	GUITools.SetUIActive(self._Img_Line, isRuin)

	self._IsOpenAssist = true
	self._CurDungeonPage = nType
	self._CurPageClass = self._DungeonsTable[nType]
	self._CurPageClass:Show(uiData)
end

-- 处理界面变化
def.method("number").HandleUIChange = function (self, nType)
	local titleStr = self._PageTitleStrMap[nType] or ""
	GUI.SetText(self._Lab_PanelTitle, titleStr)

	local originFrame = self._FrameTable[self._CurDungeonPage]
	if not IsNil(originFrame) then
		originFrame:SetActive(false)
	end

	local targetFrame = self._FrameTable[nType]
	if not IsNil(targetFrame) then
		targetFrame:SetActive(true)
		if  nType == DungeonPage._NormalDungeon or
			nType == DungeonPage._NightmareDungeon or
			nType == DungeonPage._TowerDungeon then
			-- 播放背景特效
			GameUtil.PlayUISfx(PATH.UIFX_DungeonBG, targetFrame, targetFrame, -1)
		end
	end
end

------------------------------内部接口 start------------------------------
-- 显示副本信息
def.method("number").ShowDungeonInfo = function(self, dungeonTId)
	local dungeonTemp = CElementData.GetInstanceTemplate(dungeonTId)
	if dungeonTemp == nil then return end
	-- 副本名称
	GUI.SetText(self._Lab_DgnName, dungeonTemp.TextDisplayName)
	-- 难度
	if dungeonTemp.InstanceType == EInstanceType.INSTANCE_GILLIAM or
	   dungeonTemp.InstanceType == EInstanceType.INSTANCE_DRAGON then
		-- 巨龙或奇利恩
		GUITools.SetUIActive(self._Lab_DgnMode, true)
		GUI.SetText(self._Lab_DgnMode, GetDifficultyText(dungeonTemp.InstanceDifficultyMode))
	else
		-- 其他类型隐藏
		GUITools.SetUIActive(self._Lab_DgnMode, false)
	end
	-- 描述
	GUI.SetText(self._Lab_DgnDes, dungeonTemp.Description)
	-- 玩法类型描述
	GUI.SetText(self._Lab_PlayDescription, dungeonTemp.PlayTypeDescription)
	-- 准入人数
	local numStr = tostring(dungeonTemp.MinRoleNum)
	if dungeonTemp.MaxRoleNum > dungeonTemp.MinRoleNum then
		numStr = numStr .. " - " .. dungeonTemp.MaxRoleNum
	end
	GUI.SetText(self._Lab_NumLimit, numStr)
	-- 等级限制
	local levelStr = tostring(dungeonTemp.MinEnterLevel)
	if game._HostPlayer._InfoData._Level < dungeonTemp.MinEnterLevel then
		-- 等级不足变红
		levelStr = string.format(ColorHexFormat.Red, levelStr)
	end
	GUI.SetText(self._Lab_LevelLimit, levelStr)
	-- 推荐战力
	local recommendedFightScore = dungeonTemp.RecommendedFightScore -- 推荐战力
	GUI.SetText(self._Lab_PropertyLimit, GUITools.FormatNumber(recommendedFightScore, false, 7))
	local curFightScore = game._HostPlayer:GetHostFightScore() -- 当前战力
	local curFightScoreStr = GUITools.FormatNumber(curFightScore, false, 7)
	if curFightScore < recommendedFightScore * self._FightScoreLowerLimitRate then
		-- 低于下限，显示红色
		curFightScoreStr = string.format(ColorHexFormat.Red, curFightScoreStr)
	elseif curFightScore < recommendedFightScore * self._FightScoreUpperLimitRate then
		-- 高于下限，低于上限，显示黄色
		curFightScoreStr = string.format(ColorHexFormat.Yellow, curFightScoreStr)
	else
		-- 高于上限，显示绿色
		curFightScoreStr = string.format(ColorHexFormat.Green, curFightScoreStr)
	end
	GUI.SetText(self._Lab_CurProperty, curFightScoreStr)
	-- 次数标题
	-- if dungeonTemp.EnterCountDeductionType == EEnterCountDeductionType.EEnter then
	-- 	GUI.SetText(self._Lab_EnterTimeTitle, StringTable.Get(911))
	-- else
		GUI.SetText(self._Lab_EnterTimeTitle, StringTable.Get(912))
	-- end
	-- 好友助战
	local canAssist = dungeonTemp.AssistType ~= EAssistType.NotSupport
	GUITools.SetUIActive(self._Frame_Assist, canAssist)
	GUITools.SetUIActive(self._Frame_CantAssist, not canAssist)
	if canAssist then
		self:EnableAssist(self._IsOpenAssist)
	end
	
	self:UpdateInfoEnterTime(dungeonTId)
	self:UpdateInfoBtnStatus(dungeonTId)
	self:UpdateQuickJoinState()
end

-- 更新快速匹配状态
def.method().UpdateQuickJoinState = function(self)
	if not self:IsShow() then return end

	local dungeonTemp = CElementData.GetInstanceTemplate(self._CurPageClass:GetCurDungeonId())
	if dungeonTemp == nil then return end

	GUI.SetText(self._Lab_QuickJoin, StringTable.Get(dungeonTemp.IsQuickMatch and 935 or 934))
end

-- 设置奖励物品列表
def.method("table").SetRewardsList = function (self, rewardsData)
	if rewardsData == nil or #rewardsData < 1 then
		self._View_Reward:SetActive(false)
	else
		self._List_Reward:SetItemCount(#rewardsData)
		self._List_Reward:ScrollToStep(0) -- 默认回到顶部
		self._View_Reward:SetActive(true)
	end
end

-- 设置货币奖励
-- @param rewardsData 结构如下
--        Id:货币ID
--        Count:货币数量
def.method("table").SetMoneyRewards = function (self, rewardsData)
	local enable = false
	if rewardsData ~= nil and rewardsData[1] ~= nil then
		enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, rewardsData[1].Id)
		GUI.SetText(self._Lab_OtherReward_1, GUITools.FormatNumber(rewardsData[1].Count, true))
	end
	GUITools.SetUIActive(self._Frame_OtherReward_1, enable)

	enable = false
	if rewardsData ~= nil and rewardsData[2] ~= nil then
		enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, rewardsData[2].Id)
		GUI.SetText(self._Lab_OtherReward_2, GUITools.FormatNumber(rewardsData[2].Count, true))
	end
	GUITools.SetUIActive(self._Frame_OtherReward_2, enable)
end

-- 获取选择的副本难度
def.method("table", "number", "number", "=>", "number").GetDifficultyMode = function (self, dungeonInfo, originMode, desMode)
	if dungeonInfo == nil then return -1 end

	local selectedMode = -1
	-- 设置页签状态
	for _, mode in pairs(EInstanceDifficultyMode) do
		if type(mode) == "number" then
			local rdoObj = self._RdoTable_Difficulty[mode]
			if not IsNil(rdoObj) then
				local uiTemplate = rdoObj:GetComponent(ClassType.UITemplate)
				local info = dungeonInfo[mode]
				rdoObj:SetActive(info ~= nil)
				if info ~= nil and uiTemplate ~= nil then
					local dungeon_data = game._DungeonMan:GetDungeonData(info.Id)
					local template = CElementData.GetInstanceTemplate(info.Id)
					if dungeon_data ~= nil and template ~= nil then
						if desMode == template.InstanceDifficultyMode then
							-- 找到目标难度
							selectedMode = template.InstanceDifficultyMode
						end
						local isOpen = dungeon_data.IsOpen -- 是否解锁
						local img_icon_u = uiTemplate:GetControl(3)
						if not IsNil(img_icon_u) then
							GUITools.SetUIActive(img_icon_u, isOpen)
						end
						local img_icon_d = uiTemplate:GetControl(7)
						if not IsNil(img_icon_d) then
							GUITools.SetUIActive(img_icon_d, isOpen)
						end
						local frame_lock = uiTemplate:GetControl(8)
						if not IsNil(frame_lock) then
							GUITools.SetUIActive(frame_lock, not isOpen)
						end
						if game._DungeonMan:IsUIFxNeedToPlay(info.Id) then
							-- 需要播放特效
							local frame_sfx = uiTemplate:GetControl(9)
							if not IsNil(frame_sfx) then
								GameUtil.PlayUISfx(PATH.UIFX_CommonUnlock, frame_sfx, frame_sfx, -1)
							end
						end
					end
				end
			end
		end
	end

	if desMode == -1 or selectedMode == -1 then
		-- 找回原来选择的难度
		if originMode == -1 then
			-- 原来没有选择，默认选择最低难度
			selectedMode = EInstanceDifficultyMode.NORMAL
			for dm, _ in pairs(dungeonInfo) do
				if dm < selectedMode then
					selectedMode = dm
				end
			end
		else
			selectedMode = originMode
		end
	end

	if not IsNil(self._RdoTable_Difficulty[selectedMode]) then
		GUI.SetGroupToggleOn(self._RdoGroup_Difficulty, selectedMode + 1)
	end
	return selectedMode
end

-- 更新详细信息的按钮状态
def.method("number").UpdateInfoBtnStatus = function (self, tid)
	local data = game._DungeonMan:GetDungeonData(tid)
	local enable = false
	if data ~= nil and data.IsOpen then
		enable = true
	end
	self:SetInfoBtnEnable(enable)
end

-- 设置副本详细信息的按钮状态
def.method("boolean").SetInfoBtnEnable = function (self, enable)
	GUITools.SetUIActive(self._Btn_QuickJoin, enable)
	GUITools.SetUIActive(self._Btn_Enter, enable)
end

-- 更新进入次数
def.method("number").UpdateInfoEnterTime = function (self, tid)
	local dungeonTemplate = CElementData.GetInstanceTemplate(tid)
	if dungeonTemplate ~= nil then
		local countGroupTemplate = CElementData.GetTemplate("CountGroup", dungeonTemplate.CountGroupTid)
		if countGroupTemplate ~= nil then
			local remainderTime = game._DungeonMan:GetRemainderCount(tid)
			-- local maxTime = game._DungeonMan:GetMaxRewardCount(tid)
			local maxTime = countGroupTemplate.MaxCount
			local colorFormat = "%d"
			if remainderTime == 0 then
				-- 剩余次数为0时变红
				colorFormat = "<color=#DB2E1C>%d</color>"
			elseif remainderTime > maxTime then
				-- 剩余次数大于初始最大次数时变绿
				colorFormat = "<color=#5CBE37>%d</color>"
			end
			GUI.SetText(self._Lab_EnterTimeVal, string.format(colorFormat, remainderTime) .. "/" .. maxTime)
		end
	end
end

def.method("number").OnDungeonUnlock = function (self, unlockTid)
	if self._CurPageClass ~= nil then
		self._CurPageClass:UpdateLockStatus(unlockTid)
	end
end

def.method("number").PlayDiffcultyUnlockSfx = function (self, mode)
	local rdoObj = self._RdoTable_Difficulty[mode]
	if not IsNil(rdoObj) then
		local uiTemplate = rdoObj:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end

		local img_icon_u = uiTemplate:GetControl(3)
		if not IsNil(img_icon_u) then
			GUITools.SetUIActive(img_icon_u, true)
		end
		local img_icon_d = uiTemplate:GetControl(7)
		if not IsNil(img_icon_d) then
			GUITools.SetUIActive(img_icon_d, true)
		end
		local img_lock = uiTemplate:GetControl(8)
		if not IsNil(img_lock) then
			GUITools.SetUIActive(img_lock, false)
		end
		local frame_sfx = uiTemplate:GetControl(9)
		if not IsNil(frame_sfx) then
			GameUtil.PlayUISfx(PATH.UIFX_CommonUnlock, frame_sfx, frame_sfx, -1)
		end
	end
end

-- 设置遗迹副本列表
def.method("number", "number").SetRuinList = function (self, count, index)
	if count > 0 then
		GUITools.SetUIActive(self._View_Dungeon, true)
		self._List_Dungeon:SetItemCount(count)
		self._List_Dungeon:ScrollToStep(index-2)		--显示在第3个位置
		self._List_Dungeon:SetSelection(index)
	else
		GUITools.SetUIActive(self._View_Dungeon, false)
	end
end

def.method("number").SetRuinListSelection = function (self, index)
	self._List_Dungeon:SetSelection(index)
end

def.method("boolean").EnableAssist = function (self, enable)
	self._IsOpenAssist = enable
	self._IOSToggle_Assist.Value = enable

	local frame_open = self._UITemplate_Assist:GetControl(0)
	GUITools.SetUIActive(frame_open, enable)
	local frame_close = self._UITemplate_Assist:GetControl(1)
	GUITools.SetUIActive(frame_close, not enable)
	local img_circle = self._UITemplate_Assist:GetControl(2)
	GameUtil.MakeImageGray(img_circle, not enable)
end

def.method("number").OpenMatchingBoard = function(self, roomId)
	local panel_data = {}
	panel_data.TargetId = roomId
	game._GUIMan:Open("CPanelUITeamMatchingBoard", panel_data)
end

def.method().QuickJoinLogic = function(self)
	local dungeon_id = self._CurPageClass:GetCurDungeonId()
	local dungeonTemp = CElementData.GetInstanceTemplate(dungeon_id)
	if dungeonTemp == nil then return end

	-- if not game._DungeonMan:DungeonIsOpen(dungeon_id) then
	-- 	-- 等级不足
	-- 	game._GUIMan:ShowTipText(StringTable.Get(915), false)
	-- 	return
	-- end

	-- warn("dungeonTemp.IsQuickMatching = ", dungeonTemp.IsQuickMatch,
	-- 									   dungeonTemp.TextDisplayName,
	-- 									   dungeonTemp.Id)
	
	if dungeonTemp.IsQuickMatch then
		local roomId = CTeamMan.Instance():ExchangeToRoomId(dungeon_id)
		if roomId > 0 then
			local curMatchDungeonId = CTeamMan.Instance():ExchangeToDungeonId(game._DungeonMan:GetQuickMatchTargetId())
			-- 快捷匹配
			if curMatchDungeonId == dungeon_id then
			--[[
				-- 停止
				if curMatchDungeonId == dungeon_id then
					game._DungeonMan:SendC2SQuickMatchState(roomId, false)
				else
					--当前存在其他匹配,请取消后再试!
		        	game._GUIMan:ShowTipText(StringTable.Get(22400), false)
				end
			]]
				self:OpenMatchingBoard(roomId)
			else
				-- 开启规则
				if CTeamMan.Instance():InTeam() then
					if CTeamMan.Instance():IsTeamLeader() then
						if CTeamMan.Instance():GetMemberCount() > dungeonTemp.MaxRoleNum then
							-- 1. 队伍人数大于副本人数上限
							game._GUIMan:ShowTipText(string.format(StringTable.Get(937), dungeonTemp.MaxRoleNum), false)
						elseif CTeamMan.Instance():GetMemberCount() == dungeonTemp.MaxRoleNum then
							-- 2. 队伍人数 等于副本人数上限，直接进入副本逻辑
							self:EnterLogic()
						else
							-- 3. 队伍人数 小于副本人数上限，快捷匹配规则
							self:OpenMatchingBoard(roomId)
						end
					else
						game._GUIMan:ShowTipText(StringTable.Get(933), false)
					end
				else
					-- 4. 没有队伍 快捷匹配规则
					self:OpenMatchingBoard(roomId)
				end
			end
		else
			warn("Error: unknown RoomID", roomId, dungeon_id)
		end
	else
		if game._HostPlayer:InTeam() then
			game._GUIMan:ShowTipText(StringTable.Get(22018), false)
		else
			-- 进入对应的组队界面
			game._GUIMan:Open("CPanelUITeamCreate", {TargetId = dungeon_id})
		end
	end
end

def.method().EnterLogic = function(self)
	local dungeon_id = self._CurPageClass:GetCurDungeonId() -- 当前副本ID
	local dungeonTemp = CElementData.GetInstanceTemplate(dungeon_id)
	if dungeonTemp == nil then
		warn("CPanelUIDungeon EnterLogic failed, dungeon_id ", dungeon_id, " Template is nil")
		return
	end

	-- 特殊情况处理
	if self._GuideAssistDungeonId == dungeon_id and CQuest.Instance():IsQuestInProgress(self._GuideAssistQuestId) then
		-- 新手引导任务
		game._DungeonMan:TryEnterDungeon(dungeon_id)
		return
	end

	if CTeamMan.Instance():InTeam() then
		-- 队伍中
		if not CTeamMan.Instance():IsTeamLeader() then
			-- 非队长
			game._GUIMan:ShowTipText(StringTable.Get(933), false)
			return
		end
	end
	local remainderTime = game._DungeonMan:GetRemainderCount(dungeon_id) -- 副本剩余次数
	if remainderTime == 0 then
		-- 副本没有剩余次数
		local countGroupTemplate = CElementData.GetTemplate("CountGroup", dungeonTemp.CountGroupTid)
		if countGroupTemplate ~= nil then
			if countGroupTemplate.InitBuyCount > 0 then
				-- 属于可购买次数的副本
				-- local leftTime = game._CCountGroupMan:OnCurLaveCount(dungeonTemp.CountGroupTid) -- 剩余可购买次数
				-- if leftTime > 0 then
					-- 还可以购买
					game._CCountGroupMan:BuyCountGroupWhenEnter(dungeonTemp.CountGroupTid)
					return
				-- end
			end
		end
	end
	if dungeonTemp.AssistType == EAssistType.Friend and dungeonTemp.AssistSuggestionNumber > 1 and self._IsOpenAssist then
		-- 好友助战
		if (not CTeamMan.Instance():InTeam()) or 								-- 没有队伍
		   (CTeamMan.Instance():GetMemberCount() < dungeonTemp.AssistSuggestionNumber) then	-- 队伍人数不足
			game._GUIMan:Open("CPanelFriendFight", dungeon_id)
			return
		end
	end
	-- 其余情况，直接发协议，让服务器做判断
	game._DungeonMan:TryEnterDungeon(dungeon_id)
end
-------------------------------内部接口 end-------------------------------

def.override('string').OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if self._Frame_Money:OnClick(id) then return end
	
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Exit" then
		game._GUIMan:CloseSubPanelLayer()
	elseif id == "Btn_QuickJoin" then
		self:QuickJoinLogic()
	elseif id == "Btn_Enter" then
		self:EnterLogic()
	elseif id == "Btn_Buy" then
		-- warn("-----------lidaming Dungeon---------------", game._DungeonMan:GetRemainderCount(self._CurPageClass:GetCurDungeonId()))
		local dungeonTid = self._CurPageClass:GetCurDungeonId()
		local dungeonData = game._DungeonMan:GetDungeonData(dungeonTid)
		if dungeonData == nil then return end

		if not dungeonData.IsOpen then
			-- 未开启
			game._GUIMan:ShowTipText(StringTable.Get(954), false)
			return
		end

		local dungeonTemplate = CElementData.GetTemplate("Instance", dungeonTid)
		game._CCountGroupMan:BuyCountGroup(game._DungeonMan:GetRemainderCount(dungeonTid) ,dungeonTemplate.CountGroupTid)
	elseif id == "IOSToggle_Assist" then
		self:EnableAssist(not self._IsOpenAssist)
	else
		self._CurPageClass:OnPanelClick(id)
	end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
	CPanelBase.OnToggle(self, id, checked)
	self._CurPageClass:OnPanelToggle(id, checked)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_Reward") then
		-- 统一初始化奖励物品，模块的类必须有_RewardData
		local rewardsData = self._CurPageClass:GetDungeonRewardData()
		if rewardsData == nil then
			warn("Rewards data is null on init item in Page" .. self._CurDungeonPage)
			return
		end
		local reward = rewardsData[index+1]
		if reward ~= nil then
			local frame_icon = GUITools.GetChild(item, 0)
			if not IsNil(frame_icon) then
				local setting =
				{
					[EItemIconTag.Probability] = reward.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
				}
				IconTools.InitItemIconNew(frame_icon, reward.Data.Id, setting)
			end
		end
	else
		self._CurPageClass:OnPanelInitItem(item, id, index)
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if string.find(id, "List_Reward") then
		-- 奖励列表
		local rewardsData = self._CurPageClass:GetDungeonRewardData()
		if rewardsData == nil then
			warn("Rewards data is null on select item in Page" .. self._CurDungeonPage)
			return
		end
		local reward = rewardsData[index + 1]
		if not reward.IsTokenMoney then
			CItemTipMan.ShowItemTips(reward.Data.Id, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
		else
			local panelData = {
				_MoneyID = reward.Data.Id,
				_TipPos = TipPosition.FIX_POSITION,
				_TargetObj = item,
			}
			CItemTipMan.ShowMoneyTips(panelData)
		end
	else
		self._CurPageClass:OnPanelSelectItem(item, id, index)
	end
end

def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler("DungeonUnlockEvent", OnDungeonUnlockEvent)
	CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:removeHandler("QuickMatchStateEvent", OnQuickMatchStateEvent)

	for _, v in pairs(self._DungeonsTable) do
		v:Destroy()
		v = nil
	end
	self._CurPageClass = nil
	self._DungeonsTable = {}

	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	self._RdoTable_Difficulty ={}
	self._Lab_PanelTitle = nil
	self._Img_Line = nil
	self._Lab_DgnName = nil
	self._Lab_DgnMode = nil
	self._Lab_DgnDes = nil
	self._Frame_OtherReward_1 = nil
	self._Img_OtherReward_1 = nil
	self._Lab_OtherReward_1 = nil
	self._Frame_OtherReward_2 = nil
	self._Img_OtherReward_2 = nil
	self._Lab_OtherReward_2 = nil
	self._View_Reward = nil
	self._List_Reward = nil
	self._Lab_PlayDescription = nil
	self._Lab_NumLimit = nil
	self._Lab_LevelLimit = nil
	self._Lab_PropertyLimit = nil
	self._Lab_CurProperty = nil
	self._Lab_EnterTimeTitle = nil
	self._Lab_EnterTimeVal = nil
	self._Btn_Buy = nil
	self._Frame_Assist = nil
	self._IOSToggle_Assist = nil
	self._UITemplate_Assist = nil
	self._Frame_CantAssist = nil
	self._Btn_QuickJoin = nil
	self._Img_QuickJoin = nil
	self._Btn_Enter = nil
	self._Img_Enter = nil
	self._Frame_DungeonList = nil
	self._View_Dungeon = nil
	self._List_Dungeon = nil
	self._Frame_Difficulty = nil
	self._RdoGroup_Difficulty = nil
	self._Lab_QuickJoin = nil
	self._Img_GilliamBoss = nil
	self._Img_DragonNestBoss = nil
	self._Frame_TowerPassTime = nil
	self._Frame_TowerContent = nil
end

CPanelUIDungeon.Commit()
return CPanelUIDungeon