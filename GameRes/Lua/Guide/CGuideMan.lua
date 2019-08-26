--[[----------------------------------------------
         		 教学管理器
          				--- by ml 2017.1.22
--------------------------------------------------]]
local Lplus = require "Lplus"
local CGuideMan = Lplus.Class("CGuideMan")
local def = CGuideMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local QuestDef = require "Quest.QuestDef"
local Guide = require "Guide.Guide"
local UserData = require "Data.UserData".Instance()
local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"

--教学不需要关的界面 
local _KeepUIs = 
{
	"CPanelRocker",
	"CPanelSkillSlot",
	"CPanelMainChat",
	"CPanelTracker",
	"CPanelMinimap",
	"CPanelUIHead",
	--"CPanelUIActivityEntrance",
	-- "CPanelUISystem",
	"CPanelSystemEntrance",
	"CPanelLoading",
	"CPanelLog",
	"CPanelDebug",
	"CpanelGuide",
	"CPanelUIQuickUse",
	"CPanelMainTips",
	"CPanelMainTipsLow",
	"CPanelEnterMapTips",
	"CPanelUIBeginnerDungeonBoss",
	"CPanelDungeonNpcTalk",
	"CPanelUIBuffEnter",
	"CPanelInExtremis",
	"CPanelUIGuildBattleMiniMap",
    "CMsgBoxPanel",
}
--教学打开界面触发 
local _OpenPlayUIs = 
{
	"CPanelUIGuild",
	"CPanelUIGuildList",
	"CPanelUIGuildSkill",
	"CPanelUIGuildDungeon",
	"CPanelUIGuildPray",
	"CPanelUIQuestList",
	"CPanelMirrorArena",
	"CPanelUIActivity",
	"CPanelFriendFight",
	"CPanelStrong",
	"CPanelUIExterior",
	"CPanelUIEquipProcess",
	"CPanelUIAutoKill",
	"CPanelUIDungeon",
	"CPanelUIGuildSmithy",
}

def.field("table")._KeepUIs = BlankTable
--教学数据链表
def.field("table")._GuideTriggerDataTable = nil
--教学配置表
def.field("table")._GuideConfigMainTable = nil
def.field("table")._GuideConfigTriggerTable = nil
--DEBUG 控制变量
def.field("boolean")._GuideDebugOpen = true
--目前     
def.field("number")._CurGuideStep = 0
def.field("number")._CurGuideID = 0
def.field("number")._LastGuideID = 0
def.field("number")._OpenedGuideID = 0 --开启过但是没有完成的教学
def.field("number")._MaxGuideNum = 0
def.field(Guide)._CurGuideTrigger = nil
def.field("table")._CurPanel = nil
def.field("userdata")._CurButton = nil
def.field("userdata")._RegisterUI = nil
def.field("table")._Panel_script = nil
def.field("table")._CurPanelTrigger = nil
def.field("number")._MinShowTime = 1
def.field("boolean")._IsNextStepTimeLimit = true
def.field("number")._MinLimitTimerId = 0

local instance = nil
def.static("=>", CGuideMan).Instance = function ()
	if instance == nil then
	    instance = CGuideMan()
	end
    return instance
end


def.method().Init = function(self)
	self:ListenToEvent()
	self._KeepUIs = _KeepUIs

		-- 防止重复加载
	if self._GuideTriggerDataTable ~= nil then return end

	self._GuideTriggerDataTable = {}

    local guideTriggerConfig = CGuideMan.GetGuideTrigger()
	for id,v in pairs( guideTriggerConfig ) do
		if self._GuideTriggerDataTable[v.Id] == nil then
			self._GuideTriggerDataTable[v.Id] = {}
			local tmpGuide = Guide.New()
			tmpGuide._ID = v.Id
			tmpGuide._Step = 0
			tmpGuide._IsNextStepTimeLimit = false
			tmpGuide._Config = guideTriggerConfig
			self._GuideTriggerDataTable[v.Id].Guide = tmpGuide
		end
	end

	if game._GUIMan ~= nil then
		game._GUIMan:Open("CPanelGuideTrigger", nil)
	end
end

--获取主线教学
def.static("=>", "table").GetGuideMain = function()
	if instance._GuideConfigMainTable == nil then
		local ret, msg, result = pcall(dofile, "Configs/GuideConfig.lua")
		if ret then
			instance._GuideConfigMainTable = result.Main
			instance._MaxGuideNum = #instance._GuideConfigMainTable
			--instance._KeepUIs = _KeepUIs
		else
			warn(msg)
		end
	end
	
	return instance._GuideConfigMainTable
end

--获取触发教学
def.static("=>", "table").GetGuideTrigger = function()
	if instance._GuideConfigTriggerTable == nil then
		local ret, msg, result = pcall(dofile, "Configs/GuideConfig.lua")
		if ret then
			instance._GuideConfigTriggerTable = result.Trigger
		else
			warn(msg)
		end
	end
	
	return instance._GuideConfigTriggerTable
end

def.static("table").UpdateGuideSortingLayerOrder = function(guide_script)
	if guide_script ~= nil then
	    local layer = guide_script._Layer
	    local order = -1

	    -- 层级赋值
	    if not guide_script._CurBigStepConfig.Steps[guide_script._CurSmallStep].IsClickLimit then
	        ----local layer = game._GUIMan:CalculateTopLayerCurrent(self)
	        -- local layer = game._GUIMan:CalculateTopLayerCurrent(self)

	        local panelName = guide_script._CurBigStepConfig.Steps[guide_script._CurSmallStep].ShowUIPanelName
	        if panelName ~= nil and panelName ~= "" then
	            -- --print(panelName)
	            local panel_script = require("GUI." .. panelName).Instance()
	            if panel_script ~= nil and panel_script:IsShow() then
	                layer = panel_script._Layer
	                order = panel_script:GetSortingOrderBase() + GUIDE_ORDER_OFFSET
	                -- --print("重新赋值")
	            end
	        end
	    end

	    local sl_id=GameUtil.Num2SortingLayerID(layer)
	    --guide_script:SetSortingLayer(sl_id)

	    if (order > 0) then
	        guide_script:SetSortingLayerOrder(sl_id, order)
	    else
	        guide_script:SetSortingLayerOrder(sl_id, guide_script:GetSortingOrderBase())
	    end
	end
end

--加载所有教学数据
def.method().LoadAllGuideData = function(self)
--[[	-- 防止重复加载
	if self._GuideTriggerDataTable ~= nil then return end

	self._GuideTriggerDataTable = {}

    local guideTriggerConfig = CGuideMan.GetGuideTrigger()
	for id,v in pairs( guideTriggerConfig ) do
		if self._GuideTriggerDataTable[v.Id] == nil then
			self._GuideTriggerDataTable[v.Id] = {}
			local tmpGuide = Guide.New()
			tmpGuide._ID = v.Id
			tmpGuide._Step = 0
			tmpGuide._IsNextStepTimeLimit = false
			tmpGuide._Config = guideTriggerConfig
			self._GuideTriggerDataTable[v.Id].Guide = tmpGuide
		end
	end

	if game._GUIMan ~= nil then
		local panel = game._GUIMan:Open( "CPanelGuideTrigger", nil )
	end--]]
end

def.method().ClearAllGuideData = function(self)
	--self._GuideTriggerDataTable = nil
end

--获取所有教学配置
def.method("=>","table").GetAllGuideTriggerData = function(self)
	return self._GuideTriggerDataTable
end

--获取对应功能未解锁提示 (功能类型，功能ID)
def.method("number", "number").OnShowTipByFunUnlockConditions = function(self, FunType, FunctionID)
	local allTid = CElementData.GetAllFun()
	for i = 1, #allTid do
		local tid = allTid[i]
		local fun = CElementData.GetTemplate("Fun", tid)
		if FunType == 1 and fun.FunID == FunctionID then
			for Funindex, v in ipairs(fun.ConditionData.FunUnlockConditions) do				
				if v.ConditionFinishTask._is_present_in_parent then	
					local quest_data = CElementData.GetQuestTemplate(v.ConditionFinishTask.FinishTaskID)
					
					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionFinishTask.FinishTaskID) .. "-" .. quest_data.TextDisplayName
					game._GUIMan:ShowTipText(string.format(StringTable.Get(22808), str), false)
					return
				elseif v.ConditionLevelUp._is_present_in_parent then
					game._GUIMan:ShowTipText(string.format(StringTable.Get(22809), v.ConditionLevelUp.LevelUp), false)
					return
				elseif v.ConditionReceiveTask._is_present_in_parent then
					local quest_data = CElementData.GetQuestTemplate(v.ConditionReceiveTask.ReceiveTaskID)	

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionReceiveTask.ReceiveTaskID) .. "-" .. quest_data.TextDisplayName
					game._GUIMan:ShowTipText(string.format(StringTable.Get(22807), str), false)
					return
				elseif v.ConditionPassDungeon._is_present_in_parent then
					warn("ConditionPassDungeon!!!")
					return
				elseif v.ConditionUseProp._is_present_in_parent then
					warn("ConditionUseProp!!!")
					return
				elseif v.ConditionGuide._is_present_in_parent then
					warn("ConditionGuide!!!")
					return
				elseif v.ConditionGloryLevelUp._is_present_in_parent then
					warn("ConditionGloryLevelUp!!!")
					return
				elseif v.ConditionFightUp._is_present_in_parent then
					warn("ConditionFightUp!!!")
					return
				else
					game._GUIMan:ShowTipText(StringTable.Get(23), false)
					return
				end
			end
		elseif FunType == 0 and tid == FunctionID then
			for Funindex, v in ipairs(fun.ConditionData.FunUnlockConditions) do				
				if v.ConditionFinishTask._is_present_in_parent then	
					local quest_data = CElementData.GetQuestTemplate(v.ConditionFinishTask.FinishTaskID)

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionFinishTask.FinishTaskID) .. "-" .. quest_data.TextDisplayName

					game._GUIMan:ShowTipText(string.format(StringTable.Get(22808), str), false)
					return
				elseif v.ConditionLevelUp._is_present_in_parent then
					game._GUIMan:ShowTipText(string.format(StringTable.Get(22809), v.ConditionLevelUp.LevelUp), false)
					return
				elseif v.ConditionReceiveTask._is_present_in_parent then
					local quest_data = CElementData.GetQuestTemplate(v.ConditionReceiveTask.ReceiveTaskID)	

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionReceiveTask.ReceiveTaskID) .. "-" .. quest_data.TextDisplayName

					game._GUIMan:ShowTipText(string.format(StringTable.Get(22807), str), false)
					return
				elseif v.ConditionPassDungeon._is_present_in_parent then
					warn("ConditionPassDungeon!!!")
					return
				elseif v.ConditionUseProp._is_present_in_parent then
					warn("ConditionUseProp!!!")
					return
				elseif v.ConditionGuide._is_present_in_parent then
					warn("ConditionGuide!!!")
					return
				elseif v.ConditionGloryLevelUp._is_present_in_parent then
					warn("ConditionGloryLevelUp!!!")
					return
				elseif v.ConditionFightUp._is_present_in_parent then
					warn("ConditionFightUp!!!")
					return
				else
					game._GUIMan:ShowTipText(StringTable.Get(23), false)
					return
				end
			end
		end		
	end
end

-- 返回对应功能未解锁提示 (功能类型，功能ID)
def.method("number", "number", "=>", "string").GetShowTipByFunUnlockConditions = function(self, FunType, FunctionID)
	local allTid = CElementData.GetAllFun()
	for i = 1, #allTid do
		local tid = allTid[i]
		local fun = CElementData.GetTemplate("Fun", tid)
		if FunType == 1 and fun.FunID == FunctionID then
			for Funindex, v in ipairs(fun.ConditionData.FunUnlockConditions) do				
				if v.ConditionFinishTask._is_present_in_parent then	
					local quest_data = CElementData.GetQuestTemplate(v.ConditionFinishTask.FinishTaskID)
					
					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionFinishTask.FinishTaskID) .. "-" .. quest_data.TextDisplayName
					return string.format(StringTable.Get(22814), str)
				elseif v.ConditionLevelUp._is_present_in_parent then
					return string.format(StringTable.Get(22815), v.ConditionLevelUp.LevelUp)
				elseif v.ConditionReceiveTask._is_present_in_parent then
					local quest_data = CElementData.GetQuestTemplate(v.ConditionReceiveTask.ReceiveTaskID)	

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionReceiveTask.ReceiveTaskID) .. "-" .. quest_data.TextDisplayName
					return string.format(StringTable.Get(22813), str)
				elseif v.ConditionPassDungeon._is_present_in_parent then
					warn("ConditionPassDungeon!!!")
					return ""
				elseif v.ConditionUseProp._is_present_in_parent then
					warn("ConditionUseProp!!!")
					return ""
				elseif v.ConditionGuide._is_present_in_parent then
					warn("ConditionGuide!!!")
					return ""
				elseif v.ConditionGloryLevelUp._is_present_in_parent then
					warn("ConditionGloryLevelUp!!!")
					return ""
				elseif v.ConditionFightUp._is_present_in_parent then
					warn("ConditionFightUp!!!")
					return ""
				else
					return StringTable.Get(23)
				end
			end
		elseif FunType == 0 and tid == FunctionID then
			for Funindex, v in ipairs(fun.ConditionData.FunUnlockConditions) do				
				if v.ConditionFinishTask._is_present_in_parent then	
					local quest_data = CElementData.GetQuestTemplate(v.ConditionFinishTask.FinishTaskID)

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionFinishTask.FinishTaskID) .. "-" .. quest_data.TextDisplayName
					return string.format(StringTable.Get(22814), str)
				elseif v.ConditionLevelUp._is_present_in_parent then
					return string.format(StringTable.Get(22815), v.ConditionLevelUp.LevelUp)
				elseif v.ConditionReceiveTask._is_present_in_parent then
					local quest_data = CElementData.GetQuestTemplate(v.ConditionReceiveTask.ReceiveTaskID)	

					local CQuest = require "Quest.CQuest"
					local str = CQuest.Instance():GetQuesthapterStr(v.ConditionReceiveTask.ReceiveTaskID) .. "-" .. quest_data.TextDisplayName

					return string.format(StringTable.Get(22813), str)
				elseif v.ConditionPassDungeon._is_present_in_parent then
					warn("ConditionPassDungeon!!!")
					return ""
				elseif v.ConditionUseProp._is_present_in_parent then
					warn("ConditionUseProp!!!")
					return ""
				elseif v.ConditionGuide._is_present_in_parent then
					warn("ConditionGuide!!!")
					return ""
				elseif v.ConditionGloryLevelUp._is_present_in_parent then
					warn("ConditionGloryLevelUp!!!")
					return ""
				elseif v.ConditionFightUp._is_present_in_parent then
					warn("ConditionFightUp!!!")
					return ""
				else
					return StringTable.Get(23)
				end
			end
		end		
	end
end

def.method("=>","boolean").InGuide = function(self)
	return self._CurPanel ~= nil or self._CurPanelTrigger ~= nil 
end

def.method("=>","boolean").InGuideIsLimit = function(self)
	local isLimit = false
	if self._CurPanel ~= nil and self._CurPanel._BlackBG ~= nil then
		isLimit = self._CurPanel._BlackBG.activeSelf
	end 
	if self._CurPanelTrigger ~= nil and self._CurPanelTrigger._BlackBG ~= nil then
		isLimit = self._CurPanelTrigger._BlackBG.activeSelf
	end
	return isLimit
end

local function CloseGuidePanel()
	game._GUIMan:CloseByScript(instance._CurPanel)
	instance._CurPanel = nil
end

--找到点亮的按键
local function ButtonLight(buttonPath,buttonName,RegisterPath,RegisterName)
	local path = ""
	if type(buttonName) == "number" then
		--instance._CurButton = CPanelUISystem.Instance():GetFunctionObject(buttonName)
	else
		if buttonPath ~= nil then
			path = buttonPath..buttonName
		else 
			path = buttonName
		end
		instance._CurButton = GameObject.Find( path )
	end

	if IsNil(instance._CurButton) then
		--print("buttonPath=",path)
		--print("ButtonLight="..buttonName.."is nil !")
		return false
	end

    local cur_s_order=instance._CurPanel:GetSortingOrder()
	if cur_s_order == 0 then
		return false
	end

	instance._CurPanel:EffectAutoPos(instance._CurButton) 
	--instance._CurPanel._HightLightBtn = instance._CurButton
    --GameUtil.SetPanelSortingLayer(instance._CurButton, instance._CurPanel:GetSortingLayer())
    GameUtil.SetPanelSortingLayerOrder(instance._CurButton, instance._CurPanel:GetSortingLayer(), cur_s_order + GUIDE_BUTTON_ORDER_EX)
    local GraphicRaycaster = instance._CurButton:GetComponent(ClassType.GraphicRaycaster)
    if GraphicRaycaster == nil then
        instance._CurButton:AddComponent(ClassType.GraphicRaycaster)
    end

	if instance._Panel_script ~= nil then
		if RegisterPath ~= nil then
			path = RegisterPath..RegisterName
		else
			path = RegisterName
		end

		instance._RegisterUI = GameObject.Find( path )
		--判断有无注册UI，没有 则注册BUTTON，有可能出现 注册和要高亮的UI不是一个
		if instance._RegisterUI ~= nil then
			instance._Panel_script:RegisterGuideHandler(instance._RegisterUI)
		else
			instance._Panel_script:RegisterGuideHandler(instance._CurButton)
		end
	end

	--如果是 TIPS类型 改变 关闭类型
	if instance._Panel_script._PanelCloseType == EnumDef.PanelCloseType.Tip then
		instance._Panel_script._PanelCloseType = EnumDef.PanelCloseType.None
	end
--    local canvas = instance._CurButton:AddComponent(ClassType.Canvas)
--    canvas.overrideSorting = true
--    canvas.sortingLayerID = instance._CurPanel:GetSortingLayer()
--    canvas.sortingOrder = instance._CurPanel:GetSortingOrder() + GUIDE_BUTTON_ORDER_EX
--    --print("教学按钮的层级为=",canvas.sortingOrder,instance._CurPanel:GetSortingOrder())
--    --canvas.sortingOrder = 1000
--    instance._CurButton:AddComponent(ClassType.GraphicRaycaster)
--    local GraphicRaycaster = instance._CurButton:GetComponent(ClassType.GraphicRaycaster)
    return true 
end

--按钮恢复正常
local function ButtonNormal()
	if IsNil(instance._CurButton) then
		return
    end

	local GraphicRaycaster = instance._CurButton:GetComponent(ClassType.GraphicRaycaster)
	if GraphicRaycaster ~= nil then
	    GameObject.Destroy( GraphicRaycaster )
    end

	local Canvas = instance._CurButton:GetComponent(ClassType.Canvas)
	if Canvas ~= nil then
		GameObject.Destroy( Canvas )
	end

	if instance._Panel_script ~= nil then
		--instance._Panel_script:UnregisterGuideHandler(instance._CurButton)
		if instance._RegisterUI ~= nil then
			instance._Panel_script:RegisterGuideHandler(instance._RegisterUI)
		else
			instance._Panel_script:RegisterGuideHandler(instance._CurButton)
		end
	end

	--如果此步骤是列表
	instance:ListGuide(false)

	instance._CurButton = nil
	instance._RegisterUI = nil
end

--显示教学
local function GuideShow( self,id,step )

    --检查是否可以进行下一步
    --local guideData = CElementData.GetGuideTemplate(id)
    --print("=======GuideShow============",id,step)

    local guideConfig = CGuideMan.GetGuideMain()
    -- --print_r(guideConfig)
    local BigStepConfig = guideConfig[id]
    -- --print("=======BigStepConfig============")
    -- --print_r(BigStepConfig)

    local SmallStepConfig
    if BigStepConfig ~= nil then
    	if BigStepConfig.Steps ~= nil and #BigStepConfig.Steps > 0 then   
    		SmallStepConfig = BigStepConfig.Steps[step]
    	end
    end
    -- --print("=======SmallStepConfig=================")
    -- --print_r(SmallStepConfig)

    -- --print( "MLMLMLMLGuideShowPopPanelName="..guideStepData.PopPanelName)
    -- --print( "MLMLMLMLGuideShowGUIDEButtonName="..guideStepData.ButtonHighlightName)
	--关闭上一步
	ButtonNormal()

	local function cb( )
		--获得当前教学的UI脚本
		instance._Panel_script = nil
		if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName ~= "" then
	    	instance._Panel_script = require("GUI." .. SmallStepConfig.ShowUIPanelName).Instance()
	    end
	    instance._CurPanel = require("GUI.CPanelGuide").Instance()
		--高亮按钮
		if SmallStepConfig.ShowHighLightButtonName ~= nil and SmallStepConfig.ShowHighLightButtonName ~= "" then
			--是否成功
			local isSuccess = ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
			--如果此步骤是列表
			if SmallStepConfig.NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickTargetList then
				instance:ListGuide(true)
			end

			--如果没有成功
			if not isSuccess then
				--教学界面 初始化回调
				local function ShowUIPaneInit()
					CGuideMan.UpdateGuideSortingLayerOrder(instance._CurPanel)
					ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
					--如果此步骤是列表
					if SmallStepConfig.NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickTargetList then
						instance:ListGuide(true)
					end
					--没有动画延迟则 初始化时显示
					if SmallStepConfig.IsAnimationDelay == nil or not SmallStepConfig.IsAnimationDelay then
						instance._CurPanel:ShowStep()
					end
				end
				SmallStepConfig.InitCallBack = ShowUIPaneInit
			end
		end

		-- 最小显示时间
		if SmallStepConfig.MinShowTime ~= nil and SmallStepConfig.MinShowTime ~= "" then
					--显示的最短时间
			self._IsNextStepTimeLimit = true
			self._MinShowTime = SmallStepConfig.MinShowTime
		    if self._MinLimitTimerId ~= 0 then
		        _G.RemoveGlobalTimer(self._MinLimitTimerId)
		        self._MinLimitTimerId = 0
		    end
		    self._MinLimitTimerId = _G.AddGlobalTimer(self._MinShowTime, true ,function()
		    	self._IsNextStepTimeLimit = false
		    end)
		else
			self._IsNextStepTimeLimit = false
		end

		--如果需要播放CG 
		if SmallStepConfig.IsShowGuideCG ~= nil and SmallStepConfig.IsShowGuideCG then
			CGMan.PlayCG(SmallStepConfig.NextStepTriggerParam, nil, 1, false)
			--print("cgman=====================================",SmallStepConfig.NextStepTriggerParam)
			--播放CG 没有限制
			self._IsNextStepTimeLimit = false
		end
	end

	if not IsNil(instance._CurPanel) then
		--GuideClose(self,instance._CurGuideID,instance._CurGuideStep)
		instance._CurPanel:ShowNextSmallStep()
		cb()
	else
		instance._CurPanel = game._GUIMan:Open( "CPanelGuide",{_data = BigStepConfig,_cb = cb} )
	end

end

--关闭教学
local function GuideClose( self,id,step )
	ButtonNormal()
	CloseGuidePanel()
end

--教学完成
local function GuideFinish( self,id )
	--print( "MLML/GuideFinish/GuideID"..id)
	--关闭上一步
	GuideClose(self,instance._CurGuideID,instance._CurGuideStep)

	self:SendC2SGuideProgress( id )
	
    self._LastGuideID = id
	self._CurGuideStep = 0
	self._CurGuideID = id + 1
	self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.AutoNextGuide,-1)
end

--教学开始
local function GuideStart( self,id,behaviourID,param )
	--要进行的教学ID 等于 已经发生的教学ID ＋１ 并且 已经完成 才可以进行
	if id ~= self._LastGuideID + 1 or self._CurGuideStep ~= 0  then
		return false
	end

	if self._IsNextStepTimeLimit then
		--print( "MLML/GuideNext/ IsNextStepTimeLimit is true" )
		return false
	end

	--临时记录 到时改成 服务器记录 
	-- if game._HostPlayer ~= nil then
	-- 	local key = "OpenedGuideID"..game._HostPlayer._ID
	-- 	local id = UserData:GetField(key)
	--     if id ~= nil then
	--     	self._OpenedGuideID = id
	--     end
	-- end

	local guideConfig = CGuideMan.GetGuideMain()
    local BigStepConfig = guideConfig[id]
	--如果是指定的教学行为ID
	-- if (behaviourID ~= BigStepConfig.TriggerBehaviour or param ~= BigStepConfig.TriggerParam) and self._OpenedGuideID < id then
	-- 	--print( "MLML/GuideStart/ GuideBehaviourID No Equal",behaviourID,BigStepConfig.TriggerBehaviour,param,BigStepConfig.TriggerParam)
	-- 	--print( "MLML/GuideStart/ _OpenedGuideID<id",self._OpenedGuideID,id )
	-- 	return false
	-- end

	if BigStepConfig.TriggerParamSymbol == nil then
		if ((behaviourID ~= BigStepConfig.TriggerBehaviour or param ~= BigStepConfig.TriggerParam) and BigStepConfig.TriggerBehaviour ~= -1 ) and self._OpenedGuideID < id then
		--print( "MLML/GuideStart/ GuideBehaviourID No Equal",behaviourID,BigStepConfig.TriggerBehaviour,param,BigStepConfig.TriggerParam)
		--print( "MLML/GuideStart/ _OpenedGuideID<id",self._OpenedGuideID,id )
			return false
		end
	elseif BigStepConfig.TriggerParamSymbol ~= nil and BigStepConfig.TriggerParamSymbol then
		if (behaviourID ~= BigStepConfig.TriggerBehaviour or param < BigStepConfig.TriggerParam) and self._OpenedGuideID < id then
			return false
		end
	elseif BigStepConfig.TriggerParamSymbol ~= nil and not BigStepConfig.TriggerParamSymbol then
		if (behaviourID ~= BigStepConfig.TriggerBehaviour or param > BigStepConfig.TriggerParam) and self._OpenedGuideID < id then
			return false
		end
	end

	self._CurGuideID = id
    self._CurGuideStep = 1
	--print( "MLML/GuideStart")

	if BigStepConfig.TriggerBehaviour ~= EnumDef.EGuideBehaviourID.OpenUI then
		game._GUIMan:CloseAll(_KeepUIs)
	end
	
	--界面特殊处理
	local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"
	CPanelSystemEntrance.Instance(): ShowFloatingFrame(false)	
	local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
	if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelTracker" then
		local CPanelTracker = require "GUI.CPanelTracker"
		CPanelTracker.Instance():ResetLayout()
		if SmallStepConfig.ShowHighLightButtonName ~= nil then
			if SmallStepConfig.ShowHighLightButtonName == "Item" then
				CPanelTracker.Instance():SwitchPage(2) -- 默认切换到组队界面
			elseif SmallStepConfig.ShowHighLightButtonName == "List_Quest" then 
				CPanelTracker.Instance():SwitchPage(0) -- 默认切换到组队界面
			end
		end
	end

	--界面特殊ID
	if BigStepConfig.LimitSpecialID ~= nil and BigStepConfig.LimitSpecialID == 1 then
		local CExteriorMan = require "Main.CExteriorMan"
		if not CExteriorMan.Instance():CanEnter() then
			GuideFinish(self,self._CurGuideID)
			return
		end
	end

	-- 判断是否可以显示
	if (BigStepConfig.IsTriggerDelay == nil or not BigStepConfig.IsTriggerDelay) and self:SpecialPanelIsShow() then
		GuideShow( self,self._CurGuideID,self._CurGuideStep )
	end
	
	--开启过的教学记录，退出游戏后 默认开启有用
	self._OpenedGuideID = id

	-- local key = "OpenedGuideID"..game._HostPlayer._ID
	-- UserData:SetField(key,self._OpenedGuideID)
	-- UserData:SaveDataToFile()
		
    self:SendC2SGuideWill(self._OpenedGuideID)
	--如果是记录点则 完成这步 就算退出游戏也算整个步骤完成
	if BigStepConfig.IsSave ~= nil and BigStepConfig.IsSave then
		self:SendC2SGuideProgress( self._OpenedGuideID )
	end
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()

    return true
end

--教学下一步
local function GuideNextStep( self,id,behaviourID,param )
	-- 判断是否是当前教学 并且 是否是下一步教学
	  local nextStep = instance._CurGuideStep + 1
	  --print( "MLML/GuideNext/eventStep"..nextStep)
		if id ~= instance._CurGuideID then
			--print( "MLML/GuideNext/ GuideID No Equal" )
			return false
		end

	    --检查是否可以进行下一步
	    --local guideData = CElementData.GetGuideTemplate(id)
	    local guideConfig = CGuideMan.GetGuideMain()
	    local BigStepConfig = guideConfig[id]
	    local SmallStepConfig = BigStepConfig.Steps[instance._CurGuideStep]
    	if self._IsNextStepTimeLimit then
    		--print( "MLML/GuideNext/ IsNextStepTimeLimit is true" )
			return false
		end
		--如果是指定的教学行为ID
		if (behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour or param ~= SmallStepConfig.NextStepTriggerParam) and
			(SmallStepConfig.NextStepTriggerBehaviour2 == nil or behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour2 or param ~= SmallStepConfig.NextStepTriggerParam2) then
			--print( "MLML/GuideNext/ GuideBehaviourID No Equal",behaviourID,SmallStepConfig.NextStepTriggerBehaviour,param,SmallStepConfig.NextStepTriggerParam)
			return false
		end

    	--获取步骤数
	    local tmpMaxStep = 0
	    if BigStepConfig ~= nil and BigStepConfig.Steps ~= nil then
	    	tmpMaxStep = #BigStepConfig.Steps 
	    end

	    if nextStep > tmpMaxStep then
	    	--print( "MLML/GuideNext/ MaxStep" )
	    	GuideFinish( self,instance._CurGuideID )
	    	return true
    	end

    	--如果是记录点则 完成这步 就算退出游戏也算整个步骤完成
    	if SmallStepConfig.IsSave ~= nil and SmallStepConfig.IsSave then
    		self:SendC2SGuideProgress( id )
    	end

    	--print("GuideNextStep",id,behaviourID,param)
		GuideShow( self,id,nextStep )
		instance._CurGuideStep = nextStep  

		return true    
end

def.method().JumpCurGuide = function(self)
	if self._CurGuideStep > 0 and self._CurPanel ~= nil then
		GuideFinish(self,instance._CurGuideID)
	end

	if self._GuideTriggerDataTable == nil then return end
	if self._CurPanelTrigger == nil then return end
  
	for k,v in pairs(self._GuideTriggerDataTable) do
		if v.Guide ~= nil and v.Guide._ID  == self._CurPanelTrigger._CurBigStep then
			v.Guide:GuideFinish(v.Guide._ID)
			--print("@@@@@@@@@",v.Guide._ID,v.isTrigger,v.Guide._IsFinish)
			self._CurPanelTrigger = nil
			self:GuideTrigger(EnumDef.EGuideBehaviourID.FinishGuide,v.Guide._ID)
			break
		end
	end

--[[	for k,v in pairs(self._GuideTriggerDataTable) do
		if v.isTrigger and v.Guide ~= nil and not v.Guide._IsFinish then
			v.Guide:GuideFinish(v.Guide._ID)
			self._CurPanelTrigger = nil
			self:GuideTrigger(EnumDef.EGuideBehaviourID.FinishGuide,v.Guide._ID)
		end
	end--]]
end

--教学执行
def.method("number","number","number").GuidePlay = function(self,id,behaviourID,param)
	--如果DEBUG 关闭则不播放
	if not self._GuideDebugOpen then
		return 
	end
	if game._HostPlayer ~= nil and game._HostPlayer:IsDead() then
		return
	end

	--要进行的教学ID 等于 已经发生的教学ID ＋１ 并且 已经完成 才可以进行
	local guideConfig = CGuideMan.GetGuideMain()
	--print("GuidePlay","_LastGuideID="..instance._LastGuideID,"CurGuideid="..id,"MaxGuideNum=",instance._MaxGuideNum,"GuideStep="..instance._CurGuideStep,"behaviourID="..behaviourID,"param="..param)

	if id == 0 then
		--默认第一步
		id = 1
		--第一步没有限制时间
		self._IsNextStepTimeLimit = false
		-- --print("GuidePlayID=0")
		-- return
	end

	if id ~= instance._LastGuideID + 1 then
		--print("GuidePlayID 不是下一步教学",id,instance._LastGuideID)
		return
	end

	if id > instance._MaxGuideNum then
		--print("GuidePlayID 没有新的教学了 ",id)
		return
	end

	local BigStepConfig = guideConfig[id]
	if BigStepConfig.LimitMapID ~= nil and game._CurWorld ~= nil and BigStepConfig.LimitMapID ~= game._CurWorld._WorldInfo.MapTid  then
		--print("GuidePlayID 不在限制的地图上 ",id,BigStepConfig.LimitMapID,game._CurWorld._WorldInfo.MapTid)
		return
	end

	if instance._CurGuideStep == 0  then
		local isSuccess = GuideStart(self,id,behaviourID,param)

		--如果有触发类型教学 则直接关闭
		if isSuccess and not IsNil(self._CurGuideTrigger) then
			self._CurGuideTrigger:GuideClose()
			self._CurGuideTrigger = nil
			--print("////////////////////////////////////")
		end
	else
		GuideNextStep(self,id,behaviourID,param)
	end
end


--教学触发执行 （与主线不同的是，这个不是连续的步骤要求）
def.method("number","number").GuideTrigger = function(self,behaviourID,param)
	--如果DEBUG 关闭则不播放
	if not self._GuideDebugOpen then
		return 
	end
	--print("GuideTrigger====",behaviourID,param)
	--要进行的教学ID 等于 已经发生的教学ID ＋１ 并且 已经完成 才可以进行
	local guideTriggerConfig = CGuideMan.GetGuideTrigger()

    --循环所有教学数据
	local tmpGuide = nil
	--判断是否是第一步
	local isFristStep = true
	if self._GuideTriggerDataTable == nil then
		return
	end

	for id,v in pairs( guideTriggerConfig ) do
		tmpGuide = self._GuideTriggerDataTable[v.Id].Guide
		if not tmpGuide._IsFinish then
			if tmpGuide == nil or not self._GuideTriggerDataTable[tmpGuide._ID].isTrigger then
				--如果有正在进行的 主线教学或者触发类教学
				if ( IsNil(self._CurPanelTrigger) or not self._CurPanelTrigger:IsClickLimit() ) and IsNil(self._CurPanel) then

					--临时加上判空 重新赋值
					if tmpGuide == nil then
						tmpGuide = Guide.New()
						tmpGuide._ID = v.Id
						tmpGuide._Step = 0
						tmpGuide._IsNextStepTimeLimit = false
						tmpGuide._Config = guideTriggerConfig
						self._GuideTriggerDataTable[v.Id].Guide = tmpGuide	
						tmpGuide = self._GuideTriggerDataTable[v.Id].Guide			
					end
					
					local isSuccess = tmpGuide:GuideStart(id,behaviourID,param)
--[[						if tmpGuide._ID == 126 then
						print("GuideStartTest2",id,behaviourID,param,isSuccess)
					end--]]
					if isSuccess then
						self._CurGuideTrigger = tmpGuide
						--print("CurGuideTrigger = tmpGuide")
						self._CurPanelTrigger = tmpGuide._CurPanel
						--只要触发过就不再触发
						self._GuideTriggerDataTable[id].isTrigger = true
						self:SendC2SGuideTrigger( id )
						--print("GuideStart",id)
						local CAutoFightMan = require "AutoFight.CAutoFightMan"
						local CQuestAutoMan = require "Quest.CQuestAutoMan"
						local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
						CQuestAutoMan.Instance():Stop()
						CDungeonAutoMan.Instance():Stop()
						CAutoFightMan.Instance():Stop()
						break
					end
				end

			else
				if not IsNil(self._CurPanelTrigger) then
					local isSuccess = tmpGuide:GuideNextStep(id,behaviourID,param)
					if isSuccess then
						self._CurPanelTrigger = tmpGuide._CurPanel
						--如果为空证明结束了
						if self._CurPanelTrigger == nil then
							self._CurGuideTrigger = nil
							--print("CurGuideTrigger = nil",EnumDef.EGuideBehaviourID.FinishGuide,id)
							self:GuideTrigger(EnumDef.EGuideBehaviourID.FinishGuide,id)
						end
						--print("GuideNextStep",id)
						break
					end
				end
			end
		end
	end
end

--事件回调
	local function EventCallback( sender, event )
		local self = instance

		if event._Type == EnumDef.EGuideType.Main_Start then
	        GuideStart( self,event._ID,event._BehaviourID,event._Param )
		end
		if event._Type == EnumDef.EGuideType.Main_NextStep then
	        GuideNextStep( self,event._ID,event._BehaviourID,event._Param )
		end
	    if event._Type == EnumDef.EGuideType.Main_Finish then
	    	GuideFinish( self,event._ID )
		end
		if event._Type == EnumDef.EGuideType.Trigger_Start then
			self:GuideTrigger(event._BehaviourID,event._Param )
		end
	end

--进入区域后 主线教学回调
	local function OnEnterRegionEvent(sender, event)
		local self = instance
		--print("OnEnterRegionEvent=======",event.RegionID)
		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.EnterRegion,event.RegionID)
		self:GuideTrigger(EnumDef.EGuideBehaviourID.EnterRegion,event.RegionID)
	end

--CG 播放后 主线教学回调
	local function OnCGEvent(sender, event)
		if game._CurWorld == nil then return end
		local self = instance
		if event.Type == "end" then
			--print("OnCGEvent=======",event.Id)
			self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.CGFinish,event.Id )
			self:GuideTrigger(EnumDef.EGuideBehaviourID.CGFinish,event.Id)
		end
	end

--杀死某只怪后 主线教学回调
	local function OnObjectDieEvent(sender, event)
		local self = instance
		local object = game._CurWorld:FindObject(event._ObjectID) 
		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.KillMonster,object:GetTemplateId() )
		self:GuideTrigger(EnumDef.EGuideBehaviourID.KillMonster,object:GetTemplateId())	
	end

--任务完成后 主线教学回调
	local function OnQuestCommonEvent(sender, event)
		local self = instance
	  	if event._Name == EnumDef.QuestEventNames.QUEST_COMPLETE then
	  		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.FinishTask,event._Data.Id)	
	  		self:GuideTrigger(EnumDef.EGuideBehaviourID.FinishTask,event._Data.Id)	
	  	elseif event._Name == EnumDef.QuestEventNames.QUEST_RECIEVE then
	  		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.ReceiveTask, event._Data.Id)
	  		self:GuideTrigger(EnumDef.EGuideBehaviourID.ReceiveTask, event._Data.Id)
	  	elseif event._Name == EnumDef.QuestEventNames.QUEST_CHANGE then
			local CQuest = require "Quest.CQuest"

			--如果是 主任务 完成状态
			if event._Data.SubQuestId == 0 then
				local model = CQuest.Instance():FetchQuestModel(event._Data.QuestId)
				if model:IsCompleteAll() and not model:IsAutoDeliver() then
					self:GuideTrigger(EnumDef.EGuideBehaviourID.ReadyToDeliverTask,event._Data.QuestId)
				end
			--else
			--	if CQuest.Instance():JudgeObjectiveIsComplete(event._Data.QuestId,event._Data.ObjectiveId, event._Data.ObjectiveCounter) then
		  	--		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.FinishTask,event._Data.SubQuestId)
		  	--		self:GuideTrigger(EnumDef.EGuideBehaviourID.FinishTask,event._Data.SubQuestId)
		  	--	end
			end
		end 
	end

	local function OnHostPlayerLevelChangeEvent(sender, event)
		local self = instance
		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.LevelUp,game._HostPlayer._InfoData._Level )
		self:GuideTrigger(EnumDef.EGuideBehaviourID.LevelUp,game._HostPlayer._InfoData._Level)
	end

	local function OnUseItemEvent(sender, event)
		local self = instance
		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.UseProp,event._ID )
		self:GuideTrigger(EnumDef.EGuideBehaviourID.UseProp,event._ID )
	end

	local function OnPassDungeonLaterEvent(sender, event)
		local self = instance
		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.DungeonPass,event._MapInstanceId )
		self:GuideTrigger(EnumDef.EGuideBehaviourID.DungeonPass,event._MapInstanceId )
	end

	local function OnNotifyHpEvent(sender, event)
		local self = instance
        if game._HostPlayer._ID == event.ObjID then
        	local HPPercent = game._HostPlayer._InfoData._CurrentHp / game._HostPlayer._InfoData._MaxHp
            self:GuideTrigger(EnumDef.EGuideBehaviourID.HPPercentLow,HPPercent )
            --self:GuideTrigger(EnumDef.EGuideBehaviourID.HPPercentHigh,HPPercent )
            -- --print(HPPercent,game._HostPlayer._InfoData._CurrentHp,game._HostPlayer._InfoData._MaxHp)
        end
	end

	local function OnEntityCombatStateEvent(sender, event)
		local self = instance

		local object = game._CurWorld:FindObject(event._EntityId) 
		-- --print("event._EntityId=",object:GetTemplateId())
		-- --print("event._CombatState=",event._CombatState)
		local object = game._CurWorld:FindObject(event._EntityId) 
        if event._CombatState == EnumDef.EntityFightType.ENTER_WEAK_POINT then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.WeakPotinIn,object:GetTemplateId() )
        else
        	self:GuideTrigger(EnumDef.EGuideBehaviourID.WeakPotinOut,object:GetTemplateId() )
        end

    	if event._CombatState == EnumDef.EntityFightType.ENTER_FIGHT then
        	self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.EnterFight,object:GetTemplateId() )
        	self:GuideTrigger(EnumDef.EGuideBehaviourID.EnterFight,object:GetTemplateId() )
    	end
	end
	
		--事件回调
	local function OnUIByType( sender, event )
		local self = instance
	    if event._Type == 3 then
    		--local mine = game._CurWorld:FindObject(event._Data.curCutTag)
    		local mine = event._Data
    		if mine ~= nil then
	    		self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.Gather,mine:GetTemplateId())
	    		self:GuideTrigger(EnumDef.EGuideBehaviourID.Gather,mine:GetTemplateId() )
	    	end
--[[    	elseif event._Type == EnumDef.EShortCutEventType.HawkEyeOpen then
    		--print("OnHawEye11",event._Data.status)
			self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.HawEye,event._Data.status)
			self:GuideTrigger(EnumDef.EGuideBehaviourID.HawEye,event._Data.status)	--]]
	    end
	end

	local function OnObjectDisable(sender, event)
	 	if game._HostPlayer._ID == event._ObjectID then		
	 		local self = instance		
	 		self:JumpCurGuide()
	 	end
	end

    local function OnUISortingChangeEvent(sender, event)

    end

    local function OnPackageChangeEvent(sender, event)
    	local self = instance
    	local Percent = #game._HostPlayer._Package._NormalPack._ItemSet / game._HostPlayer._Package._NormalPack._EffectSize
    	self:GuideTrigger(EnumDef.EGuideBehaviourID.BagCapacityLast,Percent )
    end

def.method().ListenToEvent = function(self)
	CGame.EventManager:addHandler('GuideEvent', EventCallback)  

	CGame.EventManager:addHandler('NotifyEnterRegion', OnEnterRegionEvent)

	CGame.EventManager:addHandler("NotifyCGEvent", OnCGEvent)  

	CGame.EventManager:addHandler("ObjectDieEvent", OnObjectDieEvent)  
	
	CGame.EventManager:addHandler("QuestCommonEvent", OnQuestCommonEvent)

	CGame.EventManager:addHandler("PlayerGuidLevelUp", OnHostPlayerLevelChangeEvent)

	CGame.EventManager:addHandler("UseItemEvent", OnUseItemEvent)
	
	CGame.EventManager:addHandler("EntityEnterEvent", OnPassDungeonLaterEvent)

	local NotifyPropEvent = require "Events.NotifyPropEvent"
	CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyHpEvent)

	CGame.EventManager:addHandler("EntityCombatStateEvent", OnEntityCombatStateEvent)

	local ObjectDieEvent = require "Events.ObjectDieEvent"
	CGame.EventManager:addHandler(ObjectDieEvent, OnObjectDisable)

	CGame.EventManager:addHandler("UISortingChangeEvent", OnUISortingChangeEvent)

	local PackageChangeEvent = require "Events.PackageChangeEvent"
	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
	local UIShortCutEvent = require "Events.UIShortCutEvent"
	CGame.EventManager:addHandler(UIShortCutEvent, OnUIByType)
end

def.method().UnlistenToEvent = function(self)
	CGame.EventManager:removeHandler('GuideEvent', EventCallback)  

	CGame.EventManager:removeHandler('NotifyEnterRegion', OnEnterRegionEvent)

	CGame.EventManager:removeHandler("NotifyCGEvent", OnCGEvent)  

	CGame.EventManager:removeHandler("ObjectDieEvent", OnObjectDieEvent)  
	
	CGame.EventManager:removeHandler("QuestCommonEvent", OnQuestCommonEvent)

	CGame.EventManager:removeHandler("PlayerGuidLevelUp", OnHostPlayerLevelChangeEvent)

	CGame.EventManager:removeHandler("UseItemEvent", OnUseItemEvent)
	
	CGame.EventManager:removeHandler("EntityEnterEvent", OnPassDungeonLaterEvent)

	local NotifyPropEvent = require "Events.NotifyPropEvent"
	CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyHpEvent)

	CGame.EventManager:removeHandler("EntityCombatStateEvent", OnEntityCombatStateEvent)

	local ObjectDieEvent = require "Events.ObjectDieEvent"
	CGame.EventManager:removeHandler(ObjectDieEvent, OnObjectDisable)

	CGame.EventManager:removeHandler("UISortingChangeEvent", OnUISortingChangeEvent)

	local PackageChangeEvent = require "Events.PackageChangeEvent"
	CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
	local UIShortCutEvent = require "Events.UIShortCutEvent"
	CGame.EventManager:removeHandler(UIShortCutEvent, OnUIByType)
end

def.method().Cleanup = function (self)
	self:UnlistenToEvent()
	self._GuideConfigMainTable = nil
	self._GuideConfigTriggerTable = nil
	self._GuideTriggerDataTable = nil
	self._CurGuideStep = 0
	self._CurGuideID = 0
	self._LastGuideID = 0
	self._OpenedGuideID = 0 --开启过但是没有完成的教学
	self._MaxGuideNum = 0
	self._CurGuideTrigger = nil
	self._CurPanel = nil
	self._CurButton = nil
	self._CurPanelTrigger = nil
end

def.method("boolean").SetOpenDebugGuide = function(self,b)
    self._GuideDebugOpen = b
    if not self._GuideDebugOpen then
    	CloseGuidePanel()
    end
    --local UserData = require "Data.UserData".Instance()
	UserData:SetField("GuideDebugOpen", self._GuideDebugOpen)
	UserData:SaveDataToFile()
end

def.method().DebugCloseGuidePanel = function(self)
	CloseGuidePanel()
end

--位移相关教学特殊处理
def.method("boolean").MoveGuide = function(self,b)
--[[    if self._CurGuideID == EnumDef.EGuideID.Main_Move and self._CurGuideStep == 1 then
    	if IsNil(self._CurPanel) then return end
    	if b then
    		self._CurPanel:ShowCurSmallStep()
    	else
    		self._CurPanel:HideCurSmallStep()
    	end
	end--]]
    if self._CurGuideTrigger ~= nil and self._CurGuideTrigger._ID == 101 and self._CurGuideTrigger._Step == 1 then
    	if IsNil(self._CurPanelTrigger) then return end
    	if b then
    		self._CurPanelTrigger:ShowCurSmallStep()
    	else
    		self._CurPanelTrigger:HideCurSmallStep()
    	end
	end
end

--采集相关教学特殊处理
def.method("boolean").GatherGuide = function(self,b)
--[[    if (self._CurGuideID == 7) and self._CurGuideStep == 1 then
    	if IsNil(self._CurPanel) then return end
    	if b then
    		self._CurPanel:ShowCurSmallStep()
    		--game._HostPlayer:StopNaviCal()
    	else
    		self._CurPanel:HideCurSmallStep()
    	end
	end--]]
    if (self._CurGuideTrigger ~= nil and self._CurGuideTrigger._ID == 107) and self._CurGuideTrigger._Step == 1 then
    	if IsNil(self._CurPanelTrigger) then return end
    	if b then
    		self._CurPanelTrigger:ShowCurSmallStep()
    		--game._HostPlayer:StopNaviCal()
    	else
    		self._CurPanelTrigger:HideCurSmallStep()
    	end
	end
end

--新手副本教学特殊处理
def.method("boolean","string").IsShowGuide = function(self,b,panelName)
	--print("111111111111111111111111111DungeonGuide",b,panelName,self._CurGuideTrigger._ID,self._CurGuideTrigger._Step,debug.traceback())
    if (self._CurGuideID == 4 or self._CurGuideID == 6) and self._CurGuideStep == 1 then
    	if b then
    		--print("11111111111")
    		if IsNil(self._CurPanel) then
    			GuideShow( self,self._CurGuideID,self._CurGuideStep )
    		else
    			self._CurPanel:ShowCurSmallStep()
    		end
    		--game._HostPlayer:StopNaviCal()
    	else
    		--print("22222222222222222")
			if IsNil(self._CurPanel) then
    			--GuideShow( self,self._CurGuideID,self._CurGuideStep )
    		else
    			self._CurPanel:HideCurSmallStep()
    		end
    	end
	end

	if panelName == "Panel_Main_QuestN(Clone)" then
	    if (self._CurGuideTrigger ~= nil and (self._CurGuideTrigger._ID == 104 or self._CurGuideTrigger._ID == 106 or self._CurGuideTrigger._ID == 111 or self._CurGuideTrigger._ID == 32 or self._CurGuideTrigger._ID == 113 )) and self._CurGuideTrigger._Step == 1 then
	    	local CGuideMan = require "Guide.CGuideMan"
	        local guideConfig = CGuideMan.GetGuideTrigger()
	        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
	        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]

	        local frame = GameObject.Find( SmallStepConfig.OpenPagePath )
	    	if b and (SmallStepConfig.OpenPagePath == nil or (frame ~= nil and frame.activeSelf and frame.localPosition.x ~= 10000) )  then
	    		if IsNil(self._CurPanelTrigger) then
	    			self._CurGuideTrigger:GuideShow( self._CurGuideTrigger._ID,self._CurGuideTrigger._Step )
	    		else
	    			self._CurPanelTrigger:ShowCurSmallStep()
	    		end
	    	else

				if IsNil(self._CurPanelTrigger) then

	    		else
	    			self._CurPanelTrigger:HideCurSmallStep()
	    		end
	    	end
		end
	elseif panelName == "UI_Main_Chat(Clone)" then
	    if self._CurGuideTrigger ~= nil and self._CurGuideTrigger._ID == 23 and self._CurGuideTrigger._Step == 1 then
	    	local CGuideMan = require "Guide.CGuideMan"
	        local guideConfig = CGuideMan.GetGuideTrigger()
	        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
	        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]

	    	local frame = GameObject.Find( SmallStepConfig.OpenPagePath )
	    	if b and (SmallStepConfig.OpenPagePath == nil or (frame ~= nil and frame.activeSelf and frame.localPosition.x ~= 10000) )  then
	    		if IsNil(self._CurPanelTrigger) then
	    			self._CurGuideTrigger:GuideShow( self._CurGuideTrigger._ID,self._CurGuideTrigger._Step )
	    		else
	    			self._CurPanelTrigger:ShowCurSmallStep()
	    			self._CurPanelTrigger:EffectAutoPos(self._CurGuideTrigger._CurButton)
	    		end
	    	else

				if IsNil(self._CurPanelTrigger) then

	    		else
	    			self._CurPanelTrigger:HideCurSmallStep()
	    		end
	    	end
		end
	elseif panelName == "" then
	    if self._CurGuideTrigger ~= nil then
	    	local CGuideMan = require "Guide.CGuideMan"
	        local guideConfig = CGuideMan.GetGuideTrigger()
	        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
	        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]

	        --print( "!!!!!!!!!!!!!!!!!!!",self._CurGuideTrigger._ID,self._CurGuideTrigger._Step )

	    	local frame = GameObject.Find( SmallStepConfig.OpenPagePath )
	    	if b and (SmallStepConfig.OpenPagePath == nil or (frame ~= nil and frame.activeSelf and frame.localPosition.x ~= 10000) )  then
	    		if IsNil(self._CurPanelTrigger) then

	    		else
	    			local isShow = false
	    			if SmallStepConfig.ShowUIPanelName ~= nil then
	    				if SmallStepConfig.ShowUIPanelName == "" then
	    					isShow = true
	    				else
				        	local panel = require("GUI." .. SmallStepConfig.ShowUIPanelName).Instance()
				    		if panel ~= nil then
				    			isShow = panel:IsShow()
				    		end
			    		end
			    	end

			    	if isShow then
	    				self._CurPanelTrigger:ShowCurSmallStep()
	    				self._CurPanelTrigger:EffectAutoPos(self._CurGuideTrigger._CurButton)
	    			end
	    		end
	    	else

				if IsNil(self._CurPanelTrigger) then

	    		else
	    			self._CurPanelTrigger:HideCurSmallStep()
	    		end
	    	end
		end
	end
end

def.method("=>","boolean").SpecialPanelIsShow = function(self)
    if (self._CurGuideID == 104 or self._CurGuideID == 106 or self._CurGuideID == 33 ) and self._CurGuideStep == 1 then
       	local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        ----print("GuideOnDataCallBack=================",SmallStepConfig.ShowUIPanelName,panel._Name)
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelTracker" then
        	local panel = require("GUI." .. SmallStepConfig.ShowUIPanelName).Instance()
    		--print("33333333333333333333",not panel:IsHidden())
    		return not panel:IsHidden()
    	end
	end
	return true
end

--鹰眼相关教学特殊处理
def.method("boolean","number").HaweyeGuide = function(self,b,state)
 --    if self._CurGuideID == 6 and self._CurGuideStep == 1 then
 --    	if IsNil(self._CurPanel) then return end
 --    	if b and state == 3 then
 --    		self._CurPanel:ShowCurSmallStep()
 --    	else
 --    		self._CurPanel:HideCurSmallStep()
 --    	end
	-- end

	local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
	    if self._CurGuideID == 6 and self._CurGuideStep == 1 then
	    	if b and state == 3 then
	    		panel:ShowCurSmallStep()
	    	else
	    		panel:HideCurSmallStep()
	    	end
		end
    end

    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
	    if self._CurGuideTrigger._ID == 11 and self._CurGuideTrigger._Step == 1 then
	    	if b and state == 3 then
	    		panelTrigger:ShowCurSmallStep()
	    	else
	    		panelTrigger:HideCurSmallStep()
	    	end
		end
    end

    if self._CurGuideTrigger ~= nil then
	    if (self._CurGuideTrigger._ID == 16 or self._CurGuideTrigger._ID == 21) and self._CurGuideTrigger._Step == 1 then
			if b and state == 1 then
				local CAutoFightMan = require "AutoFight.CAutoFightMan"
				local CQuestAutoMan = require "Quest.CQuestAutoMan"
				local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
				CQuestAutoMan.Instance():Stop()
				CDungeonAutoMan.Instance():Stop()
				CAutoFightMan.Instance():Stop()
				game._HostPlayer:StopNaviCal()
			end
		end
	end
end

--列表相关教学特殊处理
def.method("boolean").ListGuide = function(self,b)
	if IsNil(self._CurPanel) then return end

	if self._RegisterUI ~= nil then
		local list = self._RegisterUI:GetComponent(ClassType.GNewListBase)
		if list ~= nil then
			list:EnableScroll(not b)
		end
	elseif self._CurButton ~= nil then
		local list = self._CurButton:GetComponent(ClassType.GNewListBase)
		if list ~= nil then
			list:EnableScroll(not b)
		end
		list = self._CurButton:GetComponent(ClassType.GNewListBase)
		if list ~= nil then
			list:EnableScroll(not b)
		end
	end
end

--列表相关教学特殊处理
def.method("=>","boolean").IsQuickGuide = function(self)
	if self:InGuide() and self._CurGuideTrigger ~= nil and self._CurGuideTrigger._ID == 119 and not (self._CurGuideTrigger._Step == 3) then
	 	return true
	end
	return false
end

def.method("table").GuideOnDataCallBack = function(self,panelcb)
	self:OnOpenUI(panelcb._Name)

    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        ----print("GuideOnDataCallBack=================",SmallStepConfig.ShowUIPanelName,panelcb._Name)
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == panelcb._Name then
            -- --print("教学指引层的层级为",self:GetSortingOrder())
            if SmallStepConfig.InitCallBack ~= nil then
                SmallStepConfig.InitCallBack()
            end
        end
    end
    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]
        --
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == panelcb._Name then
            -- --print("教学指引层的层级为", self:GetSortingOrder())
            if SmallStepConfig.InitCallBack ~= nil then
                SmallStepConfig.InitCallBack()
            end
        end
    end
end

def.method().TriggerDelayCallBack = function(self)
    local CGuideMan = require "Guide.CGuideMan"
    local guideConfig = CGuideMan.GetGuideMain()
    local BigStepConfig = guideConfig[self._CurGuideID]
    if BigStepConfig ~= nil then
	    local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
		if BigStepConfig.IsTriggerDelay ~= nil and BigStepConfig.IsTriggerDelay and self._CurGuideStep == 1 then
			GuideShow( self,self._CurGuideID,self._CurGuideStep )
		end
	end

    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step-1]
		if SmallStepConfig ~= nil and SmallStepConfig.IsNextStepTriggerDelay ~= nil and SmallStepConfig.IsNextStepTriggerDelay then
			self._CurGuideTrigger:GuideShow( self._CurGuideTrigger._ID,self._CurGuideTrigger._Step )
		end
    end
end

def.method("table").AnimationEndCallBack = function(self,panelcb)
	--print("AnimationEndCallBack",panelcb._Name,debug.traceback())
    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() and panelcb ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        --print("AnimationEndCallBack1111111111",SmallStepConfig.ShowUIPanelName,panelcb._Name,SmallStepConfig.IsAnimationDelay)
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == panelcb._Name and SmallStepConfig.IsAnimationDelay ~= nil then
            --print("AnimationEndCallBack222222222222")
            if SmallStepConfig.ShowDelayCallBack ~= nil then
            	--print("AnimationEndCallBack33333333")
            	ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
                SmallStepConfig.ShowDelayCallBack()
                SmallStepConfig.IsAnimationFinish = true
            end
        elseif SmallStepConfig.IsAnimationDelay ~= nil then
        	SmallStepConfig.ShowDelayCallBack()
        	SmallStepConfig.IsAnimationFinish = true
        end
    end
    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    --print("1111111111111111111111")
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil and panelcb ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]
        --print("22222222222222222",SmallStepConfig.ShowUIPanelName,panelcb._Name,SmallStepConfig.IsAnimationDelay)
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == panelcb._Name and SmallStepConfig.IsAnimationDelay ~= nil then
        	--print("3333333333333333")
            if SmallStepConfig.ShowDelayCallBack ~= nil then
            	self._CurGuideTrigger:ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
                SmallStepConfig.ShowDelayCallBack()
                SmallStepConfig.IsAnimationFinish = true
            end
        end
    end
end

def.method("number").OnServer = function(self, id)
	--print("OnServer111",id)
	self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.ServerCallBack,id)
	self:GuideTrigger(EnumDef.EGuideBehaviourID.ServerCallBack,id )
end

def.method("number").OnGatherFinish = function(self, id)
	--print("OnGatherFinish111",id)
	self:GuidePlay(self._CurGuideID,EnumDef.EGuideBehaviourID.GatherFinish,id)
	self:GuideTrigger(EnumDef.EGuideBehaviourID.GatherFinish,id )
end

def.method("string").OnOpenUI = function(self,name)
	local param = -1
	for k,v in pairs(_OpenPlayUIs) do
		if v == name then
			param = k
			break
		end
	end
	--print("OnOpenUI",name,param)
    self:GuideTrigger(EnumDef.EGuideBehaviourID.OpenUI,param)
end

def.method("string").OnCloseUI = function(self,name)
	local param = -1
	for k,v in pairs(_OpenPlayUIs) do
		if v == name then
			param = k
			break
		end
	end
	--print("OnCloseUI",name,param)
    self:GuideTrigger(EnumDef.EGuideBehaviourID.CloseUI,param)
end

--def.method("string").GuideClickCallBack = function(self,id)
def.method("string").OnClick = function(self, id)
	--print("Onclick========",id)
    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]

        if SmallStepConfig.ShowHighLightButtonName ~= nil then
            local btnName = SmallStepConfig.ShowHighLightButtonName
            if type(btnName) == "number" then
            end
            if id == btnName then
                GuideNextStep( self,self._CurGuideID,EnumDef.EGuideBehaviourID.OnClickTargetBtn,-1 )
            end
        end
    end

    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    -- --print("====================",panelTrigger,panelTrigger:IsShow(),game._CGuideMan._CurGuideTrigger)
    --print("1111111111111111",panelTrigger,panelTrigger:IsShow(),self._CurGuideTrigger)
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]

        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil and SmallStepConfig.RegisterUI ~= "" then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end

        if btnName ~= nil and id == btnName then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.OnClickTargetBtn,-1 )
        end
    end
end

def.method("string", "boolean").OnToggle = function(self, id, checked)
    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        if SmallStepConfig.ShowHighLightButtonName ~= nil and id == SmallStepConfig.ShowHighLightButtonName then
            GuideNextStep( self,self._CurGuideID,EnumDef.EGuideBehaviourID.OnClickTargetBtn,-1 )
        end
    end

    local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    print("====================",panelTrigger,panelTrigger:IsShow(),game._CGuideMan._CurGuideTrigger)
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]

        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil and SmallStepConfig.RegisterUI ~= "" then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end
        if btnName ~= nil and id == btnName then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.OnClickTargetBtn,-1 )
        end
    end
end

def.method("userdata", "string", "number").OnSelectItem = function(self, item, id, index)

    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        --print("id.name=", id, index, SmallStepConfig.NextStepTriggerParam)
        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end
        if btnName ~= nil and id == btnName and index == SmallStepConfig.NextStepTriggerParam then
            GuideNextStep( self,self._CurGuideID,EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end

	local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    print("====================",panelTrigger,panelTrigger:IsShow(),game._CGuideMan._CurGuideTrigger)
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]
        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end
        print("ShowHighLightButtonName=",self._CurGuideTrigger._ID,self._CurGuideTrigger._Step,btnName,id,index,SmallStepConfig.NextStepTriggerParam )
        if btnName ~= nil and id == btnName and index == SmallStepConfig.NextStepTriggerParam then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end
end

def.method("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
print("OnSelectItemButton========",id)
    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        --print("id.name=", id, button_obj.name,index, SmallStepConfig.NextStepTriggerParam)
        if SmallStepConfig.ShowHighLightButtonName ~= nil and button_obj.name == SmallStepConfig.ShowHighLightButtonName and index == SmallStepConfig.NextStepTriggerParam then
            GuideNextStep( self,self._CurGuideID,EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end

	local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    -- --print("====================",panelTrigger,panelTrigger:IsShow(),game._CGuideMan._CurGuideTrigger)
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]
        --print("id.name=", id, button_obj.name,index, SmallStepConfig.NextStepTriggerParam)
        if SmallStepConfig.ShowHighLightButtonName ~= nil and button_obj.name == SmallStepConfig.ShowHighLightButtonName and index == SmallStepConfig.NextStepTriggerParam then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end
end

def.method("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
print("OnTabListSelectItem========",list.name,main_index,sub_index)
    local id = list.name

    local CPanelGuide = require "GUI.CPanelGuide"
    local panel = CPanelGuide.Instance()
    if panel ~= nil and panel:IsShow() then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideMain()
        local BigStepConfig = guideConfig[self._CurGuideID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideStep]
        --print("id.name=", id, index, SmallStepConfig.NextStepTriggerParam)
        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end
        if btnName ~= nil and id == btnName and main_index == SmallStepConfig.NextStepTriggerParam then
            GuideNextStep( self,self._CurGuideID,EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end

	local CPanelGuideTrigger = require "GUI.CPanelGuideTrigger"
    local panelTrigger = CPanelGuideTrigger.Instance()
    -- --print("====================",panelTrigger,panelTrigger:IsShow(),game._CGuideMan._CurGuideTrigger)
    if panelTrigger ~= nil and panelTrigger:IsShow() and self._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._CurGuideTrigger._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._CurGuideTrigger._Step]
        local btnName = nil
        if SmallStepConfig.RegisterUI ~= nil then
        	btnName = SmallStepConfig.RegisterUI
        	--print("RegisterUI=",btnName)
        elseif SmallStepConfig.ShowHighLightButtonName ~= nil then
        	btnName = SmallStepConfig.ShowHighLightButtonName
        	--print("ShowHighLightButtonName=",btnName)
        end
        if btnName ~= nil and id == btnName and main_index == SmallStepConfig.NextStepTriggerParam then
            self:GuideTrigger(EnumDef.EGuideBehaviourID.OnClickTargetList,SmallStepConfig.NextStepTriggerParam )
        end
    end
end

--------------------------S2C-----------------------------

--改变教学数据
def.method("table").ChangeGuideData = function(self, data)
	--print( "ChangeGuideData" )
	game._CFunctionMan:ChangeFunctionData(data.GuideIdList)
	if self._GuideTriggerDataTable == nil then
		self._GuideTriggerDataTable = {}
	end
	
	for k,v in ipairs(data.GuideIdList) do
		if self._GuideTriggerDataTable[v] == nil then
			self._GuideTriggerDataTable[v] = {}
		end
		self._GuideTriggerDataTable[v].isTrigger = true

		if self._GuideTriggerDataTable[v].Guide ~= nil then
			self._GuideTriggerDataTable[v].Guide._IsFinish = true
		end

	    if self._CurGuideTrigger ~= nil and v == self._CurGuideTrigger._ID then
			self._GuideTriggerDataTable[v].Guide = self._CurGuideTrigger
			self._GuideTriggerDataTable[v].Guide._IsFinish = false
		end
	end		
	if self._CurGuideID == 0 then
		self._IsNextStepTimeLimit = false
	end

	self._LastGuideID = data.CurrId
	self._CurGuideID = self._LastGuideID + 1
	self._OpenedGuideID = data.WillId
end

------------------C2S----------------------------
--完成步骤
def.method("number").SendC2SGuideTrigger = function(self,guideID)
	local C2SGuideUpdateProgress = require "PB.net".C2SGuideUpdateProgress
	local protocol = C2SGuideUpdateProgress()
	protocol.GuideId = guideID
	PBHelper.Send(protocol)
	--print("MLMLSendC2SGuideTriggerguideID ="..guideID)
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetPipelineBreakPoint(
		PlatformSDKDef.PipelinePointType.GuideTriggerEnter,
		guideID)
end

--完成步骤
def.method("number").SendC2SGuideProgress = function(self,CurrId)
	local C2SGuideUpdateProgress = require "PB.net".C2SGuideUpdateProgress
	local protocol = C2SGuideUpdateProgress()
	--触发步骤<=10000,主线步骤>10000
	protocol.CurrId = CurrId
	PBHelper.Send(protocol)
	--print("MLMLSendC2SGuideProgress ="..CurrId)

	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetPipelineBreakPoint(
		PlatformSDKDef.PipelinePointType.GuideEnd,
		CurrId)
end

--记录已打开步骤我
def.method("number").SendC2SGuideWill = function(self,willId)
	local C2SGuideUpdateProgress = require "PB.net".C2SGuideUpdateProgress
	local protocol = C2SGuideUpdateProgress()
	--触发步骤<=10000,主线步骤>10000
	protocol.WillId = willId
	PBHelper.Send(protocol)
	--print("MLMLSendC2SGuideWill ="..willId)

	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetPipelineBreakPoint(
		PlatformSDKDef.PipelinePointType.GuideEnter,
		willId)
end

CGuideMan.Commit()
return CGuideMan