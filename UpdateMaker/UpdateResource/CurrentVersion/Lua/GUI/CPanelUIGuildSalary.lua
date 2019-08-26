--
--公会工资
--
--【孟令康】
--
--2018年10月23日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CUIScene = require "GUI.CUIScene"

local CPanelUIGuildSalary = Lplus.Extend(CPanelBase, "CPanelUIGuildSalary")
local def = CPanelUIGuildSalary.define

def.field(CUIScene)._UIScene = nil
def.field("number")._ModelState = 0 --0 not loaded, 1, 2 opened
def.field("number")._GSTimerID = 0
def.field("userdata")._ImageChest = nil

local instance = nil
def.static("=>", CPanelUIGuildSalary).Instance = function()
	if not instance then
		instance = CPanelUIGuildSalary()
		instance._PrefabPath = PATH.UI_Guild_Salary
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
    self._ImageChest = self:GetUIObject("Img_Chest")
end

def.override("dynamic").OnData = function (self, data)
    self._ModelState = 0
--<<宝箱显示代码 
    if self._UIScene == nil then
        local cb = (function(b_ret)
            if instance ~= nil then
                instance._UIScene:SetVisible(not (instance._IsHidden or instance._IsSelfHidden))
                instance._UIScene:PlaySequence(0, "GABox_Stand", nil)
                instance._UIScene:PossessImage(self._ImageChest, 1)

                instance._ModelState = 1

            end
        end )

        self._UIScene = CUIScene.new(self)
        self._UIScene:Load(PATH.UI_Scene_Salary, cb)
    end
-->>宝箱
end

-- 可见发生改变
def.override("boolean").OnVisibleChange = function(self, is_show)
    if self._UIScene~=nil then
        self._UIScene:SetVisible(is_show)
    end
end

-- 当摧毁
def.override().OnDestroy = function(self)
    if (self._GSTimerID~=0) then
        _G.RemoveGlobalTimer(self._GSTimerID)
    end

    if self._UIScene ~= nil then
        self._UIScene:Destroy()
        self._UIScene = nil
    end
    instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Button_Draw" then
        if self._ModelState == 1 then

            local play_failed = true
            if self._UIScene ~= nil and self._UIScene:IsSceneReady() then
                play_failed = self._UIScene:PlaySequence(0, "GABox_open_c", nil) < 0
            end

            self._ModelState = 2

--            if play_failed then
--                cb()
--            end


            local function cb()
                --warn("cb")
                self:OnBtnDraw()  --debug off
                self._GSTimerID = 0
	        end

            if (self._GSTimerID~=0) then
                _G.RemoveGlobalTimer(self._GSTimerID)
            end
            self._GSTimerID = _G.AddGlobalTimer(1, true, cb);  --debug off

        --elseif self._ModelState == 2 then        --debug on
            --game._GUIMan:CloseByScript(self)        --debug on

        end
	end
end

def.method().OnBtnDraw = function(self)
	local protocol = (require "PB.net".C2SGuildDrawSalary)()
	PBHelper.Send(protocol)
end

def.method("table").ShowBtnDraw = function(self, data)
	local rewardList = GUITools.GetRewardList(data._RewardId, true)
	local msg = {}
	msg.Items = {}
	msg.Moneys = {}
	for i, v in ipairs(rewardList) do
		if v.IsTokenMoney then
			local count = #msg.Moneys + 1
			msg.Moneys[count] = {}
			msg.Moneys[count].MoneyId = v.Data.Id
			msg.Moneys[count].Count = v.Data.Count		
		else
			local count = #msg.Items + 1
			msg.Items[count] = {}
			msg.Items[count].Tid = v.Data.Id
			msg.Items[count].Count = v.Data.Count
		end
	end
	local panelData = {}
    panelData = 
    {
        IsFromRewardTemplate = false,
        ListItem = msg.Items,
        MoneyList = msg.Moneys,
    }
    game._GUIMan:Open("CPanelLottery", panelData)
    game._GUIMan:CloseByScript(self)
    game._HostPlayer._Guild._ShowSalary = false
end

CPanelUIGuildSalary.Commit()
return CPanelUIGuildSalary