--
-- S2CHorse
--

local PBHelper = require "Network.PBHelper"
local ServerMessageBase = require "PB.data".ServerMessageBase
local ServerMessageHorse = require "PB.data".ServerMessageHorse

local function ErrorCodeCheck(error_code)
	game._GUIMan:ShowErrorCodeMsg(error_code, nil)
end

--刷新坐骑按钮显隐
local function UpdateHorseBtn()
	local CPanelRocker = require "GUI.CPanelRocker"
	if CPanelRocker and CPanelRocker.Instance():IsShow() then
		CPanelRocker.Instance():UpdateHorseBtnState()
	end
end

local function UpdateRide()
	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if CPanelUIExterior and CPanelUIExterior.Instance():IsShow() then
		CPanelUIExterior.Instance():UpdateRideData()
	end
end

--查看坐骑列表
local function OnS2CHorseViewList(sender, msg)
	if game._HostPlayer ~= nil then
		game._HostPlayer:InitHorseList(msg.Horses)
	end
	UpdateHorseBtn()
end
PBHelper.AddHandler("S2CHorseViewList", OnS2CHorseViewList)

--设置坐骑
local function OnS2CHorseSet(sender, msg)
	-- printLog("ResCode", msg.ResCode)
	-- printLog("notify", game._HostPlayer._CanNotifyErrorMountHorse)
	if msg.ResCode ~= nil and msg.ResCode ~= ServerMessageBase.Success then
		-- 上马或下马失败
		if game._HostPlayer._CanNotifyErrorMountHorse then
			-- 若是主动请求，提示错误码
			ErrorCodeCheck(msg.ResCode)
		end
		game._HostPlayer._CanNotifyErrorMountHorse = false
		return
	end
	local entity = game._CurWorld:FindObject( msg.EntityId )
	
	if entity ~= nil then
		local EHorseOptType = require "PB.net".EHorseOptType
		if msg.OptType == EHorseOptType.HorseOpt_Set then
			entity:SetCurrentHorseId(msg.HorseTID)
			UpdateHorseBtn()
			UpdateRide() -- 新坐骑界面

			if msg.EntityId == game._HostPlayer._ID and msg.HorseTID > 0 then
				game._GUIMan:ShowTipText(StringTable.Get(15501), false)
			end
		elseif msg.OptType == EHorseOptType.HorseOpt_Mount then
			entity:MountOn(true)
		elseif msg.OptType == EHorseOptType.HorseOpt_Unmount then
			entity:MountOn(false)

			if msg.EntityId == game._HostPlayer._ID and msg.UnmountReason ~= nil and msg.UnmountReason ~= 0 then
				-- 下马原因提醒
				ErrorCodeCheck(msg.UnmountReason)
			end
		end
	end
end
PBHelper.AddHandler("S2CHorseSet", OnS2CHorseSet)

--坐骑通知
local function OnS2CHorseNotify(sender, msg)
	local EHorseNotifyType = require "PB.net".EHorseNotifyType
	local bIsAdd = false

	if msg.NotifyType == EHorseNotifyType.EHorseNotifyType_Add then
		bIsAdd = true
	elseif msg.NotifyType == EHorseNotifyType.EHorseNotifyType_Del then
		bIsAdd = false
	end
	-- 更新数据
	game._HostPlayer:UpdateHorseList(bIsAdd, msg.HorseID)

	if bIsAdd then
		-- 弹获取提示
		local CElementData = require "Data.CElementData"
		local horseData = CElementData.GetTemplate("Horse", msg.HorseID)
		game._GUIMan:ShowTipText(string.format(StringTable.Get(15504), horseData.Name), false)

		-- 保存红点显示状态
		local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
		if exteriorMap == nil then
			exteriorMap = {}
		end
		local key = "Ride"
		if exteriorMap[key] == nil then
			exteriorMap[key] = {}
		end
		exteriorMap[key][msg.HorseID] = true
		CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Exterior, exteriorMap)
		if game._CFunctionMan:IsUnlockByFunTid(21) then
			-- 坐骑功能已解锁，更新系统菜单红点
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, true)
		end

		UpdateRide()
	end
end
PBHelper.AddHandler("S2CHorseNotify", OnS2CHorseNotify)