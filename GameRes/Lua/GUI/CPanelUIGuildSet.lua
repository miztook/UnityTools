--
--公会设置职位
--
--【孟令康】
--
--2017年9月25日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local CPanelUIGuildSet = Lplus.Extend(CPanelBase, "CPanelUIGuildSet")
local def = CPanelUIGuildSet.define

def.field("table")._Member = BlankTable
def.field("table")._Tab = BlankTable
def.field("number")._Member_Type = 0
def.field("table")._DefaultColor = nil
def.field("table")._LightColor = nil

local instance = nil
def.static("=>", CPanelUIGuildSet).Instance = function()
	if not instance then
		instance = CPanelUIGuildSet()
		instance._PrefabPath = PATH.UI_Guild_Set
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self._Tab[1] = self:GetUIObject("Tab_Leader")
	self._Tab[2] = self:GetUIObject("Tab_Vice")
	self._Tab[3] = self:GetUIObject("Tab_Elite")
	self._Tab[4] = self:GetUIObject("Tab_Normal")
    self._DefaultColor = Color.New(158/255,185/255,215/255)
    self._LightColor = Color.New(251/255,244/255,173/255)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Member = data
	self:OnBtnTab(self._Member._RoleType)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Sure" then
		self:OnBtnSure()
	elseif id == "Btn_Cancel" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Tab_Normal" then
		self:OnBtnTab(GuildMemberType.GuildNormalMember)
	elseif id == "Tab_Elite" then
		self:OnBtnTab(GuildMemberType.GuildElite)
	elseif id == "Tab_Vice" then
		self:OnBtnTab(GuildMemberType.GuildViceLeader)
	elseif id == "Tab_Leader" then
		self:OnBtnTab(GuildMemberType.GuildLeader)
	end
end

-- 职位按钮点击
def.method("number").OnBtnTab = function(self, memberType)
	for i = 1, 4 do
		if memberType == i then
			self._Tab[i]:FindChild("Img_D"):SetActive(true)
            GameUtil.SetTextColor(self._Tab[i]:FindChild("Lab"):GetComponent(ClassType.Text), self._LightColor)
		else
			self._Tab[i]:FindChild("Img_D"):SetActive(false)
            GameUtil.SetTextColor(self._Tab[i]:FindChild("Lab"):GetComponent(ClassType.Text), self._DefaultColor)
		end
	end
	self._Member_Type = memberType
end

-- 确定设置职位
def.method().OnBtnSure = function(self)
	if self._Member_Type ~= self._Member._RoleType then
		local guild = game._HostPlayer._Guild
		local guildLevel = CElementData.GetTemplate("GuildLevel", guild._GuildLevel)
		if self._Member_Type == GuildMemberType.GuildViceLeader then
			if guild._ViceNum == guildLevel.ViceLeaderNumber then
				game._GUIMan:ShowTipText(string.format(StringTable.Get(8054), guildLevel.ViceLeaderNumber, StringTable.Get(825)), true)
				return
			end
		end
		if self._Member_Type == GuildMemberType.GuildElite then
			if guild._ViceNum == guildLevel.EliteNumber then
				game._GUIMan:ShowTipText(string.format(StringTable.Get(8054), guildLevel.EliteNumber, StringTable.Get(826)), true)
				return
			end
		end
		local callback = function(value)
			if value then
				local protocol = (require "PB.net".C2SGuildAppoint)()
				protocol.memberType = self._Member_Type
				protocol.roleID = self._Member._RoleID
				PBHelper.Send(protocol)
				if self._Member_Type == GuildMemberType.GuildLeader then
					game._GUIMan:ShowTipText(StringTable.Get(8059), true)
				else
					game._GUIMan:ShowTipText(StringTable.Get(8060), true)
				end
			end
		end
		if self._Member_Type == GuildMemberType.GuildLeader then
			local title, msg, closeType = StringTable.GetMsg(33)
			local message = string.format(msg, self._Member._RoleName)
			MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
		else
			callback(true)
		end
	end
	game._GUIMan:CloseByScript(self)
end

CPanelUIGuildSet.Commit()
return CPanelUIGuildSet