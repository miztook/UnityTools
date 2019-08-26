local Lplus = require "Lplus"

local CWebViewMan = Lplus.Class("CWebViewMan")
local def = CWebViewMan.define


local instance = nil
def.static("=>", CWebViewMan).Instance = function ()
    if instance == nil then
	    instance = CWebViewMan()
    end
	return instance
end

-----------------------------------------------------------------
--解析从C#穿过来的网页消息，返回一个table
-----------------------------------------------------------------
def.static("string", "=>", "table").ParseWebViewMsg = function(msg)
    local msgs = {}
    local args = string.split(msg, ",")
    for i,v in ipairs(args) do
        if v ~= "" and v ~= nil then
            local kv = string.split(v, "#")
            if #kv ==2 then
                msgs[kv[1]] = kv[2]
            else
                warn("WebView msg parse error !!")
            end
        end
    end
    return msgs
end

-----------------------------------------------------------------
--在请求URL之前设置head键值对。
-----------------------------------------------------------------
def.static("userdata", "table").AddWebViewURLHeads = function(webview, data)
    if webview == nil then return end
    for key,value in pairs(data)do
        webview:SetHeaderField(key,value)
    end
end

CWebViewMan.Commit()
return CWebViewMan
