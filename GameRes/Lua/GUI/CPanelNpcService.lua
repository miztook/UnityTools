
local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'

local CPanelNpcService = Lplus.Extend(CPanelBase, 'CPanelNpcService')

local def = CPanelNpcService.define
local max_option_count = 3

def.field('userdata')._Frame_NPCService = nil
def.field('userdata')._Lab_Dialog = nil
def.field('userdata')._Lab_NameService = nil
def.field('userdata')._Frame_NPCList = nil
def.field('userdata')._List_ServerList = nil
def.field("table")._ServOptions = nil

local instance = nil
def.static('=>', CPanelNpcService).Instance = function ()
	if not instance then
        instance = CPanelNpcService()
        instance._PrefabPath = PATH.Panel_NpcService
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        --instance._SpecialId = 0
        instance._DestroyOnHide = false
	instance._ForbidESC = true

        instance:SetupSortingParam()
	end
	return instance
end

--生命周期内预定义函数
def.override().OnCreate = function(self)
    self._Panel:FindChild('Img_Shadow'):SetActive(false)
    local TextType = ClassType.Text
    self._Frame_NPCService = self:GetUIObject("Frame_NPCService")
	self._Frame_NPCService:SetActive(true)
    self._Lab_Dialog = self:GetUIObject("Lab_Dialog")
    self._Lab_NameService = self:GetUIObject("Lab_NameService")
    self._Frame_NPCList = self:GetUIObject("Frame_NPCList")
    self._List_ServerList = self:GetUIObject("List_ServerList"):GetComponent(ClassType.GNewList)
end

def.override('dynamic').OnData = function(self, data)
	local ho = game._HostPlayer._OpHdl
	local curNpc = ho:GetCurServiceNPC()

	if curNpc == nil then
		ho:EndNPCService(nil)
		return
	end

	local npc_template = curNpc._NpcTemplate
	GUI.SetText(self._Lab_NameService, curNpc._InfoData._Name)
	GUI.SetText(self._Lab_Dialog, npc_template.TextDefaultConversation)
    if not IsNilOrEmptyString(npc_template.AudioAssetPath) then
        CSoundMan.Instance():Play3DVoice(npc_template.AudioAssetPath, curNpc:GetPos(),0)
    else
    	--CSoundMan.Instance():Play3DVoice("", curNpc:GetPos(),0)
    end

	self._ServOptions = data

	if self._ServOptions == nil or #self._ServOptions <= 0 then
		self._Frame_NPCList:SetActive(false)
	else
		self._Frame_NPCList:SetActive(true)

		local count = #self._ServOptions
		self._List_ServerList:SetItemCount( count )
		self._List_ServerList:ScrollToStep( count )
		self._List_ServerList:EnableScroll(count > 4)
	end

	self:GetUIObject('Img_Next'):SetActive(false)
end

local click_close_panel = true
def.method("string").SetNpcDialogue = function(self, dialogue)
	GUI.SetText(self._Lab_Dialog,dialogue)
	click_close_panel = false
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_ServerList' then
    	local maxCnt = #self._ServOptions

        local item_model = self._ServOptions[maxCnt - index]
		if item_model == nil then
			return
		end

		local Lab_ServerName = item:FindChild('Lab_ServerName')
		GUI.SetText(Lab_ServerName, item_model.service_name)

		local Img_Back = item:FindChild('Img_Back')
		local Img_Quest = item:FindChild('Img_Quest')
		if item_model.service_type == EnumDef.ServiceType.ProvideQuest or 
			item_model.service_type == EnumDef.ServiceType.DeliverQuest then
			Img_Back:SetActive(false)
			Img_Quest:SetActive(true)
		else
			Img_Back:SetActive(true)
			Img_Quest:SetActive(false)
		end



		local ImgG_Sign = item:FindChild('ImgG_Sign')
		GUITools.SetGroupImg(ImgG_Sign, item_model.service_type)
    end
end

local option = nil
def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_ServerList' then
    	local maxCnt = #self._ServOptions
        option = self._ServOptions[maxCnt - index]

		if click_close_panel then
			game._GUIMan:CloseByScript(self)
		end
		click_close_panel = true

        local CNPCServiceHdl = require "ObjHdl.CNPCServiceHdl"
		CNPCServiceHdl.DealServiceOption(option)
    end
end

def.override("string").OnClick = function(self,id)
    -- TODO: 以下情形好像永不会发生，Options只有在个数多余1时才会进入此界面
    --if string.find(id, "Img_BG") and #self._ServOptions < 1 then
	if string.find(id, "Img_BG") then
		game._HostPlayer._OpHdl:EndNPCService(nil)
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	self._ServOptions = nil
	CSoundMan.Instance():Play3DVoice("", game._HostPlayer:GetPos(),0)
end

CPanelNpcService.Commit()
return CPanelNpcService