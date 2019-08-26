-- 每一行代码的内存增长次数、大小k
local memStat = { }
local currentMem = 0
local memRecord = 0
local toolMemRecord = 0
local startRecordCount = 0

local LuaMemoryProfiler = {}

local function RecordAlloc(event, lineNo)
    local currentMemInd = collectgarbage("count")
    local memInc = currentMemInd - currentMem
    -- 没涨内存就不统计
    if (memInc <= 1e-3) then return end

    memRecord = memRecord + memInc
    -- 2nd from stack top is the func hooked
    local s = debug.getinfo(2, 'S')

	local k = string.format("%s:%d", s.source, lineNo - 1)

    local item = memStat[k]
    if (not item) then
        memStat[k] = { 1, memInc }
    else
        item[1] = item[1] + 1
        item[2] = item[2] + memInc
    end
    
    -- 最后再读一次内存，忽略本次统计引起的增长
    currentMem = collectgarbage("count")
    toolMemRecord = toolMemRecord + (currentMem - currentMemInd)
end

function _G.SG_StartRecordAlloc()
    if (debug.gethook()) then
        LuaMemoryProfiler.SG_StopRecordAllocAndDumpStat()
        return
    end
    collectgarbage("stop")
    memStat = { }
    currentMem = collectgarbage("count")
    startRecordCount = currentMem
    -- hook到每行执行
    debug.sethook(RecordAlloc, 'l')
    return startRecordCount
end


function _G.SG_StopRecordAllocAndDumpStat(filename)
    debug.sethook()
    if (not memStat) then return end

    collectgarbage("restart")
    local sorted = { }
    --1 结束Mem
    local cur = collectgarbage("count")
    table.insert( sorted, cur )
    --2 总增长
    table.insert( sorted, memRecord + toolMemRecord )
    --3 统计到的Mem增长
    table.insert( sorted, memRecord )
    --4 统计工具消耗
    table.insert( sorted, toolMemRecord )

    local memSort = {}
    for k, v in pairs(memStat) do
        table.insert(memSort, {k, v[1], v[2]})
    end
    -- return sorted
    return cur, memRecord + toolMemRecord, memRecord, toolMemRecord, memSort
end

return LuaMemoryProfiler