local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local RecordType = require "PB.data".RecordType
local BuildType = require "PB.data".GuildBuildingType
local MemberType = require "PB.data".GuildMemberType

local CPageGuildInfo = Lplus.Class("CPageGuildInfo")
local def = CPageGuildInfo.define

def.field("table")._Parent = nil
def.field("userdata")._FrameRoot = nil

-- 公会事件信息
def.field("table")._Event_Data = BlankTable

def.field("table")._Guild_Icon_Image = BlankTable
def.field("userdata")._Info_Guild_Name = nil
def.field("userdata")._Info_Guild_Level = nil
def.field("userdata")._Info_Guild_ID_Con = nil
def.field("userdata")._Info_Guild_Leader_Con = nil
def.field("userdata")._Info_Guild_Rank_Con = nil
def.field("userdata")._Info_Guild_Activity_Con = nil
def.field("userdata")._Info_Guild_Member_Con = nil

def.field("userdata")._Frame_Guild_Announce = nil
def.field("userdata")._Info_Guild_Announce = nil
def.field("userdata")._Btn_Set_Guild_Announce = nil
def.field("userdata")._Btn_Info_Guild_Name = nil

def.field("userdata")._Frame_Guild_Event = nil
def.field("userdata")._Tab_Guild_Announce = nil
def.field("userdata")._Tab_Guild_Event = nil

def.field("userdata")._Tab_Guild_Event_Tab_U = nil
def.field("userdata")._Tab_Guild_Even_Tab_D = nil
def.field("userdata")._Tab_Guild_Announce_Tab_U = nil
def.field("userdata")._Tab_Guild_Announce_Tab_D = nil


def.field("userdata")._Guild_Event_List = nil

local ParseGuildEventData = function(data)
    local event_data = {}
    local function CheckFunc(item)
        if item.RecordType == RecordType.RecordType_Contribute then
            return item.DonateId ~= nil and item.DonateId > 0
        elseif item.RecordType == RecordType.RecordType_WorldBossKilled then
        	return item.WorldBossId ~= nil and item.WorldBossId > 0
        end
        return true
    end
    for i,v in ipairs(data) do
        local item = {}
        item.RecordType = v.RecordType
        item.OptTime = v.OptTime
        item.OperaterName = v.OperaterName
        item.TargetName = v.TargetName
        item.ItemId = v.ItemId
        item.BuildType = v.BuildType
        item.Level = v.Level
        item.DungeonTID = v.DungeonTID
        item.MemberType = v.MemberType
        item.Contribute = v.Contribute
        item.DonateId = v.DonateId
        item.WorldBossId = v.WorldBossId
        if CheckFunc(item) then
            event_data[#event_data + 1] = item
        end
    end
    return event_data
end

def.static("table", "userdata", "=>", CPageGuildInfo).new = function(parent, frame)
	local obj = CPageGuildInfo()
	obj._Parent = parent
	obj._FrameRoot = frame	
	return obj
end

-- 展示时调用
def.method().Show = function(self)
    game._GuildMan:SendC2SGuildMembersInfo(game._GuildMan:GetHostPlayerGuildID())
	game._GuildMan:SendC2SGuildRecord(0)
	self._FrameRoot:SetActive(true)
	self:InitUIObject()
	self:Update()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
	if #self._Guild_Icon_Image > 0 then return end
	local parent = self._Parent

	local info_Img_Flag = parent:GetUIObject("Info_Img_Flag")
	self._Guild_Icon_Image[1] = info_Img_Flag:FindChild("Info_Img_Flag_BG")
	self._Guild_Icon_Image[2] = info_Img_Flag:FindChild("Info_Img_Flag_Flower_1")
	self._Guild_Icon_Image[3] = info_Img_Flag:FindChild("Info_Img_Flag_Flower_2")
	self._Info_Guild_Name = parent:GetUIObject("Info_Guild_Name")
	self._Info_Guild_Level = parent:GetUIObject("Info_Guild_Level")
	self._Info_Guild_ID_Con = parent:GetUIObject("Info_Guild_ID_Con")
	self._Info_Guild_Leader_Con = parent:GetUIObject("Info_Guild_Leader_Con")
	self._Info_Guild_Rank_Con = parent:GetUIObject("Info_Guild_Rank_Con")
	self._Info_Guild_Activity_Con = parent:GetUIObject("Info_Guild_Activity_Con")
	self._Info_Guild_Member_Con = parent:GetUIObject("Info_Guild_Member_Con")

	self._Frame_Guild_Announce = parent:GetUIObject("Frame_Guild_Announce")
	self._Info_Guild_Announce = parent:GetUIObject("Info_Guild_Announce")
	self._Btn_Set_Guild_Announce = parent:GetUIObject("Btn_Set_Guild_Announce")
    self._Btn_Info_Guild_Name = parent:GetUIObject("Btn_Info_Guild_Name")

	self._Frame_Guild_Event = parent:GetUIObject("Frame_Guild_Event")

	self._Tab_Guild_Announce = parent:GetUIObject("Tab_Guild_Announce")
	self._Tab_Guild_Event = parent:GetUIObject("Tab_Guild_Event")

-----1207版本暂时保留按钮
	self._Tab_Guild_Event_Tab_U = parent:GetUIObject("Img_U1")
	self._Tab_Guild_Even_Tab_D = parent:GetUIObject("Img_D1")
	self._Tab_Guild_Announce_Tab_U = parent:GetUIObject("Img_U0")
	self._Tab_Guild_Announce_Tab_D = parent:GetUIObject("Img_D0")

    self._Guild_Event_List = parent:GetUIObject("Guild_Event_List"):GetComponent(ClassType.GNewLayoutTable)
end

def.method().Update = function(self)
	game._GuildMan:SetGuildUseIcon(self._Guild_Icon_Image)
	local guild = game._HostPlayer._Guild
	GUI.SetText(self._Info_Guild_Name, guild._GuildName)
	GUI.SetText(self._Info_Guild_Level, tostring(guild._GuildLevel))
	GUI.SetText(self._Info_Guild_ID_Con, tostring(guild._GuildID))
	GUI.SetText(self._Info_Guild_Leader_Con, guild._LeaderName)
	if guild._LivenessRank == 0 then
		GUI.SetText(self._Info_Guild_Rank_Con, StringTable.Get(8063))		
	else
		GUI.SetText(self._Info_Guild_Rank_Con, tostring(guild._LivenessRank))
	end
	GUI.SetText(self._Info_Guild_Activity_Con, GUITools.FormatNumber(guild._GuildLiveness))
	local guildTemp = CElementData.GetTemplate("GuildLevel", guild._GuildModuleID)
	GUI.SetText(self._Info_Guild_Member_Con, guild._MemberNum .. "/" .. guildTemp.MemberNumber)
	self._Info_Guild_Announce:GetComponent(ClassType.InputField).text = guild._Announce

	local member = game._GuildMan:GetHostGuildMemberInfo()
	if member ~= nil then
		self._Info_Guild_Announce:GetComponent(ClassType.InputField).enabled = 0 ~= bit.band(member._Permission, PermissionMask.SetAnnounce)
		self._Info_Guild_Announce:FindChild("Placeholder"):SetActive(0 ~= bit.band(member._Permission, PermissionMask.SetAnnounce))
		self._Btn_Set_Guild_Announce:SetActive(0 ~= bit.band(member._Permission, PermissionMask.SetAnnounce))
		self._Btn_Info_Guild_Name:SetActive(0 ~= bit.band(member._Permission, PermissionMask.SetDisplayInfo))
	end
end

def.method().UpdatePageRedPoint = function(self)
end

-- 当点击
def.method("string").OnClick = function(self, id)
	if id == "Tab_Guild_Announce" then
		print("Tab_Guild_Announce")
		self:OnTabGuildAnnounce()
	-- elseif id == "Tab_Guild_Event" then
	-- 	print("Tab_Guild_Event")
	-- 	self:OnTabGuildEvent()
	elseif id == "Btn_Info_Guild_Name" then
		self:OnBtnInfoGuildName()
	elseif id == "Btn_Guild_Back" then
		self:OnBtnGuildBack()
	end
end

-- 当输入框变化
def.method("string", "string").OnValueChanged = function(self, id, str)
	if id == "Info_Guild_Announce" then
		if GameUtil.GetStringLength(str) > GlobalDefinition.MaxGuildAnnounceLength then
			self._Info_Guild_Announce:GetComponent(ClassType.InputField).text = GameUtil.SetStringLength(str, GlobalDefinition.MaxGuildAnnounceLength)
		end
	end
end

-- 当输入框结束操作
def.method("string", "string").OnEndEdit = function(self, id, str)
	if id == "Info_Guild_Announce" then
		local curAnnounce = game._HostPlayer._Guild._Announce
		if str == curAnnounce then
			return
		end
		local Filter = require "Utility.BadWordsFilter".Filter
		local filterStr = Filter.FilterChat(str)
		if filterStr ~= str then
			self._Info_Guild_Announce:GetComponent(ClassType.InputField).text = curAnnounce
			game._GUIMan:ShowTipText(StringTable.Get(8056), true)
			return
		end
		if GameUtil.GetStringLength(str) < GlobalDefinition.MinGuildAnnounceLength then
            game._GUIMan:ShowTipText(string.format(StringTable.Get(860), GlobalDefinition.MinGuildAnnounceLength), true)
        elseif GameUtil.GetStringLength(str) > GlobalDefinition.MaxGuildAnnounceLength then
            game._GUIMan:ShowTipText(string.format(StringTable.Get(861), GlobalDefinition.MaxGuildAnnounceLength), true)
        else
            local protocol = (require "PB.net".C2SGuildSetAnnounce)()
            protocol.announce = str
            PBHelper.Send(protocol)
        end
	end
end

-- 初始化列表
def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "Guild_Event_List" then
    	self:OnInitEventItem(item, index)
    end
end

-- 设置公会事件信息
def.method("userdata", "number").OnInitEventItem = function(self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	local hp = game._HostPlayer
	local guildName = hp._Guild._GuildName
	local labTime = uiTemplate:GetControl(0)
	local labEvent = uiTemplate:GetControl(1)
	local data = self._Event_Data[index + 1]
	local clientTime = GameUtil.GetServerTime() / 1000
    local logoutTime = clientTime - data.OptTime
    if logoutTime == clientTime then
    	logoutTime = StringTable.Get(1008)
    elseif logoutTime > 86400 then
    	logoutTime = math.round(logoutTime / 86400) .. StringTable.Get(1003)
    elseif logoutTime > 3600 then
    	logoutTime = math.round(logoutTime / 3600) .. StringTable.Get(1002)
    elseif logoutTime > 60 then
    	logoutTime = math.round(logoutTime / 60) .. StringTable.Get(1001)
    else
    	logoutTime = "1" .. StringTable.Get(1001)
    end
    logoutTime = string.format(StringTable.Get(1009), logoutTime)
    GUI.SetText(labTime, logoutTime)

    local operatorName = data.OperaterName
    if operatorName == nil then
    	operatorName = ""
    elseif operatorName ~= "" then
		if operatorName == hp._InfoData._Name then
			operatorName = string.format(StringTable.Get(8129),operatorName)
		else
			operatorName = string.format(StringTable.Get(8128),operatorName)
		end
	end
	local targetName = data.TargetName
	if targetName == nil then
		targetName = ""
	elseif targetName ~= "" then
		if targetName == hp._InfoData._Name then
			targetName = string.format(StringTable.Get(8129),targetName)
		else
			targetName = string.format(StringTable.Get(8128),targetName)		
		end
	end
	if data.RecordType == RecordType.RecordType_GuildLevelUp then
		GUI.SetText(labEvent, string.format(StringTable.Get(877), operatorName, data.Level))
	elseif data.RecordType == RecordType.RecordType_BuildLevelUp then
		local build = nil
		if data.BuildType == BuildType.WareHouse then
			build = StringTable.Get(838)
		elseif data.BuildType == BuildType.Smithy then
			build = StringTable.Get(839)				
		elseif data.BuildType == BuildType.PrayPool then
			build = StringTable.Get(840)				
		elseif data.BuildType == BuildType.GuildDungeon then
			build = StringTable.Get(841)
		elseif data.BuildType == BuildType.GuildShop then
			build = StringTable.Get(842)				
		elseif data.BuildType == BuildType.Laboratory then
			build = StringTable.Get(843)
		end
		GUI.SetText(labEvent, string.format(StringTable.Get(878), operatorName, build, data.Level))
	elseif data.RecordType == RecordType.RecordType_Appoint then
		local appoint = ""
		if data.MemberType == MemberType.GuildLeader then
			appoint = StringTable.Get(824)
		elseif data.MemberType == MemberType.GuildViceLeader then
			appoint = StringTable.Get(825)				
		elseif data.MemberType == MemberType.GuildElite then
			appoint = StringTable.Get(826)				
		elseif data.MemberType == MemberType.GuildNormalMember then
			appoint = StringTable.Get(827)		
		elseif data.MemberType == MemberType.GuildApplyMember then
			appoint = StringTable.Get(828)
		end
		GUI.SetText(labEvent, string.format(StringTable.Get(879), targetName, appoint))
	elseif data.RecordType == RecordType.RecordType_MemberAdd then
		local name = targetName
		if name == nil or name == "" then
			name = operatorName
		end
		GUI.SetText(labEvent, string.format(StringTable.Get(880), name, guildName))
	elseif data.RecordType == RecordType.RecordType_MemberExit then
		GUI.SetText(labEvent, string.format(StringTable.Get(881), operatorName))
	elseif data.RecordType == RecordType.RecordType_MemberKick then
		GUI.SetText(labEvent, string.format(StringTable.Get(882), targetName))
	elseif data.RecordType == RecordType.RecordType_Dungeon then
		GUI.SetText(labEvent, string.format(StringTable.Get(883), operatorName, data.DungeonTID))
	elseif data.RecordType == RecordType.RecordType_Contribute then
		local donate = CElementData.GetTemplate("GuildDonate", data.DonateId)
		if donate == nil then
			GUI.SetText(labEvent, "")
			return
		end
		local money = CElementData.GetTemplate("Money", donate.CostType)
		GUI.SetText(labEvent, string.format(StringTable.Get(8065), operatorName, GUITools.FormatNumber(donate.CostNum), money.TextDisplayName))		
	elseif data.RecordType == RecordType.RecordType_BuffOpen then 
		GUI.SetText(labEvent, string.format(StringTable.Get(8132)))
	elseif data.RecordType == RecordType.RecordType_WorldBossKilled then 
		local bossData = game._CWorldBossMan:GetWorldBossByID(data.WorldBossId)
		GUI.SetText(labEvent, string.format(StringTable.Get(8133),bossData._Data.Name))	
	elseif data.RecordType == RecordType.RecordType_GuildActionPutaway then 
		local ItemTemp = CElementData.GetItemTemplate(data.ItemId)
        local name = RichTextTools.GetQualityText(ItemTemp.TextDisplayName, ItemTemp.InitQuality)
		GUI.SetText(labEvent, string.format(StringTable.Get(8134),name))
	end
end

-- 查看公会公告
def.method().OnTabGuildAnnounce = function(self)
	
	
	-----1207版本暂时保留按钮
	self._Tab_Guild_Event_Tab_U:SetActive(false)
	self._Tab_Guild_Even_Tab_D:SetActive(true)
	self._Tab_Guild_Announce_Tab_U:SetActive(true)
	self._Tab_Guild_Announce_Tab_D:SetActive(false)




	self._Frame_Guild_Announce:SetActive(true)
	self._Frame_Guild_Event:SetActive(false)
end

-- 修改公会名字
def.method().OnBtnInfoGuildName = function(self)
	local guild = game._HostPlayer._Guild
	local data = {}
	data._Name = guild._GuildName
	data._Min = GlobalDefinition.MinGuildNameLength
	data._Max = GlobalDefinition.MaxGuildNameLength
	data._Tid = 2
	data._Cost = CSpecialIdMan.Get("GuildRenameDiamondCost")
	local callback = function(name)
		local protocol = (require "PB.net".C2SGuildSetDisplayInfo)()
		protocol.DisplayInfo.AddLimit.battlePower = guild._AddLimit._BattlePower
       	protocol.DisplayInfo.Name = name
        protocol.DisplayInfo.NeedAgree = guild._NeedAgree
        protocol.DisplayInfo.Icon.BaseColorID = guild._GuildIconInfo._BaseColorID
        protocol.DisplayInfo.Icon.FrameID = guild._GuildIconInfo._FrameID
        protocol.DisplayInfo.Icon.ImageID = guild._GuildIconInfo._ImageID
        PBHelper.Send(protocol)
	end
	data._Callback = callback
	game._GUIMan:Open("CPanelUIRename", data)
end

-- 回到公会基地
def.method().OnBtnGuildBack = function(self)
	game._GuildMan:EnterGuildMap()
end

-- 展示公会事件
def.method("table").ShowGuildEvent = function(self, data)
	-- 根据时间排序
	local SortFun = function(a, b)
		return a.OptTime > b.OptTime
	end
	table.sort(data, SortFun)
	self._Event_Data = ParseGuildEventData(data)

    self._Guild_Event_List:SetItemCount(#self._Event_Data)
end

-- 隐藏时调用
def.method().Hide = function(self)
	self._FrameRoot:SetActive(false)
end

-- 摧毁时调用
def.method().Destroy = function(self)
	self._Parent = nil
	self._FrameRoot = nil

	self._Event_Data = nil

	self._Guild_Icon_Image = nil
	self._Info_Guild_Name = nil
	self._Info_Guild_Level = nil
	self._Info_Guild_ID_Con = nil
	self._Info_Guild_Leader_Con = nil
	self._Info_Guild_Rank_Con = nil
	self._Info_Guild_Activity_Con = nil
	self._Info_Guild_Member_Con = nil

	self._Frame_Guild_Announce = nil
	self._Info_Guild_Announce = nil
	self._Frame_Guild_Event = nil
	self._Tab_Guild_Announce = nil
	self._Tab_Guild_Event = nil
end

CPageGuildInfo.Commit()
return CPageGuildInfo