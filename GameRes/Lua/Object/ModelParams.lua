local Lplus = require "Lplus"
local Util = require "Utility.Util"
local OutwardUtil = require "Utility.OutwardUtil"
local CDress = require "Dress.CDress"
local EDressType = require "PB.Template".Dress.eDressType

local ModelParams = Lplus.Class("ModelParams")
local def = ModelParams.define

-- 影响Model外观参数列表
-- 包装成统一结构，便于维护
def.field("number")._Prof = 0
def.field("string")._ModelAssetPath = ""
def.field("string")._ArmorAssetPath = ""
def.field("string")._FacialAssetPath = ""
def.field("string")._HairstyleAssetPath = ""
def.field("number")._HairColorId = 0
def.field("number")._SkinColorId = 0
def.field("boolean")._IsWeaponInHand = false
def.field("string")._WeaponAssetPathL = ""
def.field("string")._WeaponAssetPathR = ""
def.field("boolean")._IsChangeWing = false -- 是否更换翅膀
def.field("string")._WingAssetPath = ""
def.field("boolean")._IsChangeHeadwear = false
def.field("string")._HeadwearAssetPath = ""

def.field("boolean")._Is2ShowDress = false
def.field("table")._DressColors = BlankTable

def.field("boolean")._IsUpdateWeaponFx = false
def.field("string")._WeaponFxPathLeftBack = ""		-- 左手后背武器特效
def.field("string")._WeaponFxPathRightBack = ""		-- 右手后背武器特效
def.field("string")._WeaponFxPathLeftHand = ""		-- 左手手上武器特效
def.field("string")._WeaponFxPathRightHand = ""		-- 右手手上武器特效

def.field("string")._GUID = ""

def.static("=>", ModelParams).new = function()
	local obj = ModelParams()
	return obj
end

-- 通过新旧参数对比，获取更新用的ModelParams
def.static(ModelParams, ModelParams, "=>", ModelParams).GetUpdateParams = function (originParams , newParams)
	if originParams._Prof ~= newParams._Prof then
		warn("GetUpdateParams failed, do not have then same Prof")
		return nil
	end
	local updateParams = ModelParams.new()
	updateParams._Prof = originParams._Prof
	-- 盔甲
	if originParams._ArmorAssetPath ~= newParams._ArmorAssetPath then
		updateParams._ArmorAssetPath = newParams._ArmorAssetPath
	end

	-- 脸
	if originParams._FacialAssetPath ~= newParams._FacialAssetPath then
		updateParams._FacialAssetPath = newParams._FacialAssetPath
	end

	-- 头部
	if originParams._HairstyleAssetPath ~= newParams._HairstyleAssetPath then
		updateParams._HairstyleAssetPath = newParams._HairstyleAssetPath
	end
	if originParams._HeadwearAssetPath ~= newParams._HeadwearAssetPath then
		updateParams._IsChangeHeadwear = true
		updateParams._HeadwearAssetPath = newParams._HeadwearAssetPath
	end

	-- 发色
	if originParams._HairColorId ~= newParams._HairColorId then
		updateParams._HairColorId = newParams._HairColorId
	end
	-- 肤色
	if originParams._SkinColorId ~= newParams._SkinColorId then
		updateParams._SkinColorId = newParams._SkinColorId
	end

	-- 武器
	local isChangeWeapon = false
	local newWeaponL, newWeaponR = newParams._WeaponAssetPathL, newParams._WeaponAssetPathR
	if newWeaponL ~= originParams._WeaponAssetPathL or newWeaponR ~= originParams._WeaponAssetPathR then
		updateParams._WeaponAssetPathL, updateParams._WeaponAssetPathR = newWeaponL, newWeaponR
		updateParams._IsWeaponInHand = newParams._IsWeaponInHand
		isChangeWeapon = true
	end

	-- 武器特效
	local newWeaponFxLB, newWeaponFxRB = newParams._WeaponFxPathLeftBack, newParams._WeaponFxPathRightBack
	local newWeaponFxLH, newWeaponFxRH = newParams._WeaponFxPathLeftHand, newParams._WeaponFxPathRightHand
	if isChangeWeapon or
		newWeaponFxLB ~= originParams._WeaponFxPathLeftBack or newWeaponFxRB ~= originParams._WeaponFxPathRightBack or
		newWeaponFxLH ~= originParams._WeaponFxPathLeftHand or newWeaponFxRH ~= originParams._WeaponFxPathRightHand then
		updateParams._IsUpdateWeaponFx = true
		updateParams._WeaponFxPathLeftBack, updateParams._WeaponFxPathRightBack = newWeaponFxLB, newWeaponFxRB
		updateParams._WeaponFxPathLeftHand, updateParams._WeaponFxPathRightHand = newWeaponFxLH, newWeaponFxRH
	end

	-- 翅膀
	if originParams._WingAssetPath ~= newParams._WingAssetPath then
		updateParams._IsChangeWing = true
		updateParams._WingAssetPath = newParams._WingAssetPath
	end

	-- 时装
	updateParams._Is2ShowDress = newParams._Is2ShowDress
	if newParams._Is2ShowDress then
		updateParams._DressColors = newParams._DressColors
	end

	updateParams._GUID = newParams._GUID
	
	return updateParams
end

-- 更新加载参数
def.method(ModelParams).Update = function (self, updateParams)
	-- 骨骼
	if updateParams._ModelAssetPath ~= "" then
		self._ModelAssetPath = updateParams._ModelAssetPath
	end
	-- 衣服
	if updateParams._ArmorAssetPath ~= "" then
		self._ArmorAssetPath = updateParams._ArmorAssetPath
	end
	-- 脸型
	if updateParams._FacialAssetPath ~= "" then
		self._FacialAssetPath = updateParams._FacialAssetPath
	end
	-- 发型
	if updateParams._HairstyleAssetPath ~= "" then
		self._HairstyleAssetPath = updateParams._HairstyleAssetPath
	end
	-- 发色Id
	if updateParams._HairColorId > 0 then
		self._HairColorId = updateParams._HairColorId
	end
	-- 肤色Id
	if updateParams._SkinColorId > 0 then
		self._SkinColorId = updateParams._SkinColorId
	end
	-- 武器挂点
	if updateParams._IsWeaponInHand ~= self._IsWeaponInHand then
		self._IsWeaponInHand = updateParams._IsWeaponInHand
	end
	-- 武器左
	if updateParams._WeaponAssetPathL ~= "" then
		self._WeaponAssetPathL = updateParams._WeaponAssetPathL
	end
	-- 武器右
	if updateParams._WeaponAssetPathR ~= "" then
		self._WeaponAssetPathR = updateParams._WeaponAssetPathR
	end
	-- 翅膀
	self._IsChangeWing = false
	if updateParams._IsChangeWing then
		self._WingAssetPath = updateParams._WingAssetPath
	end
	-- 头饰
	self._IsChangeHeadwear = false
	if updateParams._IsChangeHeadwear then
		self._HeadwearAssetPath = updateParams._HeadwearAssetPath
	end
	-- 时装显隐
	if updateParams._Is2ShowDress ~= self._Is2ShowDress then
		self._Is2ShowDress = updateParams._Is2ShowDress
	end
	-- 时装颜色
	if updateParams._Is2ShowDress then
		self._DressColors = updateParams._DressColors
	end
	-- 武器特效
	self._IsUpdateWeaponFx = false
	if updateParams._IsUpdateWeaponFx then
		self._WeaponFxPathLeftBack = updateParams._WeaponFxPathLeftBack
		self._WeaponFxPathRightBack = updateParams._WeaponFxPathRightBack
		self._WeaponFxPathLeftHand = updateParams._WeaponFxPathLeftHand
		self._WeaponFxPathRightHand = updateParams._WeaponFxPathRightHand
	end

	if updateParams._GUID ~= "" then
		self._GUID = updateParams._GUID
	end
end

def.method("table", "number").MakeParam = function(self, exteriorInfo, prof)
	local gender = Profession2Gender[prof]
	self._ModelAssetPath = Util.GetPlayerBaseModelAssetPath(prof, gender)

	self._Is2ShowDress = exteriorInfo.DressFirstShow
	-- 显示优先级：非默认时装 > 武器装备 > 默认时装
	-- 衣服
	local armorAssetPath = ""
	local hairAssetPath = ""
	local headwearAssetPath = ""
	local weaponAssetPathL, weaponAssetPathR = "", ""
	if exteriorInfo.DressFirstShow then
		for _, info in ipairs(exteriorInfo.DressWear) do
			if info.Tid > 0 and info.InsId > 0 then
				local data = CDress.new(info)
				if data then
					-- 染色信息
					self._DressColors[data._DressSlot] = CDress.CopyColors(data)

					if data._DressSlot == EDressType.Armor then
						-- 服饰
						armorAssetPath = data._Template.AssetPath1
					elseif data._DressSlot == EDressType.Headdress then
						-- 头饰
						headwearAssetPath = data._Template.AssetPath1
					elseif data._DressSlot == EDressType.Hat then
						-- 帽子
						hairAssetPath = data._Template.AssetPath1
					elseif data._DressSlot == EDressType.Weapon then
						-- 武器
						weaponAssetPathL = data._Template.AssetPath1
						weaponAssetPathR = data._Template.AssetPath2
					end
				end
			end
		end
	end
	
	if armorAssetPath == "" then
		local armorTid = exteriorInfo.ArmorTId
		if armorTid == nil then
			armorTid = 0
		end
		armorAssetPath = Util.GetArmorAssetPath(armorTid, prof, gender)
	end
	self._ArmorAssetPath = armorAssetPath
	-- 武器
	local weaponTid = exteriorInfo.WeaponTId
	if weaponTid == nil then
		weaponTid = 0
	end
	if weaponAssetPathL == "" and weaponAssetPathR == "" then
		weaponAssetPathL, weaponAssetPathR = Util.GetWeaponAssetPaths(weaponTid, prof, gender)
		-- 武器特效
		self._WeaponFxPathLeftBack, self._WeaponFxPathRightBack, self._WeaponFxPathLeftHand, self._WeaponFxPathRightHand = Util.GetWeaponFxPaths(weaponTid, exteriorInfo.WeaponInforceLevel)
	end
	self._WeaponAssetPathL, self._WeaponAssetPathR = weaponAssetPathL, weaponAssetPathR
	self._IsUpdateWeaponFx = true
	-- 脸部
	if exteriorInfo.Face.FacialId > 0 then
		self._FacialAssetPath = OutwardUtil.Get(prof, "Face", exteriorInfo.Face.FacialId)
	else
		warn("ModelParams MakeParams FacialId must be greater than 0")
	end
	-- 发型
	if exteriorInfo.Face.HairstyleId > 0 then
		if hairAssetPath == "" then
			hairAssetPath = OutwardUtil.Get(prof, "Hair", exteriorInfo.Face.HairstyleId)
		end
	else
		warn("ModelParams MakeParams HairstyleId must be greater than 0")
	end
	self._HairstyleAssetPath = hairAssetPath
	-- 头饰
	if headwearAssetPath ~= "" then
		self._IsChangeHeadwear = true
		self._HeadwearAssetPath = headwearAssetPath
	end
	-- 翅膀
	self._IsChangeWing = true
	self._WingAssetPath = Util.GetWingAssetPath(exteriorInfo.WingTId, exteriorInfo.WingLevel, exteriorInfo.WingTalentPageID)

	self._Prof = prof
	self._HairColorId = exteriorInfo.Face.HairColorId
	self._SkinColorId = exteriorInfo.Face.SkinColorId
	self._IsWeaponInHand = false
end

def.method("number", "number", CDress).SetHeadParam = function (self, hairstyleId, hairColorId, headDressInfo)
	if hairstyleId <= 0 then return end
	if self._Prof <= 0 then
		warn("SetHeadParam failed, please set _Prof first", debug.traceback())
		return
	end

	if headDressInfo ~= nil and self._Is2ShowDress then
		if headDressInfo._DressSlot == EDressType.Headdress then
			-- 头饰
			self._IsChangeHeadwear = true
			self._HeadwearAssetPath = headDressInfo._Template.AssetPath1
			self._HairstyleAssetPath = OutwardUtil.Get(self._Prof, "Hair", hairstyleId)
			self._HairColorId = hairColorId
			self._DressColors[EDressType.Headdress] = CDress.CopyColors(headDressInfo)
		elseif headDressInfo._DressSlot == EDressType.Hat then
			-- 帽子
			self._HeadwearAssetPath = ""
			self._HairstyleAssetPath = headDressInfo._Template.AssetPath1
			self._DressColors[EDressType.Hat] = CDress.CopyColors(headDressInfo)
		end
	else
		self._HeadwearAssetPath = ""
		self._HairstyleAssetPath = OutwardUtil.Get(self._Prof, "Hair", hairstyleId)
		self._HairColorId = hairColorId
	end
end

def.method("number", CDress).SetArmorParam = function (self, armorTid, armorDressInfo)
	if self._Prof <= 0 then
		warn("SetArmorParam failed, please set _Prof first", debug.traceback())
		return
	end

	if armorDressInfo ~= nil and self._Is2ShowDress then
		if armorDressInfo._DressSlot == EDressType.Armor then
			self._ArmorAssetPath = Util.GetArmorDressAssetPath(armorDressInfo._Tid)
			self._DressColors[EDressType.Armor] = CDress.CopyColors(armorDressInfo)
		end
	else
		local gender = Profession2Gender[self._Prof]
		self._ArmorAssetPath = Util.GetArmorAssetPath(armorTid, self._Prof, gender)
	end
end

def.method("number", "number", CDress).SetWeaponParam = function (self, weaponTid, weaponInforceLv, weaponDressInfo)
	if self._Prof <= 0 then
		warn("SetWeaponParam failed, please set _Prof first", debug.traceback())
		return
	end

	if weaponDressInfo ~= nil and self._Is2ShowDress then
		if weaponDressInfo._DressSlot == EDressType.Weapon then
			self._WeaponAssetPathL, self._WeaponAssetPathR = Util.GetWeaponDressAssetPaths(weaponDressInfo._Tid)
			self._DressColors[EDressType.Weapon] = CDress.CopyColors(weaponDressInfo)
			self._IsUpdateWeaponFx = true
			self._WeaponFxPathLeftBack, self._WeaponFxPathRightBack, self._WeaponFxPathLeftHand, self._WeaponFxPathRightHand = "", "", "", ""
		end
	else
		local gender = Profession2Gender[self._Prof]
		self._WeaponAssetPathL, self._WeaponAssetPathR = Util.GetWeaponAssetPaths(weaponTid, self._Prof, gender)
		self._IsUpdateWeaponFx = true
		self._WeaponFxPathLeftBack, self._WeaponFxPathRightBack, self._WeaponFxPathLeftHand, self._WeaponFxPathRightHand = Util.GetWeaponFxPaths(weaponTid, weaponInforceLv)
	end
end

-- 打印ModelParams（测试用）
def.method("string").PrintModelParams = function (self, tag)
	warn("[PrintModelParams] tag:" .. tag, debug.traceback())
	local str = "ModelParams Info:"
	str = str .. "\nProf: " .. self._Prof
	str = str .. "\nGUID: " .. self._GUID
	str = str .. "\nModelPath: " .. self._ModelAssetPath
	str = str .. "\nArmorPath: " .. self._ArmorAssetPath
	str = str .. "\nFacialPath: " .. self._FacialAssetPath
	str = str .. "\nHairstylePath: " .. self._HairstyleAssetPath
	str = str .. "\nHairColorId: " .. self._HairColorId
	str = str .. "\nSkinColorId: " .. self._SkinColorId
	str = str .. "\nIsWeaponInHand: " .. tostring(self._IsWeaponInHand)
	str = str .. "\nWeaponAssetPathL: " .. self._WeaponAssetPathL
	str = str .. "\nWeaponAssetPathR: " .. self._WeaponAssetPathR
	str = str .. "\nIsUpdateWeaponFx: " .. tostring(self._IsUpdateWeaponFx)
	str = str .. "\nWeaponFxPathLeftBack: " .. self._WeaponFxPathLeftBack
	str = str .. "\nWeaponFxPathRigthBack: " .. self._WeaponFxPathRightBack
	str = str .. "\nWeaponFxPathLeftHand: " .. self._WeaponFxPathLeftHand
	str = str .. "\nWeaponFxPathRigthHand: " .. self._WeaponFxPathRightHand
	str = str .. "\nIsChangeWing: " .. tostring(self._IsChangeWing)
	str = str .. "\nWingPath: " .. self._WingAssetPath
	str = str .. "\nIsChangeHeadwear: " .. tostring(self._IsChangeHeadwear)
	str = str .. "\nHeadwearPath:" .. self._HeadwearAssetPath
	str = str .. "\nIsShowDress: " .. tostring(self._Is2ShowDress)
	str = str .. "\nDressColors:"
	for slot, colors in pairs(self._DressColors) do
		local dressStr = "\n\tDressSlot: " .. slot
		for i, v in ipairs(colors) do
			dressStr = dressStr .. "\n\t\tDyePart:" .. i .. ", DyeId:" .. v
		end
		str = str .. dressStr
	end
	warn(str)
end

ModelParams.Commit()
return ModelParams