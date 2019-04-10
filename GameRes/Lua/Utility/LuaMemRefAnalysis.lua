local cConfig = 
{
    m_bAllMemoryRefFileAddTime = true,
    m_bSingleMemoryRefFileAddTime = true,
    m_bComparedMemoryRefFileAddTime = true
}

function LocalSplit(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter=='') then return false end
    local pos,arr = 0, {}
    -- for each divider found
    for st,sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

function ConcatListNode(arr)
	local ret = ""
	for i = 1, #arr do 
		ret = ret..arr[i]
	end
	return ret
end

function RevCatchList(arr, len)
	if not arr then
		return ""
	end

	if #arr < len then
		return ConcatListNode(arr)
	end
	local arr_length = #arr
	local ret = {}
	for i = arr_length - len + 1, #arr do 
		table.insert(ret, arr[i])
	end

	return ConcatListNode(ret)
end

local FilterList = {
    [1] = "loaded.PB",
    [2] = "memberInfoMap",
    --[3] = "MapBasicInfoTable",
}
	
function IsInFilterList(name)
    local ret = false
    for i = 1, #FilterList do 
        if string.find(name, FilterList[i]) then
            ret = true
            break
        end
    end
    return ret
end


-- Get the string result without overrided __tostring.
local function GetOriginalToStringResult(cObject)
	if not cObject then
		return ""
	end

	local cMt = getmetatable(cObject)
	if not cMt then
		return tostring(cObject)
	end

	-- Check tostring override.
	local strName = ""
	local cToString = rawget(cMt, "__tostring")
	if cToString then
		rawset(cMt, "__tostring", nil)
		strName = tostring(cObject)
		rawset(cMt, "__tostring", cToString)
	else
		strName = tostring(cObject)
	end

	return strName
end

-- Create a container to collect the mem ref info results.
local function CreateObjectReferenceInfoContainer()
	-- Create new container.
	local cContainer = {}

	-- Contain [table/function] - [reference count] info.
	local cObjectReferenceCount = {}
	setmetatable(cObjectReferenceCount, {__mode = "k"})

	-- Contain [table/function] - [name] info.
	local cObjectAddressToName = {}
	setmetatable(cObjectAddressToName, {__mode = "k"})

	-- Set members.
	cContainer.m_cObjectReferenceCount = cObjectReferenceCount
	cContainer.m_cObjectAddressToName = cObjectAddressToName

	-- For stack info.
	cContainer.m_nStackLevel = -1
	cContainer.m_strShortSrc = "None"
	cContainer.m_nCurrentLine = -1

	return cContainer
end

-- Create a container to collect the mem ref info results from a dumped file.
-- strFilePath - The file path.
local function CreateObjectReferenceInfoContainerFromFile(strFilePath)
	-- Create a empty container.
	local cContainer = CreateObjectReferenceInfoContainer()
	cContainer.m_strShortSrc = strFilePath

	-- Cache ref info.
	local cRefInfo = cContainer.m_cObjectReferenceCount
	local cNameInfo = cContainer.m_cObjectAddressToName

	-- Read each line from file.
	local cFile = assert(io.open(strFilePath, "rb"))
	for strLine in cFile:lines() do
		local strHeader = string.sub(strLine, 1, 2)
		if "--" ~= strHeader then
			local _, _, strAddr, strName, strRefCount= string.find(strLine, "(.+),(.*),(%d+)")
			if strAddr then
				cRefInfo[strAddr] = strRefCount
				cNameInfo[strAddr] = strName
			end
		end
	end

    -- Close and clear file handler.
    io.close(cFile)
    cFile = nil

	return cContainer
end

-- Create a container to collect the mem ref info results from a dumped file.
-- strObjectName - The object name you need to collect info.
-- cObject - The object you need to collect info.
local function CreateSingleObjectReferenceInfoContainer(strObjectName, cObject)
	-- Create new container.
	local cContainer = {}

	-- Contain [address] - [true] info.
	local cObjectExistTag = {}
	setmetatable(cObjectExistTag, {__mode = "k"})

	-- Contain [name] - [true] info.
	local cObjectAliasName = {}

	-- Contain [access] - [true] info.
	local cObjectAccessTag = {}
	setmetatable(cObjectAccessTag, {__mode = "k"})

	-- Set members.
	cContainer.m_cObjectExistTag = cObjectExistTag
	cContainer.m_cObjectAliasName = cObjectAliasName
	cContainer.m_cObjectAccessTag = cObjectAccessTag

	-- For stack info.
	cContainer.m_nStackLevel = -1
	cContainer.m_strShortSrc = "None"
	cContainer.m_nCurrentLine = -1

	-- Init with object values.
	cContainer.m_strObjectName = strObjectName
	cContainer.m_strAddressName = (("string" == type(cObject)) and ("\"" .. tostring(cObject) .. "\"")) or GetOriginalToStringResult(cObject)
	cContainer.m_cObjectExistTag[cObject] = true

	return cContainer
end

-- Collect memory reference info from a root table or function.
-- strName - The root object name that start to search, default is "_G" if leave this to nil.
-- cObject - The root object that start to search, default is _G if leave this to nil.
-- cDumpInfoContainer - The container of the dump result info.
local function CollectObjectReferenceInMemory(strName, cObject, cDumpInfoContainer)
	if not cObject then
		return
	end

	if not strName then
		strName = ""
	end

	-- Check container.
	if (not cDumpInfoContainer) then
		cDumpInfoContainer = CreateObjectReferenceInfoContainer()
	end

	-- Check stack.
	if cDumpInfoContainer.m_nStackLevel > 0 then
		local cStackInfo = debug.getinfo(cDumpInfoContainer.m_nStackLevel, "Sl")
		if cStackInfo then
			cDumpInfoContainer.m_strShortSrc = cStackInfo.short_src
			cDumpInfoContainer.m_nCurrentLine = cStackInfo.currentline
		end

		cDumpInfoContainer.m_nStackLevel = -1
	end

	-- Get ref and name info.
	local cRefInfoContainer = cDumpInfoContainer.m_cObjectReferenceCount
	local cNameInfoContainer = cDumpInfoContainer.m_cObjectAddressToName
	
	local strType = type(cObject)
	if "table" == strType then
		-- Check table with class name.
		if rawget(cObject, "__cname") then
			if "string" == type(cObject.__cname) then
				strName = strName .. "[class:" .. cObject.__cname .. "]"
			end
		elseif rawget(cObject, "class") then
			if "string" == type(cObject.class) then
				strName = strName .. "[class:" .. cObject.class .. "]"
			end
		elseif rawget(cObject, "_className") then
			if "string" == type(cObject._className) then
				strName = strName .. "[class:" .. cObject._className .. "]"
			end
		end

		-- Check if table is _G.
		if cObject == _G then
			strName = strName .. "[_G]"
		end

		-- Get metatable.
		local bWeakK = false
		local bWeakV = false
		local cMt = getmetatable(cObject)
		if cMt then
			-- Check mode.
			local strMode = rawget(cMt, "__mode")
			if strMode then
				if "k" == strMode then
					bWeakK = true
				elseif "v" == strMode then
					bWeakV = true
				elseif "kv" == strMode then
					bWeakK = true
					bWeakV = true
				end
			end
		end

		-- Add reference and name.
		cRefInfoContainer[cObject] = (cRefInfoContainer[cObject] and (cRefInfoContainer[cObject] + 1)) or 1
		if cNameInfoContainer[cObject] then
			return
		end

		-- Set name.
		cNameInfoContainer[cObject] = strName

		-- Dump table key and value.
		for k, v in pairs(cObject) do
			-- Check key type.
			local strKeyType = type(k)
			if "table" == strKeyType then
				if not bWeakK then
					CollectObjectReferenceInMemory(strName .. ".[t:k.t]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "function" == strKeyType then
				if not bWeakK then
					CollectObjectReferenceInMemory(strName .. ".[t:k.f]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "thread" == strKeyType then
				if not bWeakK then
					CollectObjectReferenceInMemory(strName .. ".[t:k.thrd]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "userdata" == strKeyType then
				if not bWeakK then
					CollectObjectReferenceInMemory(strName .. ".[t:k.usd]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			else
				CollectObjectReferenceInMemory(strName .. "." .. tostring(k), v, cDumpInfoContainer)
			end
		end

		-- Dump metatable.
		if cMt then
			CollectObjectReferenceInMemory(strName ..".[mt]", cMt, cDumpInfoContainer)
		end
	elseif "userdata" == strType then
		-- Add reference and name.
		cRefInfoContainer[cObject] = (cRefInfoContainer[cObject] and (cRefInfoContainer[cObject] + 1)) or 1
		if cNameInfoContainer[cObject] then
			return
		end

		-- Set name.
		cNameInfoContainer[cObject] = strName

		-- Dump environment table.
		local getfenv = debug.getfenv
		if getfenv then
			local cEnv = getfenv(cObject)
			if cEnv then
				CollectObjectReferenceInMemory(strName ..".[usd:env]", cEnv, cDumpInfoContainer)
			end
		end

		-- Dump metatable.
		local cMt = getmetatable(cObject)
		if cMt then
			CollectObjectReferenceInMemory(strName ..".[usd:mt]", cMt, cDumpInfoContainer)
		end
	end
end

-- Collect memory reference info of a single object from a root table or function.
-- strName - The root object name that start to search, can not be nil.
-- cObject - The root object that start to search, can not be nil.
-- cDumpInfoContainer - The container of the dump result info.
local function CollectSingleObjectReferenceInMemory(strName, cObject, cDumpInfoContainer)
	if not cObject then
		return
	end

	if not strName then
		strName = ""
	end

	-- Check container.
	if (not cDumpInfoContainer) then
		cDumpInfoContainer = CreateObjectReferenceInfoContainer()
	end

	-- Check stack.
	if cDumpInfoContainer.m_nStackLevel > 0 then
		local cStackInfo = debug.getinfo(cDumpInfoContainer.m_nStackLevel, "Sl")
		if cStackInfo then
			cDumpInfoContainer.m_strShortSrc = cStackInfo.short_src
			cDumpInfoContainer.m_nCurrentLine = cStackInfo.currentline
		end

		cDumpInfoContainer.m_nStackLevel = -1
	end

	local cExistTag = cDumpInfoContainer.m_cObjectExistTag
	local cNameAllAlias = cDumpInfoContainer.m_cObjectAliasName
	local cAccessTag = cDumpInfoContainer.m_cObjectAccessTag
	
	local strType = type(cObject)
	if "table" == strType then
		-- Check table with class name.
		if rawget(cObject, "__cname") then
			if "string" == type(cObject.__cname) then
				strName = strName .. "[cls:" .. cObject.__cname .. "]"
			end
		elseif rawget(cObject, "class") then
			if "string" == type(cObject.class) then
				strName = strName .. "[cls:" .. cObject.class .. "]"
			end
		elseif rawget(cObject, "_className") then
			if "string" == type(cObject._className) then
				strName = strName .. "[cls:" .. cObject._className .. "]"
			end
		end

		-- Check if table is _G.
		if cObject == _G then
			strName = strName .. "[_G]"
		end

		-- Get metatable.
		local bWeakK = false
		local bWeakV = false
		local cMt = getmetatable(cObject)
		if cMt then
			-- Check mode.
			local strMode = rawget(cMt, "__mode")
			if strMode then
				if "k" == strMode then
					bWeakK = true
				elseif "v" == strMode then
					bWeakV = true
				elseif "kv" == strMode then
					bWeakK = true
					bWeakV = true
				end
			end
		end

		-- Check if the specified object.
		if cExistTag[cObject] and (not cNameAllAlias[strName]) then
			cNameAllAlias[strName] = true
		end

		-- Add reference and name.
		if cAccessTag[cObject] then
			return
		end

		-- Get this name.
		cAccessTag[cObject] = true

		-- Dump table key and value.
		for k, v in pairs(cObject) do
			-- Check key type.
			local strKeyType = type(k)
			if "table" == strKeyType then
				if not bWeakK then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:k.t]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "function" == strKeyType then
				if not bWeakK then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:k.f]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "thread" == strKeyType then
				if not bWeakK then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:k.thrd]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			elseif "userdata" == strKeyType then
				if not bWeakK then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:k.usd]", k, cDumpInfoContainer)
				end

				if not bWeakV then
					CollectSingleObjectReferenceInMemory(strName .. ".[t:v]", v, cDumpInfoContainer)
				end
			else
				CollectSingleObjectReferenceInMemory(strName .. "." .. tostring(k), v, cDumpInfoContainer)
			end
		end

		-- Dump metatable.
		if cMt then
			CollectSingleObjectReferenceInMemory(strName ..".[mt]", cMt, cDumpInfoContainer)
		end
	elseif "function" == strType then
		-- Get function info.
		local cDInfo = debug.getinfo(cObject, "Su")
		local cCombinedName = strName .. "[line:" .. tostring(cDInfo.linedefined) .. "@file:" .. cDInfo.short_src .. "]"

		-- Check if the specified object.
		if cExistTag[cObject] and (not cNameAllAlias[cCombinedName]) then
			cNameAllAlias[cCombinedName] = true
		end

		-- Write this info.
		if cAccessTag[cObject] then
			return
		end

		-- Set name.
		cAccessTag[cObject] = true

		-- Get upvalues.
		local nUpsNum = cDInfo.nups
		for i = 1, nUpsNum do
			local strUpName, cUpValue = debug.getupvalue(cObject, i)
			local strUpValueType = type(cUpValue)
			--print(strUpName, cUpValue)
			if "table" == strUpValueType then
				CollectSingleObjectReferenceInMemory(strName .. ".[ups:t:" .. strUpName .. "]", cUpValue, cDumpInfoContainer)
			elseif "function" == strUpValueType then
				CollectSingleObjectReferenceInMemory(strName .. ".[ups:f:" .. strUpName .. "]", cUpValue, cDumpInfoContainer)
			elseif "thread" == strUpValueType then
				CollectSingleObjectReferenceInMemory(strName .. ".[ups:thrd:" .. strUpName .. "]", cUpValue, cDumpInfoContainer)
			elseif "userdata" == strUpValueType then
				CollectSingleObjectReferenceInMemory(strName .. ".[ups:usd:" .. strUpName .. "]", cUpValue, cDumpInfoContainer)
			end
		end

		-- Dump environment table.
		local getfenv = debug.getfenv
		if getfenv then
			local cEnv = getfenv(cObject)
			if cEnv then
				CollectSingleObjectReferenceInMemory(strName ..".[f:env]", cEnv, cDumpInfoContainer)
			end
		end
	elseif "thread" == strType then
		-- Check if the specified object.
		if cExistTag[cObject] and (not cNameAllAlias[strName]) then
			cNameAllAlias[strName] = true
		end

		-- Add reference and name.
		if cAccessTag[cObject] then
			return
		end

		-- Get this name.
		cAccessTag[cObject] = true

		-- Dump environment table.
		local getfenv = debug.getfenv
		if getfenv then
			local cEnv = getfenv(cObject)
			if cEnv then
				CollectSingleObjectReferenceInMemory(strName ..".[thrd:env]", cEnv, cDumpInfoContainer)
			end
		end

		-- Dump metatable.
		local cMt = getmetatable(cObject)
		if cMt then
			CollectSingleObjectReferenceInMemory(strName ..".[thrd:mt]", cMt, cDumpInfoContainer)
		end
	elseif "userdata" == strType then
		-- Check if the specified object.
		if cExistTag[cObject] and (not cNameAllAlias[strName]) then
			cNameAllAlias[strName] = true
		end

		-- Add reference and name.
		if cAccessTag[cObject] then
			return
		end

		-- Get this name.
		cAccessTag[cObject] = true

		-- Dump environment table.
		local getfenv = debug.getfenv
		if getfenv then
			local cEnv = getfenv(cObject)
			if cEnv then
				CollectSingleObjectReferenceInMemory(strName ..".[usd:env]", cEnv, cDumpInfoContainer)
			end
		end

		-- Dump metatable.
		local cMt = getmetatable(cObject)
		if cMt then
			CollectSingleObjectReferenceInMemory(strName ..".[usd:mt]", cMt, cDumpInfoContainer)
		end
    elseif "string" == strType then
        -- Check if the specified object.
        if cExistTag[cObject] and (not cNameAllAlias[strName]) then
            cNameAllAlias[strName] = true
        end

        -- Add reference and name.
        if cAccessTag[cObject] then
            return
        end

        -- Get this name.
        cAccessTag[cObject] = true
    else
        -- For "number" and "boolean" type, they are not object type, skip.
	end
end

-- The base method to dump a mem ref info result into a file.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- strRootObjectName - The header info to show the root object name, can be nil.
-- cRootObject - The header info to show the root object address, can be nil.
-- cDumpInfoResultsBase - The base dumped mem info result, nil means no compare and only output cDumpInfoResults, otherwise to compare with cDumpInfoResults.
-- cDumpInfoResults - The compared dumped mem info result, dump itself only if cDumpInfoResultsBase is nil, otherwise dump compared results with cDumpInfoResultsBase.
local function OutputMemorySnapshot(strSavePath, strExtraFileName, nMaxRescords, strRootObjectName, cRootObject, cDumpInfoResultsBase, cDumpInfoResults)
	-- Check results.
	if not cDumpInfoResults then
		return
	end

	-- Collect memory info.
	local cRefInfoBase = (cDumpInfoResultsBase and cDumpInfoResultsBase.m_cObjectReferenceCount) or nil
	local cNameInfoBase = (cDumpInfoResultsBase and cDumpInfoResultsBase.m_cObjectAddressToName) or nil
	local cRefInfo = cDumpInfoResults.m_cObjectReferenceCount
	local cNameInfo = cDumpInfoResults.m_cObjectAddressToName
	
	-- Create a cache result to sort by ref count.
	local cRes = {}
	local nIdx = 0
	for k in pairs(cRefInfo) do
		nIdx = nIdx + 1
		cRes[nIdx] = k
	end

	-- Sort result.
	table.sort(cRes, function (l, r)
		return cRefInfo[l] > cRefInfo[r]
	end)

	-- Save result to file.
	local bOutputFile = true
	local cOutputHandle = nil
	local cOutputEntry = print
	
	if bOutputFile then
		-- Combine file name.
		local strFileName = strSavePath .. strExtraFileName.."_analysis.csv"
		-- warn(">>>>>>>>>>>>>>>  strFileName = "..strFileName)
		local cFile = assert(io.open(strFileName, "w"))
		cOutputHandle = cFile
		cOutputEntry = cFile.write		
	end

	local cOutputer = function (strContent)
		if cOutputHandle then
			cOutputEntry(cOutputHandle, strContent)
		else
			cOutputEntry(strContent)
		end
		-- warn(">>>>>>>>>>>>>>>>>>> strContent = "..strContent)
	end

	-- Write table header.
	if cDumpInfoResultsBase then
		cOutputer("--------------------------------------------------------\n")
		cOutputer("-- This is compared memory information.\n")

		cOutputer("--------------------------------------------------------\n")
		cOutputer("-- Collect base memory reference at line:" .. tostring(cDumpInfoResultsBase.m_nCurrentLine) .. "@file:" .. cDumpInfoResultsBase.m_strShortSrc .. "\n")
		cOutputer("-- Collect compared memory reference at line:" .. tostring(cDumpInfoResults.m_nCurrentLine) .. "@file:" .. cDumpInfoResults.m_strShortSrc .. "\n")
	else
		cOutputer("--------------------------------------------------------\n")
		cOutputer("-- Collect memory reference at line:" .. tostring(cDumpInfoResults.m_nCurrentLine) .. "@file:" .. cDumpInfoResults.m_strShortSrc .. "\n")
	end

	cOutputer("--------------------------------------------------------\n")
	cOutputer("-- [Table/Function/String Address/Name]\t[Reference Path]\t[Reference Count]\n")
	cOutputer("--------------------------------------------------------\n")

	if strRootObjectName and cRootObject then
        if "string" == type(cRootObject) then
            cOutputer("-- From Root Object: \"" .. tostring(cRootObject) .. "\" (" .. strRootObjectName .. ")\n")
        else
            cOutputer("-- From Root Object: " .. GetOriginalToStringResult(cRootObject) .. " (" .. strRootObjectName .. ")\n")
        end
	end

	-- Save each info.
	for i, v in ipairs(cRes) do
		if (not cDumpInfoResultsBase) or (not cRefInfoBase[v]) then
			if (nMaxRescords > 0) then
				if (i <= nMaxRescords) then
                    if "string" == type(v) then                    	
                        local strOrgString = tostring(v)
                        local nPattenBegin, nPattenEnd = string.find(strOrgString, "string: \".*\"")
                        if ((not cDumpInfoResultsBase) and ((nil == nPattenBegin) or (nil == nPattenEnd))) then
                            local strRepString = string.gsub(strOrgString, "([\n\r])", "\\n")
                            cOutputer("string: \"" .. strRepString .. "\"\t" .. cNameInfo[v] .. "\t" .. tostring(cRefInfo[v]) .. "\n")
                        else
                            cOutputer(tostring(v) .. "\t" .. cNameInfo[v] .. "\t" .. tostring(cRefInfo[v]) .. "\n")
                        end                    	
                    else                    
				        if not IsInFilterList(cNameInfo[v]) then
				        	cOutputer(GetOriginalToStringResult(v) .. "\t" .. cNameInfo[v] .. "\t" .. tostring(cRefInfo[v]) .. "\n")	
				        end                    	
                    end
				end
			else
                if "string" == type(v) then
                    local strOrgString = tostring(v)
                    local nPattenBegin, nPattenEnd = string.find(strOrgString, "string: \".*\"")
                    if ((not cDumpInfoResultsBase) and ((nil == nPattenBegin) or (nil == nPattenEnd))) then
                        local strRepString = string.gsub(strOrgString, "([\n\r])", "\\n")
                        cOutputer("string: \"" .. strRepString .. "\"\t," .. cNameInfo[v] .. "\t," .. tostring(cRefInfo[v]) .. "\n")
                    else
                        cOutputer(tostring(v) .. "\t," .. cNameInfo[v] .. "\t," .. tostring(cRefInfo[v]) .. "\n")
                    end                	
				else
					if not IsInFilterList(cNameInfo[v]) then
                    	cOutputer(GetOriginalToStringResult(v) .. "\t," .. cNameInfo[v] .. "\t," .. tostring(cRefInfo[v]) .. "\n")
                    end
                end
			end
		end
	end

	if bOutputFile then
		io.close(cOutputHandle)
        cOutputHandle = nil
        print(">>>>>>>>>>>>>>>>>> finish <<<<<<<<<<<<<<<<<<<")
	end	
end

-- The base method to dump a mem ref info result of a single object into a file.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- cDumpInfoResults - The dumped results.
local function OutputMemorySnapshotSingleObject(strSavePath, strExtraFileName, nMaxRescords, cDumpInfoResults)
	-- Check results.
	if not cDumpInfoResults then
		return
	end

	-- Collect memory info.
	local cObjectAliasName = cDumpInfoResults.m_cObjectAliasName

	-- Save result to file.
	local bOutputFile = strSavePath and (string.len(strSavePath) > 0)
	local cOutputHandle = nil
	local cOutputEntry = print
	
	if bOutputFile then
		-- Check save path affix.
		local strAffix = string.sub(strSavePath, -1)
		if ("/" ~= strAffix) and ("\\" ~= strAffix) then
			strSavePath = strSavePath .. "/"
		end

		-- Combine file name.
		local strFileName = strSavePath .. "LuaMemRefInfo-Single"
		if (not strExtraFileName) or (0 == string.len(strExtraFileName)) then
            if cConfig.m_bSingleMemoryRefFileAddTime then
                strFileName = strFileName .. ".txt"
            else
                strFileName = strFileName .. ".txt"
            end
		else
            if cConfig.m_bSingleMemoryRefFileAddTime then
                strFileName = strFileName .. "-[" .. strExtraFileName .. "].txt"
            else
                strFileName = strFileName .. "-[" .. strExtraFileName .. "].txt"
            end
		end

		local cFile = assert(io.open(strFileName, "w"))
		cOutputHandle = cFile
		cOutputEntry = cFile.write
	end

	local cOutputer = function (strContent)
		if cOutputHandle then
			cOutputEntry(cOutputHandle, strContent)
		else
			cOutputEntry(strContent)
		end
	end

	-- Write table header.
	cOutputer("--------------------------------------------------------\n")
	cOutputer("-- Collect single object memory reference at line:" .. tostring(cDumpInfoResults.m_nCurrentLine) .. "@file:" .. cDumpInfoResults.m_strShortSrc .. "\n")
	cOutputer("--------------------------------------------------------\n")

	-- Calculate reference count.
	local nCount = 0
	for k in pairs(cObjectAliasName) do
		nCount = nCount + 1
	end

	-- Output reference count.
	cOutputer("-- For Object: " .. cDumpInfoResults.m_strAddressName .. " (" .. cDumpInfoResults.m_strObjectName .. "), have " .. tostring(nCount) .. " reference in total.\n")
	cOutputer("--------------------------------------------------------\n")

	-- Save each info.
	for k in pairs(cObjectAliasName) do
		if (nMaxRescords > 0) then
			if (i <= nMaxRescords) then
				cOutputer(k .. "\n")
			end
		else
			cOutputer(k .. "\n")
		end
	end

	if bOutputFile then
		io.close(cOutputHandle)
        cOutputHandle = nil
	end
end

-- Fileter an existing result file and output it.
-- strFilePath - The existing result file.
-- strFilter - The filter string.
-- bIncludeFilter - Include(true) or exclude(false) the filter.
-- bOutputFile - Output to file(true) or console(false).
local function OutputFilteredResult(strFilePath, strFilter, bIncludeFilter, bOutputFile)
	if (not strFilePath) or (0 == string.len(strFilePath)) then
		print("You need to specify a file path.")
		return
	end

	if (not strFilter) or (0 == string.len(strFilter)) then
		print("You need to specify a filter string.")
		return
	end

	-- Read file.
	local cFilteredResult = {}
    local cReadFile = assert(io.open(strFilePath, "rb"))
	for strLine in cReadFile:lines() do
		local nBegin, nEnd = string.find(strLine, strFilter)
		if nBegin and nEnd then
			if bIncludeFilter then
                nBegin, nEnd = string.find(strLine, "[\r\n]")
                if nBegin and nEnd  and (string.len(strLine) == nEnd) then
                    table.insert(cFilteredResult, string.sub(strLine, 1, nBegin - 1))
                else
				    table.insert(cFilteredResult, strLine)
                end
			end
		else
			if not bIncludeFilter then
                nBegin, nEnd = string.find(strLine, "[\r\n]")
                if nBegin and nEnd and (string.len(strLine) == nEnd) then
                    table.insert(cFilteredResult, string.sub(strLine, 1, nBegin - 1))
                else
				    table.insert(cFilteredResult, strLine)
                end
			end
		end
	end

    -- Close and clear read file handle.
    io.close(cReadFile)
    cReadFile = nil

	-- Write filtered result.
	local cOutputHandle = nil
	local cOutputEntry = print

	if bOutputFile then
		-- Combine file name.
		local _, _, strResFileName = string.find(strFilePath, "(.*)%.txt")
		strResFileName = strResFileName .. "-Filter-" .. ((bIncludeFilter and "I") or "E") .. "-[" .. strFilter .. "].txt"

		local cFile = assert(io.open(strResFileName, "w"))
		cOutputHandle = cFile
		cOutputEntry = cFile.write
	end

	local cOutputer = function (strContent)
		if cOutputHandle then
			cOutputEntry(cOutputHandle, strContent)
		else
			cOutputEntry(strContent)
		end
	end

	-- Output result.
	for i, v in ipairs(cFilteredResult) do
		cOutputer(v .. "\n")
	end

	if bOutputFile then
		io.close(cOutputHandle)
        cOutputHandle = nil
	end
end

-- Dump memory reference at current time.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- strRootObjectName - The root object name that start to search, default is "_G" if leave this to nil.
-- cRootObject - The root object that start to search, default is _G if leave this to nil.
local function DumpMemorySnapshot(strSavePath, strExtraFileName, nMaxRescords, strRootObjectName, cRootObject)
	-- Check root object.
	if cRootObject then
		if (not strRootObjectName) or (0 == string.len(strRootObjectName)) then
			strRootObjectName = tostring(cRootObject)
		end
	else
		cRootObject = debug.getregistry()
		strRootObjectName = "registry"
	end

	-- Create container.
	local cDumpInfoContainer = CreateObjectReferenceInfoContainer()
	local cStackInfo = debug.getinfo(2, "Sl")
	if cStackInfo then
		cDumpInfoContainer.m_strShortSrc = cStackInfo.short_src
		cDumpInfoContainer.m_nCurrentLine = cStackInfo.currentline
	end

	-- Collect memory info.
	CollectObjectReferenceInMemory(strRootObjectName, cRootObject, cDumpInfoContainer)
	
	-- Dump the result.
	OutputMemorySnapshot(strSavePath, strExtraFileName, nMaxRescords, strRootObjectName, cRootObject, nil, cDumpInfoContainer)
end

-- Dump compared memory reference results generated by DumpMemorySnapshot.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- cResultBefore - The base dumped results.
-- cResultAfter - The compared dumped results.
local function DumpMemorySnapshotCompared(strSavePath, strExtraFileName, nMaxRescords, cResultBefore, cResultAfter)
	-- Dump the result.
	OutputMemorySnapshot(strSavePath, strExtraFileName, nMaxRescords, nil, nil, cResultBefore, cResultAfter)
end

-- Dump compared memory reference file results generated by DumpMemorySnapshot.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- strResultFilePathBefore - The base dumped results file.
-- strResultFilePathAfter - The compared dumped results file.
local function DumpMemorySnapshotComparedFile(strSavePath, strExtraFileName, nMaxRescords, strResultFilePathBefore, strResultFilePathAfter)
	-- Read results from file.
	local cResultBefore = CreateObjectReferenceInfoContainerFromFile(strResultFilePathBefore)
	local cResultAfter = CreateObjectReferenceInfoContainerFromFile(strResultFilePathAfter)

	-- Dump the result.
	OutputMemorySnapshot(strSavePath, strExtraFileName, nMaxRescords, nil, nil, cResultBefore, cResultAfter)
end

-- Dump memory reference of a single object at current time.
-- strSavePath - The save path of the file to store the result, must be a directory path, If nil or "" then the result will output to console as print does.
-- strExtraFileName - If you want to add extra info append to the end of the result file, give a string, nothing will do if set to nil or "".
-- nMaxRescords - How many rescords of the results in limit to save in the file or output to the console, -1 will give all the result.
-- strObjectName - The object name reference you want to dump.
-- cObject - The object reference you want to dump.
local function DumpMemorySnapshotSingleObject(strSavePath, strExtraFileName, nMaxRescords, strObjectName, cObject)
	-- Check object.
	if not cObject then
		return
	end

	if (not strObjectName) or (0 == string.len(strObjectName)) then
		strObjectName = GetOriginalToStringResult(cObject)
	end

	-- Create container.
	local cDumpInfoContainer = CreateSingleObjectReferenceInfoContainer(strObjectName, cObject)
	local cStackInfo = debug.getinfo(2, "Sl")
	if cStackInfo then
		cDumpInfoContainer.m_strShortSrc = cStackInfo.short_src
		cDumpInfoContainer.m_nCurrentLine = cStackInfo.currentline
	end

	-- Collect memory info.
	CollectSingleObjectReferenceInMemory("registry", debug.getregistry(), cDumpInfoContainer)
	
	-- Dump the result.
	OutputMemorySnapshotSingleObject(strSavePath, strExtraFileName, nMaxRescords, cDumpInfoContainer)
end


-- 输出原始对比
local function OutputDiff2Ori()
	local outdir = GameUtil.GetDocumentPath() .."/Logs/"
	DumpMemorySnapshotComparedFile(outdir, "Compared", -1, "./Logs/base_analysis.csv", "./Logs/upd_analysis.csv")
end


-- 输出更新log
local function OutputRefUpdLog()
    collectgarbage("collect")
    local outdir = GameUtil.GetDocumentPath() .."/Logs/"
    DumpMemorySnapshot(outdir, "upd", -1, nil)	
end

local LuaRefTimerId = 0
local LuaVmMemCache = 0
local DectectMemChange = 5
local function OutputLuaOccupy()
	collectgarbage("collect")
	local cache = string.format("%.2f", (collectgarbage("count") / 1000)  )
	warn("****************** OutputLuaMemOccupy num(MB) = "..cache.."MB ******************")
	if LuaVmMemCache ~= 0 and (cache - LuaVmMemCache) > DectectMemChange then
		local cmp_callback = function(val)
			if val then
				OutputDiff2Ori()
			end
		end

		local upd_callback = function(val)
			if val then
				OutputRefUpdLog()
				local title, msg, closeType = StringTable.GetMsg(81)
				MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, cmp_callback)				
			end
		end

		local title, msg, closeType = StringTable.GetMsg(80)
		msg = string.format(msg, DectectMemChange)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, upd_callback)	

	end
	LuaVmMemCache = tonumber(cache)
end

-- stop
local function StopLuaMemDetect()
	_G.RemoveGlobalTimer(LuaRefTimerId)
	LuaRefTimerId = 0
	LuaVmMemCache = 0
end

-- 开启lua ref统计
local function StartLuaMemDetect()
	if LuaRefTimerId > 0 then
		StopLuaMemDetect()
	end
    LuaRefTimerId = _G.AddGlobalTimer(5, false, OutputLuaOccupy)
    LuaVmMemCache = 0
    collectgarbage("collect")
    local outdir = GameUtil.GetDocumentPath() .."/Logs/"
    DumpMemorySnapshot(outdir, "base", -1, nil)	
end


-- Return methods.
_G.LuaRefAnalysis = {Config = nil, Methods = {}, Helpers = {}, Bases = {}}
LuaRefAnalysis.Config = cConfig
LuaRefAnalysis.Methods.DumpMemorySnapshot = DumpMemorySnapshot
LuaRefAnalysis.Methods.DumpMemorySnapshotCompared = DumpMemorySnapshotCompared
LuaRefAnalysis.Methods.DumpMemorySnapshotComparedFile = DumpMemorySnapshotComparedFile
LuaRefAnalysis.Methods.DumpMemorySnapshotSingleObject = DumpMemorySnapshotSingleObject
LuaRefAnalysis.Methods.StartLuaMemDetect = StartLuaMemDetect
LuaRefAnalysis.Methods.StopLuaMemDetect = StopLuaMemDetect
LuaRefAnalysis.Methods.OutputDiff2Ori = OutputDiff2Ori
LuaRefAnalysis.Methods.OutputRefUpdLog = OutputRefUpdLog

LuaRefAnalysis.Helpers.GetOriginalToStringResult = GetOriginalToStringResult

LuaRefAnalysis.Bases.CreateObjectReferenceInfoContainer = CreateObjectReferenceInfoContainer
LuaRefAnalysis.Bases.CreateObjectReferenceInfoContainerFromFile = CreateObjectReferenceInfoContainerFromFile
LuaRefAnalysis.Bases.CreateSingleObjectReferenceInfoContainer = CreateSingleObjectReferenceInfoContainer
LuaRefAnalysis.Bases.CollectObjectReferenceInMemory = CollectObjectReferenceInMemory
LuaRefAnalysis.Bases.CollectSingleObjectReferenceInMemory = CollectSingleObjectReferenceInMemory
LuaRefAnalysis.Bases.OutputMemorySnapshot = OutputMemorySnapshot
LuaRefAnalysis.Bases.OutputMemorySnapshotSingleObject = OutputMemorySnapshotSingleObject
LuaRefAnalysis.Bases.OutputFilteredResult = OutputFilteredResult

return LuaRefAnalysis
