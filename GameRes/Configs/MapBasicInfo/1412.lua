local MapInfo = 
{
	MapType = 3,
	Remarks = "霍加斯南部",
	TextDisplayName = "圣火仪式【声望】",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	Monster = 
	{
		[50201] = 
		{
			[1] = { x = 300.07, y = 51.98, z = -67.88, name = "黑翼掠夺者", level = 33, SortID = 4, DropItemIds = " " },
		},
		[50202] = 
		{
			[1] = { x = 324.43, y = 48.78, z = -74.86, name = "黑翼祭司", level = 33, SortID = 5, DropItemIds = " " },
		},
		[50203] = 
		{
			[1] = { x = 301.07, y = 52.00, z = -70.05, name = "黑翼大主教", level = 33, SortID = 6, DropItemIds = " " },
		},
		[50204] = 
		{
			[1] = { x = 311.30, y = 48.76, z = -84.44, name = "隐身怪物", level = 33, SortID = 7, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[40301] = 
		{
			[1] = { x = 311.30, y = 44.92, z = -84.44, name = "席坎兰尼", SortID = 1, FunctionName = " " },
		},
		[40302] = 
		{
			[1] = { x = 311.30, y = 48.76, z = -84.44, name = "席坎兰尼", SortID = 2, FunctionName = " " },
		},
		[40303] = 
		{
			[1] = { x = 311.24, y = 48.76, z = -84.19, name = "席坎卫兵", SortID = 8, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[3] = { x = 318.94, y = 48.81, z = -81.63, name = "相位区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[4] = 
		{
			x = 300.07, y = 51.98, z = -67.88, Type = 1,
			Tid = 
			{
				[50201] = 3,
			},
		},
		[5] = 
		{
			x = 324.43, y = 48.78, z = -74.86, Type = 1,
			Tid = 
			{
				[50202] = 3,
			},
		},
		[6] = 
		{
			x = 301.07, y = 52.00, z = -70.05, Type = 1,
			Tid = 
			{
				[50203] = 1,
			},
		},
		[7] = 
		{
			x = 311.30, y = 48.76, z = -84.44, Type = 1,
			Tid = 
			{
				[50204] = 1,
			},
		},
		[1] = 
		{
			x = 311.30, y = 44.92, z = -84.44, Type = 2,
			Tid = 
			{
				[40301] = 1,
			},
		},
		[2] = 
		{
			x = 311.30, y = 48.76, z = -84.44, Type = 2,
			Tid = 
			{
				[40302] = 1,
			},
		},
		[8] = 
		{
			x = 311.24, y = 48.76, z = -84.19, Type = 2,
			Tid = 
			{
				[40303] = 4,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo