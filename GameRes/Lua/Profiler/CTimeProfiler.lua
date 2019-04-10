local Lplus = require "Lplus"

local CTimeProfiler = Lplus.Class("CTimeProfiler")
local def = CTimeProfiler.define

local _startTime = -1
local _stopTime = -1
local _isStarted = false

def.static().Dump = function()
	local t = _stopTime - _startTime
	if _isStarted then
		t = os.time() - _startTime
	end
	if t <= 0 then print("nothing to dump") return end
	local stat = profiler.stat()
	print("lua profile stat:", stat)
	if stat ~= nil then
		local filename = _G.res_base_path .. "/" .. "lua_profile.csv"
		local f = io.open(filename,"w")
		local title = string.format("id,call count,stat count,time(millisecond),t%%(stat time:%f)\n",t)
		f:write(title)
		for k,v in ipairs(stat) do
			local id = string.gsub(v[1],","," ")
			local s = string.format("%s,%d,%d,%f,%f\n",id,v[2],v[4],v[3],v[3]/t/10)
			f:write(s)
		end
		f:close()
	end
	warn("-----------> profiler.dump()")
end

def.static().Start = function()
	if _isStarted then
		warn("lua profile has started!!!")
		return
	end
	_startTime = os.time()
	_isStarted = true
	profiler.start()

	warn("-----------> profiler.start()")
end

def.static().Stop = function()
	if not _isStarted  then return end
	_isStarted = false
	_stopTime = os.time()
	profiler.stop()
	warn("-----------> profiler.stop()")
end

CTimeProfiler.Commit()

return CTimeProfiler
