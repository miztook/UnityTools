--
-- S2CQuickMatch
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local QuickMatchStateEvent = require "Events.QuickMatchStateEvent"
local CTeamMan = require "Team.CTeamMan"

local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end

local function SendQuickMatchStateEvent()
	local event = QuickMatchStateEvent()
	CGame.EventManager:raiseEvent(nil, event)
end

-- 便捷匹配 开启 & 关闭
local function OnS2CQuickMatchState(sender,protocol)
-- warn("=============OnS2CQuickMatchState=============", protocol.bState)
	if protocol.bState then
		-- warn("S2CQuickMatchState targetId = ", protocol.targetId)
		game._DungeonMan:StartQuickMatch(protocol.targetId)
	else
		game._DungeonMan:StopQuickMatch()
	end

	-- 更新副本匹配 按钮
	SendQuickMatchStateEvent()
end
PBHelper.AddHandler("S2CQuickMatchState", OnS2CQuickMatchState)

-- 便捷匹配 开启界面，同步数据
local function OnS2CQuickMatchSyncData(sender,protocol)
-- warn("=============OnS2CQuickMatchSyncData=============")
	local param = {}
	local dungeonId = CTeamMan.Instance():ExchangeToDungeonId(protocol.targetId)

	param.DungeonId = dungeonId
	param.RoomId = protocol.targetId
	param.LeaderId = protocol.leaderId
	param.Duration = protocol.duration*1000
	param.MemeberList = {}

	-- warn("DungeonId = ", dungeonId)
	-- warn("RoomId = ", param.RoomId)
	-- warn("LeaderId = ", protocol.leaderId)
	-- warn("Duration = ", protocol.duration)

	for i,v in ipairs(protocol.members) do
		local member = {}
		member._ID = v.memberId
		member._Name = v.memberName
		member._Profession = v.professionId
		member._Gender = Profession2Gender[v.professionId]
		table.insert(param.MemeberList, member)
	end

	game._GUIMan:Open("CPanelUIQuickMatchConfirm", param)
end
PBHelper.AddHandler("S2CQuickMatchSyncData", OnS2CQuickMatchSyncData)

-- 便捷匹配 状态界面更新
local function OnS2CQuickMatchUpdate(sender,protocol)
-- warn("=============OnS2CQuickMatchUpdate=============")
	local EQuickMatchUpdate = require "PB.net".S2CQuickMatchUpdate.EQuickMatchUpdate
	local optType = protocol.optType
	
	if EQuickMatchUpdate.update == optType then
		-- warn("OnS2CQuickMatchUpdate---------update")
		local CPanelUIQuickMatchConfirm = require "GUI.CPanelUIQuickMatchConfirm"
		if CPanelUIQuickMatchConfirm.Instance():IsShow() then
			CPanelUIQuickMatchConfirm.Instance():UpdateTeamMemberConfirmed(protocol.memberId)
		end
	elseif EQuickMatchUpdate.success == optType then
		-- warn("OnS2CQuickMatchUpdate---------success")
		game._GUIMan:Close("CPanelUIQuickMatchConfirm")
	elseif EQuickMatchUpdate.cancel == optType then
		-- warn("OnS2CQuickMatchUpdate---------cancel")
		local name = ""
		if protocol.memberId == game._HostPlayer._ID then
			name = StringTable.Get(248)
		else
			name = protocol.memberName
		end
		SendFlashMsg(string.format(StringTable.Get(938), name))

		game._GUIMan:Close("CPanelUIQuickMatchConfirm")
	end
end
PBHelper.AddHandler("S2CQuickMatchUpdate", OnS2CQuickMatchUpdate)