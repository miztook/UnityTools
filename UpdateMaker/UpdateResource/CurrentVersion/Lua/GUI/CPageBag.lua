local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local EResourceType = require "PB.data".EResourceType
local bit = require "bit"
local CElementData = require "Data.CElementData"
local CUIModel = require "GUI.CUIModel"
local CPanelDecomposeFilter = require "GUI.CPanelDecomposeFilter"
local PBHelper = require "Network.PBHelper"
local net = require "PB.net"
local EDestType = require "PB.Template".ItemMachining.EDestType
local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
local EItemType = require "PB.Template".Item.EItemType
local CPanelBagSort = require "GUI.CPanelBagSort"
-- 以下为监听的Event事件
local UseItemEvent = require "Events.UseItemEvent"
local CloseTipsEvent = require "Events.CloseTipsEvent"
local CMallUtility = require "Mall.CMallUtility"


local CPageBag = Lplus.Class("CPageBag")
local def = CPageBag.define

def.field("userdata")._Panel = nil
def.field("userdata")._CurrentSelectedItem = nil
def.field("userdata")._LabDrop = nil 
def.field("table")._Parent = BlankTable
def.field("table")._PanelObject = BlankTable
def.field("function")._CurTabRefreshFunc = nil 
def.field("number")._CurRdoType = 0
def.field("table")._ItemSet = nil -- 当前显示的item集合,index从1开始
def.field("number")._ProfMask = 0
def.field("boolean")._IsOpenStorage = false
def.field("table")._StorageItemSet = BlankTable
def.field("number")._CurStoragePage = 0
def.field("number")._UnlockPage = 0 
def.field("table")._UnLockPrice = BlankTable
def.field("boolean")._IsUnlockSolt = false
def.field("number")._PreSoltNumber = 0
def.field("number")._EffectTimerId = 0
def.field("number")._CurSortType = 0
def.field("boolean")._IsDescending = false       -- 是否为降序
def.field("table")._ItemObjList = nil 
def.field("table")._DecomposeItemObjList = BlankTable 
def.field("table")._ConsumableTypes = BlankTable        -- 消耗品类型组

-- 分解
def.field("boolean")._IsOpenDecompose = false
def.field("table")._ChooseDecomItems  = BlankTable
def.field("table")._GetItemsByDecom = BlankTable
def.field("table")._CurSelectParts = BlankTable
def.field("table")._CurSelectQualitys = BlankTable 
def.field("boolean")._IsSelectAll = false
def.field("boolean")._IsSelectAllQualitys = false
def.field("boolean")._IsSelectAllParts = false
def.field("boolean")._IsDecomposeTimer = false
def.field("number")._TimerID = 0
def.field("boolean")._IsShowDecomposeFx = false
def.field("table")._BagCouponData = nil

local instance = nil
def.static("=>", CPageBag).Instance = function()
	if instance == nil then
        instance = CPageBag()
	end
	return instance
end

-------------------------------------------事件监听-----------------------------------

local OnUseItemEvent = function(sender, event)
 	if instance ~= nil then
		instance:UpdateBagItem(event)
 	end
end   

local OnCloseTipsEvent = function(sender, event)
	if instance ~= nil and instance._Panel ~= nil then
		instance:CleanBorder()
		instance ._CurrentSelectedItem = nil 
 	end	
end

--使用物品，纹章的响应
def.method("table").UpdateBagItem = function(self, event)
	local EItemType = require "PB.Template".Item.EItemType	--物品 结构类型
	if EItemType.Rune == event._ItemType then
		--是纹章 响应事件
		local runeItem = CElementData.GetTemplate("Item", event._ID)
		local EItemEventType = require "PB.data".EItemEventType	--物品使用 类型

		if EItemEventType.ItemEvent_Rune == runeItem.EventType1 then
			local runeId = runeItem.Type1Param1
			OperationTip.ShowRuneUseTip(runeId)

			local UserData = require "Data.UserData".Instance()
			--根据全服角色ID唯一
			local skillField = game._HostPlayer._ID .. EnumDef.LocalFields.Skill
			UserData:SetCfg(skillField, tostring(runeId), true)
			UserData:SaveDataToFile()
		end
	end
end
-------------------------------------事件监听end----------------------------------------------

local function IsConsumableType(self,itemType)
	for _,typeValue in ipairs(self._ConsumableTypes) do 
		if typeValue == itemType then 
			return true
		end
	end
	return false
end

local function IsAutoDecompose(self,itemType)
	local BanAutoDecomType = {}
	local types = string.split(CSpecialIdMan.Get("BanAutoDecomposeItemType"),"*")
	for _,v in ipairs(types) do
		table.insert(BanAutoDecomType,tonumber(v))
	end
	for _,typeValue in ipairs(BanAutoDecomType) do 
		if typeValue == itemType then 
			return false
		end
	end
	return true
end

local function InitCurRdoType(self,itemId)
	if itemId == 0 then 
		self._CurTabRefreshFunc = self.OnInitWeapon
		self._CurRdoType = EnumDef.EBagItemType.Weapon
	return end
	local temp = CElementData.GetItemTemplate(itemId)
	if temp.ItemType == EItemType.Equipment then 
		if temp.Slot == EEquipmentSlot.Weapon then 
			self._CurTabRefreshFunc = self.OnInitWeapon
			self._CurRdoType = EnumDef.EBagItemType.Weapon
			return 
		elseif temp.Slot == EEquipmentSlot.Helmet  or 
			   temp.Slot == EEquipmentSlot.Armor or 
			   temp.Slot == EEquipmentSlot.Leggings or
			   temp.Slot == EEquipmentSlot.Boots or
			   temp.Slot == EEquipmentSlot.Bracers then
			self._CurTabRefreshFunc = self.OnInitArmor
			self._CurRdoType = EnumDef.EBagItemType.Armor
			return
		else
			self._CurTabRefreshFunc = self.OnInitAccessory
			self._CurRdoType = EnumDef.EBagItemType.Accessory
			return
		end
	elseif temp.ItemType == EItemType.Charm then
		self._CurTabRefreshFunc = self.OnInitCharm
		self._CurRdoType = EnumDef.EBagItemType.Charm
		return 
	elseif IsConsumableType(self, temp.ItemType) then 
		self._CurTabRefreshFunc = self.OnInitConsumables
		self._CurRdoType = EnumDef.EBagItemType.Consumables
		return
	else
		self._CurTabRefreshFunc = self.OnInitElse
		self._CurRdoType = EnumDef.EBagItemType.Else
		return
	end  
end

local function InitDataAndPanel(self,IsOpenUIFromNpc,IsOpenDecompose,itemId)

	CGame.EventManager:addHandler(CloseTipsEvent, OnCloseTipsEvent)
	CGame.EventManager:addHandler(UseItemEvent, OnUseItemEvent)
	self._PanelObject._Frame_Decompose:SetActive(false)
	self._PanelObject._FrameBagBottom:SetActive(true)
	self._PanelObject._FrameDecBottom:SetActive(false)
	--初始化数据
	self._IsOpenStorage = IsOpenUIFromNpc 
	self._IsOpenDecompose = IsOpenDecompose
	local types = string.split(CSpecialIdMan.Get("ConsumableTypesId"),"*")
	for _,v in ipairs(types) do
		table.insert(self._ConsumableTypes,tonumber(v))
	end
	self._CurrentSelectedItem = nil
	self._IsShowDecomposeFx = false
	self._IsDescending = game._CDecomposeAndSortMan._IsDescending
	self._CurSortType = game._CDecomposeAndSortMan._CurSortType
	self._BagCouponData = {}
	local idList = string.split(CSpecialIdMan.Get("BackpackCouponId"),"*")
	for i,id in ipairs(idList) do 
		local data = {}
		data.ItemId = tonumber(id)
		local temp = CElementData.GetItemTemplate(data.ItemId)
		data.UnlockNum = tonumber(temp.Type1Param1)
		data.Name = temp.TextDisplayName
		data.Quality = temp.InitQuality
		data.Count = 0
		data.ApproachID = temp.ApproachID
		table.insert(self._BagCouponData,data)
	end

	InitCurRdoType(self,itemId)
	GUI.SetGroupToggleOn(self._PanelObject._FrameSideTabs,self._CurRdoType + 1)
	self:UpdateBag(nil,nil)
	self:InitStorage()
	if not self._IsOpenDecompose then return end
	self:OpenDecomposePanel()
end

local function GetSortValue(item1,item2)
	local value1 = 0 
	local value2 = 0 
	if instance._CurSortType == CPanelBagSort.BagSortType.Quality then 
		value1 = item1._Quality
		value2 = item2._Quality
	elseif instance._CurSortType == CPanelBagSort.BagSortType.InitLevel then 
		value1 = item1._Template.InitLevel
		value2 = item2._Template.InitLevel
	elseif instance._CurSortType == CPanelBagSort.BagSortType.CreateTimestamp then 
		value1 = item1._CreateTimestamp
		value2 = item2._CreateTimestamp
	elseif instance._CurSortType == CPanelBagSort.BagSortType.MinLevelLimit then 
		value1 = item1._Template.MinLevelLimit
		value2 = item2._Template.MinLevelLimit
	end
	return value1,value2
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

-- 升序(想要放在后面返回false)
local function sortfunctionAscending(item1,item2)
	if item1._Tid == 0 then
		return false
	end
	if item2._Tid == 0 then
		return true
	end
	local value1,value2 = GetSortValue(item1,item2)
	if value1 < value2 then 
		return true
	elseif value1 > value2 then 
		return false
	else
		local value = sortfunction(item1,item2)
		return value
	end
end

--降序
local function sortfunctionDescending(item1,item2)
	-- if item1 == nil or item2 == nil then return end
	if item1._Tid == 0 then
		return false
	end
	if item2._Tid == 0 then
		return true
	end
	local value1,value2 = GetSortValue(item1,item2)
	if value1 > value2 then 
		return true
	elseif value1 < value2 then 
		return false
	else
		local value = sortfunction(item1,item2)
		return value
	end	
end

local function GetDecomposeFilter(self)
	self._CurSelectParts = game._CDecomposeAndSortMan:GetPartFilterData()
    self._CurSelectQualitys = game._CDecomposeAndSortMan:GetQualityFilterData()
	self._IsSelectAllParts = game._CDecomposeAndSortMan._IsSelectAllParts
	self._IsSelectAllQualitys = game._CDecomposeAndSortMan._IsSelectAllQualitys
	self._IsSelectAll = false
	self._IsDecomposeTimer = game._CDecomposeAndSortMan:GetDecomposeTimerState()
	if self._IsSelectAllQualitys and self._IsSelectAllParts then 
		self._IsSelectAll = true
	end
end

local function CreateDecomposeFx(self)
	for i,item in ipairs(self._DecomposeItemObjList) do
    	if item ~= nil then
	   		local fxObjBg = item:FindChild("ItemIconNew/Frame_ItemIcon")
	    	GameUtil.PlayUISfxClipped(PATH.UIFx_DecompseBg, fxObjBg,fxObjBg,self._PanelObject._StroageMask)
	    end
	end
end

-- 红点规则是否有宝箱
local function UpdateRdoRed(self)
	if self._IsOpenDecompose then return end
	local isShowRed = false
    for i,item in ipairs(game._HostPlayer._Package._NormalPack._ItemSet) do 
        if item._ItemType == EItemType.TreasureBox then 
            isShowRed = true
            break 
        end  
    end
	local img_RedPoint = self._PanelObject._FrameSideTabs:FindChild("Rdo_5/Img_RedPoint")
	if img_RedPoint then 
		img_RedPoint:SetActive(isShowRed)
		self._PanelObject._RdoImgRedBag:SetActive(isShowRed)
	end
end

-- 分解隐藏红点
local function HideRed(self)
	local img_RedPoint = self._PanelObject._FrameSideTabs:FindChild("Rdo_5/Img_RedPoint")
	if img_RedPoint then 
		img_RedPoint:SetActive(false)
	end
end

local function UpdateBagItems(self)
	local itemData = self:SetNormalPackNewStateFromUserData()
	self._ItemSet = {}
	self._ItemSet = self:GetItemSets(itemData)
	UpdateRdoRed(self)
	for i,v in ipairs(self._ItemSet) do 
		GUI.SetText(self._PanelObject._FrameSideTabs:FindChild("Rdo_"..i.."/Label_"..i),string.format(StringTable.Get(21516),#v))
	end
	if #self._ItemSet[self._CurRdoType] == 0 then 
		self._PanelObject._LabNoItem:SetActive(true)
	else
		self._PanelObject._LabNoItem:SetActive(false)
	end
	self._ItemObjList = {}
	self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._ItemSet[self._CurRdoType])
	self:CleanBorder()
end

def.method("table", "table","userdata","boolean","boolean","number").Show = function(self, parent,linkInfo, root, IsOpenUIFromNpc,IsOpenDecompose,itemId)
	self._Parent = parent
	self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
    InitDataAndPanel(self,IsOpenUIFromNpc,IsOpenDecompose,itemId)
    GetDecomposeFilter(self)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Bag, 0)
end

def.method("dynamic","dynamic").UpdateBag = function(self,bagType,decomposedSlots)
	if self._Panel == nil then return end
	self:UpdateUnlockCell()

	if bagType ~= nil and bagType == net.BAGTYPE.STORAGEPACK then
		if self._IsOpenStorage then 
			self:UpdateStorage()
		end
	else
		if decomposedSlots == nil or #decomposedSlots == 0 then 
			if not self._IsShowDecomposeFx then 
				UpdateBagItems(self)
			return end
			if self._EffectTimerId > 0 then 
				_G.RemoveGlobalTimer(self._EffectTimerId)
				self._EffectTimerId = 0 
			end
			local function cb()
				UpdateBagItems(self)
				self._IsShowDecomposeFx = false
				_G.RemoveGlobalTimer(self._EffectTimerId)
				self._EffectTimerId = 0 
				self._DecomposeItemObjList = {}
                self._PanelObject._DecomposeListView:SetItemCount(#self._ChooseDecomItems)
			end
			self._EffectTimerId = _G.AddGlobalTimer(1.3,true,cb)
		else
			self._IsShowDecomposeFx = true
			CreateDecomposeFx(self)
		end
	end
end

-- 从本地获取背包中Item的“新”状态
def.method("=>","table").SetNormalPackNewStateFromUserData = function (self)
	local userdata = CRedDotMan.GetModuleDataToUserData("Bag")
	if userdata ~= nil then 
		local itemData = game._HostPlayer._Package._NormalPack._ItemSet
		for i,v in ipairs(itemData) do 
			for j,w in ipairs(userdata) do
				if w.Slot == v._Slot then 
					v._IsNewGot = w.IsNewGot 
					break
				end
			end
		end
		CRedDotMan.DeleteModuleDataToUserData("Bag")		
		return itemData
	end
	return game._HostPlayer._Package._NormalPack._ItemSet
end

def.method().UpdatePage = function(self)
	if #self._ItemSet[self._CurRdoType] == 0 then 
		self._PanelObject._LabNoItem:SetActive(true)
	else
		self._PanelObject._LabNoItem:SetActive(false)
	end
	self._ItemObjList = {}
	self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._ItemSet[self._CurRdoType])
	self:CleanBorder()
	
end

------------------------------------------------仓库-----------------------------------------

def.method().InitStorage = function(self)
	self._UnlockPage = game._HostPlayer._Package._StoragePack._EffectSize
	for i = 2,5 do
		local Rdo_Storage = self._PanelObject._RdoStorage:FindChild("Rdo_Storage"..i)
		if i > self._UnlockPage then 
			Rdo_Storage:FindChild("Img_U/Image"):SetActive(false)
		end
		if i <= self._UnlockPage then 
			local lock = self._PanelObject._RdoStorage:FindChild("Btn_Lock"..i)
			lock:SetActive(false)
		end
	end
	local priceStr = CElementData.GetTemplate("SpecialId", 326).Value
	self._UnLockPrice = string.split(priceStr, "*")
	local imgStroageIcon  = self._PanelObject._BtnStorage:FindChild("Img_Icon")
	GUITools.SetGroupImg(imgStroageIcon,0)
	local vipId = tonumber(CElementData.GetSpecialIdTemplate(651).Value)
	if game._HostPlayer:GetGloryLevel() < vipId then 
		GUITools.SetGroupImg(imgStroageIcon,1)
	end
	if not self._IsOpenStorage then 
		self._PanelObject._Frame_Storage:SetActive(false)
		self._PanelObject._FrameButtons:SetActive(true)
	else
		if game._HostPlayer:GetGloryLevel() < vipId then 
			local gloryemplate = CElementData.GetTemplate('GloryLevel', vipId)
			if gloryemplate == nil then  return end
			game._GUIMan:ShowTipText(string.format(StringTable.Get(22504),gloryemplate.Name),false)
			game._GUIMan:Close("CPanelRoleInfo")
		return end
		self:OpenStorage()
	end
end


def.method().OpenStorage = function (self)
	self._CurStoragePage = 1
	self._IsOpenStorage = true
	GUITools.SetGroupImg(self._PanelObject._ImgBg,1)
	self._PanelObject._FrameModel:SetActive(false)
	self._PanelObject._FrameRoleLeft:SetActive(false)
	self._PanelObject._FrameTopTabs:SetActive(false)
	self._PanelObject._FrameBagBottom:SetActive(false)
	GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21514))
	self._PanelObject._Frame_Storage:SetActive(true)
	GUI.SetGroupToggleOn(self._PanelObject._RdoStroToggle,self._CurStoragePage)
	self:UpdateStorage()
	self._PanelObject._FrameButtons:SetActive(false)
	-- body
end

-- 仓库Item分页数据处理
def.method().UpdateStorage = function(self)
	local storageList  = game._HostPlayer._Package._StoragePack._ItemSet
	self._StorageItemSet = {}
	if #storageList > 0 then 
		for i,data in ipairs(storageList) do
			local index = math.modf(data._Slot / 30) + 1
			if self._StorageItemSet[index] == nil then
				self._StorageItemSet[index] = {}
			end
			table.insert(self._StorageItemSet[index],data)
		end
	end
	for i = 1, self._UnlockPage do 
		if self._StorageItemSet[i] == nil  then 
			self._StorageItemSet[i] = {}
		elseif #self._StorageItemSet[i] >= 2 then 
			table.sort(self._StorageItemSet[i], sortfunction)
		end
	end
	self._PanelObject._StorageItemList:SetItemCount(30)	
end

--从外部直接打开仓库 切换到仓库未满页面(暂时弃用此功能)
def.method().CutStoragePage = function (self)
	self._StorageItemSet = game._HostPlayer._Package._StoragePack._ItemSet
	table.sort( self._StorageItemSet, sortfunction )
	if #self._StorageItemSet <= 30 then 
		self._CurStoragePage = 1
	elseif #self._StorageItemSet > 30 and #self._StorageItemSet <= 60 then 
		self._CurStoragePage = 2 
	elseif #self._StorageItemSet > 60 and #self._StorageItemSet <= 90 then 
		self._CurStoragePage = 3
	elseif #self._StorageItemSet >90 and #self._StorageItemSet <= 120 then 
		self._CurStoragePage = 4
	elseif #self._StorageItemSet > 120 and #self._StorageItemSet < 150 then 
		self._CurStoragePage = 5		
	end
	GUI.SetGroupToggleOn(self._PanelObject._RdoStroToggle,self._CurStoragePage)
	self._PanelObject._StorageItemList:SetItemCount(30)	
end

--S2C成功解锁背包仓库
def.method().UnlockStoragePage = function (self)
	game._GUIMan:ShowTipText(StringTable.Get(22502), false)
	self._UnlockPage = self._UnlockPage + 1
	game._HostPlayer._Package._StoragePack._EffectSize = self._UnlockPage
	local lock = self._PanelObject._RdoStorage:FindChild("Btn_Lock"..self._UnlockPage)
	if IsNil(lock) then return end
	lock:SetActive(false)
	local Rdo_Storage = self._PanelObject._RdoStorage:FindChild("Rdo_Storage"..self._UnlockPage)
	Rdo_Storage:FindChild("Img_U/Image"):SetActive(true)
	self._CurStoragePage = self._UnlockPage
	for i = 1,self._CurStoragePage do
		local toggleObj = self._PanelObject._RdoStorage:FindChild("Rdo_Storage"..i)
		if i ~= self._CurStoragePage then 
			toggleObj:GetComponent(ClassType.Toggle).isOn = false
			toggleObj:FindChild("Img_D"):SetActive(false)
		else
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Storage_Unlock, 0)
			GameUtil.PlayUISfx(PATH.UIFX_jiesuo,toggleObj,toggleObj,-1)
			toggleObj:GetComponent(ClassType.Toggle).isOn = true
			toggleObj:FindChild("Img_D"):SetActive(true)			
		end
	end
	-- 设置空格
	self._StorageItemSet[self._CurStoragePage] = {}
	self._PanelObject._StorageItemList:SetItemCount(30)	
end

-- S2C 解锁失败
def.method('number').FailStorageActive = function (self,errorCode)
	game._GUIMan:ShowErrorTipText(errorCode)
	-- body
end

--------------------------------------------初始化各种类型Item包方法--------------------------------------
--初始化物品显示(基础方法)
def.method("userdata","string", "number","table").OnInitNormalItem = function(self, item,id,index,itemSetData)
 -- 	local EquipmentProcess = item:FindChild("EquipmentProcess")
	-- EquipmentProcess:SetActive(false)
	local itemData = itemSetData[index + 1]
	local frame_item_icon = GUITools.GetChild(item, 0)
	if itemData == nil or itemData._Tid == 0 then
		local frame_setting =
		{
			[EFrameIconTag.Empty] = true,
			[EFrameIconTag.ItemIcon] = false,
			[EFrameIconTag.Check] = false,
			[EFrameIconTag.RedPoint] = false,
			[EFrameIconTag.Select] = false,
			[EFrameIconTag.Remove] = false,

		}
		IconTools.SetFrameIconTags(frame_item_icon, frame_setting)
		-- self:OnInitBlankCell(item)
	else
		local isShowRed = itemData._ItemType == EItemType.TreasureBox
		local frame_setting =
		{
			[EFrameIconTag.Empty] = false,
			[EFrameIconTag.ItemIcon] = true,
			[EFrameIconTag.Check] = false,
			[EFrameIconTag.RedPoint] = isShowRed,
			[EFrameIconTag.Select] = false,
			[EFrameIconTag.Remove] = false,
		}
		IconTools.SetFrameIconTags(frame_item_icon, frame_setting)
		-- self:ResetCell(item)
		self:ItemCDInfo(id, item, index)
		local number = itemData:GetCount()
		if id == "List_Item4" and itemData._DecomposeNum ~= 0 then 
			number = itemData._DecomposeNum
		end
		local count = game._CCountGroupMan:OnCurUseCount(itemData._Template.ItemUseCountGroupId)
		local isActivated = false
		if count > 0 then 
			isActivated = true
		end
		local icon_setting = {
		            [EItemIconTag.Bind] = itemData:IsBind(),
					[EItemIconTag.Number] = number,
					[EItemIconTag.New] = itemData._IsNewGot,
					[EItemIconTag.ArrowUp] = false,
					[EItemIconTag.Time] = itemData._SellCoolDownExpired ~= 0,
					[EItemIconTag.Grade] = -1,
					[EItemIconTag.Activated] = isActivated,
		        }
		IconTools.InitItemIconNew(frame_item_icon, itemData._Tid, icon_setting, EItemLimitCheck.AllCheck)
		-- IconTools.SetLimit(item, itemData._Tid, EItemLimitCheck.AllCheck)
		-- GUITools.SetItem(item, itemData._Template, itemData:GetCount(), nil, itemData:IsBind(), itemData._IsNewGot, itemData:CanUse())
	end
end
 
--初始化装备物品显示(基础方法)
def.method("userdata","string","number",'table').OnInitEquip = function(self, item, id,index,itemSetData)
	-- local uiTemplate = item:GetComponent(ClassType.UITemplate)
	
	-- local EquipmentProcess = item:FindChild("EquipmentProcess")
	local frame_item_icon = GUITools.GetChild(item, 0)
	if itemSetData[index + 1] == nil then
		local frame_setting =
		{
			[EFrameIconTag.Empty] = true,
			[EFrameIconTag.ItemIcon] = false,
			[EFrameIconTag.Check] = false,
			[EFrameIconTag.RedPoint] = false,
			[EFrameIconTag.Select] = false,
			[EFrameIconTag.Remove] = false,

		}
		IconTools.SetFrameIconTags(frame_item_icon, frame_setting)
		-- self:OnInitBlankCell(item)
		return		
	end

	local itemData = itemSetData[index + 1]
	if itemData == nil or itemData._Tid == 0  then
		local frame_setting =
		{
			[EFrameIconTag.Empty] = true,
			[EFrameIconTag.ItemIcon] = false,
			[EFrameIconTag.Check] = false,
			[EFrameIconTag.RedPoint] = false,
			[EFrameIconTag.Select] = false,
			[EFrameIconTag.Remove] = false,
			[EItemIconTag.Time] = false,
		}
		IconTools.SetFrameIconTags(frame_item_icon, frame_setting)
		-- self:OnInitBlankCell(item)
		return
	end
	local frame_setting =
	{
		[EFrameIconTag.Empty] = false,
		[EFrameIconTag.ItemIcon] = true,
		[EFrameIconTag.Check] = false,
		[EFrameIconTag.RedPoint] = false,
		[EFrameIconTag.Select] = false,
		[EFrameIconTag.Remove] = false,
	}
	IconTools.SetFrameIconTags(frame_item_icon, frame_setting)
	-- self:ResetCell(item)

	self:ItemCDInfo(id,item, index)
	local bShowArrowUp = true
	local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
	if profMask == bit.band(itemData._ProfessionMask, profMask) then
		for _, v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do
			if v._Tid ~= 0 then
				if v._EquipSlot == itemData._EquipSlot then
					local equipedFight = v:GetFightScore()
					local curFight = itemData:GetFightScore()
					if equipedFight >= curFight then
						bShowArrowUp = false
					end
					break
				end
			end

		end
	end
	local inforceLv = itemData:GetInforceLevel()
	local refineLv = itemData:GetRefineLevel()
	--warn(' itemData._SellCoolDownExpired ~= 0 ',itemData._SellCoolDownExpired ~= 0)
	local icon_setting = {
		            [EItemIconTag.Bind] = itemData:IsBind(),
					[EItemIconTag.Number] = itemData:GetCount(),
					[EItemIconTag.New] = itemData._IsNewGot,
					[EItemIconTag.StrengthLv] = inforceLv,
					[EItemIconTag.Refine] = refineLv,
					[EItemIconTag.ArrowUp] = bShowArrowUp,
					[EItemIconTag.Enchant] = itemData._EnchantAttr ~= nil and itemData._EnchantAttr.index ~= 0,
					[EItemIconTag.Time] = itemData._SellCoolDownExpired ~= 0,
					[EItemIconTag.Grade] = itemData._BaseAttrs.Star,
		        }
	IconTools.InitItemIconNew(frame_item_icon, itemData._Tid, icon_setting, EItemLimitCheck.AllCheck)
	-- IconTools.SetLimit(item, itemData._Tid, EItemLimitCheck.AllCheck)
	-- GUITools.SetEquipItemFightArrow(itemData,item)
end

-- 初始化"武器"标签页下的物品显示
def.method("userdata","string","number",'table').OnInitWeapon = function(self, item, id,index,itemSetData)
	self:OnInitEquip(item,id,index,itemSetData)
end

-- 初始化"防具"标签页下的物品显示
def.method("userdata","string","number",'table').OnInitArmor = function(self, item, id,index,itemSetData)
	self:OnInitEquip(item,id,index,itemSetData)
end

-- 初始化"饰品"标签页下的物品显示
def.method("userdata","string","number",'table').OnInitAccessory = function(self, item, id,index,itemSetData)
	self:OnInitEquip(item,id,index,itemSetData)
end

-- 初始化"神符"标签页下的物品显示
def.method("userdata", "string","number","table").OnInitCharm = function(self, item,id,index,itemSetData)
	self:OnInitNormalItem(item,id,index,itemSetData)
end

-- 初始化“纹章”标签页下的物品显示
def.method("userdata","string", "number",'table').OnInitRune = function(self, item,id,index,itemSetData)
	self:OnInitNormalItem(item,id,index,itemSetData)
end

-- 初始化“消耗品”标签页下的物品显示
def.method("userdata","string", "number",'table').OnInitConsumables = function(self, item,id,index,itemSetData)
	self:OnInitNormalItem(item,id,index,itemSetData)
end

--初始化“其他”标签页下的物品显示
def.method("userdata","string","number","table").OnInitElse = function(self, item,id,index,itemSetData)
	self:OnInitNormalItem(item,id,index,itemSetData)
end

-------------------------------------------------涉及格子Cell相关接口----------------------------
-- 空白格子
def.method("userdata").OnInitBlankCell = function(self, item)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	uiTemplate:GetControl(0):SetActive(true)
	uiTemplate:GetControl(1):SetActive(true)
	uiTemplate:GetControl(2):SetActive(false)
	uiTemplate:GetControl(3):SetActive(false)
	uiTemplate:GetControl(4):SetActive(false)
	uiTemplate:GetControl(5):SetActive(false)
	local EquipmentProcess = item:FindChild("EquipmentProcess")
	EquipmentProcess:SetActive(false)
	uiTemplate:GetControl(12):SetActive(false)
	uiTemplate:GetControl(10):SetActive(false)
	uiTemplate:GetControl(14):SetActive(false)
end	

-- 带锁的格子
def.method("userdata").OnInitlockCell = function(self, item)
	GUITools.GetChild(item , 1):SetActive(false)
	GUITools.GetChild(item , 3):SetActive(false)
	GUITools.GetChild(item , 4):SetActive(false)
	--item:FindChild('Image_Other'):SetActive(false)
	-- GUITools.GetChild(item , 6):SetActive(true)
	GUITools.GetChild(item , 5):SetActive(false)
	GUITools.GetChild(item , 0):SetActive(false)
	GUITools.GetChild(item , 7):SetActive(false)
	GUITools.GetChild(item , 2):SetActive(false)
	GUITools.GetChild(item , 8):SetActive(false)
	GUITools.GetChild(item , 12):SetActive(false)
	GUITools.GetChild(item , 10):SetActive(false)
    
end
 
-- 重置格子
def.method("userdata").ResetCell = function(self, item)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	uiTemplate:GetControl(0):SetActive(true)
	uiTemplate:GetControl(1):SetActive(true)
	uiTemplate:GetControl(2):SetActive(true)
	uiTemplate:GetControl(3):SetActive(true)
	uiTemplate:GetControl(4):SetActive(true)
	uiTemplate:GetControl(5):SetActive(true)
	local EquipmentProcess = item:FindChild("EquipmentProcess")
	EquipmentProcess:SetActive(true)
	uiTemplate:GetControl(12):SetActive(true)
	uiTemplate:GetControl(10):SetActive(true)
	uiTemplate:GetControl(14):SetActive(true)

end

def.method("string","userdata", "number").ItemCDInfo = function(self, id,item, index)
	if id ~= "List_Item1" then return end
	local hp = game._HostPlayer
	local CDHdl = hp._CDHdl

	-- local cd_image = item:FindChild("Img_Item_CoolDown") --Img_Item_CD
	-- local cd_time = item:FindChild("Lab_Item_CD")	--lab_Item_CD	
	local cd_image = GUITools.GetChild(item, 1) --Img_Item_CD
	local cd_time = GUITools.GetChild(item, 2)	--lab_Item_CD
	local pack = self._ItemSet[self._CurRdoType][index + 1]
	if pack ~= nil and pack._CooldownId > 0 then
		local cdid = pack._CooldownId			
		if not IsNil(cd_image) then
			if CDHdl:IsCoolingDown(cdid) then
				-- if not cd_image.activeSelf then					
				local elapsed, max = CDHdl:GetCurInfo(cdid)
				GameUtil.AddCooldownComponent(cd_image, elapsed, max, cd_time, function () end, false)
				-- end
			else
				cd_image:SetActive(false)
				if not IsNil(cd_time) then
					cd_time:GetComponent(ClassType.Text).text = ""
				end
			end
		end
	else
		cd_image:SetActive(false)
		cd_time:SetActive(false)
	end
end

--获取当前标签下，有多少个可用的格子
def.method("=>","number").GetUnlockCellNum = function(self)
	local count = 0
    count = game._HostPlayer._Package._NormalPack._EffectSize
    return count
end

--清除格子选中框
def.method().CleanBorder = function(self)
	if not IsNil(self._CurrentSelectedItem) then
    	-- self._CurrentSelectedItem:FindChild('Img_Select'):SetActive(false)
    	local frame_item_icon = GUITools.GetChild(self._CurrentSelectedItem, 0)
		IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Select] = false })
    end
end

-- 显示选中框
def.method("userdata").ShowBorder = function(self, item)
	if item ~= nil then
		local frame_item_icon = GUITools.GetChild(item, 0)
		IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Select] = true })
		-- local obj = item:FindChild("Img_Select")
		-- if not IsNil(obj) then
  --   		obj:SetActive(true)
  --   	else
  --   		warn("Can not get child at ", item.name)
  --   	end
    end
end

def.method('number').UnlockCell = function(self, index)
	local C2SItemUnlock = require "PB.net".C2SItemUnlock
	local protocol = C2SItemUnlock()
	local net = require "PB.net"
	-- protocol.BagType = net.BAGTYPE.BACKPACK
	protocol.Index = index
	PBHelper.Send(protocol)

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Add_BagCell, 0)
end

-- 播放解锁特效
def.method("string","number","userdata").PlayUnlockSlotFx = function (self,id,index,item)
	if not self._IsUnlockSolt then return end
	if id ~= "List_Item1" then return end
	if index + 1 > self._PreSoltNumber  then 
		local Img_Unlock = item:FindChild("Img_Unlock")
		if Img_Unlock ~= nil then 
			GameUtil.PlayUISfx(PATH.UIFx_SlotJiesuo,Img_Unlock,self._Panel,2)
		end
	end
	if index + 1 == game._HostPlayer._Package._NormalPack._EffectSize then 
		self._IsUnlockSolt = false
	end
end

------------------------------------------分解-------------------------------------------

--预览分解背包的堆叠处理
local function PileItem(self,item,nomalCount,probability,isTokenMoney)
	-- 货币
	if isTokenMoney then 
		local moneyId = item.ItemId or item.GainMoneyId
		local itemCount = (item.ItemCount or item.GainMoneyCount) * nomalCount
		for i,itemData in ipairs(self._GetItemsByDecom) do 
			-- 包里已经有
			if itemData.Tid == moneyId and probability >= 10000 and itemData.IsTokenMoney then 
				itemData.ItemCount = itemData.ItemCount + itemCount
			return end
		end
		local item = 
		{
			Tid = moneyId,
			ItemCount = itemCount,
			Probability = probability ,
			IsTokenMoney = true
		}
		table.insert(self._GetItemsByDecom,item)
	return end
	-- 物品 
	local itemId = item.ItemId or item.GainItemId
	local itemCount = (item.ItemCount or item.GainItemCount) * nomalCount
	local temp = CElementData.GetItemTemplate(itemId)
	if temp.PileLimit > 1 and #self._GetItemsByDecom > 0  and probability >= 10000 then 
		local isHaven = false
		for j,itemData in ipairs(self._GetItemsByDecom) do 
			-- 包里已经有 包里的概率也要大于10000
			if itemData.Tid == itemId and itemData.ItemCount < temp.PileLimit and itemData.Probability >= 10000 then
				isHaven = true
				itemData.ItemCount = itemData.ItemCount + itemCount
				if itemData.ItemCount > temp.PileLimit then 
					local count = itemData.ItemCount - temp.PileLimit
					itemData.ItemCount = temp.PileLimit
					local item = 
					{
						Tid = itemId,
						ItemCount = count,
						Probability = probability ,
						IsTokenMoney = false
					}
					table.insert(self._GetItemsByDecom,item)
				end
			end
		end
		if not isHaven then 
			local item = 
			{
				Tid = itemId,
				ItemCount = itemCount,
				Probability = probability,
				IsTokenMoney = false,
			}
			table.insert(self._GetItemsByDecom,item)
		end
	else
		-- 不可堆叠(概率小于10000) 或为空
		local item = 
		{
			Tid = itemId,
			ItemCount = itemCount,
			Probability = probability,
			IsTokenMoney = false,
		}
		table.insert(self._GetItemsByDecom,item)
	end
end

local function UpdateDecomposeBag(self)
	self._DecomposeItemObjList = {}
	self._PanelObject._DecomposeListView:SetItemCount(#self._ChooseDecomItems)
    -- local GetMoney = 0 
   	self._GetItemsByDecom = {}
    for i,itemData in ipairs(self._ChooseDecomItems) do 
    	-- 本身的分解id
    	local decomposeId = itemData._Template.DecomposeId
    	local decomposeTemp = CElementData.GetItemMachiningTemplate(decomposeId)
    	local count = itemData._NormalCount
    	if itemData._DecomposeNum > 0 then 
    		count = itemData._DecomposeNum
    	end
    	if decomposeTemp ~= nil then 
    		local items = decomposeTemp.DestItemData.DestItems
    		for i,v in ipairs(items) do 
    			if v.DestType == EDestType.Item then 
    				PileItem(self,v,count,v.Probability,false)
    			elseif v.DestType == EDestType.Money then
    				PileItem(self,v,count,v.Probability,true)
    			end
    		end
    	end
    	-- 如果是强化另加的分解
    	if itemData:IsEquip() and itemData._InforceLevel > 0 then 
    		local InforceDecomposeId = itemData._Template.InforceDecomposeID
    		local InforceDecomTemp = CElementData.GetInforceDecomposeApproach(InforceDecomposeId)
    		if InforceDecomTemp == nil and #InforceDecomTemp.InforceLevels == 0 then return end
			for i,data in ipairs(InforceDecomTemp.InforceLevels) do 
				if data.Level == itemData._InforceLevel then
					if data.GainMoneyCount > 0 and data.GainMoneyId > 0 then
						PileItem(self,data,itemData._NormalCount,10000,true)
					end
		    		local items = data.ItemDatas 
		    		for j,v in ipairs(items) do 
	    				PileItem(self,v,itemData._NormalCount,v.Weight,false)
	    			end
		    	end
		    end
    	end
    end
    self._PanelObject._ItemsByDecomList:SetItemCount(#self._GetItemsByDecom)
end

local function FilterPart(self,itemData)
	if #self._CurSelectParts == 0 then return end
	for i,v in ipairs(self._CurSelectParts) do
		if v == CPanelDecomposeFilter.FilterPart.Weapon then 
			if itemData:IsEquip() and itemData:GetCategory() == EnumDef.ItemCategory.Weapon and itemData._InforceLevel == 0 then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		elseif v == CPanelDecomposeFilter.FilterPart.Armor then 
			if itemData:IsEquip() and itemData:GetCategory() == EnumDef.ItemCategory.Armor and itemData._InforceLevel == 0 then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		elseif v == CPanelDecomposeFilter.FilterPart.Accessory then 
		
			if itemData:IsEquip() and itemData:GetCategory() == EnumDef.ItemCategory.Jewelry and itemData._InforceLevel == 0 then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		elseif v == CPanelDecomposeFilter.FilterPart.Charm then 
			if itemData:IsCharm() then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		elseif v == CPanelDecomposeFilter.FilterPart.Consumables then 
			if IsConsumableType(self,itemData._ItemType) and IsAutoDecompose(self,itemData._ItemType) then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		elseif v == CPanelDecomposeFilter.FilterPart.Else then 
			if IsAutoDecompose(self,itemData._ItemType) and not itemData:IsEquip() and not IsConsumableType(self,itemData._ItemType) and not itemData:IsCharm() then  
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		end
	end
end

local function FilterQuality(self,itemData)
	if #self._CurSelectQualitys == 0 then return end
	for i,v in ipairs(self._CurSelectQualitys) do
		if itemData._Quality == v - 1 then 
			if IsAutoDecompose(self,itemData._ItemType) and not itemData:IsEquip() or (itemData:IsEquip() and itemData._InforceLevel == 0)then 
				table.insert(self._ChooseDecomItems,itemData)
				break
			end
		end
	end
end

local function FilterDecomposeItems(self,itemList) 
	if #itemList == 0 then return end
	self._ChooseDecomItems = {}

	if self._IsSelectAll then 
		for i,v in ipairs(itemList) do
			if (not v:IsEquip() or (v:IsEquip() and v._InforceLevel == 0)) and IsAutoDecompose(self,v._ItemType) then
				table.insert(self._ChooseDecomItems,v)
			end
		end
		return
	end

	if self._IsSelectAllParts then 
		for i,itemData in ipairs(itemList) do 
			FilterQuality(self,itemData)
		end
		return
	end

	if self._IsSelectAllQualitys then
		for i,itemData in ipairs(itemList) do 
			FilterPart(self,itemData)
		end
		return
	end

	for i,itemData in ipairs(itemList) do 
		FilterPart(self,itemData)
	end

	local items = {}
	for i,data in ipairs(self._ChooseDecomItems) do 
		for j,filterQuality in ipairs(self._CurSelectQualitys) do 
			if data._Quality == filterQuality - 1 then 
				if (not data:IsEquip() or (data:IsEquip() and data._InforceLevel == 0)) and IsAutoDecompose(self,data._ItemType) then
					table.insert(items,data)
					break
				end
			end
		end
	end
	self._ChooseDecomItems = items
end

local function GetCanDecomposeItems(self)

	local itemList = {}
	if game._HostPlayer == nil or game._HostPlayer._Package._NormalPack._ItemSet == nil or table.nums(game._HostPlayer._Package._NormalPack._ItemSet) == 0 then return itemList end
	for i,v in ipairs(game._HostPlayer._Package._NormalPack._ItemSet)do
		if v:CanDecompose() then 
			table.insert(itemList,v)
		end
	end
	return itemList
end

-- 打开分解界面
def.method().OpenDecomposePanel = function(self)
	HideRed(self)
	self:RemoveDecomposeTimer()
	self._IsOpenDecompose = true
	self._IsOpenStorage = false
	self._GetItemsByDecom = {}
	self._ChooseDecomItems = {} 
	GUITools.SetGroupImg(self._PanelObject._ImgBg,1)
	self._PanelObject._FrameButtons:SetActive(false)
	self._PanelObject._Frame_Storage:SetActive(false)
	self._PanelObject._Frame_Decompose:SetActive(true)
	self._PanelObject._FrameBagBottom:SetActive(false)
	self._PanelObject._FrameDecBottom:SetActive(true)
	self._PanelObject._FrameModel:SetActive(false)
	self._PanelObject._FrameRoleLeft:SetActive(false)
	self._PanelObject._FrameTopTabs:SetActive(false)
	GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21515))
	local itemList = GetCanDecomposeItems(self)
	FilterDecomposeItems(self,itemList)
	UpdateDecomposeBag(self)
	GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21515))
	self:UpdateBag(nil,nil)
end

def.method("number","number","userdata").AddOrDeletChooseItemSets = function (self,slot,index,itemObj)
	local isAdd = true
    if #self._ChooseDecomItems > 0 then 
        for i = #self._ChooseDecomItems, 1, -1 do
        	local itemData = self._ChooseDecomItems[i]
            if itemData._Slot == slot then 
            	isAdd = false
                table.remove(self._ChooseDecomItems,i)
                break
            end
        end
    end
    -- 通过删除按钮删除选中
    if itemObj == nil then 
    	for i,v in ipairs(self._ItemSet[self._CurRdoType]) do
    		if slot == v._Slot then 
    			itemObj = self._ItemObjList[i]
    			break 
    		end
    	end	
    end
    if itemObj == nil then 
    	UpdateDecomposeBag(self)
    return end

    local frame_item_icon = GUITools.GetChild(itemObj, 0)
 --    local imgSelect = itemObj:FindChild("Img_Selected")
	-- local dt_selected = imgSelect:FindChild("Img_SelectedAnim")
    if not isAdd then
    	-- imgSelect:SetActive(false)
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
    	IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Check] = false })
    	UpdateDecomposeBag(self)
   	else 
		local itemData = self._ItemSet[self._CurRdoType][index + 1]

		if itemData._NormalCount == 1 then 
			-- imgSelect:SetActive(true)
			-- if not IsNil(dt_selected) then
		 --        dt_selected = dt_selected:GetComponent(ClassType.DOTweenPlayer)
		 --        dt_selected:Restart("1")
			-- end
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
    		IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Check] = true })
			itemData._DecomposeNum = itemData._NormalCount
    		table.insert(self._ChooseDecomItems,itemData)
			UpdateDecomposeBag(self)
		return end
    	local function okback(number) 
    		itemData._DecomposeNum = number
    		table.insert(self._ChooseDecomItems,itemData)
			-- imgSelect:SetActive(true)
			-- if not IsNil(dt_selected) then
		 --        dt_selected = dt_selected:GetComponent(ClassType.DOTweenPlayer)
		 --        dt_selected:Restart("1")
			-- end
			IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Check] = true })
			UpdateDecomposeBag(self)
    	end
        local text = RichTextTools.GetQualityText(itemData._Name,itemData._Quality)
        text = string.format(StringTable.Get(21517),text)
    	BuyOrSellItemMan.ShowCommonOperate(TradingType.DECOMPOSE,StringTable.Get(21515), text, 1, itemData._NormalCount,0, EResourceType.ResourceTypeBindDiamond , itemData._Tid, okback, nil)
   	end
end

-- 分解物品
def.method("table").C2SDecomposeItemsOperation = function(self,chooseDcomposeItems)
    if #self._ChooseDecomItems > 0 then 
        local C2SItemMachiningBatch = require "PB.net".C2SItemMachiningBatch
        local protocol = C2SItemMachiningBatch()
        local C2SItemStruct = require"PB.net".ItemMachiningBatchStruct
        for i,item in ipairs(chooseDcomposeItems) do
            local DecomposeItem = C2SItemStruct()
            DecomposeItem.Slot = item._Slot
            local count = item._DecomposeNum
            if item._DecomposeNum == 0 then 
            	DecomposeItem.Count = item._NormalCount
            elseif item._DecomposeNum > 0 then 
            	DecomposeItem.Count = item._DecomposeNum
            end
            table.insert(protocol.Machings,DecomposeItem)
        end
        PBHelper.Send(protocol)                                                                                                                                      
    end
end

-- S2C分解协议返回操作
def.method('number').S2CDecompose = function (self, ErrorCode)
    --warn("S2CDecompose" .. tostring(ErrorCode))
    if ErrorCode == 0 then 
        self._ChooseDecomItems = {}
        self._GetItemsByDecom = {}
        self._PanelObject._ItemsByDecomList:SetItemCount(#self._GetItemsByDecom)

        -- self._DecomposeItemObjList = {}
        -- self._PanelObject._DecomposeListView:SetItemCount(#self._ChooseDecomItems)
        self:UpdateBag(nil, nil)
        -- GUI.SetText(self._PanelObject._LabGetMoney,tostring(0))
        -- GUI.SetText(self._PanelObject._LabDecomposeNum,string.format(StringTable.Get(308),#self._ChooseDecomItems))
	else
		game._GUIMan:ShowErrorTipText(ErrorCode)		
    end
end

def.method().AddDecomposeTimer = function(self)
	self:RemoveDecomposeTimer()
	local startTime = 0 
	local function callback()
		startTime = startTime + 1
		if startTime >= 30 then 
			local itemList = GetCanDecomposeItems(self)
			GetDecomposeFilter(self)
			FilterDecomposeItems(self,itemList)
			startTime = 0 
			self:C2SDecomposeItemsOperation(self._ChooseDecomItems)
			self:AddDecomposeTimer()
		end
	end
	self._TimerID = _G.AddGlobalTimer(1,false,callback)
end

def.method().RemoveDecomposeTimer = function(self)
    if self._TimerID ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0 
    end
end
-------------------------------------------------外部接口--------------------------------------
def.method('userdata','string','number').InitItem = function(self, item, id, index)
    if id == 'List_Item1' then
    	table.insert(self._ItemObjList,item)
    	self._CurTabRefreshFunc(self, item,id,index,self._ItemSet[self._CurRdoType])
    	-- local uiTemplate = item:GetComponent(ClassType.UITemplate)
     --    local Btn_Selected = item:FindChild("Img_Selected")
    	-- Btn_Selected:SetActive(false)
    	local bShowCheck = false
        local itemData = self._ItemSet[self._CurRdoType][index + 1]
    	if not self._IsOpenDecompose then return end
    	if #self._ChooseDecomItems > 0 then 
			 for i,choseItem in ipairs(self._ChooseDecomItems) do
                if itemData._Slot == choseItem._Slot then 
                    -- Btn_Selected:SetActive(true)
                    bShowCheck = true
                end
            end
        end 
        local frame_item_icon = GUITools.GetChild(item, 0)
        IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Check] = bShowCheck })
    elseif id =='List_Item2' then
  		local curPagedata = self._StorageItemSet[self._CurStoragePage]
    	if curPagedata[index + 1] ~= nil and curPagedata[index + 1]:IsEquip() then
    		self:OnInitEquip(item,id,index,curPagedata)
    	else
    		self:OnInitNormalItem(item,id,index,curPagedata)
    	end
    elseif id == "List_Item4" then 
    	-- local uiTemplate = item:GetComponent(ClassType.UITemplate)
        table.insert(self._DecomposeItemObjList,item)
        local itemData = self._ChooseDecomItems[index + 1]
    	if not self._IsOpenDecompose then return end
    	if itemData:IsEquip() then 
    		self:OnInitEquip(item,id,index,self._ChooseDecomItems)
    	else
    		self:OnInitNormalItem(item,id,index,self._ChooseDecomItems)
    	end
    	local frame_item_icon = GUITools.GetChild(item, 0)
    	IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.Remove] = true })
    elseif id == "List_Item3" then 
    	-- local uiTemplate = item:GetComponent(ClassType.UITemplate)
    	local itemData = self._GetItemsByDecom[index + 1]
    	-- local labPer = uiTemplate:GetControl(4)
    	-- local labNum = uiTemplate:GetControl(3)
    	-- labPer:SetActive(false)

    	local frame_item_icon = GUITools.GetChild(item, 0)
		local number = itemData.ItemCount
		local bShowProb = false
		if itemData.Probability < 10000 then
			number = 0
			bShowProb = true
		end
    	if not itemData .IsTokenMoney then 
			local setting =
			{
				[EItemIconTag.Number] = number,
				[EItemIconTag.Probability] = bShowProb,
			}
			IconTools.InitItemIconNew(frame_item_icon, itemData.Tid, setting)

    		-- if itemData.Probability < 10000 then 
    		-- 	labPer:SetActive(true)
    		-- 	GUITools.SetItem(item,itemData.Tid,0)
    		-- else
    		-- 	GUITools.SetItem(item,itemData.Tid,itemData.ItemCount)
    		-- end	
    	else
    		IconTools.InitTokenMoneyIcon(frame_item_icon, itemData.Tid, number)
    		IconTools.SetTags(frame_item_icon, { [EItemIconTag.Probability] = bShowProb })
    		-- if itemData.Probability < 10000 then 
    		-- 	labPer:SetActive(true)
    		-- 	GUITools.SetTokenItem(item,itemData.Tid,0)
    		-- else
    		-- 	GUITools.SetTokenItem(item,itemData.Tid,itemData.ItemCount)
    		-- end
    	end
    end
end

-- toggle触发事件
def.method("string", "boolean").OnTogglePageBag = function(self, id, checked)
	-- print("OnToggle: " .. tostring(id) .. " : " .. tostring(checked))
	if string.find(id, "Rdo_1") and checked then
		if self._CurTabRefreshFunc ~= self.OnInitWeapon then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitWeapon
			self._CurRdoType = EnumDef.EBagItemType.Weapon
			self:UpdatePage()
		end
	elseif string.find(id, "Rdo_2") and checked then
		if self._CurTabRefreshFunc ~= self.OnInitArmor then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitArmor
			self._CurRdoType = EnumDef.EBagItemType.Armor
			self:UpdatePage()
		end
	elseif string.find(id, "Rdo_3") and checked then
		if self._CurTabRefreshFunc ~= self.OnInitAccessory then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitAccessory
			self._CurRdoType = EnumDef.EBagItemType.Accessory
			self:UpdatePage()
		end
	elseif string.find(id,"Rdo_4") and checked then
		if self._CurTabRefreshFunc ~= self.OnInitCharm then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitCharm
			self._CurRdoType = EnumDef.EBagItemType.Charm
			self:UpdatePage()
		end
	elseif string.find(id,"Rdo_5") and checked then
		if self._CurTabRefreshFunc ~= self.OnInitConsumables then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitConsumables
			self._CurRdoType = EnumDef.EBagItemType.Consumables
			self:UpdatePage()
		end
	elseif  string.find(id,"Rdo_6") and checked then 
		if self._CurTabRefreshFunc ~= self.OnInitElse then
			self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):ScrollToStep(0)
			self._CurTabRefreshFunc = self.OnInitElse
			self._CurRdoType = EnumDef.EBagItemType.Else
			self:UpdatePage()
		end
	elseif string.find(id,"Rdo_Storage") and checked then
		local page = tonumber(string.sub(id,-1))
		self._CurStoragePage = page 
		self._PanelObject._StorageItemList:SetItemCount(30)	
	end
end

-- 按钮点击事件(能从仓库转到分解，不能从分解到仓库)++++++++++++++++++++++++++++++
def.method("string").Click = function(self,id)
	if string.find(id, "Btn_Storage") then
		local vipId = tonumber(CElementData.GetSpecialIdTemplate(651).Value)
		if game._HostPlayer:GetGloryLevel() < vipId then 
			local gloryemplate = CElementData.GetTemplate('GloryLevel', vipId)
			if gloryemplate == nil then warn("GloryLevel id"..id.." Is nil ") return end
			game._GUIMan:ShowTipText(string.format(StringTable.Get(22504),gloryemplate.Name),false)
		return end
		if not self._IsOpenStorage then 
			self:RemoveDecomposeTimer()
			self:OpenStorage()
		end 
		-- self._Parent._HelpUrlType = HelpPageUrlType.Bag
	elseif id == "Btn_Decompose" then 
		self:OpenDecomposePanel()
	elseif id == "Btn_UnlockCell" then 
		-- 使用背包扩展券
		if game._HostPlayer._Package._NormalPack._EffectSize >= 100 then 
			game._GUIMan:ShowTipText(StringTable.Get(22505), false)
		return end
		local title, msg, closeType = StringTable.GetMsg(124)
		local content = ""
		local totalCount = 0
		local ApproachID = 0
		for i,data in ipairs(self._BagCouponData) do 
			data.Count = game._HostPlayer._Package._NormalPack:GetItemCount(data.ItemId)
			ApproachID =  tonumber(data.ApproachID)
			if data.Count > 0 then
				totalCount = totalCount + data.Count * data.UnlockNum
				content = content..string.format(StringTable.Get(315),data.Count,RichTextTools.GetQualityText(data.Name,data.Quality))
			end
		end
		if totalCount == 0 then 
			local approachItem = CElementData.GetItemApproach(ApproachID)
			if approachItem == nil then return end
			if not game._CFunctionMan:IsUnlockByFunTid(approachItem.FunID) then
		        -- game._GUIMan:ShowTipText(StringTable.Get(30108), false)
    			game._CGuideMan:OnShowTipByFunUnlockConditions(0, approachItem.FunID)
			return end
			game._AcheivementMan:DrumpToRightPanel(approachItem.Id,0)
		return end
		local function callback(value)
			if not value then return end
            local num = self:GetUnlockCellNum() + totalCount
			if num <= GlobalDefinition.MaxPackbackItemNum then
				self:UnlockCell(self:GetUnlockCellNum() + totalCount - 1)
			else
				game._GUIMan:ShowTipText(StringTable.Get(306), false)
			end
		end
		msg = string.format(msg,content,totalCount)
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    

		-- -- 弃用货币
		-- 	if self:GetUnlockCellNum() >= GlobalDefinition.MaxPackbackItemNum then  
		-- 		game._GUIMan:ShowTipText(StringTable.Get(306), false)
		-- 		return
		-- 	end

		-- 	local function okback(count)
	 --            local num = self:GetUnlockCellNum() + count
		-- 		if num <= GlobalDefinition.MaxPackbackItemNum then
		-- 			self:UnlockCell(self:GetUnlockCellNum() + count - 1)
		-- 		else
		-- 			game._GUIMan:ShowTipText(StringTable.Get(306), false)
		-- 		end
		-- 	end
	 --        local function failback(count)
	 --            local callback = function(val)
	 --                if val then
		-- 		        self:UnlockCell(self:GetUnlockCellNum() + count - 1)
	 --                end
	 --            end
	 --            local limit = {
	 --                [EQuickBuyLimit.BagMaxSlotCount] = GlobalDefinition.MaxPackbackItemNum,
	 --                [EQuickBuyLimit.BagBuyCount] = count,
	 --            }
	 --            MsgBox.ShowQuickBuyBox(EResourceType.ResourceTypeBindDiamond, CMallUtility.GetBagBuyCellTotalPrice(count), callback, limit)
	 --        end
		-- 	local maxValue = GlobalDefinition.MaxPackbackItemNum - self:GetUnlockCellNum()
		-- 	BuyOrSellItemMan.ShowCommonOperate(TradingType.BagBuyCell,StringTable.Get(11115), StringTable.Get(305), 1, maxValue,0, EResourceType.ResourceTypeBindDiamond , nil, okback, failback)
	elseif id == "Btn_DecomposeOperation" then 
		local isHaveUncommon = false
		local UncommonItems = {}
		local chooseDcomposeItems = {}
		for i,item in ipairs(self._ChooseDecomItems) do 
			if item._Quality > 2 then 
				table.insert(UncommonItems,item)
				isHaveUncommon = true
			elseif item:IsEquip() and item._InforceLevel > 0 then 
				table.insert(UncommonItems,item)
				isHaveUncommon = true
			else
				table.insert(chooseDcomposeItems,item)
			end
		end
		if isHaveUncommon then 
			local function callback(value)
				if not value then return end
				for k,j in ipairs(UncommonItems) do 
					table.insert(chooseDcomposeItems,j)
				end
				self:C2SDecomposeItemsOperation(chooseDcomposeItems)
			end
			local title, msg, closeType = StringTable.GetMsg(12)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
		else
			self:C2SDecomposeItemsOperation(chooseDcomposeItems)
		end
	elseif id == "Btn_Sort" then 
		game._GUIMan:Open("CPanelBagSort",CPanelBagSort.PanelType.BagSort)
	elseif id == "Btn_Filter" then 
		self:RemoveDecomposeTimer()
		game._GUIMan:Open("CPanelDecomposeFilter",nil)
	elseif string.sub(id,1,8) == "Btn_Lock" then 
		local sum = tonumber(self._UnLockPrice[self._UnlockPage])
		local callback = function(val)
			if val then
				local C2SStoragePackUnlock = require "PB.net".C2SStoragePackUnlockReq
				local protocol = C2SStoragePackUnlock()
				PBHelper.Send(protocol)
			end
		end
		
		local moneyId = CSpecialIdMan.Get("StorageMoneyType")
		if sum > game._HostPlayer:GetMoneyCountByType( moneyId ) then 
            MsgBox.ShowQuickBuyBox(moneyId, sum, callback)
        return end	
		local title, msg, closeType = StringTable.GetMsg(1)
        local setting = {
            [MsgBoxAddParam.CostMoneyID] = moneyId,
            [MsgBoxAddParam.CostMoneyCount] = sum,
        }
	    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Normal, setting) 		
	elseif id =="Btn_Back" then
		self._PanelObject._FrameButtons:SetActive(true)
		self._Parent._HelpUrlType = HelpPageUrlType.Bag
		GUITools.SetGroupImg(self._PanelObject._ImgBg,0)
		self._PanelObject._FrameModel:SetActive(true)
		self._PanelObject._FrameTopTabs:SetActive(true)
		self._PanelObject._FrameRoleLeft:SetActive(true)
		if self._IsOpenStorage then 
			if self._IsDecomposeTimer then 
				self:AddDecomposeTimer()
			end	
			self._IsOpenStorage = false
			self._PanelObject._Frame_Storage:SetActive(false)
			self._PanelObject._FrameBagBottom:SetActive(true)
			GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21512))
		elseif self._IsOpenDecompose then 
			UpdateRdoRed(self)
			GUI.SetText(self._PanelObject._LabTitle,StringTable.Get(21512))
			self._PanelObject._FrameTopTabs:SetActive(true)
			self._IsOpenDecompose = false
			self._GetItemsByDecom = {}
			self._ChooseDecomItems = {}
			self._PanelObject._Frame_Decompose:SetActive(false)
			self._PanelObject._FrameBagBottom:SetActive(true)
			self._PanelObject._FrameDecBottom:SetActive(false)
			self:UpdateBag(nil,nil)
			if self._IsDecomposeTimer then 
				self:AddDecomposeTimer()
			end
		elseif not self._IsOpenDecompose and not self._IsOpenStorage then 
        	game._GUIMan:Close("CPanelRoleInfo")
		end
	end
end

def.method('userdata','string','number').SelectItem = function(self, item, id, index)
    --print("OnSelectItem index: " .. tostring(index) .. ' ' .. math.floor(index/5) .. ' itemName =' .. item.name)
    if self._IsShowDecomposeFx then return end
    if id == 'List_Item1' then
		local itemData = self._ItemSet[self._CurRdoType][index + 1]
		if itemData == nil or itemData._Tid == 0  then
			return
		end
		local frame_item_icon = GUITools.GetChild(item, 0)
		if not self._IsOpenStorage and not self._IsOpenDecompose then  
			-- 弹tip
			MsgBox.ClearAllBoxes()
			CItemTipMan.CloseCurrentTips()
			if itemData:IsEquip() then 
				itemData:ShowTipWithFuncBtns(TipsPopFrom.BACK_PACK_PANEL,TipPosition.DEFAULT_POSITION,self._PanelObject._BagEquipTipsPosition,item)
			else
				itemData:ShowTipWithFuncBtns(TipsPopFrom.BACK_PACK_PANEL,TipPosition.DEFAULT_POSITION,self._PanelObject._BagItemTipsPosition,item)
			end
			if itemData._IsNewGot then 
				itemData._IsNewGot = false
				IconTools.SetTags(frame_item_icon, { [EItemIconTag.New] = false })
				-- local setting = {
		  --           [EItemIconTag.Bind] = itemData:IsBind(),
				-- 	[EItemIconTag.Number] = itemData:GetCount(),
				-- 	[EItemIconTag.New] = itemData._IsNewGot,
		  --       }
				-- IconTools.InitItemIcon(item, itemData._Tid, setting)
				-- IconTools.SetLimit(item, itemData._Tid, EItemLimitCheck.AllCheck)
				-- GUITools.SetItem(item, itemData._Template, itemData:GetCount(),0, itemData:IsBind(), itemData._IsNewGot, itemData:CanUse())
			end
			self:CleanBorder()
	    	self._CurrentSelectedItem = item
	    	self:ShowBorder(item)
	    elseif self._IsOpenStorage and not self._IsOpenDecompose then 
	    	-- 仓库打开之后点击Item进行存储操作
			itemData = self._ItemSet[self._CurRdoType][index + 1]
			local StoragePackChange = require "PB.net".C2SStoragePackChangeReq
			local protocol = StoragePackChange()
			protocol.ChangeType = net.StoragePackChangeType.Type_Load
			protocol.PageNum = self._CurStoragePage
			protocol.Index = itemData._Slot
			PBHelper.Send(protocol)		
		elseif not self._IsOpenStorage and self._IsOpenDecompose then 
		-- 分解界面(选中或是删选)
			self:AddOrDeletChooseItemSets(itemData._Slot,index,item)
			self:CleanBorder()
	    	self._CurrentSelectedItem = item
	    	self:ShowBorder(item)
	    end
    elseif id == 'List_Item2' then 
    	if self._IsOpenStorage then 
    		local itemData = nil  
    		--取
			itemData = self._StorageItemSet[self._CurStoragePage][index + 1]
			if itemData == nil or itemData._Tid == 0  then
				return
			end
			local StoragePackChange = require "PB.net".C2SStoragePackChangeReq
			local protocol = StoragePackChange()
			protocol.ChangeType =  net.StoragePackChangeType.Type_UnLoad
			protocol.Index = itemData._Slot
			PBHelper.Send(protocol)	
		end	
	elseif id == "List_Item3" then 
		local itemData = self._GetItemsByDecom[index + 1]
		if not itemData.IsTokenMoney then 
			CItemTipMan.ShowItemTips(itemData.Tid, TipsPopFrom.OTHER_PANEL, self._PanelObject._StorageTipPosition, TipPosition.DEFAULT_POSITION)
    	else
    		local panelData = 
							{
								_MoneyID = itemData.Tid ,  
								_TipPos = TipPosition.FIX_POSITION,
								_TargetObj = nil, 
							} 
			CItemTipMan.ShowMoneyTips(panelData) 
    	end
    elseif id == "List_Item4" then    
    	local itemData  = self._ChooseDecomItems[index + 1]
    	if itemData == nil then return end
    	if itemData:IsEquip() then 
			itemData:ShowTipWithFuncBtns(TipsPopFrom.BACK_PACK_PANEL,TipPosition.DEFAULT_POSITION,self._PanelObject._BagEquipTipsPosition,item)
		else
			itemData:ShowTipWithFuncBtns(TipsPopFrom.BACK_PACK_PANEL,TipPosition.DEFAULT_POSITION,self._PanelObject._BagItemTipsPosition,item)
		end
    end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if self._IsShowDecomposeFx then return end
	if id == "List_Item4" and id_btn == "Btn_Delete" then 
		self:AddOrDeletChooseItemSets(self._ChooseDecomItems[index + 1]._Slot,index ,nil) 
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
	end
end

-- 仓库打开之后的长按弹出tips
def.method('userdata','string','number').LongPressItem = function(self, item, id, index)
	local itemData = nil		
	local targetObj = nil 
	local isDeposit = false
	if id =='List_Item1' then	
		itemData = self._ItemSet[self._CurRdoType][index + 1]
		if self._IsOpenStorage then 
			targetObj = self._PanelObject._BagEquipTipsPosition
			isDeposit = true
		elseif self._IsOpenDecompose then 
			itemData:ShowTip(TipPosition.DEFAULT_POSITION,self._PanelObject._BagEquipTipsPosition)
		return end
	elseif id == 'List_Item2' then 
		itemData = self._StorageItemSet[self._CurStoragePage][index + 1]
		targetObj = self._PanelObject._StorageTipPosition
		isDeposit = false
	end
	if itemData == nil or itemData._Tid == 0  then
		return
	end
	-- 处理按钮长按状态
	if self._IsOpenStorage then	
		MsgBox.ClearAllBoxes()
		itemData:ShowTipWithOutOrDepositFunc(targetObj,isDeposit,self._CurStoragePage)
		self:CleanBorder()
    	self._CurrentSelectedItem = item
    	self:ShowBorder(item)
	end	
end

-- 判断当前背包是否满
def.method("=>","boolean").IsBagFull = function (self)
	local EffectSize = self:GetUnlockCellNum()
	local curNum = #game._HostPlayer._Package._NormalPack._ItemSet
	if curNum < EffectSize then 
		return false
	else
		return true
	end
end

def.method("number").SetUnlockSoltFlag = function (self,preSlotNumber)
	self._PreSoltNumber = preSlotNumber
	self._IsUnlockSolt = true
end

def.method().UpdateUnlockCell = function(self)
	GUI.SetText(self._PanelObject._LabLockCell,string.format(StringTable.Get(21510),#game._HostPlayer._Package._NormalPack._ItemSet,self:GetUnlockCellNum()))
end

def.method().UpdateSort = function(self)
	self._CurSortType = game._CDecomposeAndSortMan._CurSortType
	self._IsDescending = game._CDecomposeAndSortMan._IsDescending
	if not self._IsDescending then 
		table.sort(self._ItemSet[self._CurRdoType],sortfunctionAscending)
	else
		table.sort(self._ItemSet[self._CurRdoType],sortfunctionDescending)
	end
	self._ItemObjList = {}
	self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._ItemSet[self._CurRdoType])
	-- if not self._IsOpenStorage then return end
	-- self:UpdateStorage()
end

def.method().SetDecomposeFilter = function (self)
	GetDecomposeFilter(self)
	if not self._IsOpenDecompose then 
		return 
	end
	local itemList = GetCanDecomposeItems(self)
	FilterDecomposeItems(self,itemList)
	-- GUI.SetText(self._PanelObject._LabDecomposeNum,string.format(StringTable.Get(308), #self._ChooseDecomItems))
	UpdateDecomposeBag(self)
	self._ItemObjList = {}
	self._PanelObject._ItemListView:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._ItemSet[self._CurRdoType])
end

---------------------------------------------Item数据处理----------------------------------------

--得到分类后的物品集合
def.method("table",'=>',"table").GetItemSets = function(self,tempitemSets)
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
				if self._IsOpenDecompose  then 
					if item:CanDecompose() and not item._IsLock then 
						table.insert(itemSets[EnumDef.EBagItemType.Weapon], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Weapon], item)
				end
			end 
			if item:IsEquip() and item:GetCategory() == EnumDef.ItemCategory.Armor then
				if self._IsOpenDecompose then 
					if item:CanDecompose() and not item._IsLock then 
						table.insert(itemSets[EnumDef.EBagItemType.Armor], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Armor], item)
				end
			end 
			if item:IsEquip() and item:GetCategory() == EnumDef.ItemCategory.Jewelry then
				if self._IsOpenDecompose then 
					if item:CanDecompose() and not item._IsLock then 
						table.insert(itemSets[EnumDef.EBagItemType.Accessory], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Accessory], item)
				end
			end
			if item:IsCharm() then
				if self._IsOpenDecompose then 
					if item:CanDecompose() then 
						table.insert(itemSets[EnumDef.EBagItemType.Charm], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Charm], item)
				end
			end 
			if IsConsumableType(self,item._ItemType) then 
				if self._IsOpenDecompose then 
					if item:CanDecompose() then 
						table.insert(itemSets[EnumDef.EBagItemType.Consumables], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Consumables], item)
				end
			end
			if not item:IsEquip() and not IsConsumableType(self,item._ItemType) and not item:IsCharm() then
				if self._IsOpenDecompose then 
					if item:CanDecompose() then 
						table.insert(itemSets[EnumDef.EBagItemType.Else], item)
					end
				else
					table.insert(itemSets[EnumDef.EBagItemType.Else], item)
				end
			end  
		end
	end
	
	--当a应该排在b前面时, 返回true, 反之返回false: 默认排序方式sortid  从大到小排序
	if self._CurSortType == 0 then 
		for i,v in ipairs(itemSets) do 
			if #v > 2 then 
				table.sort(v , sortfunction)
			end
		end
	else
		if not self._IsDescending then 
			for i,v in ipairs(itemSets) do 
				if #v > 2 then 
					table.sort(v , sortfunctionAscending)
				end
			end
		else
			for i,v in ipairs(itemSets) do 
				if #v > 2 then 
					table.sort(v , sortfunctionDescending)
				end
			end
		end
	end
	return itemSets
end

-------------------------------------------关闭界面（清除数据）------------------------------------
local function clear_item_new_flag()
	local pack = game._HostPlayer._Package._NormalPack
	if pack == nil then return end
	if pack._ItemSet == nil then return end
	
	for k,v in pairs(pack._ItemSet) do
		if v ~= nil then
			v._IsNewGot = false
		end
	end
end

def.method().Hide = function(self)
	
	CGame.EventManager:removeHandler(CloseTipsEvent, OnCloseTipsEvent)
	CGame.EventManager:removeHandler(UseItemEvent, OnUseItemEvent)
	clear_item_new_flag()
	if self._EffectTimerId ~= 0 then 
		_G.RemoveGlobalTimer(self._EffectTimerId)
		self._EffectTimerId = 0
	end
	self._Panel = nil
	self._CurTabRefreshFunc = nil
	self._CurrentSelectedItem = nil 
	self._ItemSet = nil 
	self._IsOpenStorage = false
	self._StorageItemSet = {}
	self._CurStoragePage = 0 
	self._UnlockPage = 0 
	self._UnLockPrice = {}
	self._IsUnlockSolt = false
	self._PreSoltNumber = 0 
	self._CurSortType = 0
	self._IsDescending = false
	self._IsOpenDecompose = false
	self._ChooseDecomItems = {}
	self._GetItemsByDecom = {}
	self._ItemObjList = {}
	self._DecomposeItemObjList = {}
	self._BagCouponData = nil 
	self._ConsumableTypes = {}
	if self._IsDecomposeTimer then 
		self:AddDecomposeTimer()
	end

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Close_Bag, 0)
end

def.method().Destroy = function(self)
	self:RemoveDecomposeTimer()
	instance = nil 

	self._LabDrop = nil
end

CPageBag.Commit()
return CPageBag