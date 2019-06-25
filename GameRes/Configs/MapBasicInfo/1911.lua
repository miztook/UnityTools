local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "帝国边境",
	Length = 800,
	Width = 800,
	NavMeshName = "World05.navmesh",
	BackgroundMusic = "",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/Map_Bg_019.png",
	AssetPath = "Assets/Outputs/Scenes/World05.prefab",
	Monster = 
	{
		[14069] = 
		{
			[1] = { x = 128.10, y = 15.53, z = 152.82, name = "不死骑士", level = 55, SortID = 1 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[438] = { x = 97.91, y = 62.78, z = -38.62, name = "声望无礼的挑战者", worldId = 0, PkMode = 0 },
			[439] = { x = 127.89, y = 18.83, z = 150.75, name = "声望边界", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 128.10, y = 15.53, z = 152.82, Type = 1,
			Tid = 
			{
				[14069] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -194.26, posy = 17.74, posz = -225.53, rotx = 0.00, roty = 139.21, rotz = 0.00 },
		[2] = { posx = 94.27, posy = 24.21, posz = -355.41, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = -219.57, posy = 17.74, posz = -307.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -133.07, posy = 17.74, posz = -330.56, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = 99.12, posy = 58.14, posz = -38.31, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[8] = { posx = -202.10, posy = 17.89, posz = -289.19, rotx = 0.00, roty = 215.75, rotz = 0.00 },
		[9] = { posx = -208.09, posy = 60.17, posz = 69.76, rotx = 0.00, roty = 180.00, rotz = 0.00 },
	},

}
return MapInfo
