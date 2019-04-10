local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local ExpUpdateEvent = require "Events.ExpUpdateEvent"
local NotifyPropEvent = require "Events.NotifyPropEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CUIModel = require "GUI.CUIModel"
local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
local CDressMan = require "Dress.CDressMan"
local EquipChangeCompleteEvent = require "Events.EquipChangeCompleteEvent"
local ShowDressEvent = require "Events.ShowDressEvent"
local CPageBag = require"GUI.CPageBag"
local CPageProperty = require"GUI.CPageProperty"
local CPageReputation = require"GUI.CPageReputation"
local PackageChangeEvent = require "Events.PackageChangeEvent"
local MapBasicConfig = require "Data.MapBasicConfig" 
local CTransManage = require "Main.CTransManage"
local EResourceType = require "PB.data".EResourceType
local CloseTipsEvent = require "Events.CloseTipsEvent"
local PBHelper = require "Network.PBHelper"
local CPanelDesignation = require "GUI.CPanelDesignation"

local CPanelRoleInfo = Lplus.Extend(CPanelBase, "CPanelRoleInfo")
local def = CPanelRoleInfo.define

def.field("userdata")._ImgBg = nil 
def.field('userdata')._Img_Role = nil
def.field(CUIModel)._Model4ImgRender1 = nil
def.field(CFrameCurrency)._Frame_Money = nil
-- def.field("userdata")._Frame_Role = nil 
def.field("userdata")._FrameTopTabs = nil 
def.field("userdata")._Page_Property = nil
def.field("userdata")._Page_Bag = nil 
def.field("userdata")._Page_Strong = nil 
def.field("userdata")._Frame_RoleLeft = nil
def.field("userdata")._FrameModel = nil 
def.field("userdata")._ImgDressOpen = nil 
def.field("userdata")._ImgDressClose = nil 
def.field("userdata")._BldExp = nil 
def.field("userdata")._TitleRedPoint = nil 
def.field("userdata")._Equipment = nil 
def.field("userdata")._CurrentSelectedItem = nil 
def.field("userdata")._LabTitle = nil 

-- 数据
def.field("table")._PanelObject = BlankTable
def.field("table")._Frame_Bag = BlankTable
def.field("boolean")._IsBaseProperty = true
def.field('boolean')._InCombatState = false
def.field("number")._CurPageType = 0
def.field("table")._BtnList = BlankTable
def.field("boolean")._IsByNPCOpenStorage = false
def.field("table")._StrongData = nil
def.field("number")._CurrentSelectEquipIndex = 0
def.field("boolean")._IsOpenDecompose = false
def.field("number")._ItemId = 0                 -- 通过Tip的获取途径直接打开背包选中物品对应的类型

--页签不能改
local PageType = 
{
    PROPERTY = 0,   -- 属性
    BAG = 1,        -- 背包
    STRONG = 2,     -- 养成
}
def.const("table").PageType = PageType
def.method("number").SetPageType = function (self, type)
    self._CurPageType = type
    if type == PageType.PROPERTY then
        self._HelpUrlType = HelpPageUrlType.Property
        GUI.SetText(self._LabTitle,StringTable.Get(21511))
    elseif type == PageType.BAG then
        self._HelpUrlType = HelpPageUrlType.Bag
        GUI.SetText(self._LabTitle,StringTable.Get(21512))
    else
        self._HelpUrlType = HelpPageUrlType.Strong
        GUI.SetText(self._LabTitle,StringTable.Get(21513))
    end
end

local instance = nil
def.static("=>",CPanelRoleInfo).Instance = function ()
    if instance == nil then 
        instance = CPanelRoleInfo()
        instance._PrefabPath = PATH.UI_RoleInfoNew
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
    end
    return instance
end

local OnExpUpdateEvent = function(sender,event)
    if instance ~= nil and instance:IsShow() then
        if instance._CurPageType ~= PageType.PROPERTY then return end
        CPageProperty.Instance():UpdateExp()
    end
end

local OnCustomImgChangeEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        if game._HostPlayer._ID == event._EntityId then
            CPageProperty.Instance():UpdateCustomHead()
        end
    end
end

local OnEntityNameChangeEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        if game._HostPlayer._ID == event._EntityId then
            instance:UpdateHostName()
        end
    end
end

local OnNotifyPropEvent = function(sender, event)
    if game._HostPlayer._ID == event.ObjID and instance ~= nil and instance:IsShow() then
        instance:UpdateEquipmenAndFight()
        if instance._CurPageType == PageType.PROPERTY then 
            CPageProperty.Instance():UpdateDatePropertyValue()
        end

        -- if event.Type == "TitleName" then
        --     CPageProperty.Instance():UpdateTitle()
        -- end
    end
end

local function UpdateUIModel(panel)
    if panel ~= nil and panel._Panel ~= nil then
        local uiModel = panel._Model4ImgRender1
        if uiModel ~= nil then
            GUITools.HostUIModelUpdate(uiModel)
        end
    end
end

-- 装备更新
local OnModelChangedEvent = function(sender, event)
    if instance ~= nil then
        UpdateUIModel(instance)
    end
end

-- 时装更新
local OnDressChangedEvent = function(sender, event)
    if instance ~= nil then
        UpdateUIModel(instance)
    end
end

local OnPackageChangeEvent = function(sender, event)
    if instance ~= nil then
        if instance._Panel == nil then return end
        instance:UpdateEquipmenAndFight()
        if instance._CurPageType ~= PageType.BAG then return end
        CPageBag.Instance():UpdateBag(event.PackageType,event.DecomposedSlots)
    end
end

local OnCloseTipsEvent = function(sender, event)
    if instance ~= nil and instance._Panel ~= nil then
        instance:CleanBorder()
        instance ._CurrentSelectedItem = nil 
    end 
end

local function GetBetterFightEquipFromBag(self,curFight,itemData)
    local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
    local equipItem = nil
    local fight = 0
    local bagPack = game._HostPlayer._Package._NormalPack._ItemSet
    for j, bagItem in ipairs(bagPack) do
        if bagItem:IsEquip() and game._HostPlayer._InfoData._Level >= bagItem._Template.MinLevelLimit
            and profMask == bit.band(bagItem._Template.ProfessionLimitMask, profMask)
            and bagItem._EquipSlot == itemData._Slot then 
            fight = bagItem:GetFightScore()
            if curFight < fight then 
                curFight = fight
                equipItem = {}
                equipItem._Slot = itemData._Slot
                equipItem._BagSlot = bagItem._Slot
                equipItem._Template = bagItem._Template
                equipItem._Tid = bagItem._Tid
                equipItem._IsBind = bagItem:IsBind()
                equipItem._PackageType = bagItem._PackageType
            end
        end
    end
    return equipItem ,curFight
end

-- 扫描背包找到战力更强的装备组成新包
local function GetBestEquipGroup(self)
    local itemSet = game._HostPlayer._Package._EquipPack._ItemSet
    local newEquipBack = {}
    local newFightValue = game._HostPlayer:GetHostFightScore()
    local curEquipFight = 0
    local equipItem = nil 
    local fight = 0
    for i,itemData in ipairs(itemSet) do 
        if itemData._Tid > 0 then 
            curEquipFight = itemData:GetFightScore()
            equipItem,fight = GetBetterFightEquipFromBag(self,curEquipFight,itemData)
        else
            -- 未穿戴
            curEquipFight = 0
            equipItem,fight = GetBetterFightEquipFromBag(self,0,itemData)
        end
        -- 减掉原来的 加上更换后的
        if equipItem ~= nil then 
            newFightValue = newFightValue  - curEquipFight + fight
            table.insert(newEquipBack,equipItem)
        else
            table.insert(newEquipBack,itemData)
        end
    end
    return newEquipBack,newFightValue
end

def.override().OnCreate = function(self)
    if IsNil(self._Panel) then return end
    self._PanelObject = 
    {
        Frame_Property = {},            --属性
        Frame_Bag = {},                 --背包
        Frame_Reputation = {},          --声望
        Frame_Strong = {},              --养成
    }
    
    self._ImgBg = self:GetUIObject("Img_BG")
    self._FrameModel = self:GetUIObject("Frame_Model")
    self._Img_Role = self:GetUIObject("Img_Role")
    self._Frame_RoleLeft = self:GetUIObject("Frame_RoleLeft")
    self._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
    self._LabTitle = self:GetUIObject("Lab_Title")
    self._Page_Property = self:GetUIObject("Page_Property")
    self._Page_Bag = self:GetUIObject("Page_Bag")
    -- self._Page_Strong = self:GetUIObject("Page_Strong")

    self._ImgDressOpen = self:GetUIObject("Img_DressOpen")
    self._ImgDressClose = self:GetUIObject("Img_DressClose")
     -- 称号红点
    self._TitleRedPoint = self:GetUIObject("Img_RedPoint") 
    self._Equipment = self:GetUIObject("Equipment")

    self:GetUIObject("Btn_Head"):SetActive(false)

    --人物背后特效
    GameUtil.PlayUISfx(PATH.UI_bj_effect, self._ImgBg, self._FrameModel, -1)

    -- 装备槽
    for k, v in pairs(EnumDef.RoleEquipImg2Slot) do
        local frame_item_icon = self:GetUIObject(k)
        local setting =
        {
            [EFrameIconTag.EmptyEquip] = v,
            [EFrameIconTag.Select] = false,
        }
        IconTools.SetFrameIconTags(frame_item_icon, setting)
    end
        
    -- 属性
    do
        local info = self._PanelObject.Frame_Property
        info.root = self._Page_Property
        info._RoleDataInfoList = self:GetUIObject("Sub_List1")
        info._FrameDetailInfo = self:GetUIObject("Frame_DetailInfo")
        info._FrameBaseInfo = self:GetUIObject("Frame_BaseInfo")
        info._ImgHead = self:GetUIObject('Img_Head')
        info._LabLevel = self:GetUIObject("Lab_Level_Data")
        info._LabGuild = self:GetUIObject("Lab_Guild_Data_")
        -- info._LabTitle = self:GetUIObject("Lab_Title_Data")
        info._BldExp = self:GetUIObject("Bld_Exp"):GetComponent(ClassType.Slider)
        info._LabJob = self:GetUIObject("Lab_Job")
        info._LabBldExp = self:GetUIObject("Lab_BldExp")
        info._BtnTitle = self:GetUIObject("Btn_Title")
        info._ImgLittleBG1 = self:GetUIObject("Img_LittleBG1")
        info._ImgLittleBG2 = self:GetUIObject("Img_LittleBG2")
        info._ImgLittleBG3 = self:GetUIObject("Img_LittleBG3")
        info._ImgLittleBG4 = self:GetUIObject("Img_LittleBG4")
        info._TipPosition = self:GetUIObject("TipPosition")
        info._LabEvilValue = self:GetUIObject("Lab_GoodAndEvil")
        info._ImgUpArrow = self:GetUIObject("Img_IconUp")
        info._ImgDownArrow = self:GetUIObject("Img_IconDown")
    end
    
    -- 背包
    do
        local info = self._PanelObject.Frame_Bag
        info.root = self._Page_Bag
        info._ImgBg = self:GetUIObject("Img_BG")
        info._Frame_Bag = self:GetUIObject("Frame_BagItemList")
        info._FrameModel = self:GetUIObject("Frame_Model")
        info._FrameButtons = self:GetUIObject("Frame_R")
        info._FrameRoleLeft = self:GetUIObject("Frame_RoleLeft")
        info._Frame_Storage = self:GetUIObject("Frame_StorageItemList")
        info._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
        info._Frame_Decompose = self:GetUIObject("Frame_Decompose")
        info._FrameBagBottom = self:GetUIObject("Frame_BagBottom")
        info._FrameDecBottom = self:GetUIObject("Frame_DecomposeBottom")
        info._FrameSideTabs = self:GetUIObject("Frame_SideTabs")
        info._ItemListView = self:GetUIObject('List_Item1')
        info._StorageItemList = self:GetUIObject('List_Item2'):GetComponent(ClassType.GNewList)
        info._LabTitle = self:GetUIObject("Lab_Title")
        info._FrameStoItemList = self:GetUIObject('Frame_StorageItemList')
        info._LabNoItem = self:GetUIObject("Lab_NoItem")       
        info._LabLockCell = self:GetUIObject("Lab_LockCell")
        info._ItemsByDecomList = self:GetUIObject("List_Item3"):GetComponent(ClassType.GNewListLoop)
        info._DecomposeListView = self:GetUIObject('List_Item4'):GetComponent(ClassType.GNewListLoop)

        -- 仓库页码
        info._RdoStroToggle = self:GetUIObject("Rdo_Storage")
        info._RdoPage1 = self:GetUIObject("Rdo_1")
        info._RdoPage2 = self:GetUIObject("Rdo_2")
        info._RdoPage3 = self:GetUIObject("Rdo_3")
        info._RdoPage4 = self:GetUIObject("Rdo_4")
        info._RdoPage5 = self:GetUIObject("Rdo_5")
        info._RdoStorage = self:GetUIObject("Rdo_Storage")
        -- 弹出tip的位置
        info._StorageTipPosition = self:GetUIObject("StorageTipPosition")
        info._BagEquipTipsPosition = self:GetUIObject("EquipPositionBag")
        info._BagItemTipsPosition = self:GetUIObject("ItemPositionBag")
        info._RoleTipPosition = self:GetUIObject("RoleEquipTipPosition")
    end
    -- --养成
    -- do
    --     local info = self._PanelObject.Frame_Strong
    --     info.root = self._Page_Strong
    --     info._ImgScore = self:GetUIObject("Img_Score")
    --     info._LabCurFight = self:GetUIObject("Lab_CurFight")
    --     info._LabBasicFight = self:GetUIObject("Lab_BasicFight")
    --     info._TabListMenu = self:GetUIObject("TabList_Menu")
    -- end
end


def.override("dynamic").OnData = function(self,data)
    CGame.EventManager:addHandler("EntityCustomImgChangeEvent", OnCustomImgChangeEvent)
    CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyPropEvent)
    CGame.EventManager:addHandler(ExpUpdateEvent,OnExpUpdateEvent)
    CGame.EventManager:addHandler(EquipChangeCompleteEvent, OnModelChangedEvent)
    CGame.EventManager:addHandler(ShowDressEvent, OnDressChangedEvent)
    CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)	
    CGame.EventManager:addHandler(CloseTipsEvent, OnCloseTipsEvent)
    if self._Frame_Money == nil then
        self:GetUIObject("Frame_Money"):SetActive(true)
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
    self:UpdateHostPlayerTitle()
    self._IsByNPCOpenStorage = false
    self._IsOpenDecompose = false
    self._ItemId = 0
    if data == nil then 
        self:SetPageType(PageType.PROPERTY)
    elseif data ~= nil and data._AppointedOpening ~= nil then--指定开启固定页面(提供给我要变强)
        if data._PageTag == "Rdo_Property" then
            self:SetPageType(PageType.PROPERTY)
        elseif data._PageTag == "Rdo_Bag" then
            self:SetPageType(PageType.BAG)
        elseif data._PageTag == "Rdo_Reputation" then
            self:SetPageType(PageType.REPUTATION)
        else
            self:SetPageType(PageType.PROPERTY)
        end
    elseif data ~= nil and data.IsByNpcOpenStorage ~= nil then
        self:SetPageType(data.PageType)
        self._IsByNPCOpenStorage = data.IsByNpcOpenStorage
        if data.StrongData ~= nil then 
            self._StrongData = data.StrongData
        end
        if data.ItemId ~= nil then 
            self._ItemId = data.ItemId
        end
    elseif data ~= nil and data.IsOpenDecompose ~= nil then
        self:SetPageType(data.PageType)
        self._IsOpenDecompose  = data.IsOpenDecompose
    end
    if self._IsByNPCOpenStorage and game._HostPlayer:GetGloryLevel() < 2 then 
        game._GUIMan:ShowTipText(StringTable.Get(22504),false)
        game._GUIMan:CloseByScript(self)
    return end
    self:InitPanel() 

    --GameUtil.LayoutTopTabs(self._FrameTopTabs)

    CPanelBase.OnData(self, data)
end

def.method().InitPanel = function (self)

    -- 初始化状态数据	
    self._FrameModel:SetActive(true)
    self._Frame_RoleLeft:SetActive(true)
    self._FrameTopTabs:SetActive(true)
    GUITools.SetGroupImg(self._ImgBg,0)
    self:UpdateRoleLeft()
    self:InitPage()
    if self._Model4ImgRender1 == nil then
        self._Model4ImgRender1 = GUITools.CreateHostUIModel(self._Img_Role, EnumDef.RenderLayer.UI, nil)
        
        self._Model4ImgRender1:AddLoadedCallback(function() 
            self._Model4ImgRender1:SetModelParam(self._PrefabPath, game._HostPlayer._InfoData._Prof)
        end)
    end	
    UpdateUIModel(self)
end

def.method().InitPage = function (self)
    GUI.SetGroupToggleOn(self._FrameTopTabs,self._CurPageType + 2)
    if self._CurPageType == PageType.PROPERTY then 
        self._Page_Property:SetActive(true)
        self._Page_Bag:SetActive(false)
        -- self._Page_Strong:SetActive(false)
        GUI.SetText(self._LabTitle,StringTable.Get(21511))
        CPageProperty.Instance():Show(self._PanelObject.Frame_Property,self._PanelObject.Frame_Property.root)
    elseif self._CurPageType == PageType.BAG then 
        self._Page_Property:SetActive(false)
        self._Page_Bag:SetActive(true)
        -- self._Page_Strong:SetActive(false)
        GUI.SetText(self._LabTitle,StringTable.Get(21512))
        CPageBag.Instance():Show(self, self._PanelObject.Frame_Bag,self._PanelObject.Frame_Bag.root,self._IsByNPCOpenStorage,self._IsOpenDecompose,self._ItemId)
        self._ItemId = 0
    end
end

------------------------------------- 更新UI左侧角色信息包括(装备、名字、模型战力等)----------------------------------
def.method().UpdateRoleLeft = function (self)
    self:UpdateEquipmenAndFight()
    if not game._HostPlayer:GetDressEnable() then 
        self._ImgDressClose:SetActive(true)
        self._ImgDressOpen:SetActive(false)
    else
        self._ImgDressClose:SetActive(false)
        self._ImgDressOpen:SetActive(true)
    end
    local info_data = game._HostPlayer._InfoData
    local labName = self:GetUIObject("Lab_RoleName")
    GUI.SetText(labName,game._HostPlayer._InfoData._Name)
    local labLv = self:GetUIObject("Lab_RoleLv")
    GUI.SetText(labLv,string.format(StringTable.Get(21508),info_data._Level))
end

--更新角色身上的装备战力
def.method().UpdateEquipmenAndFight = function(self)
    if self._Panel == nil then return end
    local itemSet = game._HostPlayer._Package._EquipPack._ItemSet

    for _, item in ipairs(itemSet) do
        local frame_item_icon = self:GetUIObject(EnumDef.RoleEquipSlotImg[item._Slot])
        local bGotEquip = item._Tid > 0
        IconTools.SetFrameIconTags(frame_item_icon, { [EFrameIconTag.ItemIcon] = bGotEquip })
        if bGotEquip then
            local setting =
            {
                [EItemIconTag.Refine] = item:GetRefineLevel(),
                [EItemIconTag.StrengthLv] = item:GetInforceLevel(),
                [EItemIconTag.Enchant] = item._EnchantAttr ~= nil and item._EnchantAttr.index ~= 0,
            }
            IconTools.InitItemIconNew(frame_item_icon, item._Tid, setting)
        end
    end
    local labelScore = self._Frame_RoleLeft:FindChild("Img_FighScoreBG/Lab_FightScore_Data")
    GUI.SetText(labelScore, GUITools.FormatMoney(game._HostPlayer:GetHostFightScore()))
end

--刻印更新武器模型特效
def.method().UpdateWeaponFx = function (self)
    if not self:IsShow() then return end
    if self._Model4ImgRender1 ~= nil then 
        GUITools.HostUIModelUpdate(self._Model4ImgRender1)
    end
end

---------------------------------------------------------------------------------------------------
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if self._CurPageType == PageType.BAG then 
        CPageBag.Instance():InitItem(item,id,index)
    elseif self._CurPageType == PageType.REPUTATION then 
        CPageReputation.Instance():InitItem(item, id, index)
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    CPanelBase.OnSelectItem(self,item, id, index)
    if self._CurPageType == PageType.BAG then 
        CPageBag.Instance():SelectItem(item, id, index)
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if self._CurPageType == PageType.REPUTATION then 
        CPageReputation.Instance():SelectItemButton(item, id, id_btn, index)
    elseif self._CurPageType == PageType.BAG then 
        CPageBag.Instance():SelectItemButton(item, id, id_btn, index)
    end
end

def.override('userdata','string','number').OnLongPressItem = function(self, item, id, index)
    if self._CurPageType == PageType.BAG then 
        CPageBag.Instance():LongPressItem(item, id, index)
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "Rdo_Property" and checked then
        CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Bag,false)
        self._ItemId = 0 
        self:SetPageType(PageType.PROPERTY)
        self._Page_Property:SetActive(true)
        self._Page_Bag:SetActive(false)
        GUI.SetText(self._LabTitle,StringTable.Get(21511))

        CPageProperty.Instance():Show(self._PanelObject.Frame_Property,self._PanelObject.Frame_Property.root)
    elseif id == "Rdo_Bag" and checked then
        self:SetPageType(PageType.BAG)
        self._Page_Property:SetActive(false)
        self._Page_Bag:SetActive(true)
        GUI.SetText(self._LabTitle,StringTable.Get(21512))
        local isOpenFromNpc = false
        local isOpenDecompose = false
        CPageBag.Instance():Show(self, self._PanelObject.Frame_Bag,self._PanelObject.Frame_Bag.root,isOpenFromNpc,isOpenDecompose,0)
    end
    if self._CurPageType == PageType.BAG then 
        CPageBag.Instance():OnTogglePageBag(id,checked)
    end
end

def.override("string").OnClick = function(self,id)
    if id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
    elseif id == "Btn_ShowDress"then
        local isShowDress = game._HostPlayer:GetDressEnable()
        if not isShowDress then 
            game._GUIMan:ShowTipText(StringTable.Get(21506),false)
            self._ImgDressOpen:SetActive(true)
            self._ImgDressClose:SetActive(false)
        else
            game._GUIMan:ShowTipText(StringTable.Get(21507),false)
            self._ImgDressOpen:SetActive(false)
            self._ImgDressClose:SetActive(true)
        end
        CDressMan.Instance():C2SShowDress(not isShowDress)
    elseif id == "Btn_ShowDressPanel" then
        local CExteriorMan = require "Main.CExteriorMan"
        if CExteriorMan.Instance():CanEnter() then
            local data =
            {
                Type = EnumDef.CamExteriorType.Armor
            }
            local CExteriorMan = require "Main.CExteriorMan"
            CExteriorMan.Instance():Enter(data)
            --game._GUIMan:CloseByScript(self)	--CBT_UE - 66 返回按钮不返回至上一个菜单，提高了操作疲劳度 
        end
    elseif id == "Btn_EquiptBest" then 
        -- TODO()
     
        local newEquipBack ,newFightValue = GetBestEquipGroup(self)
        if newFightValue == game._HostPlayer:GetHostFightScore() then
            game._GUIMan:ShowTipText(StringTable.Get(312),false)
            return
        end

        local panelData = 
               {
                    NewEquipBack = newEquipBack,
                    NewFightValue = newFightValue,
               }
        game._GUIMan:Open("CPanelEquipChange",panelData)

    elseif id == "Btn_Title" then 
        --TODO("敬请期待")   
        game._GUIMan:Open("CPanelDesignation", nil)
    elseif id == "Btn_ChangeName" then 
        game._GUIMan:Open("CPanelChangeName",nil)
    else
        -- 点击装备栏显示Item的tip
        local slot = EnumDef.RoleEquipImg2Slot[id]
        if slot ~= nil then
            local itemSet = game._HostPlayer._Package._EquipPack._ItemSet
            local itemData = itemSet[slot+1]

            if itemData == nil or itemData._Tid == 0 then return end
            self._CurrentSelectEquipIndex = slot + 1
            local ui_equip = self:GetUIObject(id)
            -- local ui_equip = self._Equipment:FindChild(id)
            itemData:ShowTipWithFuncBtns(TipsPopFrom.ROLE_PANEL,TipPosition.DEFAULT_POSITION,self:GetUIObject("RoleEquipTipPosition"),ui_equip)
            MsgBox.CloseAll()
            self:CleanBorder()
            self._CurrentSelectedItem = ui_equip
            self:ShowBorder(ui_equip)
        end
    end

    if self._CurPageType == PageType.PROPERTY then
        if string.find(id, "Btn_Back") then
            game._GUIMan:Close("CPanelRoleInfo")            
            if CPanelDesignation.Instance():IsShow() then
                game._GUIMan:Close("CPanelDesignation")
            end
        end
        CPageProperty.Instance():Click(id)
    elseif self._CurPageType == PageType.BAG then 
        CPageBag.Instance():Click(id)
    else
        if string.find(id, "Btn_Back") then
            game._GUIMan:Close("CPanelRoleInfo")
            if CPanelDesignation.Instance():IsShow() then
                game._GUIMan:Close("CPanelDesignation")
            end
        end
    end
    CPanelBase.OnClick(self,id)
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
    CPanelBase.OnDOTComplete(self,go_name,dot_id)
    if self._CurPageType == PageType.PROPERTY then  
        CPageProperty.Instance():DOTComplete(go_name, dot_id)
    end
end

--清除格子选中框
def.method().CleanBorder = function(self)
    if not IsNil(self._CurrentSelectedItem) then
        IconTools.SetFrameIconTags(self._CurrentSelectedItem, { [EFrameIconTag.Select] = false })
        -- self._CurrentSelectedItem:FindChild('Img_Select'):SetActive(false)
    end
end

-- 显示选中框
def.method("userdata").ShowBorder = function(self, item)
    if item ~= nil then
        IconTools.SetFrameIconTags(item, { [EFrameIconTag.Select] = true })
        -- local obj = item:FindChild("Img_Select")
        -- if not IsNil(obj) then
        --     obj:SetActive(true)
        -- else
        --     warn("Can not get child at ", item.name)
        -- end
    end
end

def.method("number","=>","boolean").IsCurTypePage = function(self, nType)
    return self._CurPageType == nType
end

def.method().UpdateHostPlayerTitle = function(self)
    --称号
    if not self:IsShow() then return end
    local titleName = game._HostPlayer._InfoData._TitleName
    local isShowTitleRedDot = CRedDotMan.GetModuleDataToUserData("RoleInfo")
    if isShowTitleRedDot == nil then 
        self._TitleRedPoint:SetActive(false)
    else
        self._TitleRedPoint:SetActive(true)
        CRedDotMan.DeleteModuleDataToUserData("RoleInfo")
    end
end

def.method().UpdateBagSortType = function(self)
    if self:IsShow() and self._CurPageType == PageType.BAG then 
        CPageBag.Instance():UpdateSort()
    end
end

def.method().UpdateHostName = function(self)
    if self:IsShow() then 
        GUI.SetText(self:GetUIObject("Lab_RoleName"),game._HostPlayer._InfoData._Name)
    end
end

def.method().SetDecomposeFilter = function (self)
    if self:IsShow() and self._CurPageType == PageType.BAG then
        CPageBag.Instance():SetDecomposeFilter()
    end
end

def.method().AddDecomposeTimer = function(self)
    CPageBag.Instance():AddDecomposeTimer()
end

def.method().S2CBagUnlockCell = function(self)
    CPageBag.Instance():UpdateUnlockCell()
end

def.method("number").S2CDecItem = function(self,errorCode)
    if self:IsShow() and self._CurPageType == PageType.BAG then 
        CPageBag.Instance():S2CDecompose(errorCode)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:SetPageType(-1)
    self._BtnList = {}
    self._StrongData = nil 
    self._CurrentSelectEquipIndex = 0 
    self._CurrentSelectedItem = nil 
    self._ItemId = 0 
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)	
    CGame.EventManager:removeHandler("EntityCustomImgChangeEvent", OnCustomImgChangeEvent)
    CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyPropEvent)
    CGame.EventManager:removeHandler(EquipChangeCompleteEvent, OnModelChangedEvent)
    CGame.EventManager:removeHandler(ShowDressEvent, OnDressChangedEvent)
    CGame.EventManager:removeHandler(CloseTipsEvent, OnCloseTipsEvent)
    CGame.EventManager:removeHandler(ExpUpdateEvent,OnExpUpdateEvent)
    CPageBag.Instance():Hide()
    CPageProperty.Instance():Hide()
    CPageReputation.Instance():Hide()
    if self._Model4ImgRender1 ~= nil  then
        self._Model4ImgRender1:Destroy()		
        self._Model4ImgRender1 = nil
    end
end

def.override().OnDestroy = function(self)
    CPageReputation.Instance():Destroy()
    CPageBag.Instance():Destroy()
    CPageProperty.Instance():Destroy()
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    instance = nil
end

CPanelRoleInfo.Commit()
return CPanelRoleInfo