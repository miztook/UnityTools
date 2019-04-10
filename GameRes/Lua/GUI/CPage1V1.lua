local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local EResourceType = require "PB.data".EResourceType
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local ERankId = require"PB.data".ERankId
local CElementData = require "Data.CElementData"
local CUIModel = require "GUI.CUIModel"
local CPage3V3 = require"GUI.CPage3V3"
local CPageBattle = require"GUI.CPageBattle"
local Util = require "Utility.Util"
local PBHelper = require "Network.PBHelper"
local net = require "PB.net"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"

local CPage1V1 = Lplus.Class("CPage1V1")
local def = CPage1V1.define

def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil
def.field("number")._1V1RewardTemplate = 2
def.field(CUIModel)._Model4ImgRender_1 = nil
def.field(CUIModel)._Model4ImgRender_2 = nil
def.field("table")._RankReward1V1Data = nil 
def.field("table")._ArenaInstance = nil
def.field("number")._ArenaInstanceTid = 306
def.field("number")._RemainCount = 0
def.field("table")._RewardDataList = nil 


local instance = nil
def.static("=>", CPage1V1).Instance = function()
	if instance == nil then
        instance = CPage1V1()
	end
	return instance
end

local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil then
        -- 更新对应界面信息
		-- warn("CountGroupUpdateEvent event._CountGroupTid ==", event._CountGroupTid, instance._ArenaInstanceTid)
		instance:UpdateInfoEnterTime(instance._ArenaInstanceTid)
	end
end

local function UpdateRoleInfo(self,obj)
	local labName = obj:FindChild("Lab_Name")
	local data = game._CArenaMan._1V1HostData

	GUI.SetText(labName,data.Name)

	local labFightScore_Data = obj:FindChild("Lab_FightScore_Data")
	GUI.SetText(labFightScore_Data,GUITools.FormatMoney(data.FightScore))
	local labRank = obj:FindChild("Lab_Rank")
	local labPoint = obj:FindChild("Lab_PointTips/Lab_Point")
	if data.Rank == 0 then 
		GUI.SetText(labRank,StringTable.Get(20103))
	else
		GUI.SetText(labRank,tostring(data.Rank))
	end
	GUI.SetText(labPoint,tostring(data.Score))
end

-- 1v1当前排名奖励
local function RankReward1V1(self)
	local rewardItem = CElementData.GetRankRewardTemplate(self._1V1RewardTemplate)
	if rewardItem == nil then warn("RankReward id 2 is nil ") return end
	self._RankReward1V1Data = rewardItem.Rewards.RewardPairs
	if game._CArenaMan._1V1HostData.Rank == 0 then 
		-- 未入榜状态下奖励显示数量为0 
	    self._RewardDataList = GUITools.GetRewardList(self._RankReward1V1Data[#self._RankReward1V1Data].RewardId,true)
	else
		for i,v in ipairs(self._RankReward1V1Data) do	
			if game._CArenaMan._1V1HostData.Rank <= self._RankReward1V1Data[i].RankMin and game._CArenaMan._1V1HostData.Rank >= self._RankReward1V1Data[i].RankMax then 
				self._RewardDataList = GUITools.GetRewardList(self._RankReward1V1Data[i].RewardId,true)
			break end
		end
	end
	if self._RewardDataList == nil then
		self._PanelObject._ItemIcon1:SetActive(false)
		self._PanelObject._ItemIcon2:SetActive(false)
	return end
	for i,data in ipairs(self._RewardDataList) do 
		local frame_icon = nil
		if i == 1 then 
			frame_icon = self._PanelObject._ItemIcon1
		else
			frame_icon = self._PanelObject._ItemIcon2
		end
		if data.IsTokenMoney then
			IconTools.InitTokenMoneyIcon(frame_icon, data.Data.Id, data.Data.Count)
		else
			IconTools.InitItemIconNew(frame_icon, data.Data.Id, { [EItemIconTag.Number] = data.Data.Count })
		end
	end
end

-- 更新战绩
local function UpdateCombatGains(self)
	local data = game._CArenaMan._1V1HostData
	if data.TotalCount == nil or data.TotalCount == 0 then
		data.TotalCount = 1
 	end
	GUI.SetText(self._PanelObject._LabWin, tostring(data.WinCount))
	GUI.SetText(self._PanelObject._LabWinPoint, string.format("%.0f", (data.WinCount / data.TotalCount) * 100) .. "%") 
	--次数显示
	local maxCount = CElementData.GetTemplate("CountGroup", self._ArenaInstance.CountGroupTid).MaxCount
	self._RemainCount = data.EnterNum
	if data.EnterNum == 0 then
		-- 剩余次数变红
		GUI.SetText(self._PanelObject._LabChance, string.format(StringTable.Get(20081), data.EnterNum, maxCount))
	elseif data.EnterNum > maxCount then
		-- 剩余次数大于初始最大次数时变绿
		GUI.SetText(self._PanelObject._LabChance, string.format(StringTable.Get(20082), data.EnterNum, maxCount))
	else
		GUI.SetText(self._PanelObject._LabChance, data.EnterNum.."/"..maxCount)
	end
end

def.method("table", "userdata").Show = function(self, linkInfo, root)
	self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
    if self._ArenaInstance == nil then
		self._ArenaInstance = CElementData.GetTemplate("Instance", self._ArenaInstanceTid)
	end

	CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
    self:InitPanel()
end

def.method().InitPanel = function (self)
	UpdateRoleInfo(self,self._PanelObject._FrameRoleInfo1V1)
	RankReward1V1(self)
	UpdateCombatGains(self)
end

-- 更新显示次数
def.method("number").UpdateInfoEnterTime = function (self, tid)
	local data = game._DungeonMan:GetDungeonData(tid)
	local maxCount = CElementData.GetTemplate("CountGroup", self._ArenaInstance.CountGroupTid).MaxCount
	self._RemainCount = data.RemainderTime
	if data ~= nil then
		if self._RemainCount == 0 then
			-- 剩余次数变红
			GUI.SetText(self._PanelObject._LabChance, string.format(StringTable.Get(20081), self._RemainCount, maxCount))
		elseif self._RemainCount > maxCount then
			-- 剩余次数大于初始最大次数时变绿
			GUI.SetText(self._PanelObject._LabChance, string.format(StringTable.Get(20082), self._RemainCount, maxCount))
		else
			GUI.SetText(self._PanelObject._LabChance, self._RemainCount.."/"..maxCount)
		end
	end
end

def.method("string").Click = function(self, id)
	if id == "Btn_Charge1" then
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Matching_Arena, 0)
		local hp = game._HostPlayer
		if not hp:InWorld() then
			game._GUIMan:ShowTipText(StringTable.Get(20075), false)
			return
		end
		-- 匹配队列
		if game._CArenaMan._IsMatching3V3 or game._CArenaMan._IsMatchingBattle then 
			game._GUIMan:ShowTipText(StringTable.Get(20076),false)
			return
		end
		-- 战斗中（和服务器统一 判断仇恨列表）
		local hateList = hp:GetHatedEntityList()
		if #hateList > 0 then game._GUIMan:ShowTipText(StringTable.Get(20077),false) return end
		-- 次数
		if self._RemainCount == 0 then game._GUIMan:ShowTipText(StringTable.Get(20078),false) return end
		--处于杀戮模式
		if hp:IsMassacre() then game._GUIMan:ShowTipText(StringTable.Get(20079),false)  return end
		game._GUIMan:Open("CPanelArenaOneMatching",nil)
		CQuestAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Stop()
		hp:StopNaviCal()
		hp:StopAutoTrans()
		self:StartJJC1x1Math()	
	elseif id == "Btn_Rank" then
		game._GUIMan:Open("CPanelRanking",ERankId.JJC1v1)
	elseif id == "Btn_PlusChance"  then 
		-- warn("-----------lidaming 1V1---------------", game._CArenaMan._1V1HostData.EnterNum)
		game:BuyCountGroup(game._CArenaMan._1V1HostData.EnterNum , self._ArenaInstance.CountGroupTid)
	elseif id == "Btn_ShowAward"  then 
		local panelData = {
								_RewardData = self._RankReward1V1Data,
								_MyRank = game._CArenaMan._1V1HostData.Rank
						  }
		game._GUIMan:Open("CPanelRewardShow",panelData)
	elseif string.find(id,"Btn_ItemIcon") then 
		local index = tonumber(string.sub(id,-1))
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

--匹配对手C2S消息
def.method().StartJJC1x1Math = function(self)
	if game._HostPlayer:IsInServerCombatState() then	
		game._GUIMan:ShowTipText(StringTable.Get(20074), false)
		return
	end
	local C2SJJC1x1Math = require "PB.net".C2SJJC1x1Math
	PBHelper.Send(C2SJJC1x1Math()) 
end

def.method().Destroy = function (self)
	CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	instance = nil 
end

CPage1V1.Commit()
return CPage1V1