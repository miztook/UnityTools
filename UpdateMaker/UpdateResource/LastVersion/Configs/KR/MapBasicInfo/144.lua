local MapInfo = 
{
	MapType = 3,
	Remarks = "废弃军营相位",
	TextDisplayName = "버려진 주둔지",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Forest",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	PKMode= 1,
	Monster = 
	{
		[12007] = 
		{
			[1] = { x = -189.09, y = -4.18, z = -65.14, name = "디포 그림자", level = 30, SortID = 1 },
		},
		[12217] = 
		{
			[1] = { x = -189.09, y = -4.18, z = -65.14, name = "흑마법사 탈영병", level = 31, DropItemIds = " " },
		},
		[12218] = 
		{
			[1] = { x = -189.09, y = -4.18, z = -65.14, name = "검사 탈영병", level = 31, DropItemIds = " " },
		},
		[12219] = 
		{
			[1] = { x = -190.30, y = -4.22, z = -66.42, name = "백부장 탈영병", level = 31, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[2002] = 
		{
			[1] = { x = -189.06, y = -4.18, z = -65.21, name = "디포", SortID = 2 },
		},
		[2003] = 
		{
			[1] = { x = -184.70, y = -4.21, z = -61.62, name = "바네사 드페라", SortID = 3 },
		},
		[2277] = 
		{
			[1] = { x = -189.06, y = -4.18, z = -65.21, name = "제2군단 탈영병", FunctionName = " " },
		},
		[2278] = 
		{
			[1] = { x = -189.06, y = -4.18, z = -65.21, name = "제2군단 탈영병", FunctionName = " " },
		},
		[2279] = 
		{
			[1] = { x = -189.06, y = -4.18, z = -65.21, name = "마크시무스", FunctionName = " " },
		},
		[2285] = 
		{
			[1] = { x = -196.78, y = -4.71, z = -70.12, name = "디포", FunctionName = " " },
		},
		[2283] = 
		{
			[1] = { x = -190.75, y = -4.42, z = -73.96, name = "바네사 드페라", FunctionName = " " },
		},
		[2284] = 
		{
			[1] = { x = -192.05, y = -4.42, z = -70.63, name = "검은 옷을 입은 사람", FunctionName = " " },
		},
		[2281] = 
		{
			[1] = { x = -191.43, y = -4.68, z = -67.93, name = "루나 엘린", FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[224] = { x = -182.77, y = 2.67, z = -64.63, name = "第二次相位区域", worldId = 0, PkMode = 1, IsCanHawkeye = true, QuestID = {2214} },
			[225] = { x = -196.10, y = 1.00, z = -76.95, name = "抵达区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -189.09, y = -4.18, z = -65.14, Type = 1,
			Tid = 
			{
				[12007] = 1,
			},
		},
		[8] = 
		{
			x = -189.09, y = -4.18, z = -65.14, Type = 1,
			Tid = 
			{
				[12217] = 5,
				[12218] = 5,
			},
		},
		[9] = 
		{
			x = -190.30, y = -4.22, z = -66.42, Type = 1,
			Tid = 
			{
				[12219] = 1,
			},
		},
		[2] = 
		{
			x = -189.06, y = -4.18, z = -65.21, Type = 2,
			Tid = 
			{
				[2002] = 1,
			},
		},
		[3] = 
		{
			x = -184.70, y = -4.21, z = -61.62, Type = 2,
			Tid = 
			{
				[2003] = 1,
			},
		},
		[4] = 
		{
			x = -189.06, y = -4.18, z = -65.21, Type = 2,
			Tid = 
			{
				[2277] = 5,
				[2278] = 5,
				[2279] = 1,
			},
		},
		[5] = 
		{
			x = -196.78, y = -4.71, z = -70.12, Type = 2,
			Tid = 
			{
				[2285] = 1,
			},
		},
		[6] = 
		{
			x = -190.75, y = -4.42, z = -73.96, Type = 2,
			Tid = 
			{
				[2283] = 1,
			},
		},
		[7] = 
		{
			x = -192.05, y = -4.42, z = -70.63, Type = 2,
			Tid = 
			{
				[2284] = 1,
			},
		},
		[10] = 
		{
			x = -191.43, y = -4.68, z = -67.93, Type = 2,
			Tid = 
			{
				[2281] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -190.11, posy = -4.22, posz = -67.41, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
