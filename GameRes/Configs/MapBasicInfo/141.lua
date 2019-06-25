local MapInfo = 
{
	MapType = 3,
	Remarks = "幻影村落",
	TextDisplayName = "幻影村落",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Forest",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	Monster = 
	{
		[12006] = 
		{
			[1] = { x = -279.81, y = -8.38, z = -80.26, name = "艾利恩暗影", level = 30, SortID = 1 },
		},
		[12005] = 
		{
			[1] = { x = -277.17, y = -3.45, z = -48.72, name = "游侠暗影", level = 30, SortID = 4 },
		},
	},
	Npc = 
	{
		[2016] = 
		{
			[1] = { x = -285.72, y = -3.45, z = -44.79, name = "死去的游侠", SortID = 7 },
			[2] = { x = -266.29, y = -3.45, z = -46.09, name = "死去的游侠", SortID = 11 },
			[3] = { x = -276.93, y = -3.45, z = -40.40, name = "死去的游侠", FunctionName = " " },
		},
		[2018] = 
		{
			[1] = { x = -267.87, y = -3.45, z = -53.34, name = "死去的游侠", SortID = 10 },
		},
		[2011] = 
		{
			[1] = { x = -283.85, y = -3.45, z = -52.57, name = "游侠", SortID = 13 },
		},
		[2010] = 
		{
			[1] = { x = -282.20, y = -8.39, z = -84.96, name = "艾丽莎·库贝尔", SortID = 30 },
		},
		[2012] = 
		{
			[1] = { x = -277.47, y = -3.53, z = -56.34, name = "游侠", SortID = 2 },
		},
		[2282] = 
		{
			[1] = { x = -284.70, y = -8.38, z = -83.78, name = "露娜·艾琳", FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[194] = { x = -283.53, y = 1.98, z = -66.49, name = "迷幻村落", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -279.81, y = -8.38, z = -80.26, Type = 1,
			Tid = 
			{
				[12006] = 1,
			},
		},
		[4] = 
		{
			x = -277.17, y = -3.45, z = -48.72, Type = 1,
			Tid = 
			{
				[12005] = 4,
			},
		},
		[7] = 
		{
			x = -285.72, y = -3.45, z = -44.79, Type = 2,
			Tid = 
			{
				[2016] = 1,
			},
		},
		[10] = 
		{
			x = -267.87, y = -3.45, z = -53.34, Type = 2,
			Tid = 
			{
				[2018] = 1,
			},
		},
		[11] = 
		{
			x = -266.29, y = -3.45, z = -46.09, Type = 2,
			Tid = 
			{
				[2016] = 1,
			},
		},
		[13] = 
		{
			x = -283.85, y = -3.45, z = -52.57, Type = 2,
			Tid = 
			{
				[2011] = 1,
			},
		},
		[30] = 
		{
			x = -282.20, y = -8.39, z = -84.96, Type = 2,
			Tid = 
			{
				[2010] = 1,
			},
		},
		[2] = 
		{
			x = -277.47, y = -3.53, z = -56.34, Type = 2,
			Tid = 
			{
				[2012] = 1,
			},
		},
		[3] = 
		{
			x = -276.93, y = -3.45, z = -40.40, Type = 2,
			Tid = 
			{
				[2016] = 1,
			},
		},
		[6] = 
		{
			x = -284.70, y = -8.38, z = -83.78, Type = 2,
			Tid = 
			{
				[2282] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo