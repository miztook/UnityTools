local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·卡拉斯试炼者·噩梦",
	TextDisplayName = "卡拉斯试炼者·噩梦",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn05_ElfArch.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/ELF_REMAINS",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD05.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn05_ElfArch.prefab",
	PKMode= 1,
	Monster = 
	{
		[24401] = 
		{
			[1] = { x = 36.61, y = 55.24, z = -99.98, name = "卡拉斯试炼者", level = 60,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[282] = { x = 37.85, y = 55.30, z = -79.42, name = "出场区域", worldId = 0, BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[2] = 
		{
			x = 36.61, y = 55.24, z = -99.98, Type = 1,
			Tid = 
			{
				[24401] = 1,
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
			x = 26.17, y = 40.55, z = -22.00, Type = 4,
			Tid = 
			{
				[22] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 36.61, posy = 55.30, posz = -81.42, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[2] = { posx = 38.44, posy = 55.38, posz = -81.05, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[3] = { posx = 34.85, posy = 55.30, posz = -80.96, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[4] = { posx = 40.36, posy = 55.30, posz = -80.96, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[5] = { posx = 32.85, posy = 55.30, posz = -80.91, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[6] = { posx = 41.60, posy = 55.38, posz = -86.85, rotx = 0.00, roty = 349.92, rotz = 0.00 },
	},

}
return MapInfo