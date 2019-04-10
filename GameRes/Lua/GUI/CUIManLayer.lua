-- Management of UI list with one sorting layer
-- add/remove/find/hide
-- its just a container

local Lplus = require "Lplus"
local UISetting = require "Data.UISettingConfig"
local CGame = Lplus.ForwardDeclare("CGame")

local CUIManLayer = Lplus.Class("CUIManLayer")
local def = CUIManLayer.define

-- <<   #fields
-- def.field("table")._KeyMap = nil
def.field("table")._PanelMap = nil
def.field("number")._FloatingTop = 0
-- def.field("boolean")._isHide = false
def.field("table")._UISetting = nil      -- no clear
-- is any fullscreen ui displaying
-- def.field("boolean")._IsShowFullScreen = false

-- >>   #fields

-- <<   #funcs
def.static("=>", CUIManLayer).new = function()
	local obj = CUIManLayer()
	obj._UISetting = UISetting.GetTable()
	obj:Clear()
	return obj
end

def.method("table", "=>", "number").RequireOrderInLayer = function(self, panel_script)
	local order = 0
	if panel_script._PanelOrderType == self._UISetting.Order_Type.Fixed then
		-- fixed : you have designed where it should be
		order = panel_script._FixedOrder
	elseif panel_script._PanelOrderType == self._UISetting.Order_Type.Floating then
		-- floating : one upon another
		order = self._FloatingTop + self._UISetting.Order_Def.Fixed_Count
		if self._PanelMap[order] ~= panel_script then
			if (self._FloatingTop + 1 > self._UISetting.Order_Def.Floating_Count) then
				-- prevent the stack from overloading
				self:CollapseStack()
				warn("UI: Collapse down stack when FloatingCount is " .. self._UISetting.Order_Def.Floating_Count)
			end
			order = order + 1
		end
	end
	-- warn(" ? " .. self._UISetting.Order_Type.Floating.." "..order)
	return order
end

def.method("table", "number").Add = function(self, panel_script, order)
	if (panel_script == nil) then return end

	if (order > 0) then
		-- Set real order in the layer
		panel_script:SetOrderInLayer(panel_script._Layer, order)

		if panel_script._PanelOrderType == self._UISetting.Order_Type.Floating then
			-- self._FloatingTop = self._FloatingTop + 1
			self._FloatingTop = order - self._UISetting.Order_Def.Fixed_Count

			-- print("UI: New order " .. panel_script._Layer .. " " .. order)

			if (self._FloatingTop > self._UISetting.Order_Def.Floating_Count) then
				--                --prevent the stack from overloading
				--                self:CollapseStack()
				warn("UI: Floating stack overloaded " .. self._UISetting.Order_Def.Floating_Count .. "!!!!!!!!!!!!!!!!!!!!!!")
			end
		end

		self._PanelMap[order] = panel_script
		-- self:AddOrder(order)
		-- warn("Layer Add " .. panel_script._Name .. " " .. panel_script._Layer .. " " .. panel_script._RealOrderInLayer)
	end
end

def.method("table").Remove = function(self, panel_script)
	if (panel_script == nil) then return end
	if (self:Exist(panel_script) == false) then return end

	local pos = panel_script._RealOrderInLayer
	if panel_script._PanelOrderType == self._UISetting.Order_Type.Fixed then
		-- fixed
		-- self:RemoveOrder(pos)
		self._PanelMap[pos] = nil
	elseif panel_script._PanelOrderType == self._UISetting.Order_Type.Floating then
		-- floating
		-- keep ANSC order
		if (pos > 0) then
			--            local cnt = self._FloatingTop + self._UISetting.Order_Def.Fixed_Count
			--            if (pos < cnt) then
			--                warn("CUILayer Remove pos < cnt !!!!!!!!!!!!!!!!!!!!!!")
			--            end

			--                        -- backup
			--                        while (pos < cnt) do
			--                            self._PanelMap[pos] = self._PanelMap[pos + 1]
			--                            self._PanelMap[pos]:SetOrderInLayer(pos)
			--                            --self._PanelMap[pos]:SetupUISorting()
			--                            pos = pos + 1
			--                        end
			--                      self._FloatingTop = self._FloatingTop - 1

			-- self:RemoveOrder(pos)
			self._PanelMap[pos] = nil

			local i = self._FloatingTop
			while (i > 0) do
				if (self._PanelMap[i + self._UISetting.Order_Def.Fixed_Count] ~= nil) then
					break
				end
				i = i - 1
			end
			self._FloatingTop = i
		end
	end
end

def.method("table", "=>", "boolean").Exist = function(self, panel_script)
	if (panel_script == nil) then return false end

	-- warn("_RealOrderInLayer "..panel_script._RealOrderInLayer.." exist ")

	return(self._PanelMap[panel_script._RealOrderInLayer] == panel_script)
end

def.method("table", "=>", "number").GetUIIndex = function(self, panel_script)
	if (self:Exist(panel_script)) then
		return panel_script._RealOrderInLayer
	end

	return 0
end

def.method("string", "=>", "table").FindUIByName = function(self, panel_name)
	if (panel_name == nil) then return nil end
	for _, v in pairs(self._PanelMap) do
		if (v._Name == panel_name) then
			return v
		end
	end

	return nil
end

def.method("string", "=>", "table").FindUIByPrefab = function(self, prefab_name)
	if (prefab_name == nil) then return nil end
	for _, v in pairs(self._PanelMap) do
		if (v._PrefabPath == prefab_name) then
			return v
		end
	end

	return nil
end

def.method().Clear = function(self)
	self._PanelMap = { }
	-- self._KeyMap = { }
	self._FloatingTop = 0
	-- self._isHide = false
end


def.method("table", "boolean").HidePanel = function(self, panel_script, is_hide)
--local function HidePanel(panel_script, is_hide)
	--    if(panel_script ~= nil and panel_script._PrefabPath == PATH.UI_ChatNew)then
	--        warn("Hide "..panel_script._Name ..tostring(panel_script._IsHidden).. "/" .. tostring(is_hide), debug.traceback())
	--        warn("IsShow "..tostring(panel_script:IsShow()))
	--    end

	if panel_script ~= nil and panel_script:IsShow() then
		--        if (is_hide) then
		--            GameUtil.SetLayerRecursively(panel_script._Panel, EnumDef.RenderLayer.Invisible)
		--        else
		--            GameUtil.SetLayerRecursively(panel_script._Panel, EnumDef.RenderLayer.UI)
		--        end

		if panel_script._IsHidden ~= is_hide then
			-- GameUtil.HidePanel(panel_script._Panel, is_hide)
			panel_script._IsHidden = is_hide
			panel_script:UpdateHiddenState()
		end
	end
end

def.method("boolean").HideLayer = function(self, is_hide)
	-- if self._isHide ~= is_hide then
	--    self._IsShowFullScreen = false

	for _, v_panel in pairs(self._PanelMap) do
		if v_panel ~= nil then
			self:HidePanel(v_panel, is_hide)

			--            if v_panel._IsFullScreen and not is_hide and not v_panel._IsLoading then
			--                self._IsShowFullScreen = true
			--            end
		end
	end
	-- self._isHide = is_hide
	-- end
end
-- >>   #funcs

-- def.method("number").AddOrder = function(self, order)
--    local i_pos = self:FindOrder(order)
--    if i_pos == 0 then
--        table.insert(self._KeyMap, order)
--    end
-- end

-- def.method("number").RemoveOrder = function(self, order)
--    local i_pos = self:FindOrder(order)
--    if i_pos ~= 0 then
--        table.remove(self._KeyMap, i_pos)
--    end
-- end

-- def.method("number","=>","number").FindOrder = function(self, order)
--    for k, v in pairs(self._KeyMap) do
--        if v == order then
--            return k
--        end
--    end
--    return 0
-- end

def.method("=>", "table").GetTop = function(self)
	local max = 0
	-- if(#(self._PanelMap) > 0) then
	if (self:GetCount() > 0) then
		max = table.maxn(self._PanelMap)
	end

	-- print("max " .. max)
	if max ~= 0 then
		-- return self._PanelMap[max]

		for i = max, 1, -1 do
			if self._PanelMap[i] ~= nil and self._PanelMap[i]:IsCountAsUI() then
				return self._PanelMap[i]
			end
		end
	end

	return nil
end

-- def.method("=>","number").GetCount = function(self)
--    return #(self._KeyMap)
-- end

def.method("=>", "number").GetCount = function(self)
	local count = 0
	for _, _ in pairs(self._PanelMap) do
		count = count + 1
	end
	-- print("count " .. count)
	return count
end


-- def.field("Table")._Heap = 0

def.method().CollapseStack = function(self)
	local count = 0
	local i = 0

	if self._FloatingTop <= 0 then
		return
	end

	for i = self._UISetting.Order_Def.Fixed_Count + 1, self._UISetting.Order_Def.Fixed_Count + self._FloatingTop, 1 do
		if self._PanelMap[self._UISetting.Order_Def.Fixed_Count + count + 1] == nil then
			local p = self._PanelMap[i]
			if p ~= nil then
				count = count + 1
				self._PanelMap[i] = nil
				self._PanelMap[self._UISetting.Order_Def.Fixed_Count + count] = p
				p:MoveUISortingOrder(self._UISetting.Order_Def.Fixed_Count + count)

				local UISortingChangeEvent = require "Events.UISortingChangeEvent"
				local event = UISortingChangeEvent()
				event._UIScript = p
				CGame.EventManager:raiseEvent(nil, event)

			end
		else
			count = count + 1
		end
	end

	self._FloatingTop = count
	warn("CollapseStack " .. count)

end

CUIManLayer.Commit()
return CUIManLayer