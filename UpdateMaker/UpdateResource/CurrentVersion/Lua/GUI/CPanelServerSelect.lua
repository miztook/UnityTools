local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local UserData = require "Data.UserData".Instance()
local CPanelLoginIns = require "GUI.CPanelLogin".Instance()
local CElementData = require "Data.CElementData"
local CLoginMan = require "Main.CLoginMan"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelServerSelect = Lplus.Extend(CPanelBase, "CPanelServerSelect")
local def = CPanelServerSelect.define

def.field("userdata")._Frame_ServerList = nil
def.field("userdata")._Frame_ServerListRight = nil
def.field("userdata")._Lab_WaitTips = nil
def.field("userdata")._View_Role = nil
def.field("userdata")._View_Server = nil
def.field("userdata")._List_Role = nil
def.field("userdata")._List_Server = nil
def.field("userdata")._List_Menu = nil
def.field("userdata")._Frame_QuickEnter = nil
def.field("userdata")._List_QuickEnter = nil
-- 数据
def.field("table")._ServerList = BlankTable
def.field("table")._QuickEnterRoleInfos = BlankTable   -- 快速进入的角色信息
def.field("table")._AccountRoleList = BlankTable
-- 缓存
def.field("string")._Account = ""
def.field("string")._Password = ""
def.field("number")._QuickEnterIndex = 0 -- 快速进入中已选中角色的列表索引
def.field("table")._ServerState2UIInfo = BlankTable
def.field("table")._MenuDataList = BlankTable
def.field("table")._RecommendedList = BlankTable
def.field("number")._SelectedMenuType = 0
def.field("number")._OrderZoneId = 0
def.field("table")._ZoneRoleIndexMap = BlankTable

local QUICK_ENTER_MAX_NUM = 3 -- 快速进入角色数量上限
-- 左菜单类型
local EMenuType =
{
	AccountRole = 1,	-- 已有角色
	Recommended = 2,	-- 推荐服务器
	All = 3,			-- 所有服务器
}

local instance = nil
def.static("=>",CPanelServerSelect).Instance = function ()
	if not instance then
        instance = CPanelServerSelect()
        instance._PrefabPath = PATH.Panel_ServerSelect
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end

	self._Frame_ServerList = self:GetUIObject("Frame_ServerList")
	self._Frame_ServerListRight = self:GetUIObject("Frame_ServerListRight")
	self._Lab_WaitTips = self:GetUIObject("Lab_WaitTips")
	self._View_Role = self:GetUIObject("View_Role")
	self._View_Server = self:GetUIObject("View_Server")
	local newList = ClassType.GNewList
	self._List_Role = self:GetUIObject("List_Role"):GetComponent(newList)
	self._List_Server = self:GetUIObject("List_Server"):GetComponent(newList)
	self._List_Menu = self:GetUIObject("List_Menu"):GetComponent(newList)
	self._Frame_QuickEnter = self:GetUIObject("Frame_QuickEnter")
	self._List_QuickEnter = self:GetUIObject("List_QuickEnter"):GetComponent(newList)
	self:EnableWaitTips(false)

	self._ServerState2UIInfo =
	{
		[EnumDef.ServerState.Good] 		= { Index = 0, Str = StringTable.Get(33200) },
		[EnumDef.ServerState.Normal] 	= { Index = 1, Str = StringTable.Get(33201) },
		[EnumDef.ServerState.Busy] 		= { Index = 2, Str = StringTable.Get(33202) },
		[EnumDef.ServerState.Unuse] 	= { Index = 3, Str = StringTable.Get(33203) },
		[EnumDef.ServerState.Unrun]		= { Index = 3, Str = StringTable.Get(33203) },
	}
end

-- @param data 结构
--        account	账号
--        pass		密码
def.override("dynamic").OnData = function(self, data)
	self._Account = ""
	self._Password = ""
	if data ~= nil then
		self._Account = data.account
		self._Password = data.password
	end

	self._ServerList = CLoginMan.GetServerListCache()
	-- 设置已有角色列表
	self._AccountRoleList = {}
	if not IsNilOrEmptyString(self._Account) then
		-- 非空账号才去取角色列表数据，否则默认列表为空
		local roleList = CLoginMan.GetAccountRoleList(self._Account)
		if roleList ~= nil then
			-- 检查已有角色里是否在现有的服务器列表里
			for _, info in ipairs(roleList) do
				local index = self:GetServerIndexByZoneId(info.zoneId)
				if self._ServerList[index] ~= nil then
					table.insert(self._AccountRoleList, info)
				end
			end
		end
	end
	self:InitData()
	self:SetMenu()
	-- self:SetQuickEnterInfo(self._Account)
end

def.method().InitData = function (self)
	self._RecommendedList = {}
	self._ZoneRoleIndexMap = {}
	self._OrderZoneId = 0
	--刷新Login服务器列表
	if CPanelLoginIns:IsShow() then
		CPanelLoginIns:RefreshServerList(self._ServerList)
	end
	-- 设置推荐服务器列表
	do
		self._OrderZoneId = GameUtil.GetOrderZoneId() -- 必须在 CLoginMan.GetAccountRoleList 后使用
		-- 预约
		local recommended_list = {}
		if #self._AccountRoleList > 0 then
			local levelMap = {}
			for index, info in ipairs(self._AccountRoleList) do
				local level = levelMap[info.zoneId]
				if level == nil or info.level > level then
					levelMap[info.zoneId] = info.level
					self._ZoneRoleIndexMap[info.zoneId] = index
				end
			end
		end
		-- 推荐
		-- 先找到所有服务器推荐的
		for _, info in ipairs(self._ServerList) do
			if info.recommend and info.zoneId ~= self._OrderZoneId then
				table.insert(recommended_list, info)
			end
		end
		-- 再从所有服务器列表找前面4个New的
		local num = 4
		local count = 0
		for _, info in ipairs(self._ServerList) do
			if not info.recommend and info.newFlag and info.zoneId ~= self._OrderZoneId then
				table.insert(recommended_list, info)
				count = count + 1
			end
			if count == num then
				break
			end
		end
		self._RecommendedList = recommended_list
	end
end

def.method("boolean").EnableWaitTips = function (self, enable)
	self._Frame_ServerList:SetActive(not enable)
	self._Frame_ServerListRight:SetActive(not enable)
	GUITools.SetUIActive(self._Lab_WaitTips, enable)
end

def.method().SetMenu = function (self)
	local list = {}
	if #self._AccountRoleList > 0 then
		local data = { MenuType = EMenuType.AccountRole, MenuName = StringTable.Get(33205) }
		table.insert(list, data)
	end
	local data = { MenuType = EMenuType.Recommended, MenuName = StringTable.Get(33206) }
	table.insert(list, data)
	data = { MenuType = EMenuType.All, MenuName = StringTable.Get(33207) }
	table.insert(list, data)
	self._MenuDataList = list
	self._SelectedMenuType = 0
	self._List_Menu:SetItemCount(#list)
	self._List_Menu:SetSelection(0) -- 默认选中第一个
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_Menu") then
		-- 左菜单
		self:OnInitMenu(item, index)
	elseif string.find(id, "List_Role") then
		self:OnInitRoleList(item, index)
	elseif string.find(id, "List_Server") then
		if self._SelectedMenuType == EMenuType.Recommended then
			self:OnInitRecommendList(item, index)
		elseif self._SelectedMenuType == EMenuType.All then
			self:OnInitAllList(item, index)
		end
	elseif string.find(id, "List_QuickEnter") then
		local roleInfo = self._QuickEnterRoleInfos[index+1]
		if roleInfo == nil then return end

		local headIcon = roleInfo.HeadIcon
		local img_headIcon = GUITools.GetChild(item, 4)
		TeraFuncs.SetEntityCustomImg(img_headIcon, roleInfo.RoleId, headIcon.CustomImgSet, headIcon.Gender, headIcon.Prof)
		local lab_roleLevel = GUITools.GetChild(item, 2)
		GUI.SetText(lab_roleLevel, "<color=#ecb554>Lv.</color> " .. roleInfo.Level)
		if index + 1 == self._QuickEnterIndex then
			self._List_QuickEnter:SetSelection(index)
		end
	end 
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if string.find(id, "List_Menu") then
		local data = self._MenuDataList[index+1]
		if data == nil or data.MenuType == self._SelectedMenuType then return end
		self._List_Menu:SetSelection(index)
		self:SelectMenu(data.MenuType)
	elseif string.find(id, "List_Role") then
		local roleInfo = self._AccountRoleList[index+1]
		if roleInfo == nil then return end

		CPanelLoginIns:UpdateServerInfo(roleInfo.zoneId)
		game._GUIMan:CloseByScript(self)
	elseif string.find(id, "List_Server") then
		local selectZoneId = 0
		if self._SelectedMenuType == EMenuType.Recommended then
			if self._OrderZoneId ~= 0 then
				if index == 0 then
					selectZoneId = self._OrderZoneId
				else
					local serverInfo = self._RecommendedList[index]
					if serverInfo ~= nil then
						selectZoneId = serverInfo.zoneId
					end
				end
			else
				local serverInfo = self._RecommendedList[index+1]
				if serverInfo ~= nil then
					selectZoneId = serverInfo.zoneId
				end
			end
		elseif self._SelectedMenuType == EMenuType.All then
			local serverInfo = self._ServerList[index+1]
			if serverInfo ~= nil then
				selectZoneId = serverInfo.zoneId
			end
		end
		if selectZoneId ~= 0 then
			CPanelLoginIns:UpdateServerInfo(selectZoneId)
			game._GUIMan:CloseByScript(self)
		end
	elseif string.find(id, "List_QuickEnter") then
		self._QuickEnterIndex = index + 1
		self._List_QuickEnter:SetSelection(index)
	end
end

def.override("string").OnClick = function(self, id)
	if _G.ForbidTimerId ~= 0 then				--不允许输入
		return
	end

	if id == "Btn_Close" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_QuickEnter" then
		game:AddForbidTimer(self._ClickInterval)
		
		if game._GUIMan:IsCircleShow() then return end
		
		game._GUIMan:CloseCircle()
		game:CloseConnection()
		self:OnBtnQuickEnter()
	end
end

-- 初始化左菜单
def.method("userdata", "number").OnInitMenu = function (self, item, index)
	-- 菜单名字
	local data = self._MenuDataList[index+1]
	if data == nil then return end

	local lab_name_u = GUITools.GetChild(item, 2)
	if not IsNil(lab_name_u) then
		GUI.SetText(lab_name_u, data.MenuName)
	end
	local lab_name_d = GUITools.GetChild(item, 3)
	if not IsNil(lab_name_d) then
		GUI.SetText(lab_name_d, data.MenuName)
	end
	if index == 0 then
		-- 默认打开菜单的第一项
		self:SelectMenu(data.MenuType)
	end
end

def.method("userdata", "number").OnInitRoleList = function (self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local roleInfo = self._AccountRoleList[index+1]
	if roleInfo == nil then return end

	local serverIndex = self:GetServerIndexByZoneId(roleInfo.zoneId)
	local serverInfo = self._ServerList[serverIndex]
	if serverInfo == nil then return end

	-- 服务器名字
	local lab_server_name = uiTemplate:GetControl(2)
	GUI.SetText(lab_server_name, serverInfo.name)
	-- 服务器状态
	local uiInfo = self._ServerState2UIInfo[serverInfo.state]
	if uiInfo ~= nil then
		local img_sign = uiTemplate:GetControl(1)
		GUITools.SetGroupImg(img_sign, uiInfo.Index)
		local lab_server_state = uiTemplate:GetControl(8)
		GUI.SetText(lab_server_state, uiInfo.Str)
	end
	-- 角色名称
	local lab_role_name = uiTemplate:GetControl(9)
	GUI.SetText(lab_role_name, roleInfo.name)
	-- 角色等级
	local lab_role_level = uiTemplate:GetControl(5)
	GUI.SetText(lab_role_level, tostring(roleInfo.level))
	-- 角色职业
	local professionTemplate = CElementData.GetProfessionTemplate(roleInfo.profession)
	if professionTemplate ~= nil then
		local img_role_prof = uiTemplate:GetControl(10)
		GUITools.SetProfSymbolIcon(img_role_prof, professionTemplate.SymbolAtlasPath)
	end
	-- 角色头像
	local gender = Profession2Gender[roleInfo.profession]
	local img_head_icon = uiTemplate:GetControl(3)
	TeraFuncs.SetEntityCustomImg(img_head_icon, roleInfo.roleId, roleInfo.customSet, gender, roleInfo.profession)
end

def.method("userdata", "number").OnInitRecommendList = function (self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local serverInfo = nil
	local isOrderServer = false
	if self._OrderZoneId ~= 0 then
		-- 有预约服务器
		if index == 0 then
			local serverIndex = self:GetServerIndexByZoneId(self._OrderZoneId)
			serverInfo = self._ServerList[serverIndex]
			isOrderServer = true
		else
			serverInfo = self._RecommendedList[index]
		end
	else
		serverInfo = self._RecommendedList[index+1]
	end
	if serverInfo == nil then return end
	-- 服务器名字
	local lab_name = uiTemplate:GetControl(2)
	GUI.SetText(lab_name, serverInfo.name)
	-- 服务器状态
	local uiInfo = self._ServerState2UIInfo[serverInfo.state]
	if uiInfo ~= nil then
		local img_sign = uiTemplate:GetControl(1)
		GUITools.SetGroupImg(img_sign, uiInfo.Index)
		local lab_server_state = uiTemplate:GetControl(4)
		GUI.SetText(lab_server_state, uiInfo.Str)
	end
	-- 服务器角标
	local flagStr = ""
	local flagIndex = 0
	if isOrderServer then
		flagStr = StringTable.Get(33208)
		flagIndex = 1
	elseif serverInfo.recommend then
		flagStr = StringTable.Get(33210)
		flagIndex = 0
	elseif serverInfo.newFlag then
		flagStr = StringTable.Get(33209)
		flagIndex = 0
	end
	local img_flag = uiTemplate:GetControl(5)
	GUITools.SetUIActive(img_flag, flagStr ~= "")
	if flagStr ~= "" then
		GUITools.SetGroupImg(img_flag, flagIndex)
		local lab_flag = uiTemplate:GetControl(6)
		GUI.SetText(lab_flag, flagStr)
	end
	-- 角色信息
	local roleInfo = nil
	local roleIndex = self._ZoneRoleIndexMap[serverInfo.zoneId]
	if roleIndex ~= nil then
		roleInfo = self._AccountRoleList[roleIndex]
	end
	local frame_role = uiTemplate:GetControl(3)
	GUITools.SetUIActive(frame_role, roleInfo ~= nil)
	if roleInfo ~= nil then
		-- 角色等级
		local lab_role_level = uiTemplate:GetControl(10)
		GUI.SetText(lab_role_level, tostring(roleInfo.level))
		-- 角色职业
		local professionTemplate = CElementData.GetProfessionTemplate(roleInfo.profession)
		if professionTemplate ~= nil then
			local img_role_prof = uiTemplate:GetControl(8)
			GUITools.SetProfSymbolIcon(img_role_prof, professionTemplate.SymbolAtlasPath)
		end
		-- 角色头像
		local gender = Profession2Gender[roleInfo.profession]
		local img_head_icon = uiTemplate:GetControl(11)
		TeraFuncs.SetEntityCustomImg(img_head_icon, roleInfo.roleId, roleInfo.customSet, gender, roleInfo.profession)
	end
end

-- 初始化全部服务器列表
def.method("userdata", "number").OnInitAllList = function (self, item, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local serverInfo = self._ServerList[index + 1]
	if serverInfo == nil then return end
	-- 服务器名字
	local lab_name = uiTemplate:GetControl(2)
	GUI.SetText(lab_name, serverInfo.name)
	-- 服务器状态
	local uiInfo = self._ServerState2UIInfo[serverInfo.state]
	if uiInfo ~= nil then
		local img_sign = uiTemplate:GetControl(1)
		GUITools.SetGroupImg(img_sign, uiInfo.Index)
		local lab_server_state = uiTemplate:GetControl(4)
		GUI.SetText(lab_server_state, uiInfo.Str)
	end
	-- 服务器角标
	local flagStr = ""
	local flagIndex = 0
	if serverInfo.zoneId == self._OrderZoneId then
		flagStr = StringTable.Get(33208)
		flagIndex = 1
	elseif serverInfo.recommend then
		flagStr = StringTable.Get(33210)
		flagIndex = 0
	elseif serverInfo.newFlag then
		flagStr = StringTable.Get(33209)
		flagIndex = 0
	end
	local img_flag = uiTemplate:GetControl(5)
	GUITools.SetUIActive(img_flag, flagStr ~= "")
	if flagStr ~= "" then
		GUITools.SetGroupImg(img_flag, flagIndex)
		local lab_flag = uiTemplate:GetControl(6)
		GUI.SetText(lab_flag, flagStr)
	end
	-- 角色信息
	local roleIndex = self._ZoneRoleIndexMap[serverInfo.zoneId]
	local roleInfo = nil
	if roleIndex ~= nil then
		roleInfo = self._AccountRoleList[roleIndex]
	end
	local frame_role = uiTemplate:GetControl(3)
	GUITools.SetUIActive(frame_role, roleInfo ~= nil)
	if roleInfo ~= nil then
		-- 角色等级
		local lab_role_level = uiTemplate:GetControl(10)
		GUI.SetText(lab_role_level, tostring(roleInfo.level))
		-- 角色职业
		local professionTemplate = CElementData.GetProfessionTemplate(roleInfo.profession)
		if professionTemplate ~= nil then
			local img_role_prof = uiTemplate:GetControl(8)
			GUITools.SetProfSymbolIcon(img_role_prof, professionTemplate.SymbolAtlasPath)
		end
		-- 角色头像
		local gender = Profession2Gender[roleInfo.profession]
		local img_head_icon = uiTemplate:GetControl(11)
		TeraFuncs.SetEntityCustomImg(img_head_icon, roleInfo.roleId, roleInfo.customSet, gender, roleInfo.profession)
	end
end

def.method("number").SelectMenu = function (self, menuType)
	self._SelectedMenuType = menuType
	self._View_Server:SetActive(menuType ~= EMenuType.AccountRole)
	self._View_Role:SetActive(menuType == EMenuType.AccountRole)

	if menuType == EMenuType.AccountRole then
		self._List_Role:SetItemCount(#self._AccountRoleList)
	elseif menuType == EMenuType.Recommended then
		local num = #self._RecommendedList
		if self._OrderZoneId ~= 0 then
			num = num + 1
		end
		self._List_Server:SetItemCount(num)
	elseif menuType == EMenuType.All then
		self._List_Server:SetItemCount(#self._ServerList)
	end
end

--[[
-- 设置快速进入信息
def.method("string").SetQuickEnterInfo = function (self, account)
	self._QuickEnterIndex = 1 -- 默认选中第一个
	self._QuickEnterRoleInfos = {}
	local roleInfos = UserData:GetCfg(EnumDef.LocalFields.QuickEnterGameRoleInfo, account)
	if type(roleInfos) == "table" and #roleInfos > 0 then
		for _, roleInfo in ipairs(roleInfos) do
			local serverIndex = self:GetServerIndexByZoneId(roleInfo.ZoneId)
			if serverIndex > 0 then
				table.insert(self._QuickEnterRoleInfos, roleInfo)
			end
		end
	end
	if #self._QuickEnterRoleInfos > 0 then
		GUITools.SetUIActive(self._Frame_QuickEnter, true)
		self._List_QuickEnter:SetItemCount(#self._QuickEnterRoleInfos)
	else
		GUITools.SetUIActive(self._Frame_QuickEnter, false)
	end
end
--]]

-- 点击快速进入
def.method().OnBtnQuickEnter = function (self)
	local roleInfo = self._QuickEnterRoleInfos[self._QuickEnterIndex]
	if roleInfo ~= nil then
		local serverIndex = self:GetServerIndexByZoneId(roleInfo.ZoneId)
		local serverInfo = self._ServerList[serverIndex]
		if serverInfo ~= nil then
			CLoginMan.Instance():SetQuickEnterRoleId(roleInfo.RoleId)
			CLoginMan.Instance():ConnectToServer(serverInfo.ip, serverInfo.port, serverInfo.name, self._Account, self._Password)
		end
	end
end

-- 通过服务器ID，获取服务器索引
def.method("number", "=>", "number").GetServerIndexByZoneId = function (self, zoneId)
	if zoneId ~= 0 then
		for index, serverInfo in ipairs(self._ServerList) do
			if serverInfo.zoneId == zoneId then
				return index
			end
		end
	end
	return 0
end

def.override().OnDestroy = function(self)
	self._ServerList = {}
	self._QuickEnterRoleInfos = {}
	self._AccountRoleList = {}
	self._ServerState2UIInfo = {}

	self._Frame_ServerList = nil
	self._Frame_ServerListRight = nil
	self._Lab_WaitTips = nil
	self._View_Role = nil
	self._View_Server = nil
	self._List_Role = nil
	self._List_Server = nil
	self._List_Menu = nil
	self._Frame_QuickEnter = nil
	self._List_QuickEnter = nil
end

CPanelServerSelect.Commit()
return CPanelServerSelect