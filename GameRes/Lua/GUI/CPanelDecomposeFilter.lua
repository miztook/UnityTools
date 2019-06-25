
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelRoleInfo = Lplus.ForwardDeclare("CPanelRoleInfo")
local CPanelDecomposeFilter = Lplus.Extend(CPanelBase, 'CPanelDecomposeFilter')
local def = CPanelDecomposeFilter.define


-- 顺序和prefab上对应不能改
local FilterPart = 
{
    Weapon = 1,
    Armor = 2,
    Accessory = 3,
    Charm = 4,
    Consumables = 5,
    Else = 6,
    All = 7,

}
local FilterQuality = 
{
    Quality0 = 1,
    Quality1 = 2,
    Quality2 = 3,
    Quality3 = 4,
    Quality4 = 5,
    Quality5 = 6,
    Quality6 = 7,
    QualityAll = 8,

}

def.const("table").FilterPart = FilterPart
def.const("table").FilterQuality = FilterQuality
def.field("table")._SelectParts = BlankTable
def.field("table")._SelectQualitys = BlankTable
def.field("table")._CurSelectParts = BlankTable
def.field("table")._CurSelectQualitys = BlankTable
def.field("boolean")._IsSelectAllParts = true
def.field("boolean")._IsSelectAllQualitys = true
def.field("boolean")._IsSelectTimer = false

def.field("userdata")._RdoWeapon = nil 
def.field("userdata")._RdoArmor = nil 
def.field("userdata")._RdoAccessory = nil 
def.field("userdata")._RdoCharm = nil 
def.field("userdata")._RdoConsumables = nil 
def.field("userdata")._RdoElse = nil 
def.field("userdata")._RdoPointAll = nil 
def.field("userdata")._Rdo0 = nil 
def.field("userdata")._Rdo1 = nil 
def.field("userdata")._Rdo2 = nil 
def.field("userdata")._Rdo3 = nil 
def.field("userdata")._Rdo5 = nil 
def.field("userdata")._Rdo6 = nil 
def.field("userdata")._RdoAllQuality = nil 
def.field("userdata")._RdoTimer = nil 

local instance = nil
def.static('=>', CPanelDecomposeFilter).Instance = function ()  
	if not instance then
        instance = CPanelDecomposeFilter()
        instance._PrefabPath = PATH.UI_BagDecomposeFilter
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
local function SaveFilterConditions(self)
    game._CDecomposeAndSortMan:ClearCurRdoData()
    game._CDecomposeAndSortMan:SetDecomposeTimerState(self._IsSelectTimer)

    if self._SelectParts[FilterPart.All] then 
        game._CDecomposeAndSortMan:SetAllPartRdoState(true)
    else
        local IsSlectAllParts = true
        for i = 1,6 do 
            if self._SelectParts[i] then 
                game._CDecomposeAndSortMan:SavePartFilterData(i)
            else
                IsSlectAllParts = false
                game._CDecomposeAndSortMan:SetAllPartRdoState(false)
            end
        end
        if IsSlectAllParts then 
            game._CDecomposeAndSortMan:SetAllPartRdoState(true)
        end
    end

    if self._SelectQualitys[FilterQuality.QualityAll] then 
        game._CDecomposeAndSortMan:SetAllQualityRdoState(true)
    else
       local IsSlectAllQuality = true
        for i = 1,7 do 
            if self._SelectQualitys[i] then 
                game._CDecomposeAndSortMan:SaveQualityFilterData(i)
            else
                IsSlectAllQuality = false
                game._CDecomposeAndSortMan:SetAllQualityRdoState(false)
            end
        end
        if IsSlectAllQuality then 
            game._CDecomposeAndSortMan:SetAllQualityRdoState(true)
        end
    end

end

def.override().OnCreate = function(self)
    self._RdoWeapon = self:GetUIObject("Rdo_Part1")
    self._RdoArmor = self:GetUIObject("Rdo_Part2")
    self._RdoAccessory = self:GetUIObject("Rdo_Part3")
    self._RdoCharm = self:GetUIObject("Rdo_Part4")
    self._RdoConsumables = self:GetUIObject("Rdo_Part5")
    self._RdoElse = self:GetUIObject("Rdo_Part6")
    self._RdoPointAll = self:GetUIObject("Rdo_Part7")
    self._Rdo0 = self:GetUIObject("Rdo_Quality0")
    self._Rdo1 = self:GetUIObject("Rdo_Quality1")
    self._Rdo2 = self:GetUIObject("Rdo_Quality2")
    self._Rdo3 = self:GetUIObject("Rdo_Quality3")
    self._Rdo5 = self:GetUIObject("Rdo_Quality5")
    self._Rdo6 = self:GetUIObject("Rdo_Quality6")
    self._RdoAllQuality = self:GetUIObject("Rdo_Quality7")
    self._RdoTimer = self:GetUIObject("Rdo_Timer")
end

def.override("dynamic").OnData = function(self,data)

    self._SelectParts = 
    {
        [FilterPart.Weapon] = false,
        [FilterPart.Armor] = false,
        [FilterPart.Accessory] = false,
        [FilterPart.Charm] = false,
        [FilterPart.Consumables] = false,
        [FilterPart.Else] = false,
        [FilterPart.All] = false,

    }
    self._SelectQualitys = 
    {
        [FilterQuality.Quality0] = false,
        [FilterQuality.Quality1] = false,
        [FilterQuality.Quality2] = false,
        [FilterQuality.Quality3] = false,
        [FilterQuality.Quality4] = true,    -- 暂时没有
        [FilterQuality.Quality5] = false,
        [FilterQuality.Quality6] = false,
        [FilterQuality.QualityAll] = false,
    }
    self:InitPanel()   
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Cancel' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Ok' then
        SaveFilterConditions(self)
        if #self._CurSelectQualitys == 0 or #self._CurSelectParts == 0 then 
            game._GUIMan:CloseByScript(self)
        end
        CPanelRoleInfo.Instance():SetDecomposeFilter()
        game._GUIMan:CloseByScript(self)
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if string.find(id ,"Rdo_Part") then 
        local index = tonumber(string.sub(id,-1))
        if index ~= 7 and not checked then
            self._SelectParts[index] = checked
            self._RdoPointAll:GetComponent(ClassType.Toggle).isOn = false
            self._RdoPointAll:FindChild("Img_Open"):SetActive(false)
            self._SelectParts[7] = false
        elseif index ~= 7 and checked then 
            self._SelectParts[index] = checked
            local isAll = true
            for i = 1, 6 do 
                if not self._SelectParts[i] then 
                    isAll = false
                end
            end
            if not isAll then return end
            self._RdoPointAll:GetComponent(ClassType.Toggle).isOn = true
            self._RdoPointAll:FindChild("Img_Open"):SetActive(true)
            self._SelectParts[6] = true
        elseif index == 7 and checked then 
            self:SetAllPartRdo(true)
        elseif index == 7 and not checked then 
            self:SetAllPartRdo(false)
        end
    elseif string.find(id,"Rdo_Quality") then 
        local index = tonumber(string.sub(id,-1))
        if index ~= 7 and not checked then 
            self._SelectQualitys[index + 1] = checked
            self._RdoAllQuality:GetComponent(ClassType.Toggle).isOn = false
            self._RdoAllQuality:FindChild("Img_Open"):SetActive(false)
            self._SelectQualitys[8] = false
        elseif index ~= 7 and checked then 
            self._SelectQualitys[index + 1] = checked
            local isAll = true
            for i = 1,7  do 
                if not self._SelectQualitys[i] then 
                    isAll = false
                end
            end
            if not isAll then return end
            self._RdoAllQuality:GetComponent(ClassType.Toggle).isOn = true
            self._RdoAllQuality:FindChild("Img_Open"):SetActive(true)
            self._SelectQualitys[8] = true
        elseif index == 7 and checked then 
            self:SetAllQualityRdo(true)
        elseif index == 7 and not checked then 
            self:SetAllQualityRdo(false)
        end
    elseif id == "Rdo_Timer" then
        self._IsSelectTimer = checked
    end
end

def.method().InitPanel = function(self) 
    if game._CDecomposeAndSortMan._IsSelectAllQualitys then 
        self:SetAllQualityRdo(true)
    else
        local lastCurQualitys = game._CDecomposeAndSortMan:GetQualityFilterData()
        if #lastCurQualitys > 0 then
            for i ,v in ipairs(lastCurQualitys) do
                self._SelectQualitys[v] = true
            end
        -- elseif #lastCurQualitys == 0 then
        --     self._SelectQualitys[FilterQuality.Quality0] = true
        end
        for i = 1, 8 do 
            if i ~= 5 then 
                local rdoObj = self:GetUIObject("Rdo_Quality"..(i-1))
                if rdoObj ~= nil then 
                    rdoObj:GetComponent(ClassType.Toggle).isOn  = self._SelectQualitys[i]
                    rdoObj:FindChild("Img_Open"):SetActive(self._SelectQualitys[i])
                end
            end
        end
    end

    if game._CDecomposeAndSortMan._IsSelectAllParts then 
        self:SetAllPartRdo(true)
    else
        local lastCurParts = game._CDecomposeAndSortMan:GetPartFilterData()
        if #lastCurParts > 0 then
            for i ,v in ipairs(lastCurParts) do
                self._SelectParts[v] = true
            end
        -- elseif #lastCurParts == 0 then 
        --     self._SelectParts[FilterPart.Weapon] = true
        end
        for i = 1, 7 do 
            local rdoObj = self:GetUIObject("Rdo_Part"..i)
            rdoObj:GetComponent(ClassType.Toggle).isOn  = self._SelectParts[i]
            rdoObj:FindChild("Img_Open"):SetActive(self._SelectParts[i])
        end
    end
    self._IsSelectTimer = game._CDecomposeAndSortMan:GetDecomposeTimerState()
    self._RdoTimer:GetComponent(ClassType.Toggle).isOn = self._IsSelectTimer
    self._RdoTimer:FindChild("Img_Open"):SetActive(self._IsSelectTimer)
end

def.method("boolean").SetAllPartRdo = function(self,state)
    self._RdoWeapon:GetComponent(ClassType.Toggle).isOn = state
    self._RdoWeapon:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Weapon] = state
    self._RdoArmor:GetComponent(ClassType.Toggle).isOn = state
    self._RdoArmor:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Armor] = state
    self._RdoAccessory:GetComponent(ClassType.Toggle).isOn = state
    self._RdoAccessory:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Accessory] = state
    self._RdoCharm:GetComponent(ClassType.Toggle).isOn = state
    self._RdoCharm:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Charm] = state
    self._RdoConsumables:GetComponent(ClassType.Toggle).isOn = state
    self._RdoConsumables:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Consumables] = state
    self._RdoElse:GetComponent(ClassType.Toggle).isOn = state
    self._RdoElse:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.Else] = state
    self._RdoPointAll:GetComponent(ClassType.Toggle).isOn = state
    self._RdoPointAll:FindChild("Img_Open"):SetActive(state)
    self._SelectParts[FilterPart.All] = state
end

def.method("boolean").SetAllQualityRdo = function(self,state)
    self._Rdo0:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo0:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality0] = state
    self._Rdo1:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo1:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality1] = state
    self._Rdo2:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo2:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality2] = state
    self._Rdo3:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo3:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality3] = state
    self._Rdo5:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo5:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality5] = state
    self._Rdo6:GetComponent(ClassType.Toggle).isOn = state
    self._Rdo6:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.Quality6] = state
    self._RdoAllQuality:GetComponent(ClassType.Toggle).isOn = state
    self._RdoAllQuality:FindChild("Img_Open"):SetActive(state)
    self._SelectQualitys[FilterQuality.QualityAll] = state
end

def.override().OnDestroy = function (self)
    instance = nil 
end

CPanelDecomposeFilter.Commit()
return CPanelDecomposeFilter