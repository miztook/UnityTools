local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
-- local ERROR_CODE = require "PB.data".ServerMessageId2   -- 刻印   没用的
local EquipProcessingChangeEvent = require "Events.EquipProcessingChangeEvent"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"


local function RaiseEquipProcessingChangeEvent(id,index)
	local event = EquipProcessingChangeEvent()
	event._Type = EnumDef.UIEquipPageState.PageEngrave
    CGame.EventManager:raiseEvent(nil, event)
end

-- --协议名称(推送主角和Player的刻印值)
-- local function OnS2CItemEngraving(sender,protocol)
-- -- warn("=============OnS2CItemEngraving=============")
-- -- warn("protocol.result  == ",protocol.result)
-- 	if protocol.result == 0  then
-- 		local player = game._CurWorld:FindObject(protocol.RoleId)
-- 		if player == nil then return end
-- 		local EngravingValue = 0 
-- 		if protocol.EngravingValues ~= nil then 
-- 			for i,v in ipairs(protocol.EngravingValues) do
-- 				EngravingValue = EngravingValue + v  
-- 			end
-- 		end
-- 		-- warn("EngravingValue ",EngravingValue)
-- 		player:UpdateWeaponEngravingValue(EngravingValue)
-- 		-- 跟新UI特效
-- 		if protocol.RoleId == game._HostPlayer._ID  then 
-- 			CPanelRoleInfo.Instance():UpdateWeaponFx()
-- 		end
-- 	end

-- 	if protocol.RoleId == game._HostPlayer._ID then 
-- 		if protocol.result == 0 then
-- 			local pack = game._HostPlayer._Package._EquipPack
-- 			local itemData = pack:GetItemBySlot( protocol.Index )
-- 			if itemData == nil then return end

-- 			local EngravingStoneTid = protocol.EngravingStoneTid

-- 			itemData:SetEngravingValues(protocol.EngravingValues)

-- 			RaiseEquipProcessingChangeEvent()
-- 		elseif protocol.result == ERROR_CODE.ItemEngravingFaild then
-- 			RaiseEquipProcessingChangeEvent()
-- 		end
-- 	end
-- end
-- PBHelper.AddHandler("S2CItemEngraving", OnS2CItemEngraving)

-- --协议名称
-- local function OnS2CItemEngravingReset(sender,protocol)
-- --warn("=============OnS2CItemEngravingReset=============")
-- 	if protocol.result == 0 then
-- 		local player = game._CurWorld:FindObject(protocol.RoleId)
-- 		if player == nil then return end
-- 		local EngravingValue = 0 
-- 		player:UpdateWeaponEngravingValue(EngravingValue)

-- 		if protocol.RoleId == game._HostPlayer._ID then 
-- 			local pack = game._HostPlayer._Package._EquipPack
-- 			local itemData = pack:GetItemBySlot( protocol.Index )
-- 			if itemData == nil then return end

-- 			itemData:ResetEngravingValues()

-- 			RaiseEquipProcessingChangeEvent()
-- 			if protocol.RoleId == game._HostPlayer._ID  then 
-- 				CPanelRoleInfo.Instance():UpdateWeaponFx()
-- 			end
-- 		end
-- 	end
-- end
-- PBHelper.AddHandler("S2CItemEngravingReset", OnS2CItemEngravingReset)