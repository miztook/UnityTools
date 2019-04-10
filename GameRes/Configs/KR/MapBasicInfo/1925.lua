local MapInfo = 
{
	MapType = 3,
	Remarks = "新手副本",
	TextDisplayName = "아르카니아 균열",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn00_EmpireRelicPrologue.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_Start.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn00_EmpireRelicPrologue.prefab",
	Monster = 
	{
		[14205] = 
		{
			[1] = { x = 42.37, y = 71.02, z = 138.07, name = "니콜라스", level = 60, SortID = 3,IsBoss = true },
		},
		[14202] = 
		{
			[1] = { x = 53.20, y = 71.01, z = 143.80, name = "니콜라스", level = 60, SortID = 4,IsBoss = true },
			[2] = { x = 3.00, y = 71.02, z = -70.40, name = "니콜라스", level = 60, SortID = 10,IsBoss = true },
		},
		[14203] = 
		{
			[1] = { x = 28.00, y = 71.02, z = 130.00, name = "니콜라스", level = 60, SortID = 1,IsBoss = true },
		},
		[14204] = 
		{
			[1] = { x = -18.80, y = 71.02, z = 104.00, name = "맵5-트레이쿤 플랫폼【던전】-비행 몬스터3", level = 60, SortID = 6 },
			[2] = { x = 2.00, y = 71.02, z = 138.70, name = "맵5-트레이쿤 플랫폼【던전】-비행 몬스터3", level = 60, SortID = 7 },
			[3] = { x = 23.10, y = 71.02, z = 102.80, name = "맵5-트레이쿤 플랫폼【던전】-비행 몬스터3", level = 60, SortID = 8 },
		},
		[14201] = 
		{
			[1] = { x = 21.70, y = 71.02, z = 126.10, name = "니콜라스", level = 56, SortID = 2,IsBoss = true },
		},
	},
	Npc = 
	{
		[4219] = 
		{
			[1] = { x = 13.98, y = 71.02, z = 117.70, name = "벨릭의 화신", SortID = 5 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -5.00, y = 71.02, z = 111.21, name = "", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[3] = 
		{
			x = 42.37, y = 71.02, z = 138.07, Type = 1,
			Tid = 
			{
				[14205] = 1,
			},
		},
		[4] = 
		{
			x = 53.20, y = 71.01, z = 143.80, Type = 1,
			Tid = 
			{
				[14202] = 1,
			},
		},
		[1] = 
		{
			x = 28.00, y = 71.02, z = 130.00, Type = 1,
			Tid = 
			{
				[14203] = 1,
			},
		},
		[6] = 
		{
			x = -18.80, y = 71.02, z = 104.00, Type = 1,
			Tid = 
			{
				[14204] = 1,
			},
		},
		[7] = 
		{
			x = 2.00, y = 71.02, z = 138.70, Type = 1,
			Tid = 
			{
				[14204] = 1,
			},
		},
		[8] = 
		{
			x = 23.10, y = 71.02, z = 102.80, Type = 1,
			Tid = 
			{
				[14204] = 1,
			},
		},
		[2] = 
		{
			x = 21.70, y = 71.02, z = 126.10, Type = 1,
			Tid = 
			{
				[14201] = 1,
			},
		},
		[10] = 
		{
			x = 3.00, y = 71.02, z = -70.40, Type = 1,
			Tid = 
			{
				[14202] = 1,
			},
		},
		[5] = 
		{
			x = 13.98, y = 71.02, z = 117.70, Type = 2,
			Tid = 
			{
				[4219] = 1,
			},
		},
		[9] = 
		{
			x = 1.98, y = 71.02, z = 68.22, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[2] = { posx = 1.90, posy = 71.02, posz = -84.70, rotx = 0.00, roty = 330.00, rotz = 0.00 },
		[3] = { posx = 10.12, posy = 71.01, posz = 119.60, rotx = 0.00, roty = 60.00, rotz = 0.00 },
		[4] = { posx = -5.00, posy = 71.02, posz = 111.00, rotx = 0.00, roty = 60.00, rotz = 0.00 },
		[5] = { posx = 53.20, posy = 71.01, posz = 143.80, rotx = 0.00, roty = 240.00, rotz = 0.00 },
	},

}
return MapInfo
