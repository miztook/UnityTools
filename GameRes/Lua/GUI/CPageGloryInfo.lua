-- 福利  --> 荣耀之路
-- 2018/5/22    lidaming

local Lplus = require "Lplus"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageGloryInfo = Lplus.Class("CPageGloryInfo")
local def = CPageGloryInfo.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Frame_GloryVIP = nil 
def.field('userdata')._List_GloryVIPMenu = nil
def.field('userdata')._List_GloryVIP = nil
def.field("userdata")._Lab_CurVIPLevel = nil        -- 当前VIP等级
def.field("userdata")._Lab_CurFightScore = nil      -- 当前战力/当前爵位所需最大战力
def.field('userdata')._List_GloryDescMenu = nil
def.field('userdata')._List_GloryDesc = nil
def.field("userdata")._Lab_UnlockReward = nil        -- 获得新称号
def.field("userdata")._Frame_BuyGift = nil 
def.field("userdata")._Btn_GloryGift = nil
def.field("userdata")._Lab_ProgressPercent = nil
def.field("userdata")._Frame_AreaVIP = nil

def.field("table")._GloryGiftInfo = BlankTable
def.field("table")._UnlockDatas = BlankTable    -- 荣耀等级解锁描述

def.field("number")._CurGlory = -1                   --当前爵位

def.field("string")._KeyCountGroup = "countgroup"			-- 描述特殊匹配字段

local romanNum_list = {"I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "Xv", "XVI", "XVII", "XVIII", "XIX", "XX"}
def.static("table", "userdata", "=>", CPageGloryInfo).new = function(parent, panel)
    local instance = CPageGloryInfo()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Frame_GloryVIP = self._Parent:GetUIObject("Frame_GloryVIP")
    self._List_GloryVIPMenu = self._Parent:GetUIObject('List_GloryVIPMenu'):GetComponent(ClassType.GNewList)
    self._List_GloryVIP = self._Parent:GetUIObject('List_GloryVIPMenu')
    self._Lab_CurVIPLevel = self._Parent:GetUIObject("Lab_CurVIPLevel")
    self._Lab_CurFightScore = self._Parent:GetUIObject("Lab_CurFightScore")
    self._List_GloryDescMenu = self._Parent:GetUIObject('List_GloryDescMenu'):GetComponent(ClassType.GNewList)
    self._List_GloryDesc = self._Parent:GetUIObject('List_GloryDescMenu')
    self._Lab_UnlockReward = self._Parent:GetUIObject("Lab_UnlockReward1")
    self._Frame_BuyGift = self._Parent:GetUIObject("Frame_BuyGift")
    self._Btn_GloryGift = self._Parent:GetUIObject("Btn_GloryGift")
    self._Lab_ProgressPercent = self._Parent:GetUIObject("Lab_ProgressPercent")
    self._Frame_AreaVIP = self._Parent:GetUIObject("Frame_AreaVIP"):GetComponent(ClassType.Scrollbar)
end

--------------------------------------------------------------------------------

def.method().Show = function(self)
    self._Panel:SetActive(true)
    self._GloryGiftInfo = {}    
    if self._CurGlory == -1 and game._CWelfareMan:GetGloryLevel() > 0 then
        self._CurGlory = game._CWelfareMan:GetGloryLevel()
    elseif self._CurGlory == -1 and game._CWelfareMan:GetGloryLevel() <= 0 then
        self._CurGlory = 1
    end
    self._GloryGiftInfo = game._CWelfareMan:GetGloryGifts()
    self._List_GloryVIPMenu:SetItemCount(#self._GloryGiftInfo)
    if self._CurGlory <= 1 then
        self._Parent:GetUIObject("Btn_GloryLeft"):SetActive(false)             
    else
        self._Parent:GetUIObject("Btn_GloryLeft"):SetActive(true) 
    end
    if self._CurGlory >= #self._GloryGiftInfo then             
        self._Parent:GetUIObject("Btn_GloryRight"):SetActive(false)
    else
        self._Parent:GetUIObject("Btn_GloryRight"):SetActive(true)
    end
    self._List_GloryVIPMenu:SetSelection(self._CurGlory - 1)  
    self._List_GloryVIPMenu:ScrollToStep(self._CurGlory - 1)    
    self:OnInitGloryDesc(self._CurGlory)    
    -- 更新进度条
    self:UpdateBarProgress(self._CurGlory)
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_VIPStore" then          
        TODO()
    elseif id == "Btn_FightScoreUp" then

        local panelData = 
        {
            PageType = CPanelRoleInfo.PageType.STRONG,
            IsByNpcOpenStorage = false,
        }
        game._GUIMan:Open("CPanelRoleInfo",panelData)
        -- game._GUIMan:Open("CPanelUIPlayerStrong",nil)
    elseif id == "Btn_GloryLeft" then
        self._Parent:GetUIObject("Btn_GloryRight"):SetActive(true)
        self._CurGlory = self._CurGlory - 1
        self._List_GloryVIPMenu:SetSelection(self._CurGlory - 1)
        self._List_GloryVIPMenu:ScrollToStep(self._CurGlory - 1)
        self:OnInitGloryDesc(self._CurGlory)
        if self._CurGlory <= 1 then
            self._Parent:GetUIObject("Btn_GloryLeft"):SetActive(false)             
            return 
        else
            self._Parent:GetUIObject("Btn_GloryLeft"):SetActive(true) 
        end
    elseif id == "Btn_GloryRight" then        
        self._Parent:GetUIObject("Btn_GloryLeft"):SetActive(true)
        self._CurGlory = self._CurGlory + 1
        self._List_GloryVIPMenu:SetSelection(self._CurGlory - 1)
        self._List_GloryVIPMenu:ScrollToStep(self._CurGlory - 1)
        self:OnInitGloryDesc(self._CurGlory)
        if self._CurGlory >= #self._GloryGiftInfo then             
            self._Parent:GetUIObject("Btn_GloryRight"):SetActive(false)
            return 
        else
            self._Parent:GetUIObject("Btn_GloryRight"):SetActive(true)
        end
    elseif id == "Btn_BuyGloryGift" then   
        local giftBuyInfo = game._CWelfareMan:GetGloryGiftBuyInfo(self._CurGlory)
        -- warn("lidaming ---->>> GloryGiftId ==", self._CurGlory, self._GloryGiftInfo[self._CurGlory].Gift1Id)
        if giftBuyInfo ~= nil then
            game._GUIMan:ShowTipText(StringTable.Get(19489), true)
        else
            local MoneyID = 3 -- 固定为红钻
            local NeedMoney = self._GloryGiftInfo[self._CurGlory].Gift1Price
            local GloryLevel = self._CurGlory
            local GloryGiftId = self._GloryGiftInfo[self._CurGlory].Gift1Id
            local callback = function(val)
                if val then
                    --购买对应荣耀战力礼包(荣耀等级，礼包ID)
                    game._CWelfareMan:OnC2SGloryBuyLevelGift(GloryLevel, GloryGiftId)
                end
            end
            local limit = {
                [EQuickBuyLimit.AdventureLevel] = GloryLevel,
            }
            MsgBox.ShowQuickBuyBox(MoneyID, NeedMoney, callback, limit)
        end
    elseif id == "Btn_GloryGift" then
        -- warn("lidaming ---->>> GloryGiftId ==", self._GloryGiftInfo[self._CurGlory].Gift1Id)
        local EItemType = require "PB.Template".Item.EItemType
        local itemTemp = CElementData.GetItemTemplate(self._GloryGiftInfo[self._CurGlory].Gift1Id)
        if itemTemp.ItemType == EItemType.TreasureBox then
            CItemTipMan.ShowItemTips(self._GloryGiftInfo[self._CurGlory].Gift1Id, 
                                TipsPopFrom.OTHER_PANEL, 
                                self._Btn_GloryGift, 
                                TipPosition.FIX_POSITION)
        else
            warn("Data Error：itemTemp.ItemType ~= EItemType.TreasureBox!!!!")
        end
    end
end

def.method("string", "userdata", "number").OnInitGloryInfo = function(self, id, item, index)
    if id == "List_GloryVIPMenu" then
        -- local Img_ItemBg = GUITools.GetChild(item , 0)
        -- local Img_SelectItem = GUITools.GetChild(item , 1)
        local Lab_GloryName = GUITools.GetChild(item , 0)
        local Lab_GloryDesc = GUITools.GetChild(item , 2)

        -- local UnlockDatas = {}      -- 荣耀等级解锁数据        
        GUI.SetText(Lab_GloryName, string.format(StringTable.Get(19474),self._GloryGiftInfo[index].Name))
        -- print_r(UnlockDatas)
        GUI.SetText(Lab_GloryDesc, string.format(StringTable.Get(19490), GUITools.FormatMoney(self._GloryGiftInfo[index].FightScore)))
        
    elseif id == "List_GloryDescMenu" then
        -- local Lab_Desc = self._List_GloryVIP:FindChild("item-"..(index - 1) .."/Img_UnlockReward"..i .."/Lab_UnlockReward"..i)
        local Lab_Desc = GUITools.GetChild(item , 0)
        local VIPAddCount = {}      -- 对应次数组中的VIP增量
        if self._UnlockDatas[index] == nil then return end
        if string.find(self._UnlockDatas[index], self._KeyCountGroup) then
            
            local delta = 1
            local start, stop = string.find(self._UnlockDatas[index], "<(%a+)(%d+)>")
            
            if start ~= nil and stop ~= nil then
                local keyWord = string.sub(self._UnlockDatas[index], start, stop)
                local key = string.sub(string.sub(keyWord, 2, string.len(keyWord) - delta), string.len(self._KeyCountGroup) + 1)
                local countGroup = CElementData.GetTemplate("CountGroup", tonumber(key))
                if countGroup == nil then warn("countGroup data is nil!!!") return end
                string.gsub(countGroup.VipInc, '[^*]+', function(w) table.insert(VIPAddCount, w) end )                
                if self._CurGlory < 1 then return end
                if VIPAddCount[self._CurGlory] == nil then return end
                -- string.gsub(self._UnlockDatas[index], "<", LinkBefore)
                
                self._UnlockDatas[index] = string.gsub(self._UnlockDatas[index],"<(%w+)>", ("<color=#ffffff> ".. VIPAddCount[self._CurGlory].. " </color>") )
            end
        end
        GUI.SetText(Lab_Desc , self._UnlockDatas[index])

    end
end
--[[
def.method("string", "userdata", "number").OnSelectGlory = function(self, id, item, index)
    self._CurGlory = index + 1
    if self._List_GloryVIPMenu ~= nil then
        self._List_GloryVIPMenu:SetSelection(index - 1)
        self:OnInitGloryDesc(self._CurGlory)
    end
end
]]
def.method("number").OnInitGloryDesc = function(self, index)     
    if self._GloryGiftInfo[index] == nil then return end  
    self._UnlockDatas = {}
    string.gsub(self._GloryGiftInfo[index].RightsDescription, '[^*]+', function(w) table.insert(self._UnlockDatas, w) end)
    -- warn("lidaming ---------------->",index , self._GloryGiftInfo[index].RightsDescription, #self._UnlockDatas)   -- countgroup
    self._List_GloryDescMenu:SetItemCount(#self._UnlockDatas)

    local Lab_GloryName = GUITools.GetChild(self._Frame_BuyGift , 1)
    local Lab_GloryDsec = GUITools.GetChild(self._Frame_BuyGift , 2)
    local Img_GiftBtnBg = GUITools.GetChild(self._Frame_BuyGift , 4)
    local Img_MoneyIcon = GUITools.GetChild(self._Frame_BuyGift , 5)
    local Lab_GiftBuyNeedMoney = GUITools.GetChild(self._Frame_BuyGift , 6)
    local Lab_GiftBuied = GUITools.GetChild(self._Frame_BuyGift , 7)
    local Btn_Gift = GUITools.GetChild(self._Frame_BuyGift , 3)

    GUI.SetText(Lab_GloryName, string.format(StringTable.Get(19487), self._GloryGiftInfo[index].Name))
    -- GUI.SetText(Lab_GloryDsec, string.format(StringTable.Get(19488), self._GloryGiftInfo[index].Name))
    Lab_GloryDsec:SetActive(false)
    GUI.SetText(self._Lab_UnlockReward, string.format(StringTable.Get(19486), ("<color=#ffffff>" .. self._GloryGiftInfo[index].Name .. "</color>")))

    -- 购买礼包需要货币显示颜色
    local MoneyID = 3 -- 固定为红钻
    local HaveMoney = game._HostPlayer:GetMoneyCountByType(MoneyID)
    local NeedMoney = self._GloryGiftInfo[index].Gift1Price
	if NeedMoney > HaveMoney then
    	local haven = "<color=red>"..NeedMoney.."</color>"
    	GUI.SetText(Lab_GiftBuyNeedMoney, GUITools.FormatNumber(haven))
    else 
        local haven = NeedMoney
    	GUI.SetText(Lab_GiftBuyNeedMoney, GUITools.FormatNumber(haven))
    end

    local giftBuyInfo = game._CWelfareMan:GetGloryGiftBuyInfo(index)
    if giftBuyInfo == nil then
        Lab_GiftBuied:SetActive(false)
        Btn_Gift:SetActive(true)
        GUITools.SetTokenMoneyIcon(Img_MoneyIcon, MoneyID)
        if game._CWelfareMan:GetGloryLevel() >= index then
            -- Lab_GloryDsec:SetActive(false)
            GUITools.SetBtnGray(Btn_Gift, false)
        else
            -- Lab_GloryDsec:SetActive(true)
            GUITools.SetBtnGray(Btn_Gift, true)
        end
    else
        Lab_GiftBuied:SetActive(true)
        Btn_Gift:SetActive(false)
        -- Lab_GloryDsec:SetActive(false)
    end

    self:UpdateBarProgress(self._CurGlory)
end

-- 更新战力进度条
def.method("number").UpdateBarProgress = function(self, curGlory)
    -- 当前战斗力
    local curFight =  game._HostPlayer:GetHostFightScore()
    local basicValue = 0
    local curGloryData = CElementData.GetTemplate("GloryLevel", curGlory)
    if curGloryData == nil then return end
    -- 推荐战力为下一爵位所需战力
    if (curGlory + 1) > #self._GloryGiftInfo then
        basicValue = curGloryData.FightScore
    else
        local GloryData = CElementData.GetTemplate("GloryLevel", (curGlory))
        if GloryData ~= nil and GloryData.Id ~= nil then
            basicValue = GloryData.FightScore        
        end
    end
	if not IsNil(self._Lab_CurFightScore) then
 		GUI.SetText(self._Lab_CurFightScore, GUITools.FormatMoney(curFight))   -- .."/"..basicValue
    end
    GUI.SetText(self._Lab_CurVIPLevel, curGloryData.GloryDescription)
    local rate = curFight / basicValue
    self._Frame_AreaVIP.size = rate
    local percent = nil
    if (rate * 100) > 100 then 
        percent = 100
    else
        percent = string.format("%.2f", rate * 100)
    end
    GUI.SetText(self._Lab_ProgressPercent, percent .. "%")
end

def.method().Hide = function(self)
    self._Panel:SetActive(false)

end

def.method().Destroy = function (self)
    self:Hide()

    self._Parent = nil
    self._Panel = nil
    -- 界面
    self._Frame_GloryVIP = nil 
    self._List_GloryVIPMenu = nil
    self._List_GloryVIP = nil
    self._Lab_CurVIPLevel = nil        -- 当前VIP等级
    self._Lab_CurFightScore = nil      -- 当前战力/当前爵位所需最大战力
    self._List_GloryDescMenu = nil
    self._List_GloryDesc = nil
    self._Lab_UnlockReward = nil        -- 获得新称号
    self._Frame_BuyGift = nil 
    self._Btn_GloryGift = nil
    self._Lab_ProgressPercent = nil
    self._Frame_AreaVIP = nil

    self._GloryGiftInfo = {}
    self._UnlockDatas = {}    -- 荣耀等级解锁描述

    self._CurGlory = -1                   --当前爵位

end
----------------------------------------------------------------------------------


CPageGloryInfo.Commit()
return CPageGloryInfo