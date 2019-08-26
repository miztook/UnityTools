local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = Lplus.ForwardDeclare("CQuest")
local QuestDef = require "Quest.QuestDef"
local CBtnAutoKill = Lplus.Class("CBtnAutoKill")
local def = CBtnAutoKill.define

def.field("userdata")._Btn = nil                    -- 通用按钮预设
def.field("userdata")._Lab_Num = nil                -- 次数
def.field("userdata")._Img_PKSet = nil              -- 图片
def.field("userdata")._Img_Warn = nil               -- 警告
def.field("userdata")._Img_RedPoint = nil           -- 红点

def.field("table")._Setting = nil                   -- 外部传过来的参数
def.field("table")._Tab_HangQuestTemps = nil                   -- 外部传过来的参数
local instance = nil
def.static("userdata", "dynamic", "=>", CBtnAutoKill).Instance = function(btn, setting)
    if instance == nil then
    	local new_btn = CBtnAutoKill()
    	new_btn._Btn = btn
        new_btn._Setting = setting or {}
        new_btn:Init()
    	new_btn:UpdateUI(true)
        instance = new_btn
    end
	return instance
end

local function OnQuestCommonEvent(sender, event)
    local self = instance
    self:UpdateUI(false)
end

local function OnEnterRegionEvent(sender, event)
    local self = instance
    self:UpdateUI(true)
end


def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler("QuestCommonEvent", OnQuestCommonEvent)
    CGame.EventManager:addHandler('NotifyEnterRegion', OnEnterRegionEvent)
    --CGame.EventManager:addHandler("PlayerGuidLevelUp", OnHostPlayerLevelChangeEvent)
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestCommonEvent)  
    CGame.EventManager:removeHandler('NotifyEnterRegion', OnEnterRegionEvent) 
    --CGame.EventManager:removeHandler('PlayerGuidLevelUp', OnHostPlayerLevelChangeEvent)  
end


def.method().Init = function(self)
	self:ListenToEvent()

    self._Lab_Num = self._Btn:FindChild("Lab_Num")
    self._Img_PKSet = self._Btn:FindChild("Img_PKSet")
    self._Img_Warn = self._Btn:FindChild("Img_Warn")
    self._Img_RedPoint = self._Btn:FindChild("Img_RedPoint")
    
    self._Tab_HangQuestTemps = {}
    local data_id_list = CElementData.GetAllHangQuest()
    for i = 1, #data_id_list do 
        local template = CElementData.GetTemplate("HangQuest", data_id_list[i])
        if self._Tab_HangQuestTemps[template.MapTId] == nil then
            self._Tab_HangQuestTemps[template.MapTId] = {}
        end
        local mapDataArray = self._Tab_HangQuestTemps[template.MapTId]
        mapDataArray[template.RegionId] = template
    end
    self._Lab_Num:SetActive(false)
    self._Img_Warn:SetActive(false)
    
    self:UpdateUI(true)
    --print_r(self._Tab_HangQuestTemps)
end

-- 更新按钮
def.method("boolean").UpdateUI = function(self,isInit)
    do
		-- 判断功能是否解锁
		local unlock = game._CFunctionMan:IsUnlockByFunTid(135)
		self._Btn:SetActive(unlock)
	end

    local questData = nil
    local HangQuestTemp = nil
    for i,v in ipairs( game._HostPlayer._CurrentRegionIds ) do
        local mapDataArray = self._Tab_HangQuestTemps[game._CurWorld._WorldInfo.SceneTid]
        --print("111111111===",i,v)
        if mapDataArray ~= nil then
            --print("222222222222===",mapDataArray)
            HangQuestTemp = mapDataArray[v]
            if HangQuestTemp ~= nil then
                questData = CQuest.Instance():GetInProgressQuestModel( HangQuestTemp.QuestId )
                --print("33333333333===",questData)
                if questData ~= nil then
                    break
                end
            end

        end
    end

    --红点
    local isShowRedPoint = false
    for k,v in pairs(CQuest.Instance()._InProgressQuestMap) do
        local quest_data = CElementData.GetQuestTemplate(v.Id)
        if quest_data.Type == QuestDef.QuestType.Hang then
            local objs = v:GetCurrentQuestObjetives()
            if #objs > 0 then
                if objs[1]:GetCurrentCount() >= objs[1]:GetNeedCount() then
                    isShowRedPoint = true
                    break
                end
            end       
        end
    end
    if self._Img_RedPoint ~= nil then
        self._Img_RedPoint:SetActive(isShowRedPoint)
    end

    if questData ~= nil then
        local objs = questData:GetCurrentQuestObjetives()
        local str = ""
        if #objs > 0 then
            if objs[1]:GetCurrentCount() >= objs[1]:GetNeedCount() then
                str = StringTable.Get(568)
                --GameUtil.PlayUISfx(PATH.UIFX_BaoXiangLingQu, self._Btn, self._Btn, -1)
                --self._Img_RedPoint:SetActive(true)
            else
                str = objs[1]:GetCurrentCount() .. '/' .. objs[1]:GetNeedCount()
                --GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, self._Btn)
                --self._Img_RedPoint:SetActive(false)
            end
        end
        --GUITools.SetGroupImg(self._Img_PKSet, 1)
        self._Lab_Num:SetActive(true)
        GUI.SetText(self._Lab_Num,str)

        if isInit then 
            GameUtil.PlayUISfx(PATH.UIFX_HOTTIME_BuffEnter, self._Btn, self._Btn, -1)
        end
        --是否危险
        self._Img_Warn:SetActive( game._HostPlayer._InfoData._Level < HangQuestTemp.MinLevel )
    else
        --GUITools.SetGroupImg(self._Img_PKSet, 0)
        self._Lab_Num:SetActive(false)
        GameUtil.StopUISfx(PATH.UIFX_HOTTIME_BuffEnter, self._Btn)

        self._Img_Warn:SetActive(false)
        --GameUtil.StopUISfx(PATH.UIFX_BaoXiangLingQu, self._Btn)
        --self._Img_RedPoint:SetActive(false)
    end
end


def.method().OnClick = function(self)
    game._GUIMan:Open("CPanelUIAutoKill",nil)
end

def.method().Destory = function (self)
    self:UnlistenToEvent()
    self._Btn = nil
    self._Setting = nil
    self._Lab_Num = nil
    self._Tab_HangQuestTemps = nil
    instance = nil
end

CBtnAutoKill.Commit()
return CBtnAutoKill