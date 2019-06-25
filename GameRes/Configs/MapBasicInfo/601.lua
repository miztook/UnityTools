local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "野蛮酋长",
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
		[36001] = 
		{
			[1] = { x = -9.01, y = 76.02, z = 84.54, name = "普里昂酋长", level = 28,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -8.72, y = 75.42, z = 72.39, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = -9.01, y = 76.02, z = 84.54, Type = 1,
			Tid = 
			{
				[36001] = 1,
			},
		},
		[1] = 
		{
			x = -28.99, y = 75.96, z = 48.52, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = 10.93, y = 75.96, z = 48.70, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = -10.90, y = 75.96, z = 50.50, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -9.01, posy = 63.34, posz = 10.00, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo
