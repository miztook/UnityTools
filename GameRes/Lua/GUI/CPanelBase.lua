local Lplus = require "Lplus"
local UISetting = require "Data.UISettingConfig"
local CPanelBase = Lplus.Class("CPanelBase")
local def = CPanelBase.define

def.field("boolean")._LoadAssetFromBundle = true
def.field("string")._PrefabPath = ""
def.field("string")._CfgPath = ""
def.field("string")._Name = ""
def.field("userdata")._Panel = nil                  -- The UI GameObject
def.field("userdata")._EventListener = nil      -- This is UIEventListener

def.field("boolean")._IsLoading = false
def.field("boolean")._Is2Destory = false
def.field("boolean")._IsHidden = false  -- Hidden by a layer, this is used by the layer-control-system.
def.field("boolean")._IsSelfHidden = false  -- A self controled hidden sate.

def.field("table")._UIObjectName2IdMap = nil    -- A decryption book to find UIObjects.
def.field("boolean")._IsFullScreen = false  -- It marks whether this is a fullscreen covered UI.
def.field("boolean")._UseIMLight = false  -- It marks whether to use ImageModel weather.
def.field("boolean")._ForbidESC = false  -- It marks whether to handle esc key.

def.field("number")._CloseMask = 0		-- 层间互斥关系 8 bit mask, check EnumDef.Panel_Order_OP
-- def.field("number")._OrderCloseOP = 0		-- 同层关系 check EnumDef.Panel_Layer_OP
def.field("number")._HideMask = 0   -- Hide other layers, per bit, 1 hide, 0 not
def.field("boolean")._DestroyOnHide = true    -- 界面关闭时，是否销毁UI对象
def.field("number")._PanelCloseType = 2

def.field("number")._Layer = 2      -- this is not an ID but an enum, check UISetting.GetTable().Sorting_Layer
def.field("number")._PanelOrderType = 1     -- check UISetting.GetTable().Order_Type
def.field("number")._FixedOrder = 1
def.field("number")._RealLayer = 0
def.field("number")._RealOrderInLayer = 0

-- Dont know what these really do
def.field("number")._OriginX = 0
def.field("boolean")._IsOut = false
def.field("boolean")._IsHideWhenClickAnyWhere = true
-- def.field("number")._SpecialId = -1
def.field("boolean")._TriggerGC = false
-- def.field("boolean")._Is2DIYClickEmptyHandler = false
def.field("number")._ClickInterval = 0

-- 页面帮助系统统一配置
def.field("number")._HelpUrlType = -1
def.field("string")._HelpUrlBtnName = "Btn_Info"

-- 生命周期函数 life time processes and all virtuals

def.virtual().OnCreate = function(self)
end

def.virtual("dynamic").OnData = function(self, data)
end

def.virtual().OnHide = function(self)
end

def.virtual("boolean").OnVisibleChange = function(self, is_show)
end

def.virtual().OnDestroy = function(self)
end

def.virtual("string").OnClick = function(self, id)
	if id == self._HelpUrlBtnName and HelpPageUrl[self._HelpUrlType] then
		CPlatformSDKMan.Instance():ShowInAppWeb(HelpPageUrl[self._HelpUrlType])
	end
end

def.virtual("userdata").OnClickGameObject = function(self, go)
end

def.virtual("string").OnPointerDown = function(self, id)
end

def.virtual("string").OnPointerUp = function(self, id)
end

def.virtual("string").OnPointerEnter = function(self, id)
end

def.virtual("string").OnPointerExit = function(self, id)
end

def.virtual("string").OnPointerLongPress = function(self, id)
end

def.virtual("string", "boolean").OnToggle = function(self, id, checked)
end

def.virtual("string", "number").OnScroll = function(self, id, value)
end

def.virtual("string", "string").OnEndEdit = function(self, id, str)
end

def.virtual("string", "string").OnValueChanged = function(self, id, str)
end

def.virtual("string", "number").OnScaleChanged = function(self, id, value)
end

-- def.virtual("string", "string").OnSceneEvent = function(self, id, event)
-- end

def.virtual("userdata", "string", "number").OnLongPressItem = function(self, item, id, index)
end

def.virtual("userdata", "string", "number").OnInitItem = function(self, item, id, index)
end

def.virtual("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
end

def.virtual("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, list_name, button_name, index)
end

def.virtual("string", "number").OnDropDown = function(self, id, index)
end

def.virtual("userdata").OnInitMenuNode = function(self, node)
end

def.virtual("userdata").OnClickMenuNode = function(self, node)
end

def.virtual("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
end

def.virtual("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
end

def.virtual("userdata", "userdata", "number", "number").OnTabListItemButton = function(self, list, item, main_index, sub_index)
end

def.virtual("string").OnButtonSlide = function(self, id)
end

def.virtual("string").OnReceiveWebViewMessage = function(self, msg)
end

def.virtual().CloseThisTip = function(self)
	if self._PanelCloseType == EnumDef.PanelCloseType.Tip then
		self:Close()
	end
end

-- we will handle the PointerClickEvent when objects without PointerClick Process
def.virtual("userdata").OnPointerClick = function(self, target)
end

-- DotTweenAnimation结束事件
def.virtual("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	if dot_id == "UI_OPEN" then
		--warn("game._CGuideMan:AnimationEndCallBack(self)")
		game._CGuideMan:AnimationEndCallBack(self)
	end
end

def.virtual("=>", "boolean").IsInvisible = function(self)
	if not IsNil(self._Panel) then
		return self._Panel.layer == EnumDef.RenderLayer.Invisible
	end
	return true
end
-- 返回键
def.virtual("=>", "boolean").HandleEscapeKey = function(self)
	-- print("Esc "..self._Name)
	if not self._ForbidESC then
		if self:IsOpen() then
			-- print("Esc panel "..self._Name)
			self:Close()
			return true
		end
	end

	return false
end
-- 按stack式取UI时是否计入
def.virtual("=>", "boolean").IsCountAsUI = function(self)
	return true
end

-- 当层级被迫移动时
def.method().OnUIOrderChanged = function(self)
	-- 教学如果需要处理 在这里发消息
end

-- 系统调用 These funcs should not be called from your scripts.
def.method().SetupUISorting = function(self)
	if IsNil(self._Panel) then return end

	GameUtil.SetupUISorting(self._Panel, self._Layer, self:GetSortingOrderBase())
end

def.method("number").MoveUISortingOrder = function(self, order_mov)
	if IsNil(self._Panel) then return end
	local old_v = self:GetSortingOrderBase()

	if order_mov ~= old_v then
		self._RealOrderInLayer = order_mov
		local new_v = self:GetSortingOrderBase()
		GameUtil.MovePanelSortingOrder(self._Panel, new_v - old_v)

		self:OnUIOrderChanged()
	end
end

def.method("dynamic", "boolean").DoShow = function(self, panel_data, first_time)
	if first_time then
		-- event listener
		local msg_handler = self._Panel:GetComponent(ClassType.UIEventListener)
		if not msg_handler then
			msg_handler = self._Panel:AddComponent(ClassType.UIEventListener)
		end

		msg_handler:SetLuaHandlerLink(self)
		msg_handler:RegisterHandler()

		self._EventListener = msg_handler

		---- lua初始化函数，状态参数更新
		self:OnCreate()
	end

	if self._PanelCloseType == EnumDef.PanelCloseType.Tip then
		GameUtil.RegisterTip(self._Panel)
	end

	self:OnVisibleChange(not self:IsHidden())

	self:EnableUIEvent(true)

	self:OnData(panel_data)

	-- if not self:IsShow() then return end
end

def.method().DoHide = function(self)
	if self._PanelCloseType == EnumDef.PanelCloseType.Tip then
		GameUtil.RegisterTip(self._Panel)
	end

	self:OnVisibleChange(false)

	self:OnHide()

	self:EnableUIEvent(false)
end

def.method().DoDestroy = function(self)
	self:OnDestroy()
	self._EventListener = nil
end

def.method("boolean").EnableUIEvent = function(self, b_flag)
	if self._EventListener ~= nil then
		self._EventListener:EnableUIEvent(b_flag)
	end
end

-- clicks without any component to handle them
def.method("userdata").HandlePointerClick = function(self, target)
	if not target then return end
	if self._PanelCloseType == EnumDef.PanelCloseType.ClickAnyWhere then
		-- self:AutoClose()
		game._GUIMan:CloseByScript(self)
	elseif self._PanelCloseType == EnumDef.PanelCloseType.ClickEmpty then
		if self._Panel and self._Panel.name == target.name then
			-- self:AutoClose()
			game._GUIMan:CloseByScript(self)
		end
	end

	self:OnPointerClick(target)
end

-- sync the hidden state to the real gameObject
def.method().UpdateHiddenState = function(self)
	self:OnVisibleChange(not self:IsHidden())
	GameUtil.HidePanel(self._Panel, self:IsHidden())
end

def.method("boolean").ShowSelfPanel = function(self, is_show)
	if not self:IsShow() then return end
	self._IsSelfHidden = not is_show
	self:UpdateHiddenState()
	game._CGuideMan:IsShowGuide(is_show,self._Panel.name)
end

-- 外部接口 public interfaces
def.method("=>", "boolean").IsShow = function(self)
	if IsNil(self._Panel) then return false end
	return self._Panel.activeSelf
end

def.method("=>", "boolean").IsHidden = function(self)
	return self._IsHidden or self._IsSelfHidden
end

def.method("=>", "boolean").IsHiddenSelf = function(self)
	return self._IsSelfHidden
end

def.method("=>", "boolean").IsOpen = function(self)
	return self:IsShow() or(self._IsLoading and not self._Is2Destory)
end

def.method("number", "number").SetOrderInLayer = function(self, layer, order)
	self._RealLayer = layer
	self._RealOrderInLayer = order
end

-- def.method("number").SetSortingOrder = function(self, order)
--    if IsNil(self._Panel) then return end
--    GameUtil.SetPanelSortingLayerOrder(self._Panel, order)
-- end

def.method("=>", "number").GetSortingOrder = function(self)
	if IsNil(self._Panel) then return 0 end
	return GameUtil.GetPanelSortingOrder(self._Panel)
end

def.method("=>", "number").GetSortingOrderBase = function(self)
	return self._RealOrderInLayer * UISetting.GetTable().Order_Def.Step_Count
end

-- def.method("number").SetSortingLayer = function(self, layerID)
--    if IsNil(self._Panel) then return end
--    --GameUtil.SetPanelSortingLayer(self._Panel, layerID)
--    GameUtil.SetPanelSortingLayerOrder(self._Panel, layerID, order)
-- end

def.method("=>", "number").GetSortingLayer = function(self)
	if IsNil(self._Panel) then return end
	return GameUtil.GetPanelSortingLayer(self._Panel)
end

def.method("number", "number").SetSortingLayerOrder = function(self, layer, order)
	if IsNil(self._Panel) then return end
	GameUtil.SetPanelSortingLayerOrder(self._Panel, layer, order)
end

def.method().Close = function(self)
	game._GUIMan:CloseByScript(self)
end

def.method("=>", "string").GetPrefabName = function(self)
	return self._PrefabPath
end

def.method("string", "=>", "userdata").GetUIObject = function(self, name)
	if self._UIObjectName2IdMap == nil then
		local cfg_file = string.sub(self._PrefabPath, 1, -8)
		self._UIObjectName2IdMap = require("GUI.ObjectCfg." .. cfg_file)
	end

	local go = nil
	if self._UIObjectName2IdMap ~= nil and self._UIObjectName2IdMap[name] ~= nil then
		local id = self._UIObjectName2IdMap[name]
		go = GameUtil.GetPanelUIObjectByID(self._Panel, id)
	else
		warn("<Panel " .. self._PrefabPath .. "> has no object with the name of  [" .. name .. "], missing UIObject data or UIObject data has error.")
		-- , debug.traceback())
	end

	return go
end

def.method("string", "=>", "boolean").HasUIObject = function(self, name)
	if self._UIObjectName2IdMap == nil then
		local cfg_file = string.sub(self._PrefabPath, 1, -8)
		self._UIObjectName2IdMap = require("GUI.ObjectCfg." .. cfg_file)
	end

	if self._UIObjectName2IdMap ~= nil and self._UIObjectName2IdMap[name] ~= nil then
		return true
	end
	return false
end

def.method("string", "string").SetObjText = function(self, name, strText)
	local obj = self:GetUIObject(name)
	if obj ~= nil then
		GUI.SetText(obj, strText)
	end
end

def.method().SetupSortingParam = function(self)
	local ui_table = require "Data.UISettingConfig"

	local ui_setting = nil
	if self._CfgPath == nil or self._CfgPath == "" then
		ui_setting = ui_table.GetUISetting(self._PrefabPath)
	else
		ui_setting = ui_table.GetUISetting(self._CfgPath)
	end

	local ui_setting_table = UISetting.GetTable()
	if ui_setting ~= nil then
		-- warn(" P "..self._PrefabPath.." : "..ui_setting.Layer..", "..ui_setting.OrderType)
		self._Layer = ui_setting.Layer
		self._PanelOrderType = ui_setting.OrderType
		if (ui_setting.OrderType == ui_setting_table.Order_Type.Fixed) then
			self._FixedOrder = ui_setting.FixedOrder
		end
		if (ui_setting.CloseMask ~= nil) then
			self._CloseMask = ui_setting.CloseMask
		end
		if (ui_setting.HideMask ~= nil) then
			self._HideMask = ui_setting.HideMask
		end
		if (ui_setting.FullScreen ~= nil) then
			self._IsFullScreen = ui_setting.FullScreen
		end
		if (ui_setting.IM ~= nil) then
			self._UseIMLight = ui_setting.IM
		end
		if (ui_setting.ForbidESC ~= nil) then
			self._ForbidESC = ui_setting.ForbidESC
		end


	else
		warn("UISettingConfig not found : " .. self._PrefabPath .. " UI层级配置没找到！ ")
	end
end

def.method("userdata").RegisterGuideHandler = function(self, game_object)
	if not IsNil(self._EventListener) then
		self._EventListener:RegisterGuideObject(game_object)
	end
end

def.method("userdata").UnregisterGuideHandler = function(self, game_object)
	if not IsNil(self._EventListener) then
		self._EventListener:UnregisterGuideObject(game_object)
	end
end

-- 时间序列<<
-- 返回值是单个事件的ID， 可以Kill
-- s_key, 你的序列组名称，用来操作某个组的所有事件
-- f_time，delay

def.method("string", "number", "userdata", "string", "=>", "number").AddEvt_PlayAnim = function(self, s_key, f_time, a_anim, s_path)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_PlayAnim(s_key, f_time, a_anim, s_path)
	end
	return -1
end

def.method("string", "number", "userdata", "string", "=>", "number").AddEvt_PlayDotween = function(self, s_key, f_time, dot_player, s_id)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_PlayDotween(s_key, f_time, dot_player, s_id)
	end
	return -1
end

def.method("string", "number", "userdata", "boolean", "=>", "number").AddEvt_SetActive = function(self, s_key, f_time, g_go, b_activeState)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_SetActive(s_key, f_time, g_go, b_activeState)
	end
	return -1
end

def.method("string", "number", "function", "=>", "number").AddEvt_LuaCB = function(self, s_key, f_time, lf_func)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_LuaCB(s_key, f_time, lf_func)
	end
	return -1
end

def.method("string", "number", "string", "userdata", "userdata", "number", "number", "=>", "number").AddEvt_PlayFx = function(self, s_key, f_time, s_path, g_hook, g_target, f_lifeTime, i_order)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_PlayFx(s_key, f_time, s_path, g_hook, g_target, nil, f_lifeTime, i_order)
	end
	return -1
end

def.method("string", "number", "string", "=>", "number").AddEvt_PlaySound = function(self, s_key, f_time, s_path)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_PlaySound(s_key, f_time, s_path)
	end
	return -1
end

def.method("string", "number", "number", "number", "=>", "number").AddEvt_Shake = function(self, s_key, f_time, f_mag, f_lifeTime)
	if not IsNil(self._EventListener) then
		return self._EventListener:AddEvt_Shake(s_key, f_time, f_mag, f_lifeTime)
	end
	return -1
end

def.method("number").KillEvt = function(self, i_key)
	if not IsNil(self._EventListener) then
		self._EventListener:KillEvt(i_key)
	end
end

def.method("string").KillEvts = function(self, s_key)
	if not IsNil(self._EventListener) then
		self._EventListener:KillEvts(s_key)
	end
end
-- >>时间序列

CPanelBase.Commit()
return CPanelBase