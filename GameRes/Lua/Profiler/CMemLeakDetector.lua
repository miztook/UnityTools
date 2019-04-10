-- 每一行代码的内存增长次数、大小k
-- 参考: https://zhuanlan.zhihu.com/p/27517089
local MemLeakDetector = {}

local memStat = { }
local currentMem = 0
-- 是否按行统计，否则只按文件统计
local statLine = true
local startTime = 0
local function RecordAlloc(event, lineNo)
    local memInc = collectgarbage("count") - currentMem
    -- 没涨内存就不统计
    if (memInc <= 1e-6) then return end

    -- 2nd from stack top is the func hooked
    local s = debug.getinfo(2, 'S').source

    if statLine then 
        s = string.format("%s__%d", s, lineNo - 1)
    end
    local item = memStat[s]
    if (not item) then
        memStat[s] = { s, 1, memInc }
    else
        item[2] = item[2] + 1
        item[3] = item[3] + memInc
    end

    -- 最后再读一次内存，忽略本次统计引起的增长
    currentMem = collectgarbage("count")
end

function MemLeakDetector.StartRecordAlloc(igoreLine)
    if (debug.gethook()) then
        MemLeakDetector.StopRecordAllocAndDumpStat()
        return
    end

    memStat = { }
    currentMem = collectgarbage("count")
    statLine = not igoreLine
    startTime = os.time()
    -- hook到每行执行
    debug.sethook(RecordAlloc, 'l')
end

function MemLeakDetector.StopRecordAllocAndDumpStat()
    debug.sethook()
    if (not memStat) then return end

    local sorted = { }
    for k, v in pairs(memStat) do
        table.insert(sorted, v)
    end

    -- 按内存排序
    table.sort(sorted, function(a, b) return a[3] > b[3] end)
    local filename = _G.res_base_path .. "/memAlloc.csv"
    local file = io.open(filename, "w")
    if (not file) then
        error("can't open file:", filename)
        return
    end
    file:write("fileLine, count, mem K, avg K\n")
    file:write("run time,", os.time() - startTime, "\n")
    for k, v in ipairs(sorted) do
        file:write(string.format("%s, %d, %f, %f\n", v[1], v[2], v[3], v[3] / v[2]))
    end
    file:close()

    memStat = nil
end

return MemLeakDetector