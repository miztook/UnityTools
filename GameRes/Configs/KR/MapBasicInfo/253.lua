local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·卡拉斯试炼者·普通",
	TextDisplayName = "카라스 수련자 - 보통",
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
		[24400] = 
		{
			[1] = { x = 36.61, y = 55.24, z = -100.78, name = "카라스 수련자", level = 52,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[282] = { x = 37.85, y = 55.30, z = -79.42, name = "出场区域", worldId = 0, BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[2] = 
		{
			x = 36.61, y = 55.24, z = -100.78, Type = 1,
			Tid = 
			{
				[24400] = 1,
			},
		},
		[1] = 
		{
			x = 38.50, y = 55.24, z = -75.84, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[3] = 
		{
			x = 26.33, y = 40.55, z = -21.46, Type = 4,
			Tid = 
			{
				[22] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 36.61, posy = 55.30, posz = -81.16, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[2] = { posx = 38.10, posy = 55.22, posz = -80.34, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[3] = { posx = 35.21, posy = 55.30, posz = -80.20, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[4] = { posx = 39.92, posy = 55.30, posz = -80.82, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[5] = { posx = 33.37, posy = 55.30, posz = -80.59, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[6] = { posx = 41.60, posy = 55.38, posz = -86.85, rotx = 0.00, roty = 349.92, rotz = 0.00 },
	},

}
return MapInfo
