local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local EAssistType = require "PB.Template".Instance.EAssistType
local EInstanceTeamType = require "PB.Template".Instance.EInstanceTeamType
local ERule = require "PB.Template".TeamRoomConfig.Rule
local CTeamMan = require "Team.CTeamMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"

local CPanelUITeamMatchingBoard = Lplus.Extend(CPanelBase, "CPanelUITeamMatchingBoard")
local def = CPanelUITeamMatchingBoard.define
local instance = nil

def.field(CTeamMan)._TeamMan = nil
def.field('userdata')._List_Left = nil
def.field('userdata')._List_Right = nil
def.field("userdata")._List_MatchingInfo = nil

def.field("table")._RoomDataList = nil
def.field("table")._MatchingList = nil
def.field("table")._Timers = nil
def.field("number")._LeftSelectIndex = 1
def.field("number")._RightSelectIndex = 0
def.field("userdata")._LeftSelectItem = nil
def.field("userdata")._RightSelectItem = nil
def.field("table")._TimesGroup = BlankTable
def.field("table")._AllowCountGroup = BlankTable
def.field("table")._SettingData = nil
def.field("table")._PanelObject = nil

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local function OnHandleMatchEvent(sender, event)
    if instance and instance:IsShow() then
        instance:UpdateMatchingList()
    end
end

def.static("=>", CPanelUITeamMatchingBoard).Instance = function()
	if not instance then
		instance = CPanelUITeamMatchingBoard()
		instance._PrefabPath = PATH.UI_TeamMatchingBoard
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._TeamMan = CTeamMan.Instance()
    self._List_Left = self:GetUIObject('List_Left'):GetComponent(ClassType.GNewList)
    self._List_Right = self:GetUIObject('List_Right'):GetComponent(ClassType.GNewList)
    self._List_MatchingInfo = self:GetUIObject('List_MatchingInfo'):GetComponent(ClassType.GNewList)

    self._TimesGroup = 
    {
        Root = self:GetUIObject('TimesGroup'),
        Lab_Times = self:GetUIObject('Lab_Times')
    }
    self._AllowCountGroup =
    {
        Root = self:GetUIObject("MemCountAllow"),
        Lab_Count = self:GetUIObject("Lab_Count")
    }
    self._PanelObject = {}
    self._PanelObject.Btn_JoinMatch = self:GetUIObject("Btn_JoinMatch")
    self._PanelObject.Btn_CancelAll = self:GetUIObject("Btn_CancelAll")
    self._PanelObject.Lab_NoMatch = self:GetUIObject("Lab_NoMatch")
    self._PanelObject.ScrollView = self:GetUIObject("ScrollView")
    CGame.EventManager:addHandler('PVEMatchEvent', OnHandleMatchEvent)
end

def.override("dynamic").OnData = function (self,data)
    self._HelpUrlType = HelpPageUrlType.TeamMatchingBoard
    -- 初始化房间数据状态
    self._RoomDataList = self._TeamMan:GetAllTeamDungeOnRoomData()
    if #self._RoomDataList == 0 then
        SendFlashMsg(StringTable.Get(22072), true)
        game._GUIMan:CloseByScript(self)
        
        return
    end

    if self._SettingData == nil then
        self._SettingData = {}
    end

    if data == nil or data.TargetId == nil then
        local current_data = self._RoomDataList[1]
        local sub_count = 0
        if current_data.ListData ~= nil then
            sub_count = #current_data.ListData
        end

        if sub_count > 0 then
            self._SettingData.TargetId = current_data.ListData[1].Data.Id
        else
            self._SettingData.TargetId = current_data.Data.Id
        end
    else
        self._SettingData.TargetId = data.TargetId
        local dungeon_id = self._TeamMan:ExchangeToDungeonId( self._SettingData.TargetId )
        local dungeon_temp = CElementData.GetTemplate("Instance", dungeon_id)
        if dungeon_temp and dungeon_temp.PlayingLaw == ERule.DUNGEON then
            CPVEAutoMatch.Instance():SendC2SMatching(self._SettingData.TargetId)
        end        
    end

    -- 重新计算位置
    self:CalcSelectIndex()
    self:OnSelectLeft()

    -- 刷新选中状态
    self:UpdateSelectState()
    -- 更新界面
    self:UpdatePanel()

    CPVEAutoMatch.Instance():SendC2SMatchList()

    CPanelBase.OnData(self,data)
end

def.method().RemoveAllTimers = function(self)
    if self._Timers ~= nil then
        for i,v in pairs(self._Timers) do
            _G.RemoveGlobalTimer(v)
        end
    end
    self._Timers = {}
end

def.method().UpdateMatchingList = function(self)
    self:RemoveAllTimers()
    self._MatchingList = CPVEAutoMatch.Instance():GetAllMatchingTable() or {}

    -- warn("#self._MatchingList > 0 ", #self._MatchingList > 0 )
    if #self._MatchingList > 0 then
        self._PanelObject.Lab_NoMatch:SetActive(false)
        self._PanelObject.ScrollView:SetActive(true)
        self._List_MatchingInfo:SetItemCount( #self._MatchingList )
    else
        self._PanelObject.Lab_NoMatch:SetActive(true)
        self._PanelObject.ScrollView:SetActive(false)
    end
end

-- 更新已选中状态，全部刷新
def.method().UpdateSelectState = function(self)
    local count = #self._RoomDataList
    self._List_Left:SetItemCount( count )
end

-- 计算选中位置
def.method().CalcSelectIndex = function(self)
    -- 计算右侧 分页签是否有内容,是否需要默认选中
    local targetId = self._SettingData.TargetId
    for i,v in ipairs(self._RoomDataList) do
        if v.Data ~= nil then
            if v.Data.Id == targetId  then
                self._LeftSelectIndex = i
                self._RightSelectIndex = 0
            end
        else
            for i1,v1 in ipairs(v.ListData) do
                if v1.Data.Id == targetId then
                    self._LeftSelectIndex = i
                    self._RightSelectIndex = i1
                end
            end
        end
    end
end

-- 重置选中位置
def.method().ResetSelectInfo = function(self)
    self._LeftSelectIndex = 1
    self._RightSelectIndex = 0
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Left" then
        local current_data = self._RoomDataList[idx]

        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")
        local img_big_sign = item:FindChild("Img_BigSign")

        Img_Select:SetActive(self._LeftSelectIndex == idx)
        Img_UnableClick:SetActive( not current_data.Open )
        img_big_sign:SetActive(false)
        GUI.SetText(Lab_TargetName, current_data.ChannelOneName)

        if self._LeftSelectIndex == idx then
            self._LeftSelectItem = Img_Select
        end
    elseif id == "List_Right" then
        local current_data = self._RoomDataList[self._LeftSelectIndex]
        local current_smallData = current_data.ListData[idx]

        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")
        local img_big_sign = item:FindChild("Img_BigSign")
        local dungeon_temp = CElementData.GetTemplate("Instance", current_smallData.Data.PlayingLawParam1)
        local dungenonData = game._DungeonMan:GetDungeonData(current_smallData.Data.PlayingLawParam1)
        local is_showBig = false
        if current_smallData.Data.PlayingLaw == require "PB.Template".TeamRoomConfig.Rule.DUNGEON  then
            if dungeon_temp then
                is_showBig = dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps
            end
        end
        img_big_sign:SetActive(is_showBig)
        Img_Select:SetActive(self._RightSelectIndex == idx)
        Img_UnableClick:SetActive( not current_smallData.Open )
        local name = current_smallData.Data.ChannelTwoName
        local limitedLv = current_smallData.Data.DisplayLevel
        local Lab_Lv = item:FindChild("Lab_Lv")
        Lab_Lv:SetActive(limitedLv>0)
        if limitedLv > 0 then
            local str = string.format(StringTable.Get(10714), limitedLv)
            GUI.SetText(Lab_Lv, str)
        end
        
        if dungenonData and dungenonData.RemainderTime <= 0 then
            GUI.SetText(Lab_TargetName, string.format(StringTable.Get(10634), name))
        else
            GUI.SetText(Lab_TargetName, name)
        end

        if self._RightSelectIndex == idx then
            self._RightSelectItem = Img_Select
        end
    elseif id == "List_MatchingInfo" then
        -- 队长有进入副本权限按钮 / 取消匹配按钮
        local is_in_team = self._TeamMan:InTeam()
        local is_leader = self._TeamMan:IsTeamLeader()
        local room_data = self._MatchingList[idx]
        local dungeon_id = self._TeamMan:ExchangeToDungeonId(room_data.TargetId)
        local dungeon_temp = CElementData.GetTemplate("Instance", dungeon_id)

        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_name = uiTemplate:GetControl(0)
        local lab_timer = uiTemplate:GetControl(1)
        local lab_ai = uiTemplate:GetControl(2)
        local btn_cancle = uiTemplate:GetControl(3)
        local btn_enter = uiTemplate:GetControl(4)
        if dungeon_temp then
            GUI.SetText(lab_name, dungeon_temp.TextDisplayName)
            lab_ai:SetActive(dungeon_temp.IsMatchEndAddAssist)
            if is_in_team then
                btn_cancle:SetActive(is_leader)
                btn_enter:SetActive(is_leader)
            else
                btn_cancle:SetActive(true)
                btn_enter:SetActive(true)
            end
            if self._Timers[room_data.TargetId] ~= nil then
                _G.RemoveGlobalTimer(self._Timers[room_data.TargetId])
            end
            local callback = function()
                local cost_time = GameUtil.GetServerTime()/1000 - room_data.StartTime
                GUI.SetText(lab_timer, GUITools.FormatTimeFromSecondsToZero(true,cost_time))
            end
            self._Timers[room_data.TargetId] = _G.AddGlobalTimer(1, false, callback)
            callback()
        else
            warn("error !!! 副本数据为空，组队配置ID：", room_data.TargetId)
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index + 1

    if id == "List_Left" then
        local Img_Select = item:FindChild("Img_Select")
        if self._LeftSelectItem ~= nil then
            self._LeftSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._LeftSelectIndex = idx
        self._LeftSelectItem = Img_Select

        -- 点击左侧页签 刷新分页签逻辑
        self:OnSelectLeft()

    elseif id == "List_Right" then
        local Img_Select = item:FindChild("Img_Select")
        if self._RightSelectItem ~= nil then
            self._RightSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._RightSelectIndex = idx
        self._RightSelectItem = Img_Select

        -- 点击右侧页签 
        self:OnSelectRight()
    elseif id == "List_MatchingInfo" then
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Btn_Enter = item:FindChild("Btn_Enter")
        local Btn_Cancel = item:FindChild("Btn_Cancel")
        local Lab_TimeCounter = item:FindChild("Lab_TimeCounter")
                
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id ~= "List_MatchingInfo" then return end
    local idx = index + 1
    local room_data = self._MatchingList[idx]
    if id_btn == "Btn_Enter" then
        -- 进入此项目副本 C2S...
        if self._TeamMan:InTeam() then
            self._TeamMan:C2SStartParepare(room_data.TargetId)
        else
            local dungeon_id = self._TeamMan:ExchangeToDungeonId(room_data.TargetId)
            game._DungeonMan:TryEnterDungeon(dungeon_id)
        end
    elseif id_btn == "Btn_Cancel" then
        -- 取消 此项目匹配 C2S...
        CPVEAutoMatch.Instance():SendC2SMatchRemove(room_data.TargetId)
    end
end

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_CancelAll" then
        if CPVEAutoMatch.Instance():IsMatching() then
            CPVEAutoMatch.Instance():SendC2SMatchRemoveAll()
        end
    elseif id == "Btn_JoinMatch" then
        self:OnClick_JoinMatch()
    end
end

def.method().OnSelectLeft = function(self)
    -- warn("OnSelectLeft...")
    local current_data = self._RoomDataList[self._LeftSelectIndex]
    local sub_count = 0
    if current_data.ListData ~= nil then
        sub_count = #current_data.ListData
    end

    -- 右侧页签 如果有数据，则默认第一项
    self._RightSelectIndex = sub_count > 0 and 1 or 0
    self._List_Right:SetItemCount( sub_count )

    if sub_count > 0 then
        -- 默认开启 二级页签的位置
        self:OnSelectRight()
    else
        self._SettingData.TargetId = current_data.Data.Id
        self:UpdatePanel()
    end
end

def.method().OnSelectRight = function(self)
    -- warn("OnSelectRight...")
    local current_data = self._RoomDataList[self._LeftSelectIndex]
    self._SettingData.TargetId = current_data.ListData[self._RightSelectIndex].Data.Id
    self:UpdatePanel()
end

def.method().OnClick_JoinMatch = function(self)
    local is_matching = CPVEAutoMatch.Instance():IsRoomMatching(self._SettingData.TargetId)
    if is_matching then
        SendFlashMsg(StringTable.Get(22070), false)
        return
    end

    if self._SettingData.TargetId > 1 then
        local dungeonTid = self._TeamMan:ExchangeToDungeonId( self._SettingData.TargetId )
        local remainderCount = game._DungeonMan:GetRemainderCount( dungeonTid )
        local dungeonTemplate = CElementData.GetTemplate("Instance", dungeonTid)

        if remainderCount > 0 then
            CPVEAutoMatch.Instance():SendC2SMatching(self._SettingData.TargetId)
        else
            game._CCountGroupMan:BuyCountGroup(remainderCount ,dungeonTemplate.CountGroupTid)
        end
    end
end


def.method().UpdatePanel = function(self)
    self:UpdateBtns()
    self:UpdateDungeonTimes()
    self:UpdateMatchingList()
end

def.method().UpdateBtns = function(self)
    local isInteam = self._TeamMan:InTeam()
    if isInteam then
        local is_leader = self._TeamMan:IsTeamLeader()
        self._PanelObject.Btn_JoinMatch:SetActive(is_leader)
        self._PanelObject.Btn_CancelAll:SetActive(is_leader)
    else
        self._PanelObject.Btn_JoinMatch:SetActive(true)
        self._PanelObject.Btn_CancelAll:SetActive(true)
    end
    GUITools.SetBtnGray(self._PanelObject.Btn_JoinMatch, false)
    if self._SettingData.TargetId > 1 then
        local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._SettingData.TargetId)
        local bDungeonIsOpen = tmpConfig.PlayingLaw == ERule.DUNGEON and game._DungeonMan:DungeonIsOpen(tmpConfig.PlayingLawParam1)
		local bFuncIsOpen = tmpConfig.PlayingLaw ~= ERule.DUNGEON and game._CFunctionMan:IsUnlockByFunTid(tmpConfig.FunTid)
        if not(bFuncIsOpen or bDungeonIsOpen) then
            GUITools.SetBtnGray(self._PanelObject.Btn_JoinMatch, true)
        end
    else
        GUITools.SetBtnGray(self._PanelObject.Btn_JoinMatch, true)
    end
end


-- 刷新副本次数, 副本开启时间
def.method().UpdateDungeonTimes = function(self)
    local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._SettingData.TargetId)
    local bShow = (tmpConfig ~= nil and tmpConfig.PlayingLawParam1 > 0)
    self._TimesGroup.Root:SetActive( bShow )
    self._AllowCountGroup.Root:SetActive(bShow)

    if bShow then
        local dungeonId =  tmpConfig.PlayingLawParam1
        local dungenonData = game._DungeonMan:GetDungeonData(dungeonId)
        local strTimes = ""
        if dungenonData.RemainderTime <= 0 then
            strTimes = string.format(StringTable.Get(26004), dungenonData.RemainderTime, dungenonData.MaxTime)
        else
            strTimes = string.format(StringTable.Get(26005), dungenonData.RemainderTime, dungenonData.MaxTime)
        end
        GUI.SetText(self._TimesGroup.Lab_Times, strTimes)

        local dungeon_temp = CElementData.GetTemplate("Instance", dungeonId)
        if dungeon_temp then
            GUI.SetText(self._AllowCountGroup.Lab_Count, string.format(StringTable.Get(22054), dungeon_temp.MinRoleNum, dungeon_temp.MaxRoleNum))
        end
    end
end

def.override().OnDestroy = function (self)
    self:RemoveAllTimers()
    CGame.EventManager:removeHandler('PVEMatchEvent', OnHandleMatchEvent)
    instance = nil
end

CPanelUITeamMatchingBoard.Commit()
return CPanelUITeamMatchingBoard