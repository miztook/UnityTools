--[[--

提供一组常用函数，以及对 Lua 标准库的扩展

]]

--[[--

输出格式化字符串

~~~ lua

printf("The value = %d", 100)

~~~

@param string fmt 输出格式
@param [mixed ...] 更多参数

]]
function printf(fmt, ...)
    print(string.format(tostring(fmt), ...))
end

--[[--

检查并尝试转换为数值，如果无法转换则返回 0

@param mixed value 要检查的值
@param [integer base] 进制，默认为十进制

@return number

]]
function checknumber(value, base)
    return tonumber(value, base) or 0
end

--[[--

检查并尝试转换为整数，如果无法转换则返回 0

@param mixed value 要检查的值

@return integer

]]
function checkint(value)
    return math.round(checknumber(value))
end

--[[--

检查并尝试转换为布尔值，除了 nil 和 false，其他任何值都会返回 true

@param mixed value 要检查的值

@return boolean

]]
function checkbool(value)
    return (value ~= nil and value ~= false)
end

--[[--

检查值是否是一个表格，如果不是则返回一个空表格

@param mixed value 要检查的值

@return table

]]
function checktable(value)
    if type(value) ~= "table" then value = {} end
    return value
end

--[[--

如果表格中指定 key 的值为 nil，或者输入值不是表格，返回 false，否则返回 true

@param table hashtable 要检查的表格
@param mixed key 要检查的键名

@return boolean

]]
function isset(hashtable, key)
    local t = type(hashtable)
    return (t == "table" or t == "userdata") and hashtable[key] ~= nil
end

--[[--

深度克隆一个值

~~~ lua

-- 下面的代码，t2 是 t1 的引用，修改 t2 的属性时，t1 的内容也会发生变化
local t1 = {a = 1, b = 2}
local t2 = t1
t2.b = 3    -- t1 = {a = 1, b = 3} <-- t1.b 发生变化

-- clone() 返回 t1 的副本，修改 t2 不会影响 t1
local t1 = {a = 1, b = 2}
local t2 = clone(t1)
t2.b = 3    -- t1 = {a = 1, b = 2} <-- t1.b 不受影响

~~~

@param mixed object 要克隆的值

@return mixed

]]
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

--[[--

载入一个模块

import() 与 require() 功能相同，但具有一定程度的自动化特性。

假设我们有如下的目录结构：

~~~

app/
app/classes/
app/classes/MyClass.lua
app/classes/MyClassBase.lua
app/classes/data/Data1.lua
app/classes/data/Data2.lua

~~~

MyClass 中需要载入 MyClassBase 和 MyClassData。如果用 require()，MyClass 内的代码如下：

~~~ lua

local MyClassBase = require("app.classes.MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = require("app.classes.data.Data1")
local Data2 = require("app.classes.data.Data2")

~~~

假如我们将 MyClass 及其相关文件换一个目录存放，那么就必须修改 MyClass 中的 require() 命令，否则将找不到模块文件。

而使用 import()，我们只需要如下写：

~~~ lua

local MyClassBase = import(".MyClassBase")
local MyClass = class("MyClass", MyClassBase)

local Data1 = import(".data.Data1")
local Data2 = import(".data.Data2")

~~~

当在模块名前面有一个"." 时，import() 会从当前模块所在目录中查找其他模块。因此 MyClass 及其相关文件不管存放到什么目录里，我们都不再需要修改 MyClass 中的 import() 命令。这在开发一些重复使用的功能组件时，会非常方便。

我们可以在模块名前添加多个"." ，这样 import() 会从更上层的目录开始查找模块。

~

不过 import() 只有在模块级别调用（也就是没有将 import() 写在任何函数中）时，才能够自动得到当前模块名。如果需要在函数中调用 import()，那么就需要指定当前模块名：

~~~ lua

# MyClass.lua

# 这里的 ... 是隐藏参数，包含了当前模块的名字，所以最好将这行代码写在模块的第一行
local CURRENT_MODULE_NAME = ...

local function testLoad()
    local MyClassBase = import(".MyClassBase", CURRENT_MODULE_NAME)
    # 更多代码
end

~~~

@param string moduleName 要载入的模块的名字
@param [string currentModuleName] 当前模块名

@return module

]]
function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n,v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end

--[[--

将 Lua 对象及其方法包装为一个匿名函数

在 quick-cocos2d-x 中，许多功能需要传入一个 Lua 函数做参数，然后在特定事件发生时就会调用传入的函数。例如触摸事件、帧事件等等。

~~~ lua

local MyScene = class("MyScene", function()
    return display.newScene("MyScene")
end)

function MyScene:ctor()
    self.frameTimeCount = 0
    -- 注册帧事件
    self:addEventListener(cc.ENTER_FRAME_EVENT, self.onEnterFrame)
end

function MyScene:onEnterFrame(dt)
    self.frameTimeCount = self.frameTimeCount + dt
end

~~~

上述代码执行时将出错，报告"Invalid self" ，这就是因为 C++ 无法识别 Lua 对象方法。因此在调用我们传入的 self.onEnterFrame 方法时没有提供正确的参数。

要让上述的代码正常工作，就需要使用 handler() 进行一下包装：

~~~ lua

function MyScene:ctor()
    self.frameTimeCount = 0
    -- 注册帧事件
    self:addEventListener(cc.ENTER_FRAME_EVENT, handler(self, self.onEnterFrame))
end

~~~

实际上，除了 C++ 回调 Lua 函数之外，在其他所有需要回调的地方都可以使用 handler()。

@param mixed obj Lua 对象
@param function method 对象方法

@return function

]]
function handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

--[[--

对数值进行四舍五入，如果不是数值则返回 0

@param number value 输入值

@return number

]]
function math.round(value)
    return math.floor(value + 0.5)
end

function math.angle2radian(angle)
	return angle*math.pi/180
end

function math.radian2angle(radian)
	return radian/math.pi*180
end

--[[--

检查指定的文件或目录是否存在，如果存在返回 true，否则返回 false

可以使用 CCFileUtils:fullPathForFilename() 函数查找特定文件的完整路径，例如：

~~~ lua

local path = CCFileUtils:sharedFileUtils():fullPathForFilename("gamedata.txt")
if io.exists(path) then
    ....
end

~~~

@param string path 要检查的文件或目录的完全路径

@return boolean

]]
function io.exists(path)
    local file = io.open(path, "r")
    if file then
        io.close(file)
        return true
    end
    return false
end

--[[--

读取文件内容，返回包含文件内容的字符串，如果失败返回 nil

io.readfile() 会一次性读取整个文件的内容，并返回一个字符串，因此该函数不适宜读取太大的文件。

@param string path 文件完全路径

@return string

]]
function io.readfile(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        io.close(file)
        return content
    end
    return nil
end

--[[--

以字符串内容写入文件，成功返回 true，失败返回 false

"mode 写入模式" 参数决定 io.writefile() 如何写入内容，可用的值如下：

-   "w+" : 覆盖文件已有内容，如果文件不存在则创建新文件
-   "a+" : 追加内容到文件尾部，如果文件不存在则创建文件

此外，还可以在 "写入模式" 参数最后追加字符 "b" ，表示以二进制方式写入数据，这样可以避免内容写入不完整。

**Android 特别提示:** 在 Android 平台上，文件只能写入存储卡所在路径，assets 和 data 等目录都是无法写入的。

@param string path 文件完全路径
@param string content 要写入的内容
@param [string mode] 写入模式，默认值为 "w+b"

@return boolean

]]
function io.writefile(path, content, mode)
    mode = mode or "w+b"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

--[[--

拆分一个路径字符串，返回组成路径的各个部分

~~~ lua

local pathinfo  = io.pathinfo("/var/app/test/abc.png")

-- 结果:
-- pathinfo.dirname  = "/var/app/test/"
-- pathinfo.filename = "abc.png"
-- pathinfo.basename = "abc"
-- pathinfo.extname  = ".png"

~~~

@param string path 要分拆的路径字符串

@return table

]]
function io.pathinfo(path)
    local pos = string.len(path)
    local extpos = pos + 1
    while pos > 0 do
        local b = string.byte(path, pos)
        if b == 46 then -- 46 = char "."
            extpos = pos
        elseif b == 47 then -- 47 = char "/"
            break
        end
        pos = pos - 1
    end

    local dirname = string.sub(path, 1, pos)
    local filename = string.sub(path, pos + 1)
    extpos = extpos - pos
    local basename = string.sub(filename, 1, extpos - 1)
    local extname = string.sub(filename, extpos)
    return {
        dirname = dirname,
        filename = filename,
        basename = basename,
        extname = extname
    }
end

--[[--

返回指定文件的大小，如果失败返回 false

@param string path 文件完全路径

@return integer

]]
function io.filesize(path)
    local size = false
    local file = io.open(path, "r")
    if file then
        local current = file:seek()
        size = file:seek("end")
        file:seek("set", current)
        io.close(file)
    end
    return size
end

--[[--

计算表格包含的字段数量

Lua table 的 "#" 操作只对依次排序的数值下标数组有效，table.nums() 则计算 table 中所有不为 nil 的值的个数。

@param table t 要检查的表格

@return integer

]]
function table.nums(t)
    if t == nil or type(t) ~= "table" then return 0 end

    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function table.isEmpty(t)
    if t == nil or table.nums(t) == 0 then
        return true 
    end
    return false
end

function table.front(t)
    if type(t) ~= "table" or table.isEmpty(t) then
        return nil
    end
    return t[1]
end

function table.back(t)
    if type(t) ~= "table" or table.isEmpty(t) then
        return nil
    end
    return t[#t]
end

function table.pop_back(t)
    if type(t) ~= "table" or table.isEmpty(t) then
        return nil
    end
    local value = t[#t]
    table.remove(t, #t)
    return value
end

function table.pop_front(t)
    if type(t) ~= "table" or table.isEmpty(t) then
        return nil
    end
    local value = t[1]
    table.remove(t, 1)
    return value
end

--[[

从表格中查找指定值，返回其索引，如果没找到返回 false

~~~ lua

local array = {"a", "b", "c"}
print(table.indexof(array, "b")) -- 输出 2

~~~

@param table array 表格
@param mixed value 要查找的值
@param [integer begin] 起始索引值

@return integer

]]
function table.indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

--[[--

返回指定表格中的所有键

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local keys = table.keys(hashtable)
-- keys = {"a", "b", "c"}

~~~

@param table hashtable 要检查的表格

@return table

]]
function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

--[[--

返回指定表格中的所有值

~~~ lua

local hashtable = {a = 1, b = 2, c = 3}
local values = table.values(hashtable)
-- values = {1, 2, 3}

~~~

@param table hashtable 要检查的表格

@return table

]]
function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

--[[--

将来源表格中所有键及其值复制到目标表格对象中，如果存在同名键，则覆盖其值

~~~ lua

local dest = {a = 1, b = 2}
local src  = {c = 3, d = 4}
table.merge(dest, src)
-- dest = {a = 1, b = 2, c = 3, d = 4}

~~~

@param table dest 目标表格
@param table src 来源表格

]]
function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

--[[--

在目标表格的指定位置插入来源表格，如果没有指定位置则连接两个表格

~~~ lua

local dest = {1, 2, 3}
local src  = {4, 5, 6}
table.insertto(dest, src)
-- dest = {1, 2, 3, 4, 5, 6}

dest = {1, 2, 3}
table.insertto(dest, src, 5)
-- dest = {1, 2, 3, nil, 4, 5, 6}

~~~

@param table dest 目标表格
@param table src 来源表格
@param [integer begin] 插入位置

]]
function table.insertto(dest, src, begin)
	begin = checkint(begin)
	if begin <= 0 then
		begin = #dest + 1
	end

	local len = #src
	for i = 0, len - 1 do
		dest[i + begin] = src[i + 1]
	end
end


--[[--

从表格中查找指定值，返回其 key，如果没找到返回 nil

~~~ lua

local hashtable = {name = "dualface", comp = "chukong"}
print(table.keyof(hashtable, "chukong")) -- 输出 comp

~~~

@param table hashtable 表格
@param mixed value 要查找的值

@return string 该值对应的 key

]]
function table.keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

--[[--

从表格中删除指定值，返回删除的值的个数

~~~ lua

local array = {"a", "b", "c", "c"}
print(table.removebyvalue(array, "c", true)) -- 输出 2

~~~

@param table array 表格
@param mixed value 要删除的值
@param [boolean removeall] 是否删除所有相同的值

@return integer

]]
function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

--[[--

对表格中每一个值执行一次指定的函数，并用函数返回值更新表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.map(t, function(v, k)
    -- 在每一个值前后添加括号
    return "[" .. v .. "]"
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
    print(k, v)
end

-- 输出
-- name [dualface]
-- comp [chukong]

~~~

fn 参数指定的函数具有两个参数，并且返回一个值。原型如下：

~~~ lua

function map_function(value, key)
    return value
end

~~~

@param table t 表格
@param function fn 函数

]]
function table.map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

--[[--

对表格中每一个值执行一次指定的函数，但不改变表格内容

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.walk(t, function(v, k)
    -- 输出每一个值
    print(v)
end)

~~~

fn 参数指定的函数具有两个参数，没有返回值。原型如下：

~~~ lua

function map_function(value, key)

end

~~~

@param table t 表格
@param function fn 函数

]]
function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

--[[--

对表格中每一个值执行一次指定的函数，如果该函数返回 false，则对应的值会从表格中删除

~~~ lua

local t = {name = "dualface", comp = "chukong"}
table.filter(t, function(v, k)
    return v ~= "dualface" -- 当值等于 dualface 时过滤掉该值
end)

-- 输出修改后的表格内容
for k, v in pairs(t) do
    print(k, v)
end

-- 输出
-- comp chukong

~~~

fn 参数指定的函数具有两个参数，并且返回一个 boolean 值。原型如下：

~~~ lua

function map_function(value, key)
    return true or false
end

~~~

@param table t 表格
@param function fn 函数

]]
function table.filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

--[[--

遍历表格，确保其中的值唯一

~~~ lua

local t = {"a", "a", "b", "c"} -- 重复的 a 会被过滤掉
local n = table.unique(t)

for k, v in pairs(n) do
    print(v)
end

-- 输出
-- a
-- b
-- c

~~~

@param table t 表格

@return table 包含所有唯一值的新表格

]]
function table.unique(t)
    local check = {}
    local n = {}
    for k, v in pairs(t) do
        if not check[v] then
            n[k] = v
            check[v] = true
        end
    end
    return n
end


--[[--

获得table长度

@param table t 表格

@return number 

]]
function table.count(t)
    local count = 0
    if t ~= nil and type(t) == "table" then
        for k,v in pairs(t) do
            count = count + 1
        end
    end
    return count
end

--[[--

用指定字符或字符串分割输入字符串，返回包含分割结果的数组

~~~ lua

local input = "Hello,World"
local res = string.split(input, ",")
-- res = {"Hello", "World"}

local input = "Hello-+-World-+-Quick"
local res = string.split(input, "-+-")
-- res = {"Hello", "World", "Quick"}

~~~

@param string input 输入字符串
@param string delimiter 分割标记字符或字符串

@return array 包含分割结果的数组

]]
function string.split(input, delimiter)
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

--[[--

去除输入字符串头部的空白字符，返回结果

~~~ lua

local input = "  ABC"
print(string.ltrim(input))
-- 输出 ABC，输入字符串前面的两个空格被去掉了

~~~

空白字符包括：

-   空格
-   制表符 \t
-   换行符 \n
-   回到行首符 \r

@param string input 输入字符串

@return string 结果

@see string.rtrim, string.trim

]]
function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end

--[[--

去除输入字符串尾部的空白字符，返回结果

~~~ lua

local input = "ABC  "
print(string.ltrim(input))
-- 输出 ABC，输入字符串最后的两个空格被去掉了

~~~

@param string input 输入字符串

@return string 结果

@see string.ltrim, string.trim

]]
function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end

--[[--

去掉字符串首尾的空白字符，返回结果

@param string input 输入字符串

@return string 结果

@see string.ltrim, string.rtrim

]]
function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

--[[--

将字符串的第一个字符转为大写，返回结果

~~~ lua

local input = "hello"
print(string.ucfirst(input))
-- 输出 Hello

~~~

@param string input 输入字符串

@return string 结果

]]
function string.ucfirst(input)
    return string.upper(string.sub(input, 1, 1)) .. string.sub(input, 2)
end

local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

--[[--

将字符串转换为符合 URL 传递要求的格式，并返回转换结果

~~~ lua

local input = "hello world"
print(string.urlencode(input))
-- 输出
-- hello%20world

~~~

@param string input 输入字符串

@return string 转换后的结果

@see string.urldecode

]]
function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

--[[--

将 URL 中的特殊字符还原，并返回结果

~~~ lua

local input = "hello%20world"
print(string.urldecode(input))
-- 输出
-- hello world

~~~

@param string input 输入字符串

@return string 转换后的结果

@see string.urlencode

]]
function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h,16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

--[[--

计算 UTF8 字符串的长度，每一个中文算一个字符

~~~ lua

local input = "你好World"
print(string.utf8len(input))
-- 输出 7

~~~

@param string input 输入字符串

@return integer 长度

]]
function string.utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end
        cnt = cnt + 1
    end
    return cnt
end

--[[--

将数值格式化为包含千分位分隔符的字符串

~~~ lua

print(string.formatnumberthousands(1924235))
-- 输出 1,924,235

~~~

@param number num 数值

@return string 格式化结果

]]
function string.formatnumberthousands(num)
    local formatted = tostring(checknumber(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function AsyncLoadArray(arr, onfinish, ...)
    local ret = {}

    if #arr == 0 then
        onfinish(ret)
    end
    
    local count = 0
    
    local function _onload (i, obj)
        ret[i] = obj
        count = count + 1
        
        if count == #arr then
            onfinish(ret)
        end
    end

    for i = 1, #arr do
        GameUtil.AsyncLoad(arr[i], function(obj)
            _onload(i, obj)
        end, ...)
    end
end

function printf(format, ...)
    local str = ""  
    for i = 1, n do
        str = string.format(format, str, tostring(arg[i]))
    end
    print(str)
end

function traceback(msg)
    msg = debug.traceback(msg, 2)
    return msg
end

--unity 对象判断为空, 如果你有些对象是在c#删掉了，lua 不知道
--判断这种对象为空时可以用下面这个函数
--上述操作属于不合理操作，会给出警告信息  -- added by lj
function IsNil(uobj)
    if uobj == nil then return true end
    if type(uobj) == "userdata" and uobj:Equals(nil) then
        warn("GameObject has been destroyed, but Lua ref has not been cleared. Need to Fix!!", debug.traceback())
        return true
    end

    return false
end

function FormatFunctionInfo(f)
    local info = debug.getinfo(f, "S")
    return ("%s:%d")
        :format(tostring(info.source), tostring(info.linedefined))
end

function CreateEmptyProtocol(protName)
    local protocols = require "PB.net"
    local msg = protocols[protName]
    if msg == nil then
        warn("can")
        return nil
    else
        return msg()
    end
end

function SendProtocol2Server(msg)
    local PBHelper = require "Network.PBHelper"
    PBHelper.Send(msg)
end

function InvalidTime(endTime)
    return endTime - Time.time <= 0
end

function IsNilOrEmptyString(str)
    return str == nil or string.len(str) <= 0
end

function IsNilOrEmptyStringCheckAndTip(str)
    if IsNilOrEmptyString(str) then
        game._GUIMan:ShowTipText(StringTable.Get(19135),false)
        return true
    end
    return false
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."[",pos,"] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(tostring(pos))+8))
                        print(indent..string.rep(" ",string.len(tostring(pos))+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."[",pos,'] => "'..val..'"')
                    else
                        print(indent.."[",pos,"] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function hasSameItem(t,item)
    local bRet = false
    for k,v in pairs(t) do
        if v == item then
            bRet = true
            break
        end
    end

    return bRet
end

-- table 泛型元素去重
function removeRepeated(t)
    if type(t)~="table" or next(t)==nil then return end

    local count=#t
    if count > 1 then
        local removeIndexs = {}
        for k=1,count do
            for i=k+1,count do
                if t[k]==t[i] then
                    if not hasSameItem(removeIndexs, i) then
                        table.insert(removeIndexs, i)
                    end
                end
            end
        end
        local removeCount = #removeIndexs
        if removeCount > 0 then
            table.sort(removeIndexs, function(a,b) return a < b end)
            for i=1,removeCount do
                local index = removeCount-i+1
                table.remove(t, removeIndexs[removeCount-i+1])
            end
        end
    end
end

_G.table_has_function = function(t)
    local has_function = false

    local print_r_cache={}
    local function sub_print_r(t)
        if not print_r_cache[tostring(t)] then
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        sub_print_r(val)
                    elseif (type(val)=="function") then
                        has_function = true
                    end
                end
            end
        end
    end
    sub_print_r(t)
    return has_function
end

--fix float精度 输出float
_G.fixFloat = function(val, digit)
    local result = val+0.000001
    if digit ~= nil then
        if digit > 0 then
            local fmtCntStr = string.format("%%0.%df", digit)
            result = tonumber(string.format(fmtCntStr,math.floor(result * 10^digit) / 10^digit))
        else
            result = math.floor(result)
        end
    end

    return result
end

--fix float精度 输出字符串
_G.fixFloatStr = function(val, digit)
    local result = ""
    if digit ~= nil then
        local fmtCntStr = string.format("%%0.%df", digit)
        result = string.format(fmtCntStr, fixFloat(val, digit))
    else
        result = string.format("%0.2f", fixFloat(val, 2))
    end

    return result
end

--[[保存2位小数位格式化函数，为0时忽略]]
_G.fmtVal2Str = function(val)
    local fixVal = fixFloat(val)
    local result = 0
    result = (fixVal * 100)
    result = result % 100

    local resultStr = ""
    if result < 1 then
        resultStr = string.format("%0.0f", fixVal)
    else
        result = (fixVal * 1000)
        result = fixFloat(result)
        result = result % 10

        if result < 1 then
            resultStr = string.format("%0.1f", fixVal)
        else
            resultStr = string.format("%0.2f", fixVal)
        end
    end

    return resultStr
end

_G.fixFloor = function(val, digit)
    local result = val+0.000001
    if digit ~= nil then
        result = result * (10 ^ digit)
        result = math.floor(result)
        result = result / (10 ^ digit)
    else
        result = math.floor(result)
    end

    return result
end