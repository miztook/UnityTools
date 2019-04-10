local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "生命之花·普通",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn05_ElfArch.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/ELF_REMAINS",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD05.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn05_ElfArch.prefab",
	Monster = 
	{
		[24100] = 
		{
			[1] = { x = -14.56, y = 82.35, z = -108.42, name = "精灵剑士", level = 50 },
			[2] = { x = -20.29, y = 82.35, z = -108.42, name = "精灵剑士", level = 50 },
			[3] = { x = -7.89, y = 80.01, z = -81.09, name = "精灵剑士", level = 50 },
			[4] = { x = -26.52, y = 80.01, z = -80.73, name = "精灵剑士", level = 50 },
			[5] = { x = -17.23, y = 80.01, z = -89.70, name = "精灵剑士", level = 50 },
		},
		[24101] = 
		{
			[1] = { x = -7.89, y = 80.01, z = -81.09, name = "精灵弓手", level = 50 },
			[2] = { x = -26.52, y = 80.01, z = -80.73, name = "精灵弓手", level = 50 },
			[3] = { x = -17.23, y = 80.01, z = -89.70, name = "精灵弓手", level = 50 },
		},
		[24102] = 
		{
			[1] = { x = -51.97, y = 75.35, z = -72.91, name = "沙行者", level = 50 },
			[2] = { x = -51.97, y = 76.92, z = -47.98, name = "沙行者", level = 50 },
			[3] = { x = -50.09, y = 72.00, z = -2.56, name = "沙行者", level = 50 },
			[4] = { x = -13.04, y = 62.76, z = 3.99, name = "沙行者", level = 50 },
		},
		[24201] = 
		{
			[1] = { x = -52.12, y = 76.92, z = -36.06, name = "沙行者精英", level = 50 },
		},
		[24103] = 
		{
			[1] = { x = -51.97, y = 76.92, z = -47.98, name = "污染者", level = 50 },
			[2] = { x = -50.09, y = 72.00, z = -2.56, name = "污染者", level = 50 },
			[3] = { x = -13.04, y = 62.76, z = 3.99, name = "污染者", level = 50 },
		},
		[24104] = 
		{
			[1] = { x = -7.51, y = 62.76, z = 14.25, name = "风之祭司", level = 50 },
			[2] = { x = 31.18, y = 55.31, z = 14.30, name = "风之祭司", level = 50 },
		},
		[24105] = 
		{
			[1] = { x = -7.51, y = 62.76, z = 14.25, name = "风之武者", level = 50 },
			[2] = { x = 31.18, y = 55.31, z = 14.30, name = "风之武者", level = 50 },
		},
		[24202] = 
		{
			[1] = { x = 30.93, y = 55.31, z = 14.13, name = "索尔纳", level = 50 },
		},
		[24300] = 
		{
			[1] = { x = 5.49, y = 40.50, z = -35.71, name = "赛利恩", level = 50,IsBoss = true },
		},
		[24302] = 
		{
			[1] = { x = 5.49, y = 40.50, z = -35.71, name = "扭曲树精", level = 10 },
		},
	},
	Npc = 
	{
		[813] = 
		{
			[1] = { x = -51.94, y = 75.35, z = -81.46, name = "精灵剑士" },
		},
		[814] = 
		{
			[1] = { x = -51.94, y = 75.35, z = -81.46, name = "精灵弓手" },
		},
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -17.13, y = 82.60, z = -122.75, name = "目标1区域", worldId = 0, PkMode = 0 },
			[2] = { x = -17.35, y = 81.23, z = -101.80, name = "目标3区域", worldId = 0, PkMode = 0 },
			[3] = { x = -32.83, y = 80.30, z = -81.04, name = "目标5区域", worldId = 0, PkMode = 0 },
			[275] = { x = -51.81, y = 77.00, z = -51.01, name = "触发沙行者精英区", worldId = 0, PkMode = 0 },
			[276] = { x = -50.38, y = 72.10, z = 1.50, name = "目标8_穿过塌陷区域", worldId = 0, PkMode = 0 },
			[277] = { x = -13.00, y = 62.84, z = 10.42, name = "目标区与包围触发", worldId = 0, PkMode = 0 },
			[278] = { x = 19.00, y = 40.55, z = -31.97, name = "目标13_前往生命之花", worldId = 0, PkMode = 0 },
			[281] = { x = 14.15, y = 55.50, z = 13.85, name = "激活对话3", worldId = 0, PkMode = 0 },
			[282] = { x = -20.19, y = 80.13, z = -81.86, name = "演出怪物移除免死区", worldId = 0, PkMode = 0 },
			[330] = { x = 13.33, y = 40.50, z = -31.89, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
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
			x = -14.56, y = 82.35, z = -108.42, Type = 1,
			Tid = 
			{
				[24100] = 1,
			},
		},
		[32] = 
		{
			x = -20.29, y = 82.35, z = -108.42, Type = 1,
			Tid = 
			{
				[24100] = 1,
			},
		},
		[21] = 
		{
			x = -7.89, y = 80.01, z = -81.09, Type = 1,
			Tid = 
			{
				[24100] = 1,
				[24101] = 1,
			},
		},
		[2] = 
		{
			x = -26.52, y = 80.01, z = -80.73, Type = 1,
			Tid = 
			{
				[24100] = 2,
				[24101] = 1,
			},
		},
		[22] = 
		{
			x = -17.23, y = 80.01, z = -89.70, Type = 1,
			Tid = 
			{
				[24100] = 1,
				[24101] = 2,
			},
		},
		[3] = 
		{
			x = -51.97, y = 75.35, z = -72.91, Type = 1,
			Tid = 
			{
				[24102] = 3,
			},
		},
		[5] = 
		{
			x = -52.12, y = 76.92, z = -36.06, Type = 1,
			Tid = 
			{
				[24201] = 1,
			},
		},
		[6] = 
		{
			x = -51.97, y = 76.92, z = -47.98, Type = 1,
			Tid = 
			{
				[24102] = 3,
				[24103] = 2,
			},
		},
		[7] = 
		{
			x = -50.09, y = 72.00, z = -2.56, Type = 1,
			Tid = 
			{
				[24103] = 3,
				[24102] = 2,
			},
		},
		[8] = 
		{
			x = -13.04, y = 62.76, z = 3.99, Type = 1,
			Tid = 
			{
				[24102] = 2,
				[24103] = 1,
			},
		},
		[9] = 
		{
			x = -7.51, y = 62.76, z = 14.25, Type = 1,
			Tid = 
			{
				[24104] = 1,
				[24105] = 2,
			},
		},
		[10] = 
		{
			x = 31.18, y = 55.31, z = 14.30, Type = 1,
			Tid = 
			{
				[24105] = 2,
				[24104] = 2,
			},
		},
		[29] = 
		{
			x = 30.93, y = 55.31, z = 14.13, Type = 1,
			Tid = 
			{
				[24202] = 1,
			},
		},
		[30] = 
		{
			x = 5.49, y = 40.50, z = -35.71, Type = 1,
			Tid = 
			{
				[24300] = 1,
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
		[23] = 
		{
			x = -51.94, y = 75.35, z = -81.46, Type = 2,
			Tid = 
			{
				[813] = 2,
				[814] = 1,
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
		[2] = { posx = 21.46, posy = 40.50, posz = -35.94, rotx = 0.00, roty = 270.00, rotz = 0.00 },
		[3] = { posx = 22.25, posy = 40.50, posz = -34.28, rotx = 0.00, roty = 270.00, rotz = 0.00 },
		[4] = { posx = 22.09, posy = 40.50, posz = -37.68, rotx = 0.00, roty = 270.00, rotz = 0.00 },
		[5] = { posx = 21.66, posy = 40.50, posz = -32.67, rotx = 0.00, roty = 270.00, rotz = 0.00 },
		[6] = { posx = 21.52, posy = 40.50, posz = -39.43, rotx = 0.00, roty = 270.00, rotz = 0.00 },
	},

}
return MapInfo