--
--公会护送主界面
--
--【孟令康】
--
--2018年04月26日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local MemberType = require "PB.data".GuildMemberType
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local EConvoyActState = require "PB.net".EConvoyActState
local EConvoyUpdateType = require "PB.net".EConvoyUpdateType
local CPanelUIGuildConvoy = Lplus.Extend(CPanelBase, "CPanelUIGuildConvoy")
local def = CPanelUIGuildConvoy.define

def.field("boolean")._Is_Leader = false
def.field("table")._RewardData = nil
def.field("table")._MoneyData = nil
def.field("boolean")._Should_Set_HPInfo = true

def.field("userdata")._Lab_Des = nil
def.field("userdata")._RewardList = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Lab_Level_Num = nil
def.field("userdata")._Lab_Member_Num = nil
def.field("userdata")._Btn_Member_Set = nil
def.field("userdata")._Lab_Sign_Num = nil
def.field("userdata")._Lab_Open_Num = nil
def.field("userdata")._Lab_Enemy_Num = nil
def.field("userdata")._Btn_Sign = nil
def.field("userdata")._Img_Enter0 = nil
def.field("userdata")._Lab0 = nil
def.field("userdata")._Btn_Start = nil
--def.field("userdata")._Img_Enter1 = nil
def.field("userdata")._Btn_Show = nil
def.field("userdata")._Lab_Remind= nil

def.field("userdata")._Frame_Activity = nil
def.field("userdata")._Bar_HP = nil
def.field("userdata")._Bar_Scoll = nil
def.field("userdata")._Lab_HPInfo = nil
def.field("userdata")._Lab_HPPercent = nil

local instance = nil
def.static("=>", CPanelUIGuildConvoy).Instance = function()
	if not instance then
		instance = CPanelUIGuildConvoy()
		instance._PrefabPath = PATH.UI_Guild_Convoy
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local OnNotifyGuildEvent = function(sender, event)
	if not IsNil(instance._Panel) then
		if event.Type == "GuildConvoyUpdate" then
			instance:UpdateConvoy(sender)
		elseif event.Type == "GuildConvoyComplete" then
			instance:OnConvoyComplete()
		end
	end
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitObject()
	self:OnInit()

	CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)
	self._HelpUrlType = HelpPageUrlType.Guild_Convoy
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	local state = data.BaseInfo.ActState
	local level = StringTable.Get(8076)
	local convoy = CElementData.GetTemplate("GuildConvoy", data.BaseInfo.ConvoyId)
	if convoy ~= nil then
		local map = CElementData.GetTemplate("Map", convoy.MapTId)
		level = map.LimitEnterLevel
	end
	GUI.SetText(self._Lab_Level_Num, tostring(level))
	local guildName = StringTable.Get(8076)
	if data.EnermyGuildName ~= "" then
		guildName = data.EnermyGuildName
	end
	GUI.SetText(self._Lab_Enemy_Num, guildName)
	local signLab = StringTable.Get(8078)
	if self._Is_Leader then
		signLab = StringTable.Get(8077)
	end
	GUI.SetText(self._Lab0, signLab)
	if state == EConvoyActState.EConvoyActState_Default then
		self._Btn_Sign:SetActive(true)
		self._Btn_Show:SetActive(false)
		self._Btn_Start:SetActive(false)
	elseif state == EConvoyActState.EConvoyActState_ApplyEnd then
		self._Btn_Sign:SetActive(false)
		self._Btn_Show:SetActive(true)
		self._Btn_Start:SetActive(false)
	elseif state == EConvoyActState.EConvoyActState_Convoy or state == EConvoyActState.EConvoyActState_MatchEnd then
		self._Btn_Sign:SetActive(false)
		self._Btn_Show:SetActive(false)
		self._Btn_Start:SetActive(true)
	else
		self._Btn_Sign:SetActive(true)
		self._Btn_Show:SetActive(false)
		self._Btn_Start:SetActive(false)
	end
	if state == EConvoyActState.EConvoyActState_Convoy then
		self._Frame_Activity:SetActive(true)
	else
		self._Frame_Activity:SetActive(false)
	end
	GameUtil.SetButtonInteractable(self._Btn_Sign, self._Is_Leader)
    GUITools.SetBtnGray(self._Btn_Sign, not self._Is_Leader)
--	GameUtil.MakeImageGray(self._Img_Enter0, not self._Is_Leader)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
    	TODO(StringTable.Get(19))
	elseif id == "Btn_Member_Set" then
		self:OnBtnMemberSet()
	elseif id == "Btn_Search" then
		self:OnBtnSearch()
	elseif id == "Btn_Sign" then
		self:OnBtnSign()
	elseif id == "Btn_Start" then
		self:OnBtnStart()
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_Reward" then
    	index = index + 1
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local data = self._RewardData[index]
		local setting =
		{
			[EItemIconTag.Probability] = data.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
		}
		IconTools.InitItemIconNew(uiTemplate:GetControl(0), data.Data.Id, setting)
    end
end

-- 选中列表按钮
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Reward" then
    	index = index + 1
		local itemTid = self._RewardData[index].Data.Id
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
    end
end

def.method().OnInit = function(self)
	local text1 = StringTable.Get(575)
	local text2 = StringTable.Get(576)
	local text3 = StringTable.Get(577)
	GUI.SetText(self._Lab_Des, text1)
	GUI.SetText(self._Lab_Sign_Num, text2)
	GUI.SetText(self._Lab_Open_Num, text3)
	local rewardList = GUITools.GetRewardList(CSpecialIdMan.Get("GuildConvoyReward"), false)
	self._RewardData = {}
	self._MoneyData = {}
	for i, v in ipairs(rewardList) do
		if v.IsTokenMoney then
			table.insert(self._MoneyData, v)
		else
			table.insert(self._RewardData, v)
		end
	end
	self._RewardList:SetItemCount(#self._RewardData)
	if self._MoneyData[1] ~= nil then
		self._Frame_OtherReward_1:SetActive(true)
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, self._MoneyData[1].Data.Id)
		GUI.SetText(self._Lab_OtherReward_1, tostring(self._MoneyData[1].Data.Count))
	else
		self._Frame_OtherReward_1:SetActive(false)
	end
	if self._MoneyData[2] ~= nil then
		self._Frame_OtherReward_2:SetActive(true)
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, self._MoneyData[2].Data.Id)
		GUI.SetText(self._Lab_OtherReward_2, tostring(self._MoneyData[2].Data.Count))
	else
		self._Frame_OtherReward_2:SetActive(false)
	end
	local member = game._GuildMan:GetHostGuildMemberInfo()
	self._Is_Leader = (member ~= nil and member._RoleType == MemberType.GuildLeader)
	self._Btn_Member_Set:SetActive(self._Is_Leader)
end

def.method().OnInitObject = function(self)
	self._Lab_Des = self:GetUIObject("Lab_Des")
	self._RewardList = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Lab_Level_Num = self:GetUIObject("Lab_Level_Num")
	self._Lab_Member_Num = self:GetUIObject("Lab_Member_Num")
	self._Btn_Member_Set = self:GetUIObject("Btn_Member_Set")
	self._Lab_Sign_Num = self:GetUIObject("Lab_Sign_Num")
	self._Lab_Open_Num = self:GetUIObject("Lab_Open_Num")
	self._Lab_Enemy_Num = self:GetUIObject("Lab_Enemy_Num")
	self._Btn_Sign = self:GetUIObject("Btn_Sign")
	self._Img_Enter0 = self:GetUIObject("Img_Enter0")
	self._Lab0 = self:GetUIObject("Lab0")
	self._Btn_Start = self:GetUIObject("Btn_Start")
	--self._Img_Enter1 = self:GetUIObject("Img_Enter1")
	self._Btn_Show = self:GetUIObject("Btn_Show")
	self._Lab_Remind = self:GetUIObject("Lab_Remind")

	self._Frame_Activity = self:GetUIObject("Frame_Activity")
	self._Bar_HP = self:GetUIObject("Bar_HP")
	self._Bar_HP:SetActive(false)
	self._Bar_Scoll = self._Bar_HP:GetComponent(ClassType.Scrollbar)
	self._Lab_HPInfo = self:GetUIObject("Lab_HPInfo")
	self._Lab_HPPercent = self:GetUIObject("Lab_HPPercent")

	local bg = self:GetUIObject("Img_BG")
	local img_che = self:GetUIObject("Img_Che")
	GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_Sfx_ImgBG,bg,bg,-1)
	GameUtil.PlayUISfx(PATH.UI_Guild_Convoy_Sfx_ImgChe,img_che,img_che,-1)
end

-- 设置准入人员
def.method().OnBtnMemberSet = function(self)
	game._GUIMan:ShowTipText(StringTable.Get(8072), true)
end

-- 查看对手
def.method().OnBtnSearch = function(self)
	local name = self._Lab_Enemy_Num:GetComponent(ClassType.Text).text
	if name == StringTable.Get(8076) then
		return
	end
	self:OnC2SGuildConvoyMatchRes()
end

-- 点击报名
def.method().OnBtnSign = function(self)
	local callback = function(value)
		if value then
			self:OnC2SGuildConvoyApply()
		end
	end
	local title, msg, closeType = StringTable.GetMsg(95)
	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

-- 报名成功刷新
def.method().ShowBtnSign = function(self)
	self._Btn_Sign:SetActive(false)
	self._Btn_Show:SetActive(true)
end

-- 开始护送
def.method().OnBtnStart = function(self)
	self:OnC2SGuildConvoyJoin()
end

-- 公会护送报名
def.method().OnC2SGuildConvoyApply = function(self)
	local protocol = (require "PB.net".C2SGuildConvoyApply)()
	PBHelper.Send(protocol)
end

-- 公会护送匹配结果
def.method().OnC2SGuildConvoyMatchRes = function(self)
	local protocol = (require "PB.net".C2SGuildConvoyMatchRes)()
	PBHelper.Send(protocol)
end

-- 公会开始护送
def.method().OnC2SGuildConvoyJoin = function(self)
	local protocol = (require "PB.net".C2SGuildConvoyJoin)()
	PBHelper.Send(protocol)
end

-- 界面实时刷新
def.method("table").UpdateConvoy = function(self, data)
	if data.EConvoyActState == EConvoyActState.EConvoyActState_Convoy then
		self._Btn_Sign:SetActive(false)
		self._Btn_Show:SetActive(false)
		self._Btn_Start:SetActive(true)
		self._Frame_Activity:SetActive(true)
	end
	if data.UpdateType == EConvoyUpdateType.EConvoyUpdateType_EntityInfo then
		local entity = data.ConvoyEntity		
		if self._Should_Set_HPInfo then
			self._Bar_HP:SetActive(true)
        	local npc = CElementData.GetTemplate("Npc", entity.NpcTid)
        	GUI.SetText(self._Lab_HPInfo, npc.TextOverlayDisplayName)
        	self._Should_Set_HPInfo = false
        end
        local percent = entity.CurrentHp / entity.MaxHp
    	self._Bar_Scoll.size = percent
    	GUI.SetText(self._Lab_HPPercent, entity.CurrentHp .. "/" .. entity.MaxHp)
    end
end

-- 护送结束刷新
def.method().OnConvoyComplete = function(self)
	self._Btn_Sign:SetActive(true)
	self._Btn_Show:SetActive(false)
	self._Btn_Start:SetActive(false)
	self._Frame_Activity:SetActive(false)
end

CPanelUIGuildConvoy.Commit()
return CPanelUIGuildConvoy