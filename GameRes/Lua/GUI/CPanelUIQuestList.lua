local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local QuestDef = require "Quest.QuestDef"
local CQuestModel = require "Quest.CQuestModel"
local CNPCServiceHdl = require "ObjHdl.CNPCServiceHdl"
local CQuestNavigation = require"Quest.CQuestNavigation"
local CTeamMan = require "Team.CTeamMan"
local MapBasicConfig = require "Data.MapBasicConfig"
local CTransManage = require "Main.CTransManage"
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = Lplus.ForwardDeclare("CQuest")
local CQuestAutoMan = require"Quest.CQuestAutoMan"                  
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require"Dungeon.CDungeonAutoMan"
local CPanelMap = require "GUI.CPanelMap"

local CPanelUIQuestList = Lplus.Extend(CPanelBase, 'CPanelUIQuestList')
local def = CPanelUIQuestList.define

def.field("table")._QuestChapters = BlankTable 
def.field("table")._ToggleTable = nil -- 六个页签的toggle
def.field("table")._ToggleTableRed = nil -- 页签红点
def.field("table")._ChaptersTemplate_id_list = nil --缓存所有章节ID模板
def.field("table")._QuestsCanRecievedTalbe = nil   --缓存可以接到的任务


def.field('userdata')._List_Quest = nil                 --左边章节目录
def.field('userdata')._List_QuestParent = nil           --左边章节目录2
def.field('userdata')._List_ElementsReward = nil         --任务奖励列表

--def.field("table")._List_QuestChapter = nil        --
def.field("userdata")._Drop_QuestChapter = nil       --任务章节下拉菜单控件

def.field('userdata')._Lab_ChapterName = nil         --任务章节名称
def.field('userdata')._Lab_ChapterDes = nil          --任务章节描述
--def.field('userdata')._Lab_Diamond = nil             --任务组完成后的钻石奖励
--def.field('userdata')._Lab_DiamondFinish = nil       --任务组完成后的钻石奖励领取完成
def.field('userdata')._Lab_QuestProvide = nil        --任务发放文本

--def.field('userdata')._Btn_Reward = nil              --任务组奖励按钮
def.field('userdata')._Btn_GiveUp = nil              --任务放弃按钮
def.field('userdata')._Btn_Go = nil                  --任务开始按钮


def.field('table')._TargetsTable = nil               --任务目标


def.field("userdata")._Frame_ElementsContainer = nil --具体内容
def.field("userdata")._Frame_CurQuest = nil --具体任务任务内容
def.field("userdata")._Lyout_Content = nil --具体任务可滑动内容
def.field('userdata')._Frame_ChapterReward = nil --奖励界面
def.field('userdata')._Frame_RewardScroll = nil --章节奖励条
def.field('userdata')._Img_RewardFront = nil --章节奖励条2
def.field('userdata')._Frame_Reward = nil   --具体任务奖励界面
def.field('userdata')._Frame_NoQuest = nil   --无任务界面
def.field("userdata")._Img_Map = nil --任务地图
def.field('userdata')._Obj_Quest = nil
def.field('userdata')._Scroll_Reward = nil
def.field('userdata')._FrameTopTabs = nil

def.field('table')._Current_SelectChapterReward = nil --当前章节奖励数据

def.field('table')._Current_SelectData = nil
def.field('table')._Current_SelectGroupData = nil
def.field("boolean")._IsTabOpen = false
def.field("number")._CurFrameType = 0
def.field("number")._CurrentSelectTabIndex = -1
--def.field("number")._CurrentSelectTabIndex2 = -1
def.field("number")._CurrentSelectQuestID = 0
def.field("number")._CurrentChapterIndex = -1
--（除主线，支线外）任务组专用
--def.field("table")._QuestGroups = BlankTable 
--def.field("table")._GroupsTemplate_id_list = nil --缓存所有任务组ID模板
def.field('userdata')._List_ElementsRepeat = nil          
def.field("userdata")._Frame_ElementContainerRepeat = nil --任务组具体内容
--声望任务相关
def.field('userdata')._Frame_ElementReputation = nil --声望任务页面
def.field('userdata')._List_ElementsReputation = nil 
def.field('userdata')._Frame_ReputationContent = nil 
def.field('userdata')._Lab_ReputationName = nil 
def.field('userdata')._Lab_ReputationNameE = nil 
def.field('userdata')._Lab_ReputationDes = nil 
def.field('userdata')._Img_ReputationIcon = nil 
def.field('userdata')._Lab_ReputationLvIcon = nil 
def.field('userdata')._List_ReputationReward = nil 
def.field('userdata')._Lab_ReputationShopDes = nil 
def.field('userdata')._Lab_ReputationProgress = nil 
def.field('userdata')._Img_Front = nil 
def.field("userdata")._Btn_GoReputationNpc = nil
def.field("userdata")._Lab_ReputationFinishQuest = nil

local Table_QuestObj = {} --所有任务的图标

local instance = nil
def.static('=>', CPanelUIQuestList).Instance = function ()
    if not instance then
        instance = CPanelUIQuestList()
        instance._PrefabPath = PATH.UI_QuestList
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        
        instance:SetupSortingParam()
    end
    return instance
end

local function OnQuestEvents(sender, event)
    local name = event._Name
    local data = event._Data
    if name == EnumDef.QuestEventNames.QUEST_INIT then
    elseif name == EnumDef.QuestEventNames.QUEST_RECIEVE then       --接任务
        if instance._CurFrameType-1 == QuestDef.QuestType.Main or instance._CurFrameType-1 == QuestDef.QuestType.Branch then
            instance:ShowMainAndBreachFrame(true)
        elseif instance._CurFrameType == 4 then
            instance:ShowReputationFrame(true)
        else
            instance:ShowOtherFrame()
        end
    -- elseif name == EnumDef.QuestEventNames.QUEST_COMPLETE then      --交任务
    -- elseif name == EnumDef.QuestEventNames.QUEST_CHANGE then        --任务数量变化
    -- elseif name == EnumDef.QuestEventNames.QUEST_GIVEUP then        --放弃任务
    -- elseif name == EnumDef.QuestEventNames.QUEST_TIME then      --任务时间
    end
end

def.override().OnCreate = function(self)
    self._List_QuestParent = self:GetUIObject("List_Quest")
    self._List_Quest = self:GetUIObject("List_Quest"):GetComponent(ClassType.GNewTabList)
    self._List_ElementsReward = self:GetUIObject("List_ElementsReward"):GetComponent(ClassType.GNewListLoop)
    self._Drop_QuestChapter = self:GetUIObject("Drop_Group_QuestChapter")

    self._Lab_ChapterName = self:GetUIObject("Lab_ChapterName")
    self._Lab_ChapterDes = self:GetUIObject("Lab_ChapterDes")
    --self._Btn_Reward = self:GetUIObject("Btn_Reward")
    self._Btn_GiveUp = self:GetUIObject("Btn_GiveUp")
    self._Btn_Go = self:GetUIObject("Btn_Go")
    -- self._Lab_Diamond = self:GetUIObject("Lab_Diamond")
    -- self._Lab_DiamondFinish = self:GetUIObject("Lab_DiamondFinish")
    self._Lab_QuestProvide = self:GetUIObject("Lab_QuestProvide")
    self._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
    self._Frame_CurQuest = self:GetUIObject("Frame_CurQuest")
    self._Frame_CurQuest:SetActive(false)
    self._Lyout_Content = self:GetUIObject("Lyout_Content")
    self._Frame_ElementsContainer = self:GetUIObject("Frame_ElementContainer")
    self._Frame_ElementsContainer:SetActive(false)
    self._Frame_ChapterReward = self:GetUIObject("Frame_ChapterReward")
    self._Frame_ChapterReward:SetActive(false)
    self._Frame_Reward = self:GetUIObject("Frame_Reward")
    self._Frame_NoQuest = self:GetUIObject("Frame_NoQuest")
    self._Frame_NoQuest:SetActive(false)
    self._Img_Map = self:GetUIObject("Img_Map")
    self._Obj_Quest = self:GetUIObject("Img_Quest")
    self._Obj_Quest: SetActive(false)
    self._Frame_RewardScroll = self:GetUIObject("Frame_RewardScroll")
    self._Img_RewardFront = self:GetUIObject("Img_RewardFront"):GetComponent(ClassType.Image)
    self._List_ElementsRepeat = self:GetUIObject("List_ElementsRepeat"):GetComponent(ClassType.GNewListLoop)
    self._Frame_ElementContainerRepeat = self:GetUIObject("Frame_ElementContainerRepeat")
    self._Frame_ElementContainerRepeat:SetActive(false)
    
    self._Frame_ElementReputation = self:GetUIObject("Frame_ElementReputation")
    self._Frame_ElementReputation:SetActive(false) 
    self._List_ElementsReputation = self:GetUIObject("List_Reputation"):GetComponent(ClassType.GNewTabList)
    self._Frame_ReputationContent = self:GetUIObject("Frame_ReputationContent")
    self._Lab_ReputationName = self:GetUIObject("Lab_ReputationName")
    self._Lab_ReputationNameE = self:GetUIObject("Lab_ReputationNameE")
    self._Lab_ReputationDes = self:GetUIObject("Lab_ReputationDes")
    

    self._Img_ReputationIcon = self:GetUIObject("Img_ReputationIcon")
    self._Lab_ReputationLvIcon = self:GetUIObject("Lab_ReputationLvIcon")
    self._Lab_ReputationShopDes = self:GetUIObject("Lab_ReputationShopDes")
    self._Lab_ReputationProgress = self:GetUIObject("Lab_ReputationProgress")
    self._List_ReputationReward = self:GetUIObject("List_ReputationReward"):GetComponent(ClassType.GNewListLoop)
    self._Img_Front = self:GetUIObject("Img_Front"):GetComponent(ClassType.Image)
    self._Btn_GoReputationNpc = self:GetUIObject("Btn_GoReputationNpc")
    self._Lab_ReputationFinishQuest = self:GetUIObject("Lab_ReputationFinishQuest")
    
    self._TargetsTable = {}
    for i = 1,4 do
        self._TargetsTable[i] = self: GetUIObject("Fram_Targets"..i)
    end

    self._ToggleTable = {}
    for i = 1,4 do
        self._ToggleTable[i] = self: GetUIObject("Rdo_"..i):GetComponent(ClassType.Toggle)
    end

    self._ToggleTableRed = {}
    for i = 1,4 do
        self._ToggleTableRed[i] = self: GetUIObject("Rdo_"..i): FindChild("Img_RedPoint")
        if not IsNil(self._ToggleTableRed[i]) then
            self._ToggleTableRed[i]: SetActive(false)
        end
    end

    CGame.EventManager:addHandler('QuestCommonEvent', OnQuestEvents)
    -- CGame.EventManager:addHandler('QuestReceiveEvent', QuestDataChange)
    -- CGame.EventManager:addHandler('QuestCompleteEvent', QuestDataChange)
    -- CGame.EventManager:addHandler('QuestObjectiveCounterEvent', QuestDataChange)
end

-- -- 页签内是否有红点显示
-- def.method("number","=>", "boolean").IsPageHasRedPoint = function (self,CurType)
--     local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
--     if Map ~= nil then
--         local redDotStatusMap = Map[CurType]
--         if redDotStatusMap ~= nil then
--             for _, status in pairs(redDotStatusMap) do
--                 if status then
--                     -- 有还未显示过的
--                     return true
--                 end
--             end
--         end
--     end
--     return false
-- end

def.method("number","boolean").ShowRedPoint = function (self,CurType,IsInit)
    local isShow = false
    --如果是重复 显示一次后就消失
    if CurType == 1 then
        isShow = CQuest.Instance():IsShowMainQuestRedPoint()
    elseif CurType == 4 then
--[[        local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
        if Map ~= nil then
            local redDotStatusMap = Map[CurType]

            if redDotStatusMap ~= nil then
                local qid = 0
                for k,v in pairs(redDotStatusMap) do
                    if v == true then
                        isShow = true
                        qid = k
                        break
                    end
                end
            end
        end--]]
--[[        local ReputationQuestList = CQuest.Instance():GetCurReputationQuestList()
        isShow = (#ReputationQuestList > 0) --]]
    elseif CurType == 2 then
        isShow = CQuest.Instance():IsShowBranchQuestRedPoint()
    elseif CurType == 3 then
        isShow = CQuest.Instance():IsShowRepeatQuestRedPoint()
    end
    if not IsNil(self._ToggleTableRed[CurType]) then
        self._ToggleTableRed[CurType]:SetActive(isShow)
    end
end


def.method().ShowBranchRedPoint = function (self)
    local isShow = CQuest.Instance():IsShowBranchQuestRedPoint()
    --print(IsShow)
    self._ToggleTableRed[2]:SetActive(isShow)
end

def.method().ShowRepeatRedPoint = function (self)
    local isShow = CQuest.Instance():IsShowRepeatQuestRedPoint()
    --print(IsShow)
    self._ToggleTableRed[3]:SetActive(isShow)
end

def.override("dynamic").OnData = function(self,data)
    self._HelpUrlType = HelpPageUrlType.QuestList
    CPanelBase.OnData(self,data)
    --GameUtil.LayoutTopTabs(self._FrameTopTabs)
    local uiData = nil
    if data ~= nil then

    end

    self._CurFrameType = 1
    self._CurrentSelectTabIndex = 0
    if data ~= nil then
        self._CurFrameType = data.OpenIndex
        if data.OpenIndex2 ~= nil then
            self._CurrentSelectTabIndex = data.OpenIndex2
        end
    end
    if not IsNil(self._ToggleTable[self._CurFrameType]) then
        self._ToggleTable[self._CurFrameType].isOn = true
    end

    self._CurrentChapterIndex = -1
    self._QuestChapters = {}
    self._QuestsCanRecievedTalbe = {}

    --self._QuestGroups = {}
    for i = 1,4 do
        self:ShowRedPoint(i,true)
    end
    self:ShowFrame()
    self:ShowRepeatRedPoint()

    -- 设置下拉菜单层级
    local drop_template = self:GetUIObject("Drop_Template_QuestChapter")
    GUITools.SetupDropdownTemplate(self, drop_template)

    for i = 1,4 do 
        local itemObj = self:GetUIObject("Frame_Gift_0"..i)
        local Lab_GiftPoint = itemObj:FindChild("Lab_GiftPoint"..i)
        GUI.SetText(Lab_GiftPoint, string.format(StringTable.Get(562),i))
    end
end

def.method().ShowFrame = function(self)
    if self._CurFrameType-1 == QuestDef.QuestType.Main or self._CurFrameType-1 == QuestDef.QuestType.Branch then
        self:ShowMainAndBreachFrame(false)
    elseif self._CurFrameType == 4 then
        self:ShowReputationFrame(false)
    else
        self:ShowOtherFrame()
    end

    self:ShowRedPoint(self._CurFrameType,false)
end

local OnDropDownIndex = 0
def.method('boolean').ShowMainAndBreachFrame = function(self,isReset)
    self._CurrentChapterIndex = -1
    self._CurrentSelectTabIndex = -1
    --self._CurrentSelectTabIndex2 = -1
    --分析任务章节，任务组 模板   
    --某一个类型的任务章节
    self._List_QuestParent:SetActive(false)
    self._Frame_ElementsContainer:SetActive(false)
    self._Frame_ElementContainerRepeat:SetActive(false)
    self._Frame_ElementReputation:SetActive(false)
    self._Frame_NoQuest:SetActive(false)
    
    local  QuestTypeChapters = nil
    self._Current_SelectData = nil
    self._Current_SelectGroupData = nil

    if self._QuestChapters[self._CurFrameType] == nil or isReset then
        self._QuestChapters[self._CurFrameType] = {}
        if self._QuestsCanRecievedTalbe[self._CurFrameType] == nil then
            self._QuestsCanRecievedTalbe[self._CurFrameType] = CQuest.Instance():GetQuestsCanRecievedByType(self._CurFrameType)
            --print_r(self._QuestsCanRecievedTalbe[self._CurFrameType])
        end

        --某一个类型的任务章节
        QuestTypeChapters = self._QuestChapters[self._CurFrameType]

        if self._ChaptersTemplate_id_list == nil then
            self._ChaptersTemplate_id_list = GameUtil.GetAllTid("QuestChapter")
        end

        --获得所有章
        for i = 1, #self._ChaptersTemplate_id_list do 
            local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._ChaptersTemplate_id_list[i])
            --print(ChapterTemplate.QuestType,self._CurFrameType)
            if ChapterTemplate.QuestType + 1 == self._CurFrameType then
                --判断这一章是什么状态
                --获得所有节
                local isBreak = false
                local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
                if Groups ~= nil and Groups[1] ~= "" then 
                    for i1, v1 in ipairs(Groups) do
                        if isBreak then
                            break
                        end
                        local GroupsTID = tonumber(v1)           
                        --print("i1,v1===",i1,v1,tonumber(v1))
                        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(v1))
                        for i2,v2 in ipairs(GroupTemplate.GroupFields) do
                            --print("i2,v2===",i2,v2,v2.QuestId)
                            if isBreak then
                                break
                            end

                            if CQuest.Instance()._CompletedMap[v2.QuestId] ~= nil then
                                --print("通过Completed==============",v2.QuestId)
                                -- i 为第几章
                                local QuestChapters = nil
                                for i3,v3 in ipairs(QuestTypeChapters) do
                                    if v3.ChapterTid == self._ChaptersTemplate_id_list[i] then
                                        QuestChapters = v3
                                        break
                                    end
                                end
                                if QuestChapters == nil then
                                    QuestChapters = {}
                                    QuestChapters.ChapterTid = self._ChaptersTemplate_id_list[i]
                                    QuestTypeChapters[#QuestTypeChapters+1] = QuestChapters
                                end
                                if QuestChapters.QuestGroups == nil then
                                    QuestChapters.QuestGroups = {}
                                end

                                local QuestGroups = QuestChapters.QuestGroups 
                                local QuestGroup = nil
                                for i3,v3 in ipairs(QuestGroups) do
                                    if v3.GroupTid == GroupTemplate.Id then
                                        QuestGroup = v3
                                        break
                                    end
                                end
                                if QuestGroup == nil then
                                    QuestGroup = {}
                                    QuestGroup.GroupTid = GroupTemplate.Id
                                    QuestGroups[#QuestGroups+1] = QuestGroup
                                end
                                if QuestGroup.FinishCount == nil then
                                    QuestGroup.FinishCount = 0
                                end
                                --不同点1
                                QuestGroup.IsSelected = false
                                --不同点2
                                QuestGroup.FinishCount = QuestGroup.FinishCount + 1
                            end

                            if CQuest.Instance()._InProgressQuestMap[v2.QuestId] ~= nil or
                               self._QuestsCanRecievedTalbe[self._CurFrameType][v2.QuestId] ~= nil
                            then
                                --print("通过Progress==============",v2.QuestId)
                                -- i 为第几章
                                local QuestChapters = nil
                                for i3,v3 in ipairs(QuestTypeChapters) do
                                    if v3.ChapterTid == self._ChaptersTemplate_id_list[i] then
                                        QuestChapters = v3
                                        if self._CurrentChapterIndex == -1 then
                                            self._CurrentChapterIndex = i3 - 1
                                        end
                                        break
                                    end
                                end
                                if QuestChapters == nil then
                                    QuestChapters = {}
                                    QuestChapters.ChapterTid = self._ChaptersTemplate_id_list[i]
                                    QuestTypeChapters[#QuestTypeChapters+1] = QuestChapters
                                    if self._CurrentChapterIndex == -1 then
                                        self._CurrentChapterIndex = #QuestTypeChapters - 1
                                    end
                                end

                                if QuestChapters.QuestGroups == nil then
                                    QuestChapters.QuestGroups = {}
                                end

                                local QuestGroups = QuestChapters.QuestGroups 
                                local QuestGroup = nil
                                for i3,v3 in ipairs(QuestGroups) do
                                    if v3.GroupTid == GroupTemplate.Id then
                                        QuestGroup = v3
                                        break
                                    end
                                end
                                if QuestGroup == nil then
                                    QuestGroup = {}
                                    QuestGroup.GroupTid = GroupTemplate.Id
                                    QuestGroups[#QuestGroups+1] = QuestGroup
                                end
                                if QuestGroup.FinishCount == nil then
                                    QuestGroup.FinishCount = 0
                                end

                                QuestGroup.IsSelected = true

                                --不同点3
                                isBreak = true
                            end
                        end
                    end
                end
            end
        end  
    else
        QuestTypeChapters = self._QuestChapters[self._CurFrameType]
    end

    local function sort_func(itm1,itm2)
        local ChapterTemplate1 = CElementData.GetTemplate("QuestChapter", itm1.ChapterTid)
        local ChapterTemplate2 = CElementData.GetTemplate("QuestChapter", itm2.ChapterTid)
        if ChapterTemplate1 == nil or ChapterTemplate2 == nil then
            return false
        end
        return ChapterTemplate1.ChapterId < ChapterTemplate2.ChapterId
    end
    table.sort(QuestTypeChapters,sort_func)
    --print_r(self._QuestChapters)

    --如果有任务
    if #QuestTypeChapters > 0 then
        self:SetQuestChaptersDropGroup()
        self._List_QuestParent:SetActive(true)
        self._Drop_QuestChapter:SetActive(true)
        -- print("aaaa==================",OnDropDownIndex)
        OnDropDownIndex = 0
        GameUtil.SetDropdownValue(self._Drop_QuestChapter, -1)
        -- local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
        -- local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
        -- self._List_Quest:SetItemCount(#Groups)

        if self._CurFrameType-1 == QuestDef.QuestType.Main then
            GameUtil.SetDropdownValue(self._Drop_QuestChapter, #QuestTypeChapters-1)
        elseif self._CurFrameType-1 == QuestDef.QuestType.Branch then
            --如果没有选中 默认为0
            if self._CurrentChapterIndex == -1 then
                self._CurrentChapterIndex = 0
            end
            local CPageQuest = require "GUI.CPageQuest"
            --应该显示的章节
            local chapterID = -1

            for i = 1, #CPageQuest.Instance()._QuestCurrent do
                self._CurrentChapterIndex = i + 1
                local curQuestId = CPageQuest.Instance()._QuestCurrent[i]
                local curQuest = CQuest.Instance():FetchQuestModel(curQuestId)
                if curQuest:GetTemplate().Type == QuestDef.QuestType.Branch then
                    chapterID = CQuest.Instance():GetQuestChapter( curQuest.Id )
                    break
                end
            end

            --判断有无选中的章节，如果有，并且任务没有完成，则覆盖上逻辑
            local SelectChapterID = CQuest.Instance():GetQuestChapter( CPageQuest.Instance()._SelectQuestID )
            if SelectChapterID ~= -1 and not CQuest.Instance():IsQuestCompleted(CPageQuest.Instance()._SelectQuestID)then
                chapterID = SelectChapterID
            end

            for i,v in ipairs(QuestTypeChapters) do
                if v.ChapterTid == chapterID then
                    self._CurrentChapterIndex = i-1
                    break
                end
            end
            GameUtil.SetDropdownValue(self._Drop_QuestChapter, self._CurrentChapterIndex)
            --self._List_Quest:SelectItem(self._CurrentChapterIndex,0)
        end

        local Img_RedPoint = self._Drop_QuestChapter:FindChild("Img_RedPoint")
        if Img_RedPoint ~= nil then
            --判断有无小类型红点
            local isShow = false

            if self._CurFrameType - 1 == QuestDef.QuestType.Main then
                isShow = CQuest.Instance():IsShowMainQuestRedPoint()
            elseif self._CurFrameType - 1 == QuestDef.QuestType.Branch then
                isShow = CQuest.Instance():IsShowBranchQuestRedPoint()
            end
            Img_RedPoint:SetActive(isShow)
        end

        self._List_Quest:PlayEffect()
    else
        self._Frame_NoQuest:SetActive(true)
        self._Drop_QuestChapter:SetActive(false)
    end
end

local repeatQuestType = { QuestDef.QuestType.Reward,QuestDef.QuestType.Activity }
local repeatQuestRewardTempID = { 1401000,1301000 }
local repeatRewards = {}
local questModels = {}

def.method().ShowOtherFrame = function(self)
    repeatRewards = {}
    questModels = {}
    self._List_QuestParent:SetActive(false)
    self._Drop_QuestChapter:SetActive(false)
    self._Frame_ElementsContainer:SetActive(false)
    self._Frame_ElementContainerRepeat:SetActive(true)
    self._Frame_NoQuest:SetActive(false)
    self._Frame_ElementReputation:SetActive(false)
    -- self._Current_SelectData = nil
    -- self._Current_SelectGroupData = nil

    self._List_ElementsRepeat:SetItemCount(2)

end

def.method("boolean").ShowReputationFrame = function(self,isReset)
    self._List_QuestParent:SetActive(false)
    self._Drop_QuestChapter:SetActive(false)
    self._Frame_ElementsContainer:SetActive(false)
    self._Frame_ElementContainerRepeat:SetActive(false)
    
    local data_list = game._CReputationMan:GetAllReputation()
    local count = 0
    for k,v in pairs(data_list) do
        count = count + 1
    end

    if count > 0 then
        self._List_ElementsReputation:SetItemCount(count)
        if isReset then
        end
        self._List_ElementsReputation:SelectItem(self._CurrentSelectTabIndex,0)
        self._Frame_ElementReputation:SetActive(true)
        self._Frame_NoQuest:SetActive(false)
    else
        self._Frame_ElementReputation:SetActive(false)
        self._Frame_NoQuest:SetActive(true)
    end
end



def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
        game._GUIMan:Close("CPanelUIQuestList")
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Reward" then
    elseif id == "Btn_GiveUp" then
        CQuest.Instance():DoGiveUpQuest(self._CurrentSelectQuestID)
        game._GUIMan:Close("CPanelUIQuestList")
    elseif id == "Btn_Go" then
        local CPageQuest = require "GUI.CPageQuest"
        CPageQuest.Instance():ListItemsNoSelect()

        local questModel = CQuest.Instance():FetchQuestModel(self._CurrentSelectQuestID)
        if not CPageQuest.Instance():IsSelectByID( self._CurrentSelectQuestID ) then
            questModel:DoShortcut()
        elseif game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.AutoFight) then
            CQuestAutoMan.Instance():Start(questModel)    

            CAutoFightMan.Instance():Start() 
            CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.QuestFight, self._CurrentSelectQuestID, false)
        else
            CPageQuest.Instance():SetSelectByID(questModel.Id, false)
        end
        game._GUIMan:Close("CPanelUIQuestList")
    elseif id == "Btn_GoReputationNpc" then
            local panelData = 
            {   
                _type = CPanelMap.MapType.REPUTATION,
                ReputationID = self._Current_SelectData.Id,
            }
            game._GUIMan:Open("CPanelMap",panelData)

--         --如果声望任务在进行中
        --local questmodel = CQuest.Instance():GetQuestModelByReputationID(self._Current_SelectData.Id)
       
--         game._HostPlayer:StopAutoTrans()
-- --[[        CQuestAutoMan.Instance():Stop()
--         CDungeonAutoMan.Instance():Stop()
--         CAutoFightMan.Instance():Stop()--]]
--         game:StopAllAutoSystems()
--         local template = CElementData.GetTemplate("Reputation", self._Current_SelectData.Id)
--         local associatedNpcTid = template.AssociatedNpcTId
--         local function DoCallback()
--              local npc = game._CurWorld._NPCMan:GetByTid(associatedNpcTid)
--              if npc ~= nil then
--                 game._HostPlayer._OpHdl:TalkToServerNpc(npc, nil)
--              end
--         end

--         local scene_id, dest_pos, idx = MapBasicConfig.GetDestParams("Npc", associatedNpcTid, {})
--         CTransManage.Instance():StartMoveByMapIDAndPos(scene_id, dest_pos, DoCallback, true, true)
--         game._GUIMan:Close("CPanelUIQuestList")
    elseif id == "Btn_ReputationShop" then
        local panelData =
        {
            OpenType = 1,
            ShopId = 9,
            RepID = self._Current_SelectData.Id
        }
        game._GUIMan:Open("CPanelNpcShop", panelData)
    elseif id == "Btn_ReputationLvTips" then
        local Btn_Item = self:GetUIObject(id)
        game._GUIMan:Open("CPanelReputationTips", { _RepID = self._Current_SelectData.Id,_Obj = Btn_Item})
    elseif string.find(id,"Btn_Item") then
        for i,v in pairs(self._Current_SelectChapterReward) do
            if id == "Btn_Item" .. i then   
                if v._State == 1 or v._State == 3 then
                    
                    local reward_template = GUITools.GetRewardList(v._RewardID, true)
                    if reward_template ~= nil then 
                        local itemObj = self:GetUIObject("Frame_Gift_0"..i)
                        local strpath = "Btn_Item"..i
                        local Btn_Item = itemObj:FindChild(strpath)
                        if not reward_template[1].IsTokenMoney then
                            local RewardId = reward_template[1].Data.Id
                            CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL,Btn_Item,TipPosition.FIX_POSITION) 
                        else
                            local panelData = {}
                            panelData = 
                            {
                                _MoneyID = reward_template[1].Data.Id ,
                                _TipPos = TipPosition.FIX_POSITION ,
                                _TargetObj = Btn_Item ,   
                            }
                            CItemTipMan.ShowMoneyTips(panelData)
                        end 
                    end
                elseif v._State == 2 then
                    print("QuestGroupDrawReward=",v._GroupID)
                    CQuest.Instance():QuestGroupDrawReward(v._GroupID)
                end
            end
        end
    end
end

def.method().OnSelectChapterDataChange = function(self)
    self._CurrentSelectTabIndex = -1
    self._Frame_ElementsContainer:SetActive(true)
    self._IsTabOpen = false
    local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
    local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
    self._List_Quest:SetItemCount(#Groups)

    local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(Groups[#Groups]))
    --如果完成的节*小于*配置总节数   并且  完成的任务数*小于*配置的总任务数 
    if #self._Current_SelectData.QuestGroups < #Groups or 
        self._Current_SelectData.QuestGroups[#self._Current_SelectData.QuestGroups].FinishCount < #GroupTemplate.GroupFields 
    then
        local CurrentSelectTabIndex = #self._Current_SelectData.QuestGroups
        local CurrentSelectTabIndex2 = self._Current_SelectData.QuestGroups[#self._Current_SelectData.QuestGroups].FinishCount + 1
        if self._CurFrameType-1 == QuestDef.QuestType.Main then
            self._List_Quest:SelectItem(CurrentSelectTabIndex-1,CurrentSelectTabIndex2-1)
        elseif self._CurFrameType-1 == QuestDef.QuestType.Branch then
            self._List_Quest:SelectItem(CurrentSelectTabIndex-1,CurrentSelectTabIndex2-1)
        end
        print("OnSelectChapterDataChange=此章选中",self._Current_SelectData.ChapterTid,CurrentSelectTabIndex,CurrentSelectTabIndex2)
    else
        print("OnSelectChapterDataChange=此章全部完成")
        local CurrentSelectTabIndex = #self._Current_SelectData.QuestGroups
        local CurrentSelectTabIndex2 = self._Current_SelectData.QuestGroups[#self._Current_SelectData.QuestGroups].FinishCount
        if self._CurFrameType-1 == QuestDef.QuestType.Main then
            self._List_Quest:SelectItem(CurrentSelectTabIndex-1,CurrentSelectTabIndex2-1)
        elseif self._CurFrameType-1 == QuestDef.QuestType.Branch then
            self._List_Quest:SelectItem(CurrentSelectTabIndex-1,CurrentSelectTabIndex2-1)
        end
    end

    self:OnSelectChapterMapChange()
    self:UpdateChapterRewardInfo( Groups )
end

def.method().OnSelectGroupDataChange = function(self)
    for i,v in ipairs(Table_QuestObj) do
        if i == self._CurrentSelectTabIndex then
            --GUITools.SetUIActive(v:FindChild("Img_QuestBG"), true)
            --GUITools.SetGroupImg(v,1)
        else
            --GUITools.SetUIActive(v:FindChild("Img_QuestBG"), false)
            --GUITools.SetGroupImg(v,0)
        end
    end
    
end

local function SetOneObjective(object, data)
    -- local img_tag = object:FindChild("Gro_Tag")
    local color = data:GetTextColor()
    if data:IsComplete() then
        color = EnumDef.QuestObjectiveColor.Finish
    else
        color = data:GetTextColor()
    end
    
    
    local lab_desc = object:FindChild("Lab_Desc")
    GUI.SetText(lab_desc, data:GetDisplayText())

    GUI.SetTextColor(lab_desc, color)
    local count_cur = data:GetCurrentCount()
    if data:IsCountOnce() then
        object:FindChild("Lab_Current"):SetActive(false)
        object:FindChild("Lab_Max"):SetActive(false)
        object:FindChild("Lab_Slash"):SetActive(false)
        object:FindChild("Lab_Time"):SetActive(false)
    elseif data:GetWaitTime() > 0 then
        local remainingTime = data:GetRemainingTime()
        object:FindChild("Lab_Current"):SetActive(false)
        object:FindChild("Lab_Max"):SetActive(false)
        object:FindChild("Lab_Slash"):SetActive(false)
        if remainingTime > 0 then
            object:FindChild("Lab_Time"):SetActive(true)
            instance:AddQuestObjectiveTimer(object:FindChild("Lab_Time"),remainingTime)
        else
            object:FindChild("Lab_Time"):SetActive(false)
            --instance:RemoveQuestObjectiveTimer(data)
        end
    else
        local lab_cur = object:FindChild("Lab_Current")
        lab_cur:SetActive(true)
        GUI.SetText(lab_cur, tostring(count_cur))
        local lab_max = object:FindChild("Lab_Max")
        lab_max:SetActive(true)
        GUI.SetText(lab_max, tostring(data:GetNeedCount()))
        local lab_slash = object:FindChild("Lab_Slash")
        lab_slash:SetActive(true)

        GUI.SetTextColor(lab_cur, color)
        GUI.SetTextColor(lab_max, color)
        GUI.SetTextColor(lab_slash, color)
        object:FindChild("Lab_Time"):SetActive(false)
    end
end

--添加副本目标倒计时
local timeID = 0
def.method("userdata","number").AddQuestObjectiveTimer = function(self,lab_time,time)
    _G.RemoveGlobalTimer(timeID)
    local callback = function()
        if IsNil(lab_time) then return end           
        local minute = math.floor(time / 60)
        if minute < 10 then
            minute = "0" .. minute
        end
        local second = math.floor(time % 60)
        if second < 10 then
            second = "0" .. second
        end

        lab_time:SetActive(true)
        GUI.SetText(lab_time, minute .. ":" .. second)

        time = time - 1
        if time < 0 then
            lab_time:SetActive(false)
            _G.RemoveGlobalTimer(timeID)
            -- QuestUpdate(quest_objectiveModel._QuestModel)
            -- local NotifyQuestDataChangeEvent = require "Events.NotifyQuestDataChangeEvent"
            -- CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())

            -- local QuestWaitTimeFinish = require "Events.QuestWaitTimeFinish"
            -- local event = QuestWaitTimeFinish()    
            -- event._QuestId = quest_objectiveModel._QuestModel.Id
            -- CGame.EventManager:raiseEvent(nil, event)            
        end
    end
    timeID = _G.AddGlobalTimer(1, false, callback)
end

def.method("table","number",'=>', 'userdata').AddQuestObj = function(self,v3Pos,index)
    local tmpObj = nil
    local AddNewQuestObj = function (objPos)
        local obj = GameObject.Instantiate(self._Obj_Quest)
        if(obj ~= nil) then
            obj:SetParent(self._Img_Map)
            obj.localPosition = v3Pos
            -- 暂时应用
            obj.localScale = Vector3.one                  
            obj:SetActive(true)
            --GUITools.SetGroupImg(obj,index)
            Table_QuestObj[#Table_QuestObj + 1] = obj
        end
        tmpObj = obj
    end

    if Table_QuestObj == nil or #Table_QuestObj <= 0 then
        AddNewQuestObj(v3Pos,index)
    else
        for _,v in ipairs(Table_QuestObj) do
            if not v.activeSelf then
                v: SetActive(true)
                v.localPosition = v3Pos
                --GUITools.SetGroupImg(v,index)
                return v
            end
        end
        AddNewQuestObj(v3Pos)
    end
    return tmpObj
end

local ClearTable = function(self)
    if Table_QuestObj ~= nil then
        for i=#Table_QuestObj, 1, -1 do
            local v = Table_QuestObj[i]
            if not IsNil(v) then
                v: SetActive(false)
            else
                table.remove(Table_QuestObj,i)
            end
        end
    end
end

def.method().OnSelectChapterMapChange = function(self)
    local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
    local Groups = string.split(ChapterTemplate.QuestGroupId, "*")

    --local map = _G.MapBasicInfoTable[ChapterTemplate.MapTId]
    local map =  MapBasicConfig.GetMapBasicConfigBySceneID(ChapterTemplate.MapTId)
   
    --无测试数据 临时
    if map == nil then
        --map = _G.MapBasicInfoTable[120]
        map = MapBasicConfig.GetMapBasicConfigBySceneID(120)
    end
    if map ~= nil then
        GUITools.SetMap(self._Img_Map, map.MiniMapAtlasPath)
    end

    ClearTable(self)
    for i,v in ipairs(Groups) do
        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(v))
        local obj = nil
        if i == self._CurrentSelectTabIndex then
            obj = self:AddQuestObj(Vector3.New(GroupTemplate.PositionX,GroupTemplate.PositionY,0),1)
            --GUITools.SetUIActive(obj:FindChild("Img_QuestBG"), true)
            --self:AddQuestObj(Vector3.New((i+1)*10,(i+1)*10,0),1)
        else
            obj = self:AddQuestObj(Vector3.New(GroupTemplate.PositionX,GroupTemplate.PositionY,0),0)
            --GUITools.SetUIActive(obj:FindChild("Img_QuestBG"), false)
            --self:AddQuestObj(Vector3.New((i+1)*10,(i+1)*10,0),0)
        end
        if obj ~= nil then
            local imgNum = obj:FindChild("Img_QuestNum")
            GUITools.SetGroupImg(imgNum,i-1)
            GUITools.SetNativeSize(imgNum)

            local lab = obj:FindChild("Lab_QuestGroupProgress")
            if self._Current_SelectData.QuestGroups[i] == nil then
                local str = '0/'..#GroupTemplate.GroupFields
                str = "<color=#FFFFFFFF>" ..str .."</color>"
                GUI.SetText(lab,str)
            else
                local str = self._Current_SelectData.QuestGroups[i].FinishCount..'/'..#GroupTemplate.GroupFields
                if self._Current_SelectData.QuestGroups[i].FinishCount >= #GroupTemplate.GroupFields then
                    str = "<color=#74D41BFF>" ..str .."</color>"
                else
                    str = "<color=#FFFFFFFF>" ..str .."</color>"
                end
                GUI.SetText(lab,str)
            end
        end
    end
    
end

local progressIndexMax = 0
local progressIndexCur = 0
-- 刷新章节奖励
def.method("table").UpdateChapterRewardInfo = function(self,Groups)
    --数据
    --更新奖励数据 -- 1不能领取、2可以领取、3已经领取
    self._Current_SelectChapterReward = {}
    progressIndexCur = 0
    for i,v in ipairs(Groups) do
        local tmpGroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(Groups[i]))
        local groupID = tonumber(v)
        local state = 1
        --判断是否已经领取
        if CQuest.Instance()._GroupRewardList[groupID] ~= nil then
            state = 3
            progressIndexCur = progressIndexCur + 1
        --判断是否可以领取
        elseif self._Current_SelectData.QuestGroups[i] ~= nil and self._Current_SelectData.QuestGroups[i].FinishCount == #tmpGroupTemplate.GroupFields then
            state = 2
            progressIndexCur = progressIndexCur + 1
        end
        local data = 
        {
            _GroupID = groupID,
            _State = state, 
            _RewardID = tmpGroupTemplate.RewardId 
        }
        self._Current_SelectChapterReward[#self._Current_SelectChapterReward+1] = data
    end

    --print_r( self._Current_SelectChapterReward )
    --逻辑
    progressIndexMax = #Groups
    self._Frame_ChapterReward:SetActive(true)

    local RectTransform = self._Frame_RewardScroll.gameObject:GetComponent(ClassType.RectTransform)
    --local v = RectTransform.rect.width / progressIndexMax  --奖励长度
    local v = 167
    local maxWidth = v * (progressIndexMax - 1)  --根据奖励奖励条最大长度
    RectTransform.sizeDelta = Vector2.New(maxWidth,RectTransform.rect.height)

    if progressIndexCur == 0 then
        self._Img_RewardFront.fillAmount = 0
    else
        self._Img_RewardFront.fillAmount = ( progressIndexCur - 1 ) / ( progressIndexMax - 1 )
    end
    
    
    --print("================",progressIndexCur,progressIndexMax)
    --print_r(self._Current_SelectChapterReward)
    for i = 1,4 do 
        local itemObj = self:GetUIObject("Frame_Gift_0"..i)
        local btn = itemObj:FindChild("Btn_Item"..i)
        local strpath = "Btn_Item"..i.."/Img_Item"..i
        local Img_Item = itemObj:FindChild(strpath)
        local Lab_GiftPoint = itemObj:FindChild("Lab_GiftPoint"..i)
        if i > progressIndexMax then
            itemObj:SetActive(false)
        else
            itemObj:SetActive(true)

            local data = self._Current_SelectChapterReward[i]
            if data._State == 1 then
                GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, btn)
                GUITools.SetGroupImg(Img_Item, 0)
                --GameUtil.MakeImageGray(Img_Item, false)
            --如果可以领奖
            elseif data._State == 2 then
                GameUtil.PlayUISfx(PATH.UIFX_BaoXiangLingQu, btn, btn, -1)
                GUITools.SetGroupImg(Img_Item, 0)
                --GameUtil.MakeImageGray(Img_Item, false)
            --如果已经领奖
            elseif data._State == 3 then
                GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, btn)
                GUITools.SetGroupImg(Img_Item, 1)
                --GameUtil.MakeImageGray(Img_Item, true)
            end
            GUI.SetText(Lab_GiftPoint, string.format(StringTable.Get(562),i))
        end
    end 
end

--领取了某一个条目奖励
def.method('number').OnDataRecieveChange = function (self,QuestGroupId)
        local index = 0
        for k,v in pairs(self._Current_SelectChapterReward) do
            index = index + 1
            if v._GroupID == QuestGroupId then
                v._State = 3
                break
            end
        end
        
        local itemObj = self:GetUIObject("Frame_Gift_0"..index)
        if not IsNil(itemObj) then
            local btn = itemObj:FindChild("Btn_Item"..index)
            local strpath = "Btn_Item"..index.."/Img_Item"..index
            local Img_Item = itemObj:FindChild(strpath)
            GUITools.SetGroupImg(Img_Item, 1)
            --GameUtil.MakeImageGray(Img_Item, true)
            GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, btn)
        end

        --如果有一个未领 则显示红点
        local isShow = false
        for k,v in pairs(self._Current_SelectChapterReward) do
            if v._State == 2 then
                isShow = true
                break
            end
        end

        if not isShow then
            -- local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
            -- if Map == nil then
            --     Map = {}
            -- end
            -- if Map[self._CurFrameType] == nil then
            --     Map[self._CurFrameType] = {}
            -- end

            -- if self._CurFrameType - 1 == QuestDef.QuestType.Main then
            --     Map[self._CurFrameType][self._Current_SelectData.ChapterTid] = false
            --     CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
            -- elseif self._CurFrameType - 1 == QuestDef.QuestType.Branch then
            --     --可领取奖励红点
            --     if Map[QuestDef.QuestType.Branch+1][2] == nil then
            --         Map[QuestDef.QuestType.Branch+1][2] = {}
            --     end
            --     Map[self._CurFrameType][2][self._Current_SelectData.ChapterTid] = false
            --     CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
            -- end
            -- print_r(Map[self._CurFrameType])
            local Img_RedPoint = self._Drop_QuestChapter:FindChild("Img_RedPoint")
            if Img_RedPoint ~= nil then
                --判断有无小类型红点
                local isShow = false
                -- local redDotStatusMap = Map[self._CurFrameType]
                -- if self._CurFrameType - 1 == QuestDef.QuestType.Main then
                --     redDotStatusMap = Map[self._CurFrameType]
                -- elseif self._CurFrameType - 1 == QuestDef.QuestType.Branch then
                --     redDotStatusMap = Map[self._CurFrameType][2]
                -- end

                -- if redDotStatusMap ~= nil then
                --     for k,v in pairs(redDotStatusMap) do
                --         if v ~= nil and v == true then
                --             isShow = true
                --             break
                --         end
                --     end
                -- end
                --isShow = CQuest.Instance():IsGiveRewardByQuestChapter( self._Current_SelectData.ChapterTid )
                if self._CurFrameType-1 == QuestDef.QuestType.Main then
                    isShow = CQuest.Instance():IsShowMainQuestRedPoint()
                elseif self._CurFrameType-1 == QuestDef.QuestType.Branch then
                    isShow = CQuest.Instance():IsShowBranchQuestRedPoint()
                end
                
                Img_RedPoint:SetActive(isShow)
            end
            self:ShowRedPoint(self._CurFrameType,false)
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
        end
        self:SetQuestChaptersDropGroup()
end

local rewards = nil
def.method().OnSelectQuestDataChange = function(self)
    print("_CurrentSelectQuestID=",self._CurrentSelectQuestID,self._Current_SelectData.ChapterTid)
    self._Frame_CurQuest:SetActive(true)

    local template = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
    GUI.SetText(self._Lab_ChapterName, template.TextDisplayName )


    local ChapterDes = ""

    local Groups = string.split(template.QuestGroupId, "*")
    for i1, v1 in ipairs(Groups) do
        local GroupsTID = tonumber(v1)           
        local GroupTemplate = CElementData.GetTemplate("QuestGroup", GroupsTID)
        for i2,v2 in ipairs(GroupTemplate.GroupFields) do
            local QuestID = v2.QuestId

            local QuestTemplate = CElementData.GetQuestTemplate(QuestID) 

            --判断此任务是否完成
            if CQuest.Instance():IsQuestCompleted(QuestID) then
                if ChapterDes == "" then
                    ChapterDes = string.format("%s",QuestTemplate.TextDescription)
                else
                    ChapterDes = string.format("%s\n%s",ChapterDes,QuestTemplate.TextDescription)
                end
            else
                --如果跳出时没有任何内容，默认第一个任务描述
                if ChapterDes == "" then
                    ChapterDes = QuestTemplate.TextDescription
                end
                break
            end
            --print(QuestID,QuestTemplate.TextDescription)
        end
    end

    ChapterDes = DynamicText.ParseDialogueText(ChapterDes)
    GUI.SetText(self._Lab_ChapterDes, ChapterDes)

    --如果此任务没有完成 才显示奖励以及按钮
    local textIndex = 0
    if CQuest.Instance():IsQuestCompleted(self._CurrentSelectQuestID) then
        self._Frame_Reward:SetActive(false)
        self._Btn_Go:SetActive(false)
        self._Btn_GiveUp:SetActive(false)
        self._Lab_QuestProvide:SetActive(false)
        local max_objective_count = 4
        for i = 1, max_objective_count do
            local frame = self._TargetsTable[i]
            frame:SetActive(false)
        end

        --对齐方式 完成了 上对齐
        local rect = self._Lyout_Content:GetComponent(ClassType.RectTransform)
        rect.anchorMin = Vector2.New(0.5, 1)
        rect.anchorMax = Vector2.New(0.5, 1)
        rect.pivot = Vector2.New(0.5, 1)
        rect.anchoredPosition = Vector2.New(0,0)
    else
        
        --任务目标
        local questModel = CQuest.Instance():FetchQuestModel(self._CurrentSelectQuestID)
        --如果是未接任务
        if questModel.QuestStatus == QuestDef.Status.NotRecieved then
            --显示发放文本
            self._Lab_QuestProvide:SetActive(true)
            GUI.SetText(self._Lab_QuestProvide, questModel:GetTemplate().ProvideRelated.ProvideText)
            --不显示任务目标
            local max_objective_count = 4
            for i = 1, max_objective_count do
                local frame = self._TargetsTable[i]
                frame:SetActive(false)
            end
            textIndex = 1
        else
            --不显示发放文本
            self._Lab_QuestProvide:SetActive(false)
            --显示任务目标
            local max_objective_count = 4
            local objs = questModel:GetCurrentQuestObjetives()
            local obj_count = #objs
            for i = 1, max_objective_count do
                local frame = self._TargetsTable[i]
                if i > obj_count then
                    frame:SetActive(false)
                else
                    frame:SetActive(true)
                    SetOneObjective(frame, objs[i])
                end
            end
            textIndex = obj_count
        end

        self._Frame_Reward:SetActive(true)
        if questModel:GetTemplate().RewardId <= 0 then
            self._List_ElementsReward:SetItemCount(0)
        else
            rewards = GUITools.GetRewardList(questModel:GetTemplate().RewardId, true)
            self._List_ElementsReward:SetItemCount(#rewards)
        end    

        self._Btn_Go:SetActive(true)
        --是否有放弃按钮 (主线任务 或者 没有接状态的任务 不显示 放弃按钮)
        --if questModel:GetTemplate().Type == QuestDef.QuestType.Main or questModel.QuestStatus == QuestDef.Status.NotRecieved then
            self._Btn_GiveUp:SetActive(false)
        -- else
        --     self._Btn_GiveUp:SetActive(true)
        -- end

        --对齐方式 没有全部完成 下对齐
        local rect = self._Lyout_Content:GetComponent(ClassType.RectTransform)
        rect.anchorMin = Vector2.New(0.5, 0)
        rect.anchorMax = Vector2.New(0.5, 0)
        rect.pivot = Vector2.New(0.5, 0)
        rect.anchoredPosition = Vector2.New(0,0)
    end

    --临时规定的距离 特殊作用
    --print("=========",self._Lab_ChapterDes:GetComponent(ClassType.Text).preferredHeight)
    if self._Lab_ChapterDes:GetComponent(ClassType.Text).preferredHeight > 180 then
        GameUtil.SetLayoutElementPreferredSize(self._Lab_ChapterDes, -1, self._Lab_ChapterDes:GetComponent(ClassType.Text).preferredHeight)
    else
        --GameUtil.SetLayoutElementPreferredSize(self._Lab_ChapterDes, -1, 150-25*textIndex)
        GameUtil.SetLayoutElementPreferredSize(self._Lab_ChapterDes, -1, 180)
    end 
end

def.method('userdata','number').OnInitTabListDeep1 = function(self,item,bigTypeIndex)
--print("OnInitTabListDeep1",bigTypeIndex)
    local GroupData = self._Current_SelectData.QuestGroups[bigTypeIndex]
    local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
    local GroupIds = string.split(ChapterTemplate.QuestGroupId, "*")
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(GroupIds[bigTypeIndex]))

    item:FindChild("Img_Arrow/Img_Arrow_01"):SetActive(false)
    --item:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(true)
            
    local color_code = "FFFFFFFF"
    --判断此任务是否完成 改变字体颜色
    local Img_Lock = item:FindChild("Img_Lock")
    if Img_Lock ~= nil then
        if 
            self._Current_SelectData.QuestGroups[bigTypeIndex] ~= nil --and 
            --self._Current_SelectData.QuestGroups[bigTypeIndex].FinishCount > 0 
        then
            Img_Lock:SetActive(false)
            color_code = "FFFFFFFF"
            item:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(true)
        else
            Img_Lock:SetActive(true)
            color_code = "FFFFFF78"
            item:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(false)
        end
    end
    
    local str = nil
    --如果是主线 加 几-几
    if self._CurFrameType-1 == QuestDef.QuestType.Main then
        str = ChapterTemplate.ChapterId..'-'..bigTypeIndex..'\n'..GroupTemplate.OpenNotify
    else
        str = GroupTemplate.OpenNotify
    end

    -- 颜色
    -- str =  "<color=#" .. color_code ..">" ..str .."</color>"

    item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = str
    --item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = str
end

def.method('userdata','number','number').OnInitTabListDeep2 = function(self,item,bigTypeIndex,smallTypeIndex)
--print("OnInitTabListDeep2",bigTypeIndex,smallTypeIndex)
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", self._Current_SelectGroupData.GroupTid)
    local QuestID = GroupTemplate.GroupFields[smallTypeIndex].QuestId
    local QuestTemplate = CElementData.GetQuestTemplate(QuestID) 


    local color_code = "FFFFFFFF"
    --判断此任务是否完成 改变字体颜色
    local Img_Finish = item:FindChild("Img_Finish")
    if Img_Finish ~= nil then
        if CQuest.Instance():IsQuestCompleted(QuestID) then
            Img_Finish:SetActive(true)
            color_code = "3FC300FF"
        else
            Img_Finish:SetActive(false)
            --判断此任务是否进行中 或者在可以接取的状态
            if CQuest.Instance():IsQuestInProgress(QuestID) or CQuest.Instance():IsQuestReady(QuestID) or CQuest.Instance():CanRecieveQuest(QuestID) then
                color_code = "FFFFFFFF"
            else
            --不能接
                color_code = "FFFFFF78"
            end
        end
    end
    
    -- 颜色
    --local str =  "<color=#" .. color_code ..">" ..QuestTemplate.TextDisplayName .."</color>"

    local str =  QuestTemplate.TextDisplayName
    item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = str
    --item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = str
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "List_Quest" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnInitTabListDeep1(item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnInitTabListDeep2(item,bigTypeIndex,smallTypeIndex)
        end
    elseif list.name == "List_Reputation" then
        local bigTypeIndex = main_index + 1

        local data = game._CReputationMan:GetAllReputation()

        --local index = 0
        local id = 0
        local curData = nil 
        for k,v in pairs(data) do
            --index = index + 1
            if v.Index == bigTypeIndex then
                id = k
                curData = v
                break
            end
        end
        
        local template = CElementData.GetTemplate("Reputation", id)
        item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = template.TextDisplayName
        --item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = template.TextDisplayName

        local Img_RedPoint = item:FindChild("Img_RedPoint")
        if Img_RedPoint ~= nil then
            --判断有无小类型红点
            local isShow = false
        --     local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
        --     if Map ~= nil then
        --         local redDotStatusMap = Map[4]
        --         if redDotStatusMap ~= nil and redDotStatusMap[id] ~= nil and redDotStatusMap[id] == true then
        --             isShow = true
        --         end
        --     end
            Img_RedPoint:SetActive(isShow)
        end

        --如果声望任务在进行中
        local questmodel = CQuest.Instance():GetQuestModelByReputationID(id)
        local Img_Finish = item:FindChild("Img_Finish")
        local isShow = not ( questmodel ~= nil or CQuest.Instance():HaveReputationQuest(id) )
        if Img_Finish ~= nil then
        Img_Finish:SetActive( isShow )
        end
    end
end

def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
print("OnClickTabListDeep1",bigTypeIndex)
    local GroupData = self._Current_SelectData.QuestGroups[bigTypeIndex]
    local ChapterTemplate = CElementData.GetTemplate("QuestChapter", self._Current_SelectData.ChapterTid)
    local GroupIds = string.split(ChapterTemplate.QuestGroupId, "*")
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(GroupIds[bigTypeIndex]))

    self._Current_SelectGroupData = GroupData
    if self._Current_SelectGroupData == nil then
        game._GUIMan:ShowTipText( StringTable.Get(561), false)
        print(self._Current_SelectData.ChapterTid.."章"..bigTypeIndex.."节未激活")
        return
    end
    self._List_Quest:SetSelection(bigTypeIndex-1,-1)
    self._Current_SelectGroupData.Index = bigTypeIndex
    if bigTypeIndex == 0 then
        self._List_Quest:OpenTab(0)
        self._Current_SelectData = nil
    else
        local function OpenTab()

            --如果有小类型 打开小类型
            local GroupTemplate = CElementData.GetTemplate("QuestGroup", self._Current_SelectGroupData.GroupTid)
            local current_type_count = #GroupTemplate.GroupFields
            --print("OpenTab=",self._Current_SelectGroupData.GroupTid,current_type_count)
            self._List_Quest:OpenTab(current_type_count)
            print("OpenTab.name=",item.name)
            local lastMainSelectedNode = self._List_Quest:GetItem(self._List_Quest.LastMainSelected)
            if lastMainSelectedNode ~= nil then
                lastMainSelectedNode:FindChild("Img_Arrow/Img_Arrow_01"):SetActive(false)
                lastMainSelectedNode:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(true)
                print("lastMainSelectedNode.name=",lastMainSelectedNode.name)
            end
            item:FindChild("Img_Arrow/Img_Arrow_01"):SetActive(true)
            item:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(false)
            --默认选择了第一项
            if current_type_count > 0 then
                self:OnClickTabListDeep2(list,bigTypeIndex,self._List_Quest.SubSelected+1)
                self._IsTabOpen = true
            end
        end

        local function CloseTab()
            self._List_Quest:OpenTab(0)
            self._IsTabOpen = false
            item:FindChild("Img_Arrow/Img_Arrow_01"):SetActive(false)
            item:FindChild("Img_Arrow/Img_Arrow_02"):SetActive(true)
        end

        if self._CurrentSelectTabIndex == bigTypeIndex then
            if self._IsTabOpen then
                CloseTab()
            else
                OpenTab()
            end
        else
            OpenTab()
        end
    end

    self._CurrentSelectTabIndex = bigTypeIndex
    self:OnSelectGroupDataChange()
end

def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    print("OnClickTabListDeep2",bigTypeIndex,smallTypeIndex)
    if self._Current_SelectGroupData == nil then
        --print("任务不能接取也没有完成")
        game._GUIMan:ShowTipText( StringTable.Get(560), false)
        print(StringTable.Get(560))
        return
    end
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", self._Current_SelectGroupData.GroupTid)

    --防止选中越界
    if smallTypeIndex > #GroupTemplate.GroupFields then
        smallTypeIndex = #GroupTemplate.GroupFields
    end
    local QuestID = GroupTemplate.GroupFields[smallTypeIndex].QuestId

        --判断此任务是否完成
    if CQuest.Instance():IsQuestCompleted(QuestID) then
        self._CurrentSelectQuestID = QuestID
        self:OnSelectQuestDataChange()
        self._List_Quest:SetSelection(bigTypeIndex-1,smallTypeIndex-1)
    else
        --判断此任务是否进行中 或者在可以接取的状态
        if CQuest.Instance():IsQuestInProgress(QuestID) or CQuest.Instance():IsQuestReady(QuestID) or CQuest.Instance():CanRecieveQuest(QuestID) then
            --选中的任务ID 打开任务界面
            self._CurrentSelectQuestID = QuestID
            self:OnSelectQuestDataChange()
            self._List_Quest:SetSelection(bigTypeIndex-1,smallTypeIndex-1)
        else
        --不能接
            --print("任务不能接取也没有完成")
            game._GUIMan:ShowTipText( StringTable.Get(560), false)
            print(StringTable.Get(560))
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "List_Quest" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
    elseif list.name == "List_Reputation" then
        local bigTypeIndex = main_index + 1
        local data = game._CReputationMan:GetAllReputation()
        local index = 0
        local id = 0
        local curData = nil 
        for k,v in pairs(data) do
            --index = index + 1
            if v.Index == bigTypeIndex then
                id = k
                curData = v
                self._Current_SelectData = { Id = id,ReputationLevel = data[id].Level }
                break
            end
        end
        
        local template = CElementData.GetTemplate("Reputation", id)
        --print("template.Id=====",template.Id,data[template.Id].Level)
        self._Frame_ReputationContent:SetActive(true)
        GUI.SetText(self._Lab_ReputationName, template.TextDisplayName )
        GUI.SetText(self._Lab_ReputationNameE, template.TextDisplayNameEnglish )
        GUI.SetText(self._Lab_ReputationDes, template.ReputationDes )

        --！！！！！背景图片
        GUITools.SetSprite(self._Frame_ElementReputation:FindChild("Img_TaskList_Bg_01/ImG_Bg"), template.BackGroundPath)

        --Lab_ReputationLv:SetActive(true)
        --GUI.SetText(Lab_ReputationLv, StringTable.Get(25000+data[template.Id].Level) )

        local levelExps = { template.ReputationLevelExp1,template.ReputationLevelExp2,template.ReputationLevelExp3,template.ReputationLevelExp4,template.ReputationLevelExp5 }
        --Pro_Loading:SetActive(true)
        local str = data[template.Id].Exp.."/"..levelExps[data[template.Id].Level]
        GUI.SetText(self._Lab_ReputationProgress, str )
        self._Img_Front.fillAmount = data[template.Id].Exp / levelExps[data[template.Id].Level]
        --local iconPath = _G.CommonAtlasDir .. "Icon/" .. template.IconAtlasPath..".png"
        GUITools.SetSprite(self._Img_ReputationIcon, template.IconAtlasPath)
        --print("data[template.Id].Level-1=",data[template.Id].Level-1)
        GUITools.SetGroupImg(self._Lab_ReputationLvIcon,data[template.Id].Level-1)

        -- if template.DescribText ~= nil then
        --     GUI.SetText(self._Lab_ReputationShopDes, template.DescribText )--DescribText )
        -- end
        GUI.SetText(self._Lab_ReputationShopDes, template.Remarks )

       local goods = game._CReputationMan:GetAllShopItemsByReputationID(template.Id)
       

       rewards = {}
        for i,v in ipairs(goods) do
            rewards[#rewards+1] = 
            {   
                IsTokenMoney = false,
                Data = 
                {
                    Id = v.ItemId, 
                    Count = 1,
                    ReputationType = v.ReputationType,
                    ReputationLevel = v.ReputationLevel
                },
            }
        end
        self._List_ReputationReward:SetItemCount( #goods )

        --如果声望任务在进行中
        local questmodel = CQuest.Instance():GetQuestModelByReputationID(self._Current_SelectData.Id)
        if questmodel ~= nil or CQuest.Instance():HaveReputationQuest(self._Current_SelectData.Id) then
            self._Btn_GoReputationNpc:SetActive(true)
            self._Lab_ReputationFinishQuest:SetActive(false)
        else
            self._Btn_GoReputationNpc:SetActive(false)
            self._Lab_ReputationFinishQuest:SetActive(true)
        end
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == 'List_ElementsReward' then
        local rewardData = rewards[idx]
        if rewardData ~= nil then
            local frame_icon = GUITools.GetChild(item, 0)
            if rewardData.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
            else
                IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id, { [EItemIconTag.Number] = rewardData.Data.Count })
            end
        end
    elseif id == 'List_ReputationReward' then
        local rewardData = rewards[idx]
        if rewardData ~= nil then
            local frame_icon = GUITools.GetChild(item, 0)
            if rewardData.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
            else
                IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id, { [EItemIconTag.Number] = rewardData.Data.Count })
            end

            local isLock = rewardData.Data.ReputationLevel <= self._Current_SelectData.ReputationLevel

            local frame_item = GUITools.GetChild(frame_icon, 3)
            local img_quality_bg = GUITools.GetChild(frame_item, 1)
            local img_quality = GUITools.GetChild(frame_item, 2)
            local img_icon = GUITools.GetChild(frame_item, 3)
            GameUtil.MakeImageGray(img_quality_bg, isLock)
            GameUtil.MakeImageGray(img_quality, isLock)
            GameUtil.MakeImageGray(img_icon, isLock)

            local lab_lock = GUITools.GetChild(item, 1)
            GUITools.SetUIActive(lab_lock, isLock)
            if isLock then
                GUI.SetText(lab_lock, StringTable.Get(25000 + rewardData.Data.ReputationLevel))
            end
        end
--[[        local img = item:FindChild("Img_BG_Reward")
        GUITools.SetRewardItem(img, rewards[idx])
        local icon = img:FindChild("Img_ItemIcon")
        local lab = img:FindChild("Lab_Number")
        if rewards[idx].Data.ReputationLevel >  self._Current_SelectData.ReputationLevel then
            GameUtil.MakeImageGray(icon, true)
            lab:SetActive(true)
            GUI.SetText(lab, StringTable.Get(25000 + rewards[idx].Data.ReputationLevel ) )
        else
            GameUtil.MakeImageGray(icon, false)
            lab:SetActive(false)
        end--]]
    elseif id == 'List_ElementsRepeat' then
        local Lab_Num_Chapter = item:FindChild("Lab_Num_Chapter")
        local Lab_Num_Count = item:FindChild("Lab_Num_Count")
        local Img_BG_QuestTypeIcon = item:FindChild("Img_BG_QuestTypeIcon")
        local Lab_QuestProvideRepeat = item:FindChild("Lab_QuestProvideRepeat")
        local Lab_QuestAllFinish = item:FindChild("Lab_QuestAllFinish")
        local Lab_QuestUnLockTips = item:FindChild("Lab_QuestUnLockTips")
        local Btn_GiveUpRepeat = item:FindChild("Btn_GiveUpRepeat")
        local Btn_GoRepeat = item:FindChild("Btn_GoRepeat")
        local Btn_AcceptRepeat = item:FindChild("Btn_AcceptRepeat")
        local Fram_TargetsBG = item:FindChild("Fram_TargetsRepeat/Fram_TargetsBG")

        local TargetsTable = {}
        for i = 1,4 do
            TargetsTable[i] = item:FindChild("Fram_TargetsRepeat/Fram_TargetsRepeat"..i)
        end
        local RewardsTable = {}
        for i = 1,4 do
            RewardsTable[i] = item:FindChild("Reward"..i)
        end

        --任务类型图标
        GUITools.SetGroupImg(Img_BG_QuestTypeIcon, index) 

        --local questModel = nil
        local QuestType = repeatQuestType[idx]
        local hoh = game._HostPlayer._OpHdl
        local isIng = false
        -- -- 0未领取 1进行中
        -- local QuestState = 0
        local str_Num_Chapter = ""
        local str_Num_repeatCount = ""
        local str_QuestProvideRepeat = ""
        if QuestType == QuestDef.QuestType.Reward then

            local CyclicQuestData = CQuest.Instance():GetCyclicQuestData()
            --计算环完成 与 总共需要完成的
            --local FinishNum = 0
            -- if CyclicQuestData._CyclicQuestFinishNum ~= nil then
            --     FinishNum = CyclicQuestData._CyclicQuestFinishNum
            -- end

            local TotalNum = 0
            local FinishNum = 0
            local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(543).Value)]
            if Group ~= nil then
                FinishNum = Group._Count
            end
            
            local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(543).Value))
            if template ~= nil then
                TotalNum = template.MaxCount
            end

            str_Num_Chapter = StringTable.Get(553)
            str_Num_repeatCount = string.format("%d/%d",FinishNum,TotalNum)
            str_QuestProvideRepeat = StringTable.Get(570)
            print( "=============Reward",CyclicQuestData._CyclicQuestID,FinishNum,TotalNum )
            if CyclicQuestData._CyclicQuestID ~= 0 then
                questModels[idx] = CQuest.Instance():GetInProgressQuestModel(CyclicQuestData._CyclicQuestID)
                Btn_AcceptRepeat:SetActive(false)
                Lab_QuestUnLockTips:SetActive(false)
                Btn_GiveUpRepeat:SetActive(true)
                Btn_GoRepeat:SetActive(true)
                Lab_QuestProvideRepeat:SetActive(false)
                Lab_QuestAllFinish:SetActive(false)
                isIng = true
            else
                if FinishNum >= TotalNum and TotalNum ~= 0 then
                    Lab_QuestAllFinish:SetActive(true)
                    Btn_AcceptRepeat:SetActive(false)
                    Lab_QuestUnLockTips:SetActive(false)
                else
                    Lab_QuestAllFinish:SetActive(false)
                    local RewardService = CElementData.GetServiceTemplate(810)
                    if hoh:JudgeServiceOption(RewardService) then
                        Btn_AcceptRepeat:SetActive(true)
                        Lab_QuestUnLockTips:SetActive(false)
                    else
                        Btn_AcceptRepeat:SetActive(false)
                        Lab_QuestUnLockTips:SetActive(true)
                        GUI.SetText(Lab_QuestUnLockTips, StringTable.Get(573) )
                    end
                end
                
                Btn_GiveUpRepeat:SetActive(false)
                Btn_GoRepeat:SetActive(false)
                Lab_QuestProvideRepeat:SetActive(true)
            end

        elseif QuestType == QuestDef.QuestType.Activity then
            --查找工会任务
            local list = CQuest.Instance():GetQuestsRecieved()
            questModels[idx] = nil 
            for _,v in pairs(CQuest.Instance()._InProgressQuestMap) do
                if v and (CQuest.Instance():IsQuestInProgress(v.Id) or CQuest.Instance():IsQuestReady(v.Id)) then
                    if v:GetTemplate().Type == QuestDef.QuestType.Activity then
                        questModels[idx] = v
                        break
                    end
                end
            end

            local FinishNum = 0
            local TotalNum = 0

            local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(435).Value)]
            if Group ~= nil then
                FinishNum = Group._Count
            end
            
            local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(435).Value))
            if template ~= nil then
                TotalNum = template.MaxCount
            end
            print( "=============Activity",FinishNum,TotalNum )
            str_Num_repeatCount = string.format("%d/%d",FinishNum,TotalNum)

            --如果没有进行中的活动任务（工会）
            if questModels[idx] == nil then
                local ActivityService = CElementData.GetServiceTemplate(790)
                -- if hoh:JudgeServiceOption(ActivityService) then
                if game._GuildMan:IsHostInGuild() and hoh:JudgeServiceOption(ActivityService) then
                    Btn_AcceptRepeat:SetActive(true)
                   if FinishNum >= TotalNum and TotalNum ~= 0 then
                        Btn_AcceptRepeat:SetActive(false)
                    else
                        Btn_AcceptRepeat:SetActive(true) 
                    end
                    Lab_QuestUnLockTips:SetActive(false)
                else
                    Btn_AcceptRepeat:SetActive(false)
                    Lab_QuestUnLockTips:SetActive(true)
                    GUI.SetText(Lab_QuestUnLockTips, StringTable.Get(574) )
                end

                Btn_GiveUpRepeat:SetActive(false)
                Btn_GoRepeat:SetActive(false)
                Lab_QuestProvideRepeat:SetActive(true)
                if FinishNum >= TotalNum and TotalNum ~= 0 then
                    Lab_QuestAllFinish:SetActive(true)
                else
                    Lab_QuestAllFinish:SetActive(false) 
                end

            else
                Btn_GiveUpRepeat:SetActive(true)
                Btn_GoRepeat:SetActive(true)
                Lab_QuestProvideRepeat:SetActive(false)
                Btn_AcceptRepeat:SetActive(false)
                Lab_QuestUnLockTips:SetActive(false)

                Lab_QuestAllFinish:SetActive(false)
                isIng = true
            end

            str_Num_Chapter = StringTable.Get(572)
            str_QuestProvideRepeat = StringTable.Get(571)
        end
        --任务类型名称+环次数
        GUI.SetText(Lab_Num_Chapter, str_Num_Chapter )
        GUI.SetText(Lab_Num_Count, str_Num_repeatCount )

        --任务类型未接时描述没用
        GUI.SetText(Lab_QuestProvideRepeat, str_QuestProvideRepeat )
        --任务类型奖励

        --如果正在进行中 不显示奖励
        if isIng then
            local max_objective_count = 4
            for i = 1, max_objective_count do
                RewardsTable[i]:SetActive(false)
            end
        else
            if repeatQuestRewardTempID[idx] <= 0 then
            
            else
                repeatRewards[idx] = GUITools.GetRewardList(repeatQuestRewardTempID[idx], true)
                local max_objective_count = 4
                for i = 1, max_objective_count do
                    if #repeatRewards[idx] >= i then
                        RewardsTable[i]:SetActive(true)
                        local frame_icon = RewardsTable[i]:FindChild("ItemIconNew")
                        local rewardData = repeatRewards[idx][i]
                        if rewardData.IsTokenMoney then
                            IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
                        else
                            IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id,{ [EItemIconTag.Number] = rewardData.Data.Count })
                        end
                    else
                        RewardsTable[i]:SetActive(false)
                    end
                end

            end  
        end
  
        
        
        if questModels[idx] ~= nil then
            --显示任务目标
            local max_objective_count = 4
            local objs = questModels[idx]:GetCurrentQuestObjetives()
            local obj_count = #objs
            for i = 1, max_objective_count do
                local frame = TargetsTable[i]
                if i > obj_count then
                    frame:SetActive(false)
                else
                    frame:SetActive(true)
                    SetOneObjective(frame, objs[i])
                end
            end
            Fram_TargetsBG:SetActive(true)
        else
            --不显示任务目标
            local max_objective_count = 4
            for i = 1, max_objective_count do
                local frame = TargetsTable[i]
                frame:SetActive(false)
            end
            Fram_TargetsBG:SetActive(false)
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == 'List_ElementsReward' or id == 'List_ReputationReward' then    
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

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    local idx = index + 1
    local QuestType = repeatQuestType[idx]
    if id_btn == "Btn_GiveUpRepeat" then
        CQuest.Instance():DoGiveUpQuest(questModels[idx].Id)
        game._GUIMan:Close("CPanelUIQuestList")
    elseif id_btn == "Btn_GoRepeat" then
        if QuestType == QuestDef.QuestType.Reward then
            --如果是赏金任务，在队中 则跟随
            if CTeamMan.Instance():InTeam() and not CTeamMan.Instance():IsTeamLeader() and questModels[idx]:GetTemplate().Type == QuestDef.QuestType.Reward then
                CTeamMan.Instance():FollowLeader(true)
            else
            --如果是赏金任务，是队长则开始任务
                questModels[idx]:DoShortcut()
            end
        elseif QuestType == QuestDef.QuestType.Activity then
            questModels[idx]:DoShortcut()
        end

        game._GUIMan:Close("CPanelUIQuestList")
    elseif id_btn == "Btn_AcceptRepeat" then
        local hoh = game._HostPlayer._OpHdl
        if QuestType == QuestDef.QuestType.Reward then
            --判断赏金服务 能不能使用 
            --如果可以使用 则找NPC(298赏金服务，1097，赏金服务NPC)
            -- local option = { service_id = 298 }
            -- CNPCServiceHdl.DealServiceOption(option)
            local RewardService = CElementData.GetServiceTemplate(810)
            --local NPC = CElementData:GetNpcTemplate(1097)
            if hoh:JudgeServiceOption(RewardService) then
                CQuestNavigation.Instance():NavigatToNpc(1097, nil)
                game._GUIMan:Close("CPanelUIQuestList")
            else
                local title, msg, closeType = StringTable.GetMsg(72)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
            end

        elseif QuestType == QuestDef.QuestType.Activity then
            local ActivityService = CElementData.GetServiceTemplate(790)
            --local NPC = CElementData:GetNpcTemplate(1097)
            --判断能不能接工会任务
            local hoh = game._HostPlayer._OpHdl
            local isHave = hoh:HaveServiceOptionsByNPCTid(20005)
            --工会任务服务 可否使用 
            if hoh:JudgeServiceOption(ActivityService) and hoh:JudgeServiceOptionIsUse(ActivityService) and isHave then
                CQuestNavigation.Instance():NavigatToNpc(20005, nil)
                game._GUIMan:Close("CPanelUIQuestList")
            else
                local title, msg, closeType = StringTable.GetMsg(73)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
            end
        end
    end

    for i = 1 ,4 do 
        if id_btn == "Btn_Reward"..i then
            local rewardData = repeatRewards[idx][i]
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
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if string.find(id, "Rdo_") and checked then
        -- 一级页签
        local rdoIndex = tonumber(string.sub(id, string.len("Rdo_")+1,-1))
        if rdoIndex == nil or rdoIndex == self._CurFrameType then return end
        self._CurFrameType = rdoIndex
        self._CurrentSelectTabIndex = 0
        self:ShowFrame()
    else
        --self._CurPageClass:ParentToggle(id, checked)
    end
end


-- 设置下拉菜单
def.method().SetQuestChaptersDropGroup = function (self)
    local groupStr = nil

    local current_type_chapters = self._QuestChapters[self._CurFrameType]
    for _, v in ipairs(current_type_chapters) do
        local template = CElementData.GetTemplate("QuestChapter", v.ChapterTid)

        local str = ""
        local Groups = string.split(template.TextDisplayName, ".")
        if Groups ~= nil and #Groups == 2 then 
            str =  "<color=#FBF4B8>" .. Groups[1] .."</color>" .. "  " .. Groups[2]
        else
            -- 如果可以接取 则显示任务名称 否则显示 章节名称
            if CQuest.Instance():QuestChapterIsRecieve( v.ChapterTid ) then
                local questID = CQuest.Instance():GetChapterFristQuest( v.ChapterTid )
                local QuestTemplate = CElementData.GetQuestTemplate(questID)
                str = QuestTemplate.TextDisplayName
            else
                str = template.TextDisplayName
            end
        end

        if self._CurFrameType-1 == QuestDef.QuestType.Branch then
            if CQuest.Instance():QuestChapterIsAllFinish( v.ChapterTid ) then
                str = str.."  "..StringTable.Get(595)
            elseif CQuest.Instance():QuestChapterIsRecieve( v.ChapterTid ) then
                str = str.."  "..StringTable.Get(593)
            else
                str = str.."  "..StringTable.Get(594)
            end
        end

        if groupStr == nil then
            groupStr = str
        else
            groupStr = groupStr .. "," .. str
        end
    end

    GameUtil.AdjustDropdownRect(self._Drop_QuestChapter, #self._QuestChapters[self._CurFrameType])
    
    local drop_template = self:GetUIObject("Drop_Template_QuestChapter")
    local RectTransform = drop_template:GetComponent(ClassType.RectTransform)
    if RectTransform.rect.height > 430 then
        RectTransform.sizeDelta = Vector2.New(RectTransform.rect.width,430)
    end

    local groupStr2 = nil
    for i,v in ipairs(current_type_chapters) do
        local isShow = false
        --626 红点修改
        isShow = CQuest.Instance():IsGiveRewardByQuestChapter( v.ChapterTid ) --or CQuest.Instance():QuestChapterIsRecieve( v.ChapterTid )

        if groupStr2 == nil then
            if isShow then
                groupStr2 = "0"
            else
                groupStr2 = " "
            end
        else
            if isShow then
                groupStr2 = groupStr2 .. "," .. "0"
            else
                groupStr2 = groupStr2 .. ","
            end
        end
    end
    --print(groupStr,groupStr2)
    GUI.SetDropDownOption2(self._Drop_QuestChapter, groupStr, groupStr2)
end
def.override("string", "number").OnDropDown = function(self, id, index)
    --第一次回调无效
    -- OnDropDownIndex = OnDropDownIndex + 1
    -- if OnDropDownIndex ~= 2 then
    --     return
    -- end
    print("OnDropDown",id,index)
    local current_type_chapters = self._QuestChapters[self._CurFrameType]
    self._Current_SelectData = current_type_chapters[index+1]
    self:OnSelectChapterDataChange()
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._QuestChapters = nil
    self._ChaptersTemplate_id_list = nil
    self._QuestsCanRecievedTalbe = nil
    CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestEvents)
    _G.RemoveGlobalTimer(timeID)
    repeatRewards = {}
    questModels = {}
    -- self._QuestGroups = nil
    -- self._GroupsTemplate_id_list = nil
end

def.override().OnDestroy = function(self)
        Table_QuestObj = {}

        self._List_Quest = nil
        self._List_QuestParent = nil
        self._Drop_QuestChapter = nil
        self._List_ElementsReward = nil
        self._Lab_ChapterName = nil
        self._Lab_ChapterDes = nil
        -- self._Lab_Diamond = nil
        -- self._Lab_DiamondFinish = nil
        self._Lab_QuestProvide = nil
        --self._Btn_Reward = nil
        self._Btn_GiveUp = nil
        self._Btn_Go = nil
        self._Frame_ElementsContainer = nil
        self._Frame_CurQuest = nil
        self._Lyout_Content = nil
        self._Frame_ChapterReward = nil
        self._Frame_RewardScroll = nil
        self._Img_RewardFront = nil
        self._Frame_Reward = nil
        self._Frame_NoQuest = nil
        self._Img_Map = nil
        self._Obj_Quest = nil
        self._List_ElementsRepeat = nil
        self._Frame_ElementContainerRepeat = nil

        self._Frame_ElementReputation = nil
        self._List_ElementsReputation = nil 
        self._Frame_ReputationContent = nil 
        self._Lab_ReputationName = nil 
        self._Lab_ReputationNameE = nil 
        self._Lab_ReputationDes = nil 
        self._Img_ReputationIcon = nil 
        self._Lab_ReputationLvIcon = nil 
        self._List_ReputationReward = nil 
        self._Lab_ReputationShopDes = nil 
        self._Lab_ReputationProgress = nil 
        self._Img_Front = nil 
        self._Btn_GoReputationNpc = nil
        self._Lab_ReputationFinishQuest = nil
        self._Scroll_Reward = nil
        self._FrameTopTabs = nil
end

CPanelUIQuestList.Commit()
return CPanelUIQuestList