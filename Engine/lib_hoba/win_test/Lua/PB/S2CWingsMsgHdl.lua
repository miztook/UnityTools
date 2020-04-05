--
-- S2CWingsMsgHdl 翅膀功能相关处理
--
local PBHelper = require "Network.PBHelper"
local ServerMessageId = require "PB.data".ServerMessageId
local CPanelFly = require 'GUI.CPanelFly'
local CWingsMan = require 'Wings.CWingsMan'

local function ErrorCodeCheck(error_code)
	-- 职业限制
	if error_code == ServerMessageId.WingProfessionLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19506), false)
	-- 性别前置
	elseif error_code == ServerMessageId.WingSexLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19507), false)
	-- 没有发现翅膀	
	elseif error_code == ServerMessageId.WingNotFindWing then
		game._GUIMan:ShowTipText(StringTable.Get(19508), false)
	-- 没有发现天赋页
	elseif error_code == ServerMessageId.WingNotFindPage then
		game._GUIMan:ShowTipText(StringTable.Get(19509), false)
	-- 没有发现天赋
	elseif error_code == ServerMessageId.WingNotFindTalent then
		game._GUIMan:ShowTipText(StringTable.Get(19506), false)
	-- 没有足够的天赋点
	elseif error_code == ServerMessageId.WingNotEnoughtPoint then
		game._GUIMan:ShowTipText(StringTable.Get(19510), false)
	-- 前置天赋限制
	elseif error_code == ServerMessageId.WingPreTalentLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19511), false)
	elseif error_code == ServerMessageId.WingTemplateDataErr then
		game._GUIMan:ShowTipText(StringTable.Get(19512), false)	-- 模板数据错误
	elseif error_code == ServerMessageId.WingAssistItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19513), false)	-- 翅膀升级辅助道具不足
	elseif error_code == ServerMessageId.WingLevelUpItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19514), false)	-- 翅膀升级道具不足
	elseif error_code == ServerMessageId.WingGradeUpItemLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19515), false)	-- 翅膀进阶道具不足
	elseif error_code == ServerMessageId.WingLevelUpNeedGrade then
		game._GUIMan:ShowTipText(StringTable.Get(19516), false)	-- 翅膀升级已满需要进阶
	elseif error_code == ServerMessageId.WingNotEnoughExp then
		game._GUIMan:ShowTipText(StringTable.Get(19517), false)	-- 没有足够经验
	elseif error_code == ServerMessageId.WingLevelLimit then
		game._GUIMan:ShowTipText(StringTable.Get(19518), false)	-- 翅膀等级限制
	else
		warn("wings errorcode not right and not the suitable condition")
	end

end

-- 翅膀列表
-- required int32					ResCode
-- repeated WingInfo				WingList
-- TotalPoint
local function OnS2CWingViewList(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageId.Success then
		CWingsMan.Instance():ResolveWingsData(msg.WingList)
		CWingsMan.Instance():SetWingPointsData(msg.TotalPoint)		
		game._GUIMan:Open("CPanelFly", 1); 							--  开启第一页
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingViewList", OnS2CWingViewList)

-- 翅膀展示
-- required int32					WingID			= 3;
-- required int32					EntityId		= 4;
-- required int32					WingLevel		= 5;
local function OnS2CWingSelectShow(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageId.Success then
		-- 设置wingid
		local player = game._CurWorld:FindObject(msg.EntityId)
		if player then
			-- 主角的话刷一下列表状态 
			if player:IsHostPlayer() and CPanelFly.Instance():IsShow() then
				CPanelFly.Instance():RefreshRoleWingItems(msg.WingID)
			end
			-- 脱下
			if msg.WingID == 0 then
				player:RemoveWing()
			-- 装上
			else
				player:SetWingById(msg.WingID, msg.WingLevel)
			end
		end
		
		if CPanelFly and CPanelFly.Instance():IsShow() then
			if msg.EntityId == game._HostPlayer._ID then
				CPanelFly.Instance():RefreshRoleWing()
			end
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
	-- logic
	if CPanelFly and CPanelFly.Instance():IsShow() then		
		-- 更新数据
		CWingsMan.Instance():UpdateWingsData(msg.WingInfo)
		-- 刷新界面
		CPanelFly.Instance():RefreshPropWinBySel()	
		-- 上浮提示	
		if msg.AddExp > 0 then
			-- 自动灌注
			if msg.TotalOptNum > 1 then
				game._GUIMan:ShowTipText(string.format(StringTable.Get(19539), msg.TotalOptNum, msg.SuccessNum, msg.AddExp), false)	
			else
				-- 暴击了
				if msg.CriticalNum > 0 then
					game._GUIMan:ShowTipText(string.format(StringTable.Get(19538), msg.CriticalNum, msg.AddExp), false)	
				else
					game._GUIMan:ShowTipText(string.format(StringTable.Get(19536), msg.AddExp), false)	
				end
			end
		else
			if msg.TotalOptNum > 0 then
				game._GUIMan:ShowTipText(StringTable.Get(19537), false)	
			end
		end
	end

	if msg.ResCode ~= ServerMessageId.Success then
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
	if msg.ResCode == ServerMessageId.Success then
		if CPanelFly and CPanelFly.Instance():IsShow() then		
			-- 更新数据
			CWingsMan.Instance():UpdateWingsData(msg.WingInfo)
			CWingsMan.Instance():AddWingPointsData(msg.AddPoint)
			-- 刷新界面
			CPanelFly.Instance():RefreshPropWinBySel()
			-- 上浮提示			
			game._GUIMan:ShowTipText(string.format(StringTable.Get(19522), msg.AddPoint), false)	
		end

		-- 刷新翅膀的显示
		local player = game._CurWorld:FindObject(msg.EntityID)
		if player then
			player:SetWingById(msg.WingInfo.WingID, msg.WingInfo.WingLevel)
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
	if msg.ResCode == ServerMessageId.Success then
		if CPanelFly and CPanelFly.Instance():IsShow() then
			-- 解析数据
			CWingsMan.Instance():SetTalentListData(msg.TalentPageInfos)
			-- 打开界面
			CPanelFly.Instance():OpenSoulPanel()
		end
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
	if msg.ResCode == ServerMessageId.Success then
		-- 更新主角翅膀信息
		-- game._HostPlayer:UpdateWingByPageId(msg.PageId)
		if CPanelFly and CPanelFly.Instance():IsShow() then	
			if CPanelFly.Instance():ReviewTalentCheckState(msg.PageId) then
				CPanelFly.Instance():SetTalentCheckBox(true)
			end
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
	if msg.ResCode == ServerMessageId.Success then		
		if CPanelFly and CPanelFly.Instance():IsShow() then		
			-- 更新数据
			CWingsMan.Instance():UpdateTalentDataLists(msg.TalentPageInfo)
			-- 更新界面 轻量级			
			local panel_intance = CPanelFly.Instance()
			-- panel_intance:SetSoulPanelByIndex(panel_intance._Cur_Talent_Page)

		    local data =  CWingsMan.Instance():GetTalentListData()
		    if data then
		        panel_intance:InitTalentItemsPage(data[panel_intance._Cur_Talent_Page])
		    end

		end
	else
		ErrorCodeCheck(msg.ResCode)
		warn("ErrorCodeCheck === >>msg.ResCode = "..tostring(msg.ResCode))
	end
end
PBHelper.AddHandler("S2CWingTalentAddPoint", OnS2CWingTalentAddPoint)

-- 翅膀天赋洗点
-- required int32					ResCode			= 2;
-- required int32					PageId			= 3;
-- required int32					Points			= 4;
local function OnS2CWingTalentWashPoint(sender, msg)
	-- logic
	if msg.ResCode == ServerMessageId.Success then
		if CPanelFly and CPanelFly.Instance():IsShow() then		
			CWingsMan.Instance():ReSetTalentLeftPoints(msg.PageId, msg.Points)	
			-- 更新界面 轻量级			
			local panel_intance = CPanelFly.Instance()
		    local data =  CWingsMan.Instance():GetTalentListData()
		    if data and data[panel_intance._Cur_Talent_Page].PageId == msg.PageId  then
		        panel_intance:InitTalentItemsPage(data[panel_intance._Cur_Talent_Page])
		    end
		end
	else
		ErrorCodeCheck(msg.ResCode)
	end
end
PBHelper.AddHandler("S2CWingTalentWashPoint", OnS2CWingTalentWashPoint)

