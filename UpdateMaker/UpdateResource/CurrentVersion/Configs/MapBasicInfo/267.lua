local MapInfo = 
{
	MapType = 4,
	Remarks = "新手副本2",
	TextDisplayName = "新手副本2",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn00_EmpireRelicPrologue.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/BGM_Dunjeon_Tutorial",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_Start.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn00_EmpireRelicPrologue.prefab",
	PKMode= 1,
	Monster = 
	{
		[40002] = 
		{
			[1] = { x = 25.56, y = 46.38, z = -56.70, name = "血武者", level = 1, SortID = 3 },
			[2] = { x = 33.01, y = 46.38, z = -49.26, name = "血武者", level = 1, SortID = 4 },
			[3] = { x = 17.04, y = 55.78, z = 6.95, name = "血武者", level = 1, SortID = 6 },
		},
		[40017] = 
		{
			[1] = { x = 22.79, y = 55.78, z = -11.67, name = "不死者", level = 1, SortID = 5 },
		},
		[40000] = 
		{
			[1] = { x = 10.81, y = 71.37, z = 107.96, name = "魔龙暴君", level = 1, SortID = 7,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[4] = { x = 10.90, y = 45.66, z = -73.23, name = "摇杆教学", worldId = 0, PkMode = 1 },
			[5] = { x = 23.12, y = 46.38, z = -58.56, name = "自动任务教学", worldId = 0, PkMode = 1 },
			[6] = { x = 21.24, y = 55.78, z = -11.80, name = "巴风特平台", worldId = 0, PkMode = 1 },
			[7] = { x = 2.38, y = 70.33, z = 64.45, name = "巨龙平台", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[3] = 
		{
			x = 25.56, y = 46.38, z = -56.70, Type = 1,
			Tid = 
			{
				[40002] = 2,
			},
		},
		[4] = 
		{
			x = 33.01, y = 46.38, z = -49.26, Type = 1,
			Tid = 
			{
				[40002] = 6,
			},
		},
		[5] = 
		{
			x = 22.79, y = 55.78, z = -11.67, Type = 1,
			Tid = 
			{
				[40017] = 1,
			},
		},
		[6] = 
		{
			x = 17.04, y = 55.78, z = 6.95, Type = 1,
			Tid = 
			{
				[40002] = 6,
			},
		},
		[7] = 
		{
			x = 10.81, y = 71.37, z = 107.96, Type = 1,
			Tid = 
			{
				[40000] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -5.73, posy = 71.37, posz = 91.81, rotx = 0.00, roty = 41.23, rotz = 0.00 },
	},

}
return MapInfo