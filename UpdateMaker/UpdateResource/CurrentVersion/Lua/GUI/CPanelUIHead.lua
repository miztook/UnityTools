local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyPropEvent = require "Events.NotifyPropEvent"
local EPkMode = require "PB.data".EPkMode
local CEntity = require "Object.CEntity"
local CPageManHead = require "GUI.CPageManHead"
local CPageMonsterHead = require "GUI.CPageMonsterHead"
local CPageBtnAutokill = require "GUI.CPageMonsterHead"
local CFrameBuff = require "GUI.CFrameBuff"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPanelUIHead = Lplus.Extend(CPanelBase, "CPanelUIHead")
local def = CPanelUIHead.define
local instance = nil

def.field("table")._PanelObject = BlankTable
def.field("boolean")._IsShowPKFight = false
def.field("number")._CurPkMode = 0
def.field("number")._BuffMaxCount = 5
def.field("table")._LastBuffInfo = BlankTable
def.field("number")._HeadIconWidth = 0
def.field("number")._UIFxTimer = 0

def.field(CFrameBuff)._CFrameBuff = nil
def.field("number")._PkModeMaxCount = 3

def.static("=>", CPanelUIHead).Instance = function ()
	if not instance then
        instance = CPanelUIHead()
        instance._PrefabPath = PATH.UI_Head
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
	self._CurPkMode = game._HostPlayer:GetPkMode()
    self._PanelObject = 
    {
        Frame_HostHead = {},            --主角头像
        Frame_ManHead = {},             --其他玩家头像
        Frame_MonsterHead = {},         --怪物&Npc头像&矿物 etc.
        Frame_TargetHead = {}, 			--目标的目标头像
        DisableGroup = {},				--系统菜单弹出时，需要显隐的组件
    }
	
    do
    --目标的目标
    	local info = self._PanelObject.Frame_TargetHead
    	info.Root = self:GetUIObject('Frame_TargetHead')

    	local Img_HeadBG = info.Root:FindChild("Img_HeadBG")
    	info._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
    	info._Name = Img_HeadBG:FindChild("Lab_Name")
    	info._HeadIcon = Img_HeadBG:FindChild("Img_HeadIcon")
    	info._HeadIcon_Elite = Img_HeadBG:FindChild("Img_HeadIcon_Elite")
    	info._HeadIcon_Boss = Img_HeadBG:FindChild("Img_HeadIcon_Boss")

    	local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
    	info._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
        -- info._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
	end

	do
	--主角头像
		local info = self._PanelObject.Frame_HostHead
		info.Root = self:GetUIObject('Frame_HostHead')

		-- buff
		local List_Buff = self:GetUIObject('List_BuffHost')
		info._ListBuffGroup = {}
		for i=1, self._BuffMaxCount do
			local obj = List_Buff:FindChild('item'..(i-1))
			info._ListBuffGroup[i] = obj
			obj:SetActive(false)
		end
		info._BtnBuff = self:GetUIObject('Btn_BuffHost')

		local Img_HeadBG = info.Root:FindChild("Img_HeadBG")
		info._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
		-- 血条 蓝条
		local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
		info._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
		-- info._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
		info._HpText =  Bld_HP:FindChild('Lab_HP')
		info._MpIndicator = Img_HeadBG:FindChild('Prg_Stamina/Prg_FillRect'):GetComponent(ClassType.Image)
		-- PK模式
		local Img_HeadBoard = info.Root:FindChild("Img_HeadBoard")
		info._ImgPKSet = Img_HeadBoard:FindChild('Btn_PKSet/Img_PKSet')
		info._Frame_Fight = self:GetUIObject('Frame_Fight')
        -- 战斗力
        info._FightScore = self:GetUIObject('Lab_FightScore_Data')
	end

	do
	--其他玩家头像
		local info = self._PanelObject.Frame_ManHead
		info.Root = self:GetUIObject('Frame_ManHead')

		-- buff
		local List_Buff = self:GetUIObject('List_BuffMan')
		info._ListBuffGroup = {}
		for i=1, self._BuffMaxCount do
			local obj = List_Buff:FindChild('item'..(i-1))
			info._ListBuffGroup[i] = obj
			obj:SetActive(false)
		end
		info._BtnBuff = self:GetUIObject('Btn_BuffMan')

		local Img_HeadBG = info.Root:FindChild("Img_HeadBG")
		info._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
    	info._Name = Img_HeadBG:FindChild("Lab_Name")
    	info._HeadIcon = Img_HeadBG:FindChild("Img_HeadIcon")
		-- 血条 蓝条
		local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
    	info._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
    	-- info._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
    	info._HpText =  Bld_HP:FindChild('Lab_HP')
    	info._MpIndicator = Img_HeadBG:FindChild('Prg_Stamina/Prg_FillRect'):GetComponent(ClassType.Image)
    	-- PK模式
    	local Img_HeadBoard = info.Root:FindChild("Img_HeadBoard")
    	info._ImgPKSet = Img_HeadBoard:FindChild('Btn_PKSet/Img_PKSet')
	end

	do
	--怪物&Npc头像 etc.
		local info = self._PanelObject.Frame_MonsterHead
		info.Root = self:GetUIObject('Frame_MonsterHead')
		info.Frame_NormalHead = {}
		info.Frame_EliteHead = {}
		info.Frame_BosslHead = {}

		do
			-- 普通怪, NPC, 矿物等
			local frameRoot = info.Frame_NormalHead
			frameRoot.Root = self:GetUIObject('Frame_NormalHead')
			-- buff
			frameRoot._ListBuff = self:GetUIObject('List_BuffMonster_Normal')
			frameRoot._ListBuffGroup = {}
			for i=1, self._BuffMaxCount do
				local obj = frameRoot._ListBuff:FindChild('item'..(i-1))
				frameRoot._ListBuffGroup[i] = obj
				obj:SetActive(false)
			end
			frameRoot._BtnBuff = self:GetUIObject('Btn_BuffMonster_Normal')

			local Img_HeadBG = frameRoot.Root:FindChild("Img_HeadBG")
			frameRoot._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
	    	frameRoot._Name = Img_HeadBG:FindChild("Lab_Name")
	    	frameRoot._HeadIcon = Img_HeadBG:FindChild("Img_HeadIcon")

	    	-- 血条 蓝条
			local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
	    	frameRoot._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
	    	frameRoot._HpText =  Bld_HP:FindChild('Lab_HP')
	    	-- frameRoot._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
	    	frameRoot._MpIndicator = Img_HeadBG:FindChild('Prg_Stamina/Prg_FillRect'):GetComponent(ClassType.Image)
		end

		do
			-- 精英怪
			local frameRoot = info.Frame_EliteHead
			frameRoot.Root = self:GetUIObject('Frame_EliteHead')
			-- buff
			frameRoot._ListBuff = self:GetUIObject('List_BuffMonster_Elite')
			frameRoot._ListBuffGroup = {}
			for i=1, self._BuffMaxCount do
				local obj = frameRoot._ListBuff:FindChild('item'..(i-1))
				frameRoot._ListBuffGroup[i] = obj
				obj:SetActive(false)
			end
			frameRoot._BtnBuff = self:GetUIObject('Btn_BuffMonster_Elite')

			local Img_HeadBG = frameRoot.Root:FindChild("Img_HeadBG")
			frameRoot._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
	    	frameRoot._Name = Img_HeadBG:FindChild("Lab_Name")
	    	frameRoot._HeadIcon = Img_HeadBG:FindChild("Img_HeadIcon")

	    	-- 血条 蓝条
			local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
	    	frameRoot._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
	    	-- frameRoot._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
	    	frameRoot._HpText =  Bld_HP:FindChild('Lab_HP')
	    	frameRoot._Pozhan = Img_HeadBG:FindChild('Img_Pozhan')

	    	-- 词缀
	    	frameRoot._AffixGroupMax = Img_HeadBG:FindChild('AffixGroupMax')
	    	frameRoot._AffixMax = {}
			for i=1,4 do
				local affixObj = frameRoot._AffixGroupMax:FindChild('Img_Rank'..i.."/Lab_Affix"..i)
				table.insert(frameRoot._AffixMax, affixObj)
			end
		end

		do
			-- BOSS怪
			local frameRoot = info.Frame_BosslHead
			frameRoot.Root = self:GetUIObject('Frame_BosslHead')
			-- buff
			frameRoot._ListBuff = self:GetUIObject('List_BuffMonster_Boss')
			frameRoot._ListBuffGroup = {}
			for i=1, self._BuffMaxCount do
				local obj = frameRoot._ListBuff:FindChild('item'..(i-1))
				frameRoot._ListBuffGroup[i] = obj
				obj:SetActive(false)
			end
			frameRoot._BtnBuff = self:GetUIObject('Btn_BuffMonster_Boss')

			local Img_HeadBG = frameRoot.Root:FindChild("Img_HeadBG")
			frameRoot._Level = Img_HeadBG:FindChild("Img_LevelBroad/Lab_Level")
	    	frameRoot._Name = Img_HeadBG:FindChild("Lab_Name")
	    	frameRoot._HeadIcon = Img_HeadBG:FindChild("Img_HeadIcon")

	    	-- 血条 蓝条
			local Bld_HP = Img_HeadBG:FindChild('Bld_HP')
	    	frameRoot._HpIndicator = Bld_HP:GetComponent(ClassType.GBlood)
	    	-- frameRoot._HpDamageUIFx = Bld_HP:FindChild("Node_Front/Img_Cap")
	    	frameRoot._HpText =  Bld_HP:FindChild('Lab_HP')
	    	frameRoot._Pozhan = Img_HeadBG:FindChild('Img_Pozhan')

	    	-- 多血条 个数
	    	frameRoot._Lab_MutipleProgressCount = Bld_HP:FindChild('Lab_MutiProgressCount')
	    	frameRoot._GBloodGameObject = Bld_HP

	    	-- 词缀
	    	frameRoot._AffixGroupMax = Img_HeadBG:FindChild('AffixGroupMax')
	    	frameRoot._AffixMax = {}
			for i=1,4 do
				local affixObj = frameRoot._AffixGroupMax:FindChild('Img_Rank'..i.."/Lab_Affix"..i)
				table.insert(frameRoot._AffixMax, affixObj)
			end
		end
	end

	do
		local HostHead = self._PanelObject.Frame_HostHead
		local info = self._PanelObject.DisableGroup
		table.insert(info, HostHead.Root)
		-- table.insert(info, self:GetUIObject('Img_HeadBG/Bld_HP'))
		-- table.insert(info, self:GetUIObject('Prg_Stamina0'))
		-- table.insert(info, self:GetUIObject('List_BuffHost'))
		-- table.insert(info, self:GetUIObject('Btn_BuffHost'))
	end	
end

--FIX S2C Message also send when hp getline
def.override("dynamic").OnData =function (self,data)
	if not IsNil(self._Panel) then
		local hp = game._HostPlayer
		self:ListenToEvent()
		self:UpdateLevelInfo()
		self:UpdateHpInfo()
		self:UpdateFightScore()
		self:UpdateEnergyInfo()
		self:UpdatePKMode()
        self:UpdatePKPanel()
		if hp._CurTarget then
			self:OpenTargetHead(hp._CurTarget)
		end
		
		if self._CFrameBuff == nil then
			self._CFrameBuff = CFrameBuff.new(hp, self._PanelObject.Frame_HostHead,CFrameBuff._LayoutDirection.FromLeftToRight)
		else
			self._CFrameBuff:InitBuffState()
		end
	end
end

local OnEntityPKModeChangeEvent = function(sender, event)
	if instance ~= nil and instance:IsShow() then
		if game._HostPlayer._ID == event._EntityId then
			instance:UpdatePKMode()
			instance:UpdatePKPanel()
		end
	end
end

local OnHostPlayerLevelChangeEvent = function(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateLevelInfo()
    	instance:UpdateFightScore()
	end
end

local OnNotifyPropEvent = function(sender, event)
	if instance ~= nil and instance:IsShow() then
		if game._HostPlayer._ID == event.ObjID then
			instance:UpdateHpInfo()
			instance:UpdateEnergyInfo()
			instance:UpdateFightScore()

			-- if event.Type == "TakeDamage"then
			--     instance:ShowTakeDamageUIFX()
			-- end
		end
	end
end

local OnEntityClick = function(sender, event)
    if event._Param ~= nil and instance:IsShow() and event._Param ~= instance._Panel.name then
        local info = instance._PanelObject.Frame_HostHead
        if info._Frame_Fight.activeSelf then
            info._Frame_Fight:SetActive(false)
            instance._IsShowPKFight = false
        end
    end
end

def.method().ListenToEvent = function(self)
	CGame.EventManager:addHandler("EntityPKModeChangeEvent", OnEntityPKModeChangeEvent)
	CGame.EventManager:addHandler("HostPlayerLevelChangeEvent", OnHostPlayerLevelChangeEvent)
	CGame.EventManager:addHandler(NotifyPropEvent, OnNotifyPropEvent)
    CGame.EventManager:addHandler('NotifyClick', OnEntityClick)	
end

def.method().UnlistenToEvent = function(self)
	CGame.EventManager:removeHandler("EntityPKModeChangeEvent", OnEntityPKModeChangeEvent)
	CGame.EventManager:removeHandler("HostPlayerLevelChangeEvent", OnHostPlayerLevelChangeEvent)
	CGame.EventManager:removeHandler(NotifyPropEvent, OnNotifyPropEvent)
    CGame.EventManager:removeHandler('NotifyClick', OnEntityClick)	
end

def.method().UpdateFightScore = function(self)
	if instance:IsShow() then
		local hp = game._HostPlayer
		local info = instance._PanelObject.Frame_HostHead
		local score = hp:GetHostFightScore()
		GUI.SetText(info._FightScore, GUITools.FormatMoney(score))
	end
end

def.method().UpdateLevelInfo = function(self)
	if instance:IsShow() then
		local hp = game._HostPlayer
		local info = self._PanelObject.Frame_HostHead
		GUI.SetText(info._Level, tostring(hp._InfoData._Level) )
	end	
end

def.method().UpdateHpInfo = function(self)
	if instance:IsShow() then
		local info = self._PanelObject.Frame_HostHead
		local info_data = game._HostPlayer._InfoData

		if info_data._CurShield > 0 then
            local allRatio = (info_data._CurrentHp+info_data._CurShield) / info_data._MaxHp

            if info._HpIndicator then
                if allRatio < 1 then
                    -- 和小于总血量
                    local hpRatio = info_data._CurrentHp / info_data._MaxHp
                    info._HpIndicator:SetValue(hpRatio)
                    -- 更新护盾值
                    info._HpIndicator:SetGuardValue(allRatio)
                else
                    -- 和大于总血量
                    local hpRatio = 1 - (info_data._CurShield / (info_data._CurrentHp + info_data._CurShield) )
                    info._HpIndicator:SetValue(hpRatio)
                    -- 更新护盾值
                    info._HpIndicator:SetGuardValue(1)
                end
            end
        else
            local num = info_data._CurrentHp / info_data._MaxHp
            if info._HpIndicator then
                -- 更新护盾值
                info._HpIndicator:SetGuardValue(0)
                info._HpIndicator:SetValue(num)
            end
        end

        -- 更新百分比，只有血量参与计算
        if info._HpText then
			GUI.SetText(info._HpText, string.format("%d / %d", info_data._CurrentHp, info_data._MaxHp))
		end
	end	
end

def.method().UpdateEnergyInfo = function(self)
	if instance:IsShow() then
		local info = self._PanelObject.Frame_HostHead
		local energy_type, cur_energy, max_energy = game._HostPlayer:GetEnergy()

		info._MpIndicator.fillAmount = cur_energy / max_energy
	end
end

def.method().UpdatePKMode = function(self)
	if instance:IsShow() then
		local hp = game._HostPlayer
		local info = self._PanelObject.Frame_HostHead
        self._CurPkMode = game._HostPlayer:GetPkMode()
        GUITools.SetGroupImg(info._ImgPKSet, self._CurPkMode - 1)
	end
end

def.override("userdata").OnPointerClick = function(self,target)
	self:OnPKFight(false)
end

def.method().UpdatePKPanel = function(self)
    -- self:GetUIObject("Btn_Fight1"):SetActive(true)
	-- self:GetUIObject("Btn_Fight2"):SetActive(true)
	-- self:GetUIObject("Btn_Fight3"):SetActive(true)
	-- self:GetUIObject("Btn_Fight"..self._CurPkMode):SetActive(false)
	
	for i = 1, self._PkModeMaxCount do
		local obj = self:GetUIObject("Btn_Fight" .. i)
		local Img_Select = obj:FindChild("Img_Select")
		obj:SetActive(true)
		if i == self._CurPkMode then
			Img_Select:SetActive(true)
		else
			Img_Select:SetActive(false)
		end
	end
end

-- def.method().InitLanguage = function(self)
--     GUI.SetText(self:GetUIObject("Btn_Fight1"):FindChild("Lab_Fight"), StringTable.Get(19404))
-- 	GUI.SetText(self:GetUIObject("Btn_Fight2"):FindChild("Lab_Fight"), StringTable.Get(19405))
-- 	GUI.SetText(self:GetUIObject("Btn_Fight3"):FindChild("Lab_Fight"), StringTable.Get(19406))
-- end

-- def.method().ShowTakeDamageUIFX = function(self)
--     local info = self._PanelObject.Frame_HostHead
--     info._HpDamageUIFx:SetActive(true)
--     local anim = info._HpDamageUIFx:GetComponent(ClassType.DOTweenAnimation)
--     if anim ~= nil then
--         anim:DORestart(false)
--     end
--     local function callback()
--         if self._UIFxTimer ~= 0 then
--             anim:DOPause()
--             info._HpDamageUIFx:SetActive(false)
--             self._UIFxTimer = 0
--         end
--     end
--     self._UIFxTimer = _G.AddGlobalTimer(0.5, true, callback)
-- end

def.override("string").OnClick = function(self,id)
	-- warn("OnClick.....", id)

	CPanelBase.OnClick(self,id)
	local info = self._PanelObject.Frame_HostHead
	local hp = game._HostPlayer
	if id == "Btn_BuffHost" then
		if hp:HasAnyState() and info._BtnBuff then
			game._GUIMan:Open("CPanelBuffOrTalent", { Target=hp, Obj=info._BtnBuff, AlignType=EnumDef.AlignType.PanelBuff,IsShowTalent=false})
		end
	elseif id == 'Btn_PKSet' then
		local hp = game._HostPlayer
		if hp:IsDead() then
			game._GUIMan:ShowTipText(StringTable.Get(30103), false)
			return
		end
        self:OnPKFight(not self._IsShowPKFight)   
        return  
	elseif string.find(id, "Btn_Fight") then
		self:OnPKFight(false)		
		-- LRL:取消紫名玩家限定只能开启杀戮模式   取消有队伍不能切换杀戮模式    lidaming  2018/07/13
		if id == "Btn_Fight2" and not game._GuildMan:IsHostInGuild() then
			local PKStr = string.format(StringTable.Get(19408),StringTable.Get(19405))
			game._GUIMan:ShowTipText(PKStr, false)
		else
			self._CurPkMode = tonumber(string.sub(id, -1))
			local C2SPkChangeMode = require "PB.net".C2SPkChangeMode
			local protocol = C2SPkChangeMode()
			protocol.PkMode = self._CurPkMode
			local PBHelper = require "Network.PBHelper"
			PBHelper.Send(protocol)
		end
	elseif id == "Btn_BuffMan" then
		CPageManHead.Instance():Click(id)
    elseif id == "Btn_SelectHeadMan" then
    	CPageManHead.Instance():Click(id)
    elseif string.find(id, "Btn_BuffMonster") then
		CPageMonsterHead.Instance():Click(id)
	elseif id == "Btn_SelectHeadMonster" then 
	 	CPageMonsterHead.Instance():OnClickHeadIconShowAffixDes()
    elseif id == "Btn_RoleInfo" then 
    	if game._GUIMan:IsFuncForbid(EnumDef.EGuideTriggerFunTag.Role) then return end
    	game._GUIMan:Open("CPanelRoleInfo",nil)
    
	end

    self:OnPKFight(false)
end

def.method("boolean").OnPKFight = function(self, bIsShow)
	if self._IsShowPKFight == bIsShow then return end

	local info = self._PanelObject.Frame_HostHead
    info._Frame_Fight:SetActive(bIsShow)
    self._IsShowPKFight = bIsShow
end

def.method(CEntity).OpenTargetHead = function(self, targetEntiy)
	if targetEntiy == nil or IsNil(self._Panel) then return end
	local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
	local info = nil
	local targetHead = nil
	local targetLinkInfo = nil
	if targetEntiy:GetObjectType() == OBJ_TYPE.ELSEPLAYER then
		info = self._PanelObject.Frame_ManHead
		targetHead = CPageManHead.Instance()
		targetLinkInfo = self._PanelObject.Frame_TargetHead
	elseif targetEntiy:GetObjectType() == OBJ_TYPE.PLAYERMIRROR then
	 	info = self._PanelObject.Frame_ManHead
	 	targetHead = CPageManHead.Instance()

	-- elseif targetEntiy:GetObjectType() == OBJ_TYPE.NPC then
	-- 	info = self._PanelObject.Frame_MonsterHead
	-- 	targetHead = CPageMonsterHead.Instance()
	-- 	targetLinkInfo = self._PanelObject.Frame_TargetHead
	-- elseif targetEntiy:GetObjectType() == OBJ_TYPE.MONSTER then
	-- 	info = self._PanelObject.Frame_MonsterHead
	-- 	targetHead = CPageMonsterHead.Instance()
	-- 	targetLinkInfo = self._PanelObject.Frame_TargetHead

	elseif targetEntiy:GetObjectType() == OBJ_TYPE.NPC or targetEntiy:GetObjectType() == OBJ_TYPE.MONSTER then
		info = self._PanelObject.Frame_MonsterHead
		targetHead = CPageMonsterHead.Instance()
		targetLinkInfo = self._PanelObject.Frame_TargetHead
	else
		return
	end
	targetHead:Show(info, info.Root, targetEntiy, targetLinkInfo)
end

def.method("boolean", "boolean").HideProgressBoard = function(self, bIsShowSystem, bIsOtherCall)
	if not self:IsShow() then return end -- 初始化没完成
	local info = self._PanelObject.DisableGroup
	for i,obj in ipairs(info) do
		obj:SetActive(not bIsShowSystem)
	end
	if bIsShowSystem then
		CPageMonsterHead.Instance():Hide()
		CPageManHead.Instance():Hide()
		self._CFrameBuff:Clear()
	else
		self._CFrameBuff:InitBuffState()
		self:OpenTargetHead(game._HostPlayer._CurTarget)
	end
end

def.method().InitFrameBuff = function(self)
	if self._CFrameBuff ~= nil then
		self._CFrameBuff:InitBuffState()
	end
end

def.method().ClearBuff = function(self)
	if self._CFrameBuff ~= nil then
		self._CFrameBuff:Clear()
	end
end

def.method().CloseTargetHead = function(self)
	CPageManHead.Instance():Hide()
	CPageMonsterHead.Instance():Hide()
end

def.override().OnHide = function (self)
	self:CloseTargetHead()
	self:UnlistenToEvent()
	if self._CFrameBuff ~= nil then
		self._CFrameBuff:Destory()
    	self._CFrameBuff = nil
    end
    if self._UIFxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._UIFxTimer)
        self._UIFxTimer = 0
    end
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
   
	self._PanelObject = nil
	--instance = nil
end

CPanelUIHead.Commit()
return CPanelUIHead