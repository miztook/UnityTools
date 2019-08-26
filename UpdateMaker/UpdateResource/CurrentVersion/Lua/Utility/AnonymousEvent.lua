--[[
	class AnonymousEvent
	With AnonymousEvent, event is sended to handlers who are registered with the same argument type as the event
]]

local Lplus = require "Lplus"
local pairs = pairs
local error = error
local type = type
local Object = Lplus.Object
local Lplus_typeof = Lplus.typeof
local Lplus_isTypeTable = Lplus.isTypeTable
local Lplus_is = Lplus.is
local GcCallbacks = require "Utility.GcCallbacks"
local _ENV = nil

local AnonymousEventManager = Lplus.Class("AnonymousEventManager")
do
	local def = AnonymousEventManager.define
	
	-- argType => handlerChain
	def.field("table").m_handlerChainMap = function () return {} end
	--
	-- utilities
	--
	local function clearTable (t)
		for k, _ in pairs(t) do
			t[k] = nil
		end
	end

	local function checkObject (obj, who, argIndex, errLevel)
		if not Lplus_is(obj, Object) then
			error(([[bad argument #%d to %s in 'AnonymousEventManager' (Lplus Object expected, got %s)]]):format(argIndex, who, type(obj)), errLevel+1)
		end
	end

	local function checkTypeTable (typeTable, who, argIndex, errLevel)
		if not Lplus_isTypeTable(typeTable) then
			error(([[bad argument #%d to %s in 'AnonymousEventManager' (type table expected, got %s)]]):format(argIndex, who, type(typeTable)), errLevel+1)
		end
	end

	local function checkSimpleType (value, who, argIndex, needType, errLevel)
		if type(value) ~= needType then
			warn(debug.traceback())
			error(([[bad argument #%d to %s in 'AnonymousEventManager' (%s expected, got %s)]]):format(argIndex, who, needType, type(value)), errLevel+1)
		end
	end

	-- removed flag
	local function REMOVED_HANDLER () end
	
	local function addToChain (chain, handler)
		chain[#chain+1] = handler
	end
	
	local function removeFromChain (chain, handler)
		for i = 1, #chain do
			if chain[i] == handler then
				chain[i] = REMOVED_HANDLER
				break
			end
		end
	end
	
	local function remove (arr, value)
		-- silimar to std::remove
		
		--scan and shift
		local iRemained = 1
		for iCur = 1, #arr do
			local cur = arr[iCur]
			if cur == value then	--removed
			else	--remained
				arr[iRemained] = cur
				iRemained = iRemained + 1
			end
		end
		
		--do remove
		for i = #arr, iRemained, -1 do
			arr[i] = nil
		end
	end
	
	local function cleanupChain (chain)
		remove(chain, REMOVED_HANDLER)
	end
	
	local function raiseEvent_internal (self, sender, arg, argTypeTable)
		local handlerChain = self.m_handlerChainMap[argTypeTable]
		if handlerChain then
			local bHasRemovedHandler = false
			-- invoke all
			for i = 1, #handlerChain do
				local handler = handlerChain[i]
				if handler ~= REMOVED_HANDLER then
					if handler ~= nil then
						handler(sender, arg)
					else
						warn("handler is nil", debug.traceback())
					end
				else
					bHasRemovedHandler = true
				end
			end
			-- clean up chain (do remove the removed ones)
			if bHasRemovedHandler then
				cleanupChain(handlerChain)
			end
		end
	end
	
	local function raiseEventIncludingBase_internal (self, sender, arg, argTypeTable)
		local baseTypeTable = Lplus_typeof(argTypeTable):getBaseTypeTable()
		--recursively invoke base type
		if baseTypeTable ~= Object then
			raiseEventIncludingBase_internal(self, sender, arg, baseTypeTable)
		end
		
		return raiseEvent_internal(self, sender, arg, argTypeTable)
	end
	
	---------------------------------
	--
	-- public methods
	--
	---------------------------------
	
	--[[
		raise an event, all handlers that are registered with the same type of arg will receive the event
	]]
	def.method("dynamic", Object).raiseEvent = function (self, sender, arg)
		checkObject(arg, "raiseEvent", 3, 2)
		
		raiseEvent_internal(self, sender, arg, arg:getTypeTable())
	end
	
	--[[
		raise an event, all handlers that are registered with any type that inherit from argTypeTable will receive the event
		handlers on base type are invoked first
	]]
	def.method("dynamic", Object).raiseEventIncludingBase = function (self, sender, arg)
		checkObject(arg, "raiseEvent", 3, 2)

		raiseEventIncludingBase_internal(self, sender, arg, arg:getTypeTable())
	end
	
	--[[
		add an event handler
			handler will receive two paramters: the sender and the argument
			if one handler is added for mutiple times, it will be invoking for mutiple times when event raised
		param argTypeTable: type table of event argument
		param handler: the added handler function
	]]
	def.method("dynamic", "function").addHandler = function (self, event, handler)
		if handler == nil then
			print("The handler you added is nil", debug.traceback())  
			return
		end

		local argTypeTable = nil
		if type(event) == "string" then
			argTypeTable = require("Events."..event)
		elseif type(event) == "table" then
			argTypeTable = event
		end

		checkTypeTable(argTypeTable, "addHandler", 2, 2)
		checkSimpleType(handler, "addHandler", 3, "function", 2)
		
		local handlerChain = self:requireHandlerChain(argTypeTable)

		local bContain = false
		for i = 1, #handlerChain do
			if handlerChain[i] == handler then
				bContain = true
				break
			end
		end

		if not bContain then
			addToChain(handlerChain, handler)
		end
	end
	
	--[[
		add an event handler with cleaner. when the cleaner collected by gc, the added handler will be automaticly removed
			handler will receive two paramters: the sender and the argument
			if one handler is added for mutiple times, it will be invoking for mutiple times when event raised
		param argTypeTable: type table of event argument
		param handler: the added handler function
		param cleaner: the cleaner used to removed handler
	]]
	def.method("table", "function", GcCallbacks).addHandlerWithCleaner = function (self, argTypeTable, handler, cleaner)
		self:addHandler(argTypeTable, handler)
		cleaner:add(function ()
			self:removeHandler(argTypeTable, handler)
		end)
	end
	
	--[[
		remove an event handler
			if one handler is added for mutiple times, it should be removed for the same times
		param argTypeTable: type table of event argument
		param handler: the added handler function
	]]
	def.method("dynamic", "function").removeHandler = function (self, event, handler)
		if handler == nil then 
			print("The handler you removed is nil", debug.traceback()) 
			return
		end

		local argTypeTable = nil
		if type(event) == "string" then
			argTypeTable = require("Events."..event)
		elseif type(event) == "table" then
			argTypeTable = event
		end
		checkTypeTable(argTypeTable, "removeHandler", 2, 2)
		checkSimpleType(handler, "removeHandler", 3, "function", 2)

		local handlerChain = self.m_handlerChainMap[argTypeTable]
		if handlerChain then
			removeFromChain(handlerChain, handler)
		end
	end
	
	--[[
		clear handlers by argument type
	]]
	def.method("table").clear = function (self, argTypeTable)
		self.m_handlerChainMap[argTypeTable] = nil
	end
	
	--[[
		clear all handlers
	]]
	def.method().clearAll = function (self)
		clearTable(self.m_handlerChainMap)
	end
	
	---------------------------------
	--
	-- END of public
	--
	---------------------------------
	
	def.method("table", "=>" , "table").requireHandlerChain = function (self, argTypeTable)
		local handlerChain = self.m_handlerChainMap[argTypeTable]
		if handlerChain == nil then
			handlerChain = {}
			self.m_handlerChainMap[argTypeTable] = handlerChain
		end
		return handlerChain
	end
	
	def.method().printStats = function (self)
		local total = 0
		for k,v in pairs(self.m_handlerChainMap) do
			if v ~= nil then

				local count = 0
				for i=1,#v do
					if v[i] ~= REMOVED_HANDLER then count = count + 1 end
				end

				total = total + count

				if count > 0 then
					warn("handler chain" ,k ,count)
				end
			end
		end
		warn("Handlers total: ", total)
	end

	def.method("=>", "number").getHandlerTotalCount = function (self)
		local total = 0
		for k,v in pairs(self.m_handlerChainMap) do
			if v ~= nil then

				local count = 0
				for i=1,#v do
					if v[i] ~= REMOVED_HANDLER then count = count + 1 end
				end

				total = total + count
			end
		end
		return total
	end
end
AnonymousEventManager.Commit()

return
{
	AnonymousEventManager = AnonymousEventManager
}
