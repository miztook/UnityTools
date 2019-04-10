_G.HotFix = {}
local visitedSign = {}
local protection = {
    setmetatable = true,
    pairs = true,
    ipairs = true,
    next = true,
    require = true,
    _ENV = true,
}

_G.HotFixFlag = false
local protection_dir = {
    [1] = "CGame",
    [2] = "debugger/",
    [3] = "preload",
    [4] = "HotFix",
    [5] = "Profiler",
    [6] = "Platform",
    [7] = "Utility/",
    [8] = "asdadsd/",   
    [9] = "EntryPoint",   
    [10] = "protobuf/",   
    [11] = "test/",
    [12] = "CPanelMainTips",
    [13] = "CHUDTextPlayer",
    [14] = "GUITools",
    [15] = "QualitySettingMan",
    [16] = "UnityClass/", 
}


local pathes = {}
local function GetPaths(rootpath)
    pathes = pathes or {}
    require 'lfs'
    for entry in lfs.dir(rootpath) do
        if entry ~= '.' and entry ~= '..' then
            local path = rootpath..'/'..entry
            local attr = lfs.attributes(path)
            assert(type(attr) == 'table')
            if attr.mode == 'directory' then
                GetPaths(path, pathes)
            else
                if HotFix.GetExtension(path) == "lua" then
                    table.insert(pathes, path)
                end
            end
        end
    end
    return pathes
end

function HotFix.UpdateFunc(newFunc, oldFunc)
    local oldUpvalueMap = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(oldFunc, i)
        if not name then break end
        oldUpvalueMap[name] = value
    end

    for i = 1, math.huge do
        local name, value = debug.getupvalue(newFunc, i)
        if not name then break end
        local oldValue = oldUpvalueMap[name]
        if oldValue then
            if type(oldValue) ~= type(value) then
                debug.setupvalue(newFunc, i, oldValue)
            elseif type(oldValue) == 'function' then
                HotFix.UpdateFunc(value, oldValue)
            elseif type(oldValue) == 'table' then
                HotFix.UpdateTable(value, oldValue)
                debug.setupvalue(newFunc, i, oldValue)
            else
                debug.setupvalue(newFunc, i, oldValue)
            end
        end
    end
end

function HotFix.UpdateTable(newTable, oldTable)
    if protection[newTable] or protection[oldTable] then return end
    if newTable == oldTable then return end
    local signature = tostring(oldTable)..tostring(newTable)
    if visitedSign[signature] then return end
    visitedSign[signature] = true

    for name, value in pairs(newTable) do
        local oldValue = oldTable[name]
        if type(value) == type(oldValue) then
            if type(value) == 'function' then
                HotFix.UpdateFunc(value, oldValue, name)
                oldTable[name] = value
            elseif type(value) == 'table' then
                HotFix.UpdateTable(value, oldValue)
            end
        else
            oldTable[name] = value
        end
    end

    -- 刷新原表
    local old_meta = debug.getmetatable(oldTable)
    local new_meta = debug.getmetatable(newTable)
    if type(old_meta) == 'table' and type(new_meta) == 'table' then
        HotFix.UpdateTable(new_meta, old_meta)
    end
end

function HotFix.ReloadFile(chunkPath)
    -- 搭建环境
    local env = {}
    setmetatable(env, { __index = _G })
    local _ENV = env
    visitedSign = {}
    
    -- 环境隔离
    local func = loadfile(chunkPath, 't')
    if type(func) ~= "function" then -- 加载文件出错了
        warn(tostring(func) .." name = " .. tostring(chunkPath))
        return
    end
    
    setfenv(func, env) -- 设置执行环境
    local ok, newEnvTable = pcall(func)
    assert(ok, newEnvTable)

    if not ok then         
        return 
    end

    -- 获取老的环境 
    local chunkTable = string.gsub(chunkPath, "/", "%.")
    if string.sub(chunkTable, 1, 1) == "." then
        chunkTable = string.gsub(chunkTable,".", "", 1)
    end
    
    local oldEnvTable = require (chunkTable) 
    if (type(newEnvTable) == "table") and (type(oldEnvTable) == "table") then
        HotFix.UpdateTable(newEnvTable, oldEnvTable)
    else
        return
    end

    -- 刷新全局环境
    for name, value in pairs(env) do
        if newEnvTable and newEnvTable.__cname == name then
            -- to do nothing
        else
            local gValue = _G[name]
            if type(gValue) ~= type(value) then
                _G[name] = value
            elseif type(value) == 'function' then
                HotFix.UpdateFunc(value, gValue)
                _G[name] = value
            elseif type(value) == 'table' then
                HotFix.UpdateTable(value, gValue)
            end
        end
    end

    -- 环境回归
    for name, value in pairs(env) do
        env[name] = _G[name]
    end

    -- warn("\"" .. tostring(chunkPath) .. "\" hot fix success")
    return 0 
end

function HotFix.IsInBlackList(name)
    local ret = false
    for i = 1, #protection_dir do 
        if string.find(name, protection_dir[i]) then
            ret = true
            break
        end
    end
    return ret
end


function HotFix.HotFixFileChange()
    local list = HotFix.ReSetFileList()
    for i = 1, #list do
        if not HotFix.IsInBlackList(list[i]) then
            HotFix.ReloadFile(list[i])
        else
            -- warn("******  defend a file >>>>>> "..list[i])
        end
    end
    -- HotFix.ReloadFile("/GUI/CPanelBook")
end

function HotFix.GetExtension(str)  
    return str:match(".+%.(%w+)$")  
end  

function HotFix.ReSetFileList()  
    pathes = {}
    GetPaths("../GameRes/Lua")
    for i = 1, #(pathes) do
        pathes[i] = string.gsub(pathes[i],"../", "", 1)
        pathes[i] = string.gsub(pathes[i],".lua", "")
        pathes[i] = string.gsub(pathes[i],"GameRes/Lua", "")
    end
    return pathes
end

function HotFix.Split(input, delimiter)
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

  
function HotFix.HotFixCode()   
    HotFixFlag = true
    HotFix.HotFixFileChange()     
    -- HotFixFlag = false
    warn("***********HotFix  done***********")
end

return HotFix