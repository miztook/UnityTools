
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CQuest = require "Quest.CQuest"
local CElementData = require "Data.CElementData"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CAutoFightMan = require "AutoFight.CAutoFightMan"

local CPanelReputationIntroduction = Lplus.Extend(CPanelBase, 'CPanelReputationIntroduction')
local def = CPanelReputationIntroduction.define
 
def.field('userdata')._List_Item = nil
def.field('userdata')._Lab_Target = nil
def.field('userdata')._Lab_Content = nil
def.field("userdata")._Lab_Title = nil 
def.field("table")._RewardItemList = nil 
def.field("number")._QuestId = 0 
def.field("boolean")._IsClosePanel = false
def.field("function")._CallBack = nil 

local instance = nil
def.static('=>', CPanelReputationIntroduction).Instance = function ()
	if not instance then
        instance = CPanelReputationIntroduction()
        instance._PrefabPath = PATH.UI_ReputationIntroduction
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end


def.override().OnCreate = function(self)
    self._Lab_Title = self:GetUIObject('Lab_Title')
    self._List_Item = self:GetUIObject('List_Item'):GetComponent(ClassType.GNewList)
    self._Lab_Content = self:GetUIObject('Lab_Content')
end

def.override("dynamic").OnData = function(self, data)
    self._QuestId = data.QuestId
    GUI.SetText(self._Lab_Content,data.QuestTemplate.TextDescription)
    GUI.SetText(self._Lab_Title,data.QuestTemplate.TextDisplayName)

    --找到此循环任务链最后一个奖励目标
    local quest_template = data.QuestTemplate
    if quest_template ~= nil then
        while true do
            local tmpNextQuestId = quest_template.DeliverRelated.NextQuestId
            local template = nil
            if tmpNextQuestId > 0 then
                template = CElementData.GetQuestTemplate(tmpNextQuestId)
            end
           if template ~= nil then
            quest_template = template
            --print("========111",quest_template.Id)
           else
             break
           end
        end

        --print("========222",quest_template.Id)

        self._RewardItemList = GUITools.GetRewardList(quest_template.RewardId,true)
        self._List_Item:SetItemCount(#self._RewardItemList)
        self._IsClosePanel = data.IsClosePanel
        if data.OkCallBack ~= nil then 
            self._CallBack = data.OkCallBack 
        end
    end
end


def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Yes' then
        CQuestAutoMan.Instance():Stop()
        CAutoFightMan.Instance():Stop()
        local lastID = CQuest.Instance():GetReputationListCurQuestID(self._QuestId)
        local questmodel = CQuest.Instance():FetchQuestModel(lastID)
        if questmodel ~= nil then
            questmodel:DoShortcut()
            if self._IsClosePanel then 
                game._GUIMan:Close("CPanelMap")
                game._GUIMan:Close("CPanelUIQuestList")
            end
            if self._CallBack ~= nil then 
                self._CallBack()
            end
            game._GUIMan:CloseByScript(self)
            return
        end
    elseif id == "Btn_Back" then 
        game._GUIMan:CloseByScript(self)
    end

end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local frame_icon = GUITools.GetChild(item, 0)
    local data = self._RewardItemList[index + 1]
    if data.IsTokenMoney then
        IconTools.InitTokenMoneyIcon(frame_icon, data.Data.Id, data.Data.Count)
    else
        IconTools.InitItemIconNew(frame_icon, data.Data.Id, { [EItemIconTag.Number] = data.Data.Count})
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local data = self._RewardItemList[index + 1]
    if data.IsTokenMoney then
        local panelData = 
                        {
                            _MoneyID = data.Data.Id,
                            _TipPos = TipPosition.FIX_POSITION,
                            _TargetObj = nil, 
                        } 
        CItemTipMan.ShowMoneyTips(panelData)
    else
        CItemTipMan.ShowItemTips(data.Data.Id, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
    end
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelReputationIntroduction.Commit()
return CPanelReputationIntroduction