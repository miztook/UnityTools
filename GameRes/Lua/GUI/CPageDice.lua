-- 福利  --> 骰子
-- 2019/6/27    lidaming

local Lplus = require "Lplus"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageDice = Lplus.Class("CPageDice")
local def = CPageDice.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"
local EDiceEventType = require "PB.Template".Dice.EDiceEventType
local EScriptEventType = require "PB.data".EScriptEventType

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Frame_Dice = nil 
def.field("userdata")._Frame_Dices = nil 
def.field("userdata")._Img_DiceBg = nil
def.field("userdata")._Lab_DiceActivityTime = nil        -- 活动时间
def.field("userdata")._Dice_Hook = nil
def.field("userdata")._Lab_DiceNeedNum = nil        -- 骰子数量

def.field("userdata")._Btn_DiceGoalReward1 = nil
def.field("userdata")._Btn_DiceGoalReward2 = nil
def.field("userdata")._DiceGoalCount1 = nil
def.field("userdata")._Img_DiceGoalRewardIcon1 = nil
def.field("userdata")._Img_DiceGoalReward1open = nil
def.field("userdata")._DiceGoalCount2 = nil
def.field("userdata")._Img_DiceGoalRewardIcon2 = nil
def.field("userdata")._Img_DiceGoalReward2open = nil
def.field("userdata")._Btn_RollDice = nil


def.field("table")._Table_DiceItemObj = BlankTable

def.field("table")._DiceInfo = BlankTable
def.field("table")._DiceItemInfos = BlankTable
def.field("number")._OldDicePos = 0                -- 前一次选中位置
def.field("number")._DicePos = 0                -- 当前位置
def.field("number")._DiceTotalCount = 0                -- 累计投掷次数
def.field("string")._DiceTotalReward = ""                -- 宝箱奖励是否领取

def.field("number")._MaxDayDiceItemNum = 24                 -- 骰子对应item最大数量
def.field("number")._TimeId = 0 

def.field("boolean")._IsRollDice = true                    -- 是否可以投掷骰子

def.static("table", "userdata", "=>", CPageDice).new = function(parent, panel)
    local instance = CPageDice()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Frame_Dice = self._Parent:GetUIObject("Frame_Dice")
    self._Lab_DiceActivityTime = self._Parent:GetUIObject("Lab_DiceActivityTime")

    self._Img_DiceBg = self._Frame_Dice:FindChild("Img_DiceBg")

    self._Btn_DiceGoalReward1 = self._Parent:GetUIObject("Btn_DiceGoalReward1")
    self._Btn_DiceGoalReward2 = self._Parent:GetUIObject("Btn_DiceGoalReward2")

    self._DiceGoalCount1 = self._Btn_DiceGoalReward1:FindChild("Lab_DiceGoalCount1")
    self._Img_DiceGoalRewardIcon1 = self._Btn_DiceGoalReward1:FindChild("Img_DiceGoalReward1")
    self._Img_DiceGoalReward1open = self._Btn_DiceGoalReward1:FindChild("Img_DiceGoalReward1open")

    self._DiceGoalCount2 = self._Btn_DiceGoalReward2:FindChild("Lab_DiceGoalCount2")
    self._Img_DiceGoalRewardIcon2 = self._Btn_DiceGoalReward2:FindChild("Img_DiceGoalRewardBg2")
    self._Img_DiceGoalReward2open = self._Btn_DiceGoalReward2:FindChild("Img_DiceGoalRewardBg2open")

    self._Lab_DiceNeedNum = self._Parent:GetUIObject("Lab_DiceNeedNum")
    self._Btn_RollDice = self._Parent:GetUIObject("Btn_RollDice")
    self._Dice_Hook = self._Parent:GetUIObject("Dice_Hook")
    if self._Dice_Hook ~= nil then
        GameUtil.SetFxSorting(self._Dice_Hook, self._Parent:GetSortingLayer(), self._Parent:GetSortingOrder(), true)
        self._Dice_Hook:SetActive(false)
    end
    self._Frame_Dices = self._Parent:GetUIObject("Frame_Dices")
    for i = 1, self._MaxDayDiceItemNum do
        table.insert(self._Table_DiceItemObj, self._Frame_Dices:FindChild("Dice_".. i))
    end
    self._OldDicePos = game._CWelfareMan:GetDicePos()
end

--------------------------------------------------------------------------------

def.method().Show = function(self)
    self._Panel:SetActive(true)
    self._DiceInfo = {}    
    self._DiceItemInfos = {}

    self._DiceInfo = game._CWelfareMan:GetDiceInfos()
    self._DiceItemInfos = game._CWelfareMan:GetDiceItemInfoList()
    self._DicePos = game._CWelfareMan:GetDicePos()
    self._DiceTotalCount = game._CWelfareMan:GetDiceTotleCounts()
    self._DiceTotalReward = game._CWelfareMan:GetDiceTotleReward()

    -- warn("========11111111111111111111111========>>", self._DiceInfo.TotleCounts, self._DiceTotalCount, self._DiceTotalReward, #self._DiceItemInfos, self._DicePos)
    if self._Lab_DiceActivityTime ~= nil then
        GUI.SetText(self._Lab_DiceActivityTime , tostring(self._DiceInfo.TimeContent))
    end

    if self._Img_DiceBg ~= nil and self._DiceInfo.BackGroundPath ~= "" then
        GUITools.SetSprite(self._Img_DiceBg, self._DiceInfo.BackGroundPath)
    end

    self:UpdateChestState()
    self:UpdateDice()
end

def.method("string").OnClick = function(self, id)
    if string.find(id, "Btn_DiceGoalReward") then
        local index = tonumber(string.sub(id, string.len("Btn_DiceGoalReward")+1,-1))  
        local RewardID = {}
        local TotalNum = {}
        local TotalNumGet = {}
        if self._DiceInfo.TotleRewardIds == nil then return end
        if self._DiceInfo.TotleCounts == nil then return end
        if self._DiceTotalReward == nil then return end
        string.gsub(self._DiceInfo.TotleRewardIds, '[^*]+', function(w) table.insert(RewardID, w) end )
        string.gsub(self._DiceInfo.TotleCounts, '[^*]+', function(w) table.insert(TotalNum, w) end )
        string.gsub(self._DiceTotalReward, '[^*]+', function(w) table.insert(TotalNumGet, w) end )
        if TotalNum[index] ~= nil and self._DiceTotalCount >= tonumber(TotalNum[index]) and TotalNum[index] ~= TotalNumGet[index] then
            game._CWelfareMan:OnC2SScriptExec(3, EScriptEventType.Dice_TotleReward, tonumber(TotalNum[index]))
        else
            local reward_template = GUITools.GetRewardList(tonumber(RewardID[index]), true)
            if reward_template ~= nil and #reward_template > 0 then            
                if not reward_template[1].IsTokenMoney then
                    local RewardId = reward_template[1].Data.Id                
                    CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL ,self._Table_DiceItemObj[index],TipPosition.FIX_POSITION) 
                else
                    -- TODO("货币不是 Item了,统一UE时记得改！")
                    local panelData = {}
                    panelData = 
                    {
                        _MoneyID = reward_template[1].Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = self._Table_DiceItemObj[index],   
                    }
                    CItemTipMan.ShowMoneyTips(panelData)
                end 
            end
            return
        end

    elseif id == "Btn_RollDice" then
        if self._IsRollDice then      
            game._CWelfareMan:OnC2SScriptExec(game._CWelfareMan._CurSpriteID, EScriptEventType.Dice_Roll, 0)
            self._IsRollDice = false
        end
    elseif id == "Btn_DiceDesc" then
        game._GUIMan:Close("CPanelUICommonNotice")        
        local data = 
        {
            Title = StringTable.Get(34350),
            Name = StringTable.Get(34200),
            Desc = StringTable.Get(34351),
        }
        game._GUIMan:Open("CPanelUICommonNotice", data)
    elseif id == "Btn_AddDice" then
        local SpecialValue = string.split(CElementData.GetSpecialIdTemplate(685).Value, "*")  -- 骰子消耗特殊ID：685
        local CostMoneyId = nil
        local CostMoneyNum = nil
        if SpecialValue ~= nil and #SpecialValue > 0 then
            CostMoneyId = tonumber(SpecialValue[1])
            CostMoneyNum = tonumber(SpecialValue[2])
        end
    
        local callback = function(buyNum)
            local callback1 = function(val)
                if val then
                    -- self:OnC2SGuildShopBuyItem(self._Fund_Tid, shopItem.ItemId, buyNum)
                    game._CWelfareMan:OnC2SScriptExec(3, EScriptEventType.Dice_Buy, buyNum)
                end
            end
            MsgBox.ShowQuickBuyBox(CostMoneyId, CostMoneyNum * buyNum, callback1)
		end
        BuyOrSellItemMan.ShowCommonOperate(TradingType.BUY,StringTable.Get(21305), StringTable.Get(34353), 1, -1, CostMoneyNum, CostMoneyId, nil, callback)
    elseif string.find(id, "Dice_") then        
        local index = tonumber(string.sub(id, string.len("Dice_")+1,-1)) 
        if self._DiceItemInfos == nil then return end
        if self._DiceItemInfos[index].EventType == EDiceEventType.DiceReward then
            local reward_template = GUITools.GetRewardList(tonumber(self._DiceItemInfos[index].EventParm), true)
            if reward_template ~= nil and #reward_template > 0 then            
                if not reward_template[1].IsTokenMoney then
                    local RewardId = reward_template[1].Data.Id                
                    CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL ,self._Frame_Dices:FindChild("Dice_"..index),TipPosition.FIX_POSITION) 
                else
                    -- TODO("货币不是 Item了,统一UE时记得改！")
                    local panelData = {}
                    panelData = 
                    {
                        _MoneyID = reward_template[1].Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = self._Frame_Dices:FindChild("Dice_"..index),   
                    }
                    CItemTipMan.ShowMoneyTips(panelData)
                end 
            end
            return
        end
    end
end

-- 更新骰子奖励物品列表
def.method().UpdateDiceItemList = function(self)
    if self._DiceItemInfos == nil then return end
    if self._DiceInfo.CostItemTid ~= nil then
        local packageNum = game._HostPlayer._Package._NormalPack:GetItemCount(self._DiceInfo.CostItemTid)
        if packageNum > 0 then
            GUITools.SetBtnGray(self._Btn_RollDice, false)  
            packageNum = RichTextTools.GetAvailableColorText(tostring(packageNum))            
        else
            GUITools.SetBtnGray(self._Btn_RollDice, true)
            packageNum = RichTextTools.GetUnavailableColorText(tostring(packageNum))
        end

        if self._Lab_DiceNeedNum ~= nil then
            GUI.SetText(self._Lab_DiceNeedNum , tostring(packageNum).."/1")
        end
    end 

    for i, v in ipairs(self._DiceItemInfos) do
        local item = self._Table_DiceItemObj[i]
        local Img_Quality = GUITools.GetChild(item , 1)
        local Img_Icon = GUITools.GetChild(item , 2)
        local Lab_ItemNum = GUITools.GetChild(item , 3)
        local Img_Select = GUITools.GetChild(item , 4)
        local Img_Event = GUITools.GetChild(item , 5)
        local Lab_Start = GUITools.GetChild(item , 6)
        local Lab_NumAdd = GUITools.GetChild(item , 7)
        local Lab_NumSub = GUITools.GetChild(item , 8)
        local Lab_Reatart = GUITools.GetChild(item , 9)
        Img_Quality:SetActive(false)
        Img_Icon:SetActive(false)
        Lab_ItemNum:SetActive(false)
        self._OldDicePos = self._DicePos
        local do_tween_player = self._Frame_Dices:GetComponent(ClassType.DOTweenPlayer)
        if self._DicePos == i then
            Img_Select:SetActive(true)
            GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop, Img_Select, Img_Select, -1)
            GameUtil.StopUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select)
            GameUtil.StopUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select)            
            if do_tween_player ~= nil then
                do_tween_player:Restart(tostring(i))
            end
        else
            local SfxState = GameUtil.IsPlayingUISfx(PATH.UIFX_WELFARE_Dice_Loop, Img_Select, Img_Select)
            if SfxState then
                GameUtil.StopUISfx(PATH.UIFX_WELFARE_Dice_Loop, Img_Select)
                if do_tween_player ~= nil then
                    do_tween_player:Stop(tostring(i))
                    do_tween_player:GoToStartPos(tostring(i))
                end
            end            
            Img_Select:SetActive(false)            
        end

        if v.EventType == EDiceEventType.DiceNone then
            Img_Event:SetActive(true)
            Lab_Start:SetActive(true)
            Lab_NumAdd:SetActive(false)
            Lab_NumSub:SetActive(false)
            Lab_Reatart:SetActive(false)
            GUITools.SetGroupImg(Img_Event, 4)
        elseif v.EventType == EDiceEventType.DiceReward then
            Img_Event:SetActive(false)
            Img_Quality:SetActive(true)
            Img_Icon:SetActive(true)
            Lab_ItemNum:SetActive(true)
            
            
            local reward_template = GUITools.GetRewardList(v.EventParm, true)
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
                    local itemTemplate = CElementData.GetMoneyTemplate(reward_template[1].Data.Id)
                    InitQuality = itemTemplate.Quality
                end 
                if InitQuality == nil then return end
                if not IsNil(Img_Quality) then
                    GUITools.SetGroupImg(Img_Quality, InitQuality)
                end

                GUI.SetText(Lab_ItemNum , GUITools.FormatNumber(reward_template[1].Data.Count))
            end

        elseif v.EventType == EDiceEventType.DiceForward then
            Img_Event:SetActive(true)
            Lab_Start:SetActive(false)
            Lab_NumAdd:SetActive(true)
            Lab_NumSub:SetActive(false)
            Lab_Reatart:SetActive(false)
            GUITools.SetGroupImg(Img_Event, 3)
        elseif v.EventType == EDiceEventType.DiceBackOff then
            Img_Event:SetActive(true)
            Lab_Start:SetActive(false)
            Lab_NumAdd:SetActive(false)
            Lab_NumSub:SetActive(true)
            Lab_Reatart:SetActive(false)
            GUITools.SetGroupImg(Img_Event, 2)
        elseif v.EventType == EDiceEventType.DiceMoveTo then
            Img_Event:SetActive(true)
            Lab_Start:SetActive(false)
            Lab_NumAdd:SetActive(false)
            Lab_NumSub:SetActive(false)
            Lab_Reatart:SetActive(true)
            GUITools.SetGroupImg(Img_Event, 1)
        end
    end
end

--  更新宝箱相关
def.method().UpdateChestState = function(self)
    local RewardID = {}
    local TotalNum = {}
    local TotalNumGet = {}
    if self._DiceInfo.TotleRewardIds == nil then return end
    if self._DiceInfo.TotleCounts == nil then return end
    if self._DiceTotalReward == nil then return end
    -- warn("self._DiceInfo.TotleRewardIds ==>>", self._DiceInfo.TotleRewardIds ,"self._DiceInfo.TotleCounts ==>", self._DiceInfo.TotleCounts, "self._DiceTotalReward", self._DiceTotalReward)
    string.gsub(self._DiceInfo.TotleRewardIds, '[^*]+', function(w) table.insert(RewardID, w) end )
    string.gsub(self._DiceInfo.TotleCounts, '[^*]+', function(w) table.insert(TotalNum, w) end )
    string.gsub(self._DiceTotalReward, '[^*]+', function(w) table.insert(TotalNumGet, w) end )
    if self._DiceGoalCount1 ~= nil then
        if self._DiceTotalCount >= tonumber(TotalNum[1]) then
            GUI.SetText(self._DiceGoalCount1, TotalNum[1] .. "/" .. TotalNum[1])      
        else
            GUI.SetText(self._DiceGoalCount1, self._DiceTotalCount .. "/" .. TotalNum[1])
        end

        if TotalNumGet[1] == TotalNum[1] then       -- 已经领取宝箱
            self._Img_DiceGoalRewardIcon1:SetActive(false)
            self._Img_DiceGoalReward1open:SetActive(true)
            GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon1)
        else
            self._Img_DiceGoalRewardIcon1:SetActive(true)
            self._Img_DiceGoalReward1open:SetActive(false)
            if self._DiceTotalCount >= tonumber(TotalNum[1]) then
                GameUtil.PlayUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon1, self._Img_DiceGoalRewardIcon1, -1)
            else
                GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon1)
            end
        end
    end

    if self._DiceGoalCount2 ~= nil then    
        if self._DiceTotalCount >= tonumber(TotalNum[2]) then
            GUI.SetText(self._DiceGoalCount2, TotalNum[2] .. "/" .. TotalNum[2])
        else
            GUI.SetText(self._DiceGoalCount2, self._DiceTotalCount .. "/" .. TotalNum[2])
        end

        if TotalNumGet[2] == TotalNum[2] then       -- 已经领取宝箱
            self._Img_DiceGoalRewardIcon2:SetActive(false)
            self._Img_DiceGoalReward2open:SetActive(true)
            GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon2)
        else
            self._Img_DiceGoalRewardIcon2:SetActive(true)
            self._Img_DiceGoalReward2open:SetActive(false)
            if self._DiceTotalCount >= tonumber(TotalNum[2]) then
                GameUtil.PlayUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon2, self._Img_DiceGoalRewardIcon2, -1)
            else
                GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, self._Img_DiceGoalRewardIcon2)
            end
        end
    end
end

local DiceNum = {
    [1] = Quaternion.Euler(0, 90, 0),
    [2] = Quaternion.Euler(270, 0, 0),
    [3] = Quaternion.Euler(0, 0, 0),
    [4] = Quaternion.Euler(90, 0, 0),
    [5] = Quaternion.Euler(0, 270, 0),
    [6] = Quaternion.Euler(180, 0, 0),
}


def.method().AddTimer = function (self)
    local DiceTime = 0
    local RollDiceNum = game._CWelfareMan._CurrentRollDiceNum           -- 投掷的骰子数
    local RollDicePos = self._OldDicePos + game._CWelfareMan._CurrentRollDiceNum           -- 投掷骰子后的位置
    if RollDicePos >= 25 then
        RollDicePos = RollDicePos - 24
    end
    local UpdateTime = RollDiceNum    
    local DiceItemInfo = self._DiceItemInfos[RollDicePos]               -- 投掷骰子后的位置对应的数据
    local CurDiceItemInfo = self._DiceItemInfos[self._DicePos]
    local RollDicePosTimer = 0
    local IsRollDicePos = false         -- 是否已经到过骰子的位置
    local DiceDotweenPlayer = self._Frame_Dices:GetComponent(ClassType.DOTweenPlayer)
    self._TimeId = _G.AddGlobalTimer(0.2, false, function()
        DiceTime = DiceTime + 1  
        if DiceTime > 10 and RollDicePosTimer == 0 then  

            local item = self._Table_DiceItemObj[self._OldDicePos]
            local Img_Select = GUITools.GetChild(item , 4)
            local SfxState = GameUtil.IsPlayingUISfx(PATH.UIFX_WELFARE_Dice_Loop, Img_Select, Img_Select) 
            if SfxState then
                GameUtil.StopUISfx(PATH.UIFX_WELFARE_Dice_Loop, Img_Select)
                if DiceDotweenPlayer then
                    DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                    DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                end
                Img_Select:SetActive(false)
            end 
            -- 进行下一圈
            if self._OldDicePos ~= -1 and self._OldDicePos > RollDicePos then
                    local OldItem = self._Table_DiceItemObj[self._OldDicePos] 
                    if DiceDotweenPlayer ~= nil then
                        DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                        DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                    end              
                    if (self._OldDicePos + 1) > 24 then
                        self._OldDicePos = 0
                    end
                    local item = self._Table_DiceItemObj[self._OldDicePos + 1]
                    local Img_Select = GUITools.GetChild(item , 4)
                    local Old_Img_Select = GUITools.GetChild(OldItem , 4)
                    if Img_Select ~= nil and Old_Img_Select ~= nil then
                        Img_Select:SetActive(true)
                        Old_Img_Select:SetActive(false)
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_02, 0)
                        GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select, Img_Select, -1) 
                        GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select, Img_Select, -1)                            
                        if DiceDotweenPlayer ~= nil then
                            DiceDotweenPlayer:Restart(tostring(self._OldDicePos + 1))
                        end
                    end
                    self._OldDicePos = self._OldDicePos + 1
            -- 正常跳对应位置
            elseif self._OldDicePos ~= -1 and self._OldDicePos < RollDicePos then                
                local OldItem = self._Table_DiceItemObj[self._OldDicePos]
                local item = self._Table_DiceItemObj[self._OldDicePos + 1]
                local Img_Select = GUITools.GetChild(item , 4)
                local Old_Img_Select = GUITools.GetChild(OldItem , 4)
                if Img_Select ~= nil and Old_Img_Select ~= nil then
                    Img_Select:SetActive(true)
                    Old_Img_Select:SetActive(false)
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_02, 0)
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select, Img_Select, -1) 
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select, Img_Select, -1) 
                    if DiceDotweenPlayer ~= nil then
                        DiceDotweenPlayer:Restart(tostring(self._OldDicePos + 1))
                        DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                        DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                    end
                end
                self._OldDicePos = self._OldDicePos + 1
            end

            if self._OldDicePos ~= -1 and self._OldDicePos == RollDicePos then
                if self._OldDicePos ~= self._DicePos then
                    RollDicePosTimer = DiceTime + 5
                end
                IsRollDicePos = true
                local item = self._Table_DiceItemObj[RollDicePos]
                local Img_Select = GUITools.GetChild(item , 4)
                Img_Select:SetActive(true)
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_03, 0)
                GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Stop, Img_Select, Img_Select, -1)
            end           
        end

        if DiceTime >= RollDicePosTimer and RollDicePosTimer ~= 0 then
            if DiceItemInfo.EventType == EDiceEventType.DiceNone or DiceItemInfo.EventType == EDiceEventType.DiceMoveTo then
                local OldItem = self._Table_DiceItemObj[self._OldDicePos]
                if DiceDotweenPlayer ~= nil then
                    DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                    DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                end  
                self._OldDicePos = 1
                local item = self._Table_DiceItemObj[self._OldDicePos]               
                local Img_Select = GUITools.GetChild(item , 4)
                local Old_Img_Select = GUITools.GetChild(OldItem , 4)
                if Img_Select ~= nil and Old_Img_Select ~= nil then
                    Img_Select:SetActive(true)
                    Old_Img_Select:SetActive(false)
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_02, 0)
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select, Img_Select, -1) 
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select, Img_Select, -1) 
                    if DiceDotweenPlayer ~= nil then
                        DiceDotweenPlayer:Restart(tostring(self._OldDicePos))
                    end
                end
            elseif DiceItemInfo.EventType == EDiceEventType.DiceForward then
                local OldItem = self._Table_DiceItemObj[self._OldDicePos]
                local item = self._Table_DiceItemObj[self._OldDicePos + 1]
                local Img_Select = GUITools.GetChild(item , 4)
                local Old_Img_Select = GUITools.GetChild(OldItem , 4)
                if Img_Select ~= nil and Old_Img_Select ~= nil then
                    Img_Select:SetActive(true)
                    Old_Img_Select:SetActive(false)
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_02, 0)
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select, Img_Select, -1) 
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select, Img_Select, -1) 
                    if DiceDotweenPlayer ~= nil then
                        DiceDotweenPlayer:Restart(tostring(self._OldDicePos + 1))
                        DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                        DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                    end
                end
                self._OldDicePos = self._OldDicePos + 1

            elseif DiceItemInfo.EventType == EDiceEventType.DiceBackOff then
                local OldItem = self._Table_DiceItemObj[self._OldDicePos]
                local item = self._Table_DiceItemObj[self._OldDicePos - 1]
                local Img_Select = GUITools.GetChild(item , 4)
                local Old_Img_Select = GUITools.GetChild(OldItem , 4)
                if Img_Select ~= nil and Old_Img_Select ~= nil then
                    Img_Select:SetActive(true)
                    Old_Img_Select:SetActive(false)
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_02, 0)
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Loop2, Img_Select, Img_Select, -1) 
                    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Once, Img_Select, Img_Select, -1) 
                    if DiceDotweenPlayer ~= nil then
                        DiceDotweenPlayer:Restart(tostring(self._OldDicePos - 1))
                        DiceDotweenPlayer:Stop(tostring(self._OldDicePos))
                        DiceDotweenPlayer:GoToStartPos(tostring(self._OldDicePos))
                    end
                end
                self._OldDicePos = self._OldDicePos - 1
            end
        end

        if self._OldDicePos ~= -1 and self._OldDicePos == self._DicePos and IsRollDicePos then
            local item = self._Table_DiceItemObj[self._DicePos]
            local Img_Select = GUITools.GetChild(item , 4)
            Img_Select:SetActive(true)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_03, 0)
            GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Dice_Stop, Img_Select, Img_Select, -1)
            if CurDiceItemInfo.EventType == EDiceEventType.DiceReward then
                local reward_template = GUITools.GetRewardList(CurDiceItemInfo.EventParm, true)
                if reward_template ~= nil then 
                    if not reward_template[1].IsTokenMoney then
                        game._GUIMan:ShowMoveItemTextTips(reward_template[1].Data.Id, false, reward_template[1].Data.Count, true)
                    else
                        game._GUIMan:ShowMoveItemTextTips(reward_template[1].Data.Id, true, reward_template[1].Data.Count, true)
                    end 
                end
            end
            self._OldDicePos = -1
            self._IsRollDice = true
            -- GUITools.SetBtnGray(self._Btn_RollDice, not self._IsRollDice)  
            self:UpdateDiceItemList()   
            self:RemoveTimer()
            self._Dice_Hook:SetActive(false)    
            IsRollDicePos = false                     
        end
    end)
end

def.method().RemoveTimer = function(self)
    if self._TimeId ~= 0 then
        _G.RemoveGlobalTimer(self._TimeId)
        self._TimeId = 0
    end
end

-- 更新骰子动画
def.method().UpdateDice = function(self)
    self._Dice_Hook:SetActive(false)
    if game._CWelfareMan._CurrentRollDiceNum > 0 then
        GUITools.SetBtnGray(self._Btn_RollDice, not self._IsRollDice)  
        -- warn("game._CWelfareMan._CurrentRollDiceNum ==>>", game._CWelfareMan._CurrentRollDiceNum, DiceNum[game._CWelfareMan._CurrentRollDiceNum])
        self._Dice_Hook:SetActive(true)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Dice_01, 0)
        local DiceModel = self._Dice_Hook:FindChild("shaizi_donghua/Bone001/shaizi_moxing")
        DiceModel.localRotation = DiceNum[game._CWelfareMan._CurrentRollDiceNum]
        if self._TimeId ~= 0 then
            self:RemoveTimer()            
        end
        self:AddTimer()
        game._CWelfareMan._CurrentRollDiceNum = 0
    else
        self:UpdateDiceItemList()
    end    
end

def.method().Hide = function(self)
    if self._TimeId ~= 0 then
        local DiceDotweenPlayer = self._Frame_Dices:GetComponent(ClassType.DOTweenPlayer)
        local CurDiceItemInfo = self._DiceItemInfos[self._DicePos]
        if CurDiceItemInfo.EventType == EDiceEventType.DiceReward then
            local reward_template = GUITools.GetRewardList(CurDiceItemInfo.EventParm, true)
            if reward_template ~= nil then 
                if not reward_template[1].IsTokenMoney then
                    game._GUIMan:ShowMoveItemTextTips(reward_template[1].Data.Id, false, reward_template[1].Data.Count, true)
                else
                    game._GUIMan:ShowMoveItemTextTips(reward_template[1].Data.Id, true, reward_template[1].Data.Count, true)
                end 
            end
        end
        if DiceDotweenPlayer then
            for i, v in ipairs(self._Table_DiceItemObj) do
                DiceDotweenPlayer:Stop(tostring(i))
                DiceDotweenPlayer:GoToStartPos(tostring(i))
            end
        end
        self._IsRollDice = true
        self:RemoveTimer()
    end
    self._Panel:SetActive(false)
    
end

def.method().Destroy = function (self)
    self:Hide()
end
----------------------------------------------------------------------------------


CPageDice.Commit()
return CPageDice