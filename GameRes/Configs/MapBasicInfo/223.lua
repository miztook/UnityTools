local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·奇利恩的仆从·普通",
	TextDisplayName = "奇利恩的仆从·普通",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn02_Cave01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/BORN_CAVE",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD02.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn02_Cave01.prefab",
	Monster = 
	{
		[21400] = 
		{
			[1] = { x = -100.74, y = 43.68, z = 99.85, name = "奇利恩的仆从", level = 35,IsBoss = true },
		},
	},
	Npc = 
	{
		[12000] = 
		{
			[1] = { x = -99.94, y = 43.68, z = 96.85, name = "卡斯塔尼克人" },
		},
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -95.41, y = 45.49, z = 99.99, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -100.74, y = 43.68, z = 99.85, Type = 1,
			Tid = 
			{
				[21400] = 1,
			},
		},
		[3] = 
		{
			x = -99.94, y = 43.68, z = 96.85, Type = 2,
			Tid = 
			{
				[12000] = 5,
			},
		},
		[2] = 
		{
			x = -113.39, y = 43.83, z = 106.18, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -103.95, posy = 43.62, posz = 95.56, rotx = 0.00, roty = 103.20, rotz = 0.00 },
		[2] = { posx = -110.16, posy = 43.50, posz = 104.71, rotx = 0.00, roty = 144.80, rotz = 0.00 },
		[3] = { posx = -109.81, posy = 43.81, posz = 106.14, rotx = 0.00, roty = 144.80, rotz = 0.00 },
		[4] = { posx = -111.15, posy = 43.81, posz = 103.71, rotx = 0.00, roty = 144.80, rotz = 0.00 },
		[5] = { posx = -109.22, posy = 43.81, posz = 107.51, rotx = 0.00, roty = 144.80, rotz = 0.00 },
		[6] = { posx = -111.96, posy = 43.81, posz = 102.52, rotx = 0.00, roty = 144.80, rotz = 0.00 },
	},

}
return MapInfo