local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelDebug = Lplus.Extend(CPanelBase, "CPanelDebug")
local def = CPanelDebug.define

def.field("userdata")._PanelGmTest = nil
def.field("boolean")._ShowPanelGmTest = false
def.field("userdata")._InputInstructions = nil
def.field('userdata')._Lab_Explain = nil
def.field("userdata")._UIOrderList = nil
def.field("userdata")._Frame_PageConnection = nil
def.field("boolean")._UseFuncTestButton = false
def.field("number")._M_TimerId = 0
def.field("boolean")._SWITCH_HUD_TEXT = true


local function TestFunction(self)
	local CNotificationMan = require "Main.CNotificationMan"
	-- 申请权限
	CNotificationMan.Instance():RegisterLocalNotificationPermission()
	-- 清空注册列表
	CNotificationMan.Instance():CleanLocalNotification()
	-- 注册推送信息
	CNotificationMan.Instance():RegisterLocalNotificationMessage("标题","这是一条测试推送信息",19, 0, true)

	GameUtil.Test()
end

local instance = nil
local cmd_Command = nil
local cmd_explain = nil
local orderList = {}


def.static("=>", CPanelDebug).Instance = function()
	if instance == nil then
		instance = CPanelDebug()
		instance._PrefabPath = PATH.UI_Debug
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end

	self._PanelGmTest = self:GetUIObject("Frame_CMD")
	self._UIOrderList = self:GetUIObject("List_Order"):GetComponent(ClassType.GNewListLoop)
	self._InputInstructions = self:GetUIObject("Input_Instructions"):GetComponent(ClassType.InputField)
	self._Frame_PageConnection = self:GetUIObject("Frame_PageConnection")

	self._PanelGmTest:SetActive(false)
	self._ShowPanelGmTest = false

	if self._UseFuncTestButton then
		self:GetUIObject("Btn_FuncTest"):SetActive(true)
	end
end

def.override("dynamic").OnData = function(self, data)
	
end

def.method().TogglePanelGmTest = function(self)
	self._ShowPanelGmTest = not self._ShowPanelGmTest
	self._PanelGmTest:SetActive(self._ShowPanelGmTest)
	GameUtil.EnableCmdsInputMode(self._ShowPanelGmTest)
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Cmd" then
		self:TogglePanelGmTest()

	elseif id == "Btn_Back" then
		self:TogglePanelGmTest()
	elseif id == "Btn_HuangxinTest" then
		game._GUIMan:Open("CPanelHuangxinTest", nil)
	elseif id == "Btn_Input" then
		local cmd_str = self:GetUIObject("Lab_Input"):GetComponent(ClassType.Text).text
		if cmd_str ~= nil then
			if cmd_str == "Fx 0" then
				CFxMan.Instance()._IsAllFxHiden = true
				return
			elseif cmd_str == "Fx 1" then
				CFxMan.Instance()._IsAllFxHiden = false
				return
			elseif cmd_str == "HUD 0" then
				self._SWITCH_HUD_TEXT = false
			elseif cmd_str == "HUD 1" then
				self._SWITCH_HUD_TEXT = true
			elseif cmd_str == "FunOpen 0" then
				game._CFunctionMan:SetOpenAll4Debug(false)
			elseif cmd_str == "FunOpen 1" then
				game._CFunctionMan:SetOpenAll4Debug(true)
			elseif cmd_str == "GuideOpen 0" then
				game._CGuideMan:SetOpenDebugGuide(false)
			elseif cmd_str == "GuideOpen 1" then
				game._CGuideMan:SetOpenDebugGuide(true)
			elseif cmd_str == "GuideJump" then
				game._CGuideMan:JumpCurGuide()
			elseif cmd_str=="TestMove" then
				--self:CountFrameAndSave()
				--关闭省电模式
				--[[game._CPowerSavingMan:Enable(false)
				local hp=game._HostPlayer
				
				-- if not hp._IsClickGroundMove then return end
				-- if hp._SkillHdl:IsApproachingTarget() then
				-- 	hp._SkillHdl:CancelSkill()
				-- end
				local MapBasicConfig = require "Data.MapBasicConfig" 
				local sceneId = game._CurWorld._WorldInfo.SceneTid
				local  allmapInfo = MapBasicConfig.GetTestMapConfigBySceneID(sceneId)

				if #allmapInfo > 0 then
					local now_info = allmapInfo
					if now_info ~=nil then

						local  index = 1
						local  function  NextPos( ... )
							index=index+1

							--这里做一个循环操作
							if index > #now_info then
								index = 1
							end

							if now_info[index] ~= nil then
								hp:Move(Vector3.New(now_info[index].x,now_info[index].y,now_info[index].z),0,NextPos,NextPos)
							end
						end 

						hp:Move(Vector3.New(now_info[index].x,now_info[index].y,now_info[index].z),0,NextPos,NextPos)
					end
				end
				-- hp:StopAutoLogic()
				
				-- local function NextPos( ... )
				-- 	hp:Move(Vector3.New(-49.218,29.89,171.80),0,nil,nil)
				-- end
				-- hp:Move(Vector3.New(-62.1,31.11,166.4),0,NextPos,NextPos)
				--]]

				--CTransDataHandler.Instance():CanMoveToTargetPos(self._CurMapID, V3pos)

			elseif cmd_str=="CountFrame" then
				local CTransDataHandler = require "Transfer.CTransDataHandler"
				local sceneId = game._CurWorld._WorldInfo.SceneTid
				local hp=game._HostPlayer

				local  xStart = 0
				local xEnd = 200

				local  zStart = 0
				local zEnd = 200

				local  x = xStart
				local  z = zStart

				local  nextTurn = false
				local  turnEnd = false

				local Timer = 0 -- 类似计时器吧 就是我也不知道怎么说 看代码理解 
				local  timerID = 0



				local  function AddPosXZ( )
					if x < xEnd then
						x = x + 2
					elseif x >= xEnd then
						x = xStart
						nextTurn = true
					end

					if z < zEnd  then

						if nextTurn then
							nextTurn = false
							z = z + 2 
						end
					elseif z >= zEnd then
						turnEnd = true
						TimerUtil.RemoveGlobalTimer(Timer)
					end

				end 


				-- warn("当前点是否可达到：")
				-- local valid = GameUtil.IsValidPositionXZ(x, z)
				-- warn(valid)
				-- game:DebugString("c 51 ".."-100"..",".."100")
				local  first = true
	
				local  function MoveAndCount()

					local file = io.open( _G.res_base_path.."\\test.csv","a")
					if not first then

						local fps = GameUtil.GetFPS()
						file:write(string.format("%.2f,%d,%d\n",fps,x,z))

					end

					if first then

						first =false
					
					end

					local can =  GameUtil.IsValidPositionXZ(x, z)
					while not can do
						file:write(string.format("0,%d,%d\n",x,z))
						AddPosXZ()
						can = GameUtil.IsValidPositionXZ(x, z)
					end

					file:close()
					game:DebugString("c 51 "..x.." "..z)

					AddPosXZ()
				end 

				Timer =  TimerUtil.AddGlobalTimer(1.5,false,MoveAndCount)

			elseif cmd_str == "debugOpen 0" then
				-- warn("close debug!!!")
			elseif cmd_str == "debugOpen 1" then
				self:CloseDebugMode()
				-- warn("OPen debug!!!")
				self:OpenDebugMode()
			elseif cmd_str == "c eid" then
				if game._HostPlayer._CurTarget ~= nil then		
					TODO("CurTarget EntityId == "..game._HostPlayer._CurTarget._ID)	
					warn("CurTarget EntityId == "..game._HostPlayer._CurTarget._ID)
				else
					warn("请选择怪物")
					return
				end
			else
				if string.find(cmd_str, "c 701") then
					game._CGuideMan:DebugCloseGuidePanel()
					-- if game._CGuideMan ~= nil then
					-- 	game._CGuideMan._CurGuideStep = 0
					-- 	game._CGuideMan._CurGuideID = 10
					-- 	game._CGuideMan._LastGuideID = 9
					-- 	game._CGuideMan:DebugCloseGuidePanel()
					-- end
				end
				game:DebugString(cmd_str)				
			end
			self:TogglePanelGmTest()
		end
	elseif id == "Btn_LVFull" then  --一键满级
		self:Change2MaxLevel()
		self:TogglePanelGmTest()

	elseif id == 'Btn_Navmesh' then   --打开navmesh 
		self:TogglePanelNavmesh()
		self:TogglePanelGmTest()

	elseif id == 'Btn_TxtMoster' then   --生成两个测试怪 
		self:AddMonster()
		self:TogglePanelGmTest()

	elseif id == 'Btn_Backpack' then   --背包全开 
		game:DebugString("c 358")
		self:TogglePanelGmTest()
		
	elseif id == 'Btn_Kill' then   --一键秒怪
		game:DebugString("c 73")
		self:TogglePanelGmTest()
		
	elseif id == 'Btn_Effect' then   --特效开关
		self:TogglePanelFx()
		self:TogglePanelGmTest()
	
	elseif id == 'Btn_Head' then   --冒字开关
		self:TogglePanelHUD()
		self:TogglePanelGmTest()
	elseif id == "Btn_FuncTest" then
		TestFunction(self)
	else
		self:CMDCommand(id)
	end
end

def.method().Start = function(self)
	-- Add Timer
	if self._M_TimerId == 0 then
		self._M_TimerId = game._HostPlayer:AddTimer(0.13, false, function()
			self:UpdateEntityInfo()
		end)
	end
end

def.method().Stop = function(self)
	if self._M_TimerId == 0 then return end
	game._HostPlayer:RemoveTimer(self._M_TimerId)
	self._M_TimerId = 0
	self:UpdateEntityInfo()
end

def.method().CloseDebugMode = function(self)
	game._IsOpenDebugMode = false
	local  DebugModeEvent = require "Events.DebugModeEvent"
	local event = DebugModeEvent()
	event._IsOpenDebug = false
	CGame.EventManager:raiseEvent(nil, event) 
	self:Stop()
end


def.method().OpenDebugMode = function(self)
	game._IsOpenDebugMode = true
	local  DebugModeEvent = require "Events.DebugModeEvent"
	local event = DebugModeEvent()
	event._IsOpenDebug = true
	CGame.EventManager:raiseEvent(nil, event) 
	game:DebugString("c 421")
	self:Start()
end

def.method().UpdateEntityInfo = function (self)
	if game._CurWorld == nil then return end
	game._HostPlayer._TopPate:UpdateName(true)

	local players = game._CurWorld._PlayerMan._ObjMap
	for _,v in pairs(players) do
		if v._TopPate ~= nil then
			v._TopPate:UpdateName(true)
		end
	end

	local monsterMan = game._CurWorld._NPCMan._ObjMap
	for _,v in pairs(monsterMan) do
		if v._TopPate ~= nil then
			v._TopPate:UpdateName(true)
		end
	end

	local CMineMan = game._CurWorld._MineObjectMan._ObjMap
	for _,v in pairs(CMineMan) do
		if v._TopPate ~= nil then
			v._TopPate:UpdateName(true)
		end
	end
end

def.method().TogglePanelFx = function(self)
	CFxMan.Instance()._IsAllFxHiden = not CFxMan.Instance()._IsAllFxHiden

	warn("Toggle Fx Show: ", not CFxMan.Instance()._IsAllFxHiden)
end

def.method().TogglePanelHUD = function(self)
	self._SWITCH_HUD_TEXT = not self._SWITCH_HUD_TEXT
end

def.method("=>","boolean").IsOpenHUD = function(self)
	return self._SWITCH_HUD_TEXT
end

local navmesh_open = false
def.method().TogglePanelNavmesh = function(self)
	local cmd_strNavmesh
	if navmesh_open then
		cmd_strNavmesh = "navmesh 0"
	else
		cmd_strNavmesh = "navmesh 1"	
	end
	game:DebugString(cmd_strNavmesh)
	navmesh_open = not navmesh_open
end

def.method().AddMonster = function(self)
	local cmd_addMonster1 = "c 1 62 1"
	local cmd_addMonster2 = "c 1 63 1"
	game:DebugString(cmd_addMonster1)
	game:DebugString(cmd_addMonster2)
end

def.method("string").CMDCommand = function(self, id)
	cmd_explain = StringTable.GetDebug(11)
	if id == "Btn_LV" then
		cmd_Command = "c 22 0 "
		cmd_explain = StringTable.GetDebug(2)

	elseif id == "Btn_Coordinate" then
		cmd_Command = "c 51 "
		cmd_explain = StringTable.GetDebug(8)

	elseif id == "Btn_Money" then
		cmd_Command = "C 23 "
		cmd_explain = StringTable.GetDebug(4)

	elseif id == "Btn_Item" then
		cmd_Command = "C 31 "
		cmd_explain = StringTable.GetDebug(5)

	elseif id == "Btn_Monster" then
		cmd_Command = "C 1 "
		cmd_explain = StringTable.GetDebug(6)

	elseif id == "Btn_NPC" then
		cmd_Command = "C 2 "
		cmd_explain = StringTable.GetDebug(3)

	elseif id == "Btn_Mineral" then
		cmd_Command = "C 3 "
		cmd_explain = StringTable.GetDebug(7)

	elseif id == "Btn_World" then
		cmd_Command = "c 81 "
		cmd_explain = StringTable.GetDebug(9)

	elseif id == "Btn_Map" then
		cmd_Command = "c 69 0 "
		cmd_explain = StringTable.GetDebug(10)

	elseif id == "Btn_Properties" then
		cmd_Command = "c 74 "
		cmd_explain = StringTable.GetDebug(12)	
	
	elseif id == "Btn_Hatred" then
		if game._HostPlayer._CurTarget ~= nil then			
			cmd_Command = "c 120 "..game._HostPlayer._CurTarget._ID
			cmd_explain = StringTable.GetDebug(17)
		else
			warn("请选择怪物")
			return
		end
	else
		cmd_Command = StringTable.GetDebug(1)
		cmd_explain = StringTable.GetDebug(11)
	end
	self:GetUIObject('Lab_Explain'):GetComponent(ClassType.Text).text = cmd_explain
	self._InputInstructions.text = cmd_Command
end


def.method().Change2MaxLevel = function(self)
	local C2SDebugCommand = require "PB.net".C2SDebugCommand
	local protocol = C2SDebugCommand()
	protocol.CommandType = 22
	--protocol.Param1 = 0
	--protocol.Param2 = 100
	protocol.CommandParam = "0 100"

	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(protocol)
end

def.override('string', 'boolean').OnToggle = function(self, id, checked)

	--快捷指令与指令大全切换
	if id == "Rdo_List2" and checked then
		self:SelectExcute(0)
	else 
		self:TabCommand(id,checked)
	end
	
end

--指令分页点击事件处理
def.method('string', 'boolean').TabCommand = function(self, id, checked)
	--self:HidTabTogle(id) 	

	if id == "Rdo_All" and checked then		
		self:SelectExcute(0)
		
	elseif id == "Rdo_Role" and checked then
		self:SelectExcute(1)
		
	elseif id == "Rdo_Unit" and checked then
		self:SelectExcute(3)
		
	elseif id == "Rdo_Debug" and checked then
		self:SelectExcute(4)
		
	elseif id == "Rdo_Mission" and checked then
		self:SelectExcute(5)
		
	elseif id == "Rdo_Move" and checked then
		self:SelectExcute(6)

	elseif id == "Rdo_Drop" and checked then
		self:SelectExcute(7)	

	elseif id == "Rdo_Instance" and checked then
		self:SelectExcute(9)
	end
end

--处理每一个type点击的逻辑处理
def.method('number').SelectExcute = function(self,mtype)
	if mtype == 0 then
		orderList = _G.CommandListTable
	else		
		orderList = {}
		for i,v in pairs(_G.CommandListTable) do 
			if v.type == mtype then
				orderList[#orderList+1] = v					
			end	
		end 
	end	

	if self._UIOrderList ~= nil then
		self._UIOrderList:SetItemCount(#orderList)
	end
end


def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	if id == "List_Order" then
		local order_name = GUITools.GetChild(item , 0)
		local order_node = GUITools.GetChild(item , 1)
		if orderList[index + 1] ~=nil then
			local name = orderList[index + 1].name
			local node = orderList[index + 1].cmd
			GUI.SetText(order_name, name)
			GUI.SetText(order_node, node)		
		end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	if id_btn == "Btn_Copy" then
		cmd_Command = orderList[index + 1].cmd
		self:GetUIObject("Input_Instructions"):GetComponent(ClassType.InputField).text = cmd_Command
		self:GetUIObject('Lab_Explain'):GetComponent(ClassType.Text).text =  orderList[index + 1].desc
	end
end

def.method("string").OnSyncLog = function(self, log)
	--if IsCriticalLog(log) and not self._PanelLog.activeSelf then
	--	self:TogglePanelLog()
	--end

end

def.override().OnHide = function(self)
	--GameUtil.EnableCmdsInputMode(false)
end

def.override().OnDestroy = function(self)
	self._PanelGmTest = nil
	self._InputInstructions = nil
	self._Lab_Explain = nil
	self._UIOrderList = nil
	self._Frame_PageConnection = nil
end

def.method().CountFrameAndSave=function(self)

	local frameList = {}
	local _minFps = 0
	local  _averageFps = 1
	local Timer1 
  
	local callback1=function ()

	local file 
		--回调2 用来处理每秒钟的帧率
		local  callback2 = function ()

			--这边记录每秒帧率的场景ID 坐位位置 还有FPS
			local fps = GameUtil.GetFPS()
			file = io.open( _G.res_base_path.."\\test.csv","a")
			local sceneId = game._CurWorld._WorldInfo.SceneTid
			local hp = game._HostPlayer
			local pos = hp:GetPos()
			local time=os.date("*t")
			file:write(string.format("%d:%d:%d,%.2f,%d,(%.2f:%.2f:%.2f)\n",time.hour,time.min,time.sec,fps,sceneId,pos.x,pos.y,pos.z))
			file:close()

			if _minFps==0 then
				_minFps = fps
			end
			if _minFps ~= 0 and fps < _minFps then
				_minFps = fps
			end

			table.insert(frameList,fps)
		end

		--每次移除 再重新添加
		if Timer1 ~= nil then 
			TimerUtil.RemoveGlobalTimer(Timer1)
		end

		Timer1=TimerUtil.AddGlobalTimer(1,false,callback2) 

		--这里需要处理一下 算出平均帧率
		if #frameList > 0 then
			file = io.open("D:\\TeraProject\\MyClientwc\\UnityProject\\test.csv","a")
			local  sum = 0
			for k,v in ipairs(frameList) do
				sum = sum + v
			end
			_averageFps=sum / #frameList

			--记录一下时间和最小、平均帧率
			--local time=os.date("*t")
			--file:write(string.format("%d:%d,%.2f,%.2f\n",time.hour,time.min,_minFps,_averageFps))
			file:close()
		end
		--每次把表置空
		frameList = {}
		_minFps = 0
	end

	TimerUtil.AddGlobalTimer(10,false,callback1) 

end



CPanelDebug.Commit()
return CPanelDebug
