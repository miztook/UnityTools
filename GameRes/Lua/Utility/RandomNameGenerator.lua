
--配置表最小名字长度
local MinRoleNameLength = GlobalDefinition.MinRoleNameLength
--配置表最大名字长度
local MaxRoleNameLength = GlobalDefinition.MaxRoleNameLength


local random_name = nil -- 随机名字表

local generateRandomName = function(index)
	if random_name == nil then
		random_name = ReadConfigTable(_G.ConfigsDir .. "RandomName.lua")
	end

	--含义请参见Configs\RandomName.lua
	local HumanMaleFirstNames = random_name.HumanMaleFirstNames
	local HumanMaleLastNames = random_name.HumanMaleLastNames
	local ElfFemaleFirstNames = random_name.ElfFemaleFirstNames
	local ElfFemaleSecondNames = random_name.ElfFemaleSecondNames
	local ElfFemaleLastNames = random_name.ElfFemaleLastNames
	local CastanicLastNameNilPro = random_name.CastanicLastNameNilPro
	local CastanicMaleFirstNames = random_name.CastanicMaleFirstNames
	local CastanicMaleLastNames = random_name.CastanicMaleLastNames
	local IreneFemaleFirstNames = random_name.IreneFemaleFirstNames
	local IreneFemaleSecondNames = random_name.IreneFemaleSecondNames
	local IreneFemaleLastNames = random_name.IreneFemaleLastNames
	local InfixSymbols = random_name.InfixSymbols


	--中缀根据势力Id是有一定概率不存在的，即仅仅有姓或者仅仅有名的情况下不存在
	--1:人类;4:高等精灵;3:卡斯塔尼克;2:艾琳
	--目前各势力性别是固定的--2016年9月29日
	local name = ""
	local firstName = ""
	local secondName = ""
	local infixSymbols = ""
	local lastName = ""
	local loopTime = 0
	while(GameUtil.GetStringLength(name) < MinRoleNameLength or GameUtil.GetStringLength(name) > MaxRoleNameLength) do
		loopTime = loopTime + 1
		if loopTime > 10 then
			warn("GenerateRandomName----dead loop")
			name = ""
			local count = math.random(MinRoleNameLength, MaxRoleNameLength)
			for i = 0, count do
				name = name .. math.random(0, 9) 
			end
			return name
		end
		if index == 1 then
			firstName = HumanMaleFirstNames[math.random(1, table.maxn(HumanMaleFirstNames))]
			infixSymbols = InfixSymbols[math.random(1, table.maxn(InfixSymbols))]			
			lastName = HumanMaleLastNames[math.random(1, table.maxn(HumanMaleLastNames))]
			name = firstName .. infixSymbols .. lastName
		elseif index == 4 then
			firstName = ElfFemaleFirstNames[math.random(1, table.maxn(ElfFemaleFirstNames))]
			secondName = ElfFemaleSecondNames[math.random(1, table.maxn(ElfFemaleSecondNames))]
			infixSymbols = InfixSymbols[math.random(1, table.maxn(InfixSymbols))]			
			lastName = ElfFemaleLastNames[math.random(1, table.maxn(ElfFemaleLastNames))]
			name = firstName .. secondName .. infixSymbols .. lastName
		elseif index == 3 then
			firstName = CastanicMaleFirstNames[math.random(1, table.maxn(CastanicMaleFirstNames))]
			if math.random(0, 1) > CastanicLastNameNilPro then
				infixSymbols = InfixSymbols[math.random(1, table.maxn(InfixSymbols))]
				lastName = CastanicMaleLastNames[math.random(1, table.maxn(CastanicMaleLastNames))]
			end
			name = firstName .. infixSymbols .. lastName
		elseif index == 2 or index == 5 then
			firstName = IreneFemaleFirstNames[math.random(1, table.maxn(IreneFemaleFirstNames))]
			secondName = IreneFemaleSecondNames[math.random(1, table.maxn(IreneFemaleSecondNames))]
			infixSymbols = InfixSymbols[math.random(1, table.maxn(InfixSymbols))]
			lastName = IreneFemaleLastNames[math.random(1, table.maxn(IreneFemaleLastNames))]
			name = firstName .. secondName .. infixSymbols .. lastName
		end
	end

	return name 
end

local releaseRandomNameTable = function()
	random_name = nil
	_G.Unrequire(_G.ConfigsDir .. "RandomName.lua")
end

return
{
	GenerateRandomName = generateRandomName,
	ReleaseRandomNameTable = releaseRandomNameTable
}