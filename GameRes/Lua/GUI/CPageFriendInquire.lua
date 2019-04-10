local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local CPageFriendInquire = Lplus.Class("CPageFriendInquire")
local def = CPageFriendInquire.define

def.field("userdata")._InputSearch = nil 
def.field("userdata")._LabNothing = nil 
def.field("userdata")._ListInquire = nil 
def.field("userdata")._LabTitle = nil 

def.field("table")._Parent = nil 
def.field("table")._SearchResultData = nil 
def.field("table")._RecommendDataList = nil 
def.field("boolean")._IsShowRecommondList = false
def.field("table")._ItemList = BlankTable
def.field("boolean")._IsOpenFrist = false

local instance = nil
def.static("=>", CPageFriendInquire).Instance = function()
	if instance == nil then
        instance = CPageFriendInquire()
        instance._IsOpenFrist = true
	end
	return instance
end

--角色名是否是自己
local function IsSameNameWithSelf(role_name)
    return game._HostPlayer._InfoData._Name == role_name
end

local function UpdateInquireResult(self)
	self._SearchResultData = game._CFriendMan:GetSearchReault()
	if self._SearchResultData == nil then 
		self._ListInquire:SetActive(false)
		self._LabNothing:SetActive(true)
	else
		self._ListInquire:SetActive(true)
		self._LabNothing:SetActive(false)
		self._ItemList = {}
		self._ListInquire:SetActive(true)
		self._ListInquire:GetComponent(ClassType.GNewList):SetItemCount(1)
	end
end

local function UpdateRecommondList(self)
	--  获取推荐列表
	self._RecommendDataList = game._CFriendMan:GetRecommondList()
	self._ItemList = {}
	self._LabNothing:SetActive(false)
	self._ListInquire:SetActive(true)
	self._ListInquire:GetComponent(ClassType.GNewList):SetItemCount(#self._RecommendDataList)
end 

def.method("table").Show = function(self, parent)
	if not self._IsOpenFrist then return end
	self._IsOpenFrist = false
	self._Parent = parent  
	self._IsShowRecommondList = true
	self._LabNothing = self._Parent:GetUIObject("Lab_NothingInquireResult")
	self._InputSearch = self._Parent:GetUIObject("Input_Search"):GetComponent(ClassType.InputField)
	self._ListInquire = self._Parent:GetUIObject("List_Inquire")
	self._LabNothing:SetActive(false)
	game._CFriendMan:DoRcommond()

end

def.method().UpdatePage = function (self)
	if self._IsShowRecommondList then 
		UpdateRecommondList(self)
	else
		UpdateInquireResult(self)
	end
end

def.method("string").Click = function (self,id)
	if id == "Btn_Search" then 
		if IsNilOrEmptyString(self._InputSearch.text) then 
			game._GUIMan:ShowTipText(StringTable.Get(30337),false)
		 	return 
		end
		if IsSameNameWithSelf(self._InputSearch.text) then 
			game._GUIMan:ShowTipText(StringTable.Get(30308),false)
	        return
	    end
	    self._IsShowRecommondList = false
		game._CFriendMan:DoSearch(self._InputSearch.text)
	elseif id == "Btn_ChangeRecommend" then 
		self._IsShowRecommondList = true
		game._CFriendMan:DoRcommond()
	elseif id == "Btn_AllApply" then 
		if not self._IsShowRecommondList then  
			if self._SearchResultData == nil then
				game._GUIMan:ShowTipText(StringTable.Get(30305),false)
			return end
			game._CFriendMan:DoFriendApply(self._SearchResultData.RoleId)
		else
			if self._RecommendDataList == nil then return end
			game._CFriendMan:DoFriendApply(self._RecommendDataList)
		end
		if #self._ItemList == 0 then return end
		for i,item in ipairs(self._ItemList) do
			local uiTemplate = item:GetComponent(ClassType.UITemplate)
			local BtnInvite = uiTemplate:GetControl(4)
			local imgBtn = uiTemplate:GetControl(6)
			local labBtn = uiTemplate:GetControl(7)
			GUI.SetText(labBtn,StringTable.Get(30351))
       		GameUtil.MakeImageGray(imgBtn,true)
       		GameUtil.SetButtonInteractable(BtnInvite, false)
		end
	end
end

def.method('userdata', 'string', 'number').InitItem = function(self, item, id, index)
	if id == "List_Inquire" then 
		local data = nil
		if not self._IsShowRecommondList then 
			data = self._SearchResultData
		else
			data = self._RecommendDataList[index + 1]
		end
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHead = uiTemplate:GetControl(0)
		local labName = uiTemplate:GetControl(1)
		local labProfession = uiTemplate:GetControl(2)
		local labLv = uiTemplate:GetControl(3)
		local BtnInvite = uiTemplate:GetControl(4)
		local imgIsFriend = uiTemplate:GetControl(5)
		local imgBtn = uiTemplate:GetControl(6)
		local labBtn = uiTemplate:GetControl(7)
		table.insert(self._ItemList,item)
		GUI.SetText(labName, data.Name)
        GUI.SetText(labLv, string.format( StringTable.Get(30327),data.Level))
        GUI.SetText(labProfession,tostring(StringTable.Get(10300 + data.Profession - 1)))
        game:SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
    	if game._CFriendMan:IsFriend(data.RoleId) then 
    		BtnInvite:SetActive(false)
    		imgIsFriend:SetActive(true)
    	else
    		BtnInvite:SetActive(true)
    		imgIsFriend:SetActive(false)
    		GUI.SetText(labBtn,StringTable.Get(30350))
        	GameUtil.MakeImageGray(imgBtn,false)
        	GameUtil.SetButtonInteractable(BtnInvite, true)
    	end   
	end
end

-- 点击按钮就显示 已申请
def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if id ==  "List_Inquire"  then 
		local data = nil
		if not self._IsShowRecommondList then 
			data = self._SearchResultData
		else
			data = self._RecommendDataList[index + 1] 
		end	
		if id_btn == "Btn_Invite" then 
			if game._CFriendMan:IsFriendNumberOverMax() then return end 
			local item = self._ItemList[index + 1]
			local uiTemplate = item:GetComponent(ClassType.UITemplate)
			local BtnInvite = uiTemplate:GetControl(4)
			local imgBtn = uiTemplate:GetControl(6)
			local labBtn = uiTemplate:GetControl(7)
			GUI.SetText(labBtn,StringTable.Get(30351))
       		GameUtil.MakeImageGray(imgBtn,true)
       		GameUtil.SetButtonInteractable(BtnInvite, false)
			game._CFriendMan:DoFriendApply(data.RoleId)  
		elseif id_btn == "Btn_Border" then 
			game:CheckOtherPlayerInfo(data.RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Friend)
		end
	end
end

-- 该界面关闭后数据是保存的
def.method().Hide = function (self)
	self._IsOpenFrist = true
	if self._InputSearch ~= nil then
		self._InputSearch.text = ""
	end
end

def.method().Destroy = function (self)
	instance = nil 
end

CPageFriendInquire.Commit()
return CPageFriendInquire