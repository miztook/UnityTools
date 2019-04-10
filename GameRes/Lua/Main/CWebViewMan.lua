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
--������C#����������ҳ��Ϣ������һ��table
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
--������URL֮ǰ����head��ֵ�ԡ�
-----------------------------------------------------------------
def.static("userdata", "table").AddWebViewURLHeads = function(webview, data)
    if webview == nil then return end
    for key,value in pairs(data)do
        webview:SetHeaderField(key,value)
    end
end

CWebViewMan.Commit()
return CWebViewMan
