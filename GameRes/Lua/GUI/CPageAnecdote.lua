local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local gtemplate = require "PB.Template"
local CPageAnecdote = Lplus.Class("CPageAnecdote")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPageAnecdote.define

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面


def.field('userdata')._List_Anecdote = nil    --左边目录
def.field("userdata")._Lab_SmallTypeName = nil --小类型名称
def.field("userdata")._List_Elements = nil  --小类型列表
def.field("userdata")._Lab_ElementSubNameAnecdote = nil --条目名称
--def.field("userdata")._Lab_ElementSubDes = nil--条目描述
def.field("userdata")._List_Attribute = nil --属性奖励列表
def.field("userdata")._Frame_ElementsContainer = nil --具体内容
def.field("userdata")._Lab_FinishTipsAnecdote = nil --完成标识
def.field("userdata")._Lab_AtrributeDes = nil --属性奖励
def.field("userdata")._Lab_AtrributeDes2 = nil --属性奖励
def.field("userdata")._Lab_AtrributeDes3 = nil --属性奖励


--def.field('userdata')._Cur_ImgD = nil -- 当前选中Item的Img_D
def.field('table')._Current_SelectData = nil
def.field('table')._Current_AttributeData = nil


def.field('table')._Current_SimulateOpenData = nil --模拟打开指定目录
def.field("number")._CurrentSelectTabIndex = 0
def.field("boolean")._IsTabOpen = false

local function Init(self)
    self._List_Anecdote = self._Parent:GetUIObject("List_Anecdote"):GetComponent(ClassType.GNewTabList)
    self._List_Elements = self._Parent:GetUIObject("List_ElementsAnecdote"):GetComponent(ClassType.GNewListLoop)
    self._List_Attribute = self._Parent:GetUIObject("List_ElementsAllAtrribute"):GetComponent(ClassType.GNewListLoop)
    self._Lab_SmallTypeName = self._Parent:GetUIObject("Lab_Tips1")
    --self.Lab_FinishTipsAnecdoteNumber = self._Parent:GetUIObject("Lab_FinishTipsAnecdoteNumber")
    self._Lab_ElementSubNameAnecdote = self._Parent:GetUIObject("Lab_ElementSubNameAnecdote")
    self._Lab_FinishTipsAnecdote = self._Parent:GetUIObject("Lab_FinishTipsAnecdote")
    self._Lab_AtrributeDes = self._Parent:GetUIObject("Lab_AtrributeDes")
    self._Lab_AtrributeDes2 = self._Parent:GetUIObject("Lab_AtrributeDes2")
    self._Lab_AtrributeDes3 = self._Parent:GetUIObject("Lab_AtrributeDes3")
    --self._Lab_ElementSubDes = self._Parent:GetUIObject("Lab_ElementSubDes")
    self._Frame_ElementsContainer = self._Parent:GetUIObject("Frame_ElementContainer")
    self._Frame_ElementsContainer:SetActive(false)

end

local instance = nil
def.static("table", "userdata", "=>", CPageAnecdote).GetInstance = function(parent, panel)
    if instance == nil then
        instance = CPageAnecdote()
        instance._Parent = parent
        instance._Panel = panel
    end
    Init(instance)
    return instance
end

---------------------------------以下方法不能删除-----------------------------
def.method("dynamic").Show = function(self, data)
    self:ListenToEvent()
    game._CManualMan:SendC2SManualDataSync()
    self._CurrentSelectTabIndex = 0
    self._Lab_FinishTipsAnecdote:SetActive(false)
    self._Lab_AtrributeDes:SetActive(false)
    self._Lab_AtrributeDes2:SetActive(false)
    self._Lab_AtrributeDes3:SetActive(false)
    self._Lab_ElementSubNameAnecdote:SetActive(false)

end

def.method().ShowData = function (self)
    local Anecdotedata = game._CManualMan:GetAllFinishAnecdote()
    self._Current_AttributeData = {}

    if Anecdotedata == nil then return end
    --判断有几个奖励
    for i,v in ipairs(Anecdotedata) do
        local template = CElementData.GetManualTemplate(v)
        if template.AttrId1 ~= 0 then
            self._Current_AttributeData[#self._Current_AttributeData+1] = 
            {
                _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId1 ).TextDisplayName, 
                _Value = template.AttrValue1
            }
        end
        if template.AttrId2 ~= 0 then
            self._Current_AttributeData[#self._Current_AttributeData+1] = 
            {
                _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId2 ).TextDisplayName,
                _Value = template.AttrValue2
            } 
        end
        if template.AttrId3 ~= 0 then
            self._Current_AttributeData[#self._Current_AttributeData+1] = 
            {
                _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId3 ).TextDisplayName, 
                _Value = template.AttrValue3
            }
        end
    end

    self:OnMenuTabChange()
    self._List_Anecdote:SelectItem(0,0)
    self:OnSelectAnecdoteSubDataChange()

    self._List_Anecdote:PlayEffect()
end

local function OnManualDataChangeEvent(sender, event)
    if event._Type == EnumDef.EManualEventType.Manual_INIT then
        instance:OnDataTabChange()
    elseif event._Type == EnumDef.EManualEventType.Manual_RECIEVE then
        instance:OnDataRecieveChange(event._Data)
    elseif event._Type == EnumDef.EManualEventType.Manual_UPDATE then
        --instance:OnClickMenuSimulate(instance._Menu,event._Data)
    end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler(require "Events.ManualDataChangeEvent", OnManualDataChangeEvent)
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler(require "Events.ManualDataChangeEvent", OnManualDataChangeEvent)  
end

--菜单
def.method().OnMenuTabChange = function(self)
    local data = game._CManualMan:GetAllAnecdoteData()
    if data ~= nil then
        --self._Menu_Frame:SetActive(true)
        self._List_Anecdote:SetItemCount(#data)
    else
        --self._Menu_Frame:SetActive(false)
    end

    -- --测试用
    -- -----------------------------------------
    -- self._List_Anecdote:SetItemCount(7)
    -- self._Frame_ElementsContainer:SetActive(true)
    -- self._List_Elements:SetItemCount(10) 
    -- self._List_Attribute:SetItemCount(5) 
end

def.method().OnSelectAnecdoteDataChange = function(self)
    if self._Current_SelectData == nil then
        self._Frame_ElementsContainer:SetActive(false)
        --self._Frame_FinishTips:SetActive(false)
        return
    end
    --print_r(self._Current_SelectData)
    self._Frame_ElementsContainer:SetActive(true)
    self._List_Elements:SetItemCount(#self._Current_SelectData.BigTypeDatas) 
    GUI.SetText(self._Lab_SmallTypeName, self._Current_SelectData.BigTypeName )
        --完成解锁的条目个数
    local finishIndex = 0
    for i,v in ipairs(self._Current_SelectData.BigTypeDatas) do
        local isAllUnlock = true
        for i2,v2 in ipairs(v.Details) do
            --如果有一个没解锁则不算完成
            if not v2.IsUnlock then
                isAllUnlock = false
                break
            end
        end
        if isAllUnlock then
            finishIndex = finishIndex + 1
        end
    end

    if finishIndex ~= 0 and finishIndex >= #self._Current_SelectData.BigTypeDatas then
    	self._Lab_FinishTipsAnecdote:SetActive(true)
    else
    	self._Lab_FinishTipsAnecdote:SetActive(false)
    end


    local template = CElementData.GetManualTemplate(self._Current_SelectData.BigTypeId)
    if template.AttrId1 ~= 0 then

        local _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId1 ).TextDisplayName 
        local _Value = template.AttrValue1

        local str = _Name..'+'.._Value

        self._Lab_AtrributeDes:SetActive(true)
        GUI.SetText(self._Lab_AtrributeDes, str )
    end

    if template.AttrId2 ~= 0 then

        local _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId2 ).TextDisplayName
        local _Value = template.AttrValue2

        local str = _Name..'+'.._Value
        
        self._Lab_AtrributeDes2:SetActive(true)
        GUI.SetText(self._Lab_AtrributeDes2, str )
    end    

    if template.AttrId3 ~= 0 then

        local _Name = CElementData.GetAttachedPropertyTemplate( template.AttrId3 ).TextDisplayName 
        local _Value = template.AttrValue3

        local str = _Name..'+'.._Value
        
        self._Lab_AtrributeDes3:SetActive(true)
        GUI.SetText(self._Lab_AtrributeDes3, str )
    end

end

def.method().OnSelectAnecdoteSubDataChange = function(self)
    if self._Current_AttributeData == nil then
        return
    end

    self._Lab_ElementSubNameAnecdote:SetActive(true)
    --GUI.SetText(self._Lab_ElementSubNameAnecdote, self._Current_SelectData.BigTypeName )
    self._List_Attribute:SetItemCount(#self._Current_AttributeData)
end

--领取了某一个条目奖励
def.method('table').OnDataRecieveChange = function (self,data)
    if data.MaType == EnumDef.ManualType.Anecdote then
        --获得此条目的数据
        -- print("OnDataRecieveChange")
        -- print(data.index)
        if self._List_Elements ~= nil then
            local strpath = "item-"..(data.index-1).."/Img_BG/Btn_Gift"
            local item = self._Parent:GetUIObject("List_ElementsManual"):FindChild(strpath)
            item:SetActive(false)
        end
    end
end

def.method('userdata','number').OnInitTabListDeep1 = function(self,item,bigTypeIndex)
    local data = game._CManualMan:GetData()
    local current_type_manuals = data[EnumDef.ManualType.Anecdote]
    local current_bigtype_data = current_type_manuals[bigTypeIndex]
    local template = CElementData.GetManualTemplate(current_bigtype_data.BigTypeId)
    item:FindChild("Img_U/Lab_Tag1"):GetComponent(ClassType.Text).text = template.DisPlayName
    item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = template.DisPlayName

    current_bigtype_data.BigTypeName = template.DisPlayName
end

def.method('userdata','number','number').OnInitTabListDeep2 = function(self,item,bigTypeIndex,smallTypeIndex)
    local data = game._CManualMan:GetData()
    local current_bigtype_array = data[EnumDef.ManualType.Anecdote]
    local current_bigtype_data = current_bigtype_array[bigTypeIndex]
    local current_smalltype_array = current_bigtype_data.BigTypeDatas[smallTypeIndex]
    local template = CElementData.GetManualTemplate(current_bigtype_data.BigTypeId)

    local cur = nil
    for i,v in ipairs(template.SmallDatas) do
        if v.SmallTypeId == current_smalltype_array.SmallTypeId then
            cur = v
            break
        end 
    end

    if cur ~= nil then 
        item:FindChild("Img_U/Lab_Tag1"):GetComponent(ClassType.Text).text = cur.SmallTypeName
        item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = cur.SmallTypeName
    end
    current_smalltype_array.SmallTypeName = cur.SmallTypeName
end



def.method('userdata','number').OnClickTabListDeep1 = function(self,list,bigTypeIndex)
    local data = game._CManualMan:GetData()
    local template = CElementData.GetManualTemplate(data[EnumDef.ManualType.Anecdote][bigTypeIndex].BigTypeId)

    if bigTypeIndex == 0 then
        self._List_Anecdote:OpenTab(0,0)
        self._Current_SelectData = nil
    elseif template.SmallDatas == nil or #template.SmallDatas == 0 then
        self._Current_SelectData = data[EnumDef.ManualType.Anecdote][bigTypeIndex]
        self:OnSelectAnecdoteDataChange()
    else
        -- local function OpenTab()
        --     --如果有小类型 打开小类型
        --     local current_type_count = #data[EnumDef.ManualType.Anecdote][bigTypeIndex].BigTypeDatas
        --     self._List_Anecdote:OpenTab(current_type_count)

        --     --默认选择了第一项
        --     if current_type_count > 0 then
        --         self:OnClickTabListDeep2(list,bigTypeIndex,1)
        --         self._IsTabOpen = true
        --     end
        -- end

        -- local function CloseTab()
        --     self._List_Anecdote:OpenTab(0)
        --     self._IsTabOpen = false
        -- end

        -- if self._CurrentSelectTabIndex == bigTypeIndex then
        --     if self._IsTabOpen then
        --         CloseTab()
        --     else
        --         OpenTab()
        --     end
        -- else
        --     OpenTab()
        -- end
    end

    self._CurrentSelectTabIndex = bigTypeIndex
end

def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    --print("OnClickMenuDeep2")
    -- local data = game._CManualMan:GetData()
    -- local current_bigtype_manuals = data[EnumDef.ManualType.Anecdote][bigTypeIndex]
    -- self._Current_SelectData = current_bigtype_manuals.BigTypeDatas[smallTypeIndex]
    -- --print_r(self._Current_SelectData)
    -- self:OnSelectAnecdoteDataChange()
end

def.method("userdata", "userdata", "number", "number").ParentTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "List_Anecdote" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnInitTabListDeep1(item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnInitTabListDeep2(item,bigTypeIndex,smallTypeIndex)
        end
    end
end

def.method("userdata", "userdata", "number", "number").ParentTabListSelectItem = function(self, list, item, main_index, sub_index)
    --print("OnTabListSelectItem", item, main_index, sub_index)
    if list.name == "List_Anecdote" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
    end
end

def.method("userdata", "string", "number").ParentInitItem = function(self, item, id, index)--item, id, index)
    local idx = index + 1
    if id == 'List_ElementsAnecdote' then
        if self._Current_SelectData == nil then
            return
        end
        local data = self._Current_SelectData.BigTypeDatas[index+1]
        local template = CElementData.GetManualEntrieTemplate(data.EntrieId)

        --是否锁住
        local Img_Lock = item:FindChild("Img_BG/Img_Lock")
        local Lab_LockDes = item:FindChild("Img_BG/Img_Lock/Lab_LockDes")

        local Img_Icon = item:FindChild("Img_BG/Img_Icon")
        local Img_Finish = item:FindChild("Img_BG/Img_Finish")
        local Btn_Gift = item:FindChild("Img_BG/Btn_Gift")
        local Lab_Name = item:FindChild("Img_BG/Lab_Name")
        local Pro_Loading = item:FindChild("Img_BG/Pro_Loading")
        local Lab_Progress = item:FindChild("Img_BG/Pro_Loading/Lab_Progress")
        local Img_Front = item:FindChild("Img_BG/Pro_Loading/Front"):GetComponent(ClassType.Image)

        --  计算进度/总进度
        local finishIndex = 0 
        --print_r(data.Details)
        for i,v in ipairs(data.Details) do
            if v.IsUnlock then
                finishIndex = finishIndex + 1
            end
        end
        --测试领奖用
        --finishIndex = #data.Details
        if finishIndex > 0 then
            Lab_Name:SetActive(true)
             GUI.SetText(Lab_Name, template.DisPlayName )
            Img_Lock:SetActive(false)
            Img_Icon:SetActive(true)
            local str = finishIndex.."/"..#data.Details
            
            GUI.SetText(Lab_Progress, str )
            Img_Front.fillAmount = finishIndex / #data.Details

            -- local iconPath = "Assets/Outputs/Interfaces/Icon/" .. data.IconPath..".png"
            -- GUITools.SetSprite(self.Img_Icon, iconPath)
            --判断是否全部完成
            if finishIndex == #data.Details then
                --如果完成 显示完成取消进度
                Img_Finish:SetActive(true)
                Pro_Loading:SetActive(false)
            else   
                Img_Finish:SetActive(false)
                Pro_Loading:SetActive(true)
            end
            
            -- 是否已经领奖
            if not data.IsDrawReward and finishIndex == #data.Details and template.RewardId ~= 0 then
                Btn_Gift:SetActive(true)
            else
                Btn_Gift:SetActive(false)
            end
        else
            Lab_Name:SetActive(false)
            Img_Lock:SetActive(true)
            GUI.SetText(Lab_LockDes, template.UnlockTips )
            Img_Icon:SetActive(false)
            Pro_Loading:SetActive(false)
            Img_Finish:SetActive(false)
            Btn_Gift:SetActive(false)
            --Lab_Progress:SetActive(false)
        end
    elseif id == 'List_ElementsAllAtrribute' then
     	local nameText = item:FindChild("Lab_Tips")
     	local valueText = item:FindChild("Lab_Values")
        if self._Current_AttributeData[index+1]._Name ~= nil then
            GUI.SetText(nameText, self._Current_AttributeData[index+1]._Name )
            GUI.SetText(valueText, tostring( '+'..self._Current_AttributeData[index+1]._Value ) )
        end
    end
end

def.method("userdata", "string", "number").ParentSelectItem = function(self, item, id, index)
    --print("OnSelectItem index: " .. tostring(index) .. ' ' .. math.floor(index/5) .. ' itemName =' .. item.name)
    if id == 'List_ElementsAnecdote' then
    elseif id == 'List_ElementsAllAtrribute' then
    end
end

def.method("userdata", "string", "string", "number").ParentSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == 'Btn_Gift' then
        local data = self._Current_SelectData.BigTypeDatas[index+1]
        if data ~= nil then
            game._CManualMan:SendC2SManualDraw(data.EntrieId)
        end     
    end
end


def.method("string").ParentClick = function (self, id)
    -- body
end

def.method().Hide = function(self)
    game._CManualMan:CleanData()
    self:UnlistenToEvent()
end

def.method().Destroy = function (self)
    self:Hide()
    instance = nil
end
------------------------------------------------------------------------------

CPageAnecdote.Commit()
return CPageAnecdote