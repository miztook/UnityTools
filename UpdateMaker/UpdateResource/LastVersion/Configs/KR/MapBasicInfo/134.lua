local MapInfo = 
{
	MapType = 3,
	Remarks = "大地图2",
	TextDisplayName = "벌레의 시험",
	Length = 600,
	Width = 600,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "BGM_Map_2/Map_2/Map_2_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	PKMode= 1,
	Monster = 
	{
		[11016] = 
		{
			[1] = { x = -139.07, y = 61.38, z = -262.30, name = "독충", level = 23, SortID = 8 },
		},
		[11018] = 
		{
			[1] = { x = -118.25, y = 62.61, z = -250.01, name = "송곳니 세이버투스", level = 23, SortID = 5 },
		},
		[11015] = 
		{
			[1] = { x = -130.31, y = 61.09, z = -257.30, name = "비틀린 길리두", level = 23, SortID = 11 },
		},
	},
	Npc = 
	{
		[1174] = 
		{
			[1] = { x = -137.79, y = 62.68, z = -247.63, name = "바바카 후카", SortID = 3 },
		},
		[1083] = 
		{
			[1] = { x = -151.31, y = 62.80, z = -252.09, name = "바바 후카", SortID = 4 },
			[2] = { x = -144.37, y = 62.80, z = -246.28, name = "바바 후카", SortID = 6 },
			[3] = { x = -130.92, y = 62.80, z = -240.18, name = "바바 후카", SortID = 7 },
			[4] = { x = -144.37, y = 62.80, z = -246.28, name = "바바 후카", SortID = 9 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[181] = { x = -131.27, y = 93.16, z = -256.16, name = "皮虫试炼相位【个人】", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[8] = 
		{
			x = -139.07, y = 61.38, z = -262.30, Type = 1,
			Tid = 
			{
				[11016] = 4,
			},
		},
		[5] = 
		{
			x = -118.25, y = 62.61, z = -250.01, Type = 1,
			Tid = 
			{
				[11018] = 2,
			},
		},
		[11] = 
		{
			x = -130.31, y = 61.09, z = -257.30, Type = 1,
			Tid = 
			{
				[11015] = 1,
			},
		},
		[3] = 
		{
			x = -137.79, y = 62.68, z = -247.63, Type = 2,
			Tid = 
			{
				[1174] = 1,
			},
		},
		[4] = 
		{
			x = -151.31, y = 62.80, z = -252.09, Type = 2,
			Tid = 
			{
				[1083] = 1,
			},
		},
		[6] = 
		{
			x = -144.37, y = 62.80, z = -246.28, Type = 2,
			Tid = 
			{
				[1083] = 1,
			},
		},
		[7] = 
		{
			x = -130.92, y = 62.80, z = -240.18, Type = 2,
			Tid = 
			{
				[1083] = 1,
			},
		},
		[9] = 
		{
			x = -144.37, y = 62.80, z = -246.28, Type = 2,
			Tid = 
			{
				[1083] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
