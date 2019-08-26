local MapInfo = 
{
	MapType = 1,
	Remarks = "호가스 남부",
	TextDisplayName = "호가스 남부",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Day_and_Night",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	PKMode= 1,
	Monster = 
	{
		[12000] = 
		{
			[1] = { x = -233.84, y = -17.66, z = -163.06, name = "사냥개 그림자", level = 30, SortID = 20 },
		},
		[12001] = 
		{
			[1] = { x = -233.84, y = -17.66, z = -163.06, name = "검투사의 그림자", level = 30, SortID = 20 },
			[2] = { x = -228.81, y = -17.76, z = -166.45, name = "검투사의 그림자", level = 30, SortID = 21 },
			[3] = { x = -231.93, y = -17.76, z = -156.95, name = "검투사의 그림자", level = 30, DropItemIds = " " },
		},
		[12216] = 
		{
			[1] = { x = -228.81, y = -17.76, z = -166.45, name = "레인저의 그림자", level = 30, DropItemIds = " " },
			[2] = { x = -231.93, y = -17.76, z = -156.95, name = "레인저의 그림자", level = 30, DropItemIds = " " },
		},
		[12002] = 
		{
			[1] = { x = -218.10, y = 1.20, z = -78.00, name = "데바 그림자", level = 30, IsCanFind = 1, Describe = "Lv.30,데바 그림자", SortID = 22, DropItemIds = "1001*1139*10009*20100*1138*10008*52*27010*24000*1137*10007*24001*20300*3000*8110101*24002*21101" },
		},
		[12003] = 
		{
			[1] = { x = -225.63, y = -4.83, z = -56.71, name = "검투사의 그림자", level = 30, SortID = 25 },
			[2] = { x = -214.15, y = -6.64, z = -85.02, name = "검투사의 그림자", level = 30, SortID = 27 },
			[3] = { x = -196.61, y = 0.43, z = -74.65, name = "검투사의 그림자", level = 30, SortID = 28 },
			[4] = { x = -217.72, y = -6.74, z = -68.81, name = "검투사의 그림자", level = 30, SortID = 23 },
		},
		[12011] = 
		{
			[1] = { x = 52.00, y = 10.30, z = -73.60, name = "검은 날개 약탈자", level = 34, IsCanFind = 1, Describe = "Lv.34,검은 날개 약탈자", SortID = 33, DropItemIds = "1001*1139*10009*20100*1138*10008*51*20010*27010*24000*1137*10007*27011*24001*20300*3000*8010201*24002*21201" },
		},
		[12258] = 
		{
			[1] = { x = 29.00, y = 12.29, z = -127.70, name = "뿔 육지거북", level = 32, DropItemIds = " " },
			[2] = { x = 51.29, y = 13.91, z = -116.60, name = "뿔 육지거북", level = 32, DropItemIds = " " },
		},
		[12010] = 
		{
			[1] = { x = -46.18, y = 7.38, z = -40.52, name = "검은 날개 약탈자", level = 30, SortID = 36 },
			[2] = { x = -55.74, y = 7.14, z = -33.39, name = "검은 날개 약탈자", level = 30, SortID = 37 },
		},
		[12012] = 
		{
			[1] = { x = -30.89, y = 2.18, z = -119.86, name = "검은 날개 탈옥범", level = 33, SortID = 42 },
			[2] = { x = -22.32, y = 1.82, z = -104.07, name = "검은 날개 탈옥범", level = 33, SortID = 43 },
			[3] = { x = -36.77, y = 3.30, z = -104.54, name = "검은 날개 탈옥범", level = 33, SortID = 44 },
			[4] = { x = -46.61, y = 3.30, z = -115.24, name = "검은 날개 탈옥범", level = 33, SortID = 46 },
		},
		[12013] = 
		{
			[1] = { x = -46.61, y = 3.30, z = -115.24, name = "검은 날개 탈옥범 두목", level = 33, SortID = 46 },
		},
		[12015] = 
		{
			[1] = { x = 212.01, y = 34.35, z = -123.17, name = "검은 날개 사제", level = 33, SortID = 48 },
			[2] = { x = 203.17, y = 34.35, z = -120.06, name = "검은 날개 사제", level = 33, SortID = 49 },
		},
		[12016] = 
		{
			[1] = { x = 332.28, y = 31.20, z = 58.46, name = "검은 날개 병사", level = 33, SortID = 57 },
		},
		[12017] = 
		{
			[1] = { x = 332.28, y = 31.20, z = 58.46, name = "검은 날개 사제", level = 33, SortID = 57 },
		},
		[12018] = 
		{
			[1] = { x = 334.24, y = 30.23, z = 75.13, name = "검은 날개 대주교", level = 33, SortID = 59 },
		},
		[34002] = 
		{
			[1] = { x = 252.60, y = -9.78, z = 54.40, name = "육지의 파괴자", level = 32, SortID = 58,BossIconPath = "CBT_Map_Tag_018.png",IsBoss = true },
		},
		[12019] = 
		{
			[1] = { x = 15.33, y = 6.12, z = -100.19, name = "제3군단 검사", level = 33, SortID = 119 },
		},
		[12020] = 
		{
			[1] = { x = 15.33, y = 6.12, z = -100.19, name = "제3군단 흑마법사", level = 33, SortID = 119 },
		},
		[12014] = 
		{
			[1] = { x = 138.36, y = 11.29, z = -84.52, name = "검은 날개 병사", level = 33, SortID = 120 },
		},
		[12023] = 
		{
			[1] = { x = -70.32, y = 40.39, z = 67.22, name = "혈마법사", level = 34, SortID = 126 },
		},
		[12021] = 
		{
			[1] = { x = -70.32, y = 40.39, z = 67.22, name = "혈전사", level = 34, SortID = 126 },
		},
		[35230] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "사막 행인 용사", level = 30, SortID = 145 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "사막 행인 용사", level = 30, SortID = 146 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "사막 행인 용사", level = 30, SortID = 147 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "사막 행인 용사", level = 30, SortID = 148 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "사막 행인 용사", level = 30, SortID = 149 },
		},
		[35231] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "혈마법사", level = 30, SortID = 145 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "혈마법사", level = 30, SortID = 146 },
			[3] = { x = -188.50, y = 0.17, z = 16.98, name = "혈마법사", level = 30, SortID = 146 },
			[4] = { x = -230.00, y = -1.28, z = 147.00, name = "혈마법사", level = 30, SortID = 147 },
			[5] = { x = 92.14, y = 10.04, z = -99.18, name = "혈마법사", level = 30, SortID = 148 },
			[6] = { x = 141.53, y = 12.55, z = -69.51, name = "혈마법사", level = 30, SortID = 149 },
		},
		[35232] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "언데드 남작", level = 30, SortID = 145 },
			[2] = { x = -230.00, y = -1.28, z = 147.00, name = "언데드 남작", level = 30, SortID = 147 },
			[3] = { x = 92.14, y = 10.04, z = -99.18, name = "언데드 남작", level = 30, SortID = 148 },
			[4] = { x = 141.53, y = 12.55, z = -69.51, name = "언데드 남작", level = 30, SortID = 149 },
		},
		[12080] = 
		{
			[1] = { x = -275.80, y = -3.45, z = -42.43, name = "매머드", level = 31, SortID = 185 },
		},
		[12081] = 
		{
			[1] = { x = -272.34, y = -3.45, z = -32.92, name = "불사의 장교 그림자", level = 32, SortID = 186 },
		},
		[12082] = 
		{
			[1] = { x = -272.34, y = -3.45, z = -32.92, name = "불사의 병사 그림자", level = 31, SortID = 186 },
		},
		[12079] = 
		{
			[1] = { x = 333.19, y = 30.31, z = 11.90, name = "시칸 강도", level = 33, SortID = 187 },
		},
		[12076] = 
		{
			[1] = { x = 196.04, y = 34.83, z = -143.09, name = "데바 추격자", level = 33, Describe = "데바 추격자", SortID = 188 },
		},
		[12072] = 
		{
			[1] = { x = -362.50, y = -5.33, z = -85.10, name = "숲 매머드", level = 32, IsCanFind = 1, Describe = "Lv.32,숲 매머드", SortID = 189, DropItemIds = "1001*1139*10009*20100*1138*10008*52*27010*24000*1137*10007*24001*20300*3000*8110101*24002*21101" },
			[2] = { x = -364.75, y = -5.31, z = -112.99, name = "숲 매머드", level = 32, SortID = 223 },
		},
		[12073] = 
		{
			[1] = { x = -197.52, y = 0.26, z = -11.20, name = "검붉은 타조", level = 32, SortID = 190 },
			[2] = { x = -205.40, y = 0.20, z = 18.05, name = "검붉은 타조", level = 32, SortID = 191 },
			[3] = { x = -357.60, y = -5.31, z = -118.20, name = "검붉은 타조", level = 32, SortID = 227 },
			[4] = { x = -345.10, y = -5.31, z = -122.50, name = "검붉은 타조", level = 32, SortID = 228 },
		},
		[12074] = 
		{
			[1] = { x = 191.60, y = 34.34, z = -117.00, name = "사막 시조새", level = 33, SortID = 192 },
			[2] = { x = 209.28, y = 30.65, z = -76.72, name = "사막 시조새", level = 33, SortID = 193 },
			[3] = { x = 298.63, y = 45.82, z = -131.24, name = "사막 시조새", level = 33, SortID = 194 },
			[4] = { x = 359.93, y = 30.31, z = 8.71, name = "사막 시조새", level = 33, SortID = 198 },
			[5] = { x = 217.81, y = 34.35, z = -122.23, name = "사막 시조새", level = 33, SortID = 226 },
		},
		[12075] = 
		{
			[1] = { x = -206.32, y = -1.28, z = 147.35, name = "검은 날개 약탈자", level = 33, SortID = 195 },
		},
		[12078] = 
		{
			[1] = { x = 32.66, y = 12.69, z = -37.26, name = "제3군단 감독관", level = 33, SortID = 196 },
		},
		[12077] = 
		{
			[1] = { x = 32.66, y = 12.69, z = -37.26, name = "제3군단 검사", level = 33, SortID = 196 },
		},
		[39003] = 
		{
			[1] = { x = -349.46, y = -0.02, z = 19.63, name = "타락한 영혼", level = 10, DropItemIds = " " },
			[2] = { x = -213.72, y = -1.28, z = 131.65, name = "타락한 영혼", level = 10, DropItemIds = " " },
			[3] = { x = -45.30, y = 3.30, z = -115.81, name = "타락한 영혼", level = 10, DropItemIds = " " },
			[4] = { x = -71.66, y = 40.54, z = 67.33, name = "타락한 영혼", level = 10, DropItemIds = " " },
			[5] = { x = 92.99, y = 21.75, z = -15.51, name = "타락한 영혼", level = 10, DropItemIds = " " },
			[6] = { x = 337.13, y = 30.31, z = 19.20, name = "타락한 영혼", level = 10, DropItemIds = " " },
		},
		[39005] = 
		{
			[1] = { x = -349.46, y = -0.02, z = 19.63, name = "아르곤 선봉", level = 10, DropItemIds = " " },
			[2] = { x = -213.72, y = -1.28, z = 131.65, name = "아르곤 선봉", level = 10, DropItemIds = " " },
			[3] = { x = -45.30, y = 3.30, z = -115.81, name = "아르곤 선봉", level = 10, DropItemIds = " " },
			[4] = { x = -71.66, y = 40.54, z = 67.33, name = "아르곤 선봉", level = 10, DropItemIds = " " },
			[5] = { x = 92.99, y = 21.75, z = -15.51, name = "아르곤 선봉", level = 10, DropItemIds = " " },
			[6] = { x = 337.13, y = 30.31, z = 19.20, name = "아르곤 선봉", level = 10, DropItemIds = " " },
		},
		[39006] = 
		{
			[1] = { x = -349.46, y = -0.02, z = 19.63, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
			[2] = { x = -213.72, y = -1.28, z = 131.65, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
			[3] = { x = -45.30, y = 3.30, z = -115.81, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
			[4] = { x = -71.66, y = 40.54, z = 67.33, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
			[5] = { x = 92.99, y = 21.75, z = -15.51, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
			[6] = { x = 337.13, y = 30.31, z = 19.20, name = "아르곤 흑마법사", level = 10, DropItemIds = " " },
		},
		[39201] = 
		{
			[1] = { x = -224.78, y = 0.91, z = -1.49, name = "바포메트", level = 32, DropItemIds = " ",IsBoss = true },
			[2] = { x = -188.76, y = -4.18, z = -64.93, name = "바포메트", level = 32, DropItemIds = " ",IsBoss = true },
			[3] = { x = -207.12, y = -12.95, z = -139.54, name = "바포메트", level = 32, DropItemIds = " ",IsBoss = true },
			[4] = { x = -207.60, y = -1.28, z = 107.60, name = "바포메트", level = 32, DropItemIds = " ",IsBoss = true },
		},
		[39200] = 
		{
			[1] = { x = -59.60, y = 40.39, z = 66.00, name = "바포메트", level = 30, DropItemIds = " ",IsBoss = true },
			[2] = { x = 20.70, y = 21.04, z = 37.50, name = "바포메트", level = 30, DropItemIds = " ",IsBoss = true },
			[3] = { x = 56.64, y = 11.99, z = -103.59, name = "바포메트", level = 30, DropItemIds = " ",IsBoss = true },
			[4] = { x = -36.66, y = 2.99, z = -114.18, name = "바포메트", level = 30, DropItemIds = " ",IsBoss = true },
		},
		[35245] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "검은 날개 대주교", level = 35, SortID = 297 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "검은 날개 대주교", level = 35, SortID = 296 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "검은 날개 대주교", level = 35, SortID = 295 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "검은 날개 대주교", level = 35, SortID = 294 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "검은 날개 대주교", level = 35, SortID = 293 },
		},
		[35246] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "아라크네아", level = 35, SortID = 297 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "아라크네아", level = 35, SortID = 296 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "아라크네아", level = 35, SortID = 295 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "아라크네아", level = 35, SortID = 294 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "아라크네아", level = 35, SortID = 293 },
		},
		[35247] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "적금", level = 35, SortID = 297 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "적금", level = 35, SortID = 296 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "적금", level = 35, SortID = 295 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "적금", level = 35, SortID = 294 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "적금", level = 35, SortID = 293 },
		},
		[35257] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "쿠사", level = 40, SortID = 298 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "쿠사", level = 40, SortID = 299 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "쿠사", level = 40, SortID = 300 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "쿠사", level = 40, SortID = 301 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "쿠사", level = 40, SortID = 302 },
		},
		[35258] = 
		{
			[1] = { x = -236.25, y = -17.74, z = -160.36, name = "카모 만 칸디스", level = 40, SortID = 298 },
			[2] = { x = -188.50, y = 0.17, z = 16.98, name = "카모 만 칸디스", level = 40, SortID = 299 },
			[3] = { x = -230.00, y = -1.28, z = 147.00, name = "카모 만 칸디스", level = 40, SortID = 300 },
			[4] = { x = 92.14, y = 10.04, z = -99.18, name = "카모 만 칸디스", level = 40, SortID = 301 },
			[5] = { x = 141.53, y = 12.55, z = -69.51, name = "카모 만 칸디스", level = 40, SortID = 302 },
		},
		[34204] = 
		{
			[1] = { x = -365.64, y = 0.06, z = 13.82, name = "시크마투스", level = 30, SortID = 35, DropItemIds = " ",IsEliteBoss = true,BossIconPath = "CBT_Map_Tag_018_001" },
		},
		[34205] = 
		{
			[1] = { x = 164.12, y = 16.21, z = -106.45, name = "시칸 다크", level = 33, SortID = 69, DropItemIds = " ",IsEliteBoss = true,BossIconPath = "CBT_Map_Tag_018_001" },
		},
		[60046] = 
		{
			[1] = { x = -45.85, y = 9.42, z = -26.08, name = "검은 날개 약탈자", level = 33, SortID = 315, DropItemIds = " " },
		},
		[12237] = 
		{
			[1] = { x = 116.98, y = 10.06, z = -105.91, name = "방주 순찰병", level = 30, DropItemIds = " " },
		},
		[12236] = 
		{
			[1] = { x = 56.32, y = 21.04, z = -0.76, name = "데바 암살자", level = 30, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[2001] = 
		{
			[1] = { x = -225.77, y = -17.77, z = -159.47, name = "디포", SortID = 1 },
		},
		[2013] = 
		{
			[1] = { x = -276.82, y = -8.43, z = -95.22, name = "레인저", SortID = 4 },
			[2] = { x = -275.52, y = -8.43, z = -92.75, name = "레인저", SortID = 5 },
			[3] = { x = -278.15, y = -8.43, z = -93.24, name = "레인저", SortID = 6 },
			[4] = { x = -287.88, y = -3.53, z = -44.79, name = "레인저", SortID = 7 },
			[5] = { x = -285.25, y = -3.53, z = -44.30, name = "레인저", SortID = 8 },
			[6] = { x = -286.55, y = -3.53, z = -46.77, name = "레인저", SortID = 9 },
			[7] = { x = -265.09, y = -3.53, z = -42.66, name = "레인저", SortID = 10 },
			[8] = { x = -264.94, y = -3.53, z = -40.61, name = "레인저", SortID = 11 },
			[9] = { x = -270.56, y = -3.53, z = -63.53, name = "레인저", SortID = 12 },
			[10] = { x = -283.85, y = -3.53, z = -62.25, name = "레인저", SortID = 13 },
			[11] = { x = -283.73, y = -8.38, z = -91.89, name = "레인저", SortID = 14 },
			[12] = { x = -291.07, y = -8.38, z = -85.76, name = "레인저", SortID = 15 },
			[13] = { x = -271.88, y = -2.09, z = -22.89, name = "레인저", SortID = 16 },
			[14] = { x = -264.86, y = -1.72, z = -26.69, name = "레인저", SortID = 17 },
			[15] = { x = -271.91, y = -8.22, z = -80.57, name = "레인저", SortID = 18 },
			[16] = { x = -272.06, y = -8.22, z = -82.62, name = "레인저", SortID = 19 },
		},
		[2014] = 
		{
			[1] = { x = -381.32, y = -1.10, z = -29.42, name = "부상당한 병사", SortID = 29 },
		},
		[2010] = 
		{
			[1] = { x = -284.99, y = -3.45, z = -52.49, name = "엘리사 쿠벨", SortID = 30 },
		},
		[2094] = 
		{
			[1] = { x = -222.63, y = -17.77, z = -159.96, name = "케스타닉인", SortID = 31 },
		},
		[2020] = 
		{
			[1] = { x = -39.19, y = 9.33, z = -3.35, name = "케스타닉 상인", SortID = 39 },
		},
		[2019] = 
		{
			[1] = { x = -48.02, y = 9.23, z = -10.80, name = "케스타닉 호위병", SortID = 40 },
			[2] = { x = -46.39, y = 9.33, z = -3.93, name = "케스타닉 호위병", SortID = 41 },
			[3] = { x = -39.46, y = 9.44, z = -15.48, name = "케스타닉 호위병", SortID = 24 },
			[4] = { x = 76.40, y = 15.64, z = -41.20, name = "케스타닉 호위병", SortID = 67 },
			[5] = { x = -42.66, y = 7.21, z = -35.44, name = "케스타닉 호위병", SortID = 113 },
			[6] = { x = 47.05, y = 21.04, z = 20.93, name = "케스타닉 호위병", SortID = 122 },
			[7] = { x = 48.89, y = 21.04, z = 21.81, name = "케스타닉 호위병", SortID = 123 },
			[8] = { x = 58.65, y = 21.09, z = 17.14, name = "케스타닉 호위병", SortID = 124 },
			[9] = { x = 57.05, y = 21.07, z = 21.29, name = "케스타닉 호위병", SortID = 125 },
			[10] = { x = -51.33, y = 7.21, z = -29.18, name = "케스타닉 호위병", SortID = 224 },
			[11] = { x = 37.05, y = 10.41, z = -49.81, name = "케스타닉 호위병", SortID = 225 },
		},
		[2030] = 
		{
			[1] = { x = -60.60, y = 3.30, z = -116.01, name = "시칸레니", SortID = 45 },
		},
		[2032] = 
		{
			[1] = { x = 305.75, y = 51.98, z = -60.29, name = "시칸레니", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "시칸레니", SortID = 38, FunctionName = "명성" },
		},
		[2034] = 
		{
			[1] = { x = 280.79, y = 52.00, z = -65.77, name = "시칸롤", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "시칸롤", SortID = 50, FunctionName = "명성" },
		},
		[2035] = 
		{
			[1] = { x = 328.24, y = 48.80, z = -102.71, name = "시칸쿠어", SortID = 51 },
		},
		[2036] = 
		{
			[1] = { x = 346.92, y = 48.80, z = -91.15, name = "시칸타스", SortID = 52 },
		},
		[2033] = 
		{
			[1] = { x = 305.65, y = 48.09, z = -107.14, name = "시칸다리 병사", SortID = 53 },
			[2] = { x = 292.97, y = 48.32, z = -99.91, name = "시칸다리 병사", SortID = 54 },
			[3] = { x = 326.10, y = 48.80, z = -45.62, name = "시칸다리 병사", SortID = 55 },
			[4] = { x = 340.93, y = 48.32, z = -46.25, name = "시칸다리 병사", SortID = 56 },
			[5] = { x = 311.80, y = 30.31, z = 31.70, name = "시칸다리 병사", SortID = 117 },
			[6] = { x = 271.31, y = -9.90, z = 15.59, name = "시칸다리 병사", SortID = 118 },
			[7] = { x = 317.10, y = 30.16, z = 52.44, name = "시칸다리 병사", SortID = 129 },
		},
		[2021] = 
		{
			[1] = { x = -35.94, y = 9.33, z = -10.14, name = "데바 상인", SortID = 62 },
		},
		[2042] = 
		{
			[1] = { x = -32.83, y = 9.33, z = -6.06, name = "사마엘", SortID = 63 },
		},
		[2023] = 
		{
			[1] = { x = 12.84, y = 21.04, z = 30.08, name = "디포", SortID = 64 },
		},
		[2026] = 
		{
			[1] = { x = 10.95, y = 21.04, z = 24.98, name = "제3군단 병사", SortID = 65 },
			[2] = { x = 14.71, y = 21.04, z = 36.03, name = "제3군단 병사", SortID = 66 },
			[3] = { x = 61.09, y = 21.04, z = -5.67, name = "제3군단 병사", SortID = 74 },
			[4] = { x = 66.99, y = 21.02, z = -2.85, name = "제3군단 병사", SortID = 75 },
			[5] = { x = 56.28, y = 21.04, z = 38.41, name = "제3군단 병사", SortID = 88 },
			[6] = { x = -33.46, y = 9.33, z = -10.69, name = "제3군단 병사", SortID = 114 },
			[7] = { x = 29.05, y = 21.04, z = 43.60, name = "제3군단 병사", SortID = 121 },
		},
		[2022] = 
		{
			[1] = { x = 76.16, y = 17.40, z = -30.86, name = "디포", SortID = 68 },
		},
		[2029] = 
		{
			[1] = { x = 167.61, y = 39.73, z = 9.50, name = "나이팅게일", SortID = 71 },
		},
		[2028] = 
		{
			[1] = { x = 62.30, y = 25.49, z = 75.38, name = "칼리시안", SortID = 72 },
		},
		[2025] = 
		{
			[1] = { x = 27.33, y = 21.06, z = 51.24, name = "파비우스", SortID = 73 },
		},
		[2027] = 
		{
			[1] = { x = 159.97, y = 39.66, z = 8.81, name = "수상한 호가스인", SortID = 76 },
			[2] = { x = 157.89, y = 39.66, z = 7.35, name = "수상한 호가스인", SortID = 77 },
			[3] = { x = 157.84, y = 39.66, z = 10.28, name = "수상한 호가스인", SortID = 78 },
			[4] = { x = 147.02, y = 39.66, z = 12.74, name = "수상한 호가스인", SortID = 79 },
			[5] = { x = 151.80, y = 39.66, z = 18.17, name = "수상한 호가스인", SortID = 80 },
		},
		[2095] = 
		{
			[1] = { x = 32.29, y = 21.22, z = 11.48, name = "야루스", SortID = 81 },
		},
		[2097] = 
		{
			[1] = { x = 27.67, y = 21.23, z = 15.67, name = "스티르", SortID = 82 },
			[2] = { x = 287.48, y = 48.79, z = -86.96, name = "스티르", SortID = 85 },
		},
		[2098] = 
		{
			[1] = { x = 52.58, y = 21.04, z = 12.88, name = "스오치", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "스오치", SortID = 83, FunctionName = "명성" },
		},
		[2099] = 
		{
			[1] = { x = 296.17, y = 48.52, z = -85.18, name = "갈리아드", IsCanFind = 1, IconPath = "Map_Img_Shop", Describe = "잡화 상인", SortID = 84 },
		},
		[2101] = 
		{
			[1] = { x = -291.66, y = -8.38, z = -80.66, name = "아슐라", IsCanFind = 1, IconPath = "Map_Img_Shop", Describe = "잡화 상인", SortID = 86 },
		},
		[2024] = 
		{
			[1] = { x = 58.77, y = 21.04, z = 43.69, name = "그림자 거미", SortID = 87 },
		},
		[2043] = 
		{
			[1] = { x = 164.90, y = 39.73, z = 12.83, name = "사마엘", SortID = 90 },
		},
		[2044] = 
		{
			[1] = { x = 53.35, y = 21.04, z = 42.41, name = "루나 엘린", SortID = 91 },
		},
		[2105] = 
		{
			[1] = { x = -366.80, y = -5.31, z = -92.06, name = "부상당한 요정", SortID = 92 },
		},
		[2107] = 
		{
			[1] = { x = -341.56, y = -0.08, z = 25.73, name = "리스테라", SortID = 101 },
		},
		[2106] = 
		{
			[1] = { x = -340.70, y = -0.08, z = 30.80, name = "요정", SortID = 102 },
			[2] = { x = -337.66, y = -0.08, z = 27.84, name = "요정", SortID = 103 },
			[3] = { x = -357.54, y = -0.08, z = 43.04, name = "요정", SortID = 104 },
			[4] = { x = -356.41, y = -0.08, z = 36.10, name = "요정", SortID = 105 },
			[5] = { x = -354.81, y = -0.08, z = 39.59, name = "요정", SortID = 106 },
		},
		[2000] = 
		{
			[1] = { x = -250.80, y = -18.44, z = -177.59, name = "루나 엘린", SortID = 107 },
			[2] = { x = -223.78, y = 0.31, z = -18.22, name = "루나 엘린", SortID = 108 },
		},
		[2037] = 
		{
			[1] = { x = -206.12, y = -12.67, z = -112.76, name = "검은 옷을 입은 사람", SortID = 26 },
		},
		[2009] = 
		{
			[1] = { x = -267.07, y = -3.45, z = -53.28, name = "사마엘", SortID = 110 },
		},
		[2005] = 
		{
			[1] = { x = -284.87, y = -3.40, z = -55.15, name = "루나 엘린", SortID = 112 },
		},
		[2038] = 
		{
			[1] = { x = 292.32, y = 51.97, z = -72.96, name = "루나 엘린", SortID = 127 },
		},
		[2041] = 
		{
			[1] = { x = 48.69, y = 25.48, z = 89.09, name = "시칸레니", SortID = 130 },
		},
		[2040] = 
		{
			[1] = { x = 53.48, y = 25.48, z = 89.09, name = "나이팅게일", SortID = 131 },
		},
		[2006] = 
		{
			[1] = { x = -216.05, y = -1.28, z = 114.14, name = "루나 엘린", SortID = 132 },
		},
		[2143] = 
		{
			[1] = { x = -217.49, y = -13.22, z = -140.04, name = "리렘", SortID = 155 },
		},
		[2070] = 
		{
			[1] = { x = 12.73, y = 21.04, z = 11.56, name = "마리안느", SortID = 156 },
		},
		[2071] = 
		{
			[1] = { x = 6.03, y = 21.04, z = 34.38, name = "줄트", SortID = 157 },
		},
		[2072] = 
		{
			[1] = { x = 44.37, y = 21.04, z = 26.89, name = "샤일라", SortID = 158 },
		},
		[2075] = 
		{
			[1] = { x = 12.11, y = 21.07, z = 53.39, name = "오슬롯", SortID = 159 },
		},
		[2077] = 
		{
			[1] = { x = 12.01, y = 13.29, z = -33.50, name = "오슬롯", SortID = 160 },
		},
		[2078] = 
		{
			[1] = { x = 29.49, y = 21.22, z = 28.68, name = "케라", SortID = 161 },
		},
		[2079] = 
		{
			[1] = { x = 14.73, y = 21.04, z = 42.87, name = "데바 장교", SortID = 162 },
		},
		[2081] = 
		{
			[1] = { x = -272.56, y = -8.35, z = -76.59, name = "아이리스", SortID = 163 },
		},
		[2082] = 
		{
			[1] = { x = -270.99, y = -3.45, z = -40.97, name = "아이리스", SortID = 164 },
		},
		[2083] = 
		{
			[1] = { x = -273.87, y = -8.43, z = -87.03, name = "신병", SortID = 165 },
		},
		[2084] = 
		{
			[1] = { x = -285.21, y = -8.38, z = -79.67, name = "노병", SortID = 166 },
		},
		[2085] = 
		{
			[1] = { x = -289.15, y = -8.38, z = -84.01, name = "연합군 장교", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "연합군 장교", SortID = 167, FunctionName = "명성" },
		},
		[2088] = 
		{
			[1] = { x = -210.50, y = 0.19, z = 27.57, name = "화물 운송인", SortID = 168 },
		},
		[2074] = 
		{
			[1] = { x = -205.26, y = -1.28, z = 136.92, name = "브루토", SortID = 169 },
		},
		[2073] = 
		{
			[1] = { x = 182.51, y = 40.41, z = -144.18, name = "파이든", SortID = 170 },
		},
		[2096] = 
		{
			[1] = { x = 27.98, y = 21.23, z = 21.28, name = "라스칼", SortID = 199 },
		},
		[2178] = 
		{
			[1] = { x = 93.00, y = 10.06, z = -87.00, name = "시칸다리 신도", SortID = 230 },
		},
		[2176] = 
		{
			[1] = { x = 315.81, y = 48.70, z = -78.17, name = "시칸다리 신도", SortID = 231 },
		},
		[2177] = 
		{
			[1] = { x = 323.17, y = 48.70, z = -85.23, name = "시칸다리 신도", SortID = 232 },
		},
		[2179] = 
		{
			[1] = { x = 312.46, y = 48.72, z = -98.62, name = "시칸다리 신도", SortID = 233 },
		},
		[20] = 
		{
			[1] = { x = -331.65, y = -3.79, z = -146.18, name = "로렌스", SortID = 238 },
		},
		[21] = 
		{
			[1] = { x = 157.85, y = 39.73, z = 24.20, name = "로렌스", SortID = 239 },
			[2] = { x = 51.02, y = 26.65, z = 133.33, name = "로렌스", FunctionName = " " },
		},
		[22] = 
		{
			[1] = { x = -381.15, y = 0.02, z = 30.83, name = "로렌스", SortID = 240 },
		},
		[2185] = 
		{
			[1] = { x = 96.58, y = 10.06, z = -96.70, name = "시칸다리 신도", SortID = 257 },
		},
		[2212] = 
		{
			[1] = { x = -375.64, y = -1.68, z = -144.36, name = "갇힌 포로", SortID = 258 },
		},
		[2213] = 
		{
			[1] = { x = -373.34, y = -1.68, z = -147.93, name = "갇힌 여행객", SortID = 259 },
		},
		[2214] = 
		{
			[1] = { x = -344.61, y = -0.08, z = 36.90, name = "리렘", SortID = 260 },
		},
		[2217] = 
		{
			[1] = { x = -359.64, y = -0.02, z = 45.91, name = "수비 요정", SortID = 261 },
			[2] = { x = -361.96, y = -0.02, z = 41.87, name = "수비 요정", SortID = 262 },
			[3] = { x = -332.73, y = -0.02, z = 32.12, name = "수비 요정", SortID = 263 },
			[4] = { x = -330.93, y = -0.02, z = 29.19, name = "수비 요정", SortID = 264 },
		},
		[2216] = 
		{
			[1] = { x = -386.71, y = -0.01, z = 23.91, name = "순찰 요정", SortID = 265 },
			[2] = { x = -343.58, y = -0.02, z = 22.15, name = "순찰 요정", SortID = 266 },
			[3] = { x = -221.04, y = -1.28, z = 98.81, name = "순찰 요정", SortID = 272 },
			[4] = { x = -194.85, y = -1.28, z = 108.76, name = "순찰 요정", SortID = 273 },
		},
		[2210] = 
		{
			[1] = { x = -287.76, y = -8.41, z = -89.50, name = "순찰 궁수", SortID = 267 },
		},
		[2211] = 
		{
			[1] = { x = -287.76, y = -8.41, z = -89.50, name = "순찰 레인저", SortID = 267 },
		},
		[2206] = 
		{
			[1] = { x = -266.57, y = -3.45, z = -57.22, name = "카이아의 검", SortID = 268 },
			[2] = { x = -282.97, y = -3.45, z = -34.50, name = "카이아의 검", SortID = 270 },
		},
		[2207] = 
		{
			[1] = { x = -267.39, y = -3.45, z = -59.63, name = "검투사", SortID = 269 },
			[2] = { x = -281.78, y = -3.45, z = -31.65, name = "검투사", SortID = 271 },
		},
		[2219] = 
		{
			[1] = { x = -191.22, y = -1.28, z = 124.32, name = "프레드 쿠벨", SortID = 274 },
		},
		[2220] = 
		{
			[1] = { x = -192.48, y = -1.28, z = 131.59, name = "엘린 여행자", SortID = 275 },
		},
		[2221] = 
		{
			[1] = { x = 46.97, y = 26.73, z = 110.78, name = "바쁜 장인", SortID = 276 },
			[2] = { x = 54.91, y = 26.64, z = 137.46, name = "바쁜 장인", SortID = 277 },
			[3] = { x = 47.39, y = 26.81, z = 128.66, name = "바쁜 장인", SortID = 278 },
		},
		[2224] = 
		{
			[1] = { x = 336.13, y = 48.82, z = -93.03, name = "시칸족", SortID = 279 },
			[2] = { x = 333.88, y = 48.83, z = -95.67, name = "시칸족", SortID = 280 },
			[3] = { x = 350.07, y = 48.80, z = -71.10, name = "시칸족", SortID = 281 },
			[4] = { x = 351.23, y = 48.80, z = -79.92, name = "시칸족", SortID = 282 },
			[5] = { x = 345.16, y = 48.80, z = -54.86, name = "시칸족", SortID = 283 },
		},
		[2222] = 
		{
			[1] = { x = 302.33, y = 48.78, z = -81.89, name = "엘린 여행자", SortID = 284 },
		},
		[2223] = 
		{
			[1] = { x = 221.64, y = 34.46, z = -104.10, name = "시칸다리 보초병", SortID = 285 },
			[2] = { x = 162.76, y = 14.28, z = -85.17, name = "시칸다리 보초병", SortID = 286 },
			[3] = { x = 343.66, y = 30.16, z = 38.40, name = "시칸다리 보초병", SortID = 288 },
		},
		[2236] = 
		{
			[1] = { x = 160.50, y = 39.73, z = 14.70, name = "", SortID = 287 },
		},
		[2243] = 
		{
			[1] = { x = -359.64, y = -0.26, z = 34.60, name = "루나 엘린", SortID = 229 },
		},
		[2241] = 
		{
			[1] = { x = -349.43, y = 0.02, z = 30.73, name = "시칸레니", SortID = 291 },
		},
		[2240] = 
		{
			[1] = { x = -353.26, y = -0.16, z = 19.24, name = "시칸레니", SortID = 292 },
		},
		[2270] = 
		{
			[1] = { x = -347.06, y = -4.36, z = -125.72, name = "사냥꾼", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "사냥꾼", SortID = 70, FunctionName = "명성" },
		},
		[2275] = 
		{
			[1] = { x = 24.84, y = 21.04, z = 51.23, name = "호가스 사신", SortID = 216, FunctionName = " " },
		},
		[2314] = 
		{
			[1] = { x = -228.80, y = -17.77, z = -158.52, name = "레인저 병사", FunctionName = " " },
		},
		[2312] = 
		{
			[1] = { x = -231.45, y = -17.75, z = -156.57, name = "", FunctionName = " " },
		},
		[2286] = 
		{
			[1] = { x = -219.86, y = 0.31, z = -16.83, name = "리렘", FunctionName = " " },
		},
		[2287] = 
		{
			[1] = { x = -219.86, y = 0.29, z = -16.83, name = "리렘", FunctionName = " " },
		},
		[2288] = 
		{
			[1] = { x = -210.85, y = -1.28, z = 122.80, name = "리렘", FunctionName = " " },
		},
		[2290] = 
		{
			[1] = { x = -210.79, y = -1.28, z = 125.40, name = "요정", FunctionName = " " },
		},
		[2289] = 
		{
			[1] = { x = -285.15, y = -3.45, z = -58.22, name = "리렘", FunctionName = " " },
		},
		[2280] = 
		{
			[1] = { x = -237.23, y = -17.71, z = -160.46, name = "루나 엘린", FunctionName = " " },
		},
		[2323] = 
		{
			[1] = { x = 118.10, y = 10.11, z = -91.00, name = "이상한 기계", FunctionName = " " },
		},
		[2324] = 
		{
			[1] = { x = 117.73, y = 10.10, z = -93.28, name = "이상한 기계", FunctionName = " " },
		},
		[2325] = 
		{
			[1] = { x = 52.22, y = 21.07, z = 16.81, name = "바쁜 장인", FunctionName = " " },
		},
		[2273] = 
		{
			[1] = { x = 318.53, y = 48.81, z = -106.50, name = "시칸카모운", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "시칸카모운", FunctionName = "명성" },
		},
		[2362] = 
		{
			[1] = { x = 312.62, y = 48.76, z = -106.50, name = "시칸족 부상자", FunctionName = " " },
		},
		[2322] = 
		{
			[1] = { x = 55.50, y = 21.09, z = -0.97, name = "의심스러운 자", FunctionName = " " },
		},
	},
	Region = 
	{
		[1] = 
		{
			[54] = { x = -248.71, y = -6.81, z = -187.87, xA = -194.70, yA = 82.20, zA = 228.76, name = "霍加斯-阿卡尼亚", worldId = 130, IsCanFind = 1, Describe = "아르카니아 가드", PkMode = 0 },
			[56] = { x = 58.68, y = 26.04, z = 143.01, xA = 336.29, yA = 46.57, zA = -106.17, name = "霍加斯1-霍加斯2", worldId = 150, IsCanFind = 1, Describe = "호가스 북부", PkMode = 0 },
			[209] = { x = 312.54, y = 30.49, z = 29.54, xA = 256.18, yA = -9.91, zA = 26.48, name = "传送至谷底", worldId = 140, IsCanFind = 1, Describe = "황금 무덤", PkMode = 0 },
			[210] = { x = 270.34, y = -8.21, z = 16.14, xA = 328.91, yA = 30.16, zA = 22.86, name = "传送至谷上", worldId = 140, PkMode = 0 },
			[220] = { x = 1.00, y = 22.29, z = 31.25, xA = -34.76, yA = 38.34, zA = 52.51, name = "通往镇长官邸", worldId = 140, IsCanFind = 1, Describe = "산꼭대기의 폐허", PkMode = 0 },
			[221] = { x = -33.10, y = 41.13, z = 51.67, xA = 3.71, yA = 21.04, zA = 30.09, name = "回到罗琳镇广场", worldId = 140, PkMode = 0 },
			[240] = { x = 316.13, y = 31.41, z = 53.01, xA = 176.50, yA = 39.78, zA = 2.81, name = "传送至罗琳镇", worldId = 140, IsCanFind = 1, Describe = "루린 마을", PkMode = 0 },
		},
		[2] = 
		{
			[192] = { x = -229.11, y = -17.62, z = -158.52, name = "폐가", isShowName = true, worldId = 0, PkMode = 0 },
			[193] = { x = -198.14, y = 2.54, z = -65.22, name = "버려진 데바 주둔지", isShowName = true, worldId = 0, IsCanFind = 1, XMap = -207.8, YMap = -6.736248, ZMap = -93.4, PkMode = 0 },
			[194] = { x = -283.94, y = 1.98, z = -68.46, name = "몽환 마을", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[195] = { x = -369.51, y = 2.10, z = 6.43, name = "아룬의 샘", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[197] = { x = -270.07, y = 0.17, z = -2.85, name = "북쪽 몽환의 숲", isShowName = true, worldId = 0, PkMode = 0 },
			[198] = { x = -200.71, y = -1.28, z = 114.12, name = "환각석 절벽", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[199] = { x = -122.91, y = 5.71, z = -5.15, name = "주라스 대교", isShowName = true, worldId = 0, IsCanFind = 1, XMap = -155.8, YMap = 5.369486, ZMap = -1.2, PkMode = 0 },
			[200] = { x = -50.60, y = 13.06, z = -13.48, name = "파라밍 캠프", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[201] = { x = 39.88, y = 30.46, z = 76.43, name = "루린 마을", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[202] = { x = -59.39, y = 40.51, z = 59.73, name = "산꼭대기의 폐허", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[203] = { x = -39.66, y = 6.80, z = -116.19, name = "감옥 캠프", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[204] = { x = 256.07, y = 34.35, z = -43.22, name = "태양의 협곡", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[205] = { x = 319.85, y = 48.62, z = -89.62, name = "시칸 마을", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[206] = { x = 333.08, y = 30.27, z = 67.90, name = "검은 제단", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 0 },
			[207] = { x = 258.54, y = 12.32, z = 50.51, name = "황금 무덤", isShowName = true, worldId = 0, IsCanFind = 1, PkMode = 2, CameraDistance = 15 },
			[208] = { x = 129.33, y = 15.05, z = -16.69, name = "파라밍 광야", isShowName = true, worldId = 0, PkMode = 0 },
			[222] = { x = 61.06, y = 30.41, z = 48.47, name = "罗琳镇相位入口", worldId = 0, PkMode = 0 },
			[223] = { x = -207.61, y = -12.88, z = -119.16, name = "追踪尼古拉斯区域【个人】", worldId = 0, PkMode = 0 },
			[225] = { x = -182.77, y = 2.67, z = -64.63, name = "第二次相位区域", worldId = 0, PkMode = 0 },
			[226] = { x = -224.35, y = 0.17, z = -23.40, name = "逃离营地区域", worldId = 0, PkMode = 0 },
			[227] = { x = -372.01, y = -0.08, z = -56.37, name = "亚伦之泉前鹰眼", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {2235} },
			[228] = { x = -169.50, y = 0.22, z = -2.44, name = "前往朱拉丝区域", worldId = 0, PkMode = 0 },
			[229] = { x = -60.55, y = 7.21, z = -15.34, name = "长桥对岸", worldId = 0, PkMode = 0 },
			[230] = { x = 7.41, y = 6.65, z = -102.35, name = "逃出奴隶营", worldId = 0, PkMode = 0 },
			[231] = { x = 135.90, y = 10.07, z = -96.75, name = "返回烈日峡谷1", worldId = 0, PkMode = 0 },
			[232] = { x = 211.55, y = 34.43, z = -111.69, name = "返回烈日峡谷2", worldId = 0, PkMode = 0 },
			[234] = { x = 146.80, y = 39.86, z = 18.51, name = "抵抗军根据地", worldId = 0, PkMode = 0 },
			[235] = { x = 332.52, y = 30.26, z = 44.92, name = "前往黑色祭坛", worldId = 0, PkMode = 0 },
			[236] = { x = -208.40, y = -1.28, z = 115.95, name = "符文石仪式", worldId = 0, PkMode = 0 },
			[237] = { x = 12.75, y = 21.04, z = 27.26, name = "使用军令", worldId = 0, PkMode = 0 },
			[239] = { x = 296.38, y = 51.94, z = -62.31, name = "伊斯莲仪式", worldId = 0, PkMode = 0 },
			[241] = { x = -276.26, y = 6.60, z = -80.23, name = "寻找爱丽丝", worldId = 0, PkMode = 0 },
			[242] = { x = -273.81, y = -3.45, z = -42.69, name = "被袭击的爱丽丝", worldId = 0, PkMode = 0 },
			[254] = { x = -205.55, y = -1.28, z = 131.93, name = "寻找接头人", worldId = 0, PkMode = 0 },
			[255] = { x = 201.20, y = 34.35, z = -131.74, name = "支线-12021-到达烈日峡谷", worldId = 0, PkMode = 0 },
			[257] = { x = -275.76, y = -3.45, z = -42.63, name = "支线-爱丽丝二次-野兽袭击【迷幻森林】", worldId = 0, PkMode = 0 },
			[258] = { x = -272.57, y = -3.31, z = -32.93, name = "支线-爱丽丝二次-幻影军团【迷幻森林】", worldId = 0, PkMode = 0 },
			[259] = { x = 333.35, y = 30.49, z = 11.67, name = "支线-泽尔特的货物-席崁强盗【烈日谷】", worldId = 0, PkMode = 0 },
			[260] = { x = 192.97, y = 34.46, z = -142.57, name = "支线-安农商人-德法追兵【烈日谷】", worldId = 0, PkMode = 0 },
			[261] = { x = -206.40, y = -1.28, z = 147.56, name = "支线-藏匿的包裹-黑翼强盗", worldId = 0, PkMode = 0 },
			[262] = { x = 31.85, y = 13.39, z = -38.18, name = "支线-黑旗触发-德法军团", worldId = 0, PkMode = 0 },
			[263] = { x = 360.38, y = 30.31, z = 8.71, name = "支线-丢失的材料包触发-野兽", worldId = 0, PkMode = 0 },
			[268] = { x = -63.60, y = 40.50, z = 41.20, name = "길드", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {52004} },
			[269] = { x = -48.40, y = 40.42, z = 87.10, name = "", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {52003} },
			[361] = { x = -222.06, y = 93.12, z = 7.60, name = "背景音乐-北迷幻森林", worldId = 0, BackgroundMusic = "BGM_Map_3/Map_3/map_3_zone_2", PkMode = 0, EnvironmentMusic = "Zone_Ambience/Ambience/Forest" },
			[362] = { x = -352.66, y = 59.79, z = 37.24, name = "背景音乐-亚伦之泉", worldId = 0, BackgroundMusic = "BGM_Map_3/Map_3/map_3_zone_3", PkMode = 0, EnvironmentMusic = "Zone_Ambience/Ambience/Forest" },
			[363] = { x = 151.94, y = 58.59, z = -11.88, name = "背景音乐-沙漠", worldId = 0, BackgroundMusic = "BGM_Map_3/Map_3/map_3_zone_1", PkMode = 0, EnvironmentMusic = "Zone_Ambience/Ambience/Desert" },
			[364] = { x = 259.31, y = 1.00, z = 69.32, name = "背景音乐-金属坟场", worldId = 0, BackgroundMusic = "BGM_Map_3/Map_3/map_3_dunjeon_1", BattleMusic = "BGM_Map_3/Map_3/map_3_battle", PkMode = 0, EnvironmentMusic = "Zone_Ambience/Ambience/Desert" },
			[431] = { x = 227.34, y = 35.92, z = -114.72, name = "声望席坎文物1", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {63102} },
			[432] = { x = 188.77, y = 25.62, z = -82.88, name = "声望席坎文物2", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {63102} },
			[433] = { x = 135.67, y = 12.03, z = -103.84, name = "声望席坎文物3", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {63102} },
			[434] = { x = -331.30, y = 0.27, z = -129.70, name = "神视单人-万物志1", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[435] = { x = -331.30, y = 2.55, z = -129.70, name = "神视单人-神秘商人1", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[436] = { x = 32.32, y = 31.04, z = 44.07, name = "神视单人-万物志2", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[437] = { x = 146.20, y = 55.98, z = 26.37, name = "神视单人-神秘商人2", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[438] = { x = -371.50, y = -0.01, z = 4.69, name = "神视单人-神秘商人3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[439] = { x = -374.90, y = -0.02, z = -48.01, name = "神视单人-随机事件1-new1", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[440] = { x = -207.98, y = 5.83, z = 68.73, name = "神视单人-随机事件2-new2", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[441] = { x = 45.27, y = 32.57, z = -82.70, name = "神视单人-随机事件3-new3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[442] = { x = 18.30, y = 40.46, z = 30.40, name = "神视单人-随机事件4-new4", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[443] = { x = 208.27, y = 87.39, z = -120.20, name = "神视单人-万物志3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[444] = { x = 39.35, y = 19.53, z = -85.65, name = "神视单人-随机事件5-new3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[445] = { x = 325.23, y = 49.63, z = -24.37, name = "神视单人-随机事件6-new5", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[446] = { x = -4.61, y = 23.67, z = -27.86, name = "神视多人1-1", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[447] = { x = -4.67, y = 23.17, z = -26.91, name = "神视多人1-2", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[448] = { x = 1.01, y = 56.38, z = -36.54, name = "神视多人1-3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[449] = { x = -3.15, y = 23.06, z = -28.08, name = "神视多人1-4", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[450] = { x = -212.12, y = -0.64, z = -10.90, name = "神视多人2-1", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[451] = { x = -212.60, y = -0.32, z = -11.60, name = "神视多人2-2", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[452] = { x = -212.69, y = 1.06, z = -15.06, name = "神视多人2-3", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[453] = { x = -212.83, y = -0.65, z = -11.56, name = "神视多人2-4", worldId = 0, PkMode = 0, IsCanHawkeye = true },
			[454] = { x = 302.92, y = 48.95, z = -102.26, name = "声望护送任务抵达", worldId = 0, PkMode = 0 },
			[455] = { x = -194.34, y = 0.27, z = 0.45, name = "寻找货运人传送区域", worldId = 0, PkMode = 0 },
			[459] = { x = 155.63, y = 59.46, z = 18.43, name = "罗琳镇相位进入区域", worldId = 0, PkMode = 0 },
			[460] = { x = 316.76, y = 49.56, z = -77.09, name = "火羽相位", worldId = 0, PkMode = 0 },
			[461] = { x = 74.14, y = 11.80, z = -64.52, name = "파라밍 광야", isShowName = true, worldId = 0, PkMode = 0 },
			[462] = { x = -201.60, y = -6.65, z = -69.92, name = "버려진 데바 주둔지", isShowName = true, worldId = 0, PkMode = 0 },
			[463] = { x = -361.84, y = -3.43, z = -83.20, name = "북쪽 몽환의 숲", isShowName = true, worldId = 0, PkMode = 0 },
			[563] = { x = -365.71, y = 5.06, z = 13.86, name = "아룬의 샘", isShowName = true, worldId = 0, PkMode = 0 },
			[564] = { x = 164.11, y = 20.03, z = -106.56, name = "태양의 협곡", worldId = 0, PkMode = 0 },
			[579] = { x = 311.81, y = -9.55, z = 47.96, name = "最后一战相位", worldId = 0, PkMode = 0 },
			[580] = { x = 50.65, y = 21.11, z = 52.06, name = "声望-点燃圣火-使用区域", worldId = 0, PkMode = 0 },
			[581] = { x = 59.45, y = 31.06, z = 76.28, name = "声望-修复工具-使用区域", worldId = 0, PkMode = 0 },
			[582] = { x = 293.66, y = 45.28, z = -112.45, name = "声望-圣火相位进入点", worldId = 0, PkMode = 0 },
			[583] = { x = -209.39, y = -1.28, z = 123.32, name = "里勒姆到达点", worldId = 0, PkMode = 0 },
			[584] = { x = 119.09, y = 12.68, z = -95.26, name = "声望-机器人抵达", worldId = 0, PkMode = 0 },
			[585] = { x = 53.90, y = 21.08, z = -0.12, name = "声望-德法间谍刷怪", worldId = 0, PkMode = 0 },
			[586] = { x = 57.74, y = 21.28, z = 16.29, name = "声望-护送抵达", worldId = 0, PkMode = 0 },
			[587] = { x = 140.58, y = 20.31, z = -90.35, name = "pk区域", worldId = 0, PkMode = 4 },
			[588] = { x = 140.77, y = 17.88, z = -63.91, name = "复活点安全区141", worldId = 0, PkMode = 1 },
			[589] = { x = -4.98, y = 20.83, z = -81.97, name = "复活点安全区140", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[194] = 
		{
			[1] = { x = 333.81, y = 30.16, z = 79.53 },
		},
		[196] = 
		{
			[1] = { x = 222.40, y = -6.70, z = 18.40 },
		},
		[195] = 
		{
			[1] = { x = -83.17, y = 40.39, z = 71.84 },
		},
		[225] = 
		{
			[1] = { x = -363.96, y = -3.78, z = -79.15 },
		},
		[226] = 
		{
			[1] = { x = -391.30, y = -0.01, z = -49.66 },
			[2] = { x = -362.18, y = -0.70, z = -63.67 },
			[3] = { x = -369.89, y = -0.01, z = -51.59 },
		},
		[227] = 
		{
			[1] = { x = -357.28, y = -4.91, z = -80.44 },
		},
		[228] = 
		{
			[1] = { x = -386.40, y = 0.01, z = -30.23 },
			[2] = { x = -392.99, y = 0.01, z = -30.23 },
			[3] = { x = -389.25, y = 0.01, z = -30.23 },
		},
		[201] = 
		{
			[1] = { x = -296.84, y = -8.51, z = -127.37 },
			[2] = { x = -312.91, y = -8.48, z = -106.99 },
		},
		[216] = 
		{
			[1] = { x = -285.22, y = -3.45, z = -37.40 },
		},
		[218] = 
		{
			[1] = { x = -188.87, y = -4.26, z = -65.01 },
		},
		[217] = 
		{
			[1] = { x = -327.04, y = -3.42, z = -146.73 },
		},
		[219] = 
		{
			[1] = { x = -209.32, y = -1.28, z = 115.35 },
		},
		[199] = 
		{
			[1] = { x = 18.95, y = 21.04, z = 48.62 },
		},
		[197] = 
		{
			[1] = { x = -347.06, y = 0.02, z = 33.45 },
		},
		[244] = 
		{
			[1] = { x = -209.47, y = -1.28, z = 115.17 },
		},
		[271] = 
		{
			[1] = { x = -239.45, y = -17.74, z = -162.54 },
		},
		[272] = 
		{
			[1] = { x = -192.38, y = 0.17, z = 14.34 },
		},
		[273] = 
		{
			[1] = { x = -230.00, y = -0.92, z = 150.61 },
		},
		[274] = 
		{
			[1] = { x = 88.00, y = 10.03, z = -100.97 },
		},
		[275] = 
		{
			[1] = { x = 144.10, y = 12.61, z = -73.29 },
		},
		[202] = 
		{
			[1] = { x = 328.80, y = 30.31, z = 10.00 },
		},
		[203] = 
		{
			[1] = { x = 57.13, y = 21.06, z = 31.88 },
		},
		[204] = 
		{
			[1] = { x = -221.63, y = 0.46, z = 24.50 },
		},
		[205] = 
		{
			[1] = { x = -209.12, y = -1.28, z = 147.38 },
		},
		[206] = 
		{
			[1] = { x = 39.90, y = 14.93, z = -34.09 },
		},
		[207] = 
		{
			[1] = { x = -228.55, y = 1.55, z = 6.20 },
		},
		[208] = 
		{
			[1] = { x = 115.30, y = 10.09, z = -112.70 },
		},
		[209] = 
		{
			[1] = { x = -270.83, y = -3.45, z = -38.72 },
		},
		[210] = 
		{
			[1] = { x = -343.00, y = -0.08, z = 42.00 },
			[2] = { x = -340.60, y = -0.01, z = 39.60 },
			[3] = { x = -349.00, y = -1.14, z = 41.10 },
			[4] = { x = -343.00, y = 0.00, z = 33.20 },
			[5] = { x = -342.13, y = -0.01, z = 17.72 },
			[6] = { x = -337.86, y = -0.01, z = 21.89 },
		},
		[214] = 
		{
			[1] = { x = 367.10, y = 30.31, z = 9.60 },
		},
		[212] = 
		{
			[1] = { x = -298.17, y = -8.48, z = -121.79 },
		},
		[211] = 
		{
			[1] = { x = -319.31, y = -8.40, z = -126.35 },
		},
		[301] = 
		{
			[1] = { x = 294.88, y = 51.96, z = -59.44 },
		},
		[371] = 
		{
			[1] = { x = -47.38, y = 40.39, z = 86.35 },
		},
		[372] = 
		{
			[1] = { x = -63.73, y = 40.39, z = 41.31 },
		},
		[373] = 
		{
			[1] = { x = 194.90, y = 34.35, z = -117.14 },
		},
		[374] = 
		{
			[1] = { x = 226.54, y = 34.81, z = -122.08 },
		},
		[317] = 
		{
			[1] = { x = -374.29, y = -0.01, z = 7.03 },
		},
		[320] = 
		{
			[1] = { x = -220.88, y = -1.28, z = 97.06 },
		},
		[318] = 
		{
			[1] = { x = 291.35, y = 51.94, z = -55.21 },
		},
		[321] = 
		{
			[1] = { x = -58.52, y = 40.39, z = 85.75 },
		},
		[322] = 
		{
			[1] = { x = 318.33, y = 30.49, z = 20.07 },
		},
		[491] = 
		{
			[1] = { x = -15.10, y = 8.49, z = -61.70 },
			[2] = { x = -10.20, y = 8.49, z = -64.20 },
			[3] = { x = -9.50, y = 8.49, z = -69.90 },
			[4] = { x = -9.10, y = 8.49, z = -76.60 },
		},
		[550] = 
		{
			[1] = { x = 261.38, y = 42.84, z = -124.71 },
		},
		[552] = 
		{
			[1] = { x = 227.37, y = 34.92, z = -114.50 },
		},
		[563] = 
		{
			[1] = { x = 188.80, y = 24.45, z = -82.90 },
		},
		[564] = 
		{
			[1] = { x = 135.70, y = 11.03, z = -103.80 },
		},
		[588] = 
		{
			[1] = { x = -332.66, y = -0.03, z = 25.00 },
			[2] = { x = -207.89, y = -1.28, z = 137.33 },
			[3] = { x = -80.90, y = 40.39, z = 70.60 },
			[4] = { x = -54.49, y = 3.40, z = -111.72 },
			[5] = { x = 95.68, y = 21.87, z = -7.04 },
			[6] = { x = 336.85, y = 30.33, z = 32.18 },
		},
		[339] = 
		{
			[1] = { x = 342.09, y = 45.61, z = -37.32 },
		},
		[621] = 
		{
			[1] = { x = 26.43, y = 21.20, z = 23.72 },
		},
		[723] = 
		{
			[1] = { x = -239.45, y = -17.73, z = -162.54 },
		},
		[724] = 
		{
			[1] = { x = -192.38, y = 0.17, z = 14.34 },
		},
		[725] = 
		{
			[1] = { x = -230.00, y = -0.92, z = 150.61 },
		},
		[726] = 
		{
			[1] = { x = 88.00, y = 10.04, z = -100.97 },
		},
		[727] = 
		{
			[1] = { x = 144.10, y = 12.55, z = -73.29 },
		},
		[773] = 
		{
			[1] = { x = -239.45, y = -17.73, z = -162.54 },
		},
		[774] = 
		{
			[1] = { x = -192.38, y = 0.17, z = 14.34 },
		},
		[775] = 
		{
			[1] = { x = -230.00, y = -0.92, z = 150.61 },
		},
		[776] = 
		{
			[1] = { x = 88.00, y = 10.04, z = -100.97 },
		},
		[777] = 
		{
			[1] = { x = 144.10, y = 12.55, z = -73.29 },
		},
		[869] = 
		{
			[1] = { x = 50.41, y = 21.04, z = 52.57 },
		},
		[868] = 
		{
			[1] = { x = 61.50, y = 25.77, z = 75.37 },
		},
		[867] = 
		{
			[1] = { x = 108.71, y = 21.27, z = -22.22 },
			[2] = { x = 107.50, y = 20.16, z = -26.64 },
			[3] = { x = 106.85, y = 21.87, z = -6.42 },
		},
		[886] = 
		{
			[1] = { x = -231.47, y = -17.74, z = -156.79 },
		},
		[873] = 
		{
			[1] = { x = -188.17, y = 0.26, z = -6.04 },
		},
		[906] = 
		{
			[1] = { x = 110.48, y = 10.07, z = -102.30 },
		},
		[885] = 
		{
			[1] = { x = 55.24, y = 21.11, z = 10.22 },
		},
	},
	Entity = 
	{
		[20] = 
		{
			x = -233.84, y = -17.66, z = -163.06, Type = 1,
			Tid = 
			{
				[12000] = 2,
				[12001] = 1,
			},
		},
		[21] = 
		{
			x = -228.81, y = -17.76, z = -166.45, Type = 1,
			Tid = 
			{
				[12216] = 3,
				[12001] = 3,
			},
		},
		[22] = 
		{
			x = -218.10, y = 1.20, z = -78.00, Type = 1,
			Tid = 
			{
				[12002] = 25,
			},
		},
		[25] = 
		{
			x = -225.63, y = -4.83, z = -56.71, Type = 1,
			Tid = 
			{
				[12003] = 1,
			},
		},
		[27] = 
		{
			x = -214.15, y = -6.64, z = -85.02, Type = 1,
			Tid = 
			{
				[12003] = 1,
			},
		},
		[28] = 
		{
			x = -196.61, y = 0.43, z = -74.65, Type = 1,
			Tid = 
			{
				[12003] = 2,
			},
		},
		[33] = 
		{
			x = 52.00, y = 10.30, z = -73.60, Type = 1,
			Tid = 
			{
				[12011] = 25,
			},
		},
		[34] = 
		{
			x = 29.00, y = 12.29, z = -127.70, Type = 1,
			Tid = 
			{
				[12258] = 3,
			},
		},
		[36] = 
		{
			x = -46.18, y = 7.38, z = -40.52, Type = 1,
			Tid = 
			{
				[12010] = 3,
			},
		},
		[37] = 
		{
			x = -55.74, y = 7.14, z = -33.39, Type = 1,
			Tid = 
			{
				[12010] = 3,
			},
		},
		[42] = 
		{
			x = -30.89, y = 2.18, z = -119.86, Type = 1,
			Tid = 
			{
				[12012] = 3,
			},
		},
		[43] = 
		{
			x = -22.32, y = 1.82, z = -104.07, Type = 1,
			Tid = 
			{
				[12012] = 3,
			},
		},
		[44] = 
		{
			x = -36.77, y = 3.30, z = -104.54, Type = 1,
			Tid = 
			{
				[12012] = 3,
			},
		},
		[46] = 
		{
			x = -46.61, y = 3.30, z = -115.24, Type = 1,
			Tid = 
			{
				[12012] = 3,
				[12013] = 1,
			},
		},
		[48] = 
		{
			x = 212.01, y = 34.35, z = -123.17, Type = 1,
			Tid = 
			{
				[12015] = 2,
			},
		},
		[49] = 
		{
			x = 203.17, y = 34.35, z = -120.06, Type = 1,
			Tid = 
			{
				[12015] = 2,
			},
		},
		[23] = 
		{
			x = -217.72, y = -6.74, z = -68.81, Type = 1,
			Tid = 
			{
				[12003] = 1,
			},
		},
		[57] = 
		{
			x = 332.28, y = 31.20, z = 58.46, Type = 1,
			Tid = 
			{
				[12016] = 4,
				[12017] = 2,
			},
		},
		[59] = 
		{
			x = 334.24, y = 30.23, z = 75.13, Type = 1,
			Tid = 
			{
				[12018] = 1,
			},
		},
		[58] = 
		{
			x = 252.60, y = -9.78, z = 54.40, Type = 1,
			Tid = 
			{
				[34002] = 1,
			},
		},
		[119] = 
		{
			x = 15.33, y = 6.12, z = -100.19, Type = 1,
			Tid = 
			{
				[12019] = 6,
				[12020] = 3,
			},
		},
		[32] = 
		{
			x = 51.29, y = 13.91, z = -116.60, Type = 1,
			Tid = 
			{
				[12258] = 3,
			},
		},
		[120] = 
		{
			x = 138.36, y = 11.29, z = -84.52, Type = 1,
			Tid = 
			{
				[12014] = 6,
			},
		},
		[126] = 
		{
			x = -70.32, y = 40.39, z = 67.22, Type = 1,
			Tid = 
			{
				[12023] = 1,
				[12021] = 4,
			},
		},
		[145] = 
		{
			x = -236.25, y = -17.74, z = -160.36, Type = 1,
			Tid = 
			{
				[35230] = 1,
				[35231] = 1,
				[35232] = 1,
			},
		},
		[146] = 
		{
			x = -188.50, y = 0.17, z = 16.98, Type = 1,
			Tid = 
			{
				[35230] = 1,
				[35231] = 2,
			},
		},
		[147] = 
		{
			x = -230.00, y = -1.28, z = 147.00, Type = 1,
			Tid = 
			{
				[35230] = 1,
				[35231] = 1,
				[35232] = 1,
			},
		},
		[148] = 
		{
			x = 92.14, y = 10.04, z = -99.18, Type = 1,
			Tid = 
			{
				[35230] = 1,
				[35231] = 1,
				[35232] = 1,
			},
		},
		[149] = 
		{
			x = 141.53, y = 12.55, z = -69.51, Type = 1,
			Tid = 
			{
				[35230] = 1,
				[35231] = 1,
				[35232] = 1,
			},
		},
		[185] = 
		{
			x = -275.80, y = -3.45, z = -42.43, Type = 1,
			Tid = 
			{
				[12080] = 5,
			},
		},
		[186] = 
		{
			x = -272.34, y = -3.45, z = -32.92, Type = 1,
			Tid = 
			{
				[12081] = 1,
				[12082] = 4,
			},
		},
		[187] = 
		{
			x = 333.19, y = 30.31, z = 11.90, Type = 1,
			Tid = 
			{
				[12079] = 5,
			},
		},
		[188] = 
		{
			x = 196.04, y = 34.83, z = -143.09, Type = 1,
			Tid = 
			{
				[12076] = 3,
			},
		},
		[189] = 
		{
			x = -362.50, y = -5.33, z = -85.10, Type = 1,
			Tid = 
			{
				[12072] = 25,
			},
		},
		[190] = 
		{
			x = -197.52, y = 0.26, z = -11.20, Type = 1,
			Tid = 
			{
				[12073] = 6,
			},
		},
		[191] = 
		{
			x = -205.40, y = 0.20, z = 18.05, Type = 1,
			Tid = 
			{
				[12073] = 6,
			},
		},
		[192] = 
		{
			x = 191.60, y = 34.34, z = -117.00, Type = 1,
			Tid = 
			{
				[12074] = 3,
			},
		},
		[193] = 
		{
			x = 209.28, y = 30.65, z = -76.72, Type = 1,
			Tid = 
			{
				[12074] = 3,
			},
		},
		[194] = 
		{
			x = 298.63, y = 45.82, z = -131.24, Type = 1,
			Tid = 
			{
				[12074] = 3,
			},
		},
		[195] = 
		{
			x = -206.32, y = -1.28, z = 147.35, Type = 1,
			Tid = 
			{
				[12075] = 3,
			},
		},
		[196] = 
		{
			x = 32.66, y = 12.69, z = -37.26, Type = 1,
			Tid = 
			{
				[12078] = 1,
				[12077] = 5,
			},
		},
		[198] = 
		{
			x = 359.93, y = 30.31, z = 8.71, Type = 1,
			Tid = 
			{
				[12074] = 3,
			},
		},
		[227] = 
		{
			x = -357.60, y = -5.31, z = -118.20, Type = 1,
			Tid = 
			{
				[12073] = 3,
			},
		},
		[228] = 
		{
			x = -345.10, y = -5.31, z = -122.50, Type = 1,
			Tid = 
			{
				[12073] = 3,
			},
		},
		[223] = 
		{
			x = -364.75, y = -5.31, z = -112.99, Type = 1,
			Tid = 
			{
				[12072] = 3,
			},
		},
		[226] = 
		{
			x = 217.81, y = 34.35, z = -122.23, Type = 1,
			Tid = 
			{
				[12074] = 3,
			},
		},
		[241] = 
		{
			x = -349.46, y = -0.02, z = 19.63, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[242] = 
		{
			x = -213.72, y = -1.28, z = 131.65, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[243] = 
		{
			x = -45.30, y = 3.30, z = -115.81, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[244] = 
		{
			x = -71.66, y = 40.54, z = 67.33, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[338] = 
		{
			x = 92.99, y = 21.75, z = -15.51, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[246] = 
		{
			x = 337.13, y = 30.31, z = 19.20, Type = 1,
			Tid = 
			{
				[39003] = 1,
				[39005] = 4,
				[39006] = 4,
			},
		},
		[248] = 
		{
			x = -224.78, y = 0.91, z = -1.49, Type = 1,
			Tid = 
			{
				[39201] = 1,
			},
		},
		[249] = 
		{
			x = -188.76, y = -4.18, z = -64.93, Type = 1,
			Tid = 
			{
				[39201] = 1,
			},
		},
		[250] = 
		{
			x = -207.12, y = -12.95, z = -139.54, Type = 1,
			Tid = 
			{
				[39201] = 1,
			},
		},
		[251] = 
		{
			x = -59.60, y = 40.39, z = 66.00, Type = 1,
			Tid = 
			{
				[39200] = 1,
			},
		},
		[252] = 
		{
			x = 20.70, y = 21.04, z = 37.50, Type = 1,
			Tid = 
			{
				[39200] = 1,
			},
		},
		[253] = 
		{
			x = 56.64, y = 11.99, z = -103.59, Type = 1,
			Tid = 
			{
				[39200] = 1,
			},
		},
		[254] = 
		{
			x = -207.60, y = -1.28, z = 107.60, Type = 1,
			Tid = 
			{
				[39201] = 1,
			},
		},
		[255] = 
		{
			x = -36.66, y = 2.99, z = -114.18, Type = 1,
			Tid = 
			{
				[39200] = 1,
			},
		},
		[297] = 
		{
			x = -236.25, y = -17.74, z = -160.36, Type = 1,
			Tid = 
			{
				[35245] = 1,
				[35246] = 1,
				[35247] = 1,
			},
		},
		[296] = 
		{
			x = -188.50, y = 0.17, z = 16.98, Type = 1,
			Tid = 
			{
				[35245] = 1,
				[35246] = 1,
				[35247] = 1,
			},
		},
		[295] = 
		{
			x = -230.00, y = -1.28, z = 147.00, Type = 1,
			Tid = 
			{
				[35245] = 1,
				[35246] = 1,
				[35247] = 1,
			},
		},
		[294] = 
		{
			x = 92.14, y = 10.04, z = -99.18, Type = 1,
			Tid = 
			{
				[35245] = 1,
				[35246] = 1,
				[35247] = 1,
			},
		},
		[293] = 
		{
			x = 141.53, y = 12.55, z = -69.51, Type = 1,
			Tid = 
			{
				[35245] = 1,
				[35246] = 1,
				[35247] = 1,
			},
		},
		[298] = 
		{
			x = -236.25, y = -17.74, z = -160.36, Type = 1,
			Tid = 
			{
				[35257] = 1,
				[35258] = 1,
			},
		},
		[299] = 
		{
			x = -188.50, y = 0.17, z = 16.98, Type = 1,
			Tid = 
			{
				[35257] = 1,
				[35258] = 1,
			},
		},
		[300] = 
		{
			x = -230.00, y = -1.28, z = 147.00, Type = 1,
			Tid = 
			{
				[35257] = 1,
				[35258] = 1,
			},
		},
		[301] = 
		{
			x = 92.14, y = 10.04, z = -99.18, Type = 1,
			Tid = 
			{
				[35257] = 1,
				[35258] = 1,
			},
		},
		[302] = 
		{
			x = 141.53, y = 12.55, z = -69.51, Type = 1,
			Tid = 
			{
				[35257] = 1,
				[35258] = 1,
			},
		},
		[35] = 
		{
			x = -365.64, y = 0.06, z = 13.82, Type = 1,
			Tid = 
			{
				[34204] = 1,
			},
		},
		[69] = 
		{
			x = 164.12, y = 16.21, z = -106.45, Type = 1,
			Tid = 
			{
				[34205] = 1,
			},
		},
		[315] = 
		{
			x = -45.85, y = 9.42, z = -26.08, Type = 1,
			Tid = 
			{
				[60046] = 6,
			},
		},
		[318] = 
		{
			x = -231.93, y = -17.76, z = -156.95, Type = 1,
			Tid = 
			{
				[12216] = 3,
				[12001] = 3,
			},
		},
		[329] = 
		{
			x = 116.98, y = 10.06, z = -105.91, Type = 1,
			Tid = 
			{
				[12237] = 10,
			},
		},
		[337] = 
		{
			x = 56.32, y = 21.04, z = -0.76, Type = 1,
			Tid = 
			{
				[12236] = 1,
			},
		},
		[1] = 
		{
			x = -225.77, y = -17.77, z = -159.47, Type = 2,
			Tid = 
			{
				[2001] = 1,
			},
		},
		[4] = 
		{
			x = -276.82, y = -8.43, z = -95.22, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[5] = 
		{
			x = -275.52, y = -8.43, z = -92.75, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[6] = 
		{
			x = -278.15, y = -8.43, z = -93.24, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[7] = 
		{
			x = -287.88, y = -3.53, z = -44.79, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[8] = 
		{
			x = -285.25, y = -3.53, z = -44.30, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[9] = 
		{
			x = -286.55, y = -3.53, z = -46.77, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[10] = 
		{
			x = -265.09, y = -3.53, z = -42.66, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[11] = 
		{
			x = -264.94, y = -3.53, z = -40.61, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[12] = 
		{
			x = -270.56, y = -3.53, z = -63.53, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[13] = 
		{
			x = -283.85, y = -3.53, z = -62.25, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[14] = 
		{
			x = -283.73, y = -8.38, z = -91.89, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[15] = 
		{
			x = -291.07, y = -8.38, z = -85.76, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[16] = 
		{
			x = -271.88, y = -2.09, z = -22.89, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[17] = 
		{
			x = -264.86, y = -1.72, z = -26.69, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[18] = 
		{
			x = -271.91, y = -8.22, z = -80.57, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[19] = 
		{
			x = -272.06, y = -8.22, z = -82.62, Type = 2,
			Tid = 
			{
				[2013] = 1,
			},
		},
		[29] = 
		{
			x = -381.32, y = -1.10, z = -29.42, Type = 2,
			Tid = 
			{
				[2014] = 1,
			},
		},
		[30] = 
		{
			x = -284.99, y = -3.45, z = -52.49, Type = 2,
			Tid = 
			{
				[2010] = 1,
			},
		},
		[31] = 
		{
			x = -222.63, y = -17.77, z = -159.96, Type = 2,
			Tid = 
			{
				[2094] = 1,
			},
		},
		[39] = 
		{
			x = -39.19, y = 9.33, z = -3.35, Type = 2,
			Tid = 
			{
				[2020] = 1,
			},
		},
		[40] = 
		{
			x = -48.02, y = 9.23, z = -10.80, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[41] = 
		{
			x = -46.39, y = 9.33, z = -3.93, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[45] = 
		{
			x = -60.60, y = 3.30, z = -116.01, Type = 2,
			Tid = 
			{
				[2030] = 1,
			},
		},
		[24] = 
		{
			x = -39.46, y = 9.44, z = -15.48, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[38] = 
		{
			x = 305.75, y = 51.98, z = -60.29, Type = 2,
			Tid = 
			{
				[2032] = 1,
			},
		},
		[50] = 
		{
			x = 280.79, y = 52.00, z = -65.77, Type = 2,
			Tid = 
			{
				[2034] = 1,
			},
		},
		[51] = 
		{
			x = 328.24, y = 48.80, z = -102.71, Type = 2,
			Tid = 
			{
				[2035] = 1,
			},
		},
		[52] = 
		{
			x = 346.92, y = 48.80, z = -91.15, Type = 2,
			Tid = 
			{
				[2036] = 1,
			},
		},
		[53] = 
		{
			x = 305.65, y = 48.09, z = -107.14, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[54] = 
		{
			x = 292.97, y = 48.32, z = -99.91, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[55] = 
		{
			x = 326.10, y = 48.80, z = -45.62, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[56] = 
		{
			x = 340.93, y = 48.32, z = -46.25, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[62] = 
		{
			x = -35.94, y = 9.33, z = -10.14, Type = 2,
			Tid = 
			{
				[2021] = 1,
			},
		},
		[63] = 
		{
			x = -32.83, y = 9.33, z = -6.06, Type = 2,
			Tid = 
			{
				[2042] = 1,
			},
		},
		[64] = 
		{
			x = 12.84, y = 21.04, z = 30.08, Type = 2,
			Tid = 
			{
				[2023] = 1,
			},
		},
		[65] = 
		{
			x = 10.95, y = 21.04, z = 24.98, Type = 2,
			Tid = 
			{
				[2026] = 1,
			},
		},
		[66] = 
		{
			x = 14.71, y = 21.04, z = 36.03, Type = 2,
			Tid = 
			{
				[2026] = 1,
			},
		},
		[67] = 
		{
			x = 76.40, y = 15.64, z = -41.20, Type = 2,
			Tid = 
			{
				[2019] = 4,
			},
		},
		[68] = 
		{
			x = 76.16, y = 17.40, z = -30.86, Type = 2,
			Tid = 
			{
				[2022] = 1,
			},
		},
		[71] = 
		{
			x = 167.61, y = 39.73, z = 9.50, Type = 2,
			Tid = 
			{
				[2029] = 1,
			},
		},
		[72] = 
		{
			x = 62.30, y = 25.49, z = 75.38, Type = 2,
			Tid = 
			{
				[2028] = 1,
			},
		},
		[73] = 
		{
			x = 27.33, y = 21.06, z = 51.24, Type = 2,
			Tid = 
			{
				[2025] = 1,
			},
		},
		[74] = 
		{
			x = 61.09, y = 21.04, z = -5.67, Type = 2,
			Tid = 
			{
				[2026] = 1,
			},
		},
		[75] = 
		{
			x = 66.99, y = 21.02, z = -2.85, Type = 2,
			Tid = 
			{
				[2026] = 1,
			},
		},
		[76] = 
		{
			x = 159.97, y = 39.66, z = 8.81, Type = 2,
			Tid = 
			{
				[2027] = 1,
			},
		},
		[77] = 
		{
			x = 157.89, y = 39.66, z = 7.35, Type = 2,
			Tid = 
			{
				[2027] = 1,
			},
		},
		[78] = 
		{
			x = 157.84, y = 39.66, z = 10.28, Type = 2,
			Tid = 
			{
				[2027] = 1,
			},
		},
		[79] = 
		{
			x = 147.02, y = 39.66, z = 12.74, Type = 2,
			Tid = 
			{
				[2027] = 1,
			},
		},
		[80] = 
		{
			x = 151.80, y = 39.66, z = 18.17, Type = 2,
			Tid = 
			{
				[2027] = 1,
			},
		},
		[81] = 
		{
			x = 32.29, y = 21.22, z = 11.48, Type = 2,
			Tid = 
			{
				[2095] = 1,
			},
		},
		[82] = 
		{
			x = 27.67, y = 21.23, z = 15.67, Type = 2,
			Tid = 
			{
				[2097] = 1,
			},
		},
		[83] = 
		{
			x = 52.58, y = 21.04, z = 12.88, Type = 2,
			Tid = 
			{
				[2098] = 1,
			},
		},
		[84] = 
		{
			x = 296.17, y = 48.52, z = -85.18, Type = 2,
			Tid = 
			{
				[2099] = 1,
			},
		},
		[85] = 
		{
			x = 287.48, y = 48.79, z = -86.96, Type = 2,
			Tid = 
			{
				[2097] = 1,
			},
		},
		[86] = 
		{
			x = -291.66, y = -8.38, z = -80.66, Type = 2,
			Tid = 
			{
				[2101] = 1,
			},
		},
		[87] = 
		{
			x = 58.77, y = 21.04, z = 43.69, Type = 2,
			Tid = 
			{
				[2024] = 1,
			},
		},
		[88] = 
		{
			x = 56.28, y = 21.04, z = 38.41, Type = 2,
			Tid = 
			{
				[2026] = 1,
			},
		},
		[90] = 
		{
			x = 164.90, y = 39.73, z = 12.83, Type = 2,
			Tid = 
			{
				[2043] = 1,
			},
		},
		[91] = 
		{
			x = 53.35, y = 21.04, z = 42.41, Type = 2,
			Tid = 
			{
				[2044] = 1,
			},
		},
		[92] = 
		{
			x = -366.80, y = -5.31, z = -92.06, Type = 2,
			Tid = 
			{
				[2105] = 1,
			},
		},
		[101] = 
		{
			x = -341.56, y = -0.08, z = 25.73, Type = 2,
			Tid = 
			{
				[2107] = 1,
			},
		},
		[102] = 
		{
			x = -340.70, y = -0.08, z = 30.80, Type = 2,
			Tid = 
			{
				[2106] = 1,
			},
		},
		[103] = 
		{
			x = -337.66, y = -0.08, z = 27.84, Type = 2,
			Tid = 
			{
				[2106] = 1,
			},
		},
		[104] = 
		{
			x = -357.54, y = -0.08, z = 43.04, Type = 2,
			Tid = 
			{
				[2106] = 1,
			},
		},
		[105] = 
		{
			x = -356.41, y = -0.08, z = 36.10, Type = 2,
			Tid = 
			{
				[2106] = 1,
			},
		},
		[106] = 
		{
			x = -354.81, y = -0.08, z = 39.59, Type = 2,
			Tid = 
			{
				[2106] = 1,
			},
		},
		[107] = 
		{
			x = -250.80, y = -18.44, z = -177.59, Type = 2,
			Tid = 
			{
				[2000] = 1,
			},
		},
		[26] = 
		{
			x = -206.12, y = -12.67, z = -112.76, Type = 2,
			Tid = 
			{
				[2037] = 1,
			},
		},
		[108] = 
		{
			x = -223.78, y = 0.31, z = -18.22, Type = 2,
			Tid = 
			{
				[2000] = 1,
			},
		},
		[110] = 
		{
			x = -267.07, y = -3.45, z = -53.28, Type = 2,
			Tid = 
			{
				[2009] = 1,
			},
		},
		[112] = 
		{
			x = -284.87, y = -3.40, z = -55.15, Type = 2,
			Tid = 
			{
				[2005] = 1,
			},
		},
		[113] = 
		{
			x = -42.66, y = 7.21, z = -35.44, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[114] = 
		{
			x = -33.46, y = 9.33, z = -10.69, Type = 2,
			Tid = 
			{
				[2026] = 2,
			},
		},
		[117] = 
		{
			x = 311.80, y = 30.31, z = 31.70, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[118] = 
		{
			x = 271.31, y = -9.90, z = 15.59, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[121] = 
		{
			x = 29.05, y = 21.04, z = 43.60, Type = 2,
			Tid = 
			{
				[2026] = 6,
			},
		},
		[122] = 
		{
			x = 47.05, y = 21.04, z = 20.93, Type = 2,
			Tid = 
			{
				[2019] = 1,
			},
		},
		[123] = 
		{
			x = 48.89, y = 21.04, z = 21.81, Type = 2,
			Tid = 
			{
				[2019] = 1,
			},
		},
		[124] = 
		{
			x = 58.65, y = 21.09, z = 17.14, Type = 2,
			Tid = 
			{
				[2019] = 1,
			},
		},
		[125] = 
		{
			x = 57.05, y = 21.07, z = 21.29, Type = 2,
			Tid = 
			{
				[2019] = 1,
			},
		},
		[127] = 
		{
			x = 292.32, y = 51.97, z = -72.96, Type = 2,
			Tid = 
			{
				[2038] = 1,
			},
		},
		[129] = 
		{
			x = 317.10, y = 30.16, z = 52.44, Type = 2,
			Tid = 
			{
				[2033] = 1,
			},
		},
		[130] = 
		{
			x = 48.69, y = 25.48, z = 89.09, Type = 2,
			Tid = 
			{
				[2041] = 1,
			},
		},
		[131] = 
		{
			x = 53.48, y = 25.48, z = 89.09, Type = 2,
			Tid = 
			{
				[2040] = 1,
			},
		},
		[132] = 
		{
			x = -216.05, y = -1.28, z = 114.14, Type = 2,
			Tid = 
			{
				[2006] = 1,
			},
		},
		[155] = 
		{
			x = -217.49, y = -13.22, z = -140.04, Type = 2,
			Tid = 
			{
				[2143] = 1,
			},
		},
		[156] = 
		{
			x = 12.73, y = 21.04, z = 11.56, Type = 2,
			Tid = 
			{
				[2070] = 1,
			},
		},
		[157] = 
		{
			x = 6.03, y = 21.04, z = 34.38, Type = 2,
			Tid = 
			{
				[2071] = 1,
			},
		},
		[158] = 
		{
			x = 44.37, y = 21.04, z = 26.89, Type = 2,
			Tid = 
			{
				[2072] = 1,
			},
		},
		[159] = 
		{
			x = 12.11, y = 21.07, z = 53.39, Type = 2,
			Tid = 
			{
				[2075] = 1,
			},
		},
		[160] = 
		{
			x = 12.01, y = 13.29, z = -33.50, Type = 2,
			Tid = 
			{
				[2077] = 1,
			},
		},
		[161] = 
		{
			x = 29.49, y = 21.22, z = 28.68, Type = 2,
			Tid = 
			{
				[2078] = 1,
			},
		},
		[162] = 
		{
			x = 14.73, y = 21.04, z = 42.87, Type = 2,
			Tid = 
			{
				[2079] = 1,
			},
		},
		[163] = 
		{
			x = -272.56, y = -8.35, z = -76.59, Type = 2,
			Tid = 
			{
				[2081] = 1,
			},
		},
		[164] = 
		{
			x = -270.99, y = -3.45, z = -40.97, Type = 2,
			Tid = 
			{
				[2082] = 1,
			},
		},
		[165] = 
		{
			x = -273.87, y = -8.43, z = -87.03, Type = 2,
			Tid = 
			{
				[2083] = 1,
			},
		},
		[166] = 
		{
			x = -285.21, y = -8.38, z = -79.67, Type = 2,
			Tid = 
			{
				[2084] = 1,
			},
		},
		[167] = 
		{
			x = -289.15, y = -8.38, z = -84.01, Type = 2,
			Tid = 
			{
				[2085] = 1,
			},
		},
		[168] = 
		{
			x = -210.50, y = 0.19, z = 27.57, Type = 2,
			Tid = 
			{
				[2088] = 1,
			},
		},
		[169] = 
		{
			x = -205.26, y = -1.28, z = 136.92, Type = 2,
			Tid = 
			{
				[2074] = 1,
			},
		},
		[170] = 
		{
			x = 182.51, y = 40.41, z = -144.18, Type = 2,
			Tid = 
			{
				[2073] = 1,
			},
		},
		[199] = 
		{
			x = 27.98, y = 21.23, z = 21.28, Type = 2,
			Tid = 
			{
				[2096] = 1,
			},
		},
		[224] = 
		{
			x = -51.33, y = 7.21, z = -29.18, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[225] = 
		{
			x = 37.05, y = 10.41, z = -49.81, Type = 2,
			Tid = 
			{
				[2019] = 2,
			},
		},
		[230] = 
		{
			x = 93.00, y = 10.06, z = -87.00, Type = 2,
			Tid = 
			{
				[2178] = 1,
			},
		},
		[231] = 
		{
			x = 315.81, y = 48.70, z = -78.17, Type = 2,
			Tid = 
			{
				[2176] = 1,
			},
		},
		[232] = 
		{
			x = 323.17, y = 48.70, z = -85.23, Type = 2,
			Tid = 
			{
				[2177] = 1,
			},
		},
		[233] = 
		{
			x = 312.46, y = 48.72, z = -98.62, Type = 2,
			Tid = 
			{
				[2179] = 1,
			},
		},
		[238] = 
		{
			x = -331.65, y = -3.79, z = -146.18, Type = 2,
			Tid = 
			{
				[20] = 1,
			},
		},
		[239] = 
		{
			x = 157.85, y = 39.73, z = 24.20, Type = 2,
			Tid = 
			{
				[21] = 1,
			},
		},
		[240] = 
		{
			x = -381.15, y = 0.02, z = 30.83, Type = 2,
			Tid = 
			{
				[22] = 1,
			},
		},
		[257] = 
		{
			x = 96.58, y = 10.06, z = -96.70, Type = 2,
			Tid = 
			{
				[2185] = 1,
			},
		},
		[258] = 
		{
			x = -375.64, y = -1.68, z = -144.36, Type = 2,
			Tid = 
			{
				[2212] = 2,
			},
		},
		[259] = 
		{
			x = -373.34, y = -1.68, z = -147.93, Type = 2,
			Tid = 
			{
				[2213] = 1,
			},
		},
		[260] = 
		{
			x = -344.61, y = -0.08, z = 36.90, Type = 2,
			Tid = 
			{
				[2214] = 1,
			},
		},
		[261] = 
		{
			x = -359.64, y = -0.02, z = 45.91, Type = 2,
			Tid = 
			{
				[2217] = 1,
			},
		},
		[262] = 
		{
			x = -361.96, y = -0.02, z = 41.87, Type = 2,
			Tid = 
			{
				[2217] = 1,
			},
		},
		[263] = 
		{
			x = -332.73, y = -0.02, z = 32.12, Type = 2,
			Tid = 
			{
				[2217] = 1,
			},
		},
		[264] = 
		{
			x = -330.93, y = -0.02, z = 29.19, Type = 2,
			Tid = 
			{
				[2217] = 1,
			},
		},
		[265] = 
		{
			x = -386.71, y = -0.01, z = 23.91, Type = 2,
			Tid = 
			{
				[2216] = 3,
			},
		},
		[266] = 
		{
			x = -343.58, y = -0.02, z = 22.15, Type = 2,
			Tid = 
			{
				[2216] = 3,
			},
		},
		[267] = 
		{
			x = -287.76, y = -8.41, z = -89.50, Type = 2,
			Tid = 
			{
				[2210] = 1,
				[2211] = 2,
			},
		},
		[268] = 
		{
			x = -266.57, y = -3.45, z = -57.22, Type = 2,
			Tid = 
			{
				[2206] = 1,
			},
		},
		[269] = 
		{
			x = -267.39, y = -3.45, z = -59.63, Type = 2,
			Tid = 
			{
				[2207] = 1,
			},
		},
		[270] = 
		{
			x = -282.97, y = -3.45, z = -34.50, Type = 2,
			Tid = 
			{
				[2206] = 1,
			},
		},
		[271] = 
		{
			x = -281.78, y = -3.45, z = -31.65, Type = 2,
			Tid = 
			{
				[2207] = 1,
			},
		},
		[272] = 
		{
			x = -221.04, y = -1.28, z = 98.81, Type = 2,
			Tid = 
			{
				[2216] = 3,
			},
		},
		[273] = 
		{
			x = -194.85, y = -1.28, z = 108.76, Type = 2,
			Tid = 
			{
				[2216] = 3,
			},
		},
		[274] = 
		{
			x = -191.22, y = -1.28, z = 124.32, Type = 2,
			Tid = 
			{
				[2219] = 1,
			},
		},
		[275] = 
		{
			x = -192.48, y = -1.28, z = 131.59, Type = 2,
			Tid = 
			{
				[2220] = 1,
			},
		},
		[276] = 
		{
			x = 46.97, y = 26.73, z = 110.78, Type = 2,
			Tid = 
			{
				[2221] = 2,
			},
		},
		[277] = 
		{
			x = 54.91, y = 26.64, z = 137.46, Type = 2,
			Tid = 
			{
				[2221] = 1,
			},
		},
		[278] = 
		{
			x = 47.39, y = 26.81, z = 128.66, Type = 2,
			Tid = 
			{
				[2221] = 1,
			},
		},
		[279] = 
		{
			x = 336.13, y = 48.82, z = -93.03, Type = 2,
			Tid = 
			{
				[2224] = 1,
			},
		},
		[280] = 
		{
			x = 333.88, y = 48.83, z = -95.67, Type = 2,
			Tid = 
			{
				[2224] = 1,
			},
		},
		[281] = 
		{
			x = 350.07, y = 48.80, z = -71.10, Type = 2,
			Tid = 
			{
				[2224] = 1,
			},
		},
		[282] = 
		{
			x = 351.23, y = 48.80, z = -79.92, Type = 2,
			Tid = 
			{
				[2224] = 1,
			},
		},
		[283] = 
		{
			x = 345.16, y = 48.80, z = -54.86, Type = 2,
			Tid = 
			{
				[2224] = 1,
			},
		},
		[284] = 
		{
			x = 302.33, y = 48.78, z = -81.89, Type = 2,
			Tid = 
			{
				[2222] = 1,
			},
		},
		[285] = 
		{
			x = 221.64, y = 34.46, z = -104.10, Type = 2,
			Tid = 
			{
				[2223] = 1,
			},
		},
		[286] = 
		{
			x = 162.76, y = 14.28, z = -85.17, Type = 2,
			Tid = 
			{
				[2223] = 1,
			},
		},
		[288] = 
		{
			x = 343.66, y = 30.16, z = 38.40, Type = 2,
			Tid = 
			{
				[2223] = 1,
			},
		},
		[287] = 
		{
			x = 160.50, y = 39.73, z = 14.70, Type = 2,
			Tid = 
			{
				[2236] = 1,
			},
		},
		[229] = 
		{
			x = -359.64, y = -0.26, z = 34.60, Type = 2,
			Tid = 
			{
				[2243] = 1,
			},
		},
		[291] = 
		{
			x = -349.43, y = 0.02, z = 30.73, Type = 2,
			Tid = 
			{
				[2241] = 1,
			},
		},
		[292] = 
		{
			x = -353.26, y = -0.16, z = 19.24, Type = 2,
			Tid = 
			{
				[2240] = 1,
			},
		},
		[70] = 
		{
			x = -347.06, y = -4.36, z = -125.72, Type = 2,
			Tid = 
			{
				[2270] = 1,
			},
		},
		[216] = 
		{
			x = 24.84, y = 21.04, z = 51.23, Type = 2,
			Tid = 
			{
				[2275] = 1,
			},
		},
		[316] = 
		{
			x = -228.80, y = -17.77, z = -158.52, Type = 2,
			Tid = 
			{
				[2314] = 3,
			},
		},
		[317] = 
		{
			x = -231.45, y = -17.75, z = -156.57, Type = 2,
			Tid = 
			{
				[2312] = 3,
			},
		},
		[319] = 
		{
			x = -219.86, y = 0.31, z = -16.83, Type = 2,
			Tid = 
			{
				[2286] = 1,
			},
		},
		[320] = 
		{
			x = -219.86, y = 0.29, z = -16.83, Type = 2,
			Tid = 
			{
				[2287] = 1,
			},
		},
		[321] = 
		{
			x = -210.85, y = -1.28, z = 122.80, Type = 2,
			Tid = 
			{
				[2288] = 1,
			},
		},
		[322] = 
		{
			x = -210.79, y = -1.28, z = 125.40, Type = 2,
			Tid = 
			{
				[2290] = 6,
			},
		},
		[323] = 
		{
			x = -285.15, y = -3.45, z = -58.22, Type = 2,
			Tid = 
			{
				[2289] = 1,
			},
		},
		[324] = 
		{
			x = -237.23, y = -17.71, z = -160.46, Type = 2,
			Tid = 
			{
				[2280] = 1,
			},
		},
		[327] = 
		{
			x = 51.02, y = 26.65, z = 133.33, Type = 2,
			Tid = 
			{
				[21] = 1,
			},
		},
		[328] = 
		{
			x = 118.10, y = 10.11, z = -91.00, Type = 2,
			Tid = 
			{
				[2323] = 1,
			},
		},
		[331] = 
		{
			x = 117.73, y = 10.10, z = -93.28, Type = 2,
			Tid = 
			{
				[2324] = 1,
			},
		},
		[332] = 
		{
			x = 52.22, y = 21.07, z = 16.81, Type = 2,
			Tid = 
			{
				[2325] = 1,
			},
		},
		[333] = 
		{
			x = 318.53, y = 48.81, z = -106.50, Type = 2,
			Tid = 
			{
				[2273] = 1,
			},
		},
		[334] = 
		{
			x = 312.62, y = 48.76, z = -106.50, Type = 2,
			Tid = 
			{
				[2362] = 1,
			},
		},
		[336] = 
		{
			x = 55.50, y = 21.09, z = -0.97, Type = 2,
			Tid = 
			{
				[2322] = 1,
			},
		},
		[60] = 
		{
			x = 333.81, y = 30.16, z = 79.53, Type = 6,
			Tid = 
			{
				[194] = 1,
			},
		},
		[61] = 
		{
			x = 222.40, y = -6.70, z = 18.40, Type = 6,
			Tid = 
			{
				[196] = 1,
			},
		},
		[89] = 
		{
			x = -83.17, y = 40.39, z = 71.84, Type = 6,
			Tid = 
			{
				[195] = 1,
			},
		},
		[93] = 
		{
			x = -363.96, y = -3.78, z = -79.15, Type = 6,
			Tid = 
			{
				[225] = 1,
			},
		},
		[94] = 
		{
			x = -391.30, y = -0.01, z = -49.66, Type = 6,
			Tid = 
			{
				[226] = 1,
			},
		},
		[95] = 
		{
			x = -357.28, y = -4.91, z = -80.44, Type = 6,
			Tid = 
			{
				[227] = 1,
			},
		},
		[96] = 
		{
			x = -386.40, y = 0.01, z = -30.23, Type = 6,
			Tid = 
			{
				[228] = 1,
			},
		},
		[97] = 
		{
			x = -392.99, y = 0.01, z = -30.23, Type = 6,
			Tid = 
			{
				[228] = 1,
			},
		},
		[98] = 
		{
			x = -389.25, y = 0.01, z = -30.23, Type = 6,
			Tid = 
			{
				[228] = 1,
			},
		},
		[99] = 
		{
			x = -362.18, y = -0.70, z = -63.67, Type = 6,
			Tid = 
			{
				[226] = 1,
			},
		},
		[100] = 
		{
			x = -369.89, y = -0.01, z = -51.59, Type = 6,
			Tid = 
			{
				[226] = 1,
			},
		},
		[109] = 
		{
			x = -296.84, y = -8.51, z = -127.37, Type = 6,
			Tid = 
			{
				[201] = 6,
			},
		},
		[111] = 
		{
			x = -285.22, y = -3.45, z = -37.40, Type = 6,
			Tid = 
			{
				[216] = 1,
			},
		},
		[2] = 
		{
			x = -188.87, y = -4.26, z = -65.01, Type = 6,
			Tid = 
			{
				[218] = 1,
			},
		},
		[3] = 
		{
			x = -312.91, y = -8.48, z = -106.99, Type = 6,
			Tid = 
			{
				[201] = 6,
			},
		},
		[115] = 
		{
			x = -327.04, y = -3.42, z = -146.73, Type = 6,
			Tid = 
			{
				[217] = 1,
			},
		},
		[116] = 
		{
			x = -209.32, y = -1.28, z = 115.35, Type = 6,
			Tid = 
			{
				[219] = 1,
			},
		},
		[47] = 
		{
			x = 18.95, y = 21.04, z = 48.62, Type = 6,
			Tid = 
			{
				[199] = 1,
			},
		},
		[128] = 
		{
			x = -347.06, y = 0.02, z = 33.45, Type = 6,
			Tid = 
			{
				[197] = 1,
			},
		},
		[133] = 
		{
			x = -209.47, y = -1.28, z = 115.17, Type = 6,
			Tid = 
			{
				[244] = 4,
			},
		},
		[150] = 
		{
			x = -239.45, y = -17.74, z = -162.54, Type = 6,
			Tid = 
			{
				[271] = 1,
			},
		},
		[151] = 
		{
			x = -192.38, y = 0.17, z = 14.34, Type = 6,
			Tid = 
			{
				[272] = 1,
			},
		},
		[152] = 
		{
			x = -230.00, y = -0.92, z = 150.61, Type = 6,
			Tid = 
			{
				[273] = 1,
			},
		},
		[153] = 
		{
			x = 88.00, y = 10.03, z = -100.97, Type = 6,
			Tid = 
			{
				[274] = 1,
			},
		},
		[154] = 
		{
			x = 144.10, y = 12.61, z = -73.29, Type = 6,
			Tid = 
			{
				[275] = 1,
			},
		},
		[171] = 
		{
			x = 328.80, y = 30.31, z = 10.00, Type = 6,
			Tid = 
			{
				[202] = 1,
			},
		},
		[172] = 
		{
			x = 57.13, y = 21.06, z = 31.88, Type = 6,
			Tid = 
			{
				[203] = 1,
			},
		},
		[173] = 
		{
			x = -221.63, y = 0.46, z = 24.50, Type = 6,
			Tid = 
			{
				[204] = 5,
			},
		},
		[174] = 
		{
			x = -209.12, y = -1.28, z = 147.38, Type = 6,
			Tid = 
			{
				[205] = 1,
			},
		},
		[175] = 
		{
			x = 39.90, y = 14.93, z = -34.09, Type = 6,
			Tid = 
			{
				[206] = 1,
			},
		},
		[176] = 
		{
			x = -228.55, y = 1.55, z = 6.20, Type = 6,
			Tid = 
			{
				[207] = 6,
			},
		},
		[177] = 
		{
			x = 115.30, y = 10.09, z = -112.70, Type = 6,
			Tid = 
			{
				[208] = 6,
			},
		},
		[178] = 
		{
			x = -270.83, y = -3.45, z = -38.72, Type = 6,
			Tid = 
			{
				[209] = 1,
			},
		},
		[179] = 
		{
			x = -343.00, y = -0.08, z = 42.00, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[180] = 
		{
			x = -340.60, y = -0.01, z = 39.60, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[181] = 
		{
			x = -349.00, y = -1.14, z = 41.10, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[182] = 
		{
			x = -343.00, y = 0.00, z = 33.20, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[183] = 
		{
			x = -342.13, y = -0.01, z = 17.72, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[184] = 
		{
			x = -337.86, y = -0.01, z = 21.89, Type = 6,
			Tid = 
			{
				[210] = 1,
			},
		},
		[197] = 
		{
			x = 367.10, y = 30.31, z = 9.60, Type = 6,
			Tid = 
			{
				[214] = 1,
			},
		},
		[200] = 
		{
			x = -298.17, y = -8.48, z = -121.79, Type = 6,
			Tid = 
			{
				[212] = 1,
			},
		},
		[201] = 
		{
			x = -319.31, y = -8.40, z = -126.35, Type = 6,
			Tid = 
			{
				[211] = 6,
			},
		},
		[202] = 
		{
			x = 294.88, y = 51.96, z = -59.44, Type = 6,
			Tid = 
			{
				[301] = 1,
			},
		},
		[207] = 
		{
			x = -47.38, y = 40.39, z = 86.35, Type = 6,
			Tid = 
			{
				[371] = 5,
			},
		},
		[208] = 
		{
			x = -63.73, y = 40.39, z = 41.31, Type = 6,
			Tid = 
			{
				[372] = 3,
			},
		},
		[209] = 
		{
			x = 194.90, y = 34.35, z = -117.14, Type = 6,
			Tid = 
			{
				[373] = 5,
			},
		},
		[210] = 
		{
			x = 226.54, y = 34.81, z = -122.08, Type = 6,
			Tid = 
			{
				[374] = 5,
			},
		},
		[211] = 
		{
			x = -374.29, y = -0.01, z = 7.03, Type = 6,
			Tid = 
			{
				[317] = 1,
			},
		},
		[212] = 
		{
			x = -220.88, y = -1.28, z = 97.06, Type = 6,
			Tid = 
			{
				[320] = 1,
			},
		},
		[213] = 
		{
			x = 291.35, y = 51.94, z = -55.21, Type = 6,
			Tid = 
			{
				[318] = 1,
			},
		},
		[214] = 
		{
			x = -58.52, y = 40.39, z = 85.75, Type = 6,
			Tid = 
			{
				[321] = 1,
			},
		},
		[215] = 
		{
			x = 318.33, y = 30.49, z = 20.07, Type = 6,
			Tid = 
			{
				[322] = 1,
			},
		},
		[219] = 
		{
			x = -15.10, y = 8.49, z = -61.70, Type = 6,
			Tid = 
			{
				[491] = 2,
			},
		},
		[220] = 
		{
			x = -10.20, y = 8.49, z = -64.20, Type = 6,
			Tid = 
			{
				[491] = 2,
			},
		},
		[221] = 
		{
			x = -9.50, y = 8.49, z = -69.90, Type = 6,
			Tid = 
			{
				[491] = 2,
			},
		},
		[222] = 
		{
			x = -9.10, y = 8.49, z = -76.60, Type = 6,
			Tid = 
			{
				[491] = 2,
			},
		},
		[234] = 
		{
			x = 261.38, y = 42.84, z = -124.71, Type = 6,
			Tid = 
			{
				[550] = 5,
			},
		},
		[235] = 
		{
			x = 227.37, y = 34.92, z = -114.50, Type = 6,
			Tid = 
			{
				[552] = 1,
			},
		},
		[236] = 
		{
			x = 188.80, y = 24.45, z = -82.90, Type = 6,
			Tid = 
			{
				[563] = 1,
			},
		},
		[237] = 
		{
			x = 135.70, y = 11.03, z = -103.80, Type = 6,
			Tid = 
			{
				[564] = 1,
			},
		},
		[203] = 
		{
			x = -332.66, y = -0.03, z = 25.00, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[204] = 
		{
			x = -207.89, y = -1.28, z = 137.33, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[205] = 
		{
			x = -80.90, y = 40.39, z = 70.60, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[206] = 
		{
			x = -54.49, y = 3.40, z = -111.72, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[247] = 
		{
			x = 95.68, y = 21.87, z = -7.04, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[256] = 
		{
			x = 336.85, y = 30.33, z = 32.18, Type = 6,
			Tid = 
			{
				[588] = 1,
			},
		},
		[289] = 
		{
			x = 342.09, y = 45.61, z = -37.32, Type = 6,
			Tid = 
			{
				[339] = 1,
			},
		},
		[290] = 
		{
			x = 26.43, y = 21.20, z = 23.72, Type = 6,
			Tid = 
			{
				[621] = 1,
			},
		},
		[307] = 
		{
			x = -239.45, y = -17.73, z = -162.54, Type = 6,
			Tid = 
			{
				[723] = 1,
			},
		},
		[306] = 
		{
			x = -192.38, y = 0.17, z = 14.34, Type = 6,
			Tid = 
			{
				[724] = 1,
			},
		},
		[305] = 
		{
			x = -230.00, y = -0.92, z = 150.61, Type = 6,
			Tid = 
			{
				[725] = 1,
			},
		},
		[304] = 
		{
			x = 88.00, y = 10.04, z = -100.97, Type = 6,
			Tid = 
			{
				[726] = 1,
			},
		},
		[303] = 
		{
			x = 144.10, y = 12.55, z = -73.29, Type = 6,
			Tid = 
			{
				[727] = 1,
			},
		},
		[308] = 
		{
			x = -239.45, y = -17.73, z = -162.54, Type = 6,
			Tid = 
			{
				[773] = 1,
			},
		},
		[309] = 
		{
			x = -192.38, y = 0.17, z = 14.34, Type = 6,
			Tid = 
			{
				[774] = 1,
			},
		},
		[310] = 
		{
			x = -230.00, y = -0.92, z = 150.61, Type = 6,
			Tid = 
			{
				[775] = 1,
			},
		},
		[311] = 
		{
			x = 88.00, y = 10.04, z = -100.97, Type = 6,
			Tid = 
			{
				[776] = 1,
			},
		},
		[312] = 
		{
			x = 144.10, y = 12.55, z = -73.29, Type = 6,
			Tid = 
			{
				[777] = 1,
			},
		},
		[217] = 
		{
			x = 50.41, y = 21.04, z = 52.57, Type = 6,
			Tid = 
			{
				[869] = 1,
			},
		},
		[218] = 
		{
			x = 61.50, y = 25.77, z = 75.37, Type = 6,
			Tid = 
			{
				[868] = 1,
			},
		},
		[245] = 
		{
			x = 108.71, y = 21.27, z = -22.22, Type = 6,
			Tid = 
			{
				[867] = 2,
			},
		},
		[313] = 
		{
			x = 107.50, y = 20.16, z = -26.64, Type = 6,
			Tid = 
			{
				[867] = 2,
			},
		},
		[314] = 
		{
			x = 106.85, y = 21.87, z = -6.42, Type = 6,
			Tid = 
			{
				[867] = 2,
			},
		},
		[325] = 
		{
			x = -231.47, y = -17.74, z = -156.79, Type = 6,
			Tid = 
			{
				[886] = 1,
			},
		},
		[326] = 
		{
			x = -188.17, y = 0.26, z = -6.04, Type = 6,
			Tid = 
			{
				[873] = 6,
			},
		},
		[330] = 
		{
			x = 110.48, y = 10.07, z = -102.30, Type = 6,
			Tid = 
			{
				[906] = 8,
			},
		},
		[335] = 
		{
			x = 55.24, y = 21.11, z = 10.22, Type = 6,
			Tid = 
			{
				[885] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -249.66, posy = -18.33, posz = -182.20, rotx = 359.73, roty = 338.57, rotz = 359.26 },
		[2] = { posx = 53.88, posy = 26.64, posz = 143.21, rotx = 0.78, roty = 263.93, rotz = 359.89 },
		[3] = { posx = 256.18, posy = -9.91, posz = 26.48, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = 328.91, posy = 30.16, posz = 22.86, rotx = 0.00, roty = 77.26, rotz = 0.00 },
		[5] = { posx = -34.76, posy = 38.34, posz = 52.51, rotx = 0.00, roty = 258.55, rotz = 0.00 },
		[6] = { posx = 3.71, posy = 21.04, posz = 30.09, rotx = 0.00, roty = 92.77, rotz = 0.00 },
		[7] = { posx = 176.50, posy = 39.78, posz = 2.81, rotx = 0.00, roty = 270.47, rotz = 0.00 },
		[8] = { posx = 51.13, posy = 26.02, posz = 96.54, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[9] = { posx = 319.00, posy = 48.44, posz = -89.00, rotx = 0.00, roty = 320.48, rotz = 0.00 },
		[10] = { posx = -364.00, posy = -0.08, posz = 15.00, rotx = 0.00, roty = 36.62, rotz = 0.00 },
		[11] = { posx = -195.80, posy = -1.37, posz = 89.39, rotx = 0.00, roty = 313.06, rotz = 0.00 },
		[12] = { posx = -365.80, posy = 6.50, posz = -151.50, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[13] = { posx = -335.50, posy = 3.00, posz = -145.90, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[14] = { posx = -378.40, posy = 3.00, posz = 30.90, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[15] = { posx = -349.30, posy = 3.00, posz = 22.80, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[16] = { posx = -213.50, posy = 3.00, posz = 129.80, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[17] = { posx = -45.60, posy = 3.00, posz = -117.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[18] = { posx = -67.60, posy = 48.60, posz = 70.00, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[19] = { posx = 45.60, posy = 23.80, posz = 63.40, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[20] = { posx = 96.00, posy = 26.30, posz = -13.00, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[21] = { posx = 206.10, posy = 34.20, posz = -134.20, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[22] = { posx = 335.10, posy = 31.40, posz = 13.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[23] = { posx = 153.60, posy = 48.60, posz = 23.70, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[24] = { posx = 50.60, posy = 18.10, posz = -105.00, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[26] = { posx = 21.40, posy = 21.04, posz = 37.03, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[27] = { posx = -38.80, posy = 5.60, posz = -114.90, rotx = 0.00, roty = 354.70, rotz = 0.00 },
		[28] = { posx = -59.10, posy = 46.20, posz = 66.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[30] = { posx = -206.44, posy = -1.28, posz = 106.05, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[31] = { posx = -187.18, posy = -4.18, posz = -66.60, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[32] = { posx = -219.53, posy = 0.19, posz = -1.55, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[33] = { posx = -201.00, posy = -6.10, posz = -135.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[34] = { posx = 156.80, posy = 39.73, posz = 14.70, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[35] = { posx = 307.22, posy = 48.81, posz = -83.83, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
