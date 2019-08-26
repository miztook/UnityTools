local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "생명의 씨앗 [명성]",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part1.navmesh",
	BackgroundMusic = "BGM_Map_4/Map_4/Map_4_phase",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-1.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part1.prefab",
	PKMode= 1,
	Monster = 
	{
		[50305] = 
		{
			[1] = { x = -249.22, y = 49.31, z = 155.53, name = "은신한 몬스터", level = 40, SortID = 6, DropItemIds = " " },
		},
		[50304] = 
		{
			[1] = { x = -238.63, y = 49.31, z = 151.97, name = "은신한 몬스터", level = 40, SortID = 7, DropItemIds = " " },
		},
		[50303] = 
		{
			[1] = { x = -242.94, y = 52.27, z = 178.54, name = "사막 행인", level = 40, SortID = 8, DropItemIds = " " },
		},
		[50301] = 
		{
			[1] = { x = -242.94, y = 52.27, z = 178.54, name = "사막 행인 용사", level = 40, SortID = 9, DropItemIds = " " },
		},
		[50302] = 
		{
			[1] = { x = -242.94, y = 52.27, z = 178.54, name = "사막 행인 두목", level = 40, SortID = 10, DropItemIds = " " },
		},
		[50306] = 
		{
			[1] = { x = -238.55, y = 49.31, z = 152.61, name = "은신한 몬스터", level = 40, SortID = 11, DropItemIds = " " },
		},
	},
	Npc = 
	{
		[40201] = 
		{
			[1] = { x = -198.00, y = 54.68, z = 129.39, name = "푸로 엘린", SortID = 1, FunctionName = " " },
		},
		[40202] = 
		{
			[1] = { x = -198.00, y = 54.68, z = 129.39, name = "푸로 엘린", SortID = 2, FunctionName = " " },
			[2] = { x = -238.63, y = 49.31, z = 151.97, name = "푸로 엘린", SortID = 12, FunctionName = " " },
		},
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -236.01, y = 49.31, z = 151.42, name = "2 抵达区域", worldId = 0, PkMode = 1 },
			[5] = { x = -228.60, y = 49.31, z = 153.07, name = "", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
		[10201] = 
		{
			[1] = { x = -249.77, y = 49.31, z = 150.74 },
			[2] = { x = -249.05, y = 49.31, z = 154.72 },
			[3] = { x = -247.96, y = 49.31, z = 158.79 },
		},
	},
	Entity = 
	{
		[6] = 
		{
			x = -249.22, y = 49.31, z = 155.53, Type = 1,
			Tid = 
			{
				[50305] = 1,
			},
		},
		[7] = 
		{
			x = -238.63, y = 49.31, z = 151.97, Type = 1,
			Tid = 
			{
				[50304] = 1,
			},
		},
		[8] = 
		{
			x = -242.94, y = 52.27, z = 178.54, Type = 1,
			Tid = 
			{
				[50303] = 3,
			},
		},
		[9] = 
		{
			x = -242.94, y = 52.27, z = 178.54, Type = 1,
			Tid = 
			{
				[50301] = 3,
			},
		},
		[10] = 
		{
			x = -242.94, y = 52.27, z = 178.54, Type = 1,
			Tid = 
			{
				[50302] = 1,
			},
		},
		[11] = 
		{
			x = -238.55, y = 49.31, z = 152.61, Type = 1,
			Tid = 
			{
				[50306] = 1,
			},
		},
		[1] = 
		{
			x = -198.00, y = 54.68, z = 129.39, Type = 2,
			Tid = 
			{
				[40201] = 1,
			},
		},
		[2] = 
		{
			x = -198.00, y = 54.68, z = 129.39, Type = 2,
			Tid = 
			{
				[40202] = 1,
			},
		},
		[12] = 
		{
			x = -238.63, y = 49.31, z = 151.97, Type = 2,
			Tid = 
			{
				[40202] = 1,
			},
		},
		[3] = 
		{
			x = -249.77, y = 49.31, z = 150.74, Type = 6,
			Tid = 
			{
				[10201] = 5,
			},
		},
		[4] = 
		{
			x = -249.05, y = 49.31, z = 154.72, Type = 6,
			Tid = 
			{
				[10201] = 5,
			},
		},
		[5] = 
		{
			x = -247.96, y = 49.31, z = 158.79, Type = 6,
			Tid = 
			{
				[10201] = 5,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -189.95, posy = 54.64, posz = 120.52, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
