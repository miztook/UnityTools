local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local Data = require "PB.data"

local CPanelMainTips = Lplus.Extend(CPanelBase, 'CPanelMainTips')
local def = CPanelMainTips.define

def.field('userdata')._SimpleTextTipTemplate = nil
def.field('userdata')._BottomSimpleTextTipTemplate = nil
def.field('userdata')._IconAndTextTipTemplate = nil 		-- 带图标的tips

def.field("userdata")._FightScoreHold = nil
def.field("userdata")._FightScoreUp = nil 					-- 战斗力提升
def.field("userdata")._FightScoreOld = nil
def.field("userdata")._FightScoreNew = nil
def.field("userdata")._FightScoreUpLab = nil  				-- 战斗力提升Label

def.field("userdata")._FightScoreDown = nil 					-- 战斗力提升
def.field("userdata")._FightScoreOldDown = nil
def.field("userdata")._FightScoreNewDown = nil
def.field("userdata")._FightScoreDownLab = nil  				-- 战斗力提升Label

def.field("table")._FSDetailTipList = nil 		-- 战斗力细节
def.field("table")._FSDetailMsg = nil 		-- 战斗力细节内容
--def.field("number")._FSDetailTimer = 0
def.field("userdata")._FrameFSDetail = nil
def.field("userdata")._DTP_FSDetail = nil

local _DT_GRP_FS_Show = "500"
local _DT_GRP_FS_Close = "501"
local _DT_GRP_FS_DETAIL = "502"		--动效
local FS_DETAIL_ITEM_CNT = 3		--条数
local FS_DETAIL_TICK = 2.3		--时长

def.field("table")._FightScoreNum = BlankTable				-- 战斗力显示的Lab
def.field("number")._FightScoreNumMax = 7					-- 战斗力显示的Lab最大个数
def.field("table")._MoveObject = BlankTable					-- 移动需要创建的Obj缓存
def.field("boolean")._FightScoreRunning = false				-- 数字移动模块开启状态
def.field("number")._FightScoreRunTimerId = 0 				-- 数字移动 tick
def.field("userdata")._ManualTipsBG = nil 				    -- 发现万物志
def.field("userdata")._ManualTipsLab = nil 				    -- 发现万物志Label
def.field("userdata")._ManualTipsTitle = nil 				  -- 发现万物志Label
def.field("number")._ManualTipsTimerId = 0
def.field("number")._ManualCurEId = 0                       -- 打开的条目ID
def.field("table")._ManualTipsList = nil                    -- 万物志条目组
def.field('userdata')._QuestChapterOpen = nil          -- 任务章节开启 
def.field('userdata')._QuestChapterOpen_TweenPlayer = nil 
def.field('userdata')._Lab_QuestChapterName = nil          -- 任务章节开启提示 
def.field('number')._QuestOpen_timer_id = -1 
def.field("boolean")._IsIgnoreDownTips = false              --是否忽略提示下提示
def.field("userdata")._MoveTextItem = nil 					--滚屏文字item
def.field("userdata")._MoveTextFather = nil 				--滚屏文字Parent
--def.field("userdata")._AttentionTip = nil     	--警示提醒
--def.field("userdata")._LabAttention = nil       --警示lab
--def.field("userdata")._ImgAttentionBoss = nil    --BOSS警示
--def.field("userdata")._ImgAttentionTips = nil   --普通三角警示
def.field("userdata")._ObjAchieve = nil         --成就TIPS
def.field("userdata")._ObjSpecialAchieve = nil  --特殊成就tips
def.field("userdata")._LabAchieve = nil         --成就label
def.field("userdata")._AchieveIconBG = nil      --成就ICON
def.field("userdata")._FrameKillTips = nil 
def.field("userdata")._FrameKiller = nil
def.field("userdata")._FrameDeath  = nil 
def.field("userdata")._FrameGuildBaseTip = nil
def.field("userdata")._FrameGuildTwerTip = nil

def.field('table')._Model = nil
def.field('table')._TipTextOriginPos = nil
def.field('table')._TipTextOriginPosDown = nil
def.field('table')._ItemTipsOriginPos = nil
def.field('table')._TableOrignalPos = nil --记录所有tips的原始位置
def.field("table")._TableMoveTextObj =nil --滚屏文字的Obj，做table缓存处理
def.field('table')._TableUpText = nil --所有上飘字
def.field('table')._TableDownText = nil -- 所有下飘字
def.field('table')._TableMoveText = nil--滚屏文字
def.field('table')._TableIconText = nil --所有带图标的飘字
def.field("table")._TableAchieve = nil  --成就提示
def.field("table")._TableSpecialAchieve = nil --特殊成就提示
def.field("number")._DownTipsTimer = 0 --系统提示timer
def.field("number")._MoveTextTimer = 0 --滚屏文字timer
def.field("number")._AchieveTimerID = 0 --成就提示Timer
def.field("number")._SpecialAchieveTimerID = 0  -- 成就特殊提示Timer
--def.field("number")._FightScoreTimerID = 0 --战斗力显示timer
def.field("number")._PopFightScoreTimerID = 0 --战斗力滚屏显示
def.field("userdata")._DoTweenPlayer_Scoreup = nil
def.field("userdata")._DoTweenPlayer_Scoredown = nil
def.field("userdata")._FrameGuildDungeonTip = nil
def.field("number")._GuildDungeonTipTimerID = 0 --公会防守提示Timer

--def.field("userdata")._BattleStgTip = nil	--副本中的消息提示
--def.field("userdata")._BattleStgTxt = nil
--def.field("userdata")._BattleStg_TweenPlayer = nil
--def.field("string")._DoTweenID_BattleStg1 = "503"
--def.field("string")._DoTweenID_BattleStg2 = "504"

local MAX_DOWNTIPS_COUNT = 3
local MOVE_TEXT_POS = Vector3.New(0,110,0) 
local MOVE_ITEM_POS = Vector3.New(-10,0,0)

local instance = nil
def.static('=>', CPanelMainTips).Instance = function ()
	if not instance then
		instance = CPanelMainTips()
		instance._PrefabPath = PATH.Panel_MainTips
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = false

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._SimpleTextTipTemplate = self:GetUIObject('Frame_SimpleTextTip')
	self._QuestChapterOpen = self:GetUIObject('Frame_QuestChapterOpen')
	self._QuestChapterOpen_TweenPlayer = self._QuestChapterOpen:GetComponent(ClassType.DOTweenPlayer)
	self._Lab_QuestChapterName = self:GetUIObject('Lab_QuestChapterName')
	self._BottomSimpleTextTipTemplate = self:GetUIObject('Frame_BottomSimpleTextTip')
	self._IconAndTextTipTemplate = self:GetUIObject('Frame_IconAndTextTip')
	self._ManualTipsBG = self:GetUIObject("Frame_ManualTips")
	self._FrameKillTips = self:GetUIObject("Frame_KillTips")
	self._FrameKiller = self:GetUIObject("FrameKiller")
	self._FrameDeath = self:GetUIObject("FrameDead")
	if self._ManualTipsBG ~= nil then
		self._ManualTipsLab = self._ManualTipsBG:FindChild("Lab_Tips")
		self._ManualTipsTitle = self._ManualTipsBG:FindChild("Lab_Title")
	end

	self._FightScoreHold = self:GetUIObject("Frame_FightScoreHold")
	self._FightScoreUp = self:GetUIObject("Frame_FightScoreUp")
	self._FrameGuildBaseTip = self:GetUIObject("Frame_GuildBF_BaseTip")
    self._FrameGuildTwerTip = self:GetUIObject("Frame_GuildBF_TwerTip")
	self._FightScoreOld = self:GetUIObject("Lab_Num_Old")
	self._FightScoreNew = self:GetUIObject("Lab_Num_New")
	self._FightScoreUpLab = self:GetUIObject("Lab_Increase_Num")
	self._DoTweenPlayer_Scoreup = self._FightScoreUp:GetComponent(ClassType.DOTweenPlayer)
	
	self._FightScoreDown = self:GetUIObject("Frame_FightScoreDown")
	self._FightScoreOldDown = self:GetUIObject("Lab_Num_Old_Down")
	self._FightScoreNewDown = self:GetUIObject("Lab_Num_New_Down")
	self._FightScoreDownLab = self:GetUIObject("Lab_Increase_Num_Down")
	self._DoTweenPlayer_Scoredown = self._FightScoreDown:GetComponent(ClassType.DOTweenPlayer)

	self._FrameFSDetail = self:GetUIObject("Frame_FightScoreDetail")
	if self._FrameFSDetail~=nil then
		self._DTP_FSDetail = self._FrameFSDetail:GetComponent(ClassType.DOTweenPlayer)
	end

	self._FSDetailTipList = {}
	for i = 1, FS_DETAIL_ITEM_CNT do
		self._FSDetailTipList[i] = self:GetUIObject("FightScoreItem_"..i)
		--warn(" "..i.." FightScoreItem_"..i)
	end

	self._TableOrignalPos = 
	{
		_SimpleTextUP = self._SimpleTextTipTemplate.localPosition,
		_SimpleTextDown = self._BottomSimpleTextTipTemplate.localPosition,
		_IconText = self._IconAndTextTipTemplate.localPosition
	}

	self._MoveTextItem = self:GetUIObject('MoveTextItem')
	self._MoveTextFather = self:GetUIObject('Frame_MoveTextTips')
	self._MoveTextFather:SetActive(true)
	--self._LabAttention =  self:GetUIObject('LabAttention')
	--self._AttentionTip = self:GetUIObject("Frame_Attention_Tips")
	--self._ImgAttentionBoss = self: GetUIObject("Img_Boss")
	--self._ImgAttentionTips = self: GetUIObject("Img_Tips")

	self._ObjAchieve = self:GetUIObject("Frame_AchieveTips")
	if not IsNil(self._ObjAchieve) then
		self._ObjAchieve:SetActive(false)
	end

    self._ObjSpecialAchieve = self:GetUIObject("Frame_AchieveSpecialTips")
    if not IsNil(self._ObjSpecialAchieve) then
        self._ObjSpecialAchieve:SetActive(false)
    end

	self._FrameGuildDungeonTip = self:GetUIObject("Frame_Guild_DungeonTip")
	if not IsNil(self._FrameGuildDungeonTip) then
		self._FrameGuildDungeonTip:SetActive(false)
	end
	

	self._LabAchieve = self:GetUIObject("Lab_AchieveTips")
	self._AchieveIconBG = self:GetUIObject("AchieveIconBG")
	--self._BattleStgTip = self:GetUIObject("Frame_SkillTip")
	--self._BattleStgTxt = self:GetUIObject("Lab_SkillTip"):GetComponent(ClassType.Text)
	--self._BattleStg_TweenPlayer = self._BattleStgTip:GetComponent(ClassType.DOTweenPlayer)
	
	self._TableUpText = {} --所有上飘字
	self._TableDownText = {} -- 所有下飘字
	self._TableIconText = {} --所有带图标的飘字
	self._TableMoveText = {} --滚屏文字
end


local function RemoveMoveTextObj()
	if instance._TableMoveTextObj == nil or #instance._TableMoveTextObj <= 0 then return end

	for _,v in ipairs(instance._TableMoveTextObj) do
		if not IsNil(v) then
			v:Destroy()
		end
	end

	instance._TableMoveTextObj = nil
end


local function RemoveDownTimer()
	if instance._DownTipsTimer ~= 0 then
        _G.RemoveGlobalTimer(instance._DownTipsTimer)
        instance._DownTipsTimer = 0
    end	
end


local function RemoveMoveTextTimer()
	if instance._MoveTextTimer ~= 0 then
		_G.RemoveGlobalTimer(instance._MoveTextTimer)
        instance._MoveTextTimer = 0
	end
end


local function RemoveAchieveTimer()
	if instance._AchieveTimerID ~= 0 then
		_G.RemoveGlobalTimer(instance._AchieveTimerID)
        instance._AchieveTimerID = 0
	end
end

local function RemoveSpecialAchieveTimer()
    if instance._SpecialAchieveTimerID ~= 0 then
        _G.RemoveGlobalTimer(instance._SpecialAchieveTimerID)
        instance._SpecialAchieveTimerID = 0
    end
end

local function RemoveGuildDungeonTipTimer()
    if instance._GuildDungeonTipTimerID ~= 0 then
        _G.RemoveGlobalTimer(instance._GuildDungeonTipTimerID)
        instance._GuildDungeonTipTimerID = 0
    end
end

def.override("dynamic").OnData = function(self, data)
	if data ~= nil then 
		self._Model = data
	end

	if self._Model ~= nil then
		if self._Model.content ~= nil then
			self:ShowTipText()
		else
			self:ShowItemShortcut()
		end
	end

	self._Model = nil
end

local function IsContainDownText(strTips)
	if instance._TableDownText == nil then return false , -1 end

	for i,v in ipairs(instance._TableDownText) do
		if v._text == strTips then
			return true, i
		end
	end

	return false, -1
end

def.method().ShowTipText = function(self)
	if(self._Model.icon == nil) then -- 纯文字tip
		if(self._Model.use_up_obj) then
			self._TableUpText[#self._TableUpText + 1] = self._Model

			if(#self._TableUpText == 1) then
				self: SetTips(1,self._TableUpText[1])
			end		
		else
			--如果之前列表包含了提示，再次提醒，增加一点显示时间
			local isContain, index = IsContainDownText(self._Model.content)
			if isContain then
				local nTime = self._TableDownText[index]._time
				if  nTime < 2 then
					nTime = nTime + 0.3
					nTime = math.clamp(nTime,self._TableDownText[index]._time, 2)
					self._TableDownText[index]._time = nTime
				end
			return end

			--策划要求，提示队列限制长度，暂定为3.
			if #self._TableDownText > MAX_DOWNTIPS_COUNT then 
				self._IsIgnoreDownTips = true
			else
				self._IsIgnoreDownTips = false
			end

			if self._IsIgnoreDownTips then 
				if #self._TableDownText > 2 then
					for i = 2 ,MAX_DOWNTIPS_COUNT - 1 do
						if (i >= #self._TableDownText) or ( i + 1 > #self._TableDownText) then break end

						self._TableDownText[i] = self._TableDownText[i + 1]
					end
				end

				self._TableDownText[#self._TableDownText] = 
				{ 
					_text = self._Model.content,
					_time = 2,
				}
			return end

			self._TableDownText[#self._TableDownText + 1] = 
			{ 
				_text = self._Model.content,
				_time = 2,
			}

			if(#self._TableDownText == 1) then
				self: SetDownText()
			end
		end
	else
		self._TableIconText[#self._TableIconText + 1] = self._Model			
		if(#self._TableIconText == 1) then
			self: SetTips(3,self._TableIconText[1])
		end	
	end
end

def.method().SetDownText = function(self)
	if self._TableDownText == nil or #self._TableDownText <= 0 then return end

	RemoveDownTimer()
	self._BottomSimpleTextTipTemplate: SetActive(true)
	local tip_txt = self:GetUIObject("Lab_DownTips")
	if IsNil(tip_txt) then return end
	GUI.SetText(tip_txt, self._TableDownText[1]._text)

	if self._DownTipsTimer == 0 then
		local callback = function()
	 		local downData = self._TableDownText[1]               
			downData._time =  downData._time - 1
         	if downData._time <= 0 then
         		table.remove(self._TableDownText,1) 

         		if self._TableDownText == nil or #self._TableDownText <= 0 then
         			RemoveDownTimer()
         			self._TableDownText = {}
         			self._BottomSimpleTextTipTemplate: SetActive(false)
         		else
         			self: SetDownText()
         		end        	
         	end
        end

        self._DownTipsTimer = _G.AddGlobalTimer(2, false, callback)
	end
end

def.method("number","table").SetTips = function(self,nType,_model)
	if nType == 1 then --上	
		self._SimpleTextTipTemplate.localPosition = self._TableOrignalPos._SimpleTextUP
		local tip_txt = self._SimpleTextTipTemplate:FindChild("Lab_Tips")
		GUI.SetText(tip_txt, _model.content)
		self._SimpleTextTipTemplate: SetActive(true)
		local endPos = Vector3.New(self._TableOrignalPos._SimpleTextUP.x,self._TableOrignalPos._SimpleTextUP.y+25,self._TableOrignalPos._SimpleTextUP.z)
		GUITools.DoLocalMove(self._SimpleTextTipTemplate,endPos,0.8, nil,function()
 			table.remove(self._TableUpText,1)

        	if (#self._TableUpText > 0) then
            	self: SetTips(1,self._TableUpText[1])
        	else          			
           		self._TableUpText = {}
           		self._SimpleTextTipTemplate: SetActive(false)
        	end
   	 	end)
	elseif nType == 2 then -- 下
		self: SetDownText()
	elseif nType == 3 then --图标
		self._IconAndTextTipTemplate.localPosition = self._TableOrignalPos._IconText
		local tip_txt1 = self:GetUIObject("Lab_PicTips")
		GUI.SetText(tip_txt1, _model.content)
		local tip_txt2 = self:GetUIObject("Lab_PicNumber")
		GUI.SetText(tip_txt2, _model.param)
		GUITools.SetItemIcon(self:GetUIObject("Img_TipsItem"), _model.icon)
		local endPos = Vector3.New(self._TableOrignalPos._IconText.x,self._TableOrignalPos._IconText.y + 25,self._TableOrignalPos._IconText.z)
		self._IconAndTextTipTemplate: SetActive(true)
		GUITools.DoLocalMove(self._IconAndTextTipTemplate,endPos ,0.8, nil,function()
 			table.remove(self._TableIconText,1)

        	if (#self._TableIconText > 0) then
            	self: SetTips(3,self._TableIconText[1])
        	else         
           		self._TableIconText = {}
           		self._IconAndTextTipTemplate: SetActive(false)
        	end
    	end)
	end	
end


local function AddMoveObj(MoveData)
	if IsNil(instance._MoveTextItem) then return end
	if MoveData == nil then return end

	if instance._TableMoveTextObj == nil then
		instance._TableMoveTextObj = {}
	end

	local obj = nil
	local function AddNewObj()
	 	obj = GameObject.Instantiate(instance._MoveTextItem)
		if IsNil(obj) then
   			warn("add new MoveText Error")
   		return end	
   		obj:SetParent(instance._MoveTextFather)
   		obj.localScale = Vector3.one
		instance._TableMoveTextObj[#instance._TableMoveTextObj + 1] = obj
	end

	if #instance._TableMoveTextObj <= 0 then
		AddNewObj()
	else
		for _,v in ipairs(instance._TableMoveTextObj) do
			if not v.activeSelf then
				obj = v				
			end
		end
		if obj == nil then
			AddNewObj()
		end		
	end

	if IsNil(obj) then return end
	
	obj.localPosition = Vector3.zero   						
   	obj:SetActive(true)
  
	--纯文本
	if MoveData._Type == 1 then
		local textObj = obj: FindChild("moveText")
		if not IsNil(textObj) then
			GUI.SetText(textObj, MoveData._Text)
		end	

		local ItemObj = obj: FindChild("MoveItemIcon")
		if not IsNil(ItemObj) then
			ItemObj: SetActive(false)
		end

		local imove = obj: FindChild("MoveItem")
		if not IsNil(imove) then
			imove: SetActive(false)
		end
	elseif MoveData._Type == 2 then--带图标的道具
		local ItemObj = obj: FindChild("MoveItemIcon")
		if not IsNil(ItemObj) then
			ItemObj: SetActive(true)
		end

		local textObj = obj: FindChild("moveText")
		if not IsNil(textObj) then
			local strTips = ""
			if not MoveData._IsTokenMoney then
				local itemData = CElementData.GetItemTemplate(MoveData._ItemID)
				if itemData == nil or itemData.InitQuality == nil or itemData.TextDisplayName == nil or MoveData._Count == nil then
					warn("ShowMoveItemTextTips-->物品错误ID："..MoveData._ItemID)
					warn(debug.traceback())
					obj:SetActive(false)
				return end

				if itemData.InitQuality < 0 or itemData.InitQuality > 6 then
					warn("ShowMoveItemTextTips-->物品品质错误，ItemID："..MoveData._ItemID)
					warn("当前品质：",itemData.InitQuality)
					warn(debug.traceback())
					obj:SetActive(false)
				return end

				local itemName = "<color=#" .. EnumDef.Quality2ColorHexStr[itemData.InitQuality] ..">" .. itemData.TextDisplayName .." x "..GUITools.FormatMoney(MoveData._Count).."</color>"
	 			strTips  = string.format(StringTable.Get(507),itemName)
			else
				if MoveData._Count == nil then
					warn("ShowMoveItemTextTips-->货币数量错误")
					warn(debug.traceback())
					obj:SetActive(false)
				return end

				local CTokenMoneyMan = require "Data.CTokenMoneyMan"
				local itemName = CTokenMoneyMan.Instance():GetName(MoveData._ItemID).." x "..GUITools.FormatMoney(MoveData._Count)
				strTips = string.format(StringTable.Get(507),itemName)
			end
			
			GUI.SetText(textObj, strTips)
		end	
	
		if MoveData._IsTokenMoney then
			IconTools.InitTokenMoneyIcon(ItemObj, MoveData._ItemID, 0)
		else
			IconTools.InitItemIconNew(ItemObj, MoveData._ItemID)
		end
		
		local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
		local CPanelUIEquipProcess = require "GUI.CPanelUIEquipProcess"
		--开启背包page的时候。不显示飞行效果
		local bSkipFlyGfx = CPanelRoleInfo.Instance():IsCurTypePage(1) or CPanelUIEquipProcess.Instance():IsShow()
		if not bSkipFlyGfx then 
			--获得道具飞行
			local imove = obj: FindChild("MoveItem")
			if not IsNil(imove) then
				if MoveData._IsFly then
					imove.localPosition = MOVE_ITEM_POS
					imove.localScale = Vector3.one
					imove: SetActive(true)
					IconTools.InitItemIconNew(imove, MoveData._ItemID)
					local mainChat = require "GUI.CPanelMainChat"
					local endPos = mainChat.Instance():GetBagBtnPos()
					GameUtil.PlayUISfx(PATH.UIFX_ITEM_FLY,imove, instance._Panel, -1,20,1,function(gofly)
						gofly.parent = imove
						end)				
				
					GUITools.DoMove(imove,endPos, 0.5, nil, 0, function()
 						imove: SetActive(false)
 						GameUtil.PlayUISfx(PATH.UIFX_ITEM_END,imove, instance._Panel, -1)

 						CSoundMan.Instance():Play2DAudio(PATH.GUISound_Inventory_FlyGet, 0)
   	 				end)
				else
					imove: SetActive(false)
				end
			end	
		end 
	end
	
	GUITools.DoLocalMove(obj,MOVE_TEXT_POS,1.2, nil,function()
 		obj: SetActive(false) 		
	end)
end

-- 依次播放MoveText队列 
local function EnumMoveTextObjs(self)
    -- if #self._TableMoveText == 1 then
    -- 	RemoveMoveTextTimer()
    if self._MoveTextTimer == 0 then
        local callback = function()

            if #self._TableMoveText <= 0 then
                RemoveMoveTextTimer()
                -- warn("MoveTextTimer done")
                return
            end
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Msg_Get, 0)
            AddMoveObj(self._TableMoveText[1])
            table.remove(self._TableMoveText, 1)

            -- warn("MoveTextTimer Update "..#self._TableMoveText)
        end

        self._MoveTextTimer = _G.AddGlobalTimer(0.35, false, callback)
        --warn("_MoveTextTimer start "..self._MoveTextTimer)
    end
    -- end
end

--滚屏文字
def.method("string").MoveText = function(self,strTips)
	if self._TableMoveText == nil then
		self._TableMoveText = {}
	end
	
	self._TableMoveText[#self._TableMoveText + 1] = 
	{
		_Type = 1,
		_Text =	strTips,
		_IsTokenMoney = false,
		_ItemID = nil
	}

    EnumMoveTextObjs(self)
end

--滚屏物品
def.method("number","boolean","number", "boolean").MoveItemText = function (self,ItemID,isTokenMoney,nCount, isFly)
	if self._TableMoveText == nil then
		self._TableMoveText = {}
	end
	
	self._TableMoveText[#self._TableMoveText + 1] = 
	{
		_Type = 2,
		_Count =	nCount,
		_IsTokenMoney = isTokenMoney,
		_ItemID = ItemID,
        _IsFly = isFly
	}
    EnumMoveTextObjs(self)
end


def.method('string', 'function').ShowQuestChapterOpen = function(self, str, on_finish)
		if not IsNil(self._QuestChapterOpen) then
			self._QuestChapterOpen:SetActive(false)
			if self._QuestOpen_timer_id ~= 0 then
	        	_G.RemoveGlobalTimer(self._QuestOpen_timer_id)
	        	self._QuestOpen_timer_id = 0
	        	self:DoTipFinishCB()
	   		end

	    	if self._QuestOpen_timer_id == 0 then
	        	self._OnTipFinishCB = on_finish
	       		local callback = function()
	        	self:DoTipFinishCB()
	                self._QuestChapterOpen: SetActive(false)
	                _G.RemoveGlobalTimer(self._QuestOpen_timer_id)
	        		self._QuestOpen_timer_id = 0
	        	end
	        	self._QuestChapterOpen : SetActive(true)
	        	GUI.SetText(self._Lab_QuestChapterName, str)
                -- local hangPoint = self._QuestChapterOpen:FindChild("Img_Bg1")
                -- GameUtil.PlayUISfx(PATH.UIFX_MainTip_Mission_Success, hangPoint, hangPoint, -1)
	        	self._QuestOpen_timer_id = _G.AddGlobalTimer(3, true, callback)
	        	self._QuestChapterOpen_TweenPlayer:Restart(1)
	        	GameUtil.PlayUISfx(PATH.UIFX_XINZHANGJIEKAIQI, self._QuestChapterOpen, self._QuestChapterOpen, -1)
	        	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Chapter_Open, 0)
	    	end
		end
end

def.method().ShowItemShortcut = function(self)
--TODO
end

local function ShowKillInfo(self,data,item)
	if data == nil then return end
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	local imgHead = uiTemplate:GetControl(1)
	local labName = uiTemplate:GetControl(3)
	TeraFuncs.SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
	GUI.SetText(labName,data.Name)
end

-- 显示击杀
def.method("table").ShowKillTips = function(self,data)
	GameUtil.SetCanvasGroupAlpha(self._FrameKillTips, 1)
	local doTweenPlayer = self._FrameKillTips:GetComponent(ClassType.DOTweenPlayer)
    doTweenPlayer:Restart("21")
	self._FrameKillTips:SetActive(true)
	ShowKillInfo(self,data.KillData,self._FrameKiller)
	ShowKillInfo(self,data.DeathData,self._FrameDeath)
	local labTitle = self:GetUIObject("Lab_KillTitle")
	if data.HitNum < 3 then 
		labTitle:SetActive(false)
	elseif data.HitNum == 3 or data.HitNum == 4 then  
		labTitle:SetActive(true)
		GUI.SetText(labTitle,StringTable.Get(27016))
	elseif  data.HitNum == 5 or data.HitNum == 6 then 
		labTitle:SetActive(true)
		GUI.SetText(labTitle,StringTable.Get(27017))
	elseif  data.HitNum == 7 or data.HitNum == 8 then 
		labTitle:SetActive(true)
		GUI.SetText(labTitle,StringTable.Get(27018))
	elseif data.HitNum == 9 then 
		labTitle:SetActive(true)
		GUI.SetText(labTitle,StringTable.Get(27019))
	elseif data.HitNum >=10 then 
		labTitle:SetActive(true)
		GUI.SetText(labTitle,StringTable.Get(27020))
	end
end


def.override('string').OnClick = function(self, id)
	if id == 'Btn_Goto' then
		--game._GUIMan:Open("CPanelManual",)
		game._CManualMan._ManualOpenEId = self._ManualCurEId
		local data = 
		{
			_type = 2, 
			_info = 
			{
				_Tid = self._ManualCurEId
			}
		}
		game._GUIMan:Open("CPanelUIManual", data)
		--game._GUIMan:Open("CPanelUIManual", nil)
		--game._CManualMan:SendC2SManualDataSync()
	elseif id == "Btn_CheckAchieve" then
		local data = 
		{
			_type = 1, 
			_info = 
			{
				_Tid = self._TableAchieve[1]._Tid
			}
		}
		game._GUIMan:Open("CPanelUIManual", data)
    elseif id == "Btn_SpecialCheckAchieve" then
        local data = 
		{
			_type = 1, 
			_info = 
			{
				_Tid = self._TableSpecialAchieve[1]._Tid
			}
		}
		game._GUIMan:Open("CPanelUIManual", data)
	end
end
--[[

def.method("string","number","number").ShowAttention = function(self,strTips, nType, nTime)
	if not IsNil(self._AttentionTip) then
		self._AttentionTip: SetActive(true)
		
		if not IsNil(self._LabAttention) then
			GUI.SetText(self._LabAttention, strTips)
		end

		local function cb( ... )
			self._AttentionTip: SetActive(false)
		end

		if nType == EnumDef.AttentionTipeType._Simple then
			if not IsNil(self._ImgAttentionBoss) then
				self._ImgAttentionBoss: SetActive(false)
			end 

			if not IsNil(self._ImgAttentionTips) then
				self._ImgAttentionTips: SetActive(false)
			end
		elseif nType == EnumDef.AttentionTipeType._Boss then
			if not IsNil(self._ImgAttentionBoss) then
				self._ImgAttentionBoss: SetActive(true)
			end 

			if not IsNil(self._ImgAttentionTips) then
				self._ImgAttentionTips: SetActive(false)
			end

		elseif nType == EnumDef.AttentionTipeType._Tips then
			if not IsNil(self._ImgAttentionBoss) then
				self._ImgAttentionBoss: SetActive(false)
			end 

			if not IsNil(self._ImgAttentionTips) then
				self._ImgAttentionTips: SetActive(true)
			end
		else--无类型的默认没有图标
			if not IsNil(self._ImgAttentionBoss) then
				self._ImgAttentionBoss: SetActive(false)
			end 

			if not IsNil(self._ImgAttentionTips) then
				self._ImgAttentionTips: SetActive(false)
			end
		end

		GUITools.DoAlpha(self._LabAttention, 1,nTime, cb)  
	end
end

def.method().HideAttention = function(self)
	if not IsNil(self._AttentionTip) then
		self._AttentionTip: SetActive(false)
	end
end
]]

def.method("number", "number", "=>", "table").CalcValidValue = function(self, value, maxCount)
	local nums = {}
	local bCrossZero = false
	--计算有效数据
	for i=1, maxCount do
		local multiplier = (maxCount - i) + 1
		local result =  math.floor( ( value % (10^multiplier) ) / 10^(multiplier-1) )

		if bCrossZero then
			table.insert(nums, result)
		elseif result > 0 then
			table.insert(nums, result)
			bCrossZero = true
		end
	end

	return nums
end

def.method("number", "number", "=>", "number").CalcValidValueNumber = function(self, value, maxCount)
	local count = 0
	local bCrossZero = false
	--计算有效数据
	for i=1, maxCount do
		local multiplier = (maxCount - i) + 1
		local result =  math.floor( ( value % (10^multiplier) ) / 10^(multiplier-1) )

		if bCrossZero then
			
		elseif result > 0 then
			count = multiplier
			break
		end
	end

	return count
end

--def.method().ClearFightScoreTimer = function(self)
--	if self._FightScoreTimerID ~= 0 then
--		--warn("_FightScoreTimerID rem "..self._FightScoreTimerID)
--		_G.RemoveGlobalTimer(self._FightScoreTimerID)
--		self._FightScoreTimerID = 0
--	end
--end

--def.method("number", "number", "number").ShowFightScoreUp = function(self, oldValue, increaseValue, pos)
--	if not self:IsShow() then return end

--	if pos > 3 then pos = 3 end
--	local Item_Height = 45
--	if self._FightScoreHold~=nil then
--		self._FightScoreHold.localPosition = Vector3.New(0,Item_Height*pos,0)
--	end

--	self._FightScoreUp:SetActive(increaseValue > 0)
--	self._FightScoreDown:SetActive(increaseValue < 0)

--	local newValue = oldValue + increaseValue
--	if increaseValue > 0 then
--		GameUtil.StopUISfx(PATH.UIFX_FS_UP, self._FightScoreUp)

--		GUI.SetText(self._FightScoreNew, GUITools.FormatNumber(newValue))
--		GUI.SetText(self._FightScoreOld, GUITools.FormatNumber(oldValue))
--		GUI.SetText(self._FightScoreUpLab, GUITools.FormatNumber(increaseValue))
--		self._DoTweenPlayer_Scoreup:Restart(self._DT_GRP_FS_Show)

--		GameUtil.PlayUISfx(PATH.UIFX_FS_UP, self._FightScoreUp, self._FightScoreUp,-1)
--	else
--		GameUtil.StopUISfx(PATH.UIFX_FS_DOWN, self._FightScoreDown)

--		GUI.SetText(self._FightScoreNewDown, GUITools.FormatNumber(newValue))
--		GUI.SetText(self._FightScoreOldDown, GUITools.FormatNumber(oldValue))
--		GUI.SetText(self._FightScoreDownLab, GUITools.FormatNumber(increaseValue))
--		self._DoTweenPlayer_Scoredown:Restart(self._DT_GRP_FS_Close)

--		GameUtil.PlayUISfx(PATH.UIFX_FS_DOWN, self._FightScoreDown, self._FightScoreDown,-1)
--	end
--end

--------------FS DETAIL<<

local EvtGroupName_FS_DETAIL = "FSDetail"

def.method("boolean").OnFightScoreRestart = function(self, is_up)
	if not self:IsShow() then return end

	self._FightScoreUp:SetActive(is_up)
	self._FightScoreDown:SetActive(not is_up)
	if is_up then
		self._FightScoreUp.localScale = Vector3.one
		--GameUtil.StopUISfx(PATH.UIFX_FS_UP_2, self._FightScoreUp)
		--GameUtil.StopUISfx(PATH.UIFX_FS_UP, self._FightScoreUp)
		--GameUtil.StopUISfx(PATH.UIFX_FS_OVER, self._FightScoreUp)
		self._DoTweenPlayer_Scoreup:Stop(_DT_GRP_FS_Show)
		self._DoTweenPlayer_Scoreup:Stop(_DT_GRP_FS_Close)

	else
		self._FightScoreDown.localScale = Vector3.one
		--GameUtil.StopUISfx(PATH.UIFX_FS_DOWN_2, self._FightScoreDown)
		--GameUtil.StopUISfx(PATH.UIFX_FS_DOWN, self._FightScoreDown)
		--GameUtil.StopUISfx(PATH.UIFX_FS_OVER, self._FightScoreDown)
		self._DoTweenPlayer_Scoredown:Stop(_DT_GRP_FS_Show)
		self._DoTweenPlayer_Scoredown:Stop(_DT_GRP_FS_Close)
	end
end

def.method("number", "number", "boolean").ShowFightScore = function(self, oldValue, increaseValue, is_up)
	if not self:IsShow() then return end

	local newValue = oldValue + increaseValue
	if is_up then
		GUI.SetText(self._FightScoreNew, GUITools.FormatNumber(newValue))
		GUI.SetText(self._FightScoreOld, GUITools.FormatNumber(oldValue))
		GUI.SetText(self._FightScoreUpLab, GUITools.FormatNumber(increaseValue))
		self._DoTweenPlayer_Scoreup:Restart(_DT_GRP_FS_Show)

		GameUtil.PlayUISfx(PATH.UIFX_FS_UP_2, self._FightScoreUp, self._FightScoreUp, -1)
		self:AddEvt_PlayFx(EvtGroupName_FS_DETAIL, 0.6, PATH.UIFX_FS_UP, self._FightScoreUp, self._FightScoreUp, 1, 1)
	else
		GUI.SetText(self._FightScoreNewDown, GUITools.FormatNumber(newValue))
		GUI.SetText(self._FightScoreOldDown, GUITools.FormatNumber(oldValue))
		GUI.SetText(self._FightScoreDownLab, GUITools.FormatNumber(increaseValue))
		self._DoTweenPlayer_Scoredown:Restart(_DT_GRP_FS_Show)

		--GameUtil.PlayUISfx(PATH.UIFX_FS_DOWN_2, self._FightScoreDown, self._FightScoreDown, -1)
		self:AddEvt_PlayFx(EvtGroupName_FS_DETAIL, 0.6, PATH.UIFX_FS_DOWN, self._FightScoreDown, self._FightScoreDown, 1, 1)
	end
end

def.method("boolean").CloseFightScore = function(self, is_up)
	if not self:IsShow() then return end

	if is_up then
		self._DoTweenPlayer_Scoreup:Restart(_DT_GRP_FS_Close)
		--GameUtil.PlayUISfx(PATH.UIFX_FS_OVER, self._FightScoreUp, self._FightScoreUp, -1)
		self:AddEvt_PlayFx(EvtGroupName_FS_DETAIL, 1.8, PATH.UIFX_FS_OVER, self._FightScoreUp, self._FightScoreUp, 1, 1)
	else
		self._DoTweenPlayer_Scoredown:Restart(_DT_GRP_FS_Close)
		--GameUtil.PlayUISfx(PATH.UIFX_FS_OVER, self._FightScoreDown, self._FightScoreDown, -1)
		self:AddEvt_PlayFx(EvtGroupName_FS_DETAIL, 1.8, PATH.UIFX_FS_OVER, self._FightScoreDown, self._FightScoreDown, 1, 1)
	end
end

local function FSProp2Name(prop_type)
	local data = CElementData.GetTemplate("FightPropertyConfig", prop_type)
	if data == nil then return nil end
	return data.AttrName
end

local function ShowFightScoreDetailStep(self, start_id, count)
	--warn("ShowFightScoreDetailStep")

	if not self:IsShow() then return end

	if self._FSDetailMsg == nil then return end
	for m = 1, count do
		local g_item=self._FSDetailTipList[m]
		if g_item ~=nil then
			GameUtil.StopUISfx(PATH.UIFX_FS_DETAIL, g_item)

			if m+start_id-1 > #self._FSDetailMsg then
				GUITools.SetUIActive(g_item, false)
				--warn("Hide "..m..", "..(m+start_id-1)..", "..g_item.name)
			else
				local msg=self._FSDetailMsg[m+start_id-1]
				GUITools.SetUIActive(g_item, true)
				local uiTemplate = g_item:GetComponent(ClassType.UITemplate)
				if uiTemplate~=nil then
					local lab_n = uiTemplate:GetControl(0)
					local lab_a = 	uiTemplate:GetControl(1)
					local lab_b = uiTemplate:GetControl(2)
					local img_up =  uiTemplate:GetControl(3)
					local img_down =  uiTemplate:GetControl(4)

					--warn("Show "..m..", "..(m+start_id-1)..", "..g_item.name)

					GUI.SetText(lab_n, FSProp2Name(msg["type"]))
					GUI.SetText(lab_a, GUITools.FormatNumber(msg["a"], false, 7))
					GUI.SetText(lab_b, GUITools.FormatNumber(msg["b"], false, 7))

					if msg.a > msg.b then
						GUITools.SetUIActive(img_up, false)
						GUITools.SetUIActive(img_down, true)
					else
						GUITools.SetUIActive(img_down, false)
						GUITools.SetUIActive(img_up, true)
						--GameUtil.PlayUISfx(PATH.UIFX_FS_DETAIL, g_item, self._FrameFSDetail,-1)
					end
				end
				
				local delay=(m-1)*0.2
				self:AddEvt_PlayFx(EvtGroupName_FS_DETAIL, delay, PATH.UIFX_FS_DETAIL, g_item, g_item, 1, 1)
			end
		end
	end

	if self._DTP_FSDetail~=nil then
		self._DTP_FSDetail:Restart(_DT_GRP_FS_DETAIL)
	end

end

def.method().CloseFSDetails = function(self)
--	if self._FSDetailTimer > 0 then
--		--warn("RemoveGlobalTimer "..self._FSDetailTimer,debug.traceback())
--		_G.RemoveGlobalTimer(self._FSDetailTimer)
--		self._FSDetailTimer = 0
--	end
	self:KillEvts(EvtGroupName_FS_DETAIL)
        self._FSDetailMsg = nil
end

local start_id = 1
local is_fs_up = false
def.method("number","number","table").ShowFightScoreDetail = function(self, oldValue, increaseValue, msg_table)
	--warn("ShowFightScoreDetail")
	--if msg_table == nil then return end

        if not self:IsShow() then return end
        if self._FrameFSDetail == nil then return end

	self:CloseFSDetails()

	is_fs_up = increaseValue > 0
	self:OnFightScoreRestart(is_fs_up)
	self:ShowFightScore(oldValue, increaseValue, is_fs_up)

	--warn("Set Table "..tostring(msg_table),debug.traceback())
	self._FSDetailMsg = msg_table

	start_id = 1
	if self._FSDetailMsg~=nil and start_id <= #self._FSDetailMsg then
		--warn("start_id "..start_id)
		--ShowFightScoreDetailStep(self, start_id, FS_DETAIL_ITEM_CNT)
		--start_id = start_id + FS_DETAIL_ITEM_CNT

		for i= 1,FS_DETAIL_ITEM_CNT do
			local g_item=self._FSDetailTipList[i]
			GUITools.SetUIActive(g_item, false)
		end

	        self._FrameFSDetail:SetActive(true)
		self._DTP_FSDetail:Stop(_DT_GRP_FS_DETAIL)
		--self._DTP_FSDetail:GoToEndPos(_DT_GRP_FS_DETAIL)

		local function StartPopFSDetail()
                        if not self:IsShow() then return end
                        if self._FrameFSDetail == nil then return end

			--warn("StartPopFSDetail")
			--self._FSDetailTimer = _G.AddGlobalTimer(FS_DETAIL_TICK, false, function()
					--if self._FSDetailTimer == 0 then return end
					if self._FSDetailMsg==nil or start_id > #self._FSDetailMsg then
						--_G.RemoveGlobalTimer(self._FSDetailTimer)
						--warn("RemoveGlobalTimer 2 "..self._FSDetailTimer..", "..start_id ,debug.traceback())

						--self._FSDetailTimer = 0
						self._FSDetailMsg = nil
						self._FrameFSDetail:SetActive(false)
					else
						--warn("ShowFightScoreDetailStep start_id "..start_id..", "..#self._FSDetailMsg)
						ShowFightScoreDetailStep(self, start_id, FS_DETAIL_ITEM_CNT)
						start_id = start_id + FS_DETAIL_ITEM_CNT

						if start_id > #self._FSDetailMsg then
							--warn("CloseFightScore "..start_id..", "..#self._FSDetailMsg)
							self:CloseFightScore(is_fs_up)
						end

						self:AddEvt_LuaCB(EvtGroupName_FS_DETAIL, FS_DETAIL_TICK, StartPopFSDetail)
					end
				--end)
			--warn("AddGlobalTimer "..self._FSDetailTimer)
			--warn("StartPopFSDetail end")
		end

		self:AddEvt_LuaCB(EvtGroupName_FS_DETAIL, 0.7, StartPopFSDetail)
	else
		local function StartPopFSDetail2()
			self:CloseFightScore(is_fs_up)
		end

		self:AddEvt_LuaCB(EvtGroupName_FS_DETAIL, 0.7, StartPopFSDetail2)
	end

end

-------------->>FS DETAIL

--[[
-- old function 2018-10-09

def.method("number", "number").ShowFightScoreUp = function(self, oldValue, increaseValue)
	if IsNil(self._FightScoreUp) then return end
	--if self._FightScoreRunning then return end
	if self._FightScoreRunning then
		self:PopFightScoreTips(true)
	end

	self._FightScoreRunning = true
	self._FightScoreUp:SetActive(true)
	GUI.SetText(self._FightScoreUpLab, tostring(increaseValue))

	--计算有效数据
	local nums = self:CalcValidValue(oldValue, self._FightScoreNumMax)
	local newNums = self:CalcValidValueNumber(oldValue + increaseValue, self._FightScoreNumMax)

	--有效数据个数
	local resultCount = newNums
	local oldCount = #nums

	for i=1, #self._FightScoreNum do
		local obj = self._FightScoreNum[i]
		obj:SetActive(i <= resultCount)

		if i <= oldCount then
			local valIdx = oldCount - i + 1
			GUI.SetText(obj, tostring(nums[valIdx]))
		elseif i <= resultCount then
			GUI.SetText(obj, "0")
		end
	end

	--self: ClearFightScoreTimer()
	--warn("self._FightScoreTimerID "..self._FightScoreTimerID)
	self._FightScoreTimerID = _G.AddGlobalTimer(0.2, true, function()
		self:ValueIncFunction(oldValue, increaseValue)
		--warn("_FightScoreTimerID end "..self._FightScoreTimerID.." "..newNums)
		self._FightScoreTimerID = 0
	end)
	--warn("_FightScoreTimerID start "..self._FightScoreTimerID)
end
]]

def.method("string","string","number").ShowFindManualTips = function(self, tipsStr, tipsTit,eId)

    if self._ManualTipsBG == nil then return end
    if self._ManualTipsList == nil then
    	self._ManualTipsList = {}
    end

    self._ManualTipsList[#self._ManualTipsList+1] = {_tipsStr=tipsStr,_tipsTit=tipsTit,_eId=eId}

    if self._ManualTipsTimerId  == 0 then
    	self:PlayManualTips()
    end

end

def.method().PlayManualTips = function(self)
	if IsNil(self._ManualTipsBG) then return end
	if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Manual) then return end
    self._ManualCurEId = self._ManualTipsList[1]._eId
	self._ManualTipsBG:SetActive(true)
	GUI.SetText(self._ManualTipsLab, self._ManualTipsList[1]._tipsStr)
	GUI.SetText(self._ManualTipsTitle, self._ManualTipsList[1]._tipsTit)

	self._ManualTipsTimerId = _G.AddGlobalTimer(2, true, function()
		if not IsNil(self._ManualTipsBG) then
			self._ManualTipsBG:SetActive(false)
		end

		table.remove(self._ManualTipsList,1)
		if #self._ManualTipsList > 0 then
				self:PlayManualTips()
		end
		self._ManualTipsTimerId = 0
		self._ManualCurEId = 0
	end)
end

def.method().RemoveManualTipsTimer = function(self)
	if self._ManualTipsTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._ManualTipsTimerId)
        self._ManualTipsTimerId = 0
    end	
end

local function ShowAchieve( )
	if IsNil(instance._ObjAchieve) then return end
	RemoveAchieveTimer()
	instance._ObjAchieve:SetActive(true)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_AchieveGot, 0)
	if not IsNil(instance._AchieveIconBG) then
		GameUtil.PlayUISfx(PATH.UIFX_ACHIEVE, instance._AchieveIconBG, instance._Panel, -1)
	end

	--warn("ShowAchieve!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	GUI.SetText(instance._LabAchieve, instance._TableAchieve[1]._Tips)
	if instance._AchieveTimerID == 0 then
		instance._AchieveTimerID = _G.AddGlobalTimer(2, true, function()
			if not IsNil(instance._ObjAchieve) then
				instance._ObjAchieve:SetActive(false)
			end

			table.remove(instance._TableAchieve,1)
			if #instance._TableAchieve > 0 then
				ShowAchieve()
			end
			instance._AchieveTimerID = 0
		end)
	end
end

local function ShowSpecialAchieve()
    if IsNil(instance._ObjSpecialAchieve) then return end
    local achi_temp = CElementData.GetTemplate("Achievement", instance._TableSpecialAchieve[1]._Tid)
    if achi_temp == nil then
        warn("error !!!! 完成的成就ID错误，ID： ", instance._TableSpecialAchieve[1]._Tid)
    end
    instance._ObjSpecialAchieve:SetActive(true)
    local uiTemplate = instance._ObjSpecialAchieve:GetComponent(ClassType.UITemplate)
    local lab_achieve = uiTemplate:GetControl(0)
    local img_icon = uiTemplate:GetControl(1)
    GUI.SetText(lab_achieve, instance._TableSpecialAchieve[1]._Tips)
    GUITools.SetIcon(img_icon, achi_temp.IconPath)

    local do_tween_player = instance._ObjSpecialAchieve:GetComponent(ClassType.DOTweenPlayer)
    if do_tween_player then
        do_tween_player:Restart("color02")
    end
    GameUtil.PlayUISfx(PATH.UIFX_MainTip_AchievementSpecial, instance._ObjSpecialAchieve, instance._ObjSpecialAchieve, -1)
    RemoveSpecialAchieveTimer()
	instance._SpecialAchieveTimerID = _G.AddGlobalTimer(3, true, function()
		if not IsNil(instance._ObjSpecialAchieve) then
			instance._ObjSpecialAchieve:SetActive(false)
		end
        RemoveSpecialAchieveTimer()
		table.remove(instance._TableSpecialAchieve,1)
		if #instance._TableSpecialAchieve > 0 then
			ShowSpecialAchieve()
		end
	end)
end

-- 显示公会战场消息
def.method("string").ShowGuildBFBaseTip = function(self, tipStr)
    if self._FrameGuildBaseTip ~= nil then
        local lab_str = self._FrameGuildBaseTip:FindChild("LabAttention")
        GUI.SetText(lab_str, tipStr)
        self._FrameGuildBaseTip:SetActive(true)
        local callback = function()
            self._FrameGuildBaseTip:SetActive(false)
        end
        GUITools.DoAlpha(lab_str, 1, 3, callback)  
    end
end

-- 显示公会战场推塔消息
def.method("boolean", "string").ShowGuildBFTwerTip = function(self, isRed, tipStr)
    if self._FrameGuildTwerTip ~= nil then
        local lab_str = self._FrameGuildTwerTip:FindChild("LabAttention")
        GUI.SetText(lab_str, tipStr)
        GUITools.SetGroupImg(self._FrameGuildTwerTip, isRed and 0 or 1)
        self._FrameGuildTwerTip:SetActive(true)
        local callback = function()
            self._FrameGuildTwerTip:SetActive(false)
        end
        GUITools.DoAlpha(lab_str, 1, 3, callback)  
    end
end

def.method("string","number").ShowAchieveTips = function(self, tipsStr, nTid)
	if IsNil(self._ObjAchieve) then
		warn("IsNil")
	return end

	if self._TableAchieve == nil then 
		self._TableAchieve = {}
	end

	self._TableAchieve[#self._TableAchieve + 1] =
	{
		_Tips = tipsStr,
		_Tid = nTid
	}

	--没有数据的时候显示，有的话等序列
	if self._AchieveTimerID == 0 then
		ShowAchieve()
	end	
end

def.method("string","number").ShowSpecialAchieveTips = function(self, tipsStr, tid)
    if IsNil(self._ObjSpecialAchieve) then
        warn("_ObjSpecialAchieve is nil !!!")
    end
    if self._TableSpecialAchieve == nil then
        self._TableSpecialAchieve = {}
    end
    self._TableSpecialAchieve[#self._TableSpecialAchieve + 1] =
    {
        _Tips = tipsStr,
        _Tid = tid
    }
    --没有数据的时候显示，有的话等序列
	if self._SpecialAchieveTimerID == 0 then
		ShowSpecialAchieve()
	end	
end

-- 公会防守提示
def.method("string").ShowFrameGuildDungeonTip = function(self, tipsStr)
	if IsNil(self._FrameGuildDungeonTip) then
        warn("FrameGuildDungeonTip is nil !!! Cannot display: "..tipsStr)
        return
    end

    self._FrameGuildDungeonTip:SetActive(true)
    local uiTemplate = self._FrameGuildDungeonTip:GetComponent(ClassType.UITemplate)
    local lab_achieve = uiTemplate:GetControl(0)
	GUI.SetText(lab_achieve, tipsStr)
	
	if self._GuildDungeonTipTimerID == 0 then
		self._GuildDungeonTipTimerID = _G.AddGlobalTimer(2, true, function()
			if not IsNil(self._FrameGuildDungeonTip) then
				self._FrameGuildDungeonTip:SetActive(false)
			end
			self._GuildDungeonTipTimerID = 0
		end)
	end
end

def.method("number", "=>", "table").GetMoveObjectInfo = function (self, index)
	if self._MoveObject[index] == nil then
		self._MoveObject[index] = {}

		local numObj = self._FightScoreNum[index]
		local size = GUITools.GetUiSize(numObj)

		local obj = GameObject.Instantiate( numObj )
		obj:SetParent( numObj.parent )
		obj.localScale = Vector3.New(1,1,1)

		local pos = numObj.localPosition
		pos.y = pos.y - size.Height
		obj.localPosition = pos

		self._MoveObject[index].Up = numObj
		self._MoveObject[index].Below = obj

		self._MoveObject[index].OrignalObj = numObj
		self._MoveObject[index].OrignalPosition = numObj.localPosition
		self._MoveObject[index].Height = size.Height
		self._MoveObject[index].OffsetY = size.Height / 3
	end

	do
		local info = self._MoveObject[index]
		if info.Below.localPosition.y >= info.OrignalPosition.y then
			local tmp = {}
			tmp.Up = info.Below
			tmp.Below = info.Up

			tmp.OrignalObj = info.OrignalObj
			tmp.OrignalPosition = info.OrignalPosition
			tmp.Height = info.Height
			tmp.OffsetY = info.OffsetY
			
			tmp.Up.localPosition = tmp.OrignalPosition
			local pos = tmp.Up.localPosition
			pos.y = pos.y - tmp.Height
			tmp.Below.localPosition = pos

			self._MoveObject[index] = tmp
		end
	end

	return self._MoveObject[index]
end

--数字滚动增加的方法
def.method("number", "number").ValueIncFunction = function(self, oldValue, increaseValue)

	--计算有效数据
	local nums = 0 
	
	--判断是否需要进位
	local oldNums = self:CalcValidValue(oldValue, self._FightScoreNumMax)
	local newNums = self:CalcValidValue(oldValue + increaseValue, self._FightScoreNumMax)

	if #newNums > #oldNums then
		nums = #newNums
	else
		for i=1, #newNums do
			if newNums[i] ~= oldNums[i] then
				nums = (#newNums - i) + 1
				break
			end
		end
	end

	--warn("nums", nums)

	--有效数据个数
	local resultCount = nums

	local interval = {}
	for i=1, resultCount do
		interval[i] = 0
	end

	local function moveReal( objInfoIndex, newValue )
		local info = self:GetMoveObjectInfo( objInfoIndex )

		if interval[objInfoIndex] == 1 then 

			local upText = info.Up:GetComponent(ClassType.Text)
			local upVal = tonumber( upText.text )

			local belowText = info.Below
			
			local newVal = upVal + 1
			if newVal >= 10 then
			 	newVal = newVal % 10
			end

			--滑动
			local up = info.Up
			local below = info.Below

			local p = up.localPosition
			p.y = p.y + info.OffsetY
			up.localPosition = p

			p.y = p.y - info.Height
			below.localPosition = p
			GUI.SetText(belowText, tostring(newVal))
		elseif interval[objInfoIndex] == 2 then

			local item = self._MoveObject[objInfoIndex]

			if item.Up and item.Below then
				if item.OrignalObj.localPosition.y ~= item.Up.localPosition.y then
					--Object.Destroy( item.Up )
					item.Up:SetActive(false)
				else
					--Object.Destroy( item.Below )
					item.Below:SetActive(false)
				end

				local infoText = item.OrignalObj
				GUI.SetText(infoText, tostring(newValue))

				item.OrignalObj.localPosition = item.OrignalPosition
			end
		end
	end

	local lastTick = 0
	local tickCount = 0
	local reverse = false

	local changeValue = 20 * 3			--大约3秒完成
	local newValue = 0
	local function funcMoveReal()
		newValue = newValue + 1

		local move = false
		tickCount = tickCount + 1
		if lastTick + 3 < tickCount then
			lastTick = tickCount
			move = true
		end

		if newValue >= changeValue then				--到达目标值，停止timer

			if self._FightScoreRunTimerId ~= 0 then
				--warn("_FightScoreRunTimerId end "..self._FightScoreRunTimerId)
				_G.RemoveGlobalTimer( self._FightScoreRunTimerId )
				self._FightScoreRunTimerId = 0
			end
			self:PopFightScoreTips( false )
		end

		local targetValue = oldValue + increaseValue
		for i=1, resultCount do
			local multiplier = i
			local result =  math.floor( ( targetValue % (10^multiplier) ) / 10^(multiplier-1) )

			if not reverse and move and interval[i] == 0 then
				interval[i] = 1
				--warn("KKK", resultCount, i)
				move = false
			end

			if not reverse and interval[resultCount] == 1 then
				reverse = true
			end

			local k = resultCount - i + 1
			if reverse and move and interval[k] == 1 then
				interval[k] = 2
				--warn("MMM", resultCount, k)
				move = false
			end

			moveReal(i, result)
		end

	end

	--warn("self._FightScoreRunTimerId "..self._FightScoreRunTimerId)
	self:RemoveScoreRunningTimer()
	self._FightScoreRunTimerId = _G.AddGlobalTimer(0.05, false, funcMoveReal)
	--warn("_FightScoreRunTimerId start "..self._FightScoreRunTimerId)
end

def.method().ClearPopFightScoreTimer = function(self)
	if self._PopFightScoreTimerID ~= 0 then
		--warn("_PopFightScoreTimerID rem "..self._PopFightScoreTimerID)
		_G.RemoveGlobalTimer(self._PopFightScoreTimerID)
		self._PopFightScoreTimerID = 0
	end
end

def.method("boolean").PopFightScoreTips = function(self, bIsRunning)
	local function DoPop()
		if not IsNil(self._FightScoreUp) then
			self._FightScoreUp:SetActive(false)
			-- self:DestroyMoveObjects()
		end
		if not IsNil(self._FightScoreDown) then
			self._FightScoreDown:SetActive(false)
			-- self:DestroyMoveObjects()
		end
		self._FightScoreRunning = false
		self._PopFightScoreTimerID = 0
	end

	self: ClearPopFightScoreTimer()
	if bIsRunning then
		DoPop()
	else
		self._PopFightScoreTimerID = _G.AddGlobalTimer(0.2, true, function()
		--warn("_PopFightScoreTimerID end "..self._PopFightScoreTimerID)
			DoPop()
		end)
	end
end

def.method().DestroyMoveObjects = function(self)
	for i=1, #self._MoveObject do
		local item = self._MoveObject[i]
		if item.Up and item.Below then
			if item.OrignalObj.localPosition.y ~= item.Up.localPosition.y then
				Object.Destroy( item.Up )
			else
				Object.Destroy( item.Below )
			end
		end

		item.OrignalObj.localPosition = item.OrignalPosition
	end
	self._MoveObject = {}
 end

def.method().RemoveScoreRunningTimer = function(self)
	if self._FightScoreRunTimerId ~= 0 then
		--warn("_FightScoreRunTimerId rem "..self._FightScoreRunTimerId)
		_G.RemoveGlobalTimer( self._FightScoreRunTimerId )
		self._FightScoreRunTimerId = 0
	end
end

def.field("function")._OnTipFinishCB = nil
def.method().DoTipFinishCB = function(self)
    if self._OnTipFinishCB ~= nil then
        self._OnTipFinishCB()
        self._OnTipFinishCB = nil
    end
end

--[[
--副本中的消息提示
local DUR_BATTLESTG = 2	--tip time
local EvtGroupName_SkillTip = "PopBattleStgTip"
local function CloseBattleStgTip()
	if not IsNil(CPanelMainTips.Instance()._BattleStgTip) then
		--warn("CloseBattleStgTip")
		CPanelMainTips.Instance()._BattleStgTip:SetActive(false)
	end
end

def.method("string","number").PopSkillTip = function(self, content, dur)
	--warn("PopBattleStgTip "..stg_type..", "..content..", "..dur)
	if not self:IsShow() then return end
	if not IsNil(self._BattleStgTip) then
		self._BattleStgTip:SetActive(true)

		if self._BattleStgTxt ~= nil then
			--if stg_type > 0 and stg_type < EnumDef.BattleStgType.Total then
				--if stg_type == EnumDef.BattleStgType.Concentrate then
					self._BattleStgTxt.text = content
				--end
			--end
		end

		self:KillEvts(EvtGroupName_SkillTip)
		self:AddEvt_PlayDotween(EvtGroupName_SkillTip, 0, self._BattleStg_TweenPlayer, self._DoTweenID_BattleStg1)
		self:AddEvt_PlayDotween(EvtGroupName_SkillTip, dur + 0.2, self._BattleStg_TweenPlayer, self._DoTweenID_BattleStg2)
		self:AddEvt_LuaCB(EvtGroupName_SkillTip, dur + 0.4, CloseBattleStgTip)
	end
end

def.method().CloseSkillTip = function(self)
	self:KillEvts(EvtGroupName_SkillTip)
	CloseBattleStgTip()
end
]]

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	--self:CloseSkillTip()

	self:CloseFSDetails()

	if self._FrameFSDetail ~= nil then
		self._FrameFSDetail:SetActive(false)
	end
end

def.override().OnDestroy = function(self)
    RemoveAchieveTimer()
    RemoveSpecialAchieveTimer()
	self:DestroyMoveObjects()
	self:RemoveScoreRunningTimer()
	self._FightScoreHold = nil
	self._FightScoreUp = nil 					-- 战斗力提升
	self._FightScoreNum = nil					-- 战斗力显示的Lab
	self._FightScoreUpLab = nil  				-- 战斗力提升Label
	self._FightScoreRunning = false				-- 数字移动模块开启状态
	self._IsIgnoreDownTips = false				--是否忽略下提示
    self._FrameGuildBaseTip = nil
    self._FrameGuildTwerTip = nil
    self._FightScoreOld = nil
	self._FightScoreNew = nil
	self._FightScoreDown = nil
	self._FightScoreOldDown = nil
	self._FightScoreNewDown = nil
	self._FightScoreDownLab = nil
	self._FrameFSDetail = nil
	self._DTP_FSDetail = nil
	self._ManualTipsTitle = nil
	self._ObjSpecialAchieve = nil
	self._FrameKillTips = nil
	self._FrameKiller = nil
	self._FrameDeath = nil
	self._DoTweenPlayer_Scoreup = nil
	self._DoTweenPlayer_Scoredown = nil

	RemoveDownTimer()
	RemoveMoveTextTimer()
	RemoveMoveTextObj()
	self:RemoveManualTipsTimer()
	--self: ClearFightScoreTimer()
	self: ClearPopFightScoreTimer()
	self._TableUpText = {} --所有上飘字
	self._TableDownText = {} -- 所有下飘字
	self._TableIconText = {} --所有带图标的飘字
--	self._TableMoveText = {} --滚屏文字

	self._SimpleTextTipTemplate = nil
	self._BottomSimpleTextTipTemplate = nil
	self._IconAndTextTipTemplate = nil
	self._ManualTipsBG = nil
	self._ManualTipsLab = nil
	self._MoveTextItem = nil
	self._MoveTextFather = nil
--	self._AttentionTip = nil
--	self._LabAttention = nil
--	self._ImgAttentionBoss = nil
--	self._ImgAttentionTips = nil
    self._TableSpecialAchieve = nil
    self._TableAchieve = nil
	self._ObjAchieve = nil
	self._LabAchieve = nil
	self._AchieveIconBG = nil

	self._QuestChapterOpen = nil
	self._QuestChapterOpen_TweenPlayer = nil
	self._Lab_QuestChapterName = nil	
	self._FrameGuildDungeonTip = nil
	RemoveGuildDungeonTipTimer()
end

def.override("=>", "boolean").IsCountAsUI = function(self)
    return false
end

CPanelMainTips.Commit()
return CPanelMainTips