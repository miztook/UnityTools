local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CTeamMan = require "Team.CTeamMan"
local CPanelUIQuickMatchConfirm = Lplus.Extend(CPanelBase, "CPanelUIQuickMatchConfirm")
local CElementData = require "Data.CElementData"
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIQuickMatchConfirm.define

local instance = nil

def.field(CTeamMan)._TeamMan = nil
def.field("table")._PanelObject = BlankTable
def.field("userdata")._Sld_Ready = nil
def.field("table")._InfoData = BlankTable


def.static("=>", CPanelUIQuickMatchConfirm).Instance = function()
	if not instance then
		instance = CPanelUIQuickMatchConfirm()
		instance._PrefabPath = PATH.UI_QuickMatchConfirm
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ForbidESC = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._TeamMan = CTeamMan.Instance()

    self._PanelObject = 
    {
        TeamMemberItemList = {},
        Btn_Yes = self:GetUIObject('Btn_Yes'),
        Btn_No = self:GetUIObject('Btn_No'),
        Lab_Sure = self:GetUIObject('Lab_Sure'),
        Lab_MsgTitle = self:GetUIObject('Lab_MsgTitle'),
    }

    self._PanelObject.Lab_Sure:SetActive(false)
end                      

local function HideSelf()
    if instance and instance:IsShow() then
        game._GUIMan:CloseByScript(instance)
        CPVEAutoMatch.Instance():Lock(instance._InfoData.DungeonId)
    end
end

def.override("dynamic").OnData = function (self,data)
    self._InfoData = data

    self:ResetAll()

    self._Sld_Ready = self:GetUIObject('Sld_Ready')
    local img_Cap = self:GetUIObject("Img_Cap1")
    GameUtil.PlayUISfx(PATH.UIFX_Team_Confirm, img_Cap, img_Cap, -1)
    GUITools.DoSlider(self._Sld_Ready, 0, self._InfoData.Duration/1000, nil, HideSelf)

    if self._InfoData.DungeonId == nil or self._InfoData.DungeonId <= 0 then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        self._InfoData.DungeonId = self._InfoData.DungeonId
        self:UpdateDungeonTitle()
    end
end

def.method().UpdateDungeonTitle = function(self)
    local targetDungeon = CElementData.GetTemplate("Instance", self._InfoData.DungeonId)
    if targetDungeon == nil then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        local str = string.format(StringTable.Get(22006), TeamUtil.GetTeamRoomNameByDungeonId(self._InfoData.DungeonId))
        GUI.SetText(self._PanelObject.Lab_MsgTitle, str)
    end
end

def.method().ResetAll = function(self)
    self:ResetItemList()
    self:UpdateItemList()
end

--初始化控件信息
def.method().ResetItemList = function(self)
    self._PanelObject.TeamMemberItemList = {}

    local memberCnt = #self._InfoData.MemeberList
    for i=1,5 do
        local obj = self:GetUIObject('Item'..i)
        if obj == nil then
            warn("obj is null???????????")
        end

        local bShow = (i <= memberCnt)
        obj:SetActive( bShow )
        if bShow then
            local key = self._InfoData.MemeberList[i]._ID
            self._PanelObject.TeamMemberItemList[key] = obj
        end
    end
end

def.method().UpdateItemList = function(self)
    for k, member in pairs( self._InfoData.MemeberList ) do
        if self._PanelObject.TeamMemberItemList[member._ID] ~= nil then
            self:SetItemInfo(self._PanelObject.TeamMemberItemList[member._ID], member)
        else
            warn("error teaminfo Item Object nil? | ::UpdateItemList()")
        end
    end
end

--设置单个UI信息
def.method("userdata", "table").SetItemInfo = function(self, item, memberInfo)
    local CElementData = require "Data.CElementData"
    local prof_template = CElementData.GetProfessionTemplate(memberInfo._Profession)
    GUITools.SetProfSymbolIcon(item:FindChild("Lab_Name/Img_Prof"), prof_template.SymbolAtlasPath)
    GUI.SetText(item:FindChild("Lab_Name"), memberInfo._Name)
    
    if memberInfo._Gender == EnumDef.Gender.Female then
        GUITools.SetHeadIcon(item:FindChild("Img_ItemIcon"), prof_template.FemaleIconAtlasPath)
    else
        GUITools.SetHeadIcon(item:FindChild("Img_ItemIcon"), prof_template.MaleIconAtlasPath)
    end
    
    item:FindChild("Img_Ready"):SetActive(false)
    local Img_AssistTag = item:FindChild("Img_AssistTag")
    if Img_AssistTag then
        Img_AssistTag:SetActive(false)
    end
end

def.override("string").OnClick = function(self,id)
	if id == "Btn_Yes" then
        local matchingId = game._DungeonMan:GetQuickMatchTargetId()
        if self._InfoData.DungeonId > 0 then
            local reward_count = game._DungeonMan:GetRemainderCount(self._InfoData.DungeonId)
            if reward_count <= 0 then
                local callback = function(val)
                    if val then
                        game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, true)
                    else
                        game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, false)
                    end
                end
                local dungeon_temp = CElementData.GetTemplate("Instance", self._InfoData.DungeonId)
                if dungeon_temp == nil then
                    game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, false)
                end
                local title, msg, closeType = StringTable.GetMsg(88)
                local message = string.format(msg, dungeon_temp.TextDisplayName)
			    MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.ImportantTip)
            else
    		    game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, true)
            end
        else
            game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, true)
        end
	elseif id == "Btn_No" then
        local matchingId = game._DungeonMan:GetQuickMatchTargetId()
		game._DungeonMan:SendC2SQuickMatchConfirm(matchingId, false)
        HideSelf()
	end
end

--更新确认入队的图标
def.method('number').UpdateTeamMemberConfirmed = function(self,roleId)
    if instance == nil or not instance:IsShow() then return end 

    local item = self._PanelObject.TeamMemberItemList[roleId]
    if item == nil then return end

    if roleId == game._HostPlayer._ID then
        self._PanelObject.Lab_Sure:SetActive(true)
        self._PanelObject.Btn_Yes:SetActive(false)
        self._PanelObject.Btn_No:SetActive(false)
    end

	local Img_Ready = item:FindChild("Img_Ready")
    Img_Ready:SetActive(true)
end

def.override().OnHide = function(self)
    if self._Sld_Ready ~= nil then
        GUITools.DoKillSlider(self._Sld_Ready)
    end
    CPanelBase.OnHide(self)
end

CPanelUIQuickMatchConfirm.Commit()
return CPanelUIQuickMatchConfirm