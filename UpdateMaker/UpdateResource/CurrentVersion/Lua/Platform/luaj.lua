--[[--

Lua 与 Java 的交互接口

]]
local luaj = {}

local callJavaStaticMethod = CLuaJavaBridge.CallStaticMethod

--[[--

私有方法

]]
local function checkArguments(args, sig)
    if type(args) ~= "table" then args = {} end
    if sig then return args, sig end

    sig = {"("}
    for i, v in ipairs(args) do
        local t = type(v)
        if t == "number" then
            sig[#sig + 1] = "F"
        elseif t == "boolean" then
            sig[#sig + 1] = "Z"
        elseif t == "function" then
            sig[#sig + 1] = "I"
        else
            sig[#sig + 1] = "Ljava/lang/String;"
        end
    end
    sig[#sig + 1] = ")V"

    return args, table.concat(sig)
end

--[[--

调用java类的接口。

只能调用java类的静态方法

@param string className java类名
@param string methodName java类静态方法名
@param table args java类静态方法所需要的各种参数 数组
@param [string sig] java类方法的签名

@return boolean ok, mixed ret ok为是否调用成功, ok为true时,ret为java方法的返回值,ok为false时,ret为出错原因

]]
function luaj.callStaticMethod(className, methodName, args, sig)
    local args, sig = checkArguments(args, sig)
    printInfo("luaj.callStaticMethod(\"%s\",\n\t\"%s\",\n\targs,\n\t\"%s\"", className, methodName, sig)
    return CallJavaStaticMethod(className, methodName, args, sig)
end

return luaj
