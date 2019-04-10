local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "에세니아 서부",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part2.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-2.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part2.prefab",
	Monster = 
	{
		[13146] = 
		{
			[1] = { x = -68.18, y = 78.13, z = -99.31, name = "타락한 사마엘", level = 45, SortID = 1, DropItemIds = " " },
		},
		[13145] = 
		{
			[1] = { x = -71.30, y = 77.51, z = -87.30, name = "저주의 영혼", level = 45, SortID = 10, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[3323] = 
		{
			[1] = { x = -68.43, y = 78.13, z = -99.54, name = "악령에 씌인 사마엘", SortID = 7, FunctionName = " " },
		},
		[3324] = 
		{
			[1] = { x = -72.46, y = 78.13, z = -97.44, name = "엘리사 쿠벨", SortID = 8, FunctionName = " " },
		},
		[3325] = 
		{
			[1] = { x = -76.49, y = 77.86, z = -96.46, name = "레인저 병사", SortID = 9, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[520] = { x = 176.69, y = 1.00, z = -194.40, name = "背景音乐-绝境要塞", worldId = 0, PkMode = 0 },
			[521] = { x = 116.27, y = 42.82, z = -28.21, name = "背景音乐-蜘蛛洞", worldId = 0, PkMode = 0 },
			[522] = { x = -113.81, y = 1.00, z = 108.33, name = "背景音乐-风之壁垒", worldId = 0, PkMode = 0 },
			[523] = { x = -151.63, y = 1.00, z = -126.86, name = "背景音乐-森林地带", worldId = 0, PkMode = 0 },
			[453] = { x = 8.65, y = 52.21, z = -144.37, name = "风精灵士兵殿后刷出", worldId = 0, PkMode = 0 },
			[490] = { x = 21.58, y = 53.36, z = -108.40, name = "断桥抵达", worldId = 0, PkMode = 0 },
			[524] = { x = 34.60, y = 54.80, z = -99.16, name = "186离开区域", worldId = 0, PkMode = 0 },
			[525] = { x = -54.64, y = 78.13, z = -107.93, name = "洛克的诅咒-魔化沙摩尔离开相位区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[836] = 
		{
			[1] = { x = -66.47, y = 78.06, z = -95.70 },
			[2] = { x = -67.49, y = 78.06, z = -98.46 },
		},
		[837] = 
		{
			[1] = { x = -67.49, y = 78.14, z = -80.48 },
			[2] = { x = -73.19, y = 78.03, z = -112.99 },
			[3] = { x = -50.24, y = 79.48, z = -103.30 },
		},
		[838] = 
		{
			[1] = { x = -70.45, y = 77.55, z = -87.23 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = -68.18, y = 78.13, z = -99.31, Type = 1,
			Tid = 
			{
				[13146] = 1,
			},
		},
		[10] = 
		{
			x = -71.30, y = 77.51, z = -87.30, Type = 1,
			Tid = 
			{
				[13145] = 3,
			},
		},
		[7] = 
		{
			x = -68.43, y = 78.13, z = -99.54, Type = 2,
			Tid = 
			{
				[3323] = 1,
			},
		},
		[8] = 
		{
			x = -72.46, y = 78.13, z = -97.44, Type = 2,
			Tid = 
			{
				[3324] = 1,
			},
		},
		[9] = 
		{
			x = -76.49, y = 77.86, z = -96.46, Type = 2,
			Tid = 
			{
				[3325] = 3,
			},
		},
		[2] = 
		{
			x = -66.47, y = 78.06, z = -95.70, Type = 6,
			Tid = 
			{
				[836] = 1,
			},
		},
		[3] = 
		{
			x = -67.49, y = 78.06, z = -98.46, Type = 6,
			Tid = 
			{
				[836] = 1,
			},
		},
		[4] = 
		{
			x = -67.49, y = 78.14, z = -80.48, Type = 6,
			Tid = 
			{
				[837] = 1,
			},
		},
		[5] = 
		{
			x = -73.19, y = 78.03, z = -112.99, Type = 6,
			Tid = 
			{
				[837] = 1,
			},
		},
		[6] = 
		{
			x = -50.24, y = 79.48, z = -103.30, Type = 6,
			Tid = 
			{
				[837] = 1,
			},
		},
		[11] = 
		{
			x = -70.45, y = 77.55, z = -87.23, Type = 6,
			Tid = 
			{
				[838] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 249.42, posy = 36.16, posz = -185.28, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[2] = { posx = 5.60, posy = 125.00, posz = 225.10, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[7] = { posx = 8.30, posy = 51.81, posz = -81.00, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[8] = { posx = -24.70, posy = 84.90, posz = -108.20, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[9] = { posx = -108.20, posy = 75.00, posz = -57.40, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[10] = { posx = -180.10, posy = 44.90, posz = -115.90, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[11] = { posx = -141.10, posy = 30.30, posz = -162.00, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[12] = { posx = 126.20, posy = 43.20, posz = -6.00, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[13] = { posx = -14.20, posy = 54.40, posz = -56.30, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[14] = { posx = -91.10, posy = 67.30, posz = -11.40, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[15] = { posx = -30.00, posy = 81.00, posz = 36.50, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[16] = { posx = -16.50, posy = 97.50, posz = 123.70, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[17] = { posx = -28.90, posy = 97.80, posz = 175.10, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[18] = { posx = -242.00, posy = 97.80, posz = 50.00, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[19] = { posx = -149.40, posy = 87.00, posz = 66.20, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[20] = { posx = -172.80, posy = 135.30, posz = 223.70, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[21] = { posx = -187.60, posy = 60.00, posz = -69.60, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[22] = { posx = -172.30, posy = 28.60, posz = -176.80, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[23] = { posx = -236.90, posy = 31.00, posz = -210.40, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[24] = { posx = -68.90, posy = 80.90, posz = -101.50, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[25] = { posx = -126.30, posy = 133.30, posz = 196.10, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[26] = { posx = -37.20, posy = 123.20, posz = 242.10, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[27] = { posx = -139.30, posy = 133.90, posz = 225.20, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[28] = { posx = 24.30, posy = 122.40, posz = 225.30, rotx = 0.00, roty = 269.67, rotz = 0.00 },
		[29] = { posx = 17.65, posy = 52.44, posz = -103.02, rotx = 0.00, roty = 350.00, rotz = 0.00 },
	},

}
return MapInfo
