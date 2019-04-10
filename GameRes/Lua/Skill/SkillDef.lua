
local EVENT_TYPE = 
	{
		GenerateActor = 1,	--生成Actor事件
		Animation = 2,   -- 动画事件
		Audio = 3,  -- 音效事件
		Judgement = 4,  -- 判定事件
		Skip = 5,  -- 跳转事件
		StopSkill = 6,  -- 技能终止事件
		SkillMove = 7, -- 技能移动
		StopMove = 8,  -- 技能移动终止
		CameraShake = 9,  			--震屏
		BlurEffect = 10,  			--屏幕模糊
		CameraTransform = 11, --摄像机效果
		AfterImage = 12, 				--幻影
		ScreenEffect = 13,			--屏幕效果，变色
		Cloak = 14,   -- 隐身
		SkillIndicator = 16,		--预警
		Mirages = 17,		--幻影
		GenerateKnifeLight = 18,		--刀光
		ResetTargetPos = 19,		--重设位置
		PopSkillName = 20,		-- 技能名弹出
		ActorBlur = 21,   -- 子物体屏幕模糊
		ContinuedTurn = 22,   -- 连续转向
		CameraEffect = 23,   -- BOSS屏幕EFFECT
		BulletTime = 24,   -- 子弹时间
		PopSkillTips = 25,   -- 副本技能信息
	}

local Idle_Skills =
 	{
		{119, 120},
		{121, 122},
		{123, 124},
		{125, 126},
		{149, 150},
	}

-- 采集胜利技能id，索引为职业id
local Gather_Successed_Skills =
	{
		127,
		128,
		129,
		130,
		140,
	}


return 
	{
		EVENT_TYPE = EVENT_TYPE,
		IdleSkills = Idle_Skills,
		GatherSuccessedSkills = Gather_Successed_Skills,
	}
