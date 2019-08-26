local Lplus = require "Lplus"

local ModuleProfDiffConfig = Lplus.Class("ModuleProfDiffConfig")
local def = ModuleProfDiffConfig.define

def.static("string", "=>", "table").GetModuleInfo = function( strType )
	local tableInfo = _G.ModuleProfDiffCfgTable

	if tableInfo ~= nil and tableInfo[strType] ~= nil then
		return tableInfo[strType]
	end
	
	return nil
end

-- 根据是否上马和职业，获取相机视点的默认高度
def.static("number", "boolean", "=>", "number").GetCamViewPointDefaultHeightOffset = function (prof, isRide)
	local heightOffset = isRide and 1.8 or 1.25
	local heightOffsetInfo = ModuleProfDiffConfig.GetModuleInfo("CameraViewPointHeightOffset")
	if heightOffsetInfo ~= nil then
		local info = isRide and heightOffsetInfo.DefaultMount or heightOffsetInfo.DefaultNormal
		if info ~= nil then
			local value = info[prof]
			if type(value) == "number" then
				heightOffset = value
			end
		end
	end
	return heightOffset
end

-- 根据是否上马和职业，获取跟随相机视点高度的区间
def.static("number", "boolean", "=>", "number", "number").GetFollowCamViewPointHeightOffsetInterval = function (prof, isRide)
	local heightOffsetMin = isRide and 1.8 or 1.25
	local heightOffsetMax = isRide and 1.8 or 1.25
	local heightOffsetInfo = ModuleProfDiffConfig.GetModuleInfo("CameraViewPointHeightOffset")
	if heightOffsetInfo ~= nil then
		local minInfo = isRide and heightOffsetInfo.FollowMountMin or heightOffsetInfo.FollowNormalMin
		if minInfo ~= nil then
			local value = minInfo[prof]
			if type(value) == "number" then
				heightOffsetMin = value
			end
		end
		local maxInfo = isRide and heightOffsetInfo.FollowMountMax or heightOffsetInfo.FollowNormalMax
		if maxInfo ~= nil then
			local value = maxInfo[prof]
			if type(value) == "number" then
				heightOffsetMax = value
			end
		end
	end
	return heightOffsetMin, heightOffsetMax
end

-- 获取外观相机坐骑页不上马的参数
def.static("number", "=>", "number", "number", "number", "number", "number").GetExteriorCamHorseDefaultParams = function (prof)
	local yaw, pitch, distance, height, min_distance = 300, 3, 5, 1.25, 1 -- 五项默认值
	local exteriorCamInfo = ModuleProfDiffConfig.GetModuleInfo("ExteriorCameraParams")
	local profInfo = exteriorCamInfo.Horse.Default[prof]
	if profInfo ~= nil then
		yaw, pitch, distance, height, min_distance = profInfo[1], profInfo[2], profInfo[3], profInfo[4], profInfo[5]
	end
	return yaw, pitch, distance, height, min_distance
end

-- 根据坐骑ID，获取外观相机坐骑页的参数
def.static("number", "number", "=>", "number", "number", "number", "number", "number").GetExteriorCamHorseParams = function (prof, horseId)
	local yaw, pitch, distance, height, min_distance = 300, 3, 5, 1.25, 1 -- 五项默认值
	local exteriorCamInfo = ModuleProfDiffConfig.GetModuleInfo("ExteriorCameraParams")
	local horseInfo = exteriorCamInfo.Horse[horseId]
	if horseInfo ~= nil then
		local profInfo = horseInfo[prof]
		if profInfo ~= nil then
			yaw, pitch, distance, height, min_distance = profInfo[1], profInfo[2], profInfo[3], profInfo[4], profInfo[5]
		end
	end
	return yaw, pitch, distance, height, min_distance
end

-- 根据时装部位，获取外观相机时装页的参数
def.static("number", "number", "=>", "number", "number", "number", "number", "number").GetExteriorCamDressParams = function (prof, dressPart)
	local yaw, pitch, distance, height, min_distance = 300, 3, 5, 1.25, 1 -- 五项默认值
	local exteriorCamInfo = ModuleProfDiffConfig.GetModuleInfo("ExteriorCameraParams")

	local dressInfo = exteriorCamInfo.Dress.Body
	if dressPart == EnumDef.PlayerDressPart.Weapon then
		dressInfo = exteriorCamInfo.Dress.Weapon
	elseif dressPart == EnumDef.PlayerDressPart.Head then
		dressInfo = exteriorCamInfo.Dress.Head
	end
	local profInfo = dressInfo[prof]
	if profInfo ~= nil then
		yaw, pitch, distance, height, min_distance = profInfo[1], profInfo[2], profInfo[3], profInfo[4], profInfo[5]
	end
	return yaw, pitch, distance, height, min_distance
end

-- 获取外观相机翅膀页的参数
def.static("number", "=>", "number", "number", "number", "number", "number").GetExteriorCamWingParams = function (prof)
	local yaw, pitch, distance, height, min_distance = 300, 3, 5, 1.25, 1 -- 五项默认值
	local exteriorCamInfo = ModuleProfDiffConfig.GetModuleInfo("ExteriorCameraParams")
	local profInfo = exteriorCamInfo.Wing[prof]
	if profInfo ~= nil then
		yaw, pitch, distance, height, min_distance = profInfo[1], profInfo[2], profInfo[3], profInfo[4], profInfo[5]
	end
	return yaw, pitch, distance, height, min_distance
end

ModuleProfDiffConfig.Commit()
return ModuleProfDiffConfig