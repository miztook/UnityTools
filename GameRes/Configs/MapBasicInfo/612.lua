local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "无拘之风",
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
		[36012] = 
		{
			[1] = { x = 0.00, y = 5.67, z = 35.00, name = "风之精灵首领", level = 44,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -0.32, y = 39.53, z = 17.95, name = "镜头调整区域", worldId = 0, PkMode = 1 },
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
				[36012] = 1,
			},
		},
		[1] = 
		{
			x = 0.42, y = 5.67, z = -0.67, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = -8.60, y = 5.67, z = 42.80, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[3] = 
		{
			x = 8.80, y = 5.67, z = 42.80, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 255.70, posy = 39.22, posz = 198.00, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[2] = { posx = 0.00, posy = 6.05, posz = -55.00, rotx = 0.00, roty = 90.00, rotz = 0.00 },
	},

}
return MapInfo