--
--公会捐献
--
--【孟令康】
--
--2017年9月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CCommonBtn = require "GUI.CCommonBtn"
local CPanelUIGuildDonate = Lplus.Extend(CPanelBase, "CPanelUIGuildDonate")
local def = CPanelUIGuildDonate.define

def.field("table")._Data = BlankTable

def.field("table")._CommonBtns = nil

def.field("table")._SfxRoots = BlankTable

def.field("number")._CacheSfxIndex = 0

local instance = nil
def.static("=>", CPanelUIGuildDonate).Instance = function()
	if not instance then
		instance = CPanelUIGuildDonate()
		instance._PrefabPath = PATH.UI_Guild_Donate
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	local allTid = CElementData.GetAllTid("GuildDonate")
	for i = 1, #allTid do
		local donate = CElementData.GetTemplate("GuildDonate", allTid[i])
		self._Data[#self._Data + 1] = donate
	end
    self._CommonBtns = {}
	for i = 1, 3 do
		local donate = self._Data[i]
		local index = i - 1
		GUI.SetText(self:GetUIObject("Lab_Donate_Title" .. index), donate.Name)
		GUI.SetText(self:GetUIObject("Lab_Fund" .. index), tostring(donate.RewardGuildFund))
		GUI.SetText(self:GetUIObject("Lab_Exp" .. index), tostring(donate.GuildExp))
		GUI.SetText(self:GetUIObject("Lab_Contribute" .. index), tostring(donate.RewardContribute))
		GUI.SetText(self:GetUIObject("Lab_RewardPoints" .. index), tostring(donate.RewardPoints))
		GUI.SetText(self:GetUIObject("Lab_Liveness" .. index), tostring(donate.RewardPoints))


        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = donate.CostType,
            [EnumDef.CommonBtnParam.MoneyCost] = donate.CostNum
        }
        self._CommonBtns[i] = CCommonBtn.new(self:GetUIObject("Btn_Donate_" .. i), setting)
		self._SfxRoots[i] = self:GetUIObject("Img_DonateIcon" .. index)
		GameUtil.PlayUISfx(PATH.UI_Guild_Donate_Sfx_Buttons[i], self._SfxRoots[i],self._SfxRoots[i], -1)

	end
	self:OnShowBtnDonate()
end

-- 当摧毁
def.override().OnDestroy = function(self)
    if self._CommonBtns ~= nil then
        for i,v in ipairs(self._CommonBtns) do
            if v then
                v:Destroy()
            end
        end
        self._CommonBtns = nil
    end
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	else
		for i = 1, 3 do
			if id == "Btn_Donate_" .. i then
				self:OnBtnDonate(i)
			end
		end
	end
end

-- 展示点击按钮
def.method().OnShowBtnDonate = function(self)
	for i = 1, 3 do
		local donate = self._Data[i]
        if self._CommonBtns ~= nil and self._CommonBtns[i] ~= nil then
		    local moneyValue = game._GuildMan:GetMoneyValueByTid(donate.CostType)
        	local labCost = self:GetUIObject("Btn_Donate_" .. i):FindChild("Img_Bg/Node_Content/Icon_Money/Lab_EngraveNeed")
            if moneyValue < donate.CostNum then
            	GUI.SetText(labCost,string.format(StringTable.Get(8136), GUITools.FormatNumber(donate.CostNum )))
        	else
        		GUI.SetText(labCost,string.format(StringTable.Get(8135),GUITools.FormatNumber(donate.CostNum )))
            end
            if game._HostPlayer._Guild:GetDonateNum() < 1 then
        	    self._CommonBtns[i]:MakeGray(true)
            end
        else
            warn("error !!! 公会捐献UI错误， 没有对应的捐献按钮 index : ", i)
        end
	end
end

def.method().OnSuccessPlayUIEffect = function (self)
	local sfxPath = "Assets/Outputs/Sfx/UI/ui_gonghuijuanxian_guang0".. (self._CacheSfxIndex) ..".prefab"
	GameUtil.PlayUISfx(sfxPath,self._SfxRoots[self._CacheSfxIndex],self._SfxRoots[self._CacheSfxIndex],-1)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_GuildDonate, 0)
end


-- 捐献
def.method("number").OnBtnDonate = function(self, index)
	local donate = self._Data[index]
	local moneyValue = game._GuildMan:GetMoneyValueByTid(donate.CostType)
	if game._HostPlayer._Guild:GetDonateNum() == 0 then
		game._GUIMan:ShowTipText(StringTable.Get(855), true)
		return
	end
	if moneyValue < donate.CostNum then
		local callback = function(value)
			if value then
				local protocol = (require "PB.net".C2SGuildDonate)()
				protocol.donateID = donate.Id
				PBHelper.Send(protocol)
                self._CacheSfxIndex = index
			end
		end
		MsgBox.ShowQuickBuyBox(donate.CostType, donate.CostNum, callback)
		return
	end
	if game._GuildMan:IsFundMax() then
		local callback = function(value)
			if value then
				local protocol = (require "PB.net".C2SGuildDonate)()
				protocol.donateID = donate.Id
				PBHelper.Send(protocol)
                self._CacheSfxIndex = index
			end
		end
		local title, msg, closeType = StringTable.GetMsg(31)
   		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
	else
		local protocol = (require "PB.net".C2SGuildDonate)()
		protocol.donateID = donate.Id
		PBHelper.Send(protocol)
		self._CacheSfxIndex = index
	end
end

CPanelUIGuildDonate.Commit()
return CPanelUIGuildDonate