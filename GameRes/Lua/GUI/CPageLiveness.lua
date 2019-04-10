local Lplus                 = require "Lplus"
local CPageLiveness         = Lplus.Class("CPageLiveness")
local def                   = CPageLiveness.define
local CGame                 = Lplus.ForwardDeclare("CGame")
local CElementData          = require "Data.CElementData"
local EAdventrueGuideOpt    = require "PB.net".C2SAdventureGuideGetData.EAdventrueGuideOpt

def.field("table")._ActivityContent = BlankTable            -- 活动列表
def.field("table")._ActivityValue = BlankTable              -- 活跃度值
def.field("number")._MaxLiveness = 150                      -- 最大活跃度值

def.field("userdata")._Frame_Liveness = nil			        -- 活跃度节点
def.field("userdata")._Frame_Activity = nil			        -- 活动列表节点
def.field('userdata')._Pro_Liveness = nil                   -- 活跃度进度条
def.field('userdata')._Lab_Liveness = nil
def.field('userdata')._List_ActivityMenu = nil

def.field("userdata")._ParentGO = nil                       -- 父节点GO
def.field("table")._Parent = nil                            -- Panel节点

def.static("table", "=>", CPageLiveness).new = function(root)
    local obj = CPageLiveness()
    print(root)
    obj._Parent = root
    obj._ParentGO = root._Panel
	obj:Init()
    return obj 
end


def.method().Init = function(self)
    self._Frame_Liveness       = self._Parent._PageRoot:FindChild("PageLiveness/Frame_Liveness")
    self._Frame_Activity       = self._Parent._PageRoot:FindChild("PageLiveness/Frame_Activity")
    self._Pro_Liveness         = self._Parent._PageRoot:FindChild("PageLiveness/Frame_Liveness/Pro_Liveness"):GetComponent(ClassType.Scrollbar)
    self._Lab_Liveness         = self._Parent._PageRoot:FindChild('PageLiveness/Frame_Liveness/Lab_CurLivenssDesc/Lab_Liveness')
    self._List_ActivityMenu    = self._Frame_Activity:FindChild('List_Activity/List_ActivityMenu'):GetComponent(ClassType.GNewListLoop)
end

def.method().Show = function (self)
    self:GetActivityReward()
end

def.method("=>", "boolean").ShowRedPoint = function(self)
    return game._CCalendarMan:GetCalendarRewardRedPointState()    -- false
end

def.method("string").OnClick = function (self, id)
    if string.find(id,"Btn_Item") then
        for i,v in pairs(self._ActivityValue) do
            if id == "Btn_Item_0" .. i then
                if v == 1 then
                    game._CCalendarMan:SendC2SActivityGetReward(EAdventrueGuideOpt.EAD_reward ,(i - 1))
                elseif v == 0 then
                    local liveness_template = CElementData.GetTemplate("Liveness", i)
                    if liveness_template == nil then return end
                    local ItenBtn = self._Frame_Liveness:FindChild("Frame_Gift_0"..i.."/Btn_Item_0"..i)
                    local reward_template = GUITools.GetRewardList(liveness_template.RewardId, true)

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
                else
                    game._GUIMan:ShowTipText(StringTable.Get(19453), false)
                end
            end
        end 
    end
end

def.method().GetActivityReward = function(self)
    self._ActivityValue = game._CCalendarMan:GetActivityGainRewardData()   
    self:InitActivityContent()
    self._List_ActivityMenu:SetItemCount(#self._ActivityContent)


    GUI.SetText(self._Lab_Liveness, (game._CCalendarMan:GetCurActivityValue().."/".. self._MaxLiveness))     --服务器传过来的当前活跃度值
    self._Pro_Liveness.size = game._CCalendarMan:GetCurActivityValue() / self._MaxLiveness  
    
    for i,v in pairs(self._ActivityValue) do
        local Img_Item = self._Frame_Liveness:FindChild("Frame_Gift_0"..i.."/Btn_Item_0"..i.."/Img_Item_0" .. i)
        local Img_ItemOpen = self._Frame_Liveness:FindChild("Frame_Gift_0"..i.."/Btn_Item_0"..i.."/Img_Item_0" .. i .."open")
        if v == 0 then
            -- GameUtil.MakeImageGray(Img_Item, false)
            Img_ItemOpen:SetActive(false)
            Img_Item:SetActive(true)
            GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, Img_Item)
        elseif v == 1 then
            -- 可领取播放宝箱特效。     
            Img_ItemOpen:SetActive(false)  
            Img_Item:SetActive(true)
            GameUtil.PlayUISfx(PATH.UIFX_CALENDAR_LingQu, Img_Item, Img_Item, -1)
        elseif v == 2 then
            -- GameUtil.MakeImageGray(Img_Item, true)
            Img_ItemOpen:SetActive(true)
            Img_Item:SetActive(false)
            GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, Img_Item)
        end        
    end
end

def.method('userdata', 'string', 'number').OnInitItem = function (self, item, id, index)
    if id == "List_ActivityMenu" then
        local temData = self._ActivityContent[index + 1]
        -- warn("temdata == ", temData._Data.Id, temData._Data.Name)
        if temData ~= nil then
            local Lab_ActivityName = GUITools.GetChild(item , 1)
            local Lab_ActivityDesc = GUITools.GetChild(item , 2)
            local Lab_ActivityNum = GUITools.GetChild(item , 3)
            local Lab_LivenessNum = GUITools.GetChild(item , 5)
            local Btn_Join = GUITools.GetChild(item , 6)
            local Img_LivenessIcon = GUITools.GetChild(item , 10)
            local Img_Done = GUITools.GetChild(item , 11)
            GUI.SetText(Lab_ActivityName, temData._Data.Name)
            GUI.SetText(Lab_ActivityDesc, temData._Data.TaskRequirement)
            
            local ActivityNumStr = nil
            ActivityNumStr = temData._CurValue .. "/" .. temData._Data.ActivityNum   -- temData._Data.ActivityNum - temData._CurValue
            GUI.SetText(Lab_ActivityNum, ActivityNumStr)

            GUI.SetText(Lab_LivenessNum, tostring(temData._Data.Liveness * temData._Data.ActivityNum))
            if temData._Data.IconPath2 ~= "" then
                GUITools.SetIcon(Img_LivenessIcon, temData._Data.IconPath2)
            end

            if (temData._Data.ActivityNum - temData._CurValue) > 0 then
                Img_Done:SetActive(false)
                Btn_Join:SetActive(true)
            else
                Img_Done:SetActive(true)
                Btn_Join:SetActive(false)
            end
        end
    end
end

def.method('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)

end

def.method("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == "Btn_Join" then
        local temData = self._ActivityContent[index + 1]
        game._CCalendarMan:OpenPlayByActivityInfo(temData)       
             
    end
end

local function sort_func_by_sortindex(a, b)
    if a._Data.SortIndex ~= b._Data.SortIndex then
        -- 根据排序index从小到大
        return a._Data.SortIndex < b._Data.SortIndex
    end
    return false
end

-- 初始化冒险日历列表
def.method().InitActivityContent = function(self)
    local not_complete_list = {}
    local lock_list = {}
    for _, v in ipairs(game._CCalendarMan:GetAllCalendarData()) do
        if v._Data.PlayPos == "1" then
            if v._IsOpen then
                if (v._Data.ActivityNum - v._CurValue) > 0 then
                    table.insert(not_complete_list, v)
                else
                    table.insert(lock_list, v)
                end
            end
        end
    end
    table.sort(not_complete_list, sort_func_by_sortindex)
    table.sort(lock_list, sort_func_by_sortindex)

    local all_activtiy_list = {}
    -- 未完成的排最前
    for _, data in ipairs(not_complete_list) do
        table.insert(all_activtiy_list, data)
    end
    -- 未到活动时间的排中间
    for _, data in ipairs(lock_list) do
        table.insert(all_activtiy_list, data)
    end

    self._ActivityContent = all_activtiy_list
end


def.method().Hide = function (self)
    
end

def.method().Destroy = function (self)
    self._Frame_Liveness    = nil
    self._Frame_Activity    = nil
    self._ActivityValue     = {}
    self._Pro_Liveness      = nil
    self._Lab_Liveness      = nil
    self._ActivityContent   = {}
    self._List_ActivityMenu = nil
    self._Parent            = {}
    self._ParentGO          = nil
end

CPageLiveness.Commit()
return CPageLiveness