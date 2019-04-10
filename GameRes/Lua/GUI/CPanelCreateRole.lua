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
def.field("table")._ImgTable_JobSelected = BlankTable
def.field("table")._ImgTable_SkinColor = BlankTable --肤色按钮
def.field("table")._ImgTable_HairColor = BlankTable --发色按钮
def.field("table")._ImgTable_FaceStyle = BlankTable --脸型按钮
def.field("table")._ImgTable_HairStyle = BlankTable --发型按钮
-- 缓存
def.field("table")._SceneGOTable = BlankTable
def.field("number")._CurProfId = -1 --非法值
def.field("number")._PanelType = -1 -- -1默认非法值  0 = 创角色选职业  1 = 完善角色信息
def.field("number")._CustomType = -1 -- 当前定制类型
def.field("number")._CameraType = -1 -- 当前相机类型
def.field("number")._RandomAnimationTimer = 0 --随机动画timer
def.field("number")._SelectRoleTimer = 0
def.field("number")._CameraAnimationTimer = 0
def.field("number")._CloseBGTimer = 0
def.field("number")._FaceId = 1
def.field("number")._HairId = 1
def.field("number")._SkinColorId = 1
def.field("number")._HairColorId = 1
def.field("boolean")._IsCgPlaying = false --是否CG播放中
def.field("boolean")._IsSkip = false --是否跳过动画
def.field("boolean")._IsUIMove = false --是否播放UI动画
def.field("table")._JobLeftPos = nil --选择职业界面左半部分坐标
def.field("table")._JobRightPos = nil --选择职业界面右半部分坐标
-- 静态数据
def.field("table")._CGPathCfg = BlankTable
def.field("table")._ModelPath = BlankTable
def.field("table")._BGMPathCfg = BlankTable
def.field("table")._SkillAudioPathCfg = BlankTable
def.field("table")._BGAnimationPath = BlankTable
def.field("string")._LightPath = "Lights/DirectionalLight_Player"
def.field("string")._CameraPath = "MainAnimator/CameraAnimator/Camera"
def.field("string")._CloseBGOnPath = "MainAnimator/CameraAnimator/CloseBGon"
def.field("string")._CloseBGOffPath = "MainAnimator/CameraAnimator/CloseBGoff"
def.field("table")._UI_TIME = BlankTable
def.field("table")._BGIdleAniName = BlankTable
def.field("table")._JobLeftOutPos = nil
def.field("table")._JobRightOutPos = nil

local JOB_MOVE_DISTANCE = 360  -- 职业界面动效移动距离
local PROFESSION_NUM = 5 	-- 职业数量
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
-- 相机类型
local ECameraType =
{
	Face = 1,			-- 脸部相机
	Halfbody = 2,		-- 半身相机
	Body = 3,			-- 全身相机
	Job = 4				-- 选择职业相机
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
	for i=1, PROFESSION_NUM do
		local rdo = self:GetUIObject("Rdo_Job_" .. i)
		self._RdoTable_Job[i] = rdo:GetComponent(ClassType.Toggle)
		self._ImgTable_JobSelected[i] = rdo:FindChild("Img_D/Img_Icon_D")
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

	-- 获取各职业的场景物体
	local scene = game:GetRoleCreateScene()
	for i = 1, PROFESSION_NUM do
		local child = scene:GetChild(i-1)
		child:SetActive(false)
		local close_bg_on_gameobject = child:FindChild(self._CloseBGOnPath)
		if not IsNil(close_bg_on_gameobject) then
			close_bg_on_gameobject:SetActive(false)
		end
		local close_bg_off_gameobject = child:FindChild(self._CloseBGOffPath)
		if not IsNil(close_bg_off_gameobject) then
			close_bg_off_gameobject:SetActive(false)
		end
		self._SceneGOTable[i] = 
		{
			_Root = child,
			_CameraAnimation = child:GetChild(0),
			_Model= child:FindChild(self._ModelPath[i]),
			_CGModel = child:FindChild(self._ModelPath[i].."_CG"),
			_StopBGAnimation = child:FindChild(self._BGAnimationPath[i]),
			_PlayerLight = child:FindChild(self._LightPath),
			_CloseBGOn = close_bg_on_gameobject,
			_CloseBGOff = close_bg_off_gameobject,
		}

		--fix
		do --not _G.IsUseRealTimeShadowInLogin() then
			local obj = self._SceneGOTable[i]._PlayerLight
			if obj ~= nil then
				GameUtil.EnableLightShadow(obj, false)
			end
		end

		do 
			local obj = self._SceneGOTable[i]._Root:FindChild(self._CameraPath)
			if obj ~= nil then

				GameUtil.FixCameraSetting(obj)

				local enable = _G.IsUseBloomHDInLogin()
				GameUtil.EnableBloomHD(obj, enable)

				local cam = obj:GetComponent(ClassType.Camera)
				if cam ~= nil then
				 	cam.useOcclusionCulling = false
				end
			end
		end
	end
end

--给所有的const赋值
def.method().InitConstTableValue = function (self)
	self._CGPathCfg = 
	{
		"Assets/Outputs/CG/CreatCharacter/Creat_Job1_show.prefab",
		"Assets/Outputs/CG/CreatCharacter/Creat_Job2_show.prefab",
		"Assets/Outputs/CG/CreatCharacter/Creat_Job3_show.prefab",
		"Assets/Outputs/CG/CreatCharacter/Creat_Job4_show.prefab",
		"Assets/Outputs/CG/CreatCharacter/Creat_Job5_show.prefab",
	}

	self._BGMPathCfg = 
	{
		PATH.BGM_Warrior_Theme, --"Assets/Outputs/Sound/Bgm/Human_Theme.mp3",
		PATH.BGM_Priest_Theme, --"Assets/Outputs/Sound/Bgm/Popori_Theme.mp3",
		PATH.BGM_Assassin_Theme, --"Assets/Outputs/Sound/Bgm/Castanic_Theme.mp3",
		PATH.BGM_Archer_Theme, --"Assets/Outputs/Sound/Bgm/HighElf_Theme.mp3",
		PATH.BGM_Lancer_Theme,
	}

	self._SkillAudioPathCfg =
	{
		PATH.Skill_Warrior_Lobby,
		PATH.Skill_Priest_Lobby,
		PATH.Skill_Assassin_Lobby,
		PATH.Skill_Archer_Lobby,
		PATH.Skill_Lancer_Lobby,
	}

	self._BGAnimationPath = 
	{
		"MainAnimator/BGAnimator/BGAnimation_Hum",
		"MainAnimator/BGAnimator/BGAnimation_Ali",
		"MainAnimator/BGAnimator/BGAnimation_cas",
		"",
		"MainAnimator/BGAnimator/BGAnimation_aliL",
	}

	self._ModelPath = 
	{	
		"MainAnimator/Character/CharacterRoot/humwarrior_m_create",
		"MainAnimator/Character/CharacterRoot/alipriest_f_create",
		"MainAnimator/Character/CharacterRoot/casassassin_m_create",
		"MainAnimator/Character/CharacterRoot/sprarcher_f_create",
		"MainAnimator/Character/CharacterRoot/alilancer_f_create",
	}

	self._UI_TIME = 
	{
		[1] =
		{
			_begin = 190,
			_end = 206,
		},
		[2] =
		{	
			_begin = 150,
			_end = 170,
		},
		[3] =
		{
			_begin = 169,
			_end = 186,
		},
		[4] = 
		{
			_begin = 195,
			_end = 210,
		},
		[5] = 
		{
			_begin = 195,
			_end = 210,
		},
	}

	self._BGIdleAniName = 
	{
		"idle_BG_Hum",
		"idle_BG_ali",
		"idle_BG_cas",
		"",
		"idle_BG_aliL",
	}
end

def.override("dynamic").OnData = function (self, data)
	-- 职业ID即索引
	local professionId = math.random(1, PROFESSION_NUM)
	self._RdoTable_Job[professionId].isOn = true
	self:OnSelectRole(professionId)
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

-- CG结束后重置场景动画和其他状态
def.method().OnFinishCG = function(self)
	if not self._IsCgPlaying then return end 
	self._IsCgPlaying = false
	self._CameraType = ECameraType.Job

	self:ResetBtnState(false)

	local profId = self._CurProfId
	-- self._SceneGOTable[profId]._CGModel:SetActive(false)
	local model = self._SceneGOTable[profId]._Model
	-- model:SetActive(true)
	GameUtil.EnableRotate(model, true)

	--[[ 屏蔽休闲动作
	if self._RandomAnimationTimer ~= 0 then
		_G.RemoveGlobalTimer(self._RandomAnimationTimer)
		self._RandomAnimationTimer = 0
	end
	local standAnimation = model:GetComponent(ClassType.Animation)		
	if standAnimation == nil then return end
	standAnimation:Play("create_stand")
	local nStandTime = standAnimation:GetClip("create_stand").length
	local nIdleTime = standAnimation:GetClip("create_idle1").length
	local function callback()
		if IsNil(standAnimation) then return end

		standAnimation:Play("create_idle1")
		--UnityUtil.PlayAnimation(model, "create_idle1", 1)	
		--standAnimation:PlayQueued("create_stand")
		
		local function cb()
			if IsNil(standAnimation) then return end
			standAnimation:Play("create_stand")
			self._RandomAnimationTimer = _G.AddGlobalTimer(2*nStandTime, true, callback)
		end
		self._RandomAnimationTimer = _G.AddGlobalTimer(nIdleTime, true, cb)
	end

	self._RandomAnimationTimer = _G.AddGlobalTimer(nStandTime, true, callback)
	--]]
end

def.method("number").OnSelectRole = function (self, profId)
	if profId == self._CurProfId then return end

	local originProfId = self._CurProfId
	if originProfId >= 0 then
		-- 隐藏原来的场景
		if self._SceneGOTable[originProfId] ~= nil then
			self._SceneGOTable[originProfId]._Root:SetActive(false)
		end
		local imgObj = self._ImgTable_JobSelected[originProfId]
		if not IsNil(imgObj) then
			GameUtil.StopUISfx(PATH.UIFX_CREATEROLE, imgObj)
		end
	end
	
	self._CurProfId = profId
	self._PanelType = EPanelType.Job

	-- 重置界面相关
	self:ResetBtnState(true)
	self:SetFrameJobPos(false)
	GUITools.SetUIActive(self._Frame_Job, false)
	GUITools.SetUIActive(self._Frame_Custom, false)
	self:InitUI()
	self._Input_PlayerName.text = game._AccountInfo._OrderRoleName
	-- self:GenerateRandomName() --切换角色根据角色职业重新随机生成名字

	if self._SceneGOTable[profId] ~= nil then
		GameUtil.SetSceneEffect(self._SceneGOTable[profId]._Root)
		-- 重置模型状态
		local model = self._SceneGOTable[profId]._Model
		model.localRotation = Quaternion.identity
		GameUtil.EnableRotate(model, false)
	end
	local imgObj = self._ImgTable_JobSelected[profId]
	if not IsNil(imgObj) then
		GameUtil.PlayUISfx(PATH.UIFX_CREATEROLE, imgObj, imgObj, -1)
	end

	--播放角色主题音乐
	CSoundMan.Instance():PlayBackgroundMusic(self._BGMPathCfg[profId], 0)
	CSoundMan.Instance():Play2DAudio(self._SkillAudioPathCfg[profId], 0)
	-- CG
	self._IsCgPlaying = true
	CGMan.StopCG()
	CGMan.PlayByNameEx(self._CGPathCfg[profId], function()
		if self._IsSkip then return end
		self:OnFinishCG()
	end, nil, true)

	-- 需要在CG期间展开界面
	if self._SelectRoleTimer ~= 0 then
		_G.RemoveGlobalTimer(self._SelectRoleTimer)
		self._SelectRoleTimer = 0
	end
	-- ??不明白为什么除以30
	local beginTime = self._UI_TIME[profId]._begin / 30
	local endTime = self._UI_TIME[profId]._end / 30
	self._SelectRoleTimer = _G.AddGlobalTimer(beginTime, true, function()
		if not self._IsCgPlaying then return end -- CG被跳过

		self:ShowJobInfo(false, endTime - beginTime, nil)
	end)
end

local function ChangeFace(self, profId, index)
	local cur_selected = self._SceneGOTable[profId]
	if cur_selected == nil then 
		warn("can not find prof scene gameobject, profId == " .. profId)
		return
	end

	local cur_model  = cur_selected._Model
	local function callback()
		--换脸之前换过肤色了。要给人家设置回去！
		OutwardUtil.ChangeSkinColor(cur_model, profId, self._SkinColorId)
	end
	OutwardUtil.ChangeFaceWhenCreate(cur_model, profId, index, callback)
end

local function ChangeHair(self, profId, index)
	local cur_selected = self._SceneGOTable[profId]
	if cur_selected == nil then 
		warn("can not find prof scene gameobject, profId == " .. profId)
		return
	end

	local cur_model = cur_selected._Model
	local function callback()
		--换脸之前换过发色了。要给人家设置回去！
		OutwardUtil.ChangeHairColor(cur_model, profId, self._HairColorId)	
	end 

	OutwardUtil.ChangeHairWhenCreate(cur_model, profId, index,callback)
end

local function ChangeSkinColor(self, profId, index)
	local curPlayer = self._SceneGOTable[profId]
	if curPlayer == nil then 
		warn("can not find prof scene gameobject, profId == " .. profId)
		return
	end

	local bodyModel = curPlayer._Model
	if IsNil(bodyModel) then
		warn("can not find body, profId == " .. profId)
		return
	end

	OutwardUtil.ChangeSkinColor(bodyModel, profId, index)
end

local function ChangeHairColor(self, profId, index)
	local curPlayer = self._SceneGOTable[profId]
	if curPlayer == nil then 
		warn("can not find prof scene gameobject, profId == " .. profId)
		return
	end

	local bodyModel = curPlayer._Model
	if IsNil(bodyModel) then
		warn("can not find body, profId == " .. profId)
		return
	end

	OutwardUtil.ChangeHairColor(bodyModel,profId, index)
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if string.find(id, "Rdo_Job_") and checked then
		-- 选择职业
		local profId = tonumber(string.sub(id, -1))
		if type(profId) ~= "number" then return end
		self:OnSelectRole(profId)
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
		if camType == nil or camType == self._CameraType then return end

		self:DoCameraMove(camType)
	else
		--以下逻辑为换脸用，如有上述条件，请在以上位置 添加elseif逻辑
		local index = tonumber(string.sub(id, -1))
		if type(index) ~= "number" then return end
		-- 切换脸，发型，肤色，发色
		local profId = self._CurProfId
		if string.find(id, "Rdo_FaceIcon_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_FaceIcon, self._FaceId)
				return
			end

			if index == self._FaceId then return end
			self._FaceId = index
			ChangeFace(self, profId, index)
		elseif string.find(id, "Rdo_HairIcon_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_HairIcon, self._HairId)
				return
			end

			if index == self._HairId then return end
			self._HairId = index
			ChangeHair(self, profId, index)
		elseif string.find(id, "Rdo_SkinColor_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_SkinColor, self._SkinColorId)
				return
			end

			if index == self._SkinColorId then return end
			self._SkinColorId = index
			ChangeSkinColor(self, profId, index)
		elseif string.find(id, "Rdo_HairColor_") and checked then
			if index > TEMP_LIMIT_NUM then
				TODO()
				GUI.SetGroupToggleOn(self._RdoGroup_HairColor, self._HairColorId)
				return
			end

			if index == self._HairColorId then return end
			self._HairColorId = index
			ChangeHairColor(self, profId, index)
		end
	end
end

--暂定上限为5次，假设超过5次，则随机一个数字(暂定)
local randomNameCount = 0
local roleRandomName = nil
--随机名字向服务器发送协议
def.method().GenerateRandomName = function(self)
	if randomNameCount <= 5 then
		roleRandomName = RandomNameGenerator.GenerateRandomName(self._CurProfId)
	else
		local min = GlobalDefinition.MinRoleNameLength
		local max = GlobalDefinition.MaxRoleNameLength
		if roleRandomName ~= nil then
			local curLength = GameUtil.GetStringLength(roleRandomName)
			if curLength >= max then
				local repeatCount = 0
				repeat
					repeatCount = repeatCount + 1
					if repeatCount > 10 then
						warn("GenerateRandomName TeraLucky")
						roleRandomName = "TeraLucky"
						curLength = GameUtil.GetStringLength(roleRandomName)
						break
					end
					roleRandomName = RandomNameGenerator.GenerateRandomName(self._CurProfId)
					curLength = GameUtil.GetStringLength(roleRandomName)
				until curLength < max
			end
		else
			warn("GenerateRandomName Tera")
			roleRandomName = "Tera"
		end
		min = GameUtil.GetStringLength(roleRandomName)
		local count = math.random(1, max - min)
		for i = 1, count do
			roleRandomName = roleRandomName .. math.random(0, 9) 
		end
	end
	C2SRandomName.name = roleRandomName
	PBHelper.Send(C2SRandomName)
	randomNameCount = randomNameCount + 1
end

--设置随机名字
def.method().SetRandomName = function(self)
	randomNameCount = 0
	if roleRandomName ~= nil then
		self._Input_PlayerName.text = roleRandomName
		roleRandomName = nil
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
def.method().InitUI = function(self)
	local index = self._CurProfId
	--根据选择角色，修改职业显示
	GUITools.SetGroupImg(self._Img_JobPower, index - 1)
	GUITools.SetGroupImg(self._Img_Flag, index - 1)
	--local prof_template = CElementData.GetProfessionTemplate(index)
	--if prof_template ~= nil then
		local text = StringTable.Get(50 + index)
		GUI.SetText(self._Lab_Desc, text)
		GUI.SetText(self._Lab_RaceName, GetRaceNameStr(index))
	--end

	for i = 1, TEMP_LIMIT_NUM do
		--设置肤色Image
		local path_id = OutwardUtil.Get(index, "SkinIconColor", i)
		local ColorConfig = require "Data.ColorConfig"
		local info = ColorConfig.GetColorInfo(path_id)
		local Skincolor = Color.New(info[1] / 255,info[2]/255,info[3]/255,1)
		GameUtil.SetImageColor(self._ImgTable_SkinColor[i],Skincolor)

		--设置发色Image
		path_id = OutwardUtil.Get(index, "HairIconColor", i)
		ColorConfig = require "Data.ColorConfig"
		info = ColorConfig.GetColorInfo(path_id)
		local HairColor = Color.New(info[1]/255,info[2]/255,info[3]/255,1)
		GameUtil.SetImageColor(self._ImgTable_HairColor[i],HairColor)

		--设置脸型
		local facePath = OutwardUtil.Get(index, "FaceIcon", i)
		GUITools.SetIcon(self._ImgTable_FaceStyle[i], facePath)

		--设置发型
		local hairPath = OutwardUtil.Get(index, "HairIcon", i)
		GUITools.SetIcon(self._ImgTable_HairStyle[i], hairPath)
	end
end

-- 检查玩家名字是否合法
def.method("=>", "boolean").CheckNameValid = function (self)
	local name = self._Input_PlayerName.text
	local len = GameUtil.GetStringLength(name)
	local min = GlobalDefinition.MinRoleNameLength
	local max = GlobalDefinition.MaxRoleNameLength

	if (IsNilOrEmptyString(name)) then
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.RoleNameIsNull)
		local message = ""
		if template == nil then
			message = "Unkownn message"
		else
			message = template.TextContent
		end
		
		local title = StringTable.Get(8)
		MsgBox.ShowSystemMsgBox(ServerMessageBase.RoleNameIsNull, message, title, MsgBoxType.MBBT_OK)

		return false
	end

	if(len < min or len > max) then
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.RoleNameLengthInvalid)
		local message = ""
		if template == nil then
			message = "Unkownn message"
		else
			message = template.TextContent
		end
		
		local title = StringTable.Get(8)
		MsgBox.ShowSystemMsgBox(ServerMessageBase.RoleNameLengthInvalid, message, title, MsgBoxType.MBBT_OK)

		return false
	end

	local FilterMgr = require "Utility.BadWordsFilter".Filter
	local strMsg = FilterMgr.FilterName(name)
	if (strMsg ~= name) then
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.NameInvalid)
		local message = ""
		if template == nil then
			message = "Unkownn message"
		else
			message = template.TextContent
		end
		
		local title = StringTable.Get(8)
		MsgBox.ShowSystemMsgBox(ServerMessageBase.NameInvalid, message, title, MsgBoxType.MBBT_OK)

		return false
	end

	return true
end

def.override("string").OnClick = function(self,id)
	if _G.ForbidTimerId ~= 0 then				--不允许输入
		return
	end

	if id == "Btn_RandomName" then
		self:GenerateRandomName()
	elseif id == "Btn_Confirm" then
		game:AddForbidTimer(self._ClickInterval)

		if self:CheckNameValid() then
			local function callback()
				if not self:IsShow() then return end

				local C2SRoleCreate = require "PB.net".C2SRoleCreate
				local protocol = C2SRoleCreate()
				
				protocol.Name = self._Input_PlayerName.text
				protocol.Profession = self._CurProfId
				protocol.Gender = Profession2Gender[self._CurProfId]
				protocol.Face.FacialId = self._FaceId
				protocol.Face.HairstyleId = self._HairId
				protocol.Face.SkinColorId = self._SkinColorId
				protocol.Face.HairColorId = self._HairColorId

				PBHelper.Send(protocol)
				-- 新建角色清空本地相机参数
				game:CleanCamParamsOfUserData()
				-- 平台SDK打点
				local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
				CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Create_Role)
			end
			StartScreenFade(0, 1, 0.5, callback)
		end
	elseif id == "Btn_Back" then
		game:AddForbidTimer(self._ClickInterval)

		--播放 CG的时候不让跳转，摄像机会有问题
		--if self._IsCgPlaying then return end
		CGMan.StopCG()
		
		--创角色界面返回选角色界面
		if self._PanelType == EPanelType.Job then
			-- CSoundMan.Instance():PlayBackgroundMusic(PATH.BGM_Login, 0)
			
			local role_list = game._AccountInfo._RoleList
			if #role_list <= 0 then
				-- 返回登录界面
				game:LogoutAccount()
				game:ReturnLoginStage()
			else
				game._GUIMan:Close("CPanelCreateRole")
				game:EnterRoleSelectStage(1)
			end
		elseif self._PanelType == EPanelType.Custom then
			--信息完善界面，返回创角色界面
			self._PanelType = EPanelType.Job

			-- 人物旋转
			local model = self._SceneGOTable[self._CurProfId]._Model
			GameUtil.EnableRotate(model, false)
			GUITools.DoLocalRotateQuaternion(model, Quaternion.Euler(0, 0, 0), self._ClickInterval, nil, nil)
			-- 人物外观
			self:ResetCreateRoleModel()
			-- 界面
			self:ShowJobInfo(false, self._ClickInterval, function ()
				GameUtil.EnableRotate(model, true)
			end)
			-- 相机
			if self._CameraType == ECameraType.Body then
				-- GameUtil.EnableBlockCanvas(true)
				StartScreenFade(0, 1, 0.1, function ()
					StartScreenFade(1, 0, 0.1, nil)
					local cameraAnimation = self._SceneGOTable[self._CurProfId]._CameraAnimation
					if not IsNil(cameraAnimation) then
						UnityUtil.PlayAnimation(cameraAnimation, "camerastay", 1)
					end
					local close_bg_on_gameobject = self._SceneGOTable[self._CurProfId]._CloseBGOn
					if not IsNil(close_bg_on_gameobject) then
						if close_bg_on_gameobject.activeSelf then
							close_bg_on_gameobject:SetActive(false)
						end
					end
					self._CameraType = ECameraType.Job
					-- GameUtil.EnableBlockCanvas(false)
				end)
			else
				self:DoCameraMove(ECameraType.Job)
			end
		end
	elseif id == "Btn_Next" then
		game:AddForbidTimer(self._ClickInterval)
		
		--播放 CG的时候不让跳转，摄像机会有问题
		if self._IsCgPlaying then return end

		self._PanelType = EPanelType.Custom
		self._CustomType = ECustomType.Face

		-- 人物旋转
		local model = self._SceneGOTable[self._CurProfId]._Model
		GameUtil.EnableRotate(model, false)
		GUITools.DoLocalRotateQuaternion(model, Quaternion.Euler(0, 0, 0), self._ClickInterval, nil, nil)
		-- 界面
		self:ResetToggleState()
		self:StartFrameJobTween(false, 1, function()
			if self._PanelType ~= EPanelType.Custom then return end

			GameUtil.EnableRotate(model, true)
			GUITools.SetUIActive(self._Frame_Custom, true)
			GUITools.SetUIActive(self._Frame_Custom_Face, true)
			GUITools.SetUIActive(self._Frame_Custom_Hair, false)
		end)
		self:DoCameraMove(ECameraType.Halfbody)
	elseif id == "Btn_Screen" then
		self._Btn_Skip:SetActive(true)
	elseif id == "Btn_Skip" then
		self._IsSkip = true
		
		local function callback()
			StartScreenFade(1, 0, 0.5,nil)

			self._IsSkip = false
			-- 界面
			self:ShowJobInfo(true, 0, nil)
			-- CG
			CGMan.StopCG()
			-- 动画
			local stopBGAnimation = self._SceneGOTable[self._CurProfId]._StopBGAnimation
			if not IsNil(stopBGAnimation) then
				UnityUtil.PlayAnimation(stopBGAnimation, self._BGIdleAniName[self._CurProfId], 1)
			end
			local cameraAnimation = self._SceneGOTable[self._CurProfId]._CameraAnimation
			if not IsNil(cameraAnimation) then
				UnityUtil.PlayAnimation(cameraAnimation, "camerastay", 1)
			end
			self:OnFinishCG()
			--停止技能音乐
			for i = 1, PROFESSION_NUM do
				CSoundMan.Instance():Stop2DAudio(self._SkillAudioPathCfg[i], "")
			end
		end
		StartScreenFade(0, 1, 0.5, callback)
	end
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

-- 重置创建模型
def.method().ResetCreateRoleModel = function(self)
 	self._FaceId = 1
 	self._HairId = 1
 	self._SkinColorId = 1
 	self._HairColorId = 1
 	local profId = self._CurProfId
	ChangeFace(self, profId, 1)
	ChangeHair(self, profId, 1)
	ChangeSkinColor(self, profId, 1)
	ChangeHairColor(self, profId, 1)
end

local function GetCamAniAndSpeed(curCamType, destCamType)
	local aniName = ""
	local speed = 0
	if curCamType ~= destCamType then
		local temp = curCamType * destCamType
		if temp == ECameraType.Body * ECameraType.Halfbody then
			aniName = "cameratostand"
			if curCamType < destCamType then
				-- 动画正向播放
				speed = 1
			else
				-- 反向
				speed = -1
			end
		elseif temp == ECameraType.Face * ECameraType.Halfbody then
			aniName = "cameratoface"
			if curCamType < destCamType then
				-- 动画反向播放
				speed = -1
			else
				-- 正向
				speed = 1
			end
		elseif temp == ECameraType.Face * ECameraType.Body then
			aniName = "camerafaceback"
			if curCamType < destCamType then
				-- 动画正向播放
				speed = 1
			else
				-- 反向
				speed = -1
			end
		elseif temp == ECameraType.Job * ECameraType.Halfbody then
			aniName = "cameragoclose"
			if curCamType < destCamType then
				-- 动画反向播放
				speed = -1
			else
				-- 正向
				speed = 1
			end
		elseif temp == ECameraType.Face * ECameraType.Job then
			aniName = "cameragoface"
			if curCamType < destCamType then
				-- 动画反向播放
				speed = -1
			else
				-- 正向
				speed = 1
			end
		end
	end
	return aniName, speed
end

def.method("number").DoCameraMove = function (self, destCamType)
	if destCamType == self._CameraType then return end

	local camRoot = self._SceneGOTable[self._CurProfId]._CameraAnimation
	if camRoot == nil then return end
	local camAni = camRoot:GetComponent(ClassType.Animation)
	if camAni == nil then return end

	local curCamType = self._CameraType
	local camAniName, speed = GetCamAniAndSpeed(curCamType, destCamType)
	if camAniName ~= "" then
		UnityUtil.PlayAnimation(camRoot, camAniName, speed)
		local cameraTime = camAni:GetClip(camAniName).length
		if cameraTime > 0 then
			if self._CameraAnimationTimer ~= 0 then
				_G.RemoveGlobalTimer(self._CameraAnimationTimer)
				self._CameraAnimationTimer = 0
			end
			self._CameraAnimationTimer = _G.AddGlobalTimer(cameraTime, true, function()
				GameUtil.EnableBlockCanvas(false)
			end)
			GameUtil.EnableBlockCanvas(true) -- 阻挡UI点击
		end
		self._CameraType = destCamType
	end

	self:CheckCloseBGShow(curCamType, destCamType)
end

-- 检查背景板的显示
def.method("number", "number").CheckCloseBGShow = function (self, curCamType, destCamType)
	if curCamType ~= ECameraType.Job and destCamType ~= ECameraType.Job then return end

	local close_bg_on_gameobject = self._SceneGOTable[self._CurProfId]._CloseBGOn
	local enable = destCamType ~= ECameraType.Job
	if enable then
		if not IsNil(close_bg_on_gameobject) then
			if not close_bg_on_gameobject.activeSelf then
				close_bg_on_gameobject:SetActive(true)
			end
		end
	else
		if not IsNil(close_bg_on_gameobject) then
			if close_bg_on_gameobject.activeSelf then
				close_bg_on_gameobject:SetActive(false)
			end
		end
		local close_bg_off_gameobject = self._SceneGOTable[self._CurProfId]._CloseBGOff
		if not IsNil(close_bg_off_gameobject) then
			if not close_bg_off_gameobject.activeSelf then
				close_bg_off_gameobject:SetActive(true)
			end
		end
		if self._CloseBGTimer ~= 0 then
			_G.RemoveGlobalTimer(self._CloseBGTimer)
			self._CloseBGTimer = 0
		end
		-- 延迟1s打开
		self._CloseBGTimer = _G.AddGlobalTimer(1, true, function ()
			if not IsNil(close_bg_off_gameobject) then
				if close_bg_off_gameobject.activeSelf then
					close_bg_off_gameobject:SetActive(false)
				end
			end
		end)
	end
end

-- 拖拽的相机响应
def.method("boolean").SetCustomMadeCamera = function(self, isZoomIn)
	--[[ 屏蔽拖拽
	if self._IsUIMove or self._IsCgPlaying or self._PanelType ~= EPanelType.Custom then return end

	local camRoot = self._SceneGOTable[self._CurProfId]._CameraAnimation
	if camRoot == nil then return end

	local destCamType = -1
	if isZoomIn then
		destCamType = self._CameraType + 1
	else
		destCamType = self._CameraType - 1
	end
	self:DoCameraMove(destCamType)
	--]]
end

def.override().OnDestroy = function(self)
	CGMan.StopCG()
	CSoundMan.Instance():StopBackgroundMusic()

	self._CGPathCfg = nil
	self._ModelPath = nil
	self._BGMPathCfg = nil
	self._BGAnimationPath = nil
	self._UI_TIME = nil
	self._BGIdleAniName  = nil

	if self._RandomAnimationTimer ~= 0 then
		_G.RemoveGlobalTimer(self._RandomAnimationTimer)
		self._RandomAnimationTimer = 0
	end
	if self._SelectRoleTimer ~= 0 then
		_G.RemoveGlobalTimer(self._SelectRoleTimer)
		self._SelectRoleTimer = 0
	end
	if self._CameraAnimationTimer ~= 0 then
		_G.RemoveGlobalTimer(self._CameraAnimationTimer)
		self._CameraAnimationTimer = 0
	end
	if self._CloseBGTimer ~= 0 then
		_G.RemoveGlobalTimer(self._CloseBGTimer)
		self._CloseBGTimer = 0
	end

	self._SceneGOTable = {}

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
	self._ImgTable_JobSelected = {}
	self._ImgTable_SkinColor = {}
	self._ImgTable_HairColor = {}
	self._ImgTable_FaceStyle = {}
	self._ImgTable_HairStyle = {}

	self._CurProfId = -1
	self._IsCgPlaying = false --是否CG播放中
	self._IsSkip  = false --是否跳过动画
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