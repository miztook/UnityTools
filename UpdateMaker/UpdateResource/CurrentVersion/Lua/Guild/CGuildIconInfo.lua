local Lplus = require "Lplus"
local CGuildIconInfo = Lplus.Class("CGuildIconInfo")
local def = CGuildIconInfo.define

-- 底色
def.field("number")._BaseColorID = 0
-- 边框
def.field("number")._FrameID = 0
-- 图片
def.field("number")._ImageID = 0

def.static("=>", CGuildIconInfo).new = function()
	local obj = CGuildIconInfo()
	return obj
end

--重置公会旗帜
def.method().ResetGuildIconInfo = function(self)
	self._BaseColorID = 0
	self._FrameID = 0
	self._ImageID = 0
end

CGuildIconInfo.Commit()
return CGuildIconInfo