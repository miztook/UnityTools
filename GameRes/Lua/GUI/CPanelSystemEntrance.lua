local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CMallMan = require "Mall.CMallMan"
local CElementData = require "Data.CElementData"
local EParmType = require "PB.Template".ItemApproach.EParmType
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = Lplus.ForwardDeclare("CQuest")

local SystemEntranceCfgTable = nil
-- 单个功能按钮的封装
local CFunctionButton = Lplus.Class("CFunctionButton")
do
	local def = CFunctionButton.define

	def.field("number")._FunctionID = 0 
	def.field("userdata")._BtnObj = nil
	def.field("userdata")._IconImgObj = nil
	def.field("userdata")._NameLabelObj = nil
	def.field("userdata")._RedPointImgObj = nil
	def.field("userdata")._LockImgObj = nil
	def.field("boolean")._IgnoreLockState = false

	def.static("number", "userdata", "userdata", "userdata", "userdata", "boolean", "userdata", "=>", CFunctionButton).new = function(funcId, btnObj, iconObj, nameObj, rpObj, ignoreLock, lockObj)
		local obj = CFunctionButton()
		obj._FunctionID = funcId
		obj._BtnObj = btnObj
		obj._IconImgObj = iconObj
		obj._NameLabelObj = nameObj
		obj._RedPointImgObj = rpObj
		obj._LockImgObj = lockObj
		obj._IgnoreLockState = ignoreLock
		obj:InitUI()
		return obj
	end

	def.method().InitUI = function(self)
		local funcConfig = SystemEntranceCfgTable
		local cfgInfo = funcConfig[self._FunctionID]
	    if cfgInfo ~= nil then
			GUITools.SetIcon(self._IconImgObj, "System/" .. cfgInfo.IconPath)
			GUI.SetText(self._NameLabelObj, cfgInfo.Name)
		end
		self:UpdateLockStatus()
	end

	def.method().UpdateLockStatus = function(self)
		if self._IgnoreLockState then return end
		local unlock = game._CFunctionMan:IsUnlockByFunID(self._FunctionID)
		if self._LockImgObj ~= nil then
			CRedDotMan.UpdateSystemUnlockState(self._BtnObj.name,unlock)
			self._LockImgObj:SetActive(not unlock)
		end

		local iconAlpha, bgAlpha = 255, 255
		if not unlock then
			iconAlpha, bgAlpha = 25, 76
		end
		GUI.SetAlpha(self._IconImgObj, iconAlpha)
		GUI.SetAlpha(self._NameLabelObj, iconAlpha)
		GUI.SetAlpha(self._BtnObj:GetChild(0), bgAlpha)
	end

	def.method("=>", "boolean").TriggerFunc = function(self)
		if game._CFunctionMan:IsUnlockByFunID(self._FunctionID) then   -- self._IgnoreLockState or 
			game._GUIMan:OpenPanelByFuncId(self._FunctionID)
			return true
		else
			return false
		end
	end
end
CFunctionButton.Commit()

local CPanelSystemEntrance = Lplus.Extend(CPanelBase, "CPanelSystemEntrance")
do
	local def = CPanelSystemEntrance.define

	def.field('userdata')._BtnOpen = nil
	def.field('userdata')._BtnClose = nil
	def.field('userdata')._FrameFloat = nil
    def.field("userdata")._DragableBannerPage = nil
    def.field("userdata")._ListBannerToggleGroup = nil
	def.field('table')._FunctionObjs = nil
    def.field("table")._OpenedBanner = nil

	def.field("table")._ListPlayFxBtnId = nil --需要显示特效的BtnID
	-- def.field("number")._FXTimerID = 0--特效计时器

	def.field("number")._MAX_BTN = 15

	local instance = nil
	def.static("=>", CPanelSystemEntrance).Instance = function ()
		if instance == nil then
			instance = CPanelSystemEntrance()
			instance._PrefabPath = PATH.UI_SystemEntrance
			instance._DestroyOnHide = false
	        instance:SetupSortingParam()
		end
		return instance
	end

	local RegularFuncIds = {38, 49, 7, 19}
	local FloatingFuncIds = {30, 0, 1, 32, 31, 48, 2, 11, 34, 43, 6, 33, 35, 37, 50}

	def.override().OnCreate = function(self)
		self._BtnOpen = self:GetUIObject("Btn_Open")
		self._BtnClose = self:GetUIObject("Btn_Close")
		self._FrameFloat = self:GetUIObject("FrameFloat")
        self._DragableBannerPage = self:GetUIObject("DragblePanel")
        self._ListBannerToggleGroup = self:GetUIObject("List_PageToggles")
        self._OpenedBanner = CMallMan.Instance():GetAllOpenedBanner()
		self:LoadFxBtnID()
		self:UpdateRedPointStatus()
        
	end

	-- 监听功能解锁
	local function OnNotifyFunctionEvent(sender, event)
		if instance ~= nil and instance:IsShow() then
			if event.FunID == 21 or event.FunID == 22 or event.FunID == 23 then
				-- 坐骑、时装、翅膀功能解锁时，更新外观红点
				local CExteriorMan = require "Main.CExteriorMan"
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, CExteriorMan.Instance():IsShowRedPoint())
			end
		end
	end

    -- 监听物品获得的事件
    local function OnGainNewItemEvent(sender, event)
        if instance ~= nil and instance:IsShow() then
            instance:UpdateRedPointStatus()
        end
    end

    local function OnBannerInfoUpdate(sender, event)
        if instance ~= nil and instance:IsShow() then
            instance._OpenedBanner = CMallMan.Instance():GetAllOpenedBanner()
            instance:UpdateBanner()
        end
    end

	def.override("dynamic").OnData = function(self, data)
	    if self._FunctionObjs == nil then
	    	local cfgPath = _G.ConfigsDir.."SystemEntranceCfg.lua"
	    	SystemEntranceCfgTable = _G.ReadConfigTable(cfgPath)

		    self._FunctionObjs = {}	    
		    for i,v in ipairs(RegularFuncIds) do   -- Btn1 - 4, Img_Icon13-16
				local key = "Btn" .. i
		    	local btnObj = self:GetUIObject(key)
				local iconObj = btnObj:FindChild("Img_Icon")     -- self:GetUIObject("Img_Icon" .. idx)
				local nameObj = btnObj:FindChild("Img_Icon/Lab_Name")		-- self:GetUIObject("Lab_Name" .. idx)
				local rpObj = btnObj:FindChild("Img_Icon/Img_RedPoint")	-- self:GetUIObject("Img_RedPoint" .. idx)
				local lockObj = nil -- self:GetUIObject(key)
				self._FunctionObjs[key] = CFunctionButton.new(v, btnObj, iconObj, nameObj, rpObj, true, lockObj)
		    end

		    for i = 1,self._MAX_BTN do
		    	local key = "Btn_F" .. i
		    	local btnObj = self:GetUIObject(key)
		    	if i > #FloatingFuncIds then
		    		btnObj: SetActive(false)
		    	else
		    		btnObj: SetActive(true)
					local iconObj = btnObj:FindChild("Img_bg/Img_Icon")     -- self:GetUIObject("Img_Icon" .. idx)
					local nameObj = btnObj:FindChild("Img_bg/Lab_Name")		-- self:GetUIObject("Lab_Name" .. idx)
					local rpObj = btnObj:FindChild("Img_bg/Img_RedPoint")	-- self:GetUIObject("Img_RedPoint" .. idx)
					local lockObj = btnObj:FindChild("Img_bg/Img_Lock") 	--self:GetUIObject("Img_Lock" .. idx)
		    		self._FunctionObjs[key] = CFunctionButton.new(FloatingFuncIds[i], btnObj, iconObj, nameObj, rpObj, false, lockObj)
		    	end
		    end

		    CGame.EventManager:addHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)
            CGame.EventManager:addHandler("GainNewItemEvent", OnGainNewItemEvent)
            CGame.EventManager:addHandler("BannerInfoUpdate", OnBannerInfoUpdate)

		    SystemEntranceCfgTable = nil
		    _G.Unrequire(cfgPath)
		end
	   
	    self:ShowFloatingFrame(false)
         
		self:UpdateBanner()
	      -- 设置按钮红点状态
    	CRedDotMan.UpdateSystemEntranceRedDotShow(self)

	       --将所有未播放解锁动画的按钮锁住
	    -- if self._ListPlayFxBtnId == nil or #self._ListPlayFxBtnId <= 0 then return end
	    -- for _,v in ipairs(self._ListPlayFxBtnId) do
	    -- 	if self._FunctionObjs[v] ~= nil then
	    -- 		if self._FunctionObjs[v]._LockImgObj ~= nil  then
	    -- 			self._FunctionObjs[v]._LockImgObj: SetActive(true)
	    -- 		end
	    -- 	end
	    -- end
	end

	def.method("boolean").ShowFloatingFrame = function(self, show)
		if self._BtnOpen == nil or self._BtnClose == nil or self._FrameFloat == nil then return end
		self._BtnOpen:SetActive(not show)
	    self._BtnClose:SetActive(show)
	    self._FrameFloat:SetActive(show)
	    --self:UpdateLockStatus()

		-- 关闭时隐藏文字。。。2018/11/5 lidaming
		for i,v in ipairs(RegularFuncIds) do   -- Btn1 - 4, Img_Icon13-16
			local key = "Btn" .. i
			local idx = 12 + i
			local nameObj = self:GetUIObject("Lab_Name" .. idx)
			nameObj:SetActive(show)
		end
		
		-- self: RemoveFXTimer()
		if show then
			if self._ListPlayFxBtnId == nil or #self._ListPlayFxBtnId <= 0 then return end
			print_r(self._ListPlayFxBtnId)
			local PlayFxBtnIdCount = #self._ListPlayFxBtnId
			for i,v in ipairs(self._ListPlayFxBtnId) do
				self:PlayOpenUIFx(self._ListPlayFxBtnId[i])
				if i == #self._ListPlayFxBtnId then
					self._ListPlayFxBtnId = {}
				end
			end
			self:UpdateLockStatus()
	    	-- local function callback( ... )
	    	-- 	if self._ListPlayFxBtnId ~= nil and #self._ListPlayFxBtnId > 0 then
	    	-- 		self:PlayOpenUIFx(self._ListPlayFxBtnId[1])
	    	-- 		self._FXTimerID = _G.AddGlobalTimer(1, true, callback)
	    	-- 	end
	    	-- end
	    	
	    	-- self:PlayOpenUIFx(self._ListPlayFxBtnId[1])
	    	-- self._FXTimerID = _G.AddGlobalTimer(1, true, callback)
	    end
	end

	def.method().UpdateLockStatus = function(self)
		if self._FunctionObjs == nil then return end

	    for k,v in pairs(self._FunctionObjs) do
	    	v:UpdateLockStatus()
	    end
	end

    def.method().UpdateBanner = function(self)
        if self._OpenedBanner ~= nil and  #self._OpenedBanner > 0 then
            local drag_view = self._DragableBannerPage:GetComponent(ClassType.GDragablePageView)
            local banner_data = self._OpenedBanner[1]
            local banner_temp = CElementData.GetTemplate("Banner", banner_data.BannerTid)
            self._DragableBannerPage:SetActive(true)
            self._ListBannerToggleGroup:SetActive(true)
            self._ListBannerToggleGroup:GetComponent(ClassType.GNewList):SetItemCount(#self._OpenedBanner)
            drag_view:SetPageItemCount(#self._OpenedBanner)
            drag_view:SetTimeInterval(banner_temp.DisplayTime)
            GUI.SetGroupToggleOn(self._ListBannerToggleGroup, 1)
        else
            self._DragableBannerPage:SetActive(false)
            self._ListBannerToggleGroup:SetActive(false)
        end
    end

	def.method().SDKCommunityLogic = function(self)
		-- SDK 提供的活动界面入口，社区
		TODO("SDK::SDK 社区接口 WebView")
	end

	def.override("string").OnClick = function(self, id)
		if id == "Btn_Open" then
			if game._GUIMan:IsFuncForbid(EnumDef.EGuideTriggerFunTag.RoleMenu) then return end
			self:ShowFloatingFrame(true)
		elseif id == "Btn_Close" then
			self:ShowFloatingFrame(false)
		else
			if self._FunctionObjs ~= nil then
				local fbObj = self._FunctionObjs[id]
				if fbObj ~= nil then
					if fbObj:TriggerFunc() then
						self:ShowFloatingFrame(false)
					else
						-- [23] = "功能尚未开启",
						-- game._GUIMan:ShowTipText(StringTable.Get(23), false)
						-- warn("============>>> ", fbObj._FunctionID)
						game._CGuideMan:OnShowTipByFunUnlockConditions(1, fbObj._FunctionID)
					end
				end
			end
		end
	end

    def.override("userdata", "string", "number").OnInitItem = function (self, item, id, index)
        local index = index + 1
        if id == "DragblePanel" then
            local banner_data = self._OpenedBanner[index]
            local banner_temp = CElementData.GetTemplate("Banner", banner_data.BannerTid)
            local uiTemplate = item:GetComponent(ClassType.UITemplate)
            local img_item = uiTemplate:GetControl(0)
            if banner_temp ~= nil then
                GUITools.SetItemIcon(img_item, banner_temp.IconPath)
            end
        end
    end

    def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
        local index = index + 1
        if id == "DragblePanel" then
            -- 点击banner的item跳转
            local banner_data = self._OpenedBanner[index]
            local banner_temp = CElementData.GetTemplate("Banner", banner_data.BannerTid)
            if banner_temp ~= nil then
                local  approachItem = CElementData.GetItemApproach(banner_temp.ItemApproachId)
                if approachItem and approachItem.ClickType == EParmType.OpenUI then
                    game._AcheivementMan:DrumpToRightPanel(approachItem.Id, 0)
                end
            end
        end
    end

    -- Banner手动滑或者自动滑的时候，index变化会回调这个方法
    def.override("userdata", "string", "number").OnDragablePageIndexChange = function(self, item_go, pageViewName, index)
        if pageViewName == "DragblePanel" then
            local index = index + 1
            local banner_data = self._OpenedBanner[index]
            local banner_temp = CElementData.GetTemplate("Banner", banner_data.BannerTid)
            if banner_temp ~= nil and banner_temp.DisplayTime > 0 then
                self._DragableBannerPage:GetComponent(ClassType.GDragablePageView):SetTimeInterval(banner_temp.DisplayTime)
            else
                self._DragableBannerPage:GetComponent(ClassType.GDragablePageView):SetTimeInterval(0)
            end

            GUI.SetGroupToggleOn(self._ListBannerToggleGroup, index + 1)
        end
    end

	def.method("string","=>","table").GetBtnObjectby = function(self, id)
		--显示右上角图标
		if self._FunctionObjs[id] == nil then return self._BtnOpen.position end

		if self._FrameFloat.activeSelf then--界面开启的时候显示固定图标
			return self._FunctionObjs[id]._BtnObj.position
		else--显示右上角图标
			return self._BtnOpen.position
		end
	end

	def.method("string","=>","boolean").IsContainKey = function(self, id)
		if self._ListPlayFxBtnId == nil or #self._ListPlayFxBtnId <= 0 then
			return false
		end
		for i,v in ipairs(self._ListPlayFxBtnId) do
			if v == id then
				return true
			end
		end
		return false
	end

	def.method("string").PlayOpenUIFx = function(self, id)
		-- 假设传过来的值可以作数字，则意味着直接解锁，需要循环判断当前key
		--warn("lidaming PlayOpenUIFx id :", id, debug.traceback())
		local tid = tonumber(id)
		if tid ~= nil then
			local flag = true	
			for i, v in pairs(self._FunctionObjs) do
				if v._FunctionID == tid then
					id = i
					flag = false
				end
			end
			if flag then
				return
			end
		end
		CRedDotMan.UpdateSystemUnlockState(id,true)
		if self._FrameFloat.activeSelf then--界面开启的时候显示固定图标
			if self._FunctionObjs[id] == nil then return end
			CRedDotMan.UpdateSystemEntranceRedDotShow(self)
			
			if self._FunctionObjs[id]._LockImgObj ~= nil  then
	    		GameUtil.PlayUISfx(PATH.UIFX_CommonUnlock, self._FunctionObjs[id]._LockImgObj, self._Panel, -1)
	    	else
	    		GameUtil.PlayUISfx(PATH.UIFX_CommonUnlock, self._FunctionObjs[id]._IconImgObj, self._Panel, -1)
	    	end
	    	CRedDotMan.UpdateSystemEntranceRedDotShow(self)
			self._FunctionObjs[id]:UpdateLockStatus()

			-- if self._ListPlayFxBtnId == nil or #self._ListPlayFxBtnId <= 0 then return end
			-- table.removebyvalue(self._ListPlayFxBtnId, id, false)
		else
			CRedDotMan.UpdateSystemMenuButtonShow()
			if self._ListPlayFxBtnId == nil then
				self._ListPlayFxBtnId = {}
			end

			if self: IsContainKey(id) then return end			
			self._ListPlayFxBtnId[#self._ListPlayFxBtnId + 1] = id
		end
	end

	-- def.method().RemoveFXTimer = function(self)
	-- 	if self._FXTimerID then
    --     	_G.RemoveGlobalTimer(self._FXTimerID)
    --     	self._FXTimerID = 0
    -- 	end	
	-- end

	--销毁界面的时候，还有解锁特效未播放
	def.method().SaveFxBtnIDToData = function (self)
		local account = game._NetMan._UserName
		local UserData = require "Data.UserData"
		local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account)
		if accountInfo == nil then
			accountInfo = {}
		end
		local serverName = game._NetMan._ServerName
		if accountInfo[serverName] == nil then
			accountInfo[serverName] = {}
		end
				
		local roleIndex = game._HostPlayer._ID  
		if accountInfo[serverName][roleIndex] == nil then
			accountInfo[serverName][roleIndex] = {}
		end

		local listFxBtnName = accountInfo[serverName][roleIndex]["fxBtnName"]
		listFxBtnName = {}--不管有没有新数据，全都重新存一遍	

		if self._ListPlayFxBtnId ~= nil and #self._ListPlayFxBtnId > 0 then		
			for i,v in ipairs(self._ListPlayFxBtnId) do
				listFxBtnName[#listFxBtnName + 1] = v			
			end
		else
			accountInfo[serverName][roleIndex]["fxBtnName"] = nil
		end

		accountInfo[serverName][roleIndex]["fxBtnName"] = listFxBtnName
		UserData.Instance():SetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account, accountInfo)
	end

	-- 获取解锁特效
	def.method().LoadFxBtnID = function (self)
		local account = game._NetMan._UserName
		local UserData = require "Data.UserData"
		local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account)
		if accountInfo ~= nil then
			local serverInfo = accountInfo[game._NetMan._ServerName]
			if serverInfo ~= nil then
				local roleInfo = serverInfo[game._HostPlayer._ID]
				if roleInfo ~= nil then
					local listFx = roleInfo["fxBtnName"]
					if listFx ~= nil then
						if self._ListPlayFxBtnId == nil then
							self._ListPlayFxBtnId = {}
						end

						for i,v in ipairs(listFx) do
							self._ListPlayFxBtnId[i] = v
						end

						--listFx = nil
						UserData.Instance():SetCfg(EnumDef.LocalFields.UnlockUIFxPlayStatus, account, accountInfo)
					end
				end
			end
		end
	end

	-- 更新按钮红点状态
	def.method().UpdateRedPointStatus = function(self)
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
		
		local CExteriorMan = require "Main.CExteriorMan"
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, CExteriorMan.Instance():IsShowRedPoint())
		local CWingsMan = require "Wings.CWingsMan"
		local bShow = CWingsMan.Instance():IsShowRedPoint()
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.WingDevelop, bShow)
        local CCharmMan = require "Charm.CCharmMan"
		CCharmMan.Instance():ShowRedPointIfNeed()
		
		local CSkillUtil = require "Skill.CSkillUtil"
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Skill, CSkillUtil.IsSkillRuneMasteryCanLvUp())
	end

	def.override().OnHide = function(self)
		CGame.EventManager:removeHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)
        CGame.EventManager:removeHandler("GainNewItemEvent", OnGainNewItemEvent)
        CGame.EventManager:removeHandler("BannerInfoUpdate", OnBannerInfoUpdate)
	end

	def.override().OnDestroy = function(self)		
		self:SaveFxBtnIDToData()	
		self._ListPlayFxBtnId = nil	

		self._BtnOpen = nil
		self._BtnClose = nil
		self._FrameFloat = nil
		self._FunctionObjs = nil
        self._DragableBannerPage = nil
        self._ListBannerToggleGroup = nil
        self._OpenedBanner = nil
	end
end

CPanelSystemEntrance.Commit()

return CPanelSystemEntrance
