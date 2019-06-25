local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "塔兰罗斯要塞",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part1.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Military",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-1.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part1.prefab",
	Monster = 
	{
		[13019] = 
		{
			[1] = { x = 22.96, y = 60.68, z = 19.78, name = "沙行者", level = 41, SortID = 18 },
		},
		[13018] = 
		{
			[1] = { x = 80.76, y = 59.46, z = 6.67, name = "沙行者勇者", level = 41, SortID = 29 },
		},
	},
	Npc = 
	{
		[3009] = 
		{
			[1] = { x = 34.88, y = 60.68, z = 21.19, name = "高等精灵卫兵", SortID = 10 },
			[2] = { x = 33.58, y = 60.69, z = 14.06, name = "高等精灵卫兵", SortID = 15 },
			[3] = { x = 14.50, y = 61.59, z = 49.02, name = "高等精灵卫兵", SortID = 25 },
			[4] = { x = 14.28, y = 64.39, z = 77.01, name = "高等精灵卫兵", SortID = 19 },
			[5] = { x = 30.17, y = 62.76, z = 69.49, name = "高等精灵卫兵", SortID = 20 },
			[6] = { x = 60.69, y = 60.80, z = 15.53, name = "高等精灵卫兵", SortID = 22 },
		},
		[3028] = 
		{
			[1] = { x = 39.07, y = 60.68, z = 20.38, name = "高等精灵射手", SortID = 14 },
			[2] = { x = 38.11, y = 60.69, z = 13.54, name = "高等精灵射手", SortID = 16 },
			[3] = { x = 62.94, y = 60.75, z = 15.28, name = "高等精灵射手", SortID = 21 },
			[4] = { x = 48.72, y = 60.84, z = 9.24, name = "高等精灵射手", SortID = 23 },
		},
		[3010] = 
		{
			[1] = { x = 94.06, y = 60.43, z = 2.38, name = "坎帕索", SortID = 17 },
		},
		[3077] = 
		{
			[1] = { x = 20.29, y = 62.38, z = 70.98, name = "塔列昂", SortID = 1 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[285] = { x = 48.83, y = 63.51, z = 30.17, name = "塔兰罗斯要塞", worldId = 0, PkMode = 0 },
			[292] = { x = 22.21, y = 61.53, z = 38.89, name = "抵达区域1-塔兰罗斯要塞", worldId = 0, PkMode = 0 },
			[293] = { x = 71.50, y = 60.40, z = 8.80, name = "抵达区域2-塔兰罗斯要塞", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[18] = 
		{
			x = 22.96, y = 60.68, z = 19.78, Type = 1,
			Tid = 
			{
				[13019] = 3,
			},
		},
		[29] = 
		{
			x = 80.76, y = 59.46, z = 6.67, Type = 1,
			Tid = 
			{
				[13018] = 1,
			},
		},
		[10] = 
		{
			x = 34.88, y = 60.68, z = 21.19, Type = 2,
			Tid = 
			{
				[3009] = 3,
			},
		},
		[14] = 
		{
			x = 39.07, y = 60.68, z = 20.38, Type = 2,
			Tid = 
			{
				[3028] = 2,
			},
		},
		[15] = 
		{
			x = 33.58, y = 60.69, z = 14.06, Type = 2,
			Tid = 
			{
				[3009] = 1,
			},
		},
		[16] = 
		{
			x = 38.11, y = 60.69, z = 13.54, Type = 2,
			Tid = 
			{
				[3028] = 1,
			},
		},
		[17] = 
		{
			x = 94.06, y = 60.43, z = 2.38, Type = 2,
			Tid = 
			{
				[3010] = 1,
			},
		},
		[25] = 
		{
			x = 14.50, y = 61.59, z = 49.02, Type = 2,
			Tid = 
			{
				[3009] = 6,
			},
		},
		[19] = 
		{
			x = 14.28, y = 64.39, z = 77.01, Type = 2,
			Tid = 
			{
				[3009] = 1,
			},
		},
		[20] = 
		{
			x = 30.17, y = 62.76, z = 69.49, Type = 2,
			Tid = 
			{
				[3009] = 1,
			},
		},
		[21] = 
		{
			x = 62.94, y = 60.75, z = 15.28, Type = 2,
			Tid = 
			{
				[3028] = 1,
			},
		},
		[22] = 
		{
			x = 60.69, y = 60.80, z = 15.53, Type = 2,
			Tid = 
			{
				[3009] = 1,
			},
		},
		[23] = 
		{
			x = 48.72, y = 60.84, z = 9.24, Type = 2,
			Tid = 
			{
				[3028] = 1,
			},
		},
		[1] = 
		{
			x = 20.29, y = 62.38, z = 70.98, Type = 2,
			Tid = 
			{
				[3077] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 166.67, posy = 49.24, posz = 276.08, rotx = 0.00, roty = 156.85, rotz = 0.00 },
		[2] = { posx = -65.74, posy = 21.54, posz = -259.30, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -198.64, posy = 31.32, posz = -223.06, rotx = 0.00, roty = 77.57, rotz = 0.00 },
	},

}
return MapInfo
