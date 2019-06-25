local MapInfo = 
{
	MapType = 3,
	Remarks = "被遗弃者墓园【支线相位】",
	TextDisplayName = "被遗弃者墓园",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part2.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Canyon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-2.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part2.prefab",
	Monster = 
	{
		[12088] = 
		{
			[1] = { x = 260.30, y = 35.94, z = 126.70, name = "丧尸", level = 37, SortID = 3 },
			[2] = { x = 244.89, y = 33.51, z = 147.10, name = "丧尸", level = 37, SortID = 4 },
			[3] = { x = 232.90, y = 33.16, z = 140.90, name = "丧尸", level = 37, SortID = 5 },
			[4] = { x = 225.90, y = 33.71, z = 116.00, name = "丧尸", level = 37, SortID = 6 },
			[5] = { x = 158.38, y = 34.34, z = 105.53, name = "丧尸", level = 37, SortID = 11 },
			[6] = { x = 150.71, y = 34.13, z = 83.62, name = "丧尸", level = 37, SortID = 12 },
		},
		[12086] = 
		{
			[1] = { x = 200.64, y = 37.69, z = 111.32, name = "惊醒的死者", level = 38, SortID = 8 },
		},
		[12087] = 
		{
			[1] = { x = 158.38, y = 34.34, z = 105.53, name = "不死者", level = 37, SortID = 11 },
			[2] = { x = 150.71, y = 34.13, z = 83.62, name = "不死者", level = 37, SortID = 12 },
		},
		[12090] = 
		{
			[1] = { x = 134.39, y = 32.23, z = 126.58, name = "托里男爵", level = 37, SortID = 14 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[213] = { x = 195.43, y = 39.00, z = 116.25, name = "遗弃者墓地", worldId = 0, IsCanFind = 1, PkMode = 0 },
			[393] = { x = 257.33, y = 1.00, z = 135.90, name = "侦查墓园01", worldId = 0, PkMode = 0 },
			[394] = { x = 229.50, y = 1.00, z = 137.50, name = "侦查墓园02", worldId = 0, PkMode = 0 },
			[395] = { x = 195.52, y = 37.34, z = 115.72, name = "侦查墓园03", worldId = 0, PkMode = 0 },
			[396] = { x = 138.14, y = 33.30, z = 117.57, name = "发现男爵", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[518] = 
		{
			[1] = { x = 198.15, y = 37.53, z = 112.20 },
		},
		[519] = 
		{
			[1] = { x = 170.60, y = 34.90, z = 103.90 },
		},
		[520] = 
		{
			[1] = { x = 141.70, y = 34.16, z = 86.30 },
		},
		[521] = 
		{
			[1] = { x = 133.93, y = 34.12, z = 107.49 },
		},
	},
	Entity = 
	{
		[3] = 
		{
			x = 260.30, y = 35.94, z = 126.70, Type = 1,
			Tid = 
			{
				[12088] = 5,
			},
		},
		[4] = 
		{
			x = 244.89, y = 33.51, z = 147.10, Type = 1,
			Tid = 
			{
				[12088] = 5,
			},
		},
		[5] = 
		{
			x = 232.90, y = 33.16, z = 140.90, Type = 1,
			Tid = 
			{
				[12088] = 5,
			},
		},
		[6] = 
		{
			x = 225.90, y = 33.71, z = 116.00, Type = 1,
			Tid = 
			{
				[12088] = 5,
			},
		},
		[8] = 
		{
			x = 200.64, y = 37.69, z = 111.32, Type = 1,
			Tid = 
			{
				[12086] = 1,
			},
		},
		[11] = 
		{
			x = 158.38, y = 34.34, z = 105.53, Type = 1,
			Tid = 
			{
				[12088] = 4,
				[12087] = 2,
			},
		},
		[12] = 
		{
			x = 150.71, y = 34.13, z = 83.62, Type = 1,
			Tid = 
			{
				[12088] = 4,
				[12087] = 2,
			},
		},
		[14] = 
		{
			x = 134.39, y = 32.23, z = 126.58, Type = 1,
			Tid = 
			{
				[12090] = 1,
			},
		},
		[7] = 
		{
			x = 198.15, y = 37.53, z = 112.20, Type = 6,
			Tid = 
			{
				[518] = 1,
			},
		},
		[9] = 
		{
			x = 170.60, y = 34.90, z = 103.90, Type = 6,
			Tid = 
			{
				[519] = 1,
			},
		},
		[10] = 
		{
			x = 141.70, y = 34.16, z = 86.30, Type = 6,
			Tid = 
			{
				[520] = 1,
			},
		},
		[13] = 
		{
			x = 133.93, y = 34.12, z = 107.49, Type = 6,
			Tid = 
			{
				[521] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 336.29, posy = 46.57, posz = -106.17, rotx = 0.00, roty = 228.09, rotz = 0.00 },
		[2] = { posx = -171.00, posy = 62.05, posz = -68.00, rotx = 0.00, roty = 218.70, rotz = 0.00 },
		[3] = { posx = -154.00, posy = 86.18, posz = 11.00, rotx = 0.00, roty = 266.89, rotz = 0.00 },
		[4] = { posx = -182.91, posy = 43.74, posz = -175.83, rotx = 0.00, roty = 294.54, rotz = 0.00 },
	},

}
return MapInfo
