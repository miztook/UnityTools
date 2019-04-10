--
--公会防守主界面
--
--【孟令康】
--
--2018年05月23日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUIGuildDefend = Lplus.Extend(CPanelBase, "CPanelUIGuildDefend")
local def = CPanelUIGuildDefend.define

def.field("table")._RewardData = nil
def.field("table")._MoneyData = nil

def.field("userdata")._Lab_Number0 = nil
def.field("userdata")._Lab_Des = nil
def.field("userdata")._RewardList = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Lab_Open_Num = nil
def.field("userdata")._Lab_Battle_Num = nil
def.field("userdata")._Lab_Activity_Num = nil
def.field("userdata")._Btn_Enter = nil
def.field("userdata")._Img_Enter = nil

local instance = nil
def.static("=>", CPanelUIGuildDefend).Instance = function()
	if not instance then
		instance = CPanelUIGuildDefend()
		instance._PrefabPath = PATH.UI_Guild_Defend
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitObject()
	self:OnInit()
	self._HelpUrlType = HelpPageUrlType.Guild_Defend
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	GUI.SetText(self._Lab_Number0, string.format(StringTable.Get(8085), data.CurRound))
	local guildDefend = CElementData.GetTemplate("GuildDefend", data.CurRound)
	local rewardList = GUITools.GetRewardList(guildDefend.RewardId, false)
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
	GUI.SetText(self._Lab_Battle_Num, tostring(guildDefend.Score))
	if data.ActiviyOpenFlag then
		GUI.SetText(self._Lab_Activity_Num, StringTable.Get(8083))
	else
		GUI.SetText(self._Lab_Activity_Num, StringTable.Get(8084))
	end
	GameUtil.SetButtonInteractable(self._Btn_Enter, data.ActiviyOpenFlag)
    GUITools.SetBtnGray(self._Btn_Enter, not data.ActiviyOpenFlag)
	--GameUtil.MakeImageGray(self._Img_Enter, not data.ActiviyOpenFlag)


end

-- 当摧毁
def.override().OnDestroy = function(self)
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
    elseif id == "Btn_Enter" then
    	self:OnBtnEnter()
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
	local text1 = StringTable.Get(578)
	local text2 = StringTable.Get(579)
	GUI.SetText(self._Lab_Des, text1)
	GUI.SetText(self._Lab_Open_Num, text2)
	local bg2 = self:GetUIObject("Img_Ta_2")
	GameUtil.PlayUISfx(PATH.UI_Guild_Defend_bg2_sfx,bg2,bg2,-1)
    local frame_left = self:GetUIObject("Frame_Left")
    local dotween_player = frame_left:GetComponent(ClassType.DOTweenPlayer)
    dotween_player:Restart("shuijing")
end

def.method().OnInitObject = function(self)
	self._Lab_Number0 = self:GetUIObject("Lab_Number")
	self._Lab_Des = self:GetUIObject("Lab_Des")
	self._RewardList = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)
	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Lab_Open_Num = self:GetUIObject("Lab_Open_Num")
	self._Lab_Battle_Num = self:GetUIObject("Lab_Battle_Num")
	self._Lab_Activity_Num = self:GetUIObject("Lab_Activity_Num")
	self._Btn_Enter = self:GetUIObject("Btn_Enter")
	self._Img_Enter = self:GetUIObject("Img_Enter")	
end

-- 进入公会防守
def.method().OnBtnEnter = function(self)
	game._GuildMan:EnterGuildMap()
end

CPanelUIGuildDefend.Commit()
return CPanelUIGuildDefend