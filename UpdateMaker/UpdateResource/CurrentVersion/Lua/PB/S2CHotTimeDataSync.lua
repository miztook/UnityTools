--
-- S2CHotTimeDataSync    2018/09/13   lidaming
--

local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPanelUIHotTime = require "GUI.CPanelUIHotTime"

local function OnS2CHotTimeDataSync(sender, msg)
	if msg.RoleId == game._HostPlayer._ID and CPanelUIHotTime.Instance():IsShow() then
		-- game._GUIMan:Open("CPanelUIHotTime",msg.HTData)
		CPanelUIHotTime.Instance():RafreshHotTime(msg.HTData)
	end

	if CPanelRoleInfo.Instance():IsShow() then
		game._GUIMan:Close("CPanelRoleInfo")
		game._GUIMan:Open("CPanelUIHotTime",nil)
	end
end

PBHelper.AddHandler("S2CHotTimeDataSync", OnS2CHotTimeDataSync)