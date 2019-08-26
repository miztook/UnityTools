local MapInfo = 
{
	MapType = 2,
	Remarks = "킬리언의 사형장 - 어려움",
	TextDisplayName = "킬리언의 사형장 - 어려움",
	Length = 512,
	Width = 512,
	NavMeshName = "Dn_evn03_Killerparty.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/KILLEEN_PARADISE",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/qilien.png",
	AssetPath = "Assets/Outputs/Scenes/Dn_evn03_Killerparty.prefab",
	PKMode= 1,
	Monster = 
	{
		[30026] = 
		{
			[1] = { x = 2.74, y = -0.40, z = 20.12, name = "카르니오스", level = 62,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[1] = 
		{
			[167] = { x = 2.53, y = -0.12, z = 124.31, xA = 2.40, yA = -0.24, zA = 52.80, name = "传送区域", worldId = 401, PkMode = 1 },
		},
		[2] = 
		{
			[168] = { x = 3.00, y = -0.66, z = 22.30, name = "集合区域", worldId = 0, PkMode = 1, CameraDistance = 15 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 2.74, y = -0.40, z = 20.12, Type = 1,
			Tid = 
			{
				[30026] = 1,
			},
		},
		[5] = 
		{
			x = 2.40, y = -1.16, z = 128.95, Type = 4,
			Tid = 
			{
				[9] = 0,
			},
		},
		[7] = 
		{
			x = 27.58, y = 9.57, z = 20.46, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[8] = 
		{
			x = -22.42, y = 9.57, z = 20.46, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[9] = 
		{
			x = 2.58, y = 9.57, z = 45.46, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
		[10] = 
		{
			x = 2.58, y = 9.57, z = -4.54, Type = 4,
			Tid = 
			{
				[13] = 0,
			},
		},
	},
	TargetPoint = 
	{
		[2] = { posx = 2.40, posy = -0.24, posz = 52.80, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[3] = { posx = -0.20, posy = 0.00, posz = -21.20, rotx = 0.00, roty = 0.00, rotz = 0.00 },
		[4] = { posx = 2.37, posy = 0.01, posz = 32.28, rotx = 0.00, roty = 180.00, rotz = 0.00 },
		[5] = { posx = -8.50, posy = 0.01, posz = 20.10, rotx = 0.00, roty = 0.00, rotz = 0.00 },
	},

}
return MapInfo
