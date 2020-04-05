_G.EnumDef =
{
    RuntimePlatform = 
    {
        OSXEditor = 0,
        OSXPlayer = 1,
        WindowsPlayer = 2,
        OSXWebPlayer = 3,
        OSXDashboardPlayer = 4,
        WindowsWebPlayer = 5,
        WindowsEditor = 7,
        IPhonePlayer = 8,
        PS3 = 9,
        XBOX360 = 10,
        Android = 11,
        NaCl = 12,
        LinuxPlayer = 13,
        FlashPlayer = 15,
        WebGLPlayer = 17,
        MetroPlayerX86 = 18,
        WSAPlayerX86 = 18,
        MetroPlayerX64 = 19,
        WSAPlayerX64 = 19,
        MetroPlayerARM = 20,
        WSAPlayerARM = 20,
        WP8Player = 21,
        BB10Player = 22,
        BlackBerryPlayer = 22,
        TizenPlayer = 23,
        PSP2 = 24,
        PS4 = 25,
        PSM = 26,
        XboxOne = 27,
        SamsungTVPlayer = 28,
        WiiU = 30,
        tvOS = 31
    },

    EntityLogoType =
    {
        Gather      = 0,   
        Talk        = 1,
        Kill        = 2,
        Shop        = 3,
        Fight       = 4,
        Store       = 5,
        Skill       = 6,
        Rescue      = 7,
        Max         = 8,
        Deliver     = 9,
        Provide     = 10,
        InProgress  = 11,
        None        = -1
    },

    ManualType =
    {
        Manual      = 0,   
        Anecdote    = 1,

        None        = -1
    },

    EntityFightType =
    {
        ENTER_FIGHT       = 0,   
        ENTER_ANGER       = 1,
        CHANGE_TARGET     = 2,
        USE_SPECIAL_SKILL = 3,
        ENTER_WEAK_POINT  = 4,
        LEAVE_FIGHT       = 5,

        None        = -1
    },

    HPColorType =
    {
        Red         = 0,   
        Green        = 1,

        None        = -1
    },

    ServiceType =
    {
        Conversation        = 0,
        ProvideQuest        = 1,
        DeliverQuest        = 2,
        SellItem            = 3,
        CreateGuild         = 4,
        GuildList           = 5,
        GuildInfo           = 6,
        GuildWareHouse      = 7,
        GuildSmithy         = 8,
        GuildExtractCard    = 9,
        GuildDungeon        = 10,
        GuildShop           = 11,
        GuildLaboratory     = 12,
        GuildKnowItem       = 13,
        GuildSubmitItem     = 14,
        GuildApplyFortress  = 15,
        Transfer            = 16
    },

    CLIP =
    {
        BATTLE_STAND = "stand_battle_c",
        BATTLE_RUN = "run_battle_c",
        COMMON_STAND = "stand_c",
        COMMON_RUN = "run_c",
        COMMON_WALK = "walk_c",
        ADDITIVE_HURT = "hurt_mix_c",
        NORMAL_HURT = "hurt_front_c",  -- 有下半身动画，在站立时播放
        COMMON_DIE = "die_c",
        RIDE_STAND = "ride_stand_c",
        RIDE_RUN = "ride_run_c",
        TALK_GREET = "greet_c",
        TALK_IDLE = "idle1_c",
        VICTORY = "victory_c",
        DEFEAT = "defeat_c",
        VICTORY_STAND = "victory_stand_c",
        DEFEAT_STAND = "defeat_stand_c",
        STUN = "stun_c",
        BORN = "born_c",

    },

    CAM_CTRL_MODE =
    {
        INVALID     = 0,
        LOGIN       = 1,    --登录中
        GAME        = 2,    --正常游戏中
        CG          = 3,    --游戏CG中
        NPC         = 4,    --打开npc界面
        DUNGEON     = 5     --通用结算界面
    },

    RenderLayer =
    {
        Default = 0,
        TransparentFX = 1,
        IgnoreRaycast = 2,
        Water = 4,
        UI = 5,

        -- 前8 layer是Unity需要的，不可修改
        Terrain = 8,
        Building = 9,
        Player = 10,
        NPC = 11,
        Blockable = 12,
        Clickable = 13,   
        EntityAttached = 17,  -- 对象附属物 （光圈 头顶字 等）
        Fx = 18,


        Unblockable = 30,
        Invisible = 31
    },


    --体型
    BodySize = 
    {
        [0] = 0.7,
        [1] = 1,
        [2] = 1.5,
        [3] = 2
    },

    --[[ ========================
    -- 以下颜色值由美术提供 --
    -- quality   color
          0     白FFFFFF
          1     绿75B900
          2     蓝097EE9
          3     紫7E33EF
          4     金FFFC22
          5     橙E6870C
          6     粉红FD3598
    ============================]]
    Quality2ColorValue =
    {
        [0] = Color.New(1, 1, 1, 0),
        [1] = Color.New(117/255, 185/255, 0, 0),
        [2] = Color.New(9/255, 126/255, 233/255, 0),
        [3] = Color.New(126/255, 51/255, 239/255, 0),
        [4] = Color.New(1, 252/255, 34/255, 0),
        [5] = Color.New(230/255, 135/255, 12/255, 0),
        [6] = Color.New(253/255, 53/255, 152/255, 0)
    },

    Quality2ColorHexStr =
    {
        [0] = "ffffff",
        [1] = "75b900",
        [2] = "097EE9",
        [3] = "7E33EF", --
        [4] = "FFFC22",
        [5] = "E6870C",
        [6] = "FD3598",
        [7] = "FD3598"
    },

    TopPateColorHexStr = 
    {
        [0] = "ffffff",
        [1] = "097EE9",
        [2] = "E6870C",
    },

    SuitColorHexStr = 
    {
        [0] = "75B900",
        [1] = "E6870C",
        [2] = "373737FF",
        [3] = "9DB4C3FF",
    },

    LegendColorHexStr = 
    {
        [0] = "FF0000FF",
        [1] = "E6870C",
        [2] = "9DB4C3FF",
        [3] = "373737FF",
    },


    QuestObjectiveColor =
    {
        Default = Color.New(1,1,1,1),
        InProgress = Color.New(1, 0.867, 0.467, 1),
        Finish = Color.New(0.573, 0.941, 0.317 ,1),
        Failed = Color.New(1,0,0,1)
    },

    GUI_SORTING_LAYER =
    {
        GameWorld = 1,
        RootPanel = 2,
        SubPanel = 3,
        NormalTip = 4,
        ImportantTip = 5,
        Debug = 6,
        Log = 7
    },

    GameLayer=
    {
        [1] = "LayerGameWorld",
        [2] = "LayerPanelRoot",
        [3] = "LayerSubPanel",
        [4] = "LayerNormalTip",
        [5] = "LayerImportantTip",
        [6] = "LayerDebug"
    },

    PanelCloseType =
    {
        ClickAnyWhere = 1,
        ClickEmpty = 2,
        None = 3
    },

    PanelLayerType =
    {
        FixedLayer = 1,
        AlwaysOnTopOfAll = 2,
        AlwaysOnTopOfCurrent = 3
    },

    LegendUpgradeType =       --传奇属性升级类型
    {
        KILLCOUNT   = 0,    -- 杀怪数量
        QUEST       = 1,    -- 完成任务ID
        STRENGHT    = 2,    -- 强化等级
        NPC         = 3     -- 指定NPC对话
    },

    ESuitPropType =               --套装属性类型
    {
        EPropType_Value         = 0,   --固定属性
        EPropType_Percent       = 1,   --属性百分比
        EPropType_PassiveID     = 2    --被动技能
    },
    

    ItemTipsTitleBg =
    {
        [0] = "ItemTip/Img_ItemTitle_White",
        [1] = "ItemTip/Img_ItemTitle_Green",
        [2] = "ItemTip/Img_ItemTitle_Blue",
        [3] = "ItemTip/Img_ItemTitle_Purple", --紫色 6B00BEFF
        [4] = "ItemTip/Img_ItemTitle_Gold",
        [5] = "ItemTip/Img_ItemTitle_Orange",--橙色 FF9200FF
        [6] = "ItemTip/Img_ItemTitle_Red"
    },

    RoleEquipSlotImg =
    {
        [0] = "Img_Weapon",
        [1] = "Img_Helmet",
        [2] = "Img_Armor",
        [3] = "Img_Leggings",
        [4] = "Img_Boots",
        [5] = "Img_Bracers",
        [6] = "Img_Ring",
        [7] = "Img_Necklace"
    },

    UIEVENTS =
    {
        HIDE_OTHER = "HideOther",
        SHOW_OTHER = "ShowOther"
    },

    CAMERA_LOCK_PRIORITY =
    {
        LOCKED_BY_USER = 10,
        LOCKED_IN_SKILL_COMMON = 20
    },

    MotorTrackType =
    {
        Linear      = 0,
        Parabolic   = 1
    },

    MonsterQuality =
    {
       NORMAL   = 0;        -- 普通
       ELITE    = 1;        -- 精英
       LEADER   = 2;        -- 头目
       BEHEMOTH = 3;        -- 巨兽
       MACHINE  = 4;        -- 机关
    },
    
    SentenceDisplayType =
    {
        Aside   = 0,
        Left    = 1,
        Right   = 2
    },

    AlignType =
    {
        Left = 0,
        Right = 1,
        Top = 2,
        Bottom = 3,
        Center = 4,
        PanelBuff = 5
    },

    NavigationType =
    {
        Position = 0,
        Quest = 1,
        Npc = 2,
        GameEntity = 3
    },

    Profession =
    {
        Warrior = 1,
        Aileen = 2,
        Assassin = 3,
        Archer = 4
    },

    Gender =
    {
        Male = 0,
        Female = 1,
        Both   = 2
    },

    --状态控制类型
    StateControlType = 
    {
        Dizziness = 5,
        Frozen    = 6
    },

    Ease = 
    {
        Unset = 0,
        Linear = 1,
        InSine = 2,
        OutSine = 3,
        InOutSine = 4,
        InQuad = 5,
        OutQuad = 6,
        InOutQuad = 7,
        InCubic = 8,
        OutCubic = 9,
        InOutCubic = 10,
        InQuart = 11,
        OutQuart = 12,
        InOutQuart = 13,
        InQuint = 14,
        OutQuint = 15,
        InOutQuint = 16,
        InExpo = 17,
        OutExpo = 18,
        InOutExpo = 19,
        InCirc = 20,
        OutCirc = 21,
        InOutCirc = 22,
        InElastic = 23,
        OutElastic = 24,
        InOutElastic = 25,
        InBack = 26,
        OutBack = 27,
        InOutBack = 28,
        InBounce = 29,
        OutBounce = 30,
        InOutBounce = 31,
        Flash = 32,
        InFlash = 33,
        OutFlash = 34,
        InOutFlash = 35,
        INTERNAL_Zero = 36,
        INTERNAL_Custom = 37
    },

    LoopType = 
    {
        Restart = 0,
        Yoyo = 1,
        Incremental = 2
    },

    NotificationType = 
    {
        SystemNotify    = 0,
        TeamInvite      = 1,
        GuildInvite     = 2,
        Mail            = 3,
        Conversation    = 4,
    },

    --职业与职业掩码的对应关系
    Profession2Mask = 
    {   
        [1] = 1,
        [2] = 4,
        [3] = 2,
        [4] = 8
    },

    --UI快捷键事件枚举
    EShortCutEventType = 
    {
        Talk_Open = 1,--对话UI开启
        Gather_Open = 2,--对话UI开启
        Talk_Close = 3,--对话UI关闭
        Gather_Close = 4,--对话UI关闭
        Eye_Open = 5,--神之视野UI开始
        Eye_Close = 6,--神之视野UI关闭
        Eye_Use = 7,--神之视野使用开始
        Eye_UseOver = 8,--神之视野使用结束

    },

    --教学事件枚举
    EGuideType = 
    {
        Main_Start = 1,--教程开始
        Main_NextStep = 2,--教学下一步
        Main_Finish = 3,--教程完成
        Trigger_Start = 4,--触发教程开始
        Trigger_Finish = 5--触发教程结束
    },

    EManualEventType = 
    {
        Manual_INIT = 1,
        Manual_RECIEVE = 2,
        Manual_UPDATE = 3,
    },


    EGuideID = 
    {
        Main_StartGame = -1,--开始游戏教学
        Trigger_GainNewSkill = -2,
        Trigger_LevelUp = 1,--升级后提示教学
        Trigger_DungeonOpen = 2, --副本开启后提示教学
    },

    EGuideBehaviourID= 
    {
        None            = -1,
        StartGame       = 0,--开始游戏按钮逻辑行为
        --SelectRoleBtn   = 1, --选择人物界面进入游戏逻辑行为
        UseProp         = 1, --选择人物界面进入游戏逻辑行为 更改为使用道具后逻辑行为
        --NormalSkillBtn  = 2, --普通攻击逻辑行为
        FinishTask      = 2, --普通攻击逻辑行为 更改为完成任务逻辑行为
        --GainNewSkillBtn = 3, --新增技能逻辑行为
        DungeonPass     = 3, --新增技能逻辑行为 更改为副本通关逻辑行为
        LevelUp         = 4, --升级逻辑行为
    },

    EGuideConditionID =      --教学
    {
        FinishTask  = 1,
        LevelUp     = 2,
        PassDungeon = 3,
        UseProp     = 4,
    },

    EGuideTriggerFunTag =     --功能标识
    {
        Task                = 0, --任务
        Skill               = 1, --技能
        Pet                 = 2, --宠物
        Mount               = 3, --坐骑
        Dungeon             = 4, --副本
        Achievement         = 5, --成就
        Guild               = 6, --工会
        Inforce             = 7, --强化
        Activity            = 8, --活动
        Wing                = 9, --翅膀
        Information         = 10, --万武志
        Rune                = 11, --纹章
        Rebuild             = 12, --重铸
        Charm               = 13, --神符
        Advance             = 14, --进阶
        Quenching           = 15, --淬火
        GoldDungeon         = 16, --金币副本
        RewardTask          = 17, --悬赏任务
        ChallengeDungeon    = 18, --挑战副本
        ExperimentDungeon   = 19, --试炼副本
        Abattoir            = 20, --角斗场
        EliminateDungeon    = 21, --淘汰试炼
        Expedition          = 22, --远征
        Ranking             = 23 ,--排行榜
        Producers           = 24 ,--制作人员名单
    },

    TokenId = 
    {
		ExperienceId = 10010001,
		BindDiamondId = 10010002,
		DiamondId = 10010003,
		GoldId = 10010004
    },

    --为了避免key冲突，把UserData.lua里的key全都列出来，需要用的时候手动添加到这里
    LocalFields = 
    {
        LastLonginServer                    = "1",
        LastUseAccount                      = "2",
        RoleCfg                             = "3",
        FriendChat                          = "4",
        Skill                               = "5",
        CameraCtrlMode                      = "6",
        CameraDistance                      = "7",
    },

    HangPoint = 
    {
        HangPoint_Hurt = 1,
        HangPoint_WeaponLeft = 2,
        HangPoint_WeaponRight = 3,
        HangPoint_WeaponBack1 = 4,
        HangPoint_WeaponBack2 = 5,
    },

    --对话中文本中配置的特殊字符
    SpecialWordsOfDialogue = 
    {
        Name = "Name",
        Class = "Class",
        Race = "Race",
        HeShe = "HeShe"
    },

    FollowState = 
    {
        No_Team = -1,
        In3V3Fight = -1,
        
        Leader_None = 0,
        Leader_NoMember = 1,
        Leader_Followed = 2,

        Member_None = 3,
        Member_Followed = 4,
    },

    CameraCtrlMode =
    {
        FOLLOW = 0,
        FIX3D = 1,
        FIX25D = 2,
    },

    VoiceMode = 
    {
        None = 0,
        OffLine = 1,
        RealTimeVoiceTeam = 2,
        RealTimeVoiceNational = 3,
        Translation = 4,
    },

    GCloudVoiceRole = 
    {
        ANCHOR = 1,
        AUDIENCE = 2,
    },

    LayoutCorner = 
    {
        UpperLeft = 0,
        UpperRight = 1,
        LowerLeft = 2,
        LowerRight = 3
    },

    TextAlignment = 
    {
        UpperLeft = 0,
        UpperCenter = 1,
        UpperRight = 2,
        MiddleLeft = 3,
        MiddleCenter = 4,
        MiddleRight = 5,
        LowerLeft = 6,
        LowerCenter = 7,
        LowerRight = 8
    },

    EMonsterBodySize =
    {
        BODYSIZE_SMALL   = 0, -- 小型
        BODYSIZE_NORMAL  = 1, -- 标准
        BODYSIZE_BIG     = 2,-- 大型
        BODYSIZE_HUGE    = 3, -- 巨大 
    },

    HUDType = 
    {
        attack_normal       = 0,       -- 攻击伤害
        attack_crit         = 1,       -- 攻击伤害暴击
        under_attack_crit   = 2,       -- 挨打伤害
        under_attack_normal = 3,       -- 挨打伤害暴击
        heal                = 4,       -- 治疗
        hitrecoverey        = 5,       -- 击中回复（自己回血）
        get_coin            = 6,       -- 获得金币
        get_exp             = 7,       -- 获得经验
        get_exp_profession  = 8,       -- 获得职业经验
        attack_absorb       = 9,
        attack_block        = 10,
        under_attack_absorb = 11,
        under_attack_block  = 12,
    },

    EntityPart = 
    {
        Body                = 0,
        Face                = 1,
        Hair                = 2,
        Weapon              = 3,
        Wing                = 4,
    },

    -- entity基础状态
    EBASE_STATE = 
    {
        CAN_MOVE =          1,  -- 是否可以移动
        CAN_SKILL =         2,  -- 是否可以释放技能
        CAN_NORMAL_SKILL  = 3,  -- 是否可以使用普攻
        CAN_USE_ITEM =      4,  -- 是否可以使用物品
        CAN_BE_INTERACTIVE = 5, -- 是否可以交互
        CAN_BE_SELECTED =   6,  -- 是否可以被选中
        CAN_BE_ATTACKED =   7,  -- 是否可以被攻击
    },

    QuestEventNames = 
    {
        QUEST_INIT = "quest_init",
        QUEST_RECIEVE = "quest_recieve",
        QUEST_COMPLETE = "quest_complete",
        QUEST_CHANGE = "quest_change",
        QUEST_GIVEUP = "quest_giveup",
        QUEST_GETHEARSAY = "quest_gethearsay",
        QUEST_TIME = "quest_time"
    },

    ScreenEventTerminal = 
    {
        PerformEnd = 1,
        SkillEnd = 2,
    },

    BEHAVIOR_RETCODE = 
    {
        Failed = 0,
        Success = 1,
        Blocked = 2,  -- 被阻挡，用于移动时
        InvalidPos = 3,  -- 被阻挡，用于移动时
    },

    EntitySkillStopType = 
    {
        PerformEnd = 1,
        SkillEnd = 2,
    },

    SoundOriginType =
    {
        Sound_Top = 0,  --系统提示，必须播放的提示性音效！其他别用

        Sound_HostPlayer = 1,
        Sound_HostPlayer_Skill = 1,
        Sound_ElsePlayer = 2,
        Sound_ElsePlayer_Skill = 2,
        Sound_Npc = 3,
        Sound_Mine = 4,
        Sound_Monster = 5,
    },

    --进出视野类型
    SightUpdateType =
    {
        Unknown = 0,    -- 未知
        NewBorn = 1,  -- 新创建对象，适用于怪在视野中出生
        GatherDestory = 2, -- 采集销毁
    },

    --
    ActivityOpenUIType =
    {
        InstanceEnter = 0,    -- 副本
        EquipFortify = 1,     -- 装备强化
        Horse = 2,       -- 坐骑
        WorldBoss = 3,  -- 世界boss
    },

    -- UI模型的显示类型
    UIModelShowType = 
    {
        All                = 0,
        NoWing             = 1,
        NoWeapon           = 2,
        OnlySelf           = 3,
    },

    -- 特效优先级 高 -> 低
    CFxPriority = 
    {
        Always             = -1,        
        High               = 10,
        Middle             = 20,
        Common             = 30,
        Low                = 40,
        Ignore             = 50,
    },

    RoleEquipImg2Slot = 
    {
        ["Img_Weapon"] = 0,
        ["Img_Helmet"] = 1,
        ["Img_Armor"] = 2,
        ["Img_Leggings"] = 3,
        ["Img_Boots"] = 4,
        ["Img_Bracers"] = 5,
        ["Img_Ring"] = 6,
        ["Img_Necklace"] = 7
    },

    --副本类型(UI) 1 = 遗迹 2= 试炼 3= 巨龙巢穴 4= 奇里恩 5 = 世界BOSS
    DungeonType = 
    {
        _NormalDungeon  = 1,
        _TowerDungeon   = 2,
        _DragonLair     = 3,
        _Gilliam        = 4,
        _WorldBoss      = 5,
    },

    --副本类型(data)
    InstanceType = 
    {
        INSTANCE_NORMAL     = 0,-- 通用副本
        INSTANCE_JJC1X1     = 1,-- 1v1竞技场
        INSTANCE_PVP3X3     = 2,-- 3v3
        INSTANCE_GILLIAM    = 3,-- 奇利恩
        INSTANCE_TOWER      = 4,-- 试炼塔
    },
}

_G.res_base_path = ""
_G.document_path = ""
_G.target_miss_diantance = 30
_G.target_miss_diantance_square = 30 * 30
--自动索敌时间
_G.auto_detector_time = 0.1
_G.LastGCTime = 0
_G.ReconnectTimerId = 0
_G.StringTable = require "Data.CStringTable"
_G.FilterMgr = require "Utility.BadWordsFilter".Filter
_G.LuaString = require "Utility.BadWordsFilter".LuaString
_G.GameConfig = require "Data.GameConfig"
_G.CFxMan = require "Main.CFxMan"
_G.CSoundMan = require "Main.CSoundMan"
_G.CMenuListMan = require "Main.CMenuListMan"
_G.IDMan = require "Main.IDMan"
_G.CSpecialIdMan = require "Data.CSpecialIdMan"
_G.GUITools = require "GUI.GUITools"
_G.CFlashTipMan = require "Main.CFlashTipMan"
_G.CNotificationMan = require "Main.CNotificationMan"
_G.CUseDiamondMan = require"Main.CUseDiamondMan"
require "GUI.CNewContentTipMan"
-- 职业性别对应关系
_G.Profession2Gender = {0, 1, 0, 1}
--冒字开关
_G.SWITCH_HUD_TEXT = false
_G.RelationDesc = { [0] = "Neutral", [1] = "Friendly", [2] = "Enemy" }