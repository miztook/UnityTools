local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "艾赛尼亚东部",
	Length = 600,
	Width = 600,
	NavMeshName = "World04Part1.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-1.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part1.prefab",
	PKMode= 1,
	Monster = 
	{
		[39300] = 
		{
			[1] = { x = 68.50, y = 60.40, z = 197.90, name = "巴风特", level = 40,IsBoss = true },
			[2] = { x = 110.20, y = 64.22, z = 78.70, name = "巴风特", level = 40,IsBoss = true },
			[3] = { x = -30.60, y = 74.10, z = 138.40, name = "巴风特", level = 40,IsBoss = true },
			[4] = { x = 17.00, y = 68.14, z = 190.90, name = "巴风特", level = 40,IsBoss = true },
		},
		[39301] = 
		{
			[1] = { x = -112.70, y = 23.65, z = -154.50, name = "巴风特", level = 42,IsBoss = true },
			[2] = { x = -18.90, y = 20.96, z = -183.80, name = "巴风特", level = 42,IsBoss = true },
			[3] = { x = -155.40, y = 32.39, z = -246.60, name = "巴风特", level = 42,IsBoss = true },
			[4] = { x = -165.20, y = 20.76, z = -210.00, name = "巴风特", level = 42,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[475] = { x = 33.59, y = 66.64, z = 150.65, name = "神之多人-1", worldId = 0, PkMode = 1 },
			[476] = { x = 32.92, y = 115.49, z = 152.49, name = "神之多人-2", worldId = 0, PkMode = 1 },
			[477] = { x = 32.85, y = 123.89, z = 152.42, name = "神之多人-3", worldId = 0, PkMode = 1 },
			[478] = { x = 29.01, y = 65.99, z = 153.78, name = "神之多人-4", worldId = 0, PkMode = 1 },
			[479] = { x = -121.15, y = 24.34, z = -175.54, name = "神之多人-5", worldId = 0, PkMode = 1 },
			[480] = { x = -119.75, y = 19.36, z = -172.54, name = "神之多人-6", worldId = 0, PkMode = 1 },
			[481] = { x = -125.96, y = 19.03, z = -172.54, name = "神之多人-7", worldId = 0, PkMode = 1 },
			[482] = { x = -127.19, y = 19.68, z = -170.11, name = "神之多人-8", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[163] = 
		{
			x = 68.50, y = 60.40, z = 197.90, Type = 1,
			Tid = 
			{
				[39300] = 1,
			},
		},
		[164] = 
		{
			x = 110.20, y = 64.22, z = 78.70, Type = 1,
			Tid = 
			{
				[39300] = 1,
			},
		},
		[165] = 
		{
			x = -30.60, y = 74.10, z = 138.40, Type = 1,
			Tid = 
			{
				[39300] = 1,
			},
		},
		[166] = 
		{
			x = 17.00, y = 68.14, z = 190.90, Type = 1,
			Tid = 
			{
				[39300] = 1,
			},
		},
		[167] = 
		{
			x = -112.70, y = 23.65, z = -154.50, Type = 1,
			Tid = 
			{
				[39301] = 1,
			},
		},
		[168] = 
		{
			x = -18.90, y = 20.96, z = -183.80, Type = 1,
			Tid = 
			{
				[39301] = 1,
			},
		},
		[169] = 
		{
			x = -155.40, y = 32.39, z = -246.60, Type = 1,
			Tid = 
			{
				[39301] = 1,
			},
		},
		[170] = 
		{
			x = -165.20, y = 20.76, z = -210.00, Type = 1,
			Tid = 
			{
				[39301] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[15] = { posx = 58.40, posy = 65.60, posz = 210.50, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[16] = { posx = 110.20, posy = 63.50, posz = 78.70, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[17] = { posx = -37.00, posy = 74.90, posz = 138.40, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[18] = { posx = 17.00, posy = 69.00, posz = 190.90, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[19] = { posx = -112.70, posy = 21.80, posz = -154.50, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[20] = { posx = -18.90, posy = 20.60, posz = -183.80, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[21] = { posx = -155.40, posy = 34.50, posz = -246.60, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[22] = { posx = -165.20, posy = 19.70, posz = -194.40, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo