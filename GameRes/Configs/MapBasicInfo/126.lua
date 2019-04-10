local MapInfo = 
{
	MapType = 4,
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
		[10051] = 
		{
			[1] = { x = 191.99, y = 20.92, z = -169.80, name = "沙摩尔", level = 14, SortID = 17 },
		},
		[10015] = 
		{
			[1] = { x = 191.83, y = 20.93, z = -170.08, name = "铁胃卡瓦库", level = 14, SortID = 16 },
		},
		[10147] = 
		{
			[1] = { x = 188.37, y = 20.90, z = -170.25, name = "巴巴霍卡人", level = 14, SortID = 23 },
		},
		[10148] = 
		{
			[1] = { x = 193.95, y = 20.93, z = -172.37, name = "槌子霍卡人", level = 14, SortID = 15 },
		},
		[10149] = 
		{
			[1] = { x = 190.29, y = 20.93, z = -176.51, name = "火药桶", level = 14, SortID = 12 },
		},
		[10150] = 
		{
			[1] = { x = 190.29, y = 20.93, z = -176.81, name = "恢复", level = 50, SortID = 32 },
		},
		[10151] = 
		{
			[1] = { x = 190.29, y = 20.93, z = -176.65, name = "攻击", level = 50, SortID = 33 },
		},
		[10188] = 
		{
			[1] = { x = 190.23, y = 20.93, z = -175.16, name = "", level = 6, SortID = 1 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[82] = { x = 200.17, y = 27.63, z = -208.92, name = "奴隶区", worldId = 0, PkMode = 0 },
			[83] = { x = 216.72, y = 27.63, z = -152.72, name = "军事区", worldId = 0, PkMode = 0 },
			[84] = { x = 147.62, y = 24.12, z = -132.52, name = "竞技场外", worldId = 0, PkMode = 0 },
			[85] = { x = 172.31, y = 43.92, z = -144.51, name = "", worldId = 0, PkMode = 0 },
			[130] = { x = 190.17, y = 20.85, z = -174.95, name = "竞技场内环", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[17] = 
		{
			x = 191.99, y = 20.92, z = -169.80, Type = 1,
			Tid = 
			{
				[10051] = 1,
			},
		},
		[16] = 
		{
			x = 191.83, y = 20.93, z = -170.08, Type = 1,
			Tid = 
			{
				[10015] = 1,
			},
		},
		[23] = 
		{
			x = 188.37, y = 20.90, z = -170.25, Type = 1,
			Tid = 
			{
				[10147] = 1,
			},
		},
		[15] = 
		{
			x = 193.95, y = 20.93, z = -172.37, Type = 1,
			Tid = 
			{
				[10148] = 1,
			},
		},
		[12] = 
		{
			x = 190.29, y = 20.93, z = -176.51, Type = 1,
			Tid = 
			{
				[10149] = 6,
			},
		},
		[32] = 
		{
			x = 190.29, y = 20.93, z = -176.81, Type = 1,
			Tid = 
			{
				[10150] = 2,
			},
		},
		[33] = 
		{
			x = 190.29, y = 20.93, z = -176.65, Type = 1,
			Tid = 
			{
				[10151] = 2,
			},
		},
		[1] = 
		{
			x = 190.23, y = 20.93, z = -175.16, Type = 1,
			Tid = 
			{
				[10188] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 188.57, posy = 20.85, posz = -180.41, rotx = 0.00, roty = 19.75, rotz = 0.00 },
		[2] = { posx = 166.70, posy = 27.64, posz = -197.58, rotx = 0.00, roty = 127.02, rotz = 0.00 },
	},

}
return MapInfo