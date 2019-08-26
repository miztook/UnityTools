local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPageFriendApply = require "GUI.CPageFriendApply"
local CPageFriendInquire = require "GUI.CPageFriendInquire"
local CPageFriendList = require "GUI.CPageFriendList"
local CPageBlackList = require "GUI.CPageBlackList"
local CElementData = require "Data.CElementData"
local MenuComponents = require"GUI.MenuComponents"
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local CPanelFriend = Lplus.Extend(CPanelBase, 'CPanelFriend')
local def = CPanelFriend.define

def.field("userdata")._FrameFriendList  = nil 
def.field("userdata")._FrameInquire = nil 
def.field("userdata")._FrameApply = nil 
def.field("userdata")._FrameBlackList = nil 
def.field("userdata")._RdoFriendList  = nil 
def.field("userdata")._RdoInquire = nil 
def.field("userdata")._RdoApply  = nil 
def.field("userdata")._RdoBlackList = nil 

def.field("number")._CurTogglePage = 0 

local OpenPageType = {
							NONE = 0,
							FRIENDLIST = 1,            -- 好友列表
							APPLY = 2,				   -- 申请
							INQUIRE = 3,			   -- 查询（添加好友）
							BLACKLIST = 4,             -- 黑名单
						}
def.const("table").OpenPageType = OpenPageType

local instance = nil
def.static("=>", CPanelFriend).Instance = function() 
	if not instance then
		instance = CPanelFriend()
		instance._PrefabPath = PATH.UI_Friend
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = false
		instance._ClickInterval = 1
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._FrameFriendList = self:GetUIObject("Frame_FriendList")
	self._FrameInquire = self:GetUIObject("Frame_Inquire")
	self._FrameApply = self:GetUIObject("Frame_ApplyList")
	self._FrameBlackList = self:GetUIObject("Frame_BlackList")
	self._RdoFriendList = self:GetUIObject("Rdo_FriendList")
	self._RdoInquire = self:GetUIObject("Rdo_Inquire")
	self._RdoApply = self:GetUIObject("Rdo_Apply")
	self._RdoBlackList  = self:GetUIObject("Rdo_BlackList")

end

def.override("dynamic").OnData = function(self,data)
    self._CurTogglePage = OpenPageType.FRIENDLIST
   	CPageFriendInquire.Instance()._IsOpenFrist = true
   	self:InitPanel()
end

def.method().InitPanel = function(self)
    self:ShowRedApply()
	self._RdoFriendList:GetComponent(ClassType.Toggle).isOn = true
	self._RdoInquire:GetComponent(ClassType.Toggle).isOn = false
	self._RdoApply:GetComponent(ClassType.Toggle).isOn = false
	self._RdoBlackList:GetComponent(ClassType.Toggle).isOn = false
	self._RdoFriendList:FindChild("Img_D"):SetActive(true)
    self._RdoInquire:FindChild("Img_D"):SetActive(false)
    self._RdoApply:FindChild("Img_D"):SetActive(false)
    self._RdoBlackList:FindChild("Img_D"):SetActive(false)

    self._RdoFriendList:FindChild("Img_U"):SetActive(false)
    self._RdoInquire:FindChild("Img_U"):SetActive(true)
    self._RdoApply:FindChild("Img_U"):SetActive(true)
    self._RdoBlackList:FindChild("Img_U"):SetActive(true)

    self._FrameFriendList:SetActive(true)
	self._FrameInquire:SetActive(false)
	self._FrameApply:SetActive(false)
	self._FrameBlackList:SetActive(false)
	CPageFriendList.Instance():Show(self)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Close" then 
        game._GUIMan:CloseByScript(self)
    end
    if self._CurTogglePage == OpenPageType.INQUIRE then 
        CPageFriendInquire.Instance():Click(id)
    elseif self._CurTogglePage == OpenPageType.APPLY then 
        CPageFriendApply.Instance():Click(id)
    elseif self._CurTogglePage == OpenPageType.BLACKLIST then 
        CPageBlackList.Instance():Click(id)
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
	if id == "Rdo_FriendList" and checked then 
        if self._CurTogglePage == OpenPageType.FRIENDLIST then return end 
		self._CurTogglePage = OpenPageType.FRIENDLIST
		self._FrameFriendList:SetActive(true)
		self._FrameInquire:SetActive(false)
		self._FrameApply:SetActive(false)
		self._FrameBlackList:SetActive(false)
		CPageFriendList.Instance():Show(self)
	elseif id == "Rdo_Inquire" and checked then 
		if self._CurTogglePage == OpenPageType.INQUIRE then return end 
		self._CurTogglePage = OpenPageType.INQUIRE
		self._FrameFriendList:SetActive(false)
		self._FrameInquire:SetActive(true)
		self._FrameApply:SetActive(false)
		self._FrameBlackList:SetActive(false)
		CPageFriendInquire.Instance():Show(self)
	elseif id == "Rdo_Apply" and checked then 
		if self._CurTogglePage == OpenPageType.APPLY then return end 
		self._CurTogglePage = OpenPageType.APPLY
		self._FrameFriendList:SetActive(false)
		self._FrameInquire:SetActive(false)
		self._FrameApply:SetActive(true)
		self._FrameBlackList:SetActive(false)
		CPageFriendApply.Instance():Show(self)
        self._RdoApply:FindChild("Img_RedPoint"):SetActive(false)
	elseif id == "Rdo_BlackList" and checked then 
		if self._CurTogglePage == OpenPageType.BLACKLIST then return end 
		self._CurTogglePage = OpenPageType.BLACKLIST
		self._FrameFriendList:SetActive(false)
		self._FrameInquire:SetActive(false)
		self._FrameApply:SetActive(false)
		self._FrameBlackList:SetActive(true)
		CPageBlackList.Instance():Show(self)
	end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if self._CurTogglePage == OpenPageType.FRIENDLIST then 
        CPageFriendList.Instance():InitItem(item, id, index)
    elseif self._CurTogglePage == OpenPageType.INQUIRE then 
        CPageFriendInquire.Instance():InitItem(item, id, index)
    elseif self._CurTogglePage == OpenPageType.APPLY then 
        CPageFriendApply.Instance():InitItem(item, id, index)
    elseif self._CurTogglePage == OpenPageType.BLACKLIST then 
        CPageBlackList.Instance():InitItem(item, id, index)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if self._CurTogglePage == OpenPageType.FRIENDLIST then 
        CPageFriendList.Instance():SelectItem(item, id, index)
    elseif self._CurTogglePage == OpenPageType.BLACKLIST then 
        CPageBlackList.Instance():SelectItem(item, id, index)
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, btn_obj, id, id_btn, index)
    if self._CurTogglePage == OpenPageType.FRIENDLIST then 
        CPageFriendList.Instance():SelectItemButton(btn_obj, id, id_btn, index)
    elseif self._CurTogglePage == OpenPageType.INQUIRE then 
        CPageFriendInquire.Instance():SelectItemButton(btn_obj, id, id_btn, index)
    elseif self._CurTogglePage == OpenPageType.APPLY then 
        CPageFriendApply.Instance():SelectItemButton(btn_obj, id, id_btn, index)
    elseif self._CurTogglePage == OpenPageType.BLACKLIST then 
        CPageBlackList.Instance():SelectItemButton(btn_obj, id, id_btn, index)
    end
end

def.method("dynamic").UpdatePageShow = function (self,param)
	if not self:IsShow() then return end
	if self._CurTogglePage == OpenPageType.APPLY and param == OpenPageType.APPLY then 
		CPageFriendApply.Instance():UpdatePage()
	elseif self._CurTogglePage == OpenPageType.INQUIRE and param == OpenPageType.INQUIRE then 
		CPageFriendInquire.Instance():UpdatePage()
	elseif self._CurTogglePage == OpenPageType.FRIENDLIST and param == OpenPageType.FRIENDLIST then
		CPageFriendList.Instance():UpdatePage()
	elseif self._CurTogglePage == OpenPageType.BLACKLIST and param == OpenPageType.BLACKLIST then 
		CPageBlackList.Instance():UpdatePage()
	end
end

-- 更新申请列表的红点显示
def.method().ShowRedApply = function(self) 
	if not self:IsShow() or self._CurTogglePage == OpenPageType.APPLY then return end
	local img_RedPoint = self._RdoApply:FindChild("Img_RedPoint")
	local data = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Friends)
	if data ~= nil then 
		img_RedPoint:SetActive(data.IsShowApplyRed)
	else
		img_RedPoint:SetActive(false)
	end
end

-- 关闭界面时调用
def.method().ShowChatFriendRed = function (self)
	local IsShowApplyRed = false
	local data = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Friends)
	if data ~= nil then 
		IsShowApplyRed = data.IsShowApplyRed
	end
	if not IsShowApplyRed then 
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Friends,false)
	else
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Friends,true)
	end
end

def.override().OnHide = function(self)

    self:ShowChatFriendRed()
    self._CurTogglePage = OpenPageType.NONE

    CPageFriendList.Instance():Hide()
    CPageFriendInquire.Instance():Hide()
    CPageFriendApply.Instance():Hide()
    CPageBlackList.Instance():Hide()
end

def.override().OnDestroy = function(self)

   	CPageFriendList.Instance():Destroy()
    CPageFriendInquire.Instance():Destroy()
    CPageFriendApply.Instance():Destroy()
    CPageBlackList.Instance():Destroy()

   	instance = nil 

end


CPanelFriend.Commit()
return CPanelFriend