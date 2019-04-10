--[[
	class Task
	Lua port of .NET System.Threading.Task
	Differences:
		run in single thread
		has sub Task, which is similar to function call
		continueWith return the self Task
	
	Example, wait for 2 seconds:
		-- coroutine style
		local task = Task.createCo(function (task)
			print "begin"
			coroutine.yield(waitForSeconds(2))		--to perform asynchromize operation, yield it
			print "finished"
			coroutine.yield "end"
		end)
		
		-- function style
		local step = 1
		local task = Task.create(function (task)
			if step == 1 then
				print "begin"
				step = step + 1
				return waitForSeconds(2)
			elseif step == 2 then
				print "finished"
				return "end"
			end
		end)
]]

local Lplus = require "Lplus"
local debug = require "debug"
local type = type
local error = error
local assert = assert
local tostring = tostring
local require = require

local _ENV = nil

local Task = Lplus.Class("Task")
do
	local def = Task.define
	
	--
	-- utilities
	--
	local function checkSimpleType (value, who, argIndex, needType, errLevel)
		if type(value) ~= needType then
			error(([[bad argument #%d to %s in 'Task' (%s expected, got %s)]]):format(argIndex, who, needType, type(value)), errLevel+1)
		end
	end
	
	local function checkNonNil (value, who, argIndex, errLevel)
		if value == nil then
			error(([[bad argument #%d to %s in 'Task' (non-nil expected, got nil)]]):format(argIndex, who, errLevel+1))
		end
	end
	
	--[[
		Initializes a new Task with the specified action
		Action gets Task as it's first param, the following params are return value from previous async operation
			the first return value of action can be:
				"end": finish Task
				"continue": continue Task
				function: async operation
					first param is the Task itself; it's second param is a resume entry function, 
					call the resume entry function to resume Task. Only the first call resume Task, other calls are ignored
			the second return value of action is the result of Task
		param action: the action to execute in the Task
	]]
	def.static("function", "=>", Task).create = function (action)
		return Task.createEx(action, nil)
	end
	
	--[[
		param cancelCallback: the callback will be called when Task been canceled, can be nil
			Gets Task as it's param
			Return "stop" to stop Task immediately, or other value to wait for Task exit normally
				if decided to stop Task immediately, should check task:isActive() during async operation
	]]
	def.static("function", "function", "=>", Task).createEx = function (action, cancelCallback)
		local obj = Task()
		obj.m_action = action
		obj.m_cancelCallback = cancelCallback
		return obj
	end
	
	--[[
		Create Task from coroutine function
	]]
	def.static("function", "=>", Task).createCo = function (actionCo)
		return Task.createCoEx(actionCo, nil)
	end
	
	--[[
		Create Task from coroutine function
	]]
	def.static("function", "function", "=>", Task).createCoEx = function (actionCo, cancelCallback)
		return Task.createEx(Task.wrapCoroutine(actionCo), cancelCallback)
	end
	
	--[[
		Create Task from step action.
		Step action received Task and current step of it's params. The step starts from 1
	]]
	def.static("function", "=>", Task).createSteps = function (action)
		return Task.createStepsEx(action, nil)
	end
	
	--[[
		Create Task from step action.
		Step action received Task and current step of it's params. The step starts from 1
	]]
	def.static("function", "function", "=>", Task).createStepsEx = function (action, cancelCallback)
		local step = 0
		local function actionFunc (task, ...)
			step = step + 1
			return action(task, step, ...)
		end
		return Task.createEx(actionFunc, cancelCallback)
	end
	
	--[[
		Create Task from one step action. The first step execute the given action, the second finish Task
		The first param sent to resume entry will be the result of task
	]]
	def.static("function", "=>", Task).createOneStep = function (action)
		return Task.createOneStepEx(action, nil)
	end
	
	--[[
		Create Task from one step action. The first step execute the given action, the second finish Task
		The first param sent to resume entry will be the result of task
	]]
	def.static("function", "function", "=>", Task).createOneStepEx = function (action, cancelCallback)
		local firstStep = true
		local function actionFunc (task, result)
			if firstStep then
				firstStep = false
				return action(task)
			else
				return "end", result
			end
		end
		return Task.createEx(actionFunc, cancelCallback)
	end
	
	--[[
		Starts the Task
	]]
	def.method().start = function (self)
		if self.m_status ~= "created" then
			error("can not start a task which is already started")
		end
		
		-- make a new closure each time when need a entry, to avoid entering for multiple times
		local function makeResumEntry ()
			local firstTime = true
			local function resumeEntry (...)
				if not firstTime then
					return
				end
				firstTime = false
				
				if self.m_canceled then
					self:finishTask(nil)
					return
				end
				
				-- execute a step
				local asyncOp, result = self.m_action(self, ...)
				while asyncOp == "continue" do
					if self.m_canceled then
						self:finishTask(nil)
						return
					end
					asyncOp, result = self.m_action(self, ...)
				end
				
				if self.m_canceled then
					self:finishTask(nil)
					return
				end
				
				if asyncOp == "end" then
					self:finishTask(result)
				elseif type(asyncOp) == "function" then
					asyncOp(self, makeResumEntry())
				else
					error(([[bad return value from action, should be "end" or async operation, got %s (%s)]]):
						format(tostring(asyncOp), type(asyncOp)))
				end
			end
			return resumeEntry
		end
		
		self.m_status = "running"
		makeResumEntry()()
	end
	
	--[[
		Starts the Task and attach to parent
		The parent task does not finish until the self task finished
	]]
	def.method(Task).startAsChild = function (self, parent)
		checkNonNil(parent, "startAsChild", 2, 2)
		if self.m_parent then
			error("can not start a child task which is already started")
		end
		self.m_parent = parent
		parent:incWaitingChildCount()
		parent:appendCancelNotify(self)
		
		self:start()
	end
	
	--[[
		Starts the Task and attach to parent
		The parent task does not finish until the self task finished
		param cancelWithParent: if parent Task is canceled, cancel self Task
	]]
	def.method(Task, "boolean").startAsChildEx = function (self, parent, cancelWithParent)
		checkNonNil(parent, "startAsChildEx", 2, 2)
		if self.m_parent then
			error("can not start a child task which is already started")
		end
		self.m_parent = parent
		parent:incWaitingChildCount()
		
		if cancelWithParent then
			parent:appendCancelNotify(self)
		end
		
		self:start()
	end
	
	--[[
		Create a async operation that executes a sub Task
		param sub: the sub task to execute, the self Task will continue after the sub Task finished
	]]
	def.method(Task, "=>", "function").executeSub = function (self, sub)
		checkNonNil(sub, "executeSub", 2, 2)
		local function subResumeFunction (task, resumeEntry)
			self:appendCancelNotify(sub)
			sub.m_nextResumeEntry = resumeEntry
			sub:start()
		end
		return subResumeFunction
	end
	
	--[[
		Create a async operation that executes a sub Task. If sub Task is canceled, cancel the self Task
		param sub: the sub task to execute, the self Task will continue after the sub Task finished
	]]
	def.method(Task, "=>", "function").completeSub = function (self, sub)
		checkNonNil(sub, "completeSub", 2, 2)
		local function subResumeFunction (task, resumeEntry)
			self:appendCancelNotify(sub)
			sub.m_nextResumeEntry = function ()
				if sub:isCanceled() then
					task:cancel()
				end
				resumeEntry()
			end
			sub:start()
		end
		return subResumeFunction
	end
	
	--[[
		Execute the continuation when the target Task completes (including canceled)
		param continuationFunction: a function to run when the Task finished. The finished task will be passed as an argument
		return: the Task itself
	]]
	def.method("function", "=>", Task).continueWith = function (self, continuationFunction)
		checkNonNil(continuationFunction, "continueWith", 2, 2)
		if self.m_status == "canceled" or self.m_status == "completed" then
			continuationFunction(self)
		else
			self:appendContinuation(continuationFunction)
		end
		return self
	end
	
	--[[
		Execute the continuation when the target Task completes successfully
		param continuationFunction: a function to run when the Task finished. The finished task will be passed as an argument
		return: the Task itself
	]]
	def.method("function", "=>", Task).completeWith = function (self, continuationFunction)
		checkNonNil(continuationFunction, "completeWith", 2, 2)
		self:continueWith(function (task)
			if not task.m_canceled then
				continuationFunction(task)
			end
		end)
		return self
	end
	
	--[[
		Execute the continuation when the target Task canceled
		param continuationFunction: a function to run when the Task completes. The finished task will be passed as an argument
		return: the Task itself
	]]
	def.method("function", "=>", Task).cancelWith = function (self, continuationFunction)
		checkNonNil(continuationFunction, "cancelWith", 2, 2)
		self:continueWith(function (task)
			if task.m_canceled then
				continuationFunction(task)
			end
		end)
		return self
	end
	
	--[[
		Get result of Task
		if no result from Task action, return nil
	]]
	def.method("=>", "dynamic").getResult = function (self)
		return self.m_result
	end
	
	--[[
		Cancel the Task
		Has no effect if the Task is already canceled or completed
	]]
	def.method().cancel = function (self)
		if self.m_canceled or self.m_status == "completed" then
			return
		end
		
		self.m_canceled = true
		
		local notifyList = self.m_cancelNotifyList
		if notifyList then
			for i = #notifyList, 1, -1 do
				notifyList[i]:cancel()
			end
		end
		local cancelCallback = self.m_cancelCallback
		if cancelCallback then
			local ret = cancelCallback(self)
			if ret == "stop" then
				self:finishTask(nil)
			end
		end
	end
	
	--[[
		Whether Task is active, which means been running and not canceled
	]]
	def.method("=>", "boolean").isActive = function (self)
		return self.m_status == "running" and not self.m_canceled
	end
	
	--[[
		Whether Task is canceled
	]]
	def.method("=>", "boolean").isCanceled = function (self)
		return not not self.m_canceled
	end
	
	--[[
		Whether Task is completed successfully
	]]
	def.method("=>", "boolean").isCompleted = function (self)
		return self.m_status == "completed"
	end
	
	--[[
		Get status of the Task
		return: current status, would be one of these values:
			"created": initialized but not scheduled
			"running": running
			"waiting_for_children": finished executing, waiting for children
			"completed": completed successfully
			"canceled": canceled
	]]
	def.method("=>", "string").getStatus = function (self)
		return self.m_status
	end
	
	--[[
		Create a closure which is suitable for Task.create, from a coroutine function
		the coroutine function gets Task as it's param
	]]
	def.static("function", "=>", "function").wrapCoroutine = function (f)
		local coroutine = require "coroutine"

		local co = coroutine.create(f)
		local coresume = coroutine.resume
		local costatus = coroutine.status
				
		local function wrapper (task, ...)
			if costatus(co) ~= "dead" then
				local succ, ret1, ret2 = coresume(co, task, ...)
				if succ then
					return ret1, ret2
				else
					local err = ret1
					local info = debug.getinfo(f, "nS")
					error(("wrapped coroutine function has error: %s")
						:format(tostring(err)))
					
				end
			else
				local info = debug.getinfo(f, "S")
				error(("wrapped coroutine exit without either finish or cancel: %s:%d")
					:format(info.source, info.linedefined))
			end
		end
		return wrapper
	end
	
	
	-------------------------------------
	-- end of public
	-------------------------------------
	
	--required
	def.field("function").m_action = nil
	
	def.field("dynamic").m_result = nil
	
	def.field("string").m_status = "created"
	
	--nil or true
	def.field("dynamic").m_canceled = nil
	
	def.field("function").m_cancelCallback = nil
	
	--function or function array
	def.field("dynamic").m_continuations = nil
	
	def.field(Task).m_parent = nil
	
	--nil (0) or number
	def.field("dynamic").m_waitingChildCount = nil
	
	def.field("function").m_nextResumeEntry = nil
	
	def.field("table").m_cancelNotifyList = nil
	
	def.method(Task).appendCancelNotify = function (self, task)
		local cancelNotifyList = self.m_cancelNotifyList
		if cancelNotifyList == nil then
			cancelNotifyList = {}
			self.m_cancelNotifyList = cancelNotifyList
		end
		cancelNotifyList[#cancelNotifyList+1] = task
	end

	def.method("dynamic").finishTask = function (self, result)
		if self.m_status ~= "running" then
			return
		end
		
		self.m_result = result
		
		-- wait for children
		if not self.m_waitingChildCount then
			self:completeTask()
		else
			self.m_status = "waiting_for_children"
		end
	end
	
	def.method().completeTask = function (self)
	--warn("bbbbbbbbb")
		--set state
		if self.m_canceled then
			self.m_status = "canceled"
		else
			self.m_status = "completed"
		end
		
		-- execute continuations
		local continuations = self.m_continuations
		if continuations == nil then
		elseif type(continuations) == "function" then	--single function
			continuations(self)
		else	--function array
			for i = 1, #continuations do
				continuations[i](self)
			end
		end
		
		--notify parent
		local parent = self.m_parent
		if parent then
			parent:onChildComplete(self)
		end
		
		-- enter next resumeEntry (sub Task)
		local nextResumeEntry = self.m_nextResumeEntry
		if nextResumeEntry then
			nextResumeEntry()
		end
	end
	
	def.method(Task).onChildComplete = function (self, child)
		if self:decWaitingChildCount() then
			self:completeTask()
		end
	end
	
	def.method("function").appendContinuation = function (self, f)
		local current = self.m_continuations
		if current == nil then
			self.m_continuations = f
		elseif type(current) == "function" then
			self.m_continuations = { current, f }
		else
			current[#current+1] = f
		end
	end
	
	def.method().incWaitingChildCount = function (self)
		local waitingChildCount = self.m_waitingChildCount
		if waitingChildCount then
			self.m_waitingChildCount = waitingChildCount + 1
		else
			self.m_waitingChildCount = 1
		end
	end
	
	-- return: true means get to zero
	def.method("=>", "boolean").decWaitingChildCount = function (self)
		local waitingChildCount = self.m_waitingChildCount
		if waitingChildCount == 1 then
			self.m_waitingChildCount = nil
			return true
		else
			self.m_waitingChildCount = waitingChildCount - 1
			return false
		end
	end
end
return Task.Commit()
