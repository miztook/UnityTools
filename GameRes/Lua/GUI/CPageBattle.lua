local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CSpecialIdMan = require  "Data.CSpecialIdMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelMinimap = Lplus.ForwardDeclare("CPanelMinimap")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local EMatchType = require "PB.net".EMatchType

local CPageBattle = Lplus.Class("CPageBattle")
local def = CPageBattle.define

def.field("userdata")._Panel = nil
def.field("table")._PanelObject = BlankTable
def.field("number")._BattleActivitySpecialId = 10 
def.field("number")._RemainTimerId = 0
def.field("number")._MatchingTimerID = 0
def.field("number")._MatchingWaitingTime = 0
def.field("number")._BattleWaitingTimeSpecialId = 376
def.field("number")._SeasonRewardSpecId = 583
def.field("table")._RewardDataList = nil 
def.field("boolean")._IsInActivityTime = false
def.field("number")._SeasonEndTime = 0
def.field("number")._BanMatchTimerID = 0
def.field("table")._RewardList = nil                     --场内奖励

local instance = nil
def.static("=>", CPageBattle).Instance = function()
	if instance == nil then
        instance = CPageBattle()
	end
return instance
end

local function ShowRemainTime(self,endTime)
	if self._RemainTimerId > 0 then
		_G.RemoveGlobalTimer(self._RemainTimerId)
		self._RemainTimerId = 0
	end 
	local timeStr = ""
	local callback = function()
		local showTime = endTime - GameUtil.GetServerTime()/1000
		timeStr = GUITools.FormatTimeFromSecondsToZero(true,showTime)
		GUI.SetText(self._PanelObject._LabRemainTime,timeStr)
        if showTime <= 0 then 
            -- 消除计时器
	        _G.RemoveGlobalTimer(self._RemainTimerId)
		    self._RemainTimerId = 0
		    self._PanelObject._LabRemainTime:SetActive(false)
        end            
    end
    self._RemainTimerId = _G.AddGlobalTimer(1, false, callback)  	
end

local function UpdateAllRoleInfo(self,obj)
	local data = game._CArenaMan._BattleHostData
	local labFightScore_Data = obj:FindChild("Lab_FightScore_Data")
	GUI.SetText(labFightScore_Data,tostring(data.FightScore))
	if game._CArenaMan._BattleHostData.Rank <= 0 then 
		GUI.SetText(self._PanelObject._LabRank,StringTable.Get(20103))
	else
		GUI.SetText(self._PanelObject._LabRank,tostring(game._CArenaMan._BattleHostData.Rank))
	end
	GUI.SetText(self._PanelObject._LabScore,tostring(game._CArenaMan._BattleHostData.EliminateScore))
	GUI.SetText(self._PanelObject._LabScore,tostring(game._CArenaMan._BattleHostData.EliminateScore))
	local dungeonTid = CSpecialIdMan.Get("EliminateScene")
	local dungeonTemplate = CElementData.GetInstanceTemplate(game._DungeonMan:GetEliminateWorldTID())
	local maxCount = CElementData.GetTemplate("CountGroup", dungeonTemplate.CountGroupTid).MaxCount
	local enterNum = game._DungeonMan:GetDungeonData(game._DungeonMan:GetEliminateWorldTID()).RemainderTime
	if enterNum == 0 then
		-- 剩余次数变红
		GUI.SetText(self._PanelObject._LabRewardTimes, string.format(StringTable.Get(20081), enterNum, maxCount))
	elseif enterNum > maxCount then
		-- 剩余次数大于初始最大次数时变绿
		GUI.SetText(self._PanelObject._LabRewardTimes, string.format(StringTable.Get(20082), enterNum, maxCount))
	else
		GUI.SetText(self._PanelObject._LabRewardTimes, enterNum.."/"..maxCount)
	end

	local sct = CElementData.GetScriptCalendarTemplate(self._BattleActivitySpecialId)
	if sct == nil or #sct.TimeData.ContentTimes <= 0 then return end
	local nowTime = GameUtil.GetServerTime()
	local today = os.date("%Y/%m/%d", nowTime/1000)
	local endStr = today .. " ".. sct.TimeData.ContentTimes[1].CloseTime
	local Time = math.abs(data.SeasonLeftTime)
	if Time + GameUtil.GetServerTime()/1000 <= GameUtil.GetServerTime()/1000 then 
		self._PanelObject._LabRemainTime:SetActive(false)
		self._IsInActivityTime = false
	else
		self._IsInActivityTime = true
		self._PanelObject._LabRemainTime:SetActive(true)
		GUI.SetText(self._PanelObject._LabRemainTime,GUITools.FormatTimeSpanFromSeconds(Time))
	end
end

local function ShowRewardItem(self)
	local tempId  = tonumber(CElementData.GetSpecialIdTemplate(self._SeasonRewardSpecId).Value)
	local rewardItem = CElementData.GetRankRewardTemplate(tempId)
	if rewardItem == nil then warn("RankReward id "..tempId.." is nil" ) return end
	self._RewardList = rewardItem.Rewards.RewardPairs
	local rank = game._CArenaMan._BattleHostData.Rank
	if rank == 0 then 
		-- 未入榜状态下奖励显示数量为0 
	    self._RewardDataList = GUITools.GetRewardList(self._RewardList[#self._RewardList].RewardId,true)
	else
		for i,v in ipairs(self._RewardList) do	
			if rank <= self._RewardList[i].RankMin and rank >= self._RewardList[i].RankMax then 
				self._RewardDataList = GUITools.GetRewardList(self._RewardList[i].RewardId,true)
			break end
		end
	end
	for i ,data in ipairs(self._RewardDataList) do
		if i == 1 then 
			self:SetReward(self._PanelObject._ItemIcon5,data)
		elseif i == 2 then
			self:SetReward(self._PanelObject._ItemIcon6,data)
		elseif i == 3 then
			self:SetReward(self._PanelObject._ItemIcon7,data)
		end
	end
end

local function StartBattleMatching(self)
	local protocol = (require "PB.net".C2SMatching)()
	protocol.MatchType = EMatchType.EMatchType_Eliminate
	PBHelper.Send(protocol)
end

--取消无畏战场匹配
local function CancelBattleMathcing( self )
	self:CancelBattleTimer() 
	local protocol = (require "PB.net".C2SMatchReqCancel)()
	protocol.MatchType = EMatchType.EMatchType_Eliminate
	PBHelper.Send(protocol)
end

def.method("table", "userdata").Show = function(self, linkInfo, root)
	self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
    -- self._PanelObject._FrameButton:SetActive(false)
    self._IsInActivityTime = false
    self:InitPanel()
end

def.method().InitPanel = function (self)
	UpdateAllRoleInfo(self,self._PanelObject._RoleInfoBattle)
	local C2SMatchActivityStateReq = require "PB.net".C2SMatchActivityStateReq
    local protocol = C2SMatchActivityStateReq()
    protocol.MatchType = EMatchType.EMatchType_Eliminate
    PBHelper.Send(protocol)
    ShowRewardItem(self)
end

def.method("string").Click = function(self, id)
	if id == "Btn_ChargeBattle" then 
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Matching_Arena, 0)
		if game._CArenaMan._IsMatching3V3 then 
			game._GUIMan: ShowTipText(StringTable.Get(20076),false)
			return
		end
		if not self._IsInActivityTime then
			game._GUIMan:ShowTipText(StringTable.Get(20080), false)
			return 
		end
		if game._CArenaMan._IsBanMatchingBattle then 
			game._GUIMan:ShowTipText(StringTable.Get(27011),false)
			return
		end
		CQuestAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()
		local hp = game._HostPlayer
		hp:StopNaviCal()
		hp:StopAutoTrans()
		StartBattleMatching(self)
	elseif id == "Btn_Rank" then
		game._GUIMan:Open("CPanelRanking", 10)
	elseif id == "Btn_CancelChargeBattle" then 
		CancelBattleMathcing(self)
	elseif id == "Btn_BattleRule" then 
		game._GUIMan:Open("CPanelRuleDescription",5)
	elseif id == "Btn_ShowAward"  then 	
		local panelData = {
								_RewardData = self._RewardList,
								_MyRank = game._CArenaMan._BattleHostData.Rank,
						  }
		game._GUIMan:Open("CPanelRewardShow",panelData)
	elseif  string.find(id, "Btn_ItemIcon") then 
		local index = tonumber(string.sub(id,-1)) - 4
		local data = self._RewardDataList[index]
		if not data.IsTokenMoney then
			CItemTipMan.ShowItemTips(data.Data.Id, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
		else
			local panelData = 
							{
								_MoneyID = data.Data.Id,
								_TipPos = TipPosition.FIX_POSITION,
								_TargetObj = nil, 
							} 
			CItemTipMan.ShowMoneyTips(panelData)
		end
	end
end

local function BanMatchTime(self,endTime)
	GUITools.SetBtnGray(self._PanelObject._BtnCharge3V3,true)
	self._PanelObject._BtnCancelCharge :SetActive(false)
	GameUtil.MakeImageGray(self._PanelObject._BtnChargeBg,true)
	self._PanelObject._FrameMatchTime:SetActive(true)
	GUI.SetText(self._PanelObject._LabMatchBanTip,string.format(StringTable.Get(20084),StringTable.Get(20063)))
	if self._BanMatchTimerID > 0 then
		_G.RemoveGlobalTimer(self._BanMatchTimerID)
		self._BanMatchTimerID = 0
	end 

	local timeStr = ""
	local callback = function()
		local showTime = endTime - GameUtil.GetServerTime()/1000
		timeStr = GUITools.FormatTimeFromSecondsToZero(false,showTime)
        GUI.SetText(self._PanelObject._LabTime,string.format(StringTable.Get(20084), timeStr))
        if showTime <= 0 then 
            -- 消除计时器
            GUITools.SetBtnGray(self._PanelObject._BtnCharge3V3,false)
	       	self._PanelObject._FrameMatchTime:SetActive(false)
	        _G.RemoveGlobalTimer(self._BanMatchTimerID)
		    self._BanMatchTimerID = 0
		    game._CArenaMan._IsBanMatchingBattle = false
        end            
    end
    self._BanMatchTimerID = _G.AddGlobalTimer(1, false, callback)  	
end
-- 控制无畏战场匹配按钮显示状态
def.method("boolean").ChangeBattleBtnChargeState = function (self,isOpenTimeBattle)
	if not isOpenTimeBattle then 
		GUI.SetText(self._PanelObject._BtnLabCharge,StringTable.Get(20062))
		self._PanelObject._BtnCancelCharge:SetActive(false)
	else
		if game._CArenaMan._IsMatchingBattle then 
			CPVPAutoMatch.Instance():Stop()
			self._PanelObject._BtnChargeBattle:SetActive(false)
			self._PanelObject._BtnCancelCharge:SetActive(true)
			self:ShowMatchingTimeBattle(game._DungeonMan._BattleMatchingStartTime)
			return
		end
		if game._CArenaMan._IsBanMatchingBattle then 
			self._PanelObject._BtnChargeBattle:SetActive(true)

    		BanMatchTime(self,game._DungeonMan._BattleBanEndTime)
    	else
    		self._PanelObject._BtnCancelCharge:SetActive(false)
    		self._PanelObject._BtnChargeBattle:SetActive(true)
    		self._PanelObject._FrameMatchTime:SetActive(false)

			-- ShowRemainTime(self,self._SeasonEndTime)
    	end
	end
end 

--无畏战场匹配中时间显示
def.method("number").ShowMatchingTimeBattle = function(self,startTime)
	self._PanelObject._BtnCancelCharge:SetActive(true)
	self._PanelObject._BtnChargeBattle:SetActive(false)
	self._PanelObject._FrameMatchTime:SetActive(true)
	GUI.SetText(self._PanelObject._LabMatchBanTip,string.format(StringTable.Get(20086),StringTable.Get(20085)))

	if self._MatchingTimerID > 0 then
		_G.RemoveGlobalTimer(self._MatchingTimerID)
		self._MatchingTimerID = 0
	end	
	local timeStr = ""
	self._MatchingWaitingTime = CSpecialIdMan.Get("EliminateMatchingTime")
	local showTime = 0
	local endTime = self._MatchingWaitingTime + startTime
	self._MatchingTimerID = _G.AddGlobalTimer(1, false, function()
		showTime = GameUtil.GetServerTime()/1000 - startTime
		if GameUtil.GetServerTime()/1000 >= endTime then 
			self:CancelBattleTimer()
			return 
		end
		timeStr = GUITools.FormatTimeFromSecondsToZero(false,showTime)
		GUI.SetText(self._PanelObject._LabTime, string.format(StringTable.Get(20086),timeStr))			
	end)
end

def.method("userdata","table").SetReward = function (self,item,data)
	if data.IsTokenMoney then
		IconTools.InitTokenMoneyIcon(item, data.Data.Id, data.Data.Count)
	else
		IconTools.InitItemIconNew(item, data.Data.Id, { [EItemIconTag.Number] = data.Data.Count })
	end
end

def.method().CancelBattleTimer = function (self)
	if self._MatchingTimerID > 0 then
		_G.RemoveGlobalTimer(self._MatchingTimerID)
		self._MatchingTimerID = 0
	end
	if self._RemainTimerId > 0 then
		_G.RemoveGlobalTimer(self._RemainTimerId)
		self._RemainTimerId = 0
	end
	self._PanelObject._BtnCancelCharge:SetActive(false)
	self._PanelObject._BtnChargeBattle:SetActive(true)
	self._PanelObject._FrameMatchTime:SetActive(false)
end

def.method().Destroy = function (self)
	if self._MatchingTimerID > 0 then
		_G.RemoveGlobalTimer(self._MatchingTimerID)
		self._MatchingTimerID = 0
	end
	if self._RemainTimerId > 0 then
		_G.RemoveGlobalTimer(self._RemainTimerId)
		self._RemainTimerId = 0
	end
	if self._BanMatchTimerID > 0 then
		_G.RemoveGlobalTimer(self._BanMatchTimerID)
		self._BanMatchTimerID = 0
	end
	instance = nil 

	self._Panel = nil
end


CPageBattle.Commit()
return CPageBattle