local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local CMallPagePetEggShop = Lplus.Extend(CMallPageBase, "CMallPagePetEggShop")
local def = CMallPagePetEggShop.define

def.field("table")._PanelObjects = BlankTable
def.field("boolean")._IsReadyPetData = false
def.field("boolean")._IsCanFreePet = false
def.field("table")._ExchangePetItemsData = nil 
def.field("number")._ExchangePetRefTimer = 0             --碎片兑换商店刷新时间
def.field("number")._PetFreeTimer = 0
def.field("number")._OneCostMoneyCount = 0
def.field("number")._TenCostMoneyCount = 0
def.field("number")._OneCostMoneyID = 0
def.field("number")._TenCostMoneyID = 0
def.field("number")._PetExchangeCostMoneyId = 0 
def.field("number")._PetDroupSpecialId = 458
def.field("number")._PetTenDroupSpecialId = 573
--def.field("number")._PetDroupGroupSpecialID = 349               -- 宠物掉落组特殊ID（用来预览）
def.field("number")._DorpAdvancedSpecialID = 614
def.field("number")._DorpMiddleSpecialID = 615
def.field("number")._DorpCommonSpecialID = 616
def.field("number")._RateShowUrlSpecialID = 649                 -- 概率查询URL的特殊ID
def.field("table")._CostCountExchangeDataList = BlankTable
def.field("number")._HaveCount = 0                              -- 单抽有的钱
def.field("number")._TenHaveCount = 0                           -- 十连抽有的钱
def.field("number")._HaveExchangeMoneyCount = 0
def.field("table")._AllRewardTable = nil                        -- 全部奖励物品信息
def.field("table")._ListNodeName = nil                          -- 提示品质名称列表

def.static("=>", CMallPagePetEggShop).new = function()
	local PageEggShop = CMallPagePetEggShop()
    PageEggShop._HasBGVideo = true
	return PageEggShop
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._PanelObjects = {}
    self._PanelObjects.Frame_Pet = uiTemplate:GetControl(0)
    self._PanelObjects.LabPetCost1 = uiTemplate:GetControl(1)
    self._PanelObjects.LabPetCost2 = uiTemplate:GetControl(2)
    self._PanelObjects.ImgPetCost1 = uiTemplate:GetControl(3)
    self._PanelObjects.ImgPetCost2 = uiTemplate:GetControl(4)
    self._PanelObjects.LabExchangeTime = uiTemplate:GetControl(5)
    self._PanelObjects.FrameNoFreePet = uiTemplate:GetControl(6)
    self._PanelObjects.LabPetFreeTime = uiTemplate:GetControl(8)
    self._PanelObjects.FramePetExchange = uiTemplate:GetControl(9)
    self._PanelObjects.LabHaveMoney = uiTemplate:GetControl(10)
    self._PanelObjects.ImgHaveMoney = uiTemplate:GetControl(11)
    self._PanelObjects.ImgPetFreeFX = uiTemplate:GetControl(27)
    self._PanelObjects.Img_Free = uiTemplate:GetControl(28)
    self._PanelObjects.Tab_Cost = uiTemplate:GetControl(29)
    self._PanelObjects.Rdo_Skip = uiTemplate:GetControl(30)
    
--    self._PanelObjects.FrameShowReward = uiTemplate:GetControl(30)
--    self._PanelObjects.ListItemPreview = uiTemplate:GetControl(31)
    self._PanelObjects.LabNameExchange = {}
    table.insert(self._PanelObjects.LabNameExchange,uiTemplate:GetControl(12))
    table.insert(self._PanelObjects.LabNameExchange,uiTemplate:GetControl(13))
    table.insert(self._PanelObjects.LabNameExchange,uiTemplate:GetControl(14))
    self._PanelObjects.ImgExchangePetIcon = {}
    table.insert(self._PanelObjects.ImgExchangePetIcon,uiTemplate:GetControl(15))
    table.insert(self._PanelObjects.ImgExchangePetIcon,uiTemplate:GetControl(16))
    table.insert(self._PanelObjects.ImgExchangePetIcon,uiTemplate:GetControl(17))
    self._PanelObjects.ImgExchangePetBg = {}
    table.insert(self._PanelObjects.ImgExchangePetBg,uiTemplate:GetControl(18))
    table.insert(self._PanelObjects.ImgExchangePetBg,uiTemplate:GetControl(19))
    table.insert(self._PanelObjects.ImgExchangePetBg,uiTemplate:GetControl(20))
    self._PanelObjects.ImgExchangePetQuality = {}
    table.insert(self._PanelObjects.ImgExchangePetQuality,uiTemplate:GetControl(34))
    table.insert(self._PanelObjects.ImgExchangePetQuality,uiTemplate:GetControl(35))
    table.insert(self._PanelObjects.ImgExchangePetQuality,uiTemplate:GetControl(36))
    self._PanelObjects.ImgMoneyExchange = {}
    table.insert(self._PanelObjects.ImgMoneyExchange,uiTemplate:GetControl(21))
    table.insert(self._PanelObjects.ImgMoneyExchange,uiTemplate:GetControl(22))
    table.insert(self._PanelObjects.ImgMoneyExchange,uiTemplate:GetControl(23))
    self._PanelObjects.LabExchangeMoney = {}
    table.insert(self._PanelObjects.LabExchangeMoney,uiTemplate:GetControl(24))
    table.insert(self._PanelObjects.LabExchangeMoney,uiTemplate:GetControl(25))
    table.insert(self._PanelObjects.LabExchangeMoney,uiTemplate:GetControl(26))
    self._PanelObjects._FrameAllRewardPanel = uiTemplate:GetControl(32)
    self._PanelObjects._FrameRewardScroll = uiTemplate:GetControl(33)
    self._PanelObjects._Lab_Tip = uiTemplate:GetControl(37)
--    self._PanelObjects._Img_Pet = uiTemplate:GetControl(38)
end
    
def.override("dynamic").OnData = function(self, data)
    self:InitPetPanel()
    local C2SPetDropRuleSync = require "PB.net".C2SPetDropRuleSync
    local protocol = C2SPetDropRuleSync()
    local PBHelper = require "Network.PBHelper"
    PBHelper.Send(protocol)
    game._CGuideMan:AnimationEndCallBack(self._PanelMall)
end

def.override().OnShow = function(self)
    self:PlayVideoBG()
end

def.override().PlayVideoBG = function (self)
	-- local function callback()
 --    end
	-- GameUtil.PlayVideo(self._PanelObjects._Img_Pet, "Mall_CG02_Loop.mp4", true, false, callback)
    GameUtil.ActivateVideoUnit(self._PanelMall._VideoPlayer_Pet, self._PanelMall:GetUIObject("Img_Elf"))
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterButtonEventHandler(self._Panel, self._GameObject,true)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
    GUITools.RegisterToggleEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallPetEgg"
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "Rdo_ShowGfx" then
        CMallUtility.SetShowGfx(EnumDef.LocalFields.PetEggSkipGfx_PetEgg, not checked)
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_PetOne" or id == "Btn_PetTen"then 
        if not self._IsReadyPetData then return end
        local str = string.sub(id,8,-1)
        local Count = nil 
        local isCanDo = nil
        local cost = 0
        local cost_money_id = 0
        if str == "Ten" then
            Count = 10
            cost = self._TenCostMoneyCount
            cost_money_id = self._OneCostMoneyID
        else
            Count = 1
            cost = self._OneCostMoneyCount
            cost_money_id = self._TenCostMoneyID
        end

        local callback = function(val)
            if val then
                CMallMan.Instance():PetExtract(Count)
                if Count == 1 then
                    self._PanelObjects.ImgPetFreeFX:SetActive(false)
                    CMallMan.Instance():SaveRedPointState(self._PageData.StoreId, false)
                    self._PanelMall:ShowRedPoint(self._PageData.StoreTagId, self._PageData.StoreId, false)
                end
            end
        end
        if Count == 1 and self._IsCanFreePet then
            callback(true)
        else
            MsgBox.ShowQuickBuyBox(cost_money_id, cost, callback)
        end
    elseif id == "Btn_PetExchange" then 
        self:ShowExchangePanel()
    elseif string.find(id,"Btn_CloseDetail") then
        --self._PanelObjects._FrameAllRewardPanel:SetActive(false)
        self:ShowRewardViewPanel(false)
    elseif id == "Btn_ExchangeBack" then 
       self._PanelObjects.FramePetExchange:SetActive(false)
    elseif id == "Btn_ShowProbability" then
--        if self._PageData.RateQueryURL == nil or self._PageData.RateQueryURL == "" then
--            warn("error !!! 要跳转的URL为空 ！！ ", debug.traceback())
--        else
--            --game._GUIMan:OpenUrl(self._PageData.RateQueryURL)
--            local strValue = CElementData.GetSpecialIdTemplate(self._RateShowUrlSpecialID).Value
--            print("strValue ", strValue)
--            CPlatformSDKMan.Instance():ShowInAppWeb(strValue)
--        end
        local strValue = CElementData.GetSpecialIdTemplate(self._RateShowUrlSpecialID).Value
        CPlatformSDKMan.Instance():ShowInAppWeb(strValue)
    elseif string.find(id,"Btn_PetChange") then 
        local index = tonumber(string.sub(id,-1))
        local needCount = self._CostCountExchangeDataList[index]
        if needCount > self._HaveExchangeMoneyCount then

            game._GUIMan:ShowTipText(StringTable.Get(19478),false)
            return
        end
        local C2SPetSaleBuyReq = require "PB.net".C2SPetSaleBuyReq
        local protocol = C2SPetSaleBuyReq()
        protocol.Slot = index - 1
        local PBHelper = require "Network.PBHelper"
        PBHelper.Send(protocol)
    elseif id == "Btn_PetShow" then 
        game._GUIMan:Open("CPanelUIPetFieldGuide", nil)
    elseif id == "Btn_ShowAllReward" then
        self:ShowRewardViewPanel(true)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if string.find(id, "List_RewardItem") then
        local bigTypeIndex = tonumber(string.sub(id, -1))
        local current_Node_list = self._AllRewardTable[bigTypeIndex]
        local rewardData = current_Node_list[index]
        local lab_rate = GUITools.GetChild(item, 1)
        lab_rate:SetActive(false)
--        GUI.SetText(lab_rate, CMallUtility.GetPercentString(rewardData.Probability))
        local frame_item_icon = GUITools.GetChild(item, 0)
        IconTools.InitItemIconNew(frame_item_icon, rewardData.ItemId, nil, EItemLimitCheck.AllCheck)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if string.find(id, "List_RewardItem") then
        local bigTypeIndex = tonumber(string.sub(id, -1))
        local smallTypeIndex = index + 1
        local current_Node_list = self._AllRewardTable[bigTypeIndex]
        CItemTipMan.ShowItemTips(current_Node_list[smallTypeIndex].ItemId, TipsPopFrom.OTHER_PANEL ,item,TipPosition.FIX_POSITION)
    end
end

-- 小时，分钟，不足一分钟显示 1分钟后刷新
local function formatTime(startTime)
    if startTime <= 60 then 
       local strTime = StringTable.Get(19477)
        return strTime
    end
    local hour = math.floor(startTime/ 3600)
    local minute = math.floor(startTime % 3600 / 60)
    if hour > 0 then 
        local strTime = string.format(StringTable.Get(706),hour,minute)
        return strTime
    else
        local strTime = string.format(StringTable.Get(707),minute)
        return strTime
    end
end

def.method().InitPetPanel = function(self)
    local dropRuleId = tonumber(CElementData.GetSpecialIdTemplate(self._PetDroupSpecialId).Value)
    local dropTenRuleId = tonumber(CElementData.GetSpecialIdTemplate(self._PetTenDroupSpecialId).Value)
    local dropRuleTemplate = CElementData.GetTemplate("DropRule",dropRuleId)
    local dropTenRuleTemplate = CElementData.GetTemplate("DropRule", dropTenRuleId)
    if dropRuleTemplate == nil then warn(" droupRule id".. dropRuleId .." is nil") return end
    local text_temp = CElementData.GetTemplate("Text", 4)
    if text_temp ~= nil then
        GUI.SetText(self._PanelObjects._Lab_Tip, text_temp.TextContent)
    end
    self._OneCostMoneyCount = dropRuleTemplate.CostMoneyCount
    self._TenCostMoneyCount = dropTenRuleTemplate.CostMoneyCount
    self._HaveCount = game._HostPlayer:GetMoneyCountByType(dropRuleTemplate.CostMoneyId)
    self._TenHaveCount = game._HostPlayer:GetMoneyCountByType(dropTenRuleTemplate.CostMoneyId)
    self._OneCostMoneyID = dropRuleTemplate.CostMoneyId
    self._TenCostMoneyID = dropTenRuleTemplate.CostMoneyId
    GUI.SetText(self._PanelObjects.LabPetCost1,GUITools.FormatNumber(dropRuleTemplate.CostMoneyCount, false))
    GUI.SetText(self._PanelObjects.LabPetCost2,GUITools.FormatNumber(dropTenRuleTemplate.CostMoneyCount, false))
    GUITools.SetTokenMoneyIcon(self._PanelObjects.ImgPetCost1,dropRuleTemplate.CostMoneyId)
    GUITools.SetTokenMoneyIcon(self._PanelObjects.ImgPetCost2,dropTenRuleTemplate.CostMoneyId)
    self._PanelObjects.Rdo_Skip:GetComponent(ClassType.Toggle).isOn = not CMallUtility.IsShowGfx(EnumDef.LocalFields.PetEggSkipGfx_PetEgg)
end

def.method("number","number").GetRewardListBySpecialId = function (self,specialId,nameId)
    local strValue = CElementData.GetSpecialIdTemplate(specialId).Value
    if strValue ~= nil then 
        local valueTable = string.split(strValue,'*')
        local itemDatas = {}
        for i,v in ipairs(valueTable) do
            local itemList =  GUITools.GetDropLibraryItemList(tonumber(v))
            local drop_down_temp = CElementData.GetTemplate("DropLibrary", tonumber(v))
            local host_level = game._HostPlayer._InfoData._Level
            repeat
                if drop_down_temp == nil or drop_down_temp.MinLevelLimit > host_level or drop_down_temp.MaxLevelLimit < host_level then break end
                if itemList == nil then warn(" id DropLibraryItem is nil " ,v) return end
                if #itemList > 0 then 
                    for i,v in ipairs(itemList) do
                        if CMallUtility.IsCanUseItem(v.ItemId) then
                            itemDatas[#itemDatas + 1] = v
                        end
                    end
                end
            until true;
        end
        if #itemDatas > 0 then 
            table.insert(self._ListNodeName,StringTable.Get(30200 + nameId))
            self._AllRewardTable[#self._AllRewardTable + 1] = itemDatas
        end
    end
end

-- 初始化奖励界面节点数据
def.method("boolean").ShowRewardViewPanel = function (self, isShow)
    if isShow then
        self._PanelObjects._FrameAllRewardPanel:SetActive(true)
    else
        self._PanelObjects._FrameAllRewardPanel:SetActive(false)
        return
    end
    
    if self._AllRewardTable ~= nil then return end
    local uiTemplate = self._PanelObjects._FrameAllRewardPanel:GetComponent(ClassType.UITemplate)
    local lab_title_list = {}
    local list_reward_list = {}
    lab_title_list[#lab_title_list + 1] = uiTemplate:GetControl(0)
    lab_title_list[#lab_title_list + 1] = uiTemplate:GetControl(2)
    lab_title_list[#lab_title_list + 1] = uiTemplate:GetControl(4)
    list_reward_list[#list_reward_list + 1] = uiTemplate:GetControl(1)
    list_reward_list[#list_reward_list + 1] = uiTemplate:GetControl(3)
    list_reward_list[#list_reward_list + 1] = uiTemplate:GetControl(5)
    self._AllRewardTable = {}
    self._ListNodeName = {}
    -- 顶级
    self:GetRewardListBySpecialId(self._DorpAdvancedSpecialID,1)
    -- 高级
    self:GetRewardListBySpecialId(self._DorpMiddleSpecialID,2)
    -- 普通
    self:GetRewardListBySpecialId(self._DorpCommonSpecialID,3)
    if #self._AllRewardTable == 0 then 
        -- warn("Elf DropLibrary data is all nil")
    else
        GameUtil.SetScrollPositionZero(self._PanelObjects._FrameRewardScroll)
        for i = 1,3 do 
            if #self._AllRewardTable < i then
                lab_title_list[i]:SetActive(false)
                list_reward_list[i]:SetActive(false)
            else
                local itemObj = list_reward_list[i]
                itemObj:SetActive(true)
                local Node_list = self._AllRewardTable[i]
                GUI.SetText(lab_title_list[i], self._ListNodeName[i])
                local current_type_count = #Node_list
                if current_type_count > 0 then
                    itemObj:GetComponent(ClassType.GNewList):SetItemCount(current_type_count)
                end
            end
        end 
    end
end

def.method("table").OnS2CPetInitDataAndPanel = function(self,data)
    self._IsReadyPetData = true
    self._ExchangePetItemsData = data.PetDropRule.Items
    local petFreeTime = data.PetDropRule.PetFreeTime
    if petFreeTime == 0 or os.time() >= petFreeTime then 
        self._IsCanFreePet = true
        self._PanelObjects.FrameNoFreePet:SetActive(false)
        self._PanelObjects.ImgPetFreeFX:SetActive(true)
        self._PanelObjects.Img_Free:SetActive(true)
        self._PanelObjects.Tab_Cost:SetActive(false)
    else
        self._IsCanFreePet = false
        self._PanelObjects.FrameNoFreePet:SetActive(true)
        self._PanelObjects.ImgPetFreeFX:SetActive(false)
        self._PanelObjects.Img_Free:SetActive(false)
        self._PanelObjects.Tab_Cost:SetActive(true)
        self._PetFreeTimer = self:AddTimer(self._PetFreeTimer,petFreeTime,false)
    end
    self._ExchangePetRefTimer = self:AddTimer(self._ExchangePetRefTimer,data.PetDropRule.PetSaleRefreshTime,true)
end

def.method().ResetPage = function(self)
    self._IsCanFreePet = true
    self._PanelObjects.ImgPetFreeFX:SetActive(true)
    self._PanelObjects.FrameNoFreePet:SetActive(false)
    self._PanelObjects.Img_Free:SetActive(true)
    self._PanelObjects.Tab_Cost:SetActive(false)
end

def.method("number","number","boolean","=>","number").AddTimer = function(self,timer,startTime,isExchange)
    if timer ~= 0 then
        _G.RemoveGlobalTimer(timer)
        timer = 0
    end
    local strTime = nil 
    local endTime = (startTime - GameUtil.GetServerTime())/1000

    --倒计时结束，重置抽取状态 BY luee
    if endTime <= 0 then
        self:ResetPage()
        return 0 
    end

    local callback = function()
        endTime = endTime - 1
        if not isExchange then 
            GUI.SetText(self._PanelObjects.LabPetFreeTime,GUITools.FormatTimeFromSecondsToZero(true,endTime))
        else
            GUI.SetText(self._PanelObjects.LabExchangeTime,formatTime(endTime)) 
        end
        if endTime <= 0 then 
            _G.RemoveGlobalTimer(timer)
            timer = 0
            self:ResetPage()
        end
    end
    timer = _G.AddGlobalTimer(1, false, callback) 
    return timer   
end

def.method().ShowExchangePanel = function(self)
    self._PanelObjects.FramePetExchange:SetActive(true)
    local costId = nil
    for i,v in ipairs(self._ExchangePetItemsData) do
        local itemTemp = CElementData.GetItemTemplate(v)
        if itemTemp == nil then  warn("item id ".. v.." is nil") return end
        GUITools.SetItemIcon(self._PanelObjects.ImgExchangePetIcon[i],itemTemp.IconAtlasPath)
        GUI.SetText(self._PanelObjects.LabNameExchange[i],itemTemp.TextDisplayName)
        if itemTemp.InitQuality == 5 then
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetBg[i],0)
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetQuality[i],0)
        elseif itemTemp.InitQuality == 3 then
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetBg[i],1)
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetQuality[i],1)
        elseif itemTemp.InitQuality == 2 then
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetBg[i],2)
            GUITools.SetGroupImg(self._PanelObjects.ImgExchangePetQuality[i],2)
        end
        local dropRuleId = tonumber(CElementData.GetSpecialIdTemplate(460 + i).Value)
        local dropRuleTemplate = CElementData.GetTemplate("DropRule",dropRuleId)
        if dropRuleTemplate == nil then warn(" droupRule id".. dropRuleId .." is nil") return end
        GUI.SetText(self._PanelObjects.LabExchangeMoney[i],GUITools.FormatNumber(dropRuleTemplate.CostMoneyCount, false))
        table.insert(self._CostCountExchangeDataList,dropRuleTemplate.CostMoneyCount)
        GUITools.SetTokenMoneyIcon(self._PanelObjects.ImgMoneyExchange[i],dropRuleTemplate.CostMoneyId)
        costId = dropRuleTemplate.CostMoneyId
    end
    self._PetExchangeCostMoneyId = costId
    self._HaveExchangeMoneyCount = game._HostPlayer:GetMoneyCountByType(self._PetExchangeCostMoneyId)
    GUI.SetText(self._PanelObjects.LabHaveMoney,GUITools.FormatNumber(self._HaveExchangeMoneyCount, false))
    GUITools.SetTokenMoneyIcon(self._PanelObjects.ImgHaveMoney,costId)
end

def.method("number").AddNextFreeTime = function(self,nextFreeTime)
    self._PanelObjects.FrameNoFreePet:SetActive(true)
    self._PanelObjects.Img_Free:SetActive(false)
    self._PanelObjects.Tab_Cost:SetActive(true)
    self._PetFreeTimer = self:AddTimer(self._PetFreeTimer,nextFreeTime,false)
    self._IsCanFreePet = false
end

def.method().UpdateMoney = function(self)
    self._HaveExchangeMoneyCount = game._HostPlayer:GetMoneyCountByType(self._PetExchangeCostMoneyId)
    GUI.SetText(self._PanelObjects.LabHaveMoney,GUITools.FormatNumber(self._HaveExchangeMoneyCount, false))
end

def.override().OnHide = function(self)
    GameUtil.DeactivateVideoUnit(self._PanelMall._VideoPlayer_Pet)
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)

    if self._PetFreeTimer ~= 0 then 
        _G.RemoveGlobalTimer(self._PetFreeTimer)
        self._PetFreeTimer = 0
    end
    if self._ExchangePetRefTimer ~= 0 then 
        _G.RemoveGlobalTimer(self._ExchangePetRefTimer)
        self._ExchangePetRefTimer = 0
    end
    self._AllRewardTable = nil
    self._ListNodeName = nil

end

CMallPagePetEggShop.Commit()
return CMallPagePetEggShop