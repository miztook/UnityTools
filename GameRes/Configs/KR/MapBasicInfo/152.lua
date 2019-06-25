local MapInfo = 
{
	MapType = 3,
	Remarks = "托里城堡相位",
	TextDisplayName = "폐허가 된 성루",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part2.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Canyon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-2.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part2.prefab",
	Monster = 
	{
		[12049] = 
		{
			[1] = { x = 330.70, y = 48.04, z = 71.60, name = "노예 주인", level = 35, SortID = 4 },
		},
		[12047] = 
		{
			[1] = { x = 330.70, y = 48.04, z = 71.60, name = "돌진하는 죽은 병사", level = 35, SortID = 4 },
		},
		[12048] = 
		{
			[1] = { x = 330.70, y = 48.04, z = 71.60, name = "돌진하는 정찰병", level = 35, SortID = 4 },
		},
		[12046] = 
		{
			[1] = { x = 334.80, y = 50.13, z = 126.70, name = "제 3군단 장교", level = 35, SortID = 5 },
		},
		[12044] = 
		{
			[1] = { x = 334.80, y = 50.13, z = 126.70, name = "제 3군단 검사", level = 35, SortID = 5 },
		},
		[12045] = 
		{
			[1] = { x = 334.80, y = 50.13, z = 126.70, name = "제 3군단 주술사", level = 35, SortID = 5 },
		},
		[12070] = 
		{
			[1] = { x = 315.99, y = 50.66, z = 136.41, name = "디포 마음 속 악마", level = 35, SortID = 14 },
		},
	},
	Npc = 
	{
		[2056] = 
		{
			[1] = { x = 314.84, y = 50.43, z = 126.93, name = "조나단", SortID = 9 },
		},
		[2055] = 
		{
			[1] = { x = 318.71, y = 50.43, z = 126.93, name = "루나 엘린", SortID = 10 },
		},
		[2054] = 
		{
			[1] = { x = 310.93, y = 50.47, z = 126.78, name = "사마엘", SortID = 11 },
		},
		[2121] = 
		{
			[1] = { x = 312.43, y = 50.66, z = 141.98, name = "바네사 드페라", SortID = 12 },
		},
		[2120] = 
		{
			[1] = { x = 316.13, y = 50.66, z = 136.44, name = "디포", SortID = 13 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[212] = { x = 297.77, y = 32.19, z = 108.27, name = "폐허가 된 성루", worldId = 0, PkMode = 0 },
			[244] = { x = 274.28, y = 42.78, z = 81.72, name = "扫雷", worldId = 0, PkMode = 0, IsCanHawkeye = true, QuestID = {2065} },
			[245] = { x = 327.18, y = 47.65, z = 76.46, name = "营地", worldId = 0, PkMode = 0 },
			[246] = { x = 330.47, y = 50.54, z = 109.50, name = "镇公所", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[243] = 
		{
			[1] = { x = 273.03, y = 41.72, z = 81.95 },
		},
		[241] = 
		{
			[1] = { x = 338.36, y = 48.73, z = 71.91 },
		},
		[240] = 
		{
			[1] = { x = 344.90, y = 48.61, z = 118.40 },
		},
		[242] = 
		{
			[1] = { x = 316.10, y = 50.66, z = 143.26 },
		},
	},
	Entity = 
	{
		[4] = 
		{
			x = 330.70, y = 48.04, z = 71.60, Type = 1,
			Tid = 
			{
				[12049] = 1,
				[12047] = 5,
				[12048] = 3,
			},
		},
		[5] = 
		{
			x = 334.80, y = 50.13, z = 126.70, Type = 1,
			Tid = 
			{
				[12046] = 1,
				[12044] = 5,
				[12045] = 3,
			},
		},
		[14] = 
		{
			x = 315.99, y = 50.66, z = 136.41, Type = 1,
			Tid = 
			{
				[12070] = 1,
			},
		},
		[9] = 
		{
			x = 314.84, y = 50.43, z = 126.93, Type = 2,
			Tid = 
			{
				[2056] = 1,
			},
		},
		[10] = 
		{
			x = 318.71, y = 50.43, z = 126.93, Type = 2,
			Tid = 
			{
				[2055] = 1,
			},
		},
		[11] = 
		{
			x = 310.93, y = 50.47, z = 126.78, Type = 2,
			Tid = 
			{
				[2054] = 1,
			},
		},
		[12] = 
		{
			x = 312.43, y = 50.66, z = 141.98, Type = 2,
			Tid = 
			{
				[2121] = 1,
			},
		},
		[13] = 
		{
			x = 316.13, y = 50.66, z = 136.44, Type = 2,
			Tid = 
			{
				[2120] = 1,
			},
		},
		[3] = 
		{
			x = 273.03, y = 41.72, z = 81.95, Type = 6,
			Tid = 
			{
				[243] = 5,
			},
		},
		[6] = 
		{
			x = 338.36, y = 48.73, z = 71.91, Type = 6,
			Tid = 
			{
				[241] = 1,
			},
		},
		[7] = 
		{
			x = 344.90, y = 48.61, z = 118.40, Type = 6,
			Tid = 
			{
				[240] = 1,
			},
		},
		[8] = 
		{
			x = 316.10, y = 50.66, z = 143.26, Type = 6,
			Tid = 
			{
				[242] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 336.29, posy = 46.57, posz = -106.17, rotx = 0.00, roty = 228.09, rotz = 0.00 },
	},

}
return MapInfo
