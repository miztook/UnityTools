
local file_name = _G.res_base_path .. "/Data/test/cvs_test.csv"

local csv = CCsvWrapper()

if not csv then
	print("CSV Create failed!")
else
	if not csv:LoadCSV(file_name) then
		print("Load csv failed!")
	else
		print( csv:GetValue(1,4) )

--i_fnd = csv:GetInt(19, 2)
--i_fnd = csv:GetFloat(19,2)
--Numbers -40000004 for "not found", GetValue is NULL

		i_fnd = csv:GetValue(19, 2)
		--if  i_fnd == -40000004 then
		if not i_fnd then
			print("Can not find Value")
		else
			print(i_fnd)
		end
	end
end