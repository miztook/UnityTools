--
--公会主界面
--
--【孟令康】
--
--2017年9月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CFrameCurrency = require "GUI.CFrameCurrency"
local EGuildRedPointType = require "PB.net".EGuildRedPointType
local CPageGuildBonus = require "Guild.CPageGuildBonus"
local CPageGuildBuilding = require "Guild.CPageGuildBuilding"
local CPageGuildInfo = require "Guild.CPageGuildInfo"
local CPageGuildMember = require "Guild.CPageGuildMember"
local CPageGuildSet = require "Guild.CPageGuildSet"
local CPanelUIGuild = Lplus.Extend(CPanelBase, "CPanelUIGuild")
local def = CPanelUIGuild.define


local Input_Type = ClassType.InputField
local BUILDING_COUNT = 5   -- 建筑列表数目

-- 通用货币界面
def.field(CFrameCurrency)._Frame_Money = nil

-- 单独模块
def.field(CPageGuildBonus)._PageGuildBonus = nil
def.field(CPageGuildBuilding)._PageGuildBuilding = nil
def.field(CPageGuildInfo)._PageGuildInfo = nil
def.field(CPageGuildMember)._PageGuildMember = nil
def.field(CPageGuildSet)._PageGuildSet = nil
def.field("table")._CurPage = nil

_G.GuildPage = 
{
	Info = 1,
	Member = 2,
	Bonus = 3,
	Building = 4,
	Setting = 5,

	None = 100,
}
-- 当前选中页面编号
def.field("number")._CurPageIndex = 0



-- 公会红点
--def.field("userdata")._Img_RedPoint6 = nil
--def.field("userdata")._Img_RedPoint7 = nil
--def.field("userdata")._Img_RedPoint8 = nil
-- 申请列表特效
def.field("userdata")._Img_BtnFloatFx = nil

-- 公会设置
def.field("userdata")._Tab_Guild_Set = nil
def.field("table")._Img_RedPoints = nil


local instance = nil
def.static("=>", CPanelUIGuild).Instance = function()
	if not instance then
		instance = CPanelUIGuild()
		instance._PrefabPath = PATH.UI_Guild
        instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
    self._Img_RedPoints = {}
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    self._PageGuildBonus = CPageGuildBonus.new(self, self:GetUIObject("Frame_Guild_Bonus"))
    self._PageGuildBuilding = CPageGuildBuilding.new(self, self:GetUIObject("Frame_Guild_Building"))
    self._PageGuildInfo = CPageGuildInfo.new(self, self:GetUIObject("Frame_Guild_Info"))
    self._PageGuildMember = CPageGuildMember.new(self, self:GetUIObject("Frame_Guild_Member"))
    self._PageGuildSet = CPageGuildSet.new(self, self:GetUIObject("Frame_Guild_Set"))
    self._Img_RedPoints[GuildPage.Info] = self:GetUIObject("Tab_Guild_Info"):FindChild("Img_RedPoint")
    self._Img_RedPoints[GuildPage.Member] = self:GetUIObject("Tab_Guild_Member"):FindChild("Img_RedPoint")
    self._Img_RedPoints[GuildPage.Bonus] = self:GetUIObject("Tab_Guild_Bonus"):FindChild("Img_RedPoint")
    self._Img_RedPoints[GuildPage.Building] = self:GetUIObject("Tab_Guild_Building"):FindChild("Img_RedPoint")
    self._Img_RedPoints[GuildPage.Setting] = self:GetUIObject("Tab_Guild_Set"):FindChild("Img_RedPoint")
    --self._Img_RedPoint6 = self:GetUIObject("Img_RedPoint6")
    --self._Img_RedPoint7 = self:GetUIObject("Img_RedPoint7")
    --self._Img_RedPoint8 = self:GetUIObject("Img_RedPoint9")
    self._Img_BtnFloatFx = self:GetUIObject("Img_BtnFloatFx0")
    self._Img_BtnFloatFx:SetActive(false)

    self._Tab_Guild_Set = self:GetUIObject("Tab_Guild_Set")
    game._GuildMan:SendC2SGuildBaseInfo(game._GuildMan:GetHostPlayerGuildID(), "")
	-- 红点数据请求
	--game._GuildMan:SendC2SGuildRedPoint()
	self._HelpUrlType = HelpPageUrlType.Guild_Main
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
    local self_member = game._GuildMan:GetHostGuildMemberInfo()
    local have_set_per = true
    if self_member ~= nil then
        local tab_guild_set = self:GetUIObject("Tab_Guild_Set")
        if 0 ~= bit.band(self_member._Permission, PermissionMask.SetDisplayInfo) then
            tab_guild_set:SetActive(true)
        else
            tab_guild_set:SetActive(false)
            have_set_per = false
        end
    end
	local id = nil
	if data == _G.GuildPage.Info then
		id = "Tab_Guild_Info"
	elseif data == _G.GuildPage.Member then
		id = "Tab_Guild_Member"
	elseif data == _G.GuildPage.Bonus then
		id = "Tab_Guild_Bonus"
	elseif data == _G.GuildPage.Building then
		id = "Tab_Guild_Building"
	elseif data == _G.GuildPage.Setting then
        if not have_set_per then
            id = "Tab_Guild_Building"
        else
    		id = "Tab_Guild_Set"
        end
	end
	if id ~= nil then
		self:GetUIObject(id):GetComponent(ClassType.Toggle).isOn = true
		self:OnToggle(id, true)
	end
end

def.override("string","boolean").OnToggle = function(self, id, checked)
	if checked then
        local is_send_pro = false
		if id == "Tab_Guild_Info" then
			self._PageGuildBonus:Hide()
			self._PageGuildBuilding:Hide()
			self._PageGuildInfo:Show()
			self._PageGuildMember:Hide()
			self._PageGuildSet:Hide()
			self._CurPageIndex = _G.GuildPage.Info
            self._CurPage = self._PageGuildInfo
            is_send_pro = true
		elseif id == "Tab_Guild_Member" then
			self._PageGuildBonus:Hide()
			self._PageGuildBuilding:Hide()
			self._PageGuildInfo:Hide()
			self._PageGuildMember:Show()
			self._PageGuildSet:Hide()
			self._CurPageIndex = _G.GuildPage.Member
            self._CurPage = self._PageGuildMember
            is_send_pro = true
		elseif id == "Tab_Guild_Bonus" then
			self._PageGuildBonus:Show()
			self._PageGuildBuilding:Hide()
			self._PageGuildInfo:Hide()
			self._PageGuildMember:Hide()
			self._PageGuildSet:Hide()
			self._CurPageIndex = _G.GuildPage.Bonus
            self._CurPage = self._PageGuildBonus
            is_send_pro = true
		elseif id == "Tab_Guild_Building" then
			self._PageGuildBonus:Hide()
			self._PageGuildBuilding:Show()
			self._PageGuildInfo:Hide()
			self._PageGuildMember:Hide()
			self._PageGuildSet:Hide()
			self._CurPageIndex = _G.GuildPage.Building
            self._CurPage = self._PageGuildBuilding
            is_send_pro = true
		elseif id == "Tab_Guild_Set" then
			self._PageGuildBonus:Hide()
			self._PageGuildBuilding:Hide()
			self._PageGuildInfo:Hide()
			self._PageGuildMember:Hide()
			self._PageGuildSet:Show()
			self._CurPageIndex = _G.GuildPage.Setting
            self._CurPage = self._PageGuildSet
            is_send_pro = true
		else
			is_send_pro = false
		end
        if is_send_pro then
            game._GuildMan:SendC2SGuildBaseInfo(game._GuildMan:GetHostPlayerGuildID(), "")
        end
	 end
end

-- 当点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
    	TODO(StringTable.Get(19))
	else
--		if self._CurPageIndex == _G.GuildPage.Info then
--			self._PageGuildInfo:OnClick(id)
--		elseif self._CurPageIndex == _G.GuildPage.Member then
--			self._PageGuildMember:OnClick(id)
--		elseif self._CurPageIndex == _G.GuildPage.Bonus then
--			self._PageGuildBonus:OnClick(id)
--		elseif self._CurPageIndex == _G.GuildPage.Building then
--			self._PageGuildBuilding:OnClick(id)
--		elseif self._CurPageIndex == _G.GuildPage.Setting then
--			self._PageGuildSet:OnClick(id)
--		end
        if self._CurPage ~= nil then
            self._CurPage:OnClick(id)
        end
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if id == "Info_Right_List" then
		self._PageGuildInfo:OnInitItem(item, id, index)
	elseif id == "Guild_Event_List" then
		self._PageGuildInfo:OnInitItem(item, id, index)
	elseif id == "Guild_Member_List" then
		self._PageGuildMember:OnInitItem(item, id, index)
	elseif id == "Guild_Building_List" then
		self._PageGuildBuilding:OnInitItem(item, id, index)
	elseif id == "Group_List_1" then
		self._PageGuildSet:OnInitItem(item, id, index)
	elseif id == "Group_List_2" then
		self._PageGuildSet:OnInitItem(item, id, index)
		elseif id == "Group_List_3" then
		self._PageGuildSet:OnInitItem(item, id, index)
	end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:OnSelectItem(item, id, index)
	elseif self._CurPageIndex == _G.GuildPage.Member then
		self._PageGuildMember:OnSelectItem(item, id, index)
	elseif self._CurPageIndex == _G.GuildPage.Building then
		self._PageGuildBuilding:OnSelectItem(item, id, index)
	elseif self._CurPageIndex == _G.GuildPage.Setting then
		self._PageGuildSet:OnSelectItem(item, id, index)
	end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	if self._CurPageIndex == _G.GuildPage.Building then
		self._PageGuildBuilding:OnSelectItemButton(item, id, id_btn, index)
	end
end

-- 当输入框变化
def.override("string", "string").OnValueChanged = function(self, id, str)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:OnValueChanged(id, str)
	elseif self._CurPageIndex == _G.GuildPage.Setting then
		self._PageGuildSet:OnValueChanged(id, str)
	end
end

-- 当输入框结束操作
def.override("string", "string").OnEndEdit = function(self, id, str)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:OnEndEdit(id, str)
	elseif self._CurPageIndex == _G.GuildPage.Setting then
		self._PageGuildSet:OnEndEdit(id, str)
	end
end

-- 基础信息刷新
def.method().UpdatePageGuildInfo = function(self)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:Update()
	elseif self._CurPageIndex == _G.GuildPage.Bonus then
		self._PageGuildBonus:Update()
	end
	game._GUIMan:Close("CPanelUIRename")
end

-- 资源信息刷新
def.method().UpdatePageGuildBonus = function(self)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:Update()
	elseif self._CurPageIndex == _G.GuildPage.Bonus then
		self._PageGuildBonus:Update()
	end

	--self._PageGuildBonus:OnInit()
	game._GUIMan:Close("CPanelUIRename")
	-- 红点数据请求
	game._GuildMan:SendC2SGuildRedPoint()
end

-- 设置界面刷新
def.method().UpdatePageGuildSet = function(self)
	if self._CurPageIndex == _G.GuildPage.Setting then
		self._PageGuildSet:Update()
	end
end

-- 公会成员信息刷新
def.method().UpdateGuildMembersInfo = function(self)
    local self_member = game._GuildMan:GetHostGuildMemberInfo()
    local have_set_per = true
    if self_member ~= nil then
        local tab_guild_set = self:GetUIObject("Tab_Guild_Set")
        if 0 ~= bit.band(self_member._Permission, PermissionMask.SetDisplayInfo) then
            tab_guild_set:SetActive(true)
        else
            tab_guild_set:SetActive(false)
            have_set_per = false
        end
    end
    if self._CurPageIndex == _G.GuildPage.Setting then
        if not have_set_per then
            self:GetUIObject("Tab_Guild_Building"):GetComponent(ClassType.Toggle).isOn = true
		    self:OnToggle("Tab_Guild_Building", true)
        end
	elseif self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:Update()
	elseif self._CurPageIndex == _G.GuildPage.Member then
		self._PageGuildMember:Update()
	end

	-- 红点数据请求
	game._GuildMan:SendC2SGuildRedPoint()
end

-- 展示公会事件
def.method("table").UpdateGuildEvent = function(self, data)
	if self._CurPageIndex == _G.GuildPage.Info then
		self._PageGuildInfo:ShowGuildEvent(data)
	end
end

-- 公会建筑信息刷新
def.method().UpdatePageGuildBuilding = function(self)
    print("更新建筑信息")
	if self._CurPageIndex == _G.GuildPage.Building then
		self._PageGuildBuilding:UpdateBuildingList()
	end
	-- 红点数据请求
	game._GuildMan:SendC2SGuildRedPoint()
end

def.method().HideAllPageRedPoints = function(self)
    for k,v in pairs(self._Img_RedPoints) do
        v:SetActive(false)
    end
end

def.method("number", "boolean").ShowPageRedPoint = function(self, pageType, isShow)
    for k,v in pairs(self._Img_RedPoints) do
        if k == pageType then
            v:SetActive(isShow)
        end
    end
end

-- 展示红点
def.method().UpdateRedPoint = function(self)
	local member = game._GuildMan:GetHostGuildMemberInfo()
	if member == nil then return end
	self:HideAllPageRedPoints()
	self._Img_BtnFloatFx:SetActive(false)
	--CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, false)
	game._HostPlayer._Guild._ShowSalary = false
	local points = game._HostPlayer._Guild._RedPoint
	for i, v in ipairs(points) do
		if v == EGuildRedPointType.EGuildRedPointType_PointsReward then
            self:ShowPageRedPoint(GuildPage.Bonus, true)
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, true)			
		elseif v == EGuildRedPointType.EGuildRedPointType_Pray then
			self:ShowPageRedPoint(GuildPage.Building, true)
		elseif v == EGuildRedPointType.EGuildRedPointType_HasApply then
			if member._RoleType == 1 then
				self:ShowPageRedPoint(GuildPage.Member, true)
				self._Img_BtnFloatFx:SetActive(true)
			end
		elseif v == EGuildRedPointType.EGuildRedPointType_Salary then
			game._HostPlayer._Guild._ShowSalary = true
			self:ShowPageRedPoint(GuildPage.Building, true)
		else
			warn("OnShowRedPoint new type")
		end
	end
    if self._CurPage ~= nil and self._CurPage.UpdatePageRedPoint ~= nil then
        self._CurPage:UpdatePageRedPoint()
    end
end

def.override().OnHide = function(self)
	self._CurPageIndex = _G.GuildPage.None
end

-- 当摧毁
def.override().OnDestroy = function(self)
    self._CurPage = nil
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    if self._PageGuildBonus ~= nil then
    	self._PageGuildBonus:Destroy()
    	self._PageGuildBonus = nil
    end
    if self._PageGuildBuilding ~= nil then
    	self._PageGuildBuilding:Destroy()
    	self._PageGuildBuilding = nil
    end
    if self._PageGuildInfo ~= nil then
    	self._PageGuildInfo:Destroy()
    	self._PageGuildInfo = nil
    end
    if self._PageGuildMember ~= nil then
    	self._PageGuildMember:Destroy()
    	self._PageGuildMember = nil
    end
    if self._PageGuildSet ~= nil then
    	self._PageGuildSet:Destroy()
    	self._PageGuildSet = nil
    end
    instance = nil
end

CPanelUIGuild.Commit()
return CPanelUIGuild