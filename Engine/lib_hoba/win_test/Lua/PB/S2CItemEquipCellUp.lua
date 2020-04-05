--
-- 装备格子
--

local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CItemEquipCellUp(sender,protocol)
--warn("=============OnS2CItemEquipCellUp=============")
	if protocol.result ~= 0 or protocol.Data == nil then return end

	local EEquipCellUpType = require "PB.data".EEquipCellUpType
	local RoleId = protocol.RoleId
	local player = game._CurWorld:FindObject( RoleId )
	if player == nil then return end

	local cellUpType = protocol.UpTpye
	--更新数据
	player:UpdateEquipCellInfo(protocol.Data)

	--更新UI
	if player:IsHostPlayer() then
		local CPanelUIEquip = require "GUI.CPanelUIEquip"
		if CPanelUIEquip.Instance():IsShow() then
			CPanelUIEquip.Instance():UpdatePanel()
		end
	end
end
PBHelper.AddHandler("S2CItemEquipCellUp", OnS2CItemEquipCellUp)