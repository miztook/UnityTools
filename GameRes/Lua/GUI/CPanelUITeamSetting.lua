local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUITeamSetting = Lplus.Extend(CPanelBase, "CPanelUITeamSetting")
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local UserData = require "Data.UserData"
local ChatChannel = require "PB.data".ChatChannel
local EInstanceTeamType = require "PB.Template".Instance.EInstanceTeamType
local TeamMode = require "PB.data".TeamMode
local FilterMgr = require "Utility.BadWordsFilter".Filter

local def = CPanelUITeamSetting.define
local instance = nil

local local_send_msg_tag = "LOCAL_SEND_MSG"
local smallTeamMaxMemCount = 5
local bigTeamMaxMemCount = 10

def.field(CTeamMan)._TeamMan = nil
def.field('userdata')._List_Left = nil
def.field('userdata')._List_Right = nil
def.field("table")._RoomDataList = nil
def.field("number")._LeftSelectIndex = 1
def.field("number")._RightSelectIndex = 0
def.field("userdata")._LeftSelectItem = nil
def.field("userdata")._RightSelectItem = nil
def.field("userdata")._Frame_ApplyLimit = nil
def.field("table")._TimesGroup = BlankTable
def.field("table")._AllowGroup = BlankTable

-- 队伍数据
def.field("table")._SettingData = nil
def.field('userdata')._Lab_Level = nil
def.field("userdata")._Lab_FightScore = nil
def.field("userdata")._Input_TeamName = nil

def.field("boolean")._LocalAutoApprove = false
def.field("boolean")._LocalApplySwitchState = false

def.field("userdata")._AutoApprove = nil
def.field("userdata")._AutoSendMsg = nil
def.field("userdata")._ApplySwitch = nil

def.field("table")._CheckBox_Friends = BlankTable
def.field("table")._CheckBox_Guild = BlankTable

def.static("=>", CPanelUITeamSetting).Instance = function()
	if not instance then
		instance = CPanelUITeamSetting()
		instance._PrefabPath = PATH.UI_TeamSetting
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._TeamMan = CTeamMan.Instance()
    self._List_Left = self:GetUIObject('List_Left'):GetComponent(ClassType.GNewList)
    self._List_Right = self:GetUIObject('List_Right'):GetComponent(ClassType.GNewList)
    self._Lab_Level = self:GetUIObject('Lab_Level')
    self._Lab_FightScore = self:GetUIObject('Lab_FightScore')
    self._Input_TeamName = self:GetUIObject('Input_TeamName'):GetComponent(ClassType.InputField)
    self._Frame_ApplyLimit = self:GetUIObject('Frame_ApplyLimit')

    do
        -- 自动审批功能
        local tgl_obj =  self:GetUIObject('Rdo_AutoApprove')
        self._AutoApprove = tgl_obj:GetComponent(ClassType.GNewIOSToggle)
        GameUtil.RegisterUIEventHandler(self._Panel, tgl_obj, ClassType.GNewIOSToggle)
    end

    do
        -- 自动发送招募信息
        local tgl_obj = self:GetUIObject('Rdo_AutoSendMsg')
        self._AutoSendMsg = tgl_obj:GetComponent(ClassType.GNewIOSToggle)
        GameUtil.RegisterUIEventHandler(self._Panel, tgl_obj, ClassType.GNewIOSToggle)
    end

    do
        -- 是否限制 队伍加入 工会 / 好友
        local tgl_obj = self:GetUIObject('Rdo_ApplySwitch')
        self._ApplySwitch = tgl_obj:GetComponent(ClassType.GNewIOSToggle)
        GameUtil.RegisterUIEventHandler(self._Panel, tgl_obj, ClassType.GNewIOSToggle)
    end

    self._TimesGroup = 
    {
        Root = self:GetUIObject('TimesGroup'),
        Lab_Times = self:GetUIObject('Lab_Times')
    }

    self._AllowGroup = 
    {
        Root = self:GetUIObject("AllowCountGroup"),
        Lab_AllowCount = self:GetUIObject("Lab_AllowCount")
    }
    self._CheckBox_Friends =
    {
        Open = self:GetUIObject('Img_Open_Friends'),
        Close = self:GetUIObject('Img_Close_Friends'),
    }
    self._CheckBox_Guild = 
    {
        Open = self:GetUIObject('Img_Open_Guild'),
        Close = self:GetUIObject('Img_Close_Guild'),
    }

end

def.override("dynamic").OnData = function (self,data)
    -- 初始化房间数据状态
    self._RoomDataList = TeamUtil.LoadValidTeamRoomData(false)

    --数据
    if self._SettingData == nil then
        self._SettingData = {}
    end
    self._SettingData.TargetId = data.TargetId
    self._SettingData.Level = data.Level
    self._SettingData.CombatPower = data.CombatPower
    self._SettingData.AutoApproval = data.AutoApproval

    -- 特殊处理数据
    self._SettingData.GuildOnly = data.GuildOnly or false
    self._SettingData.FriendOnly = data.FriendOnly or false
    -- 本地限制匹配开关
    self._LocalApplySwitchState = self._SettingData.GuildOnly or self._SettingData.FriendOnly

    -- 计算初始界面 选中位置
    self:InitSelectIndex()

    -- 刷新选中状态
    self:UpdateSelectState()
    -- 同步页面数据
    self:SyncAllSetting()
    -- 同步本地自动发送标志
    self:ChangeAutoSendMsg( self:GetLocalSendMsgState() )
    -- 同步本地限制标志
    self._ApplySwitch.Value = self._LocalApplySwitchState
    -- 同步自动审批标志
    self:ChangeAutoApprove( self._TeamMan:IsAutoApprove() )
    -- 同步组队限制 状态
    self:UpdateApplyUI()

    CPanelBase.OnData(self,data)
end

-- 更新已选中状态，全部刷新
def.method().UpdateSelectState = function(self)
    local count = #self._RoomDataList
    self._List_Left:SetItemCount( count )

    local current_data = self._RoomDataList[self._LeftSelectIndex]
    local sub_count = 0
    if current_data and current_data.ListData ~= nil then
        sub_count = #current_data.ListData
    end
    self._List_Right:SetItemCount( sub_count )
end

-- 初始化界面选中位置
def.method().InitSelectIndex = function(self)
    if self._SettingData.TargetId > 1 then
        -- 有目标情况 计算位置
        self._LeftSelectIndex, self._RightSelectIndex = TeamUtil.GetRoomIndexByID(self._RoomDataList, self._SettingData.TargetId)
    else
        -- 无目标选中 附近
        self._LeftSelectIndex = 1
        self._RightSelectIndex = 0
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1

    if id == "List_Left" then
        local current_data = self._RoomDataList[idx]

        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")
        local Img_IsBigTeam = item:FindChild("Img_IsBigTeam")
        Img_IsBigTeam:SetActive(false)
        Img_Select:SetActive(self._LeftSelectIndex == idx)
        Img_UnableClick:SetActive( not current_data.Open )
        GUI.SetText(Lab_TargetName, current_data.ChannelOneName)

        if self._LeftSelectIndex == idx then
            self._LeftSelectItem = Img_Select
        end
    elseif id == "List_Right" then
        local current_data = self._RoomDataList[self._LeftSelectIndex]
        local current_smallData = current_data.ListData[idx]
        local is_showBig = false
        if current_smallData.Data.PlayingLaw == require "PB.Template".TeamRoomConfig.Rule.DUNGEON then
            local dungeon_temp = CElementData.GetTemplate("Instance", current_smallData.Data.PlayingLawParam1)
            if dungeon_temp then
                is_showBig = dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps
            end
        end
        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")
        local Img_IsBigTeam = item:FindChild("Img_IsBigTeam")
        Img_IsBigTeam:SetActive(is_showBig)
        Img_Select:SetActive(self._RightSelectIndex == idx)
        Img_UnableClick:SetActive( not current_smallData.Open )

        local name = current_smallData.Data.ChannelTwoName
        local limitedLv = current_smallData.Data.DisplayLevel
        local Lab_Lv = item:FindChild("Lab_Lv")
        Lab_Lv:SetActive(limitedLv>0)
        if limitedLv > 0 then
            local str = string.format(StringTable.Get(10714), limitedLv)
            GUI.SetText(Lab_Lv, str)
        end
        
        GUI.SetText(Lab_TargetName, name)

        if self._RightSelectIndex == idx then
            self._RightSelectItem = Img_Select
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Left" or id == "List_Right" then
        if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() then
            TeraFuncs.SendFlashMsg(StringTable.Get(22069), false)
            return
        end
    end
    if id == "List_Left" then
        local Img_Select = item:FindChild("Img_Select")
        if self._LeftSelectItem ~= nil then
            self._LeftSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._LeftSelectIndex = idx
        self._LeftSelectItem = Img_Select

        -- 点击左侧页签 刷新分页签逻辑
        self:OnSelectLeft()

    elseif id == "List_Right" then
        local Img_Select = item:FindChild("Img_Select")
        if self._RightSelectItem ~= nil then
            self._RightSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._RightSelectIndex = idx
        self._RightSelectItem = Img_Select

        -- 点击右侧页签 
        self:OnSelectRight()
    end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_OK" then
        self:OnClick_Btn_OK()
    elseif id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Rdo_AutoApprove" then
        self:ChangeAutoApprove( not self._LocalAutoApprove )
    elseif id == "Rdo_AutoSendMsg" then
        self:ChangeAutoSendMsg( not self:GetLocalSendMsgState() )
    elseif id == "Rdo_ApplySwitch" then
        self:ChangeApplySwitch( not self._LocalApplySwitchState )
        self:UpdateApplyUI()
    elseif id == "Img_Close_Friends" then
        self:ChangeFriendLimitState(true)
    elseif id == "Img_Open_Friends" then
        self:ChangeFriendLimitState(false)
    elseif id == "Img_Close_Guild" then
        self:ChangeGuildLimitState(true)
    elseif id == "Img_Open_Guild" then
        self:ChangeGuildLimitState(false)
    elseif id == "Btn_NumLimitLevelInput" then
        self:OnClickLimitLevelInput()
    elseif id == "Btn_NumFightScoreInput" then
        self:OnClickFightScoreInput()
    end

    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

-- 限制等级
def.method().OnClickLimitLevelInput = function(self)
    local function callback()
        if not self:IsShow() then return end
        local objText = self._Lab_Level:GetComponent(ClassType.Text)
        local lv = tonumber(objText.text) or 0
        self._SettingData.Level = lv
    end

    game._GUIMan:OpenNumberKeyboard(self._Lab_Level,nil, self:GetLevelLimited(), GlobalDefinition.MaxRoleLevel, callback, callback)
end

-- 限制战斗力
def.method().OnClickFightScoreInput = function(self)
    local function callback()
        local objText = self._Lab_FightScore:GetComponent(ClassType.Text)
        local score = tonumber(objText.text) or 0
        self._SettingData.CombatPower = score
    end

    game._GUIMan:OpenNumberKeyboard(self._Lab_FightScore,nil, GlobalDefinition.MinFightScoreNum, GlobalDefinition.MaxFightScoreNum, callback, callback)
end

--当输入框结束操作
def.override("string", "string").OnEndEdit = function(self, id, str)
    local s = tonumber(str)
    if id == "Input_TeamName" then
        local NameChecker = require "Utility.NameChecker"
        if not NameChecker.CheckTeamNameValid(str) then
            self._Input_TeamName.text = self._TeamMan:GetTeamName()
            return
        end
        TeamUtil.ChangeTeamName(str)
    end
end

def.method().OnSelectLeft = function(self)
    -- warn("OnSelectLeft...")
    local current_data = self._RoomDataList[self._LeftSelectIndex]
    local sub_count = 0
    if current_data.ListData ~= nil then
        sub_count = #current_data.ListData
    end

    -- 右侧页签 如果有数据，则默认第一项
    self._RightSelectIndex = sub_count > 0 and 1 or 0
    self._List_Right:SetItemCount( sub_count )

    if sub_count > 0 then
        -- 默认开启 二级页签的位置
        self:OnSelectRight()
    else
        self._SettingData.TargetId = current_data.Data.Id
        self:CheckUpdateSetting()
        self:UpdateDungeonTimes()
    end
end

def.method().OnSelectRight = function(self)
    -- warn("OnSelectRight...")
    local current_data = self._RoomDataList[self._LeftSelectIndex]
    self._SettingData.TargetId = current_data.ListData[self._RightSelectIndex].Data.Id
    self:CheckUpdateSetting()
    self:UpdateDungeonTimes()
end

def.method().OnClick_Btn_OK = function(self)
    local is_big_team = self._TeamMan:IsBigTeam()
    local mem_count = self._TeamMan:GetMemberCount()
    local callback = function(val)
        if val then
            TeamUtil.ModifyMatchSetting(self._SettingData.TargetId, self._SettingData.Level, self._SettingData.CombatPower, self._LocalAutoApprove, self._SettingData.GuildOnly, self._SettingData.FriendOnly)
            -- 发送队伍招募信息
            if self:GetLocalSendMsgState() then
                local param = {
                    TargetId = self._SettingData.TargetId,
                    Level = self._SettingData.Level,
                    CombatPower = self._SettingData.CombatPower,
                }
                self._TeamMan:SendLinkMsg(ChatChannel.ChatChannelRecruit, param)
            end
        end
    end

    if self._SettingData.TargetId > 1 then
        local dungeonId = TeamUtil.ExchangeToDungeonId(self._SettingData.TargetId)
        local dungeon_temp = CElementData.GetTemplate("Instance", dungeonId)
        if dungeon_temp ~= nil then
            if is_big_team then
                if dungeon_temp.InstanceTeamType ~= EInstanceTeamType.EInstanceTeam_Corps then
                    if mem_count > smallTeamMaxMemCount then
                        TeraFuncs.SendFlashMsg(StringTable.Get(22068), false)
                        return
                    else
                        local title, msg, closeType = StringTable.GetMsg(125)
                        local callback1 = function(val)
                            if val then
                                TeamUtil.ChangeTeamMode(TeamMode.Group)
                                callback(true)
                            end
                        end
                        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
                        return
                    end
                end
            else
                if dungeon_temp.InstanceTeamType == EInstanceTeamType.EInstanceTeam_Corps then
                    local title, msg, closeType = StringTable.GetMsg(126)
                    local callback1 = function(val)
                        if val then
                            TeamUtil.ChangeTeamMode(TeamMode.Corps)
                            callback(true)
                        end
                    end
                    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
                    return
                end
            end
        end
    end
    callback(true)
end

-------------------------------------------------------------------------------
--同步成上一次设置成功的数据
def.method().SyncAllSetting = function(self)
    --1. a最低等级
    self:UpdateLevelLimited( self._TeamMan._Team._Setting.Level )
    --2. 战斗力
    self:UpdateFightScore(self._TeamMan._Team._Setting.CombatPower)
    --3. 自动审批
    self:ChangeAutoApprove( self._LocalAutoApprove )
    --4. 更新副本次数信息
    self:UpdateDungeonTimes()
    --5. 刷新 队伍名称/队伍宣言
    self:UpdateTeamName()
    --6. 刷新准入人数
    self:UpdateAllowCount()
end

def.method().ResetAllSetting = function(self)
    if not self:IsShow() then return end

    --1.最低等级
    self:UpdateLevelLimited( self:GetLevelLimited() )
    --2.战斗力
    self:UpdateFightScore(0)
    --3.自动审批
    self:ChangeAutoApprove( self._LocalAutoApprove )
    --4. 更新副本次数信息
    self:UpdateDungeonTimes()
    --5. 刷新 队伍名称/队伍宣言
    self:UpdateTeamName()
    --6. 刷新准入人数
    self:UpdateAllowCount()
end

def.method().CheckUpdateSetting = function(self)
    if self._SettingData.TargetId == self._TeamMan._Team._Setting.TargetId then
        self:SyncAllSetting()
    else
        self:ResetAllSetting()
    end
end

-- 获取 副本最低等级限制
def.method('=>', 'number').GetLevelLimited = function(self)
    local iRet = 1
    local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._SettingData.TargetId)
    if (tmpConfig ~= nil and tmpConfig.PlayingLawParam1 > 0) then
        local data = CElementData.GetTemplate("Instance", tmpConfig.PlayingLawParam1)
        iRet = data.MinEnterLevel or 1
    end

    return iRet
end

-- 切换 组队加入好友限制
def.method("boolean").ChangeFriendLimitState = function(self, bState)
    self._SettingData.FriendOnly = bState

    self._CheckBox_Friends.Open:SetActive(bState)
    self._CheckBox_Friends.Close:SetActive(not bState)
end

-- 切换 组队加入工会限制
def.method("boolean").ChangeGuildLimitState = function(self, bState)
    self._SettingData.GuildOnly = bState

    self._CheckBox_Guild.Open:SetActive(bState)
    self._CheckBox_Guild.Close:SetActive(not bState)
end

-- 切换自动审批
def.method("boolean").ChangeAutoApprove = function(self, bAutoApprove)
    self._AutoApprove.Value = bAutoApprove
    self._LocalAutoApprove = bAutoApprove
end

-- 切换自动发送招募信息
def.method("boolean").ChangeAutoSendMsg = function(self, bAutoSendMsg)
    self:SetLocalSendMsgState(bAutoSendMsg)
    self._AutoSendMsg.Value = bAutoSendMsg
end

-- 切换 是否限制邀请 工会 / 好友
def.method("boolean").ChangeApplySwitch = function(self, bLimited)
    self._ApplySwitch.Value = bLimited
    self._LocalApplySwitchState = bLimited

    -- 数据 直接勾选，[Open 工会 & 好友 可见， Close 不可见]
    self._SettingData.GuildOnly = bLimited
    self._SettingData.FriendOnly = bLimited
end

-- 刷新 限制UI
def.method().UpdateApplyUI = function(self)
    self._Frame_ApplyLimit:SetActive( self._LocalApplySwitchState )

    if self._LocalApplySwitchState then
        self:ChangeFriendLimitState(self._SettingData.FriendOnly)
        self:ChangeGuildLimitState(self._SettingData.GuildOnly)
    end
end

-- 设置 本地默认发送世界招募信息 变量
def.method("boolean").SetLocalSendMsgState = function(self, bState)
    local account = game._NetMan._UserName
    UserData.Instance():SetCfg(local_send_msg_tag, account, bState)
end

-- 获取 本地默认发送世界招募信息 变量
def.method("=>", "boolean").GetLocalSendMsgState = function(self)
    local account = game._NetMan._UserName
    local ret = UserData.Instance():GetCfg(local_send_msg_tag, account)
    return ret == nil and true or ret
end

--1.最低等级
def.method('number').UpdateLevelLimited = function(self, iLevel)
    GUI.SetText(self._Lab_Level, tostring(iLevel))
    self._SettingData.Level = iLevel
end
--2.战斗力
def.method('number').UpdateFightScore = function(self, iFightScore)
    GUI.SetText(self._Lab_FightScore, tostring(iFightScore))
    self._SettingData.CombatPower = iFightScore
end
-- --3. 自动审批
-- def.method("number").UpdateAutoApprove = function(self, bAuto)
--     self._AutoApprove.Value = bAuto
-- end
--4. 刷新副本次数, 副本开启时间
def.method().UpdateDungeonTimes = function(self)
    local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._SettingData.TargetId)
    local bShow = (tmpConfig ~= nil and tmpConfig.PlayingLawParam1 > 0)
    self._TimesGroup.Root:SetActive( bShow )

    if bShow then
        local dungeonId =  tmpConfig.PlayingLawParam1
        local remain_count = game._DungeonMan:GetRemainderCount(dungeonId)
        local max_count = game._DungeonMan:GetMaxRewardCount(dungeonId)
        local str = ""
        if remain_count > 0 then
            str = string.format(StringTable.Get(26005), remain_count, max_count)
        else
            str = string.format(StringTable.Get(26004), remain_count, max_count)
        end
        GUI.SetText(self._TimesGroup.Lab_Times, str)
    end
end
--5. 刷新 队伍名称/队伍宣言
def.method().UpdateTeamName = function(self)
    self._Input_TeamName.text = self._TeamMan:GetTeamName()
end

--6. 刷新准入人数
def.method().UpdateAllowCount = function(self)
    local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", self._SettingData.TargetId)
    local bShow = (tmpConfig ~= nil and tmpConfig.PlayingLawParam1 > 0)
    self._AllowGroup.Root:SetActive(bShow)
    if bShow then
        local dungeonId =  tmpConfig.PlayingLawParam1
        local dungeon_temp = CElementData.GetTemplate("Instance", dungeonId)
        if dungeon_temp then
            local mem_count = dungeon_temp.MinRoleNum
            local str = string.format(StringTable.Get(26005), mem_count, dungeon_temp.MaxRoleNum)
            GUI.SetText(self._AllowGroup.Lab_AllowCount, str)
        else
            warn("找不到地牢模板数据： ID： ", dungeonId)
        end
    end
end

-------------------------------------------------------------------------------

def.override().OnDestroy = function (self)
    instance = nil
end

CPanelUITeamSetting.Commit()
return CPanelUITeamSetting