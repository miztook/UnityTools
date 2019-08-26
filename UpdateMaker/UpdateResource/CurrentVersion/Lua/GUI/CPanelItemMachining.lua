
------------------------lidaming-----------------------

local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local EMachingType = require "PB.net".EMachingType
local CPanelItemMachining = Lplus.Extend(CPanelBase, 'CPanelItemMachining')
local def = CPanelItemMachining.define
local EMachingOptType = require "PB.net".EMachingOptType
 
def.field('userdata')._Lab_Title = nil
def.field('userdata')._Lab_Describe = nil
def.field('userdata')._Lab_InputNum = nil
def.field('userdata')._Lab_CostNumber = nil
def.field('userdata')._Img_Money = nil

def.field("table")._SelectedItem = nil
def.field("boolean")._IsCompose = true   -- 合成 / 分解

-- local btn_max = nil
local btn_up = nil
local btn_down = nil
local btn_ensure = nil

local CostItemNum = 1           --消耗的物品数量
local input_ProcessCount = 1    --合成/消耗数量
local CostNum = 1               --需要的金钱数量
local CostOneNeedNum = 0        --合成/消耗一个所需要的数量
local CostOneNeedMoney = 0      --合成/消耗一个所需要的钱数
local BagItemCount = 0          --背包中当前物品的数量
local HostplayGoldNum = 0       --当前玩家的金币数量
local IsMax = true              --是否可以获得最大加工数量
local IsshowBtn = 0             --显示对应的btn

local itemTemplate = nil        --当前物品的模板数据
local itemName = ""             --物品品质颜色

local IsFirstOpen = false       --初次进入物品加工界面

local instance = nil
def.static('=>', CPanelItemMachining).Instance = function ()
	if not instance then
        instance = CPanelItemMachining()
        instance._PrefabPath = PATH.Panel_ItemMachining
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        -- instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._Lab_Title = self:GetUIObject('Lab_Title')
    self._Lab_Describe = self:GetUIObject('Lab_Describe')
    self._Lab_InputNum = self:GetUIObject('Label_Number')
    self._Lab_CostNumber = self:GetUIObject('Lab_CostNumber')
    self._Img_Money = self:GetUIObject('Img_Gold')

    btn_up = self:GetUIObject('Btn_Up')
    btn_down = self:GetUIObject('Btn_Down')
    -- btn_max = self:GetUIObject('Btn_Max')
    btn_ensure = self:GetUIObject('Btn_Ensure')
end

def.override("dynamic").OnData = function(self, data)
    self._SelectedItem = data.item_data
    self._IsCompose = data.cost_type
    if self._IsCompose == true then --修改标题
        GUI.SetText(self._Lab_Title, StringTable.Get(19504))
    else
        GUI.SetText(self._Lab_Title, StringTable.Get(19505))
    end    

    local normalPack = game._HostPlayer._Package._NormalPack
    BagItemCount = normalPack:GetItemCount(self._SelectedItem._Tid)
    HostplayGoldNum = game._HostPlayer._Package._GoldCoinCount

    itemTemplate = self._SelectedItem._Template
    itemName = "<color=#" .. EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality] ..">" .. self._SelectedItem._Name .."</color>"
    input_ProcessCount = 1
    IsFirstOpen = true
    IsMax = true
    self:InitProcessPanel()
end

def.method().InitProcessPanel = function(self)
    local descStr = ""   
    if self._SelectedItem:CanCompose() and self._IsCompose == true then --合成
        local template_processItem = CElementData.GetTemplate("ItemMachining", itemTemplate.ComposeId)
        local ComposeNum = template_processItem.DestCount
        local ComposeTid = template_processItem.DestItemData.DestItems[1].ItemId
        local ComposeItemTemplate = CElementData.GetTemplate("Item", ComposeTid)
        CostOneNeedNum = template_processItem.SrcItemData.SrcItems[1].ItemCount   --合成一个需要消耗的物品数量
        CostOneNeedMoney = template_processItem.MoneyNum    --合成一个需要消耗的钱数   
        local ComposeName = "<color=#" .. EnumDef.Quality2ColorHexStr[ComposeItemTemplate.InitQuality] ..">"..ComposeItemTemplate.Name .."</color>"    --合成的物品
        if input_ProcessCount == 0 then
            CostItemNum = CostOneNeedNum
            ComposeNum = 1
        else
            CostItemNum = CostOneNeedNum * input_ProcessCount     --一共需要消耗的物品数量
            ComposeNum = template_processItem.DestCount * input_ProcessCount
        end  
        local CostItemNumStr = CostItemNum
        if CostItemNum > BagItemCount then      --一共消耗的物品数量大于玩家背包中的物品数量显示红色,并且置灰确定按钮，否则显示白色
            CostItemNumStr = "<color=#FF0000>"..CostItemNumStr.."</color>"
            IsshowBtn = 7
            if IsFirstOpen then
                input_ProcessCount = 0
            end
        else
            CostItemNumStr = "<color=#FFFFFF>"..CostItemNumStr.."</color>"
            if IsFirstOpen then  
                if (BagItemCount - (CostItemNum + CostOneNeedNum )) < 0 
                or (HostplayGoldNum - (CostNum + CostOneNeedMoney)) < 0 then           
                    IsshowBtn = 8
                else
                    IsshowBtn = 9
                end  
            else    
                IsshowBtn = 4
            end       
        end   
        descStr = string.format(StringTable.Get(19500),CostItemNumStr,itemName,ComposeNum,ComposeName)
        GUITools.SetTokenMoneyIcon(self._Img_Money, template_processItem.MoneyId)

    elseif self._SelectedItem:CanDecompose() and self._IsCompose == false then --分解
        local template_processItem = CElementData.GetTemplate("ItemMachining", itemTemplate.DecomposeId)  
        CostOneNeedNum = template_processItem.SrcItemData.SrcItems[1].ItemCount  --分解一个需要消耗的物品数量
        CostOneNeedMoney = template_processItem.MoneyNum    --分解一个需要消耗的钱数
        if input_ProcessCount == 0 then
            CostItemNum = CostOneNeedNum
        else
            CostItemNum = CostOneNeedNum * input_ProcessCount   --一共需要消耗的物品数量
        end      
        local CostItemNumStr = CostItemNum
        if CostItemNum > BagItemCount then      --一共消耗的物品数量大于玩家背包中的物品数量显示红色,并且置灰确定按钮，否则显示白色
            CostItemNumStr = "<color=#FF0000>"..CostItemNumStr.."</color>"
            IsshowBtn = 7
            if IsFirstOpen then
                input_ProcessCount = 0
            end
        else
            CostItemNumStr = "<color=#FFFFFF>"..CostItemNumStr.."</color>"
            if IsFirstOpen then  
                if (BagItemCount - (CostItemNum + CostOneNeedNum )) < 0 
                or (HostplayGoldNum - (CostNum + CostOneNeedMoney)) < 0 then           
                    IsshowBtn = 8
                else
                    IsshowBtn = 9
                end  
            else    
                IsshowBtn = 4
            end
        end
        descStr = string.format(StringTable.Get(19501),CostItemNumStr,itemName)
        GUITools.SetTokenMoneyIcon(self._Img_Money, template_processItem.MoneyId)
    end

    if input_ProcessCount == 0 then
        CostNum = CostOneNeedMoney
    else
        CostNum = CostOneNeedMoney * input_ProcessCount  --一共需要消耗的钱数
    end
    
    local CostNumStr = CostNum
    if IsshowBtn ~= 7 then
        if CostNum > HostplayGoldNum then     --一共消耗的钱数大于玩家所有的钱数显示红色,并且置灰确定按钮，否则显示白色  
            CostNumStr = "<color=#FF0000>"..CostNumStr.."</color>"
            IsshowBtn = 7
            if IsFirstOpen then
                input_ProcessCount = 0
            end
        elseif CostNum <= HostplayGoldNum then 
            CostNumStr = "<color=#FFFFFF>"..CostNumStr.."</color>"
            if IsFirstOpen then  
                if (BagItemCount - (CostItemNum + CostOneNeedNum )) < 0 
                or (HostplayGoldNum - (CostNum + CostOneNeedMoney)) < 0 then           
                    IsshowBtn = 8
                else
                    IsshowBtn = 9
                end  
            else    
                IsshowBtn = 4
            end
        end
    else
        if CostNum > HostplayGoldNum then     --一共消耗的钱数大于玩家所有的钱数显示红色,并且置灰确定按钮，否则显示白色  
            CostNumStr = "<color=#FF0000>"..CostNumStr.."</color>"
        elseif CostNum <= HostplayGoldNum then 
            CostNumStr = "<color=#FFFFFF>"..CostNumStr.."</color>"
        end
    end

    if CostNum == 0 then
        self:GetUIObject('Frame_Cost'):SetActive(false)
    else
        self:GetUIObject('Frame_Cost'):SetActive(true)        
    end
    IsFirstOpen = false
    self:IsShowBtn(IsshowBtn)
    GUI.SetText(self._Lab_CostNumber, CostNumStr)
    GUI.SetText(self._Lab_Describe, descStr)  --物品加工描述       
    GUI.SetText(self._Lab_InputNum, tostring(input_ProcessCount))
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Ensure' then
        local machiningId = 0
        local template = self._SelectedItem._Template
        if self._SelectedItem:CanCompose() and self._IsCompose == true then --合成
            machiningId = template.ComposeId
            if machiningId ~= 0 and input_ProcessCount ~= 0 then
                local C2SItemMachining = require "PB.net".C2SItemMachining
                local protocol = C2SItemMachining()
                protocol.ItemMachiningId = machiningId   --物品加工ID
                protocol.Count = input_ProcessCount                       --加工数量  先默认为1
                protocol.MachingType = EMachingType.EMachingType_Normal
                protocol.MachingOptType = EMachingOptType.EMachingOptType_Compose
                PBHelper.Send(protocol)
            end
        elseif self._SelectedItem:CanDecompose() and self._IsCompose == false then --分解
            machiningId = template.DecomposeId
            local callback = function(val)
    			if val then       												
					if machiningId ~= 0 and input_ProcessCount ~= 0 then                        
                        local C2SItemMachining = require "PB.net".C2SItemMachining
                        local protocol = C2SItemMachining()
                        protocol.ItemMachiningId = machiningId   --物品加工ID
                        protocol.Count = input_ProcessCount         --加工数量  先默认为1
                        protocol.MachingType = EMachingType.EMachingType_Normal                     --物品加工类型
                        protocol.Slot = self._SelectedItem._Slot
                        protocol.MachingOptType = EMachingOptType.EMachingOptType_Decompose
                        PBHelper.Send(protocol)
                        if CPanelItemMachining.Instance():IsShow() then
                            CPanelItemMachining.Instance():Close()
                        end
                    end								
    			end
    		end
            if self._SelectedItem._Quality >= 3 then    -- 3代表紫色。紫色以上品质的物品分解需要msgBox提示
                local title, msg, closeType = StringTable.GetMsg(14)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
            else
                 callback(true)
            end
             
        else
            warn("COMPOSE ERRPR!!!")
        end           
        if CPanelItemMachining.Instance():IsShow() then
            CPanelItemMachining.Instance():Close()
        end
    elseif id == 'Btn_Cancel' then
        if CPanelItemMachining.Instance():IsShow() then
            CPanelItemMachining.Instance():Close()
        end

    elseif id == 'Btn_Up'then  -- +
        -- (BagItemCount - (CostItemNum + CostOneNeedNum )) >= 0 and (HostplayGoldNum - (CostNum + CostOneNeedMoney)) >= 0
        --如果背包中的物品和金钱足够合成       
        if input_ProcessCount == 0 
           or (BagItemCount - (CostItemNum + CostOneNeedNum )) >= 0 
           or (HostplayGoldNum - (CostNum + CostOneNeedMoney)) >= 0 then  
            input_ProcessCount = input_ProcessCount + 1
            self:InitProcessPanel()
            IsshowBtn = 5
            self:IsShowBtn(IsshowBtn)
            GUI.SetText(self._Lab_InputNum, tostring(input_ProcessCount))  --初始数量为1
            if (BagItemCount - (CostItemNum + CostOneNeedNum )) < 0 
               or (HostplayGoldNum - (CostNum + CostOneNeedMoney)) < 0 then           
                IsshowBtn = 6
                self:IsShowBtn(IsshowBtn)
            end
        end
    elseif id == 'Btn_Down'then  -- 背包中的物品和金钱足够合成
        if input_ProcessCount > 1 then
            input_ProcessCount = input_ProcessCount - 1            
            self:InitProcessPanel()
            IsMax = true
            IsshowBtn = 1
            self:IsShowBtn(IsshowBtn)
            if input_ProcessCount == 1 then
                IsshowBtn = 2
                self:IsShowBtn(IsshowBtn)
            end
        end        
    -- elseif id == 'Btn_Max'then  --可以 合成/分解 最大值
    --     if IsMax == true then
    --         local CanComposeItemNum = math.floor(BagItemCount / CostOneNeedNum)
    --         local CanComposeGoldNum = math.floor(HostplayGoldNum / CostOneNeedMoney)
    --         if CanComposeItemNum > 0 and CanComposeGoldNum > 0 then
    --             if CanComposeItemNum <= CanComposeGoldNum then
    --                 input_ProcessCount = CanComposeItemNum
    --             elseif CanComposeGoldNum <= CanComposeItemNum then
    --                 input_ProcessCount = CanComposeGoldNum                          
    --             end
    --             self:InitProcessPanel()  
    --             IsMax = false
    --             IsshowBtn = 6
    --             self:IsShowBtn(IsshowBtn)

    --         end
    --     end
    end
end

--isshow
def.method("number").IsShowBtn = function(self,isshow)
    if isshow == 1 then
        GameUtil.SetButtonInteractable(btn_up, true)
        -- GameUtil.SetButtonInteractable(btn_max, true)
    elseif isshow == 2 then
        GameUtil.SetButtonInteractable(btn_down, false)
    elseif isshow == 3 then
        GameUtil.SetButtonInteractable(btn_up, false)
        -- GameUtil.SetButtonInteractable(btn_max, false)
        GameUtil.SetButtonInteractable(btn_ensure, false)
    elseif isshow == 4 then
        GameUtil.SetButtonInteractable(btn_up, true)
        -- GameUtil.SetButtonInteractable(btn_max, true)
        GameUtil.SetButtonInteractable(btn_ensure, true)
    elseif isshow == 5 then
        GameUtil.SetButtonInteractable(btn_down, true)
        GameUtil.SetButtonInteractable(btn_ensure, true)
    elseif isshow == 6 then
        GameUtil.SetButtonInteractable(btn_up, false)
        -- GameUtil.SetButtonInteractable(btn_max, false)
        GameUtil.SetButtonInteractable(btn_down, true)
    elseif isshow == 7 then
        GameUtil.SetButtonInteractable(btn_up, false)
        -- GameUtil.SetButtonInteractable(btn_max, false)
        GameUtil.SetButtonInteractable(btn_down, false)
        GameUtil.SetButtonInteractable(btn_ensure, false)
    elseif isshow == 8 then
        GameUtil.SetButtonInteractable(btn_down, false)
        GameUtil.SetButtonInteractable(btn_up, false)
        -- GameUtil.SetButtonInteractable(btn_max, false)
    elseif isshow == 9 then
        GameUtil.SetButtonInteractable(btn_down, false)
        GameUtil.SetButtonInteractable(btn_up, true)
        -- GameUtil.SetButtonInteractable(btn_max, true)
        GameUtil.SetButtonInteractable(btn_ensure, true)
    else
        warn("没有考虑到的情况")
        -- GameUtil.SetButtonInteractable(btn_up, false)
        -- GameUtil.SetButtonInteractable(btn_max, false)
        -- GameUtil.SetButtonInteractable(btn_down, false)
        -- GameUtil.SetButtonInteractable(btn_ensure, false)
    end
end

CPanelItemMachining.Commit()
return CPanelItemMachining