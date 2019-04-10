local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'

local CElementData = require "Data.CElementData"
local CTokenMoneyMan = require "Data.CTokenMoneyMan"
local CPetUtility = require "Pet.CPetUtility"
local CFrameCurrency = require "GUI.CFrameCurrency"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CUIModel = require "GUI.CUIModel"

local CPagePetInfo = require "Pet.CPagePetInfo"
local CPagePetCultivate = require "Pet.CPagePetCultivate"
local CPagePetAdvance = require "Pet.CPagePetAdvance"
local CPagePetRecast = require "Pet.CPagePetRecast"
local CPagePetSkill = require "Pet.CPagePetSkill"

local PetRetDotUpdateEvent = require "Events.PetRetDotUpdateEvent"

local CPanelUIPetProcess = Lplus.Extend(CPanelBase, 'CPanelUIPetProcess')
local def = CPanelUIPetProcess.define

def.field("table")._PanelObject = BlankTable                -- 存储界面节点的集合
def.field(CFrameCurrency)._Frame_Money = nil                -- 金币通用组件
def.field("userdata")._ItemList = nil                       -- 背包列表

def.field("table")._AllLocalItemList = BlankTable           -- 本地全部数据结构
def.field("table")._LocalItemList = BlankTable              -- 本地数据结构
def.field("table")._ProcessFrames = BlankTable              -- 加工的界面集合
def.field("table")._PageToggleList = BlankTable             -- 右侧功能栏toggle的集合
def.field("table")._PageRedDotList = BlankTable             -- 右侧功能栏红点的集合

def.field("number")._CurrentPage = 0                        -- 当前选择的界面
def.field("table")._CurrentSelectInfo = BlankTable          -- 当前选择物品的Index,object
def.field("number")._CurrentSortQuality = -1                -- 当前筛选品质
def.field("table")._ItemData = nil                          -- 当前选中Item
def.field("table")._PetItemData = nil                       -- 当前正在设置的宠物item的data
def.field(CUIModel)._UIModel = nil                          -- 当前的宠物model

def.field("userdata")._CurAdvanceMeterialPetItem = nil      -- 当前升星选中的材料宠Item(背包列表)
def.field("table")._PetItemList = BlankTable                -- 存储宠物背包Item列表
def.field("number")._CurAdvanceMeterialPetId = 0            -- 当前升星选中的材料宠Id

def.field("number")._TimerID = 0        -- timer
def.field("number")._Interval = 1       -- tick时间差
def.field("number")._TimeDelay = 15 

local listQuality = 
{
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
}

local instance = nil
def.static('=>', CPanelUIPetProcess).Instance = function ()
    if not instance then
        instance = CPanelUIPetProcess()
        instance._PrefabPath = PATH.UI_PetProcess
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

-- 刷新宠物红点
local function OnPetRetDotUpdateEvent(sender, event)
    if instance == nil then return end
    instance:UpdatePageRedDotState()
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end
    if EPetOptType.EPetOptType_levelup == event._Type then              --升级
        instance:UpdateSortList()
        instance:SyncSelectItemData()
        instance:UpdateCommonUI()
        instance:FixSelectInfo()
        
        instance:UpdateItemList()
        instance:PlayLevelupAni()
        instance:UpdateSelectPet()
        instance:UpdateSetFightRedDotState()
        instance._ProcessFrames[EnumDef.UIPetPageState.PageCultivate]:ShowLevelUpGfx()

    elseif EPetOptType.EPetOptType_petBagCell == event._Type then       --格子变化
        instance:UpdatePackageSize()

    elseif EPetOptType.EPetOptType_free == event._Type then             --放生
        instance:SyncPackageData()
        instance:UpdateSortList()
        instance:ResetSelectItem()
        instance:SetDefultSelectInedx()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:UpdateSelectPet()
        GameUtil.PlayUISfx(PATH.UIFX_ITEM_END,instance._Panel, instance._Panel, -1)

    elseif EPetOptType.EPetOptType_advance == event._Type then          --进阶
        instance:SyncPackageData()
        instance:UpdateSortList()
        instance:SyncSelectItemData()
        instance:UpdateCommonUI()
        instance:FixSelectInfo()

        instance:UpdateItemList()
        instance:PlayLevelupAni()
        instance:UpdateSelectPet()
        instance:UpdateSetFightRedDotState()
        --将升星结果 界面改为在S2CPetUpdate 打开，当该界面关闭后 广播消息更新CPanelUIProcess界面
        -- game._GUIMan:Open("CPanelCommonConltivate", instance._ItemData)
    elseif EPetOptType.EPetOptType_talent == event._Type then           --被动技能学习
        instance:SyncSelectItemData()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:UpdateSelectPet()
        instance._ProcessFrames[EnumDef.UIPetPageState.PageSkill]:PlaySkillLeanGfx()
        instance:UpdateSetFightRedDotState()

    elseif EPetOptType.EPetOptType_confirmRecast == event._Type then    --重铸确认
        instance:SyncSelectItemData()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:UpdateSelectPet()

    elseif EPetOptType.EPetOptType_rest == event._Type then             --休息
        instance:UpdateItemList()
        instance:UpdateSetFightRedDotState()
        instance:UpdateSelectPet()
    elseif EPetOptType.EPetOptType_fight == event._Type then            --出战
        instance:SyncPackageData()
        instance:UpdateSortList()
        instance:ResetSelectItem()
        instance:SetDefultSelectInedx()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:UpdateSelectPet()
        
        instance:UpdateSetFightRedDotState()

    elseif EPetOptType.EPetOptType_help == event._Type then             --助战
        instance:SyncPackageData()
        instance:UpdateSortList()
        instance:ResetSelectItem()
        instance:SetDefultSelectInedx()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:UpdateSelectPet()
        
        instance:UpdateSetFightRedDotState()

    elseif EPetOptType.EPetOptType_reName == event._Type then           --重命名
        instance:UpdateCommonUI()
        instance:UpdateItemList()

    elseif EPetOptType.EPetOptType_ResetRecastCount == event._Type then --重置洗练次数
        instance:SyncSelectItemData()
        instance:UpdateCommonUI()
        instance:UpdateItemList()
        instance:PlayLevelupAni()
        instance:UpdateSelectPet()
    end
end

def.override().OnCreate = function(self)
    self._ProcessFrames = {}
    self._ProcessFrames[EnumDef.UIPetPageState.PagePetInfo] = CPagePetInfo.new(self, self:GetUIObject("Frame_PetInfo"))
    self._ProcessFrames[EnumDef.UIPetPageState.PageCultivate] = CPagePetCultivate.new(self, self:GetUIObject("Frame_Cultivate"))
    self._ProcessFrames[EnumDef.UIPetPageState.PageAdvance] = CPagePetAdvance.new(self, self:GetUIObject("Frame_Advance"))
    self._ProcessFrames[EnumDef.UIPetPageState.PageRecast] = CPagePetRecast.new(self, self:GetUIObject("Frame_Recast"))
    self._ProcessFrames[EnumDef.UIPetPageState.PageSkill] = CPagePetSkill.new(self, self:GetUIObject("Frame_Skill"))

    self._PageToggleList = {}
    self._PageToggleList[EnumDef.UIPetPageState.PagePetInfo] = self:GetUIObject('Rdo_PetInfo'):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIPetPageState.PageCultivate] = self:GetUIObject('Rdo_Cultivate'):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIPetPageState.PageAdvance] = self:GetUIObject('Rdo_Advance'):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIPetPageState.PageRecast] = self:GetUIObject('Rdo_Recast'):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIPetPageState.PageSkill] = self:GetUIObject('Rdo_Skill'):GetComponent(ClassType.Toggle)

    self._PageRedDotList = {}
    self._PageRedDotList[EnumDef.UIPetPageState.PageCultivate] = self:GetUIObject('Rdo_Cultivate'):FindChild("Img_RedPoint")
    self._PageRedDotList[EnumDef.UIPetPageState.PageRecast] = self:GetUIObject('Rdo_Recast'):FindChild("Img_RedPoint")
    self._PageRedDotList[EnumDef.UIPetPageState.PageSkill] = self:GetUIObject('Rdo_Skill'):FindChild("Img_RedPoint")
    self:ResetSelectItem()

    -- UI
    self._PanelObject = 
    {
        Lab_PackageSize = self:GetUIObject('Lab_PackageSize'),
        Frame_ShowBoard = {},
    }

    local root = self._PanelObject
    do
        --宠物中间栏（宠物基本信息）
        local Frame_ShowBoard = root.Frame_ShowBoard
        Frame_ShowBoard.Root = self:GetUIObject('Frame_ShowBoard')                  -- 根节点
        Frame_ShowBoard.Lab_NoPetSelect = self:GetUIObject('Lab_NoPetSelect')       -- 没有选择宠物的提示
        Frame_ShowBoard.Model_Pet = self:GetUIObject("Img_Role")                    -- 模型控件
        Frame_ShowBoard.Label_NickName = self:GetUIObject("Label_NickName")         -- 昵称
        Frame_ShowBoard.Lab_Genre = self:GetUIObject('Lab_Genre')                   -- 类型
        Frame_ShowBoard.Img_Genre = self:GetUIObject('Img_Genre')                   -- Image类型
        Frame_ShowBoard.Lab_Level = self:GetUIObject('Lab_Level')                   -- 等级
        Frame_ShowBoard.List_Star = self:GetUIObject("List_Star")                   -- 宠物星级
        Frame_ShowBoard.Lab_FightScore = self:GetUIObject('Lab_FightScore')         -- 战斗力
        Frame_ShowBoard.Lab_QualityValue = self:GetUIObject('Lab_QualityValue')     -- 品阶
        Frame_ShowBoard.Btn_SetFight = self:GetUIObject('Btn_SetFight')             -- 出战设置
        Frame_ShowBoard.Img_BtnFloatFx = Frame_ShowBoard.Btn_SetFight:FindChild("Img_Bg/Img_BtnFloatFx")    -- 出战红点状态
    end

    self._ItemList = self:GetUIObject('List_PetView'):GetComponent(ClassType.GNewListLoop)
    self:SetDorpdownGroup()
    self._HelpUrlType = HelpPageUrlType.Pet
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
--[[
Parameters
----------
data: Table
    外部跳转装备类型, default: nil
    data = 
    {
        UIPetPageState,
        PetData,
    }
]]      
        -- 初始化通用金币
        if self._Frame_Money == nil then
            local Frame_Money = self:GetUIObject("Frame_Money")
            Frame_Money:SetActive(true)
            self._Frame_Money = CFrameCurrency.new(self, Frame_Money, EnumDef.MoneyStyleType.None)
        else
            self._Frame_Money:Update()
        end

        -- 同步背包数据
        self:SyncPackageData()
        -- 排序
        self:UpdateSortList()
        -- 默认初始化 选中Index
        self:SetDefultSelectInedx()

        -- 默认功能页签
        local page = EnumDef.UIPetPageState.PagePetInfo
        if data ~= nil and data.UIPetPageState ~= nil then
            page = data.UIPetPageState
            self._PageToggleList[page].isOn = true
        end
        -- 跳转功能页签
        self:ChangePage(page)

        -- 更新宠物背包列表
        self:UpdateItemList()

        -- 刷新通用UI界面
        self:UpdateCommonUI()
        
        -- 刷新红点状态
        self:UpdateSetFightRedDotState()
        self:UpdatePageRedDotState()

        CGame.EventManager:addHandler(PetUpdateEvent, OnPetUpdateEvent)
        CGame.EventManager:addHandler(PetRetDotUpdateEvent, OnPetRetDotUpdateEvent)
        CPanelBase.OnData(self,data)

        GameUtil.PlayUISfx(PATH.UI_bj_effect, self._PanelObject.Frame_ShowBoard.Root, self._PanelObject.Frame_ShowBoard.Model_Pet, -1)
    end
end

def.method().SetDefultSelectInedx = function(self)
    if #self._LocalItemList > 0 then
        self._CurrentSelectInfo.Index = 1
        self._ItemData = self:GetItemDataByIndex(self._CurrentSelectInfo.Index)
    else
        self._ItemData = nil
    end
end

-- 品质过滤器
def.method().QualityFilter = function(self)
    if self._CurrentSortQuality ~= -1 and #self._AllLocalItemList > 0 then
        local quality = self._CurrentSortQuality
        local map = {}
        for i=1, #self._AllLocalItemList do
            local pet = self._AllLocalItemList[i]
            if pet:GetQuality() == quality then
                table.insert(map, pet)
            end
        end
        self._LocalItemList = map
    else
        self._LocalItemList = self._AllLocalItemList
    end
end

-- 矫正Index
def.method().FixSelectInfo = function(self)
    if self._ItemData ~= nil then
        self._CurrentSelectInfo.Index = 0
        
        for i, pet in ipairs(self._LocalItemList) do
            if self._ItemData._ID == pet._ID then
                self._CurrentSelectInfo.Index = i
                break
            end
        end
        
        if self._CurrentSelectInfo.Index > 0 and not self._ItemList:IsListItemVisible(self._CurrentSelectInfo.Index - 1, 1) then
            self._ItemList:ScrollToStep(self._CurrentSelectInfo.Index - 1)
        end
    end
end

def.method("=>", "string").GetQualityGroupStr = function(self)
    local groupStr = StringTable.Get(10010)
    for _, v in ipairs(listQuality) do
        local str = StringTable.Get(10000 + v)
        str = RichTextTools.GetQualityText(str, v)
        groupStr = groupStr .. "," .. str
    end

    return groupStr
end

-- 设置下拉菜单
def.method().SetDorpdownGroup = function(self)
    local Drop_Template = self:GetUIObject("Drop_Template")
    GUITools.SetupDropdownTemplate(self, Drop_Template)

    local groupStr = self:GetQualityGroupStr()
    GUI.SetDropDownOption(self:GetUIObject('DropDown_Down'), groupStr)
end

-- 刷新通用UI界面
def.method().UpdateCommonUI = function(self)
    -- 更新背包数量信息
    self:UpdatePackageSize()
    -- 更新通用信息显示
    self:UpdateShowBoard()
    --更新模型
    self:UpdateModel()
end

-- 更新背包数量信息
def.method().UpdatePackageSize = function(self)
--warn("UpdatePackageSize...")
    local hp = game._HostPlayer
    local root = self._PanelObject
    local curSize = #self._LocalItemList
    local maxSize = hp._PetPackage:GetEffectSize()

    local str = string.format(StringTable.Get(19069), curSize, maxSize)
    GUI.SetText(root.Lab_PackageSize, str)
end

def.method().CollectLocalItemList = function(self)
    self._AllLocalItemList = {}
    self._LocalItemList = {}
    local petPackage = game._HostPlayer._PetPackage

    if petPackage:GetListCount() > 0 then
        self._AllLocalItemList = clone(petPackage:GetList())
        self._LocalItemList = self._AllLocalItemList
    end
end

def.method().UpdateSortList = function(self)
    local hp = game._HostPlayer

    -- 出战提最前, 其余算战力排
    local function sortfunction(item1, item2)
        if hp:IsFightingPetById(item1._ID) then
            return true
        elseif hp:IsFightingPetById(item2._ID) then
            return false
        elseif hp:IsHelpingPetById(item1._ID) and hp:IsHelpingPetById(item2._ID) then
            return item1:GetFightScore() > item2:GetFightScore()
        elseif hp:IsHelpingPetById(item1._ID) then
            return true
        elseif hp:IsHelpingPetById(item2._ID) then
            return false
        else
            return item1:GetFightScore() > item2:GetFightScore()-- and true or false
        end
    end
    table.sort(self._LocalItemList, sortfunction)
end

-- 同步背包数据
def.method().SyncPackageData = function(self)
    -- 获取本地数据
    self:CollectLocalItemList()
    self:QualityFilter()
end

-- 同步已选中的 装备
def.method().SyncSelectItemData = function(self)
    if self._ItemData ~= nil then
        for i=1, #self._LocalItemList do
            local item = self._LocalItemList[i]
            if item._ID == self._ItemData._ID then
                self._ItemData = item
                return
            end
        end
    end
end

-- 更新通用信息显示
def.method().UpdateShowBoard = function(self)
    local root = self._PanelObject.Frame_ShowBoard
    local bSelected = (self._ItemData ~= nil)

    root.Root:SetActive( bSelected )
    root.Lab_NoPetSelect:SetActive( not bSelected )

    if bSelected then
        --昵称
        GUI.SetText(root.Label_NickName, RichTextTools.GetQualityText(self._ItemData:GetNickName(), self._ItemData:GetQuality()))
        --类型
        GUI.SetText(root.Lab_Genre, self._ItemData:GetGenusString())
        GUITools.SetGroupImg(root.Img_Genre, self._ItemData._Genus)
        --等级
        GUI.SetText(root.Lab_Level, tostring(self._ItemData:GetLevel()))
        --战斗力
        GUI.SetText(root.Lab_FightScore, GUITools.FormatMoney(self._ItemData:GetFightScore()))--tostring())
        --品阶
        GUI.SetText(root.Lab_QualityValue, tostring(self._ItemData:GetQualityText()))
        --星级
        root.List_Star:GetComponent(ClassType.GNewList).PageWidth = self._ItemData._MaxStage
        root.List_Star:GetComponent(ClassType.GNewList):SetItemCount(self._ItemData._MaxStage)
        --更新模型
        self:UpdateModel()
    end
end

local function CancelAniTick(self)
    if self._TimerID ~= 0 then
        _G.RemoveGlobalTimer(self._TimerID)
        self._TimerID = 0
    end
end
local function AddAniTick(self)
    CancelAniTick(self)

    local timeCnt = 0    
    self._TimerID = _G.AddGlobalTimer(self._Interval, false, function()
        timeCnt = timeCnt + self._Interval
        if timeCnt < self._TimeDelay then return end
        self:PlayIdelAni()

        timeCnt = 0
    end)
end
def.method().PlayIdelAni = function(self)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.TALK_IDLE, false)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.COMMON_STAND, true)
end

def.method().PlayLevelupAni = function(self)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.LEVELUP, false)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.COMMON_STAND, true)
end
def.method().UpdateModel = function(self)
    CancelAniTick(self)
    if self._ItemData == nil then return end

    --warn("更新模型")
    if self._UIModel == nil then
        self._UIModel = CUIModel.new(self._ItemData._ModelAssetPath, 
                                     self._PanelObject.Frame_ShowBoard.Model_Pet, 
                                     EnumDef.UIModelShowType.All, 
                                     EnumDef.RenderLayer.UI, 
                                     nil)
    else
        self._UIModel:Update(self._ItemData._ModelAssetPath)
    end

    self._UIModel:AddLoadedCallback(function() 
        self._UIModel:SetModelParam(self._PrefabPath, self._ItemData._ModelAssetPath)
        --先播一次
        self:PlayIdelAni()
        --延时播放
        AddAniTick(self)
        end)
end


-- 切换功能页面
def.method("number").ChangePage = function(self, pageIndex)
    --warn("ChangePage = ", pageIndex)
    if self._CurrentPage == pageIndex then return end
    self:ClearAdvanceMeterialPetItemBg()
    self._CurrentPage = pageIndex
    self:UpdateFrameShow()
end

-- 重置背包 List
def.method().UpdateItemList = function(self)
    local count = #self._LocalItemList
    self._PetItemList = {}
    self._CurAdvanceMeterialPetItem = nil 
    self._ItemList:SetItemCount( count )
end

-- 设置背包中升星材料宠Item的选中效果 
def.method("number").SetAdvanceMeterialPetItemBg = function(self,petId)
    local index = 0
    for i ,pet in ipairs(self._LocalItemList) do 
        if pet._ID == petId then 
            index = i
            break
        end
    end
    if self._CurAdvanceMeterialPetItem ~= nil then 
        local imgMerBg = self._CurAdvanceMeterialPetItem :FindChild("Img_AdvanceMeterialPetBg") 
        imgMerBg:SetActive(false)
    end
    self._CurAdvanceMeterialPetItem = self._PetItemList[index]
    self._CurAdvanceMeterialPetId = petId
    if self._CurAdvanceMeterialPetItem == nil then return end
    local imgMerBg = self._CurAdvanceMeterialPetItem :FindChild("Img_AdvanceMeterialPetBg") 
    imgMerBg:SetActive(true)
end

def.method().ClearAdvanceMeterialPetItemBg = function(self)
    if self._CurAdvanceMeterialPetItem == nil  then return end
    local imgMerBg = self._CurAdvanceMeterialPetItem :FindChild("Img_AdvanceMeterialPetBg") 
    imgMerBg:SetActive(false)
    self._CurAdvanceMeterialPetItem = nil 
    self._CurAdvanceMeterialPetId = 0
end

--更新是否显示分界面
def.method().UpdateFrameShow = function(self)
    self:HideAllFrames()
    self:GetCurrentPage():Show(self._ItemData)
end

--只更新选中目标界面
def.method().UpdateSelectPet = function(self)
    self:GetCurrentPage():UpdateSelectPet(self._ItemData)
end

def.method("=>", "dynamic").GetCurrentPage = function(self)
    return self._ProcessFrames[self._CurrentPage]
end

def.method("number", "=>", "table").GetItemDataByIndex = function(self, index)
    return self._LocalItemList[index]
end

--设置宠物格子（获得宠物属性 | 空格子）
def.method("userdata", "number").SetPetInfo = function(self, item, index)
    local iconGroup = item:FindChild("IconGroup")
    local img_Quality = iconGroup:FindChild("Img_Quality")
    local img_QualityBG = iconGroup:FindChild("Img_QualityBG")
    local img_ItemIcon = iconGroup:FindChild("Img_ItemIcon")
    local lab_Lv = iconGroup:FindChild("Lab_Lv")
    local img_Fight = item:FindChild("Img_Fight")
    local img_Help = item:FindChild("Img_Help")
    local petInfo = item:FindChild("PetInfo")
    local imgAdvanceMerPetBg = item:FindChild("Img_AdvanceMeterialPetBg")
    local hp = game._HostPlayer
    self._PetItemData = self:GetItemDataByIndex(index)

    if hp:IsFightingPetById(self._PetItemData._ID) then
        img_Fight:SetActive(true)
        img_Help:SetActive(false)
    elseif hp:IsHelpingPetById(self._PetItemData._ID) then
        img_Fight:SetActive(false)
        img_Help:SetActive(true)
    else
        img_Fight:SetActive(false)
        img_Help:SetActive(false)
    end
    imgAdvanceMerPetBg:SetActive(false)
    GUITools.SetIcon(img_ItemIcon, self._PetItemData._IconPath)
    GUITools.SetGroupImg(img_QualityBG, self._PetItemData._Quality)
    GUITools.SetGroupImg(img_Quality, self._PetItemData._Quality)
    GUI.SetText(lab_Lv, string.format(StringTable.Get(10641), self._PetItemData._Level))
    GUI.SetText(petInfo:FindChild("Lab_Name"), RichTextTools.GetQualityText(self._PetItemData._NickName, self._PetItemData._Quality))
    GUI.SetText(petInfo:FindChild("Lab_FightSocre/Lab_Value"), GUITools.FormatMoney(self._PetItemData._FightScore))
    local item_star_list = petInfo:FindChild("List_ItemStar"):GetComponent(ClassType.GNewList)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, petInfo:FindChild("List_ItemStar"), true)
    item_star_list.PageWidth = self._PetItemData._MaxStage
    item_star_list:SetItemCount(self._PetItemData._MaxStage)
    if self._PetItemData._ID == self._CurAdvanceMeterialPetId then 
        imgAdvanceMerPetBg:SetActive(true)
    end
    -- local retDotObj = item:FindChild("RedPoint")
    -- local bShow = CPetUtility.CalcPetRedDotState(self._PetItemData)
    -- retDotObj:SetActive( bShow )
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_PetView" then
        self:SetPetInfo(item, idx)
        table.insert(self._PetItemList,item)
        local currentSelectIndex = self._CurrentSelectInfo.Index
        local img_select = item:FindChild("Img_D")
        img_select:SetActive(currentSelectIndex == idx)
        if currentSelectIndex == idx then
            self._CurrentSelectInfo.Object = img_select
        end
    elseif id == "List_Star" then
        local pet_star = self._ItemData:GetStage()
        local pet_max_star = self._ItemData._MaxStage
        GUITools.SetGroupImg(item, 1)
        if idx <= pet_star then
            GUITools.SetGroupImg(item, 0)
        end
    elseif id == "List_ItemStar" then
        local pet_star = self._PetItemData:GetStage()
        local pet_max_star = self._PetItemData._MaxStage
        --GUITools.SetGroupImg(item, 1)
        item:SetActive(false)
        if idx <= pet_star then
            item:SetActive(true)
            GUITools.SetGroupImg(item, 0)
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_PetView" then
        if self._CurrentSelectInfo.Object ~= nil then
            self._CurrentSelectInfo.Object:SetActive(false)
        end
        
        self:ResetSelectItem()
        self._ItemData = self:GetItemDataByIndex(idx)

        local img_select = item:FindChild("Img_D")
        img_select:SetActive(true)
        self._CurrentSelectInfo.Object = img_select
        self._CurrentSelectInfo.Index = idx

        -- 选中逻辑
        self:UpdateShowBoard()
        -- 刷新宠物
        self:UpdateSelectPet()
    end
end

def.method().DoFreePet = function(self)
    local hp = game._HostPlayer
    if hp:IsFightingPetById(self._ItemData._ID) then
        SendFlashMsg(StringTable.Get(19053), false)
    elseif hp:IsHelpingPetById(self._ItemData._ID) then
        SendFlashMsg(StringTable.Get(19053), false)
    else
        game._GUIMan:Open("CPanelUIPetFreeConfirm", self._ItemData)
    end
end

def.method().DoPackageAdd = function(self)
    local hp = game._HostPlayer
    local maxSize = hp._PetPackage:GetMaxSize()
    local effectSize = hp._PetPackage:GetEffectSize()
    -- 格子满了
    if effectSize >= maxSize then
        SendFlashMsg(StringTable.Get(19054), false)
        return
    end

    local info = hp._PetPackage:GetUnlockCellPriceInfo()

    local hp = game._HostPlayer
    local callback = function(val)
        if val then
            local Do = function(val)
                if val then
                    CPetUtility.SendC2SPetUnLockPetBag(1)
                end
            end
            local title, msg, closeType = StringTable.GetMsg(85)
            local moneyName = CTokenMoneyMan.Instance():GetEmoji(info[1])
            msg = string.format(msg, moneyName, info[2])
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, Do)
        end
    end

    MsgBox.ShowQuickBuyBox(info[1], info[2], callback)
end

def.method().DoBtnRename = function(self)
    local data = {}
    data._Name = self._ItemData:GetNickName()

    local function Callback( name )
        CPetUtility.SendC2SPetReName(self._ItemData._ID, name)
    end

    data._Callback = Callback
    game._GUIMan:Open("CPanelUIPetRename", data)
end

def.override('string').OnClick = function(self, id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then

    elseif id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Delete" then
        self:DoFreePet()
    elseif id == "Btn_Rename" then
        self:DoBtnRename()
    elseif id == "Btn_SetFight" then
        game._GUIMan:Open("CPanelUIPetFightSetting", nil)
    elseif id == "Btn_PetLibrary" then
        game._GUIMan:Open("CPanelUIPetFieldGuide", nil)
    elseif id == 'Btn_PackageAdd' then
        self:DoPackageAdd()
    else
        self:GetCurrentPage():OnClick(id)
    end
    CPanelBase.OnClick(self, id)
end

def.override("string").OnPointerLongPress = function(self, id)
    if self._CurrentPage == EnumDef.UIPetPageState.PageCultivate then
        self:GetCurrentPage():OnPointerLongPress(id)
    elseif self._CurrentPage == EnumDef.UIPetPageState.PageAdvance then 
        self:GetCurrentPage():OnPointerLongPress(id)
    end
end
--[[
def.override("string").OnPointerDown = function(self,id)
    if self._CurrentPage == EnumDef.UIPetPageState.PageCultivate then
        self:GetCurrentPage():OnPointerDown(id)
    end
end

def.override("string").OnPointerUp = function(self,id)
    if self._CurrentPage == EnumDef.UIPetPageState.PageCultivate then
        self:GetCurrentPage():OnPointerUp(id)
    end
end

def.override("string").OnPointerExit = function(self,id)
    if self._CurrentPage == EnumDef.UIPetPageState.PageCultivate then
        self:GetCurrentPage():OnPointerExit(id)
    end
end
]]

def.override('userdata','string','number').OnLongPressItem = function(self, item, id, index)
    if self._CurrentPage == EnumDef.UIPetPageState.PageCultivate then
        self:GetCurrentPage():OnLongPressItem(item, id, index)
    end
end

def.method('number', '=>', 'number').ExchangePetQualityByIndex = function(self, index)
    return listQuality[index] or -1
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if id == "DropDown_Down" then
        local quality = self:ExchangePetQualityByIndex(index)
        if quality == self._CurrentSortQuality then return end

        self._CurrentSortQuality = quality
        self:QualityFilter()
        self:FixSelectInfo()
        self:UpdateItemList()
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    -- warn("OnToggle = ", id)
    if id == "Rdo_PetInfo" and checked then
        self:ChangePage(EnumDef.UIPetPageState.PagePetInfo)
    elseif id == "Rdo_Cultivate" and checked then
        self:ChangePage(EnumDef.UIPetPageState.PageCultivate)
    elseif id == "Rdo_Advance" and checked then
        self:ChangePage(EnumDef.UIPetPageState.PageAdvance)
    elseif id == "Rdo_Recast" and checked then
        self:ChangePage(EnumDef.UIPetPageState.PageRecast)
    elseif id == "Rdo_Skill" and checked then
        self:ChangePage(EnumDef.UIPetPageState.PageSkill)
    end
end

-- 更新页签 红点状态
def.method().UpdatePageRedDotState = function(self)
    do
        local bShow = CPetUtility.CalcPetCultivatePageRedDotState()
        self._PageRedDotList[EnumDef.UIPetPageState.PageCultivate]:SetActive( bShow )
    end

    -- 洗练 刷新洗练内部红点状态    废弃洗练
    -- do
    --     local bShow = CPetUtility.CalcPetRecastPageRedDotState()
    --     self._PageRedDotList[EnumDef.UIPetPageState.PageRecast]:SetActive( bShow )
    -- end

    -- -- 洗练 刷新洗练内部红点状态    废弃洗练
    -- if self._CurrentPage == EnumDef.UIPetPageState.PageRecast then
    --     self:GetCurrentPage():UpdateRedDotState()
    -- end

    -- 技能 出战宠物没有学习过技能 且 背包内有技能书的情况
    do
        local bShow = CPetUtility.CalcFightPetSkillRedDotState()
        self._PageRedDotList[EnumDef.UIPetPageState.PageSkill]:SetActive( bShow )
    end

end

-- 更新出战 红点状态
def.method().UpdateSetFightRedDotState = function(self)
    local bShow = CPetUtility.CalcPetFightingSetRedDotState()
    local root = self._PanelObject.Frame_ShowBoard
    root.Img_BtnFloatFx:SetActive( bShow )     
end

-- 当前选择物品的Index列表,按类别分类
def.method().ResetSelectItem = function(self)
    self._CurrentSelectInfo = {Index = 0, Object = nil}
    self._ItemData = nil
end

-- 关闭所有界面
def.method().HideAllFrames = function(self)
    for i=1, #self._ProcessFrames do
        if self._ProcessFrames[i] ~= nil and self._CurrentPage ~= i then
            self._ProcessFrames[i]:Hide()
        end
    end
end

def.override().OnHide = function(self)
    self:HideAllFrames()
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    CancelAniTick(self)

    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end

    if self._UIModel ~= nil then
        self._UIModel:Destroy()
        self._UIModel = nil
    end

    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
    CGame.EventManager:removeHandler(PetRetDotUpdateEvent, OnPetRetDotUpdateEvent)

    for k,v in pairs(self._ProcessFrames) do
        v:Destroy()
    end

    instance = nil
end

CPanelUIPetProcess.Commit()
return CPanelUIPetProcess