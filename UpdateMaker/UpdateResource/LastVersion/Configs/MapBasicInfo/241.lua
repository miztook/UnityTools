local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "朱拉丝方舟·普通",
	Length = 400,
	Width = 400,
	NavMeshName = "Dungn04_Zuras01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/JURAS_ARK",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn04_Zuras01.prefab",
	PKMode= 1,
	Monster = 
	{
		[23100] = 
		{
			[1] = { x = -2.36, y = 6.70, z = -107.12, name = "血武者", level = 40 },
			[2] = { x = 3.00, y = 6.70, z = -109.17, name = "血武者", level = 40 },
		},
		[23102] = 
		{
			[1] = { x = 26.01, y = 0.93, z = -83.42, name = "黑翼卫兵", level = 40 },
			[2] = { x = 21.87, y = 0.93, z = -86.46, name = "黑翼卫兵", level = 40 },
			[3] = { x = 0.53, y = 1.87, z = -22.97, name = "黑翼卫兵", level = 40 },
		},
		[23104] = 
		{
			[1] = { x = 26.01, y = 0.93, z = -83.42, name = "德法祭祀", level = 40 },
			[2] = { x = 0.53, y = 1.87, z = -22.97, name = "德法祭祀", level = 40 },
		},
		[23106] = 
		{
			[1] = { x = 0.36, y = 5.77, z = -58.42, name = "德法祭祀", level = 40 },
		},
		[23107] = 
		{
			[1] = { x = 0.36, y = 5.77, z = -58.42, name = "黑翼卫兵", level = 40 },
			[2] = { x = 2.86, y = 5.77, z = -58.09, name = "黑翼卫兵", level = 40 },
		},
		[23103] = 
		{
			[1] = { x = 0.55, y = 1.87, z = -34.39, name = "黑翼祭祀", level = 40 },
			[2] = { x = 0.53, y = 1.87, z = -29.51, name = "黑翼祭祀", level = 40 },
			[3] = { x = 0.53, y = 1.87, z = -24.13, name = "黑翼祭祀", level = 40 },
		},
		[23105] = 
		{
			[1] = { x = 0.53, y = 1.87, z = -18.86, name = "德法指挥官", level = 40 },
		},
		[23200] = 
		{
			[1] = { x = 0.45, y = 1.87, z = -18.80, name = "黑翼大主教", level = 40 },
		},
		[23201] = 
		{
			[1] = { x = -0.14, y = 5.67, z = 28.52, name = "方舟巡查者A型", level = 40 },
		},
		[23202] = 
		{
			[1] = { x = -0.14, y = 5.67, z = 28.52, name = "方舟巡查者B型", level = 40 },
		},
		[23300] = 
		{
			[1] = { x = -0.20, y = 5.67, z = 37.24, name = "方舟守护者", level = 40,IsBoss = true },
		},
		[23301] = 
		{
			[1] = { x = -0.20, y = 5.67, z = 37.24, name = "方舟守护者", level = 40,IsBoss = true },
		},
	},
	Npc = 
	{
		[60055] = 
		{
			[1] = { x = 7.19, y = 10.70, z = -83.21, name = "席坎兰尼" },
		},
	},
	Region = 
	{
		[2] = 
		{
			[250] = { x = 0.18, y = 5.73, z = 22.55, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1 },
			[251] = { x = 18.06, y = 4.07, z = -103.10, name = "对话1", worldId = 0, PkMode = 1 },
			[252] = { x = 19.49, y = 4.71, z = -62.74, name = "对话2", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -2.36, y = 6.70, z = -107.12, Type = 1,
			Tid = 
			{
				[23100] = 1,
			},
		},
		[19] = 
		{
			x = 3.00, y = 6.70, z = -109.17, Type = 1,
			Tid = 
			{
				[23100] = 1,
			},
		},
		[2] = 
		{
			x = 26.01, y = 0.93, z = -83.42, Type = 1,
			Tid = 
			{
				[23102] = 1,
				[23104] = 2,
			},
		},
		[20] = 
		{
			x = 21.87, y = 0.93, z = -86.46, Type = 1,
			Tid = 
			{
				[23102] = 1,
			},
		},
		[3] = 
		{
			x = 0.36, y = 5.77, z = -58.42, Type = 1,
			Tid = 
			{
				[23106] = 2,
				[23107] = 1,
			},
		},
		[21] = 
		{
			x = 2.86, y = 5.77, z = -58.09, Type = 1,
			Tid = 
			{
				[23107] = 1,
			},
		},
		[4] = 
		{
			x = 0.55, y = 1.87, z = -34.39, Type = 1,
			Tid = 
			{
				[23103] = 2,
			},
		},
		[5] = 
		{
			x = 0.53, y = 1.87, z = -29.51, Type = 1,
			Tid = 
			{
				[23103] = 2,
			},
		},
		[6] = 
		{
			x = 0.53, y = 1.87, z = -24.13, Type = 1,
			Tid = 
			{
				[23103] = 2,
			},
		},
		[7] = 
		{
			x = 0.53, y = 1.87, z = -18.86, Type = 1,
			Tid = 
			{
				[23105] = 2,
			},
		},
		[8] = 
		{
			x = 0.53, y = 1.87, z = -22.97, Type = 1,
			Tid = 
			{
				[23102] = 2,
				[23104] = 2,
			},
		},
		[9] = 
		{
			x = 0.45, y = 1.87, z = -18.80, Type = 1,
			Tid = 
			{
				[23200] = 1,
			},
		},
		[10] = 
		{
			x = -0.14, y = 5.67, z = 28.52, Type = 1,
			Tid = 
			{
				[23201] = 1,
				[23202] = 1,
			},
		},
		[11] = 
		{
			x = -0.20, y = 5.67, z = 37.24, Type = 1,
			Tid = 
			{
				[23300] = 1,
			},
		},
		[18] = 
		{
			x = -0.20, y = 5.67, z = 37.24, Type = 1,
			Tid = 
			{
				[23301] = 1,
			},
		},
		[23] = 
		{
			x = 7.19, y = 10.70, z = -83.21, Type = 2,
			Tid = 
			{
				[60055] = 1,
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
		[22] = 
		{
			x = -0.22, y = 10.70, z = -90.99, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 9.73, posy = 14.88, posz = 67.20, rotx = 0.00, roty = 147.99, rotz = 0.00 },
		[2] = { posx = 0.05, posy = 5.73, posz = 23.29, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -1.76, posy = 5.73, posz = 22.53, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = 1.69, posy = 5.73, posz = 22.51, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = -3.84, posy = 5.73, posz = 22.97, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = 3.63, posy = 5.73, posz = 23.12, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo