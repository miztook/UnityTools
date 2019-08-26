local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local ERankId = require"PB.data".ERankId
local ECustomSet = require "PB.data".ECustomSet
local CPanelRanking = Lplus.Extend(CPanelBase, 'CPanelRanking')
local CFrameCurrency = require "GUI.CFrameCurrency"
local ETimeType = require"PB.Template".Rank.ETimeType
local ERankDataType = require"PB.Template".Rank.eRankDataType
local EStatisticsType = require"PB.Template".Rank.eStatisticsType
local MenuComponents = require "GUI.MenuComponents"
local CGuildMan = require "Guild.CGuildMan"
local CGuildIconInfo = require "Guild.CGuildIconInfo"
local def = CPanelRanking.define

local instance = nil
local RankingColors = {
    [1] = Color.New(141/255, 105/255, 99/255 ,120/255), 
    [2] = Color.New(112/255, 107/255, 80/255, 120/255), 
    [3] = Color.New(81/255, 88/255, 98/255, 120/255)
}

local RankingTips ={
    [1] = 20055,
    [2] = 400,
    [3] = 20105,
    [4] = 20106,
    [5] = 20203,
    [6] = 405,
    [7] = 884,
    [8] = 410,
    [9] = 20108,
    [10] = 20110,
    [11] = 20110,
    [12] = 20111,
    [13] = 20111,
    [14] = 20114,
}
def.field("userdata")._MenuRanking = nil
def.field('userdata')._LabMyNumber = nil
def.field("userdata")._ImgMyNumber = nil
def.field('userdata')._ListGuildList = nil
def.field("userdata")._ListGuildListGO = nil
def.field("number")._CurrentSelectRankID= 0 -- 排行版类型id
def.field("number")._CurrentSelectRankCount = 0 -- 该类型排行榜统计数量
def.field("table")._RankData = BlankTable
def.field("table")._RankMainType = BlankTable
def.field("table")._RankSubType = BlankTable
def.field("number")._OpenIndex = -1
def.field("userdata")._TitleObj = nil
def.field("userdata")._Frame_Member1 = nil 
def.field("userdata")._Frame_Member2 = nil 
def.field("userdata")._Frame_Member3 = nil 
def.field("userdata")._Frame_Member4 = nil 
def.field("userdata")._Frame_Member5 = nil 
def.field("userdata")._Frame_Member6 = nil
def.field("userdata")._Frame_Member7 = nil
def.field("userdata")._Frame_Member8 = nil
def.field("userdata")._Frame_Empty = nil
def.field('number')._StatisticsType = 0  -- 统计对象
def.field("userdata")._List = nil 
def.field("userdata")._ImgHead = nil 
def.field("userdata")._LabLevel = nil 
def.field("userdata")._LabJob1 = nil
def.field("userdata")._LastTabItemArrow = nil
--def.field("userdata")._ImgJob2 = nil 
def.field("userdata")._LabName = nil
def.field("userdata")._LabName2 = nil
def.field("userdata")._LabMainData1 = nil
def.field("userdata")._LabMainData2 = nil
def.field("userdata")._LabGuildNumber = nil -- 工会排行榜倒数第二位数据
def.field("userdata") ._ImgStage = nil 
def.field("userdata")._Frame_HostPlayer = nil 
def.field("number")._CurrentRankMainDataType = 0
def.field(CFrameCurrency)._Frame_Money = nil
def.field("boolean")._IsTabOpen = false
def.field("boolean")._IsScriptOpenTab = false
def.field("number")._CurrentSelectTabIndex = 0 
def.field("userdata")._Host1 = nil 
def.field("userdata")._Host2 = nil 
def.field("userdata")._Lab_GuildName = nil 
def.field("userdata")._MyMainDataTip = nil
def.field("userdata")._MyMainDataTip1 = nil
def.field("userdata")._Lab_SanName = nil
def.field("userdata")._Img_San = nil
def.field("boolean")._IsGray = false
def.field("table")._SelectedItems = BlankTable
def.field("number")._SelectedIndex = -1
def.field("number")._MyRank = 0
def.field("boolean")._IsSelf = false

def.static('=>', CPanelRanking).Instance = function ()
    if not instance then
        instance = CPanelRanking() 
        instance._PrefabPath = PATH.UI_Ranking
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        
        instance:SetupSortingParam()
    end
    return instance
end

local OnNotifyGuildEvent = function(sender, event)
    if event.Type == "GuildBFInfo" then
        if instance._CurrentRankMainDataType == ERankDataType.BATTLE_WINCOUNT or instance._CurrentRankMainDataType == ERankDataType.BATTLE_SCORE then
            --print("接收到事件")
            instance:ShowHostPlayerInfo(instance._MyRank, instance._IsSelf)
        end
    end
end

def.override().OnCreate = function(self)
    self._Frame_Member1 = self:GetUIObject("Frame_Member1")
    self._Frame_Member2 = self:GetUIObject("Frame_Member2")
    self._Frame_Member3 = self:GetUIObject("Frame_Member3")
    self._Frame_Member4 = self:GetUIObject("Frame_Member4")
    self._Frame_Member5 = self:GetUIObject("Frame_Member5")
    self._Frame_Member6 = self:GetUIObject("Frame_Member6")
    self._Frame_Member7 = self:GetUIObject("Frame_Member7")
    self._Frame_Member8 = self:GetUIObject("Frame_Member8")  
    self._Frame_Empty = self:GetUIObject("EmptyPanel")
    self._LabMyNumber = self:GetUIObject("Lab_MyNumber")
    self._ImgMyNumber = self:GetUIObject("Img_Number")
    self._ImgHead = self:GetUIObject("Img_Head")
    self._LabLevel = self:GetUIObject("Lab_Level")
    self._LabJob1 = self:GetUIObject("Lab_Job1")
    --self._ImgJob2 = self:GetUIObject("Img_Job2")
    self._LabName = self:GetUIObject("Lab_Name")
    self._LabName2 = self:GetUIObject("Lab_Name2")
    self._ImgStage = self:GetUIObject("Img_Stage")
    self._LabGuildNumber = self:GetUIObject("Lab_GuildNumber") 
    self._Frame_HostPlayer = self:GetUIObject("Frame_HostPlayer")
    self._LabMainData1 = self:GetUIObject("Lab_MainData1")
    self._LabMainData2 = self:GetUIObject("Lab_MainData2")
    self._List = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)  
    self._Host1 = self:GetUIObject("Host1")
    self._Host2 = self:GetUIObject("Host2")
    self._Lab_GuildName = self:GetUIObject("Lab_GuildName")
    self._MyMainDataTip = self:GetUIObject("Lab_BattleTip")
    self._MyMainDataTip1 = self:GetUIObject("Lab_BattleTip2")
    self._Lab_SanName = self:GetUIObject("Lab_SanName")
    self._Img_San = self:GetUIObject("Img_San")
    self._LabGuildNumber:SetActive(false)
    self._Frame_HostPlayer:SetActive(false)
    CGame.EventManager:removeHandler("NotifyGuildEvent", OnNotifyGuildEvent)
end

def.override("dynamic").OnData = function(self, data)
    self._HelpUrlType = HelpPageUrlType.Ranking
    -- 跨服匹配 功能不能使用
    if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        game._GUIMan:CloseByScript(self)
        return
    end
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
    self:GetAllRankingIDs()
    if self._RankMainType == nil then return end
    self._Frame_Member1:SetActive(false)
    self._Frame_Member2:SetActive(false)
    self._Frame_Member3:SetActive(false)
    self._Frame_Member4:SetActive(false)
    self._Frame_Member5:SetActive(false)
    self._Frame_Member6:SetActive(false)
    self._Frame_Member7:SetActive(false)
    self._Frame_Member8:SetActive(false)
    self._Frame_Empty:SetActive(false)
    self._List:SetItemCount(#self._RankMainType)
    -- self._MenuRanking:Open(#self._RankMainType)
    self._IsTabOpen = false
    local index = data or 1
    --添加排行榜时间解锁功能（注意策划说会能够所以得index没有时间限制）
    local currentData = self._RankSubType[index]
    self._CurrentSelectRankID = currentData.id
    self._CurrentSelectRankCount = currentData.rankCount
    self._CurrentRankMainDataType = currentData.mainDataType
    self._IsScriptOpenTab = true
    self:SendC2SRankData(self._CurrentSelectRankID ,self._CurrentSelectRankCount) 
    self:UpdataPanelTitle(currentData)
    self._List:SelectItem(self._RankSubType[index].type - 1,self._RankSubType[index].subTypeId - 1)
    self._List:PlayEffect()
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
    elseif id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    end
end

def.method("=>", "table").GetMyRankData = function(self)
    if self._RankData == nil then return nil end
    local hp = game._HostPlayer
    for i,v in ipairs(self._RankData) do
        if v.SubjectId == hp._ID then
            return v
        end
    end
    return nil
end

def.method("=>", "table").GetMyGuildRankData = function(self)
    if self._RankData == nil then return nil end
    local my_guild_id = game._HostPlayer._Guild._GuildID
    for i,v in ipairs(self._RankData) do
        if v.SubjectId == my_guild_id then
            return v
        end
    end
    return nil
end

def.method("table","number","number").UpdateListItem = function(self,data,rankId,myRank)
    local IsSelf = false
    self._RankData = data
    if self._CurrentSelectRankID == rankId then
        local rank = CElementData.GetRankTemplate(rankId)
        if rank then
            self._StatisticsType = rank.StatisticsType   
        end
       --[[ for _,v in pairs(self._RankData) do
            local rank = CElementData.GetRankTemplate(rankId)
            self._StatisticsType = rank.StatisticsType   
            if self._StatisticsType <= EStatisticsType.LANCER then 
                if v.SubjectId == game._HostPlayer._ID then 
                    myRank = v.Rank
                    IsSelf = true
                end
            elseif self._StatisticsType == EStatisticsType.GUILD then 
                if v.SubjectId == game._HostPlayer._Guild._GuildID then 
                    myRank = v.Rank
                    IsSelf = true
                end
                --todo (小队)
            end
        end--]]
        if myRank > 0 then
            IsSelf = true
        end
        self:ShowHostPlayerInfo(myRank,IsSelf)
        if #self._RankData > 0 then
            self._ListGuildListGO:SetActive(true)
            self._Frame_Empty:SetActive(false)
        else
            self._ListGuildListGO:SetActive(false)
            self._Frame_Empty:SetActive(true)
        end
        self._ListGuildList:SetItemCount(#self._RankData)
    end    
end
-- title显示
def.method("table").UpdataPanelTitle = function (self,data)
    local name = "Frame_Member"
    local titleObjectName = name..tostring(data.panelId)
    --self._TitleObj = self._Panel:FindChild(titleObjectName)
    self._TitleObj = self:GetUIObject(titleObjectName)
    self._TitleObj:SetActive(true)
    if self._TitleObj == nil then 
        warn("4444444444444444") 
    end
    self._ListGuildListGO = self._TitleObj
    self._ListGuildList = self:GetUIObject("List_GuildList"..data.panelId):GetComponent(ClassType.GNewListLoop)
end

local ResizeGuidListHeight = function(self, height)
    if self._TitleObj == nil then return end
    local rect = self._TitleObj:GetComponent(ClassType.RectTransform)
    rect.offsetMin = Vector2.New(rect.offsetMin.x, height)
end

-- 控制主角排行信息的显示
def.method("number","boolean").ShowHostPlayerInfo = function (self,myRank,isSelf)
    local hp = game._HostPlayer
    local InfoData = hp._InfoData
    self._MyRank = myRank
    self._IsSelf = isSelf
    self._Frame_HostPlayer:SetActive(true)
    local my_data_from_server = self:GetMyRankData()
    if isSelf then
        if myRank > 3 then
            self._LabMyNumber:SetActive(true)
            self._ImgMyNumber:SetActive(false)
            GUI.SetText(self._LabMyNumber,tostring(myRank))  
            GameUtil.StopUISfx(PATH["UIFX_Ranking_Num1"], self._ImgMyNumber)
            GameUtil.StopUISfx(PATH["UIFX_Ranking_Num2"], self._ImgMyNumber)
            GameUtil.StopUISfx(PATH["UIFX_Ranking_Num3"], self._ImgMyNumber)
        else
            GameUtil.PlayUISfxClipped(PATH["UIFX_Ranking_Num"..myRank], self._ImgMyNumber, self._ImgMyNumber, self._ListGuildListGO)
            self._LabMyNumber:SetActive(false)
            self._ImgMyNumber:SetActive(true)
            GUITools.SetGroupImg(self._ImgMyNumber, myRank - 1)
        end
    else
        self._LabMyNumber:SetActive(true)
        self._ImgMyNumber:SetActive(false)
        GUI.SetText(self._LabMyNumber,StringTable.Get(20103))
    end
    self._ImgHead:SetActive(true)
    if self._CurrentRankMainDataType < ERankDataType.PVPSTAGESTAR or self._CurrentRankMainDataType == ERankDataType.ACHIEVEMENTCOUNT then 
        self._Host1:SetActive(true)
        self._Host2:SetActive(false)
        self._Img_San:SetActive(false)
        self._Lab_SanName:SetActive(false)
        self._LabMainData1:SetActive(true)
        self._MyMainDataTip:SetActive(true)
        self._LabMainData2:SetActive(false)
        self._MyMainDataTip1:SetActive(false)
        GUI.SetText(self._LabName,InfoData._Name)
        GUI.SetText(self._LabName2, InfoData._Name)
        GUI.SetText(self._LabLevel,tostring(InfoData._Level))
        
        local professionTemplate = CElementData.GetProfessionTemplate(InfoData._Prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:",InfoData._Prof)
        else
            GUI.SetText(self._LabJob1, tostring(StringTable.Get(10300 + InfoData._Prof - 1)))
            TeraFuncs.SetEntityCustomImg(self._ImgHead,game._HostPlayer._ID,ECustomSet.ECustomSet_Defualt,Profession2Gender[InfoData._Prof],InfoData._Prof)
        end
        if self._CurrentRankMainDataType == ERankDataType.FIGHT then
            if self._StatisticsType >= EStatisticsType.WARRIOR and self._StatisticsType <= EStatisticsType.LANCER then
                if self._StatisticsType ~= game._HostPlayer._InfoData._Prof then
                    self._Frame_HostPlayer:SetActive(false)
                    ResizeGuidListHeight(self, 0)
                else
                    ResizeGuidListHeight(self, 100)
                    self._Frame_HostPlayer:SetActive(true)
                    local info_data = InfoData._FightProperty
                    local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
                    GUI.SetText(self._LabMainData1, GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or hp:GetHostFightScore(), false))
                    GUI.SetText(self._MyMainDataTip, StringTable.Get(20055))
                end
            else
                ResizeGuidListHeight(self, 100)
                self._Frame_HostPlayer:SetActive(true)
                local info_data = InfoData._FightProperty
                local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
                GUI.SetText(self._LabMainData1, GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or hp:GetHostFightScore(), false))
                GUI.SetText(self._MyMainDataTip, StringTable.Get(20055))
            end

        elseif self._CurrentRankMainDataType == ERankDataType.GOLD then 
            local pack = game._HostPlayer._Package
            local num = GUITools.FormatMoney(my_data_from_server ~= nil and my_data_from_server.MainData or pack._GoldCoinCount)
            GUI.SetText(self._LabMainData1, num)
            GUI.SetText(self._MyMainDataTip, StringTable.Get(400))
        elseif self._CurrentRankMainDataType == ERankDataType.JJC1X1SCORE then 
            self._LabMainData1:SetActive(true)
            GUI.SetText(self._LabMainData1,GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or game._HostPlayer._InfoData._ArenaJJCScore, false))
            GUI.SetText(self._MyMainDataTip, StringTable.Get(20105))
        elseif self._CurrentRankMainDataType == ERankDataType.ELIMINATESCORE then
            self._LabMainData1:SetActive(true)
            GUI.SetText(self._LabMainData1,GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or game._HostPlayer._InfoData._EliminateScore, false))
            GUI.SetText(self._MyMainDataTip, StringTable.Get(20108))
        elseif self._CurrentRankMainDataType == ERankDataType.PVPSTAGE then
            self._LabMainData1:SetActive(false)
            self._MyMainDataTip:SetActive(false)
            self._Img_San:SetActive(true)
            self._Lab_SanName:SetActive(true)
            local data_temp = CElementData.GetPVP3v3Template(game._HostPlayer._InfoData._Arena3V3Stage)
            if data_temp ~= nil then
                local img_level = self._Img_San:FindChild("Img_Level")
                local lab_level = self._Img_San:FindChild("Lab_SanLevel")
                GUITools.SetGroupImg(self._Img_San, data_temp.StageType - 1)
                GUI.SetText(self._Lab_SanName, data_temp.Name)
                if game._HostPlayer._InfoData._Arena3V3Stage == 16 then 
                    img_level:SetActive(false)
                    lab_level:SetActive(true)
                    GUI.SetText(lab_level,GUITools.FormatNumber(game._HostPlayer._InfoData._Arena3V3Star, false))
                else
                    img_level:SetActive(true)
                    lab_level:SetActive(false)
                    GUITools.SetGroupImg(img_level,data_temp.StageLevel - 1)
                end
            else
                warn("error !!!! 角斗场段位数据错误，段位等级为：", game._HostPlayer._InfoData._Arena3V3Stage)
            end
        elseif self._CurrentRankMainDataType == ERankDataType.ACHIEVEMENTCOUNT then
            self._LabMainData1:SetActive(true)
            local totalCount, finishCount =  game._AcheivementMan:GetAchievementCountValue()
            GUI.SetText(self._LabMainData1,GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or finishCount, false))
            GUI.SetText(self._MyMainDataTip, StringTable.Get(20114))
        end
        --end
    elseif self._CurrentRankMainDataType == ERankDataType.GUILD_CONTRIBUTE or self._CurrentRankMainDataType == ERankDataType.BATTLE_WINCOUNT then
        self._Host1:SetActive(false)
        self._Host2:SetActive(true)
        local uiTemplate = self._Host2:GetComponent(ClassType.UITemplate)
        local labGuildLevel = uiTemplate:GetControl(2)
        local labGuildNum = uiTemplate:GetControl(1)
        local labGuildAchi = uiTemplate:GetControl(3)
        local labGuildName = uiTemplate:GetControl(4)
        local lab_battle_tip = uiTemplate:GetControl(5)
        local lab_num_tip = uiTemplate:GetControl(6)
        if not game._GuildMan:IsHostInGuild() then 
            uiTemplate:GetControl(0):SetActive(false)
            self._ImgHead:SetActive(true)
            GUI.SetText(labGuildLevel,tostring(0))
            GUI.SetText(labGuildNum,StringTable.Get(20104))
            GUI.SetText(labGuildAchi,StringTable.Get(20104))
            GUI.SetText(labGuildName,StringTable.Get(20104))
            GUI.SetText(self._LabName,InfoData._Name)
            GUI.SetText(self._LabName2,InfoData._Name)
            if self._CurrentRankMainDataType == ERankDataType.GUILD_CONTRIBUTE then
                GUI.SetText(lab_battle_tip, StringTable.Get(20109))
                GUI.SetText(lab_num_tip, StringTable.Get(20115))
            else
                GUI.SetText(lab_battle_tip, StringTable.Get(20113))
                GUI.SetText(lab_num_tip, StringTable.Get(20110))
            end
        else
            my_data_from_server = self:GetMyGuildRankData()
            local myGuildData = game._HostPlayer._Guild
            local guildFlag = uiTemplate:GetControl(0)
            local _Guild_Icon_Image = {}
            _Guild_Icon_Image[1] = guildFlag:FindChild("Info_Img_Flag_BG")
            _Guild_Icon_Image[2] = guildFlag:FindChild("Info_Img_Flag_Flower_1")
            _Guild_Icon_Image[3] = guildFlag:FindChild("Info_Img_Flag_Flower_2")
            guildFlag:SetActive(true)
            game._GuildMan:SetGuildUseIcon(_Guild_Icon_Image)
            self._ImgHead:SetActive(false)
            GUI.SetText(labGuildLevel,tostring(myGuildData._GuildLevel))
            GUI.SetText(labGuildName,myGuildData._GuildName)
            if self._CurrentRankMainDataType == ERankDataType.GUILD_CONTRIBUTE then
                GUI.SetText(lab_battle_tip, StringTable.Get(20109))
                GUI.SetText(lab_num_tip, StringTable.Get(20115))
                GUI.SetText(labGuildNum,tostring(myGuildData._MemberNum.."/"..myGuildData._MaxMemberNum))
                GUI.SetText(labGuildAchi, GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or myGuildData._GuildLiveness, false))
            else
                GUI.SetText(lab_battle_tip, StringTable.Get(20113))
                GUI.SetText(lab_num_tip, StringTable.Get(20110))
                GUI.SetText(labGuildNum,GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or myGuildData._GuildBFWinCount, false))
                GUI.SetText(labGuildAchi, GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.SubData or myGuildData._GuildBFRank, false))
            end
        end
    elseif self._CurrentRankMainDataType == ERankDataType.ROLELEVEL then 
        self._Host1:SetActive(true)
        self._Host2:SetActive(false)
        self._Img_San:SetActive(false)
        self._Lab_SanName:SetActive(false)
        self._LabMainData2:SetActive(false)
        self._MyMainDataTip1:SetActive(false)
        GUI.SetText(self._LabName,InfoData._Name)
        GUI.SetText(self._LabName2,InfoData._Name)
        local professionTemplate = CElementData.GetProfessionTemplate(InfoData._Prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:",InfoData._Prof)
        else
            --GUITools.SetProfSymbolIcon(self._ImgJob2, professionTemplate.SymbolAtlasPath)
            GUI.SetText(self._LabJob1, tostring(StringTable.Get(10300 + InfoData._Prof - 1)))
            TeraFuncs.SetEntityCustomImg(self._ImgHead,game._HostPlayer._ID,ECustomSet.ECustomSet_Defualt,Profession2Gender[InfoData._Prof],InfoData._Prof)
        end
        -- 判断是否在工会
        if not game._GuildMan:IsHostInGuild() then 
            GUI.SetText(self._LabMainData1,StringTable.Get(20104))
        else
            GUI.SetText(self._LabMainData1,game._HostPlayer._Guild._GuildName)
        end
        GUI.SetText(self._LabLevel,tostring(my_data_from_server ~= nil and my_data_from_server.MainData or InfoData._Level))
        GUI.SetText(self._MyMainDataTip, StringTable.Get(20107))
    elseif self._CurrentRankMainDataType == ERankDataType.ELIMINATESCORE then
        self._Host1:SetActive(true)
        self._Host2:SetActive(false)
        self._Img_San:SetActive(false)
        self._Lab_SanName:SetActive(false)
        self._LabMainData1:SetActive(true)
        self._MyMainDataTip:SetActive(true)
        self._LabMainData2:SetActive(false)
        self._MyMainDataTip1:SetActive(false)
        GUI.SetText(self._LabName,InfoData._Name)
        GUI.SetText(self._LabName2,InfoData._Name)
        local professionTemplate = CElementData.GetProfessionTemplate(InfoData._Prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:",InfoData._Prof)
        else
            --GUITools.SetProfSymbolIcon(self._ImgJob2, professionTemplate.SymbolAtlasPath)
            GUI.SetText(self._LabJob1, tostring(StringTable.Get(10300 + InfoData._Prof - 1)))
            TeraFuncs.SetEntityCustomImg(self._ImgHead,game._HostPlayer._ID,ECustomSet.ECustomSet_Defualt,Profession2Gender[InfoData._Prof],InfoData._Prof)
        end
        GUI.SetText(self._LabMainData1,GUITools.FormatNumber(my_data_from_server ~= nil and my_data_from_server.MainData or game._HostPlayer._InfoData._EliminateScore, false))
        GUI.SetText(self._LabLevel,tostring(InfoData._Level))
        GUI.SetText(self._MyMainDataTip, StringTable.Get(20108))
    elseif self._CurrentRankMainDataType == ERankDataType.TOWERTIER or self._CurrentRankMainDataType == ERankDataType.TOWERTIME then
        self._Host1:SetActive(true)
        self._Host2:SetActive(false)
        self._Img_San:SetActive(false)
        self._Lab_SanName:SetActive(false)
        self._LabMainData1:SetActive(true)
        self._MyMainDataTip:SetActive(true)
        self._LabMainData2:SetActive(true)
        self._MyMainDataTip1:SetActive(true)
        GUI.SetText(self._LabName,InfoData._Name)
        GUI.SetText(self._LabName2, InfoData._Name)
        GUI.SetText(self._LabLevel,tostring(InfoData._Level))
        local professionTemplate = CElementData.GetProfessionTemplate(InfoData._Prof)
        local nTime, nFloor = game._DungeonMan:GetTowerDungeonData()
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:",InfoData._Prof)
        else
            GUI.SetText(self._LabJob1, tostring(StringTable.Get(10300 + InfoData._Prof - 1)))
            TeraFuncs.SetEntityCustomImg(self._ImgHead,game._HostPlayer._ID,ECustomSet.ECustomSet_Defualt,Profession2Gender[InfoData._Prof],InfoData._Prof)
        end
        GUI.SetText(self._LabMainData1, GUITools.FormatTimeSpanFromSeconds(my_data_from_server ~= nil and my_data_from_server.SubData or nTime))
        GUI.SetText(self._MyMainDataTip, StringTable.Get(20111))
        GUI.SetText(self._LabMainData2,tostring(my_data_from_server ~= nil and my_data_from_server.MainData or nFloor))
        GUI.SetText(self._MyMainDataTip1, StringTable.Get(20112))
    end
end
-- 获得排行List的所有Item
def.method().GetAllRankingIDs = function ( self )
    local allIds = CElementData.GetAllTid("Rank")
    for i,v in pairs(allIds) do 
        local rank = CElementData.GetTemplate("Rank", v)
        repeat
            if rank.TimeType == ETimeType.TIME_INTERVAL then 
                local startTimeStr = rank.ShowStartTime 
                local endTimeStr = rank.ShowStopTime
                if startTimeStr == nil and endTimeStr == nil then 
                    warn("Lack LimitTime")
                    break
                end
                local startSec = GUITools.FormatTimeFromGmtToSeconds(startTimeStr) or 0
                local endSec = GUITools.FormatTimeFromGmtToSeconds(endTimeStr) or 4070966340   -- 2099/1/1 23:59

                if GameUtil.GetServerTime()/1000 < startSec or GameUtil.GetServerTime()/1000 > endSec then 
                    break
                end
            end
            self._RankMainType[rank.MainTypeId] = {}
            self._RankMainType[rank.MainTypeId].mainTypeName = rank.MainTypeName
            self._RankMainType[rank.MainTypeId].id = rank.Id
            self._RankMainType[rank.MainTypeId].count = rank.RankCount

            self._RankSubType[rank.Id] = {}
            self._RankSubType[rank.Id].type = rank.MainTypeId 
            self._RankSubType[rank.Id].id = rank.Id
            self._RankSubType[rank.Id].name = rank.SubTypeName
            self._RankSubType[rank.Id].subTypeId = rank.SubTypeId
            self._RankSubType[rank.Id].rankCount = rank.RankCount
            self._RankSubType[rank.Id].panelId = rank.PanelId
            self._RankSubType[rank.Id].mainDataType = rank.MainDataType
        until true 
    end
end
def.override('userdata', 'string','number').OnSelectItem = function(self, item, id, index)
    local v = self._RankData[index + 1]
    local memberId = tonumber(string.sub(id,-1))
    local comps = BlankTable
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local target = uiTemplate:GetControl(10)

    if self._SelectedItems[memberId] ~= nil then
        self._SelectedItems[memberId]:SetActive(false)
        uiTemplate:GetControl(15):SetActive(true)
        self._SelectedItems[memberId] = uiTemplate:GetControl(15)
    else
        uiTemplate:GetControl(15):SetActive(true)
        self._SelectedItems[memberId] = uiTemplate:GetControl(15)
    end
    self._SelectedIndex = index
    if memberId == 6 then
        --TODO 在公会选项里面的东西。
    else
        if v and v.SubjectId ~= game._HostPlayer._ID then
            comps = {
                MenuComponents.SeePlayerInfoComponent.new(v.SubjectId),
                MenuComponents.ChatComponent.new(v.SubjectId),
                MenuComponents.AddFriendComponent.new(v.SubjectId),
            }
            MenuList.Show(comps, target, EnumDef.AlignType.Bottom)
        end
    end
end
def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index) 
    local v = self._RankData[index + 1]
    if not v then return end
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local img_back = uiTemplate:GetControl(0)
    local lab_number = uiTemplate:GetControl(1)  
    --基础数据()
    local lab_Name = uiTemplate:GetControl(2)
    local lab_BaseData = uiTemplate:GetControl(3)
    -- 基础数据中的职业 公会排名中的公会人数
    local subData = uiTemplate:GetControl(4) 
    local img_Number = uiTemplate:GetControl(5)
    local lab_job = uiTemplate:GetControl(8)
    local img_RankingBack = uiTemplate:GetControl(9)
    local MainData = uiTemplate:GetControl(6)
    -- 工会的是工会徽章，其他事玩家头像
    local img_Head = uiTemplate:GetControl(7)
    local memberId = tonumber(string.sub(id,-1))
    local roleInfo = uiTemplate:GetControl(11)
    local guildInfo = uiTemplate:GetControl(12)
    local lab_mainDataTip = uiTemplate:GetControl(13)
    roleInfo:SetActive(true)
    guildInfo:SetActive(false)
    
    if self._SelectedIndex == index then
        uiTemplate:GetControl(15):SetActive(true)
    else
        uiTemplate:GetControl(15):SetActive(false)
    end
    if v.Rank <=3 then 
        img_Number:SetActive(true)
        img_RankingBack:SetActive(true)
        lab_number:SetActive(false)
        GUITools.SetGroupImg(img_Number,v.Rank-1)
        GUITools.SetGroupImg(img_RankingBack, v.Rank-1)
        GameUtil.PlayUISfxClipped(PATH["UIFX_Ranking_Num"..v.Rank], img_Number, img_Number, self._ListGuildListGO)
    else
        GameUtil.StopUISfx(PATH["UIFX_Ranking_Num1"], img_Number)
        GameUtil.StopUISfx(PATH["UIFX_Ranking_Num2"], img_Number)
        GameUtil.StopUISfx(PATH["UIFX_Ranking_Num3"], img_Number)
        img_Number:SetActive(false)
        img_RankingBack:SetActive(false)
        lab_number:SetActive(true)
    end
    GUI.SetText(lab_number,tostring(v.Rank))
    local name = ""
    local baseData2 = ""
    local mainData = ""
    local guildMember = ''
    local baseData = v.BaseDatas   
    if baseData[1] ~= nil then name = baseData[1] end  
    if baseData[2] ~= nil then baseData2 = baseData[2] end  
    mainData = GUITools.FormatNumber(v.MainData, false)
    GUI.SetText(lab_mainDataTip, StringTable.Get(RankingTips[self._CurrentRankMainDataType + 1]))
    if memberId == 4 then       -- 角斗场段位
        MainData:SetActive(false)
        lab_mainDataTip:SetActive(false)
        local lab_san_name = uiTemplate:GetControl(16)
        local img_san = uiTemplate:GetControl(17)
        local img_level = uiTemplate:GetControl(18)
        local lab_level = uiTemplate:GetControl(19)
        if baseData[3] == nil then warn("baseData[3] is nil ") return end
        local prof = tonumber(baseData[3])
        if not prof then return end
        local professionTemplate = CElementData.GetProfessionTemplate(prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:", prof)
            return
        end
        --GUITools.SetProfSymbolIcon(subData, professionTemplate.SymbolAtlasPath)
        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + prof - 1)))
        TeraFuncs.SetEntityCustomImg(img_Head,v.SubjectId,ECustomSet.ECustomSet_Defualt,Profession2Gender[prof],prof)
        local data_temp = CElementData.GetPVP3v3Template(v.MainData)
        if data_temp ~= nil then
            GUITools.SetGroupImg(img_san, data_temp.StageType - 1)
            GUI.SetText(lab_san_name, data_temp.Name)
            if v.MainData == 16 then
                img_level:SetActive(false)
                lab_level:SetActive(true)
                GUI.SetText(lab_level, GUITools.FormatNumber(v.SubData, false))
            else
                img_level:SetActive(true)
                lab_level:SetActive(false)
                GUITools.SetGroupImg(img_level,data_temp.StageLevel - 1)
            end
        end
    elseif memberId <= 5 then
        if baseData[3] == nil then warn("baseData[3] is nil ") return end
        local prof = tonumber(baseData[3])
        if not prof then return end
        local professionTemplate = CElementData.GetProfessionTemplate(prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:", prof)
            return
        end
        --GUITools.SetProfSymbolIcon(subData, professionTemplate.SymbolAtlasPath)    
        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + prof - 1)))
        TeraFuncs.SetEntityCustomImg(img_Head,v.SubjectId,ECustomSet.ECustomSet_Defualt,Profession2Gender[prof],prof)
        GUI.SetText(MainData, GUITools.FormatMoney(v.MainData))
        ----设置主数据的tip
        --GUI.SetText(lab_mainDataTip, StringTable.Get(RankingTips[memberId]))
    -- 工会
    elseif memberId == 6 then   
        roleInfo:SetActive(false)
        guildInfo:SetActive(true)
        local uiTemplate = guildInfo:GetComponent(ClassType.UITemplate)
        local labName = uiTemplate:GetControl(0)
        local labLevel = uiTemplate:GetControl(1)
        local labNums = uiTemplate:GetControl(2)
        local labGuildAchi = uiTemplate:GetControl(3)
        local labRanking = uiTemplate:GetControl(4)
        local lab_battle_tip = uiTemplate:GetControl(8)
        local lab_num_tip = uiTemplate:GetControl(9)
        local guildActiveValue = ""

        local guildInfo = CGuildIconInfo.new()
        guildInfo._BaseColorID = v.GuildIcon.BaseColorID
        guildInfo._FrameID = v.GuildIcon.FrameID
        guildInfo._ImageID = v.GuildIcon.ImageID
        local go_GuildIcon = {}
        go_GuildIcon[1] = uiTemplate:GetControl(5)
        go_GuildIcon[2] = uiTemplate:GetControl(6)
        go_GuildIcon[3] = uiTemplate:GetControl(7)
        game._GuildMan:SetPlayerGuildIcon(guildInfo, go_GuildIcon)

        if baseData[3] ~= nil then 
            guildMember = baseData[3]
        end
        if v.SubjectId == game._HostPlayer._Guild._GuildID then 
            name = "<color=#eebf33>"..name.."</color>"
            GUI.SetText(labRanking,"<color=#eebf33>"..v.Rank.."</color>")
        else
            name = "<color=white>"..name.."</color>"
            GUI.SetText(labRanking,tostring(v.Rank))
        end
        if v.Rank <= 3 then
            labRanking:SetActive(false)
        else
            labRanking:SetActive(true)
        end
        if self._CurrentRankMainDataType == ERankDataType.GUILD_CONTRIBUTE then
            GUI.SetText(lab_battle_tip, StringTable.Get(20109))
            GUI.SetText(lab_num_tip, StringTable.Get(20115))
            GUI.SetText(labNums,guildMember)
            GUI.SetText(labGuildAchi, mainData)
        elseif self._CurrentRankMainDataType == ERankDataType.BATTLE_WINCOUNT then
            GUI.SetText(lab_battle_tip, StringTable.Get(20113))
            GUI.SetText(lab_num_tip, StringTable.Get(20110))
            GUI.SetText(labNums,mainData)
            GUI.SetText(labGuildAchi, GUITools.FormatNumber(v.SubData, false))
        end
        GUI.SetText(labName,name)
        GUI.SetText(labLevel,baseData2)
    elseif memberId == 7 then 
        local prof = tonumber(baseData2)
        local professionTemplate = CElementData.GetProfessionTemplate(prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:", prof)
            return
        end
        --GUITools.SetProfSymbolIcon(subData, professionTemplate.SymbolAtlasPath)
        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + prof - 1)))
        -- 注意等级排行榜中的第二个数据为职业第三个数据为工会名称
        if baseData[3] ~= nil then 
            -- 工会名称
            mainData = baseData[3]
            if mainData == ""then 
                mainData = StringTable.Get(20104)
            end
        end
        baseData2 = tostring(v.MainData)
        TeraFuncs.SetEntityCustomImg(img_Head,v.SubjectId,ECustomSet.ECustomSet_Defualt,Profession2Gender[prof],prof)
        --设置主数据的tip
        GUI.SetText(lab_mainDataTip, StringTable.Get(20107))
    elseif memberId == 8 then
        if v.SubjectId == game._HostPlayer._ID then 
            name = "<color=#eebf33>"..name.."</color>"
            GUI.SetText(lab_number,"<color=#eebf33>"..v.Rank.."</color>")
        else
            name = "<color=white>"..name.."</color>" 
        end
        GUI.SetText(lab_Name,name)
        GUI.SetText(lab_BaseData,baseData2)

        if baseData[3] == nil then warn("baseData[3] is nil ") return end
        local prof = tonumber(baseData[3])
        if not prof then return end
        local professionTemplate = CElementData.GetProfessionTemplate(prof)
        if professionTemplate == nil then
            warn("设置职业徽记时 读取模板错误：profession:", prof)
            return
        end
        GUI.SetText(lab_job, tostring(StringTable.Get(10300 + prof - 1)))
        TeraFuncs.SetEntityCustomImg(img_Head,v.SubjectId,ECustomSet.ECustomSet_Defualt,Profession2Gender[prof],prof)
        local lab_floor_count = uiTemplate:GetControl(16)
        GUI.SetText(lab_floor_count, GUITools.FormatMoney(v.MainData))
        mainData = GUITools.FormatTimeSpanFromSeconds(v.SubData) --tostring(v.SubData)
    end 
    
    -- 榜中主角信息颜色为蓝色(工会另加)
    if self._StatisticsType <= 5 then
        if v.SubjectId == game._HostPlayer._ID then 
            name = "<color=#eebf33>"..name.."</color>"
            GUI.SetText(MainData,mainData)
            GUI.SetText(lab_number,"<color=#eebf33>"..v.Rank.."</color>")
        else
            name = "<color=white>"..name.."</color>" 
            GUI.SetText(MainData,mainData)
        end
        GUI.SetText(lab_Name,name)
        GUI.SetText(lab_BaseData,baseData2)
    end    
end
--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    --print("OnTabListInitItem", item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            GUI.SetText(item:FindChild("Lab_Text"),self._RankMainType[bigTypeIndex].mainTypeName)
            local img_arrow = item:FindChild("Img_Arrow")
            GUITools.SetGroupImg(img_arrow, 0)
            GUITools.SetNativeSize(img_arrow)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            for _,v in pairs(self._RankSubType) do
                if v.type == bigTypeIndex and v.subTypeId == smallTypeIndex then
                    GUI.SetText(item:FindChild("Lab_Text"),v.name)
                end
            end  
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    --print("OnTabListSelectItem", item, main_index, sub_index)
    if list.name == "TabList" then        
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
        self._SelectedIndex = -1
    end
end
def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
    local subList = {}
    for _,v in pairs(self._RankSubType) do
        if v.type == bigTypeIndex then
            subList[#subList + 1] = v
        end
    end  
    local current_type_rankings = self._RankMainType[bigTypeIndex]
    if #subList == 0 then
        --如果没有小类型 直接打开
      -- 暂时不确定
    else
        local function OpenTab()
             --如果有小类型 打开小类型
            local current_type_count = #subList
            local img_arrow = item:FindChild("Img_Arrow")
            self._LastTabItemArrow = img_arrow
            self._List:OpenTab(current_type_count)
            GUITools.SetGroupImg(img_arrow, 2)
            GUITools.SetNativeSize(img_arrow)
            --默认选择了第一项
            if current_type_count > 0 then
                local index = self._List.SubSelected+1
                self._IsTabOpen = true
                self._TitleObj:SetActive(false)
                self:UpdataPanelTitle(subList[index]) 
                self._CurrentSelectRankID = subList[index].id
                self._CurrentSelectRankCount = subList[index].rankCount
                self._CurrentRankMainDataType = subList[index].mainDataType
                self._ListGuildList:ScrollToStep(0)
                if not self._IsScriptOpenTab then
                    self:SendC2SRankData(self._CurrentSelectRankID ,self._CurrentSelectRankCount) 
                end
            end
            -- body
        end
        local function CloseTab()
            self._List:OpenTab(0)
            self._IsTabOpen = false
            GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 1)
            GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
        end
        if self._CurrentSelectTabIndex == bigTypeIndex then
            if self._IsTabOpen then
                CloseTab()
            else
                OpenTab()
            end
        else
            if self._LastTabItemArrow ~= nil then
                GUITools.SetGroupImg(self._LastTabItemArrow, 0)
            end
            OpenTab()
        end
    end
    self._CurrentSelectTabIndex = bigTypeIndex    
end
def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    if self._IsScriptOpenTab then
        self._IsScriptOpenTab = false
        return
    end

     for _,v in pairs(self._RankSubType) do
        if v.type == bigTypeIndex and v.subTypeId == smallTypeIndex then
            self._TitleObj:SetActive(false)
            self._Frame_Empty:SetActive(false)
            self:UpdataPanelTitle(v)       
            self._CurrentSelectRankID = v.id
            self._CurrentSelectRankCount = v.rankCount
            self._CurrentRankMainDataType = v.mainDataType
            self._ListGuildList:ScrollToStep(0)
            self:SendC2SRankData(self._CurrentSelectRankID ,self._CurrentSelectRankCount)
            if (self._CurrentRankMainDataType == ERankDataType.BATTLE_WINCOUNT or self._CurrentRankMainDataType == ERankDataType.BATTLE_SCORE) and game._GuildMan:IsHostInGuild() then
                game._GuildMan:SendC2SGuildBattleWinCount()
            end
        end
    end                 
end

-- C2S
def.method("number","number").SendC2SRankData = function (self,rankId,count)
    local C2SRankGetData = require "PB.net".C2SRankGetData
    local protocol = C2SRankGetData()
    protocol.RankId = rankId
    protocol.Count= count
    PBHelper.Send(protocol)
end
--S2C获取排行榜数据
def.method("table","number","number").LoadRankDataFromSer = function (self, data, id,myRank)
    if data == nil and id == 0 then return end
    self:UpdateListItem(data,id,myRank)
end

def.method().Clear = function (self)
    self._RankData = {}
    self._SelectedItems = {}
end
def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._Frame_Member1 = nil
    self._Frame_Member2 = nil
    self._Frame_Member3 = nil
    self._Frame_Member4 = nil
    self._Frame_Member5 = nil
    self._Frame_Member6 = nil
    self._Frame_Member7 = nil
    self._Frame_Member8 = nil
    self._Frame_Empty = nil
    self._LabMyNumber = nil
    self._ImgMyNumber = nil
    self._ImgHead = nil
    self._LabLevel = nil
    self._LabJob1 = nil
    self._LabName = nil
    self._LabName2 = nil
    self._ImgStage = nil
    self._LabGuildNumber = nil
    self._Frame_HostPlayer = nil
    self._LabMainData1 = nil
    self._List = nil 
    self._Host1 = nil
    self._Host2 = nil
    self._Lab_GuildName = nil
    self._MyMainDataTip = nil
    self._Lab_SanName = nil
    self._Img_San = nil
    self._CurrentRankMainDataType = 0
    self._IsTabOpen = false
    self._LastTabItemArrow = nil
    self._ListGuildListGO = nil
    self._ListGuildList = nil
    CGame.EventManager:removeHandler("NotifyGuildEvent", OnNotifyGuildEvent) 
end
def.override().OnDestroy = function(self)
    self._RankData = {}
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    self._SelectedItems = {}
    --instance = nil --destroy
end
CPanelRanking.Commit()
return CPanelRanking