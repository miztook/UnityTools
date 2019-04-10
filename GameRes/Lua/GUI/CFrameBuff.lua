local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local BuffChangeEvent = require "Events.BuffChangeEvent"
local CEntity = require "Object.CEntity"
local EStateType = require "PB.Template".State.StateType

local CFrameBuff = Lplus.Class("CFrameBuff")
local def = CFrameBuff.define

def.field(CEntity)._TargetEntity = nil
def.field("table")._PanelObject = nil
def.field("table")._LastBuffInfo = nil
def.field("function")._OnBuffChangeEvent = nil
def.field("number")._LastBuffID = 0
def.field("number")._MaxBuffNumber = 5
def.field("number")._Direction = 0 

local BUFF_MAX_COUNT = 5
local LayoutDirection = 
                        {
                            NONE = 0,
                            FromLeftToRight = 1, 
                            FromRightToLeft = 2,
                        }
def.const("table")._LayoutDirection = LayoutDirection                               -- buff排布方向

def.static(CEntity, "table","number", "=>", CFrameBuff).new = function(entity, objectInfo,direction)
	local obj = CFrameBuff()
	obj._TargetEntity = entity  
    obj._PanelObject = objectInfo
    obj._Direction = direction
    obj:Init()

	return obj
end

def.method().Init = function(self)
	self:InitBuffState() 
    self._OnBuffChangeEvent = function(sender, event)
            if event._EntityID == self._TargetEntity._ID then
                self:UpdateBuffinfo(event._BuffID, event._IsAdd)
            end
        end

	CGame.EventManager:addHandler(BuffChangeEvent, self._OnBuffChangeEvent)
end

def.method().InitBuffState = function(self)
    self:Clear()
    local info = self._PanelObject
    local curBuffList = self._TargetEntity:GetTopShowStates(5)
    local curBuffCnt = #curBuffList

    self._LastBuffInfo = {}
 
    for i=1, BUFF_MAX_COUNT do
        local item = info._ListBuffGroup[i]
        local bShow = curBuffCnt >= i
        if bShow then
            self:UpdateBuffinfo(curBuffList[i]._ID, true)
        end
    end
end

local buffWidth = 35
def.method('number','=>','table').GetPositionByIndex = function(self, index)
    if self._Direction == LayoutDirection.FromLeftToRight then 
        local padding = 1*(index-1)
        local x = buffWidth*(index-1)+padding
        local position = Vector3.New(x,0,0)
        return position
    elseif self._Direction == LayoutDirection.FromRightToLeft then  
        local padding = 1*(index-1)
        local x = -buffWidth*(index-1)-padding
        local position = Vector3.New(x,0,0)
        return position
    end
end

def.method("number", "=>", "table").GetBuffItem = function(self, buffId)
    local info = self._PanelObject

    if self._LastBuffInfo[buffId] == nil then
        for i=1, BUFF_MAX_COUNT do
            local item = info._ListBuffGroup[i]

            if item.activeSelf == false then
                local buffItem = {}
                buffItem.Obj = item
                buffItem.Img_UpOrDown = buffItem.Obj:FindChild("Img_UpOrDown")
                buffItem.IsShow = true

                return buffItem
            end
        end
        self._LastBuffInfo[buffId] = self._LastBuffInfo[self._LastBuffID]
        self._LastBuffInfo[self._LastBuffID] = nil 
    end

    return self._LastBuffInfo[buffId]
end

def.method("number", "boolean").UpdateBuffinfo = function(self, buffID, bIsAdd)
    local info = self._PanelObject
    local curBuffList = self._TargetEntity:GetTopShowStates(5)

    local buffItem = self:GetBuffItem( buffID )

    if buffItem ~= nil then
        if bIsAdd then
            --增加
            local index = 1 
            buffItem.Obj:SetActive(true)
            self._LastBuffInfo[buffID] = buffItem

            for i,v in pairs(curBuffList) do
                local buffInfo = self._LastBuffInfo[v._ID]

                if buffInfo ~= nil then
                    buffInfo.Obj.localPosition = self:GetPositionByIndex(index)
                    index = index + 1
                    if v._ID == buffID then
                        GUITools.SetBuffIcon(buffInfo.Obj, v)
                        local bUpFlag = (v._StateType == EStateType.Buff or v._StateType == EStateType.DeBuff)
                        buffInfo.Img_UpOrDown:SetActive(bUpFlag)
                        if bUpFlag then
                            GUITools.SetGroupImg(buffInfo.Img_UpOrDown, v._StateType == EStateType.Buff and 1 or 0)
                        end
                    end
                    if i == self._MaxBuffNumber then 
                       self._LastBuffID = v._ID 
                    end
                end
            end
        else
            --删除
            local index = 1
            buffItem.Obj:SetActive(false)
            self._LastBuffInfo[buffID] = nil
            for i,v in pairs(curBuffList) do
                local buffInfo = self._LastBuffInfo[v._ID]
                if buffInfo == nil then
                    buffInfo = self:GetBuffItem(v._ID)
                    self._LastBuffInfo[v._ID] = buffInfo
                    buffInfo.Obj:SetActive(true)
                    GUITools.SetBuffIcon(buffInfo.Obj, v)
                    local bUpFlag = (v._StateType == EStateType.Buff or v._StateType == EStateType.DeBuff)
                    buffInfo.Img_UpOrDown:SetActive(bUpFlag)
                    if bUpFlag then
                        GUITools.SetGroupImg(buffInfo.Img_UpOrDown, v._StateType == EStateType.Buff and 1 or 0)
                    end
                end
                buffInfo.Obj.localPosition = self:GetPositionByIndex(index)
                index = index + 1
                if i == self._MaxBuffNumber then 
                   self._LastBuffID = v._ID 
                end
            end
        end    
    end
end

def.method().Clear = function(self)
    local info = self._PanelObject
    for i=1, BUFF_MAX_COUNT do
        local item = info._ListBuffGroup[i]

        item:SetActive(false)
    end
    self._LastBuffInfo = nil
end

def.method().Destory = function (self)
	CGame.EventManager:removeHandler(BuffChangeEvent, self._OnBuffChangeEvent)
    self._OnBuffChangeEvent = nil

	self:Clear()

    self._TargetEntity = nil
    self._PanelObject = nil
    self._LastBuffInfo = nil
end

CFrameBuff.Commit()
return CFrameBuff