local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CUIModel = require "GUI.CUIModel"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local ChatChannel = require "PB.data".ChatChannel
local MenuComponents = require "GUI.MenuComponents"
local CFriendMan = require "Main.CFriendMan"
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
local TeamMode = require "PB.data".TeamMode

local CPanelUITeamMember = Lplus.Extend(CPanelBase, "CPanelUITeamMember")
local def = CPanelUITeamMember.define

local smallTeamMaxMemCount = 5
local bigTeamMaxMemCount = 10

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._TeamMemberList = BlankTable
def.field(CTeamMan)._TeamMan = nil
def.field("table")._UIModelList = BlankTable
def.field("boolean")._IsShowSendLinkButton = false
def.field("boolean")._IsShowBuffInfo = false
def.field("number")._TeamBuffSpecialID = 211        -- 队伍人数增加buff的起始特殊ID
def.field("number")._FriendBuffSpecialID = 211      -- 好友人数增加buff的起始特殊ID
def.field("number")._WorldChatCDTimeID = 96         -- 世界频道说话CD特殊ID
def.field("number")._NextCanWorldChatTime = 0       -- 下一次可以发送到世界频道的时间戳
def.field("number")._WorldCharmCDTimer = 0          -- 世界频道说话ui显示timer

local instance = nil
def.static('=>',CPanelUITeamMember).Instance = function ()
	if not instance then
        instance = CPanelUITeamMember()
        instance._PrefabPath = PATH.UI_TeamMember
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._TeamMan = CTeamMan.Instance()

	self._PanelObject = 
	{
		TeamMemberItemList = {},
		MemberHideGroup = {},
		Lab_AutoMatch = self:GetUIObject('Lab_AutoMatch'),
--		Lab_Convene = self:GetUIObject('Lab_Convene'),
        Frame_BuffInfo = self:GetUIObject('Frame_BuffInfo'),
        Btn_LayoutGroupLeader = self:GetUIObject("Btn_LayoutGroupL"),
        Btn_LayoutGroupMember = self:GetUIObject("Btn_LayoutGroupL2"),
        MemberGroup = self:GetUIObject("MemberGroup"),
        MemberBigGroup = self:GetUIObject("MemberBigGroup")
	}

	do
		local info = self._PanelObject.MemberHideGroup
--		info.Btn_Convene = self:GetUIObject('Btn_Convene')
		info.Btn_Begin = self:GetUIObject('Btn_Begin')
		info.Btn_ApplyList = self:GetUIObject('Btn_ApplyList')
		info.Btn_AutoMatch = self:GetUIObject('Btn_AutoMatch')
		info.SendLinkGroup = self:GetUIObject('SendLinkGroup')
		info.Btn_Send = self:GetUIObject('Btn_Send')
		info.Btn_Setting = self:GetUIObject("Btn_Setting")
		info.Btn_Disband = self:GetUIObject("Btn_Disband")
        info.Btn_ChangeToBigTeam = self:GetUIObject("Btn_ChangeToBig")
        info.Btn_ChangeToSmallTeam = self:GetUIObject("Btn_ChangeToSmall")
        info.Btn_Follow = self:GetUIObject("Btn_Follow")
		info.TeamApplyRedDotObj = info.Btn_ApplyList:FindChild("Img_Bg/Img_BtnFloatFx")
	end

	-- 刷新 组队申请红点信息
	self:UpdateTeamRedDotState() 
    self._HelpUrlType = HelpPageUrlType.Team
end

local function OnTeamInfoChange(sender, event)
	if instance == nil or event == nil then return end

	local TeamInfoChangeType = EnumDef.TeamInfoChangeType
	local data = event._ChangeInfo

	if event._Type == TeamInfoChangeType.ResetAllMember then
		instance:UpdateAll()
	elseif event._Type == TeamInfoChangeType.OnLineState then
		--warn("OnTeamInfoChange::OnLineState")
		instance:UpdateOnLineState( data )
	elseif event._Type == TeamInfoChangeType.Level then
		--warn("OnTeamInfoChange::Level")
		instance:UpdateLevel( data )
	elseif event._Type == TeamInfoChangeType.FightScore then
		--warn("OnTeamInfoChange::FightScore")
		instance:UpdateFightScore( data )
	elseif event._Type == TeamInfoChangeType.InvitateStatus then
		instance:UpdateInvitingTag()
	elseif event._Type == TeamInfoChangeType.FollowState then
        instance:UpdateLeaderBtn()
	elseif event._Type == TeamInfoChangeType.TARGETCHANGE then
        instance:UpdateTopInfo()
        instance:UpdateLeaderBtn()
    elseif event._Type == TeamInfoChangeType.NewRoleComeIn then
        instance:UpdateTopInfo()
    elseif event._Type == TeamInfoChangeType.TeamMode then
        instance:UpdateAll()
    elseif event._Type == TeamInfoChangeType.TeamSetting then
        instance:UpdateItemList()
        instance:UpdateLeaderBtn()
	    instance:UpdateMatchingTag()
        instance:UpdateTopInfo()
	elseif event._Type == TeamInfoChangeType.TeamMemberName then

	else
		-- warn("error, unknown TeamInfoChangeType! please check: ", event._Type)
	end
end

local function OnPVEMatchChange(sender, event)
    if instance == nil or event == nil then return end
    if instance:IsShow() then
        instance:UpdateItemList()
        instance:UpdateLeaderBtn()
	    instance:UpdateMatchingTag()
        instance:UpdateTopInfo()
    end
end

def.override("dynamic").OnData = function (self,data)
	self:UpdateAll()

	if game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get3V3WorldTID() then
		game._GUIMan:CloseByScript(self)	
		return
	end

	CGame.EventManager:addHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:addHandler('PVEMatchEvent', OnPVEMatchChange)
end

-- 刷新 组队申请红点信息
def.method().UpdateTeamRedDotState = function(self)
	if instance:IsShow() then
		local bShow = CRedDotMan.GetModuleDataToUserData("TeamApply") or false
		local info = self._PanelObject.MemberHideGroup
		info.TeamApplyRedDotObj:SetActive(bShow)
	end
end

def.method().UpdateTeamSetting = function(self)
	if not self:IsShow() then return end
	local strTitle = self._TeamMan:GetCurTargetString()
	GUI.SetText(self:GetUIObject('Lab_Setting'), strTitle)
end

def.method().UpdateTopInfo = function(self)
    if self:IsShow() then
        local uiTemplate = self:GetUIObject("Tab_Top"):GetComponent(ClassType.UITemplate)
        local lab_buff = uiTemplate:GetControl(2)
        local lab_exp_add = uiTemplate:GetControl(3)
        local lab_mem_count = uiTemplate:GetControl(4)
        local team_count = CTeamMan.Instance():GetMemberCount()
        GUI.SetText(lab_mem_count, team_count.."")
        -- print("team_count", team_count)
        if team_count <= 1 then
            GUI.SetText(lab_buff, StringTable.Get(22601))
            -- GUI.SetText(lab_exp_add, StringTable.Get(22601))
        else
        	-- 组队buff在人数大于5时未处理，6-10按照5来处理 （范导定的规则）
        	if team_count > 5 then team_count = 5 end
            local team_buff_value = CElementData.GetSpecialIdTemplate(self._TeamBuffSpecialID + team_count - 2).Value
            if team_buff_value == nil then
                warn("error !!! 找不到组队或者好友人数加成的特殊ID")
                return
            end
            local team_state_temp = CElementData.GetTemplate("State", tonumber(team_buff_value))
            local team_buff_string = StringTable.Get(22601)
            local friend_buff_string = StringTable.Get(22601)
            if team_state_temp ~= nil and team_state_temp.ExecutionUnits ~= nil and #team_state_temp.ExecutionUnits ~= 0 then
                local unit = team_state_temp.ExecutionUnits[1]
                local unit1 = team_state_temp.ExecutionUnits[2]

                if unit.Trigger.Timeline._is_present_in_parent ~= nil then
                    local property = unit.Event.AddAttachedProperty
                    local property1 = unit1.Event.AddAttachedProperty
                    local attach_temp = CElementData.GetAttachedPropertyTemplate(property.Id)
                    local value = tonumber(property.Value) * 100
                    local value1 = tonumber(property1.Value) * 100
                    team_buff_string = string.format(StringTable.Get(22080), value, value1)
                end
            end
            GUI.SetText(lab_buff, team_buff_string)
            -- GUI.SetText(lab_exp_add, friend_buff_string)
        end
        if self._IsShowBuffInfo then
            self:ShowBuffInfoPanel(true)
        else
            self:ShowBuffInfoPanel(false)
        end
        self:UpdateTeamSetting()
    end
end

--全部刷新
def.method().UpdateAll = function(self)
	--warn("TeamMember::UpdateAll", debug.traceback())
	self:ResetTeamMemberList()
	self:ResetItemList()
	self:UpdateItemList()
	self:UpdateLeaderBtn()
	-- self:UpdateBountyBtn()
	self:UpdateMatchingTag()
    self:UpdateTopInfo()
end

--获取队伍信息，UI内刷新用
def.method().ResetTeamMemberList = function(self)
	self._TeamMemberList = {}
	self._TeamMemberList = self._TeamMan:GetMemberList()
end

--初始化控件信息
def.method().ResetItemList = function(self)
	self._PanelObject.TeamMemberItemList = {}
    local bIsBigTeam = self._TeamMan:IsBigTeam()
	local memberCnt = #self._TeamMemberList
    local bIsMatching = CPVEAutoMatch.Instance():IsMatching()

    if bIsBigTeam then
        for i=1,10 do
            local uiTemplate = self._PanelObject.MemberBigGroup:GetComponent(ClassType.UITemplate)

            local obj = uiTemplate:GetControl(i-1)
		    if obj == nil then
			    warn("obj is null???????????")
		    end

		    local bShow = (i <= memberCnt)
            local hideGroupGO = obj:FindChild('HideGroup')
		    --先隐藏，后续需要进行邀请按钮显隐规则设计
		    hideGroupGO:SetActive(bShow)
		    obj:FindChild('Btn_AddMemeber'):SetActive((not bShow) and self._TeamMan:IsTeamLeader() and (not bIsMatching))
		    if bShow then
			    local key = self._TeamMemberList[i]._ID
			    self._PanelObject.TeamMemberItemList[key] = obj
                GameUtil.PlayUISfx(PATH.UIFX_Team_TeamMemberFX, hideGroupGO, hideGroupGO, -1, 20, -1)
            else
                GameUtil.StopUISfx(PATH.UIFX_Team_TeamMemberFX, hideGroupGO)
		    end
        end
    else
        for i=1,5 do
		    local obj = self:GetUIObject('item'..i)
		    if obj == nil then
			    warn("obj is null???????????")
		    end

		    local bShow = (i <= memberCnt)
            local hideGroupGO = obj:FindChild('HideGroup')
		    --先隐藏，后续需要进行邀请按钮显隐规则设计
		    hideGroupGO:SetActive(bShow)
		    obj:FindChild('Btn_AddMemeber'):SetActive((not bShow) and self._TeamMan:IsTeamLeader() and (not bIsMatching))
		    if bShow then
			    local key = self._TeamMemberList[i]._ID
			    self._PanelObject.TeamMemberItemList[key] = obj
                GameUtil.PlayUISfx(PATH.UIFX_Team_TeamMemberFX, hideGroupGO, hideGroupGO, -1, 20, -1)
            else
                GameUtil.StopUISfx(PATH.UIFX_Team_TeamMemberFX, hideGroupGO)
		    end
	    end
    end

	self:UpdateInvitingTag()
end

def.method().UpdateMatchingTag = function(self)
	local memberCnt = #self._TeamMemberList
	local bIsAutoMatch = CPVEAutoMatch.Instance():IsMatching()
	local bIsInviting = self._TeamMan:IsInviting()
	local bShowLoading = bIsAutoMatch or bIsInviting
    local bIsBigTeam = self._TeamMan:IsBigTeam()
    if bIsBigTeam then
        local uiTemplate = self._PanelObject.MemberBigGroup:GetComponent(ClassType.UITemplate)
        for i=1,10 do
            local obj = uiTemplate:GetControl(i-1)
		    if obj == nil then
			    warn("obj is null??????????? 1111")
		    end

		    local bShow = (i > memberCnt)
		    obj:FindChild("Img_Matching"):SetActive(bShow and bIsAutoMatch)
        end
    else
        for i=1,5 do
		    local obj = self:GetUIObject('item'..i)
		    if obj == nil then
			    warn("obj is null???????????")
		    end

		    local bShow = (i > memberCnt)
		    obj:FindChild("Img_Matching"):SetActive(bShow and bIsAutoMatch)
	    end
    end
end

def.method().UpdateInvitingTag = function(self)
	local memberCnt = #self._TeamMemberList
	local bIsAutoMatch = CPVEAutoMatch.Instance():IsMatching()
	local inviteCount = self._TeamMan:GetInvitingCount()
	local bShowLoading = bIsAutoMatch or inviteCount > 0
    local is_big_team = self._TeamMan:IsBigTeam()

    if is_big_team then
        local uiTemplate = self._PanelObject.MemberBigGroup:GetComponent(ClassType.UITemplate)
        for i=1,10 do
            local obj = uiTemplate:GetControl(i-1)
            if obj == nil then
			    warn("obj is null???????????")
		    end

		    local bShow = (i > memberCnt)
		    obj:FindChild("Lab_Inviting"):SetActive(bShow and inviteCount>=i-1)
        end
    else
        for i=1,5 do
		    local obj = self:GetUIObject('item'..i)
		    if obj == nil then
			    warn("obj is null???????????")
		    end

		    local bShow = (i > memberCnt)
		    obj:FindChild("Lab_Inviting"):SetActive(bShow and inviteCount>=i-1)
	    end
    end
end

def.method().UpdateItemList = function(self)
    local is_big_team = self._TeamMan:IsBigTeam()
    if is_big_team then
        self._PanelObject.MemberBigGroup:SetActive(true)
        self._PanelObject.MemberGroup:SetActive(false)
    else
        self._PanelObject.MemberBigGroup:SetActive(false)
        self._PanelObject.MemberGroup:SetActive(true)
    end
	for k, member in pairs( self._TeamMemberList ) do
		if self._PanelObject.TeamMemberItemList[member._ID] ~= nil then
			self:SetItemInfo(self._PanelObject.TeamMemberItemList[member._ID], member)
		else
			warn("error teaminfo Item Object nil? | ::UpdateItemList()")
		end
	end
end

--更新在线状态
def.method("table").UpdateOnLineState = function(self, data)
	if self._PanelObject.TeamMemberItemList[data.roleId] == nil then return end

	local item = self._PanelObject.TeamMemberItemList[data.roleId]
	local HideGrouproot = item:FindChild("HideGroup")
	local lab_chanel = HideGrouproot:FindChild("Lab_Chanel")
	local pLable_Name = HideGrouproot:FindChild("Lab_Name")
	local Img_OffLine = HideGrouproot:FindChild("Img_OffLine")
    -- local Img_OfflineState = HideGrouproot:FindChild("Img_OfflineGroup/Img_OfflineState")

	local memberInfo = self._TeamMan:GetMember(data.roleId)

	Img_OffLine:SetActive(not memberInfo._IsOnLine)
	GUI.SetText(pLable_Name, memberInfo._Name)
    -- Img_OfflineState:SetActive(memberInfo._IsOnLine)

	if memberInfo._IsOnLine then
    	-- local isSameLine = game._CurWorld._WorldInfo.CurMapLineId == memberInfo._LineId
    	-- local color = isSameLine and Color.New(0,1,0) or Color.New(1,0,0)
    	-- GameUtil.SetImageColor(Img_OfflineState, color)
    	local worldTemp = CElementData.GetTemplate("Map", memberInfo._MapTid)
    	if memberInfo._LineId ~= 0 then
        	GUI.SetText(lab_chanel, string.format(StringTable.Get(12028),worldTemp.TextDisplayName, memberInfo._LineId))
        else
        	GUI.SetText(lab_chanel, string.format(StringTable.Get(12034),worldTemp.TextDisplayName))
        end
    else
    	GUI.SetText(lab_chanel, StringTable.Get(22027))
    end
end

--更新等级
def.method("table").UpdateLevel = function(self, data)
	if self._PanelObject.TeamMemberItemList[data.roleId] == nil then return end

	local item = self._PanelObject.TeamMemberItemList[data.roleId]
	local lab_level = item:FindChild("HideGroup/Lab_LvValues")
	GUI.SetText(lab_level, string.format(StringTable.Get(10641), data.level))
end

--更新战斗力
def.method("table").UpdateFightScore = function(self, data)
	if self._PanelObject.TeamMemberItemList[data.roleId] == nil then return end

	local item = self._PanelObject.TeamMemberItemList[data.roleId]
	local Lab_BattleValues = item:FindChild("HideGroup/Lab_BattleValues")
	GUI.SetText(Lab_BattleValues, GUITools.FormatNumber(data.fightScore))
end

--更新队员名称
def.method("table").UpdateMemberName = function(self, data)
	if self._PanelObject.TeamMemberItemList[data.roleId] == nil then return end
	
	local memberInfo = self._TeamMan:GetMember(data.roleId)
	local item = self._PanelObject.TeamMemberItemList[data.roleId]
	local pLable_Name = item:FindChild("HideGrouproot/Lab_Name")
	GUI.SetText(pLable_Name, RichTextTools.GetOnlineColorHexText(memberInfo._Name, memberInfo._IsOnLine))
end

--设置单个UI信息
def.method("userdata", "table").SetItemInfo = function(self, item, memberInfo)
	local curItem = nil
	local leaderId = CTeamMan.Instance()._Team._TeamLeaderId
	local bIsBigTeam = self._TeamMan:IsBigTeam()

	curItem = item
	local HideGrouproot = curItem:FindChild("HideGroup")
	local pLable_Name = HideGrouproot:FindChild("Lab_Name")
	GUI.SetText(pLable_Name, RichTextTools.GetOnlineColorHexText(memberInfo._Name, memberInfo._IsOnLine))

	local Lab_LvValues = HideGrouproot:FindChild("Lab_LvValues")
	GUI.SetText(Lab_LvValues, string.format(StringTable.Get(10641), memberInfo._Lv))

	local Lab_BattleValues = HideGrouproot:FindChild("Lab_BattleValues")
	GUI.SetText(Lab_BattleValues, GUITools.FormatNumber(memberInfo._Fight))
	HideGrouproot:FindChild("Img_TeamSign"):SetActive(memberInfo._ID == leaderId)

	local Img_JobSign = HideGrouproot:FindChild("Img_JobSign")
	local professionTemplate = CElementData.GetProfessionTemplate(memberInfo._Profession)
	if professionTemplate == nil then
		warn("设置职业徽记时 读取模板错误：profession:", memberInfo._Profession)
	else
		GUITools.SetProfSymbolIcon(Img_JobSign, professionTemplate.SymbolAtlasPath)
	end
	
	local beginIndex = string.find(item.name, "m") + 1
	local strIndex = string.sub(item.name, beginIndex, -1)

	local index = tonumber(strIndex)
	local pModelObj = HideGrouproot:FindChild("Img_Role_"..(bIsBigTeam and 100 + index or index))
	if not IsNil(pModelObj) then
		self:SetImageModel(memberInfo, pModelObj)
		GUITools.RegisterImageModelEventHandler(self._Panel, pModelObj)
	end

    local isOnLine = memberInfo._IsOnLine
    local lab_chanel = HideGrouproot:FindChild("Lab_Chanel")
    -- local Img_OfflineState = HideGrouproot:FindChild("Img_OfflineGroup/Img_OfflineState")
    local Img_OffLine = HideGrouproot:FindChild("Img_OffLine")
    local worldTemp = CElementData.GetTemplate("Map", memberInfo._MapTid)

    -- Img_OfflineState:SetActive(isOnLine)
    Img_OffLine:SetActive(not isOnLine)
    if isOnLine then
    	-- local isSameLine = game._CurWorld._WorldInfo.CurMapLineId == memberInfo._LineId
    	-- local color = isSameLine and Color.New(0,1,0) or Color.New(1,0,0)
    	-- GameUtil.SetImageColor(Img_OfflineState, color)
    	if memberInfo._LineId ~= 0 then
        	GUI.SetText(lab_chanel, string.format(StringTable.Get(12028),worldTemp.TextDisplayName, memberInfo._LineId))
        else
        	GUI.SetText(lab_chanel, string.format(StringTable.Get(12034),worldTemp.TextDisplayName))
        end
    else
    	GUI.SetText(lab_chanel, StringTable.Get(22027))
    end
	local hp = game._HostPlayer
	HideGrouproot:FindChild('Img_LineOn'):SetActive(hp._ID == memberInfo._ID)
    HideGrouproot:FindChild('Img_MySelf'):SetActive(hp._ID == memberInfo._ID)
    HideGrouproot:FindChild('Img_AssistTag'):SetActive(memberInfo._IsAssist)

    -- 有队员的情况下，不会显示邀请提示
    curItem:FindChild("Lab_Inviting"):SetActive(false)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_TeamBuff" then
        local member_count = CTeamMan.Instance():GetMemberCount()
        local lab_buff_tip = item:FindChild("Lab_BuffTip")
        local special_value = CElementData.GetSpecialIdTemplate(self._TeamBuffSpecialID + index - 1).Value
        if special_value == nil then warn("error !!! 特殊ID ：", self._TeamBuffSpecialID + index - 1, "没找到") return end

        local MAX_BUFF_COUNT = 5 -- 最大BUFF数
        local team_state_temp = CElementData.GetTemplate("State", tonumber(special_value))
        local team_buff_string = StringTable.Get(22601)
        if team_state_temp ~= nil and team_state_temp.ExecutionUnits ~= nil and #team_state_temp.ExecutionUnits ~= 0 then
            local unit = team_state_temp.ExecutionUnits[1]
            local unit1 = team_state_temp.ExecutionUnits[2]
            if unit.Trigger.Timeline._is_present_in_parent ~= nil then
            	if index + 1 >= MAX_BUFF_COUNT and CTeamMan.Instance():IsBigTeam() then
            		-- 大于或等于5人，且是团队队伍
            		team_buff_string = StringTable.Get(22093)
            	else
            		team_buff_string = string.format(StringTable.Get(22092), index+1)
            	end
                local property = unit.Event.AddAttachedProperty
                local property1 = unit1.Event.AddAttachedProperty
                local attach_temp = CElementData.GetAttachedPropertyTemplate(property.Id)
                local value = tonumber(property.Value) * 100
                local value2 = tonumber(property1.Value) * 100
                local buff_content_string = string.format(StringTable.Get(22094), tostring(value), tostring(value2))
                team_buff_string = team_buff_string .. buff_content_string
            end
        end
        if (index + 1 < MAX_BUFF_COUNT and index == member_count - 1) or
           (index + 1 >= MAX_BUFF_COUNT and index <= member_count - 1) then
            GUI.SetText(lab_buff_tip, string.format(StringTable.Get(22034), team_buff_string))
        else
            GUI.SetText(lab_buff_tip, team_buff_string)
        end
    elseif id == "List_FriendBuff" then
--        local member_list = CTeamMan.Instance():GetMemberList()
--        local member_count = CTeamMan.Instance():GetMemberCount()
--        local friend_man = game._CFriendMan
--        local friend_count = 0
--        for _,v in ipairs(member_list) do
--            if friend_man:IsFriend(v._ID) then
--                friend_count = friend_count + 1
--            end
--        end
--        local lab_buff_tip = item:FindChild("Lab_BuffTip")
--        local special_value = CElementData.GetSpecialIdTemplate(self._FriendBuffSpecialID + index - 1).Value
--        if special_value == nil then warn("error !!! 特殊ID ：", self._FriendBuffSpecialID + index - 1, "没找到") return end
--        local state_temp = CElementData.GetTemplate("State", tonumber(special_value))
--        if index == friend_count then
--            GUI.SetText(lab_buff_tip, string.format(StringTable.Get(22034), state_temp.Description))
--        else
--            GUI.SetText(lab_buff_tip, state_temp.Description)
--        end
    end
end

--def.override("string", "string").OnEndEdit = function(self, id, str)
--    if id == "Input_TeamName" then
--        -- print("str  : ", str)
--        if CTeamMan.Instance()._Team._TeamName == str then return end
--        if str == nil or str == "" then
--            game._GUIMan: ShowTipText(StringTable.Get(22033),false)
--                self._PanelObject.Input_TeamNameInput.text = CTeamMan.Instance()._Team._TeamName
--            return
--        end
--        local FilterMgr = require "Utility.BadWordsFilter".Filter
--		local resultStr = FilterMgr.FilterName(str)
--        TeamUtil.ChangeTeamName(resultStr)
--    end
--end

def.override("string").OnClick = function(self,id)
	CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
	elseif id == "Btn_Leave" then
		local callback = function (ret)
	        if ret then
        		local teamId = CTeamMan.Instance():GetTeamId()
	        	TeamUtil.QuitTeam(teamId)
				game._GUIMan:CloseByScript(self)
	        end
	    end
	    local text, title, closeType = nil, nil, 0
	    if game._HostPlayer:InDungeon() and CTeamMan.Instance():HaveTeamMemberInSameMap() then
	    	title, text, closeType = StringTable.GetMsg(37)
	    	MsgBox.ShowMsgBox(text, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
	    else
	    	title, text, closeType = StringTable.GetMsg(38)
	    	MsgBox.ShowMsgBox(text, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
	    end
	elseif id == "Btn_Disband" then
		local callback = function (ret)
	        if ret then
	            TeamUtil.DisbandTeam()
				game._GUIMan:CloseByScript(self)
	        end
	    end
	    local text, title, closeType = nil, nil, 0
	    if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then
	    	TeraFuncs.SendFlashMsg(StringTable.Get(22408), false)
	    else
	    	title, text, closeType = StringTable.GetMsg(120)
	    	MsgBox.ShowMsgBox(text, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
	    end
    elseif id == "Btn_ChangeToBig" then
        if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then
            TeraFuncs.SendFlashMsg(StringTable.Get(22048), false)
        else
            local TeamMode = require "PB.data".TeamMode
            local is_matching = CPVEAutoMatch.Instance():IsMatching()
            local callback = function(val)
                if val then
                    TeamUtil.ChangeTeamMode(TeamMode.Corps)
                end
            end

            if is_matching then
                local title, msg, closeType = StringTable.GetMsg(127)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
            else
                local title, msg, closeType = StringTable.GetMsg(126)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
            end
        end
    elseif id == "Btn_ChangeToSmall" then
        if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then
            TeraFuncs.SendFlashMsg(StringTable.Get(22048), false)
        else
            local TeamMode = require "PB.data".TeamMode
            local team_mode = CTeamMan.Instance():GetTeamMode()
            local mem_count = CTeamMan.Instance():GetMemberCount()
            if mem_count > smallTeamMaxMemCount then
                TeraFuncs.SendFlashMsg(StringTable.Get(22049), false)
            else
                local is_matching = CPVEAutoMatch.Instance():IsMatching()
                local callback = function(val)
                    if val then
                    	TeamUtil.ChangeTeamMode(TeamMode.Group)
                    end
                end

                if is_matching then
                    local title, msg, closeType = StringTable.GetMsg(128)
                    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
                else
                    local title, msg, closeType = StringTable.GetMsg(125)
                    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
                end 
            end
        end
	elseif id == "Btn_ApplyList" then
		if game._HostPlayer:IsInGlobalZone() then
			TeraFuncs.SendFlashMsg(StringTable.Get(15556), false)
		else
	        if CPVEAutoMatch.Instance():IsMatching() then
	            TeraFuncs.SendFlashMsg(StringTable.Get(22066), false)
	        else
	            game._GUIMan:Open("CPanelUITeamInvite", 4)
	        end
	    end
	elseif id == "Btn_AddMemeber" then --邀请
--		if game._HostPlayer:InDungeon() and not game._GuildMan:IsGuildBattleScene() then
--			TeraFuncs.SendFlashMsg(StringTable.Get(22408), false)
--		else
--			game._GUIMan:Open("CPanelUITeamInvite",nil)
--		end
		if game._HostPlayer:IsInGlobalZone() then
			TeraFuncs.SendFlashMsg(StringTable.Get(15556), false)
		else
        	game._GUIMan:Open("CPanelUITeamInvite",nil)
        end
	elseif id == "Btn_Begin" then
        if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then
            TeraFuncs.SendFlashMsg(StringTable.Get(22048), false)
        else
        	local dungeonTid = TeamUtil.ExchangeToDungeonId(self._TeamMan._Team._Setting.TargetId)
        	local remainderCount = game._DungeonMan:GetRemainderCount(dungeonTid)
        	
        	if remainderCount > 0 then
            	TeamUtil.StartParepare(self._TeamMan._Team._Setting.TargetId)
            else
	        	local dungeonTemplate = CElementData.GetTemplate("Instance", dungeonTid)
	        	if dungeonTemplate ~= nil then
					game._CCountGroupMan:BuyCountGroup(remainderCount ,dungeonTemplate.CountGroupTid)
				end
			end
        end
	elseif id == "Btn_Setting" then
		if game._HostPlayer:IsInGlobalZone() then
			TeraFuncs.SendFlashMsg(StringTable.Get(15556), false)
		else
	        if CPVEAutoMatch.Instance():IsMatching() then
	            TeraFuncs.SendFlashMsg(StringTable.Get(22066), false)
	        else
	            if self._TeamMan:IsTeamLeader() then
				    game._GUIMan:Open("CPanelUITeamSetting", self._TeamMan._Team._Setting)
			    else
				    TeraFuncs.SendFlashMsg(StringTable.Get(213), false)
			    end
	        end
	    end
	elseif id == "Btn_Send" then
		if game._HostPlayer:IsInGlobalZone() then
			TeraFuncs.SendFlashMsg(StringTable.Get(15556), false)
		else
	        if CPVEAutoMatch.Instance():IsMatching() then
	            TeraFuncs.SendFlashMsg(StringTable.Get(22066), false)
	        else
	    		self:ShowSendLinkButtonGroup(not self._IsShowSendLinkButton)
	        end
	    end
	elseif id == "Btn_AutoMatch" then
		if game._HostPlayer:IsInGlobalZone() then
			TeraFuncs.SendFlashMsg(StringTable.Get(15556), false)
		else
			self:OnBtnAutoMatch()
		end
	elseif string.find(id, "Img_Role_") then
		local length = string.len(id)
		local smallLength = string.len("Img_Role_")+1

		local index = 0
		if length > smallLength then
			local beginIndex = smallLength+1
			local strIndex = string.sub(id, beginIndex, -1)
			index = tonumber(strIndex)
		else
			index = tonumber(string.sub(id, -1))
		end
		self:OnClickTeamMember(index)
	elseif id == "Btn_SendGuild" then
	    if self._NextCanWorldChatTime > 0 and GameUtil.GetServerTime() < self._NextCanWorldChatTime then
	    	TeraFuncs.SendFlashMsg(StringTable.Get(13003), false)
        else
			self._TeamMan:SendLinkMsg(ChatChannel.ChatChannelGuild, nil)
			self:MarkCanSendWorldChatTime()
		end
	elseif id == "Btn_SendWorld" then
		self._TeamMan:SendLinkMsg(ChatChannel.ChatChannelRecruit, nil)
		-- self:MarkCanSendWorldChatTime()
    elseif id == "Btn_BuffInfo" then
        self:ShowBuffInfoPanel(true)
    elseif id == "Btn_Follow" then
        self._TeamMan:FollowLeader( not self._TeamMan:IsFollowing())
	end

    if self._IsShowBuffInfo and id ~= "Btn_BuffInfo" then
        self:ShowBuffInfoPanel(false)
    end
    if id ~= "Btn_Send" then
		self:ShowSendLinkButtonGroup(false)
	end

	if id == "Img_BG" then return end

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.method("number").SendLinkMsg = function(self, channelType)
	if self._TeamMan._Team._Setting.TargetId > 1 then
		local ChatLinkType = require "PB.data".ChatLinkType
		local ERule = require "PB.Template".TeamRoomConfig.Rule

		local linkInfo = {}
		local chatLink = {}
	    chatLink.LinkType = ChatLinkType.ChatLinkType_Team
	    chatLink.ContentID = self._TeamMan._Team._ID
	    linkInfo.ChatLink = chatLink

	    local lv = self._TeamMan._Team._Setting.Level
	    local combatPower = self._TeamMan._Team._Setting.CombatPower
	    local targetId = self._TeamMan._Team._Setting.TargetId

		linkInfo.chatChannel = channelType
		linkInfo.TargetId = targetId
		linkInfo.Level = lv
		linkInfo.CombatPower = combatPower
		linkInfo.TeamName = CTeamMan.Instance():GetTeamName()
		
	    require "Chat.ChatManager".Instance():ChatOtherSend(linkInfo)

	    if channelType == ChatChannel.ChatChannelRecruit then
	    	self:MarkCanSendWorldChatTime()
	    end
	else
		TeraFuncs.SendFlashMsg(StringTable.Get(22020), false)
	end
end

def.method("boolean").ShowSendLinkButtonGroup = function(self, bShow)
	if self._PanelObject == nil then return end
	
	self._PanelObject.MemberHideGroup.SendLinkGroup:SetActive(bShow)
	self._IsShowSendLinkButton = bShow
--[[
    local uiTemplate = self._PanelObject.MemberHideGroup.SendLinkGroup:GetComponent(ClassType.UITemplate)
    local lab_send_world = uiTemplate:GetControl(1)
    local img_send_world = uiTemplate:GetControl(2)
    local btn_send_world = uiTemplate:GetControl(5)
    if bShow then
        if self._WorldCharmCDTimer ~= 0 then
            _G.RemoveGlobalTimer(self._WorldCharmCDTimer)
            self._WorldCharmCDTimer = 0
        end
        if GameUtil.GetServerTime() > self._NextCanWorldChatTime then
            GameUtil.MakeImageGray(img_send_world, false)
            GameUtil.SetButtonInteractable(btn_send_world, true)
            GUI.SetText(lab_send_world, StringTable.Get(22040))
        else
            GameUtil.MakeImageGray(img_send_world, true)
            GameUtil.SetButtonInteractable(btn_send_world, false)
            local callback = function()
                local remain_time = (self._NextCanWorldChatTime - GameUtil.GetServerTime())/1000
                remain_time = math.floor(remain_time)
                if remain_time <= 0 then
                    _G.RemoveGlobalTimer(self._WorldCharmCDTimer)
                    self._WorldCharmCDTimer = 0
                    GUI.SetText(lab_send_world, StringTable.Get(22040))
                    GameUtil.MakeImageGray(img_send_world, false)
                    GameUtil.SetButtonInteractable(btn_send_world, true)
                else
                    GUI.SetText(lab_send_world, string.format(StringTable.Get(22042), remain_time))
                end
            end
            self._WorldCharmCDTimer = _G.AddGlobalTimer(1, false, callback)
        end
    else
        if self._WorldCharmCDTimer ~= 0 then
            _G.RemoveGlobalTimer(self._WorldCharmCDTimer)
            self._WorldCharmCDTimer = 0
        end
    end
]]
end

def.method().MarkCanSendWorldChatTime = function(self)
    local cd_value = tonumber(CElementData.GetSpecialIdTemplate(self._WorldChatCDTimeID).Value)
    self._NextCanWorldChatTime = GameUtil.GetServerTime() + cd_value * 1000
end

def.method("boolean").ShowBuffInfoPanel = function(self, bShow)
	if self._PanelObject == nil then return end
	
    self._PanelObject.Frame_BuffInfo:SetActive(bShow)
    self._IsShowBuffInfo = bShow
    if bShow then
        local friend_man = game._CFriendMan
        local member_list = CTeamMan.Instance():GetMemberList()
        local member_count = CTeamMan.Instance():GetMemberCount()
        local friend_count = 0
        for _,v in ipairs(member_list) do
            if friend_man:IsFriend(v._ID) then
                friend_count = friend_count + 1
            end
        end
        local uiTemplate = self._PanelObject.Frame_BuffInfo:GetComponent(ClassType.UITemplate)
        local tab_team_buff = uiTemplate:GetControl(0)
        local tab_friend_buff = uiTemplate:GetControl(1)
        local tab_other_buff = uiTemplate:GetControl(2)
        local list_teambuff = uiTemplate:GetControl(3)
        -- local list_friendbuff = uiTemplate:GetControl(4)
        tab_friend_buff:SetActive(false)
        tab_other_buff:SetActive(false)
        list_teambuff:GetComponent(ClassType.GNewList):SetItemCount(4)
        -- list_friendbuff:GetComponent(ClassType.GNewList):SetItemCount(0)
    end
end

def.method().OnBtnAutoMatch = function(self)
    local is_leader = self._TeamMan:IsTeamLeader()
    local is_matching = CPVEAutoMatch.Instance():IsMatching()
    local is_in_dungeon = game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate()
    -- if not is_leader then
    --     TeraFuncs.SendFlashMsg(StringTable.Get(22067), false)
    --     return
    -- end
    if is_in_dungeon then
        TeraFuncs.SendFlashMsg(StringTable.Get(22048), false)
        return
    end
    if is_matching then
        game._GUIMan:Open("CPanelUITeamMatchingBoard", nil)
    else
        local panel_data = nil
        if self._TeamMan._Team._TargetId > 0 then
        	panel_data = {}
            panel_data.TargetId = self._TeamMan._Team._TargetId
        end
        game._GUIMan:Open("CPanelUITeamMatchingBoard", panel_data)
    end
    
end

--def.method().SetAutoMatchText = function(self)
--    local is_matching = CPVEAutoMatch.Instance():IsMatching()
--	if is_matching then
--		GUI.SetText(self._PanelObject.Lab_AutoMatch, StringTable.Get(242))
--	else
--		GUI.SetText(self._PanelObject.Lab_AutoMatch, StringTable.Get(241))
--	end

--	self:UpdateMatchingTag()
--end

def.method("number").OnClickTeamMember = function(self, index)
	local memberCount = #self._TeamMemberList
	if index == 0 then index = 10 end

	--队长，或多出队员总数的情况忽略
	if index > memberCount then return end

	local member = self._TeamMemberList[index]

	if member._IsAssist or member._ID == game._HostPlayer._ID then return end

	local comps = {
        MenuComponents.SeePlayerInfoComponent.new(member._ID),
        MenuComponents.ChatComponent.new(member._ID),
        MenuComponents.AddFriendComponent.new(member._ID),
        MenuComponents.KickTeamComponent.new(member._ID),
        MenuComponents.ExchangeTeamLeaderComponent.new(member._ID)
    }
    local item = self._PanelObject.TeamMemberItemList[member._ID]
    local btn_add = item ~= nil and item:FindChild("Btn_AddMemeber") or item
	--local item = self:GetUIObject('item'..index):FindChild("Btn_AddMemeber")
    MenuList.Show(comps, btn_add, EnumDef.AlignType.Center)
end

def.method().UpdateLeaderBtn = function (self)
    if not self:IsShow() then return end
	local info = self._PanelObject.MemberHideGroup
	local bIsLeader = self._TeamMan:IsTeamLeader()
    local bIsBigTeam = self._TeamMan:IsBigTeam()
    local bIsInDungeon = game._HostPlayer:IsInGlobalZone() or game._HostPlayer:InImmediate()
    local bIsMatching = CPVEAutoMatch.Instance():IsMatching()
    local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._TeamMan._Team._TargetId)
    self._PanelObject.Btn_LayoutGroupLeader:SetActive(bIsLeader)
    self._PanelObject.Btn_LayoutGroupMember:SetActive(not bIsLeader)

--	info.Btn_Send:SetActive(bIsLeader)
--	info.Btn_Disband:SetActive(bIsLeader)
--	info.Btn_Convene:SetActive(bIsLeader)
	info.Btn_ApplyList:SetActive(bIsLeader)
	info.Btn_Begin:SetActive(bIsLeader and tmpConfig ~= nil and (tmpConfig.PlayingLaw == require "PB.Template".TeamRoomConfig.Rule.DUNGEON))
	info.Btn_AutoMatch:SetActive(true)
    info.Btn_ChangeToSmallTeam:SetActive(bIsLeader and bIsBigTeam)
    info.Btn_ChangeToBigTeam:SetActive(bIsLeader and not bIsBigTeam)

    GUITools.SetBtnGray(info.Btn_Disband, bIsInDungeon)
    GUITools.SetBtnGray(info.Btn_AutoMatch, bIsInDungeon)
    GUITools.SetBtnGray(info.Btn_ChangeToSmallTeam, bIsInDungeon)
    GUITools.SetBtnGray(info.Btn_ChangeToBigTeam, bIsInDungeon)
    GUITools.SetBtnGray(info.Btn_Send, bIsInDungeon or bIsMatching)
    GUITools.SetBtnGray(info.Btn_Begin, bIsInDungeon)
    GUITools.SetBtnGray(info.Btn_ApplyList, bIsInDungeon or bIsMatching)
    GUITools.SetBtnGray(info.Btn_Setting, bIsMatching)

    local lab_match = info.Btn_AutoMatch:FindChild("Img_Bg/Lab_AutoMatch")
    if bIsMatching then
        GUI.SetText(lab_match, StringTable.Get(22059))
    else
        GUI.SetText(lab_match, StringTable.Get(22060))
    end

    if not bIsLeader then
        local lab_follow = info.Btn_Follow:FindChild("Img_Bg/Lab_Follow")
        local is_following = self._TeamMan:IsFollowing()
        GUI.SetText(lab_follow, is_following and StringTable.Get(231) or StringTable.Get(22009))
    end
	info.SendLinkGroup:SetActive(false)
	self._IsShowSendLinkButton = false
end

-- def.method().UpdateBountyBtn = function (self)
-- 	if not self:IsShow() then return end

--     local b_isLeader = self._TeamMan:IsTeamLeader()
--     local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", self._TeamMan._Team._TargetId)
--     if roomTemplate ~= nil then
--     	local ERule = require "PB.Template".TeamRoomConfig.Rule

-- 	    --如果是队长 显示控制按钮，如果是队员，显示赏金奖励信息
-- 		local bShow = (self._TeamMan:IsBountyMode() and roomTemplate.PlayingLaw == ERule.DUNGEON) 

-- 	 	if bShow then
-- 			if b_isLeader then
-- 				local str = string.format(StringTable.Get(22008))
-- 				GUI.SetText(self._PanelObject.Lab_BountyModeReward, str)
-- 			else
-- 				if roomTemplate ~= nil then
-- 					--扣税，除队长以外平分
-- 					local CSpecialIdMan = require  "Data.CSpecialIdMan"
-- 					local bountyTax = tonumber(CSpecialIdMan.Get("BountyTax"))
-- 					local val = roomTemplate.BountyNum * (1 - bountyTax)
-- 					local memberCnt = self._TeamMan:GetMemberCount() - 1
-- 					val = math.floor( val / memberCnt )
-- 					local str = string.format(StringTable.Get(249), val)

-- 					GUI.SetText(self._PanelObject.Lab_BountyModeReward, str)
-- 				end
-- 			end
--             GameUtil.PlayUISfx(PATH.UIFX_Team_EnableBounty, self:GetUIObject("Lab_BountyModeReward"), self:GetUIObject("Lab_BountyModeReward"), -1)
--             GameUtil.PlayUISfx(PATH.UIFX_Team_EnableBountyIcon, self:GetUIObject("Img_Point"), self:GetUIObject("Img_Point"), -1)
--         else
--             GameUtil.StopUISfx(PATH.UIFX_Team_EnableBounty, self:GetUIObject("Lab_BountyModeReward"))
--             GameUtil.StopUISfx(PATH.UIFX_Team_EnableBountyIcon, self:GetUIObject("Img_Point"))
-- 		end
-- 	end
-- end

--def.method().UpdateTeamName = function(self)
--    -- print("更新队伍名字 重新设置", CTeamMan.Instance():GetTeamName())
--    local is_leader = self._TeamMan:IsTeamLeader()
--    if is_leader then
--        self._PanelObject.Tab_MemberCanSee:SetActive(false)
--        self._PanelObject.Tab_LeaderCanSee:SetActive(true)
--        self._PanelObject.Input_TeamNameInput.text = CTeamMan.Instance():GetTeamName()
--    else
--        self._PanelObject.Tab_MemberCanSee:SetActive(true)
--        self._PanelObject.Tab_LeaderCanSee:SetActive(false)
--        local lab_team_name = self._PanelObject.Tab_MemberCanSee:FindChild("Lab_TeamName")
--        if lab_team_name then
--            GUI.SetText(lab_team_name, CTeamMan.Instance():GetTeamName())
--        end
--    end
--end

def.method().UpdateTeamInfo = function (self)
	if IsNil(self._Panel) then return end

	for k,v in pairs(self._UIModelList) do
		if not self._TeamMan:IsTeamMember(k) and not IsNil(v) then
			v:Destroy()
			self._UIModelList[k] = nil
		end
	end

	self:UpdateAll()
end

--根据obj查找CuiModel
def.method("userdata", "=>", "number").FindModel = function (self, pImgObj)
    local ret = -1

	for k,v in pairs(self._UIModelList) do
		if v._RoleImg == pImgObj then
            ret = k
            break
		end
	end

    return ret
end

def.method("table", "userdata").SetImageModel = function(self, memberInfo, pImgObj)
	    local memberId = memberInfo._ID
	    local hostId = game._HostPlayer._ID
	    local bIsBigTeam = self._TeamMan:IsBigTeam()

        local umKey =  self:FindModel(pImgObj)
        if umKey ~= -1 then

            --warn("Des ImageModel "..pImgObj.name..", "..memberId)

            self._UIModelList[umKey]:Destroy()
            self._UIModelList[umKey] = nil
        end

	    if memberId ~= umKey and self._UIModelList[memberId] ~= nil then

            --warn("Des ImageModel "..self._UIModelList[memberId]._RoleImg.name..", "..memberId)

            self._UIModelList[memberId]:Destroy()
            self._UIModelList[memberId] = nil
        end


        local model = nil
        local profession = 0
        if memberId == hostId then
	        model = GUITools.CreateHostUIModel(pImgObj, EnumDef.RenderLayer.UI, nil)
            profession = game._HostPlayer._InfoData._Prof
        else
	        model = CUIModel.new(memberInfo._Param, pImgObj, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, nil)
            profession = memberInfo._Profession
        end

        --warn("SetImageModel "..pImgObj.name..", "..memberId)

        model:AddLoadedCallback(function() 
            -- model:SetModelParam(self._PrefabPath, profession)
            model:SetModelParamEx(self._PrefabPath, bIsBigTeam and 101 or 1, profession)
            end)

        self._UIModelList[memberId] = model
    --	else
    --		local model = self._UIModelList[memberId]
    --		model:ChangeTargetImage(pImgObj, true)

    --        model:AddLoadedCallback(function() 
    --            model:SetModelParam(self._PrefabPath, profession)
    --            end)
    --	end
end
 
def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	CGame.EventManager:removeHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    CGame.EventManager:removeHandler('PVEMatchEvent', OnPVEMatchChange)
	for k,v in pairs(self._UIModelList) do
		v:Destroy()
	end
	self._UIModelList = {}
    if self._WorldCharmCDTimer ~= 0 then
        _G.RemoveGlobalTimer(self._WorldCharmCDTimer)
        self._WorldCharmCDTimer = 0
    end
    self._IsShowBuffInfo = false
end

def.override().OnDestroy = function(self)
    self._PanelObject = nil
end

CPanelUITeamMember.Commit()
return CPanelUITeamMember