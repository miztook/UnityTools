local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "캐리언",
	Length = 800,
	Width = 800,
	NavMeshName = "Dungn04_Zuras01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn04_Zuras01.prefab",
	Monster = 
	{
		[36013] = 
		{
			[1] = { x = 0.00, y = 5.67, z = 35.00, name = "캐리언", level = 48,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = 0.18, y = 39.53, z = 18.74, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = 0.00, y = 5.67, z = 35.00, Type = 1,
			Tid = 
			{
				[36013] = 1,
			},
		},
		[1] = 
		{
			x = -0.20, y = 5.67, z = -0.98, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = 8.70, y = 5.67, z = 42.60, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = -9.30, y = 5.67, z = 42.60, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 0.00, posy = 6.23, posz = -55.00, rotx = 0.00, roty = 90.00, rotz = 0.00 },
	},

}
return MapInfo
