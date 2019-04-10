--
-- S2Dress
--

local PBHelper = require "Network.PBHelper"
local CDressMan = require "Dress.CDressMan"
local ServerMessageBase = require "PB.data".ServerMessageBase

--角色时装数据回应
local function OnS2CDressDataSync(sender,protocol)
--warn("=============OnS2CDressDataSync=============")
	local dressMan = CDressMan.Instance()
	dressMan:InitDressInfo(protocol.DressList)
end
PBHelper.AddHandler("S2CDressDataSync", OnS2CDressDataSync)

--时装穿脱
local function OnS2CDressWear(sender,protocol)
	-- warn("=============OnS2CDressWear=============")
	
	if ServerMessageBase.Success ~= protocol.ErrorCode then
		warn("OnS2CDressWear ErrorCode = " .. protocol.ErrorCode)
		return
	end

	local EWearType = require "PB.net".eWearType	--时装穿脱类型
	local hp = game._HostPlayer
	local dressMan = CDressMan.Instance()

	local player = game._CurWorld:FindObject( protocol.RoleId )
	if player == nil then return end
	if hp._ID == protocol.RoleId then
		--warn("--主角自己")
		if EWearType.PutOn == protocol.WearType then
			--穿
			dressMan:OnHostPlayerPutOnMsg( protocol.Dress )
		elseif EWearType.TakeOff == protocol.WearType then
			--脱
			dressMan:OnHostPlayerTakeOffMsg( protocol.Dress.InsId )
		end
	else
		--warn("--视野内其他玩家")
		if EWearType.PutOn == protocol.WearType then
			--warn("穿")
			dressMan:OnElsePlayerPutOnMsg(player, protocol.Dress)
		elseif EWearType.TakeOff == protocol.WearType then
			--warn("脱")
			dressMan:OnElsePlayerTakeOffMsg(player, protocol.Dress.InsId)
		end
	end
end
PBHelper.AddHandler("S2CDressWear", OnS2CDressWear)

--时装染色
local function OnS2CDressDye(sender,protocol)
--warn("=============OnS2CDressDye=============")
	if ServerMessageBase.Success ~= protocol.ErrorCode then
		warn("OnS2CDressDye ErrorCode = " .. protocol.ErrorCode)
		return
	end

	local player = game._CurWorld:FindObject( protocol.RoleId )
	if player == nil then
		warn("OnS2CDressDye fail, can find player with instance id:" .. protocol.RoleId)
		return
	end

	local dressMan = CDressMan.Instance()
	if player:IsHostPlayer() then
		dressMan:OnHostPlayerDressTint(protocol)
	else
		dressMan:OnElsePlayerDressTint(player, protocol)
	end
end
PBHelper.AddHandler("S2CDressDye", OnS2CDressDye)

--时装列表更新
local function OnS2CDressUpdateInfo(sender,protocol)
	-- warn("=============OnS2CDressUpdateInfo=============", protocol.UpdateType)
	for _, dressInfo in ipairs(protocol.DressInfos) do
		CDressMan.Instance():UpdateDressInfo(dressInfo, protocol.UpdateType)
	end
end
PBHelper.AddHandler("S2CDressUpdateInfo", OnS2CDressUpdateInfo)

--协议名称
local function OnS2CDressFirstShow(sender,protocol)
--warn("=============OnS2CDressFirstShow=============")
	local player = game._CurWorld:FindObject(protocol.RoleId)
	if player == nil then return end

	player:SetDressEnable(protocol.isFirst)
end
PBHelper.AddHandler("S2CDressFirstShow", OnS2CDressFirstShow)