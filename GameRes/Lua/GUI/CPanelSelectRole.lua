local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CPanelSelectRole = Lplus.Extend(CPanelBase, "CPanelSelectRole")
local def = CPanelSelectRole.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local MapBasicConfig = require "Data.MapBasicConfig" 
local bit = require "bit"
local ROLE_VAILD = require "PB.data".ERoleVaild

-- 界面
def.field("userdata")._Lab_FightScore = nil       --战力值
def.field("userdata")._Img_Race = nil 			-- 种族图
def.field("userdata")._Lab_Location = nil       --所在地图
def.field("userdata")._Lab_OnlineTime = nil       --登陆时间
def.field("userdata")._Frame_Guild = nil     --公会
def.field("userdata")._Img_GuildBG = nil
def.field("userdata")._Img_GuildFlower_1 = nil
def.field("userdata")._Img_GuildFlower_2 = nil
def.field("userdata")._Lab_Guild = nil   	  --公会名
def.field("userdata")._Lab_HPPercent = nil   --血条百分比
def.field("userdata")._Lab_MPPercent = nil   --魔法百分比
def.field("userdata")._Lab_EXPPercent = nil  --经验百分比
def.field("userdata")._Sld_HP = nil --血条
def.field("userdata")._Sld_MP = nil --魔法条
def.field("userdata")._Sld_EXP = nil --经验条
def.field("userdata")._Btn_Delete = nil --删角色按钮
def.field("table")._RoleUIList = BlankTable
-- 缓存
def.field("number")._CurSelectIdx = 0
def.field("table")._DelRoleTimer = BlankTable   --删角色的四个timer计时器
def.field("table")._TableFrameRolePos = BlankTable -- 各个角色框初始位置
def.field("number")._DeleteRoleLimit = 0 -- 立刻删除角色等级限制

----------------- CONST 常量 ---------------------------------
local FRAME_ROLE_POS_X_OFFSET = 30 -- 角色列表框X轴上的偏移
local UI_MOVE_DURATION = 0.5 -- 界面移动的时间
-----------------------------------------------------------------

local instance = nil
def.static("=>", CPanelSelectRole).Instance = function()
	if instance == nil then
		instance = CPanelSelectRole()
        instance._PrefabPath = PATH.Panel_SelectRoleNew
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance._ClickInterval = 2
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end
	-- 界面初始化
	for i = 1, GlobalDefinition.MaxRoleCount do
		local frame_role = self:GetUIObject("Frame_Role_"..i)
		local uiTemplate = frame_role:GetComponent(ClassType.UITemplate)
		if uiTemplate ~= nil then
			local uiTable =
			{
				Frame_Root = frame_role,
				Btn_Create = uiTemplate:GetControl(0),
				Btn_RoleInfo = uiTemplate:GetControl(1),
				Img_HeadIcon = uiTemplate:GetControl(4),
				Frame_Selected = uiTemplate:GetControl(3),
				Frame_Lock = uiTemplate:GetControl(8),
				-- Img_Job =  uiTemplate:GetControl(7),
				Lab_Name = uiTemplate:GetControl(5),
				Lab_Level = uiTemplate:GetControl(6),
				Lab_Recover = uiTemplate:GetControl(9),
				Lab_Prof = uiTemplate:GetControl(10),
			}
			self._RoleUIList[i] = uiTable
			-- 默认状态处理
			GUITools.SetUIActive(uiTable.Frame_Selected, false)
		end

		self._TableFrameRolePos[i] = frame_role.localPosition
	end
	self._Lab_FightScore = self:GetUIObject("Lab_FightScore")
	self._Img_Race = self:GetUIObject("Img_Race")
	self._Lab_Location =self:GetUIObject("Lab_Location")
	self._Lab_OnlineTime = self:GetUIObject("Lab_OnlineTime")
	self._Frame_Guild = self:GetUIObject("Frame_Guild")
	self._Img_GuildBG = self:GetUIObject("Img_GuildFlag_BG")
	self._Img_GuildFlower_1 = self:GetUIObject("Img_GuildFlag_Flower_1")
	self._Img_GuildFlower_2 = self:GetUIObject("Img_GuildFlag_Flower_2")
	self._Lab_Guild = self:GetUIObject("Lab_Guild")
	self._Lab_HPPercent = self:GetUIObject("Lab_HPPercent")
	self._Lab_MPPercent = self:GetUIObject("Lab_MPPercent")
	self._Lab_EXPPercent = self:GetUIObject("Lab_EXPPercent")
	self._Sld_HP = self:GetUIObject("Sld_HP"):GetComponent(ClassType.Slider)
	self._Sld_MP = self:GetUIObject("Sld_MP"):GetComponent(ClassType.Slider)
	self._Sld_EXP = self:GetUIObject("Sld_EXP"):GetComponent(ClassType.Slider)
	self._Btn_Delete = self:GetUIObject("Btn_Delete")

	self._DeleteRoleLimit = CSpecialIdMan.Get("DeleteRoleImmediatelyLevelLimit")
end

def.override("dynamic").OnData = function(self, data)
	CSoundMan.Instance():PlayBackgroundMusic(PATH.BGM_Login, 0)
	if #game._AccountInfo._RoleList <= 0 then
		error("CPanelSelectRole OnData failed, role list got empty")
		return
	end

	local selectedIndex = 1
	if type(data) == "number" then
		selectedIndex = data
	end

	self:ResetAll(selectedIndex)
end

local function EnableUIFx(obj, enable)
	if IsNil(obj) then return end
	if enable then
		GameUtil.PlayUISfx(PATH.UIFX_SELECTROLE, obj, obj, -1)
	else
		GameUtil.StopUISfx(PATH.UIFX_SELECTROLE, obj)
	end
end

def.method("number").ResetAll = function (self, selectedIndex)
	if selectedIndex <= 0 then return end

	game._AccountInfo._CurrentSelectRoleIndex = selectedIndex
	-- 重置场景
	game._RoleSceneMan:ResetRoleSelectScene(selectedIndex)
	-- 设置界面
	self:InitUIRoleList()

	if self._CurSelectIdx > 0 then
		-- 清空当前选中的状态
		local curIndex = self._CurSelectIdx
		local roleItem = self._RoleUIList[curIndex]
		if roleItem ~= nil then
			GUITools.SetUIActive(roleItem.Frame_Selected, false)
			EnableUIFx(roleItem.Img_HeadIcon, false)
			GUITools.DoKill(roleItem.Frame_Root)
			GUITools.DoLocalMove(roleItem.Frame_Root, self._TableFrameRolePos[curIndex], UI_MOVE_DURATION, nil,nil)
		end
		self._CurSelectIdx = 0
	end
	self:SelectRole(selectedIndex)
end

-- 初始化界面左侧角色列表
def.method().InitUIRoleList = function (self)
	local roleCount = #game._AccountInfo._RoleList
	for i = 1, GlobalDefinition.MaxRoleCount do
		local roleItem = self._RoleUIList[i]
		local hasRole = i <= roleCount -- 此索引下是否有角色
		roleItem.Btn_RoleInfo:SetActive(hasRole)
		roleItem.Btn_Create:SetActive(not hasRole)
		if hasRole then
			local roleData = game._AccountInfo._RoleList[i]
			-- 头像
			TeraFuncs.SetEntityCustomImg(roleItem.Img_HeadIcon, roleData.Id, roleData.Exterior.CustomImgSet, roleData.Gender, roleData.Profession)
			-- 职业徽记
			-- local professionTemplate = CElementData.GetProfessionTemplate(roleData.Profession)
			-- if professionTemplate ~= nil then
			-- 	GUITools.SetProfSymbolIcon(roleItem.Img_Job, professionTemplate.SymbolAtlasPath)
			-- end
			-- 角色名
			GUI.SetText(roleItem.Lab_Name, roleData.Name)
			-- 等级
			GUI.SetText(roleItem.Lab_Level, tostring(roleData.Level))
			-- 职业名
			GUI.SetText(roleItem.Lab_Prof, StringTable.Get(10300 + roleData.Profession - 1))
			
			if roleData.RoleVaild == ROLE_VAILD.HangUp then
				-- 角色被挂起（正在删除）
				self:FreshDelRoleShow(i)
			else
				GUITools.SetUIActive(roleItem.Frame_Lock, false)
				GUITools.SetUIActive(roleItem.Lab_Recover, false)
				GUI.SetAlpha(roleItem.Img_HeadIcon, 255)
			end
		end
	end
end

-- 选中某个角色
def.method("number").SelectRole = function (self, roleIndex)
	if roleIndex <= 0 then return end
	local originIndex = self._CurSelectIdx
	if roleIndex == originIndex then return end

	game._RoleSceneMan:ChangeRole(originIndex, roleIndex)
	-- 先处理旧的
	local originRoleItem = self._RoleUIList[originIndex]
	if originRoleItem ~= nil then
		GUITools.SetUIActive(originRoleItem.Frame_Selected, false)
		EnableUIFx(originRoleItem.Img_HeadIcon, false)
		GUITools.DoKill(originRoleItem.Frame_Root)
		GUITools.DoLocalMove(originRoleItem.Frame_Root, self._TableFrameRolePos[originIndex], UI_MOVE_DURATION, nil,nil)
	end

	-- 再处理新的
	-- 界面
	local curRoleItem = self._RoleUIList[roleIndex]
	if curRoleItem ~= nil then
		local roleData = game._AccountInfo._RoleList[roleIndex]
		if roleData ~= nil then
			-- 选中且角色状态有效
			local enable = roleData.RoleVaild == ROLE_VAILD.Vaild
			GUITools.SetUIActive(curRoleItem.Frame_Selected, enable)
			EnableUIFx(curRoleItem.Img_HeadIcon, enable)
			self._Btn_Delete:SetActive(enable)
		end
	    GUITools.DoKill(curRoleItem.Frame_Root)
	    local originPos = self._TableFrameRolePos[roleIndex]
	    local destPos = Vector3.New(originPos.x + FRAME_ROLE_POS_X_OFFSET, originPos.y, originPos.z)
		GUITools.DoLocalMove(curRoleItem.Frame_Root, destPos, UI_MOVE_DURATION, nil,nil)
	end
	self:InitUIRoleInfo(roleIndex)

	self._CurSelectIdx = roleIndex
end

-- 初始化界面右侧角色信息
def.method("number").InitUIRoleInfo = function (self, roleIndex)
	if roleIndex <= 0 then return end
	local roleData = game._AccountInfo._RoleList[roleIndex]
	if roleData == nil then return end
	-- 战力
	GUI.SetText(self._Lab_FightScore, GUITools.FormatNumber(roleData.FightScore, false, 7))
	-- 种族图
	local profTemplate = CElementData.GetProfessionTemplate(roleData.Profession)
	if profTemplate ~= nil then
		local race_icon_path = ""
		if roleData.Gender == EnumDef.Gender.Female then
			race_icon_path = profTemplate.FemaleIconAtlasPath
		else
			race_icon_path = profTemplate.MaleIconAtlasPath
		end
		GUITools.SetHeadIcon(self._Img_Race, race_icon_path)
	end
	-- 最后在线时间
	GUI.SetText(self._Lab_OnlineTime, roleData.LastLoginTime)
	-- 公会
	if not IsNilOrEmptyString(roleData.GuildName) then
		GUITools.SetUIActive(self._Frame_Guild, true)
		-- 公会名
		GUI.SetText(self._Lab_Guild, string.format("[ %s ]", roleData.GuildName))
		-- 公会图标
		local guildIconTemp = CElementData.GetTemplate("GuildIcon", roleData.Exterior.guildIcon.BaseColorID)
		if guildIconTemp ~= nil then
			GUITools.SetGuildIcon(self._Img_GuildBG, guildIconTemp.IconPath)
		end
		local guildIconTemp = CElementData.GetTemplate("GuildIcon", roleData.Exterior.guildIcon.FrameID)
		if guildIconTemp ~= nil then
			GUITools.SetGuildIcon(self._Img_GuildFlower_1, guildIconTemp.IconPath)
		end
		local guildIconTemp = CElementData.GetTemplate("GuildIcon", roleData.Exterior.guildIcon.ImageID)
		if guildIconTemp ~= nil then
			GUITools.SetGuildIcon(self._Img_GuildFlower_2, guildIconTemp.IconPath)
		end
	else
		GUITools.SetUIActive(self._Frame_Guild, false)
	end
	-- 血量
	self._Sld_HP.value = roleData.HpPercent / 100
	GUI.SetText(self._Lab_HPPercent,tostring(roleData.HpPercent).."%")
	-- 蓝量
	self._Sld_MP.value = roleData.MpPercent / 100
	GUI.SetText(self._Lab_MPPercent,tostring(roleData.MpPercent).."%")
	-- 经验
	self._Sld_EXP.value = roleData.ExpPercent / 100
	GUI.SetText(self._Lab_EXPPercent,tostring(roleData.ExpPercent).."%")
	-- 当前位置
	local strLocation = ""
	local worldData = CElementData.GetMapTemplate(roleData.MapId)
	if worldData ~= nil then
		strLocation = worldData.TextDisplayName
	end		
	-- if roleData.RegionId > 0 then
	-- 	if MapBasicConfig.IsShowRegionNameTips(roleData.MapId, roleData.RegionId) then 
	-- 		strLocation = MapBasicConfig.GetRegionName(roleData.MapId, roleData.RegionId)
	-- 	end
	-- end
	GUI.SetText(self._Lab_Location, strLocation)
end

def.override("string").OnClick = function(self,id)
	if _G.ForbidTimerId ~= 0 then				--不允许输入
		return
	end

	if string.find(id, "Btn_Role") then
		-- 选择角色
		local index = tonumber(string.sub(id, -1))
		if index == nil or index == self._CurSelectIdx then return end

		self:SelectRole(index)
	elseif id == "Btn_Enter" then
		-- 进入游戏
		game:AddForbidTimer(self._ClickInterval)

		local roleData = game._AccountInfo._RoleList[self._CurSelectIdx]
		if roleData == nil then return end

		if roleData.RoleVaild == ROLE_VAILD.HangUp then
			game._GUIMan:ShowTipText(StringTable.Get(18), false)
			return
		end

		self:OnBtnEnter()
	elseif string.find(id, "Btn_Create") then
		-- 创造角色
		game:AddForbidTimer(self._ClickInterval)

		local curRoleNum = #game._AccountInfo._RoleList
		if curRoleNum >= GlobalDefinition.MaxRoleCount then
			TODO()
		else
			game._RoleSceneMan:EnterRoleCreateStage()
		end
	elseif id == "Btn_Delete" then
		game:AddForbidTimer(self._ClickInterval)

		local role_count = #game._AccountInfo._RoleList
		if role_count <= 0 then return end

		local function callback(ret)
			if ret then
				local seleRoleID = game._AccountInfo._RoleList[self._CurSelectIdx].Id
				local C2SRoleDelete = require "PB.net".C2SRoleDelete
				local protocol = C2SRoleDelete()
				protocol.RoleId = seleRoleID
				PBHelper.Send(protocol)
			end
		end
		local level = game._AccountInfo._RoleList[self._CurSelectIdx].Level
		if level < self._DeleteRoleLimit then
			local title, message, closeType = StringTable.GetMsg(138)
			MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
		else
			local title, message, closeType = StringTable.GetMsg(27)
			MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
		end
	elseif id == "Btn_Back" then
		-- 返回
		game:AddForbidTimer(self._ClickInterval)
		game:LogoutAccount()
		game._GUIMan:Close("CPanelSelectRole")
	elseif string.find(id, "Btn_Recover_")  then
		-- 恢复角色
		game:AddForbidTimer(self._ClickInterval)

		local index = tonumber(string.sub(id, -1))
		if index == nil then return end

		self:C2SReCoverRole(index)
	end
end

--登录游戏
def.method().OnBtnEnter = function(self)
	local function callback()
		local curIndex = self._CurSelectIdx
		local roleData = game._AccountInfo._RoleList[curIndex]
		if roleData ~= nil then
			game._AccountInfo._CurrentSelectRoleIndex = curIndex
			local PBUtil = require "PB.PBUtil"
			PBUtil.SendSelectRoleProtocol(roleData.Id)
		else
			warn("CPanelSelectRole enter game failed, role data got nil, wrong index: ", tostring(curIndex))
		end
	end
	StartScreenFade(0, 1, 0.5, callback)
end

--请求恢复角色
def.method("number").C2SReCoverRole = function(self,index)
	if index < 0 then return end
	local C2SRoleReCoverReq = require "PB.net".C2SRoleReCoverReq
	local msg = C2SRoleReCoverReq()
	msg.RoleId = game._AccountInfo._RoleList[index].Id
	PBHelper.Send(msg)
end

-- 移除角色删除定时器
local function RemoveDeleteRoleTimer(self, index)
	if self._DelRoleTimer[index] ~= nil then
		_G.RemoveGlobalTimer(self._DelRoleTimer[index])
		self._DelRoleTimer[index] = nil
	end
end

--恢复角色显示
def.method("number").FreshReCoverRoleShow = function(self, nIdex)
	if nIdex <= 0 then return end
	local roleItem = self._RoleUIList[nIdex]
	if roleItem == nil then return end

	self._Btn_Delete:SetActive(true)
	GUI.SetAlpha(roleItem.Img_HeadIcon, 255)
	GUITools.SetUIActive(roleItem.Frame_Lock, false)
	GUITools.SetUIActive(roleItem.Lab_Recover, false)
	GUITools.SetUIActive(roleItem.Frame_Selected, self._CurSelectIdx == nIdex)
	EnableUIFx(roleItem.Img_HeadIcon, self._CurSelectIdx == nIdex)

	RemoveDeleteRoleTimer(self, nIdex)
end

--删角色显示
def.method("number").FreshDelRoleShow = function(self, nIdex)
	if nIdex <= 0 then return end
	local roleItem = self._RoleUIList[nIdex]
	if roleItem == nil then return end

	-- 设置界面
	self._Btn_Delete:SetActive(false)
	GUI.SetAlpha(roleItem.Img_HeadIcon, 51) -- 20%透明度
	GUITools.SetUIActive(roleItem.Frame_Lock, true)
	GUITools.SetUIActive(roleItem.Lab_Recover, true)
	GUITools.SetUIActive(roleItem.Frame_Selected, false)
	EnableUIFx(roleItem.Img_HeadIcon, false)
    
    -- 添加删除的定时器
	RemoveDeleteRoleTimer(self, nIdex)
	local function callback()
		local isRemoveTimer = true
		local roleData = game._AccountInfo._RoleList[nIdex]
		if roleData ~= nil then 
			local time = (roleData.ExpiredTime - GameUtil.GetServerTime())/1000 
			if time > 0 then
				local strTime = GUITools.FormatTimeSpanFromSeconds(time)
				strTime = string.format(StringTable.Get(21102),strTime)
				if roleItem ~= nil then
					GUI.SetText(roleItem.Lab_Recover, strTime)
				end
				isRemoveTimer = false
			else
				-- 时间到，删除客户端数据
				game:DeleteRole(roleData.Id, ROLE_VAILD.Invaild, 0)
			end
		end
		if isRemoveTimer then
			-- 没有角色数据或者时间到
			RemoveDeleteRoleTimer(self, nIdex)
		end
	end
	self._DelRoleTimer[nIdex] = _G.AddGlobalTimer(1, false, callback)
	callback() -- 手动调用一次保证显示正常
end


-- 服务器推送，角色被删除
def.method("number", "number").RoleDeleteFromServer = function(self, roleIndex, roleState)
	if roleIndex <= 0 then return end

	if roleState == ROLE_VAILD.HangUp then
		-- 角色被挂起（正在删除）
		self:FreshDelRoleShow(roleIndex)
	elseif roleState == ROLE_VAILD.Invaild then
		-- 角色被删除，重置所有并选中第一个
		self:ResetAll(1)
	end
end

def.override().OnDestroy = function(self)
	for _, v in pairs(self._DelRoleTimer) do
		if v > 0 then
			_G.RemoveGlobalTimer(v)
		end
	end
	self._DelRoleTimer = {}
	self._TableFrameRolePos = {}
	self._CurSelectIdx = 0

	self._Lab_FightScore = nil
	self._Img_Race = nil
	self._Lab_Location = nil
	self._Lab_OnlineTime = nil
	self._Frame_Guild = nil
	self._Img_GuildBG = nil
	self._Img_GuildFlower_1 = nil
	self._Img_GuildFlower_2 = nil
	self._Lab_Guild = nil
	self._Lab_HPPercent = nil
	self._Lab_MPPercent = nil
	self._Lab_EXPPercent = nil
	self._Sld_HP = nil
	self._Sld_MP = nil
	self._Sld_EXP = nil
	self._Btn_Delete = nil
	self._RoleUIList = {}
end

CPanelSelectRole.Commit()
return CPanelSelectRole