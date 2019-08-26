local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local QuestDef = require "Quest.QuestDef"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CPanelUIQuestReward = Lplus.Extend(CPanelBase, "CPanelUIQuestReward")
local def = CPanelUIQuestReward.define

def.field("userdata")._Lab_QuestChapterName = nil 
def.field("userdata")._List_Reward = nil 
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Element_ListReward = nil
def.field("userdata")._Element_OtherReward = nil
def.field("userdata")._Img_Title = nil


local instance = nil
def.static("=>", CPanelUIQuestReward).Instance = function()
	if not instance then
		instance = CPanelUIQuestReward()
		instance._PrefabPath = PATH.UI_QuestReward
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Lab_QuestChapterName = self:GetUIObject("Lab_QuestChatperName")

	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Element_ListReward = self:GetUIObject("Element_ListReward")
	self._Element_OtherReward = self:GetUIObject("Element_OtherReward")
	self._Img_Title = self:GetUIObject("Img_Title")
	
	--self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)

end

-- 设置其他奖励
local function SetOtherReward(self, rewardTid)
	if rewardTid <= 0 then return end

    local rewardList = GUITools.GetRewardList(rewardTid, true)
    if rewardList == nil then return end

    local moneyRewardList = {}
    for _, v in ipairs(rewardList) do
        if v.IsTokenMoney then
            table.insert(moneyRewardList, v.Data)
        else
        end
    end

    self._Element_OtherReward:SetActive((moneyRewardList ~= nil and moneyRewardList[1] ~= nil) or (moneyRewardList ~= nil and moneyRewardList[2] ~= nil))
	if moneyRewardList ~= nil and moneyRewardList[1] ~= nil then
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, moneyRewardList[1].Id)
		GUI.SetText(self._Lab_OtherReward_1, GUITools.FormatMoney( moneyRewardList[1].Count ))
	end

	if moneyRewardList ~= nil and moneyRewardList[2] ~= nil then
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, moneyRewardList[2].Id)
		GUI.SetText(self._Lab_OtherReward_2, GUITools.FormatMoney( moneyRewardList[2].Count ))
	end
end

local rewards = nil
def.override("dynamic").OnData = function(self, data)
    self._OnTipFinishCB = data.OnFinish
	--local quest_data = CElementData.GetQuestTemplate(data._QuestId)

	local quest_model = CQuest.Instance():FetchQuestModel(data._QuestId)
	local quest_data = quest_model:GetTemplate()
	GUI.SetText(self._Lab_QuestChapterName, quest_data.TextDisplayName )

    -- if quest_data.IsPartentQuest then
    --     quest_data = CElementData.GetQuestTemplate(quest_model.CurrentSubQuestId)
    -- end

    local reward_temp = CElementData.GetRewardTemplate(quest_data.RewardId)

    if reward_temp == nil then
    	self._Element_ListReward:SetActive(false)
        self._List_Reward:SetItemCount(0)
    else
        rewards = GUITools.GetRewardList(quest_data.RewardId, false)
        if #rewards > 0 then
	        self._Element_ListReward:SetActive(true)
        	self._List_Reward:SetItemCount(#rewards)
    	    local rc = self._List_Reward.gameObject:GetComponent(ClassType.RectTransform)
		    rc.anchorMin = Vector2.New(0.5,1)
			rc.anchorMax = Vector2.New(0.5,1)
		    rc.pivot = Vector2.New(0.5,1)
		    rc.anchoredPosition = Vector2.New(0,rc.anchoredPosition.y)
        else
	        self._Element_ListReward:SetActive(false)
        	--self._List_Reward:SetItemCount(#rewards)
        end

    end   
    SetOtherReward(self, quest_data.RewardId)

    CQuestAutoMan.Instance():Pause(_G.PauseMask.UIShown)	
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Quest_Complete, 0)

    GameUtil.PlayUISfx(PATH.UIFX_QuestN_Reward, self._Panel, self._Panel, -1)
    GameUtil.PlayUISfx(PATH.UIFX_MainTip_Mission_Success, self._Img_Title, self._Img_Title, -1)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == 'List_Reward' then 
		local rewardData = rewards[idx]
		if rewardData ~= nil then
			local frame_icon = GUITools.GetChild(item, 0)
			if rewardData.IsTokenMoney then
				IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
			else
				IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id, { [EItemIconTag.Number] = rewardData.Data.Count })
			end
		end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == 'List_Reward' then    
        local rewardData = rewards[index + 1]
        if not rewardData.IsTokenMoney then
            CItemTipMan.ShowItemTips(rewardData.Data.Id, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        else
            local panelData = 
                {
                    _MoneyID = rewardData.Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item ,
                }
                CItemTipMan.ShowMoneyTips(panelData)
        end
    end
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_FinishQuest" then
		if #rewards > 0 then
			for i,v in ipairs( rewards ) do
				if not v.IsTokenMoney then
					--local itemtemp = CElementData.GetItemTemplate( v.Data.Id )
					--print("111111111111111111111",v.Data.Id,itemtemp.BindType,v.Data.Count,game._HostPlayer:HasEnoughSpace( v.Data.Id,true,v.Data.Count ))
					if not game._HostPlayer:HasEnoughSpace( v.Data.Id,true,v.Data.Count ) then
						game._GUIMan:ShowTipText(StringTable.Get(276), false)
						game._GUIMan:CloseByScript(self)
						--print("222222222222222222",v.Data.Id,true,v.Data.Count)
						return
					end
				end
			end
		end
		self:FinishCB()
		game._GUIMan:CloseByScript(self)
		CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
	elseif id == "Btn_Cancel" then
		game._GUIMan:CloseByScript(self)
	end
end

def.override().OnHide = function(self)
	self._Lab_QuestChapterName = nil
	self._Frame_OtherReward_1 = nil
	self._Img_OtherReward_1 = nil
	self._Lab_OtherReward_1 = nil
	self._Frame_OtherReward_2 = nil
	self._Img_OtherReward_2 = nil
	self._Lab_OtherReward_2 = nil
	self._Element_ListReward = nil
	self._Element_OtherReward = nil
	self._Img_Title = nil
	rewards = nil
	--self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = nil
	--game._GUIMan:CloseByScript(self)
end

def.field("function")._OnTipFinishCB = nil
def.method().FinishCB = function(self)
    if self._OnTipFinishCB ~= nil then
        self._OnTipFinishCB()
        self._OnTipFinishCB = nil
    end
end

CPanelUIQuestReward.Commit()
return CPanelUIQuestReward