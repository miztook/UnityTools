local BEHAVIOR_TYPE = 
	{
		MOVE = 0,  -- 移动
		TURN = 1,   -- 转向
		JUMP = 2,  -- 跳劈
		DASH = 3,  -- 冲锋
		FOLLOW = 4,  -- 跟随
		ADSORB = 5,  -- 吸附
		
		JOYSTICK = 6, 
	}

local AI_STATE = 
	{
		IDLE = 0,
        INFIGHT = 1,
        GODLIKE = 2,
	}
	

local OBJ_TYPE =
    {
        NONE = -1,             	-- 未知
        HOSTPLAYER = 0,        	-- 主角
        ELSEPLAYER = 1,        	-- 其他玩家
        NPC = 2,               	-- NPC
        MONSTER = 3,           	-- 怪
        SUBOBJECT = 4,         	-- 子物体
        LOOT = 5,			   	-- 掉落物
        MINE = 6,              	-- 矿
        PET = 7,				-- 宠物
        PLAYERMIRROR = 8,		-- 玩家镜像
    }

local COLLIDE_ENTITY_TYPE =
    {
        ALL = 0,
        ONLYTARGET = 1,
        ENEMY = 2,
    }

return 
	{
		BEHAVIOR = BEHAVIOR_TYPE,
		AI_STATE = AI_STATE,
		OBJ_TYPE = OBJ_TYPE,
		COLLIDE_ENTITY_TYPE = COLLIDE_ENTITY_TYPE,
	}