--
-- S2CPet
--

local PBHelper = require "Network.PBHelper"


local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end
local function SendMsgToSysteamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false)
end
local function SendMsgToTeamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, msg, false)
end


local function UpdatePanel()
	local CPanelPet = require "GUI.CPanelPet"
	if CPanelPet ~= nil and CPanelPet.Instance():IsShow() then
		CPanelPet.Instance():Update()
	end
end

--同步
local function OnS2CPetData(sender, protocol)
--warn("同步")

	local list = protocol.PetList
	if #list > 0 then
		game._HostPlayer:InitPetList( list )
	end

	UpdatePanel()
end
PBHelper.AddHandler("S2CPetData", OnS2CPetData)



--休息
local function OnS2CPetRest(sender, protocol)
--warn("休息")

	local tid = protocol.PetTId
	local hp = game._HostPlayer

--warn("休息宠物 TID = ", tid)

	if hp:GetCurrentPetId() == tid then
		hp:SetCurrentPetId(0)
	end

	SendFlashMsg( StringTable.Get(19006) )

	UpdatePanel()
end
PBHelper.AddHandler("S2CPetRest", OnS2CPetRest)



--战斗
local function OnS2CPetFighting(sender, protocol)
--warn("战斗")
	local tid = protocol.PetTId
--warn("战斗宠物 TID = ", tid)

	game._HostPlayer:SetCurrentPetId(tid)

	SendFlashMsg( StringTable.Get(19005) )
	UpdatePanel()
end
PBHelper.AddHandler("S2CPetFighting", OnS2CPetFighting)



--增加
local function OnS2CPetAdd(sender, protocol)
--warn("增加")
	local dataDB = protocol.PetData
	if dataDB ~= nil then
		game._HostPlayer:UpdatePetList(true, dataDB)

		local CElementData = require "Data.CElementData"
		local tid = dataDB.PetId
        local data = CElementData.GetTemplate("Pet", tid)
        if data == nil then return end

		SendFlashMsg( string.format(StringTable.Get( 19107 ), data.Name) )
	end

	UpdatePanel()
end
PBHelper.AddHandler("S2CPetAdd", OnS2CPetAdd)



--放生
local function OnS2CPetFree(sender, protocol)
--warn("放生")
	local data = protocol.PetData
	if data ~= nil then
		game._HostPlayer:UpdatePetList(false, data)
	end

	SendFlashMsg( StringTable.Get(19007) )
	UpdatePanel()
end
PBHelper.AddHandler("S2CPetFree", OnS2CPetFree)


local function OnS2CPetLevelUp(sender, protocol)
--warn("升级")
	local data = {}
	data.PetId = protocol.PetTId
	data.Level = protocol.Level
	data.CurExp = protocol.CurrentExp
	data.MaxExp = protocol.MaxExp
	data.FightScore = protocol.FightScore

	game._HostPlayer:UpdatePetInfo( data )

	local CPanelPet = require "GUI.CPanelPet"
	if CPanelPet ~= nil and CPanelPet.Instance():IsShow() then
		SendFlashMsg( StringTable.Get( 19110 ) )
		CPanelPet.Instance():UpdateExp(m)
		CPanelPet.Instance():Update()
	end
end
PBHelper.AddHandler("S2CPetLevelUp", OnS2CPetLevelUp)


local function OnS2CPetExp(sender, protocol)
--warn("经验变化")
	local CPanelPet = require "GUI.CPanelPet"
	if CPanelPet ~= nil and CPanelPet.Instance():IsShow() then
		local m = {}
		m.Current = protocol.CurrentExp
		CPanelPet.Instance():UpdateExp(m)
	end
end
PBHelper.AddHandler("S2CPetExp", OnS2CPetExp)


--返回值
local function OnS2CPetErrorCode(sender, protocol)
	warn("返回值 :: ", StringTable.Get( 19100 + protocol.ErrorCode) )
end
PBHelper.AddHandler("S2CPetErrorCode", OnS2CPetErrorCode)