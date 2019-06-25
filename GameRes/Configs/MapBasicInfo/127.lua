local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "毒蛇竞技场",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Viper_Arena",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	Monster = 
	{
		[10078] = 
		{
			[1] = { x = 188.80, y = 20.92, z = -173.88, name = "獠牙剑齿虎", level = 10, SortID = 15 },
		},
		[10079] = 
		{
			[1] = { x = 192.82, y = 21.10, z = -165.65, name = "暴熊", level = 12, SortID = 16 },
		},
		[10080] = 
		{
			[1] = { x = 192.96, y = 20.98, z = -166.03, name = "暗影豹狮", level = 12, SortID = 17 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[1] = 
		{
			[131] = { x = 169.08, y = 27.69, z = -197.19, xA = 183.17, yA = 20.90, zA = -180.27, name = "进入传送区域", worldId = 127, PkMode = 0 },
		},
		[2] = 
		{
			[85] = { x = 172.31, y = 43.92, z = -144.51, name = "", worldId = 0, PkMode = 0 },
			[130] = { x = 190.17, y = 20.85, z = -174.95, name = "竞技场内环", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[15] = 
		{
			x = 188.80, y = 20.92, z = -173.88, Type = 1,
			Tid = 
			{
				[10078] = 5,
			},
		},
		[16] = 
		{
			x = 192.82, y = 21.10, z = -165.65, Type = 1,
			Tid = 
			{
				[10079] = 3,
			},
		},
		[17] = 
		{
			x = 192.96, y = 20.98, z = -166.03, Type = 1,
			Tid = 
			{
				[10080] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 181.68, posy = 20.85, posz = -181.26, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[2] = { posx = 183.17, posy = 20.90, posz = -180.27, rotx = 0.00, roty = 55.86, rotz = 0.00 },
	},

}
return MapInfo