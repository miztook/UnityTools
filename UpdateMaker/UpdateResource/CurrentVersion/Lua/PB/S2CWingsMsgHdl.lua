--
-- S2CWingsMsgHdl 翅膀功能相关处理
--
local PBHelper = require "Network.PBHelper"
local ServerMessageBase = require "PB.data".ServerMessageBase
local ServerMessageWing = require "PB.data".ServerMessageWing
local CWingsMan = require 'Wings.CWingsMan'
local EChatChannel = require "PB.data".ChatChannel
local ChatManager = require "Chat.ChatManager"
local EWingUpdateType = require "PB.net".EWingUpdateType

local function ErrorCodeCheck(error_code)
	-- 职业限制
	if error_code == ServerMessageWing.WingProfessionLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19506), false)
	-- 性别前置
	elseif error_code == ServerMessageWing.WingSexLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19507), false)
	-- 没有发现翅膀	
	elseif error_code == ServerMessageWing.WingNotFindWing then
		game._GUIMan:ShowTipText(StringTable.Get(19508), false)
	-- 没有发现天赋页
	elseif error_code == ServerMessageWing.WingNotFindPage then
		game._GUIMan:ShowTipText(StringTable.Get(19509), false)
	-- 没有发现天赋
	elseif error_code == ServerMessageWing.WingNotFindTalent then
		game._GUIMan:ShowTipText(StringTable.Get(19506), false)
	-- 没有足够的天赋点
	elseif error_code == ServerMessageWing.WingNotEnoughtPoint then
		game._GUIMan:ShowTipText(StringTable.Get(19520), false)
	-- 前置天赋限制
	elseif error_code == ServerMessageWing.WingPreTalentLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19511), false)
	elseif error_code == ServerMessageWing.WingTemplateDataErr then
		game._GUIMan:ShowTipText(StringTable.Get(19512), false)	-- 模板数据错误
	elseif error_code == ServerMessageWing.WingAssistItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19513), false)	-- 翅膀升级辅助道具不足
	elseif error_code == ServerMessageWing.WingLevelUpItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19514), false)	-- 翅膀升级道具不足
	elseif error_code == ServerMessageWing.WingGradeUpItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19515), false)	-- 翅膀进阶道具不足
	elseif error_code == ServerMessageWing.WingLevelUpNeedGrade then
		game._GUIMan:ShowTipText(StringTable.Get(19516), false)	-- 翅膀升级已满需要进阶
	elseif error_code == ServerMessageWing.WingNotEnoughExp then
		game._GUIMan:ShowTipText(StringTable.Get(19517), false)	-- 没有足够经验
	elseif error_code == ServerMessageWing.WingLevelLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19518), false)	-- 翅膀等级限制
	elseif error_code == ServerMessageBase.NotEnoughMoney then
		game._GUIMan:ShowTipText(StringTable.Get(22307), false) -- 货币不足
	else 
		warn("wings errorcode not right and not the suitable condition, wrong code: " .. tostring(error_code))
	end
end

-- @param type 0:添加翅膀 1:装备翅膀 2:翅膀升级 3:翅膀进阶
local function NotifyWingChange(type)
	local CPanelUIExterior = require "GUI.CPanelUIExterior"
	if CPanelUIExterior and CPanelUIExterior.Instance():IsShow() then
		CPanelUIExterior.Instance():UpdateWingList()
	end
	local CPanelUIWing = require "GUI.CPanelUIWing"
	if CPanelUIWing and CPanelUIWing.Instance():IsShow() then
		CPanelUIWing.Instance():UpdateWingList(type)
	end
end

-- @param type 0:整体数据推送 1:获得天赋点 2:选中天赋页 3:天赋点分配 4:天赋页洗点
local function NotifyWingTalentChange(type, param)
	local CPanelUISkill = require "GUI.CPanelUISkill"
	if CPanelUISkill and CPanelUISkill.Instance():IsShow() then
		CPanelUISkill.Instance():UpdateSoulShow(type, param)
	end
end

-- 翅膀列表
-- required int32					ResCode
-- repeated WingInfo				WingList
-- TotalPoint
local function OnS2CWingViewList(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then
		CWingsMan.Instance():ResolveWingsData(msg.WingList)
		CWingsMan.Instance():SetWingPointsData(msg.TotalPoint)		
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingViewList", OnS2CWingViewList)

-- 更新翅膀数据
local function OnS2CWingUpdateInfo(sender, msg)
	if msg.ResCode == ServerMessageBase.Success then
		if msg.UpdateType == EWingUpdateType.EWingUpdateType_WingInfo then
			-- 添加翅膀
			CWingsMan.Instance():AddWingData(msg.WingInfo)
			NotifyWingChange(0)
		elseif msg.UpdateType == EWingUpdateType.EWingUpdateType_AddPoint then
			-- 更新天赋点数
			CWingsMan.Instance():AddWingPointsData(msg.AddPointNum)
			NotifyWingTalentChange(1)
		end
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingUpdateInfo", OnS2CWingUpdateInfo)

-- 翅膀展示
-- required int32					WingID			= 3;
-- required int32					EntityId		= 4;
-- required int32					WingLevel		= 5;
local function OnS2CWingSelectShow(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then
		local function SetSelectShow(player)
			if player == nil then return end
			-- 设置wingid
			local level = msg.WingID > 0 and msg.WingLevel or 0
			player:SetWingById(msg.WingID, level)
		end

		if msg.EntityId == game._HostPlayer._ID then
			SetSelectShow(game._HostPlayer)

			NotifyWingChange(1)
		else
			local player = game._CurWorld._PlayerMan:Get(msg.EntityId)
			SetSelectShow(player)
		end
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingSelectShow", OnS2CWingSelectShow)

-- 翅膀升级
-- WingInfo
-- CostItemNum
-- CostAssistItem
-- AddExp		
-- CriticalNum	 暴击次数（单次灌注用到）
-- TotalOptNum 总操作数
-- SuccessNum	 成功数
local function OnS2CWingLevelUp(sender, msg)

	-- local CPanelUIExterior = require 'GUI.CPanelUIExterior'
	-- if CPanelUIExterior and CPanelUIExterior.Instance():IsShow() then
	-- 	if msg.AddExp > 0 then
	-- 		CPanelUIExterior.Instance():UpdateWingList()
	-- 		if msg.TotalOptNum > 1 then
	-- 			-- 自动灌注
	-- 			game._GUIMan:ShowTipText(string.format(StringTable.Get(19539), msg.TotalOptNum, msg.SuccessNum, msg.AddExp), false)	
	-- 		else
	-- 			if msg.CriticalNum > 0 then
	-- 				-- 暴击了
	-- 				game._GUIMan:ShowTipText(string.format(StringTable.Get(19538), msg.CriticalNum, msg.AddExp), false)	
	-- 			else
	-- 				game._GUIMan:ShowTipText(string.format(StringTable.Get(19536), msg.AddExp), false)
	-- 			end
	-- 		end
	-- 	else
	-- 		if msg.TotalOptNum > 0 then
	-- 			CPanelUIExterior.Instance():UpdateWingList()
	-- 			game._GUIMan:ShowTipText(StringTable.Get(19537), false)
	-- 		end
	-- 	end

	-- 	-- 错误码不为0，都弹提示
	-- 	if msg.ResCode ~= ServerMessageBase.Success then
	-- 		ErrorCodeCheck(msg.ResCode)
	-- 	end
	-- end

	-- game._GUIMan:ShowTipText(StringTable.Get(19550), false)
	-- 错误码不为0，都弹提示
	-- if msg.ResCode ~= ServerMessageBase.Success then
	-- 	ErrorCodeCheck(msg.ResCode)
	-- end
	if msg.ResCode == ServerMessageBase.Success then
		-- 更新数据
		CWingsMan.Instance():UpdateWingData(msg.WingInfo)

		local wingTemplate = CWingsMan.Instance():GetWingData(msg.WingInfo.WingID)
		if wingTemplate ~= nil then
			-- 弹提示
			local grade, level = CWingsMan.Instance():CalcGradeByLevel(msg.WingInfo.WingLevel)
			local message = string.format(StringTable.Get(19555), wingTemplate.WingName, grade, level)
			game._GUIMan:ShowTipText(message, false)
			-- 同步频道
			ChatManager.Instance():ClientSendMsg(EChatChannel.ChatChannelSystem, message, false, 0, nil,nil)
		end

		NotifyWingChange(2)
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingLevelUp", OnS2CWingLevelUp)

-- 翅膀进阶
-- WingInfo
-- AddPoint
-- EntityID		= 5;
local function OnS2CWingGradeUp(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then
		local function SetGradeUp(player)
			if player == nil then return end
			-- 刷新翅膀的显示
			local cur_wing_id = player:GetCurWingId()
			if cur_wing_id == msg.WingInfo.WingID and cur_wing_id > 0 then
				-- 翅膀进阶触发的外观改变
				player:SetWingById(cur_wing_id, msg.WingInfo.WingLevel)
			end
		end

		if msg.EntityID == game._HostPlayer._ID then
			SetGradeUp(game._HostPlayer)
			-- 更新数据
			CWingsMan.Instance():UpdateWingData(msg.WingInfo)
			CWingsMan.Instance():AddWingPointsData(msg.AddPoint)

			local wingTemplate = CWingsMan.Instance():GetWingData(msg.WingInfo.WingID)
			if wingTemplate ~= nil then
				-- 弹提示
				local message = string.format(StringTable.Get(19556), wingTemplate.WingName, msg.AddPoint)
				game._GUIMan:ShowTipText(message, false)
				-- 同步频道
				ChatManager.Instance():ClientSendMsg(EChatChannel.ChatChannelSystem, message, false, 0, nil,nil)
			end

			NotifyWingChange(3)
			NotifyWingTalentChange(1)
		else
			local player = game._CurWorld._PlayerMan:Get(msg.EntityID)
			SetGradeUp(player)
		end
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingGradeUp", OnS2CWingGradeUp)

-- 翅膀天赋查看
-- required int32					ResCode			= 2;
-- repeated WingTalentPageInfo		TalentPageInfos	= 3;
local function OnS2CWingTalentView(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then	
		-- 解析数据
		CWingsMan.Instance():SetTalentListData(msg.TalentPageInfos)

		NotifyWingTalentChange(0)
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingTalentView", OnS2CWingTalentView)


-- 翅膀天赋选择
-- required int32					ResCode			= 2;
-- required int32					PageId			= 3;
local function OnS2CWingTalentSelect(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then
		local function SetTalentSelect(player)
			if player == nil then return end
			-- 更新翅膀信息
			player:UpdateWingByPageId(msg.PageId)
		end

		if msg.EntityId == game._HostPlayer._ID then
			SetTalentSelect(game._HostPlayer)

			local message = StringTable.Get(19557)
			game._GUIMan:ShowTipText(message, false)
			-- 同步频道
			ChatManager.Instance():ClientSendMsg(EChatChannel.ChatChannelSystem, message, false, 0, nil,nil)

			NotifyWingTalentChange(2, msg.PageId)
		else
			local player = game._CurWorld._PlayerMan:Get(msg.EntityId)
			SetTalentSelect(player)
		end
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingTalentSelect", OnS2CWingTalentSelect)

-- 翅膀天赋加点
-- required int32					ResCode			= 2;
-- required WingTalentPageInfo		TalentPageInfo	= 3;
local function OnS2CWingTalentAddPoint(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageBase.Success then
		-- 更新数据
		CWingsMan.Instance():UpdateTalentDataLists(msg.TalentPageInfo)

		local message = StringTable.Get(19551)
		game._GUIMan:ShowTipText(message, false)
		-- 同步频道
		ChatManager.Instance():ClientSendMsg(EChatChannel.ChatChannelSystem, message, false, 0, nil,nil)

		NotifyWingTalentChange(3)
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingTalentAddPoint", OnS2CWingTalentAddPoint)

-- 翅膀天赋洗点
-- required int32					ResCode			= 2;
-- required int32					PageId			= 3;
-- required int32					Points			= 4;
local function OnS2CWingTalentWashPoint(sender, msg)
	-- logic

	if msg.ResCode == ServerMessageBase.Success then
		CWingsMan.Instance():ReSetTalentLeftPoints(msg.PageId, msg.Points)

		game._GUIMan:ShowTipText(StringTable.Get(19552), false)
		NotifyWingTalentChange(4, msg.PageId)
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingTalentWashPoint", OnS2CWingTalentWashPoint)

