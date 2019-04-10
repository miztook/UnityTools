
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
                _ChapterContent = StringTable.Get(20807)
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
    --print("self._Data_Element.EntrieId=",self._Data_Element.EntrieId)
    --print_r(self._Data_Element)

    --local iconPath = "Assets/Outputs/Interfaces/Icon/" .. temData._Data.IconPath..".png"
    --GUITools.SetSprite(self._Img_ElementIcon, iconPath)


    local strIndex = string.format(StringTable.Get(20804),self._Data_Book[self._Cur_Index]._ChapterIndex)
    GUI.SetText(self._Lab_ElementNameLeft, strIndex)

    GUI.SetText(self._Lab_ElementDes, self._Data_Book[self._Cur_Index]._ChapterContent)
end

-- def.method().OnElementSubInfo = function(self)
--     local template = CElementData.GetManualEntrieTemplate(self._Data_Element.EntrieId)
--     --print("self._Data_Element.EntrieId=",self._Data_Element.EntrieId)
--     --print_r(self._Data_Element)

--     --local iconPath = "Assets/Outputs/Interfaces/Icon/" .. temData._Data.IconPath..".png"
--     --GUITools.SetSprite(self._Img_ElementIcon, iconPath)


--     local strIndex = string.format(StringTable.Get(20804),self._Cur_Index)
--     GUI.SetText(self._Lab_ElementNameLeft, strIndex)


--     local detailTemplate = template.Details[self._Cur_Index]
--     for i,v in ipairs(template.Details) do
--         if v.DetailId == self._Data_Element.Details[self._Cur_Index].DetailId then
--             detailTemplate = v
--             break
--         end
--     end
--     self._Num_MaxPage = #template.Details
--     --GUI.SetText(self._Lab_ElementName, "此条目的名字" )

--     if self._Data_Element.Details[self._Cur_Index].IsUnlock then
--         GUI.SetText(self._Lab_ElementDes, detailTemplate.Content)
--     else
--         GUI.SetText(self._Lab_ElementDes, StringTable.Get(20807))
--     end
-- end

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
    end
end



CPanelUIManualElementSubDes.Commit()
return CPanelUIManualElementSubDes