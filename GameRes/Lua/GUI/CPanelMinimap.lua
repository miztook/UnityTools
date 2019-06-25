local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageMiniMap = require "GUI.CPageMiniMap"
local CPageDamageCount = require "GUI.CPageDamageCount"
local CPanelTracker = require "GUI.CPanelTracker"
local EWorldType = require "PB.Template".Map.EWorldType
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CElementData = require "Data.CElementData"
local CPanelRoleInfo = require"GUI.CPanelRoleInfo"
local NotifyFunctionEvent = require "Events.NotifyFunctionEvent"
local RegionLimitChangeEvent = require "Events.RegionLimitChangeEvent"
local CTeamMan = require "Team.CTeamMan"

local CPanelMinimap = Lplus.Extend(CPanelBase, "CPanelMinimap")
local def = CPanelMinimap.define

def.field("userdata")._TweenMan = nil

def.field(CPageMiniMap)._MiniMap = nil -- 小地图
def.field(CPageDamageCount)._DamageCount = nil -- 伤害统计
def.field("dynamic")._CurrentPage = nil -- 当前打开的页面
def.field("userdata")._Frame_MiniMap = nil
def.field("userdata")._Frame_Damage = nil
def.field("userdata")._Btn_Switch = nil
def.field("userdata")._BtnExitDungeon = nil -- 退出副本按钮
def.field("userdata")._FrameOpenIntroduction = nil -- 副本通用介绍按钮

def.field("boolean")._IsShowMap = true

def.field("userdata")._FrameArenaMatch = nil 
def.field("userdata")._LabMatchingTime = nil 
def.field("userdata")._FrameCommonMatch = nil 		-- 通用匹配计时模块
def.field("userdata")._LabCommonMatchTime = nil 	-- 通用匹配计时模块显示Label
def.field("userdata")._Lab_TargetMatchText = nil 	-- 通用匹配，功能模块字符 显示

def.field("string")._ArenaMatchTweenId = "3V3Match"
-- def.field("string")._CommonMatchTweenId = "CommonMatch"

-- 分线相关  lidaming  2018/07/26
def.field("userdata")._Btn_Line = nil
def.field("userdata")._Lab_Line = nil

def.field("boolean")._IsShowLine = false
def.field("table")._LastBuffInfo = BlankTable

local instance = nil
def.static("=>",CPanelMinimap).Instance = function ()
	if not instance then
		instance = CPanelMinimap()
		instance._PrefabPath = PATH.Panel_Main_MiniMap
		instance._DestroyOnHide = false
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end

	if instance._MiniMap == nil then
        instance._MiniMap = CPageMiniMap.New()
    end
    if instance._DamageCount == nil then
        instance._DamageCount = CPageDamageCount.New()
    end
	return instance
end

def.override().OnCreate = function(self)
	self._TweenMan = self._Panel:GetComponent(ClassType.DOTweenPlayer)
	-- 小地图
	self._Frame_MiniMap = self:GetUIObject("Frame_MiniMap")
	self._Frame_MiniMap:SetActive(true)
	self._MiniMap:Init(self)
	-- 伤害统计
	self._Frame_Damage = self:GetUIObject("Frame_Damage")
	self._DamageCount:Init(self)
	self._Frame_Damage:SetActive(true)

	self._Btn_Switch = self:GetUIObject("Btn_Switch0")
	-- 离开副本
	self._BtnExitDungeon = self:GetUIObject("Btn_LeaveDungeon")
	self._FrameOpenIntroduction = self:GetUIObject("Frame_OpenIntroduction")

	self:SetExitBtnState()

	-- 匹配
	self._FrameArenaMatch = self:GetUIObject("Frame_3V3Match")
	self._LabMatchingTime = self:GetUIObject("Lab_MatchTime")
	self._FrameArenaMatch:SetActive(false)

	self._FrameCommonMatch = self:GetUIObject('Frame_CommonMatch')
	self._LabCommonMatchTime = self:GetUIObject('Lab_CommonMatchTime')
	self._Lab_TargetMatchText = self:GetUIObject('Lab_TargetMatchText')

	-- 分线 
	self._Btn_Line = self:GetUIObject("Btn_Line")
	self._Lab_Line = self:GetUIObject("Lab_Line")
	
end


-- 监听区域限制改变事件
--[[
local function OnRegionLimitChangeEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:SetExitBtnStateByLimit()
	end
end
]]

def.override("dynamic").OnData = function (self,data)
	CPanelBase.OnData(self,data)
	if self._DamageCount:HasData() then
		-- 小地图打开之前已缓存了数据
		GUITools.SetUIActive(self._Btn_Switch, true)
		self:ChangePage(false)
		self._DamageCount:UpdateView()
	else
		GUITools.SetUIActive(self._Btn_Switch, false)
		self:ChangePage(true)
	end

	local matchType = CPVPAutoMatch.Instance():GetType()
	if matchType ~= EnumDef.AutoMatchType.None and
	   matchType ~= EnumDef.AutoMatchType.SearchTeam and 
	   matchType ~= EnumDef.AutoMatchType.InTeam then
		self:SetTargetMatchText(CPVPAutoMatch.Instance():GetMatchFunctionText())
    	self:ShowCommonMatch(true)
	end 
	--CGame.EventManager:addHandler(RegionLimitChangeEvent, OnRegionLimitChangeEvent)
	self:UpdateArrayLineList()
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
	self._DamageCount:OnInitItemRankData(item, id, index)
end

def.method().LeaveDungeon = function (self)
	-- 1V1不能退出，给提示
	if game._HostPlayer:In1V1Fight() then
		game._GUIMan:ShowTipText(StringTable.Get(20004), false)	
		return
	end
	-- 3V3不能退出，给提示
	if game._HostPlayer:In3V3Fight() then
		game._GUIMan: ShowTipText(StringTable.Get(20004),false)
		return
	end	
	-- 无畏战场不能退出
	if game._HostPlayer:InEliminateFight() then
		game._GUIMan: ShowTipText(StringTable.Get(20004),false)
		return
	end	

	local callback = function(value)
		local hp = game._HostPlayer
		if value then
			if hp:InDungeon() or hp:InImmediate() or game._HostPlayer:InPharse() then
				game._DungeonMan:TryExitDungeon()
				self:EnableExitBtn(false)
			end	
		end
	end
	local title,message = "",""
    local closeType = 0
	if game._HostPlayer:InImmediate() then
        title, message, closeType = StringTable.GetMsg(97)
    elseif game._HostPlayer:InPharse() then
		title, message, closeType = StringTable.GetMsg(82)
	elseif game._HostPlayer:InDungeon() then 
		if game._HostPlayer:IsInGlobalZone() then
			-- 跨服副本
			title, message, closeType = StringTable.GetMsg(131)
		else
			title, message, closeType = StringTable.GetMsg(17)
		end
	end
	MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

-------------------------------- 副本按钮 start ---------------------------------
def.method().SetExitBtnState = function(self)
	local isVisable = false 
	--if game._HostPlayer:In1V1Fight() or game._HostPlayer:In3V3Fight() or game._HostPlayer:InEliminateFight() then 
	--	isVisable = false
	--else
	--	isVisable = (game._CurMapType == EWorldType.Instance) or (game._CurMapType == EWorldType.Immediate)
	--end
	
	--if game._RegionLimit._LimitLeave then
		--isVisable = false
	--end

	--大世界和城镇不用判断属性，肯定不显示离开图标
	if (game._CurMapType == EWorldType.City) or (game._CurMapType == EWorldType.Town) then
		self:EnableExitBtn(isVisable)
		return
	end

	--其他类型地图，根据属性显示，不根据类型
	local nMapID = game._CurWorld._WorldInfo.MapTid
    local worldData = CElementData.GetMapTemplate(nMapID)
    if worldData ~= nil then
    	isVisable = worldData.IsShowLeaveButton
    end

	self:EnableExitBtn(isVisable)
end

def.method().HideDungeonShow = function(self)
	self:EnableExitBtn(false)
	self:EnableDungeonIntroductionBtn(false)
end

def.method().SetExitBtnStateByLimit = function(self)
	if (game._CurMapType == EWorldType.City) or (game._CurMapType == EWorldType.Town) then return end
	--self:EnableExitBtn(not game._RegionLimit._LimitLeave)
end

def.method("boolean").EnableExitBtn = function (self, enable)
	if not IsNil(self._BtnExitDungeon) then
		self._BtnExitDungeon:SetActive(enable)
	end
end

def.method("boolean").EnableDungeonIntroductionBtn = function(self, enable)
	if not IsNil(self._FrameOpenIntroduction) then
		if self._FrameOpenIntroduction.activeSelf ~= enable then
			self._FrameOpenIntroduction:SetActive(enable)
		end
	end
end

-------------------------------- 副本按钮 end ---------------------------------


-- 小地图和伤害统计的切换
def.method("boolean").ChangePage = function (self, isShowMap)
	if self._CurrentPage ~= nil then
		self._CurrentPage:Hide()
	end
	if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Map) then
		GUITools.SetUIActive(self._Frame_MiniMap, isShowMap)
	else
		GUITools.SetUIActive(self._Frame_MiniMap, false)
	end
	GUITools.SetUIActive(self._Frame_Damage, not isShowMap)

	self._CurrentPage = isShowMap and self._MiniMap or self._DamageCount
	self._CurrentPage:Show()

	self._IsShowMap = isShowMap
end

def.method("number").ChangeDamageTitle = function (self, type)
	if self:IsShow() then
		self._DamageCount:ChangeDamageTitle(type)
	end
end

-- 处理实时伤害统计
def.method("table", "number").HandleDamageStatistics = function (self, data, showType)	
	if self._DamageCount:GetDamageShowType() ~= showType then
		self._DamageCount:SetShowType(showType)

		if self:IsShow() and self._IsShowMap then
			GUITools.SetUIActive(self._Btn_Switch, true)
			self:ChangePage(false) -- 切换至对应统计界面
		end
	end
	self._DamageCount:HandleDamageData(data, showType)
end

-- 清空伤害统计信息
def.method("boolean").ClearDamageInfo = function (self, isClearUI)
	self._DamageCount:ClearDamageData()
	if isClearUI and self:IsShow() then
		self._DamageCount:ClearDamageUI()
		GUITools.SetUIActive(self._Btn_Switch, false)
		if not self._IsShowMap then
			self:ChangePage(true)
		end
	end
end

def.method("table").HandleEliminateStatistics = function (self, data)
	if self:IsShow() and self._IsShowMap then
		self:ChangePage(false) -- 切换至排行榜界面
	end
	self._DamageCount:HandleRankData(data)
end

-- 清空无畏战场排行数据信息
def.method().ClearEliminateRankInfo = function (self)
	self._DamageCount:ClearRankData()
	if not self._IsShowMap and self:IsShow() then
		self._DamageCount:ClearRankUI()
		self:ChangePage(true)
	end
end

-- 离开副本时清理副本相关
def.method().ClearDungeonInfo = function (self)
	self:HideDungeonShow()
	self:ClearDamageInfo(true)
end

--[[---------------------------------分线--------------------------------------]]

def.method().UpdateArrayLineList = function(self)
	--大世界和城镇不用判断，肯定显示分线   -- lidaming  2018/08/30
	if self._Btn_Line == nil then return end
	if (game._CurMapType == EWorldType.City) or (game._CurMapType == EWorldType.Town) then
		-- 公会基地不显示分线
		if game._GuildMan:IsInGuildScene() then 
			self._Btn_Line:SetActive(false)
			return
		end
		self._Btn_Line:SetActive(true)
	else
		self._Btn_Line:SetActive(false)
	end	

	local curWorldInfo = game._CurWorld._WorldInfo
	local curState = nil
	if self._Lab_Line ~= nil and curWorldInfo.ValidLineIds ~= nil then
		for i,v in ipairs(curWorldInfo.ValidLineIds) do
			if v.LineId == curWorldInfo.CurMapLineId then
				curState = v.Pressure
			end
		end
		if curState ~= nil then			
			local stateStr = string.format(StringTable.Get(12021), curWorldInfo.CurMapLineId)
			if curState == EnumDef.ValidLineState.Idel then
				stateStr = "<color=#ffff00>".. stateStr .. "</color>"
			elseif curState == EnumDef.ValidLineState.Free then
				stateStr = "<color=#7ddc37>".. stateStr .. "</color>"
			elseif curState == EnumDef.ValidLineState.Busy then
				stateStr = "<color=#eb8e1f>".. stateStr .. "</color>"
			elseif curState == EnumDef.ValidLineState.Full then
				stateStr = "<color=#f93838>".. stateStr .. "</color>"
			end
			-- warn("lidaming ---->>> curState ==", curState , "StateStr == ", stateStr)
			if stateStr == nil then warn("state == nil !!!!!!!!!!!!!!") stateStr = "<color=#ffff00>".. stateStr .. "</color>" end
			GUI.SetText(self._Lab_Line , stateStr)
			-- GUI.SetText(self._Lab_LineState , stateStr)
		end
	end
end

--[[---------------------------------通用匹配模块---------------------------------]]
def.field("number")._CommonMatchTimerId = 0
def.method("boolean").ShowCommonMatch = function(self, bShow)
	if not self:IsShow() then return end
	
	self._FrameCommonMatch:SetActive(bShow)
	if bShow then
		self:AddMatchTimer()
	else
		self:ResetMatchTimer()
	end
end

-- 设置匹配目标功能 字符串
def.method("string").SetTargetMatchText = function(self, targetMatchText)
	GUI.SetText(self._Lab_TargetMatchText, targetMatchText)
end

def.method().MatchTick = function(self)
	GUI.SetText(self._LabCommonMatchTime, CPVPAutoMatch.Instance():GetAutoMatchingTimeStr())
end

def.method().AddMatchTimer = function(self)
	self:ResetMatchTimer()
	self._CommonMatchTimerId = _G.AddGlobalTimer(1, false, function()
        self:MatchTick()
    end)
end

def.method().ResetMatchTimer = function(self)
	if self._CommonMatchTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._CommonMatchTimerId)
    end
    self._CommonMatchTimerId = 0
end

def.method().OnBtnLeaveDungeon = function(self)
	if game._RegionLimit._LimitLeave then
		-- 地图限制禁止离开
		game._GUIMan:ShowTipText(StringTable.Get(15555), false)
	else
		local CQuestAutoMan = require "Quest.CQuestAutoMan"
		local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
		local CAutoFightMan = require "AutoFight.CAutoFightMan"
		CQuestAutoMan.Instance():Stop()	
		CDungeonAutoMan.Instance():Stop()
		CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)

		game._HostPlayer:StopAutoTrans()
		
		self:LeaveDungeon()
	end
end

--[[---------------------------------通用匹配模块---------------------------------]]

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_LeaveDungeon" then
		self:OnBtnLeaveDungeon()
	elseif id == "Btn_Switch" then
		self:ChangePage(not self._IsShowMap)
	elseif id == "Btn_CommonMatch" then
		self:ReturnPageCommonMatchLogic()
	elseif id == "Btn_Line" then
		-- game._GUIMan:Open("CPanelUIArrayLine", nil)
		-- 获取分线状态
		local PBHelper = require "Network.PBHelper"
		local C2SMapLineGetInfo = require "PB.net".C2SMapLineGetInfo		
		local protocol = C2SMapLineGetInfo()
		PBHelper.Send(protocol)

	elseif id == "Btn_OpenIntroduction" then
		local popupTid = game._DungeonMan:GetCurIntroductionPopupTID()
		game._GUIMan:Open("CPanelUIDungeonIntroduction", popupTid)
	else
		self._CurrentPage:ParentOnClick(id)
	end
end

def.method().ReturnPageCommonMatchLogic = function(self)
	local curType = CPVPAutoMatch.Instance():GetType()
	if curType == EnumDef.AutoMatchType.In3V3Fight then
		if game._CArenaMan._IsMatching3V3 then 
			game._CArenaMan:SendC2SOpenThree()
		end
	elseif curType == EnumDef.AutoMatchType.InBattleFight then
		if game._CArenaMan._IsMatchingBattle then 
			game._CArenaMan:OnOpenBattle()
		end
	elseif curType == EnumDef.AutoMatchType.SearchTeam then

	elseif curType == EnumDef.AutoMatchType.QuickMatch then
		local EInstanceType = require "PB.Template".Instance.EInstanceType
		local roomId = game._DungeonMan:GetQuickMatchTargetId()
		local dungeon_id = CTeamMan.Instance():ExchangeToDungeonId(roomId)

		warn("dungeon_id = ", dungeon_id)

		local dungeonTemp = CElementData.GetInstanceTemplate(dungeon_id)
		if dungeonTemp == nil then return end

		-- 远征  副本只有 两个界面可以进入快捷匹配，如有其它添加，请修正以下逻辑
		if dungeonTemp.InstanceType == EInstanceType.INSTANCE_EXPEDITION then
			local data = { DungeonID = dungeon_id}
			game._GUIMan:Open("CPanelUIExpedition", data)
		else
			game._GUIMan:Open("CPanelUIDungeon", dungeon_id)
		end
	end
end

def.override().OnHide = function (self)
    CPanelBase.OnHide(self)
	self._CurrentPage:Hide()
	--CGame.EventManager:removeHandler(RegionLimitChangeEvent, OnRegionLimitChangeEvent)
end

def.override().OnDestroy = function(self)
	if self._MiniMap then
		self._MiniMap:Destroy()
		self._MiniMap = nil
	end

	if self._DamageCount then
		self._DamageCount:Destroy()
		self._DamageCount = nil
	end
	
	self._CurrentPage = nil

	self._Frame_MiniMap = nil
	self._Frame_Damage = nil
	self._BtnExitDungeon = nil
	self._FrameOpenIntroduction = nil
	self._FrameArenaMatch = nil
	self._LabMatchingTime = nil
	self._FrameCommonMatch = nil
	self._LabCommonMatchTime = nil
	self._IsShowLine = false
	self._Btn_Line = nil
	self._Lab_Line = nil
	self._LastBuffInfo = {}
	self._TweenMan = nil
	self._Btn_Switch = nil
	self._Lab_TargetMatchText = nil

end

CPanelMinimap.Commit()
return CPanelMinimap