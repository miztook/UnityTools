local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "风暴之城",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part2.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-2.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part2.prefab",
	Monster = 
	{
		[50015] = 
		{
			[1] = { x = 313.60, y = 48.25, z = 114.00, name = "阿克德法猎犬", level = 10, SortID = 1 },
			[2] = { x = 324.60, y = 46.00, z = 89.00, name = "阿克德法猎犬", level = 10, SortID = 3 },
			[3] = { x = 297.90, y = 48.10, z = 103.50, name = "阿克德法猎犬", level = 10, SortID = 5 },
			[4] = { x = 313.46, y = 48.63, z = 118.60, name = "阿克德法猎犬", level = 10, SortID = 8 },
		},
		[50033] = 
		{
			[1] = { x = 313.60, y = 48.25, z = 114.00, name = "血祭者", level = 10, SortID = 1 },
			[2] = { x = 324.60, y = 46.00, z = 89.00, name = "血祭者", level = 10, SortID = 3 },
			[3] = { x = 297.90, y = 48.10, z = 103.50, name = "血祭者", level = 10, SortID = 5 },
			[4] = { x = 313.46, y = 48.63, z = 118.60, name = "血祭者", level = 10, SortID = 8 },
		},
		[50017] = 
		{
			[1] = { x = 313.60, y = 48.25, z = 114.00, name = "血武者", level = 10, SortID = 1 },
			[2] = { x = 324.60, y = 46.00, z = 89.00, name = "血武者", level = 10, SortID = 3 },
			[3] = { x = 297.90, y = 48.10, z = 103.50, name = "血武者", level = 10, SortID = 5 },
			[4] = { x = 313.46, y = 48.63, z = 118.60, name = "血武者", level = 10, SortID = 8 },
		},
		[50016] = 
		{
			[1] = { x = 306.45, y = 48.36, z = 112.26, name = "血执事", level = 10, SortID = 2 },
			[2] = { x = 301.10, y = 48.30, z = 84.10, name = "血执事", level = 10, SortID = 4 },
			[3] = { x = 324.00, y = 49.40, z = 89.60, name = "血执事", level = 10, SortID = 6 },
			[4] = { x = 313.46, y = 48.63, z = 118.60, name = "血执事", level = 10, SortID = 8 },
		},
		[50018] = 
		{
			[1] = { x = 306.45, y = 48.36, z = 112.26, name = "复仇血法师", level = 10, SortID = 2 },
			[2] = { x = 301.10, y = 48.30, z = 84.10, name = "复仇血法师", level = 10, SortID = 4 },
			[3] = { x = 324.00, y = 49.40, z = 89.60, name = "复仇血法师", level = 10, SortID = 6 },
			[4] = { x = 313.46, y = 48.63, z = 118.60, name = "复仇血法师", level = 10, SortID = 8 },
		},
		[50019] = 
		{
			[1] = { x = 313.00, y = 48.96, z = 110.10, name = "德法屠杀者", level = 10, SortID = 7 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = 311.57, y = 46.43, z = 99.13, name = "刷怪区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 313.60, y = 48.25, z = 114.00, Type = 1,
			Tid = 
			{
				[50015] = 5,
				[50033] = 5,
				[50017] = 5,
			},
		},
		[2] = 
		{
			x = 306.45, y = 48.36, z = 112.26, Type = 1,
			Tid = 
			{
				[50016] = 5,
				[50018] = 5,
			},
		},
		[3] = 
		{
			x = 324.60, y = 46.00, z = 89.00, Type = 1,
			Tid = 
			{
				[50015] = 5,
				[50033] = 5,
				[50017] = 5,
			},
		},
		[4] = 
		{
			x = 301.10, y = 48.30, z = 84.10, Type = 1,
			Tid = 
			{
				[50016] = 5,
				[50018] = 5,
			},
		},
		[5] = 
		{
			x = 297.90, y = 48.10, z = 103.50, Type = 1,
			Tid = 
			{
				[50015] = 5,
				[50033] = 5,
				[50017] = 5,
			},
		},
		[6] = 
		{
			x = 324.00, y = 49.40, z = 89.60, Type = 1,
			Tid = 
			{
				[50016] = 5,
				[50018] = 5,
			},
		},
		[7] = 
		{
			x = 313.00, y = 48.96, z = 110.10, Type = 1,
			Tid = 
			{
				[50019] = 1,
			},
		},
		[8] = 
		{
			x = 313.46, y = 48.63, z = 118.60, Type = 1,
			Tid = 
			{
				[50015] = 4,
				[50016] = 4,
				[50017] = 4,
				[50018] = 4,
				[50033] = 4,
			},
		},
		[9] = 
		{
			x = 312.92, y = 50.66, z = 130.17, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[10] = 
		{
			x = 283.95, y = 44.39, z = 100.00, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[11] = 
		{
			x = 312.99, y = 45.99, z = 74.86, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[12] = 
		{
			x = 338.00, y = 47.03, z = 100.00, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 318.42, posy = 50.46, posz = 127.16, rotx = 0.00, roty = 90.00, rotz = 0.00 },
	},

}
return MapInfo
