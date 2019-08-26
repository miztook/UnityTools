local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local QuestDef = require "Quest.QuestDef"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local MapBasicConfig = require "Data.MapBasicConfig" 
local CUIModel = require "GUI.CUIModel"
local CCommonBtn = require "GUI.CCommonBtn"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelUIAutoKill = Lplus.Extend(CPanelBase, "CPanelUIAutoKill")
local def = CPanelUIAutoKill.define

--def.field("userdata")._Lab_QuestChapterName = nil 
def.field("userdata")._List_Monster = nil 
def.field('userdata')._List_ElementsMap = nil
--def.field("table")._Tab_UIModels = BlankTable 
def.field("table")._Tab_GoReputationNpc = BlankTable 
def.field("table")._Tab_ReceiveReward = BlankTable 

def.field("table")._Tab_HangQuestTemps = nil  
def.field("number")._SelectedMapID = 0  
def.field("number")._SelectedIndex = 0  

local instance = nil
def.static("=>", CPanelUIAutoKill).Instance = function()
	if not instance then
		instance = CPanelUIAutoKill()
		instance._PrefabPath = PATH.UI_AutokillMonster
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	--self._Lab_QuestChapterName = self:GetUIObject("Lab_QuestChatperName")
	self._List_Monster = self:GetUIObject("List_Monster"):GetComponent(ClassType.GNewListLoop)
    self._List_ElementsMap = self:GetUIObject("List_Map"):GetComponent(ClassType.GNewTabList)

end

def.override("dynamic").OnData = function(self, data)
    self._HelpUrlType = HelpPageUrlType.AutoKillMonster
	self:ListenToEvent()
	--self._Tab_UIModels = {}
	self._Tab_GoReputationNpc = {}
	self._Tab_ReceiveReward = {}
	self:getHangQuestsTemp()

    self._List_ElementsMap:SetItemCount( table.nums( self._Tab_HangQuestTemps ) )
    self._List_ElementsMap:SelectItem(self._SelectedIndex - 1,0)
end

local keyTest = {}
--获得此地图上的 挂机怪物数据
def.method().getHangQuestsTemp = function(self)
	self._Tab_HangQuestTemps = {}
	self._SelectedIndex = 1
    local data_id_list = CElementData.GetAllHangQuest()
    for i = 1, #data_id_list do 
    	local template = CElementData.GetTemplate("HangQuest", data_id_list[i])
    	if self._Tab_HangQuestTemps[template.MapTId] == nil then
    		self._Tab_HangQuestTemps[template.MapTId] = {}
    	end
    	local mapDataArray = self._Tab_HangQuestTemps[template.MapTId]
    	mapDataArray[#mapDataArray+1] = template
    end

	keyTest ={}
	for i in pairs(self._Tab_HangQuestTemps) do
	   table.insert(keyTest,i)  
	end
	-- 对key进行升序
	table.sort(keyTest,function(a,b)return (tonumber(a) < tonumber(b)) end) 

	for i,v in ipairs(keyTest) do
		if game._CurWorld._WorldInfo.SceneTid == v then
    		self._SelectedIndex = i
    		break
    	end
	end
end

local rewards = nil
def.method().showFrameBySelectMap = function(self)
	rewards = {}
	local mapDataArray = self._Tab_HangQuestTemps[self._SelectedMapID]
	for i,v in ipairs(self._Tab_GoReputationNpc) do
		if v ~= nil then
	        v:Destroy()
	        v = nil
	    end
	end
	for i,v in ipairs(self._Tab_ReceiveReward) do
		if v ~= nil then
	        v:Destroy()
	        v = nil
	    end
	end
	self._List_Monster:SetItemCount( #mapDataArray )
end


def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == 'List_Monster' then 
    	local Img_Bg = item:FindChild("Img_Bg")
		local Lab_RegionName = item:FindChild("Lab_RegionName")
        local Lab_Name = item:FindChild("HideGroup/Lab_Name")
        local Lab_LvTips = item:FindChild("HideGroup/Lab_Name/Text")
        local Lab_LvValues = item:FindChild("HideGroup/Lab_LvValues")
        local Img_Role_1 = item:FindChild("HideGroup/Img_Role_1")

        local Img_DangerTag = item:FindChild("HideGroup/Img_DangerTag")
        local Img_MonsterBg = item:FindChild("Img_MonsterBg")
        local Lab_SuggestLv = item:FindChild("HideGroup/Lab_SuggestLv")
        local Lab_SuggestLvValue = item:FindChild("HideGroup/Lab_SuggestLvValue")
        local Lab_SkillMonster = item:FindChild("HideGroup/Lab_SkillMonster")
        local Lab_SkillMonsterValue = item:FindChild("HideGroup/Lab_SkillMonsterValue")
		local Img_Lock = item:FindChild("Img_Lock")
		local Lab_UnLockLv = item:FindChild("Img_Lock/Lab_UnLockLv") 
		local Pro_Loading = item:FindChild("HideGroup/Pro_Loading")
		local Lab_Progress = item:FindChild("HideGroup/Pro_Loading/Lab_Progress")
        local Img_Front = item:FindChild("HideGroup/Pro_Loading/Img_Front"):GetComponent(ClassType.Image)
        local Btn_GoReputationNpc = CCommonBtn.new( item:FindChild("Btn_GoKillMonster"),nil )
        local Btn_ReceiveReward = CCommonBtn.new( item:FindChild("Btn_ReceiveReward"),nil )
        local Frame_Reward = item:FindChild("Frame_Reward")

        self._Tab_GoReputationNpc[idx] = Btn_GoReputationNpc
        self._Tab_ReceiveReward[idx] = Btn_ReceiveReward

        local Img_Onclick = item:FindChild("Img_Onclick")
        local Img_Black = item:FindChild("Img_Black")
        

        local mapTemp = CElementData.GetTemplate("Map", self._SelectedMapID)
        local mapTempArray = self._Tab_HangQuestTemps[self._SelectedMapID]
        local HangQuestTemp = mapTempArray[idx]
        local questTemp = CElementData.GetQuestTemplate(HangQuestTemp.QuestId)
        local questData =  CQuest.Instance():GetInProgressQuestModel( HangQuestTemp.QuestId )

        local regionName = MapBasicConfig.GetRegionName(self._SelectedMapID, HangQuestTemp.RegionId)
        GUI.SetText(Lab_RegionName, regionName )
        GUI.SetText(Lab_Name, HangQuestTemp.DescText )
        
        Lab_LvValues:SetActive(false)
       	--print("ModelAssetPath====", HangQuestTemp.ModelAssetPath)
        local model_asset_path = HangQuestTemp.ModelAssetPath
        GUITools.SetSprite(Img_Role_1, model_asset_path)

--[[        local model = self._Tab_UIModels[idx]
        if model == nil then 
	        model = CUIModel.new(model_asset_path, Img_Role_1, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI,
	            function() end)    --no animation
	    else
	        model:Update(model_asset_path)
	    end
	    model:AddLoadedCallback(function()
	        model:SetModelParam(self._PrefabPath, model_asset_path)
	        model:PlayAnimation(EnumDef.CLIP.COMMON_STAND)
	    end)

	    self._Tab_UIModels[idx] = model
	    --]]

        local Tab_RewardBtn = {}
        for i=1,3 do
        	local RewardBtn = item:FindChild( "Frame_Reward/Btn_Reward"..i )
        	Tab_RewardBtn[#Tab_RewardBtn + 1] = RewardBtn
        end


        
        rewards[idx] = GUITools.GetRewardList(questTemp.RewardId, true)
    	local rewardData = nil
    	local item = nil
        for i,v in ipairs(Tab_RewardBtn) do
        	item = v
        	if i > #rewards[idx] then
        		item:SetActive( false )
        	else
        		item:SetActive( true )

	        	--local obj_Prop = item:FindChild("ItemIcon")
	        	rewardData = rewards[idx][i]
	            local frame_icon = GUITools.GetChild(item, 0) 
	            if rewardData.IsTokenMoney then
	                IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
	            else
	                IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id, { [EItemIconTag.Number] = rewardData.Data.Count })
	            end

--[[		            local isLock = rewardData.Data.ReputationLevel <= self._Current_SelectData.ReputationLevel

	            local frame_item = GUITools.GetChild(frame_icon, 3)
	            local img_quality_bg = GUITools.GetChild(frame_item, 1)
	            local img_quality = GUITools.GetChild(frame_item, 2)
	            local img_icon = GUITools.GetChild(frame_item, 3)
	            GameUtil.MakeImageGray(img_quality_bg, isLock)
	            GameUtil.MakeImageGray(img_quality, isLock)
	            GameUtil.MakeImageGray(img_icon, isLock)

	            local lab_lock = GUITools.GetChild(item, 1)
	            GUITools.SetUIActive(lab_lock, isLock)
	            if isLock then
	                GUI.SetText(lab_lock, StringTable.Get(25000 + rewardData.Data.ReputationLevel))
	            end--]]
        	end
        end

        -- 已经解锁
		if questData ~= nil then
			Lab_SuggestLv:SetActive(true)
			Lab_SkillMonster:SetActive(true)
			Lab_SkillMonster:SetActive(true)
			Lab_SkillMonsterValue:SetActive(true)
			Lab_SuggestLvValue:SetActive(true)
			--GUI.SetText(Lab_SuggestLvValue, HangQuestTemp.MinLevel .. '-' .. HangQuestTemp.MaxLevel )
			GUI.SetText(Lab_SuggestLvValue, tostring( HangQuestTemp.MinLevel ))
			if game._HostPlayer._InfoData._Level < HangQuestTemp.MinLevel then
				Img_DangerTag:SetActive(true)
			else
				Img_DangerTag:SetActive(false)
			end 

			local objs = questData:GetCurrentQuestObjetives()
			local str = ""
			if #objs > 0 then
				str = objs[1]:GetCurrentCount() .. '/' .. objs[1]:GetNeedCount()
			end

			GUI.SetText(Lab_SkillMonsterValue, str )
			Pro_Loading:SetActive(true)
			GUI.SetText(Lab_Progress, "" )

			if #objs > 0 then
            	Img_Front.fillAmount = objs[1]:GetCurrentCount() / objs[1]:GetNeedCount()

    			if objs[1]:GetCurrentCount() >= objs[1]:GetNeedCount() then
					Btn_GoReputationNpc:SetActive(false)
					Btn_ReceiveReward:SetActive(true)
					Btn_ReceiveReward:ShowFlashFx(true)
    			else
					--未完成
					Btn_GoReputationNpc:SetActive(true)
					Btn_GoReputationNpc:MakeGray(false)
					--GUITools.SetBtnGray(Btn_GoReputationNpc, false)
					Btn_ReceiveReward:SetActive(false)
					Btn_ReceiveReward:ShowFlashFx(false)
				end
            end

			Img_Black:SetActive(false)
			Img_Lock:SetActive(false)

			
			GUI.SetAlpha(Img_Bg,47)
			GUI.SetAlpha(Lab_RegionName,255)
			GUI.SetAlpha(Lab_Name,255)
			GUI.SetAlpha(Lab_LvTips,255)
			GUI.SetAlpha(Img_Role_1,255)
			GUI.SetAlpha(Img_MonsterBg,255)

			GameUtil.SetCanvasGroupAlpha(Frame_Reward, 1)
--[[			for i,v in ipairs(Tab_RewardBtn) do
				GUI.SetAlpha(v,255)
			end--]]
		-- 未解锁
		else
			Lab_SuggestLv:SetActive(false)
			Lab_SuggestLvValue:SetActive(false)
			Lab_SkillMonster:SetActive(false)
			Lab_SkillMonsterValue:SetActive(false)
			Pro_Loading:SetActive(false)
			Btn_ReceiveReward:SetActive(false)
			Img_DangerTag:SetActive(false)

			Img_Black:SetActive(false)
			Img_Lock:SetActive(true)
			local unlockStr = string.format(StringTable.Get(175), mapTemp.LimitEnterLevel)
			GUI.SetText(Lab_UnLockLv,unlockStr)
			Btn_GoReputationNpc:SetActive(true)
			Btn_GoReputationNpc:MakeGray(true)
			--GUITools.SetBtnGray(Btn_GoReputationNpc, true)

			GUI.SetAlpha(Img_Bg,14.1)
			GUI.SetAlpha(Lab_RegionName,76.5)
			GUI.SetAlpha(Lab_Name,76.5)
			GUI.SetAlpha(Lab_LvTips,76.5)
			GUI.SetAlpha(Img_Role_1,76.5)
			GUI.SetAlpha(Img_MonsterBg,76.5)
			
			GameUtil.SetCanvasGroupAlpha(Frame_Reward, 0.3)
		end

        

    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == 'List_Monster' then    

    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if string.find(id_btn,"Btn_Reward") then    
    	local idx = string.sub(id_btn, -1)

        local rewardData = rewards[index+1][tonumber(idx)]
        if not rewardData.IsTokenMoney then
            CItemTipMan.ShowItemTips(rewardData.Data.Id, TipsPopFrom.OTHER_PANEL,button_obj,TipPosition.FIX_POSITION)
        else
            local panelData =  
                {
                    _MoneyID = rewardData.Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = button_obj ,
                }
                CItemTipMan.ShowMoneyTips(panelData)
        end
    elseif id_btn == "Btn_GoKillMonster" then
        local mapTempArray = self._Tab_HangQuestTemps[self._SelectedMapID]
        local HangQuestTemp = mapTempArray[index+1]
        local questTemp = CElementData.GetQuestTemplate(HangQuestTemp.QuestId)
        local questData =  CQuest.Instance():GetInProgressQuestModel( HangQuestTemp.QuestId )
		if questData ~= nil then
			local isAutoFightOn = CAutoFightMan.Instance():IsOn()
			CAutoFightMan.Instance():Start()
			CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.QuestFight, HangQuestTemp.QuestId, false)
			CQuestAutoMan.Instance():Start(questData)
			
			local cb = function()
				CAutoFightMan.Instance():Stop()
				CQuestAutoMan.Instance():Stop()	
				CDungeonAutoMan.Instance():Stop()
				CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
			end
			local CTransManage = require "Main.CTransManage"
			CTransManage.Instance():SetLeaveMsgboxCB(cb)

        	questData:DoShortcut()
        	game._GUIMan:CloseByScript(self)
        end
    elseif id_btn == "Btn_ReceiveReward" then
        local mapTempArray = self._Tab_HangQuestTemps[self._SelectedMapID]
        local HangQuestTemp = mapTempArray[index+1]
        local questTemp = CElementData.GetQuestTemplate(HangQuestTemp.QuestId)
        local questData =  CQuest.Instance():GetInProgressQuestModel( HangQuestTemp.QuestId )
        if questData ~= nil then
			CQuest.Instance():DoDeliverQuest2(HangQuestTemp.QuestId)
        end

        local Tree = self:GetUIObject("List_Map"):FindChild("Viewport/Content")
        local strpath = "item-"..(self._SelectedIndex-1).."/Img_RedPoint"

        		    --判断有无大类型红点
	    local isShowRedPoint = false
        for k,v in ipairs( mapTempArray ) do
	        local questData =  CQuest.Instance():GetInProgressQuestModel( v.QuestId )
	        if questData ~= nil and HangQuestTemp.QuestId ~= v.QuestId then
	            local objs = questData:GetCurrentQuestObjetives()
	            if #objs > 0 then
	                if objs[1]:GetCurrentCount() >= objs[1]:GetNeedCount() then
	                    isShowRedPoint = true
	                    break
	                end
	            end  
	        end     
	    end

        Tree:FindChild( strpath ):SetActive(isShowRedPoint)
    end
end

local function OnQuestCommonEvent(sender, event)
	local self = instance
	self:showFrameBySelectMap()
end


def.method().ListenToEvent = function(self)
	CGame.EventManager:addHandler("QuestCommonEvent", OnQuestCommonEvent)
	--CGame.EventManager:addHandler("PlayerGuidLevelUp", OnHostPlayerLevelChangeEvent)
end

def.method().UnlistenToEvent = function(self)
	CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestCommonEvent)  
	--CGame.EventManager:removeHandler('PlayerGuidLevelUp', OnHostPlayerLevelChangeEvent)  
end

def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Info" then
    	local Btn_Item = self:GetUIObject(id)
    	--game._GUIMan:Open("CPanelAutoKillTips", {_Obj = Btn_Item})
    end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
	if list.name == "List_Map" then
   		if sub_index == -1 then
            local bigTypeIndex = main_index + 1

            local current_mapID = 0
            local index = 1
            for i,v in ipairs(keyTest) do
            	if index == bigTypeIndex then
            		current_mapID = v
            		break
            	end
            	index = index + 1
            end
            
            local mapTemplate = CElementData.GetMapTemplate( current_mapID )
		    item:FindChild("Lab_Text"):GetComponent(ClassType.Text).text = mapTemplate.TextDisplayName

		    --判断有无大类型红点
		    local isShowRedPoint = false
	        local mapTempArray = self._Tab_HangQuestTemps[current_mapID]
	        for k,v in ipairs( mapTempArray ) do
		        local questData =  CQuest.Instance():GetInProgressQuestModel( v.QuestId )
		        if questData ~= nil then
		            local objs = questData:GetCurrentQuestObjetives()
		            if #objs > 0 then
		                if objs[1]:GetCurrentCount() >= objs[1]:GetNeedCount() then
		                    isShowRedPoint = true
		                    break
		                end
		            end  
		        end     
		        
		    end
		    item:FindChild("Img_RedPoint"):SetActive(isShowRedPoint)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
	if list.name == "List_Map" then
		if sub_index == -1 then
            local bigTypeIndex = main_index + 1

            local index = 1
            for k,v in pairs(self._Tab_HangQuestTemps) do
            	if index == bigTypeIndex then
            		self._SelectedMapID = keyTest[index]
            		self._SelectedIndex = index
            		break
            	end
            	index = index + 1
            end
            
        	self:showFrameBySelectMap()
        	self._List_Monster:ScrollToStep(0)
            --self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            --self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end

    end
end

def.override().OnHide = function(self)
	self:UnlistenToEvent()
	for i,v in ipairs(self._Tab_GoReputationNpc) do
		if v ~= nil then
	        v:Destroy()
	        v = nil
	    end
	end
	for i,v in ipairs(self._Tab_ReceiveReward) do
		if v ~= nil then
	        v:Destroy()
	        v = nil
	    end
	end

	--self._Lab_QuestChapterName = nil
	self._List_Monster = nil
	self._List_ElementsMap = nil
	--self._Tab_UIModels = nil 
	--self._Tab_RewardBtn = nil
	self._Tab_HangQuestTemps = nil
	self._SelectedMapID = 0
	self._SelectedIndex = 0
end

CPanelUIAutoKill.Commit()
return CPanelUIAutoKill