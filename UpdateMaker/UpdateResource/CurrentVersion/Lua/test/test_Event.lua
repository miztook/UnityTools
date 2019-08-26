
local Lplus = require "Lplus"

-- ！！！！ 仅是一个使用案例

-- 定义一个event
local CGFinishEvent = Lplus.Class("CGFinishEvent")
do
	local def = CGFinishEvent.define
	
	def.field("number")._EventType = 0
	def.field("number")._Pre = 0
	
	def.static("number", "number", "=>", CGFinishEvent).new = function (event_type, pre)
		local obj = CGFinishEvent()
		obj._EventType = event_type
		obj._Pre = pre
		return obj
	end
end
CGFinishEvent.Commit()

-- 注册监听CGFinishEvent事件
CGame.EventManager:addHandler(CGFinishEvent, function (sender, event)
		-- process event
	end)

-- 触发CGFinishEvent事件
CGame.EventManager:raiseEvent(nil, event)