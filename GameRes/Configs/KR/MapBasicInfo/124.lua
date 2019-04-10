local MapInfo = 
{
	MapType = 3,
	Remarks = "个人相位-贪婪溪谷营地",
	TextDisplayName = "숲 속 주둔지",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Foerst",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	Monster = 
	{
		[10038] = 
		{
			[1] = { x = -218.22, y = 42.69, z = -146.29, name = "제국 주술사", level = 18, SortID = 1 },
			[2] = { x = -222.03, y = 43.60, z = -152.02, name = "제국 주술사", level = 18, SortID = 6 },
			[3] = { x = -217.74, y = 42.12, z = -161.92, name = "제국 주술사", level = 18, SortID = 7 },
		},
		[10039] = 
		{
			[1] = { x = -218.22, y = 42.69, z = -146.29, name = "제국 암살자", level = 18, SortID = 1 },
			[2] = { x = -222.03, y = 43.60, z = -152.02, name = "제국 암살자", level = 18, SortID = 6 },
			[3] = { x = -217.74, y = 42.12, z = -161.92, name = "제국 암살자", level = 18, SortID = 7 },
			[4] = { x = -222.43, y = 43.09, z = -137.83, name = "제국 암살자", level = 18, SortID = 10 },
			[5] = { x = -218.05, y = 43.17, z = -136.54, name = "제국 암살자", level = 18, SortID = 11 },
		},
		[10040] = 
		{
			[1] = { x = -218.22, y = 42.69, z = -146.29, name = "노예 무사", level = 18, SortID = 1 },
			[2] = { x = -222.03, y = 43.60, z = -152.02, name = "노예 무사", level = 18, SortID = 6 },
			[3] = { x = -217.74, y = 42.12, z = -161.92, name = "노예 무사", level = 18, SortID = 7 },
		},
		[10043] = 
		{
			[1] = { x = -219.99, y = 42.54, z = -140.20, name = "카모 만 칸디스", level = 18, SortID = 2 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[66] = { x = -216.74, y = 50.71, z = -183.02, name = "", isShowName = true, worldId = 0, PkMode = 0 },
			[187] = { x = -219.13, y = 43.00, z = -145.21, name = "爆炸区", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[14] = 
		{
			[1] = { x = -221.57, y = 42.61, z = -135.46 },
			[2] = { x = -224.13, y = 42.66, z = -134.81 },
			[3] = { x = -219.37, y = 42.58, z = -136.40 },
		},
		[34] = 
		{
			[1] = { x = -205.69, y = 41.84, z = -147.77 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = -218.22, y = 42.69, z = -146.29, Type = 1,
			Tid = 
			{
				[10038] = 1,
				[10039] = 1,
				[10040] = 2,
			},
		},
		[2] = 
		{
			x = -219.99, y = 42.54, z = -140.20, Type = 1,
			Tid = 
			{
				[10043] = 1,
			},
		},
		[6] = 
		{
			x = -222.03, y = 43.60, z = -152.02, Type = 1,
			Tid = 
			{
				[10038] = 1,
				[10039] = 1,
				[10040] = 2,
			},
		},
		[7] = 
		{
			x = -217.74, y = 42.12, z = -161.92, Type = 1,
			Tid = 
			{
				[10038] = 1,
				[10039] = 1,
				[10040] = 2,
			},
		},
		[10] = 
		{
			x = -222.43, y = 43.09, z = -137.83, Type = 1,
			Tid = 
			{
				[10039] = 2,
			},
		},
		[11] = 
		{
			x = -218.05, y = 43.17, z = -136.54, Type = 1,
			Tid = 
			{
				[10039] = 4,
			},
		},
		[3] = 
		{
			x = -221.57, y = 42.61, z = -135.46, Type = 6,
			Tid = 
			{
				[14] = 2,
			},
		},
		[4] = 
		{
			x = -224.13, y = 42.66, z = -134.81, Type = 6,
			Tid = 
			{
				[14] = 2,
			},
		},
		[5] = 
		{
			x = -219.37, y = 42.58, z = -136.40, Type = 6,
			Tid = 
			{
				[14] = 2,
			},
		},
		[8] = 
		{
			x = -205.69, y = 41.84, z = -147.77, Type = 6,
			Tid = 
			{
				[34] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -213.55, posy = 45.81, posz = -184.86, rotx = 0.00, roty = 90.51, rotz = 0.00 },
	},

}
return MapInfo
