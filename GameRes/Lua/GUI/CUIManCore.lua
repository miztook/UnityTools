-- 界面用途分类;
-- 常驻界面/非常驻界面;
-- 不同情境分类:大世界/副本;

-- Note: 这里打开的所有Panel必须是单例;
-- I wont do nil check on params in local functions, bw awared

-- 界面管理: 层级;
-- 1. UI按Layer分类，每类按Order排序;
-- 2. Layer中分固定 1-40 和浮动 41-80 两块,（保留81-100）;
-- 3. 打开UI 层间互斥 [每层全部 不变/关闭];
-- 4. 打开/关闭UI 隐藏Layer[每层全部 不变/隐藏];
-- 5. 实际order间隔是10 +0~+5是给特效的，+6以上的是给教学的;

-- 6.想要改变一个已开界面的层级，必须先关闭, 不能隐藏自己层

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local bit = require "bit"
local CUIManLayer = require "GUI.CUIManLayer"
local UISetting = require "Data.UISettingConfig"
local CUIManCore = Lplus.Class("CUIManCore")
local def = CUIManCore.define

-- hide layer mask
local panel_hide_mask = 0 
-- opened panels with hide mask
local panels_with_HM = { }


-- <<   #fields
def.field("table")._UISetting = nil      -- no clear
def.field("userdata")._UIRoot = nil     -- no clear
def.field("userdata")._FullScreenUIBG = nil      -- no clear 
def.field("table")._LayerBitMask = nil      -- no clear
def.field("table")._LayerMap = nil
def.field("number")._HideMask = 255     -- correspond to s layers

def.field("table")._NotDestroyed = nil

def.field("boolean")._IsLogUI = false

-- def.field("boolean")._ForceHideMainCamera = false
def.field("table")._BlockMainCamera = BlankTable


-- UI Light and referrence count
def.field("number")._UILightRefCount = 0
def.field("userdata")._UILight = nil
-- env colors
-- local envColor = { }
local FullScreenUIEnv = 192
def.field("number")._LastEnvMode = -1
def.field("boolean")._UseIMLighting = false

-- >>   #fields

-- <<   #funcs
def.static("=>", CUIManCore).new = function()
	local obj = CUIManCore()
	obj._UISetting = UISetting.GetTable()
	return obj
	-- return nil
end

-- def.method().Init = function(self)
--    --CPate.Setup()
--    --self:GetAllOriginalPos()
--    --self._UIRoot = GameObject.Find("UIRootCanvas/")
-- end

def.method().Init = function(self)
	-- CPate.Setup()
	-- self:GetAllOriginalPos()
	self._UIRoot = GameObject.Find("UIRootCanvas/PanelRoot")

	-- All full screen BG
	self._FullScreenUIBG = self._UIRoot:FindChild("FullScreenUIBG")
	-- self._FullScreenUIBG:SetActive(false)

	self:Clear()
end

local function FindPanelWithHideMask(panel_script)
	for i, v in pairs(panels_with_HM) do
		if (v == panel_script) then
			return i
		end
	end
	return 0
end

-- 隐藏层级UI、开关主相机，开关IM光照
-- local _layer_hide={}
local function ApplyLayerSettings(self)
	-- Apply Hide Mask
	local mask = bit.bor(panel_hide_mask, self._HideMask)

	-- warn("ApplyLayerSettings "..mask)
	local is_fullscreen_open = false
	local use_IM_lighting = false
	local ui_fs_top = nil
	local ui_fs_top_loading = nil

	for i = self._UISetting.Sorting_Layer.Debug, self._UISetting.Sorting_Layer.GameWorld, -1 do
		local result = bit.band(mask, self._LayerBitMask[i])
		if (result == 0) then
			local layer = self._LayerMap[i]
			for i = self._UISetting.Order_Def.Order_Max, 1, -1 do
				local ui_tmp = layer._PanelMap[i]
				if ui_tmp ~= nil then
					-- 					warn("ApplyLayerSettings to "..ui_tmp._Name)
					if ui_tmp._IsLoading then
						if (ui_fs_top == nil and ui_fs_top_loading == nil) then
							if ui_tmp._IsFullScreen and not ui_tmp:IsHiddenSelf() then
								ui_fs_top_loading = ui_tmp
							end
						end
					else
						if (ui_fs_top == nil) then
							layer:HidePanel(ui_tmp, false)
							if (ui_tmp._IsFullScreen and not ui_tmp:IsHiddenSelf()) then
								-- 								warn("ApplyLayerSettings Found new top FS ui : "..ui_tmp._Name)
								ui_fs_top = ui_tmp
								is_fullscreen_open = true
							end
						else
							layer:HidePanel(ui_tmp, true)
						end


						if ui_tmp._UseIMLight and not ui_tmp:IsHidden() then
							use_IM_lighting = true
						end
					end
				end
			end
		else
			self._LayerMap[i]:HideLayer(true)
		end
	end

	-- just because there s no .count in lua
	local auto_hideCam = is_fullscreen_open
	if not auto_hideCam then
		for _, v in pairs(self._BlockMainCamera) do
			if v ~= nil then
				auto_hideCam = true
				break
			end
		end
	end
	game:EnableMainCamera(not auto_hideCam)

	--CSoundMan.Instance():SetMixMode(SOUND_ENUM.MIX_MODE.FSUI, is_fullscreen_open)

	self._UseIMLighting = use_IM_lighting
	self:OpenEnvLighting()

	self._FullScreenUIBG:SetActive(ui_fs_top == nil and ui_fs_top_loading ~= nil)
end

local function AddHideMask(panel_script)
	-- warn("AddHideMask "..panel_script._Name,debug.traceback())
	if (panel_script._HideMask ~= 0) then
		local index = FindPanelWithHideMask(panel_script)
		if (index < 1) then
			panel_hide_mask = bit.bor(panel_hide_mask, panel_script._HideMask)
			panels_with_HM[#panels_with_HM + 1] = panel_script
		end
	end
end

local function SubHideMask(panel_script)
	-- warn("SubHideMask "..panel_script._Name,debug.traceback())
	if (panel_script._HideMask ~= 0) then
		local index = FindPanelWithHideMask(panel_script)
		if (index > 0) then
			table.remove(panels_with_HM, index)
		end

		panel_hide_mask = 0
		for i, v in pairs(panels_with_HM) do
			if (v ~= nil) then
				panel_hide_mask = bit.bor(panel_hide_mask, v._HideMask)
			end
		end
	end
end

-- >>Hide Layers

local function GetLayer(self, panel_script)
	local layer = self._LayerMap[panel_script._Layer]
	if (layer == nil) then
		warn("Panel layer not found! This Problem need to be sovled." .. panel_script._Name)
	end
	return layer
end

local function GetRealLayer(self, panel_script)
	local layer = self._LayerMap[panel_script._RealLayer]
	if (layer == nil) then
		warn("Panel layer not found! This Problem need to be sovled." .. panel_script._Name)
	end
	return layer
end

local function RemovePanel(self, panel_script)
	-- warn("RemovePanel " .. panel_script._Name.." "..)

	local layer = GetRealLayer(self, panel_script)
	if (layer ~= nil) then
		layer:Remove(panel_script)

		-- warn("UI remove " .. panel_script._Name .. " : " .. panel_script._RealLayer .. ", " .. panel_script._RealOrderInLayer)
	end
end

local function ClearPanelStates(panel_script, keep_hidden)
	-- Have to keep hidden state for opened Non-Destroy UI sometimes, or it wont show properly next time
	-- clear this if the ui is destroyed.
	if keep_hidden then
		panel_script._IsHidden = false
	end
	panel_script._IsSelfHidden = false
end

-- dont extend
local function _CloseByScript(self, panel_script)
	if (panel_script == nil) then return end

	-- warn("CloseByScript " .. panel_script._PrefabPath)

	if (not panel_script:IsOpen()) then return end

	RemovePanel(self, panel_script)
	SubHideMask(panel_script)

	local keep_hidden =(panel_script:IsShow() and panel_script._DestroyOnHide)

	if not IsNil(panel_script._Panel) then
		if panel_script._DestroyOnHide then
			panel_script._Panel:SetActive(false)

			-- panel_script:OnHide()
			panel_script:DoHide()
			-- panel_script:OnDestroy()
			panel_script:DoDestroy()

			Object.Destroy(panel_script._Panel)
			panel_script._Panel = nil
		else
			panel_script._Panel:SetActive(false)
			panel_script:DoHide()
		end

		--        local panel_name = nil
		--        if panel_script._SpecialId ~= -1 then
		--            panel_name = name_to_script_cache[panel_script._SpecialId]
		--        end
		--        -- 	if panel_name ~= nil and SpecialDialogMask[panel_name] ~= nil then
		--        -- 		local new_mask = bit.band(hide_special_mask, bit.bnot(SpecialDialogMask[panel_name]))
		--        -- 		if hide_special_mask ~= 0 and new_mask == 0 then
		--        -- 			SetPanelLayer(EnumDef.RenderLayer.UI)
		--        -- 		end
		--        -- 		hide_special_mask = new_mask
		--        -- 	end

	else
		if panel_script._IsLoading then
			panel_script._Is2Destory = true
		end
		if panel_script:IsShow() then
			if panel_script._DestroyOnHide then
				--                panel_script:OnHide()
				panel_script:DoHide()
				--                panel_script:OnDestroy()
				panel_script:DoDestroy()

			else
				-- panel_script:OnHide()
				panel_script:DoHide()
			end
		end
	end

	--    if not panel_script._DestroyOnHide then
	--        self._NotDestroyed[panel_script] = nil
	--    end

	ClearPanelStates(panel_script, keep_hidden)

	if panel_script._TriggerGC then
		game:GC(true)
	end

end

--
local function OnPanelOpen(self, panel_script)
	for i, v_layer in pairs(self._LayerMap) do
		-- if (i == panel_script._Layer) then
		--            -- handle this layer
		--            if (panel_script._OrderCloseOP == EnumDef.Panel_Order_OP.CloseLower) then
		--                for k, v_panel in pairs(v_layer._PanelMap) do
		--                    if (v_panel ~= panel_script and v_panel ~= nil) then
		--                        if (v_panel._RealOrderInLayer < panel_script._RealOrderInLayer) then
		--                            _CloseByScript(self, v_panel)
		--                        end
		--                    end
		--                end
		--            end
		--            if (panel_script._OrderCloseOP == EnumDef.Panel_Order_OP.CloseAll) then
		--                for k, v_panel in pairs(v_layer._PanelMap) do
		--                    if (v_panel ~= panel_script and v_panel ~= nil) then
		--                        _CloseByScript(self, v_panel)
		--                    end
		--                end
		--            end
		-- else
		local result = bit.band(panel_script._CloseMask, self._LayerBitMask[i])
		if (result ~= 0) then
			-- warn("Close by Layer " .. i .. ", " .. panel_script._CloseMask)

			local to_remove = { }
			for k, v_panel in pairs(v_layer._PanelMap) do
				if (v_panel ~= nil and v_panel ~= panel_script) then
					-- warn("Close " .. v_panel._Name)
					to_remove[v_panel] = 1
				end
			end

			for k_panel, _ in pairs(to_remove) do
				_CloseByScript(self, k_panel)
			end
		end
		-- end
	end

	AddHideMask(panel_script)
end

local function ShowPanel(self, panel_name, panel_script, panel_data, first_show)
	--    if(panel_script._PrefabPath == PATH.Panel_EnterMap_Tips)then
	--        warn("S#1 " .. panel_script._Name)
	--    end

	-- OnPanelOpen(self, panel_script)

	--    local layer = GetLayer(self, panel_script)
	--    if (layer ~= nil) then
	--        if not(layer:Exist(panel_script)) then
	--            local order = layer:RequireOrderInLayer(panel_script)
	--            if (order > 0) then
	--                if (layer._PanelMap[order] ~= nil) then
	--                    warn("_RealOrderInLayer "..panel_script._RealOrderInLayer)
	--                    warn(layer._PanelMap[order]._Name .. " layer order conflicts with " .. panel_script._Name)
	--                    _CloseByScript(self, layer._PanelMap[order])
	--                end
	--                layer:Add(panel_script, order)
	--            end
	--        end
	--    end

	--    local mask = GetFinalHideMask(self)
	--    local m_layer = self._LayerBitMask[i]
	--    if m_layer ~= nil then
	--        local result = (bit.band(mask, m_layer) ~= 0)
	--        if result ~= panel_script._IsHidden then
	--            warn(" result ~= panel_script._IsHidden "..panel_script._Name)
	--            panel_script._IsHidden = result
	--            panel_script:UpdateHiddenState()
	--        end
	--    end


	-- auto set sorting order
	panel_script:SetupUISorting()

	panel_script:DoShow(panel_data, first_show)

	game._CGuideMan:GuideOnDataCallBack(panel_script)

	ApplyLayerSettings(self)

end

local function PrefabLoaded(self, panel_name, panel_script, prefab, panel_data)
	if prefab == nil then
		warn("the panel prefab loaded is nil.", panel_name)
		return
	end
	-- 设置game object父级和位置
	panel_script._Panel = GameObject.Instantiate(prefab)
	if panel_script._Panel == nil then
		warn("GameObject.Instantiate has failed, cannot open ui " .. panel_name)
	else
		local parentgo = self._UIRoot
		panel_script._Panel:SetParent(parentgo, false)
		local rect = panel_script._Panel:GetComponent(ClassType.RectTransform)
		if rect == nil then
			warn("the panel prefab's RectTransform is nil:", panel_name)
		else
			panel_script._OriginX = rect.anchoredPosition.x
		end

		-- register to none-destroy list
		if not panel_script._DestroyOnHide then
			self._NotDestroyed[panel_script] = 1
		end

		--    -- 添加UIEventListener脚本，并调用其中的初始化函数
		--    local msg_handler = panel_script._Panel:GetComponent(ClassType.UIEventListener)
		--    if not msg_handler then
		--        msg_handler = panel_script._Panel:AddComponent(ClassType.UIEventListener)
		--    end

		--    panel_script.evtHandler=msg_handler

		--    msg_handler:SetLuaHandlerLink(panel_script)
		--    msg_handler:RegisterHandler()

		game._CFunctionMan:FunctionCheck(prefab.name, panel_script)

		--    -- setup sorting layer
		--    local sl_id = GameUtil.Num2SortingLayerID(panel_script._Layer)
		--    panel_script:SetSortingLayer(sl_id)

		--    local GraphicRaycaster = panel_script._Panel:GetComponent(ClassType.GraphicRaycaster)
		--    if GraphicRaycaster == nil then
		--        panel_script._Panel:AddComponent(ClassType.GraphicRaycaster)
		--    end

		ShowPanel(self, panel_name, panel_script, panel_data, true)
	end
end


-- def.method("number", "table").ReSetPanelLayer = function(self, layer, panel_script)
-- if panel_script == nil then return end
-- if self:Exist(panel_script) then
-- 	local old_layer = GetRealLayer(self, panel_script)
-- 	if old_layer ~= nil then
-- 		old_layer:Remove(panel_script)
-- 	end
-- 	local new_layer = self._LayerMap[layer]
-- 	local order = new_layer:RequireOrderInLayer(panel_script)

-- 	local p = new_layer._PanelMap[order]
-- 	if (p ~= nil) then
-- 		_CloseByScript(self, p)
-- 	end
-- 	new_layer:Add(panel_script, order)
-- 	panel_script:SetOrderInLayer(panel_script._Layer, order)
-- 	panel_script:SetupUISorting()
-- 	if not panel_script._Panel.activeSelf then
-- 		panel_script._Panel:SetActive(true)
-- 	end
-- 	OnPanelOpen(self, panel_script)
-- end
-- end

def.method("string", "dynamic", "table", "=>", "table").OpenByScript = function(self, panel_name, panel_data, panel_script)
	--    -- 地图限制，禁止打开
	--    if self:IsUIForbid(panel_script) then
	--        self:ShowTipText(StringTable.Get(15555), false)
	--        return nil
	--    end

	-- warn("OpenByScript " .. panel_name)

	if (panel_script == nil or panel_name == nil) then return nil end

	local new_layer = GetLayer(self, panel_script)
	local new_order = 0
	if (new_layer ~= nil) then
		new_order = new_layer:RequireOrderInLayer(panel_script)

		if new_order > 0 then
			local p = new_layer._PanelMap[new_order]
			if p ~= panel_script then
				if p ~= nil then
					warn("!!!!!!! UI SOrder Conflicted : " .. panel_name .. " with " .. p._Name)
					_CloseByScript(self, p)
				end
				panel_script._Name = panel_name

				_CloseByScript(self, panel_script)
--TODO
--				if panel_script:IsShow() then
--					panel_script:MoveUISortingOrder(panel_script._Layer,new_order - panel_script._RealOrderInLayer)
--				end

			elseif (p == panel_script) then
				if panel_script._IsLoading then
					-- Resources are still on the way
					return panel_script
				else
					-- 已在在显示状态，刷新
					panel_script:OnData(panel_data)
					game._CGuideMan:GuideOnDataCallBack(panel_script)

					return panel_script
				end
			end
			new_layer:Add(panel_script, new_order)

			--    if self:Exist(panel_script) then
			--        if panel_script._IsLoading then
			--            --Resources are still on the way
			--            return panel_script
			--        else
			--            -- 已经存在于列表
			--            if panel_script:IsShow() then
			--                -- 已在在显示状态，刷新
			--                panel_script:OnData(panel_data)
			--                game._CGuideMan:GuideOnDataCallBack(panel_script)
			--                return panel_script
			--            else

			--            end
			--        end
			--    else
			--        panel_script._Name = panel_name

			--        -- Add panel to Map
			--        local layer = GetLayer(self, panel_script)
			--        if (layer ~= nil) then
			--            local order = layer:RequireOrderInLayer(panel_script)
			--            if (order > 0) then
			--                local p = layer._PanelMap[order]
			--                if (p ~= nil) then
			--                    -- warn("_RealOrderInLayer "..panel_script._RealOrderInLayer)
			--                    -- warn(layer._PanelMap[order]._Name .. " layer order conflicts with " .. panel_script._Name)
			--                    _CloseByScript(self, p)
			--                end

			--                layer:Add(panel_script, order)

			--                if self._IsLogUI then
			--                    warn("UI Add "..panel_script._Name.." : "..panel_script._Layer..", "..panel_script._RealOrderInLayer)
			--                end
			--            end
			--        end
			--    end

			--    if not panel_script._DestroyOnHide then
			--        self._NotDestroyed[panel_script] = 1
			--    end

			--    if(panel_script._PrefabPath == PATH.Panel_EnterMap_Tips)then
			--        warn("Open " .. panel_name)
			--    end

			OnPanelOpen(self, panel_script)

			if not IsNil(panel_script._Panel) then
				-- game object 已经存在, for those non-destroy
				if not panel_script._Panel.activeSelf then
					panel_script._Panel:SetActive(true)
				end
				ShowPanel(self, panel_name, panel_script, panel_data, false)
			else
				-- game object 还没创建
				if panel_script._IsLoading then
					if panel_script._Is2Destory then
						panel_script._Is2Destory = false
					end
					-- warn("the panel's game object is loading " .. panel_name)
					return nil
				end
				panel_script._IsLoading = true
				if not panel_script._LoadAssetFromBundle then
					local prefab = Resources.Load(_G.InterfacesDir .. panel_script._PrefabPath)
					PrefabLoaded(self, panel_name, panel_script, prefab, panel_data)
				else

					ApplyLayerSettings(self)

					-- if panel_script._IsFullScreen then
					-- self._FullScreenUIBG:SetActive(true)
					-- end

					local function cb(prefab)
						-- reset
						if not panel_script._IsLoading then
							return
						end
						panel_script._IsLoading = false

						-- cancel loading but not reset
						if panel_script._Is2Destory then
							panel_script._Is2Destory = false
							return
						end
						PrefabLoaded(self, panel_name, panel_script, prefab, panel_data)
					end
					GameUtil.AsyncLoad(_G.InterfacesDir .. panel_script._PrefabPath, cb)

					-- ToDo: lock screen while loading?
				end
				-- if not panel_script._LoadAssetFromBundle then
			end
			-- if not IsNil(panel_script._Panel) then
		end
		-- if order > 0 then
	end

	return panel_script
end

def.method("table").CloseByScript = function(self, panel_script)
	_CloseByScript(self, panel_script)
	ApplyLayerSettings(self)

	if panel_script ~= nil then
		game._CGuideMan:OnCloseUI(panel_script._Name)
	end
end

def.method("number").CloseByLayer = function(self, layer_id)
	local v_layer = self._LayerMap[layer_id]
	if v_layer ~= nil then
		for _, v_panel in pairs(v_layer._PanelMap) do
			if v_panel ~= nil then
				self:CloseByScript(v_panel)
			end
		end
	end
end

def.method("table").CloseAll = function(self, except)
	-- print("CloseAll")

	for i, v_layer in pairs(self._LayerMap) do
		for _, v_panel in pairs(v_layer._PanelMap) do
			if not IsNil(v_panel) then
				local isHave = false

				if except ~= nil then
					for k2, v2 in pairs(except) do
						if v_panel._Name == v2 then
							isHave = true
							break
						end
					end
				end

				if not isHave then
					self:CloseByScript(v_panel)
				end
			end
		end
	end

	ApplyLayerSettings(self)
end

-- /]]

-- 返回登陆时，清空所有
-- Clear and destroy all panels when returning to Login
def.method().Clear = function(self)

	-- print("Clear All UIs")

	if self._LayerBitMask == nil then
		self._LayerBitMask = { }
		for i = self._UISetting.Sorting_Layer.GameWorld, self._UISetting.Sorting_Layer.Debug do
			self._LayerBitMask[i] = bit.lshift(1, i - 1)
		end
	end

	-- clear opened
	if (self._LayerMap ~= nil) then
		for i, v_layer in pairs(self._LayerMap) do
			for k, v_panel in pairs(v_layer._PanelMap) do
				if not IsNil(v_panel) then
					-- warn("Clear " .. i .. " " .. k .. " " .. v_panel._Name)

					if v_panel._IsLoading then
						v_panel._Is2Destory = true
					else
						-- v_panel:OnHide()
						v_panel:DoHide()

						-- v_panel:OnDestroy()
						v_panel:DoDestroy()

						if not IsNil(v_panel._Panel) then
							Object.Destroy(v_panel._Panel)
						end

						ClearPanelStates(v_panel, false)
						v_panel._Panel = nil
					end
				end
			end
			v_layer:Clear()
		end
	else
		self._LayerMap = { }
		for i = self._UISetting.Sorting_Layer.GameWorld, self._UISetting.Sorting_Layer.Debug do
			self._LayerMap[i] = CUIManLayer.new()
		end
	end

	-- clear !DestroyOnHide s
	if (self._NotDestroyed ~= nil) then
		for k_panel, _ in pairs(self._NotDestroyed) do
			if not IsNil(k_panel) then
				k_panel:DoDestroy()
				if not IsNil(k_panel._Panel) then
					Object.Destroy(k_panel._Panel)
				end
				k_panel._Panel = nil
				k_panel._IsLoading = false
				k_panel._Is2Destory = false
				ClearPanelStates(k_panel, false)
			end
		end
	end
	self._NotDestroyed = { }

	panel_hide_mask = 0
	panels_with_HM = { }
	self:ClearHideMask()

	self._UILightRefCount = 0
	self:RefUILight(0)

	self._LastEnvMode = -1

	self._BlockMainCamera = { }
end

def.method("table", "=>", "boolean").Exist = function(self, panel_script)
	if (panel_script == nil) then return false end

	local layer = GetRealLayer(self, panel_script)

	if (layer ~= nil) then
		return layer:Exist(panel_script)
	end

	return false
end

-- Hide layers, 0,~255, 1 hide, 0 show all
def.method("number").SetHideMask = function(self, mask)
	self._HideMask = mask
	ApplyLayerSettings(self)
end

def.method().ClearHideMask = function(self)
	self:SetHideMask(0)
	ApplyLayerSettings(self)
end

def.method("string", "=>", "table").FindUIByName = function(self, panel_name)
	if (panel_name == nil) then return nil end
	for _, v_layer in pairs(self._LayerMap) do
		local panel = v_layer:FindUIByName(panel_name)
		if (panel ~= nil) then
			return panel
		end
	end

	return nil
end

def.method("string", "=>", "table").FindUIByPrefab = function(self, prefab_name)
	if (prefab_name == nil) then return nil end
	for _, v_layer in pairs(self._LayerMap) do
		local panel = v_layer:FindUIByPrefab(prefab_name)
		if (panel ~= nil) then
			return panel
		end
	end

	return nil
end

-- def.method("boolean").HideMainCamera = function(self, flag)
--    if(flag) then
--        game:EnableMainCamera(false)
--    end
--    self._ForceHideMainCamera = flag
-- end

def.method("table", "boolean").BlockMainCamera = function(self, ui_inst, flag)
	if (flag) then
		self._BlockMainCamera[ui_inst._Name] = ui_inst
	else
		self._BlockMainCamera[ui_inst._Name] = nil
	end

end

local function HandleESCInLayer(self, layer_id)
	local layer = self._LayerMap[layer_id]
		if layer ~= nil and layer:GetCount() > 0 then
			local panel = layer:GetTop()
			if panel ~= nil then
				if panel:HandleEscapeKey() then
					-- warn("HandleEscapeKey True"..panel._Name)
					return true
				end
			end
		end
    return false
end

-- Android回退键-- return handled
def.method("=>", "boolean").HandleEscapeKey = function(self)
	local boxMan = require "GUI.CMsgBoxMan"
    
        --msgbox in layer debug
	if boxMan.Instance():HandleEscapeKeyManually(self._UISetting.Sorting_Layer.Debug) then
		--warn("HandleEscapeKey boxMan")
		return true
	end

	-- As no window
	if game._CPowerSavingMan:IsSleeping() then return false end

	if _G.IsCGPlaying then return false end

        --important tips
        if HandleESCInLayer(self, self._UISetting.Sorting_Layer.ImportantTip) then return true end

        --guide
	if boxMan.Instance():HandleEscapeKeyManually(self._UISetting.Sorting_Layer.Guide) then
                --warn("HandleEscapeKey boxMan")
		return true
	end

	if game._CGuideMan:InGuide() then
                --warn("JumpCurGuide InGuideIsLimit")
		if game._CGuideMan:InGuideIsLimit() then
			return false
		else
                        --warn("JumpCurGuide")
			game._CGuideMan:JumpCurGuide()
			return true
		end
	end

        --lower
	local chk_layers = {self._UISetting.Sorting_Layer.ImportantTip, self._UISetting.Sorting_Layer.NormalTip, self._UISetting.Sorting_Layer.Dialog, self._UISetting.Sorting_Layer.SubPanel}
	for _, v_layer in pairs(chk_layers) do
        if HandleESCInLayer(self, v_layer) then return true end
	end

	return false
end

-- UI Lighting

def.method().OpenEnvLighting = function(self)
	local uiSc = require "GUI.CUIScene"
	--    if not uiSc.IsOverrideAmb() then
	--        if flag then
	--            GameUtil.OpenSmithyUI(envColor[0],envColor[1],envColor[2])
	--        else
	--            GameUtil.CloseSmithyUI()
	--        end
	--    end

	local flag = self._UseIMLighting

	local ef_id = uiSc.GetEnvEffectID()

	-- warn("GetEnvEffectID "..ef_id)

	if ef_id < 1 then
		if flag then
			ef_id = FullScreenUIEnv
		end
	end

	-- warn("OpenEnvLighting "..ef_id)

	if self._LastEnvMode ~= ef_id then
		if ef_id > 0 then
			GameUtil.OpenUIWithEffect(ef_id)
			-- warn("OpenUIWithEffect "..ef_id)
		else
			GameUtil.LeaveUIEffect()
			-- warn("LeaveUIEffect")
		end
	end
	self._LastEnvMode = ef_id
end

def.method("number").RefUILight = function(self, count)
	--    self._UILightRefCount = self._UILightRefCount + count
	--    --print("CUIModel ref count " .. self._UILightRefCount)

	--    if self._UILightRefCount < 0 then
	--        self._UILightRefCount = 0
	--        warn("UILight over kill")
	--    end

	if IsNil(self._UILight) then
		local light = GameObject.Find("UILight")
		if not IsNil(light) then
			-- print("Light "..light.name)
			-- light.rotation = Quaternion.Euler(22.5, 340, 0)
			self._UILight = light:GetComponent(ClassType.Light)
			if not IsNil(self._UILight) then
				-- self._UILight.enabled = true

				-- something more...

			end
		else
			error("UILight not found!!!")
		end
	end

	--    if not IsNil(self._UILight) then
	--        self._UILight.enabled = (self._UILightRefCount > 0)
	--        --print("UILight "..tostring(_UILight.enabled))
	--    end

end

-- Debug Log
-------------------------------------------

def.method().Debug_LogLayer = function(self)
	for i, v_layer in pairs(self._LayerMap) do
		local str_out = "<<print layer " .. i .. " floatTop " .. v_layer._FloatingTop .. " >>"
		for k, v_panel in pairs(v_layer._PanelMap) do
			if not IsNil(v_panel) then
				-- warn("Clear " .. i .. " " .. k .. " " .. v_panel._Name)
				str_out = str_out .. k .. ": " .. v_panel._Name .. "/ "
			end
		end

		warn(str_out)
	end
end

def.method().Debug_CollapseLayer = function(self)
	for i, v_layer in pairs(self._LayerMap) do
		v_layer:CollapseStack()
	end
end

def.method().Debug_LogHideMask = function(self)
	local str_out = "<<print hide mask " .. panel_hide_mask .. ">> "
	for k, v_panel in pairs(panels_with_HM) do
		if not IsNil(v_panel) then
			-- warn("Clear " .. i .. " " .. k .. " " .. v_panel._Name)
			str_out = str_out .. v_panel._Name .. ": " .. v_panel._HideMask .. "/ "
		end
	end
	warn(str_out)
end

def.method().Debug_LogFullScreenUI = function(self)
	local str_out = "<<print full screen>> "
	for _, v in pairs(self._LayerMap[self._UISetting.Sorting_Layer.SubPanel]._PanelMap) do
		str_out = str_out .. v._Name .. " " .. tostring(v._IsFullScreen) .. " "
	end
	warn(str_out)
end

def.method().Debug_LogAddRemove = function(self)
	self._IsLogUI = not self._IsLogUI
	if self._IsLogUI then
		warn("<<log UI +->> on")
	else
		warn("<<log UI +->> off")
	end

end

def.method().Debug_TipQ = function(self)
	local q = game._CGameTipsQ
	local str_out = "Tips Q: " .. q._StateStack .. "\n"

	str_out = str_out .. "is loading: " .. tostring(IsLoadingUI()) .. " in guide " .. tostring(game._CGameTipsQ:IsInGuide()) .. "\n"
	str_out = str_out .. " is in CG " .. tostring(game._CGameTipsQ:IsInCG()) .. "\n"

	if q._Blocker ~= nil then
		str_out = str_out .. " blocker: " .. q:LogEvt(q._Blocker) .. " " .. q._Blocker.blockTime .. "\n"
	end
	if q._BlockerA ~= nil then
		str_out = str_out .. " blockerA: " .. q:LogEvt(q._BlockerA) .. " " .. q._BlockerA.blockTime .. "\n"
	end
	str_out = str_out .. "mbox len: " .. #(q._MsgBox) .. "\n"
	-- str_out = str_out .. " q_queue len: " .. #(q._QueueQ)
	str_out = str_out .. " e_queue len: " .. #(q._QueueE)
	str_out = str_out .. " a_queue len: " .. #(q._QueueA)

	warn(str_out)
end

def.method().Debug_WBTip = function(self)
	game._GUIMan:OpenSpecialTopTips(string.format(StringTable.Get(21010), "asdad", "12345"))
end

def.method().Debug_SleepingState = function(self)
	warn("PS enable " .. tostring(game._CPowerSavingMan:IsEnabled()) .. ", isPlaying " .. tostring(game._CPowerSavingMan._IsPlaying) .. ", isInCD " .. tostring(game._CPowerSavingMan._IsInCD) .. " , isSleeping " .. tostring(game._CPowerSavingMan._IsSleeping))
end
-----------------------------------

-- >>   #funcs

CUIManCore.Commit()
return CUIManCore