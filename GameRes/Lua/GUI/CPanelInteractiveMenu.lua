local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelInteractiveMenu = Lplus.Extend(CPanelBase, 'CPanelInteractiveMenu')
local def = CPanelInteractiveMenu.define

def.field("userdata")._BtnsParent = nil
def.field("userdata")._BtnList = nil
def.field("table")._Components = BlankTable
def.field("number")._AlignType = 0
def.field("userdata")._TargetObj = nil

local instance = nil
def.static("=>", CPanelInteractiveMenu).Instance = function()
	if instance == nil then
        instance = CPanelInteractiveMenu()
	end
    instance._PrefabPath = PATH.UI_InteractiveMenu
    instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
    instance._DestroyOnHide = true
    instance:SetupSortingParam()
	return instance
end

def.override().OnCreate = function(self)
    self._BtnsParent = self:GetUIObject("List_Btns")
    self._BtnList = self:GetUIObject("List_Btns"):GetComponent(ClassType.GNewList)
end

def.override("dynamic").OnData = function(self, data)
    if data ~= nil then
        self._Components = self:GetEnableComponents(data.comps)
        self._AlignType = data.alignType or 0
        self._TargetObj = data.targetObj or nil
    end
    self:UpdatePanel()
    self._BtnList:SetItemCount(#self._Components)
    self:SetPanelPos()
end

def.method("table", "=>", "table").GetEnableComponents = function(self, comps)
    local newComps = {}
    for _,v in ipairs(comps) do
        if v:IsMeetCondition() then
            table.insert(newComps, v)
        end
    end 
    return newComps
end

def.method().SetPanelPos = function (self)
    if self._TargetObj ~= nil and self._Panel ~= nil then
        --GameUtil.SetTipsPosition(self._TargetObj, self._BtnsParent, true)
        self:SetRelativePosition(self._TargetObj, self._BtnsParent, self._AlignType)
        --GameUtil.SetTipsPosition(self._TargetObj, self._BtnsParent, true)
    end
end

def.method("userdata", "userdata", "number").SetRelativePosition   = function(self,alignedObj, targetObj, alignType)
    local targetTrans = targetObj:GetComponent(ClassType.RectTransform)
    if alignedObj == nil or alignType == nil then
        local screenRect = GameUtil.GetRootCanvasPosAndSize(targetObj)
        targetTrans.pivot = Vector2.New(0.5, 0.5)
        targetTrans.anchoredPosition = Vector2.New(0,0)
    else
         --修改UI相对位置
        local alignedTrans = alignedObj:GetComponent(ClassType.RectTransform)
        local screenRect = GameUtil.GetRootCanvasPosAndSize(alignedObj)
        local offsetX = 0
        local offsetY = 0
        if alignType == EnumDef.AlignType.Left then
            offsetX = -alignedTrans.rect.width / 2
            targetTrans.pivot = Vector2.New(1, 0.5)
        elseif alignType == EnumDef.AlignType.Right then
            offsetX = alignedTrans.rect.width / 2
            targetTrans.pivot = Vector2.New(0, 0.5)
        elseif alignType == EnumDef.AlignType.Top then
            offsetY = targetTrans.rect.height / 2
            targetTrans.pivot = Vector2.New(0.5, 0)
        elseif alignType == EnumDef.AlignType.Bottom then
            offsetY = -alignedTrans.rect.height / 2
            targetTrans.pivot = Vector2.New(0.5, 1)
        end

        GameUtil.AlignUiElementWithOther(alignedObj, targetObj, offsetX, offsetY)
        --屏幕适应
        if -targetTrans.anchoredPosition.x + targetTrans.rect.width > screenRect.z/2 and alignType == EnumDef.AlignType.Left then
            targetTrans.anchoredPosition = Vector2.New(-screenRect.z/2+targetTrans.rect.width, targetTrans.anchoredPosition.y)
        end
        if targetTrans.anchoredPosition.x + targetTrans.rect.width > screenRect.z/2 and alignType == EnumDef.AlignType.Right then
            targetTrans.anchoredPosition = Vector2.New(screenRect.z/2-targetTrans.rect.width, targetTrans.anchoredPosition.y)
        end
        if -targetTrans.anchoredPosition.y + targetTrans.rect.height > screenRect.w/2 and alignType == EnumDef.AlignType.Bottom then
            targetTrans.anchoredPosition = Vector2.New(targetTrans.anchoredPosition.x, -screenRect.w/2+targetTrans.rect.height)
        end
        if targetTrans.anchoredPosition.y + targetTrans.rect.height > screenRect.w/2 and alignType == EnumDef.AlignType.Top then
            targetTrans.anchoredPosition = Vector2.New(targetTrans.anchoredPosition.x, screenRect.w/2-targetTrans.rect.height)
        end
    end
   
end

def.method().UpdatePanel = function(self)
    if not self._Components or #self._Components == 0 then return end
    local itemCount = #self._Components
    if itemCount > 4 then
        self._BtnList:SetPageSize(math.ceil(itemCount/4),3)
        --gLayout.Size = Vector2.New(math.ceil(itemCount/4),3)
    else
        self._BtnList:SetPageSize(1, itemCount)
        --gLayout.Size = Vector2.New(1,4)
    end
end

def.override("string").OnClick = function(self, id)
    if string.find(id,"Btn_Interactive_") then
        local index = tonumber(string.sub(id, 17, -1))
        if not self._Components or index > #self._Components then
            game._GUIMan:ShowTipText(StringTable.Get(29002), false)
        else
            self._Components[index+1]:HandleClick()
            if self._Components[index+1]._CallBack then
                self._Components[index+1]._CallBack()
            end
        end
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if id == "List_Btns" then
        if not self._Components or index > #self._Components then
            game._GUIMan:ShowTipText(StringTable.Get(29002), false)
            return
        end
        GUI.SetText(item:FindChild("Img_BtnBG/Lab_BtnText"), self._Components[index+1]:GetBtnName())
        item:SetActive(true)
	end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Btns" then
        if not self._Components or index > #self._Components then
            game._GUIMan:ShowTipText(StringTable.Get(29002), false)
            return
        end
        self._Components[index+1]:HandleClick()
        if self._Components[index+1]._CallBack then
            self._Components[index+1]._CallBack()
        end
        game._GUIMan:CloseByScript(self)
	end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._BtnsParent = nil
    self._Components = nil
    self._TargetObj = nil
end

def.override().OnDestroy = function(self)
end

CPanelInteractiveMenu.Commit()
return CPanelInteractiveMenu