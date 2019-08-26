local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "神圣帝国遗址",
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
			[1] = { x = 10.22, y = 38.02, z = -71.64, name = "血武者", level = 1, SortID = 3 },
		},
		[40004] = 
		{
			[1] = { x = 32.48, y = 46.38, z = -49.90, name = "普里昂战士", level = 1, SortID = 4 },
			[2] = { x = 62.60, y = 39.28, z = -57.12, name = "普里昂战士", level = 1, SortID = 17 },
		},
		[40000] = 
		{
			[1] = { x = 11.50, y = 71.37, z = 107.80, name = "魔龙暴君", level = 1, SortID = 11,IsBoss = true },
		},
		[40001] = 
		{
			[1] = { x = -5.70, y = 71.37, z = 91.30, name = "魔龙暴君", level = 1, SortID = 12,IsBoss = true },
		},
		[40003] = 
		{
			[1] = { x = 62.60, y = 39.28, z = -57.12, name = "普里昂战士", level = 1, SortID = 17 },
		},
		[40005] = 
		{
			[1] = { x = -48.43, y = 0.00, z = 158.32, name = "巴风特", level = 1, SortID = 5 },
		},
		[40006] = 
		{
			[1] = { x = -82.49, y = 0.08, z = 145.89, name = "元素浮雕", level = 4, SortID = 6 },
		},
		[40007] = 
		{
			[1] = { x = 32.54, y = 46.38, z = -49.36, name = "元素浮雕", level = 4, SortID = 7 },
		},
		[40008] = 
		{
			[1] = { x = -82.25, y = 0.08, z = 145.89, name = "元素浮雕", level = 4, SortID = 10 },
		},
		[40009] = 
		{
			[1] = { x = 33.00, y = 46.61, z = -50.80, name = "石碑空", level = 10, SortID = 19 },
		},
		[40010] = 
		{
			[1] = { x = 33.00, y = 46.38, z = -50.80, name = "石碑空", level = 10, SortID = 22 },
		},
		[40011] = 
		{
			[1] = { x = 33.00, y = 46.38, z = -50.80, name = "石碑空", level = 10, SortID = 23 },
		},
		[40012] = 
		{
			[1] = { x = -18.07, y = 31.43, z = -100.07, name = "石碑空", level = 10, SortID = 24 },
			[2] = { x = -0.40, y = 38.02, z = -82.10, name = "石碑空", level = 10, SortID = 25 },
			[3] = { x = 23.60, y = 46.38, z = -57.80, name = "石碑空", level = 10, SortID = 26 },
		},
		[40014] = 
		{
			[1] = { x = -82.49, y = 0.08, z = 145.89, name = "守备军", level = 60, SortID = 1 },
		},
		[40015] = 
		{
			[1] = { x = -16.00, y = 31.43, z = -105.04, name = "联盟军新兵", level = 2, SortID = 27 },
		},
		[40016] = 
		{
			[1] = { x = 43.86, y = 46.38, z = -44.50, name = "联盟军新兵", level = 2, SortID = 28 },
		},
	},
	Npc = 
	{
		[30000] = 
		{
			[1] = { x = -25.01, y = 31.43, z = -101.93, name = "克莱丝", SortID = 8 },
		},
		[30001] = 
		{
			[1] = { x = 17.23, y = 55.78, z = 7.06, name = "", SortID = 9 },
		},
		[30003] = 
		{
			[1] = { x = 7.96, y = 38.02, z = -73.57, name = "", SortID = 18 },
			[2] = { x = 21.51, y = 46.38, z = -46.21, name = "", SortID = 29 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[334] = { x = -16.90, y = 31.62, z = -99.87, name = "摇杆教学", worldId = 0, PkMode = 1 },
			[335] = { x = 0.82, y = 38.02, z = -80.02, name = "自动移动教学", worldId = 0, PkMode = 1 },
			[336] = { x = 24.20, y = 46.38, z = -57.17, name = "石碑区域", worldId = 0, PkMode = 1 },
			[337] = { x = -37.21, y = 55.78, z = 136.77, name = "鹰眼区域", worldId = 0, PkMode = 1, IsCanHawkeye = true },
			[338] = { x = 22.14, y = 55.78, z = -11.84, name = "平台区域", worldId = 0, PkMode = 1 },
			[339] = { x = -41.78, y = 0.08, z = 160.45, name = "裂隙中心", worldId = 0, PkMode = 1 },
			[340] = { x = -22.74, y = 31.43, z = -105.44, name = "遥感教学触发区域", worldId = 0, PkMode = 1 },
			[341] = { x = 2.69, y = 70.99, z = 63.37, name = "巨龙CG触发", worldId = 0, PkMode = 1 },
			[342] = { x = -4.55, y = 82.74, z = 87.93, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1, CameraDistance = 15 },
			[343] = { x = 17.30, y = 55.78, z = 7.06, name = "鹰眼教学触发教学", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[567] = 
		{
			[1] = { x = 32.58, y = 46.61, z = -49.17 },
		},
		[568] = 
		{
			[1] = { x = -82.25, y = 0.08, z = 145.89 },
		},
	},
	Entity = 
	{
		[3] = 
		{
			x = 10.22, y = 38.02, z = -71.64, Type = 1,
			Tid = 
			{
				[40002] = 2,
			},
		},
		[4] = 
		{
			x = 32.48, y = 46.38, z = -49.90, Type = 1,
			Tid = 
			{
				[40004] = 3,
			},
		},
		[11] = 
		{
			x = 11.50, y = 71.37, z = 107.80, Type = 1,
			Tid = 
			{
				[40000] = 1,
			},
		},
		[12] = 
		{
			x = -5.70, y = 71.37, z = 91.30, Type = 1,
			Tid = 
			{
				[40001] = 1,
			},
		},
		[17] = 
		{
			x = 62.60, y = 39.28, z = -57.12, Type = 1,
			Tid = 
			{
				[40003] = 1,
				[40004] = 1,
			},
		},
		[5] = 
		{
			x = -48.43, y = 0.00, z = 158.32, Type = 1,
			Tid = 
			{
				[40005] = 1,
			},
		},
		[6] = 
		{
			x = -82.49, y = 0.08, z = 145.89, Type = 1,
			Tid = 
			{
				[40006] = 1,
			},
		},
		[7] = 
		{
			x = 32.54, y = 46.38, z = -49.36, Type = 1,
			Tid = 
			{
				[40007] = 1,
			},
		},
		[10] = 
		{
			x = -82.25, y = 0.08, z = 145.89, Type = 1,
			Tid = 
			{
				[40008] = 1,
			},
		},
		[19] = 
		{
			x = 33.00, y = 46.61, z = -50.80, Type = 1,
			Tid = 
			{
				[40009] = 1,
			},
		},
		[22] = 
		{
			x = 33.00, y = 46.38, z = -50.80, Type = 1,
			Tid = 
			{
				[40010] = 1,
			},
		},
		[23] = 
		{
			x = 33.00, y = 46.38, z = -50.80, Type = 1,
			Tid = 
			{
				[40011] = 1,
			},
		},
		[24] = 
		{
			x = -18.07, y = 31.43, z = -100.07, Type = 1,
			Tid = 
			{
				[40012] = 1,
			},
		},
		[25] = 
		{
			x = -0.40, y = 38.02, z = -82.10, Type = 1,
			Tid = 
			{
				[40012] = 1,
			},
		},
		[26] = 
		{
			x = 23.60, y = 46.38, z = -57.80, Type = 1,
			Tid = 
			{
				[40012] = 1,
			},
		},
		[1] = 
		{
			x = -82.49, y = 0.08, z = 145.89, Type = 1,
			Tid = 
			{
				[40014] = 1,
			},
		},
		[27] = 
		{
			x = -16.00, y = 31.43, z = -105.04, Type = 1,
			Tid = 
			{
				[40015] = 1,
			},
		},
		[28] = 
		{
			x = 43.86, y = 46.38, z = -44.50, Type = 1,
			Tid = 
			{
				[40016] = 1,
			},
		},
		[8] = 
		{
			x = -25.01, y = 31.43, z = -101.93, Type = 2,
			Tid = 
			{
				[30000] = 1,
			},
		},
		[9] = 
		{
			x = 17.23, y = 55.78, z = 7.06, Type = 2,
			Tid = 
			{
				[30001] = 1,
			},
		},
		[18] = 
		{
			x = 7.96, y = 38.02, z = -73.57, Type = 2,
			Tid = 
			{
				[30003] = 1,
			},
		},
		[29] = 
		{
			x = 21.51, y = 46.38, z = -46.21, Type = 2,
			Tid = 
			{
				[30003] = 1,
			},
		},
		[2] = 
		{
			x = 22.31, y = 46.45, z = -59.79, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
		[15] = 
		{
			x = 23.29, y = 55.78, z = -15.31, Type = 4,
			Tid = 
			{
				[8] = 0,
			},
		},
		[16] = 
		{
			x = 11.91, y = 55.78, z = 27.59, Type = 4,
			Tid = 
			{
				[17] = 0,
			},
		},
		[20] = 
		{
			x = 0.29, y = 71.37, z = 68.60, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[21] = 
		{
			x = -11.20, y = 71.37, z = 114.70, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
		[13] = 
		{
			x = 32.58, y = 46.61, z = -49.17, Type = 6,
			Tid = 
			{
				[567] = 1,
			},
		},
		[14] = 
		{
			x = -82.25, y = 0.08, z = 145.89, Type = 6,
			Tid = 
			{
				[568] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -28.83, posy = -0.08, posz = 165.36, rotx = 0.00, roty = 248.97, rotz = 0.00 },
		[2] = { posx = 17.19, posy = 55.91, posz = 6.95, rotx = 0.00, roty = 345.99, rotz = 0.00 },
		[3] = { posx = 17.26, posy = 56.32, posz = 6.91, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -52.66, posy = 0.00, posz = 156.78, rotx = 0.00, roty = 250.00, rotz = 0.00 },
		[5] = { posx = 11.50, posy = 71.37, posz = 107.80, rotx = 0.00, roty = 225.24, rotz = 0.00 },
		[6] = { posx = -5.72, posy = 70.80, posz = 91.85, rotx = 0.00, roty = 47.60, rotz = 0.00 },
		[7] = { posx = -76.88, posy = 0.08, posz = 148.03, rotx = 0.00, roty = 249.12, rotz = 0.00 },
	},

}
return MapInfo