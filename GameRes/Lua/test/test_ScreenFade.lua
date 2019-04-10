

local function test()
	local from = 0
	local to = 0.5
	StartScreenFade(from, to, 1, function()
			StartScreenFade(to, from, 1, nil)
		end)
end
	
test()