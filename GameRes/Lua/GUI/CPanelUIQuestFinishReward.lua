local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local QuestDef = require "Quest.QuestDef"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CPanelUIQuestFinishReward = Lplus.Extend(CPanelBase, "CPanelUIQuestFinishReward")
local def = CPanelUIQuestFinishReward.define

def.field("userdata")._Lab_QuestChapterName = nil 
def.field("userdata")._Lab_QuestGroupName = nil 
def.field("userdata")._List_Reward = nil 
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field("userdata")._Element_ListReward = nil
def.field("userdata")._Element_OtherReward = nil



local instance = nil
def.static("=>", CPanelUIQuestFinishReward).Instance = function()
	if not instance then
		instance = CPanelUIQuestFinishReward()
		instance._PrefabPath = PATH.UI_QuestFinishReward
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._Lab_QuestChapterName = self:GetUIObject("Lab_QuestChatperName")
	self._Lab_QuestGroupName = self:GetUIObject("Lab_QuestGroupName")

	self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
	self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
	self._Element_ListReward = self:GetUIObject("Element_ListReward")
	self._Element_OtherReward = self:GetUIObject("Element_OtherReward")
	
	
	--self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = self:GetUIObject("List_Reward"):GetComponent(ClassType.GNewList)

end

-- 设置其他奖励
local function SetOtherReward(self, rewardTid)
	if rewardTid <= 0 then return end
	-- local template = CElementData.GetRewardTemplate(rewardTid)
	-- if template == nil then return end

	-- self._Element_OtherReward:SetActive(template.MoneyId1 > 0 or template.MoneyId2 > 0 )
	-- GUITools.SetUIActive(self._Frame_OtherReward_1, template.MoneyId1 > 0)
	-- if template.MoneyId1 > 0 then
	-- 	GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, template.MoneyId1)
	-- 	GUI.SetText(self._Lab_OtherReward_1, tostring(template.MoneyNum1))
	-- end
	-- GUITools.SetUIActive(self._Frame_OtherReward_2, template.MoneyId2 > 0)
	-- if template.MoneyId2 > 0 then
	-- 	GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, template.MoneyId2)
	-- 	GUI.SetText(self._Lab_OtherReward_2, tostring(template.MoneyNum2))
	-- end




    local rewardList = GUITools.GetRewardList(rewardTid, true)
    if rewardList == nil then return end

    local moneyRewardList = {}
    --self._RewardsData = {}
    for _, v in ipairs(rewardList) do
        if v.IsTokenMoney then
            table.insert(moneyRewardList, v.Data)
        else
            --table.insert(self._RewardsData, v)
        end
    end

    self._Element_OtherReward:SetActive((moneyRewardList ~= nil and moneyRewardList[1] ~= nil) or (moneyRewardList ~= nil and moneyRewardList[2] ~= nil))
	--local enable = false
	if moneyRewardList ~= nil and moneyRewardList[1] ~= nil then
		--enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, moneyRewardList[1].Id)
		GUI.SetText(self._Lab_OtherReward_1, tostring(moneyRewardList[1].Count))
	end
	--GUITools.SetUIActive(self._Frame_OtherReward_1, enable)

	--enable = false
	if moneyRewardList ~= nil and moneyRewardList[2] ~= nil then
		--enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, moneyRewardList[2].Id)
		GUI.SetText(self._Lab_OtherReward_2, tostring(moneyRewardList[2].Count))
	end
	--GUITools.SetUIActive(self._Frame_OtherReward_2, enable)
end

local rewards = nil
def.override("dynamic").OnData = function(self, data)
    self._OnTipFinishCB = data.OnFinish
	local quest_data = CElementData.GetQuestTemplate(data._QuestId)
 	local chapterTip = string.split(quest_data.QuestChapterInfo, ".")
    if chapterTip ~= nil and chapterTip[1] ~= "nil"  and chapterTip[1] ~= "" then
    	local ChapterTemplate = CElementData.GetTemplate("QuestChapter", tonumber(chapterTip[1]))
        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(chapterTip[2]))
        if ChapterTemplate ~= nil then
	        local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
	         if Groups ~= nil and Groups[1] ~= "" then 
    			-- local GroupsIndex = 1
    			-- for i,v in ipairs(Groups) do
    			-- 	if v == chapterTip[2] then
    			-- 		GroupsIndex = i
    			-- 		break
    			-- 	end
    			-- end
    			local str = ""
    			-- if quest_data.Type == QuestDef.QuestType.Main then
	    		-- 	--str = "["
	    		-- 	if ChapterTemplate.OpenNotify ~= nil then
	    		-- 		--str = str.."<color=#FFAE00FF>"..ChapterTemplate.ChapterId..'-'..GroupsIndex..' '..ChapterTemplate.OpenNotify.."</color>"
	    		-- 		str = str..ChapterTemplate.ChapterId..'-'..GroupsIndex..' '..ChapterTemplate.OpenNotify
	    		-- 	end
	    		-- 	--str = str .." - "
	    		-- 	if GroupTemplate.OpenNotify ~= nil then
	    		-- 	   str = str..GroupTemplate.OpenNotify
	    		-- 	end
	    		-- 	--str = str.."]"
	    		-- else
	    		-- 	--str = "["
	    		-- 	if ChapterTemplate.OpenNotify ~= nil then
	    		-- 		str = str..ChapterTemplate.OpenNotify
	    		-- 	end
	    		-- 	--str = str .." - "
	    		-- 	if GroupTemplate.OpenNotify ~= nil then
	    		-- 	   str = str..GroupTemplate.OpenNotify
	    		-- 	end
	    		-- 	--str = str.."]"
	    		-- end
	    		str = ChapterTemplate.OpenNotify .. ' - ' .. GroupTemplate.OpenNotify
    			GUI.SetText(self._Lab_QuestChapterName, str )
	    	end
	    end
    end

    GUI.SetText(self._Lab_QuestGroupName, quest_data.TextDisplayName )

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
    self:AddTimer()
end

def.field("number")._TimerId = 0
def.method().AddTimer = function (self)
	local callback = function()
		game._GUIMan:CloseByScript(self)
	end
    self._TimerId = _G.AddGlobalTimer(3, true ,callback)
end

def.method().RemoveTimer = function(self)
    if self._TimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end
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

-- def.override("string").OnClick = function(self, id)
-- 	if id == "Btn_Continue" then
-- 		game._GUIMan:CloseByScript(self)
-- 	end
-- end

def.override().OnHide = function(self)
	self:RemoveTimer()
	self._Lab_QuestChapterName = nil
	self._Lab_QuestGroupName = nil
	self._Frame_OtherReward_1 = nil
	self._Img_OtherReward_1 = nil
	self._Lab_OtherReward_1 = nil
	self._Frame_OtherReward_2 = nil
	self._Img_OtherReward_2 = nil
	self._Lab_OtherReward_2 = nil
	self._Element_ListReward = nil
	self._Element_OtherReward = nil

	self._TimerId = 0
	rewards = nil
	--self._View_Reward = self:GetUIObject("View_Reward")
	self._List_Reward = nil
	--game._GUIMan:CloseByScript(self)
	CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)

    self:DoTipFinishCB()
end

def.field("function")._OnTipFinishCB = nil
def.method().DoTipFinishCB = function(self)
    if self._OnTipFinishCB ~= nil then
        self._OnTipFinishCB()
        self._OnTipFinishCB = nil
    end
end

CPanelUIQuestFinishReward.Commit()
return CPanelUIQuestFinishReward