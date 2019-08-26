local Lplus = require "Lplus"
local CSummonPageBase = require "GUI.CSummonPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local CCommonBtn = require "GUI.CCommonBtn"
local CGame = Lplus.ForwardDeclare("CGame")
local CSummonPageElf = Lplus.Extend(CSummonPageBase, "CSummonPageElf")
local def = CSummonPageElf.define

local ElfRandomInfoSpecialID = 688

def.field("table")._PanelObjects = nil
def.field("table")._AllRewardTable = nil
def.field("table")._ListNodeName = nil
def.field("table")._ElfUseDropRuleTemplate = nil
def.field("table")._ElfUseTenDropRuleTemplate = nil
def.field("table")._NeedMats = nil                      -- 需要的材料
def.field("function")._OnPackageChangeEvent = nil
def.field("number")._PreRewardSpecialID = 441
def.field("number")._TenRewardSpecialID = 572
def.field("number")._DorpAdvancedSpecialID = 442
def.field("number")._DorpMiddleSpecialID = 443
def.field("number")._DorpCommonSpecialID = 444
def.field("number")._RateShowUrlSpecialID = 648         -- 精灵献礼概率查询的URL的特殊ID
def.field("number")._FlowerItemCount = 0
def.field("number")._MaterialItemCount = 0
def.field("number")._TenFlowerItemCount = 0
def.field("number")._TenMaterialItemCount = 0
def.field(CCommonBtn)._Btn_ElfMoneyOne = nil
def.field(CCommonBtn)._Btn_ElfMoneyTen = nil

def.static("=>", CSummonPageElf).new = function()
	local PageElfShop = CSummonPageElf()
    PageElfShop._HasBGVideo = true
	return PageElfShop
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._PanelObjects = {}
    self._PanelObjects._FrameRewardScroll = uiTemplate:GetControl(3)
    self._PanelObjects._FrameAllRewardPanel = uiTemplate:GetControl(2)
    self._PanelObjects._FrameSummon = uiTemplate:GetControl(0)
    self._PanelObjects._Lab_Des = uiTemplate:GetControl(1)
    self._PanelObjects._Frame_MatNoEnough = uiTemplate:GetControl(4)
    self._PanelObjects._Img_BG = uiTemplate:GetControl(5)
    self._PanelObjects._Btn_ElfMoneyOne = uiTemplate:GetControl(6)
    self._PanelObjects._Btn_ElfMoneyTen = uiTemplate:GetControl(7)
    self._PanelObjects._Rdo_Skip = uiTemplate:GetControl(8)
    self._PanelObjects._Lab_Tip = uiTemplate:GetControl(9)
--    self._PanelObjects._Img_Elf = uiTemplate:GetControl(10)
    self._PanelObjects._Frame_MatNoEnough:SetActive(false)
    local setting = {
        [EnumDef.CommonBtnParam.MoneyID] = 2,
        [EnumDef.CommonBtnParam.MoneyCost] = 300
    }
    self._Btn_ElfMoneyOne = CCommonBtn.new(self._PanelObjects._Btn_ElfMoneyOne, setting)
    local setting1 = {
        [EnumDef.CommonBtnParam.MoneyID] = 2,
        [EnumDef.CommonBtnParam.MoneyCost] = 2900 
    }
    self._Btn_ElfMoneyTen = CCommonBtn.new(self._PanelObjects._Btn_ElfMoneyTen, setting1)
end
    
def.override("dynamic").OnData = function(self, data)
    -- [ 暂时隐藏掉消耗货币的按钮 ]
    self._Btn_ElfMoneyOne:SetActive(false)
    self._Btn_ElfMoneyTen:SetActive(false)
    self._PanelObjects._Rdo_Skip:GetComponent(ClassType.Toggle).isOn = not CMallUtility.IsShowGfx(EnumDef.LocalFields.MallSkipGfx_Springift)
    self:InitElfData()
    self:UpdatePanel()
end

def.override().PlayVideoBG = function (self)
	-- local function callback()
 --    end
	-- GameUtil.PlayVideo(self._PanelObjects._Img_Elf, "Mall_CG01_Loop.mp4", true, false, callback)
    GameUtil.ActivateVideoUnit(self._PanelSummon._VideoPlayer_Elf, self._PanelSummon._Img_Screen_Video)
end

def.override().OnShow = function(self)
    self:PlayVideoBG()
end

def.override("=>", "string").GetSummonPageTemplateName = function(self)
    return "Page_MallElf"
end

def.method().UpdatePanel = function(self)
    self:UpdateMaterialNum()
    GUI.SetText(self._PanelObjects._Lab_Des,StringTable.Get(30204))
    local text_temp = CElementData.GetTemplate("Text", 3)
    if text_temp ~= nil then
        GUI.SetText(self._PanelObjects._Lab_Tip, text_temp.TextContent)
    end
end

def.method().InitElfData = function(self)
    local DropRuleId = tonumber(CElementData.GetSpecialIdTemplate(self._PreRewardSpecialID).Value)
    local TenDropRuleId = tonumber(CElementData.GetSpecialIdTemplate(self._TenRewardSpecialID).Value)
    self._ElfUseDropRuleTemplate = CElementData.GetTemplate("DropRule",DropRuleId)
    self._ElfUseTenDropRuleTemplate = CElementData.GetTemplate("DropRule", TenDropRuleId)
    if self._ElfUseDropRuleTemplate == nil then
        warn("error !! CSummonPageElf.InitElfData 精灵献礼使用的掉落模板数据为空")
        return
    end
    if self._ElfUseTenDropRuleTemplate == nil then
        warn("error !! CSummonPageElf.InitElfData 精灵献礼使用的十连抽掉落模板数据为空")
        return
    end
    self._FlowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseDropRuleTemplate.CostItemId2)
    self._MaterialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseDropRuleTemplate.CostItemId1)
    self._TenFlowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseTenDropRuleTemplate.CostItemId2)
    self._TenMaterialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseTenDropRuleTemplate.CostItemId1)
end

def.method().ShowNotEnoughMatPanel = function(self)
    self._PanelObjects._Frame_MatNoEnough:SetActive(true)

    GUITools.SetupDropdownTemplate(self._PanelSummon, self._PanelObjects._Frame_MatNoEnough)

    local uiTemplate = self._PanelObjects._Frame_MatNoEnough:GetComponent(ClassType.UITemplate)
    local list_reward_list = uiTemplate:GetControl(0)
    self._NeedMats = {{itemID = self._ElfUseDropRuleTemplate.CostItemId2, count = self._ElfUseDropRuleTemplate.CostItemCount2}, 
                        {itemID = self._ElfUseDropRuleTemplate.CostItemId1, count = self._ElfUseDropRuleTemplate.CostItemCount1}}
    list_reward_list:GetComponent(ClassType.GNewList):SetItemCount(#self._NeedMats)
end

--刷新界面消耗材料的数量
def.method().UpdateMaterialNum = function (self)
    if self._ElfUseDropRuleTemplate == nil or self._ElfUseTenDropRuleTemplate == nil then
        warn("error !!! 单抽或者十连抽的彩票规则模板为空")
        return
    end
    local uiTemplate = self._PanelObjects._FrameSummon:GetComponent(ClassType.UITemplate)
    local tab_free = uiTemplate:GetControl(2)
    local img_flower = uiTemplate:GetControl(3)
    local lab_flower = uiTemplate:GetControl(4)
    local img_item = uiTemplate:GetControl(5)
    local lab_item = uiTemplate:GetControl(6)
    local img_one_fx = uiTemplate:GetControl(7)
    local img_ten_fx = uiTemplate:GetControl(8)
    local img_flower_ten = uiTemplate:GetControl(9)
    local lab_flower_ten = uiTemplate:GetControl(10)
    local img_item_ten = uiTemplate:GetControl(11)
    local lab_item_ten = uiTemplate:GetControl(12)
    local itemFlower = CElementData.GetItemTemplate(self._ElfUseDropRuleTemplate.CostItemId2)
    local itemMaterial = CElementData.GetItemTemplate(self._ElfUseDropRuleTemplate.CostItemId1)
    local ten_item_flower = CElementData.GetItemTemplate(self._ElfUseTenDropRuleTemplate.CostItemId2)
    local ten_item_material = CElementData.GetItemTemplate(self._ElfUseTenDropRuleTemplate.CostItemId1)
    img_one_fx:SetActive(false)
    img_ten_fx:SetActive(false)
    if self._ElfUseDropRuleTemplate == nil or self._ElfUseTenDropRuleTemplate == nil then
        warn("error !! CSummonPageElf.UpdateMaterialNum 精灵献礼使用的掉落模板为空(单抽或者十连抽)")
        return
    end
    self._FlowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseDropRuleTemplate.CostItemId2)
    self._MaterialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseDropRuleTemplate.CostItemId1)
    self._TenFlowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseTenDropRuleTemplate.CostItemId2)
    self._TenMaterialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._ElfUseTenDropRuleTemplate.CostItemId1)
    GUITools.SetItemIcon(img_flower, itemFlower.IconAtlasPath)
    GUI.SetText(lab_flower, self._FlowerItemCount >= self._ElfUseDropRuleTemplate.CostItemCount2 and string.format(StringTable.Get(30340), self._FlowerItemCount, self._ElfUseDropRuleTemplate.CostItemCount2) 
        or string.format(StringTable.Get(26004), self._FlowerItemCount, self._ElfUseDropRuleTemplate.CostItemCount2))
    GUITools.SetItemIcon(img_item, itemMaterial.IconAtlasPath)
    GUI.SetText(lab_item, self._MaterialItemCount >= self._ElfUseDropRuleTemplate.CostItemCount2 and string.format(StringTable.Get(30340), self._MaterialItemCount, self._ElfUseDropRuleTemplate.CostItemCount1) 
        or string.format(StringTable.Get(26004), self._MaterialItemCount, self._ElfUseDropRuleTemplate.CostItemCount1))
    GUITools.SetItemIcon(img_flower_ten, ten_item_flower.IconAtlasPath)
    GUI.SetText(lab_flower_ten, self._TenFlowerItemCount >= self._ElfUseTenDropRuleTemplate.CostItemCount2 and string.format(StringTable.Get(30340), self._TenFlowerItemCount, self._ElfUseTenDropRuleTemplate.CostItemCount2) 
        or string.format(StringTable.Get(26004), self._TenFlowerItemCount, self._ElfUseTenDropRuleTemplate.CostItemCount2))
    GUITools.SetItemIcon(img_item_ten, ten_item_material.IconAtlasPath)
    GUI.SetText(lab_item_ten, self._TenMaterialItemCount >= self._ElfUseTenDropRuleTemplate.CostItemCount2 and string.format(StringTable.Get(30340), self._TenMaterialItemCount, self._ElfUseTenDropRuleTemplate.CostItemCount1) 
        or string.format(StringTable.Get(26004), self._TenMaterialItemCount, self._ElfUseTenDropRuleTemplate.CostItemCount1))
    if self._FlowerItemCount >= self._ElfUseDropRuleTemplate.CostItemCount1 and self._MaterialItemCount >= self._ElfUseDropRuleTemplate.CostItemCount1 then 
        img_one_fx:SetActive(true)
        self._PanelSummon:ShowRedPoint(self._PageData.StoreId, true)
    else
        img_one_fx:SetActive(false)
        self._PanelSummon:ShowRedPoint(self._PageData.StoreId, false)
    end
    if self._TenFlowerItemCount >= self._ElfUseTenDropRuleTemplate.CostItemCount2 and self._TenMaterialItemCount >= self._ElfUseTenDropRuleTemplate.CostItemCount1 then 
        img_ten_fx:SetActive(true)
    else
        img_ten_fx:SetActive(false)
    end
end

-- 更新花费金钱的按钮
def.method().UpdateCostMoneyBtns = function(self)
    
end

def.override("table", "table").OnGainItem = function(self, sender, event)
    self:UpdatePanel()
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
def.method().InitRewardPanelListNode = function (self)
    self._PanelObjects._FrameAllRewardPanel:SetActive(true)
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
    elseif id == "List_NeedMatsList" then
        local item_data = self._NeedMats[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local item_temp = CElementData.GetItemTemplate(item_data.itemID)
        local item_icon = uiTemplate:GetControl(0)
        local lab_name = uiTemplate:GetControl(1)
        local lab_get_tip = uiTemplate:GetControl(2)
        IconTools.InitItemIconNew(item_icon, item_data.itemID, nil)
        GUI.SetText(lab_name,  RichTextTools.GetItemNameRichText(item_data.itemID, 1, false))
        GUI.SetText(lab_get_tip, item_temp.TextDescription)
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

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if id == "List_NeedMatsList" and id_btn == "Btn_Approach" then
        local itemdata = self._NeedMats[index]
        local item_temp = CElementData.GetItemTemplate(itemdata.itemID)
        local PanelData = 
        {
            ApproachIDs = item_temp.ApproachID,
            ParentObj = self._PanelObjects._Img_BG or button_obj,
            IsFromTip = false,
            TipPanel = self._PanelSummon,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    elseif id == "List_NeedMatsList" and id_btn == "ItemIconNew" then
        CItemTipMan.ShowItemTips(self._NeedMats[index].itemID, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "Rdo_ShowGfx" then
        CMallUtility.SetShowGfx(EnumDef.LocalFields.MallSkipGfx_Springift, not checked)
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_ShowAllReward" then
        self:InitRewardPanelListNode()
    elseif string.find(id,"Btn_CloseDetail") then
        self._PanelObjects._FrameAllRewardPanel:SetActive(false)
    elseif id == "Btn_ElfOne" then
        if CMallMan.Instance()._IsExtracting then return end
        local callback = function(val)
            if val then
                CMallMan.Instance():ElfExtract(1)
            end
        end
        local rewardTable = {
            {
                ID = self._ElfUseDropRuleTemplate.CostItemId2,
                Count = self._ElfUseDropRuleTemplate.CostItemCount2,
                IsMoney = false
            },
            {
                ID = self._ElfUseDropRuleTemplate.CostItemId1,
                Count = self._ElfUseDropRuleTemplate.CostItemCount1,
                IsMoney = false
            },
        }
        MsgBox.ShowQuickMultBuyBox(rewardTable, callback)
    elseif id == "Btn_ElfTen" then
        if CMallMan.Instance()._IsExtracting then return end
        local callback = function(val)
            if val then
                CMallMan.Instance():ElfExtract(10)
            end
        end
        local rewardTable = {
            {
                ID = self._ElfUseTenDropRuleTemplate.CostItemId2,
                Count = self._ElfUseTenDropRuleTemplate.CostItemCount2,
                IsMoney = false
            },
            {
                ID = self._ElfUseTenDropRuleTemplate.CostItemId1,
                Count = self._ElfUseTenDropRuleTemplate.CostItemCount1,
                IsMoney = false
            },
        }
        MsgBox.ShowQuickMultBuyBox(rewardTable, callback)
    elseif id == "Btn_ShowProbability" then
        local bKakaoPlatform = CPlatformSDKMan.Instance():IsInKakao()
        if bKakaoPlatform then
            local key = CElementData.GetSpecialIdTemplate(ElfRandomInfoSpecialID).Value
            local url = CPlatformSDKMan.Instance():GetCustomData(key)
            CPlatformSDKMan.Instance():ShowInAppWeb(url)
        else
            local strValue = CElementData.GetSpecialIdTemplate(self._RateShowUrlSpecialID).Value
            game._GUIMan:OpenUrl(strValue)
            --CPlatformSDKMan.Instance():ShowInAppWeb(strValue)
        end
    elseif id == "Btn_OK" then
        self._PanelObjects._Frame_MatNoEnough:SetActive(false)
    elseif id == "Img_MatNotEnoughBG" then
        self._PanelObjects._Frame_MatNoEnough:SetActive(false)
    end
end

-- 返回键
def.override("=>", "boolean").HandleEscapeKey = function(self)
    if self._PanelObjects._FrameAllRewardPanel.activeSelf then
        self._PanelObjects._FrameAllRewardPanel:SetActive(false)
        return true
    end
    
    return false
end

def.override().OnHide = function(self)
    GameUtil.DeactivateVideoUnit(self._PanelSummon._VideoPlayer_Elf)
    self._FlowerItemCount = 0
    self._MaterialItemCount = 0
    self._TenFlowerItemCount = 0
    self._TenMaterialItemCount = 0
end

def.override().OnDestory = function(self)
    CSummonPageBase.OnDestory(self)

    if self._Btn_ElfMoneyOne ~= nil then
        self._Btn_ElfMoneyOne:Destroy()
        self._Btn_ElfMoneyOne = nil
    end
    if self._Btn_ElfMoneyTen ~= nil then
        self._Btn_ElfMoneyTen:Destroy()
        self._Btn_ElfMoneyTen = nil
    end
    self._PanelObjects = nil
    self._AllRewardTable = nil
    self._ListNodeName = nil
    self._ElfUseDropRuleTemplate = nil
end

CSummonPageElf.Commit()
return CSummonPageElf