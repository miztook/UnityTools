local params = {}

params.SearchRadius = 25           -- 自动战斗半径
params.DungeonSearchRadius = 50          -- 自动战斗半径 副本
params.guard_radius = 20            -- 挂机半径
params.JumpDistance = 5             -- 弓手等逃脱技能释放距离

--Warrior = 1,
--Aileen = 2,
--Assassin = 3,
--Archer = 4,
--Lancer = 5,

params.SkillsList =              -- 技能列表
{
    [1] = {34,37,32,33,38,39,35,31},
    [2] = {41,42,9,43,10,44,45,46},
    [3] = {25,24,18,23,22,21,26,54},
    [4] = {51,52,50,49,48,28,53,55},
	[5] = {132,133,136,134,137,135,138,131},
}

params.ChangedSkillsIndex =              -- 变身技能列表
{
	2,3,4,5,6,1,
}

params.MovableSkills =             --释放时能同时位移的技能
{
    33
}
-- params.skill_duration = 0.5         --技能的释放间隔
return params