local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require"Data.CElementData"
local CDressMan = require "Dress.CDressMan"
local GuideType = require "PB.Template".GrowthGuidance.GuideType
local EParmType = require "PB.Template".ItemApproach.EParmType
local CPanelStrong = Lplus.Extend(CPanelBase, 'CPanelStrong')
local def = CPanelStrong.define
 
def.field("table")._PanelObject = BlankTable
def.field("number")._CurType = -1 --当前选中分类
def.field("table")._StrongListData = nil 
def.field("table")._ExpListData = BlankTable 
def.field("table")._EquipListData = BlankTable 
def.field("table")._MoneyListData = BlankTable 
def.field("table")._MaterialListData = BlankTable 
def.field('table')._PetListData = BlankTable
def.field("boolean")._IsOpen = false --是否开启了list

def.field("userdata")._ImgScore = nil 
def.field("userdata")._LabCurFight = nil 
def.field("userdata")._LabBasicFight = nil 
def.field("userdata")._TabListMenu = nil 
def.field("number")._CurPageType  = 0
def.field("userdata")._NewTabList = nil 
def.field("userdata")._FrameToggle = nil 
def.field("userdata")._Toggle = nil 


local PageType = 
{
    NONE = 0,   
    GETSTRONG = 1,       -- 我要变强
    GETEXP = 2,          -- 我要经验   
    GETMONEY = 3,        -- 我要财富
    GETEQUIP = 4,        -- 我要装备
    GETPET = 5,          -- 我要宠物
    GETMATERIAL = 6,     -- 我要材料
}
def.const("table").PageType = PageType

local instance = nil
def.static('=>', CPanelStrong).Instance = function ()
	if not instance then
        instance = CPanelStrong()
        instance._PrefabPath = PATH.UI_Strong
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end

-- 成长引导的数据里不包括我要变强
local function InitStrongData(self)
    local allData = game._PlayerStrongMan :GetAllData()--获取所有数据。然后进行筛选
    if allData == nil or #allData <= 0 then 
        warn("PlayerStrongMan: 数据是空，打开失败")
        return
    end

    self._IsOpen = false
    --将数据做处理。所有解锁的放入列表中
    self._StrongListData = {}
    for _,v in ipairs(allData) do
        local FunID = v._Data.FunID
        -- if game._CFunctionMan:IsUnlockByFunTid(FunID) then
        local nType = #self._StrongListData + 1
        self._StrongListData[nType] = 
        {
            _Data = v._Data,
            _Cells = {},
        }

        local cellIdex = 1
        for _, k in ipairs(v._Cells) do
            local data =  CElementData.GetTemplate("PlayerStrongCell", k)
            if data ~= nil and data.Id ~= nil then
                -- if game._CFunctionMan:IsUnlockByFunTid(data.FunID) then
                self._StrongListData[nType]._Cells[cellIdex] = data
                cellIdex = cellIdex + 1
                -- end      
            end             
        end
        -- end
    end 
end

local function sortFunction(data1,data2)
    if data1.SortId < data2.SortId then 
        return true
    elseif data1.SortId > data2.SortId then 
        return false
    end
    return false
end

local function InitElseData(self)
    local allIds = CElementData.GetAllTid("GrowthGuidance")
    if allIds == nil or #allIds == 0 then warn( " CPanelStrong Get Template is fail") return end
    for i,id in ipairs(allIds) do
        local data = {}
        local template = CElementData.GetTemplate("GrowthGuidance",id)
        data.Id = id
        data.Description = template.Description
        data.SortId = template.SortId
        local itemTemplate = CElementData.GetItemTemplate(template.ItemId)
        data.ItemTemp = itemTemplate
        local listID = string.split(itemTemplate.ApproachID, "*")
        if listID == nil then return end    
        data.ApproachTemps = {}
        for _,v in ipairs(listID) do
            local Tid = tonumber(v)
            if Tid ~= nil and Tid ~= 0 then
                local approachItem = CElementData.GetItemApproach(Tid)
                table.insert(data.ApproachTemps,approachItem)
            end
        end
        if template.GuidanceType == GuideType.GetExp then 
            table.insert(self._ExpListData,data)
        elseif template.GuidanceType == GuideType.GetEquip then
            table.insert(self._EquipListData,data)
        elseif template.GuidanceType == GuideType.GetMoney then
            table.insert(self._MoneyListData,data)
        elseif template.GuidanceType == GuideType.GetMaterial then
            table.insert(self._MaterialListData,data)
        elseif template.GuidanceType == GuideType.GetPet then
            table.insert(self._PetListData,data)
        end
    end
    if #self._ExpListData > 2 then 
        table.sort(self._ExpListData,sortFunction)
    end
    if #self._EquipListData > 2 then 
        table.sort(self._EquipListData,sortFunction)
    end
    if #self._MoneyListData > 2 then 
        table.sort(self._MoneyListData,sortFunction)
    end
    if #self._MaterialListData > 2 then 
        table.sort(self._MaterialListData,sortFunction)
    end
    if #self._PetListData > 2 then 
        table.sort(self._PetListData,sortFunction)
    end
end

local OnNotifyPropEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        local hp = game._HostPlayer
        if hp._ID == event.ObjID then
            local curFight =  hp:GetHostFightScore()
            if not IsNil(instance._LabCurFight) then
                GUI.SetText(instance._LabCurFight, GUITools.FormatMoney(curFight))
            end
        end
    end
end

local function InitPanel(self,data,selectId)
    --当前战斗力
    local curFight =  game._HostPlayer:GetHostFightScore()
    if not IsNil(self._LabCurFight) then
        GUI.SetText(self._LabCurFight, GUITools.FormatMoney(curFight))
    end

    --推荐战斗力
    local s_value = game._PlayerStrongMan:GetSValueByValueID(1)
    local basicValue = game._PlayerStrongMan:GetBasicValueByValueID(1)
    if not IsNil(self._LabBasicFight) then
        GUI.SetText(self._LabBasicFight, GUITools.FormatMoney(s_value))
    end

    --战斗力评级S、A、B、C、 -- 3、2、1、0
    local groupID = game._PlayerStrongMan:GetImgScoreGroupID(curFight, basicValue)
    GUITools.SetGroupImg(self._ImgScore,groupID)
    -- if groupID == 3 then 
    --     GameUtil.PlayUISfx(PATH.UIFx_ScoreS,self._ImgScore,self._ImgScore,-1)
    -- elseif groupID == 2 then 
    --     GameUtil.PlayUISfx(PATH.UIFx_ScoreA,self._ImgScore,self._ImgScore,-1)
    -- elseif groupID == 1 then 
    --     GameUtil.PlayUISfx(PATH.UIFx_ScoreB,self._ImgScore,self._ImgScore,-1)
    -- elseif groupID == 0 then 
    --     GameUtil.PlayUISfx(PATH.UIFx_ScoreC,self._ImgScore,self._ImgScore,-1)
    -- end
    
    if data == nil or #data <= 0 then
        self._TabListMenu:SetActive(false)
        return
    else
        self._TabListMenu:SetActive(true)
        if self._TabListMenu ~= nil then
            self._NewTabList:SetItemCount(#data) 
            if selectId == 0 then return end
            local selectIndex = 0
            for i,v in ipairs(data) do
                if v.Id == selectId then 
                    selectIndex = i
                    break
                end
            end
            self._NewTabList:SelectItem(selectIndex - 1,selectIndex - 1)
        end
    end

    -- local curType = -1
    -- local idex = -1
    -- if data ~= nil then
    --     for i,v in ipairs(self._StrongListData) do
    --         if v._Data.Id == data._Type then
    --             curType = i
    --         end
    --     end
    --     idex = data._idex
    -- end
    -- if curType <= 0 or idex <= 0 then return end
    -- self._TabListMenu:GetComponent(ClassType.GNewTabList):SelectItem(curType - 1,idex - 1)
end

def.override().OnCreate = function(self)
    self._ImgScore = self:GetUIObject("Img_Score")
    self._LabCurFight = self:GetUIObject("Lab_CurFight")
    self._LabBasicFight = self:GetUIObject("Lab_BasicFight")
    self._TabListMenu = self:GetUIObject("TabList_Menu")
    self._FrameToggle = self:GetUIObject("Frame_Toggle")
    self._NewTabList = self._TabListMenu:GetComponent(ClassType.GNewTabList)
    self._Toggle = self:GetUIObject("Toogle_Panel")
end

-- panelData = {
--                 PageType ,
--                 SelectId,               --- 选中的右侧列表id
--             }

def.override("dynamic").OnData = function(self, data)
    self._ExpListData = {}
    self._StrongListData = {}
    self._EquipListData = {}
    self._MoneyListData = {}
    self._MaterialListData = {}
    self._PetListData = {}
    InitElseData(self)
    InitStrongData(self)
    local selectId = 0
    local state = game._PlayerStrongMan:GetShowPlayerStrongPanelState()
    self._Toggle:GetComponent(ClassType.Toggle).isOn = not state
    if data ~= nil and data.SelectId ~= nil then 
        selectId = data.SelectId
    end
    if data == nil or (data ~= nil and data.PageType == PageType.GETSTRONG) then
        self._CurPageType = PageType.GETSTRONG
        InitPanel(self,self._StrongListData,selectId)
    else
        self._CurPageType = data.PageType
        GUI.SetGroupToggleOn(self._FrameToggle,self._CurPageType)
        if data.PageType == PageType.GETEXP then 
            InitPanel(self,self._ExpListData,selectId)
        elseif data.PageType == PageType.GETEQUIP then 
            InitPanel(self,self._EquipListData,selectId)
        elseif data.PageType == PageType.GETMONEY then 
            InitPanel(self,self._MoneyListData,selectId)
        elseif data.PageType == PageType.GETMATERIAL then 
            InitPanel(self,self._MaterialListData,selectId)
        elseif data.PetType == PageType.GETPET then 
            InitPanel(self,self._PetListData,selectId)
        end
    end
    self._HelpUrlType = HelpPageUrlType.StrongGuide

    CGame.EventManager:addHandler("NotifyPropEvent", OnNotifyPropEvent)
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if id == 'Btn_Close' then
        game._GUIMan:CloseByScript(self)
    end

end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if id  == "Rdo_Strong" then 
        if self._CurPageType ~= PageType.GETSTRONG then
            self._CurPageType = PageType.GETSTRONG
            if self._StrongListData == nil or #self._StrongListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._StrongListData) 
                    self._NewTabList:ScrollToStep(0)
                end
            end
        end
    elseif id == "Rdo_Exp" then 
        if self._CurPageType ~= PageType.GETEXP then
            self._CurPageType = PageType.GETEXP
            if self._ExpListData == nil or #self._ExpListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._ExpListData) 
                    self._NewTabList:ScrollToStep(0)
                end
            end
        end
    elseif id == "Rdo_Equip" then 
        if self._CurPageType ~= PageType.GETEQUIP then
            self._CurPageType = PageType.GETEQUIP
            if self._EquipListData == nil or #self._EquipListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._EquipListData)
                    self._NewTabList:ScrollToStep(0)
                end
            end
        end
    elseif id == "Rdo_Money" then 
        if self._CurPageType ~= PageType.GETMONEY then
            self._CurPageType = PageType.GETMONEY
            if self._MoneyListData == nil or #self._MoneyListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._MoneyListData) 
                    self._NewTabList:ScrollToStep(0)  
                end
            end
        end

    elseif id == "Rdo_Material" then 
        if self._CurPageType ~= PageType.GETMATERIAL then
            self._CurPageType = PageType.GETMATERIAL
            if self._MaterialListData == nil or #self._MaterialListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._MaterialListData)   
                    self._NewTabList:ScrollToStep(0)
                end
            end
        end
    elseif id == "Rdo_Pet" then 
        if self._CurPageType ~= PageType.GETPET then
            self._CurPageType = PageType.GETPET
            if self._PetListData == nil or #self._PetListData <= 0 then
                self._TabListMenu:SetActive(false)
                return
            else
                self._TabListMenu:SetActive(true)
                if self._NewTabList ~= nil then
                    self._NewTabList:SetItemCount(#self._PetListData)   
                    self._NewTabList:ScrollToStep(0)
                end
            end
        end    
    elseif id == "Toogle_Panel" then
        game._PlayerStrongMan:SetShowPlayerStrongPanel(not checked)
    end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    if string.find(list.name, "TabList_Menu") then
        if sub_index == -1 then
            self:OnInitTabListDeep1(item, main_index + 1)
        else
            self:OnInitTabListDeep2(item, main_index + 1, sub_index + 1)
        end
    end
end

def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if string.find(list.name, "TabList_Menu") then
        if sub_index == -1 then
            local data = nil 
            if self._CurPageType == PageType.GETSTRONG then 
                data = self._StrongListData[main_index + 1]._Cells
            elseif self._CurPageType == PageType.GETEXP then 
                data = self._ExpListData[main_index + 1].ApproachTemps
            elseif self._CurPageType == PageType.GETEQUIP then 
                data = self._EquipListData[main_index + 1].ApproachTemps
            elseif self._CurPageType == PageType.GETMONEY then 
                data = self._MoneyListData[main_index + 1].ApproachTemps
            elseif self._CurPageType == PageType.GETMATERIAL then 
                data = self._MaterialListData[main_index + 1].ApproachTemps
            elseif self._CurPageType == PageType.GETPET then 
                data = self._PetListData[main_index + 1].ApproachTemps
            end
            local imgArrowUp = item:FindChild("Img_D/Img_ArrowUp")
            local imgArrowDown = item:FindChild("Img_D/Img_ArrowDown")
            if self._CurType == main_index + 1 then 
                if not self._IsOpen  then
                    self._IsOpen = true
                    imgArrowUp:SetActive(true)
                    imgArrowDown:SetActive(false)
                    if not IsNil(data) then
                        self._NewTabList:OpenTab(#data)
                    end
                else
                    imgArrowUp:SetActive(false)
                    imgArrowDown:SetActive(true)
                    self._NewTabList:OpenTab(0)
                    self._IsOpen = false
                end
            else
                imgArrowUp:SetActive(true)
                imgArrowDown:SetActive(false)
                self._IsOpen = true
                self._CurType = main_index + 1
                if not IsNil(data) then
                    self._NewTabList:OpenTab(#data)
                end  
            end
        end
    end
end

def.override("userdata", "userdata", "number", "number").OnTabListItemButton  = function(self, list, item, main_index, sub_index)
    local data = nil 
    if self._CurPageType == PageType.GETSTRONG then 
        data = self._StrongListData[main_index + 1]._Cells[sub_index + 1]
    elseif self._CurPageType == PageType.GETEXP then 
        data = self._ExpListData[main_index + 1].ApproachTemps[sub_index + 1]
    elseif self._CurPageType == PageType.GETEQUIP then 
        data = self._EquipListData[main_index + 1].ApproachTemps[sub_index + 1]
    elseif self._CurPageType == PageType.GETMONEY then 
        data = self._MoneyListData[main_index + 1].ApproachTemps[sub_index + 1]
    elseif self._CurPageType == PageType.GETMATERIAL then 
        data = self._MaterialListData[main_index + 1].ApproachTemps[sub_index + 1]
    elseif self._CurPageType == PageType.GETPET then 
        data = self._PetListData[main_index + 1].ApproachTemps[sub_index + 1]
    end
    if data == nil then return end
    if not game._CFunctionMan:IsUnlockByFunTid(data.FunID) then 
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, data.FunID)
    return end
    if self._CurPageType == PageType.GETSTRONG then 
        game._AcheivementMan:DrumpToRightPanel(data.OpenPanelId,0)
    else
        game._AcheivementMan:DrumpToRightPanel(data.Id,0)
    end
end

def.method("userdata", "userdata", "number", "number").TabItemButton  = function(self, list, item, main_index, sub_index)
    
    
end

--初始化我要变强Tab
local function InitStrongTabDeep1(self,index,item)
    local data = self._StrongListData[index]._Data
    if data.Id == nil then
        warn("CPanelStrong:: OnInitTabListDeep1-->类型"..index.."数据错误")
    return end
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local item = uiTemplate:GetControl(9)
    item:SetActive(false)

    local labName = uiTemplate:GetControl(1)
    labName:SetActive(true)
    GUI.SetText(labName, data.Name)

    local LadDescribe1 = uiTemplate:GetControl(3)
    LadDescribe1:SetActive(false)
    local LabDescribe2 = uiTemplate:GetControl(7)
    LabDescribe2:SetActive(false)
    local icon =  uiTemplate:GetControl( 5)
    icon:SetActive(true)
    GUITools.SetIcon(icon, data.IconPath)

    local imgScore = uiTemplate:GetControl(6)
    imgScore:SetActive(true)
    local value = game._PlayerStrongMan:GetFightScoreByType(data.Id)
    local basicValue = game._PlayerStrongMan:GetBasicValueByValueID(data.ValueId)
    local sliderBg = uiTemplate:GetControl(8)
    sliderBg:SetActive(true)
    local slider = uiTemplate:GetControl(4)
    slider:SetActive(true)
    if basicValue == 0 then 
        slider:GetComponent(ClassType.Image).fillAmount = 0
        GUITools.SetGroupImg(imgScore,3)
    return end
    if slider ~= nil then
        slider:GetComponent(ClassType.Image).fillAmount = math.clamp(value/basicValue, 0, 1)
    end

    local percent = (value/basicValue) * 100
    local Ascore = CSpecialIdMan.Get("PlayerSrongScoreA")
    local Bscore = CSpecialIdMan.Get("PlayerSrongScoreB") 
    local Cscore = CSpecialIdMan.Get("PlayerSrongScoreC")
    if percent >= Ascore then 
        GUITools.SetGroupImg(imgScore,0)
    elseif percent >= Bscore and percent < Ascore then 
        GUITools.SetGroupImg(imgScore,1)
    elseif percent >= Cscore and percent < Bscore then 
        GUITools.SetGroupImg(imgScore,2)
    elseif percent < Cscore then
        GUITools.SetGroupImg(imgScore,3)
    end
end

--初始化其他页签Tab
local function InitElseTabDeep1(self,index,item,data)
    local curData = data[index]
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local labName = uiTemplate:GetControl(1)
    labName:SetActive(false)
    local sliderBg = uiTemplate:GetControl(8)
    sliderBg:SetActive(false)
    local ImgScore = uiTemplate:GetControl(6)
    ImgScore:SetActive(false)
    local icon = uiTemplate:GetControl(5)

    local FrameItem = uiTemplate:GetControl(9)
    FrameItem:SetActive(true)
    icon:SetActive(false)
    local labDescribe1 = uiTemplate:GetControl(3)
    local labDescribe2 = uiTemplate:GetControl(7)
    labDescribe1:SetActive(true)
    labDescribe2:SetActive(true)
    GUI.SetText(labDescribe1,curData.ItemTemp.TextDisplayName)
    GUI.SetText(labDescribe2,curData.Description)
    local frame_icon = uiTemplate:GetControl(10)
    IconTools.InitItemIconNew(frame_icon, curData.ItemTemp.Id, { [EItemIconTag.Number] = 0})
end

--初始化树节点
def.method("userdata","number").OnInitTabListDeep1 = function(self, item, index)
    if self._CurPageType == PageType.GETSTRONG then 
        InitStrongTabDeep1(self,index,item)
    elseif self._CurPageType == PageType.GETEXP then 
        InitElseTabDeep1(self,index,item,self._ExpListData)
    elseif self._CurPageType == PageType.GETEQUIP then 
        InitElseTabDeep1(self,index,item,self._EquipListData)
    elseif self._CurPageType == PageType.GETMONEY then 
        InitElseTabDeep1(self,index,item,self._MoneyListData)
    elseif self._CurPageType == PageType.GETMATERIAL then 
        InitElseTabDeep1(self,index,item,self._MaterialListData)
    elseif self._CurPageType == PageType.GETPET then 
        InitElseTabDeep1(self,index,item,self._PetListData)
    end
end

local function InitStrongTabDeep2(self,item, mainIndex,index,data)
    local cellData = self._StrongListData[mainIndex]._Cells[index]
    
    if cellData == nil or cellData.Id == nil then 
        warn("CPanelStrong--OnInitTabListDeep2->分类："..mainIndex.."的ID"..index.."数据错误")
    return end

    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local labTag1 = uiTemplate:GetControl(0)
    local labTag2 = uiTemplate:GetControl(2)
    local labTag3 = uiTemplate:GetControl(3)
    labTag1:SetActive(true)
    labTag3:SetActive(false)
    labTag2:SetActive(false)
    GUI.SetText(labTag1, cellData.Name)
    local value = game._PlayerStrongMan:GetCellFightScore(cellData.Id)
    local basicValue = game._PlayerStrongMan: GetBasicValueByValueID(cellData.ValueId)
    local slider = uiTemplate:GetControl(1)
    local sliderBg = uiTemplate:GetControl(4)
    sliderBg:SetActive(true)
    if slider ~= nil then
        slider:SetActive(true)
        slider:GetComponent(ClassType.Image).fillAmount = math.clamp(value/basicValue, 0, 1)
    end
end

local function InitElseTabDeep2(self,item, mainIndex,index,data)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local labTag1 = uiTemplate:GetControl(0)
    local labTag2 = uiTemplate:GetControl(2)
    local labTag3 = uiTemplate:GetControl(3)
    local imgSlider = uiTemplate:GetControl( 1)
    local imgSliderBg = uiTemplate:GetControl(4)
    local btnGo = uiTemplate:GetControl(5)
    imgSliderBg:SetActive(false)
    imgSlider:SetActive(false)
    labTag1:SetActive(false)
    labTag2:SetActive(true)
    labTag3:SetActive(true)
    local ApproachTemps = data[mainIndex].ApproachTemps
    GUI.SetText(labTag2,ApproachTemps[index].DisplayName)
    GUI.SetText(labTag3,ApproachTemps[index].Description)
    if ApproachTemps[index].ClickType == EParmType.OpenUI then
        btnGo:SetActive(true)
    else
        btnGo:SetActive(false)
    end
end

--初始化2级菜单
def.method("userdata","number","number").OnInitTabListDeep2 = function(self, item, mainIndex, index) 
    if self._CurPageType == PageType.GETSTRONG then 
        InitStrongTabDeep2(self,item, mainIndex,index)
    elseif self._CurPageType == PageType.GETEXP then 
        InitElseTabDeep2(self,item, mainIndex ,index ,self._ExpListData)
    elseif self._CurPageType == PageType.GETEQUIP then 
        InitElseTabDeep2(self,item, mainIndex ,index ,self._EquipListData)
    elseif self._CurPageType == PageType.GETMONEY then 
        InitElseTabDeep2(self,item, mainIndex ,index ,self._MoneyListData)
    elseif self._CurPageType == PageType.GETMATERIAL then 
        InitElseTabDeep2(self,item, mainIndex ,index ,self._MaterialListData)
    elseif self._CurPageType == PageType.GETPET then 
        InitElseTabDeep2(self,item, mainIndex ,index ,self._PetListData)
    end  
end

def.override().OnHide = function (self)
    CGame.EventManager:removeHandler("NotifyPropEvent", OnNotifyPropEvent)
end

def.override().OnDestroy = function(self)
    instance = nil 
end 

CPanelStrong.Commit()
return CPanelStrong