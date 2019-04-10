--
--公会申请列表
--
--【孟令康】
--
--2017年9月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelUIGuildApply = Lplus.Extend(CPanelBase, "CPanelUIGuildApply")
local def = CPanelUIGuildApply.define

def.field("userdata")._List_MenuType = nil
-- 申请成员数据
def.field("table")._Apply_List = nil

local instance = nil
def.static("=>", CPanelUIGuildApply).Instance = function()
	if not instance then
		instance = CPanelUIGuildApply()
		instance._PrefabPath = PATH.UI_Guild_Apply
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self._List_MenuType = self:GetUIObject("List_MenuType"):GetComponent(ClassType.GNewListLoop)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Apply_List = {}	
	for i = #data, 1, -1 do
		self._Apply_List[#self._Apply_List + 1] = data[i]
	end
	self._List_MenuType:SetItemCount(#data)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Refresh" then
		self:OnBtnRefresh()
	elseif id == "Btn_RefuseAll" then
		self:OnBtnRefuseAll()
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_MenuType" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local data = self._Apply_List[index + 1]
    	game:SetEntityCustomImg(uiTemplate:GetControl(3), data.roleID, data.CustomImgSet, Profession2Gender[data.professionID], data.professionID)
    	GUI.SetText(uiTemplate:GetControl(4), data.roleName)
    	GUITools.SetGroupImg(uiTemplate:GetControl(5), data.professionID - 1)
    	GUI.SetText(uiTemplate:GetControl(7), tostring(data.roleLevel))
    	GUI.SetText(uiTemplate:GetControl(9), tostring(data.fightScore))
    end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id == "List_MenuType" then
    	if id_btn == "Btn_Agree" then
        	self:OnBtnApply(index, true)
        elseif id_btn == "Btn_Refuse" then
        	self:OnBtnApply(index, false)
        end
    end
end

-- 刷新列表
def.method("table").OnRefreshList = function(self, data)
	self._Apply_List = {}
	for i = #data, 1, -1 do
		self._Apply_List[#self._Apply_List + 1] = data[i]
	end
	self._List_MenuType:SetItemCount(#data)
	-- 红点数据请求
	game._GuildMan:SendC2SGuildRedPoint()
end

-- 单条同意或拒绝
def.method("number", "boolean").OnBtnApply = function(self, index, value)
	local protocol = nil
	if value then
		protocol = (require "PB.net".C2SGuildAcceptApply)()
	else
		protocol = (require "PB.net".C2SGuildRefuseApply)()
	end
	protocol.roleID = self._Apply_List[index + 1].roleID
	PBHelper.Send(protocol)
end

-- 刷新界面
def.method().OnBtnRefresh = function(self)
	local protocol = (require "PB.net".C2SGuildApplyList)()
	PBHelper.Send(protocol)
end

-- 拒绝全部请求
def.method().OnBtnRefuseAll = function(self)
	local protocol = (require "PB.net".C2SGuildRefuseApply)()
	for i,v in ipairs(self._Apply_List) do
		protocol.roleID = v.roleID
		PBHelper.Send(protocol)
	end
end

CPanelUIGuildApply.Commit()
return CPanelUIGuildApply