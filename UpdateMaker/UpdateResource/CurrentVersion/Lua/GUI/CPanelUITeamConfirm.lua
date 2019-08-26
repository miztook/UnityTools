local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CTeamMan = require "Team.CTeamMan"
local CCommonBtn = require "GUI.CCommonBtn"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local EInstanceTeamType = require "PB.Template".Instance.EInstanceTeamType
local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"

local CPanelUITeamConfirm = Lplus.Extend(CPanelBase, "CPanelUITeamConfirm")
local def = CPanelUITeamConfirm.define

local instance = nil

def.field(CTeamMan)._TeamMan = nil
def.field("table")._PanelObject = BlankTable
def.field("table")._TeamMemberList = BlankTable
def.field("userdata")._Sld_Ready = nil
def.field("number")._DungeonID = 0
def.field("number")._TimerId = 0
def.field("number")._LeftTime = 0
def.field("userdata")._DoTweenPlayer = nil
def.field("userdata")._DoTweenPlayerTen = nil
def.field("function")._CallBack = nil
def.field("boolean")._IsMatchMode = false
def.field("table")._MatchList = nil
def.field(CCommonBtn)._CommonBtn_Buy = nil
def.field("boolean")._IsBigTeam = false

def.static("=>", CPanelUITeamConfirm).Instance = function()
	if not instance then
		instance = CPanelUITeamConfirm()
		instance._PrefabPath = PATH.UI_TeamConfirm
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
        Btn_Buy = self:GetUIObject("Btn_Buy"),
        Btn_No = self:GetUIObject('Btn_No'),
        Lab_Sure = self:GetUIObject('Lab_Sure'),
        Lab_MsgTitle = self:GetUIObject('Lab_MsgTitle'),
        Lab_Reward = self:GetUIObject('Lab_Reward'),
        Lab_LeftTime = self:GetUIObject('Lab_LeftTime'),
        PlayerItemGroup = self:GetUIObject("PlayerItemGroup"),
        PlayerTenItemGroup = self:GetUIObject("PlayerTenItemGroup"),
       
    }
    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(955),
    }
    self._CommonBtn_Buy = CCommonBtn.new(self._PanelObject.Btn_Buy, setting)
    self._DoTweenPlayer = self:GetUIObject("PlayerItemGroup"):GetComponent(ClassType.DOTweenPlayer)
    self._DoTweenPlayerTen = self:GetUIObject("PlayerTenItemGroup"):GetComponent(ClassType.DOTweenPlayer)
    self._PanelObject.Lab_Sure:SetActive(false)
end                      

local function HideSelf()
    if instance and instance:IsShow() then
        game._GUIMan:CloseByScript(instance)
        CPVEAutoMatch.Instance():Lock(instance._DungeonID)
    end
end

-- 监听购买次数组事件
local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateBuyCountInfo()
        TeamUtil.ConfirmParepare(true)
	end
end

def.override("dynamic").OnData = function (self,data)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_UI_POPUP, 0)
    
    if data.MatchList ~= nil then
        self._IsMatchMode = true
        self._MatchList = data.MatchList
        self._LeftTime = data.Duration
    else
        self._IsMatchMode = false
        self._LeftTime = data.Duration/1000
    end

    if data.DungeonId == nil or data.DungeonId <= 0 then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        self._DungeonID = data.DungeonId
        self:UpdateDungeonTitle()
    end

    local targetDungeon = CElementData.GetTemplate("Instance", self._DungeonID)
    self._IsBigTeam = targetDungeon.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps


    self:ResetAll()
    self._Sld_Ready = self:GetUIObject('Sld_Ready')
    local img_Cap = self:GetUIObject("Img_Cap1")
    GameUtil.PlayUISfx(PATH.UIFX_Team_Confirm, img_Cap, img_Cap, -1)
    GUITools.DoSlider(self._Sld_Ready, 0, self._LeftTime, nil, HideSelf)

    self._TimerId = _G.AddGlobalTimer(1, false ,function()
        if self._LeftTime > 0 then
            if self._PanelObject == nil or self._PanelObject.Lab_LeftTime == nil then return end
            GUI.SetText(self._PanelObject.Lab_LeftTime, string.format(StringTable.Get(22045), self._LeftTime))
            self._LeftTime = self._LeftTime - 1
        else
            _G.RemoveGlobalTimer(self._TimerId)
            self._TimerId = 0
            -- 倒计时结束关闭界面
            game._GUIMan:CloseByScript(self)            
        end
    end)

    if data.CallBack ~= nil then
        self._CallBack = data.CallBack
    end
        
    self._PanelObject.Lab_Reward:SetActive(self._TeamMan:IsBountyMode())

	local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
	local event = NotifyPowerSavingEvent()
	event.Type = "Dungeon"
    if targetDungeon == nil then
		event.Param1 = ""
	else
		event.Param1 = TeamUtil.GetTeamRoomNameByDungeonId(self._DungeonID)
	end

    self:UpdateBuyCountInfo()

    if not self._IsMatchMode then
        self:UpdateTeamMemberConfirmed(self._TeamMan._Team._TeamLeaderId)
    end

    CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:raiseEvent(nil, event)

    self:SyncConfirm()
end

-- 同步组队跟随状态 自动准备
def.method().SyncConfirm = function(self)
    if not self._IsMatchMode then return end

    local bConfirm = self._TeamMan:IsFollowing()
    if bConfirm then
        self:DoConfirm()
    end
end

def.method().UpdateDungeonTitle = function(self)
    local targetDungeon = CElementData.GetTemplate("Instance", self._DungeonID)
    if targetDungeon == nil then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        local roomId = TeamUtil.ExchangeToRoomId(self._DungeonID)
        local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", roomId)
        local str = ""
        if roomTemplate == nil then
            str = string.format(StringTable.Get(22006), TeamUtil.GetTeamRoomNameByDungeonId(self._DungeonID))
        else
            str = string.format(StringTable.Get(22006), RichTextTools.GetElsePlayerNameRichText(roomTemplate.DisplayName, false))
        end
        GUI.SetText(self._PanelObject.Lab_MsgTitle, str)
    end
end

def.method().UpdateBuyCountInfo = function(self)
    local remain_count = game._DungeonMan:GetRemainderCount(self._DungeonID)
    local bHave = remain_count > 0
    local root = self._PanelObject

    local hp = game._HostPlayer
    local member = self:GetMemberById(hp._ID)

    root.Btn_Yes:SetActive( bHave and not member._IsFollow )
    root.Btn_Buy:SetActive( not bHave and not member._IsFollow )

    if not bHave then
        local dungeonTemplate = CElementData.GetTemplate("Instance", self._DungeonID)
        local info = game._CCountGroupMan:MoneyInfoByCountGroupId(dungeonTemplate.CountGroupTid)

        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(955),
            [EnumDef.CommonBtnParam.MoneyID] = info.MoneyType,
            [EnumDef.CommonBtnParam.MoneyCost] = info.MoneyCount
        }
        self._CommonBtn_Buy:ResetSetting(setting)
    end
end

def.method().ResetAll = function(self)
    self:ResetTeamMemberList()
    self:ResetItemList()
    self:UpdateItemList()
end

def.method().ResetTeamMemberList = function(self)
    if self._IsMatchMode then
        self._TeamMemberList = {}
        self._TeamMemberList = self._MatchList
    else
        self._TeamMemberList = {}
        self._TeamMemberList = self._TeamMan:GetMemberList()
    end
end
--初始化控件信息
def.method().ResetItemList = function(self)
    self._PanelObject.TeamMemberItemList = {}
    local memberCnt = #self._TeamMemberList


    self._PanelObject.PlayerItemGroup:SetActive(not self._IsBigTeam)
    self._PanelObject.PlayerTenItemGroup:SetActive(self._IsBigTeam)


    if self._IsBigTeam then
        memberCnt = #self._TeamMemberList
        local uiTemplate = self._PanelObject.PlayerTenItemGroup:GetComponent(ClassType.UITemplate)
        for i=1, 10 do
            local obj = uiTemplate:GetControl(i-1)
            if obj == nil then
                warn("obj is null??????????? 1111")
            end

            local bShow = (i <= memberCnt)
            obj:SetActive( bShow )
            if bShow then
                local member = self._TeamMemberList[i]
                local key = self._IsMatchMode and member.RoleID or member._ID
                self._PanelObject.TeamMemberItemList[key] = obj
            end
        end

    else
        for i=1,5 do
            local obj = self:GetUIObject('Item'..i)
            if obj == nil then
                warn("obj is null???????????")
            end

            local bShow = (i <= memberCnt)
            obj:SetActive( bShow )
            if bShow then
                local member = self._TeamMemberList[i]
                local key = self._IsMatchMode and member.RoleID or member._ID
                self._PanelObject.TeamMemberItemList[key] = obj
            end
        end
    end
end

def.method().UpdateItemList = function(self)
    for i, member in ipairs( self._TeamMemberList ) do
        local key = self._IsMatchMode and member.RoleID or member._ID
        if self._PanelObject.TeamMemberItemList[key] ~= nil then
            if self._IsMatchMode then
                self:SetMatchItemInfo(self._PanelObject.TeamMemberItemList[key], member, i)
            else
                self:SetItemInfo(self._PanelObject.TeamMemberItemList[key], member, i)
            end
        end
    end
end

def.method("userdata", "table", "number").SetMatchItemInfo = function(self, item, memberInfo, index)
    local CElementData = require "Data.CElementData"
    local prof_template = CElementData.GetProfessionTemplate(memberInfo.Profession)
    GUITools.SetProfSymbolIcon(item:FindChild("Lab_Name/Img_Prof"), prof_template.SymbolAtlasPath)

    local name = ""
    if tonumber(memberInfo.Name) ~= nil then
        local npcName = CElementData.GetTextTemplate(tonumber(memberInfo.Name))
        name = npcName.TextContent
    else
        name = memberInfo.Name
    end

    if GUITools.UTFstrlen(name) > 4 then
        GUI.SetText(item:FindChild("Lab_Name"), GUITools.SubUTF8String(name, 1, 4).."...")
    else
        GUI.SetText(item:FindChild("Lab_Name"), name)
    end

    TeraFuncs.SetEntityCustomImg(item:FindChild("Img_ItemIcon"),memberInfo.RoleID,memberInfo.CustomImgSet,memberInfo.Gender,memberInfo.Profession)

    if memberInfo.RoleID == game._HostPlayer._ID then
        self._PanelObject.Lab_Sure:SetActive(false)
        self._PanelObject.Btn_Yes:SetActive(true)
        self._PanelObject.Btn_No:SetActive(true)
    else
        self._DoTweenPlayerTen:Restart(index)
    end

    item:FindChild("Img_Ready"):SetActive(memberInfo.IsPlayerMirror)
    local Img_AssistTag = item:FindChild("Img_AssistTag")
    if Img_AssistTag ~= nil then
        Img_AssistTag:SetActive(memberInfo.IsPlayerMirror)
    end
end

--设置单个UI信息
def.method("userdata", "table", "number").SetItemInfo = function(self, item, memberInfo, index)
    local CElementData = require "Data.CElementData"
    local prof_template = CElementData.GetProfessionTemplate(memberInfo._Profession)
    GUITools.SetProfSymbolIcon(item:FindChild("Lab_Name/Img_Prof"), prof_template.SymbolAtlasPath)
    if self._IsBigTeam then
        if GUITools.UTFstrlen(memberInfo._Name) > 4 then
            GUI.SetText(item:FindChild("Lab_Name"), GUITools.SubUTF8String(memberInfo._Name, 1, 4).."...")
        else
            GUI.SetText(item:FindChild("Lab_Name"), memberInfo._Name)
        end
    else
        GUI.SetText(item:FindChild("Lab_Name"), memberInfo._Name)
    end
    
    if memberInfo._Gender == EnumDef.Gender.Female then
        GUITools.SetHeadIcon(item:FindChild("Img_ItemIcon"), prof_template.FemaleIconAtlasPath)
    else
        GUITools.SetHeadIcon(item:FindChild("Img_ItemIcon"), prof_template.MaleIconAtlasPath)
    end

    if memberInfo._ID == game._HostPlayer._ID then
        self._PanelObject.Lab_Sure:SetActive(memberInfo._IsFollow)
        self._PanelObject.Btn_Yes:SetActive(not memberInfo._IsFollow)
        self._PanelObject.Btn_No:SetActive(not memberInfo._IsFollow)
    else
        if self._IsBigTeam then
            self._DoTweenPlayerTen:Restart(index)
        else
            self._DoTweenPlayer:Restart(index)
        end
    end
    
    item:FindChild("Img_Ready"):SetActive(memberInfo._IsFollow or memberInfo._IsAssist)
    local Img_AssistTag = item:FindChild("Img_AssistTag")
    if Img_AssistTag ~= nil then
        Img_AssistTag:SetActive(memberInfo._IsAssist)
    end
end

def.method().DoConfirm = function(self)
    if self._CallBack ~= nil then
        self._CallBack(true)
    end
    if self._IsMatchMode then
        self._PanelObject.Lab_Sure:SetActive(true)
        self._PanelObject.Btn_Yes:SetActive(false)
        self._PanelObject.Btn_No:SetActive(false)
        GUI.SetText(self._PanelObject.Lab_Sure, StringTable.Get(26002))
    end
end

def.override("string").OnClick = function(self,id)
	if id == "Btn_Yes" then
        self:DoConfirm()
	elseif id == "Btn_No" then
        if self._CallBack ~= nil then
            self._CallBack(false)
        end
        if self._IsMatchMode then
            self._PanelObject.Lab_Sure:SetActive(true)
            self._PanelObject.Btn_Yes:SetActive(false)
            self._PanelObject.Btn_No:SetActive(false)
            GUI.SetText(self._PanelObject.Lab_Sure, StringTable.Get(246))
            HideSelf()
        end
    elseif id == "Btn_Buy" then
        local dungeonTid = TeamUtil.ExchangeToDungeonId(self._DungeonID)
        local remainderCount = game._DungeonMan:GetRemainderCount(self._DungeonID)
        local dungeonTemplate = CElementData.GetTemplate("Instance", self._DungeonID)
        game._CCountGroupMan:BuyCountGroup(remainderCount ,dungeonTemplate.CountGroupTid)
	end
end

def.method("number", "=>", "number").GetIndexById = function(self, roleId)
    local index = 0
    for i,v in ipairs(self._TeamMemberList) do
        if self._IsMatchMode then
            if v.RoleID == roleId then
                index = i
                break
            end
        else
            if v._ID == roleId then
                index = i
                break
            end
        end
    end

    return index
end

def.method("number", "=>", "table").GetMemberById = function(self, roleId)
    local info = nil
    for i,v in ipairs(self._TeamMemberList) do
        if self._IsMatchMode then
            if v.RoleID == roleId then
                info = v
                break
            end
        else
            if v._ID == roleId then
                info = v
                break
            end
        end
    end

    return info
end

--更新确认入队的图标
def.method('number').UpdateTeamMemberConfirmed = function(self,roleId)
    if instance == nil or not instance:IsShow() then return end 

    local item = self._PanelObject.TeamMemberItemList[roleId]
    if item == nil then return end
    if self._IsMatchMode then
        local index = self:GetIndexById(roleId)
        self._DoTweenPlayerTen:Stop(index)
        self._DoTweenPlayerTen:GoToStartPos(index)    
    else
        if roleId == game._HostPlayer._ID then
            self._PanelObject.Lab_Sure:SetActive(true)
            self._PanelObject.Btn_Yes:SetActive(false)
            self._PanelObject.Btn_No:SetActive(false)
            self._PanelObject.Btn_Buy:SetActive(false)
        else
            local index = self:GetIndexById(roleId)
            if self._IsBigTeam then
                self._DoTweenPlayerTen:Stop(index)
                self._DoTweenPlayerTen:GoToStartPos(index)      
            else
                self._DoTweenPlayer:Stop(index)
                self._DoTweenPlayer:GoToStartPos(index)
            end
        end
    end
    
	local Img_Ready = item:FindChild("Img_Ready")
    Img_Ready:SetActive(true)
end

def.override().OnHide = function(self)
    if self._TimerId > 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end

    if self._Sld_Ready ~= nil then
        GUITools.DoKillSlider(self._Sld_Ready)
    end
    CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    if self._CommonBtn_Buy ~= nil then
        self._CommonBtn_Buy:Destroy()
        self._CommonBtn_Buy = nil
    end
    self._PanelObject = nil
    self._TeamMemberList = nil
    self._Sld_Ready = nil
    self._DoTweenPlayer = nil
    self._DoTweenPlayerTen = nil
    self._CallBack = nil
    self._MatchList = nil
end

CPanelUITeamConfirm.Commit()
return CPanelUITeamConfirm