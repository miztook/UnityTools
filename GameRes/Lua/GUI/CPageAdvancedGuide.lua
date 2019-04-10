local CElementData          = require "Data.CElementData"
local Lplus                 = require "Lplus"
local CPageAdvancedGuide    = Lplus.Class("CPageAdvancedGuide")
local def                   = CPageAdvancedGuide.define
local CGame                 = Lplus.ForwardDeclare("CGame")

def.const("number").MaxAdvancedBtnCount     = 10    

def.field("number")._CurrentPageIndex       = 0             -- 当前页面    

def.field("userdata")._Content 		        = nil			-- Page节点
def.field("userdata")._PageBack 		    = nil			-- 上一页
def.field("userdata")._PageForward 		    = nil			-- 下一页
def.field("userdata")._PageTitle 		    = nil			-- 标题 第几章
def.field("userdata")._ParentGO             = nil           -- 父节点GO
def.field("userdata")._PageWarn             = nil           -- 页码提示

def.field("table")._Parent                  = nil           -- Panel节点
def.field("table")._AdvancedBtnInfo 	    = nil			-- 成就按钮各种信息显示Cache
def.field("table")._AdvancedInfo            = nil           -- 成就相关信息

def.field("table")._FxCache                 = BlankTable           -- 特效记录
def.field("table")._FinishShowInfo          = BlankTable

def.static("table", "=>", CPageAdvancedGuide).new = function(root)
	local obj = CPageAdvancedGuide()
    obj._Parent = root
    obj._ParentGO = root._Panel
	obj:Init()
    return obj 
end

def.method("=>", "boolean").ShowRedPoint = function(self)
    return game._AcheivementMan:AdvancedInfoRedNodeIsShow()
end

def.method().Init = function(self)
    self._Content       = self._Parent._PageRoot:FindChild("PageAdvancedGuide/Content")
    local content       = self._Content
    self._PageBack      = content:FindChild("PageBack")
    self._PageForward   = content:FindChild("PageForward")
    self._PageTitle     = content:FindChild("Img_Title/PageTitle")
    self._PageWarn      = content:FindChild("Lab_Page")

    self._AdvancedBtnInfo = {}
    for i = 1, CPageAdvancedGuide.MaxAdvancedBtnCount do
        local advancedBtnInfo = {}
        local btn = content:FindChild("Btn"..i)
        advancedBtnInfo.BtnGO = btn
        advancedBtnInfo.Icon = btn:FindChild("Icon")
        advancedBtnInfo.Title = btn:FindChild("Title")
        advancedBtnInfo.TagOwned = btn:FindChild("TagOwned")
        advancedBtnInfo.Progress = btn:FindChild("Progress")
        advancedBtnInfo.ImgProgress = btn:FindChild("Img_Progress")
        advancedBtnInfo.QualityBG = btn:FindChild("Img_Mask/Img_QualityBG")
        advancedBtnInfo.NumText = btn:FindChild("Lab_Num")
        self._AdvancedBtnInfo[i] = advancedBtnInfo
    end
    self._CurrentPageIndex = -1
end

def.method().Show = function (self)
    self:UpdateAdvancedInfo()
    self:UpdateShow()
end

def.method("string").OnClick = function (self, id)
    if id == "PageBack" then
        self._CurrentPageIndex = self._CurrentPageIndex - 1 
        self:UpdateShow()
    elseif id == "PageForward" then
        self._CurrentPageIndex = self._CurrentPageIndex + 1 
        self:UpdateShow()
    elseif string.find(id, "Btn") then
        self:ClickAdvancedBtn(id)
    end
end

def.method("number", "number", "=>", "boolean").PreGuideComplite = function (self, start, index)
    for i = start, index do
        local advancedInfo = self._AdvancedInfo[index]
        if not advancedInfo.IsReceive then
            return false 
        end
    end
    return true
end

def.method("string").ClickAdvancedBtn = function (self, id)
    local s, e = string.find( id, "Btn" )
    if s and e then 
        local sI = string.sub( id, e + 1, -1 )
        local start = (self._CurrentPageIndex - 1) * CPageAdvancedGuide.MaxAdvancedBtnCount
        local index = start + tonumber(sI)
        
        local advancedInfo = self._AdvancedInfo[index]
        local preGuideComplite = self:PreGuideComplite(1, index - 1)
        if advancedInfo.isFinish and not advancedInfo.IsReceive and preGuideComplite then
            game._AcheivementMan: SendC2SReceiveReward(advancedInfo.Tid, false)
        elseif (not advancedInfo.isFinish) or (not preGuideComplite) then
            local item_data = GUITools.GetRewardList(advancedInfo.RewardId, true)
            item_data = item_data[1]
            if item_data.IsTokenMoney then
                local panelData = {
				    _MoneyID = item_data.Data.Id,
				    _TipPos = TipPosition.FIX_POSITION,
				    nil,
			    }
			    CItemTipMan.ShowMoneyTips(panelData)
            else
                CItemTipMan.ShowItemTips(item_data.Data.Id, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 nil, 
                                 TipPosition.FIX_POSITION)
            end
        end
    end
end

def.method().CheckFxShow = function (self)
    self._FinishShowInfo = {}
    for k, v in ipairs(self._AdvancedInfo) do
        if v.isFinish and not v.IsReceive then
            self._FinishShowInfo.finishIndex = k
            return
        elseif not v.isFinish then
            self._FinishShowInfo.doingIndex = k
            return
        end
    end
end

def.method().UpdateAdvancedInfo = function(self)
     self._AdvancedInfo = game._AcheivementMan:GetAdvancedGuideInfo()
     if self._CurrentPageIndex == -1 then
        for k, v in ipairs(self._AdvancedInfo) do
            if not v.IsReceive then
                self._CurrentPageIndex = math.modf( k / (CPageAdvancedGuide.MaxAdvancedBtnCount + 1)) + 1
                break
            end
        end
     end
end

def.method().UpdateShow = function(self)
    self:CheckFxShow()
    for k, v in pairs (self._FxCache) do
        GameUtil.StopUISfx(k, v)
    end
    self._FxCache = {}
    GUI.SetText(self._PageTitle, StringTable.Get(self._CurrentPageIndex + 34102))
    self._PageBack:SetActive(self._CurrentPageIndex > 1) 
    local pageCount = math.modf((#self._AdvancedInfo) / CPageAdvancedGuide.MaxAdvancedBtnCount)
    self._PageForward:SetActive(self._CurrentPageIndex < pageCount)
    local startIndex = (self._CurrentPageIndex - 1) * CPageAdvancedGuide.MaxAdvancedBtnCount
    for i = 1, CPageAdvancedGuide.MaxAdvancedBtnCount do
        local index = startIndex + i
        local advancedInfo = self._AdvancedInfo[index]
        local btnInfo = self._AdvancedBtnInfo[i]
        btnInfo.BtnGO:SetActive(advancedInfo ~= nil)
        if advancedInfo then
            GUI.SetText(btnInfo.Title, advancedInfo.DisPlayName)

            local curValue = advancedInfo.CurValue
            local reachParm = advancedInfo.ReachParm
            GUI.SetText(btnInfo.Progress, curValue .. "/" .. reachParm)

            local item_data = GUITools.GetRewardList(advancedInfo.RewardId, true)
            item_data = item_data[1]
            if item_data.IsTokenMoney then
                local moneyTemplate = CElementData.GetMoneyTemplate(item_data.Data.Id)
                GUITools.SetGroupImg(btnInfo.QualityBG, moneyTemplate.Quality)
                GUITools.SetItemIcon(btnInfo.Icon, moneyTemplate.IconPath)
                GUI.SetText(btnInfo.NumText, tostring(item_data.Data.Count))
            else
                local itemTemplate = CElementData.GetItemTemplate(item_data.Data.Id)
                GUITools.SetGroupImg(btnInfo.QualityBG, itemTemplate.InitQuality)
                GUITools.SetItemIcon(btnInfo.Icon, itemTemplate.IconAtlasPath)
                GUI.SetText(btnInfo.NumText, tostring(item_data.Data.Count))
            end

            local isReceive = advancedInfo.IsReceive
            btnInfo.ImgProgress:SetActive(true)
            btnInfo.TagOwned:SetActive(isReceive)
            local a = 255
            if isReceive then
                a = 127
            else
                local imgProgress = btnInfo.ImgProgress:GetComponent(ClassType.Image)
                GUITools.SetImageProgress(imgProgress, curValue / reachParm)
            end

            GUI.SetAlpha(btnInfo.ImgProgress, a)
            GUI.SetAlpha(btnInfo.Title, a)
            GUI.SetAlpha(btnInfo.BtnGO:FindChild("Img_Bg/Image"), a)
            GUI.SetAlpha(btnInfo.Icon, a)
            GUI.SetAlpha(btnInfo.Progress, a)

            local finishIndex = self._FinishShowInfo.finishIndex
            if finishIndex and finishIndex == index then
                GameUtil.PlayUISfx(PATH.UI_AdvancedGuideFinish, btnInfo.BtnGO, btnInfo.BtnGO, -1)
                self._FxCache[PATH.UI_AdvancedGuideFinish] = btnInfo.BtnGO
            end
            local doingIndex = self._FinishShowInfo.doingIndex
            if doingIndex and doingIndex == index then
                GameUtil.PlayUISfx(PATH.UI_AdvancedGuideDoing, btnInfo.BtnGO, btnInfo.BtnGO, -1)
                local go = btnInfo.BtnGO:FindChild("FXObj")
                go.localScale = Vector3.New(1.094,1.094,1.094)
                self._FxCache[PATH.UI_AdvancedGuideDoing] = btnInfo.BtnGO
            end
        end
    end

    local pageWarnText = StringTable.Get(34102)
    pageWarnText = string.format(pageWarnText, self._CurrentPageIndex .. "/" .. pageCount)
    GUI.SetText(self._PageWarn, pageWarnText)
end

def.method('userdata', 'string', 'number').OnInitItem = function (self, item, id, index)
end

def.method("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
end

def.method().Hide = function (self)
    
end

def.method().Destroy = function (self)
    self._Content           = nil
    self._PageBack          = nil
    self._PageForward       = nil
    self._PageTitle         = nil
    self._AdvancedBtnInfo   = nil
    self._FinishShowInfo    = nil
    self._FxCache           = nil
end

CPageAdvancedGuide.Commit()
return CPageAdvancedGuide