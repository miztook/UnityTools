local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "自然之子",
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
		[36011] = 
		{
			[1] = { x = 0.00, y = 5.00, z = 35.00, name = "卡玛伊酋长", level = 40,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -0.02, y = 39.53, z = 19.16, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = 0.00, y = 5.00, z = 35.00, Type = 1,
			Tid = 
			{
				[36011] = 1,
			},
		},
		[1] = 
		{
			x = 0.45, y = 5.67, z = -1.00, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = -9.50, y = 5.67, z = 43.00, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = 9.40, y = 5.67, z = 43.00, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 0.00, posy = 5.90, posz = -55.00, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo