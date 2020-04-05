local Lplus = require "Lplus"

local GameConfig = Lplus.Class("GameConfig")
local def = GameConfig.define

local config = nil

def.static("string", "=>", "dynamic").Get = function(key)
	if config == nil then
		local ret, msg, result = pcall(dofile, "Configs/GameCfg.lua")
		if ret then
			config = result
		else
			warn(msg)
		end
	end
	if config == nil then return nil end

	return config[key]
end

GameConfig.Commit()
return GameConfig