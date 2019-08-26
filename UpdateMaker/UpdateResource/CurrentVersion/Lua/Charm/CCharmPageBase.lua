local Lplus = require "Lplus"
local CCharmPageBase = Lplus.Class("CCharmPageBase")
local def = CCharmPageBase.define

def.field("userdata")._GameObject = nil
def.field("table")._PanelCharm = BlankTable         -- 神符Panel
def.field("table")._CharmItems = BlankTable         -- 神符列表
def.field("table")._PanelObject = BlankTable        -- Page的UI集合
def.field("boolean")._IsShow = false                  -- 是否正在显示

def.virtual().OnCreate = function(self)
end

def.virtual("dynamic").OnData = function(self, data)
    self:ShowUIFX()
end

def.method("table", "dynamic").Init = function(self, panelCharm, data)
    self._PanelCharm = panelCharm
    self._CharmItems = {}
    self._PanelObject = {}
    self:GetAllCharmItems()
    self:OnCreate()
    self:OnData(data)
end

def.virtual("dynamic").ShowPage = function(self, data)
    self._IsShow = true
    self._GameObject:SetActive(true)
    self:GetAllCharmItems()
end

def.method().GetAllCharmItems = function(self)
    self._CharmItems = {}
    local itemSet = game._HostPlayer._Package._NormalPack._ItemSet
    for i,itemData in ipairs(itemSet) do
        if itemData ~= nil and itemData._Tid ~= 0 then
            if itemData:IsCharm() then
                self._CharmItems[#self._CharmItems + 1] = itemData
            end
        end
    end
end

def.virtual().RefreshPageUI = function(self)
end

def.virtual("table").HandleOption = function(self, event)
end

def.virtual('string').OnClick = function(self, id)
end

def.virtual('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
end

def.virtual('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
end

def.virtual("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
end

def.virtual("string", "boolean").OnToggle = function(self,id, checked)
end

def.virtual("string", "number").OnDropDown = function(self, id, index)
end

def.virtual().ShowUIFX = function(self)
end

def.virtual().HideUIFX = function(self)
end

def.method().HidePage = function(self)
    self._GameObject:SetActive(false)
    self:OnHide()
end

def.virtual().OnHide = function(self)
    self._IsShow = false
end

def.virtual().OnDestory = function(self)
    self:HideUIFX()
    self._GameObject = nil
    self._PanelCharm = nil
    self._PanelObject = nil
end

CCharmPageBase.Commit()
return CCharmPageBase