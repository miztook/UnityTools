local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode

local CPateBase = Lplus.Class("CPateBase")
do
	local def = CPateBase.define

	local _staticData = nil
	def.static("=>","table").StaticData = function()
		if _staticData == nil then
			_staticData = {}
			--_staticData._TopPateRoot = nil

			_staticData._PlayerTopPatePrefab = nil
			_staticData._NPCPatePrefab = nil
			_staticData._ItemPatePrefab = nil
			_staticData._TextPopPrefab = nil

			_staticData._PlayerTopPateCache = {}
			_staticData._NPCPateCache = {}
			_staticData._ItemTopCache = {}
			_staticData._TextPopCache = {}

			--_staticData._AllCreated = {}
		end

		return _staticData
	end

	local function DeleteCache(cache)
		if cache ~= nil then
			while #cache > 0 do
				local tpt = table.remove(cache)
				if not IsNil(tpt) then
					tpt:Destroy()
				end
			end
		end
	end

	def.static().CleanCaches = function()
		if _staticData ~= nil then
			DeleteCache(_staticData._PlayerTopPateCache)
			DeleteCache(_staticData._NPCPateCache)
			DeleteCache(_staticData._ItemTopCache)
			DeleteCache(_staticData._TextPopCache)

			_staticData._PlayerTopPateCache = {}
			_staticData._NPCPateCache = {}
			_staticData._ItemTopCache = {}
			_staticData._TextPopCache = {}
		end
	end


	def.field(CEntity)._Owner = nil
	def.field("table")._UIObjectName2IdMap = nil
	def.field("boolean")._IsReleased = true

	def.field("boolean")._IsContentValid = false
	def.field("function")._OnCreateCB = nil
	def.field("boolean")._IsVisible = false

	def.field("userdata")._PateObj = nil
	def.field("userdata")._FollowComponent = nil

	def.field('number')._TextPopTimerId = -1
	def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Frame_QuestTalk = nil
	def.field('userdata')._Go_QuestTalk = nil
	def.field('userdata')._Go_QuestTalkLab = nil

	def.field('number')._VOffset = 3
	def.field('table')._Data = nil

--	def.static("boolean").Enable = function (enable)
--		_EnablePate = enable
--	end

	def.static("boolean").ShowAll = function (show)
		if not IsNil(game._TopPateCanvas) then
			if show then
				game._TopPateCanvas.localScale = Vector3.one
			else
				game._TopPateCanvas.localScale = Vector3.zero
			end
		end
	end
	
	def.static().Clear = function()
		--warn("**************Clear***************")
		--_staticData = nil
		--if _staticData ~= nil then
		--	 _staticData._AllCreated = {}
		--end
	end

	def.static().Setup = function ()
--		_PlayerTopPateCache = GameObject.New("PlayerTopPateCache")
--		_PlayerTopPateCache.position = Vector3.New(0, 10000, 0)
--		_NPCPateCache = GameObject.New("NPCPateCache")
--		_NPCPateCache.position = Vector3.New(0, 10000, 0)
--		_ItemTopCache = GameObject.New("ItemTopCache")
--		_ItemTopCache.position = Vector3.New(0, 10000, 0)
		--warn("Top cache "..tostring(_PlayerTopPateCache).." , "..tostring(_NPCPateCache).." , "..tostring(_ItemTopCache).." , ")

		CPateBase.CleanCaches()

		CPateBase.StaticData()

		--data._TopPateRoot = GameObject.Find("TopPateCanvas")

		-- 提前准备好资源
		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.MonsterTopPate, function(res)
				if res ~= nil then
					_staticData._NPCPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("MonsterTopPate Load Failed! ", PATH.MonsterTopPate)
				end
			end)

		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.ItemTopPate, function(res)
				if res ~= nil then
					_staticData._ItemPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("ItemTopPate Load Failed! ", PATH.ItemTopPate)
				end
			end)

		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.PlayerTopPate, function(res)
				if res ~= nil then
					_staticData._PlayerTopPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("PlayerTopPate Load Failed! ", PATH.PlayerTopPate)
				end
			end)

		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.TextPopPrefab, function(res)
				if res ~= nil then
					_staticData._TextPopPrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("TextPop Load Failed! ", PATH.TextPopPrefab)
				end
			end)

	end

	def.static().UpdateAllVisibility  = function ()
--		local data=CPateBase.StaticData()
--		for k,v in pairs(data._AllCreated) do
--			v:SetVisible(v._IsVisible)
--		end
	end

	--local NormalSize = Vector3.New(0.01, 0.01, 0.01)
	def.method("userdata", "number", "number", "=>", "userdata").CreateFromCacheInternal  = function (self, obj, offsetH, pix_scale)
		local tpt = nil
		local cache, limit, prefab = self:GetGoCache()
		if prefab == nil then
			warn("CPate Prefab is Nil!")
			return nil
		end

		while #cache > 0 do
			--warn("pop cache "..tostring(cache).." # "..#cache)
			tpt = table.remove(cache)
			if not IsNil(tpt) then
				--warn("Reuse top "..tpt.name .." as "..obj.name)
				break
			end
		end

		if not IsNil(tpt) then
			--tpt:SetParent(_TopPateRoot, false)
			self._PateObj = tpt
			GameUtil.SetLayerRecursively(self._PateObj, EnumDef.RenderLayer.TopPate)
			self:AttachTarget(obj, offsetH)
			self:UIFind()
			self:UIReset()
		else
			--warn("create new "..obj.name.." to cache "..tostring(cache))
			tpt = Object.Instantiate(prefab)
			--pate.name = "pate"
			local data=CPateBase.StaticData()
			tpt:SetParent(game._TopPateCanvas, false)
			tpt.localScale = Vector3.zero

			self._PateObj = tpt

			self:AttachTarget(obj, offsetH)
			self:UIFind()
			self:UIReset()

--            if pix_scale > 1 then
--                GameUtil.SetupWorldCanvas(self._PateObj, pix_scale)
--            else
--                GameUtil.SetupWorldCanvas(self._PateObj)
--            end

		end

		--tpt.name = tostring(self._Owner._ID) --obj.name
		tpt.name = obj.name
		--warn("Show Pate On ".. obj.name, debug.traceback())
		--self._IsContentValid = false

		return self._PateObj
	end



--	def.virtual("=>", "userdata").GetCacheRoot = function (self)
--		return nil
--	end
	def.virtual("=>", "table", "number", "userdata").GetGoCache = function (self)
		return nil, 0, nil
	end

	def.method("boolean").MarkAsValid = function (self,flag)
		self._IsContentValid = flag
	end

	def.method("string", "=>", "userdata").GetUIObject = function(self, name)
		local go = nil
		if self._UIObjectName2IdMap ~= nil and self._UIObjectName2IdMap[name] ~= nil then
			local id = self._UIObjectName2IdMap[name]
			go = GameUtil.GetPanelUIObjectByID(self._PateObj, id)
		else
			warn("this pate has no ".. name.. " cfg data or cfg data has error", debug.traceback())
		end

		return go
	end

	def.virtual().UIFind = function(self)
	end

	def.virtual().UIReset = function(self)	
	end

	def.method("userdata", "number").AttachTarget = function(self, target, offsetH)
		if IsNil(target) then return end
		local follow = self._PateObj:GetComponent(ClassType.CHUDFollowTarget)
		if follow == nil then follow = self._PateObj:AddComponent(ClassType.CHUDFollowTarget) end
		follow.FollowTarget = target
		local model = self._Owner:GetCurModel()
		if model ~= nil and model:GetGameObject() ~= nil then
			if self._Owner:IsMonster() == true then
                local monsterData = CElementData.GetTemplate("Monster", self._Owner:GetTemplateId())
                follow:AdjustOffsetWithScale(model:GetGameObject(), 0, monsterData.BodyScale)
            else
                follow:AdjustOffset(model:GetGameObject(), 0)
            end
		end
		self._FollowComponent = follow
	end
	
	def.method("userdata","number","=>","userdata","number").GetPateAttachInfo = function(self,obj,offsetH)
		if obj == nil then return nil, 0 end
		return obj, offsetH
	end

	def.method("=>","boolean").IsObjCreated = function (self)
		return not IsNil(self._PateObj)
	end

	def.method().CheckObject = function (self)
		if IsNil(self._Owner) then return end

		if not self._IsReleased and not self:IsObjCreated() then
			local attachObj, offsetH = self:GetPateAttachInfo(self._Owner._GameObject, self._VOffset)
			--local pate = self:CreateFromCacheInternal(attachObj, _PlayerTopPateCache, _PlayerTopPatePrefab, offsetH, 1)
			self._PateObj = self:CreateFromCacheInternal(attachObj, offsetH, 1)

			--self:UpdateName(true)
			if self._OnCreateCB ~= nil then
				self._OnCreateCB()
				self._OnCreateCB = nil
			end

			self:SyncDataToUI()

			--self._IsCreated = true
		end
	end

	def.virtual().Release = function (self)
		if not self._IsReleased then
			self:ReleaseTextPop()
			self:SetVisible(false)
			
			self._Data = nil
			self._IsReleased = true
			self._IsContentValid = false

			if self:IsObjCreated() then
				self._FollowComponent.FollowTarget = nil
				self._FollowComponent = nil

				local cache, limit, prefab = self:GetGoCache()
				if #cache < limit then

					self._PateObj.name=self._PateObj.name.."(Pooled)"
					GameUtil.SetLayerRecursively(self._PateObj, EnumDef.RenderLayer.Invisible)

					table.insert(cache, self._PateObj)
				else
					self._PateObj:Destroy()
				end

				self._PateObj = nil
				self._UIObjectName2IdMap = nil
			end

			self._Owner = nil

		end
	end

	def.method(CEntity,"function", "boolean").Init = function (self, obj, cb, visible)
		self._Owner = obj
		self._Data = {}
		self._IsReleased = false

		self._OnCreateCB = cb

		self._IsContentValid = self._IsContentValid or visible
		self:SetVisible(visible)

	end

	def.method("=>","boolean").CanShow = function (self)
		--return game._MiscSetting:IsShowHeadInfo() or self._Owner:IsHostPlayer()
		return true
	end

	def.method("boolean").SetVisible = function (self, visible)
		self._IsVisible = visible
		local is_visible= self._IsContentValid and self._IsVisible and self:CanShow()

--		if self._Owner:IsMonster() then
--			warn("X SetVisible "..self._Owner._ID.." "..tostring(is_visible)..", "..tostring(self._IsContentValid)..", "..debug.traceback())
--		end

		if is_visible then
			self:CheckObject()
		end

		if not self._IsReleased and self:IsObjCreated() then
			if self._FollowComponent then
				self._FollowComponent.enabled = is_visible
			end
			if self._PateObj ~= nil then
				if is_visible then
					--	self._PateObj.localScale = Vector3.zero
					--warn("SetVisible "..tostring(visible)..", "..self._PateObj.name, debug.traceback())

					--self._PateObj.localScale = Vector3.one
				else
					self._PateObj.localScale = Vector3.zero
				end
			end
		end

	end

	--	血量更改
	def.virtual("number").OnHPChange = function (self, value)
	end
	--  能量条更改
	def.virtual("number").OnStaChange = function (self, value)
	end
	--  指示更改 
	def.virtual("number").OnLogoChange = function (self, curType)
	end
    --  头衔更改
	def.virtual("boolean","string").OnTitleNameChange= function(self, isShow, name)
	end
	--  名称更改
	def.virtual("boolean").UpdateName= function(self,isShow)
	end
	--	设置名称
	def.virtual("string").SetName = function(self, name)
	end

	-- override this to show your things
	def.virtual().SyncDataToUI = function (self)
		if not self._IsReleased and self:IsObjCreated() then
			--XXX
		end
	end

	def.method("=>", "table", "number").GetTextPopGoCache = function (self)
		local data=CPateBase.StaticData()
		return data._TextPopCache, 50
	end

	def.method().CheckTextPopObj = function (self)
		self:CheckObject()

		if  not self._IsReleased and self:IsObjCreated() then
			if self._Go_QuestTalk == nil then
				local tpt = nil
				local cache, limit = self:GetTextPopGoCache()

				local pop_root = self._Frame_QuestTalk
				while #cache > 0 do
					tpt=table.remove(cache)
					if not IsNil(tpt) then
						break
					end
				end
				if IsNil(tpt) then
					local data=CPateBase.StaticData()
					local prefab = data._TextPopPrefab
					
					if prefab ~= nil then
						tpt = Object.Instantiate(prefab)
					else
						warn("CPate QuestTalk Prefab is Nil!")
					end
				end

				if tpt~=nil then
					tpt:SetParent(pop_root, false)
					--tpt.localScale = Vector3.zero
					tpt.name = "QTalk"
					self._Go_QuestTalk = tpt
					GUITools.SetUIActive(self._Go_QuestTalk, true)

					local ui_tpl=self._Go_QuestTalk:GetComponent(ClassType.UITemplate)
					if ui_tpl~=nil then
						self._Go_QuestTalkLab = ui_tpl:GetControl(0)
					end
				end
			end
		end
	end

	def.method().ReleaseTextPop = function (self)
		if self._TextPopTimerId>0 then
			_G.RemoveGlobalTimer(self._TextPopTimerId)
			self._TextPopTimerId = -1
		end

		if self._Go_QuestTalk ~= nil then
			if not IsNil(self._Go_QuestTalk) then
				local cache, limit = self:GetTextPopGoCache()
				if #cache < limit then
					local data=CPateBase.StaticData()
					self._Go_QuestTalk:SetParent(game._TopPateCanvas, false)
					GUITools.SetUIActive(self._Go_QuestTalk, false)
					self._Go_QuestTalk.name = "QTalk(Pooled)"
					table.insert(cache, self._Go_QuestTalk)
				else
					self._Go_QuestTalk:Destroy()
				end
			end
			self._Go_QuestTalk = nil
			self._Go_QuestTalkLab = nil
		end
	end

	def.method("boolean","string","number").TextPop = function (self, isShow, text, time)
		if isShow then
			if self._Frame_QuestTalk == nil then return end
			self:CheckTextPopObj()

			if self._Go_QuestTalk ~= nil and self._Go_QuestTalkLab ~= nil then
				if self._TextPopTimerId>0 then
					_G.RemoveGlobalTimer(self._TextPopTimerId)
					self._TextPopTimerId = -1
				end

				GUITools.SetUIActive(self._Frame_ActionTip, false)
				if time == 0 then
					time = 3
				end

				GUI.SetText(self._Go_QuestTalkLab,text)
				--GUITools.SetTextAlignmentByLineHeight(self._Go_QuestTalkLab,21)
				
				local ctext = self._Go_QuestTalkLab:GetComponent(ClassType.Text)
				local line = ctext.preferredHeight / 21
				local width = 0
				if line > 1 then
					width = GUITools.GetUiSize(self._Go_QuestTalkLab).Width
				else
					width = ctext.preferredWidth
				end
				GUITools.UIResize(self._Go_QuestTalk, width+20, ctext.preferredHeight+35)

				GUITools.SetUIActive(self._Frame_QuestTalk, true)
				--self._Go_QuestTalk:SetActive(true)

				self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
	        		GUITools.SetUIActive(self._Frame_QuestTalk, false)
	        		GUITools.SetUIActive(self._Frame_ActionTip, true)

					self:ReleaseTextPop()
				end)
			end
		else
			--if self._Go_QuestTalk ~= nil and self._Go_QuestTalkLab ~= nil then
				if self._TextPopTimerId > 0 then
					_G.RemoveGlobalTimer(self._TextPopTimerId)
					self._TextPopTimerId = -1
				end

        		GUITools.SetUIActive(self._Frame_QuestTalk, false)
        		GUITools.SetUIActive(self._Frame_ActionTip, true)
			--end
		end
	end


--def.static("=>","userdata").GetPlayerTopPatePrefab = function ()
--	return _staticData._PlayerTopPatePrefab
--end

--def.static("=>","userdata").GetNPCPatePrefab = function ()
--	return _NPCPatePrefab
--end

--def.static("=>","userdata").GetItemPatePrefab = function ()
--	return _ItemPatePrefab
--end

--def.static("=>","table").GetPlayerTopPateCache = function ()
--	return _PlayerTopPateCache
--end

--def.static("=>","table").GetNPCPateCache = function ()
--	return _NPCPateCache
--end

--def.static("=>","table").GetItemPateCache = function ()
--	return _ItemTopCache
--end

	CPateBase.Commit()
end

--local CNPCTopPate = require("GUI.CPates.CNPCTopPate")
--local CPlayerTopPate = require("GUI.CPates.CPlayerTopPate")
--local CItemTopPate = require("GUI.CPates.CItemTopPate")

--return
--{
--	CPateBase = CPate,
--	CNPCTopPate = CNPCTopPate,
--	CPlayerTopPate = CPlayerTopPate,
--	CItemTopPate = CItemTopPate,
--}



return CPateBase