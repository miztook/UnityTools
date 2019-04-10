local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
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


local PageType = 
{
    NONE = 0,   
    GETSTRONG = 1,       -- 我要变强
    GETEXP = 2,          -- 我要经验   
    GETEQUIP = 3,        -- 我要装备
    GETMONEY = 4,        -- 我要财富
    GETMATERIAL = 5,     -- 我要材料
    GETPET = 6,          -- 我要宠物
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
    local allIds = GameUtil.GetAllTid("GrowthGuidance")
    if allIds == nil or #allIds == 0 then warn( " CPanelStrong Get Template is fail") return end
    for i,id in ipairs(allIds) do
        local data = {}
        local template = CElementData.GetTemplate("GrowthGuidance",id)
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

local function InitPanel(self,data)

    --当前战斗力
    local curFight =  game._HostPlayer:GetHostFightScore()
    if not IsNil(self._LabCurFight) then
        GUI.SetText(self._LabCurFight, GUITools.FormatMoney(curFight))
    end

    --推荐战斗力
    local basicValue = game._PlayerStrongMan:GetBasicValueByValueID(1)
    if not IsNil(self._LabBasicFight) then
        GUI.SetText(self._LabBasicFight, GUITools.FormatMoney(basicValue))
    end

    --战斗力评级S、A、B、C、 -- 3、2、1、0
    local groupID = game._PlayerStrongMan:GetImgScoreGroupID(curFight, basicValue)
    GUITools.SetGroupImg(self._ImgScore,groupID)
    if groupID == 3 then 
        GameUtil.PlayUISfx(PATH.UIFx_ScoreS,self._ImgScore,self._ImgScore,-1)
    elseif groupID == 2 then 
        GameUtil.PlayUISfx(PATH.UIFx_ScoreA,self._ImgScore,self._ImgScore,-1)
    elseif groupID == 1 then 
        GameUtil.PlayUISfx(PATH.UIFx_ScoreB,self._ImgScore,self._ImgScore,-1)
    elseif groupID == 0 then 
        GameUtil.PlayUISfx(PATH.UIFx_ScoreC,self._ImgScore,self._ImgScore,-1)
    end
    
    if data == nil or #data <= 0 then
        self._TabListMenu:SetActive(false)
        return
    else
        self._TabListMenu:SetActive(true)
        if self._TabListMenu ~= nil then
            self._NewTabList:SetItemCount(#data)    
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
end

-- panelData = {
--                 PageType ,
--             }

def.override("dynamic").OnData = function(self, data)
    self._ExpListData = {}
    self._StrongListData = {}
    self._EquipListData = {}
    self._MoneyListData = {}
    self._MaterialListData = {}
    self._PetListData = {}
    InitElseData(self)
    if data == nil or (data ~= nil and data.PageType == PageType.GETSTRONG) then
        self._CurPageType = PageType.GETSTRONG
        InitStrongData(self)
        InitPanel(self,self._StrongListData)
    else
        self._CurPageType = data.PageType
        GUI.SetGroupToggleOn(self._FrameToggle,self._CurPageType)
        if data ~= nil and data.PageType == PageType.GETEXP then 
            InitPanel(self,self._ExpListData)
        elseif data ~= nil and data.PageType == PageType.GETEQUIP then 
            InitPanel(self,self._EquipListData)
        elseif data ~= nil and data.PageType == PageType.GETMONEY then 
            InitPanel(self,self._MoneyListData)
        elseif data ~= nil and data.PageType == PageType.GETMATERIAL then 
            InitPanel(self,self._MaterialListData)
        elseif data ~= nil and data.PetType == PageType.GETPET then 
            InitPanel(self,self._PetListData)
        end
    end
end

def.override('string').OnClick = function(self, id)
    
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
    local slider = uiTemplate:GetControl(4):GetComponent(ClassType.Image)

    if basicValue == 0 then 
        slider.fillAmount = 0
        GUITools.SetGroupImg(imgScore,3)
    return end
    if slider ~= nil then
        slider.fillAmount = math.clamp(value/basicValue, 0, 1)
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

-- 策划数据表不能更改
local function GetCellFightScore(Id)
    local CWingsMan = require "Wings.CWingsMan"
    local CCharmMan = require "Charm.CCharmMan"
    if Id == 1 then -- 装备基础
        local equipLevel = 0
        for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do         
            if v ~= nil and v._Tid ~= 0 then 
                local itemData =  CElementData.GetItemTemplate(v._Tid)
                equipLevel = equipLevel + itemData.MinLevelLimit
            end
        end
        return equipLevel
    elseif Id == 2 then--装备品质
        local equipQuality = 0
        for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do         
            if v ~= nil and v._Tid ~= 0 then 
                local itemData =  CElementData.GetItemTemplate(v._Tid)
                equipQuality = equipQuality + itemData.InitQuality
            end
        end
        return equipQuality
    elseif Id == 3 then--强化等级
        local equipInforceLevel = 0
        for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do         
            if v ~= nil and v._Tid ~= 0 then 
                equipInforceLevel = equipInforceLevel + v._InforceLevel
            end
        end
        return equipInforceLevel
    elseif Id == 4 then--附魔战斗力加成
        return 0
    elseif Id == 5 then--重铸
        local equipRecast = 0
        for i,v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do             
            if v ~= nil and v._Tid ~= 0 then 
                for j,data in ipairs(v._EquipBaseAttrs) do
                    equipRecast = equipRecast + data.value
                end
            end
        end
        return equipRecast
    elseif Id == 6 then--刻印
        return 0
    elseif Id == 7 then--技能等级
        local userSkillMap = game._HostPlayer._UserSkillMap
        local skillLevel = 0
        for _, v in ipairs(userSkillMap) do
            skillLevel = skillLevel + v.SkillLevel
        end
        return skillLevel
    elseif Id == 8 then--技能文章
        local userSkillMap = game._HostPlayer._UserSkillMap
        local skillRune = 0
        for _, v in ipairs(userSkillMap) do
            for _, x in ipairs(v.SkillRuneInfoDatas) do
                skillRune = skillRune + x.level
            end
        end
        return skillRune
    elseif Id == 9 then--出战宠物等级
        local petLevel = 0
        local petPackage = game._HostPlayer._PetPackage
        local petId = game._HostPlayer:GetCurrentFightPetId()
        if petId ~= 0 then
            local petData = petPackage:GetPetById(petId)
            if petData ~= nil then
                petLevel = petData._Level
            end
        end
        return petLevel
    elseif Id == 10 then--出战宠物品质
        local petquality = 0
        local petPackage = game._HostPlayer._PetPackage
        local petId = game._HostPlayer:GetCurrentFightPetId()
        if petId ~= 0 then
            local petData = petPackage:GetPetById(petId)
            if petData ~= nil then
                petquality = petData._Quality
            end
        end
        return petquality
    elseif Id == 11 then--出战宠物升阶
        local petState = 0
        local petPackage = game._HostPlayer._PetPackage
        local petId = game._HostPlayer:GetCurrentFightPetId()
        if petId ~= 0 then
            local petData = petPackage:GetPetById(petId)
            if petData ~= nil then
                petState = petData._Stage
            end
        end
        return petState
    elseif Id == 12 then--宠物技能数量
        local petPackage = game._HostPlayer._PetPackage
        local petId = game._HostPlayer:GetCurrentFightPetId()
        if petId ~= 0 then
            local petData = petPackage:GetPetById(petId)
            if petData ~= nil then
                return petData:GetSkillCount()
            end
        end
        return 0 
    elseif Id == 13 then--宠物技能品质
        local petPackage = game._HostPlayer._PetPackage
        local petId = game._HostPlayer:GetCurrentFightPetId()
        if petId ~= 0 then
            local petData = petPackage:GetPetById(petId)
            if petData ~= nil then
                return petData:GetAllSkillQualityAmount()
            end
        end
        return 0
    elseif Id == 14 then--宠物属性洗练
        return 0
    elseif Id == 15 then--铭符等级
        --return CCharmMan.Instance(): GetTotalSmallCharmMinLevel()
        return 0
    elseif Id == 16 then--铭符数量
        --return CCharmMan.Instance():GetTotalSmallCharmCount()
        return 0
    elseif Id == 17 then--铭符祝福
        --return CCharmMan.Instance(): GetTotalSmallCharmWishes()
        return 0
    elseif Id == 18 then--神符等级
        --return CCharmMan.Instance(): GetTotalBigCharmMinLevel()
        return 0
    elseif Id == 19 then--神符数量
        --return CCharmMan.Instance():GetTotalBigCharmCount()
        return 0
    elseif Id == 20 then--神符祝福
        --return CCharmMan.Instance(): GetTotalBigCharmWishes()
        return 0
    elseif Id == 21 then--翅膀数量
        return CWingsMan.Instance():GetWingsTotalNum()
    elseif Id == 22 then--翅膀等级
        return CWingsMan.Instance():GetAllWingsLevel()
    elseif Id == 23 then--天赋技能
        return 0
    elseif Id == 24 then--称号
        return game._DesignationMan: GetDesignationFightScore() 
    elseif Id == 25 then--公会技能
        return game._HostPlayer._Guild:GetGuildSkillScore()
    elseif Id == 26 then--实装站力
        return CDressMan.Instance():GetCurFightScore()
    else
        return 0
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
    local slider = uiTemplate:GetControl(1):GetComponent(ClassType.Image)
    local sliderBg = uiTemplate:GetControl(4)
    sliderBg:SetActive(true)
    if slider ~= nil then
        slider.fillAmount = math.clamp(value/basicValue, 0, 1)
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

def.override().OnDestroy = function(self)
    instance = nil 
end 

CPanelStrong.Commit()
return CPanelStrong