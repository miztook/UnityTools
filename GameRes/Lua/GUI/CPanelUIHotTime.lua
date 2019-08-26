local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local EHotTimeType = require "PB.Template".HotTimeConfigure.EHotTimeType
local CPanelUIHotTime = Lplus.Extend(CPanelBase, 'CPanelUIHotTime')
local EItemEventType = require "PB.data".EItemEventType
local def = CPanelUIHotTime.define
local CPanelUIBuffEnter = require "GUI.CPanelUIBuffEnter" 

def.field("userdata")._Frame_BuffList = nil
def.field("userdata")._List_Buff = nil
def.field("userdata")._Lab_BuffEffectiveMap = nil
def.field("userdata")._Lab_HotTimeTag = nil

def.field("userdata")._Frame_HotTimeDesc = nil

def.field("table")._Table_HotTimeInfo = BlankTable
def.field("table")._TimerID = BlankTable

local function sort_func(value1,value2)
    if value1._Data.HotTimeType == nil or 
    value2._Data.HotTimeType == nil then
        return false
    end
    if value1._Data.HotTimeType < value2._Data.HotTimeType then
        return true
    end
    return false
end

local instance = nil
def.static('=>', CPanelUIHotTime).Instance = function()
    if not instance then
        instance = CPanelUIHotTime()
        instance._PrefabPath = PATH.UI_HotTime
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Frame_BuffList = self:GetUIObject('Frame_BuffList')    
    self._List_Buff = self:GetUIObject('List_Buff'):GetComponent(ClassType.GNewList)
    self._Lab_BuffEffectiveMap = self:GetUIObject('Lab_BuffEffectiveMap')
    self._Lab_HotTimeTag = self:GetUIObject("Lab_HotTimeTag")
    GUITools.RegisterGTextEventHandler(self._Panel, self._Lab_BuffEffectiveMap) 

    self._Frame_HotTimeDesc = self:GetUIObject("Frame_HotTimeDesc")
    local HotTimeCount = CElementData.GetAllTid("HotTimeConfigure")
    local HotTimeTable = {}
    -- local HotTimeCount = 4   -- CBT暂时只有四个hottime
    for i,v in ipairs(HotTimeCount) do
        local HotTimeConfigure = CElementData.GetTemplate("HotTimeConfigure",v)
        if HotTimeConfigure ~= nil and HotTimeConfigure.Id ~= nil then   
            if HotTimeTable[HotTimeConfigure.HotTimeType] == nil then
                HotTimeTable[HotTimeConfigure.HotTimeType] = 0
                if HotTimeConfigure.HotTimeType ~= EHotTimeType.EAdminGold 
                    and HotTimeConfigure.HotTimeType ~= EHotTimeType.EAdminExp
                    and HotTimeConfigure.HotTimeType ~= EHotTimeType.EDropLimit then
                    self._Table_HotTimeInfo[#self._Table_HotTimeInfo + 1] = 
                    {
                        _Data = HotTimeConfigure,
                        _CountDown = 0,
                        _ItemId = 0,
                    }
                end
            end
        else
            warn("HotTime Error ID："..v)
        end	
    end
    GameUtil.PlayUISfx(PATH.UIFX_HOTTIME_Bannerfenwei, self._Lab_HotTimeTag, self._Lab_HotTimeTag, -1)
end

def.override("dynamic").OnData = function (self,data)
    if data == nil then
        local C2SHotTimeDataSync = require "PB.net".C2SHotTimeDataSync
        local PBHelper = require "Network.PBHelper"
        local protocol = C2SHotTimeDataSync()
        protocol.RoleId = game._HostPlayer._ID
        PBHelper.Send(protocol)
    end     
    self:RafreshHotTime(data)
end

def.method("dynamic").RafreshHotTime = function(self, data)
    if data == nil or #self._Table_HotTimeInfo <= 0 then return end
    local GetHottimeData = {}
    local index = 0
    -- 增加Admin hottime数据
    if #data.AdminSysDatas > 0 then
        for i,v in ipairs(data.AdminSysDatas) do
            local HotTimeConfigure = CElementData.GetTemplate("HotTimeConfigure", v.HotTimeId)
            self._Table_HotTimeInfo[#self._Table_HotTimeInfo + 1] = 
            {
                _Data = HotTimeConfigure,
                _CountDown = v.CountDown,
                _Percent = v.Percent
            }
        end
    end

    -- 增加道具物品 hottime数据
    if #data.HotTimeItemDatas > 0 then
        for i,v in ipairs(data.HotTimeItemDatas) do
            for k,hottime in ipairs(self._Table_HotTimeInfo) do                
                if hottime._Data.HotTimeType == v.HotTimeType then
                    self._Table_HotTimeInfo[k] = 
                    {
                        _Data = hottime._Data,
                        _CountDown = v.CountDown,
                        _ItemId = v.ItemId,
                    } 
                end
            end
        end
    end

    table.sort(self._Table_HotTimeInfo , sort_func)
    if #data.AdminSysDatas <= 0 then
        self._List_Buff:SetItemCount(#self._Table_HotTimeInfo + 1)
    else
        self._List_Buff:SetItemCount(#self._Table_HotTimeInfo)
    end
    
    self._List_Buff:SetSelection(index)
    self._List_Buff:ScrollToStep(index) 
    GUI.SetText(self._Lab_HotTimeTag, StringTable.Get(31851))
    GUI.SetText(self._Lab_BuffEffectiveMap, StringTable.Get(31852))
    self:RafreshMainHotTimeRedPoint()
end

def.method().RafreshMainHotTimeRedPoint = function(self)
    local IsShowSfx = false
    for k,hottime in ipairs(self._Table_HotTimeInfo) do 
        if hottime._CountDown ~= nil and hottime._CountDown > 0 then
            IsShowSfx = true
            CPanelUIBuffEnter.Instance():IsShowHottimeBuffEnterSfx(IsShowSfx)
            return
        end
    end
    CPanelUIBuffEnter.Instance():IsShowHottimeBuffEnterSfx(IsShowSfx)
end

-- 获取秒小时分天
def.method("number", "=>", "string").GetTimeDes = function(self, time)
    local timeDes = ""
    local time_3 = math.floor(time / 86400)
    time = time - time_3 * 86400
	local time_1 = math.floor(time / 3600)
	time = time - time_1 * 3600
	local time_2 = math.floor(time / 60)
    time = time - time_2 * 60
    if time_3 > 0 then
		timeDes = time_3 .. StringTable.Get(1003)
	end
	if time_1 > 0 then
		timeDes = timeDes .. time_1 .. StringTable.Get(1002)
	end
	if time_2 > 0 then
		timeDes = timeDes .. time_2 .. StringTable.Get(1001)
	end
	if time > 0 then
		timeDes = timeDes .. math.modf( time % 60 ) .. StringTable.Get(1000)
	end

	return timeDes
end

def.method( "number","userdata","number").ShowTime = function (self, startTime,textObj,index)
    if  self._TimerID[index] ~= nil then
        if self._TimerID[index] ~= 0 then
            _G.RemoveGlobalTimer(self._TimerID[index])
            self._TimerID[index] = 0
        end
    else 
        self._TimerID[index] = 0
    end

    if self._TimerID[index] == 0 then
        local callback = function()
            if not IsNil(textObj) then
                GUI.SetText(textObj, self:GetTimeDes(startTime))   
            end
            startTime = startTime - 1

            if startTime <= 0 then 
                -- 消除计时器
                _G.RemoveGlobalTimer(self._TimerID[index])
                self._TimerID[index] = 0
                self._Table_HotTimeInfo[index]._CountDown = 0
                self._List_Buff:SetItemCount(#self._Table_HotTimeInfo)
            end            
        end
        self._TimerID[index] = _G.AddGlobalTimer(1, false, callback)  
    end
end

def.method().RemoveGlobalTimer = function(self)
    for i,v in pairs(self._TimerID) do
        _G.RemoveGlobalTimer(v)
        v = 0
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_Buff" then
        local Img_BuffIconBG = GUITools.GetChild(item, 1)
        local Img_BuffIcon = GUITools.GetChild(item, 2)
        local Lab_BuffName = GUITools.GetChild(item, 3)
        local Lab_BuffDesc = GUITools.GetChild(item, 4)
        local Lab_BuffState = GUITools.GetChild(item, 5)
        local Btn_BuyBuff = GUITools.GetChild(item, 6)
        local Btn_UseBuff = GUITools.GetChild(item, 9)
        local Lab_UseBuff = GUITools.GetChild(item, 11)
        local Img_BuffOpen = GUITools.GetChild(item, 12)
        local Lab_BuffNum = GUITools.GetChild(item, 13)
        local Img_BuffClose = GUITools.GetChild(item, 14)
        local Img_BuffState = GUITools.GetChild(item, 15)


        local idx = index + 1
        local HotTimeDate = self._Table_HotTimeInfo[idx]
        if HotTimeDate == nil then
            GUITools.SetItemIcon(Img_BuffIcon, "Item/defaultItemIcon")  -- 没有活动的空item显示固定不变的图标
            GUI.SetText(Lab_BuffName, StringTable.Get(19))
            GUI.SetText(Lab_BuffDesc, StringTable.Get(31857))
            Btn_BuyBuff:SetActive(false)
            Btn_UseBuff:SetActive(false)
            Img_BuffOpen:SetActive(false) 
            Img_BuffState:SetActive(false) 
            Img_BuffClose:SetActive(true)

            return
        end
        if HotTimeDate._Data.DisPlayName ~= nil then
            GUI.SetText(Lab_BuffName, HotTimeDate._Data.DisPlayName)
        end

        GUITools.SetItemIcon(Img_BuffIcon, HotTimeDate._Data.IconPath)
        -- warn("init --->>>", HotTimeDate._Data.HotTimeType, HotTimeDate._Data.DisPlayName, HotTimeDate._CountDown)
        local BuffDesc = nil
        local normalPack = game._HostPlayer._Package._NormalPack
        if HotTimeDate._Data.HotTimeType ~= nil then
            if HotTimeDate._Data.HotTimeType == EHotTimeType.ESingleGold then
                local itemCount = normalPack:GetItemCount(HotTimeDate._ItemId)
                -- warn("OninitItem =======>>> ", HotTimeDate._Data.DisPlayName, HotTimeDate._CountDown, HotTimeDate._ItemId, itemCount)
                local Percent = 0
                Btn_BuyBuff:SetActive(false)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    local item = CElementData.GetItemTemplate(HotTimeDate._ItemId)
                    if item ~= nil and item.EventType1 == EItemEventType.ItemEvent_HotTime then 
                        Percent = item.Type1Param3
                    end
                    Lab_BuffState:SetActive(true)
                    local time = HotTimeDate._CountDown/1000

                    self:ShowTime(time, Lab_BuffState, idx)
                    Btn_UseBuff:SetActive(false)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    Img_BuffClose:SetActive(false)
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                    game._HottimeGoldItemTid = HotTimeDate._ItemId
                    game._IsGoldHottime = true
                else
                    Lab_BuffState:SetActive(false)
                    Img_BuffOpen:SetActive(false)   
                    Img_BuffState:SetActive(false)
                    Img_BuffClose:SetActive(true)
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG) 
                    game._HottimeGoldItemTid = 0
                    game._IsGoldHottime = false
                end
                BuffDesc = string.format(HotTimeDate._Data.Content, (Percent.."%"))
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.ESingleExp then
                -- if HotTimeDate._ItemId == 0 then
                --     HotTimeDate._ItemId = 97    -- hottime固定经验道具加成Tid
                -- end
                local itemCount = normalPack:GetItemCount(HotTimeDate._ItemId)
                local Percent = 0
                Btn_BuyBuff:SetActive(false)
                -- warn("OninitItem =======>>> ", HotTimeDate._Data.DisPlayName, HotTimeDate._CountDown, HotTimeDate._ItemId, itemCount)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    local item = CElementData.GetItemTemplate(HotTimeDate._ItemId)
                    if item ~= nil and item.EventType1 == EItemEventType.ItemEvent_HotTime then 
                        Percent = item.Type1Param3
                    end
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext) 
                    Lab_BuffState:SetActive(true)
                    local time = HotTimeDate._CountDown/1000
                    self:ShowTime(time, Lab_BuffState, idx)

                    Btn_UseBuff:SetActive(false)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    Img_BuffClose:SetActive(false)
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                    game._HottimeExpItemTid = HotTimeDate._ItemId
                    game._IsExpHottime = true
                else
                    Lab_BuffState:SetActive(false)
                    Img_BuffOpen:SetActive(false)   
                    Img_BuffState:SetActive(false)
                    Img_BuffClose:SetActive(true)
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG)
                    game._HottimeExpItemTid = 0
                    game._IsExpHottime = false
                end
                BuffDesc = string.format(HotTimeDate._Data.Content, (Percent.."%"))
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.EMonthGold then
                local itemCount = normalPack:GetItemCount(HotTimeDate._ItemId)
                -- warn("OninitItem =======>>> ", HotTimeDate._Data.DisPlayName, HotTimeDate._CountDown, HotTimeDate._ItemId, itemCount)
                GUITools.SetItemIcon(Img_BuffIcon, PATH.ICON_ITEN_HOTTIME_02)
                local Percent = 0
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    local item = CElementData.GetItemTemplate(HotTimeDate._ItemId)
                    if item ~= nil and item.EventType1 == EItemEventType.ItemEvent_HotTime then 
                        Percent = item.Type1Param3
                    end
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext)  
                    Lab_BuffState:SetActive(true)
                    local time = HotTimeDate._CountDown/1000

                    self:ShowTime(time, Lab_BuffState, idx)
                    Btn_BuyBuff:SetActive(false)
                    Btn_UseBuff:SetActive(false)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                else
                    Lab_BuffState:SetActive(false)
                    Img_BuffOpen:SetActive(false)   
                    Img_BuffState:SetActive(false)
                    if itemCount > 0 then
                        Btn_BuyBuff:SetActive(false)
                        Btn_UseBuff:SetActive(true)
                        -- GUI.SetText(Lab_UseBuff, string.format(StringTable.Get(31853), itemCount))
                        GUI.SetText(Lab_BuffNum, "("..itemCount..")")
                    elseif itemCount <= 0 then
                        Btn_BuyBuff:SetActive(true)
                        Btn_UseBuff:SetActive(false)
                    end
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG) 
                end
                BuffDesc = string.format(HotTimeDate._Data.Content, (Percent.."%"))
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.EMonthExp then
                local itemCount = normalPack:GetItemCount(HotTimeDate._ItemId)
                local Percent = 0
                -- warn("OninitItem =======>>> ", HotTimeDate._Data.DisPlayName, HotTimeDate._CountDown, HotTimeDate._ItemId, itemCount)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    local item = CElementData.GetItemTemplate(HotTimeDate._ItemId)
                    if item ~= nil and item.EventType1 == EItemEventType.ItemEvent_HotTime then 
                        Percent = item.Type1Param3
                    end
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext) 
                    Lab_BuffState:SetActive(true)
                    local time = HotTimeDate._CountDown/1000
                    self:ShowTime(time, Lab_BuffState, idx)

                    Btn_BuyBuff:SetActive(false)
                    Btn_UseBuff:SetActive(false)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                else
                    Lab_BuffState:SetActive(false)
                    Img_BuffOpen:SetActive(false)   
                    Img_BuffState:SetActive(false)
                    if itemCount > 0 then
                        Btn_BuyBuff:SetActive(false)
                        Btn_UseBuff:SetActive(true)
                        -- GUI.SetText(Lab_UseBuff, string.format(StringTable.Get(31853), itemCount))
                        GUI.SetText(Lab_BuffNum, "("..itemCount..")")
                    elseif itemCount <= 0 then
                        Btn_BuyBuff:SetActive(true)
                        Btn_UseBuff:SetActive(false)
                    end
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG)
                end
                BuffDesc = string.format(HotTimeDate._Data.Content, (Percent.."%"))
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.EAdminGold then                
                Btn_BuyBuff:SetActive(false)
                Btn_UseBuff:SetActive(false)
                Lab_BuffState:SetActive(true)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext) 
                    local time = HotTimeDate._CountDown/1000
                    self:ShowTime(time, Lab_BuffState, idx)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    BuffDesc = string.format(HotTimeDate._Data.Content, (HotTimeDate._Percent.."%"))
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                else
                    -- GUI.SetText(Lab_BuffState, StringTable.Get(31850))  
                    Img_BuffOpen:SetActive(false) 
                    Img_BuffState:SetActive(false)  
                    BuffDesc = StringTable.Get(19469)  
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Huang, Img_BuffIconBG)    
                end
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.EAdminExp then
                Btn_BuyBuff:SetActive(false)
                Btn_UseBuff:SetActive(false)
                Lab_BuffState:SetActive(true)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext)
                    local time = HotTimeDate._CountDown/1000
                    self:ShowTime(time, Lab_BuffState, idx)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    BuffDesc = string.format(HotTimeDate._Data.Content, (HotTimeDate._Percent.."%"))
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                else                
                    -- GUI.SetText(Lab_BuffState, StringTable.Get(31850))
                    Img_BuffOpen:SetActive(false)
                    Img_BuffState:SetActive(false)
                    BuffDesc = StringTable.Get(19469)  
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG)
                end
            elseif HotTimeDate._Data.HotTimeType == EHotTimeType.EDropLimit then
                Btn_BuyBuff:SetActive(false)
                Btn_UseBuff:SetActive(false)
                Lab_BuffState:SetActive(true)
                if HotTimeDate._CountDown ~= nil and HotTimeDate._CountDown > 0 then
                    -- local Timetext = os.date("%H:%M:%S", HotTimeDate._CountDown/1000)
                    -- GUI.SetText(Lab_BuffState, Timetext)
                    local time = HotTimeDate._CountDown/1000
                    self:ShowTime(time, Lab_BuffState, idx)
                    Img_BuffOpen:SetActive(true)
                    Img_BuffState:SetActive(true)
                    BuffDesc = string.format(HotTimeDate._Data.Content, (HotTimeDate._Percent.."%"))
                    GameUtil.PlayUISfxClipped(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG, Img_BuffIconBG, self:GetUIObject('List_BuffView'))
                else                
                    -- GUI.SetText(Lab_BuffState, StringTable.Get(31850))
                    Img_BuffOpen:SetActive(false)
                    Img_BuffState:SetActive(false)
                    BuffDesc = StringTable.Get(19469)  
                    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Lan, Img_BuffIconBG)
                end
            end
        end        
        if BuffDesc ~= nil then
            GUI.SetText(Lab_BuffDesc, BuffDesc)
        end
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == "Btn_BuyItem" then
        -- TODO()
        if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Mall) then
            local ShopType = tonumber(CElementData.GetSpecialIdTemplate(901).Value)     -- 红钻商店的特殊ID = 901
            -- game._GUIMan:Open("CPanelMall", ShopType)

            -- game._GUIMan:Open("CPanelMall", 11)
            game._GUIMan:Open("CPanelMall", 33)
            game._GUIMan:CloseByScript(self)
        else
            game._CGuideMan:OnShowTipByFunUnlockConditions(1, EnumDef.EGuideTriggerFunTag.Mall)
        end
    elseif id_btn == "Btn_UseItem" then
        -- 使用物品
        local HotTimeDate = self._Table_HotTimeInfo[index + 1]
        local ItemTid = nil
        local normalPack = game._HostPlayer._Package._NormalPack
        if HotTimeDate._Data.HotTimeType == EHotTimeType.ESingleGold then
            ItemTid = HotTimeDate._ItemId
        elseif HotTimeDate._Data.HotTimeType == EHotTimeType.ESingleExp then
            ItemTid = HotTimeDate._ItemId        
        end
        if ItemTid ~= nil and ItemTid > 0 then
            local itemData = normalPack:GetItem(ItemTid)
            if not itemData then warn("item == nil !!!!!!!!!!!!!!!!!!!!") return end
            itemData:Use()
        end
        -- game._GUIMan:CloseByScript(self)
    end
end

def.override("string").OnClick = function(self, id)
    if id == "Btn_HottimeDesc" then
        self:OnHotTimeDesc(true)
    elseif id == 'Frame_HotTimeDesc' then
        self:OnHotTimeDesc(false)
    elseif id == "Btn_Close" then
        game._GUIMan:CloseByScript(self)
    end
end

def.method('number', 'number').OnGTextClick = function(self, msgId, linkId) 
    -- warn("-------点在了GTextItemLink上-------msgId == ", msgId, "linkId == ", linkId)
    if linkId == 1 then
        game._GUIMan:CloseByScript(self)
        game._GUIMan:Open("CPanelMap", nil)        
    end
end

def.override("userdata").OnPointerClick = function(self,target)
    if target ~= nil then
        self:OnHotTimeDesc(false)
    end    
end

def.method("boolean").OnHotTimeDesc = function(self, isShow)
    self._Frame_HotTimeDesc:SetActive(isShow)
    if isShow then
        local Lab_DescContent1 = GUITools.GetChild(self._Frame_HotTimeDesc, 7)
        local Lab_DescContent2 = GUITools.GetChild(self._Frame_HotTimeDesc, 8)
        local Lab_DescContent3 = GUITools.GetChild(self._Frame_HotTimeDesc, 9)
        local Lab_DescContent4 = GUITools.GetChild(self._Frame_HotTimeDesc, 10)
        local Lab_DescContent5 = GUITools.GetChild(self._Frame_HotTimeDesc, 11)
        Lab_DescContent5:SetActive(false)
        GUI.SetText(Lab_DescContent1, StringTable.Get(31854))  
        GUI.SetText(Lab_DescContent2, StringTable.Get(31855)) 
        GUI.SetText(Lab_DescContent3, StringTable.Get(31856)) 
        GUI.SetText(Lab_DescContent4, StringTable.Get(31857)) 
    end
end

def.override().OnDestroy = function (self)
    GameUtil.StopUISfx(PATH.UIFX_HOTTIME_Bannerfenwei,self._Lab_HotTimeTag)
    self:RafreshMainHotTimeRedPoint()
    self._Frame_BuffList = nil
    self._List_Buff = nil
    self._Lab_BuffEffectiveMap = nil
    self._Lab_HotTimeTag = nil
    self._Table_HotTimeInfo = {}
    self:RemoveGlobalTimer()
    self._TimerID = {}
    self._Frame_HotTimeDesc = nil    
end

CPanelUIHotTime.Commit()
return CPanelUIHotTime