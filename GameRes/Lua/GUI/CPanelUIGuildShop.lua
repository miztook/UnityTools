--
-- 温德商会
--
--【孟令康】
--
-- 2018年1月13日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local GuildBuildingType = require "PB.data".GuildBuildingType
local CFrameCurrency = require "GUI.CFrameCurrency"
local CMallUtility = require "Mall.CMallUtility"
local CPanelUIGuildShop = Lplus.Extend(CPanelBase, "CPanelUIGuildShop")
local def = CPanelUIGuildShop.define

def.field("number")._List_Type = ClassType.GNewListLoop
def.field("number")._Money_Honor_Tid = 5
def.field("number")._Honor_Tid = 1
def.field("table")._Honor_Template = nil
def.field("number")._Money_Fund_Tid = 10
def.field("number")._Fund_Tid = 2
-- 个人贡献
def.field("number")._Money_Contribute_Tid = 6
-- 服务器发的数据
def.field("table")._Fund_Template = nil

def.field(CFrameCurrency)._Frame_Money = nil
-- def.field("userdata")._Img_Diamond = nil
-- def.field("userdata")._Lab_Diamond = nil
-- def.field("userdata")._Img_Diamond_Lock = nil
-- def.field("userdata")._Lab_Diamond_Lock = nil
--def.field("userdata")._Img_D0 = nil
--def.field("userdata")._Lab_List1 = nil
--def.field("userdata")._Img_D1 = nil
--def.field("userdata")._Lab_List2 = nil

def.field("userdata")._TabList = nil
def.field("userdata")._Frame_Guild_Honor = nil
def.field("userdata")._Guild_Honor_List = nil
def.field("userdata")._Frame_Guild_Fund = nil
def.field("userdata")._Guild_Fund_List = nil
def.field("userdata")._Lab_Refresh = nil

local instance = nil
def.static("=>", CPanelUIGuildShop).Instance = function()
	if not instance then
		instance = CPanelUIGuildShop()
		instance._PrefabPath = PATH.UI_Guild_Shop
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local OnNotifyGuildEvent = function(sender, event)
	if instance:IsShow() then
		if event.Type == "GuildShopBuy" then
			if sender._Tid == instance._Honor_Tid then
				instance:ShowHonorShop()				
			else				
				for i, v in ipairs(instance._Fund_Template._Items) do
					if sender._ItemTid == v.ItemId then
						v.ItemNum = sender._ItemNum
					end
				end
				instance:ShowFundShop(sender._Fund)
				instance._Guild_Fund_List:SetItemCount(#instance._Fund_Template._Items)
			end
			--game._GUIMan:ShowMoveItemTextTips(sender._ItemTid, false, sender._ItemNum)
		end
	end
end

-- 当创建
def.override().OnCreate = function(self)
	self:OnInitUIObject()
	self:OnInit()
	CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)

--	-- 临时屏蔽资金商店
--	self:GetUIObject("Tab_Fund"):SetActive(false)
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._HelpUrlType = HelpPageUrlType.Guild_Shop
	self._Fund_Template = data

	self._Guild_Honor_List:SetItemCount(#self._Honor_Template.GuildShopItems)
	self._Guild_Fund_List:SetItemCount(#self._Fund_Template._Items)
end

-- 当摧毁
def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if self._Frame_Money:OnClick(id) then return end
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
		local CPanelUIGuildPray = require "GUI.CPanelUIGuildPray"
		CPanelUIGuildPray.Instance():UpdateBagPrayInfo()
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
	end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    --print("OnTabListInitItem", item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            local lab_name = item:FindChild("Lab_Text")
            
            if main_index == 0 then
                GUI.SetText(lab_name, self._Honor_Template.Name)
            else
                GUI.SetText(lab_name, self._Fund_Template.Name)
            end
        elseif sub_index ~= -1 then
        
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            if main_index == 0 then
                self:ShowHonorShop()
            else
                self:ShowFundShop(game._HostPlayer._Guild._Fund)
            end
        else
            
        end
    end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	local building = game._HostPlayer._Guild._BuildingList[GuildBuildingType.GuildShop]
	local buildingLevel = building._BuildingLevel
	local buildingName = building._BuildingName
	if id == "Guild_Honor_List" then	
		local shopItem = self._Honor_Template.GuildShopItems[index]
		local itemTemplate = CElementData.GetTemplate("Item", shopItem.ItemId)
		--GUITools.SetCommonItem(uiTemplate:GetControl(6), false, shopItem.ItemId)
        IconTools.InitItemIconNew(uiTemplate:GetControl(6), shopItem.ItemId, nil, EItemLimitCheck.AllCheck)
		GUI.SetText(uiTemplate:GetControl(13), itemTemplate.TextDisplayName)
		uiTemplate:GetControl(14):SetActive(false)
		if buildingLevel >= shopItem.ShopLevel then
			uiTemplate:GetControl(1):SetActive(true)
			uiTemplate:GetControl(5):SetActive(false)
			uiTemplate:GetControl(15):SetActive(false)
			uiTemplate:GetControl(6):SetActive(true)	
            uiTemplate:GetControl(13):SetActive(true)
            uiTemplate:GetControl(7):SetActive(true)
			GUITools.SetTokenMoneyIcon(uiTemplate:GetControl(3), shopItem.CostMoneyId)
			GUI.SetText(uiTemplate:GetControl(4), GUITools.FormatNumber(shopItem.CostMoneyNum))
		else
			uiTemplate:GetControl(1):SetActive(false)
			uiTemplate:GetControl(5):SetActive(true)
			uiTemplate:GetControl(15):SetActive(true)
			uiTemplate:GetControl(16):SetActive(true)
            uiTemplate:GetControl(6):SetActive(false)
            uiTemplate:GetControl(13):SetActive(false)
            uiTemplate:GetControl(7):SetActive(false)
			GUI.SetText(uiTemplate:GetControl(5), string.format(StringTable.Get(8012), buildingName, shopItem.ShopLevel))
		end
	elseif id == "Guild_Fund_List" then
		local shopItem = self._Fund_Template._Items[index]
		local itemTemplate = CElementData.GetTemplate("Item", shopItem.ItemId)
		--GUITools.SetCommonItem(uiTemplate:GetControl(6), false, shopItem.ItemId)
        IconTools.InitItemIconNew(uiTemplate:GetControl(6), shopItem.ItemId, nil, EItemLimitCheck.AllCheck)
		GUI.SetText(uiTemplate:GetControl(13), itemTemplate.TextDisplayName)
		if shopItem.ItemNum == 0 then
			uiTemplate:GetControl(12):SetActive(true)
			uiTemplate:GetControl(14):SetActive(false)
		else
			uiTemplate:GetControl(12):SetActive(false)
			uiTemplate:GetControl(14):SetActive(true)
			GUI.SetText(uiTemplate:GetControl(14), "x" .. shopItem.ItemNum)
		end
		if buildingLevel >= shopItem.GuildLevel then
			uiTemplate:GetControl(1):SetActive(true)
			uiTemplate:GetControl(5):SetActive(false)
			uiTemplate:GetControl(15):SetActive(false)
			uiTemplate:GetControl(16):SetActive(false)
			GUITools.SetTokenMoneyIcon(uiTemplate:GetControl(3), shopItem.CostMoneyID)
			GUI.SetText(uiTemplate:GetControl(4), GUITools.FormatNumber(shopItem.CostNum))
		else
			uiTemplate:GetControl(1):SetActive(false)
			uiTemplate:GetControl(5):SetActive(true)
			uiTemplate:GetControl(15):SetActive(true)
			uiTemplate:GetControl(16):SetActive(true)
			GUI.SetText(uiTemplate:GetControl(5), string.format(StringTable.Get(8012), buildingName, shopItem.GuildLevel))
		end
	end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	index = index + 1
	local building = game._HostPlayer._Guild._BuildingList[GuildBuildingType.GuildShop]
	local buildingLevel = building._BuildingLevel
	local buildingName = building._BuildingName
	if id == "Guild_Honor_List" then
		local shopItem = self._Honor_Template.GuildShopItems[index]
		if buildingLevel < shopItem.ShopLevel then
			game._GUIMan:ShowTipText(string.format(StringTable.Get(8012), buildingName, shopItem.ShopLevel), true)
			return
		end
		local callback = function(buyNum)
			local moneyValue = game._GuildMan:GetMoneyValueByTid(shopItem.CostMoneyId)	
			if moneyValue < shopItem.CostMoneyNum * buyNum then
				local money = CElementData.GetTemplate("Money", shopItem.CostMoneyId)
				game._GUIMan:ShowTipText(string.format(StringTable.Get(893), money.TextDisplayName), true)
			else
				self:OnC2SGuildShopBuyItem(self._Honor_Tid, shopItem.ItemId, buyNum)
			end
		end
        local itemTemp = CElementData.GetItemTemplate(shopItem.ItemId)
        local des = string.format(StringTable.Get(22312),   "<color=#"..EnumDef.Quality2ColorHexStr[itemTemp.InitQuality] ..">" .. itemTemp.TextDisplayName .."</color>")
        local max_number = -1
        if CMallUtility.GetQuickBuyTid(shopItem.CostMoneyId, true) <= 0 then
            local money_have = game._GuildMan:GetMoneyValueByTid(shopItem.CostMoneyId)	
            max_number = math.floor(money_have/shopItem.CostMoneyNum)
        end
        BuyOrSellItemMan.ShowCommonOperate(TradingType.BUY,StringTable.Get(11115), des, 1, max_number, shopItem.CostMoneyNum, shopItem.CostMoneyId, nil, callback)
	elseif id == "Guild_Fund_List" then
		local member = game._GuildMan:GetHostGuildMemberInfo()
		if member ~= nil and member._RoleType ~= GuildMemberType.GuildLeader then
			game._GUIMan:ShowTipText(StringTable.Get(8034), true)
			return
		end
		local shopItem = self._Fund_Template._Items[index]
		if shopItem.ItemNum == 0 then
			local itemTemplate = CElementData.GetTemplate("Item", shopItem.ItemId)
			game._GUIMan:ShowTipText(string.format(StringTable.Get(8035), itemTemplate.TextDisplayName), true)
			return
		end
		if buildingLevel < shopItem.GuildLevel then
			game._GUIMan:ShowTipText(string.format(StringTable.Get(8012), buildingName, shopItem.GuildLevel), true)
			return
		end
		local callback = function(buyNum)
			local moneyValue = game._GuildMan:GetMoneyValueByTid(self._Money_Fund_Tid)	
			if moneyValue < shopItem.CostNum * buyNum then
				local money = CElementData.GetTemplate("Money", shopItem.CostMoneyID)
				game._GUIMan:ShowTipText(string.format(StringTable.Get(893), money.TextDisplayName), true)
			else
				self:OnC2SGuildShopBuyItem(self._Fund_Tid, shopItem.ItemId, buyNum)
			end
		end
        local itemTemp = CElementData.GetItemTemplate(shopItem.ItemId)
        local des = string.format(StringTable.Get(22312),   "<color=#"..EnumDef.Quality2ColorHexStr[itemTemp.InitQuality] ..">" .. itemTemp.TextDisplayName .."</color>")
        BuyOrSellItemMan.ShowCommonOperate(TradingType.BUY,StringTable.Get(11115), des, 1, -1, shopItem.CostMoneyNum, shopItem.CostMoneyId, nil, callback)
	end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	index = index + 1
	if id == "Guild_Honor_List" and id_btn == "ItemIconNew" then
		local itemTid = self._Honor_Template.GuildShopItems[index].ItemId
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL)
	elseif id == "Guild_Fund_List" and id_btn == "ItemIconNew" then
		local itemTid = self._Fund_Template._Items[index].ItemId
		CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL)
	end
end

-- 初始化模板信息等
def.method().OnInit = function(self)
	self._Honor_Template = CElementData.GetTemplate("GuildShop", self._Honor_Tid)
	self._Fund_Template = CElementData.GetTemplate("GuildShop", self._Fund_Tid)
    self._TabList:SetItemCount(1)
    self._TabList:SetSelection(0,0)
--	GUI.SetText(self._Lab_List1, self._Honor_Template.Name)
--	GUI.SetText(self._Lab_List2, self._Fund_Template.Name)

	-- self:OnShowMoney()
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.GuildShop)
    self._TabList = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)
	-- self._Img_Diamond = self:GetUIObject("Img_Diamond")
	-- self._Lab_Diamond = self:GetUIObject("Lab_Diamond")
	-- self._Img_Diamond_Lock = self:GetUIObject("Img_Diamond_Lock")
	-- self._Lab_Diamond_Lock = self:GetUIObject("Lab_Diamond_Lock")
--	self._Img_D0 = self:GetUIObject("Img_D0")
--	self._Lab_List1 = self:GetUIObject("Lab_List1")
--	self._Img_D1 = self:GetUIObject("Img_D1")
--	self._Lab_List2 = self:GetUIObject("Lab_List2")
	self._Frame_Guild_Honor = self:GetUIObject("Frame_Guild_Honor")
	self._Guild_Honor_List = self:GetUIObject("Guild_Honor_List"):GetComponent(self._List_Type)
	self._Frame_Guild_Fund = self:GetUIObject("Frame_Guild_Fund")
	self._Guild_Fund_List = self:GetUIObject("Guild_Fund_List"):GetComponent(self._List_Type)
end

-- 展示货币
-- def.method().OnShowMoney = function(self)
	-- GUITools.SetTokenMoneyIcon(self._Img_Diamond, self._Money_Contribute_Tid)
	-- GUI.SetText(self._Lab_Diamond, tostring(game._GuildMan:GetMoneyValueByTid(self._Money_Contribute_Tid)))
	-- GUITools.SetTokenMoneyIcon(self._Img_Diamond_Lock, self._Money_Honor_Tid)
	-- GUI.SetText(self._Lab_Diamond_Lock, tostring(game._GuildMan:GetMoneyValueByTid(self._Money_Honor_Tid)))
-- end

-- 展示荣誉商店
def.method().ShowHonorShop = function(self)
	self._Frame_Guild_Honor:SetActive(true)
	self._Frame_Guild_Fund:SetActive(false)

	-- self:OnShowMoney()
end

-- 展示资金商店
def.method("number").ShowFundShop = function(self, fund)
	self._Frame_Guild_Honor:SetActive(false)
	self._Frame_Guild_Fund:SetActive(true)

	-- self:OnShowMoney()
end

-- 购买商店物品
def.method("number", "number", "number").OnC2SGuildShopBuyItem = function(self, shopID, itemID, buyNum)
	local protocol = (require "PB.net".C2SGuildShopBuyItem)()
	protocol.ShopID = shopID
	protocol.ItemID = itemID
	protocol.BuyNum = buyNum
	PBHelper.Send(protocol)
end

CPanelUIGuildShop.Commit()
return CPanelUIGuildShop