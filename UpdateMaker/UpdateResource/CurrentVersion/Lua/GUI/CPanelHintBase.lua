local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelHintBase = Lplus.Extend(CPanelBase, 'CPanelHintBase')
local def = CPanelHintBase.define

def.field("table")._ItemData = nil
def.field("boolean")._CallWithFuncs = false
def.field("table")._ValidComponents = nil
def.field("number")._PopFrom = 0
def.field("userdata")._Lay_Button = nil 
def.field("boolean")._IsShowButton = false
def.field("userdata")._Scroll1 = nil 
def.field("userdata")._Scroll2 = nil 
def.field("boolean")._IsShowCompare = false

local function SetButton(self,layButton)
    local count = #self._ValidComponents
    local listBtn = layButton:FindChild("List_Buttons"):GetComponent(ClassType.GNewList)
    listBtn:SetItemCount(count)
end 

def.method("userdata").InitButtons = function(self,BtnsObj)
    if not self._CallWithFuncs then
        local comps = self._ItemData._Components
        if comps == nil or #comps == 0 or self._PopFrom == TipsPopFrom.OTHER_PANEL or  self._PopFrom == TipsPopFrom.OTHER_PALYER or self._PopFrom ==TipsPopFrom.ROLE_PACK_COMPARE_PANEL then
            BtnsObj:SetActive(false)
        else
            BtnsObj:SetActive(true)
            self._ValidComponents = {}
                -- warn("背包界面") 
            for i,v in ipairs(comps) do 
                if v:IsEnabled() then
                    self._ValidComponents[#self._ValidComponents+1] = v
                end
            end
            SetButton(self,BtnsObj)
        end
    else
        BtnsObj:SetActive(true)
        SetButton(self,BtnsObj)
    end
end 

def.method("userdata","userdata").InitButtonPosition = function (self,mask,buttonObj)
    if not self._IsShowButton then return end
    local maskRect = mask:GetComponent(ClassType.RectTransform)
    local buttonRect = buttonObj:GetComponent(ClassType.RectTransform)
    local buttonSizeDelta = buttonRect.sizeDelta
    buttonSizeDelta.y = maskRect.sizeDelta.y
    buttonRect.sizeDelta = buttonSizeDelta
    buttonObj.localPosition.y = mask.localPosition.y
    -- body
end

def.method( "number","dynamic","userdata").ShowTime = function (self, time,isExpireTime,LabObj)
    local day = math.floor(time / 86400)
    local hour = math.floor(time % 86400 / 3600)
    local minute = math.floor((time % 86400 % 3600) / 60)
    local second = math.floor(time % 60)
    local text = ""
    if day > 0 then
        text = text..string.format(StringTable.Get(10670),day)
    end
    if hour > 0 then
        text = text..string.format(StringTable.Get(10671),hour)
    end
    if minute > 0 then
        text = text..string.format(StringTable.Get(10672),minute)
    end
    if second > 0 then 
        text = text..string.format(StringTable.Get(10673),second)
    end
    if isExpireTime == nil and self._ItemData:IsEquip() then 
        GUI.SetText(LabObj,text..StringTable.Get(10677))
        return
    elseif isExpireTime == nil and not self._ItemData:IsEquip() then
        GUI.SetText(LabObj,string.format(StringTable.Get(10692),text))
        return
    end
    if not isExpireTime then
        GUI.SetText(LabObj,string.format(StringTable.Get(10675),text))
    else
        GUI.SetText(LabObj,string.format(StringTable.Get(10676),text))
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_Buttons" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local btnName = uiTemplate:GetControl(0)
        GUI.SetText(btnName,self._ValidComponents[index + 1]:GetName())
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id ==  "List_Buttons" and id_btn == "Btn_Item" then
        local component = self._ValidComponents[index + 1]
        component:Do()
        CItemTipMan.CloseCurrentTips()  
    end
end

def.method("boolean").IsShowButton = function (self,isShow)
    if self._Lay_Button ~= nil and self._IsShowButton then
        self._Lay_Button:SetActive(isShow)
    end
end

-- 当有对比tip时设置两个tip居中
def.method("boolean").IsSetCompareTipCenter = function (self,isCenter)
    if not self._IsShowCompare then return end
    if isCenter then
        -- 两个tip居中
        local scrollRect1 = self._Scroll1:GetComponent(ClassType.RectTransform)
        local scrollRect2 = self._Scroll2:GetComponent(ClassType.RectTransform)
        local offsety = 0
        if scrollRect1.sizeDelta.y <= scrollRect2.sizeDelta.y then 
            offsety = (scrollRect2.sizeDelta.y - scrollRect1.sizeDelta.y)/2
            self._Scroll1.localPosition = Vector2.New(scrollRect1.sizeDelta.x/2,offsety)
            self._Scroll2.localPosition = Vector2.New(-scrollRect2.sizeDelta.x/2,0)
        elseif scrollRect1.sizeDelta.y > scrollRect2.sizeDelta.y then 
            offsety = (scrollRect1.sizeDelta.y - scrollRect2.sizeDelta.y)/2
            self._Scroll1.localPosition = Vector2.New(scrollRect1.sizeDelta.x/2,0)
            self._Scroll2.localPosition = Vector2.New(-scrollRect2.sizeDelta.x/2,offsety)
        end
    else
        --出现获取途径面板时移动具有对比tip的tip面板
        local scrollRect1 = self._Scroll1:GetComponent(ClassType.RectTransform)
        local scrollRect2 = self._Scroll2:GetComponent(ClassType.RectTransform)
        local offsety = 0
        if scrollRect1.sizeDelta.y <= scrollRect2.sizeDelta.y then 
            offsety = (scrollRect2.sizeDelta.y - scrollRect1.sizeDelta.y)/2
            self._Scroll1.localPosition = Vector2.New(0,offsety)
            self._Scroll2.localPosition = Vector2.New(-scrollRect2.sizeDelta.x,0)
        elseif scrollRect1.sizeDelta.y > scrollRect2.sizeDelta.y then 
            offsety = (scrollRect1.sizeDelta.y - scrollRect2.sizeDelta.y)/2
            self._Scroll1.localPosition = Vector2.New(0,0)
            self._Scroll2.localPosition = Vector2.New(-scrollRect2.sizeDelta.x,offsety)
        end
    end
end

def.override().OnHide = function(self)
    
    CPanelBase.OnHide(self)
	if self._ItemData ~= nil then
		self._ItemData._IsNewGot = false
	end
    self._IsShowCompare = false
    self._IsShowButton = false
    game._GUIMan:Close("CPanelItemApproach")    
    EventUntil.RaiseCloseTipsEvent()
    self._Lay_Button = nil 
    self._Scroll1 = nil 
    self._Scroll2 = nil 
end

CPanelHintBase.Commit()
return CPanelHintBase