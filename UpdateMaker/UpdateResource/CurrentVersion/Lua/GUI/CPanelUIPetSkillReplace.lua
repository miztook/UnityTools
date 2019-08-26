local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"

local CPanelUIPetSkillReplace = Lplus.Extend(CPanelBase, 'CPanelUIPetSkillReplace')
local def = CPanelUIPetSkillReplace.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._oldSkillInfo = BlankTable   -- 旧技能
def.field("table")._NewSkillInfo = BlankTable   -- 新技能
def.field("table")._UISkillOld = BlankTable     -- 旧技能UI
def.field("table")._UISkillNew = BlankTable     -- 新技能UI
def.field("function")._Callback = nil

local instance = nil
def.static('=>', CPanelUIPetSkillReplace).Instance = function ()
    if not instance then
        instance = CPanelUIPetSkillReplace()
        instance._PrefabPath = PATH.UI_PetSkillReplace
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
    self._UISkillOld = {}
    self._UISkillNew = {}
    do
        local root = self:GetUIObject("FrameSkillOld")
        self._UISkillOld.Icon = root:FindChild("ItemSkill/Img_ItemIcon")
        self._UISkillOld.Quality = root:FindChild("Img_Quality")
        self._UISkillOld.Name = root:FindChild("Lab_SkilName")
    end

    do
        local root = self:GetUIObject("FrameSkillNew")
        self._UISkillNew.Icon = root:FindChild("ItemSkill/Img_ItemIcon")
        self._UISkillNew.Quality = root:FindChild("Img_Quality")
        self._UISkillNew.Name = root:FindChild("Lab_SkilName")
    end
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._oldSkillInfo = data.Old
            self._NewSkillInfo = data.New
            self._Callback = data.Callback
        end

        CPanelBase.OnData(self,data)
    end

    local title, msg, closeType = StringTable.GetMsg(136)
    local lab_title = self:GetUIObject('Lab_MsgTitle')
    local lab_msg = self:GetUIObject('Lab_Message')
    GUI.SetText(lab_title, title)
    GUI.SetText(lab_msg, msg)

    self:InitSkillUI(self._oldSkillInfo, self._UISkillOld)
    self:InitSkillUI(self._NewSkillInfo, self._UISkillNew)
end

def.method("table", "table").InitSkillUI = function(self, skillInfo, UIInfo)
    local TalentData = CElementData.GetTemplate("Talent", skillInfo.ID)
    if TalentData then
        GUITools.SetIcon(UIInfo.Icon, TalentData.Icon)

        local lv = skillInfo.Level
        local BackItemList = {}
        local ids = string.split(TalentData.ItemTIds, "*")
        for i,v in ipairs(ids) do
            local tid = tonumber(v)
            table.insert(BackItemList, tid)
        end
        if BackItemList[lv] == nil then
            warn("Error:Data is Null, SKill BackItemList SkillID, Lv = ", skillInfo.ID, lv)
            return
        end
        local itemTemp = CElementData.GetTemplate("Item", BackItemList[lv])
        local strName = RichTextTools.GetQualityText(TalentData.Name, itemTemp.InitQuality)
        GUI.SetText(UIInfo.Name, string.format(StringTable.Get(19092), strName, lv))
        GUITools.SetGroupImg(UIInfo.Quality, itemTemp.InitQuality)
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Yes' then
        if self._Callback then
            self._Callback(true)            
        end
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        if self._Callback then
            self._Callback(false)            
        end
        game._GUIMan:CloseByScript(self)
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelUIPetSkillReplace.Commit()
return CPanelUIPetSkillReplace