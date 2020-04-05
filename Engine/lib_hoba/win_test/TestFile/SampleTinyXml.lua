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


doc = TiXmlDocument();

--objinfo(doc);

--加载
if not doc:LoadFile("../../skillProcess.xml", 1) then
	print("load failed!")
else
	--print("load success!")
end

--根节点
local rootElement = doc:RootElement();

if not rootElement then
	print("Get Root failed!")
else
	--print("Get Root success!")
end

--标签
local element = rootElement:FirstChildElement()

--if not element then
	--print("Can not Find item!")
	--objinfo(element)
--else
	--print("Find item!")
	--print(element:Value())
--end

--element = element:NextSiblingElement()

--if not element then
	--print("element find failed!")
--else
	--print("element find success!")
--end

--element = element:FirstChildElement():FirstChildElement()
element = element:NextSiblingElement():FirstChildElement()
--element = element:NextSiblingElement():FirstChildElement():FirstChildElement()

if rootElement:FirstChildElement():Value() == "Action" then
	--print("same")
else
	--print("diff")
end

--print(rootElement:FirstChildElement():Value())
--print(element:Value())

local arrValue = nil

while element do
	ele_Name = element:Value()

	print("[element = "..ele_Name.."]")
	

	if ele_Name == 'index' then
		attr = element:FirstAttribute()

		while attr do
			attr_Name = attr:Name()
			attr_Value = attr:Value()
			print(attr_Name.." = "..attr_Value)

			attr = attr:Next()
		end

		print("--------------------------------")
	end

	if ele_Name == 'Event' then
		attr = element:FirstAttribute()

		while attr do
			attr_Name = attr:Name()
			attr_Value = attr:Value()
			print(attr_Name.." = "..attr_Value)

			--Get data
			if attr_Name == "frame" then
				arrValue = attr_Value
				print("jjjjjjjjjjjjjjjjj"..arrValue)
			end

			attr = attr:Next()
		end

		print("--------------------------------")
	end

	element = element:NextSiblingElement()

end
