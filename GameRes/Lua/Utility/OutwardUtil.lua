local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local OutwardUtil = Lplus.Class("OutwardUtil")
local def = OutwardUtil.define

local config = nil

def.static("number", "string", "number", "=>", "dynamic").Get = function(profId, typeKey, index)
	if config == nil then
		local ret, msg, result = pcall(dofile, "Configs/OutwardCfg.lua")
		if ret then
			config = result
		else
			warn(msg)
		end
	end
	if config == nil then return nil end

	if config[profId] ~= nil and config[profId][typeKey] ~= nil and config[profId][typeKey][index] ~= nil then
		return config[profId][typeKey][index]
	end

	return nil
end

def.static("userdata", "number", "number", "function").ChangeArmor = function(go, armorTid, prof, cb)
	local gender = Profession2Gender[prof]
	local Util = require "Utility.Util"
	local asset_path = Util.GetArmorAssetPath(armorTid, prof, gender)
	if asset_path ~= "" then
		GameUtil.ChangeOutward(go, EnumDef.EntityPart.Body, asset_path, cb)
	else
		if cb ~= nil then cb() end
	end
end


def.static("userdata", "number", "number", "function").ChangeFace = function(go, profId, id, cb)
	local asset_path = OutwardUtil.Get(profId, "Face", id)
	if asset_path == nil or type(asset_path) ~= "string" then
		warn("Can not get face cfg data, prof = " .. profId .. " id = " .. id)
		if cb ~= nil then cb() end
		return
	end
	GameUtil.ChangeOutward(go, EnumDef.EntityPart.Face, asset_path, cb)
end

def.static("userdata", "number", "number", "function").ChangeHair = function(go, profId, id, cb)
	local asset_path = OutwardUtil.Get(profId, "Hair", id)
	if asset_path == nil or type(asset_path) ~= "string" then
		warn("Can not get hair cfg data, prof = " .. profId .. " id = " .. id)
		if cb ~= nil then cb() end
		return
	end
	GameUtil.ChangeOutward(go, EnumDef.EntityPart.Hair, asset_path, cb)
end

def.static("userdata","number","number").ChangeSkinColor = function(go,profId,colorID)
	local id = OutwardUtil.Get(profId, "SkinColor", colorID)
	if id == nil then
		warn("can not GetSkinColor", colorID, "profId =", profId, debug.traceback())
		return 
	end
	local ColorConfig = require "Data.ColorConfig"
	local info = ColorConfig.GetColorInfo(id)
	if info == nil then
		warn("ColorCfg get nil, id = " .. id)
		return
	end
	GameUtil.ChangeSkinColor(go, info[1], info[2], info[3])
	--warn("SkincolorID",colorID)
	--warn("Skin A:"..info[1].."Skin B:".. info[2].."Skin C:".. info[3])
end

def.static("userdata","number","number").ChangeHairColor = function(go,profId,colorID)
	local id = OutwardUtil.Get(profId, "HairColor", colorID)
	if id == nil then
		warn("can not ChangeHairColor", colorID, "profId =", profId, debug.traceback())
		return 
	end
	local ColorConfig = require "Data.ColorConfig"
	local info = ColorConfig.GetColorInfo(id)
	if info == nil then
		warn("ColorCfg get nil, id = " .. id)
		return
	end
	GameUtil.ChangeHairColor(go, info[1], info[2], info[3])
	--warn("HaircolorID",colorID)
	--warn("Hair A:"..info[1].."Hair B:".. info[2].."Hair C:".. info[3])
end

def.static("userdata", "number", "number","function").ChangeFaceWhenCreate = function(go, profId, id,cb)
	local asset_path = OutwardUtil.Get(profId, "FaceCreate", id)
	if asset_path == nil or type(asset_path) ~= "string" then
		warn("Can not get face cfg data when create, prof = " .. profId .. " id = " .. id)
		return
	end
	GameUtil.ChangeOutward(go, EnumDef.EntityPart.Face, asset_path, cb)
end

def.static("userdata", "number", "number", "function").ChangeHairWhenCreate = function(go, profId, id,cb)
	local asset_path = OutwardUtil.Get(profId, "HairCreate", id)
	if asset_path == nil or type(asset_path) ~= "string" then
		warn("Can not get hair cfg data when create, prof = " .. profId .. " id = " .. id)
		return
	end
	GameUtil.ChangeOutward(go, EnumDef.EntityPart.Hair, asset_path, cb)
end

-- 更改时装染色
-- @param go 玩家GameObject
-- @param name 时装部位名称
-- @param dyeIdList 染色Id列表，按照部位一到部位二排序，不需要染的补0
def.static("userdata", "string", "table").ChangeDressColors = function(go, name, dyeIdList)
	if dyeIdList == nil or next(dyeIdList) == nil then return end

	local CDressUtility = require "Dress.CDressUtility"
	local EDressType = require "PB.Template".Dress.eDressType
	for part, dyeId in ipairs(dyeIdList) do
		if dyeId > 0 then
			local color = CDressUtility.GetColorInfoByDyeId(dyeId)
			if color ~= nil then
				GameUtil.ChangeDressColor(go, name, part, color)
			end
		end
	end
end

OutwardUtil.Commit()
return OutwardUtil