local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode
local CPateBase = require "GUI.CPates.CPateBase"

local CPlayerTopPate = Lplus.Extend(CPateBase, "CPlayerTopPate")
do
	local def = CPlayerTopPate.define

    local CONST_CACHE_AMOUNT = 200

	--UI Elems
	def.field('userdata')._Go_Name = nil
	def.field('userdata')._Go_GuildName = nil
	def.field("table")._Go_GuildIcon = nil
	def.field('userdata')._Go_TitleName = nil
	def.field('userdata')._Go_TitleIcon = nil
	def.field('userdata')._Go_PkIcon = nil
	def.field('userdata')._Go_HP = nil
	def.field('userdata')._Go_Back = nil
	def.field('userdata')._Go_Front = nil
	def.field('userdata')._Go_ActionTip = nil
	def.field("userdata")._Img_Convoy = nil
	def.field('userdata')._Frame_Guild_Flag = nil

	def.field('userdata')._GB_HP = nil
	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_GuildName = nil
	def.field('userdata')._Txt_TitleName = nil

	--Mem
	def.field('boolean')._IsShowHP = true
	def.field('number')._LogoType = -1
	def.field('boolean')._IsMirrorPlayer = false
	def.field('number')._TextHeight = 18

    def.field('boolean')._IsMini = false
	def.field('userdata')._Go_Frame_Normal = nil
	def.field('userdata')._Go_Frame_Mini = nil
	def.field('userdata')._Txt_TitleName_m = nil


	def.final("=>", CPlayerTopPate).new = function ()
        local cache, limit = CPlayerTopPate.GetPateCache()
		local obj = CPateBase.CreateNewInternal("GUI.CPates.CPlayerTopPate", cache, limit) --CNPCTopPate()
	    obj._IsShowHP = true
	    obj._LogoType = -1
	    obj._IsMirrorPlayer = false
	    obj._TextHeight = 18
        --obj._IsMini = false

		return obj
	end

	def.method().Pool = function (self)
        --self:SetMini(false)

		if not IsNil(self._GB_HP) then
			self._GB_HP:MakeInvalid()
		end

		self._Go_Name = nil
		self._Go_GuildName = nil
		self._Go_GuildIcon = nil
		self._Go_TitleName = nil
		self._Go_TitleIcon = nil
		self._Go_PkIcon = nil
		self._Go_HP = nil
		self._Go_Back = nil
		self._Go_Front = nil
		self._Go_ActionTip = nil

		self._Img_Convoy = nil
		self._Frame_QuestTalk = nil
		self._Frame_ActionTip = nil
		self._Frame_Guild_Flag = nil

		self._GB_HP = nil
		self._Txt_Name = nil
		self._Txt_GuildName = nil
		self._Txt_TitleName = nil

        self._Go_Frame_Normal = nil
        self._Go_Frame_Mini = nil
        self._Txt_TitleName_m = nil

        local cache, limit = CPlayerTopPate.GetPateCache()
        CPateBase.PoolInternal(self, cache, limit) --CPlayerTopPate()
	end

--	def.static("number").SetCacheAmount = function (num)
--        CONST_CACHE_AMOUNT = num
--	end

	def.static("=>", "table", "number").GetPateCache = function ()
		local data = CPateBase.StaticData()
		return data._PlayerPateCache, CONST_CACHE_AMOUNT
	end

	def.override("=>", "table", "number", "userdata").GetGoCache = function (self)
		local data = CPateBase.StaticData()
		return data._PlayerPateGOCache, CONST_CACHE_AMOUNT, data._PlayerPatePrefab
	end

	def.override().UIFind = function(self)
		if self._UIObjectName2IdMap == nil then
			self._UIObjectName2IdMap = require("GUI.ObjectCfg.Panel_M_Head_Cha")

			self._Go_Name = self:GetUIObject("Txt_CharName")
			self._Go_GuildName = self:GetUIObject("Txt_Guild")
			self._Go_GuildIcon = {}
			self._Go_GuildIcon[1] = self:GetUIObject("Img_Guild_1")
			self._Go_GuildIcon[2] = self:GetUIObject("Img_Guild_2")
			self._Go_GuildIcon[3] = self:GetUIObject("Img_Guild_3")
			self._Go_TitleName = self:GetUIObject("Txt_Title")
			self._Go_TitleIcon = self:GetUIObject("Img_Title")
			self._Go_PkIcon = self:GetUIObject("Img_PK")
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_Back = self:GetUIObject("Img_Back")
			self._Go_Front = self:GetUIObject("Img_Front")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			self._Img_Convoy = self:GetUIObject("Img_Convoy")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Frame_QuestTalk = self:GetUIObject("Frame_QuestTalk")
			self._Frame_Guild_Flag = self:GetUIObject("Frame_GuildFlag")

            self._Go_Frame_Normal = self:GetUIObject("Frame_Normal")
            self._Go_Frame_Mini = self:GetUIObject("Frame_Mini")
            

			if self._Go_HP ~= nil then
				self._GB_HP = self._Go_HP:GetComponent(ClassType.GBlood)
			end
			if self._Go_Name ~= nil then
				self._Txt_Name = self._Go_Name:GetComponent(ClassType.Text)
			end
			if self._Go_GuildName ~= nil then
				self._Txt_GuildName = self._Go_GuildName:GetComponent(ClassType.Text)
			end
			if self._Go_TitleName ~= nil then
				self._Txt_TitleName = self._Go_TitleName:GetComponent(ClassType.Text)
			end
            
            if self._Go_Frame_Normal ~= nil and self._Go_Frame_Mini ~= nil then
                self._IsMini = not self._Go_Frame_Normal.activeSelf
                self._Go_Frame_Mini:SetActive(self._IsMini)
            end

            local txt_name_m = self:GetUIObject("Txt_CharName_m")
			if txt_name_m ~= nil then
				self._Txt_TitleName_m = txt_name_m:GetComponent(ClassType.Text)
			end
		end
	end

	def.override().UIReset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		GUITools.SetUIActive(self._Go_TitleIcon, false)
		GUITools.SetUIActive(self._Go_GuildName, false)
		GameUtil.SetIgnoreLayout(self._Go_GuildName, false)
		GUITools.SetUIActive(self._Frame_Guild_Flag, false)
		GUITools.SetUIActive(self._Go_PkIcon, false)
		GUITools.SetUIActive(self._Go_HP, false)
		GUITools.SetUIActive(self._Img_Convoy, false)
	end

	local function SyncHPStyle(self, isShow,curType)
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

	def.method("boolean","number").SetHPLineIsShow = function (self, isShow, curType)
		if self._IsPooled then return end
		self._IsShowHP = isShow

		if self:IsObjCreated() then
			SyncHPStyle(self, isShow, curType)
		else
			self._Data._HPType = curType
		end	
	end

	local function SyncHP(self, hp, guard)
		if self._PateObj ~= nil then
			if self._IsShowHP and self._GB_HP then
                if guard == nil then guard = 0 end
                if hp == nil then hp = 0 end
                local hp_rate, gd_rate = self:CalcHpGuard(hp, guard)
                self._GB_HP:SetValue(hp_rate)
                self._GB_HP:SetGuardValue(gd_rate)
            end
		end
	end

	def.override("number").OnHPChange = function (self, hp)
		if self._IsPooled or self._Owner == nil then return end
        local guard = 0
        if self._Owner ~= nil and self._Owner._InfoData ~= nil then
            guard  = self._Owner._InfoData._CurShield / self._Owner._InfoData._MaxHp
        end

		if self:IsObjCreated() then
			SyncHP(self, hp, guard)
		else
			self._Data._HP = hp
			self._Data._GuardP = guard
		end
	end

	local function SyncGuild(self, isShow, guild_name, guild_icon)
	    if self._Go_GuildName ~= nil then
			GUITools.SetUIActive(self._Go_GuildName, isShow)
			GameUtil.SetIgnoreLayout(self._Go_GuildName, not isShow)
			GUITools.SetUIActive(self._Frame_Guild_Flag, isShow)

			if isShow then
				if self._Txt_GuildName ~= nil then
					self._Txt_GuildName.text = "["..guild_name.."]"
				end

				game._GuildMan:SetPlayerGuildIcon(guild_icon, self._Go_GuildIcon)
			end
		end
	end

	--公会更改
	def.method("boolean", "table").OnGuildNameChange = function (self, isShow, guild)
		if self._IsPooled then return end
		if self:IsObjCreated() then
			SyncGuild(self, isShow, guild._GuildName, guild._GuildIconInfo)
		else
			self._Data._IsShowGuild = isShow
			self._Data._GuildName = guild._GuildName
			self._Data._GuildIconInfo = guild._GuildIconInfo
		end
	end

	local function SyncPK(self)
		if self._PateObj == nil or self._Owner == nil then return end
		if self._LogoType == EnumDef.EntityLogoType.None then
			local is_show = false
			if not self._IsMirrorPlayer then
				is_show=self._Owner:GetPkMode() == EPkMode.EPkMode_Massacre
			end
			GUITools.SetUIActive(self._Go_PkIcon, is_show)
			if is_show then
				GUITools.SetGroupImg(self._Go_PkIcon, 0)
			end
		elseif self._LogoType == EnumDef.EntityLogoType.Rescue then
			GUITools.SetUIActive(self._Go_PkIcon, true)
			GUITools.SetGroupImg(self._Go_PkIcon, 1)
		else
			GUITools.SetUIActive(self._Go_PkIcon, false)
		end
	end

	def.method().SetPKIconIsShow = function (self)
		if self._IsPooled then return end
		if self:IsObjCreated() then
			SyncPK(self)
		end
	end

	local function SyncLogo(self)
		if self._PateObj == nil then return end
		if self._LogoType ~= EnumDef.EntityLogoType.None or self._LogoType == EnumDef.EntityLogoType.Rescue then
			GUITools.SetUIActive(self._Go_ActionTip, false)
		else
			GUITools.SetUIActive(self._Go_ActionTip, true)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._IsPooled then return end
		self._LogoType = curType
		if self:IsObjCreated() then
			SyncLogo(self)
			SyncPK(self)
		end
	end

	local function SyncTitle(self, isShow, name)
	    if self._Go_TitleName ~= nil then
			GUITools.SetUIActive(self._Go_TitleIcon, isShow)
			if isShow then
				local Designation = game._DesignationMan:GetDesignationDataByID(self._Owner:GetDesignationId())    -- game._DesignationMan:GetCurDesignation()
				if Designation ~= nil and Designation.IconPath ~= "" then
					-- GUITools.SetGroupImg(self._Go_TitleIcon, Designation.Quality)
					GUITools.SetSprite(self._Go_TitleIcon, Designation.IconPath)
					if self._Txt_TitleName ~= nil then
						self._Txt_TitleName.text = name
					end
				else
					GUITools.SetUIActive(self._Go_TitleIcon, false)
				end
			end
		end
	end

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
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
				name = name .. self._Owner._ID .. ", CPos:".. clientPos
			end

            		if not self:IsMini() then
				if self._Txt_Name ~= nil then
					self._Txt_Name.text = name
                		end
            		else
                		if self._Txt_TitleName_m ~= nil then
                    			self._Txt_TitleName_m.text = name
				end
            		end
		end
	end

	def.override("boolean").UpdateName = function(self, isShow)
		if self._IsPooled then return end
		if self:IsObjCreated() then
			SyncName(self, isShow)
		else
			self._Data._IsShowName = isShow
		end
	end

	def.override().SyncDataToUI = function (self)
		if not self._IsPooled and self:IsObjCreated() then
			if self._Data._HPType ~= nil then
				SyncHPStyle(self, self._IsShowHP, self._Data._HPType)
				self._Data._HPType = nil
			end
			if self._Data._HP ~= nil then
				SyncHP(self, self._Data._HP, self._Data._GuardP)
				self._Data._HP = nil
                self._Data._GuardP = nil
			end
			if self._Data.isShow ~= nil and  self._Data._GuildName ~= nil and  self._Data._GuildIconInfo ~= nil then
				SyncGuild(self, self._Data._IsShowGuild, self._Data._GuildName, self._Data._GuildIconInfo)
				self._Data._IsShowGuild = nil
				self._Data._GuildName = nil
				self._Data._GuildIconInfo = nil
			end

			SyncLogo(self)
			SyncPK(self)

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

    def.method("boolean").SetMini = function(self, flag)
        if self._IsMini ~= flag then
            self._IsMini = flag
            if self._Go_Frame_Normal ~= nil then
                self._Go_Frame_Normal:SetActive(not self._IsMini)
            end
            if self._Go_Frame_Mini ~= nil then
                self._Go_Frame_Mini:SetActive(self._IsMini)
            end
        end
    end

    def.override("=>", "boolean").IsMini = function(self)
        return self._IsMini
    end

	CPlayerTopPate.Commit()
end
return CPlayerTopPate