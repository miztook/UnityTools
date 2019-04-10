local MapInfo = 
{
	MapType = 3,
	Remarks = "测试",
	TextDisplayName = "好望港",
	Length = 512,
	Width = 512,
	NavMeshName = "City01.navmesh",
	BackgroundMusic = "BGM_Maincastle_1/Maincastle_1/maincastle_1_zone_1",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/city01.png",
	AssetPath = "Assets/Outputs/Scenes/City01.prefab",
	Monster = 
	{
		[10120] = 
		{
			[1] = { x = 124.72, y = 18.98, z = 223.95, name = "疯狂的鬼魂", level = 14, SortID = 1 },
		},
		[10191] = 
		{
			[1] = { x = 124.72, y = 18.98, z = 223.95, name = "游魂", level = 14, SortID = 1, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[213] = 
		{
			[1] = { x = 121.64, y = 18.98, z = 213.01, name = "宾客", SortID = 95 },
			[2] = { x = 62.08, y = 23.30, z = 168.69, name = "宾客", SortID = 126 },
		},
		[214] = 
		{
			[1] = { x = 118.57, y = 18.98, z = 214.15, name = "宾客", SortID = 96 },
		},
		[215] = 
		{
			[1] = { x = 123.46, y = 18.98, z = 207.81, name = "宾客", SortID = 97 },
			[2] = { x = 62.93, y = 23.30, z = 166.73, name = "宾客", SortID = 125 },
		},
		[15] = 
		{
			[1] = { x = 51.41, y = 18.52, z = 184.29, name = "塞勒斯", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "塞勒斯", SortID = 138, FunctionName = "声望" },
		},
		[16] = 
		{
			[1] = { x = 127.24, y = 18.98, z = 223.17, name = "女孩幽灵", SortID = 139 },
		},
		[233] = 
		{
			[1] = { x = 92.02, y = 21.41, z = 164.89, name = "女孩", SortID = 142 },
			[2] = { x = -5.37, y = 32.83, z = 120.43, name = "女孩", SortID = 143 },
		},
		[19] = 
		{
			[1] = { x = -28.50, y = 58.38, z = -36.24, name = "传送石", SortID = 160 },
			[2] = { x = -5.56, y = 179.30, z = -131.01, name = "传送石", SortID = 161 },
		},
		[731] = 
		{
			[1] = { x = 127.13, y = 18.98, z = 223.25, name = "迷茫的鬼魂", SortID = 62 },
		},
		[733] = 
		{
			[1] = { x = 132.94, y = 22.03, z = 109.00, name = "塔伦", SortID = 116 },
		},
	},
	Region = 
	{
		[1] = 
		{
			[1] = { x = -1.18, y = 28.71, z = 204.52, xA = 38.19, yA = 49.34, zA = -221.96, name = "传送至东部领地1", worldId = 120, PkMode = 1 },
			[2] = { x = -113.82, y = 29.13, z = 142.47, xA = -21.32, yA = 53.58, zA = -242.44, name = "传送至东部领地2", worldId = 120, PkMode = 1 },
			[4] = { x = 145.58, y = 19.09, z = 219.67, xA = 239.44, yA = 21.91, zA = -224.12, name = "", worldId = 120, PkMode = 1 },
			[87] = { x = -4.99, y = 179.30, z = -131.70, xA = -4.55, yA = 58.38, zA = -43.17, name = "顶端传送区域", worldId = 110, PkMode = 1 },
			[91] = { x = -28.68, y = 58.38, z = -36.51, xA = -5.80, yA = 179.30, zA = -138.31, name = "传送阵大堂", worldId = 110, PkMode = 1 },
		},
		[2] = 
		{
			[86] = { x = 118.73, y = 21.86, z = 89.05, name = "码头附近", worldId = 0, PkMode = 1 },
			[108] = { x = -109.81, y = 48.94, z = 44.56, name = "军事区", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[109] = { x = -78.81, y = 31.17, z = 131.60, name = "日暮大道", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[110] = { x = -34.01, y = 28.93, z = 188.25, name = "贫民区", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[111] = { x = -3.90, y = 28.93, z = 173.39, name = "日升大道", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[112] = { x = 118.41, y = 18.98, z = 210.10, name = "密特拉商会", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[113] = { x = 57.08, y = 23.37, z = 71.18, name = "港务区", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[114] = { x = 98.05, y = 21.90, z = 136.19, name = "码头区", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[115] = { x = -6.01, y = 32.83, z = 114.01, name = "神佑广场", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[116] = { x = -3.06, y = 48.66, z = 31.26, name = "沉思大道", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[117] = { x = -6.37, y = 58.38, z = -52.79, name = "贝里克神殿", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[118] = { x = -7.01, y = 185.32, z = -201.91, name = "天空圣殿", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[124] = { x = 22.82, y = 25.45, z = 159.87, name = "难民抢劫【任务】", worldId = 0, PkMode = 1 },
			[125] = { x = 60.56, y = 23.37, z = 56.09, name = "鹰眼区域01", worldId = 0, PkMode = 1 },
			[126] = { x = -23.25, y = 29.33, z = 199.72, name = "鹰眼区域02", worldId = 0, PkMode = 1 },
			[127] = { x = 12.07, y = 191.18, z = -221.77, name = "鹰眼区域03", worldId = 0, PkMode = 1 },
			[128] = { x = 92.67, y = 20.10, z = 110.07, name = "鹰眼区域04", worldId = 0, PkMode = 1 },
			[129] = { x = 91.38, y = 19.82, z = 216.36, name = "鹰眼区域05", worldId = 0, PkMode = 1 },
			[186] = { x = 126.02, y = 18.98, z = 225.60, name = "鹰眼区域06", worldId = 0, PkMode = 1 },
			[195] = { x = -3.56, y = 48.66, z = 21.73, name = "鹰眼任务区域", worldId = 0, PkMode = 1 },
			[255] = { x = -4.20, y = 54.85, z = 85.30, name = "鹰眼万物志05", worldId = 0, PkMode = 0 },
			[268] = { x = 130.77, y = 21.84, z = 94.95, name = "抵达区域", worldId = 0, PkMode = 0 },
			[336] = { x = -16.60, y = 45.12, z = 146.22, name = "暴动相位区域", worldId = 0, PkMode = 0 },
			[337] = { x = 126.99, y = 18.98, z = 217.57, name = "迷茫的灵魂相位", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[345] = 
		{
			[1] = { x = -4.74, y = 54.85, z = 84.90 },
		},
		[441] = 
		{
			[1] = { x = 126.57, y = 18.98, z = 224.04 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = 124.72, y = 18.98, z = 223.95, Type = 1,
			Tid = 
			{
				[10120] = 1,
				[10191] = 3,
			},
		},
		[95] = 
		{
			x = 121.64, y = 18.98, z = 213.01, Type = 2,
			Tid = 
			{
				[213] = 1,
			},
		},
		[96] = 
		{
			x = 118.57, y = 18.98, z = 214.15, Type = 2,
			Tid = 
			{
				[214] = 1,
			},
		},
		[97] = 
		{
			x = 123.46, y = 18.98, z = 207.81, Type = 2,
			Tid = 
			{
				[215] = 1,
			},
		},
		[125] = 
		{
			x = 62.93, y = 23.30, z = 166.73, Type = 2,
			Tid = 
			{
				[215] = 1,
			},
		},
		[126] = 
		{
			x = 62.08, y = 23.30, z = 168.69, Type = 2,
			Tid = 
			{
				[213] = 1,
			},
		},
		[138] = 
		{
			x = 51.41, y = 18.52, z = 184.29, Type = 2,
			Tid = 
			{
				[15] = 1,
			},
		},
		[139] = 
		{
			x = 127.24, y = 18.98, z = 223.17, Type = 2,
			Tid = 
			{
				[16] = 1,
			},
		},
		[142] = 
		{
			x = 92.02, y = 21.41, z = 164.89, Type = 2,
			Tid = 
			{
				[233] = 1,
			},
		},
		[143] = 
		{
			x = -5.37, y = 32.83, z = 120.43, Type = 2,
			Tid = 
			{
				[233] = 1,
			},
		},
		[160] = 
		{
			x = -28.50, y = 58.38, z = -36.24, Type = 2,
			Tid = 
			{
				[19] = 1,
			},
		},
		[161] = 
		{
			x = -5.56, y = 179.30, z = -131.01, Type = 2,
			Tid = 
			{
				[19] = 1,
			},
		},
		[62] = 
		{
			x = 127.13, y = 18.98, z = 223.25, Type = 2,
			Tid = 
			{
				[731] = 1,
			},
		},
		[116] = 
		{
			x = 132.94, y = 22.03, z = 109.00, Type = 2,
			Tid = 
			{
				[733] = 1,
			},
		},
		[106] = 
		{
			x = 9.19, y = 29.33, z = -156.23, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[107] = 
		{
			x = -115.20, y = 25.66, z = -119.11, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[114] = 
		{
			x = -4.74, y = 54.85, z = 84.90, Type = 6,
			Tid = 
			{
				[345] = 1,
			},
		},
		[113] = 
		{
			x = 126.57, y = 18.98, z = 224.04, Type = 6,
			Tid = 
			{
				[441] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -2.98, posy = 28.67, posz = 182.82, rotx = 0.00, roty = 170.64, rotz = 0.00 },
		[2] = { posx = -89.17, posy = 31.06, posz = 142.08, rotx = 0.00, roty = 91.05, rotz = 0.00 },
		[3] = { posx = 141.91, posy = 19.02, posz = 218.47, rotx = 0.00, roty = 223.41, rotz = 0.00 },
		[5] = { posx = 119.66, posy = 21.41, posz = 180.92, rotx = 0.00, roty = 323.41, rotz = 0.00 },
		[6] = { posx = -4.55, posy = 58.38, posz = -43.17, rotx = 0.00, roty = 345.32, rotz = 0.00 },
		[7] = { posx = -5.80, posy = 179.30, posz = -138.31, rotx = 0.00, roty = 151.86, rotz = 0.00 },
		[8] = { posx = -5.14, posy = 48.66, posz = 45.51, rotx = 0.00, roty = 156.87, rotz = 0.00 },
		[9] = { posx = -5.38, posy = 185.32, posz = -191.79, rotx = 0.00, roty = 169.89, rotz = 0.00 },
		[10] = { posx = -71.82, posy = 30.68, posz = 177.99, rotx = 0.00, roty = 135.00, rotz = 0.00 },
		[11] = { posx = -2.84, posy = 32.84, posz = 114.64, rotx = 0.00, roty = 169.58, rotz = 0.00 },
		[12] = { posx = 54.05, posy = 18.52, posz = 185.34, rotx = 0.00, roty = 270.00, rotz = 0.00 },
	},

}
return MapInfo