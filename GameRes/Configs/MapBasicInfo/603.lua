local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "狡诈的窟拉首领",
	Length = 800,
	Width = 800,
	NavMeshName = "Dungn03_QXGJ01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD03.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn03_QXGJ01.prefab",
	PKMode= 1,
	Monster = 
	{
		[36003] = 
		{
			[1] = { x = -9.00, y = 76.02, z = 85.44, name = "弗斯特比艾波斯", level = 36,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -8.85, y = 76.00, z = 75.47, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = -9.00, y = 76.02, z = 85.44, Type = 1,
			Tid = 
			{
				[36003] = 1,
			},
		},
		[1] = 
		{
			x = -29.23, y = 75.96, z = 48.71, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = 10.74, y = 75.96, z = 48.72, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = -9.70, y = 75.96, z = 50.60, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -9.00, posy = 63.09, posz = 10.00, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo