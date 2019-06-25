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
        InWeakPoint = 12,
        InViolent   = 13,
        None        = -1
    },

    ServerState = 
    {
        Good        = 0,        --良好
        Normal      = 1,        --一般
        Busy        = 2,        --火爆
        Unuse       = 3,        --不可登录
    },

    ManualType =
    {
        Manual      = 0,   
        Anecdote    = 1,

        None        = -1
    },

    EntityFightType =
    {
        ENTER_FIGHT       = 1,   
        ENTER_ANGER       = 2,
        CHANGE_TARGET     = 3,
        USE_SPECIAL_SKILL = 4,
        ENTER_WEAK_POINT  = 5,
        LEAVE_FIGHT       = 6,
        None        = 7
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
        GuildPray           = 9,
        GuildDungeon        = 10,
        GuildShop           = 11,
        GuildLaboratory     = 12,
        GuildKnowItem       = 13,
        GuildSubmitItem     = 14,
        GuildApplyFortress  = 15,
        Transfer            = 16,
        EnterDungeon        = 17,
        NpcSale             = 18,
        StoragePack          = 19,
        CyclicQuest          = 20,
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
        TALK_IDLE = "idle01_c",
        VICTORY = "victory_c",
        DEFEAT = "defeat_c",
        VICTORY_STAND = "victory_stand_c",
        DEFEAT_STAND = "defeat_stand_c",
        STUN = "stun_c",
        BORN = "born_c",
        LEVELUP = "levelup_c",
        WING_COMMON_STAND = "stand_common_c",
        UNLOAD_WEAPON = "battle_end_c",
    },

    CAM_CTRL_MODE =
    {
        INVALID     = 0,
        LOGIN       = 1,    --登录中
        GAME        = 2,    --正常游戏中
        CG          = 3,    --游戏CG中
        NPC         = 4,    --打开npc界面
        DUNGEON     = 5,    --通用结算界面
        EXTERIOR    = 6,    --外观界面
        NEAR        = 7,    --主角近景
        BOSS        = 8,     --Boss进场动作
        SCENE_DLG = 10	--测试对画模糊
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
        HostPlayer = 16,
        EntityAttached = 17,  -- 对象附属物 （光圈 头顶字 等）
        Fx = 18,
        ClientBlockable = 21,

        TopPate = 25,

        CG = 27,

        Unblockable = 30,
        Invisible = 31
    },

    --Item蒙红原因
    ItemUseReason =
    {
        Success = 0,
        MinLevel = 1,
        MaxLevel = 2,
        Prof = 3,
        Gender = 4,
        QuestFail = 5,
        IsExpire = 6,
        IsCoolingDown = 7,
    },

    --体型
    BodySize = 
    {
        [0] = 0.7,
        [1] = 1,
        [2] = 2,
        [3] = 3
    },

    --[[ ========================
    -- 以下颜色值由美术提供 --
    -- quality   color
          0     白 909AA8
          1     绿 5CBE37
          2     蓝 3990DA
          3     紫 A436D7
          4     金 
          5     橙 D78236
          6     红 DB2E1C
    ============================]]
    Quality2ColorValue =
    {
        [0] = Color.New(144/255, 154/255, 168/255, 0),
        [1] = Color.New(92/255, 190/255, 55/255, 0),
        [2] = Color.New(57/255, 144/255, 218/255, 0),
        [3] = Color.New(164/255, 54/255, 215/255, 0),
        [4] = Color.New(164/255, 54/255, 215/255, 0),
        [5] = Color.New(219/255, 46/255, 28/255, 0),
        [6] = Color.New(215/255, 130/255, 54/255, 0)
    },

    Quality2RecommendCount = 
    {
        [0] = 2,
        [1] = 2,
        [2] = 2,
        [3] = 4,
        [4] = 0,
        [5] = 5,
        [6] = 6,
    },

    Quality2ColorHexStr =
    {
        [0] = "909AA8",
        [1] = "5CBE37",
        [2] = "3990DA", --
        [3] = "A436D7",
        [4] = "A436D7",
        [5] = "D78236",
        [6] = "DB2E1C",
    },

    EquipProcessStatus2HexStr =
    {
        [0] = "FFFFFF",
        [1] = "5CBE37",
        [2] = "DB2E1C",
    },

    TopPateColorHexStr = 
    {
        [0] = "ffffff",
        [1] = "097EE9",
        [2] = "E6870C",
    },

    QuestColorHexStr = 
    {
        [0] = "FF5105",
        [1] = "FFC740",
        [2] = "3ECD55",
        [3] = "3ECD55",
        [4] = "097EE9",
        [5] = "097EE9",
        [6] = "3ECD55",
        [7] = "097EE9",
        [8] = "32A6E2",
        [9] = "3ECD55",
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
        [2] = "4DA1FFFF",
        [3] = "999999FF",
    },

    NeedColorHexStr = 
    {
        [0] = "FF0000",
        [1] = "FFFFFF",
    },

    OnlineColorHexStr = 
    {
        [0] = "FF0000",
        [1] = "FFFFFF",
    },
    QuestObjectiveColor =
    {
        Default = Color.New(1,1,1,1),
        InProgress = Color.New(1, 1, 1, 1),
        Finish = Color.New(0.573, 0.941, 0.317 ,1),
        Failed = Color.New(1,0,0,1)
    },

    PanelCloseType =
    {
        ClickAnyWhere = 1,
        ClickEmpty = 2,
        None = 3,
        Tip = 4,
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

    RoleEquipSlotImg_UIEquipPanel =
    {
        [0] = "Img_Equip_Weapon",
        [1] = "Img_Equip_Helmet",
        [2] = "Img_Equip_Armor",
        [3] = "Img_Equip_Leggings",
        [4] = "Img_Equip_Boots",
        [5] = "Img_Equip_Bracers",
        [6] = "Img_Equip_Ring",
        [7] = "Img_Equip_Necklace"
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

    MonsterQuality =
    {
       NORMAL   = 0,        -- 普通
       ELITE    = 1,        -- 精英
       LEADER   = 2,        -- 头目
       BEHEMOTH = 3,        -- 巨兽
       MACHINE  = 4,        -- 机关
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
        PanelBuff = 5,
        PVPLeft = 6,
        PVPRight = 7,
        PVP1V1Left = 8,
        PVP1V1Right = 9,
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
        Archer = 4,
        Lancer = 5,
    },

    --职业与职业掩码的对应关系
    Profession2Mask = 
    {   
        [1] = 1,
        [2] = 2,
        [3] = 4,
        [4] = 8,
        [5] = 16,
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
        Normal          = -1,
        TeamInvite      = 0,
        TeamApplication = 1,
        GuildInvite     = 2,
        Mail            = 3,
        Conversation    = 4,
        SystemNotify    = 5,
        TimeLimitActivity = 6,
    },

    --UI快捷键事件枚举
    EShortCutEventType = 
    {
        DialogStart = 1,--对话UI开启
        DialogEnd = 2,--对话UI关闭
        GatherStart = 3,--对话UI开启
        RescueStart = 4,--救援开启
        HawkEyeOpen = 5,
        HawkEyeClose = 6,--神之视野UI关闭
        HawkEyeActive = 7,--神之视野使用开始
        HawkEyeDeactive = 8,--神之视野使用结束    
    },

    --教学事件枚举
    EGuideType = 
    {
        Main_Start = 1,--教程开始
        Main_NextStep = 2,--教学下一步
        Main_Finish = 3,--教程完成
        Trigger_Start = 4,--触发教程开始
        Trigger_Finish = 5,--触发教程结束
        Guide_Show = 6,--教程开始显示
        Guide_Close = 7 --教学关闭显示
    },

    EManualEventType = 
    {
        Manual_INIT = 1,
        Manual_RECIEVE = 2,
        Manual_UPDATE = 3,
        Manual_RECIEVETOTAL = 4,
    },


    EGuideID = 
    {
        Main_Move = 1,--开始游戏教学
        Main_Attack  = 2,
        Main_Skill  = 3,--升级后提示教学
        Main_Task  = 4, --副本开启后提示教学
        -- Trigger_GainNewSkill = 100,
        -- Trigger_LevelUp = 101,--升级后提示教学
        -- Trigger_DungeonOpen = 102, --副本开启后提示教学
    },

    EGuideBehaviourID= 
    {
        AutoNextGuide   = -1,
        StartGame       = 0, --开始游戏逻辑行为
        UseProp         = 1, --选择人物界面进入游戏逻辑行为 更改为使用道具后逻辑行为
        FinishTask      = 2, --普通攻击逻辑行为 更改为完成任务逻辑行为
        DungeonPass     = 3, --新增技能逻辑行为 更改为副本通关逻辑行为
        LevelUp         = 4, --升级逻辑行为
        OnClickBG       = 5, --点击全屏背景行为
        OnClickTargetBtn= 6, --点击制定按钮行为
        EnterRegion     = 7, --到达某个区域行为
        OnClickTargetList = 8, --点击指定的列表的行为
        OnClickBlackBG    = 9, --点击全屏黑色遮罩背景按钮行为
        CGFinish          = 10, --CG播放结束后行为
        KillMonster       = 11, --杀死某只怪的行为
        ReceiveTask       = 12, --接到任务逻辑行为
        HPPercentLow      = 13, --血量降低
        HPPercentHigh     = 14, --血量增长
        WeakPotinIn       = 15, --进入破绽
        WeakPotinOut      = 16, --出破绽
        EnterFight        = 17, --进入战斗
        ServerCallBack    = 18, --服务器调用
        HawEye    = 19, --鹰眼开启行为
        Gather    = 20, --采集开启行为
        GatherFinish = 21, --采集结束行为
        LeaveRegion = 22,  --离开某个区域行为
        OpenUI = 23,  --打开某个界面行为
        FinishGuide  = 24, --完成某个教學
        BagCapacityLast  = 25, --背包超过剩余空间行为
        CloseUI = 26,  --关闭某个界面行为
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
        Calendar            = 7, --活动
        Wing                = 8, --翅膀
        Manual              = 9, --万物志
        Rune                = 10, --纹章
        Charm               = 11, --神符
        GoldDungeon         = 12, --金币副本
        RewardTask          = 13, --悬赏任务
        ChallengeDungeon    = 14, --挑战副本
        ExperimentDungeon   = 15, --试炼副本
        Abattoir            = 16, --角斗场
        EliminateDungeon    = 17, --淘汰试炼
        Expedition          = 18, --远征
        Mall                = 19, --商城
        Sign                = 20, --签到
        Designation         = 21, --称号
        Social              = 22, --好友
        Team                = 23, --组队
        Bag                 = 24, --背包
        EquipUp_Inforce     = 25,--装备强化
        EquipUp_Rebuild     = 26,--装备重铸
        EquipUp_Enchant     = 27,--附魔
        Dress               = 28,--时装
        JJC                 = 29,--竞技场
        --20170823追加
        Role                = 30,--角色
        Equip               = 31,--装备
        Exterior            = 32,--外观
        Rank                = 33,--排行榜
        Shop                = 34,--商店
        Operation           = 35,--设置
        AutoFight           = 36,--自动战斗
        Auction             = 37,--拍卖行
        Bonus               = 38,--福利
        PVP                 = 39,--pvp
        PVE                 = 40,--Pve
        TeamSkill           = 41,--团队技能
        DragonLair          = 42,--巨龙巢穴
        Honor               = 43,--荣誉
        SkillBtn            = 44,--技能按钮
        Map                 = 45,--Map地图
        RoleMenu            = 46,--角色菜单
        TaskTrack           = 47,--任务追踪
        WingEnter           = 48,--翅膀养成
        Activity            = 49,--指南
        Power               = 50,--省点模式
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
        LastLonginServer                = "LastLonginServer",
        LastUseAccount                  = "LastUseAccount",
        RoleCfg                         = "RoleCfg",
        FriendChatMessage               = "FriendChatMessage",
        FriendChatUnreadMsg             = "FriendChatUnreadMsg",
        Skill                           = "Skill",
        CameraCtrlMode                  = "CameraCtrlMode",
        CameraDistance                  = "CameraDistance",
        CameraPVELock                   = "CameraPVELock",
        CameraPVPLock                   = "CameraPVPLock",
        CameraSkillRecover              = "CameraSkillRecover",
        RecentLoginRoleInfo             = "RecentLoginRoleInfo",
        QuickEnterGameRoleInfo          = "QuickEnterGameRoleInfo",
        MedicialAutoUse                 = "MedicialAutoUse",
        MinHpValueToUseMedic            = "MinHpValueToUseMedic",
        MedicialUseHigher               = "MedicialUseHigher",
        ClickGroundMove                 = "ClickGroundMove",
        PowerSaving                     = "PowerSaving",
		PowerSavingTime				= "PowerSavingTime",
        --IsBackgroundMusicEnable             = "IsBackgroundMusicEnable",
        --IsEffectAudioEnable                 = "IsEffectAudioEnable",
        IsShowHeadInfo                  = "IsShowHeadInfo",
        PostProcessLevel                = "PostProcessLevel",
        ShadowLevel                     = "ShadowLevel",
        CharacterLevel                  = "CharacterLevel",
        SceneDetailLevel                = "SceneDetailLevel",
        FxLevel                         = "FxLevel",
        IsUseDOF                        = "IsUseDOF",
        IsUsePostProcessFog             = "IsUsePostProcessFog",
        IsUseWaterReflection            = "IsUseWaterReflection",
        --IsUseWeatherEffect                  = "IsUseWeatherEffect",
        --IsUseDetailFootStepSound            = "IsUseDetailFootStepSound",
        FPSLimit                        = "FPSLimit",
        BGMSysVolume                    = "BGMSysVolume",
        EffectSysVolume                 = "EffectSysVolume",
        UnlockUIFxPlayStatus            = "UnlockUIFxPlayStatus",

        ManPlayersInScreen              = "ManPlayersInScreen",
        RedDotModuleData                = "RedDotModuleData",
        DecomposeFliter                 = "DecomposeFliter",
        BagSort                         = "BagSort",    
        AppMsgBox                       = "AppMsgBox", 

        AccountToken                    = "AccountToken",

        EquipSkipGfx_Fortify            = "EquipSkipGfx_Fortify",
        EquipSkipGfx_Recast             = "EquipSkipGfx_Recast",
        EquipSkipGfx_Refine             = "EquipSkipGfx_Refine",
        EquipSkipGfx_LegendChange       = "EquipSkipGfx_LegendChange",
        EquipSkipGfx_Inherit            = "EquipSkipGfx_Inherit",
        PetEggSkipGfx_PetEgg            = "PetEggSkipGfx_PetEgg",
        MallSkipGfx_Springift           = "MallSkipGfx_Springift",
        CharmSkipGfx_Compose            = "CharmSkipGfx_Compose",

		ShowHeadInfo							= "ShowHeadInfo",

        QuickMsg                        = "QuickMsg",
    },

    HangPoint = 
    {
        HangPoint_Hurt = 1,
        HangPoint_WeaponLeft = 2,
        HangPoint_WeaponRight = 3,
        HangPoint_WeaponBack1 = 4,
        HangPoint_WeaponBack2 = 5,
        HangPoint_WaistTrans = 6,
        HangPoint_Wing =7,
        HangPoint_Carry =8,
        HangPoint_Ride_alipriest_f =9,
        HangPoint_Ride_casassassin_m = 10,
        HangPoint_Ride_humwarrior_m = 11,
        HangPoint_Ride_sprarcher_f = 12 ,
        HangPoint_NPCDigCamera = 13,
        HangPoint_Headwear = 18
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

    TeamInfoChangeType = 
    {
        ResetAllMember  = 0,    --全部刷新，包括队伍成
        Hp              = 1,    --血量变化
        OnLineState     = 2,    --在线状态
        MapInfo         = 3,    --地图线路变化
        Level           = 4,    --等级变化
        FollowState     = 5,    --跟随
        FightScore      = 6,    --战斗力变化
        Bounty          = 7,    --赏金模式
        TARGETCHANGE    = 8,    --目标改变
        MATCHSTATECHANGE= 9,    --匹配状态改变
        Position        = 10,   --队员位置 x,z,mapId
        NewRoleComeIn   = 11,   --新队员加入
        InvitateStatus  = 12,   --邀请状态
        TeamMode        = 13,   --队伍类型（团队还是普通队伍 data.TeamMode）
        TeamSetting     = 14,   --队伍设置变化
        TeamMemberName  = 15,   --队伍成员名称变化
        
        DeadState = 50,         --客户端维护死亡状态  前值
    },

    PVEMatchEventType = 
    {
        None        = 0,
        StopByID    = 1,
        StopAll     = 2,
        Add         = 3,
        Update      = 4,
        UpdateList  = 5,
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
        skill_canceled =13,		--ji neng da duan
        attacked_skill_canceled  = 14,	--ji neng da duan
        attack_elem_light = 15,
        attack_elem_dark = 16,
        attack_elem_ice = 17,
        attack_elem_fire = 18,
        attack_elem_wind = 19,
        attack_elem_thunder = 20,
        attack_elem_light_c = 21,
        attack_elem_dark_c = 22,
        attack_elem_ice_c = 23,
        attack_elem_fire_c = 24,
        attack_elem_wind_c = 25,
        attack_elem_thunder_c = 26,
    },

	DamageElemType =
	{
        light = 1,
        dark = 2,
        ice = 3,
        fire = 4,
        wind = 5,
        thunder = 6,
	},

    HUDTextBGType = 
    {
        attack_crit         = 0,       -- 攻击伤害暴击
    },

    EntityType =
    {
        Unknown             = 0,
        Role                = 1,
        Monster             = 2,
        Npc                 = 3,
        SubObject           = 4,
        Obstacle            = 5,
        Loot                = 6,
        Mine                = 7,
        Pet                 = 8,
    },

    EntityPart = 
    {
        Body                = 0,
        Face                = 1,
        Hair                = 2,
        Weapon              = 3,
        Wing                = 4,
    },

    -- 玩家时装穿戴部位
    PlayerDressPart =
    {
        Body                = 0,
        Weapon              = 1,
        Head                = 2,
    },

    -- entity基础状态  PB3
    EBASE_STATE = 
    {
        EBASE_STATE_default = 1, 
        CAN_MOVE =          2,  -- 是否可以移动
        CAN_SKILL =         3,  -- 是否可以释放技能
        CAN_NORMAL_SKILL  = 4,  -- 是否可以使用普攻
        CAN_USE_ITEM =      5,  -- 是否可以使用物品
        CAN_BE_INTERACTIVE = 6, -- 是否可以交互
        CAN_BE_SELECTED =   7,  -- 是否可以被选中
        CAN_BE_ATTACKED =   8,  -- 是否可以被攻击
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
        LifeEnd = -1,
    },

    EntityGfxClearType = 
    {
        PerformEnd = 1,
        SkillEnd = 2,
        BackToPeace = 3,
        SkillInterrupted = 4,
        LifeEnd = 5,
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

    -- 冒险指南UI类型
    ActivityOpenUIType =
    {
        InstanceEnter = 0,  	-- 副本
        Expedition = 1,    	 	-- 远征
		ArenaOne = 2,       	-- 1V1
        ArenaThree = 3,  		-- 3V3
		Eliminate = 4,   		-- 无畏战场
		GuildDefend = 5,		-- 公会防守
		GuildDungeon = 6,   	-- 异界之门
		WorldBoss = 7,  		-- 世界boss
		GuildBattle = 8, 		-- 天空竞技场(公会战场)
		GuildQuest = 9,  		-- 公会任务
        RewardQuest = 10, 		-- 赏金任务
        GuildConvoy = 11, 		-- 公会护送
        ReputationQuest = 12,   -- 声望任务
        GuildTreasure = 13,     -- 公会宝藏
        SingleHawkeye = 14,           -- 神之视野 单人
        MultiHawkeye = 15,           -- 神之视野 多人
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
        Prior              =  0,
        High               = 10,
        Middle             = 20,
        Common             = 30,
        Low                = 40,
        Last               = 50,
        Ignore             = 60,
    },

    CFxSubType = 
    {
        Actor = 0,
        ClientFx = 1,
        Boomb = 2,
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

    --福利类型 1 = 签到   (暂时只有签到，以后有了再加)
    WelfareType = 
    {
        _Sign           = 1, 
        _GloryVIP       = 2,  -- 荣耀之路
        _SpecialSign    = 3,  -- 特殊签到
        _Festival       = 4,  -- 材料兑换
        _OnLineReward   = 5,  -- 在线奖励
    },

    --福利类型 1 = 签到   (暂时只有签到，以后有了再加)
    -- EnumDef.SkillFadeTime.MonsterSkill,
    SkillFadeTime = 
    {
        MonsterSkill = 0.1,
        MonsterOther = 0.1,
        HostSkill = 0.1,
        HostOther = 0.1,
    },

    --渲染等级
    EDisplayLevel =
    {
        DL_LOW = 0,
        DL_NORMAL = 1,
        DL_HIGH = 2,
        DL_HIGHER = 3,
        DL_CUSTOM = 4,
    },

    EntityRimEffect =
    {
        All = 0,
        Elite = 8,
        Flaw = 6,   
        Twinkle = 7,     
    },

    AutoMatchType = 
    {
        None = 0,           -- 未匹配
        In3V3Fight = 1,     -- 3v3竞技场
        InBattleFight = 2,  -- 无畏战场  
    },    

    OperationTipsType = 
    {
        PlayerLevelUp = 1, --等级提升
        GainNewSkill  = 2, --技能提升 
        FuncOpen      = 3, --功能开启
        RuneUse       = 4, --使用纹章
    },

    AutoFightType = 
    {
        None      = 0,  
        WorldFight = 1,
        QuestFight = 2,
    },

    OpenInfoType = 
    {
        UnLimited = 0,      --无限制
        TimeLimited = 1,    --时间限制， 无次数限制
        TimesLimited = 2,   --次数限制， 无时间限制
        AllLimited = 3,     --时间，次数 双限制
    },

    OpenArenaType = 
    {
        Open1V1 = 1,
        Open3V3 = 2,
        OpenBattle = 3,
    },
    DungeonEndType = 
    {
        InstanceType = 0,
        TrialType = 1,
        ArenaOneType = 2,
        ArenaThreeType = 3,
        EliminateType = 4,
        GuildDefend = 5,
    },

    -- 外观相机枚举类型
    CamExteriorType =
    {
        Ride = 1,       -- 坐骑
        Wing = 2,       -- 翅膀
        -- 时装
        Armor = 4,      -- 服饰
        Helmet = 5,     -- 头饰
        Weapon = 6,     -- 武器
    },

    -- 物品 分类 集合标志(用于装备加工界面)
    ItemCategory =
    {
        Weapon = 1,                 -- 武器
        Armor = 2,                  -- 防具
        Jewelry = 3,                -- 首饰
        EquipProcessMaterial = 4,   -- 装备加工材料

        Others = 0,     -- 其他物品
    },

    UIEquipPageState = 
    {
        PageFortify = 1,
        PageRecast = 2,
        PageRefine = 3,
        PageLegendChange = 4,
        PageInherit = 5,
        
        PageNone = -1,
    },

    UIPetPageState = 
    {
        PagePetInfo = 1,
        PageCultivate = 2,
        PageFuse = 3,
        PageAdvance = 4,
        PageSkill = 5,

        PageNone = -1,
    },

    TabListOpenType=
    {
        Unselect_Close = 0,
        Selected_Close = 1,
        Selected_Open = 2,
    },

    EntityAudioType = 
    {
        DeadAudio = 1,
        HurtAudio = 2,
    },

    ButtonHold =
    {
        Delay = 1,  -- 按钮长按延迟
        Tick = 0.1,   -- 按钮长按间隔
    },

    AttentionTipeType = 
    {
        _Simple = 1, --普通不带图标的
        _Boss   = 2, --BOSS释放技能
        _Tips   = 3, --带警告的
    },

    SkillLoadingBarType = 
    {
        Stick   = 1,
        Circle  = 2,
    },
    OpenMimiMapStatisticsPageType = 
    {
        DamageCountType = 1,
        RankDataType = 2, 
    },
    EngraveIconType = 
    {
        Empty = 0,
        Succeed = 1,
        Failed = 2,
    },

    GetTargetInfoOriginType = 
    {
        TargetHead = 0,
        Mail = 1,
        Guild = 2,
        Chat = 3,
        RecentContacts = 4,
        Friend = 5,      -- 好友
        FriendApply = 6, -- 好友申请
        RecentList = 7,  -- 最近联系人
        DungeonEnd = 8 , -- 副本结算
        GuildPrayHelp = 9,      -- 月光庭院互助
    },

    EntitySkillType = 
    {
        Normal = 0,
        Birth = 1,
        Dead = 2,
    },

    SettingPageType = 
    {
        RenderSetting = 0,
        BaseSetting = 1,
        BattleSetting = 2,
        AccountSetting = 3
    },

    -- 道具使用音效类型(暂时只添加了装备穿卸的音效)
    UseItemAudioType = 
    {
        [0] = "equip_cloth",
        [1] = "equip_armor",
        [2] = "equip_weapon",
        [3] = "equip_shoes",
    },

    PanelLoginOpenType =
    {
        DebugLogin = 1,
        KakaoLogin = 2,
        LongtuLogin = 3,
        OnlyServer = 99
    },

    CharmEnum = {
        CharmPageState = {
            Locked  = 1,
            Opened  = 2,
        },
        CharmFieldState = {
            Locked = 1,
            OpenButNoCharm = 2,
            HaveCharm = 3,     
        },
    },

    LootItemType =
    {
        Common	= 0;
		Senior	= 1;
		Rare	= 2;
		Epic	= 3;
		Suit	= 4;
		Legend	= 5;
		Origin	= 6;
        Money   = 10;
    },

    WholeQualityLevel =
    {
        Custom = 0,         --自定义
        Low = 1,            --低级
        Mid = 2,            --中级
        High = 3,           --高级
        Perfect = 4,        --最高级
    },

	-- 分线相关
    ValidLineState =
    {
        Idel = 0,           -- 为默认
        Free = 1,
        Busy = 2,
        Full = 3,
    },

    -- 替换动作分类
    PostureType =
    {
        StandAction = 1,
        FightStandAction = 2,
        MoveAction = 3,
        FightMoveAction = 4,
    },

    -- 奖励物品概率类型
    ERewardProbabilityType =
    {
        Certainly = 0,       -- 必得（默认）
        Low = 1,             -- 低概率获得
    },

    ETransType = 
    {
        TransToWorldMap = 1,     -- 传送到某个地图的出生点
        TransToPortal = 2,       -- 传送到某个地图的传送阵
        TransToInstance = 3,     -- 传送到某个副本
    },

    -- 装备战斗力细分类型
    EquipFightScoreType =
    {
        Total       = 0,    -- 总和
        Base        = 1,    -- 基础值
        Inforce     = 2,    -- 强化
        Recast      = 3,    -- 重铸
        Refine      = 4,    -- 精炼
        Talent      = 5,    -- 转化（天赋技能）
        Enchant     = 6,    -- 附魔
    },

    -- 冒险生涯解锁功能类型
    GloryUnlockType =
    {
        SelfPackUnlock                  = 0,    -- 解锁随身仓库
        BlackMarketUnlcok               = 1,    -- 解锁黑市
        No2PetUnlock                    = 2,    -- 解锁第2个出战宠物栏
        No3PetUnlock                    = 3,    -- 解锁第3个出战宠物栏
        GuildTaskFinishUnlock           = 4,    -- 解锁工会任务立即完成
        ReputationTaskFinishUnlock      = 5,    -- 解锁声望任务立即完成
        WorldAuctionUnlock              = 6,    -- 解锁世界拍卖行
    },

    MallStoreType = 
    {
        Coin                            = 1,    -- 金币
        BlueDiamond                     = 2,    -- 蓝钻
        RedDiamond                      = 3,    -- 红钻
        MonthlyCard                     = 4,    -- 月卡
        Fund                            = 5,    -- 基金
        RedDiamondExchange              = 6,    -- 红钻兑换
        CoinExchange                    = 7,    -- 金币兑换
        RedDiamondBag                   = 9,    -- 红钻礼包
        RedDiamondShop                  = 10,   -- 红钻商店
        MysteryShop                     = 11,   -- 神秘商店
        ClothShop                       = 12,   -- 时装商店
        HourseShop                      = 13,   -- 坐骑商店
        BlueDiamondShop                 = 14,   -- 蓝钻礼包
        PointShop                       = 15,   -- 积分商店
        BlueDiamondBag                  = 16,   -- 蓝钻礼包
        GrothlyShop                     = 17,   -- 成长礼包
        SuperWorthBag                   = 18,   -- 超值礼包
        ElfExtract                      = 19,   -- 精灵献礼
        PetExtract                      = 20,   -- 宠物扭蛋
    },

    NOTICE_EVENT_TYPE = 
    {
        QUESTDONE=1,
        FIGHTSCORE = 2,
        ACHIEVE = 3,
        LVUP = 4,
        NEWSKILL = 5,
        UNLOCKFUNC = 6,
        MAP = 7,
        CHAPTEROPEN = 8,
    },

    DailyQuestLuckColor = 
    {
        [1] = "E854FE",
        [2] = "32B5F2",
        [3] = "4DD15D",
        [4] = "658269",
        [5] = "797A7E",
    },
    -- 通用按钮参数
    CommonBtnParam = 
    {
        BtnTip          = 1,
        MoneyID         = 2,
        MoneyCost       = 3,  
    },

    -- 通用货币栏传入类型
    MoneyStyleType = 
    {
        None = 0,
        GuildSkill = 1,
        BucketShop = 2,     -- 斗技商店
        GuildShop = 3,
        FearlessShop = 4,   -- 无畏商店
        ScoreShop = 5,      -- 积分商店
        GloryShop = 6,      -- 荣耀商店
        DressShop = 7,      -- 时装兑换
        ReputationShop = 8, -- 声望商店
        SmallCharmShop = 9, -- 铭符商店
        BigCharmShop = 10,  -- 神符商店
    },

    -- 货币类型对应显示货币种类
    MoneyType = 
    { 
        [0] = { 1, 2, 3, 28},    -- 默认布局类型对应id 金币，蓝钻，红钻，绿钻
        [1] = { 6, 10 },
        [2] = { 7 },
        [3] = { 6, 5 },
        [4] = { 31 },
        [5] = { 29 },
        [6] = { 30 },
        [7] = { 32 },
        [8] = { 33, 1, 2, 3},
        [9] = { 24 },
        [10] = { 8 },
    },

    -- Emoji
    EmojiType = 
    {
        Gold = 0,           -- 金币
        EXp = 1,            -- 经验
        BlueDiamond = 2,    -- 蓝钻
        RedDiamond = 3,     -- 红钻
        GreenDiamond = 4,   -- 绿钻
        DressIntegration = 5,       -- 时装积分
    },

    ExchangeMoneyToEmoji = 
    {
        [1] = 0,    --EnumDef.EmojiType.Gold,
        [11] = 1,   --EnumDef.EmojiType.EXp,
        [2] = 2,    --EnumDef.EmojiType.BlueDiamond,
        [3] = 3,    --EnumDef.EmojiType.RedDiamond,
        [28] = 4,   --EnumDef.EmojiType.GreenDiamond,
        [32] = 5,   --EnumDef.EmojiType.DressIntegration,
    },

    NetworkStatus = 
    {
        NotReachable = 0,
        DataNetwork = 1,
        LocalNetwork = 2
    },

    BatteryStatus = 
    {

        Unknown = 0,
        Charging = 1,
        Discharging = 2,
        NotCharging = 3,
        Full = 4,
    },

    -- 平台SDK事件类型
    PlatformSDKEventType =
    {
        AccountConversion = 1,
        GoogleGame = 2,
    },

    TriggerTag =     --触发App弹窗条件
    {
        FinishAchievement        = 0, -- 完成成就
        FinishQuest              = 1, -- 完成任务
        GetIDItem                = 2, -- 获得指定ID物品
        ReachGloryLevel          = 3, -- 达到荣耀等级
        GetQualityItem           = 4, -- 获得指定品质物品
    },

    -- 上传角色信息的类型
    UploadRoleInfoType =
    {
        RoleInfoChange      = 0,
        Login               = 1,
    },
    -- 变强Tip提示（经验获取 和我要变强）
    PlayerStrongTip = 
    {
        ReviveTip = 1,
        GainExperience = 2,
    },

    -- 头顶字变更类型
    PateChangeType =
    {
        HP = 1,
        HPLine = 2,
        PKIcon = 3,
        TitleName = 4,
        GuildName = 5,
        GuildConvoy = 6,
        Rescue = 7,
    },

	BattleStgType = 
	{
		Concentrate=1, --集火BOSS，
		Cover =2, --转火，
		FallBack=3, --远离BOSS，
		StayClose=4, --靠近BOSS，
		Evade=5, --注意走位，
		Heal=6,	--注意治疗，
		Scatter=7, --分散，
		Ralley=8,	--集合
		Total=9,
	},

    EquipProcessStatus = 
    {
        None = 0,
        Success = 1,
        Failed = 2,
    },
    
    ThreadPriority = 
    {
        Low = 0,
        BelowNormal = 1,
        Normal = 2,
        High = 4
    },

    ApproachMaterialType = 
    {
        None = 0,
        PetAdvance = 1,
        PetSkillBook = 2,
        PetFuse = 3,
    },

    -- 创建角色的相机类型
    ECreateRoleCamType =
    {
        Face = 1,           -- 脸部相机
        Halfbody = 2,       -- 半身相机
        Body = 3,           -- 全身相机
        Job = 4             -- 选择职业相机
    },
    --背包物品呢类型
    EBagItemType = 
    {
        Weapon = 1,
        Armor = 2,
        Accessory = 3,
        Charm = 4,
        Consumables = 5,
        Else = 6,
    }
}

_G.FSM_STATE_TYPE = 
{
    NONE = 0,

    IDLE = 1,
    MOVE = 2,
    SKILL = 3,
    BE_CONTROLLED = 4,
    DEAD = 5,
}

-- 事件触发器类型，对应Template.proto ExecutionUnit中的类型
-- 部分触发器在技能系统中不生效，需要根据策划需求进行
_G.TriggerType =
{
    Timeline = 1,
    Loop = 2,
    Collision = 3,
    Operation = 4,
    NormalStop = 5,
    AbnormalStop = 6,
    FinalStop = 7,
    Charge = 8,
    RuneActivity = 9,  -- 符文
    CriticalHit = 10,
    Hit = 11,
    BeHited = 12,
    KillMonster = 13,
    HpChanged = 14,
    PropertiesChanged = 15,
    KillEntity = 16,

    All = 100,
}

_G.res_base_path = ""
_G.document_path = ""

--自动索敌时间
_G.auto_detector_time = 0.3
--小地图更新时间
_G.minimap_update_time = 0.3

_G.ReconnectTimerId = 0
_G.ForbidTimerId = 0

--教学层级次序上移
_G.GUIDE_ORDER_OFFSET = 6
_G.GUIDE_BUTTON_ORDER_EX = 1        --will add up with GUIDE_ORDER_OFFSET
_G.GUIDE_FX_ORDER_EX = 2        --will add up with GUIDE_ORDER_OFFSET
_G.NAV_OFFSET = 2.5
_G.NAV_STEP = 1.0

_G.StringTable = require "Data.CStringTable" 
_G.GameConfig = require "Data.GameConfig"
_G.CFxMan = require "Main.CFxMan"
_G.CSoundMan = require "Main.CSoundMan"
_G.IDMan = require "Main.IDMan"
_G.CSpecialIdMan = require "Data.CSpecialIdMan"
_G.GUITools = require "GUI.GUITools"
_G.RichTextTools = require "GUI.RichTextTools"
require "GUI.IconTools"
_G.CFlashTipMan = require "Main.CFlashTipMan"
_G.CUseDiamondMan = require"Main.CUseDiamondMan"
_G.CPlatformSDKMan = require "PlatformSDK.CPlatformSDKMan"
-- 职业性别对应关系
_G.Profession2Gender = {0, 1, 0, 1, 1}

-- 帮助页面链接配置 
local HelpUrlConfig = require "Data.HelpUrlConfig"
_G.HelpPageUrlType = HelpUrlConfig.Get().HelpPageUrlType
_G.HelpPageUrl = HelpUrlConfig.Get().HelpPageUrl

--不同的角色对应不同的武器缩放切换参数
_G.WeaponChangeCfg = 
{
    -- [武器放大的时间点] [武器缩小的时间点] [收回武器切换挂点的时间点] [拔出武器切换挂点的时间点] 
    [1] = { (40-22)/30, 24/30, 30/30, (40-30)/30 },  --战士
    [2] = { (36-18)/30, 20/30, 22/30, (36-22)/30 },  --萝莉
    [3] = { (40-14)/30, 16/30, 24/30, (40-23)/30 },  --刺客
    [4] = { (40-20)/30, 15/30, 25/30, (40-24)/30 },  --射手
    [5] = { (36-18)/30, 20/30, 22/30, (36-22)/30 },  --枪骑士
}

_G.WeaponChangeSoundCfg = 
{
    -- [拔剑音效] [收剑音效]  
    [1] = { "warrior_weapon_in", "warrior_weapon_out" },  --战士
    [2] = { "priest_weapon_in", "priest_weapon_out" },  --萝莉
    [3] = { "assassin_weapon_in", "assassin_weapon_out" },  --刺客
    [4] = { "archer_weapon_in", "archer_weapon_in" },  --射手
    [5] = { "lancer_weapon_in", "lancer_weapon_out" },  --枪骑士
}

--冒字开关
_G.SWITCH_HUD_TEXT = false
_G.RelationDesc = { [0] = "Neutral", [1] = "Friendly", [2] = "Enemy" }

-- 玩家数量显示控制
_G.MAX_VISIBLE_PLAYER = 20
_G.VISIBLE_PLAYER_INNER_RATIO = 0.4

_G.BeginnerDungeonCgId = 2
_G.GuildBaseTid = 3

_G.PauseMask =
{
    UIShown       = bit.lshift(1,0),
    ManualControl = bit.lshift(1,1),
    TransBroken   = bit.lshift(1,2),
    WorldLoading  = bit.lshift(1,3),
    SameMapTrans  = bit.lshift(1,4),
    NpcService    = bit.lshift(1,5),
    BossEnterAnim = bit.lshift(1,6),
    CGPlaying     = bit.lshift(1,7),
    HostBaseState = bit.lshift(1,8),
    SkillPerform = bit.lshift(1,9),
    WorldMapTrans = bit.lshift(1,10),
    DungeonGoalChanged = bit.lshift(1,11),
}

_G.SkillUpdateFXOScale = 1.5

_G.PanelPageConfig =
{
    Activity = {
        {MenuBtn = "MenuBtn1", Page = "PageAdvancedGuide", Script = "GUI.CPageAdvancedGuide", MenuText = {{key = "Lab_Name", gameTextIndex = 34101}}, RedPoint = "Img_RedPoint", IsShow = true, IsRefrash = false, FunTid = 132, HelpUrlType = HelpPageUrlType.AdvancedGuide},
        {MenuBtn = "MenuBtn2", Page = "PageLiveness", Script = "GUI.CPageLiveness", MenuText = {{key = "Lab_Name", gameTextIndex = 31950}}, RedPoint = "Img_RedPoint", IsShow = true, IsRefrash = false, FunTid = 130, HelpUrlType = HelpPageUrlType.Liveness},
        {MenuBtn = "MenuBtn3", Page = "PageDailyTask", Script = "GUI.CPageDailyTask", MenuText = {{key = "Lab_Name", gameTextIndex = 31807}}, RedPoint = "Img_RedPoint", IsShow = true, IsRefrash = true, FunTid = 76, HelpUrlType = HelpPageUrlType.DailyTask},
    },
}

_G.MaxLevel = 60