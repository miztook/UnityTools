local Lplus = require "Lplus"

local NotifyGuildEvent = Lplus.Class("NotifyGuildEvent")
local def = NotifyGuildEvent.define

-- All:全部UI刷新
-- BaseInfo:单纯更新公会基础信息
-- GuildList:公会列表界面
-- MemberInfo:单纯更新公会成员信息
-- BuildingInfo:单纯更新公会建筑信息
-- Create:创建公会
-- ApplyAdd:加入公会申请
-- RefuseAdd:加入申请被拒绝
-- AcceptApply:接收加入公会申请
-- RefuseApply:拒绝加入申请
-- Appoint:设置公会职位
-- KickMember:踢出公会成员
-- Announce:更改公会公告
-- Donate:公会捐献(单纯刷新公会经验、资金、能源等）
-- GuildLevelUp:公会升级
-- GuildBuildingLevelUp:公会建筑升级
-- Quit:重设公会基础信息(包括但不限于玩家脱离公会、玩家被踢出公会等)
-- Dismiss:解散公会
-- Notify:公会通知
-- ApplyAddSuccess:加入公会申请成功
-- FortressApply:要塞报名
-- FortressItem:提交要塞报名道具
-- RecordBase:公会事件;RecordItem:公会道具分配记录
-- AssignItem:公会分配道具
-- DisplayInfo:设置显示信息
-- PointsReward:积分奖励
-- AddGuild:加入公会
-- QuitGuild:退出公会(此时信息还未重置)
-- ClearGuild:退出公会(此时信息已经重置)
-- GuildSkill:查看公会技能信息
-- SkillLevelUp:技能升级
-- BuffOpen:Buff开启
-- BuffSet:Buff设置
-- GuildShop:打开温德商会
-- GuildShopBuy:购买温德商会物品
-- GuildPray:查看许愿池（根据角色ID区分本人还是其他成员）
-- GuildPrayReward:领取祈祷奖励
-- GuildPrayRecord:查看祈祷记录
-- GuildPrayReduce:祈祷加速
-- GuildPrayHelp:祈祷帮助
-- GuildPrayHelpList:查看祈祷帮助列表
-- GuildPrayPut:放置祈祷道具
-- GuildDungeonInfo:异界之门信息
-- GuildDungeonOpen:异界之门开启
-- GuildDungeonEnter:异界之门进入
-- GuildDungeonDamage:异界之门伤害信息
-- GuildConvoyInfo:公会护送信息
-- GuildConvoyApply:公会护送报名
-- GuildConvoyJoin:公会护送参与
-- GuildConvoyMatch:公会护送匹配结果
-- GuildConvoyUpdate:公会护送更新
-- GuildConvoyComplete:公会护送完成
-- GuildConvoyRankInfo:公会护送伤害排名
-- GuildRedPoint:公会红点
-- GuildDefendInfo:公会防守信息
-- GuildDefendUpdate:公会防守更新
-- GuildDefendRoundStart:公会防守开始一波
-- GuildDefendRoundFinish:公会防守完成一波
-- GuildDefendComplete:公会防守完成
-- CloseGuildShop:关闭公会商店(用于部分界面物品刷新)
-- GuildBattleInfo:公会战场信息
-- GuildBattleSign:公会战场报名
-- GuildBattleEnter:公会战场进入
-- GuildBattleUpdate:公会战场小地图信息刷新
-- GuildBattleReward:公会战场奖励
-- GuildBattleDungeon:公会战场左侧任务面板更新
-- GuildSalary:公会工资
def.field("string").Type = ""
def.field("number").Param = 1

NotifyGuildEvent.Commit()
return NotifyGuildEvent
