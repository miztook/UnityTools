local MapInfo = 
{
	MapType = 4,
	Remarks = "",
	TextDisplayName = "신의 제단 보호",
	Length = 511,
	Width = 511,
	NavMeshName = "City01.navmesh",
	BackgroundMusic = "BGM_Dunjeon/Dunjeon/DUNJEON_BATTLE",
	BattleMusic = "",
	EnvironmentMusic = "",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/city01.png",
	AssetPath = "Assets/Outputs/Scenes/City01.prefab",
	Monster = 
	{
		[50005] = 
		{
			[1] = { x = 7.02, y = 185.74, z = -207.66, name = "어린 엘프", level = 10, SortID = 1 },
			[2] = { x = 6.05, y = 185.56, z = -188.48, name = "어린 엘프", level = 10, SortID = 3 },
			[3] = { x = 9.11, y = 185.56, z = -198.96, name = "어린 엘프", level = 10, SortID = 5 },
		},
		[50008] = 
		{
			[1] = { x = 7.02, y = 185.74, z = -207.66, name = "시칸 사제", level = 10, SortID = 1 },
			[2] = { x = 6.05, y = 185.56, z = -188.48, name = "시칸 사제", level = 10, SortID = 3 },
			[3] = { x = 9.11, y = 185.56, z = -198.96, name = "시칸 사제", level = 10, SortID = 5 },
		},
		[50006] = 
		{
			[1] = { x = -19.92, y = 185.56, z = -196.43, name = "시조새", level = 10, SortID = 2 },
			[2] = { x = -16.60, y = 185.56, z = -208.53, name = "시조새", level = 10, SortID = 4 },
			[3] = { x = -16.59, y = 185.45, z = -188.74, name = "시조새", level = 10, SortID = 6 },
			[4] = { x = -5.84, y = 185.56, z = -183.37, name = "시조새", level = 10, SortID = 8 },
		},
		[50007] = 
		{
			[1] = { x = -19.92, y = 185.56, z = -196.43, name = "시칸 병사", level = 10, SortID = 2 },
			[2] = { x = -16.60, y = 185.56, z = -208.53, name = "시칸 병사", level = 10, SortID = 4 },
			[3] = { x = -16.59, y = 185.45, z = -188.74, name = "시칸 병사", level = 10, SortID = 6 },
			[4] = { x = -5.84, y = 185.56, z = -183.37, name = "시칸 병사", level = 10, SortID = 8 },
		},
		[50009] = 
		{
			[1] = { x = -5.85, y = 185.56, z = -185.42, name = "시칸 대주교", level = 10, SortID = 7 },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[3] = { x = -5.81, y = 185.56, z = -199.25, name = "区域1", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = 7.02, y = 185.74, z = -207.66, Type = 1,
			Tid = 
			{
				[50005] = 5,
				[50008] = 5,
			},
		},
		[2] = 
		{
			x = -19.92, y = 185.56, z = -196.43, Type = 1,
			Tid = 
			{
				[50006] = 5,
				[50007] = 5,
			},
		},
		[3] = 
		{
			x = 6.05, y = 185.56, z = -188.48, Type = 1,
			Tid = 
			{
				[50005] = 5,
				[50008] = 5,
			},
		},
		[4] = 
		{
			x = -16.60, y = 185.56, z = -208.53, Type = 1,
			Tid = 
			{
				[50006] = 5,
				[50007] = 5,
			},
		},
		[5] = 
		{
			x = 9.11, y = 185.56, z = -198.96, Type = 1,
			Tid = 
			{
				[50005] = 5,
				[50008] = 5,
			},
		},
		[6] = 
		{
			x = -16.59, y = 185.45, z = -188.74, Type = 1,
			Tid = 
			{
				[50006] = 5,
				[50007] = 5,
			},
		},
		[7] = 
		{
			x = -5.85, y = 185.56, z = -185.42, Type = 1,
			Tid = 
			{
				[50009] = 1,
			},
		},
		[8] = 
		{
			x = -5.84, y = 185.56, z = -183.37, Type = 1,
			Tid = 
			{
				[50007] = 4,
				[50006] = 4,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = -5.78, posy = 185.56, posz = -202.57, rotx = 0.00, roty = 270.00, rotz = 0.00 },
	},

}
return MapInfo
