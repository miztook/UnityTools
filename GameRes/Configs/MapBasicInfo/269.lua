local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "提图斯神殿",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn06_EmpireRelic.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/BGM_Dunjeon_Tutorial",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn06_EmpireRelic.prefab",
	PKMode= 1,
	Monster = 
	{
		[14062] = 
		{
			[1] = { x = -13.90, y = 71.37, z = 83.44, name = "拉坎化身", level = 55, SortID = 2 },
		},
		[14063] = 
		{
			[1] = { x = -16.01, y = 71.37, z = 94.13, name = "席坎特化身", level = 55, SortID = 3 },
		},
		[14064] = 
		{
			[1] = { x = 2.34, y = 71.37, z = 99.35, name = "伊斯莲化身", level = 55, SortID = 5 },
		},
		[14065] = 
		{
			[1] = { x = 5.12, y = 71.37, z = 88.97, name = "洛克化身", level = 55, SortID = 6 },
		},
	},
	Npc = 
	{
		[4180] = 
		{
			[1] = { x = -6.93, y = 71.37, z = 68.76, name = "贝里克", SortID = 1 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[330] = { x = -13.71, y = 31.43, z = -95.80, name = "进入帝国遗址区域", worldId = 0, PkMode = 1 },
			[331] = { x = 74.00, y = 38.67, z = -60.52, name = "遗址的宝藏区域", worldId = 0, PkMode = 1 },
			[332] = { x = 27.15, y = 65.40, z = -30.90, name = "遗址军备平台区域", worldId = 0, PkMode = 1 },
			[333] = { x = 0.38, y = 71.37, z = 69.89, name = "神圣广场区域", worldId = 0, PkMode = 1 },
			[334] = { x = -6.70, y = 71.37, z = 94.69, name = "副本刷怪", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1 },
		},
	},
	Mine = 
	{
		[539] = 
		{
			[1] = { x = 5.47, y = 38.02, z = -76.74 },
			[2] = { x = 20.71, y = 55.78, z = -6.19 },
		},
		[535] = 
		{
			[1] = { x = -9.52, y = 71.37, z = 87.68 },
		},
		[536] = 
		{
			[1] = { x = -6.62, y = 71.37, z = 97.27 },
		},
		[537] = 
		{
			[1] = { x = -1.18, y = 71.37, z = 95.63 },
		},
		[538] = 
		{
			[1] = { x = -0.06, y = 71.37, z = 90.13 },
		},
	},
	Entity = 
	{
		[2] = 
		{
			x = -13.90, y = 71.37, z = 83.44, Type = 1,
			Tid = 
			{
				[14062] = 1,
			},
		},
		[3] = 
		{
			x = -16.01, y = 71.37, z = 94.13, Type = 1,
			Tid = 
			{
				[14063] = 1,
			},
		},
		[5] = 
		{
			x = 2.34, y = 71.37, z = 99.35, Type = 1,
			Tid = 
			{
				[14064] = 1,
			},
		},
		[6] = 
		{
			x = 5.12, y = 71.37, z = 88.97, Type = 1,
			Tid = 
			{
				[14065] = 1,
			},
		},
		[1] = 
		{
			x = -6.93, y = 71.37, z = 68.76, Type = 2,
			Tid = 
			{
				[4180] = 1,
			},
		},
		[4] = 
		{
			x = 11.58, y = 38.02, z = -70.57, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[9] = 
		{
			x = 49.41, y = 46.38, z = -53.48, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[10] = 
		{
			x = 6.60, y = 68.64, z = 52.40, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[18] = 
		{
			x = 12.48, y = 55.78, z = 25.49, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[26] = 
		{
			x = 32.54, y = 46.38, z = -49.26, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[11] = 
		{
			x = 5.47, y = 38.02, z = -76.74, Type = 6,
			Tid = 
			{
				[539] = 2,
			},
		},
		[15] = 
		{
			x = 20.71, y = 55.78, z = -6.19, Type = 6,
			Tid = 
			{
				[539] = 4,
			},
		},
		[7] = 
		{
			x = -9.52, y = 71.37, z = 87.68, Type = 6,
			Tid = 
			{
				[535] = 1,
			},
		},
		[8] = 
		{
			x = -6.62, y = 71.37, z = 97.27, Type = 6,
			Tid = 
			{
				[536] = 1,
			},
		},
		[12] = 
		{
			x = -1.18, y = 71.37, z = 95.63, Type = 6,
			Tid = 
			{
				[537] = 1,
			},
		},
		[13] = 
		{
			x = -0.06, y = 71.37, z = 90.13, Type = 6,
			Tid = 
			{
				[538] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo