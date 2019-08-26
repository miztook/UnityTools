-- loop queue
local Lplus = require "Lplus"
local CLoopQueue = Lplus.Class("CLoopQueue")
local def = CLoopQueue.define
def.field("number")._MaxCount = 10
def.field("table")._Array = nil
def.field("number")._Count = 0
def.field("number")._IdStart = 0

def.static("=>", CLoopQueue).new = function()
	local obj = CLoopQueue()
	return obj
end

def.method("number").Init = function(self, max_count)
	self._Array = { }
	self._MaxCount = max_count
	self._IdStart = 0
	self._Count = 0
end

local function Loop(num, max)
	local fm = math.fmod(num, max)
	if fm <= 0 then fm = fm + max end
	return fm
end

def.method("dynamic").EnQueue = function(self, value)

	self._IdStart = Loop(self._IdStart + 1, self._MaxCount)
	if self._Count < self._MaxCount then
		self._Count = self._Count + 1
	end

	-- warn("EnQ "..self._IdStart.." "..value)
	-- local i=Loop(self._IdStart+self._Count-1, self._MaxCount)

	self._Array[self._IdStart] = value
	--warn("EnQueue at " .. self._IdStart)
end

def.method().DeQueue = function(self)
	if self._Count > 0 then
		self._Count = self._Count - 1
	end
end

def.method("number").Remove = function(self, id)
	if id > 0 and id <= self._Count then
		for i = id - 1, self._Count - 2 do
			local lid = Loop(self._IdStart - i, self._MaxCount)
			local lid1 = Loop(self._IdStart - i - 1, self._MaxCount)

			--warn("Copy to " .. tostring(lid) .. "->" .. tostring(lid1))

			self._Array[lid] = self._Array[lid1]
		end
		self._Count = self._Count - 1
	end
end

def.method("number", "=>", "dynamic").GetAt = function(self, id)
	if id > 0 and id <= self._Count then
		id = Loop(self._IdStart - id + 1, self._MaxCount)

		-- if self._Array[id]~=nil then warn("GetAt "..id.." not nil") end

		return self._Array[id]
	end
	return nil
end

def.method("=>", "number").Count = function(self)
	return self._Count
end

CLoopQueue.Commit()
return CLoopQueue
-- loop queue