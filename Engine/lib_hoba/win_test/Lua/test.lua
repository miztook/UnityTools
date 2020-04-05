local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

function _G.GetLuaMemory()
	return collectgarbage("count")
end

_G.GetTemplateData = function (name, id)
	return CElementData.GetTemplate(name, id)
end 

print("Hello,Lua!")

--[[
local tb = setmetatable({id = 1}, {
  __index = function(t, key)
    if key == "id" then
      return t[key]
    else
      return rawget(t, "id") + 1000
    end
  end
})

print(tb.id)
print(tb.wdsf)
]]

--local data = GetTemplateData("MonsterProperty", 10001)
--print(data.Name)

--[[
local S1 = snapshot()

local tmp = {1,2}

local S2 = snapshot()

for k,v in pairs(S2) do
	if S1[k] == nil then
		print(k,v)
	end
end
]]
