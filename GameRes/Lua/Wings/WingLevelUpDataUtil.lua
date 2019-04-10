-- 获取优化后的翅膀升级数据

local Lplus = require "Lplus"
local WingLevelUpDataUtil = Lplus.Class("WingLevelUpDataUtil")
local def = WingLevelUpDataUtil.define

local data = nil
-- 获取翅膀升级模版ID
def.static("number", "number", "=>", "number").GetTid = function(wingId, wingLevel)
	if data == nil then
		local ret, msg, result = pcall(dofile, "Configs/WingLevelUpData.lua")
		if ret then
			data = result
		else
			warn(msg)
		end
	end
	if data == nil then return 0 end

	if data[wingId] ~= nil and type(data[wingId][wingLevel]) == "number" then
		return data[wingId][wingLevel]
	end

	return 0
end

WingLevelUpDataUtil.Commit()
return WingLevelUpDataUtil