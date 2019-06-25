
--[[--

初始化，载入预定义的常量、模块。

### 常量

在初始化框架之前，可以定义以下常量：

-   DEBUG: 设置框架的调试输出级别

    ```lua
    DEBUG = 0           -- 不输出任何调试信息（默认值）
    DEBUG = 1           -- 输出基本的调试信息
    DEBUG = 2           -- 输出详细的调试信息
    ```

-   DEBUG_FPS: 设置是否在画面中显示渲染帧率等信息

    ```lua
    DEBUG_FPS = false   -- 不显示（默认值）
    DEBUG_FPS = true    -- 显示
    ```

-   DEBUG_MEM: 设置是否输出内存占用信息

    ```lua
    DEBUG_MEM = false   -- 不输出（默认值）
    DEBUG_MEM = true    -- 每 10 秒输出一次
    ```
    
<br />


### 自动载入的模块

框架初始化时，会自动载入以下基本模块：

-   debug: 调试接口
-   functions: 提供一组常用的函数，以及对 Lua 标准库的扩展
-   device: 针对设备接口的扩展
-   crypto: 加密相关的接口
-   luaj: 提供从 Lua 调用 Java 方法的接口（仅限 Android 平台）
-   luaoc: 提供从 Lua 调用 Objective-C 方法的接口（仅限 iOS 平台）
]]

-- 初始化参数定义
local DEBUG = 2
local DEBUG_MEM = false


if type(DEBUG) ~= "number" then DEBUG = 0 end
if type(DEBUG_MEM) ~= "boolean" then DEBUG_MEM = false end

----

-- disable stdout buffer
io.stdout:setvbuf("no")

require "Utility.Debug"
require "Utility.Functions"
require "Utility.ShortCodes"

printInfo("# DEBUG = "..DEBUG)

if DEBUG_MEM then
    local function ShowMemoryUsage()
        printInfo(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
        --printInfo("---------------------------------------------------")
    end
    _G.AddGlobalTimer(30, false, ShowMemoryUsage)
end

-- LPlus config
local LuaCheckLevelEnum =
{
    None = 0,
    Limited = 1,
    Strict = 2,
}

local LuaCheckingLevel = LuaCheckLevelEnum.Strict

package.loaded.Lplus_config =
{
    reflection = false,
    declare_checking = LuaCheckingLevel >= 1,
    accessing_checking = LuaCheckingLevel >= 2,
    calling_checking = LuaCheckingLevel >= 2,
    reload = false,
}

_G.ReadConfigTable = function (path)
    local ret, msg, result = pcall(dofile, path)
    if ret then
        return result
    else
        warn("ReadConfigTable Failed!!!!!!!!! ", path, msg)
        return nil
    end
end

--释放已经加载的lua模块
_G.Unrequire = function(m)
    package.loaded[m] = nil
    _G[m] = nil
end

_G.PrintLoadedModules = function()
    for k,v in pairs(package.loaded) do
        print("package.loaded: "..k)
    end
end

_G.UserLanguageCode = ""
_G.UserLanguagePostfix = ""
_G.InterfacesDir = ""
_G.CommonAtlasDir = ""
_G.ConfigsDir = "Configs/"

_G.TemplatePath = 
{
    Achievement = "Achievement.data",
    Actor = {"Actor0.data", "Actor1.data" },
    AdventureGuide = "AdventureGuide.data",
    Asset = "Asset.data",
    AttachedPropertyGenerator = "AttachedPropertyGenerator.data",
    AttachedPropertyGroupGenerator = "AttachedPropertyGroupGenerator.data",
    AttachedProperty = "AttachedProperty.data",
    Banner = "Banner.data",
    CharmItem = "CharmItem.data",
    CharmPage = "CharmPage.data",
    CharmField = "CharmField.data",
    CharmUpgrade = "CharmUpgrade.data",
    ColorConfig = "ColorConfig.data",
    Cooldown = "Cooldown.data",
    CountGroup = "CountGroup.data",
    CyclicQuest = "CyclicQuest.data",
    CyclicQuestReward = "CyclicQuestReward.data",
    Designation = "Designation.data",
    Dialogue = "Dialogue.data",
    Dress = "Dress.data",
    DressScore = "DressScore.data",
    DropLibrary = "DropLibrary.data",
    DropLimit = "DropLimit.data",
    DropRule = "DropRule.data",
        DyeAndEmbroidery = "DyeAndEmbroidery.data",
    EliminateReward = "EliminateReward.data",
    Email = "Email.data",
    Enchant = "Enchant.data",
    EquipConsumeConfig = "EquipConsumeConfig.data",
    EquipInforce = "EquipInforce.data",
    EquipRefine = "EquipRefine.data",
    EquipSuit = "EquipSuit.data",
    ExecutionUnit = "ExecutionUnit.data",
    Expedition = "Expedition.data",
    Faction = "Faction.data",
    FactionRelationship = "FactionRelationship.data",
    FightPropertyConfig = "FightPropertyConfig.data",
    FightProperty = "FightProperty.data",
    Fortress = "Fortress.data",
    Fund = "Fund.data",
    Fun = "Fun.data",
    GloryLevel = "GloryLevel.data",
    Goods = "Goods.data",
    Guide = "Guide.data",
    GuildBattle = "GuildBattle.data",
    GuildDonate = "GuildDonate.data",
    GuildBuildLevel = "GuildBuildLevel.data",
    GuildConvoy = "GuildConvoy.data",
    GuildDefend = "GuildDefend.data",
    GuildSkill = "GuildSkill.data",
    GuildExpedition = "GuildExpedition.data",
    GuildIcon = "GuildIcon.data",
    GuildLevel = "GuildLevel.data",
    GuildPermission = "GuildPermission.data",
    GuildPrayItem = "GuildPrayItem.data",
    GuildPrayPool = "GuildPrayPool.data",
    GuildRewardPoints = "GuildRewardPoints.data",
    GuildSalary = "GuildSalary.data",
    GuildShop = "GuildShop.data",
    GuildBuff = "GuildBuff.data",
    GuildSmithy = "GuildSmithy.data",
    GuildWareHouseLevel = "GuildWareHouseLevel.data",
    Hearsay = "Hearsay.data",
    Horse = "Horse.data",
    Instance = "Instance.data",
    ItemApproach = "ItemApproach.data",
    ItemMachining = "ItemMachining.data",
    Item = "Item.data",
    LegendaryGroup = "LegendaryGroup.data",
    LegendaryPropertyUpgrade = "LegendaryPropertyUpgrade.data",
    Letter = "Letter.data",
    LevelUpExp = "LevelUpExp.data",
    Liveness = "Liveness.data",
    ManualAnecdote = "ManualAnecdote.data",
    ManualEntrie = "ManualEntrie.data",
    ManualTotalReward = "ManualTotalReward.data",
    Map = "Map.data",
    MarketItem = "MarketItem.data",
    Market = "Market.data",
    MetaFightPropertyConfig = "MetaFightPropertyConfig.data",
    Mine = "Mine.data",
    Money = "Money.data",
    MonsterAffix = "MonsterAffix.data",
    Monster = "Monster.data",
    --MonsterPosition = "MonsterPosition.data",
    --MonsterProperty = "MonsterProperty.data",
    MonthlyCard = "MonthlyCard.data",
    NavigationData = "NavigationData.data",
    Npc = "Npc.data",
    NpcSale = "NpcSale.data",
    NpcShop = "NpcShop.data",
    Obstacle = "Obstacle.data",
    PetLevel = "PetLevel.data",
    Pet = "Pet.data",
    PetQualityInfo = "PetQualityInfo.data",
    PlayerStrongCell = "PlayerStrongCell.data",
    PlayerStrong = "PlayerStrong.data",
    PlayerStrongValue = "PlayerStrongValue.data",
    Profession = "Profession.data",
    PublicDrop = "PublicDrop.data",
    PVP3v3 = "PVP3v3.data",
    QuestChapter = "QuestChapter.data",
    QuestGroup = "QuestGroup.data",
    Quest = {"Quest0.data", "Quest1.data", "Quest2.data", "Quest3.data", "Quest4.data", "Quest5.data", "Quest6.data", "Quest7.data", "Quest8.data"},
    QuickStore = "QuickStore.data",
    Rank = "Rank.data",
    RankReward = "RankReward.data",
    Reputation = "Reputation.data",
    Reward = "Reward.data",
    RuneLevelUp = "RuneLevelUp.data",
    Rune = "Rune.data",
    ScriptCalendar = "ScriptCalendar.data",
    ScriptConfig = "ScriptConfig.data",
    SensitiveWord = "SensitiveWord.data",
    Service = "Service.data",
    Sign = "Sign.data",
    SkillLearnCondition = "SkillLearnCondition.data",
    SkillLevelUpCondition = "SkillLevelUpCondition.data",
    SkillLevelUp = "SkillLevelUp.data",
    Skill = {"Skill0.data", "Skill1.data"},
    SpecialId = "SpecialId.data",
    SkillMastery = "SkillMastery.data",
    State = "State.data",
    Store = "Store.data",
    StoreTag = "StoreTag.data",
    Suit = "Suit.data",
    SystemNotify = "SystemNotify.data",
    TalentGroup = "TalentGroup.data",
    TalentLevelUp = "TalentLevelUp.data",
    Talent = "Talent.data",
    TeamRoomConfig = "TeamRoomConfig.data",
    Text = "Text.data",
    TowerDungeon = "TowerDungeon.data",
    Trans = "Trans.data",
    User = "User.data",
    WingGradeUp = "WingGradeUp.data",
    WingLevelUp = "WingLevelUp.data",
    WingLevelWeight = "WingLevelWeight.data",
    Wing = "Wing.data",
    WingTalentLevel = "WingTalentLevel.data",
    WingTalent = "WingTalent.data",
    WingTalentPage = "WingTalentPage.data",
    WorldBossConfig = "WorldBossConfig.data",
    EquipSurmount = "EquipSurmount.data",
    EquipQuench = "EquipQuench.data",
    EquipInherit = "EquipInherit.data",
    LuckyInforce = "LuckyInforce.data",
    StoneInforce = "StoneInforce.data",
    TaskLuck = "TaskLuck.data",
    DailyTask = "DailyTask.data",
    DailyTaskBox = "DailyTaskBox.data",
    SpecialSign = "SpecialSign.data",
    HotTimeConfigure = "HotTimeConfigure.data",
    DungeonIntroductionPopup = "DungeonIntroductionPopup.data",
    InforceDecompose = "InforceDecompose.data",
    OnlineReward = "OnlineReward.data",
    ExpFind = "ExpFind.data",
    HangQuest = "HangQuest.data",
    GrowthGuidance = "GrowthGuidance.data",
    EliteBossConfig = "EliteBossConfig.data",
    FestivalActivity = "FestivalActivity.data",
}

_G.ResetLanguage = function()

    _G.UserLanguageCode = GameUtil.GetUserLanguageCode()
    _G.UserLanguagePostfix = GameUtil.GetUserLanguagePostfix(false)

    --if true then 
    if _G.UserLanguagePostfix ~= "_KR" then
        _G.UserLanguagePostfix = ""
    end

    GameUtil.SetSoundLanguage("Korean");   --使用GameRes\Audio\GeneratedSoundBanks\Windows下的localize语音

    _G.InterfacesDir = "Assets/Outputs/Interfaces".._G.UserLanguagePostfix.."/"
    _G.CommonAtlasDir = "Assets/Outputs/CommonAtlas/"

    if _G.UserLanguagePostfix == "_KR" then
        GameUtil.UnloadBundle("interfaces")
        GameUtil.UnloadBundle("interfaces_tw")
    elseif _G.UserLanguagePostfix == "" then
        GameUtil.UnloadBundle("interfaces_kr")
        GameUtil.UnloadBundle("interfaces_tw")
    end

    _G.ConfigsDir = "Configs/"
    if _G.UserLanguageCode ~= "CN" then
        _G.ConfigsDir = _G.ConfigsDir.._G.UserLanguageCode.."/"
    end

    warn("<Init LanCode>: ".._G.UserLanguageCode.." <LanPostfix>: ".._G.UserLanguagePostfix)
    warn("<InterfacesDir>: ".._G.InterfacesDir.." <ConfigsDir>: ".._G.ConfigsDir)


    --重新加载路径 受 _G.InterfacesDir 影响
    _G.Unrequire("Data.ResPath")
    require "Data.ResPath"

    --受 _G.ConfigsDir影响
    _G.Unrequire("Data.ConfigsData")
    require "Data.ConfigsData"

    GameUtil.ClearHUDTextFontCache()

    --清除data数据，重新设置data路径
    local CElementData = require "Data.CElementData"
    CElementData.ClearAll()
    GameUtil.ClearAllBaseDataManagers()
    GameUtil.GC(false)
    local MapBasicConfig = require "Data.MapBasicConfig" 
    MapBasicConfig.Reset()

    local basePath = GameUtil.GetResourceBasePath()
    local dataPath = "Data/"
    local localePath = "Data/"
    if _G.UserLanguageCode ~= "CN" then
        dataPath = dataPath.._G.UserLanguageCode.."/"
        localePath = localePath.._G.UserLanguageCode.."/"
    end

    warn("<TemplateBasePath>: "..basePath.." <TemplateBinPath>: "..dataPath.." <TemplateLocalePath>: "..localePath)
    GameUtil.SetTemplatePath(basePath, dataPath, localePath)
end

_G.SetBaseDataManagerPath = function ()
    for name, path in pairs(_G.TemplatePath) do
        GameUtil.SetBaseDataManagerPath(name, path)
    end 
end

_G.PreLoadDataManagers = function ()
    warn(" --PreLoadDataManagers----")
    for name, path in pairs(_G.TemplatePath) do
        GameUtil.PreloadTemplateFile(name)
    end
end

_G.GetConfigsDir = function ()
    return _G.ConfigsDir
end

_G.IsLanguageChanged = function ()
    return _G.UserLanguageCode ~= GameUtil.GetUserLanguageCode() or _G.UserLanguagePostfix ~= GameUtil.GetUserLanguagePostfix(false)
end

_G.ResponseDevice = GameUtil.GetResponseDeviceString()
_G.ResponseOSVersion = GameUtil.GetResponseOSVersionString()
_G.ResponseMACString = GameUtil.GetResponseMACString()

warn("MemoryLimit:", GameUtil.GetLargeMemoryLimit(), GameUtil.GetMemoryLimit())
warn("response Device-OSVersion-MAC:", _G.ResponseDevice, _G.ResponseOSVersion, _G.ResponseMACString)

_G.SetBaseDataManagerPath()
_G.ResetLanguage()
_G.PreLoadDataManagers()
