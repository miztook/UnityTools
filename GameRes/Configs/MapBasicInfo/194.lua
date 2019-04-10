local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "惧亡者引擎",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "BGM_Map_5/Map_5/Map_5_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world05.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[14016] = 
		{
			[1] = { x = -68.20, y = 70.22, z = 302.60, name = "普里昂战士", level = 58, SortID = 3 },
		},
		[14013] = 
		{
			[1] = { x = -68.20, y = 69.93, z = 302.60, name = "普里昂精英", level = 58, SortID = 4 },
		},
		[14039] = 
		{
			[1] = { x = -82.63, y = 69.93, z = 266.44, name = "德法猛犸虎", level = 58, SortID = 5 },
		},
		[14009] = 
		{
			[1] = { x = -98.76, y = 70.22, z = 289.69, name = "不死近卫", level = 58, SortID = 6 },
		},
		[14011] = 
		{
			[1] = { x = -98.76, y = 70.22, z = 289.69, name = "不死骑士", level = 60, SortID = 7 },
		},
	},
	Npc = 
	{
		[4139] = 
		{
			[1] = { x = -79.24, y = 70.22, z = 285.07, name = "迪波", SortID = 2 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[344] = { x = -80.99, y = 72.35, z = 293.37, name = "石头相位区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[458] = 
		{
			[1] = { x = -83.25, y = 70.22, z = 285.26 },
		},
		[461] = 
		{
			[1] = { x = -74.95, y = 70.22, z = 281.01 },
		},
	},
	Entity = 
	{
		[3] = 
		{
			x = -68.20, y = 70.22, z = 302.60, Type = 1,
			Tid = 
			{
				[14016] = 5,
			},
		},
		[4] = 
		{
			x = -68.20, y = 69.93, z = 302.60, Type = 1,
			Tid = 
			{
				[14013] = 4,
			},
		},
		[5] = 
		{
			x = -82.63, y = 69.93, z = 266.44, Type = 1,
			Tid = 
			{
				[14039] = 6,
			},
		},
		[6] = 
		{
			x = -98.76, y = 70.22, z = 289.69, Type = 1,
			Tid = 
			{
				[14009] = 9,
			},
		},
		[7] = 
		{
			x = -98.76, y = 70.22, z = 289.69, Type = 1,
			Tid = 
			{
				[14011] = 3,
			},
		},
		[2] = 
		{
			x = -79.24, y = 70.22, z = 285.07, Type = 2,
			Tid = 
			{
				[4139] = 1,
			},
		},
		[1] = 
		{
			x = -83.25, y = 70.22, z = 285.26, Type = 6,
			Tid = 
			{
				[458] = 1,
			},
		},
		[8] = 
		{
			x = -74.95, y = 70.22, z = 281.01, Type = 6,
			Tid = 
			{
				[461] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo