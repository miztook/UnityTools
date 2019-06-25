--
--通用结算界面
--
--【孟令康】
--
--2017年04月12日
--
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelDungeonEnd = Lplus.Extend(CPanelBase, "CPanelDungeonEnd")
local def = CPanelDungeonEnd.define
local EJJC1x1RewardResult = require "PB.net".S2CJJC1x1Reward.EJJC1x1RewardResult
local EJJC3V3RewardResult = require "PB.net".S2CArenaReward.EResult
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local MapBasicConfig = require "Data.MapBasicConfig"
local CPageManHead = require "GUI.CPageManHead"
local CModel = require "Object.CModel"
local CPanelUIQuickUse = require"GUI.CPanelUIQuickUse"
local CPanelMinimap = require "GUI.CPanelMinimap"
local CPanelMirrorArena = require"GUI.CPanelMirrorArena"
local CPage3V3 = require"GUI.CPage3V3"
local CTeamMan = require "Team.CTeamMan"
local EResourceType = require "PB.data".EResourceType
local EDamageStatisticsOpt = require"PB.data".EDamageStatisticsOpt
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local EStatistic = require "PB.net".DamageStatistics.EStatistic
local CPanelLoading = require "GUI.CPanelLoading"


def.field("table")._Data = BlankTable
--def.field("userdata")._HostPlayer = nil
def.field(CModel)._PlayerModel = nil
def.field("userdata")._LabBtnQuite = nil 
def.field("userdata")._FrameInformation = nil 
def.field("userdata")._ImgRankUpArrow = nil 
def.field("userdata")._ImgPointUpArrow = nil 
def.field("userdata")._ImgRankDownArrow = nil 
def.field("userdata")._ImgPointDownArrow = nil 
def.field("userdata")._LabPoint = nil 
def.field("userdata")._LabRank = nil 
def.field("userdata")._LabPointChange = nil 
def.field("userdata")._LabRankChange = nil 
def.field("userdata")._Frame_Rank = nil 
def.field("userdata")._Frame_Point = nil 
def.field("userdata")._LabBtnQuitTime = nil 
def.field("userdata")._LabBtnAgainTime = nil 
def.field("userdata")._FrameGuildList = nil 

def.field('userdata')._FrameVictory = nil 
def.field('userdata')._FrameLose = nil 
def.field('userdata')._FrameEnd = nil 
def.field("userdata")._FrameButton = nil 
def.field("userdata")._LabQuitBattle = nil 
def.field("userdata")._ViewGift = nil
def.field("userdata")._CurGoldInstanceItem = nil
def.field("userdata")._BtnAgain = nil 
def.field("userdata")._List_Players = nil

def.field("table")._InstanceScoreTable = nil 

def.field("number")._CurType = 0  --当前界面的类型
def.field("number")._RankChange = 0 
def.field("number")._PointChange = 0 
def.field("number")._MaxKillNum = 0
def.field("number")._MaxCure = 0 
def.field("number")._MaxDmg = 0
def.field("number")._MaxGetDmg =0
def.field("table")._DetailData = nil
def.field("number")._LoadingTimerID = 0 
def.field("number")._DetailInfoTimerID = 0
def.field("number")._CurRemainCount = 0
--组队情况下点击再次挑战
def.field("boolean")._IsAgainTeam = false

--最终播放的动画名称
def.field("string")._FinalAnimation = ''

--最终播放的站立动画名称 victory_stand_c | defeat_stand_c_c
def.field("string")._FinalStandAnimation = ''
def.field("table")._TimeIDs = BlankTable
def.field("number")._EndTimerID = 0 
def.field("table")._BattleRewardItemData = nil
def.field("table")._UIFXTimers = BlankTable

def.field("table")._UI3V3FxTimers = BlankTable 



local _CamerParam =
{
    [1] =
    {
        pos = Vector3.New( -0.154, 0.95, 2.854 ),
        rot = Vector3.New( 1.433, 193.2, 0.05 )
    },
    [2] =
    {
        pos = Vector3.New( 0.016, 1.251, 2.808 ),
        rot = Vector3.New( 8.75, 192.65, 1.2 )
    },
    [3] =
    {
        pos = Vector3.New( 0.422, 0.959, 2.593 ),
        rot = Vector3.New( 0, 204.55, 0 )
    },
    [4] =
    {
        pos = Vector3.New( -0.29, 0.987, 2.71 ),
        rot = Vector3.New( 0, 188.1, 0 )  --{ 0, 195, 0 }
    },
    [5] =
    {
        pos = Vector3.New( 0.016, 1.251, 2.808 ),
        rot = Vector3.New( 8.75, 192.65, 1.2 )
    },
}

local instance = nil
def.static("=>", CPanelDungeonEnd).Instance = function()
    if not instance then
        instance = CPanelDungeonEnd()
        instance._PrefabPath = PATH.UI_Dungeon_End
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

-- 更新显示次数
local function UpdateInfoEnterTime(self)
    local tid = game._DungeonMan:GetDungeonID()
    local template = CElementData.GetInstanceTemplate(tid)
    if template == nil  then warn("dungeonTid Instance Template is nil " ..tid) return end
    local maxCount = game._CCountGroupMan:OnCurMaxCount(template.CountGroupTid)
    self._CurRemainCount = game._DungeonMan:GetDungeonData(tid).RemainderTime
    if self._CurRemainCount == 0 then
        -- 剩余次数变红
        GUI.SetText(self._LabBtnAgainTime, string.format(StringTable.Get(20081), self._CurRemainCount, maxCount))
    elseif self._CurRemainCount > maxCount then
        -- 剩余次数大于初始最大次数时变绿
        GUI.SetText(self._LabBtnAgainTime, string.format(StringTable.Get(20082), self._CurRemainCount, maxCount))
    else
        GUI.SetText(self._LabBtnAgainTime, self._CurRemainCount.."/"..maxCount)
    end
end

local function OnCountGroupUpdateEvent(sender, event)
    if instance ~= nil then
        -- 更新对应界面信
        UpdateInfoEnterTime(instance)
    end
end

--0:副本;1:试炼;2:1v1;3:3v3,4:淘汰试炼（无为战场）;
--接收数据
def.override().OnCreate = function (self)
    --self._LabBtnQuite = self:GetUIObject("Lab_Quit1")
    self._FrameInformation = self:GetUIObject("Frame_Information")
    self._ImgPointUpArrow = self:GetUIObject("Img_PointUpArrow")
    self._ImgPointDownArrow = self:GetUIObject("Img_PointDownArrow")
    self._ImgRankUpArrow = self:GetUIObject("Img_RankUpArrow")
    self._ImgRankDownArrow = self:GetUIObject("Img_RankDownArrow")
    self._LabPoint = self:GetUIObject("Lab_PointValues1")
    self._LabPointChange = self:GetUIObject("Lab_PointValues2")
    self._LabRank = self:GetUIObject("Lab_RankValues1")
    self._LabRankChange = self:GetUIObject("Lab_RankValues2")
    self._Frame_Point = self:GetUIObject("Frame_PointChange")
    self._Frame_Rank = self:GetUIObject("Frame_RankChange")
    self._LabBtnQuitTime = self:GetUIObject("Lab_QuitTime")
    self._FrameVictory = self:GetUIObject("Frame_Victory")
    self._FrameEnd = self:GetUIObject("Frame_End")
    self._FrameLose = self:GetUIObject("Frame_Lose")
    self._FrameButton = self:GetUIObject("Frame_Button")
    self._ViewGift = self:GetUIObject("View_Gift")
    self._LabBtnAgainTime = self:GetUIObject("Lab_BtnAgainTime")
    self._BtnAgain = self:GetUIObject("Btn_Again")
    self._List_Players = self:GetUIObject("List_Players")
    self._FrameGuildList = self:GetUIObject("Frame_GuildList"):GetComponent(ClassType.GNewList)
    if CPanelUIQuickUse.Instance()._IsShowQuickUse then
        CPanelUIQuickUse.Instance()._Frame_QuickUse:SetActive(false)
    end
end

def.override("dynamic").OnData = function(self, data)
    CGame.EventManager:addHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
    CDungeonAutoMan.Instance():Stop()
    self._IsAgainTeam = false
    self._Data = data
    self._CurType = data._Type
    self._MaxDmg,self._MaxCure,self._MaxCure = 0,0,0
    self:GetUIObject("Frame1"):SetActive(false)	
    self:GetUIObject("Frame2"):SetActive(false)	
    self:GetUIObject("Frame3"):SetActive(false)	
    self:GetUIObject("Frame4"):SetActive(false)
    self:GetUIObject("Frame5"):SetActive(false)

    self:GetUIObject("Frame_Instance1"):SetActive(false)
    self:GetUIObject("Frame_Instance2"):SetActive(false)
    self:GetUIObject("Frame_GuildDefend"):SetActive(false)
    self:GetUIObject("Frame_PVP1"):SetActive(false)
    self:GetUIObject("Frame_PVP2"):SetActive(false)
    self:GetUIObject("Frame_Battle"):SetActive(false)
    self._FrameButton:SetActive(false)
    do 
        local cb = nil 
        if data._Type == EnumDef.DungeonEndType.InstanceType then
            self._FinalAnimation = EnumDef.CLIP.VICTORY
            self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND
            local function callBack()
               self:ShowInstanceEnd()
            end  
            cb = callBack 
        elseif data._Type == EnumDef.DungeonEndType.TrialType then
            self._FinalAnimation = EnumDef.CLIP.VICTORY
            self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND
            local function callBack()
                self:ShowTrialEnd()
            end 
            cb = callBack  
        elseif data._Type == EnumDef.DungeonEndType.GuildDefend then 
            if not self._Data._InfoData.IsWin then
                self._FinalAnimation = EnumDef.CLIP.DEFEAT
                self._FinalStandAnimation = EnumDef.CLIP.DEFEAT_STAND
            else
                self._FinalAnimation = EnumDef.CLIP.VICTORY
                self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND
            end  
            local function callBack()
                self:ShowGuildDefendEnd()
            end 
            cb = callBack  
        elseif data._Type == EnumDef.DungeonEndType.ArenaOneType then
            if self._Data._InfoData.RewardState == EJJC1x1RewardResult.VICTORY then
                self._FinalAnimation = EnumDef.CLIP.VICTORY
                self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND
            elseif self._Data._InfoData.RewardState == EJJC1x1RewardResult.FAILED then 
                self._FinalAnimation = EnumDef.CLIP.DEFEAT
                self._FinalStandAnimation = EnumDef.CLIP.DEFEAT_STAND
            else
                self._FinalAnimation = EnumDef.CLIP.DEFAET
                self._FinalStandAnimation = EnumDef.CLIP.DEFEAT_STAND
            end  
            local function callBack()
                self:ShowArenaOneEnd()
            end   
            cb = callBack
        elseif data._Type == EnumDef.DungeonEndType.ArenaThreeType then
            if self._Data._InfoData.RewardState == EJJC3V3RewardResult.VICTORY then
                self._FinalAnimation = EnumDef.CLIP.VICTORY
                self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND
            else
                self._FinalAnimation = EnumDef.CLIP.DEFEAT
                self._FinalStandAnimation = EnumDef.CLIP.DEFEAT_STAND
            end
            local function callBack()
                self:ShowArenaThreeEnd()
            end
            cb = callBack
        elseif data._Type == EnumDef.DungeonEndType.EliminateType then 
            self._FinalAnimation = EnumDef.CLIP.VICTORY
            self._FinalStandAnimation = EnumDef.CLIP.VICTORY_STAND  
            local function callBack()
                self:ShowBattleEnd()
            end 
            cb = callBack  
        else
            warn("CPanelDungeonEnd error type")
        end
        self:SetPlayerModel(cb)
    end
    -- 设置再一次挑战按钮
    do 
        local dungeonTid = game._DungeonMan:GetDungeonID()
        local template = CElementData.GetInstanceTemplate(dungeonTid)
        if template == nil  then warn("dungeonTid Instance Template is nil " ..dungeonTid) return end
        if not template.IsChallengeAgain then 
            self._BtnAgain:SetActive(false)
        return end

        self._BtnAgain:SetActive(true)
        if CTeamMan.Instance():InTeam() and not CTeamMan.Instance():IsTeamLeader() and not self._CurType == EnumDef.DungeonEndType.ArenaOneType then 
            local imgIcon = self._BtnAgain:FindChild("Image")
            GameUtil.MakeImageGray(imgIcon, true)
        end
        if self._CurType == EnumDef.DungeonEndType.ArenaThreeType or self._CurType == EnumDef.DungeonEndType.EliminateType then 
            self._LabBtnAgainTime:SetActive(false)
        else
            local maxCount = game._CCountGroupMan:OnCurMaxCount(template.CountGroupTid)
            self._CurRemainCount = game._DungeonMan:GetDungeonData(dungeonTid).RemainderTime
            self._LabBtnAgainTime:SetActive(true)
            if self._CurRemainCount == 0 then
                -- 剩余次数变红
                GUI.SetText(self._LabBtnAgainTime, string.format(StringTable.Get(20081), self._CurRemainCount, maxCount))
            elseif self._CurRemainCount > maxCount then
                -- 剩余次数大于初始最大次数时变绿
                GUI.SetText(self._LabBtnAgainTime, string.format(StringTable.Get(20082), self._CurRemainCount, maxCount))
            else
                GUI.SetText(self._LabBtnAgainTime, self._CurRemainCount.."/"..maxCount)
            end
        end
    end
end

--Button点击
def.override("string").OnClick = function(self, id)
    if id == "Btn_Quit" then
        self:OnLeaveDungeon()
    elseif string.find(id,"Img_Head") then 
        local index = tonumber(string.sub(id,-1))
        local roleId = 0
        if self._CurType == EnumDef.DungeonEndType.InstanceType then
            for i,v in ipairs(self._DetailData._Data[index].statisticDatas) do 
                if v.key == EStatistic.EStatistic_roleId then 
                    roleId = v.value
                break end
            end
            if roleId == game._HostPlayer._ID then return end
        elseif self._CurType == EnumDef.DungeonEndType.ArenaOneType then
            if index == 1 then return end
            for i,Data in ipairs(self._DetailData._Data) do 
                for k,w in ipairs(Data.statisticDatas) do
                    if w.key == EStatistic.EStatistic_roleId then 
                        if  w.value ~= game._HostPlayer._ID then 
                            roleId  = w.value
                            break
                        end
                    end
                end
            end
        elseif self._CurType == EnumDef.DungeonEndType.ArenaThreeType then
            if roleId == game._HostPlayer._ID then return end
            if index <= 3 then 
                roleId = self._DetailData.BlackList[index].RoleId 
            else
                roleId = self._DetailData.RedList[index - 3].RoleId
            end
            if roleId == game._HostPlayer._ID then return end
        end
        game:CheckOtherPlayerInfo(roleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.DungeonEnd)

    elseif id == "Btn_Again" then
        if self._CurRemainCount == 0 then 

            local dungeonTid = game._DungeonMan:GetDungeonID()
            local dungeonTemp = CElementData.GetInstanceTemplate(dungeonTid)
            if dungeonTemp == nil  then warn("dungeonTid Instance Template is nil " ..dungeonTid) return end
            local CountTemp = CElementData.GetTemplate("CountGroup", dungeonTemp.CountGroupTid)
            if CountTemp == nil then warn("CountGroupTid Instance Template is nil " ..dungeonTemp.CountGroupTid) return end
            if CountTemp.InitBuyCount == 0 then 
                game._GUIMan:ShowTipText(StringTable.Get(21706),false)
            return end
            game._CCountGroupMan:BuyCountGroupWhenEnter(dungeonTemp.CountGroupTid)
        return end
        if self._CurType == EnumDef.DungeonEndType.ArenaOneType then 
            -- self:OnLeaveDungeon()
            if self._CurRemainCount > 0 then 
                GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
            end
            game._CArenaMan._IsAgainStart1V1 = true
            game._CArenaMan:SendC2SOpenOne()
            game._GUIMan:SetMainUIMoveToHide(false,nil)
        else
            -- 组队状态
            if CTeamMan.Instance():InTeam() then
                local TeamList = CTeamMan.Instance():GetMemberList()
                if #TeamList > 1 and not CTeamMan.Instance():IsTeamLeader() then 
                    game._GUIMan:ShowTipText(StringTable.Get(933),false)
                    return 
                elseif #TeamList > 1 and CTeamMan.Instance():IsTeamLeader() then 
                    self._IsAgainTeam = true
                    local C2SReStartInstance = require "PB.net".C2SReStartInstance
                    local protocol = C2SReStartInstance()
                    PBHelper.Send(protocol)
                    game._GUIMan:SetMainUIMoveToHide(false,nil)
                return end
            end
            -- 非组队状态
            game._GUIMan:CloseByScript(self)
            game._GUIMan:Open("CPanelLoading" ,{BGResPathId = game._CurWorld._WorldInfo.SceneTid})
            --game._NetMan:SetProtocolPaused(true)
            local C2SReStartInstance = require "PB.net".C2SReStartInstance
            local protocol = C2SReStartInstance()
            PBHelper.Send(protocol)
            game._GUIMan:SetMainUIMoveToHide(false,nil)
            GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
            self:CloseLoadingPanel()
        end 
    end
end

local function SetGuildDefendItem(self,item,data,rank)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local labLv = uiTemplate:GetControl(0)
    local imgDamageBar = uiTemplate:GetControl(1)
    local labName = uiTemplate:GetControl(2)
    local labDamage = uiTemplate:GetControl(3)
    local labRank = uiTemplate:GetControl(4)
    local imgJob = uiTemplate:GetControl(5)
    if rank > 50 then 
        GUI.SetText(labRank,StringTable.Get(20103))
    else
        GUI.SetText(labRank,tostring(rank))
    end
    local value = 0
    if data.DamageTotal ~= 0 then 
        value =  math.min(data.Damage/data.DamageTotal, 1) *100
    end
    GUI.SetText(labDamage,string.format(StringTable.Get(21707),value))
    local bar = imgDamageBar :GetComponent(ClassType.Image)
    bar.fillAmount = data.Damage / self._DetailData[1].Damage
    GUI.SetText(labLv,tostring(data.Level))
    GUI.SetText(labName,data.Name)
    local professionTemplate = CElementData.GetProfessionTemplate(data.ProfessionId)
    if professionTemplate == nil then
        warn("设置职业徽记时 读取模板错误：profession:", data.ProfessionId)
    else
        GUITools.SetProfSymbolIcon(imgJob, professionTemplate.SymbolAtlasPath)
    end
end

--初始化滑动列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_Gift" then
        local frame_icon = GUITools.GetChild(item, 0)
        local lab_tips = GUITools.GetChild(item, 1) -- 已达上限提示
        if self._CurType == EnumDef.DungeonEndType.EliminateType then 
            local data = self._BattleRewardItemData[index + 1]
            lab_tips:SetActive(false)	
            if data.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_icon, data.Data.Id, data.Data.Count)
            else
                IconTools.InitItemIconNew(frame_icon, data.Data.Id, { [EItemIconTag.Number] = data.Data.Count })
            end
        else
            local ItemId = self._Data._InfoData.Rewards[index + 1].ItemId
            if ItemId ~= 0 then
                local tNum = self._Data._InfoData.Rewards[index + 1].ItemNum
                lab_tips:SetActive(false)	
                IconTools.InitItemIconNew(frame_icon,ItemId, { [EItemIconTag.Number] = tNum })
            else
                if self._Data._InfoData.Rewards[index + 1].MoneyId == EResourceType.ResourceTypeArenaPoints and self._CurType == EnumDef.DungeonEndType.ArenaThreeType and self._Data._InfoData.Rewards[index + 1].MoneyNum == 0 then 
                    lab_tips:SetActive(true)
                    IconTools.InitTokenMoneyIcon(frame_icon, self._Data._InfoData.Rewards[index + 1].MoneyId, 0)
                else
                    lab_tips:SetActive(false)
                    IconTools.InitTokenMoneyIcon(frame_icon,self._Data._InfoData.Rewards[index + 1].MoneyId, self._Data._InfoData.Rewards[index + 1].MoneyNum)
                    if self._Data._InfoData.Rewards[index + 1].MoneyId == EResourceType.ResourceTypeGold then 
                        self._CurGoldInstanceItem = frame_icon
                    end
                end
            end
        end
    elseif id == "Frame_BattleList" then 
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local labLv = uiTemplate:GetControl(0)
        local imgHead = uiTemplate:GetControl(1)
        local labJob = uiTemplate:GetControl(2)
        local labName = uiTemplate:GetControl(3)
        local labKill = uiTemplate:GetControl(4)
        local labRank = uiTemplate:GetControl(5)
        local labScore = uiTemplate:GetControl(6)
        local hightLight = uiTemplate:GetControl(7)
        local imgBg = uiTemplate:GetControl(8)
        local labOut = uiTemplate:GetControl(9)
        local labNotOut = uiTemplate:GetControl(10)
        local data = self._DetailData[index + 1]
        local name = data.Name
        if data.RoleId == game._HostPlayer._ID then 
            GUITools.SetUIActive(hightLight,true)
            name =  "<color=#ECBE33FF>" .. name .."</color>" 
        else
            GUITools.SetUIActive(hightLight,false)
        end
        GUI.SetText(labRank,tostring(index + 1))
        GUI.SetText(labKill,tostring(data.KillNum))

        GUI.SetText(labName,name)
        GUI.SetText(labLv,tostring(data.Level))
        GUI.SetText(labJob,tostring(StringTable.Get(10300 + data.Profession - 1)))
        game:SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
        if not self._Data._IsOut then 
            GUITools.SetUIActive(labNotOut,false)
            if index + 1 <= 6 then 
                GUITools.SetUIActive(labScore,true)
                GUI.SetText(labScore,GUITools.FormatMoney(data.Score))
                GUITools.SetUIActive(labOut,false)
            else
                GUITools.SetUIActive(labOut,true)
                GUITools.SetUIActive(labScore,false)
            end
        else
            GUITools.SetUIActive(labOut,false)
            if index + 1 <= 6 then 
                GUITools.SetUIActive(labScore,false)
                GUITools.SetUIActive(labNotOut,true)
            else
                GUITools.SetUIActive(labScore,true)
                GUITools.SetUIActive(labNotOut,false)
                GUITools.SetUIActive(labOut,false)
                GUI.SetText(labScore,tostring(data.Score))
            end
        end
    elseif id == "List_Players" then
        local data = self._DetailData._Data[index + 1]
        self:SetFramePlayer(item, data)
    elseif id == "Frame_GuildList" then 
        SetGuildDefendItem(self,item,self._DetailData[index + 1],index + 1)
    end
end

--选中滑动列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Gift" then
        if self._CurType == EnumDef.DungeonEndType.EliminateType then 
            if self._BattleRewardItemData.IsTokenMoney then
                local panelData = 
                    {
                        _MoneyID = self._BattleRewardItemData.Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = item ,   
                    }
                CItemTipMan.ShowMoneyTips(panelData)
            else
                CItemTipMan.ShowItemTips(self._BattleRewardItemData.Data.Id, TipsPopFrom.OTHER_PANEL ,item,TipPosition.FIX_POSITION) 
            end
        else
            local itemTid = self._Data._InfoData.Rewards[index + 1].ItemId
            local moneyId = self._Data._InfoData.Rewards[index + 1].MoneyId
            if itemTid ~= nil and itemTid ~= 0 then
                CItemTipMan.ShowItemTips(itemTid, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
            elseif moneyId ~= 0 then  
                local panelData = 
                    {
                        _MoneyID = moneyId ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = item ,   
                    }
                CItemTipMan.ShowMoneyTips(panelData)
            end
        end
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id == "Frame_BattleList" then 
        if id_btn == "Img_Head" then 
            local roleId = 0 
            roleId = self._DetailData[index + 1].RoleId
            game:CheckOtherPlayerInfo(roleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.DungeonEnd)
        end
    end
end

--副本结束设置角色
def.method("function").SetPlayerModel = function(self,cb1)
    --关闭MirrorHead
    CPageManHead.Instance():Hide()

    local dungeonEndInfo = MapBasicConfig.GetDungeonEnd()[game._CurWorld._WorldInfo.SceneTid]
    if dungeonEndInfo == nil then
        -- game._GUIMan:ShowTipText("请配置最终展示点", false)
        return
    end

    if self._PlayerModel ~= nil then
        self._PlayerModel:Destroy()
        self._PlayerModel = nil
    end

    local hp = game._HostPlayer
    local modelParams = hp:GetModelParams()
    modelParams._IsWeaponInHand = false

    local function cb()
        if self._PlayerModel == nil then return end
        local model = self._PlayerModel
        local go = model:GetGameObject()
        GameUtil.SetLayerRecursively(go, EnumDef.RenderLayer.HostPlayer)
        GameUtil.SetLayerRecursively(hp:GetCurModel():GetGameObject(), EnumDef.RenderLayer.Player)

        -- 2018.08.30 应瑞龙&腾飞需求做以下修改：
        -- 播放欢呼时 武器全部改到背上，不在分职业单独处理；
        -- 直接播展示动画，前面不再播Stand
        model:PlayAnimation(self._FinalAnimation, 0.1, false, 0, 1)
        model:PlayAnimation(self._FinalStandAnimation, 0, true, 0, 1)

        local pCombatStateChangeComp = go:GetComponent(ClassType.CombatStateChangeBehaviour)
        if pCombatStateChangeComp == nil then
            pCombatStateChangeComp = go:AddComponent(ClassType.CombatStateChangeBehaviour)
        end
        pCombatStateChangeComp:ChangeState(true, false, 0, 0)

        -- 设置位置与朝向
        go.parent = nil
        local position = dungeonEndInfo.position
        position = Vector3.New(position.x, position.y, position.z)
        position.y = GameUtil.GetMapHeight(position)
        go.position = position
        local rotation = dungeonEndInfo.rotation
        go.rotation = Quaternion.Euler(rotation.x, rotation.y, rotation.z)

        --在此设置镜头参数
        local profession = hp._InfoData._Prof
        local cam_param = _CamerParam[profession];
        --设置镜头额外参数
        GameUtil.SetCameraParamsEX(EnumDef.CAM_CTRL_MODE.DUNGEON, cam_param.pos, cam_param.rot, 50);
        GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.DUNGEON, go, 1, cb1)

        --屏蔽物体
        self:SetGameObjectLayerVisible(false)
    end
    self._PlayerModel = CModel.new()
    self._PlayerModel:LoadWithModelParams(modelParams, cb)
end

--屏蔽/显示对象
def.method("boolean").SetGameObjectLayerVisible = function(self, isOn)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Player, isOn)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.NPC, isOn)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.EntityAttached, isOn)
    GameUtil.SetCurLayerVisible(EnumDef.RenderLayer.Fx, isOn)

    local CPate = require "GUI.CPate".CPateBase
    CPate.ShowAll(isOn)
end

--离开副本
def.method().OnLeaveDungeon = function(self)
    if game._GuildMan:IsInGuildScene() then
        game._GUIMan:CloseByScript(self)
        return 
    end
    game._GUIMan:SetMainUIMoveToHide(false,nil)
    game._DungeonMan:TryExitDungeon()
end

--展示详细信息
def.method().OnShowDetail = function(self)
    self:RemoveDetailInfoTimer()
    self._FrameInformation:SetActive(false)
    local startTime = 0 
    local function callback()
        startTime = startTime + 1
        if startTime >= 5 then 
            self._FrameInformation:SetActive(true)
            local C2SDamageStatistics = require "PB.net".C2SDamageStatistics
            local protocol = C2SDamageStatistics()
            if self._CurType == EnumDef.DungeonEndType.ArenaOneType then 
                protocol.opt = EDamageStatisticsOpt.EDamageStatisticsOpt_1v1 
            elseif self._CurType == EnumDef.DungeonEndType.ArenaThreeType then 
                protocol.opt = EDamageStatisticsOpt.EDamageStatisticsOpt_pvp3v3
            elseif self._CurType == EnumDef.DungeonEndType.EliminateType then
                self._DetailData = self._Data._AllRoleDataList
                self:ShowEliminatePlayer(self._DetailData)
                self:RemoveDetailInfoTimer()
                return
            elseif self._CurType == EnumDef.DungeonEndType.GuildDefend then 
                protocol.opt = EDamageStatisticsOpt.EDamageStatisticsOpt_GuildDefense
            else
                protocol.opt = EDamageStatisticsOpt.EDamageStatisticsOpt_dungeonNormalEnd
            end
            PBHelper.Send(protocol)
            _G.RemoveGlobalTimer(self._DetailInfoTimerID)
            self._DetailInfoTimerID = 0
        end
    end
    self._DetailInfoTimerID = _G.AddGlobalTimer(1,false,callback)
end

--副本结束界面倒计时
def.method("number").AddDungeonEndTimer = function(self, time)
    if self._EndTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._EndTimerID)
        self._EndTimerID = 0
    end
    local endTime = GameUtil.GetServerTime()/1000 + time
    if self._EndTimerID == 0 then
        local callback = function()
            time = math.floor(endTime - GameUtil.GetServerTime()/1000)
            if time <= 0 then
                self:RemoveDungeonEndTimer()
                if not self._IsAgainTeam then 
                    game._GUIMan:CloseByScript(self)
                end
            return end
            local second = time % 60
            if second < 10 then
                second = "0" .. second
            end
            GUI.SetText(self._LabBtnQuitTime,string.format(StringTable.Get(905),second))
        end
        self._EndTimerID = _G.AddGlobalTimer(1, false, callback)
    end
end

--清除倒计时
def.method().RemoveDungeonEndTimer = function(self)
    if self._EndTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._EndTimerID)
        self._EndTimerID = 0
    end
    if self._CurType == EnumDef.DungeonEndType.EliminateType and self._Data._IsOut then 
        self:OnLeaveDungeon()
    end
end

-- 清除详细信息计时器
def.method().RemoveDetailInfoTimer = function(self)
    if self._DetailInfoTimerID ~= 0 then 
        _G.RemoveGlobalTimer(self._DetailInfoTimerID)
        self._DetailInfoTimerID = 0 
    end
end

-- 再来一次的loading界面 遮挡穿帮
def.method().CloseLoadingPanel = function(self)
    local function cb()
        if CPanelMinimap.Instance():IsShow() then 
            CPanelMinimap.Instance():SetExitBtnState()
        end
    end

    if self._LoadingTimerID > 0 then 
        _G.RemoveGlobalTimer(self._LoadingTimerID)
        self._LoadingTimerID = 0 
    end
    local startTime = 0 
    local function callback ()
        startTime = startTime + 1 
        if startTime >= 3 then 
            CPanelLoading.Instance():AttemptCloseLoading(cb)
            _G.RemoveGlobalTimer(self._LoadingTimerID)
            self._LoadingTimerID = 0 
        end
    end
    self._LoadingTimerID = _G.AddGlobalTimer(1,false,callback)
end

----------[副本]----------

def.method().ShowInstanceEnd = function(self)
    self._FrameButton:SetActive(true)
    self:OnShowDetail()
    self._FrameEnd:SetActive(true)
    self._FrameVictory:SetActive(false)
    self._FrameLose:SetActive(false)
    self._ViewGift:SetActive(true)		
    local infoData = self._Data._InfoData
    local dungeon = CElementData.GetTemplate("Instance", infoData.InstanceTId)	
    self:GetUIObject("Frame_Time"):SetActive(true)
    GUI.SetText(self:GetUIObject("Lab_InstanceName0"), dungeon.TextDisplayName)
    GUI.SetText(self:GetUIObject("Lab_TimeValues0"), GUITools.FormatTimeSpanFromSeconds(infoData.PassTime))
    local imgPoint = self:GetUIObject("Img_Point")
    GUITools.SetGroupImg(imgPoint,infoData.ScoreGrade - 1 )
    do  --添加副本结束的UI特效
        local imgPointFx = imgPoint:FindChild("Img_PointFX")
        if infoData.ScoreGrade <= 1 then
            GameUtil.PlayUISfx(PATH.UIFX_Dungeon_End_YellowScore, imgPointFx, imgPointFx, -1)
        else
            GameUtil.PlayUISfx(PATH.UIFX_Dungeon_End_BlueScore, imgPointFx, imgPointFx, -1)
        end
        local img_Point = self._FrameEnd:FindChild("Img_ResultTitle")
        GameUtil.PlayUISfx(PATH.UIFX_PVP1_End_Victory, img_Point, img_Point, -1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_DungeonEnd,0)
        self:GetUIObject("Frame_Instance1"):SetActive(true)
    end
    self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#infoData.Rewards)
    self:AddDungeonEndTimer(infoData.DurationSeconds)
    local frameTeam = self:GetUIObject("Frame_Team")
    if infoData.TeamExpAddtionRate <= 0 then 
        frameTeam:SetActive(false)
    else
        frameTeam:SetActive(true)
        GUI.SetText(self:GetUIObject("Lab_Team"),string.format(StringTable.Get(21703),infoData.TeamExpAddtionRate * 100))
    end
    local frameGold = self:GetUIObject("Frame_Glod")
    if self._InstanceScoreTable == nil then 
        frameGold:SetActive(false)
    else
        frameGold:SetActive(true)
        local labScore = self:GetUIObject("Lab_ScoreRatio")
        local value = self._InstanceScoreTable.Ratio * 100
        GUI.SetText(labScore,string.format(StringTable.Get(21703),value))
    end
    if self._CurGoldInstanceItem == nil then return end
    IconTools.SetTags(self._CurGoldInstanceItem, { [EItemIconTag.Number] = self._InstanceScoreTable.ConversionNum } )
end

--副本结束界面详细信息
def.method("table").ShowInstancePlayer = function(self,data)
    if not self:IsShow() then return end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_DungeonDetails,0)
    self._DetailData = data
    self._FrameInformation:SetActive(true)
    self:GetUIObject("Frame3"):SetActive(true)

--    local count = #data._Data
--    if count == 1 then
--        self:GetUIObject("Frame_Player22"):SetActive(false)
--        self:GetUIObject("Frame_Player31"):SetActive(false)
--        self:GetUIObject("Frame_Player41"):SetActive(false)
--        self:GetUIObject("Frame_Player51"):SetActive(false)	
--    elseif count == 2 then
--        self:GetUIObject("Frame_Player31"):SetActive(false)
--        self:GetUIObject("Frame_Player41"):SetActive(false)
--        self:GetUIObject("Frame_Player51"):SetActive(false)	
--    elseif count == 3 then
--        self:GetUIObject("Frame_Player41"):SetActive(false)
--        self:GetUIObject("Frame_Player51"):SetActive(false)	
--    elseif count == 4 then
--        self:GetUIObject("Frame_Player51"):SetActive(false)	
--    end
    self._List_Players:GetComponent(ClassType.GNewList):SetItemCount(#data._Data)
--    if count > 1 then 
--        self._MaxGetDmg,self._MaxCure, self._MaxDmg = self:MaxValue(data._Data)
--    end
--    for i, v in ipairs(data._Data) do
--        if i == 1 or i == 2 then 
--            self:SetFramePlayer(self:GetUIObject("Frame_Player"..i..2),data._Data[i])
--        else
--            self:SetFramePlayer(self:GetUIObject("Frame_Player"..i..1),data._Data[i])
--        end
--    end
end

-- 策划目前定死是对金币的系数加成
def.method("number","number","number").SaveInstanceScore = function (self,resourceType,ratio,conversionNum)
    self._InstanceScoreTable = {}
    self._InstanceScoreTable.ResourceType = resourceType
    self._InstanceScoreTable.Ratio = fmtVal2Str(ratio)
    self._InstanceScoreTable.ConversionNum = conversionNum
end
----------[副本end]----------

----------[公会防守/次元王朝]-------
def.method().ShowGuildDefendEnd = function(self)
    self._FrameButton:SetActive(true)
    self._FrameEnd:SetActive(false)
    self:OnShowDetail()
    self:GetUIObject("Frame_GuildDefend"):SetActive(true)
    local ImgResult = self:GetUIObject("Img_GuildResult")
    local infoData = self._Data._InfoData
    if not infoData.IsWin then
        GUITools.SetGroupImg(ImgResult,1)
    else
        GUITools.SetGroupImg(ImgResult,0)
    end
    self._ViewGift:SetActive(true)      
    local infoData = self._Data._InfoData
    GUI.SetText(self:GetUIObject("Lab_DefendTime"), GUITools.FormatTimeSpanFromSeconds(infoData.PassTime))
    GUI.SetText(self:GetUIObject("Lab_DefendFloor"), tostring(infoData.GuildDefenseRound))
    GUI.SetText(self:GetUIObject("Lab_DefendMax"),tostring(infoData.GuildDefenseRound))
    self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#infoData.Rewards)
    self:AddDungeonEndTimer(infoData.DurationSeconds)   
end

local function sortfunction(item1,item2)
    if item1.Damage > item2.Damage then 
        return true
    elseif item1.Damage < item2.Damage then 
        return false
    else
        return false
    end
end

local function GetGuildDefendDetailInfo(self,data)
    local dataList = {}
    for i,Data in ipairs(data._Data) do

        local playerData = {}
        for j,v in ipairs(Data.statisticDatas) do
            if v.key == EStatistic.EStatistic_damage then 
                playerData.Damage = v.value
            elseif v.key == EStatistic.EStatistic_roleId then 
                playerData.RoleId = v.value
            elseif v.key == EStatistic.EStatistic_roleLevel then 
                playerData.Level = v.value
            elseif v.key == EStatistic.EStatistic_professionId then
                playerData.ProfessionId = v.value
            elseif v.key == EStatistic.EStatistic_roleName then 
                playerData.Name = v.strValue
            elseif v.key == EStatistic.EStatistic_damage_total then 
                playerData.DamageTotal = v.value
            end 
        end
        table.insert(dataList,playerData)
    end
    table.sort( dataList, sortfunction )
    return dataList
end

def.method("table").ShowGuildDetailInfo = function(self,data)
    self:GetUIObject("Frame4"):SetActive(true)
    self._DetailData = GetGuildDefendDetailInfo(self,data)
    if self._DetailData == nil then return end
    if  #self._DetailData > 50 then 
        self._FrameGuildList:SetItemCount(50)
    else
        self._FrameGuildList:SetItemCount(#self._DetailData)
    end
    local hostData = nil 
    local rank = 0
    for i,v in ipairs(self._DetailData) do
        if v.RoleId == game._HostPlayer._ID then
            hostData = v
            rank = i
            break
        end
    end
    local frameHost = self:GetUIObject("Frame_HostPlayer")
    if hostData ~= nil then
        frameHost:SetActive(true)
        SetGuildDefendItem(self,frameHost,hostData,rank)
    else
        frameHost:SetActive(false)
    end
end


----------[公会防守/次元王朝End]-------

----------[1v1]----------

def.method().ShowArenaOneEnd = function(self)
    self._FrameButton:SetActive(true)
    self._ViewGift:SetActive(true)
    self:OnShowDetail()
    local LabVictoryHost = self:GetUIObject("Lab_VictorylHost")
    local LabFailHost = self:GetUIObject("Lab_FailHost")
    local LabVictoryEnemy = self:GetUIObject("Lab_VictoryEnemy")
    local LabFailEnemy = self:GetUIObject("Lab_FailEnemy")
    local infoData = self._Data._InfoData
    local frame_PVP1 = self:GetUIObject("Frame_PVP1")
    frame_PVP1:SetActive(true)
    if infoData.RewardState == EJJC1x1RewardResult.VICTORY then
        self._FrameEnd:SetActive(false)
        self._FrameLose:SetActive(false)	
        LabVictoryEnemy:SetActive(false)
        LabVictoryHost:SetActive(true)
        LabFailEnemy:SetActive(true)
        LabFailHost:SetActive(false)
        frame_PVP1:FindChild("Img_Bg_04"):SetActive(false)
        -- do  --UI特效添加
        --     local callback = function()
        CSoundMan.Instance():Play3DVoice(PATH.GUISound_Arena1v1Victory, game._HostPlayer:GetPos(),0)
        self._FrameVictory:SetActive(true)
        GameUtil.PlayUISfx(PATH.UIFX_PVP1_End_Victory, self._FrameVictory, self._FrameVictory, -1)
        GameUtil.PlayUISfx(PATH.UIFX_Dungeon_PVP1_FrameVectory, frame_PVP1, frame_PVP1, -1,-1,-3)
        GameUtil.PlayUISfx(PATH.UIFX_Dungeon_PVP1_Rank, self:GetUIObject("EffectPos1"), self:GetUIObject("EffectPos1"), -1)
        local callback1 = function()
            if self._UIFXTimers[1] ~= 0 then
                GameUtil.PlayUISfx(PATH.UIFX_Dungeon_PVP1_Rank, self:GetUIObject("EffectPos2"), self:GetUIObject("EffectPos2"), -1)
                self._UIFXTimers[1] = 0
            end
        end
        self._UIFXTimers[1] = _G.AddGlobalTimer(0.2, true, callback1)
    elseif infoData.RewardState == EJJC1x1RewardResult.FAILED then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena_Defeat, 0)  
        self._FrameEnd:SetActive(false)
        self._FrameVictory:SetActive(false)
        self:GetUIObject("EffectPos1"):SetActive(false)
        self:GetUIObject("EffectPos2"):SetActive(false)
        LabVictoryEnemy:SetActive(true)
        LabVictoryHost:SetActive(false)
        LabFailEnemy:SetActive(false)
        LabFailHost:SetActive(true)
        frame_PVP1:FindChild("Img_Bg_04"):SetActive(true)
        self._FrameLose:SetActive(true)	
        GameUtil.PlayUISfx(PATH.UIFx_JJCLose,frame_PVP1,frame_PVP1 ,-1)
    end
    
    self._PointChange = infoData.ToScore - infoData.FromScore
    self._RankChange = infoData.ToRank -infoData.FromRank 
    if infoData.FromRank == 0 then 
        GUI.SetText(self._LabRank, StringTable.Get(20103))
    else
        GUI.SetText(self._LabRank, tostring(infoData.FromRank))
    end 
    GUI.SetText(self._LabPoint, tostring(infoData.FromScore)) 
    GUI.SetText(self._LabRankChange, tostring(math.abs(self._RankChange)))
    GUI.SetText(self._LabPointChange, tostring(math.abs(self._PointChange)))
    local isRankRise = false
    local isPointRise = false
    if self._RankChange ~= 0 then 
        self._Frame_Rank:SetActive(true)
        if infoData.FromRank ~= 0 then
            if self._RankChange > 0 then 
                self._ImgRankUpArrow:SetActive(false)
                self._ImgRankDownArrow:SetActive(true)
            elseif self._RankChange < 0 then 
                isRankRise = true
                self._ImgRankUpArrow:SetActive(true)
                self._ImgRankDownArrow:SetActive(false)
            end
        else
            isRankRise = true
            self._ImgRankUpArrow:SetActive(true)
            self._ImgRankDownArrow:SetActive(false)
        end
        self:ShowValueChanging(self._LabRank,self._LabRankChange,self._Frame_Rank,infoData.FromRank,infoData.ToRank,self._RankChange,1,isRankRise)
    else 
        self._Frame_Rank:SetActive(false)
    end
    if self._PointChange ~= 0 then 
        self._Frame_Point:SetActive(true)
        if self._PointChange > 0 then 
            isPointRise = true
            self._ImgPointUpArrow:SetActive(true)
            self._ImgPointDownArrow:SetActive(false)
        else
            self._ImgPointUpArrow:SetActive(false)
            self._ImgPointDownArrow:SetActive(true)
        end
        self:ShowValueChanging(self._LabPoint,self._LabPointChange,self._Frame_Point,infoData.FromScore,infoData.ToScore,self._PointChange,2,isPointRise)
    else
        self._Frame_Point:SetActive(false)
    end
    GUI.SetText(self:GetUIObject("Lab_TimeValues2"), GUITools.FormatTimeSpanFromSeconds(infoData.PassTime))
    self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#infoData.Rewards)
    self:AddDungeonEndTimer(infoData.DurationSeconds)
end

--积分和排行榜的值变化效果
def.method('userdata',"userdata","userdata","number","number","number","number","boolean").ShowValueChanging = function (self,labObj,labChange,frameObj,value,toValue,changeValue,index,isRise)
    if self._TimeIDs[index] ~= nil then
        if self._TimeIDs[index] ~= 0 then
            _G.RemoveGlobalTimer(self._TimeIDs[index])
            self._TimeIDs[index] = 0
        end
    else 
        self._TimeIDs[index] = 0
    end
    local formatID = 0 
    if not isRise then 
        formatID = 21702
    else
        formatID = 21700
    end

    if self._TimeIDs[index] == 0 then 
        local startTime = 0
        local callback = function()
            local Corlor = 0
            startTime = startTime + 0.1
            if startTime >= 1.5 then 
                if changeValue > 0 then 
                    if value >= toValue then 
                        value = toValue
                    else
                        value = value + 1
                        changeValue = changeValue - 1
                    end
                    GUI.SetText(labObj,tostring(value))
                    GUI.SetText(labChange,string.format(StringTable.Get(formatID),changeValue))
                elseif changeValue < 0 then 
                    if value <= toValue then 
                        value = toValue
                    else
                        value = value - 1
                        changeValue = changeValue + 1
                    end
                    GUI.SetText(labObj,tostring(value))
                    GUI.SetText(labChange,string.format(StringTable.Get(formatID),math.abs(changeValue)))
                else 
                    frameObj:SetActive(false)
                    _G.RemoveGlobalTimer(self._TimeIDs[index])
                end	 
            end   
        end
        self._TimeIDs[index] = _G.AddGlobalTimer(0.1 + 0.01*index, false, callback)
    end  	
    -- body
end

-- 1V1 详细内容
def.method("table").ShowArenaOnePlayer = function(self,data)
    if not self:IsShow() then return end
    self._DetailData = data
    self._FrameInformation:SetActive(true)
    self:GetUIObject("Frame1"):SetActive(true)	
 
    self._MaxGetDmg,self._MaxCure,self._MaxDmg = self:MaxValue(data._Data)
    for i,Data in ipairs(data._Data) do 
        for j,w in ipairs(Data.statisticDatas) do
            if w.key == EStatistic.EStatistic_roleId then 
                if w.value == game._HostPlayer._ID then
                    self:SetFramePlayer(self:GetUIObject("Frame_Player11"),Data)
                else
                    self:SetFramePlayer(self:GetUIObject("Frame_Player21"),Data)
                end
            end
        end
    end
end
----------[1v1]----------


----------[3v3]----------
-- 升星特效显示
local function StarUp(self,newStar ,oldStar,maxStar,GroupStars,doTweenPlayer,delayTime,TimerIndex)
    for i = 1 ,maxStar do
        local starImg = GroupStars: FindChild("Img_Star"..i)
        if i <= oldStar then 
            starImg:SetActive(true)
            -- doTweenPlayer:Restart("StarAppear"..maxStar..i)
        elseif (i > oldStar) and (i <= newStar) then 
            starImg:SetActive(false)
            local cb = function()
                if self._UI3V3FxTimers[TimerIndex + (i - oldStar - 1)] > 0 then
                    starImg:SetActive(true)
                    doTweenPlayer:Restart("StarAppear"..maxStar..i)
                    GameUtil.PlayUISfx(PATH.UIFX_PVP2_StarUpFX, starImg, starImg, -1)
                    _G.RemoveGlobalTimer(self._UI3V3FxTimers[TimerIndex + (i - oldStar - 1)])
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_StarUp, 0)
                end
                self._UI3V3FxTimers[TimerIndex + (i - oldStar - 1)]  = 0
            end
            self._UI3V3FxTimers[TimerIndex + (i - oldStar - 1)] = _G.AddGlobalTimer(delayTime, true, cb)
            delayTime = delayTime + 0.2
        elseif (i > newStar) and (i <= maxStar) then 
            starImg:SetActive(false)
        end
    end
    return delayTime
end

-- 降星特效显示
local function StarDown(self,newStar ,oldStar,maxStar,GroupStars,doTweenPlayer,delayTime,TimerIndex)

    for i = maxStar , 1, -1 do
        local starImg = GroupStars:FindChild("Img_Star"..i)
        if i <= oldStar then 
            starImg:SetActive(true)
            doTweenPlayer:Restart("StarAppear"..maxStar..i)
            if i > newStar then 
                local cb = function()
                    if self._UI3V3FxTimers[TimerIndex + (i - newStar - 1)] ~= 0 then
                        GameUtil.PlayUISfx(PATH.UIFX_PVP2_StarDownFX, starImg, starImg, -1)
                        doTweenPlayer:Restart("StarDisappear"..maxStar..i)
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_StarDown, 0)
                        _G.RemoveGlobalTimer(self._UI3V3FxTimers[TimerIndex + (i - newStar - 1)])
                    end
                    self._UI3V3FxTimers[TimerIndex + (i - newStar - 1)]  = 0
                end
                delayTime = delayTime + 0.2 * math.abs(i - oldStar)
                self._UI3V3FxTimers[TimerIndex + (i - newStar - 1)] = _G.AddGlobalTimer(delayTime, true, cb)
            end
        else
            starImg:SetActive(false)
        end
    end
    return delayTime
end

-- 星级消失动画
local function StarDisappear(self,delayTime,maxStar,doTweenPlayer,TimerIndex)
    local function cb ()
        if self._UI3V3FxTimers[TimerIndex] ~= 0 then 
            doTweenPlayer:Restart("StarDisappear"..maxStar)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[TimerIndex])
        end
        self._UI3V3FxTimers[TimerIndex] = 0
    end
    self._UI3V3FxTimers[TimerIndex] = _G.AddGlobalTimer(delayTime , true, cb)
end

-- 显示旧数据段位和段位等级
local function ShowOldstageAndLevel(self,oldData,OldDataTemp,TimerIndex)
    GUI.SetText(self:GetUIObject("Lab_San"),OldDataTemp.Name)  
    local imgSan = self:GetUIObject("Img_San")
    GUITools.SetGroupImg(imgSan,OldDataTemp.StageType - 1)
    local imgLevel = self:GetUIObject("Img_Level")
    local labLevel = self:GetUIObject("Lab_SanLevel")
    if oldData.Stage == 16 then 
        labLevel:SetActive(true)
        imgLevel:SetActive(false)
        GUI.SetText(labLevel,tostring(oldData.Star))
    else
        labLevel:SetActive(false)
        imgLevel:SetActive(true)
        GUITools.SetGroupImg(self:GetUIObject("Img_Level"),OldDataTemp.StageLevel - 1)
    end 
    local function cb ()
        if self._UI3V3FxTimers[TimerIndex] ~= 0 then
            local ImgBgL = self:GetUIObject("Img_BgL")
            local ImgBgR = self:GetUIObject("Img_BgR")
            GameUtil.PlayUISfx(PATH.UIFx_PVP2_BgR,ImgBgR,ImgBgR,-1)
            GameUtil.PlayUISfx(PATH.UIFx_PVP2_BgL,ImgBgL,ImgBgL,-1)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[TimerIndex])
        end
        self._UI3V3FxTimers[TimerIndex] = 0
    end
    self._UI3V3FxTimers[TimerIndex] = _G.AddGlobalTimer(0.3, true, cb)
end   

-- 段位未变时相关显示
local function StageUnChange(self,newData,oldData,doTweenPlayer,isShowFx)
    local DataTemp = CElementData.GetPVP3v3Template(newData.Stage)
    if DataTemp == nil then warn(" 3V3 Stage Template is nil ",newData.Stage) return end
     -- .RewardState == EJJC3V3RewardResult.VICTORY
    do
        GUI.SetText(self:GetUIObject("Lab_San"),DataTemp.Name)  
        local imgSan = self:GetUIObject("Img_San")
        local FxObjBg = self:GetUIObject("Frame_Sans")
        GUITools.SetGroupImg(imgSan,DataTemp.StageType - 1)
        doTweenPlayer:Restart("StageUnchange")  
        if isShowFx then
            local function cb1 ()
                if self._UI3V3FxTimers[1] ~= 0 then
                    GameUtil.PlayUISfx(PATH.UIFX_PVP2_StageImgBGFX,FxObjBg,FxObjBg,-1, 20,-1)
                end
                _G.RemoveGlobalTimer(self._UI3V3FxTimers[1])
                self._UI3V3FxTimers[1] = 0
            end
            self._UI3V3FxTimers[1] = _G.AddGlobalTimer(0.15 , true, cb1)
        end     
    end

    -- 显示段位等级图标动画
    do 
        local imgLevel = self:GetUIObject("Img_Level")
        local labLevel = self:GetUIObject("Lab_SanLevel")
        local groupId = ""
        local ObjFx = nil
        if newData.Stage == 16 then 
            labLevel:SetActive(true)
            imgLevel:SetActive(false)
            GUI.SetText(labLevel,tostring(newData.Star))
            groupId = "LabLevelUnchange"
            ObjFx = labLevel
        else
            labLevel:SetActive(false)
            imgLevel:SetActive(true)
            GUITools.SetGroupImg(self:GetUIObject("Img_Level"),DataTemp.StageLevel - 1)
            groupId = "ImgLevelUnchange"
            ObjFx = imgLevel
        end   
        doTweenPlayer:Restart(groupId)
        if isShowFx then
            local function cb2 ()
                if self._UI3V3FxTimers[2] ~= 0 then
                    GameUtil.PlayUISfx(PATH.UIFX_PVP2_StageLevelBgFX, ObjFx, ObjFx,-1)
                end
                _G.RemoveGlobalTimer(self._UI3V3FxTimers[2])
                self._UI3V3FxTimers[2] = 0
            end
            self._UI3V3FxTimers[2] = _G.AddGlobalTimer(0.3 , true, cb2)
        end
    end

    do 
        local function cb3 ()
            if self._UI3V3FxTimers[3] ~= 0 then
                local ImgBgL = self:GetUIObject("Img_BgL")
                local ImgBgR = self:GetUIObject("Img_BgR")
                GameUtil.PlayUISfx(PATH.UIFx_PVP2_BgR,ImgBgR,ImgBgR,-1)
                GameUtil.PlayUISfx(PATH.UIFx_PVP2_BgL,ImgBgL,ImgBgL,-1)
                _G.RemoveGlobalTimer(self._UI3V3FxTimers[3])
            end
            self._UI3V3FxTimers[3] = 0
        end
        self._UI3V3FxTimers[3] = _G.AddGlobalTimer(0.5, true, cb3)
    end

    -- 显示星的动画和特效
    do
        if DataTemp.CountUpLimit <= 0 then warn(" 3V3 Stage Template CountUpLimit is 0 ",newData.Stage) return end
        local GroupStars = self: GetUIObject("Frame_Star"..DataTemp.CountUpLimit)
        if IsNil(GroupStars) then warn("Frame_Star"..DataTemp.CountUpLimit .." is nil") return end
        local function cb4 ()
            if self._UI3V3FxTimers[4] > 0 then
                GroupStars:SetActive(true)
                _G.RemoveGlobalTimer(self._UI3V3FxTimers[4])
            end
            self._UI3V3FxTimers[4] = 0
        end
        self._UI3V3FxTimers[4] = _G.AddGlobalTimer(0.8, true, cb4)
        local delayTime = 1.4
        local TimerIndex = 5
        if oldData.Star < newData.Star then 
            StarUp(self,newData.Star,oldData.Star,DataTemp.CountUpLimit,GroupStars,doTweenPlayer,delayTime,TimerIndex)
        elseif oldData.Star > newData.Star then
            StarDown(self,newData.Star,oldData.Star,DataTemp.CountUpLimit,GroupStars,doTweenPlayer,delayTime,TimerIndex)
        else
            for i = 1 ,DataTemp.CountUpLimit do
                local starImg = GroupStars:FindChild("Img_Star"..i)
                if i <= newData.Star then 
                    starImg:SetActive(true)
                else
                    starImg:SetActive(false)
                end
            end
        end
    end
end

-- 切换段位和段位等级(有动画,失败无特效) 
local function ChangeSan(self,newData,oldData,DataTemp,doTweenPlayer)
    doTweenPlayer:Restart("StageChange")
    local imgSanChange = self:GetUIObject("Img_ChangeSan")
    local FxSanBg = self:GetUIObject("Frame_Sans")
    imgSanChange:SetActive(true)
    GUITools.SetGroupImg(imgSanChange,DataTemp.StageType - 1)

   
    local FxLeveObj = nil
    local imgChangeLevel = self:GetUIObject("Img_ChangeLevel")
    local labChangeLevel = self:GetUIObject("Lab_SanChangeLevel")
    doTweenPlayer:Restart("ImgLevelchange")
    doTweenPlayer:Restart("LabLevelChange")
    if newData.Stage == 16 then 
        labChangeLevel:SetActive(true)
        FxLeveObj = labChangeLevel
        GUI.SetText(labChangeLevel,tostring(newData.Star))
    else 
        imgChangeLevel:SetActive(true)
        FxLeveObj = imgChangeLevel
        GUITools.SetGroupImg(imgChangeLevel,DataTemp.StageLevel - 1)
    end  
    doTweenPlayer:Restart("LabSanChangeName")  
    doTweenPlayer:Restart("LabSanChange")    if newData.Stage < oldData.Stage then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_FailStage, 0)
    return end
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_VictoryStage, 0)  
    local function cb1()
        if self._UI3V3FxTimers[11] ~= 0 then 
            GameUtil.PlayUISfx(PATH.UIFX_PVP2_StageImgBGFX,FxSanBg,FxSanBg,-1,20,-1)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[11])
        end
        self._UI3V3FxTimers[11] = 0
    end
    self._UI3V3FxTimers[11] = _G.AddGlobalTimer(0.8, true, cb1)

    local function cb2()
        if self._UI3V3FxTimers[12] ~= 0 then 
            GameUtil.PlayUISfx(PATH.UIFX_PVP2_StageLevelBgFX,FxLeveObj,FxLeveObj,-1)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[12])
        end
        self._UI3V3FxTimers[12] = 0
    end
    self._UI3V3FxTimers[12] = _G.AddGlobalTimer(1, true, cb2)
    local labSan = self:GetUIObject("Lab_San")
    local function cb3()
        if self._UI3V3FxTimers[13] ~= 0 then 
            GameUtil.PlayUISfx(PATH.UIFX_PVP2_LabStageFX,labSan,labSan,-1)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[13])
        end
        self._UI3V3FxTimers[13] = 0
    end
    self._UI3V3FxTimers[13] = _G.AddGlobalTimer(1.2, true, cb3)
end
 
-- 整体切换
local function ControlChange(self,newData,oldData,DataTemp,doTweenPlayer)
    ChangeSan(self,newData,oldData,DataTemp,doTweenPlayer)

     -- 点亮新段位星
    if DataTemp.CountUpLimit <= 0 then warn(" 3V3 Stage Template CountUpLimit is 0 ",newData.Stage) return end
    local GroupStars = self:GetUIObject("Frame_Star"..DataTemp.CountUpLimit)
    if IsNil(GroupStars) then warn("Frame_Star"..DataTemp.CountUpLimit .." is nil") return end
    local delayTime = 2
    local function cb ()
        if self._UI3V3FxTimers[14] ~= 0 then
            GroupStars:SetActive(true)
            doTweenPlayer:Restart("StarAppear"..DataTemp.CountUpLimit)
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[14])
        end
        self._UI3V3FxTimers[14] = 0
    end
    self._UI3V3FxTimers[14] = _G.AddGlobalTimer(2, true, cb)

    if oldData.Stage < newData.Stage then 
        if newData.Star == 0 then 
            for i = 1 , DataTemp.CountUpLimit do
                local starImg = GroupStars: FindChild("Img_Star"..i)
                starImg:SetActive(false)
            end
        elseif newData.Star > 0 then 
            StarUp(self,newData.Star,0,DataTemp.CountUpLimit,GroupStars,doTweenPlayer,delayTime,15)
        end
    elseif oldData.Stage > newData.Stage then
        if newData.Star <= 0 then return end
        StarDown(self,newData.Star,DataTemp.CountUpLimit,DataTemp.CountUpLimit,GroupStars,doTweenPlayer,delayTime,15)
    end
end

local function StageChange(self,newData,oldData,doTweenPlayer)
    local DataTemp = CElementData.GetPVP3v3Template(oldData.Stage)
    if DataTemp == nil then warn(" 3V3 Stage Template is nil ",oldData.Stage) return end
    local delayTime = 0.5
    -- 先展示旧的数据无动画
    local TimerIndex = 1
    ShowOldstageAndLevel(self,oldData,DataTemp,TimerIndex)
    -- 注意 神选者  DataTemp.CountUpLimit = 0
    if DataTemp.CountUpLimit > 0 then 
        local GroupStars = self: GetUIObject("Frame_Star"..DataTemp.CountUpLimit)
        if IsNil(GroupStars) then warn("Frame_Star"..DataTemp.CountUpLimit .." is nil") return end
        GroupStars:SetActive(true)

        -- 段位改变增加( 1升星 ，2播放消失dotween)
        if oldData.Stage < newData.Stage then 
            TimerIndex = 2
            delayTime = StarUp(self,DataTemp.CountUpLimit,oldData.Star,DataTemp.CountUpLimit,GroupStars,doTweenPlayer,delayTime,TimerIndex)
            delayTime = delayTime + 1 
        else
            -- 段位下降(定死为星级从零星状态开始下降)
            for i = 1, DataTemp.CountUpLimit do
                local starImg = GroupStars: FindChild("Img_Star"..i)
                starImg:SetActive(false)
            end
            delayTime = 1
        end
        --星消失
        TimerIndex = 6
        StarDisappear(self,delayTime,DataTemp.CountUpLimit,doTweenPlayer,TimerIndex)
    elseif DataTemp.CountUpLimit == 0 then
        local function cb2()
            if self._UI3V3FxTimers[6] ~= 0 then 
                local newDataTemp = CElementData.GetPVP3v3Template(newData.Stage)
                ControlChange(self,newData,oldData,newDataTemp,doTweenPlayer)
            end
            self._UI3V3FxTimers[6] = 0
        end
        self._UI3V3FxTimers[6] = _G.AddGlobalTimer(0.5, true, cb2)
    end
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
    CPanelBase.OnDOTComplete(self,go_name,dot_id)
    if go_name == "Lab_San" and dot_id == "LabSanChangeName" then 
        local DataTemp = CElementData.GetPVP3v3Template(self._Data._InfoData.Stage)
        if DataTemp == nil then warn(" 3V3 Stage Template is nil ",self._Data._InfoData.Stage) return end
        local labSan = self:GetUIObject("Lab_San")
        GUI.SetText(labSan,DataTemp.Name)
    elseif string.find(go_name,"Frame_Star") and string.find(dot_id,"StarDisappear") then 
        local doTweenPlayer = self:GetUIObject("Frame_PVP2"):GetComponent(ClassType.DOTweenPlayer)
        local newData = self._Data._InfoData
        local oldData = game._CArenaMan._3V3HostData
        if oldData == nil then 
            oldData = {}
            oldData.Stage = self._Data._InfoData.OldStage
            oldData.Star = self._Data._InfoData.OldStar
        end
        local DataTemp = CElementData.GetPVP3v3Template(newData.Stage)
        if DataTemp == nil then warn(" 3V3 Stage Template is nil ",newData.Stage) return end
        ControlChange(self,newData,oldData,DataTemp,doTweenPlayer)
    end
end

def.method().ShowArenaThreeEnd = function(self)
    self._FrameButton:SetActive(true)
    self:GetUIObject("Frame_PVP2"):SetActive(true)
    self._ViewGift:SetActive(true)
    self:OnShowDetail()
    self._UI3V3FxTimers = {}
    local infoData = self._Data._InfoData
    if infoData == nil then return end	

    do 
        local allWin = self:GetUIObject("Img_AllWin")
        GUI.SetText(self:GetUIObject("Lab_TimeValues3"),GUITools.FormatTimeSpanFromSeconds(infoData.PassTime))
        self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#infoData.Rewards)
        self:AddDungeonEndTimer(infoData.LeftTime)
        self:GetUIObject("Frame_Star3"):SetActive(false)
        self:GetUIObject("Frame_Star4"):SetActive(false)
        self:GetUIObject("Frame_Star5"):SetActive(false)
        if infoData.WinStreak > 1 then 
            allWin:SetActive(true)
            GUI.SetText(self:GetUIObject("Lab_WinTime"),string.format(StringTable.Get(21701),infoData.WinStreak))
        else
            allWin:SetActive(false)
        end
    end

    local isShowFx = false  
    if infoData.RewardState == EJJC3V3RewardResult.VICTORY then
        isShowFx = true
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena_Victory, 0)  
        self._FrameEnd:SetActive(false)
        self._FrameVictory:SetActive(false)
        self._FrameLose:SetActive(false)	
        self._FrameVictory:SetActive(true)
        GameUtil.PlayUISfx(PATH.UIFX_PVP1_End_Victory, self._FrameVictory, self._FrameVictory, -1)
    else
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Arena_Defeat, 0)  
        self._FrameEnd:SetActive(false)
        self._FrameVictory:SetActive(false)
        self._FrameLose:SetActive(false)
        self._FrameLose:SetActive(true)	
    end

      -- 段位星级 段位级别显示 和相关特效
    do
        local newData = infoData
        local oldData = game._CArenaMan._3V3HostData
        local doTweenPlayer = self:GetUIObject("Frame_PVP2"):GetComponent(ClassType.DOTweenPlayer)
        if oldData == nil then 
            oldData = {}
            oldData.Stage = infoData.OldStage 
            oldData.Star = infoData.OldStar
        end
        if oldData.Stage == newData.Stage then
            StageUnChange(self,newData,oldData,doTweenPlayer,isShowFx)
        else
            StageChange(self,newData,oldData,doTweenPlayer)
        end
    end
end

-- 3v3结算详细信息面板
def.method("table").ShowArenaThreePlayer = function(self,data)
    if not self:IsShow() then return end
    self._FrameInformation:SetActive(true)
    self:GetUIObject("Frame2"):SetActive(true)	
    if self._DetailData == nil then 
        self:Get3V3DetailData(data)
    end
    local blackResult = 0
    local redResult = 0
    if #self._DetailData.RedList == 0 or #self._DetailData.BlackList == 0 then warn(" #self._DetailData.BlackList == 0") end
    for _,k in ipairs(self._DetailData.BlackList) do 
        if game._HostPlayer._ID == k.RoleId then 
            blackResult = self._Data._InfoData.RewardState
            if blackResult == EJJC3V3RewardResult.VICTORY then 
                self:GetUIObject("Lab_VictorylBlack"):SetActive(true)
                self:GetUIObject("Lab_FailBlack"):SetActive(false)
                self:GetUIObject("Lab_VictorylRed"):SetActive(false)
                self:GetUIObject("Lab_FailRed"):SetActive(true)
            else
                self:GetUIObject("Lab_VictorylBlack"):SetActive(false)
                self:GetUIObject("Lab_FailBlack"):SetActive(true)
                self:GetUIObject("Lab_VictorylRed"):SetActive(true)
                self:GetUIObject("Lab_FailRed"):SetActive(false)
            end
        end
    end
    for _,k in ipairs(self._DetailData.RedList) do
        if game._HostPlayer._ID == k.RoleId then 
            redResult = self._Data._InfoData.RewardState
            if redResult == EJJC3V3RewardResult.VICTORY then
                self:GetUIObject("Lab_VictorylBlack"):SetActive(false)
                self:GetUIObject("Lab_FailBlack"):SetActive(true)
                self:GetUIObject("Lab_VictorylRed"):SetActive(true)
                self:GetUIObject("Lab_FailRed"):SetActive(false)
            else
                self:GetUIObject("Lab_VictorylBlack"):SetActive(true)
                self:GetUIObject("Lab_FailBlack"):SetActive(false)
                self:GetUIObject("Lab_VictorylRed"):SetActive(false)
                self:GetUIObject("Lab_FailRed"):SetActive(true)
            end
        end
    end
    self._MaxKillNum,self._MaxCure,self._MaxDmg = self:MaxValue(data)
    --黑
    local blackPlayer1 = self: GetUIObject("Frame_PlayerBlack1")
    self:SetFramePlayer(blackPlayer1,self._DetailData.BlackList[1])
    
    local blackPlayer2 = self: GetUIObject("Frame_PlayerBlack2")
    self:SetFramePlayer(blackPlayer2,self._DetailData.BlackList[2])
    
    local blackPlayer3 = self: GetUIObject("Frame_PlayerBlack3")
    self:SetFramePlayer(blackPlayer3,self._DetailData.BlackList[3])
    --红
    local RedPlayer1 = self: GetUIObject("Frame_PlayerRed1")
    self:SetFramePlayer(RedPlayer1,self._DetailData.RedList[1])

    local RedPlayer2 = self: GetUIObject("Frame_PlayerRed2")
    self:SetFramePlayer(RedPlayer2,self._DetailData.RedList[2])

    local RedPlayer3 = self: GetUIObject("Frame_PlayerRed3")
    self:SetFramePlayer(RedPlayer3,self._DetailData.RedList[3])	
end

-- 整理3v3详细信息数据
def.method("table").Get3V3DetailData = function (self,data)
    local RedList = {}
    local BlackList = {}
    for i, v in ipairs(data._Data) do 
        local personData = self:Get3V3StatisticData(v.statisticDatas)
        if personData.Camp == 1 then 
            RedList[#RedList + 1] = personData
        elseif personData.Camp == 2 then 
            BlackList[#BlackList + 1] = personData
        end
    end
    self._DetailData = {}
    self._DetailData.RedList = RedList
    self._DetailData.BlackList = BlackList
end

-- 整理每个人的所有数据
def.method("table","=>","table").Get3V3StatisticData = function (self,statisticDatas)
    local data = {}
    for j,v in ipairs(statisticDatas) do
        if v.key == EStatistic.EStatistic_cured then
            data.Cure = v.value
        elseif v.key == EStatistic.EStatistic_damage then 
            data.Dmg = v.value
        elseif v.key == EStatistic.EStatistic_roleId then 
            data.RoleId = v.value
        elseif v.key == EStatistic.EStatistic_roleLevel then 
            data.Level = v.value
        elseif v.key == EStatistic.EStatistic_professionId then
            data.Profession = v.value
            data.Gender = Profession2Gender[data.Profession]
        elseif v.key == EStatistic.EStatistic_customImgSetId then
            data.CustomImgSetId = v.value
        elseif v.key == EStatistic.EStatistic_roleName then 
            data.RoleName = v.strValue	
        elseif v.key == EStatistic.EStatistic_kill then
            data.KillNum = v.value 
        elseif v.key == EStatistic.EStatistic_camp then 
            data.Camp = v.value
        end
    end
    return data
end

-------------------[试炼]-------------------------------------
def.method().ShowTrialEnd = function (self)
    self._FrameButton:SetActive(true)
    self:OnShowDetail()
    self._ViewGift:SetActive(true)
    local infoData = self._Data._InfoData
    GUI.SetText(self:GetUIObject("Lab_TimeValues1"),GUITools.FormatTimeSpanFromSeconds(infoData.PassTime))
    local dungeon = CElementData.GetTemplate("Instance", infoData.InstanceTId)		
    GUI.SetText(self:GetUIObject("Lab_InstanceName1"), dungeon.TextDisplayName)
    self._FrameEnd:SetActive(true)
    self._FrameVictory:SetActive(false)
    self._FrameLose:SetActive(false)
    self:GetUIObject("Img_New"):SetActive(false)
    if infoData.IsBreakRecord then 
        local img_New = self:GetUIObject("Img_New")
        img_New:SetActive(true)
        GameUtil.PlayUISfx(PATH.UIFX_Instance2_NewScoreFX, img_New, img_New, -1)
    else
        self:GetUIObject("Img_New"):SetActive(false)
    end
    self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#infoData.Rewards)
    local tierNow = 0
    if infoData.Tier == 0 then 
        tierNow = 1
    else
        tierNow = infoData.Tier
    end
    self:TrialTier(tierNow)
    self:AddDungeonEndTimer(infoData.DurationSeconds)
    	
    do  --副本层数UI特效
        local callback = function()
            if self._UIFXTimers[2] ~= 0 then
                self:GetUIObject("Frame_Instance2"):SetActive(true)
                local imgBG = self:GetUIObject("Frame_Instance2"):FindChild("Img_Bg")
                GameUtil.PlayUISfx(PATH.UIFX_Instance2_DungeonFloor, imgBG, imgBG, -1)
                self._UIFXTimers[2] = 0
            end
        end
        self._UIFXTimers[2] = _G.AddGlobalTimer(0.3, true, callback)
        GameUtil.PlayUISfx(PATH.UIFX_PVP1_End_Victory, self._FrameEnd, self._FrameEnd, -1)
    end
end

-- 试炼层级滚动变化
def.method("number").TrialTier = function (self,endTier)
    local timeID = 0 
    local startTier = 0
    local labTier = self:GetUIObject("Lab_FloorValues1")
    local callback = function()
        if IsNil(labTier) then _G.RemoveGlobalTimer(timeID) return end
        if startTier < endTier then 
            startTier = startTier + 1
            GUI.SetText(labTier,tostring(startTier))
        else 
            _G.RemoveGlobalTimer(timeID)
        end	 
    end
    timeID = _G.AddGlobalTimer(0.151, false, callback)  	
    -- body
end
-------------------[试炼end]-------------------------------------
-- 3V3 依次返回击杀、治疗、伤害的最大值，1v1和副本 依次返回 0， 治疗和伤害的最大值
def.method("table","=>","number","number","number").MaxValue = function (self,infoData)
    local value1,value2,value3 = 0,0,0
    if self._CurType == EnumDef.DungeonEndType.ArenaThreeType then 
        value1 = self._DetailData.RedList[1].KillNum
        value2 = self._DetailData.RedList[1].Cure
        value3 = self._DetailData.RedList[1].Dmg
        for _,k in ipairs(self._DetailData.RedList) do
            if value1 < k.KillNum then 
                value1 = k.KillNum
            end
            if value2 < k.Cure then 
                value2 = k.Cure
            end
            if value3 < k.Dmg then 
                value3 = k.Dmg
            end
        end
        for _,k in ipairs(self._DetailData.BlackList) do
            if value1 < k.KillNum then 
                value1 = k.KillNum
            end
            if value2 < k.Cure then 
                value2 = k.Cure
            end
            if value3 < k.Dmg then 
                value3 = k.Dmg
            end
        end
        return value1,value2,value3
    elseif self._CurType == EnumDef.DungeonEndType.EliminateType then
        value1 = self._DetailData[1].KillNum
        for i,k in ipairs(self._DetailData) do
            if value1 < k.KillNum then 
                value1 = k.KillNum
            end
        end
        return value1,value2,value3
    else 
        for i,Data in ipairs(infoData) do 
            for j,v in ipairs(Data.statisticDatas) do 
                if v.key == EStatistic.EStatistic_cured then
                    if value2 < v.value then 
                        value2 = v.value
                    end
                elseif v.key == EStatistic.EStatistic_damage then 
                    if value3 < v.value then 
                        value3 = v.value
                    end
                elseif v.key == EStatistic.EStatistic_stuffer then 
                    if value1 < v.value then 
                        value1 = v.value
                    end
                end	
            end 
        end
        return value1,value2,value3
    end
end

def.method("userdata","number","number").ShowValueWtihColor = function (self,labObj,value,MaxValue)
    if value < MaxValue or MaxValue == 0 then 
        GUI.SetText(labObj,GUITools.FormatMoney(value))
    elseif value >= MaxValue and MaxValue ~= 0 then 
        GUI.SetText(labObj,GUITools.FormatMoney(value))
    end
    -- body
end

------------------无畏战场--------------------------------------
def.method().ShowBattleEnd = function (self)
    self._FrameButton:SetActive(true)
    self:GetUIObject("Frame_Battle"):SetActive(true)
    self:OnShowDetail()
    self._FrameEnd:SetActive(true)
    self._FrameVictory:SetActive(false)
    self._FrameLose:SetActive(false)

    local LabRank = self:GetUIObject("Lab_BattleRank")
    LabRank:SetActive(true)
    if not self._Data._IsOut then 
        GUI.SetText(LabRank,tostring(self._Data._Rank))
    else
        local rank = 0
        for i,v in ipairs(self._Data._AllRoleDataList) do
            if v.RoleId == game._HostPlayer._ID then 
                rank = i
            end
        end
        GUI.SetText(LabRank,tostring(rank))
    end

    local imgPointFx = LabRank:FindChild("Img_PointFX")
    GameUtil.PlayUISfx(PATH.UIFX_Dungeon_End_YellowScore, imgPointFx, imgPointFx, -1)
    local seasonScore = self:GetUIObject("Frame_SeasonScore")
    if self._Data._AddScore > 0 then 
        GUITools.SetUIActive(seasonScore,true)
        GUI.SetText(self:GetUIObject("Lab_ScoreUp"),tostring(self._Data._AddScore))
    else
        GUITools.SetUIActive(seasonScore,false)
    end
    local labNoReward =  self:GetUIObject("Lab_NoRewardTip")
    if self._Data._RewardTid == 0 then 
        self._ViewGift:SetActive(false)
        labNoReward:SetActive(true)
    else
        labNoReward:SetActive(false)
        self._ViewGift:SetActive(true)
        self._BattleRewardItemData = GUITools.GetRewardList(self._Data._RewardTid, true)
        self:GetUIObject("List_Gift"):GetComponent(ClassType.GNewList):SetItemCount(#self._BattleRewardItemData)
    end
    self:AddDungeonEndTimer(self._Data._LeftTime)
       
    self:GetUIObject("Frame_Battle"):SetActive(true)
    local effectPoint = self:GetUIObject("EffectPos")
    effectPoint:SetActive(true)
    GameUtil.PlayUISfx(PATH.UIFX_Dungeon_PVP1_Rank, effectPoint, effectPoint, -1)
end

def.method("table").ShowEliminatePlayer = function (self,data)
    if not self:IsShow() then return end
    self._FrameInformation:SetActive(true)
    self:GetUIObject("Frame5"):SetActive(true) 
    local listObj = self:GetUIObject("Frame_BattleList")
    -- self._MaxKillNum,self._MaxCure,self._MaxDmg = self:MaxValue(data)
    listObj:GetComponent(ClassType.GNewList):SetItemCount(#data)
    if self._Data._IsOut then 
       listObj:GetComponent(ClassType.GNewList):ScrollToStep(6)
    end

end

------------------无畏战场结束----------------------------------
----副本、1V1和3V3详细情况的单条信息
def.method("userdata","table").SetFramePlayer = function(self,uiItem,uiData)
    if not IsNil(uiItem) then
        if uiData ~= nil then 
            uiItem: SetActive(true)
            local uiTemplate = uiItem:GetComponent(ClassType.UITemplate)
            local ImgHostHightLight = uiTemplate:GetControl(0)
            local ImgHead = uiTemplate:GetControl(3)
            local LabName = uiTemplate:GetControl(4)
            local LabPoint = uiTemplate:GetControl(5)
            local LabDamage = uiTemplate:GetControl(6)
            local LabCure = uiTemplate:GetControl(7)
            local LabLv = uiTemplate:GetControl(8)
            local LabJob = uiTemplate:GetControl(10)
            if self._CurType == EnumDef.DungeonEndType.ArenaThreeType  then
                local Gender = 0
                local prof = 0
                local ColorName  = "<color=#FFFFFFFF>" ..uiData.RoleName.."</color>" 
                ImgHostHightLight:SetActive(false)
                if uiData.RoleId == game._HostPlayer._ID then 
                    -- uiItem:FindChild("Img_HostHightLight"):SetActive(true)
                    ColorName =  "<color=#ECBE33FF>" .. uiData.RoleName .."</color>" 
                    ImgHostHightLight:SetActive(true)
                end
                GUI.SetText(LabName,ColorName)
                GUI.SetText(LabLv,tostring(uiData.Level))
                GUI.SetText(LabJob,StringTable.Get(10300 + uiData.Profession - 1))
                self:ShowValueWtihColor(LabPoint,uiData.KillNum,self._MaxKillNum)
                self:ShowValueWtihColor(LabCure,uiData.Cure,self._MaxCure)  
                self:ShowValueWtihColor(LabDamage,uiData.Dmg,self._MaxDmg)
                game:SetEntityCustomImg(ImgHead,uiData.RoleId,uiData.CustomImgSetId,uiData.Gender,uiData.Profession)
            else
                local roleId,customImgSetId ,prof,Gender = 0,0,0,0
                local IsHostPlayer = false
                for i,v in ipairs(uiData.statisticDatas) do 
                    if v.key == EStatistic.EStatistic_cured then
                        self:ShowValueWtihColor(LabCure,v.value,self._MaxCure)
                    elseif v.key == EStatistic.EStatistic_damage then 
                        self:ShowValueWtihColor(LabDamage,v.value,self._MaxDmg)
                    elseif v.key == EStatistic.EStatistic_roleId then 
                        roleId = v.value
                        IsHostPlayer = false
                        ImgHostHightLight:SetActive(false)
                        if roleId == game._HostPlayer._ID then 
                            IsHostPlayer = true
                            ImgHostHightLight:SetActive(true)
                        end
                    elseif v.key == EStatistic.EStatistic_roleLevel then 
                        GUI.SetText(LabLv,tostring(v.value))
                    elseif v.key == EStatistic.EStatistic_professionId  then
                        prof = v.value
                        Gender = Profession2Gender[prof]
                        GUI.SetText(LabJob,StringTable.Get(10300 + prof - 1))
                    elseif v.key == EStatistic.EStatistic_customImgSetId then
                        customImgSetId = v.value
                    elseif v.key == EStatistic.EStatistic_roleName then 
                        local ColorName = ""
                        if v.originParam < 0 then 
                            local TextTemp = CElementData.GetTextTemplate(tonumber(v.strValue))
                            ColorName = TextTemp.TextContent
                        else
                            ColorName = v.strValue
                        end
                        ColorName = "<color=#FFFFFFFF>" ..ColorName.."</color>" 
                        if IsHostPlayer then 
                            ColorName = "<color=#ECBE33FF>" ..ColorName.."</color>" 
                        end
                        GUI.SetText(LabName, ColorName)		
                    elseif v.key == EStatistic.EStatistic_stuffer then 
                        if self._CurType == EnumDef.DungeonEndType.ArenaOneType or self._CurType == EnumDef.DungeonEndType.InstanceType or self._CurType == EnumDef.DungeonEndType.TrialType then
                            self:ShowValueWtihColor(LabPoint,v.value,self._MaxGetDmg)
                        end
                    end	
                end
                game:SetEntityCustomImg(ImgHead,roleId,customImgSetId,Gender,prof)
            end
        else
            uiItem: SetActive(false)
        end
    end
end

def.override().OnHide = function(self)
    for i,v in pairs(self._UIFXTimers) do
        if self._UIFXTimers[i] ~= 0 then
            _G.RemoveGlobalTimer(self._UIFXTimers[i])
            self._UIFXTimers[i] = 0
        end
    end
    self._UIFXTimers = {}

    for i,v in pairs(self._UI3V3FxTimers) do
        if self._UI3V3FxTimers[i] > 0 then
            _G.RemoveGlobalTimer(self._UI3V3FxTimers[i])
            self._UI3V3FxTimers[i] = 0
        end
    end
    self._UI3V3FxTimers = {}
end

--当摧毁
def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler("CountGroupUpdateEvent", OnCountGroupUpdateEvent)
    self._DetailData = nil
    game._GUIMan:SetNormalUIMoveToHide(false, 0, "", nil)
    CItemTipMan.CloseCurrentTips()
    CSoundMan.Instance():Stop3DAudio(PATH.GUISound_Arena1v1Victory,"")
    if self._PlayerModel ~= nil then
        self._PlayerModel:Destroy()
        self._PlayerModel = nil
    end
    for i,v in pairs(self._TimeIDs) do 
        if self._TimeIDs[i] ~= 0 then
           _G.RemoveGlobalTimer(self._TimeIDs[i])
           self._TimeIDs[i] = 0
        end
    end
    self:RemoveDetailInfoTimer()
    if self._LoadingTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._LoadingTimerID)
        self._LoadingTimerID = 0 
    end

    if CPanelUIQuickUse.Instance()._IsShowQuickUse then
        CPanelUIQuickUse.Instance()._Frame_QuickUse:SetActive(true)
    end
    self._CurGoldInstanceItem = nil
    self._InstanceScoreTable = nil 
    self._TimeIDs = {}
    self:SetGameObjectLayerVisible(true)
    GameUtil.SetLayerRecursively(game._HostPlayer:GetCurModel():GetGameObject(), EnumDef.RenderLayer.HostPlayer)
    GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
    self:RemoveDungeonEndTimer()

    instance = nil 
end

CPanelDungeonEnd.Commit()
return CPanelDungeonEnd