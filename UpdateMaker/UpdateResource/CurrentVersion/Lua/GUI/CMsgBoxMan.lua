local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
-- msgbox的逻辑对象
local CMsgBox = Lplus.Class("CMsgBox")
do
	local def = CMsgBox.define

	def.field("number")._Priority = MsgBoxPriority.Normal
	def.field("number")._Type = MsgBoxType.MBBT_OKCANCEL

	def.field("string")._Title = ""
	def.field("string")._Message = ""
	def.field("table")._Sender = nil
	def.field("function")._ClickCall = nil
	def.field("function")._TimerCall = nil
	def.field("number")._LifeTime = 0 
	def.field("number")._TTL = 0
	def.field("string")._SpecTip = ""
    def.field("boolean")._NotShowAgain = false
	def.field("boolean")._IsNoBtn = false -- 是否没有按钮
	def.field("boolean")._IsNOCloseBtn = false	--是否显示关闭按钮
	def.field("number")._MsgboxID = 1
    def.field("string")._NotShowTag = ""
    def.field("number")._CostItemID = 0
    def.field("number")._CostItemCount = 0
    def.field("number")._CostMoneyID = 0
    def.field("number")._CostMoneyCount = 0
    def.field("number")._GainItemID = 0
    def.field("number")._GainItemCount = 0
    def.field("number")._GainMoneyID = 0
    def.field("number")._GainMoneyCount = 0
    def.field("number")._Star = 0               -- 如果是装备的话，装备评分

	local _uniqueID = 1
	local function uniqueId()
		local r = _uniqueID
		_uniqueID = _uniqueID + 1
		return r
	end

	def.static("number","=>",CMsgBox).new = function(priority)
		local obj = CMsgBox()
		obj._MsgboxID = uniqueId()
		obj._Priority = priority
		return obj
	end
end
CMsgBox.Commit()

-- msgbox的管理器
local instance = nil
local CMsgBoxMan = Lplus.Class("CMsgBoxMan")
do
	local def = CMsgBoxMan.define
	def.field("table")._BoxList = BlankTable
	def.field("table")._InactiveBox = BlankTable        -- 缓存不再显示的msgbox们
    def.field("table")._ChacheBoxData = nil
	def.field("boolean")._IsShowingNormalMsg = false    -- 是否正在显示普通类型的msgbox
	def.field("number")._CurPriority = MsgBoxPriority.None

	def.static("=>",CMsgBoxMan).Instance = function()
		if instance == nil then
		    instance = CMsgBoxMan()
		end
		return instance
	end

    local function ExistNotShowBox(self, notShowTag)
        if self._InactiveBox ~= nil and self._InactiveBox[notShowTag] ~= nil then
            return self._InactiveBox[notShowTag]
        end
        return nil
    end

	local function FindNextBox2Show(self)
		if #self._BoxList == 0 then
			--warn("Close msgBox")
            self._IsShowingNormalMsg = false
			self._CurPriority = MsgBoxPriority.None
			game._GUIMan:Close("CMsgBoxPanel")
		else
			local curMsgBox = self._BoxList[1]

			local msgBoxPanel = require "GUI.CMsgBoxPanel".Instance()
			if (self._CurPriority ~= curMsgBox._Priority) then
				self._CurPriority = curMsgBox._Priority
--				--if msgBoxPanel:IsOpen() then
--				--	msgBoxPanel:Close()
--				--end

				msgBoxPanel:SetPriority(curMsgBox._Priority)
			end

			local CMsgBoxPanel = require "GUI.CMsgBoxPanel"
            if CMsgBoxPanel.Instance()._IsLoading then
                self._ChacheBoxData = curMsgBox
            end
			game._GUIMan:Open("CMsgBoxPanel", curMsgBox)
            self._IsShowingNormalMsg = true
		end
	end

    local function MsgBoxSortFunc(item1, item2)
        if item1 == nil or item2 == nil then return false end
        return item1._Priority > item2._Priority
    end

	def.method("table","string","string","number","function","number","function","number","table").ShowMsgBox = function (self, sender, msg, title, msgtype, clickcall, ttl, timercall, priority, setting)
        if setting == nil then
            setting = {}
        end
        local notShowTag = setting[MsgBoxAddParam.NotShowTag]
        if notShowTag ~= nil and notShowTag ~= "" then
            local notShowBox = ExistNotShowBox(self,notShowTag)
            if notShowBox ~= nil then
                if notShowBox == 1 then
                    if clickcall ~= nil then
                        clickcall(true)
                    end
                else
                    if clickcall ~= nil then
                        clickcall(false)
                    end
                end
                return
            end
        end
        local function NewBox()
            local box = CMsgBox.new(priority)
		    if msg then box._Message = msg end 
		    if title then box._Title = title end 
		    if msgtype then box._Type = msgtype end
		    box._Sender = sender
		    box._ClickCall = clickcall
		    box._TimerCall = timercall
		    box._LifeTime = ttl
		    box._TTL = ttl
		    box._SpecTip = setting[MsgBoxAddParam.SpecialStr] or ""
            box._CostItemID = setting[MsgBoxAddParam.CostItemID] or 0
            box._CostItemCount = setting[MsgBoxAddParam.CostItemCount] or 0
            box._CostMoneyID = setting[MsgBoxAddParam.CostMoneyID] or 0
            box._CostMoneyCount = setting[MsgBoxAddParam.CostMoneyCount] or 0
            box._GainItemID = setting[MsgBoxAddParam.GainItemID] or 0
            box._GainItemCount = setting[MsgBoxAddParam.GainItemCount] or 0
            box._GainMoneyID = setting[MsgBoxAddParam.GainMoneyID] or 0
            box._GainMoneyCount = setting[MsgBoxAddParam.GainMoneyCount] or 0
		    box._IsNoBtn = (bit.band(box._Type, MsgBoxType.MBBT_NONE) == MsgBoxType.MBBT_NONE)
		    box._IsNOCloseBtn = setting[MsgBoxAddParam.IsNOCloseBtn] ~= nil and setting[MsgBoxAddParam.IsNOCloseBtn]
            box._NotShowTag = setting[MsgBoxAddParam.NotShowTag] or ""
            box._Star = setting[MsgBoxAddParam.EquipItemStar] or -1
            return box
        end

        local box = NewBox()
		self._BoxList[#self._BoxList+1] = box
        table.sort(self._BoxList, MsgBoxSortFunc)

    	FindNextBox2Show(self)
	end

	def.method("number", "table", "number", "function", "number", "function", "number", "table").ShowSystemMsgBox = function(self, sysTid, sender, msgtype, clickcall, ttl, timercall, priority, setting)
		local template = CElementData.GetSystemNotifyTemplate(sysTid)
		local message = ""
        local title = ""
		if template == nil then
			message = "Unkownn message"
            title = "Unknow Title"
		else
			message = template.TextContent
            title = template.Title
		end
		
		self:ShowMsgBox(sender, message, title, msgtype, clickcall, ttl, timercall, priority, setting)
	end

    def.method("table", "number").AddNotShowAgainBox = function(self, box, sure)
        if box == nil then return end
        if box._NotShowTag and box._NotShowTag ~= "" then
            self._InactiveBox[box._NotShowTag] = sure
        end
    end

	def.method("number", "=>", "table", "number").FindBox = function(self, id)
		for k,v in pairs(self._BoxList) do
			if v._MsgboxID == id then
				return v,k
			end
		end
		return nil,0
	end

    def.method("=>", "number").GetMsgBoxPanelShowingCount = function(self)
       if self._IsShowingNormalMsg then
            return 1
       else
            return 0
       end
    end

    def.method("=>", "boolean").IsDisconnectShow = function(self)
        return self._CurPriority == MsgBoxPriority.Disconnect
    end

    def.method("=>", "number").GetMsgListCount = function(self)
        return #self._BoxList
    end

    def.method("=>", "table").GetChacheMsgData = function(self)
        return self._ChacheBoxData
    end

    def.method().ReSetChacheMsgData = function(self)
        self._ChacheBoxData = nil
    end

	def.method("number").RemoveBoxById = function(self,id)
		local _,pos = self:FindBox(id)
		if pos >0 then
			table.remove(self._BoxList, pos)
		end
		--warn("rm msgbox ", id, debug.traceback())
	end

	def.method().ToggleNext = function(self)
		FindNextBox2Show(self)
	end

	def.method().ClearAllBoxList = function(self)
		self._BoxList = {}
        self._IsShowingNormalMsg = false
        self._CurPriority = MsgBoxPriority.None
        self:ToggleNext()
		--warn("rm all ", debug.traceback())
	end

    def.method().ClearAllExceptDisconnect = function(self)
        local remove_table = {}
        -- 找到需要删除的ids
        for i,v in ipairs(self._BoxList) do
            if v._Priority ~= MsgBoxPriority.Disconnect then
                remove_table[#remove_table + 1] = v._MsgboxID
            end
        end
        -- 从后往前删除
        for i = #self._BoxList, 1, -1 do
            for k,v in ipairs(remove_table) do
                if self._BoxList[i]._MsgboxID == v then
                    table.remove(self._BoxList, i)
                end
            end
        end
        self._IsShowingNormalMsg = false
        self._CurPriority = MsgBoxPriority.None
        if #self._BoxList> 0 then
            local msgBox = require "GUI.CMsgBoxPanel".Instance()
            if self._BoxList[1] ~= msgBox._MsgBoxData then
                self:ToggleNext()
            end
        else
            self:ToggleNext()
        end
    end

    def.method().RemoveAllBoxesData = function(self)
        self:ClearAllBoxList()
        self._InactiveBox = {}
        self._ChacheBoxData = nil
    end

    def.method("number", "=>", "boolean").HandleEscapeKeyManually = function(self, layer_id)
--		if self._CurPriority ~= MsgBoxPriority.None then
--			local msgBox = require "GUI.CMsgBoxPanel".Instance()
--			msgBox:HandleEscapeKeyManually()
--			return true
--		end
--		return false

        local msgBox = require "GUI.CMsgBoxPanel".Instance()
        return msgBox:HandleEscapeKeyManually(layer_id)
	end

end

CMsgBoxMan.Commit()

return CMsgBoxMan