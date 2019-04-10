local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CUIModel = require "GUI.CUIModel"
local CTeamMan = require "Team.CTeamMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
local ERule = require "PB.Template".TeamRoomConfig.Rule
local TeamMode = require "PB.data".TeamMode
local EInstanceTeamType = require "PB.Template".Instance.EInstanceTeamType

local CPanelUITeamCreate = Lplus.Extend(CPanelBase, "CPanelUITeamCreate")
local def = CPanelUITeamCreate.define
local instance = nil

def.field('userdata')._TeamListView = nil
def.field("userdata")._List = nil
--匹配按钮字体
def.field('table')._Current_SelectData = nil
def.field(CUIModel)._SelectTargetModel = nil
def.field("table")._TeamList = BlankTable
def.field("number")._TargetTeamId = 0
def.field("userdata")._OldSelectItem = nil
def.field("number")._OldSelectIdx = 0
def.field("number")._CurrentSelectTabIndex = 1
def.field("boolean")._IsTabOpen = false
def.field(CTeamMan)._TeamMan = nil
def.field("number")._LastSortIndex = 0
def.field("boolean")._LastSortUp = false
def.field("boolean")._IsSearching = false
def.field('userdata')._LastSelectItem = nil
def.field('userdata')._LastSelectSmallItemD = nil
def.field("table")._PanelObject = nil

def.static("=>",CPanelUITeamCreate).Instance = function ()
	if not instance then
        instance = CPanelUITeamCreate()
        instance._PrefabPath = PATH.UI_TeamCreate
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local function OnTeamInfoChange(sender, event)
	if instance == nil or event == nil then return end

	local TeamInfoChangeType = EnumDef.TeamInfoChangeType
	local data = event._ChangeInfo

	if event._Type == TeamInfoChangeType.TeamMode then
		if instance:SetSingleTeamMode(data.teamId, data.mode) then
            instance:SetListCount()
        end
--    elseif event._Type == TeamInfoChangeType.TARGETCHANGE then
--        instance:UpdateMatchState()
	end
end

local function OnPVEMatchChange(sender, event)
    if instance == nil or event == nil then return end
    if instance:IsShow() then
        instance:UpdateMatchState()
    end
end

local function ParseTeamInfoList(teamList)
    local team_list = {}
    for i,v in ipairs(teamList) do
        local team_item = {}
        team_item.teamID = v.teamID
        team_item.captainID = v.captainID
        team_item.capture = v.capture
        team_item.level = v.level
        team_item.Competitiveness = v.Competitiveness
        team_item.maxNum = v.maxNum
        team_item.curNum = v.curNum
        team_item.modifyRoleID = v.modifyRoleID
        team_item.tips = v.tips
        team_item.teamIconPath = v.teamIconPath
        team_item.captainLevel = v.captainLevel
        team_item.teamName = v.teamName
        team_item.memberBriefInfos = {}
        for i1,v1 in ipairs(v.memberBriefInfos) do
            local mem_item = {}
            mem_item.roleId = v1.roleId
            mem_item.name = v1.name
            mem_item.profession = v1.profession
            mem_item.level = v1.level
            mem_item.fightScore = v1.fightScore
            team_item.memberBriefInfos[#team_item.memberBriefInfos + 1] = mem_item
        end
        team_item.mode = v.mode
        team_item.levelLimit = v.levelLimit
        team_item.combatPowerLimit = v.combatPowerLimit
        team_item.isBountyMode = v.isBountyMode
        team_item.targetId = v.targetId
        team_item.isMatching = v.isMatching
        team_list[#team_list + 1] = team_item
    end
    return team_list
end


def.override().OnCreate = function(self)
    self._PanelObject = {}
    self._TeamListView = self:GetUIObject('List_TeamList'):GetComponent(ClassType.GNewList)
    self._List = self:GetUIObject("TabList"):GetComponentInChildren(ClassType.GNewTabList)
    --目标相关
    -- self._PanelObject._Img_Target = self:GetUIObject("Model_Member")
    -- self._PanelObject._Lab_TargetName = self:GetUIObject("Lab_TargetName")
    -- self._PanelObject._Lab_TargetCount = self:GetUIObject("Lab_TargetCount")
    -- self._PanelObject._Frame_Target = self:GetUIObject("Frame_TargetItem")

    self._PanelObject._Lab_Search = self:GetUIObject("Lab_Search")
    self._PanelObject._Times_Group = self:GetUIObject('Times_Group')
    self._PanelObject._MemCountAllow = self:GetUIObject("MemCountAllow")
    self._PanelObject._Lab_Times = self:GetUIObject('Lab_Times')
    self._PanelObject._Lab_Count = self:GetUIObject("Lab_Count")
    self._PanelObject._Lab_None = self:GetUIObject('Lab_None')
    self._PanelObject._List_TeamList = self:GetUIObject('List_TeamList')
    self._PanelObject._Btn_Search = self:GetUIObject('Btn_Search')
    self._PanelObject._Btn_Create = self:GetUIObject("Btn_Create")
    self._TeamMan = CTeamMan.Instance()

    self:ResetSort()

    --FIXME: 副本BUG 暂时组队模块隐掉
--    self._PanelObject._Times_Group:SetActive( false )
    self._HelpUrlType = HelpPageUrlType.Team

    CGame.EventManager:addHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:addHandler('PVEMatchEvent', OnPVEMatchChange)
end

def.override("dynamic").OnData = function(self, data)
    self:OnMenuTabChange()
    self:SetListCount()

    local teamData = self._TeamMan:GetAllTeamRoomData()
    local function CommonInit()
        self._List:SelectItem(0,-1)
        self._Current_SelectData = teamData[1].Data
    end

    --初始化
    if data ~= nil then
        local function InitByDungeonId(id)
            local b,s = self._TeamMan:GetRoomIndexByDungeonID(id)
            if b > 0 then
                self._List:SelectItem(b-1,s-1)
                if s > 0 then
                    self._Current_SelectData = teamData[b].ListData[s]
                else
                    self._Current_SelectData = teamData[b].Data
                end
            else
                CommonInit()
            end
        end
        local function InitByRoomId(id)
            local b,s = self._TeamMan:GetRoomIndexByID(id)
            if b > 0 then
                self._List:SelectItem(b-1,s-1)
                if s > 0 then
                    self._Current_SelectData = teamData[b].ListData[s]
                else
                    self._Current_SelectData = teamData[b].Data
                end
            else
                CommonInit()
            end
        end

        if data.TargetId ~= nil and data.TargetId > 0 then
            InitByDungeonId(data.TargetId)
        elseif data.TargetMatchId ~= nil then
            InitByRoomId(data.TargetMatchId)
        else
            CommonInit()
        end
    else
        CommonInit()
    end
    
    self:InitSeleteRoom()
end

--初始化房间
def.method().InitSeleteRoom = function(self)
    --初始化目标
    -- self._PanelObject._Frame_Target:SetActive( self._Current_SelectData.Model~=nil and  self._Current_SelectData.Model~="")
    -- if  self._Current_SelectData.Model~=nil and  self._Current_SelectData.Model~="" then
    --     self:SetImageModel( tonumber( self._Current_SelectData.Model) )
    -- end  
    -- self._PanelObject._Lab_TargetName:SetActive(false)
    -- self._PanelObject._Lab_TargetCount:SetActive(false)

    local bShowTimeGroup = (self._Current_SelectData.PlayingLaw ~= ERule.NONE)

    --FIXME: 副本BUG 暂时组队模块隐掉
    self._PanelObject._Times_Group:SetActive(bShowTimeGroup)
    self._PanelObject._MemCountAllow:SetActive(bShowTimeGroup)
    if bShowTimeGroup then
        local dungenonData = game._DungeonMan:GetDungeonData(self._Current_SelectData.PlayingLawParam1)
        if dungenonData == nil then
            --FIXME: 副本BUG 暂时组队模块隐掉
            self._PanelObject._Times_Group:SetActive(false)
            self._PanelObject._MemCountAllow:SetActive(false)
            warn("请查询配表 活动或副本ID 为空", self._Current_SelectData.PlayingLawParam1)
        else
            local strTimes = ""
            if dungenonData.RemainderTime <= 0 then
                strTimes = string.format(StringTable.Get(26004), dungenonData.RemainderTime, dungenonData.MaxTime)
            else
                strTimes = string.format(StringTable.Get(26005), dungenonData.RemainderTime, dungenonData.MaxTime)
            end
            GUI.SetText(self._PanelObject._Lab_Times, strTimes)
        end
    end
    local dungeon_temp = CElementData.GetTemplate("Instance", self._Current_SelectData.PlayingLawParam1)
    if dungeon_temp then
        GUI.SetText(self._PanelObject._Lab_Count, string.format(StringTable.Get(22054), dungeon_temp.MinRoleNum, dungeon_temp.MaxRoleNum))
    end
end

--设置目标
def.method("number").SetImageModel = function(self, model_asset_id)
	if self._SelectTargetModel == nil then
		self._SelectTargetModel = CUIModel.new(model_asset_id, self._PanelObject._Img_Target, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, nil)
	else
		self._SelectTargetModel:Update(model_asset_id)
	end
end

def.method().SetListCount = function(self)
    local count = #self._TeamList
    self._PanelObject._List_TeamList:SetActive(count > 0)
    self._PanelObject._Lab_None:SetActive(count==0)
    if count > 0 then
	   self._TeamListView:SetItemCount(count)
    end
end

def.method("table", "=>", "table").CalcMeetList = function(self, list)
    local meetList = {}
    for i,teamInfo in ipairs(list) do
        print("teamInfo.targetId ",teamInfo.targetId)
        local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", teamInfo.targetId)
        if teamRoomConfig ~= nil then
            if teamRoomConfig.PlayingLaw == ERule.NONE then
                --附近默认开启
                table.insert(meetList, teamInfo)
            else
                --副本是否开启
                if game._DungeonMan:DungeonIsOpen(teamRoomConfig.PlayingLawParam1) then
                    table.insert(meetList, teamInfo)
                end  
            end
        end
    end
    print("#meetList ", #meetList)
    return meetList
end

def.method("table").SetTeamList = function(self, teamList)
    local team_list = ParseTeamInfoList(teamList)
    self._TeamList = self:CalcMeetList(team_list)

	if self:IsShow() then
        self:ResetSort()
		self:SetListCount()
	end
end

-- 设置单个队伍的队伍类型（团队or队伍）
def.method("number", "number", "=>", "boolean").SetSingleTeamMode = function(self, teamID, teamMode)
    local flag = false
    if self._TeamList ~= nil then
        for i,v in ipairs(self._TeamList) do
            if v.teamID == teamID then
                v.mode = teamMode
                flag = true
            end
        end
    end
    return flag
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if id == "List_TeamList" then
        local idx = index + 1
        local infoData =  self._TeamList[idx]
        local hp = game._HostPlayer
        local lv = hp._InfoData._Level
        local fightScore = hp:GetHostFightScore()
        
        do
            -- 队伍目标
            local Lab_Target = item:FindChild("Tab_Target/Lab_Target")
            local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", infoData.targetId)
            local targetName = ""

            if teamRoomConfig == nil then
                targetName = StringTable.Get(22401)
            else
                targetName = teamRoomConfig.DisplayName
            end
            GUI.SetText(Lab_Target, targetName)
        end

        do
            -- 队伍宣言，队伍名称
            local Lab_TeamName = item:FindChild("Tab_TeamName/Lab_TeamName")
            GUI.SetText(Lab_TeamName, infoData.teamName)
        end

        do
            -- 限制等级
            local Lab_Level = item:FindChild("Tab_InNeed/Lab_Level")
            local strLevelLimit = ""
            if lv >= infoData.levelLimit then
                strLevelLimit = string.format(StringTable.Get(10641), infoData.levelLimit)
            else
                strLevelLimit = RichTextTools.GetNeedColorText(string.format(StringTable.Get(10641), infoData.levelLimit), (lv >= infoData.levelLimit))
            end
            GUI.SetText(Lab_Level, strLevelLimit)
        end

        do
            -- 限制战力
            local Lab_CombatNeed = item:FindChild("Tab_InNeed/Img_Combat/Lab_CombatNeed")
            local strCombatPowerLimit = ""
            if fightScore >= infoData.combatPowerLimit then
                strCombatPowerLimit = GUITools.FormatNumber(infoData.combatPowerLimit)
            else
                strCombatPowerLimit = RichTextTools.GetNeedColorText(GUITools.FormatNumber(infoData.combatPowerLimit), (fightScore >= infoData.combatPowerLimit))
            end
            GUI.SetText(Lab_CombatNeed, strCombatPowerLimit)
        end

        do
            local memberInfoList = {}
            for _,v in ipairs(infoData.memberBriefInfos) do
                table.insert(memberInfoList, v)
            end
            -- 设置队员信息
            local targetMemberCountMax = 5
            local Tab_MemberGroup = nil
            if infoData.mode == TeamMode.Corps then
                item:FindChild("Tab_MemberGroup"):SetActive(false)
                item:FindChild("Tab_MemberBigGroup"):SetActive(true)
                Tab_MemberGroup = item:FindChild("Tab_MemberBigGroup")
                targetMemberCountMax = 10
            else
                item:FindChild("Tab_MemberGroup"):SetActive(true)
                item:FindChild("Tab_MemberBigGroup"):SetActive(false)
                Tab_MemberGroup = item:FindChild("Tab_MemberGroup")
                targetMemberCountMax = 5
            end
            local curMemberCount = #memberInfoList
            for i = 1, targetMemberCountMax do
                local bActive = i <= curMemberCount
                
                local ui_item = Tab_MemberGroup:FindChild("Tab_MemberInfo"..i)
                
                local Img_Head = ui_item:FindChild("Img_HeadGroup/Img_Head")
                local Lab_Name = ui_item:FindChild("Lab_Name")
                local Lab_Prof = ui_item:FindChild("Lab_Prof")
                local Lab_Level = ui_item:FindChild("Lab_Level")
                Img_Head:SetActive( bActive )
                Lab_Name:SetActive( bActive )
                if Lab_Prof then
                    Lab_Prof:SetActive( bActive )
                end
                Lab_Level:SetActive( bActive )

                if bActive then
                    local memberInfo = memberInfoList[i]
                    -- 队长标志
                    local Img_LeaderTag = Img_Head:FindChild("Img_LeaderTag")
                    Img_LeaderTag:SetActive(memberInfo.roleId == infoData.captainID)
                    -- 名称
                    if infoData.mode == TeamMode.Corps then
                        if GUITools.UTFstrlen(memberInfo.name) > 5 then
                            GUI.SetText(Lab_Name, GUITools.SubUTF8String(memberInfo.name, 1, 5).."...")
                        else
                            GUI.SetText(Lab_Name, memberInfo.name)
                        end
                    else
                        GUI.SetText(Lab_Name, memberInfo.name)
                    end
                    -- 等级
                    GUI.SetText(Lab_Level, string.format(StringTable.Get(10641), memberInfo.level))

                    local professionTemplate = CElementData.GetProfessionTemplate(memberInfo.profession)
                    -- 职业名称
                    if Lab_Prof then
                        GUI.SetText(Lab_Prof, professionTemplate.Name)
                    end
                    -- 职业头像
                    if Profession2Gender[memberInfo.profession] == EnumDef.Gender.Female then
                        GUITools.SetHeadIcon(Img_Head, professionTemplate.FemaleIconAtlasPath)
                    else
                        GUITools.SetHeadIcon(Img_Head, professionTemplate.MaleIconAtlasPath)
                    end
                end
            end
        end

        do
            -- 申请按钮状态
            local Btn_Join = item:FindChild("Tab_Buttom/Btn_Join")
            local lab_tip = item:FindChild("Tab_Buttom/Lab_ApplyTip")
            local img_apply_tip = item:FindChild("Tab_Buttom/Img_ApplyTip")
            if infoData.FriendOnly or infoData.GuildOnly then
                local can_join = false
                local str = ""
                if infoData.FriendOnly and infoData.GuildOnly then
                    if game._CFriendMan:IsFriend(infoData.captainID) or game._GuildMan:IsGuildMember(infoData.captainID) then
                        can_join = true
                    else
                        str = StringTable.Get(22056)
                    end
                else
                    if infoData.FriendOnly then
                        if game._CFriendMan:IsFriend(infoData.captainID) then
                            can_join = true
                        else
                            str = StringTable.Get(22057)
                        end
                    else
                        if game._GuildMan:IsGuildMember(infoData.captainID) then
                            can_join = true
                        else
                            str = StringTable.Get(22058)
                        end
                    end
                end
                if can_join then
                    Btn_Join:SetActive(true)
                    lab_tip:SetActive(false)
                    img_apply_tip:SetActive(false)
                else
                    Btn_Join:SetActive(false)
                    lab_tip:SetActive(true)
                    img_apply_tip:SetActive(true)
                    str = string.format(StringTable.Get(10634), str)
                    GUI.SetText(lab_tip, str)
                end
            else
                Btn_Join:SetActive(true)
                lab_tip:SetActive(false)
                img_apply_tip:SetActive(false)
            end
            local canJoin = lv >= infoData.levelLimit and fightScore >= infoData.combatPowerLimit
            GameUtil.SetButtonInteractable(Btn_Join, canJoin)
            GUITools.SetBtnGray(Btn_Join, not canJoin)
            GUI.SetText(Btn_Join:FindChild("Img_Bg/Lab_Join"), StringTable.Get(22409))
        end
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == 'List_Team' then
        local idx = index + 1
        self._TargetTeamId = self._TeamList[idx].teamID

        local Img_LightBG = item:FindChild("Img_LightBG")
        if Img_LightBG then
            Img_LightBG:SetActive(true)
            
            if self._OldSelectItem ~= nil and idx ~= self._OldSelectIdx then
                local old_Img_LightBG = self._OldSelectItem:FindChild("Img_LightBG")
                old_Img_LightBG:SetActive(false)
            end
            self._OldSelectItem = item
            self._OldSelectIdx = idx
        end
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == "Btn_Join" then
        local idx = index + 1
        local infoData =  self._TeamList[idx]
        local hp = game._HostPlayer
        local lv = hp._InfoData._Level
        local fightScore = hp:GetHostFightScore()
        local canJoin = lv >= infoData.levelLimit and fightScore >= infoData.combatPowerLimit
        if canJoin then
            self._TeamMan:ApplyTeam(infoData.teamID)
            local lab_tip = item.parent:FindChild("Lab_ApplyTip")
            if lab_tip then
                lab_tip:SetActive(true)
                GUI.SetText(lab_tip, string.format(StringTable.Get(22055), StringTable.Get(22410)))
            end
            item:SetActive(false)
        else
            local str = ""
            if lv < infoData.levelLimit and fightScore < infoData.combatPowerLimit then
                str = StringTable.Get(22065)
            else
                if lv < infoData.levelLimit then
                    str = StringTable.Get(22064)
                else
                    str = StringTable.Get(22063)
                end
            end
            game._GUIMan:ShowTipText(str, false)
        end
    end
end

def.override("string").OnClick = function(self,id)
    CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:Close("CPanelUITeamCreate")
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
	elseif id == "Btn_Create" then
        local dungeon_temp = CElementData.GetTemplate("Instance", self._Current_SelectData.PlayingLawParam1)
        local team_mode = 0
        if dungeon_temp then
            if dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps then
                team_mode = TeamMode.Corps
            else
                team_mode = TeamMode.Group
            end
        end
		self._TeamMan:CreateTeam(0, 0, "",self._Current_SelectData.Id,false, team_mode)
	elseif id == "Btn_Search" then
        local is_matching = CPVEAutoMatch.Instance():IsRoomMatching(self._Current_SelectData.Id)
        if is_matching then
            game._GUIMan:Open("CPanelUITeamMatchingBoard", nil)
        else
            local panel_data = nil
            if self._Current_SelectData.Id > 1 then
                panel_data = {}
                panel_data.TargetId = self._Current_SelectData.Id
            end
            game._GUIMan:Open("CPanelUITeamMatchingBoard", panel_data)
        end
	elseif id == "Btn_Refresh" then
        --刷新此频道的队伍
        self._TeamMan:C2SGetTeamListInRoom(self._Current_SelectData.Id)
    elseif id == "Btn_AddTimes" then
        TODO()
    elseif string.find(id, "Lab_Tips") then
        local index = tonumber(string.sub(id, -1))
        self:OnClickSortIndex(index)
	end
end

def.method("number").OnClickSortIndex = function(self, index)
    if self._LastSortIndex == index then
        self._LastSortUp = not self._LastSortUp
    else
        self._LastSortUp = false
        self:GetUIObject('SortImgGroup'..index):SetActive(true)
        self:GetUIObject('Img_Up'..index):SetActive(not self._LastSortUp)
        self:GetUIObject('Img_Down'..index):SetActive(self._LastSortUp)

        if self._LastSortIndex > 0 then
            self:GetUIObject('SortImgGroup'..self._LastSortIndex):SetActive(false)
        end
    end

    self._LastSortIndex = index
    --self:SortLogic()
end

def.method().ResetSort = function(self)
    self._LastSortIndex = 0
    --self:SortLogic()
end

def.method().SortLogic = function(self)
    if self._LastSortIndex == 3 then
    --等级排序排序
        if self._LastSortUp then
            local function sortFunction(a, b)
                if a.levelLimit > b.levelLimit then
                    return true
                else
                    return false
                end
            end
            table.sort(self._TeamList, sortFunction)
        else
            local function sortFunction(a, b)
                if a.levelLimit > b.levelLimit then
                    return false
                else
                    return true
                end
            end
            table.sort(self._TeamList, sortFunction)
        end
    elseif self._LastSortIndex == 4 then
    --战斗力排序
        if self._LastSortUp then
            local function sortFunction(a, b)
                if a.combatPowerLimit > b.combatPowerLimit then
                    return true
                else
                    return false
                end
            end
            table.sort(self._TeamList, sortFunction)
        else
            local function sortFunction(a, b)
                if a.combatPowerLimit > b.combatPowerLimit then
                    return false
                else
                    return true
                end
            end
            table.sort(self._TeamList, sortFunction)
        end
    else
        self:GetUIObject('SortImgGroup3'):SetActive(false)
        self:GetUIObject('SortImgGroup4'):SetActive(false)
        return
    end 
    self:GetUIObject('Img_Up'..self._LastSortIndex):SetActive(not self._LastSortUp)
    self:GetUIObject('Img_Down'..self._LastSortIndex):SetActive(self._LastSortUp)
    self:SetListCount()
end

--菜单
def.method().OnMenuTabChange = function(self)
    if instance:IsShow() then
        local data = self._TeamMan:GetAllTeamRoomData()
        self._List:SetItemCount(#data)
    end
end

def.method('userdata','number').OnInitTabListDeep1 = function(self,item,bigTypeIndex)
    local data = self._TeamMan:GetAllTeamRoomData()
    local current_data = data[bigTypeIndex]

    local sub_count = 0
    if current_data.ListData ~= nil then
        sub_count = #current_data.ListData
    end
    local img_arrow = item:FindChild("Img_Arrow")
    GUITools.SetGroupImg(img_arrow, 0)
    GUITools.SetNativeSize(img_arrow)
    img_arrow:SetActive(sub_count > 0)

    GUI.SetText(item:FindChild("Lab_Text"), current_data.ChannelOneName)
end

def.method('userdata','number','number').OnInitTabListDeep2 = function(self,item,bigTypeIndex,smallTypeIndex)
    local data = self._TeamMan:GetAllTeamRoomData()

    local current_data = data[bigTypeIndex]
    local current_smallData = current_data.ListData[smallTypeIndex]
    local img_big_sign = item:FindChild("Img_BigSign")
    local is_dungeon_open = current_smallData.Open
    local remain_count = game._DungeonMan:GetRemainderCount(current_smallData.Data.PlayingLawParam1)

    local dungeon_temp = CElementData.GetTemplate("Instance", current_smallData.Data.PlayingLawParam1)
    local is_showBig = false
    if current_smallData.Data.PlayingLaw == require "PB.Template".TeamRoomConfig.Rule.DUNGEON  then
        if dungeon_temp then
            is_showBig = dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps
        end
    end
    img_big_sign:SetActive(is_showBig)
    if remain_count > 0 and is_dungeon_open then
        GUI.SetText(item:FindChild("Lab_Text"), current_smallData.Data.ChannelTwoName)
    else
        GUI.SetText(item:FindChild("Lab_Text"), string.format(StringTable.Get(10634), current_smallData.Data.ChannelTwoName))
    end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnInitTabListDeep1(item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnInitTabListDeep2(item,bigTypeIndex,smallTypeIndex)
        end
    end
end

def.method('userdata', 'userdata', 'number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
    local data = self._TeamMan:GetAllTeamRoomData()
    local current_bigData = data[bigTypeIndex]

    if self._LastSelectItem ~= nil then
        local last_data = data[self._CurrentSelectTabIndex]
        GUITools.SetTabListOpenTypeImg(self._LastSelectItem, EnumDef.TabListOpenType.Unselect_Close)
    end
    -- if self._LastSelectSmallItemD ~= nil then
    --     GameUtil.StopUISfx(PATH.UIFX_Team_TabMenuListItemFX,self._LastSelectSmallItemD)
    -- end
    if bigTypeIndex == 0 then
        self._List:OpenTab(0)
        self._Current_SelectData = nil
    elseif current_bigData.ListData == nil or #current_bigData.ListData == 0 then
        --如果没有小类型 直接打开
        self._List:OpenTab(0)
        self._Current_SelectData = current_bigData.Data
        self._TeamMan:C2SGetTeamListInRoom(self._Current_SelectData.Id)
        self:InitSeleteRoom()
        self:UpdateMatchState()
    else
        local function OpenTab()
            --如果有小类型 打开小类型
            local current_type_count = #data[bigTypeIndex].ListData
            self._List:OpenTab(current_type_count)
            --print("current_type_count",current_type_count)
            --默认选择了第一项
            if current_type_count > 0 then
                -- if self._LastSelectSmallItemD ~= nil then
                --     GameUtil.StopUISfx(PATH.UIFX_Team_TabMenuListItemFX,self._LastSelectSmallItemD)
                -- end
                self._LastSelectSmallItemD = self:GetUIObject("Tab1"):FindChild("Img_D")
                -- GameUtil.PlayUISfx(PATH.UIFX_Team_TabMenuListItemFX, self._LastSelectSmallItemD, self._LastSelectSmallItemD, -1)
                self:OnClickTabListDeep2(list,bigTypeIndex, self._List.SubSelected+1)
                self._IsTabOpen = true
                local img_arrow = item:FindChild("Img_Arrow")
                GUITools.SetGroupImg(img_arrow, 2)
                GUITools.SetNativeSize(img_arrow)
                GUITools.SetTabListOpenTypeImg(self._List:GetItem(bigTypeIndex-1), EnumDef.TabListOpenType.Selected_Open)
            else
                -- if self._LastSelectSmallItemD ~= nil then
                --     GameUtil.StopUISfx(PATH.UIFX_Team_TabMenuListItemFX,self._LastSelectSmallItemD)
                -- end
            end
        end

        local function CloseTab()
            self._List:OpenTab(0)
            self._IsTabOpen = false
            local img_arrow = item:FindChild("Img_Arrow")
            GUITools.SetGroupImg(img_arrow, 1)
            GUITools.SetNativeSize(img_arrow)
            -- if self._LastSelectSmallItemD ~= nil then
            --     GameUtil.StopUISfx(PATH.UIFX_Team_TabMenuListItemFX,self._LastSelectSmallItemD)
            -- end
            GUITools.SetTabListOpenTypeImg(self._List:GetItem(bigTypeIndex-1), EnumDef.TabListOpenType.Selected_Close)
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

        local sub_count = 0
        if current_bigData.ListData ~= nil then
            sub_count = #data[bigTypeIndex].ListData
        end
        if sub_count > 0 then
            self._LastSelectItem = self._List:GetItem(bigTypeIndex-1)
        else
            self._LastSelectItem = nil
        end
    end

    self._CurrentSelectTabIndex = bigTypeIndex
end

def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    local data = self._TeamMan:GetAllTeamRoomData()
    local current_bigtype = data[bigTypeIndex]

    self._Current_SelectData = current_bigtype.ListData[smallTypeIndex].Data
    self._TeamMan:C2SGetTeamListInRoom(self._Current_SelectData.Id)
    self:InitSeleteRoom()
    self:UpdateMatchState()
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    --print("OnTabListSelectItem", item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list, item, bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            -- if self._LastSelectSmallItemD ~= nil then
            --     GameUtil.StopUISfx(PATH.UIFX_Team_TabMenuListItemFX,self._LastSelectSmallItemD)
            -- end
            self._LastSelectSmallItemD = item:FindChild("Img_D")
            -- GameUtil.PlayUISfx(PATH.UIFX_Team_TabMenuListItemFX, self._LastSelectSmallItemD, self._LastSelectSmallItemD, -1)
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
    end
end


--[[
    ============================匹配逻辑代码块============================
]]

def.method().UpdateMatchState = function(self)
    if not self:IsShow() then return end

    self._PanelObject._Btn_Search:SetActive(self._Current_SelectData.Id > 1)
    local lab_search = self._PanelObject._Btn_Search:FindChild("Img_Bg/Lab_Search")
    local is_matching = CPVEAutoMatch.Instance():IsRoomMatching(self._Current_SelectData.Id)
    if is_matching then
        GUI.SetText(lab_search, StringTable.Get(22059))
    else
        GUI.SetText(lab_search, StringTable.Get(22060))
    end

    self._PanelObject._Btn_Create:SetActive(true)
    local lab_create = self._PanelObject._Btn_Create:FindChild("Img_Bg/Lab_Create")
    local dungeon_temp = CElementData.GetTemplate("Instance", self._Current_SelectData.PlayingLawParam1)
    if dungeon_temp and dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps then
        GUI.SetText(lab_create, StringTable.Get(22062))
    else
        GUI.SetText(lab_create, StringTable.Get(22061))
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function (self)
    CGame.EventManager:removeHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:removeHandler('PVEMatchEvent', OnPVEMatchChange)
    if self._SelectTargetModel ~= nil then
        self._SelectTargetModel:Destroy()
        self._SelectTargetModel = nil
    end

    self._LastSortIndex = 0
    self._TargetTeamId = 0
    self._OldSelectItem = nil
    self._OldSelectIdx = -1
    self._TeamList = nil
    self._IsTabOpen = false
    self._CurrentSelectTabIndex = 1
    self._TeamMan = nil
    self._TeamListView = nil
    self._List = nil
    self._PanelObject = nil
    self._LastSelectSmallItemD = nil

    instance = nil
end

CPanelUITeamCreate.Commit()
return CPanelUITeamCreate