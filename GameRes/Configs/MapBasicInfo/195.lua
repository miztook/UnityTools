local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "温妮莎大营",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "BGM_Map_5/Map_5/Map_5_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_019.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[14036] = 
		{
			[1] = { x = 135.01, y = 24.72, z = 306.62, name = "沙摩尔", level = 60, SortID = 1 },
		},
		[14037] = 
		{
			[1] = { x = 134.22, y = 24.70, z = 313.65, name = "乔纳森", level = 60, SortID = 2 },
		},
		[14002] = 
		{
			[1] = { x = 138.21, y = 21.25, z = 246.70, name = "复生联盟军", level = 59, SortID = 7 },
		},
	},
	Npc = 
	{
		[4060] = 
		{
			[1] = { x = 143.33, y = 24.70, z = 295.58, name = "卡塔娅·拉赫纳", SortID = 3 },
		},
		[4019] = 
		{
			[1] = { x = 135.01, y = 24.70, z = 306.03, name = "沙摩尔", SortID = 4 },
		},
		[4061] = 
		{
			[1] = { x = 134.23, y = 21.30, z = 230.92, name = "艾丽莎·库贝尔", SortID = 5 },
		},
		[4032] = 
		{
			[1] = { x = 136.61, y = 21.25, z = 231.27, name = "艾利恩·库贝尔", SortID = 6 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[338] = { x = 133.88, y = 22.53, z = 285.72, name = "第三军团大营", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {4106} },
			[379] = { x = 114.72, y = 24.70, z = 315.17, name = "抵达1", worldId = 0, PkMode = 0 },
			[382] = { x = 136.79, y = 21.25, z = 274.30, name = "抵达2", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[456] = 
		{
			[1] = { x = 136.55, y = 21.25, z = 247.91 },
		},
		[61] = 
		{
			[1] = { x = 134.96, y = 21.25, z = 233.20 },
		},
		[62] = 
		{
			[1] = { x = 134.96, y = 21.25, z = 233.20 },
		},
		[63] = 
		{
			[1] = { x = 134.96, y = 21.25, z = 233.20 },
		},
		[64] = 
		{
			[1] = { x = 134.96, y = 21.25, z = 233.20 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = 135.01, y = 24.72, z = 306.62, Type = 1,
			Tid = 
			{
				[14036] = 1,
			},
		},
		[2] = 
		{
			x = 134.22, y = 24.70, z = 313.65, Type = 1,
			Tid = 
			{
				[14037] = 1,
			},
		},
		[7] = 
		{
			x = 138.21, y = 21.25, z = 246.70, Type = 1,
			Tid = 
			{
				[14002] = 9,
			},
		},
		[3] = 
		{
			x = 143.33, y = 24.70, z = 295.58, Type = 2,
			Tid = 
			{
				[4060] = 1,
			},
		},
		[4] = 
		{
			x = 135.01, y = 24.70, z = 306.03, Type = 2,
			Tid = 
			{
				[4019] = 1,
			},
		},
		[5] = 
		{
			x = 134.23, y = 21.30, z = 230.92, Type = 2,
			Tid = 
			{
				[4061] = 1,
			},
		},
		[6] = 
		{
			x = 136.61, y = 21.25, z = 231.27, Type = 2,
			Tid = 
			{
				[4032] = 1,
			},
		},
		[8] = 
		{
			x = 136.55, y = 21.25, z = 247.91, Type = 6,
			Tid = 
			{
				[456] = 1,
			},
		},
		[9] = 
		{
			x = 134.96, y = 21.25, z = 233.20, Type = 6,
			Tid = 
			{
				[61] = 3,
				[62] = 3,
				[63] = 3,
				[64] = 3,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
