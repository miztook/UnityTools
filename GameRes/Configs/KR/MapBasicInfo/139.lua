local MapInfo = 
{
	MapType = 3,
	Remarks = "补给营地相位",
	TextDisplayName = "보급지",
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
		[11068] = 
		{
			[1] = { x = 92.50, y = 58.11, z = -182.72, name = "쿠차트 선봉대", level = 21, SortID = 46 },
		},
		[11069] = 
		{
			[1] = { x = 112.80, y = 56.69, z = -179.70, name = "쿠차트 약탈자", level = 21, SortID = 236 },
			[2] = { x = 92.00, y = 54.87, z = -163.10, name = "쿠차트 약탈자", level = 21, SortID = 237 },
		},
		[11002] = 
		{
			[1] = { x = 112.75, y = 56.95, z = -177.61, name = "망치 쿠차트", level = 21, SortID = 13 },
		},
	},
	Npc = 
	{
		[1001] = 
		{
			[1] = { x = 88.86, y = 53.75, z = -148.18, name = "다친 연합군 병사", SortID = 1 },
		},
		[1006] = 
		{
			[1] = { x = 85.39, y = 58.85, z = -190.32, name = "연합군 병사", SortID = 239 },
		},
		[1095] = 
		{
			[1] = { x = 117.42, y = 55.94, z = -191.12, name = "조나단", SortID = 33 },
		},
		[1103] = 
		{
			[1] = { x = 120.12, y = 55.80, z = -188.63, name = "엘리사 쿠벨", SortID = 38 },
		},
		[1098] = 
		{
			[1] = { x = 210.17, y = 67.94, z = -96.27, name = "로탈 중위", IsCanFind = 1, IconPath = "Common_Npc_013", Describe = "로탈 중위", SortID = 39, FunctionName = "명성" },
		},
	},
	Region = 
	{
		[2] = 
		{
			[152] = { x = 100.89, y = 59.90, z = -183.84, name = "守备营地", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[46] = 
		{
			x = 92.50, y = 58.11, z = -182.72, Type = 1,
			Tid = 
			{
				[11068] = 6,
			},
		},
		[236] = 
		{
			x = 112.80, y = 56.69, z = -179.70, Type = 1,
			Tid = 
			{
				[11069] = 3,
			},
		},
		[237] = 
		{
			x = 92.00, y = 54.87, z = -163.10, Type = 1,
			Tid = 
			{
				[11069] = 3,
			},
		},
		[13] = 
		{
			x = 112.75, y = 56.95, z = -177.61, Type = 1,
			Tid = 
			{
				[11002] = 4,
			},
		},
		[1] = 
		{
			x = 88.86, y = 53.75, z = -148.18, Type = 2,
			Tid = 
			{
				[1001] = 1,
			},
		},
		[239] = 
		{
			x = 85.39, y = 58.85, z = -190.32, Type = 2,
			Tid = 
			{
				[1006] = 2,
			},
		},
		[33] = 
		{
			x = 117.42, y = 55.94, z = -191.12, Type = 2,
			Tid = 
			{
				[1095] = 1,
			},
		},
		[38] = 
		{
			x = 120.12, y = 55.80, z = -188.63, Type = 2,
			Tid = 
			{
				[1103] = 1,
			},
		},
		[39] = 
		{
			x = 210.17, y = 67.94, z = -96.27, Type = 2,
			Tid = 
			{
				[1098] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
