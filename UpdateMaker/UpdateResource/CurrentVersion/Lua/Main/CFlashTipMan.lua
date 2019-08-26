local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CFlashTipMan = Lplus.Class("CFlashTipMan")
local def = CFlashTipMan.define

local instance = nil
def.static("=>",CFlashTipMan).Instance = function()
	if instance == nil then
		instance = CFlashTipMan()
	end
	return instance
end

def.method("string", "string", "number").AddFlashTip = function(self, tip, category, duration)
	local param = 
	{
		item_tip = tip,
		item_category = category,
		item_duration = duration,
	}
	require "GUI.CUIMan".Instance():Open("CFlashTipItem",param)
end

def.method("table").RemoveFlashTip = function(self, tip_inst)
	require "GUI.CUIMan".Instance():Close("CFlashTipItem")
end

--[[
	Tip需要自己实现方法，基本对其方式已经实现好，
	需要自己在onData中调用：
	do
		local Img_BG = self._Panel:FindChild("Img_BG")
    	GUITools.SetRelativePosition(data.Obj, Img_BG, self._AlignType)
	end
]]
def.method("dynamic", "number", "string").ShowPropertyTip = function (self, obj, alignType, tip)
	local data = 	{
						Obj = obj,
						AlignType = alignType,
						Value = tip
					}

	game._GUIMan:Open("CPanelRoleInfoTips", data)
end

CFlashTipMan.Commit()
return CFlashTipMan