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
			self._CurPriority=MsgBoxPriority.None
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

			--warn("Open msgBox")
			game._GUIMan:Open("CMsgBoxPanel", curMsgBox)
            self._IsShowingNormalMsg = true
		end
	end

    local function MsgBoxSortFunc(item1, item2)
        if item1 == nil or item2 == nil then return false end
        return item1._Priority > item2._Priority
    end

	def.method("table","string","string","number","function","number","function","number","string","string").ShowMsgBox = function (self, sender, msg, title, msgtype, clickcall, ttl, timercall, priority, spectip, notShowTag)
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
		    box._SpecTip = spectip
		    box._IsNoBtn = (bit.band(box._Type, MsgBoxType.MBBT_NONE) == MsgBoxType.MBBT_NONE)
		    box._IsNOCloseBtn = (bit.band(box._Type, MsgBoxType.MBT_NOCLOSEBTN) == MsgBoxType.MBT_NOCLOSEBTN)
            box._NotShowTag = notShowTag
            return box
        end

        local box = NewBox()
		self._BoxList[#self._BoxList+1] = box
        table.sort(self._BoxList, MsgBoxSortFunc)
       --print("count ", #self._BoxList, self._BoxList[1]._Priority)
        
    	FindNextBox2Show(self)
	end

	def.method("number", "table", "string", "string", "number", "function", "number", "function", "number", "string", "string").ShowSystemMsgBox = function(self, sysTid, sender, msg, title, msgtype, clickcall, ttl, timercall, priority, spectip, notShowTag)
		local template = CElementData.GetSystemNotifyTemplate(sysTid)
		local message = msg
		if message == nil or message == "" then
			if template == nil then
				message = "Unkownn message"
			else
				message = template.TextContent
			end
		end
		if title == nil or title == "" then
			title = template.Name
		end
		
		if template and not template.IsShowCloseBtn then
			msgtype = bit.bor(msgtype, MsgBoxType.MBT_NOCLOSEBTN)
		end
		self:ShowMsgBox(sender, message, title, msgtype, clickcall, ttl, timercall, priority, spectip, notShowTag)
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

    def.method("=>", "number").GetMsgListCount = function(self)
        return #self._BoxList
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

	def.method().RemoveAll = function(self)
		self._BoxList = {}
        self._IsShowingNormalMsg = false
		--warn("rm all ", debug.traceback())
	end

    def.method().RemoveAllBoxes = function(self)
        self:RemoveAll()
        self._InactiveBox = {}
    end

    def.method("=>", "boolean").HandleEscapeKeyManually = function(self)
		if self._CurPriority ~= MsgBoxPriority.None then
			local msgBox = require "GUI.CMsgBoxPanel".Instance()
			msgBox:HandleEscapeKeyManually()
			return true
		end
		return false
	end

end

CMsgBoxMan.Commit()

return CMsgBoxMan