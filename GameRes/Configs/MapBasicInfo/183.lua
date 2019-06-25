local MapInfo = 
{
	MapType = 3,
	Remarks = "",
	TextDisplayName = "魔法圆环",
	Length = 512,
	Width = 512,
	NavMeshName = "World04Part2.navmesh",
	BackgroundMusic = "BGM_Map_4/Map_4/Map_4_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Castle",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world04-2.png",
	AssetPath = "Assets/Outputs/Scenes/World04Part2.prefab",
	Monster = 
	{
		[13034] = 
		{
			[1] = { x = -211.01, y = 84.27, z = 60.46, name = "风之武者", level = 49, SortID = 2 },
		},
		[13035] = 
		{
			[1] = { x = -211.01, y = 84.27, z = 60.46, name = "风之祭司", level = 49, SortID = 2 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[309] = { x = -209.19, y = 84.24, z = 65.71, name = "魔法圆环", worldId = 0, IsCanFind = 1, PkMode = 0 },
		},
	},
	Mine = 
	{
		[424] = 
		{
			[1] = { x = -235.86, y = 82.74, z = 53.84 },
		},
	},
	Entity = 
	{
		[2] = 
		{
			x = -211.01, y = 84.27, z = 60.46, Type = 1,
			Tid = 
			{
				[13034] = 4,
				[13035] = 4,
			},
		},
		[1] = 
		{
			x = -235.86, y = 82.74, z = 53.84, Type = 6,
			Tid = 
			{
				[424] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 249.42, posy = 36.16, posz = -185.28, rotx = 0.00, roty = 269.67, rotz = 0.00 },
	},

}
return MapInfo
