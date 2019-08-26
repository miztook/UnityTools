local MapInfo = 
{
	MapType = 2,
	Remarks = "神视单人",
	TextDisplayName = "东部领地",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	PKMode= 1,
	Monster = 
	{
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[402] = { x = 42.54, y = 61.15, z = -132.84, name = "神视单人-1", worldId = 0, PkMode = 1 },
			[403] = { x = -46.20, y = 49.33, z = -205.70, name = "神视单人-2", worldId = 0, PkMode = 1 },
			[404] = { x = -224.91, y = 130.94, z = -164.84, name = "神视单人-3", worldId = 0, PkMode = 1 },
			[405] = { x = 36.70, y = 49.55, z = -184.80, name = "神视万物志-1", worldId = 0, PkMode = 1 },
			[406] = { x = -192.29, y = 131.12, z = -177.56, name = "神视万物志-2", worldId = 0, PkMode = 1 },
			[407] = { x = -207.24, y = 132.42, z = -184.38, name = "神视万物志-3", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[610] = 
		{
			[1] = { x = 67.50, y = 49.24, z = -142.00 },
			[2] = { x = -41.10, y = 53.34, z = -241.80 },
			[3] = { x = -235.60, y = 42.24, z = -160.80 },
		},
		[342] = 
		{
			[1] = { x = 67.50, y = 49.47, z = -220.00 },
		},
		[343] = 
		{
			[1] = { x = -184.70, y = 41.06, z = -192.00 },
		},
		[344] = 
		{
			[1] = { x = -224.80, y = 46.69, z = -208.00 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = 67.50, y = 49.24, z = -142.00, Type = 6,
			Tid = 
			{
				[610] = 1,
			},
		},
		[2] = 
		{
			x = -41.10, y = 53.34, z = -241.80, Type = 6,
			Tid = 
			{
				[610] = 1,
			},
		},
		[3] = 
		{
			x = -235.60, y = 42.24, z = -160.80, Type = 6,
			Tid = 
			{
				[610] = 1,
			},
		},
		[4] = 
		{
			x = 67.50, y = 49.47, z = -220.00, Type = 6,
			Tid = 
			{
				[342] = 1,
			},
		},
		[5] = 
		{
			x = -184.70, y = 41.06, z = -192.00, Type = 6,
			Tid = 
			{
				[343] = 1,
			},
		},
		[6] = 
		{
			x = -224.80, y = 46.69, z = -208.00, Type = 6,
			Tid = 
			{
				[344] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo