-- 福利  --> 在线奖励
-- 2019/1/5    lidaming

local Lplus = require "Lplus"
local CPageOnlineReward = Lplus.Class("CPageOnlineReward")
local def = CPageOnlineReward.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata").Frame_ShowReward = nil 
def.field("userdata")._List_OnlineReward = nil 
def.field("userdata")._Lab_OnlineTime = nil 
def.field("userdata")._Img_OnlineRewardBg = nil 
def.field("userdata")._Btn_CheckOnlineReward = nil 

def.field("table")._OnlineRewardDataTable = BlankTable

def.field("number")._OnlineTime = 1                   --当前在线时间
def.field("number")._TimeId = 0                         

def.field("number")._CurSelectReward = 0                -- 当前选择在线奖励

def.static("table", "userdata", "=>", CPageOnlineReward).new = function(parent, panel)
    local instance = CPageOnlineReward()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    -- self._Frame_GloryVIP = self._Parent:GetUIObject("Frame_GloryVIP")
    self._List_OnlineReward = self._Parent:GetUIObject('List_OnlineReward'):GetComponent(ClassType.GNewList)
    self._Lab_OnlineTime = self._Parent:GetUIObject("Lab_OnlineTime")
    self._Img_OnlineRewardBg = self._Parent:GetUIObject("Img_OnlineRewardBg")
    self._Btn_CheckOnlineReward = self._Parent:GetUIObject("Btn_CheckOnlineReward")
end

--------------------------------------------------------------------------------

def.method().Show = function(self)
    self._Panel:SetActive(true)
    self._OnlineRewardDataTable = {}
    self._OnlineRewardDataTable = game._CWelfareMan:GetOnlineRewardDataTable()
    self._OnlineTime = game._CWelfareMan:GetOnlineTime()
    self._List_OnlineReward:SetItemCount(#self._OnlineRewardDataTable)
    if self._TimeId ~= 0 then
        self:RemoveTimer()
    end
    self:AddTimer()
    if game._CWelfareMan:IsShowOnlineRewardRedPoint() then
        GUITools.SetBtnGray(self._Btn_CheckOnlineReward, false)
    else
        GUITools.SetBtnGray(self._Btn_CheckOnlineReward, true)
    end
    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_SpecialSign_Changzhu, self._Img_OnlineRewardBg, self._Img_OnlineRewardBg, -1)
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_CheckOnlineReward" then          
        -- TODO()
        game._CWelfareMan:OnC2SOnlineRewardDrawReward(0)
    end
end

def.method("userdata", "number").OnInitOnlineRewardInfo = function(self, item, index)
    local Img_Get = GUITools.GetChild(item , 0)             -- 获得奖励
    local Lab_RewardTime = GUITools.GetChild(item , 1)      -- 获取奖励时间
    local Item = GUITools.GetChild(item , 5)                -- 奖励物品图标
    local Frame_ItemIcon = GUITools.GetChild(item , 6)
    local Img_Done = GUITools.GetChild(item , 11)           -- 已领取
    local Lab_RewardName = GUITools.GetChild(item , 14)
    local Img_BG = GUITools.GetChild(item , 4) 
    local Lab_ItemNum = GUITools.GetChild(item , 10) 

    local OnlineRewardInfo = self._OnlineRewardDataTable[index]
    if OnlineRewardInfo ~= nil then
        GUI.SetText(Lab_RewardTime, OnlineRewardInfo._Data.DescText) 
        if OnlineRewardInfo._IsDraw then
            Img_Done:SetActive(true)
            GameUtil.SetCanvasGroupAlpha(Img_BG, 0.5)
            Img_Get:SetActive(false)
            GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Get)
        else
            Img_Done:SetActive(false)
            GameUtil.SetCanvasGroupAlpha(Img_BG, 1)
            if OnlineRewardInfo._IsGet then
                Img_Get:SetActive(true)
                GameUtil.PlayUISfxClipped(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Get, Img_Get, self._Parent:GetUIObject('Frame_ShowReward'))
            else
                Img_Get:SetActive(false)
                GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecailSign_Get, Img_Get)
            end
        end

        local rewardsData = GUITools.GetRewardList(OnlineRewardInfo._Data.RewardId, true) 
        if rewardsData == nil then return end
        local reward = rewardsData[1]
        if reward ~= nil then
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(Item, reward.Data.Id, 0)
                local itemTemplate = CElementData.GetTemplate("Money", reward.Data.Id)
                local itemName = itemTemplate.TextDisplayName
                GUI.SetText(Lab_RewardName, itemName) 
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            else
                IconTools.InitItemIconNew(Item, reward.Data.Id)
                local itemTemplate = CElementData.GetItemTemplate(reward.Data.Id)
                local itemName = itemTemplate.TextDisplayName
                GUI.SetText(Lab_RewardName, itemName) 
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            end
        end  
    end

end

def.method("userdata", "number").OnSelectOnlineReward = function(self, item, index)    
    local OnlineRewardInfo = self._OnlineRewardDataTable[index]
    local rewardsData = GUITools.GetRewardList(OnlineRewardInfo._Data.RewardId, true) 
    self._CurSelectReward = index
    if OnlineRewardInfo ~= nil then
        if OnlineRewardInfo._IsDraw == false and OnlineRewardInfo._IsGet then
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_System_Bonus_Sign, 0)
            game._CWelfareMan:OnC2SOnlineRewardDrawReward(self._CurSelectReward)
        else
            local reward_template = GUITools.GetRewardList(OnlineRewardInfo._Data.RewardId, true)
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
        end      
    end    
end


def.method().AddTimer = function (self)
    local TimeZone = tonumber(os.date("%z", 0))/100
    self._TimeId = _G.AddGlobalTimer(1, false, function()
        self._OnlineTime = self._OnlineTime + 1 
        -- self:Show()     
        if self._Lab_OnlineTime ~= nil then
            GUI.SetText(self._Lab_OnlineTime, os.date("%H:%M:%S", (self._OnlineTime + (24 - TimeZone) * 3600)))
        end
    end)
end
def.method().RemoveTimer = function(self)
    if self._TimeId ~= 0 then
        _G.RemoveGlobalTimer(self._TimeId)
        self._TimeId = 0
    end
end

def.method().Hide = function(self)
    self._Panel:SetActive(false)
    GameUtil.StopUISfx(PATH.UIFX_WELFARE_SpecialSign_Changzhu, self._Img_OnlineRewardBg)
    self:RemoveTimer()
end

def.method().Destroy = function (self)
    self:Hide()

    self._Parent = nil
    self._Panel = nil
    -- 界面
    self.Frame_ShowReward = nil 
    self._List_OnlineReward = nil 
    self._Lab_OnlineTime = nil 
    self._Btn_CheckOnlineReward = nil 
    self._Img_OnlineRewardBg = nil
    self._OnlineRewardDataTable = BlankTable
    self._OnlineTime = 1
    self._TimeId = 0                         
    self._CurSelectReward = 0
end
----------------------------------------------------------------------------------


CPageOnlineReward.Commit()
return CPageOnlineReward