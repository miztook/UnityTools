--------------------------------------------
-----------冒险指南数据处理
------- 2018/3/21    lidaming
--------------------------------------------


local Lplus = require "Lplus"
local AdventureGuideMan = Lplus.Class("AdventureGuideMan")
local def = AdventureGuideMan.define
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyActivityEvent = require "Events.NotifyActivityEvent"

def.field("table")._Table_AdventureGuideData = nil
def.field("table")._Table_OpenTimeByPlayId = nil


def.static("=>", AdventureGuideMan).new = function()
    local obj = AdventureGuideMan()
	return obj
end

local function sort_func(value1,value2)
    return value1.openLevel > value2.openLevel
end

--缓存所有冒险指南数据
def.method().LoadAllAdventureGuideData = function(self)
	if self._Table_AdventureGuideData ~= nil then return end

    self._Table_AdventureGuideData = {}
    local cfgPath = _G.ConfigsDir.."AdventureGuideBasicInfo.lua"
    local allInfo = _G.ReadConfigTable(cfgPath)
	if allInfo == nil then return end
	for _,v in pairs(allInfo) do
		if v ~= nil then
			self._Table_AdventureGuideData[#self._Table_AdventureGuideData + 1] =
			{
				_Data = v,				--模板数据
				_IsOpen = true,			--是否开启(根据模版数据)
				_IsOpenByLevel = true, 	--是否根据等级开启
				_IsOpenByTime = true, 	--是否根据时间开启
			}

			if string.len(v.DateDisplayText) > 0 and string.len(v.PlayID) then
				local strPlayIds = string.split(v.PlayID, "*")
				if strPlayIds ~= nil then
					for i=1, #strPlayIds do
						local keyStr = strPlayIds[i]
						if self._Table_OpenTimeByPlayId == nil then
							self._Table_OpenTimeByPlayId = {}
						end
						self._Table_OpenTimeByPlayId[keyStr] = v.DateDisplayText
					end
				end
			end				
		else
			warn("冒险指南数据错误ID："..v)
		end
	end

	_G.Unrequire(cfgPath)
end

def.method().ClearAllAdventureGuideData = function(self)
    self._Table_AdventureGuideData = nil
    self._Table_OpenTimeByPlayId = nil
end

--获取开启时间
def.method('number', '=>', 'string').GetOpenTimeByPlayId = function(self, playId)
	return self._Table_OpenTimeByPlayId[tostring(playId)] or StringTable.Get(22028)
end

-- 发送活动事件
def.method("dynamic").SendActivityEvent = function(self, data)
	local event = NotifyActivityEvent()
	CGame.EventManager:raiseEvent(data, event)
end

--------------------------S2C-----------------------------

--上线 or 更新冒险指南数据
def.method("table").UpdateAdventureGuideState = function(self, data)
	if data == nil then return end
	for _,v in pairs(self._Table_AdventureGuideData) do
		for _,k in pairs(data.adventrueGuideDatas) do
			if v._Data.Id == k.TId then	
				v._IsOpenByTime = k.isActivity
			end
		end
	end
end
------------------C2S----------------------------

----------------------------Client--------------------------------
--获取所有冒险指南
def.method("=>","table").GetAllAdventureGuides = function(self)
	local table_AdventureGuide = {}
	for i = 1, #self._Table_AdventureGuideData do
		local level = tonumber(self._Table_AdventureGuideData[i]._Data.OpenLevel)
		if #self._Table_AdventureGuideData[i]._Data.Play ~= 0 then
			table.sort(self._Table_AdventureGuideData[i]._Data.Play , sort_func)
			for _,k in ipairs(self._Table_AdventureGuideData[i]._Data.Play) do 
				if self._Table_AdventureGuideData[i]._Data.IndexRules == 0 then -- 0、最低难度  1、等级索引  
					if k.difficultyMode == 0 then
						level = k.openLevel
					end
				elseif self._Table_AdventureGuideData[i]._Data.IndexRules == 1 then
					if game._HostPlayer._InfoData._Level > k.openLevel then                                    
						level = k.openLevel
					end
				end
			end 				
		end
		-- level < 0 活动未开启， level > HostPlayer 等级不足， _IsOpen、_IsOpenByLevel 同时为true 活动开启。
		if level < 0 then
			self._Table_AdventureGuideData[i]._IsOpen = false
		else
			self._Table_AdventureGuideData[i]._IsOpen = true
			if level > game._HostPlayer._InfoData._Level then
				self._Table_AdventureGuideData[i]._IsOpenByLevel = false
			else				
				self._Table_AdventureGuideData[i]._IsOpenByLevel = true
			end
		end
		table_AdventureGuide[#table_AdventureGuide + 1 ] = self._Table_AdventureGuideData[i]
	end
	return table_AdventureGuide
end

--通过ID获取某一冒险指南数据
def.method("number","=>","table").GetAdventureGuideByID = function(self, nID)
	for _,v in pairs(self._Table_AdventureGuideData) do
		if v._Data.Id == nID then
            return v 
        end
	end
	return nil
end

-- 根据页签类型和排序索引，获取到对应数据。
def.method("number","number","=>", "table").GetAdventureGuide = function(self, type, sortIndex)
    for _,k in pairs(self._Table_AdventureGuideData) do 
        if k._Data.TabType == type then
            if k._Data.SortIndex == sortIndex then 
                return k
            end
        end
    end
	return nil
end


AdventureGuideMan.Commit()
return AdventureGuideMan