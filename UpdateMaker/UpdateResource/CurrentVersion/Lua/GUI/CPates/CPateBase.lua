local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local bit = require "bit"
local EPkMode = require "PB.data".EPkMode

local CPateBase = Lplus.Class("CPateBase")
do
    local def = CPateBase.define

    local CONST_TEXTPOP_CACHE_AMOUNT = 50
    local CONST_TEXTPOP_CACHE_TIME = 30

    local _staticData = nil
    def.static("=>", "table").StaticData = function()
        if _staticData == nil then
            _staticData = { }
            -- _staticData._TopPateRoot = nil

            _staticData._PlayerPatePrefab = nil
            _staticData._NPCPatePrefab = nil
            _staticData._ItemPatePrefab = nil
            _staticData._TextPopPrefab = nil

            _staticData._PlayerPateCache = nil  --{ }
            _staticData._NPCPateCache = nil --{ }
            _staticData._ItemPateCache = nil    --{ }

            _staticData._PlayerPateGOCache = { }
            _staticData._NPCPateGOCache = { }
            _staticData._ItemPateGOCache = { }
            _staticData._TextPopCache = { }

            -- _staticData._AllCreated = {}
        end

        return _staticData
    end

    local function DeleteCache(cache, rate)
        if cache ~= nil then
            local n = (#cache) * rate
            while #cache > n do
                local tpt = table.remove(cache)
                if tpt ~= nil then
                    tpt:DestroyInternal()
                end
            end
        end
    end

    local function DeleteGOCache(cache, rate)
        if cache ~= nil then
            local n = (#cache) * rate
            while #cache > n do
                local tpt = table.remove(cache)
                if not IsNil(tpt) then
                    tpt:Destroy()
                end
            end
        end
    end

    local function TickCache(cache, dt)
        if cache ~= nil then
            for i = #cache, 1, -1 do
                local tpt = cache[i]
                if tpt ~= nil then
                    tpt._PoolTime = tpt._PoolTime - dt
                    if tpt._PoolTime < 0 then
                        table.remove(cache, i)
                        tpt:DestroyInternal()
                    end
                end
            end
        end
    end

    def.static("number").CleanCachesByRate = function(rate)
        if _staticData ~= nil then
            DeleteCache(_staticData._PlayerPateCache, rate)
            DeleteCache(_staticData._NPCPateCache, rate)
            DeleteCache(_staticData._ItemPateCache, rate)

            DeleteGOCache(_staticData._PlayerPateGOCache, rate)
            DeleteGOCache(_staticData._NPCPateGOCache, rate)
            DeleteGOCache(_staticData._ItemPateGOCache, rate)
            DeleteGOCache(_staticData._TextPopCache, rate)

            -- _staticData._PlayerTopPateCache = {}
            -- _staticData._NPCPateCache = {}
            -- _staticData._ItemTopCache = {}
            -- _staticData._TextPopCache = {}
        end
    end


    def.field(CEntity)._Owner = nil
    def.field("table")._UIObjectName2IdMap = nil
    def.field("boolean")._IsPooled = true

    def.field("boolean")._IsContentValid = false
    def.field("function")._OnCreateCB = nil
    def.field("boolean")._IsVisible = false
    def.field("boolean")._IsShown = false

    def.field("userdata")._PateObj = nil
    def.field("userdata")._FollowComponent = nil

    def.field('number')._TextPopTimerId = -1
    def.field('userdata')._Frame_ActionTip = nil
    def.field('userdata')._Frame_QuestTalk = nil
    def.field('userdata')._Go_QuestTalk = nil
    def.field('userdata')._Go_QuestTalkLab = nil

    def.field('number')._VOffset = 0
    def.field('table')._Data = nil

    def.static("boolean").ShowAll = function(show)
        if not IsNil(game._TopPateCanvas) then
            if show then
                game._TopPateCanvas.localScale = Vector3.one
            else
                game._TopPateCanvas.localScale = Vector3.zero
            end
        end
    end

    def.static("boolean").Setup = function(is_reloadPrefab)
        -- avoid unneccessary cleaning
        CPateBase.CleanCachesByRate(0)
        CPateBase.StaticData()

        if is_reloadPrefab then
            --warn("cpate reloadPrefab")
            
            -- 提前准备好资源
            local cb1 = function(res)
                if res ~= nil then
                    _staticData._NPCPatePrefab = res
                    GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
                else
                    warn("MonsterTopPate Load Failed! ", PATH.MonsterTopPate)
                end
            end
            GameUtil.AsyncLoadPanel(PATH.MonsterTopPate, cb1, false)

            local cb2 = function(res)
                if res ~= nil then
                    _staticData._ItemPatePrefab = res
                    GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
                else
                    warn("ItemTopPate Load Failed! ", PATH.ItemTopPate)
                end
            end
            GameUtil.AsyncLoadPanel(PATH.ItemTopPate, cb2, false)

            local cb3 = function(res)
                if res ~= nil then
                    _staticData._PlayerPatePrefab = res
                    GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
                else
                    warn("PlayerTopPate Load Failed! ", PATH.PlayerTopPate)
                end
            end
            GameUtil.AsyncLoadPanel(PATH.PlayerTopPate, cb3, false)

            local cb4 = function(res)
                if res ~= nil then
                    _staticData._TextPopPrefab = res
                    GameUtil.SetLayerRecursively(res, EnumDef.RenderLayer.TopPate)
                else
                    warn("TextPop Load Failed! ", PATH.TextPopPrefab)
                end
            end
            GameUtil.AsyncLoadPanel(PATH.TextPopPrefab, cb4, false)
        end
    end

    -- local NormalSize = Vector3.New(0.01, 0.01, 0.01)
    def.method("userdata", "number", "number").CreateObjectInternal = function(self, obj, offsetH, pix_scale)
        --warn("-----CreateObjectInternal")

        if IsNil(self._PateObj) then
            local tpt = nil
            local cache, limit, prefab = self:GetGoCache()
            if prefab == nil then
                warn("CPate Prefab is Nil!")
                return
            end

            while #cache > 0 do
                -- warn("pop cache "..tostring(cache).." # "..#cache)
                tpt = table.remove(cache)
                if not IsNil(tpt) then
                    -- warn("Reuse top "..tpt.name .." as "..obj.name)
                    break
                end
            end

            if not IsNil(tpt) then
                self._PateObj = tpt
            else
                self._PateObj = Object.Instantiate(prefab)
                self._PateObj:SetParent(game._TopPateCanvas, false)
                self._PateObj.localScale = Vector3.zero
            end

            --GameUtil.SetLayerRecursively(self._PateObj, EnumDef.RenderLayer.TopPate)
            self._PateObj.layer = EnumDef.RenderLayer.TopPate
            self._PateObj.name = obj.name
            self:UIFind()
            --warn("CreateInternal "..self._PateObj.name)
            self:AttachTarget(obj, offsetH)
            self:UIReset()

            --          if pix_scale > 1 then
            --              GameUtil.SetupWorldCanvas(self._PateObj, pix_scale)
            --          else
            --              GameUtil.SetupWorldCanvas(self._PateObj)
            --          end
        end
    end

    def.static("string", "table", "number", "=>", "table").CreateNewInternal = function(type_name, cache, limit)
        return require(type_name)()
    end

    def.static("table", "table", "number").PoolInternal = function(tpt, cache, limit)
        if not tpt._IsPooled then
            tpt:ReleaseTextPop()
            tpt:SetVisible(false)

            tpt._IsPooled = true
            tpt._IsContentValid = false

            -- pool object	
            if not IsNil(tpt._PateObj) then
                local cache_go, limit_go, prefab = tpt:GetGoCache()
                if #cache_go < limit_go then
                    tpt._PateObj.name = tpt._PateObj.name .. "(Pooled)"
                    --GameUtil.SetLayerRecursively(tpt._PateObj, EnumDef.RenderLayer.Invisible)
                    tpt._PateObj.layer = EnumDef.RenderLayer.Invisible

                    tpt._FollowComponent.FollowTarget = nil

                    table.insert(cache_go, tpt._PateObj)
                else
                    tpt._PateObj:Destroy()
                end
            end

            tpt._PateObj = nil
            tpt._FollowComponent = nil

            tpt._Frame_ActionTip = nil
            tpt._Frame_QuestTalk = nil

            tpt._OnCreateCB = nil
            tpt._UIObjectName2IdMap = nil

            tpt._Owner = nil
        end
    end

    def.virtual("=>", "table", "number", "userdata").GetGoCache = function(self)
        return nil, 0, nil
    end

    def.method("boolean").MarkAsValid = function(self, flag)
        self._IsContentValid = flag
    end

    def.method("string", "=>", "userdata").GetUIObject = function(self, name)
        local go = nil
        if self._UIObjectName2IdMap ~= nil and self._UIObjectName2IdMap[name] ~= nil then
            local id = self._UIObjectName2IdMap[name]
            go = GameUtil.GetPanelUIObjectByID(self._PateObj, id)
        else
            warn("this pate has no " .. name .. " cfg data or cfg data has error", debug.traceback())
        end

        return go
    end

    def.virtual().UIFind = function(self)
    end

    def.virtual().UIReset = function(self)
    end

    def.method("userdata", "number").AttachTarget = function(self, target, offsetH)
        if IsNil(target) then return end
        local follow = self._PateObj:GetComponent(ClassType.CHUDFollowTarget)
        if follow == nil then follow = self._PateObj:AddComponent(ClassType.CHUDFollowTarget) end
        follow.FollowTarget = target
        local model = self._Owner:GetCurModel()
        if model ~= nil and model:GetGameObject() ~= nil then
            local CNonPlayerCreature = require "Object.CNonPlayerCreature"
            if Lplus.is(self._Owner, CNonPlayerCreature) then
                -- local monsterData = CElementData.GetTemplate("Monster", self._Owner:GetTemplateId())
                follow:AdjustOffsetWithScale(model:GetGameObject(), offsetH, self._Owner._MonsterTemplate.BodyScale)
            else
                follow:AdjustOffset(model:GetGameObject(), offsetH)
            end
        end
        self._FollowComponent = follow
    end

    def.method("=>", "boolean").IsObjCreated = function(self)
        return not IsNil(self._PateObj)
    end

    def.method().CheckObject = function(self)
        if IsNil(self._Owner) then return end

        if not self._IsPooled and not self:IsObjCreated() then
            self:CreateObjectInternal(self._Owner._GameObject, self._VOffset, 1)

            if self._OnCreateCB ~= nil then
                self._OnCreateCB()
                self._OnCreateCB = nil
            end

            self:SyncDataToUI()
        end
    end

    def.method(CEntity, "function", "boolean").Init = function(self, obj, cb, visible)
        self._Owner = obj
        self._Data = { }
        self._IsPooled = false
        self._OnCreateCB = cb
        self._IsContentValid = self._IsContentValid or visible
        self:SetVisible(visible)
    end

    def.method("=>", "boolean").CanShow = function(self)
        return true
    end

    def.method("boolean").SetVisible = function(self, visible)
        self._IsVisible = visible
        local is_visible = self._IsContentValid and self._IsVisible and self:CanShow()
        if is_visible then
            self:CheckObject()
        end

        if not self._IsPooled and self:IsObjCreated() then
            if self._IsShown ~= is_visible then
                if self._FollowComponent then
                    self._FollowComponent.enabled = is_visible
                end
                if not is_visible then
                    self._PateObj.localScale = Vector3.zero
                end
                self._IsShown = is_visible
            end
        end
    end

    -- 血量更改
    def.virtual("number").OnHPChange = function(self, value)
    end
    --  能量条更改
    def.virtual("number").OnStaChange = function(self, value)
    end
    --  指示更改
    def.virtual("number").OnLogoChange = function(self, curType)
    end
    --  头衔更改
    def.virtual("boolean", "string").OnTitleNameChange = function(self, isShow, name)
    end
    --  名称更改
    def.virtual("boolean").UpdateName = function(self, isShow)
    end
    -- 设置名称
    def.virtual("string").SetName = function(self, name)
    end

    -- override this to show your things
    def.virtual().SyncDataToUI = function(self)
    end

    def.virtual("number").SetOffsetH = function(self, offsetH)
        self._VOffset = offsetH
    end

    def.method("=>", "table", "number").GetTextPopGoCache = function(self)
        local data = CPateBase.StaticData()
        return data._TextPopCache, CONST_TEXTPOP_CACHE_AMOUNT
    end

    def.method().CheckTextPopObj = function(self)
        self:CheckObject()

        if not self._IsPooled and self:IsObjCreated() then
            if self._Go_QuestTalk == nil then
                local tpt = nil
                local cache, limit = self:GetTextPopGoCache()

                local pop_root = self._Frame_QuestTalk
                while #cache > 0 do
                    tpt = table.remove(cache)
                    if not IsNil(tpt) then
                        break
                    end
                end
                if IsNil(tpt) then
                    local data = CPateBase.StaticData()
                    local prefab = data._TextPopPrefab

                    if prefab ~= nil then
                        tpt = Object.Instantiate(prefab)
                    else
                        warn("CPate QuestTalk Prefab is Nil!")
                    end
                end

                if tpt ~= nil then
                    tpt:SetParent(pop_root, false)
                    tpt.name = "QTalk"
                    self._Go_QuestTalk = tpt
                    --GameUtil.SetLayerRecursively(self._Go_QuestTalk, EnumDef.RenderLayer.TopPate)
                    self._Go_QuestTalk.layer = EnumDef.RenderLayer.TopPate
                    GUITools.SetUIActive(self._Go_QuestTalk, true)

                    local ui_tpl = self._Go_QuestTalk:GetComponent(ClassType.UITemplate)
                    if ui_tpl ~= nil then
                        self._Go_QuestTalkLab = ui_tpl:GetControl(0)
                    end
                end
            end
        end
    end

    def.method().ReleaseTextPop = function(self)
        if self._TextPopTimerId > 0 then
            _G.RemoveGlobalTimer(self._TextPopTimerId)
            self._TextPopTimerId = -1
        end

        if self._Go_QuestTalk ~= nil then
            if not IsNil(self._Go_QuestTalk) then
                local cache, limit = self:GetTextPopGoCache()
                if #cache < limit then
                    local data = CPateBase.StaticData()
                    self._Go_QuestTalk:SetParent(game._TopPateCanvas, false)
                    GUITools.SetUIActive(self._Go_QuestTalk, false)
                    self._Go_QuestTalk.name = "QTalk(Pooled)"
                    --GameUtil.SetLayerRecursively(self._Go_QuestTalk, EnumDef.RenderLayer.Invisible)
                    self._Go_QuestTalk.layer = EnumDef.RenderLayer.Invisible
                    table.insert(cache, self._Go_QuestTalk)
                else
                    self._Go_QuestTalk:Destroy()
                end
            end
            self._Go_QuestTalk = nil
            self._Go_QuestTalkLab = nil
        end
    end

    def.method("boolean", "string", "number").ChangePopText = function(self, isShow, text, time)
        if isShow then
            if self._Frame_QuestTalk == nil then return end
            self:CheckTextPopObj()

            if self._Go_QuestTalk ~= nil and self._Go_QuestTalkLab ~= nil then
                if self._TextPopTimerId > 0 then
                    _G.RemoveGlobalTimer(self._TextPopTimerId)
                    self._TextPopTimerId = -1
                end

                GUITools.SetUIActive(self._Frame_ActionTip, false)
                if time == 0 then
                    time = 3
                end

                GUI.SetText(self._Go_QuestTalkLab, text)

                local ctext = self._Go_QuestTalkLab:GetComponent(ClassType.Text)
                local line = ctext.preferredHeight / 21
                local width = 0
                if line > 1 then
                    width = GUITools.GetUiSize(self._Go_QuestTalkLab).Width
                else
                    width = ctext.preferredWidth
                end
                GUITools.UIResize(self._Go_QuestTalk, width + 20, ctext.preferredHeight + 35)
                GUITools.SetUIActive(self._Frame_QuestTalk, true)

                self._TextPopTimerId = _G.AddGlobalTimer(time, true, function()
                    GUITools.SetUIActive(self._Frame_QuestTalk, false)
                    GUITools.SetUIActive(self._Frame_ActionTip, true)

                    self:ReleaseTextPop()
                end )
            end
        else
            if self._TextPopTimerId > 0 then
                _G.RemoveGlobalTimer(self._TextPopTimerId)
                self._TextPopTimerId = -1
            end

            GUITools.SetUIActive(self._Frame_QuestTalk, false)
            GUITools.SetUIActive(self._Frame_ActionTip, true)
        end
    end

    def.method("number", "number", "=>", "number", "number").CalcHpGuard = function(self, hp, guard)
        local hp_rate = hp
        local gd_rate = 0

        if guard > 0 then
            local allRatio = hp + guard
            if allRatio <= 1 then
                -- 和小于总血量
                gd_rate = allRatio
            else
                -- 和大于总血量
                hp_rate = hp /(hp + guard)
                gd_rate = 1
            end
        end
        return hp_rate, gd_rate
    end

    def.virtual("=>", "boolean").IsMini = function(self)
        return false
    end

    CPateBase.Commit()
end

return CPateBase