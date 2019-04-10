--[[-----------------------------------------
         进地图和区域提示
       			——by luee. 2017.4.14
 --------------------------------------------
]]
local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"
local CPanelEnterMapTips = Lplus.Extend(CPanelBase, "CPanelEnterMapTips")
local def = CPanelEnterMapTips.define
local EWorldType = require "PB.Template".Map.EWorldType
local EPkMode = require "PB.data".EPkMode
local MapBasicConfig = require "Data.MapBasicConfig"

def.field('userdata')._Img_Obj = nil
def.field('userdata')._ImgText = nil
def.field('userdata')._Text_Obj = nil
def.field('userdata')._Text = nil
def.field("userdata")._ImgRegionType = nil

def.field("number")._MapID = 0   	-- 地图数据
def.field("number")._RegionID = 0    -- 区域数据

local instance = nil
def.static('=>', CPanelEnterMapTips).Instance = function()
    -- body
    if not instance then
        instance = CPanelEnterMapTips()
        instance._PrefabPath = PATH.Panel_EnterMap_Tips
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._Img_Obj = self:GetUIObject("Frame_Map")
    if not IsNil(self._Img_Obj) then
        self._Img_Obj:SetActive(false)
    end

    self._Text_Obj = self:GetUIObject("Frame_Area")
    if not IsNil(self._Text_Obj) then
        self._Text_Obj:SetActive(false)
    end

    self._ImgText = self:GetUIObject("Lab_Map")
    self._Text = self:GetUIObject("Lab_Area")

    self._ImgRegionType = self:GetUIObject("Img_RegionType")
end

local function InitShow(iPanel, strImg, strLab, nType)
    if strImg ~= nil then
        if not IsNil(iPanel._Img_Obj) then
            iPanel._Img_Obj:SetActive(true)
            -- 特效要求不显示IMG。特效包含图片 2018.4.26 
            GUI.SetText(iPanel._ImgText, strImg)
            GameUtil.PlayUISfx(PATH.UIFX_ENTERWORLD, iPanel._Img_Obj, iPanel._Panel, -1)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Effect_EnterMap, 0)
            return true
        end
    elseif strLab ~= nil then
        if not IsNil(iPanel._Text_Obj) then
            iPanel._Text_Obj:SetActive(true)
            local textColor
            if nType == EPkMode.EPkMode_Peace then
                GUITools.SetGroupImg(iPanel._ImgRegionType, 0)
            elseif nType == EPkMode.EPkMode_Massacre or nType == EPkMode.EPkMode_Guild then
                GUITools.SetGroupImg(iPanel._ImgRegionType, 1)
            else
                GUITools.SetGroupImg(iPanel._ImgRegionType, 2)
            end

            GUI.SetText(iPanel._Text, strLab)
            -- GUITools.ChangeGradientBtmColor(iPanel._Text,textColor)
            return true
        end
    end

    return false
end

local function SetMapNameDataByID(iPanel, nMapID)
    --[[
	-- 不能加如此的判断，因为异步加载，提示信息和状态数据可能不一致
	-- 比如新手相位
	if game._CurMapType == EWorldType.Pharse then
		iPanel._Img_Obj:SetActive(false)
		return false
	end
	]]
    local worldData = CElementData.GetMapTemplate(nMapID)
    if worldData == nil then
        iPanel._Img_Obj:SetActive(false)
        return false
    end

    -- 防止TextDisplayName 没有数据，最少需要显示一个（地图名称，或者显示名称）
    local strTips = worldData.Name
    if worldData.TextDisplayName ~= nil and worldData.TextDisplayName ~= "" then
        strTips = worldData.TextDisplayName
    end
    return InitShow(iPanel, strTips, "", 0)
end

local function SetRegionNameDataByID(self, nRegionID)
    if game._CurWorld == nil then return false end
    local nMapID = game._CurWorld._WorldInfo.MapTid
    if not MapBasicConfig.IsShowRegionNameTips(nMapID, nRegionID) then
        --warn("not show " .. nRegionID)

        return false
    end

    local nSceneID = game._CurWorld._WorldInfo.SceneTid
    --local scendData = _G.MapBasicInfoTable[nSceneID]
    local scendData = MapBasicConfig.GetMapBasicConfigBySceneID(nSceneID)

    local nType = 0
    -- 默认
    if scendData ~= nil and scendData.Region ~= nil then
        for _, v in pairs(scendData.Region) do
            for j, w in pairs(v) do
                if j == nRegionID then
                    nType = w.PkMode
                    break
                end
            end
        end
    end

    local regionName = MapBasicConfig.GetRegionName(nMapID, nRegionID)

    return InitShow(self, nil, regionName, nType)
end

def.override("dynamic").OnData = function(self, data)
    self:ShowTips()
end

def.method().ShowTips = function(self)
    local failed

    if self._MapID ~= 0 then
        -- 进入地图
        if not SetMapNameDataByID(self, self._MapID) then
            self._MapID = 0
            -- self:DoTipFinishCB()
            failed = true
        else
            self._MapID = 0
            -- GUITools.DoAlpha(self._ImgText, 0.5, 2.5, Imgcallback)
        end
    end

    if self._RegionID ~= 0 then
        -- 进入区域
        if not SetRegionNameDataByID(self, self._RegionID) then
            self._RegionID = 0
            -- self:OnTipFinish()
            failed = true
        else
            self._RegionID = 0
            -- GUITools.DoAlpha(self._Text, 0.5, 2.5, Textcallback)
        end
    end

    if failed then
        self:DoTipFinishCB()
    end
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	--特例 不掉 CPanelBase.OnDOTComplete(self,go_name,dot_id)

    if go_name == "Lab_Map" then
        if not IsNil(self._Img_Obj) then
            self._Img_Obj:SetActive(false)
        end
    elseif go_name == "Img_RegionType" then
        if not IsNil(self._Text_Obj) then
            self._Text_Obj:SetActive(false)
        end
    end
    self:OnTipFinish(go_name)
end


def.field("number")._OnFinishType = 1

def.method("string").OnTipFinish = function(self, key)
    local test_key = false

    if self._OnFinishType==1 then
        test_key = (key=="Lab_Map")
    else
        test_key = (key=="Img_RegionType")
    end

    if test_key then
        self:DoTipFinishCB()
    end
end

def.method("table", "function").ShowEnterTips = function(self, data, on_finish)
    if data == nil then return end

    if data._type == 1 then
        -- 进入地图
        self._MapID = data._Id
    elseif data._type == 2 then
        -- 进入区域
        self._RegionID = data._RegionID
    end

    self:DoTipFinishCB()

    self._OnFinishType = data._type
    self._OnTipFinishCB = on_finish

    if self._Panel == nil then
        game._GUIMan:Open("CPanelEnterMapTips", nil)
        return
    end

    self:ShowTips()
end

-- Tip Queue
def.field("function")._OnTipFinishCB = nil

def.method().DoTipFinishCB = function(self)
    if self._OnTipFinishCB ~= nil then
        self._OnTipFinishCB()
        self._OnTipFinishCB = nil
    end
end

def.override("=>", "boolean").IsCountAsUI = function(self)
    return false
end

CPanelEnterMapTips.Commit()
return CPanelEnterMapTips
