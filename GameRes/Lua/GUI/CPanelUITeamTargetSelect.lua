local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUITeamTargetSelect = Lplus.Extend(CPanelBase, "CPanelUITeamTargetSelect")
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"

local def = CPanelUITeamTargetSelect.define
local instance = nil

def.field(CTeamMan)._TeamMan = nil
def.field('userdata')._List_Left = nil
def.field('userdata')._List_Right = nil
def.field("table")._RoomDataList = nil
def.field("number")._LeftSelectIndex = 1
def.field("number")._RightSelectIndex = 0
def.field("userdata")._LeftSelectItem = nil
def.field("userdata")._RightSelectItem = nil

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

def.static("=>", CPanelUITeamTargetSelect).Instance = function()
	if not instance then
		instance = CPanelUITeamTargetSelect()
		instance._PrefabPath = PATH.UI_TeamTargetSelect
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._TeamMan = CTeamMan.Instance()
    self._List_Left = self:GetUIObject('List_Left'):GetComponent(ClassType.GNewList)
    self._List_Right = self:GetUIObject('List_Right'):GetComponent(ClassType.GNewList)

end

def.override("dynamic").OnData = function (self,data)
    -- 初始化房间数据状态
    self._RoomDataList = self._TeamMan:GetAllTeamRoomData()

    if data == nil then

    else

    end

    -- 刷新选中状态
    self:UpdateSelectState()

    CPanelBase.OnData(self,data)
end

-- 更新已选中状态，全部刷新
def.method().UpdateSelectState = function(self)
    local count = #self._RoomDataList
    self._List_Left:SetItemCount( count )
end

-- 计算选中位置
def.method().CalcSelectIndex = function(self)
    -- 计算右侧 分页签是否有内容,是否需要默认选中
end

-- 重置选中位置
def.method().ResetSelectInfo = function(self)
    self._LeftSelectIndex = 1
    self._RightSelectIndex = 0
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1

    if id == "List_Left" then
        local current_data = self._RoomDataList[idx]

        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")

        Img_Select:SetActive(self._LeftSelectIndex == idx)
        Img_UnableClick:SetActive( not current_data.Open )
        GUI.SetText(Lab_TargetName, current_data.ChannelOneName)

        if self._LeftSelectIndex == idx then
            self._LeftSelectItem = Img_Select
        end
    elseif id == "List_Right" then
        local current_data = self._RoomDataList[self._LeftSelectIndex]
        local current_smallData = current_data.ListData[idx]

        local Img_Select = item:FindChild("Img_Select")
        local Lab_TargetName = item:FindChild("Lab_TargetName")
        local Img_UnableClick = item:FindChild("Img_UnableClick")

        Img_Select:SetActive(self._RightSelectIndex == idx)
        Img_UnableClick:SetActive( not current_smallData.Open )
        GUI.SetText(Lab_TargetName, current_smallData.Data.ChannelTwoName)

        if self._RightSelectIndex == idx then
            self._RightSelectItem = Img_Select
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index + 1

    if id == "List_Left" then
        local Img_Select = item:FindChild("Img_Select")
        if self._LeftSelectItem ~= nil then
            self._LeftSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._LeftSelectIndex = idx
        self._LeftSelectItem = Img_Select

        -- 点击左侧页签 刷新分页签逻辑
        self:OnSelectLeft()

    elseif id == "List_Right" then
        local Img_Select = item:FindChild("Img_Select")
        if self._RightSelectItem ~= nil then
            self._RightSelectItem:SetActive(false)
        end
        Img_Select:SetActive(true)
        self._RightSelectIndex = idx
        self._RightSelectItem = Img_Select

        -- 点击右侧页签 
        self:OnSelectRight()
    end
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_OK" then
        self:OnClick_Btn_OK()
    elseif id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    end
end

def.method().OnSelectLeft = function(self)
    local current_data = self._RoomDataList[self._LeftSelectIndex]
    local sub_count = 0
    if current_data.ListData ~= nil then
        sub_count = #current_data.ListData
    end

    -- 右侧页签 如果有数据，则默认第一项
    self._RightSelectIndex = sub_count > 0 and 1 or 0
    self._List_Right:SetItemCount( sub_count )
end

def.method().OnSelectRight = function(self)
end

def.method().OnClick_Btn_OK = function(self)
end

def.override().OnDestroy = function (self)
    instance = nil
end

CPanelUITeamTargetSelect.Commit()
return CPanelUITeamTargetSelect