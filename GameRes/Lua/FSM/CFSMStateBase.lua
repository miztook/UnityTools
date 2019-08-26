local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE

local CFSMStateBase = Lplus.Class("CFSMStateBase")
local def = CFSMStateBase.define

def.field(CEntity)._Host = nil
def.field("number")._Type = 0
def.field("boolean")._IsValid = true
def.field("boolean")._Mountable = false

def.final("=>", CFSMStateBase).new = function ()
	local obj = CFSMStateBase()
	return obj
end

-- oldstate表示之前的状态，用来判断是否可以状态切换
def.virtual("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return true;
end

-- oldstate表示之前的状态，在进入此函数之前已经进行过 oldstate.LeaveState()的调用
def.virtual("number").EnterState = function(self, oldstate)
	self._IsValid = true
end

--虚函数，在每个state中重载，表示播放这个状态的动画，而不改变状态的其他逻辑
def.virtual("number").PlayStateAnimation = function(self, oldstate)			
end

-- 虚函数 根据主角当前状态（战斗或是骑马）播放动画以及控制播放的速度
def.virtual("number").PlayMountStateAnimation = function(self, oldstate)
end

-- elseplayer由不可见到可见时，需要刷新动作 位置点
def.virtual().UpdateWhenBecomeVisible = function(self)
end

def.method().CheckMountable = function (self)
	if self._Host == nil then
		self._Mountable = false
		return
	end

	local objType = self._Host:GetObjectType()
	self._Mountable = ( objType == OBJ_TYPE.ELSEPLAYER or objType == OBJ_TYPE.HOSTPLAYER )
end

-- 状态结束后进行清理工作
def.virtual().LeaveState = function(self)
	self._IsValid = false
	self._Host = nil
end

-- 一个状态需要更新参数时候会调用，例如移动状态下更新移动的方向等
def.virtual(CFSMStateBase).UpdateState = function(self, newstate)

end

CFSMStateBase.Commit()
return CFSMStateBase
