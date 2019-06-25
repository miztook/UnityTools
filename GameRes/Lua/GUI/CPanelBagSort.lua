
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelRoleInfo = Lplus.ForwardDeclare("CPanelRoleInfo")
local CPanelUIGuild = require "GUI.CPanelUIGuild"
local CPanelBagSort = Lplus.Extend(CPanelBase, 'CPanelBagSort')
local def = CPanelBagSort.define

def.field("boolean")._IsDescending = false
def.field("number")._CurSortType = 0 
def.field("number")._CurPanelType = 0 
def.field("userdata")._RdoAscending = nil 
def.field("userdata")._RdoDescending = nil
def.field("userdata")._RdoBagCondition = nil 
def.field("userdata")._RdoGuildCondition = nil
def.field("userdata")._LabTitle = nil 


local PanelType = 
{
    BagSort = 1,
    GuildSort = 2,
}
def.const("table").PanelType = PanelType
local BagSortType = 
{
    Quality = 1,
    InitLevel = 2,
    CreateTimestamp = 3,
    MinLevelLimit = 4,
}
def.const("table").BagSortType = BagSortType
local GuildSortType = 
{
    Online = 1,              -- 在线
    Profession = 2,          -- 职位
    Level = 3,               -- 等级
    Battle = 4,              -- 战力
    Liveness = 5,            -- 活跃度
}
def.const("table").GuildSortType = GuildSortType

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
    self._RdoBagCondition = self:GetUIObject("Rdo_BagCondition")
    self._RdoGuildCondition = self:GetUIObject("Rdo_GuildCondition")
    self._LabTitle = self:GetUIObject("Lab_Title")
end

-- 用于背包物品排序和公会成员排序 data 为界面类型
def.override("dynamic").OnData = function(self,data)
    if data == nil then 
        warn("CPanelBagSort panelData is nil")
        game._GUIMan:CloseByScript(self) 
    return end
    local RdoNum = 0
    local RdoName = ""
    self._CurPanelType = data
    if self._CurPanelType == PanelType.BagSort then 
        RdoNum = 4
        RdoName = "Rdo_BagSort"
        GUI.SetText(self._LabTitle,StringTable.Get(317))
        self._RdoBagCondition:SetActive(true)
        self._RdoGuildCondition:SetActive(false)
        self._IsDescending = game._CDecomposeAndSortMan._IsDescending
        self._CurSortType = game._CDecomposeAndSortMan._CurSortType
        if self._CurSortType == 0 then
            self._CurSortType = BagSortType.Quality
        end
    elseif self._CurPanelType == PanelType.GuildSort then 
        RdoNum = 5
        RdoName = "Rdo_GuildSort"
        GUI.SetText(self._LabTitle,StringTable.Get(8127))
        self._RdoBagCondition:SetActive(false)
        self._RdoGuildCondition:SetActive(true)
        self._CurSortType,self._IsDescending = game._GuildMan:GetSortData()
        if self._CurSortType == 0 then 
            self._CurSortType = GuildSortType.Online 
        end
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

    for i = 1, RdoNum do
        local rdoObj = self:GetUIObject(RdoName..i)
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
    elseif (string.find(id,"Rdo_BagSort") or string.find(id,"Rdo_GuildSort")) and checked then 
        local index = tonumber(string.sub(id,-1))
        self._CurSortType = index
    end
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_Ok" then 
        if self._CurPanelType == PanelType.BagSort then 
            game._CDecomposeAndSortMan:SaveSortData(self._CurSortType,self._IsDescending)
            CPanelRoleInfo.Instance():UpdateBagSortType()
        elseif self._CurPanelType == PanelType.GuildSort then 
            game._GuildMan:SaveSortData(self._CurSortType,self._IsDescending)
            CPanelUIGuild.Instance():UpdateMemberSort()
        end
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