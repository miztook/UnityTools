--
-- S2CCharm
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local CCharmMan = require "Charm.CCharmMan"
local ServerMessageCharm = require "PB.data".ServerMessageCharm

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

--上线同步列表 神符列表
local function OnS2CCharmList(sender,protocol)
--warn("=============OnS2CCharmList=============")
	CCharmMan.Instance():InitCharmField( protocol.Fields )
    CCharmMan.Instance():InitCharmPageField()
    CCharmMan.Instance():InitCharmPageCombatInfo(protocol.FightScores)
end
PBHelper.AddHandler("S2CCharmList", OnS2CCharmList)

--更新神符卡槽信息
local function OnS2CUpdateCharmField(sender,protocol)
--warn("=============OnS2CUpdateCharmField=============")
	local errorCode = protocol.ResCode
	if errorCode == 0 then
		CCharmMan.Instance():UpdateCharmField(protocol.Field, protocol.OptCode, protocol.TakeOffCharmTid)
	else		
		game._GUIMan:ShowErrorTipText(errorCode)
	end
end
PBHelper.AddHandler("S2CUpdateCharmField", OnS2CUpdateCharmField)

local function OnS2CCharmCompose(sender, protocol)
    local errorCode = protocol.ResCode
    if errorCode == ServerMessageCharm.CharmComposeFaild or errorCode == 0 then
        CCharmMan.Instance():CharmComposeResult(protocol, errorCode == 0)
    else
		game._GUIMan:ShowErrorTipText(errorCode)
    end
end
PBHelper.AddHandler("S2CCharmCompose", OnS2CCharmCompose)

local function OnS2CCharmFightScore(sender, protocol)
    CCharmMan.Instance():InitCharmPageCombatInfo(protocol.FightScores)
end
PBHelper.AddHandler("S2CCharmFightScore", OnS2CCharmFightScore)

local function OnS2CCharmPutOnBatch(sender, protocol)
    print("protocol ", protocol)
    CCharmMan.Instance():S2CCharmPutOnBatch(protocol.Fields)
end
PBHelper.AddHandler("S2CCharmPutOnBatch", OnS2CCharmPutOnBatch)