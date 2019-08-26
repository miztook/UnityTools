local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CTeamMan = require "Team.CTeamMan"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local TeamMode = require "PB.data".TeamMode
local CPageTeam = Lplus.Class("CPageTeam")
local def = CPageTeam.define

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._TeamMan = nil
def.field("number")._TargetMemberId = 0
def.field("number")._MatchTimer = 0
def.field("number")._InVisionTimer = 0
def.field("table")._TeamMemberItemList = BlankTable
def.field("table")._BigTeamMemberItemList = BlankTable
def.field("table")._TeamMemberList = BlankTable

local instance = nil
def.static("table", "userdata", "=>", CPageTeam).new = function(parent, panel)
	if instance == nil then
		instance = CPageTeam()
		instance._Panel = panel
		instance._Parent = parent
        instance._TeamMan = CTeamMan.Instance()
	end
	return instance
end

--[[
	TeamInfoChangeType = 
    {
        ResetAllMember  = 0,    --全部刷新，包括队伍成
        Hp              = 1,    --血量变化
        OnLineState     = 2,    --在线状态
        MapInfo         = 3,    --地图线路变化
        Level           = 4,    --等级变化
        FollowState     = 5,    --跟随
        FightScore      = 6,    --战斗力变化
        Bounty          = 7,    --赏金模式
        TARGETCHANGE    = 8,    --目标改变
        MATCHSTATECHANGE= 9,    --匹配状态改变
    },
]]
local function OnTeamInfoChange(sender, event)
	if instance == nil or event == nil then return end

	local TeamInfoChangeType = EnumDef.TeamInfoChangeType
	local data = event._ChangeInfo

	if event._Type == TeamInfoChangeType.ResetAllMember then
		instance:UpdateAll()
	elseif event._Type == TeamInfoChangeType.Hp then
		-- warn("OnTeamInfoChange::Hp")
		instance:UpdateHp( data )
	elseif event._Type == TeamInfoChangeType.OnLineState then
		--warn("OnTeamInfoChange::OnLineState")
		instance:UpdateOnLineState( data )
	elseif event._Type == TeamInfoChangeType.MapInfo then
		--warn("OnTeamInfoChange::MapInfo")
		instance:UpdateMapInfo( data )
	elseif event._Type == TeamInfoChangeType.Level then
		--warn("OnTeamInfoChange::Level")
		instance:UpdateLevel( data )
	elseif event._Type == TeamInfoChangeType.FollowState then
		--warn("OnTeamInfoChange::FollowState")
		instance:UpdateFollowState( data )
    elseif event._Type == TeamInfoChangeType.NewRoleComeIn then
        instance:OnNewRoleComeIn( data )
	elseif event._Type == TeamInfoChangeType.DeadState then
		instance:UpdateDeadState( data )
	elseif event._Type == TeamInfoChangeType.TARGETCHANGE then
        instance:UpdateAll()
    elseif event._Type == TeamInfoChangeType.TeamMode then
        instance:UpdateAll()
	elseif event._Type == TeamInfoChangeType.TeamMemberName then
		instance:UpdateMemberName( data )
	else
		-- warn("error, unknown TeamInfoChangeType! please check:", event._Type)
	end
end

def.method().Show = function(self)
	self._Panel:SetActive(true)
	self:UpdateAll()

    self:AddInVisionTimer()
	CGame.EventManager:addHandler('TeamInfoChangeEvent', OnTeamInfoChange)
end

def.method().AddInVisionTimer = function(self)
    if self._InVisionTimer ~= 0 then
        _G.RemoveGlobalTimer(self._InVisionTimer)
        self._InVisionTimer = 0
    end

    local callback = function()
        self:UpdateInVision()
    end
    self._InVisionTimer = _G.AddGlobalTimer(1, false, callback)
end

def.method().RemoveInVisionTimer = function(self)
    if self._InVisionTimer ~= 0 then
        _G.RemoveGlobalTimer(self._InVisionTimer)
        self._InVisionTimer = 0
    end
end

-- def.method().UpdateTargetTab = function(self)
--     local lab_target = self._Panel:FindChild("FrameMatching/Tab_MatchingInfo/Lab_Target")
--     local lab_match_time = self._Panel:FindChild("FrameMatching/Tab_MatchingInfo/Lab_MatchTime")
--     local match_id = self._TeamMan:GetTargetMatchId()
--     local team_room_temp = CElementData.GetTemplate("TeamRoomConfig", match_id)
--     if team_room_temp then
--         GUI.SetText(lab_target, team_room_temp.DisplayName)
--     else
--         GUI.SetText(lab_target, StringTable.Get(22011))
--     end
--     GUI.SetText(lab_match_time, CPVPAutoMatch.Instance():GetAutoMatchingTimeStr())
--     if self._MatchTimer ~= 0 then
--         _G.RemoveGlobalTimer(self._MatchTimer)
--         self._MatchTimer = 0
--     end
--     local callback = function()
--         GUI.SetText(lab_match_time, CPVPAutoMatch.Instance():GetAutoMatchingTimeStr())
--     end
--     self._MatchTimer = _G.AddGlobalTimer(1, false, callback)
-- end

def.method("table").UpdateDeadState = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local info = CTeamMan.Instance():GetMember(data.roleId)
	local item = self._TeamMemberItemList[data.roleId]
	local imgHeadBack = item:FindChild("Fram_Head/Img_HeadBack")
	-- local imgHead = item:FindChild("Fram_Head/Img_HeadIcon")
    local lab_level = item:FindChild("Img_LevelBroad/Lab_Level")
    local lab_name = item:FindChild("Lab_Name")
    local img_dead = item:FindChild("Img_Dead")


    local member = self._TeamMan:GetMember(data.roleId)
    local bIsInVision = false
    if member then
	    local player = game._CurWorld:FindObject(member._ID)
	    if player ~= nil or member._IsAssist then
	    	bIsInVision = true
	    end
	end

	if data.DeadState then
        local text_color = Color.New(100/255, 100/255, 100/255)
        GameUtil.SetTextColor(lab_level:GetComponent(ClassType.Text), text_color)
        GameUtil.SetTextColor(lab_name:GetComponent(ClassType.Text), text_color)
		local color = Color.New(245/255,100/255,100/255)
		GameUtil.SetImageColor(imgHeadBack, color)
        img_dead:SetActive(info._IsOnLine)
	else
		local color = Color.New(1,1,1)
        GameUtil.SetTextColor(lab_level:GetComponent(ClassType.Text), color)
        GameUtil.SetTextColor(lab_name:GetComponent(ClassType.Text), color)
        GameUtil.SetImageColor(imgHeadBack, color)
        img_dead:SetActive(false)

		GameUtil.SetCanvasGroupAlpha(item, bIsInVision and 1 or 0.5)
	end
end
--更新血量
def.method("table").UpdateHp = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local item = self._TeamMemberItemList[data.roleId]
	local bld_hp = item:FindChild("Bld_HP"):GetComponent(ClassType.GBlood)
	local lab_hp = item:FindChild("Bld_HP/Lab_Num")

	local world_obj = nil
	local num = 1
	if game._CurWorld ~= nil then 
		world_obj = game._CurWorld:FindObject( data.roleId )
	end

	local curHp = 0
	if world_obj ~= nil and 0 ~= world_obj._InfoData._MaxHp then
		num = world_obj._InfoData._CurrentHp / world_obj._InfoData._MaxHp
		curHp = world_obj._InfoData._CurrentHp
	elseif 0 ~= data.MaxHp then
		num = data.HP / data.MaxHp
		curHp = data.HP
	end
	bld_hp:SetValue(num)
	GUI.SetText(lab_hp, tostring(math.ceil(curHp)))
	self:UpdateDeadState({roleId = data.roleId, DeadState = curHp <= 0})
end
--更新等级
def.method("table").UpdateLevel = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local item = self._TeamMemberItemList[data.roleId]
	local lab_level = item:FindChild("Img_LevelBroad/Lab_Level")
	local str = string.format(StringTable.Get(10641), data.level)
	GUI.SetText(lab_level, str)
end
--更新地图&线路
def.method("table").UpdateMapInfo = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	--TODO("队员切换地图&线路，待服务器增加线路后处理")
end
--更新在线状态
def.method("table").UpdateOnLineState = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local info = CTeamMan.Instance():GetMember(data.roleId)
	local item = self._TeamMemberItemList[data.roleId]
	local img_off_line = item:FindChild("Img_OffLine")
	img_off_line:SetActive(not data.isOnline)

    local img_dead = item:FindChild("Img_Dead")
    if data.isOnline then
    	img_dead:SetActive(info._Hp <= 0)
    else
    	img_dead:SetActive(false)
    end
end

--更新跟随状态
def.method("table").UpdateFollowState = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local item = self._TeamMemberItemList[data.roleId]
	local lab_follow = item:FindChild("Lab_Name/Lab_Follow")
	lab_follow:SetActive(data.isFollow)
end

def.method("table").UpdateMemberName = function(self, data)
	if self._TeamMemberItemList[data.roleId] == nil then return end

	local item = self._TeamMemberItemList[data.roleId]
	local Lab_Name = item:FindChild("Lab_Name")
	local memberInfo = self._TeamMan:GetMember(data.roleId)

	local team_mode = self._TeamMan:GetTeamMode()
    if team_mode == TeamMode.Corps then
        local str = memberInfo._Name
        local len = GUITools.UTFstrlen(str)
        if len > 5 then
            str = GUITools.SubUTF8String(memberInfo._Name, 1, 5).."..."
        end
        GUI.SetText(Lab_Name, str)
    else
	    GUI.SetText(Lab_Name, memberInfo._Name)
    end
end

-- 更新是否在视野范围之内
def.method().UpdateInVision = function(self)
    for k, member in pairs( self._TeamMemberList ) do
        if member._Hp > 0 then
		    if self._TeamMemberItemList[member._ID] ~= nil then
                local item = self._TeamMemberItemList[member._ID]
	            local player = game._CurWorld:FindObject( member._ID )
	            local bIsInVision = player ~= nil or member._IsAssist

	            GameUtil.SetCanvasGroupAlpha(item, bIsInVision and 1 or 0.5)
		    else
			    warn("error teaminfo Item Object nil? | ::UpdateInVision()")
		    end
        end
	end
end

--设置单个UI信息
def.method("userdata", "table").SetItemInfo = function(self, item, memberInfo)
	if memberInfo == nil then
		warn("CPageTeam :: the memberInfo is nil.")
		return
	end
    local team_mode = self._TeamMan:GetTeamMode()
	local img_head = item:FindChild("Fram_Head/Img_HeadIcon")
	local img_leader_tag = item:FindChild("Fram_Head/Img_LeaderTag")
	local img_assist_tag = item:FindChild("Fram_Head/Img_AssistTag")
	local lab_level = item:FindChild("Img_LevelBroad/Lab_Level")
	--local lab_follow = item:FindChild("Fram_Head/Lab_Follow")
	local lab_name = item:FindChild("Lab_Name")
	local bld_hp = item:FindChild("Bld_HP"):GetComponent(ClassType.GBlood)
	local lab_hp = item:FindChild("Bld_HP/Lab_Num")
	local lab_map_name = item:FindChild("Lab_MapName")
	local img_off_line = item:FindChild("Img_OffLine")
    local lab_follow = item:FindChild("Lab_Name/Lab_Follow")
	--local ImgJobSign = item:FindChild("Fram_Head/Img_JobSign")
    if team_mode == TeamMode.Corps then
        local img_hp_front = item:FindChild("Bld_HP/Img_Front")
        GUITools.SetGroupImg(img_hp_front, memberInfo._Profession - 1)
        local str = memberInfo._Name
        local len = GUITools.UTFstrlen(str)
        if len > 3 then
            str = GUITools.SubUTF8String(memberInfo._Name, 1, 3).."..."
        end

        GUI.SetText(lab_name, str)
    else
	    GUI.SetText(lab_name, memberInfo._Name)
    end

	img_off_line:SetActive(not memberInfo._IsOnLine)

	local professionTemplate = CElementData.GetProfessionTemplate(memberInfo._Profession)
	GUITools.SetProfSymbolIcon(img_head, professionTemplate.SymbolAtlasPath)

	img_leader_tag:SetActive(self._TeamMan:IsTeamLeaderById(memberInfo._ID))
	img_assist_tag:SetActive(memberInfo._IsAssist)

	local lab_level = item:FindChild("Img_LevelBroad/Lab_Level")
	GUI.SetText(lab_level, tostring(memberInfo._Lv))

	local world_obj = nil
	local num = 1
	local curHp = 0
	if game._CurWorld ~= nil then
		world_obj = game._CurWorld:FindObject(memberInfo._ID)
	end
	if world_obj ~= nil and 0 ~= world_obj._InfoData._MaxHp then
		num = world_obj._InfoData._CurrentHp / world_obj._InfoData._MaxHp
		curHp = world_obj._InfoData._CurrentHp
	elseif 0 ~= memberInfo._HpMax then
		num = memberInfo._Hp / memberInfo._HpMax
		curHp = memberInfo._Hp
	end
	bld_hp:SetValue(num)
	GUI.SetText(lab_hp, tostring(math.ceil(curHp)))
	
	lab_follow:SetActive(memberInfo._IsFollow)
	--FIXME::不在同地图显示，默认关闭
	lab_map_name:SetActive(false)
end

def.method().UpdateAll = function(self)
    self._TeamMemberList = {}
    local list = self._TeamMan:GetMemberList()
    local hpId = game._HostPlayer._ID
    for i,v in ipairs(list) do
		if v._ID ~= hpId then
			table.insert(self._TeamMemberList, v)
		end
	end
	self:ResetItemList()
	self:UpdateItemList()
	for i,member in ipairs(self._TeamMemberList) do
		self:UpdateDeadState({roleId = member._ID, DeadState = member._Hp <= 0})
	end
end

def.method().UpdateItemList = function(self)
	for k, member in pairs( self._TeamMemberList ) do
		if self._TeamMemberItemList[member._ID] ~= nil then
			self:SetItemInfo(self._TeamMemberItemList[member._ID], member)
		else
			warn("error teaminfo Item Object nil? | ::UpdateItemList()")
		end
	end
end

--初始化控件信息
def.method().ResetItemList = function(self)
    local team_mode = self._TeamMan:GetTeamMode()
    local is_big_team = self._TeamMan:IsBigTeam()
	self._TeamMemberItemList = {}
	local memberCnt = #self._TeamMemberList
    local frame_team_mem = self._Panel:FindChild("Frame_TeamMem")
    local frame_big_team_mem = self._Panel:FindChild("Frame_BigTeamMem")
    if is_big_team then
        frame_team_mem:SetActive(false)
        frame_big_team_mem:SetActive(true)
        for i = 1,9 do
            local obj = frame_big_team_mem:FindChild("MemberItem"..(i-1))
            local bShow = (memberCnt >= i)
            obj:SetActive(bShow)
            if bShow then
			    local key = self._TeamMemberList[i]._ID
			    self._TeamMemberItemList[key] = obj
		    end
        end
    else
        frame_team_mem:SetActive(true)
        frame_big_team_mem:SetActive(false)
	    for i=1,4 do
		    local obj = frame_team_mem:FindChild('MemberItem'..(i-1) )

		    local bShow = (memberCnt >= i)
		    obj:SetActive(bShow)
		    if bShow then
			    local key = self._TeamMemberList[i]._ID
			    self._TeamMemberItemList[key] = obj
		    end
	    end
    end
end

--新队员的加入
def.method("table").OnNewRoleComeIn = function(self, data)
    local memberCount = #self._TeamMemberList
    if memberCount > 0 then
	    local bindPoint = self._Panel:FindChild('MemberItem'..(memberCount-1))
	    if bindPoint == nil then return end
	    bindPoint:GetComponent(ClassType.DOTweenAnimation):DORestart(false)
	    GameUtil.PlayUISfx(PATH.UIFX_Team_NewRoleComeIn, bindPoint, bindPoint, -1)
	end
end

def.method().Hide = function(self)
	CGame.EventManager:removeHandler('TeamInfoChangeEvent', OnTeamInfoChange)
    if self._MatchTimer ~= 0 then
        _G.RemoveGlobalTimer(self._MatchTimer)
        self._MatchTimer = 0
    end
    self:RemoveInVisionTimer()
	if self._Panel ~= nil then
		self._Panel:SetActive(false)
	end
end

def.method().Destroy = function (self)
	self:Hide()
	instance = nil

	self._Panel = nil
end

CPageTeam.Commit()
return CPageTeam