--
-- 月光庭院互助
--
--【孟令康】
--
-- 2018年1月18日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUIGuildPrayHelp = Lplus.Extend(CPanelBase, "CPanelUIGuildPrayHelp")
local def = CPanelUIGuildPrayHelp.define

def.field("table")._Data = nil

def.field("userdata")._List_Type = nil
def.field("userdata")._List_MenuType = nil
def.field("userdata")._Lab_None = nil


def.field("userdata")._Lab_Rest = nil
def.field("userdata")._Lab_Num = nil

local instance = nil
def.static("=>", CPanelUIGuildPrayHelp).Instance = function()
	if not instance then
		instance = CPanelUIGuildPrayHelp()
		instance._PrefabPath = PATH.UI_Guild_PrayHelp
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitUIObject()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	local memberList = game._HostPlayer._Guild._MemberList
	self._Data = {}
	for i, v in pairs(memberList) do
		if v._RoleID ~= game._HostPlayer._ID then
			local flag = true
			for j, w in ipairs(data) do
				if v._RoleID == w.MemberInfo.roleID then
					self._Data[#self._Data + 1] = {}
					self._Data[#self._Data]._Member = v
					self._Data[#self._Data]._CanHelp = true
					flag = false
				end
			end
			if flag then
				self._Data[#self._Data + 1] = {}
				self._Data[#self._Data]._Member = v
				self._Data[#self._Data]._CanHelp = false
			end
		end
	end
    local sort_func = function(item1, item2)
        if item1._CanHelp ~= item2._CanHelp then
            return item1._CanHelp
        else
            return false
        end
    end
    table.sort(self._Data, sort_func)

	if #self._Data == 0 then
		self._List_Type:SetActive(false)
		self._Lab_None:SetActive(true)
	else
		self._List_Type:SetActive(true)
		self._List_MenuType:SetItemCount(#self._Data)
		self._Lab_None:SetActive(false)
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_MenuType" then	
		local member = self._Data[index]._Member
		game:SetEntityCustomImg(uiTemplate:GetControl(3), member._RoleID, member._CustomImgSet, Profession2Gender[member._ProfessionID], member._ProfessionID)
		GUI.SetText(uiTemplate:GetControl(4), member._RoleName)
		GUITools.SetGroupImg(uiTemplate:GetControl(5), member._ProfessionID - 1)
		GUI.SetText(uiTemplate:GetControl(6), member:GetMemberTypeName())
		GUI.SetText(uiTemplate:GetControl(7), string.format(StringTable.Get(10714), member._RoleLevel))
		if self._Data[index]._CanHelp then
			GUI.SetText(uiTemplate:GetControl(8), StringTable.Get(8036))
		else
			GUI.SetText(uiTemplate:GetControl(8), StringTable.Get(8037))
		end
	end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	index = index + 1
	if id == "List_MenuType" then
		local roleId = self._Data[index]._Member._RoleID
		game._GuildMan:SendC2SGuildPrayViewPool(roleId)
	end
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._List_Type = self:GetUIObject("List_Type")
	self._List_MenuType = self:GetUIObject("List_MenuType"):GetComponent(ClassType.GNewListLoop)
	self._Lab_None = self:GetUIObject("Lab_None")
	self._Lab_Rest =self:GetUIObject("_Lab_Rest")
	self._Lab_Num = self:GetUIObject("Lab_Num")



	local helpNum = "<color=#D78236>" .. game._HostPlayer._Guild:GetHelpNum() .. "</color>"
	local strHelpNum = helpNum .. "/" .. game._HostPlayer._Guild._MaxHelpNum
	
	GUI.SetText(self._Lab_Rest, helpNum)
	GUI.SetText(self._Lab_Num, strHelpNum)
end

CPanelUIGuildPrayHelp.Commit()
return CPanelUIGuildPrayHelp