-- CPageExample

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CPageExample = Lplus.Class("CPageExample")
local def = CPageExample.define

-- 父Panel类
def.field("table")._Parent = nil
-- 对应页根节点
def.field("userdata")._FrameRoot = nil

-- UI对象缓存
def.field("table")._ItemList = BlankTable
def.field("userdata")._ImgIcon = nil            
def.field("userdata")._LabDisplayName = nil     
def.field("userdata")._BtnChangeName = nil            

-- 数据成员
def.field("table")._InfoList = BlankTable
def.field("boolean")._IsShown = false

def.static("table", "=>", CPageExample).new = function(root)
	local obj = CPageExample()
	obj._Parent = root
	obj:Init()
	return obj 
end

def.method().Init = function(self)
    
end

def.method().Show = function (self)
	if self._IsShown then return end
    -- 
    -- some logic
    --

    self._IsShown = true
end


def.method("string").OnClick = function (self, id)
    
end

def.method("string", "boolean").OnToggle = function(self, id, checked)
    
end

def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    
end

def.method().Hide = function (self)
    if not self._IsShown then return end
    -- 
    -- 清理再次打开时需要更新的逻辑数据
    --

    self._IsShown = false
end

def.method().Destroy = function (self)
    -- 清理界面GameObject引用 + 缓存数据
end

CPageExample.Commit()
return CPageExample