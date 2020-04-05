--
-- S2CHorse
--

local PBHelper = require "Network.PBHelper"

local function SendFlashMsg(msg, isUp)
	game._GUIMan:ShowTipText(msg, isUp)
end

--刷新坐骑按钮显隐
local function UpdateHorseBtn()
	local CPanelRocker = require "GUI.CPanelRocker"
	if CPanelRocker and CPanelRocker.Instance():IsShow() then
		CPanelRocker.Instance():UpdateHorseBtn()
	end
end

local function UpdateBoard()
	local CPanelHorse = require "GUI.CPanelHorse"
	if CPanelHorse and CPanelHorse.Instance():IsShow() then
		CPanelHorse.Instance():UpdateBoard()
	end
end

--查看坐骑列表
local function OnS2CHorseViewList(sender, msg)
	game._HostPlayer:InitHorseList(msg.Horses)
	UpdateHorseBtn()
end
PBHelper.AddHandler("S2CHorseViewList", OnS2CHorseViewList)

--设置坐骑
local function OnS2CHorseSet(sender, msg)
	local entity = game._CurWorld:FindObject( msg.EntityId )
	if msg.ResCode ~= nil and msg.ResCode ~= 0 and game._HostPlayer._CanNotifyErrorMountHorse then
		--warn("msg.ResCode = ", msg.ResCode+15110)
		SendFlashMsg(StringTable.Get( msg.ResCode + 15110 ), false)
	end

	if entity ~= nil then
		local EHorseOptType = require "PB.net".EHorseOptType
		if msg.OptType == EHorseOptType.HorseOpt_Set then
			entity:SetCurrentHorseId(msg.HorseTID)
			UpdateHorseBtn()
			UpdateBoard()

			SendFlashMsg(StringTable.Get( 15501 ), false)
		elseif msg.OptType == EHorseOptType.HorseOpt_Mount then
			entity:MountOn(true)
		elseif msg.OptType == EHorseOptType.HorseOpt_Unmount then
			entity:MountOn(false)
		end
	end

	game._HostPlayer._CanNotifyErrorMountHorse = false
end
PBHelper.AddHandler("S2CHorseSet", OnS2CHorseSet)

--坐骑通知
local function OnS2CHorseNotify(sender, msg)
	local EHorseNotifyType = require "PB.net".EHorseNotifyType
	local bIsAdd = false

	if msg.NotifyType == EHorseNotifyType.EHorseNotifyType_Add then
		bIsAdd = true
		local CElementData = require "Data.CElementData"
		local horseData = CElementData.GetTemplate("Horse", msg.HorseID)
		
		SendFlashMsg( string.format(StringTable.Get( 15504 ), horseData.Name), true)
	elseif msg.NotifyType == EHorseNotifyType.EHorseNotifyType_Del then
		bIsAdd = false
	end

	game._HostPlayer:UpdateHorseList(bIsAdd, msg.HorseID)
end
PBHelper.AddHandler("S2CHorseNotify", OnS2CHorseNotify)