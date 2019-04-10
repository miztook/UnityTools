-- 福利  --> 特殊签到
-- 2018/09/10    lidaming

local Lplus = require "Lplus"
local CPageSpecialSign = Lplus.Class("CPageSpecialSign")
local def = CPageSpecialSign.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"
local EScriptEventType = require "PB.data".EScriptEventType

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Frame_SpecialSign = nil 
def.field('userdata')._List_SpecialSign = nil
def.field('userdata')._Lab_SpecialSignActivityTime = nil
def.field('userdata')._Lab_SpecialSignActivityDesc = nil
def.field('userdata')._Lab_SpecialSignDesc = nil
def.field('userdata')._Img_SpecialSignBg = nil
def.field('userdata')._Lab_TotalDayNum = nil
def.field('userdata')._Img_TotalItem = nil
def.field('userdata')._Lab_MaxNum = nil
def.field('userdata')._Img_MaxDone = nil
def.field('userdata')._Img_MaxSelect = nil
def.field('userdata')._Btn_TotalItem = nil

def.field("table")._SpecialSignInfo = BlankTable    -- 特殊签到详细信息
def.field("table")._SpecialSigned = BlankTable      -- 已签列表
def.field("table")._CanSpecialSign = BlankTable     -- 可签列表
def.field("table")._Rewards = BlankTable

def.static("table", "userdata", "=>", CPageSpecialSign).new = function(parent, panel)
    local instance = CPageSpecialSign()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Frame_SpecialSign = self._Parent:GetUIObject("Frame_SpecialSign")
    
    self._List_SpecialSign = self._Parent:GetUIObject('List_SpecialSign'):GetComponent(ClassType.GNewList)
    self._Lab_SpecialSignActivityTime = self._Parent:GetUIObject('Lab_SpecialSignActivityTime')
    self._Lab_SpecialSignActivityDesc = self._Parent:GetUIObject('Lab_SpecialSignActivityDesc')
    self._Lab_SpecialSignDesc = self._Parent:GetUIObject("Lab_SpecialSignDesc")
    self._Img_SpecialSignBg = self._Parent:GetUIObject("Img_SpecialSignBg")
    self._Lab_TotalDayNum = self._Parent:GetUIObject("Lab_TotalDayNum")
    self._Img_TotalItem = self._Parent:GetUIObject("Img_TotalItem")
    self._Lab_MaxNum = self._Parent:GetUIObject("Lab_MaxNum")
    self._Img_MaxDone = self._Parent:GetUIObject("Img_MaxDone")
    self._Img_MaxSelect = self._Parent:GetUIObject("Img_MaxSelect")
    self._Btn_TotalItem = self._Parent:GetUIObject("Btn_TotalItem")
end

--------------------------------------------------------------------------------

def.method().Show = function(self)
    self._Panel:SetActive(true)
    self._SpecialSignInfo = {}
    self._SpecialSignInfo = game._CWelfareMan:GetSpecialSignInfo()    
    local SpecialSignTemp = CElementData.GetTemplate("SpecialSign", self._SpecialSignInfo._Tid)

    self._Rewards = SpecialSignTemp.SpecialSignRewards
    
    self._SpecialSigned = {}  
    self._CanSpecialSign = {}  
    string.gsub(self._SpecialSignInfo._Signed, '[^*]+', function(w) table.insert(self._SpecialSigned, w) end )
    string.gsub(self._SpecialSignInfo._CanSign, '[^*]+', function(w) table.insert(self._CanSpecialSign, w) end )

    -- local ActivityOpenTime = StringTable.Get(19454) .. string.sub(self._SpecialSignInfo._OpenTime, 1, -6) .. "-" .. string.sub(self._SpecialSignInfo._CloseTime, 1, -6)
    local ActivityOpenTime = string.format(StringTable.Get(19454), os.date("%Y/%m/%d %H:%M", self._SpecialSignInfo._OpenTime) .. " - " .. os.date("%Y/%m/%d %H:%M", self._SpecialSignInfo._CloseTime))
    GUI.SetText(self._Lab_SpecialSignActivityTime, ActivityOpenTime)
    GUI.SetText(self._Lab_SpecialSignActivityDesc, SpecialSignTemp.Content)


    GUI.SetText(self._Lab_SpecialSignDesc, string.format(StringTable.Get(19482),tostring(#self._Rewards)))
    GUI.SetText(self._Lab_TotalDayNum, string.format(StringTable.Get(19484),tostring(#self._Rewards)))
    local rewardsData = GUITools.GetRewardList(self._Rewards[#self._Rewards].RewardId, true) 
    if rewardsData == nil then return end
    local reward = rewardsData[1]
    if reward ~= nil then
        if reward.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(self._Img_TotalItem, reward.Data.Id, 0)
        else
            IconTools.InitItemIconNew(self._Img_TotalItem, reward.Data.Id)
        end
        GUI.SetText(self._Lab_MaxNum, tostring(reward.Data.Count))
    end   
    if SpecialSignTemp.BackgroundImg ~= "" then  
        GUITools.SetSprite(self._Img_SpecialSignBg, SpecialSignTemp.BackgroundImg)
    end
    
    local IsMaxSigned = false
    local IsMaxCanSign = false
    if #self._SpecialSigned > 0 then        
        for i,v in pairs(self._SpecialSigned) do
            if tonumber(v) == #self._Rewards then 
                IsMaxSigned = true                
            end
        end
    end
    if #self._CanSpecialSign > 0 then
        for i,v in pairs(self._CanSpecialSign) do            
            if tonumber(v) == #self._Rewards then 
                IsMaxCanSign = true
            end
        end
    end
    -- warn("lidaming specialSign  _CanSpecialSign ==", IsMaxSigned, IsMaxCanSign)
    if IsMaxSigned then
        self._Img_MaxDone:SetActive(true)  
        self._Img_MaxSelect:SetActive(false)
        GameUtil.SetCanvasGroupAlpha(self._Btn_TotalItem, 0.5)
    elseif IsMaxCanSign then
        self._Img_MaxDone:SetActive(false)  
        self._Img_MaxSelect:SetActive(true)
        GameUtil.SetCanvasGroupAlpha(self._Btn_TotalItem, 1)
    else
        self._Img_MaxDone:SetActive(false)  
        self._Img_MaxSelect:SetActive(false)
        GameUtil.SetCanvasGroupAlpha(self._Btn_TotalItem, 1)
    end

    self._List_SpecialSign:SetItemCount(#self._Rewards - 1)
    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_SpecialSign_Changzhu, self._Img_SpecialSignBg, self._Img_SpecialSignBg, -1)    
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_TotalItem" then  
        local IsCanSign = false
        if #self._CanSpecialSign > 0 then
            for i,v in pairs(self._CanSpecialSign) do
                if tonumber(v) == #self._Rewards then                    
                    IsCanSign = true                    
                end
            end
        else
            IsCanSign = false            
        end  
        -- warn("Btn_Item eventType == ",eventType, IsCanSign)
        if IsCanSign then
            -- 发送领取奖励协议
            game._CWelfareMan:OnC2SScriptExec(self._SpecialSignInfo._ScriptID, EScriptEventType.SpecialSign_Sign, #self._Rewards)
        else
            local rewardsData = GUITools.GetRewardList(self._Rewards[#self._Rewards].RewardId, true)
            local reward = rewardsData[1] 
            if not reward.IsTokenMoney then
                CItemTipMan.ShowItemTips(reward.Data.Id, TipsPopFrom.OTHER_PANEL,self._Img_TotalItem,TipPosition.FIX_POSITION)
            else
                local panelData = 
                {
                    _MoneyID = reward.Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = self._Img_TotalItem ,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
            end
        end
        
    end
end

def.method("userdata", "number").OnInitSpecialSignInfo = function(self, item, index)
    -- warn("===OnInitSpecialSignInfo====>>>", index, #self._Rewards, #self._SpecialSigned, #self._CanSpecialSign)
    if index == #self._Rewards then return end
    local Img_Item = GUITools.GetChild(item , 0)
    local Img_Bg = GUITools.GetChild(item , 1)
    local Img_SelectItem = GUITools.GetChild(item , 7)
    local Lab_SpecialSignDay = GUITools.GetChild(item , 6)
    local Img_Done = GUITools.GetChild(item , 5)
    local Lab_ItemNum = GUITools.GetChild(item , 4)
    
    GUI.SetText(Lab_SpecialSignDay, string.format(StringTable.Get(19484),tostring(index)))

    local rewardsData = GUITools.GetRewardList(self._Rewards[index].RewardId, true) 
    if rewardsData == nil then return end
    local reward = rewardsData[1]
    if reward ~= nil then
        if reward.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(Img_Item, reward.Data.Id, 0)
        else
            IconTools.InitItemIconNew(Img_Item, reward.Data.Id)
        end
        GUI.SetText(Lab_ItemNum, tostring(reward.Data.Count))
    end     
    
    Img_Done:SetActive(false)  
    GameUtil.SetCanvasGroupAlpha(Img_Bg, 1)
    local IsSigned = false
    local IsCanSign = false
    if #self._SpecialSigned > 0 then        
        for i,v in pairs(self._SpecialSigned) do
            if tonumber(v) == index then 
                IsSigned = true                
            end
        end
    end

    if #self._CanSpecialSign > 0 then
        for i,v in pairs(self._CanSpecialSign) do            
            if tonumber(v) == index then 
                IsCanSign = true
            end
        end
    end
    -- warn("lidaming specialSign  _CanSpecialSign ==", IsSigned, IsCanSign)
    if IsSigned then
        Img_Done:SetActive(true)  
        GameUtil.SetCanvasGroupAlpha(Img_Bg, 0.5)
        Img_SelectItem:SetActive(false)
        GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Item)
    elseif IsCanSign then
        Img_Done:SetActive(false)  
        Img_SelectItem:SetActive(true)
        GameUtil.SetCanvasGroupAlpha(Img_Bg, 1)
        GameUtil.PlayUISfxClipped(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Item, Img_Item, item.parent.parent)
    else
        Img_Done:SetActive(false)  
        Img_SelectItem:SetActive(false)
        GameUtil.SetCanvasGroupAlpha(Img_Bg, 1)
        GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Item)
    end
end

def.method("userdata", "number").OnSelectSpecialSign = function(self, item, index)
    local IsSelectCanSign = false
    if #self._CanSpecialSign > 0 then
        for i,v in pairs(self._CanSpecialSign) do
            if tonumber(v) == index then 
                IsSelectCanSign = true                
            end
        end        
    else
        IsSelectCanSign = false        
    end   
    if IsSelectCanSign then
        -- 发送领取奖励协议
        game._CWelfareMan:OnC2SScriptExec(self._SpecialSignInfo._ScriptID, EScriptEventType.SpecialSign_Sign, index)
    else
        local rewardsData = GUITools.GetRewardList(self._Rewards[index].RewardId, true)
        local reward = rewardsData[1] 
        if not reward.IsTokenMoney then
            CItemTipMan.ShowItemTips(reward.Data.Id, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        else
            local panelData = 
            {
                _MoneyID = reward.Data.Id ,
                _TipPos = TipPosition.FIX_POSITION ,
                _TargetObj = item ,   
            }
            CItemTipMan.ShowMoneyTips(panelData)
        end
    end

end

def.method().Hide = function(self)
    self._Panel:SetActive(false)
    GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecialSign_Changzhu, self._Img_SpecialSignBg)
end

def.method().Destroy = function (self)
    self:Hide()
end
----------------------------------------------------------------------------------


CPageSpecialSign.Commit()
return CPageSpecialSign