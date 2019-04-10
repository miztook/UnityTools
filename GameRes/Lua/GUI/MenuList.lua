
local _ShowMenuList = function(comps, obj, alignType)
    local interactiveMan = require "Main.CInteractiveMenuMan"
    interactiveMan.Instance():ShowMenuList(comps, obj, alignType)
end

local _CloseCurList = function()
    local interactiveMan = require "Main.CInteractiveMenuMan"
    interactiveMan.Instance():CloseMenu()
end

local MenuList = {
    Show = _ShowMenuList,
    Close = _CloseCurList
}

_G.MenuList = MenuList