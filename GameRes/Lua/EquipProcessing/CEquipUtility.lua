local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CEquipUtility = Lplus.Class("CEquipUtility")
local CScoreCalcMan = require "Data.CScoreCalcMan"
local def = CEquipUtility.define

-- 重铸
def.static("number", "number").SendC2SItemRebuild = function(bagType, itemSlot)
	--warn("C2SItemRebuild")
	local C2SItemRebuild = require "PB.net".C2SItemRebuild
	local protocol = C2SItemRebuild()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	SendProtocol(protocol)
end

-- 重铸确认 放弃
def.static("number", "number", "boolean").SendC2SItemRebuildConfirm = function(bagType, itemSlot, bIsConfirm)
	--warn("C2SItemRebuildConfirm")
	local C2SItemRebuildConfirm = require "PB.net".C2SItemRebuildConfirm
	local protocol = C2SItemRebuildConfirm()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot
	protocol.IsConfirm = bIsConfirm

	SendProtocol(protocol)
end

-- 淬火
def.static("number", "number").SendC2SItemQuench = function(bagType, itemSlot)
	--warn("C2SItemQuench")
	local C2SItemQuench = require "PB.net".C2SItemQuench
	local protocol = C2SItemQuench()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	SendProtocol(protocol)
end

-- 突破
def.static("number", "number").SendC2SItemSurmount = function(bagType, itemSlot)
	--warn("C2SItemSurmount")
	local C2SItemSurmount = require "PB.net".C2SItemSurmount
	local protocol = C2SItemSurmount()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	SendProtocol(protocol)
end

-- 强化
def.static("number", "number", "table").SendC2SItemInforce = function(bagType, itemSlot, materialList)
	--warn("C2SItemInforce")
	local C2SItemInforce = require "PB.net".C2SItemInforce
	local protocol = C2SItemInforce()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	for i=1, #materialList do
		local materialInfo = materialList[i]
		if materialInfo.ItemData ~= nil and materialInfo.ItemData.ItemData ~= nil then
		    table.insert(protocol.MaterialIndexs, materialInfo.ItemData.ItemData._Slot)
		end
    end

 --    for i,v in ipairs(protocol.MaterialIndexs) do
 --    	warn(" MaterialIndexs = ", i,v)
 --    end
	-- warn("bagType = ", protocol.BagType)
	-- warn("Index = ", protocol.Index)
	-- warn("bagType = ", protocol.BagType)

	SendProtocol(protocol)
end

--精炼
def.static("number", "number").SendC2SItemRefine = function(bagType, itemSlot)
	--warn("C2SItemRefine")
	local C2SItemRefine = require "PB.net".C2SItemRefine
	local protocol = C2SItemRefine()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	SendProtocol(protocol)
end

--转换
def.static("number", "number").SendC2SItemTalentChange = function(bagType, itemSlot)
	--warn("C2SItemRefine")
	local C2SItemTalentChange = require "PB.net".C2SItemTalentChange
	local protocol = C2SItemTalentChange()
	
	protocol.BagType = bagType
	protocol.Index = itemSlot

	SendProtocol(protocol)
end

--继承
def.static("number", "number", "number", "number").SendC2SItemInherit = function(orignBagType, orignSlot, targetBagType, targetSlot)
	-- warn("C2SItemInherit")
	local C2SItemInherit = require "PB.net".C2SItemInherit
	local protocol = C2SItemInherit()
	
	protocol.SrcBagType = orignBagType
	protocol.SrcIndex = orignSlot
	protocol.DestBagType = targetBagType
	protocol.DestIndex = targetSlot
	protocol.IsPerfect = false

	SendProtocol(protocol)
end

--获取强化data的 逻辑调用     索引ID 规则：强化ID 强化等级 + 下一级
def.static("number", "number", "=>", "table").GetInforceInfoByLevel = function(tid, level)
    local InforceTemplate = CEquipUtility.GetInforceTemplate(tid)

    if InforceTemplate == nil then return nil end

    return InforceTemplate.InforceDatas[level] ~= nil and InforceTemplate.InforceDatas[level] or nil
end

--获取强化模板
def.static("number", "=>", "table").GetInforceTemplate = function(tid)
	local CElementData = require "Data.CElementData"
    local InforceTemplate = CElementData.GetEquipInforceInfoMap(tid)

    if InforceTemplate == nil then return nil end

    return InforceTemplate
end

-- --获取强化模板配置的 最大等级
-- def.static("number", "=>", "number").GetMaxInforceLevel = function(tid)
-- 	local iRet = 0
-- 	local InforceTemplate = CEquipUtility.GetInforceTemplate(tid)
--     if InforceTemplate ~= nil then
--     	-- pb结构 用#取个数不准确 需要循环一次记录
--     	for i,v in ipairs(InforceTemplate.InforceDatas) do
--     		iRet = i
--     	end
--     end

--     return iRet
-- end

def.static("number", "=>", "number").GetMaxInforceLevelByQuality = function(quility)
	local iRet = 0
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("MaxInforceLevelInfo")
	local infoList = string.split(str, "*")
	local retTable = {}

	for i=1, #infoList do
		local maxLv = tonumber(infoList[i])
		table.insert(retTable, maxLv)
	end
	return retTable[quility+1] or 0
end

--精炼材料
def.static('number', 'number', '=>', "table").GetRefineMaterialInfo = function(equipRefineTid, refineLevel)
	--warn("GetRefineMaterialInfo = ", equipRefineTid, refineLevel)
	local equipRefineData = CElementData.GetTemplate('EquipRefine', equipRefineTid)

	if equipRefineData == nil then return nil end

	local info = {}
	for i,refineData in ipairs(equipRefineData.RefineDatas) do
		local keyLevel = tostring(refineData.Level)
		info[keyLevel] = {}
		info[keyLevel].Rate = refineData.Rate
		info[keyLevel].Increase = refineData.FPropertyInc
		info[keyLevel].MoneyId = refineData.CostMoneyId
		info[keyLevel].MoneyNeed = refineData.CostMoneyCount
		info[keyLevel].MaterialId = refineData.CostItemId
		info[keyLevel].MaterialNeed = refineData.CostItemCount
	end

	local retMap = {}
	retMap.Old = nil
	retMap.New = nil

	local strCurLevel = tostring(refineLevel)
	if info[strCurLevel] == nil then
		info[strCurLevel] = { Increase = 0}
	end

	retMap.Old = info[strCurLevel]

	local strNextLevel = tostring(refineLevel+1)
	if info[strNextLevel] ~= nil then
		retMap.New = info[strNextLevel]
	end

	return retMap
end

--获取淬火data的 逻辑调用
def.static("number", "number", "=>", "table").GetQuenchInfoByLevel = function(tid, level)
    local QuenchTemplate = CEquipUtility.GetQuenchTemplate(tid)
    if QuenchTemplate == nil then return nil end
    
    return QuenchTemplate.QuenchDatas[level] ~= nil and QuenchTemplate.QuenchDatas[level] or nil
end

--获取淬火模板
def.static("number", "=>", "table").GetQuenchTemplate = function(tid)
	local CElementData = require "Data.CElementData"
    local QuenchTemplate = CElementData.GetTemplate("EquipQuench", tid)

    if QuenchTemplate == nil then return nil end

    return QuenchTemplate
end

--获取突破data的 逻辑调用
def.static("number", "number", "=>", "table").GetSurmountInfoByLevel = function(tid, level)
    local SurmountTemplate = CEquipUtility.GetSurmountTemplate(tid)

    if SurmountTemplate == nil then return nil end

    return SurmountTemplate.SurmountDatas[level] ~= nil and SurmountTemplate.SurmountDatas[level] or nil
end

--获取突破模板
def.static("number", "=>", "table").GetSurmountTemplate = function(tid)
	local CElementData = require "Data.CElementData"
    local SurmountTemplate = CElementData.GetTemplate("EquipSurmount", tid)

    if SurmountTemplate == nil then return nil end

    return SurmountTemplate
end

--获取强化石 data的 逻辑调用
def.static("number", "number", "=>", "table").GetStoneInforceInfoByLevel = function(tid, level)
    local StoneInforceTemplate = CEquipUtility.GetStoneInforceTemplate(tid)

    if StoneInforceTemplate == nil then return nil end

    return StoneInforceTemplate.InforceValueStructs[level] ~= nil and StoneInforceTemplate.InforceValueStructs[level] or nil
end

--获取强化石 模板
def.static("number", "=>", "table").GetStoneInforceTemplate = function(tid)
	local CElementData = require "Data.CElementData"
    local StoneInforceTemplate = CElementData.GetTemplate("StoneInforce", tid)

    if StoneInforceTemplate == nil then return nil end

    return StoneInforceTemplate
end

--获取当前选中的 itemData 数据
def.static('number' ,"=>", "table").GetEquipBySlot = function(equipSlot)    
    local hp = game._HostPlayer
    local itemSet = hp._Package._EquipPack._ItemSet
    local itemData = itemSet[equipSlot]

    if itemData == nil or itemData._Tid == 0 then return nil end
    return itemData
end

-- 计算淬火红点
def.static("number", "=>", "boolean").CalcEquipQuenchRedDotState = function(equipSlot)
	local itemData = CEquipUtility.GetEquipBySlot(equipSlot)
    if itemData == nil or itemData._Tid <= 0 then return false end
    if itemData:IsAttrAllMax() then	return false end

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local template = CEquipUtility.GetQuenchInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
    if template == nil then return false end
    
    local MaterialId = template.CostItemId
    local MaterialNeed = template.CostItemCount
    local MaterialHave = pack:GetItemCount( MaterialId )
    local MoneyId = template.CostMoneyId
    local MoneyNeed = template.CostMoneyCount
    local MoneyHave = hp:GetMoneyCountByType( MoneyId )

    -- 材料不足
    if MaterialNeed > MaterialHave then return false end

    -- 货币不足
    if MoneyNeed > MoneyHave then return false end
        
	return true
end

-- 计算突破红点
def.static("number", "=>", "boolean").CalcEquipSurmountRedDotState = function(equipSlot)
	local itemData = CEquipUtility.GetEquipBySlot(equipSlot)
    if itemData == nil or itemData._Tid <= 0 then return false end
    if itemData:IsAttrAllMax() == false then return false end

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    
    local template = CEquipUtility.GetSurmountInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
    if template == nil then return false end

    local MaterialId = template.CostItemId
    local MaterialNeed = template.CostItemCount
    local MaterialHave = pack:GetItemCount( MaterialId )
    local MoneyId = template.CostMoneyId
    local MoneyNeed = template.CostMoneyCount
    local MoneyHave = hp:GetMoneyCountByType( MoneyId )
    
    -- 材料不足
    if MaterialNeed > MaterialHave then return false end

    -- 货币不足
    if MoneyNeed > MoneyHave then return false end
        
	return true
end

-- 计算精炼红点
def.static("number", "=>", "boolean").CalcEquipRefineRedDotState = function(equipSlot)
	local itemData = CEquipUtility.GetEquipBySlot(equipSlot)
    if itemData == nil or itemData._Tid <= 0 then return false end
    if itemData:CanRefine() == false then return false end

    local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
    if materialInfo == nil or materialInfo.New == nil then return false end

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

	local MaterialId = materialInfo.New.MaterialId
    local MaterialNeed = materialInfo.New.MaterialNeed
    local MaterialHave = pack:GetItemCount(MaterialId)
    local MoneyId = materialInfo.New.MoneyId
    local MoneyNeed = materialInfo.New.MoneyNeed
    local MoneyHave = hp:GetMoneyCountByType( MoneyId )

    -- 材料不足
    if MaterialHave < MaterialNeed then return false end

    -- 货币不足
    if MoneyNeed > MoneyHave then return false end
        
	return true
end

--计算淬火功能页签，红点信息
def.static('=>', 'boolean').CalcEquipRefinePageRedDotState = function()
	local hp = game._HostPlayer
    local itemSet = hp._Package._EquipPack._ItemSet

    local bShowRedDot = false
    --八个equipSlot
    for equipSlot=1,8 do
		local equip = CEquipUtility.GetEquipBySlot(equipSlot)
		if equip ~= nil then
			if CEquipUtility.CalcEquipRefineRedDotState(equipSlot) then
		   		bShowRedDot = true
		   		break
		   	end
		end
	end

	return bShowRedDot
end

--计算重铸功能页签，红点信息 （淬火 or 突破）
def.static('=>', 'boolean').CalcEquipRecastPageRedDotState = function()
	local hp = game._HostPlayer
    local itemSet = hp._Package._EquipPack._ItemSet

    local bShowRedDot = false
    --八个equipSlot
    for equipSlot=1,8 do
		local equip = CEquipUtility.GetEquipBySlot(equipSlot)
		if equip ~= nil then
			if CEquipUtility.CalcEquipQuenchRedDotState(equipSlot) or
			   CEquipUtility.CalcEquipSurmountRedDotState(equipSlot) then
		   		bShowRedDot = true
		   		break
		   	end
		end
	end

	return bShowRedDot
end

--计算单装备整体 红点信息
def.static('number', '=>', 'boolean').CalcEquipRedDotState = function(equipSlot)
	-- 淬火
	if CEquipUtility.CalcEquipQuenchRedDotState(equipSlot) then return true end
	-- 突破
	if CEquipUtility.CalcEquipSurmountRedDotState(equipSlot) then return true end
	-- 精炼
	if CEquipUtility.CalcEquipRefineRedDotState(equipSlot) then return true end

	return false
end

--刷新红点显示
def.static().UpdateEquipRedDot = function()
	local ERedPointType = require "PB.data".ERedPointType
	local hp = game._HostPlayer
    local itemSet = hp._Package._EquipPack._ItemSet

    local bShowRedDot = false
    --八个equipSlot
    for equipSlot=1,8 do
		local equip = CEquipUtility.GetEquipBySlot(equipSlot)
		if equip ~= nil then
			if CEquipUtility.CalcEquipRedDotState(equipSlot) then
		   		bShowRedDot = true
		   		break
		   	end
		end
	end

	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Equip, bShowRedDot)
end

--获取 突破材料
def.static("table", "=>", "table").GetEquipSurmountNeedInfo = function(itemData)
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

	local surmountTemplate = CEquipUtility.GetSurmountInfoByLevel(itemData._SurmountTid, itemData:GetSurmountLevel())
    local MaterialId = surmountTemplate.CostItemId
    local MaterialNeed = surmountTemplate.CostItemCount
    local MaterialHave = pack:GetItemCount( MaterialId )

    local info = 
    {
    	MaterialId = MaterialId,
    	MaterialNeed = MaterialNeed,
    	MaterialHave = MaterialHave,
	}

    return info
end

--获取 淬火材料
def.static("table", "=>", "table").GetEquipQuenchNeedInfo = function(itemData)
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local quenchTemplate = CEquipUtility.GetQuenchInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
    local MaterialId = quenchTemplate.CostItemId
    local MaterialNeed = quenchTemplate.CostItemCount
    local MaterialHave = pack:GetItemCount( MaterialId )

    local info = 
    {
    	MaterialId = MaterialId,
    	MaterialNeed = MaterialNeed,
    	MaterialHave = MaterialHave,
	}

    return info
end

--获取 重铸材料
def.static("table", "=>", "table").GetEquipRecastNeedInfo = function(itemData)
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
    local MaterialId = recastTemplate.Item.ConsumePairs[1].ConsumeId
    local MaterialNeed = recastTemplate.Item.ConsumePairs[1].ConsumeCount
    local MaterialHave = pack:GetItemCount( MaterialId )

    local info = 
    {
    	MaterialId = MaterialId,
    	MaterialNeed = MaterialNeed,
    	MaterialHave = MaterialHave,
	}

    return info
end

--获取 重铸需要的金币
def.static("table", "=>", "table").GetEquipRecastMoneyNeedInfo = function(itemData)
    local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
    local hp = game._HostPlayer
    local moneyId = recastTemplate.Money.ConsumePairs[1].ConsumeId
    local moneyNeed = recastTemplate.Money.ConsumePairs[1].ConsumeCount

    return {moneyId,moneyNeed}
end

def.static("table", "=>", "table").CalcRecommendProperty = function(itemData)
	local attrLibrary = CElementData.GetEquipAttrInfoById( itemData._Template.AttachedPropertyGroupGeneratorId )
	local propertyCoefficient = itemData:GetPropertyCoefficient()
	local prof = game._HostPlayer._InfoData._Prof
	local RecommendCount = EnumDef.Quality2RecommendCount[itemData:GetQuality()]

	local propertyTable = {}
    for k,v in pairs(attrLibrary) do
    	local info = {}
        local item = {}

        local max = math.ceil(v.MaxValue * propertyCoefficient)
		max = math.clamp(max, 1, max)
        item.ID = v.FightPropertyId
        item.FightPropertyId = v.FightPropertyId
        item.Value = max

        item.Name = v.Name
        item.MaxValue = v.MaxValue
        item.MinValue = v.MinValue
        table.insert(info, item)
        item.Score = CScoreCalcMan.Instance():CalcEquipScore(prof, info)
        table.insert(propertyTable, item)
    end

    local function sortFunc(a,b)
    	return a.Score > b.Score
    end
    table.sort(propertyTable, sortFunc)

    local resultTable = {}
    for i,v in ipairs(propertyTable) do
    	--warn("Score----------",v.Name,v.Score)
    	if #resultTable >= RecommendCount and
    	   resultTable[#resultTable] ~= nil and
    	   resultTable[#resultTable].Score ~= v.Score then
    	   	break
    	end

    	table.insert(resultTable, v)
    end

    return resultTable
end



CEquipUtility.Commit()
return CEquipUtility