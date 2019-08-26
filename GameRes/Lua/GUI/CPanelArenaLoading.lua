local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CUIModel = require "GUI.CUIModel"
local Util = require "Utility.Util"
local EMatchType = require "PB.net".EMatchType

local CPanelArenaLoading = Lplus.Extend(CPanelBase, "CPanelArenaLoading")
local def = CPanelArenaLoading.define

def.field("table")._BlackShows = nil           	--左方信息
def.field("table")._RedShows = nil           	--右方信息
def.field("number")._LoadWord_Timer = 0         --加载地图的计时器
def.field("number")._LoadTime = 0               --加载地图时间
def.field("number")._LoadRatio = 0              --加载地图进度
def.field("boolean")._IsFinishLoad = false		--完成地图加载
-- def.field("userdata")._Img_Loading = nil 
-- def.field("userdata")._SelfImg = nil            --自己的图框标志

def.field("number") ._3V3LoadingTimeSpecialId = 210                --加载等待的时间
def.field("number")._LoadingTime = 0

def.field("number")._CurArenaType = 0
def.field("userdata")._FrameBattle = nil 
def.field("userdata")._Frame3V3 = nil 
def.field("userdata")._ImgFront = nil 
def.field("userdata")._FrameContent = nil 
def.field("userdata")._LabPro = nil 
def.field("number")._BattleLoadingTimeSpecialId = 378
def.field("table")._3V3PlayerData = nil 
def.field("number")._PrefabDelayID = 0
def.field("userdata")._Frame3V3Content = nil 

local instance = nil
def.static("=>", CPanelArenaLoading).Instance = function()
    if not instance then
        instance = CPanelArenaLoading()
        instance._PrefabPath = PATH.UI_3v3_Loading
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
		instance._ForbidESC = true
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    -- self._SelfImg = self: GetUIObject("Image_self")
    --左边队伍
    -- self._Img_Loading = self:GetUIObject("Image_Loading")
    self._BlackShows = {}
    self._FrameBattle = self:GetUIObject("Frame_Battle")
    self._Frame3V3 = self:GetUIObject("Frame_3V3")
    self._ImgFront = self:GetUIObject("Img_Front"):GetComponent(ClassType.Image)
    self._LabPro = self:GetUIObject("Label_Pro")
    self._FrameContent = self:GetUIObject("Frame_Content")
    self._Frame3V3Content = self:GetUIObject("Frame_Mid")
    for  i = 0,2  do
        self._BlackShows[#self._BlackShows + 1] = 
        {
            _RoleID = 0,
            _item = self: GetUIObject("Img_Role"..i + 1),
            _levelImg = self:GetUIObject("Img_San"..i),
            _RoleImg = self:GetUIObject("Model_Member".. i + 1),
            _FightName =    self:GetUIObject("Lab_Name"..i) ,			
            _levelLab = self: GetUIObject("Lab_Level"..i), 
            _lab_Rdo = self:GetUIObject("Lab_Rdo"..i) ,
            _UIModel4ImgRender = nil,
            _ReadyLab = self:GetUIObject("Lab_Ready"..i),
            _PointGroup = self:GetUIObject("PointGroup"..i),
            _ImgLevelSan = self:GetUIObject("Img_Level"..i),
            _LabLevelSan = self:GetUIObject("Lab_SanLevel"..i)
            -- _RatioImg = self:GetUIObject("Slider"..i):GetComponent(ClassType.Slider),
            -- _ProfessionImg = self: GetUIObject("Img_JobSign"..i),
            -- _ImgHeadIcon = self:GetUIObject("Img_HeadIcon"..i),			
            -- _ImgBoard = self:GetUIObject("Img_Board"..i)
        }
    end
  --右边队伍
    self._RedShows = {}
     for i= 3,5 do
        self._RedShows[#self._RedShows + 1] = 
        {
            _RoleID = 0,
            _item = self: GetUIObject("Img_Role"..i + 1),
            _levelImg = self:GetUIObject("Img_San"..i),
            _RoleImg = self: GetUIObject("Model_Member"..i + 1),
            _FightName =  self:GetUIObject("Lab_Name"..i) ,
            _levelLab = self: GetUIObject("Lab_Level"..i),
            _lab_Rdo = self:GetUIObject("Lab_Rdo"..i),
            _ReadyLab = self:GetUIObject("Lab_Ready"..i),	
            _PointGroup = self:GetUIObject("PointGroup"..i),
            _ImgLevelSan = self:GetUIObject("Img_Level"..i),
            _LabLevelSan = self:GetUIObject("Lab_SanLevel"..i),
            _UIModel4ImgRender = nil,
            -- _ImgBoard = self:GetUIObject("Img_Board"..i)
            -- _ImgHeadIcon = self:GetUIObject("Img_HeadIcon"..i),
            -- _ProfessionImg = self: GetUIObject("Img_JobSign"..i),
            -- _RatioImg = self:GetUIObject("Slider"..i):GetComponent(ClassType.Slider),
        }
     end
end

local function SetPlayerShow(nType,index,PlayerInfo)
    if PlayerInfo == nil then return end
    local uiItem = nil
    if nType == 0 then
        uiItem = instance._BlackShows[index]
    else
        uiItem = instance._RedShows[index]
    end

    uiItem._RoleID = PlayerInfo.RoleId

    -- local professionTemplate = CElementData.GetProfessionTemplate(PlayerInfo.Profession)
    -- if professionTemplate == nil then
    -- 	warn("设置职业徽记时 读取模板错误：profession:", PlayerInfo.Profession)
    -- else
    -- 	GUITools.SetProfSymbolIcon(uiItem._ProfessionImg, professionTemplate.SymbolAtlasPath)
    -- end

    
    GUI.SetText(uiItem._levelLab, string.format(StringTable.Get(20053),PlayerInfo.Level))
   
    -- TeraFuncs.SetEntityCustomImg(uiItem._ImgHeadIcon,PlayerInfo.RoleId,PlayerInfo.Exterior.CustomImgSet,Profession2Gender[PlayerInfo.Profession],PlayerInfo.Profession)
    -- if game._HostPlayer._ID == PlayerInfo.RoleId then
    -- 	-- instance._SelfImg:SetParent(uiItem._item)
    -- 	instance._SelfImg.localPosition = Vector3.zero
    -- end

    --段位
    local DataTemp = CElementData.GetPVP3v3Template(PlayerInfo.Stage)
    GUITools.SetGroupImg(uiItem._levelImg,DataTemp.StageType - 1)
    if PlayerInfo.Stage == 16 then 
        uiItem._LabLevelSan:SetActive(true)
        GUI.SetText(uiItem._LabLevelSan,tostring(PlayerInfo.Star))
        uiItem._ImgLevelSan:SetActive(false)
    else
        uiItem._LabLevelSan:SetActive(false)
        uiItem._ImgLevelSan:SetActive(true)
        GUITools.SetGroupImg(uiItem._ImgLevelSan,DataTemp.StageLevel - 1)
    end
    local hostId = game._HostPlayer._ID
    --加载模型
    -- if hostId == PlayerInfo.RoleId then
    --     GUITools.SetGroupImg(uiItem._ImgBoard,1)
    -- else
    -- 	GUITools.SetGroupImg(uiItem._ImgBoard,0)
    -- end

    local ColorName = "<color=#FFFFFFFF>" ..PlayerInfo.Name.."</color>" 
    if hostId == PlayerInfo.RoleId then
        ColorName =  "<color=#ECBE33FF>" .. PlayerInfo.Name .."</color>" 
    end
    GUI.SetText(uiItem._FightName, ColorName)

    local profession = 1
    if uiItem._UIModel4ImgRender == nil then
        local model = nil
        if hostId == PlayerInfo.RoleID then
            model = GUITools.CreateHostUIModel(uiItem._RoleImg,  EnumDef.RenderLayer.UI, nil,EnumDef.UIModelShowType.NoWing)
            profession =  game._HostPlayer._InfoData._Prof
        else
            local ModelParams = require "Object.ModelParams"
            local params = ModelParams.new()
            params:MakeParam(PlayerInfo.Exterior, PlayerInfo.Profession)
            model = CUIModel.new(params, uiItem._RoleImg, EnumDef.UIModelShowType.NoWing, EnumDef.RenderLayer.UI, nil)
            profession = PlayerInfo.Profession
        end
        
        --uiItem._RoleImg:GetComponent(ClassType.GImageModel):SetLookAtParam(0.7,-1.37)

        uiItem._UIModel4ImgRender = model

        uiItem._UIModel4ImgRender:AddLoadedCallback(function() 
            uiItem._UIModel4ImgRender:SetModelParam(instance._PrefabPath, profession)
            end)
    end	
end 

local function C2SLoadWorldRatio(self,nRatio)
    local RoomId = 0
    local MatchType = 0
    local protocol = (require "PB.net".C2SMatchMapLoadingProgress)()
    if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 and game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get3V3WorldTID() then 
        MatchType = EMatchType.EMatchType_Arena
        RoomId = game._HostPlayer:Get3V3RoomID()
    elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle and game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:GetEliminateWorldTID() then
        MatchType = EMatchType.EMatchType_Eliminate
        RoomId = game._HostPlayer:GetEliminateRoomID()
    end
    if protocol == nil then return end
    protocol.MatchType = MatchType
    protocol.Progress = nRatio
    protocol.RoomId = RoomId
    PBHelper.Send(protocol)
end

def.override("dynamic").OnData = function(self, data)
    self._CurArenaType = data.CurArenaType
    if self._CurArenaType == EnumDef.OpenArenaType.Open3V3 then
        self._Frame3V3Content:SetActive(false)
        if self._PrefabDelayID ~= 0 then 
            _G.RemoveGlobalTimer(self._PrefabDelayID)
            self._PrefabDelayID = 0 
        end
        local time = 0
        local callback = function()
            time = time + 0.5
            if time == 1 then
                _G.RemoveGlobalTimer(self._PrefabDelayID)
                self._PrefabDelayID = 0
                self:Init3V3Panel(data.Info)
            end
        end
        self._PrefabDelayID = _G.AddGlobalTimer(0.5, false, callback)
        self._3V3PlayerData = data.Info
    elseif self._CurArenaType == EnumDef.OpenArenaType.OpenBattle then 
        self:InitBattlePanel()
    end
end

def.method("table").Init3V3Panel = function (self,data)
    self._Frame3V3:SetActive(true)
    self._FrameBattle:SetActive(false)
    self._Frame3V3Content:SetActive(true)
    self._LoadingTime = tonumber(CElementData.GetSpecialIdTemplate(self._3V3LoadingTimeSpecialId).Value)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena3V3Loading, 0) 
    -- local rotation = Vector3.New(0, 0, -180)
    -- local rotationTime = 0.5
    -- GameUtil.DoLoopRotate(self._Img_Loading, rotation, rotationTime)
    local idex = 1
    for _,v in ipairs(data.BlackList) do
        if v ~= nil then
            SetPlayerShow(0,idex,v)		
        end
        idex = idex + 1	
    end

    idex = 1
    for _,v in ipairs(data.RedList) do
        if v ~= nil then			
            SetPlayerShow(1,idex,v)		
        end	
        idex = idex + 1
    end

    if self._LoadWord_Timer ~= 0 then
        _G.RemoveGlobalTimer(self._LoadWord_Timer)
        self._LoadWord_Timer = 0
    end

	self._LoadRatio = 0
	self._IsFinishLoad = false
	C2SLoadWorldRatio(self,self._LoadRatio)
    self._LoadTime = 0
	-- local sendRatio = false --是否发送进度
	local callback = function()
		self._LoadTime = self._LoadTime + 0.5
		if self._IsFinishLoad and self._LoadTime >= self._LoadingTime - 2 then
			self._LoadRatio = 100
		else
			self._LoadRatio = self._LoadRatio + math.random(4, 10)
			self._LoadRatio = math.clamp(self._LoadRatio, 1, 95)
		end
		C2SLoadWorldRatio(self,self._LoadRatio)	
		if self._LoadRatio == 100 then
			if self._LoadWord_Timer ~= 0 then
				_G.RemoveGlobalTimer(self._LoadWord_Timer)
				self._LoadWord_Timer = 0
				return
			end
		end
	end
	self._LoadWord_Timer = _G.AddGlobalTimer(0.3, false, callback)
    do  --UI特效
        GameUtil.PlayUISfx(PATH.UIFX_JJC_3V3_LoadingFX, self._FrameContent, self._FrameContent, -1)
        local img_PointBlue = self:GetUIObject("EffectPoint1")
        local img_PointRed = self:GetUIObject("EffectPoint2")
        GameUtil.PlayUISfx(PATH.UIFX_JJC_3V3_LoadingBlue, img_PointBlue, img_PointBlue, -1)
        GameUtil.PlayUISfx(PATH.UIFX_JJC_3V3_LoadingRed, img_PointRed, img_PointRed, -1)
    end
end

def.method().InitBattlePanel = function (self)
    self._Frame3V3:SetActive(false)
    self._FrameBattle:SetActive(true)
    self._LoadingTime = tonumber(CElementData.GetSpecialIdTemplate(self._BattleLoadingTimeSpecialId).Value)

    if self._LoadWord_Timer ~= 0 then
        _G.RemoveGlobalTimer(self._LoadWord_Timer)
        self._LoadWord_Timer = 0
    end

	self._LoadRatio = 0
	self._IsFinishLoad = false
    self._LoadTime = 0
	local callback = function()
		self._LoadTime = self._LoadTime + 0.5
		if self._IsFinishLoad and self._LoadTime >= self._LoadingTime then
			self._LoadRatio = 100
		else
			self._LoadRatio = self._LoadRatio + math.random(4, 10)
			self._LoadRatio = math.clamp(self._LoadRatio, 1, 95)
		end
		C2SLoadWorldRatio(self,self._LoadRatio)	
		GUI.SetText(self._LabPro,self._LoadRatio..StringTable.Get(26003))
		self._ImgFront.fillAmount = self._LoadRatio / 100
		if self._LoadRatio >= 100 then
			if self._LoadWord_Timer ~= 0 then
				_G.RemoveGlobalTimer(self._LoadWord_Timer)
				self._LoadWord_Timer = 0
				return
			end
		end
	end
	self._LoadWord_Timer = _G.AddGlobalTimer(0.3, false, callback)
end

-- 3v3
def.method("number","number").ChangeLoadRatio = function(self,nPlayerID,nRatio)
    for _,v in ipairs(self._BlackShows) do
        if nil ~= v and v._RoleID == nPlayerID then
            -- v._RatioImg.value = nRatio / 100
            if nRatio < 100 then 
                GUI.SetText(v._lab_Rdo,nRatio.."%")
            else
                v._lab_Rdo:SetActive(false)
                v._ReadyLab:SetActive(true)
                v._PointGroup:SetActive(false)
            end
        end
    end
    for _,v in ipairs(self._RedShows) do
        if nil ~= v and v._RoleID == nPlayerID then
            -- v._RatioImg.value = nRatio / 100
            if nRatio < 100 then 
                GUI.SetText(v._lab_Rdo,nRatio.."%")
            else
                v._lab_Rdo:SetActive(false)
                v._ReadyLab:SetActive(true)
                v._PointGroup:SetActive(false)
            end
        end
    end
end

-- 主角完成地图加载后向服务器发送进度100 
def.method().LoadFinishWorld = function (self)
	self._IsFinishLoad = true
end

def.override().OnDestroy = function(self)
    if self._PrefabDelayID ~= 0 then 
        _G.RemoveGlobalTimer(self._PrefabDelayID)
        self._PrefabDelayID = 0 
    end
    if self._LoadWord_Timer ~= 0 then
        _G.RemoveGlobalTimer(self._LoadWord_Timer)
        self._LoadWord_Timer = 0
    end

    if self._BlackShows ~= nil then
        for _,v in ipairs(self._BlackShows) do
            if nil ~= v and nil ~= v._UIModel4ImgRender then
                v._UIModel4ImgRender:Destroy()
            end
        end
        self._BlackShows = nil
    end
    
    if self._RedShows ~= nil then
        for _,v in ipairs(self._RedShows) do
            if nil ~= v and nil ~= v._UIModel4ImgRender then
                v._UIModel4ImgRender:Destroy()
            end
        end	
        self._RedShows = nil
    end

    self._FrameBattle = nil
    self._Frame3V3 = nil
    self._ImgFront = nil
    self._LabPro = nil
    self._FrameContent = nil 
    self._Frame3V3Content = nil 
end

CPanelArenaLoading.Commit()
return CPanelArenaLoading