local PBHelper = require "Network.PBHelper"
local CTransManage = require "Main.CTransManage"


--上线同步所有区域信息
local function OnS2CAllMapData(sender, msg)
	for i,v in ipairs(msg.BeenMapList) do
		CTransManage.Instance():OpenMap(v)
	end 
end
PBHelper.AddHandler("S2CRoleMapData", OnS2CAllMapData)


--改变区域信息
local function OnS2CFreshMapData(sender, msg)
	CTransManage.Instance():OpenMap(msg.MapID)
end
PBHelper.AddHandler("S2CUpdateRoleMapData", OnS2CFreshMapData)