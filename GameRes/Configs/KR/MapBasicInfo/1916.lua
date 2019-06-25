local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "트레이쿤 플랫폼【스토리】",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_019.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[13118] = 
		{
			[1] = { x = -224.51, y = 95.01, z = 330.29, name = "", level = 40, SortID = 11 },
		},
	},
	Npc = 
	{
		[4211] = 
		{
			[1] = { x = -185.20, y = 95.01, z = 323.30, name = "데바 정예 병사", SortID = 2 },
		},
		[4214] = 
		{
			[1] = { x = -207.00, y = 95.00, z = 331.74, name = "제국 흑마법사", SortID = 1 },
			[2] = { x = -230.53, y = 95.11, z = 340.90, name = "제국 흑마법사", SortID = 7 },
		},
		[4212] = 
		{
			[1] = { x = -228.43, y = 95.01, z = 339.98, name = "웨이즈 커 나로프레", SortID = 3 },
		},
		[4209] = 
		{
			[1] = { x = -218.85, y = 95.01, z = 344.18, name = "디포", SortID = 4 },
		},
		[4208] = 
		{
			[1] = { x = -221.52, y = 95.11, z = 337.42, name = "바네사 드페라", SortID = 5 },
		},
		[4213] = 
		{
			[1] = { x = -224.54, y = 95.01, z = 330.17, name = "케스타닉인", SortID = 6 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[465] = { x = -172.91, y = 95.12, z = 340.35, name = "塔雷坤相关相位", worldId = 0, PkMode = 0 },
			[466] = { x = -213.69, y = 95.01, z = 334.57, name = "抵达区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[11] = 
		{
			x = -224.51, y = 95.01, z = 330.29, Type = 1,
			Tid = 
			{
				[13118] = 1,
			},
		},
		[2] = 
		{
			x = -185.20, y = 95.01, z = 323.30, Type = 2,
			Tid = 
			{
				[4211] = 8,
			},
		},
		[1] = 
		{
			x = -207.00, y = 95.00, z = 331.74, Type = 2,
			Tid = 
			{
				[4214] = 8,
			},
		},
		[3] = 
		{
			x = -228.43, y = 95.01, z = 339.98, Type = 2,
			Tid = 
			{
				[4212] = 1,
			},
		},
		[4] = 
		{
			x = -218.85, y = 95.01, z = 344.18, Type = 2,
			Tid = 
			{
				[4209] = 1,
			},
		},
		[5] = 
		{
			x = -221.52, y = 95.11, z = 337.42, Type = 2,
			Tid = 
			{
				[4208] = 1,
			},
		},
		[6] = 
		{
			x = -224.54, y = 95.01, z = 330.17, Type = 2,
			Tid = 
			{
				[4213] = 1,
			},
		},
		[7] = 
		{
			x = -230.53, y = 95.11, z = 340.90, Type = 2,
			Tid = 
			{
				[4214] = 4,
			},
		},
		[8] = 
		{
			x = -253.80, y = 97.64, z = 273.71, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[9] = 
		{
			x = -142.94, y = 83.62, z = 305.55, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[10] = 
		{
			x = -232.32, y = 95.04, z = 342.04, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -194.26, posy = 17.74, posz = -225.53, rotx = 0.00, roty = 139.21, rotz = 0.00 },
		[2] = { posx = 94.27, posy = 24.21, posz = -355.41, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -219.57, posy = 17.74, posz = -307.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -133.07, posy = 17.74, posz = -330.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = 99.12, posy = 58.14, posz = -38.31, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[8] = { posx = -202.10, posy = 17.89, posz = -289.19, rotx = 0.00, roty = 215.75, rotz = 0.00 },
		[9] = { posx = -208.09, posy = 60.17, posz = 69.76, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo
