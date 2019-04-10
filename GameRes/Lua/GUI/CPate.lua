local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode

local _EnablePate = true
local _PlayerTopPatePrefab = nil
local _NPCPatePrefab = nil
local _ItemPatePrefab = nil

local _PlayerTopPateCache = {}
local _NPCPateCache = {}
local _ItemTopCache = {}

local _TopPateRoot = nil
local CPate = Lplus.Class("CPate")
do
	local def = CPate.define
	def.field("userdata")._PateObj = nil
	def.field("userdata")._FollowComponent = nil
	def.field(CEntity)._Owner = nil
	def.field("table")._UIObjectName2IdMap = nil

	def.field("boolean")._IsContentValid = false

	def.static("boolean").Enable = function (enable)
		_EnablePate = enable
	end

	def.static("boolean").ShowAll = function (show)
		if not IsNil(_TopPateRoot) then
			if show then
				_TopPateRoot.localScale = Vector3.one 
			else
				_TopPateRoot.localScale = Vector3.zero
			end
		end
	end
	
	def.static().Clear = function()
		--warn("**************Clear***************")
	end

	def.static().Setup = function ()
--		_PlayerTopPateCache = GameObject.New("PlayerTopPateCache")
--		_PlayerTopPateCache.position = Vector3.New(0, 10000, 0)
--		_NPCPateCache = GameObject.New("NPCPateCache")
--		_NPCPateCache.position = Vector3.New(0, 10000, 0)
--		_ItemTopCache = GameObject.New("ItemTopCache")
--		_ItemTopCache.position = Vector3.New(0, 10000, 0)

		--warn("Top cache "..tostring(_PlayerTopPateCache).." , "..tostring(_NPCPateCache).." , "..tostring(_ItemTopCache).." , ")

		_TopPateRoot = GameObject.Find("TopPateCanvas")

		-- 提前准备好资源
		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.MonsterTopPate, function(res)
				if res ~= nil then
					_NPCPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("MonsterTopPate Load Failed! ", PATH.MonsterTopPate)
				end
			end)

		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.ItemTopPate, function(res)
				if res ~= nil then
					_ItemPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("ItemTopPate Load Failed! ", PATH.ItemTopPate)
				end
			end)

		GameUtil.AsyncLoad(_G.InterfacesDir .. PATH.PlayerTopPate, function(res)
				if res ~= nil then
					_PlayerTopPatePrefab = res
					GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
				else
					warn("PlayerTopPate Load Failed! ", PATH.PlayerTopPate)
				end
			end)
	end

	--local NormalSize = Vector3.New(0.01, 0.01, 0.01)
	def.method("userdata", "table", "userdata", "number", "number", "=>", "userdata").CreateFromCacheInternal  = function (self, obj, cache, prefab, offsetH, pix_scale)
		local tpt = nil
		while #cache > 0 do
			--warn("pop cache "..tostring(cache).." # "..#cache)
			tpt=table.remove(cache)
			if not IsNil(tpt) then
				--warn("Reuse top "..tpt.name .." as "..obj.name)
				break
			end
		end

		if not IsNil(tpt) then
			--tpt:SetParent(_TopPateRoot, false)
			self._PateObj = tpt
			self:AttachTarget(obj, offsetH)
			self:UIFind()
			self:Reset()
		else
			--warn("create new "..obj.name.." to cache "..tostring(cache))

			tpt = Object.Instantiate(prefab)
			--pate.name = "pate"
			tpt:SetParent(_TopPateRoot, false)
			tpt.localScale = Vector3.zero
			self._PateObj = tpt

			self:AttachTarget(obj, offsetH)
			self:UIFind()
			self:Reset()

--            if pix_scale > 1 then
--                GameUtil.SetupWorldCanvas(self._PateObj, pix_scale)
--            else
--                GameUtil.SetupWorldCanvas(self._PateObj)
--            end

		end

		tpt.name=obj.name
		--warn("Show Pate On ".. obj.name, debug.traceback())
		--self._IsContentValid = false

		return self._PateObj
	end

	def.virtual().Reset = function(self)	
	end

--	def.virtual("=>", "userdata").GetCacheRoot = function (self)
--		return nil
--	end
	def.virtual("=>", "table", "number").GetCache = function (self)
		return nil, 0
	end

	def.method("boolean").MarkAsValid = function (self,flag)
		self._IsContentValid = flag
	end

	def.virtual().Release = function(self)
		if self._PateObj then
			--warn("top Release "..self._PateObj.name)
			--warn("CPate Release self._FollowComponent.FollowTarget "..self._FollowComponent.FollowTarget.name,debug.traceback())

			self._FollowComponent.FollowTarget = nil
			self._FollowComponent = nil
			self:SetVisible(false)

			--warn("2")

			local cache, limit = self:GetCache()
			if #cache < limit then
				table.insert(cache, self._PateObj)

				--warn("push cache "..tostring(cache).." # "..#cache)

			else
				self._PateObj:Destroy()
			end

			self._PateObj = nil
			self._UIObjectName2IdMap = nil
		end
		self._IsContentValid=false
		self._Owner = nil
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
	--  头部气泡
	def.virtual("boolean","string","number").TextPop = function (self,isShow,text,time)
	end

	def.method("boolean").SetVisible = function (self, visible)

		--warn("SetVisible "..tostring(visible)..", "..self._PateObj.name, debug.traceback())
		local is_visible= self._IsContentValid and visible

		if self._FollowComponent then
			self._FollowComponent.enabled = is_visible
		end
		if self._PateObj ~= nil then
			if is_visible then
			--	self._PateObj.localScale = Vector3.zero
			--warn("SetVisible "..tostring(visible)..", "..self._PateObj.name, debug.traceback())
			else
				self._PateObj.localScale = Vector3.zero
			end
		end
	end

	CPate.Commit()
end

local CNPCTopPate = Lplus.Extend(CPate, "CNPCTopPate")
do
	local def = CNPCTopPate.define
	
	def.field('userdata')._Go_Name = nil
	def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Go_ActionTip = nil
	def.field('userdata')._Go_TitleName = nil
	--def.field('userdata')._Frame_Title = nil
	def.field('userdata')._Go_HP = nil
	def.field('userdata')._Go_Energy = nil
	--def.field('userdata')._Frame_QuestTalk = nil
	def.field('userdata')._Go_QuestTalk = nil
	def.field('userdata')._Go_Talk = nil
	
	def.field('userdata')._Go_Back = nil
	def.field('userdata')._Go_Front = nil

	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_TitleName = nil

	def.field('number')._TimerId = -1
	def.field('number')._CurTipType = -1
	def.field('number')._NextTipType  = -1
	def.field('number')._TextPopTimerId = -1

	def.final("=>", CNPCTopPate).new = function ()
		local obj = CNPCTopPate()
		return obj
	end

	def.override().Reset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		GUITools.SetUIActive(self._Go_TitleName, false)
		GUITools.SetUIActive(self._Go_HP, false)
		GUITools.SetUIActive(self._Go_Energy, false)
		GUITools.SetUIActive(self._Go_QuestTalk, false)
	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _NPCPateCache
--	end

	--returns a cache table, and its limit in count
	def.override("=>", "table", "number").GetCache = function (self)
		return _NPCPateCache, 50
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Monster")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			--self._Frame_Title = self:GetUIObject("Frame_Title")
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_Energy = self:GetUIObject("Prg_M_Head_Energy")
			--self._Frame_QuestTalk = self:GetUIObject("Frame_QuestTalk")
			self._Go_QuestTalk = self:GetUIObject("Img_QuestTalk")
			self._Go_Talk = self:GetUIObject("Lab_Talk")
			self._Go_Back = self:GetUIObject("Img_Back0")
			self._Go_Front = self:GetUIObject("Img_Front0")
		
			if self._Go_Name ~= nil then
				self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
			if 	self._Go_TitleName ~= nil then
				self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end
		end
	end

	def.method(CEntity,"function").Create = function (self, obj, cb)
		self._Owner = obj
		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 2.5)
		local pate = self:CreateFromCacheInternal(attachObj, _NPCPateCache, _NPCPatePrefab, offsetH, 1)
		--self:UpdateName(true)
		if cb ~= nil then cb() end
	end 

	def.override().Release = function(self)

		--warn("monster_top Release")

		_G.RemoveGlobalTimer(self._TimerId)
		_G.RemoveGlobalTimer(self._TextPopTimerId)
		CPate.Release(self)

		--self._Go_Name = nil
		self._Frame_ActionTip = nil
		self._Go_ActionTip = nil
		--self._Go_TitleName = nil
		--self._Frame_Title = nil
		self._Go_HP = nil
		self._Go_Energy = nil
		self._Go_QuestTalk = nil
		self._Go_Talk = nil
		self._Go_Back = nil
		self._Go_Front = nil

		self._Txt_TitleName = nil
		self._Txt_Name = nil
	end

	def.override("number").OnHPChange = function (self, num)
		if self._PateObj ~= nil then
			local hpIndicator = self._Go_HP:GetComponent(ClassType.GBlood)
			hpIndicator:SetValue(num)
		end
	end

	def.override("number").OnStaChange = function (self, num)
		if self._PateObj ~= nil then
			local staminaIndicator = self._Go_Energy:GetComponent(ClassType.GBlood)
			staminaIndicator:SetValue(num)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._PateObj == nil or self._Owner == nil then return end
		if curType ~= EnumDef.EntityLogoType.None then
			GUITools.SetUIActive(self._Go_ActionTip, true)
			local curTipType = self:GetFristTipType(curType)
			if curTipType == EnumDef.EntityLogoType.InViolent then
				curTipType = 9
			end
			GUITools.SetGroupImg(self._Go_ActionTip, curTipType)		
		else
        	self:ActionTipHideTest()
		end

		self._Owner._CurLogoType = curType
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
	    if self._PateObj == nil then return end
		
		if name == "" then
			isShow=false
		end

		--GUITools.SetUIActive(self._Frame_Title, isShow)
		GUITools.SetUIActive(self._Go_TitleName, isShow)
		GameUtil.SetIgnoreLayout(self._Go_TitleName, not isShow)

		if isShow then
			--GUI.SetTextAndChangeLayout(self._Go_TitleName, tostring("["..name.."]"), 200)
			if self._Txt_TitleName ~= nil then
				self._Txt_TitleName.text = "["..name.."]"

				--warn("Monster UpdateTitleName ", debug.traceback())
			end
		end
	end

	--更改名称
	def.override("boolean").UpdateName = function(self,isShow)
		--warn("Monster UpdateName "..tostring(isShow), debug.traceback())

		if self._PateObj == nil then return end
		GUITools.SetUIActive(self._Go_Name, isShow)
		if isShow then
			local name = self._Owner:GetEntityColorName()
			if game._IsOpenDebugMode == true then
				local clientPosX, clientPosY, clientPosZ = self._Owner:GetPosXYZ()
				clientPosX = string.format("%.2f", clientPosX)
				clientPosY = string.format("%.2f", clientPosY)
				clientPosZ = string.format("%.2f", clientPosZ)			
				local clientPos = clientPosX .. "," .. clientPosY .. "," .. clientPosZ
				if tonumber(self._Owner:GetTemplateId()) ~= 0 then
					name = name .. tostring(self._Owner:GetTemplateId()) .. ", CPos:".. clientPos
				else
					-- name = name .. self._Owner._ID .. ", CPos:".. clientPos
				end
			end
			--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)
			if self._Txt_Name ~= nil then
				self._Txt_Name.text = name
				--warn("Monster UpdateName ", debug.traceback())
			end

		end
	end
		
	--设置名称，暂时只用于宠物
	def.override("string").SetName = function(self, name)
		--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)
		if self._Txt_Name ~= nil then
			self._Txt_Name.text = name
		end
	end

	def.method("boolean","number").SetHPLineIsShow = function (self,isShow,curType)
		if self._Go_HP ~= nil then
			GUITools.SetUIActive(self._Go_HP, isShow)
			--self._Go_HP:SetActive(isShow)
			if isShow then
				if curType ~= EnumDef.HPColorType.None then
					GUITools.SetGroupImg(self._Go_Back, curType)
					GUITools.SetGroupImg(self._Go_Front, curType)
				end

				self:OnHPChange(self._Owner._InfoData._CurrentHp / self._Owner._InfoData._MaxHp)
			end
		end
	end

	def.method("boolean").SetStaLineIsShow = function (self,isShow)
		if self._PateObj == nil then return end
		GUITools.SetUIActive(self._Go_Energy, isShow)
		if isShow then
			self:OnStaChange(self._Owner._InfoData._CurrentStamina / self._Owner._InfoData._MaxStamina)
		end
	end

	local _ActionTips = { [1] = {0,1,2,3,4,5,6,7}, [2] = {8,9,10,11,12,13,14} }
	--获取信息显示优先级
	def.method('number','=>','number').GetTipShowLv = function (self,actionType)
		for i,v in pairs(_ActionTips) do
			for lv,_type in pairs(v) do
				if _type == actionType then
					return i
				end
			end
		end
		return -1
	end

	def.method('number','=>','number').GetFristTipType = function (self,actionType)
		if self._PateObj == nil then return end
		local lvOld = self:GetTipShowLv( self._CurTipType )
		local lvNew = self:GetTipShowLv( actionType )

		if lvOld == lvNew or self._CurTipType == -1 then
			self._CurTipType = actionType
		elseif lvOld < lvNew then
			self._NextTipType = self._CurTipType
			self._CurTipType = actionType
		else
			self._NextTipType = actionType
		end

		return self._CurTipType
	end


	def.method("number","number").CombatTipChange = function (self,actionType,time)
		if self._PateObj == nil then return end
		if actionType ~= EnumDef.EntityFightType.None and not self._Owner:IsDead() then
			GUITools.SetUIActive(self._Go_ActionTip, true)
			GUITools.SetGroupImg(self._Go_ActionTip,self:GetFristTipType(actionType-1))
			--self._NextTipType = 3
			if time > 0 then
				_G.RemoveGlobalTimer(self._TimerId)
		        self._TimerId = _G.AddGlobalTimer(time, true, function()
		        	self:ActionTipHideTest()
			    end)
			end
		else
			_G.RemoveGlobalTimer(self._TimerId)
			self:ActionTipHideTest()
	    end
	end

	def.method().ActionTipHideTest = function (self)
    	if self._NextTipType ~= -1 then
    		GUITools.SetUIActive(self._Go_ActionTip, true)
			self._CurTipType = self._NextTipType
			GUITools.SetGroupImg(self._Go_ActionTip,self._CurTipType)
			self._NextTipType = -1
        else
    		GUITools.SetUIActive(self._Go_ActionTip, false)
        	self._CurTipType = -1
        end
	end

	def.override("boolean","string","number").TextPop = function (self,isShow,text,time)
		if self._PateObj == nil then return end

    	--GUITools.SetUIActive(self._Go_QuestTalk, isShow)
		if isShow then
			_G.RemoveGlobalTimer(self._TextPopTimerId)

    		GUITools.SetUIActive(self._Frame_ActionTip, false)
			if time == 0 then
				time = 3
			end

			GUI.SetText(self._Go_Talk,text)

			local ctext = self._Go_Talk:GetComponent(ClassType.Text)
			local line = ctext.preferredHeight / 21
			local width = 0
			if line > 1 then
				width = GUITools.GetUiSize(self._Go_Talk).Width
			else
				width = ctext.preferredWidth
			end
			GUITools.UIResize(self._Go_QuestTalk, width+20, ctext.preferredHeight+35)

			self._Go_QuestTalk:SetActive(true)
			GUITools.SetUIActive(self._Go_QuestTalk, true)

	        self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
	        	GUITools.SetUIActive(self._Go_QuestTalk, false)
	        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		    end)
		else
        	GUITools.SetUIActive(self._Go_QuestTalk, false)
        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		end
	end
	CNPCTopPate.Commit()
end

local CItemTopPate = Lplus.Extend(CPate, "CItemTopPate")
do
	local def = CItemTopPate.define
	
	def.final("=>", CItemTopPate).new = function ()
		local obj = CItemTopPate()
		return obj
	end
	
	def.field('userdata')._Go_Name = nil
	def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Go_ActionTip = nil
	def.field('userdata')._Go_TitleName = nil
	--def.field('userdata')._Frame_Title = nil
	def.field('userdata')._Txt_TitleName = nil
	def.field('userdata')._Txt_Name = nil

	def.override().Reset = function(self)
		GUITools.SetUIActive(self._Go_Name, false)
		GUITools.SetUIActive(self._Go_TitleName, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		GUITools.SetUIActive(self._Go_ActionTip, false)
	end

	def.override().Release = function(self)
		CPate.Release(self)

		self._Go_Name = nil
		self._Frame_ActionTip = nil
		self._Go_ActionTip = nil
		self._Go_TitleName = nil
		--self._Frame_Title = nil
		self._Txt_TitleName = nil
		self._Txt_Name = nil
	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _ItemTopCache
--	end
	def.override("=>", "table", "number").GetCache = function (self)
		return _ItemTopCache, 50
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Obj")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			--self._Frame_Title = self:GetUIObject("Frame_Title")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			if self._Go_TitleName~=nil then
				self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end
			if self._Go_Name~=nil then
				self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
		end
	end

	def.method(CEntity,"function").Create = function (self, obj, cb)
		self._Owner = obj
		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 2.5)
		local pate = self:CreateFromCacheInternal(attachObj, _ItemTopCache, _ItemPatePrefab, offsetH, 1)
		self:UpdateName(true)
		if cb ~= nil then cb() end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._PateObj == nil or self._Owner == nil then return end
		if curType ~= EnumDef.EntityLogoType.None then
			local CElementSkill = require "Data.CElementSkill"
			GUITools.SetUIActive(self._Go_ActionTip, true)			   
			-- warn("lidaming icon name ==".. CElementSkill.Get(self._Owner._MineralTemplate.SkillId).IconName)			
			GUITools.SetIcon(self._Go_ActionTip, CElementSkill.Get(self._Owner._MineralTemplate.SkillId).IconName)
		else
			GUITools.SetUIActive(self._Go_ActionTip, false)
		end
		self._Owner._CurLogoType = curType
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
	    if self._Go_TitleName ~= nil then
			--GUITools.SetUIActive(self._Frame_Title, isShow)
			if name == "" then
				isShow = false
			end
			GUITools.SetUIActive(self._Go_TitleName, isShow)
			if isShow then
				if self._Txt_TitleName ~= nil then
					--GUI.SetTextAndChangeLayout(self._Go_TitleName, tostring("["..name.."]"), 200)
					self._Txt_TitleName.text = "["..name.."]"
				end
			end
		end
	end

	def.override("boolean").UpdateName= function(self, isShow)		
		if self._PateObj == nil then return end	
		if not self._Owner and not game._IsOpenDebugMode then
			isShow = false
		end

		--warn("CItemPate UpdateName "..tostring(isShow), debug.traceback())

		if isShow then
			local name = ""	
			if self._Owner._MineralTemplate ~= nil then					
				name = self._Owner._MineralTemplate.TextDisplayName
			end
			if game._IsOpenDebugMode == true then
				local clientPosX, clientPosY, clientPosZ = self._Owner:GetPosXYZ()
				clientPosX = string.format("%.2f", clientPosX)
				clientPosY = string.format("%.2f", clientPosY)
				clientPosZ = string.format("%.2f", clientPosZ)						
				local clientPos = clientPosX .. "," .. clientPosY .. "," .. clientPosZ
				if tonumber(self._Owner:GetTemplateId()) ~= 0 then
					name = name .. tostring(self._Owner:GetTemplateId()) .. ", CPos:".. clientPos
				else
					name = name .. self._Owner._ID .. ", CPos:".. clientPos
				end		
			end
			-- warn("lidaming debugOpen name == ".. name)
			-- GUI.SetText(self._Go_Name, name)
			--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)

			if name == "" then
				isShow = false
			end

			GUITools.SetUIActive(self._Go_Name, isShow)

			if isShow then
				if self._Txt_Name ~= nil then
					self._Txt_Name.text = name
				end
			end
		end


	end

	CItemTopPate.Commit()
end

local CPlayerTopPate = Lplus.Extend(CPate, "CPlayerTopPate")
do
	local def = CPlayerTopPate.define

	def.field('userdata')._Go_Name = nil
	def.field('userdata')._Go_GuildName = nil
	def.field("table")._Go_GuildIcon = BlankTable
	def.field('userdata')._Go_TitleName = nil
	def.field('userdata')._Go_TitleIcon = nil
	def.field('userdata')._Go_PkIcon = nil
	def.field('userdata')._Go_HP = nil
	def.field('userdata')._Go_Back = nil
	def.field('userdata')._Go_Front = nil
	def.field('userdata')._Go_ActionTip = nil

	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_GuildName = nil
	def.field('userdata')._Txt_TitleName = nil

	--def.field('userdata')._Frame_Title = nil
	--def.field("userdata")._Frame_Guild = nil
	def.field("userdata")._Img_Convoy = nil
	--def.field('userdata')._Frame_CharName = nil
	def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Go_QuestTalk = nil
	def.field('userdata')._Go_Talk = nil
	def.field('userdata')._Frame_Guild_Flag = nil
	def.field('number')._TextPopTimerId = -1
	def.field('number')._TextHeight = 18

	def.final("=>", CPlayerTopPate).new = function ()
		local obj = CPlayerTopPate()
		return obj
	end

	def.override().Reset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		--GUITools.SetUIActive(self._Frame_Guild, false)
		GUITools.SetUIActive(self._Go_TitleIcon, false)
		GUITools.SetUIActive(self._Go_GuildName, false)
		GameUtil.SetIgnoreLayout(self._Go_GuildName, false)
		GUITools.SetUIActive(self._Frame_Guild_Flag, false)
		GUITools.SetUIActive(self._Go_PkIcon, false)
		GUITools.SetUIActive(self._Go_HP, false)
		GUITools.SetUIActive(self._Go_QuestTalk, false)
		--self._Go_QuestTalk:SetActive(false)
		GUITools.SetUIActive(self._Img_Convoy, false)
	end

	def.override().Release = function(self)
		_G.RemoveGlobalTimer(self._TextPopTimerId)
		CPate.Release(self)

		self._Txt_Name = nil
		self._Txt_GuildName = nil
		self._Txt_TitleName = nil

		self._Go_Name = nil
		self._Go_GuildName = nil
		self._Go_TitleName = nil
		self._Go_TitleIcon = nil
		self._Go_PkIcon = nil
		self._Go_HP = nil
		self._Go_Back = nil
		self._Go_Front = nil
		self._Go_ActionTip = nil
		--self._Frame_Title = nil
		--self._Frame_Guild = nil
		--self._Frame_CharName = nil
		self._Frame_ActionTip = nil
		self._Go_QuestTalk = nil
		self._Go_Talk = nil
		self._Frame_Guild_Flag = nil
		self._Img_Convoy = nil
	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _PlayerTopPateCache
--	end
	def.override("=>", "table", "number").GetCache = function (self)
		return _PlayerTopPateCache, 50
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Cha")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Go_GuildName = self:GetUIObject("Txt_Guild")
			self._Go_GuildIcon[1] = self:GetUIObject("Img_Guild_1")
			self._Go_GuildIcon[2] = self:GetUIObject("Img_Guild_2")
			self._Go_GuildIcon[3] = self:GetUIObject("Img_Guild_3")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			self._Go_TitleIcon = self:GetUIObject("Img_Title")
			--self._Frame_Title = self:GetUIObject("Frame_Title")
			--self._Frame_Guild = self:GetUIObject("Frame_Guild")
			self._Img_Convoy = self:GetUIObject("Img_Convoy")
			--self._Frame_CharName = self:GetUIObject("Frame_CharName")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Go_PkIcon = self:GetUIObject("Img_PK")
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_Back = self:GetUIObject("Img_Back")
			self._Go_Front = self:GetUIObject("Img_Front")
			self._Go_QuestTalk = self:GetUIObject("Img_QuestTalk")
			self._Go_Talk = self:GetUIObject("Lab_Talk")
			self._Frame_Guild_Flag = self:GetUIObject("Frame_GuildFlag")
			--self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)

			if self._Go_Name ~= nil then
				self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
			if self._Go_GuildName ~= nil then
				self._Txt_GuildName = self._Go_GuildName:GetComponent(ClassType.Text)
			end
			if self._Go_TitleName ~= nil then
				self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end
		end
	end

	def.method(CEntity,"function").Create = function (self, obj, cb)
		self._Owner = obj
		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 3)
		local pate = self:CreateFromCacheInternal(attachObj, _PlayerTopPateCache, _PlayerTopPatePrefab, offsetH, 1)

		self:UpdateName(true)

		if cb ~= nil then
			cb()
		end
	end

	def.override("number").OnHPChange = function (self, num)
		if self._PateObj ~= nil then
			local hpIndicator = self._Go_HP:GetComponent(ClassType.GBlood)
			hpIndicator:SetValue(num)
		end
	end

	--公会更改
	def.method("boolean", "table").OnGuildNameChange = function (self, isShow, guild)
	    if self._Go_GuildName ~= nil then
			--GUITools.SetUIActive(self._Frame_Guild, isShow)
			GUITools.SetUIActive(self._Go_GuildName, isShow)
			GameUtil.SetIgnoreLayout(self._Go_GuildName, not isShow)
			GUITools.SetUIActive(self._Frame_Guild_Flag, isShow)

			if isShow then
				-- GUI.SetText(self._Go_GuildName, tostring(RichTextTools.GetTopPateColorText("["..guild._GuildName.."]", 1))
				--GUI.SetTextAndChangeLayout(self._Go_GuildName, tostring("["..guild._GuildName.."]"), 200)

				if self._Txt_GuildName ~= nil then
					self._Txt_GuildName.text = "["..guild._GuildName.."]"
				end

				game._GuildMan:SetPlayerGuildIcon(guild._GuildIconInfo, self._Go_GuildIcon)
				-- 瑞龙需求：有公会，PK模式的图标显示在名称和公会中间。
				--self._TextHeight = 34 -- text的最小高度。
				-- warn("lidaming self._TextHeight ==", self._TextHeight)
				self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)
			else
				-- 瑞龙需求：没有公会，PK模式的图标显示在名称中间。
				--self._TextHeight = 17
				self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight/2, 0)

			end
		end
	end

	-- 护送更改
	def.method("number").OnGuildConvoyChange = function(self, index)
		local isShow = index > 1
		GUITools.SetUIActive(self._Img_Convoy, isShow)
		if isShow then
			GUITools.SetUIActive(self._Go_PkIcon, false)
			GUITools.SetGroupImg(self._Img_Convoy, index + 2)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._PateObj == nil or self._Owner == nil then return end
		if curType ~= EnumDef.EntityLogoType.None then
			if curType == EnumDef.EntityLogoType.Rescue then
				GUITools.SetUIActive(self._Go_PkIcon, true)
				GUITools.SetUIActive(self._Go_ActionTip, false)
				GUITools.SetGroupImg(self._Go_PkIcon, 1)
			else
				GUITools.SetGroupImg(self._Go_ActionTip, curType)
				GUITools.SetUIActive(self._Go_ActionTip, true)
				GUITools.SetUIActive(self._Go_PkIcon,false)
			end			
		else			
			if self._Owner:GetPkMode() == EPkMode.EPkMode_Massacre then
				GUITools.SetUIActive(self._Go_PkIcon, true)
			end
			GUITools.SetUIActive(self._Go_ActionTip, false)
		end
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)

		--warn("CItemPate OnTitleNameChange "..tostring(isShow), debug.traceback())

	    if self._Go_TitleName ~= nil then
			if name == "" then
				isShow=false
			end

			--GUITools.SetUIActive(self._Frame_Title, isShow)
			GUITools.SetUIActive(self._Go_TitleIcon, isShow)
			--GUITools.SetUIActive(self._Go_TitleName, isShow)

			--if not IsNil(self._Go_TitleIcon) then
			if isShow then

				local Designation = game._DesignationMan:GetDesignationDataByID(self._Owner:GetDesignationId())    -- game._DesignationMan:GetCurDesignation()
				if Designation ~= nil then 
					GUITools.SetGroupImg(self._Go_TitleIcon, Designation.Quality)
				end

				if self._Txt_TitleName ~= nil then
					self._Txt_TitleName.text = name
				end
			end
			--end
			-- GUI.SetText(self._Go_TitleName, RichTextTools.GetTopPateColorText(name, 2) )
			--GUI.SetTextAndChangeLayout(self._Go_TitleName, tostring(name), 200)
		end
	end

	def.override("boolean").UpdateName= function(self,isShow)

		--warn("CItemPate UpdateName "..tostring(isShow), debug.traceback())

		if self._PateObj == nil then return end
		GUITools.SetUIActive(self._Go_Name, isShow)
		if isShow then
			local name = self._Owner:GetEntityColorName()
			if game._IsOpenDebugMode == true then
				local clientPosX, clientPosY, clientPosZ = self._Owner:GetPosXYZ()
				clientPosX = string.format("%.2f", clientPosX)
				clientPosY = string.format("%.2f", clientPosY)
				clientPosZ = string.format("%.2f", clientPosZ)		
				local clientPos = clientPosX .. "," .. clientPosY .. "," .. clientPosZ
				name = name .. self._Owner._ID .. ", CPos:".. clientPos
			end
			-- GUI.SetText(self._Go_Name, name )
			--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)
			if self._Txt_Name ~=nil then
				self._Txt_Name.text = name
			end

		end
	end

	def.method("boolean").SetAutoPathingState= function(self,isAutoPath)
		if self._PateObj == nil then return end
		
	    local autoPrefab = self._PateObj: FindChild("Prg_Find")
	    if(autoPrefab == nil) then return end

	    GUITools.SetUIActive(autoPrefab, isAutoPath)
	end

	def.method("boolean").SetPKIconIsShow = function (self,isShow)
		if self._Go_PkIcon ~= nil then
			-- 护送图标显示优先级高于PK模式
			if self._Img_Convoy.activeSelf then
				return
			end
			if self._Owner:CanRescue() and self._Owner:IsFriendly() then
				GUITools.SetUIActive(self._Go_PkIcon, true)
				GUITools.SetGroupImg(self._Go_PkIcon, 1)
			else
				GUITools.SetUIActive(self._Go_PkIcon, isShow)
				-- 显示PK模式图标，并且是杀戮模式
				if isShow then
					GUITools.SetGroupImg(self._Go_PkIcon, 0)
				end
			end
		end
	end

	def.method("boolean","number").SetHPLineIsShow = function (self,isShow,curType)
		if self._Go_HP ~= nil then
			GUITools.SetUIActive(self._Go_HP, isShow)
			if curType ~= EnumDef.HPColorType.None then
				GUITools.SetGroupImg(self._Go_Back, curType)
				GUITools.SetGroupImg(self._Go_Front, curType)
			end
			if isShow then
				self:OnHPChange(self._Owner._InfoData._CurrentHp / self._Owner._InfoData._MaxHp)
			end
		end
	end

	def.override("boolean","string","number").TextPop = function (self,isShow,text,time)
		if self._PateObj == nil then return end

		if isShow then
			_G.RemoveGlobalTimer(self._TextPopTimerId)

			GUITools.SetUIActive(self._Frame_ActionTip, false)
			if time == 0 then
				time = 3
			end

			GUI.SetText(self._Go_Talk,text)
			--GUITools.SetTextAlignmentByLineHeight(self._Go_Talk,21)

			local ctext = self._Go_Talk:GetComponent(ClassType.Text)
			local line = ctext.preferredHeight / 21
			local width = 0
			if line > 1 then
				width = GUITools.GetUiSize(self._Go_Talk).Width
			else
				width = ctext.preferredWidth
			end
			GUITools.UIResize(self._Go_QuestTalk, width+20, ctext.preferredHeight+35)

			GUITools.SetUIActive(self._Go_QuestTalk, true)
			self._Go_QuestTalk:SetActive(true)

	        self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
	        	GUITools.SetUIActive(self._Go_QuestTalk, false)
	        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		    end)
		else
        	GUITools.SetUIActive(self._Go_QuestTalk, false)
        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		end
	end
	CPlayerTopPate.Commit()
end

local CPlayerMirrorTopPate = Lplus.Extend(CPate, "CPlayerMirrorTopPate")
do
	local def = CPlayerMirrorTopPate.define

	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_GuildName = nil
	def.field('userdata')._Txt_TitleName = nil

	def.field('userdata')._Go_Name = nil
	def.field('userdata')._Go_GuildName = nil
	def.field("table")._Go_GuildIcon = BlankTable
	def.field('userdata')._Go_TitleName = nil
	def.field('userdata')._Go_TitleIcon = nil
	def.field('userdata')._Go_PkIcon = nil
	def.field('userdata')._Go_HP = nil
	def.field('userdata')._Go_Back = nil
	def.field('userdata')._Go_Front = nil
	def.field('userdata')._Go_ActionTip = nil

	--def.field('userdata')._Frame_Title = nil
	--def.field("userdata")._Frame_Guild = nil
	def.field("userdata")._Img_Convoy = nil
	--def.field('userdata')._Frame_CharName = nil
	def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Go_QuestTalk = nil
	def.field('userdata')._Go_Talk = nil
	def.field('userdata')._Frame_Guild_Flag = nil
	def.field('number')._TextPopTimerId = -1
	def.field('number')._TextHeight = 18

	def.final("=>", CPlayerMirrorTopPate).new = function ()
		local obj = CPlayerMirrorTopPate()
		return obj
	end

	def.override().Reset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		--GUITools.SetUIActive(self._Frame_Guild, false)
		GUITools.SetUIActive(self._Go_TitleIcon, false)
		GUITools.SetUIActive(self._Go_GuildName, false)
		GameUtil.SetIgnoreLayout(self._Go_GuildName, false)
		GUITools.SetUIActive(self._Frame_Guild_Flag, false)
		GUITools.SetUIActive(self._Go_PkIcon, false)
		GUITools.SetUIActive(self._Go_HP, false)
		GUITools.SetUIActive(self._Go_QuestTalk, false)
		--self._Go_QuestTalk:SetActive(false)
		GUITools.SetUIActive(self._Img_Convoy, false)
	end

	def.override().Release = function(self)
		_G.RemoveGlobalTimer(self._TextPopTimerId)
		CPate.Release(self)

		self._Txt_Name = nil
		self._Txt_GuildName = nil
		self._Txt_TitleName = nil

		self._Go_Name = nil
		self._Go_GuildName = nil
		self._Go_TitleName = nil
		self._Go_TitleIcon = nil
		self._Go_PkIcon = nil
		self._Go_HP = nil
		self._Go_Back = nil
		self._Go_Front = nil
		self._Go_ActionTip = nil
		--self._Frame_Title = nil
		--self._Frame_Guild = nil
		--self._Frame_CharName = nil
		self._Frame_ActionTip = nil
		self._Go_QuestTalk = nil
		self._Go_Talk = nil
		self._Frame_Guild_Flag = nil
		self._Img_Convoy = nil
	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _PlayerTopPateCache
--	end
	def.override("=>", "table", "number").GetCache = function (self)
		return _PlayerTopPateCache, 50
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Cha")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Go_GuildName = self:GetUIObject("Txt_Guild")
			self._Go_GuildIcon[1] = self:GetUIObject("Img_Guild_1")
			self._Go_GuildIcon[2] = self:GetUIObject("Img_Guild_2")
			self._Go_GuildIcon[3] = self:GetUIObject("Img_Guild_3")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			self._Go_TitleIcon = self:GetUIObject("Img_Title")
			--self._Frame_Title = self:GetUIObject("Frame_Title")
			--self._Frame_Guild = self:GetUIObject("Frame_Guild")
			self._Frame_Guild_Flag = self:GetUIObject("Frame_GuildFlag")
			self._Img_Convoy = self:GetUIObject("Img_Convoy")
			--self._Frame_CharName = self:GetUIObject("Frame_CharName")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Go_PkIcon = self:GetUIObject("Img_PK")
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_Back = self:GetUIObject("Img_Back")
			self._Go_Front = self:GetUIObject("Img_Front")
			self._Go_QuestTalk = self:GetUIObject("Img_QuestTalk")
			self._Go_Talk = self:GetUIObject("Lab_Talk")
			--self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)

			if self._Go_Name ~= nil then
					self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
			if self._Go_GuildName ~= nil then
					self._Txt_GuildName = self._Go_GuildName:GetComponent(ClassType.Text)
			end
			if self._Go_TitleName ~= nil then
					self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end
		end
	end

	def.method(CEntity,"function").Create = function (self, obj, cb)
		self._Owner = obj
		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 3)
		local pate = self:CreateFromCacheInternal(attachObj, _PlayerTopPateCache, _PlayerTopPatePrefab, offsetH, 1)

		self:UpdateName(true)

		if cb ~= nil then
			cb()
		end
	end

	def.override("number").OnHPChange = function (self, num)
		if self._PateObj ~= nil then
			local hpIndicator = self._Go_HP:GetComponent(ClassType.GBlood)
			hpIndicator:SetValue(num)
		end
	end

	--公会更改
	def.method("boolean", "table").OnGuildNameChange = function (self, isShow, guild)
	    if self._Go_GuildName ~= nil then
			--GUITools.SetUIActive(self._Frame_Guild, isShow)
			GUITools.SetUIActive(self._Go_GuildName, isShow)
			GameUtil.SetIgnoreLayout(self._Go_GuildName, not isShow)
			GUITools.SetUIActive(self._Frame_Guild_Flag, isShow)

			if isShow then
				-- GUI.SetText(self._Go_GuildName, tostring(RichTextTools.GetTopPateColorText("["..guild._GuildName.."]", 1))
				--GUI.SetTextAndChangeLayout(self._Go_GuildName, tostring("["..guild._GuildName.."]"), 200)

				if self._Txt_GuildName ~= nil then
					self._Txt_GuildName.text = "["..guild._GuildName.."]"
				end

				game._GuildMan:SetPlayerGuildIcon(guild._GuildIconInfo, self._Go_GuildIcon)
				-- 瑞龙需求：有公会，PK模式的图标显示在名称和公会中间。
				--self._TextHeight = 17 -- text的最小高度。
				-- warn("lidaming self._TextHeight ==", self._TextHeight)
				self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)
			else
				-- 瑞龙需求：没有公会，PK模式的图标显示在名称中间。
				--self._TextHeight = 0
				self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight/2, 0)
			end
		end
	end

	-- 护送更改
	def.method("number").OnGuildConvoyChange = function(self, index)
		local isShow = index > 1
		GUITools.SetUIActive(self._Img_Convoy, isShow)
		if isShow then
			GUITools.SetUIActive(self._Go_PkIcon, false)
			GUITools.SetGroupImg(self._Img_Convoy, index + 2)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._PateObj == nil or self._Owner == nil then return end
		if curType ~= EnumDef.EntityLogoType.None then
			if curType == EnumDef.EntityLogoType.Rescue then
				GUITools.SetUIActive(self._Go_PkIcon, true)
				GUITools.SetUIActive(self._Go_ActionTip, false)
				GUITools.SetGroupImg(self._Go_PkIcon, 1)
			else
				GUITools.SetGroupImg(self._Go_ActionTip, curType)
				GUITools.SetUIActive(self._Go_ActionTip, true)
				-- warn("lidaming curType ~= Rescue and PKMode ~= Massacre!!!!")
				GUITools.SetUIActive(self._Go_PkIcon, false)
			end			
		else			
			if self._Owner:GetPkMode() == EPkMode.EPkMode_Massacre then
				GUITools.SetUIActive(self._Go_PkIcon, true)
			end
			GUITools.SetUIActive(self._Go_ActionTip, false)
		end
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
	    if self._Go_TitleName ~= nil then
			if name == "" then
				isShow = false
			end

			--GUITools.SetUIActive(self._Frame_Title, isShow)
			GUITools.SetUIActive(self._Go_TitleIcon, isShow)
			if isShow then
				-- GUI.SetText(self._Go_TitleName, RichTextTools.GetTopPateColorText(name, 2) )
				--GUI.SetTextAndChangeLayout(self._Go_TitleName, tostring(name), 200)
				if self._Txt_TitleName ~= nil then
					self._Txt_TitleName.text = name
				end
			end
		end
	end

	def.override("boolean").UpdateName= function(self,isShow)
		if self._PateObj == nil then return end
		GUITools.SetUIActive(self._Go_Name, isShow)
		if isShow then
			local name = self._Owner:GetEntityColorName()
			if game._IsOpenDebugMode == true then
				local clientPosX, clientPosY, clientPosZ = self._Owner:GetPosXYZ()
				clientPosX = string.format("%.2f", clientPosX)
				clientPosY = string.format("%.2f", clientPosY)
				clientPosZ = string.format("%.2f", clientPosZ)		
				local clientPos = clientPosX .. "," .. clientPosY .. "," .. clientPosZ
				name = name .. self._Owner._ID .. ", CPos:".. clientPos
			end
			-- GUI.SetText(self._Go_Name, name )
			--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)
			if self._Txt_Name ~= nil then
				self._Txt_Name.text = name
			end
		end
	end

	def.method("boolean").SetAutoPathingState= function(self,isAutoPath)
		if self._PateObj == nil then return end
		
	    local autoPrefab = self._PateObj:FindChild("Prg_Find")
	    if(autoPrefab == nil) then return end

	    GUITools.SetUIActive(autoPrefab, isAutoPath)
	end

	def.method("boolean").SetPKIconIsShow = function (self,isShow)
		if self._Go_PkIcon ~= nil then
			-- 护送图标显示优先级高于PK模式
			if self._Img_Convoy.activeSelf then
				return
			end
			if self._Owner:CanRescue() and self._Owner:IsFriendly() then 
				GUITools.SetUIActive(self._Go_PkIcon, true)	
				GUITools.SetGroupImg(self._Go_PkIcon, 1)
			else
				GUITools.SetUIActive(self._Go_PkIcon, isShow)	
				-- 显示PK模式图标，并且是杀戮模式
				if isShow then
					GUITools.SetGroupImg(self._Go_PkIcon, 0)
				end
			end
		end
	end

	def.method("boolean","number").SetHPLineIsShow = function (self,isShow,curType)
		if self._Go_HP ~= nil then
			GUITools.SetUIActive(self._Go_HP, isShow)
			if curType ~= EnumDef.HPColorType.None then
				GUITools.SetGroupImg(self._Go_Back, curType)
				GUITools.SetGroupImg(self._Go_Front, curType)
			end
			if isShow then
				self:OnHPChange(self._Owner._InfoData._CurrentHp / self._Owner._InfoData._MaxHp)
			end
		end
	end

	def.override("boolean","string","number").TextPop = function (self,isShow,text,time)
		if self._PateObj == nil then return end

		if isShow then
			_G.RemoveGlobalTimer(self._TextPopTimerId)

			GUITools.SetUIActive(self._Frame_ActionTip, false)
			if time == 0 then
				time = 3
			end

			GUI.SetText(self._Go_Talk,text)
			--GUITools.SetTextAlignmentByLineHeight(self._Go_Talk,21)

			local ctext = self._Go_Talk:GetComponent(ClassType.Text)
			local line = ctext.preferredHeight / 21
			local width = 0
			if line > 1 then
				width = GUITools.GetUiSize(self._Go_Talk).Width
			else
				width = ctext.preferredWidth
			end
			GUITools.UIResize(self._Go_QuestTalk, width+20, ctext.preferredHeight+35)

			self._Go_QuestTalk:SetActive(true)
			GUITools.SetUIActive(self._Go_QuestTalk, true)

	        self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
	        	GUITools.SetUIActive(self._Go_QuestTalk, false)
	        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		    end)
		else
        	GUITools.SetUIActive(self._Go_QuestTalk, false)
        	GUITools.SetUIActive(self._Frame_ActionTip, true)
		end
	end

	CPlayerMirrorTopPate.Commit()
end

return 
{
	CPateBase = CPate,
	CNPCTopPate = CNPCTopPate,
	CPlayerTopPate = CPlayerTopPate,
	CItemTopPate = CItemTopPate,
	CPlayerMirrorTopPate = CPlayerMirrorTopPate,
}