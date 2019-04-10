local PBHelper = require "Network.PBHelper"
local CTransManage = require "Main.CTransManage"


--上线同步所有已经去过的地图信息
local function OnS2CAllMapData(sender, msg)
	for i,v in ipairs(msg.BeenMapList) do
		CTransManage.Instance():AddMapData(v)
	end 
end
PBHelper.AddHandler("S2CRoleMapData", OnS2CAllMapData)


--改变已经去过的地图的信息
local function OnS2CFreshMapData(sender, msg)
	CTransManage.Instance():AddMapData(msg.MapID)
end
PBHelper.AddHandler("S2CUpdateRoleMapData", OnS2CFreshMapData)