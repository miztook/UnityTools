
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelRoleInfo = Lplus.ForwardDeclare("CPanelRoleInfo")
local CPanelBagSort = Lplus.Extend(CPanelBase, 'CPanelBagSort')
local def = CPanelBagSort.define

def.field("boolean")._IsDescending = false
def.field("number")._CurSortType = 0
def.field("userdata")._RdoAscending = nil 
def.field("userdata")._RdoDescending = nil 
 
local SortType = 
{
    Quality = 1,
    InitLevel = 2,
    CreateTimestamp = 3,
    MinLevelLimit = 4,
}
def.const("table").SortType = SortType

local instance = nil
def.static('=>', CPanelBagSort).Instance = function ()
	if not instance then
        instance = CPanelBagSort()
        instance._PrefabPath = PATH.UI_BagSort
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._RdoDescending = self:GetUIObject("Rdo_Descending")
    self._RdoAscending  = self:GetUIObject("Rdo_Ascending")
end

def.override("dynamic").OnData = function(self,data)
    self._IsDescending = game._CDecomposeAndSortMan._IsDescending
    self._CurSortType = game._CDecomposeAndSortMan._CurSortType
    if self._CurSortType == 0 then
        self._CurSortType = SortType.Quality
    end
    if not self._IsDescending then 
        self._RdoDescending:GetComponent(ClassType.Toggle).isOn = false
        self._RdoDescending:FindChild("Img_Open"):SetActive(false)
        self._RdoAscending:GetComponent(ClassType.Toggle).isOn = true
        self._RdoAscending:FindChild("Img_Open"):SetActive(true)
    else
        self._RdoDescending:GetComponent(ClassType.Toggle).isOn = true
        self._RdoDescending:FindChild("Img_Open"):SetActive(true)
        self._RdoAscending:GetComponent(ClassType.Toggle).isOn = false
        self._RdoAscending:FindChild("Img_Open"):SetActive(false)
    end
    for i = 1, 4 do
        local rdoObj = self:GetUIObject("Rdo_Sort"..i)
        if i == self._CurSortType then 
            rdoObj:GetComponent(ClassType.Toggle).isOn = true
            rdoObj:FindChild("Img_Open"):SetActive(true)
        else
            rdoObj:GetComponent(ClassType.Toggle).isOn = false
            rdoObj:FindChild("Img_Open"):SetActive(false)
        end
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)

    if id == "Rdo_Descending" and checked then 
        self._IsDescending = true
    elseif id == "Rdo_Ascending" and checked then 
        self._IsDescending = false
    elseif string.find(id,"Rdo_Sort") and checked then 
        local index = tonumber(string.sub(id,-1))
        self._CurSortType = index
    end
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_Ok" then 
        game._CDecomposeAndSortMan:SaveSortData(self._CurSortType,self._IsDescending)
        CPanelRoleInfo.Instance():UpdateBagSortType()
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Cancel" then 
        self._CurSortType = 0
        self._IsDescending = false
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnDestroy = function(self)
    instance = nil 
end

CPanelBagSort.Commit()
return CPanelBagSort