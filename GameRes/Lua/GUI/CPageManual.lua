local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local gtemplate = require "PB.Template"
local CCommonBtn = require "GUI.CCommonBtn"
local PropertyInfoConfig = require "Data.PropertyInfoConfig"
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
def.field("userdata")._Frame_OverviewPanel            = nil--万物志总览面板
def.field("userdata")._Frame_ManualProgressPanel      = nil--万物志进度面板
def.field("userdata")._List_OverviewMenu = nil  --总览列表
def.field("userdata")._ImgProgress = nil  
def.field("userdata")._LabProgressTotal = nil  
def.field(CCommonBtn)._Btn_Activation = nil            -- 合成按钮对象
def.field("userdata")._Lab_ActivationTip = nil 
def.field("userdata")._Lab_NoAttr = nil 


def.field("userdata")._Lab_UnlockEntrie = nil --未解锁标识
def.field("userdata")._Lab_ArrTip = nil --属性加成提示标识

--def.field('userdata')._Cur_ImgD = nil -- 当前选中Item的Img_D
def.field('table')._Current_SelectData = nil
def.field('table')._Current_SelectSubData = nil
def.field('table')._Current_SimulateOpenData = nil --模拟打开指定目录
def.field("number")._CurrentSelectTabIndex = 0
def.field("boolean")._IsTabOpen = false
def.field("boolean")._IsInit = false

def.field('number')._CurChoiceIndex = -1 --当前选中的成就Index

def.field("userdata")._List_ManualTree = nil -- 一级目录根节点
def.field("userdata")._List_ManualSubTree = nil -- 二级目录根节点
def.field('table')._Table_attriObjs = nil -- 添加属性
def.field('table')._Table_OverviewAttriObjs = nil -- 添加属性
def.field("userdata")._SelectedNode             = nil -- 当前选中的一级节点
local ColorHexStr =
{
    Gray = "<color=#909AA8>%s</color>",
    White = "<color=#FFFFFF>%s</color>",
    Blue = "<color=#3FD7E5>%s</color>",
    Green = "<color=#97E03B>%s</color>",
    Red = "<color=#F70000>%s</color>",
}

local function Init(self)
    self._List_Manual = self._Parent:GetUIObject("List_Manual"):GetComponent(ClassType.GNewTabList)
    self._List_Elements = self._Parent:GetUIObject("List_ElementsManual"):GetComponent(ClassType.GNewListLoop)
    self._List_ElementsTree = self._Parent:GetUIObject("List_ElementsManual")
    self._List_ElementsSub = self._Parent:GetUIObject("List_ElementsSub"):GetComponent(ClassType.GNewListLoop)
    --self._Lab_SmallTypeName = self._Parent:GetUIObject("Lab_SmallTypeName")
    self._Lab_ElementSubName = self._Parent:GetUIObject("Lab_ElementSubName")
    self._Lab_ElementSubDes = self._Parent:GetUIObject("Lab_ElementSubDes")
    self._Lab_UnlockEntrie = self._Parent:GetUIObject("Lab_UnlockEntrie")
    self._Lab_ArrTip = self._Parent:GetUIObject("Lab_ArrTip") 
    self._Frame_List_Elements = self._Parent:GetUIObject("Frame_List_Elements")
    self._Frame_List_ElementSubContainer = self._Parent:GetUIObject("Frame_List_ElementSubContainer")
    self._Frame_List_ElementSubContainer:SetActive(false)
    self._Frame_ElementsContainer = self._Parent:GetUIObject("Frame_ElementContainer")
    self._Frame_ElementsContainer:SetActive(false)

    self._Frame_OverviewPanel = self._Parent:GetUIObject("OverviewPanel")
    self._Frame_ManualProgressPanel = self._Parent:GetUIObject("ManualProgressPanel")
    self._List_OverviewMenu = self._Parent:GetUIObject("List_OverviewMenu"):GetComponent(ClassType.GNewList)
    self._ImgProgress = self._Parent:GetUIObject("Prs_Cur1"):GetComponent(ClassType.Image)
    self._LabProgressTotal = self._Parent:GetUIObject("Lab_Total1")
    self._Btn_Activation = CCommonBtn.new(self._Parent:GetUIObject("Btn_Activation"), nil)
    self._Lab_ActivationTip = self._Parent:GetUIObject("Lab_ActivationTip")
    self._Lab_NoAttr = self._Parent:GetUIObject("Lab_NoAttr")
    self._Table_attriObjs = {}
    local strPath = ""
    for i=1,4 do
        strPath = "element_Attri"..i
        local obj = self._Parent:GetUIObject(strPath)
        self._Table_attriObjs[#self._Table_attriObjs+1] = obj
    end  
    self._Table_OverviewAttriObjs = {}
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

local function InstantiateObjByTemplate(template)
    if IsNil(template) then return end
    local obj = GameObject.Instantiate(template)
    obj:SetParent(template.parent)
    obj.localPosition = template.localPosition
    obj.localScale = template.localScale
    obj.localRotation = template.localRotation
    obj:SetActive(true)
    return obj
end

-- 设置属性名和属性值
local function SetTipsAndValue(item, tipStr, valStr)
    if IsNil(item) then return end

    local lab_tip = item:FindChild("Lab_Tips")
    if not IsNil(lab_tip) then
        GUI.SetText(lab_tip, tipStr)
    end
    local lab_val = item:FindChild("Lab_Values")
    if not IsNil(lab_val) then
        GUI.SetText(lab_val, valStr)
    end
end

def.method("boolean").ShowOverviewPanel = function(self, isShow)
    self._Frame_OverviewPanel:SetActive(isShow)
    self._Frame_ManualProgressPanel:SetActive(isShow)

    if isShow then
        local tids = CElementData.GetAllTid("ManualTotalReward")
        self._List_OverviewMenu:SetItemCount(#tids)

        local activeCount = game._CManualMan._ManualActiveCount
        local totalCount = CElementData.GetAllTid("ManualEntrie")
        self._ImgProgress.fillAmount = activeCount / #totalCount
        local str = "<color=#5CBE37>"..activeCount.."</color>" ..'/'.. #totalCount
        GUI.SetText(self._LabProgressTotal, str )

        local attriObjTemp = self._Parent:GetUIObject("Frame_Attri")
        attriObjTemp:SetActive(false)
        -- 设置属性
        local AddPropertys = game._CManualMan:GetAddPropertys()
        --print_r( AddPropertys )
        for i,v in ipairs( self._Table_OverviewAttriObjs ) do
            GameObject.Destroy( v )
        end
        self._Table_OverviewAttriObjs = {}
        for _, attriData in pairs( AddPropertys ) do
            if attriData ~= nil then
                local attri_temp = CElementData.GetAttachedPropertyTemplate(attriData._ID)
                if attri_temp ~= nil then
                    local attriObj = InstantiateObjByTemplate(attriObjTemp)
                    local tipStr = attri_temp.TextDisplayName
                    local valStr = ""
                    local isRatio = PropertyInfoConfig.IsRatio(attriData._ID)
                    if isRatio then
                        -- 属于百分比属性
                        local percent = fixFloat(attriData._Value * 100)
                        valStr = fixFloatStr(percent, 1) .. "%" -- 修正浮点数，保留小数点后一位
                    else
                        valStr = tostring( GUITools.FormatNumber(attriData._Value) )
                    end
 --                   if isHighLight then
--[[                        tipStr = string.format(ColorHexStr.White, tipStr)
                        valStr = string.format(ColorHexStr.Blue, valStr)--]]
--[[                    else
                        tipStr = string.format(ColorHexStr.Gray, tipStr)
                        valStr = string.format(ColorHexStr.Gray, valStr)
                    end--]]
                    SetTipsAndValue(attriObj, tipStr, valStr)

                    self._Table_OverviewAttriObjs[#self._Table_OverviewAttriObjs+1] = attriObj
                end
            end

        end

        self._Lab_NoAttr:SetActive( not (#self._Table_OverviewAttriObjs > 0) )
    end
end


def.method().ShowData = function (self)
    self:OnMenuTabChange()
    -- if self._Current_SelectData == nil then
    --     return
    -- end

    self._IsTabOpen = false
    self._IsInit = true
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
    elseif event._Type == EnumDef.EManualEventType.Manual_RECIEVETOTAL then
        instance:OnDataManualTotalDrawChange(event._Data._ID)
    end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler(require "Events.ManualDataChangeEvent", OnManualDataChangeEvent)
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler(require "Events.ManualDataChangeEvent", OnManualDataChangeEvent)  
end

--第一个参数，选择得第几个条目，-1 为 总览专用
--第二个参数，是否检测新增万物志红点 点击取消红点检测
def.method("number").NodeShowRedPoint = function(self,index)
    self._List_ManualTree = self._Parent:GetUIObject("List_Manual"):FindChild("Viewport/Content")
    self._List_ManualSubTree = self._List_ManualTree:FindChild("SubContent")

    --判断有无大类型红点
    local isShowBigType = false
    local isShowSmallType = false
    local isShowEntEntrie = false
    --local selectdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,self._Current_SelectSubData.EntrieId)

    -- -1特殊处理 代表总览
    if index == -1 then
        isShowBigType = game._CManualMan:NodeShowBigTypeRedPoint( 0 )
        local strpath = "item-0/Img_RedPoint"
        self._List_ManualTree:FindChild( strpath ):SetActive(isShowBigType)
    else
        local selectdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,self._Current_SelectData.SmallTypeDatas[index+1].EntrieId)

        -- 是否已经领奖
        local IsDrawReward = game._CManualMan:IsDrawReward(selectdata)
        if not IsDrawReward then
            isShowEntEntrie = true
        end
        isShowBigType = game._CManualMan:NodeShowBigTypeRedPoint( selectdata.bindex )
        isShowSmallType = game._CManualMan:NodeShowSmallTypeRedPoint( selectdata.bindex,selectdata.sindex )

        --如果是点击检测，并且没有未领取红点 只有新增红点 则点击取消红点
        --if isTestNewTypeClick and not isShowBigTypeReward and isShowBigTypeNew then
        --    isShowBigType = false
        --end
        --if isTestNewTypeClick and not isShowSmallTypeReward and isShowSmallTypeNew then
        --    isShowSmallType = false
        --end

        local strpath = "item-"..(selectdata.bindex).."/Img_RedPoint"
        self._List_ManualTree:FindChild( strpath ):SetActive(isShowBigType)
        strpath = "item-"..(selectdata.sindex-1).."/Img_RedPoint"
        self._List_ManualSubTree:FindChild( strpath ):SetActive(isShowSmallType)
        strpath = "item-"..(selectdata.index-1).."/Img_RedPoint"
        --self._List_ElementsTree: FindChild( strpath ):SetActive(isShowEntEntrie)
        self._List_ElementsTree: FindChild( strpath ):SetActive(false)
    end

    self._Parent:ShowManualRedPoint()
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
    --print("@@@@@@@@@@@@@@@",index,isShowBigType,isShowSmallType,isShowEntEntrie)
end

--菜单
def.method().OnMenuTabChange = function(self)
    local data = game._CManualMan:GetAllManualData()
    if data ~= nil then
        --self._Menu_Frame:SetActive(true)
        self._List_Manual:SetItemCount(#data+1)
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
    --print("self._Current_SelectData.SmallTypeName ", self._Current_SelectData.SmallTypeName)
    --GUI.SetText(self._Lab_SmallTypeName, self._Current_SelectData.SmallTypeName )
end

local isFinish = false
def.method('number').OnSelectManualSubDataChange = function(self,index)
    if self._Current_SelectSubData == nil then
        return
    end

    self:ShowClickView(index)
    local isActive = false
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

    self._Lab_ElementSubDes:SetActive(true)
    GUI.SetText(self._Lab_ElementSubDes, template.Content )
    self._Lab_UnlockEntrie:SetActive(false)
    --if finishIndex > 0 then       --self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[index+1]
    if self._Current_SelectSubData.IsShow then
        --print("self._Current_SelectSubData.EntrieId=",self._Current_SelectSubData.EntrieId)
        --print_r(self._Current_SelectSubData)
        
        --local iconPath = template.IconPath..".png"
        --GUITools.SetSprite(self._Img_ElementIcon, iconPath)

        self._Frame_List_ElementSubContainer:SetActive(true)
        --self._Lab_UnlockEntrie:SetActive(false)
        self._List_ElementsSub:SetItemCount(#self._Current_SelectSubData.Details) 

        if self._Current_SelectSubData.IsDrawReward then
             self._Btn_Activation:SetActive(false)
             self._Lab_ActivationTip:SetActive(true)
             GUI.SetText(self._Lab_ActivationTip, StringTable.Get(20813) )
             isActive = true
        else
            self._Lab_ActivationTip:SetActive(false)
            -- 如果已经完成 激活按钮出现
            if finishIndex == #self._Current_SelectSubData.Details then
                self._Btn_Activation:SetActive(true)
                self._Btn_Activation:SetInteractable(true)
                self._Btn_Activation:MakeGray(false)
                self._Btn_Activation:ShowFlashFx(true)
                isFinish = true
            else
                self._Btn_Activation:SetActive(true)
                self._Btn_Activation:SetInteractable(true)
                self._Btn_Activation:MakeGray(true)
                self._Btn_Activation:ShowFlashFx(false)
                isFinish = false
            end
        end
    else
        self._Lab_ActivationTip:SetActive(true)
        GUI.SetText(self._Lab_ActivationTip, string.format(StringTable.Get(20814), template.ShowParam1) )
        self._Frame_List_ElementSubContainer:SetActive(true)
        --self._Lab_ElementSubDes:SetActive(false)
        --self._Lab_UnlockEntrie:SetActive(true)
        --GUI.SetText(self._Lab_UnlockEntrie, template.UnlockTips )
        self._List_ElementsSub:SetItemCount(0) 
        self._Btn_Activation:SetActive(false)      
    end

    --print("self._Current_SelectSubData.EntrieId======",self._Current_SelectSubData.EntrieId,template.DisPlayName)
    local AddPropertys = {}
    local template = CElementData.GetManualEntrieTemplate( self._Current_SelectSubData.EntrieId )
    local ids = string.split(template.AttrIds, '*') 
    local values = string.split(template.AttrValues, '*') 
    if ids ~= nil and values ~= nil then
        for i, k in ipairs(ids) do
            local id = tonumber(ids[i])
            local value = tonumber(values[i])
            if id ~= nil and value ~= nil then
                AddPropertys[#AddPropertys + 1] = 
                {
                    _ID = id,
                    _Value = value
                }
            end
        end
    end 

    self._Lab_ArrTip:SetActive( #AddPropertys > 0 )
    --print_r(AddPropertys)
    for i,v in ipairs(self._Table_attriObjs) do

        if i <= #AddPropertys then
            v:SetActive(true)

            local attriData = AddPropertys[i]
            
            local attri_temp = CElementData.GetAttachedPropertyTemplate(attriData._ID)
            if attri_temp ~= nil then
                local tipStr = attri_temp.TextDisplayName
                local valStr = ""
                local isRatio = PropertyInfoConfig.IsRatio(attriData._ID)
                if isRatio then
                    -- 属于百分比属性
                    local percent = fixFloat(attriData._Value * 100)
                    valStr = fixFloatStr(percent, 1) .. "%" -- 修正浮点数，保留小数点后一位
                else
                    valStr = tostring(GUITools.FormatNumber(attriData._Value))
                end
                if isActive then
                    tipStr = string.format(ColorHexStr.White, tipStr)
                    valStr = string.format(ColorHexStr.Blue, valStr)
                else
                    tipStr = string.format(ColorHexStr.Gray, tipStr)
                    valStr = string.format(ColorHexStr.White, valStr)
                end
                SetTipsAndValue(v, tipStr, valStr)
            end
        else
            v:SetActive(false)
        end
    end
    
end

--领取了某一个条目奖励
def.method('table').OnDataRecieveChange = function (self,data)
    if data.MaType == EnumDef.ManualType.Manual then
        --获得此条目的数据
        if self._List_Elements ~= nil then
            local list = self._Parent:GetUIObject("List_ElementsManual")
            local strpath = "item-"..(data.index-1).."/Img_BG/Btn_Gift"
            local Btn_Gift = list:FindChild(strpath)
            Btn_Gift:SetActive(false)

            strpath = "item-"..(data.index-1).."/Img_BG/Img_Finish"
            local Img_Finish = list:FindChild(strpath)
            Img_Finish:SetActive(true)

            strpath = "item-"..(data.index-1).."/Img_BG/Pro_Loading"
            local Pro_Loading = list:FindChild(strpath)
            Pro_Loading:SetActive(false)
 
            strpath = "item-"..(data.index-1).."/Img_BG/Img_Icon"
            local Img_Icon = list:FindChild(strpath)
            GameUtil.MakeImageGray(Img_Icon, false)

            strpath = "item-"..(data.index-1)
            local item = list:FindChild(strpath) 
            GameUtil.StopUISfx(PATH.UIFX_manual_kejihuo, Img_Icon)
            GameUtil.PlayUISfxClipped(PATH.UIFX_manual_jihuo, Img_Icon, Img_Icon, item.parent.parent)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillUpgrade, 0)

            self._Btn_Activation:SetActive(false)
            self._Lab_ActivationTip:SetActive(true)
            GUI.SetText(self._Lab_ActivationTip, StringTable.Get(20813) )

            for i,v in ipairs(self._Table_attriObjs) do
                if v.activeSelf then
                    local lab_tip = v:FindChild("Lab_Tips")
                    local lab_val = v:FindChild("Lab_Values")
                    local tipStr = lab_tip:GetComponent(ClassType.Text).text
                    local valStr = lab_val:GetComponent(ClassType.Text).text

                    tipStr = string.gsub(tipStr,'#909AA8','#FFFFFF')
                    valStr = string.gsub(valStr,'#FFFFFF','#3FD7E5')

                    SetTipsAndValue(v, tipStr, valStr)
                    GameUtil.PlayUISfx(PATH.UIFX_PetAptitudeReset, v, v, 1)
                end
            end
        end

        self:NodeShowRedPoint(data.index-1)
        self:NodeShowRedPoint(-1)
    end
end

--领取了某一个阶段奖励
def.method('number').OnDataManualTotalDrawChange = function (self,id)
    --获得此条目的数据
    if self._List_OverviewMenu ~= nil then
        local tids = CElementData.GetAllTid("ManualTotalReward")
        local template = CElementData.GetManualTotalRewardTemplate(id)

        local idx = -1
        for i,v in ipairs(tids) do
            if v == id then
                idx = i
            end
        end

        idx = idx - 1
        if idx > -1 then
            local strpath = "item-"..idx.."/Btn_Get"
            local Btn_Get = self._List_OverviewMenu.gameObject:FindChild(strpath)
            Btn_Get:SetActive(false)

            strpath = "item-"..idx.."/Img_Done"
            local Btn_Get = self._List_OverviewMenu.gameObject:FindChild(strpath)
            Btn_Get:SetActive(true)
        end
        self:NodeShowRedPoint(-1)
    end
end


def.method('userdata','number').OnInitTabListDeep1 = function(self,item,bigTypeIndex)
    local img_arrow = item:FindChild("Img_Arrow") 
    if bigTypeIndex == 1 then
        item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = StringTable.Get(20811)
        img_arrow:SetActive(false)
    else
        local data = game._CManualMan:GetData()
        local current_type_manuals = data[EnumDef.ManualType.Manual]

        local template = CElementData.GetManualTemplate(current_type_manuals[bigTypeIndex-1].BigTypeId)
        item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = template.DisPlayName
        --item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = template.DisPlayName
        img_arrow:SetActive(true)
        GUITools.SetGroupImg(img_arrow, 0)
    end
    --判断有无大类型红点
    local isShow = game._CManualMan:NodeShowBigTypeRedPoint(bigTypeIndex-1)
    item:FindChild("Img_RedPoint"):SetActive(isShow)
end

def.method('userdata','number','number').OnInitTabListDeep2 = function(self,item,bigTypeIndex,smallTypeIndex)
    local data = game._CManualMan:GetData()
    local current_bigtype_array = data[EnumDef.ManualType.Manual]
    local current_bigtype_data = current_bigtype_array[bigTypeIndex-1]
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
    local isShow = game._CManualMan:NodeShowSmallTypeRedPoint(bigTypeIndex-1,smallTypeIndex)
    item:FindChild("Img_RedPoint"):SetActive(isShow)
end



def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
    if self._SelectedNode ~= nil then
        GUITools.SetGroupImg(self._SelectedNode:FindChild("Img_Arrow"), 0)
        GUITools.SetNativeSize(self._SelectedNode:FindChild("Img_Arrow"))
    end
    self._SelectedNode = item

    if bigTypeIndex == 1 then
        self:ShowOverviewPanel(true)
        --item:FindChild("Img_Arrow"):SetActive(false)
        self._Frame_ElementsContainer:SetActive(false)

        self._List_Manual:OpenTab(0)
    else
        self:ShowOverviewPanel(false)
        item:FindChild("Img_Arrow"):SetActive(true)
        --item:FindChild("Img_Arrow")
        local data = game._CManualMan:GetData()
        if data == nil then
            warn("manual data = nil")
            return
        end
        local template = CElementData.GetManualTemplate(data[EnumDef.ManualType.Manual][bigTypeIndex-1].BigTypeId)

        if bigTypeIndex == 0 then
            self._List_Manual:OpenTab(0)
            self._Current_SelectData = nil
        elseif template.SmallDatas == nil or #template.SmallDatas == 0 then
            --如果没有小类型 直接打开
--[[            self._List_Manual:OpenTab(0)
            self._Current_SelectData = current_bigtype.Data
            TeamUtil.RequestTeamListInRoom(self._Current_SelectData.Id)
            self:InitSeleteRoom()
--]]
        else
            local function OpenTab()
                --如果有小类型 打开小类型
                local current_type_count = #data[EnumDef.ManualType.Manual][bigTypeIndex-1].BigTypeDatas
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
    end
    self._CurrentSelectTabIndex = bigTypeIndex
end

local newIconTag = nil
def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    --print("OnClickMenuDeep2")
    local data = game._CManualMan:GetData()
    local current_bigtype_manuals = data[EnumDef.ManualType.Manual][bigTypeIndex-1]
    self._Current_SelectData = current_bigtype_manuals.BigTypeDatas[smallTypeIndex]
    --print_r(self._Current_SelectData)
    
    local function sortfunction(value1, value2)
        if value1 == nil or value2 == nil then
            return false
        end

        local template = CElementData.GetManualEntrieTemplate(value1.EntrieId)
        local template2 = CElementData.GetManualEntrieTemplate(value2.EntrieId)

        if value1.IsShow and not value2.IsShow then
            return true
        elseif not value1.IsShow and value2.IsShow then
            return false
        elseif not value1.IsShow and not value2.IsShow then
            return template.ShowParam1 < template2.ShowParam1
        end

        if template.EntrieQuality == template2.EntrieQuality then
            if value1.EntrieId < value2.EntrieId then
                return true
            else
                return false
            end
        end

        if template.EntrieQuality < template2.EntrieQuality then
            return true
        else
            return false
        end
    end
    table.sort(self._Current_SelectData.SmallTypeDatas, sortfunction)

    newIconTag = {}
    --新解锁 标识
    local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Manual)
    for k,v in pairs(self._Current_SelectData.SmallTypeDatas) do
        if Map ~= nil and Map[v.EntrieId] ~= nil then
            newIconTag[v.EntrieId] = true
            Map[v.EntrieId] = nil
        end
    end
    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Manual, Map)

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
    --print("OnTabListSelectItem", item, main_index, sub_index)
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

    if not self._IsInit then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
    end
    
    if self._IsInit then
        self._IsInit = false
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
        local Img_NewIcon = item:FindChild("Img_NewIcon")
        local Img_Quality = item:FindChild("Img_BG/Img_Quality")
        local Img_ClickManual = item:FindChild("Img_BG/Img_ClickManual")
         
        Img_ClickManual:SetActive(false)

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
        
        --if finishIndex > 0 then
        if data.IsShow then
            Img_Quality:SetActive(true)
            GUITools.SetGroupImg(Img_Quality,template.EntrieQuality)
        else
            Img_Quality:SetActive(false)
        end

        GameUtil.StopUISfx(PATH.UIFX_manual_kejihuo, Img_Icon)
        --测试领奖用
        --finishIndex = #data.Details
        if data.IsShow then
            Lab_Name:SetActive(true)
             GUI.SetText(Lab_Name, template.DisPlayName )
            Img_Lock:SetActive(false)
            Lab_LockDes:SetActive(false)
            Img_Light:SetActive(true)
            Img_Icon:SetActive(true)
            Lab_UnLock:SetActive(false)

            --GUI.SetText(Lab_Progress, str )
            Img_Front.fillAmount = finishIndex / #data.Details

            local iconPath = template.IconPath..".png"
            GUITools.SetSprite(Img_Icon, iconPath)

--[[            --判断是否全部完成
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
            end--]]

            Btn_Gift:SetActive(false)
            GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, Btn_Gift)

            local str = finishIndex.."/"..#data.Details
            -- 优化 是否已经激活置灰
            if data.IsDrawReward then
                Img_Finish:SetActive(true)
                Pro_Loading:SetActive(false)
                GameUtil.MakeImageGray(Img_Icon, false)
            else
                Img_Finish:SetActive(false)
                Pro_Loading:SetActive(true)
                GameUtil.MakeImageGray(Img_Icon, true)
                -- 如果已经完成 激活按钮出现
                if finishIndex == #data.Details then              
                    str = "<color=#5CBE37>".. str .. "</color>"
                    GameUtil.PlayUISfxClipped(PATH.UIFX_manual_kejihuo, Img_Icon, Img_Icon, item.parent.parent)
                else
                    str = "<color=#909AA8>".. str .. "</color>"
                end
            end
            GUI.SetText(Lab_Progress, str )
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
        local tmpdata = game._CManualMan:GetDataByTypeAndEntrieId(EnumDef.ManualType.Manual,data.EntrieId)
        local isShow = not game._CManualMan:IsDrawReward(tmpdata)

        --Img_RedPoint:SetActive(isShow)

        if idx == 1 then
            self._Current_SelectSubData = self._Current_SelectData.SmallTypeDatas[index+1]
            self:OnSelectManualSubDataChange(0)
            self:NodeShowRedPoint(index)
        end

        
        if newIconTag[data.EntrieId] ~= nil then
            Img_NewIcon:SetActive(true)
        else
            Img_NewIcon:SetActive(false)
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
        local Img_Lock = item:FindChild("Lab_FragmentDes/Unlock/Image")
        local Img_RedPoint = item:FindChild("Lab_FragmentDes/Img_RedPoint")


        Unlock:SetActive( self._Current_SelectSubData.Details[index+1].IsUnlock ) 
        Lock:SetActive( not self._Current_SelectSubData.Details[index+1].IsUnlock )

        local Lab_Des = nil
        local Lab_Index = nil
        local strIndex = string.format(StringTable.Get(20804),self._Current_SelectSubData.Details[index+1].DetailId)
        

        if self._Current_SelectSubData.Details[index+1].IsUnlock then
            --GUITools.SetGroupImg(Img_Lock,0)
            Lab_Index = item:FindChild("Lab_FragmentDes/Unlock/Lab_Index")
            Lab_Des=item:FindChild("Lab_FragmentDes/Unlock/Lab_Index/Lab_Des")
        else
            --GUITools.SetGroupImg(Img_Lock,1)
            Lab_Index = item:FindChild("Lab_FragmentDes/Lock/Lab_Index")
            Lab_Des=item:FindChild("Lab_FragmentDes/Lock/Lab_Index/Lab_Des")
        end

        GUI.SetText(Lab_Index, strIndex)

        --字符串赋值
--[[        local s = detailTemplate.Content
        s = string.sub(s,1,36)
        s = s.."..."--]]
        GUI.SetText(Lab_Des, detailTemplate.Title)
    elseif id == 'List_OverviewMenu' then
        --local data = self._Current_SelectData.SmallTypeDatas[index+1]
        local tids = CElementData.GetAllTid("ManualTotalReward")
        local template = CElementData.GetManualTotalRewardTemplate(tids[idx])

        --是否锁住
        local Lab_ManualName = item:FindChild("Lab_ManualName")
        local Lab_ManualContent = item:FindChild("Lab_ManualContent")
        local Frame_Item = item:FindChild("Frame_Item") 
        local Img_Done = item:FindChild("Img_Done") 
        local Btn_Get = item:FindChild("Btn_Get") 

        local items = GUITools.GetRewardList(template.RewardId, true)

        -- local items = reward_template.ItemRelated.RewardItems
        for i=1,5 do
            local itemObj = Frame_Item: FindChild("Img_ItemBG"..i)
            if itemObj ~= nil then
                if i <= #items then
                    itemObj:SetActive(true)
                    local item_data = items[i]
                    local item_new = itemObj:FindChild("ItemIcon")
                    if item_data.IsTokenMoney then
                        IconTools.InitTokenMoneyIcon(item_new, items[i].Data.Id, items[i].Data.Count)
                    else
                        local setting = {
                            [EItemIconTag.Number] = items[i].Data.Count,
                        }
                        IconTools.InitItemIconNew(item_new, items[i].Data.Id, setting, EItemLimitCheck.AllCheck)
                    end
                else
                    itemObj:SetActive(false)
                end
            end         
        end


        if game._CManualMan._TotleRewardIds[tids[idx]] ~= nil then
            Btn_Get:SetActive(false)
            Img_Done:SetActive(true)
        else
            Btn_Get:SetActive(true)
            Img_Done:SetActive(false)
            if game._CManualMan._ManualActiveCount >= template.TotalCount then
                
                GUITools.SetBtnFlash(Btn_Get, true)
                GameUtil.SetButtonInteractable(Btn_Get, true)
                GUITools.SetBtnGray(Btn_Get, false)
            else
                GUITools.SetBtnFlash(Btn_Get, false)
                GameUtil.SetButtonInteractable(Btn_Get, false)
                GUITools.SetBtnGray(Btn_Get, true)
            end
            
        end

        GUI.SetText(Lab_ManualName, template.Name)
        local str =  string.format(StringTable.Get(20812), game._CManualMan._ManualActiveCount, template.TotalCount)
        GUI.SetText(Lab_ManualContent, str)
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
        local Img_NewIcon = item:FindChild("Img_NewIcon")
        Img_NewIcon:SetActive(false)
            --game._GUIMan:Open("CPanelManualElement", data)
        
    elseif id == 'List_ElementsSub' then
       if self._Current_SelectSubData == nil then
            return
        end
        --如果没有解锁跳过
        --if not self._Current_SelectSubData.Details[index+1].IsUnlock then return end

        self._Current_SelectSubData.CurIndex = index + 1
        game._GUIMan:Open("CPanelUIManualElementSubDes", self._Current_SelectSubData)
    end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.method("userdata", "string", "string", "number").ParentSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == 'Btn_Gift' then
        local data = self._Current_SelectData.SmallTypeDatas[index+1]
        if data ~= nil then
            game._CManualMan:SendC2SManualDraw(data.EntrieId)
        end 
     elseif id_btn == 'Btn_Get' then  
        local item_index = index + 1

        local tids = CElementData.GetAllTid("ManualTotalReward")
        local template = CElementData.GetManualTotalRewardTemplate(tids[item_index])
        if template ~= nil then
            game._CManualMan:SendC2SManualTotalDraw(template.Id)
        end 
     elseif id == 'List_OverviewMenu' and string.find(id_btn, "Img_ItemBG") then
        local idx = index + 1
        local item_index = tonumber(string.sub(id_btn, -1))
        if not item_index then return end

        local tids = CElementData.GetAllTid("ManualTotalReward")
        local template = CElementData.GetManualTotalRewardTemplate(tids[idx])

        if template.RewardId > 0 then            
            local items = GUITools.GetRewardList(template.RewardId, true)
            local obj = item:FindChild("Frame_Item/"..id_btn)
            if items[item_index].IsTokenMoney then
                local panelData = {
                    _MoneyID = items[item_index].Data.Id,
                    _TipPos = TipPosition.FIX_POSITION,
                    _TargetObj = obj,
                }
                CItemTipMan.ShowMoneyTips(panelData)
            else
                CItemTipMan.ShowItemTips(items[item_index].Data.Id, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 obj, 
                                 TipPosition.FIX_POSITION)
            end
        end 
    end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end


def.method("string").ParentClick = function (self, id)
    -- body
    if id == "Btn_Activation" then
        if isFinish then
            local data = self._Current_SelectSubData
            if data ~= nil then
                game._CManualMan:SendC2SManualDraw(data.EntrieId)
            end 
        else
            game._GUIMan:ShowTipText(StringTable.Get(20815), false)
        end
    end
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
    if self._Btn_Activation ~= nil then
        self._Btn_Activation:Destroy()
        self._Btn_Activation = nil
    end
    self._SelectedNode = nil
    self._List_Manual = nil    --左边目录
    self._List_Elements = nil  --小类型列表
    self._List_ElementsTree = nil  --小类型列表
    self._Lab_ElementSubName = nil --条目名称
    self._Lab_ElementSubDes = nil--条目描述
    self._List_ElementsSub = nil --条目列表
    self._Frame_ElementsContainer = nil --具体内容
    self._Frame_List_Elements = nil
    self._Frame_List_ElementSubContainer = nil --具体内容
    self._Frame_OverviewPanel            = nil--万物志总览面板
    self._Frame_ManualProgressPanel      = nil--万物志进度面板
    self._List_OverviewMenu = nil  --总览列表
    self._ImgProgress = nil  
    self._LabProgressTotal = nil  
    self._Btn_Activation = nil            -- 合成按钮对象
    self._Lab_ActivationTip = nil 
    self._Lab_UnlockEntrie = nil --未解锁标识
    self._Lab_ArrTip = nil --属性加成提示标识
    self._Current_SimulateOpenData = nil --模拟打开指定目录
    self._CurrentSelectTabIndex = 0
    self._IsTabOpen = false
    self._List_ManualTree = nil -- 一级目录根节点
    self._List_ManualSubTree = nil -- 二级目录根节点
    self._Table_attriObjs = nil -- 添加属性
    self._Table_OverviewAttriObjs = nil -- 添加属性

    instance = nil
end
------------------------------------------------------------------------------

CPageManual.Commit()
return CPageManual