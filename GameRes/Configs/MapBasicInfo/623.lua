local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "神造巨像",
	Length = 800,
	Width = 800,
	NavMeshName = "Dn_evn03_Killerparty.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/qilien.png",
	AssetPath = "Assets/Outputs/Scenes/Dn_evn03_Killerparty.prefab",
	PKMode= 1,
	Monster = 
	{
		[36023] = 
		{
			[1] = { x = 2.20, y = -0.40, z = 20.00, name = "神卫者三型", level = 60,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = 2.04, y = 39.53, z = 18.54, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = 2.20, y = -0.40, z = 20.00, Type = 1,
			Tid = 
			{
				[36023] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 2.20, posy = 0.00, posz = 153.00, rotx = 0.00, roty = 270.00, rotz = 0.00 },
	},

}
return MapInfo