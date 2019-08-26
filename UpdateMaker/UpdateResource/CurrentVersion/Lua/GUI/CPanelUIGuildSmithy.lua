--公会铁匠铺
--时间：2017/7/13
--Add by Yao

local CFrameCurrency = require "GUI.CFrameCurrency"
local CCommonBtn = require "GUI.CCommonBtn"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local bit = require "bit"
local EBagType = require "PB.net".BAGTYPE
local EMachingType = require "PB.net".EMachingType
local EGuildBuildingType = require "PB.data".GuildBuildingType
local CUIScene = require "GUI.CUIScene"
local CGuildSmithyMan = require "Guild.CGuildSmithyMan"

local PackageChangeEvent = require "Events.PackageChangeEvent"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIGuildSmithy = Lplus.Extend(CPanelBase, "CPanelUIGuildSmithy")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIGuildSmithy.define

-- 界面
def.field(CFrameCurrency)._Frame_Money = nil
def.field("userdata")._TabList_Menu = nil
def.field("userdata")._Frame_Right = nil
def.field("userdata")._ListObj_Right = nil
def.field("userdata")._List_Right = nil
def.field("userdata")._Frame_Detail = nil
def.field("userdata")._Frame_Equip = nil
def.field("userdata")._Lab_EquipName = nil
def.field("userdata")._Lab_EquipPos = nil
def.field("userdata")._Lab_BaseAttri = nil
def.field("userdata")._Lab_BaseAttriVal = nil
def.field("userdata")._Lab_FixedAttriVal = nil
def.field("userdata")._Frame_RandomAttri = nil
def.field("userdata")._Lab_RandomAttriVal = nil
def.field("userdata")._Frame_LegendAttri = nil
def.field("userdata")._Lab_LegendAttriVal = nil
def.field("userdata")._ListObj_Material = nil
def.field("userdata")._List_Material = nil
def.field(CCommonBtn)._Btn_Forge = nil
def.field("userdata")._Lab_Forge = nil
def.field("userdata")._Frame_Forging = nil
def.field("userdata")._Img_Cooldown = nil
def.field(CUIScene)._SmithScene = nil
def.field("table")._ImgTable_Tab1RedPoint = BlankTable
def.field("table")._ImgTable_Tab2RedPoint = BlankTable
def.field("table")._FrameTable_ListIcon = BlankTable
def.field("table")._FrameTable_Material = BlankTable
-- 数据
def.field("table")._ShowQualityList = BlankTable -- 展示的所有品质
def.field("table")._ShowLevelList = BlankTable  -- 品质下展示的所有等级
def.field("table")._ItemIdMap = BlankTable -- 所有装备Tid字典
def.field("table")._MaterialCheckMap = BlankTable -- 材料检测字典(Key为装备Tid)
-- 缓存
def.field("number")._SelectedItemId = 0 -- 指定的物品Id
def.field("table")._FrameRightLocalPos = BlankTable
def.field("boolean")._IsMovingIn = false
def.field("boolean")._IsMovingOut = false
def.field("userdata")._CurSelectedIcon = nil
def.field("table")._MaterialNumObjList = BlankTable -- 所有材料数量GameObject
def.field("number")._CurQuality = -1 -- 当前品质
def.field("number")._CurLevel = 0 -- 当前等级
def.field("table")._CurMachiningData = nil -- 当前打开的加工详细信息
def.field("boolean")._IsOpenDetail = false -- 是否打开了打造细节
def.field("boolean")._IsOpenTabListDeep1 = false -- 是否已展开主List

local FORGE_COOLDOWN_TIME = 2000 -- 打造时间（毫秒）
local TWEEN_INTERVAL = 0.5
local TWEEN_DISTANCE = 330

local instance = nil
def.static("=>", CPanelUIGuildSmithy).Instance = function ()
	if instance == nil then
		instance = CPanelUIGuildSmithy()
		instance._PrefabPath = PATH.UI_Guild_Smithy
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
	local tabListObj = self:GetUIObject("TabList_Menu")
	self._TabList_Menu = tabListObj:GetComponent(ClassType.GNewTabList)
	self._Frame_Right = self:GetUIObject("Frame_Right")
	self._ListObj_Right = self:GetUIObject("List_Right")
	self._List_Right = self._ListObj_Right:GetComponent(ClassType.GNewList)
	self._Frame_Detail = self:GetUIObject("Frame_Detail")
	self._Frame_Equip = self:GetUIObject("Frame_Equip")
	self._Lab_EquipName = self:GetUIObject("Lab_EquipName")
	self._Lab_EquipPos = self:GetUIObject("Lab_EquipPos")
	self._Lab_BaseAttri = self:GetUIObject("Lab_AttriTips_1")
	self._Lab_BaseAttriVal = self:GetUIObject("Lab_AttriValues")
	self._Lab_FixedAttriVal = self:GetUIObject("Lab_AttriTips_2")
	self._Frame_RandomAttri = self:GetUIObject("Frame_RandomAttri")
	self._Lab_RandomAttriVal = self:GetUIObject("Lab_AttriTips_3")
	self._Frame_LegendAttri = self:GetUIObject("Frame_LegendAttri")
	self._Lab_LegendAttriVal = self:GetUIObject("Lab_AttriTips_4")
	self._ListObj_Material = self:GetUIObject("List_Material")
	self._List_Material = self._ListObj_Material:GetComponent(ClassType.GNewList)
	self._Btn_Forge = CCommonBtn.new(self:GetUIObject("Btn_Forge"), nil)
	self._Lab_Forge = self:GetUIObject("Lab_Forge")
	self._Frame_Forging = self:GetUIObject("Frame_Forging")
	self._Img_Cooldown = self:GetUIObject("Img_Cooldown")

	self._FrameRightLocalPos = self._Frame_Right.localPosition

	self._Frame_Forging:SetActive(true)
	self._Frame_Detail:SetActive(true)

    --<<显示女铁匠的 临时代码
    if self._SmithScene == nil then
        local cb = (function(b_ret)
            if(not b_ret)then return end
            if instance ~= nil then
                instance._SmithScene:SetVisible(not (instance._IsHidden or instance._IsSelfHidden))
                local bg = instance:GetUIObject("Img_BG")
                if bg ~= nil then
                    local player  = bg:GetComponent(ClassType.DOTweenPlayer)
                    if player ~= nil then
                        player:Restart("Img_BG")
                    end
                end
            end
        end )

        self._SmithScene = CUIScene.new(self)
        self._SmithScene:Load(PATH.UI_Scene_Smith, cb)
    end

    -->>显示女铁匠的 临时代码

    --屏蔽女铁匠的 临时代码
--    local img_obj = self:GetUIObject("Img_Scene")
--    if img_obj ~= nil then
--        img_obj:SetActive(false)
--    end
    --屏蔽女铁匠的 临时代码
end

------------------------------显示数据处理 start-----------------------------
-- 初始化界面数据
def.method().InitPanelData = function (self)
	self._ItemIdMap = {}
	self._MaterialCheckMap = {}

	local qualityMap = {}
	local machiningTidMap = CGuildSmithyMan.Instance():GetMachiningTidMap()
	local costPercent = CGuildSmithyMan.Instance():GetCostPercent()
	for itemId, machiningTid in pairs(machiningTidMap) do
		-- 初始化材料检查数据
		local machiningTemplate = CElementData.GetItemMachiningTemplate(machiningTid)
		if machiningTemplate ~= nil then
			local checkData =
			{
				SrcItemDatas = machiningTemplate.SrcItemData.SrcItems,	-- 材料列表
				MoneyID = machiningTemplate.MoneyId,					-- 消耗货币ID
				MoneyNum = math.ceil(machiningTemplate.MoneyNum * costPercent),	-- 消耗货币数量
			}
			self._MaterialCheckMap[itemId] = checkData
		end
		-- 初始化所有物品Tid数据
		local itemTemplate = CElementData.GetItemTemplate(itemId)
		if itemTemplate ~= nil then
			-- 添加到品质字典
			local quality = itemTemplate.InitQuality
			local levelMap = qualityMap[quality]
			if levelMap == nil then
				levelMap = {}
			end
			local level = itemTemplate.MinLevelLimit
			if levelMap[level] == nil then
				levelMap[level] = {}
			end
			-- 添加到等级层
			local data =
			{
				ItemId = itemId,
				Slot = itemTemplate.Slot,
			}
			table.insert(levelMap[level], data)
			-- 添加到品质层
			qualityMap[quality] = levelMap
		end
	end

	local function item_sort(a, b)
		if a.Slot ~= b.Slot then
			return a.Slot < b.Slot
		end
		return false
	end

	-- 初始化展示品质列表
	self._ShowQualityList = {}
	for quality, levelMap in pairs(qualityMap) do
		table.insert(self._ShowQualityList, quality)
		-- 按照装备部位排序
		for level, dataList in pairs(levelMap) do
			local itemIds = {}
			table.sort(dataList, item_sort)
			for _, data in ipairs(dataList) do
				table.insert(itemIds, data.ItemId)
			end
			if self._ItemIdMap[quality] == nil then
				self._ItemIdMap[quality] = {}
			end
			if self._ItemIdMap[quality][level] == nil then
				self._ItemIdMap[quality][level] = {}
			end
			self._ItemIdMap[quality][level] = itemIds
		end
	end
	table.sort(self._ShowQualityList)
end

-- 初始化当前打开的打造详细数据
def.method("number").InitCurMachiningData = function (self, itemId)
	self._CurMachiningData = nil
	if itemId <= 0 then return end
	local machiningTidMap = CGuildSmithyMan.Instance():GetMachiningTidMap()
	local machiningTid = machiningTidMap[itemId]
	if machiningTid == nil then return end

	local itemMachining = CElementData.GetItemMachiningTemplate(machiningTid)
	local itemTemplate = CElementData.GetItemTemplate(itemId)
	if itemMachining ~= nil and itemTemplate ~= nil then
		local propInfo = CElementData.GetPropertyInfoById(itemTemplate.AttachedPropertyGeneratorId)
		local baseAttriStr = GUITools.FormatNumber(propInfo.MinValue, false, 7) .. "~" .. GUITools.FormatNumber(propInfo.MaxValue, false, 7)

		local fixedPorpGroupTemp = CElementData.GetAttachedPropertyGroupGeneratorTemplateMap(itemTemplate.AttachedPropertyGroupGeneratorId)		
		local fixedPorpCountInfo = fixedPorpGroupTemp.CountData.GenerateCounts
		local fixedPorpMinNum = fixedPorpCountInfo[1].Count
		local fixedPorpMaxNum = 0
		for _, info in ipairs(fixedPorpCountInfo) do
			if info.Weight == 0 then break end
			fixedPorpMaxNum = info.Count
		end

		-- local randomPorpGroupTemp = CElementData.GetAttachedPropertyGroupGeneratorTemplateMap(itemTemplate.AttachedPropertyGroupGeneratorId2)
		-- local randomPorpCountInfo = randomPorpGroupTemp.CountData.GenerateCounts
		-- local randomPorpMaxNum = randomPorpCountInfo[#randomPorpCountInfo].Count
		-- 保存打造物品对应的打造数据
		self._CurMachiningData =
		{
			DestItemID = itemId,									-- 目标装备ID
			DestItemName = itemTemplate.TextDisplayName,			-- 目标装备名称
			DestItemQuality = itemTemplate.InitQuality,				-- 目标装备品质
			DestItemSlot = itemTemplate.Slot,						-- 目标装备部位
			DestItemLevel = itemTemplate.MinLevelLimit,				-- 目标装备等级
			SrcItemDatas = itemMachining.SrcItemData.SrcItems,		-- 材料列表
			MachiningTid = machiningTid,							-- 对应加工ID
			BaseAttriName = propInfo.Name,							-- 基础属性名称
			BaseAttriStr = baseAttriStr,							-- 基础属性值的显示范围
			FixedAttriMinNum = fixedPorpMinNum,						-- 附加属性最小生成数量
			FixedAttriMaxNum = fixedPorpMaxNum,						-- 附加属性最大生成数量
			-- RandomAttriMaxNum = randomPorpMaxNum,					-- 随机属性最大生成数量
			LegendAttriGroupTid = itemTemplate.LegendaryGroupId,	-- 目标装备传奇属性组ID
		}
	end
end
--------------------------------显示数据处理 end-----------------------------

-- 监听物品变化
local function OnPackageChangeEvent(sender, event)
	if instance ~= nil and instance:IsShow() and event.PackageType == EBagType.BACKPACK then
		instance:UpdateRedPointAndMaterialNum()
	end
end

-- 监听货币变化
local function OnNotifyMoneyChangeEvent(sender, event )
	if instance ~= nil and instance:IsShow() then
		instance:UpdateRedPoint() -- 更新红点
		local machiningData = instance._CurMachiningData
		if machiningData ~= nil then
			instance:UpdateBtnForgeState(machiningData.DestItemID) -- 更新按钮
			-- instance:UpdateMoneyNum(machiningData.DestItemID)
		end
	end
end

-- @param data:目标装备Tid
def.override("dynamic").OnData = function (self, data)
    self._HelpUrlType = HelpPageUrlType.Guild_Smithy
	self:InitPanelData()

	-- 重置状态
	self._IsMovingIn = false
	self._IsMovingOut = false
	self._CurQuality = -1
	self._CurLevel = 0
	self._Frame_Right:SetActive(false)
	GUITools.SetUIActive(self._Frame_Forging, false)
	GUITools.SetUIActive(self._Frame_Detail, false)

	self._CurMachiningData = nil
	self._IsOpenDetail = false
	self._IsOpenTabListDeep1 = false

	-- 设置左菜单主List
	self._TabList_Menu:SetItemCount(#self._ShowQualityList)
	self:UpdateQualityRedPoint()

	self._SelectedItemId = 0
	local main_index, sub_index = 0, 0
	local selectedQuality, selectedLevel = 0, 0
	if type(data) == "number" then
		-- 指定特定的装备
		for quality, levelMap in pairs(self._ItemIdMap) do
			for level, idList in pairs(levelMap) do
				for _, id in ipairs(idList) do
					if id == data then
						selectedQuality = quality
						selectedLevel = level
						self._SelectedItemId = id
						break
					end
				end
			end
		end
		for index, quality in ipairs(self._ShowQualityList) do
			if selectedQuality == quality then
				main_index = index - 1
				break
			end
		end
		local showLevelList = {}
		for level, _ in pairs(self._ItemIdMap[selectedQuality]) do
			table.insert(showLevelList, level)
		end
		table.sort(showLevelList)
		for index, level in ipairs(showLevelList) do
			if selectedLevel == level then
				sub_index = index - 1
				break
			end
		end
	else
		-- 默认打开菜单，选中第一个
		if #self._ShowQualityList > 0 then
			selectedQuality = self._ShowQualityList[1]
			local showLevelList = {}
			for level, _ in pairs(self._ItemIdMap[selectedQuality]) do
				table.insert(showLevelList, level)
			end
			table.sort(showLevelList)
			if #showLevelList > 0 then
				selectedLevel = showLevelList[1]
			end
		end
	end
	-- print("selectedQuality", selectedQuality, "selectedLevel", selectedLevel, "main_index", main_index, "sub_index", sub_index, "data", data)
	self._TabList_Menu:SetSelection(main_index, sub_index)
	self:SelectTabListDeep1(selectedQuality)
	self:SelectTabListDeep2(selectedLevel)

	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
	CGame.EventManager:addHandler(NotifyMoneyChangeEvent, OnNotifyMoneyChangeEvent)
end

-- 重置界面状态
def.method().ResetPanel = function (self)
	-- self:EnableTween(false) -- 重置Tween

	self._CurLevel = 0
	self._Frame_Right:SetActive(false)
	self._FrameTable_ListIcon = {}
	self:CloseDetail()
end

-- 关闭打造细节界面
def.method().CloseDetail = function (self)
	-- self:EnableTween(false)

	self._CurMachiningData = nil
	self._IsOpenDetail = false

	GUITools.SetUIActive(self._Frame_Detail, false)
	IconTools.SetFrameIconTags(self._CurSelectedIcon, { [EFrameIconTag.Select] = false })
end

def.override("string").OnClick = function (self, id)
	CPanelBase.OnClick(self,id)
	if self._Frame_Money:OnClick(id) then return end

	if string.find(id, "Btn_Back") then
		game._GUIMan:CloseByScript(self)
		CItemTipMan.CloseCurrentTips()

		-- 关闭时刷新公会界面铁匠铺的红点
		local CPanelUIGuild = require "GUI.CPanelUIGuild"
		if CPanelUIGuild and CPanelUIGuild.Instance():IsShow() then
			CPanelUIGuild.Instance():UpdateRedPoint()
		end
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
        --game._GUIMan:Close("CPanelUIGuildSmithy")
	elseif string.find(id, "Btn_CloseDetail") then
		self:CloseDetail()
	elseif string.find(id, "Btn_Forge") then
		-- 打造
		local machiningData = self._CurMachiningData
		if machiningData ~= nil then
			local checkData = self._MaterialCheckMap[machiningData.DestItemID]
			if checkData ~= nil then
				-- 弹窗有检查货币的功能
				MsgBox.ShowQuickBuyBox(checkData.MoneyID, checkData.MoneyNum, function(ret)
					if not ret then return end

					if not self:IsMaterialEnough(machiningData.DestItemID) then
						-- 材料不足
						game._GUIMan:ShowTipText(StringTable.Get(10901), false)
					elseif not game._HostPlayer:HasEnoughSpace(machiningData.DestItemID, true, 1) then
						-- 背包空间不足
						game._GUIMan:ShowTipText(StringTable.Get(256), false)
					else
						self:StartForge(machiningData)
					end
				end)
			end
		end
	end
end

-- 根据品质和等级获取装备列表
local function GetItemList(self, quality, level)
	if self._ItemIdMap[quality] ~= nil then
		return self._ItemIdMap[quality][level]
	end
	return nil
end

-- 根据右列表索引获取打造数据
local function GetItemIdByListIndex(self, index)
	local itemIds = GetItemList(self, self._CurQuality, self._CurLevel)
	if itemIds == nil or itemIds[index+1] == nil then return 0 end

	return itemIds[index+1]
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
	if string.find(list.name, "TabList_Menu") then
		if sub_index == -1 then
			self:OnInitTabListDeep1(item, main_index)
		else
			self:OnInitTabListDeep2(item, main_index, sub_index)
		end
	end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
	if string.find(list.name, "TabList_Menu") then
		if sub_index == -1 then
			self:OnClickTabListDeep1(item, main_index)
		else
			self:OnClickTabListDeep2(item, main_index, sub_index)
		end
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_Right") then
		self:OnInitRightList(item, index)
	elseif string.find(id, "List_Material") then
		self:OnInitMaterialList(item, index)
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if string.find(id, "List_Right") then
		self:OnClickRightList(item, index)
	elseif string.find(id, "List_Material") then
		local machiningData = self._CurMachiningData
		if machiningData == nil then return end

		local materialItem = GUITools.GetChild(item, 1)
		local srcItemData = machiningData.SrcItemDatas[index+1]
		CItemTipMan.ShowItemTips(srcItemData.ItemId, TipsPopFrom.OTHER_PANEL, materialItem, TipPosition.FIX_POSITION)
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, list_name, button_name, index)
	if string.find(list_name, "List_Right") then
		if string.find(button_name, "Frame_Item") then
			self:OnClickRightItem(button_obj, index)
		end
	end
end

------------------------------------左菜单 start--------------------------------
-- 初始化主List
def.method("userdata", "number").OnInitTabListDeep1 = function (self, item, index)
	local quality = self._ShowQualityList[index+1]
	local qualityStr = StringTable.Get(10000 + quality) .. StringTable.Get(22900)
	local lab_quality = item:FindChild("Lab_Text")
	GUI.SetText(lab_quality, qualityStr)
	local img_red_point = item:FindChild("Img_RedPoint")
	self._ImgTable_Tab1RedPoint[quality] = img_red_point
end

-- 初始化次List
def.method("userdata", "number", "number").OnInitTabListDeep2 = function (self, item, main_index, sub_index)
	local level = self._ShowLevelList[sub_index+1]
	local lab_level = item:FindChild("Lab_Text")
	GUI.SetText(lab_level, level .. StringTable.Get(6))
	local img_red_point = item:FindChild("Img_RedPoint")
	self._ImgTable_Tab2RedPoint[level] = img_red_point
end

-- 点击主List
def.method("userdata", "number").OnClickTabListDeep1 = function (self, item, index)
	local quality = self._ShowQualityList[index+1]
	if self._CurQuality == quality then
		local img_arrow = item:FindChild("Img_Arrow")
		if self._IsOpenTabListDeep1 then
			-- 点击已展开的
			self._IsOpenTabListDeep1 = false
			self._TabList_Menu:OpenTab(0)
			if not IsNil(img_arrow) then
				GUITools.SetGroupImg(img_arrow, 2)
			end
		else
			self:SelectTabListDeep1(quality)
			if not IsNil(img_arrow) then
				GUITools.SetGroupImg(img_arrow, 1)
			end
		end
	else
		-- 点击新的
		if self._CurLevel > 0 then
			self:ResetPanel()
		end
		self._TabList_Menu:SetSelection(index, 0)
		self:SelectTabListDeep1(quality)
		if #self._ShowLevelList > 0 then
			-- 默认选中次List第一个
			self:SelectTabListDeep2(self._ShowLevelList[1])
		end
	end
end

-- 点击次List
def.method("userdata", "number", "number").OnClickTabListDeep2 = function (self, item, main_index, sub_index)
	local level = self._ShowLevelList[sub_index+1]
	if level == self._CurLevel then return end

	self:SelectTabListDeep2(level)
end

def.method("number").SelectTabListDeep1 = function (self, quality)
	self._CurQuality = quality
	self._IsOpenTabListDeep1 = true

	self._ImgTable_Tab2RedPoint = {}
	self._ShowLevelList = {}
	local levelMap = self._ItemIdMap[quality]
	if levelMap ~= nil then
		for level, _ in pairs(levelMap) do
			table.insert(self._ShowLevelList, level)
		end
		table.sort(self._ShowLevelList)
	end
	self._TabList_Menu:OpenTab(#self._ShowLevelList)
	self:UpdateLevelRedPoint(quality)
end

def.method("number").SelectTabListDeep2 = function (self, level)
	local equipList = GetItemList(self, self._CurQuality, level)
	if equipList == nil then return end

	-- 重置界面
	self._FrameTable_ListIcon = {}
	if self._CurLevel > 0 then
		self:CloseDetail()
	end

	self._CurLevel = level
	if #equipList > 0 then
		self._Frame_Right:SetActive(true)
		self._List_Right:SetItemCount(#equipList)
	else
		self._Frame_Right:SetActive(false)
	end
end
-------------------------------------左菜单 end---------------------------------

------------------------------------右列表 start--------------------------------
-- 初始化右列表
def.method("userdata", "number").OnInitRightList = function (self, item, index)
	local itemId = GetItemIdByListIndex(self, index)
	local itemTemplate = CElementData.GetItemTemplate(itemId)
	if itemTemplate == nil then return end

	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end
	-- 装备图标
	local frame_item = uiTemplate:GetControl(2)
	IconTools.InitItemIconNew(frame_item, itemId)
	-- 名字
	local lab_name = uiTemplate:GetControl(3)
	local nameStr = itemTemplate.TextDisplayName
	-- local nameStr = RichTextTools.GetQualityText(itemTemplate.TextDisplayName, itemTemplate.InitQuality)
	GUI.SetText(lab_name, nameStr)
	-- 基础属性名
	local propInfo = CElementData.GetPropertyInfoById(itemTemplate.AttachedPropertyGeneratorId)
	local lab_attri = uiTemplate:GetControl(4)
	GUI.SetText(lab_attri, propInfo.Name)
	-- 基础属性值
	local minStr = GUITools.FormatNumber(propInfo.MinValue, false, 7)
	local maxStr = GUITools.FormatNumber(propInfo.MaxValue, false, 7)
	local lab_attri_value = uiTemplate:GetControl(5)
	GUI.SetText(lab_attri_value, minStr .. "~" .. maxStr)
	-- 是否被选中
	IconTools.SetFrameIconTags(frame_item, { [EFrameIconTag.Select] = false } )
	-- 红点
	local bShow = self:IsMoneyEnough(itemId) and self:IsMaterialEnough(itemId)
	IconTools.SetFrameIconTags(frame_item, { [EFrameIconTag.RedPoint] = bShow } )
	self._FrameTable_ListIcon[itemId] = frame_item
	-- 选中
	if self._SelectedItemId > 0 and self._SelectedItemId == itemId then
		self:SelectRigthItem(frame_item, itemId)
		self._SelectedItemId = 0
	end
end

-- 点击右列表
def.method("userdata", "number").OnClickRightList = function (self, item, index)
	CItemTipMan.CloseCurrentTips()

	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local itemId = GetItemIdByListIndex(self, index)
	local machiningData = self._CurMachiningData
	if machiningData ~= nil and machiningData.DestItemID == itemId then return end

	local frame_icon = uiTemplate:GetControl(2)
	self:SelectRigthItem(frame_icon, itemId)
end

-- 选中
def.method("userdata", "number").SelectRigthItem = function (self, selectedIcon, itemId)
	-- self:EnableTween(true)

	IconTools.SetFrameIconTags(self._CurSelectedIcon, { [EFrameIconTag.Select] = false })
	IconTools.SetFrameIconTags(selectedIcon, { [EFrameIconTag.Select] = true })
	self._CurSelectedIcon = selectedIcon

	self:InitCurMachiningData(itemId)
	self:ShowMachiningDetail(self._CurMachiningData)
end

-- 点击右列表的装备按钮，弹提示
def.method("userdata", "number").OnClickRightItem = function (self, btnObj, index)
	local itemId = GetItemIdByListIndex(self, index)
	CItemTipMan.ShowItemTips(itemId, TipsPopFrom.OTHER_PANEL, btnObj, TipPosition.FIX_POSITION)
end
-------------------------------------右列表 end---------------------------------

-------------------------------------红点 start---------------------------------
-- 更新所有红点
def.method().UpdateRedPoint = function (self)
	self:UpdateLeftRedPoint()
	self:UpdateRightRedPoint()
end

-- 更新左菜单红点
def.method().UpdateLeftRedPoint = function (self)
	self:UpdateQualityRedPoint()
	self:UpdateLevelRedPoint(self._CurQuality)
end

-- 更新所有品质Tab的红点
def.method().UpdateQualityRedPoint = function (self)
	for quality, img_red_point in pairs(self._ImgTable_Tab1RedPoint) do
		local isShow = false
		local levelMap = self._ItemIdMap[quality]
		if levelMap ~= nil then
			for level, _ in pairs(levelMap) do
				if self:IsShowLevelRedPoint(quality, level) then
					isShow = true
					break
				end
			end
		end
		img_red_point:SetActive(isShow)
	end
end

-- 更新特定品质下所有等级Tab的红点
def.method("number").UpdateLevelRedPoint = function (self, quality)
	local levelMap = self._ItemIdMap[quality]
	if levelMap == nil then return end

	for level, img_red_point in pairs(self._ImgTable_Tab2RedPoint) do
		local isShow = self:IsShowLevelRedPoint(quality, level)
		img_red_point:SetActive(isShow)
	end
end

-- 更新特定品质，特定等级下是否有红点
def.method("number", "number", "=>", "boolean").IsShowLevelRedPoint = function (self, quality, level)
	local levelMap = self._ItemIdMap[quality]
	if levelMap ~= nil then
		local idList = levelMap[level]
		if idList ~= nil then
			for _, itemId in ipairs(idList) do
				if self:IsMaterialEnough(itemId) and self:IsMoneyEnough(itemId) then
					return true
				end
			end
		end
	end
	return false
end

-- 更新右列表红点
def.method().UpdateRightRedPoint = function (self)
	local equipList = GetItemList(self, self._CurQuality, self._CurLevel)
	if equipList == nil then return end

	for _, itemId in ipairs(equipList) do
		local frame_icon = self._FrameTable_ListIcon[itemId]
		local bShow = self:IsMoneyEnough(itemId) and self:IsMaterialEnough(itemId)
		IconTools.SetFrameIconTags(frame_icon, { [EFrameIconTag.RedPoint] = bShow })
	end
end
-------------------------------------红点 end---------------------------------

-- 初始化材料列表
def.method("userdata", "number").OnInitMaterialList = function (self, item, index)
	local machiningData = self._CurMachiningData
	if machiningData == nil then return end

	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if uiTemplate == nil then return end

	local srcItemData = machiningData.SrcItemDatas[index+1]
	-- 材料名称
	local lab_name = uiTemplate:GetControl(0)
	local itemTemplate = CElementData.GetItemTemplate(srcItemData.ItemId)
	if itemTemplate ~= nil then
		GUI.SetText(lab_name, itemTemplate.TextDisplayName)
	end
	-- 材料图标
	local materialItem = uiTemplate:GetControl(1)
	IconTools.InitMaterialIconNew(materialItem, srcItemData.ItemId, srcItemData.ItemCount)
	self._FrameTable_Material[index+1] = materialItem
end


-- 显示打造细节
def.method("table").ShowMachiningDetail = function (self, machiningData)
	if machiningData == nil then return end

	self._IsOpenDetail = true
	GUITools.SetUIActive(self._Frame_Detail, true)
	-- 装备图标
	IconTools.InitItemIconNew(self._Frame_Equip, machiningData.DestItemID)
	-- 装备名称
	GUI.SetText(self._Lab_EquipName, machiningData.DestItemName)
	-- 装备等级和部位
	self:SetEquipPosLab(machiningData)
	-- 基本属性
	GUI.SetText(self._Lab_BaseAttri, machiningData.BaseAttriName)
	GUI.SetText(self._Lab_BaseAttriVal, tostring(machiningData.BaseAttriStr))
	-- 附加属性
	GUI.SetText(self._Lab_FixedAttriVal, string.format(StringTable.Get(22902), machiningData.FixedAttriMinNum, machiningData.FixedAttriMaxNum))
	-- 随机属性
	GUITools.SetUIActive(self._Frame_RandomAttri, false) -- 临时处理
	-- GUI.SetText(self._Lab_RandomAttriVal, string.format(StringTable.Get(22901), machiningData.RandomAttriMaxNum))
	-- 传奇属性
	GUITools.SetUIActive(self._Frame_LegendAttri, machiningData.LegendAttriGroupTid > 0)
	-- 材料列表
	if #machiningData.SrcItemDatas > 0 then
		self._FrameTable_Material = {}
		GUITools.SetUIActive(self._ListObj_Material, true)
		self._List_Material:SetItemCount(#machiningData.SrcItemDatas)
	else
		GUITools.SetUIActive(self._ListObj_Material, false)
	end
	local checkData = self._MaterialCheckMap[machiningData.DestItemID]
	if checkData ~= nil then
		local setting =
		{
			[EnumDef.CommonBtnParam.MoneyID] = checkData.MoneyID,
			[EnumDef.CommonBtnParam.MoneyCost] = checkData.MoneyNum,
		}
		self._Btn_Forge:ResetSetting(setting)
	end
	self:UpdateBtnForgeState(machiningData.DestItemID) -- 打造按钮
end

-----------------------------------界面更新 start-------------------------------
-- 更新打造按钮状态
def.method("number").UpdateBtnForgeState = function (self, itemId)
	if not self._IsOpenDetail then return end

	local isMaterialEnough = self:IsMaterialEnough(itemId)
	self._Btn_Forge:SetInteractable(isMaterialEnough)
	self._Btn_Forge:MakeGray(not isMaterialEnough)
end

-- 更新红点和材料数量
def.method().UpdateRedPointAndMaterialNum = function (self)
	self:UpdateRedPoint() -- 更新红点

	if not self._IsOpenDetail then return end

	local machiningData = self._CurMachiningData
	if machiningData == nil then return end

	-- 更新材料
	local normalPack = game._HostPlayer._Package._NormalPack -- 普通背包
	for index, srcItemData in ipairs(machiningData.SrcItemDatas) do
		IconTools.InitMaterialIconNew(self._FrameTable_Material[index], srcItemData.ItemId, srcItemData.ItemCount)
	end

	self:UpdateBtnForgeState(machiningData.DestItemID) -- 更新按钮
end

-- 更新装备等级部位文本
def.method("table").SetEquipPosLab = function (self, machiningData)
	if not self._IsOpenDetail or machiningData == nil then return end

	if machiningData == nil then return end

	local slotStr = StringTable.Get(10400 + machiningData.DestItemSlot)
	slotStr = RichTextTools.GetQualityText(slotStr, machiningData.DestItemQuality)
	local posStr = machiningData.DestItemLevel .. StringTable.Get(6) .. " " .. slotStr
	-- if machiningData.DestItemLevel > game._HostPlayer._InfoData._Level then
	-- 	-- 玩家等级低于装备等级
	-- 	posStr = RichTextTools.GetUnavailableColorText(posStr)
	-- end
	GUI.SetText(self._Lab_EquipPos, posStr)
end
-------------------------------------界面更新 end---------------------------------
-- 检查背包是否有足够的材料
def.method("number", "=>", "boolean").IsMaterialEnough = function (self, itemId)
	local checkData = self._MaterialCheckMap[itemId]
	if checkData == nil then return false end
	local hp = game._HostPlayer
	local normalPack = hp._Package._NormalPack
	for _, v in ipairs(checkData.SrcItemDatas) do
		local materialInPackage = normalPack:GetItemCount(v.ItemId)
		local materialNeed = v.ItemCount
		if materialNeed > materialInPackage then return false end
	end
	return true
end

-- 检查货币是否足够
def.method("number", "=>", "boolean").IsMoneyEnough = function (self, itemId)
	local checkData = self._MaterialCheckMap[itemId]
	if checkData == nil then return false end
	local hp = game._HostPlayer
	local moneyHave = hp:GetMoneyCountByType(checkData.MoneyID)
	if checkData.MoneyNum > moneyHave then return false end
	return true
end

-- 开始打造
def.method("table").StartForge = function (self, machiningData)
	if machiningData == nil then return end

    if self._SmithScene ==nil then return end

	GUITools.SetUIActive(self._Frame_Detail, false)
	GUITools.SetUIActive(self._Frame_Forging, true)
	-- self:EnableTween(true)

	local function cb()
		local C2SItemMachining = require "PB.net".C2SItemMachining
		local EMachingOptType = require "PB.net".EMachingOptType
		local protocol = C2SItemMachining()
		protocol.MachingOptType = EMachingOptType.EMachingOptType_Compose
		protocol.ItemMachiningId = machiningData.MachiningTid -- 物品加工ID
		protocol.Count = 1 --加工数量，默认为1
		protocol.MachingType = EMachingType.EMachingType_Guild
		PBHelper.Send(protocol)
	end

    local animLength = 0
    local play_failed = true
    if self._SmithScene ~= nil and self._SmithScene:IsSceneReady() then
        animLength = self._SmithScene:PlaySequence(0, "BS_Forge", cb)
        play_failed = animLength < 0
    end

    if play_failed then
        cb()
    end

    if animLength > 0 then
	    GameUtil.AddCooldownComponent(self._Img_Cooldown, 0, animLength * 1000, nil, nil, false)
    end
end

-- 界面移动
def.method("boolean").EnableTween = function (self, enable)
	if enable then
		if not self._IsMovingIn then
			self._IsMovingIn = true
			local localPos = self._FrameRightLocalPos
			local movePos = Vector3.New(localPos.x + TWEEN_DISTANCE, localPos.y, localPos.z)
			GUITools.DoLocalMove(self._Frame_Right, movePos, TWEEN_INTERVAL, nil, function()
				self._IsMovingIn = false
			end)
		end
	else
		-- 复位
		if not self._IsMovingOut then
			self._IsMovingOut = true
			GUITools.DoLocalMove(self._Frame_Right, self._FrameRightLocalPos, TWEEN_INTERVAL, nil, function()
				self._IsMovingOut = false
			end)
		end
	end
end

-- 打造成功回调
def.method("table", "boolean").ForgeCallBack = function (self, itemDB, isSuccessful)
	GUITools.SetUIActive(self._Frame_Forging, false)

	local function close_callback()
		GUITools.SetUIActive(self._Frame_Detail, true)
	end

	if isSuccessful then
		if itemDB == nil then
			error("Guild smithy forge succeed, but itemDB got null")
			return
		end
		-- 打造成功
		local data =
		{
			ItemDB = itemDB,
			CloseCallBack = close_callback,
		}
		game._GUIMan:Open("CPanelUISmithyForgeSuccess", data)
	else
		close_callback()
	end
end

def.override().OnHide = function (self)
    CPanelBase.OnHide(self)
	CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
	CGame.EventManager:removeHandler(NotifyMoneyChangeEvent, OnNotifyMoneyChangeEvent)
end

def.override("boolean").OnVisibleChange = function(self, is_show)

    --warn("OnVisibleChange")

    ----game._GUIMan:HideMainCamera(is_show)
	--game._GUIMan:BlockMainCamera(self, is_show)


    if self._SmithScene~=nil then
        self._SmithScene:SetVisible(is_show)
    end
end

def.override().OnDestroy = function (self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end

    if self._SmithScene ~= nil then
        self._SmithScene:Destroy()
        self._SmithScene = nil
    end

    if self._Btn_Forge ~= nil then
    	self._Btn_Forge:Destroy()
    	self._Btn_Forge = nil
    end

	self._TabList_Menu = nil
	self._Frame_Right = nil
	self._ListObj_Right = nil
	self._List_Right = nil
	self._Frame_Detail = nil
	self._Frame_Equip = nil
	self._Lab_EquipName = nil
	self._Lab_EquipPos = nil
	self._Lab_BaseAttri = nil
	self._Lab_BaseAttriVal = nil
	self._Lab_FixedAttriVal = nil
	self._Frame_RandomAttri = nil
	self._Lab_RandomAttriVal = nil
	self._Frame_LegendAttri = nil
	self._Lab_LegendAttriVal = nil
	self._ListObj_Material = nil
	self._List_Material = nil
	self._Lab_Forge = nil
	self._Frame_Forging = nil
	self._Img_Cooldown = nil
	self._SmithScene = nil
	self._ImgTable_Tab1RedPoint = {}
	self._ImgTable_Tab2RedPoint = {}
	self._FrameTable_ListIcon = {}
	self._CurSelectedIcon = nil

    ----game._GUIMan:HideMainCamera(false)
	--game._GUIMan:BlockMainCamera(self, false)

end

CPanelUIGuildSmithy.Commit()
return CPanelUIGuildSmithy