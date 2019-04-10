local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementSkill = require "Data.CElementSkill"
local DynamicText = require "Utility.DynamicText"
local PBHelper = require "Network.PBHelper"
local EResourceType = require "PB.data".EResourceType 
local CElementData      = require "Data.CElementData" 

local CPageSkillInfo = Lplus.Class("CPageSkillInfo")
local def = CPageSkillInfo.define

def.field("table")._Parent = nil
--最外层大框
def.field("userdata")._FrameSkillCenter = nil
def.field("userdata")._FrameSkillLeft = nil

--技能框相关
def.field("table")._SkillToggle = BlankTable

def.field("userdata")._Img_SkillIcon = nil
def.field("userdata")._Img_SkillRuneIcon = nil
def.field("userdata")._Lab_SkillName = nil
def.field("userdata")._Lab_SkillLevel = nil
def.field("userdata")._Lab_Cooldown = nil
def.field("userdata")._Lab_CostParent = nil
def.field("userdata")._Lab_Cost = nil
def.field("userdata")._Lab_SkillDes = nil
def.field("userdata")._Lab_NeedLevelParent = nil
def.field("userdata")._Lab_NeedLevel = nil
def.field("userdata")._Lab_CostMoney = nil
def.field("userdata")._Frame_Des = nil
def.field("userdata")._Lab_Max_Des = nil
def.field("userdata")._Img_Arrow = nil
def.field("userdata")._Img_ProArrow = nil
def.field("userdata")._SkillLine1 = nil
def.field("userdata")._SkillLine2 = nil
def.field("userdata")._UpgradeAllBtn = nil
def.field("userdata")._UpgradeBtn = nil 
def.field("userdata")._UpgradeAllCost = nil
def.field("userdata")._BtnUpdSkillRoot = nil
def.field("userdata")._SkillUpdBtnEff = nil
def.field("userdata")._SkillRuneIcon = nil
def.field("userdata")._SkillRuneTitle = nil
def.field("userdata")._SkillRuneDes = nil
def.field("userdata")._SkillRuneNone = nil

def.field("table")._Lab_Des = BlankTable
def.field("table")._Lab_SkillNow = BlankTable
def.field("table")._Lab_SkillNext = BlankTable
def.field("table")._LabDesAnchoredPos = nil 
def.field("table")._SkillPoseToRuen = BlankTable    -- 位置为Key，runeID为value

-- 数据
def.field("number")._CurIndex = 1   -- 当前选中index
def.field("boolean")._IsShown = false

local LevelUpKey = "levelup"                        -- 描述特殊匹配字段

def.static("table", "=>", CPageSkillInfo).new = function(root)
	local obj = CPageSkillInfo()
	obj._Parent = root
	obj:Init()
	return obj 
end

def.method().Init = function(self)
    self._FrameSkillLeft = self._Parent:GetUIObject("Frame_SkillInfo")
    self._FrameSkillCenter = self._Parent:GetUIObject("Frame_Skill")

    self._Img_SkillIcon = self._Parent:GetUIObject("Img_SkillIcon9")
    self._Img_SkillRuneIcon = self._Img_SkillIcon:FindChild("icon")
    self._Lab_SkillName = self._Parent:GetUIObject("Lab_SkillName")
    self._Lab_SkillLevel = self._Parent:GetUIObject("Lab_SkillLevel")
    self._Lab_Cooldown = self._Parent:GetUIObject("Lab_Cooldown")
    self._Lab_CostParent = self._Parent:GetUIObject("Lab_2")
    self._Lab_Cost = self._Parent:GetUIObject("Lab_Cost")
    self._Lab_SkillDes = self._Parent:GetUIObject("Lab_SkillDes")
    self._Lab_NeedLevel = self._Parent:GetUIObject("Lab_NeedLevel")
    self._Lab_NeedLevelParent = self._Lab_NeedLevel.parent -- self._Parent:GetUIObject("Lab_41") fuxxk get
    self._Lab_CostMoney = self._Parent:GetUIObject("Lab_CostMoney")

    self._UpgradeAllBtn = self._Parent:GetUIObject("Btn_UpgradeSkillAll")
    self._UpgradeBtn = self._Parent:GetUIObject("Btn_UpgradeSkill")
    self._UpgradeAllCost = self._Parent:GetUIObject("Lab_AllCostMoney")
    self._BtnUpdSkillRoot = self._Parent:GetUIObject("Btn_UpgradeSkill")
    self._SkillUpdBtnEff = self._Parent:GetUIObject("SKill_Btn_Effect")

    self._SkillLine1 = self._Parent:GetUIObject("Skill_Line1")
    self._SkillLine2 = self._Parent:GetUIObject("Skill_Line2")
    
    self._SkillRuneIcon = self._Parent:GetUIObject("Skill_RuneInfo_Icon")
    self._SkillRuneTitle = self._Parent:GetUIObject("Skill_RuneInfo_Title")
    self._SkillRuneDes = self._Parent:GetUIObject("Skill_RuneInfo_Des")
    self._SkillRuneNone = self._Parent:GetUIObject("Skill_RuneInfo_None")
    self._SkillRuneNone:SetActive(false)
    GUI.SetText(self._SkillRuneTitle, StringTable.Get(10643))
    GUI.SetText(self._SkillRuneNone, StringTable.Get(10980))
    
    local hp = game._HostPlayer
    for i = 1, 8 do
        self._SkillToggle[i] = {}
        local activeGo = nil      
        if i ~= 8 then
            local go = self._Parent:GetUIObject("Rdo_Skill" .. i)
            activeGo = go
            local runeIcon = self._Parent:GetUIObject("Img_RuneIcon" .. (i - 1))
            runeIcon:SetActive(false)
        else            
            local go = self._Parent:GetUIObject("Rdo_Skill" .. i)
            local nextGo = self._Parent:GetUIObject("Rdo_Skill" .. (i + 1))
            local runeIcon = self._Parent:GetUIObject("Img_RuneIcon" .. (i - 1))
            local nextRuneIcon = self._Parent:GetUIObject("Img_RuneIcon" .. i)
            
            if hp._InfoData._Prof ~= EnumDef.Profession.Archer then -- normal
                go:SetActive(true)
                nextGo:SetActive(false)
                activeGo = go
                runeIcon:SetActive(false)
                nextRuneIcon:SetActive(false)
            else -- Archer
                go:SetActive(false)
                nextGo:SetActive(true)
                activeGo = nextGo
                runeIcon:SetActive(false)
                nextRuneIcon:SetActive(false)
            end
        end

        self._SkillToggle[i].SkillIcon = activeGo:FindChild("Img_U/Img_SkillIcon")
        self._SkillToggle[i].LockIcon = activeGo:FindChild("Img_U/Img_SkillLock")
        self._SkillToggle[i].LockLvLabel = activeGo:FindChild("Img_U/Img_SkillLock/Lab_LockLevel")
        self._SkillToggle[i].LabLevelBg = activeGo:FindChild("Img_U/Img_SkillIcon/Lab_Level_Bg")
        self._SkillToggle[i].LabLevel = activeGo:FindChild("Img_U/Img_SkillIcon/Lab_Level_Bg/Lab_Level")
        self._SkillToggle[i].ToggleOnImg = activeGo:FindChild("Img_U/Img_SkillIcon/Img_D")
        self._SkillToggle[i].UpLevelIcon = activeGo:FindChild("Img_LevelUp")
    end

    self._Frame_Des = self._Parent:GetUIObject("Frame_Des0")
    self._Lab_Max_Des = self._Parent:GetUIObject("Lab_Max_Des")
    for i = 1, 2 do
        self._Lab_Des[i] = self._Parent:GetUIObject("Lab_Des_" .. i)
        self._Lab_SkillNow[i] = self._Parent:GetUIObject("Lab_SkillNow" .. (i - 1))
        self._Lab_SkillNext[i] = self._Parent:GetUIObject("Lab_SkillNext" .. (i - 1))
    end
    self._Img_Arrow = self._Parent:GetUIObject("Img_Arrow")
    self._Img_ProArrow = self._Parent:GetUIObject("Img_ProfArrow")
    
    if hp._InfoData._Prof ~= EnumDef.Profession.Archer then
        local rdo7 = self._Parent:GetUIObject("Rdo_Skill7")
        local rdo9 = self._Parent:GetUIObject("Rdo_Skill9")
        if not IsNil(rdo7) and not IsNil(rdo9) then
            rdo7.localPosition = rdo9.localPosition
        end
    end
end

def.method().Show = function (self)
	if self._IsShown then return end

    self._FrameSkillLeft:SetActive(true)
    self._FrameSkillCenter:SetActive(true)
    self._CurIndex = self._Parent._SelectedSkillIndex
    self:Update()

    self._IsShown = true
end

def.method().Update = function (self)
    self:UpdateRuneInfo()
    self:UpdateSkillList()
    self:UpdateCurSkillInfo()
    self:DoUpgradeAllCheck()
end


def.method().UpdateRuneInfo = function (self)
    local skillInfo = {}
    local userSkillMap = game._HostPlayer._UserSkillMap
    
    for k, v in pairs(userSkillMap) do
        skillInfo[v.SkillId] = v
    end
    self._SkillPoseToRuen = {}
    local hp = game._HostPlayer
    local skillPoseToInfo = hp._MainSkillIDList
    for k, v in pairs(skillPoseToInfo) do
        if skillInfo[v] then
            local SkillRuneInfoDatas = skillInfo[v].SkillRuneInfoDatas
            for m, n in ipairs(SkillRuneInfoDatas) do
                if n.isActivity then
                    self._SkillPoseToRuen[k] = n.runeId
                end
            end
        end
    end
end

def.method().UpdateSkillList = function(self)
    local hp = game._HostPlayer
    local skillList = hp._MainSkillIDList

    for i,v in ipairs(skillList) do
        local skillData = hp:GetSkillData(v)

        local curToggle = self._SkillToggle[i]
        curToggle._Tid = v

        if skillData ~= nil then
            curToggle._IsLearned = true

            GUITools.SetSkillIcon(curToggle.SkillIcon, skillData.Skill.IconName)
            GameUtil.MakeImageGray(curToggle.SkillIcon, false)

            if curToggle._SkillLevel ~= nil and curToggle._SkillLevel < (skillData.SkillLevel - skillData.TalentAdditionLevel) then
                GameUtil.PlayUISfx(PATH.UIFX_WenZhangZhuanJingShengJi, curToggle.SkillIcon, curToggle.SkillIcon, 1)
                -- 展示升级动画
                GameUtil.PlayUISfx(PATH.UIFX_TongYongShuXingLiuGuang_01, self._Img_Arrow, self._Img_Arrow, -1)
                if i == 1 then
                    GUITools.ScaleChildFXObj(curToggle.SkillIcon, SkillUpdateFXOScale)
                end
            end

            curToggle._SkillLevel = skillData.SkillLevel - skillData.TalentAdditionLevel
            curToggle._TalentLevel = skillData.TalentAdditionLevel

            curToggle.LockIcon:SetActive(false)
            curToggle.LabLevelBg:SetActive(true)
            GUI.SetText(curToggle.LabLevel, tostring(skillData.SkillLevel))

            self:UpdateSkillLine(i, true)

            if i == self._CurIndex then
                curToggle.ToggleOnImg:SetActive(true)
            else
                curToggle.ToggleOnImg:SetActive(false)
            end

            GUITools.SetBtnGray(self._UpgradeBtn, false) 
        else
            curToggle._IsLearned = false
            curToggle._SkillLevel = 1
            curToggle._TalentLevel = 0
            local skillTemp = CElementSkill.Get(v)

            GUITools.SetSkillIcon(curToggle.SkillIcon, skillTemp.IconName)
            GameUtil.MakeImageGray(curToggle.SkillIcon, true, nil)

            curToggle.LockIcon:SetActive(true)
            curToggle.LabLevelBg:SetActive(false)

            self:UpdateSkillLine(i, false)

            local slc = hp:GetSkillLearnConditionTemp(v)
            if slc ~= nil and slc.RoleLearnType == 0 then
                GUI.SetText(curToggle.LockLvLabel, string.format(StringTable.Get(10714), slc.RoleLearnParam))
            else
                GUI.SetText(curToggle.LockLvLabel, StringTable.Get(166))                        
            end
            GUITools.SetBtnGray(self._UpgradeBtn, true)
        end
    end
end

-- 展示技能基础信息
def.method().UpdateCurSkillInfo = function(self)
    local index = self._CurIndex
    local skillToggle = self._SkillToggle[index]

    local hp = game._HostPlayer
    local skillList = hp._MainSkillIDList
    local skillId = skillList[index]

    if skillToggle == nil or skillId == nil then return end

    local skillData = hp:GetSkillData(skillId)
    local skill = nil
    if skillData ~= nil then
        skill = skillData.Skill
    else
        skill = CElementSkill.Get(skillId)
    end

    GUITools.SetSkillIcon(self._Img_SkillIcon, skill.IconName)
    GUI.SetText(self._Lab_SkillName, skill.Name)

    local level_str = string.format(StringTable.Get(168), skillToggle._SkillLevel)
    if skillToggle._TalentLevel > 0 then
        level_str = level_str .."+"..skillToggle._TalentLevel
    end
    GUI.SetText(self._Lab_SkillLevel, level_str)

    local cooldown = skill.CooldownDuration / 1000 .. StringTable.Get(1000)
    GUI.SetText(self._Lab_Cooldown, cooldown)
    
    if skill.EnergyValue == 0 then
        self._Lab_CostParent:SetActive(false)
    else        
        self._Lab_CostParent:SetActive(true)
        local skillCostData = skill.EnergyValue .. StringTable.Get(129)
        GUI.SetText(self._Lab_Cost, skillCostData)
    end

    self:UpdateCurSkillDes(skill, (skillToggle._SkillLevel + skillToggle._TalentLevel))
    
    self:RefreshSkillRemindGfx()

    local maps = hp:GetSkillLevelUpConditionMap(skillId)
    for i,v in ipairs(maps) do
        if v.SkillLevel == skillToggle._SkillLevel then
            if v.RoleLevel > 60 then
                -- 技能已经达到最高等级
                self:UpdateCurSkillLevelUpInfo(0, 0, 0)
            else
                self:UpdateCurSkillLevelUpInfo(v.RoleLevel, v.NeedMoneyNum, v.NeedMoneyId)
            end
            return
        end
    end
end

-- 判断是否可以升级全部技能并做对应操作
def.method().DoUpgradeAllCheck = function(self)
    local needGold = self:GetGoldCount2LevelupAll()
    self._UpgradeAllBtn:SetActive(needGold > 0)  

    if needGold == 0 then
        GUI.SetText(self._UpgradeAllCost, "0")  
    else
        local haveGold = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
        local levelDes = nil
        local canUpgrade = haveGold >= needGold
        if canUpgrade then
            levelDes = "<color=white>" .. GUITools.FormatMoney(needGold) ..  "</color>"     
        else
            levelDes = "<color=red>" .. GUITools.FormatMoney(needGold) ..  "</color>"
        end
        
        GUI.SetText(self._UpgradeAllCost, levelDes)     
    end
end

def.method("number", "boolean").UpdateSkillLine = function(self, index, is_learned)
    if index < 7 then return end

    local isArcher = (game._HostPlayer._InfoData._Prof == EnumDef.Profession.Archer)
    self._SkillLine1:SetActive(not isArcher)
    self._SkillLine2:SetActive(isArcher)

    local activeLine = self._SkillLine1
    if isArcher then activeLine = self._SkillLine2 end

    if index == 7 then
        activeLine:FindChild("line_Left"):SetActive(is_learned)
        activeLine:FindChild("line_Left_Gray"):SetActive(not is_learned)
    else
        activeLine:FindChild("line_Right"):SetActive(is_learned)
        activeLine:FindChild("line_Right_Gray"):SetActive(not is_learned)       
    end
end

-- 设置技能最多两条条信息展示
def.method("table", "number").UpdateCurSkillDes = function(self, skill, skillLevel)
    local skillId = skill.Id
    GUI.SetText(self._Lab_SkillDes, DynamicText.ParseSkillDescText(skillId, skillLevel, false))

    local skillLevelUpDes = skill.SkillLevelUpDescription
    local des_data = string.split(skillLevelUpDes, "\n")
    local result = {}
    local desc = ""
    local count = 0
    for i = 1, 2 do
        if des_data[i] ~= nil then
            self._Lab_Des[i]:SetActive(true)

            result[i], desc = self:ParasSkillDes(des_data[i], skill.Id, skillLevel)

            if result[i]._Start ~= nil and result[i]._Stop ~= nil then
                if i > 1 then
                    if result[i - 1]._EStart ~= nil and result[i - 1]._EStop ~= nil then
                        count = count + 1
                        self._Lab_Des[i]:SetActive(true)
                    else
                        self._Lab_Des[i]:SetActive(false)
                    end
                else
                    count = count + 1
                    self._Lab_Des[i]:SetActive(true)
                end
                GUI.SetText(self._Lab_Des[i], result[i]._DesNow)

                GUI.SetText(self._Lab_SkillNow[i], tostring(result[i]._ValueNow .. result[i]._DesNext))
                GUI.SetText(self._Lab_SkillNext[i],tostring(result[i]._ValueNext .. result[i]._DesNext))
            else
                self._Lab_Des[i]:SetActive(false)
            end
        else
            self._Lab_Des[i]:SetActive(false)
        end
    end

    local runeId = self._SkillPoseToRuen[self._CurIndex]
    local parsedText = ""
    self._Img_SkillRuneIcon:SetActive(runeId ~= nil)
    if runeId then
        local runeTemplate = CElementData.GetTemplate("Rune", runeId)
        parsedText = runeTemplate.SkillWithRuneDes
        if parsedText then
            parsedText = string.format( parsedText, tostring(result[1]._ValueNow .. result[1]._DesNext))
            GUI.SetText(self._SkillRuneDes, parsedText)
        end
        local icon = CElementSkill.GetRune(runeId).RuneSmallIcon
        GUITools.SetSkillIcon(self._SkillRuneIcon, icon)
        GUITools.SetSkillIcon(self._Img_SkillRuneIcon, icon)
    end
    local isShowRuneDes = (runeId ~= nil) and (parsedText ~= "")
    -- self._SkillRuneNone:SetActive(not isShowRuneDes)
    self._SkillRuneIcon:SetActive(isShowRuneDes)
    self._SkillRuneDes:SetActive(isShowRuneDes)

    if self._LabDesAnchoredPos == nil then
        self._LabDesAnchoredPos = self._Lab_Des[1]:GetComponent(ClassType.RectTransform).anchoredPosition3D
    end

    if count == 1 then
        local vecY = self._Img_Arrow:GetComponent(ClassType.RectTransform).anchoredPosition3D.y
        self._Lab_Des[1]:GetComponent(ClassType.RectTransform).anchoredPosition3D = Vector3.New(self._LabDesAnchoredPos.x, vecY, self._LabDesAnchoredPos.z)
    else
        self._Lab_Des[1]:GetComponent(ClassType.RectTransform).anchoredPosition3D = self._LabDesAnchoredPos
    end
end

-- 拆分技能描述
def.method("string", "number", "number", "=>", "table", "string").ParasSkillDes = function(self, skillLevelUpDes, skillId, skillLevel)
    local delta = 1
    local start, stop = string.find(skillLevelUpDes, "<(%a+)(%d+)>")
    if start == nil then
        delta = 2
        start, stop = string.find(skillLevelUpDes, "<(%a+)(%d+)%%>")
    end

    local finalValue = {}
    finalValue._Start = start
    finalValue._Stop = stop
    if start ~= nil and stop ~= nil then
        local keyWord = string.sub(skillLevelUpDes, start, stop)
        
        local key = string.sub(string.sub(keyWord, 2, string.len(keyWord) - delta), string.len(LevelUpKey) + 1)
        local cStart, cStop = string.find(skillLevelUpDes, "<")
        local des_1 = ""
        local des_2 = ""
        local eStart, eStop = nil
        local value_1 = self:GetSkillLevelUpValue(skillId, tonumber(key), skillLevel)
        local value_2 = self:GetSkillLevelUpValue(skillId, tonumber(key), skillLevel + 1)

        if string.find(skillLevelUpDes, "%%") then
            value_1 = tonumber(value_1) * 100
            value_2 = tonumber(value_2) * 100
            des_2 = "%"
        end

        if cStart ~= nil and cStop ~= nil then
            des_1 = string.sub(skillLevelUpDes, 1, cStop - 1)           
        end
        finalValue._EStart = start
        finalValue._EStop = stop
        finalValue._ValueNow = value_1
        finalValue._ValueNext = value_2
        finalValue._DesNow = des_1
        finalValue._DesNext = des_2
    end

    return finalValue, skillLevelUpDes
end

-- 获取技能升级数据值
def.method("number", "number", "number", "=>", "string").GetSkillLevelUpValue = function(self, skillId, levelUpId, skillLevel)
    local allSkillLevelUp = GameUtil.GetAllTid("SkillLevelUp")
    for i,v in ipairs(allSkillLevelUp) do
        local skillLevelUp = CElementSkill.GetLevelUp(v)
        if skillLevelUp.SkillId == skillId and skillLevelUp.LevelUpId == levelUpId then
            local value = 0
            if skillLevelUp.LevelDatas[skillLevel] ~= nil then
                value = skillLevelUp.LevelDatas[skillLevel].Value
            end
            if value == 0 then
                warn("-----缺少正确的技能升级数据以支撑UI显示")
            end
            local start, stop = string.find(value, "%.")
            if start ~= nil and stop ~= nil then
                value = string.format("%.3f", value)
            end
            return tostring(value)
        end
    end
    warn("-----缺少正确的技能升级数据以支撑UI显示")
    return 0
end

-- 设置技能升级信息
def.method("number", "number", "number").UpdateCurSkillLevelUpInfo = function(self, roleLevel, needGold, moneyId)
    if roleLevel == 0 then
        self._Frame_Des:SetActive(false)
        self._Lab_NeedLevelParent:SetActive(false)
        self._Lab_Max_Des:SetActive(true)
        GUI.SetText(self._Lab_Max_Des, StringTable.Get(126))
        self._UpgradeBtn:SetActive(false)
    else
        self._UpgradeBtn:SetActive(true)
        self._Frame_Des:SetActive(true)
        self._Lab_NeedLevelParent:SetActive(true)
        self._Lab_Max_Des:SetActive(false)
        local playerLevel = game._HostPlayer._InfoData._Level
        local playerGold = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold

        local expextMoneyMeet = false
        local levelDes = nil
        if playerLevel >= roleLevel then
            levelDes = "<color=white>" .. roleLevel .. StringTable.Get(6) .. "</color>" 
            GUITools.SetBtnGray(self._UpgradeBtn, false)  
            expextMoneyMeet = true                          
        else        
            levelDes = "<color=red>" .. roleLevel .. StringTable.Get(6) .. "</color>"
            GUITools.SetBtnGray(self._UpgradeBtn, true)           
        end
        GUI.SetText(self._Lab_NeedLevel, levelDes)
        local goldDes = nil
        if playerGold >= needGold then
            if expextMoneyMeet then
                goldDes = "<color=white>" .. GUITools.FormatMoney(needGold) .. "</color>"
            else
                goldDes = "<color=grey>" .. GUITools.FormatMoney(needGold) .. "</color>"
            end
        else
            if expextMoneyMeet then
                goldDes = "<color=red>" .. GUITools.FormatMoney(needGold) .. "</color>"
            else
                goldDes = "<color=grey>" .. GUITools.FormatMoney(needGold) .. "</color>"
            end
        end
        GUI.SetText(self._Lab_CostMoney, goldDes)
    end
end

-- 学习新技能
def.method("number").OnLearnNewSkill = function(self, skillId)
    local index = 0

    local hp = game._HostPlayer
    local skillList = hp._MainSkillIDList
    for i,v in ipairs(skillList) do
        if v == skillId then
            index = i
            break
        end
    end

    local toggle = self._SkillToggle[index]
    if toggle ~= nil then
        toggle._IsLearned = true
        toggle.LockIcon:SetActive(false)

        local skillData = hp:GetSkillData(skillId)
        local skill = nil
        if skillData ~= nil then
            skill = skillData.Skill
        else
            skill = CElementSkill.Get(skillId)
        end

        GUITools.SetSkillIcon(toggle.SkillIcon, skill.IconName)
        toggle.LabLevelBg:SetActive(true)
        GUI.SetText(toggle.LabLevel, "1")
    end
end

def.method("string").OnClick = function (self, id)
    if id == "Btn_UpgradeSkill" then
        self:OnBtnUpgradeCurSkill()
    elseif id == "Btn_UpgradeSkillAll" then
        self:OnBtnUpgradeSkillAll()
    elseif string.find(id, "Rdo_Skill") then
        self:OnToggleSkill(id)
    end
end

def.method().OnBtnUpgradeCurSkill = function(self)
    local index = self._CurIndex

    if not self._SkillToggle[index]._IsLearned then
        game._GUIMan:ShowTipText(StringTable.Get(125), true)
        return
    end

    local hp = game._HostPlayer
    local skillId = hp._MainSkillIDList[index]
    local skillData = hp:GetSkillData(skillId)

    local lvupCfgMaps = hp:GetSkillLevelUpConditionMap(skillId)
    local lv = (skillData.SkillLevel - skillData.TalentAdditionLevel)
    for i, v in ipairs(lvupCfgMaps) do      
        if v.SkillLevel == lv then
            if hp._InfoData._Level < v.RoleLevel then -- 等级不足
                game._GUIMan:ShowTipText(StringTable.Get(127), false)                   
            else
                local callback = function(val)
                    if val then
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillUpgrade, 0)
                        local protocol = (require "PB.net".C2SSkillOperateLevelUp)()
                        protocol.skillLevelUp.skillId = skillId
                        PBHelper.Send(protocol)
                    end
                end
                MsgBox.ShowQuickBuyBox(EResourceType.ResourceTypeGold, v.NeedMoneyNum, callback)
            end
            break
        end

        if v.SkillLevel > lv then
            break
        end
    end

    -- 技能已经达到最高等级
    -- game._GUIMan:ShowTipText(StringTable.Get(126), false)
end

-- 点击升级全部技能
def.method().OnBtnUpgradeSkillAll = function(self)
    local needGold = self:GetGoldCount2LevelupAll()
    local haveGold = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
    if haveGold >= needGold and needGold > 0 then      
        local title, str, closeType = StringTable.GetMsg(98)        
        local str_col = string.format(str, GUITools.FormatMoney(needGold))
        local function cb(val) 
            if val then
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillUpgrade, 0)
                local protocol = (require "PB.net".C2SSkillOperateSkillLevelUpAll)()
                PBHelper.Send(protocol)
            end
        end
        MsgBox.ShowMsgBox(str_col, title, closeType, MsgBoxType.MBBT_OKCANCEL, cb)
    else
        if needGold <= 0 then
            game._GUIMan:ShowTipText(StringTable.Get(126), false)           
        else
            local function callback(val)
                if val then
                    local title, str, closeType = StringTable.GetMsg(98)        
                    local str_col = string.format(str, GUITools.FormatMoney(needGold) )
                    MsgBox.ShowMsgBox(str_col, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val) 
                            if val then
                                CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillUpgrade, 0)
                                local protocol = (require "PB.net".C2SSkillOperateSkillLevelUpAll)()
                                PBHelper.Send(protocol)
                            end
                        end)
                end
            end
            MsgBox.ShowQuickBuyBox(EResourceType.ResourceTypeGold, needGold, callback)
        end
    end
end

def.method("string").OnToggleSkill = function(self, id)
    for i = 1, 9 do
        local index = i
        if i == 9 then
            index = 8
        end

        if id == "Rdo_Skill" .. i then
            local lastIdx = self._CurIndex
            if index == lastIdx then
                return
            end
            self._SkillToggle[lastIdx].ToggleOnImg:SetActive(false)
            self._SkillToggle[index].ToggleOnImg:SetActive(true)
            self._Parent._SelectedSkillIndex = index
            self._CurIndex = index
            self:UpdateCurSkillInfo()                              
            self._Parent:UpdateTabRedDotState()   
            return
        end
    end
end

def.method().RefreshSkillRemindGfx  = function(self)
    local hp = game._HostPlayer
    local haveGold = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
    for i = 1, 8 do
        local toggle = self._SkillToggle[i] 
        local skillId = hp._MainSkillIDList[i]
        local skillData = hp:GetSkillData(skillId)
        local isOk = false
        if skillData ~= nil then
            local maps = hp:GetSkillLevelUpConditionMap(skillId)
            for i, v in ipairs(maps) do
                if v.SkillLevel == skillData.SkillLevel then
                    if (hp._InfoData._Level >= v.RoleLevel) and (haveGold >= v.NeedMoneyNum) then -- 等级 金币 满足
                        isOk = true
                    end 
                    break                
                end
            end
        end

        if isOk then
            -- GameUtil.PlayUISfx(Special_Effect_Ten, toggle.SkillIcon, toggle.SkillIcon, -1)
            -- if i == 1 then
            --     GUITools.ScaleChildFXObj(toggle.SkillIcon, SkillUpdateFXOScale)
            -- else
            --     GUITools.ScaleChildFXObj(toggle.SkillIcon, 1)
            -- end
            toggle.UpLevelIcon:SetActive(true)
        else
            -- GameUtil.StopUISfx(Special_Effect_Ten, toggle.SkillIcon)
            toggle.UpLevelIcon:SetActive(false)
        end

        if i == self._CurIndex then
            self._SkillUpdBtnEff:SetActive(isOk)
        end
    end

    self._Parent:UpdateTabRedDotState()
end

def.method("=>", "number").GetGoldCount2LevelupAll = function(self)
    local hp = game._HostPlayer
    local playerLevel = hp._InfoData._Level

    local needGold = 0
    for i = 1, 8 do
        local skillId = hp._MainSkillIDList[i]
        local skillData = hp:GetSkillData(skillId)
        if skillData ~= nil then
            local skillLv = skillData.SkillLevel
            local map = hp:GetSkillLevelUpConditionMap(skillId)
            for _,v in ipairs(map) do
                if v.RoleLevel <= playerLevel and v.SkillLevel >= skillLv then
                    needGold = needGold + v.NeedMoneyNum
                end
            end
        end
    end

    return needGold
end

def.method().Hide = function (self)
    if not self._IsShown then return end
    -- 
    -- 清理再次打开时需要更新的逻辑数据
    --
    self._FrameSkillLeft:SetActive(false)
    self._FrameSkillCenter:SetActive(false) 
    self._UpgradeAllBtn:SetActive(false)  

    self._IsShown = false
end

def.method().Destroy = function (self)
    -- 清理界面GameObject引用 + 缓存数据
    self._FrameSkillLeft = nil
    self._FrameSkillCenter = nil
    self._Img_SkillIcon = nil
    self._Lab_SkillName = nil
    self._Lab_SkillLevel = nil
    self._Lab_Cooldown = nil
    self._Lab_CostParent = nil
    self._Lab_Cost = nil
    self._Lab_SkillDes = nil
    self._Lab_NeedLevelParent = nil
    self._Lab_NeedLevel = nil
    self._Lab_CostMoney = nil
    self._Frame_Des = nil
    self._Lab_Max_Des = nil
    self._Img_Arrow = nil
    self._SkillLine1 = nil
    self._SkillLine2 = nil
    self._UpgradeAllBtn = nil
    self._UpgradeBtn = nil
    self._UpgradeAllCost = nil
    self._BtnUpdSkillRoot = nil
    self._SkillUpdBtnEff = nil

    self._Lab_Des = {}
    self._Lab_SkillNow = {}
    self._Lab_SkillNext = {}
    self._LabDesAnchoredPos = nil
    self._SkillPoseToRuen = nil
    self._SkillRuneIcon = nil
    self._SkillRuneTitle = nil
    self._SkillRuneDes = nil
    self._SkillRuneNone = nil
end

CPageSkillInfo.Commit()
return CPageSkillInfo