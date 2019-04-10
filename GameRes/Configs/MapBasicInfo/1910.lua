local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "帝国边境",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world05.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[14068] = 
		{
			[1] = { x = 98.23, y = 58.14, z = -41.31, name = "暴躁的新兵", level = 52, SortID = 1 },
		},
		[14072] = 
		{
			[1] = { x = 91.67, y = 58.14, z = -37.18, name = "好斗的士兵", level = 52, SortID = 2 },
		},
		[14074] = 
		{
			[1] = { x = 91.67, y = 58.14, z = -37.18, name = "暴躁的新兵", level = 52, SortID = 2 },
		},
		[14073] = 
		{
			[1] = { x = 106.51, y = 58.14, z = -38.27, name = "暴躁的新兵", level = 52, SortID = 3 },
		},
		[14075] = 
		{
			[1] = { x = 106.51, y = 58.14, z = -38.27, name = "暴躁的新兵", level = 52, SortID = 3 },
		},
	},
	Npc = 
	{
		[4048] = 
		{
			[1] = { x = 101.04, y = 58.42, z = -30.17, name = "焰晶", SortID = 122 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[438] = { x = 97.91, y = 62.78, z = -38.62, name = "声望无礼的挑战者", worldId = 0, PkMode = 0 },
			[439] = { x = 98.83, y = 62.04, z = -36.21, name = "声望训练新兵刷怪区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 98.23, y = 58.14, z = -41.31, Type = 1,
			Tid = 
			{
				[14068] = 1,
			},
		},
		[2] = 
		{
			x = 91.67, y = 58.14, z = -37.18, Type = 1,
			Tid = 
			{
				[14072] = 1,
				[14074] = 1,
			},
		},
		[3] = 
		{
			x = 106.51, y = 58.14, z = -38.27, Type = 1,
			Tid = 
			{
				[14073] = 1,
				[14075] = 1,
			},
		},
		[122] = 
		{
			x = 101.04, y = 58.42, z = -30.17, Type = 2,
			Tid = 
			{
				[4048] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -194.26, posy = 17.74, posz = -225.53, rotx = 0.00, roty = 139.21, rotz = 0.00 },
		[2] = { posx = 94.27, posy = 24.21, posz = -355.41, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -219.57, posy = 17.74, posz = -307.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -133.07, posy = 17.74, posz = -330.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = 99.12, posy = 58.14, posz = -38.31, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[8] = { posx = -202.10, posy = 17.89, posz = -289.19, rotx = 0.00, roty = 215.75, rotz = 0.00 },
		[9] = { posx = -208.09, posy = 60.17, posz = 69.76, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo