local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "죽음의 왕좌",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part1.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-1.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part1.prefab",
	Monster = 
	{
		[14241] = 
		{
			[1] = { x = -100.20, y = 62.83, z = 109.90, name = "숲 유안트 용사", level = 56, SortID = 41, DropItemIds = " " },
			[2] = { x = -105.80, y = 62.83, z = 91.20, name = "숲 유안트 용사", level = 56, SortID = 1, DropItemIds = " " },
			[3] = { x = -102.10, y = 62.83, z = 77.70, name = "숲 유안트 용사", level = 56, SortID = 2, DropItemIds = " " },
		},
		[14237] = 
		{
			[1] = { x = -81.64, y = 65.30, z = 54.55, name = "사막 행인", level = 56, SortID = 3, DropItemIds = " " },
			[2] = { x = -90.05, y = 65.30, z = 64.06, name = "사막 행인", level = 56, SortID = 4, DropItemIds = " " },
			[3] = { x = -58.80, y = 65.30, z = 65.50, name = "사막 행인", level = 56, SortID = 5, DropItemIds = " " },
		},
		[14242] = 
		{
			[1] = { x = -126.90, y = 59.46, z = 72.20, name = "천명의 도살자", level = 56, SortID = 7, DropItemIds = " ",IsBoss = true },
		},
	},
	Npc = 
	{
		[4225] = 
		{
			[1] = { x = -120.06, y = 63.32, z = 121.73, name = "칼 마신", SortID = 30, FunctionName = " " },
		},
		[3012] = 
		{
			[1] = { x = -105.61, y = 62.99, z = 113.59, name = "카마이 전사", SortID = 31, FunctionName = " " },
			[2] = { x = -50.20, y = 68.92, z = 69.40, name = "카마이 전사", SortID = 6, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[288] = { x = -90.03, y = 67.22, z = 87.30, name = "죽음의 왕좌", worldId = 0, IsCanFind = 1, Describe = "죽음의 왕좌", PkMode = 0, IsCanHawkeye = true, QuestID = {4533} },
		},
	},
	Mine = 
	{
		[856] = 
		{
			[1] = { x = -134.80, y = 59.32, z = 68.20 },
		},
	},
	Entity = 
	{
		[41] = 
		{
			x = -100.20, y = 62.83, z = 109.90, Type = 1,
			Tid = 
			{
				[14241] = 8,
			},
		},
		[1] = 
		{
			x = -105.80, y = 62.83, z = 91.20, Type = 1,
			Tid = 
			{
				[14241] = 8,
			},
		},
		[2] = 
		{
			x = -102.10, y = 62.83, z = 77.70, Type = 1,
			Tid = 
			{
				[14241] = 8,
			},
		},
		[3] = 
		{
			x = -81.64, y = 65.30, z = 54.55, Type = 1,
			Tid = 
			{
				[14237] = 8,
			},
		},
		[4] = 
		{
			x = -90.05, y = 65.30, z = 64.06, Type = 1,
			Tid = 
			{
				[14237] = 8,
			},
		},
		[5] = 
		{
			x = -58.80, y = 65.30, z = 65.50, Type = 1,
			Tid = 
			{
				[14237] = 8,
			},
		},
		[7] = 
		{
			x = -126.90, y = 59.46, z = 72.20, Type = 1,
			Tid = 
			{
				[14242] = 1,
			},
		},
		[30] = 
		{
			x = -120.06, y = 63.32, z = 121.73, Type = 2,
			Tid = 
			{
				[4225] = 1,
			},
		},
		[31] = 
		{
			x = -105.61, y = 62.99, z = 113.59, Type = 2,
			Tid = 
			{
				[3012] = 8,
			},
		},
		[6] = 
		{
			x = -50.20, y = 68.92, z = 69.40, Type = 2,
			Tid = 
			{
				[3012] = 8,
			},
		},
		[49] = 
		{
			x = -134.80, y = 59.32, z = 68.20, Type = 6,
			Tid = 
			{
				[856] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 166.67, posy = 49.24, posz = 276.08, rotx = 0.00, roty = 156.85, rotz = 0.00 },
		[2] = { posx = -65.74, posy = 21.54, posz = -259.30, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -198.64, posy = 31.32, posz = -223.06, rotx = 0.00, roty = 77.57, rotz = 0.00 },
	},

}
return MapInfo
