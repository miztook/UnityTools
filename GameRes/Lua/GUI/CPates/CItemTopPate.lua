local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode
local CPateBase = require "GUI.CPates.CPateBase"

local CItemTopPate = Lplus.Extend(CPateBase, "CItemTopPate")
do
	local def = CItemTopPate.define
		
    local CONST_CACHE_AMOUNT = 50

	def.field('userdata')._Go_Name = nil
	--def.field('userdata')._Frame_ActionTip = nil
	def.field('userdata')._Go_ActionTip = nil
	def.field('userdata')._Go_TitleName = nil
	--def.field('userdata')._Frame_Title = nil
	def.field('userdata')._Txt_TitleName = nil
	def.field('userdata')._Txt_Name = nil

	def.final("=>", CItemTopPate).new = function ()
        local cache, limit = CItemTopPate.GetPateCache()
        local obj = CPateBase.CreateNewInternal("GUI.CPates.CItemTopPate", cache, limit) --CItemTopPate()
        --obj._VOffset = 2.5
		--local data=CPateBase.StaticData()
		--table.insert(data._AllCreated,obj)

--        if obj._Data ~= nil then
--			obj._Data._LogoType = nil
--			obj._Data._TitleName = nil
--			obj._Data._IsShowTitle = nil
--			obj._Data._IsShowName = nil
--        end

		return obj
	end

	def.method().Pool = function (self)

		self._Go_Name = nil
		self._Frame_ActionTip = nil
		self._Go_ActionTip = nil
		self._Go_TitleName = nil
		--self._Frame_Title = nil
		self._Txt_TitleName = nil
		self._Txt_Name = nil

		--local data=CPateBase.StaticData()
		--table.remove(data._AllCreated,obj)

        local cache, limit = CItemTopPate.GetPateCache()
        CPateBase.PoolInternal(self, cache, limit) --CNPCTopPate()
	end

	def.override().UIReset = function(self)
		GUITools.SetUIActive(self._Go_Name, false)
		GUITools.SetUIActive(self._Go_TitleName, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		GUITools.SetUIActive(self._Go_ActionTip, false)
	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _ItemTopCache
--	end
	def.static("=>", "table", "number").GetPateCache = function ()
		local data = CPateBase.StaticData()
		return data._ItemPateCache, CONST_CACHE_AMOUNT
	end

	def.override("=>", "table", "number", "userdata").GetGoCache = function (self)
		local data = CPateBase.StaticData()
		return data._ItemPateGOCache, CONST_CACHE_AMOUNT, data._ItemPatePrefab
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

--	def.method(CEntity,"function").Create = function (self, obj, cb)
--		self._Owner = obj
--		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 2.5)
--		local pate = self:CreateFromCacheInternal(attachObj, _ItemTopCache, _ItemPatePrefab, offsetH, 1)
--		self:UpdateName(true)
--		if cb ~= nil then cb() end
--	end

	local function SyncLogo(self, curType)
		if self._PateObj == nil or self._Owner == nil then return end
		if curType ~= EnumDef.EntityLogoType.None then
			local CElementSkill = require "Data.CElementSkill"
			GUITools.SetUIActive(self._Go_ActionTip, true)			   
			-- warn("lidaming icon name ==".. CElementSkill.Get(self._Owner._MineralTemplate.SkillId).IconName)			
			GUITools.SetIcon(self._Go_ActionTip, CElementSkill.Get(self._Owner._MineralTemplate.SkillId).IconName)
		else
			GUITools.SetUIActive(self._Go_ActionTip, false)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		self._Owner._CurLogoType = curType
		if self._IsPooled then return end
		if self:IsObjCreated() then
			SyncLogo(self, curType)
		end
	end

	local function SyncTitle(self, isShow, name)
	    if self._Go_TitleName ~= nil then
			--GUITools.SetUIActive(self._Frame_Title, isShow)
			GUITools.SetUIActive(self._Go_TitleName, isShow)
			if isShow then
				if self._Txt_TitleName ~= nil then
					--GUI.SetTextAndChangeLayout(self._Go_TitleName, tostring("["..name.."]"), 200)
					self._Txt_TitleName.text = "["..name.."]"
				end
			end
		end
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
	    if self._Go_TitleName ~= nil then
			--GUITools.SetUIActive(self._Frame_Title, isShow)
			if name == "" then
				isShow = false
			end

			if self._IsPooled then return end
			if self:IsObjCreated() then
				SyncTitle(self, isShow,name)
			else
				self._Data._TitleName = name
				self._Data._IsShowTitle = isShow
			end
		end
	end

	local function SyncName(self, isShow)
		if self._PateObj == nil then return end

		if not self._Owner and not game._IsOpenDebugMode then
			isShow = false
		end

		local name = ""	
		if isShow then	
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
		end

		GUITools.SetUIActive(self._Go_Name, isShow)
		if isShow then
			if self._Txt_Name ~= nil then
				self._Txt_Name.text = name
			end
		end
	end

	def.override("boolean").UpdateName= function(self, isShow)
		if self._IsPooled then return end
		if self:IsObjCreated() then
			SyncName(self, isShow)
		else
			self._Data._IsShowName = isShow
		end
	end

	def.override().SyncDataToUI = function (self)
		if not self._IsPooled and self:IsObjCreated() then

			if self._Data._LogoType ~= nil then
				SyncLogo(self, self._Data._LogoType)
				self._Data._LogoType = nil
			end
			if self._Data._TitleName ~= nil and self._Data._IsShowTitle ~= nil then
				SyncTitle(self, self._Data._IsShowTitle, self._Data._TitleName)
				self._Data._TitleName = nil
				self._Data._IsShowTitle = nil
			end
			if self._Data._IsShowName ~= nil then
				SyncName(self, self._Data._IsShowName)
				self._Data._IsShowName = nil
			end

		end
	end


	CItemTopPate.Commit()
end
return CItemTopPate