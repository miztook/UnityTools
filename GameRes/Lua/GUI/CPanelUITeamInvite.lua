local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY

local CPanelUITeamInvite = Lplus.Extend(CPanelBase, "CPanelUITeamInvite")
local def = CPanelUITeamInvite.define

local InvitePageType = {
    Near = 1,
    Friend = 2,
    Guild = 3,
    Apply = 4,
}

def.field('userdata')._List_PlayerList = nil
def.field("userdata")._List_ApplyList = nil
def.field('table')._CurrentList = BlankTable
def.field("table")._ApplicationList = BlankTable
def.field("table")._InviteCounts = nil
def.field("string")._CurrentSelectGroup = ""
def.field("number")._LastSortIndex = 0
def.field("boolean")._LastSortUp = false
def.field("table")._PanelObject = nil
def.field("number")._CurPageType = InvitePageType.Near

local instance = nil
def.static("=>",CPanelUITeamInvite).Instance = function ()
	if not instance then 
		instance = CPanelUITeamInvite()
        instance._PrefabPath = PATH.UI_TeamInvite
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._PanelObject = {}
    self._PanelObject._List_PlayerListObj = self:GetUIObject('List_TeamList')
    self._PanelObject._List_ApplyListObj = self:GetUIObject("List_ApplyList")
    self._PanelObject._Tab_Player = self:GetUIObject("List_Player")
    self._PanelObject._Tab_Apply = self:GetUIObject("List_Apply")
	self._PanelObject._Lab_InviteNone = self:GetUIObject('Lab_None')
    self._PanelObject._Lab_ApplyNone = self:GetUIObject("Lab_ApplyNone")
    self._PanelObject._ToggleGroup_Tags = self:GetUIObject("Rdo_TagGroup")
    self._PanelObject._Btn_RefuseAll = self:GetUIObject("Btn_RefuseAll")
    self._PanelObject._Img_BtnRefuseAllBG = self:GetUIObject("Img_BottomBG")
	self._List_PlayerList = self._PanelObject._List_PlayerListObj:GetComponent(ClassType.GNewListLoop)
    self._List_ApplyList = self._PanelObject._List_ApplyListObj:GetComponent(ClassType.GNewListLoop)
    self._PanelObject._Rdo_Items = {}
    table.insert(self._PanelObject._Rdo_Items, self:GetUIObject("Rdo_Nearby"))
    table.insert(self._PanelObject._Rdo_Items, self:GetUIObject("Rdo_Friend"))
    table.insert(self._PanelObject._Rdo_Items, self:GetUIObject("Rdo_Guild"))
    table.insert(self._PanelObject._Rdo_Items, self:GetUIObject("Rdo_Apply"))
	self._InviteCounts = {
        FriendCount = 0,
        GuildCount = 0,
        ApplyCount = 0
    }
end

def.override("dynamic").OnData = function(self, data)
    if data ~= nil then
        self._CurPageType = tonumber(data) or InvitePageType.Near
    else
        self._CurPageType = InvitePageType.Near
    end
    self:RequestTabDataByScript()
    GUI.SetGroupToggleOn(self._PanelObject._ToggleGroup_Tags, self._CurPageType)
    self:UpdatePanel()
    TeamUtil.RequestTeamDisplayCount()
end

def.method().UpdatePanel = function(self)
    if self._CurPageType == InvitePageType.Apply then
        self._PanelObject._Lab_InviteNone:SetActive(false)
        self._PanelObject._Tab_Player:SetActive(false)

        if self._ApplicationList == nil or #self._ApplicationList == 0 then
            self._PanelObject._List_ApplyListObj:SetActive(false)
            self._PanelObject._Lab_ApplyNone:SetActive(true)
            self._PanelObject._Btn_RefuseAll:SetActive(false)
            self._PanelObject._Img_BtnRefuseAllBG:SetActive(false)
        else
            self._PanelObject._List_ApplyListObj:SetActive(true)
            self._PanelObject._Lab_ApplyNone:SetActive(false)
            self._PanelObject._Btn_RefuseAll:SetActive(true)
            self._PanelObject._Img_BtnRefuseAllBG:SetActive(true)
            self._List_ApplyList:SetItemCount(#self._ApplicationList)
        end
        self._PanelObject._Tab_Apply:SetActive(true)
    else
        self._PanelObject._Lab_ApplyNone:SetActive(false)
        self._PanelObject._Tab_Apply:SetActive(false)
        self._PanelObject._Btn_RefuseAll:SetActive(false)
        self._PanelObject._Img_BtnRefuseAllBG:SetActive(false)

        if self._CurrentList == nil or #self._CurrentList == 0 then
            self._PanelObject._List_PlayerListObj:SetActive(false)
            self._PanelObject._Lab_InviteNone:SetActive(true)
        else
            self._PanelObject._List_PlayerListObj:SetActive(true)
            self._PanelObject._Lab_InviteNone:SetActive(false)
            self._List_PlayerList:SetItemCount(#self._CurrentList)
        end
        self._PanelObject._Tab_Player:SetActive(true)
    end
end

def.method("=>", "number").GetNearbyNicePlayerCount = function(self)
    local count = 0
    local map = clone(game._CurWorld._PlayerMan._ObjMap)
	
	for i,v in pairs(CTeamMan.Instance():GetMemberList()) do
		local entityId = v._ID
		table.remove(map, entityId)
	end

	for i,v in pairs(map) do
		local entity = v
		if not entity:InTeam() and not game._CFriendMan:IsInBlackList(entity._ID) then
    		count = count + 1
		end
	end
    return count
end

def.method().UpdateNearbyList = function(self)
	self._CurrentList = {}
	local map = clone(game._CurWorld._PlayerMan._ObjMap)
	
	for i,v in pairs(CTeamMan.Instance():GetMemberList()) do
		local entityId = v._ID
		table.remove(map, entityId)
	end

	for i,v in pairs(map) do
		local entity = v
		if not entity:InTeam() and not game._CFriendMan:IsInBlackList(entity._ID) then
    		local battleValue = math.ceil(entity._InfoData._FightProperty[ENUM_FIGHTPROPERTY.FIGHTSCORE][1])
			local roleInfo = 
			{
				roleId = entity._ID,					--ID
				name = entity._InfoData._Name,			--名字
				profession = entity._InfoData._Prof,	--职业
				level = entity._InfoData._Level,		--等级
				combatPower = math.ceil(battleValue),	--战力
				gender = entity._InfoData._Gender,		--性别
                isOnline = true,
			}
			table.insert(self._CurrentList, roleInfo)
		end
	end
    map = nil
	self:UpdatePanel()
end

local function SortOffLine(a,b)
    if a.isOnline and b.isOnline then
        return a.combatPower > b.combatPower
    else
        return a.isOnline
    end
end

def.method("table").UpdateInviteList = function(self, dataList)
	self._CurrentList = {}
    if dataList ~= nil then
    	for i, roleInfo in ipairs(dataList) do
    		table.insert(self._CurrentList, roleInfo)
    	end
        if #self._CurrentList > 0 then
            table.sort(self._CurrentList, SortOffLine)
        end
    end

	if self:IsShow() then
		self:UpdatePanel()
	end
end

def.method("table").UpdateApplyList = function(self, dataList)
    self._ApplicationList = {}
    if dataList ~= nil then
    	for i, roleInfo in ipairs(dataList) do
    		table.insert(self._ApplicationList, roleInfo)
    	end
    end

	if self:IsShow() then
		self:UpdatePanel()
	end
end

-- 更新界面各个Tab页签的成员数量显示
def.method("number", "number", "number").UpdateCount = function(self, guildCount, friendCount, applyCount)
    self._InviteCounts.FriendCount = friendCount
    self._InviteCounts.GuildCount = guildCount
    self._InviteCounts.ApplyCount = applyCount
    self:UpdateCountUI()
end

def.method().UpdateCountUI = function(self)
    if self:IsShow() then
        local lab_near_count_D = self:GetUIObject("Lab_Count1_D")
        local lab_near_count_U = self:GetUIObject("Lab_Count1_U")
        local n1 = self:GetNearbyNicePlayerCount()
        GUI.SetText(lab_near_count_D, string.format(StringTable.Get(30314), n1))
        GUI.SetText(lab_near_count_U, string.format(StringTable.Get(30314), n1))

        local lab_friend_count_D = self:GetUIObject("Lab_Count2_D")
        local lab_friend_count_U = self:GetUIObject("Lab_Count2_U")
        local n2 = self._InviteCounts.FriendCount
        GUI.SetText(lab_friend_count_D, string.format(StringTable.Get(30314), n2))
        GUI.SetText(lab_friend_count_U, string.format(StringTable.Get(30314), n2))

        local lab_guild_count_D = self:GetUIObject("Lab_Count3_D")
        local lab_guild_count_U = self:GetUIObject("Lab_Count3_U")
        local n3 = self._InviteCounts.GuildCount
        GUI.SetText(lab_guild_count_D, string.format(StringTable.Get(30314), n3))
        GUI.SetText(lab_guild_count_U, string.format(StringTable.Get(30314), n3))

        local lan_apply_count_D = self:GetUIObject("Lab_Count4_D")
        local lan_apply_count_U = self:GetUIObject("Lab_Count4_U")
        local n4 = self._InviteCounts.ApplyCount
        GUI.SetText(lan_apply_count_D, string.format(StringTable.Get(30314), n4))
        GUI.SetText(lan_apply_count_U, string.format(StringTable.Get(30314), n4))
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	local lua_index = index + 1
	if id == "List_TeamList" then
        local ImgG_ListBG = item:FindChild('ImgG_ListBG')
        local Img_ItemBG = item:FindChild('Img_ItemBG')
        local Img_Head = item:FindChild('Img_Head')

        local Lab_Name = item:FindChild('Lab_Name')
        local Lab_Lv = item:FindChild('Lab_Lv')
        local Lab_Prof = item:FindChild("Lab_Prof")
        local Lab_BattleTips = item:FindChild("Lab_BattleTips")
        local Lab_Battle = item:FindChild('Lab_Battle')
        local Btn_Invite = item:FindChild("Btn_Invite")
        local Lab_Applyed = item:FindChild("Lab_Applyed")
        local Lab_Offline = item:FindChild("Lab_Offline")

	    local roleInfo = self._CurrentList[lua_index]
		local profTemplate = CElementData.GetProfessionTemplate(roleInfo.profession)

		if roleInfo.gender == EnumDef.Gender.Female then
			GUITools.SetHeadIcon(Img_Head, profTemplate.FemaleIconAtlasPath)
		else
			GUITools.SetHeadIcon(Img_Head, profTemplate.MaleIconAtlasPath)
		end
    	
        --职业
        if profTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:", roleInfo.profession)
        else
            GUI.SetText(Lab_Prof, profTemplate.Name)
        end
        
        Lab_Applyed:SetActive(roleInfo.isOnline)
        Btn_Invite:SetActive(roleInfo.isOnline)
	    GUI.SetText(Lab_Name, roleInfo.name)
	    GUI.SetText(Lab_Lv, string.format(StringTable.Get(10641), roleInfo.level))
    	GUI.SetText(Lab_Battle, GUITools.FormatNumber(roleInfo.combatPower))
        local bInvited = CTeamMan.Instance():HasInvited(roleInfo.roleId)
        GUI.SetText(item:FindChild("Btn_Invite/Img_Bg/Lab_Apply"), StringTable.Get(roleInfo.isOnline and (bInvited and 22404 or 22403) or 22412))
        GameUtil.MakeImageGray(ImgG_ListBG, not roleInfo.isOnline)
        GameUtil.MakeImageGray(Img_ItemBG, not roleInfo.isOnline)
        GameUtil.MakeImageGray(Img_Head, not roleInfo.isOnline)

        -- GUI.SetAlpha(ImgG_ListBG, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Img_ItemBG, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Img_Head, roleInfo.isOnline and 255 or 128)
        
        GUI.SetAlpha(Lab_Name, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Lab_Lv, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Lab_Prof, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Lab_BattleTips, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Lab_Battle, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Btn_Invite, roleInfo.isOnline and 255 or 128)
        GUI.SetAlpha(Lab_Applyed, roleInfo.isOnline and 255 or 128)
        Lab_Offline:SetActive(not roleInfo.isOnline)

    elseif id == "List_ApplyList" then
        local Lable_Name = item:FindChild("Lab_Name")
        local Label_Level = item:FindChild("Lab_Lv")
        local Label_Fight = item:FindChild("Lab_Battle")
        local Img_Head =  item:FindChild("Img_Head")
		local Lab_Prof = item:FindChild("Lab_Prof")

        if Lable_Name and Label_Level and Label_Fight and Img_Head then
        	local infoData = self._ApplicationList[lua_index]
        	GUI.SetText(Lable_Name, infoData.name)
        	GUI.SetText(Label_Level, string.format(StringTable.Get(10641), infoData.level))
        	GUI.SetText(Label_Fight, GUITools.FormatNumber(infoData.Competitiveness))
        	
        	local proId = infoData.profession
        	local profTemplate = CElementData.GetProfessionTemplate(proId)
			if Profession2Gender[proId] == EnumDef.Gender.Female then
				GUITools.SetHeadIcon(Img_Head, profTemplate.FemaleIconAtlasPath)
			else
				GUITools.SetHeadIcon(Img_Head, profTemplate.MaleIconAtlasPath)
			end
			--职业
	        if profTemplate == nil then
	            warn("设置职业徽记时 读取模板错误：profession:", infoData.profession)
	        else
                GUI.SetText(Lab_Prof, profTemplate.Name)
	        end
        end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	local lua_index = index + 1
	if id == "List_TeamList" and id_btn == "Btn_Invite" then
		local roleInfo = self._CurrentList[lua_index]
        local bInvited = CTeamMan.Instance():HasInvited(roleInfo.roleId)
        local teamId = CTeamMan.Instance():GetTeamId()
        local function callback( ret )
            if ret then
                TeamUtil.InviteMember(teamId, roleInfo.roleId)
            end
        end

        if bInvited then
            local title, msg, closeType = StringTable.GetMsg(103)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
        else
            TeamUtil.InviteMember(teamId, roleInfo.roleId)
            CTeamMan.Instance():AddInvitedCache(roleInfo.roleId)
            GUI.SetText(item:FindChild("Img_Bg/Lab_Apply"), StringTable.Get(22404))
        end
    elseif id == "List_ApplyList" and id_btn == "Btn_Apply" then
        local teamId = CTeamMan.Instance():GetTeamId()
		TeamUtil.ApproveJoinTeam(teamId, self._ApplicationList[lua_index].roleID)
		self:PopLocalApplicationList(self._ApplicationList[lua_index].roleID)
        self._InviteCounts.ApplyCount = self._InviteCounts.ApplyCount -1
        self:UpdateCountUI()
	elseif id == "List_ApplyList" and id_btn == "Btn_Refuse" then
        local teamId = CTeamMan.Instance():GetTeamId()
		TeamUtil.RefuseJoinTeam(teamId, self._ApplicationList[lua_index].roleID)
		self:PopLocalApplicationList(self._ApplicationList[lua_index].roleID)
        self._InviteCounts.ApplyCount = self._InviteCounts.ApplyCount -1
        self:UpdateCountUI()
	end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.method("number").PopLocalApplicationList = function(self, id)
	if #self._ApplicationList > 0 then
		local index = 1
		local map = {}
		for k,v in pairs(self._ApplicationList) do
			if v.roleID ~= nil and v.roleID ~= id then
				-- warn("v.roleID = ",v.roleID, "addMemeber index = ", index)
				map[index] = v
				index = index + 1
			end
		end
		--self._ApplicationList = {}
		self._ApplicationList = map
		map = {}

		self:UpdatePanel()
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if self._CurrentSelectGroup == id then return end
	
	if id == "Rdo_Nearby" then
        self._CurPageType = InvitePageType.Near
		self:UpdateNearbyList()
	elseif id == "Rdo_Friend" then
    -- warn("OnToggle 好友")
		-- 1 好友 2 公会
        self._CurPageType = InvitePageType.Friend
        -- self:UpdateInviteList({})
		TeamUtil.RequestInviteList(1)
        TeamUtil.RequestTeamDisplayCount()
	elseif id == "Rdo_Guild" then
    -- warn("OnToggle 公会")
		-- 1 好友 2 公会
        self._CurPageType = InvitePageType.Guild
        -- self:UpdateInviteList({})
		TeamUtil.RequestInviteList(2)
        TeamUtil.RequestTeamDisplayCount()
    elseif id == "Rdo_Apply" then
        self._CurPageType = InvitePageType.Apply
        local teamId = CTeamMan.Instance():GetTeamId()
        TeamUtil.RequestApplyInfo(teamId)
        TeamUtil.RequestTeamDisplayCount()
	end

	self._CurrentSelectGroup = id
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.override("string").OnClick = function(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Refresh" then
		self:OnClickRefresh()
	elseif string.find(id, "Lab_Tips") then
        local index = tonumber(string.sub(id, -1))
        self:OnClickSortIndex(index)
    elseif id == "Btn_RefuseAll" then
        local C2STeamOneKeyApplyAckRefuse = require "PB.net".C2STeamOneKeyApplyAckRefuse
        local protocol = C2STeamOneKeyApplyAckRefuse()
        SendProtocol(protocol)
        game._GUIMan:CloseByScript(self)
	end

    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.method().OnClickRefresh = function(self)
	if self._CurPageType == InvitePageType.Near then
		self:UpdateNearbyList()
	elseif self._CurPageType == InvitePageType.Friend then
		-- 1 好友 2 公会
		TeamUtil.RequestInviteList(1)
	elseif self._CurPageType == InvitePageType.Guild then
		-- 1 好友 2 公会
		TeamUtil.RequestInviteList(2)
    elseif self._CurPageType == InvitePageType.Apply then
        local teamId = CTeamMan.Instance():GetTeamId()
        TeamUtil.RequestApplyInfo(teamId)
	end
    
    TeamUtil.RequestTeamDisplayCount()
end

-- 根据当前的pageType请求数据和所有页签个数显示
def.method().RequestTabDataByScript = function(self)
    if self._CurPageType == InvitePageType.Near then
    	self:UpdateNearbyList()
        self:UpdateCountUI()
    elseif self._CurPageType == InvitePageType.Friend then
        TeamUtil.RequestInviteList(1)
        TeamUtil.RequestTeamDisplayCount()
    elseif self._CurPageType == InvitePageType.Guild then
        TeamUtil.RequestInviteList(2)
        TeamUtil.RequestTeamDisplayCount()
    elseif self._CurPageType == InvitePageType.Apply then
        local teamId = CTeamMan.Instance():GetTeamId()
        TeamUtil.RequestApplyInfo(teamId)
        TeamUtil.RequestTeamDisplayCount()
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
    self:SortLogic()
end

def.method().ResetSort = function(self)
    self._LastSortIndex = 0
    self:SortLogic()
end

def.method().SortLogic = function(self)
    if self._LastSortIndex == 3 then
    --等级排序排序
        if self._LastSortUp then
            local function sortFunction(a, b)
                if a.level > b.level then
                    return true
                else
                    return false
                end
            end
            table.sort(self._CurrentList, sortFunction)
        else
            local function sortFunction(a, b)
                if a.level > b.level then
                    return false
                else
                    return true
                end
            end
            table.sort(self._CurrentList, sortFunction)
        end
    elseif self._LastSortIndex == 4 then
    --战斗力排序
        if self._LastSortUp then
            local function sortFunction(a, b)
                if a.combatPower > b.combatPower then
                    return true
                else
                    return false
                end
            end
            table.sort(self._CurrentList, sortFunction)
        else
            local function sortFunction(a, b)
                if a.combatPower > b.combatPower then
                    return false
                else
                    return true
                end
            end
            table.sort(self._CurrentList, sortFunction)
        end
    else
        self:GetUIObject('SortImgGroup3'):SetActive(false)
        self:GetUIObject('SortImgGroup4'):SetActive(false)
        return
    end 
    self:GetUIObject('Img_Up'..self._LastSortIndex):SetActive(self._LastSortUp)
    self:GetUIObject('Img_Down'..self._LastSortIndex):SetActive(not self._LastSortUp)
    self:UpdatePanel()
end

def.override().OnDestroy = function(self)
	self._LastSortIndex = 0
    self._CurPageType = InvitePageType.Near
	self._List_PlayerList = nil
    self._List_ApplyList = nil
	self._CurrentList = nil
    self._ApplicationList = nil
	self._CurrentSelectGroup = ""
end

CPanelUITeamInvite.Commit()
return CPanelUITeamInvite