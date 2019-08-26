local Lplus = require "Lplus"
local UISetting = require "Data.UISettingConfig"
local ApplicationQuitEvent = require "Events.ApplicationQuitEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CPanelBase = require 'GUI.CPanelBase'
local bit = require "bit"

-- msgbox的UI对象，此Prefab唯一
local CMsgBoxPanel = Lplus.Extend(CPanelBase, "CMsgBoxPanel")
do 
	local CMsgBoxMan = Lplus.ForwardDeclare("CMsgBoxMan")
	local def = CMsgBoxPanel.define
    local instance = nil
    def.field("table")._PanelObject = nil
	def.field('number')._PosXOfBtnYes = 0
	def.field('number')._PosXOfBtnNo = 0
    def.field('number')._Priority = MsgBoxPriority.Normal
	def.field("number")._CurType = 0 --MsgBoxType.MBBT_OKCANCEL
	def.field('number')._TimerId = 0
    def.field('number')._MsgGUID = -1

	def.field("table")._MsgBoxData = nil
	def.field("number")._CurBoxId = 0
	def.field("string")._StrOfYes = ""
	def.field("string")._StrOfNo = ""
	def.field("boolean")._IsInCallback = false

    def.static("=>", CMsgBoxPanel).Instance = function ()
        if not instance then
            instance = CMsgBoxPanel()
            instance._PrefabPath = PATH.UI_MessageBox
            instance._DestroyOnHide = false
            instance._PanelCloseType = EnumDef.PanelCloseType.None
            --instance:SetupSortingParam()
        end
	    return instance
    end

--	--按stack式取UI时是否计入
--	def.override("=>", "boolean").IsCountAsUI = function(self)
--		return false
--	end

    local function OnApplicationQuit(sender, event)
        MsgBox.RemoveAllBoxesData()
    end

	def.method("number").SetPriority = function(self, priority)
        if priority == MsgBoxPriority.Disconnect then
            self._CfgPath=PATH.UI_MessageBox2
        elseif priority == MsgBoxPriority.Quit then
            self._CfgPath=PATH.UI_MessageBox3
        elseif priority == MsgBoxPriority.ImportantTip then
            self._CfgPath=PATH.UI_MessageBox2
		elseif priority == MsgBoxPriority.Guide then
            self._CfgPath=PATH.UI_MessageBox1
		else
            self._CfgPath=PATH.UI_MessageBox
		end
		self:SetupSortingParam()
	end

	def.override().OnCreate = function(self)
        self._PanelObject = {}

	    self._PanelObject._LabMsgTitle = self:GetUIObject('Lab_MsgTitle')
	    self._PanelObject._LabMessage = self:GetUIObject('Lab_Message')
	    self._PanelObject._LabSpec = self:GetUIObject('Lab_Special')
	    self._PanelObject._BtnYes = self:GetUIObject('Btn_Yes')
	    self._PanelObject._BtnNo = self:GetUIObject('Btn_No')
	    self._PanelObject._LabYes = self:GetUIObject('Lab_Yes')
	    self._PanelObject._LabNo = self:GetUIObject('Lab_No')
	    self._PanelObject._LabTips = self:GetUIObject('Lab_CloseTips')
        self._PanelObject._CheckBoxShow = self:GetUIObject('CheckBox_ShowAgain')
        self._PanelObject._Img_MsgBG = self:GetUIObject('Img_MessageBg')
        self._PanelObject._BtnClose = self:GetUIObject('Btn_Close')
        self._PanelObject._Img_MoneyBG = self:GetUIObject("Img_MoneyBG")
        self._PanelObject._Img_MoneyIcon = self:GetUIObject("Img_MoneyIcon")
        self._PanelObject._Lab_CostNumber = self:GetUIObject("Lab_CostNumber")
        self._PanelObject._ItemIconNew = self:GetUIObject("ItemIconNew")
        self._PanelObject._Lab_ItemName = self:GetUIObject("Lab_ItemName")
        self._PanelObject._Frame_Middle = self:GetUIObject("Frame_Middle")
	    local rect = self._PanelObject._BtnYes:GetComponent(ClassType.RectTransform)
	    self._PosXOfBtnYes = rect.anchoredPosition.x

	    rect = self._PanelObject._BtnNo:GetComponent(ClassType.RectTransform)
	    self._PosXOfBtnNo = rect.anchoredPosition.x

	    self._PanelObject._LabSpec:SetActive(false)
        self._PanelObject._CheckBoxShow:SetActive(false)
	    self._PanelObject._LabTips:SetActive(false)
        self._PanelObject._Img_MoneyBG:SetActive(false)
        self._PanelObject._ItemIconNew:SetActive(false)
	    self._PanelObject._BtnClose:SetActive(true)
	    self._StrOfYes = StringTable.Get(2)
	    self._StrOfNo = StringTable.Get(1)
        CGame.EventManager:addHandler(ApplicationQuitEvent, OnApplicationQuit)
	end

	def.override('dynamic').OnData = function(self, data)
        local new_data = CMsgBoxMan.Instance():GetChacheMsgData()
        if new_data ~= nil then
            data = new_data
            CMsgBoxMan.Instance():ReSetChacheMsgData()
        end
        if self._TimerId > 0 then
	        _G.RemoveGlobalTimer(self._TimerId)
	        self._TimerId = 0 
	    end
        if data == nil then
		    warn("error !!!! MessageBox 参数不能为空")
        else
            self._MsgBoxData = data
		    self._CurBoxId = data._MsgboxID
            self._Priority = data._Priority
            self:Update(data)
        end
        --ReSetSortingLayerByPriority(self)
        --self:SetupUISorting()
        if self._PanelObject._CheckBoxShow then
            self._PanelObject._CheckBoxShow:GetComponent(ClassType.Toggle).isOn = false
        end
        self._Panel:FindChild("Frame"):SetActive(false)
        self._Panel:FindChild("Frame"):SetActive(true)
	end

    -- 更新额外附加的UI的显示
    def.method("table").UpdateAddPart = function(self, msgData)
        if self._PanelObject._Frame_Middle then
            if (msgData._CostItemID == nil or msgData._CostItemID <= 0)
                and (msgData._CostMoneyID == nil or msgData._CostMoneyID <= 0)
                and (msgData._GainItemID == nil or msgData._GainItemCount <= 0)
                and (msgData._GainMoneyID == nil or msgData._GainMoneyCount <= 0)
                and (msgData._SpecTip == nil or msgData._SpecTip == "")
                and (msgData._NotShowTag ~= nil or msgData._NotShowTag == "") then
                self._PanelObject._Frame_Middle:SetActive(false)
            else
                self._PanelObject._Frame_Middle:SetActive(true)
            end
        end
        -- 消耗物品的UI
        if msgData._CostItemID > 0 or msgData._GainItemID > 0 then
            self._PanelObject._ItemIconNew:SetActive(true)
            local is_cost = msgData._CostItemID > 0
            local lab_number = self._PanelObject._ItemIconNew:FindChild("Frame_ItemIcon/Lab_Number")
            local count_str = ""
            if is_cost then
                local have_count = game._HostPlayer._Package._NormalPack:GetItemCount(msgData._CostItemID)
                if have_count >= msgData._CostItemCount then
                    count_str = string.format(StringTable.Get(20082), have_count, msgData._CostItemCount)
                else
                    count_str = string.format(StringTable.Get(20081), have_count, msgData._CostItemCount)
                end
                local setting = {
                    [EItemIconTag.Grade] = msgData._Star,
                }
                IconTools.InitItemIconNew(self._PanelObject._ItemIconNew, msgData._CostItemID, setting, EItemLimitCheck.AllCheck)
                GUI.SetText(self._PanelObject._Lab_ItemName, RichTextTools.GetItemNameRichText(msgData._CostItemID, 1, false))
            else
                local have_count = game._HostPlayer._Package._NormalPack:GetItemCount(msgData._GainItemID)
                local setting = {
                    [EItemIconTag.Grade] = msgData._Star,
                }
                count_str = string.format(StringTable.Get(20082), have_count, msgData._GainItemCount)
                IconTools.InitItemIconNew(self._PanelObject._ItemIconNew, msgData._GainItemID, setting, EItemLimitCheck.AllCheck)
                GUI.SetText(self._PanelObject._Lab_ItemName, RichTextTools.GetItemNameRichText(msgData._GainItemID, 1, false))
            end
            GUI.SetText(lab_number, count_str)
        else
            self._PanelObject._ItemIconNew:SetActive(false)
        end
        -- 消耗货币的UI
        if msgData._CostMoneyID > 0 or msgData._GainMoneyID > 0 then
            self._PanelObject._Img_MoneyBG:SetActive(true)
            local is_cost = msgData._CostMoneyID > 0
            if is_cost then
                GUITools.SetTokenMoneyIcon(self._PanelObject._Img_MoneyIcon, msgData._CostMoneyID)
                local have_count = game._HostPlayer:GetMoneyCountByType(msgData._CostMoneyID)
                if have_count >= msgData._CostMoneyCount then
                    GUI.SetText(self._PanelObject._Lab_CostNumber, GUITools.FormatNumber(msgData._CostMoneyCount, false))
                else
                    GUI.SetText(self._PanelObject._Lab_CostNumber, string.format(StringTable.Get(20446), GUITools.FormatNumber(msgData._CostMoneyCount, false)))
                end
            else
                GUITools.SetTokenMoneyIcon(self._PanelObject._Img_MoneyIcon, msgData._GainMoneyID)
                GUI.SetText(self._PanelObject._Lab_CostNumber, GUITools.FormatNumber(msgData._GainMoneyCount, false))
            end
        else
            self._PanelObject._Img_MoneyBG:SetActive(false)
        end
        -- 特殊提示的UI
        if msgData._SpecTip ~= nil and msgData._SpecTip ~= "" then
            self._PanelObject._LabSpec:SetActive(true)
    		GUI.SetText(self._PanelObject._LabSpec, msgData._SpecTip)
        else
            self._PanelObject._LabSpec:SetActive(false)
        end
        local isNotShowAgain = (msgData._NotShowTag ~= nil and msgData._NotShowTag ~= "")
        self._PanelObject._CheckBoxShow:SetActive(isNotShowAgain)
    end

	def.method('table').Update = function(self, msgData)
		GUI.SetText(self._PanelObject._LabMsgTitle, msgData._Title)
		GUI.SetText(self._PanelObject._LabMessage, msgData._Message)

        local msgBoxType = msgData._Type
		if msgBoxType ~= self._CurType then
			-- 类型不同才需要更改的内容
            local isNOCloseBtn = msgData._IsNOCloseBtn
			self._PanelObject._LabTips:SetActive(msgData._IsNoBtn)
--            local bgRect = self._PanelObject._Img_MsgBG:GetComponent(ClassType.RectTransform)
			if isNOCloseBtn then
				self._PanelObject._BtnClose:SetActive(false)
			else
				self._PanelObject._BtnClose:SetActive(true)
			end
			if msgData._IsNoBtn then
				self._PanelObject._BtnYes:SetActive(false)
				self._PanelObject._BtnNo:SetActive(false)
                --bgRect.sizeDelta = Vector2.New(bgRect.rect.width,294)
			else
                --bgRect.sizeDelta = Vector2.New(bgRect.rect.width,189)
				--local info_icon = (bit.band(msgBoxType, MsgBoxType.MBT_INFO) > 0)
				--local ok_icon = (bit.band(msgBoxType, MsgBoxType.MBT_OK) > 0)
				--local warn_icon = (bit.band(msgBoxType, MsgBoxType.MBT_WARN) > 0)

				-- TODO: 将来如果要换不同的图标，请在这里继续

				local isShowOKCancel = (bit.band(msgBoxType, MsgBoxType.MBBT_OKCANCEL) == MsgBoxType.MBBT_OKCANCEL)
				local isShowYesNo = (bit.band(msgBoxType, MsgBoxType.MBBT_YESNO) == MsgBoxType.MBBT_YESNO)
				local isShowOk = (bit.band(msgBoxType, MsgBoxType.MBBT_OK) == MsgBoxType.MBBT_OK)
				local isShowCancel = (bit.band(msgBoxType, MsgBoxType.MBBT_CANCEL) == MsgBoxType.MBBT_CANCEL)
				--local isShowCheckBox = (bit.band(msgBoxType, MsgBoxType.MBBT_CHECKBOX) > 0)
				local isShowYes = (bit.band(msgBoxType, MsgBoxType.MBBT_YES) == MsgBoxType.MBBT_YES)
				local isShowNo = (bit.band(msgBoxType, MsgBoxType.MBBT_NO) == MsgBoxType.MBBT_NO)

				if isShowOKCancel or isShowYesNo then
					self._PanelObject._BtnYes:SetActive(true)
	            	self._PanelObject._BtnNo:SetActive(true)
	            	local rect = self._PanelObject._BtnYes:GetComponent(ClassType.RectTransform)
		            rect.anchoredPosition = Vector2.New(self._PosXOfBtnYes,rect.anchoredPosition.y)
		            rect = self._PanelObject._BtnNo:GetComponent(ClassType.RectTransform)
		            rect.anchoredPosition = Vector2.New(self._PosXOfBtnNo,rect.anchoredPosition.y)
				elseif isShowOk or isShowYes then
					self._PanelObject._BtnYes:SetActive(true)
	            	self._PanelObject._BtnNo:SetActive(false)
	            	local rect = self._PanelObject._BtnYes:GetComponent(ClassType.RectTransform)
	            	rect.anchoredPosition = Vector2.New(0,rect.anchoredPosition.y)
	            elseif isShowCancel or isShowNo then
					self._PanelObject._BtnYes:SetActive(false)
	            	self._PanelObject._BtnNo:SetActive(true)
	            	local rect = self._PanelObject._BtnNo:GetComponent(ClassType.RectTransform)
	            	rect.anchoredPosition = Vector2.New(0,rect.anchoredPosition.y)
				end

				if isShowOk then
					self._StrOfYes = StringTable.Get(2)
				elseif isShowYes then
					self._StrOfYes = StringTable.Get(4)
				end
				GUI.SetText(self._PanelObject._LabYes, self._StrOfYes)

				if isShowCancel then
					self._StrOfNo = StringTable.Get(1)
				elseif isShowNo then
					self._StrOfNo = StringTable.Get(3)
				end
				GUI.SetText(self._PanelObject._LabNo, self._StrOfNo)
			end
			self._CurType = msgBoxType
            if msgData._IsNoBtn then
                self._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
            else
                self._PanelCloseType = EnumDef.PanelCloseType.None
            end
            self:UpdateAddPart(msgData)
		end

	    if self._TimerId > 0 then
	        _G.RemoveGlobalTimer(self._TimerId)
	        self._TimerId = 0
	    end

		local isTimeYes = (bit.band(msgBoxType, MsgBoxType.MBT_TIMEYES) == MsgBoxType.MBT_TIMEYES)
		local isTimeNo = (bit.band(msgBoxType, MsgBoxType.MBT_TIMENO) == MsgBoxType.MBT_TIMENO)
	    if msgData._LifeTime > 0 then
	    	local life_time = msgData._LifeTime
	    	local time_str = StringTable.Get(21)
	        self._TimerId = _G.AddGlobalTimer(1, false, function()
	        	life_time = life_time - 1
	        	if life_time <= 0 then
	        		-- 没有按钮类型不走这套逻辑
	            	self:OnTimerOut(isTimeYes)
	            else
					if msgData._IsNoBtn then
		        		GUI.SetText(self._PanelObject._LabTips, string.format(time_str, life_time))
		        	else
		        		if isTimeYes then
		        			GUI.SetText(self._PanelObject._LabYes, self._StrOfYes .. "(" .. life_time .. ")")
		        		elseif isTimeNo then
		        			GUI.SetText(self._PanelObject._LabNo, self._StrOfNo .. "(" .. life_time .. ")")
		        		end
		        	end
				end
			end)
		else
			if msgData._IsNoBtn then
				GUI.SetText(self._PanelObject._LabTips, StringTable.Get(20))
			end
	    end
	end

	def.override('string').OnClick = function(self, id)
		if id == 'Btn_Yes' then
			self:OnResult(true)
	    elseif id == 'Btn_No' or id == 'Btn_Close' then
			self:OnResult(false)
        elseif id == "ItemIconNew" then
            if self._MsgBoxData._CostItemID > 0 then
                CItemTipMan.ShowItemTips(self._MsgBoxData._CostItemID, TipsPopFrom.OTHER_PANEL)
            end
		end
	end

    def.override("string", "boolean").OnToggle = function(self,id, checked)
        if id == 'CheckBox_ShowAgain' then
            self._MsgBoxData._NotShowAgain = checked
        end
    end

--    def.override("userdata").OnPointerClick = function(self, target)
--        if self._PanelCloseType == EnumDef.PanelCloseType.ClickEmpty then
--            self:OnResult(false)
--        end
--    end

	def.method('boolean').OnResult = function(self, result)
	    if self._MsgBoxData ~= nil then
            if self._MsgBoxData._NotShowAgain and result then
                CMsgBoxMan.Instance():AddNotShowAgainBox(self._MsgBoxData, 1)
            end
	        local func_result = self._MsgBoxData._ClickCall
	        self:CallResult(func_result, result)
            self:ShowNextOrClose()
	    end
	end

	def.method("boolean").OnTimerOut = function(self, isCallYes)
	    if self._MsgBoxData ~= nil then
	        local func_result = self._MsgBoxData._ClickCall
	        if func_result == nil then
	        	func_result = self._MsgBoxData._TimerCall
	        	isCallYes = false
	        end
	        self:CallResult(func_result, isCallYes)
            self:ShowNextOrClose()
	    end
	end

    -- 没有msg在排队的话就隐藏界面，否则显示下一个
    def.method().ShowNextOrClose = function(self)
        --print("11111111111111")
		--warn("ToggleNext")
        CMsgBoxMan.Instance():RemoveBoxById(self._CurBoxId)
        CMsgBoxMan.Instance()._IsShowingNormalMsg = false

--        if  CMsgBoxMan.Instance():GetMsgListCount() <= 0 then
--			warn("Close")
--    	    game._GUIMan:CloseByScript(self)
--        else
--			warn("ToggleNext")
	        CMsgBoxMan.Instance():ToggleNext()
--        end

    end

	def.method("function", "boolean").CallResult = function(self, callBack, result)
		if callBack == nil then return end
		self._IsInCallback = true
		callBack(result)
		self._IsInCallback = false
	end

	def.override().OnHide = function(self)
        self._CurType = 0
        CPanelBase.OnHide(self)
	    if self._TimerId > 0 then
	        _G.RemoveGlobalTimer(self._TimerId)
	        self._TimerId = 0 
	    end
        CGame.EventManager:removeHandler(ApplicationQuitEvent, OnApplicationQuit)
	end

	def.override().OnDestroy = function (self)
		self._PanelObject = nil
        self._MsgBoxData = nil
		if self._TimerId > 0 then
	        _G.RemoveGlobalTimer(self._TimerId)
	        self._TimerId = 0
	    end
	    self._CurType = 0
	end

	def.method("number", "=>", "boolean").HandleEscapeKeyManually = function(self, layer_id)
		--warn("Msg Esc "..self._Name)
		if self:IsOpen() then
            if self._Layer == layer_id or layer_id == 0 then
			    if self._MsgBoxData ~= nil then
				    self:OnResult(false)
			    else
				    self:ShowNextOrClose()
			    end
			    return true
            end
		end

		return false
	end

	-- 返回键
	def.override("=>", "boolean").HandleEscapeKey = function(self)
		return self:HandleEscapeKeyManually(0)
	end

end
CMsgBoxPanel.Commit()
return CMsgBoxPanel