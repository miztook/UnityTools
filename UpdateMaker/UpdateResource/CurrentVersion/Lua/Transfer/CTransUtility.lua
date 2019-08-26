local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local CTransUtility = Lplus.Class("CTransUtility")
local def = CTransUtility.define

-- 根据传送门ID找到地图ID
def.static("number", "=>", "number").GetTransToPortalMapID = function(nPortalID)
    local v = CElementData.GetTemplate("Trans", nPortalID)
	if v ~= nil then

		return v.MapId
	end

	return game._CurWorld._WorldInfo.SceneTid
end


--通过地图ID获取传送门ID
def.static("number", "=>", "number").GetPortalIDByMapID = function(nMapID)
	local allTransData = CElementData.GetAllTid("Trans")
	for _,v in pairs(allTransData) do
		local transData = CElementData.GetTemplate("Trans", v)    
		if transData ~= nil and transData.MapId ~= nil then
			if transData.MapId == nMapID then
				return transData.Id
			end
		end
	end

	return -1
end

CTransUtility.Commit()
return CTransUtility