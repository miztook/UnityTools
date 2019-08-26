local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"

local CVisualEffectMan = Lplus.Class("CVisualEffectMan")
local def = CVisualEffectMan.define

def.static().Init = function()
	-- 将来可能需要做资源预加载
end

--[[ ----------------------------
 --   以下效果作用对象为Object
---------------------------------]]

def.static(CEntity, "table", "number", "number", "number", "function").DoFlyingDie = function(obj, dir, force, mass, corpse_stay_duration, cb)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 1, dir, force, mass, corpse_stay_duration)
			obj:AddTimer(5, true, function()
					if cb ~= nil then cb() end
				end)
		end
	end
end

-- 破绽闪红，逻辑控制其开关
def.static(CEntity, "boolean", "number", "number", "number", "number").EnableRimColorEffect = function(obj, enabled, r, g, b, power)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 6, enabled, r, g, b, power)
		end
	end
end

-- 受击闪白，闪一下
def.static(CEntity).StartTwinkleWhiteEffect = function(obj)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			if obj:IsHostPlayer() then
				GameUtil.AddObjectEffect(md:GetGameObject(), 7, 0.3, 1, 0, 0, 1, 5)
			else
				GameUtil.AddObjectEffect(md:GetGameObject(), 7, 0.3, 1, 1, 1, 200/255, 2.5)				
			end			
		end
	end
end

def.static(CEntity).StopTwinkleWhiteEffect = function(obj)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md ~= nil and md:IsReady() then			
			GameUtil.AddObjectEffect(md:GetGameObject(), 3)
			local oriModel = obj:GetOriModel()
			if oriModel ~= nil and oriModel ~= md then
				GameUtil.AddObjectEffect(oriModel:GetGameObject(), 3)
			end
		end
	end
end

-- 死亡溶解 param -> color
def.static(CEntity, "number", "number", "number", "number").DissolveDie = function(obj, duration, r, g, b)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			if r and g and b then
				GameUtil.AddObjectEffect(md:GetGameObject(), 13, duration,  r,  g, b, 255)
			else
				GameUtil.AddObjectEffect(md:GetGameObject(), 13, duration, 255,255,255,255)
			end
		end
	end
end

-- 选中颜色 0- 无颜色  1- 红  2- 蓝  3- 黄
def.static(CEntity,"number","number","number","number").EliteBornColor = function(obj, r, g, b, power)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 8, r, g, b, power)
		end
	end
end

def.static(CEntity, "boolean").DoFreezen = function(obj, enabled)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 10, enabled)
		end
	end
end

def.static(CEntity, "boolean").DoStealth = function(obj, on)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then		
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 12, on)
		end
	end
end

-- 显示刀光
def.static(CEntity, "boolean").ShowBladeEffect = function(obj, on)
	if obj ~= nil and obj:IsCullingVisible() and not IsNil(obj:GetGameObject()) then		
		local md = obj:GetCurModel()
		if md and md:IsReady() then
			GameUtil.AddObjectEffect(md:GetGameObject(), 14, on)
		end
	end
end

--[[ ----------------------------
 --   以下为相机或屏幕效果
---------------------------------]]
-- 淡入时间，淡出时间，持续时间，振幅，频率
-- 摇镜头（panning shot）
def.static("number", "number", "number", "number", "number", "string").ShakeCamera = function(fadein_time, fadeout_time, last_time, magnitude, roughness, key)
	GameUtil.AddCameraOrScreenEffect(1, fadein_time, fadeout_time, last_time, magnitude, roughness, key)
end

-- 打断震屏
def.static("string").StopCameraShake = function(key)
	GameUtil.StopSkillScreenEffect(1, key)
end

-- 移镜头（traveling shot）
def.static("number", "number", "number", "number").MoveOrRotateCamera = function(dis_radio, change_duration, keep_duration, change_back_duration)
	GameUtil.AddCameraOrScreenEffect(2, dis_radio, change_duration, keep_duration, change_back_duration)
end

-- 打断镜头移动
def.static().StopCameraStretch = function()
	GameUtil.StopSkillScreenEffect(2)
end

-- 运动模糊  level：模糊程度 fadein_duration: 淡入到最大模糊程度所需时间, keep_max_duration：模糊时间 （根据摄像机运动走就不需要这个参数）
def.static("number", "number", "number", "number").StartMotionBlur = function(level, fadein_duration, keep_max_duration, fadeout_duration)
	GameUtil.AddCameraOrScreenEffect(3, level, fadein_duration, keep_max_duration, fadeout_duration)
end

def.static("boolean", "number", "number", "number", "number", "number", "number", "number").ScreenColor = function(is_open, fade_in, keep, fade_out, color_r, color_g, color_b, color_a)
	GameUtil.AddCameraOrScreenEffect(4, is_open, fade_in, keep, fade_out, color_r, color_g, color_b, color_a)
end

-- 神之视界
def.static("boolean").EnableHawkeyeEffect = function(isOn)
	GameUtil.EnableSpecialVisionEffect(isOn)
end


-- 子物体专用 因资源加载与fxone 做成了一体 数据做了缓存
def.static("userdata", "boolean", "number", "number", "number", "number", "number").StartRadialBlurAtActor = function(obj, ison, fade_in, duration, fade_out, level, radius)
	if not IsNil(obj) then		
		GameUtil.AddObjectEffect(obj, 15, ison, fade_in, duration, fade_out, level, radius)
	end
end

-- 技能专用 即时显示 obj为技能释放对象
def.static("userdata", "string", "number", "number", "number", "number", "number").StartRadialBlurAtEntity = function(obj, hang_point, fade_in, duration, fade_out, level, radius)
	if not IsNil(obj) then		
		GameUtil.AddObjectEffect(obj, 16, hang_point, fade_in, duration, fade_out, level, radius)
	end
end

def.static("userdata").StopRadialBlurEffect = function(obj)
	if not IsNil(obj) then	
		GameUtil.StopSkillScreenEffect(3, obj)  -- 
	end
end

CVisualEffectMan.Commit()
return CVisualEffectMan
