local Lplus = require "Lplus"
local CPageAchievement = Lplus.Class("CPageAchievement")
local def = CPageAchievement.define

local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local EventType = require "PB.Template".Achievement.EventType
local CountType = require "PB.Template".Achievement.EParmType
local EParmType = require "PB.Template".ItemApproach.EParmType


def.field("table")._Parent = nil
def.field("userdata")._Panel = nil

def.field('userdata')._AcheiveType_List         = nil--成就类型list
def.field('userdata')._AcheiveTree_List         = nil--成就子类list
def.field('userdata')._AcheiveTree_Obj          = nil--成就子类Obj
def.field("userdata")._CellRoot_Obj             = nil--存放子类型的根节点
def.field("userdata")._NewGet_List              = nil--新获得的数据
def.field('userdata')._PanelEmpty               = nil--没有成就的展示面板
def.field("userdata")._PanelNewGet              = nil--新获得的展示面板
def.field("userdata")._PanelProgress            = nil--成就进度面板
def.field("userdata")._LabProgressTotal         = nil--成就总共Lab
def.field("userdata")._ImgProgress              = nil--进度显示图片
def.field("userdata")._RootGO                   = nil --成就一级节点
def.field("userdata")._NodeGO                   = nil --成就二级节点
def.field("userdata")._SelectedNode             = nil -- 当前选中的一级节点
def.field("userdata")._Btn_ReceiveAll           = nil -- 一键领取按钮

def.field("number")._OrigialOpenTid         = 0 --默认打开0
def.field('number')._CurType                = -1--当前打开的页签
def.field("number")._CurNode                = -1--当前选中的二级节点
def.field('number')._CurChoiceIndex         = -1 --当前选中的成就Index
def.field("number")._CurAchiTid             = 0     -- 当前领取的成就TID

def.field("table")._ListAchivement      = nil --成就列表
def.field("table")._ListParm            = nil --成就变量
def.field("table")._ListNewGet          = nil --新获得的数据
def.field("table")._CurChoiceData       = nil --当前选中的具体数据
def.field("boolean")._IsOpenTree        = false --树形分支是否打开
def.field("boolean")._IsOpenNode        = false --节点是否打开

def.field("number")._MAX_NEWGET_SHOW = 20 --最多显示20个新获取的


local EShowHideType = {
    EShowHideType_None 	= 0; 
	Show 				= 1; --始终显示
	Hide 				= 2; --始终隐藏
	FinishShow 			= 3; --完成后显示
}


local instance = nil
def.static("table", "userdata", "=>", CPageAchievement).new = function(parent, panel)
    if instance == nil then
        instance = CPageAchievement()
        instance._Parent = parent
        instance._Panel = panel
    end

    instance: Init()
    return instance
end

def.method().Init= function(self)
	self._AcheiveType_List = self._Parent:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)
	self._AcheiveTree_Obj = self._Parent:GetUIObject("TabList_ShowMenu")
	self._AcheiveTree_List = self._AcheiveTree_Obj :GetComponent(ClassType.GNewTabList)
    self._NewGet_List = self._Parent:GetUIObject("List_AchivementMenu"):GetComponent(ClassType.GNewList)
    self._CellRoot_Obj = self._Parent:GetUIObject("ShowMenuContent")

    self._PanelEmpty = self._Parent:GetUIObject("EmptyPanel")
    self._PanelProgress = self._Parent:GetUIObject("ProgressPanel")
    self._PanelNewGet = self._Parent:GetUIObject("NewGetPanel")
    self._Btn_ReceiveAll = self._Parent:GetUIObject("Btn_ReceiveAll")
    self._LabProgressTotal = self._Parent:GetUIObject("Lab_Total")
    self._ImgProgress = self._Parent:GetUIObject("Prs_Cur"):GetComponent(ClassType.Image)

    self._RootGO = self._Parent:GetUIObject("TabListContent")
    self._NodeGO = self._Panel:FindChild("Frame_L/TabList/Viewport/Content/SubContent")
end

def.method("dynamic").Show = function(self, data)
    --先清列表 ，防止动效闪烁 
    if self._AcheiveType_List ~= nil then
        self._AcheiveType_List: SetItemCount(0)
        --self._AcheiveType_List:SetSelection(0, 0)
    end
    game._AcheivementMan:SortAchieveTable()
    if data ~= nil then
        self._OrigialOpenTid = data._Tid
    else
        self._OrigialOpenTid = 0--默认不选中
    end 
    if not game._AcheivementMan._HasGotAchieveDatas then
        game._AcheivementMan:SendC2SAchieveSync()
    else
        self._Parent:FreshAchievementPage()
    end
end

def.method("number","=>","number","number").GetRootIndexAndNodeIndex = function(self, nTid)
    if self._ListAchivement == nil or #self._ListAchivement <= 0 then return 0 , 0 end

    for i,v in ipairs(self._ListAchivement) do
        if v._NodeList ~= nil then
            for l,k in ipairs(v._NodeList) do
                if k._CellList ~= nil then
                    for _,m in ipairs(k._CellList) do
                        if m._Tid == nTid then
                            return i, l
                        end
                    end
                end
            end
        end
    end

    warn("GetRootIndexAndNodeIndex: 查询失败:"..nTid)
    return 0, 0
end

def.method().SelectAchievementItems = function(self)
    self._ListAchivement = {}
    local all_achivements = game._AcheivementMan:GetAllAchievement()
    for _,v in pairs(all_achivements) do
        if self._ListAchivement[v._RootID + 1] == nil then
		    self._ListAchivement[v._RootID + 1] = 
		    {
			    _RootID = v._RootID,
			    _RootName = v._RootName,
			    _NodeList = {}
		    }
	    end
		for _,k in pairs(v._NodeList) do
            if self._ListAchivement[v._RootID + 1]._NodeList[k._NodeID] == nil then
                self._ListAchivement[v._RootID + 1]._NodeList[k._NodeID] = {
                    _NodeID = k._NodeID,
					_NodeName = k._NodeName,
					_CellList = {}
                }
            end
            local cell_list = self._ListAchivement[v._RootID + 1]._NodeList[k._NodeID]._CellList
			for _,m in pairs(k._CellList) do
                repeat
                    local achivement_temp = CElementData.GetTemplate("Achievement", m._Tid)
                    if achivement_temp == nil then break end
				    if achivement_temp.ShowHideType == EShowHideType.Hide then break end
                    if achivement_temp.ShowHideType == EShowHideType.Show then
                        cell_list[#cell_list + 1] = m
                    elseif achivement_temp.ShowHideType == EShowHideType.FinishShow then
                        if m._State._isFinish then
                            cell_list[#cell_list + 1] = m
                        end
                    end
                until true;
			end
		end
	end
end

local function SetNewGetList(self)
    self._ListNewGet = {}
    local totalCount, finishCount =  game._AcheivementMan:GetAchievementCountValue()
    --筛选出最新的获取
    if finishCount > 0 then
        for _,v in pairs(self._ListAchivement) do     
            if v._NodeList ~= nil and v._RootID ~= 0 then
                for _,m in pairs(v._NodeList) do
                    for _,k in pairs(m._CellList) do
                        if k._State._isFinish then
                            self._ListNewGet[#self._ListNewGet + 1] = k
                        end
                    end  
                end   
            end
        end
    end
    if #self._ListNewGet > 1 then
        local function SortNew(item1, item2)
            if item1._State._IsReceive ~= item2._State._IsReceive then
                return item2._State._IsReceive
            else
                return item1._FinishTime > item2._FinishTime
            end
        end

        table.sort(self._ListNewGet, SortNew)
    end
end

local function ShowNewGetPanel(self)
    SetNewGetList(self)
    local totalCount, finishCount =  game._AcheivementMan:GetAchievementCountValue()
    if finishCount > 0 then
        self._AcheiveTree_Obj: SetActive(false)
        self._PanelEmpty: SetActive(false)
        self._PanelProgress: SetActive(true)
        self._PanelNewGet: SetActive(true)
        local listCount = math.clamp(#self._ListNewGet,1,self._MAX_NEWGET_SHOW)
        self._NewGet_List:SetItemCount(listCount)
        GUI.SetText(self._LabProgressTotal, string.format(StringTable.Get(31202), finishCount, totalCount))
        self._ImgProgress.fillAmount = finishCount / totalCount
        if game._AcheivementMan:NeedShowRedPoint() then
            GUITools.SetBtnGray(self._Btn_ReceiveAll, false)
            GameUtil.SetButtonInteractable(self._Btn_ReceiveAll, true)
        else
            GUITools.SetBtnGray(self._Btn_ReceiveAll, true)
            GameUtil.SetButtonInteractable(self._Btn_ReceiveAll, false)
        end
        
    else
        self._AcheiveTree_Obj : SetActive(false)
        self._PanelEmpty: SetActive(true)
        self._PanelNewGet: SetActive(false)
        self._PanelProgress: SetActive(true)
        GUI.SetText(self._LabProgressTotal, string.format(StringTable.Get(31202), math.max(0, finishCount), totalCount))
    end
end

def.method().FreshPage = function(self)
    --self._ListAchivement = game._AcheivementMan:GetAllAchievement() --将数据进行筛选。显示满足条件的
    self:SelectAchievementItems()
    local totalCount, finishCount =  game._AcheivementMan:GetAchievementCountValue()
    if #self._ListAchivement > 0 then
        self._AcheiveType_List:SetItemCount(#self._ListAchivement)    
    end

    --默认不显示list，显示展示面板
    if self._OrigialOpenTid <= 0 then
        ShowNewGetPanel(self)
        self._AcheiveType_List:SelectItem(0,0)
    else
        self._AcheiveTree_Obj : SetActive(true)
        self._PanelEmpty: SetActive(false)
        self._PanelNewGet: SetActive(false)
        self._PanelProgress: SetActive(false)
        local curType, idex = self:GetRootIndexAndNodeIndex(self._OrigialOpenTid)
        self._AcheiveType_List:SelectItem(curType - 1,idex - 1)
        self._AcheiveType_List:PlayEffect()
    end
end

def.method("userdata","number").RootShowRedPoint = function(self, item, index)
    if self._ListAchivement == nil or #self._ListAchivement <= 0 then 
        warn("成就数据是空的")
    return end
    local imgRed = item: FindChild("Img_RedPoint")
    if self._ListAchivement[index]._RootID == 0 then
        imgRed:SetActive(false)
        return
    end
    local itemData = self._ListAchivement[index]._NodeList
    if itemData == nil or #itemData <= 0 then 
        warn("成就类型"..index.."是空的")
    return end

    for _,v in ipairs(itemData) do
        for _,m in ipairs(v._CellList) do
            if m._State._isFinish and not m._State._IsReceive then               
                if not IsNil(imgRed) then
                    imgRed: SetActive(true)
                    return
                end
            end
        end
    end

    if not IsNil(imgRed) then
        imgRed: SetActive(false)
    end
end

def.method("userdata","number","number").NodeShowRedPoint = function(self, item, nType, index)
    local itemData = self._ListAchivement[nType]._NodeList[index]
    if itemData == nil  or itemData._CellList == nil then return end

    local imgRed = item: FindChild("Img_RedPoint")
    if nType ~= 1 then
        for _,v in ipairs(itemData._CellList) do
            if v._State._isFinish and not v._State._IsReceive then               
                if not IsNil(imgRed) then
                    imgRed: SetActive(true)
                    return
                end
            end
        end
    end
    if not IsNil(imgRed) then
        imgRed: SetActive(false)
    end
end

def.method("userdata").AllReviewNodeShowRedPoint = function(self, item)
    local imgRed = item:FindChild("Img_RedPoint")
    if not IsNil(imgRed) then
        imgRed:SetActive(game._AcheivementMan:NeedShowRedPoint())
    end
end

--初始化成List
def.method("userdata", "userdata", "number", "number").ParentTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then--一级菜单
            local nType = main_index + 1
            if self._ListAchivement == nil or #self._ListAchivement <= 0 then 
                warn("成就数据是空的")
            return end
            if self._ListAchivement[nType] == nil or #self._ListAchivement[nType]._NodeList <= 0 then 
                warn("成就类型"..nType.."是空的")
            return end
            
            local nameText = item:FindChild("Lab_Text")
            local img_arrow = item:FindChild("Img_Arrow")
            local strName = self._ListAchivement[nType]._RootName
            if self._ListAchivement[nType]._RootID == 0 then
                img_arrow:SetActive(false)
            else
                img_arrow:SetActive(true)
                GUITools.SetGroupImg(img_arrow, 0)
            end
            GUI.SetText(nameText,strName)     
            GUITools.SetNativeSize(img_arrow)    
            self: RootShowRedPoint(item, nType)
            if main_index == 0 then
                self:AllReviewNodeShowRedPoint(item)
            end
        else
            local nType = main_index + 1
            local nameText = item:FindChild("Lab_Text")
            local strName = self._ListAchivement[nType]._NodeList[sub_index + 1]._NodeName
            GUI.SetText(nameText, strName)     
            self: NodeShowRedPoint(item, nType, sub_index + 1)
        end
    elseif list.name == "TabList_ShowMenu" then
        if sub_index == -1 then
            self: InitAchievementShow(item, main_index)  
        else
            self: InitConditionShow(item, sub_index)
        end
    end
end

--初始化成就显示
def.method("userdata","number").InitAchievementShow = function(self,item, Index)
    local nIndex = Index +  1
	if self._ListAchivement == nil or #self._ListAchivement <= 0 then return end
	if self._ListAchivement[self._CurType] == nil or #self._ListAchivement[self._CurType]._NodeList <= 0 then return end
    local cellData = self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[nIndex]
    if cellData == nil then return end

    local temData = CElementData.GetTemplate("Achievement",cellData._Tid)
    if temData ~= nil then
    	local img_Done =  GUITools.GetChild(item, 0)
       	local get_Btn = GUITools.GetChild(item, 1)
        local drump_btn = GUITools.GetChild(item, 14)
        local img_Click =  GUITools.GetChild(item, 2)
        if not IsNil(img_Click) then
            img_Click: SetActive(false) 
         end 
    
        local nameText = GUITools.GetChild(item, 11)
        GUI.SetText(nameText, temData.Name)
        local markText  = GUITools.GetChild(item, 4)
        GUI.SetText(markText, temData.Description)

        if temData.IconPath ~= nil then
        	GUITools.SetIcon(GUITools.GetChild(item, 5), temData.IconPath)
        end

		local countText = GUITools.GetChild(item, 3)
		
		local titleObj = GUITools.GetChild(item, 6)
		if titleObj ~= nil then
			titleObj: SetActive(false)
		end

		local rewardObj = GUITools.GetChild(item, 7)
		if rewardObj ~= nil then
			rewardObj: SetActive(false)
		end

		if temData.RewardId > 0 then			
			local reward_template = CElementData.GetRewardTemplate(temData.RewardId)
			if reward_template ~= nil then
				if reward_template.DesignationId ~= 0 then					
					local DesignationData = CElementData.GetTemplate("Designation",reward_template.DesignationId)
					if DesignationData ~= nil then
						titleObj: SetActive(true)
                        GUITools.SetGroupImg(titleObj, DesignationData.Quality)
						local titleLab = titleObj:FindChild("Lab_Title")
--						local rewardtext = string.format(StringTable.Get(517),DesignationData.Name)
						GUI.SetText(titleLab,DesignationData.Name)
					end					
				else
					rewardObj: SetActive(true)
					local items = GUITools.GetRewardList(temData.RewardId, true)
					-- local items = reward_template.ItemRelated.RewardItems
					for i=1,5 do
						local itemObj = rewardObj: FindChild("Img_ItemBG"..i)
						if itemObj ~= nil then
							if i <= #items then
								itemObj: SetActive(true)
                                local item_data = items[i]
                                local item_new = itemObj:FindChild("ItemIcon")
                                if item_data.IsTokenMoney then
                                    IconTools.InitTokenMoneyIcon(item_new, items[i].Data.Id, items[i].Data.Count)
                                else
                                    local setting = {
                                        [EItemIconTag.Number] = items[i].Data.Count,
                                    }
                                    IconTools.InitItemIconNew(item_new, items[i].Data.Id, setting, EItemLimitCheck.AllCheck)
                                end
							else
								itemObj: SetActive(false)
							end
						end			
					end
				end
			end
		end

		local fillFull = GUITools.GetChild(item, 8)
		local fillImg = GUITools.GetChild(item, 9)
        local ProgressBG = GUITools.GetChild(item, 12)
   
        local CurCount = 1
        local MaxCount = 1
        local isShowProgress = true
        if temData.EventId == EventType.FinishManual or temData.EventId == EventType.FinishAchieve then
            local strCells = string.split(temData.ReachParm, "*")
            if cellData._State._IsReceive or cellData._State._isFinish then
                CurCount = #strCells
            else
                CurCount = #cellData._State._CurValueList               
            end    
            MaxCount = #strCells
            isShowProgress = false
        else
            if cellData._State._IsReceive or cellData._State._isFinish then
                CurCount = temData.ReachParm
            else
                CurCount = cellData._State._CurValue  
            end

            if temData.ParmType == CountType.Contrast then
                MaxCount = 1
            else
                MaxCount = temData.ReachParm
            end
        end

        if not IsNil(ProgressBG) then
            ProgressBG: SetActive(isShowProgress)
        end

        local strCount = string.format(StringTable.Get(31202), CurCount, MaxCount)
        local btnName = GUITools.GetChild(item, 13)
        if not IsNil(countText)then
        	GUI.SetText(countText, strCount)
        end

        --已经领取，直接显示Img，不用任何处理
        if cellData._State._IsReceive then
            img_Done: SetActive(true)
            get_Btn:SetActive(false)
            drump_btn:SetActive(false)
        	if not IsNil(fillImg) then
        		fillImg:SetActive(false)
        	end   	

        	if not IsNil(fillFull)then
        		fillFull: SetActive(true)
        	end
        else
            img_Done: SetActive(false)
            if cellData._State._isFinish then
        	    get_Btn: SetActive(true)
                drump_btn:SetActive(false)
                --img_btn_fx:SetActive(true)
                GUITools.SetBtnFlash(get_Btn, true)
        	    GameUtil.SetButtonInteractable(get_Btn, true)
                GUITools.SetBtnGray(get_Btn, false)

        	    if not IsNil(fillImg) then
        		    fillImg:SetActive(false)
        	    end 

        	    if not IsNil(fillFull)then
        		    fillFull: SetActive(true)
        	    end

                if not IsNil(btnName) then
                    GUI.SetText(btnName, StringTable.Get(31201))
                end
            else
                if temData.ProceedToId > 0 then
                    get_Btn:SetActive(false)
                    drump_btn:SetActive(true)
                else
                    --正在完成的成就      
                    get_Btn: SetActive(true)
                    drump_btn:SetActive(false)
                    --img_btn_fx:SetActive(false)
                    GUITools.SetBtnFlash(get_Btn, false)
                    GameUtil.SetButtonInteractable(get_Btn, false)
                    GUITools.SetBtnGray(get_Btn, true)
                    if not IsNil(btnName) then
                       GUI.SetText(btnName, StringTable.Get(31200))
                    end
                end

                if not IsNil(fillImg) then
        	        fillImg:SetActive(true)
                    local imgAmout = fillImg:GetComponent(ClassType.Image)
        	        imgAmout.fillAmount = CurCount / MaxCount
                end 

                if not  IsNil(fillFull)then
        	        fillFull: SetActive(false)
                end
            end
        end
    end
end

def.method("table","number","=>","boolean").IsContain = function(self, list, value)
    for _,v in ipairs(list) do
        if v == value then 
            return true
        end
    end

    return false
end

--初始化显示附加条件
def.method("userdata","number").InitConditionShow = function(self, item, index)
    local nIndex = index + 1
    if self._ListParm == nil or #self._ListParm <= 0 then return end    
    if self._CurChoiceData == nil then return end

    local curConditionID = self._ListParm[nIndex]
    local labLockName = GUITools.GetChild(item, 0)
    local labOpenName = GUITools.GetChild(item, 1)

    local strName = ""
    local iData = CElementData.GetTemplate("Achievement",self._CurChoiceData._Tid)
    if iData.EventId == EventType.FinishManual then
        local template = CElementData.GetManualEntrieTemplate(curConditionID)
        strName = template.DisPlayName       
    elseif iData.EventId == EventType.FinishAchieve then
        strName = game._AcheivementMan:GetAchievementName(curConditionID)
    end
    GUI.SetText(labLockName, strName)
    GUI.SetText(labOpenName, strName)

    if self._CurChoiceData._State._isFinish then
        labLockName: SetActive(false)
        labOpenName: SetActive(true)
    else
        local isFinish = self:IsContain(self._CurChoiceData._State._CurValueList, curConditionID)
        labLockName: SetActive(not isFinish)
        labOpenName: SetActive(isFinish)
    end
end

--点击Item
def.method("userdata", "userdata", "number", "number").ParentTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            self:ShowNodeByType(item,main_index)
        else
            self:ShowAchievementByNode(sub_index)
        end  
    elseif list.name == "TabList_ShowMenu" then 
        if sub_index == -1 then
            self: ShowClickAchievementView(main_index)
        else

        end    
    end
end

def.method("userdata", "string", "string", "number").ParentSelectItemButton = function(self, item, id, id_btn, index)
    if string.find(id, "TabList_ShowMenu") and id_btn == "Btn_Get" then
        local idx = index + 1
        if self._ListAchivement == nil or #self._ListAchivement <= 0 then return end
        if self._ListAchivement[self._CurType] == nil or #self._ListAchivement[self._CurType]._NodeList <= 0 then return end
        local Tid = self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[idx]._Tid
        if Tid ~= nil then
            if Tid == self._CurAchiTid then return end
            game._AcheivementMan: SendC2SReceiveReward(Tid, true)
            self._CurAchiTid = Tid
        end
    elseif string.find(id, "TabList_ShowMenu") and id_btn == "Btn_Go" then
        local idx = index + 1
        if self._ListAchivement == nil or #self._ListAchivement <= 0 then return end
        if self._ListAchivement[self._CurType] == nil or #self._ListAchivement[self._CurType]._NodeList <= 0 then return end
        local achi_temp = CElementData.GetTemplate("Achievement", self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[idx]._Tid)
        if achi_temp == nil then warn("成就模板错误 Tid :",self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[idx]._Tid) return end
        game._AcheivementMan:DrumpToRightPanel(achi_temp.ProceedToId,nil)
    elseif string.find(id, "TabList_ShowMenu") and string.find(id_btn, "Img_ItemBG") then
        local index = index + 1
        local item_index = tonumber(string.sub(id_btn, -1))
        if not item_index then return end
        if self._ListAchivement == nil or #self._ListAchivement <= 0 then return end
        if self._ListAchivement[self._CurType] == nil or #self._ListAchivement[self._CurType]._NodeList <= 0 then return end
        local cellData = self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[index]
        local temData = CElementData.GetTemplate("Achievement",cellData._Tid)
        if temData.RewardId > 0 then			
			local items = GUITools.GetRewardList(temData.RewardId, true)
            local obj = item:FindChild("Frame_Item/"..id_btn)
            if items[item_index].IsTokenMoney then
                local panelData = {
				    _MoneyID = items[item_index].Data.Id,
				    _TipPos = TipPosition.FIX_POSITION,
				    _TargetObj = obj,
			    }
			    CItemTipMan.ShowMoneyTips(panelData)
            else
			    CItemTipMan.ShowItemTips(items[item_index].Data.Id, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 obj, 
                                 TipPosition.FIX_POSITION)
            end
		end
    elseif string.find(id, "List_AchivementMenu") and string.find(id_btn, "Img_ItemBG") then
        local index = index + 1
        local item_index = tonumber(string.sub(id_btn, -1))
        if not item_index then return end
        if self._ListNewGet == nil or #self._ListNewGet <= 0 then return end
        local cellData = self._ListNewGet[index]
        local temData = CElementData.GetTemplate("Achievement",cellData._Tid)
        if temData.RewardId > 0 then			
			local items = GUITools.GetRewardList(temData.RewardId, true)
            local obj = item:FindChild("Frame_Item/"..id_btn)
            if items[item_index].IsTokenMoney then
                local panelData = {
				    _MoneyID = items[item_index].Data.Id,
				    _TipPos = TipPosition.FIX_POSITION,
				    _TargetObj = obj,
			    }
			    CItemTipMan.ShowMoneyTips(panelData)
            else
			    CItemTipMan.ShowItemTips(items[item_index].Data.Id, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 obj, 
                                 TipPosition.FIX_POSITION)
            end
		end
    end  
end

--显示具体某类成就列表
def.method("number").ShowAchievementByNode = function(self, nNode)
	if self._ListAchivement == nil or #self._ListAchivement <= 0 then return end
	if self._ListAchivement[self._CurType] == nil or #self._ListAchivement[self._CurType]._NodeList <= 0 then return end

    self._CurNode = nNode + 1
    if self._CurType <= 1 then
        SetNewGetList(self)
        local totalCount, finishCount =  game._AcheivementMan:GetAchievementCountValue()
        if finishCount > 0 then
            self._AcheiveTree_Obj: SetActive(false)
            self._PanelEmpty: SetActive(false)
            self._PanelProgress: SetActive(true)
            self._PanelNewGet: SetActive(true)
            local listCount = math.clamp(#self._ListNewGet,1,self._MAX_NEWGET_SHOW)
            self._NewGet_List:SetItemCount(listCount)
            GUI.SetText(self._LabProgressTotal, string.format(StringTable.Get(31202), math.max(0, finishCount), totalCount))
            self._ImgProgress.fillAmount = finishCount / totalCount
        else
            self._AcheiveTree_Obj : SetActive(false)
            self._PanelEmpty: SetActive(true)
            self._PanelNewGet: SetActive(false)
            self._PanelProgress: SetActive(true)
            GUI.SetText(self._LabProgressTotal, string.format(StringTable.Get(31202), math.max(0, finishCount), totalCount))
        end
    else
        self._PanelNewGet: SetActive(false)
        self._PanelProgress: SetActive(false)
        if #self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList > 0 then
            self._AcheiveTree_Obj:SetActive(true)
            self._PanelEmpty:SetActive(false)
	        if self._AcheiveTree_List ~= nil then
                self._AcheiveTree_List: SetItemCount(#self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList)
                self._AcheiveTree_List:ScrollToStep(0)
            end 
        else
            self._AcheiveTree_Obj : SetActive(false)
            self._PanelEmpty: SetActive(true)
        end
    end

    self._CurChoiceIndex = -1
end

--显示node节点的信息(默认选中第一个)
def.method("userdata", "number").ShowNodeByType = function(self, item, nType)
   local clickImg = item:FindChild("Img_Arrow")
    if self._CurType ~= nType + 1 then
        if self._SelectedNode ~= nil then
            GUITools.SetGroupImg(self._SelectedNode:FindChild("Img_Arrow"), 0)
            GUITools.SetNativeSize(self._SelectedNode:FindChild("Img_Arrow"))
        end
        self._IsOpenNode = true
        self._CurType = nType + 1
        self._SelectedNode = item
        if self._ListAchivement[self._CurType] == nil then return end

        self._CurNode = 1
        if self._CurType <= 1 then
            ShowNewGetPanel(self)
            self._AcheiveType_List:OpenTab(0)
        else
            self._PanelNewGet: SetActive(false)
            self._PanelProgress: SetActive(false)
            self._AcheiveType_List:OpenTab(#self._ListAchivement[self._CurType]._NodeList)
            if #self._ListAchivement[self._CurType]._NodeList[1]._CellList > 0 then
                self._AcheiveTree_Obj : SetActive(true)
                self._PanelEmpty: SetActive(false)
                if self._AcheiveTree_List ~= nil then
                    self._AcheiveTree_List: SetItemCount(#self._ListAchivement[self._CurType]._NodeList[1]._CellList)
                end 
            else
                self._AcheiveTree_Obj : SetActive(false)
                self._PanelEmpty: SetActive(true)
            end
        end
        GUITools.SetGroupImg(clickImg, 2)
        GUITools.SetNativeSize(clickImg)
    else
        if self._IsOpenNode then
            self._IsOpenNode = false
            self._AcheiveType_List:OpenTab(0)
            GUITools.SetGroupImg(clickImg, 1)
            GUITools.SetNativeSize(clickImg)
        else
            self._IsOpenNode = true
            if self._ListAchivement[self._CurType] == nil then return end

            self._CurNode = 1
            if self._CurType <= 1 then
                ShowNewGetPanel(self)
                self._AcheiveType_List:OpenTab(0)
            else
                self._PanelNewGet: SetActive(false)
                self._PanelProgress: SetActive(false)
                self._AcheiveType_List:OpenTab(#self._ListAchivement[self._CurType]._NodeList)
                if #self._ListAchivement[self._CurType]._NodeList[1]._CellList > 0 then
                    self._AcheiveTree_Obj : SetActive(true)
                    self._PanelEmpty:SetActive(false)
                    if self._AcheiveTree_List ~= nil then
                        self._AcheiveTree_List: SetItemCount(#self._ListAchivement[self._CurType]._NodeList[1]._CellList)
                    end 
                else
                    self._AcheiveTree_Obj : SetActive(false)
                    self._PanelEmpty:SetActive(true)
                end
            end
            GUITools.SetGroupImg(clickImg, 2)
            GUITools.SetNativeSize(clickImg)
        end
    end
end

--显示成就条件
def.method().InitConditionList = function(self)
    local iData = self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList[self._CurChoiceIndex] 
    if iData == nil then
        warn("数据错误大类："..self._ListAchivement[self._CurType]._RootID.."小类:"..self._ListAchivement[self._CurType]._NodeList[self._CurNode]._NodeID.."索引"..self._CurChoiceIndex)
        return
    end

    self._ListParm = {}
    local achievementData = CElementData.GetTemplate("Achievement",iData._Tid)
    if achievementData ~= nil then
        if achievementData.EventId == EventType.FinishManual or achievementData.EventId == EventType.FinishAchieve then
            local strCells = string.split(achievementData.ReachParm, "*")
            if strCells ~= nil then
                for i, k in ipairs(strCells) do
                    local Id = tonumber(k)
                    if Id ~= nil then
                        self._ListParm[#self._ListParm + 1] = Id
                    end
                end
            end
        end
    end

    if #self._ListParm <= 0 then return end

    self._CurChoiceData = iData
    self._AcheiveTree_List: OpenTab(#self._ListParm)
end

--显示选中的成就
def.method("number").ShowClickAchievementView = function(self, nIndex)
    self._AcheiveTree_List: OpenTab(0)
    if self._CurChoiceIndex ~= nIndex + 1 then
        self._IsOpenTree = true
        self._CurChoiceIndex = nIndex + 1
        self: InitConditionList()
    else
        if self._IsOpenTree then
            self._IsOpenTree = false
        else
            self._IsOpenTree = true
            self: InitConditionList()
        end
    end   
end

def.method("userdata", "string", "number").ParentInitItem = function(self, item, id, index)
    if string.find(id, "List_AchivementMenu") then
        local achievementData = self._ListNewGet[index + 1]
        local achievementTemp = CElementData.GetTemplate("Achievement", achievementData._Tid)
        local icon = GUITools.GetChild(item, 0)
        local labName = GUITools.GetChild(item, 1)
        local frame_item = GUITools.GetChild(item, 2)
        local lab_content = GUITools.GetChild(item, 3)
        local img_done = GUITools.GetChild(item, 4)
        local img_can_receive = GUITools.GetChild(item, 5)
        if not IsNil(icon) then
            GUITools.SetIcon(icon, achievementTemp.IconPath)
        end
        if achievementData._State._IsReceive then
            img_can_receive:SetActive(false)
            frame_item:SetActive(false)
            img_done:SetActive(true)
        else
            img_can_receive:SetActive(false)
            frame_item:SetActive(true)
            img_done:SetActive(false)

            local items = GUITools.GetRewardList(achievementTemp.RewardId, true)

			-- local items = reward_template.ItemRelated.RewardItems
			for i=1,5 do
				local itemObj = frame_item: FindChild("Img_ItemBG"..i)
				if itemObj ~= nil then
					if i <= #items then
						itemObj:SetActive(true)
                        local item_data = items[i]
                        local item_new = itemObj:FindChild("ItemIcon")
                        if item_data.IsTokenMoney then
                            IconTools.InitTokenMoneyIcon(item_new, items[i].Data.Id, items[i].Data.Count)
                        else
                            local setting = {
                                [EItemIconTag.Number] = items[i].Data.Count,
                            }
                            IconTools.InitItemIconNew(item_new, items[i].Data.Id, setting, EItemLimitCheck.AllCheck)
                        end
					else
						itemObj:SetActive(false)
					end
				end			
			end

        end
        GUI.SetText(labName, achievementTemp.Name)
        GUI.SetText(lab_content, achievementTemp.Description)
    end
end

def.method("userdata", "string", "number").ParentSelectItem = function(self, item, id, index)
    if id == "List_AchivementMenu" then
        local Tid = self._ListNewGet[index + 1]._Tid
        local rootidex,nodeidex = self:GetRootIndexAndNodeIndex(Tid)
        self._AcheiveType_List:SelectItem(rootidex - 1,nodeidex - 1)
    end
end

def.method("string").ParentClick = function (self, id)
    if id == "Btn_ReceiveAll" then
        if game._AcheivementMan:NeedShowRedPoint() then
            game._AcheivementMan:SendC2SReceiveBatchReward()
            self._OrigialOpenTid = 0
        end
    end
end

--刷新返回的奖励
def.method("number").RevGetReward = function(self,nAchievmentID)
    local index = 0
    for _,v in pairs(self._ListAchivement) do
		for _,k in pairs(v._NodeList) do
			for i,m in pairs(k._CellList) do
				if m._Tid == nAchievmentID then			
  						index = i - 1
  					break
				end
			end
		end
	end	
	local item = self._CellRoot_Obj: FindChild("item-"..index)
    game._AcheivementMan:SortAchieveTable()
    self:SelectAchievementItems()
    if self._AcheiveTree_List ~= nil then
        self._AcheiveTree_List: SetItemCount(#self._ListAchivement[self._CurType]._NodeList[self._CurNode]._CellList)
    end 
    local rootIdex = self._CurType - 1
    local rootCell = self._RootGO: FindChild("item-"..rootIdex)
    self: RootShowRedPoint(rootCell, self._CurType)

    local nodeIdex = self._CurNode - 1
    local nodeCell = self._NodeGO: FindChild("item-"..nodeIdex)
    self: NodeShowRedPoint(nodeCell,self._CurType, self._CurNode)
    local node_all = self._RootGO:FindChild("item-0")
    self:AllReviewNodeShowRedPoint(node_all)
end

def.method().Hide = function(self)
    self._ListAchivement = nil
    self._ListParm = nil
    self._CurChoiceData = nil
    self._SelectedNode = nil
    self._CurType = -1
    self._CurChoiceIndex = -1 
    self._CurNode = -1
    self._ListNewGet = {}
    self._OrigialOpenTid = 0
    self._CurAchiTid = 0
    self._IsOpenTree = false
    self._IsOpenNode = false
end

def.method().Destroy = function (self)
    self:Hide()
    instance = nil
end

CPageAchievement.Commit()
return CPageAchievement