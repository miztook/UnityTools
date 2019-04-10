local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "东部领地",
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
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = 185.73, y = 46.53, z = 24.27, name = "进入点", worldId = 0, PkMode = 0 },
			[2] = { x = 186.29, y = 121.94, z = 20.30, name = "更亮", worldId = 0, PkMode = 0 },
			[3] = { x = 173.80, y = 47.48, z = 1.20, name = "范围", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[585] = 
		{
			[1] = { x = 186.17, y = 42.35, z = 25.70 },
		},
	},
	Entity = 
	{
		[1] = 
		{
			x = 186.17, y = 42.35, z = 25.70, Type = 6,
			Tid = 
			{
				[585] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 186.17, posy = 41.99, posz = 25.70, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo