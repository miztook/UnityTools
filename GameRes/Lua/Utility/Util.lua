local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local Util = Lplus.Class("Util")
local def = Util.define

local function getPlayerBaseModelAssetPath(prof, gender)
	if gender == nil then
		gender = Profession2Gender[prof]
	end
	local model_path = "" 
	local prof_template = CElementData.GetProfessionTemplate(prof)
	if prof_template ~= nil then
		model_path = prof_template.MaleModelAssetPath
		if gender == EnumDef.Gender.Female then
			model_path = prof_template.FemaleModelAssetPath
		end
	end
	return model_path
end

-- 获取默认武器模板id
local function getDefaultWeaponTid(prof, gender)
	local profession = CElementData.GetProfessionTemplate(prof)
	if profession then
		local default_weapon = profession.MaleWeaponId
		if gender == EnumDef.Gender.Female then
			default_weapon = profession.FemaleWeaponId
		end
		return default_weapon
	else
		return 0
	end
end

-- 获取默认衣服模板id
local function getDefaultArmorTid(prof, gender)
	local profession = CElementData.GetProfessionTemplate(prof)
	if profession then
		local default_armor = profession.MaleArmorId
		if gender == EnumDef.Gender.Female then
			default_armor = profession.FemaleArmorId
		end
		return default_armor
	else
		return 0
	end
end

local function getArmorAssetPath(armorTid, prof, gender)
	local path = ""
	if type(armorTid) == "number" then
		if armorTid <= 0 then armorTid = getDefaultArmorTid(prof, gender) end
		if armorTid > 0 then
			local armorTemp = CElementData.GetItemTemplate(armorTid)
			if armorTemp ~= nil then 
				path = armorTemp.MaleModelAssetPath
				if gender == EnumDef.Gender.Female then	
					path = armorTemp.FemaleModelAssetPath
				end
			end
		end
		if path == "" then
			warn("ArmorAssetPath get empty, wrong armorTid:", armorTid, debug.traceback())
		end
	else
		warn("GetArmorAssetPath argument 1 \"number\" type expected, get \"" .. type(armorTid) .. "\"", debug.traceback())
	end
	return path
end

local function getWeaponAssetPaths(tid, prof, gender)
	local left_hand_asset_path, right_hand_asset_path = "", ""
	if type(tid) == "number" then
		if tid <= 0 then tid = getDefaultWeaponTid(prof, gender) end
		if tid > 0 then
			local item = CElementData.GetItemTemplate(tid)
			if item ~= nil then
				if gender == EnumDef.Gender.Male then	
					left_hand_asset_path = item.MaleLeftHandModelAssetPath
					right_hand_asset_path = item.MaleRightHandModelAssetPath
				else 
					left_hand_asset_path = item.FemaleLeftHandModelAssetPath
					right_hand_asset_path = item.FemaleRightHandModelAssetPath
				end
			end
		end
		if left_hand_asset_path == "" and right_hand_asset_path == "" then
			warn("WeaponAssetPaths get empty, wrong weaponTid:", tid, debug.traceback())
		end
	else
		warn("GetWeaponAssetPaths argument 1 \"number\" type expected, get \"" .. type(tid) .. "\"", debug.traceback())
	end
	
	return left_hand_asset_path, right_hand_asset_path
end

local function getArmorDressAssetPath(dressTid)
	local path = ""
	if type(dressTid) == "number" and dressTid > 0 then
		local dressTemp = CElementData.GetDressTemplate(dressTid)
		if dressTemp ~= nil then
			path = dressTemp.AssetPath1
		else
			warn("Can not get armor dress asset path, wrong dress id:", dressTid)
		end
	end
	return path
end

local function getWeaponDressAssetPaths(dressTid)
	local pathL, pathR = "", ""
	if type(dressTid) == "number" and dressTid > 0 then
		local dressTemp = CElementData.GetDressTemplate(dressTid)
		if dressTemp ~= nil then
			pathL = dressTemp.AssetPath1
			pathR = dressTemp.AssetPath2
		else
			warn("Can not get weapon dress asset paths, wrong dress id:", dressTid)
		end
	end
	return pathL, pathR
end

--[[
	-- 服务器定义的枚举
	public enum EnumSightUpdateType
    {
        Unknown = 0,        // 未知
        ChangeMap = 1,      // 切换地图, 包括进入, 离开, 跳转
        ChangePos = 2,      // 切换坐标, 一般指的是单位移动
        ChangeState = 3,    // 切换状态， 一般是视野内单位
    }

	public enum EnumStateChangeReasonType
    {
        Unknwon = 0,        // 未知, 默认
        Create = 1,         // 创建, 通用
        Destory = 2,        // 销毁, 通用
        CreateGenerator = 3, // 生成器创建
        DestoryGather = 4,  // 采集销毁
    }
]]

local function getWingAssetPath(wing_id, wing_level, wing_talent_page_id)
	local asset_path = ""
	if type(wing_id) == "number" and type(wing_level) == "number" and type(wing_talent_page_id) == "number" then
		if wing_id > 0 and wing_level > 0 and wing_talent_page_id > 0 then
			local CWingsMan = require "Wings.CWingsMan" 
			local wing_template = CWingsMan.Instance():GetWingData(wing_id)
			if wing_template ~= nil then
				local show_grades = string.split(wing_template.ShowGrade, "*")
				if show_grades ~= nil then
					local cur_grade = CWingsMan.Instance():CalcGradeByLevel(wing_level)
					-- 先找到对应阶级的翅膀模型路径的索引
					local index = 0
					for i, grade_str in ipairs(show_grades) do
						local grade = tonumber(grade_str)
						if grade ~= nil and grade <= cur_grade then
							index = i
						else
							break
						end
					end
					if index > 0 then
						-- 找到对应天赋页的翅膀模型
						-- PS:路径不是特效的路径，是整个翅膀模型的路径
						local special_effect_paths = nil
						if wing_talent_page_id == wing_template.WingTalentPage1 then
							special_effect_paths = string.split(wing_template.SpecialEffectPath1, "*")
						elseif wing_talent_page_id == wing_template.WingTalentPage2 then
							special_effect_paths = string.split(wing_template.SpecialEffectPath2, "*")
						elseif wing_talent_page_id == wing_template.WingTalentPage3 then
							special_effect_paths = string.split(wing_template.SpecialEffectPath3, "*")
						end
						if special_effect_paths ~= nil and special_effect_paths[index] ~= nil then
							asset_path = special_effect_paths[index]
						end
					end
				end
			else
				warn("Can not get wing asset paths, wrong wing id:", wing_id)
			end
		end
	end
	return asset_path
end

local function calcSightUpdateType(updateType, reason)
	if updateType == 3 then --  EnumSightUpdateType.ChangeState
		if reason == 1 or reason == 3 then -- Create/CreateGenerator
			return EnumDef.SightUpdateType.NewBorn
		elseif reason == 4 then -- DestoryGather 
			return EnumDef.SightUpdateType.GatherDestory
		end
	end

	return EnumDef.SightUpdateType.Unknown
end

-- 根据时装模版部位获取穿戴部位
local function getDressPartBySlot(dressSlot)
	local EDressType = require "PB.Template".Dress.eDressType
	if dressSlot == EDressType.Armor then
		return EnumDef.PlayerDressPart.Body
	elseif dressSlot == EDressType.Hat or dressSlot == EDressType.Headdress then
		return EnumDef.PlayerDressPart.Head
	elseif dressSlot == EDressType.Weapon then
		return EnumDef.PlayerDressPart.Weapon
	end
	warn("GetDressPartBySlot failed, invalid dressSlot:", dressSlot)
	return -1
end

-- 获取武器特效路径，返回值 左手后背特效，右手后背特效，左手手上特效，右手手上特效
local function getWeaponFxPaths(tid, inforveLv)
	if type(tid) ~= "number" or type(inforveLv) ~= "number" then return "", "" end
	
	local left_back_fx_path, right_back_fx_path, left_hand_fx_path, right_hand_fx_path = "", "", "", ""
	if tid > 0 and inforveLv > 0 then
		local itemTemp = CElementData.GetItemTemplate(tid) 
		if itemTemp ~= nil and itemTemp.InforceLv1 ~= 0 and inforveLv >= itemTemp.InforceLv1 then
			if inforveLv >= itemTemp.InforceLv3 and itemTemp.InforceLv3 ~= 0 then
				local lPaths = string.split(itemTemp.InforceEffectPath3_Left, "*")
				if lPaths ~= nil then
					if lPaths[1] ~= nil then
						left_back_fx_path = lPaths[1]
					end
					if lPaths[2] ~= nil then
						left_hand_fx_path = lPaths[2]
					end
				end
				local rPaths = string.split(itemTemp.InforceEffectPath3_Right, "*")
				if rPaths ~= nil then
					if rPaths[1] ~= nil then
						right_back_fx_path = rPaths[1]
					end
					if rPaths[2] ~= nil then
						right_hand_fx_path = rPaths[2]
					end
				end
			elseif inforveLv >= itemTemp.InforceLv2 and itemTemp.InforceLv2 ~= 0 then
				local lPaths = string.split(itemTemp.InforceEffectPath2_Left, "*")
				if lPaths ~= nil then
					if lPaths[1] ~= nil then
						left_back_fx_path = lPaths[1]
					end
					if lPaths[2] ~= nil then
						left_hand_fx_path = lPaths[2]
					end
				end
				local rPaths = string.split(itemTemp.InforceEffectPath2_Right, "*")
				if rPaths ~= nil then
					if rPaths[1] ~= nil then
						right_back_fx_path = rPaths[1]
					end
					if rPaths[2] ~= nil then
						right_hand_fx_path = rPaths[2]
					end
				end
			else
				local lPaths = string.split(itemTemp.InforceEffectPath1_Left, "*")
				if lPaths ~= nil then
					if lPaths[1] ~= nil then
						left_back_fx_path = lPaths[1]
					end
					if lPaths[2] ~= nil then
						left_hand_fx_path = lPaths[2]
					end
				end
				local rPaths = string.split(itemTemp.InforceEffectPath1_Right, "*")
				if rPaths ~= nil then
					if rPaths[1] ~= nil then
						right_back_fx_path = rPaths[1]
					end
					if rPaths[2] ~= nil then
						right_hand_fx_path = rPaths[2]
					end
				end
			end
		end
	end 
	return left_back_fx_path, right_back_fx_path, left_hand_fx_path, right_hand_fx_path
end

def.const("function").GetPlayerBaseModelAssetPath		= getPlayerBaseModelAssetPath
def.const("function").GetArmorAssetPath					= getArmorAssetPath
def.const("function").GetWeaponAssetPaths				= getWeaponAssetPaths
def.const("function").GetArmorDressAssetPath			= getArmorDressAssetPath
def.const("function").GetWeaponDressAssetPaths			= getWeaponDressAssetPaths
def.const("function").CalcSightUpdateType				= calcSightUpdateType
def.const("function").GetWingAssetPath					= getWingAssetPath
def.const("function").GetDressPartBySlot				= getDressPartBySlot
def.const("function").GetWeaponFxPaths					= getWeaponFxPaths

Util.Commit()
return Util