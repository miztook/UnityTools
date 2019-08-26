local statistics = {}

local entitys = {}
entitys.NPC = {}
entitys.Player = {}
entitys.Monster = {}

statistics.Register = function(t, id)
	if entitys[t] == nil then
		warn("Error Entity Type")
		return
	end

	if entitys[t][id] ~= nil then
		warn("Same Entity Id", t, id)
		return
	end

	entitys[t][id] = 1

	--warn(t .. " Enter Sight " .. id)
end

statistics.Unregister = function(id)
	if entitys.NPC[id] ~= nil then
		entitys.NPC[id] = nil
		--warn("NPC Leave Sight " .. id)
	elseif entitys.Player[id] ~= nil then
		entitys.Player[id] = nil
		--warn("Player Leave Sight " .. id)
	elseif entitys.Monster[id] ~= nil then
		entitys.Monster[id] = nil
		--warn("Monster Leave Sight " .. id)
	end
end

statistics.Clear = function()
	entitys.NPC = {}
	entitys.Player = {}
	entitys.Monster = {}
end

statistics.FormatInfo = function(t)
	if entitys[t] == nil then
		warn("Error Entity Type")
		return
	end

	local info = "------Statistics Info Begin [" .. t .. "]--------\n"

	for k,v in pairs(entitys[t]) do
		info = info .. tostring(k) .. "\n"
	end

	info = info .. "------Statistics Info End --------\n"

	return info
end

return statistics