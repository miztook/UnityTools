local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·巴哈勒试炼者·普通",
	TextDisplayName = "바하르 수련자 - 보통",
	Length = 128,
	Width = 128,
	NavMeshName = "Dungn01_Rins01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/BAHAR_REMAINS",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD01.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn01_Rins01.prefab",
	Monster = 
	{
		[20400] = 
		{
			[1] = { x = -3.16, y = 54.21, z = -0.91, name = "바하르 수련자", level = 32,IsBoss = true },
		},
		[20401] = 
		{
			[1] = { x = -3.33, y = 54.23, z = -1.59, name = "바하르 수련자", level = 32 },
			[2] = { x = -3.26, y = 54.23, z = -3.11, name = "바하르 수련자", level = 32 },
			[3] = { x = -3.26, y = 54.23, z = -3.11, name = "바하르 수련자", level = 32 },
		},
		[20402] = 
		{
			[1] = { x = -3.20, y = 54.23, z = -1.20, name = "용암 사냥개", level = 32 },
		},
		[20403] = 
		{
			[1] = { x = -3.60, y = 54.23, z = -1.52, name = "바하르 수련자", level = 32 },
			[2] = { x = -3.28, y = 54.21, z = -1.23, name = "바하르 수련자", level = 32 },
		},
		[20405] = 
		{
			[1] = { x = 1.85, y = 54.23, z = -9.47, name = "바하르 수련자", level = 32 },
			[2] = { x = -11.29, y = 54.23, z = -6.08, name = "바하르 수련자", level = 32 },
			[3] = { x = 5.27, y = 54.23, z = 3.77, name = "바하르 수련자", level = 32 },
			[4] = { x = -7.69, y = 54.23, z = 7.05, name = "바하르 수련자", level = 32 },
			[5] = { x = -2.96, y = 54.23, z = -0.75, name = "바하르 수련자", level = 32 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -3.11, y = 54.21, z = -4.31, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -3.16, y = 54.21, z = -0.91, Type = 1,
			Tid = 
			{
				[20400] = 1,
			},
		},
		[2] = 
		{
			x = -3.33, y = 54.23, z = -1.59, Type = 1,
			Tid = 
			{
				[20401] = 2,
			},
		},
		[3] = 
		{
			x = -3.26, y = 54.23, z = -3.11, Type = 1,
			Tid = 
			{
				[20401] = 3,
			},
		},
		[4] = 
		{
			x = -3.20, y = 54.23, z = -1.20, Type = 1,
			Tid = 
			{
				[20402] = 2,
			},
		},
		[5] = 
		{
			x = -3.60, y = 54.23, z = -1.52, Type = 1,
			Tid = 
			{
				[20403] = 4,
			},
		},
		[6] = 
		{
			x = -3.28, y = 54.21, z = -1.23, Type = 1,
			Tid = 
			{
				[20403] = 4,
			},
		},
		[7] = 
		{
			x = 1.85, y = 54.23, z = -9.47, Type = 1,
			Tid = 
			{
				[20405] = 1,
			},
		},
		[8] = 
		{
			x = -11.29, y = 54.23, z = -6.08, Type = 1,
			Tid = 
			{
				[20405] = 1,
			},
		},
		[9] = 
		{
			x = 5.27, y = 54.23, z = 3.77, Type = 1,
			Tid = 
			{
				[20405] = 1,
			},
		},
		[11] = 
		{
			x = -7.69, y = 54.23, z = 7.05, Type = 1,
			Tid = 
			{
				[20405] = 1,
			},
		},
		[12] = 
		{
			x = -2.96, y = 54.23, z = -0.75, Type = 1,
			Tid = 
			{
				[20405] = 1,
			},
		},
		[16] = 
		{
			x = -3.26, y = 54.23, z = -3.11, Type = 1,
			Tid = 
			{
				[20401] = 4,
			},
		},
		[13] = 
		{
			x = 40.48, y = 40.27, z = 32.94, Type = 4,
			Tid = 
			{
				[7] = 0,
			},
		},
		[10] = 
		{
			x = 1.88, y = 53.94, z = 18.02, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -0.25, posy = 54.33, posz = -6.67, rotx = 0.00, roty = 44.95, rotz = 0.00 },
		[2] = { posx = 0.41, posy = 54.21, posz = 11.46, rotx = 0.00, roty = 193.87, rotz = 0.00 },
		[3] = { posx = 2.31, posy = 54.67, posz = 11.68, rotx = 0.00, roty = 193.87, rotz = 0.00 },
		[4] = { posx = -1.05, posy = 54.67, posz = 12.53, rotx = 0.00, roty = 193.87, rotz = 0.00 },
		[5] = { posx = 3.68, posy = 54.67, posz = 10.70, rotx = 0.00, roty = 193.87, rotz = 0.00 },
		[6] = { posx = -2.85, posy = 54.67, posz = 12.31, rotx = 0.00, roty = 193.87, rotz = 0.00 },
	},

}
return MapInfo
