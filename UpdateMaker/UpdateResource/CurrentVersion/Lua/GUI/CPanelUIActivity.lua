local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"

local CPanelUIActivity = Lplus.Extend(CPanelBase, "CPanelUIActivity")
local def = CPanelUIActivity.define

local instance = nil
def.final("=>", CPanelUIActivity).Instance = function()
	if instance == nil then
		instance = CPanelUIActivity()
		instance._PrefabPath = PATH.Panel_Activity
        instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.field("userdata")._TitleRoot 		= nil 			-- 标题栏
def.field("userdata")._MenuBtnRoot 		= nil			-- 菜单按钮节点
def.field("userdata")._PageRoot 		= nil			-- Page节点

def.field("table")._Page 				= BlankTable	-- Page节点

def.field("string")._CurrentMenuName 	= ""			-- 当前页面
def.field("string")._DefaultMenuName 	= ""			-- 默认页面的按钮

def.override().OnCreate = function(self)
	self._TitleRoot 		= self:GetUIObject("TitleRoot")
	self._MenuBtnRoot 		= self:GetUIObject("MenuBtnRoot")
	self._PageRoot 			= self:GetUIObject("PageRoot")

	self:UpdateData()

	-- 设置多语言文本显示
	-- 活动
	local title = self._TitleRoot:FindChild("title")
	GUI.SetText(title, StringTable.Get(549))

	-- 红点更新
	self:UpdateBtnInfo()
end

def.override("dynamic").OnData = function(self, data)
	CPanelBase.OnData(self,data)
	if data ~= nil then
		self:ChangeShowPage(data)
		local index = string.sub(data, string.len("MenuBtn")+1,-1)	
		GUI.SetGroupToggleOn(self._MenuBtnRoot, index + 1)
	end
end

def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == 'Btn_Exit' then
		game._GUIMan:CloseByScript(self)
	else
		local currentPage = self._Page[self._CurrentMenuName]
		if currentPage then
			local scriptObj = currentPage.ScriptObj
			if scriptObj then
				scriptObj:OnClick(id)
			end
		end
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)	
	local pageInfo = self._Page[id]
	if pageInfo then
		self:ChangeShowPage(id)
	end
end

def.method().UpdateData = function(self)
	local pageConf = PanelPageConfig.Activity

	for k, v in pairs(pageConf) do
		local pageInfo = {}
		pageInfo.Page = v.Page
		pageInfo.Script = v.Script
		-- 菜单按钮处理
		local menuBtnName = v.MenuBtn
		pageInfo.MenuBtnName = menuBtnName
		local menuBtnGO = self._MenuBtnRoot:FindChild(menuBtnName)
		pageInfo.MenuBtnGO = menuBtnGO
		pageInfo.IsShow = v.IsShow
		pageInfo.IsRefrash = v.IsRefrash
		pageInfo.FunTid = v.FunTid
		pageInfo.HelpUrlType = v.HelpUrlType
		-- 红点
		if v.RedPoint then
			pageInfo.RedPoint = menuBtnGO:FindChild(v.RedPoint)
		end
		-- 设置菜单按钮多语言
		local MenuText = v.MenuText
		if MenuText and #MenuText > 0 then
			for k, v in ipairs(MenuText) do
				GUI.SetText(menuBtnGO:FindChild(v.key), StringTable.Get(v.gameTextIndex))
			end
		end
		pageInfo.Page = self._PageRoot:FindChild(v.Page)
		pageInfo.Page:SetActive(false)
		self._Page[menuBtnName] = pageInfo
	end
end

def.method().UpdateDefaultMenuBtnName = function(self)
	self._DefaultMenuName = ""

	local pageConf = PanelPageConfig.Activity
	for k, v in pairs(pageConf) do
		local unlock = game._CFunctionMan:IsUnlockByFunTid(v.FunTid)
		if v.IsShow and unlock then
			if self._DefaultMenuName == "" then
				self._DefaultMenuName = v.MenuBtn
			end
		else
			if self._CurrentMenuName == v.MenuBtnName then
				self._CurrentMenuName = ""
			end
		end
	end
end

def.method().UpdateShow = function(self)
	local pageInfo = self._Page[self._CurrentMenuName]
	if pageInfo then
		local scriptObj = pageInfo.ScriptObj
		if scriptObj then
			scriptObj:Show()
		end
	end

	self:UpdateBtnInfo()
end

-- 是否显示总的红点
def.method("=>", "boolean").IsShowRedPoint = function(self)
	local isShow = false
	for k, v in pairs(self._Page) do
		local scriptObj = v.ScriptObj
		if not scriptObj then
			local script = v.Script
			if v.Script then
				v.ScriptObj = require(script).new(self)
			end
		end
		
		scriptObj = v.ScriptObj
		if scriptObj then
			if scriptObj:ShowRedPoint() then
				isShow = true
			end
		end
	end
	return isShow
end

-- 菜单按钮红点和选中状态
def.method().UpdateBtnInfo = function(self)
	self:UpdateDefaultMenuBtnName()
	if self._CurrentMenuName == "" then
		self:ChangeShowPage(self._DefaultMenuName)
	end

	for k, v in pairs(self._Page) do
		local menuBtnName = v.MenuBtnName	
		-- 判断功能是否解锁
		local unlock = game._CFunctionMan:IsUnlockByFunTid(v.FunTid)
		v.MenuBtnGO:SetActive(v.IsShow and unlock)	

		local redPointGO = v.RedPoint
		local scriptObj = v.ScriptObj
		if not scriptObj then
			local script = v.Script
			if v.Script then
				v.ScriptObj = require(script).new(self)
			end
		end

		v.MenuBtnGO:GetComponent(ClassType.Toggle).isOn = self._CurrentMenuName == v.MenuBtnName
		
		scriptObj = v.ScriptObj
		if scriptObj then
			redPointGO:SetActive(scriptObj:ShowRedPoint())
		end
	end
end

--切换菜单页面
def.method("string").ChangeShowPage = function(self, MenuBtnName)
	if MenuBtnName == self._CurrentMenuName then return end
	local currentMenuName = self._CurrentMenuName
	self._CurrentMenuName = MenuBtnName
	local pageInfo = self._Page[MenuBtnName]
	if pageInfo then
		-- 更新UI
		pageInfo.Page:SetActive(true)
		local oldPageInfo = self._Page[currentMenuName]
		if oldPageInfo then
			oldPageInfo.Page:SetActive(false)
		end
		-- 更新脚本数据
		local scriptObj = pageInfo.ScriptObj
		if not scriptObj then
			local script = pageInfo.Script
			if script then
				if not scriptObj then
					pageInfo.ScriptObj = require(script).new(self)
					scriptObj = pageInfo.ScriptObj
				end
			end
		end
		if scriptObj then
			scriptObj:Show()
		end
		self._HelpUrlType = pageInfo.HelpUrlType
	end
end


def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
	local currentPage = self._Page[self._CurrentMenuName]
	if currentPage then
		local scriptObj = currentPage.ScriptObj
		if scriptObj then
			scriptObj:OnInitItem(item, id, index)
		end
	end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
	local currentPage = self._Page[self._CurrentMenuName]
	if currentPage then
		local scriptObj = currentPage.ScriptObj
		if scriptObj then
			scriptObj:OnSelectItem(item, id, index)
		end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    local currentPage = self._Page[self._CurrentMenuName]
	if currentPage then
		local scriptObj = currentPage.ScriptObj
		if scriptObj then
			scriptObj:OnSelectItemButton(item, id, id_btn, index)
		end
	end
end


def.method("number").UpdateUIState = function(self, eventType)
	local pageInfo = self._Page[self._CurrentMenuName]
	if pageInfo then
		local scriptObj = pageInfo.ScriptObj
		local redPointGO = pageInfo.RedPoint
		if scriptObj and pageInfo.IsRefrash then
			redPointGO:SetActive(scriptObj:ShowRedPoint())
			scriptObj:DailyTaskEventFormServer(eventType)
		end
	end
end

def.method("=>", "string").GetCurrentMenuName = function(self)
	return self._CurrentMenuName
end

def.override().OnHide = function(self)
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Activity, self:IsShowRedPoint())
end

def.override().OnDestroy = function(self)
	self._TitleRoot 		= nil
	self._MenuBtnRoot 		= nil
	self._PageRoot 			= nil

	for k, v in ipairs(self._Page) do
		local scriptObj = v.ScriptObj
		if scriptObj then
			scriptObj:OnDestroy()
		end
	end
	self._Page 				= {}

	instance = nil
end

CPanelUIActivity.Commit()
return CPanelUIActivity