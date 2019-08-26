local file_name = _G.res_base_path .. "/Data/test/xml_test.xml"

doc = TiXmlDocument()

--加载
if not doc:LoadFile(file_name, 1) then
	print("tinyxml load failed!")
else
	print("tinyxml load success!")
end
