local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local CPageBlackList = Lplus.Class("CPageBlackList")
local def = CPageBlackList.define


def.field("userdata")._ListBlack = nil
def.field("userdata")._LabNo = nil
def.field("table")._BlackListData = BlankTable 
-- def.field("number")._CurSelectIndex = 0
-- def.field("userdata")._CurSelectItem = nil 
def.field("table")._Parent = nil 
-- def.field("table")._ItemList = nil 

local instance = nil
def.static("=>", CPageBlackList).Instance = function()
	if instance == nil then
        instance = CPageBlackList()
	end
	return instance
end

def.method("table").Show = function(self, parent)
	self._Parent = parent  
	self._ListBlack = self._Parent:GetUIObject("List_BlackList")
	self._LabNo = self._Parent:GetUIObject("Lab_NoBlack")
	-- self._CurSelectIndex = 1
	self:UpdatePage()
end

def.method().UpdatePage = function(self)
	self._BlackListData = game._CFriendMan:GetBlackListData()
	local btnAllRemove = self._Parent:GetUIObject("Frame_BlackList"):FindChild("Btn_AllRemove")
	if #self._BlackListData == 0 then 
		self._ListBlack:SetActive(false)
		self._LabNo:SetActive(true)
		btnAllRemove:SetActive(false)
	return end
	btnAllRemove:SetActive(true)
	self._ListBlack:SetActive(true)
	self._LabNo:SetActive(false)
	-- self._ItemList = {}
	self._ListBlack:GetComponent(ClassType.GNewList):SetItemCount(#self._BlackListData)
end

def.method("string").Click = function(self,id)
	if id == "Btn_AllRemove" then 
		local function callback(value)
			if not value then return end
			local ids = {}
			for i=1,#self._BlackListData do
				table.insert(ids,self._BlackListData[i].RoleId)
			end
			game._CFriendMan:DoOutBlackList(ids)
		end
		local title, str, closeType = StringTable.GetMsg(99)
        MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
	end
end

def.method('userdata', 'string', 'number').InitItem = function(self, item, id, index)
	if id == "List_BlackList" then 
		-- table.insert(self._ItemList,item)
		local data = self._BlackListData[index + 1] 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHead = uiTemplate:GetControl(1)
		local labName = uiTemplate:GetControl(2)
		local labProfession = uiTemplate:GetControl(3)
		local lablv = uiTemplate:GetControl(4)
		local labFight = uiTemplate:GetControl(5)
		local labTime = uiTemplate:GetControl(6) 
		local btnApply = uiTemplate:GetControl(7)
		GUI.SetText(labName, data.Name)
        GUI.SetText(lablv, string.format(StringTable.Get(30327),data.Level))
        TeraFuncs.SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
        GUI.SetText(labFight,GUITools.FormatNumber(data.Fight))
        GUI.SetText(labProfession,tostring(StringTable.Get(10300 + data.Profession - 1)))
        btnApply:SetActive(false)
        local time = os.date("%Y-%m-%d",data.BlackOptTime /1000)
        GUI.SetText(labTime,time)
        if not game._CFriendMan:IsFriend(data.RoleId) then 
        	btnApply:SetActive(true)
        end
	end
end

def.method('userdata', 'string', 'number').SelectItem = function(self, item, id, index)
	-- if id == "List_BlackList" then 
	-- 	if self._CurSelectIndex ~= index + 1 and self._CurSelectIndex ~= nil then 
	-- 		self._CurSelectItem:FindChild("Img_D"):SetActive(false)
	-- 	end
	-- 	item:FindChild("Img_D"):SetActive(true)
	-- 	self._CurSelectIndex = index + 1
	-- 	self._CurSelectItem = item
	-- end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if id == "List_BlackList"then 
		-- self._CurSelectItem = self._ItemList[index + 1]
		if id_btn == "Btn_Border" then
			local PBUtil = require "PB.PBUtil"
			PBUtil.RequestOtherPlayerInfo(self._BlackListData[index + 1].RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Friend)
		elseif id_btn == "Btn_Apply" then 
			game._CFriendMan:DoApply(self._BlackListData[index + 1].RoleId)
		elseif id_btn == "Btn_Remove" then
			game._CFriendMan:DoOutBlackList(self._BlackListData[index + 1].RoleId)
		end
	end
end

def.method().Hide = function(self)
	self._ListBlack = nil
	self._LabNo = nil
	self._BlackListData = {}
	-- self._CurSelectIndex = 0
	-- self._CurSelectItem = nil 
	-- self._ItemList = nil 
end

def.method().Destroy = function (self)
	instance = nil 
end

CPageBlackList.Commit()
return CPageBlackList