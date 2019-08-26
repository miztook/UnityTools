local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelLoading = Lplus.Extend(CPanelBase, "CPanelLoading")
local def = CPanelLoading.define

local instance = nil

def.field('userdata')._Lab_Tip = nil
def.field('userdata')._Pro_Loading = nil
def.field('userdata')._Img_BG = nil
def.field('userdata')._Label = nil
def.field('function')._OnHideCallback = nil

def.field("number")._DetectTimerID = 0
def.field("number")._NumCount = 0
def.field("boolean")._IsRealLoadFinish = false
def.field("table")._LoadingImgCfg = nil

def.static("=>",CPanelLoading).Instance = function ()
        if not instance then 
	        instance = CPanelLoading()
	        instance._PrefabPath = PATH.Panel_Loading
                instance._PanelCloseType = EnumDef.PanelCloseType.None
                instance._DestroyOnHide = false
	            instance._ForbidESC = true
                instance:SetupSortingParam()

                local ret, msg, result = pcall(dofile, "Configs/LoadingCfg.lua")
                if ret then
		        instance._LoadingImgCfg = result 
	        else
		        warn(msg)
	        end
	        --print("Instance",debug.traceback())
	end
        return instance
end

--记录调用的地方
--game 321 373
--S2CBriefUserInfo

def.override().OnCreate = function(self)
    self._Lab_Tip = self:GetUIObject('Lab_Tip')
    local sliderObj = self:GetUIObject('Pro_Loading')
    if sliderObj ~= nil then
        self._Pro_Loading = sliderObj:GetComponent(ClassType.Slider)
    end
    self._Label = self:GetUIObject('Label')
    self._Img_BG = self:GetUIObject('Img_BG')

    self._IsRealLoadFinish = false
end

def.override('dynamic').OnData = function(self, data)
    GameUtil.OnLoadingShow(true)
    game._IsPanelLoadingShow = not game:IsInBeginnerDungeon()       --新手副本认为Loading不显示，特殊逻辑
    game:CheckProtcolPaused()

	self._NumCount = 0
    self._IsRealLoadFinish = false
    if self._DetectTimerID > 0 then
        _G.RemoveGlobalTimer(self._DetectTimerID)
    end
    local waitTime = 0
    self._DetectTimerID = _G.AddGlobalTimer(0.2, false, function()
                    self:NumCountAdd()
                    self:UpdateLoadInfo()
                    if self._NumCount >= 100 then
                        waitTime = waitTime + 0.1
                    end
                    if waitTime >= 1 then
                        -- 希望玩家在看完CG后再进入大世界，新手本开场CG由服务器行为树控制
                        -- 客户端无法挑选协议处理，故加此特殊逻辑；加载完后不关闭Loading，直到CG开始
                        -- added by  lijian
                        if not game:IsInBeginnerDungeon() then
                            game._GUIMan:CloseByScript(self)
                        else
                            _G.RemoveGlobalTimer(self._DetectTimerID)
                            self._DetectTimerID = 0
                        end
                        --game._NetMan:SetProtocolPaused(false)
                    end
                end)
    math.random(1, 100) -- 第一次使用随机函数会永远都是1，先调一次

    self:UpdateLogoBG(data) 
    self:UpdateLoadInfo()
end

def.method("function").AttemptCloseLoading = function(self, cb)
    self._IsRealLoadFinish = true
    self._OnHideCallback = cb

    --如果这时还没显示, 直接关闭
    if not self:IsShow() then
        game._GUIMan:CloseByScript(self)
        --game._NetMan:SetProtocolPaused(false)
    end
end

def.method().NumCountAdd = function(self)
	self._NumCount = self._NumCount + math.random(4, 10)
    if not self._IsRealLoadFinish then
        self._NumCount = math.clamp(self._NumCount, 0, 95)
    end
end

def.method('table').UpdateLogoBG = function(self,data)
    if data == nil then return end

    --text
    local cfg = self._LoadingImgCfg.MapLogoImagePath[data.BGResPathId]
    local path = ""
    local tiptext = ""
    if cfg == nil then  -- 随机一张
        local index = math.random(1, #self._LoadingImgCfg.MapLogoImagePath.default)
        path = self._LoadingImgCfg.MapLogoImagePath.default[index]

        local index = math.random(1, #self._LoadingImgCfg.defaultTips)
        local id = self._LoadingImgCfg.defaultTips[index]
        tiptext = StringTable.Get(id)

    elseif type(cfg) == "string" then
        path = tostring(cfg)
        if path == "" then  -- 随机一张
            local index = math.random(1, #self._LoadingImgCfg.MapLogoImagePath.default)
            path = self._LoadingImgCfg.MapLogoImagePath.default[index]
        end

        local index = math.random(1, #self._LoadingImgCfg.defaultTips)
        local id = self._LoadingImgCfg.defaultTips[index]
        tiptext = StringTable.Get(id)

    elseif type(cfg) == "table" then
        path = cfg[1]
        local tips = cfg[2]

        local index = math.random(1, #tips)
        local id = tips[index]
        tiptext = StringTable.Get(id)
    end
    GUITools.SetSprite(self._Img_BG, path)
    GUI.SetText( self._Lab_Tip, tiptext )
end

def.method().UpdateLoadInfo = function(self)
    if not IsNil(self._Panel) then
        local num = self._NumCount 
        if self._Pro_Loading then
            self._Pro_Loading.value = num / 100
        end

        if self._Label then
            num = math.clamp(num, 0, 100)
            GUI.SetText(self._Label, tostring(math.floor(num)) .. "%" )
        end
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    if self._DetectTimerID > 0 then
        _G.RemoveGlobalTimer(self._DetectTimerID)
        self._DetectTimerID = 0
    end

    GUITools.CleanSprite(self._Img_BG)
    
    if self._OnHideCallback ~= nil then
        self._OnHideCallback()
        self._OnHideCallback = nil
    end

    game._CGuideMan:TriggerDelayCallBack()
    GameUtil.OnLoadingShow(false)
    game._IsPanelLoadingShow = false
    game:CheckProtcolPaused()
end

def.override().OnDestroy = function(self)
    game._IsPanelLoadingShow = false
    game:CheckProtcolPaused()
    self._Lab_Tip = nil
    self._Pro_Loading = nil
    self._Img_BG = nil
    self._Label = nil
    self._LoadingImgCfg = nil
    instance = nil
end

-- 返回键
def.override("=>", "boolean").HandleEscapeKey = function(self)
        if self:IsOpen() then
                return true
        end
end

CPanelLoading.Commit()
return CPanelLoading