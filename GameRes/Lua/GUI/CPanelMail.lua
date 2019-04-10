
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CEmailMan = Lplus.ForwardDeclare("CEmailMan").Instance()
local CElementData = require "Data.CElementData"
local RewardType = require"PB.data".RewardType

local CPanelMail = Lplus.Extend(CPanelBase, 'CPanelMail')
local def = CPanelMail.define
 
def.field('userdata')._List_Mail = nil
def.field('userdata')._LabSenderName = nil
def.field('userdata')._List_Item = nil
def.field('userdata')._Lab_Dimension = nil
def.field('userdata')._Lab_Nothing = nil
def.field('userdata')._Btn_Check = nil
def.field("userdata")._Lab_EmailTitle = nil
def.field('userdata')._Frame_NotingMail = nil
def.field('userdata')._Frame_LeftList = nil
def.field('userdata')._Frame_Right = nil
def.field('userdata')._Frame_Bottom = nil
def.field('userdata')._Btn_CheckAll = nil
def.field('userdata')._Btn_CleanALL = nil
def.field('table')._EmailData = BlankTable   --邮件数据
def.field('table')._Reward = BlankTable   --邮件奖励

def.field('number')._EmailCreateTime = 0	--邮箱有效时间(天)
def.field('number')._EmailCreateTimeId = 123	--邮箱有效时间Id
def.field("boolean")._IsSelect = false  --是否为选中邮件
def.field("number")._SelectIndex = 0  --当前选中邮件的index
def.field("userdata")._Lab_SenderTips = nil
def.field("userdata")._SliderStore = nil 
def.field("userdata")._LabStore = nil 
def.field("boolean")._IsFirstOpen = false
def.field("userdata")._BeforeSelectItem = nil 
def.field("number")._BeforeSelectIndex = 0 
local instance = nil
def.static('=>', CPanelMail).Instance = function ()
	if not instance then
        instance = CPanelMail()
        instance._PrefabPath = PATH.UI_Mail
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._List_Mail = self:GetUIObject('List_Mail'):GetComponent(ClassType.GNewList)
    local TextType = ClassType.Text
    self._LabSenderName = self:GetUIObject('lab_SenderName')
    self._List_Item = self:GetUIObject('List_Reward'):GetComponent(ClassType.GNewList)
    self._Lab_Dimension = self:GetUIObject('Lab_Dimension')
    self._Lab_Nothing = self:GetUIObject("Lab_Nothing")
    self._Btn_Check = self:GetUIObject('Btn_Check')
    -- self._Btn_Clean = self:GetUIObject('Btn_Clean')
    self._Btn_CheckAll = self:GetUIObject('Btn_CheckAll')
    self._Btn_CleanALL = self:GetUIObject('Btn_CleanALL')
    self._Lab_EmailTitle = self:GetUIObject("Lab_MailTitle")
    self._Lab_SenderTips = self:GetUIObject("lab_Sender")
    self._Frame_NotingMail = self:GetUIObject('Frame_NotingMail')
    self._Frame_Right = self:GetUIObject('Frame_Right')
    self._Frame_Bottom = self:GetUIObject('Frame_Bottom')
    self._Frame_LeftList = self:GetUIObject('Frame_LeftList')
    self._SliderStore = self:GetUIObject("SliderStore"):GetComponent(ClassType.Slider)
    self._LabStore = self:GetUIObject("Lab_Store")
    game:SendC2SRankRewardGet()
    self._SelectIndex = 0
    self._IsSelect = false
    self._EmailData = {}
    self._Reward = {}
    self._IsFirstOpen = false
    self._Frame_Right:SetActive(false)
    self._Frame_Bottom:SetActive(false)
    self._Frame_LeftList:SetActive(false)
    self._Btn_CleanALL:SetActive(false)
    self._Btn_CheckAll:SetActive(false)
    self._Btn_Check:SetActive(false)
    -- warn("----------------OnCreate---------------", #CEmailMan:GetEmailList())    
    self:OnEmailList()   
end

def.override("dynamic").OnData = function(self,data)     
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Open_Mail, 0)
end

local LessPred = function (email1, email2) --按照时间和是否已读排序
	if email1 ~= nil and email2 == nil then
        return true
    elseif email1 == nil and email2 ~= nil then
        return false
    end
    if not email1._IsRead and email2._IsRead then    -- 未阅读 > 已阅读。
        return true
    end 

    if email1._IsRead and not email2._IsRead then    -- 未阅读 > 已阅读。  
        return false
    end
    if email1._IsRead and email2._IsRead then 
        if email1._IsHaveReward and not email2._IsHaveReward then -- 有附件 > 无附件
            return true
        end
        if not email1._IsHaveReward and email2._IsHaveReward  then  -- 有附件 > 无附件 
            return false
        end
        if email2._IsHaveReward and email1._IsHaveReward then  -- 有附件的 未领取 > 已领取
            if not email1._IsDraw and  email2._IsDraw then 
                return true
            end
            if  email1._IsDraw and not email2._IsDraw then 
                return false
            end
        end
    end
	-- if email1._CreateTime ~= email2._CreateTime then  --  时间晚 > 时间早
	-- 	return email1._CreateTime < email2._CreateTime
	-- end

	return email1._EmailID < email2._EmailID  -- 按照是否已读排序
end 

--得邮件数据
def.method().OnEmailList = function(self) 
    self._EmailData = CEmailMan:GetEmailList()
    local count = #self._EmailData
    if count == 0 then        
        self._Frame_Right:SetActive(false)
        self._Frame_Bottom:SetActive(false)   
        self._Frame_LeftList:SetActive(false)
        self._Frame_NotingMail:SetActive(true) 
        -- GameUtil.SetButtonInteractable(self._Btn_CleanALL, false)
        -- GameUtil.SetButtonInteractable(self._Btn_CheckAll, false)
        -- GameUtil.SetButtonInteractable(self._Btn_Check, false)         
        self._Btn_CleanALL:SetActive(false)
        self._Btn_CheckAll:SetActive(false)
        self._Btn_Check:SetActive(false) 
    else        
        self._Frame_NotingMail:SetActive(false)
        self._Btn_CleanALL:SetActive(true)
        self._Btn_CheckAll:SetActive(true)
        self._Btn_Check:SetActive(true) 
        GameUtil.SetButtonInteractable(self._Btn_CleanALL, true)
        GameUtil.SetButtonInteractable(self._Btn_CheckAll, true)
        GameUtil.SetButtonInteractable(self._Btn_Check, true)
        self._Frame_Right:SetActive(true)
        self._Frame_Bottom:SetActive(true)
        self._Frame_LeftList:SetActive(true)
        if self._EmailCreateTime == 0 then   --获取特殊配置中邮件的有效时间（天）
            self._EmailCreateTime = tonumber(CElementData.GetSpecialIdTemplate(self._EmailCreateTimeId).Value)
            self._EmailCreateTime = self._EmailCreateTime * 86400
        end                    
    end
    -- self._Btn_CleanALL:SetActive(true)
    -- self._Btn_CheckAll:SetActive(true)
    -- self._Btn_Check:SetActive(true)
    if self._IsSelect == false then --打开界面之后只走一遍排序
        if count > 1 then
            table.sort(self._EmailData, LessPred)
        end
        self._IsSelect = true
    end

     --邮件最大数量定死的 策划说的
     self._SliderStore.value = count / 100 
     GUI.SetText(self._LabStore,count.."/"..100)
     self._List_Mail:SetItemCount(count)
    if CEmailMan:OnEmailRedPoint() then
        GUITools.SetBtnGray(self._Btn_CheckAll, false)
    else
        GUITools.SetBtnGray(self._Btn_CheckAll, true)
    end
    
    if count ~= 0 and self._SelectIndex == 0 then
        local item = self:GetUIObject('List_Mail'): FindChild("item-"..self._SelectIndex)
        local uiTemplate = item:GetComponent(ClassType.UITemplate)   
        local Img_D = uiTemplate:GetControl(1)
        local Img_ItemIcon = uiTemplate:GetControl(3)
        --默认读取第一封邮件            
        self._SelectIndex = 1
        Img_D:SetActive(true)
        self._BeforeSelectItem = item
        self._BeforeSelectIndex = self._SelectIndex
        self:OnCurrentSelectEmail(self._SelectIndex)        
        local do_tween_player = item:GetComponent(ClassType.DOTweenPlayer)
        if do_tween_player ~= nil then
            do_tween_player:Restart("1")
            do_tween_player:Restart("2")
        end
        if self._EmailData[self._SelectIndex]._IsRead == false then             
            GameUtil.PlayUISfx(PATH.UIFX_MAIL_zhankai, Img_ItemIcon, Img_ItemIcon, -1)
            CEmailMan:OnC2SReadEmail(self._EmailData[self._SelectIndex]._EmailID)
        end
    end
    
end

def.override('string').OnClick = function(self, id)    
    if id == 'Btn_Close' then        
        game._GUIMan:Close("CPanelMail")
    elseif id == 'Btn_CleanALL' then        
        local function callback( value )
            if not value then return end
            CEmailMan:OnC2SEmailBatchRemove()   
            -- body
        end
        local title, str, closeType = StringTable.GetMsg(117)
        MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
    elseif id == 'Btn_CheckAll' then    
        CEmailMan:OnC2SEmailBatchDrawReward()
    elseif id == 'Btn_Check' then    
        CEmailMan:OnC2SEmailDrawReward(self._EmailData[self._SelectIndex]._EmailID)
    elseif id == 'Btn_Clean' then
        CEmailMan:OnC2SEmailRemove(self._EmailData[self._SelectIndex]._EmailID)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)    
    if id == 'List_Mail' then  --邮件列表显示
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local emailIndex = index + 1 
        local Lab_MaillName = uiTemplate:GetControl(5)
        local Lab_Part = uiTemplate:GetControl(6)
        local Lab_Enahnce = uiTemplate:GetControl(7)
        local Img_ItemIcon = uiTemplate:GetControl(3)
        local Img_D = uiTemplate:GetControl(1)
        local Img_New = uiTemplate:GetControl(4)
        local Img_Bg = uiTemplate:GetControl(0)
        local Img_Read = uiTemplate:GetControl(8)
        local Img_ItemIcon_Open = uiTemplate:GetControl(9)
        local strTime = os.date("%Y-%m-%d", self._EmailData[emailIndex]._CreateTime)
        local createTime = self._EmailCreateTime - (GameUtil.GetClientTime() / 1000 - self._EmailData[emailIndex]._CreateTime)
        if createTime > 86400 then
            createTime = math.round(createTime / 86400) .. StringTable.Get(1003)
        else
            -- createTime = StringTable.Get(15001)            
            local time = os.date("%Y/%m/%d %H:%M:%S", createTime)
            if time ~= nil then
                local year, mon, mday, hour, min, sec = string.match(time, "(%d+)/(%d+)/(%d+) (%d+):(%d+):(%d+)")
                createTime = hour..StringTable.Get(1002).. min ..StringTable.Get(1001)
            else
                createTime = StringTable.Get(15001) 
            end
        end
        if self._EmailData[emailIndex]._IsRead == true then            
            Img_ItemIcon_Open:SetActive(true)      
            -- Img_ItemIcon:SetActive(false)     
            -- GUITools.SetGroupImg(Img_ItemIcon,1)  
            if not self._EmailData[emailIndex]._IsHaveReward then
                Img_Read:SetActive(true)
                GUITools.MakeBtnBgGray(Img_Read, true)
                GUI.SetAlpha(Img_Read, 26)
                Img_New:SetActive(false)
            else
                --附件
                if not self._EmailData[emailIndex]._IsDraw then
                    Img_New:SetActive(true)
                    Img_Read:SetActive(false)
                    GUITools.MakeBtnBgGray(Img_Read, false)
                else
                    Img_New:SetActive(false)
                    Img_Read:SetActive(true)
                    GUITools.MakeBtnBgGray(Img_Read, true)
                    GUI.SetAlpha(Img_Read, 26)
                end
            end
        else
            Img_ItemIcon:SetActive(true) 
            GUITools.SetGroupImg(Img_ItemIcon,0)
            Img_ItemIcon_Open:SetActive(false)
            Img_Read:SetActive(false)
            GUITools.MakeBtnBgGray(Img_Read, false)
            -- 未读
            if not self._EmailData[emailIndex]._IsHaveReward then
                Img_New:SetActive(false)
                if not self._EmailData[emailIndex]._IsDraw then 
                end
            else
                Img_New:SetActive(true)                
            end
        end

        if self._SelectIndex ~= emailIndex then        
            Img_D:SetActive(false)
        elseif self._SelectIndex == emailIndex then            
            Img_D:SetActive(true)
            self:OnCurrentSelectEmail(self._SelectIndex)   
            Img_Read:SetActive(false) 
            GUITools.MakeBtnBgGray(Img_Read, false)
        end
        GUI.SetText(Lab_MaillName,self._EmailData[emailIndex]._Title)
        GUI.SetText(Lab_Part,strTime)
        GUI.SetText(Lab_Enahnce,StringTable.Get(15000) ..createTime)


    elseif id == 'List_Reward' then  --邮件内容奖励列表
        local itemData = nil
        local frame_icon = GUITools.GetChild(item, 0)
        local uiTemplate = frame_icon:GetComponent(ClassType.UITemplate)
        local Img_Done = uiTemplate:GetControl(5)
        if self._Reward[index + 1 ].Id ~= nil then
            -- itemData = CElementData.GetTemplate("Item", self._Reward[index + 1].Id)
            if self._Reward[index + 1 ].Type == RewardType.Item then 
                IconTools.InitItemIconNew(frame_icon, self._Reward[index + 1].Id, { [EItemIconTag.Number] = self._Reward[index + 1].Num })
            elseif self._Reward[index + 1 ].Type == RewardType.Resource then 
                IconTools.InitTokenMoneyIcon(frame_icon, self._Reward[index + 1 ].Id, self._Reward[index + 1].Num)
            end

        elseif self._Reward[index + 1 ].Tid ~= nil then
            -- itemData = CElementData.GetTemplate("Item", self._Reward[index + 1].Tid)   
            IconTools.InitItemIconNew(frame_icon, self._Reward[index + 1].Tid, { [EItemIconTag.Number] = self._Reward[index + 1].Count })
        
        -- 走奖励模板
        elseif self._Reward[index + 1].IsTokenMoney ~= nil then 
            if self._Reward[index + 1].IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_icon, self._Reward[index + 1].Data.Id, self._Reward[index + 1].Data.Count)
            else
                IconTools.InitItemIconNew(frame_icon, self._Reward[index + 1].Data.Id, { [EItemIconTag.Number] = self._Reward[index + 1].Data.Count })
            end
        else 
            warn("itemData have lost!!!")      
        end
        if self._EmailData[self._SelectIndex]._IsDraw then
            Img_Done:SetActive(true)
            GameUtil.SetCanvasGroupAlpha(uiTemplate:GetControl(3), 0.5)
        else
            Img_Done:SetActive(false)
            GameUtil.SetCanvasGroupAlpha(uiTemplate:GetControl(3), 1)
        end  
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index) 
    local uiTemplate = item:GetComponent(ClassType.UITemplate)   
    if id == 'List_Mail' then
        self._SelectIndex = index + 1
        local Img_D = uiTemplate:GetControl(1)
        local Img_ItemIcon = uiTemplate:GetControl(3)
        Img_D:SetActive(true)        
        if self._BeforeSelectIndex ~= self._SelectIndex then 
            self._BeforeSelectIndex = self._SelectIndex
            if not IsNil(self._BeforeSelectItem) then 
                self._BeforeSelectItem:FindChild("Img_D"):SetActive(false)
            end   
            self._BeforeSelectItem = item
        end
        
        local do_tween_player = item:GetComponent(ClassType.DOTweenPlayer)
        if do_tween_player ~= nil then
            do_tween_player:Restart("1")
            do_tween_player:Restart("2")
        end
        if self._EmailData[self._SelectIndex]._IsRead == false then
            GameUtil.PlayUISfx(PATH.UIFX_MAIL_zhankai, Img_ItemIcon, Img_ItemIcon, -1)    
            CEmailMan:OnC2SReadEmail(self._EmailData[self._SelectIndex]._EmailID)
        end
        self:OnCurrentSelectEmail(self._SelectIndex)        
   elseif id == 'List_Reward' then
        if self._Reward[index + 1 ].Id ~= nil then
            if self._Reward[index + 1 ].Type == RewardType.Item then 
                CItemTipMan.ShowItemTips(self._Reward[index + 1 ].Id, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
            else
                local panelData = 
                {
                    _MoneyID =  self._Reward[index + 1 ].Id,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item ,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
            end
        elseif self._Reward[index + 1 ].Tid ~= nil then
            --CItemTipMan.ShowItemTips(self._Reward[index + 1 ].Tid, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
            print("SellCoolDownExpired", self._Reward.SellCoolDownExpired)
            CItemTipMan.ShowItemTips(self._Reward[index + 1 ], TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        elseif self._Reward[index + 1].IsTokenMoney ~= nil then 
            if not self._Reward[index + 1].IsTokenMoney then 
                CItemTipMan.ShowItemTips(self._Reward[index + 1 ].Data.Id, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
               
            else
                local panelData = 
            {
                _MoneyID =  self._Reward[index + 1 ].Data.Id,
                _TipPos = TipPosition.FIX_POSITION ,
                _TargetObj = item ,   
            }
            CItemTipMan.ShowMoneyTips(panelData)
            end
        else 
            warn("itemData have lost!!!")      
        end
    end
end



--邮件列表选中状态
def.method("number").OnCurrentSelectEmail = function(self,emailId)
    self._Reward = {}  
    GUI.SetText(self._LabSenderName,self._EmailData[emailId]._SenderName)   
    -- GUI.SetText(self._LabSenderName:GetComponent(ClassType.Text).text, self._EmailData[emailId]._SenderName)
    GUI.SetText(self._Lab_Dimension,self._EmailData[emailId]._Content)
    GUI.SetText(self._Lab_EmailTitle,self._EmailData[emailId]._Title)
    if not self._IsFirstOpen then 
        self._IsFirstOpen = true 
        self._Btn_Check:SetActive(true)
        self._LabSenderName:SetActive(true)
        self._Lab_Dimension:SetActive(true)
        self._Lab_SenderTips:SetActive(true)   
        self._Lab_EmailTitle:SetActive(true)
    end
    if #self._EmailData[emailId]._RewardItem ~= 0 then
        for i =1, #self._EmailData[emailId]._RewardItem do
            self._Reward[#self._Reward+1] = self._EmailData[emailId]._RewardItem[i]
        end
    elseif #self._EmailData[emailId]._Reward ~= 0 then  
        for i =1, #self._EmailData[emailId]._Reward do
            self._Reward[#self._Reward+1] = self._EmailData[emailId]._Reward[i]
        end
     elseif self._EmailData[emailId]._RewardId ~= 0 then 
        
        local rewards = GUITools.GetRewardListByLevel(self._EmailData[emailId]._RewardId, true, self._EmailData[emailId]._Level)
        for i = 1,#rewards do
            self._Reward[#self._Reward + 1] = rewards[i]
        end  
    end 
    self._List_Item:SetItemCount(#self._Reward)
    local Btn_CheckText = GUITools.GetChild(self._Btn_Check, 1)
    if self._EmailData[emailId]._IsHaveReward == true and self._EmailData[emailId]._IsDraw == false then  
        self:SetEnableBtn(true)        
        -- self._Btn_Check:SetActive(true)
    else
        -- self._List_Item:SetItemCount(0)
        self:SetEnableBtn(false)
    end    
end

-- 邮件领取和删除按钮禁止点击 & 置灰  Check/Clean
def.method("boolean").SetEnableBtn = function(self, CCEnable)
    if CCEnable then
        GameUtil.SetButtonInteractable(self._Btn_Check, CCEnable)
        self._Btn_Check:SetActive(CCEnable)
        -- GameUtil.SetButtonInteractable(self._Btn_Clean, false)
    else  
        self._Btn_Check:SetActive(CCEnable)      
    end    
end

def.override().OnHide = function(self)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Close_Mail, 0)
end

def.override().OnDestroy = function(self)
    --instance = nil --destroy
    self._List_Mail = nil
    self._LabSenderName = nil
    self._List_Item = nil
    self._Lab_Dimension = nil
    self._Lab_Nothing = nil
    self._Btn_Check = nil
    self._Lab_EmailTitle = nil
    self._Frame_NotingMail = nil
    self._Frame_LeftList = nil
    self._Frame_Right = nil
    self._Frame_Bottom = nil
    self._Btn_CheckAll = nil
    self._Btn_CleanALL = nil
    self._EmailData = {}   --邮件数据
    self._Reward = {}   --邮件奖励

    self._EmailCreateTime = 0
    self._IsSelect = false
    self._SelectIndex = 0
    self._Lab_SenderTips = nil
    self._SliderStore = nil 
    self._LabStore = nil 
    self._IsFirstOpen = false
    self._BeforeSelectItem = nil 
    self._BeforeSelectIndex = 0 
end

CPanelMail.Commit()
return CPanelMail