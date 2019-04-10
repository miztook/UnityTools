local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "埋伏地",
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
		[14040] = 
		{
			[1] = { x = -29.28, y = 52.35, z = -105.13, name = "帝国剑斗士", level = 57, SortID = 3 },
		},
		[14038] = 
		{
			[1] = { x = -29.28, y = 52.35, z = -105.13, name = "德法猛犸虎", level = 57, SortID = 3 },
		},
		[14019] = 
		{
			[1] = { x = -29.28, y = 52.35, z = -105.13, name = "丧尸", level = 53, SortID = 4 },
		},
		[14003] = 
		{
			[1] = { x = -29.28, y = 52.35, z = -105.13, name = "不死者", level = 53, SortID = 4 },
		},
		[14042] = 
		{
			[1] = { x = -28.82, y = 52.35, z = -105.00, name = "屠杀者", level = 52, SortID = 5 },
		},
	},
	Npc = 
	{
		[4045] = 
		{
			[1] = { x = -31.91, y = 52.34, z = -99.41, name = "卡塔娅·拉赫纳", SortID = 1 },
		},
		[4047] = 
		{
			[1] = { x = -35.11, y = 52.35, z = -99.74, name = "焰晶", SortID = 2 },
		},
		[4055] = 
		{
			[1] = { x = -40.04, y = 52.38, z = -89.65, name = "温妮莎·德佩拉", SortID = 6 },
		},
		[4073] = 
		{
			[1] = { x = -40.04, y = 52.38, z = -89.65, name = "迪波", SortID = 6 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[343] = { x = -33.79, y = 52.36, z = -97.81, name = "伏击地", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {4040} },
		},
	},
	Mine = 
	{
		[454] = 
		{
			[1] = { x = -32.26, y = 52.92, z = -88.30 },
		},
	},
	Entity = 
	{
		[3] = 
		{
			x = -29.28, y = 52.35, z = -105.13, Type = 1,
			Tid = 
			{
				[14040] = 6,
				[14038] = 2,
			},
		},
		[4] = 
		{
			x = -29.28, y = 52.35, z = -105.13, Type = 1,
			Tid = 
			{
				[14019] = 4,
				[14003] = 4,
			},
		},
		[5] = 
		{
			x = -28.82, y = 52.35, z = -105.00, Type = 1,
			Tid = 
			{
				[14042] = 1,
			},
		},
		[1] = 
		{
			x = -31.91, y = 52.34, z = -99.41, Type = 2,
			Tid = 
			{
				[4045] = 1,
			},
		},
		[2] = 
		{
			x = -35.11, y = 52.35, z = -99.74, Type = 2,
			Tid = 
			{
				[4047] = 1,
			},
		},
		[6] = 
		{
			x = -40.04, y = 52.38, z = -89.65, Type = 2,
			Tid = 
			{
				[4055] = 1,
				[4073] = 1,
			},
		},
		[41] = 
		{
			x = -32.26, y = 52.92, z = -88.30, Type = 6,
			Tid = 
			{
				[454] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo