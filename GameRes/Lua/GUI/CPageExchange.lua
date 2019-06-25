-- 福利  --> 材料兑换
-- 2019/6/19    lidaming

local Lplus = require "Lplus"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageExchange = Lplus.Class("CPageExchange")
local def = CPageExchange.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Frame_Festival = nil 
def.field('userdata')._List_Festival = nil
def.field("userdata")._Lab_FestivalActivityTime = nil        -- 活动时间


def.field("table")._FestivalInfo = BlankTable
def.field("table")._MaterialList = BlankTable

def.static("table", "userdata", "=>", CPageExchange).new = function(parent, panel)
    local instance = CPageExchange()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Frame_Festival = self._Parent:GetUIObject("Frame_Festival")
    self._List_Festival = self._Parent:GetUIObject('List_Festival'):GetComponent(ClassType.GNewList)

    self._Lab_FestivalActivityTime = self._Parent:GetUIObject("Lab_FestivalActivityTime")

end

--------------------------------------------------------------------------------

def.method().Show = function(self)
    self._Panel:SetActive(true)
    self._FestivalInfo = {}    
    self._FestivalInfo = game._CWelfareMan:GetFestivalInfos()
    self._MaterialList = self._FestivalInfo[game._CWelfareMan._CurFestivalId]._Data.ExchangeRewards
    self._List_Festival:SetItemCount(#self._MaterialList)

end

def.method("string").OnClick = function(self, id)
    if id == "Btn_ExchangeDesc" then          
        game._GUIMan:Close("CPanelUICommonNotice")        
        local data = 
        {
            Title = StringTable.Get(34305),
            Name = StringTable.Get(34200),
            Desc = StringTable.Get(34306),
        }
        game._GUIMan:Open("CPanelUICommonNotice", data)
    end
end

def.method("userdata", "number").OnInitFestivalInfo = function(self, item, index)
    local ItemIcon1 = GUITools.GetChild(item , 0)
    local Img_Add1 = GUITools.GetChild(item , 1)
    local ItemIcon2 = GUITools.GetChild(item , 2)
    local Img_Add2 = GUITools.GetChild(item , 4)
    local ItemIcon3 = GUITools.GetChild(item , 5)
    local ItemIconReward = GUITools.GetChild(item , 6)
    local Btn_Exchange = GUITools.GetChild(item , 7)
    local Lab_ExchangeNum = GUITools.GetChild(item , 8)
    local ItemID = {}
    local ItemNum = {}
    local MaterialData = self._MaterialList[index]

    local curLimitNum = 0
    for _,v in pairs(self._FestivalInfo[1]._FestivalRewardDatas) do
        if v.RewardId == MaterialData.Id then		
            curLimitNum = v.RemainCount
       end
    end
    if curLimitNum == nil then curLimitNum = 0 end
    if curLimitNum <= 0 then
        curLimitNum = RichTextTools.GetUnavailableColorText(tostring(curLimitNum))
        -- Btn_Exchange:MakeGray(true) 
        GUITools.SetBtnGray(Btn_Exchange, true)
    else
        curLimitNum = RichTextTools.GetAvailableColorText(tostring(curLimitNum))
        -- Btn_Exchange:MakeGray(false) 
        GUITools.SetBtnGray(Btn_Exchange, false)
    end
    GUI.SetText(Lab_ExchangeNum , string.format(StringTable.Get(34304), (curLimitNum .. "/" .. MaterialData.ExchangeLimit)))   
    string.gsub(MaterialData.ItemIds, '[^*]+', function(w) table.insert(ItemID, w) end )
    string.gsub(MaterialData.ItemNums, '[^*]+', function(w) table.insert(ItemNum, w) end )
    if #ItemID > 0 and #ItemNum > 0 then
        Img_Add1:SetActive(true)
        Img_Add2:SetActive(true)
        ItemIcon2:SetActive(true)
        ItemIcon3:SetActive(true)
        if ItemID[1] ~= nil and ItemNum[1] ~= nil then
            IconTools.InitMaterialIconNew(ItemIcon1, tonumber(ItemID[1]), tonumber(ItemNum[1]))
        end
        if ItemID[2] ~= nil and ItemNum[2] ~= nil then
            IconTools.InitMaterialIconNew(ItemIcon2, tonumber(ItemID[2]), tonumber(ItemNum[2]))
        else
            Img_Add1:SetActive(false)
            ItemIcon2:SetActive(false)
        end
        if ItemID[3] ~= nil and ItemNum[3] ~= nil then
            IconTools.InitMaterialIconNew(ItemIcon3, tonumber(ItemID[3]), tonumber(ItemNum[3]))
        else
            Img_Add2:SetActive(false)
            ItemIcon3:SetActive(false)
        end
    else
        warn("ItemID == nil !!!")
    end

    local rewardList = GUITools.GetRewardList(MaterialData.RewardId, true)

    if rewardList[1].IsTokenMoney then
        IconTools.InitTokenMoneyIcon(ItemIconReward, rewardList[1].Data.Id, rewardList[1].Data.Count)
    else
        local setting = {
            [EItemIconTag.Number] = rewardList[1].Data.Count,
        }
        IconTools.InitItemIconNew(ItemIconReward, rewardList[1].Data.Id, setting, EItemLimitCheck.AllCheck)
    end
end

def.method("number").OnSelectFestivalInfoButton = function(self, index)
    -- self._FestivalInfo[index]
    local ItemID = {}
    local ItemNum = {}
    local MaterialData = self._MaterialList[index]
    string.gsub(MaterialData.ItemIds, '[^*]+', function(w) table.insert(ItemID, w) end )
    string.gsub(MaterialData.ItemNums, '[^*]+', function(w) table.insert(ItemNum, w) end )
    local isMaterialEnough1 = true
    local isMaterialEnough2 = true
    local isMaterialEnough3 = true
    if #ItemID > 0 and #ItemNum > 0 then
        if ItemID[1] ~= nil and ItemNum[1] ~= nil then
            local packageNum1 = game._HostPlayer._Package._NormalPack:GetItemCount(tonumber(ItemID[1]))
            local needNum1 = tonumber(ItemNum[1])
            isMaterialEnough1 = needNum1 <= packageNum1
        end
        if ItemID[2] ~= nil and ItemNum[2] ~= nil then
            local packageNum2 = game._HostPlayer._Package._NormalPack:GetItemCount(tonumber(ItemID[2]))
            local needNum2 = tonumber(ItemNum[2])
            isMaterialEnough2 = needNum2 <= packageNum2
        end
        if ItemID[3] ~= nil and ItemNum[3] ~= nil then
            local packageNum3 = game._HostPlayer._Package._NormalPack:GetItemCount(tonumber(ItemID[3]))
            local needNum3 = tonumber(ItemNum[3]) 
            local isMaterialEnough3 = needNum3 <= packageNum3
        end
        if not isMaterialEnough1 or not isMaterialEnough2 or not isMaterialEnough3 then
            game._GUIMan: ShowTipText(StringTable.Get(34300), true)
        else
            game._CWelfareMan:OnC2SFestivalExchange(self._FestivalInfo[1]._Data.Id, MaterialData.Id)
        end
    else
        warn("ItemID == nil !!!")
    end
end

def.method("userdata", "string", "number").OnSelectMaterial = function(self, button_obj, id_btn, index)
    local MaterialData = self._MaterialList[index]
    if string.find(id_btn, "MaterialIcon") then
        local MaterialIndex = tonumber(string.sub(id_btn, string.len("MaterialIcon") +1, -1))   
        local ItemID = {}
        local ItemNum = {}
        string.gsub(MaterialData.ItemIds, '[^*]+', function(w) table.insert(ItemID, w) end )
    
        local MaterialId = tonumber(ItemID[MaterialIndex])
        CItemTipMan.ShowItemTips(MaterialId, 
                                TipsPopFrom.OTHER_PANEL, 
                                button_obj, 
                                TipPosition.FIX_POSITION)
    elseif string.find(id_btn, "ItemIconNewReward") then
        local reward_template = GUITools.GetRewardList(MaterialData.RewardId, true)
        if reward_template ~= nil then 
            if not reward_template[1].IsTokenMoney then
                local RewardId = reward_template[1].Data.Id
                CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL , ItenBtn, TipPosition.FIX_POSITION) 
            else
                -- TODO("货币不是 Item了,统一UE时记得改！")
                local panelData = {}
                panelData = 
                {
                    _MoneyID = reward_template[1].Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = ItenBtn ,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
            end 
        end
    end
end

def.method().Hide = function(self)
    self._Panel:SetActive(false)

end

def.method().Destroy = function (self)
    self:Hide()


end
----------------------------------------------------------------------------------


CPageExchange.Commit()
return CPageExchange