local MapInfo = 
{
	MapType = 2,
	Remarks = "远征·奇利恩的仆从·噩梦",
	TextDisplayName = "킬리언의 시종 - 악몽",
	Length = 512,
	Width = 512,
	NavMeshName = "Dungn02_Cave01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/BORN_CAVE",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/mapD02.png",
	AssetPath = "Assets/Outputs/Scenes/Dungn02_Cave01.prefab",
	PKMode= 1,
	Monster = 
	{
		[21402] = 
		{
			[1] = { x = -100.74, y = 43.69, z = 99.85, name = "킬리언의 시종", level = 59,IsBoss = true },
		},
	},
	Npc = 
	{
		[12000] = 
		{
			[1] = { x = -99.94, y = 43.68, z = 96.85, name = "케스타닉인" },
		},
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = -95.41, y = 45.49, z = 99.99, name = "BOSS区域", worldId = 0, BattleMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE", PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -100.74, y = 43.69, z = 99.85, Type = 1,
			Tid = 
			{
				[21402] = 1,
			},
		},
		[3] = 
		{
			x = -99.94, y = 43.68, z = 96.85, Type = 2,
			Tid = 
			{
				[12000] = 5,
			},
		},
		[2] = 
		{
			x = -113.39, y = 43.83, z = 106.18, Type = 4,
			Tid = 
			{
				[15] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -103.95, posy = 43.62, posz = 95.96, rotx = 0.00, roty = 103.20, rotz = 0.00 },
		[2] = { posx = -110.73, posy = 43.51, posz = 105.34, rotx = 0.00, roty = 99.79, rotz = 0.00 },
		[3] = { posx = -110.18, posy = 43.81, posz = 106.72, rotx = 0.00, roty = 99.79, rotz = 0.00 },
		[4] = { posx = -111.65, posy = 43.81, posz = 104.30, rotx = 0.00, roty = 99.79, rotz = 0.00 },
		[5] = { posx = -109.43, posy = 43.81, posz = 107.89, rotx = 0.00, roty = 99.79, rotz = 0.00 },
		[6] = { posx = -112.20, posy = 43.81, posz = 102.96, rotx = 0.00, roty = 99.79, rotz = 0.00 },
	},

}
return MapInfo
