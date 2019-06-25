local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·伊斯莲试炼者·普通",
	TextDisplayName = "伊斯莲试炼者·普通",
	Length = 256,
	Width = 256,
	NavMeshName = "Dungn03_QXGJ01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/FAIRY_SPRING",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD03.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn03_QXGJ01.prefab",
	Monster = 
	{
		[22400] = 
		{
			[1] = { x = -9.00, y = 76.02, z = 86.58, name = "伊斯莲试炼者", level = 42,IsBoss = true },
		},
		[22401] = 
		{
			[1] = { x = -9.10, y = 76.02, z = 73.25, name = "幻影", level = 42 },
			[2] = { x = -9.10, y = 76.02, z = 73.25, name = "幻影", level = 42 },
			[3] = { x = -9.10, y = 76.02, z = 73.25, name = "幻影", level = 42 },
			[4] = { x = -9.10, y = 76.02, z = 67.30, name = "幻影", level = 42 },
			[5] = { x = -9.10, y = 76.02, z = 69.29, name = "幻影", level = 42 },
		},
		[22403] = 
		{
			[1] = { x = 36.88, y = 64.99, z = -40.07, name = "幻影", level = 42 },
		},
		[22404] = 
		{
			[1] = { x = 36.88, y = 64.99, z = -40.07, name = "幻影", level = 42 },
		},
		[22405] = 
		{
			[1] = { x = 36.71, y = 64.99, z = -20.82, name = "幻影", level = 42 },
		},
		[22406] = 
		{
			[1] = { x = -8.80, y = 57.66, z = -90.69, name = "腐化精灵", level = 42 },
		},
		[22402] = 
		{
			[1] = { x = -8.60, y = 76.02, z = 70.70, name = "幻影", level = 42 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[193] = { x = -8.88, y = 76.02, z = 71.14, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
		},
	},
	Mine = 
	{
		[125] = 
		{
			[1] = { x = 36.84, y = 64.99, z = -39.36 },
		},
	},
	Entity = 
	{
		[2] = 
		{
			x = -9.00, y = 76.02, z = 86.58, Type = 1,
			Tid = 
			{
				[22400] = 1,
			},
		},
		[7] = 
		{
			x = -9.10, y = 76.02, z = 73.25, Type = 1,
			Tid = 
			{
				[22401] = 6,
			},
		},
		[8] = 
		{
			x = -9.10, y = 76.02, z = 73.25, Type = 1,
			Tid = 
			{
				[22401] = 6,
			},
		},
		[9] = 
		{
			x = -9.10, y = 76.02, z = 73.25, Type = 1,
			Tid = 
			{
				[22401] = 8,
			},
		},
		[10] = 
		{
			x = -9.10, y = 76.02, z = 67.30, Type = 1,
			Tid = 
			{
				[22401] = 8,
			},
		},
		[11] = 
		{
			x = -9.10, y = 76.02, z = 69.29, Type = 1,
			Tid = 
			{
				[22401] = 8,
			},
		},
		[12] = 
		{
			x = 36.88, y = 64.99, z = -40.07, Type = 1,
			Tid = 
			{
				[22403] = 3,
				[22404] = 3,
			},
		},
		[13] = 
		{
			x = 36.71, y = 64.99, z = -20.82, Type = 1,
			Tid = 
			{
				[22405] = 3,
			},
		},
		[14] = 
		{
			x = -8.80, y = 57.66, z = -90.69, Type = 1,
			Tid = 
			{
				[22406] = 4,
			},
		},
		[15] = 
		{
			x = -8.60, y = 76.02, z = 70.70, Type = 1,
			Tid = 
			{
				[22402] = 6,
			},
		},
		[3] = 
		{
			x = -29.16, y = 75.96, z = 48.87, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[4] = 
		{
			x = 10.50, y = 75.96, z = 49.30, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[5] = 
		{
			x = 28.64, y = 64.93, z = -25.50, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[6] = 
		{
			x = -9.14, y = 58.16, z = -72.16, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[16] = 
		{
			x = -9.44, y = 75.96, z = 91.79, Type = 4,
			Tid = 
			{
				[20] = 0,
			},
		},
		[17] = 
		{
			x = 36.60, y = 64.99, z = -64.42, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[19] = 
		{
			x = -9.23, y = 63.42, z = -8.72, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[18] = 
		{
			x = 36.84, y = 64.99, z = -39.36, Type = 6,
			Tid = 
			{
				[125] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -0.44, posy = 76.03, posz = 62.97, rotx = 0.00, roty = 317.10, rotz = 0.00 },
		[2] = { posx = -9.20, posy = 57.66, posz = -77.85, rotx = 0.00, roty = 172.02, rotz = 0.00 },
		[3] = { posx = 36.94, posy = 64.99, posz = -58.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -9.98, posy = 76.02, posz = 58.91, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = -8.95, posy = 76.02, posz = 57.44, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = -10.56, posy = 76.02, posz = 57.29, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[7] = { posx = -7.30, posy = 76.02, posz = 57.23, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[8] = { posx = -12.22, posy = 76.02, posz = 57.00, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[9] = { posx = -5.68, posy = 76.02, posz = 56.90, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
