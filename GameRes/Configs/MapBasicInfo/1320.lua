local MapInfo = 
{
	MapType = 3,
	Remarks = "大地图2",
	TextDisplayName = "巨人碑石",
	Length = 600,
	Width = 600,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	Monster = 
	{
		[14227] = 
		{
			[1] = { x = -27.72, y = 65.49, z = -240.77, name = "腐化库摩斯", level = 53, SortID = 1, DropItemIds = " " },
		},
		[14225] = 
		{
			[1] = { x = -31.06, y = 64.37, z = -160.91, name = "暴虐毒蜂", level = 53, SortID = 3, DropItemIds = " " },
			[2] = { x = -27.28, y = 64.67, z = -179.49, name = "暴虐毒蜂", level = 53, SortID = 4, DropItemIds = " " },
			[3] = { x = -29.47, y = 64.09, z = -197.35, name = "暴虐毒蜂", level = 53, SortID = 8, DropItemIds = " " },
		},
		[14226] = 
		{
			[1] = { x = -29.77, y = 63.99, z = -217.12, name = "暴虐剑齿虎", level = 53, SortID = 9, DropItemIds = " " },
			[2] = { x = -30.16, y = 65.87, z = -223.87, name = "暴虐剑齿虎", level = 53, SortID = 10, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[4227] = 
		{
			[1] = { x = -54.74, y = 67.22, z = -153.68, name = "槌子", SortID = 200, FunctionName = " " },
		},
		[1039] = 
		{
			[1] = { x = -43.71, y = 64.94, z = -158.07, name = "槌子霍卡卫兵", SortID = 2, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[149] = { x = -35.91, y = 72.23, z = -204.61, name = "库摩斯相位【个人】", worldId = 0, PkMode = 0 },
			[559] = { x = -35.35, y = 68.35, z = -245.95, name = "鹰眼", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {4512} },
		},
	},
	Mine = 
	{
		[853] = 
		{
			[1] = { x = -35.02, y = 65.97, z = -245.02 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = -27.72, y = 65.49, z = -240.77, Type = 1,
			Tid = 
			{
				[14227] = 1,
			},
		},
		[3] = 
		{
			x = -31.06, y = 64.37, z = -160.91, Type = 1,
			Tid = 
			{
				[14225] = 8,
			},
		},
		[4] = 
		{
			x = -27.28, y = 64.67, z = -179.49, Type = 1,
			Tid = 
			{
				[14225] = 8,
			},
		},
		[8] = 
		{
			x = -29.47, y = 64.09, z = -197.35, Type = 1,
			Tid = 
			{
				[14225] = 8,
			},
		},
		[9] = 
		{
			x = -29.77, y = 63.99, z = -217.12, Type = 1,
			Tid = 
			{
				[14226] = 8,
			},
		},
		[10] = 
		{
			x = -30.16, y = 65.87, z = -223.87, Type = 1,
			Tid = 
			{
				[14226] = 8,
			},
		},
		[200] = 
		{
			x = -54.74, y = 67.22, z = -153.68, Type = 2,
			Tid = 
			{
				[4227] = 1,
			},
		},
		[2] = 
		{
			x = -43.71, y = 64.94, z = -158.07, Type = 2,
			Tid = 
			{
				[1039] = 8,
			},
		},
		[7] = 
		{
			x = -35.02, y = 65.97, z = -245.02, Type = 6,
			Tid = 
			{
				[853] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo