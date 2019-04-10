local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "생명의 꽃 - 악몽",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn05_ElfArch.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/ELF_REMAINS",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD05.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn05_ElfArch.prefab",
	Monster = 
	{
		[24110] = 
		{
			[1] = { x = -17.29, y = 82.35, z = -108.42, name = "엘프 검사", level = 50 },
			[2] = { x = -26.68, y = 80.01, z = -79.64, name = "엘프 검사", level = 50 },
			[3] = { x = -7.15, y = 80.01, z = -81.04, name = "엘프 검사", level = 50 },
			[4] = { x = -17.23, y = 80.01, z = -90.59, name = "엘프 검사", level = 50 },
		},
		[24111] = 
		{
			[1] = { x = -26.68, y = 80.01, z = -79.64, name = "엘프 궁수", level = 50 },
			[2] = { x = -7.15, y = 80.01, z = -81.04, name = "엘프 궁수", level = 50 },
			[3] = { x = -17.23, y = 80.01, z = -90.59, name = "엘프 궁수", level = 50 },
		},
		[24112] = 
		{
			[1] = { x = -51.84, y = 75.35, z = -71.84, name = "사막 행인", level = 50 },
			[2] = { x = -54.81, y = 75.35, z = -80.90, name = "사막 행인", level = 50 },
			[3] = { x = -52.12, y = 76.92, z = -39.38, name = "사막 행인", level = 50 },
			[4] = { x = -51.97, y = 76.92, z = -47.98, name = "사막 행인", level = 50 },
			[5] = { x = -50.09, y = 71.87, z = -2.49, name = "사막 행인", level = 50 },
			[6] = { x = -13.71, y = 62.76, z = 5.25, name = "사막 행인", level = 50 },
		},
		[24203] = 
		{
			[1] = { x = -52.12, y = 76.92, z = -39.38, name = "사막 행인 정예", level = 50 },
		},
		[24113] = 
		{
			[1] = { x = -51.97, y = 76.92, z = -47.98, name = "감염자", level = 50 },
			[2] = { x = -50.09, y = 71.87, z = -2.49, name = "감염자", level = 50 },
			[3] = { x = -13.71, y = 62.76, z = 5.25, name = "감염자", level = 50 },
		},
		[24114] = 
		{
			[1] = { x = -7.51, y = 62.76, z = 14.25, name = "바람의 사제", level = 50 },
			[2] = { x = 31.18, y = 55.31, z = 9.77, name = "바람의 사제", level = 50 },
			[3] = { x = 26.10, y = 55.31, z = 14.13, name = "바람의 사제", level = 50 },
		},
		[24115] = 
		{
			[1] = { x = -7.51, y = 62.76, z = 14.25, name = "바람의 전사", level = 50 },
			[2] = { x = 26.10, y = 55.31, z = 14.13, name = "바람의 전사", level = 50 },
		},
		[24204] = 
		{
			[1] = { x = 31.18, y = 55.31, z = 9.77, name = "소르나", level = 50 },
		},
		[24310] = 
		{
			[1] = { x = 5.49, y = 40.50, z = -35.71, name = "셀리온", level = 50,IsBoss = true },
		},
		[24302] = 
		{
			[1] = { x = 5.49, y = 40.50, z = -35.71, name = "비틀린 길리두", level = 10 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -17.14, y = 82.60, z = -124.14, name = "目标1区域", worldId = 0, PkMode = 0 },
			[2] = { x = -17.35, y = 81.23, z = -101.80, name = "目标3区域", worldId = 0, PkMode = 0 },
			[3] = { x = -32.83, y = 80.30, z = -81.04, name = "目标5区域", worldId = 0, PkMode = 0 },
			[275] = { x = -51.75, y = 77.00, z = -44.84, name = "触发沙行者精英区", worldId = 0, PkMode = 0 },
			[276] = { x = -50.56, y = 72.10, z = -3.24, name = "目标8_穿过塌陷区域", worldId = 0, PkMode = 0 },
			[277] = { x = -13.00, y = 62.84, z = 10.42, name = "目标区与包围触发", worldId = 0, PkMode = 0 },
			[278] = { x = 19.00, y = 40.55, z = -31.97, name = "目标13_前往生命之花", worldId = 0, PkMode = 0 },
			[281] = { x = 14.15, y = 55.50, z = 13.85, name = "激活对话3", worldId = 0, PkMode = 0 },
			[282] = { x = -20.19, y = 80.13, z = -81.86, name = "演出怪物移除免死区", worldId = 0, PkMode = 0 },
			[331] = { x = 12.21, y = 40.50, z = -29.41, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
		},
	},
	Mine = 
	{
		[384] = 
		{
			[1] = { x = -52.41, y = 76.92, z = -44.40 },
			[2] = { x = -52.41, y = 71.88, z = -2.48 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = -17.29, y = 82.35, z = -108.42, Type = 1,
			Tid = 
			{
				[24110] = 2,
			},
		},
		[2] = 
		{
			x = -26.68, y = 80.01, z = -79.64, Type = 1,
			Tid = 
			{
				[24110] = 2,
				[24111] = 1,
			},
		},
		[3] = 
		{
			x = -51.84, y = 75.35, z = -71.84, Type = 1,
			Tid = 
			{
				[24112] = 1,
			},
		},
		[4] = 
		{
			x = -54.81, y = 75.35, z = -80.90, Type = 1,
			Tid = 
			{
				[24112] = 2,
			},
		},
		[5] = 
		{
			x = -52.12, y = 76.92, z = -39.38, Type = 1,
			Tid = 
			{
				[24203] = 1,
				[24112] = 2,
			},
		},
		[6] = 
		{
			x = -51.97, y = 76.92, z = -47.98, Type = 1,
			Tid = 
			{
				[24112] = 1,
				[24113] = 2,
			},
		},
		[7] = 
		{
			x = -50.09, y = 71.87, z = -2.49, Type = 1,
			Tid = 
			{
				[24113] = 3,
				[24112] = 2,
			},
		},
		[8] = 
		{
			x = -13.71, y = 62.76, z = 5.25, Type = 1,
			Tid = 
			{
				[24112] = 2,
				[24113] = 1,
			},
		},
		[9] = 
		{
			x = -7.51, y = 62.76, z = 14.25, Type = 1,
			Tid = 
			{
				[24114] = 1,
				[24115] = 2,
			},
		},
		[10] = 
		{
			x = 31.18, y = 55.31, z = 9.77, Type = 1,
			Tid = 
			{
				[24204] = 1,
				[24114] = 2,
			},
		},
		[21] = 
		{
			x = -7.15, y = 80.01, z = -81.04, Type = 1,
			Tid = 
			{
				[24110] = 1,
				[24111] = 2,
			},
		},
		[22] = 
		{
			x = -17.23, y = 80.01, z = -90.59, Type = 1,
			Tid = 
			{
				[24110] = 1,
				[24111] = 2,
			},
		},
		[29] = 
		{
			x = 26.10, y = 55.31, z = 14.13, Type = 1,
			Tid = 
			{
				[24114] = 1,
				[24115] = 2,
			},
		},
		[30] = 
		{
			x = 5.49, y = 40.50, z = -35.71, Type = 1,
			Tid = 
			{
				[24310] = 1,
			},
		},
		[31] = 
		{
			x = 5.49, y = 40.50, z = -35.71, Type = 1,
			Tid = 
			{
				[24302] = 1,
			},
		},
		[11] = 
		{
			x = -17.51, y = 82.35, z = -105.01, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[12] = 
		{
			x = -31.86, y = 80.20, z = -80.94, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[13] = 
		{
			x = -52.07, y = 75.35, z = -67.02, Type = 4,
			Tid = 
			{
				[23] = 0,
			},
		},
		[14] = 
		{
			x = -51.84, y = 76.92, z = -28.06, Type = 4,
			Tid = 
			{
				[22] = 0,
			},
		},
		[15] = 
		{
			x = -40.69, y = 72.18, z = 1.19, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[16] = 
		{
			x = -1.20, y = 62.95, z = 13.73, Type = 4,
			Tid = 
			{
				[23] = 0,
			},
		},
		[17] = 
		{
			x = -20.92, y = 62.95, z = 1.17, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[18] = 
		{
			x = 31.32, y = 55.31, z = 1.21, Type = 4,
			Tid = 
			{
				[9] = 0,
			},
		},
		[19] = 
		{
			x = 32.78, y = 40.45, z = -57.73, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[20] = 
		{
			x = 26.40, y = 40.55, z = -21.47, Type = 4,
			Tid = 
			{
				[23] = 0,
			},
		},
		[25] = 
		{
			x = -52.41, y = 76.92, z = -44.40, Type = 6,
			Tid = 
			{
				[384] = 3,
			},
		},
		[26] = 
		{
			x = -52.41, y = 71.88, z = -2.48, Type = 6,
			Tid = 
			{
				[384] = 3,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 5.42, posy = 40.49, posz = -34.09, rotx = 0.00, roty = 51.28, rotz = 0.00 },
		[2] = { posx = 24.71, posy = 40.50, posz = -36.64, rotx = 0.00, roty = 258.41, rotz = 0.00 },
		[3] = { posx = 25.26, posy = 40.50, posz = -38.47, rotx = 0.00, roty = 258.41, rotz = 0.00 },
		[4] = { posx = 25.63, posy = 40.50, posz = -35.12, rotx = 0.00, roty = 258.41, rotz = 0.00 },
		[5] = { posx = 24.46, posy = 40.50, posz = -40.00, rotx = 0.00, roty = 258.41, rotz = 0.00 },
		[6] = { posx = 24.89, posy = 40.50, posz = -33.49, rotx = 0.00, roty = 258.41, rotz = 0.00 },
	},

}
return MapInfo
