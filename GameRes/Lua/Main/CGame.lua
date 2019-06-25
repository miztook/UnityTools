local Lplus = require "Lplus"
local CWorld = require "Main.CWorld"

local CEventManager = require "Utility.AnonymousEvent".AnonymousEventManager
local CHostPlayer = require "Object.CHostPlayer"
local CElementData = require "Data.CElementData"
local CUIMan = require "GUI.CUIMan"
local CNetwork = require "Network.CNetwork"
local CAccountInfo = require "Main.CAccountInfo"
local EMatchType = require "PB.net".EMatchType
local CModel = require "Object.CModel"
local CDungeonMan = require "Dungeon.CDungeonMan"
local AchievementMan = require "Achievement.AchievementMan"
local DesignationMan = require "Designation.DesignationMan"
local CWorldBossMan = require "Main.CWorldBossMan"
local CGuideMan = require "Guide.CGuideMan"
local CManualMan = require "Manual.CManualMan"
local CFunctionMan = require "Guide.CFunctionMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CReputationMan = require "Reputation.CReputationMan"
local CNetAutomicMan = require "Main.CNetAutomicMan"
local CPanelRocker = require "GUI.CPanelRocker"
local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
local CPanelMinimap = require "GUI.CPanelMinimap"
local PBHelper = require "Network.PBHelper"
local UserData = require "Data.UserData".Instance()
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CAuctionUtil = require "Auction.CAuctionUtil"
local CPath = require "Path.CPath"
local CQuest = require "Quest.CQuest"
local CTransManage = require "Main.CTransManage"
local CTeamMan = require "Team.CTeamMan"
local CGuildMan = require "Guild.CGuildMan"
local CGameTipsQueue = require "GUI.CGameTipsQueue"
local CFriendMan = require "Main.CFriendMan"
local CArenaMan = require "Main.CArenaMan"
local CMallMan = require "Mall.CMallMan"
local CPanelDungeonEnd = require "GUI.CPanelDungeonEnd"
local CPanelLoading = require "GUI.CPanelLoading"
local CQuestNavigation = require "Quest.CQuestNavigation"
local CDecomposeAndSortMan = require "DecomposeFilter.CDecomposeAndSortMan"
local CRegionLimit = require "Main.CRegionLimit"
local CNPCServiceHdl = require "ObjHdl.CNPCServiceHdl"
local CDressMan = require "Dress.CDressMan"
local CWingsMan = require "Wings.CWingsMan"
local AdventureGuideMan = require "Main.AdventureGuideMan"
local CPlayerStrongMan = require "Main.CPlayerStrongMan"
local CExteriorMan = require "Main.CExteriorMan"
local MapChangeEvent = require "Events.MapChangeEvent"
local CCalendarMan = require "Main.CCalendarMan"
local CWelfareMan = require "Main.CWelfareMan"
local CNotificationMan = require "Main.CNotificationMan"
local CPanelUIBuffEnter = require "GUI.CPanelUIBuffEnter" 
local QualitySettingMan = require "Main.QualitySettingMan"
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
local CRoleSceneMan = require "RoleScene.CRoleSceneMan"

local CMiscSetting = require "Main.CMiscSetting"
--省电模式
local CPowerSavingMan = require "Main.CPowerSavingMan"

local CCountGroupMan = require "Main.CCountGroupMan"


local CGame = Lplus.Class("CGame")
local def = CGame.define

def.const(CEventManager).EventManager = CEventManager()

def.field("boolean")._IsOfflineGame = false
def.field(CAccountInfo)._AccountInfo = nil

def.field(CWorld)._CurWorld = nil 
def.field("userdata")._MainCamera = nil
def.field("userdata")._TopPateCamera = nil
def.field("userdata")._MainCameraComp = nil
def.field("number")._MainCameraCullingMask = 0
def.field("userdata")._PharseEffectGfx = nil

def.field("userdata")._TopPateCanvas = nil
def.field(CHostPlayer)._HostPlayer = nil
def.field(CUIMan)._GUIMan = nil
def.field("boolean")._IsUsingJoyStick = false
def.field(CNetwork)._NetMan = nil
def.field("table")._SceneTemplate = nil
def.field("boolean")._IsDebugMode = false

def.field(CMiscSetting)._MiscSetting = nil 		--游戏设置
def.field(CRoleSceneMan)._RoleSceneMan = nil 		--角色场景管理器
def.field(CPowerSavingMan)._CPowerSavingMan = nil		--省电模式
def.field(CGuildMan)._GuildMan = nil
def.field(CDungeonMan)._DungeonMan = nil 			--副本管理器
def.field(AchievementMan)._AcheivementMan = nil 	--成就管理器
def.field(DesignationMan)._DesignationMan = nil     --称号管理器
def.field(CWorldBossMan)._CWorldBossMan = nil 		--世界Boss管理器
def.field(CFunctionMan)._CFunctionMan = nil
def.field(CGuideMan)._CGuideMan = nil
def.field(CGameTipsQueue)._CGameTipsQ = nil     --游戏提示队列 升级等
def.field(CManualMan)._CManualMan = nil
def.field(CFriendMan)._CFriendMan = nil 
def.field(CArenaMan)._CArenaMan = nil 
def.field(CDecomposeAndSortMan)._CDecomposeAndSortMan = nil 
def.field(CReputationMan)._CReputationMan = nil
def.field(CNetAutomicMan)._CNetAutomicMan = nil
def.field(CAuctionUtil)._CAuctionUtil = nil
def.field(AdventureGuideMan)._AdventureGuideMan = nil 
def.field(CPlayerStrongMan)._PlayerStrongMan = nil --我要变强
def.field(CCalendarMan)._CCalendarMan = nil 	--冒险指南管理器
def.field(CWelfareMan)._CWelfareMan = nil 		--福利管理器
def.field(CCountGroupMan)._CCountGroupMan = nil 		--次数组管理器

def.field("boolean")._IsOpenDebugMode = false			--是否开启debug模式

def.field("boolean")._Is2InitEnterWorld = true

--断线重连
def.field("number")._ReconnectTime = 0		        -- 重连时间
def.field("boolean")._IsReEnter = false 	        -- 是否是重新登录
def.field("number")._ReConnectNum = 0		        -- 重连次数
def.field("boolean")._IsReconnecting = false	    -- 是否正在重连中

def.field("number")._CurMapType = 0

def.field("boolean")._IsSystemVoice = true          -- 是否是系统聊天
def.field("boolean")._IsSystemPlayVoice = true      -- 是否播放的系统聊天

def.field("number")._TargetMissDistanceSqr = 0      -- 目标解锁距离
def.field("boolean")._FirstEnterGame = true
def.field("boolean")._IsOpenPVECamLock = true       -- 是否开启PVE镜头锁定
def.field("boolean")._IsOpenPVPCamLock = true       -- 是否开启PVP镜头锁定
def.field("boolean")._IsOpenCamSkillRecover = true  -- 是否开启相机的技能自动回正
def.field("number")._CamLockEntityId = 0 			-- 相机战斗锁定视角的目标Id
def.field("boolean")._IsInNearCam = false 			-- 是否处于近景模式
def.field("boolean")._IsShowHeadInfo = true         -- 是否显示头顶信息
def.field("number")._MaxPlayersInScreen = 0         -- 最大同屏人数
def.field("number")._EnterPowerSaveSeconds = 0      -- 多久进入省点模式

def.field(CRegionLimit)._RegionLimit = nil		    -- 场景限制

-- 隐藏debug log FPS信息  false 打开  true 隐藏
def.field("boolean")._IsHideDebug = false
def.field("boolean")._IsHideLog = false
def.field("boolean")._IsHideFPS = false
def.field("boolean")._IsHideMallPages = false       -- 是否隐藏商城的Page（礼包商城，成长福利，蓝钻兑换）
def.field("boolean")._IsHideGuildBattle = false     -- 是否隐藏公会战场这个功能。
def.field("boolean")._IsHideUrlHelp 	= false     -- 是否隐藏UI帮助提示功能。
def.field("boolean")._IsHideHottime 	= false     -- 是否隐藏Hottime功能。
def.field("boolean")._IsHideAppMsgBox 	= false     -- 是否隐藏问卷弹窗功能。
def.field("boolean")._IsHideLancer = false          -- 是否隐藏枪骑士职业创建。

def.field("boolean")._AnotherDeviceLogined = false

def.field("number")._Ping = 0.0

def.field("number")._GCCount = 0

def.field("boolean")._IsGoldHottime = false
def.field("boolean")._IsExpHottime = false
def.field("number")._HottimeGoldItemTid = 0		        -- hottime金币增益Tid
def.field("number")._HottimeExpItemTid = 0		        -- hottime经验增益Tid

def.field("number")._CurSceneTid = 0			--实际地图加载完毕后的MapId
def.field("number")._CurMapId = 0			--实际地图加载完毕后的MapId
def.field("boolean")._IsLoggingOut = false
def.field('number')._AppMsgTimerId = 0				-- app弹窗Timer

local BEGINNER_DUNGEON_WORLD_TID = 1208 -- 新手副本地图id

_G.game = nil

def.static("=>", CGame).Instance = function()
	if _G.game == nil then
		_G.game = CGame()
	end

	return _G.game
end

local function DoAssetCacheCleanup(clearAll)
	-- loaded Sprite and AnimationClip asset cache in AssetBundleManager
	-- 定时清理 + OnLowMemory完全清理 + 切换场景完全清理
	-- 定时清理只保留最近2min内使用的AssetCache
	GameUtil.ClearAssetBundleCache(clearAll)  
	--fx 特效缓存
	--定时清理(清理时长与Cache数量相关) + 
	--OnLowMemory + 切换场景 除 主角特效 常驻特效外全部清理
	--定时清理，C# Tick检查，
	if clearAll then
		GameUtil.ClearFxManCache()
	end  
	-- 清理Lua层CModel引用到的资源，包括角色模型、武器、翅膀、怪物模型、NPC模型等
	-- 定时清理，C# Tick检查
	-- OnLowMemory完全清理 + 切换场景完全清理
	if clearAll then
		GameUtil.ClearEntityModelCache()
	end

	-- Unload Unused Assets and Call C# GC
	game:GC(true)
	-- lua collect garbage
	game:LuaGC()

	game._GCCount = 0
end

def.method().Init = function(self)
	--LogMemory("Lua Game Init Start")
	-- 系统级初始化

	--_G.AddGlobalTimer(1, false, function() QualitySettingMan.Instance():UpdateQualityLevel() end)

	do
		collectgarbage("setpause", 150)
		local seed = tostring(os.time()):reverse():sub(1, 7) --os.time()
		math.randomseed(seed)
		warn(("randomseed: 0x%08x"):format(seed))
		--math.randomseed = function () error("should not call randomseed when game running") end
	end

	_G.res_base_path = GameUtil.GetResourceBasePath()
	_G.document_path = GameUtil.GetDocumentPath()

	--读取存储的Userdata
	UserData:Init()
	QualitySettingMan.Instance():DecideQualityLevel()

    self._NetMan = CNetwork.new()
    self._NetMan:Init()

    _G.AddGlobalTimer(60, false, function()		
		self._GCCount = self._GCCount + 1
		if self._GCCount >= 3 then		--30×4 = 每3分钟调用一次 避免内存累加
			self._GCCount = 0
			DoAssetCacheCleanup(false)
		else
			self:LuaGC()	
		end
	end)

    --初始化声音，默认开启，以后服务器下发用户数据是否开启
	CSoundMan.Instance():Init(true, true)
    CMallMan.Instance():Init()
    CNotificationMan.Instance():Init()

    self._RoleSceneMan = CRoleSceneMan.new()

	self._MiscSetting = CMiscSetting.new()
	--省电模式
	self._CPowerSavingMan = CPowerSavingMan.new()

	self._GuildMan = CGuildMan.new()
	self._DungeonMan = CDungeonMan.new()			--数据和多语言无关，只加载一次
	self._AcheivementMan = AchievementMan.new()			--数据和多语言无关，只加载一次
	self._DesignationMan = DesignationMan.new()			--数据和多语言无关，只加载一次
	self._AdventureGuideMan = AdventureGuideMan.new()			
	self._PlayerStrongMan = CPlayerStrongMan.new() --我要变强。只初始化。不加载数据，不处理逻辑
	self._CWorldBossMan = CWorldBossMan.new()
	
	self._CFunctionMan = CFunctionMan.new()
	self._CGuideMan = CGuideMan.new()
	GameUtil.PassLuaGuideMan(self._CGuideMan)

	self._CGameTipsQ = CGameTipsQueue.Instance()

	self._CManualMan = CManualMan.new()
	self._CReputationMan = CReputationMan.new()
    self._CNetAutomicMan = CNetAutomicMan.new()
	self._CAuctionUtil = CAuctionUtil.new()	
	self._TopPateCanvas = GameObject.Find("TopPateCanvas")	
	self._RegionLimit = CRegionLimit.new()
	self._CFriendMan = CFriendMan.new()
	self._CCalendarMan = CCalendarMan.new()
	self._CArenaMan = CArenaMan.new()
	self._CWelfareMan = CWelfareMan.new()
	self._CDecomposeAndSortMan = CDecomposeAndSortMan.new()
	self._CCountGroupMan = CCountGroupMan.new()
end

--多语言相关
def.method().ReloadData = function (self)
	--加载init涉及的element data，在init时不加载data
	self._CGuideMan:LoadAllGuideData()
	self._CFunctionMan:LoadAllFunctionData()
	self._AdventureGuideMan:LoadAllAdventureGuideData()
	self._DungeonMan:LoadAllDungeonData()
	self._AcheivementMan:LoadAllAchievementData()
	self._CCalendarMan:LoadAllCalendarData()
	self._CWorldBossMan:LoadAllWorldBossData()
    self._CAuctionUtil:GetAllItemInfo()
	CTransManage.Instance():LoadAllTransTable()
end

def.method().Start = function (self)
	Application.backgroundLoadingPriority = EnumDef.ThreadPriority.Normal
	self:ReloadData()

	if self._GUIMan == nil then
	    self._GUIMan = CUIMan.new()
	    self._GUIMan:InitTopPate()
	end

	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.LOGIN)	
	self:HideDebug(self._IsHideDebug)
	self:HideLog(self._IsHideLog)
	self:HideFPSPing(self._IsHideFPS)

	self:PreloadAssets()
	--监听事件
	self:QuestRelatedInit()
	self._CGuideMan:Init()
	self._CGameTipsQ:Init()
	self._CFriendMan:Init()
    CTransManage.Instance():Init()
	--SDK初始化 开始登录流程
	CPlatformSDKMan.Instance():StartLoginFlow()

	CPath.Instance():Init()
	self._GuildMan:Init()
end

def.method().ClearScene = function(self)
	self._RoleSceneMan:CleanUp()
end

def.method("=>", "boolean").IsInGame = function (self)
	return self._MainCamera ~= nil
end

def.method().PreloadAssets = function(self)
	if IsNil(_G.ShadowTemplate) then
		GameUtil.AsyncLoad(PATH.Shadow, function(res)
                    if res ~= nil then
                        _G.ShadowTemplate = res
                    end
                end)

	end
	if IsNil(_G.PathArrowTemplate) then
		GameUtil.AsyncLoad( PATH.Gfx_PathArrow, function(res)
                    if res ~= nil then
                        _G.PathArrowTemplate = res
                    end
                end)
	
	end
end

def.method("number", "number", "string").SetCurrentMapInfo = function (self, sceneTid, mapId, nvmeshName)
	GameUtil.SetCurrentMapInfo(sceneTid, mapId, nvmeshName)
	self._CurSceneTid = sceneTid
	self._CurMapId = mapId
end

def.method("number").SetQualityLevel = function (self, lev)
	GameUtil.SetGFXRenderLevel(lev)
end

def.method("number").Tick = function(self, dt)
	CModel.UpdateLoadedResult(false)
end

def.method().LuaGC = function (self)
	_G.tempOutTable = {}	--清除全局缓存表

	collectgarbage("collect")
	printInfo(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
end

def.method("boolean").GC = function(self, unloadAssets)
	GameUtil.GC(unloadAssets)
end

def.method().CleanOnSceneChange = function (self)       --场景切换时的资源
	DoAssetCacheCleanup(true)
end

def.method().OnLowMemory = function (self)
	DoAssetCacheCleanup(true)
end

-- --首次进入游戏世界相关 new
def.method("table").CreateHostPlayer = function (self, info)	
	if self._HostPlayer == nil then
		self._HostPlayer = CHostPlayer.new()
	end
	self._HostPlayer._LoadedIsShow = false
	self._HostPlayer:Init(info)
	--Test
	--self._GUIMan:TestAllUI()

	-- 上传角色Id和名字
	GameUtil.ReportRoleInfo("ID: " .. tostring(self._HostPlayer._ID) .. " & Name: " .. tostring(self._HostPlayer._InfoData._Name))

	--初始化完角色, 初始化 IAP支付
	CPlatformSDKMan.Instance():InitIap(self._HostPlayer._ID)
end

def.method().PrepareForGameStart = function(self)
	self._CurWorld = CWorld.new()

	--首次进入游戏 隐藏头部信息
	self._TopPateCanvas:SetActive(false)
end

--头顶显示的隐藏关闭
def.method("boolean").SetTopPateVisible = function(self,isVisible)
	if not IsNil(self._TopPateCanvas) then
		self._TopPateCanvas: SetActive(isVisible)
	end
end

def.method().PlayPharseEffect = function(self)
	if self._PharseEffectGfx == nil then
		local gfx = GameUtil.RequestUncachedFx(PATH.Gfx_PharseEffect)
		gfx:SetParent(self._MainCamera, false)
		gfx.localPosition = Vector3.New(0, 0, 3) 
		self._PharseEffectGfx = gfx:GetComponent(ClassType.CFxOne)
	end

	self._PharseEffectGfx:Stop()
	self._PharseEffectGfx:Play(3)
end

def.method("number", "number").DoDungeonCheck = function(self, oldMapTid, newMapTid)
	local oldMapTemp = nil
	if oldMapTid ~= -1 then
		oldMapTemp = CElementData.GetMapTemplate(oldMapTid)
	end
	local newMapTemp = CElementData.GetMapTemplate(newMapTid)
	local CPanelTracker = require "GUI.CPanelTracker"
	local EWorldType = require "PB.Template".Map.EWorldType
	-- 从计时相位出来关闭结算
	if oldMapTemp ~= nil and oldMapTemp.WorldType == EWorldType.Immediate then
		self._GUIMan:Close("CPanelDungeonEnd")
	end
	if oldMapTemp ~= nil and oldMapTemp.WorldType == EWorldType.Instance then
		self._GUIMan:Close("CPanelDungeonEnd")
	    self._GUIMan:SetMainUIMoveToHide(false,nil)
		-- 从1v1 3v3 无畏战场出来 进到大世界 打来 CPanelUIBuffEnter 界面
		local isFromArena = oldMapTid == self._DungeonMan:Get1v1WorldTID() or oldMapTid == self._DungeonMan:Get3V3WorldTID() or oldMapTid == self._DungeonMan:GetEliminateWorldTID()
		if isFromArena and CPanelUIBuffEnter.Instance():IsShow() then 
			CPanelUIBuffEnter.Instance()._Panel:SetActive(true)
		end
		-- 断线重连后 地图是从306到306 
		if oldMapTid == self._DungeonMan:Get1v1WorldTID() and newMapTid ~= self._DungeonMan:Get1v1WorldTID() then
			self._GUIMan:Close("CPanelPVPHead")	
			CPanelTracker.Instance():ShowSelfPanel(true)
			local protocol = require "PB.net".C2SJJC1x1Info
			PBHelper.Send(protocol())
		end
		if oldMapTid == self._DungeonMan:Get3V3WorldTID() and newMapTid ~= self._DungeonMan:Get3V3WorldTID() then
            -- 打开svs
			self._GUIMan:Close("CPanelPVPHead")	
        	CPanelTracker.Instance():ShowSelfPanel(true)
			local protocol = (require "PB.net".C2SMatchDataReq)()
			protocol.MatchType = EMatchType.EMatchType_Arena
			PBHelper.Send(protocol)
		end	
		if oldMapTid == self._DungeonMan:GetEliminateWorldTID() and newMapTid ~= self._DungeonMan:GetEliminateWorldTID() then 
			self._GUIMan:Close("CPanelPVPHead")	
			local CPanelBattleMiddle = require"GUI.CPanelBattleMiddle"
			self._CArenaMan:OnOpenBattle()
			CPanelTracker.Instance():ShowSelfPanel(true)
			CPanelBattleMiddle.Instance():ClearRankData()
		end
		if oldMapTid == self._GuildMan:GetGuildBattleSceneTid() and newMapTid ~= self._GuildMan:GetGuildBattleSceneTid() then
			self._GUIMan:Close("CPanelUIGuildBattleResult")
			self._GUIMan:Close("CPanelUIBattleDamage")
			self._GUIMan:Close("CPanelUIGuildBattleMiniMap")			
			self._GUIMan:Open("CPanelMinimap", nil)
			self._GUIMan:Open("CPanelSystemEntrance", nil)
			self._GUIMan:SetNormalUIMoveToHide(false, 0, "", nil)
		end
	end
	--离开相位
	if oldMapTemp ~= nil and oldMapTemp.WorldType == EWorldType.Pharse then
		self:PlayPharseEffect()
	end
	--进入相位
	if newMapTemp ~= nil and newMapTemp.WorldType == EWorldType.Pharse then
		self:PlayPharseEffect()
	end
	-- 进入副本 关闭层级为3 和4 的界面（从获取途径进到副本功能）
	if newMapTemp ~= nil and newMapTemp.WorldType == EWorldType.Instance and newMapTid ~= self._DungeonMan:Get1v1WorldTID()  and 
		newMapTid ~= self._DungeonMan:GetEliminateWorldTID() and  newMapTid ~= self._DungeonMan:Get3V3WorldTID() then
		self._GUIMan:CloseSubPanelLayer()
	end
	-- 进入1v1 和3v3 无畏战场
	if newMapTid == self._DungeonMan:Get3V3WorldTID() or newMapTid == self._DungeonMan:Get1v1WorldTID() or newMapTid == self._DungeonMan:GetEliminateWorldTID() then 
		if CPanelUIBuffEnter.Instance():IsShow() then 
			CPanelUIBuffEnter.Instance()._Panel:SetActive(false)
		end
		self._GUIMan:Close("CPanelMinimap")
		self._GUIMan:Close("CPanelUIHead")
		self._GUIMan:Close("CPanelSystemEntrance")
		CPanelTracker.Instance():ShowSelfPanel(false)
	elseif newMapTid == self._GuildMan:GetGuildBattleSceneTid() then
		self._GUIMan:Close("CPanelMinimap")
		self._GUIMan:Close("CPanelSystemEntrance")		
		self._GUIMan:Open("CPanelUIGuildBattleMiniMap", nil)
	end
end

--首次进入游戏世界相关
def.method().FirstEnterGameWorld = function(self)	
	local CPanelHuangxinTest = require"GUI.CPanelHuangxinTest"
	CPanelHuangxinTest.Instance():OnFirstEnterGameWorld()

	self:ClearScene()

	self._HostPlayer:SetActive(true)
	self:CreateMainCamera()

	local profTemplate = self._HostPlayer._ProfessionTemplate
	if profTemplate ~= nil then
		GameUtil.SetProDefaultSpeed(profTemplate.MoveSpeed) -- 设置职业默认速度

		-- 设置相机视点高度
		local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
		if ModuleProfDiffConfig ~= nil then
			-- 跟随相机
			local heightOffsetMin, heightOffsetMax = ModuleProfDiffConfig.GetFollowCamViewPointHeightOffsetInterval(self._HostPlayer._InfoData._Prof, false)
			GameUtil.SetGameCamHeightOffsetInterval(heightOffsetMin, heightOffsetMax, true)
			local heightOffset = ModuleProfDiffConfig.GetCamViewPointDefaultHeightOffset(profTemplate.Id, false)
			GameUtil.SetGameCam2DHeightOffset(heightOffset)
			-- 读取近景相机配置
			GameUtil.ReadNearCameraProfConfig(self._HostPlayer._InfoData._Prof)
		end
	end

	self:SetCamParamsFromUserData()

	self._MiscSetting:UpdateHeadInfo()

	self._TopPateCanvas:SetActive(true)
    -- 初始化指示路径数据

	-- 请求所有时装数据
	CDressMan.Instance():RequestDressDataSync()
	-- 请求秘晶数据
	CWingsMan.Instance():C2SWingTalentView()
    -- 请求商城数据
    CMallMan.Instance():RequestMallRoleInfo()
    -- 请求副本匹配列表
    CPVEAutoMatch.Instance():SendC2SMatchList()
    -- 请求成就数据
    self._AcheivementMan:RequestAchieveDatas()
    -- 请求远征副本数据
    -- self._DungeonMan:SendAskExpeditionData()
end

def.method("number", "number","table", "table", "number").EnterGameWorld = function(self, mapTid, mapId, position, dir, cgId)
    GameUtil.EnableBackUICamera(false)  
	self._HostPlayer:OnJumpToNewPos()
	self._HostPlayer:Stand()--地图传送完毕站立，因为不stand的寻路状态，他会持续发送寻路链表中的点，导致服务器校验很容易失败，然后强制stopmove
	CPath.Instance():Hide()
	--LogMemory("EnterGameWorld begin")
	local oldMapTid = -1
	local curWorldInfo = self._CurWorld._WorldInfo
	if curWorldInfo.MapTid ~= nil then
		oldMapTid = curWorldInfo.MapTid
	end

	curWorldInfo.MapTid = mapTid
	local mapTemp = CElementData.GetMapTemplate(mapTid)
	local sceneTid = mapTemp.AssociatedMapId
	curWorldInfo.SceneTid = sceneTid
	curWorldInfo.MapId = mapId
	self._CurMapType = mapTemp.WorldType
	local MapBasicConfig = require "Data.MapBasicConfig"
	local nvmeshName = MapBasicConfig.GetNavmeshName(sceneTid)
	self:SetCurrentMapInfo(sceneTid, mapId, nvmeshName)

	local load_new_world = oldMapTid ~= mapTid
	local curWorld = self._CurWorld

	self._GUIMan:SetUIForbidList() -- 设置禁止打开的界面
	
	--local st = _G.MapBasicInfoTable[sceneTid]
	local st = MapBasicConfig.GetMapBasicConfigBySceneID(sceneTid)
	-- 且地图时存储好友数据(登陆游戏不需要存储)
	if not self._FirstEnterGame then 
		self._CFriendMan:SaveRecord()
	end

	if load_new_world then
		--首次进入游戏世界相关
		local isFirstEnterGame = self._FirstEnterGame
		if isFirstEnterGame then
			StartScreenFade(1, 0, 0.5)
			self:FirstEnterGameWorld()
			self._HostPlayer._LoadedIsShow = true
			self:SendC2SRankRewardGet()
			self._FirstEnterGame = false
		end
		
		-- 不同的场景Asset需要重新加载
		if self._SceneTemplate == nil or self._SceneTemplate.AssetPath ~= st.AssetPath then
			local function loadingCb()
				if curWorld ~= nil then
					curWorld:Release(true, false)
				end
				self._Is2InitEnterWorld = true
				local function callback( p )
					local function _on_host_loaded(hp)
						if self._Is2InitEnterWorld  then					
							self._HostPlayer:Stand()				
						end

	 					self._Is2InitEnterWorld = false
						self._HostPlayer:SetPos(position)
						self._HostPlayer:SetDir(dir)

						local function _on_all_ready()
							--更新高度，这时的高度才正确
							--self._HostPlayer:SetPos(position)
							self._HostPlayer:SetDir(dir)							
							GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
							self:OnHostPlayerPosChange(position)

							local isCGFinish, isLoadingClose = true, false
							local function showPromotion()
								if not isCGFinish or not isLoadingClose then return end
								-- 打开Promotion
								CPlatformSDKMan.Instance():ShowPromotion(function(deepLinkUrl)
									-- TODO:处理DeepLink
									warn("ShowPromotion callback deepLinkUrl:", deepLinkUrl)
								end)
							end

							if oldMapTid == BEGINNER_DUNGEON_WORLD_TID then
								-- 从新手本出来，播放特定CG by 杨宗翰
								local function cbFinish()
									isCGFinish = true
									showPromotion()
								end
								isCGFinish = false
								local firstWorldCGId = 32
								CGMan.PlayCG(firstWorldCGId, cbFinish, 1, false)
							elseif cgId > 0 then
								CGMan.PlayCG(cgId, nil, 1, false)
							end
						
							-- if oldMapTid ~= self._DungeonMan:Get1v1WorldTID() and oldMapTid ~= self._DungeonMan:Get3V3WorldTID() then
							-- 	-- self._GUIMan:Close("CPanelMirrorArena")
							-- end

							--self._GUIMan:Close("CPanelLoading")
							local function showMapInfo()
								self:ShowEnterMapImg(mapTid, oldMapTid)
								self._PlayerStrongMan:CheckShowPlayerStrong()
								isLoadingClose = true
								if mapTid ~= BEGINNER_DUNGEON_WORLD_TID and isFirstEnterGame then
									-- 第一次进入世界而且不是新手本，或者从新手本出来
									showPromotion()
								end
							end

							CPanelLoading.Instance():AttemptCloseLoading(showMapInfo)
							if self._DungeonMan:Get3V3WorldTID() == mapTid or self._DungeonMan:GetEliminateWorldTID() == mapTid then
								local CPanelArenaLoading = require"GUI.CPanelArenaLoading"
								if CPanelArenaLoading.Instance():IsShow() then
									CPanelArenaLoading.Instance():LoadFinishWorld()
								end
							end

							self._GUIMan:Open("CPanelUIHead",nil)
							self._GUIMan:Open("CPanelSkillSlot", nil)
							self._GUIMan:Open("CPanelRocker",nil)
							self._GUIMan:Open("CPanelTracker",nil)
							self._GUIMan:Open("CPanelMainTips",nil)
							self._GUIMan:Open("CPanelMainTipsLow",nil)
							self._GUIMan:Open("CPanelMainChat",nil)
							self._GUIMan:Open("CPanelOperationTips",nil)
							self._GUIMan:Open("CPanelMinimap", nil)
							self._GUIMan:Open("CPanelUIQuickUse",nil)
							self._GUIMan:Open("CPanelSystemEntrance",nil)
							self._GUIMan:Open("CPanelChatNew", 1)
							self._GUIMan:Open("CPanelUIBuffEnter",nil)
							self._CDecomposeAndSortMan:GetUserData()
							CAutoFightMan.Instance():Restart(_G.PauseMask.WorldLoading)
							--省电模式
                            self._CPowerSavingMan:SetSleepingTime(self._EnterPowerSaveSeconds)
							self._CPowerSavingMan:StartPlaying()
							self:DoDungeonCheck(oldMapTid, mapTid)
							self:FinishEnterWorld()

							CSoundMan.Instance():ChangeBackgroundMusic(0)
							CSoundMan.Instance():ChangeEnvironmentMusic(0)

							self._NetMan:SetProtocolPaused(false)
						end
						GameUtil.LoadSceneBlocks(position.x, position.z, _on_all_ready)
					end
					
					self._HostPlayer:AddLoadedCallback(_on_host_loaded)
					--CSoundMan.Instance():ChangeBackgroundMusic(0)
					--CSoundMan.Instance():ChangeEnvironmentMusic(0)
					--LogMemory("EnterGameWorld host_loaded")
				end
				CAutoFightMan.Instance():Pause(_G.PauseMask.WorldLoading)
				--省电模式
				self._CPowerSavingMan:StopPlaying()

				self._NetMan:SetProtocolPaused(true)
				self:LoadWorld(st, sceneTid, callback)
			end
			
			if self._DungeonMan:Get1v1WorldTID() ~= mapTid and self._DungeonMan:Get3V3WorldTID() ~= mapTid and self._DungeonMan:GetEliminateWorldTID() ~= mapTid then
				self._GUIMan:Open("CPanelLoading",{BGResPathId = mapTid})
				--self._NetMan:SetProtocolPaused(true)
			elseif self._DungeonMan:Get1v1WorldTID() == mapTid or self._DungeonMan:Get3V3WorldTID() == mapTid or self._DungeonMan:GetEliminateWorldTID() == mapTid then
 				
			end
			loadingCb()
		else
			local function enter()
				self._Is2InitEnterWorld = false
				self._HostPlayer:Stand()
				--self._HostPlayer:SetPos(position)

				self._HostPlayer:SetDir(dir)

				self:OnHostPlayerPosChange(position)

				if cgId > 0 then
					CGMan.PlayCG(cgId, nil, 1, false)
				end
				self._SceneTemplate = st
				self:ShowEnterMapImg(mapTid, oldMapTid)
				self:DoDungeonCheck(oldMapTid, mapTid)
				self:FinishEnterWorld()
			end

			local dis = Vector3.DistanceH(self._HostPlayer:GetPos(), position)
			if dis > 0.01 then
				self._NetMan:SetProtocolPaused(true)
				StartScreenFade(0, 1, 0.5, function()
						enter()
						GameUtil.SetCamToDefault(true, false, false, true)
						StartScreenFade(1, 0, 0.5, nil)
						self._NetMan:SetProtocolPaused(false)
					end)
			else
				enter()
			end
		end
	else
		if self._IsReEnter then
			self._GUIMan:Open("CPanelLoading",{BGResPathId = mapTid})
			--self._NetMan:SetProtocolPaused(true)

			self:ClearScene()
			local function callback( p )
				if cgId > 0 then
					CGMan.PlayCG(cgId, nil, 1, false)
				end
				self._GUIMan:Close("CPanelMirrorArena")		
				--self._GUIMan:Close("CPanelLoading")	
				local function showMapInfo()
					self:ShowEnterMapImg(mapTid, oldMapTid)
				end
				CPanelLoading.Instance():AttemptCloseLoading(showMapInfo)		
				self._HostPlayer:Stand()

				--self._HostPlayer:SetPos(position)
				self._HostPlayer:SetDir(dir)
				
				self:OnHostPlayerPosChange(position)

				self:DoDungeonCheck(oldMapTid, mapTid)
				self:FinishEnterWorld()

				self._NetMan:SetProtocolPaused(false)
			end
			self._NetMan:SetProtocolPaused(true)
			self:LoadWorld(st, sceneTid, callback)
		else
			local function enter()
				self._HostPlayer:Stand()
				--self._HostPlayer:SetPos(position)
				self._HostPlayer:SetDir(dir)

				self:OnHostPlayerPosChange(position)

				self._SceneTemplate = st
				if cgId > 0 then
					CGMan.PlayCG(cgId, nil, 1, false)
				end
				self:ShowEnterMapImg(mapTid, oldMapTid)
				self:DoDungeonCheck(oldMapTid, mapTid)
				self:FinishEnterWorld()
			end

			local dis = Vector3.DistanceH(self._HostPlayer:GetPos(), position)
			if dis > 0.01 then
				self._NetMan:SetProtocolPaused(true)
				StartScreenFade(0, 1, 0.5, function()
						enter()
						GameUtil.SetCamToDefault(true, false, false, true)
						StartScreenFade(1, 0, 0.5, nil)
						self._NetMan:SetProtocolPaused(false)
					end)
			else
				enter()
			end
		end
	end

	--self:DoDungeonCheck(oldMapTid, mapTid)
	self:UpdateTargetMissDistance()

	self._ReConnectNum = 0
	self._IsReEnter = false

	local CPanelMinimap = require "GUI.CPanelMinimap"
	if CPanelMinimap.Instance():IsShow() then
		CPanelMinimap.Instance():SetExitBtnState()
	end

	self._CurWorld._NPCMan:ClearNPCAnimationList()
	--warn("EnterGameWorld End")
	--LogMemory("EnterGameWorld End")
end

--在HostPlayer位置改变时，需要加载collider，然后重新设置高度
def.method("table").OnHostPlayerPosChange = function (self, position)
	self._HostPlayer:SetPos(position)  -- 这个好像是多余的

	GameUtil.OnHostPlayerPosChange(position.x, position.z)
	GameUtil.SetCamToDefault(true, false, false, true)

	--有些情况如1v1,3v3，在加载地图前就加载entity了，因此在地图加载后要刷新一下高度
	if self._CurWorld ~= nil then
		self._CurWorld._PlayerMan:UpdateAllHeight()
		self._CurWorld._NPCMan:UpdateAllHeight()
		--self._CurWorld._MineObjectMan:UpdateAllHeight()
		--self._CurWorld._DynObjectMan:UpdateAllHeight()
		self._CurWorld._PetMan:UpdateAllHeight()

		local sceneTid = self._CurWorld._WorldInfo.SceneTid
	   	if sceneTid == self._CurSceneTid then
	   		self:CleanOnSceneChange()
	   	end
	end
end

def.method("number", "table").SetMapLineInfo = function(self, lineId, allLines)
	local curWorldInfo = self._CurWorld._WorldInfo
	curWorldInfo.CurMapLineId = lineId
	curWorldInfo.ValidLineIds = allLines
	
	-- 刷新当前所在分线
	local CPanelMinimap = require "GUI.CPanelMinimap"
	if CPanelMinimap.Instance():IsShow() then
		CPanelMinimap.Instance():UpdateArrayLineList()
	end

	local CPanelUIArrayLine = require "GUI.CPanelUIArrayLine"
	if CPanelUIArrayLine.Instance():IsShow() then
		CPanelUIArrayLine.Instance():UpdateArrayLineInfo()
	end
end

def.method().UpdateTargetMissDistance = function (self)
	local mapId = self._CurWorld._WorldInfo.MapTid
	local map = CElementData.GetMapTemplate(mapId)
	local d = 0
	if map ~= nil and map.UnlockSightRange ~= 0 then
		d = map.UnlockSightRange
	else
		d = tonumber(CElementData.GetSpecialIdTemplate(1).Value)
	end
	self._TargetMissDistanceSqr = d * d
end

--进入场景。显示场景图片
def.method("number", "number").ShowEnterMapImg = function(self, mapTid, nOldMapID)
    CTransManage.Instance():ContinueTrans()
	local cMap = require "GUI.CPanelMap"
    if(cMap.Instance():IsShow()) and not CTransManage.Instance():IsTransState() then	
    	cMap.Instance(): ClosePanel()
    elseif (cMap.Instance():IsShow()) and CTransManage.Instance():IsTransState() then
    	self._GUIMan:Open("CPanelMap",nil)
    end
	local MapBasicConfig = require "Data.MapBasicConfig"
	local EWorldType = require "PB.Template".Map.EWorldType
	--if self._CurMapType == EWorldType.Pharse then return end	

	if nOldMapID > 0 then
		local oldMapType =  MapBasicConfig.GetMapType(nOldMapID)
		-- 如果之前地图是相位。不显示地图img
		if oldMapType == EWorldType.Pharse then return end	
	end

	local data = {_type = 1, _Id = mapTid}
--	local CPanelEnterMapTips = require "GUI.CPanelEnterMapTips"
--	CPanelEnterMapTips.Instance():ShowEnterTips(data)
	self._CGameTipsQ:ShowMapTip(data)

	-- 加载场景完毕，需要判断一下是不是3V3的加载完毕，告诉服务器拉人
	-- if self._HostPlayer:In3V3Fight() and self._CurWorld._WorldInfo.MapTid == self._DungeonMan:Get3V3WorldTID() then	
	-- 	local C3V3LoadingPanel = require "GUI.CPanelArenaLoading"
	-- 	if C3V3LoadingPanel.Instance():IsShow() then
	-- 		C3V3LoadingPanel.Instance():LoadFinishWorld()
	-- 	end 
	-- end
end

--进入地图完成，包含加载回调和同地图进入完成
def.method().FinishEnterWorld = function(self)	
	--传送门降落
	-- self._GUIMan:Close("CPanelArenaLoading")
	--跨地图，清除技能组
	self._HostPlayer:CancelCachedAction()
	
	local goals = self._DungeonMan:GetDungeonGoal()
	--self._DungeonMan:ClearDungeonGoal()
	local CPanelTracker = require "GUI.CPanelTracker"
	CPanelTracker.Instance():OpenDungeonUI(goals~=nil)	

	-- 检查上马状态
	self._HostPlayer:CheckMountState()

	--重置待机状态
	self._HostPlayer:SetPauseIdleState(false)

	GameUtil.OnFinishEnterWorld()
	
	-- 重置血条信息
	self._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.HPLine)
end

def.method("boolean").TryEnableHawkEyeMode = function (self, enable)
	local protocol = (require "PB.net".C2SHawkeye)()
	protocol.enable = enable
	PBHelper.Send(protocol)
end

def.method().CreateMainCamera = function (self)
	local cam_go = GameObject.New("Main Camera")
	cam_go.tag = "MainCamera"
	local cam = cam_go:AddComponent(ClassType.Camera)
    cam.nearClipPlane = 0.1
    cam.farClipPlane = 2500
    cam.fieldOfView = 60
    cam.backgroundColor = Color.New(32/255, 32/255, 54/255, 5/255)
    cam.depth = -1
    cam.useOcclusionCulling = false
    
    --cam_go:AddComponent(ClassType.GUILayer)

    local cullDistances = {}
    for i=1, 32 do cullDistances[i] = 0 end
    
    cullDistances[5] = 300       -- water
    cullDistances[10] = 500      -- building
    cullDistances[11] = 60       -- player
    --cullDistances[12] = 100       -- npc
    --cullDistances[15] = 200000   -- Background
    --cullDistances[17] = 200000   -- HostPlayer

    --cullDistances[18] = 50       -- EntityAttacked
    --cullDistances[19] = 50      -- Fx
    --cullDistances[26] = 50       -- toppate 头顶字

    cam.layerCullDistances = cullDistances
    -- cam.layerCullSpherical = true

    self._MainCameraComp = cam
	self._MainCamera = GameObject.New("MainCameraRoot")
	--self._MainCamera:AddComponent(ClassType.GUILayer)
	self._MainCamera.rotation = Quaternion.Euler(GameConfig.Get("view_angle"), 0, 0)


	cam_go:SetParent(self._MainCamera, false)

	--Camera topPate 头顶字
	local cam_tp_go = GameObject.New("TopPateCamera")
	cam_tp_go:SetParent(cam_go, false)
	self._TopPateCamera = cam_tp_go:AddComponent(ClassType.Camera)

	local cullDistances_tp = {}
	for i=1, 32 do cullDistances_tp[i] = 0 end
	cullDistances_tp[26] = 50       -- toppate
	self._TopPateCamera.layerCullDistances = cullDistances_tp

	self._TopPateCamera.depth = self._MainCameraComp.depth + 1

	--LogMemory("CreateMainCamera End")

	GameUtil.OnMainCameraCreate()

	--refresh character level
	local level = QualitySettingMan.Instance():GetCharacterLevel()
	QualitySettingMan.Instance():SetCharacterLevel(level)
	QualitySettingMan.Instance():ApplyChanges()
end

def.method().DestroyMainCamera = function (self)
	if self._MainCamera ~= nil then
		self._MainCameraComp = nil
		GameUtil.OnMainCameraDestroy()
		GameObject.Destroy(self._MainCamera)
		self._MainCamera = nil
		self._TopPateCamera = nil

		--refresh character level
		local level = QualitySettingMan.Instance():GetCharacterLevel()
		QualitySettingMan.Instance():SetCharacterLevel(level)
		QualitySettingMan.Instance():ApplyChanges()
	
		self._PharseEffectGfx = nil
	end
end

def.method("boolean").EnableMainCamera = function (self, enable)
	GameUtil.EnableMainCamera(enable)
end

--初始化或更改技能信息，暂定
def.method("table").InitHostPlayerSkill = function(self, skills)
	self._HostPlayer._UserSkillMap = skills
	self._HostPlayer._SkillHdl:HostSkillGfxPreload()
    self._HostPlayer._MainSkillLearnState = {}
	for k,v in pairs(skills) do
		self._HostPlayer._MainSkillLearnState[v.SkillId] = true
	end
end  

def.method("table", "number", "function").LoadWorld = function(self, template, sceneTid, cb)
	self._SceneTemplate = template
	
	Application.backgroundLoadingPriority = EnumDef.ThreadPriority.High
	self._CurWorld:Load(template.AssetPath, function (...)
		if cb then
			cb(...)
			Application.backgroundLoadingPriority = EnumDef.ThreadPriority.Normal
		end
	end)
    --LogMemory("LoadWorld End")
end

def.method("table").OnClickGround = function (self, pos)
	local hp = self._HostPlayer
    if not hp._IsClickGroundMove then return end
	if hp._SkillHdl:IsApproachingTarget() then
		hp._SkillHdl:CancelSkill()
	end

	hp:StopAutoLogic()
	CAutoFightMan.Instance():Pause(_G.PauseMask.ManualControl)	
	CQuestAutoMan.Instance():Stop()	
	CDungeonAutoMan.Instance():Stop()

	local function ResetAuto()
		hp:StopNaviCal()	
		-- 从任务模式切换到世界模式
		CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
		CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
	end
	hp:Move(pos, 0, ResetAuto, ResetAuto)
	CFxMan.Instance():OnClickGround(pos)
end

local click_event = nil
def.method("dynamic").RaiseNotifyClickEvent = function(self, obj)
	if click_event == nil then
		local NotifyClick = require "Events.NotifyClick"
    	click_event = NotifyClick()
    end
    click_event._Param = obj
    CGame.EventManager:raiseEvent(nil, click_event)
end

local uiShortcutEvent = nil
def.method("number","table").RaiseUIShortCutEvent = function (self, type, data)
	if uiShortcutEvent == nil then
		local NotifyClick = require "Events.UIShortCutEvent"
    	uiShortcutEvent = NotifyClick()
    end
    uiShortcutEvent._Type = type
    uiShortcutEvent._Data = data
    CGame.EventManager:raiseEvent(nil, uiShortcutEvent)
end

def.method().Release = function(self)
	self:SaveUserDataToFile()

	if self._HostPlayer ~= nil then
		self._HostPlayer:HalfRelease()
	end
	if self._CurWorld ~= nil then
		self._CurWorld:Release(true, true)
		self._CurWorld = nil
	end
	if self._HostPlayer ~= nil then
		self._HostPlayer:Release()
		self._HostPlayer = nil
	end
	
	self:RaiseQuitGameEvent()
	self._AnotherDeviceLogined = false
end

def.method().SaveUserDataToFile = function(self)
	if not self._FirstEnterGame then
		--保存配置
		self:SaveCamParamsToUserData()
		self:SaveGameConfigToUserData()
		self:SaveLoginRoleConfigToUserData()
		self:SaveOperationUnLockFXData()
		self:SaveBagItemToUserData()
		self._CFriendMan:SaveRecord()
		self._CDecomposeAndSortMan:SaveRecord()
	end
	UserData:SaveDataToFile()
end

def.method().RaiseQuitGameEvent = function(self)
	local ApplicationQuitEvent = require "Events.ApplicationQuitEvent"
    local event = ApplicationQuitEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

def.method().RaiseDisconnectEvent = function(self)
	local DisconnectEvent = require "Events.DisconnectEvent"
    local event = DisconnectEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

def.method().RaiseConnectEvent = function(self)
    local ConnectEvent = require "Events.ConnectEvent"
    local event = ConnectEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

def.method("string").DebugString = function (self, str)
	local spaceSet = "[%s%,]"
	local notSpaceSet = "[^%s%,]"
	
	local cmds = {}
	local i = 1
	for w in string.gmatch(str, notSpaceSet.."+") do
		cmds[i] = w
		i = i + 1
	end
	
	local count = #cmds
	
	if count == 0 then
		return
	end
	
	local cmd_type = string.lower(cmds[1])
	local debugModel = require "Main.DebugCmds"
	if debugModel[cmd_type] ~= nil then
		debugModel[cmd_type](cmds)
	else
		FlashTip("unknown debug cmd" , "tip", 2)
		warn("unknown debug cmd")
	end
end

def.method().StartTestScene = function(self)
	self:CreateMainCamera()
	self._MainCamera.position = Vector3.New(383, 127,  269)
	GameUtil.AsyncLoadByPathID(635, function(mapres)
			if mapres ~= nil then
				local scene = Object.Instantiate(mapres)
			end
		end)
end


def.method("number", "number").OnJoystickPressEvent = function (self, x, y)
	local hp = self._HostPlayer
	local is_draging = (x ~= 0 or y ~= 0)
	self._IsUsingJoyStick = is_draging
	if hp == nil then return end
	if hp:IsInExterior() then return end

	if is_draging then
		hp:Move(nil, 0, nil, nil)
		CPanelRocker.Instance():HideUIByDrag(true)
		self._CGuideMan:MoveGuide(false)
		hp:StopAutoLogic()
		CQuestAutoMan.Instance():Stop()	
		CDungeonAutoMan.Instance():Stop()
		CAutoFightMan.Instance():Pause(_G.PauseMask.ManualControl)
        MenuList.Close()
	else
		hp:OnJoystickDragEnd()
		CPanelRocker.Instance():HideUIByDrag(false)
		self._CGuideMan:MoveGuide(true)		
		CAutoFightMan.Instance():Restart(_G.PauseMask.ManualControl)
		CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
	end
end

local CachedLogs = {}
local MaxCacheHalfCount = 10
def.method("string").OnUnityLog = function (self, log)
	--if string.length(log) > 256 then return end

	if #CachedLogs >= MaxCacheHalfCount * 2 then
		-- 超出上限时，清除一半
		for i = 1, MaxCacheHalfCount do
			CachedLogs[i] = CachedLogs[#CachedLogs - MaxCacheHalfCount + i]
		end
		for i = #CachedLogs, MaxCacheHalfCount+1, -1 do
			CachedLogs[i] = nil
		end
	end

	CachedLogs[#CachedLogs+1] = log

	local PanelDebug = require "GUI.CPanelDebug".Instance()
	if PanelDebug:IsShow() then
		PanelDebug:OnSyncLog(log)
	end
end

def.method("=>", "table").GetLogs = function (self)
	return CachedLogs
end

local server_time_gap = 0 --本地时间与服务器时间的间隔

-- 移动中带有时间戳，服务器会校对时间戳，如果异常，强制同步时间
def.method("number").UpdateServerTime = function(self, server_time)	
	server_time_gap = GameUtil.GetClientTime() - server_time
	GameUtil.SetServerTimeGap(server_time_gap)
end

local ping_label_obj = nil
def.method("number").UpdatePing = function(self, serverTime)
	if IsNil(ping_label_obj) then
		ping_label_obj = GameObject.Find("UIRootCanvas/Panel_FPS/PING")
	end

	local gap = GameUtil.GetClientTime() - serverTime
	self._Ping = tonumber(string.format("%0.2f", gap))

	if not IsNil(ping_label_obj) then
		local pingtext = string.format("%0.2fms", gap)
		GUI.SetText(ping_label_obj, pingtext)
	end
end

def.method("number", "number", "function").AddReconnectTimer = function(self, interval, timeout, cb)
	--warn("AddReconnectTimer!!!")

	if _G.ReconnectTimerId == 0 then
		local callback = function()
			cb(self, timeout)
		end
		_G.ReconnectTimerId = _G.AddGlobalTimer(interval, false, callback)

	end
end

def.method().CancelReconnectTimer = function(self)
	if _G.ReconnectTimerId ~= 0 then
		_G.RemoveGlobalTimer(_G.ReconnectTimerId)
		_G.ReconnectTimerId = 0
		self._ReconnectTime = 0
	end
end

def.method("number").AddForbidTimer = function(self, interval)
	if _G.ForbidTimerId == 0 then
		local callback = function()
			self:CancelForbidTimer()
		end
		_G.ForbidTimerId = _G.AddGlobalTimer(interval, true, callback)
	end
end

def.method().CancelForbidTimer = function(self)
	if _G.ForbidTimerId ~= 0 then
		_G.RemoveGlobalTimer(_G.ForbidTimerId)
		_G.ForbidTimerId = 0
	end
end

def.method().QuestRelatedInit = function(self)
	CQuest.Instance():Init()

	--初始化任务追踪界面
	local CPageQuest = require "GUI.CPageQuest"
	CPageQuest.Instance():Init()
end

def.method().QuestRelatedRelease = function(self)
	CQuest.Instance():Release()

	local CQuestAutoGather = require "Quest.CQuestAutoGather"
	CQuestAutoGather.Instance():Stop()
	
	--初始化任务追踪界面
	local CPageQuest = require "GUI.CPageQuest"
	CPageQuest.Instance():Release()
end

-- App弹窗接口 param1:TriggerTag param2:ID 
def.method("number", "number").OnAppMsgBoxStatic = function (self, TriggerTag, ConditionId)
	local AppMsgBoxTable = _G.AppMsgBoxTable
	if AppMsgBoxTable == nil then return end

	if self._AppMsgTimerId > 0 then
		_G.RemoveGlobalTimer(self._AppMsgTimerId)
		self._AppMsgTimerId = 0
	end

	-- 屏蔽商店评分功能   lidaming
	for i,v in pairs(AppMsgBoxTable) do
		if v.TriggerConditions == TriggerTag then
			local QualificationTable = {}
			string.gsub(v.Qualification, '[^*]+', function(w) table.insert(QualificationTable, w) end )
			for _,k in pairs(QualificationTable) do
				if tonumber(k) == ConditionId then
					local account = self._NetMan._UserName
					local accountInfo = UserData:GetCfg(EnumDef.LocalFields.AppMsgBox, account)
					if accountInfo == nil then
						accountInfo = {}
					end
					local serverName = self._NetMan._ServerName
					if accountInfo[serverName] == nil then
						accountInfo[serverName] = {}
					end
					local roleId = self._HostPlayer._ID
					if accountInfo[serverName][roleId] == nil then
						accountInfo[serverName][roleId] = {}
					end
					local AppMsgBoxOpenTime = accountInfo[self._NetMan._ServerName][self._HostPlayer._ID].AppMsgBoxOpenTime
					if AppMsgBoxOpenTime == nil or AppMsgBoxOpenTime <= 0 then
						-- warn("lidaming OOOOOOOOOOOOOOOOOOOOOOO AppMsgBoxOpenTime ==", os.time(), AppMsgBoxOpenTime)
						local data = {
							AppMsgBoxOpenTime = os.time(),
						}
						accountInfo[serverName][roleId] = data
						UserData:SetCfg(EnumDef.LocalFields.AppMsgBox, account, accountInfo)

						local life_time = v.SecondDelay
						self._AppMsgTimerId = _G.AddGlobalTimer(1, false, function()
							life_time = life_time - 1
							if life_time == 0 then
								local param = {}
								param.TriggerTag = TriggerTag	
								param.ConditionId = ConditionId
								param.AppMsgBoxCfg = v
								self._GUIMan:Open("CPanelUIAppMsgBox", param)
								_G.RemoveGlobalTimer(self._AppMsgTimerId)
							end
						end)		
					else
						if (os.time() - AppMsgBoxOpenTime) > (tonumber(v.DayDelay) * 86400) then
							local data = {
								AppMsgBoxOpenTime = os.time(),
							}
							accountInfo[serverName][roleId] = data
							UserData:SetCfg(EnumDef.LocalFields.AppMsgBox, account, accountInfo)



							local life_time = v.SecondDelay
							self._AppMsgTimerId = _G.AddGlobalTimer(1, false, function()
								life_time = life_time - 1
								if life_time == 0 then
									local param = {}
									param.TriggerTag = TriggerTag	
									param.ConditionId = ConditionId
									param.AppMsgBoxCfg = v
									self._GUIMan:Open("CPanelUIAppMsgBox", param)
									_G.RemoveGlobalTimer(self._AppMsgTimerId)
								end
							end)							
						end
					end
                end
            end
		end
	end
	
end

-- 游戏内重连 逻辑清理，重连之前
def.method().OnReconnectReset = function (self)
	--清除entity
    if self._CurWorld ~= nil then
		--清除队伍信息
		CTeamMan.Instance():Reset()
    	self._CurWorld:Release(false, false)
    end

	if self._HostPlayer ~= nil then
		self._HostPlayer:Reset()
    end

    self._RegionLimit:Clear()		--场景限制

    local CPate = require "GUI.CPate".CPateBase
    CPate.Clear()

    -- 清除界面
    self._GUIMan:Close("CPanelMirrorArena")
    self._GUIMan:Close("CPanelMate")
    self._GUIMan:Close("CPanelArenaLoading")
end

-- 游戏逻辑处理，在游戏内重连成功之后
def.method().OnReconnectSucceed = function (self)
	-- body
	local CPageQuest = require "GUI.CPageQuest"
    CPageQuest.Instance():Update()
end

def.method().StopAllAutoSystems = function (self)
	CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
	if self._HostPlayer ~= nil then
		self._HostPlayer:StopAutoLogic()
	end
end

def.method("boolean").CleanUpGameResources = function(self, bReturnLogin)
	warn("CleanUpGameResources!!!")

	--关闭TargetDector的timer
	if self._HostPlayer ~= nil then
		local CTargetDetector = require "ObjHdl.CTargetDetector"
		CTargetDetector.Instance():Clear()
	end

	--清除停止CG并CG缓存
	CGMan.Release()

	--清除任务模块的消息响应
	self:QuestRelatedRelease()

	--清除guide消息响应
	self._CGuideMan:Release()
	
	self._GuildMan:Release()

	--清除游戏提示队列
	self._CGameTipsQ:Release()

	--清除寻路模块响应
	CTransManage.Instance():Release()

	--清除副本信息
	self._DungeonMan:Release()
	CDungeonAutoMan.Instance():Release()
	--清除称号数据
	self._DesignationMan:Release()

	--清除我要变强信息
	self._PlayerStrongMan:Release()

	--清除成就数据
	self._AcheivementMan:Release()

	--清除队伍信息
	CTeamMan.Instance():Release()

	--清除福利数据
	self._CWelfareMan:Release()

	self._CFriendMan:Release()

	self._CArenaMan:Release()

	self._CDecomposeAndSortMan:Release()

    self._CAuctionUtil:Release()

	self._CReputationMan:Release()

    self._CNetAutomicMan:Release()

	-- 清除计时器
	CPVPAutoMatch.Instance():Stop()

	-- 清除计时器
	CPath.Instance():CleanPathAndData()
	-- 清除登陆选角色场景
	self:ClearScene()
	
	self:StopAllAutoSystems()

	--省电模式
	self._CPowerSavingMan:CleanUp()

	CQuestNavigation.Instance():Release()
	-- 清除HostPlayer大世界的一些信息
	if self._HostPlayer ~= nil then
		self._HostPlayer:HalfRelease()
	end

	CNPCServiceHdl.Clear()

	CExteriorMan.Instance():Reset()
	-- 清除时装信息
	CDressMan.Instance():Clear()
	-- 清除翅膀信息
	CWingsMan.Instance():Clear()
	-- 清除数据
	CPanelSkillSlot.Instance():Clear()
    -- 清除商城数据
    CMallMan.Instance():Release()
    -- 清除副本匹配数据
    CPVEAutoMatch.Instance():Release()
    -- 清除消息提示数据
    CNotificationMan.Instance():Release()
    -- 清除MsgBox的不再显示缓存
    MsgBox.RemoveAllBoxes()

	--删除world
	if self._CurWorld ~= nil then
		if self._CurWorld:GetCurScene() ~= nil then
			self._CurWorld:Release(true, true)
		else
			self._CurWorld:Release(false, true)
		end
	end
	self._CurWorld = nil 
	self._SceneTemplate = nil

	-- for debug
	--local EntityStatis = require "Profiler.CEntityStatistics"
	--EntityStatis.Clear()

	self._GUIMan:CloseCircle()
	MsgBox.CloseAll()
	self._GUIMan:Clear()

	self:DestroyMainCamera()

	if self._HostPlayer ~= nil then
		self._HostPlayer:Release()
		self._HostPlayer = nil --清除HostPlayer
	end
	
	if bReturnLogin then
		CSoundMan.Instance():Reset()
	end

	CRedDotMan.ClearRedTabelState()

	--清理所有资源
	GameUtil.SetCameraGreyOrNot(false) -- 重置镜头灰度
	GameUtil.ResetLogReporter()

	--下次进入游戏一定还会加载的资源，无需清理
	--GameUtil.ClearHUDTextFontCache()
	--GameUtil.ClearAllEmoji()

	CFxMan.Instance():Reset()
	DoAssetCacheCleanup(true)

	if self._AppMsgTimerId > 0 then
		_G.RemoveGlobalTimer(self._AppMsgTimerId)
		self._AppMsgTimerId = 0 
	end

	self._FirstEnterGame = true			--重新初始化
end

def.method().CloseConnection = function (self)
	_G.canSendPing = false
	_G.canAutoReconnect = false

	self._GUIMan:CloseCircle()
	self._NetMan:Close()
	self:CancelReconnectTimer()

	self._AnotherDeviceLogined = false
end

def.method("number").SendSelectRole = function (self, roleId)
	local C2SRoleSelect = require "PB.net".C2SRoleSelect
	local protocol = C2SRoleSelect()
	protocol.RoleId = roleId
	PBHelper.Send(protocol)
	-- 平台SDK打点
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Role_Login)
end

def.method().LogoutRole = function (self)
	self._IsLoggingOut = true
	local C2SLogoutRole = require "PB.net".C2SLogoutRole
	local protocol = C2SLogoutRole()
	PBHelper.Send(protocol)
end

def.method().LogoutAccount = function (self)
	self._IsLoggingOut = true

	local C2SLogoutAccount = require "PB.net".C2SLogoutAccount
	local protocol = C2SLogoutAccount()
	PBHelper.Send(protocol)

	local UserData = require "Data.UserData".Instance()
	UserData:SetCfg(EnumDef.LocalFields.LastUseAccount, "AccountToken", "")
	UserData:SaveDataToFile()
end

def.method().ReturnLoginStage = function(self)
	self._ReConnectNum = 0	
	self._IsReEnter = true
	self._IsReconnecting = false

	CGame.EventManager:clearAll()
	
	if not self._FirstEnterGame then
		self:SaveCamParamsToUserData()
		self:SaveGameConfigToUserData()
		self:SaveLoginRoleConfigToUserData()	 -- 保存角色信息
		self:SaveBagItemToUserData()
		self._CFriendMan:SaveRecord()
	end

	--关闭连接
	self:CloseConnection()

	GameUtil.EnableBackUICamera(true)			--隐藏黑色背景
	self:CleanUpGameResources(true)

	if self._AccountInfo ~= nil then
		self._AccountInfo:Clear()
		self._AccountInfo = nil
	end

	--if _G.IsLanguageChanged() then
		_G.ResetLanguage()
		_G.PreLoadDataManagers()
	--end

	self:ReloadData()

	self._GUIMan:InitTopPate()

	--CGame.EventManager:printStats()

	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.LOGIN)
	self:HideDebug(self._IsHideDebug)
	self:HideLog(self._IsHideLog)
	self:HideFPSPing(self._IsHideFPS)

	--重新监听事件
	self:QuestRelatedInit()
	self._CGuideMan:Init()
	self._CGameTipsQ:Init()
	CTransManage.Instance():Init()
    CMallMan.Instance():Init()
    CNotificationMan.Instance():Init()
	self._CFriendMan:Init()
	--重新开始登录流程
	CPlatformSDKMan.Instance():RestartLoginFlow()

	self._IsLoggingOut = false
end

def.method().ReturnSelectRole = function (self)
	CGame.EventManager:clearAll()
	
	if not self._FirstEnterGame then
		self:SaveCamParamsToUserData()
		self:SaveGameConfigToUserData()
		self:SaveLoginRoleConfigToUserData()	 -- 保存角色信息
	end

	GameUtil.EnableBackUICamera(true)			--隐藏黑色背景
	self:CleanUpGameResources(false)

	self:ReloadData()

	--CGame.EventManager:printStats()

	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.LOGIN)
	self:HideDebug(self._IsHideDebug)
	self:HideLog(self._IsHideLog)
	self:HideFPSPing(self._IsHideFPS)
	--重新监听事件
	self:QuestRelatedInit()
	self._CGuideMan:Init()
	self._CGameTipsQ:Init()
	CTransManage.Instance():Init()
    CMallMan.Instance():Init()
    CNotificationMan.Instance():Init()
	self._CFriendMan:Init()

	--登录，开始角色选择
	local CLoginMan = require "Main.CLoginMan"
	CLoginMan.Instance():SetQuickEnterRoleId(0)
	CLoginMan.Instance():OnAccountInfoSet(0)

	_G.canSendPing = true
	_G.canAutoReconnect = true
	
	self._IsLoggingOut = false
end

def.method().ResetConnection = function(self)
	self._ReConnectNum = 0	
	self._IsReEnter = true
	self._IsReconnecting = false

	--关闭连接
	self:CloseConnection()
end

local AutoReconnectCallback = function (self, timeout)
	local bCancel = false

	self._ReconnectTime = self._ReconnectTime + 1

	if self._NetMan._GameSession:IsConnected() then
		self._GUIMan:CloseCircle()
		self._IsReconnecting = false

		MsgBox.CloseAll()
		self:CancelReconnectTimer()
		bCancel = true

		self._GUIMan:ShowTipText(StringTable.Get(14004), false)
		StartScreenFade(0.3, 0, 0.5, nil)

		self:OnReconnectSucceed()

	elseif self._ReconnectTime <= timeout then
	    --发送重连请求
		self._NetMan:ReConnect()

		warn("Reconnecting...", self._NetMan._IP, self._NetMan._Port)

	else  --超时仍未连接成功

		self._IsReconnecting = false

		self:CancelReconnectTimer()				--重连超时，停止连接
		bCancel = true
		StartScreenFade(0.3, 0, 0.5, nil)

		--断线重新登录
		local callback = function(value)
			if value then
				self:ReConnect()
			else
				self:ReturnLoginStage()
			end
			_G.MsgBoxDisconnectShow = false
		end

		self._GUIMan:CloseCircle()
		MsgBox.CloseAll()

		local ServerMessageBase = require "PB.data".ServerMessageBase
		local CElementData = require "Data.CElementData"
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.Disconnected)
		local title = ""
		local message = ""
		if template == nil then
			title = "提示"			
			message = "网络断开连接"
		else
			title = template.Title
			message = template.TextContent
		end

		_G.MsgBoxDisconnectShow = true
		MsgBox.ShowSystemMsgBox(ServerMessageBase.Disconnected, message, title, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Disconnect)

	end

	return bCancel
end

def.method().AutoReconnect = function (self)
	self:CancelReconnectTimer()

	if self._NetMan._GameSession:IsConnected() then return end

	--重连提示
	self._GUIMan:CloseCircle()
	MsgBox.CloseAll()

--重连时间计时,如果取消不再重连
	self._GUIMan:ShowCircle(StringTable.Get(14001), true)
	self._IsReconnecting = true

	self:OnReconnectReset()

	self:AddReconnectTimer(2, 8, AutoReconnectCallback)
	StartScreenFade(0, 0.3, 0.5, nil)
end

local ReconnectCallback = function(self, timeout)
	local bCancel = false

	self._ReconnectTime = self._ReconnectTime + 1

	if self._NetMan._GameSession:IsConnected() then
		self._GUIMan:CloseCircle()
		self._IsReconnecting = false

		MsgBox.CloseAll()
		self:CancelReconnectTimer()
		bCancel = true

		self._GUIMan:ShowTipText(StringTable.Get(14004), false)
		StartScreenFade(0.3, 0, 0.5, nil)

		self:OnReconnectSucceed()
		
	elseif self._ReconnectTime <= timeout then
	    --发送重连请求
		self._NetMan:ReConnect()

	else  --超时仍未连接成功
		self._IsReconnecting = false

		self._GUIMan:CloseCircle()
		MsgBox.CloseAll()
		self:CancelReconnectTimer()				--重连超时，停止连接
		StartScreenFade(0.3, 0, 0.5, nil)

		--如果超时还没连接，弹框
		_G.MsgBoxDisconnectShow = true
		local title, msg, closeType = StringTable.GetMsg(51)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, 
			function(value) 
				self:ReturnLoginStage() 
				_G.MsgBoxDisconnectShow = false
			end, nil, nil, MsgBoxPriority.Disconnect)
	end							
	
	return bCancel
end

def.method().ReConnect = function(self)
	self._ReConnectNum = self._ReConnectNum + 1	

	self:CancelReconnectTimer()

	--重连提示
	self._GUIMan:CloseCircle()
	MsgBox.CloseAll()
	--MsgBox.ShowMsgBox(StringTable.Get(14001), StringTable.Get(14000), MsgBoxType.MBBT_OK, function(val) MsgBox.CloseAll() end, nil, nil, MsgBoxPriority.Disconnect)
	
	--重连时间计时,如果取消不再重连
	self._GUIMan:ShowCircle(StringTable.Get(14001), true)
	self._IsReconnecting = true

	self:OnReconnectReset()

	local bCancelTimer = ReconnectCallback(self, 10)
	if not bCancelTimer then
		self:AddReconnectTimer(3, 10, ReconnectCallback)
		StartScreenFade(0, 0.3, 0.5, nil)
	else
		self._GUIMan:CloseCircle()
		MsgBox.CloseAll()
	end
end

def.method("=>", "table").GetCurWorldInfo = function(self)
	if self._CurWorld == nil then return nil end
	return self._CurWorld._WorldInfo
end

def.method("=>", "boolean").IsInBeginnerDungeon = function(self)
	if self._CurWorld == nil then return false end
	return (self._CurWorld._WorldInfo.MapTid == BEGINNER_DUNGEON_WORLD_TID)
end

def.method("=>", "dynamic").GetCurMapTemp = function(self)
 	if self._CurWorld == nil then return nil end
 	
    if self._CurWorld._WorldInfo.MapTid then
        local CElementData = require "Data.CElementData"
        local mapTemp = CElementData.GetMapTemplate(self._CurWorld._WorldInfo.MapTid)
        if mapTemp then
            return mapTemp
        end
    end
    return nil
end

-- 当前场景禁止自动战斗
def.method("=>", "boolean").IsCurMapForbidDrug = function(self)
    local temp = self:GetCurMapTemp()
    if temp then
        return temp.ForbidUseBlood
    end
    return false
end

-- 当前场景禁止自动战斗
def.method("=>", "boolean").IsCurMapForbidAutofight = function(self)
    local temp = self:GetCurMapTemp()
    if temp then
        return temp.ForbidAutoFight
    end
    return false
end

_G.DPG =
{
	KillEnemy = 0,    -- 战斗杀敌
	AchieveGoals = 1,  -- 完成副本目标
}
-- 当前副本目标优先选项
def.method("=>", "number").GetCurDungeonPreferedGoal = function(self)
    if self:GetCurMapAutoFightType() == AFT.DungeonGoal then
	    local temp = self:GetCurMapTemp()
	    
	    if temp then
	        return temp.DungeonGoalPri
	    end
	end
    return -1
end

--0任务目标, 1副本目标, 2无目标
_G.AFT =
{
	QuestGoal = 0,
	DungeonGoal = 1,
	None = 2,
}
def.method("=>", "number").GetCurMapAutoFightType = function(self)
	local temp = self:GetCurMapTemp()
    if temp then
        return temp.AutoFightType
    end

    return -1
end

-- 摄像机相关
def.method().SetCamParamsFromUserData = function(self)
	local mode = UserData:GetField(EnumDef.LocalFields.CameraCtrlMode)
	if mode == nil then
		mode = GameUtil.GetGameCamCtrlMode()
	end
	GameUtil.SetGameCamCtrlMode(mode, true, true, true, true)

	if mode ~= EnumDef.CameraCtrlMode.FIX25D then
		local dist = UserData:GetField(EnumDef.LocalFields.CameraDistance) 
		if dist ~= nil and dist > 0 then
			GameUtil.SetGameCamDestDistOffset(dist, true)
		end
	end

	-- Boss锁定视角
	local pve_lock_state = UserData:GetField(EnumDef.LocalFields.CameraPVELock)
	if pve_lock_state == nil then
		-- 默认开启
		self._IsOpenPVECamLock = true
	else
		self._IsOpenPVECamLock = pve_lock_state
	end
	-- PVP锁定视角
	local pvp_lock_state = UserData:GetField(EnumDef.LocalFields.CameraPVPLock)
	if pvp_lock_state == nil then
		-- 默认开启
		self._IsOpenPVPCamLock = true
	else
		self._IsOpenPVPCamLock = pvp_lock_state
	end
	-- 相机的技能自动回正
	local recover_state = UserData:GetField(EnumDef.LocalFields.CameraSkillRecover)
	if recover_state == nil then
		-- 默认开启(cuifenggong  韩服默认生效，国内要求默认不生效)
		self._IsOpenCamSkillRecover = true
	else
		self._IsOpenCamSkillRecover = recover_state
	end
    local is_show_head_info = UserData:GetField(EnumDef.LocalFields.IsShowHeadInfo)
    if is_show_head_info == nil then
        self._IsShowHeadInfo = true
    else
        self._IsShowHeadInfo = false
    end
    local max_person_num = UserData:GetField(EnumDef.LocalFields.ManPlayersInScreen)
    if max_person_num == nil then
        self._MaxPlayersInScreen = _G.MAX_VISIBLE_PLAYER
    else
        self._MaxPlayersInScreen = max_person_num
    end
    local seconds = UserData:GetField(EnumDef.LocalFields.PowerSavingTime)
    if seconds == nil then
        self._EnterPowerSaveSeconds = 0
    else
        self._EnterPowerSaveSeconds = seconds
    end
end

def.method().SaveCamParamsToUserData = function(self)
	local mode = GameUtil.GetGameCamCtrlMode()
	local dist = GameUtil.GetGameCamDestDistOffset()
	UserData:SetField(EnumDef.LocalFields.CameraCtrlMode, mode)
	UserData:SetField(EnumDef.LocalFields.CameraDistance, dist)
	UserData:SetField(EnumDef.LocalFields.CameraPVELock, self._IsOpenPVECamLock)
	UserData:SetField(EnumDef.LocalFields.CameraPVPLock, self._IsOpenPVPCamLock)
	UserData:SetField(EnumDef.LocalFields.CameraSkillRecover, self._IsOpenCamSkillRecover)
end

-- 清空相机参数相关本地数据
def.method().CleanCamParamsOfUserData = function(self)
	UserData:CleanField(EnumDef.LocalFields.CameraCtrlMode)
	UserData:CleanField(EnumDef.LocalFields.CameraDistance)
	UserData:CleanField(EnumDef.LocalFields.CameraPVELock)
	UserData:CleanField(EnumDef.LocalFields.CameraPVPLock)
	UserData:CleanField(EnumDef.LocalFields.CameraSkillRecover)
end

def.method().SaveGameConfigToUserData = function (self)
	QualitySettingMan.Instance():SaveQualityConfigToUserData()
	self._MiscSetting:SaveToUserData()
	self._CPowerSavingMan:SaveToUserData()
    UserData:SetField(EnumDef.LocalFields.IsShowHeadInfo, self._IsShowHeadInfo)
    UserData:SetField(EnumDef.LocalFields.ManPlayersInScreen, self._MaxPlayersInScreen)
    UserData:SetField(EnumDef.LocalFields.PowerSavingTime, self._EnterPowerSaveSeconds)
	UserData:SetField(EnumDef.LocalFields.BGMSysVolume, CSoundMan.Instance():GetBGMSysVolume())
	UserData:SetField(EnumDef.LocalFields.EffectSysVolume, CSoundMan.Instance():GetEffectSysVolume())
end

-- 保存角色信息，Key为当前服务器的名称
def.method().SaveLoginRoleConfigToUserData = function (self)
	if self._HostPlayer == nil then return end
	local hpData = self._HostPlayer._InfoData
	local account = self._NetMan._UserName
	local CLoginMan = require "Main.CLoginMan"
	local curZoneId = CLoginMan.GetServerZoneId(self._NetMan._IP, self._NetMan._Port, self._NetMan._ServerName)
	do
		local role =
		{
			roleId = self._HostPlayer._ID,
			level = hpData._Level,
			name = hpData._Name,
			profession = hpData._Prof,
			customSet = hpData._CustomImgSet,
			zoneId = curZoneId,
		}
		-- 用于显示最近登录，Key为服务器名字
		local roleList = UserData:GetCfg(EnumDef.LocalFields.RecentLoginRoleInfo, account)
		if roleList == nil then
			roleList = {}
		end
		local removeIndex = 0
		for i, v in ipairs(roleList) do
			if v.roleId == self._HostPlayer._ID and v.zoneId == curZoneId then
				removeIndex = i
				break
			end
		end
		if removeIndex > 0 then
			-- 移除旧的角色信息
			table.remove(roleList, removeIndex)
		end
		table.insert(roleList, 1, role)
		UserData:SetCfg(EnumDef.LocalFields.RecentLoginRoleInfo, account, roleList)
	end

	do
		local role =
		{
			ZoneId = curZoneId,
			ServerName = self._NetMan._ServerName,
			-- LastRoleIndex = self._AccountInfo._CurrentSelectRoleIndex,	-- 该角色在账号角色列表的索引
			Level = hpData._Level,
			RoleId = self._HostPlayer._ID,
			HeadIcon =
			{
				-- 头像相关
				CustomImgSet = hpData._CustomImgSet,
				Gender = hpData._Gender,
				Prof = hpData._Prof,
			},
		}
		-- 用于显示快速进入，属于列表，最多存放三个
		local roleInfoList = UserData:GetCfg(EnumDef.LocalFields.QuickEnterGameRoleInfo, account)
		if roleInfoList == nil then
			roleInfoList = {}
		end
		local removeIndex = 0
		for i, v in ipairs(roleInfoList) do
			if v.RoleId == self._HostPlayer._ID then
				removeIndex = i
				break
			end
		end
		if removeIndex > 0 then
			-- 移除旧的角色信息
			table.remove(roleInfoList, removeIndex)
		end
		table.insert(roleInfoList, 1, role)
		-- 最多存放三个
		local maxLength = 3
		while(#roleInfoList > maxLength) do
			table.remove(roleInfoList, maxLength+1)
		end
		UserData:SetCfg(EnumDef.LocalFields.QuickEnterGameRoleInfo, account, roleInfoList)
	end
	self._HostPlayer:SaveHostPlayerConfig()
end

-- 保存背包数据信息
def.method().SaveBagItemToUserData = function (self)
	local itemList = {}
	local itemData = self._HostPlayer._Package._NormalPack._ItemSet
	for i,v in ipairs(itemData) do
		if v._IsNewGot then 
			local item = {}
			item.IsNewGot = v._IsNewGot
			item.Slot = v._Slot
			itemList[#itemList +1] = item
		end 
	end
	CRedDotMan.SaveModuleDataToUserData("Bag",itemList)
	-- self._CFriendMan:SaveRecord()
end

--获取当前Entiy自定义头像  1、Image 2、roleId 3、CustomImgSet 4、Gender 5、Profession 6、
def.method("userdata" , "number" , "number" , "number",  "number").SetEntityCustomImg = function(self, imgObj , roleId ,customImgSet , gender , profession)
	if roleId ~= nil then
		local ECustomSet = require "PB.data".ECustomSet	
			
		if customImgSet == ECustomSet.ECustomSet_Success then	--获取自定义头像
			-- warn("lidaming : Review or HaveSet!!!")
			--获取自定义头像
			local entityImgPath = ""
			
			-- error: 1、参数不匹配 2、没有用户 3、审核中 4、审核未通过 5、文件不存在 6、md5一致 7、被Ban
			local callback = function(strFileName ,retCode, error)	
				if IsNil(imgObj) then return end
                if retCode == 0 or retCode == 6 then
                    entityImgPath = GameUtil.GetCustomPicDir().."/"..roleId
                else
                    entityImgPath = ""
                end		
                if entityImgPath == "" then
                    local professionTemplate = CElementData.GetProfessionTemplate(profession)   
					if professionTemplate == nil then
						warn("自定义头像模板错误：profession:_",profession)
					return end      
					
					if gender == EnumDef.Gender.Female then
						GUITools.SetHeadIcon(imgObj, professionTemplate.FemaleIconAtlasPath)
					else
						GUITools.SetHeadIcon(imgObj, professionTemplate.MaleIconAtlasPath)
					end
                else
                    GUITools.SetHeadIconfromImageFile(imgObj, entityImgPath)	
                end		
            end
			GameUtil.DownloadPicture(tostring(roleId), callback)
		else
		-- 只要不是检测成功，全部显示默认头像
		-- 	if customImgSet == ECustomSet.ECustomSet_Defualt 	--默认职业头像
		-- or customImgSet == ECustomSet.ECustomSet_Review then	--审核中
			local professionTemplate = CElementData.GetProfessionTemplate(profession)   
			if professionTemplate == nil then
				warn("自定义头像模板错误：profession:_",profession)
			return end      
			
			if gender == EnumDef.Gender.Female then
				GUITools.SetHeadIcon(imgObj, professionTemplate.FemaleIconAtlasPath)
			else
				GUITools.SetHeadIcon(imgObj, professionTemplate.MaleIconAtlasPath)
			end
		end
	end	    
end

def.method().SendC2SRankRewardGet = function(self)
	local protocol = (require "PB.net".C2SRankRewardGet)()
	PBHelper.Send(protocol)
end

def.method("=>", "boolean").IsWorldReady = function (self)
	if self._CurWorld == nil then return false end

	return self._CurWorld._IsReady
end

def.method("=>", "number").GetCurMapTid = function (self)
	return self._CurWorld._WorldInfo.MapTid
end

def.method("table", "number", "function", "function").NavigatToPos = function(self, destPos, distOffset, onArrive, onFail)
	if not self:IsWorldReady() or self._HostPlayer == nil then 
		if onFail ~= nil then onFail() end
		return 
	end
	
	if not self._HostPlayer:CanMove() then
		if onFail ~= nil then onFail() end
		self._GUIMan:ShowTipText(StringTable.Get(600), false)
		return
	end

    self._HostPlayer._NavTargetPos = destPos

    local function OnReach()
	    self._HostPlayer:StopNaviCal()
	    self._HostPlayer:SetAutoPathFlag(false)
	    self._HostPlayer._NavTargetPos = nil
	    CPath.Instance():HideTargetFxAndDistance()
	    if onArrive ~= nil then onArrive() end
	end

	local function OnNotReach()
	    self._HostPlayer:StopNaviCal()
	    self._HostPlayer:SetAutoPathFlag(false)
	    self._HostPlayer._NavTargetPos = nil
	    CPath.Instance():HideTargetFxAndDistance()
	    if onFail ~= nil then onFail() end
	end

    self._HostPlayer:MoveAndDonotCareCollision(destPos, distOffset, OnReach, OnNotReach)
    CPath.Instance():ShowPath(destPos)
end

-- 更新相机战斗锁定状态
def.method("number", "boolean").UpdateCameraLockState = function (self, entityId, isToLock)
	local hp = self._HostPlayer
	if hp == nil then return end

	-- print("UpdateCameraLockState entityId:", entityId, " _CamLockEntityId:", self._CamLockEntityId, " isToLock:", isToLock)
	if isToLock then
		-- 尝试进入锁定
		if entityId <= 0 or self._CamLockEntityId > 0 then return end
		if not hp._IsTargetLocked then return end -- 处于强锁状态
		local curTarget = hp:GetCurrentTarget()
		if curTarget == nil or curTarget._ID ~= entityId then return end -- 强锁目标与锁定视角目标一致
		if hp:IsEntityHate(entityId) then
			-- 处于强锁状态，且有仇恨
			local entity = self._CurWorld:FindObject(entityId)
			if entity ~= nil then
				local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
				if entity:GetObjectType() == OBJ_TYPE.MONSTER and self._IsOpenPVECamLock then
					-- PVE相机锁定
					local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
					local quality = entity._MonsterTemplate.MonsterQuality
					if quality == EMonsterQuality.LEADER or quality == EMonsterQuality.BEHEMOTH then
						-- 头目或者巨兽
						self._CamLockEntityId = entityId
						GameUtil.SetCamLockState(true, entity._GameObject)
						return
					end
				elseif entity:GetObjectType() == OBJ_TYPE.ELSEPLAYER or entity:GetObjectType() == OBJ_TYPE.PLAYERMIRROR and self._IsOpenPVPCamLock then
					-- PVP相机锁定
					self._CamLockEntityId = entityId
					GameUtil.SetCamLockState(true, entity._GameObject)
					return
				end
			end
		end
	else
		-- 尝试解除锁定

		-- print("NotToLock IsEntityHate:", hp:IsEntityHate(entityId))

		if entityId <= 0 then
			--[[
			-- 检查是否满足锁定的判断条件，满足则不解锁
			if self._CamLockEntityId <= 0 then return end
			if hp:IsEntityHate(self._CamLockEntityId) then
				local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
				local entity = self._CurWorld:FindObject(self._CamLockEntityId)
				if entity ~= nil then
					if self._IsOpenPVECamLock and entity:GetObjectType() == OBJ_TYPE.MONSTER then
						local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
						local quality = entity._MonsterTemplate.MonsterQuality
						if quality == EMonsterQuality.LEADER or quality == EMonsterQuality.BEHEMOTH then
							return -- PVE锁定的判断条件满足，解除锁定失败
						end
					elseif self._IsOpenPVPCamLock and entity:GetObjectType() == OBJ_TYPE.ELSEPLAYER then
						return -- PVP锁定的判断条件满足，解除锁定失败
					end
				end
			end
			--]]
		elseif self._CamLockEntityId ~= entityId or hp:IsEntityHate(entityId) then
			return -- 强锁目标与解除锁定目标不一致，或仇恨没解除，解除锁定失败
		end
	end

	-- 进入锁定失败或想关闭锁定
	self._CamLockEntityId = 0
	GameUtil.SetCamLockState(false)
end

def.method().QuitNearCam = function (self)
	if not self._IsInNearCam then return end
	GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.NEAR, true, nil, 2, nil)
	self._GUIMan:Close("CPanelUINearCam")
	-- 开启人物休闲状态
	self._HostPlayer:SetPauseIdleState(false)
end

---------------------------------Open Debug Log FPS-----------------------------------------

def.method("boolean").HideDebug = function(self, hideDebug)
	if not hideDebug then
		self._GUIMan:Open("CPanelDebug", nil)	
	else
		local PanelDebug = require "GUI.CPanelDebug".Instance()
		if PanelDebug:IsShow() then
			self._GUIMan:Close("CPanelDebug")
		end
	end
end

def.method("boolean").HideLog = function(self, hideLog)
	if not hideLog then
		self._GUIMan:Open("CPanelLog", nil)	
	else
		local PanelLog = require "GUI.CPanelLog".Instance()
		if PanelLog:IsShow() then
			self._GUIMan:Close("CPanelLog")
		end
	end
end

local ping_obj = nil
def.method("boolean").HideFPSPing = function(self, hideFPSPing)	
	if IsNil(ping_obj) then
		ping_obj = GameObject.Find("UIRootCanvas/Panel_FPS")
	end
	if not hideFPSPing then
		ping_obj:SetActive(true)
	else
		ping_obj:SetActive(false)
	end
end

--查询其他玩家信息
def.method("number", 'number', 'dynamic').CheckOtherPlayerInfo = function(self, nPlayerID, infoType, originType)
	 local protocol = (require "PB.net".C2SGetOtherRoleInfo)()
    protocol.RoleId = nPlayerID
    protocol.InfoType = infoType
    protocol.Mark = originType or -1

    PBHelper.Send(protocol)
end

--储存功能解锁特效
def.method().SaveOperationUnLockFXData = function(self)
	local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"
	CPanelSystemEntrance.Instance(): SaveFxBtnIDToData()

	self._DesignationMan: SaveRedPointData()
end
--------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------
-- SystemInfo

-- 联网状态
def.method("=>", "number").GetNetworkStatus = function(self)
	--[[
		NetworkStatus = 
	    {
	        NotReachable = 0,
	        DataNetwork = 1,
	        WIFI = 2
	    },
	]]
	return GameUtil.GetNetworkStatus()
end
-- 电池剩余电量
def.method("=>", "number").GetBatteryLevel = function(self)
	return GameUtil.GetBatteryLevel()
end
-- 服务器连接ping值
def.method("=>", "number").GetPing = function(self)
	return self._Ping
end
-- 电池状态
def.method("=>", "number").GetBatteryStatus = function(self)
--[[
	BatteryStatus
    {

        Unknown = 0,
        Charging = 1,
        Discharging = 2,
        NotCharging = 3,
        Full = 4,
    },
]]
	return GameUtil.GetBatteryStatus()
end
--------------------------------------------------------------------------------------------
--手动退出游戏
def.method().QuitGame = function(self)
	if CPlatformSDKMan.Instance():IsPlatformExitGame() then
		CPlatformSDKMan.Instance():ExitGame()
	else
		local function callback( ret )
			if ret then
				GameUtil.QuitGame()
			end
		end

		--warn("ShowMsgBox Quit")
		local boxMan = require "GUI.CMsgBoxMan"
		if boxMan.Instance()._CurPriority ~= MsgBoxPriority.Quit then
			local title, msg, closeType = StringTable.GetMsg(104)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Quit)
		end
	end
end

CGame.Commit()

_G.game = CGame.Instance()

return CGame