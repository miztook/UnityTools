local CacheTable = {}
local CurrentKey = nil
local IsWork = false
local StartTime = nil

function _G.EfficiencyAnalyzeOpen( )
	StartTime = GameUtil.GetServerTime()
	IsWork = true
end

function _G.EfficiencyAnalyzeRegist( key )
	if not IsWork then return end
	CurrentKey = key
	local item = CacheTable[key]
	if (not item) then
		CacheTable[key] = {1, GameUtil.GetServerTime(), 0}
	else
		if item[2] ~= 0 then
			printError("+++", "EfficiencyAnalyze Error Regist")
		end
		item[2] = GameUtil.GetServerTime()
	end
end

function _G.EfficiencyAnalyzeFinish( )
	if not IsWork then return end
	if CurrentKey == nil then
		printError("+++", "EfficiencyAnalyze Error Finish : CurrentKey is nil", CurrentKey)
		return
	end
	local item = CacheTable[CurrentKey]
	if not item then
		printError("+++", "EfficiencyAnalyze Error Finish : CacheTable[CurrentKey] is nil", CurrentKey)
		return
	end
	item[1] = item[1] + 1
	item[3] = item[3] + GameUtil.GetServerTime() - item[2]
	-- item[3] = item[3] + GameUtil.GetNowMicrosecond() - item[2]
	item[2] = 0
	CurrentKey = nil
end

function _G.EfficiencyAnalyzePrint(  )
	if not IsWork then return end
	IsWork = false
	local filename = _G.res_base_path .. "/" .. "EfficiencyAnalyzePrint.csv"
    local file = io.open(filename, "w")
	-- local res = "名称,调用次数,时间\n"
	file:write("start,end,interval\n")
	local endTime = GameUtil.GetServerTime()
	file:write(StartTime .. "," .. endTime .. "," ..  (endTime - StartTime) .."\n")
	file:write("name,count,time(total),average\n")
	for k, v in pairs(CacheTable) do
		-- print(k .. " " .. v[1] .. " " .. v[3] .. v[3]/v[1] .. "\n")
        file:write(k .. "," .. v[1] .. "," .. v[3] .. "," .. v[3]/v[1] .. "\n")
		-- res = res .. k .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. "\n"
	end
    file:close()
end

--------------------------------------------------------------次数统计--------------------------------------------------
local CacheTemplateData = {}
function _G.EfficiencyTemplateDataRegist( name, id )
	local item = CacheTemplateData[name]
	if (not item) then
		local temp = {}
		temp[id] = 1
		CacheTemplateData[name] = temp
	else
		local targetID = item[id]
		if not targetID then
			item[id] = 1
		else
			item[id] = item[id] + 1
		end
	end
end

local CacheAllTidData = {}
function _G.EfficiencyAllTidRegist( name )
	local item = CacheAllTidData[name]
	if (not item) then
		CacheAllTidData[name] = 1
	else
		CacheAllTidData[name] = CacheAllTidData[name] + 1
	end
end

function _G.EfficiencyTemplateAllTidDataPrint()
	local filename = _G.res_base_path .. "/" .. "TemplateEfficiencyAnalyze.txt"
    local file = io.open(filename, "w")
	-- file:write("name,count - id[count]\n")
	file:write("GetTemplate name id[count]\n")
	for k, v in pairs(CacheTemplateData) do
		file:write("\n")
		file:write("\t" .. k)
		local res = "\n\t\t{\n\t\t\t"
		for m, n in pairs(v) do
			res = res .. m .. "[" .. n .. "]" .. " "
		end
		res = res .. "\n\t\t}"
        file:write(res .. "\n")
	end

	file:write("\n")
	file:write("\n")
	
	
	file:write("GetAllTid   name count\n")
	for k, v in pairs(CacheAllTidData) do
        file:write(k .. "\t\t" .. v .. "\n")
	end

    file:close()
end

-- function _G.EfficiencyTemplateAllTidDataPrint()
-- 	IsWork = false
-- 	local filename = _G.res_base_path .. "/" .. "TemplateEfficiencyAnalyze.csv"
--     local file = io.open(filename, "w")
-- 	file:write("name,count - id[count]\n")

-- 	for k, v in pairs(CacheTemplateData) do
-- 		local res = k .. ","
-- 		for m, n in pairs(v) do
-- 			res = res .. m .. "[" .. n .. "]" .. " "
-- 		end
--         file:write(res .. "\n")
-- 	end

-- 	file:write("\n")
-- 	file:write("\n")
	
-- 	for k, v in pairs(CacheAllTidData) do
--         file:write(k .. "," .. v .. "\n")
-- 	end

--     file:close()
-- end