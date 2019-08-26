local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local CElementData = require "Data.CElementData"
local CPageFriendList = Lplus.Class("CPageFriendList")
local def = CPageFriendList.define


-- def.field("userdata")._FrameFriends = nil 
def.field("userdata")._ListFriend = nil
def.field("userdata")._LabNo = nil
def.field("userdata")._LabFriendNum = nil 
def.field("table")._FriendListData = BlankTable 
def.field("number")._CurSelectIndex = 0
def.field("userdata")._CurSelectItem = nil 
def.field("table")._ItemList = nil 
def.field("table")._Parent = nil 

local instance = nil
def.static("=>", CPageFriendList).Instance = function()
	if instance == nil then
        instance = CPageFriendList()
	end
	return instance
end

local function sortfunction(item1,item2)
	if item1.IsOnLine and not item2.IsOnLine then
		return true
	elseif not item1.IsOnLine and item2.IsOnLine then 
		return false
	elseif item1.IsOnLine == item2.IsOnLine then 
		if item1.Amicability > item2.Amicability then 
			return true
		elseif item1.Amicability < item2.Amicability then 
			return false
		elseif item1.Amicability == item2.Amicability then 
			return false
		end
	end
end

--一天内显示XX小时XX分钟，一天外显示X天前 最小就1分钟
local function formatTime(time)
	local d = math.floor(time / 86400)
	local h = math.floor(time % 86400 / 3600)
	local m = math.floor(time % 3600 / 60)
	local timeText = ""
	if d > 0 then 
		timeText = string.format(StringTable.Get(601),d)..StringTable.Get(30343)
	elseif d == 0 then 
		if h == 0 then 
			timeText = string.format(StringTable.Get(603),m)..StringTable.Get(30343)
		else 
			if m == 0 then 
				m = 1 
			end
			timeText = string.format(StringTable.Get(602),h)..string.format(StringTable.Get(603),m)..StringTable.Get(30343)
		end
	end
	return timeText
end

def.method("table").Show = function(self, parent)
	self._Parent = parent  
	-- self._FrameFriends = self._Parent:GetUIObject("Frame_Friends")	
	self._ListFriend = self._Parent:GetUIObject("List_Friend")
	self._LabNo = self._Parent:GetUIObject("Lab_NoFriend")
	self._LabFriendNum = self._Parent:GetUIObject("Lab_FriendNum")	
	self._CurSelectIndex = 1
	self:UpdatePage()
end

def.method().UpdatePage = function(self)
	self._FriendListData = game._CFriendMan:GetFriendsWithoutBlack()
	GUI.SetText(self._LabFriendNum,string.format(StringTable.Get(30340),#self._FriendListData,game._CFriendMan._MaxFriend))
	if #self._FriendListData == 0 then 
		self._ListFriend:SetActive(false)
		self._LabNo:SetActive(true)
	return end
	self._ListFriend:SetActive(true)
	self._LabNo:SetActive(false)
	if #self._FriendListData > 1 then 
		table.sort(self._FriendListData, sortfunction)
	end
	self._ItemList = {}
	self._ListFriend:GetComponent(ClassType.GNewList):SetItemCount(#self._FriendListData)
end

def.method('userdata', 'string', 'number').InitItem = function(self, item, id, index)
	if id == "List_Friend" then 
		table.insert(self._ItemList,item)
		local data = self._FriendListData[index + 1] 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgD = uiTemplate:GetControl(0)
		local imgHead = uiTemplate:GetControl(1)
		local labName = uiTemplate:GetControl(2)
		local labProfession = uiTemplate:GetControl(3)
		local lablv = uiTemplate:GetControl(4)
		local labFight = uiTemplate:GetControl(5)
		local labIntimacy = uiTemplate:GetControl(6) 
		local labLocation = uiTemplate:GetControl(7)
		local labOfflineTime = uiTemplate:GetControl(8)
		local imgBg = uiTemplate:GetControl(9)
		local labFightTip = uiTemplate:GetControl(10)
		local labIntimacyTip = uiTemplate:GetControl(11)
		local imgLocation = uiTemplate:GetControl(12)
		local imgBorder = uiTemplate:GetControl(13)
		GUI.SetText(labName, data.Name)
        GUI.SetText(lablv, string.format(StringTable.Get(30327),data.Level))
        GUI.SetText(labIntimacy,tostring(data.Amicability))
        GUI.SetText(labFight,GUITools.FormatNumber(data.Fight))
        TeraFuncs.SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
        GameUtil.MakeImageGray(imgHead, not data.IsOnLine)
        GUI.SetText(labProfession,tostring(StringTable.Get(10300 + data.Profession - 1)))
        imgD:SetActive(false)
    	GameUtil.MakeImageGray(imgBg, not data.IsOnLine)
    	GameUtil.MakeImageGray(imgBorder, not data.IsOnLine)

        if not data.IsOnLine then 
        	labLocation:SetActive(false)
        	labOfflineTime:SetActive(true)
        	local time = (GameUtil.GetServerTime() - data.LogoutTime)/1000
        	imgLocation:SetActive(false)
        	GUI.SetText(labOfflineTime,formatTime(time))
        	GUI.SetAlpha(labName,128)
        	GUI.SetAlpha(labProfession,128)
        	GUI.SetAlpha(lablv,128)
        	GUI.SetAlpha(labFight,128)
        	GUI.SetAlpha(labIntimacy,128)
        	GUI.SetAlpha(labOfflineTime,128)
        	GUI.SetAlpha(labFightTip,128)
        	GUI.SetAlpha(labIntimacyTip,128)
        	GUI.SetAlpha(imgHead,128)
        else
        	labLocation:SetActive(true)
        	labOfflineTime:SetActive(false)
        	imgLocation:SetActive(true)
        	GUI.SetAlpha(labName,255)
        	GUI.SetAlpha(labProfession,255)
        	GUI.SetAlpha(lablv,255)
        	GUI.SetAlpha(labFight,255)
        	GUI.SetAlpha(labLocation,255)
        	GUI.SetAlpha(labIntimacy,255)
        	GUI.SetAlpha(labFightTip,255)
        	GUI.SetAlpha(labIntimacyTip,255)
        	GUI.SetAlpha(imgHead,255)
        	local mapTemp = CElementData.GetMapTemplate(data.MapInfo.mapTemplateId)
        	if mapTemp == nil then warn("Map Template tid is nil ",data.MapInfo.mapTemplateId) return end 
        	local mapname = mapTemp.TextDisplayName
        	if data.MapInfo.LineId == 0 then 
        		GUI.SetText(labLocation, mapname)
        	elseif data.MapInfo.LineId > 0 then 
        		GUI.SetText(labLocation,string.format(StringTable.Get(30341), mapname,data.MapInfo.LineId))
        	end
        end
     	if self._CurSelectIndex == index + 1 then 
     		self._CurSelectItem = item
     		imgD:SetActive(true)
     	end
	end
end

def.method('userdata', 'string', 'number').SelectItem = function(self, item, id, index)
	if id == "List_Friend" then 
		if self._CurSelectIndex ~= index + 1 and not IsNil(self._CurSelectItem) then 
			self._CurSelectItem:FindChild("Img_D"):SetActive(false)
		end
		item:FindChild("Img_D"):SetActive(true)
		self._CurSelectIndex = index + 1
		self._CurSelectItem = item
	end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if id == "List_Friend" and id_btn == "Btn_Function" then 
		if self._CurSelectIndex ~= index + 1 and not IsNil(self._CurSelectItem) then 
			self._CurSelectItem:FindChild("Img_D"):SetActive(false)
		end
		self._CurSelectIndex = index + 1
		self._CurSelectItem = self._ItemList[index + 1]
		self._CurSelectItem:FindChild("Img_D"):SetActive(true)
		local PBUtil = require "PB.PBUtil"
		PBUtil.RequestOtherPlayerInfo(self._FriendListData[index + 1].RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Friend)
	end
end

def.method().Hide = function(self)
	self._FriendListData = {} 
	self._ListFriend = nil
	self._LabNo = nil
	self._LabFriendNum = nil 
	self._CurSelectIndex = 0
	self._CurSelectItem = nil
	self._ItemList = nil 
end

def.method().Destroy = function (self)
	instance = nil 
end

CPageFriendList.Commit()
return CPageFriendList