local Lplus = require "Lplus"
local ModelParams = require "Object.ModelParams"
local OutwardUtil = require "Utility.OutwardUtil"
local HeadwearUtil = require "Utility.HeadwearUtil"
local CFxObject = require "Fx.CFxObject"

local CModel = Lplus.Class("CModel")
local def = CModel.define

_G.ModelStatus = { NORMAL = 0, LOADING = 1, DESTROY = 2}

def.field("userdata")._GameObject = nil
def.field("userdata")._Animation = nil
def.field(CFxObject)._ModelFx1 = nil 		-- 对于武器模型来说，是武器在背上时的特效
def.field(CFxObject)._ModelFx2 = nil 		-- 对于武器模型来说，是武器在手上时的特效
def.field("number")._Status = -1  
def.field("table")._Attachments = BlankTable   -- { hp = { obj, boneObj } , .... }
def.field("string")._ResName = ""
def.field("number")._ResId = 0
def.field("table")._Renderers = nil
def.field("boolean")._Visible = false
def.field("table")._HangPoints = BlankTable
def.field(ModelParams)._Params = nil

def.field("table")._ModelReadyFlags = nil
def.field("number")._ModelFxPriority = -1 --EnumDef.CFxPriority.Always
def.field("boolean")._HasAnimationComp = true

def.final("=>", CModel).new = function ()
	local obj = CModel()
	return obj
end

local weapon_scale_in_hand = Vector3.one
local weapon_scale_on_back = Vector3.New(0.7, 0.7, 0.7)

local function GetWeaponHangPoint(isInHand)
	if isInHand then
		return "HangPoint_WeaponLeft", "HangPoint_WeaponRight"
	else
		return "HangPoint_WeaponBack1", "HangPoint_WeaponBack2"
	end
end

def.static(CModel, "string", "string", "boolean", "function").AttachWeaponModel = function (mainModel, left_hand_asset_path, right_hand_asset_path, is_in_hand, cb)
	if mainModel == nil then warn("mainModel is nil") return end

	if left_hand_asset_path ~= "" then
		local m = CModel.new()
		m._HasAnimationComp = false

		local function loaded()
			if mainModel._Status == ModelStatus.DESTROY then
				m:Destroy()
				return
			end

			if mainModel._Params ~= nil then
				if mainModel._Params._WeaponAssetPathL ~= left_hand_asset_path then
					-- 无效的加载（过时）
					m:Destroy()
					return
				end
			else
				warn("AttachWeaponModel mainModel _Params got nil when loaded left")
			end

			local hangPointL, _ = GetWeaponHangPoint(is_in_hand)
			mainModel:DestroyChild("WeaponL")
			mainModel:AttachModel("WeaponL", m, hangPointL, Vector3.zero, Quaternion.identity)

			local scale = is_in_hand and weapon_scale_in_hand or weapon_scale_on_back
			m._GameObject.localScale = scale

			if mainModel._ModelReadyFlags ~= nil then
				mainModel._ModelReadyFlags.WeaponLReady = true
			end
			
			if cb ~= nil then cb() end
		end

		m:Load(left_hand_asset_path, function(ret)
				if ret then
					loaded()
				else
					warn("Model Failed to WeaponLoad Model, ModelAssetPath = ", left_hand_asset_path)
				end
			end)
	end

	if right_hand_asset_path ~= "" then
		local m = CModel.new()
		m._HasAnimationComp = false

		local function loaded()
			if mainModel._Status == ModelStatus.DESTROY then
				m:Destroy()
				return
			end

			if mainModel._Params ~= nil then
				if mainModel._Params._WeaponAssetPathR ~= right_hand_asset_path then
					-- 无效的加载（过时）
					m:Destroy()
					return
				end
			else
				warn("AttachWeaponModel mainModel _Params got nil when loaded right")
			end

			local _, hangPointR = GetWeaponHangPoint(is_in_hand)
			mainModel:DestroyChild("WeaponR")
			mainModel:AttachModel("WeaponR", m, hangPointR, Vector3.zero, Quaternion.identity)

			local scale = is_in_hand and weapon_scale_in_hand or weapon_scale_on_back
			m._GameObject.localScale = scale

			if mainModel._ModelReadyFlags ~= nil then
				mainModel._ModelReadyFlags.WeaponRReady = true
			end

			if cb ~= nil then cb() end
		end

		m:Load(right_hand_asset_path, function(ret)
			if ret then
				loaded()
			else
				warn("Model Failed to WeaponLoad Model, ModelAssetPath = ", right_hand_asset_path)
			end
		end)
	end
end

def.static(CModel, "string", "function").AttachWingModel = function (mainModel, wingAssetPath, cb)
	if mainModel == nil then warn("mainModel is nil") return end

	if wingAssetPath ~= "" then
		local m = CModel.new()

		local function loaded()
			if mainModel._Status == ModelStatus.DESTROY then
				m:Destroy()
				return
			end

			if mainModel._Params ~= nil then
				if mainModel._Params._WingAssetPath ~= wingAssetPath then
					-- 无效的加载（过时）
					m:Destroy()
					return
				end
			else
				warn("AttachWingModel mainModel _Params got nil")
			end

			local wingModel = mainModel:GetAttach("WingHP")
			if wingModel ~= nil and not IsNil(wingModel:GetGameObject()) then
				-- 解锁翅膀YZ轴旋转
				GameUtil.EnableLockWingYZRotation(false, wingModel:GetGameObject(), nil)
			end
			mainModel:DestroyChild("WingHP")
			mainModel:AttachModel("WingHP", m, "HangPoint_Wing", Vector3.zero, Quaternion.identity)

			if mainModel._ModelReadyFlags ~= nil then
				mainModel._ModelReadyFlags.WingReady = true
			end
				
			m:PlayAnimation(EnumDef.CLIP.COMMON_STAND, 0, false, 0, 1)			
			if cb ~= nil then cb() end
		end

		m:Load(wingAssetPath, function(ret)
				if ret then
					loaded()
				else
					warn("Model Failed to Wing Model, ModelAssetPath = ", wingAssetPath)
				end
			end)
	end
end

-- 挂载头饰
def.static(CModel, "string", "number", "function").AttachHeadwearModel = function (mainModel, assetPath, prof, cb)
	if mainModel == nil then warn("mainModel is nil when AttachHeadwearModel") return end

	if assetPath ~= "" then
		local m = CModel.new()
		m._HasAnimationComp = false

		local function loaded()
			if mainModel._Status == ModelStatus.DESTROY then
				m:Destroy()
				return
			end

			if mainModel._Params ~= nil then
				if mainModel._Params._HeadwearAssetPath ~= assetPath then
					-- 无效的加载（过时）
					m:Destroy()
					return
				end
			else
				warn("AttachHeadwearModel mainModel _Params got nil")
			end

			local config = HeadwearUtil.Get(assetPath, prof)
			if config ~= nil then
				local position = Vector3.New(config.position[1], config.position[2], config.position[3])
				local rotation = Quaternion.Euler(config.rotation[1], config.rotation[2], config.rotation[3])

				mainModel:DestroyChild("HeadwearHP")
				mainModel:AttachModel("HeadwearHP", m, config.path, position, rotation)

				local scale = Vector3.New(config.scale[1], config.scale[2], config.scale[3])
				m._GameObject.localScale = scale
				GameUtil.SetupDynamicBones(m._GameObject)
				local main_go = mainModel:GetGameObject()
				if not IsNil(main_go) then
					GameUtil.EnableOutwardPart(main_go, EnumDef.EntityPart.Face, not config.isHideFace)
					GameUtil.EnableOutwardPart(main_go, EnumDef.EntityPart.Hair, not config.isHideHair)
				end
			else
				warn("Attach Headwear failed, config got nil, prof:" .. prof .. ", assetPath:" .. assetPath)
				m:Destroy()
				return
			end
			if cb ~= nil then cb() end
		end

		m:Load(assetPath, function(ret)
				if ret then
					loaded()
				else
					warn("Model Failed to Headwear Model, ModelAssetPath = ", assetPath)
				end
			end)
	end
end

local model_orignal_local_params = {}

def.method("=>", "boolean").IsReady = function (self)
	if self._Status ~= ModelStatus.NORMAL then
		return false
	end

	if self._ModelReadyFlags ~= nil then
		for k,v in pairs(self._ModelReadyFlags) do
			if not v then 
				return false
			end
		end
	end

	return true
end

def.method("=>", "boolean").IsInLoading = function (self)
	if self._Status == ModelStatus.LOADING then
		return true
	end

	if self._ModelReadyFlags ~= nil then
		for k,v in pairs(self._ModelReadyFlags) do
			if not v then 
				return true
			end
		end
	end

	return false
end

def.method("userdata", "dynamic", "function").OnModelLoadResult = function (self, go, res, cb)
	local m = go
	m:SetActive(true)
	local params = model_orignal_local_params[res]
	if params ~= nil then
		m.localPosition = params[1]
		m.localScale = params[2]
		m.localRotation = params[3]
	end

	self._GameObject = m
	self._GameObject.localPosition = Vector3.zero
	if self._HasAnimationComp then
		self._Animation = m:GetComponent(ClassType.AnimationUnit)
		if IsNil(self._Animation) then
			self._Animation = m:AddComponent(ClassType.AnimationUnit)
		end
	--else
	--	print("model doesn't have AnimationComp", go.name)
	end

	self._Status = ModelStatus.NORMAL

	--self._Renderers = m:GetRenderersInChildren()
	self._Visible = true
	if cb then cb(true) end
end

def.method("dynamic","function").Load = function (self, res, cb) 
	if type(res) ~= "number" and type(res) ~= "string" then
		warn("Cmodel.Load's first param must be number or string")
		return
	end

	if type(res) == "number" then
		self._ResId = res
		self._ResName = "" 
	else
		self._ResId = 0
		self._ResName = res
	end

	local g = GameUtil.FetchResFromCache(res)
	if g ~= nil then
		self:OnModelLoadResult(g, res, cb)	
	else
		self._Status = ModelStatus.LOADING
		if type(res) == "string" then
			local function loaded(obj)
				if self._Status == ModelStatus.DESTROY then			
					return 
				end

				if obj == nil then 
					cb(false)
					return 
				end
				
				if obj.localPosition ~= Vector3.zero or obj.localScale ~= Vector3.zero or obj.localRotation ~= Quaternion.identity then
					model_orignal_local_params[res] = {obj.localPosition, obj.localScale, obj.localRotation}
				end

				local go = GameObject.Instantiate(obj)
				self:OnModelLoadResult(go, res, cb)
			end
			GameUtil.AsyncLoad(res, loaded, false, "characters")
		else
			self._Status = ModelStatus.DESTROY
			--warn("cannot load by id: ", res)
		end
	end
end

def.method(ModelParams,"function").LoadWithModelParams = function (self, params, callback) 	
	if params ~= nil then
		local asset_path = params._ModelAssetPath
		if asset_path ~= nil and asset_path ~= "" then
			local function cb()
				--self._Status = ModelStatus.LOADING  -- 后面会有换装需求，此时重置状态为Loading
				self._Params = ModelParams.new()
				self._Params._Prof = params._Prof
				self:UpdateWithModelParams(params, callback)
			end
			self:Load(asset_path, function(ret)
				if self._Status == ModelStatus.DESTROY then
					self:Destroy()
					return
				end

				if ret then
					cb()
				else
					warn("Failed to load model, path:", asset_path)
				end
			end)
		end
	end
end

-- 更新模型外观
def.method(ModelParams,"function").UpdateWithModelParams = function (self, params, callback)
	if self._Status == ModelStatus.DESTROY then
		self:Destroy()
		return
	end

	if params ~= nil then
		self._ModelReadyFlags = {}
		self._ModelReadyFlags.ArmorReady = (params._ArmorAssetPath == "")
		self._ModelReadyFlags.FacialReady = (params._FacialAssetPath == "")
		self._ModelReadyFlags.HairstyleReady = (params._HairstyleAssetPath == "")
		self._ModelReadyFlags.HeadwearReady = (params._HeadwearAssetPath == "" or not params._IsChangeHeadwear)
		self._ModelReadyFlags.WeaponLReady = (params._WeaponAssetPathL == "")
		self._ModelReadyFlags.WeaponRReady = (params._WeaponAssetPathR == "")
		self._ModelReadyFlags.WingReady = (params._WingAssetPath == "" or not params._IsChangeWing)

		if self._Params ~= nil then
			-- params:PrintModelParams("UpdateWithModelParams params")
			-- self._Params:PrintModelParams("UpdateWithModelParams before")
			self._Params:Update(params) -- 更新本地保存参数
			-- self._Params:PrintModelParams("UpdateWithModelParams after")
		end
		-- 提前记录，之后的异步过程有可能是同步的，防止二次调用
		local isAllReady = self:IsReady()

		local go = self:GetGameObject()
		local function allReadyCallback()
			if not self:IsReady() then
				-- print_r(self._ModelReadyFlags)
				-- print(debug.traceback())
				return
			end
			
			GameUtil.OnEntityModelChanged(go)
			-- 肤色
			if params._SkinColorId > 0 then
				OutwardUtil.ChangeSkinColor(go, params._Prof, params._SkinColorId)
			end

			-- 发色
			if params._HairColorId > 0 then
				OutwardUtil.ChangeHairColor(go, params._Prof, params._HairColorId)
			end

			-- 时装染色
			if params._Is2ShowDress then
				local EDressType = require "PB.Template".Dress.eDressType
				for slot, colors in pairs(params._DressColors) do
					local name_1, name_2 = nil, nil
					if slot == EDressType.Armor then
						-- 服饰
						name_1 = "body"
						name_2 = "body2"  -- 部分时装有body2
					elseif slot == EDressType.Hat then
						-- 帽子
						name_1 = "hair"
					elseif slot == EDressType.Headdress then
						-- 头饰
						local headwearModel = self:GetAttach("HeadwearHP")
						if headwearModel ~= nil then
							name_1 = headwearModel:GetGameObject().name
						end
					elseif slot == EDressType.Weapon then
						-- 武器
						local weaponModelL = self:GetAttach("WeaponL")
						if weaponModelL ~= nil then
							name_1 = weaponModelL:GetGameObject().name
						end
						local weaponModelR = self:GetAttach("WeaponR")
						if weaponModelR ~= nil then
							name_2 = weaponModelR:GetGameObject().name
						end
					end
					if name_1 ~= nil then
						OutwardUtil.ChangeDressColors(go, name_1, colors)
					end
					if name_2 ~= nil then
						OutwardUtil.ChangeDressColors(go, name_2, colors)
					end
				end
			end

			-- 武器特效
			local isLancer = self._Params._Prof == EnumDef.Profession.Lancer
			if params._IsUpdateWeaponFx then
				local weaponModelL = self:GetAttach("WeaponL")
				if weaponModelL ~= nil then
					if weaponModelL._ModelFx1 ~= nil then
						weaponModelL._ModelFx1:Stop()
						weaponModelL._ModelFx1 = nil
					end
					if weaponModelL._ModelFx2 ~= nil then
						weaponModelL._ModelFx2:Stop()
						weaponModelL._ModelFx2 = nil
					end
					local weapon_go = weaponModelL:GetGameObject()
					local weapon_go_back, weapon_go_hand = weapon_go, weapon_go
					if isLancer and not IsNil(weapon_go) then
						for i=1, weapon_go.childCount do
							local child_go = weapon_go:GetChild(i-1)
							if string.find(child_go.name, "_B_") then
								weapon_go_back = child_go
							elseif string.find(child_go.name, "_L_") then
								weapon_go_hand = child_go
							end
						end
					end
					if params._WeaponFxPathLeftBack ~= "" then
						weaponModelL._ModelFx1 = CFxMan.Instance():PlayAsChild(params._WeaponFxPathLeftBack, weapon_go_back, Vector3.zero, Vector3.zero, -1, false, -1, self._ModelFxPriority)
					end
					if params._WeaponFxPathLeftHand ~= "" then
						weaponModelL._ModelFx2 = CFxMan.Instance():PlayAsChild(params._WeaponFxPathLeftHand, weapon_go_hand, Vector3.zero, Vector3.zero, -1, false, -1, self._ModelFxPriority)
					end
				end
				
				local weaponModelR = self:GetAttach("WeaponR")
				if weaponModelR ~= nil then
					if weaponModelR._ModelFx1 ~= nil then
						weaponModelR._ModelFx1:Stop()
						weaponModelR._ModelFx1 = nil
					end
					if weaponModelR._ModelFx2 ~= nil then
						weaponModelR._ModelFx2:Stop()
						weaponModelR._ModelFx2 = nil
					end
					local weapon_go = weaponModelR:GetGameObject()
					local weapon_go_back, weapon_go_hand = weapon_go, weapon_go
					if isLancer and not IsNil(weapon_go) then
						for i=1, weapon_go.childCount do
							local child_go = weapon_go:GetChild(i-1)
							if string.find(child_go.name, "_B_") then
								weapon_go_back = child_go
							elseif string.find(child_go.name, "_R_") then
								weapon_go_hand = child_go
							end
						end
					end
					if params._WeaponFxPathRightBack ~= "" then
						weaponModelR._ModelFx1 = CFxMan.Instance():PlayAsChild(params._WeaponFxPathRightBack, weapon_go_back, Vector3.zero, Vector3.zero, -1, false, -1, self._ModelFxPriority)
					end
					if params._WeaponFxPathRightHand ~= "" then
						weaponModelR._ModelFx2 = CFxMan.Instance():PlayAsChild(params._WeaponFxPathRightHand, weapon_go_hand, Vector3.zero, Vector3.zero, -1, false, -1, self._ModelFxPriority)
					end
				end
			end

			if params._Prof > 0 then
				local CombatStateChangeComp = go:GetComponent(ClassType.CombatStateChangeBehaviour)
				if IsNil(CombatStateChangeComp) then
					CombatStateChangeComp = self:GetGameObject():AddComponent(ClassType.CombatStateChangeBehaviour)
				end			
				CombatStateChangeComp:EnableWeaponStateSwtichable(isLancer)
			end
			

			self._Status = ModelStatus.NORMAL
			self._ModelReadyFlags = nil		

			if callback ~= nil then
				callback()
			end
		end

		-- 衣服
		if params._ArmorAssetPath ~= "" then
			GameUtil.ChangeOutward(go, EnumDef.EntityPart.Body, params._ArmorAssetPath, function()
					if self._Status == ModelStatus.DESTROY then
						return  
					end
					
					if self._ModelReadyFlags ~= nil then
						self._ModelReadyFlags.ArmorReady = true
					end
					allReadyCallback()
				end)
		end

		-- 脸
		if params._FacialAssetPath ~= "" then
			GameUtil.ChangeOutward(go, EnumDef.EntityPart.Face, params._FacialAssetPath, function()
					if self._Status == ModelStatus.DESTROY then
						return
					end

					if self._ModelReadyFlags ~= nil then
						self._ModelReadyFlags.FacialReady = true
					end

					allReadyCallback()
				end)
		end		

		-- 发型
		if params._HairstyleAssetPath ~= "" then
			GameUtil.ChangeOutward(go, EnumDef.EntityPart.Hair, params._HairstyleAssetPath, function()
					if self._Status == ModelStatus.DESTROY then
						return  
					end

					if self._ModelReadyFlags ~= nil then
						self._ModelReadyFlags.HairstyleReady = true
					end
					allReadyCallback()
				end)
		end

		-- 头饰
		if params._IsChangeHeadwear then
			if params._HeadwearAssetPath ~= "" then
				CModel.AttachHeadwearModel(self, params._HeadwearAssetPath, params._Prof, function()
						if self._Status == ModelStatus.DESTROY then
							return
						end

						if self._ModelReadyFlags ~= nil then
							self._ModelReadyFlags.HeadwearReady = true
						end
						allReadyCallback()
					end)
			else
				-- 移除
				self:DestroyChild("HeadwearHP")
				GameUtil.EnableOutwardPart(go, EnumDef.EntityPart.Face, true)
				GameUtil.EnableOutwardPart(go, EnumDef.EntityPart.Hair, true)
				GameUtil.OnEntityModelChanged(go)
			end
		end

		-- 武器
		if params._WeaponAssetPathL ~= "" or params._WeaponAssetPathR ~= "" then
			CModel.AttachWeaponModel(self, params._WeaponAssetPathL, params._WeaponAssetPathR, params._IsWeaponInHand, function()
					if self._Status == ModelStatus.DESTROY then
						return
					end

					allReadyCallback()
				end)
		end

		-- 翅膀
		if params._IsChangeWing then
			if params._WingAssetPath ~= "" then
				CModel.AttachWingModel(self, params._WingAssetPath, function()
							if self._Status == ModelStatus.DESTROY then
								return
							end

							allReadyCallback()
						end)
			else
				-- 移除翅膀
				local wingModel = self:GetAttach("WingHP")
				if wingModel ~= nil and not IsNil(wingModel:GetGameObject()) then
					-- 解锁翅膀YZ轴旋转
					GameUtil.EnableLockWingYZRotation(false, wingModel:GetGameObject(), nil)
				end
				self:DestroyChild("WingHP")
				GameUtil.OnEntityModelChanged(go)
			end
		end

		if isAllReady then
			allReadyCallback()
		end
	end
end

--带关键字的异步加载
def.method("dynamic","number","function").LoadWithKey = function (self, res, nKey, cb) 
	local function callback(ret)
		if ret then
			if cb ~= nil then
				cb(nKey)
			end
		else
			cb(-1)
			warn("CModel LoadWithKey Error.Res:",res)
		end	
	end

	self:Load(res, callback)
end

def.method("boolean").SetVisible = function (self, visible)
	if self._Visible ~= visible then
		self._Visible = visible
		if self._GameObject ~= nil and self._GameObject.activeSelf ~= visible then
			self._GameObject:SetActive(visible)
		end
		--[[
		local rs = self._Renderers
		if rs ~= nil then
			for i = 1, #rs do
				rs[i].enabled = visible
			end
		end
		]]
	end
	
	local att = self._Attachments
	for k, v in pairs(att) do
		v[1]:SetVisible(visible)
	end
end

def.method("number").SetRenderLayer = function (self, layer)
	local rs = self._Renderers
	for i = 1, #rs do
		rs[i].gameObject.layer = layer
	end
end

def.method("string",CModel,"string","table","table", "=>", "userdata").AttachModel = function (self, hp, model, bone, pos, angles) 
	if not self._GameObject or self._Status ~= ModelStatus.NORMAL then
		warn("please load model firstly")
	end
	
	local bone_map =  self._HangPoints
    local hook_bone = bone_map[bone]
    if IsNil(hook_bone) then
		local hang_point_id = EnumDef.HangPoint[bone]

	    if hang_point_id ~= nil then
	        hook_bone = GameUtil.GetHangPoint(self._GameObject, hang_point_id)
	        if hook_bone == nil then
	        	hook_bone = GameUtil.FindChild(self._GameObject, bone)
	        end
	    else
	        hook_bone = GameUtil.FindChild(self._GameObject, bone)
	    end

		if IsNil(hook_bone) then
			warn("can not find model hook, hook name = " .. bone)
			hook_bone = model._GameObject
		end
	end

	if self._HangPoints[bone] == nil then
		self._HangPoints[bone] = hook_bone
	end
	
	self:Detach(hp)
	self:AttachModelImp(hp,model,hook_bone,pos,angles)

	return hook_bone
end

def.method("string","string","string","table","table","table").ChangeAttach = function (self, srchp,dsthp,dstbone,lpos,angles,scale) 
	if not self._GameObject or self._Status ~= ModelStatus.NORMAL then
		warn("please load model firstly")
	end
	local model = self:GetAttach(srchp)
  	self:Detach(srchp)
	self:AttachModel(dsthp,model,dstbone,lpos,angles)
	if model ~= nil and scale ~= nil then
		model._GameObject.localScale = scale
	end
end

def.method("string",CModel,"userdata","table","table").AttachModelImp = function (self,hp,model,boneObj,lpos,angles) 
	if hp == nil or hp == "" or model == nil or boneObj == nil then
		warn("AttachModelImp", hp, model, boneObj, debug.traceback())
		return
	end
	
	self._Attachments[hp] = { model, boneObj }
	local m = model._GameObject
	if IsNil(boneObj) then
		warn("boneObj is nil", hp,CModel,boneObj,lpos,angles)
		return
	end
	m.parent = boneObj
	m.localPosition = lpos
	m.localRotation = angles
	m.localScale = Vector3.one
end

def.method("string","=>","table").Detach = function (self, hp) 
	local info = self._Attachments[hp]
	if info ~= nil then
		if not IsNil(info[1]._GameObject) then
			info[1]._GameObject.parent = nil
		end
		self._Attachments[hp] = nil
		return info[1]
	end
	return nil
end

def.method("string").DestroyChild = function (self, hp) 
	local child = self:Detach(hp)
	if child then
		child:Destroy()
	end
end

def.method("string", "=>", "boolean").IsPlaying = function (self, aniname) 
	local ani = self._Animation
	if IsNil(ani) then return false end
	return ani:IsPlaying(aniname)
end

def.method("string", "=>", "boolean").HasAnimation = function (self, aniname) 
	local ani = self._Animation
	if IsNil(ani) then return false end
	return ani:HasAnimation(aniname)
end

def.method("string", "number", "boolean", "number", "number").PlayAnimation = function (self, aniname, fade_time, is_queued, life_time, aniSpeed) 
	local ani = self._Animation
	if IsNil(ani) then return end

	if math.isinf(aniSpeed) or math.isnan(aniSpeed) then
		error("fixedSpeed is Inf or Nan!")
		return
	end

	ani:PlayAnimation(aniname, fade_time, is_queued, life_time, false, aniSpeed)
end

def.method("string", "number").StopAnimation = function (self, aniname, layer) 
	local ani = self._Animation
	if IsNil(ani) then return end	
	ani:StopAnimation(aniname, layer)
end

-- 播一个半身动作
def.method("string").PlayPartialAnimation = function (self, aniname) 
	local ani = self._Animation
	if IsNil(ani) then
		warn("error occur in PlayPartialAnimation ani not exists")
		return 
	end
	ani:PlayPartialSkillAnimation(aniname)
end

-- 停止播放半身动作
def.method("string").StopPartialAnimation = function (self, aniname) 
	local ani = self._Animation
	if IsNil(ani) then
		warn("error occur in StopPartialAnimation ani not exists")
		return 
	end
	ani:StopPartialSkillAnimation(aniname)
end

def.method("boolean").PlayDieAnimation = function (self, onlyLastFrame) 
	local ani = self._Animation
	if IsNil(ani) then return end
	ani:PlayDieAnimation(onlyLastFrame)
end

def.method("boolean", "string").PlayHurtAnimation = function (self, additive, hurt_ani) 
	local ani = self._Animation
	if IsNil(ani) then return end
	ani:PlayHurtAnimation(additive, hurt_ani)
end

def.method("string", "number", "boolean", "number").PlayClampForeverAnimation = function (self, aniname, fade_time, is_queued, life_time) 
	local ani = self._Animation
	if IsNil(ani) then return end
	ani:PlayAnimation(aniname, fade_time, is_queued, life_time, true, 1)
end

def.method("number", "boolean", "=>", "number").BluntCurAnimation = function (self, blunt_time, correct_when_end) 
	local ani = self._Animation
	if IsNil(ani) then return 1 end
	return ani:BluntCurSkillAnimation(blunt_time, correct_when_end)
end

-- 获取当前播放动作的进度 和动作名
def.method("=>", "dynamic", "dynamic").GetCurAniClip = function (self) 
	local ani = self._Animation
	if IsNil(ani) then
		warn("error occur in cmodel GetCurAniClip")
		return nil, nil
	end
	-- TODO: 此处逻辑存在漏洞，现在动画分两层，以下获得的动画信息可能不是你想要的
	local ani_name = ani:GetCurAnimNameAtLayer(0)
	local ani_cur_time = ani:GetCurAnimTimeAtLayer(0)
	if not (ani_name and ani_cur_time) then
		warn("error occur in GetCurAniClip call bind")
	end
	return ani_name, ani_cur_time
end

def.method("string", "number").PlayAssignedAniClip = function (self, ani_name, start_time) 
	local ani = self._Animation
	if IsNil(ani) then
		warn("error occur in cmodel PlayAssignedAniClip")
		return
	end
	ani:PlayAssignedAniClip(ani_name, start_time)	
end

def.method("string", "=>", "number").GetAniLength = function (self, aniname)
	local ani = self._Animation
	if IsNil(ani) then return 0 end
	return ani:GetAniLength(aniname)
end

def.method("boolean").EnableAnimationComponent = function (self, active)
	local ani = self._Animation
	if IsNil(ani) then
		return
	end	
	ani:EnableAnimationComponent(active)
end

def.method("string").CloneAnimationState = function (self, aniname)
	local ani = self._Animation
	if IsNil(ani) then return end

	ani:CloneAnimationState(aniname)
end

def.method("=>", "userdata").GetGameObject = function (self)
	return self._GameObject
end

def.method().Destroy = function (self)
	local hps = {}
	for k,v in pairs(self._Attachments) do
		table.insert(hps,k)
	end
	for _,hp in pairs(hps) do
		self:DestroyChild(hp)
	end

	-- 销毁特效
	if self._ModelFx1 ~= nil then
		self._ModelFx1:Stop()
		self._ModelFx1 = nil
	end
	if self._ModelFx2 ~= nil then
		self._ModelFx2:Stop()
		self._ModelFx2 = nil
	end

	self._ModelReadyFlags = nil
	self._Params = nil
	self._ModelFxPriority = -1
	self._HasAnimationComp = true

	-- 回池之前 再激活animation animator
	self:EnableAnimationComponent(true)

	self._Status = ModelStatus.DESTROY
	if not IsNil(self._GameObject) then
		--local rs = self._Renderers
		--if rs then
		--    for i = 1, #rs do
		--		local t = rs[i]
		--		if not t.isnil then
		--			t.enabled = true
		--		end
		--    end
		--end	

		--if self._ResName == "" then
		--	warn("ResName is Empty!")
		--end

		--warn(debug.traceback())
		local res = self._ResId
		if res == 0 then res = self._ResName end
		GameUtil.AddResToCache(res, self._GameObject)
		self._GameObject = nil
		self._Animation = nil
	end
end

def.method("string","=>",CModel).GetAttach = function(self, hp)
	local attachment = self._Attachments[hp]
	if attachment then
		return attachment[1]
	end
	return nil
end

CModel.Commit()

return CModel
