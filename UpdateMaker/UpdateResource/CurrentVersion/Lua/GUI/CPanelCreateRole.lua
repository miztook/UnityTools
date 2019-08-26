local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelCreateRole = Lplus.Extend(CPanelBase, "CPanelCreateRole")
local def = CPanelCreateRole.define

local CElementData = require "Data.CElementData"
local OutwardUtil = require "Utility.OutwardUtil"
local ServerMessageBase = require "PB.data".ServerMessageBase
local C2SRandomName = (require "PB.net".C2SRandomName)()
local PBHelper = require "Network.PBHelper"
local RandomNameGenerator = require "Utility.RandomNameGenerator"
local NameChecker = require "Utility.NameChecker"

-- 界面
def.field("userdata")._Btn_Screen = nil  	--全屏按钮
def.field("userdata")._Btn_Skip = nil  --跳过动画
def.field("userdata")._Btn_Back = nil        --后退按钮
def.field("userdata")._Frame_Job = nil --选择职业界面
def.field("userdata")._Frame_JobLeft = nil --选择职业界面左半部分
def.field("userdata")._Frame_JobRight = nil --选择职业界面右半部分
def.field("userdata")._Img_Flag = nil
def.field("userdata")._Img_JobPower = nil --职业能力显示
def.field("userdata")._Lab_Desc = nil --职业描述
def.field("userdata")._Lab_RaceName = nil    --种族名称
def.field("userdata")._Frame_Custom = nil --完善创角内容界面
def.field("userdata")._Frame_Custom_Face = nil
def.field("userdata")._Frame_Custom_Hair = nil
def.field("userdata")._RdoGroup_CustomLeft = nil
def.field("userdata")._RdoGroup_Camera = nil
def.field("userdata")._Input_PlayerName = nil
def.field("userdata")._RdoGroup_FaceIcon = nil
def.field("userdata")._RdoGroup_SkinColor = nil
def.field("userdata")._RdoGroup_HairIcon = nil
def.field("userdata")._RdoGroup_HairColor = nil
def.field("table")._RdoTable_Job = BlankTable
def.field("table")._ImgTable_JobUnSelected = BlankTable
def.field("table")._ImgTable_JobSelected = BlankTable
def.field("table")._ImgTable_SkinColor = BlankTable --肤色按钮
def.field("table")._ImgTable_HairColor = BlankTable --发色按钮
def.field("table")._ImgTable_FaceStyle = BlankTable --脸型按钮
def.field("table")._ImgTable_HairStyle = BlankTable --发型按钮
-- 缓存
def.field("number")._PanelType = -1 -- -1默认非法值  0 = 创角色选职业  1 = 完善角色信息
def.field("number")._CustomType = -1 -- 当前定制类型
def.field("number")._SelectProfTimer = 0
def.field("number")._FaceId = 1
def.field("number")._HairId = 1
def.field("number")._SkinColorId = 1
def.field("number")._HairColorId = 1
def.field("boolean")._IsUIMove = false --是否播放UI动画
def.field("table")._JobLeftPos = nil --选择职业界面左半部分坐标
def.field("table")._JobRightPos = nil --选择职业界面右半部分坐标
-- 静态数据
def.field("table")._UI_TIME = BlankTable
def.field("table")._JobLeftOutPos = nil
def.field("table")._JobRightOutPos = nil

local JOB_MOVE_DISTANCE = 360  -- 职业界面动效移动距离
local CHOICE_NUM = 8 		-- 自定义选择数量
local TEMP_LIMIT_NUM = 8    -- 限制数量（临时）
-- 界面类型
local EPanelType =
{
	Job = 1,			-- 职业界面
	Custom = 2 			-- 定制界面
}
-- 定制类型
local ECustomType =
{
	Face = 1,			-- 定制脸部
	Hair = 2,			-- 定制头发
}

local instance = nil
def.static("=>", CPanelCreateRole).Instance = function ()
	if instance == nil then
		instance = CPanelCreateRole()
        instance._PrefabPath = PATH.Panel_CreateRoleNew
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance._ClickInterval = 1
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	self:InitConstTableValue()

	self._Btn_Screen = self:GetUIObject("Btn_Screen")
	self._Btn_Skip = self:GetUIObject("Btn_Skip")
	self._Btn_Back = self: GetUIObject("Btn_Back")
	self._Frame_Job =  self:GetUIObject("Frame_Job")
	self._Frame_JobLeft = self:GetUIObject("Frame_MidL_Job")
	self._Frame_JobRight = self:GetUIObject("Frame_MidR_Job")
	self._Img_JobPower = self:GetUIObject("Img_JobPower")
	self._Lab_Desc = self:GetUIObject("Lab_Desc")
	self._Lab_RaceName = self: GetUIObject("Lab_JobName")
	self._Img_Flag = self:GetUIObject("Img_Flag")
	self._Frame_Custom = self:GetUIObject("Frame_Custom")
	self._Frame_Custom_Face = self:GetUIObject("Frame_Custom_Face")
	self._Frame_Custom_Hair = self:GetUIObject("Frame_Custom_Hair")
	self._Input_PlayerName = self:GetUIObject("Input_InputName"):GetComponent(ClassType.InputField)
	self._RdoGroup_CustomLeft = self:GetUIObject("RdoGroup_CustomLeft")
	self._RdoGroup_Camera = self:GetUIObject("RdoGroup_Camera")
	self._RdoGroup_FaceIcon = self:GetUIObject("RdoGroup_FaceIcon")
	self._RdoGroup_SkinColor = self:GetUIObject("RdoGroup_SkinColor")
	self._RdoGroup_HairIcon = self:GetUIObject("RdoGroup_HairIcon")
	self._RdoGroup_HairColor = self:GetUIObject("RdoGroup_HairColor")
	for i=1, GlobalDefinition.ProfessionCount do
		local rdo = self:GetUIObject("Rdo_Job_" .. i)
		self._RdoTable_Job[i] = rdo:GetComponent(ClassType.Toggle)
		self._ImgTable_JobUnSelected[i] = rdo:FindChild("Img_U")
		self._ImgTable_JobSelected[i] = rdo:FindChild("Img_D/Img_Icon_D")

		if i == EnumDef.Profession.Lancer then
			-- 设置枪骑士显隐
			local options = GameConfig.Get("FuncOpenOption")
			GUITools.SetUIActive(rdo, not options.HideLancer)
		end
	end
	for i=1, CHOICE_NUM do
		self._ImgTable_SkinColor[i] = self:GetUIObject("Img_SkinColor_"..i)
		self._ImgTable_HairColor[i] = self:GetUIObject("Img_HairColor_"..i)
		self._ImgTable_FaceStyle[i] = self:GetUIObject("Img_FaceIcon_"..i)
		self._ImgTable_HairStyle[i] = self:GetUIObject("Img_HairIcon_"..i)

		local enable = i <= TEMP_LIMIT_NUM
		-- 肤色
		local rdo_skin_color = self:GetUIObject("Rdo_SkinColor_"..i)
		GameUtil.SetButtonInteractable(rdo_skin_color, enable)
		GUITools.SetUIActive(self._ImgTable_SkinColor[i], enable)
		-- 发色
		local rdo_hair_color = self:GetUIObject("Rdo_HairColor_"..i)
		GameUtil.SetButtonInteractable(rdo_hair_color, enable)
		GUITools.SetUIActive(self._ImgTable_HairColor[i], enable)
		-- 脸型
		local rdo_face_icon = self:GetUIObject("Rdo_FaceIcon_"..i)
		GameUtil.SetButtonInteractable(rdo_face_icon, enable)
		local img_face_icon_bg = rdo_face_icon:FindChild("Img_OpenBG")
		GUITools.SetUIActive(img_face_icon_bg, enable)
		GUITools.SetUIActive(self._ImgTable_FaceStyle[i], enable)
		-- 发型
		local rdo_hair_icon = self:GetUIObject("Rdo_HairIcon_"..i)
		GameUtil.SetButtonInteractable(rdo_hair_icon, enable)
		local img_hair_icon_bg = rdo_hair_icon:FindChild("Img_OpenBG")
		GUITools.SetUIActive(img_hair_icon_bg, enable)
		GUITools.SetUIActive(self._ImgTable_HairStyle[i], enable)
	end

	self._Btn_Screen:SetActive(true)
	self._Frame_Job:SetActive(true)
	self._Frame_Custom:SetActive(true)
	self._Frame_Custom_Face:SetActive(true)
	self._Frame_Custom_Hair:SetActive(true)

	self._JobLeftPos = self._Frame_JobLeft.localPosition
	self._JobRightPos = self._Frame_JobRight.localPosition
	self._JobLeftOutPos = Vector3.New(self._JobLeftPos.x - JOB_MOVE_DISTANCE, self._JobLeftPos.y, self._JobLeftPos.z)
	self._JobRightOutPos = Vector3.New(self._JobRightPos.x + JOB_MOVE_DISTANCE, self._JobRightPos.y, self._JobRightPos.z)
end

--给所有的const赋值
def.method().InitConstTableValue = function (self)
	self._UI_TIME = 
	{
		[1] = { _begin = 190, _end = 206 },
		[2] = {	_begin = 150, _end = 170 },
		[3] = { _begin = 169, _end = 186 },
		[4] = { _begin = 195, _end = 210 },
		[5] = { _begin = 195, _end = 210 },
	}
end

def.override("dynamic").OnData = function (self, data)
	if type(data) ~= "number" then
		warn("CPanelCreateRole need a profession")
		return
	end
	-- 职业ID即索引
	local professionId = data
	self._RdoTable_Job[professionId].isOn = true
	self:OnSelectProf(professionId)
end

def.method("number").OnSelectProf = function (self, profId)
	local originProfId = game._RoleSceneMan:GetCurProfId()
	if profId == originProfId then return end

	if originProfId >= 0 then
		local imgUObj = self._ImgTable_JobUnSelected[originProfId]
		if not IsNil(imgUObj) then
			GUITools.SetUIActive(imgUObj, true)
		end
		local imgObj = self._ImgTable_JobSelected[originProfId]
		if not IsNil(imgObj) then
			GameUtil.StopUISfx(PATH.UIFX_CREATEROLE, imgObj)
		end
	end
	do
		local imgUObj = self._ImgTable_JobUnSelected[profId]
		if not IsNil(imgUObj) then
			GUITools.SetUIActive(imgUObj, false)
		end
		local imgObj = self._ImgTable_JobSelected[profId]
		if not IsNil(imgObj) then
			GameUtil.PlayUISfx(PATH.UIFX_CREATEROLE, imgObj, imgObj, -1)
		end
	end

	game._RoleSceneMan:SelectProfession(profId, function()
		if not self:IsShow() then return end

		self:ResetBtnState(false)
	end)

	-- 重置界面相关
	self:InitUI(profId)

	-- 需要在CG期间展开界面
	if self._SelectProfTimer ~= 0 then
		_G.RemoveGlobalTimer(self._SelectProfTimer)
		self._SelectProfTimer = 0
	end
	-- ??不明白为什么除以30
	local beginTime = self._UI_TIME[profId]._begin / 30
	local endTime = self._UI_TIME[profId]._end / 30
	self._SelectProfTimer = _G.AddGlobalTimer(beginTime, true, function()
		self:ShowJobInfo(false, endTime - beginTime, nil)
	end)

	self._PanelType = EPanelType.Job
end

def.override("string").OnClick = function(self,id)
	if _G.ForbidTimerId ~= 0 then				--不允许输入
		return
	end

	if id == "Btn_RandomName" then
		game:AddForbidTimer(0.5)

		self:GenerateRandomName()
	elseif id == "Btn_Confirm" then
		game:AddForbidTimer(self._ClickInterval)

		if NameChecker.CheckRoleNameValidWhenCreate(self._Input_PlayerName.text) then
			local function callback()
				if not self:IsShow() then return end

				game._RoleSceneMan:SendC2SRoleCreate(self._Input_PlayerName.text,
													 self._FaceId,
													 self._HairId,
													 self._SkinColorId,
													 self._HairColorId)
			end
			StartScreenFade(0, 1, 0.5, callback)
		end
	elseif id == "Btn_Back" then
		game:AddForbidTimer(self._ClickInterval)

		CGMan.StopCG()
		
		--创角色界面返回选角色界面
		if self._PanelType == EPanelType.Job then
			-- CSoundMan.Instance():PlayBackgroundMusic(PATH.BGM_Login, 0)
			
			local role_list = game._AccountInfo._RoleList
			if #role_list <= 0 then
				-- 返回登录界面
				game:LogoutAccount()
			else
				game._RoleSceneMan:EnterRoleSelectStage(1)
			end
		elseif self._PanelType == EPanelType.Custom then
			--信息完善界面，返回创角色界面
			self._PanelType = EPanelType.Job
			self._FaceId = 1
			self._HairId = 1
			self._SkinColorId = 1
			self._HairColorId = 1

			game._RoleSceneMan:ResetRoleCreateScene()
			-- 界面
			-- GameUtil.EnableRotate(model, false)
			GameUtil.EnableBlockCanvas(true)
			self:ShowJobInfo(false, self._ClickInterval, function ()
				-- GameUtil.EnableRotate(model, true)
				GameUtil.EnableBlockCanvas(false)
			end)
		end
	elseif id == "Btn_Next" then
		game:AddForbidTimer(self._ClickInterval)

		self._PanelType = EPanelType.Custom
		self._CustomType = ECustomType.Face

		game._RoleSceneMan:FocusModel()
		-- 界面
		GameUtil.EnableBlockCanvas(true)
		self:ResetToggleState()
		self:StartFrameJobTween(false, 1, function()
			-- if self._PanelType ~= EPanelType.Custom then return end

			GameUtil.EnableBlockCanvas(false)
			GUITools.SetUIActive(self._Frame_Custom, true)
			GUITools.SetUIActive(self._Frame_Custom_Face, true)
			GUITools.SetUIActive(self._Frame_Custom_Hair, false)
		end)
	elseif id == "Btn_Screen" then
		self._Btn_Skip:SetActive(true)
	elseif id == "Btn_Skip" then
		if self._SelectProfTimer ~= 0 then
			_G.RemoveGlobalTimer(self._SelectProfTimer)
			self._SelectProfTimer = 0
		end
		StartScreenFade(0, 1, 0.5, function ()
			StartScreenFade(1, 0, 0.5,nil)

			game._RoleSceneMan:SkipCG()
			-- 界面
			self:ShowJobInfo(true, 0, nil)
			self:ResetBtnState(false)
		end)
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if string.find(id, "Rdo_Job_") and checked then
		-- 选择职业
		local profId = tonumber(string.sub(id, -1))
		if type(profId) ~= "number" then return end
		self:OnSelectProf(profId)
	elseif string.find(id, "Rdo_Custom_") then
		local customType = tonumber(string.sub(id, -1))
		if customType == nil or customType == self._CustomType then return end

		self._CustomType = customType
		if customType == ECustomType.Face then
			GUITools.SetUIActive(self._Frame_Custom_Face, true)
			GUITools.SetUIActive(self._Frame_Custom_Hair, false)
		elseif customType == ECustomType.Hair then
			GUITools.SetUIActive(self._Frame_Custom_Face, false)
			GUITools.SetUIActive(self._Frame_Custom_Hair, true)
		end
	elseif string.find(id, "Rdo_Camera_") then
		local camType = tonumber(string.sub(id, -1))
		if camType == nil then return end

		game._RoleSceneMan:ChangeCreateCamera(camType)
	else
		--以下逻辑为换脸用，如有上述条件，请在以上位置 添加elseif逻辑
		local index = tonumber(string.sub(id, -1))
		if type(index) ~= "number" then return end
		-- 切换脸，发型，肤色，发色
		if string.find(id, "Rdo_FaceIcon_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_FaceIcon, self._FaceId)
				return
			end

			if index == self._FaceId then return end
			self._FaceId = index
			game._RoleSceneMan:ChangeModelExterior(false, false, self._SkinColorId, index)
		elseif string.find(id, "Rdo_HairIcon_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_HairIcon, self._HairId)
				return
			end

			if index == self._HairId then return end
			self._HairId = index
			game._RoleSceneMan:ChangeModelExterior(false, true, self._HairColorId, index)
		elseif string.find(id, "Rdo_SkinColor_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_SkinColor, self._SkinColorId)
				return
			end

			if index == self._SkinColorId then return end
			self._SkinColorId = index
			game._RoleSceneMan:ChangeModelExterior(true, false, index, 0)
		elseif string.find(id, "Rdo_HairColor_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_HairColor, self._HairColorId)
				return
			end

			if index == self._HairColorId then return end
			self._HairColorId = index
			game._RoleSceneMan:ChangeModelExterior(true, true, index, 0)
		end
	end
end

-- 获取种族名
local function GetRaceNameStr(prof)
	local str = ""
	if prof == EnumDef.Profession.Warrior then
		str = StringTable.Get(31400)
	elseif prof == EnumDef.Profession.Aileen then
		str = StringTable.Get(31401)
	elseif prof == EnumDef.Profession.Assassin then
		str = StringTable.Get(31403)
	elseif prof == EnumDef.Profession.Archer then
		str = StringTable.Get(31402)
	elseif prof == EnumDef.Profession.Lancer then
		str = StringTable.Get(31401)
	end
	return str
end

--初始化UI显示
def.method("number").InitUI = function(self, profId)
	if profId <= 0 then return end

	self:ResetBtnState(true)
	self:SetFrameJobPos(false)
	GUITools.SetUIActive(self._Frame_Job, false)
	GUITools.SetUIActive(self._Frame_Custom, false)
	self._Input_PlayerName.text = game._AccountInfo._OrderRoleName -- 读取预约名字，没有预约会为空字符串

	--根据选择角色，修改职业显示
	GUITools.SetGroupImg(self._Img_JobPower, profId - 1)
	GUITools.SetGroupImg(self._Img_Flag, profId - 1)
	--local prof_template = CElementData.GetProfessionTemplate(profId)
	--if prof_template ~= nil then
		local text = StringTable.Get(50 + profId)
		GUI.SetText(self._Lab_Desc, text)
		GUI.SetText(self._Lab_RaceName, GetRaceNameStr(profId))
	--end

	for i = 1, TEMP_LIMIT_NUM do
		--设置肤色Image
		local path_id = OutwardUtil.Get(profId, "SkinIconColor", i)
		local ColorConfig = require "Data.ColorConfig"
		local info = ColorConfig.GetColorInfo(path_id)
		local Skincolor = Color.New(info[1] / 255,info[2]/255,info[3]/255,1)
		GameUtil.SetImageColor(self._ImgTable_SkinColor[i],Skincolor)

		--设置发色Image
		path_id = OutwardUtil.Get(profId, "HairIconColor", i)
		ColorConfig = require "Data.ColorConfig"
		info = ColorConfig.GetColorInfo(path_id)
		local HairColor = Color.New(info[1]/255,info[2]/255,info[3]/255,1)
		GameUtil.SetImageColor(self._ImgTable_HairColor[i],HairColor)

		--设置脸型
		local facePath = OutwardUtil.Get(profId, "FaceIcon", i)
		GUITools.SetIcon(self._ImgTable_FaceStyle[i], facePath)

		--设置发型
		local hairPath = OutwardUtil.Get(profId, "HairIcon", i)
		GUITools.SetIcon(self._ImgTable_HairStyle[i], hairPath)
	end
end

def.method("boolean").ResetBtnState = function (self, isInCG)
	GUITools.SetUIActive(self._Btn_Screen, isInCG)
	GUITools.SetUIActive(self._Btn_Back, not isInCG)
	self._Btn_Skip:SetActive(false)
end

def.method().ResetToggleState = function (self)
	GUI.SetGroupToggleOn(self._RdoGroup_CustomLeft, 1)
	GUI.SetGroupToggleOn(self._RdoGroup_Camera, 2) -- 默认选半身相机
	GUI.SetGroupToggleOn(self._RdoGroup_FaceIcon, 1)
	GUI.SetGroupToggleOn(self._RdoGroup_SkinColor, 1)
	GUI.SetGroupToggleOn(self._RdoGroup_HairIcon, 1)
	GUI.SetGroupToggleOn(self._RdoGroup_HairColor, 1)
end

-- 显示职业选择界面
def.method("boolean", "number", "function").ShowJobInfo = function(self, isImmediatly, interval, callback)
	GUITools.SetUIActive(self._Frame_Job, true)
	GUITools.SetUIActive(self._Frame_Custom, false)

	if self._IsUIMove then
		GUITools.DoKill(self._Frame_JobLeft)
		GUITools.DoKill(self._Frame_JobRight)
		self._IsUIMove = false
	end
	if isImmediatly then
		self:SetFrameJobPos(true)
	else
		self:StartFrameJobTween(true, interval, callback)
	end
end

def.method("boolean").SetFrameJobPos = function (self, enable)
	if enable then
		self._Frame_JobLeft.localPosition = self._JobLeftPos
		self._Frame_JobRight.localPosition = self._JobRightPos
	else
		self._Frame_JobLeft.localPosition = self._JobLeftOutPos
		self._Frame_JobRight.localPosition = self._JobRightOutPos
	end
end

def.method("boolean", "number", "function").StartFrameJobTween = function (self, isMoveIn, interval, callback)
	local function OnTweenComplete()
		self._IsUIMove = false
		if callback ~= nil then
			callback()
		end
	end

	local frame_left = self._Frame_JobLeft
	local frame_right = self._Frame_JobRight
	if isMoveIn then
		GUITools.DoLocalMove(frame_left, self._JobLeftPos, interval, nil, nil)
		GUITools.DoLocalMove(frame_right, self._JobRightPos, interval, nil, OnTweenComplete)
	else
		GUITools.DoLocalMove(frame_left, self._JobLeftOutPos, interval, nil, nil)
		GUITools.DoLocalMove(frame_right, self._JobRightOutPos, interval, nil, OnTweenComplete)
	end
	self._IsUIMove = true
end

local randomNameCount = 0
local roleRandomName = ""
--随机名字向服务器发送协议
def.method().GenerateRandomName = function(self)
	local profId = game._RoleSceneMan:GetCurProfId()
	if profId <= 0 then return end

	if randomNameCount <= 5 then
		roleRandomName = RandomNameGenerator.GenerateRandomName(profId)
	else
		-- 随机名字验证失败大于5次，获取小于最大长度的名字，然后补随机数量的随机数字
		local max = GlobalDefinition.MaxRoleNameLength
		local curLength = NameChecker.GetNameLength(roleRandomName)
		if curLength >= max then
			local repeatCount = 0
			repeat
				repeatCount = repeatCount + 1
				if repeatCount > 10 then
					warn("GenerateRandomName----TeraLucky")
					roleRandomName = ""
					curLength = NameChecker.GetNameLength(roleRandomName)
					break
				end
				roleRandomName = RandomNameGenerator.GenerateRandomName(profId)
				curLength = NameChecker.GetNameLength(roleRandomName)
			until curLength < max
		end
		local min = NameChecker.GetNameLength(roleRandomName)
		local count = math.random(1, max - min)
		for i = 1, count do
			roleRandomName = roleRandomName .. math.random(0, 9) 
		end
	end

	if roleRandomName == "" then
		self:SetRandomName()
		game._GUIMan:ShowTipText(StringTable.Get(31504), false)
	else
		-- print("C2SRandomName", roleRandomName)
		C2SRandomName.name = roleRandomName
		PBHelper.Send(C2SRandomName)
		randomNameCount = randomNameCount + 1
	end
end

--设置随机名字
def.method().SetRandomName = function(self)
	randomNameCount = 0
	self._Input_PlayerName.text = roleRandomName
	roleRandomName = ""
end

def.override().OnDestroy = function(self)
	self._UI_TIME = {}
	if self._SelectProfTimer ~= 0 then
		_G.RemoveGlobalTimer(self._SelectProfTimer)
		self._SelectProfTimer = 0
	end

	self._Btn_Screen = nil  	--全屏按钮
	self._Btn_Skip = nil  --跳过动画
	self._Btn_Back = nil        --后退按钮
	self._Frame_Job = nil --选择职业界面
	self._Frame_JobLeft = nil --选择职业界面左半部分
	self._Frame_JobRight = nil --选择职业界面右半部分
	self._Img_Flag = nil
	self._Img_JobPower = nil --职业能力显示
	self._Lab_Desc = nil --职业描述
	self._Lab_RaceName = nil    --种族名称
	self._Frame_Custom = nil --完善创角内容界面
	self._Frame_Custom_Face = nil
	self._Frame_Custom_Hair = nil
	self._Input_PlayerName = nil
	self._RdoGroup_CustomLeft = nil
	self._RdoGroup_Camera = nil
	self._RdoGroup_FaceIcon = nil
	self._RdoGroup_SkinColor = nil
	self._RdoGroup_HairIcon = nil
	self._RdoGroup_HairColor = nil
	self._RdoTable_Job = {}
	self._ImgTable_JobUnSelected = {}
	self._ImgTable_JobSelected = {}
	self._ImgTable_SkinColor = {}
	self._ImgTable_HairColor = {}
	self._ImgTable_FaceStyle = {}
	self._ImgTable_HairStyle = {}

	self._IsUIMove = false --是否播放UI动画
	self._FaceId = 1
	self._HairId = 1
	self._SkinColorId = 1
	self._HairColorId = 1

	-- 释放本地数据
	randomNameCount = 0
	roleRandomName = nil
	RandomNameGenerator.ReleaseRandomNameTable()
end

CPanelCreateRole.Commit()
return CPanelCreateRole