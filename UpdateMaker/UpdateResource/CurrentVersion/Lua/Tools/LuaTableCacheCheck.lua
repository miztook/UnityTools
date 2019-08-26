local LuaTableCacheCheck = {}

local showTableIndex = 0

local TableLengthCache = {}
function _G.Hoba_TravelTableLength( )
    collectgarbage("collect")
    local memSize = collectgarbage("count")
    local visited = {}
    visited[LuaTableCacheCheck] = true
    
    local function StartTravelG(t)
        if t == nil then return end
        if type(t) ~= "table" or visited[t]  then return end
        visited[t] = true
        if type(t) == "table" then
            StartTravelG(debug.getmetatable(t))
            local len = 0
            for k,v in pairs(t) do
                len = len + 1
                if type(v) == "table" then
                    StartTravelG(v)
                end
            end
            local tt = TableLengthCache[t]
            if tt then
                tt[2] = len - tt[1]
            else
                TableLengthCache[t] = {len, 0}
            end
        end
    end

    StartTravelG(_G)

    local res = {}
    for k, v in pairs(TableLengthCache) do
        table.insert(res, {v[1], v[2]})
    end

    table.sort( res, function(a,b) return a[2] > b[2] end )

    local filename = _G.res_base_path .. "/" .. showTableIndex .. ".txt"
    local file = io.open(filename, "w")

    file:write("mem : " .. memSize .. "\n")
    file:write("childCount : " .. #res .. "\n")
    for i = 1, 100 do
        if res[i] then
            file:write(res[i][1] .. "\t" .. res[i][2] .. "\n")
        end
    end
    
    file:close()

    showTableIndex = showTableIndex + 1
end

return LuaTableCacheCheck