
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelMonsterDropItems = Lplus.Extend(CPanelBase, 'CPanelMonsterDropItems')
local def = CPanelMonsterDropItems.define
 
def.field("table")._ItemIds = nil 
def.field("function")._OkCallBack = nil 
def.field("userdata")._ListItem  = nil 


local instance = nil
def.static('=>', CPanelMonsterDropItems).Instance = function ()
	if not instance then
        instance = CPanelMonsterDropItems()
        instance._PrefabPath = PATH.UI_MonsterDropItems
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._ListItem = self:GetUIObject("List_Item"):GetComponent(ClassType.GNewList)
end

-- panelData = 
-- {
--     MonsterName,
--     ItemIds,
--     OkCallBack ,
    
-- }
def.override("dynamic").OnData = function(self, data)
    GUI.SetText(self:GetUIObject("Lab_Title"),data.MonsterName)
    self._ItemIds = data.ItemIds 
    self._OkCallBack = data.OkCallBack
    if self._ItemIds ~= nil and #self._ItemIds > 0 then 
        self._ListItem:SetItemCount(#self._ItemIds)
    end
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Yes' then
        self._OkCallBack()
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        game._GUIMan:CloseByScript(self)
    end

end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_Item" then 
        local frame_icon = GUITools.GetChild(item, 0)
        IconTools.InitItemIconNew(frame_icon, self._ItemIds[index + 1], {[EItemIconTag.Number] = 0 })
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    CItemTipMan.ShowItemTips(self._ItemIds[index + 1], TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
end

def.override().OnDestroy = function(self)
    instance = nil 
end

CPanelMonsterDropItems.Commit()
return CPanelMonsterDropItems