--------------------------------------------
   --------------福利相关-----------------
--------------------------------------------

local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CElementData = require "Data.CElementData"
local EScriptEventType = require "PB.data".EScriptEventType
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPanelUIWelfare = Lplus.Extend(CPanelBase, 'CPanelUIWelfare')
local def = CPanelUIWelfare.define
local TextType = ClassType.Text

local CPageGloryInfo = require "GUI.CPageGloryInfo"         -- 荣耀之路
def.field(CPageGloryInfo)._CPageGloryInfo = nil

local CPageSpecialSign = require "GUI.CPageSpecialSign"     -- 特殊签到
def.field(CPageSpecialSign)._CPageSpecialSign = nil

local CPageOnlineReward = require "GUI.CPageOnlineReward"     -- 在线奖励
def.field(CPageOnlineReward)._CPageOnlineReward = nil

local CPageExchange = require "GUI.CPageExchange"     -- 材料兑换
def.field(CPageExchange)._CPageExchange = nil

def.field("userdata")._Frame_WelfareList = nil 
def.field('userdata')._List_MenuType = nil
-- def.field('userdata')._List_SignMenu = nil
def.field('userdata')._ScrollSign = nil
def.field("userdata")._Frame_ActivityClose = nil 

def.field("userdata")._List_Sign = nil



-- def.field("userdata")._Lab_Gold = nil
-- def.field("userdata")._Lab_Diamond = nil
-- def.field("userdata")._Lab_Diamond_Lock = nil
def.field("userdata")._Frame_Sign = nil
def.field(CFrameCurrency)._Frame_Money = nil
def.field("number")._CurFrameType = 1 --当前页
def.field("table")._WelfareType = BlankTable
def.field("table")._SignInfo = BlankTable
def.field("table")._SignDays = BlankTable
def.field("table")._SignDaysInfo = BlankTable
def.field("table")._RewardDaysInfo = BlankTable
def.field("table")._DoubleSignDays = BlankTable

def.field("number")._CurDay = 1 --当前可签到天
def.field("number")._CurSignedDays = 0  -- 当前已签天数总和
-- def.field("userdata")._CurrentGetItem = nil

def.field("table")._PreviewRewardData = nil
def.field("number")._PreRewardSpecialID = 441
def.field("number")._DorpAdvancedSpecialID = 442
def.field("number")._DorpMiddleSpecialID = 443
def.field("number")._DorpCommonSpecialID = 444
def.field("table")._AllRewardTable = nil
def.field("table")._ListNodeName = nil
def.field("number")._FlowerItemCount = 0
def.field("number")._MaterialItemCount = 0
def.field("number")._CostItemFlowerId = 0 
def.field("number")._CostItemMaterialId = 0
def.field("string")._CostItemFlowerName = '' 
def.field("string")._CostItemMaterialName = '' 
def.field("number")._CurToggle = 0

def.field("table")._SpecialSignInfo = BlankTable    -- 特殊签到详细信息

local GLORY_UNLOCKED_BY_TID = 110  -- 冒险生涯教学功能Tid

local eventType = -1 
local scriptId = 0

local ToggleType = 
{
    None = 0,
    WelfareType = 1 ,
    ElfType = 2,
}

local instance = nil
def.static('=>', CPanelUIWelfare).Instance = function ()
	if not instance then
        instance = CPanelUIWelfare()
        instance._PrefabPath = PATH.UI_Welfare
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        
        -- instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Frame_WelfareList = self:GetUIObject("Frame_WelfareList")
    self._List_MenuType = self:GetUIObject('List_MenuType'):GetComponent(ClassType.GNewList)
    -- self._List_SignMenu = self:GetUIObject('List_SignMenu'):GetComponent(ClassType.GNewListLoop)
    self._Frame_Sign = self:GetUIObject("Frame_Sign")
    self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)

    -- self._FrameRewardList = self:GetUIObject("Frame_RewardList")

    self._ScrollSign = self._Frame_Sign:GetComponent(ClassType.Scrollbar)
    
    self._CPageGloryInfo = CPageGloryInfo.new(self, self:GetUIObject("Frame_GloryVIP"))
    self._CurFrameType = EnumDef.WelfareType._Sign
      
    self._Frame_ActivityClose = self:GetUIObject("Frame_ActivityClose")
    self._CPageSpecialSign = CPageSpecialSign.new(self, self:GetUIObject("Frame_SpecialSign"))
    self._CPageOnlineReward = CPageOnlineReward.new(self, self:GetUIObject("Frame_OnlineReward"))
    self._CPageExchange = CPageExchange.new(self, self:GetUIObject("Frame_Festival"))
    self._List_Sign = self:GetUIObject("List_Sign")

end

def.override("dynamic").OnData = function(self,data)
    self._HelpUrlType = HelpPageUrlType.Welfare
    self._WelfareType = game._CWelfareMan:GetAllWelfareTypes() 
    self._SignDays = game._CWelfareMan:GetAllSignDays()
    self._SignInfo = game._CWelfareMan:GetAllSignInfo()
    self._CurDay = game._CWelfareMan:GetCurrentDay()  
    self._CurSignedDays = game._CWelfareMan:GetCurrentSignedDays()  
    self._List_Sign:GetComponent(ClassType.GNewList):SetItemCount(game._CWelfareMan:GetCurrentTotalDay())
    -- 初始化精灵献礼模板数据
    if data == nil then 
        self:OpenPanelToggle(ToggleType.WelfareType)
    else 
        -- 直接打开对应的页签
        self:OpenPanelToggle(ToggleType.WelfareType)            
        if data == "SpecialSign" or data == EnumDef.WelfareType._SpecialSign then
            self._CurFrameType = EnumDef.WelfareType._SpecialSign
        elseif data == EnumDef.WelfareType._Sign then
            self._CurFrameType = EnumDef.WelfareType._Sign
        elseif data == EnumDef.WelfareType._GloryVIP then  
            if game._CFunctionMan:IsUnlockByFunTid(GLORY_UNLOCKED_BY_TID) then -- if game._HostPlayer:GetGloryLevel() > 0 then         
                self._CurFrameType = EnumDef.WelfareType._GloryVIP
            else
                game._GUIMan:ShowTipText(StringTable.Get(23), false)
            end
        elseif data == EnumDef.WelfareType._OnLineReward then
            self._CurFrameType = EnumDef.WelfareType._OnLineReward
        end
    end

end



def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)  
    if not self._Frame_Money:OnClick(id) then
        if id == 'Btn_Back' then
            game._GUIMan:CloseByScript(self)
        elseif id == 'Btn_Exit' then
            game._GUIMan:CloseSubPanelLayer()

        elseif id == "Btn_VIPStore" or id == 'Btn_FightScoreUp' or id == 'Btn_GloryLeft' or id == 'Btn_GloryRight' or id == "Btn_BuyGloryGift" or id == "Btn_GloryGift" then
            self._CPageGloryInfo:OnClick(id)

        elseif id == "Btn_TotalItem" then
            self._CPageSpecialSign:OnClick(id)

        elseif id == "Btn_CheckOnlineReward" then
            self._CPageOnlineReward:OnClick(id)
        elseif id == "Btn_ExchangeDesc" then
            self._CPageExchange:OnClick(id)
        elseif string.find(id,"Btn_Item_Days") then
            local index = tonumber(string.sub(id, string.len("Btn_Item_Days")+1,-1))   
            self:OnSelectSignDay(self:GetUIObject("Btn_Item_Days".. tostring(index)), index)
        
        elseif id == "Btn_PlusFllower" or id == "Btn_PlusItem" then 
            -- 需要等商城做完才能补功能
            local strValue = CElementData.GetSpecialIdTemplate(901).Value
            game._GUIMan:Open("CPanelMall",tonumber(strValue))
        end
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "Rdo_btnWelfare" then 
        self._CurToggle = ToggleType.WelfareType
        if self._SignInfo == nil or #self._SignInfo == 0 then 
            self._SignInfo = game._CWelfareMan:GetAllSignInfo()  
            scriptId = self._SignInfo._Data.Id
            game._CWelfareMan:OnGetWelfareData()
        end
        
        -- 切回福利默认选中签到
        -- self._CurFrameType = EnumDef.WelfareType._Sign
        self._Frame_WelfareList:SetActive(true)   
        self:RefrashWelfare(self._CurFrameType)
    end 
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_MenuType' then
        local Img_SelectType = GUITools.GetChild(item , 1)
        local Lab_WelfareName = GUITools.GetChild(item , 2)
        local Img_RedPoint = GUITools.GetChild(item , 3)
        local Lab_WelfareNameD = GUITools.GetChild(item , 4)
        -- nameText.text = temData._Data.Name
        -- self._CurFrameType = index + 1
        local ItemName = ""
        if self._WelfareType[index + 1] == EnumDef.WelfareType._Sign then
            ItemName = StringTable.Get(19472)
            Img_RedPoint:SetActive(game._CWelfareMan:GetSignRedPointState())
        elseif self._WelfareType[index + 1] == EnumDef.WelfareType._GloryVIP then
            ItemName = StringTable.Get(19473)
            Img_RedPoint:SetActive(game._CWelfareMan:GetGloryRedPointState())
        elseif self._WelfareType[index + 1] == EnumDef.WelfareType._SpecialSign then
            ItemName = StringTable.Get(19481)
            Img_RedPoint:SetActive(game._CWelfareMan:GetSpecialSignRedPointState())
        elseif self._WelfareType[index + 1] == EnumDef.WelfareType._OnLineReward then
            ItemName = StringTable.Get(19495)
            Img_RedPoint:SetActive(game._CWelfareMan:IsShowOnlineRewardRedPoint())
        elseif self._WelfareType[index + 1] == EnumDef.WelfareType._Festival then
            ItemName = StringTable.Get(19446)
            -- Img_RedPoint:SetActive(game._CWelfareMan:IsShowOnlineRewardRedPoint())
        end
        GUI.SetText(Lab_WelfareName , ItemName)   
        GUI.SetText(Lab_WelfareNameD , ItemName)   
    elseif id == "List_GloryVIPMenu" or id == "List_GloryDescMenu" then
        self._CPageGloryInfo:OnInitGloryInfo(id, item, index + 1)
    elseif id == "List_SpecialSign" then
        self._CPageSpecialSign:OnInitSpecialSignInfo(item, index + 1)
    elseif id == "List_OnlineReward" then
        self._CPageOnlineReward:OnInitOnlineRewardInfo(item, index + 1)
    elseif id == "List_Festival" then
        self._CPageExchange:OnInitFestivalInfo(item, index + 1)
    end


    if id=="List_Sign" then

        local Img_ItemBg = GUITools.GetChild(item , 0)
        local Lab_DayNum = GUITools.GetChild(item , 1)
        local Img_Icon = GUITools.GetChild(item , 2)    --Icon
        local Img_Done = GUITools.GetChild(item , 8)    --已签
        local Img_Retroactive = GUITools.GetChild(item , 3)  -- 补签
        local Img_Get = GUITools.GetChild(item , 9)    --可签
        local Lab_ItemNum = GUITools.GetChild(item , 4)    --物品数量
        local Img_Glory = GUITools.GetChild(item , 5)    --爵位翻倍背景
        local Lab_Glory = GUITools.GetChild(item , 6)    --爵位翻倍
        local CanvasGroup = GUITools.GetChild(item ,11)    --已签天图标alpha值修改
        local img_quality_bg = GUITools.GetChild(item, 12)
        local img_quality = GUITools.GetChild(item, 13)

        local days = index+1
        local rewardID = self._SignDays[days]
        local reward_template = GUITools.GetRewardList(rewardID, true)
        Img_Glory:SetActive(false)
        Img_Get:SetActive(true)
        -- Img_ItemBg:SetActive(true)
        local alpha = 1 -- 已经签到时透明度需要变10%
        
        GUI.SetText(Lab_DayNum , tostring(days))
        
        GUITools.SetGroupImg(Img_ItemBg, 0)
        if reward_template ~= nil then 
            local InitQuality = nil
            if not reward_template[1].IsTokenMoney then
                local items = CElementData.GetTemplate("Item", reward_template[1].Data.Id)
                GUITools.SetItemIcon(Img_Icon, items.IconAtlasPath)
                local itemTemplate = CElementData.GetItemTemplate(reward_template[1].Data.Id)
                --GUI.SetText(Lab_ItemNum , tostring(reward_template[1].Data.Count))   
                InitQuality = itemTemplate.InitQuality
            else
                GUITools.SetTokenMoneyIcon(Img_Icon,reward_template[1].Data.Id)
                --GUI.SetText(Lab_ItemNum , tostring(reward_template[1].Data.Count))
                itemTemplate = CElementData.GetMoneyTemplate(reward_template[1].Data.Id)
                InitQuality = itemTemplate.Quality
            end 
	        if InitQuality == nil then return end
            if not IsNil(img_quality_bg) then
                GUITools.SetGroupImg(img_quality_bg, InitQuality)
            end
            
            if not IsNil(img_quality) then
                GUITools.SetGroupImg(img_quality, InitQuality)
            end
            GUI.SetText(Lab_ItemNum , GUITools.FormatNumber(reward_template[1].Data.Count))
        end

        Img_Done:SetActive(false)
        Img_Retroactive:SetActive(false)  
        if self._CurDay == days then            
            -- if #self._SignDaysInfo > 0 then
            if self._CurDay == self._CurSignedDays then
                alpha = 0.1
                Img_Done:SetActive(true)  
                GameUtil.StopUISfx(PATH.UIFX_WELFARE_Zhengfangxing, Img_ItemBg)
                GUITools.SetGroupImg(Img_ItemBg, 2)
            else
                GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Zhengfangxing, Img_ItemBg, Img_ItemBg, -1)

                GUITools.SetGroupImg(Img_ItemBg, 1)
                Img_Done:SetActive(false)
                alpha = 1
            end
            GUI.SetText(Lab_DayNum , "<color=#FE8F0C>"..days..StringTable.Get(19448).."</color>")
        elseif self._CurDay > days then
            alpha = 0.1
            Img_Done:SetActive(true)  
            GameUtil.StopUISfx(PATH.UIFX_WELFARE_Zhengfangxing, Img_ItemBg)
            GUITools.SetGroupImg(Img_ItemBg, 2)
        elseif self._CurDay < days then
            -- GameUtil.MakeImageGray(Img_Icon, false)   
            GameUtil.StopUISfx(PATH.UIFX_WELFARE_Zhengfangxing, Img_ItemBg)
        end
        GameUtil.SetCanvasGroupAlpha(CanvasGroup, alpha)
    end

end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_MenuType' then
        self._CurFrameType = self._WelfareType[index + 1]
        local Img_SelectType = GUITools.GetChild(item , 1)
        self:OnWelfareFrameInfo(self._CurFrameType)
        self._List_MenuType:SetSelection(index)

        local Img_RedPoint = GUITools.GetChild(item , 3)
        if self._WelfareType[index + 1] == EnumDef.WelfareType._GloryVIP then
            game._CWelfareMan._IsOpenGloryRedPoint = false
            Img_RedPoint:SetActive(false)
        end

    -- elseif id == "List_GloryVIPMenu" or id == "List_GloryDescMenu" then
    --     self._CPageGloryInfo:OnSelectGlory(id, item, index + 1)
    elseif id == "List_SpecialSign" then
        self._CPageSpecialSign:OnSelectSpecialSign(item, index + 1)
    elseif id == "List_OnlineReward" then
        self._CPageOnlineReward:OnSelectOnlineReward(item, index + 1)
    end

    if id == "List_Sign" then
        self:OnSelectSignDay(item, index+1)
    end
end


def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    warn("uuuuuuuuuuuuuuuuuu=====>>>", id_btn)
    if id_btn == "Btn_Exchange" then
        self._CPageExchange:OnSelectFestivalInfoButton(index + 1) 
    elseif string.find(id_btn, "MaterialIcon") or string.find(id_btn, "ItemIconNewReward") then
        self._CPageExchange:OnSelectMaterial(button_obj, id_btn, index + 1) 
    end
end

-- 打开对应页签
def.method("number").OpenPanelToggle = function(self,toggleType)
    if toggleType == ToggleType.WelfareType then 
        self._CurToggle = ToggleType.WelfareType
        --self._SignInfo = game._CWelfareMan:GetAllSignInfo()  
        scriptId = self._SignInfo._ScriptID        

        game._CWelfareMan:OnGetWelfareData()
        self:RefrashWelfare(self._CurFrameType)
    end
end

def.method().RefrashWelfareType = function(self) 
    self._SignDays = game._CWelfareMan:GetAllSignDays()
    self._SignInfo = game._CWelfareMan:GetAllSignInfo()
    self._CurDay = game._CWelfareMan:GetCurrentDay() 
    self._List_MenuType:SetItemCount(#self._WelfareType) 
    self._List_Sign:GetComponent(ClassType.GNewList):SetItemCount(game._CWelfareMan:GetCurrentTotalDay())

    local SelectionIndex = 0
    for i,v in pairs(self._WelfareType) do
        if v == self._CurFrameType then
            SelectionIndex = i
        end
    end
    
    self._List_MenuType:SetSelection(SelectionIndex - 1)
    --game._CGuideMan:AnimationEndCallBack(self)
end

-------------------------------------------签到Start-------------------------------------
def.method("number").RefrashWelfare = function(self, RefrashType)    
    if self._CurFrameType == RefrashType then
        self._Frame_ActivityClose:SetActive(false)
        self._SignDays = game._CWelfareMan:GetAllSignDays()
        self._SignInfo = game._CWelfareMan:GetAllSignInfo()
        self._CurDay = game._CWelfareMan:GetCurrentDay()  
        self._CurSignedDays = game._CWelfareMan:GetCurrentSignedDays()
        self._List_Sign:GetComponent(ClassType.GNewList):SetItemCount(game._CWelfareMan:GetCurrentTotalDay())
        
        if game._CWelfareMan:GetCurrentDay() ~= nil and game._CWelfareMan:GetCurrentDay() > 0 then
            self._CurDay = game._CWelfareMan:GetCurrentDay()
        else
            game._GUIMan:CloseByScript(self)
            return
        end
        self:OnWelfareFrameInfo(self._CurFrameType)
        
        if self._CurFrameType == EnumDef.WelfareType._SpecialSign and self:IsShow() and not game._CWelfareMan:GetSpecialSignIsOpen() then
            self._Frame_ActivityClose:SetActive(true)
            return
        end 
        self:RefrashWelfareType()
    end
end

def.method("number").OnWelfareFrameInfo = function(self, CurWelfareFrame)
    if CurWelfareFrame == EnumDef.WelfareType._Sign then
        self._Frame_Sign:SetActive(true)  
        self._CPageGloryInfo:Hide() 
        self._CPageSpecialSign:Hide()   
        self._CPageOnlineReward:Hide()   
        self._CPageExchange:Hide()
        self._SignDaysInfo = {}  
        self._RewardDaysInfo = {}          
        -- string.gsub(self._SignInfo._Signed, '[^*]+', function(w) table.insert(self._SignDaysInfo, w) end )
        -- string.gsub(self._SignInfo._IsTotleReward, '[^*]+', function(w) table.insert(self._RewardDaysInfo, w) end )
        local Lab_SignActivityTime = self:GetUIObject("Lab_SignActivityTime")
        if Lab_SignActivityTime ~= nil then
            GUI.SetText(Lab_SignActivityTime , StringTable.Get(34307))
        end
        local Lab_SignActivityDesc = self:GetUIObject("Lab_SignActivityDesc")
        if Lab_SignActivityDesc ~= nil then
            GUI.SetText(Lab_SignActivityTime , StringTable.Get(34308))
        end
        if self._SignInfo._Data.DoubleSigns ~= nil and #self._SignInfo._Data.DoubleSigns > 0 then
            for i,v in pairs(self._SignInfo._Data.DoubleSigns) do
                if v.VipLevel ~= nil then
                    local DoubleSigndays = {}
                    string.gsub(v.DoubleDay, '[^*]+', function(w) table.insert(DoubleSigndays, w) end )
                    self._DoubleSignDays[#self._DoubleSignDays + 1] = 
                    {
                        DoubleVIPLevel = v.VipLevel,
                        DoubleDays = DoubleSigndays,
                    }
                end
            end
        end            
    elseif CurWelfareFrame == EnumDef.WelfareType._GloryVIP then
        self._Frame_Sign:SetActive(false)        
        self._CPageGloryInfo:Show()
        self._CPageSpecialSign:Hide()
        self._CPageOnlineReward:Hide()
        self._CPageExchange:Hide()
    elseif CurWelfareFrame == EnumDef.WelfareType._SpecialSign then
        self._Frame_Sign:SetActive(false)        
        self._CPageGloryInfo:Hide()   
        self._CPageSpecialSign:Show()
        self._CPageOnlineReward:Hide()
        self._CPageExchange:Hide()
    elseif CurWelfareFrame == EnumDef.WelfareType._OnLineReward then
        self._Frame_Sign:SetActive(false)        
        self._CPageGloryInfo:Hide()   
        self._CPageSpecialSign:Hide()
        self._CPageOnlineReward:Show()
        self._CPageExchange:Hide()
    elseif CurWelfareFrame == EnumDef.WelfareType._Festival then
        self._Frame_Sign:SetActive(false)        
        self._CPageGloryInfo:Hide()   
        self._CPageSpecialSign:Hide()
        self._CPageOnlineReward:Hide()
        self._CPageExchange:Show()

    else
        warn("Waiting for development!!!", CurWelfareFrame, self._WelfareType[CurWelfareFrame])
    end
end

def.method("number", "=>", "boolean", "string").GetDoubleSignByDay = function(self, day)
    local DoubleSignInfo = ""
    -- 不需要判断当前是否有爵位。     lidaming  2018/10/31 
    -- local GolryLevel = game._HostPlayer:GetGloryLevel()

    if self._DoubleSignDays ~= nil and #self._DoubleSignDays > 0 then
        for i,v in pairs(self._DoubleSignDays) do            
            -- if GolryLevel >= v.DoubleVIPLevel then 
                for _,doubleDay in pairs(v.DoubleDays) do
                    if tonumber(doubleDay) == day then
                        -- warn("game._HostPlayer:GetGloryLevel() ==", game._HostPlayer:GetGloryLevel(), v.DoubleVIPLevel)
                        local gloryName = game._CWelfareMan:GetDataByGloryLevel(v.DoubleVIPLevel).Name
                        return true, gloryName
                    end
                end
            -- end
        end
    end
    return false, ""
end

-- def.method('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)

-- end

def.method("userdata", "number").OnSelectSignDay = function(self, item, index)

    local days = index
    eventType = -1
    -- warn("self._CurDay == ", self._CurDay , "days == ", days)       
    -- 判断当前天是否可签，是否为补签
    if self._CurDay == days then

        if self._CurDay == self._CurSignedDays then
            local daysRewardId = self._SignDays[days]
            local reward_template = GUITools.GetRewardList(daysRewardId, true)
            if reward_template ~= nil then 
                if not reward_template[1].IsTokenMoney then
                -- if reward_template.ItemRelated.RewardItems[1] and reward_template.ItemRelated.RewardItems[1].Id > 0 then
                    local RewardId = reward_template[1].Data.Id
                    CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
                else
                    -- TODO("货币不是 Item了,统一UE时记得改！")
                    local panelData = {}
                    panelData = 
                    {
                        _MoneyID = reward_template[1].Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = item,   
                    }
                    CItemTipMan.ShowMoneyTips(panelData)
                end 
            end 
            return
        else
            eventType = EScriptEventType.Sign_sign
        end
    elseif self._CurDay < days then
        local daysRewardId = self._SignDays[days]
        local reward_template = GUITools.GetRewardList(daysRewardId, true)
        if reward_template ~= nil then 
            if not reward_template[1].IsTokenMoney then
                local RewardId = reward_template[1].Data.Id
                CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
            else
                -- TODO("货币不是 Item了,统一UE时记得改！")
                local panelData = {}
                panelData = 
                {
                    _MoneyID = reward_template[1].Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
            end 
        end
    else  
        if #self._SignDaysInfo > 0 then          
            local daysRewardId = self._SignDays[days]
            local reward_template = GUITools.GetRewardList(daysRewardId, true)
            if reward_template ~= nil then 
                if not reward_template[1].IsTokenMoney then
                    local RewardId = reward_template[1].Data.Id
                    CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
                else
                    -- TODO("货币不是 Item了,统一UE时记得改！")
                    local panelData = {}
                    panelData = 
                    {
                        _MoneyID = reward_template[1].Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = item,   
                    }
                    CItemTipMan.ShowMoneyTips(panelData)
                end 
            end
            return
        end 
    end    

    local useSignRemedy = tonumber(CElementData.GetSpecialIdTemplate(247).Value)
    local useMoneyType = tonumber(CElementData.GetSpecialIdTemplate(467).Value)

    if eventType == 0 then
        game._CWelfareMan:OnC2SScriptExec(scriptId, eventType, days)
        warn("scriptId:"..scriptId.."       eventType:"..eventType)          
    else
        warn("Can not sign in!!!")
    end
end

---------------------------------------签到end------------------------------------------

def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
    self._CPageGloryInfo:Hide() 
    self._CPageSpecialSign:Hide()   
    self._CPageOnlineReward:Hide()  
    self._PreviewRewardData = nil
    instance = nil
    self._CPageGloryInfo = nil
    self._CPageSpecialSign = nil
    self._SpecialSignInfo = {}
    self._Frame_ActivityClose = nil
    self._CPageOnlineReward = nil
    self._CPageExchange:Hide()
end

CPanelUIWelfare.Commit()
return CPanelUIWelfare