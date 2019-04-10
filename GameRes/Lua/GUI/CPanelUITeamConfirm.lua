local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CTeamMan = require "Team.CTeamMan"
local CCommonBtn = require "GUI.CCommonBtn"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")

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

def.static("=>", CPanelUITeamConfirm).Instance = function()
	if not instance then
		instance = CPanelUITeamConfirm()
		instance._PrefabPath = PATH.UI_TeamConfirm
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true

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

    self._DoTweenPlayer = self:GetUIObject("PlayerItemGroup"):GetComponent(ClassType.DOTweenPlayer)
    self._DoTweenPlayerTen = self:GetUIObject("PlayerTenItemGroup"):GetComponent(ClassType.DOTweenPlayer)
    self._PanelObject.Lab_Sure:SetActive(false)
end                      

local function HideSelf()
    if instance and instance:IsShow() then
        game._GUIMan:CloseByScript(instance)
    end
end

-- 监听购买次数组事件
local function OnCountGroupUpdateEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		instance:UpdateBuyCountInfo()
        CTeamMan.Instance():C2SConfirmParepare(true)
	end
end

def.override("dynamic").OnData = function (self,data)
    if data.MatchList ~= nil then
        self._IsMatchMode = true
        self._MatchList = data.MatchList
        self._LeftTime = data.Duration
    else
        self._IsMatchMode = false
        self._LeftTime = data.Duration/1000
    end
    self:ResetAll()
    self._Sld_Ready = self:GetUIObject('Sld_Ready')
    local img_Cap = self:GetUIObject("Img_Cap1")
    GameUtil.PlayUISfx(PATH.UIFX_Team_Confirm, img_Cap, img_Cap, -1)
    GUITools.DoSlider(self._Sld_Ready, 0, self._LeftTime, nil, HideSelf)

    self._TimerId = _G.AddGlobalTimer(1, false ,function()
        if self._LeftTime > 0 then
            GUI.SetText(self._PanelObject.Lab_LeftTime, string.format(StringTable.Get(22045), self._LeftTime))
            self._LeftTime = self._LeftTime - 1
        else
            _G.RemoveGlobalTimer(self._TimerId)
            self._TimerId = 0
            -- 倒计时结束关闭界面
            game._GUIMan:CloseByScript(self)            
        end
    end)

    if data.DungeonId == nil or data.DungeonId <= 0 then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        self._DungeonID = data.DungeonId
        self:UpdateDungeonTitle()
    end

    if data.CallBack ~= nil then
        self._CallBack = data.CallBack
    end
        
    self._PanelObject.Lab_Reward:SetActive(self._TeamMan:IsBountyMode())
    

	local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
	local event = NotifyPowerSavingEvent()
	event.Type = "Dungeon"
    local targetDungeon = CElementData.GetTemplate("Instance", self._DungeonID)
    if targetDungeon == nil then
		event.Param1=""
	else
		event.Param1=CTeamMan.Instance():GetTeamRoomNameByDungeonId(self._DungeonID)
	end

    self:UpdateBuyCountInfo()

    if not self._IsMatchMode then
        self:UpdateTeamMemberConfirmed(self._TeamMan._Team._TeamLeaderId)
    end

    CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
	CGame.EventManager:raiseEvent(nil, event)
end

def.method().UpdateDungeonTitle = function(self)
    local targetDungeon = CElementData.GetTemplate("Instance", self._DungeonID)
    if targetDungeon == nil then
        GUI.SetText(self._PanelObject.Lab_MsgTitle, StringTable.Get(22007))
    else
        local roomId = self._TeamMan:ExchangeToRoomId(self._DungeonID)
        local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", roomId)
        local str = ""
        if roomTemplate == nil then
            str = string.format(StringTable.Get(22006), CTeamMan.Instance():GetTeamRoomNameByDungeonId(self._DungeonID))
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

    root.Btn_Yes:SetActive( bHave )
    root.Btn_Buy:SetActive( not bHave )

    if not bHave then
        local dungeonTemplate = CElementData.GetTemplate("Instance", self._DungeonID)
        local info = game:MoneyInfoByCountGroupId(dungeonTemplate.CountGroupTid)

        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(955),
            [EnumDef.CommonBtnParam.MoneyID] = info.MoneyType,
            [EnumDef.CommonBtnParam.MoneyCost] = info.MoneyCount   
        }
        root.CommonBtn_Buy = CCommonBtn.new(root.Btn_Buy ,setting)
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
    local is_big_team = CTeamMan.Instance():IsBigTeam()
    local memberCnt = #self._TeamMemberList
    if self._IsMatchMode then
        is_big_team = true
        memberCnt = #self._TeamMemberList
        self._PanelObject.PlayerItemGroup:SetActive(false)
        self._PanelObject.PlayerTenItemGroup:SetActive(true)
        local uiTemplate = self._PanelObject.PlayerTenItemGroup:GetComponent(ClassType.UITemplate)
        for i=1,10 do
            local obj = uiTemplate:GetControl(i-1)
            if obj == nil then
                warn("obj is null??????????? 1111")
            end
            local bShow = (i <= memberCnt)
            obj:SetActive( bShow )
            if bShow then
                local key = self._TeamMemberList[i].RoleID
                self._PanelObject.TeamMemberItemList[key] = obj
            end
        end
    else
        if is_big_team then
            self._PanelObject.PlayerItemGroup:SetActive(false)
            self._PanelObject.PlayerTenItemGroup:SetActive(true)
            local uiTemplate = self._PanelObject.PlayerTenItemGroup:GetComponent(ClassType.UITemplate)
            for i=1,10 do
                local obj = uiTemplate:GetControl(i-1)
                if obj == nil then
                    warn("obj is null??????????? 1111")
                end
                local bShow = (i <= memberCnt)
                obj:SetActive( bShow )
                if bShow then
                    local key = self._TeamMemberList[i]._ID
                    self._PanelObject.TeamMemberItemList[key] = obj
                end
            end
        else
            self._PanelObject.PlayerItemGroup:SetActive(true)
            self._PanelObject.PlayerTenItemGroup:SetActive(false)
            for i=1,5 do
                local obj = self:GetUIObject('Item'..i)
                if obj == nil then
                    warn("obj is null???????????")
                end

                local bShow = (i <= memberCnt)
                obj:SetActive( bShow )
                if bShow then
                    local key = self._TeamMemberList[i]._ID
                    self._PanelObject.TeamMemberItemList[key] = obj
                end
            end
        end
    end
end

def.method().UpdateItemList = function(self)
    for i, member in ipairs( self._TeamMemberList ) do
        if self._IsMatchMode then
            if self._PanelObject.TeamMemberItemList[member.RoleID] ~= nil then
                self:SetMatchItemInfo(self._PanelObject.TeamMemberItemList[member.RoleID], member, i)
            end
        else
            if self._PanelObject.TeamMemberItemList[member._ID] ~= nil then
                if self._IsMatchMode then
                    self:SetMatchItemInfo(self._PanelObject.TeamMemberItemList[member.RoleID], member, i)
                else
                    self:SetItemInfo(self._PanelObject.TeamMemberItemList[member._ID], member, i)
                end
            else
                warn("error teaminfo Item Object nil? | ::UpdateItemList()")
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

    game:SetEntityCustomImg(item:FindChild("Img_ItemIcon"),memberInfo.RoleID,memberInfo.CustomImgSet,memberInfo.Gender,memberInfo.Profession)

    if memberInfo.RoleID == game._HostPlayer._ID then
        self._PanelObject.Lab_Sure:SetActive(false)
        self._PanelObject.Btn_Yes:SetActive(true)
        self._PanelObject.Btn_No:SetActive(true)
    else
        self._DoTweenPlayerTen:Restart(index)
    end

    item:FindChild("Img_Ready"):SetActive(false)
    local Img_AssistTag = item:FindChild("Img_AssistTag")
    if Img_AssistTag ~= nil then
        Img_AssistTag:SetActive(false)
    end
end

--设置单个UI信息
def.method("userdata", "table", "number").SetItemInfo = function(self, item, memberInfo, index)
    local CElementData = require "Data.CElementData"
    local prof_template = CElementData.GetProfessionTemplate(memberInfo._Profession)
    GUITools.SetProfSymbolIcon(item:FindChild("Lab_Name/Img_Prof"), prof_template.SymbolAtlasPath)
    local is_big_team = CTeamMan.Instance():IsBigTeam()
    if is_big_team then
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
        if is_big_team then
            self._DoTweenPlayerTen:Restart(index)
        else
            self._DoTweenPlayer:Restart(index)
        end
    end

    item:FindChild("Img_Ready"):SetActive(memberInfo._IsFollow)
    local Img_AssistTag = item:FindChild("Img_AssistTag")
    if Img_AssistTag ~= nil then
        Img_AssistTag:SetActive(memberInfo._IsAssist)
    end
end

def.override("string").OnClick = function(self,id)
	if id == "Btn_Yes" then
        if self._CallBack ~= nil then
            self._CallBack(true)
        end
        if self._IsMatchMode then
            self._PanelObject.Lab_Sure:SetActive(true)
            self._PanelObject.Btn_Yes:SetActive(false)
            self._PanelObject.Btn_No:SetActive(false)
            GUI.SetText(self._PanelObject.Lab_Sure, StringTable.Get(26002))
        end
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
        local dungeonTid = self._TeamMan:ExchangeToDungeonId(self._DungeonID)
        local remainderCount = game._DungeonMan:GetRemainderCount(self._DungeonID)
        local dungeonTemplate = CElementData.GetTemplate("Instance", self._DungeonID)
        game:BuyCountGroup(remainderCount ,dungeonTemplate.CountGroupTid)
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
            local is_big_team = CTeamMan.Instance():IsBigTeam()
            if is_big_team then
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

CPanelUITeamConfirm.Commit()
return CPanelUITeamConfirm