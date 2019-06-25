
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIManualElementSubDes = Lplus.Extend(CPanelBase, 'CPanelUIManualElementSubDes')
local def = CPanelUIManualElementSubDes.define

local instance = nil
------------------------------------------GENERATE_TAG------------------------------------------
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")

def.field('table')._Current_SelectData = nil
def.field("userdata")._Img_ElementIcon = nil
def.field("userdata")._Lab_ElementName = nil
def.field("userdata")._Lab_ElementNameLeft = nil
def.field("userdata")._Lab_ElementDes = nil
def.field("userdata")._Frame_UnLock = nil
def.field("userdata")._Frame_Lock = nil
def.field("userdata")._Lab_ElementNameLock = nil
def.field("userdata")._Lab_ElementNameLeftLock = nil
def.field("userdata")._Lab_ElementDesLock = nil
def.field("userdata")._Btn_Next = nil
def.field("userdata")._Btn_Last = nil
def.field("number")._SelectIndex = 1
def.field("number")._Cur_Index = 1
def.field("number")._ChapterIndex = 1
def.field("number")._Num_MaxPage = 1
def.field('table')._Data_Element = nil
def.field('table')._Data_Book = nil
------------------------------------------GENERATE_TAG------------------------------------------
def.static('=>', CPanelUIManualElementSubDes).Instance = function ()
	if not instance then
        instance = CPanelUIManualElementSubDes()
        instance._PrefabPath = PATH.UI_Manual_ElementSubDes
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Img_ElementIcon = self:GetUIObject("Img_ElementIcon")
    self._Lab_ElementName = self:GetUIObject("Lab_ElementName")
    self._Lab_ElementDes = self:GetUIObject("Lab_ElementDes")
    self._Lab_ElementNameLeft = self:GetUIObject("Lab_ElementNameLeft")
    self._Btn_Next = self:GetUIObject("Btn_Next")
    self._Btn_Last = self:GetUIObject("Btn_Last")
    self._Frame_UnLock = self:GetUIObject("Frame_UnLock")
    self._Frame_Lock = self:GetUIObject("Frame_Lock")
    self._Lab_ElementNameLock = self:GetUIObject("Lab_ElementNameLock")
    self._Lab_ElementNameLeftLock = self:GetUIObject("Lab_ElementNameLeftLock")
    self._Lab_ElementDesLock = self:GetUIObject("Lab_ElementDesLock")
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override("dynamic").OnData = function(self, data)
    self._Data_Element = data
    self:OnBookInfo()
    self:OnElementSubInfo()
    self:PageBtnUp()
end

def.method().OnBookInfo = function(self)
    self._Data_Book = {}

    local template = CElementData.GetManualEntrieTemplate(self._Data_Element.EntrieId)
    self._SelectIndex = self._Data_Element.Details[self._Data_Element.CurIndex].DetailId

    local tmpDetails =  clone(self._Data_Element.Details)
    local function sortfunction(value1, value2)
        if value1 == nil or value2 == nil then
            return false
        end
        if value1.DetailId < value2.DetailId then
            return true
        else
            return false
        end
    end
    table.sort(tmpDetails, sortfunction)

    for i,v in ipairs(template.Details) do
        if tmpDetails[i].IsUnlock then
            local contents = string.split(v.Content, "*")

            if contents ~= nil and contents ~= "" then
                for _,v in ipairs(contents) do
                    self._Data_Book[#self._Data_Book+1] = 
                    {
                        _ChapterIndex = i,
                        _ChapterContent = v
                    }
                end
            else
                self._Data_Book[#self._Data_Book+1] = 
                {
                    _ChapterIndex = i,
                    _ChapterContent = v.Content
                }
            end

        else
            self._Data_Book[#self._Data_Book+1] = 
            {
                _ChapterIndex = i,
                _ChapterContent = v.UnlockTips
            }
        end
    end

    self._ChapterIndex = template.Details[self._SelectIndex].DetailId

    for i,v in ipairs(self._Data_Book) do
        if v._ChapterIndex == self._ChapterIndex then
            self._Cur_Index = i
            break
        end 
    end
    
    self._Num_MaxPage = #self._Data_Book
end

def.method().OnElementSubInfo = function(self)
    local template = CElementData.GetManualEntrieTemplate(self._Data_Element.EntrieId)
    if self._Data_Element.Details[self._Data_Element.CurIndex].IsUnlock then
        self._Frame_UnLock:SetActive(true)
        self._Frame_Lock:SetActive(false)

        GUI.SetText(self._Lab_ElementName, template.DisPlayName )
        local strIndex = string.format(StringTable.Get(20804),self._Data_Element.CurIndex)
        local detailTemplate = template.Details[self._Data_Element.CurIndex]
        GUI.SetText(self._Lab_ElementNameLeft, strIndex.." "..detailTemplate.Title)
        GUI.SetText(self._Lab_ElementDes, self._Data_Book[self._Data_Element.CurIndex]._ChapterContent)
    else
        self._Frame_UnLock:SetActive(false)
        self._Frame_Lock:SetActive(true)


        GUI.SetText(self._Lab_ElementNameLock, template.DisPlayName )
        local strIndex = string.format(StringTable.Get(20804),self._Data_Element.CurIndex)
        local detailTemplate = template.Details[self._Data_Element.CurIndex]
        GUI.SetText(self._Lab_ElementNameLeftLock, strIndex.." "..detailTemplate.Title)
        GUI.SetText(self._Lab_ElementDesLock, detailTemplate.UnlockTips)
    end

end

def.method().LastPage = function(self)
    self._Cur_Index = self._Cur_Index - 1
    if self._Cur_Index < 1 then
        self._Cur_Index = 1
        --FlashTip(StringTable.Get(20805) , "tip", 2)
        game._GUIMan:ShowTipText(StringTable.Get(20805), false)
        return
    end
    self:OnElementSubInfo()
    self:PageBtnUp()
end

def.method().NextPage = function(self)
    self._Cur_Index = self._Cur_Index + 1
    if self._Cur_Index > self._Num_MaxPage then
        self._Cur_Index = self._Num_MaxPage
        --FlashTip(StringTable.Get(20806) , "tip", 2)
        game._GUIMan:ShowTipText(StringTable.Get(20806), false)
        return
    end

    self:OnElementSubInfo()
    self:PageBtnUp()
end

def.method().PageBtnUp = function(self)
    if self._Btn_Last ~= nil then
        self._Btn_Last:SetActive(false)
        self._Btn_Next:SetActive(false)
    end
    -- if self._Cur_Index == 1 then
    --     self._Btn_Last:SetActive(false)
    -- else
    --     self._Btn_Last:SetActive(true)
    -- end

    -- if self._Cur_Index == self._Num_MaxPage then
    --     self._Btn_Next:SetActive(false)
    -- else
    --     self._Btn_Next:SetActive(true)
    -- end
end

def.override("string").OnClick = function(self,id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Next' then
        self:NextPage()
    elseif id == 'Btn_Last' then
        self:LastPage()
    elseif id == 'Btn_Close' then
        game._GUIMan:CloseByScript(self)
    end
end



CPanelUIManualElementSubDes.Commit()
return CPanelUIManualElementSubDes