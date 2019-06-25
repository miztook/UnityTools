--
-- S2CDungeonErrorCode
--

local PBHelper = require "Network.PBHelper"

local function OnS2CDungeonErrorCode(sender, protocol)
-- warn("OnS2CDungeonErrorCode...........")
	local CElementData = require "Data.CElementData"
	local EMatchTeamErrorCode = require "PB.data".EMatchTeamErrorCode
	local err = protocol.error
	local msg = ""
	local dungeonTemplate = CElementData.GetInstanceTemplate(protocol.dungeonTId)
	local dungeonName = dungeonTemplate.TextDisplayName

	if err == EMatchTeamErrorCode.EMatchTeamMemLowLevel then
		msg = string.format(StringTable.Get(22086), dungeonName)
    elseif err == EMatchTeamErrorCode.EMatchTeamMemDeath then
        msg = string.format(StringTable.Get(22087), dungeonName)
    elseif err == EMatchTeamErrorCode.EMatchTeamMemInInstance then
        msg = string.format(StringTable.Get(22088), dungeonName)
    elseif err == EMatchTeamErrorCode.EMatchInMassacre then
        msg = string.format(StringTable.Get(22089), dungeonName)
    elseif err == EMatchTeamErrorCode.EMatchUnLock then
        msg = string.format(StringTable.Get(22090), dungeonName)
    elseif err == EMatchTeamErrorCode.EMatchEnterNumberLimit then
        msg = string.format(StringTable.Get(22091), dungeonName)
    end

    game._GUIMan:ShowTipText(msg, false)
end

PBHelper.AddHandler("S2CDungeonErrorCode", OnS2CDungeonErrorCode)