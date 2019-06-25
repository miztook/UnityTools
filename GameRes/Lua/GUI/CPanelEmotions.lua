local Lplus = require "Lplus"
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelEmotions = Lplus.Extend(CPanelBase, 'CPanelEmotions')
local def = CPanelEmotions.define

def.field("userdata")._FrameEmotions = nil 
def.field("userdata")._FrameItems = nil 
def.field("userdata")._ListEmotion = nil 
def.field("userdata")._ListItem = nil 
def.field("userdata")._InputChat = nil 
def.field("userdata")._FramePosition = nil 
def.field("userdata")._PositionObj = nil 
def.field("boolean")._IsSendItemLink = false
def.field("table")._CurSelectItem = nil
def.field("table")._ListItemData = nil 
def.field("userdata")._RdoEmotion = nil 
def.field("userdata")._RdoItem = nil 

def.field("userdata")._Rdo_Position = nil 
def.field("userdata")._Frame_MapPos = nil 
def.field("userdata")._Lab_Position = nil 
def.field("boolean")._IsSendPosLink = false
def.field("table")._ConsumableTypes = BlankTable
def.field("number")._ProfMask = 0


local instance = nil
def.static("=>", CPanelEmotions).Instance = function() 
	if not instance then
		instance = CPanelEmotions()
		instance._PrefabPath = PATH.UI_Emotion
		instance._PanelCloseType = EnumDef.PanelCloseType.Tip
		instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

-- 初始化面板位置  
local function InitPanelPosition(self)
	self._FramePosition.localPosition = self._PositionObj.localPosition
end

local function sortfunction(item1, item2)
	if item1._Tid == 0 then
		return false
	end
	if item2._Tid == 0 then
		return true
	end

	local profMask = instance._ProfMask

	if item1._ProfessionMask == profMask and item2._ProfessionMask == profMask then
		if item1._SortId == item2._SortId then
			return item1._Slot < item2._Slot
		else
			return item1._SortId > item2._SortId
		end
	elseif item1._ProfessionMask == profMask then
		return false
	elseif item2._ProfessionMask == profMask then
		return true
	else
		if item1._SortId == item2._SortId then
			return item1._Slot < item2._Slot
		else
			return item1._SortId > item2._SortId
		end
	end
end

local function IsConsumableType(self,itemType)
	for _,typeValue in ipairs(self._ConsumableTypes) do 
		if typeValue == itemType then 
			return true
		end
	end
	return false
end

--得到分类后的物品集合
local function GetItemSets(self,tempitemSets)
	local itemSets = {}
	itemSets[EnumDef.EBagItemType.Weapon] = {}
	itemSets[EnumDef.EBagItemType.Armor] = {}
	itemSets[EnumDef.EBagItemType.Accessory] = {}
	itemSets[EnumDef.EBagItemType.Charm] = {}
	itemSets[EnumDef.EBagItemType.Consumables] = {}
	itemSets[EnumDef.EBagItemType.Else] = {}

	for i,item in ipairs(tempitemSets) do
		if item._Tid ~= 0 then
			if item:IsEquip() and item:GetCategory() == EnumDef.ItemCategory.Weapon then
				table.insert(itemSets[EnumDef.EBagItemType.Weapon], item)
			end 
			if item:IsEquip() and item:GetCategory() == EnumDef.ItemCategory.Armor then
				table.insert(itemSets[EnumDef.EBagItemType.Armor], item)
			end 
			if item:IsEquip() and item:GetCategory() == EnumDef.ItemCategory.Jewelry then
				table.insert(itemSets[EnumDef.EBagItemType.Accessory], item)
			end
			if item:IsCharm() then
				table.insert(itemSets[EnumDef.EBagItemType.Charm], item)
			end 
			if IsConsumableType(self,item._ItemType) then 
				table.insert(itemSets[EnumDef.EBagItemType.Consumables], item)
			end
			if not item:IsEquip() and not IsConsumableType(self,item._ItemType) and not item:IsCharm() then
				table.insert(itemSets[EnumDef.EBagItemType.Else], item)
			end  
		end
	end
	for i,v in ipairs(itemSets) do 
		if #v > 2 then 
			table.sort(v , sortfunction)
		end
	end
	return itemSets
end


def.override().OnCreate = function(self)
	self._FrameEmotions = self:GetUIObject("ScrollView_Emotion")
	self._FrameItems = self:GetUIObject("ScrollView_Item")
	self._ListEmotion = self:GetUIObject("List_Emotion"):GetComponent(ClassType.GNewListLoop)
	self._ListItem = self:GetUIObject("List_Item"):GetComponent(ClassType.GNewListLoop)
	self._FramePosition = self:GetUIObject("Frame_Position")
	self._RdoEmotion = self:GetUIObject("Rdo_Emotion")
	self._RdoItem = self:GetUIObject("Rdo_Item")
	self._Rdo_Position = self:GetUIObject("Rdo_Position")
	self._Frame_MapPos = self:GetUIObject("Frame_MapPos")
	self._Lab_Position = self:GetUIObject("Lab_Position")
end

--传过来输入框的Input 和位置Obj
def.override("dynamic").OnData = function(self, data)
	if data == nil then return end
	self._IsSendItemLink = false
	self._InputChat = data.InputChat
	self._PositionObj = data.PositionObj
	self._CurSelectItem = nil 
	self._ListItemData = nil 
	self._IsSendPosLink = false
	local types = string.split(CSpecialIdMan.Get("ConsumableTypesId"),"*")
	for _,v in ipairs(types) do
		table.insert(self._ConsumableTypes,tonumber(v))
	end
	InitPanelPosition(self)

	self._FrameEmotions:SetActive(true)
	self._FrameItems:SetActive(false)
	self._Frame_MapPos:SetActive(false)
	self._RdoItem:FindChild("Img_D"):SetActive(false)
	self._RdoEmotion:FindChild("Img_D"):SetActive(true)
	self._RdoItem:GetComponent(ClassType.Toggle).isOn = false
	self._RdoEmotion:GetComponent(ClassType.Toggle).isOn = true
	self._ListEmotion:SetItemCount(GameUtil.GetEmojiCount())
	self._ListEmotion:ScrollToStep(0)
end



def.override("string", "boolean").OnToggle = function(self, id, checked)
	if id == "Rdo_Item" then 
		self._IsSendPosLink = false
		self._FrameItems:SetActive(true)
		self._FrameEmotions:SetActive(false)
		if self._ListItemData == nil or table.nums(self._ListItemData) == 0 then 
			self._ListItemData = {}
			if game._HostPlayer._Package._EquipPack._ItemSet ~= nil then 
				for i = 1 ,#game._HostPlayer._Package._EquipPack._ItemSet do
					if game._HostPlayer._Package._EquipPack._ItemSet[i]._Tid > 0 then	
						self._ListItemData[#self._ListItemData + 1] = game._HostPlayer._Package._EquipPack._ItemSet[i]
					end
				end
			end
			if game._HostPlayer._Package._NormalPack._ItemSet ~= nil then 
				local itemSets = GetItemSets(self,game._HostPlayer._Package._NormalPack._ItemSet)
				for _,items in ipairs(itemSets) do
					if items ~= nil and #items > 0 then 
						for i = 1,#items do
							self._ListItemData[#self._ListItemData + 1] = items[i]
						end
					end 
				end
			end
			if #self._ListItemData == 0 then return end
			self._ListItem:SetItemCount(#self._ListItemData)
		end
		self._ListItem:ScrollToStep(0)
		self._Frame_MapPos:SetActive(false)
	elseif id == "Rdo_Emotion" then  
		self._IsSendPosLink = false
		self._FrameItems:SetActive(false)
		self._FrameEmotions:SetActive(true)
		self._ListEmotion:ScrollToStep(0)
		self._Frame_MapPos:SetActive(false)
	elseif id == "Rdo_Position" then 
		if not game._HostPlayer:InWorld() then
			game._GUIMan:ShowTipText(StringTable.Get(13060), false)
			return
		end
		self._FrameItems:SetActive(false)
		self._FrameEmotions:SetActive(false)
		self._ListEmotion:ScrollToStep(0)
		self._Frame_MapPos:SetActive(true)
		self:OnInitHostPosition()		
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if id == "List_Emotion" then 
		local imgEmoji = GUITools.GetChild(item , 0)
        GameUtil.SetEmojiSprite(imgEmoji, index)
	elseif id == "List_Item" then 
		local itemData = self._ListItemData[index + 1]
		local frame_item_icon = GUITools.GetChild(item, 0)
		local bShowEquip = false
		local bShowArrowUp = false
		if itemData._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then
			bShowEquip = true
		else
			if itemData:IsEquip() then
				local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
				if profMask == bit.band(itemData._ProfessionMask, profMask) then
					for _, v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do
						if v._Tid ~= 0 then 
							if v._EquipSlot == itemData._EquipSlot then 
								local equipedFight = v:GetFightScore()
								local curFight = itemData:GetFightScore()
								if equipedFight < curFight then
									bShowArrowUp = true
								end
							end
						end
					end
				end
			end
		end
		local setting =
		{
			[EItemIconTag.Bind] = itemData:IsBind(),
			[EItemIconTag.Number] = itemData:GetCount(),
			[EItemIconTag.New] = itemData._IsNewGot,
			[EItemIconTag.Equip] = bShowEquip,
			[EItemIconTag.ArrowUp] = bShowArrowUp,
		}
		IconTools.InitItemIconNew(frame_item_icon, itemData._Tid, setting)
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if id == "List_Emotion" then 
        GameUtil.InputEmoji(self._InputChat, index)
	elseif id == "List_Item" then 
		self._CurSelectItem = self._ListItemData[index + 1]
		if self._CurSelectItem == nil then return end
		self._IsSendItemLink = true
		local strText = self._InputChat.text
		local name = self._CurSelectItem._Name 
		if string.find(strText,"<") == nil then
        	strText = strText.."<"..name..">"
    	else 
    		-- replace     
        	strText = string.gsub(strText, "%b<>", "<"..name..">" )
    	end
    	self._InputChat.text = strText
	end 
end

-- 显示角色当前所在地图和位置
def.method().OnInitHostPosition = function(self)
	self._IsSendPosLink = true
	local HostPlayerPosX, HostPlayerPosZ = game._HostPlayer:GetPosXZ() -- 无内存分配的getPosition
	local strText = self._InputChat.text
	GUI.SetText(self._Lab_Position , self:GetShowName().. "(" .. math.ceil(HostPlayerPosX).. "," .. math.ceil(HostPlayerPosZ) ..")")
	

	local NameAndPos = self:GetShowName().. "(" .. math.ceil(HostPlayerPosX).. "," .. math.ceil(HostPlayerPosZ) ..")"
	if string.find(strText,"<") == nil then
		strText = strText .. "<" ..  NameAndPos ..">"
	else 
		-- replace     
		strText = string.gsub(strText, "%b<>", "<"..NameAndPos..">" )
	end
	self._InputChat.text = strText
end

def.method("=>", "string").GetShowName = function(self)
	local MapBasicConfig = require "Data.MapBasicConfig"
	local CurSceneTemplate = MapBasicConfig.GetMapBasicConfigBySceneID(game._CurWorld._WorldInfo.SceneTid)
	if CurSceneTemplate ~= nil then
		local regionIds = game._HostPlayer._CurrentRegionIds
		local regionCount = #regionIds
		local showName = CurSceneTemplate.TextDisplayName
		local regions = CurSceneTemplate.Region

		--倒叙查找最后一个进入的有名字的区域
		for i = 1, regionCount do
			for j, w in ipairs(regions) do
				for k, x in pairs(w) do
					if k == regionIds[regionCount-i+1] then
						if x.isShowName ~= nil and x.isShowName and x.name ~= ""  then
							return x.name
						end
					end
				end
			end
		end
		return showName
	end
end

-- 发送信息必调用 检查返回数据
def.method("=>","dynamic").IsSendItemLink = function(self)
	return self._CurSelectItem
end

def.method("=>","boolean").IsSendPositionLink = function(self)
	return self._IsSendPosLink
end

def.override().OnHide = function(self)
	self._InputChat = nil 
	self._PositionObj = nil
end

def.override().OnDestroy = function(self)
	self._InputChat = nil 
	self._PositionObj = nil  
	self._ListItemData = nil 
	self._CurSelectItem = nil 
	instance = nil 
end

CPanelEmotions.Commit()
return CPanelEmotions