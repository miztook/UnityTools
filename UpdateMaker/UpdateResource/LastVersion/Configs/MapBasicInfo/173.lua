local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "甜水绿洲",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part1.navmesh",
	BackgroundMusic = "BGM_Map_4/Map_4/Map_4_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Desert",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-1.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part1.prefab",
	PKMode= 1,
	Monster = 
	{
		[13032] = 
		{
			[1] = { x = -76.70, y = 31.98, z = -100.20, name = "沙行者", level = 44, SortID = 42 },
		},
		[13033] = 
		{
			[1] = { x = -74.30, y = 31.98, z = -102.20, name = "沙行者勇者", level = 44, SortID = 1 },
		},
	},
	Npc = 
	{
		[3046] = 
		{
			[1] = { x = -63.82, y = 31.98, z = -118.22, name = "精灵探险者", SortID = 91 },
		},
		[3047] = 
		{
			[1] = { x = -61.77, y = 31.98, z = -119.97, name = "精灵幸存者", SortID = 93 },
		},
		[3045] = 
		{
			[1] = { x = -36.80, y = 31.12, z = -80.04, name = "坎帕索", SortID = 94 },
		},
		[3044] = 
		{
			[1] = { x = -39.21, y = 31.28, z = -80.37, name = "高等精灵射手", SortID = 95 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[287] = { x = -50.34, y = 40.90, z = -107.05, name = "甜水营地", worldId = 0, PkMode = 1 },
			[316] = { x = -77.06, y = 31.81, z = -104.68, name = "抵达区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[390] = 
		{
			[1] = { x = -33.15, y = 30.87, z = -78.96 },
		},
	},
	Entity = 
	{
		[42] = 
		{
			x = -76.70, y = 31.98, z = -100.20, Type = 1,
			Tid = 
			{
				[13032] = 4,
			},
		},
		[1] = 
		{
			x = -74.30, y = 31.98, z = -102.20, Type = 1,
			Tid = 
			{
				[13033] = 1,
			},
		},
		[91] = 
		{
			x = -63.82, y = 31.98, z = -118.22, Type = 2,
			Tid = 
			{
				[3046] = 1,
			},
		},
		[93] = 
		{
			x = -61.77, y = 31.98, z = -119.97, Type = 2,
			Tid = 
			{
				[3047] = 1,
			},
		},
		[94] = 
		{
			x = -36.80, y = 31.12, z = -80.04, Type = 2,
			Tid = 
			{
				[3045] = 1,
			},
		},
		[95] = 
		{
			x = -39.21, y = 31.28, z = -80.37, Type = 2,
			Tid = 
			{
				[3044] = 2,
			},
		},
		[2] = 
		{
			x = -33.15, y = 30.87, z = -78.96, Type = 6,
			Tid = 
			{
				[390] = 1,
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