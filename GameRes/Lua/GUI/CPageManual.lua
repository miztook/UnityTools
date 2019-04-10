local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local gtemplate = require "PB.Template"
local CPageManual = Lplus.Class("CPageManual")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPageManual.define

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面


def.field('userdata')._List_Manual = nil    --左边目录
--def.field("userdata")._Lab_SmallTypeName = nil --小类型名称
def.field("userdata")._List_Elements = nil  --小类型列表
def.field("userdata")._List_ElementsTree = nil  --小类型列表
def.field("userdata")._Lab_ElementSubName = nil --条目名称
def.field("userdata")._Lab_ElementSubDes = nil--条目描述
def.field("userdata")._List_ElementsSub = nil --条目列表
def.field("userdata")._Frame_ElementsContainer = nil --具体内容

def.field("userdata")._Frame_List_Elements = nil
def.field("userdata")._Frame_List_ElementSubContainer = nil --具体内容
def.field("userdata")._Lab_UnlockEntrie = nil --未解锁标识

--def.field('userdata')._Cur_ImgD = nil -- 当前选中Item的Img_D
def.field('table')._Current_SelectData = nil
def.field('table')._Current_SelectSubData = nil
def.field('table')._Current_SimulateOpenData = nil --模拟打开指定目录
def.field("number")._CurrentSelectTabIndex = 0
def.field("boolean")._IsTabOpen = false
def.field('number')._CurChoiceIndex = -1 --当前选中的成就Index

def.field("userdata")._List_ManualTree = nil -- 一级目录根节点
def.field("userdata")._List_ManualSubTree = nil -- 二级目录根节点


local function Init(self)
    self._List_Manual = self._Parent:GetUIObject("List_Manual"):GetComponent(ClassType.GNewTabList)
    self._List_Elements = self._Parent:GetUIObject("List_ElementsManual"):GetComponent(ClassType.GNewListLoop)
    self._List_ElementsTree = self._Parent:GetUIObject("List_ElementsManual")
    self._List_ElementsSub = self._Parent:GetUIObject("List_ElementsSub"):GetComponent(ClassType.GNewListLoop)
    --self._Lab_SmallTypeName = self._Parent:GetUIObject("Lab_SmallTypeName")
    self._Lab_ElementSubName = self._Parent:GetUIObject("Lab_ElementSubName")
    self._Lab_ElementSubDes = self._Parent:GetUIObject("Lab_ElementSubDes")
    self._Lab_UnlockEntrie = self._Parent:GetUIObject("Lab_UnlockEntrie")
    self._Frame_List_Elements = self._Parent:GetUIObject("Frame_List_Elements")
    self._Frame_List_ElementSubContainer = self._Parent:GetUIObject("Frame_List_ElementSubContainer")
    self._Frame_List_ElementSubContainer:SetActive(false)
    self._Frame_ElementsContainer = self._Parent:GetUIObject("Frame_ElementContainer")
    self._Frame_ElementsContainer:SetActive(false)
end

local instance = nil
def.static("table", "userdata", "=>", CPageManual).GetInstance = function(parent, panel)
    if instance == nil then
        instance = CPageManual()
        instance._Parent = parent
        instance._Panel = panel
    end
    Init(instance)
    return instance
end
---------------------------------以下方法不能删除-----------------------------
def.method("dynamic").Show = function(self, data)
    self._Frame_ElementsContainer:SetActive(false)
    self:ListenToEvent()
    game._CManualMan:SendC2SManualDataSync()
    self._CurrentSelectTabIndex = 0
end

def.method().ShowData = function (self)
    self:OnMenuTabChange()
    -- if self._Current_SelectData == nil then
    --     return
    -- end

    self._IsTabOpen = false
    
    --self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[1]
    --self:OnSelectManualSubDataChange(0)
    self._List_Manual:SelectItem(0,0)
    self._List_Manual:PlayEffect()
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

def.method("number").NodeShowRedPoint = function(self,index)
    self._List_ManualTree = self._Parent:GetUIObject("List_Manual"):FindChild("Viewport/Content")
    self._List_ManualSubTree = self._List_ManualTree:FindChild("SubContent")

    --判断有无大类型红点
    local isShowBigType = false
    local isShowSmallType = false
    local isShowEntEntrie = false
    --local selectdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,self._Current_SelectSubData.EntrieId)
    local selectdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,self._Current_SelectData.SmallTypeDatas[index+1].EntrieId)
    local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)

    if Map ~= nil then

            -- 是否已经领奖
            local IsDrawReward = game._CManualMan:IsDrawReward(selectdata)
            if not IsDrawReward then
                isShowEntEntrie = true
            end

            if Map[selectdata.EntrieId] ~= nil then
                Map[selectdata.EntrieId] = nil
            end

            --有新解锁 保存新解锁红点数据， 没有新解锁红点，有未领取奖励，保存未领取奖励红点数据
            if Map[selectdata.EntrieId] == nil and not IsDrawReward then 
                Map[selectdata.EntrieId] = true
            end
 
            CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Manual, Map)

        for k,v in pairs(Map) do
            if v ~= nil then
                local tmpdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,k)
                if selectdata.bindex == tmpdata.bindex and not game._CManualMan:IsDrawReward(tmpdata) then
                    isShowBigType = true
                    break
                end
            end
        end

        for k,v in pairs(Map) do
            if v ~= nil then
                local tmpdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,k)
                if selectdata.bindex == tmpdata.bindex and selectdata.sindex == tmpdata.sindex and not game._CManualMan:IsDrawReward(tmpdata) then
                    isShowSmallType = true
                    break
                end
            end
        end
    end

    local strpath = "item-"..(selectdata.bindex-1).."/Img_RedPoint"
    self._List_ManualTree:FindChild( strpath ):SetActive(isShowBigType)
    strpath = "item-"..(selectdata.sindex-1).."/Img_RedPoint"
    self._List_ManualSubTree:FindChild( strpath ):SetActive(isShowSmallType)
    strpath = "item-"..(selectdata.index-1).."/Img_RedPoint"
    self._List_ElementsTree: FindChild( strpath ):SetActive(isShowEntEntrie)

    self._Parent:ShowManualRedPoint()
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
end

--菜单
def.method().OnMenuTabChange = function(self)
    local data = game._CManualMan:GetAllManualData()
    if data ~= nil then
        --self._Menu_Frame:SetActive(true)
        self._List_Manual:SetItemCount(#data)
    else
        --self._Menu_Frame:SetActive(false)
    end

    -- --测试用
    -- -----------------------------------------
    -- self._List_Manual:SetItemCount(7)
    -- self._Frame_ElementsContainer:SetActive(true)
    -- self._List_Elements:SetItemCount(10) 
    -- self._List_ElementsSub:SetItemCount(5) 
end

def.method().OnSelectManualDataChange = function(self)
    if self._Current_SelectData == nil then
        self._Frame_ElementsContainer:SetActive(false)
        --self._Frame_FinishTips:SetActive(false)
        return
    end
    --print_r(self._Current_SelectData)
    self._Frame_ElementsContainer:SetActive(true)
    self._List_Elements:SetItemCount(#self._Current_SelectData.SmallTypeDatas) 
    print("self._Current_SelectData.SmallTypeName ", self._Current_SelectData.SmallTypeName)
    --GUI.SetText(self._Lab_SmallTypeName, self._Current_SelectData.SmallTypeName )
end

def.method('number').OnSelectManualSubDataChange = function(self,index)
    if self._Current_SelectSubData == nil then
        return
    end

    self:ShowClickView(index)
    
    --  计算进度/总进度
    local finishIndex = 0 
    --print_r(data.Details)
    for i,v in ipairs(self._Current_SelectSubData.Details) do
        if v.IsUnlock then
            finishIndex = finishIndex + 1
        end
    end

    local template = CElementData.GetManualEntrieTemplate(self._Current_SelectSubData.EntrieId)
    GUI.SetText(self._Lab_ElementSubName, template.DisPlayName )
    if finishIndex > 0 then       --self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[index+1]
        --print("self._Current_SelectSubData.EntrieId=",self._Current_SelectSubData.EntrieId)
        --print_r(self._Current_SelectSubData)
        
        self._Lab_ElementSubDes:SetActive(true)
        GUI.SetText(self._Lab_ElementSubDes, template.Content )
        --local iconPath = template.IconPath..".png"
        --GUITools.SetSprite(self._Img_ElementIcon, iconPath)

        self._Frame_List_ElementSubContainer:SetActive(true)
        self._Lab_UnlockEntrie:SetActive(false)
        self._List_ElementsSub:SetItemCount(#self._Current_SelectSubData.Details) 
    else
        self._Frame_List_ElementSubContainer:SetActive(true)
        self._Lab_ElementSubDes:SetActive(false)
        self._Lab_UnlockEntrie:SetActive(true)
        GUI.SetText(self._Lab_UnlockEntrie, template.UnlockTips )
        self._List_ElementsSub:SetItemCount(0)        
    end
end

--领取了某一个条目奖励
def.method('table').OnDataRecieveChange = function (self,data)
    if data.MaType == EnumDef.ManualType.Manual then
        --获得此条目的数据
        if self._List_Elements ~= nil then
            local strpath = "item-"..(data.index-1).."/Img_BG/Btn_Gift"
            local item = self._Parent:GetUIObject("List_ElementsManual"):FindChild(strpath)
            item:SetActive(false)
        end

        self:NodeShowRedPoint(data.index-1)
    end
end

def.method('userdata','number').OnInitTabListDeep1 = function(self,item,bigTypeIndex)
    local data = game._CManualMan:GetData()
    local current_type_manuals = data[EnumDef.ManualType.Manual]
    local template = CElementData.GetManualTemplate(current_type_manuals[bigTypeIndex].BigTypeId)
    item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = template.DisPlayName
    --item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = template.DisPlayName

    --判断有无大类型红点
    local isShow = false
    local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
    if Map ~= nil then
        for k,v in pairs(Map) do
            if v ~= nil then
                local tmpdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,k)
                local IsDrawReward = game._CManualMan:IsDrawReward(tmpdata)
                if bigTypeIndex == tmpdata.bindex and not IsDrawReward then
                    isShow = true
                    break
                end
            end
        end
    end
    item:FindChild("Img_RedPoint"):SetActive(isShow)
end

def.method('userdata','number','number').OnInitTabListDeep2 = function(self,item,bigTypeIndex,smallTypeIndex)
    local data = game._CManualMan:GetData()
    local current_bigtype_array = data[EnumDef.ManualType.Manual]
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
        item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = cur.SmallTypeName
        --item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = cur.SmallTypeName
    end
    current_smalltype_array.SmallTypeName = cur.SmallTypeName

    --判断有无小类型红点
    local isShow = false
    local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
    if Map ~= nil then
        for k,v in pairs(Map) do
            if v ~= nil then
                local tmpdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,k)
                local IsDrawReward = game._CManualMan:IsDrawReward(tmpdata)
                if bigTypeIndex == tmpdata.bindex and smallTypeIndex == tmpdata.sindex and not IsDrawReward then
                    isShow = true
                    break
                end
            end
        end
    end
    item:FindChild("Img_RedPoint"):SetActive(isShow)
end



def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
    --item:FindChild("Img_Arrow")
    local data = game._CManualMan:GetData()
    local template = CElementData.GetManualTemplate(data[EnumDef.ManualType.Manual][bigTypeIndex].BigTypeId)

    if bigTypeIndex == 0 then
        self._List_Manual:OpenTab(0)
        self._Current_SelectData = nil
    elseif template.SmallDatas == nil or #template.SmallDatas == 0 then
        --如果没有小类型 直接打开
        -- self._List_Manual:OpenTab(0)
        -- self._Current_SelectData = current_bigtype.Data
        -- self._TeamMan:C2SGetTeamListInRoom(self._Current_SelectData.Id)
        -- self:InitSeleteRoom()
    else
        local function OpenTab()
            --如果有小类型 打开小类型
            local current_type_count = #data[EnumDef.ManualType.Manual][bigTypeIndex].BigTypeDatas
            self._List_Manual:OpenTab(current_type_count)
            
            local lastMainSelectedNode = self._List_Manual:GetItem(self._List_Manual.LastMainSelected)
            if lastMainSelectedNode ~= nil then
                GUITools.SetGroupImg(lastMainSelectedNode:FindChild("Img_Arrow"), 0)
                GUITools.SetNativeSize(lastMainSelectedNode:FindChild("Img_Arrow"))
            end
            GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 2)
            GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
            --默认选择了第一项
            if current_type_count > 0 then
                self:OnClickTabListDeep2(list,bigTypeIndex,self._List_Manual.SubSelected+1)
                self._IsTabOpen = true
            end
        end

        local function CloseTab()
            self._List_Manual:OpenTab(0)
            self._IsTabOpen = false
            GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 1)
            GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
        end

        if self._CurrentSelectTabIndex == bigTypeIndex then
            if self._IsTabOpen then
                CloseTab()
            else
                OpenTab()
            end
        else
            OpenTab()
        end
    end

    self._CurrentSelectTabIndex = bigTypeIndex
end

def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    --print("OnClickMenuDeep2")
    local data = game._CManualMan:GetData()
    local current_bigtype_manuals = data[EnumDef.ManualType.Manual][bigTypeIndex]
    self._Current_SelectData = current_bigtype_manuals.BigTypeDatas[smallTypeIndex]
    --print_r(self._Current_SelectData)
    self:OnSelectManualDataChange()
end

def.method("userdata", "userdata", "number", "number").ParentTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "List_Manual" then
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
    print("OnTabListSelectItem", item, main_index, sub_index)
    if list.name == "List_Manual" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
    end
end

--显示选中的成就
def.method("number").ShowClickView = function(self, nIndex)
    if self._CurChoiceIndex >= 0 then
        local item = self._List_ElementsTree: FindChild("item-"..self._CurChoiceIndex)
        if item ~= nil then
            local img_Click =  item: FindChild("Img_BG/Img_ClickManual")
             if not IsNil(img_Click)then
                 img_Click: SetActive(false) 
            end 
        end
     end

    self._CurChoiceIndex = nIndex

    if self._CurChoiceIndex >= 0 then
        local item = self._List_ElementsTree: FindChild("item-"..self._CurChoiceIndex)
        if item ~= nil then
            local img_Click =  item: FindChild("Img_BG/Img_ClickManual")
            if not IsNil(img_Click) then
                img_Click: SetActive(true) 
            end 
        end
    end
end

def.method("userdata", "string", "number").ParentInitItem = function(self, item, id, index)--item, id, index)
    local idx = index + 1
    if id == 'List_ElementsManual' then
        if self._Current_SelectData == nil then
            return
        end
        local data = self._Current_SelectData.SmallTypeDatas[index+1]
        local template = CElementData.GetManualEntrieTemplate(data.EntrieId)

        --是否锁住
        local Img_Lock = item:FindChild("Img_BG/Img_Lock")
        local Lab_LockDes = item:FindChild("Img_BG/Img_Lock/Lab_LockDes")
        local Img_Light = item:FindChild("Img_BG/Img_Light")
        local Img_Icon = item:FindChild("Img_BG/Img_Icon")
        local Img_Finish = item:FindChild("Img_BG/Img_Finish")
        local Btn_Gift = item:FindChild("Img_BG/Btn_Gift")
        local Lab_Name = item:FindChild("Img_BG/Lab_Name")
        local Pro_Loading = item:FindChild("Img_BG/Pro_Loading")
        local Lab_Progress = item:FindChild("Img_BG/Pro_Loading/Lab_Progress")
        local Img_Front = item:FindChild("Img_BG/Pro_Loading/Front"):GetComponent(ClassType.Image)
        local Lab_UnLock = item:FindChild("Img_BG/Lab_UnLock")
        local Img_RedPoint = item:FindChild("Img_RedPoint")

        -- 是否已经领奖
        local IsDrawReward = true
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
            Lab_LockDes:SetActive(false)
            Img_Light:SetActive(true)
            Img_Icon:SetActive(true)
            Lab_UnLock:SetActive(false)
            local str = finishIndex.."/"..#data.Details
            
            GUI.SetText(Lab_Progress, str )
            Img_Front.fillAmount = finishIndex / #data.Details

            local iconPath = template.IconPath..".png"
            GUITools.SetSprite(Img_Icon, iconPath)
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
                IsDrawReward = false
                Btn_Gift:SetActive(true)
                GameUtil.PlayUISfxClipped(PATH.UIFX_BaoXiangLingQu, Btn_Gift, Btn_Gift, self._Frame_List_Elements)
            else
                Btn_Gift:SetActive(false)
                GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, Btn_Gift)
            end
        else
            Lab_Name:SetActive(false)
            Img_Lock:SetActive(true)
            --GUI.SetText(Lab_LockDes, template.UnlockTips )
            Lab_LockDes:SetActive(false)
            Img_Light:SetActive(false)
            Img_Icon:SetActive(false)
            Lab_UnLock:SetActive(true)
            GUI.SetText(Lab_UnLock, template.DisPlayName )
            Pro_Loading:SetActive(false)
            Img_Finish:SetActive(false)
            GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, Btn_Gift)
            Btn_Gift:SetActive(false)
            --Lab_Progress:SetActive(false)
        end

        --判断有无小类型红点
        local isShow = false
        local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
        if Map ~= nil then
            for k,v in pairs(Map) do
                if v ~= nil and k == data.EntrieId and not IsDrawReward then
                    isShow = true
                    break
                end
            end
        end
        Img_RedPoint:SetActive(isShow)

        if idx == 1 then
            self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[index+1]
            self:OnSelectManualSubDataChange(0)
            self:NodeShowRedPoint(index)
        end
    elseif id == 'List_ElementsSub' then
        if self._Current_SelectSubData == nil then
            return
        end
        local template = CElementData.GetManualEntrieTemplate(self._Current_SelectSubData.EntrieId)

        local detailTemplate = template.Details[index+1]
        for i,v in ipairs(template.Details) do
            if v.DetailId == self._Current_SelectSubData.Details[index+1].DetailId then
                detailTemplate = v
                break
            end
        end
        
        -- --是否解锁
        local Unlock = item:FindChild("Lab_FragmentDes/Unlock")
        local Lock = item:FindChild("Lab_FragmentDes/Lock")
        local Img_RedPoint = item:FindChild("Lab_FragmentDes/Img_RedPoint")
        Unlock:SetActive( self._Current_SelectSubData.Details[index+1].IsUnlock )
        Lock:SetActive( not self._Current_SelectSubData.Details[index+1].IsUnlock )

        if self._Current_SelectSubData.Details[index+1].IsUnlock then
            local Lab_Des = item:FindChild("Lab_FragmentDes/Unlock/Lab_Des")
            -- --字符串赋值
            local s = detailTemplate.Content
            s = string.sub(s,1,36)
            s = s.."..."
            GUI.SetText(Lab_Des, s)
            --GUI.SetText(Lab_Des, detailTemplate.Content)

            local Lab_Index = item:FindChild("Lab_FragmentDes/Unlock/Lab_Index")
            local strIndex = string.format(StringTable.Get(20804),self._Current_SelectSubData.Details[index+1].DetailId)
            GUI.SetText(Lab_Index, strIndex)


        else
            --如果没解锁 提示解锁信息
            --如果是 击杀怪物类型 则配置 TIPS%d/1
            local Lab_Des = item:FindChild("Lab_FragmentDes/Lock/Lab_Des")
            local str = string.format(detailTemplate.UnlockTips,self._Current_SelectSubData.Details[index+1].UnlockParam)
            GUI.SetText(Lab_Des, str)
            local molecule = 0
            local Denominator = 1
            if detailTemplate.UnlockType == gtemplate.ManualEntrie.EventType.KillMonster or
               detailTemplate.UnlockType == gtemplate.ManualEntrie.EventType.CollectItem or
               detailTemplate.UnlockType == gtemplate.ManualEntrie.EventType.Mine then
                molecule = self._Current_SelectSubData.Details[index+1].UnlockParam
                Denominator = detailTemplate.UnlockParam2  
            end

            local Img_Front = item:FindChild("Lab_FragmentDes/Lock/Pro_Loading/Front"):GetComponent(ClassType.Image)
            if Img_Front then
               --Img_Front.fillAmount = self._Current_SelectSubData.Details[index+1].UnlockParam/detailTemplate.UnlockParam1 

               Img_Front.fillAmount = molecule/Denominator
            end

            local Label = item:FindChild("Lab_FragmentDes/Lock/Pro_Loading/Label")
            if Label then
                --GUI.SetText(self._Label, self._Current_SelectSubData.Details[index+1].UnlockParam .. "/"..detailTemplate.UnlockParam2 )
                GUI.SetText(Label, molecule.."/"..Denominator )
            end

        end

        -- local img_Lock = item:FindChild("Lab_FragmentDes/Unlock/Img_Lock")
        -- img_Lock:SetActive( not self._Current_SelectSubData.Details[index+1].IsUnlock )

        --判断有无小类型红点
        local isShow = false
        local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
        if Map ~= nil then
            if Map[self._Current_SelectSubData.EntrieId] ~= nil and 
                type(Map[self._Current_SelectSubData.EntrieId]) == "table" and 
                Map[self._Current_SelectSubData.EntrieId][self._Current_SelectSubData.Details[index+1].DetailId] ~= nil and
                self._Current_SelectSubData.Details[index+1].IsUnlock then
                isShow = true
            end
        end
        --Img_RedPoint:SetActive(isShow)
    end
end

def.method("userdata", "string", "number").ParentSelectItem = function(self, item, id, index)
    --print("OnSelectItem index: " .. tostring(index) .. ' ' .. math.floor(index/5) .. ' itemName =' .. item.name)
    if id == 'List_ElementsManual' then
       if self._Current_SelectData == nil then
            return
        end

        self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[index+1]
        self:OnSelectManualSubDataChange(index)
        self:NodeShowRedPoint(index)
            --game._GUIMan:Open("CPanelManualElement", data)
        
    elseif id == 'List_ElementsSub' then
       if self._Current_SelectSubData == nil then
            return
        end
        --如果没有解锁跳过
        if not self._Current_SelectSubData.Details[index+1].IsUnlock then return end

        self._Current_SelectSubData.CurIndex = index + 1
        game._GUIMan:Open("CPanelUIManualElementSubDes", self._Current_SelectSubData)
    end
end

def.method("userdata", "string", "string", "number").ParentSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == 'Btn_Gift' then
        local data = self._Current_SelectData.SmallTypeDatas[index+1]
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
    self._Current_SelectData = nil
    self._Current_SelectSubData = nil
    self._CurChoiceIndex = -1
    self:UnlistenToEvent()
end

def.method().Destroy = function (self)
    self:Hide()
    instance = nil
end
------------------------------------------------------------------------------

CPageManual.Commit()
return CPageManual