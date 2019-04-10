local Lplus = require "Lplus"

local CFxObject = Lplus.Class("CFxObject")
local def = CFxObject.define

def.field("number")._ID = 0
def.field("userdata")._GameoObject = nil
def.field("userdata")._FxOne = nil

def.static("=>", CFxObject).new = function()
	local fx = CFxObject()
	return fx
end

def.method("number", "userdata", "userdata").Init = function(self, id, go, fxone)
    self._ID = id
    self._GameoObject = go
    self._FxOne = fxone
    if fxone == nil and go ~= nil then
        self._FxOne = go:GetComponent(ClassType.CFxOne)
    end
end

def.method("=>", "userdata").GetGameObject = function(self)
    if self._GameoObject ~= nil and self._GameoObject:Equals(nil) then
        return nil 
    end
    
	return self._GameoObject
end

def.method("number").ChangeSpeed = function(self, speed)
    if self._GameoObject ~= nil and not self._GameoObject:Equals(nil) then
        GameUtil.ChangeGfxPlaySpeed(self._GameoObject, speed)
    end
end

def.method("=>", "boolean").IsReleased = function(self)
    return self._GameoObject == nil or self._GameoObject:Equals(nil)
end

def.method("=>", "boolean").IsPlaying = function(self)
    return self._FxOne ~= nil and not self._FxOne:Equals(nil) and self._FxOne.IsPlaying
end

def.method().Stop = function(self)
    -- 技能特效的C#清理一般都是按照c# timer来的，而lua中的对象只有在技能结束/段结束/打断等时候才调用
    -- 可能存在C# Lua不一致的情况
    if self._GameoObject ~= nil and not self._GameoObject:Equals(nil) then
        GameUtil.StopGfx(self._GameoObject, self._ID)
    end
    self._GameoObject = nil
    self._FxOne = nil
    self._ID = 0
end

CFxObject.Commit()
return CFxObject