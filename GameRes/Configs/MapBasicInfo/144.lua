local MapInfo = 
{
	MapType = 3,
	Remarks = "废弃军营相位",
	TextDisplayName = "废弃军营",
	Length = 800,
	Width = 800,
	NavMeshName = "World03Part1.navmesh",
	BackgroundMusic = "BGM_Map_3/Map_3/Map_3_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Forest",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/world03-1.png",
	AssetPath = "Assets/Outputs/Scenes/World03Part1.prefab",
	Monster = 
	{
		[12007] = 
		{
			[1] = { x = -189.09, y = -4.18, z = -65.14, name = "迪波暗影", level = 30, SortID = 1 },
		},
		[12008] = 
		{
			[1] = { x = -189.09, y = -4.18, z = -65.14, name = "黑法师暗影", level = 30, SortID = 1 },
		},
	},
	Npc = 
	{
		[2002] = 
		{
			[1] = { x = -189.06, y = -4.18, z = -65.21, name = "迪波", SortID = 2 },
		},
		[2003] = 
		{
			[1] = { x = -184.70, y = -4.21, z = -61.62, name = "温妮莎·德佩拉", SortID = 3 },
		},
	},
	Region = 
	{
		[2] = 
		{
			[224] = { x = -182.77, y = 2.67, z = -64.63, name = "第二次相位区域", worldId = 0, PkMode = 0 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[1] = 
		{
			x = -189.09, y = -4.18, z = -65.14, Type = 1,
			Tid = 
			{
				[12007] = 1,
				[12008] = 4,
			},
		},
		[2] = 
		{
			x = -189.06, y = -4.18, z = -65.21, Type = 2,
			Tid = 
			{
				[2002] = 1,
			},
		},
		[3] = 
		{
			x = -184.70, y = -4.21, z = -61.62, Type = 2,
			Tid = 
			{
				[2003] = 1,
			},
		},
	},
	TargetPoint = 
	{
	},

}
return MapInfo