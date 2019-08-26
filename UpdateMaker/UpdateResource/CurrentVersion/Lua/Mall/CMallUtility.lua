local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local EResourceType = require "PB.data".EResourceType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local CMallUtility = Lplus.Class("CMallUtility")
local def = CMallUtility.define
local instance = nil

local mystery_shop_specialID = 902
local bag_cell_specialID = 567
local bag_cell_specialID1 = 565
local bag_cell_specialID2 = 566

def.static("=>", CMallUtility).Instance = function()
	if instance == nil then
		instance = CMallUtility()
	end
	return instance
end

-- 获得剩余时间的字符串
def.static("number", "=>", "string").GetRemainStringByEndTime = function(endTime)
    local remain_sec = math.max((endTime - GameUtil.GetServerTime())/1000, 0 )
    if remain_sec > 86400 then
        return GUITools.FormatTimeSpanFromSecondsAndDecimal(remain_sec, 0)
    else
        if remain_sec > 3600 then
            return GUITools.FormatTimeFromSecondsToZero(true, remain_sec)
        else
            return string.format(StringTable.Get(10634), GUITools.FormatTimeFromSecondsToZero(true, remain_sec))
        end
    end
end

-- 获得活动商品的剩余时间字符串
def.static("number", "=>", "string").GetActivityGoodsEndTime = function(endTime)
    local remain_sec = math.max((endTime - GameUtil.GetServerTime())/1000, 0 )
    if remain_sec > 86400 * 31 then
        return StringTable.Get(31080)
    elseif remain_sec > 86400 then
        return string.format(StringTable.Get(31078), math.ceil(remain_sec/86400))
    else
        if remain_sec > 3600 then
            return GUITools.FormatTimeFromSecondsToZero(true, remain_sec)
        else
            return string.format(StringTable.Get(10634), GUITools.FormatTimeFromSecondsToZero(true, remain_sec))
        end
    end
end

-- 获得月卡剩余时间
def.static("number", "=>", "string").GetRemainStringForMonthlyCard = function(endTime)
    local remain_sec = math.max((endTime - GameUtil.GetServerTime())/1000, 0 )
    if remain_sec > 86400 then
        local day = math.floor(remain_sec/86400)
        local hour = math.floor((remain_sec % 86400) / 3600)
        return string.format(StringTable.Get(708), day, hour)
    else
        return GUITools.FormatTimeFromSecondsToZero(true, remain_sec)
    end
end

-- 获得快速购买的模板
def.static("number", "boolean", "=>", "table").GetQuickBuyTemp = function(moneyID, isMoney)
    local IDs = CElementData.GetAllTid("QuickStore")
    if IDs == nil then return nil end
    local EItemType = require "PB.Template".QuickStore.EItemType
    for _,v in ipairs(IDs) do
        local temp = CElementData.GetTemplate("QuickStore", v)
        if isMoney then
            if temp.ItemType == EItemType.Resource and temp.GainId == moneyID then
                return temp
            end
        else
            if temp.ItemType == EItemType.Item and temp.GainId == moneyID then
                return temp
            end
        end
    end
    return nil
end

-- 根据消耗货币或者item的ID，获得快速购买的Tid
def.static("number", "boolean", "=>", "number").GetQuickBuyTid = function(moneyOrItemID, isMoney)
    local IDs = CElementData.GetAllTid("QuickStore")
    local EItemType = require "PB.Template".QuickStore.EItemType
    for k,v in ipairs(IDs) do
        local temp = CElementData.GetTemplate("QuickStore", v)
        if isMoney then
            if temp.ItemType == EItemType.Resource and temp.GainId == moneyOrItemID then
                return k
            end
        else
            if temp.ItemType == EItemType.Item and temp.GainId == moneyOrItemID then
                return k
            end
        end
    end
    return -1
end

-- 检查快速购买的外部条件并弹提示
def.static("table", "=>", "boolean").CheckQuickBuyExternalCondition = function(model)
    if model == nil then return true end
    -- 冒险生涯等级判断
    if model[EQuickBuyLimit.AdventureLevel] ~= nil and type(model[EQuickBuyLimit.AdventureLevel]) == "number" then
        if game._HostPlayer._InfoData._GloryLevel < model[EQuickBuyLimit.AdventureLevel] then
            local glory_gift_info = game._CWelfareMan:GetGloryGifts()
            if glory_gift_info ~= nil and glory_gift_info[model[EQuickBuyLimit.AdventureLevel]] ~= nil then
                game._GUIMan:ShowTipText(string.format(StringTable.Get(19491), glory_gift_info[model[EQuickBuyLimit.AdventureLevel]].Name), true)
            else
                game._GUIMan:ShowTipText(StringTable.Get(31041), false)
            end
            return false
        end
    end
    -- 声望条件判断
    if model[EQuickBuyLimit.ReputationType] ~= nil and model[EQuickBuyLimit.ReputationLevel] ~= nil and 
            type(model[EQuickBuyLimit.ReputationType]) == "number" and type(model[EQuickBuyLimit.ReputationLevel]) == "number" then
        local reps = game._CReputationMan:GetAllReputation()
        for k,v in pairs(reps) do
            if k == model[EQuickBuyLimit.ReputationType] then
                if v.Level < model[EQuickBuyLimit.ReputationLevel] then
                    game._GUIMan:ShowTipText(StringTable.Get(31041), false)
                    return false
                end
            end
        end
    end
    -- 角色等级判断
    if model[EQuickBuyLimit.RoleLevel] ~= nil and type(model[EQuickBuyLimit.RoleLevel]) == "number" then
        if game._HostPlayer._InfoData._Level < model[EQuickBuyLimit.RoleLevel] then
            game._GUIMan:ShowTipText(StringTable.Get(804), false)
            return false
        end
    end
    -- 功能解锁
    if model[EQuickBuyLimit.FunID] ~= nil and type(model[EQuickBuyLimit.FunID]) == "number" then
        if not game._CFunctionMan:IsUnlockByFunTid(model[EQuickBuyLimit.FunID]) then
            local fun_temp = CElementData.GetFunTemplate(model[EQuickBuyLimit.FunID])
            game._GUIMan:ShowTipText(string.format(StringTable.Get(31040), fun_temp.Name), false)
            return false
        end
    end
    -- 购买次数判断
    if model[EQuickBuyLimit.MaxBuyCount] ~= nil and model[EQuickBuyLimit.CurBuyCount] and
            type(model[EQuickBuyLimit.MaxBuyCount]) == "number" and type(model[EQuickBuyLimit.CurBuyCount]) == "number" then
        if model[EQuickBuyLimit.CurBuyCount] >= model[EQuickBuyLimit.MaxBuyCount] then
            game._GUIMan:ShowTipText(StringTable.Get(31104), false)
            return false
        end
    end
    -- 消耗材料及数量判断
    if model[EQuickBuyLimit.MatID] ~= nil and type(model[EQuickBuyLimit.MatID]) == "number" then
        local have_count = game._HostPlayer._Package._NormalPack:GetItemCount(model[EQuickBuyLimit.MatID])
        if have_count < model[EQuickBuyLimit.MatNeedCount] then
            local item_temp = CElementData.GetItemTemplate(model[EQuickBuyLimit.MatID])
            game._GUIMan:ShowTipText(string.format(StringTable.Get(893),item_temp.TextDisplayName),false)
            return false
        end
    end
    -- 宠物背包最大购买数量判断
    if model[EQuickBuyLimit.PetBagMaxSlotCount] ~= nil and model[EQuickBuyLimit.PetBagBuyCount] ~= nil and 
            type(model[EQuickBuyLimit.PetBagMaxSlotCount]) == "number" and type(model[EQuickBuyLimit.PetBagBuyCount]) == "number" then
        local petPackage = game._HostPlayer._PetPackage
        local cur_bag_count = petPackage:GetEffectSize()
        if cur_bag_count + model[EQuickBuyLimit.PetBagBuyCount] > model[EQuickBuyLimit.PetBagMaxSlotCount] then
            game._GUIMan:ShowTipText(StringTable.Get(31043), false)
            return false
        end
    end
    -- 主角背包格子数已满判断
    if model[EQuickBuyLimit.BagMaxSlotCount] ~= nil and model[EQuickBuyLimit.BagBuyCount] ~= nil and
            type(model[EQuickBuyLimit.BagMaxSlotCount]) == "number" and type(model[EQuickBuyLimit.BagBuyCount]) == "number" then
        local hp_package = game._HostPlayer._Package
        local cur_bag_count = hp_package._NormalPack._EffectSize
        if cur_bag_count + model[EQuickBuyLimit.BagBuyCount] > model[EQuickBuyLimit.BagMaxSlotCount] then
            game._GUIMan:ShowTipText(StringTable.Get(306), false)
            return false
        end
    end
    -- 运势最大刷新次数判断
    if model[EQuickBuyLimit.LuckRefMaxCount] ~= nil and type(model[EQuickBuyLimit.LuckRefMaxCount]) == "number" then
        local ref_count = game._CCalendarMan:GetLuckRefTime()
        if ref_count >= model[EQuickBuyLimit.LuckRefMaxCount] then
            game._GUIMan:ShowTipText(StringTable.Get(31803), false)
            return false
        end
    end
    return true
end

-- 所有的要兑换的货币或者物品都有快速兑换的模板
def.static("table", "=>", "boolean").IsAllQuickBuyHaveTemp = function(itemOrMoneyTable)
    for i,v in ipairs(itemOrMoneyTable) do
        local temp = CMallUtility.GetQuickBuyTemp(v.ID, v.IsMoney)
        if temp == nil then
            return false
        end
    end
    return true
end

-- ==================================CanBuyWhenNotEnough Start======================================
-- itemOrMoneyTable 必须是以下结构：
--[[
    local itemOrMoneyTable = {
        {ID = 1, Count = 2, IsMoney = true},
        {ID = 1, Count = 2, IsMoney = true},
    }
]]
def.static("table", "=>", "boolean").CanBuyWhenNotEnough = function(itemOrMoneyTable)
    --[[
        {  
            {MoneyID = 1, Count = 2},
            {MoneyID = 1, Count = 2},
        }
    ]]
    local pre_cost_money_table = {}

    local insert_to_table = function(ID, Count)
        --print("Count ", Count)
        local finded = false
        for i,v in ipairs(pre_cost_money_table) do
            --print("i,v ", i,v.MoneyID, v.Count )
            if v.MoneyID == ID then
                v.Count = v.Count + Count
                finded = true
            end
        end
        if not finded then
            local item = {}
            item.MoneyID = ID
            item.Count = Count
            pre_cost_money_table[#pre_cost_money_table + 1] = item
        end
    end

    local get_remain_count = function(moneyID)
        local remain_count = game._HostPlayer:GetMoneyCountByType(moneyID)
        for i,v in ipairs(pre_cost_money_table) do
            if v.MoneyID == moneyID then
                remain_count = remain_count - v.Count
            end
        end
        return remain_count
    end
    for i,v in ipairs(itemOrMoneyTable) do
        local lead_temp = CMallUtility.GetQuickBuyTemp(v.ID, v.IsMoney)
        if lead_temp ~= nil and v.Count ~= 0 then
            local need_break = false
            local need_time_count = math.ceil(v.Count/lead_temp.GainCount)
            local total_need_money_count = need_time_count * lead_temp.CostMoneyCount
            if lead_temp.CostMoneyId1 > 0 then
                local remain_count = get_remain_count(lead_temp.CostMoneyId1)
                if remain_count > 0 then
                    total_need_money_count = total_need_money_count - remain_count
                    if total_need_money_count <= 0 then
                        insert_to_table(lead_temp.CostMoneyId1, total_need_money_count + remain_count)
                        need_break = true
                    else
                        insert_to_table(lead_temp.CostMoneyId1, remain_count)
                    end
                end
            end
            
            if not need_break then
                if  lead_temp.CostMoneyId2 > 0 then
                    local remain_count = get_remain_count(lead_temp.CostMoneyId2)
                    if remain_count > 0 then
                        total_need_money_count = total_need_money_count - remain_count
                        if total_need_money_count <= 0 then
                            insert_to_table(lead_temp.CostMoneyId2, total_need_money_count + remain_count)
                            need_break = true
                        else
                            insert_to_table(lead_temp.CostMoneyId2, remain_count)
                        end
                    end
                end
                
                if not need_break then
                    if  lead_temp.CostMoneyId3 > 0 then
                        local remain_count = get_remain_count(lead_temp.CostMoneyId3)
                        if remain_count > 0 then
                            total_need_money_count = total_need_money_count - remain_count
                            if total_need_money_count <= 0 then
                                insert_to_table(lead_temp.CostMoneyId2, total_need_money_count + remain_count)
                            else
                                insert_to_table(lead_temp.CostMoneyId2, remain_count)
                            end
                        end
                    end

                    if total_need_money_count > 0 then
                        return false
                    end
                end
            end
        end
    end
    return true
end

--===================================GetQuickBuyNeedCostMoneyTable Start======================================
-- itemOrMoneyTable 必须是以下结构：
--[[
    local itemOrMoneyTable = {
        {ID = 1, Count = 2, IsMoney = true},
        {ID = 1, Count = 2, IsMoney = true},
    }
]]
-- 返回的table则以以下结构返回(返回的是需要消耗的货币信息)
--[[
    local return_table = {
        {MoneyID = 1, Count = 2},
        {MoneyID = 1, Count = 2},
    }
]]
def.static("table", "=>", "table").GetQuickBuyNeedCostMoneyTable = function(itemOrMoneyTable)
    local pre_cost_money_table = {}
    local insert_to_table = function(ID, Count)
        local finded = false
        for i,v in ipairs(pre_cost_money_table) do
            if v.MoneyID == ID then
                v.Count = v.Count + Count
                finded = true
            end
        end
        if not finded then
            local item = {}
            item.MoneyID = ID
            item.Count = Count
            pre_cost_money_table[#pre_cost_money_table + 1] = item
        end
    end

    local get_remain_count = function(moneyID)
        local remain_count = game._HostPlayer:GetMoneyCountByType(moneyID)
        for i,v in ipairs(pre_cost_money_table) do
            if v.MoneyID == moneyID then
                remain_count = remain_count - v.Count
            end
        end
        return remain_count
    end
    for i,v in ipairs(itemOrMoneyTable) do
        local lead_temp = CMallUtility.GetQuickBuyTemp(v.ID, v.IsMoney)
        if lead_temp ~= nil and v.Count ~= 0 then
            local need_break = false
            local last_money_id = 0
            local need_time_count = math.ceil(v.Count/lead_temp.GainCount)
            local total_need_money_count = need_time_count * lead_temp.CostMoneyCount
            if lead_temp.CostMoneyId1 > 0 then
                last_money_id = lead_temp.CostMoneyId1
                local remain_count = get_remain_count(lead_temp.CostMoneyId1)
                if remain_count > 0 then
                    total_need_money_count = total_need_money_count - remain_count
                    if total_need_money_count <= 0 then
                        insert_to_table(lead_temp.CostMoneyId1, total_need_money_count + remain_count)
                        need_break = true
                    else
                        insert_to_table(lead_temp.CostMoneyId1, remain_count)
                    end
                end
            end
            
            if not need_break then
                if  lead_temp.CostMoneyId2 > 0 then
                    last_money_id = lead_temp.CostMoneyId2
                    local remain_count = get_remain_count(lead_temp.CostMoneyId2)
                    if remain_count > 0 then
                        total_need_money_count = total_need_money_count - remain_count
                        if total_need_money_count <= 0 then
                            insert_to_table(lead_temp.CostMoneyId2, total_need_money_count + remain_count)
                            need_break = true
                        else
                            insert_to_table(lead_temp.CostMoneyId2, remain_count)
                        end
                    end
                end
                
                if not need_break then
                    if  lead_temp.CostMoneyId3 > 0 then
                        last_money_id = lead_temp.CostMoneyId3
                        local remain_count = get_remain_count(lead_temp.CostMoneyId3)
                        if remain_count > 0 then
                            total_need_money_count = total_need_money_count - remain_count
                            if total_need_money_count <= 0 then
                                insert_to_table(lead_temp.CostMoneyId2, total_need_money_count + remain_count)
                            else
                                insert_to_table(lead_temp.CostMoneyId2, remain_count)
                            end
                        end
                    end
                    if total_need_money_count > 0 then
                        insert_to_table(last_money_id, total_need_money_count)
                    end
                end
            end
        end
    end
    return pre_cost_money_table
end



-- 获得需要消耗的所有moneyID的ID
def.static("table", "=>", "table").GetCostMoneyIDs = function(itemOrMoneyTable)
    local money_ids = {}
    local is_have = function(id)
        for i,v in ipairs(money_ids) do
            if v == id then
                return true
            end
        end
        return false
    end
    for i,v in ipairs(itemOrMoneyTable) do
        local lead_temp = CMallUtility.GetQuickBuyTemp(v.ID, v.IsMoney)
        if lead_temp ~= nil then
            if not is_have(lead_temp.CostMoneyId1) and lead_temp.CostMoneyId1 > 0 then
                money_ids[#money_ids + 1] = lead_temp.CostMoneyId1
            end

            if not is_have(lead_temp.CostMoneyId2) and lead_temp.CostMoneyId2 > 0 then
                money_ids[#money_ids + 1] = lead_temp.CostMoneyId2
            end

            if not is_have(lead_temp.CostMoneyId3) and lead_temp.CostMoneyId3 > 0 then
                money_ids[#money_ids + 1] = lead_temp.CostMoneyId3
            end
        end
    end
    return money_ids
end

-- 掉落模板
local function getDropLibraryMoneyList(dropLibrary)
	local EDropItemType = require "PB.Template".DropLibrary.EDropItemType
	local temp = nil
	if type(dropLibrary) == "number" then
		temp = CElementData.GetTemplate("DropLibrary",dropLibrary)
	else
		temp = dropLibrary
	end

	if temp == nil then
		warn("the dropLibrary template data is nil.")
		return
	end
	local MoneyList = {}
    for i,v in ipairs(temp.DropMoneyExps.DropMoneyExps) do
        MoneyList[#MoneyList + 1] = v
    end
    for i,v in ipairs(temp.DropItems.DropItems) do
        if v.ItemType == EDropItemType.DROPGROUP then 
			local listData = getDropLibraryMoneyList(v.ItemId)
			for j,w in ipairs(listData) do
				MoneyList[#MoneyList+1] = w
			end
		end
	end
	return MoneyList
end

local function CheckProf(itemID)
    local item_temp = CElementData.GetItemTemplate(itemID)
    if item_temp == nil then
        return false
    end
    local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
    return profMask == bit.band(item_temp.ProfessionLimitMask, profMask)
end


-- 通过物品ID获得所有奖励列表（包括必得和随机获得）
def.static("number", "number", "=>", "table").GetItemsShowDataByItemID = function(itemID, count)
    local rewards = {}
    local item_temp = CElementData.GetItemTemplate(itemID)
    if item_temp == nil then
        return nil
    end
    local EItemType = require "PB.Template".Item.EItemType
    local EItemEventType = require "PB.data".EItemEventType
    if item_temp.ItemType == EItemType.TreasureBox and item_temp.EventType1 ~= nil and item_temp.EventType1 == EItemEventType.ItemEvent_OpenBox then
        local drup_ID = tonumber(item_temp.Type1Param1)
        if drup_ID > 0 then
            local drup_temp = CElementData.GetTemplate("DropRule", drup_ID)
            if drup_temp == nil then warn("彩票规则id配置错误,物品ID是：", itemID) return{} end
            for i,v in ipairs(drup_temp.DropLibWeights) do
                if v.DropLibId ~= nil and v.DropLibId > 0 then
                    local dorp_money = getDropLibraryMoneyList(v.DropLibId)
                    for i1, v1 in ipairs(dorp_money) do
                        if v1.Probability > 0 then
                            local data = {}
                            data.IsTokenMoney = true
                            data.Data = {}
                            data.Data.Id = v1.MoneyId
                            data.Data.Count = v1.DropMin
                            rewards[#rewards + 1] = data
                        end
                    end
                    local drop_weight = GUITools.GetDropLibraryItemList(v.DropLibId)
                    for i1, v1 in ipairs(drop_weight) do
                        if v1.Probability > 0 and CheckProf(v1.ItemId) then
                            local data = {}
                            data.IsTokenMoney = false
                            data.Data = {}
                            data.Data.Id = v1.ItemId
                            data.Data.Count = v1.MinNum
                            rewards[#rewards + 1] = data
                        end
                    end
                end
            end
        end
    else
        rewards = 
        {
            {   IsTokenMoney = false,
			    Data = 
			    {
				    Id = itemID, 
				    Count = count
			    }
            },
        }
    end
    return rewards
end

local InsertToSelfTable = function(selfTable, targetTable)
    if selfTable == nil or targetTable == nil then return end
    for _,v in ipairs(targetTable) do
        selfTable[#selfTable + 1] = v
    end
end

-- 根据金币ID和数量生成一个reward的结构
local GetMoneyItemsDataByMoneyID = function(moneyID, count)
    if moneyID <= 0 then return nil end
    return {
             {   IsTokenMoney = true,
				Data = 
				{
					Id = moneyID, 
					Count = count
				}
              }
            }
end

-- 根据赠送的物品ID和数量 以及 赠送的货币ID和数量，返回一个table
def.static("number", "number", "number", "number", "=>", "table").GetGiftItemsByGoodsData = function(giftItemID, giftItemCount, giftMoneyID, giftMoneyCount)
    local items = {}
    InsertToSelfTable(items, CMallUtility.GetItemsShowDataByItemID(giftItemID, giftItemCount))
    InsertToSelfTable(items, GetMoneyItemsDataByMoneyID(giftMoneyID, giftMoneyCount))
    return items
end

-- 通过物品ID获得必得奖励列表
def.static("number", "number", "=>", "table").GetNonRandomShowDataByItemID = function(itemID, count)
    local rewards = {}
    local item_temp = CElementData.GetItemTemplate(itemID)
    if item_temp == nil then
        return nil
    end
    local EItemType = require "PB.Template".Item.EItemType
    local EItemEventType = require "PB.data".EItemEventType
    if item_temp.ItemType == EItemType.TreasureBox and item_temp.EventType1 ~= nil and item_temp.EventType1 == EItemEventType.ItemEvent_OpenBox then
        local drup_ID = tonumber(item_temp.Type1Param1)
        if drup_ID > 0 then
            local drup_temp = CElementData.GetTemplate("DropRule", drup_ID)
            if drup_temp == nil then warn("彩票规则id配置错误,物品ID是：", itemID) return{} end
            for i,v in ipairs(drup_temp.DropLibWeights) do
                if v.DropLibId ~= nil and v.DropLibId > 0 then
                    local dorp_money = getDropLibraryMoneyList(v.DropLibId)
                    for i1, v1 in ipairs(dorp_money) do
                        if v1.Probability >= 10000 then
                            local data = {}
                            data.IsTokenMoney = true
                            data.Data = {}
                            data.Data.Id = v1.MoneyId
                            data.Data.Count = v1.DropMin
                            rewards[#rewards + 1] = data
                        end
                    end
                    local drop_weight = GUITools.GetDropLibraryItemList(v.DropLibId)
                    for i1, v1 in ipairs(drop_weight) do
                        if v1.Probability >= 10000 and CheckProf(v1.ItemId) then
                            local data = {}
                            data.IsTokenMoney = false
                            data.Data = {}
                            data.Data.Id = v1.ItemId
                            data.Data.Count = v1.MinNum
                            rewards[#rewards + 1] = data
                        end
                    end
                end
            end
        end
    else
        rewards = 
        {
            {   IsTokenMoney = false,
			    Data = 
			    {
				    Id = itemID, 
				    Count = count
			    }
            },
        }
    end
    return rewards
end

-- 通过物品ID随机获得奖励列表
def.static("number", "number", "=>", "table").GetRandomShowDataByItemID = function(itemID, count)
    local rewards = {}
    local item_temp = CElementData.GetItemTemplate(itemID)
    if item_temp == nil then
        return nil
    end
    local EItemType = require "PB.Template".Item.EItemType
    local EItemEventType = require "PB.data".EItemEventType
    if item_temp.ItemType == EItemType.TreasureBox and item_temp.EventType1 ~= nil and item_temp.EventType1 == EItemEventType.ItemEvent_OpenBox then
        local drup_ID = tonumber(item_temp.Type1Param1)
        if drup_ID > 0 then
            local drup_temp = CElementData.GetTemplate("DropRule", drup_ID)
            if drup_temp == nil then warn("彩票规则id配置错误,物品ID是：", itemID) return{} end
            for i,v in ipairs(drup_temp.DropLibWeights) do
                if v.DropLibId ~= nil and v.DropLibId > 0 then
                    local dorp_money = getDropLibraryMoneyList(v.DropLibId)
                    for i1, v1 in ipairs(dorp_money) do
                        if v1.Probability > 0 and v1.Probability < 10000 then
                            local data = {}
                            data.IsTokenMoney = true
                            data.Data = {}
                            data.Data.Id = v1.MoneyId
                            data.Data.Count = v1.DropMin
                            rewards[#rewards + 1] = data
                        end
                    end
                    local drop_weight = GUITools.GetDropLibraryItemList(v.DropLibId)
                    for i1, v1 in ipairs(drop_weight) do
                        if v1.Probability > 0 and v1.Probability < 10000 and CheckProf(v1.ItemId) then
                            local data = {}
                            data.IsTokenMoney = false
                            data.Data = {}
                            data.Data.Id = v1.ItemId
                            data.Data.Count = v1.MinNum
                            rewards[#rewards + 1] = data
                        end
                    end
                end
            end
        end
    else
        rewards = 
        {
            {   IsTokenMoney = false,
			    Data = 
			    {
				    Id = itemID, 
				    Count = count
			    }
            },
        }
    end
    return rewards
end


-- 获得神秘商店VIP格子数信息
def.static("=>", "table").GetMysteryShopVIPGridTable = function()
    local shop_tid = tonumber(CElementData.GetSpecialIdTemplate(mystery_shop_specialID).Value)
    if shop_tid == nil then return nil end
    local mystery_shop_temp = CElementData.GetTemplate("Store", shop_tid)
    if mystery_shop_temp.VipInc == nil then return nil end
    local grid_counts = string.split(mystery_shop_temp.VipInc, "*")
    local grid_info = {}
    for _,v in ipairs(grid_counts) do
        grid_info[#grid_info + 1] = tonumber(v)
    end
    return grid_info
end

-- 根据格子index找到能开启到这个index的第一个VIP等级
def.static("number", "=>", "number").GetVIPLevelByIndex = function(index)
    local gride_info = CMallUtility.GetMysteryShopVIPGridTable()
    local level = gride_info[#gride_info]
    for i,v in ipairs(gride_info) do
        if v >= index then
            level = i
            break
        end
    end
    return level
end

-- 商店活动是否结束
def.static("number", "=>", "boolean").IsStoreActiveEnd = function(endTime)
    if endTime > 0 then
        return GameUtil.GetServerTime() > endTime
    else
        return false
    end
end

-- 角色等级是否是在商品可购买等级的区间
def.static("number", "number", "=>", "boolean").IsRoleLevelGood = function(minLevel, maxLevel)
    if maxLevel <= 0 then return true end
    local self_level = game._HostPlayer._InfoData._Level
    if self_level >= minLevel and self_level <= maxLevel then 
        return true
    else
        return false
    end
end

-- 精灵献礼是否可以抽取
def.static("=>", "boolean").CanExtractElf = function()
    if not game._CFunctionMan:IsUnlockByFunTid(10) then
        return false
    end
    local DropRuleId = tonumber(CElementData.GetSpecialIdTemplate(441).Value)
    local elfUseDropRuleTemp = CElementData.GetTemplate("DropRule",DropRuleId)
    if elfUseDropRuleTemp == nil then
        warn("error !! CSummonPageElf.InitElfData 精灵献礼使用的掉落模板数据为空")
        return false
    end
    local flower_count = game._HostPlayer._Package._NormalPack:GetItemCount(elfUseDropRuleTemp.CostItemId2)
    local mat_count = game._HostPlayer._Package._NormalPack:GetItemCount(elfUseDropRuleTemp.CostItemId1)
    if flower_count >= elfUseDropRuleTemp.CostItemCount2 and mat_count >= elfUseDropRuleTemp.CostItemCount1 then
        return true
    else
        return false
    end
end

-- 背包购买格子算法（根据要买的格子数返回需要的钱）
def.static("number", "=>", "number").GetBagBuyCellTotalPrice = function(buyCount)
    local cell_param1 = tonumber(CElementData.GetSpecialIdTemplate(bag_cell_specialID1).Value)
    local cell_param2 = tonumber(CElementData.GetSpecialIdTemplate(bag_cell_specialID2).Value)
    local free_cell_num = tonumber(CElementData.GetSpecialIdTemplate(bag_cell_specialID).Value)
    local count = game._HostPlayer._Package._NormalPack._EffectSize
    local total  = 0
    for i = 1,buyCount do
        local price = cell_param1 + math.floor((count + i - free_cell_num) / 5) * cell_param2
        total = total + price
    end
    return total
end

-- 根据配置的万分比数字获得一个 “**%”的字符串
def.static("number", "=>", "string").GetPercentString = function(percent)
    local result = percent/100
    return string.format(StringTable.Get(31044), result)
end

def.static("number", "=>", "boolean").IsCanUseItem = function(itemID)
    local itemData = CElementData.GetItemTemplate(itemID)
    local prof = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
    if itemData.MaxLevelLimit < game._HostPlayer._InfoData._Level then 
        return false
    else
        if prof == bit.band(itemData.ProfessionLimitMask, prof) then 
            local Gender = require "PB.data".Gender
            if itemData.GenderLimitMask == game._HostPlayer._InfoData._Gender or itemData.GenderLimitMask == Gender.BOTH then 
                return true 
            else
                return false
            end 
        else
            return false
        end
    end
end

-- 获得商品的名字
def.static("number", "=>", "string").GetGoodsItemName = function(goodsID)
    local goods_temp = CElementData.GetTemplate("Goods", goodsID)
    if goods_temp ~= nil then
        if goods_temp.GoodsType == EGoodsType.Item then
            local itemTemplate = CElementData.GetItemTemplate(goods_temp.ItemId)
            return "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..goods_temp.Name.."</color>"
        else
            return goods_temp.Name
        end
    end
    return ""
end

-- 获得物品的名字
def.static("number", "=>", "string").GetItemName = function(itemID)
    local item_temp = CElementData.GetItemTemplate(itemID)
    if item_temp ~= nil then
        return "<color=#"..EnumDef.Quality2ColorHexStr[item_temp.InitQuality]..">"..item_temp.TextDisplayName.."</color>"
    end
    return ""
end

-- 是否跳过动画(id对应LocalFields)
def.static("string", "=>", "boolean").IsShowGfx = function(defID)
    local account = game._NetMan._UserName
    local UserData = require "Data.UserData"
    local cfg = UserData.Instance():GetCfg(defID, account)
    if cfg == nil then
        return true
    else
        return cfg
    end
end

-- 设置是否跳过动画的偏好
def.static("string", "boolean").SetShowGfx = function(defID, bShow)
    --print("SetShowGfx ", defID, bShow)
    local oldShow = CMallUtility.IsShowGfx(defID)
    if oldShow == bShow then
        --print("怎么会被return")
        return
    end
    local account = game._NetMan._UserName
    local UserData = require "Data.UserData"
    UserData.Instance():SetCfg(defID, account, bShow)
end

CMallUtility.Commit()
return CMallUtility