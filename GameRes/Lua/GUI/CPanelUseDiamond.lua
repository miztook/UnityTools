--作废 ?
local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUseDiamond = Lplus.Extend(CPanelBase, "CPanelUseDiamond")
local def = CPanelUseDiamond.define
local EResourceType = require "PB.data".EResourceType

def.field('userdata')._TipsToggleObj = nil  --提示TipsObj
def.field('userdata')._TipsToggle = nil     --提示toggle
def.field("userdata")._LabText    = nil     --文本


def.field("table")._PanelTable = nil     --界面数据
def.field("string")._CurComeType = ""  --界面来源
def.field("number")._OperaType  = -1   --操作类型 1= 消耗操作  2= 兑换操作  3 = 充值操作

local STRING_ICONNAME =
    {
        "[e]E_0[-]",
        "[e]E_1[-]",
        "[e]E_2[-]",
        "[e]E_3[-]",
    }   

local instance = nil
def.static("=>",CPanelUseDiamond).Instance = function ()
	if not instance then
        instance = CPanelUseDiamond()
        instance._PrefabPath = PATH.Panel_UseDiamond
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        --instance._DestroyOnHide = false
        instance:SetupSortingParam()
    end

	return instance
end

def.override().OnCreate = function(self)
    self._TipsToggleObj = self:GetUIObject("option")
    if not IsNil(self._TipsToggleObj) then
        self._TipsToggle = self._TipsToggleObj:GetComponent(ClassType.Toggle)
    end
    self._LabText = self:GetUIObject("Lab_Message2")
end

--初始化购买物品界面
local function InitBuyItemShow(iPanel)
    local iconName = STRING_ICONNAME[4]
    if iPanel._PanelTable._UseType == EResourceType.ResourceTypeDiamond then
        iconName = STRING_ICONNAME[3]
    elseif  iPanel._PanelTable._UseType == EResourceType.ResourceTypeGold then
        iconName = STRING_ICONNAME[1]
    end

    local strName = "<color=#" .. EnumDef.Quality2ColorHexStr[iPanel._PanelTable._Item._QualityIdex] ..">" .. iPanel._PanelTable._Item._ItemName .."</color>"
    --local showStr = string.format(StringTable.Get(20301),strName,iPanel._PanelTable._Diamond,iconName)
    local showStr = string.format(StringTable.Get(20301), strName,iPanel._PanelTable._Diamond, iconName)
    GUI.SetText(iPanel._LabText, showStr)
    iPanel._OperaType = 1
    iPanel._TipsToggleObj: SetActive(iPanel._PanelTable._tips) 
end

--初始化直接扣钱的操作
local function InitDirectlyUseDimaond(iPanel)
    --直接扣钱，但是是购买物品有数量的
    local iconName = STRING_ICONNAME[4]
    if iPanel._PanelTable._UseType == EResourceType.ResourceTypeDiamond then
        iconName = STRING_ICONNAME[3]
    elseif iPanel._PanelTable._UseType == EResourceType.ResourceTypeGold then
        iconName = STRING_ICONNAME[1]
    end

    local showStr = ""
    if iPanel._PanelTable._BuyCount ~= nil and iPanel._PanelTable._BuyItemID ~= nil then  
        local itemID = iPanel._PanelTable._BuyItemID
        local itemTemplate = CElementData.GetItemTemplate(itemID)
        if itemTemplate ~= nil then
            local strName = "<color=#" .. EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality] ..">" .. itemTemplate.Name .."</color>"
            --showStr = string.format(StringTable.Get(20302),iPanel._PanelTable._Diamond, iconName, iPanel._PanelTable._BuyCount,strName)
            showStr = string.format(StringTable.Get(20302), iPanel._PanelTable._Diamond, iconName, iPanel._PanelTable._BuyCount,strName)
        end     
    else
        --showStr = string.format(StringTable.Get(20300),iPanel._PanelTable._Diamond,iconName)
        showStr = string.format(StringTable.Get(20300), iPanel._PanelTable._Diamond, iconName)
    end

    GUI.SetText(iPanel._LabText, showStr)
    iPanel._TipsToggleObj: SetActive(iPanel._PanelTable._tips) 
    iPanel._OperaType = 1
end

--兑换界面
local function InitChangeDiamond(iPanel,nCount,isTips)  
    iPanel._TipsToggleObj: SetActive(isTips) 
    iPanel._PanelTable._Diamond = nCount
    local showStr = string.format(StringTable.Get(20304),nCount,nCount)
    GUI.SetText(iPanel._LabText, showStr)

    if isTips then
        if not  IsNil(iPanel._TipsToggle) then
            iPanel._TipsToggle.isOn = false
        end
    end

    iPanel._CurComeType = "ChangeDiamond"
    iPanel._OperaType = 2
end 

--充值界面
local function BuyDiamond(iPanel)
    GUI.SetText(iPanel._LabText, StringTable.Get(20303))
    iPanel._TipsToggleObj: SetActive(false) 
    iPanel._OperaType = 3
end


def.override("dynamic").OnData = function(self, data)
    if data == nil then --！！
 		game._GUIMan:CloseByScript(self) 
 	return end
    
    if not  IsNil(self._TipsToggle) then
        self._TipsToggle.isOn = false
    end

    self._PanelTable = data  
    self._CurComeType = data._ComeType
    if  data._PanelType == 1 then--交易界面
        if data._Item ~= nil then
            InitBuyItemShow(self)
        else
            InitDirectlyUseDimaond(self)
        end
    elseif  data._PanelType == 2 then --兑换界面
        InitChangeDiamond(self,data._Diamond,data._tips)
    elseif  data._PanelType == 3 then --充值界面
        BuyDiamond(self)
    end 
end

def.override("string").OnClick = function(self, id)
    if id == "Btn_Yes" then--确定
        if self._OperaType == 1 then--交易
             ---1 购买类型错误，直接退出 0 = 可以购买 1= 可以购买，但是需要兑换  2= 没钱，充钱！
            local ntype,nCount = CUseDiamondMan.Instance():ClickConfigCheck(self._PanelTable._UseType,self._PanelTable._Diamond)      
            if ntype == 0 then
                CUseDiamondMan.Instance(): ConfigEvent(true) 

                if CUseDiamondMan.Instance(): GetUseCount() <= 0 then
                    game._GUIMan:CloseByScript(self)  
                end                                           
            elseif ntype == 1 then
                InitChangeDiamond(self,nCount,self._PanelTable._tips)
            elseif ntype == 2 then
                BuyDiamond(self)
            else
                game._GUIMan:CloseByScript(self)  
            end  
            return     
        elseif self._OperaType == 2 then--兑换
            CUseDiamondMan.Instance():C2SChangeDiamond(self._PanelTable._Diamond)         
        elseif self._OperaType == 3 then--充值
            CUseDiamondMan.Instance():BuyDiamond()          
        end 
    elseif id == "Btn_No" then--取消
           CUseDiamondMan.Instance(): ConfigEvent(false)                    
    end  

    game._GUIMan:CloseByScript(self)   
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "option" then
        CUseDiamondMan.Instance(): SetIgnore(self._CurComeType,checked)   
    end     
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._PanelTable = nil
    CUseDiamondMan.Instance(): ConfigEvent(false) 
end

CPanelUseDiamond.Commit()
return CPanelUseDiamond