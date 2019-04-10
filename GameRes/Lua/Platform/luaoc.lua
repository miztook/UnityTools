
--[[--

Lua 与 Objective-C 的交互接口

]]
local luaoc = {}

local CallStaticMethod = CLuaObjcBridge.CallStaticMethod

--[[--

调用Object-C类的接口。

只能调用Object-C类的类方法

@param string className Object-C类名
@param string methodName Object-C类方法名
@param table args Object-C类方法所需要的各种参数字典,key值为方法的参数名

@return boolean ok, mixed ret ok为是否调用成功, ok为true时,ret为java方法的返回值,ok为false时,ret为出错原因

]]
function luaoc.callStaticMethod(className, methodName, args)
    local ok, ret = CallStaticMethod(className, methodName, args)
    if not ok then
        local msg = string.format("luaoc.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ",
                className, methodName, tostring(args), tostring(ret))
        if ret == -1 then
            printError(msg .. "INVALID PARAMETERS")
        elseif ret == -2 then
            printError(msg .. "CLASS NOT FOUND")
        elseif ret == -3 then
            printError(msg .. "METHOD NOT FOUND")
        elseif ret == -4 then
            printError(msg .. "EXCEPTION OCCURRED")
        elseif ret == -5 then
            printError(msg .. "INVALID METHOD SIGNATURE")
        else
            printError(msg .. "UNKNOWN")
        end
    end
    return ok, ret
end

return luaoc
