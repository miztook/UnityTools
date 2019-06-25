local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CUIModel = require "GUI.CUIModel"
local CScoreCalcMan = require "Data.CScoreCalcMan"

local CPanelUIPetFightSetting = Lplus.Extend(CPanelBase, 'CPanelUIPetFightSetting')
local def = CPanelUIPetFightSetting.define

def.field("table")._PanelObject = BlankTable                -- 存储界面节点的集合
def.field("userdata")._ItemList = nil                       -- 背包列表
def.field("table")._LocalItemList = BlankTable              -- 本地数据结构
def.field("table")._CurrentSelectInfo = BlankTable          -- 当前选择物品的Index,object
def.field("table")._SelectObjectList = BlankTable           -- 出战助战选中框
def.field("number")._SelectGroupType = 0                    -- 选中框类型
def.field("table")._UIModelList = BlankTable                -- 存储UIModel的集合
def.field("table")._UnlockInfopet = BlankTable             -- 解锁助战宠物栏 信息
def.field("number")._FightFieldPropAddID = 355              -- 出战宠物属性加成特殊ID
def.field("number")._HelpFieldPropAddID = 354               -- 助战宠物属性加成特殊ID
def.field("table")._ItemPetData = nil                       -- 正在实例化的pet的item数据

local SelectGroupType = 
{
    FightPetGroup = 0,
    HelpPetGroup1 = 1,
    HelpPetGroup2 = 2,
}

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local instance = nil
def.static('=>', CPanelUIPetFightSetting).Instance = function ()
    if not instance then
        instance = CPanelUIPetFightSetting()
        instance._PrefabPath = PATH.UI_PetFightSetting
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_rest == event._Type then         --休息
        -- warn("...........休息")
        instance:UpdateSortList()
        instance:FixSelectInfo()
        instance:UpdateItemList()
        instance:UpdateAllGroup()
        instance:UpdateButtonRedDotState()

    elseif EPetOptType.EPetOptType_fight == event._Type then    --出战
        -- warn("...........出战")
        instance:UpdateSortList()
        instance:FixSelectInfo()
        instance:UpdateItemList()
        instance:UpdateFightPetGroup()
        instance:UpdateButtonRedDotState()

    elseif EPetOptType.EPetOptType_help == event._Type then     --助战
        -- warn("...........助战")
        instance:UpdateSortList()
        instance:FixSelectInfo()
        instance:UpdateItemList()
        instance:UpdateHelpPetGroup()
        instance:UpdateButtonRedDotState()

    elseif EPetOptType.EPetOptType_TotalFightSocre == event._Type then -- 战斗力
        instance:UpdateFightScore()
    end

end

def.override().OnCreate = function(self)
    self._UnlockInfopet = CPetUtility.GetPetUnlockHelpCellInfo()
    -- UI
    self._PanelObject = 
    {
        FightPetGroup = {},
        HelpPetGroup1 = {},
        HelpPetGroup2 = {},
        Lab_FightScore = self:GetUIObject('Lab_FightScore'),
        Img_BtnFloatFx = self:GetUIObject('Img_BtnFloatFx'),
    }
    self._ItemList = self:GetUIObject('List_PetView'):GetComponent(ClassType.GNewListLoop)
    self._SelectObjectList = {}
    self._UIModelList = {nil,nil,nil}
    do
        local root = self._PanelObject.FightPetGroup
        root.Root = self:GetUIObject('FightGroup')
        root.Img_Model = root.Root:FindChild("Img_Role_1")
		GUITools.RegisterImageModelEventHandler(self._Panel, root.Img_Model)
        root.Btn_Add = root.Root:FindChild("Btn_AddFight")
        root.Btn_Drop = root.Root:FindChild("Btn_Drop_Fight")
        root.Lab_LevelNum = root.Root:FindChild("Lab_LevelNum")
        root.Lab_Level = root.Root:FindChild("Lab_Level")
        root.Lab_PropTip = root.Root:FindChild("Lab_PropTip")
        root.Lab_PropAdd = root.Root:FindChild("Lab_PropTip/Lab_PropAdd")
        table.insert(self._SelectObjectList, root.Root:FindChild("Img_D"))
    end

    do
        local root = self._PanelObject.HelpPetGroup1
        root.Root = self:GetUIObject('HelpGroup1')
        root.Img_Model = root.Root:FindChild("Img_Role_2")
		GUITools.RegisterImageModelEventHandler(self._Panel, root.Img_Model)
        root.Btn_Add = root.Root:FindChild("Btn_AddHelp1")
        root.Btn_Drop = root.Root:FindChild("Btn_Drop_Help1")
        root.Img_Lock = root.Root:FindChild("Img_Lock")
        root.Lab_UnLockCondition = root.Img_Lock:FindChild("Lab_UnLockCondition")
        root.Lab_LevelNum = root.Root:FindChild("Lab_LevelNum")
        root.Lab_Level = root.Root:FindChild("Lab_Level")
        root.Lab_PropTip = root.Root:FindChild("Lab_PropTip")
        root.Lab_PropAdd = root.Root:FindChild("Lab_PropTip/Lab_PropAdd")
        table.insert(self._SelectObjectList, root.Root:FindChild("Img_D"))
    end

    do
        local root = self._PanelObject.HelpPetGroup2
        root.Root = self:GetUIObject('HelpGroup2')
        root.Img_Model = root.Root:FindChild("Img_Role_3")
		GUITools.RegisterImageModelEventHandler(self._Panel, root.Img_Model)
        root.Btn_Add = root.Root:FindChild("Btn_AddHelp2")
        root.Btn_Drop = root.Root:FindChild("Btn_Drop_Help2")
        root.Img_Lock = root.Root:FindChild("Img_Lock")
        root.Lab_UnLockCondition = root.Img_Lock:FindChild("Lab_UnLockCondition")
        root.Lab_LevelNum = root.Root:FindChild("Lab_LevelNum")
        root.Lab_Level = root.Root:FindChild("Lab_Level")
        root.Lab_PropTip = root.Root:FindChild("Lab_PropTip")
        root.Lab_PropAdd = root.Root:FindChild("Lab_PropTip/Lab_PropAdd")
        table.insert(self._SelectObjectList, root.Root:FindChild("Img_D"))
    end

    CGame.EventManager:addHandler(PetUpdateEvent, OnPetUpdateEvent)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        CPanelBase.OnData(self,data)
    end

    -- 同步背包数据
    self:SyncPackageData()
    -- 刷新排序
    self:UpdateSortList()
    -- 重置背包 List
    self:UpdateItemList()

    -- 默认选中类型 第一个 出战栏
    self._SelectGroupType = SelectGroupType.FightPetGroup
    self:UpdateAllGroup()
    self:UpdateFightScore()
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

def.method().UpdateAllGroup = function(self)
    self:UpdateFightPetGroup()
    self:UpdateHelpPetGroup()
    self:UpdateSelectType()
    self:UpdateButtonRedDotState()
end

def.method().UpdateButtonRedDotState = function(self)
    local bShow = CPetUtility.CalcPetFightingSetRedDotState()
    self._PanelObject.Img_BtnFloatFx:SetActive( bShow )
end

def.method().UpdateFightScore = function(self)
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage

    local score = petPackage:GetTotalFightScore()--CScoreCalcMan.Instance():GetWholePetFightScore()
    local root = self._PanelObject
    GUI.SetText(root.Lab_FightScore, GUITools.FormatNumber(score))
end

def.method().UpdateFightPetGroup = function(self)
    local root = self._PanelObject.FightPetGroup
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local petId = hp:GetCurrentFightPetId()

    do
        local root = self._PanelObject.FightPetGroup
        local bShow = (petId > 0)

        root.Img_Model:SetActive(bShow)
        root.Btn_Drop:SetActive(bShow)
        root.Btn_Add:SetActive(not bShow)
        root.Lab_Level:SetActive(bShow)
        root.Lab_LevelNum:SetActive(bShow)
        if bShow then
            local pet = petPackage:GetPetById( petId )
            GUI.SetText(root.Lab_LevelNum, tostring(pet:GetLevel()))
            if pet ~= nil then
                if self._UIModelList[1] == nil then
                    self._UIModelList[1] = CUIModel.new(pet._ModelAssetPath, 
                                                        root.Img_Model, 
                                                        EnumDef.UIModelShowType.All, 
                                                        EnumDef.RenderLayer.UI, 
                                                        nil)
                else
                    self._UIModelList[1]:Update(pet._ModelAssetPath)
                end
                self._UIModelList[1]:AddLoadedCallback(function()
                    self._UIModelList[1]:SetModelParam(self._PrefabPath, pet._ModelAssetPath)
                end)
            end
        end
    end
    GUI.SetText(root.Lab_PropAdd, CElementData.GetSpecialIdTemplate(self._FightFieldPropAddID).Value * 100 .. "%")
end

def.method().UpdateHelpPetGroup = function(self)
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local petList = hp:GetCurrentHelpPetList()

    do
        local root = self._PanelObject.HelpPetGroup1
        local petId = petList[1]
        local locked = petId == nil
        local bShow = (not locked and petId > 0)
        --warn("petId1 = ", petId)

        root.Img_Model:SetActive(bShow)
        root.Btn_Drop:SetActive(bShow)
        root.Btn_Add:SetActive(not (bShow or locked) )
        root.Img_Lock:SetActive( locked )
        root.Lab_Level:SetActive(bShow)
        root.Lab_LevelNum:SetActive(bShow)
        root.Lab_PropTip:SetActive(not locked)
        if locked then
            local str = string.format(StringTable.Get(19062), self._UnlockInfopet[1])
            GUI.SetText(root.Lab_UnLockCondition, str)
        end

        if bShow then
            local pet = petPackage:GetPetById( petId )
            GUI.SetText(root.Lab_LevelNum, tostring(pet:GetLevel()))
            if pet ~= nil then
                if self._UIModelList[2] == nil then
                    self._UIModelList[2] = CUIModel.new(pet._ModelAssetPath, 
                                                        root.Img_Model, 
                                                        EnumDef.UIModelShowType.All, 
                                                        EnumDef.RenderLayer.UI, 
                                                        nil)
                else
                    self._UIModelList[2]:Update(pet._ModelAssetPath)
                end

                self._UIModelList[2]:AddLoadedCallback(function()
                    self._UIModelList[2]:SetModelParam(self._PrefabPath, pet._ModelAssetPath)
                end)
            end
        end
        GUI.SetText(root.Lab_PropAdd, CElementData.GetSpecialIdTemplate(self._HelpFieldPropAddID).Value * 100 .. "%")
    end

    do
        local root = self._PanelObject.HelpPetGroup2
        local petId = petList[2]
        local locked = petId == nil
        local bShow = (not locked and petId > 0)
        --warn("petId2 = ", petId)

        root.Img_Model:SetActive(bShow)
        root.Btn_Drop:SetActive(bShow)
        root.Btn_Add:SetActive(not (bShow or locked) )
        root.Img_Lock:SetActive( locked )
        root.Lab_Level:SetActive(bShow)
        root.Lab_LevelNum:SetActive(bShow)
        root.Lab_PropTip:SetActive(not locked)
        if locked then
            local str = string.format(StringTable.Get(19062), self._UnlockInfopet[2])
            GUI.SetText(root.Lab_UnLockCondition, str)
        end

        if bShow then
            local pet = petPackage:GetPetById( petId )
            GUI.SetText(root.Lab_LevelNum, tostring(pet:GetLevel()))
            if pet ~= nil then
                if self._UIModelList[3] == nil then
                    self._UIModelList[3] = CUIModel.new(pet._ModelAssetPath, 
                                                        root.Img_Model, 
                                                        EnumDef.UIModelShowType.All, 
                                                        EnumDef.RenderLayer.UI, 
                                                        nil)
                else
                    self._UIModelList[3]:Update(pet._ModelAssetPath)
                end

                self._UIModelList[3]:AddLoadedCallback(function()
                    self._UIModelList[3]:SetModelParam(self._PrefabPath, pet._ModelAssetPath)
                end)
            end
        end
        GUI.SetText(root.Lab_PropAdd, CElementData.GetSpecialIdTemplate(self._HelpFieldPropAddID).Value * 100 .. "%")
    end
end

-- 同步背包数据
def.method().SyncPackageData = function(self)
    -- 获取本地数据
    self:CollectLocalItemList()
end

def.method().CollectLocalItemList = function(self)
    self._LocalItemList = {}
    local petPackage = game._HostPlayer._PetPackage

    if petPackage:GetListCount() > 0 then
        self._LocalItemList = clone(petPackage:GetList())
    end
end

def.method("number", "=>", "table").GetItemDataByIndex = function(self, index)
    return self._LocalItemList[index]
end

-- 矫正Index
def.method().FixSelectInfo = function(self)
    if self._CurrentSelectInfo ~= nil and self._CurrentSelectInfo.ID ~= nil and self._CurrentSelectInfo.ID > 0 then
        self._CurrentSelectInfo.Index = 0
        
        for i, pet in ipairs(self._LocalItemList) do
            if self._CurrentSelectInfo.ID == pet._ID then
                self._CurrentSelectInfo.Index = i
                break
            end
        end
        warn("self._CurrentSelectInfo.Index = ", self._CurrentSelectInfo.Index)
        if self._CurrentSelectInfo.Index > 0 and not self._ItemList:IsListItemVisible(self._CurrentSelectInfo.Index - 1, 1) then
            self._ItemList:ScrollToStep(self._CurrentSelectInfo.Index - 1)
        end
    end
end

-- 重置背包 List
def.method().UpdateItemList = function(self)
    local count = #self._LocalItemList
    self._ItemList:SetItemCount( count )
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
    local Btn_Set = item:FindChild("Btn_Set")
    local Btn_Drop = item:FindChild("Btn_Drop")
    local list_item_star = petInfo:FindChild("List_ItemStar")

    self._ItemPetData = self:GetItemDataByIndex(index)
    local hp = game._HostPlayer

    if hp:IsFightingPetById(self._ItemPetData._ID) then
        img_Fight:SetActive(true)
        img_Help:SetActive(false)
        Btn_Set:SetActive(false)
        Btn_Drop:SetActive(true)
    elseif hp:IsHelpingPetById(self._ItemPetData._ID) then
        img_Fight:SetActive(false)
        img_Help:SetActive(true)
        Btn_Set:SetActive(false)
        Btn_Drop:SetActive(true)
    else
        img_Fight:SetActive(false)
        img_Help:SetActive(false)
        Btn_Set:SetActive(true)
        Btn_Drop:SetActive(false)
    end

    lab_Lv:SetActive(true)
    GUITools.SetIcon(img_ItemIcon, self._ItemPetData._IconPath)
    GUITools.SetGroupImg(img_Quality, self._ItemPetData._Quality)
    GUITools.SetGroupImg(img_QualityBG, self._ItemPetData._Quality)
    GUI.SetText(lab_Lv, string.format(StringTable.Get(10641), self._ItemPetData._Level))
    GUI.SetText(petInfo:FindChild("Lab_Name"), RichTextTools.GetPetNickNameRichText(self._ItemPetData._Tid, self._ItemPetData._NickName, false))
    GUI.SetText(petInfo:FindChild("Lab_FightSocre/Lab_Value"), GUITools.FormatNumber(self._ItemPetData._FightScore, false))
    if list_item_star ~= nil then
        local item_star_list = list_item_star:GetComponent(ClassType.GNewList)
        GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, list_item_star, true)
        item_star_list.PageWidth = self._ItemPetData._MaxStage
        item_star_list:SetItemCount(self._ItemPetData._MaxStage)
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_PetView" then
        self:SetPetInfo(item, idx)
        local currentSelectIndex = self._CurrentSelectInfo.Index

        local img_select = item:FindChild("Img_D")
        img_select:SetActive(currentSelectIndex == idx)
    elseif id == "List_ItemStar" then
        local pet_star = self._ItemPetData:GetStage()
        local pet_max_star = self._ItemPetData._MaxStage
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
        local img_select = item:FindChild("Img_D")

        img_select:SetActive(true)
        self._CurrentSelectInfo.Object = img_select
        self._CurrentSelectInfo.Index = idx
        self._CurrentSelectInfo.ID = (self:GetItemDataByIndex(idx))._ID
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    local idx = index + 1
    if id == "List_PetView" then
        if id_btn == "Btn_Set" then
            self:DoPetSet(idx)
        elseif id_btn == "Btn_Drop" then
            self:DoPetDrop(idx)
        end

        if self._CurrentSelectInfo.Object ~= nil then
            self._CurrentSelectInfo.Object:SetActive(false)
        end
        
        self:ResetSelectItem()
        local img_select = item.parent:FindChild("Img_D")
        img_select:SetActive(true)
        self._CurrentSelectInfo.Object = img_select
        self._CurrentSelectInfo.Index = idx
        self._CurrentSelectInfo.ID = (self:GetItemDataByIndex(idx))._ID 
    end
end

def.method("number").DoPetSet = function(self, index)
    --warn("DoPetSet :" ,index)
    if self:CheckCanSetFightstate() then
        local petData = self:GetItemDataByIndex(index)
        if self._SelectGroupType == SelectGroupType.FightPetGroup then
            CPetUtility.SendC2SPetFighting(petData._ID, self._SelectGroupType)
        else
            CPetUtility.SendC2SPetHelpFighting(petData._ID, self._SelectGroupType - 1)
        end
    end
end

def.method("number").DoPetDrop = function(self, index)
    --warn("DoPetDrop :" ,index)
    if self:CheckCanSetFightstate() then
        local petData = self:GetItemDataByIndex(index)
        CPetUtility.SendC2SPetRest(petData._ID)
    end
end

def.method().UpdateSelectType = function(self)
    for i=1, #self._SelectObjectList do
    local obj = self._SelectObjectList[i]
        obj:SetActive( self._SelectGroupType == i-1 )
    end
end

-- 当前选择物品的Index列表,按类别分类
def.method().ResetSelectItem = function(self)
    self._CurrentSelectInfo = {Index = 0, Object = nil, ID = 0}
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_FightingProperty" then
        game._GUIMan:Open("CPanelUIPetFightingProperty", nil)
    elseif id == 'FightGroup' or id == "Img_Role_1" then
        self._SelectGroupType = SelectGroupType.FightPetGroup
        self:UpdateSelectType()

    elseif id == 'HelpGroup1' or id == "Img_Role_2" then
        local hp = game._HostPlayer
        local petList = hp:GetCurrentHelpPetList()
        local petId = petList[1]
        local locked = petId == nil
        if locked then
            local str = string.format(StringTable.Get(19062), self._UnlockInfopet[1])
            SendFlashMsg(str, false)
        else
            self._SelectGroupType = SelectGroupType.HelpPetGroup1
            self:UpdateSelectType()
        end

    elseif id == 'HelpGroup2' or id == "Img_Role_3" then
        local hp = game._HostPlayer
        local petList = hp:GetCurrentHelpPetList()
        local petId = petList[2]
        local locked = petId == nil
        if locked then
            local str = string.format(StringTable.Get(19062), self._UnlockInfopet[2])
            SendFlashMsg(str, false)
        else
            self._SelectGroupType = SelectGroupType.HelpPetGroup2
            self:UpdateSelectType()
        end

    elseif id == "Btn_Drop_Fight" then
        self._SelectGroupType = SelectGroupType.FightPetGroup
        self:UpdateSelectType()
        
        if self:CheckCanSetFightstate() then
            local hp = game._HostPlayer
            local petPackage = hp._PetPackage
            local petId = hp:GetCurrentFightPetId()
            CPetUtility.SendC2SPetRest( petId )
        end

    elseif id == "Btn_Drop_Help1" then
        self._SelectGroupType = SelectGroupType.HelpPetGroup1
        self:UpdateSelectType()

        if self:CheckCanSetFightstate() then
            local hp = game._HostPlayer
            local petPackage = hp._PetPackage
            local petList = hp:GetCurrentHelpPetList()
            local petId = petList[self._SelectGroupType]
            CPetUtility.SendC2SPetRest( petId )
        end

    elseif id == "Btn_Drop_Help2" then
        self._SelectGroupType = SelectGroupType.HelpPetGroup2
        self:UpdateSelectType()

        if self:CheckCanSetFightstate() then
            local hp = game._HostPlayer
            local petPackage = hp._PetPackage
            local petList = hp:GetCurrentHelpPetList()
            local petId = petList[self._SelectGroupType]
            CPetUtility.SendC2SPetRest( petId )
        end
    elseif id == "Btn_AutoSet" then
        if self:CheckCanSetFightstate() then
            if #self._LocalItemList == 0 then
                SendFlashMsg(StringTable.Get(19059), false)
            else
                CPetUtility.SendC2SPetAutoFighting()
            end
        end
    end
    CPanelBase.OnClick(self, id)
end

def.method("=>", "boolean").CheckCanSetFightstate = function (self)
    local hp = game._HostPlayer
    local isServerCombatState = hp:IsInServerCombatState()
    if isServerCombatState then
        SendFlashMsg(StringTable.Get(19046), false)
    end

    return not isServerCombatState
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    for i=1, #self._UIModelList do
        if self._UIModelList[i] ~= nil then
            self._UIModelList[i]:Destroy()
            self._UIModelList[i] = nil
        end
    end

    instance = nil
    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
end

CPanelUIPetFightSetting.Commit()
return CPanelUIPetFightSetting