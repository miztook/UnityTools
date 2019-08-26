local cfg = {}

--[[ -- 配置数据格式 ---

cfg[职业ID] = 
{
	Face = {默认五官, asse t_path_id1, ..., asset_path_id8},
	Hair = {默认发型, asset_path_id1, ..., asset_path_id8},
	FaceCreate = {默认五官, asset_path_id1, ..., asset_path_id8},
	HairCreate = {默认发型, asset_path_id1, ..., asset_path_id8},
	SkinColor = {默认肤色, color1, ..., color8},
	HairColor = {默认发色, color1, ..., color8},
}

【说明】
-- 因为创建角色自定义外观的发型 脸型资源与游戏中用的不是一套，所以需要单独配置
-- 默认五官，默认发型 资源id均填0
-- 

]] 

-- 战士
cfg[1] = 
{
	Face = {"Assets/Outputs/Characters/Outward/Basic/humwarrior_mface.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face06.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face01.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face03.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face07.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face04.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face05.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/humwarrior_m_face02.prefab"},
	Hair = {"Assets/Outputs/Characters/Outward/Basic/humwarrior_mhair.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair01.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair02.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair03.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair04.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair05.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair06.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/humwarrior_m_hair07.prefab"},
	FaceCreate = {"", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face06.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face01.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face03.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face07.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face04.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face05.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/head/Humwarrior_m_create_face02.prefab"},
	HairCreate = {"", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair01.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair02.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair03.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair04.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair05.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair06.prefab", "Assets/Outputs/Characters/Outward/Human/Warrior/hair/Humwarrior_m_create_hair07.prefab"},
	SkinColor = {111, 113, 112, 114, 115, 116, 117, 118},
	HairColor = {101, 103, 102, 104, 105, 106, 107, 108},
	SkinIconColor = {1111, 1113, 1112, 1114, 1115, 1116, 1117, 1118},
	HairIconColor = {1101, 1103, 1102, 1104, 1105, 1106, 1107, 1108},
	FaceIcon = {"Head/Face_Human_001", "Head/Face_Human_002", "Head/Face_Human_003", "Head/Face_Human_004", "Head/Face_Human_005", "Head/Face_Human_006", "Head/Face_Human_007", "Head/Face_Human_008"},
	HairIcon = {"Head/Hair_Human_001", "Head/Hair_Human_002", "Head/Hair_Human_003", "Head/Hair_Human_004", "Head/Hair_Human_005", "Head/Hair_Human_006", "Head/Hair_Human_007", "Head/Hair_Human_008"},
}

-- 祭祀
cfg[2] = 
{
	Face = {"Assets/Outputs/Characters/Outward/Basic/alipriest_fface.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_face07.prefab"},
	Hair = {"Assets/Outputs/Characters/Outward/Basic/alipriest_fhair.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_hair07.prefab"},
	FaceCreate = {"", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/head/alipriest_f_create_face07.prefab"},
	HairCreate = {"", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Priest/hair/alipriest_f_create_hair07.prefab"},
	SkinColor = {211, 212, 213, 214, 215, 216, 217, 218},
	HairColor = {201, 202, 203, 204, 205, 206, 207, 208},
	SkinIconColor = {1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218},
	HairIconColor = {1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208},
	FaceIcon = {"Head/Face_Alipriest_001", "Head/Face_Alipriest_002", "Head/Face_Alipriest_006", "Head/Face_Alipriest_004", "Head/Face_Alipriest_005", "Head/Face_Alipriest_003", "Head/Face_Alipriest_007", "Head/Face_Alipriest_008"},
	HairIcon = {"Head/Hair_Alipriest_001", "Head/Hair_Alipriest_002", "Head/Hair_Alipriest_003", "Head/Hair_Alipriest_004", "Head/Hair_Alipriest_005", "Head/Hair_Alipriest_006", "Head/Hair_Alipriest_007", "Head/Hair_Alipriest_008"},
}

-- 刺客
cfg[3] = 
{
	Face = {"Assets/Outputs/Characters/Outward/Basic/casassassin_mface.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face01.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face02.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face03.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face04.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face05.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face06.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_face07.prefab"},
	Hair = {"Assets/Outputs/Characters/Outward/Basic/casassassin_mhair.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair01.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair02.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair03.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair04.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair05.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair06.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_hair07.prefab"},
	FaceCreate = {"", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face01.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face02.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face03.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face04.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face05.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face06.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/head/casassassin_m_create_face07.prefab"},
	HairCreate = {"", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair01.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair02.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair03.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair04.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair05.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair06.prefab", "Assets/Outputs/Characters/Outward/Castanic/Assassin/hair/casassassin_m_create_hair07.prefab"},
	SkinColor = {311, 312, 313, 314, 315, 316, 317, 318},
	HairColor = {301, 302, 303, 304, 305, 306, 307, 308},
	SkinIconColor = {1311, 1312, 1313, 1314, 1315, 1316, 1317, 1318},
	HairIconColor = {1301, 1302, 1303, 1304, 1305, 1306, 1307, 1308},
	FaceIcon = {"Head/Face_Castainc_001", "Head/Face_Castainc_002", "Head/Face_Castainc_003", "Head/Face_Castainc_004", "Head/Face_Castainc_005", "Head/Face_Castainc_006", "Head/Face_Castainc_007", "Head/Face_Castainc_008"},
	HairIcon = {"Head/Hair_Castainc_001", "Head/Hair_Castainc_002", "Head/Hair_Castainc_003", "Head/Hair_Castainc_004", "Head/Hair_Castainc_005", "Head/Hair_Castainc_006", "Head/Hair_Castainc_007", "Head/Hair_Castainc_008"},
}

-- 射手
cfg[4] = 
{
	Face = {"Assets/Outputs/Characters/Outward/Basic/sprarcher_fface.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face02.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face01.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face03.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face04.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face05.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face06.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_face07.prefab"},
	Hair = {"Assets/Outputs/Characters/Outward/Basic/sprarcher_fhair.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair02.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair01.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair03.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair04.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair05.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair06.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_hair07.prefab"},
	FaceCreate = {"", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face02.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face01.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face03.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face04.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face05.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face06.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/head/sprarcher_f_create_face07.prefab"},
	HairCreate = {"", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair02.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair01.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair03.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair04.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair05.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair06.prefab", "Assets/Outputs/Characters/Outward/Spirit/Archer/hair/sprarcher_f_create_hair07.prefab"},
	SkinColor = {411, 415, 413, 414, 412, 416, 417, 418},
	HairColor = {401, 403, 402, 404, 405, 406, 407, 408},
	SkinIconColor = {1411, 1415, 1413, 1414, 1412, 1416, 1417, 1418},
	HairIconColor = {1401, 1403, 1402, 1404, 1405, 1406, 1407, 1408},
	FaceIcon = {"Head/Face_HighElf_001", "Head/Face_HighElf_002", "Head/Face_HighElf_003", "Head/Face_HighElf_004", "Head/Face_HighElf_005", "Head/Face_HighElf_006", "Head/Face_HighElf_007", "Head/Face_HighElf_008"},
	HairIcon = {"Head/Hair_HighElf_001", "Head/Hair_HighElf_008", "Head/Hair_HighElf_003", "Head/Hair_HighElf_004", "Head/Hair_HighElf_005", "Head/Hair_HighElf_006", "Head/Hair_HighElf_007", "Head/Hair_HighElf_002"},
}

-- 枪骑士
cfg[5] = 
{
	Face = {"Assets/Outputs/Characters/Outward/Basic/alilancer_fface.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_face07.prefab"},
	Hair = {"Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair05.prefab", "Assets/Outputs/Characters/Outward/Basic/alilancer_fhair.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_hair07.prefab"},
	FaceCreate = {"", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/head/alilancer_f_create_face07.prefab"},
	HairCreate = {"", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair01.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair02.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair03.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair04.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair05.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair06.prefab", "Assets/Outputs/Characters/Outward/Aileen/Lancer/hair/alilancer_f_create_hair07.prefab"},
	SkinColor = {211, 212, 213, 214, 215, 216, 217, 218},
	HairColor = {201, 202, 203, 204, 205, 206, 207, 208},
	SkinIconColor = {1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218},
	HairIconColor = {1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208},
	FaceIcon = {"Head/Face_Alipriest_001", "Head/Face_Alipriest_002", "Head/Face_Alipriest_006", "Head/Face_Alipriest_004", "Head/Face_Alipriest_005", "Head/Face_Alipriest_003", "Head/Face_Alipriest_007", "Head/Face_Alipriest_008"},
	HairIcon = {"Head/Hair_Alipriest_007", "Head/Hair_Alipriest_002", "Head/Hair_Alipriest_003", "Head/Hair_Alipriest_004", "Head/Hair_Alipriest_005", "Head/Hair_Alipriest_006", "Head/Hair_Alipriest_001", "Head/Hair_Alipriest_008"},
}

return cfg
