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
    local IDs = GameUtil.GetAllTid("QuickStore")
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
    local IDs = GameUtil.GetAllTid("QuickStore")
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

-- 当对应货币不足的时候，判断能不能买（走引导购买逻辑）
def.static("number", "boolean", "number", "=>", "boolean").CanBuyWhenNotEnough = function(itemOrMoneyID, isMoney, count)
    local lead_temp = CMallUtility.GetQuickBuyTemp(itemOrMoneyID,isMoney)
    if lead_temp ~= nil then
        local have_count = 0
        if isMoney then
            have_count = game._HostPlayer:GetMoneyCountByType(itemOrMoneyID)
        else
            have_count = game._HostPlayer._Package._NormalPack:GetItemCount(itemOrMoneyID)
        end
        local have_money1 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId1)
        local have_money2 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId2)
        local have_money3 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId3)
        local change_count = math.ceil((have_money1 + have_money2 + have_money3)/lead_temp.CostMoneyCount)
        if change_count * lead_temp.GainCount + have_count >= count then
            return true
        end
    else
        warn("没有这个快速购买的ID：", itemOrMoneyID)
    end
    return false
end

-- 通过要花费的货币ID得到最大能购买的数量
def.static("number", "number", "=>", "number").GetCanBuyMaxCountByMoneyID = function(moneyID, price)
    local lead_temp = CMallUtility.GetQuickBuyTemp(moneyID,true)
    local have_money0 = game._HostPlayer:GetMoneyCountByType(moneyID)
    if lead_temp ~= nil then
        local have_money1 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId1)
        local have_money2 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId2)
        local have_money3 = game._HostPlayer:GetMoneyCountByType(lead_temp.CostMoneyId3)
        local change_count = math.floor((have_money1 + have_money2 + have_money3)/lead_temp.CostMoneyCount)
        return math.floor((change_count * lead_temp.GainCount + have_money0)/price)
    else
        local count = math.floor(have_money0/price)
        if count == 0 then
            return 1
        else
            return count
        end
    end
end

-- 通过物品ID获得奖励列表
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
            if drup_temp == nil then warn("彩票规则id配置错误,物品ID是：", itemID) return end
            local reward = GUITools.GetRewardList(drup_temp.DescRewardid, true)
            if reward == nil then return end
            for k,v in ipairs(reward) do
                v.Data.Count = v.Data.Count * count
                table.insert(rewards, v)
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
        warn("error !! CMallPageElf.InitElfData 精灵献礼使用的掉落模板数据为空")
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

CMallUtility.Commit()
return CMallUtility