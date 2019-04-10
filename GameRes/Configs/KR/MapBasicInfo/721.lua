local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "농장 수비",
	Length = 511,
	Width = 511,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	Monster = 
	{
		[50000] = 
		{
			[1] = { x = 18.05, y = 51.99, z = 18.80, name = "제국 정찰병", level = 20, SortID = 1 },
			[2] = { x = -6.70, y = 52.96, z = 16.28, name = "제국 정찰병", level = 20, SortID = 3 },
			[3] = { x = -14.00, y = 51.30, z = 27.20, name = "제국 정찰병", level = 20, SortID = 6 },
		},
		[50001] = 
		{
			[1] = { x = 18.05, y = 51.99, z = 18.80, name = "제국 검투사", level = 20, SortID = 1 },
			[2] = { x = -6.70, y = 52.96, z = 16.28, name = "제국 검투사", level = 20, SortID = 3 },
			[3] = { x = 22.50, y = 50.47, z = 29.60, name = "제국 검투사", level = 20, SortID = 5 },
			[4] = { x = 3.17, y = 53.08, z = 9.08, name = "제국 검투사", level = 20, SortID = 8 },
		},
		[50002] = 
		{
			[1] = { x = 18.58, y = 51.03, z = 49.71, name = "제국 흑마법사", level = 20, SortID = 2 },
			[2] = { x = -10.20, y = 51.11, z = 46.40, name = "제국 흑마법사", level = 20, SortID = 4 },
			[3] = { x = -14.00, y = 51.30, z = 27.20, name = "제국 흑마법사", level = 20, SortID = 6 },
			[4] = { x = 3.17, y = 53.08, z = 9.08, name = "제국 흑마법사", level = 20, SortID = 8 },
		},
		[50029] = 
		{
			[1] = { x = 18.58, y = 51.03, z = 49.71, name = "데바 전사", level = 22, SortID = 2 },
			[2] = { x = -10.20, y = 51.11, z = 46.40, name = "데바 전사", level = 22, SortID = 4 },
		},
		[50003] = 
		{
			[1] = { x = 22.50, y = 50.47, z = 29.60, name = "노예 용사", level = 21, SortID = 5 },
		},
		[50004] = 
		{
			[1] = { x = 3.10, y = 52.87, z = 11.30, name = "제국 창기사", level = 23, SortID = 7 },
		},
		[50030] = 
		{
			[1] = { x = 3.10, y = 52.87, z = 11.30, name = "데바 암살자", level = 23, SortID = 7 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[4] = { x = 3.68, y = 51.61, z = 28.59, name = "刷挂区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 18.05, y = 51.99, z = 18.80, Type = 1,
			Tid = 
			{
				[50000] = 5,
				[50001] = 5,
			},
		},
		[2] = 
		{
			x = 18.58, y = 51.03, z = 49.71, Type = 1,
			Tid = 
			{
				[50002] = 5,
				[50029] = 5,
			},
		},
		[3] = 
		{
			x = -6.70, y = 52.96, z = 16.28, Type = 1,
			Tid = 
			{
				[50000] = 5,
				[50001] = 5,
			},
		},
		[4] = 
		{
			x = -10.20, y = 51.11, z = 46.40, Type = 1,
			Tid = 
			{
				[50002] = 5,
				[50029] = 5,
			},
		},
		[5] = 
		{
			x = 22.50, y = 50.47, z = 29.60, Type = 1,
			Tid = 
			{
				[50003] = 5,
				[50001] = 5,
			},
		},
		[6] = 
		{
			x = -14.00, y = 51.30, z = 27.20, Type = 1,
			Tid = 
			{
				[50002] = 5,
				[50000] = 5,
			},
		},
		[7] = 
		{
			x = 3.10, y = 52.87, z = 11.30, Type = 1,
			Tid = 
			{
				[50004] = 1,
				[50030] = 1,
			},
		},
		[8] = 
		{
			x = 3.17, y = 53.08, z = 9.08, Type = 1,
			Tid = 
			{
				[50001] = 4,
				[50002] = 4,
			},
		},
		[9] = 
		{
			x = 8.50, y = 49.27, z = 67.80, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[10] = 
		{
			x = -23.00, y = 51.48, z = 30.00, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[11] = 
		{
			x = 10.00, y = 55.19, z = -1.00, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[12] = 
		{
			x = 40.00, y = 51.24, z = 30.00, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 0.00, posy = 50.56, posz = 38.00, rotx = 0.00, roty = 150.00, rotz = 0.00 },
	},

}
return MapInfo
