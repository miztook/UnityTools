--
-- S2Dress
--

local PBHelper = require "Network.PBHelper"
local CDressMan = require "Dress.CDressMan"

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

--角色时装数据回应
local function OnS2CDressDataSync(sender,protocol)
--warn("=============OnS2CDressDataSync=============")
	local dressMan = CDressMan.Instance()
	dressMan:InitDressInfo(protocol.DressList)
end
PBHelper.AddHandler("S2CDressDataSync", OnS2CDressDataSync)

--时装穿脱
local function OnS2CDressWear(sender,protocol)
--warn("=============OnS2CDressWear=============")
	local EServerMessageId = require "PB.data".ServerMessageId
	if EServerMessageId.Success ~= protocol.ErrorCode then
		SendFlashMsg("OnS2CDressWear ErrorCode = ", protocol.ErrorCode)
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
			dressMan:OnHostPlayerPutOnMsg( protocol.InsId )
		elseif EWearType.TakeOff == protocol.WearType then
			--脱
			dressMan:OnHostPlayerTakeOffMsg( protocol.InsId )
		end
	else
		--warn("--视野内其他玩家")
		if EWearType.PutOn == protocol.WearType then
			--warn("穿")
			--构建DB data
			local tempDBInfo = {}
			tempDBInfo.Tid = protocol.Tid
			tempDBInfo.InsId = protocol.InsId
			tempDBInfo.DyeColors = protocol.DyeColors
			tempDBInfo.Embroidery = protocol.Embroidery

			dressMan:OnElsePlayerPutOnMsg(player, tempDBInfo)
		elseif EWearType.TakeOff == protocol.WearType then
			--warn("脱")
			dressMan:OnElsePlayerTakeOffMsg(player, protocol.InsId)
		end
	end
end
PBHelper.AddHandler("S2CDressWear", OnS2CDressWear)

--时装染色刺绣
local function OnS2CDressDyeAndEmbroidery(sender,protocol)
--warn("=============OnS2CDressDyeAndEmbroidery=============")
	local EServerMessageId = require "PB.data".ServerMessageId
	if EServerMessageId.Success ~= protocol.ErrorCode then
		SendFlashMsg("OnS2CDressDyeAndEmbroidery ErrorCode = ", protocol.ErrorCode)
		return
	end

	local info = {}
	local EDEType = require "PB.net".eDEType	--结构类型
	if EDEType.Dye == protocol.DeType then
		--染色
		info.ID = protocol.InsId
		info.ColorId = protocol.DeId
		info.Part = protocol.Part + 1
	elseif EDEType.Embroidery == protocol.DeType then
		--刺绣
		info.ID = protocol.InsId
		info.EmbroideryId = protocol.DeId
	end

	CDressMan.Instance():ProcessDressInfo(info, EDEType.Dye == protocol.DeType)
end
PBHelper.AddHandler("S2CDressDyeAndEmbroidery", OnS2CDressDyeAndEmbroidery)

--时装列表更新
local function OnS2CDressUpdateInfo(sender,protocol)
--warn("=============OnS2CDressUpdateInfo=============")
	local EUpdateType = require "PB.net".eUpdateType	--时装更新类型
	if EUpdateType.Add == protocol.UpdateType then
		CDressMan.Instance():UpdateDressInfo(protocol.Dress, false)
	elseif EUpdateType.Remove == protocol.UpdateType then
		CDressMan.Instance():UpdateDressInfo(protocol.Dress, true)
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