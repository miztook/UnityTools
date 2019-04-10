local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CPageGuildMember = Lplus.Class("CPageGuildMember")
local def = CPageGuildMember.define
local bit = require "bit"

def.field("table")._Parent = nil
def.field("userdata")._FrameRoot = nil
-- 上次选中的Image
def.field("userdata")._Last_Selected = nil
def.field("userdata")._Lab_Guild_Member_Num = nil
def.field("userdata")._Guild_Member_List = nil
def.field("userdata")._Btn_Guild_Quit = nil
def.field("userdata")._Btn_Guild_Apply = nil

def.static("table", "userdata", "=>", CPageGuildMember).new = function(parent, frame)
	local obj = CPageGuildMember()
	obj._Parent = parent
	obj._FrameRoot = frame
	return obj
end

-- 展示时调用
def.method().Show = function(self)
    game._GuildMan:SendC2SGuildMembersInfo(game._GuildMan:GetHostPlayerGuildID())
	self._FrameRoot:SetActive(true)
	self:InitUIObject()
	self:Update()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
	local parent = self._Parent
	self._Lab_Guild_Member_Num = parent:GetUIObject("Lab_Guild_Member_Num")

	self._Guild_Member_List = parent:GetUIObject("Guild_Member_List"):GetComponent(ClassType.GNewList)
    self._Btn_Guild_Quit = parent:GetUIObject("Btn_Guild_Quit")
    self._Btn_Guild_Apply = parent:GetUIObject("Btn_Guild_Apply")
end

def.method().Update = function(self)
	local guild = game._HostPlayer._Guild
	local guildLevel = CElementData.GetTemplate("GuildLevel", guild._GuildModuleID)

	local memberNum = "<color=#5CBE37>" .. guild._MemberNum .. "</color>"

	GUI.SetText(self._Lab_Guild_Member_Num, "[" .. memberNum .. "/" .. guildLevel.MemberNumber .. "]")

	self._Guild_Member_List:SetItemCount(#guild._MemberID)

	local member = game._GuildMan:GetHostGuildMemberInfo()  
    if member ~= nil then                                                                                             
    	self._Btn_Guild_Quit:SetActive(member._RoleType ~= 1)
    	self._Btn_Guild_Apply:SetActive(0 ~= bit.band(member._Permission, PermissionMask.AcceptApply))
    end
end

def.method().UpdatePageRedPoint = function(self)
end

-- 当点击
def.method("string").OnClick = function(self, id)
	if id == "Btn_Guild_Apply" then
		self:OnBtnGuildApply()
	end
end

-- 初始化列表
def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "Guild_Member_List" then
    	local uiTemplate = item:GetComponent(ClassType.UITemplate)	
    	local _Guild = game._HostPlayer._Guild
    	local memberID = _Guild._MemberID[index + 1]
    	local baseContent = ""
    	if memberID == game._HostPlayer._ID then
    		baseContent = "<color=#E7BF30>%s</color>"
    	else
    		baseContent = "<color=white>%s</color>"
    	end
    	local member = _Guild._MemberList[memberID]
    	game:SetEntityCustomImg(uiTemplate:GetControl(3), member._RoleID, member._CustomImgSet, Profession2Gender[member._ProfessionID], member._ProfessionID)
    	GUI.SetText(uiTemplate:GetControl(4), string.format(baseContent, member._RoleName))
        GUI.SetText(uiTemplate:GetControl(5), StringTable.Get(10300 + member._ProfessionID - 1))
    	GUI.SetText(uiTemplate:GetControl(6), member:GetMemberTypeName())
    	GUI.SetText(uiTemplate:GetControl(8), string.format(baseContent, tostring(member._RoleLevel)))
    	GUI.SetText(uiTemplate:GetControl(10), string.format(baseContent, tostring(member._BattlePower)))
    	GUI.SetText(uiTemplate:GetControl(12), string.format(baseContent, tostring(member._Liveness)))
    	local clientTime = GameUtil.GetServerTime() / 1000
    	local logoutTime = clientTime - member._LogoutTime
    	if logoutTime == clientTime then
    		
    	elseif logoutTime > 86400 then
    		logoutTime = math.round(logoutTime / 86400) .. StringTable.Get(1003) .. StringTable.Get(1006)
    	elseif logoutTime > 3600 then
    		logoutTime = math.round(logoutTime / 3600) .. StringTable.Get(1002) .. StringTable.Get(1006)
    	elseif logoutTime > 60 then
    		logoutTime = math.round(logoutTime / 60) .. StringTable.Get(1001) .. StringTable.Get(1006)
    	else
    		logoutTime = "1" .. StringTable.Get(1001) .. StringTable.Get(1006)
    	end
    	if logoutTime == clientTime then
    		uiTemplate:GetControl(13):SetActive(true)
    		uiTemplate:GetControl(15):SetActive(false)
    	else
    		uiTemplate:GetControl(13):SetActive(false)
    		uiTemplate:GetControl(15):SetActive(true)
    		GUI.SetText(uiTemplate:GetControl(16), logoutTime)
    	end
        uiTemplate:GetControl(17):SetActive(false)
    end
end

-- 选中列表
def.method("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if id == "Guild_Member_List" then
		if not IsNil(self._Last_Selected) then
			self._Last_Selected:SetActive(false)
		end
		local _Guild = game._HostPlayer._Guild
		local member = _Guild._MemberList[_Guild._MemberID[index + 1]]
		if member._RoleID ~= game._HostPlayer._ID then
			local uiTemplate = item:GetComponent(ClassType.UITemplate)
			uiTemplate:GetControl(17):SetActive(true)
			self._Last_Selected = uiTemplate:GetControl(17)

			local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
            game:CheckOtherPlayerInfo(member._RoleID, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Guild)
			-- local CGuildMember = require "Guild.CGuildMember"
            --local menuList = CGuildMember.GetMenuList(member)
            --MenuList.Show(menuList, uiTemplate:GetControl(6), EnumDef.AlignType.Bottom)
		end
	end
end

-- 申请列表
def.method().OnBtnGuildApply = function(self)
	local protocol = (require "PB.net".C2SGuildApplyList)()
	PBHelper.Send(protocol)
end

-- 隐藏时调用
def.method().Hide = function(self)
	self._FrameRoot:SetActive(false)
	-- self._Img_D:SetActive(false)
end

-- 摧毁时调用
def.method().Destroy = function(self)
    self._Parent = nil
    self._FrameRoot = nil
    self._Last_Selected = nil
    self._Lab_Guild_Member_Num = nil
    self._Guild_Member_List = nil
    self._Btn_Guild_Quit = nil
    self._Btn_Guild_Apply = nil
end

CPageGuildMember.Commit()
return CPageGuildMember