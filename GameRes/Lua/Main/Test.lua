-- 测试专用

-- pvrtc VS truecolor
local panels = {}
local function CreatePanel(prefab)
	local panel = prefab
	local parentgo = GameObject.Find("UIRootCanvas")
	panel:SetParent(parentgo, false)
	panels[#panels + 1] = panel
end

function test1(start)
	if start and #panels == 0 then
		local Panel_TrueColor = "Assets/Outputs/Interfaces/Panel_test01.prefab"
		local Panel_Pvrtc = "Assets/Outputs/Interfaces/Panel_test02.prefab"

		local cb1 = function(res)
				CreatePanel(res)
			end
		GameUtil.AsyncLoad(Panel_TrueColor, cb1, false, "interfaces")

		local cb2 = function(res)
				CreatePanel(res)
			end
		GameUtil.AsyncLoad(Panel_Pvrtc, , false, , "interfaces")
	end

	if not start and #panels > 0 then
		for i,v in ipairs(panels) do
			Object.Destroy(v)
		end
		panels = {}
	end 
end


function test2(p)
	warn("just a sample")
end

return 
{
	test1,
	test2,
}