
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelLottery = Lplus.Extend(CPanelBase, 'CPanelLottery')
local CElementData = require "Data.CElementData"
local EItemQuality = require "PB.Template".Item.ItemQuality
local def = CPanelLottery.define
 
def.field("userdata")._FrameItem1 = nil 
def.field("userdata")._FrameItem2 = nil 
def.field("userdata")._ListItem1 = nil 
def.field("userdata")._ListItem2 = nil 
def.field("userdata")._FrameShow = nil 

def.field("table")._AllItemData = BlankTable
def.field('number')._UseItemId = 0
def.field("number")._ProfMask = 0
def.field("boolean")._IsRewardItem = false
def.field("table")._MoneyItems = BlankTable
def.field("number")._CurPage = 0
def.field('number')._TotalPage = 0
def.field("number")._TimerID = 0

local instance = nil
def.static('=>', CPanelLottery).Instance = function ()
    if not instance then
        instance = CPanelLottery()
        instance._PrefabPath = PATH.UI_Lottery
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        -- instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

local function sortfunction1(item1, item2)
    if item1.Id == 0 then
        return false
    end
    if item2.Id == 0 then
        return true
    end

    local profMask = instance._ProfMask 

    if item1.ProfessionMask == profMask and item2.ProfessionMask == profMask then
        if item1.SortId == item2._SortId then
            return item1.Slot < item2.Slot
        else
            return item1.SortId > item2.SortId
        end
    elseif item1.ProfessionMask == profMask then
        return true
    elseif item2.ProfessionMask == profMask then
        return false
    else
        if item1.SortId == item2.SortId then
            return item1.Slot < item2.Slot
        else
            return item1.SortId > item2.SortId
        end
    end
end

local function sortfunction2(item1,item2)
    return item1.Id < item2.Id
end

def.override().OnCreate = function(self)
    self._ListItem1 = self:GetUIObject("List_Item1"):GetComponent(ClassType.GNewList)
    self._ListItem2 = self:GetUIObject("List_Item2"):GetComponent(ClassType.GNewList)
    self._FrameItem2 = self:GetUIObject("Frame_Item2")
    self._FrameItem1 = self:GetUIObject("Frame_Item1")
    self._FrameShow = self:GetUIObject("Frame_Show")
    self._ProfMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof] 
end

--彩票界面（通用获得界面）
--界面参数(或为空)
-- panelData = 
--             {
--                 IsFromRewardTemplate = false,
--                 ListItem = {},
--                 MoneyList = {},
--             }
def.override("dynamic").OnData = function(self, data)
    --warn("debug.traceback",debug.traceback())

	if self:InitData(data) then
		--self:InitData(data)
		-- self:ShowMoneyTopTip()
		self._CurPage = 1
		self:CreateItem()
		do  --UI特效添加 
			local img_Point = self._FrameShow:FindChild("Frame_Bg")
			GameUtil.PlayUISfx(PATH.UIFX_Lottery_BGFX, img_Point, img_Point, -1)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_LottertOpen, 0)
		end
	else
		self:Close()
	end
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_Close" then 
        if self._TotalPage == self._CurPage then 
            game._GUIMan:CloseByScript(self)
        else
            self._FrameShow:SetActive(false)
            self:ChangePage()
        end
    end
end

local function PileItem(self,item)
    local itemId = item.ItemId 
    
    local itemCount = item.Count 
    local temp = CElementData.GetItemTemplate(itemId)
    if temp.PileLimit > 1 then 
        local isHaven = false
        if #self._AllItemData > 0 then 
            for j,itemData in ipairs(self._AllItemData) do 
                if itemData.Id  == itemId and itemData.Count < temp.PileLimit then
                    isHaven = true
                    itemData.Count = itemData.Count + itemCount
                    if itemData.Count > temp.PileLimit then 
                        local count = itemData.Count - temp.PileLimit
                        itemData.Count = temp.PileLimit
                        local template = CElementData.GetItemTemplate(itemId)
                        local item = 
                        {
                            Id = itemId,
                            Count = count,
                            SortId = template.SortId,
                            ProfessionMask = template.ProfessionLimitMask,
                            Slot = template.Slot,
                            InitQuality = template.InitQuality,
                            TextDisplayName = template.TextDisplayName
                        }
                        table.insert(self._AllItemData,item)
                    end
                    break
                end
            end
        end
        if not isHaven then 
            local template = CElementData.GetItemTemplate(itemId)
            local item = 
            {
                Id = itemId,
                Count = itemCount,
                SortId = template.SortId,
                ProfessionMask = template.ProfessionLimitMask,
                Slot = template.Slot,
                InitQuality = template.InitQuality,
                TextDisplayName = template.TextDisplayName
            }
            table.insert(self._AllItemData,item)
        end
    else
        local template = CElementData.GetItemTemplate(itemId)
        local item = 
        {
            Id = itemId,
            Count = itemCount,
            SortId = template.SortId,
            ProfessionMask = template.ProfessionLimitMask,
            Slot = template.Slot,
            InitQuality = template.InitQuality,
            TextDisplayName = template.TextDisplayName
        }
        table.insert(self._AllItemData,item)
    end
end

local function PileMoney(self,moneyItem)
    if #self._MoneyItems > 0 then 
        local isHaven = false
        for j,moneyData in ipairs(self._MoneyItems) do 
            if moneyData.Id  == moneyItem.MoneyId then
                isHaven = true
                moneyData.Count = moneyData.Count + moneyItem.Count
                break
            end
        end 
        if not isHaven then 
            local moneyTemp = CElementData.GetMoneyTemplate(moneyItem.MoneyId)
            local money = 
            {
                Id = moneyItem.MoneyId,
                Count = moneyItem.Count,
                InitQuality = moneyTemp.Quality,
                TextDisplayName = moneyTemp.TextDisplayName
            }
            table.insert(self._MoneyItems,money)
        end
    else
        local moneyTemp = CElementData.GetMoneyTemplate(moneyItem.MoneyId)
        local money = 
        {
            Id = moneyItem.MoneyId,
            Count = moneyItem.Count,
            InitQuality = moneyTemp.Quality,
            TextDisplayName = moneyTemp.TextDisplayName
        }
        table.insert(self._MoneyItems,money)
    end
end

-- 初始化数据
def.method("table","=>","boolean").InitData = function (self,data)
    self._AllItemData = {}
    -- self._MoneyItems = {}
    if data.IsFromRewardTemplate then
       -- 暂无
    else
        if #data.ListItem == 0 and #data.MoneyList == 0 then 
            --game._GUIMan:CloseByScript(self)
			return false
		end
        if #data.MoneyList ~= 0 then 
            self._MoneyItems = {}
            for i,item in ipairs(data.MoneyList) do 
               PileMoney(self,item)
            end
        end
        if #data.ListItem ~= 0 then
            for i,item in ipairs(data.ListItem) do 
                PileItem(self,item)
                -- self._AllItemData[#self._AllItemData + 1] = {}
                -- self._AllItemData[#self._AllItemData].Id= item.ItemId
                -- local template = CElementData.GetItemTemplate(self._AllItemData[#self._AllItemData].Id)
                -- self._AllItemData[#self._AllItemData].Count = item.Count
                -- if template == nil then return end
                -- self._AllItemData[#self._AllItemData].SortId = template.SortId
                -- self._AllItemData[#self._AllItemData].ProfessionMask = template.ProfessionLimitMask
                -- self._AllItemData[#self._AllItemData].Slot = template.Slot
                -- self._AllItemData[#self._AllItemData].InitQuality = template.InitQuality
                -- self._AllItemData[#self._AllItemData].TextDisplayName = template.TextDisplayName
            end
        end
    end
    if #self._AllItemData >= 2 then 
        table.sort(self._AllItemData , sortfunction1)
    end
    local count = #self._AllItemData + #self._MoneyItems
    self._TotalPage = math.floor(count / 10)
    if count % 10 ~= 0 then 
        self._TotalPage = self._TotalPage + 1
    end

	return true
end

def.method("table").SetCurPage = function (self,data)
    if data ~= nil then 
        self._CurPage = 1
    else
        self._CurPage = self._CurPage + 1
    end
end

def.method().ShowMoneyTopTip = function (self)
    if self._MoneyItems == nil then return end
    for i,v in ipairs(self._MoneyItems) do
        game._GUIMan:ShowMoveItemTextTips(self._MoneyItems[i].Data.Id,true,self._MoneyItems[i].Data.Count, false)
    end
end

def.method().CreateItem = function (self)
    local count = #self._AllItemData + #self._MoneyItems - (self._CurPage - 1) *10
    if count <= 5 then 
        self._FrameItem1:SetActive(true)
        self._FrameItem2:SetActive(false)
        self._ListItem1:SetItemCount(count)
    elseif count > 10 then
        self._FrameItem1:SetActive(false)
        self._FrameItem2:SetActive(true)
        self._ListItem2:SetItemCount(10)
    else
        self._FrameItem1:SetActive(false)
        self._FrameItem2:SetActive(true)
        self._ListItem2:SetItemCount(count)
    end
end

-- 翻页操作
def.method().ChangePage = function (self)
    if self._TimerID ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0
    end
    local startTime = 1
    local function callback()
        startTime = startTime - 0.5
        if startTime == 0 then 
            self._FrameShow:SetActive(true)
            self._CurPage = self._CurPage + 1
            self:CreateItem()
            _G.RemoveGlobalTimer(self._TimerID)
            self._TimerID = 0
        end
    end
    self._TimerID = _G.AddGlobalTimer(0.5,false,callback)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_Item1" or id == "List_Item2" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local n = (self._CurPage -1) * 10
        local i = n + index + 1
        local  data  = nil
        local frame_icon = uiTemplate:GetControl(0)
        local lab_name = uiTemplate:GetControl(1)
        local itemName = nil 
        if i <= #self._MoneyItems then 
            data = self._MoneyItems[i]
            itemName  = RichTextTools.GetQualityText(data.TextDisplayName,data.InitQuality)

            IconTools.InitTokenMoneyIcon(frame_icon, data.Id, data.Count)
        else
            i = i - #self._MoneyItems
            data = self._AllItemData[i]
            itemName = RichTextTools.GetQualityText(data.TextDisplayName,data.InitQuality)
            if data.isShowInScroll then 
                if self._UseItemId ~= 0 then
                    local strName = RichTextTools.GetHostPlayerNameRichText(false)
                    local strGiftName = RichTextTools.GetItemNameRichText(self._UseItemId,1, false)
                    game._GUIMan:OpenSpecialTopTips(string.format(StringTable.Get(22600),strName,strGiftName,itemName))
                end
            end
            local setting = {
                    [EItemIconTag.Number] = data.Count,
                }
            IconTools.InitItemIconNew(frame_icon, data.Id, setting, EItemLimitCheck.AllCheck)
        end
        GUI.SetText(lab_name, itemName)
       
        do  --UI特效添加
            local img_Point = uiTemplate:GetControl(2)
            GameUtil.PlayUISfx(PATH.UIFX_Lottery_ItemShow, img_Point, img_Point, -1)
            if data.InitQuality == EItemQuality.Suit then
                GameUtil.PlayUISfx(PATH.UIFX_Lottery_PurpleItemFX, img_Point, img_Point, -1)
            elseif data.InitQuality == EItemQuality.Legend then
                GameUtil.PlayUISfx(PATH.UIFX_Lottery_OrangeItemFX, img_Point, img_Point, -1)
            elseif data.InitQuality == EItemQuality.Origin then
                GameUtil.PlayUISfx(PATH.UIFX_Lottery_RedItemFX, img_Point, img_Point, -1)
            end
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Item1" or id == "List_Item2" then 
        local n = (self._CurPage -1) * 10
        local i = n + index + 1
        if i <= #self._MoneyItems then 
            local panelData = 
                {
                    _MoneyID = self._MoneyItems[i].Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item ,   
                }
            CItemTipMan.ShowMoneyTips(panelData)
        else
            i = i - #self._MoneyItems
            local itemTemplate = CElementData.GetItemTemplate(self._AllItemData[i].Id)
            local normalPack = game._HostPlayer._Package._NormalPack
            local itemData =  normalPack:GetItem(self._AllItemData[i].Id)
            if itemData ~= nil then
                if itemData:IsEquip() then 
                    CItemTipMan.ShowPackbackEquipTip(itemData, TipsPopFrom.WithoutButton,TipPosition.FIX_POSITION,item)
                else
                    CItemTipMan.ShowPackbackItemTip(itemData, TipsPopFrom.OTHER_PANEL,TipPosition.FIX_POSITION,item)
                end
            else
                CItemTipMan.ShowItemTips(self._AllItemData[i].Id,TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION) 
            end
        end
    end
end

def.override().OnDestroy = function(self)
    self._TotalPage = 0 
    self._CurPage = 0
    self._AllItemData = nil
    if self._TimerID ~= 0 then 
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0 
    end 

    self._FrameItem1 = nil
    self._FrameItem2 = nil
    self._ListItem1 = nil
    self._ListItem2 = nil
    self._FrameShow = nil
    
    instance = nil
end

CPanelLottery.Commit()
return CPanelLottery