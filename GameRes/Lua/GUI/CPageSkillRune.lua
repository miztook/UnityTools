local Lplus             = require "Lplus"
local CElementSkill     = require "Data.CElementSkill"
local PBHelper          = require "Network.PBHelper"
local DynamicText       = require "Utility.DynamicText"
local CElementData      = require "Data.CElementData"

local CGame             = Lplus.ForwardDeclare("CGame")

local CPageSkillRune    = Lplus.Class("CPageSkillRune")
local def               = CPageSkillRune.define

def.field("table")._Parent                  = nil
def.field("userdata")._FrameRoot            = nil

def.field("table")._SkillToggle             = BlankTable                    -- 根据技能Id存储8个技能Toggle
def.field("table")._RuneToggle              = BlankTable                     -- 根据纹章Id存储3个纹章Toggle
def.field("table")._Img_RuneIcon            = BlankTable
--最外层大框
def.field("userdata")._FrameSkillCenter     = nil
def.field("userdata")._Frame_RuneInfo       = nil
def.field("userdata")._RunePlanGroup        = nil

--纹章框相关 
def.field("userdata")._Lab_RuneDes          = nil
def.field("userdata")._Lab_Config_Enabled   = nil
def.field("userdata")._Img_Lock3            = nil  
def.field("userdata")._Img_Lock4            = nil
def.field("userdata")._Lab_Config_Enabled2  = nil
def.field("userdata")._Img_Lock0            = nil
def.field("userdata")._Text0                = nil  -- 变量命名，差评！！ 
def.field("userdata")._Text1                = nil  -- 变量命名，差评！！
def.field("userdata")._RuneUnLockBtn        = nil
def.field("userdata")._RuneUpgradeBtn       = nil
def.field("userdata")._RuneConfigBtn        = nil
def.field("userdata")._RuneUnlockBtnEff     = nil
def.field("userdata")._BtnRuneCost          = nil
def.field("userdata")._RuneCostIcon         = nil      
def.field("userdata")._RuneUpdBtnEff        = nil
def.field("userdata")._UpdateInfoPanel      = nil
def.field("userdata")._MaxDes               = nil

def.field("table")._CurrentPlaySfxUI        = BlankTable    -- 当前播放UI特效
def.field("table")._PlaneStateControler     = BlankTable    -- 纹章策略按钮

-- 技能框相关
def.field("userdata")._UpgradeBtn           = nil 
def.field("userdata")._SkillLine1           = nil
def.field("userdata")._SkillLine2           = nil
def.field("userdata")._BtnUpdSkillRoot      = nil
def.field("userdata")._SkillUpdBtnEff       = nil

def.field("number")._RuneConfigTwoUnlimitLevel      = 0
def.field("number")._RuneConfigThreeUnlimitLevel    = 0
def.field("number")._SelectedRuneIndex              = 1     -- 当前选中纹章
def.field("number")._SelectedPlanIndex              = 1     -- 当前选中纹章配置

def.const("number").RuneMaxLevel                   = 6   
def.const("number").PlaneCount                     = 3     -- 纹章策略数量上限
def.const("number").SkillTotalCount                = 8     -- 技能数量上限 
def.const("number").RuneValueFlag                  = 10    -- 

-- 特效需要逻辑
def.field("boolean")._TotalRuneStateChange          = false 
def.field("boolean")._SpecialRuneStateChange        = false
def.field("userdata")._BG                           = nil
def.field("table")._RuneTagCache                    = BlankTable

def.field("table")._BagRuneInfo                     = BlankTable	-- 背包纹章信息
def.field("table")._DefaultRuneInfo                 = BlankTable    -- 默认展示纹章信息

def.field("table")._SkillInfo                       = BlankTable    -- 技能id为key，技能信息为value
def.field("table")._SkillConditionInfo              = BlankTable    -- 技能位置为key，技能配置为value


def.field("boolean")._IsShown   = false
local RuneIconNameDic = {}
local RuneIconDotNameDic = {}

def.static("table", "=>", CPageSkillRune).new = function(root)
	local obj = CPageSkillRune()
	obj._Parent = root
	obj:Init()
    return obj 
end

def.method().Init = function(self)
    self._BG = self._Parent:GetUIObject("BG")
    self._Frame_RuneInfo = self._Parent:GetUIObject("Frame_RuneInfo") -- 纹章信息、装配、升级模块
    self._RunePlanGroup = self._Parent:GetUIObject("RunePlanGroup") -- Plane
    self._FrameSkillCenter = self._Parent:GetUIObject("Frame_Skill") -- 技能面板
    self._Lab_RuneDes = self._Parent:GetUIObject("Lab_RuneDes")
    self._Text0 = self._Parent:GetUIObject("Text0")
    self._Text1 = self._Parent:GetUIObject("Text1")
    self._RuneUnLockBtn = self._Parent:GetUIObject("Btn_UnLock")
    self._RuneUpgradeBtn = self._Parent:GetUIObject("Btn_UpgradeRune")
    self._RuneConfigBtn = self._Parent:GetUIObject("Btn_ConfigRune")
    self._RuneUpdBtnEff = self._Parent:GetUIObject("Rune_Btn_Effect")
    self._RuneUnlockBtnEff = self._Parent:GetUIObject("RuneUnlock_Btn_Effect")  
    self._BtnRuneCost = self._Parent:GetUIObject("Btn_Rune_Cost")
    self._RuneCostIcon = self._Parent:GetUIObject("Rune_Cost_Icon")
    self._UpgradeBtn = self._Parent:GetUIObject("Btn_UpgradeSkill")
    self._SkillLine1 = self._Parent:GetUIObject("Skill_Line1")
    self._SkillLine2 = self._Parent:GetUIObject("Skill_Line2")
    self._BtnUpdSkillRoot = self._Parent:GetUIObject("Btn_UpgradeSkill")
    self._SkillUpdBtnEff = self._Parent:GetUIObject("SKill_Btn_Effect")
    self._UpdateInfoPanel = self._Frame_RuneInfo:FindChild("Frame_Des")
    local updateInfoRune = self._UpdateInfoPanel:FindChild("Lab_Des_2") -- 纹章效果升级数据预览
    GUI.SetText(updateInfoRune, StringTable.Get(177))
    local updateInfoElement = self._UpdateInfoPanel:FindChild("Lab_Des_1") -- 纹章效果升级元素预览
    GUI.SetText(updateInfoElement, StringTable.Get(178))
    self._MaxDes = self._Frame_RuneInfo:FindChild("Lab_Max_Des")

    -- Plane按钮
    self._Img_Lock3 = self._Parent:GetUIObject("Img_Lock10")
    self._Img_Lock4 = self._Parent:GetUIObject("Img_Lock11")

    for i = 1, CPageSkillRune.PlaneCount do
        local plan = {}
        plan.ShowText = self._RunePlanGroup:FindChild("Rdo_RunePlan".. i .. "/PlanTag")
        GUI.SetText(plan.ShowText, StringTable.Get(179 + i))
        plan.ShowTag = self._RunePlanGroup:FindChild("Rdo_RunePlan".. i .. "/Lab_Config_Enabled")
        plan.BtnBG = self._RunePlanGroup:FindChild("Rdo_RunePlan".. i .. "/BtnBG")
        self._PlaneStateControler[i] = plan
    end

    local isArcher = game._HostPlayer._InfoData._Prof == EnumDef.Profession.Archer
    if not isArcher then
        local rdo7 = self._Parent:GetUIObject("Rdo_Skill7")
        local rdo9 = self._Parent:GetUIObject("Rdo_Skill9")
        if not IsNil(rdo7) and not IsNil(rdo9) then
            rdo7.localPosition = rdo9.localPosition
        end
    end

    local runeGOName = nil
    for i = 1, 8 do
        self._SkillToggle[i] = {}       
        if i ~= 8 then
            runeGOName = "Img_RuneIcon" .. (i - 1)
            self._SkillToggle[i]._GameObject = self._Parent:GetUIObject("Rdo_Skill" .. i)
            self._Img_RuneIcon[i] = self._Parent:GetUIObject(runeGOName)
        else            
            self._Parent:GetUIObject("Rdo_Skill" .. i):SetActive(false)
            self._Parent:GetUIObject("Rdo_Skill" .. (i + 1)):SetActive(false)
            self._Parent:GetUIObject("Img_RuneIcon" .. (i - 1)):SetActive(false)
            self._Parent:GetUIObject("Img_RuneIcon" .. i):SetActive(false)
            -- 通用
            if not isArcher then
                runeGOName = "Img_RuneIcon" .. (i - 1)
                self._Parent:GetUIObject("Rdo_Skill" .. i):SetActive(true)
                self._SkillToggle[i]._GameObject = self._Parent:GetUIObject("Rdo_Skill" .. i)
                self._Parent:GetUIObject("Img_RuneIcon" .. (i - 1)):SetActive(true)
                self._Img_RuneIcon[i] = self._Parent:GetUIObject(runeGOName)
            -- 弓箭手
            else
                runeGOName = "Img_RuneIcon" .. i
                self._Parent:GetUIObject("Rdo_Skill" .. (i + 1)):SetActive(true)
                self._SkillToggle[i]._GameObject = self._Parent:GetUIObject("Rdo_Skill" .. (i + 1))
                self._Parent:GetUIObject("Img_RuneIcon" .. i):SetActive(true)
                self._Img_RuneIcon[i] = self._Parent:GetUIObject("Img_RuneIcon" .. i)
            end
        end
        RuneIconNameDic[runeGOName] = self._Img_RuneIcon[i]
        RuneIconDotNameDic[self._Img_RuneIcon[i]] = runeGOName
        self._Img_RuneIcon[i]:SetActive(false)
    end

    for i = 1, 3 do
        self._RuneToggle[i] = {}
        self._RuneToggle[i]._GameObject = self._Parent:GetUIObject("Rdo_Rune" .. i)
        self._RuneToggle[i]._GameObject:FindChild("Img_RuneIcon_R/Img_LevelUp"):SetActive(false)
    end

    self._RuneConfigTwoUnlimitLevel = CSpecialIdMan.Get("RuneConfigTwoUnlimitLevel")
    self._RuneConfigThreeUnlimitLevel = CSpecialIdMan.Get("RuneConfigThreeUnlimitLevel")

    self:SetRdoRunePlan()
end

def.method().InitPlanBtnState = function(self)
    local playerLevel = game._HostPlayer._InfoData._Level

    local active = playerLevel >= self._RuneConfigTwoUnlimitLevel
    self._Img_Lock3:SetActive(not active)
    self._PlaneStateControler[2].ShowText:SetActive(active)

    active = playerLevel >= self._RuneConfigThreeUnlimitLevel
    self._Img_Lock4:SetActive(not active)
    self._PlaneStateControler[3].ShowText:SetActive(active)
end

def.method().SetRdoRunePlan = function(self)
    self:InitPlanBtnState()
    self._SelectedPlanIndex = game._HostPlayer._ActiveRuneConfigId + 1
    self:UpdatePlanBtnState(self._SelectedPlanIndex)
end

def.method("number").Show = function (self,tid)
	if self._IsShown then return end
    self:Update()
    if tid ~= -1 then
        local userSkillMap = game._HostPlayer._UserSkillMap
        local skillId = CElementSkill.GetRune(tid).SkillId
        for i = 1, #self._SkillToggle do
            if self._SkillToggle[i]._Tid == skillId then
                if self._SkillToggle[i]._IsLearned then
                    local runeInfo = self._SkillToggle[i]._RuneInfo
                    for k, v in pairs(runeInfo) do
                        if v._Tid == tid then
                            self:OnToggleSkill("Rdo_Skill" .. i)
                            self:OnToggleRune("Rdo_Rune" .. k)
                        end
                    end 
                else
                    game._GUIMan:ShowTipText(StringTable.Get(111), true)
                end                 
            end
        end
    end

    self._IsShown = true
end

def.method().Update = function (self)
    self._Frame_RuneInfo:SetActive(true)
    self._RunePlanGroup:SetActive(true)
    self._FrameSkillCenter:SetActive(true)

    self:InitInfo()
    self:UpdateRuenData()
    self:InitSkillShow()
    self:InitRuenShow()
    self:UpdateSkillSmallRuenShow()
    self:UpdateRuneInfoShow()

    self:InitPlanBtnState()
    self._SpecialRuneStateChange = false;
end

def.method("string").OnClick = function (self, id)
    if id == "ZL_Btn" then
        game._GUIMan:Open("CPanelRuneExpress", nil)
    elseif id == "Rdo_RunePlan1" then
        self._TotalRuneStateChange = true
        self:OnRdoRunePlan1()
    elseif id == "Rdo_RunePlan2" then
        self._TotalRuneStateChange = true   
        self:OnRdoRunePlan2()    
    elseif id == "Rdo_RunePlan3" then
        self._TotalRuneStateChange = true
        self:OnRdoRunePlan3()
    elseif id == "Btn_UpgradeRune" then
        self:OnBtnUpgradeRune()
    elseif id == "Btn_ConfigRune" then
        self:OnBtnConfigRune()
    elseif id == "Btn_UnLock" then
        self:OnBtnUnlockRune()
    elseif string.find(id, "Rdo_Skill") then
        self:OnToggleSkill(id)
    elseif string.find(id, "Rdo_Rune") then
        self:OnToggleRune(id)
    elseif id == 'Btn_Rune_Cost' then       
        self:ShowRuneCostTip()
    end  
end

-------------------------------------------------------------------------------------------------------------
def.method().InitInfo = function (self)
    self._SkillInfo = {}
    self._SkillConditionInfo = {}

    local userSkillMap = game._HostPlayer._UserSkillMap
    -- 目前学习了技能的信息
    for k, v in pairs(userSkillMap) do
        self._SkillInfo[v.SkillId] = v
    end
    -- 技能配置信息缓存,
    local learnCondition = game._HostPlayer._SkillLearnCondition
    for k, v in pairs(learnCondition) do
        local SkillUIPos = v.SkillUIPos
        if SkillUIPos >= 1 and SkillUIPos <= CPageSkillRune.SkillTotalCount then -- 1~8
            self._SkillConditionInfo[SkillUIPos] = v
        end
    end
    
	-- 纹章基础信息
	local allRune = GameUtil.GetAllTid("Rune")
	for i, v in ipairs(allRune) do
		local rune = CElementSkill.GetRune(v)
		self._DefaultRuneInfo[rune.SkillId .. rune.UiPos] = v
	end
end

def.method().InitSkillShow = function (self)
    for k, v in pairs (self._RuneTagCache) do
        GameUtil.StopUISfx(v.path, v.parent)
    end
    for i = 1, CPageSkillRune.SkillTotalCount do
        self._SkillToggle[i]._GameObject:FindChild("Img_U/Img_SkillIcon/Img_D"):SetActive(i == self._Parent._SelectedSkillIndex)
        
        local go = self._SkillToggle[i]._GameObject
        go:FindChild("Img_U/Img_SkillIcon/Lab_Level_Bg"):SetActive(false)
        go:FindChild("Img_LevelUp"):SetActive(false)
        
    end
end

def.method().InitRuenShow = function (self)
    -- TODO  应该不需要
    self:StopAllRuneIconUISfx()
end

-- 初始化背包基础信息(为监测背包道具变化)
def.method().InitBagRuneInfo = function(self)
	self._BagRuneInfo = {}
	local normalPack = game._HostPlayer._Package._NormalPack
    for i, v in ipairs(normalPack._ItemSet) do
    	local tid = v._Tid
    	if tid ~= 0 then
    		local item = CElementData.GetTemplate("Item", tid)
    		if item.ItemType == 5 then
    			local itemBag = normalPack:GetItem(tid)
    			if itemBag:CanUse() == 0 then
                    self._BagRuneInfo[#self._BagRuneInfo + 1] = { _Tid = tid, _RuneId = tonumber(item.Type1Param1), _RuneLevel = tonumber(item.Type1Param2) }
    			end
    		end
    	end
    end
end

def.method("number", "number", "=>", "table").HadRune = function (self, runeID, runeLevel)
    for k, v in ipairs(self._BagRuneInfo) do
        if v._RuneId == runeID and v._RuneLevel == runeLevel then
            return v
        end
    end
    return nil
end

def.method().UpdateRuenData = function (self)
	-- 背包纹章道具信息
	self:InitBagRuneInfo()

    for k, v in pairs(self._SkillConditionInfo) do
        local skill = CElementSkill.Get(v.SkillId)
        self._SkillToggle[v.SkillUIPos]._Tid = skill.Id
        self._SkillToggle[v.SkillUIPos]._IsLearned = false
        local go = self._SkillToggle[v.SkillUIPos]._GameObject
        -- 技能图标
        local skillIcon = go:FindChild("Img_U/Img_SkillIcon")
        GUITools.SetSkillIcon(skillIcon, skill.IconName)
    end

    local hp = game._HostPlayer
    local normalPack = hp._Package._NormalPack
    local skillPoseToInfo = hp._MainSkillIDList
    for k, v in pairs(skillPoseToInfo) do
        self._SkillToggle[k]._IsLearned = (self._SkillInfo[v] ~= nil) -- 如果学习过的技能索引里面含有这个技能则已经学习
        if self._SkillInfo[v] then
            local SkillRuneInfoDatas = self._SkillInfo[v].SkillRuneInfoDatas
            local runeInfo = {}
            for m, n in ipairs(SkillRuneInfoDatas) do
                local rune = CElementSkill.GetRune(n.runeId)
                if rune.UiPos >= 1 and rune.UiPos <= 3 then
                    local level = n.level
                    local Info = {}
                    Info._IsOwn = true
                    Info._Tid = n.runeId
                    Info._Level = level
                    Info._IsActivity = n.isActivity

                    Info._IsUpgrade = false
                    Info._IsMax = (level >= CPageSkillRune.RuneMaxLevel)
                    local sl = math.fmod( level, 3 )
                    
                    if Info._IsMax then
                        Info._IsUpgrade = false
                    else
                        Info._UpdItemId, Info._UpdItemNeed, Info._BagNum = self:RuneCanUpgrade(n.runeId, level + 1)
                        Info._IsUpgrade = Info._BagNum >= Info._UpdItemNeed
                        if sl == 0 then
                            local runeInfo = self:HadRune(n.runeId, n.level + 1)
                            if runeInfo then
                                Info._IsUpgrade = true
                                Info._Item = normalPack:GetItem(runeInfo._Tid)
                            end
                        end
                    end
                    runeInfo[rune.UiPos] = Info
                end
            end
            for i = 1, 3 do
                if not runeInfo[i] then
                    local tid = self._DefaultRuneInfo[v .. i]
                    if IsNil(tid) then
                        warn("DefaultRuneInfo is Null " .. v .. i)
                    end
                    runeInfo[i] = self:MakeRuneInfo(tid)
                    local runeInfoTemp = self:HadRune(tid, 1)
                    if runeInfoTemp then
                        runeInfo[i]._IsUpgrade = true
                        runeInfo[i]._Item = normalPack:GetItem(runeInfoTemp._Tid)
                    end
                end
            end
            self._SkillToggle[k]._RuneInfo = runeInfo
        else
            local runeInfo = {}
            for i = 1, 3 do
                local tid = self._DefaultRuneInfo[v .. i]
                if IsNil(tid) then
                    warn("DefaultRuneInfo is Null " .. v .. i)
                end
                runeInfo[i] = self:MakeRuneInfo(tid)
            end
            self._SkillToggle[k]._RuneInfo = runeInfo
        end
    end
end

def.method("number", "=>", "table").MakeRuneInfo = function (self, runeID)
    local Info = {}
    Info._IsOwn = false
    Info._Tid = runeID
    Info._Level = 0
    Info._IsActivity = false
    Info._IsUpgrade = false
    Info._IsMax = false
    Info._UpdItemId, Info._UpdItemNeed, Info._BagNum = self:RuneCanUpgrade(runeID, 1)
    return Info
end

def.method("number", "number", "=>", "number", "number", "number").RuneCanUpgrade = function (self, runeID, runeLevel)
    local rune_data = CElementSkill.GetRune(runeID)
    local item_ids = string.split(rune_data.RuneUpdItems, "*")
    -- 升级所需物品ID
    local upd_itemid = item_ids[runeLevel]
    upd_itemid = tonumber(upd_itemid)
    -- 背包中现有数量
    local pack = game._HostPlayer._Package._NormalPack
    local bag_num = pack:GetItemCount(upd_itemid)
    -- 升级所需数量
    local upd_counts = string.split(rune_data.RuneUpdItemCount, "*")
    local upd_itemNeed = upd_counts[runeLevel]
    upd_itemNeed = tonumber(upd_itemNeed)

    if upd_itemNeed == nil then  upd_itemNeed = 0 end
    if bag_num == nil then  bag_num = 0 end
    return upd_itemid, upd_itemNeed, bag_num
end

-- 纹章信息显示更新
def.method().UpdateRuneInfoShow = function (self)
    local SelectedSkillIndex = self._Parent._SelectedSkillIndex
    for i = 1, 3 do
        local go = self._RuneToggle[i]._GameObject
        local ImgEquipedGO = go:FindChild("Img_Equiped")
        local img_Rune = go:FindChild("Img_RuneIcon_R")
        local img_LevelUp = go:FindChild("Img_RuneIcon_R/Img_LevelUp")
        local info
        local runeInfo = self._SkillToggle[SelectedSkillIndex]._RuneInfo
        if runeInfo then
            info = runeInfo[i]
            -- 佩戴角标
            if info._IsActivity then
                ImgEquipedGO:SetActive(true)
            else
                ImgEquipedGO:SetActive(false)
            end
            local isHas = info._Level > 0
            self:MakeImgRuneIconEnable(img_Rune, isHas)
            local RuneName
            local RuneLevel
            if isHas then
                local rune = CElementSkill.GetRune(info._Tid)
                GUITools.SetSkillIcon(img_Rune, rune.RuneIcon)
                RuneName = rune.Name
                RuneLevel = info._Level
                go:FindChild("Img_RuneIcon_R/Img_Lock_R"):SetActive(false)
                -- 升级提示箭头
                if info._IsUpgrade then
                    img_LevelUp:SetActive(true)
                else
                    img_LevelUp:SetActive(false)
                end
            else -- 还没有这个纹章
                go:FindChild("Img_RuneIcon_R/Img_Lock_R"):SetActive(true)
                local skillId = self._SkillToggle[SelectedSkillIndex]._Tid
                local tid = self._DefaultRuneInfo[skillId .. i]
                local rune = CElementSkill.GetRune(tid)
                GUITools.SetSkillIcon(img_Rune, rune.RuneIcon)
                RuneName = rune.Name
                RuneLevel = 0
                -- 升级提示箭头
                if info._IsUpgrade then
                    img_LevelUp:SetActive(true)
                else
                    img_LevelUp:SetActive(false)
                end
            end
            local rune_level = ""
            if RuneLevel == 0 then
                rune_level = "<color=#808080>" ..StringTable.Get(20808) .."</color>"
            else
                local sl = math.fmod( RuneLevel, 3 )
                sl = sl == 0 and 3 or sl
                rune_level = RichTextTools.GetRuneColorText(RuneLevel) .. string.format(StringTable.Get(10714), sl)
            end
            GUI.SetText(go:FindChild("Img_RuneIcon_R/Lab_RuneName"), RuneName)
            GUI.SetText(go:FindChild("Img_RuneIcon_R/Lab_RuneLevel"), rune_level)
        end  
    end
    self:OnShowRuneInfo() 
    self._Parent:UpdateTabRedDotState()   
end

-- 技能图标上面的纹章信息显示更新
def.method().UpdateSkillSmallRuenShow = function (self)
    local skillPoseToInfo = game._HostPlayer._MainSkillIDList
    for k, v in pairs(skillPoseToInfo) do
        -- 选中标志的光圈
        self._SkillToggle[k]._GameObject:FindChild("Img_U/Img_SkillIcon/Img_D"):SetActive(k == self._Parent._SelectedSkillIndex)

        local go = self._SkillToggle[k]._GameObject
        -- 解锁图标
        local skillLock = go:FindChild("Img_U/Img_SkillLock")
        -- 技能图标
        local skillIcon = go:FindChild("Img_U/Img_SkillIcon")
        skillIcon:SetActive(true)
        -- 技能是否学习，更新UI
        if self._SkillToggle[k]._IsLearned then
            skillLock:SetActive(false)
            GameUtil.MakeImageGray(skillIcon, false)
            self:UpdateSkillLine(k, true)

            -- 更新纹章小图标信息
            self._Img_RuneIcon[k]:SetActive(false)
            for m, n in pairs(self._SkillInfo[v].SkillRuneInfoDatas)do
                if n.isActivity then
                    self._Img_RuneIcon[k]:SetActive(true)
                    -- 设置小图标
                    local icon = CElementSkill.GetRune(n.runeId).RuneSmallIcon
                    GUITools.SetSkillIcon(self._Img_RuneIcon[k], icon)
                    -- 满级之后会有特效
                    if n.level >= CPageSkillRune.RuneMaxLevel then
                        local path = string.gsub(icon .. ".prefab", PATH.UIFX_RuneIconTag, PATH.UIFX_RuneIconSmallTag)
                        local cache = {path = path, parent = self._Img_RuneIcon[k]}
                        self._RuneTagCache[k] = cache
                        GameUtil.PlayUISfx(path, self._Img_RuneIcon[k], self._Img_RuneIcon[k], -1)
                    end
                    -- 切换策略之后整体会有特效显示
                    if self._TotalRuneStateChange and not game._HostPlayer:IsInServerCombatState()then
                        self._Img_RuneIcon[k].parent:GetComponent(ClassType.DOTweenPlayer):Restart(RuneIconDotNameDic[self._Img_RuneIcon[k]])
                    elseif self._SpecialRuneStateChange and k == self._Parent._SelectedSkillIndex then
                        self._Img_RuneIcon[k].parent:GetComponent(ClassType.DOTweenPlayer):Restart(RuneIconDotNameDic[self._Img_RuneIcon[k]])
                    end
                    break  
                end
            end
        else
            skillLock:SetActive(true)
            GameUtil.MakeImageGray(skillIcon, true, nil)
            self:UpdateSkillLine(k, false)

            if self._SkillConditionInfo[k].RoleLearnType == 0 then
                GUI.SetText(go:FindChild("Img_U/Img_SkillLock/Lab_LockLevel"), string.format(StringTable.Get(10714), self._SkillConditionInfo[k].RoleLearnParam))
            else
                GUI.SetText(go:FindChild("Img_U/Img_SkillLock/Lab_LockLevel"), StringTable.Get(166))                        
            end
        end
        local runeInfo = self._SkillToggle[k]._RuneInfo
        local img_LevelUp = go:FindChild("Img_LevelUp")
        local isLevelUp = false
        for k, v in pairs(runeInfo) do
            if v._IsUpgrade then
                isLevelUp = true
            end
        end
        img_LevelUp:SetActive(isLevelUp)
    end
end

def.method().OnShowRuneInfo = function(self)
    self._RuneToggle[self._SelectedRuneIndex]._GameObject:FindChild("Img_D"):SetActive(true)
    local runeToggle = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex]
    local runeLevelDes = runeToggle._Level
    if runeLevelDes == 0 then
        runeLevelDes = 1
    end
    local runeDes = DynamicText.ParseRuneDescText(runeToggle._Tid, runeLevelDes)
    local runeDes2 = ""

    local runeTemplate = CElementData.GetTemplate("Rune", runeToggle._Tid)
    if runeTemplate ~= nil then
        runeDes2 = DynamicText.ParseRuneDescSpecial(runeToggle._Tid, runeLevelDes, runeTemplate.SkillWithRuneDes2)
    end
    runeDes = runeDes .. "\n" .. runeDes2

     
    GUI.SetText(self._Lab_RuneDes, runeDes)

    local canUpgrade = not runeToggle._IsMax
    self._UpdateInfoPanel:SetActive(canUpgrade)
    self._MaxDes:SetActive(not canUpgrade)

    local makeShow = function(parsedText, val, isRune)
        local tag = "runelevelup1%%"
        if not isRune then
            tag = "runelevelup10%%"
        end
        local isFloat = string.find(parsedText, tag)
        if isFloat then
            val = val * 100
        end
        val = math.abs(val)
        local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
        if isFloat then
            replStr = string.format("%s%%", replStr)
        end
        return replStr
    end

    local runeUpgradeText = self._RuneUpgradeBtn:FindChild("Img_Bg/Text")
    local sl = math.fmod( runeToggle._Level, 3 )
    local showRuneUpgradeText = StringTable.Get(158)
    if sl == 0 then
        showRuneUpgradeText = StringTable.Get(179)
    end
    GUI.SetText(runeUpgradeText, showRuneUpgradeText)

    if canUpgrade then
        local runeId = runeToggle._Tid
        local runeLevel = runeToggle._Level
        local runeTemplate = CElementData.GetTemplate("Rune", runeId)
        local parsedText = runeTemplate.RuneDescription
        local parsedText1 = runeTemplate.SkillWithRuneDes2
        local valnow = CElementSkill.GetRuneLevelUpValue(runeId, 1, runeLevel)
        valnow = makeShow(parsedText, valnow, true)
        local valnext = CElementSkill.GetRuneLevelUpValue(runeId, 1, runeLevel + 1)
        valnext = makeShow(parsedText, valnext, true)
        local rune = self._UpdateInfoPanel:FindChild("Lab_Des_2")
        local rnow = rune:FindChild("Lab_SkillNow")
        GUI.SetText(rnow, valnow)
        local rnext = rune:FindChild("Lab_SkillNext")
        GUI.SetText(rnext, valnext)
        -- 
        valnow = CElementSkill.GetRuneLevelUpValue(runeId, CPageSkillRune.RuneValueFlag, runeLevel)
        valnow = makeShow(parsedText1, valnow, false)
        valnext = CElementSkill.GetRuneLevelUpValue(runeId, CPageSkillRune.RuneValueFlag, runeLevel + 1)
        valnext = makeShow(parsedText1, valnext, false)

        local ele = self._UpdateInfoPanel:FindChild("Lab_Des_1")
        local enow = ele:FindChild("Lab_SkillNow")
        GUI.SetText(enow, valnow)
        local enext = ele:FindChild("Lab_SkillNext")
        GUI.SetText(enext, valnext)
    end

    
    self._RuneUnLockBtn:SetActive(false)
    self._RuneUpgradeBtn:SetActive(false)
    self._RuneConfigBtn:SetActive(false)
    self._BtnRuneCost:SetActive(false)
    self:SetRuneLockBtnState(runeToggle._Level < 1)

    if runeToggle._IsOwn then
        if runeToggle._IsActivity then
            GUI.SetText(self._Text1, StringTable.Get(161))
        else
            GUI.SetText(self._Text1, StringTable.Get(160))      
        end
    else
        if runeToggle._IsUpgrade then                                   
            self:SetUpdBtnEffect(5, true)
        else            
            self:SetUpdBtnEffect(5, false)
        end 
    end
    -- 满级
    if not runeToggle._IsMax then
        self._BtnRuneCost:SetActive(true)
        local runeLevel = runeToggle._Level
        local upd_itemid = runeToggle._UpdItemId
        local upd_itemCount = runeToggle._UpdItemNeed
        local bag_num = runeToggle._BagNum
        if runeLevel < 1 then
            GUITools.SetBtnGray(self._RuneUnLockBtn, (bag_num < upd_itemCount))
        else
            local isActivity = bag_num >= upd_itemCount
            self:SetBtGray(self._RuneUpgradeBtn, not isActivity)
            self._RuneUpdBtnEff:SetActive(isActivity)
        end
        -- 设置升级所需材料ICON
        IconTools.InitMaterialIconNew(self._RuneCostIcon, upd_itemid, upd_itemCount)
    else
        self._BtnRuneCost:SetActive(false)
        self:SetBtGray(self._RuneUpgradeBtn, true)
        self._RuneUpdBtnEff:SetActive(false)
    end
    -- 如果技能都没学过就隐藏起来右边的纹章条件和解锁按钮
    if not self._SkillToggle[self._Parent._SelectedSkillIndex]._IsLearned then
        self._RuneUnLockBtn:SetActive(false)
        self._RuneUpgradeBtn:SetActive(false)
        self._RuneConfigBtn:SetActive(false)
        self._BtnRuneCost:SetActive(false)
    end
end

def.method("number", "boolean").UpdateSkillLine = function(self, index, is_learned)
    if index < 7 then
        return
    end
    
    local isArcher = game._HostPlayer._InfoData._Prof == EnumDef.Profession.Archer

    self._SkillLine1:SetActive(not isArcher)
    self._SkillLine2:SetActive(isArcher)
    
    local skillLine = isArcher and self._SkillLine2 or self._SkillLine1
    if index == 7 then
        skillLine:FindChild("line_Left"):SetActive(is_learned)
        skillLine:FindChild("line_Left_Gray"):SetActive(not is_learned)
    else
        skillLine:FindChild("line_Right"):SetActive(is_learned)
        skillLine:FindChild("line_Right_Gray"):SetActive(not is_learned)
    end
end

-- 技能Toggle(改为整体Button)
def.method("string").OnToggleSkill = function(self, id)
    for i = 1, 9 do
        local index = i
        if i == 9 then
            index = 8
        end
        if id == "Rdo_Skill" .. i then
            if index == self._Parent._SelectedSkillIndex then
                return
            end
            self._SkillToggle[self._Parent._SelectedSkillIndex]._GameObject:FindChild("Img_U/Img_SkillIcon/Img_D"):SetActive(false)
            self._SkillToggle[index]._GameObject:FindChild("Img_U/Img_SkillIcon/Img_D"):SetActive(true)
            self._Parent._SelectedSkillIndex = index
            self:UpdateRuneInfoShow()
            self._Parent:UpdateTabRedDotState()   
            return
        end
    end
end

-- 技能Toggle(改为整体Button)
def.method("string").OnToggleRune = function(self, id)
    for i = 1, 3 do
        if id == "Rdo_Rune" .. i then
            self._RuneToggle[self._SelectedRuneIndex]._GameObject:FindChild("Img_D"):SetActive(false)
            self._SelectedRuneIndex = i
            self:OnShowRuneInfo()
            return
        end
    end
end

def.method("userdata", "boolean").SetBtGray = function(self, bt, isGray)
    GUITools.SetBtnGray(bt, isGray)
    GameUtil.MakeImageGray(bt:FindChild("Img_Bg"), isGray)
end

def.method("boolean").SetRuneLockBtnState = function(self, is_show)
    if is_show then
        self._RuneUnLockBtn:SetActive(true)
    else
        self._RuneUpgradeBtn:SetActive(true)
        self._RuneConfigBtn:SetActive(true)
    end
end

def.method("userdata", "boolean").MakeImgRuneIconEnable = function(self, imgRuneIconGO, isEnable)
    local img = imgRuneIconGO:GetComponent(ClassType.Image)
    local alpha = 1
    if not isEnable then
        GameUtil.MakeImageGray(imgRuneIconGO, (not isEnable), nil)
        alpha = 0.2
    else
        GameUtil.MakeImageGray(imgRuneIconGO, (not isEnable))
    end
	GameUtil.ChangeGraphicAlpha(imgRuneIconGO, alpha)

    local text = imgRuneIconGO:FindChild("Lab_RuneName")
	GameUtil.ChangeGraphicAlpha(text, alpha)
end

def.method().OnRdoRunePlan1 = function(self)
    if self._SelectedPlanIndex == 1 then
        return
    end

    if game._HostPlayer:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), true)
    else
        self._SelectedPlanIndex = 1
        self:OnActiveRuneConfig(0)
        self:UpdatePlanBtnState(1)
        GameUtil.PlayUISfx(PATH.UIFX_WenZhangQieHuan, self._BG, self._BG, -1)
    end
end

-- 纹章方案二
def.method().OnRdoRunePlan2 = function(self)
    if self._SelectedPlanIndex == 2 then
        return
    end
    local hp = game._HostPlayer
    if hp:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), true)
    else
        local playerLevel = hp._InfoData._Level
        if playerLevel >= self._RuneConfigTwoUnlimitLevel then
            self._SelectedPlanIndex = 2
            self:OnActiveRuneConfig(1)
            self:UpdatePlanBtnState(2)
            GameUtil.PlayUISfx(PATH.UIFX_WenZhangQieHuan, self._BG, self._BG, -1)
        else
            game._GUIMan:ShowTipText(string.format(StringTable.Get(137), self._RuneConfigTwoUnlimitLevel), false)
        end
    end
end

-- 纹章方案三
def.method().OnRdoRunePlan3 = function(self)
    if self._SelectedPlanIndex == 3 then
        return
    end
    local hp = game._HostPlayer
    if hp:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), true)
    else
        if hp._InfoData._Level >= self._RuneConfigThreeUnlimitLevel then
            self._SelectedPlanIndex = 3
            self:OnActiveRuneConfig(2) 
            self:UpdatePlanBtnState(3)
            GameUtil.PlayUISfx(PATH.UIFX_WenZhangQieHuan, self._BG, self._BG, -1)
        else
            game._GUIMan:ShowTipText(string.format(StringTable.Get(137), self._RuneConfigThreeUnlimitLevel), false)
        end
    end
end

def.method("number").UpdatePlanBtnState = function(self, state)
    -- 背景
    local ColorPress = Color.New(0.98, 0.96, 0.72, 1)
    local ColorRex = Color.New(0.6, 0.71, 0.85, 1)
    local playerLevel = game._HostPlayer._InfoData._Level
    
    for i = 1, CPageSkillRune.PlaneCount do
        local isShow = false
        -- “已启用” 文字
        if i == state then
            isShow = true
        end
        local color = isShow and ColorPress or ColorRex
        GUI.SetTextColor(self._PlaneStateControler[i].ShowText, color)
        self._PlaneStateControler[i].ShowTag:SetActive(isShow)
        self._PlaneStateControler[i].BtnBG:SetActive(isShow)
    end
end

-- 显示纹章tip
def.method().ShowRuneCostTip = function(self)
    local runeToggle = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex]
    
    local rune_data = CElementSkill.GetRune(runeToggle._Tid)
    if rune_data then       
        local item_ids = string.split(rune_data.RuneUpdItems, "*")
        local upd_itemid = item_ids[1]
        if runeToggle._Level > 0 then
            upd_itemid = item_ids[runeToggle._Level + 1]
        end

        upd_itemid = tonumber(upd_itemid)           
        if upd_itemid and upd_itemid > 0 then
            CItemTipMan.ShowItemTips(upd_itemid, TipsPopFrom.OTHER_PANEL, self._BtnRuneCost, TipPosition.FIX_POSITION)
        end
    end
end

def.method("string", "string").OnDOTComplete = function(self, go_name, dot_id)
    if RuneIconNameDic[dot_id] then
        GameUtil.PlayUISfx(PATH.UIFX_RuneIconSmall, RuneIconNameDic[dot_id], RuneIconNameDic[dot_id], 1)
    end
end

def.method().OnChangeRuneConfig = function(self)
    self._TotalRuneStateChange = false
end

def.method("number", "boolean").SetUpdBtnEffect = function(self, btn_type, state)
    if btn_type == 1 then
        self._SkillUpdBtnEff:SetActive(state)
    elseif btn_type == 5 then                               -- prof upd btn all
        self._RuneUnlockBtnEff:SetActive(state)
    end
end

-- 点击纹章升级按钮
def.method().OnBtnUpgradeRune = function(self)
    local runeToggle = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex]--self._RuneToggle[self._SelectedRuneIndex]
    if runeToggle._IsOwn then
        if runeToggle._IsMax then
            game._GUIMan:ShowTipText(StringTable.Get(163), false)
            return          
        end
        local sl = math.fmod( runeToggle._Level, 3 )
        if runeToggle._IsUpgrade then
            self:PlayUISfx(2, self._SelectedRuneIndex)
            local runeToggleFxParent = self._RuneToggle[self._SelectedRuneIndex]._GameObject:FindChild("Img_RuneIcon_R")
            GameUtil.PlayUISfx(PATH.UIFX_WenZhangZhuanJingShengJi, runeToggleFxParent, runeToggleFxParent, -1)
            if sl == 0 then
                runeToggle._Item:RealUse()
            else
                game._GUIMan:ShowTipText(StringTable.Get(164), false)
                self:UpgradeRune(runeToggle._Tid)
            end
        else
            if sl == 0 then
                game._GUIMan:ShowTipText(StringTable.Get(128), false)
            else
                game._GUIMan:ShowTipText(StringTable.Get(176), false)
            end
        end
    end
end

-- 升级纹章
def.method("number").UpgradeRune = function(self, runeId)
    local protocol = (require "PB.net".C2SSkillOperateRuneInfo)()
    protocol.runeInfo.runeId = runeId
    protocol.runeInfo.IsLeveUp = true
    protocol.runeInfo.isActivity = false
    protocol.runeInfo.configId = game._HostPlayer._ActiveRuneConfigId
    PBHelper.Send(protocol)
end

def.method().OnBtnUnlockRune = function(self)
    local runeToggle = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex]--self._RuneToggle[self._SelectedRuneIndex]
    if runeToggle._IsUpgrade then
        runeToggle._Item:RealUse()
        self:StopUISfx(4, self._SelectedRuneIndex)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_RuneUnlock, 0)
    else
        game._GUIMan:ShowTipText(StringTable.Get(128), false)
    end
end

-- 装备纹章
def.method().OnBtnConfigRune = function(self)
    if game._HostPlayer:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), true)
    else
        local runeToggle = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex] --self._RuneToggle[self._SelectedRuneIndex]
        if runeToggle._IsOwn then
            self:PlayUISfx(2, self._SelectedRuneIndex)   
            if not runeToggle._IsActivity then
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_RuneEquip, 0)
            else
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipSkillRune, 0)
            end
            self:OnActiveRune(runeToggle._Tid, runeToggle._IsActivity)
            --TODO
            self._RuneToggle[self._SelectedRuneIndex]._GameObject:FindChild("Img_Equiped"):SetActive(true)
            self._RuneToggle[self._SelectedRuneIndex]._GameObject:GetComponent(ClassType.DOTweenPlayer):Restart("Img_Equiped")
        else
            game._GUIMan:ShowTipText(StringTable.Get(165), false)
        end
    end
end

-- 激活或者不激活纹章
def.method("number", "boolean").OnActiveRune = function(self, runeId, isActivity)
    if not isActivity then
        self._SpecialRuneStateChange = true
    end

    local protocol = (require "PB.net".C2SSkillOperateRuneInfo)()
    protocol.runeInfo.runeId = runeId
    protocol.runeInfo.isActivity = isActivity
    protocol.runeInfo.configId = game._HostPlayer._ActiveRuneConfigId
    PBHelper.Send(protocol)
end

-- 切换纹章配置
def.method("number").OnActiveRuneConfig = function(self, configId)
    local protocol = (require "PB.net".C2SSkillOperateRuneConfig)()
    protocol.runeConfig.configId = configId
    PBHelper.Send(protocol)
end

--纹章学习 升级
def.method("number").OnUseItemEvent = function(self, itemTid)
    local runeInfo = self._SkillToggle[self._Parent._SelectedSkillIndex]._RuneInfo[self._SelectedRuneIndex]
    if not runeInfo._IsOwn then
        game._GUIMan:ShowTipText(StringTable.Get(138), false)
        self:PlayUISfx(3, self._SelectedRuneIndex)
        -- 穿戴纹章不在聊天框中显示
        -- local itemTemp = CElementData.GetItemTemplate(itemTid)
        -- if itemTemp then
        --     local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
        --     local ChatManager = require "Chat.ChatManager"
        --     local msg = string.format(StringTable.Get(171), itemTemp.TextDisplayName)
        --     if msg ~= nil then
        --         ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
        --     end
        -- end
    else
        game._GUIMan:ShowTipText(StringTable.Get(189), false)                       
    end
    self:Update()
end



def.method("number", "number").PlayUISfx = function(self, sfxType, index)
    if sfxType == 2 then
        GameUtil.PlayUISfx(PATH.UI_zhuangbeiwenzhang, self._RuneToggle[index]._GameObject:FindChild("Img_RuneIcon_R"),
            self._RuneToggle[index]._GameObject:FindChild("Img_RuneIcon_R"), 1) 
    elseif sfxType == 3 then
        GameUtil.PlayUISfx(PATH.UI_wenzhangjiesuo, self._RuneToggle[index]._GameObject:FindChild("Img_RuneIcon_R"),self._RuneToggle[index]._GameObject:FindChild("Img_RuneIcon_R"),
         1)
    end
end

def.method("number", "number").StopUISfx = function(self, sfxType, index)
    if sfxType == 4 then
        GameUtil.StopUISfx(PATH.UI_xinwenzhang, self._RuneToggle[index]._GameObject:FindChild("Img_RuneIcon_R"))
    end
end

def.method().StopAllRuneIconUISfx = function(self)
    for i = 1, 3 do
        self._RuneToggle[i]._GameObject:FindChild("Img_RuneIcon_R/Img_LevelUp"):SetActive(false)
    end
end

def.method().Hide = function (self)
    if not self._IsShown then return end
    -- 清理再次打开时需要更新的逻辑数据
    self._FrameSkillCenter:SetActive(false) 
    self._Frame_RuneInfo:SetActive(false)
    self._RunePlanGroup:SetActive(false)

    self:StopAllRuneIconUISfx()
    self._IsShown = false

    for i = 1, 8 do
        self._Img_RuneIcon[i]:SetActive(false)
    end
end

def.method().Destroy = function (self)
    -- 清理界面GameObject引用 + 缓存数据
    self._Frame_RuneInfo        = nil
    self._RunePlanGroup         = nil
    self._FrameSkillCenter      = nil

    self._Lab_RuneDes           = nil
    self._Lab_Config_Enabled    = nil
    self._Img_Lock3             = nil
    self._Img_Lock4             = nil
    self._Lab_Config_Enabled2   = nil
    self._Img_Lock0             = nil
    self._Text0                 = nil
    self._Text1                 = nil
    self._RuneUnLockBtn         = nil
    self._RuneUpgradeBtn        = nil
    self._RuneConfigBtn         = nil
    self._RuneUnlockBtnEff      = nil
    self._BtnRuneCost           = nil
    self._RuneCostIcon          = nil
    self._RuneUpdBtnEff         = nil
    self._UpgradeBtn            = nil
    self._SkillLine1            = nil
    self._SkillLine2            = nil
    self._BtnUpdSkillRoot       = nil
    self._SkillUpdBtnEff        = nil

    self._SkillToggle           = {}
    self._RuneToggle            = {}
    self._Img_RuneIcon          = {}
    self._CurrentPlaySfxUI      = {}

    self._SkillInfo             = nil
    self._SkillConditionInfo    = nil
end

CPageSkillRune.Commit()
return CPageSkillRune