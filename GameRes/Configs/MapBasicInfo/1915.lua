local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "塔雷坤平台【剧情】",
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
		[14082] = 
		{
			[1] = { x = -221.53, y = 95.01, z = 336.83, name = "温妮莎·德佩拉", level = 58, SortID = 5 },
		},
	},
	Npc = 
	{
		[4217] = 
		{
			[1] = { x = -229.04, y = 95.01, z = 340.24, name = "尼古拉斯", SortID = 295 },
		},
		[4215] = 
		{
			[1] = { x = -213.92, y = 95.01, z = 333.22, name = "迪波", SortID = 296 },
		},
		[4216] = 
		{
			[1] = { x = -221.55, y = 95.11, z = 336.92, name = "温妮莎·德佩拉", SortID = 297 },
		},
		[4218] = 
		{
			[1] = { x = -229.04, y = 95.01, z = 340.24, name = "尼古拉斯", SortID = 4 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[467] = { x = -172.91, y = 95.12, z = 340.35, name = "塔雷坤相关相位", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[680] = 
		{
			[1] = { x = -206.86, y = 95.00, z = 331.80 },
			[2] = { x = -185.45, y = 95.00, z = 322.43 },
		},
		[681] = 
		{
			[1] = { x = -206.86, y = 95.00, z = 331.80 },
			[2] = { x = -185.45, y = 95.00, z = 322.43 },
		},
		[682] = 
		{
			[1] = { x = -206.86, y = 95.00, z = 331.80 },
			[2] = { x = -185.45, y = 95.00, z = 322.43 },
		},
	},
	Entity = 
	{
		[5] = 
		{
			x = -221.53, y = 95.01, z = 336.83, Type = 1,
			Tid = 
			{
				[14082] = 1,
			},
		},
		[295] = 
		{
			x = -229.04, y = 95.01, z = 340.24, Type = 2,
			Tid = 
			{
				[4217] = 1,
			},
		},
		[296] = 
		{
			x = -213.92, y = 95.01, z = 333.22, Type = 2,
			Tid = 
			{
				[4215] = 1,
			},
		},
		[297] = 
		{
			x = -221.55, y = 95.11, z = 336.92, Type = 2,
			Tid = 
			{
				[4216] = 1,
			},
		},
		[4] = 
		{
			x = -229.04, y = 95.01, z = 340.24, Type = 2,
			Tid = 
			{
				[4218] = 1,
			},
		},
		[2] = 
		{
			x = -206.86, y = 95.00, z = 331.80, Type = 6,
			Tid = 
			{
				[680] = 3,
				[681] = 3,
				[682] = 2,
			},
		},
		[3] = 
		{
			x = -185.45, y = 95.00, z = 322.43, Type = 6,
			Tid = 
			{
				[680] = 3,
				[681] = 3,
				[682] = 2,
			},
		},
	},
	TargetPoint = 
	{
		[10] = { posx = -213.13, posy = 95.01, posz = 335.33, rotx = 0.00, roty = 302.35, rotz = 0.00 },
	},

}
return MapInfo