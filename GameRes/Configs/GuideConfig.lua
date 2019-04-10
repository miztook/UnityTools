-- 步骤
    -- EGuideID = 
    -- {
    --     Main_StartGame = -1,--开始游戏教学
    --     Main_Attack  = 2,
    --     Main_Skill  = 3,--升级后提示教学
    --     Main_Task  = 4, --副本开启后提示教学
    --     -- Trigger_GainNewSkill = 100,
    --     -- Trigger_LevelUp = 101,--升级后提示教学
    --     -- Trigger_DungeonOpen = 102, --副本开启后提示教学
    -- },

--触发类型

    -- EGuideBehaviourID= 
    -- {
    --     AutoNextGuide   			= -1,
    --     StartGame       			= 0,--开始游戏逻辑行为
    --     UseProp(道具ID)          = 1, --使用道具后逻辑行为
    --     FinishTask(任务ID)       = 2, --完成任务逻辑行为
    --     DungeonPass(通关ID)      = 3, --副本(进入)通关逻辑行为
    --     LevelUp(升级级别)        = 4, --升级逻辑行为
    --     OnClickBG      			= 5, --点击全屏背景行为
    --     OnClickTargetBtn			= 6, --点击指定按钮行为
    --     EnterRegion(区域ID)      = 7, --到达某个区域行为
    --     OnClickTargetList        = 8，--点击指定的列表行为
    --	   OnClickBlackBG      		= 9, --点击全屏黑色遮罩背景按钮行为
    --	   CGFinish      		    = 10, --CG播放结束后行为
    --	   KillMonster              = 11, --杀死某只怪的行为
    --     ReceiveTask(任务ID)      = 12, --接到任务逻辑行为
   	--     HPPercentLow(血条百分比低于)    = 13, --血量下降到百分比行为
   	--     HPPercentHigh(血条百分比高于)    = 14, --血量下降到百分比行为
   	--        WeakPotinIn       = 15, --进入破绽
    --    WeakPotinOut      = 16, --出破绽
    --    EnterFight             = 17, --进入战斗
    --    ServerCallBack(服务器触发的教学ID)         = 18, --服务器触发
    --        HawEye    = 19, --鹰眼开启行为
    --    Gather    = 20, --采集开启行为
    --      GatherFinish    = 21, --采集结束行为
    --    LeaveRegion(区域ID)      = 22, --离开某个区域行为
    --    OpenUI	   = 23, --打开某个界面
    --    FinishGuide  = 24, --完成某个教学
    --    BagCapacityLast  = 25, --背包超过剩余空间行为
    --	  CloseUI	   = 26, --关闭某个界面
    -- },

	-- [字段例子] = 
	-- { 
	--     --高亮按钮名称
	-- 	ShowHighLightButtonName = "Btn_SkillNormalAttack",
	       --路径
	--	ShowHighLightButtonPath = ShowHighLightButtonPath = "Panel_Main_MiniMap(Clone)/",
	-- 	--后弹出的界面一点要配置
	-- 	ShowUIPanelName = "",
	-- 	--是否强制点击
	-- 	IsClickLimit = false,
--[[	 是否强制某个地图
	 LimitMapID = 49--]]
	--  是否强制某个任务后
	--  LimitFinishQuestID = 49
	-- 是否强制某个等级
	-- LimitLevel = 10
	-- 	--是否黑屏
	-- 	IsShowBlackBG = false,
		--是否播放CG
	--	IsShowGuideCG = true,
	--  是否触发延迟
	--  IsTriggerDelay
	--  是否自适应触发延迟
	--  IsAutoEffectDelay
	    --是否有动画延迟
	--    IsAnimationDelay = true，
		--是否是记录点
	--	IsSave = true,
	--  是否有高亮区域
	--	IsHighLight = true,
	-- 	--触发标准--------------------------------
	    --最小显示时间
	--  MinShowTime = 1
	--  多长时间 自动下一步
	--AutoShowNextStepTime = 4，
	-- 	--下一步的触发行为
	-- 	NextStepTriggerBehaviour = 6,
	-- 	--触发行为参数(无参数默认为-1)
	-- 	NextStepTriggerParam = -1,

	-- 	--下一步的触发行为2
	-- 	NextStepTriggerBehaviour2 = 11,
	-- 	--触发行为参数(无参数默认为-1)
	-- 	NextStepTriggerParam2 = 10063,
		--符号 false 是 小于，true 是 大于
	--  TriggerParamSymbol = true
	--  LimitSpecialID = 1 --特殊处理 1、外观相关教学
	--  IsSkip = 1 为 右上，2 为 右下
 --    }
--教学打开界面触发 
-- local _OpenPlayUIs = 
-- {
-- 	"CPanelUIGuild",  =1
--  CPanelUIGuildList, = 2
--CPanelUIGuildSkill = 3,
--CPanelUIGuildDungeon = 4,
--  CPanelUIGuildPray, = 5
--  CPanelUIActivity = 8
--  CPanelFriendFight = 9
--  CPanelStrong = 10
--  CPanelUIExterior = 11
--	CPanelUIEquipProcess = 12,
-- }
local GuideCfg = 
{
	Main = 
	{
		
	},
	--以下是触发类型教学，哪个条件触发了 就提示哪种教学
	Trigger	=
	{
		[1] = 
		--签到引导
		{ 
			Id = 1,
			TriggerBehaviour = 2,
			TriggerParam = 143,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击商城图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn1",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				}
			}
		},
		[2] = 
		--声望任务引导
		{ 
			Id = 2,
			TriggerBehaviour = 2,
			TriggerParam = 12,
			--LimitFinishQuestID = 12,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开生涯界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F2",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开任务界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_4",
					ShowHighLightButtonPath = "UI_QuestList(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIQuestList",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--打开任务界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_GoReputationNpc",
					ShowHighLightButtonPath = "UI_QuestList(Clone)/Frame_Center/Frame_ElementReputation/Img_BG/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIQuestList",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--打开任务界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_Map(Clone)/Frame_Map/Frame_L/Frame_List/Mask2D/Viewport/Item1/",
					RegisterUI = "Item1",
					RegisterUIPath = "UI_Map(Clone)/Frame_Map/Frame_L/Frame_List/Mask2D/Viewport/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--打开任务界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Yes",
					ShowHighLightButtonPath = "UI_ReputationIntroduction(Clone)/Img_MsgBG/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelReputationIntroduction",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[3] = 
		--加入公会引导
		{ 
			Id = 3,
			TriggerBehaviour = 23,
			TriggerParam = 2,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				
			}
		},
		[4] = 
		--公会功能引导
		{ 
			Id = 4,
			TriggerBehaviour = 23,
			TriggerParam = 1,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开公会界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Guild_Bonus",
					ShowHighLightButtonPath = "UI_Guild(Clone)/TabGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIGuild",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--打开公会界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Guild_Info",
					ShowHighLightButtonPath = "UI_Guild(Clone)/TabGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIGuild",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--打开公会界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Guild_Member",
					ShowHighLightButtonPath = "UI_Guild(Clone)/TabGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIGuild",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				
			}
		},
		[5] = 
		--药水功能引导
		{ 
			Id = 5,
			TriggerBehaviour = 13,
			TriggerParam = 0.50,
			TriggerParamSymbol = false,
			--步骤
			Steps = 
			{
				[1] = 
				{
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Item",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Frame_Skill/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 14,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			NextStepTriggerParamSymbol = true,

				    NextStepTriggerBehaviour2 = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,
	    			AutoShowElement = "",
				}
			}
		},
		--（未同步）
		[6] = 
		--强化保底引导
		{ 
			Id = 6,
			TriggerBehaviour = 12,
			TriggerParam = 32002,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--点击菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[2] = 
				{
					--打开加工界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F5",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					 -- 是否有高亮区域
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					 -- 是否有高亮区域
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				
			}
		},
		--（未找到荣耀之路）
		[7] = 
		--冒险生涯引导
		{ 
			Id = 7,
			TriggerBehaviour = 2,
			TriggerParam = 11,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
					 -- 是否有高亮区域
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击福利引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn1",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开荣耀之路引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-1",
					ShowHighLightButtonPath = "UI_Welfare(Clone)/Frame_Center/Frame_Content/Frame_L/Frame_WelfareList/List_Type/List_MenuType/",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_MenuType",
					RegisterUIPath = "UI_Welfare(Clone)/Frame_Center/Frame_Content/Frame_L/Frame_WelfareList/List_Type/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIWelfare",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					 -- 是否有高亮区域
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[8] = 
		--公会技能引导
		{ 
			Id = 8,
			TriggerBehaviour = 23,
			TriggerParam = 3,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[9] = 
		--公会副本引导
		{ 
			Id = 9,
			TriggerBehaviour = 23,
			TriggerParam = 4,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[10] = 
		--万物志引导
		{ 
			Id = 10,
			TriggerBehaviour = 2,
			TriggerParam = 515,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开生涯界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F10",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开万物志界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_2",
					ShowHighLightButtonPath = "UI_Manual(Clone)/Frame_Center/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIManual",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			    --对话指引
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				
			}
		},
		[11] = 
		--神视引导
		{
			Id = 11,
			TriggerBehaviour = 19,
			TriggerParam = 3,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--技能UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Chk_Eye",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Tween_Eye/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[12] = 
		--天赋引导
		{ 
			Id = 12,
			TriggerBehaviour = 12,
			TriggerParam = 1109,

			--步骤
			Steps = 
			{
						    --对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开技能界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--选择天赋页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Soul",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--选择升级技能按钮--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Icon1",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_Center/Frame_Soul_C/Frame_Gift/Frame_Gift1/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--点击天赋升级引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_PointUp",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_SoulInfo/Frame_Adjust/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--点击天赋保存引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Save",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_SoulInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[9] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			    --对话指引
				[10] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			    --对话指引
				[11] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				
			}
		},
		[13] = 
		--签到引导（与Step1重复）
		{ 
			Id = 13,
			TriggerBehaviour = 2,
			TriggerParam = 999999,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--点击商城图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn1",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				}
			}
		},
		[14] = 
		--分解引导
		{ 
			Id = 14,
			TriggerBehaviour = 12,
			TriggerParam = 32025,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--背包按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Bag",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMainChat",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--打开分解引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Decompose",
					ShowHighLightButtonPath = "UI_RoleInfoNew(Clone)/Frame_All/Frame_Center/Frame_AllInfo/Page_Bag/Frame_BagBottom/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRoleInfo",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			IsAnimationDelay = true,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				--对话指引
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			    --对话指引
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},			   
				 --对话指引
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Filter",
					ShowHighLightButtonPath = "UI_RoleInfoNew(Clone)/Frame_All/Frame_Center/Frame_AllInfo/Page_Bag/Frame_DecomposeBottom/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRoleInfo",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},			    
				--对话指引
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				}
			}
		},
		[15] = 
		--巨龙匹配
		{
			Id = 15,
			TriggerBehaviour = 12,
			TriggerParam = 917,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--冒险日历引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[3] = 
				{
					--参加巨龙按钮引导--------------------------------
				    --高亮按钮名称
	    			ShowHighLightButtonName = "item-3",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/List_TimesActivityMenu/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_TimesActivityMenu",
					RegisterUIPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/",

					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 3,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--参加巨龙按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jion",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_ActivityRightDesc/Lay_Right/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--快捷匹配按钮引导--------------------------------按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_QuickJoin",
					ShowHighLightButtonPath = "UI_Dungeon(Clone)/Frame_Common/Frame_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIDungeon",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[16] = 
		--神视引导（大世界场景）
		{
			Id = 16,
			TriggerBehaviour = 99999,
			TriggerParam = 1,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--技能UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Chk_Eye",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Tween_Eye/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			NextStepTriggerParam = -1,
	    			NextStepTriggerBehaviour2 = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
				[2] = 
				{
					--技能UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Frame_MiniMap",
					ShowHighLightButtonPath = "Panel_Main_MiniMap(Clone)/Frame_Main/Img_MapBG/",
					RegisterUI = "Mask_Map",
					RegisterUIPath = "Panel_Main_MiniMap(Clone)/Frame_Main/Img_MapBG/Frame_MiniMap/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMinimap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			NextStepTriggerParam = -1,
	    			NextStepTriggerBehaviour2 = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
--[[	    			AutoShowElement = "",
	    			EffectScale = 1.2,--]]
				}
			}
		},
		-- [17] = 
		-- {
		-- 	Id = 17,
		-- 	--神视引导（与Step11重复）
		-- 	TriggerBehaviour = -1,
		-- 	TriggerParam = -1,
		-- 	--步骤
		-- 	Steps = 
		-- 	{
--[[				[1] = 
				{
					--技能UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Chk_Eye",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Tween_Eye/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}--]]
		-- 	}
		-- },
		[18] = 
		--月光庭院引导
		{ 
			Id = 18,
			TriggerBehaviour = 23,
			TriggerParam = 5,

			--步骤
			Steps = 
			{
				--对话指引
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
--[[					--是否高亮
					IsHighLight = true,--]]
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开公会界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Help",
					ShowHighLightButtonPath = "UI_Guild_Pray(Clone)/Frame_Center/Frame_Right/Img_BG/Frame_Icon/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIGuildPray",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[19] = 
		--1v1引导
		{
			Id = 19,
			TriggerBehaviour = 12,
			TriggerParam = 999999,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--冒险日历引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAutoEffectDelay = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] = 
				{
					--参加竞技按钮引导--------------------------------
				    --高亮按钮名称
	    			ShowHighLightButtonName = "item-1",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/List_TimesActivityMenu/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_TimesActivityMenu",
					RegisterUIPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					-- ShowHighLightButtonName = "Btn_Join",
					-- ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu/item-1/",

					-- --列表相关
					-- --ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					-- RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					-- RegisterUIPath = "",
					-- --显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    -- 			ShowUIPanelName = "CPanelCalendar",
					-- --是否强制
					-- IsClickLimit = true,
					-- --是否黑屏
					-- IsShowBlackBG = true,
	    -- 			--触发标准--------------------------------
	    -- 			--下一步的触发行为
	    -- 			NextStepTriggerBehaviour = 8,
	    -- 			--触发行为参数(无参数默认为-1)
	    -- 			NextStepTriggerParam = 1,
	    -- 			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    -- 			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--参加竞技按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jion",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_ActivityRightDesc/Lay_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					--RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					--RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--匹配按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Charge1",
					ShowHighLightButtonPath = "UI_MirrorArena(Clone)/Frame_All/Frame_Center/Frame_Right/Frame_1V1/Frame_1V1Info/Frame_Charge1V1/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMirrorArena",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[20] = 
		--飞翼引导
		{
			Id = 20,
			TriggerBehaviour = 2,
			TriggerParam = 999999,
			--特殊处理 1、外观相关教学
			LimitSpecialID = 1,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--系统功能菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[3] = 
				{
					--点击外观引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F4",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--选择飞翼页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Main_3",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Rdo_MainGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    --是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--飞翼列表UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "List_Wing",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_3/Frame_Left_Wing/View_Wing/ViewPort/",
					RegisterUI = "List_Wing",
					RegisterUIPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_3/Frame_Left_Wing/View_Wing/ViewPort/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    --是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "item-0",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--穿戴UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Operate",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_3/Frame_Right_Wing/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior", 
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- --是否界面有动画延迟
				    -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[21] = 
		--神视引导（打开地图）
		{
			Id = 21,
			TriggerBehaviour = 2,
			TriggerParam = 32030,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
				    --高亮按钮名称
					ShowHighLightButtonName = "Mask_Map",
					ShowHighLightButtonPath = "Panel_Main_MiniMap(Clone)/Frame_Main/Img_MapBG/Frame_MiniMap/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMinimap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_EyeRegionCount",
					ShowHighLightButtonPath = "UI_Map(Clone)/Frame_Map/Frame_Tip/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--IsAutoEffectDelay = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Close",
					ShowHighLightButtonPath = "UI_EyeRegionIntroduction(Clone)/Img_BG/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelEyeRegionIntroduction",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_EyeEntrance414",
					ShowHighLightButtonPath = "UI_Map(Clone)/Frame_Map/Img_Map/Icon/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,

			    	NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
			}
		},
		[22] = 
		--冠军竞技（第一次打开冠军竞技）
		{
			Id = 22,
			TriggerBehaviour = 23,
			TriggerParam = 7,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
					RegisterUI = "",
					RegisterUIPath = "",
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
                    --是否高亮
					IsHighLight = true,
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--竞技商店按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Shop",
					ShowHighLightButtonPath = "UI_MirrorArena(Clone)/Frame_All/Frame_Center/Frame_Bottom/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
					RegisterUI = "",
					RegisterUIPath = "",
	    			ShowUIPanelName = "CPanelMirrorArena",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
				    NextStepTriggerBehaviour2 = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[23] = 
		--背包提示（非强制引导，第一次背包容量达到90%出现）
		{
			Id = 23,
			TriggerBehaviour = 25,
			TriggerParam = 0.9,
			TriggerParamSymbol = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--竞技商店按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Bag",
					ShowHighLightButtonPath = "UI_Main_Chat(Clone)/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
					RegisterUI = "",
					RegisterUIPath = "",
	    			ShowUIPanelName = "CPanelMainChat",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				},
			}
		},
		[24] = 
		--好友助战
		{
			Id = 24,
			TriggerBehaviour = 23,
			TriggerParam = 9,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[25] = 
		--好友助战
		{
			Id = 25,
			TriggerBehaviour = 23,
			TriggerParam = 10,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 2,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[30] = 
		--教学第8步 发射弩箭
		{
			Id = 30,
			TriggerBehaviour = 18,
			TriggerParam = 30,
			--步骤
			Steps = 
			{
				[1] = 
				{
								    --高亮按钮名称
					ShowHighLightButtonName = "Btn_SkillNormalAttack",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Frame_Skill/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",

					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
					NextStepTriggerBehaviour = 6,
					NextStepTriggerParam = -1,
--[[				    NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,--]]
	    			AutoShowElement = "",
				},
			}
		},
		[32] = 
		--支线教学
		{
			Id = 32,
			TriggerBehaviour = 26,
			TriggerParam = 12,
			LimitFinishQuestID = 130,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-1",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Quest/Content/",
					RegisterUI = "List_Quest",
					RegisterUIPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
--[[	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 2,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 225,--]]
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "Content/item-0",
				}
			}
		},
		[33] = 
		--教学第12步 任务寻路3引导
		{
			Id = 33,
			TriggerBehaviour = 18,
			TriggerParam = 33,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Item",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Dungeon/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
                 --    --是否有动画延迟
	                -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    				    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 33,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "",
				}
			}
		},
		[101] = 
		--教学第1步 移动引导
		{ 
			Id = 101,
			TriggerBehaviour = 18,
			TriggerParam = 1,
			LimitMapID = 1208,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--场景位置引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Joystick",
					ShowHighLightButtonPath = "Panel_Main_Move(Clone)/Panel_Main_Move/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRocker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[102] = 
		--教学第2步 普通攻击引导
		{
			Id = 102,
			TriggerBehaviour = 18,
			TriggerParam = 2,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--普攻UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_SkillNormalAttack",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					RegisterUI = "",
					RegisterUIPath = "",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 40022,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[103] = 
		--教学第3步 使用技能引导
		{
			Id = 103,
			TriggerBehaviour = 18,
			TriggerParam = 3,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--技能UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_SkillConventional1",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					RegisterUI = "",
					RegisterUIPath = "",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 40018,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[104] = 
		--教学第4步 任务寻路引导
		{
			Id = 104,
			TriggerBehaviour = 18,
			TriggerParam = 4,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Item",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Dungeon/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
                 --    --是否有动画延迟
	                -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    				    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 4,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "",
				}
			}
		},
		[105] = 
		--教学第5步 闪避引导
		{
			Id = 105,
			TriggerBehaviour = 18,
			TriggerParam = 70,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--闪避UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_JumpSkill",
					ShowHighLightButtonPath = "UI_BeginnerDungeonBoss(Clone)/Frame_JumpGuide/GUIPanel/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIBeginnerDungeonBoss",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 70,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[106] = 
		--教学第6步 任务寻路2引导
		{
			Id = 106,
			TriggerBehaviour = 18,
			TriggerParam = 6,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Item",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Dungeon/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
                 --    --是否有动画延迟
	                -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    				    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 6,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "",
				}
			}
		},
		[107] = 
		--教学第7步 新手弩车引导
		{
			Id = 107,
			TriggerBehaviour = 20,
			TriggerParam = 22,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--采集UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Talk",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Tween_Talk/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 21,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 22,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[108] = 
		--教学第9步 闪避2引导
		{
			Id = 108,
			TriggerBehaviour = 18,
			TriggerParam = 8,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--闪避UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jump",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Frame_Skill/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 18,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 8,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
				}
			}
		},
		[109] = 
		--教学第10步 破绽引导
		{
			Id = 109,
			TriggerBehaviour = 18,
			TriggerParam = 9,

			--步骤
			Steps = 
			{
				[1] = 
				{
								    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Item",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Frame_Skill/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",

					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
					NextStepTriggerBehaviour = 18,
					NextStepTriggerParam = 9,

				    NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 40019,
	    			AutoShowElement = "",
				}
			}
		},
		[110] = 
		--教学第11步 锁定敌人引导
		{
			Id = 110,
			TriggerBehaviour = 18,
			TriggerParam = 10,

			--步骤
			Steps = 
			{
				[1] = 
				{
								    --高亮按钮名称
					ShowHighLightButtonName = "Btn_ChangeTarget",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/Frame_Skill/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",

					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
					NextStepTriggerBehaviour = 6,
					NextStepTriggerParam = -1,

				    NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 40029,
	    			AutoShowElement = "",
				},
			}
		},
		[111] = 
		--点击任务导航
		{
			Id = 111,
			TriggerBehaviour = 7,
			TriggerParam = 94,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Quest/Content/",
					RegisterUI = "List_Quest",
					RegisterUIPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/",

					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 2,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 504,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "Content/item-0",
				}
			}
		},
		[112] = 
		--背包引导
		{
			Id = 112,
			TriggerBehaviour = 2,
			TriggerParam = 504,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
					RegisterUI = "",
					RegisterUIPath = "",
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--背包按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Bag",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
					RegisterUI = "",
					RegisterUIPath = "",
	    			ShowUIPanelName = "CPanelMainChat",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--背包物品选中--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_RoleInfoNew(Clone)/Frame_All/Frame_Center/Frame_AllInfo/Page_Bag/Frame_BagItemList/View_Item1/RectMask/List_Item1/",
					RegisterUI = "List_Item1",
					RegisterUIPath = "UI_RoleInfoNew(Clone)/Frame_All/Frame_Center/Frame_AllInfo/Page_Bag/Frame_BagItemList/View_Item1/RectMask/",

					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRoleInfo",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1) 点击的INDEX
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--装备穿戴--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Item1",
					ShowHighLightButtonPath = "UI_EquipHint(Clone)/Scroll/Lay_Button/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelEquipHint",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    --是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,	
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
			    },
			    [5] = 
				{
					--返回主界面--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Back",
					ShowHighLightButtonPath = "UI_RoleInfoNew(Clone)/Frame_All/Frame_Title_2/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRoleInfo",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,	

	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Back",
					IsSkip = 1,  -- 1右上  2右下
			    }
			}
		},
		[113] = 
		--追踪引导
		{
			Id = 113,
			TriggerBehaviour = 12,
			TriggerParam = 225,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--任务UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/List_Quest/Content/",
					RegisterUI = "List_Quest",
					RegisterUIPath = "Panel_Main_QuestN(Clone)/Frame_Main/Frame_Lists/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelTracker",
					--是否强制
					IsClickLimit = false,
					--是否黑屏
					IsShowBlackBG = false,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour2 = 2,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = 225,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			--AutoShowElement = "Content/item-0",
				}
			}
		},
		[114] = 
		--技能升级引导
		{
			Id = 114,
			TriggerBehaviour = 2,
			TriggerParam = 241,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开技能界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--选择技能引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Skill2",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_Center/Frame_Skill/SkillGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--升级技能引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_UpgradeSkill",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_SkillInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[115] = 
		--自動戰鬥引导
		{
			Id = 115,
			TriggerBehaviour = 18,
			TriggerParam = 11,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--高亮按钮名称
					ShowHighLightButtonName = "Tog_AutoFight",
					ShowHighLightButtonPath = "Panel_Main_SkillNew(Clone)/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSkillSlot",

					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					
	    			--触发标准--------------------------------
	    			--下一步的触发行为
					NextStepTriggerBehaviour = 6,
					NextStepTriggerParam = -1,

				    NextStepTriggerBehaviour2 = 11,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,
	    			AutoShowElement = "",
				},
			}
		},
		[116] = 
		--坐骑引导
		{
			Id = 116,
			TriggerBehaviour = 2,
			TriggerParam = 196,
			--特殊处理 1、外观相关教学
			LimitSpecialID = 1,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--系统功能菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] = 
				{
					--坐骑UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F4",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--坐骑UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_1/Frame_Left_Ride/View_Ride/ViewPort/List_Ride/",
					RegisterUI = "List_Ride",
					RegisterUIPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_1/Frame_Left_Ride/View_Ride/ViewPort/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				--还不能得到坐骑，调整后可以打开
				[6] = 
				{
					--坐骑UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Launch",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_1/Frame_Right_Ride/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior", 
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- --是否界面有动画延迟
				    -- IsAnimationDelay = true,
		    		--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--坐骑UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Back",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Title_1/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior", 
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- --是否界面有动画延迟
				    -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--坐骑UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Ride",
					ShowHighLightButtonPath = "Panel_Main_Move(Clone)/Panel_Main_Move/Joystick/Img_BG/Img_Pole/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelRocker", 
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    --是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--是否高亮
					--IsHighLight = true,
					--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,

			    	NextStepTriggerBehaviour2 = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam2 = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Ride",
					IsSkip = 1,  -- 1右上  2右下
				}
			}
		},
		[117] = 
		--技能专精引导
		{
			Id = 117,
			TriggerBehaviour = 2,
			TriggerParam = 912,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开技能界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--选择专精页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Prof",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--选择专精引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "SkillProf_1",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_Center/Frame_Prof/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--升级引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_UpgradeProf",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_ProfInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[118] = 
		--遗迹引导
		{
			Id = 118,
			TriggerBehaviour = 12,
			TriggerParam = 125,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--冒险日历引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] = 
				{
					--参加遗迹引导--------------------------------
				    --高亮按钮名称
	    			ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/List_TimesActivityMenu/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_TimesActivityMenu",
					RegisterUIPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--参加遗迹按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jion",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_ActivityRightDesc/Lay_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					--RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					--RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
	    			ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_Dungeon(Clone)/Frame_Content/Frame_Center/Frame_DungeonList/View_Dungeon/ViewPort/List_Dungeon/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_Dungeon",
					RegisterUIPath = "UI_Dungeon(Clone)/Frame_Content/Frame_Center/Frame_DungeonList/View_Dungeon/ViewPort/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIDungeon",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--进入遗迹按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Enter",
					ShowHighLightButtonPath = "UI_Dungeon(Clone)/Frame_Content/Frame_Center/Frame_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIDungeon",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[119] = 
		--加工引导
		{
			Id = 119,
			TriggerBehaviour = 2,
			TriggerParam = 130,
			--是否是记录点
			IsSave = true,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
		    		--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--快捷使用引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Use",
					ShowHighLightButtonPath = "UI_QuickUse(Clone)/Frame_Tween/Frame_QuickUse/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIQuickUse",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},	
				[4] = 
				{
					--系统功能菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[5] = 
				{
					--点击加工图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F5",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--点击装备图标引导--------------------------------
				    --高亮按钮名
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_EquipProcess(Clone)/Frame_Center/Frame_R/Frame_Package /View_Package/RectMask/List_Item/",
					RegisterUI = "List_Item",
					RegisterUIPath = "UI_EquipProcess(Clone)/Frame_Center/Frame_R/Frame_Package /View_Package/RectMask/",
					--RegisterUI = "UI_EquipProcess(Clone)/Frame_Center/Frame_Package/View_Package/RectMask/List_Item",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIEquipProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--点击材料图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_EquipProcess(Clone)/Frame_Center/Frame_R/Frame_Package /View_Package/RectMask/List_Item/",
					RegisterUI = "List_Item",
					RegisterUIPath = "UI_EquipProcess(Clone)/Frame_Center/Frame_R/Frame_Package /View_Package/RectMask/",
					--RegisterUI = "UI_EquipProcess(Clone)/Frame_Center/Frame_Package /View_Package/RectMask/List_Item",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIEquipProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--点击强化按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Fortify",
					ShowHighLightButtonPath = "UI_EquipProcess(Clone)/Frame_Center/Frame_Fortify/Frame_B/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIEquipProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					--IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[120] = 
		--飞翼强化引导
		{
			Id = 120,
			TriggerBehaviour = 2,
			TriggerParam = 2050,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--系统功能菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] = 
				{
					--点击外观引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F6",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--点击加成引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Attribute",
					ShowHighLightButtonPath = "UI_Wing(Clone)/Frame_Develop/Frame_MidR_Develop/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIWing",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		--（商城功能未完成）
		[121] = 
		--商城抽奖引导
		{
			Id = 121,
			TriggerBehaviour = 2,
			TriggerParam = 39,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
				},
				[3] = 
				{
					--点击商城图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn4",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] =
				{
					--选择召唤页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-3",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_TopMenu/Src_MenuList/Viewport/List_BigMenu/",
					RegisterUI = "List_BigMenu",
					RegisterUIPath = "UI_Mall(Clone)/Frame_TopMenu/Src_MenuList/Viewport/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 3,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
				},
				[6] = 
				{
					--点击单抽一次引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_ElfOne",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_Center/Frame_Content/Page_MallElf(Clone)/Frame_Elf/Frame_Summon/Frame_One/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[122] = 
		--技能纹章引导
		{
			Id = 122,
			TriggerBehaviour = 2,
			TriggerParam = 59,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开技能界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--选择纹章页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Tab_Rune",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--选择技能引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Skill1",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_Center/Frame_Skill/SkillGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_U",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--选择纹章页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Rune1",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_RuneInfo/RuneGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--装配引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_UnLock",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_RuneInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--装配引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_ConfigRune",
					ShowHighLightButtonPath = "UI_Skill(Clone)/Frame_All/Frame_R/Frame_RuneInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUISkill",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[123] = 
		--传送引导
		{
			Id = 123,
			TriggerBehaviour = 12,
			TriggerParam = 902,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击小地图引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Mask_Map",
					ShowHighLightButtonPath = "Panel_Main_MiniMap(Clone)/Frame_Main/Img_MapBG/Frame_MiniMap/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMinimap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},	
				[3] = 
				{
					--点击世界地图引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Toggle",
					ShowHighLightButtonPath = "UI_Map(Clone)/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--点击好望港图标--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_City110",
					ShowHighLightButtonPath = "UI_Map(Clone)/Frame_WorldMap/CityGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMap",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				-- [5] = 
				-- {
				-- 	--点击确认引导--------------------------------
				--     --高亮按钮名称
				-- 	ShowHighLightButtonName = "Btn_Yes",
				-- 	ShowHighLightButtonPath = "UI_MessageBox(Clone)/Frame/",
				-- 	--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	   --  			ShowUIPanelName = "CMsgBoxPanel",
				-- 	--是否强制
				-- 	IsClickLimit = true,
				-- 	--是否黑屏
				-- 	IsShowBlackBG = true,
	   --  			--触发标准--------------------------------
	   --  			--下一步的触发行为
	   --  			NextStepTriggerBehaviour = 6,
	   --  			--触发行为参数(无参数默认为-1)
	   --  			NextStepTriggerParam = -1,
	   --  			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	   --  			AutoShowElement = "",
				-- },
			}
		},
		[124] = 
		--查看淬火引导
		{
			Id = 124,
			TriggerBehaviour = 12,
			TriggerParam = 188,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开加工界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F5",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--点击重铸页签--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Recast",
					ShowHighLightButtonPath = "UI_EquipProcess(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--RegisterUI = "UI_EquipProcess(Clone)/Frame_Center/Frame_Package/View_Package/RectMask/List_Item",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIEquipProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAutoEffectDelay = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[8] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
			}
		},
		--（商城功能未完成）
		[125] = 
		--商城抽奖引导
		{
			Id = 125,
			TriggerBehaviour = 2,
			TriggerParam = 1056,

			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击商城图标引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn4",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] =
				{
					--选择召唤页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-3",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_TopMenu/Src_MenuList/Viewport/List_BigMenu/",
					RegisterUI = "List_BigMenu",
					RegisterUIPath = "UI_Mall(Clone)/Frame_TopMenu/Src_MenuList/Viewport/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 3,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--选择召唤页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-1",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_Center/Frame_MenuBG/TabList/Viewport/Content/",
					RegisterUI = "TabList",
					RegisterUIPath = "UI_Mall(Clone)/Frame_Center/Frame_MenuBG/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--点击单抽一次引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_PetOne",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_Center/Frame_Content/Page_MallPetEgg(Clone)/Frame_Pet/Frame_Click/Frame_One/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_MallLottery(Clone)/Frame_Center/Frame_List/List_Items/",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_Items",
					RegisterUIPath = "UI_MallLottery(Clone)/Frame_Center/Frame_List/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMallLottery",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},	
				[8] = 
				{
					--点击返回按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Back",
					ShowHighLightButtonPath = "UI_Mall(Clone)/Frame_Title/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelMall",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Back",
					IsSkip = 1,  -- 1右上  2右下
				},	
			}
		},
		[126] = 
		--查看宠物引导
		{
			Id = 126,
			TriggerBehaviour = 24,
			TriggerParam = 125,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[3] = 
				{
					--打开技能界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F7",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--打开宠物培养引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Cultivate",
					ShowHighLightButtonPath = "UI_PetProcess(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIPetProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--打开宠物培养引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Advance",
					ShowHighLightButtonPath = "UI_PetProcess(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIPetProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--打开宠物重置引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Recast",
					ShowHighLightButtonPath = "UI_PetProcess(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIPetProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[10] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- 是否有高亮区域
				    IsHighLight = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[127] = 
		--神符引导
		{
			Id = 127,
			TriggerBehaviour = 2,
			TriggerParam = 2030,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--点击展开菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开神符界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F8",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[7] = 
				{
					--选择神符引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Charm_0",
					ShowHighLightButtonPath = "UI_CharmNew(Clone)/Frame_Center/Frame_CC/Frame_Charm/Tab_Left/Tab_CharmPages/Tab_CharmPage1/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCharm",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--选择专精引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "item-0",
					ShowHighLightButtonPath = "UI_CharmNew(Clone)/Frame_Center/Frame_R/Tab_HaveCharm/Frame_Package/View_Package/RectMask/List_CharmList/",
					RegisterUI = "List_CharmList",
					RegisterUIPath = "UI_CharmNew(Clone)/Frame_Center/Frame_R/Tab_HaveCharm/Frame_Package/View_Package/RectMask/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCharm",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 0,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--镶嵌引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Item1",
					ShowHighLightButtonPath = "UI_CharmItemHint(Clone)/Scroll/Lay_Button/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCharmItemHint",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
--[[				[10] = 
				{
					--点击吞噬引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_BtnCompose",
					ShowHighLightButtonPath = "UI_CharmNew(Clone)/Frame_Tabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCharm",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[11] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--MinShowTime = 1,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		}--]]
				
			}
		},
        [128] = 
		--业绩引导（领取任务131）
		{
            Id = 128,
			TriggerBehaviour = 2,
			TriggerParam = 131,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--活动菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn2",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
	    	}
		},
		[129] = 
		--活跃度引导（完成任务23）
		{
			Id = 129,
			TriggerBehaviour = 2,
			TriggerParam = 150,
			--IsTriggerDelay = true,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--活动菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn2",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[3] = 
				{
				    --高亮按钮名称
					ShowHighLightButtonName = "MenuBtn2",
					ShowHighLightButtonPath = "UI_Activity(Clone)/Window/MenuRoot/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIActivity",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					-- 是否有高亮区域
				    IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
	    		},
	    	}
		},
		[130] = 
		--时装引导（完成任务611）
		{
			Id = 130,
			TriggerBehaviour = 23,
			TriggerParam = 11,
			LimitFinishQuestID = 611,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--选择时装页签引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Main_2",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Rdo_MainGroup/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    --是否界面有动画延迟
				    IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--穿戴UE引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Addition",
					ShowHighLightButtonPath = "UI_Exterior(Clone)/Frame_TweenMan/Frame_Center/Frame_2/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIExterior", 
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
				    -- --是否界面有动画延迟
				    -- IsAnimationDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[131] = 
		--每日任务引导（到达22级后）
		{
			Id = 131,
			TriggerBehaviour = 23,
			TriggerParam = 8,
			LimitLevel = 22,
			--步骤
			Steps = 
			{
				[1] = 
				{
				    --高亮按钮名称
					ShowHighLightButtonName = "MenuBtn3",
					ShowHighLightButtonPath = "UI_Activity(Clone)/Window/MenuRoot/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIActivity",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[4] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[132] = 
		--宠物技能
		{
			Id = 132,
			TriggerBehaviour = 2,
			TriggerParam = 2012,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--系统功能菜单引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Open",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 2,  -- 1右上  2右下
				},	
				[4] = 
				{
					--点击宠物引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_F7",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Panel/FrameFloat/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_bg/Img_Icon",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--打开宠物技能引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_Skill",
					ShowHighLightButtonPath = "UI_PetProcess(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelUIPetProcess",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,

	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否高亮
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[134] = 
		--精英狩猎
		{
			Id = 134,
			TriggerBehaviour = 12,
			TriggerParam = 912,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--冒险日历引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开日常活动界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_4",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--参加狩猎按钮引导--------------------------------
				    --高亮按钮名称
	    			ShowHighLightButtonName = "item-1",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/List_TimesActivityMenu/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_TimesActivityMenu",
					RegisterUIPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--参加狩猎按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jion",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_ActivityRightDesc/Lay_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					--RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					--RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[7] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelWorldBoss",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsAnimationDelay = true,
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[8] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					IsHighLight = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[9] = 
				{
					--参加狩猎按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_FindBoss",
					ShowHighLightButtonPath = "UI_WorldBoss(Clone)/Frame_Content/Frame_R/Frame_BossInfo/",
					RegisterUI = "",
					RegisterUIPath = "",
					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					--RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					--RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelWorldBoss",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
			}
		},
		[135] = 
		--悬赏任务
		{
			Id = 135,
			TriggerBehaviour = 12,
			TriggerParam = 1123,
			--步骤
			Steps = 
			{
				[1] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					MinShowTime = 2.4,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = -1,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[2] = 
				{
					--指引对话--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "",
					ShowHighLightButtonPath = "",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 9,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
					IsSkip = 1,  -- 1右上  2右下
				},
				[3] = 
				{
					--冒险日历引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn3",
					ShowHighLightButtonPath = "UI_SystemEntrance(Clone)/Frame_Main/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelSystemEntrance",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
		    		--是否是记录点
					--IsSave = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "Img_Icon",
					IsSkip = 2,  -- 1右上  2右下
				},
				[4] = 
				{
					--打开日常活动界面引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Rdo_4",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_TopTabs/",
					RegisterUI = "",
					RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
					--是否自适应触发延迟
					IsAutoEffectDelay = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[5] = 
				{
					--参加狩猎按钮引导--------------------------------
				    --高亮按钮名称
	    			ShowHighLightButtonName = "item-3",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/List_TimesActivityMenu/",

					--列表相关
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					RegisterUI = "List_TimesActivityMenu",
					RegisterUIPath = "UI_Calendar(Clone)/Frame_Center/Frame_TimesActivity/Img_TimesActivityBG/List_Activity/",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 8,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = 3,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				},
				[6] = 
				{
					--参加狩猎按钮引导--------------------------------
				    --高亮按钮名称
					ShowHighLightButtonName = "Btn_Jion",
					ShowHighLightButtonPath = "UI_Calendar(Clone)/Frame_Center/Frame_ActivityRightDesc/Lay_Right/",
					RegisterUI = "",
					RegisterUIPath = "",
					--列表相关Panel_GuideTrigger
					--ScrollRectUIName = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity",
					--RegisterUI = "UI_Calendar(Clone)/Frame_Activity/Img_ActivityBG/List_Activity/List_ActivityMenu",
					--RegisterUIPath = "",
					--显示的UI界面 all 全显示，“” 全隐藏， name 单独显示的名称
	    			ShowUIPanelName = "CPanelCalendar",
					--是否强制
					IsClickLimit = true,
					--是否黑屏
					IsShowBlackBG = true,
	    			--触发标准--------------------------------
	    			--下一步的触发行为
	    			NextStepTriggerBehaviour = 6,
	    			--触发行为参数(无参数默认为-1)
	    			NextStepTriggerParam = -1,
	    			--为""是默认按钮自适应，有内容为自适应的子元素，没有此字段则不自适应
	    			AutoShowElement = "",
					IsSkip = 1,  -- 1右上  2右下
				}
			}
		},
	},
}

return GuideCfg