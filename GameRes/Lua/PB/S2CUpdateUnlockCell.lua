--
-- S2CInventoryInfo
--
local CPageBag = require"GUI.CPageBag"
local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CElementData = require "Data.CElementData"

local function OnUpdateUnlockCell(sender, protocol)

	if protocol.ErrorCode ~= 0 then 
		-- 错误码
		game._GUIMan:ShowErrorTipText(protocol.ErrorCode)
	return end
	game._HostPlayer._Package._NormalPack._EffectSize = protocol.Count
	local CPanelMainChat = require "GUI.CPanelMainChat"
	local pre =  #game._HostPlayer._Package._NormalPack._ItemSet / game._HostPlayer._Package._NormalPack._EffectSize
	CPanelMainChat.Instance():SetBagCapacityLast(pre)
	CPanelRoleInfo.Instance():S2CBagUnlockCell()

	local Lplus = require "Lplus"
	local CGame = Lplus.ForwardDeclare("CGame")
	local NotifyBagCapacityEvent = require "Events.NotifyBagCapacityEvent"
	local event = NotifyBagCapacityEvent()
	event.Value=pre
	CGame.EventManager:raiseEvent(nil, event)

	-- -- else
	-- -- end
	-- do
	-- 	local Lplus = require "Lplus"
	-- 	local CGame = Lplus.ForwardDeclare("CGame")
	-- 	local PackageChangeEvent = require "Events.PackageChangeEvent"
	--     local event = PackageChangeEvent()
	--     -- event.PackageType = protocol.BagType
	--     CGame.EventManager:raiseEvent(nil, event)
	-- end

end

PBHelper.AddHandler("S2CUpdateUnlockCell", OnUpdateUnlockCell)