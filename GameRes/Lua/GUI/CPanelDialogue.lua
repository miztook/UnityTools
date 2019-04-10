local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local DynamicText = require "Utility.DynamicText"
local CUIModel = require "GUI.CUIModel"
local CElementData = require "Data.CElementData"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"

local CPanelDialogue = Lplus.Extend(CPanelBase, 'CPanelDialogue')
local def = CPanelDialogue.define

def.field('userdata')._Img_NameLeft = nil
def.field('userdata')._Img_NameRight = nil
def.field('userdata')._Lab_NameLeft = nil
def.field('userdata')._Lab_NameRight = nil
def.field('userdata')._Lab_NPCTalk = nil
def.field(CUIModel)._NPCUIModelLeft = nil
def.field(CUIModel)._NPCUIModelRight = nil
def.field('userdata')._Model_NPCTalkLeft = nil
def.field('userdata')._Model_NPCTalkRight = nil
def.field('number')._Sentence_Timer_Id = 0
def.field('number')._Current_Sentence_Index = 0
def.field('table')._Current_Dialogue_Template = nil
--def.field('userdata')._Img_Shadow = nil
def.field('userdata')._Frame_NpcDialogue = nil
def.field("userdata")._ImgNext = nil
def.field("userdata")._ImgFinish = nil
def.field("userdata")._LabGetQuest = nil
def.field("number")._DialogueType = 0
def.field("boolean")._IsCameraChange = false
def.field("boolean")._IsAutoProvide = false
def.field("boolean")._IsAutoDeliver = false
def.field("boolean")._IsAutoConversation = false
def.field("table")._Model = nil
def.field("number")._LeftNpcID = -1
def.field("number")._RightNpcID = -1

--def.field("boolean")._InSceneCamFX = false

local DialogueType =
{
	DialogueOnly = 0,
	Provide = 1,
	Deliver = 2,
}

local instance = nil

def.static('=>', CPanelDialogue).Instance = function()
	if not instance then
		instance = CPanelDialogue()
		instance._PrefabPath = PATH.UI_SceneDialogue
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = false

		instance:SetupSortingParam()

	end
	return instance
end

def.override().OnCreate = function(self)
	--self._Img_Shadow = self:GetUIObject("Img_Shadow")
	-- self._Img_Shadow:SetActive(false)

	self._Frame_NpcDialogue = self:GetUIObject("Frame_NpcDialogue")
	self._Frame_NpcDialogue:SetActive(true)

	self._Img_NameLeft = self:GetUIObject("Img_NameLeft")
	self._Img_NameRight = self:GetUIObject("Img_NameRight")
	self._Lab_NameLeft = self:GetUIObject("Lab_NameLeft")
	self._Lab_NameRight = self:GetUIObject("Lab_NameRight")
	self._Lab_NPCTalk = self:GetUIObject("Lab_NPCTalk")
	self._Model_NPCTalkLeft = self:GetUIObject("Model_NPCTalkLeft")
	self._Model_NPCTalkRight = self:GetUIObject("Model_NPCTalkRight")
	self._ImgNext = self:GetUIObject("Img_Next")
	self._ImgFinish = self:GetUIObject("Img_Finish")
	self._LabGetQuest = self:GetUIObject("Lab_GetQuest")

	GUITools.RegisterImageModelEventHandler(self._Panel, self._Model_NPCTalkLeft)
	GUITools.RegisterImageModelEventHandler(self._Panel, self._Model_NPCTalkRight)

end

local function OnSkip()
	if instance._Model ~= nil and instance._Model.on_close ~= nil then
		local onClose = instance._Model.on_close
		if onClose ~= nil then
			onClose()
		end
		if instance._Model ~= nil then
			-- 回调中可能会将_Model置空
			instance._Model.on_close = nil
		end
	end
	game._GUIMan:Close("CPanelDialogue")
end

def.override('dynamic').OnData = function(self, data)
	if data == nil then
		warn("the data of CPanelDialogue is nil.")
		return
	end

	self._Model = data

	if data.dialogue_id == nil or data.dialogue_id <= 0 then
		warn("the dialogue_id is not illegal.")
		return
	end

	-- warn("dialog id "..data.dialogue_id)

	if data.is_provide ~= nil then
		if data.is_provide then
			self._DialogueType = DialogueType.Provide
			self._IsAutoProvide = data.is_autoProvide
		else
			self._DialogueType = DialogueType.Deliver
			self._IsAutoDeliver = data.is_autoDeliver
		end
		self._IsAutoConversation = false
	else
		self._DialogueType = DialogueType.DialogueOnly
		self._IsAutoConversation = true
	end
	--self._Img_Shadow:SetActive(data.is_provide ~= nil)

	if data.is_camera_change ~= nil then
		self._IsCameraChange = data.is_camera_change
	end

	local img_fade = self:GetUIObject("Img_Fade")
	if img_fade ~= nil then
		img_fade:SetActive(not self._IsCameraChange)
	end

	self._Model_NPCTalkRight:SetActive(not self._IsCameraChange)
	self._Model_NPCTalkLeft:SetActive(not self._IsCameraChange)

	self:Refresh()

	--CQuestAutoMan.Instance():Pause(_G.PauseMask.UIShown)
	--CDungeonAutoMan.Instance():Pause(_G.PauseMask.UIShown)
	CAutoFightMan.Instance():Pause(_G.PauseMask.UIShown)

--	if self:IsShow() then
--		-- warn("OD GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.SCENE_DLG)", debug.traceback())
--		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.SCENE_DLG)
--		self._InSceneCamFX = true
--	end
end

def.method().Refresh = function(self)
	self._Current_Sentence_Index = 0
	self._Current_Dialogue_Template = CElementData.GetDialogueTemplate(self._Model.dialogue_id)
	if self._Current_Dialogue_Template == nil then
		warn("the dialogue template cant find.")
		return
	end
	self:RefreshSentence(false)
end

local function IsLast2Sentence()
	return instance._Current_Sentence_Index + 1 >= #instance._Current_Dialogue_Template.Sentences
end

local function IsLastSentence()
	if instance._Current_Dialogue_Template.Sentences == nil then
		warn("cant find property 'Sentences' in _CurrentDialogueTemplate fields.")
		return true
	end
	return instance._Current_Sentence_Index == #instance._Current_Dialogue_Template.Sentences
end

local function GetSentenceModelByIndex(sntns_index)
	if instance._Current_Dialogue_Template.Sentences == nil then
		warn("the property 'Sentences' of _Model is nil.")
		return nil
	end
	return instance._Current_Dialogue_Template.Sentences[sntns_index]
end


local function GetNpcModelAssetPath(id)
	local npcTemplate = CElementData.GetNpcTemplate(id)
	if npcTemplate == nil then return "" end

	return npcTemplate.ModelAssetPath
end

-- local function SetImageModelParam(c_im, e_side)
--    local keyword = c_im._ModelAssetPath
--    local l_cfg = require "ImageModelParams.DialogParam"

--    if l_cfg == nil then
--        warn("ImageModelParams.DialogParam not found!")
--        return
--    end

--    local index = 0
--    if e_side == EnumDef.SentenceDisplayType.Left then
--        index = 1
--    elseif e_side == EnumDef.SentenceDisplayType.Right then
--        index = 2
--    else
--        return
--    end

--    local item = l_cfg[keyword]
--    if item == nil or item[index] == nil then
--        item = l_cfg["default"]
--    end

--    if item ~= nil and item[index] then
--        local param = item[index]
--        c_im:SetLookAtParam(param.Size, param.Offset[2], param.Offset[1], param.RotY)
--    end
-- end

local function PostInitModel(self, c_im, e_side, npc_id)
	----formly as SetImageModelParam(c_im, e_side)
	-- c_im:SetDialogParam(e_side)

	--    local dirX, dirZ = game._HostPlayer:GetDirXZ()
	--    local dir = Vector3.New(dirX, 0, dirZ)

	--    --warn("PostInitModel "..npc_id..", "..e_side)

	--    if npc_id == -1 then
	--        c_im:AlignSystemWithDir(- dir)
	--    else
	--        c_im:AlignSystemWithDir(dir)
	--    end

	local anim = self:PlayNpcDefaultAnim(c_im, npc_id)

	c_im:SetDialogParam(e_side, anim)
end

def.method(CUIModel, "number", "=>", "string").PlayNpcDefaultAnim = function(self, im, npc_id)
	local anim_name = EnumDef.CLIP.COMMON_STAND
	local npcTemplate = nil

	if npc_id ~= -1 then
		npcTemplate = CElementData.GetNpcTemplate(npc_id)
	end

	-- warn("da "..npcTemplate.DefaultAnimation..", "..#(npcTemplate.DefaultAnimation))

	if npcTemplate ~= nil and #(npcTemplate.DefaultAnimation) > 0 then
		anim_name = npcTemplate.DefaultAnimation
	end
	im:PlayAnimation(anim_name)
	return anim_name
end

def.method("boolean").RefreshSentence = function(self, isTimeAuto)
	if not self:IsShow() then
		return
	end

	local bIsLast2Sentence = IsLast2Sentence()
	local bIsLastSentence = IsLastSentence()
	if bIsLastSentence then
		local isAutoSkip = false
		if self._IsAutoProvide or self._IsAutoDeliver or self._IsAutoConversation then
			isAutoSkip = true
		end

		if isTimeAuto and not isAutoSkip then
			return
		end
	end

	-- 最后一条数据，是否 接取任务/交付任务
	if bIsLast2Sentence and self._DialogueType ~= DialogueType.DialogueOnly then
		self._ImgNext:SetActive(false)
		self._ImgFinish:SetActive(true)
		self._LabGetQuest:SetActive(true)

		GUI.SetText(self._LabGetQuest, StringTable.Get((self._DialogueType == DialogueType.Provide) and 700 or 701))
	else
		self._ImgNext:SetActive(true)
		self._ImgFinish:SetActive(false)
		self._LabGetQuest:SetActive(false)
	end

	if bIsLastSentence then
		OnSkip()
		return
	end

	self._Current_Sentence_Index = self._Current_Sentence_Index + 1

	local sntns_model = GetSentenceModelByIndex(self._Current_Sentence_Index)
	if sntns_model == nil then
		warn("the sentence " .. self._Current_Sentence_Index .. " is not exist in the data of file.")
		return
	end
	local setting = nil
	local profession = game._HostPlayer._ProfessionTemplate.Id
	setting = sntns_model.ProfessionDistinguishSettings[profession]
	if setting == nil or setting.UseDefault then
		setting = sntns_model.Default
	end
	if setting == nil then
		warn("there isnt setting datas.")
		return
	end

	if setting.DisplayType == EnumDef.SentenceDisplayType.Aside then
		self._Img_NameLeft:SetActive(false)
		self._Img_NameRight:SetActive(false)
		GUI.SetText(self._Lab_NPCTalk, DynamicText.ParseDialogueText(setting.TextContent))

		if not IsNilOrEmptyString(setting.AudioAssetPath) then
			CSoundMan.Instance():Play3DVoice(setting.AudioAssetPath, game._HostPlayer:GetPos(), 0)
		else
			CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(), 0)
		end
	else
		local model_asset_path = nil
		local npc_id = 0
		if setting.ShowHost ~= nil and setting.ShowHost then
			-- model_asset_path = game._HostPlayer:GetModelParams()
			npc_id = -1
		else
			model_asset_path = GetNpcModelAssetPath(setting.ModelId)
			npc_id = setting.ModelId
		end

		if model_asset_path ~= nil or npc_id == -1 then
			if setting.DisplayType == EnumDef.SentenceDisplayType.Left then

				self._Img_NameLeft:SetActive(true)
				self._Img_NameRight:SetActive(false)
				GUI.SetText(self._Lab_NPCTalk, DynamicText.ParseDialogueText(setting.TextContent))

				if not IsNilOrEmptyString(setting.AudioAssetPath) then
					CSoundMan.Instance():Play3DVoice(setting.AudioAssetPath, game._HostPlayer:GetPos(), 0)
				else
					CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(), 0)
				end

				if npc_id == -1 then
					GUI.SetText(self._Lab_NameLeft, game._HostPlayer._InfoData._Name)
				else
					GUI.SetText(self._Lab_NameLeft, setting.TextSpeakerName)
				end

				local last_id = self._LeftNpcID
				self._LeftNpcID = npc_id

				if self._IsCameraChange == false then
					if self._LeftNpcID ~= last_id or self._NPCUIModelLeft == nil then
						if self._NPCUIModelLeft ~= nil then
							self._NPCUIModelLeft:Destroy()
						end

						local cb_1 =( function(c_im)
							PostInitModel(self, c_im, EnumDef.SentenceDisplayType.Left, instance._LeftNpcID)
						end )

						if self._LeftNpcID == -1 then
							self._NPCUIModelLeft = GUITools.CreateHostUIModel(self._Model_NPCTalkLeft, EnumDef.RenderLayer.UI, cb_1)
						else
							self._NPCUIModelLeft = CUIModel.new(model_asset_path, self._Model_NPCTalkLeft, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, cb_1)
						end
					end
				end
			elseif setting.DisplayType == EnumDef.SentenceDisplayType.Right then
				self._Img_NameLeft:SetActive(false)
				self._Img_NameRight:SetActive(true)
				GUI.SetText(self._Lab_NPCTalk, DynamicText.ParseDialogueText(setting.TextContent))

				if not IsNilOrEmptyString(setting.AudioAssetPath) then
					CSoundMan.Instance():Play3DVoice(setting.AudioAssetPath, game._HostPlayer:GetPos(), 0)
				else
					CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(), 0)
				end

				if npc_id == -1 then
					GUI.SetText(self._Lab_NameRight, game._HostPlayer._InfoData._Name)
				else
					GUI.SetText(self._Lab_NameRight, setting.TextSpeakerName)
				end

				local last_id = self._RightNpcID
				self._RightNpcID = npc_id

				if self._IsCameraChange == false then
					if self._RightNpcID ~= last_id or self._NPCUIModelRight == nil then
						if self._NPCUIModelRight ~= nil then
							self._NPCUIModelRight:Destroy()
						end

						local cb_2 =( function(c_im)
							PostInitModel(self, c_im, EnumDef.SentenceDisplayType.Right, instance._RightNpcID)
						end )

						if self._RightNpcID == -1 then
							self._NPCUIModelRight = GUITools.CreateHostUIModel(self._Model_NPCTalkRight, EnumDef.RenderLayer.UI, cb_2)
						else
							self._NPCUIModelRight = CUIModel.new(model_asset_path, self._Model_NPCTalkRight, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, cb_2)
						end
					end
				end
			end

			-- warn("Show Model "..setting.DisplayType)

			if self._NPCUIModelLeft ~= nil then
				if setting.DisplayType == EnumDef.SentenceDisplayType.Left then
					self._NPCUIModelLeft:SetColor(1, 1, 1)

					-- warn("Model L 1")

				else
					self._NPCUIModelLeft:SetColor(0.6, 0.6, 0.6)

					-- warn("Model L 0.6")

				end
			end
			if self._NPCUIModelRight ~= nil then
				if setting.DisplayType == EnumDef.SentenceDisplayType.Right then
					self._NPCUIModelRight:SetColor(1, 1, 1)

					-- warn("Model R 1")

				else
					self._NPCUIModelRight:SetColor(0.6, 0.6, 0.6)

					-- warn("Model R 0.6")

				end
			end

		end
	end

	_G.RemoveGlobalTimer(self._Sentence_Timer_Id)
	if sntns_model.MaxDuration > 0 then
		local func = function()
			self:RefreshSentence(true)
		end
		self._Sentence_Timer_Id = _G.AddGlobalTimer(sntns_model.MaxDuration / 1000, true, func)
	end
end

def.override().OnHide = function(self)
	CPanelBase.OnHide(self)
	_G.RemoveGlobalTimer(self._Sentence_Timer_Id)
	self._Sentence_Timer_Id = 0

	self._Model = nil
	self._Current_Sentence_Index = 0
	self._Current_Dialogue_Template = nil

	if self._NPCUIModelLeft ~= nil then
		self._NPCUIModelLeft:Destroy()
		self._NPCUIModelLeft = nil
	end

	if self._NPCUIModelRight ~= nil then
		self._NPCUIModelRight:Destroy()
		self._NPCUIModelRight = nil
	end

	self._IsCameraChange = false

	--CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
	--CDungeonAutoMan.Instance():Restart(_G.PauseMask.UIShown)
	CAutoFightMan.Instance():Restart(_G.PauseMask.UIShown)

	CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(), 0)

--	if self._InSceneCamFX then
--		-- warn("OH GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)", debug.traceback())
--		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
--	end
end

def.override().OnDestroy = function(self)
	self._Img_NameLeft = nil
	self._Img_NameRight = nil
	self._Lab_NameLeft = nil
	self._Lab_NameRight = nil
	self._Lab_NPCTalk = nil
	self._Model_NPCTalkLeft = nil
	self._Model_NPCTalkRight = nil
	--self._Img_Shadow = nil
	self._Frame_NpcDialogue = nil
	self._ImgNext = nil
	self._ImgFinish = nil
	self._LabGetQuest = nil
	--self._InSceneCamFX = false
end

def.override("userdata").OnPointerClick = function(self, target)
	if target ~= nil and target.name ~= 'Btn_Skip' then
		self:RefreshSentence(false)
	end
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Skip" then
		OnSkip()
	end
	if id == 'Model_NPCTalkLeft' or id == 'Model_NPCTalkRight' then
		self:RefreshSentence(false)
	end
end

CPanelDialogue.Commit()
return CPanelDialogue