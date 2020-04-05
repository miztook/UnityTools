function objinfo(obj)

	local meta = getmetatable(obj)
	if meta ~= nil then
		metainfo(meta)
	else
		print("no object infomation !!")
	end
end

function metainfo(meta)

	if meta ~= nil then
		local name = meta["__name"]
		if name ~= nil then
			metainfo(meta["__parent"])
			print("<"..name..">")
			for key,value in pairs(meta) do 
				if not string.find(key, "__..") then 
					if type(value) == "function" then
						print("\t[f] "..name..":"..key.."()") 
					elseif type(value) == "userdata" then
						print("\t[v] "..name..":"..key)
					end
				end
			end
		end
	end
end


csv = CCsvWrapper();

if not csv then
	print("CSV Create failed!")
else
	--print("CSV Create success!")
end

if not csv:LoadCSV("../../cvs_test.csv") then
	print("Load csv failed!")
else
	--print("Load csv success!")
end


str_fnd = csv:GetValue(1,4)
print( str_fnd )


i_fnd = csv:GetValue(19, 2)
if  i_fnd == -40000004 then
	print("Can not find Value")
else
	print(i_fnd)
end

f_fnd = csv:GetValue(19,3)

if f_fnd == -40000004 then
	print("Can not find Value")
else
	f_fnd = string.format("%.3f", f_fnd) 
	print(f_fnd)
end


saveSuccess = csv:SaveCSV("../../out777777777777.csv")



