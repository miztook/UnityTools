local MapInfo = 
{
	MapType = 3,
	Remarks = "大地图2",
	TextDisplayName = "伐木者村",
	Length = 512,
	Width = 512,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "BGM_Map_2/Map_2/Map_2_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Canyon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	PKMode= 1,
	Monster = 
	{
		[11055] = 
		{
			[1] = { x = -91.93, y = 62.44, z = 45.21, name = "第三军团斥候", level = 22, SortID = 4 },
		},
		[11056] = 
		{
			[1] = { x = -88.83, y = 62.19, z = 59.98, name = "第三军团剑士", level = 22, SortID = 5 },
			[2] = { x = -91.79, y = 63.27, z = 31.76, name = "第三军团剑士", level = 22, SortID = 11 },
			[3] = { x = -97.20, y = 64.22, z = 20.31, name = "第三军团剑士", level = 22, SortID = 12 },
		},
		[11058] = 
		{
			[1] = { x = -112.73, y = 62.38, z = 46.10, name = "千夫长", level = 22, SortID = 13 },
		},
		[11057] = 
		{
			[1] = { x = -115.12, y = 62.38, z = 46.27, name = "第三军团术士", level = 22, SortID = 14 },
		},
		[11059] = 
		{
			[1] = { x = -106.36, y = 62.38, z = 44.68, name = "安农狂暴者", level = 22, SortID = 15 },
		},
	},
	Npc = 
	{
		[1108] = 
		{
			[1] = { x = -85.78, y = 63.07, z = 43.63, name = "沙摩尔", SortID = 1 },
		},
		[1021] = 
		{
			[1] = { x = -88.89, y = 62.69, z = 44.48, name = "阿卡尼亚守备军", SortID = 2 },
			[2] = { x = -89.83, y = 62.66, z = 60.58, name = "阿卡尼亚守备军", SortID = 3 },
			[3] = { x = -91.90, y = 63.83, z = 30.36, name = "阿卡尼亚守备军", SortID = 9 },
			[4] = { x = -96.60, y = 63.83, z = 21.94, name = "阿卡尼亚守备军", SortID = 10 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[141] = { x = -93.47, y = 63.86, z = 45.75, name = "西门战斗相位【个人】", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[78] = 
		{
			[1] = { x = -89.81, y = 62.72, z = 64.97 },
			[2] = { x = -95.34, y = 63.90, z = 27.64 },
		},
	},
	Entity = 
	{
		[4] = 
		{
			x = -91.93, y = 62.44, z = 45.21, Type = 1,
			Tid = 
			{
				[11055] = 5,
			},
		},
		[5] = 
		{
			x = -88.83, y = 62.19, z = 59.98, Type = 1,
			Tid = 
			{
				[11056] = 2,
			},
		},
		[11] = 
		{
			x = -91.79, y = 63.27, z = 31.76, Type = 1,
			Tid = 
			{
				[11056] = 2,
			},
		},
		[12] = 
		{
			x = -97.20, y = 64.22, z = 20.31, Type = 1,
			Tid = 
			{
				[11056] = 2,
			},
		},
		[13] = 
		{
			x = -112.73, y = 62.38, z = 46.10, Type = 1,
			Tid = 
			{
				[11058] = 1,
			},
		},
		[14] = 
		{
			x = -115.12, y = 62.38, z = 46.27, Type = 1,
			Tid = 
			{
				[11057] = 3,
			},
		},
		[15] = 
		{
			x = -106.36, y = 62.38, z = 44.68, Type = 1,
			Tid = 
			{
				[11059] = 2,
			},
		},
		[1] = 
		{
			x = -85.78, y = 63.07, z = 43.63, Type = 2,
			Tid = 
			{
				[1108] = 1,
			},
		},
		[2] = 
		{
			x = -88.89, y = 62.69, z = 44.48, Type = 2,
			Tid = 
			{
				[1021] = 2,
			},
		},
		[3] = 
		{
			x = -89.83, y = 62.66, z = 60.58, Type = 2,
			Tid = 
			{
				[1021] = 1,
			},
		},
		[9] = 
		{
			x = -91.90, y = 63.83, z = 30.36, Type = 2,
			Tid = 
			{
				[1021] = 1,
			},
		},
		[10] = 
		{
			x = -96.60, y = 63.83, z = 21.94, Type = 2,
			Tid = 
			{
				[1021] = 1,
			},
		},
		[7] = 
		{
			x = -128.35, y = 62.78, z = 52.96, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[16] = 
		{
			x = -84.24, y = 32.78, z = -50.19, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[17] = 
		{
			x = -78.06, y = 61.26, z = 69.98, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[18] = 
		{
			x = -79.15, y = 64.34, z = 42.57, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[6] = 
		{
			x = -89.81, y = 62.72, z = 64.97, Type = 6,
			Tid = 
			{
				[78] = 1,
			},
		},
		[8] = 
		{
			x = -95.34, y = 63.90, z = 27.64, Type = 6,
			Tid = 
			{
				[78] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 206.82, posy = 48.87, posz = -229.57, rotx = 0.00, roty = 270.27, rotz = 0.00 },
		[2] = { posx = 134.62, posy = 66.38, posz = 240.18, rotx = 0.00, roty = 182.41, rotz = 0.00 },
	},

}
return MapInfo