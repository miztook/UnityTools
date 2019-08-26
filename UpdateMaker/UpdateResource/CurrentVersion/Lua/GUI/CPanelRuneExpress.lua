local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local DynamicText = require "Utility.DynamicText"
local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"

local CPanelRuneExpress = Lplus.Extend(CPanelBase, 'CPanelRuneExpress')
local def = CPanelRuneExpress.define

def.field("table")._RuneEffect              = BlankTable

def.field("table")._SkillRuneList           = nil
def.field("table")._RuneEffectShow          = BlankTable

local instance = nil
def.static('=>', CPanelRuneExpress).Instance = function()
    if not instance then
        instance = CPanelRuneExpress()
        instance._PrefabPath = PATH.UI_RuneExpress
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    local root = self:GetUIObject("RuneEffectRoot")
    for i = 1, 3 do
        self._RuneEffectShow[i] = root:FindChild("text"..i)
    end
    self._SkillRuneList = {}
    for i = 1, 8 do
        local item = {}
        local root = self:GetUIObject('Rune_Item' .. i )
        item.SkillRuneDes = root:FindChild("SkillRuneDes")
        item.SkillName = root:FindChild("SkillName")
        item.SkillRuneName = item.SkillName:FindChild("SkillRuneName")
        item.SkillIcon = root:FindChild("SkillIconBase/SkillIcon")
        item.SkillLock = root:FindChild("SkillIconBase/Skilllock")
        item.RuneIcon = item.SkillIcon:FindChild("RuneIcon")
        self._SkillRuneList[i] = item
    end
end

def.method().InitRuneInfo = function (self)
    self._RuneEffect = {}
    local defaultRuneInfo = {}
    local allRune = CElementData.GetAllTid("Rune")
	for i, v in ipairs(allRune) do
		local rune = CElementSkill.GetRune(v)
		defaultRuneInfo[rune.SkillId .. rune.UiPos] = v
    end
    
    local hp = game._HostPlayer
    local normalPack = hp._Package._NormalPack
    local skillPoseToInfo = hp._MainSkillIDList
    for k, v in pairs(skillPoseToInfo) do
        for i = 1, 3 do
            local tid = defaultRuneInfo[v .. i]
            local rune = CElementSkill.GetRune(tid)
            local type = rune.ElementType
            self._RuneEffect[type] = 0
        end
    end
end

def.override("dynamic").OnData = function (self, data)
    local hp = game._HostPlayer
    local mianUISkillList = hp._MainSkillIDList
    local learnedState = hp._MainSkillLearnState
    local userSkillMap = hp._UserSkillMap
    self:InitRuneInfo()
    
    for i = 1, 8 do
        local skillId = mianUISkillList[i]
        local isLeraned = learnedState[skillId]
        local item = self._SkillRuneList[i]

        -- 技能已学习
        if isLeraned then
            local skill = CElementSkill.Get(skillId)
            item.SkillLock:SetActive(false)
            item.SkillIcon:SetActive(true)
            GUITools.SetSkillIcon(item.SkillIcon, skill.IconName)

            local name = string.format("[%s]", skill.Name)
            GUI.SetText(item.SkillName, name)
            -- 内容set
            local skillData = hp:GetSkillData(skillId)
            local clearIcon = true
            for l, m in ipairs(skillData.SkillRuneInfoDatas) do
                if m.isActivity then
                    local runeLevel = m.level
                    if runeLevel == 0 then
                        runeLevel = 1
                    end
                    local runeDes = DynamicText.ParseRuneDescText(m.runeId, runeLevel)
                    GUI.SetText(item.SkillRuneDes, runeDes) 

                    local runeTemp = CElementSkill.GetRune(m.runeId) 
                    GUI.SetText(item.SkillRuneName, runeTemp.Name)
                    item.RuneIcon:SetActive(true)
                    GUITools.SetSkillIcon(item.RuneIcon, runeTemp.RuneSmallIcon)
                    clearIcon = false

                    local valnow = CElementSkill.GetRuneLevelUpValue(m.runeId, 10, m.level)
                    local type = runeTemp.ElementType
                    local effect = self._RuneEffect[type]
                    if effect == nil then
                        self._RuneEffect[type] = valnow
                    else
                        self._RuneEffect[type] = self._RuneEffect[type] + valnow
                    end
                end
            end

            if clearIcon then 
                GUI.SetText(item.SkillRuneDes, StringTable.Get(20449))
                item.RuneIcon:SetActive(false)
                GUI.SetText(item.SkillRuneName, "")
            end
        -- 没学习
        else
            GUI.SetText(item.SkillRuneDes, StringTable.Get(20450))
            item.SkillLock:SetActive(true)
            item.SkillIcon:SetActive(false)
            GUI.SetText(item.SkillRuneName, "")
        end
    end
    
    local ind = 1
    for k, v in pairs(self._RuneEffect) do
        local effShow = self._RuneEffectShow[ind]
        if effShow then
            local des =  string.format("<color=write>+%s</color>",v)
            GUI.SetText(effShow,  StringTable.Get(189 + k) .. des)
        end
        ind = ind + 1
    end
end

def.override("string").OnClick = function(self, id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnDestroy = function(self)
    self._SkillRuneList = nil
    self._RuneEffect = nil
end

CPanelRuneExpress.Commit()
return CPanelRuneExpress