local Lplus = require "Lplus"
local CModel = require "Object.CModel"

local CUIScene = Lplus.Class("CUIScene")
local def = CUIScene.define

local _GetEnvEffectID = 0
-- is overriding ambient colors
def.static("=>","number").GetEnvEffectID = function()
    return _GetEnvEffectID
end

def.field(CModel)._Model = nil
def.field("table")._OwnerTable = nil

-- def.field('userdata')._ImgObj = nil 			-- 背景UI图片<GameObject>
def.field('userdata')._GUIScene = nil       -- <GUIScene>
def.field("string")._ModelAssetPath = ""		-- 主模型AssetPath

def.field("boolean")._IsDestroyed = false

-- def.field("table")._CallbackWhenInit = nil
def.field("table")._OnLoadedCallbacks = nil
def.field("function")._OnFinishCallback = nil
def.field("function")._OnEventCallback = nil

-- local _instCount = 0
-- def.static("=>", "number").InstCount = function()
--    return _instCount
-- end

-- def.field("number")._ShowType = 0 				-- All
-- def.field("number")._ModelHeight = 0
-- def.field("number")._RenderLayer = -1

---- 标记相关
-- def.field("boolean")._ModelLoaded = false
-- def.field("boolean")._ModelReleased = false

-- def.field("table").DialogCfg = nil
-- def.field("table").ImgRoleCfg = nil

---- UI Light and referrence count
-- local _UILightRefCount = 0
-- local _UILight = nil

local function OnFinish(self, go_name, anim_name)
    if self._OnFinishCallback ~= nil then
        print("OnFinish " .. go_name .. ", " .. anim_name)

        self._OnFinishCallback(self._OwnerTable, go_name, anim_name)
        self._OnFinishCallback = nil
    end
end

local function OnEvent(self, evt_name, args)
    print("OnEvent " .. evt_name)

    if self._OnEventCallback ~= nil then
        self._OnEventCallback(self._OwnerTable, evt_name)
    end
end

local function OnModelLoaded(self, b_ret)
    -- def.method("boolean").OnModelLoaded = function(self, b_ret)
    --print("OnModelLoaded " .. tostring(b_ret))

    if b_ret then
        local go = self._Model._GameObject
        if not IsNil(go) then
            go.name = "UIScene"
            go.localPosition = Vector3.New(3000, 0, 0)

            self._GUIScene = go:GetComponent(ClassType.GUIScene)
            -- self._GUIScene:Init(self._ImgObj)
            self._GUIScene:Init()
            self._GUIScene:SetLuaHandler(self, OnFinish, OnEvent)

            self:SetVisible(true)
            ----GameUtil.OpenSmithyUI(self._GUIScene.EnvSkyColor,self._GUIScene.EnvSkyColor,self._GUIScene.EnvSkyColor)

            

        else
            warn("GameObject lost ", self._ModelAssetPath)
        end
    else
        warn("Fail to load ui scene, asset path = ", self._ModelAssetPath)
    end

    if self._OnLoadedCallbacks then
        for i, v in ipairs(self._OnLoadedCallbacks) do
            v(self, b_ret)
        end
        self._OnLoadedCallbacks = nil
    end
end

-- Load model asset, dont call from outside
local function BeginLoading(self)
    -- def.method().BeginLoading = function(self)
    local asset_path = self._ModelAssetPath
    if asset_path ~= nil and asset_path ~= "" then
        local m = CModel.new()
        self._Model = m

        local function CallBack(b_ret)
            if b_ret then
                self._Model._GameObject.parent = nil
                OnModelLoaded(self, b_ret)
            end
        end

        m:Load(asset_path, CallBack)
    end
end

-- new
def.static("table", "=>", CUIScene).new = function(owner)
    local obj = CUIScene()
    obj._OwnerTable = owner
    return obj
end

-- new
def.method("string", "function").Load = function(self, asset_path, cb)

    if self._Model ~= nil then return end

    if IsNil(asset_path) or asset_path == "" then
        warn("CUIScene.New: asset_path is empty!")
        return
    end

    self._ModelAssetPath = asset_path
    self:AddLoadedCallback(cb)

    BeginLoading(self)

    -- _instCount = _instCount + 1

end

--  Destroy
def.method().Destroy = function(self)
    self._IsDestroyed = true

    self._OwnerTable = nil
    self._OnLoadedCallbacks = nil
    -- self._CallbackWhenInit = nil
    self._OnFinishCallback = nil
    self._OnEventCallback = nil

    if self._Model ~= nil then
        self._Model:Destroy()
        self._Model = nil
    end
    self._ModelAssetPath = ""

    -- self._ImgObj = nil
    self._GUIScene = nil

    self:SetVisible(false)

    -- _instCount = _instCount - 1
    --GameUtil.CloseSmithyUI()

end

-- 具体处理回调
def.method("function").AddLoadedCallback = function(self, cb)
    if cb ~= nil then
        if self:IsSceneReady() then
            cb(self, true)
        else
            if self._OnLoadedCallbacks == nil then
                self._OnLoadedCallbacks = { }
            end
            self._OnLoadedCallbacks[#self._OnLoadedCallbacks + 1] = cb
        end
    end
end

-- Model ready
def.method("=>", "boolean").IsSceneReady = function(self)
    --return(self._Model ~= nil and self._Model._Status == ModelStatus.NORMAL and(not IsNil(self._GUIScene)))
    return (not IsNil(self._GUIScene))
end

def.method("number", "string", "function", "=>", "number").PlaySequence = function(self, id, anim_name, cb)
    if not IsNil(self._GUIScene) then
        --if cb ~= nil then
            self._OnFinishCallback = cb
        --end
        return self._GUIScene:PlaySequence(id, anim_name)
    end
    return -1
end

def.method("function").SetEventCallback = function(self, cb)
    if cb ~= nil then
        self._OnEventCallback = cb
    end
end

def.method("boolean").SetVisible = function(self, is_show)
    if not IsNil(self._GUIScene) then
        self._GUIScene:SetVisible(is_show)

        local old_GetEnvEffectID=_GetEnvEffectID

		local envEffectID = self._GUIScene.EnvEffectID
        if is_show and envEffectID > 0 then
            _GetEnvEffectID = envEffectID
        else
            _GetEnvEffectID = 0
        end

        if old_GetEnvEffectID ~= _GetEnvEffectID then
            game._GUIMan._UIManCore:OpenEnvLighting()
        end

    end

--    if is_show and self._GUIScene ~= nil then
--        GameUtil.OpenSmithyUI(self._GUIScene.EnvSkyColor, self._GUIScene.EnvSkyColor, self._GUIScene.EnvSkyColor)
--    else
--        GameUtil.CloseSmithyUI()
--    end

end

def.method("userdata","number").PossessImage = function(self, image, alpha)
    if not IsNil(self._GUIScene) then
        self._GUIScene:PossessImage(image, alpha)
    end
end


CUIScene.Commit()
return CUIScene