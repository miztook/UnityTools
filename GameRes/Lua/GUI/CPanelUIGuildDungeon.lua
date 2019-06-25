--
-- 异界之门
--
--【孟令康】
--
-- 2018年3月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local GuildMemberType = require "PB.data".GuildMemberType
local CGame = Lplus.ForwardDeclare("CGame")
local GuildBuildingType = require "PB.data".GuildBuildingType
local CPanelUIGuildDungeon = Lplus.Extend(CPanelBase, "CPanelUIGuildDungeon")
local CFrameCurrency = require "GUI.CFrameCurrency"
local def = CPanelUIGuildDungeon.define

def.field("table")._Data = nil
def.field("table")._RewardData = nil
def.field("table")._DamageInfo = nil
def.field("number")._PageIndex = 1
def.field("number")._BossIndex = 1
def.field("table")._PanelObject = nil
-- 对应建筑信息
def.field("table")._Building = nil
local EXPEDITION_POPUP_TID = 13 -- 远征介绍弹窗TID

local instance = nil
def.static("=>", CPanelUIGuildDungeon).Instance = function()
	if not instance then
		instance = CPanelUIGuildDungeon()
		instance._PrefabPath = PATH.UI_Guild_Dungeon
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:ShowBtnBuy()
	end
end

-- 当创建
def.override().OnCreate = function(self)
    self._PanelObject = {}
    self._PanelObject._Tab_Boss = self:GetUIObject("Tab_Boss")
    self._PanelObject._ListDungeon = self:GetUIObject("List_Dungeon"):GetComponent(ClassType.GNewList)
    self._PanelObject._Frame_Center = self:GetUIObject("Frame_Center")
    self._PanelObject._Frame_Bottom = self:GetUIObject("Frame_Bottom")
    self._PanelObject._Frame_Right = self:GetUIObject("Frame_Right")
	CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)	
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
    self._HelpUrlType = HelpPageUrlType.Guild_Dungeon
	self._Data = {}
	self._Data._Template = {}	
	local allTid = GameUtil.GetAllTid("GuildExpedition")
	for i = 1, #allTid do
		self._Data._Template[i] = CElementData.GetTemplate("GuildExpedition", allTid[i]) 
	end
	-- 所有副本次数组共用，取1个计算
	local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
	local dungeon = CElementData.GetTemplate("Instance", dungeonTid)
	local countGroup = CElementData.GetTemplate("CountGroup", dungeon.CountGroupTid)
	self._Data._MaxCount = countGroup.MaxCount
	self._Data._CurCount = game._DungeonMan:GetRemainderCount(dungeonTid)
	self._Building = game._HostPlayer._Guild._BuildingList[3]
    
	self._Data._BossHP = data.BossHP
	self._Data._BossTid = data.BossTId
	self._Data._CurDungeonTid = data.CurDungeonTID
	self._Data._MaxExpeditionId = data.MaxExpeditionId
	self._Data._BossTotalHP = data.BossTotalHp
    self._Data._CurExpeditionIndex = 1
	if self._Data._BossTid == 0 then
		self._Data._BossTid = self._Data._Template[1].DungeonDatas[1].BossTID
	end
	self._Data._BossMaxHp = data.CurBossMaxHp
	if self._Data._BossHP > self._Data._BossMaxHp then
		self._Data._BossHP = self._Data._BossMaxHp
	end
    self._Data._HasOpened = false
	self._Data._Passed = {}
	self._Data._Opened = {}
	self._Data._Rewarded = {}
	local rewardList = game._HostPlayer._Guild._ExpeditionRewardList
	for i = 1, #self._Data._Template do
		local template = self._Data._Template[i]
		local dungeonDatas = template.DungeonDatas
		self._Data._Opened[template.Id] = false
		for j = 1, #dungeonDatas do
			local dungeonTid = dungeonDatas[j].DungeonTID
			if dungeonTid == self._Data._CurDungeonTid then
				self._Data._Opened[template.Id] = true
                self._Data._HasOpened = true
                self._Data._CurExpeditionIndex = i
				self._PageIndex = i
				self._BossIndex = j
			end
			self._Data._Passed[dungeonTid] = false			
			self._Data._Rewarded[dungeonTid] = false
			for k = 1, #data.PassedDungeonIds do
				if data.PassedDungeonIds[k] == dungeonTid then					
					self._Data._Passed[dungeonTid] = true
                    self._Data._Opened[template.Id] = true
                    self._Data._HasOpened = true
				end
			end
			for k = 1, #rewardList do
				if rewardList[k] == dungeonTid then
					self._Data._Rewarded[dungeonTid] = true
				end
			end
		end
	end
    local bg1 = self._Panel:FindChild("Img_BG")
	GameUtil.PlayUISfx(PATH.UI_Guild_Defend_bg_sfx,bg1,bg1,-1)
    local protocol = (require "PB.net".C2SGuildExpeditionDamageInfo)()
    protocol.DungeonTID = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex].DungeonTID
	PBHelper.Send(protocol)
    GUI.SetGroupToggleOn(self._PanelObject._Tab_Boss, self._BossIndex)
    self:UpdatePanel()
end

-- 更新左边Pages的信息
local UpdateLeftPanel = function(self)
    self._PanelObject._ListDungeon:SetItemCount(#self._Data._Template)
end

-- 更新中间boss的信息
local UpdateCenterPanel = function(self)
    local uiTemplate = self._PanelObject._Frame_Center:GetComponent(ClassType.UITemplate)
    local img_boss = uiTemplate:GetControl(0)
    local img_boss_kill = uiTemplate:GetControl(1)
    local tab_boss = uiTemplate:GetControl(2)
    local data = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex]
    local expedition = self._Data._Template[self._PageIndex]
    GUITools.SetSprite(img_boss, data.BossPicturePath or "")
    if self._Data._Passed[data.DungeonTID] then
        img_boss_kill:SetActive(true)
    else
        img_boss_kill:SetActive(false)
    end
    for i = 1,3 do
        local dungeonTid = expedition.DungeonDatas[i].DungeonTID
		local passed = self._Data._Passed[dungeonTid]
        local rdo_boss = GUITools.GetChild(tab_boss, i-1)
        local img_boss = GUITools.GetChild(rdo_boss, 0)
        local img_kill = GUITools.GetChild(rdo_boss, 1)
        local img_lock = GUITools.GetChild(rdo_boss, 2)
        local img_red_point = GUITools.GetChild(rdo_boss, 3)
		img_kill:SetActive(passed)
		if passed and not self._Data._Rewarded[dungeonTid] then 
            img_red_point:SetActive(true)
        else
            img_red_point:SetActive(false)
		end 
		local bossTid = self._Data._Template[self._PageIndex].DungeonDatas[i].BossTID
		local boss = CElementData.GetTemplate("Monster", bossTid)
        if boss == nil then warn("Error !!! bossTid 填写错误，ID: ", bossTid) return end
		GUITools.SetHeadIcon(img_boss, boss.IconAtlasPath)		
		if passed then
			img_lock:SetActive(false)
            GameUtil.MakeImageGray(img_boss, true)
		else
            GameUtil.MakeImageGray(img_boss, false)
			if self._Data._CurDungeonTid == dungeonTid then
				img_lock:SetActive(false)
			else
				img_lock:SetActive(true)	
			end
		end
    end
end

-- 更新界面下方次数和按钮的信息
local UpdateBottomPanel = function(self)
    local uiTemplate = self._PanelObject._Frame_Bottom:GetComponent(ClassType.UITemplate)
    local lab_cost_num = uiTemplate:GetControl(0)
    local lab_red_tip = uiTemplate:GetControl(2)
    local lab_green_tip = uiTemplate:GetControl(3)
    local btn_open = uiTemplate:GetControl(4)
    local btn_enter = uiTemplate:GetControl(5)
    lab_red_tip:SetActive(false)
    lab_green_tip:SetActive(false)
    btn_open:SetActive(false)
    btn_enter:SetActive(false)
    do  -- 更新次数
        local remainderTime = self._Data._CurCount
	    local maxTime = self._Data._MaxCount
	    local colorFormat = "%d"
	    if remainderTime == 0 then
		    colorFormat = "<color=#DB2E1C>%d</color>"
	    elseif remainderTime > maxTime then
		    colorFormat = "<color=#5CBE37>%d</color>"
	    end
	    GUI.SetText(lab_cost_num, string.format(colorFormat, remainderTime) .. "/" .. maxTime)
    end
    do -- 更新按钮和label显示
        local data = self._Data._Template[self._PageIndex]
        local is_page_lock = self._Building._BuildingLevel < data.GuildLevel
        local expedition = self._Data._Template[self._PageIndex]
        local dungeonTid = expedition.DungeonDatas[self._BossIndex].DungeonTID
		local passed = self._Data._Passed[dungeonTid]
        if is_page_lock then
            lab_red_tip:SetActive(true)
            GUI.SetText(lab_red_tip, string.format(StringTable.Get(8012), StringTable.Get(841), data.GuildLevel))
        else
            if self._Data._CurDungeonTid == 0 and (not self._Data._HasOpened) then
                local member = game._GuildMan:GetHostGuildMemberInfo()
                if member == nil then warn("error !!! 当前角色暂未加入公会本应该不能打开这个界面") return end
                if member._RoleType == GuildMemberType.GuildLeader then
                    btn_open:SetActive(true)
                else
                    lab_red_tip:SetActive(true)
                    GUI.SetText(lab_red_tip, StringTable.Get(8068))
                end
            else
                if passed then
                    lab_green_tip:SetActive(true)
                else
                    if self._Data._CurExpeditionIndex ~= self._PageIndex then
                        lab_red_tip:SetActive(true)
                        GUI.SetText(lab_red_tip, StringTable.Get(8087))
                    else
                        if self._Data._CurDungeonTid == expedition.DungeonDatas[self._BossIndex].DungeonTID then
                            btn_enter:SetActive(true)
                        else
                            lab_red_tip:SetActive(true)
                            local tid = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex - 1].DungeonTID
				            local name = CElementData.GetTemplate("Instance", tid).TextDisplayName
				            GUI.SetText(lab_red_tip, string.format(StringTable.Get(8067), name))
                        end
                    end
                end
            end
        end
    end
end

-- 更新右方boss信息和排行信息
local UpdateRightPanel = function(self)
    local uiTemplate = self._PanelObject._Frame_Right:GetComponent(ClassType.UITemplate)
    local frame_boss_info = uiTemplate:GetControl(0)
    local frame_rank_info = uiTemplate:GetControl(1)
    local frame_reward = uiTemplate:GetControl(2)
    local expedition = self._Data._Template[self._PageIndex]
    local dungeonTid = expedition.DungeonDatas[self._BossIndex].DungeonTID
    do  -- 更新boss信息
        local dungeon_temp = CElementData.GetTemplate("Instance", dungeonTid)
        if dungeon_temp ~= nil then
            local lab_level = GUITools.GetChild(frame_boss_info, 0)
            local lab_boss_name = GUITools.GetChild(frame_boss_info, 1)
            local bar_hp = GUITools.GetChild(frame_boss_info, 2):GetComponent(ClassType.Scrollbar)
            local lab_hp_num = GUITools.GetChild(frame_boss_info, 3)
            local percent = 1
            if self._Data._CurDungeonTid == expedition.DungeonDatas[self._BossIndex].DungeonTID then
                percent = self._Data._BossHP / self._Data._BossMaxHp
            else
                if self._Data._Passed[expedition.DungeonDatas[self._BossIndex].DungeonTID] then
                    percent = 0
                else
                    percent = 1
                end
            end
	        if self._Data._BossMaxHp == 0 then
		        percent = 1
	        end
	        bar_hp.size = percent
            GUI.SetText(lab_hp_num, GUITools.FormatPreciseDecimal(percent * 100, 2) .. "%")

            if self._Building._BuildingLevel < expedition.GuildLevel then
                GUITools.GetChild(frame_boss_info, 2):SetActive(false)
            else
                if not self._Data._Opened[expedition.Id] then
                    GUITools.GetChild(frame_boss_info, 2):SetActive(false)
                else
                    GUITools.GetChild(frame_boss_info, 2):SetActive(true)
                end
            end

            
            GUI.SetText(lab_boss_name, dungeon_temp.TextDisplayName)
            local boss_temp = CElementData.GetTemplate("Monster", expedition.DungeonDatas[self._BossIndex].BossTID)
            if boss_temp ~= nil then
                GUI.SetText(lab_boss_name, boss_temp.TextDisplayName)
                GUI.SetText(lab_level, tostring(boss_temp.Level))
            end
        end
        local passed = self._Data._Passed[dungeonTid]
        local img_reward = GUITools.GetChild(frame_boss_info, 4)
        local btn_reward = GUITools.GetChild(frame_boss_info, 5)
        GameUtil.StopUISfx(PATH.UI_Guild_Dungeon_sfx_tip,img_reward)
        if passed and not self._Data._Rewarded[dungeonTid] then
			GameUtil.PlayUISfx(PATH.UI_Guild_Dungeon_sfx_tip,img_reward,img_reward,-1)
--            GameUtil.PlayUISfx(PATH.UIFX_GuildDungeonExpore, self._Img_Reward[i], self._Img_Reward[i], 3)
		end
        GameUtil.SetButtonInteractable(btn_reward, not self._Data._Rewarded[dungeonTid])
        GameUtil.MakeImageGray(img_reward, self._Data._Rewarded[dungeonTid])
    end

    do  -- 排行情况
        local max_damage = 0
        local max_count = 0
        local boss_max_hp = self._Data._BossMaxHp
        if self._DamageInfo ~= nil and #self._DamageInfo.DamageDatas > 0 then
            max_damage = self._DamageInfo.DamageDatas[1].Damage
            max_count = #self._DamageInfo.DamageDatas
        end
        if boss_max_hp == 0 then
            boss_max_hp = max_count
        end
        for i = 1,5 do
            local item = GUITools.GetChild(frame_rank_info, i-1)
            local lab_rank = GUITools.GetChild(item, 0)
            local img_hp = GUITools.GetChild(item, 1)
            local lab_level = GUITools.GetChild(item, 2)
            local lab_player_name = GUITools.GetChild(item, 3)
            local lab_process = GUITools.GetChild(item, 4)
            local tab_have = GUITools.GetChild(item, 5)
            local tab_not_have = GUITools.GetChild(item, 6)
            GUI.SetText(lab_rank, tostring(i))
            if i <= max_count then
                local data = self._DamageInfo.DamageDatas[i]
                tab_have:SetActive(true)
                tab_not_have:SetActive(false)
                GUITools.SetImageProgress(img_hp:GetComponent(ClassType.Image), data.Damage/max_damage)
                GUI.SetText(lab_level, tostring(data.RoleLevel))
                GUI.SetText(lab_process, GUITools.FormatPreciseDecimal(data.Damage * 100/boss_max_hp, 2).."%")
                GUI.SetText(lab_player_name, data.RoleName)
                GUITools.SetBtnExpressGray(item, false)
            else
                tab_have:SetActive(false)
                tab_not_have:SetActive(true)
                GUI.SetText(lab_process, 0 .."%")
                GUITools.SetBtnExpressGray(item, true)
            end
        end
    end

    do  -- 奖励
        local rewardId = CElementData.GetTemplate("Instance", dungeonTid).RewardId
	    self._RewardData = GUITools.GetRewardList(rewardId, false)
        local reward_list = GUITools.GetChild(frame_reward, 0):GetComponent(ClassType.GNewList)
	    reward_list:SetItemCount(#self._RewardData)
    end
end

-- 更新界面
def.method().UpdatePanel = function(self)
    UpdateLeftPanel(self)
    UpdateCenterPanel(self)
    UpdateBottomPanel(self)
    UpdateRightPanel(self)
end

local ParseDamageMsg = function(self, msg)
    local new_table = {}
    new_table.DamageDatas = {}
    new_table.TotalHp = msg.DamageInfo.TotalHp
    new_table.DungeonId = msg.DamageInfo.DungeonId
    local datas = new_table.DamageDatas
    for i,v in ipairs(msg.DamageInfo.DamageDatas) do
        local item = {}
        item.RoleId = v.RoleId
        item.RoleName = v.RoleName
        item.RoleLevel = v.RoleLevel
        item.ProfessionId = v.ProfessionId
        item.Damage = v.Damage
        datas[#datas + 1] = item
    end
    local sort_func = function(item1, item2)
        return item1.Damage > item2.Damage
    end
    table.sort(datas, sort_func)
    return new_table
end

def.method("table").ShowDamageDatas = function(self, msg)
    local dungeon_tid = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex].DungeonTID
    self._DamageInfo = ParseDamageMsg(self, msg)
    self._Data._BossTotalHP = self._DamageInfo.TotalHp
    UpdateRightPanel(self)
end

def.method().RequestDamageInfo = function(self)
	local protocol = (require "PB.net".C2SGuildExpeditionDamageInfo)()
    protocol.DungeonTID = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex].DungeonTID
	PBHelper.Send(protocol)
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if string.find(id, "Rdo_Boss_") then
        local new_index = tonumber(string.sub(id, -1))
        if not new_index then
            warn("error !!! 请检查预设，Tab_Boss 下面的Rdo名字必须是Rdo_Boss_%d的形式")
            return
        end
        if self._BossIndex == new_index then return end
        self._BossIndex = new_index
        self:RequestDamageInfo()
        self:UpdatePanel()
    end
end

-- Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
    	TODO(StringTable.Get(19))
	elseif id == "Btn_RankDetial" then
	    local data = {}
    --	local tid = self._Data._Template[self._PageIndex].Id
	    data._TotalHP = self._Data._BossMaxHp
	    data._Info = self._DamageInfo.DamageDatas or {}
	    game._GUIMan:Open("CPanelUIDamage", data)
    elseif id == "Btn_Reward" then
        self:OnBtnReward()
	elseif id == "Btn_Buy" then
	    local hasOpen = false
	    for _, state in pairs(self._Data._Opened) do
		    if state then
			    hasOpen = true
			    break
		    end
	    end
	    if not hasOpen then
		    -- 没有一个开启
		    game._GUIMan:ShowTipText(StringTable.Get(954), false)
		    return
	    end
	    -- 所有副本次数组共用，取1个计算
	    local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
	    local dungeon = CElementData.GetTemplate("Instance", dungeonTid)
	    game._CCountGroupMan:BuyCountGroup(game._DungeonMan:GetRemainderCount(dungeonTid) ,dungeon.CountGroupTid)
	elseif id == "Btn_Enter" then
        if self._Data._CurCount < 1 then
		    game._GUIMan:ShowTipText(StringTable.Get(8071), true)
		    return
	    end
   
	    local tid = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex].DungeonTID
        local instance_temp = CElementData.GetTemplate("Instance", tid)
        if instance_temp == nil then
            warn("error!!! 要进入的副本模板数据不存在")
            return
        end
        if instance_temp.MinEnterLevel > game._HostPlayer._InfoData._Level then
            game._GUIMan:ShowTipText(string.format(StringTable.Get(22415), instance_temp.MinEnterLevel), true)
            return
        end
        if not game._CFunctionMan:IsUnlockByFunTid(92) then
            game._GUIMan:ShowTipText(StringTable.Get(20060), true)
            return
        end
	    local protocol = (require "PB.net".C2SGuildExpeditionEnter)()
	    protocol.DungeonTID = tid
	    PBHelper.Send(protocol)
        game:StopAllAutoSystems()
	elseif id == "Btn_QuickJoin" then
		if self._Data._CurCount < 1 then
		    game._GUIMan:ShowTipText(StringTable.Get(8071), true)
		    return
	    end
	    if game._HostPlayer:InTeam() then
		    game._GUIMan:ShowTipText(StringTable.Get(22018), false)
	    else
		    -- 进入对应的组队界面
		    game._GUIMan:Open("CPanelUITeamCreate", nil)
	    end
    elseif id == "Btn_Open" then
        if game._HostPlayer:IsInGlobalZone() then
            game._GUIMan:ShowTipText(StringTable.Get(15556), false)
            return
        end
        local protocol = (require "PB.net".C2SGuildExpeditionOpen)()
	    protocol.ExpeditionId = self._Data._Template[self._PageIndex].Id
	    PBHelper.Send(protocol)
    elseif id == "Btn_Rule" then
        game._GUIMan:Open("CPanelUIDungeonIntroduction", EXPEDITION_POPUP_TID)
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_Dungeon" then
		local data = self._Data._Template[index]
        local img_selected = uiTemplate:GetControl(0)
        local lab_name = uiTemplate:GetControl(1)
        local lab_open = uiTemplate:GetControl(2)
        local img_lock = uiTemplate:GetControl(3)
        local img_red_point = uiTemplate:GetControl(4)
        local lab_not_open = uiTemplate:GetControl(5)
        img_selected:SetActive(false)
        lab_open:SetActive(false)
        img_lock:SetActive(false)
        img_red_point:SetActive(false)
        lab_not_open:SetActive(false)
		GUI.SetText(lab_name, data.Name)
        if index == self._PageIndex then
            img_selected:SetActive(true)
        end
		local guild = game._HostPlayer._Guild
        -- 已经解锁了
		if self._Building._BuildingLevel >= data.GuildLevel then
            img_lock:SetActive(false)
			if self._Data._Opened[data.Id] then
				lab_open:SetActive(true)
			else
                lab_open:SetActive(false)
			end
            local expedition = self._Data._Template[index]
            local should_show_red = false
            for i = 1,3 do
                local dungeonTid = expedition.DungeonDatas[i].DungeonTID
		        local passed = self._Data._Passed[dungeonTid]
		        if passed and not self._Data._Rewarded[dungeonTid] then 
                    should_show_red = true
                end
            end
            img_red_point:SetActive(should_show_red)
            lab_not_open:SetActive(not self._Data._HasOpened)
		else
            img_lock:SetActive(true)
            img_red_point:SetActive(false)
		end
	elseif id == "List_Reward" then
		local data = self._RewardData[index]
        if data.IsTokenMoney then
            IconTools.InitTokenMoneyIcon(uiTemplate:GetControl(0), data.Data.Id, data.Data.Count)
        else
		    local setting =
		    {
			    [EItemIconTag.Probability] = data.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
		    }
		    IconTools.InitItemIconNew(uiTemplate:GetControl(0), data.Data.Id, setting)
        end
	end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_Dungeon" then
        if self._PageIndex == index then return end
		self._PageIndex = index
        self:RequestDamageInfo()
		self:UpdatePanel()
	elseif id == "List_Reward" then
        local data = self._RewardData[index]
        if data.IsTokenMoney then
            local panelData = 
			{
				_MoneyID = data.Data.Id,
				_TipPos = TipPosition.FIX_POSITION,
				_TargetObj = item, 
			} 
			CItemTipMan.ShowMoneyTips(panelData)
        else
		    local itemTid = self._RewardData[index].Data.Id
		    CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
        end
	end
end

-- 购买副本次数后刷新
def.method().ShowBtnBuy = function(self)
    local dungeonTid = self._Data._Template[1].DungeonDatas[1].DungeonTID
    self._Data._CurCount = game._DungeonMan:GetRemainderCount(dungeonTid)
    UpdateBottomPanel(self)
end

-- 领取奖励
def.method().OnBtnReward = function(self)
	local tid = self._Data._Template[self._PageIndex].DungeonDatas[self._BossIndex].DungeonTID
    local passed = self._Data._Passed[tid]
    if passed then
        if not self._Data._Rewarded[tid] then 
	        local protocol = (require "PB.net".C2SGuildExpeditionDungeonReward)()
	        protocol.DungeonTID = tid
	        PBHelper.Send(protocol)
        end
    else
--        if self._Data._HasOpened and self._Data._CurExpeditionIndex == self._PageIndex then
--            local expedition = self._Data._Template[self._PageIndex]
--            local reward_id = expedition.DungeonDatas[self._BossIndex].RewardID
--            game._GUIMan:Open("CPanelGuildDungeonReward", reward_id)
--        end
        local expedition = self._Data._Template[self._PageIndex]
        local reward_id = expedition.DungeonDatas[self._BossIndex].RewardID
        game._GUIMan:Open("CPanelGuildDungeonReward", reward_id)
    end
end

-- 展示领取奖励
def.method("number").OnShowBtnReward = function(self, tid)
	self._Data._Rewarded[tid] = true
    self:UpdatePanel()
end

-- 当摧毁
def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	instance = nil
end


CPanelUIGuildDungeon.Commit()
return CPanelUIGuildDungeon