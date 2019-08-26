-- 技能专精页
-- 2018/12/25

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"

local CPageSkillMastery = Lplus.Class("CPageSkillMastery")
local def = CPageSkillMastery.define

def.field("table")._Parent = nil

def.field("userdata")._FrameCenter = nil
def.field("userdata")._FrameRight = nil
def.field("userdata")._FrameLeft = nil

--专精图标
def.field("table")._MasteryItemList = BlankTable
--选中专精信息
def.field("userdata")._ImgMasteryIcon = nil            
def.field("userdata")._LabMasteryDisplayName = nil     
def.field("userdata")._LabMasteryName = nil            
def.field("userdata")._LabMasteryLevel = nil           
def.field("userdata")._LabMasteryDesc = nil            
def.field("userdata")._LabAttrNow = nil               
def.field("userdata")._LabAttrNxt = nil                
def.field("userdata")._LabAttrDesc = nil               
def.field("userdata")._ImgCostItemIcon = nil          
def.field("userdata")._BtnCostItme = nil              
def.field("userdata")._LabEngraveNeed = nil          
def.field("userdata")._BtnUpgrade = nil  
def.field("userdata")._UpdBtnEffect = nil  
def.field("userdata")._LabLevelDesc = nil 
def.field("userdata")._LabLevel = nil   
def.field("userdata")._LabMaxDes = nil

--专精Tips
def.field("userdata")._TipListComp = nil
def.field("userdata")._LabCombatPower = nil          

def.field("userdata")._Img_ProArrow = nil

-- 数据
def.field("table")._MasteryInfoList = nil
def.field("table")._ElementMasteryList = BlankTable
def.field("number")._CurSelectIdx = 1
def.field("number")._CurSelectMasteryTid = -1
def.field("number")._CostItemTid = 0

local MasteryMaxCount = 11

def.static("table", "=>", CPageSkillMastery).new = function(root)
	local obj = CPageSkillMastery()
	obj._Parent = root
	obj:Init()
	return obj 
end

def.method().Init = function(self)
    self._FrameCenter = self._Parent:GetUIObject("Frame_Prof")
    self._FrameRight  = self._Parent:GetUIObject("Frame_ProfInfo")
    self._FrameLeft  = self._Parent:GetUIObject("Frame_ProfTip_Bg")

    self._TipListComp = self._Parent:GetUIObject("List_Prof_GuildList"):GetComponent(ClassType.GNewList)
	
    self._ImgMasteryIcon = self._Parent:GetUIObject("Img_ProfIcon")
    self._LabMasteryDisplayName = self._Parent:GetUIObject("Lab_ProfDesc")
    self._LabMasteryName = self._Parent:GetUIObject("Lab_ProfName")
    self._LabMasteryLevel = self._Parent:GetUIObject("Lab_ProfLevel_Num")
    self._LabMasteryDesc = self._Parent:GetUIObject("Lab_ProfDes")
    self._LabAttrNow = self._Parent:GetUIObject("Lab_ProfNow")
    self._LabAttrNxt = self._Parent:GetUIObject("Lab_ProfNext")
    self._LabAttrDesc = self._Parent:GetUIObject("Lab_Prof_Des")
    self._LabLevel = self._Parent:GetUIObject("Lab_ProfNeedLevel")
    self._ImgCostItemIcon = self._Parent:GetUIObject("Prof_Cost_Icon")
    self._BtnUpgrade = self._Parent:GetUIObject("Btn_UpgradeProf")
    self._BtnCostItme = self._Parent:GetUIObject("Btn_Prof_Cost")
    self._LabEngraveNeed = self._Parent:GetUIObject("Lab_EngraveNeed")
    self._LabCombatPower = self._Parent:GetUIObject("Lab_Prof_Combat_Num")
    self._UpdBtnEffect = self._Parent:GetUIObject("Prof_Btn_Effect")
    self._LabLevelDesc = self._Parent:GetUIObject("Lab_42")
    self._LabMaxDes = self._BtnUpgrade.parent:FindChild("Lab_Max_Des")
    self._Img_ProArrow = self._Parent:GetUIObject("Img_ProfArrow")

    for i = 1, MasteryMaxCount do
        local item = {}
        local root = self._Parent:GetUIObject("SkillProf_" .. i)
        item.Root = root
        item.Toggle = root:GetComponent(ClassType.Toggle)
        item.Toggle.isOn = false
        item.Lock = root:FindChild("Lock")
        item.Icon = root:FindChild("Img_Prof_Icon")
        item.Level = root:FindChild("Lab_Prof_Level") 
        item.RedPoint = root:FindChild("RedPoint")
        self._MasteryItemList[i] = item
    end
end

def.method().Show = function (self)
    local item = self._MasteryItemList[self._CurSelectIdx]
    if item ~= nil then
        item.Toggle.isOn = true
    end

	self:Update()
    -- 请求数据
    local protocol = (require "PB.net".C2SSkillMasterySyncInfo)()
    PBHelper.Send(protocol)
end

def.method().Update = function (self)
    self._FrameCenter:SetActive(true)
    self._FrameRight:SetActive(true)

    self:UpdateItemsList()
    self:UpdateSelectedItemInfo(false)
    self._Parent:UpdateTabRedDotState()
end

def.method("string").OnClick = function (self, id)
    if id == 'Btn_UpgradeProf' then
        local nextTid = 0
        local masteryData = self:GetMasteryData(self._CurSelectIdx)
        if masteryData ~= nil then
            if masteryData.UnLockLevel > game._HostPlayer._InfoData._Level then
                game._GUIMan:ShowTipText(StringTable.Get(1303), true)
                return
            end

            nextTid = masteryData.NextTid
        end
        if nextTid > 0 then
            local tmp = CElementData.GetSkillMasteryTemplate(nextTid)
            local callback = function(val)
                if val then
                    -- 展示升级动画
                    GameUtil.PlayUISfx(PATH.UIFX_TongYongShuXingLiuGuang_01, self._Img_ProArrow, self._Img_ProArrow, -1)
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_SkillUpgrade, 0)
                    local protocol = (require "PB.net".C2SSkillMasteryUpgradeReq)() 
                    protocol.Tid = nextTid
                    PBHelper.Send(protocol) 
                end
            end
            local limit = {
                [EQuickBuyLimit.RoleLevel] = (tmp ~= nil and tmp.Level or nil),
                [EQuickBuyLimit.MatID] = tmp.CostItemId,
                [EQuickBuyLimit.MatNeedCount] = tmp.CostItemCount,
            }

            MsgBox.ShowQuickBuyBox(tonumber(tmp.CostMoneyId), tonumber(tmp.CostMoneyCount), callback, limit)
        end
    elseif id == 'Btn_AttrAdd' then
        self:ShowMasteryTips(true)
    elseif id == 'Btn_Prof_Cost' then
        if self._CostItemTid ~= 0 then
            CItemTipMan.ShowItemTips(self._CostItemTid, TipsPopFrom.OTHER_PANEL, self._BtnCostItme, TipPosition.FIX_POSITION)
        end
    elseif id == 'Frame_ProfTip_Bg' then
        self:ShowMasteryTips(false)
    end
end

def.method("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "SkillProf_") then
        local id_data = string.split(id, "_")
        if id_data[2] then
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
            local index = tonumber(id_data[2])
            self._CurSelectIdx = index
            self:UpdateSelectedItemInfo(false)
        end
    end
end

def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local data = self._MasteryInfoList[index+1]
    local propertyTmp = CElementData.GetAttachedPropertyTemplate(data.ID)
    if propertyTmp ~= nil then
        local attr_name = item:FindChild("Lab_AttrName")
        GUI.SetText(attr_name, tostring(propertyTmp.TextDisplayName))              
        local attr_num = item:FindChild("Lab_AttrNum")
        GUI.SetText(attr_num, GUITools.FormatNumber(data.Value, false))             
    end
end

def.method().UpdateItemsList = function(self)
    local game = game
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local hpLv = hp._InfoData._Level
    local goldHasCount = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
    for i = 1, MasteryMaxCount do
        local item = self._MasteryItemList[i]
        local canUpdate = false
        local isLock = true
        local lvTxt = ""
        local masteryData = self:GetMasteryData(i)
        if masteryData ~= nil then
            local temp = CElementData.GetSkillMasteryTemplate(masteryData.Tid)
            if temp == nil then break end
            GUITools.SetIcon(item.Icon, temp.IconPath)
            isLock = (hpLv < masteryData.UnLockLevel)
            if isLock then
                GameUtil.MakeImageGray(item.Icon, true)
                GameUtil.ChangeGraphicAlpha(item.Icon, 0.2)
                GameUtil.SetTextAlignment(item.Level, 4)  -- 居中对齐
                lvTxt = string.format("<color=red>Lv.%d</color>", masteryData.UnLockLevel)
            else
                GameUtil.MakeImageGray(item.Icon, false)
                GameUtil.ChangeGraphicAlpha(item.Icon, 1)
                GameUtil.SetTextAlignment(item.Level, 6)  -- 左对齐
                lvTxt = string.format("<color=#ECB554>Lv.</color> <color=white>%d</color>", temp.Level)
            end

            if not isLock then
                local nextLvTemp = CElementData.GetSkillMasteryTemplate(masteryData.NextTid)
                if nextLvTemp ~= nil then
                    local itemHasCount = pack:GetItemCount(nextLvTemp.CostItemId)
                    canUpdate = (itemHasCount >= nextLvTemp.CostItemCount and hpLv >= nextLvTemp.Level and goldHasCount >= nextLvTemp.CostMoneyCount)           
                end
            end
        end
        item.RedPoint:SetActive(canUpdate)
        item.Lock:SetActive(isLock)
        GUI.SetText(item.Level, lvTxt) 
    end
end

def.method("boolean").UpdateSelectedItemInfo = function(self, is_upd)
    local masteryData = self:GetMasteryData(self._CurSelectIdx)
    if masteryData ~= nil then            
        local tmp = CElementData.GetSkillMasteryTemplate(masteryData.Tid)              
        if tmp ~= nil then
            GUITools.SetIcon(self._ImgMasteryIcon, tmp.IconPath)
            GUI.SetText(self._LabMasteryDisplayName, tmp.DisplayName)
            GUI.SetText(self._LabMasteryName, tmp.Name)
            GUI.SetText(self._LabMasteryLevel, tostring(tmp.Level))
            GUI.SetText(self._LabMasteryDesc, tmp.Description)
            GUI.SetText(self._LabAttrNow, tostring(GUITools.FormatNumber(tonumber(tmp.PropValue), false)))
            local hp = game._HostPlayer
            local can_upd = true
            local enough_Money = true
            local nxt_tmp = CElementData.GetSkillMasteryTemplate(masteryData.NextTid)          
            if nxt_tmp then
                local playerGold = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
                self._LabAttrNxt:SetActive(true)

                if is_upd and (self._CurSelectMasteryTid > 0 and self._CurSelectMasteryTid ~= masteryData.Tid )then
                    GameUtil.PlayUISfx(PATH.UI_shengjishuzhi, self._LabAttrNxt, self._LabAttrNxt, -1)
                end
                
                GUI.SetText(self._LabAttrNxt, tostring(GUITools.FormatNumber(tonumber(nxt_tmp.PropValue), false)))        
                local goldDes = nxt_tmp.CostMoneyCount
                if playerGold >= nxt_tmp.CostMoneyCount then
                    goldDes = "<color=white>" .. GUITools.FormatMoney(nxt_tmp.CostMoneyCount) .. "</color>"
                else
                    goldDes = "<color=red>" .. GUITools.FormatMoney(nxt_tmp.CostMoneyCount) .. "</color>"
                    enough_Money = false
                end
                GUI.SetText(self._LabEngraveNeed, goldDes)

                local playerLevel = hp._InfoData._Level
                local levelString = nil
                local lvDescId = 0
                if masteryData.UnLockLevel <= playerLevel then
                    if playerLevel >= nxt_tmp.Level then
                        levelString = "<color=white>" .. (tmp.Level + 1)  .. "</color>"        
                    else        
                        levelString = "<color=red>" .. (tmp.Level + 1) .. "</color>"
                        can_upd = false
                    end 
                    lvDescId = 1300
                else
                    can_upd = false
                    levelString = "<color=red>" .. (masteryData.UnLockLevel) .. "</color>"
                    lvDescId = 1301
                end
                GUI.SetText(self._LabLevel, levelString)
                GUI.SetText(self._LabLevelDesc, StringTable.Get(lvDescId))

                local pack = hp._Package._NormalPack
                local bag_num = pack:GetItemCount(nxt_tmp.CostItemId)
                if bag_num >= nxt_tmp.CostItemCount and nxt_tmp.Level <= hp._InfoData._Level then
                else
                    can_upd = false
                end    
                
            else
                self._LabAttrNxt:SetActive(false)
                GUI.SetText(self._LabEngraveNeed,"<color=white>" .. tostring(0) .. "</color>")
                GUI.SetText(self._LabLevel, "<color=red>" .. (tmp.Level) .. "</color>")
                can_upd = false
            end

            local item_tmp = CElementData.GetItemTemplate(tmp.CostItemId)
            self._CostItemTid = tmp.CostItemId
            if item_tmp then
                local costnum = 0
                if nxt_tmp then
                    costnum = nxt_tmp.CostItemCount
                end
                IconTools.InitMaterialIconNew(self._ImgCostItemIcon, tmp.CostItemId, costnum)                             
            end

            self._UpdBtnEffect:SetActive(can_upd and enough_Money)
            GUITools.SetBtnGray(self._BtnUpgrade, not can_upd)

            local property_tmp = CElementData.GetAttachedPropertyTemplate(tmp.PropID)
            if property_tmp then
                GUI.SetText(self._LabAttrDesc, tostring(property_tmp.TextDisplayName))
            end
        end

        self._CurSelectMasteryTid = masteryData.Tid

        
        local isMax = tmp.Level + 1 > MaxLevel
        self._BtnUpgrade:SetActive(not isMax)
        self._LabMaxDes:SetActive(isMax)
        self._LabAttrDesc.parent:SetActive(not isMax)
        self._BtnCostItme:SetActive(not isMax)
        self._LabLevel.parent:SetActive(not isMax)
    end


end

def.method("boolean").ShowMasteryTips = function(self, state)
    if state then   
        self._FrameLeft:SetActive(true)
        
        local hp = game._HostPlayer
        local masteryInfos, score = hp:GetSkillMasteryInfo()
        self._MasteryInfoList = {}
        for i = 1, #masteryInfos do
            local tmp = CElementData.GetSkillMasteryTemplate(masteryInfos[i].Tid)
            if tmp ~= nil then         
                local match = false
                for j = 1, #self._MasteryInfoList do 
                    if self._MasteryInfoList[j].ID == tmp.PropID then
                        self._MasteryInfoList[j].Value = self._MasteryInfoList[j].Value + tmp.PropValue
                        match = true
                    end
                end

                if not match then
                    if tmp.PropValue > 0 then
                        table.insert(self._MasteryInfoList, { ID = tmp.PropID, Value = tmp.PropValue})
                    end
                end
            end
        end
        self._TipListComp:SetItemCount(#self._MasteryInfoList)
        GUI.SetText(self._LabCombatPower, GUITools.FormatNumber(math.floor(score), false))
    else
        self._FrameLeft:SetActive(false)
        self._MasteryInfoList = nil
    end
end

def.method("number", "=>", "table").GetMasteryData = function(self, index)
    local result = nil
    local masteryInfos, _ = game._HostPlayer:GetSkillMasteryInfo()    
    for i = 1, #masteryInfos do
        local info = masteryInfos[i]
        local tmp = CElementData.GetSkillMasteryTemplate(info.Tid)
        if tmp ~= nil then
            if index <= 8 then
                if tmp.PlaceType == 1 and tmp.PlaceParam == (index - 1) then
                    result = info
                end
            else
                if tmp.PlaceType == 2 and tmp.PlaceParam == self:GetElementMasteryPos(index % 8) then
                    result = info
                end
            end
        end
    end
    return result
end

def.method("number", "=>", "number").GetElementMasteryPos = function(self, index)
    local pos = -1
    if #self._ElementMasteryList == 0 then
        -- 510-514  对应的元素 EElementType
        local hp = game._HostPlayer
        local data = nil
        if hp._InfoData._Prof  == EnumDef.Profession.Warrior then
            data = CElementData.GetSpecialIdTemplate(510).Value
        elseif hp._InfoData._Prof  == EnumDef.Profession.Aileen then
            data = CElementData.GetSpecialIdTemplate(511).Value
        elseif hp._InfoData._Prof  == EnumDef.Profession.Assassin then
            data = CElementData.GetSpecialIdTemplate(512).Value
        elseif hp._InfoData._Prof  == EnumDef.Profession.Archer then        
            data = CElementData.GetSpecialIdTemplate(513).Value
        elseif hp._InfoData._Prof  == EnumDef.Profession.Lancer then
            data = CElementData.GetSpecialIdTemplate(514).Value
        end

        if data ~= nil then
            data = string.split(data, "*")
            for i,v in ipairs(data) do
                self._ElementMasteryList[#self._ElementMasteryList + 1] = tonumber(v)
            end
        end
    end

    if self._ElementMasteryList[index] ~= nil then
        pos = self._ElementMasteryList[index]
    end

    return pos
end

def.method().Hide = function (self)
    self._FrameCenter:SetActive(false)
    self._FrameRight:SetActive(false)
    self._FrameLeft:SetActive(false)
    self._MasteryInfoList = nil
end

def.method().Destroy = function (self)
    self._Parent = nil
    self._FrameCenter = nil
    self._FrameRight = nil
    self._FrameLeft = nil
    self._MasteryItemList = nil
    self._ImgMasteryIcon = nil            
    self._LabMasteryDisplayName = nil     
    self._LabMasteryName = nil            
    self._LabMasteryLevel = nil           
    self._LabMasteryDesc = nil            
    self._LabAttrNow = nil               
    self._LabAttrNxt = nil                
    self._LabAttrDesc = nil               
    self._ImgCostItemIcon = nil          
    self._BtnCostItme = nil              
    self._LabEngraveNeed = nil          
    self._BtnUpgrade = nil  
    self._UpdBtnEffect = nil  
    self._LabLevelDesc = nil 
    self._LabLevel = nil               
    self._TipListComp = nil
    self._LabCombatPower = nil  
    self._Img_ProArrow = nil
end

CPageSkillMastery.Commit()
return CPageSkillMastery