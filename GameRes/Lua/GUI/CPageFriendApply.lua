local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local CPageFriendApply = Lplus.Class("CPageFriendApply")
local def = CPageFriendApply.define

def.field("userdata")._LabNothing = nil 
def.field("userdata")._ListApply = nil 
def.field("userdata")._BtnAllAgree = nil 
def.field("userdata")._BtnAllReject = nil 

def.field("table")._Parent = nil 
def.field("table")._ApplyDatas = nil 


local instance = nil
def.static("=>", CPageFriendApply).Instance = function()
	if instance == nil then
        instance = CPageFriendApply()
	end
	return instance
end

def.method("table").Show = function(self, parent)
	self._Parent = parent  
	self._LabNothing = self._Parent:GetUIObject("Lab_NothingApply")
	self._ListApply = self._Parent:GetUIObject("List_Apply"):GetComponent(ClassType.GNewList)
	self._BtnAllAgree = self._Parent:GetUIObject("Btn_AllAgree")
	self._BtnAllReject = self._Parent:GetUIObject("Btn_AllReject")
	self:UpdatePage()
	local data = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Friends)
	if data == nil then return end
	data.IsShowApplyRed = false
	CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Friends,data)

end

def.method().UpdatePage = function(self)
	self._ApplyDatas = game._CFriendMan:GetFriendsApply()
	if self._ApplyDatas == nil or #self._ApplyDatas == 0 then 
		self._LabNothing:SetActive(true)
		self._ListApply:SetItemCount(0)
		self._BtnAllReject:SetActive(false)
		self._BtnAllAgree:SetActive(false)
		return
	end
	self._BtnAllReject:SetActive(true)
	self._BtnAllAgree:SetActive(true)
	self._LabNothing:SetActive(false)
	self._ListApply:SetItemCount(#self._ApplyDatas)
end

def.method("string").Click = function (self,id)
	if id == "Btn_AllAgree" then
		if self._ApplyDatas == nil or #self._ApplyDatas == 0 then 
			game._GUIMan:ShowTipText(StringTable.Get(30305),false)
			self._ListApply:SetItemCount(0)
			return
		end
		local RoleIdList = {}
		for i,v in ipairs(self._ApplyDatas) do
			table.insert(RoleIdList,v.RoleId)
		end
		game._CFriendMan:DoAgreeApply(RoleIdList)
	elseif id == "Btn_AllReject" then 
		if self._ApplyDatas == nil or #self._ApplyDatas == 0 then 
			game._GUIMan:ShowTipText(StringTable.Get(30305),false)
			self._ListApply:SetItemCount(0)
			return
		end
		game._CFriendMan:DoClearApplyList()
	end
end

def.method('userdata', 'string', 'number').InitItem = function(self, item, id, index)
	if id == "List_Apply" then 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHead = uiTemplate:GetControl(0)
		local labName = uiTemplate:GetControl(1)
		local labProfession = uiTemplate:GetControl(2)
		local labLv = uiTemplate:GetControl(3)
		local labFight = uiTemplate:GetControl(4)
		GUI.SetText(labName, self._ApplyDatas[index + 1].Name)
        GUI.SetText(labLv,string.format(StringTable.Get(30327), self._ApplyDatas[index + 1].Level))
        GUI.SetText(labProfession,tostring(StringTable.Get(10300 + self._ApplyDatas[index + 1].Profession - 1)))
        game:SetEntityCustomImg(imgHead,self._ApplyDatas[index + 1].RoleId,self._ApplyDatas[index + 1].CustomImgSet,self._ApplyDatas[index + 1].Gender,self._ApplyDatas[index + 1].Profession)
        GUI.SetText(labFight,tostring(self._ApplyDatas[index + 1].Fight))
	end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if id ==  "List_Apply"  then 
		if id_btn == "Btn_Agree" then 
			if game._CFriendMan:IsFriend(self._ApplyDatas[index + 1].RoleId) then 
				game._GUIMan:ShowTipText(StringTable.Get(30339), false)
				table.remove(self._ApplyDatas,index + 1)
				self._ListApply:SetItemCount(#self._ApplyDatas)
			return end
			game._CFriendMan:DoAgreeApply({self._ApplyDatas[index + 1].RoleId})
		elseif id_btn == "Btn_Reject" then 
			if game._CFriendMan:IsFriend(self._ApplyDatas[index + 1].RoleId) then 
				game._GUIMan:ShowTipText(StringTable.Get(30339), false)
				table.remove(self._ApplyDatas,index + 1)
				self._ListApply:SetItemCount(#self._ApplyDatas)
			return end
			game._CFriendMan:DoRejectApply({self._ApplyDatas[index + 1].RoleId}) 
		elseif id_btn == "Btn_Border" then 
			game:CheckOtherPlayerInfo(self._ApplyDatas[index + 1].RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.FriendApply)
		end
	end
end

def.method().Hide = function(self)
	self._ApplyDatas = {}
	self._LabNothing = nil 
	self._ListApply = nil 
	self._BtnAllReject = nil
	self._BtnAllAgree  = nil 
end

def.method().Destroy = function (self)
	instance = nil 
end

CPageFriendApply.Commit()
return CPageFriendApply