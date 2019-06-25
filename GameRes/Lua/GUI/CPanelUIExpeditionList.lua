--[[-----------------------------------------
    	远征列表展示
      		 ——by luee. 2018.1.9
 --------------------------------------------
]]

local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIExpeditionList = Lplus.Extend(CPanelBase, 'CPanelUIExpeditionList')
local def = CPanelUIExpeditionList.define
local CElementData = require "Data.CElementData"
local GUnlimitedType = ClassType.GNewList
local ECHAPTERSTATE = require "PB.data".EExpeditionChapterState

def.field("userdata")._ListShowCell = nil    --远征展示
def.field("userdata")._ObjTime = nil    	 --远征重置时间
def.field("userdata")._LabTime = nil    	 --远征时间

--远征数据
def.field("table")._TableExpeditionInfo = nil

def.field("number")._ResetTime = 0 -- 重置时间 
def.field("number")._ResetTimerID = 0 --倒计时timerID

local instance = nil
def.static('=>', CPanelUIExpeditionList).Instance = function ()
	if not instance then
		instance = CPanelUIExpeditionList()
		instance._PrefabPath = PATH.UI_ExpeditionList
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._ListShowCell = self:GetUIObject("List_MenuType"):GetComponent(GUnlimitedType)
	self._ObjTime = self:GetUIObject("ResetTimeObj")
	self._LabTime = self:GetUIObject("Lab_ResetTime")
end

def.override("dynamic").OnData = function(self, data)
	if not IsNil(self._ObjTime) then
		self._ObjTime:SetActive(false)
	end
	self._TableExpeditionInfo = {}
	game._DungeonMan:SendAskExpeditionData()
end

def.override('string').OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
	end
end

--设置显示
def.method("userdata","number").InitShow = function(self, item, nIndex)
	if IsNil(item) then return end
	if self._TableExpeditionInfo == nil or #self._TableExpeditionInfo <= 0 then 
		warn("CPanelUIExpeditionList: Data is NIL")
		game._GUIMan:CloseByScript(self)
		return	
	end

	local data = self._TableExpeditionInfo[nIndex]
	if data == nil then 
		warn("CPanelUIExpeditionList：Index： ",nIndex,"数据错误!")
		return
	end
	local expeditionData = CElementData.GetTemplate("Expedition", data._ChapterID)
	if expeditionData == nil then
		warn("CPanelUIExpeditionList：ID： ",data._ChapterID,"数据错误!")
	return end

	self._TableExpeditionInfo[nIndex]._Name = expeditionData.Name
	
  	local imgDone = GUITools.GetChild(item, 4)
  	if not IsNil(imgDone) then
  		--imgDone:SetActive(data._State == ECHAPTERSTATE.EExpeditionChapterState_running)
  		imgDone: SetActive(false)
  	end	

  	--等级锁定
	local isLock = (data._State == ECHAPTERSTATE.EExpeditionChapterState_LevelLock) 
	--warn("data._State------------------>",data._State)

	local strTitle = string.format(StringTable.Get(23000), data._ChapterID)
	local strName = expeditionData.Name
	local strFight = GUITools.FormatNumber(expeditionData.RecommendedFightScore, false, 7)
	if isLock then
		local labLV = GUITools.GetChild(item, 10)	
		if not IsNil(labLV) then
			local strLvTips = string.format(StringTable.Get(137),expeditionData.UnLockLevel)
			GUI.SetText(labLV, strLvTips)
		end

		local greyFormat = "<color=#909AA8>%s</color>" -- 灰色
		strTitle = string.format(greyFormat, strTitle)
		strName = string.format(greyFormat, strName)
		strFight = string.format(greyFormat, strFight)
	end
	local labTitle = GUITools.GetChild(item,2)
	if not IsNil(labTitle) then
		GUI.SetText(labTitle, strTitle)
	end
	local labName = GUITools.GetChild(item, 1)
	if not IsNil(labName) then
		GUI.SetText(labName, strName)
	end
	local labFight = GUITools.GetChild(item, 3)
	if not IsNil(labFight) then
		GUI.SetText(labFight, strFight)
	end

	local imgMap = GUITools.GetChild(item, 0)
	if not IsNil(imgMap) then
		local strIcon = "Assets/Outputs/"..expeditionData.Icon..".png"
		-- if isLock then
		-- 	strIcon = "Assets/Outputs/"..expeditionData.Icon.."_Lock.png"
		-- end

    	imgMap: SetActive(true)
    	GUITools.SetSprite(imgMap, strIcon)
	end


	local ObjLock = GUITools.GetChild(item, 8)	
	if not IsNil(ObjLock) then
		ObjLock:SetActive(isLock)
	end

	--关卡锁定。同时只能闯关一个章节
	local imgClickMask = GUITools.GetChild(item, 9)
	if data._State == ECHAPTERSTATE.EExpeditionChapterState_lock then
		if not IsNil(imgClickMask) then
			imgClickMask:SetActive(true)
  		end

  		local labTips = GUITools.GetChild(item, 11)	
  		if not IsNil(labTips) then
  			GUI.SetText(labTips,StringTable.Get(23003))
  		end	
	else
		if not IsNil(imgClickMask) then
			imgClickMask:SetActive(false)
  		end
  	end	
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "List_MenuType") then
		self:InitShow(item, index + 1)
	end
end


def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if string.find(id, "List_MenuType") then
		local state = self._TableExpeditionInfo[index + 1]._State
	 	if state == ECHAPTERSTATE.EExpeditionChapterState_LevelLock then
			--等级不够不能挑战
			local expeditionData = CElementData.GetTemplate("Expedition", self._TableExpeditionInfo[index+1]._ChapterID)
			if expeditionData ~= nil then
				local str = string.format(StringTable.Get(23004), expeditionData.UnLockLevel)
				game._GUIMan:ShowTipText(str, false)
			end
	 		return
	 	end		
	 	if state == ECHAPTERSTATE.EExpeditionChapterState_lock then
	 		--同时只能挑战一个章节
	 		game._GUIMan:ShowTipText(StringTable.Get(23003), false)
	 		return
	 	end
		local data =
		{
			ChapterID = self._TableExpeditionInfo[index + 1]._ChapterID
		}
		game._GUIMan: Open("CPanelUIExpedition",data)
	end
end

--初始化显示
def.method().InitPanelShow = function(self)
	if(self._Panel == nil)then return end

	self:SetChapterData()
	if self._TableExpeditionInfo == nil or table.nums(self._TableExpeditionInfo) <= 0 then 
		game._GUIMan:CloseByScript(self)
		return	
	end

	if not IsNil(self._ListShowCell) then
		self._ListShowCell: SetItemCount(#self._TableExpeditionInfo)
	end

	--远征重置时间
	if self._ResetTime <= 0 then
		if not IsNil(self._ObjTime) then
			self._ObjTime:SetActive(false)
		end
	else
		if not IsNil(self._ObjTime) then
			self._ObjTime:SetActive(true)
		end

		self:ClearTimer()
		self._ResetTimerID = _G.AddGlobalTimer(1, false, function()
			if not IsNil(self._LabTime) then
				local strTime = GUITools.FormatTimeFromSecondsToZero(true, self._ResetTime)
				GUI.SetText(self._LabTime, strTime)
				self._ResetTime =  self._ResetTime - 1

				if self._ResetTime <= 0 then
					self:ClearTimer()
					if not IsNil(self._ObjTime) then
						self._ObjTime:SetActive(true)
					end
				end
			end
		end)
	end	
end

--清除计时器
def.method().ClearTimer = function(self)
	if self._ResetTimerID > 0 then
		_G.RemoveGlobalTimer(self._ResetTimerID)
		self._ResetTimerID = 0
	end	
end 

def.method().SetChapterData = function(self)
	self._ResetTime = game._DungeonMan:GetExpeditionResetTime()

	self._TableExpeditionInfo = {}
	local chapterDatas = game._DungeonMan:GetExpeditionChapterData()
	for _, chapterData in ipairs(chapterDatas) do
		local temp =
		{
			_ChapterID = chapterData.Id,
			_Name = "",
			_State = chapterData.chapterState,
			_dungeonDatas = {},
		}
		for _, dungeonData in ipairs(chapterData.dungeonDatas) do
			temp._dungeonDatas =
			{
				_DungeonTID = dungeonData.dungeonTId,
				_IsOpen = dungeonData.bOpen,
			}
		end

		table.insert(self._TableExpeditionInfo, temp)
	end
end

def.override().OnDestroy = function(self)
	self._TableExpeditionInfo = nil
	self:ClearTimer()

	self._ListShowCell = nil
	self._ObjTime = nil
	self._LabTime = nil

end

CPanelUIExpeditionList.Commit()
return CPanelUIExpeditionList