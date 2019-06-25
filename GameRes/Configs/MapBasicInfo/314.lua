local MapInfo = 
{
	MapType = 2,
	Remarks = "巨龙巢穴·困难",
	TextDisplayName = "巨龙巢穴·困难",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn_evn01_DN.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DRAGON_CAVE",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/dragon.png",
	AssetPath = "Assets/Outputs/Scenes/Dn_evn01_DNest.prefab",
	Monster = 
	{
		[32066] = 
		{
			[1] = { x = 7.93, y = -37.64, z = -14.38, name = "隐形怪", level = 50 },
		},
		[32068] = 
		{
			[1] = { x = 7.96, y = -37.64, z = -7.45, name = "巨龙", level = 36,IsBoss = true },
		},
		[32069] = 
		{
			[1] = { x = 8.26, y = -42.97, z = -96.25, name = "龙血蜥蜴蛋", level = 34 },
			[2] = { x = 8.26, y = -42.97, z = -71.25, name = "龙血蜥蜴蛋", level = 34 },
		},
		[32070] = 
		{
			[1] = { x = 8.26, y = -37.64, z = -13.25, name = "龙血蜥蜴蛋", level = 34 },
		},
		[32071] = 
		{
			[1] = { x = 8.26, y = -42.97, z = -77.55, name = "龙血蜥蜴", level = 34 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[200] = { x = 7.58, y = -10.31, z = -63.30, name = "镜头调整区域", worldId = 0, PkMode = 0 },
			[201] = { x = 8.10, y = -35.93, z = -13.50, name = "boss区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[120] = 
		{
			[1] = { x = 7.73, y = -42.97, z = -126.89 },
		},
		[191] = 
		{
			[1] = { x = 8.10, y = -37.64, z = 0.00 },
		},
		[381] = 
		{
			[1] = { x = 26.50, y = -37.64, z = -10.50 },
		},
		[380] = 
		{
			[1] = { x = -9.50, y = -37.64, z = -10.40 },
		},
		[379] = 
		{
			[1] = { x = -5.30, y = -37.64, z = -32.10 },
		},
		[378] = 
		{
			[1] = { x = 22.02, y = -37.64, z = -32.64 },
		},
		[383] = 
		{
			[1] = { x = 7.92, y = -37.64, z = 6.71 },
		},
	},
	Entity = 
	{
		[14] = 
		{
			x = 7.93, y = -37.64, z = -14.38, Type = 1,
			Tid = 
			{
				[32066] = 1,
			},
		},
		[18] = 
		{
			x = 7.96, y = -37.64, z = -7.45, Type = 1,
			Tid = 
			{
				[32068] = 1,
			},
		},
		[16] = 
		{
			x = 8.26, y = -42.97, z = -96.25, Type = 1,
			Tid = 
			{
				[32069] = 10,
			},
		},
		[12] = 
		{
			x = 8.26, y = -42.97, z = -71.25, Type = 1,
			Tid = 
			{
				[32069] = 8,
			},
		},
		[13] = 
		{
			x = 8.26, y = -37.64, z = -13.25, Type = 1,
			Tid = 
			{
				[32070] = 4,
			},
		},
		[17] = 
		{
			x = 8.26, y = -42.97, z = -77.55, Type = 1,
			Tid = 
			{
				[32071] = 8,
			},
		},
		[3] = 
		{
			x = -10.61, y = -42.97, z = -93.30, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[4] = 
		{
			x = 28.30, y = -42.97, z = -93.30, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[5] = 
		{
			x = 36.40, y = -37.55, z = -24.90, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[6] = 
		{
			x = 34.20, y = -36.55, z = 4.80, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[7] = 
		{
			x = -18.10, y = -36.88, z = -2.02, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[8] = 
		{
			x = -18.10, y = -36.92, z = -26.70, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[9] = 
		{
			x = 4.90, y = -36.32, z = 14.90, Type = 4,
			Tid = 
			{
				[18] = 0,
			},
		},
		[10] = 
		{
			x = 8.24, y = -42.97, z = -64.60, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[11] = 
		{
			x = 8.20, y = -37.64, z = -42.24, Type = 4,
			Tid = 
			{
				[19] = 0,
			},
		},
		[2] = 
		{
			x = 7.73, y = -42.97, z = -126.89, Type = 6,
			Tid = 
			{
				[120] = 1,
			},
		},
		[19] = 
		{
			x = 8.10, y = -37.64, z = 0.00, Type = 6,
			Tid = 
			{
				[191] = 1,
			},
		},
		[20] = 
		{
			x = 26.50, y = -37.64, z = -10.50, Type = 6,
			Tid = 
			{
				[381] = 1,
			},
		},
		[21] = 
		{
			x = -9.50, y = -37.64, z = -10.40, Type = 6,
			Tid = 
			{
				[380] = 1,
			},
		},
		[22] = 
		{
			x = -5.30, y = -37.64, z = -32.10, Type = 6,
			Tid = 
			{
				[379] = 1,
			},
		},
		[23] = 
		{
			x = 22.02, y = -37.64, z = -32.64, Type = 6,
			Tid = 
			{
				[378] = 1,
			},
		},
		[15] = 
		{
			x = 7.92, y = -37.64, z = 6.71, Type = 6,
			Tid = 
			{
				[383] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 7.91, posy = -37.40, posz = 8.20, rotx = 0.00, roty = 180.01, rotz = 0.00 },
		[2] = { posx = 7.80, posy = -37.64, posz = -24.17, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = 22.15, posy = -37.64, posz = -32.65, rotx = 0.00, roty = 311.11, rotz = 0.00 },
		[4] = { posx = -5.40, posy = -37.60, posz = -32.20, rotx = 0.00, roty = 25.81, rotz = 0.00 },
		[5] = { posx = 26.70, posy = -37.60, posz = -10.47, rotx = 0.00, roty = 244.41, rotz = 0.00 },
		[6] = { posx = -9.70, posy = -37.60, posz = -10.40, rotx = 0.00, roty = 77.51, rotz = 0.00 },
		[7] = { posx = 8.00, posy = -37.60, posz = 7.00, rotx = 0.00, roty = 162.91, rotz = 0.00 },
	},

}
return MapInfo
