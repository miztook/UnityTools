local MapInfo = 
{
	MapType = 3,
	Remarks = "大地图2",
	TextDisplayName = "쿠사의 왕좌",
	Length = 512,
	Width = 512,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "BGM_Map_2/Map_2/Map_2_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Canyon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	Monster = 
	{
		[11027] = 
		{
			[1] = { x = 230.02, y = 70.23, z = 210.98, name = "쿠사", level = 26, SortID = 3 },
		},
		[11093] = 
		{
			[1] = { x = 230.14, y = 69.24, z = 211.40, name = "핏빛 마법의 돌", level = 28, SortID = 4 },
		},
		[11053] = 
		{
			[1] = { x = 188.00, y = 69.70, z = 210.43, name = "군단 장교", level = 27, SortID = 7 },
		},
		[11051] = 
		{
			[1] = { x = 181.32, y = 69.22, z = 210.43, name = "제 1군단 검사", level = 27, SortID = 8 },
		},
		[11052] = 
		{
			[1] = { x = 184.12, y = 69.20, z = 210.50, name = "제 1군단 주술사", level = 27, SortID = 9 },
		},
		[11050] = 
		{
			[1] = { x = 180.88, y = 69.31, z = 221.24, name = "혈전사", level = 27, SortID = 10 },
			[2] = { x = 179.89, y = 69.29, z = 200.49, name = "혈전사", level = 27, SortID = 11 },
		},
		[11076] = 
		{
			[1] = { x = 189.79, y = 69.70, z = 213.71, name = "혈마법사", level = 26, SortID = 5 },
		},
		[11075] = 
		{
			[1] = { x = 219.31, y = 69.70, z = 211.30, name = "비행 몬스터", level = 20, SortID = 15 },
			[2] = { x = 179.72, y = 69.70, z = 210.92, name = "비행 몬스터", level = 20, SortID = 16 },
		},
		[11094] = 
		{
			[1] = { x = 230.18, y = 69.24, z = 211.38, name = "핏빛 마법의 돌", level = 28, SortID = 17 },
		},
		[11095] = 
		{
			[1] = { x = 230.16, y = 69.24, z = 211.35, name = "핏빛 마법의 돌", level = 28, SortID = 18 },
		},
	},
	Npc = 
	{
		[2162] = 
		{
			[1] = { x = 189.60, y = 69.24, z = 207.38, name = "바네사 드페라", SortID = 6 },
		},
		[2160] = 
		{
			[1] = { x = 164.65, y = 69.70, z = 216.47, name = "사마엘", SortID = 12 },
			[2] = { x = 185.07, y = 69.70, z = 213.26, name = "사마엘", SortID = 19 },
		},
		[2161] = 
		{
			[1] = { x = 164.65, y = 69.70, z = 216.47, name = "연합군", SortID = 12 },
		},
		[2159] = 
		{
			[1] = { x = 167.98, y = 69.08, z = 204.37, name = "디포", SortID = 13 },
			[2] = { x = 185.50, y = 69.08, z = 207.09, name = "디포", SortID = 20 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[148] = { x = 203.38, y = 74.90, z = 207.81, name = "库萨大营相位【个人】", worldId = 0, PkMode = 0 },
			[457] = { x = 174.98, y = 70.08, z = 205.42, name = "第一阶段区域", worldId = 0, PkMode = 0 },
			[458] = { x = 202.35, y = 69.70, z = 211.23, name = "第二阶段区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[3] = 
		{
			x = 230.02, y = 70.23, z = 210.98, Type = 1,
			Tid = 
			{
				[11027] = 1,
			},
		},
		[4] = 
		{
			x = 230.14, y = 69.24, z = 211.40, Type = 1,
			Tid = 
			{
				[11093] = 3,
			},
		},
		[7] = 
		{
			x = 188.00, y = 69.70, z = 210.43, Type = 1,
			Tid = 
			{
				[11053] = 1,
			},
		},
		[8] = 
		{
			x = 181.32, y = 69.22, z = 210.43, Type = 1,
			Tid = 
			{
				[11051] = 2,
			},
		},
		[9] = 
		{
			x = 184.12, y = 69.20, z = 210.50, Type = 1,
			Tid = 
			{
				[11052] = 2,
			},
		},
		[10] = 
		{
			x = 180.88, y = 69.31, z = 221.24, Type = 1,
			Tid = 
			{
				[11050] = 2,
			},
		},
		[11] = 
		{
			x = 179.89, y = 69.29, z = 200.49, Type = 1,
			Tid = 
			{
				[11050] = 2,
			},
		},
		[5] = 
		{
			x = 189.79, y = 69.70, z = 213.71, Type = 1,
			Tid = 
			{
				[11076] = 1,
			},
		},
		[15] = 
		{
			x = 219.31, y = 69.70, z = 211.30, Type = 1,
			Tid = 
			{
				[11075] = 1,
			},
		},
		[16] = 
		{
			x = 179.72, y = 69.70, z = 210.92, Type = 1,
			Tid = 
			{
				[11075] = 1,
			},
		},
		[17] = 
		{
			x = 230.18, y = 69.24, z = 211.38, Type = 1,
			Tid = 
			{
				[11094] = 3,
			},
		},
		[18] = 
		{
			x = 230.16, y = 69.24, z = 211.35, Type = 1,
			Tid = 
			{
				[11095] = 3,
			},
		},
		[6] = 
		{
			x = 189.60, y = 69.24, z = 207.38, Type = 2,
			Tid = 
			{
				[2162] = 1,
			},
		},
		[12] = 
		{
			x = 164.65, y = 69.70, z = 216.47, Type = 2,
			Tid = 
			{
				[2160] = 1,
				[2161] = 3,
			},
		},
		[13] = 
		{
			x = 167.98, y = 69.08, z = 204.37, Type = 2,
			Tid = 
			{
				[2159] = 1,
			},
		},
		[19] = 
		{
			x = 185.07, y = 69.70, z = 213.26, Type = 2,
			Tid = 
			{
				[2160] = 1,
			},
		},
		[20] = 
		{
			x = 185.50, y = 69.08, z = 207.09, Type = 2,
			Tid = 
			{
				[2159] = 1,
			},
		},
		[14] = 
		{
			x = 196.61, y = 69.70, z = 210.98, Type = 4,
			Tid = 
			{
				[24] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 173.59, posy = 69.70, posz = 210.64, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[2] = { posx = 193.58, posy = 69.70, posz = 211.24, rotx = 0.00, roty = 90.00, rotz = 0.00 },
	},

}
return MapInfo
