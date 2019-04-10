--
-- S2CDebugServerVersion
--

local PBHelper = require "Network.PBHelper"

local function OnS2CDebugServerVersion(sender, protocol)
	local CPanelHuangxinTest = require"GUI.CPanelHuangxinTest"
	CPanelHuangxinTest.Instance():SetServerVersion(protocol.text)
end

PBHelper.AddHandler("S2CDebugServerVersion", OnS2CDebugServerVersion)
