local Lplus = require "Lplus"

local Guide = Lplus.Class("Guide")
local def = Guide.define
local CQuest = require "Quest.CQuest"
local CGuideMan = Lplus.ForwardDeclare("CGuideMan")
--local CGuideMan = require "Guide.CGuideMan"
def.static("=>",Guide).New = function()
	local guide = Guide()
	return guide
end

def.field("number")._Step = 0
def.field("number")._ID = 0
def.field("table")._Config = nil
def.field("number")._MinShowTime = 1
def.field("boolean")._IsNextStepTimeLimit = true
def.field("number")._MinLimitTimerId = 0
def.field("number")._AutoShowNextStepTimeTimerId = 0

def.field("table")._CurPanel = nil
def.field("userdata")._CurButton = nil
def.field("userdata")._RegisterUI = nil
def.field("table")._Panel_script = nil
def.field("boolean")._IsFinish = false

def.method("number","number","number","=>","boolean").GuideStart = function(self,id,behaviourID,param)
	if game._HostPlayer ~= nil and game._HostPlayer:IsDead() then
		return false
	end

    local BigStepConfig = self._Config[id]

	if self._IsNextStepTimeLimit then
    		--print( "MLML/GuideNext/ IsNextStepTimeLimit is true" )
			return false
	end


	if BigStepConfig.LimitFinishQuestID ~= nil and not CQuest.Instance():IsQuestCompleted(BigStepConfig.LimitFinishQuestID) then
		return false
	end
	
	if BigStepConfig.LimitMapID ~= nil and game._CurWorld ~= nil and BigStepConfig.LimitMapID ~= game._CurWorld._WorldInfo.MapTid  then
		--print("GuidePlayID 不在限制的地图上 ",id,BigStepConfig.LimitMapID,game._CurWorld._WorldInfo.MapTid)
		return false
	end

	local hp = game._HostPlayer
	if BigStepConfig.LimitLevel ~= nil and hp ~= nil and game._HostPlayer._InfoData._Level < BigStepConfig.LimitLevel then
		return false
	end

	--如果是指定的教学行为ID
	if BigStepConfig.TriggerParamSymbol == nil then
		if (behaviourID ~= BigStepConfig.TriggerBehaviour or param ~= BigStepConfig.TriggerParam) then
			--print( "MLML/GuideStart/ GuideBehaviourID No Equal",behaviourID,BigStepConfig.TriggerBehaviour,param,BigStepConfig.TriggerParam)
			return false
		end
	elseif BigStepConfig.TriggerParamSymbol ~= nil and BigStepConfig.TriggerParamSymbol then
		if (behaviourID ~= BigStepConfig.TriggerBehaviour or param < BigStepConfig.TriggerParam) then
			--print( "MLML/GuideStart/ GuideBehaviourID No Equal",behaviourID,BigStepConfig.TriggerBehaviour,param,BigStepConfig.TriggerParam)
			return false
		end
	elseif BigStepConfig.TriggerParamSymbol ~= nil and not BigStepConfig.TriggerParamSymbol then
		if (behaviourID ~= BigStepConfig.TriggerBehaviour or param > BigStepConfig.TriggerParam) then
			--print( "MLML/GuideStart/ GuideBehaviourID No Equal",behaviourID,BigStepConfig.TriggerBehaviour,param,BigStepConfig.TriggerParam)
			return false
		end
	end

	if BigStepConfig.OpenPagePath ~= nil then
    	local frame = GameObject.Find( BigStepConfig.OpenPagePath )
    	if frame == nil or not frame.activeSelf then
    		return false
    	end
    end

    --在教学中 并且不跳过其他教学 作为开启条件
	if game._CGuideMan:InGuide() and BigStepConfig.IsNotJumpGuide ~= nil and BigStepConfig.IsNotJumpGuide then
		return false
	end

	-- 如果成功进入下一步，跳过上一步教学
	game._CGuideMan:JumpCurGuide()

	--print("BigStepConfig.TriggerBehaviour=",BigStepConfig.TriggerBehaviour)
	if BigStepConfig.TriggerBehaviour ~= EnumDef.EGuideBehaviourID.OpenUI and BigStepConfig.IsCloseAll == nil then
		game._GUIMan:CloseAll(game._CGuideMan._KeepUIs)
	end

	local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"
	CPanelSystemEntrance.Instance(): ShowFloatingFrame(false)


	self._ID = id
    self._Step = 1

    	--界面特殊处理
	local CPanelSystemEntrance = require "GUI.CPanelSystemEntrance"
	CPanelSystemEntrance.Instance(): ShowFloatingFrame(false)	
	local SmallStepConfig = BigStepConfig.Steps[self._Step]
	if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelTracker" then
		local CPanelTracker = require "GUI.CPanelTracker"
		CPanelTracker.Instance():ResetLayout()
		if SmallStepConfig.ShowHighLightButtonName ~= nil then
			if SmallStepConfig.ShowHighLightButtonName == "Item" then
				CPanelTracker.Instance():SwitchPage(2) -- 默认切换到组队界面
			elseif SmallStepConfig.ShowHighLightButtonName == "item-0" or SmallStepConfig.ShowHighLightButtonName == "item-1" then 
				CPanelTracker.Instance():SwitchPage(0) -- 默认切换到组队界面
				if CPanelTracker.Instance()._QuestPage ~= nil and CPanelTracker.Instance()._QuestPage._List ~= nil then
					CPanelTracker.Instance()._QuestPage._List:ScrollToStep( 0 )
				end
			end
		end
	end

	--界面特殊ID
	if BigStepConfig.LimitSpecialID ~= nil and BigStepConfig.LimitSpecialID == 1 then
		local CExteriorMan = require "Main.CExteriorMan"
		if not CExteriorMan.Instance():CanEnter() then
			self:GuideFinish(self._ID)
			return false
		end
	end

	-- 判断是否可以显示
	if (BigStepConfig.IsTriggerDelay == nil or not BigStepConfig.IsTriggerDelay) and self:SpecialPanelIsShow() then
		self:GuideShow( self._ID,self._Step )
	end

	

	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CQuestAutoMan.Instance():Stop()
	CDungeonAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
	return true
end

def.method("number","number","number","=>","boolean").GuideNextStep = function(self,id,behaviourID,param)
	  local nextStep = self._Step + 1
	  --print( "MLML/GuideNext/eventStep"..nextStep)
	  	if self._Step == 0 then
			--print( "MLML/GuideNext/ _Step = 0" )
			return false
		end
		if id ~= self._ID then
			--print( "MLML/GuideNext/ GuideID No Equal" )
			return false
		end

	    --检查是否可以进行下一步
	    local BigStepConfig = self._Config[id]
	    local SmallStepConfig = BigStepConfig.Steps[self._Step]
    	if self._IsNextStepTimeLimit then
    		--print( "MLML/GuideNext/ IsNextStepTimeLimit is true" )
			return false
		end

	--如果是指定的教学行为ID
	local Trigger1 = true
	if BigStepConfig.NextStepTriggerParamSymbol == nil then
		if (behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour or param ~= SmallStepConfig.NextStepTriggerParam) and behaviourID ~= -1 then
			--print( "MLML/GuideNext/ GuideBehaviourID No Equal",behaviourID,SmallStepConfig.NextStepTriggerBehaviour,param,SmallStepConfig.NextStepTriggerParam)
			Trigger1 = false
		end
	elseif BigStepConfig.NextStepTriggerParamSymbol ~= nil and BigStepConfig.TriggerParamSymbol then
		if behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour or param < SmallStepConfig.NextStepTriggerParam then
			Trigger1 = false
		end
	elseif BigStepConfig.NextStepTriggerParamSymbol ~= nil and not BigStepConfig.TriggerParamSymbol then
		if behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour or param > SmallStepConfig.NextStepTriggerParam then
			Trigger1 = false
		end
	end

	local Trigger2 = true
	if BigStepConfig.NextStepTriggerParamSymbol2 == nil then
		if SmallStepConfig.NextStepTriggerBehaviour2 == nil or behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour2 or param ~= SmallStepConfig.NextStepTriggerParam2 then
			Trigger2 = false
		end
	elseif BigStepConfig.NextStepTriggerParamSymbol2 ~= nil and BigStepConfig.TriggerParamSymbol then
		if SmallStepConfig.NextStepTriggerBehaviour2 == nil or behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour2 or param < SmallStepConfig.NextStepTriggerParam2 then
			Trigger2 = false
		end
	elseif BigStepConfig.NextStepTriggerParamSymbol2 ~= nil and not BigStepConfig.TriggerParamSymbol then
		if SmallStepConfig.NextStepTriggerBehaviour2 == nil or behaviourID ~= SmallStepConfig.NextStepTriggerBehaviour2 or param > SmallStepConfig.NextStepTriggerParam2 then
			Trigger2 = false
		end
	end

	if not Trigger1 and not Trigger2 then
		return false
	end


	--获取步骤数
    local tmpMaxStep = 0
    if BigStepConfig ~= nil and BigStepConfig.Steps ~= nil then
    	tmpMaxStep = #BigStepConfig.Steps 
    end

    if nextStep > tmpMaxStep then
    	--print( "MLML/GuideNext/ MaxStep" )
    	self:GuideFinish( self._ID )
    	return true
	end

	if SmallStepConfig.IsNextStepTriggerDelay == nil or not SmallStepConfig.IsNextStepTriggerDelay then
		self:GuideShow( id,nextStep )
	end
	self._Step = nextStep 
	return true  
end

def.method("number").GuideFinish = function(self,id)
	self:GuideClose()
	--self:SendC2SGuideTrigger( id )
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetPipelineBreakPoint(
		PlatformSDKDef.PipelinePointType.GuideTriggerEnd,
		id)
	CSoundMan.Instance():Play3DVoice("",game._HostPlayer:GetPos(),0)
end

def.method("=>","boolean").SpecialPanelIsShow = function(self)
    if (self._ID == 104 or self._ID == 106) and self._Step == 1 then
       	local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[self._ID]
        local SmallStepConfig = BigStepConfig.Steps[self._Step]
        ----print("GuideOnDataCallBack=================",SmallStepConfig.ShowUIPanelName,panel._Name)
        if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName == "CPanelTracker" then
        	local panel = require("GUI." .. SmallStepConfig.ShowUIPanelName).Instance()
    		--print("33333333333333333333",not panel:IsHidden())
    		return not panel:IsHidden()
    	end
	end
	if self._ID == 23 and self._Step == 1 then
       	return game._GUIMan:IsMainUIShowing()
	end
	--print("44444444444")
	return true
end

--找到点亮的按键
def.method("string","string","string","string","=>","boolean").ButtonLight = function(self,buttonPath,buttonName,RegisterPath,RegisterName)
	--print( "/////////////////////////////////////////"..buttonName )
	local path = ""
	if buttonPath ~= nil then
		path = buttonPath..buttonName
	else 
		path = buttonName
	end
	self._CurButton = GameObject.Find( path )

	if IsNil(self._CurButton) then
		--print("buttonPath=",path)
		--print("ButtonLight="..buttonName.."is nil !")
		return false
	end

	if IsNil(self._CurPanel) then
		return false
	end

    local cur_s_order=self._CurPanel:GetSortingOrder()
	if cur_s_order == 0 then
		return false
	end

	self._CurPanel:EffectAutoPos(self._CurButton)
	--self._CurPanel._HightLightBtn = self._CurButton

    --GameUtil.SetPanelSortingLayer(self._CurButton, self._CurPanel:GetSortingLayer())
    GameUtil.SetPanelSortingLayerOrder(self._CurButton, self._CurPanel:GetSortingLayer(), cur_s_order + GUIDE_BUTTON_ORDER_EX)
    local GraphicRaycaster = self._CurButton:GetComponent(ClassType.GraphicRaycaster)
    if GraphicRaycaster == nil then
        self._CurButton:AddComponent(ClassType.GraphicRaycaster)
    end
	if self._Panel_script ~= nil then
		self._Panel_script:RegisterGuideHandler(self._CurButton)

		if RegisterPath ~= nil then
			path = RegisterPath..RegisterName
		else
			path = RegisterName
		end

		self._RegisterUI = GameObject.Find( path )
		--判断有无注册UI，没有 则注册BUTTON，有可能出现 注册和要高亮的UI不是一个
		if self._RegisterUI ~= nil then
			self._Panel_script:RegisterGuideHandler(self._RegisterUI)
		else
			self._Panel_script:RegisterGuideHandler(self._CurButton)
		end
	end

	--如果是 TIPS类型 改变 关闭类型
	if self._Panel_script._PanelCloseType == EnumDef.PanelCloseType.Tip then
		self._Panel_script._PanelCloseType = EnumDef.PanelCloseType.None
	end
--    local canvas = self._CurButton:AddComponent(ClassType.Canvas)
--    if canvas ~= nil then
--	    canvas.overrideSorting = true
--        canvas.sortingLayer = self._CurPanel:GetSortingLayer()
--	    canvas.sortingOrder = self._CurPanel:GetSortingOrder() + GUIDE_ORDER_OFFSET
--    	--print("教学按钮的层级为=",canvas.sortingOrder,self._CurPanel:GetSortingOrder(),debug.traceback())
--    end

--    local GraphicRaycaster = self._CurButton:GetComponent(ClassType.GraphicRaycaster)
--    if GraphicRaycaster == nil then
--        self._CurButton:AddComponent(ClassType.GraphicRaycaster)
--    end

    return true 
end

--按钮恢复正常
def.method().ButtonNormal = function(self)
	if IsNil(self._CurButton) then
		return
    end
	local GraphicRaycaster = self._CurButton:GetComponent(ClassType.GraphicRaycaster)
	if GraphicRaycaster ~= nil then
		--需要立刻刪除 所以用 DestroyImmediate
	    GameObject.DestroyImmediate( GraphicRaycaster )
    end

	local Canvas = self._CurButton:GetComponent(ClassType.Canvas)
	if Canvas ~= nil then
		GameObject.DestroyImmediate( Canvas )
	end

	GameUtil.ResetMask2D(self._CurButton)

	-- if self._Panel_script ~= nil then
	-- 	self._Panel_script:UnregisterGuideHandler(self._CurButton)
	-- end
	if self._Panel_script ~= nil then
		--self._Panel_script:UnregisterGuideHandler(instance._CurButton)
		if self._RegisterUI ~= nil then
			self._Panel_script:UnregisterGuideHandler(self._RegisterUI)
		else
			self._Panel_script:UnregisterGuideHandler(self._CurButton)
		end
	end

	--如果此步骤是列表
	self:ListGuide(false)
	self._CurButton = nil
	self._RegisterUI = nil
end

def.method("number","number").GuideShow = function(self,id,step)
	--print("GuideShow------------------------------",id,step,debug.traceback())
    local BigStepConfig = self._Config[id]
    local SmallStepConfig = BigStepConfig.Steps[step]

    self:ButtonNormal()
	if not IsNil(self._CurPanel) then
		self._CurPanel:ShowNextSmallStep()
	else
		self._CurPanel = game._GUIMan:Open( "CPanelGuideTrigger",BigStepConfig )
		if self._CurPanel ~= nil then
			self._CurPanel._HightLightBtn = self._CurButton
		end
	end

	--获得当前教学的UI脚本
	self._Panel_script = nil
	if SmallStepConfig.ShowUIPanelName ~= nil and SmallStepConfig.ShowUIPanelName ~= "" then
    	self._Panel_script = require("GUI." .. SmallStepConfig.ShowUIPanelName).Instance()
    end
    
    if SmallStepConfig.ShowHighLightButtonDynamicName ~= nil then
    	local CPanelMall = require "GUI.CPanelMall"
    	local mall = CPanelMall.Instance()
    	if mall ~= nil then
	    	SmallStepConfig.ShowHighLightButtonName = mall:GetBigTabNameForGuide( tonumber(SmallStepConfig.ShowHighLightButtonDynamicName) )
	    	SmallStepConfig.NextStepTriggerParam = tonumber(SmallStepConfig.ShowHighLightButtonDynamicName) - 1

	    	--print("~~~~~~~~~~~~~~~~~~~~~",SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.NextStepTriggerParam,id,step)
	    end
    end

	--高亮按钮
	if SmallStepConfig.ShowHighLightButtonName ~= nil and SmallStepConfig.ShowHighLightButtonName ~= "" then
		--是否成功
		local isSuccess = self:ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
		--如果此步骤是列表
		if SmallStepConfig.NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickTargetList then
			self:ListGuide(true)
		end
		--如果没有成功
		if not isSuccess then
			--教学界面 初始化回调
			local function ShowUIPaneInit()
				CGuideMan.UpdateGuideSortingLayerOrder(self._CurPanel)
				self:ButtonLight( SmallStepConfig.ShowHighLightButtonPath,SmallStepConfig.ShowHighLightButtonName,SmallStepConfig.RegisterUIPath,SmallStepConfig.RegisterUI )
				--如果此步骤是列表
				if SmallStepConfig.NextStepTriggerBehaviour == EnumDef.EGuideBehaviourID.OnClickTargetList then
					self:ListGuide(true)
				end
				--没有动画延迟则 初始化时显示
				if SmallStepConfig.IsAnimationDelay == nil or not SmallStepConfig.IsAnimationDelay then
					self._CurPanel:ShowStep()
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
	    	self:GuideNextStep(id,EnumDef.EGuideBehaviourID.AutoNextGuide,-1)
	    end)
	else
		self._IsNextStepTimeLimit = false
	end

	-- 自动跳过下一步
	if SmallStepConfig.AutoShowNextStepTime ~= nil and SmallStepConfig.AutoShowNextStepTime ~= "" then
	    if self._AutoShowNextStepTimeTimerId ~= 0 then
	        _G.RemoveGlobalTimer(self._AutoShowNextStepTimeTimerId)
	        self._AutoShowNextStepTimeTimerId = 0
	    end
	    self._AutoShowNextStepTimeTimerId = _G.AddGlobalTimer(SmallStepConfig.AutoShowNextStepTime, true ,function()
	    	self:GuideNextStep(id,EnumDef.EGuideBehaviourID.AutoNextGuide,-1)
	    end)
	end
	
end

def.method().GuideClose = function(self)
    if self._MinLimitTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._MinLimitTimerId)
        self._MinLimitTimerId = 0
    end
    if self._AutoShowNextStepTimeTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._AutoShowNextStepTimeTimerId)
        self._AutoShowNextStepTimeTimerId = 0
    end
	self:ButtonNormal()
	game._GUIMan:CloseByScript(self._CurPanel)
	self._CurPanel = nil
	self._IsFinish = true
end

--列表相关教学特殊处理
def.method("boolean").ListGuide = function(self,b)
	if IsNil(self._CurPanel) then return end

	if self._RegisterUI ~= nil then
		local list = self._RegisterUI:GetComponent(ClassType.GNewListBase)
		if list ~= nil then
			list:EnableScroll(not b)
		end
		local list2 = self._RegisterUI:GetComponent(ClassType.GNewTableBase)
		if list2 ~= nil then
			list2:EnableScroll(not b)
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

Guide.Commit()
return Guide

