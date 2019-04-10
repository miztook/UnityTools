--
-- 装备格子
--

local PBHelper = require "Network.PBHelper"
local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")

local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end
local RaiseEvent = function(protocol)
	local EquipDevEvent = require "Events.EquipDevEvent"
    local event = EquipDevEvent()
    event._Msg = protocol

    CGame.EventManager:raiseEvent(nil, event)
end

local DoLogic = function(protocol, msg)
	if protocol.result == 0 then--装备养成 成功
		SendFlashMsg(msg..StringTable.Get(10914))
	else--装备养成 失败
		SendFlashMsg(msg..StringTable.Get(10915))
	end
end

--协议名称
local function OnS2CItemEquipCellUp(sender,protocol)
--warn("=============OnS2CItemEquipCellUp=============")
	local cellUpType = protocol.UpTpye
	local EEquipCellUpType = require "PB.data".EEquipCellUpType

	if protocol.result ~= 0 or protocol.Data == nil then
		if cellUpType == EEquipCellUpType.Inforce then
			DoLogic(protocol, StringTable.Get(10905))
		else
			DoLogic(protocol, StringTable.Get(10906))
		end
		
		return
	end

	local RoleId = protocol.RoleId
	local player = game._CurWorld:FindObject( RoleId )
	if player == nil then return end

	--更新数据
	player:UpdateEquipCellInfo(protocol.Data)

	--更新UI
	if player:IsHostPlayer() then
		if cellUpType == EEquipCellUpType.Inforce then
			DoLogic(protocol, StringTable.Get(10905))
		else
			DoLogic(protocol, StringTable.Get(10906))
		end
		RaiseEvent(protocol)
		
		local CPanelUIEquip = require "GUI.CPanelUIEquip"
		if CPanelUIEquip.Instance():IsShow() then
			CPanelUIEquip.Instance():UpdatePanel()
		end
	end
end
PBHelper.AddHandler("S2CItemEquipCellUp", OnS2CItemEquipCellUp)