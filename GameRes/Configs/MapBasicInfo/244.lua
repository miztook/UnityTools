local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·朱拉斯试炼者·噩梦",
	TextDisplayName = "朱拉斯试炼者·噩梦",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn04_Zuras01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/JURAS_ARK",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn04_Zuras01.prefab",
	Monster = 
	{
		[23420] = 
		{
			[1] = { x = -0.34, y = 14.96, z = 85.34, name = "朱拉斯试炼者", level = 60,IsBoss = true },
		},
		[23421] = 
		{
			[1] = { x = -11.26, y = 14.90, z = 82.57, name = "正电荷", level = 42 },
		},
		[23422] = 
		{
			[1] = { x = 10.76, y = 14.90, z = 82.73, name = "负电荷", level = 42 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -0.93, y = 14.96, z = 68.54, name = "出场触发区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[4] = 
		{
			x = -0.34, y = 14.96, z = 85.34, Type = 1,
			Tid = 
			{
				[23420] = 1,
			},
		},
		[10] = 
		{
			x = -11.26, y = 14.90, z = 82.57, Type = 1,
			Tid = 
			{
				[23421] = 1,
			},
		},
		[11] = 
		{
			x = 10.76, y = 14.90, z = 82.73, Type = 1,
			Tid = 
			{
				[23422] = 1,
			},
		},
		[1] = 
		{
			x = 0.00, y = 5.67, z = 1.88, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[2] = 
		{
			x = -10.51, y = 15.09, z = 62.95, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
		[3] = 
		{
			x = 10.51, y = 15.09, z = 62.63, Type = 4,
			Tid = 
			{
				[21] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -0.35, posy = 14.96, posz = 69.06, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[2] = { posx = -2.10, posy = 14.96, posz = 68.86, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = 1.53, posy = 14.96, posz = 68.83, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -3.83, posy = 14.96, posz = 68.70, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = 3.14, posy = 14.96, posz = 68.49, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = 1.18, posy = 14.98, posz = 75.67, rotx = 0.00, roty = 156.50, rotz = 0.00 },
	},

}
return MapInfo
