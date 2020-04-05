local PBHelper = require "Network.PBHelper"

--上限发送的成就列表
local function OnS2CDesignationInfo(sender, msg)
	game._DesignationMan: SetCurDesignationID(msg.RoleId, msg.Info.CurrentID)

	if msg.Info.Infos == nil or #msg.Info.Infos == 0 then return end
	for _,v in ipairs(msg.Info.Infos) do		
		game._DesignationMan:ChangeDesignationLockState(v) 
	end
end
PBHelper.AddHandler("S2CDesignationInfo", OnS2CDesignationInfo)

--称号获得
local function OnS2CDesignationInc(sender, msg)
	game._DesignationMan: ChangeDesignationLockState(msg.Tid)
end
PBHelper.AddHandler("S2CDesignationInc", OnS2CDesignationInc)

--装备称号
local function OnS2CDesignationPutOn(sender, msg)
	if msg.errorCode == 0 then
		game._DesignationMan: ChangeDesignationID(msg.RoleId,msg.Tid)
	end
end
PBHelper.AddHandler("S2CDesignationPutOn", OnS2CDesignationPutOn)

--卸载称号
local function OnS2CDesignationTakeOff(sender, msg)
	if msg.errorCode == 0 then
		game._DesignationMan: ChangeDesignationID(msg.RoleId,0)
	end
end
PBHelper.AddHandler("S2CDesignationTakeOff", OnS2CDesignationTakeOff)