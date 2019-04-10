--[[
1.此表以客户端&服务器 红点功能枚举 罗列
2.设置功能Icon & 优先级 等【不长修改的信息】
EGuideTriggerFunTag =     --功能标识
{
    Task                = 0, --任务
    Skill               = 1, --技能
    Pet                 = 2, --宠物
    Mount               = 3, --坐骑
    Dungeon             = 4, --副本
    Achievement         = 5, --成就
    Guild               = 6, --工会
    Activity            = 7, --活动
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

]]

local SystemEntranceCfg = 
{
--左侧
    [30] = {  Name = "信息",    IconPath = "System_CharacterInformation",   Priority = 0, },     --角色
    [0] =  {  Name = "任务",    IconPath = "System_Task",   Priority = 2, },    --任务
    [1]  = {  Name = "技能",    IconPath = "System_Skill",   Priority = 1, },     --技能    
	[32] = {  Name = "外观",    IconPath = "System_Appearence",   Priority = 4, },     --外观
    [31] = {  Name = "加工",    IconPath = "System_Processing",   Priority = 5, },     --装备   
    [48] = {  Name = "飞翼",    IconPath = "System_Wing",   Priority = 24, },    --翅膀养成
    [2]  = {  Name = "宠物",    IconPath = "System_Pet",   Priority = 6, },     --宠物
    [11] = {  Name = "神符",    IconPath = "System_Magic",   Priority = 7, },     --神符
    
    [34] = {  Name = "商店",    IconPath = "System_Shop",   Priority = 8, },     --商店
    [43] = {  Name = "生涯",    IconPath = "System_Museum",   Priority = 3, },    --荣誉
    [6]  = {  Name = "公会",    IconPath = "System_Guild",   Priority = 9, },     --公会    
    [33] = {  Name = "排行",    IconPath = "System_Ranking",   Priority = 10, },     --排行榜
    [35] = {  Name = "设置",    IconPath = "System_Setting",   Priority = 11, },    --设置

    [38] = {  Name = "福利",    IconPath = "System_Welfare",   Priority = 23, },    --福利
    [49] = {  Name = "指南",    IconPath = "System_Activity",   Priority = 22, },    --指南
    [7] =  {  Name = "冒险",    IconPath = "System_Calendar",   Priority = 21, },    --冒险
    [19] = {  Name = "商城",    IconPath = "System_Mall",   Priority = 20, },    --商城

    [37] = {  Name = "交易",    IconPath = "System_Auction",   Priority = 25, },    --交易  
    
    
}

return SystemEntranceCfg