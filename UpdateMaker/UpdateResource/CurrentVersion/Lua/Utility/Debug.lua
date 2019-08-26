

--[[--

定义一个作废的接口

]]
function DEPRECATED(f, name, newname)
    return function(...)
        PRINT_DEPRECATED(string.format("%s() is deprecated, please use %s()", name, newname))
        return f(...)
    end
end

--[[--

显示作废信息

]]
function PRINT_DEPRECATED(msg)
    printf("[DEPRECATED] %s", msg)
end

--[[--

打印调试信息

### 用法示例

~~~ lua

printLog("WARN", "Network connection lost at %d", os.time())

~~~

@param string tag 调试信息的 tag
@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printLog(tag, fmt, ...)
    local t = {
        "[",
        string.upper(tostring(tag)),
        "] ",
        string.format(tostring(fmt), ...)
    }
    print(table.concat(t))
end

--[[--

输出 tag 为 ERR 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printError(fmt, ...)
    warn("[ERR]" .. string.format(tostring(fmt), ...))
    warn(debug.traceback("", 2))
end

--[[--

输出 tag 为 INFO 的调试信息

@param string fmt 调试信息格式
@param [mixed ...] 更多参数

]]
function printInfo(fmt, ...)
    printLog("INFO", fmt, ...)
end

--[[--

输出值的内容

### 用法示例

~~~ lua

local t = {comp = "chukong", engine = "quick"}

dump(t)

~~~

@param mixed value 要输出的值

@param [string desciption] 输出内容前的文字描述

@parma [integer nesting] 输出时的嵌套层级，默认为 3

]]
function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end

local print_file_and_line = false

function print(...)
    lprint(...)
    if print_file_and_line then
        local info = debug.getinfo(2, "nSl")
        local line_file_info = ""
        if info ~= nil then
            line_file_info = string.format("[%s line:%-4d]", info.source or "", info.currentline)
        end
        lprint(line_file_info)
    end
end

function warn(...)
    lwarn(...)
    if print_file_and_line then
        local info = debug.getinfo(2, "nSl")
        local line_file_info = ""
        if info ~= nil then
            line_file_info = string.format("[%s line:%-4d]", info.source or "", info.currentline)
        end
        lwarn(line_file_info)
    end
end

function trace(...)
    warn(...)
    warn(debug.traceback())
end
