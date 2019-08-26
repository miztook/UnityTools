--
-- S2CRandomName
-- 随机名字返回是否重名
--

local PBHelper = require "Network.PBHelper"
local CPanelCreateRole = require "GUI.CPanelCreateRole"

local function OnS2CRandomName(sender, msg)
	--创角色UI没有开启，不错处理
	if not CPanelCreateRole.Instance():IsShow() then return end
	
	if msg.success then
		CPanelCreateRole.Instance():SetRandomName()
	else
		CPanelCreateRole.Instance():GenerateRandomName()
	end
end
PBHelper.AddHandler("S2CRandomName", OnS2CRandomName)