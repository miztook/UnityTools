local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelDebug = require "GUI.CPanelDebug"
local CElementData = require "Data.CElementData"
local CPageQuest = require "GUI.CPageQuest"
local QualitySettingMan = require "Main.QualitySettingMan"

local CPanelHuangxinTest = Lplus.Extend(CPanelBase, "CPanelHuangxinTest")
local def = CPanelHuangxinTest.define

local Level1Tabs =
{
	{
		TabName = "快捷常用",
		Level2Tabs = 
		{
			{
				TabName = "通用",
				PanelName = "Panel_Shortcut",
			}
		}
	},
	{
		TabName = "角色对象",
		Level2Tabs = 
		{
			{
				TabName = "基础",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "对象生成",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "生成器",
				PanelName = "Panel_ComingSoon",
			}
		}
	},
	{
		TabName = "货币道具",
		Level2Tabs = 
		{
			{
				TabName = "货币",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "坐骑",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "翅膀",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "纹章",
				PanelName = "Panel_Heraldry",
			}
		}
	},
	{
		TabName = "任务流程",
		Level2Tabs = 
		{
			{
				TabName = "任务",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "副本关卡",
				PanelName = "Panel_ComingSoon",
			},
		}
	},
	{
		TabName = "场景地图",
		Level2Tabs = 
		{
			{
				TabName = "大地图",
				PanelName = "Panel_ComingSoon",
				Level3Tabs = 
				{
					{
						TabName = "东部领地",
						PanelName = "Panel_Map1_120",
					},
					{
						TabName = "阿卡尼亚",
						PanelName = "Panel_ComingSoon",
					},
					{
						TabName = "法雷门旷野",
						PanelName = "Panel_ComingSoon",
					},
					{
						TabName = "霍加斯公国",
						PanelName = "Panel_ComingSoon",
					}
				}
			},
			{
				TabName = "主城",
				PanelName = "Panel_ComingSoon",
				Level3Tabs = 
				{
					{
						TabName = "好望港",
						PanelName = "Panel_ComingSoon",
					}
				}
			},
			{
				TabName = "副本",
				PanelName = "Panel_ComingSoon",
			}
		}
	},
	{
		TabName = "其他内容",
		Level2Tabs = 
		{
			{
				TabName = "称号",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "声望",
				PanelName = "Panel_ComingSoon",
			},
			{
				TabName = "公会",
				PanelName = "Panel_ComingSoon",
			},
		}
	},
	{
		TabName = "查错调试",
		Level2Tabs = 
		{
			{
				TabName = "功能开关",
				PanelName = "Panel_Function",
			},
			{
				TabName = "操作",
				PanelName = "Panel_Operation",
			},
			{
				TabName = "信息",
				PanelName = "Panel_Info",
			},
			{
				TabName = "统计",
				PanelName = "Panel_Statistics",
			},
			{
				TabName = "UI",
				PanelName = "Panel_UI",
			},
			{
				TabName = "内存",
				PanelName = "Panel_Memory",
			},
			{
				TabName = "版本信息",
				PanelName = "Panel_Version",
			},
		}
	},
}

local MaxLevel1TabCount = 8


def.field("number")._TimerId = 0
def.field("number")._HeartbeatInterval = 1

def.field("userdata")._Btn_Close = nil
--分页
--便捷测试
def.field("userdata")._Btn_MaxSpeed = nil
def.field("userdata")._Btn_MaxMoney = nil
def.field("userdata")._Btn_Client_FunOpen = nil
def.field("userdata")._Btn_MaxLevel = nil

--系统功能
def.field("userdata")._Dropdown_LogLevel = nil
def.field("userdata")._Lab_CLRMemCur = nil
def.field("userdata")._Lab_CLRMemLastGC = nil
def.field("userdata")._Lab_CLRMemGCCount = nil
def.field("userdata")._Lab_LuaMemCur = nil
def.field("userdata")._Lab_LuaMemLastGC = nil
def.field("number")._LuaMemLastGC = 0
def.field("userdata")._Lab_LuaMemGCCount = nil
def.field("number")._LuaMemGCCount = 0
def.field("userdata")._Lab_RegistryTableSize = nil
def.field("userdata")._Lab_GlobalTableSize = nil

--UI
def.field("table")._CmdList = BlankTable

--版本信息
def.field("userdata")._Client_Lab_MainVersion = nil
def.field("userdata")._Lab_ClientSvnVer = nil

def.field("userdata")._Server_Lab_MainVersion = nil
def.field("userdata")._Lab_ServerSvnVer = nil
def.field("string")._ServerVersion = ""
def.field("number")._FirstEnterGameWorldTime = 0


--def.field("table")._CmdList = 
--{
--    "hide_mask",
--    "show_layer"
--}
def.field("userdata")._CmdHint = nil
def.field("userdata")._CmdHintText = nil




def.field("table")._All_Panel_Names = nil
def.field('userdata')._Frame_Panel = nil

def.field('userdata')._Rdo_TabGroup = nil
def.field("number")._Level1TabIndex = 1
def.field('userdata')._List_Toggle = nil
def.field('userdata')._GNewTabList = nil
def.field("number")._Level2TabIndex = 1
def.field("boolean")._IsTabOpen = false

--info
def.field('userdata')._Txt_RangeOfVisibilityValue = nil
def.field('userdata')._Txt_ActualDistScaleValue = nil
def.field('userdata')._Txt_SceneQualityValue = nil
def.field('userdata')._Txt_LODLevelValue = nil
def.field('userdata')._Txt_ScreenCurrentResolutionValue = nil
def.field('userdata')._Txt_IsEnableBloomHDValue = nil
def.field('userdata')._Txt_PostProcessLevelValue = nil
def.field('userdata')._Txt_MasterTextureLimitValue = nil

--Panel_Statistics
def.field('userdata')._Txt_OnLineTimeValue = nil
def.field('userdata')._Txt_ProtocolC2SValue = nil
def.field('userdata')._Txt_ProtocolS2CValue = nil
def.field('userdata')._Txt_NearbyPlayerValue = nil
def.field('userdata')._Txt_NearbyNPCValue = nil
def.field('userdata')._Txt_NearbySubobjectValue = nil
def.field('userdata')._Txt_NearbyMineValue = nil

def.field('number')._LastRecordProtocolC2SCount = 0
def.field('number')._PeakProtocolC2SCount = 0
def.field('number')._LastRecordProtocolS2CCount = 0
def.field('number')._PeakProtocolS2CCount = 0

def.field('number')._NearbyObjectSampleNum = 0
def.field('number')._PeakNearbyPlayerCount = 0
def.field('number')._NearbyPlayerAccumulate = 0
def.field('number')._PeakNearbyNPCCount = 0
def.field('number')._NearbyNPCAccumulate = 0
def.field('number')._PeakNearbySubobjectCount = 0
def.field('number')._NearbySubobjectAccumulate = 0
def.field('number')._PeakNearbyMineCount = 0
def.field('number')._NearbyMineAccumulate = 0


local instance = nil
def.static("=>", CPanelHuangxinTest).Instance = function()
	if not instance then
		instance = CPanelHuangxinTest()
		instance._DestroyOnHide = false
		instance._PrefabPath = PATH.UI_HuangxinTest
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.method().OnHeartbeat = function (self)
	self._Lab_CLRMemCur:GetComponent(ClassType.Text).text = GameUtil.GetCLRMemUseStringCur()
	self._Lab_CLRMemLastGC:GetComponent(ClassType.Text).text = GameUtil.GetCLRMemUseStringOnLastGC()
	self._Lab_CLRMemGCCount:GetComponent(ClassType.Text).text = string.format("CLRGC(%d)", GameUtil.GetCLRMemGCCount())

	self._Lab_LuaMemCur:GetComponent(ClassType.Text).text = string.format("%0.2f KB", collectgarbage("count"))
	self._Lab_LuaMemLastGC:GetComponent(ClassType.Text).text = string.format("%0.2f KB", self._LuaMemLastGC)
	self._Lab_LuaMemGCCount:GetComponent(ClassType.Text).text = string.format("LuaGC(%d)", self._LuaMemGCCount)
	self._Lab_RegistryTableSize:GetComponent(ClassType.Text).text = string.format("RegistryTableSize(%d)", GameUtil.GetRegistryTableSize())
	local globalTableSize = 0
	local str = ''
	for k, v in pairs(_G) do
		globalTableSize = globalTableSize + 1
		str = str .. tostring(k) .. ' = ' .. tostring(v) .. '\r\n'
	end
	self._Lab_GlobalTableSize:GetComponent(ClassType.Text).text = string.format("GlobalTableSize(%d)", globalTableSize)
	self._Txt_RangeOfVisibilityValue:GetComponent(ClassType.Text).text = GameUtil.GetGameCamCurDistOffset()
--	self._Txt_ActualDistScaleValue:GetComponent(ClassType.Text).text = GameUtil.GetActualDistScale()
	self._Txt_ActualDistScaleValue:GetComponent(ClassType.Text).text = "已删除"
	self._Txt_SceneQualityValue:GetComponent(ClassType.Text).text = GameUtil.GetSceneQuality()
	self._Txt_LODLevelValue:GetComponent(ClassType.Text).text = GameUtil.GetFxLODLevel()
	self._Txt_ScreenCurrentResolutionValue:GetComponent(ClassType.Text).text = GameUtil.GetScreenCurrentResolution()
	self._Txt_IsEnableBloomHDValue:GetComponent(ClassType.Text).text = GameUtil.IsEnableBloomHD()
	self._Txt_PostProcessLevelValue:GetComponent(ClassType.Text).text = QualitySettingMan.Instance():GetPostProcessLevel()
	self._Txt_MasterTextureLimitValue:GetComponent(ClassType.Text).text = GameUtil.GetMasterTextureLimit()

	local second = (GameUtil.GetClientTime() - self._FirstEnterGameWorldTime) / 1000
	self._Txt_OnLineTimeValue:GetComponent(ClassType.Text).text = string.format("%0.0fs", second)

	local cur_count = _G._TotalSendProtoCount - self._LastRecordProtocolC2SCount
	self._PeakProtocolC2SCount = math.max(self._PeakProtocolC2SCount, cur_count)
	self._Txt_ProtocolC2SValue:GetComponent(ClassType.Text).text =
		cur_count .. "/s、" .. self._PeakProtocolC2SCount .. "/s、" .. string.format("%0.1f/s", _G._TotalSendProtoCount / second) .. "、" .. _G._TotalSendProtoCount
	self._LastRecordProtocolC2SCount = _G._TotalSendProtoCount

	cur_count = _G._TotalRecvProtoCount - self._LastRecordProtocolS2CCount
	self._PeakProtocolS2CCount = math.max(self._PeakProtocolS2CCount, cur_count)
	self._Txt_ProtocolS2CValue:GetComponent(ClassType.Text).text = 
		cur_count .. "/s、" .. self._PeakProtocolS2CCount .. "/s、" .. string.format("%0.1f/s", _G._TotalRecvProtoCount / second) .. "、" .. _G._TotalRecvProtoCount
	self._LastRecordProtocolS2CCount = _G._TotalRecvProtoCount

	local cur_world = game._CurWorld
	if cur_world ~= nil then
		self._NearbyObjectSampleNum = self._NearbyObjectSampleNum + 1

		cur_count = table.nums(cur_world._PlayerMan._ObjMap)
		self._PeakNearbyPlayerCount = math.max(self._PeakNearbyPlayerCount, cur_count)
		self._NearbyPlayerAccumulate = self._NearbyPlayerAccumulate + cur_count
		self._Txt_NearbyPlayerValue:GetComponent(ClassType.Text).text = cur_count .. "、" .. self._PeakNearbyPlayerCount .. "、" .. string.format("%0.1f", self._NearbyPlayerAccumulate / self._NearbyObjectSampleNum)
		
		cur_count = table.nums(cur_world._NPCMan._ObjMap)
		self._PeakNearbyNPCCount = math.max(self._PeakNearbyNPCCount, cur_count)
		self._NearbyNPCAccumulate = self._NearbyNPCAccumulate + cur_count
		self._Txt_NearbyNPCValue:GetComponent(ClassType.Text).text = cur_count .. "、" .. self._PeakNearbyNPCCount .. "、" .. string.format("%0.1f", self._NearbyNPCAccumulate / self._NearbyObjectSampleNum)

		cur_count = table.nums(cur_world._SubobjectMan._ObjMap)
		self._PeakNearbySubobjectCount = math.max(self._PeakNearbySubobjectCount, cur_count)
		self._NearbySubobjectAccumulate = self._NearbySubobjectAccumulate + cur_count
		self._Txt_NearbySubobjectValue:GetComponent(ClassType.Text).text = cur_count .. "、" .. self._PeakNearbySubobjectCount .. "、" .. string.format("%0.1f", self._NearbySubobjectAccumulate / self._NearbyObjectSampleNum)

		cur_count = table.nums(cur_world._MineObjectMan._ObjMap)
		self._PeakNearbyMineCount = math.max(self._PeakNearbyMineCount, cur_count)
		self._NearbyMineAccumulate = self._NearbyMineAccumulate + cur_count
		self._Txt_NearbyMineValue:GetComponent(ClassType.Text).text = cur_count .. "、" .. self._PeakNearbyMineCount .. "、" .. string.format("%0.1f", self._NearbyMineAccumulate / self._NearbyObjectSampleNum)

	end

end

def.method().AddTimer = function(self)
	self:RemoveTimer()
	self._TimerId = _G.AddGlobalTimer(self._HeartbeatInterval, false ,function()
		self:OnHeartbeat()
	end)
end

def.method().RemoveTimer = function(self)
	if self._TimerId ~= 0 then
		_G.RemoveGlobalTimer(self._TimerId)
		self._TimerId = 0
	end
end


def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    print("CPanelHuangxinTest OnInitItem")
end

def.override().OnCreate = function(self)
    print("CPanelHuangxinTest OnCreate")
	self._Btn_Close = self:GetUIObject("Btn_Close")

	self._Btn_MaxSpeed = self:GetUIObject("Btn_MaxSpeed")
	self._Btn_MaxMoney = self:GetUIObject("Btn_MaxMoney")
	self._Btn_Client_FunOpen = self:GetUIObject("Btn_Client_FunOpen")
	self._Btn_MaxLevel = self:GetUIObject("Btn_MaxLevel")

	self._Dropdown_LogLevel = self:GetUIObject("Dropdown_LogLevel")
	self._Lab_CLRMemCur = self:GetUIObject("Lab_CLRMemCur")
	self._Lab_CLRMemLastGC = self:GetUIObject("Lab_CLRMemLastGC")
	self._Lab_CLRMemGCCount = self:GetUIObject("Lab_CLRMemGCCount")
	self._Lab_LuaMemCur = self:GetUIObject("Lab_LuaMemCur")
	self._Lab_LuaMemLastGC = self:GetUIObject("Lab_LuaMemLastGC")
	self._Lab_LuaMemGCCount = self:GetUIObject("Lab_LuaMemGCCount")
	self._Lab_RegistryTableSize = self:GetUIObject("Lab_RegistryTableSize")
	self._Lab_GlobalTableSize = self:GetUIObject("Lab_GlobalTableSize")


    self._CmdHint = self:GetUIObject("Tip_CMDHinit")
    self._CmdHintText = self:GetUIObject("Lab_CMDHintText")

	self._Client_Lab_MainVersion = self:GetUIObject("Client_Lab_MainVersion")
	self._Lab_ClientSvnVer = self:GetUIObject("Lab_ClientSvnVer")

	self._Server_Lab_MainVersion = self:GetUIObject("Server_Lab_MainVersion")
	self._Lab_ServerSvnVer = self:GetUIObject("Lab_ServerSvnVer")

	self._Client_Lab_MainVersion:GetComponent(ClassType.Text).text = "CN-trunk"
	--self._Client_Lab_MainVersion:GetComponent(ClassType.Text).text = "CN-1.0.5"

	local logLevel = GameUtil.GetLogLevel()
	--self._Dropdown_LogLevel:GetComponent(ClassType.Dropdown).value = logLevel
	GameUtil.MonitorGC(true)

	-- --5.1版本不生效__gc函数只在c代码中可以,无法跟踪lua gc调用
	-- local function NewGCMonitorObject()
	-- 	local GCMonitorObject = {}
	-- 	local OnGCCall = function()
	-- 		warn("huangxin lua gc")
	-- 		NewGCMonitorObject()
	-- 	end
	-- 	setmetatable(GCMonitorObject, { ["__gc"] = OnGCCall })
	-- end
	-- NewGCMonitorObject()

	--新版相关代码
    self._Frame_Panel = self:GetUIObject("Frame_Panel")
	self._All_Panel_Names = {}
    local function InsertOnePanel(panelName)
    	local panel = self._Frame_Panel:FindChild(panelName)
		if panel == nil then
			warn("黄鑫的测试面板中无法找到面板：", panelName)
		else
			table.insert(self._All_Panel_Names, panel)
		end
    end

	for i = 1, #Level1Tabs do
		local level1Tab = Level1Tabs[i]
		for j = 1, #level1Tab.Level2Tabs do
			local level2Tab = level1Tab.Level2Tabs[j]
			if level2Tab.PanelName == nil then
				warn("黄鑫的测试面板中对应页签：", level2Tab.TabName, "中缺少字段PanelName")
			else
				InsertOnePanel(level2Tab.PanelName)
				if level2Tab.Level3Tabs ~= nil then
					for k = 1, #level2Tab.Level3Tabs do
						local level3Tab = level2Tab.Level3Tabs[k]
						if level3Tab.PanelName == nil then
								warn("黄鑫的测试面板中对应页签：", level3Tab.TabName, "中缺少字段PanelName")
						else
							InsertOnePanel(level3Tab.PanelName)
						end
					end
				end
			end
		end
	end

	self._Rdo_TabGroup = self:GetUIObject("Rdo_TabGroup")
	self._List_Toggle = self:GetUIObject("List_Toggle")
	self._GNewTabList = self._List_Toggle:GetComponent(ClassType.GNewTabList)
	for i = 1, MaxLevel1TabCount do
		local panelInfo = Level1Tabs[i]
		local tabLevel = self._Rdo_TabGroup:FindChild("Tab_Level_" .. i)
		if panelInfo ~= nil and tabLevel ~= nil then
			--warn("huangxin 1234", panelInfo.TabName, tabLevel)
			tabLevel:FindChild("Img_U/Lab_Name"):GetComponent(ClassType.Text).text = panelInfo.TabName
			tabLevel:FindChild("Img_D/Lab_Name"):GetComponent(ClassType.Text).text = panelInfo.TabName
		else
			tabLevel:SetActive(false)
		end
	end
	self:CloseAllPanels()
	self:Level1TabOnToggle("Tab_Level_1")
	self._List_Toggle:SetActive(true)


	self._Lab_ClientSvnVer:GetComponent(ClassType.Text).text = GameUtil.GetClientVersion() .. "\n" .. GameUtil.GetABVersion()
	self._Lab_ServerSvnVer:GetComponent(ClassType.Text).text = self._ServerVersion

	self._Txt_RangeOfVisibilityValue = self:GetUIObject("Txt_RangeOfVisibilityValue")
	self._Txt_ActualDistScaleValue = self:GetUIObject("Txt_ActualDistScaleValue")
	self._Txt_SceneQualityValue = self:GetUIObject("Txt_SceneQualityValue")
	self._Txt_LODLevelValue = self:GetUIObject("Txt_LODLevelValue")
	self._Txt_ScreenCurrentResolutionValue = self:GetUIObject("Txt_ScreenCurrentResolutionValue")
	self._Txt_IsEnableBloomHDValue = self:GetUIObject("Txt_IsEnableBloomHDValue")
	self._Txt_PostProcessLevelValue = self:GetUIObject("Txt_PostProcessLevelValue")
	self._Txt_MasterTextureLimitValue = self:GetUIObject("Txt_MasterTextureLimitValue")

	self._Txt_OnLineTimeValue = self:GetUIObject("Txt_OnLineTimeValue")
	self._Txt_ProtocolC2SValue = self:GetUIObject("Txt_ProtocolC2SValue")
	self._Txt_ProtocolS2CValue = self:GetUIObject("Txt_ProtocolS2CValue")
	self._Txt_NearbyPlayerValue = self:GetUIObject("Txt_NearbyPlayerValue")
	self._Txt_NearbyNPCValue = self:GetUIObject("Txt_NearbyNPCValue")
	self._Txt_NearbySubobjectValue = self:GetUIObject("Txt_NearbySubobjectValue")
	self._Txt_NearbyMineValue = self:GetUIObject("Txt_NearbyMineValue")

end

def.override("dynamic").OnData = function(self, data)
    print("CPanelHuangxinTest OnData")
    --当前值和峰值，只有在界面开启之后才统计
    self._LastRecordProtocolC2SCount = _G._TotalSendProtoCount
    self._LastRecordProtocolS2CCount = _G._TotalRecvProtoCount

	self:AddTimer()
	--GameUtil.MonitorGC(true)
end

def.override().OnHide = function(self)
    print("CPanelHuangxinTest OnHide")
    CPanelBase.OnHide(self)
	self:RemoveTimer()
	--GameUtil.MonitorGC(false)
end

def.override().OnDestroy = function (self)
    print("CPanelHuangxinTest OnDestroy")
	self._Btn_Close = nil
	self._Btn_MaxSpeed = nil
	self._Btn_MaxMoney = nil
	self._Btn_Client_FunOpen = nil
	self._Btn_MaxLevel = nil

	self._Dropdown_LogLevel = nil
	self._Lab_CLRMemCur = nil
	self._Lab_CLRMemLastGC = nil
	self._Lab_CLRMemGCCount = nil
	self._Lab_LuaMemCur = nil
	self._Lab_LuaMemLastGC = nil
	self._Lab_LuaMemGCCount = nil
	self._Lab_RegistryTableSize = nil
	self._Lab_GlobalTableSize = nil

	self._CmdHint = nil
	self._CmdHintText = nil

	self._Client_Lab_MainVersion = nil
	self._Lab_ClientSvnVer = nil
	self._Server_Lab_MainVersion = nil
	self._Lab_ServerSvnVer = nil

	self._List_Toggle = nil
	self._Txt_RangeOfVisibilityValue = nil
	self._Txt_ActualDistScaleValue = nil
	self._Txt_SceneQualityValue = nil
	self._Txt_LODLevelValue = nil
	self._Txt_ScreenCurrentResolutionValue = nil
	self._Txt_IsEnableBloomHDValue = nil
	self._Txt_PostProcessLevelValue = nil
	self._Txt_MasterTextureLimitValue = nil

	self._Txt_OnLineTimeValue = nil
	self._Txt_ProtocolC2SValue = nil
	self._Txt_ProtocolS2CValue = nil
	self._Txt_NearbyPlayerValue = nil
	self._Txt_NearbyNPCValue = nil
	self._Txt_NearbySubobjectValue = nil
	self._Txt_NearbyMineValue = nil

end

def.override("string", "number").OnDropDown = function(self, id, index)
	if id == "Dropdown_LogLevel" then
		GameUtil.SetLogLevel(index)
	end
end

------------------UI Frame <<

local _cmdList =
 {
    ["hide_mask"] = "hide_mask",
    ["show_layer"] = "show_layer",
    ["collapse_layer"] = "collapse_layer",
    ["full_screen"] = "full_screen",
    ["log_+-"] = "log_+-",
    ["log_charInput"] = "log_charInput",
    ["show_tipQ"] = "show_tipQ",
    ["show_psSta"] = "show_psSta",
    ["show_WBtip"] = "show_WBtip",
	["show_BTip"]="show_BTip",
	["show_ui_pos"]="show_ui_pos",
}

def.override("string","string").OnEndEdit = function(self, goName, str)
    if goName == "InputField_Cmd" then

		local call_table = string.split(str, " ")
		local str_call = call_table[1]

        local uiManCore = game._GUIMan._UIManCore
        if(str_call == "show_layer") then
            uiManCore:Debug_LogLayer()
        elseif(str_call == "collapse_layer") then
            uiManCore:Debug_CollapseLayer()
        elseif(str_call == "hide_mask") then
            uiManCore:Debug_LogHideMask()
        elseif(str_call == "full_screen") then
            uiManCore:Debug_LogFullScreenUI()
        elseif(str_call== "log_+-") then
            uiManCore:Debug_LogAddRemove()
        elseif(str_call== "log_charInput") then
            GameUtil.LogCharInput()
        elseif(str_call == "show_tipQ") then
            uiManCore:Debug_TipQ()
        elseif(str_call == "show_psSta") then
            uiManCore:Debug_SleepingState()
        elseif(str_call == "show_WBtip") then
            uiManCore:Debug_WBTip()
        elseif(str_call == "show_BTip") then
            game._GUIMan:PopBattleStgTip(1)
		elseif(str_call == "show_ui_pos") then
            GameUtil.DebugLogUIRT(call_table[2])
        end

        GUITools.SetUIActive(self._CmdHint, false)
    end
end

def.override("string","string").OnValueChanged = function(self, goName, str)
    if goName == "InputField_Cmd" then
        GUITools.SetUIActive(self._CmdHint, true)
        local str_ret = "\n"
        if string.len(str) > 0 then
            for k,v in pairs(_cmdList) do
                if k == str or string.find(k, str) then
                    str_ret = str_ret..v.."\n"
                end
            end
        end

        GUI.SetTextAndChangeLayout(self._CmdHintText, str_ret, 300)
    end
end
------------------>> UI Frame



--新的开始
--初始化相关
def.method("string").Level1TabOnToggle = function(self, id)
	self._Level1TabIndex = tonumber(string.sub(id, string.len("Tab_Level_") + 1))
	local level2Tabs= Level1Tabs[self._Level1TabIndex].Level2Tabs
	--warn("huangxin test", id, self._Level1TabIndex, #level2Tabs)
	self._GNewTabList:SetItemCount(#level2Tabs)
	for i = 1, #level2Tabs do
		local level2Tab = level2Tabs[i]
		--warn("huangxin level2Tab", level2Tab.TabName)
	end

	self._IsTabOpen = false
	--暂时选第一个
	self:OnClickTabListLevel1(self._GNewTabList, 1)
	--self._GNewTabList:SetSelection(0, -1)
end

def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
	if list.name == "List_Toggle" then
		self:List_ToggleOnTabListInitItem(list, item, main_index, sub_index)
	end
end

def.method("userdata", "userdata", "number", "number").List_ToggleOnTabListInitItem = function(self, list, item, main_index, sub_index)
	--warn("huangxin InitList_Toggle", main_index, sub_index)
    if sub_index == -1 then
        self:OnInitTabListLevel1(item, main_index + 1)
    elseif sub_index ~= -1 then
        self:OnInitTabListLevel2(item, main_index + 1, sub_index + 1)
    end
end

def.method('userdata', 'number').OnInitTabListLevel1 = function(self, item, index)
	local level2Tab = Level1Tabs[self._Level1TabIndex].Level2Tabs[index]
	--warn("adsf", Level1Tabs[self._Level1TabIndex], index)
	local str = level2Tab.TabName
    item:FindChild("Img_U/Lab_Tag1"):GetComponent(ClassType.Text).text = str
    item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = str
end

def.method('userdata', 'number', 'number').OnInitTabListLevel2 = function(self, item, main_index, sub_index)
	local level3Tab = Level1Tabs[self._Level1TabIndex].Level2Tabs[main_index].Level3Tabs[sub_index]
	local str = level3Tab.TabName
    item:FindChild("Img_U/Lab_Tag1"):GetComponent(ClassType.Text).text = str
    item:FindChild("Img_D/Lab_Tag1"):GetComponent(ClassType.Text).text = str
end

--操作相关
def.override("string", "boolean").OnToggle = function(self, id, checked)
	if id == "Rdo_DebugMode" then
		if checked then
			CPanelDebug.Instance():OpenDebugMode()
		else
			CPanelDebug.Instance():CloseDebugMode()
		end
	elseif id == "Rdo_HUD" then
		CPanelDebug.Instance()._SWITCH_HUD_TEXT = checked
	elseif id == "Rdo_NavMesh" then
		local cmd_strNavmesh = ""
		if checked then
			cmd_strNavmesh = "navmesh 1"
		else
			cmd_strNavmesh = "navmesh 0"	
		end
		game:DebugString(cmd_strNavmesh)
	elseif id == "Rdo_Fx" then
		CFxMan.Instance()._IsAllFxHiden = not checked
	elseif id == "Rdo_C2S" then
		_G.logc2s = checked
	elseif id == "Rdo_S2C" then
		_G.logs2c = checked

	elseif id == "Rdo_UIEvent" then
		GameUtil.DebugUI(checked)
	else
		self:Level1TabOnToggle(id)
	end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
	if list.name == "List_Toggle" then
		self:List_ToggleOnTabListSelectItem(list, item, main_index, sub_index)
	end
end

def.method("userdata", "userdata", "number", "number").List_ToggleOnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if sub_index == -1 then
        self:OnClickTabListLevel1(list, main_index + 1)
    elseif sub_index ~= -1 then
        local bigTypeIndex = main_index + 1
        local smallTypeIndex = sub_index + 1
        self:OnClickTabListLevel2(list,bigTypeIndex,smallTypeIndex)
    end
end

def.method('userdata', 'number').OnClickTabListLevel1 = function(self, list, index)
	--warn("huangxin OnClickTabListLevel1", list, index, self._Level2TabIndex)
	self._GNewTabList:SetSelection(index - 1, -1)
	self:CloseAllPanels()
	self:ShowThePanel(self._Level1TabIndex, index, 0)
	if index == 0 then
	    self._GNewTabList:OpenTab(0)
	    self._Level2TabIndex = 0
	else
		local function OpenTab()
			--如果有小类型 打开小类型
			local level3Tabs = Level1Tabs[self._Level1TabIndex].Level2Tabs[index].Level3Tabs
			if level3Tabs == nil then
				self._GNewTabList:OpenTab(0)
			else
			    self._GNewTabList:OpenTab(#level3Tabs)
			    if #level3Tabs > 0 then
			        self._IsTabOpen = true
			    end
			end
		end

		local function CloseTab()
		    self._GNewTabList:OpenTab(0)
		    self._IsTabOpen = false
		end
		if self._Level2TabIndex == index then
		    if self._IsTabOpen then
		        CloseTab()
		    else
		        OpenTab()
		    end
		else
		    OpenTab()
		end
	end
	self._Level2TabIndex = index
end

def.method('userdata','number','number').OnClickTabListLevel2 = function(self, list, main_index, sub_index)
	self._GNewTabList:SetSelection(main_index - 1, sub_index - 1)
	self:CloseAllPanels()
	self:ShowThePanel(self._Level1TabIndex, main_index, sub_index)
end

local S1 = nil

def.override('userdata').OnClickGameObject = function(self, gameObj)
	local gameObjName = gameObj.name
	if gameObjName == "Btn_Close" then
		--保存
		game._GUIMan:CloseByScript(self)
	--快捷常用
	elseif gameObjName == "Btn_KillAllMonster" then
		game:DebugString("c 73")
	elseif gameObjName == "Btn_CommitSuicide" then
		game:DebugString("c 41")

	elseif gameObjName == "Btn_GetCurMainQuestDone" then
		local pageQuestInstance = CPageQuest.Instance()
		if pageQuestInstance == nil then return end
		local mainQuestId = pageQuestInstance._QuestCurrent[1]
		if mainQuestId == nil then return end
		--local cmd = "c 61 " .. mainQuestId .. " 1"
		--game:DebugString(cmd)
		local cmd = "c 60 " .. mainQuestId
		game:DebugString(cmd)

	elseif gameObjName == "Btn_GainCurMainQuest" then
		local pageQuestInstance = CPageQuest.Instance()
		if pageQuestInstance == nil then return end
		local mainQuestId = pageQuestInstance._QuestCurrent[1]
		if mainQuestId == nil then return end
		--local cmd = "c 61 " .. mainQuestId .. " 1"
		--game:DebugString(cmd)
		local cmd = "c 61 " .. mainQuestId
		game:DebugString(cmd)

	elseif gameObjName == "Btn_GetInstanceStepDone" then
		game:DebugString("c 69 555")
	elseif gameObjName == "Btn_SkipOneStepGuide" then
		game._CGuideMan:JumpCurGuide()
	elseif gameObjName == "Btn_Server_FunOpen" then
		game:DebugString("c 372")

	elseif gameObjName == "Btn_SkipGuide" then
		game._CGuideMan:SetOpenDebugGuide(false)
	elseif gameObjName == "Btn_SkipFirstInstance" then
		game:DebugString("c 701")
--[[		game._CGuideMan._CurGuideID = 10
		game._CGuideMan._LastGuideID = 9
		
		game._CGuideMan:DebugCloseGuidePanel()
		game._CGuideMan:OnServer(10)--]]

		game._CGuideMan:JumpCurGuide()
	elseif gameObjName == "Btn_Client_FunOpen" then
		local cmd = "c 372"
		game:DebugString(cmd)
	elseif gameObjName == "Btn_Client_FunClose" then
		game._CFunctionMan:SetOpenAll4Debug(false)

	elseif gameObjName == "Btn_CLRMemGC" then
		GameUtil.GC(true)
	elseif gameObjName == "Btn_LuaMemGC" then
		collectgarbage("collect")
		self._LuaMemLastGC = collectgarbage("count")
		self._LuaMemGCCount = self._LuaMemGCCount + 1
		
	elseif gameObjName == "Btn_Snapshot" then
		collectgarbage("collect")
		if S1 == nil then
			S1 = snapshot()

			print("S1 Snapshot")
		else
			local S2 = snapshot()

			print("Snapshot diff!")

			for k,v in pairs(S2) do
				if S1[k] == nil then
					print(k,v)
				end
			end
			S1 = nil
			S2 = nil
			collectgarbage("collect")
		end
	elseif gameObjName == "Btn_GetAllRuneByProf" then
		local hp = game._HostPlayer
		local prof = hp._InfoData._Prof
		local allItemTids = GameUtil.GetAllTid("Item")
		for _,v in ipairs(allItemTids) do
			if v > 0 then
				local itemTemplate = CElementData.GetTemplate("Item", v)
				local EItemEventType = require "PB.data".EItemEventType	--物品使用 类型
				if EItemEventType.ItemEvent_Rune == itemTemplate.EventType1 then
					local profMask = EnumDef.Profession2Mask[prof]
					local bit = require "bit"
					if profMask == bit.band(itemTemplate.ProfessionLimitMask, profMask) then
						local cmd = "c 31 " .. v
						game:DebugString(cmd)
					end
				end
			end
		end
	elseif gameObjName == "Btn_All" then
		self:OnClickGameObject(self._Btn_MaxSpeed)
		self:OnClickGameObject(self._Btn_MaxMoney)
		self:OnClickGameObject(self._Btn_MaxLevel)
		self:OnClickGameObject(self._Btn_Client_FunOpen)
		self:OnClickGameObject(self._Btn_Close)
	elseif string.sub(gameObjName, 1, string.len("Btn_")) == "Btn_" then
		local cmds = string.split(gameObj:FindChild("Img_Bg/Lab_Cmd"):GetComponent(ClassType.Text).text, "\n") 
		for _, cmd in ipairs(cmds) do
			game:DebugString(cmd)
		end
	end
end

--显示相关
def.method('number', 'number', 'number').ShowThePanel = function(self, level1, level2, level3)
	local panelName = ""
	local level1Tab = Level1Tabs[level1]
	local level2Tab = level1Tab.Level2Tabs[level2]
	if level3 ~= 0 then
		local level3Tab = level2Tab.Level3Tabs[level3]
		panelName = level3Tab.PanelName
	else
		panelName = level2Tab.PanelName
	end
	self:ShowThePanelByName(panelName)
end

def.method('string').ShowThePanelByName = function(self, panelName)
	local panel = self._Frame_Panel:FindChild(panelName)
	panel:SetActive(true)
end

def.method().CloseAllPanels = function(self)
	for i = 1, #self._All_Panel_Names do
		local panel = self._All_Panel_Names[i]
		panel:SetActive(false)
	end
end

--具体面板内容实现

--查错调试
--版本信息
def.method("string").SetServerVersion = function(self, serverVersion)
	self._ServerVersion = serverVersion
end

def.method().OnFirstEnterGameWorld = function(self)
    print("CPanelHuangxinTest OnFirstEnterGameWorld")
    self._FirstEnterGameWorldTime = GameUtil.GetClientTime()
end


CPanelHuangxinTest.Commit()
return CPanelHuangxinTest
