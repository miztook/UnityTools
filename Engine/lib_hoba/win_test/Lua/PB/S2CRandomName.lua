--
-- S2CRandomName
-- 随机名字返回是否重名
--

local PBHelper = require "Network.PBHelper"
local CPanelCreateRole = require "GUI.CPanelCreateRole"

local function OnS2CRandomName(sender, msg)
	if msg.success then
		CPanelCreateRole.Instance():SetRandomName()
	else
		CPanelCreateRole.Instance():GenerateRandomName()
	end
end
PBHelper.AddHandler("S2CRandomName", OnS2CRandomName)