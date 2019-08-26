local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPetClass = require "Pet.CPetClass"

local CPetUtility = Lplus.Class("CPetUtility")
local def = CPetUtility.define

local MaxAptitudeCount = 5      --资质最大个数
local MaxPropertyCount = 5      --属性最大个数
local MaxSkillCount = 6         --技能最大个数

-- 人物显示属性 与 附加属性 转换对照表
local ExchangeIDInfo = 
{
	["11"] = 69,	-- 生命
	["19"] = 10,	-- 攻击
	["21"] = 11,	-- 防御
	["3"] = 2,		-- 力量
	["5"] = 3,		-- 敏捷
	["7"] = 4,		-- 智慧
	["23"] = 12,	-- 光
	["25"] = 13,	-- 火
	["27"] = 14,	-- 雷
	["29"] = 15,	-- 冰
	["31"] = 16,	-- 风
	["33"] = 17,	-- 暗
}

def.static("number", "=>", "number").ExchangeToPropertyTipsID = function(id)
	local key = tostring(id)
	return ExchangeIDInfo[key]
end

def.static("=>", "number").GetMaxAptitudeCount = function()
	return MaxAptitudeCount
end
def.static("=>", "number").GetMaxPropertyCount = function()
	return MaxPropertyCount
end
def.static("=>", "number").GetMaxSkillCount = function()
	return MaxSkillCount
end
def.static("=>", "table").GetPetSkillUnlockInfo = function()
	local retTable = {}
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetSkillUnlockInfo")
	local infoList = string.split(str, "*")

	for i=1, #infoList do
		table.insert(retTable, tonumber(infoList[i]))
	end

	return retTable
end
def.static("=>", "table").GetPetSkillTakeOffCostInfo = function()
	local retTable = {}
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetSkillTakeOffCostInfo")
	local infoList = string.split(str, "*")

	for i=1, #infoList do
		if i > 1 then
			local data = 
			{
				tonumber(infoList[1]),
				tonumber(infoList[i]),
			}
			table.insert(retTable, data)
		end
	end

	return retTable
end
def.static("=>", "number").GetPetFuseAptitudeAddRatio = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetFuseAptitudeAddRatio")
	return tonumber(str)
end
def.static("=>", "number").GetPetHelpAddPropertyRatio = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetHelpAddPropertyRatio")
	return tonumber(str)
end
def.static("=>", "number").GetPetFightAddPropertyRatio = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetFightAddPropertyRatio")
	return tonumber(str)
end
def.static("=>", "table").GetPetResetRecastCountItem = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetResetRecastCountItem")
	local infoList = string.split(str, "*")
	return {tonumber(infoList[1]), tonumber(infoList[2])}
end
def.static("=>", "table").GetPetUnlockHelpCellInfo = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetUnlockHelpCellInfo")
	local infoList = string.split(str, "*")
	return {tonumber(infoList[1]), tonumber(infoList[2])}
end
def.static("=>", "number").GetMaxPetStage = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetMaxStage")
	return tonumber(str)
end
def.static("=>", "number").GetMaxPetTalentLevel = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("MaxPetTalentLevel")
	return tonumber(str)
end

def.static("=>", "table").GetRecastNeedInfo = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetRecastNeedInfo")
	local infoList = string.split(str, "*")

	if #infoList ~= 2 then return nil end

	return {tonumber(infoList[1]), tonumber(infoList[2])}
end
def.static("=>", "table").GetAdvanceLvLimitInfo = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetAdvanceLvLimitInfo")
	local infoList = string.split(str, "*")
	local retTable = {}

	table.insert(retTable, 0)
	for i=1, #infoList do
		local limitValue = tonumber(infoList[i])
		table.insert(retTable, limitValue)
	end

	return retTable
end
def.static("=>", "table").GetPetAptitudeIncFixCoefficient = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetAptitudeIncFixCoefficient")
	local infoList = string.split(str, "*")
	local retTable = {}

	for i=1, #infoList do
		local info = string.split(infoList[i], "#")
		retTable[tonumber(info[1])] = tonumber(info[2])
	end

	return retTable
end
def.static("number", "=>", "number").GetPetAptitudeIncFixCoefficientById = function(id)
	local infoList = CPetUtility.GetPetAptitudeIncFixCoefficient()
	return infoList[id] or 1
end

def.static("number", "=>", "number").GetCoefficientByStage = function(stage)
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetAdvanceCoefficient")
    local advanceCoefficientList = string.split(str, "*")

    if advanceCoefficientList[stage] == nil then return nil end

	return tonumber(advanceCoefficientList[stage])
end

def.static("=>", "table").GetUnlockPriceInfo = function()
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetUnlockCellPrice")
    local infoList = string.split(str, "*")
    if #infoList ~= 2 then return nil end

    return {tonumber(infoList[1]), tonumber(infoList[2])}
end 

-- --宠物升阶
-- def.static("number", "number").SendC2SPetAdvance = function(petIdMain, petIdMaterial)
-- 	--warn("C2SPetAdvance")
-- 	local C2SPetAdvance = require "PB.net".C2SPetAdvance
-- 	local protocol = C2SPetAdvance()
	
-- 	protocol.petIdMain = petIdMain
-- 	protocol.petIdMaterial = petIdMaterial

-- 	SendProtocol(protocol)
-- end

--宠物升星
def.static("number", "number").SendC2SPetStarUp = function(petIdMain, petIdMaterial)
	--warn("C2SPetStarUp")
	local C2SPetStarUp = require "PB.net".C2SPetStarUp
	local protocol = C2SPetStarUp()
	
	protocol.petIdMain = petIdMain
	protocol.petIdMaterial = petIdMaterial

	SendProtocol(protocol)
end

--宠物融合
def.static("number", "table").SendC2SPetFuse = function(petIdMain, list)
	-- warn("C2SPetFuse")
	local C2SPetFuse = require "PB.net".C2SPetFuse
	local protocol = C2SPetFuse()
	
	protocol.petIdMain = petIdMain
	for _, petId in ipairs(list) do
		table.insert(protocol.petIdMaterials, petId)
	end

	SendProtocol(protocol)
end

--宠物重铸
def.static("number", "number").SendC2SPetRecast = function(petId, aptitudeId)
	local C2SPetRecast = require "PB.net".C2SPetRecast
    local protocol = C2SPetRecast()

    protocol.petId = petId
    protocol.aptitudeId = aptitudeId
    
    SendProtocol( protocol )
end
--宠物重铸确认
def.static("number").SendC2SPetConfirmRecast = function(petId)
	local C2SPetConfirmRecast = require "PB.net".C2SPetConfirmRecast
    local protocol = C2SPetConfirmRecast()

    protocol.petId = petId
    
    SendProtocol( protocol )
end
--宠物升级
def.static("number", "number", "number").SendC2SPetLevelUp = function(petId, medicineTid, count)
	--warn("SendC2SPetLevelUp")
	local C2SPetLevelUp = require "PB.net".C2SPetLevelUp
    local protocol = C2SPetLevelUp()

    protocol.petId = petId
    protocol.itemTId = medicineTid
    protocol.itemCount = count

    SendProtocol( protocol )
end
--宠物出战
def.static("number", "number").SendC2SPetFighting = function(petId, cellIndex)
	--warn("SendC2SPetFighting")
	local C2SPetFighting = require "PB.net".C2SPetFighting
	local protocol = C2SPetFighting()
	
	protocol.petId = petId
	protocol.cellIndex = cellIndex

	SendProtocol(protocol)
end
--宠物助战
def.static("number", "number").SendC2SPetHelpFighting = function(petId, cellIndex)
	--warn("C2SPetHelpFighting", petId, cellIndex)
	local C2SPetHelpFighting = require "PB.net".C2SPetHelpFighting
	local protocol = C2SPetHelpFighting()
	
	protocol.petId = petId
	protocol.cellIndex = cellIndex

	SendProtocol(protocol)
end
--宠物休息
def.static("number").SendC2SPetRest = function(petId)
	local C2SPetRest = require "PB.net".C2SPetRest
	local protocol = C2SPetRest()
	
	protocol.petId = petId

	SendProtocol(protocol)
end
--宠物放生
def.static("number").SendC2SPetSetFree = function(petId)
	local C2SPetSetFree = require "PB.net".C2SPetSetFree
	local protocol = C2SPetSetFree()
	
	protocol.petId = petId

	SendProtocol(protocol)
end
--被动技能学习
def.static("number", "number", "number").SendC2SPetLearnTalent = function(petId, itemTid, skillIndex)
	--warn("SendC2SPetLearnTalent")
	local C2SPetLearnTalent = require "PB.net".C2SPetLearnTalent
	local protocol = C2SPetLearnTalent()
	
	protocol.petId = petId
	protocol.itemTId = itemTid
	protocol.slotIndex = skillIndex

	SendProtocol(protocol)
end
--被动技能 拆除
def.static("number", "number").SendC2SPetTakedownTalent = function(petId, skillIndex)
	--warn("SendC2SPetTakedownTalent")
	local C2SPetTakedownTalent = require "PB.net".C2SPetTakedownTalent
	local protocol = C2SPetTakedownTalent()
	
	protocol.petId = petId
	protocol.slotIndex = skillIndex

	SendProtocol(protocol)
end

--格子解锁
def.static("number").SendC2SPetUnLockPetBag = function(index)
	local C2SPetUnLockPetBag = require "PB.net".C2SPetUnLockPetBag
	local protocol = C2SPetUnLockPetBag()
	protocol.number = index

	SendProtocol(protocol)
end
--重命名
def.static("number", "string").SendC2SPetReName = function(petId, name)
	--warn("SendC2SPetReName...", petId, name)
	local C2SPetReName = require "PB.net".C2SPetReName
	local protocol = C2SPetReName()
	protocol.petId = petId
	protocol.newName = name

	SendProtocol(protocol)
end
--重置 洗练个数
def.static("number").SendC2SPetResetRecastCount = function(petId)
	--warn("SendC2SPetResetRecastCount...", petId)
	local C2SPetResetRecastCount = require "PB.net".C2SPetResetRecastCount
	local protocol = C2SPetResetRecastCount()
	protocol.petId = petId

	SendProtocol(protocol)
end
--宠物自动出战助战
def.static().SendC2SPetAutoFighting = function()
	--warn("SendC2SPetAutoFighting...")
	local C2SPetAutoFighting = require "PB.net".C2SPetAutoFighting
	local protocol = C2SPetAutoFighting()

	SendProtocol(protocol)
end
-- 获取 宠物经验药 返还比例
def.static("=>", "number").GetPetExpRecycleRatio = function()
	local petExpRecycleRatio = CSpecialIdMan.Get("PetExpRecycleRatio")
	local result = tonumber(petExpRecycleRatio) / 10000

	return result
end
-- 获取培养经验药 id列表
def.static("=>", "table").GetPetExpMedicineList = function()
	local specialId = CSpecialIdMan.Get("PetExpMedicine")
    local ids = string.split(specialId, "*")
    
    local list = {}
    for i,v in ipairs(ids) do
        local tid = tonumber(v)
        table.insert(list, tid)
    end

    return list
end
-- 能否培养 不考虑材料
def.static(CPetClass, "=>", "boolean").CanCultivate = function(pet)
    if pet:IsMaxLevel() then return false end
    if pet:GetLevel() >= game._HostPlayer._InfoData._Level then return false end

    return true
end
-- 经验药是否存在
def.static('=>', "boolean").IsGotPetExpMedicine = function()
	local bRet = false
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local list = CPetUtility.GetPetExpMedicineList()
    for i,tid in ipairs(list) do
    	if pack:GetItem(tid) ~= nil then
    		bRet = true
    		break
    	end
    end

    return bRet
end
-- 宠物洗练材料是否存在
def.static('=>', "boolean").IsGotPetRecastMaterial = function()
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local RecastNeedInfo = CPetUtility.GetRecastNeedInfo()
    local MaterialHave = pack:GetItemCount(RecastNeedInfo[1])
    local MaterialNeed = RecastNeedInfo[2]

    return MaterialHave >= MaterialNeed
end

-- 能否进阶 不考虑材料
def.static(CPetClass, "=>", "boolean").CanAdvance = function(pet)
    if pet:IsMaxStage() then return false end
    return true
end
-- 升级用的宠物材料是否存在
def.static(CPetClass, '=>', "boolean").IsGotAdvancePetNeed = function(pet)
	local bRet = false
	local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local allPetList = petPackage:GetList()

    for i=1, #allPetList do
        local petElse = allPetList[i]
        
        --材料不能为出战 助战宠物
        if (hp:IsFightingPetById(petElse._ID) or hp:IsHelpingPetById(petElse._ID)) == false then
	        if pet._ID ~= petElse._ID and pet:GetStage() == petElse:GetStage() then
	            bRet = true
	            break
	        end
	    end
    end

    return bRet
end
-- 宠物技能书是否存在
def.static('=>', "boolean").IsGotPetTalentBook = function()
	local bRet = false
	local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    for i,itemData in ipairs(pack._ItemSet) do
    	if itemData:IsPetTalentBook() then
    		bRet = true
    		break
    	end
    end

    return bRet
end

def.static("number", "=>", "table").CalcRecycleMedicineList = function(totalExp)
	local retTable = {}
	local cookies = CPetUtility.GetPetExpMedicineList()
	local cookieList = {}
	for i,tid in ipairs(cookies) do
		local itemTemplate = CElementData.GetTemplate("Item", tid)
		local Medicine = {}
        Medicine.Tid = tid
        Medicine.Template = itemTemplate
        Medicine.AddExp = itemTemplate.PetItemExp
        table.insert(cookieList, Medicine)
	end
	table.sort(cookieList, function(a,b) return a.AddExp > b.AddExp end)

	local ratio = CPetUtility.GetPetExpRecycleRatio()
	local fixExp = totalExp * ratio

	for i,cookie in ipairs(cookieList) do
		local divisor = cookie.AddExp
		local count = math.floor(fixExp / divisor)
		fixExp = fixExp % divisor

		if count > 0 then
			local data = {}
			data.Count = count
			data.Tid = cookie.Tid
			data.Template = cookie.Template
			table.insert(retTable, data)
		end
	end

	return retTable
end

-- 计算返还饼干 & 精魄 table
def.static(CPetClass,"=>", "table").CalcRecycleList = function(pet)
	local retTable = {}
	local petMatItemID = 1026        -- 宠物碎片ID 为啥写死,暂时先这样。有需求灵活配置再行增加字段

	retTable = CPetUtility.CalcRecycleMedicineList(pet:CalcTotalExp())

	local matItemCount = pet:GetRecyclingPetDebris()
	if matItemCount > 0 then
		local itemTemplate = CElementData.GetTemplate("Item", petMatItemID)
		local petMatItemInfo = 
		{
			Count = pet:GetRecyclingPetDebris(),
			Tid = petMatItemID,
			Template = itemTemplate
		}
		table.insert(retTable, petMatItemInfo)
	end

	return retTable
end


def.static("=>", "table").CalcPropertyInfo = function()
	local resultTable = {}
	local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local fightPetId = hp:GetCurrentFightPetId()
	local pet = petPackage:GetPetById(fightPetId)

	local petList = hp:GetCurrentHelpPetList()
	local helpPetId1 = petList[1]
	local helpPetId2 = petList[2]

	-- 合并属性
	local function CallWholeProperty(propertyList)
		local resultTmp = {}
		for i, property in ipairs(resultTable) do
			if resultTmp[property.FightPropertyId] == nil then
				resultTmp[property.FightPropertyId] = property
			end
		end

		for i, propNew in ipairs(propertyList) do
			if resultTmp[propNew.FightPropertyId] == nil then
				resultTmp[propNew.FightPropertyId] = propNew
			else
				resultTmp[propNew.FightPropertyId].Value = resultTmp[propNew.FightPropertyId].Value + propNew.Value
			end
		end

		resultTable = {}
		for k, property in pairs(resultTmp) do
			property.Value = math.ceil(property.Value)
			table.insert(resultTable, property)
		end
	end
	-- 排序
	local sort_func = function(item1, item2)
        return item1.FightPropertyId < item2.FightPropertyId
    end

    if pet ~= nil then
	    local propertyClone = clone(pet._PropertyList)
	    CallWholeProperty(propertyClone)
    end
    local addRatio = CPetUtility.GetPetHelpAddPropertyRatio()
    
    if (helpPetId1 ~= nil and helpPetId1 > 0) then
    	local helpPet = petPackage:GetPetById(helpPetId1)
    	local propertyClone = clone(helpPet._PropertyList)
    	for i, property in ipairs(propertyClone) do
    		property.Value = property.Value * addRatio
    	end

    	CallWholeProperty(propertyClone)
    end

    if (helpPetId2 ~= nil and helpPetId2 > 0) then
    	local helpPet = petPackage:GetPetById(helpPetId2)
    	local propertyClone = clone(helpPet._PropertyList)
    	for i, property in ipairs(propertyClone) do
    		property.Value = property.Value * addRatio
    	end

    	CallWholeProperty(propertyClone)
    end
    
    table.sort(resultTable, sort_func)
	return resultTable
end

def.static("=>", "table").GetAllPetGuideInfo = function()
	local map = {}
	local tids = CElementData.GetAllPet()
	for i=1, #tids do
		local petId = tids[i]
		local petGuideInfo = CElementData.GetPetGuideById( petId )

		table.insert(map, petGuideInfo)
	end

	local function sortFunc(a, b)
		return a.Quality < b.Quality
	end
	table.sort(map, sortFunc)

	return map
end

-- 获取 宠物蛋来源信息
def.static("=>", "table").GetPetFromInfo = function()
	local retTable = {}
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetFromInfo")
	local infoList = string.split(str, "*")

	for i=1, #infoList do
		local tid = tonumber(infoList[i])
		local template = CElementData.GetItemApproach(tid)
		local data = {}
		if template ~= nil then
			data.ID = tid
			data.Name = template.DisplayName
			data.FuncID = template.FunID
			data.IconPath = template.IconPath
			table.insert(retTable, data)
		end
	end

	return retTable
end

-- 获取 宠物技能书来源信息
def.static("=>", "table").GetPetSkillBookFromInfo = function()
	local retTable = {}
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local str = CSpecialIdMan.Get("PetSkillBookFromInfo")
	local infoList = string.split(str, "*")

	for i=1, #infoList do
		local tid = tonumber(infoList[i])
		local template = CElementData.GetItemApproach(tid)
		local data = {}
		if template ~= nil then
			data.ID = tid
			data.Name = template.DisplayName
			data.FuncID = template.FunID
			data.IconPath = template.IconPath
			table.insert(retTable, data)
		end
	end

	return retTable
end

-- 计算宠物养成后数据结构
def.static(CPetClass, CPetClass, "=>", "table").CalcFuseInfo = function(pet, petMaterial)
	local retTable = {}
	local oldAptitudeList = pet._AptitudeList
	local addAptitudeList = petMaterial._AptitudeList
	local addRatio = CPetUtility.GetPetFuseAptitudeAddRatio()

	for i=1, #oldAptitudeList do
		local data = {}
		local oldInfo = oldAptitudeList[i]
		local addInfo = addAptitudeList[i]
		local addValue = math.floor(addInfo.Value * (oldInfo.FightPropertyId == addInfo.FightPropertyId and addRatio or 0))
		table.insert(retTable, addValue)
	end

	return retTable
end

-- 获取宠物平均 星级
def.static("=>", "table").GetAvgInfo = function()
	local retTable = {}

	local hp = game._HostPlayer
	local petPackage = hp._PetPackage
	local allPetList = petPackage:GetList()
	local helpPetList = hp:GetCurrentHelpPetList()
	local unlockCount = #helpPetList + 1
	local aptitudeCnt = 5 * unlockCount
	local totalAptitude = 0
	local totalLevel = 0
	local totalStar = 0
	do
		-- 出战宠物
    	local petId = hp:GetCurrentFightPetId()
		local pet = petPackage:GetPetById(petId)
		if pet ~= nil then
			totalAptitude = pet:CalcTotalAptitude()
			totalStar = pet:GetStage()
			totalLevel = pet:GetLevel()
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[1]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				totalAptitude = totalAptitude + pet:CalcTotalAptitude()
				totalStar = totalStar + pet:GetStage()
				totalLevel = totalLevel + pet:GetLevel()
			end
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[2]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				totalAptitude = totalAptitude + pet:CalcTotalAptitude()
				totalStar = totalStar + pet:GetStage()
				totalLevel = totalLevel + pet:GetLevel()
			end
		end
	end

	retTable.AvgStar = totalStar / unlockCount
	retTable.AvgAptitude = totalAptitude / aptitudeCnt
	retTable.AvgLevel = totalLevel / unlockCount

	return retTable
end

-- 洗练红点 状态
def.static(CPetClass, "=>", "boolean").CalcPetRecastRedDotState = function(pet)
    if pet:CanRecast() == false then return false end
    if CPetUtility.IsGotPetRecastMaterial() == false then return false end

    return true
end

-- 培养红点 状态
def.static(CPetClass, "=>", "boolean").CalcPetCultivateRedDotState = function(pet)
    if CPetUtility.CanCultivate(pet) == false then return false end
    if CPetUtility.IsGotPetExpMedicine() == false then return false end

    return true
end
-- 进阶红点 状态
def.static(CPetClass, "=>", "boolean").CalcPetAdvanceRedDotState = function(pet)
    if CPetUtility.CanAdvance(pet) == false then return false end
    if CPetUtility.IsGotAdvancePetNeed(pet) == false then return false end

    return true
end
-- 宠物新技能栏学习红点 状态
def.static(CPetClass, "=>", "boolean").CalcPetSkillCellRedDotState = function(pet)
	-- 宠物技能学习解锁
	if game._CFunctionMan:IsUnlockByFunTid(136) == false then return false end 
	if pet:HasEmptySkillCell() == false then return false end
	if CPetUtility.IsGotPetTalentBook() == false then return false end

    return true
end
-- 宠物界面tag技能学习红点 状态
def.static("=>", "boolean").CalcFightPetSkillRedDotState = function()
	local bRet = false

	-- 技能 只看当前出站宠物，是否学习过技能
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage

	-- 出战宠物
	local petId = hp:GetCurrentFightPetId()
	local pet = petPackage:GetPetById(petId)
	if pet ~= nil then
		bRet = game._CFunctionMan:IsUnlockByFunTid(136) and
			   (not pet:HasSkill()) and
			   CPetUtility.IsGotPetTalentBook()
	end

	return bRet
end

-- 宠物上阵 or 战斗力更高的为出战 红点
def.static("=>", "boolean").CalcPetFightingSetRedDotState = function()
	--warn("CalcPetFightingSetRedDotState===================")

	local hp = game._HostPlayer
	local petPackage = hp._PetPackage
	local allPetList = petPackage:GetList()
	if #allPetList == 0 then return false end

	local fightPetId = hp:GetCurrentFightPetId()
	local helpPetList = hp:GetCurrentHelpPetList()

	local curFightingCnt = 0
	if fightPetId > 0 then
		curFightingCnt = curFightingCnt + 1
	end
	for i=1, #helpPetList do
		if helpPetList[i] > 0 then
			curFightingCnt = curFightingCnt + 1
		end
	end

	local unlockCount = #helpPetList + 1
	if curFightingCnt < unlockCount and #allPetList > curFightingCnt then return true end
--[[
	-- 是否有战力更高的宠物 没有出战 助战  |  策略： 找出出战的最低的，随便有一个为出战的 比值高 即为true
	local lowestScore = 9999999999999
	local fightPetScore = 0
	local fightPet = petPackage:GetPetById(fightPetId)
	
	if fightPet ~= nil then
		fightPetScore = fightPet:GetFightScore()
		lowestScore = math.min(lowestScore, fightPet:GetFightScore())
	else
		lowestScore = 0
	end

	local helpPetScoreMax = 0
	local helpPetId1 = helpPetList[1]
	if helpPetId1 ~= nil then
		local helpPet1 = petPackage:GetPetById(helpPetId1)
		lowestScore = math.min(lowestScore, helpPet1 == nil and 0 or helpPet1:GetFightScore())
		helpPetScoreMax = math.max(helpPetScoreMax, helpPet1 == nil and 0 or helpPet1:GetFightScore())
	end

	local helpPetId2 = helpPetList[2]
	if helpPetId2 ~= nil then
		local helpPet2 = petPackage:GetPetById(helpPetId2)
		lowestScore = math.min(lowestScore, helpPet2 == nil and 0 or helpPet2:GetFightScore())
		helpPetScoreMax = math.max(helpPetScoreMax, helpPet2 == nil and 0 or helpPet2:GetFightScore())
	end

	if helpPetScoreMax > fightPetScore then
		return true
	end

	for i=1, #allPetList do
        local pet = allPetList[i]
        --不能为 出战 助战宠物
        if (hp:IsFightingPetById(pet._ID) or hp:IsHelpingPetById(pet._ID)) == false then
        	if pet:GetFightScore() > lowestScore then
	            return true
	        end
	    end
    end
]]
    return false
end
-- 单宠物红点 状态
def.static(CPetClass, "=>", "boolean").CalcPetRedDotState = function(pet)
    if CPetUtility.CalcPetCultivateRedDotState(pet) then return true end

    return false
end

-- 培养红点提示
def.static("=>", "boolean").CalcPetCultivatePageRedDotState = function()
	local bShowRedDot = false

	local hp = game._HostPlayer
    local petPackage = hp._PetPackage
	local helpPetList = hp:GetCurrentHelpPetList()

	do
		-- 出战宠物
    	local petId = hp:GetCurrentFightPetId()
		local pet = petPackage:GetPetById(petId)
		if pet ~= nil then
			bShowRedDot = CPetUtility.CalcPetCultivateRedDotState(pet)
			if bShowRedDot then return true end
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[1]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				bShowRedDot = CPetUtility.CalcPetCultivateRedDotState(pet)
				if bShowRedDot then return true end
			end
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[2]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				bShowRedDot = CPetUtility.CalcPetCultivateRedDotState(pet)
				if bShowRedDot then return true end
			end
		end
		
	end

    return bShowRedDot
end

-- 重铸红点提示
def.static("=>", "boolean").CalcPetRecastPageRedDotState = function()
	local bShowRedDot = false

	local hp = game._HostPlayer
    local petPackage = hp._PetPackage
	local helpPetList = hp:GetCurrentHelpPetList()

	do
		-- 出战宠物
    	local petId = hp:GetCurrentFightPetId()
		local pet = petPackage:GetPetById(petId)
		if pet ~= nil then
			bShowRedDot = CPetUtility.CalcPetRecastRedDotState(pet)
			if bShowRedDot then return true end
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[1]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				bShowRedDot = CPetUtility.CalcPetRecastRedDotState(pet)
				if bShowRedDot then return true end
			end
		end
	end
	
	do
		-- 助战宠物
    	local petId = helpPetList[2]
    	if petId ~= nil then
			local pet = petPackage:GetPetById(petId)
			if pet ~= nil then
				bShowRedDot = CPetUtility.CalcPetRecastRedDotState(pet)
				if bShowRedDot then return true end
			end
		end
		
	end

    return bShowRedDot
end

-- 刷新红点显示
def.static().UpdatePetRedDot = function()
	local bShowRedDot = false
    
    -- 出战助战 战斗力优于现配置
    if CPetUtility.CalcPetFightingSetRedDotState() == true then
    	bShowRedDot = true
    	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Pet, bShowRedDot)
    	return
    end
    -- 培养
    if CPetUtility.CalcPetCultivatePageRedDotState() == true then
    	bShowRedDot = true
    	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Pet, bShowRedDot)
    	return
    end
    -- 洗练 废弃
    -- if CPetUtility.CalcPetRecastPageRedDotState() == true then
    -- 	bShowRedDot = true
    -- 	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Pet, bShowRedDot)
    -- 	return
    -- end

    -- 技能 只看当前出站宠物，是否学习过技能
    if CPetUtility.CalcFightPetSkillRedDotState() == true then
    	bShowRedDot = true
    	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Pet, bShowRedDot)
    	return
    end

	-- warn("UpdateModuleRedDotShow。。。。。。。", bShowRedDot)
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Pet, bShowRedDot)
end

CPetUtility.Commit()
return CPetUtility