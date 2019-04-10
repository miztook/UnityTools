local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "드페라 저택",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "BGM_Map_5/Map_5/Map_5_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Square",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_019.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[14000] = 
		{
			[1] = { x = -141.69, y = 37.83, z = -84.16, name = "언데드 연합군", level = 51, SortID = 1 },
			[2] = { x = -139.84, y = 37.83, z = -84.35, name = "언데드 연합군", level = 51, SortID = 2 },
		},
	},
	Npc = 
	{
		[4000] = 
		{
			[1] = { x = -132.68, y = 37.84, z = -85.70, name = "다친 연합군 병사", SortID = 3 },
		},
		[4036] = 
		{
			[1] = { x = -157.74, y = 38.08, z = -85.08, name = "폭도들의 환영", SortID = 4 },
		},
		[4037] = 
		{
			[1] = { x = -157.74, y = 38.08, z = -85.08, name = "폭도들의 환영", SortID = 4 },
		},
		[4102] = 
		{
			[1] = { x = -157.74, y = 38.03, z = -85.08, name = "폭도들의 환영", SortID = 5 },
		},
		[4103] = 
		{
			[1] = { x = -157.74, y = 38.03, z = -85.08, name = "폭도들의 환영", SortID = 5 },
		},
		[4015] = 
		{
			[1] = { x = -135.46, y = 37.84, z = -85.58, name = "사마엘", SortID = 6 },
		},
		[4086] = 
		{
			[1] = { x = -157.16, y = 37.85, z = -88.00, name = "벨릭", SortID = 7 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[333] = { x = -154.16, y = 37.85, z = -69.83, name = "드페라 저택", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {4012,4013,4014,4015} },
			[377] = { x = -162.55, y = 37.96, z = -59.69, name = "抵达区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[452] = 
		{
			[1] = { x = -162.73, y = 37.83, z = -54.92 },
		},
		[465] = 
		{
			[1] = { x = -147.49, y = 37.95, z = -61.67 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = -141.69, y = 37.83, z = -84.16, Type = 1,
			Tid = 
			{
				[14000] = 4,
			},
		},
		[2] = 
		{
			x = -139.84, y = 37.83, z = -84.35, Type = 1,
			Tid = 
			{
				[14000] = 8,
			},
		},
		[3] = 
		{
			x = -132.68, y = 37.84, z = -85.70, Type = 2,
			Tid = 
			{
				[4000] = 1,
			},
		},
		[4] = 
		{
			x = -157.74, y = 38.08, z = -85.08, Type = 2,
			Tid = 
			{
				[4036] = 1,
				[4037] = 1,
			},
		},
		[5] = 
		{
			x = -157.74, y = 38.03, z = -85.08, Type = 2,
			Tid = 
			{
				[4102] = 1,
				[4103] = 1,
			},
		},
		[6] = 
		{
			x = -135.46, y = 37.84, z = -85.58, Type = 2,
			Tid = 
			{
				[4015] = 1,
			},
		},
		[7] = 
		{
			x = -157.16, y = 37.85, z = -88.00, Type = 2,
			Tid = 
			{
				[4086] = 1,
			},
		},
		[21] = 
		{
			x = -162.73, y = 37.83, z = -54.92, Type = 6,
			Tid = 
			{
				[452] = 1,
			},
		},
		[8] = 
		{
			x = -147.49, y = 37.95, z = -61.67, Type = 6,
			Tid = 
			{
				[465] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
