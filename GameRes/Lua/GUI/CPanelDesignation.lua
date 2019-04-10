local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelDesignation = Lplus.Extend(CPanelBase, "CPanelDesignation")
local def = CPanelDesignation.define
local CGame = Lplus.ForwardDeclare("CGame")
-- local CUIModel = require "GUI.CUIModel"
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local PropertyInfoConfig = require "Data.PropertyInfoConfig" 

local CCommonBtn = require "GUI.CCommonBtn"
def.field(CCommonBtn)._CommonBtn = nil

def.field('userdata')._TabList_Menu  = nil --称号类型list
-- def.field("userdata")._LabTitleName  = nil --称号名称
def.field("userdata")._LabName 		 = nil --称号
-- def.field("userdata")._LabPlayerName = nil --玩家名字
def.field("userdata")._LabDescribe   = nil --称号描述
def.field("userdata")._LabTypeName   = nil --类型名称
def.field("userdata")._LabTime       = nil --时间
def.field("userdata")._TabProperty   = nil --属性列表
def.field("userdata")._Btn_On        = nil --装备
def.field("userdata")._Btn_Off       = nil --卸下
def.field("userdata")._LabTips       = nil --开启条件
def.field("userdata")._ImgTitleBg       = nil --称号品质框
def.field("userdata")._Btn_Title_TotalCombat       = nil

-- def.field("userdata")._ImgIcon1      = nil --成就图标1
-- def.field("userdata")._ImgIcon2      = nil --成就图标2
-- def.field("userdata")._ImgIcon3      = nil --成就图标3
-- def.field("userdata")._ImgIcon4      = nil --成就图标4
-- def.field("userdata")._ImgLock       = nil --未解锁

-- def.field('userdata')._Img_Role = nil
-- def.field(CUIModel)._Model4ImgRender1 = nil

def.field('number')._CurType = -1--当前打开的页签
def.field('number')._CurDesignationID = -1--当前装备的ID
def.field("number")._CurClickTID = 0 --当前选中的ID
def.field("number")._TimerID = 0 --称号倒计时的ID
def.field("table")._TableTalentID = nil --天赋ID

-- def.field("table")._Table_titleClickObj = nil--称号title控件
-- def.field("table")._Table_ChildClickObj = nil--二级菜单选择

def.field("table")._DesignationList = nil--称号，用作显示
def.field("boolean")._IsOpenList = false -- list是不是打开的


local instance = nil
def.static("=>",CPanelDesignation).Instance = function ()
	if not instance then
        instance = CPanelDesignation()
        instance._PrefabPath = PATH.Panel_Designation
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

	return instance
end

def.override().OnCreate = function(self)
	self._TabList_Menu = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)
	-- self._Img_Role = self:GetUIObject("Img_Role")

	-- self._LabTitleName  = self:GetUIObject("Lab_Title")
	self._LabName       = self:GetUIObject("Lab_ShowTitle")
	-- self._LabPlayerName = self:GetUIObject("Lab_Name")
	self._LabDescribe   = self:GetUIObject("Lab_Decribe")
	self._LabTypeName   = self:GetUIObject("Lab_Type")
	self._LabTime       = self:GetUIObject("Lab_Time")
	self._TabProperty  	= self:GetUIObject("PropertyList"):GetComponent(ClassType.GNewList)
	self._Btn_On        = self:GetUIObject("Btn_PutOn")
	self._Btn_Off       = self:GetUIObject("Btn_TakeOff")
	self._LabTips       = self:GetUIObject("Lab_Tips")
	self._Btn_Title_TotalCombat      = self:GetUIObject("Btn_Title_TotalCombat")
	self._ImgTitleBg 	= self:GetUIObject("Img_TitleBg")
	self._Btn_Title_TotalCombat:SetActive(false)
	-- self._ImgIcon1      = self:GetUIObject("Image2")
	-- self._ImgIcon2      = self:GetUIObject("Image1")
	-- self._ImgIcon3      = self:GetUIObject("Image1_1")
	-- self._ImgIcon4      = self:GetUIObject("Image2_2")
	-- self._ImgLock       = self:GetUIObject("Img_Lock")
	-- self._CommonBtn = CCommonBtn.new(self._Btn_On ,nil)
	-- self._CommonBtn = CCommonBtn.new(self._Btn_Off ,nil)
end


-- local function UpdateUIModel(panel)
--     if panel ~= nil and panel._Panel ~= nil then
--         local uiModel = panel._Model4ImgRender1
--         if uiModel ~= nil then
--             GUITools.HostUIModelUpdate(uiModel)
--         end
--     end
-- end

def.override("dynamic").OnData = function(self, data)
	-- self._Table_titleClickObj = {}
	-- self._Table_ChildClickObj = {}
	self._IsOpenList = false
	game._DesignationMan: SortTable() --打开界面做排序
	self._CurDesignationID = game._DesignationMan: GetCurDesignation()
	self._DesignationList = game._DesignationMan: GetAllDesignation()	
	if self._TabList_Menu ~= nil then
		self._TabList_Menu:SetItemCount(#self._DesignationList)	
	end

	local openID = self._CurDesignationID	--打开当前装备称号
	if data ~= nil then	--指定打开ID
		openID = data
	end

	local idex = 0
	local curType = 0
	curType,idex = self: GetTypeIdexByID(openID)
	if curType < 0 then
		curType = 1 --默认开启第一个
		idex = 1
	end

	if not IsNil(self._TabList_Menu) then
		self._TabList_Menu:SelectItem(curType - 1,idex - 1)
	end

	-- if self._Model4ImgRender1 == nil then
    --     self._Model4ImgRender1 = GUITools.CreateHostUIModel(self._Img_Role,  EnumDef.RenderLayer.UI, nil)
    --     self._Model4ImgRender1:AddLoadedCallback(function() 
    --         self._Model4ImgRender1:SetModelParam(self._PrefabPath, game._HostPlayer._InfoData._Prof)
    --     end)
    -- end	
    -- UpdateUIModel(self)

    -- if not IsNil(self._LabPlayerName) then
    -- 	GUI.SetText(self._LabPlayerName, game._HostPlayer._InfoData._Name)
    -- end
end


--通过成就ID，获取类型type和索引
def.method("number","=>","number","number").GetTypeIdexByID = function(self, nID)
	if self._DesignationList == nil or table.nums(self._DesignationList) <= 0 then return -1 end 

	for i,v in pairs(self._DesignationList) do
		if v ~= nil then
			for k,m in ipairs(v) do			
				if m._Data.Id == nID then
					return i,k
				end
			end
		end
	end

	return -1,-1
end

--清空称号list的选中状态
-- local ClearTitleObjState = function( ... )
-- 	if instance._Table_titleClickObj == nil or table.nums(instance._Table_titleClickObj) <= 0 then return end

-- 	for _,v in pairs(instance._Table_titleClickObj) do
-- 		if not IsNil(v) then
-- 			v: SetActive(false)
-- 		end
-- 	end
-- end

--清空二级菜单
-- local ClearChildObjState = function( ... )
-- 	if instance._Table_ChildClickObj == nil or table.nums(instance._Table_ChildClickObj) <= 0 then return end

-- 	for _,v in pairs(instance._Table_ChildClickObj) do
-- 		for _,m in pairs(v) do
-- 			if not IsNil(m) then
-- 				m : SetActive(false)
-- 			end
-- 		end
-- 	end
-- end

def.method("userdata","number").OnInitTabListDeep1 = function(self, item, index)
	local nType = index + 1
    if self._DesignationList == nil or table.nums(self._DesignationList) <= 0 then return end
	if self._DesignationList[nType] == nil or #self._DesignationList[nType] <= 0 then return end
    local nameText = item:FindChild("Lab_Text")   -- GUITools.GetChild(item, 1) 
	local nameStr = self._DesignationList[nType][1]._Data.TypeName
	GUI.SetText(nameText, nameStr)
	local isNeedRed = game._DesignationMan: NeedRedPointByType(nType)
	local imgRed = item:FindChild("Img_RedPoint")   -- GUITools.GetChild(item, 4)
	if not IsNil(imgRed) then
		imgRed: SetActive(isNeedRed)
	end 
	GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 0)
end

def.method("userdata","number","number").OnInitTabListDeep2 = function(self, item, mainIndex, index)
	local nType = mainIndex + 1
	local nIndex = index + 1
    if self._DesignationList == nil or table.nums(self._DesignationList) <= 0 then return end
	if self._DesignationList[nType] == nil or #self._DesignationList[nType] <= 0 then return end
   	-- if self._Table_ChildClickObj[nType] == nil then
	-- 	self._Table_ChildClickObj[nType] = {}
	-- end

    local nameText = item:FindChild("Lab_Text")  -- GUITools.GetChild(item, 1) 
	local nameStr = self._DesignationList[nType][nIndex]._Data.Name
	GUI.SetText(nameText, nameStr)
	-- local lightNameText = GUITools.GetChild(item, 3) 
	-- GUI.SetText(lightNameText, nameStr)
	-- self._Table_ChildClickObj[nType][nIndex] = item:FindChild("Img_D")   -- GUITools.GetChild(item,2)

	if self._DesignationList[nType][nIndex]._lock == 0 then
		item:FindChild("Img_Lock"):SetActive(true)
	else
		item:FindChild("Img_Lock"):SetActive(false)
	end	

	local imgRed = item:FindChild("Img_RedPoint")   -- GUITools.GetChild(item, 4)
	if not IsNil(imgRed) then
		local isNeedRed = game._DesignationMan:NeedRedPoint(self._DesignationList[nType][nIndex]._Data.Id)
		imgRed: SetActive(isNeedRed)
	end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
	if string.find(list.name, "TabList") then
		if sub_index == -1 then
			self:OnInitTabListDeep1(item, main_index)
		else
			self:OnInitTabListDeep2(item, main_index, sub_index)
		end
	end
end

--属性list面板显示
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if string.find(id, "PropertyList") then
		local talentData = CElementData.GetAttachedPropertyTemplate(self._TableTalentID[index + 1].AttrId)
		if talentData == nil then return end

		local labName = GUITools.GetChild(item, 0)
		if not IsNil(labName) then
			GUI.SetText(labName, talentData.TextDisplayName)
		end

		local labValue = GUITools.GetChild(item, 1)
		local valStr = nil
		if not IsNil(labValue) then
			local isRatio = PropertyInfoConfig.IsRatio(self._TableTalentID[index + 1].AttrId)
			if isRatio then
				-- 属于百分比属性
				local percent = fixFloat(self._TableTalentID[index + 1].AttrValue * 100)
				valStr = fixFloatStr(percent, 1) .. "%" -- 修正浮点数，保留小数点后一位
			else
				valStr = tostring(self._TableTalentID[index + 1].AttrValue)
			end
			GUI.SetText(labValue, valStr)
		end
	end
end

--显示具体某类成就列表
def.method("number").ShowDesignationByType = function(self, nType)
	if self._DesignationList == nil or table.nums(self._DesignationList) <= 0 then return end
	if self._DesignationList[nType] == nil or #self._DesignationList[nType] <= 0 then return end
	self._CurType = nType
	-- warn("aaaaaaaaaaa=========>>>", nType, #self._Table_titleClickObj)
	-- ClearTitleObjState()
	-- self._Table_titleClickObj[nType]: SetActive(true)
	
	if not IsNil(self._TabList_Menu) then
		self._TabList_Menu:OpenTab(#self._DesignationList[nType])
	end

	self:ShowClickDesignation(nType, 1)--默认选中第一个
end

def.method("number", "number").FreshTimeShow = function(self, nTime, nLimitTime)
	local time = (nTime - GameUtil.GetServerTime())/1000 	
	local strTime = ""
	if time < 0 then
		self: SetLockStateShow(nLimitTime)
		if self._TimerID ~= 0 then
    		_G.RemoveGlobalTimer(self._TimerID)
			self._TimerID  = 0
    	end
	else		
		local nDay = math.ceil(time / (3600 * 24))
		if nDay > 1 then
			strTime = string.format(StringTable.Get(703), nDay) 
		else 
			strTime = StringTable.Get(704)
		end
	end

	if not IsNil(self._LabTime)	 then   			
    	GUI.SetText(self._LabTime, strTime) 
    end 	
end

def.method("number").SetLockStateShow = function(self, nTime)
	if not IsNil(self._LabTips) then
    	self._LabTips: SetActive(true)
    end

    -- if not IsNil(self._ImgLock) then
    -- 	self._ImgLock: SetActive(true)
    -- end	

    if not IsNil(self._Btn_On) then
    	self._Btn_On: SetActive(false) 
    end

    if not IsNil(self._Btn_Off)then
    	self._Btn_Off: SetActive(false)
    end

    local strTime = ""
    if nTime ~= 0 then
    	strTime = string.format(StringTable.Get(703), nTime) 
    else
		strTime = StringTable.Get(705)
    end
    		
    if not IsNil(self._LabTime)	 then   			
    	GUI.SetText(self._LabTime, strTime) 
    end 
end

--称号Cell显示设置
def.method("number","number").ShowClickDesignation = function(self, nType, nIndex)
	if self._DesignationList == nil or table.nums(self._DesignationList) <= 0 then return end
	if self._DesignationList[self._CurType] == nil or #self._DesignationList[self._CurType]  <= 0 then return end
    local temData = self._DesignationList[self._CurType][nIndex]

    if temData == nil then 
		warn("Panel_Designation 数据错误!self._CurType："..self._CurType.."索引："..nIndex)
    return end
    -- ClearChildObjState()
    self._CurClickTID = temData._Data.Id

    if self._TimerID ~= 0 then
    	_G.RemoveGlobalTimer(self._TimerID)
		self._TimerID  = 0
    end

    if temData ~= nil then
    	local strIcon = "Assets/Outputs/"..temData._Data.IconPath..".png"
    	-- if not IsNil(self._ImgIcon1) then   			
    	-- 	self._ImgIcon1: SetActive(true)
    	-- 	GUITools.SetSprite(self._ImgIcon1, strIcon)
    	-- end

    	-- if not IsNil(self._ImgIcon2) then   			
    	-- 	self._ImgIcon2: SetActive(true)
    	-- 	GUITools.SetSprite(self._ImgIcon2, strIcon)
    	-- end

    	-- if not IsNil(self._ImgIcon3) then   			
    	-- 	self._ImgIcon2: SetActive(true)
    	-- 	GUITools.SetSprite(self._ImgIcon2, strIcon)
    	-- end

    	-- if not IsNil(self._ImgIcon4) then   			
    	-- 	self._ImgIcon4: SetActive(true)
    	-- 	GUITools.SetSprite(self._ImgIcon4, strIcon)
    	-- end

    	if not IsNil(self._LabDescribe) then
    		GUI.SetText(self._LabDescribe, temData._Data.DisplayName)
    	end

    	if not IsNil(self._LabTypeName)then
    		GUI.SetText(self._LabTypeName, temData._Data.TypeName) 
    	end	

    	if not IsNil(self._LabTips) then
    		GUI.SetText(self._LabTips, temData._Data.SrcDescript) 
    	end
		if not IsNil(self._ImgTitleBg) then
			GUITools.SetGroupImg(self._ImgTitleBg, temData._Data.Quality)
		end

    	local strName = "<color="..temData._Data.ColorRGB..">" ..temData._Data.Name.."</color>"
    	-- if not IsNil(self._LabTitleName) then
    	-- 	GUI.SetText(self._LabTitleName,strName )
    	-- end

    	if not IsNil(self._LabName) then
    		GUI.SetText(self._LabName,strName)
    	end	

    	--属性
    	self._TableTalentID = {}
    	for i_,v in ipairs(temData._Data.Attrs) do
    		if v ~= nil then				
    			self._TableTalentID[#self._TableTalentID + 1] = v  			
    		end
    	end
    	self._TabProperty:SetItemCount(#self._TableTalentID)

    	if temData._lock == 0 then
    		self: SetLockStateShow(temData._Time)	
    	else
    		if not IsNil(self._LabTips) then
    			self._LabTips: SetActive(false)
    		end
			
    		-- if not IsNil(self._ImgLock) then
    		-- 	self._ImgLock: SetActive(false)
    		-- end	
			self: SetBtn(temData._Data.Id ~= self._CurDesignationID)

			if temData._Time ~= 0 then
				local function callback( ... )
					self: FreshTimeShow(temData._Time, temData._Data.TimeLimit)
				end

				self._TimerID = _G.AddGlobalTimer(30, false, callback)--以天计时。不用太频繁
			else
				if not IsNil(self._LabTime)	 then   			
    				GUI.SetText(self._LabTime, StringTable.Get(705)) 
    			end 
			end
    	end

    	-- if self._Table_ChildClickObj[self._CurType] == nil then return end
    	-- if not IsNil(self._Table_ChildClickObj[self._CurType][nIndex]) then
    	-- 	self._Table_ChildClickObj[self._CurType][nIndex]: SetActive(true)	
    	-- end
    end
end


--点击Item,-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
	  if string.find(list.name, "TabList") then
    	if sub_index == -1 then
    		game._DesignationMan: SetTypeRedPointState(main_index + 1, false)
    		-- local clickImg = GUITools.GetChild(item, 5)
    		if self._CurType ~= main_index + 1 then
    			self._IsOpenList = true
				self: ShowDesignationByType(main_index + 1)
				GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 2)
    			-- GUITools.SetGroupImg(clickImg, 2)
                -- GUITools.SetNativeSize(clickImg)
    		else
    			if self._IsOpenList then
    				self._TabList_Menu:OpenTab(0)
					self._IsOpenList = false
					GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 0)
    				-- GUITools.SetGroupImg(clickImg, 1)
                    -- GUITools.SetNativeSize(clickImg)
    			else
					self: ShowDesignationByType(main_index + 1)
					GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 2)
    				self._IsOpenList = true
    				-- GUITools.SetGroupImg(clickImg, 2)
                    -- GUITools.SetNativeSize(clickImg)
    			end
    		end

    		local imgRed = item:FindChild("Img_RedPoint")   -- GUITools.GetChild(item, 4)
			if not IsNil(imgRed) then
				imgRed: SetActive(false)
			end 
			game._DesignationMan: ClearAllTypeRedPoint(self._CurType)
    	else
    		self: ShowClickDesignation(main_index + 1, sub_index + 1)
    		game._DesignationMan: SetRedPointState(self._CurClickTID, false)
    		local imgRed = item:FindChild("Img_RedPoint")   -- GUITools.GetChild(item, 4)
			if not IsNil(imgRed) then
				imgRed: SetActive(false)
			end 
    	end
    end
end


def.override("string").OnClick = function(self, id)
	if id == "Btn_Close" or id == "Btn_Exit" then
       game._GUIMan:CloseByScript(self)
	end

	if id == "Btn_PutOn" then
		game._DesignationMan: PutOnDesignationID(self._CurClickTID)
		GameUtil.PlayUISfx(PATH.UIFX_TITLE_Select, self._LabName, self._LabName, -1)
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Designation, 0)
    end

   if id == "Btn_TakeOff" then
		game._DesignationMan: TakeOffDesignation()
    end
end

--卸载称号
def.method("number").TakeOffDesignation = function(self,nID)
	self._CurDesignationID = 0
	local nType,nIdex = self:GetTypeIdexByID(nID)
	nIdex = nIdex - 1
	if nType ~= self._CurType or nIdex < 0 then return end
	self:SetBtn(true)
end

--装备称号
def.method("number").PutOnDesignation = function(self, nID)
	self._CurDesignationID = nID
	local nType,nIdex = self:GetTypeIdexByID(nID)
	nIdex = nIdex - 1
	if nType ~= self._CurType or nIdex < 0 then return end


	self:SetBtn(false)
end

--删除称号
def.method("number").RemoveDesignation = function(self, nID)
	if self._CurDesignationID ~= nID then return end --不是当前暂时的不用处理
	local nType,nIdex = self:GetTypeIdexByID(nID)
	self._CurDesignationID = 0
	if nType < 0 or nIdex < 0 then return end
	local DataTem = self._DesignationList[nType][nIdex]
	if DataTem == nil then return end
	self: SetLockStateShow(DataTem._Time)	
end

--设置单个cell的显示状态！
def.method("boolean").SetBtn = function(self,PutOn)
   	if not IsNil(self._Btn_Off) then
    	self._Btn_Off: SetActive(not PutOn) 
    end

    if not IsNil(self._Btn_On)then
    	self._Btn_On: SetActive(PutOn) 
    end
end

def.override().OnDestroy = function(self)
	--  if self._Model4ImgRender1 ~= nil  then
    --     self._Model4ImgRender1:Destroy()		
    --     self._Model4ImgRender1 = nil
    -- end

    self._DesignationList = nil
    self._CurDesignationID = -1
    self._CurClickTID = -1
    self._CurType = -1
    -- self._Table_titleClickObj = {}
 	-- self._Table_ChildClickObj = {}
    self._TableTalentID = {}

	self._TabList_Menu = nil
	-- self._LabTitleName = nil
	self._LabName = nil
	-- self._LabPlayerName = nil
	self._LabDescribe = nil
	self._LabTypeName = nil
	self._LabTime = nil
	self._TabProperty = nil
	self._Btn_On = nil
	self._Btn_Off = nil
	self._LabTips = nil
	-- self._ImgIcon1 = nil
	-- self._ImgIcon2 = nil
	-- self._ImgIcon3 = nil
	-- self._ImgIcon4 = nil
	-- self._ImgLock = nil
	-- self._Img_Role = nil
	self._IsOpenList = false

    if self._TimerID ~= 0 then
    	_G.RemoveGlobalTimer(self._TimerID)
		self._TimerID  = 0
	end
	
	if self._CommonBtn ~= nil then
		self._CommonBtn:Destroy()
		self._CommonBtn = nil
	end
end

CPanelDesignation.Commit()
return CPanelDesignation