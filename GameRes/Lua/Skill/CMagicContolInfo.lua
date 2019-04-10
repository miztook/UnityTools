local Lplus = require "Lplus"
local CMagicContolInfo = Lplus.Class("CMagicContolInfo")
local CEntity = Lplus.ForwardDeclare("CEntity")
local FightSpecialityType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EffectAddFightSpeciality.FightSpecialityType

local def = CMagicContolInfo.define

def.field("table")._StatesList = BlankTable      -- node 设计成这种形式{ key, value}
def.field(CEntity)._Host = nil -- 附加的主角

def.static(CEntity, "=>", CMagicContolInfo).new = function (host)
	local obj = CMagicContolInfo()
	obj._Host = host
	return obj
end

local function GetPriority(control_type)
	local priority = 0
	if control_type == FightSpecialityType.Forzen then
		priority = 5
	elseif control_type == FightSpecialityType.Dizziness then
		priority = 4
	end
	return priority
end

def.method("table").Init = function(self, states)
	if not states or #states <= 0 then		
		return
	end

	for i = 1, #states do 
		self:Add(states[i])
	end
end
 
local function MakeParam(self, ctrltype)
	local param
	if ctrltype == FightSpecialityType.Forzen then
		param = {}		
		param.ani, param.time = self._Host:GetCurAniClip()
	elseif ctrltype == FightSpecialityType.Dizziness then

	end
	return param
end


-- 更新单独的魔法状态
def.method("number").Add = function(self, state)
	for _, v in ipairs(self._StatesList) do 
		if v.key == state then
			return
		end
	end

	local priority = GetPriority(state)  --优先级
	local data = MakeParam(self, state)
	local tmp = {key = state, value = priority, param = data}
	table.insert(self._StatesList, tmp)

	-- 进行排序
	local function SortList(node1, node2)
		return node1.value > node2.value
	end
	table.sort(self._StatesList, SortList)
end

-- 删除指定魔法状态
def.method("number").Remove = function(self, state)
	for i = #self._StatesList, 1, -1 do
		local v = self._StatesList[i]
		if v.key == state then
			-- 去除状态
			if state == FightSpecialityType.Forzen then
				local CVisualEffectMan = require "Effects.CVisualEffectMan"
				CVisualEffectMan.DoFreezen(self._Host, false)  

				-- 变身后重置主模型
				if self._Host:IsModelChanged() then
					GameUtil.AddObjectEffect(self._Host:GetOriModel():GetGameObject(), 10, 0)
				end

				if v.param and v.param.ani then				
					self._Host:PlayAssignedAniClip(v.param.ani, v.param.time)
				else
					--self._Host:StopNaviCal()  -- _StatesList还未清除数据，StopNaviCal走空逻辑
				end
			end
			table.remove(self._StatesList, i)		
		end
	end	
end

-- 获取优先级最高的状态 做处理
def.method("=>","number").GetPriState = function(self)
	return -1
end

-- 获取长度
def.method("=>","number").GetLength = function(self)
	if self._StatesList then
		return #self._StatesList
	end
	return 0
end

-- 刷新当前魔法控制状态
def.method().Refresh = function(self)
	-- TODO: 此状态会在OnModelLoaded中调用，因为和Stand/Dead调用顺序有前有后，可能会出现状态错误
	-- 刷新新的状态	
	if self:GetLength() > 0 then  -- 排序以保证 优先级最高
		local node = self._StatesList[1]	
		if node.key == FightSpecialityType.Forzen then
			local CVisualEffectMan = require "Effects.CVisualEffectMan"
			CVisualEffectMan.DoFreezen(self._Host, true)  
		elseif node.key == FightSpecialityType.Dizziness then	-- 控制状态下不眩晕				
			if not self._Host:IsPhysicalControled() then
				self._Host:PlayAnimation(EnumDef.CLIP.STUN, 0, false, 0, 1)
			end
		end		
	end	
end

def.method().Release = function(self)
	self._StatesList = {}
	self._Host = nil
end

CMagicContolInfo.Commit()
return CMagicContolInfo

