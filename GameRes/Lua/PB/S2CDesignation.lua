local PBHelper = require "Network.PBHelper"

--上限发送的成就列表
local function OnS2CDesignationInfo(sender, msg)
	game. _DesignationMan:LoadAllDesignationData() --上线的时候，有数据就加载称号
	game._DesignationMan: SetCurDesignationID(msg.RoleId, msg.Info.CurrentID)

	if msg.Info.Infos == nil or #msg.Info.Infos == 0 then return end
	for _,v in ipairs(msg.Info.Infos) do		
		--warn("v.TimeLimit------>",v.TimeLimit)
		game._DesignationMan:ChangeDesignationLockState(v.Tid, v.TimeLimit) 
	end
end
PBHelper.AddHandler("S2CDesignationInfo", OnS2CDesignationInfo)

--称号获得
local function OnS2CDesignationInc(sender, msg)
	--warn("msg.TimeLimit----->",msg.TimeLimit)
	game._DesignationMan: ChangeDesignationLockState(msg.Tid, msg.TimeLimit)
	game._DesignationMan: SetRedPointState(msg.Tid, true)
	game._DesignationMan: SetTypeRedPointStateByTId(msg.Tid, true)
	local isShowRed = true
	CRedDotMan.SaveModuleDataToUserData("RoleInfo",isShowRed)

	
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
    local msg = string.format(StringTable.Get(13047), game._DesignationMan: GetColorDesignationNameByTID(msg.Tid))
    if msg ~= nil then
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
    end

end
PBHelper.AddHandler("S2CDesignationInc", OnS2CDesignationInc)

--装备称号
local function OnS2CDesignationPutOn(sender, msg)
	--warn("S2CDesignationPutOn")
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

--称号到期，卸掉
local function OnS2CDesignationRemove(sender, msg)
	game._DesignationMan: RemoveDesignation(msg.RoleId , msg.Tid)
end
PBHelper.AddHandler("S2CDesignationRemove", OnS2CDesignationRemove)