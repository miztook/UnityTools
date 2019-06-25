local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"
local CPanelMainChat = require"GUI.CPanelMainChat"

_G.RedDotSystemType = 
{
	Welfare = 1, 				  -- 福利（界面上的名称为活动）
	Activity = 2,				  -- 指南
	Calendar = 3,                 -- 活动 （冒险）
	Mall = 4,					  -- 商城
	RoleInfo = 5,				  -- 信息（暂无）
	Quest = 6,					  -- 任务
	Skill = 7,					  -- 技能
	Exterior = 8,				  -- 外观
	Equip = 9,					  -- 加工
	WingDevelop = 10,             -- 飞翼养成
	Pet = 11,					  -- 宠物
	Charm = 12,					  -- 神符
	NpcShop = 13,				  -- 商店（暂无）
	Manual = 14,				  -- 生涯
	GuildList = 15,				  -- 工会
	Ranking = 16 , 				  -- 排行（暂无）
	Auction = 17, 				  -- 交易
	Bag = 18,                     -- 背包
	Mail = 19,                    -- 邮件
	Friends = 20,                 -- 好友

}
local RedDotSystemTabel = 
{
	[RedDotSystemType.Welfare] = {
									State = false,
									ObjectName = "Btn1",
									IsUnlock = true,
								 },
	[RedDotSystemType.Activity] = {
									State = false,
									ObjectName = "Btn2",
									IsUnlock = true,
								  },
	[RedDotSystemType.Calendar] = {
								State = false,
								ObjectName = "Btn3",
								IsUnlock = true,
							  },
	
	[RedDotSystemType.Mall] = {
									State = false,
									ObjectName = "Btn4",
									IsUnlock = true,
								 },

	[RedDotSystemType.RoleInfo] = {
									State = false,
									ObjectName = "Btn_F1",
									IsUnlock = true,
								 },								 
	[RedDotSystemType.Quest] = {
									State = false,
									ObjectName = "Btn_F2",
									IsUnlock = true,
								},
	[RedDotSystemType.Skill] = {
									State = false,
									ObjectName = "Btn_F3",
									IsUnlock = true,
								},
	[RedDotSystemType.Exterior] = {
									State = false,
									ObjectName = "Btn_F4",
									IsUnlock = true,
								  },													 
	[RedDotSystemType.Equip] = {
									State = false,
									ObjectName = "Btn_F5",
									IsUnlock = true,
								},
	[RedDotSystemType.WingDevelop] = {
									State = false,
									ObjectName = "Btn_F6",
									IsUnlock = true,
							 },							 																	
	[RedDotSystemType.Pet] = {
									State = false,
									ObjectName = "Btn_F7",
									IsUnlock = true,
							   },
   [RedDotSystemType.Charm] = {
									State = false,
									ObjectName = "Btn_F8",
									IsUnlock = true,
							 },
	[RedDotSystemType.NpcShop] = {
									State = false,
									ObjectName = "Btn_F9",
									IsUnlock = true,
								 },
	[RedDotSystemType.Manual] = {
									State = false,
									ObjectName = "Btn_F10",
						 			IsUnlock = true,
							    },	
	[RedDotSystemType.GuildList] = {
									State = false,
									ObjectName = "Btn_F11",
							 		IsUnlock = true,
								},	
	[RedDotSystemType.Ranking] = {
									State = false,
									ObjectName = "Btn_F12",
							 		IsUnlock = true,
								 },
	[RedDotSystemType.Auction] = {
									State = false,
									ObjectName = "Btn_F14",
									IsUnlock = true,
								 },

	[RedDotSystemType.Bag] = {
								State = false,
								ObjectName = "Btn_Bag",
							 	IsUnlock = true,
							 },
	[RedDotSystemType.Mail] = {
								State = false,
								ObjectName = "Btn_Email",
							 	IsUnlock = true,
							 },								 
	[RedDotSystemType.Friends] = {
									State = false,
									ObjectName = "Btn_Friend",
							 		IsUnlock = true,
								 },		
								 
}

-- 更新系统解锁状态
local function _UpdateSystemUnlockState(BtnName,isUnlock)
	for i = 1, 16 do 
		if RedDotSystemTabel[i].ObjectName == BtnName then 
			RedDotSystemTabel[i].IsUnlock = isUnlock 
		break end
	end
end

-- 更新系统菜单按钮
local function _UpdateSystemMenuButtonShow()
	local SystemEntrancePanel = CPanelSystemEntrance.Instance()._Panel
	local img_RedPoint = CPanelSystemEntrance.Instance():GetUIObject("Btn_Open"):FindChild("Img_Icon/Img_RedPoint")
	if img_RedPoint == nil then return end
	for i = 5 , 16 do
		if RedDotSystemTabel[i].State and RedDotSystemTabel[i].IsUnlock then 
			img_RedPoint:SetActive(true)
			return
		end
	end
	img_RedPoint:SetActive(false)
end

-- 更新界面按钮红点显示
local function _UpdateModuleRedDotShow(type,state) 
	local SystemEntrancePanel = CPanelSystemEntrance.Instance()._Panel
	local MainChatPanel = CPanelMainChat.Instance()._Panel
	RedDotSystemTabel[type].State = state
	local data = RedDotSystemTabel[type]
	if not data.IsUnlock then return end
	local img_RedPoint = nil 
	if type <= 17 then 
		if not CPanelSystemEntrance.Instance():IsShow() then return end
		if type < 5 then 
			img_RedPoint = SystemEntrancePanel:FindChild("Frame_Main/"..data.ObjectName.."/Img_Icon/Img_RedPoint")
		else
			img_RedPoint = SystemEntrancePanel:FindChild("Frame_Panel/FrameFloat/"..data.ObjectName.."/Img_bg/Img_RedPoint")
		end
	else
		if not CPanelMainChat.Instance():IsShow() then  return end
		img_RedPoint = MainChatPanel:FindChild("Frame_Group/Frame_Social/"..data.ObjectName.."/Img_RedPoint")
	end

	if img_RedPoint == nil then  return end
	img_RedPoint:SetActive(state)
	if type < 5 or type > 17 then return end
	_UpdateSystemMenuButtonShow()
end

local function _UpdateSystemEntranceRedDotShow(panel)

	for i = 1, 17 do
		local state = RedDotSystemTabel[i].State
		if state then 
			local img_RedPoint = panel:GetUIObject(RedDotSystemTabel[i].ObjectName):FindChild("Img_Icon/Img_RedPoint")
			if img_RedPoint == nil then 
				img_RedPoint = panel:GetUIObject(RedDotSystemTabel[i].ObjectName):FindChild("Img_bg/Img_RedPoint")
			end
			if img_RedPoint == nil then  break end
			if not RedDotSystemTabel[i].IsUnlock then 
				img_RedPoint:SetActive(false) 
			else
				img_RedPoint:SetActive(state)
			end
		end
	end
	_UpdateSystemMenuButtonShow()
end

local function _UpdateMainChatRedDotShow(panel)
	for i = 18, 20 do
		local state = RedDotSystemTabel[i].State
		local img_RedPoint = panel:FindChild(RedDotSystemTabel[i].ObjectName.."/Img_RedPoint")
		if img_RedPoint == nil then warn("-- UI_Main_Chat Frame Change is wrong imgRedPoint is nil") return end
		img_RedPoint:SetActive(state)
	end
end

-- 保存各个模块数据存到本地(上下线需要保存的)
local function _SaveModuleDataToUserData(typeName,data)
	local account = game._NetMan._UserName
	local UserData = require "Data.UserData"
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.RedDotModuleData, account)
	if accountInfo == nil then
		accountInfo = {}
	end
	local serverName = game._NetMan._ServerName
	if accountInfo[serverName] == nil then
		accountInfo[serverName] = {}
	end
	local roleId = game._HostPlayer._ID
	if accountInfo[serverName][roleId] == nil then
		accountInfo[serverName][roleId] = {}
	end
	accountInfo[serverName][roleId][typeName] = data

	UserData.Instance():SetCfg(EnumDef.LocalFields.RedDotModuleData, account, accountInfo)
end

-- 从本地获取存储的模块数据
local function _GetModuleDataToUserData(typeName)
	local account = game._NetMan._UserName
	local UserData = require "Data.UserData"
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.RedDotModuleData, account)
	if accountInfo ~= nil then
		local serverInfo = accountInfo[game._NetMan._ServerName]
		if serverInfo ~= nil then
			local roleInfo = serverInfo[game._HostPlayer._ID]
			if roleInfo ~= nil then
				local RedDotModuleDataMap = roleInfo[typeName]
				if RedDotModuleDataMap ~= nil then
					return RedDotModuleDataMap
				end
			end
		end
	end
	return nil 
end 

--获取模块红点状态
local function _GetModuleState(type)
	return RedDotSystemTabel[type].State
end

-- 从本地删除对应模块数据
local function _DeleteModuleDataToUserData(typeName)
	local account = game._NetMan._UserName
	local UserData = require "Data.UserData"
	local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.RedDotModuleData, account)
	if accountInfo ~= nil then
		local serverInfo = accountInfo[game._NetMan._ServerName]
		if serverInfo ~= nil then
			local roleInfo = serverInfo[game._HostPlayer._ID]
			if roleInfo ~= nil then
				local RedDotModuleDataMap = roleInfo[typeName]
				if RedDotModuleDataMap ~= nil then
					accountInfo[game._NetMan._ServerName][game._HostPlayer._ID][typeName] = nil
					UserData.Instance():SetCfg(EnumDef.LocalFields.RedDotModuleData, account, accountInfo)
				end
			end
		end
	end
end 

-- 切换账号或是切换角色时清除所有红点状态数据
local function _ClearRedTabelState ()
	for i = 1 , 20 do
		RedDotSystemTabel[i].State = false 
	end
end



_G.CRedDotMan = 
{
	UpdateSystemMenuButtonShow = _UpdateSystemMenuButtonShow,
	UpdateModuleRedDotShow = _UpdateModuleRedDotShow,
	UpdateSystemEntranceRedDotShow = _UpdateSystemEntranceRedDotShow,
	UpdateMainChatRedDotShow = _UpdateMainChatRedDotShow,
	SaveModuleDataToUserData = _SaveModuleDataToUserData,
	DeleteModuleDataToUserData = _DeleteModuleDataToUserData,
	GetModuleDataToUserData = _GetModuleDataToUserData,
	ClearRedTabelState = _ClearRedTabelState,
	UpdateSystemUnlockState = _UpdateSystemUnlockState,
	GetModuleState          = _GetModuleState,
}


return CRedDotMan