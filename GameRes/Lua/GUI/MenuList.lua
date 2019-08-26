
-- CInteractiveMenuMan 只在这里引用了，最好将相关代码整合到这里  -- added by Jerry

local _ShowMenuList = function(comps, obj, alignType)
    local interactiveMan = require "GUI.CInteractiveMenuMan"
    interactiveMan.Instance():ShowMenuList(comps, obj, alignType)
end

local _CloseCurList = function()
    local interactiveMan = require "GUI.CInteractiveMenuMan"
    interactiveMan.Instance():CloseMenu()
end

local MenuList = {
    Show = _ShowMenuList,
    Close = _CloseCurList
}

_G.MenuList = MenuList