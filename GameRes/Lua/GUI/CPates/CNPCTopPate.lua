local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode
local CPateBase = require "GUI.CPates.CPateBase"

local CNPCTopPate = Lplus.Extend(CPateBase, "CNPCTopPate")
do
	local def = CNPCTopPate.define
	
	def.field('userdata')._Go_Name = nil
--	def.field('userdata')._Frame_ActionTip = nil
--	def.field('userdata')._Frame_QuestTalk = nil
	def.field('userdata')._Go_ActionTip = nil
	def.field('userdata')._Go_TitleName = nil
	--def.field('userdata')._Frame_Title = nil
	def.field('userdata')._Go_HP = nil
	def.field('userdata')._Go_Back = nil
	def.field('userdata')._Go_Front = nil
	def.field('userdata')._Go_STA = nil
--	def.field('userdata')._Go_QuestTalk = nil
--	def.field('userdata')._Go_Talk = nil
	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_TitleName = nil

	def.field('userdata')._GB_HP = nil
	def.field('userdata')._GB_STA = nil

	def.field('boolean')._IsShowHP = true
	def.field('boolean')._IsShowSTA = false
	def.field('dynamic')._ODName = nil		--强制Name
	def.field('number')._TimerId = -1
	def.field('number')._CurTipType = -1
	def.field('number')._NextTipType  = -1
	--def.field('number')._TextPopTimerId = -1

	def.final("=>", CNPCTopPate).new = function ()
		local obj = CNPCTopPate()
		obj._VOffset = 2.5

		--local data=CPateBase.StaticData()
		--table.insert(data._AllCreated,obj)

		return obj
	end

--	def.method(CEntity,"function").Create = function (self, obj, cb)
--		self._Owner = obj
--		local attachObj, offsetH = self:GetPateAttachInfo(obj._GameObject, 2.5)
--		local pate = self:CreateFromCacheInternal(attachObj, _NPCPateCache, _NPCPatePrefab, offsetH, 1)
--		--self:UpdateName(true)
--		if cb ~= nil then cb() end
--	end 

	def.override().Release = function(self)

		_G.RemoveGlobalTimer(self._TimerId)
		--_G.RemoveGlobalTimer(self._TextPopTimerId)

		if self._GB_HP ~= nil then
			self._GB_HP:MakeInvalid()
		end

		if self._GB_STA ~= nil then
			self._GB_STA:MakeInvalid()
		end

		CPateBase.Release(self)

		--self._Go_Name = nil
		self._Frame_QuestTalk = nil
		self._Frame_ActionTip = nil
		self._Go_ActionTip = nil
		--self._Go_TitleName = nil
		--self._Frame_Title = nil
		self._Go_HP = nil
		self._Go_STA = nil
--		self._Go_QuestTalk = nil
--		self._Go_Talk = nil
		self._Go_Back = nil
		self._Go_Front = nil
		self._Txt_TitleName = nil
		self._Txt_Name = nil

		self._GB_HP = nil
		self._GB_STA = nil

		self._IsShowHP = true
		self._IsShowSTA = true
		self._ODName = nil		--强制Name
		self._TimerId = -1
		self._CurTipType = -1
		self._NextTipType  = -1

		--local data=CPateBase.StaticData()
		--table.remove(data._AllCreated,obj)

	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _NPCPateCache
--	end

	--returns a cache table, and its limit in count
	def.override("=>", "table", "number","userdata").GetGoCache = function (self)
		local data = CPateBase.StaticData()
		return data._NPCPateCache, 50, data._NPCPatePrefab
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Monster")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Frame_QuestTalk = self:GetUIObject("Frame_QuestTalk")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			--self._Frame_Title = self:GetUIObject("Frame_Title")
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_STA = self:GetUIObject("Prg_M_Head_Energy")
			
--			self._Go_QuestTalk = self:GetUIObject("Img_QuestTalk")
--			self._Go_Talk = self:GetUIObject("Lab_Talk")
			self._Go_Back = self:GetUIObject("Img_Back0")
			self._Go_Front = self:GetUIObject("Img_Front0")
		
			if self._Go_Name ~= nil then
				self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
			if 	self._Go_TitleName ~= nil then
				self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end

			if self._Go_HP ~= nil then
				self._GB_HP = self._Go_HP:GetComponent(ClassType.GBlood)
			end
			if self._Go_STA ~= nil then
				self._GB_STA = self._Go_STA:GetComponent(ClassType.GBlood)
			end
		end
	end

	def.override().UIReset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		GUITools.SetUIActive(self._Go_TitleName, false)
		GUITools.SetUIActive(self._Go_HP, false)
		GUITools.SetUIActive(self._Go_STA, false)
		--GUITools.SetUIActive(self._Go_QuestTalk, false)
	end

	local function SyncHPStyle(self, isShow,curType)
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

	def.method("boolean","number").SetHPLineIsShow = function (self,isShow,curType)
		if self._IsReleased then return end
		self._IsShowHP = isShow

		if self:IsObjCreated() then
			SyncHPStyle(self, isShow,curType)
		else
			self._Data._HPType = curType
		end
	end

	local function SyncSTAStyle(self, isShow)
		if self._PateObj == nil then return end
		GUITools.SetUIActive(self._Go_STA, isShow)
		if isShow then
			self:OnStaChange(self._Owner._InfoData._CurrentStamina / self._Owner._InfoData._MaxStamina)
		end
	end

	def.method("boolean").SetStaLineIsShow = function (self,isShow)
		if self._IsReleased then return end
		self._IsShowSTA = isShow
		if self:IsObjCreated() then
			SyncSTAStyle(self, isShow)
		end
	end

	local function SyncHP(self, num)
		if self._PateObj ~= nil then
			if self._IsShowHP then
				self._GB_HP:SetValue(num)
			end
		end
	end

	def.override("number").OnHPChange = function (self, num)
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncHP(self, num)
		else
			self._Data._HP = num
		end
	end

	local function SyncSTA(self, num)
		if self._PateObj ~= nil then
			if self._IsShowSTA then
				self._GB_STA:SetValue(num)
			end
		end
	end

	def.override("number").OnStaChange = function (self, num)
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncSTA(self, num)
		else
			self._Data._STA = num
		end
	end

	local function SyncLogo(self, curType)
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
	end

	def.override("number").OnLogoChange = function (self, curType)
		self._Owner._CurLogoType = curType
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncLogo(self, curType)
		end
	end

	local function SyncTitle(self, isShow, name)
	    if self._PateObj == nil then return end

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

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
	    if self._PateObj == nil then return end
		if name == "" then
			isShow=false
		end
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncTitle(self, isShow,name)
		else
			self._Data._TitleName = name
			self._Data._IsShowTitle = isShow
		end
	end

	local function SyncName(self, isShow)
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
				if self._ODName ~= nil then
					self._Txt_Name.text = self._ODName
				else
					self._Txt_Name.text = name
				end
				--warn("Monster UpdateName ", debug.traceback())
			end
		end
	end

	--更改名称
	def.override("boolean").UpdateName = function(self,isShow)
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncName(self, isShow)
		else
			self._Data._IsShowName = isShow
		end
	end
	
	--设置名称，暂时只用于宠物???
	def.override("string").SetName = function(self, name)
		if self._IsReleased then return end
		self._ODName = name
		if self:IsObjCreated() then
			if self._PateObj == nil then return end
			if self._Txt_Name ~= nil then
				self._Txt_Name.text = name
			end
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
		if self._PateObj == nil then return -1 end
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
		if self._IsReleased then return end
		if self:IsObjCreated() then
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
	end

	def.method().ActionTipHideTest = function (self)
		if self._IsReleased then return end
		if self:IsObjCreated() then
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
	end

--	def.override("boolean","string","number").TextPop = function (self,isShow,text,time)
--		if self._PateObj == nil then return end

--    	--GUITools.SetUIActive(self._Go_QuestTalk, isShow)
--		if isShow then
--			_G.RemoveGlobalTimer(self._TextPopTimerId)

--    		GUITools.SetUIActive(self._Frame_ActionTip, false)
--			if time == 0 then
--				time = 3
--			end

--			GUI.SetText(self._Go_Talk,text)

--			local ctext = self._Go_Talk:GetComponent(ClassType.Text)
--			local line = ctext.preferredHeight / 21
--			local width = 0
--			if line > 1 then
--				width = GUITools.GetUiSize(self._Go_Talk).Width
--			else
--				width = ctext.preferredWidth
--			end
--			GUITools.UIResize(self._Go_QuestTalk, width+20, ctext.preferredHeight+35)

--			self._Go_QuestTalk:SetActive(true)
--			GUITools.SetUIActive(self._Go_QuestTalk, true)

--	        self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
--	        	GUITools.SetUIActive(self._Go_QuestTalk, false)
--	        	GUITools.SetUIActive(self._Frame_ActionTip, true)
--		    end)
--		else
--        	GUITools.SetUIActive(self._Go_QuestTalk, false)
--        	GUITools.SetUIActive(self._Frame_ActionTip, true)
--		end
--	end

	def.override().SyncDataToUI = function (self)
		if not self._IsReleased and self:IsObjCreated() then
			if self._Data._HPType ~= nil then
				SyncHPStyle(self, self._IsShowHP, self._Data._HPType)
				self._Data._HPType = nil
			end
			if self._Data._HP ~= nil then
				SyncHP(self, self._Data._HP)
				self._Data._HP = nil
			end
			SyncSTAStyle(self, self._IsShowSTA)

			if self._Data._STA ~= nil then
				SyncSTA(self, self._Data._STA)
				self._Data._STA = nil
			end

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

	CNPCTopPate.Commit()
end
return CNPCTopPate
