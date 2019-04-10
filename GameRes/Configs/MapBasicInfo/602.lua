local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "不死亲王",
	Length = 800,
	Width = 800,
	NavMeshName = "Dungn03_QXGJ01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD03.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn03_QXGJ01.prefab",
	Monster = 
	{
		[36002] = 
		{
			[1] = { x = -9.00, y = 76.02, z = 86.90, name = "霍加斯亲王", level = 32,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -9.85, y = 76.02, z = 81.61, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = -9.00, y = 76.02, z = 86.90, Type = 1,
			Tid = 
			{
				[36002] = 1,
			},
		},
		[1] = 
		{
			x = -29.18, y = 75.96, z = 48.34, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = 11.21, y = 75.96, z = 48.50, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = -7.77, y = 75.96, z = 50.29, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -9.00, posy = 63.48, posz = 10.00, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo