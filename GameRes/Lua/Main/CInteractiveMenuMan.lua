
local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CInteractiveMenuMan = Lplus.Class("CInteractiveMenuMan")
local def = CInteractiveMenuMan.define
local instance = nil

def.field("table")._ListenerDic = BlankTable
def.field("table")._OpenedMenu = nil

def.static("=>", CInteractiveMenuMan).Instance = function()
    if not instance then
        instance = CInteractiveMenuMan()
    end
	return instance
end

----------------------------------------------
--根据AlignType(EnumDef.AlignType..)来让菜单停靠在obj的边上
----------------------------------------------
def.method("table", "dynamic", "dynamic").ShowMenuList = function (self, comps, obj, alignType)
	local data = {
        comps = comps,
        targetObj = obj,
        alignType = alignType
    }
	self._OpenedMenu = game._GUIMan:Open("CPanelInteractiveMenu",data)
end

def.method().CloseMenu = function(self)
    if self._OpenedMenu ~= nil then
        self._OpenedMenu:Close()
        self._OpenedMenu = nil
    end
end

CInteractiveMenuMan.Commit()
return CInteractiveMenuMan