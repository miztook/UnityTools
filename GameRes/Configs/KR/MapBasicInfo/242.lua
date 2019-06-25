local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "주라스 방주 - 악몽",
	Length = 400,
	Width = 400,
	NavMeshName = "Dungn04_Zuras01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/JURAS_ARK",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn04_Zuras01.prefab",
	Monster = 
	{
		[23120] = 
		{
			[1] = { x = 0.14, y = 6.70, z = -110.45, name = "혈전사", level = 40 },
			[2] = { x = 0.14, y = 6.70, z = -105.58, name = "혈전사", level = 40 },
		},
		[23122] = 
		{
			[1] = { x = 21.98, y = 0.93, z = -83.42, name = "시칸 병사", level = 40 },
			[2] = { x = 27.18, y = 0.93, z = -83.42, name = "시칸 병사", level = 40 },
			[3] = { x = 0.53, y = 1.87, z = -22.97, name = "시칸 병사", level = 40 },
		},
		[23124] = 
		{
			[1] = { x = 27.18, y = 0.93, z = -83.42, name = "데바 사제", level = 40 },
			[2] = { x = 0.53, y = 1.87, z = -22.97, name = "데바 사제", level = 40 },
		},
		[23126] = 
		{
			[1] = { x = -0.04, y = 5.77, z = -59.36, name = "데바 사제", level = 40 },
		},
		[23127] = 
		{
			[1] = { x = -0.04, y = 5.77, z = -59.36, name = "시칸 병사", level = 40 },
			[2] = { x = 5.06, y = 5.77, z = -58.30, name = "시칸 병사", level = 40 },
		},
		[23123] = 
		{
			[1] = { x = 0.55, y = 1.87, z = -34.39, name = "시칸 사제", level = 40 },
			[2] = { x = 0.53, y = 1.87, z = -29.51, name = "시칸 사제", level = 40 },
			[3] = { x = 0.53, y = 1.87, z = -24.13, name = "시칸 사제", level = 40 },
		},
		[23125] = 
		{
			[1] = { x = 0.53, y = 1.87, z = -18.86, name = "데바 지휘관", level = 40 },
		},
		[23220] = 
		{
			[1] = { x = 0.45, y = 1.87, z = -18.80, name = "시칸 대주교", level = 40 },
		},
		[23221] = 
		{
			[1] = { x = -0.14, y = 5.67, z = 28.52, name = "방주 순찰병 A형", level = 40 },
		},
		[23222] = 
		{
			[1] = { x = -0.14, y = 5.67, z = 28.52, name = "방주 순찰병 B형", level = 40 },
		},
		[23320] = 
		{
			[1] = { x = -0.20, y = 5.67, z = 37.24, name = "방주 수호자", level = 40,IsBoss = true },
		},
		[23321] = 
		{
			[1] = { x = 0.00, y = 5.67, z = 19.56, name = "방주 수호자", level = 40,IsBoss = true },
			[2] = { x = 0.00, y = 5.67, z = 19.56, name = "방주 수호자", level = 40,IsBoss = true },
		},
		[23322] = 
		{
			[1] = { x = 0.00, y = 5.67, z = 19.56, name = "방주 수호자", level = 40,IsBoss = true },
			[2] = { x = 0.00, y = 5.67, z = 19.56, name = "방주 수호자", level = 40,IsBoss = true },
		},
		[23301] = 
		{
			[1] = { x = -0.20, y = 5.67, z = 37.24, name = "방주 수호자", level = 40,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[250] = { x = 0.18, y = 5.73, z = 22.55, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
			[252] = { x = 17.83, y = 4.16, z = -104.44, name = "对话1", worldId = 0, PkMode = 0 },
			[253] = { x = 17.23, y = 5.30, z = -61.71, name = "对话2", worldId = 0, PkMode = 0 },
			[254] = { x = -0.13, y = 10.76, z = -88.19, name = "对话0", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 0.14, y = 6.70, z = -110.45, Type = 1,
			Tid = 
			{
				[23120] = 1,
			},
		},
		[21] = 
		{
			x = 0.14, y = 6.70, z = -105.58, Type = 1,
			Tid = 
			{
				[23120] = 1,
			},
		},
		[2] = 
		{
			x = 21.98, y = 0.93, z = -83.42, Type = 1,
			Tid = 
			{
				[23122] = 1,
			},
		},
		[22] = 
		{
			x = 27.18, y = 0.93, z = -83.42, Type = 1,
			Tid = 
			{
				[23122] = 1,
				[23124] = 2,
			},
		},
		[3] = 
		{
			x = -0.04, y = 5.77, z = -59.36, Type = 1,
			Tid = 
			{
				[23126] = 2,
				[23127] = 1,
			},
		},
		[23] = 
		{
			x = 5.06, y = 5.77, z = -58.30, Type = 1,
			Tid = 
			{
				[23127] = 1,
			},
		},
		[4] = 
		{
			x = 0.55, y = 1.87, z = -34.39, Type = 1,
			Tid = 
			{
				[23123] = 2,
			},
		},
		[5] = 
		{
			x = 0.53, y = 1.87, z = -29.51, Type = 1,
			Tid = 
			{
				[23123] = 2,
			},
		},
		[6] = 
		{
			x = 0.53, y = 1.87, z = -24.13, Type = 1,
			Tid = 
			{
				[23123] = 2,
			},
		},
		[7] = 
		{
			x = 0.53, y = 1.87, z = -18.86, Type = 1,
			Tid = 
			{
				[23125] = 2,
			},
		},
		[8] = 
		{
			x = 0.53, y = 1.87, z = -22.97, Type = 1,
			Tid = 
			{
				[23122] = 2,
				[23124] = 2,
			},
		},
		[9] = 
		{
			x = 0.45, y = 1.87, z = -18.80, Type = 1,
			Tid = 
			{
				[23220] = 1,
			},
		},
		[10] = 
		{
			x = -0.14, y = 5.67, z = 28.52, Type = 1,
			Tid = 
			{
				[23221] = 1,
				[23222] = 1,
			},
		},
		[11] = 
		{
			x = -0.20, y = 5.67, z = 37.24, Type = 1,
			Tid = 
			{
				[23320] = 1,
			},
		},
		[18] = 
		{
			x = 0.00, y = 5.67, z = 19.56, Type = 1,
			Tid = 
			{
				[23321] = 1,
				[23322] = 1,
			},
		},
		[19] = 
		{
			x = 0.00, y = 5.67, z = 19.56, Type = 1,
			Tid = 
			{
				[23321] = 1,
				[23322] = 1,
			},
		},
		[20] = 
		{
			x = -0.20, y = 5.67, z = 37.24, Type = 1,
			Tid = 
			{
				[23301] = 1,
			},
		},
		[12] = 
		{
			x = 22.61, y = 1.16, z = -70.92, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
		[13] = 
		{
			x = -0.31, y = 4.83, z = -50.68, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
		[14] = 
		{
			x = -0.05, y = 5.74, z = -5.65, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
		[15] = 
		{
			x = 0.03, y = 5.67, z = 3.30, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[16] = 
		{
			x = -9.14, y = 5.67, z = 41.51, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[17] = 
		{
			x = 8.73, y = 5.67, z = 41.78, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 9.73, posy = 14.88, posz = 67.20, rotx = 0.00, roty = 147.99, rotz = 0.00 },
		[2] = { posx = 0.00, posy = 5.73, posz = 22.82, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -1.80, posy = 5.73, posz = 22.23, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = 1.80, posy = 5.73, posz = 22.23, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = -3.85, posy = 5.73, posz = 22.55, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = 3.85, posy = 5.73, posz = 22.55, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
