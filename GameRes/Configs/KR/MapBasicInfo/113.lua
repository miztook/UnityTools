local MapInfo = 
{
	MapType = 3,
	Remarks = "测试",
	TextDisplayName = "희망항",
	Length = 512,
	Width = 512,
	NavMeshName = "City01.navmesh",
	BackgroundMusic = "BGM_Maincastle_1/Maincastle_1/maincastle_1_zone_1",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/city01.png",
	AssetPath = "Assets/Outputs/Scenes/City01.prefab",
	PKMode= 1,
	Monster = 
	{
		[10115] = 
		{
			[1] = { x = -2.32, y = 32.83, z = 122.20, name = "난민 반대자", level = 13, SortID = 4 },
		},
	},
	Npc = 
	{
		[539] = 
		{
			[1] = { x = -6.29, y = 28.93, z = 160.43, name = "캘리 발레토", SortID = 1 },
		},
		[510] = 
		{
			[1] = { x = -4.74, y = 32.83, z = 111.96, name = "케스타닉 난민", SortID = 2 },
		},
		[511] = 
		{
			[1] = { x = -4.74, y = 32.83, z = 111.96, name = "분노한 난민", SortID = 2 },
		},
		[509] = 
		{
			[1] = { x = -9.67, y = 32.83, z = 122.74, name = "목격자", SortID = 3 },
			[2] = { x = 1.17, y = 32.83, z = 121.14, name = "목격자", SortID = 10 },
		},
		[547] = 
		{
			[1] = { x = -9.67, y = 32.83, z = 122.74, name = "독수리파 멤버", SortID = 3 },
			[2] = { x = 1.17, y = 32.83, z = 121.14, name = "독수리파 멤버", SortID = 10 },
		},
		[538] = 
		{
			[1] = { x = -6.29, y = 28.93, z = 160.43, name = "캘리 발레토", SortID = 8 },
		},
		[552] = 
		{
			[1] = { x = -4.10, y = 32.82, z = 131.75, name = "캘리 발레토", SortID = 9 },
		},
		[513] = 
		{
			[1] = { x = -2.93, y = 32.83, z = 123.28, name = "스파이크", SortID = 5 },
		},
		[545] = 
		{
			[1] = { x = 1.17, y = 32.83, z = 121.14, name = "목격자", SortID = 6 },
			[2] = { x = -9.67, y = 32.83, z = 122.74, name = "목격자", SortID = 7 },
		},
		[550] = 
		{
			[1] = { x = 1.17, y = 32.83, z = 121.14, name = "독수리파 멤버", SortID = 6 },
			[2] = { x = -9.67, y = 32.83, z = 122.74, name = "독수리파 멤버", SortID = 7 },
		},
		[546] = 
		{
			[1] = { x = -2.28, y = 32.83, z = 122.12, name = "독수리파 멤버", SortID = 11 },
		},
		[549] = 
		{
			[1] = { x = -2.28, y = 32.83, z = 122.12, name = "독수리파 멤버", SortID = 12 },
		},
		[551] = 
		{
			[1] = { x = -2.93, y = 32.83, z = 123.28, name = "스파이크", SortID = 13 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[334] = { x = -16.60, y = 45.12, z = 146.22, name = "暴动相位区域", worldId = 0, PkMode = 1 },
			[335] = { x = -2.43, y = 32.82, z = 132.66, name = "护送区域1", worldId = 0, PkMode = 1 },
			[336] = { x = -4.30, y = 33.02, z = 116.65, name = "护送区域2", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[4] = 
		{
			x = -2.32, y = 32.83, z = 122.20, Type = 1,
			Tid = 
			{
				[10115] = 3,
			},
		},
		[1] = 
		{
			x = -6.29, y = 28.93, z = 160.43, Type = 2,
			Tid = 
			{
				[539] = 1,
			},
		},
		[2] = 
		{
			x = -4.74, y = 32.83, z = 111.96, Type = 2,
			Tid = 
			{
				[510] = 2,
				[511] = 1,
			},
		},
		[3] = 
		{
			x = -9.67, y = 32.83, z = 122.74, Type = 2,
			Tid = 
			{
				[509] = 2,
				[547] = 2,
			},
		},
		[8] = 
		{
			x = -6.29, y = 28.93, z = 160.43, Type = 2,
			Tid = 
			{
				[538] = 1,
			},
		},
		[10] = 
		{
			x = 1.17, y = 32.83, z = 121.14, Type = 2,
			Tid = 
			{
				[509] = 2,
				[547] = 2,
			},
		},
		[9] = 
		{
			x = -4.10, y = 32.82, z = 131.75, Type = 2,
			Tid = 
			{
				[552] = 1,
			},
		},
		[5] = 
		{
			x = -2.93, y = 32.83, z = 123.28, Type = 2,
			Tid = 
			{
				[513] = 1,
			},
		},
		[6] = 
		{
			x = 1.17, y = 32.83, z = 121.14, Type = 2,
			Tid = 
			{
				[545] = 2,
				[550] = 2,
			},
		},
		[7] = 
		{
			x = -9.67, y = 32.83, z = 122.74, Type = 2,
			Tid = 
			{
				[545] = 2,
				[550] = 2,
			},
		},
		[11] = 
		{
			x = -2.28, y = 32.83, z = 122.12, Type = 2,
			Tid = 
			{
				[546] = 3,
			},
		},
		[12] = 
		{
			x = -2.28, y = 32.83, z = 122.12, Type = 2,
			Tid = 
			{
				[549] = 3,
			},
		},
		[13] = 
		{
			x = -2.93, y = 32.83, z = 123.28, Type = 2,
			Tid = 
			{
				[551] = 1,
			},
		},
		[106] = 
		{
			x = 9.19, y = 29.33, z = -156.23, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[107] = 
		{
			x = -115.20, y = 25.66, z = -119.11, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -2.98, posy = 28.67, posz = 182.82, rotx = 0.00, roty = 170.64, rotz = 0.00 },
		[2] = { posx = -89.17, posy = 31.06, posz = 142.08, rotx = 0.00, roty = 91.05, rotz = 0.00 },
		[3] = { posx = 141.91, posy = 19.02, posz = 218.47, rotx = 0.00, roty = 223.41, rotz = 0.00 },
		[5] = { posx = 119.66, posy = 21.41, posz = 180.92, rotx = 0.00, roty = 323.41, rotz = 0.00 },
		[6] = { posx = -4.55, posy = 58.38, posz = -43.17, rotx = 0.00, roty = 345.32, rotz = 0.00 },
		[7] = { posx = -5.80, posy = 179.30, posz = -138.31, rotx = 0.00, roty = 151.86, rotz = 0.00 },
		[8] = { posx = -5.14, posy = 48.66, posz = 45.51, rotx = 0.00, roty = 156.87, rotz = 0.00 },
		[9] = { posx = -5.38, posy = 185.32, posz = -191.79, rotx = 0.00, roty = 169.89, rotz = 0.00 },
		[10] = { posx = -71.82, posy = 30.68, posz = 177.99, rotx = 0.00, roty = 135.00, rotz = 0.00 },
		[11] = { posx = -2.84, posy = 32.84, posz = 114.64, rotx = 0.00, roty = 169.58, rotz = 0.00 },
		[12] = { posx = 90.41, posy = 21.41, posz = 166.33, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
