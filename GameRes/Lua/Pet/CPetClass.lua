local Lplus = require "Lplus"

local DynamicText = require "Utility.DynamicText"
local CPetClass = Lplus.Class("CPetClass")
local CElementData = require "Data.CElementData"
local CScoreCalcMan = require "Data.CScoreCalcMan"

local def = CPetClass.define

def.field("number")._ID = 0							--唯一id
def.field("number")._Tid = 0						--模板id
def.field("string")._Name = ""						--显示名称
def.field("string")._NickName = ""					--昵称（玩家重命名）
def.field("number")._Level = 0						--等级
def.field("number")._Stage = 0						--品阶
def.field("number")._MaxStage = 0					--最大品阶
def.field("number")._FightScore = 0					--战斗力
def.field("number")._Exp = 0						--当前宠物经验值
def.field("number")._MaxExp = 0						--当前等级最大经验值
def.field("table")._SkillList = BlankTable			--宠物技能
def.field("table")._AptitudeList = BlankTable		--宠物资质
def.field("table")._AptitudeCache = nil				--临时洗练资质
def.field("table")._PropertyList = BlankTable		--宠物属性
def.field("number")._Genus = 0						--类别
def.field("string")._IconPath = ""					--图标
def.field("number")._Quality = 0					--品质
def.field("string")._ModelAssetPath = ""			--模型路径
def.field("string")._PetStroy = ""                  --宠物故事
def.field("table")._BaseProperty = BlankTable		--宠物基础属性值 1阶 1级
def.field("number")._RecyclingPetDebris = 0			--回收返还的东西
def.field("number")._TalentId = 0					--天赋技能
def.field("number")._TalentLevel = 0				--天赋技能等级
def.field("number")._RecastCount = 0				--剩余洗脸次数
def.field("number")._PropertyScore = 0				--属性提供的战斗力
def.field("number")._SkillScore = 0					--技能提供的战斗力
def.field("number")._InsteadSkillIndex = 0			--技能学习被替换的Index
def.field("table")._Template = BlankTable			--模板数据
def.field("table")._AptitudeMaxList = BlankTable	--资质最大值 按品阶划分




def.static("=>", CPetClass).new = function ()
	local obj = CPetClass()
	return obj
end

def.method("table").Init = function(self, petDB)
	local template = CElementData.GetTemplate("Pet", petDB.tId)
	if template == nil then
		warn("Pet template is null id = ", petDB.tId)
		return
	end

	self._ID = petDB.petId
	self._Tid = petDB.tId
	self._Name = template.Name

	self._Genus = template.Genus
	self._IconPath = template.IconPath
	self._Quality = template.Quality
	self._PetStroy = template.Stroy
	self._RecyclingPetDebris = template.RecyclingPetDebris
	self._Template = template

	do
	--模型 关联怪物信息
		local monsterData = CElementData.GetTemplate("Monster", template.AssociatedMonsterId)
		if monsterData ~= nil then
			self._ModelAssetPath = monsterData.ModelAssetPath
			self._BaseProperty = {}
			for i,v in ipairs(petDB.petProperties) do
				table.insert(self._BaseProperty, { ID = v.id, Value = v.value })
			end
		end
	end

	--设置属性
	self:UpdateAll(petDB)
end

--设置属性
def.method("table").UpdateAll = function(self, petDB)
	if petDB.nickName == nil or petDB.nickName == "" then
		self._NickName = self._Name
	else
		self._NickName = petDB.nickName --string.format("%s(%s)", petDB.nickName, self._Name)
	end
	self._Level = petDB.level
	self._Stage = petDB.stage

	self._TalentId = petDB.specialTalentSkillData.talentId
	self._TalentLevel =  petDB.specialTalentSkillData.level
	self._RecastCount = petDB.recastCount
	
	local CPetUtility = require "Pet.CPetUtility"
	self._MaxStage = CPetUtility.GetMaxPetStage()
	
	self._Exp = petDB.currExp

	-- 升到下一级所需要的经验 
	self._MaxExp = CElementData.GetPetExp(self._Quality, self._Level)
	
	--宠物技能初始化
	self:InitSkill(petDB.petSkillDatas)
	--宠物资质初始化
	self:InitAptitude(petDB.aptitudes)
	--宠物临时-洗练资质 初始化
	self:InitAptitudeCache(petDB.aptitudeCache)
	--宠物属性初始化
	self:InitProperty(petDB.petProperties)
	-- 计算宠物战斗力
	self._FightScore = petDB.fightScore --self:CalcFightScore()
	self._PropertyScore = petDB.fightScoreBaseProperties
	self._SkillScore = petDB.fightScoreSkill
	-- 初始化资质最大值
	self:InitAptitudeMax()
--[[
	warn("【宠物】名称: ", self._Name)
	warn("【宠物】昵称: ", self._NickName)
	warn("【宠物】等级: ", self._Level)
	warn("【宠物】品阶: ", self._Stage)
	warn("【宠物】战斗力: ", self._FightScore)
	warn("【宠物】当前经验: ", self._Exp)
	warn("【宠物】最大经验: ", self._MaxExp)
	warn("【宠物】技能个数: ", #self._SkillList)
	warn("【宠物】资质个数: ", #self._AptitudeList)
	for i,v in ipairs(self._AptitudeList) do
		warn("================================")
		warn("ID = ", v.ID)
		warn("FightPropertyId = ", v.FightPropertyId)
		warn("Name = ", v.Name)
		warn("Star = ", v.Star)
		warn("Value = ", v.Value)
		warn("MinValue = ", v.MinValue)
		warn("MaxValue = ", v.MaxValue)
		warn("MaxStar = ", v.MaxStar)
	end

	warn("【宠物】临时资质个数: ", #self._AptitudeCache)
]]
end

-- 初始化资质最大值
def.method().InitAptitudeMax = function(self)
	self._AptitudeMaxList = {}

	local infoList = string.split(self._Template.AptitudeMax, "*")
	for i,v in ipairs(infoList) do
		table.insert(self._AptitudeMaxList, tonumber(v))
	end
end
-- 获得资质属性最大值
def.method("number", "=>", "number").GetAptitudeMaxByIndex = function(self, index)
	return self._AptitudeMaxList[index] or 0
end


--[[==============================================================================================]]
--[[ Skill ]]
--宠物技能初始化
def.method("table").InitSkill = function(self, skillDBList)
	--warn("宠物技能初始化")
	self._SkillList = {}

	local CPetUtility = require "Pet.CPetUtility"
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数

    for i, dbInfo in ipairs(skillDBList) do
		local skillInfo = self:GetSkillInfoByDbInfo(dbInfo)
		table.insert(self._SkillList, skillInfo)
	end
end

--[[ 
	构造宠物技能信息
	Skill = 
	{
		--Require var
		Open = false,
		Desc = "",   --if Open: skill desc, or open condition
		
		-- Opened:: Optional var
		ID = 0,
		Name = "",
		IconPath = "",
	}
]]
def.method("table", "=>", "table").GetSkillInfoByDbInfo = function(self, dbInfo)
	--开启的技能槽
	local data = {}
	local template = CElementData.GetTemplate("Talent", dbInfo.talentId)
	--skill存在, 则技能槽为开启, or 未开启
	data.Open = true
	data.CanOpen = true

	if template == nil then
		--未设置技能的卡槽
		data.ID = 0
	else
		--设置技能的卡槽
		data.ID = dbInfo.talentId
		data.Level = dbInfo.level
		data.Name = template.Name
		data.Desc = DynamicText.ParseSkillDescText(dbInfo.talentId, dbInfo.level, true)--template.TalentDescribtion
		data.IconPath = template.Icon
		data.Quality = template.InitQuality
	end

	return data
end

def.method("=>", "number").CalcFightScore = function(self)
	local list = {}
	for i=1, #self._PropertyList do
		local data = {}
		local property = self._PropertyList[i]
		data.ID = property.FightPropertyId
		data.Value = property.Value
		table.insert(list, data)
	end
	self._PropertyScore = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, list)
	self._SkillScore = self:CalcSkillFightScore()

	return self._PropertyScore + self._SkillScore
end

def.method("=>", "number").GetPropertyScore = function(self)
	return self._PropertyScore
end

def.method("=>", "number").GetSkillScore = function(self)
	return self._SkillScore
end

--[[==============================================================================================]]
--[[ Property ]]
--宠物属性初始化
def.method("table").InitProperty = function(self, propertyDBList)
	--warn("宠物属性初始化")
	self._PropertyList = {}
	for i, propertyDB in ipairs(propertyDBList) do
		local propertyInfo = self:GetPropertyInfoByPropertyDB(propertyDB)
		
		if propertyInfo ~= nil then
			table.insert(self._PropertyList, propertyInfo)
		end
	end
end
def.method("table", "=>", "table").GetPropertyInfoByPropertyDB = function(self, propertyDB)
	local groupTemplate = CElementData.GetAttachedPropertyGeneratorTemplate(propertyDB.id)
	local fightElement = CElementData.GetAttachedPropertyTemplate(groupTemplate.FightPropertyId)

	if fightElement == nil then return nil end

	local data = {}
	data.ID = propertyDB.id
	data.Name = fightElement.TextDisplayName
	data.FightPropertyId = fightElement.Id

	local CPetUtility = require "Pet.CPetUtility"
	local Aptitude = self:GetAptitudeInfoByPropertyId( data.ID )
    local coefficient = CPetUtility.GetPetAptitudeIncFixCoefficientById( Aptitude.FightPropertyId )
    local val = Aptitude.Value * coefficient
    local addValue = math.clamp(val, 1, val)
	data.Value = propertyDB.value + addValue * self:GetLevel()

	return data
end

--[[==============================================================================================]]
--[[ Aptitude ]]
--宠物资质初始化
def.method("table").InitAptitude = function(self, aptitudeDBList)
	--warn("宠物资质初始化")
	self._AptitudeList = {}
	local ids = string.split(self._Template.AttachedPropertyGeneratorIds, "*")

	for i, aptitudeDB in ipairs(aptitudeDBList) do
		local aptitudeInfo = self:GetAptitudeInfoByAptitudeDB( aptitudeDB )

		if aptitudeInfo ~= nil then
			local limitInfoId = tonumber(ids[i])	
			local propertyInfo = CElementData.GetPropertyInfoById( limitInfoId )

			aptitudeInfo.MinValue = propertyInfo.MinValue
			aptitudeInfo.MaxValue = propertyInfo.MaxValue

			table.insert(self._AptitudeList, aptitudeInfo)
		end
	end
end

--宠物临时-洗练资质 初始化
def.method("table").InitAptitudeCache = function(self, aptitudeCacheDBList)
	--warn("宠物临时-洗练资质 初始化")
	self._AptitudeCache = {}
	local ids = string.split(self._Template.AttachedPropertyGeneratorIds, "*")

	for i, aptitudeCacheDB in ipairs(aptitudeCacheDBList) do
		local aptitudeCacheInfo = self:GetAptitudeInfoByAptitudeDB( aptitudeCacheDB )

		if aptitudeCacheInfo ~= nil then
			local limitInfoId = tonumber(ids[i])	
			local propertyInfo = CElementData.GetPropertyInfoById( limitInfoId )

			aptitudeCacheInfo.MinValue = propertyInfo.MinValue
			aptitudeCacheInfo.MaxValue = propertyInfo.MaxValue

			table.insert(self._AptitudeCache, aptitudeCacheInfo)
		end
	end
end

--[[ 
	构造宠物资质信息
	Aptitude = 
	{
		ID = 0,
		FightPropertyId = 0,
		Name = "",
		Star = 0,
		Value = 0,
		MinValue,
		--MaxValue,
		--MaxStar,
	}
]]
def.method("table", "=>", "table").GetAptitudeInfoByAptitudeDB = function(self, aptitudeDB)
	--warn("aptitudeDB.id = ", aptitudeDB.id)
	local propertyInfo = CElementData.GetPropertyInfoById( aptitudeDB.id )
	if propertyInfo == nil then return nil end

	local data = {}
	data.ID = aptitudeDB.id
	data.FightPropertyId = propertyInfo.FightPropertyId
	data.Name = propertyInfo.Name
	data.Star = aptitudeDB.level
	data.Value = tonumber(fixFloatStr(tostring(aptitudeDB.value), 1))


	return data
end

--获取资质成长值
def.method("number", "=>", "table").GetAptitudeInfoByPropertyId = function(self, propertyId)
	local result = nil
	for i=1, #self._AptitudeList do
		local aptitude = self._AptitudeList[i]
		if aptitude.ID == propertyId then
			result = aptitude
			break
		end
	end

	return result
end

--计算成长值
def.method("number", "number", "number", "number", "=>", "number").CalcProperty = function(self, propertyId, basePropertyValue, level, stage)
	local CPetUtility = require "Pet.CPetUtility"
	local addAptitude = self:GetAptitudeInfoByPropertyId(propertyId).Value
	local coefficient = CPetUtility.GetCoefficientByStage(stage)

	return basePropertyValue*(1+coefficient) + addAptitude*(level-1)
end

-- 计算技能提供的战斗力
def.method("=>", "number").CalcSkillFightScore = function(self)
	local result = 0
	local info = {}
	local prof = game._HostPlayer._InfoData._Prof

	--计算公式类 获取结果
	result = result + CScoreCalcMan.Instance():CalcTalentSkillScore(prof, self._TalentId, self._TalentLevel)
	for i=1, #self._SkillList do
		local skill = self._SkillList[i]
		if skill.ID > 0 then
			result = result + CScoreCalcMan.Instance():CalcTalentSkillScore(prof, skill.ID, skill.Level)
		end
	end

	return result
end

--[[
--计算战斗力
def.method("=>", "number").CalcFightScore = function(self)
	local result = 0

	local CScoreCalcMan = require "Data.CScoreCalcMan"
	local info = {}

	for i=1, #self._PropertyList do
		local property = self._PropertyList[i]
		local data = {}
		data.ID = property.FightPropertyId
		data.Value = property.Value

		table.insert(info, data)
	end

	--计算公式类 获取结果
	result = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, info)
	result = result + CScoreCalcMan.Instance():CalcLegendaryUpgradeScore(self._TalentId, 1)
	for i=1, #self._SkillList do
		local skill = self._SkillList[i]
		if skill.ID > 0 then
			result = result + CScoreCalcMan.Instance():CalcLegendaryUpgradeScore(skill.ID, 1)
		end
	end

	return result
end
]]
--[[==============================================================================================]]
--[[ Client Fuction ]]

def.method("number").UpdateInsteadSkillIndex = function(self, skillId)
	for i,v in ipairs(self._SkillList) do
		if v.ID == skillId then
			self._InsteadSkillIndex = i
		end
	end
end
def.method("=>", "number").GetInsteadSkillIndex = function(self)
	return self._InsteadSkillIndex
end
def.method("number").UpdateRecastCount = function(self, count)
	self._RecastCount = count
end
def.method("string").UpdateNickName = function(self, nickName)
	self._NickName = nickName
end
def.method("number").UpdateLevel = function(self, level)
	self._Level = level
end
def.method("number").UpdateStage = function(self, stage)
	self._Stage = stage
end
def.method("number").UpdateFightScore = function(self, fightScore)
	self._FightScore = fightScore
end
def.method("number").UpdateExp = function(self, currExp)
	self._Exp = currExp
end
def.method("=>", "boolean").HasEmptySkillCell = function(self)
	local bRet = false
	for i, skillInfo in ipairs(self._SkillList) do
		if skillInfo.Open and skillInfo.ID == 0 then
			bRet = true
			break
		end
	end

	return bRet
end
def.method("=>", "boolean").HasSkill = function(self)
	local bRet = false
	for i, skillInfo in ipairs(self._SkillList) do
		if skillInfo.ID ~= 0 then
			bRet = true
			break
		end
	end

	return bRet
end

def.method("number", "=>", "boolean").HasLearnedSkillById = function(self, skillId)
	local bRet = false
	for i=1, #self._SkillList do
		local id = self._SkillList[i].ID
		if id ~= nil and id == skillId then
			bRet = true
			break
		end
	end

	return bRet
end
def.method("=>", "boolean").HasAptitudeCache = function(self)
	return (self._AptitudeCache ~= nil and #self._AptitudeCache > 0) 
end
def.method("=>", "boolean").IsMaxStage = function(self)
	return self._Stage >= self._MaxStage
end
def.method("=>", "boolean").IsMaxLevel = function(self)
	return self._MaxExp == 0
end
def.method("=>", "string").GetName = function(self)
	return self._Name
end
def.method("=>", "string").GetNickName = function(self)
	return self._NickName
end
def.method("=>", "number").GetStage = function(self)
	return self._Stage
end
def.method("=>", "number").GetLevel = function(self)
	return self._Level
end
def.method("=>", "number").GetQuality = function(self)
	return self._Quality
end
def.method("=>", "string").GetQualityText = function(self)
	return StringTable.Get(10000 + self._Quality)
end
def.method("=>", "number").GetFightScore = function(self)
	return self._FightScore
end
def.method("=>", "string").GetGenusString = function(self)
	return StringTable.Get(19022+self._Genus)
end
def.method("=>", "string").GetStory = function(self)
	return self._PetStroy
end

def.method("=>", "number").GetSkillFieldCount = function(self)
    return self._SkillList ~= nil and #self._SkillList or 0
end

def.method("=>", "number").GetRecyclingPetDebris = function(self)
	return self._RecyclingPetDebris
end
def.method("number", "=>", "number").GetBasePropertyById = function(self, propertyId)
	local retVal = 0
	for i=1, #self._BaseProperty do
		local info = self._BaseProperty[i]
		if info.ID == propertyId then
			retVal = info.Value
			break
		end
	end

	return retVal
end
--获取宠物技能个数
def.method('=>', "number").GetSkillCount = function(self)
	return #self._SkillList or 0
end
--获取宠物技能品质总和
def.method('=>', "number").GetAllSkillQualityAmount = function(self)
	local nRet = 0
	for i, skillInfo in ipairs(self._SkillList) do
		nRet = nRet + (skillInfo.Quality or 0)
	end

	return nRet
end
--能否洗练
def.method("=>", "boolean").CanRecast = function(self)
	return self._RecastCount > 0
end

def.method().Reset = function (self)
	self._ID = 0
	self._Tid = 0
	self._Name = ""
	self._NickName = ""
	self._Level = 0
	self._Stage = 0
	self._FightScore = 0
	self._Exp = 0
	self._MaxExp = 0
	self._SkillList = nil
	self._AptitudeList = nil
	self._AptitudeCache = nil
	self._PropertyList = nil
	self._Genus = 0
	self._IconPath = ""
	self._Quality = 0
	self._ModelAssetPath = ""
end

CPetClass.Commit()
return CPetClass