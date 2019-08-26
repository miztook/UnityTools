local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "살무사 아레나",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	PKMode= 1,
	Monster = 
	{
		[14222] = 
		{
			[1] = { x = 235.90, y = 22.52, z = -217.20, name = "타락한 해적", level = 52, SortID = 1, DropItemIds = " " },
			[2] = { x = 203.82, y = 27.65, z = -142.99, name = "타락한 해적", level = 52, SortID = 6, DropItemIds = " " },
			[3] = { x = 219.91, y = 27.65, z = -157.70, name = "타락한 해적", level = 52, SortID = 2, DropItemIds = " " },
			[4] = { x = 223.14, y = 27.65, z = -184.37, name = "타락한 해적", level = 52, SortID = 7, DropItemIds = " " },
			[5] = { x = 216.31, y = 27.65, z = -199.37, name = "타락한 해적", level = 52, SortID = 8, DropItemIds = " " },
			[6] = { x = 203.82, y = 27.65, z = -142.99, name = "타락한 해적", level = 52, SortID = 14, DropItemIds = " " },
		},
		[14221] = 
		{
			[1] = { x = 196.35, y = 27.65, z = -209.79, name = "타락한 부하", level = 52, SortID = 4, DropItemIds = " " },
			[2] = { x = 196.35, y = 27.65, z = -209.79, name = "타락한 부하", level = 52, SortID = 9, DropItemIds = " " },
			[3] = { x = 179.50, y = 27.65, z = -208.77, name = "타락한 부하", level = 52, SortID = 12, DropItemIds = " " },
			[4] = { x = 156.06, y = 27.65, z = -185.03, name = "타락한 부하", level = 52, SortID = 13, DropItemIds = " " },
		},
		[14249] = 
		{
			[1] = { x = 179.98, y = 27.65, z = -141.58, name = "불사의 병사", level = 52, SortID = 15, DropItemIds = " " },
			[2] = { x = 161.70, y = 27.65, z = -154.45, name = "불사의 병사", level = 52, SortID = 16, DropItemIds = " " },
			[3] = { x = 142.20, y = 24.11, z = -127.23, name = "불사의 병사", level = 52, SortID = 17, DropItemIds = " " },
			[4] = { x = 151.31, y = 24.24, z = -136.88, name = "불사의 병사", level = 52, SortID = 18, DropItemIds = " " },
		},
		[14223] = 
		{
			[1] = { x = 190.25, y = 20.93, z = -170.79, name = "타락한 해적 선장", level = 52, SortID = 19, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[76] = 
		{
			[1] = { x = 237.14, y = 22.37, z = -219.84, name = "희망항 수비군", SortID = 3, FunctionName = " " },
			[2] = { x = 138.32, y = 24.67, z = -121.50, name = "희망항 수비군", SortID = 5, FunctionName = " " },
		},
		[4228] = 
		{
			[1] = { x = 238.16, y = 22.42, z = -230.73, name = "푸불리", SortID = 11, FunctionName = " " },
		},
	},
	Region = 
	{
		[1] = 
		{
			[131] = { x = 181.54, y = 21.52, z = -184.19, xA = 165.72, yA = 27.64, zA = -198.88, name = "传送楼下", worldId = 1220, PkMode = 1 },
			[132] = { x = 167.76, y = 27.65, z = -197.04, xA = 183.87, yA = 20.85, zA = -180.41, name = "传送楼上", worldId = 1220, PkMode = 1 },
		},
		[2] = 
		{
			[82] = { x = 215.84, y = 27.63, z = -200.46, name = "奴隶区", worldId = 0, PkMode = 1 },
			[83] = { x = 210.04, y = 27.63, z = -146.71, name = "군사 구역", worldId = 0, PkMode = 1 },
			[84] = { x = 147.62, y = 24.12, z = -132.52, name = "竞技场外", worldId = 0, PkMode = 1 },
			[85] = { x = 177.08, y = 46.90, z = -158.82, name = "", worldId = 0, PkMode = 1 },
			[130] = { x = 190.17, y = 20.85, z = -174.95, name = "竞技场内环", worldId = 0, PkMode = 1, IsCanHawkeye = true, QuestID = {4506} },
		},
	},
	Mine = 
	{
		[852] = 
		{
			[1] = { x = 200.41, y = 20.93, z = -175.09 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = 235.90, y = 22.52, z = -217.20, Type = 1,
			Tid = 
			{
				[14222] = 12,
			},
		},
		[4] = 
		{
			x = 196.35, y = 27.65, z = -209.79, Type = 1,
			Tid = 
			{
				[14221] = 8,
			},
		},
		[6] = 
		{
			x = 203.82, y = 27.65, z = -142.99, Type = 1,
			Tid = 
			{
				[14222] = 8,
			},
		},
		[2] = 
		{
			x = 219.91, y = 27.65, z = -157.70, Type = 1,
			Tid = 
			{
				[14222] = 8,
			},
		},
		[7] = 
		{
			x = 223.14, y = 27.65, z = -184.37, Type = 1,
			Tid = 
			{
				[14222] = 8,
			},
		},
		[8] = 
		{
			x = 216.31, y = 27.65, z = -199.37, Type = 1,
			Tid = 
			{
				[14222] = 8,
			},
		},
		[9] = 
		{
			x = 196.35, y = 27.65, z = -209.79, Type = 1,
			Tid = 
			{
				[14221] = 8,
			},
		},
		[12] = 
		{
			x = 179.50, y = 27.65, z = -208.77, Type = 1,
			Tid = 
			{
				[14221] = 8,
			},
		},
		[13] = 
		{
			x = 156.06, y = 27.65, z = -185.03, Type = 1,
			Tid = 
			{
				[14221] = 8,
			},
		},
		[14] = 
		{
			x = 203.82, y = 27.65, z = -142.99, Type = 1,
			Tid = 
			{
				[14222] = 8,
			},
		},
		[15] = 
		{
			x = 179.98, y = 27.65, z = -141.58, Type = 1,
			Tid = 
			{
				[14249] = 8,
			},
		},
		[16] = 
		{
			x = 161.70, y = 27.65, z = -154.45, Type = 1,
			Tid = 
			{
				[14249] = 8,
			},
		},
		[17] = 
		{
			x = 142.20, y = 24.11, z = -127.23, Type = 1,
			Tid = 
			{
				[14249] = 8,
			},
		},
		[18] = 
		{
			x = 151.31, y = 24.24, z = -136.88, Type = 1,
			Tid = 
			{
				[14249] = 8,
			},
		},
		[19] = 
		{
			x = 190.25, y = 20.93, z = -170.79, Type = 1,
			Tid = 
			{
				[14223] = 1,
			},
		},
		[3] = 
		{
			x = 237.14, y = 22.37, z = -219.84, Type = 2,
			Tid = 
			{
				[76] = 8,
			},
		},
		[5] = 
		{
			x = 138.32, y = 24.67, z = -121.50, Type = 2,
			Tid = 
			{
				[76] = 8,
			},
		},
		[11] = 
		{
			x = 238.16, y = 22.42, z = -230.73, Type = 2,
			Tid = 
			{
				[4228] = 1,
			},
		},
		[21] = 
		{
			x = 200.41, y = 20.93, z = -175.09, Type = 6,
			Tid = 
			{
				[852] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 183.87, posy = 20.85, posz = -180.41, rotx = 0.00, roty = 19.75, rotz = 0.00 },
		[2] = { posx = 165.72, posy = 27.64, posz = -198.88, rotx = 0.00, roty = 127.02, rotz = 0.00 },
		[3] = { posx = 188.62, posy = 20.54, posz = -174.42, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
