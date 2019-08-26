local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·朱拉斯试炼者·普通",
	TextDisplayName = "주라스 수련자 - 보통",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn04_Zuras01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/JURAS_ARK",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD04.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn04_Zuras01.prefab",
	PKMode= 1,
	Monster = 
	{
		[23410] = 
		{
			[1] = { x = -0.34, y = 14.96, z = 85.34, name = "주라스 수련자", level = 45,IsBoss = true },
		},
		[23411] = 
		{
			[1] = { x = -11.26, y = 14.95, z = 82.57, name = "양전하", level = 22 },
		},
		[23412] = 
		{
			[1] = { x = 10.76, y = 14.95, z = 82.73, name = "음전하", level = 22 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[1] = { x = -0.93, y = 14.96, z = 68.54, name = "出场触发区域", worldId = 0, PkMode = 1 },
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
				[23410] = 1,
			},
		},
		[10] = 
		{
			x = -11.26, y = 14.95, z = 82.57, Type = 1,
			Tid = 
			{
				[23411] = 1,
			},
		},
		[11] = 
		{
			x = 10.76, y = 14.95, z = 82.73, Type = 1,
			Tid = 
			{
				[23412] = 1,
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
		[1] = { posx = -0.35, posy = 14.96, posz = 69.62, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[2] = { posx = -2.05, posy = 14.96, posz = 69.09, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[3] = { posx = 1.54, posy = 14.96, posz = 69.09, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = -3.71, posy = 14.96, posz = 68.72, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[5] = { posx = 3.03, posy = 14.96, posz = 68.69, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[6] = { posx = 1.18, posy = 14.98, posz = 75.67, rotx = 0.00, roty = 156.50, rotz = 0.00 },
	},

}
return MapInfo
