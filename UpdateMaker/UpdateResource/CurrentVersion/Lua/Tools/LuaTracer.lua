local codeInfo = { }
local scriptFile = {}

local LuaTracer = {}

local IsBlackList = false
local BlackList = {}
local IsWhiteList = false
local WhiteList = {}

local function SourceIsValid(sor)
    if IsBlackList then
        for k, v in ipairs(BlackList) do
            if string.find(sor, v) then
                return false
            end
        end
        return true
    elseif IsWhiteList then
        for k, v in ipairs(WhiteList) do
            if string.find(sor, v) then
                return true
            end
        end
        return false
    end
    return true
end

local function CacheScriptFile( file )
    for k, v in ipairs(scriptFile) do
        if v == file then
            return k
        end
    end
    return -1
end

local function LuaAlloc(event, lineNo)
    local s = debug.getinfo(2, 'S')

    local source = s.source
    if SourceIsValid(source) then
        local ind = CacheScriptFile(source)
        if ind ~= -1 then
            codeInfo[#codeInfo + 1] = {ind, lineNo}
        else
            local len = #scriptFile + 1
            scriptFile[len] = source
            codeInfo[#codeInfo + 1] = {len, lineNo}
        end

    end
end

function _G.LT_StartLuaTrace(isWhite, isBlack, whiteList, balckList)
    IsWhiteList = isWhite
    IsBlackList = isBlack

    BlackList = {}
    if isBlack then
        string.gsub(balckList,'[^'.. ';' ..']+',function ( w )
            table.insert(BlackList,w)
        end)
    end
    WhiteList = {}
    if isWhite then
        string.gsub(whiteList,'[^'.. ';' ..']+',function ( w )
            table.insert(WhiteList,w)
        end)
    end

    codeInfo = { }
    scriptFile = {}
    -- hook到每行执行
    debug.sethook(LuaAlloc, 'l')
    print("StartTrace")
end

function _G.LT_StopLuaTrace(filename)
    debug.sethook()
    print("StopTrace")
    print("共记录Lua行数" .. #codeInfo)
    print("共记录Lua文件数" .. #scriptFile)

    local filename = _G.res_base_path .. "/" .. "LuaTracer.csv"
    local file = io.open(filename, "w")
    for k, v in ipairs(codeInfo) do
        file:write(scriptFile[v[1]] .. " " .. v[2] .. "\n")
    end
    
    file:close()
    return scriptFile, codeInfo
end

return LuaTracer