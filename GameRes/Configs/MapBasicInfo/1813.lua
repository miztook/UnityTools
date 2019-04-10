local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "要塞争夺战【声望】",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part2.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-2.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part2.prefab",
	Monster = 
	{
		[50103] = 
		{
			[1] = { x = -39.04, y = 86.99, z = 85.09, name = "风之精锐队长", level = 45, SortID = 15, DropItemIds = " " },
			[2] = { x = -90.76, y = 93.80, z = 127.43, name = "风之精锐队长", level = 45, SortID = 17, DropItemIds = " " },
			[3] = { x = -31.08, y = 98.33, z = 140.24, name = "风之精锐队长", level = 45, SortID = 19, DropItemIds = " " },
		},
		[50101] = 
		{
			[1] = { x = -34.24, y = 87.08, z = 86.08, name = "风之祭司", level = 45, SortID = 16, DropItemIds = " " },
			[2] = { x = -90.98, y = 93.80, z = 131.25, name = "风之祭司", level = 45, SortID = 18, DropItemIds = " " },
			[3] = { x = -26.36, y = 98.33, z = 140.24, name = "风之祭司", level = 45, SortID = 20, DropItemIds = " " },
		},
		[50102] = 
		{
			[1] = { x = -34.24, y = 87.08, z = 86.08, name = "风之武士", level = 45, SortID = 16, DropItemIds = " " },
			[2] = { x = -90.98, y = 93.80, z = 131.25, name = "风之武士", level = 45, SortID = 18, DropItemIds = " " },
			[3] = { x = -26.36, y = 98.33, z = 140.24, name = "风之武士", level = 45, SortID = 20, DropItemIds = " " },
		},
		[12118] = 
		{
			[1] = { x = -37.06, y = 87.24, z = 85.36, name = "", level = 5, SortID = 21, DropItemIds = " " },
		},
		[12119] = 
		{
			[1] = { x = -90.79, y = 93.80, z = 129.41, name = "", level = 5, SortID = 22, DropItemIds = " " },
		},
		[12120] = 
		{
			[1] = { x = -29.09, y = 98.33, z = 140.29, name = "", level = 5, SortID = 23, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[40101] = 
		{
			[1] = { x = -37.48, y = 80.47, z = 35.54, name = "高等精灵队长", SortID = 1, FunctionName = " " },
		},
		[40102] = 
		{
			[1] = { x = -34.45, y = 80.50, z = 33.62, name = "高等精灵射手", SortID = 2, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -62.55, y = 87.02, z = 88.86, name = "", worldId = 0, PkMode = 0 },
			[2] = { x = -36.84, y = 87.24, z = 85.34, name = "占点1", worldId = 0, PkMode = 0 },
			[3] = { x = -90.73, y = 93.61, z = 130.05, name = "占点2", worldId = 0, PkMode = 0 },
			[4] = { x = -29.22, y = 98.34, z = 140.42, name = "占点3", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[10101] = 
		{
			[1] = { x = -37.06, y = 87.24, z = 85.44 },
			[2] = { x = -90.72, y = 93.80, z = 129.46 },
		},
		[10104] = 
		{
			[1] = { x = -37.06, y = 87.24, z = 85.44 },
			[2] = { x = -90.72, y = 93.80, z = 129.46 },
		},
		[10107] = 
		{
			[1] = { x = -37.06, y = 87.24, z = 85.44 },
			[2] = { x = -90.72, y = 93.80, z = 129.46 },
			[3] = { x = -29.15, y = 98.33, z = 140.33 },
		},
		[10108] = 
		{
			[1] = { x = -37.06, y = 87.24, z = 85.44 },
			[2] = { x = -90.72, y = 93.81, z = 129.46 },
			[3] = { x = -29.15, y = 98.33, z = 140.33 },
		},
		[10103] = 
		{
			[1] = { x = -29.15, y = 98.33, z = 140.33 },
		},
		[10106] = 
		{
			[1] = { x = -29.15, y = 98.33, z = 140.33 },
		},
	},
	Entity = 
	{
		[15] = 
		{
			x = -39.04, y = 86.99, z = 85.09, Type = 1,
			Tid = 
			{
				[50103] = 1,
			},
		},
		[16] = 
		{
			x = -34.24, y = 87.08, z = 86.08, Type = 1,
			Tid = 
			{
				[50101] = 3,
				[50102] = 3,
			},
		},
		[17] = 
		{
			x = -90.76, y = 93.80, z = 127.43, Type = 1,
			Tid = 
			{
				[50103] = 1,
			},
		},
		[18] = 
		{
			x = -90.98, y = 93.80, z = 131.25, Type = 1,
			Tid = 
			{
				[50101] = 3,
				[50102] = 3,
			},
		},
		[19] = 
		{
			x = -31.08, y = 98.33, z = 140.24, Type = 1,
			Tid = 
			{
				[50103] = 1,
			},
		},
		[20] = 
		{
			x = -26.36, y = 98.33, z = 140.24, Type = 1,
			Tid = 
			{
				[50101] = 3,
				[50102] = 3,
			},
		},
		[21] = 
		{
			x = -37.06, y = 87.24, z = 85.36, Type = 1,
			Tid = 
			{
				[12118] = 1,
			},
		},
		[22] = 
		{
			x = -90.79, y = 93.80, z = 129.41, Type = 1,
			Tid = 
			{
				[12119] = 1,
			},
		},
		[23] = 
		{
			x = -29.09, y = 98.33, z = 140.29, Type = 1,
			Tid = 
			{
				[12120] = 1,
			},
		},
		[1] = 
		{
			x = -37.48, y = 80.47, z = 35.54, Type = 2,
			Tid = 
			{
				[40101] = 1,
			},
		},
		[2] = 
		{
			x = -34.45, y = 80.50, z = 33.62, Type = 2,
			Tid = 
			{
				[40102] = 3,
			},
		},
		[24] = 
		{
			x = -29.65, y = 92.38, z = 117.41, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[3] = 
		{
			x = -37.06, y = 87.24, z = 85.44, Type = 6,
			Tid = 
			{
				[10101] = 1,
			},
		},
		[4] = 
		{
			x = -37.06, y = 87.24, z = 85.44, Type = 6,
			Tid = 
			{
				[10104] = 1,
			},
		},
		[5] = 
		{
			x = -37.06, y = 87.24, z = 85.44, Type = 6,
			Tid = 
			{
				[10107] = 1,
			},
		},
		[6] = 
		{
			x = -37.06, y = 87.24, z = 85.44, Type = 6,
			Tid = 
			{
				[10108] = 1,
			},
		},
		[7] = 
		{
			x = -90.72, y = 93.80, z = 129.46, Type = 6,
			Tid = 
			{
				[10101] = 1,
			},
		},
		[8] = 
		{
			x = -90.72, y = 93.80, z = 129.46, Type = 6,
			Tid = 
			{
				[10104] = 1,
			},
		},
		[9] = 
		{
			x = -90.72, y = 93.80, z = 129.46, Type = 6,
			Tid = 
			{
				[10107] = 1,
			},
		},
		[10] = 
		{
			x = -90.72, y = 93.81, z = 129.46, Type = 6,
			Tid = 
			{
				[10108] = 1,
			},
		},
		[11] = 
		{
			x = -29.15, y = 98.33, z = 140.33, Type = 6,
			Tid = 
			{
				[10103] = 1,
			},
		},
		[12] = 
		{
			x = -29.15, y = 98.33, z = 140.33, Type = 6,
			Tid = 
			{
				[10106] = 1,
			},
		},
		[13] = 
		{
			x = -29.15, y = 98.33, z = 140.33, Type = 6,
			Tid = 
			{
				[10107] = 1,
			},
		},
		[14] = 
		{
			x = -29.15, y = 98.33, z = 140.33, Type = 6,
			Tid = 
			{
				[10108] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo