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
	--def.field('userdata')._Go_AutoPathIcon = nil

	--def.field('userdata')._Frame_Title = nil
	--def.field("userdata")._Frame_Guild = nil
	def.field("userdata")._Img_Convoy = nil
	--def.field('userdata')._Frame_CharName = nil
--	def.field('userdata')._Frame_ActionTip = nil
--	def.field('userdata')._Frame_QuestTalk = nil
	--def.field('userdata')._Go_QuestTalk = nil
	--def.field('userdata')._Go_Talk = nil
	def.field('userdata')._Frame_Guild_Flag = nil

	def.field('userdata')._GB_HP = nil
	def.field('userdata')._Txt_Name = nil
	def.field('userdata')._Txt_GuildName = nil
	def.field('userdata')._Txt_TitleName = nil

	--Mem
	def.field('boolean')._IsShowHP = true
	--def.field('number')._HPType = -1
	--def.field('number')._GuildConvoyId = 0
	def.field('number')._LogoType = -1
	def.field('boolean')._IsMirrorPlayer = false
	def.field('number')._TextHeight = 18

	def.final("=>", CPlayerTopPate).new = function ()
		local obj = CPlayerTopPate()

		local data=CPateBase.StaticData()

		--table.insert(data._AllCreated,obj)

		return obj
	end

	def.override().Release = function(self)
		--_G.RemoveGlobalTimer(self._TextPopTimerId)

		if self._GB_HP ~= nil then
			self._GB_HP:MakeInvalid()
		end

		CPateBase.Release(self)

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
		--self._Go_AutoPathIcon = nil

		self._Img_Convoy = nil
		self._Frame_QuestTalk = nil
		self._Frame_ActionTip = nil
		--self._Go_QuestTalk = nil
		--self._Go_Talk = nil
		self._Frame_Guild_Flag = nil

		self._GB_HP = nil
		self._Txt_Name = nil
		self._Txt_GuildName = nil
		self._Txt_TitleName = nil

		--self._HPType = -1
		self._IsShowHP = false
		--self._GuildConvoyId = 0
		self._LogoType = 0
		self._IsMirrorPlayer = false
		self._TextHeight = 18

		--local data=CPateBase.StaticData()
		--table.remove(data._AllCreated,obj)

	end

--	def.override("=>", "userdata").GetCacheRoot = function (self)
--		return _PlayerTopPateCache
--	end

	def.override("=>", "table", "number", "userdata").GetGoCache = function (self)
		local data = CPateBase.StaticData()
		return data._PlayerTopPateCache, 50, data._PlayerTopPatePrefab
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
			--self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)
			self._Go_HP = self:GetUIObject("Prg_M_Head_Hp")
			self._Go_Back = self:GetUIObject("Img_Back")
			self._Go_Front = self:GetUIObject("Img_Front")
			self._Go_ActionTip = self:GetUIObject("Img_Inf")
			--self._Go_AutoPathIcon = self:GetUIObject("Frame_AutoPath")

			--self._Frame_Title = self:GetUIObject("Frame_Title")
			--self._Frame_Guild = self:GetUIObject("Frame_Guild")
			self._Img_Convoy = self:GetUIObject("Img_Convoy")
			--self._Frame_CharName = self:GetUIObject("Frame_CharName")
			self._Frame_ActionTip = self:GetUIObject("Frame_Inf")
			self._Frame_QuestTalk = self:GetUIObject("Frame_QuestTalk")
			--self._Go_QuestTalk = self:GetUIObject("Img_QuestTalk")
			--self._Go_Talk = self:GetUIObject("Lab_Talk")
			self._Frame_Guild_Flag = self:GetUIObject("Frame_GuildFlag")

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

		end
	end

	def.override().UIReset = function(self)
		GUITools.SetUIActive(self._Go_ActionTip, false)
		--GUITools.SetUIActive(self._Frame_Title, false)
		--GUITools.SetUIActive(self._Frame_Guild, false)
		GUITools.SetUIActive(self._Go_TitleIcon, false)
		GUITools.SetUIActive(self._Go_GuildName, false)
		GameUtil.SetIgnoreLayout(self._Go_GuildName, false)
		GUITools.SetUIActive(self._Frame_Guild_Flag, false)
		GUITools.SetUIActive(self._Go_PkIcon, false)
		GUITools.SetUIActive(self._Go_HP, false)
		--GUITools.SetUIActive(self._Go_QuestTalk, false)
		--self._Go_QuestTalk:SetActive(false)
		GUITools.SetUIActive(self._Img_Convoy, false)
	end
	--

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
		if self._IsReleased then return end
		self._IsShowHP = isShow

		if self:IsObjCreated() then
			SyncHPStyle(self, isShow,curType)
		else
			self._Data._HPType = curType
		end	
	end

	local function SyncHP(self, num)
		if self._PateObj ~= nil then
			--self._GB_HP = self._Go_HP:GetComponent(ClassType.GBlood)

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
			self._Data.HP = num
		end
	end

	local function SyncGuild(self, isShow, guild_name, guild_icon)
	    if self._Go_GuildName ~= nil then
			--GUITools.SetUIActive(self._Frame_Guild, isShow)
			GUITools.SetUIActive(self._Go_GuildName, isShow)
			GameUtil.SetIgnoreLayout(self._Go_GuildName, not isShow)
			GUITools.SetUIActive(self._Frame_Guild_Flag, isShow)

			if isShow then
				-- GUI.SetText(self._Go_GuildName, tostring(RichTextTools.GetTopPateColorText("["..guild._GuildName.."]", 1))
				--GUI.SetTextAndChangeLayout(self._Go_GuildName, tostring("["..guild._GuildName.."]"), 200)
				if self._Txt_GuildName ~= nil then
					self._Txt_GuildName.text = "["..guild_name.."]"
				end

				game._GuildMan:SetPlayerGuildIcon(guild_icon, self._Go_GuildIcon)
				-- 瑞龙需求：有公会，PK模式的图标显示在名称和公会中间。
				--self._TextHeight = 34 -- text的最小高度。
				-- warn("lidaming self._TextHeight ==", self._TextHeight)
				--self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight, 0)
			else
				-- 瑞龙需求：没有公会，PK模式的图标显示在名称中间。
				--self._TextHeight = 17
				--self._Go_PkIcon.localPosition = Vector3.New(self._Go_PkIcon.localPosition.x, self._TextHeight/2, 0)
			end
		end
	end

	--公会更改
	def.method("boolean", "table").OnGuildNameChange = function (self, isShow, guild)
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncGuild(self, isShow, guild._GuildName, guild._GuildIconInfo)
		else
			self._Data._IsShowGuild = isShow
			self._Data._GuildName = guild._GuildName
			self._Data._GuildIconInfo = guild._GuildIconInfo
		end
	end

--	local function SyncGuildConvoy(self)
--		warn("SyncGuildConvoy "..self._GuildConvoyId, debug.traceback())
--		local isShow = self._GuildConvoyId > 1
--		GUITools.SetUIActive(self._Img_Convoy, isShow)
--		if isShow then
--			GUITools.SetUIActive(self._Go_PkIcon, false)
--			GUITools.SetGroupImg(self._Img_Convoy, self._GuildConvoyId + 2)
--		end
--	end

--	-- 护送更改
--	def.method("number").OnGuildConvoyChange = function(self, index)
--		if self._IsReleased then return end
--		self._GuildConvoyId = index
--		if self:IsObjCreated() then
--			SyncGuildConvoy(self)
--		end
--	end

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
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncPK(self)
		end
	end

	local function SyncLogo(self)
		if self._PateObj == nil then return end
		if self._LogoType ~= EnumDef.EntityLogoType.None or self._LogoType == EnumDef.EntityLogoType.Rescue then
			GUITools.SetUIActive(self._Go_ActionTip, false)
		else
			--GUITools.SetGroupImg(self._Go_ActionTip, self._LogoType)
			GUITools.SetUIActive(self._Go_ActionTip, true)
		end
	end

	def.override("number").OnLogoChange = function (self, curType)
		if self._IsReleased then return end
		self._LogoType = curType
		if self:IsObjCreated() then
			SyncLogo(self)
			SyncPK(self)
		end
	end

	local function SyncTitle(self, isShow, name)
	    if self._Go_TitleName ~= nil then
			--GUITools.SetUIActive(self._Frame_Title, isShow)
			GUITools.SetUIActive(self._Go_TitleIcon, isShow)
			--GUITools.SetUIActive(self._Go_TitleName, isShow)
			--if not IsNil(self._Go_TitleIcon) then
			if isShow then
				if not self._IsMirrorPlayer then
					local Designation = game._DesignationMan:GetDesignationDataByID(self._Owner:GetDesignationId())    -- game._DesignationMan:GetCurDesignation()
					if Designation ~= nil then
						GUITools.SetGroupImg(self._Go_TitleIcon, Designation.Quality)
					end
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

	def.override("boolean","string").OnTitleNameChange = function (self, isShow, name)
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
				name = name .. self._Owner._ID .. ", CPos:".. clientPos
			end
			-- GUI.SetText(self._Go_Name, name )
			--GUI.SetTextAndChangeLayout(self._Go_Name, tostring(name), 200)
			if self._Txt_Name ~=nil then
				self._Txt_Name.text = name
			end
		end
	end

	def.override("boolean").UpdateName= function(self, isShow)
		if self._IsReleased then return end
		if self:IsObjCreated() then
			SyncName(self, isShow)
		else
			self._Data._IsShowName = isShow
		end
	end

----???
--	local function SyncAutoPath(self, isShow)
--	    --local autoPrefab = self._PateObj: FindChild("Prg_Find")
--	    if(self._Go_AutoPathIcon ~= nil) then
--			GUITools.SetUIActive(self._Go_AutoPathIcon, isAutoPath)
--		end
--	end

--	def.method("boolean").SetAutoPathingState= function(self, isAutoPath)
--		if self._IsReleased then return end
--		if self:IsObjCreated() then
--			SyncAutoPath(self, isAutoPath)
--		else
--			self._Data._IsAutoPath = isShow
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
			if self._Data.isShow ~= nil and  self._Data._GuildName ~= nil and  self._Data._GuildIconInfo ~= nil then
				SyncGuild(self, self._Data._IsShowGuild, self._Data._GuildName, self._Data._GuildIconInfo)
				self._Data._IsShowGuild = nil
				self._Data._GuildName = nil
				self._Data._GuildIconInfo = nil
			end

			--SyncGuildConvoy(self)

--			if self._Data._LogoType ~= nil then
--				SyncLogo(self, self._Data._LogoType)
--				self._Data._LogoType = nil
--			end
--			if self._Data._IsPK ~= nil then
--				SyncPK(self, self._Data._IsPK)
--				self._Data._IsPK = nil
--			end

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
--			if self._Data._IsAutoPath ~= nil then
--				SyncAutoPath(self, self._Data._IsAutoPath)
--				self._Data._IsAutoPath = nil 
--			end
		end
	end

	CPlayerTopPate.Commit()
end
return CPlayerTopPate