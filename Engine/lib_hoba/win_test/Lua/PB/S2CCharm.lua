--
-- S2CCharm
--

local PBHelper = require "Network.PBHelper"
local RoleCharmField = require "PB.net".RoleCharmField
local CHARM_RES_CODE = require "PB.net".CHARM_RES_CODE

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

local function UpdatePanel()

end

--上线同步列表 神符列表
local function OnS2CCharmList(sender,protocol)
--warn("=============OnS2CCharmList=============")
	game._HostPlayer._CharmMan:InitCharmField( protocol.Fields )
end
PBHelper.AddHandler("S2CCharmList", OnS2CCharmList)

--更新神符卡槽信息
local function OnS2CUpdateCharmField(sender,protocol)
--warn("=============OnS2CUpdateCharmField=============")
	local errorCode = protocol.ResCode
	
	if errorCode == CHARM_RES_CODE.CHARM_CODE_OK then
		--SendFlashMsg( StringTable.Get( 19300 + errorCode ), false)
		game._HostPlayer._CharmMan:UpdateCharmField(protocol.Field, protocol.OptCode)
	else
		SendFlashMsg( StringTable.Get( 19300 + errorCode ), false)
	end
end
PBHelper.AddHandler("S2CUpdateCharmField", OnS2CUpdateCharmField)