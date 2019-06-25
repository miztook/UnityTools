local Lplus = require "Lplus"
local CModel = require "Object.CModel"
local CDressUtility = require "Dress.CDressUtility"
local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
local ModelParams = require "Object.ModelParams"

local CUIModel = Lplus.Class("CUIModel")
local def = CUIModel.define

def.field("number")._ShowType = 0 				-- All
def.field("string")._ModelAssetPath = ""		-- 主模型AssetPath
def.field(ModelParams)._ModelParams = nil       -- 为了好维护，将以下相关数据包装成 ModelParams 结构

def.field('userdata')._RoleImg = nil 			-- 背景UI图片
def.field('userdata')._ImageModelComp = nil

def.field("function")._CallbackWhenInit = nil
def.field("table")._OnLoadedCallbacks = nil
def.field(CModel)._Model = nil
-- def.field("number")._ModelHeight = 0
def.field("number")._RenderLayer = -1

-- 标记相关
def.field("boolean")._ModelLoaded = false
def.field("boolean")._SelfDestroyed = false

def.field("table")._DialogCfg = nil
def.field("table")._ImgRoleCfg = nil

---- UI Light and referrence count
-- local _UILightRefCount = 0
-- local _UILight = nil

-- 测试用 
local _IM_table = { }

-- new
def.static("dynamic", "userdata", "number", "number", "function", "=>", CUIModel).new = function(entityInfo, roleImge, showType, renderLayer, cb)
	if IsNil(roleImge) then
		warn("CUIModel.new roleImge is  nil")
		return nil
	end

	if _IM_table[roleImge] ~= nil then
		warn("IM: GImgeModel is still used by other cuimodel! " .. roleImge.name .. " -> " .. tostring(_IM_table[roleImge]))
		-- return nil
	end

	local obj = CUIModel()

	_IM_table[roleImge] = obj
	obj._RoleImg = roleImge
	obj._ImageModelComp = obj._RoleImg:GetComponent(ClassType.GImageModel)

	do
		if type(entityInfo) == "string" then
			-- 此时参数未ModelAssetPath
			obj._ModelAssetPath = entityInfo
			obj._ModelParams = nil
		elseif Lplus.is(entityInfo, ModelParams) then
			-- 此时参数为影响外形的参数列表
			obj._ModelAssetPath = entityInfo._ModelAssetPath
			obj._ModelParams = entityInfo
		else
			warn("error params type @ CUIModel.Init")
		end

		obj._ShowType = showType
		obj._RenderLayer = renderLayer

		if cb == nil then
			cb = function() obj:PlayAnimation(EnumDef.CLIP.COMMON_STAND) end
		end
		obj._CallbackWhenInit = cb

		obj:PrivateLoad()
	end
	return obj
end

--Release GImageModel in C#
def.method().ReleaseGIMComp = function(self)
	if _IM_table[self._RoleImg] == self then
		_IM_table[self._RoleImg] = nil
	end

	self._RoleImg = nil
	if not IsNil(self._ImageModelComp) then
		self._ImageModelComp:SetModel(nil)
	end
	self._ImageModelComp=nil
end

-- Load model asset, dont call from outside
def.method().PrivateLoad = function(self)
	self:DestroyModel()

	if self._ModelParams == nil then
		local asset_path = self._ModelAssetPath
		if asset_path ~= nil and asset_path ~= "" then
			local m = CModel.new()
			self._Model = m
			local function CallBack(ret)
				if ret then
					self:OnModelLoaded()
					-- self:SetupUILight()
				else
					warn("Fail to load ui model, asset path = ", asset_path)
				end
			end
			m:Load(asset_path, CallBack)
		end
	else
		if self._ShowType == EnumDef.UIModelShowType.NoWing or self._ShowType == EnumDef.UIModelShowType.OnlySelf then
			self._ModelParams._IsChangeWing = false
			self._ModelParams._WingAssetPath = ""
		end
		if self._ShowType == EnumDef.UIModelShowType.NoWeapon or self._ShowType == EnumDef.UIModelShowType.OnlySelf then
			self._ModelParams._WeaponAssetPathL = ""
			self._ModelParams._WeaponAssetPathR = ""
			self._ModelParams._IsUpdateWeaponFx = true
			self._ModelParams._WeaponFxPathLeftBack = ""
			self._ModelParams._WeaponFxPathRightBack = ""
			self._ModelParams._WeaponFxPathLeftHand = ""
			self._ModelParams._WeaponFxPathRightHand = ""
		end

		local m = CModel.new()
		self._Model = m
		local function CallBack()
			self:OnModelLoaded()
			-- self:SetupUILight()
		end
		m:LoadWithModelParams(self._ModelParams, CallBack)
	end
end

-- 外形部件显隐的解析
-- EnumDef.UIModelShowType:
-- All 						完整原型
-- NoWing 					不含翅膀
-- NoWeapon 				不含武器
-- OnlySelf					什么都不带
def.method().OnModelLoaded = function(self)
	if self._SelfDestroyed then

		if self._Model ~= nil and self._Model._GameObject ~= nil then
			warn("ImageModel already destroyed " .. GameUtil.GetScenePath(self._Model._GameObject.Name))
		end

		self:DestroyModel()
		return
	end

--	--    _UILightRefCount = _UILightRefCount + 1
--	--    print("CUIModel ref count INC " .. _UILightRefCount)
--	----    --self:SetupUILight()

	if not IsNil(self._ImageModelComp) then

--		if self._ImageModelComp.HasModel then
--			warn("ImageModel Has Model : " .. GameUtil.GetScenePath(self._RoleImg))
--			self:DestroyModel()
--			return
--		end

		local go = self._Model._GameObject
		if IsNil(go) then return end

		go.name = "UIPlayer"

		GameUtil.SetLayerRecursively(go, self._RenderLayer)
		game._GUIMan:RefUILight(1)

		self._ImageModelComp:SetModel(go)
		self._ModelLoaded = true

		self._CallbackWhenInit(self)

		if self._OnLoadedCallbacks then
			for i, v in ipairs(self._OnLoadedCallbacks) do
				v(self)
			end
			self._OnLoadedCallbacks = nil
		end

		return
	end

end

-- 具体处理回调
def.method("function").AddLoadedCallback = function(self, cb)
	if self._ModelLoaded and not self._SelfDestroyed then
		cb(self)
	else
		if self._OnLoadedCallbacks == nil then
			self._OnLoadedCallbacks = { }
		end
		self._OnLoadedCallbacks[#self._OnLoadedCallbacks + 1] = cb
	end
end

-- UnLoad model asset
def.method().DestroyModel = function(self)
	if self._Model ~= nil then
		game._GUIMan:RefUILight(-1)
		--        _UILightRefCount = _UILightRefCount - 1
		--        print("CUIModel ref count DEC " .. _UILightRefCount)
		--        ----self:SetupUILight()
		self._Model:Destroy()
		self._Model = nil
	end

	if not IsNil(self._ImageModelComp) then
		self._ImageModelComp:UnLoadModel()		--will keep gui camera
	end

	self._ModelLoaded = false
end

---- setup UI Light param
-- def.method().SetupUILight = function(self)
--    if _UILight == nil then
--        local light = GameObject.Find("UILight")

--        print("Light "..light.name)
--        if light ~= nil then
--            --light.rotation = Quaternion.Euler(22.5, 340, 0)
--            _UILight = light:GetComponent(ClassType.Light)
--            if _UILight ~= nil then
--            	_UILight.enabled = true

--                -- something more...

--            end
--        else
--            error("UILight not found!!!")
--        end
--    end

----    if _UILight ~= nil then
----        _UILight.enabled = _UILightRefCount > 0
----        --print("UILight "..tostring(_UILight.enabled))
----    end
-- end

def.method("string").PlayAnimation = function(self, aniname)
	if not self._ModelLoaded or self._SelfDestroyed then
		warn("error occur in PlayAnimation, uimodel")
		return
	end

	local model = self._Model
	if model ~= nil then
		model:PlayAnimation(aniname, 0, false, 0, 1)
	end
end

def.method("string", 'boolean').PlayAnimationQueue = function(self, aniname, bIsQueue)
	if not self._ModelLoaded or self._SelfDestroyed then
		warn("error occur in PlayAnimationQueue, uimodel")
		return
	end

	local model = self._Model
	if model ~= nil then
		model:PlayAnimation(aniname, 0, bIsQueue, 0, 1)
	end
end

def.method("number", "number", "number").SetColor = function(self, r, g, b)
	-- if IsNil(self._RoleImg) then return end

	local imgModel = self._ImageModelComp
	-- img:GetComponent(ClassType.GImageModel)
	if not IsNil(imgModel) then
		imgModel:SetColor(r, g, b)
	end
end

def.method("number", "number", "number", "number", "number", "number", "number").SetLookAtParam = function(self, camSize, posx, posy, posz, rotx, roty, rotz)
	-- if IsNil(self._RoleImg) then return end

	local imgModel = self._ImageModelComp
	-- img:GetComponent(ClassType.GImageModel)
	if not IsNil(imgModel) then
--		if posx == nil or roty == nil then
--			imgModel:SetLookAtParam(camSize, posy)
--		else
			imgModel:SetLookAtParam(camSize, posx, posy, posz, rotx, roty, rotz)
--		end
	end
end

def.method("number").SetCameraSize = function(self, camSize)
	-- if IsNil(self._RoleImg) then return end

	local imgModel = self._ImageModelComp
	-- img:GetComponent(ClassType.GImageModel)
	if not IsNil(imgModel) then
		imgModel:SetCameraSize(camSize)
	end
end

--def.method("number").SetLookAtPosY = function(self, posy)
--	-- if IsNil(self._RoleImg) then return end

--	local imgModel = self._ImageModelComp
--	-- img:GetComponent(ClassType.GImageModel)
--	if not IsNil(imgModel) then
--		imgModel:SetLookAtPosY(posy)
--	end
--end

def.method("table").AlignSystemWithDir = function(self, dir)
	-- local imageModel = self._RoleImg:GetComponent(ClassType.GImageModel)
	local imgModel = self._ImageModelComp
	-- img:GetComponent(ClassType.GImageModel)
	if imgModel ~= nil then
		imgModel:AlignSystemWithModelForward(dir)
	end
end

---- Play on another GImageModel 有巨大问题 不许打开
--def.method("userdata", "boolean").ChangeTargetImage = function(self, img, bPlayStandAni)
--	if img == self._RoleImg then return end

--	local ui_m=_IM_table[img]
--	ui_m:Destroy()

--	self:AddLoadedCallback( function()
--		self:ReleaseGIMComp()
--		if IsNil(img) then return end
--		local im = img:GetComponent(ClassType.GImageModel)
--		if not IsNil(im) then
--			_IM_table[img] = self
--			self._RoleImg = img
--			self._ImageModelComp=im

--			self._ImageModelComp:SetModel(self._Model._GameObject)

--			-- 需要默认播放站立动作时，参数填true
--			if bPlayStandAni then
--				local ani = self._Model._GameObject:GetComponent(ClassType.AnimationUnit)
--				if not IsNil(ani) then
--					ani:PlayAnimation(EnumDef.CLIP.COMMON_STAND, 0, false, 0, false, 1)
--				end
--			end
--		end
--	end )
--end

def.method("=>", "userdata").GetGameObject = function(self)
	if not self._ModelLoaded or self._SelfDestroyed then return nil end
	return self._Model._GameObject
end

-- 此接口只接受同种类型参数的更新
def.method("dynamic").Update = function(self, newParams)
	if newParams == nil then return end

	-- 暂时不支持不同类型参数之间的Model复用
	if (self._ModelParams == nil and type(newParams) ~= "string") or(self._ModelParams ~= nil and not Lplus.is(newParams, ModelParams)) then
		return
	end

	if self._ModelParams == nil then
		if newParams ~= "" and self._ModelAssetPath ~= newParams then

			self._OnLoadedCallbacks = nil
--			-- warn("Update destroy")
--			if not IsNil(self._ImageModelComp) then
--				self._ImageModelComp:SetModel(nil)
--			end
--			--self:DestroyModel()
			self._ModelAssetPath = newParams
			--self._ModelLoaded = false

			self:PrivateLoad()
		end
	elseif self._ModelAssetPath == newParams._ModelAssetPath then
		self:AddLoadedCallback( function()
			--            -- 当参数为number类型时，只能换基础模型 （主要针对NPC对话模板上的模型更新）
			--            if self._ModelParams == nil then
			--                if newParams ~= "" and self._ModelAssetPath ~= newParams then
			--                    self:DestroyModel()
			--                    local m = CModel.new()
			--                    self._Model = m
			--                    local function cb(ret)
			--                        if ret then
			--                            self:OnModelLoaded()
			--                        end
			--                    end

			--                    self._ModelAssetPath = newParams
			--                    self._ModelLoaded = false
			--                    m:Load(newParams, cb)
			--                end
			--                -- 当参数为ModelParams类型时，基础模型保持不变 （主要针对主角外形的变化）
			--            elseif self._ModelAssetPath == newParams._ModelAssetPath then
			local go = self._Model._GameObject
			if IsNil(go) then return end

			local updateParams = ModelParams.GetUpdateParams(self._ModelParams, newParams)
			if updateParams ~= nil then
				-- newParams:PrintModelParams("CUIModel Update new guid:" .. newParams._GUID)
				-- self._ModelParams:PrintModelParams("CUIModel Update cur")
				-- updateParams:PrintModelParams("CUIModel Update")
				self._ModelParams = newParams
				if self._ShowType == EnumDef.UIModelShowType.NoWing or self._ShowType == EnumDef.UIModelShowType.OnlySelf then
					updateParams._IsChangeWing = false
					updateParams._WingAssetPath = ""
				end
				if self._ShowType == EnumDef.UIModelShowType.NoWeapon or self._ShowType == EnumDef.UIModelShowType.OnlySelf then
					updateParams._WeaponAssetPathL = ""
					updateParams._WeaponAssetPathR = ""
					updateParams._IsUpdateWeaponFx = true
					updateParams._WeaponFxPathLeftBack = ""
					updateParams._WeaponFxPathRightBack = ""
					updateParams._WeaponFxPathLeftHand = ""
					updateParams._WeaponFxPathRightHand = ""
				end
				self._Model:UpdateWithModelParams(updateParams, function()
					GameUtil.SetLayerRecursively(go, self._RenderLayer)
				end )
			end
			-- end
		end )
	else
		warn("IM: Cannot update player model, different path, try destroy and new")
	end
end

---- 按职业数据，设置相机Size和模型偏移
-- def.method("number").SetDefaultLookAtByProfession = function(self, profession)
--    if IsNil(self._RoleImg) then return end

--    --warn("SetDefaultLookAtByProfession")

--    -- 分职业模型角度显示
--    local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
--    local im_param = ModuleProfDiffConfig.GetModuleInfo("ImageModelParam")[profession]

--    local imageModel = self._RoleImg:GetComponent(ClassType.GImageModel)
--    if not IsNil(imageModel) then
--        imageModel:SetLookAtParam(im_param.Size, im_param.OffsetY)
--        imageModel:SetCameraAngle(im_param.CamPitch, 0, 0)
--        imageModel:ShowGroundShadow(im_param.Shadow)
--    end
-- end

---- 按Dialog数据，设置相机Size和模型偏移
-- def.method("boolean").SetDialogConfig = function(self, param)
--    local keyword = self._ModelAssetPath
--    local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
--    local cfgList = ModuleProfDiffConfig.GetModuleInfo("DialogueImageModelParam")

--    if cfgList == nil then return end

--        local index = 1
--        if is_left then
--            index = 2
--        end

--    local item = cfgList[keyword]
--    if item == nil or item[index] == nil then
--        item = cfgList["default"]
--    end

--    if item ~= nil and item[index] then
--        local param = item[index]
--        self:SetLookAtParam(param.Size, param.Offset[2], param.Offset[1], param.RotY)
--    end
-- end

---- 按怪物数据，设置相机Size和模型偏移
-- def.method().SetDefaultLookAtMonster = function(self)
--    if IsNil(self._RoleImg) then return end
--    local keyword = self._ModelAssetPath
--    local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
--    local cfgList = ModuleProfDiffConfig.GetModuleInfo("MonsterImageModelParam")

--    if cfgList == nil then return end

--    local item = cfgList[keyword]
--    if item == nil or item[1] == nil then
--        item = cfgList["default"]
--    end
--    local param = item[1]
--    -- warn("lidaming im param "..param.Size..", "..param.OffsetY..", "..self._ModelAssetPath)
--    local imageModel = self._RoleImg:GetComponent(ClassType.GImageModel)
--    if not IsNil(imageModel) then
--        imageModel:SetLookAtParam(param.Size, param.OffsetY)
--    end

-- end

def.method("number", "string").SetDialogParam = function(self, e_side, s_anim)
	if self._ImageModelComp ~= nil then
		local key1 = self._ModelAssetPath

		if self._DialogCfg == nil then
			local ret, msg, result = pcall(dofile, "Configs/SceneDialogModelCfg.lua")
			if ret then
				self._DialogCfg = result
			else
				warn(msg)
				return
			end
		end

		local im_param = nil

		if s_anim ~= EnumDef.CLIP.COMMON_STAND then
			local key2 = key1 .. " " .. s_anim

			local im_param = self._DialogCfg:GetRawConfig(key2, e_side)
			if im_param ~= nil then
				self:SetLookAtParam(im_param.Size, im_param.PosX, im_param.PosY, 0, 0, im_param.RotY, 0)
				return
			end
		end

		im_param = self._DialogCfg:GetConfig(key1, e_side)
		if im_param ~= nil then
			self:SetLookAtParam(im_param.Size, im_param.PosX, im_param.PosY, 0, 0, im_param.RotY, 0)
			-- self:SetLookAtParam(im_param.Size, im_param.PosY, im_param.PosX, im_param.RotY)
			return
		end

	end
end

def.method("string", "dynamic").SetModelParam = function(self, ui_resPath, key2)
	self:SetModelParamEx(ui_resPath,	0, key2)
end

def.method("string", "number","dynamic").SetModelParamEx = function(self, ui_resPath, key1, key2)
	if self._ImageModelComp ~= nil then
		if self._ImgRoleCfg == nil then
			local ret, msg, result = pcall(dofile, "Configs/ImageModelCfg.lua")
			if ret then
				self._ImgRoleCfg = result
			else
				warn(msg)
				return
			end
		end

		if key1 == 0 then
			local im_name = self._RoleImg.name
			local len = string.len(im_name)
			if len > 9 then
				key1 = tonumber(string.sub(im_name, 10, len))	-- remove "Img_Role_" then to number
			end
		end

		if ui_resPath ~= nil then
			local t_sa = string.split(ui_resPath, '.')
			ui_resPath = t_sa[1]
		end

		local im_ui, im_param = self._ImgRoleCfg:GetConfig(ui_resPath, key1, key2)
		if nil ~= im_ui and nil ~= im_param then
			self._ImageModelComp:SetCameraType(im_ui.CameraType)
			--self._ImageModelComp:SetStageZ(im_param.position[3])
			if im_param.MOffsetX ~= nil then
				self._ImageModelComp:FixModelAxisX(im_param.MOffsetX)
			end
			self._ImageModelComp:SetCameraAngle(im_param.cameraRotX, 0, 0)
			-- self._ImageModelComp:SetLookAtParam(im_param.cameraParam, im_param.position[2], im_param.position[1], im_param.rotation[2])
			--warn("LookAt ".. im_param.cameraParam..", "..im_param.position[1]..", "..im_param.position[2]..", "..im_param.position[3]..", "..im_param.rotation[1]..", "..im_param.rotation[2]..", "..im_param.rotation[3])
			self:SetLookAtParam(im_param.cameraParam, im_param.position[1], im_param.position[2], im_param.position[3], im_param.rotation[1], im_param.rotation[2], im_param.rotation[3])

			self._ImageModelComp:ShowGround(im_param.shadow)
			if im_param.shadow then
				if im_param.GroundRotX == nil then
					im_param.GroundRotX = 0
				end
				self._ImageModelComp:SetGroundOffset(im_param.GroundOffsetY, im_param.GroundRotX)
			end

			--            if im_ui.CameraType == false then
			--                self._ImageModelComp:SetCameraFarClip(100)
			--            end
		end
	end
end

--  Destroy
def.method().Destroy = function(self)
	self:ReleaseGIMComp()
	self:DestroyModel()

	self._ShowType = 0
	self._ModelLoaded = false
	self._SelfDestroyed = true
	self._RoleImg = nil
	self._ModelAssetPath = ""
	self._ModelParams = nil
	self._OnLoadedCallbacks = nil
	self._CallbackWhenInit = nil
	self._DialogCfg = nil
	self._ImgRoleCfg = nil
end

CUIModel.Commit()
return CUIModel