local Lplus = require "Lplus"
local malut = require "Utility.malut"

local UserData = Lplus.Class("UserData")
local def = UserData.define

def.field("table")._DataTable = function() return {} end

local theData = nil
def.static("=>",UserData).Instance = function ()
	if theData == nil then
		theData = UserData()
	end

	return theData
end

def.method().Init = function(self)
	if #self._DataTable == 0 then
		local ret, msg, result = pcall(dofile, "UserData/usercfg.lua")
		if result ~= nil then
			self._DataTable = result
		end
	end
end

def.method().SaveDataToFile = function(self)
	local path = document_path .. "/UserData/usercfg.lua"
	local bSucc, err = malut.toCodeToFile(self._DataTable, path)
	if not bSucc then
		error(err)
	end
end

def.method("string", "string", "dynamic").SetCfg = function(self, catalog, key, value)
	local catalogData = self._DataTable[catalog]
	if not catalogData then
		catalogData = {}
		self._DataTable[catalog] = catalogData
	end
	
	catalogData[key] = value
end

def.method("string", "string", "=>", "dynamic").GetCfg = function(self, catalog, key)
	local catalogData = self._DataTable[catalog]
	if not catalogData then
		return nil
	end
	return catalogData[key]
end
def.method("string", "string").RemoveCfg = function(self, catalog, key)
	local catalogData = self._DataTable[catalog]
	if not catalogData then
		return
	end
	catalogData[key] = nil
end

def.method("string", "=>", "dynamic").GetField = function(self, field_name)
	return self._DataTable[field_name]
end

def.method("string", "dynamic").SetField = function(self, field_name, value)
	local filed = self._DataTable[field_name]
	--if not filed then
	self._DataTable[field_name] = value
	--end
end

-- def.method("string", "string", "=>", "dynamic").GetFieldValue = function(self, field_name, key)
-- end

-- def.method("string", "string", "dynamic").SetFieldValue = function(self, field_name, value)
-- end

UserData.Commit()
return UserData