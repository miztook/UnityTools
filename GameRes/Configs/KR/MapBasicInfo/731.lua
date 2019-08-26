local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "오염된 샘 구멍",
	Length = 511,
	Width = 511,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	PKMode= 1,
	Monster = 
	{
		[50010] = 
		{
			[1] = { x = -45.38, y = 61.63, z = 205.08, name = "검붉은 타조", level = 10, SortID = 1 },
			[2] = { x = -65.67, y = 60.65, z = 186.36, name = "검붉은 타조", level = 10, SortID = 3 },
			[3] = { x = -39.85, y = 62.44, z = 175.06, name = "검붉은 타조", level = 10, SortID = 5 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "검붉은 타조", level = 10, SortID = 8 },
		},
		[50011] = 
		{
			[1] = { x = -45.38, y = 61.63, z = 205.08, name = "난폭한 세이버투스", level = 10, SortID = 1 },
			[2] = { x = -65.67, y = 60.65, z = 186.36, name = "난폭한 세이버투스", level = 10, SortID = 3 },
			[3] = { x = -39.85, y = 62.44, z = 175.06, name = "난폭한 세이버투스", level = 10, SortID = 5 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "난폭한 세이버투스", level = 10, SortID = 8 },
		},
		[50012] = 
		{
			[1] = { x = -45.38, y = 61.63, z = 205.08, name = "유니콘", level = 10, SortID = 1 },
			[2] = { x = -65.67, y = 60.65, z = 186.36, name = "유니콘", level = 10, SortID = 3 },
			[3] = { x = -39.85, y = 62.44, z = 175.06, name = "유니콘", level = 10, SortID = 5 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "유니콘", level = 10, SortID = 8 },
		},
		[50013] = 
		{
			[1] = { x = -56.05, y = 61.85, z = 204.01, name = "그림자 쿠거", level = 10, SortID = 2 },
			[2] = { x = -54.29, y = 64.65, z = 174.51, name = "그림자 쿠거", level = 10, SortID = 4 },
			[3] = { x = -60.98, y = 62.36, z = 196.97, name = "그림자 쿠거", level = 10, SortID = 6 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "그림자 쿠거", level = 10, SortID = 8 },
		},
		[50031] = 
		{
			[1] = { x = -56.05, y = 61.85, z = 204.01, name = "뿔 육지거북", level = 10, SortID = 2 },
			[2] = { x = -54.29, y = 64.65, z = 174.51, name = "뿔 육지거북", level = 10, SortID = 4 },
			[3] = { x = -60.98, y = 62.36, z = 196.97, name = "뿔 육지거북", level = 10, SortID = 6 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "뿔 육지거북", level = 10, SortID = 8 },
		},
		[50032] = 
		{
			[1] = { x = -56.05, y = 61.85, z = 204.01, name = "매머드", level = 10, SortID = 2 },
			[2] = { x = -54.29, y = 64.65, z = 174.51, name = "매머드", level = 10, SortID = 4 },
			[3] = { x = -60.98, y = 62.36, z = 196.97, name = "매머드", level = 10, SortID = 6 },
			[4] = { x = -32.36, y = 61.84, z = 197.79, name = "매머드", level = 10, SortID = 8 },
		},
		[50014] = 
		{
			[1] = { x = -35.78, y = 61.94, z = 194.91, name = "바실리스크", level = 10, SortID = 7 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[5] = { x = -46.92, y = 61.84, z = 190.50, name = "刷挂区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -45.38, y = 61.63, z = 205.08, Type = 1,
			Tid = 
			{
				[50010] = 5,
				[50011] = 5,
				[50012] = 5,
			},
		},
		[2] = 
		{
			x = -56.05, y = 61.85, z = 204.01, Type = 1,
			Tid = 
			{
				[50013] = 5,
				[50031] = 5,
				[50032] = 5,
			},
		},
		[3] = 
		{
			x = -65.67, y = 60.65, z = 186.36, Type = 1,
			Tid = 
			{
				[50010] = 5,
				[50011] = 5,
				[50012] = 5,
			},
		},
		[4] = 
		{
			x = -54.29, y = 64.65, z = 174.51, Type = 1,
			Tid = 
			{
				[50013] = 5,
				[50031] = 5,
				[50032] = 5,
			},
		},
		[5] = 
		{
			x = -39.85, y = 62.44, z = 175.06, Type = 1,
			Tid = 
			{
				[50010] = 5,
				[50011] = 5,
				[50012] = 5,
			},
		},
		[6] = 
		{
			x = -60.98, y = 62.36, z = 196.97, Type = 1,
			Tid = 
			{
				[50013] = 5,
				[50031] = 5,
				[50032] = 5,
			},
		},
		[7] = 
		{
			x = -35.78, y = 61.94, z = 194.91, Type = 1,
			Tid = 
			{
				[50014] = 1,
			},
		},
		[8] = 
		{
			x = -32.36, y = 61.84, z = 197.79, Type = 1,
			Tid = 
			{
				[50010] = 4,
				[50011] = 4,
				[50012] = 4,
				[50013] = 4,
				[50031] = 4,
				[50032] = 4,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -66.25, posy = 61.84, posz = 206.15, rotx = 0.00, roty = 40.00, rotz = 0.00 },
	},

}
return MapInfo
