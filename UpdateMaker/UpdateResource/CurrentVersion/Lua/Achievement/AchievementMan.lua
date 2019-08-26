--[[----------------------------------------------
         		 成就管理器
          				--- by luee 2017.1.11
--------------------------------------------------]]
local Lplus = require "Lplus"
local AchievementMan = Lplus.Class("AchievementMan")
local def = AchievementMan.define

local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local EParmType = require "PB.Template".ItemApproach.EParmType
local EUseType = require "PB.Template".Achievement.EUseType
local EventType = require "PB.Template".Achievement.EventType
local CPanelUIManual = require "GUI.CPanelUIManual"
local CPanelUIActivity = require "GUI.CPanelUIActivity"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"

--成就数据链表
def.field("table")._Table_Achievements = nil
def.field("boolean")._IsShowRed = false
def.field("boolean")._HasGotAchieveDatas = false
def.field("table")._AchievementsTIDtoValue = nil

def.field("table")._AdvancedGuideInfo = BlankTable           -- 成就引导、业绩信息

def.static("=>", AchievementMan).new = function()
    local obj = AchievementMan()
	return obj
end

def.method().RequestAchieveDatas = function(self)
    if not self._HasGotAchieveDatas then
        self:SendC2SAchieveSync()
    end
end

--加载所有副本数据
def.method().Init = function(self)
	self._Table_Achievements = {}
	self._AchievementsTIDtoValue = {}
	local allAchievement = CElementData.GetAllTid("Achievement")
	
	for _,v in ipairs(allAchievement) do
        repeat
            if v > 0 then
			    local achievementData = CElementData.GetTemplate("Achievement",v)
                if achievementData == nil or achievementData.Id == nil then break end
				local ntype = achievementData.TypeID
				
				if self._Table_Achievements[ntype] == nil then
					self._Table_Achievements[ntype] = 
					{
						_RootID = achievementData.TypeID,
						_RootName = achievementData.TypeName,
						_NodeList = {}
					}
				end

				if self._Table_Achievements[ntype]._NodeList[achievementData.TypeID2] == nil then
					self._Table_Achievements[ntype]._NodeList[achievementData.TypeID2] = 
					{
						_NodeID = achievementData.TypeID2,
						_NodeName = achievementData.TypeName2,
						_CellList = {}
					}	
				end
				local cell_list = self._Table_Achievements[ntype]._NodeList[achievementData.TypeID2]._CellList
				
				local cell = {
                    _Tid = v,                           -- 模板ID
                    _MarkId = achievementData.MarkId,   -- 排序ID
					_FinishTime = 0,                    -- 完成时间
					_SortId = achievementData.SortId,	-- 业绩系统排序
                    _UseType = achievementData.UseType, -- 用途
                    _ShowType = achievementData.ShowHideType,   -- 显示类型
					_DisPlayName = achievementData.DisPlayName,	-- 业绩系统显示名称
					_RewardId = achievementData.RewardId, 	-- 奖励ID
					_ReachParm = achievementData.ReachParm,
					_ParmType = achievementData.ParmType,	-- 参数类型
					_Condition = achievementData.Condition,
					_State =                            -- 成就状态
					{
						_CurValueList = {},     -- 数组计数器
						_isFinish = false,      -- 是否完成
						_IsReceive = false,     -- 是否已领取
					}
				}
				cell_list[#cell_list + 1] = cell
				self._AchievementsTIDtoValue[v] = cell
			else
				warn("成就数据错误ID："..v)
			end	
        until true;
	end
end

--获取所有成就
def.method("=>","table").GetAllAchievement = function(self)
	return self._Table_Achievements
end

def.method("=>","table").GetAdvancedGuideInfo = function(self)
	return self._AdvancedGuideInfo
end

--通过ID获取某一成就
def.method("number","=>","table").GetAchieventMentByID = function(self, nID)
	for _,v in pairs(self._Table_Achievements) do
		for _,k in pairs(v._NodeList) do
			for _,m in ipairs(k._CellList) do
				if m._Tid == nID then
					return m
				end
			end
		end
	end

	return nil
end

--通过Tid获取成就名字
def.method("number","=>","string").GetAchievementName = function(self, nID)
	local achievementData = CElementData.GetTemplate("Achievement", nID)
	if achievementData == nil or achievementData.Name == nil then return "" end

	return achievementData.Name
end

def.method("number", "=>", "boolean").IsRootTagHaveAchi = function(self, rID)
    if self._Table_Achievements == nil then return false end
    for i,v in pairs(self._Table_Achievements) do
        if v._RootID == rID then
            for _,v1 in ipairs(v._NodeList) do
                for _,v2 in ipairs(v1._CellList) do
                    if v2._UseType == EUseType.EUseType_Achieve then
                        return true
                    end
                end
            end
        end
    end
    return false
end

def.method().SortAchieveTable = function(self)
	local function AchieveSort(item1, item2)
		if item1 == nil or item2 == nil then return false end
        if item1._State._IsReceive == item2._State._IsReceive then
            if item1._State._isFinish == item2._State._isFinish then
                return item1._MarkId < item2._MarkId
            else
                return item1._State._isFinish
            end
        else
            return not item1._State._IsReceive
        end
	end

	for _,v in pairs(self._Table_Achievements) do
		if v._NodeList ~= nil then
			for _,k in pairs(v._NodeList) do
				if k._CellList ~= nil then
					table.sort(k._CellList, AchieveSort)	
				end		
			end			
		end
	end
end

--获取某一个成就是否已完成
def.method("number","=>","boolean").AchieventIsFinish = function(self, nTid)
	local iData = self: GetAchieventMentByID(nTid)
	if iData == nil then return false end

	return iData._State._isFinish
end

--获取成就数据数据  总数  + 完成数
def.method("=>","number","number").GetAchievementCountValue = function(self)
	local totalValue = 0
	local finishCount = 0
	for _,v in pairs(self._Table_Achievements) do
		if v._NodeList ~= nil then
			for _,k in pairs(v._NodeList) do
				if k._CellList ~= nil then
					for _,m in ipairs(k._CellList) do
                        if m._UseType == EUseType.EUseType_Achieve and m._ShowType ~= 2 then
						    totalValue = totalValue + 1
						    if m._State._isFinish then
							    finishCount = finishCount + 1 
						    end
                        end
					end	
				end	
			end
		end		
	end

	return totalValue, finishCount
end

--成就小红点
def.method("=>","boolean").NeedShowRedPoint = function(self)
	for _,v in pairs(self._Table_Achievements) do
		if v._NodeList ~= nil and v._RootID ~= 0 then
			for _,k in pairs(v._NodeList) do
				if k._CellList ~= nil then
					for _,m in ipairs(k._CellList) do
						if m._State._isFinish  and not m._State._IsReceive then
                            local achi_temp = CElementData.GetTemplate("Achievement", m._Tid)
                            if achi_temp ~= nil and achi_temp.ShowHideType ~= 2 then
							    self._IsShowRed = true
							    return true
                            end
						end
					end	
				end	
			end
		end		
	end
	self._IsShowRed = false
	return false
end

def.method("=>", "boolean").IsAchievementUnlock = function(self)
    return game._CFunctionMan:IsUnlockByFunTid(25)
end

def.method("boolean").SetShowRedPoint = function(self, isShow)
	self._IsShowRed = isShow
end

def.method("=>","boolean").IsHaveRedPoint = function(self)
	return self._IsShowRed
end

def.method("number","number").DrumpToRightPanel = function(self, proceedToId,ItemId)
    local drump_temp = CElementData.GetTemplate("ItemApproach", proceedToId)
    if drump_temp == nil then
        warn("物品来源错误 Tid : ", proceedToId)
        return
    end
    -- warn('drump_temp.ClickType ',drump_temp.ClickType)
    if drump_temp.ClickType ~= EParmType.OpenUI then
        warn("跳转参数不是开启界面 ")
        return
    end
    if drump_temp.ClickValue1 == nil or drump_temp.ClickValue1 == "" then
        warn("打开界面的名字不能为空")
        return
    end
    -- TODO 判断功能是否解锁
    if drump_temp.FunID > 0 and (not game._CFunctionMan:IsUnlockByFunTid(drump_temp.FunID)) then
        local fun_temp = CElementData.GetTemplate("Fun", drump_temp.FunID)
        if fun_temp ~= nil then
            game._CGuideMan:OnShowTipByFunUnlockConditions(0, drump_temp.FunID)
            return
        end
    end

    local panelName = drump_temp.ClickValue1
    local param = drump_temp.ClickValue2
    if panelName == "CPanelMirrorArena" then
        if param == nil then warn("竞技场，角斗场，无畏战场跳转需要有参数 分别是1，2，3") return end
        if tonumber(param) == 1 then
            game._CArenaMan:OpenArena(game._DungeonMan:Get1v1WorldTID())
        elseif tonumber(param) == 2 then
            game._CArenaMan:OpenArena(game._DungeonMan:Get3V3WorldTID())
        elseif tonumber(param) == 3 then
            game._CArenaMan:OpenArena(game._DungeonMan:GetEliminateWorldTID())
        end
    elseif panelName == "CPanelUIGuildList" then
        if param == nil or param == "" then warn("公会列表跳转参数错误，不能不填") return end
        if tonumber(param) == 1 then
            if game._GuildMan:IsHostInGuild() then 
                game._GUIMan:Open("CPanelUIGuild", _G.GuildPage.Building)
            else
                game._GuildMan:SendC2SGuildList()
            end
        elseif tonumber(param) == 2 then
            local data = {_Index = 1}
			game._GUIMan:Open("CPanelUIGuildList", data)
        end
    elseif panelName == "GuildDefend" then
        game._GuildMan:OpenGuildDefend()
    elseif panelName == "GuildBattle" then
        game._GuildMan:OpenGuildBattle()
    elseif panelName == "GuildPanel" then
        game._GuildMan:RequestAllGuildInfo()
    elseif panelName == "GuildDonate" then
        game._GuildMan:OpenGuildDonate()
    elseif panelName == "GuildPray" then
        game._GuildMan:OpenGuildPray()
    elseif panelName == "GuildLaboratory" then
        game._GuildMan:OpenGuildLaboratory()
    elseif panelName == "GuildSmithy" then
        game._GuildMan:OpenGuildSmithy()
    elseif panelName == "GuildShop" then
        game._GuildMan:OpenGuildShop()
    elseif panelName == "GuildDungeon" then 
    	game._GuildMan:OpenGuildDungeon()
	elseif panelName == "GuildConvoy" then 
		game._GuildMan:OpenGuildConvoy()
    elseif panelName == "CalendarOpen" then
        if param == nil then warn("冒险日历参数错误，必须填一个日历id") end
        local playID = tonumber(param)
        game._CCalendarMan:IsCalendarOpenByPlayID(playID)
    elseif panelName == "CPanelUISkill" then
    	if tonumber(param) == 1 then 
    		-- 技能
	        local data = {}
	        data._PageTag = "Tab_Skill"
			game._GUIMan:Open("CPanelUISkill", data)
		elseif param == "Tab_Prof" then
			--专精 
			local data = { }
    		data._PageTag = "Tab_Prof"
    		game._GUIMan:Open("CPanelUISkill", data)
		elseif param == "Tab_Rune" then 
			-- 纹章
			local data = { }
   	 		data._PageTag = "Tab_Rune"
    		game._GUIMan:Open("CPanelUISkill", data)
		elseif param == "Tab_Soul" then
			-- 秘晶
			local data = { }
			data._PageTag = "Tab_Soul"
			game._GUIMan:Open("CPanelUISkill", data)
		end
    elseif panelName == "CPanelUIEquipProcess" then
        local pageType = tonumber(param)
        if pageType == nil then warn("装备页签跳转参数错误") return end
        local data = nil
        if pageType == 1 then
            data = {UIEquipPageState = EnumDef.UIEquipPageState.PageFortify}
        elseif pageType == 2 then
            data = {UIEquipPageState = EnumDef.UIEquipPageState.PageRecast}
        elseif pageType == 3 then
            data = {UIEquipPageState = EnumDef.UIEquipPageState.PageRefine}
        elseif pageType == 4 then
            data = {UIEquipPageState = EnumDef.UIEquipPageState.PageLegendChange}
        elseif pageType == 5 then
            data = {UIEquipPageState = EnumDef.UIEquipPageState.PageInherit}
        end
        game._GUIMan:Open("CPanelUIEquipProcess", data)
    elseif panelName == "CPanelUIPetProcess" then
        local pageType = tonumber(param)
        if pageType == nil then warn("宠物页签跳转参数错误") return end
        local data = nil
        if pageType == 1 then
            data = {UIPetPageState = EnumDef.UIPetPageState.PagePetInfo}
        elseif pageType == 2 then
            data = {UIPetPageState = EnumDef.UIPetPageState.PageCultivate}
        elseif pageType == 3 then
            data = {UIPetPageState = EnumDef.UIPetPageState.PageFuse}
        elseif pageType == 4 then
            data = {UIPetPageState = EnumDef.UIPetPageState.PageAdvance}
        elseif pageType == 5 then 
        	data = {UIPetPageState = EnumDef.UIPetPageState.PageSkill}
        end
        game._GUIMan:Open("CPanelUIPetProcess", data)
    elseif panelName == "CPanelNpcShop" then
        local values = string.split(param, '*') 
    	local vlaueList = {}
    	if values ~= nil then 
    		for i,v in pairs(values) do
    			table.insert(vlaueList,v)
    		end
    	end
    	if vlaueList == nil or #vlaueList < 1 then warn("Npc商店界面跳转参数错误") return end
        local panelData = {}
    	if #vlaueList == 1 then 
    		if ItemId > 0 then
				panelData =
					{
						OpenType = 1,
						ShopId = tonumber(vlaueList[1]),
						ItemId = ItemId,
					}
			else
				panelData =
					{
						OpenType = 1,
						ShopId = tonumber(vlaueList[1]),
					}
			end
		elseif #vlaueList == 2 then 
			if ItemId > 0 then
				panelData =
					{
						OpenType = 1,
						ShopId = tonumber(vlaueList[1]),
						SubShopId = tonumber(vlaueList[2]),
						RepID = tonumber(vlaueList[2]),
						ItemId = ItemId,
					}
			else
				panelData =
					{
						OpenType = 1,
						ShopId = tonumber(vlaueList[1]),
						SubShopId = tonumber(vlaueList[2]),
						RepID = tonumber(vlaueList[2]),
					}
			end
		end
		game._GUIMan:Open("CPanelNpcShop",panelData)
    elseif panelName == "CPanelUIExterior" then
    	local CPanelStrong = require "GUI.CPanelStrong"
    	if CPanelStrong.Instance():IsShow() then 
    		game._GUIMan:Close("CPanelStrong")
    	end
        local CExteriorMan = require "Main.CExteriorMan"
		CExteriorMan.Instance():Enter({ Type = tonumber(param)})
    elseif panelName == "CPanelCharm" then
        local page_type = tonumber(param)
        if page_type == nil or page_type < 0 or page_type > 2 then warn("神符界面跳转参数错误") return end
        game._GUIMan:Open("CPanelCharm", {pageType = page_type})
    elseif panelName == "CPanelUIWing" then 
    	if tonumber(param) == 1 then 
    		local data = {Type = 1}
			game._GUIMan:Open("CPanelUIWing", data)
    	end
    elseif panelName == "CPanelRoleInfo" then 
    	if tonumber(param) ~= nil then 
	    	local panelData = 
	        {
	            PageType = tonumber(param),
	            IsByNpcOpenStorage = false,
	        }
	        game._GUIMan:Open("CPanelRoleInfo", panelData)
	    elseif param == "Decompose" then 
	    	local panelData = 
	        {
	            PageType = CPanelRoleInfo.PageType.BAG,
	            IsOpenDecompose = true,
	        }
	        game._GUIMan:Open("CPanelRoleInfo", panelData)
	    else
	    	if param == nil then return end
	    	local values = string.split(param, '*') 
	    	local vlaueList = {}
	    	if values ~= nil then 
	    		for i,v in pairs(values) do
	    			table.insert(vlaueList,v)
	    		end
	    	end
	    	local panelData = 
	        {
	            PageType = tonumber(vlaueList[1]),
	            ItemId = tonumber(vlaueList[2]),
	            IsByNpcOpenStorage = false,
	        }
	        game._GUIMan:Open("CPanelRoleInfo", panelData)
	    end
	elseif panelName == "CPanelUIExpedition" then 
		-- 远征
		if tonumber(param) ~= nil then 
			local panelData = { DungeonID = tonumber(param)}
			game._GUIMan:Open("CPanelUIExpedition", panelData)
		end
	elseif panelName == "CPanelUIManual" then
        local index_type = tonumber(param)
		if index_type ~= nil then
            if index_type == 2 then
			    -- 万物志
			    local panelData = {_type = 2}
			    game._GUIMan:Open("CPanelUIManual", panelData)
            elseif index_type == 3 then
                game._GUIMan:Open("CPanelUIManual", nil)
            end
		else
			-- 成就
			game._GUIMan:Open("CPanelUIManual", nil)
		end
	elseif panelName == "CPanelUIQuestList" then
		local params = string.split(param,"*")
    	local panelData = {}
    	if #params == 1 then 
	    	panelData = 
	    	{
	    		OpenIndex = tonumber(params[1])
	   		 }
	   	elseif #params == 2 then 
	   		panelData = 
	   		{
	   			OpenIndex = tonumber(params[1]),
	   			OpenIndex2 = tonumber(params[2]),
	   		}
	   	end
		game._GUIMan:Open("CPanelUIQuestList",panelData)
	elseif panelName == "CPanelUIDungeon" then
		if param == nil then warn("冒险日历参数错误，必须填一个日历id") end
        local playID = tonumber(param)
        local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(playID)
        if not isOpen then 
        	game._GUIMan:ShowTipText(StringTable.Get(30109), false)
        	return
        end
    	game._GUIMan:Open("CPanelUIDungeon", playID)
    elseif panelName == "CPanelUIGuildSmithy" then 
    	game._GuildMan:OpenGuildSmithy()
    elseif panelName == "CPanelStrong" then
    	local params = string.split(param,"*")
    	local panelData = {}
    	if #params == 1 then 
	    	panelData = 
	    	{
	    		PageType = tonumber(params[1])
	   		 }
	   	elseif #params == 2 then 
	   		panelData = 
	   		{
	   			PageType = tonumber(params[1]),
	   			SelectId = tonumber(params[2]),
	   		}
	   	end
   		game._GUIMan:Open("CPanelStrong",panelData)
    elseif panelName == "CPanelAuction" then
        local param = tonumber(param)
        if param == 3 then
            if game._GuildMan:IsHostInGuild() then
                game._GUIMan:Open("CPanelAuction", 3)
            else
                game._GUIMan:ShowTipText(StringTable.Get(8091), false)
            end
        else
            game._GUIMan:Open("CPanelAuction", nil)
        end
    else
        game._GUIMan:Open(panelName, tonumber(param) or param)
    end
end
--------------------------S2C-----------------------------

--改变成就数据
def.method("table", "=>", "number").ChangeAchievementState = function(self, data)
	if data == nil then return 0 end

	for _,v in pairs(self._Table_Achievements) do
		if v._NodeList ~= nil then
			for _,k in pairs(v._NodeList) do
				for _,m in ipairs(k._CellList) do
					if m._Tid == data.TId then
						m._State._isFinish = data.IsFinish
						m._State._IsReceive = data.IsReceive
						local CurrParmList = data.CurrParmList
						m._State._CurValueList = CurrParmList
						m._FinishTime = data.FinishTime or 0
						return self:GetAchievementCurrent(CurrParmList, m._ParmType)
					end
				end
			end
		end
	end
	return 0
end

-- 当前完成个数为数组，在计算进度时使用最少完成的个数或者为各个子成就完成数之和
def.method("number", "=>", "number").GetTargetAchievementCurrent = function(self, tid)
	local achData = self._AchievementsTIDtoValue[tid]
	return self:GetAchievementCurrent(achData._State._CurValueList, achData._ParmType)
end

def.method("table", "number", "=>", "number").GetAchievementCurrent = function(self, currParmList, parmType)
	if nil == currParmList then return 0 end

	local current = 0
	if parmType == EParmType.CountShare then
		for k, v in ipairs(currParmList) do
			current = current + v.CurrParm
		end
	else
		for k, v in ipairs(currParmList) do
			local currParm = v.CurrParm
			if current < currParm then
				current = currParm
			end
		end
	end
	return current
end

def.method("number", "=>", "number").GetAchievementReachCount = function(self, tid)
    local achievementData = CElementData.GetTemplate("Achievement",tid)
    if achievementData == nil then
        warn("error !!! 成就模板数据为空 ， ID：", tid)
        return 0
    end
    -- 特殊需求，完成指定章节和完成指定副本ID，达成参数填的是章节ID或副本ID，直接返回1
    if achievementData.EventId == EventType.EventType_000 
            or achievementData.EventId == EventType.EventType_001
            or achievementData.EventId == EventType.EventType_036
            or achievementData.EventId == EventType.EventType_037 then
        return 1
    end
	local achData = self._AchievementsTIDtoValue[tid]
	local reachList = string.split(achData._ReachParm, "*")
	return tonumber(reachList[1])
end

def.method("number").FinishAchievementeData = function(self, tid)
	local achData = self._AchievementsTIDtoValue[tid]
	local parmType = achData._ParmType
	local reachList = string.split(achData._ReachParm, "*")
	local conditionList = string.split(achData._Condition, "*")
	local reachCondition = {}
	local len = #reachList
	if parmType == EParmType.CountShare then
		table.insert(reachCondition, {CurrParm = tonumber(reachList[1]), Condition = tonumber(conditionList[1])})
	else
		for i = 1, len do
			table.insert(reachCondition, {CurrParm = tonumber(reachList[i]), Condition = tonumber(conditionList[i])})
		end
	end
	achData._State._CurValueList = reachCondition
end

--完成奖励
def.method("number", "number").FinishAchievement = function(self, nTID, time)	
	for i,v in pairs(self._Table_Achievements) do
		for l,k in pairs(v._NodeList) do
			for _,m in ipairs(k._CellList) do
				if m._Tid == nTID then
					m._State._isFinish = true
					self:FinishAchievementeData(nTID)
                    m._FinishTime = time
                    if self:IsAchievementUnlock() then
					    local strName = self:GetAchievementName(nTID)
                        local achi_temp = CElementData.GetTemplate("Achievement", nTID)
                        if achi_temp and achi_temp.UseType == EUseType.EUseType_Achieve then
					        game._GUIMan:ShowAchieveTips(strName,nTID)
                        end
                    end
				end
			end
		end
	end	
    self:NeedShowRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
end

def.method("number", "=>", "boolean").IsAchievementUseType = function(self, nTID)	
	local achi_temp = CElementData.GetTemplate("Achievement", nTID)
	if achi_temp then
		return achi_temp.UseType == EUseType.EUseType_Achieve
	end
	return false
end

--领取奖励
def.method("number","number").RevGetReward = function(self,nAchievmentID,nErroID)
  	if nErroID ~= 0 then
  		game._GUIMan:ShowErrorTipText(nErroID)
  		return
  	end

  	local panel = CPanelUIManual.Instance()
  	local isShow = panel:IsShow() 
    local finded = false
  	for _,v in pairs(self._Table_Achievements) do
		for _,k in pairs(v._NodeList) do
			for i,m in ipairs(k._CellList) do
				if m._Tid == nAchievmentID then
					m._State._IsReceive = true	
                    finded = true				
  					break
				end
			end
		end
	end	
	self: NeedShowRedPoint()
    if finded then
		if isShow then
  			panel:RevGetAchievementReward(nAchievmentID)
  		end
    end
  	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
end

def.method().UpdateAdvancedGuideInfo = function(self)
    self._AdvancedGuideInfo = {}
    local all_achivements = self._Table_Achievements
    for _,v in pairs(all_achivements) do
		if v._NodeList ~= nil then
			for _,k in pairs(v._NodeList) do
                for _,m in ipairs(k._CellList) do
                    if m._SortId and m._SortId > 0 then
						local state = m._State
                        self._AdvancedGuideInfo[#self._AdvancedGuideInfo + 1] = 
                            {SortId = m._SortId, isFinish = state._isFinish, IsReceive = state._IsReceive, DisPlayName = m._DisPlayName, RewardId = m._RewardId, ReachParm = m._ReachParm, Tid = m._Tid}
                    end
				end
			end
		end
    end
	table.sort(self._AdvancedGuideInfo, function(a, b) return a.SortId < b.SortId end)
	
	PanelPageConfig.Activity[1].IsShow = not self:AdvancedGuideComplite()

	local panelActivity = CPanelUIActivity.Instance()
	if panelActivity:IsShow() and panelActivity:GetCurrentMenuName() == PanelPageConfig.Activity[1].MenuBtn then
		panelActivity:UpdateShow()
	end
	if self:AdvancedInfoRedNodeIsShow() then
		if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Activity) then
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Activity,true)
		end
	end
end

def.method("=>", "boolean").AdvancedInfoRedNodeIsShow = function(self)
	for k, v in ipairs(self._AdvancedGuideInfo) do
		if not v.IsReceive then
			if v.isFinish then
				return true
			else
				return false
			end
		end
	end
	return false
end

def.method("=>", "boolean").AdvancedGuideComplite = function(self)
	for k, v in ipairs(self._AdvancedGuideInfo) do
		if (not v.isFinish) or (not v.IsReceive) then
			return false
		end
	end
	return true
end

-- 一键领取返回消息
def.method("table").RevBatchGetReward = function(self, achievementIDs)
    for k,v in pairs(self._Table_Achievements) do
        for k1,v1 in pairs(v._NodeList) do
            for k2,v2 in pairs(v1._CellList) do
                for _,w in ipairs(achievementIDs) do
                    if v2._Tid == w then
                        v2._State._IsReceive = true
                    end
                end
            end
        end
    end
    self:SortAchieveTable()
    self:NeedShowRedPoint()
  	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Manual,game._CManualMan:IsShowRedPoint())
	if CPanelUIManual.Instance():IsShow() then 
        CPanelUIManual.Instance():FreshAchievementPage()
    end
end

def.method().Cleanup = function(self)
	self._Table_Achievements = {}
	self._IsShowRed = false
	self._HasGotAchieveDatas = false
	self._AdvancedGuideInfo = {}
	self._AchievementsTIDtoValue = {}
end

------------------C2S----------------------------
--领取奖励
def.method("number", "boolean").SendC2SReceiveReward = function(self,nTID,isAchi)
	local C2SAchieveDraw = require "PB.net".C2SAchieveDraw
	local protocol = C2SAchieveDraw()
	protocol.Tid = nTID
    protocol.IsAchieve = isAchi
	PBHelper.Send(protocol)
end

--请求数据
def.method().SendC2SAchieveSync = function(self)
	local C2SAchieveSync = require "PB.net".C2SAchieveSync
	local protocol = C2SAchieveSync()
	PBHelper.Send(protocol)
end

--一键领取
def.method().SendC2SReceiveBatchReward = function(self)
    local C2SAchieveDrawBatch = require "PB.net".C2SAchieveDrawBatch
    local protocol = C2SAchieveDrawBatch()
    protocol.IsAchieve = true
    PBHelper.Send(protocol)
end

AchievementMan.Commit()
return AchievementMan