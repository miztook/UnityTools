
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CUIModel = require "GUI.CUIModel"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local GainNewItemEvent = require "Events.GainNewItemEvent"
local PBHelper = require "Network.PBHelper"
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local C2SGetOtherRoleInfo = require "PB.net".C2SGetOtherRoleInfo
local ModelParams = require "Object.ModelParams"
local BAGTYPE = require "PB.net".BAGTYPE
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelFriendFight = Lplus.Extend(CPanelBase, 'CPanelFriendFight')
local def = CPanelFriendFight.define


def.field("userdata")._LabItemCount = nil 
def.field("userdata")._ImgItemIcon = nil 
def.field("userdata")._ListItem = nil 
def.field("userdata")._LabNothing = nil 
def.field("userdata")._BtnAdd = nil 

def.field("number")._CostItemSpecialId = 550
def.field("number")._LevelLimitSpecialId = 549 
def.field("number")._BaseFreeSpecialId = 552
def.field("number")._AddFreeTimeSpecialId1 = 553
def.field("number")._AddFreeTimeSpecialId2 = 554
def.field("number")._AddFreeTimeSpecialId3 = 555
def.field("number")._CostNumSpecilaId = 551

def.field("number")._HaveItemCount = 0
def.field("number")._BaseFreeTimes = 0
def.field("number")._Amicability1 = 0
def.field("number")._Amicability2 = 0 
def.field("number")._Amicability3 = 0 
def.field("number")._DungeonLimitNum = 0
def.field("number")._CostNum = 0
def.field("table")._CurFightMemList = BlankTable                        -- 参加战斗的成员列表
def.field("table")._CurFriendList  = BlankTable                        -- 可助战好友类表
def.field("number")._DungeonTid = 0
def.field("number")._CurTeamNum = 0
def.field("table")._CurSelectData = BlankTable
def.field("table")._CostItemTemplate = nil 
def.field("number")._CostTid = 0


local instance = nil
def.static('=>', CPanelFriendFight).Instance = function ()
	if not instance then
        instance = CPanelFriendFight()
        instance._PrefabPath = PATH.UI_FriendFight
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end

local OnGainNewItemEvent = function(sender, event)
    if instance ~= nil then
        if instance._Panel == nil then return end
        -- 更新获得数据
        if event.BagType ~= BAGTYPE.BACKPACK then return end
        instance._HaveItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(instance._CostTid)
        GUI.SetText(instance._LabItemCount,tostring(instance._HaveItemCount))
        instance._ListItem:GetComponent(ClassType.GNewList):SetItemCount(#instance._CurFriendList)
    end
end

-- 获取队员信息
local function GetTeamMemberData(self)
    self._CurFightMemList = {}
    if not CTeamMan.Instance():InTeam() then return end
    local list = CTeamMan.Instance():GetMemberList()
    if #list  == 1 then return end
    self._CurTeamNum = #list - 1
    for _,teamMember in ipairs(list) do
        if teamMember._ID ~= game._HostPlayer._ID then 
            local member = {}
            member.IsAI = false
            member.ID = teamMember._ID
            member.Name = teamMember._Name
            member.Profession = teamMember._Profession 
            member.Lv = teamMember._Lv
            member.Param = teamMember._Param
            member.ModelImgRender = nil 
            member.CostItemNum = 0
            table.insert(self._CurFightMemList,member)
        end
    end
end

-- 免费 、亲密度 、等级
local function SortFunction(Item1,Item2)
    if Item1.FreeTimes > Item2.FreeTimes then 
        return true
    elseif Item1.FreeTimes < Item2.FreeTimes then 
        return false
    else 
        if Item1.Amicability > Item2.Amicability then 
            return true
        elseif Item1.Amicability < Item2.Amicability then 
            return false
        else
            if Item1.Lv > Item2.Lv then 
                return true
            elseif Item1.Lv < Item2.Lv then 
                return false
            else
                return false
            end
        end
    end
end

-- 获取可助战好友列表
local function GetFriendFightList(self)
    self._CurFriendList = {}
    local friendList = game._CFriendMan:GetFriendList()
    local levelLimit = game._HostPlayer._InfoData._Level + tonumber(CElementData.GetSpecialIdTemplate(self._LevelLimitSpecialId).Value)
    local mirrorList = game._CFriendMan:GetFightMirrorList()
    if #friendList > 0 then 
        for i,friend in ipairs(friendList) do
            while true do
                if friend.Level > levelLimit then break end
                local isAdd = true
                for i,teamMember in ipairs(self._CurFightMemList) do
                    if teamMember.ID == friend.RoleId then 
                        isAdd = false
                    break end
                end
                if not isAdd then break end
                local member = {}
                member.ID = friend.RoleId
                member.Name = friend.Name 
                member.IsAI = false
                member.Lv = friend.Level
                member.Profession = friend.Profession
                member.CustomImgSet = friend.CustomImgSet
                member.Amicability = friend.Amicability
                member.Gender = friend.Gender
                member.Param = nil 
                
                member.FreeTimes = self._BaseFreeTimes 
                if member.Amicability > self._Amicability1 and member.Amicability < self._Amicability2 then 
                    member.FreeTimes = member.FreeTimes + 1
                elseif member.Amicability > self._Amicability2 and member.Amicability < self._Amicability3 then 
                    member.FreeTimes = member.FreeTimes + 2
                elseif member.Amicability > self._Amicability3 then 
                    member.FreeTimes = member.FreeTimes + 3
                end  
                -- warn("friend.UsedAssistCount  ",friend.UsedAssistCount)
                member.FreeTimes = member.FreeTimes - friend.UsedAssistCount     
                table.insert(self._CurFriendList,member)
            break end
        end
    end
    if #mirrorList > 0 then 
        for i,mirror in ipairs(mirrorList) do
            local member = {}
            member.ID = mirror.RoleId
            local TextTemp = CElementData.GetTextTemplate(tonumber(mirror.Name))
            member.Name = TextTemp.TextContent
            member.Lv = mirror.Level
            member.Profession = mirror.Profession
            member.CustomImgSet = mirror.CustomImgSet
            member.Amicability = mirror.Amicability
            local Gender = Profession2Gender[mirror.Profession]
            member.Gender = Gender
            member.Param = nil 
            
            member.FreeTimes = self._BaseFreeTimes 
            if member.Amicability > self._Amicability1 and member.Amicability < self._Amicability2 then 
                member.FreeTimes = member.FreeTimes + 1
            elseif member.Amicability > self._Amicability2 and member.Amicability < self._Amicability3 then 
                member.FreeTimes = member.FreeTimes + 2
            elseif member.Amicability > self._Amicability3 then 
                member.FreeTimes = member.FreeTimes + 3
            end  

            member.FreeTimes = member.FreeTimes - mirror.UsedAssistCount     
            table.insert(self._CurFriendList,member)
        end
    end
    table.sort( self._CurFriendList, SortFunction )

end

-- C2S获取外观数据
local function C2SGetExterior(self,RoleId)
    local protocol = C2SGetOtherRoleInfo()
    protocol.RoleId = RoleId 
    protocol.InfoType = EOtherRoleInfoType.RoleInfo_Assist
    protocol.Mark = 0
    PBHelper.Send(protocol)
end

-- 队伍显示
local function UpdateTeamPanel(self,index,IsShow,IsLocked,IsShowCircle)
    local FrameMember = self:GetUIObject("FrameMember"..index)
    if FrameMember == nil then warn("index  ",index ) return end
    local uiTemplate = FrameMember:GetComponent(ClassType.UITemplate)
    local memberData = self._CurFightMemList[index]
    local FrameExist = uiTemplate:GetControl(5)
    local imgNone = uiTemplate:GetControl(6)
    local imgLock = uiTemplate:GetControl(8)
    local img_Circle = uiTemplate:GetControl(10) 
    local imgRole = uiTemplate:GetControl(0)
    img_Circle:SetActive(false)
    imgLock:SetActive(false)
    imgNone:SetActive(false)
    FrameExist:SetActive(false)
    if IsLocked then 
        imgLock:SetActive(true)
    return end
    if not IsShow then 
        imgNone:SetActive(true)
        if memberData ~= nil and memberData.ModelImgRender ~= nil  then
            memberData.ModelImgRender:Destroy()        
            memberData.ModelImgRender = nil
        end
        table.remove(self._CurFightMemList,index)
    return end
    if IsShowCircle then 
        img_Circle:SetActive(true)
        imgRole:SetActive(false)
        local rotation = Vector3.New(0, 0, -180)
        local rotationTime = 0.4
        GameUtil.DoLoopRotate(img_Circle, rotation, rotationTime)
    return end
    if memberData == nil then 
        imgNone:SetActive(true)
    return end
    -- 显示 或是更新
    local labName = uiTemplate:GetControl(1)
    local labJob = uiTemplate:GetControl(2)
    local labLevel = uiTemplate:GetControl(3)
    local imgAI = uiTemplate:GetControl(4)
    local BtnExit = uiTemplate:GetControl(7) 
    local Img_JobSign = uiTemplate:GetControl(9) 
    imgNone:SetActive(false)
    FrameExist:SetActive(true)
    imgAI:SetActive(true)
    BtnExit:SetActive(true)
    imgRole:SetActive(true)
    if not memberData.IsAI then 
        imgAI:SetActive(false)
        BtnExit:SetActive(false)
    end
    GUI.SetText(labName,memberData.Name)
    local professionTemplate = CElementData.GetProfessionTemplate(memberData.Profession)
    GUITools.SetProfSymbolIcon(Img_JobSign, professionTemplate.SymbolAtlasPath)
    GUI.SetText(labLevel,string.format(StringTable.Get(21508),memberData.Lv))
    imgRole:SetActive(true)
    -- GUI.SetText(labJob,tostring(StringTable.Get(10300 + memberData.Profession - 1)))
    if not IsNil(memberData.ModelImgRender) then
        memberData.ModelImgRender:Destroy()
    end
    memberData.ModelImgRender = CUIModel.new(memberData.Param, imgRole, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, nil)
    memberData.ModelImgRender:AddLoadedCallback(function() 
        memberData.ModelImgRender:SetModelParam(self._PrefabPath, memberData.Profession)
        end)
    GameUtil.PlayUISfx(PATH.UIFX_FriendFightModelBg,imgRole,imgRole,-1)
end

-- 更新当前选中好友助战的数据
local function UpdateFightFriendDataInfo(self,FriendData)
    if self._CurFightMemList ~= nil and #self._CurFightMemList then
        for i,v in ipairs(self._CurFightMemList) do 
            if FriendData.ID == v.ID then 
                return
            end
        end
    end
    local member = {}
    member.IsAI = true
    member.ID = FriendData.ID
    member.Name = FriendData.Name
    member.Profession = FriendData.Profession 
    member.Lv = FriendData.Lv
    member.Param = FriendData.Param
    member.ModelImgRender = nil
    if FriendData.FreeTimes > 0 then
        member.CostItemNum = 0
    else
        member.CostItemNum = self._CostNum
    end
    table.insert(self._CurFightMemList,member)
end

local function C2SStartFight(self)
    
    local C2SEnterInstance = require"PB.net".C2SEnterInstance
    local protocol = C2SEnterInstance()
    protocol.reqEnterInstance.InstanceId = self._DungeonTid
    for i,v in ipairs(self._CurSelectData) do
        table.insert(protocol.reqEnterInstance.FriendIds,v.ID)
    end
    PBHelper.Send(protocol)
end

def.override().OnCreate = function(self)
   self._LabItemCount = self:GetUIObject("Lab_ItemCount")
   self._ImgItemIcon = self:GetUIObject("Img_ItemIcon")
   self._ListItem = self:GetUIObject("List_Item")
   self._LabNothing = self:GetUIObject("Lab_Nothing")
   self._BtnAdd = self:GetUIObject("Btn_Add")
end

-- 副本Tid
def.override("dynamic").OnData = function(self,data)
    CGame.EventManager:addHandler(GainNewItemEvent, OnGainNewItemEvent)
    self._DungeonTid = data
    self._CostTid = tonumber(CElementData.GetSpecialIdTemplate(self._CostItemSpecialId).Value)
    self._CostItemTemplate = CElementData.GetItemTemplate(self._CostTid)
    self._CostNum = tonumber(CElementData.GetSpecialIdTemplate(self._CostNumSpecilaId).Value)
    if self._CostItemTemplate ~= nil then
        self._HaveItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._CostTid)
        GUITools.SetIcon(self:GetUIObject("Img_ItemIcon"),self._CostItemTemplate.IconAtlasPath)
    end
    self._Amicability1 = tonumber(CElementData.GetSpecialIdTemplate(self._AddFreeTimeSpecialId1).Value)
    self._Amicability2 = tonumber(CElementData.GetSpecialIdTemplate(self._AddFreeTimeSpecialId2).Value)
    self._Amicability3 = tonumber(CElementData.GetSpecialIdTemplate(self._AddFreeTimeSpecialId3).Value)
    self._BaseFreeTimes = tonumber(CElementData.GetSpecialIdTemplate(self._BaseFreeSpecialId).Value)
    GUI.SetText(self._LabItemCount,tostring( self._HaveItemCount))
    self:InitPanel()
end

def.override("string").OnClick = function(self,id)
    if string.find(id,"Btn_Exit") then
        local index = tonumber(string.sub(id,-1))
        local member = self._CurFightMemList[index]
        local index1 = 0
        local item = nil 
        if #self._CurSelectData == 0 then return end
        for i,v in ipairs(self._CurSelectData) do
            if v.ID == member.ID then
                index1 = i
                item = v.Item
            break end
        end
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        uiTemplate:GetControl(1):SetActive(false)
        uiTemplate:GetControl(6):SetActive(false)
        table.remove(self._CurSelectData,index1)
        local isEnd = false
        if index == #self._CurFightMemList then 
            isEnd = true
        end
        UpdateTeamPanel(self,index,false,false,false)
        if isEnd then return end
        if index -1 == 0 then 
            index = 1
        else
            index = index - 1
        end 
        for i = index ,#self._CurFightMemList do 
            UpdateTeamPanel(self,i,true,false,false)
        end
        UpdateTeamPanel(self,#self._CurFightMemList + 1,false,false,false)

    elseif id == "Btn_Start" then
        local cost = 0 
        for _,member in ipairs(self._CurFightMemList) do
            cost = cost + member.CostItemNum 
        end
        if cost == 0 then 
            C2SStartFight(self)
            game._GUIMan:CloseByScript(self)
        elseif cost > 0 and cost <= self._HaveItemCount then 
            local setting =
            {
                [MsgBoxAddParam.CostItemID] = self._CostTid,
                [MsgBoxAddParam.CostItemCount] = cost,
            }
            local  function callback(value)
                if value then 
                    C2SStartFight(self)
                    game._GUIMan:CloseByScript(self)
                end
            end
            local title,msg,closeType = StringTable.GetMsg(135)
            MsgBox.ShowMsgBox(msg,title,closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Normal, setting)
            
        elseif cost > 0 and cost > self._HaveItemCount then
            game._GUIMan:ShowTipText(StringTable.Get(23007),false)
        end
    elseif id == "Btn_Close" then
        game._GUIMan:CloseByScript(self)
    elseif id =="Btn_Add" then 
        local PanelData = 
        {
            ApproachIDs = self._CostItemTemplate.ApproachID,
            ParentObj = self._BtnAdd,
            IsFromTip = false,
            TipPanel = nil,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_Item" then 
        local friendData = self._CurFriendList[index + 1]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local imgHead = uiTemplate:GetControl(0)
        local imgD = uiTemplate:GetControl(1)
        local labName = uiTemplate:GetControl(2)
        -- local imgJob = uiTemplate:GetControl(3)
        local labLevel = uiTemplate:GetControl(4)
        local labAmicabilty = uiTemplate:GetControl(5)
        local imgAI = uiTemplate:GetControl(6)
        local FrameItem = uiTemplate:GetControl(7)
        local labFree = uiTemplate:GetControl(8)
        local labFreeTip = uiTemplate:GetControl(11)
        local imgIcon = uiTemplate:GetControl(9)
        local labCount = uiTemplate:GetControl(10)
        local labJob = uiTemplate:GetControl(12)
        imgD:SetActive(false)
        imgAI:SetActive(false)
        for _,v in ipairs(self._CurSelectData) do
            if v.ID == friendData.ID then 
                v.Item = item
                imgD:SetActive(true)
                imgAI:SetActive(true)
            break end
        end
        GUI.SetText(labName,friendData.Name)
        GUI.SetText(labLevel,string.format(StringTable.Get(21508),friendData.Lv))
        local professionTemplate = CElementData.GetProfessionTemplate(friendData.Profession)
        GUI.SetText(labJob,professionTemplate.Name )
        -- GUITools.SetProfSymbolIcon(imgJob, professionTemplate.SymbolAtlasPath)
        GUI.SetText(labAmicabilty,tostring(friendData.Amicability))
        TeraFuncs.SetEntityCustomImg(imgHead,friendData.ID,friendData.CustomImgSet,friendData.Gender,friendData.Profession)
          
        if friendData.FreeTimes > 0 then
            FrameItem:SetActive(false)
            labFree:SetActive(true)
            GUI.SetText(labFree,tostring(friendData.FreeTimes))
        else
            FrameItem:SetActive(true)
            labFree:SetActive(false)
            labFreeTip:SetActive(false)
            if self._CostItemTemplate ~= nil then
                GUITools.SetIcon(imgIcon,self._CostItemTemplate.IconAtlasPath)
            end
            local count = tostring(self._CostNum)
            --warn("self._CostNum , self._HaveItemCount ",self._CostNum ,self._HaveItemCount )
            if self._CostNum > self._HaveItemCount then
                count = string.format(StringTable.Get(931),count)
            end
            GUI.SetText(labCount,count)
        end
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == "List_Item" then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
        local friendData = self._CurFriendList[index + 1]
        local index1 = 0
        local uiTemplate = item:GetComponent(ClassType.UITemplate) 
        local imgD = uiTemplate:GetControl(1)
        local imgAI = uiTemplate:GetControl(6)
        if #self._CurSelectData == 0 then 
            local member = {}
            member.ID = friendData.ID
            member.Item = item 
            table.insert(self._CurSelectData,member)
            imgD:SetActive(true)
            imgAI:SetActive(true)
            if friendData.Param == nil then
                UpdateTeamPanel(self,#self._CurFightMemList + #self._CurSelectData,true,false,true)
                C2SGetExterior(self,friendData.ID)
            return end
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
            UpdateFightFriendDataInfo(self,friendData)
            UpdateTeamPanel(self,#self._CurFightMemList,true,false,false)
        return end

        local isDelete = false
        for i,v in ipairs(self._CurSelectData) do
            if v.ID == friendData.ID then 
                -- 删除
                index1 = i
                local uiTemplate = item:GetComponent(ClassType.UITemplate) 
                local imgD = uiTemplate:GetControl(1)
                local imgAI = uiTemplate:GetControl(6)
                imgD:SetActive(false)
                imgAI:SetActive(false)
                isDelete = true 
            break end
        end
        -- warn(" #self._CurSelectData,#self._CurFightMemList,self._DungeonLimitNum ",#self._CurSelectData,#self._CurFightMemList,self._DungeonLimitNum)

        if not isDelete and #self._CurSelectData + self._CurTeamNum >= self._DungeonLimitNum - 1 then
            game._GUIMan:ShowTipText(StringTable.Get(930),false)
            return
        elseif not isDelete and #self._CurSelectData + self._CurTeamNum < self._DungeonLimitNum - 1 then
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
            local member = {
                                ID = friendData.ID,
                                Item = item,
                            }
            table.insert(self._CurSelectData,member)
            imgD:SetActive(true)
            imgAI:SetActive(true)
            if friendData.Param == nil then
                UpdateTeamPanel(self,#self._CurFightMemList + #self._CurSelectData - 1,true,false,true)
                C2SGetExterior(self,friendData.ID)
            return end
            UpdateFightFriendDataInfo(self,friendData)
            UpdateTeamPanel(self,#self._CurFightMemList,true,false,false)
            return 
        elseif isDelete then
            table.remove(self._CurSelectData,index1)
            local index2 = 0
            for i,v in ipairs(self._CurFightMemList) do 
                if v.ID == friendData.ID then
                    index2 = i
                end
            end
            local isEnd = false
            if index2 == #self._CurFightMemList then 
                isEnd = true
            end

            UpdateTeamPanel(self,index2,false,false,false)
            -- 点击的是最后一个
            if isEnd then return end
            if index2 -1 == 0 then 
                index2 = 1
            else
                index2 = index2 - 1
            end 
            for i = index2 ,#self._CurFightMemList do 
                UpdateTeamPanel(self,i,true,false,false)
            end
            UpdateTeamPanel(self,#self._CurFightMemList + 1,false,false,false)
        end
    end
end

-- 初始化数据和面板
def.method().InitPanel = function(self)
    
    self._DungeonLimitNum = CElementData.GetInstanceTemplate(self._DungeonTid).AssistSuggestionNumber 
    GetTeamMemberData(self)
    GetFriendFightList(self)

    for i = 1 ,4 do 
        if #self._CurFightMemList > 0 and i <= #self._CurFightMemList then 
            UpdateTeamPanel(self,i,true,false,false)
        elseif i > self._DungeonLimitNum - 1 then 
            UpdateTeamPanel(self,i,true,true,false)
        end
    end

    self._LabNothing:SetActive(false)
    if #self._CurFriendList == 0 then 
        self._LabNothing:SetActive(true)
        for i = #self._CurFightMemList + 1 , self._DungeonLimitNum - 1 do
            UpdateTeamPanel(self,i,true,false,false)
        end
        self._ListItem:GetComponent(ClassType.GNewList):SetItemCount(0)        
    return end

    local CurFriendFightNum = self._DungeonLimitNum -  #self._CurFightMemList - 1
    self._CurSelectData = {}
    for i = 1, CurFriendFightNum do 
        if self._CurFriendList[i] == nil then break end
        local member = {}
        member.ID = self._CurFriendList[i].ID
        member.Item = nil 
        table.insert(self._CurSelectData,member)
        if self._CurFriendList[i].Param == nil then 
            local index = #self._CurFightMemList + i
            UpdateTeamPanel(self,index,true,false,true)
            C2SGetExterior(self,self._CurFriendList[i].ID)
        end
    end  
    self._ListItem:GetComponent(ClassType.GNewList):SetItemCount(#self._CurFriendList)
    self._ListItem:GetComponent(ClassType.GNewList):ScrollToStep(0)

end

-- 得到好友外观模型数据
def.method("table").S2CGetOtherRoleInfo = function(self,data)

    if not self:IsShow() then return end
    local param = ModelParams.new()
    param:MakeParam(data.OtherRoleInfo.Exterior, data.OtherRoleInfo.Profession)
    local FriendData = nil
    for _,member in ipairs(self._CurFriendList) do
        if member.ID == data.RoleId then 
            member.Param = param
            FriendData = member
            break
        end
    end
    if FriendData == nil then warn("RoleId is wrong") return end
    --检测一下当前roleId 是否还在选中列表中
    local isSelected = false
    for _,v in ipairs(self._CurSelectData) do
        if v.ID == data.RoleId then 
            isSelected = true 
            break
        end
    end
    if not isSelected then warn("消息延迟 已经更换选择") return end
    UpdateFightFriendDataInfo(self,FriendData)
    UpdateTeamPanel(self,#self._CurFightMemList,true,false,false)
    if #self._CurFightMemList < self._DungeonLimitNum - 1 then
        for i = #self._CurFightMemList + 1 , self._DungeonLimitNum - 1 do
            UpdateTeamPanel(self,i,true,false,false)
        end
    end
end

def.override().OnDestroy = function (self)
    CGame.EventManager:removeHandler(GainNewItemEvent, OnGainNewItemEvent)
    if #self._CurFightMemList > 0 then 
        for i = 1,#self._CurFightMemList do
            if self._CurFightMemList[i].ModelImgRender ~= nil then 
                self._CurFightMemList[i].ModelImgRender:Destroy()        
                self._CurFightMemList[i].ModelImgRender = nil
            end
        end
    end
    instance = nil 
end

CPanelFriendFight.Commit()
return CPanelFriendFight