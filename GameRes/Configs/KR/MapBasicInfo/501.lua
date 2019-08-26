local MapInfo = 
{
	MapType = 1,
	Remarks = "大地图2",
	TextDisplayName = "아르카니아",
	Length = 600,
	Width = 600,
	NavMeshName = "World02.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world02.png",
	AssetPath = "Assets/Outputs/Scenes/World02.prefab",
	PKMode= 1,
	Monster = 
	{
		[202] = 
		{
			[1] = { x = 214.50, y = 68.86, z = -125.10, name = "어디 한번 쳐 봐!", level = 25, SortID = 1 },
			[2] = { x = 132.90, y = 58.06, z = -31.80, name = "어디 한번 쳐 봐!", level = 25, SortID = 2 },
			[3] = { x = 168.20, y = 62.66, z = -185.20, name = "어디 한번 쳐 봐!", level = 25, SortID = 3 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 214.50, y = 68.86, z = -125.10, Type = 1,
			Tid = 
			{
				[202] = 5,
			},
		},
		[2] = 
		{
			x = 132.90, y = 58.06, z = -31.80, Type = 1,
			Tid = 
			{
				[202] = 5,
			},
		},
		[3] = 
		{
			x = 168.20, y = 62.66, z = -185.20, Type = 1,
			Tid = 
			{
				[202] = 5,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
