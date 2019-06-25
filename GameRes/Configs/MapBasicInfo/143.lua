local MapInfo = 
{
	MapType = 3,
	Remarks = "奇袭罗琳镇",
	TextDisplayName = "奇袭罗琳镇",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Battle",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	Monster = 
	{
		[12025] = 
		{
			[1] = { x = 142.45, y = 36.93, z = 24.63, name = "第三军团术士", level = 35, SortID = 2 },
			[2] = { x = 24.84, y = 21.04, z = 42.35, name = "第三军团术士", level = 35, SortID = 5 },
		},
		[12024] = 
		{
			[1] = { x = 142.45, y = 36.93, z = 24.63, name = "第三军团剑士", level = 35, SortID = 2 },
			[2] = { x = 64.34, y = 21.03, z = -1.36, name = "第三军团剑士", level = 35, SortID = 3 },
		},
		[12026] = 
		{
			[1] = { x = 64.34, y = 21.03, z = -1.36, name = "第三军团千夫长", level = 35, SortID = 3 },
		},
		[12028] = 
		{
			[1] = { x = 24.84, y = 21.04, z = 42.35, name = "屠杀者", level = 35, SortID = 5 },
		},
		[12027] = 
		{
			[1] = { x = -65.11, y = 40.39, z = 64.80, name = "残暴尖刺蜘蛛", level = 35, SortID = 6 },
		},
	},
	Npc = 
	{
		[2046] = 
		{
			[1] = { x = 156.39, y = 39.90, z = 11.89, name = "罗琳镇反抗军", SortID = 80 },
		},
		[2039] = 
		{
			[1] = { x = 157.76, y = 39.88, z = 10.10, name = "夜莺", SortID = 1 },
		},
		[2111] = 
		{
			[1] = { x = -51.81, y = 40.46, z = 59.97, name = "“夜莺”", SortID = 7 },
		},
		[2054] = 
		{
			[1] = { x = -51.81, y = 40.46, z = 59.97, name = "沙摩尔", SortID = 7 },
		},
		[2055] = 
		{
			[1] = { x = -51.81, y = 40.46, z = 59.97, name = "露娜·艾琳", SortID = 7 },
		},
	},
	Region = 
	{
		[1] = 
		{
			[223] = { x = 0.58, y = 21.37, z = 31.35, xA = -30.71, yA = 38.34, zA = 51.38, name = "上山", worldId = 143, PkMode = 0 },
		},
		[2] = 
		{
			[222] = { x = 62.95, y = 33.65, z = 55.32, name = "罗琳镇相位入口", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
		[200] = 
		{
			[1] = { x = 58.94, y = 21.02, z = -6.96 },
		},
	},
	Entity = 
	{
		[2] = 
		{
			x = 142.45, y = 36.93, z = 24.63, Type = 1,
			Tid = 
			{
				[12025] = 3,
				[12024] = 5,
			},
		},
		[3] = 
		{
			x = 64.34, y = 21.03, z = -1.36, Type = 1,
			Tid = 
			{
				[12026] = 1,
				[12024] = 6,
			},
		},
		[5] = 
		{
			x = 24.84, y = 21.04, z = 42.35, Type = 1,
			Tid = 
			{
				[12028] = 1,
				[12025] = 5,
			},
		},
		[6] = 
		{
			x = -65.11, y = 40.39, z = 64.80, Type = 1,
			Tid = 
			{
				[12027] = 1,
			},
		},
		[80] = 
		{
			x = 156.39, y = 39.90, z = 11.89, Type = 2,
			Tid = 
			{
				[2046] = 4,
			},
		},
		[1] = 
		{
			x = 157.76, y = 39.88, z = 10.10, Type = 2,
			Tid = 
			{
				[2039] = 1,
			},
		},
		[7] = 
		{
			x = -51.81, y = 40.46, z = 59.97, Type = 2,
			Tid = 
			{
				[2111] = 1,
				[2054] = 1,
				[2055] = 1,
			},
		},
		[4] = 
		{
			x = 58.94, y = 21.02, z = -6.96, Type = 6,
			Tid = 
			{
				[200] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -30.71, posy = 38.34, posz = 51.38, rotx = 0.00, roty = 270.65, rotz = 0.00 },
	},

}
return MapInfo
