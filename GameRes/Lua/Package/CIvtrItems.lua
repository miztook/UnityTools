local Lplus = require "Lplus"
local ItemComponent = require "Package.ItemComponents"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local EItemEventType = require"PB.data".EItemEventType
local GUITools = require "GUI.GUITools"
local BagType = require "PB.net".BAGTYPE
local bit = require "bit"
local EEquipmentSlot = require "PB.Template".Item.EquipmentSlot
local CEquipUtility = require "EquipProcessing.CEquipUtility"

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

--[[----------------------------------
--- 以下顺序需要与服务器端定义保持一致
------------------------------------]]
local SubItemType =
{
	NormalItem 		= 0, 	-- 普通物品
	Equipment 	 	= 1, 	-- 装备
	Material   		= 2,	-- 材料
	Potion     		= 3, 	-- 药品
	QuestItem  		= 4, 	-- 任务
	Rune 	   		= 5,    -- 符文
	Horse      		= 6,	-- 坐骑
	TreasureBox		= 7,	-- 宝箱
	Pet  			= 8,	-- 宠物蛋
	Charm 			= 9,	-- 神符-宝石
	PetExpPotion    = 10,   -- 经验药水
	Wing 			= 11,  	-- 翅膀
	Dress 			= 12, 	-- 时装
	Wanted          = 13,   -- 讨伐令
	PetTalentBook 	= 14;   -- 宠物被动技能书
	EnchantReel     = 15,   -- 附魔卷轴
	Pray 			= 16,   -- 月光庭院
	--EngravingStone  = 17,   -- 刻纹石
	Evil	   		= 18;   -- 赎罪卷
	InforceStone 	= 19;   -- 强化石
	LuckyStone 		= 20;	-- 幸运符
	SafeStone   	= 21;   -- 保底石
	RebuildStore 	= 22;   -- 重铸材料
	TalentChange 	= 23;   -- 被动技能转化材料
	RefineStore 	= 24; 	-- 精炼材料
	HotTime         = 25;   -- HotTime道具
	BagExtend       = 26;   -- 背包扩展
}

--[[----------------------
--    父类CIvtrItem
-------------------------]]
local CIvtrItem = Lplus.Class("CIvtrItem")
do
	local def = CIvtrItem.define

	local CANNOT_USE_REASON = 
	{
		REASON_UNKNOWN        = -1,  
		REASON_LEVEL          = 0, 		  -- 级别不满足
		REASON_PROFESSION     = 1,        -- 职业不满足
		REASON_CMN_COUNT      = 2,	      -- 使用次数超出限制
		REASON_FIGHTING       = 3,        -- 战斗中不能使用
		REASON_TASK_LIMIT     = 4,        -- 任务限制
		REASON_SCENE_LIMIT    = 5,        -- 场景限制
		REASON_INSTANCE_LIMIT = 6,        -- 副本限制
		REASON_TARGET_LIMIT   = 7,        -- 目标
		REASON_FACTION_LIMIT   = 8,       -- 帮派使用
	}

	def.const("table").CANNOT_USE_REASON = CANNOT_USE_REASON	-- 错误类型
	def.field("table")._Template = BlankTable	-- 模板

	def.field("string")._Guid = ""				-- 唯一标示
	def.field("number")._Tid = 0				-- 模板ID
	def.field("number")._SortId = -1			-- 客户端物品排序ID
	def.field("number")._Slot = -1				-- 格子的索引
	def.field('number')._Level = 1				-- 装备等级
	def.field("number")._NormalCount = 0		-- 数量
	def.field("number")._ExpireData = 0			-- 失效时间
	def.field("boolean")._IsBind = false		-- 是否绑定
	def.field("number")._Quality = 0			-- 品质
	def.field("string")._Name = ""				-- 名称
	def.field("string")._Description = ""		-- 简介
	def.field("string")._IconAtlasPath = ""		-- 背包小图标
	def.field("string")._LootModelAssetPath = ""	-- 掉落物模型路径
	def.field("number")._ItemType = -1			-- 物品类型
	def.field("number")._LevelRequired = 0 		-- 使用等级限制
	def.field("number")._GenderMask = 0			-- 性别
	def.field("number")._ProfessionMask = 0		-- 职业
	def.field("number")._CooldownDuration = 0	-- 物品冷却时间
	def.field("number")._CooldownId = 0		    -- 物品冷却ID
	def.field("boolean")._IsNewGot = false		-- 新获得标志
	def.field("table")._Components = BlankTable -- 操作组件
	def.field("number")._ItemUseSkillId = 0		-- 物品使用引导技能ID
	def.field("number")._SellCoolDownExpired = 0	-- 物品出售冷却到期时间
	def.field("number")._PackageType = -1
	def.field("string")._DescriptionType = ""        -- 物品类型显示
	def.field("number")._CreateTimestamp = 0     -- 获得道具的时间
	def.field("number")._DecomposeNum = 0        -- 背包中分解数量
	def.field("number")._FightScore = 0			 -- 战斗力

	-- 是否绑定
	def.virtual("=>", "boolean").IsBind = function (self)
		return self._IsBind
	end

	-- 获取品质的字符串
	def.virtual("=>","string").GetQualityText = function(self)
	   return StringTable.Get(10000 + self._Quality)
	end

	-- 获取品质
	def.virtual("=>","number").GetQuality = function(self)
	   return self._Quality
	end

	-- 获取名称
	def.virtual("=>","string").GetNameText = function(self)
	   return self._Name
	end

	-- 获取数量
	def.virtual("=>","number").GetCount = function(self)
	   return self._NormalCount
	end
	-- 获取物品类别
	def.virtual("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.Others
	end
	-- 是否可以分解
	def.virtual("=>", "boolean").CanDecompose = function (self)
		if self._Template.DecomposeId == nil then 
			return false
		else 
			return self._Template.DecomposeId > 0
		end
	end
	-- 是否可以出售
	def.method("=>", "boolean").CanSell = function(self)
		if self._Template.RecyclePriceInGold == nil then 
			return false
		else 
			return self._Template.RecyclePriceInGold > 0 
		end
	end
	--是否可以强化
	def.method('=>', "boolean").CanFortity = function(self)
		return self._Template.ReinforceConfigId > 0
	end
	--是否可以重铸
	def.method('=>', "boolean").CanRecast = function(self)
		return self._Template.RecastCostId > 0 and self._Template.AttachedPropertyGroupGeneratorId > 0
	end
	--是否可以精炼
	def.method('=>', "boolean").CanRefine = function(self)
		return self._Template.EquipRefineTId > 0
	end
	--是否可以转化
	def.method('=>', 'boolean').CanChangeLegendary = function(self)
		return self._Template.LegendaryGroupId > 0
	end

	-- 是否配有事件(策划使用事件1 和事件2 来判断是否有使用按钮)
	def.method("=>", "boolean").IsUse= function (self)
		if self._Template.EventType1 ~= nil and self._Template.EventType1 > 0 then 
			return true
		elseif self._Template.EventType2 ~= nil and self._Template.EventType2 > 0 then 
			return true
		else
			return false
		end
	end
	-- 是否可以合成
	def.virtual("=>", "boolean").CanCompose = function (self)
		if self._Template.ComposeId == nil then 
			return false
		else 
			return self._Template.ComposeId > 0
		end
	end

	--是否为 装备
	def.virtual("=>", "boolean").IsEquip = function (self)
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.Equipment
	end
	-- 是否为 药品
	def.virtual("=>","boolean").IsPotion = function(self)
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.Potion
	end
	-- 是否为 神符宝石
	def.virtual("=>", "boolean").IsCharm = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.Charm
	end
	-- 是否为 纹章
	def.virtual("=>","boolean").IsRune = function (self)
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.Rune
		-- body
	end
	-- 是否为 宠物技能书
	def.virtual("=>", "boolean").IsPetTalentBook = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.PetTalentBook
	end
	-- 是否为 赎罪卷
	def.virtual("=>", "boolean").IsEvil = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.Evil
	end
	-- 是否为 强化石
	def.virtual("=>", "boolean").IsInforceStone = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.InforceStone
	end
	-- 是否为 幸运符
	def.virtual("=>", "boolean").IsLuckyStone = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.LuckyStone
	end
	-- 是否为 保底石
	def.virtual("=>", "boolean").IsSafeStone = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.SafeStone
	end
	-- 是否为 重铸材料
	def.virtual("=>", "boolean").IsRebuildStore = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.RebuildStore
	end
	-- 是否为 被动技能转化材料
	def.virtual("=>", "boolean").IsTalentChange = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.TalentChange
	end
	-- 是否为 精炼材料
	def.virtual("=>", "boolean").IsRefineStore = function (self)	
		local EItemType = require "PB.Template".Item.EItemType
		return self._ItemType == EItemType.RefineStore
	end

	--是否显示获得途径
	def.virtual("=>","boolean").NeedShowApproach = function(self)
		local strApproach = self._Template.ApproachID
		if strApproach == nil or strApproach == "" then return false end

		local listApproach = string.split(strApproach, "*")
	    if listApproach == nil then return false end

	    return true
	end

	-- 根据物品信息itemDB 创建一个虚拟的物品，用于tips显示
	def.static("dynamic", "=>", "table").CreateVirtualItem = function(itemInfo)
		local itemTemplate = nil
		if type(itemInfo) == "table" then
			itemTemplate = CElementData.GetItemTemplate(itemInfo.Tid)
		elseif type(itemInfo) == "number" then
			itemTemplate = CElementData.GetItemTemplate(itemInfo)
		end
		if itemTemplate == nil then return nil end

		local tmpItemDB = {}
		if type(itemInfo) == "table" then
			tmpItemDB.ItemData = itemInfo
		elseif type(itemInfo) == "number" then
			--构造服务器 ItemData 结构
			local tmp = {}
			tmp.Guid = ""
			tmp.Tid = itemInfo
			tmp.Count = 1
			tmp.ExpireTimestamp = -1
			tmp.IsBind = false
			tmp.StrenghtLevel = 0
			tmp.GoldLevel = -1
			tmp.AdvanceExp = -1
			tmp.TalentLevel = 0
			tmp.TalentParam = 0
			tmp.EquipBaseAttrs = {}
			tmp.EnchantAttr = {}
			tmp.FightScore = 0
			
			tmpItemDB.ItemData = tmp
		end
		tmpItemDB.Index = -1

		local ItemTypeToClass = require "Package.CIvtrItems".ItemTypeToClass
		local cIvtrItem = ItemTypeToClass[itemTemplate.ItemType].new(tmpItemDB)
		cIvtrItem._Template = itemTemplate
		return cIvtrItem
	end

	def.virtual("number","number","userdata","userdata").ShowTipWithFuncBtns = function(self, panelFrom,tipPos,targetObj,itemObj)
		CItemTipMan.ShowPackbackItemTip(self, panelFrom,tipPos,targetObj,itemObj)
	end

	-- 不显示右侧功能按钮
	def.virtual("number","userdata").ShowTip = function(self,tipPos,targetObj)
		CItemTipMan.ShowPackbackItemTip(self, TipsPopFrom.OTHER_PANEL,tipPos,targetObj)
	end
	def.virtual("userdata","boolean").ShowTipWithOutOrDepositFunc = function(self,target,isDeposit)
		local comp = nil 
		if not isDeposit then
			comp = ItemComponent.TakeOutComponent.new(self)
		else
			comp = ItemComponent.DepositComponent.new(self)
		end
		CItemTipMan.ShowItemTipWithCertainFunc(self, {comp},TipPosition.DEFAULT_POSITION,target)
	end

	def.method().InitComponents = function (self)
		if self:IsUse() and not self:IsPotion() then 
			local usecomp = ItemComponent.UseComponent.new(self)
			table.insert(self._Components,usecomp)
		end
		if self:IsEquip() then 
			local equiponcomp = ItemComponent.EquipOnComponent.new(self)
			local equipoffcomp = ItemComponent.EquipOffComponent.new(self)
			-- local inheritcomp = ItemComponent.InheritComponent.new(self)
			local processcomp = ItemComponent.ProcessComponent.new(self)
			table.insert(self._Components,equiponcomp)
			table.insert(self._Components,equipoffcomp)
			-- table.insert(self._Components,inheritcomp)
			table.insert(self._Components,processcomp)
		end

        if self:IsCharm() then
            local inlay_comp = ItemComponent.EmbedComponent.new(self)
            table.insert(self._Components, inlay_comp)
            local devour_comp = ItemComponent.DevourComponent.new(self)
            table.insert(self._Components, devour_comp)
        end
		
		if self:IsPotion() then 
			local potionComp = ItemComponent.PotionComponent.new(self)
			table.insert(self._Components,potionComp)
			local buyComp = ItemComponent.BuyComponent.new(self)
			table.insert(self._Components,buyComp)
			local conComp = ItemComponent.ConfigurationComponent.new(self)
			table.insert(self._Components,conComp)
		end

		if self:CanCompose() then 
			local composeComp = ItemComponent.ComposeComponent.new(self)
			table.insert(self._Components,composeComp)
		end
		-- if self:CanDecompose() then 
		-- 	local decomposecomp = ItemComponent.DecomposeComponent.new(self) 
		-- 	table.insert(self._Components,decomposecomp)
		-- end
		if self:CanSell() then 
			local sellcomp = ItemComponent.SellComponent.new(self)
			table.insert(self._Components,sellcomp)
		end

		local linkcomp = ItemComponent.SendLinkComponent.new(self)
		table.insert(self._Components,linkcomp)	
	end

	def.method("number","=>",ItemComponent.ItemComponent,"boolean").GetComponentByType = function (self, Type)
		local components = self._Components
		for _,v in ipairs(components) do
			if v._Type == Type then
				return v, true
			end
		end
		warn("ItemComponent can not find,Type=",Type)
		return ItemComponent.ItemComponent(), false
	end

	def.virtual("=>", "string").GetGenderText = function(self)
		local Gender = require "PB.data".Gender
		local genderStr = StringTable.Get(11000 + self._Template.GenderLimitMask)
		if self._Template.GenderLimitMask ~= Gender.BOTH and game._HostPlayer._InfoData._Gender ~= self._Template.GenderLimitMask  then
			genderStr = RichTextTools.GetUnavailableColorText( genderStr ) 
		end
		return genderStr
	end

	def.virtual("=>", "string").GetUseLevelText = function(self)
	    local useLevelstr = tostring(self._Template.MinLevelLimit).." ".. StringTable.Get(10800)  --
	    if game._HostPlayer._InfoData._Level < self._Template.MinLevelLimit then
	        useLevelstr = RichTextTools.GetUnavailableColorText( useLevelstr ) 
	    end
	    if self._Template.MinLevelLimit == 0 then
	    	useLevelstr = StringTable.Get(17255)
	    end
	    return useLevelstr
	end

	def.virtual("=>", "number").CanUse = function(self)
		local hp = game._HostPlayer
		local infoData = hp._InfoData
		--职业限制
		local profMask = EnumDef.Profession2Mask[infoData._Prof]
		if profMask ~= bit.band(self._Template.ProfessionLimitMask, profMask) then return EnumDef.ItemUseReason.Prof end
		-- 性别限制
		local gender =  Profession2Gender[infoData._Prof]
		if self._Template.GenderLimitMask ~= 2 and self._Template.GenderLimitMask ~= gender then return EnumDef.ItemUseReason.Gender end
		-- 过期时间
		if self._ExpireData ~= 0 and self._ExpireData < GameUtil.GetServerTime()/1000 then return EnumDef.ItemUseReason.IsExpire end
		-- 等级限制
		if infoData._Level < self._Template.MinLevelLimit then return EnumDef.ItemUseReason.MinLevel end
		if self._Template.MaxLevelLimit ~= 0 and infoData._Level > self._Template.MaxLevelLimit then  
			return EnumDef.ItemUseReason.MaxLevel
		end
		-- 	任务相关限制
		if self:ItemUseQuestLimt() ~= 0 then 
			return EnumDef.ItemUseReason.QuestFail 
		end
		-- CD限制
		if self._CooldownId > 0 and hp._CDHdl:IsCoolingDown(self._CooldownId) then
			return EnumDef.ItemUseReason.IsCoolingDown
		end

		return EnumDef.ItemUseReason.Success	
	end
	def.method("=>","number").CanNotUseReason = function (self)
		local reason = self:CanUse()
		if reason ~= 0 then 
			if reason == EnumDef.ItemUseReason.QuestFail then 
				game._GUIMan: ShowTipText(StringTable.Get(10713), false)
			elseif reason == EnumDef.ItemUseReason.Prof then 
				game._GUIMan: ShowTipText(StringTable.Get(10706), false)
			elseif reason == EnumDef.ItemUseReason.Gender then 
				game._GUIMan: ShowTipText(StringTable.Get(10707), false)
			elseif reason == EnumDef.ItemUseReason.Level then 
				game._GUIMan: ShowTipText(StringTable.Get(10707), false)
			elseif reason == EnumDef.ItemUseReason.IsExpire then 
				game._GUIMan: ShowTipText(StringTable.Get(10703), false)
			elseif reason == EnumDef.ItemUseReason.IsCoolingDown then 
				game._GUIMan: ShowTipText(StringTable.Get(10717), false)
			end
		end
		return reason
		-- body
	end
	def.virtual().PushClickUseEvent = function(self)
		--点击使用后的提示
		-- warn("点击使用后的提示")
		local CGame = Lplus.ForwardDeclare("CGame")
		local SendUseItemEvent = require "Events.SendUseItemEvent"
		local event = SendUseItemEvent()
		event._Tid = self._Tid
		event._Slot = self._Slot
		CGame.EventManager:raiseEvent(nil, event)
	end

	def.virtual().Use = function(self)
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end
			
		if self:IsPotion() then 
			local hp = game._HostPlayer
			if hp:IsDead() then
				game._GUIMan:ShowTipText(StringTable.Get(30103), false)
				return
			end
			
			if hp._InfoData._CurrentHp >= hp._InfoData._MaxHp  then
				game._GUIMan:ShowTipText(StringTable.Get(113), false)
        		return
			end
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_DrugItem_Click, 0)
		end

		self:RealUse()
	end
	
	def.virtual().RealUse = function(self)
		-- warn("RealUse----------In")
		local function DoUse(ret)
			if not ret then return end
			local C2SItemUse = require "PB.net".C2SItemUse
			local protocol = C2SItemUse()

			protocol.Index = self._Slot
			protocol.Count = 1
			protocol.BagType = BagType.BACKPACK
			PBHelper.Send(protocol)
		end

		self:ItemUseNavToRegion(DoUse)
	end

	def.virtual("=>", "number").ItemUseQuestLimt = function(self)
		local bRet = EnumDef.ItemUseReason.Success
		local template = self._Template
		if template.QuestId ~= nil and template.isProvide ~= nil and template.QuestId > 0 then
			local CQuest = require "Quest.CQuest"
			--逻辑是 判断是否 有这个任务，如果 有任务 并且 是领取限制 (包含父子任务) 则不能使用
			if (CQuest.Instance():IsQuestReady(template.QuestId) and CQuest.Instance():IsQuestReadyBySubID(template.QuestId)) 
			or (CQuest.Instance():IsQuestInProgress(template.QuestId) ~= template.isProvide and CQuest.Instance():IsQuestInProgressBySubID (template.QuestId) ~= template.isProvide) then
				bRet = EnumDef.ItemUseReason.QuestFail	
			end
		end

		return bRet
	end

	def.virtual("function").ItemUseNavToRegion = function(self, callback)

		if callback == nil then return end
		
		local function DoCallback()
			self:ItemUseSkill(callback)
		end

		local template = self._Template
		--地图没有限制，直接使用
		if template.UseMapId == nil or template.UseMapId == 0 then
			DoCallback()
		else
			local mapTid = game._CurWorld._WorldInfo.MapTid
			--有区域限制
			if template.UseRegionId ~= nil and template.UseRegionId ~= 0 then
				--如果在同地图中，判断是否在同一区域
				local IsCanUseRegion = false
				if game._CurWorld._WorldInfo.SceneTid == template.UseMapId then
					for k, v in ipairs(game._HostPlayer._CurrentRegionIds) do
						if v == template.UseRegionId then
							IsCanUseRegion = true
						end
					end
				end			
				local CTransManage = require "Main.CTransManage"
				if IsCanUseRegion then
                    if mapTid == template.UseMapId then
					    DoCallback()
                    else
                    	if game._HostPlayer:IsInGlobalZone() then
				   			SendFlashMsg(StringTable.Get(15556), false)
				  			return
				  		end
                        CTransManage.Instance():TransToRegionIsNeedBroken(template.UseMapId, template.UseRegionId, true, DoCallback, true)
                    end
				else
					if game._HostPlayer:IsInGlobalZone() then
			   			SendFlashMsg(StringTable.Get(15556), false)
			  			return
			  		end
					CTransManage.Instance():TransToRegionIsNeedBroken(template.UseMapId, template.UseRegionId, true, DoCallback, true)
				end
			else
				if template.UsePointId ~= nil and template.UsePointId ~= 0 then
					warn("此处接口错误，注掉了")
				else
                    if mapTid == template.UseMapId then
					    DoCallback()
                    else
                    	if game._HostPlayer:IsInGlobalZone() then
				   			SendFlashMsg(StringTable.Get(15556), false)
				  			return
				  		end
						local CTransManage = require "Main.CTransManage"
                        CTransManage.Instance():TransToPortalTargetByMapID(mapTid, DoCallback)
                    end
				end
			end
		end
	end

	def.virtual("function").ItemUseSkill = function(self, callback)
		if callback == nil then return end

		if self._ItemUseSkillId == 0 then
			callback(true)
		else
			local hp = game._HostPlayer
			if hp:IsOnRide() then
		    	hp:UnRide() 
		    	SendHorseSetProtocol(-1, false)
		    end

			local hostskillhdl = hp._SkillHdl			
			hostskillhdl:CastSkill(self._ItemUseSkillId, false)
			hostskillhdl:RegisterCallback(false, callback)
		end
	end

	CIvtrItem.Commit()
end
local GetAttachedPropertyByFightPropertyId = function(obj,id)
	if id ~= nil then
		local allIds = GameUtil.GetAllTid("AttachedProperty")
		for i,v in ipairs(allIds) do
			local attPro = CElementData.GetTemplate("AttachedProperty", v)
			if id == attPro.Id then 
				return attPro
			end
		end
	end
end
--初始化装备data数据
local InitEquipData = function(obj, data)
	obj._EquipSlot = obj._Template.Slot							-- 装备位置
	obj._IsLock = data.IsLocked or false
	obj._ReinforceConfigId = obj._Template.ReinforceConfigId	-- 强化表
	obj._RecastCostId = obj._Template.RecastCostId				-- 重铸表

	obj._GoldLevel = data.GoldLevel 							-- 神器等级
	obj._TalentLevel = data.TalentLevel 		                -- 传奇属性等级
	obj._TalentParam = data.TalentParam 	                    -- 传奇属性经验值
	obj._TalentIdCache = data.TalentIdCache or 0				-- 传奇属性 临时结构，用于保存
	obj._TalentLevelCache = data.TalentLevelCache or 0		 	-- 传奇属性 临时结构，用于保存

	obj._EquipBaseAttrs = data.EquipBaseAttrs                   -- 附加属性的基础值
	obj._EquipBaseAttrsCache = data.EquipBaseAttrsCache or nil	-- 附加属性 临时结构，用于重铸保存
	obj._EnchantAttr = data.EnchantAttr	or nil					-- 附魔属性
	
	obj._TalentId = data.TalentId or 0
	obj._LegendaryGroupId = obj._Template.LegendaryGroupId or 0	-- 传奇属性组
	obj._RefineLevel = data.RefineLevel	or 0                    -- 精炼等级


	-- 装备加工相关字段(201807版)
	obj._QuenchTid = obj._Template.QuenchTid or 0				-- 装备淬火ID
	obj._SurmountTid = obj._Template.SurmountTid or 0			-- 装备突破ID
	obj._InforceLevel = data.InforceLevel or 0					-- 强化等级
	obj._QuenchLevel = data.QuenchLevel or 0					-- 淬火等级
	obj._SurmountLevel = data.SurmountLevel or 0				-- 突破等级
	obj._EnchantExpiredTime = data.EnchantExpiredTime or 0 		-- 附魔持续时间
	obj._IsOrgValueChanged = data.IsOrgValueChanged or false	-- 装备重铸属性是否被淬火过

    local attPro = GetAttachedPropertyByFightPropertyId(obj._Template.FightPropertyId)
	if attPro ~= nil then 
		obj._AttachedProperty = attPro
	end


	if data.FightProperty ~= nil then
		local propertyGeneratorElement = CElementData.GetAttachedPropertyGeneratorTemplate( data.FightProperty.index )
	    if propertyGeneratorElement == nil then
	    	warn("装备DB 数据初始化 ===============,", obj._Tid, obj._Name)
			warn("data.FightProperty.index = ", data.FightProperty.index)
	    end

	    local fightElement = CElementData.GetAttachedPropertyTemplate( propertyGeneratorElement.FightPropertyId )
	    if fightElement == nil then
	    	warn("装备DB 数据初始化 ===============,", obj._Tid, obj._Name)
			warn("propertyGeneratorElement.FightPropertyId = ", propertyGeneratorElement.FightPropertyId)
	    end
		obj._BaseAttrs.ID = fightElement.Id
		obj._BaseAttrs.GeneratorID = data.FightProperty.index
		obj._BaseAttrs.Value = data.FightProperty.value
		obj._BaseAttrs.Star = data.FightProperty.star
	end
end

--初始化神符data数据
local InitCharmData =  function(obj, template)
	if template.CharmId == nil then warn("error Can not find CharmItem CharmId!") return end

	local CharmItemdata = CElementData.GetTemplate("CharmItem", template.Id)
	if CharmItemdata == nil then warn("error Can not find CharmItem data!", template.Id) return end

	obj._CharmItemTemplate = CharmItemdata
	local ECharmSize = require "PB.data".ECharmSize
	obj._IsBig = CharmItemdata.CharmSize == ECharmSize.ECharmSize_Big
end
--初始化时装data数据
local InitDressData = function(obj, template)
end

local InitPetExpPotionData = function(obj, template)
end

local InitInforceStoneData = function(obj, template)
	local StoneInforceTemplate = CElementData.GetTemplate("StoneInforce", template.StoneInforceId)
    if StoneInforceTemplate ~= nil then
    	obj._InforceStoneLevel = StoneInforceTemplate.Level
    end
end

--初始化data数据
local InitData = function(obj, data)
	local ItemData = data.ItemData
	if ItemData ~= nil then 
		obj._Slot = data.Index								-- 格子的索引
	else
		ItemData = data
		obj._Slot = 0
	end
	local tid = ItemData.Tid


	if tid == 0 then return end
	local template = CElementData.GetTemplate("Item", tid)
	if template == nil then return end
	
	obj._Template = template							-- 模板
	obj._Guid = ItemData.Guid 					    -- 唯一标示
	obj._Tid = tid										-- 模板Id
	obj._SortId = template.SortId						-- 客户端物品排序ID
	obj._Level = template.MinLevelLimit					-- 装备等级
	obj._NormalCount = ItemData.Count				-- 数量
	obj._ExpireData = ItemData.ExpireTimestamp		-- 失效时间
	obj._IsBind = ItemData.IsBind					-- 是否绑定
	obj._Quality = template.InitQuality					-- 品质
	obj._Name = template.TextDisplayName				-- 名称
	obj._Description = template.TextDescription			-- 简介
	obj._IconAtlasPath = template.IconAtlasPath			-- 背包小图标
	obj._LootModelAssetPath = template.LootModelAssetPath	-- 掉落物模型
	obj._ItemType = template.ItemType					-- 物品类型
	obj._LevelRequired = template.MinLevelLimit 		-- 使用等级限制
	obj._GenderMask = template.GenderLimitMask			-- 性别
	obj._ProfessionMask = template.ProfessionLimitMask	-- 职业
	obj._CooldownDuration = template.CooldownDuration	-- 物品冷却时间
	obj._CooldownId = template.CooldownId				-- 物品冷却ID
	obj._IsNewGot = false								-- 新获得标志
	obj._ItemUseSkillId = template.SkillId			    -- 物品使用引导技能ID
	obj._SellCoolDownExpired = ItemData.SellCoolDownExpired or 0 -- 物品出售冷却到期时间
	obj._DescriptionType = template.DescriptionType   -- 物品类型显示信息
	obj._CreateTimestamp = ItemData.CreateTimestamp or 0  -- 创建道具时间
	obj._FightScore = ItemData.FightScore or 0


	if obj._ItemType == SubItemType.Equipment then
		InitEquipData(obj, ItemData)
	elseif obj._ItemType == SubItemType.Charm then
		InitCharmData(obj, template)
	elseif obj._ItemType == SubItemType.Dress then
		InitDressData(obj, template)
	elseif obj._ItemType == SubItemType.PetExpPotion then
		InitPetExpPotionData(obj, template)
	elseif obj._ItemType == SubItemType.InforceStone then
		InitInforceStoneData(obj, template)
	end
end

--[[----------------------
--       普通物品
-------------------------]]
local CIvtrNormalItem = Lplus.Extend(CIvtrItem,"CIvtrNormalItem")
do
	local def = CIvtrNormalItem.define

	def.final("table", "=>",CIvtrNormalItem).new = function (data)
		local obj = CIvtrNormalItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.override().Use = function(self)
		self:PushClickUseEvent()
		if self._Template.EventType1 == EItemEventType.ItemEvent_OpenPanel and self._Template.Type1Param1 ~= "" then 
			game._GUIMan:Open(self._Template.Type1Param1,self._Template.Type1Param2)
		else			
			local reason = self:CanNotUseReason()
			if reason ~= 0 then return end
			self:RealUse()
		end
	end

	CIvtrNormalItem.Commit()
end

--[[----------------------
--        装备
-------------------------]]
local CIvtrEquip = Lplus.Extend(CIvtrItem, "CIvtrEquip")
do
	local def = CIvtrEquip.define
	
	def.field("number")._EquipSlot = 0			-- 装备位置
	def.field("table")._EquipBaseAttrs = BlankTable --重铸用的附加属性：只包含创建装备时的属性
	def.field("table")._EquipBaseAttrsCache = BlankTable	-- 重铸属性，临时结构，用于重铸保存
	def.field("table")._BaseAttrs = BlankTable  -- 基础属性
	def.field("number")._ReinforceConfigId = 0	-- 强化表
	def.field("number")._RecastCostId = 0		-- 重铸表
	def.field("number")._GoldLevel = 0			-- 神器等级
	def.field("number")._TalentId = 0           -- 天赋id
	def.field("number")._TalentLevel = 0		-- 传奇属性等级
	def.field("number")._TalentIdCache = 0      -- 天赋属性，临时结构，用于保存
	def.field("number")._TalentLevelCache = 0   -- 天赋属性，临时结构，用于保存
	def.field("number")._TalentParam = 0	    -- 传奇属性经验值

	def.field("table")._AllEquipAttrInfo = BlankTable	-- 装备重铸属性信息表大全
	def.field("table")._AttachedProperty = BlankTable   -- 附加属性表Table
	def.field("table")._EnchantAttr = BlankTable		-- 附魔属性
	def.field('number')._LegendaryGroupId = 0			-- 传奇属性组
	def.field('number')._RefineLevel = 0				-- 精炼等级

	-- 装备加工相关字段(201807版)
	def.field('number')._QuenchTid = 0					-- 装备淬火ID
	def.field('number')._SurmountTid = 0				-- 装备突破ID
	def.field("boolean")._IsOrgValueChanged = false		-- 装备重铸值是否被淬火过

	def.field("number")._InforceLevel = 0				-- 强化等级
	def.field("number")._QuenchLevel = 0				-- 淬火等级
	def.field("number")._SurmountLevel = 0				-- 突破等级
	def.field("number")._EnchantExpiredTime = 0			-- 附魔持续时间
	def.field("boolean")._IsLock = false                -- 是否锁柱
	def.field("number")._PropertyCoefficient = 1 		-- 品质系数
	def.field("table")._RecommendPropertyList = BlankTable -- 推荐属性 生成器内最高属性值-提供战斗力最高ID（前几个）

	def.final("table", "=>", CIvtrEquip).new = function (data)
		local obj = CIvtrEquip()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
		-- return EnumDef.ItemCategory.Weapon
		if self._EquipSlot == EEquipmentSlot.Weapon then
			-- 武器
			return EnumDef.ItemCategory.Weapon
		elseif self._EquipSlot == EEquipmentSlot.Helmet  or 
			   self._EquipSlot == EEquipmentSlot.Armor or 
			   self._EquipSlot == EEquipmentSlot.Leggings or
			   self._EquipSlot == EEquipmentSlot.Boots or
			   self._EquipSlot == EEquipmentSlot.Bracers then
			-- 防具
			return EnumDef.ItemCategory.Armor
		else
			-- 饰品
	   		return EnumDef.ItemCategory.Jewelry
	   	end
	end

	--获取装备部位的字符串
	def.method("=>","string").GetEquipSlotText = function(self)
	   return StringTable.Get(10400 + self._EquipSlot)
	end

	--判断是否存在重铸属性
	def.method("=>", "boolean").HasEquipAttrs = function(self)
		return #self._EquipBaseAttrs > 0
	end

	-- 判断是否存在附魔属性
	def.method("=>", "boolean").HasEnchantAttr = function(self)
		return self._EnchantAttr ~= nil and self._EnchantAttr.index > 0
	end

	--获取品质系数
	def.method("=>", "number").GetPropertyCoefficient = function(self)
		return self._Template.PropertyCoefficient
	end

	def.method("=>", "table").GetEquipAttrs = function(self)
		return self._EquipBaseAttrs
	end

	--是否可以继承
	def.method("=>", "boolean").CanInherit = function(self)
		return self._InforceLevel > 0
	end
	
	--判断是否存在橙色重铸属性
	def.method("=>", "boolean").HasValuableEquipAttrs = function(self)
		local bRet = false
		local allCfg = self:GetEquipAttrInfo()
		for i,attr in ipairs(self._EquipBaseAttrs) do
			if attr.star+1 == allCfg[attr.index].MaxStar then
				bRet = true
				break
			end
		end

		return bRet
	end
	--判断是否有未保存 重铸属性
	def.method("=>", "boolean").HasUnsaveEquipAttrsCache = function(self)
		local bRet = false
		if self._EquipBaseAttrsCache ~= nil and #self._EquipBaseAttrsCache > 0 then
			bRet = true
		end	

		return bRet
	end
	--判断是否有未保存 传奇属性
	def.method("=>", "boolean").HasUnsaveEquipTalentCache = function(self)	
		local bRet = false
		if self._TalentIdCache > 0 and self._TalentLevelCache > 0 then
			bRet = true
		end	

		return bRet
	end

	--设置传奇属性
	def.method("number").SetLegendId = function(self, id)
		self._TalentId = id
	end
	--获取传奇属性
	def.method("=>","number").GetLegendId = function(self)
		return self._TalentId
	end
	--设置传奇属性
	def.method("number").SetLegendLevel = function(self, lv)
		self._TalentLevel = lv
	end
	--获取传奇属性
	def.method("=>","number").GetLegendLevel = function(self)
		return self._TalentLevel
	end
	--获取强化等级
	def.method("=>","number").GetInforceLevel = function(self)
		return self._InforceLevel
	end
	--获取淬火等级
	def.method("=>", "number").GetQuenchLevel = function(self)
		return self._QuenchLevel
	end

    --获取强化增长值
	def.method("=>","number").GetInforceIncrease = function(self)
		local curLv = self:GetInforceLevel()
		local incVal = 0
		if curLv > 0 then
	        local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(self._ReinforceConfigId, curLv)
	        if InforceInfoOld ~= nil then
	        	incVal = math.ceil(self._BaseAttrs.Value * (InforceInfoOld.InforeValue / 100))
	        	incVal = math.max(incVal, curLv)
	        end
	    end

		return incVal
	end
	--获取精炼增长值
	def.method("=>", "number").GetRefineIncrease =function(self)
		local nRet = 0
		if self:GetRefineLevel() > 0 then
			local materialInfo = CEquipUtility.GetRefineMaterialInfo(self._Template.EquipRefineTId, self:GetRefineLevel())
			if materialInfo ~= nil then
				nRet= materialInfo.Old.Increase
			end
		end

		return nRet
	end
	--获取Item最大强化等级
	def.method("=>","number").GetMaxInforceLevel = function(self)
		return CEquipUtility.GetMaxInforceLevelByQuality(self._Quality)
	end
	--强化是否为最大等级
	def.method("=>", "boolean").IsMaxReinforceLevel = function(self)
		return self._InforceLevel >= self:GetMaxInforceLevel()
	end

	--获取精炼等级
	def.method("=>", "number").GetRefineLevel = function(self)
		return self._RefineLevel
	end
	--设置精炼等级
	def.method("number").SetRefineLevel = function(self, level)
		self._RefineLevel = level
	end
	
	-- 重铸属性是否 淬满
	def.method("=>", "boolean").IsAttrAllMax = function(self)
		local bRet = true

		for i=1, #self._EquipBaseAttrs do
			local attr = self._EquipBaseAttrs[i]
			if attr.value < attr.MaxStarValue then
        		bRet = false
        		break
        	end
		end

        return bRet
	end

	-- 获取突破等级
	def.method("=>","number").GetSurmountLevel = function(self)
		return self._SurmountLevel
	end

	-- 是否存在突破属性
	def.method("=>", "boolean").HasSurmount = function(self)
		return self._SurmountLevel > 1
	end
	-- 是否存在淬火属性
	def.method("=>", "boolean").HasQuench = function(self)
		return self._IsOrgValueChanged
	end
	-- 突破最高等级
	def.method("=>", "number").GetSurmountMaxLevel = function(self)
		local iRet = 0

		if self._SurmountTid > 0 then
			local template = CElementData.GetTemplate("EquipSurmount", self._SurmountTid)
			if template ~= nil then
				for i,v in ipairs(template.SurmountDatas) do
					iRet = v.Level
				end
			end
		end

		return iRet
	end

	-- 获取 推荐属性信息列表
	def.method("=>", "table").GetRecommendPropertyList = function(self)
		if next(self._RecommendPropertyList) == nil then
			self._RecommendPropertyList = CEquipUtility.CalcRecommendProperty(self)
		end

		return self._RecommendPropertyList
	end

	-- 判断是否为推荐属性
	def.method("number", "=>", "boolean").IsRecommendProperty = function(self, propertyId)
		local bRet = false

		local list = self:GetRecommendPropertyList()
		for i,v in ipairs(list) do
			if propertyId == v.ID then
				bRet = true
				break
			end
		end

		return bRet
	end
	-- 是否可以继续突破
	def.method("=>", "boolean").CanSurmount = function(self)
	-- 突破初始值为 1 ，未突破过
		return self:GetSurmountMaxLevel() >= self._SurmountLevel
	end

	--获取装备重铸属性信息表
	def.method("=>", "table").GetEquipAttrInfo = function(self)
		if #self._AllEquipAttrInfo == 0 then
			-- warn("self._Template.AttachedPropertyGroupGeneratorId == ", self._Template.AttachedPropertyGroupGeneratorId)
			self._AllEquipAttrInfo = CElementData.GetEquipAttrInfoById(self._Template.AttachedPropertyGroupGeneratorId)
		end

		return self._AllEquipAttrInfo
	end

	-- --获取装备附魔属性信息表
	-- def.method("=>", "table").GetEquipEnchantAttrInfo = function(self)
	-- 	if self._EnchantAttr == 0 then
	-- 		-- warn("self._Template.EnchantAttrId == ", self._Template.EnchantAttrId)
	-- 		self._EnchantAttrs = CElementData.GetEquipAttrInfoById(self._Template.EnchantAttrId)
	-- 	end

	-- 	return self._EnchantAttrs
	-- end

	--本地战斗力计算：只能用参与计算的每个属性对应的基元属性来计算战斗力
	def.static("number","number", "=>", "number").GetFightPropertyFightScore = function(metaFightPropertyIndex, value)
		local result = 0
		local CScoreCalcMan = require "Data.CScoreCalcMan"
		local info = {}
		local data = {}

		local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( metaFightPropertyIndex )
		data.ID = attachPropertGenerator.FightPropertyId
		data.Value = value
		table.insert(info, data)
        --计算公式类 获取结果
		result = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, info)

		return result
	end

	-- 重铸属性
	def.method("=>", "number").CalcFightPropertyScore = function(self)
		local result = 0
		for i,v in ipairs(self._EquipBaseAttrs) do
			result = result + CIvtrEquip.GetFightPropertyFightScore(v.index, v.value)
		end

		return result
	end

	def.method().CalcBaseFightScore = function(self)
		-- body
	end

	def.method("=>", "number").GetFightScore = function(self)
		return self._FightScore
	end

	--newAttrs   重铸时使用
	--isCalcBase 是否只计算基本属性（不算强化、淬火、宝石等附加属性)
	def.method("dynamic", "dynamic", "=>", "number").CalcFightScore = function(self, newAttrs, isOnlyCalcBase)
		local result = 0
		local CScoreCalcMan = require "Data.CScoreCalcMan"
		local info = {}

		local function SetInfo(attrs)
			for i,v in ipairs( attrs ) do
				local data = {}				
				local attrData = CElementData.GetAttachedPropertyGeneratorTemplate( v.index )

				if attrData then
					data.ID = attrData.FightPropertyId
					data.Value = v.value
					table.insert(info, data)
				end
			end
		end

		--基础属性
		do
			local data = {}
			data.ID = self._BaseAttrs.ID

			local curLv = self:GetInforceLevel()
			local curVal = self._BaseAttrs.Value
			if curLv > 0 then
		        local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(self._ReinforceConfigId, curLv)
		        if InforceInfoOld ~= nil then
		        	curVal = math.ceil(self._BaseAttrs.Value * (1 + InforceInfoOld.InforeValue / 100))
		        end
		    end
			data.Value = curVal
			table.insert(info, data)
		end

		--附魔属性
		do
			if self._EnchantAttr ~= nil then
				local propertyGeneratorElement = CElementData.GetAttachedPropertyGeneratorTemplate( self._EnchantAttr.index )
			    if propertyGeneratorElement ~= nil then
			    	local fightElement = CElementData.GetAttachedPropertyTemplate( propertyGeneratorElement.FightPropertyId )
			   	 	if fightElement ~= nil then
			   	 		local data = {}
			   	 		data.ID = fightElement.Id
			   	 		data.Value = self._EnchantAttr.value
			   	 		table.insert(info, data)
			    	end
			    end
			end
		end

		--精炼
		do
			if self:GetRefineLevel() > 0 then
				local materialInfo = CEquipUtility.GetRefineMaterialInfo(self._Template.EquipRefineTId, self:GetRefineLevel())
				local data = {}
				data.ID = self._BaseAttrs.ID
				data.Value = materialInfo.Old.Increase
				table.insert(info, data)
			end
		end

		--附加属性
		local currentAttrs = {}
		currentAttrs = self._EquipBaseAttrs

		if newAttrs~= nil and #newAttrs > 0 then
			currentAttrs = newAttrs
		end
		SetInfo(currentAttrs)

		--计算公式类 获取结果
		result = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, info)
		--计算被动技能 战斗力
		if self._TalentId > 0 then
			result = result + CScoreCalcMan.Instance():CalcLegendaryUpgradeScore(self._TalentId, self._TalentLevel)
		end

		return result
	end
	
	--不显示右侧功能按钮
	def.override("number","userdata").ShowTip = function(self,tipPos,targetObj)
		CItemTipMan.ShowPackbackEquipTip(self, TipsPopFrom.WithoutButton,tipPos,targetObj)
	end

	def.override("number","number","userdata","userdata").ShowTipWithFuncBtns = function(self, panelFrom,tipPos,targetObj,itemObj)
		CItemTipMan.ShowPackbackEquipTip(self, panelFrom,tipPos,targetObj,itemObj)
	end

    def.override().Use = function(self)
    	self:PushClickUseEvent()
    	local Success = self:CanNotUseReason()
    	if Success ~= 0 then return end

    	if game._HostPlayer:IsDead() then
    		game._GUIMan: ShowTipText(StringTable.Get(167), false)
    	else
	    	local ItemBindMode = require "PB.Template".Item.ItemBindMode
		    if not self:IsBind() and self._Template.BindMode == ItemBindMode.OnUse then
		    	local title, msg, closeType = StringTable.GetMsg(58)
		        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, function(val)
				        if val then
				            self:RealUse()
				        end
			        end) 
		    else
		        self:RealUse()
		    end
		end
	end

	def.override().RealUse = function(self)
    	local hp = game._HostPlayer
		local oldEquip = hp._Package._EquipPack._ItemSet[self._EquipSlot+1]
		if self._Template.AudioType ~= nil then 
			CSoundMan.Instance():Play2DAudio(EnumDef.UseItemAudioType[self._Template.AudioType], 0)
		end

		do 
	        local C2SEquipPuton = require "PB.net".C2SEquipPuton
	        local protocol = C2SEquipPuton()
	        protocol.Index = self._Slot
	        SendProtocol(protocol)
	    end
	end

	CIvtrEquip.Commit()
end

--[[----------------------
--        药 品
-------------------------]]
local CIvtrMedicine = Lplus.Extend(CIvtrItem, "CIvtrMedicine")
do
    local def = CIvtrMedicine.define

	def.final("table", "=>", CIvtrMedicine).new = function (data)
		local obj = CIvtrMedicine()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	CIvtrMedicine.Commit()
end

--[[----------------------
--      材料
-------------------------]]
local CIvtrMaterialItem = Lplus.Extend(CIvtrItem,"CIvtrMaterialItem")
do
	local def = CIvtrMaterialItem.define

	def.final("table", "=>",CIvtrMaterialItem).new = function (data)
		local obj = CIvtrMaterialItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	CIvtrMaterialItem.Commit()
end

--[[----------------------
--       任务物品
-------------------------]]
local CIvtrQuestItem = Lplus.Extend(CIvtrItem, "CIvtrQuestItem")
do
    local def = CIvtrQuestItem.define

	def.final("table", "=>", CIvtrQuestItem).new = function (data)
		local obj = CIvtrQuestItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end
def.override().RealUse = function(self)
		--warn("RealUse----------In")
		local function DoUse(ret)
			if not ret then return end
			local C2SItemUse = require "PB.net".C2SItemUse
			local protocol = C2SItemUse()

			protocol.Index = self._Slot
			protocol.Count = 1
			protocol.BagType = BagType.QUESTPACK
			PBHelper.Send(protocol)
		end

		self:ItemUseNavToRegion(DoUse)
	end
	CIvtrQuestItem.Commit()
end

--[[----------------------
--       讨伐令
-------------------------]]
local CIvtrWantedItem = Lplus.Extend(CIvtrItem, "CIvtrWantedItem")
do
    local def = CIvtrWantedItem.define

	def.final("table", "=>", CIvtrWantedItem).new = function (data)
		local obj = CIvtrWantedItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

    def.override().Use = function(self)
    	if game._HostPlayer:IsInGlobalZone() then
   			SendFlashMsg(StringTable.Get(15556), false)
  			return
  		end
		local function callback(val)
			if val then
				CIvtrItem.Use(self)
			end
		end

 		local CQuest = require "Quest.CQuest"
	    if CQuest.Instance():IsHasQuestPunitive() then
--[[	    	local title, msg, closeType = StringTable.GetMsg(59)
	    	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_YESNO,callback)--]]
	    else
	    	game._GUIMan:Close("CPanelRoleInfo")
	    end

	    local UserData = require "Data.UserData"

    	UserData.Instance():SetField("LastWantedItemQuality", self._Template.InitQuality)
		UserData.Instance():SaveDataToFile()
	    callback(true)
	end
	CIvtrWantedItem.Commit()
end




--[[----------------------
--       纹章
-------------------------]]
local CIvtrRuneItem = Lplus.Extend(CIvtrItem, "CIvtrRuneItem")
do
    local def = CIvtrRuneItem.define

	def.final("table", "=>", CIvtrRuneItem).new = function (data)
		local obj = CIvtrRuneItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	def.override().Use = function(self)
		local Success = self:CanNotUseReason()
		if not game._CFunctionMan:IsUnlockByFunTid(9) then 
	    	game._CGuideMan:OnShowTipByFunUnlockConditions(0, 9)
		return end
		if Success == 0 then
			local data = {}
			data._PageTag = "Tab_Rune"
			data._Tid = self._Template.Type1Param1
			--warn(' self._Template.Type1Param1 ',self._Template.Type1Param1)
			game._GUIMan:Open("CPanelUISkill", data)
			game._GUIMan:Close("CPanelRoleInfo")
				
		end	
	end

	CIvtrRuneItem.Commit()
end


--[[----------------------
--       坐骑蛋
-------------------------]]
local CIvtrHorseItem = Lplus.Extend(CIvtrItem,"CIvtrHorseItem")
do
	local def = CIvtrHorseItem.define

	def.final("table", "=>",CIvtrHorseItem).new = function (data)
		local obj = CIvtrHorseItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	CIvtrHorseItem.Commit()
end


--[[----------------------
--       宝箱物品
-------------------------]]
local CIvtrTreasureBoxItem = Lplus.Extend(CIvtrItem,"CIvtrTreasureBoxItem")
do
	local def = CIvtrTreasureBoxItem.define

	def.final("table", "=>",CIvtrTreasureBoxItem).new = function (data)
		local obj = CIvtrTreasureBoxItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end
	local function C2SRealUse(self,count) 
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end

		local C2SItemUse = require "PB.net".C2SItemUse
		local protocol = C2SItemUse()
		protocol.Index = self._Slot
		protocol.Count = count
		protocol.BagType = BagType.BACKPACK
		PBHelper.Send(protocol)
	end
	def.override().Use = function(self)
		-- 判断不可回购标志，用于商城礼包等现金消费品
		local function UseFunc(ret)
			if ret then
				local function CostMoney(count)
					if self._Template.EventType1 == EItemEventType.ItemEvent_OpenBox and self._Template.Type1Param1 ~= "" then
						local dropRuleId = tonumber(self._Template.Type1Param1)
						local dropRuleItem = CElementData.GetTemplate("DropRule", dropRuleId)
						if dropRuleItem ~= nil then 
							local moneyTemp = CElementData.GetMoneyTemplate(dropRuleItem.CostMoneyId)
							if moneyTemp == nil or dropRuleItem.CostMoneyCount == 0 then 
								C2SRealUse(self,count)
							return end

							local function callback(value)
								if not value then return end
								C2SRealUse(self,count)
							end	
							local title, msg, closeType = StringTable.GetMsg(62)
							local cost = tonumber(dropRuleItem.CostMoneyCount) *count
							local str = string.format(msg,moneyTemp.Name,cost)
							MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
						else 
							warn( dropRuleId .." DropRule dont have this Template ")
						end
					else
						warn(" Item dont have EventType1 or Type1Param1 ")
					end	
				end

				local function okback(count) 
					CostMoney(count)
				end

				if self._NormalCount > 1 then 
					--local text = "<color=#" .. EnumDef.Quality2ColorHexStr[self._Quality] ..">" .. self._Template.TextDisplayName .."</color>"
					local text = string.format(StringTable.Get(313),"")
					BuyOrSellItemMan.ShowCommonOperate(TradingType.USE,StringTable.Get(11105),text, 1, self._NormalCount,0, 0 , self._Tid, okback, nil)
				else
					local useNum = 1
					CostMoney(useNum)
				end
			end
		end

		if self._Template.IsUseMsg then
			local title, msg, closeType = StringTable.GetMsg(111)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, UseFunc)
		else
			UseFunc(true)
		end
	end
	
	CIvtrTreasureBoxItem.Commit()
end


--[[----------------------
--       宠物蛋
-------------------------]]
local CIvtrPetItem = Lplus.Extend(CIvtrItem,"CIvtrPetItem")
do
	local def = CIvtrPetItem.define

	def.final("table", "=>",CIvtrPetItem).new = function (data)
		local obj = CIvtrPetItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	CIvtrPetItem.Commit()
end


--[[----------------------
--       神符-宝石
-------------------------]]
local CIvtrCharmItem = Lplus.Extend(CIvtrItem,"CIvtrCharmItem")
do
	local def = CIvtrCharmItem.define

	def.field("boolean")._IsBig = false				-- 是否为大神符
	def.field("table")._CharmItemTemplate = BlankTable	-- 神符模板数据
	def.final("table", "=>",CIvtrCharmItem).new = function (data)
		local obj = CIvtrCharmItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.method("=>", "boolean").IsBigCharm = function(self)
		return self._IsBig
	end

	def.method("=>", "string").GetCharmColorText = function(self)
		return StringTable.Get(19320 + self._CharmItemTemplate.CharmColor)
	end

	def.override("=>", "number").CanUse = function(self)
		return EnumDef.ItemUseReason.Success
	end

    def.override("=>", "boolean").CanCompose = function(self)
        return false
    end

	CIvtrCharmItem.Commit()
end

--[[----------------------
--		翅膀
-------------------------]]
local CIvtrWingItem = Lplus.Extend(CIvtrItem,"CIvtrWingItem")
do
	local def = CIvtrWingItem.define

	def.final("table", "=>",CIvtrWingItem).new = function (data)
		local obj = CIvtrWingItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.override("=>", "number").CanUse = function(self)
		return EnumDef.ItemUseReason.Success
	end

	CIvtrWingItem.Commit()
end

--[[----------------------
--		时装
-------------------------]]
local CIvtrDressItem = Lplus.Extend(CIvtrItem,"CIvtrDressItem")
do
	local def = CIvtrDressItem.define

	def.final("table", "=>",CIvtrDressItem).new = function (data)
		local obj = CIvtrDressItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end
	def.override().Use = function(self)
		local function callback(value)
			if not value then return end
			self:PushClickUseEvent()
			local reason = self:CanNotUseReason()
			if reason ~= 0 then return end
			self:RealUse()
		end
		local title, str, closeType = StringTable.GetMsg(61)
		MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)	
	end
	CIvtrDressItem.Commit()
end

--[[----------------------
--		经验药水
-------------------------]]
local CIvtrPetExpPotionItem = Lplus.Extend(CIvtrItem,"CIvtrPetExpPotionItem")
do
	local def = CIvtrPetExpPotionItem.define

	def.final("table", "=>",CIvtrPetExpPotionItem).new = function (data)
		local obj = CIvtrPetExpPotionItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.override().Use = function(self)
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end
		if self._Template.EventType2 == EItemEventType.ItemEvent_OpenPanel and self._Template.Type2Param1 ~= "" and self._Template.Type2Param2 ~= "" then 
			-- 打开宠物界面页签
			local data = nil
			local pageType = tonumber( self._Template.Type2Param2 )
			if pageType == 1 then
	            data = {UIPetPageState = EnumDef.UIPetPageState.PageCultivate}
	        elseif pageType == 2 then
	            data = {UIPetPageState = EnumDef.UIPetPageState.PageAdvance}
	        elseif pageType == 3 then
	            data = {UIPetPageState = EnumDef.UIPetPageState.PageRecast}
	        elseif pageType == 4 then
	            data = {UIPetPageState = EnumDef.UIPetPageState.PageSkill}
	        end
	        game._GUIMan:Open(self._Template.Type2Param1, data)
		end
	end

	-- def.override("=>", "number").CanUse = function(self)
	-- 	return EnumDef.ItemUseReason.Success
	-- end

	CIvtrPetExpPotionItem.Commit()
end


--[[----------------------
--       宠物被动技能书
-------------------------]]
local CIvtrPetTalentBookItem = Lplus.Extend(CIvtrItem,"CIvtrPetTalentBookItem")
do
	local def = CIvtrPetTalentBookItem.define

	def.final("table", "=>",CIvtrPetTalentBookItem).new = function (data)
		local obj = CIvtrPetTalentBookItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	def.override().Use = function(self)
		local Success = self:CanNotUseReason()
		if Success == 0 then
			game._GUIMan:Open("CPanelUIPetProcess", nil)
		end	
	end

	CIvtrPetTalentBookItem.Commit()
end


--[[----------------------
--       附魔卷轴
-------------------------]]
local CIvtrEnchantReelItem = Lplus.Extend(CIvtrItem,"CIvtrEnchantReelItem")
do
	local def = CIvtrEnchantReelItem.define

	def.final("table", "=>",CIvtrEnchantReelItem).new = function (data)
		local obj = CIvtrEnchantReelItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	def.override().Use = function(self)
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end
		if self._Template.EventType1 == EItemEventType.ItemEvent_EquipEnchant and self._Template.Type1Param1 ~= "" then 
			local EnchantData = CElementData.GetEquipEquipEnchantInfoMapByItemID(self._Tid)
    		if EnchantData == nil then warn(" EnchantItem Id Enchant is nil",self._Tid) return end
			local itemData = CEquipUtility.GetEquipBySlot(EnchantData.Enchant.Slot)
			if itemData == nil then 
				game._GUIMan:ShowTipText(StringTable.Get(10977), false)
			else
				local PanelData = 
				{
					EquipData = itemData,
					EnchantItemData = self,
					EnchantInfo = EnchantData,
				}
				game._GUIMan:Open("CPanelEnchantWindow",PanelData)
			end
		end
	end

	CIvtrEnchantReelItem.Commit()
end

--[[----------------------
--       月光庭院
-------------------------]]
local CIvtrGuildPrayItem = Lplus.Extend(CIvtrItem,"CIvtrGuildPrayItem")
do
	local def = CIvtrGuildPrayItem.define

	def.final("table", "=>",CIvtrGuildPrayItem).new = function (data)
		local obj = CIvtrGuildPrayItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	--打开月光庭院
	def.override().Use = function(self)
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end
	
		if self._Template.EventType1 == EItemEventType.ItemEvent_OpenPanel and self._Template.Type1Param1 ~= "" then 
			if self._Template.Type1Param1 == "GuildPray" then 
				game._GuildMan:OpenGuildPray()
			end
		end
	end
	CIvtrGuildPrayItem.Commit()
end

--[[----------------------
--       赎罪卷
-------------------------]]
local CIvtrEvilItem = Lplus.Extend(CIvtrItem,"CIvtrEvilItem")
do
	local def = CIvtrEvilItem.define

	def.final("table", "=>",CIvtrEvilItem).new = function (data)
		local obj = CIvtrEvilItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrEvilItem.Commit()
end

--[[----------------------
--       强化石
-------------------------]]
local CIvtrInforceStoneItem = Lplus.Extend(CIvtrItem,"CIvtrInforceStoneItem")
do
	local def = CIvtrInforceStoneItem.define

	def.field("number")._InforceStoneLevel = 0				-- 强化石等级

	def.final("table", "=>",CIvtrInforceStoneItem).new = function (data)
		local obj = CIvtrInforceStoneItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrInforceStoneItem.Commit()
end

--[[----------------------
--       幸运符
-------------------------]]
local CIvtrLuckyStoneItem = Lplus.Extend(CIvtrItem,"CIvtrLuckyStoneItem")
do
	local def = CIvtrLuckyStoneItem.define

	def.final("table", "=>",CIvtrLuckyStoneItem).new = function (data)
		local obj = CIvtrLuckyStoneItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrLuckyStoneItem.Commit()
end

--[[----------------------
--       保底石
-------------------------]]
local CIvtrSafeStoneItem = Lplus.Extend(CIvtrItem,"CIvtrSafeStoneItem")
do
	local def = CIvtrSafeStoneItem.define

	def.final("table", "=>",CIvtrSafeStoneItem).new = function (data)
		local obj = CIvtrSafeStoneItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrSafeStoneItem.Commit()
end

--[[----------------------
--       重铸材料
-------------------------]]
local CIvtrRebuildStoreItem = Lplus.Extend(CIvtrItem,"CIvtrRebuildStoreItem")
do
	local def = CIvtrRebuildStoreItem.define

	def.final("table", "=>",CIvtrRebuildStoreItem).new = function (data)
		local obj = CIvtrRebuildStoreItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrRebuildStoreItem.Commit()
end

--[[----------------------
--       被动技能转化材料
-------------------------]]
local CIvtrTalentChangeItem = Lplus.Extend(CIvtrItem,"CIvtrTalentChangeItem")
do
	local def = CIvtrTalentChangeItem.define

	def.final("table", "=>",CIvtrTalentChangeItem).new = function (data)
		local obj = CIvtrTalentChangeItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrTalentChangeItem.Commit()
end

--[[----------------------
--       精炼材料
-------------------------]]
local CIvtrRefineStoreItem = Lplus.Extend(CIvtrItem,"CIvtrRefineStoreItem")
do
	local def = CIvtrRefineStoreItem.define

	def.final("table", "=>",CIvtrRefineStoreItem).new = function (data)
		local obj = CIvtrRefineStoreItem()
		InitData(obj, data)
		obj:InitComponents()

		return obj
	end

	-- 获取物品类别
	def.override("=>","number").GetCategory = function(self)
	   	return EnumDef.ItemCategory.EquipProcessMaterial
	end

	CIvtrRefineStoreItem.Commit()
end

--[[----------------------
--       HotTime道具
-------------------------]]
local CIvtrHotTimeItem = Lplus.Extend(CIvtrItem,"CIvtrHotTimeItem")
do
	local def = CIvtrHotTimeItem.define

	def.final("table", "=>",CIvtrHotTimeItem).new = function (data)
		local obj = CIvtrHotTimeItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.override().Use = function(self)
		-- warn("game._IsExpHottime and game._IsGoldHottime ==>>>", game._IsExpHottime, game._IsGoldHottime, self._Tid, game._HottimeExpItemTid, game._HottimeGoldItemTid, (self._Tid == 95 or self._Tid == 97), (self._Tid == 96 or self._Tid == 98))
		if ((self._Tid == 95 or self._Tid == 97) and game._IsExpHottime and self._Tid ~= game._HottimeExpItemTid) or
		((self._Tid == 96 or self._Tid == 98) and game._IsGoldHottime and self._Tid ~= game._HottimeGoldItemTid) then
			local function callback(value)
				if not value then return end
				self:RealUse()
			end
			local title, str, closeType = StringTable.GetMsg(123)
			MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_YESNO, callback)
		else
			self:RealUse()
		end
	end
	CIvtrHotTimeItem.Commit()
end

--[[----------------------
--       BagExtend道具
-------------------------]]
local CIvtrBagExtendItem = Lplus.Extend(CIvtrItem,"CIvtrBagExtendItem")
do
	local def = CIvtrBagExtendItem.define

	def.final("table", "=>",CIvtrBagExtendItem).new = function (data)
		local obj = CIvtrBagExtendItem()
		InitData(obj, data)
		obj:InitComponents()
		return obj
	end

	def.override().Use = function(self)
		self:PushClickUseEvent()
		local reason = self:CanNotUseReason()
		if reason ~= 0 then return end
		local function callback(count)
			local C2SItemUse = require "PB.net".C2SItemUse
			local protocol = C2SItemUse()
			protocol.Index = self._Slot
			protocol.Count = count
			protocol.BagType = BagType.BACKPACK
			PBHelper.Send(protocol)
		end	
		if self._NormalCount > 1 then 
			local text = "<color=#" .. EnumDef.Quality2ColorHexStr[self._Quality] ..">" .. self._Template.TextDisplayName .."</color>"
			text = string.format(StringTable.Get(313),text)
			BuyOrSellItemMan.ShowCommonOperate(TradingType.USE,StringTable.Get(11105),text, 1, self._NormalCount,0, 0 , self._Tid, callback, nil)
		else
			local useNum = 1
			callback(useNum)
		end
	end
	
	CIvtrBagExtendItem.Commit()
end

--[[----------------------
--    未知物品
-------------------------]]
local CIvtrUnknown = Lplus.Extend(CIvtrItem, "CIvtrUnknown")
do
    local def = CIvtrUnknown.define

	def.final("table", "=>", CIvtrUnknown).new = function (data)
		local obj = CIvtrUnknown()
		InitData(obj, data)
		--暂时tips实现的 未知物品的使用记得 修复
		obj:InitComponents()

		return obj
	end

	CIvtrUnknown.Commit()
end

return
{
	CIvtrItem 				= CIvtrItem,
	CIvtrUnknown 			= CIvtrUnknown,

	CIvtrNormalItem 		= CIvtrNormalItem,
	CIvtrEquip 				= CIvtrEquip,
	CIvtrMedicine 			= CIvtrMedicine,
	CIvtrMaterialItem 		= CIvtrMaterialItem,
	CIvtrQuestItem 			= CIvtrQuestItem,
	CIvtrHorseItem 			= CIvtrHorseItem,
	CIvtrPetItem 			= CIvtrPetItem,
	CIvtrCharmItem 			= CIvtrCharmItem,
	CIvtrWantedItem 		= CIvtrWantedItem,
	CIvtrPetTalentBookItem 	= CIvtrPetTalentBookItem,
	CIvtrEnchantReelItem 	= CIvtrEnchantReelItem,
	CIvtrGuildPrayItem 		= CIvtrGuildPrayItem,
	CIvtrEvilItem			= CIvtrEvilItem,
	CIvtrInforceStoneItem 	= CIvtrInforceStoneItem,
	CIvtrLuckyStoneItem		= CIvtrLuckyStoneItem,
	CIvtrSafeStoneItem		= CIvtrSafeStoneItem,
	CIvtrRebuildStoreItem	= CIvtrRebuildStoreItem,
	CIvtrTalentChangeItem	= CIvtrTalentChangeItem,
	CIvtrRefineStoreItem    = CIvtrRefineStoreItem,
	CIvtrHotTimeItem        = CIvtrHotTimeItem,
	CIvtrBagExtendItem      = CIvtrBagExtendItem,

	ItemTypeToClass = 
	{ 
		[SubItemType.NormalItem] 	= CIvtrNormalItem,
		[SubItemType.Equipment] 	= CIvtrEquip,
		[SubItemType.Material] 		= CIvtrMaterialItem,
		[SubItemType.Potion] 		= CIvtrMedicine,
		[SubItemType.QuestItem] 	= CIvtrQuestItem,
		[SubItemType.Rune] 			= CIvtrRuneItem,
		[SubItemType.Horse] 		= CIvtrHorseItem,
		[SubItemType.TreasureBox]	= CIvtrTreasureBoxItem,
		[SubItemType.Pet]			= CIvtrPetItem,
		[SubItemType.Charm]			= CIvtrCharmItem,
		[SubItemType.Wing]			= CIvtrWingItem,
		[SubItemType.Dress]  		= CIvtrDressItem,
		[SubItemType.PetExpPotion]  = CIvtrPetExpPotionItem,
		[SubItemType.Wanted]  		= CIvtrWantedItem,
		[SubItemType.PetTalentBook] = CIvtrPetTalentBookItem,
		[SubItemType.EnchantReel]   = CIvtrEnchantReelItem,
		[SubItemType.Pray] 			= CIvtrGuildPrayItem,
		[SubItemType.Evil] 			= CIvtrEvilItem,
		[SubItemType.InforceStone]  = CIvtrInforceStoneItem,
		[SubItemType.LuckyStone]	= CIvtrLuckyStoneItem,
		[SubItemType.SafeStone]		= CIvtrSafeStoneItem,
		[SubItemType.RebuildStore]	= CIvtrRebuildStoreItem,
		[SubItemType.TalentChange]	= CIvtrTalentChangeItem,
		[SubItemType.RefineStore]	= CIvtrRefineStoreItem,	
		[SubItemType.HotTime]	    = CIvtrHotTimeItem,
		[SubItemType.BagExtend]     = CIvtrBagExtendItem,
	},
}