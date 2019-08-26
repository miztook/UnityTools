--
-- S2CMapLineGetInfo   获取到分线信息。  lidaming 2018/07/16
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

local function OnS2CMapLineGetInfo( sender,msg )
	-- warn("------S2CMapLineGetInfo----->>>", msg.MapLine, #msg.Lines)
	game:SetMapLineInfo(msg.MapLine, msg.Lines)
	local CPanelUIArrayLine = require "GUI.CPanelUIArrayLine"
	if not CPanelUIArrayLine.Instance():IsShow() then
		-- CPanelUIArrayLine.Instance():UpdateArrayLineList()
		game._GUIMan:Open("CPanelUIArrayLine", nil)
	end
end
PBHelper.AddHandler("S2CMapLineGetInfo", OnS2CMapLineGetInfo)