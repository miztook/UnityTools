local CommandList = {}


local list = {}
function CommandList:GetAllCommandList ()
	return list
end

function CommandList:AddCommandInfo()
	return function (command_info)
		list[#list + 1] = command_info
	end
end


-- TO DO : 1、角色,单位 2、物品 3、生成器 4、调试 5、任务 6、地图 7、掉落 8、公会、CG相关  9、副本
CommandList:AddCommandInfo()
{
	name = "升级",
	cmd = "c 22 0 ",
	desc = "C 22 0 等级（等级可为负数，表示降低等级）",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "自杀",
	cmd = "c 41", 
	desc = "C 41",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "属性",
	cmd = "c 74", 
	desc = "C 74 属性id 属性值增加量",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "debug模式",
	cmd = "debugOpen ", 
	desc = "debugOpen 0/1 0关闭，1打开，控制debug模式的开关",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "增减金币",
	cmd = "c 23 1 ", 
	desc = "C 23 1 数量",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "增减钻石",
	cmd = "c 23 2 ", 
	desc = "C 23 2 数量",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "增减绑钻",
	cmd = "c 23 3 ", 
	desc = "C 23 3 数量",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "增加物品(装备)",
	cmd = "c 31 ", 
	desc = "C 31 物品ID  数量",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "删除物品(装备)",
	cmd = "c 32 ", 
	desc = "C 32 背包格子（0开始） 数量",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "使用物品",
	cmd = "c 37 ", 
	desc = "c 37 背包格子（1开始）",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "怪物",
	cmd = "c 1 ", 
	desc = "C 1 怪物ID 数量",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "NPC",
	cmd = "c 2 ", 
	desc = "C 2 NPC_ID 数量",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "可采集物",
	cmd = "c 3 ", 
	desc = "C 3 可采集单位ID 数量",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "坐骑",
	cmd = "c 100 ", 
	desc = "C 100 坐骑单位ID 数量",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "扫视野",
	cmd = "c 364", 
	desc = "C 364",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "查看生成器",
	cmd = "c 369 ", 
	desc = "C 369 生成器ID",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "生成器怪物巡逻切换",
	cmd = "c 366 ", 
	desc = "C 366 生成器ID 1 路径ID",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "激活生成器",
	cmd = "c 366 ", 
	desc = "C 366 生成器ID 2",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "反激活生成器",
	cmd = "c 366 ", 
	desc = "C 366 生成器ID 3",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "navmesh",
	cmd = "navmesh ", 
	desc = "navmesh 0/1",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "临时功能全开",
	cmd = "FunOpen 1", 
	desc = "FunOpen 0/1 0关闭，1打开，关闭游戏后失效",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "教学",
	cmd = "GuideOpen 1", 
	desc = "GuideOpen 0/1 0关闭，1打开",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "活动",
	cmd = "c 103 2 ", 
	desc = "c 103 2 活动id 增加次数",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "显隐regionset",
	cmd = "regionset ", 
	desc = "regionset 0/<地图id> (MapInfo拷贝到GameRes下)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "显隐obstacleset",
	cmd = "obstacleset ", 
	desc = "obstacleset 0/<地图id> (MapInfo拷贝到GameRes下)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "打印C2S",
	cmd = "logc2s ", 
	desc = "logc2s 0/1 1显示，0隐藏 客户端协议",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "打印S2C",
	cmd = "logs2c ", 
	desc = "logs2c 0/1 1显示，0隐藏 服务器协议",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "显隐当前UI",
	cmd = "showui ", 
	desc = "showui 0/1 1显示，0隐藏",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "播放Npc语音",
	cmd = "playvoice ", 
	desc = "playvoice <name>",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "播放BGM",
	cmd = "playbgm ", 
	desc = "playbgm <name>",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "播放3D音效",
	cmd = "playaudio3d ", 
	desc = "playaudio3d <name> [distance]",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "播放2D音效",
	cmd = "playaudio2d ", 
	desc = "playaudio2d <name>",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "请求Camera权限",
	cmd = "reqcamerapermission", 
	desc = "reqcamerapermission",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "请求Photo权限",
	cmd = "reqphotopermission", 
	desc = "reqphotopermission",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "游戏参数",
	cmd = "stats ", 
	desc = "stats (1-7) 0/1 1开，0关",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "游戏性能调试",
	cmd = "perfs ", 
	desc = "perfs (1-4) 0/1 1开，0关",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "后处理开关",
	cmd = "postprocess ", 
	desc = "postprocess 0/1 1开，0关",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "服务器调试模式",
	cmd = "C 400 ", 
	desc = "c 400 断线时间间隔",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "添加状态",
	cmd = "C 83 ", 
	desc = "c 83 状态ID 0/1(0默认不写为自己,1为other)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "显隐属性",
	cmd = "C 500 ", 
	desc = "c 500 设置自身显隐属性",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "打印event统计",
	cmd = "logevent", 
	desc = "logevent",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "打印timer统计",
	cmd = "logtimer", 
	desc = "logtimer",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "查看角色信息",
	cmd = "c 206 ", 
	desc = "c 206 角色ID",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "根据账号名字踢用户下线",
	cmd = "c 450 ", 
	desc = "c 450 账号Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "根据账号名字查用户信息",
	cmd = "c 451 ", 
	desc = "c 451 账号Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "根据角色名字查用户信息",
	cmd = "c 452 ", 
	desc = "c 452 角色Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "查询当前视野内的用户信息",
	cmd = "c 453", 
	desc = "c 453 查询当前视野内的用户信息",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "自动穿装备",
	cmd = "c 359", 
	desc = "c 359 装备等级",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "添加一封邮件",
	cmd = "c 90 1 1 1", 
	desc = "c 90 1 1 1",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "查看任务的激活状态",
	cmd = "c 64 ", 
	desc = "C 64 任务ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "领取任务",
	cmd = "c 61 ", 
	desc = "C 61 任务ID 1（无条件领取）",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "放弃任务",
	cmd = "c 62 ", 
	desc = "C 62 任务ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "完成任务的所有目标",
	cmd = "c 63 ", 
	desc = "C 63 任务ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "已完成任务的状态",
	cmd = "c 59 ", 
	desc = "c 59 任务id 已完成任务的状态",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "无条件交付任务",
	cmd = "c 60 ", 
	desc = "c 60 任务id 无条件交付任务",
	type = 5,
}


CommandList:AddCommandInfo()
{
	name = "传送到本场景指定坐标",
	cmd = "c 51 ", 
	desc = "c 51 x y",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "调整移动速度",
	cmd = "c 71 ", 
	desc = "c 71 速度",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "世界",
	cmd = "c 81 ", 
	desc = "c 81 地图id x坐标 z坐标 可以传送的世界信息ID，列表可选，确认后进入该世界",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "副本",
	cmd = "c 69 0 ",
	desc = "c 69 0 副本id 可以传送的副本信息ID，列表可选，确认后进入该副本" ,
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "掉落",
	cmd = "c 66 ", 
	desc = "C 66 怪物ID 怪物数量 怪物数量是几，就表示对这个怪物的掉落执行几次",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "查看掉落",
	cmd = "c 66 666 666", 
	desc = "显示服务器掉落物创建，销毁，拾取数量",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "删除掉落",
	cmd = "c 66 777 777", 
	desc = "删除自己的掉落",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "清除统计数据",
	cmd = "c 66 888 888", 
	desc = "清除666相关的统计数据",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "显示统计数据",
	cmd = "c 66 -999 ", 
	desc = "c 66 -999 怪物ID 显示统计数据 怪物的击杀次数，以及掉落统计数据",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "一键满级",
	cmd = "c 22 0 100", 
	desc = "c 22 0 最大等级",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "一键秒怪",
	cmd = "c 73", 
	desc = "c 73 一键杀死视野内的怪",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "背包全开",
	cmd = "c 358", 
	desc = "c 358 背包全开",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "公会基地",
	cmd = "c 110", 
	desc = "c 110 公会基地",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "公会仓库",
	cmd = "c 111 ", 
	desc = "c 111 道具ID 数量",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "CG播放",
	cmd = "c 102 ", 
	desc = "c 102 资源ID",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "纹章",
	cmd = "c 200 ", 
	desc = "c 200 纹章index",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "创建镜像",
	cmd = "C 121 ", 
	desc = "c 121 角色id",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "进入副本",
	cmd = "C 69 0 ", 
	desc = "C 69 0 副本Id 进入副本",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "离开副本",
	cmd = "C 69 1", 
	desc = "C 69 1 离开当前副本",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "重置副本次数",
	cmd = "C 69 777", 
	desc = "C 69 777 重置所有副本次数",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "增加进入副本次数",
	cmd = "C 69 777 ", 
	desc = "C 69 777 副本Id 次数",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "导出当前副本Log",
	cmd = "C 69 666", 
	desc = "C 69 666 导出当前副本Log",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "跳转到结算",
	cmd = "C 69 999", 
	desc = "C 69 999 副本直接跳转到结算",
	type = 9,
}

return CommandList
