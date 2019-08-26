local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CFxObject = require "Fx.CFxObject"
local EIndicatorType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillIndicator.EIndicatorType

local CFxMan = Lplus.Class("CFxMan")
local def = CFxMan.define

def.field("boolean")._IsAllFxHiden = false
def.field("userdata")._UnCachedFxsRoot = nil

-- 目标选中特效
def.field("table")._ApertureGfxs = BlankTable
def.field("userdata")._CrossFx = nil
def.field("userdata")._BracketsFx = nil
def.field("userdata")._BracketsFxFollowComp = nil

-- 技能指示特效
def.field("table")._SkillIndicatorsGfxs = BlankTable
def.field("userdata")._SkillRangeGfx = nil

-- 点地特效
def.field("userdata")._ClickGroundGfx = nil
def.field("userdata")._ClickGroundGfxOne = nil

local instance = nil
def.static("=>",CFxMan).Instance = function()
	if not instance then
		instance = CFxMan()
		instance._UnCachedFxsRoot = GameUtil.GetFxManUncachedFxsRoot()
	end
	return instance
end

def.static("boolean",  "number", "number", "=>", "string").GetAttackWarningFxPath = function(isDecl, fxType, param)
	local fxPath = nil
	if fxType == EIndicatorType.Circular then
		fxPath = isDecl and PATH.Etc_Yujing_Ring_Decl or PATH.Etc_Yujing_Ring
	elseif fxType == EIndicatorType.Fan then
		fxPath = isDecl and PATH["Etc_Yujing_Shanxing"..tostring(param).."_Decl"] or PATH["Etc_Yujing_Shanxing"..tostring(param)]
	elseif fxType == EIndicatorType.Rectangle then
		fxPath = isDecl and PATH.Etc_Yujing_Juxing_Decl or PATH.Etc_Yujing_Juxing
	elseif fxType == EIndicatorType.Ring then
		fxPath = isDecl and PATH.Etc_Yujing_Hollow_Decl or PATH.Etc_Yujing_Hollow
	end

	if fxPath == nil then
		warn("预警特效参数错误: ", isDecl, fxType, param)
		fxPath = ""
	end

	return fxPath
end

def.method("table").OnClickGround = function(self,pos)
	if IsNil(self._ClickGroundGfx)  then
		self._ClickGroundGfx = GameUtil.RequestUncachedFx(PATH.Gfx_ClickGround)
		self._ClickGroundGfxOne = self._ClickGroundGfx:GetComponent(ClassType.CFxOne)
	end
	local fx = self._ClickGroundGfx
	pos.y = pos.y + 0.1
	fx.position = pos
	local fxone = self._ClickGroundGfxOne
	fxone:Stop()
	fxone:Play(2)
end


-- 目标选中 和 自动索敌
--[[
	自动锁定(敌对怪物/NPC/玩家)：脚底十字特效 + 脚底圆圈特效（多个）
	强锁(敌对怪物/NPC/玩家)：脚底十字特效 + 脚底圆圈特效（多个） + 胸部括号特效
	强锁(中立和友好玩家/NPC)：脚底圆圈特效（多个）

	备注：OnTargetSelected在CHostPlayer对象切换时主动调用，无需消息监听
]]
local function GetCrossFx(self)
	if self._CrossFx == nil then
		self._CrossFx = GameUtil.RequestUncachedFx(PATH.Gfx_SelectCross)
	end
	return self._CrossFx
end

local function GetApertureGfx(self, relation)
	if self._ApertureGfxs[relation] == nil then
		self._ApertureGfxs[relation] = GameUtil.RequestUncachedFx(PATH.Gfx_SelectAperture[relation])
	end
	return self._ApertureGfxs[relation]
end

local function GetBracketsFx(self)
	if self._BracketsFx == nil then
		self._BracketsFx = GameUtil.RequestUncachedFx(PATH.Gfx_SelectBrackets)
		self._BracketsFxFollowComp = self._BracketsFx:AddComponent(ClassType.CFxFollowTarget)
	end
	return self._BracketsFx
end

-- LRL需求：脚下圈最大上限为8     2018/08/20   
local function GetApertureFxScale(self, target)
	local scale = 0
	if target:IsMonster() then
		scale = target._MonsterTemplate.CollisionRadius	
		scale = scale / 0.5   				-- 不能用主角的半径，不同职业半径不一样  commented by lijian	
	elseif target:IsRole() then
		scale = target._ProfessionTemplate.CollisionRadius
		scale = scale / 0.5
	elseif target:IsMineral() then		
		scale = target._MineralTemplate.CollisionRadius
		scale = scale / 0.5
	else
		scale = 1
	end
	scale = scale * target:GetEntityBodyScale()
	if scale > 5 then  -- LRL需求：缩放值最大为5   2018/07/28
		scale = 5
	end
	if scale < 1 then  -- LRL需求：缩放值最小为1   2018/08/22
		scale = 1
	end
	local CElementData = require "Data.CElementData"
	local SpecialValue = string.split(CElementData.GetSpecialIdTemplate(13).Value, "*")
	local MonsterTid = nil
	local ApertureScale = nil
	local BracketsScale = nil
	if SpecialValue ~= nil and #SpecialValue > 0 then
		MonsterTid = SpecialValue[1]
		ApertureScale = SpecialValue[2]
		BracketsScale = SpecialValue[3]
	end
	
	if target:IsMonster() and MonsterTid ~= nil and target._MonsterTemplate.Id == tonumber(MonsterTid) and ApertureScale ~= nil then   -- 新手本的boss特殊处理。 怪物id是40000
		scale = tonumber(ApertureScale)
	end
	return scale
end

-- LRL需求：身上括号最大上限为6     2018/08/20   
local function GetBracketsFxScale(self, target)
	local scale = 0
	if target:IsMonster() then
		scale = target._MonsterTemplate.CollisionRadius	
		scale = scale / 0.5   				-- 不能用主角的半径，不同职业半径不一样  commented by lijian	
	elseif target:IsRole() then
		scale = target._ProfessionTemplate.CollisionRadius
		scale = scale / 0.5
	elseif target:IsMineral() then
		scale = target._MineralTemplate.CollisionRadius
		scale = scale / 0.5
	else
		scale = 1
	end
	scale = scale * target:GetEntityBodyScale() * 0.8  -- LRL 身上特效缩放 乘以 缩放系数
	if scale > 3 then  -- LRL需求：缩放值最大为3   2018/07/28
		scale = 3
	end	
	if scale < 1 then  -- LRL需求：缩放值最小为1   2018/08/22
		scale = 1
	end
	local CElementData = require "Data.CElementData"
	local SpecialValue = string.split(CElementData.GetSpecialIdTemplate(13).Value, "*")
	local MonsterTid = nil
	local ApertureScale = nil
	local BracketsScale = nil
	if SpecialValue ~= nil and #SpecialValue > 0 then
		MonsterTid = SpecialValue[1]
		ApertureScale = SpecialValue[2]
		BracketsScale = SpecialValue[3]
	end

	if target:IsMonster() and MonsterTid ~= nil  and target._MonsterTemplate.Id == tonumber(MonsterTid) and BracketsScale ~= nil then   -- 新手本的boss特殊处理。 怪物id是40000
		scale = tonumber(BracketsScale)
	end
	return scale
end

def.method(CEntity, "boolean").OnTargetSelected = function(self, target, lock)	
	for i,v in pairs(self._ApertureGfxs) do
		if not v or (type(v) == "userdata" and v:Equals(nil)) then					--可能会因为挂在obj身上，obj删除而导致删除
			self._ApertureGfxs[i] = nil
		else
			v.parent = self._UnCachedFxsRoot
			v.localPosition = Vector3.zero
			GameUtil.SetFxScale(v, 0)	
		end
	end

	-- 脚下十字特效  （2018/08/22 删除）
	-- if not IsNil(self._CrossFx) then
	-- 	self._CrossFx.parent = self._UnCachedFxsRoot
	-- 	self.localPosition = Vector3.zero
	-- end
	if not IsNil(self._BracketsFx) then
		self._BracketsFxFollowComp:Apply(false, nil, 0, 0)
		GameUtil.SetFxScale(self._BracketsFx, 0)	
	end

	if target ~= nil  then
		local crossFx = nil
		local apertureFx = nil
		local bracketsFx = nil
		local relation = target:GetRelationWithHost()
		if not lock then -- 自动锁定	    
			if relation == "Enemy" then
				-- 脚底十字特效（2018/08/22 删除） + 脚底圆圈特效（多个）
		    	-- crossFx = GetCrossFx(self)
		    	apertureFx = GetApertureGfx(self, relation)
		    end
		else  -- 强锁
			if relation == "Enemy" then
				-- 脚底十字特效（2018/08/22 删除） + 脚底圆圈特效（多个） + 胸部括号特效
				-- crossFx = GetCrossFx(self)
		    	apertureFx = GetApertureGfx(self, relation)
				bracketsFx = GetBracketsFx(self)
			else
				-- 脚底圆圈特效
				apertureFx = GetApertureGfx(self, relation)
			end			
		end

		-- if crossFx ~= nil then
		-- 	GameUtil.SetLayerRecursively(crossFx, EnumDef.RenderLayer.Fx)
		-- 	crossFx.parent = target:GetGameObject()
		-- 	crossFx.localRotation = Quaternion.identity
		-- 	crossFx.localPosition = Vector3.New(0, 0.1, 0)
		-- 	GameUtil.SetFxScale(crossFx, GetApertureFxScale(self, target))
		-- end

		if apertureFx ~= nil then
			GameUtil.SetLayerRecursively(apertureFx, EnumDef.RenderLayer.Fx)
			apertureFx.parent = target:GetGameObject()
			apertureFx.localRotation = Quaternion.identity
			apertureFx.localPosition = Vector3.New(0, 0.1, 0)
			GameUtil.SetFxScale(apertureFx, GetApertureFxScale(self, target))	
		end

		if bracketsFx ~= nil then					
			GameUtil.SetLayerRecursively(bracketsFx, EnumDef.RenderLayer.Fx)
			local scale = GetBracketsFxScale(self, target)
			local distance = scale < 1 and 1 or scale
			local targetId = 0
			if target:IsMonster() then
				targetId = target._MonsterTemplate.Id
			else
				targetId = target._ID
			end
			self._BracketsFxFollowComp:Apply(true, target:GetGameObject(), distance, targetId)
			GameUtil.SetFxScale(bracketsFx, scale)	
		end
	end
end

--type = 0 时，清空
--type = 1 时，为矩形；param1 为宽，param2为长； param3无效
--type = 2 时，为扇形；param1 为半径，param2无效，param3为角度
--type = 3 时，为圆形；param1 为半径，param2无效； param3无效
def.method("number", "table", "table", "number", "number", "number").DrawSkillCastIndicator = function(self, indictor_type, pos, dir, arg1, arg2, arg3)
	for i,v in pairs(self._SkillIndicatorsGfxs) do
		if not IsNil(v) then
			v.parent = self._UnCachedFxsRoot
			v.localPosition = Vector3.zero
		end
	end

	if indictor_type == 0 then return end
	local gfx = self._SkillIndicatorsGfxs[indictor_type]
	local gfx_prefab = PATH.Skill_Indicator[indictor_type]
	if IsNil(gfx) and gfx_prefab ~= nil and gfx_prefab ~= "" then
	    self._SkillIndicatorsGfxs[indictor_type] = GameUtil.RequestUncachedFx(gfx_prefab)
	end
	if self._SkillIndicatorsGfxs[indictor_type] ~= nil then
	    gfx = self._SkillIndicatorsGfxs[indictor_type]

	    gfx.parent = game._HostPlayer:GetGameObject()
	    gfx.localPosition = Vector3.New(0, 0.1, 0)
		gfx.localRotation = Quaternion.identity

		-- 方向初始大小 1.2*0.8  
	    -- 圆半径 1
	    if indictor_type == 3 then
	    	--gfx.localScale =  Vector3.New(arg1, arg1, arg1)
	    	GameUtil.SetFxScale(gfx, arg1)
	    end
	end
end


def.method("table", "number").DrawSkillRangeIndicator = function(self, pos, radius)
	if IsNil(self._SkillRangeGfx) then
	    self._SkillRangeGfx = GameUtil.RequestUncachedFx(PATH.Skill_HurtArea)
	end
	
	if not IsNil(self._SkillRangeGfx) then
	    pos.y = GameUtil.GetMapHeight(pos)
	    self._SkillRangeGfx.parent = nil
	    self._SkillRangeGfx.position = pos
		self._SkillRangeGfx.localScale =  Vector3.New(radius, radius, radius)
		_G.AddGlobalTimer(0.35, true, function()
				if not IsNil(self._SkillRangeGfx) then
					self._SkillRangeGfx.parent = self._UnCachedFxsRoot
					self._SkillRangeGfx.localPosition = Vector3.zero
				end
			end)
	end
end

def.method("string","table","table","number", "number", "number", "=>",CFxObject).Play = function(self,res_path,pos,rotation, lifetime, scale, priority)
	if self._IsAllFxHiden then return nil end

	local fx, id = GameUtil.RequestFx(res_path, false, priority)
	--if type(fx) == "userdata" and fx:Equals(nil) then return nil end   --防止这种情况
	local fxone = nil
	if fx then
		local fx_scale = scale > 0 and scale or 1
		GameUtil.SetLayerRecursively(fx, EnumDef.RenderLayer.Fx)
		fxone = fx:GetComponent(ClassType.CFxOne)
		fx.position = pos
		if rotation ~= nil then
			fx.rotation = rotation
		else
			fx.rotation = Quaternion.identity
		end	
		fx.localScale = Vector3.one * fx_scale
        fx:SetActive(true)
		GameUtil.SetFxScale(fx, fx_scale)

		fxone:Play(lifetime)
	end
	if fx == nil and id ~= 0 and res_path ~= "" then 
		warn("failed to get fx:", res_path) 
	end

	local fo = CFxObject.new()
	fo:Init(id, fx, fxone)
	return fo
end

def.method("string","userdata", "table", "table","number","boolean", "number", "number", "=>",CFxObject).PlayAsChild = function(self, resName, parent, localpos, localrot, lifetime, isFixRot, scale, priority)
	if self._IsAllFxHiden then return nil end

	local fx, id = GameUtil.RequestFx(resName, isFixRot, priority)
	--if type(fx) == "userdata" and fx:Equals(nil) then return nil end   --防止这种情况
	local fxone = nil
	if fx ~= nil and parent ~= nil then
		local fx_scale = scale > 0 and scale or 1
		GameUtil.SetLayerRecursively(fx, EnumDef.RenderLayer.Fx)
		fx.parent = parent
		fx.localPosition = localpos
		fx.localRotation = localrot
		fx.localScale = Vector3.one * fx_scale
        fx:SetActive(true)
		GameUtil.SetFxScale(fx, fx_scale)
		fxone = fx:GetComponent(ClassType.CFxOne)
		fxone:Play(lifetime)
	end
	
	if fx == nil and id ~= 0 and resName ~= "" then 
		warn("failed to get fx:", resName) 
	end
	
	local fo = CFxObject.new()
	fo:Init(id, fx, fxone)
	return fo
end

def.method("string","table","dynamic","function","number","number","number", "=>",CFxObject).FlyAlongLine = function(self, resName, pos, dest, cb,speed, scale, priority)
	if type(dest) ~= "userdata" and type(dest) ~= "table" then return nil end
	
	local dir = dest - pos
	dir.y = 0
	local rotation = Quaternion.LookRotation(dir, Vector3.up)
	local fxobj = self:Play(resName, pos, rotation, -1, scale, priority)
	if fxobj then
		local go = fxobj:GetGameObject()
		if go ~= nil then
			local motor = go:AddComponent(ClassType.CLinearMotor)
			motor:Fly(pos,dest,speed,0.2,function(g, timeout) 
				if cb then cb(g,dest,resName) end
				self:Stop(fxobj)
			end)
		end
	end

	return fxobj
end

def.method("string","userdata", "userdata", "number", "=>", CFxObject).PlayArcFx = function(self, resPath, parent, target, priority)	
	local fx, id = GameUtil.RequestArcFx(resPath, parent, target, priority)
	local fxone = nil
	if fx ~= nil then
		fxone = fx:GetComponent(ClassType.CFxOne)
		fxone:Play(-1)		
	end
	
	if fx == nil and id ~= 0 and resPath ~= "" then
		warn("failed to get fx:", resPath)
	end

	local fo = CFxObject.new()
	fo:Init(id, fx, fxone)
	return fo
end

def.method("string", "table", "table", "userdata", "number", "number", "number", "number", "number", "=>", CFxObject).PlayBallCurvFx = function(self, resPath, pos, rotation, hudobj, life_time, angle, speed, height, priority)	
	if resPath == nil or resPath == "" then 
		warn("error in PlayBallCurvFx resPath is empty ", debug.traceback())
		return nil 
	end
	local bullet = self:Play(resPath, pos, rotation, life_time, -1, priority)	
	if bullet and hudobj ~= nil then
		local go = bullet:GetGameObject()
		if not IsNil(go) then
			local motor = go:AddComponent(ClassType.CBallCurvMotor)
			if not IsNil(motor) then
				motor:SetParam(height, speed)
				motor:BallCurvFly(pos, hudobj, go, angle)
			end	
		end
	else
		return nil
	end

	return bullet
end

def.method("string","table","userdata","number","number", "number", "boolean", "number", "number", "=>", CFxObject).FlyToTargetGameObject = function(self,resName,pos,target,speed,accelerate, life_time, is_track, scale, priority)
	if resName == nil or resName == "" then 
		warn("resPathName was empty", debug.traceback())
		return nil 
	end

	local dir = target.position - pos
	dir.y = 0
	local rotation = Quaternion.LookRotation(dir, Vector3.up)

	local fxObject = self:Play(resName, pos, rotation, -1, scale, priority)
	if fxObject == nil then return nil end
	
	local go = fxObject:GetGameObject()
	if go ~= nil and target ~= nil then		
		local motor = go:AddComponent(ClassType.CTargetMotor)		
		motor:SetParms(accelerate, not is_track)
		motor:Fly(pos, target, speed, 0.1, function(g, timeout)  
				self:Stop(fxObject)
			end)
	end

	return fxObject
end

def.method("string","table","userdata","number","number","number","function","=>",CFxObject).FlyMutantBezierCurve = function(self,resName,bornPos,target,speed,life_time,priority,cb)
    if resName == nil or resName == "" then 
		warn("resPathName was empty", debug.traceback())
		return nil 
	end
	local fxObject = self:Play(resName, bornPos, Quaternion.identity, -1, -1, priority)
	if fxObject == nil then return nil end

	local go = fxObject:GetGameObject()
	if go ~= nil and target ~= nil then
		local motor = go:AddComponent(ClassType.CMutantBezierMotor)
		motor:Fly(bornPos, target, speed, 0.1, function(g, timeout)
				self:Stop(fxObject)
				if cb ~= nil then cb() end
			end)
	end

	return fxObject
end

def.method(CFxObject).Stop = function(self, gfxobj)
	if gfxobj ~= nil then
		gfxobj:Stop()
	end
end

def.method().Cleanup = function(self)
	self._IsAllFxHiden = false

	GameUtil.FxCacheManCleanup()
	self._ClickGroundGfx = nil
	self._ClickGroundGfxOne = nil
	self._ApertureGfxs = {}
	self._CrossFx = nil
	self._BracketsFx = nil
	self._SkillRangeGfx = nil
	self._SkillIndicatorsGfxs = {}
    self._UnCachedFxsRoot = GameUtil.GetFxManUncachedFxsRoot()
    self._BracketsFxFollowComp = nil
end

CFxMan.Commit()

return CFxMan
