local MapInfo = 
{
	MapType = 3,
	Remarks = "大地图1",
	TextDisplayName = "동부 가드",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	PKMode= 1,
	Monster = 
	{
		[10117] = 
		{
			[1] = { x = 82.33, y = 63.38, z = 154.58, name = "육지 거북이", level = 8, SortID = 391 },
		},
		[10118] = 
		{
			[1] = { x = 69.43, y = 48.33, z = -51.49, name = "강도", level = 12, SortID = 394 },
		},
		[10119] = 
		{
			[1] = { x = 65.78, y = 49.19, z = -47.13, name = "강도 두목", level = 10, SortID = 395 },
		},
		[10122] = 
		{
			[1] = { x = 60.00, y = 51.82, z = -90.00, name = "사절단", level = 15, SortID = 396 },
		},
		[10121] = 
		{
			[1] = { x = 186.60, y = 36.41, z = -29.30, name = "노예상", level = 12, SortID = 1 },
		},
	},
	Npc = 
	{
		[727] = 
		{
			[1] = { x = 117.58, y = 67.02, z = 150.44, name = "모니카", SortID = 388 },
		},
		[729] = 
		{
			[1] = { x = 112.29, y = 67.08, z = 154.91, name = "휴먼 고아", SortID = 389 },
		},
		[728] = 
		{
			[1] = { x = 120.74, y = 66.71, z = 149.38, name = "셀러스", SortID = 390 },
		},
	},
	Region = 
	{
		[1] = 
		{
			[63] = { x = 39.14, y = 49.57, z = -229.65, xA = -2.98, yA = 28.67, zA = 182.82, name = "传送区域-好望港A", worldId = 110, IsCanFind = 1, Describe = "희망항 - 정문", PkMode = 1 },
			[64] = { x = -12.22, y = 53.77, z = -249.65, xA = -89.17, yA = 31.06, zA = 142.08, name = "传送区域-好望港B", worldId = 110, PkMode = 1 },
			[65] = { x = -248.91, y = 43.14, z = -173.63, xA = 206.82, yA = 48.87, zA = -229.57, name = "传送区域-阿卡尼亚", worldId = 130, PkMode = 1 },
			[68] = { x = 239.83, y = 21.64, z = -238.40, xA = 141.91, yA = 19.02, zA = 218.47, name = "", worldId = 110, PkMode = 1 },
		},
		[2] = 
		{
			[59] = { x = 185.93, y = 91.20, z = 95.01, name = "初始相位", worldId = 0, PkMode = 1 },
			[61] = { x = 111.18, y = 101.57, z = 191.07, name = "그린 마을 서문", worldId = 0, PkMode = 1 },
			[62] = { x = -222.68, y = 42.90, z = -170.96, name = "숲속 주둔지", worldId = 0, PkMode = 1 },
			[67] = { x = 24.14, y = 62.35, z = 200.33, name = "抵达区域-迪波", worldId = 0, PkMode = 1 },
			[69] = { x = 222.45, y = 76.10, z = 219.99, name = "新兵训练", worldId = 0, PkMode = 1 },
			[70] = { x = 212.65, y = 76.11, z = 231.80, name = "难民区【任务】", worldId = 0, PkMode = 1 },
			[71] = { x = 126.49, y = 79.84, z = 58.06, name = "난민 대피소", worldId = 0, PkMode = 1 },
			[72] = { x = 7.77, y = 50.53, z = 64.87, name = "农场", worldId = 0, PkMode = 1 },
			[73] = { x = 145.40, y = 39.42, z = -39.67, name = "海盗营地外", worldId = 0, PkMode = 1 },
			[74] = { x = -111.55, y = 62.28, z = 191.93, name = "로카 벌목장", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[77] = { x = -150.77, y = 75.86, z = 122.83, name = "레인저 캠프", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[78] = { x = 173.66, y = 27.64, z = -173.21, name = "살무사 아레나", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[79] = { x = -227.22, y = 84.29, z = 72.01, name = "巴哈勒祭坛前", worldId = 0, PkMode = 1 },
			[87] = { x = -85.79, y = 48.06, z = -141.68, name = "탐욕의 골짜기", worldId = 0, PkMode = 1 },
			[88] = { x = 41.29, y = 50.50, z = -130.17, name = "好望港外【任务\公共】", worldId = 0, PkMode = 1 },
			[89] = { x = -234.49, y = 87.86, z = 81.99, name = "바하르 제단", worldId = 0, PkMode = 1 },
			[92] = { x = 124.47, y = 66.38, z = 194.48, name = "西门区域", worldId = 0, PkMode = 1 },
			[93] = { x = 160.14, y = 72.15, z = 232.64, name = "商业街附近", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[94] = { x = 178.01, y = 81.40, z = 180.85, name = "그린 마을", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[95] = { x = 147.48, y = 69.89, z = 247.36, name = "상인 연합 지부", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[96] = { x = 212.81, y = 76.04, z = 227.93, name = "教堂广场", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[97] = { x = 155.59, y = 102.64, z = 152.26, name = "연합의 광장", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[98] = { x = 217.58, y = 59.72, z = 110.11, name = "그린 마을 남문", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[99] = { x = 23.62, y = 62.41, z = 227.20, name = "낭떠러지", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[100] = { x = -13.58, y = 54.24, z = 17.64, name = "캠벨 농장", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[101] = { x = -152.65, y = 177.43, z = 157.23, name = "로카 숲", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[102] = { x = -141.34, y = 200.98, z = 110.52, name = "레인저 캠프", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[103] = { x = -137.74, y = 44.26, z = -176.92, name = "탐욕의 골짜기", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[104] = { x = 186.19, y = 36.00, z = -30.30, name = "해적 소굴", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[105] = { x = -211.75, y = 50.56, z = -201.41, name = "숲속 주둔지", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[106] = { x = 36.82, y = 49.63, z = -177.84, name = "희망항 정문", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[107] = { x = 260.85, y = 76.06, z = 232.32, name = "窃听镇长", worldId = 0, PkMode = 1 },
			[108] = { x = -148.91, y = 42.03, z = -160.69, name = "窟拉逃离区", worldId = 0, IsCanFind = 1, PkMode = 1 },
			[121] = { x = 98.81, y = 67.17, z = 183.98, name = "西门陷阱【任务】", worldId = 0, PkMode = 1 },
			[123] = { x = -177.71, y = 79.07, z = 39.06, name = "祭坛山道【任务】", worldId = 0, PkMode = 1 },
			[125] = { x = -91.61, y = 61.88, z = 161.70, name = "伐木场附近【任务】", worldId = 0, PkMode = 1 },
			[127] = { x = 242.57, y = 76.04, z = 214.93, name = "喝粥区域【任务】", worldId = 0, PkMode = 1 },
			[129] = { x = -81.90, y = 59.43, z = 25.42, name = "农场BOSS刷新", worldId = 0, PkMode = 1 },
			[137] = { x = -18.00, y = 171.34, z = 144.27, name = "世界boss测试区域", worldId = 0, PkMode = 1 },
			[139] = { x = -42.05, y = 58.36, z = 1.91, name = "鹰眼区域01", worldId = 0, PkMode = 1 },
			[140] = { x = 181.71, y = 42.67, z = 22.43, name = "鹰眼区域02", worldId = 0, PkMode = 1 },
			[141] = { x = 162.01, y = 68.50, z = 115.94, name = "鹰眼区域03", worldId = 0, PkMode = 1 },
			[142] = { x = 255.23, y = 65.73, z = 139.29, name = "鹰眼区域04", worldId = 0, PkMode = 1 },
			[143] = { x = 119.61, y = 67.12, z = 166.10, name = "鹰眼区域05", worldId = 0, PkMode = 1 },
			[144] = { x = -134.59, y = 64.57, z = 195.25, name = "鹰眼区域06", worldId = 0, PkMode = 1 },
			[145] = { x = -118.79, y = 75.33, z = 87.70, name = "鹰眼区域07", worldId = 0, PkMode = 1 },
			[146] = { x = -232.87, y = 42.17, z = -147.50, name = "鹰眼区域08", worldId = 0, PkMode = 1 },
			[181] = { x = 173.66, y = 27.64, z = -173.21, name = "살무사 아레나", worldId = 0, PkMode = 1 },
			[182] = { x = 143.45, y = 64.89, z = 146.57, name = "埋葬布莱恩", worldId = 0, PkMode = 1 },
			[183] = { x = -159.13, y = 75.83, z = 112.04, name = "治疗迪波", worldId = 0, PkMode = 1 },
			[184] = { x = 264.08, y = 76.06, z = 234.75, name = "间谍刷怪【任务】", worldId = 0, PkMode = 1 },
			[255] = { x = 178.70, y = 73.06, z = 208.29, name = "难民乞讨1", worldId = 0, PkMode = 1 },
			[256] = { x = 178.14, y = 72.44, z = 222.43, name = "难民乞讨2", worldId = 0, PkMode = 1 },
			[266] = { x = -34.75, y = 54.85, z = 11.58, name = "拷问", worldId = 0, PkMode = 1 },
			[267] = { x = -170.26, y = 42.62, z = -137.63, name = "万物志鹰眼0-霜峰卢肯日记02", worldId = 0, PkMode = 1 },
			[268] = { x = -95.26, y = 59.46, z = 37.46, name = "万物志鹰眼01-迪波日记01", worldId = 0, PkMode = 1 },
			[269] = { x = -191.94, y = 57.36, z = -238.07, name = "万物志鹰眼03-霜峰卢肯日记05", worldId = 0, PkMode = 1 },
			[270] = { x = -107.97, y = 57.64, z = -91.61, name = "万物志鹰眼04-霜峰卢肯日记06", worldId = 0, PkMode = 1 },
			[282] = { x = 38.81, y = 46.72, z = -169.36, name = "测试护送到达", worldId = 0, PkMode = 1 },
			[332] = { x = 115.53, y = 67.04, z = 183.06, name = "그린 마을 서문", worldId = 0, PkMode = 1 },
			[333] = { x = 107.92, y = 60.88, z = 88.35, name = "测试公会护送02到达", worldId = 0, PkMode = 1 },
			[334] = { x = 184.74, y = 39.90, z = -22.97, name = "支线任务审判", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[443] = 
		{
			[1] = { x = 203.13, y = 37.35, z = -30.90 },
		},
	},
	Entity = 
	{
		[391] = 
		{
			x = 82.33, y = 63.38, z = 154.58, Type = 1,
			Tid = 
			{
				[10117] = 5,
			},
		},
		[394] = 
		{
			x = 69.43, y = 48.33, z = -51.49, Type = 1,
			Tid = 
			{
				[10118] = 5,
			},
		},
		[395] = 
		{
			x = 65.78, y = 49.19, z = -47.13, Type = 1,
			Tid = 
			{
				[10119] = 1,
			},
		},
		[396] = 
		{
			x = 60.00, y = 51.82, z = -90.00, Type = 1,
			Tid = 
			{
				[10122] = 1,
			},
		},
		[1] = 
		{
			x = 186.60, y = 36.41, z = -29.30, Type = 1,
			Tid = 
			{
				[10121] = 10,
			},
		},
		[388] = 
		{
			x = 117.58, y = 67.02, z = 150.44, Type = 2,
			Tid = 
			{
				[727] = 1,
			},
		},
		[389] = 
		{
			x = 112.29, y = 67.08, z = 154.91, Type = 2,
			Tid = 
			{
				[729] = 1,
			},
		},
		[390] = 
		{
			x = 120.74, y = 66.71, z = 149.38, Type = 2,
			Tid = 
			{
				[728] = 1,
			},
		},
		[3] = 
		{
			x = 38.03, y = 49.34, z = -230.24, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[30] = 
		{
			x = -9.87, y = 53.20, z = -249.30, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[331] = 
		{
			x = -174.55, y = 59.00, z = -233.62, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[2] = 
		{
			x = 203.13, y = 37.35, z = -30.90, Type = 6,
			Tid = 
			{
				[443] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[2] = { posx = 38.19, posy = 49.34, posz = -221.96, rotx = 0.00, roty = 346.50, rotz = 0.00 },
		[3] = { posx = -21.32, posy = 53.58, posz = -242.44, rotx = 0.00, roty = 301.61, rotz = 0.00 },
		[4] = { posx = -243.45, posy = 42.75, posz = -174.06, rotx = 0.00, roty = 79.69, rotz = 0.00 },
		[5] = { posx = 239.44, posy = 21.91, posz = -224.12, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = 167.44, posy = 27.63, posz = -197.53, rotx = 0.00, roty = 203.08, rotz = 0.00 },
		[7] = { posx = 138.09, posy = 64.85, posz = 146.72, rotx = 0.00, roty = 81.21, rotz = 0.00 },
		[8] = { posx = 245.95, posy = 76.04, posz = 215.60, rotx = 0.00, roty = 205.61, rotz = 0.00 },
		[9] = { posx = -183.89, posy = 57.05, posz = -233.24, rotx = 0.00, roty = 301.93, rotz = 0.00 },
		[10] = { posx = -181.72, posy = 57.38, posz = -232.94, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[11] = { posx = 181.00, posy = 20.85, posz = -181.00, rotx = 0.00, roty = 36.29, rotz = 0.00 },
		[12] = { posx = 29.73, posy = 61.06, posz = 175.90, rotx = 0.00, roty = 103.47, rotz = 0.00 },
	},

}
return MapInfo
