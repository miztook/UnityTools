--[[
	各种常用异步操作 Task
]]

local Lplus = require "Lplus"
local Task = require "Utility.Task"

local AsyncTask = Lplus.Class("AsyncTask")
do
	local def = AsyncTask.define
	
	--[[
		给Task增加时间限制。超时则取消。-1 为无时限
	]]
	def.static(Task, "number", "=>", Task).AddTimelimit = function (task, timeout)
		if timeout >= 0 then
			local timer = _G.AddGlobalTimer(timeout, true, function ()
				task:cancel()
			end)
			
			task:continueWith(function ()
				_G.RemoveGlobalTimer(timer)
			end)
		end
		return task
	end
	
	--[[
		等待一段时间。-1 为无时限
	]]
	def.static("number", "=>", Task).WaitForTime = function (seconds)
		return Task.createOneStepEx(function (task)
			return function (task, resumeEntry)
				_G.AddGlobalTimer(seconds, true, function ()
					resumeEntry()
				end)
			end
		end, function () return "stop" end)
	end
end
return AsyncTask.Commit()

