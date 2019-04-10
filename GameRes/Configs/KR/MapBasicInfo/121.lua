local MapInfo = 
{
	MapType = 3,
	Remarks = "동부 가드 전용 던전01",
	TextDisplayName = "동부 가드 전용 던전01",
	Length = 576,
	Width = 576,
	NavMeshName = "World01.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world01.png",
	AssetPath = "Assets/Outputs/Scenes/World01.prefab",
	Monster = 
	{
		[20000] = 
		{
			[1] = { x = 122.44, y = 62.61, z = 122.96, name = "노예 선봉군", level = 10, SortID = 1 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[50] = { x = 215.05, y = 58.72, z = 127.41, name = "专属相位测试", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 122.44, y = 62.61, z = 122.96, Type = 1,
			Tid = 
			{
				[20000] = 5,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo
