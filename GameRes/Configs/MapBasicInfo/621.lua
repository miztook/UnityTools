local MapInfo = 
{
	MapType = 2,
	Remarks = "",
	TextDisplayName = "亡灵君主",
	Length = 800,
	Width = 800,
	NavMeshName = "Dn_evn03_Killerparty.navmesh",
	BackgroundMusic = "BGM_Map_1/Map_1/Map_1_phase",
	BattleMusic = "",
	EnvironmentMusic = "Zone_Ambience/Ambience/Dungeon",
	MiniMapAtlasPath = "Assets/Outputs/CommonAtlas/MiniMap/qilien.png",
	AssetPath = "Assets/Outputs/Scenes/Dn_evn03_Killerparty.prefab",
	Monster = 
	{
		[36021] = 
		{
			[1] = { x = 2.30, y = 0.00, z = 20.50, name = "不死骑士", level = 52,IsBoss = true },
		},
	},
	Npc = 
	{
	},
	Region = 
	{
		[2] = 
		{
			[192] = { x = 1.09, y = 39.53, z = 21.29, name = "镜头调整区域", worldId = 0, PkMode = 1 },
		},
	},
	Mine = 
	{
	},
	Entity = 
	{
		[13] = 
		{
			x = 2.30, y = 0.00, z = 20.50, Type = 1,
			Tid = 
			{
				[36021] = 1,
			},
		},
	},
	TargetPoint = 
	{
		[1] = { posx = 2.30, posy = 0.00, posz = 154.00, rotx = 0.00, roty = 270.00, rotz = 0.00 },
	},

}
return MapInfo
