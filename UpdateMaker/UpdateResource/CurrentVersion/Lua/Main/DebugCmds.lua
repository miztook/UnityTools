local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CScoreCalcMan = require "Data.CScoreCalcMan"
local MemLeakDetector = require "Profiler.CMemLeakDetector"

local cmds = {}

local check_params_count = function(params, count)
	return (#params == count)
end

--根据传入的参数0/1，获取真正要取得的参数，一般是选中的目标的entityId
local get_real_param = function (param)
		if param == 1 then --选中目标
			if game._HostPlayer._CurTarget == nil then print("game._HostPlayer._CurTarget._ID is null") return 0 end
			param = game._HostPlayer._CurTarget._ID
			--print("game._HostPlayer._CurTarget._ID: ", msg.Param2)
		elseif param == 0 then
			param = game._HostPlayer._ID
		end	
		return param
end

cmds["c"] = function(c)
	if #c < 2 then return end
	local sub_command_type = tonumber(c[2])
	local param1 = tonumber(c[3])
	local param2 = tonumber(c[4])
	local param3 = tonumber(c[5])
	local is_string_cmd = false;

	if param1 == nil then param1 = 0 is_string_cmd = true end 
	if param2 == nil then param2 = 0  end
	if param3 == nil then param3 = 0  end

	if game._HostPlayer == nil then return end

	local C2SDebugCommand = require "PB.net".C2SDebugCommand
	local msg = C2SDebugCommand()
	msg.CommandType = sub_command_type
	local pos = game._HostPlayer:GetPos()
	msg.Position.x = pos.x
	msg.Position.y = pos.y
	msg.Position.z = pos.z

	if sub_command_type == 32 or sub_command_type == 37 then --删除物品、使用物品 索引，背包类型，[锁定的条目] 
		param1 = game._HostPlayer._Package._NormalPack:GetItemServerIndex(param1)
		if param1 == -1 then
			print("C 32 or 37 not a valid index")
			return
		end	
	end
	if sub_command_type == 83 or sub_command_type == 410 or sub_command_type == 414 then
		param2 = get_real_param(param2)
	end
	if sub_command_type == 206 or sub_command_type == 409 or sub_command_type == 411 or sub_command_type == 404 then
		param1 = get_real_param(param1)	
	end

	if sub_command_type == 205 then
		if game._HostPlayer._CurTarget == nil then return end
		param3 = param2
		param2 = game._HostPlayer._CurTarget._ID
	end

	if sub_command_type == 408 then
		is_string_cmd = true
	end

	if sub_command_type == 464 then
		is_string_cmd = true
	end

	if is_string_cmd then
		msg.CommandParam = tostring(c[3]) .. " " .. tostring(c[4]) .. " ".. tostring(c[5])
		-- warn("C2SDebugCommand string ", sub_command_type, msg.CommandParam)
	else
		msg.CommandParam = param1 .. " " .. param2 .. " ".. param3
		-- warn("C2SDebugCommand number", sub_command_type, msg.CommandParam)
	end

	local PBHelper = require "Network.PBHelper"
    PBHelper.Send(msg)
end

cmds["msgbox"]	= function(c)
	MsgBox.ShowMsgBox("我就是一个测试","坑爹啊", MsgBoxType.MBBT_OK)
end

cmds["net"]	= function(c)
	if not check_params_count(c, 2) then return end
	local enable = tonumber(c[2]) <= 0
	game._NetMan:SetProtocolPaused(enable)
end

cmds["fps"]	= function(c)
	if not check_params_count(c, 2) then return end
	local lv = tonumber(c[2])
	local FPSAdapter = require "System.FPSAdapter"
	FPSAdapter.Debug(lv)
end

cmds["line"]	= function(c)
	if not check_params_count(c, 2) then return end
	local id = tonumber(c[2])
	if id == -1 then -- show all lines
		local allLines = game._CurWorld._WorldInfo.ValidLineIds
		if allLines ~= nil then
			local idsStr = "lineIds = {"
			for i,v in ipairs(allLines) do
				idsStr = idsStr .. tostring(v)
				if i ~= #allLines then
					idsStr = idsStr .. ", "
				else
					idsStr = idsStr .. "}"
				end
			end
			warn(idsStr)
		else
			warn("lineIds = nil")
		end
	else -- change line
		local C2SChangeMapLine = require "PB.net".C2SChangeMapLine
		local msg = C2SChangeMapLine()
		msg.MapLine = id
		local PBHelper = require "Network.PBHelper"
	    PBHelper.Send(msg)
	    
	end
end

cmds["test"] = function(c)
	if check_params_count(c, 1) then
		GameUtil.Test()
	end

	if not check_params_count(c, 3) then return end
	local Test = require "Main.Test"
	local index = tonumber(c[2])
	local param = tonumber(c[3])
	if Test[index] ~= nil then
		Test[index](param > 0)
	end
end

cmds["info"] = function(c)
	if not check_params_count(c, 2) then return end
	GameUtil.ShowGameInfo(c[2])
end

cmds["resdelay"] = function(c)
	if not check_params_count(c, 2) then return end
	local t = tonumber(c[2])
	if t > 0 then
		GameUtil.SetResLoadDelay(t)
	end
end

cmds["netdelay"] = function(c)
	if not check_params_count(c, 2) then return end
	local t = tonumber(c[2])
	if t >= 0 then
		GameUtil.SetNetLatency(t)
	end
end

cmds["stat"] = function(c)
	if not check_params_count(c, 2) then return end
	local EntityStatis = require "Profiler.CEntityStatistics"
	local info = EntityStatis.FormatInfo(c[2])
	warn(info)
end

cmds["abcount"] = function(c)
	GameUtil.DebugCommand("abcount")
end

cmds["navmesh"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "navmesh " .. c[2]
	GameUtil.DebugCommand(cmd)
end


cmds["lightregion"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "lightregion " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["dn"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "dn " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["regionset"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "regionset " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["obstacleset"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "obstacleset " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["count"] = function(c)
	local cmd = "count 1"
	GameUtil.DebugCommand(cmd)
end

cmds["perfs"] = function (c)
	if not check_params_count(c, 3) then return end
	local cmd = "perfs " .. c[2] .. " " .. c[3]
	GameUtil.DebugCommand(cmd)
end

cmds["stats"] = function(c)
	if not check_params_count(c, 3) then return end
	local cmd = "stats " .. c[2] .. " " .. c[3]
	GameUtil.DebugCommand(cmd)
end

cmds["postprocess"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "postprocess " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["errormessage"] = function(c)
	if not check_params_count(c, 2) then return end
	local cmd = "errormessage " .. c[2]
	GameUtil.DebugCommand(cmd)
end

--local UIShowTable = nil
cmds["showui"] = function(c)

	if not check_params_count(c, 2) then return end
	local show = tonumber(c[2]) ~= 0

	local cmd = "showui " .. c[2]
	GameUtil.DebugCommand(cmd)
end

cmds["playvoice"] = function (c)
	if not check_params_count(c, 2) then return end
	local name = tostring(c[2])

	local pos = Vector3.zero
	if game._HostPlayer ~= nil then
		pos = game._HostPlayer:GetPos()
	end
	CSoundMan.Instance():Play3DVoice(name, pos,0)
end

cmds["playbgm"] = function (c)
	if not check_params_count(c, 2) then return end
	local name = tostring(c[2])

	CSoundMan.Instance():PlayBackgroundMusic(name,0)
end

cmds["playaudio3d"] = function (c)
	if check_params_count(c, 2) then
		local name = tostring(c[2])

		local pos = Vector3.zero
		if game._HostPlayer ~= nil then
			pos = game._HostPlayer:GetPos()
		end
		CSoundMan.Instance():Play3DAudio(name, pos,0)
	elseif check_params_count(c, 3) then
		local name = tostring(c[2])
		local dist = tonumber(c[3])

		local pos = Vector3.zero
		if game._HostPlayer ~= nil then
			pos = game._HostPlayer:GetPos() + game._HostPlayer:GetDir() * dist
		end
		CSoundMan.Instance():Play3DAudio(name, pos,0)
	end
end

cmds["playaudio2d"] = function (c)
	if not check_params_count(c, 2) then return end
	local name = tostring(c[2])

	CSoundMan.Instance():Play2DAudio(name,0)
end

cmds["item_enforce"] = function(c)
	if not check_params_count(c, 3) then return end
	local C2SItemEnforce = require "PB.net".C2SItemEnforce
	local msg = C2SItemEnforce()
	local PBHelper = require "Network.PBHelper"
	msg.BagType = tonumber(c[2])
	msg.Index = game._HostPlayer._Package._NormalPack:GetItemServerIndex(tonumber(c[3]))
    PBHelper.Send(msg)
end

cmds["item_rebuild"] = function(c)
	if not check_params_count(c, 3) then return end
	local C2SItemRebuild = require "PB.net".C2SItemRebuild
	local msg = C2SItemRebuild()
	local PBHelper = require "Network.PBHelper"
	msg.BagType = tonumber(c[2])
	msg.Index = game._HostPlayer._Package._NormalPack:GetItemServerIndex(tonumber(c[3]))
	local tb = game._HostPlayer._Package:GetItemAttrIndex(tonumber(c[2]), tonumber(c[3]))
	for k,v in ipairs(tb) do
		table.insert(msg.LockLists, v)
	end
    PBHelper.Send(msg)
end

cmds["item_quenting"] = function(c)
	if not check_params_count(c, 3) then return end
	local C2SItemQuenching = require "PB.net".C2SItemQuenching
	local msg = C2SItemQuenching()
	local PBHelper = require "Network.PBHelper"
	msg.BagType = tonumber(c[2])
	msg.Index = game._HostPlayer._Package._NormalPack:GetItemServerIndex(tonumber(c[3]))
	local tb = game._HostPlayer._Package:GetItemAttrIndex(tonumber(c[2]), tonumber(c[3]))
	for k,v in ipairs(tb) do
		table.insert(msg.QuenchingList, v)
	end		
    PBHelper.Send(msg)
end

cmds["item_advance"] = function(c)
	if not check_params_count(c, 4) then return end
	local C2SItemAdvance = require "PB.net".C2SItemAdvance
	local msg = C2SItemAdvance()
	local PBHelper = require "Network.PBHelper"
	msg.BagType = tonumber(c[2])
	msg.Index = game._HostPlayer._Package._NormalPack:GetItemServerIndex(tonumber(c[3]))
	local consumeIndex = game._HostPlayer._Package._NormalPack:GetItemServerIndex(tonumber(c[4]))
	table.insert(msg.ConsumeIndexs, consumeIndex )
    PBHelper.Send(msg)
end

cmds["item_inherit"] = function(c)
	if not check_params_count(c, 3) then return end
	local C2SItemInherit = require "PB.net".C2SItemInherit
	local msg = C2SItemInherit()
	local PBHelper = require "Network.PBHelper"
	msg.BagEquipIndex = tonumber(c[2])
	msg.RoleEquipIndex = tonumber(c[3])
    PBHelper.Send(msg)
end

cmds["prof"] = function(c)
	if not check_params_count(c, 2) then return end
	local act = tonumber(c[2])
	local profiler = require "Profiler.CTimeProfiler"
	if act == 0 then 
		profiler.Stop() 
		profiler.Dump()
	elseif act == 1 then 
		profiler.Start() 
	end
end

cmds["td"] = function(c)
	if not check_params_count(c, 1) then return end
	local CElementData = require "Data.CElementData"
	CElementData.DumpStatistics()
end

cmds["debugmode"] = function(c)
	if not check_params_count(c, 2) then return end
	local DebugTools = require "Main.DebugTools"

	if c[1] == 0 then
		DebugTools.EnableEntityInfoDebug = false
	else
		DebugTools.EnableEntityInfoDebug = true 
	end	
end

cmds["selfpos"] = function(c)
	if not check_params_count(c, 1) then return end
	local pos = game._HostPlayer:GetPos()
	warn("pos =", pos)
end

cmds["memstats"] = function (c)
	local LuaTableProfiler = require "Profiler.CLuaTableProfiler"

	LuaTableProfiler.LogMemoryStats()
	--GameUtil.DumpCSharpMemory()
end

cmds["godump"] = function (c)
	GameUtil.DumpCSharpMemory(0)
end

cmds["compdump"] = function (c)
	GameUtil.DumpCSharpMemory(1)
end

cmds["texdump"] = function (c)
	GameUtil.DumpCSharpMemory(2)
end

cmds["matdump"] = function (c)
	GameUtil.DumpCSharpMemory(3)
end

cmds["pss"] = function (c)
	warn(GameUtil.GetMemotryStats())
end

cmds["memory"] = function (c)
	if not check_params_count(c, 2) then return end
	local tickTime = tonumber(c[2])

	if c[2] == "on" then
		MemLeakDetector.StartRecordAlloc(false)
	elseif c[2] == "off" then
		MemLeakDetector.StopRecordAllocAndDumpStat()
	else
		_G.MemoryHook(tickTime)
	end
end

cmds["lplus"] = function (c)
	if not check_params_count(c, 2) then return end

	if c[2] == "1" then
		_G.StartRecordCreation()
	elseif c[2] == "0" then
		local filename = _G.res_base_path .. "/" .. "lplusAlloc.csv"
		_G.StopRecordCreation(filename)
	end 
end

cmds["roleid"] = function(c)
	warn("RoleId: ", game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Id)
end

cmds["logc2s"] = function(c)
	if not check_params_count(c, 2) then return end
	local show = tonumber(c[2]) ~= 0
	_G.logc2s = show
end

cmds["logs2c"] = function(c)
	if not check_params_count(c, 2) then return end
	local show = tonumber(c[2]) ~= 0
	_G.logs2c = show
end

cmds["logevent"] = function(c)
	CGame.EventManager:printStats()
end

cmds["logtimer"] = function(c)
	local cmd = "logtimer"
	GameUtil.DebugCommand(cmd)
end

cmds["servertime"] = function (c)
	local ServerTime = GameUtil.GetServerTime()	
	local ServerTimetext = os.date("%y/%m/%d, %H:%M:%S", ServerTime/1000)
	warn("服务器时间：", ServerTimetext)
end

cmds["regprint"] = function (c)
	local num = GameUtil.PrintRegistryTable()
	warn("Registry Count = ", num)
end

cmds["talentscore"] = function(c)
	if not check_params_count(c, 3) then return end

	local talentId = tonumber(c[2])
	local talentLevel = tonumber(c[3])
	if talentId == nil or talentLevel == nil then
		warn("输入错误,正确格式: talentscore 被动技能ID 被动技能等级")
		return
	end
	local fightScore = CScoreCalcMan.Instance():CalcTalentSkillScore(game._HostPlayer._InfoData._Prof, talentId, talentLevel)
	warn("被动技能总战力 ", fightScore)
end

cmds["luamem"] = function (c)
	if not check_params_count(c, 2) then return end
	local param = tonumber(c[2])

	local detecter = require "Utility.LuaMemRefAnalysis"
	if param == 1 then
		detecter.Methods.StartLuaMemDetect() -- 开启
	elseif param == 2 then
		detecter.Methods.OutputRefUpdLog()
		detecter.Methods.OutputDiff2Ori()
		detecter.Methods.StopLuaMemDetect()
	end
end

cmds["mem"] = function (c)
	local virtual = math.floor(GameUtil.GetVirtualMemoryUsedSize() / (1024 * 1024))
	local phys = math.floor(GameUtil.GetPhysMemoryUsedSize() / (1024 * 1024))
	warn("virtual MEM: " .. tostring(virtual) .. " M, phys MEM: " .. tostring(phys) .. " M")
end

cmds["reqcamerapermission"] = function (c)
	if not check_params_count(c, 1) then return end

	local ret = GameUtil.HasCameraPermission()
	warn("HasCameraPermission:", ret)

	if not ret then
		GameUtil.RequestCameraPermission()
	end
end

cmds["reqphotopermission"] = function (c)
	if not check_params_count(c, 1) then return end

	local ret = GameUtil.HasPhotoPermission()
	warn("HasPhotoPermission:", ret)

	if not ret then
		GameUtil.RequestPhotoPermission()
	end
end

cmds["autostate"] = function (c)
	if not check_params_count(c, 1) then return end
	
	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Debug()
	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	CAutoFightMan.Instance():Debug()
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	CDungeonAutoMan.Instance():Debug()
end

cmds["stand"] = function (c)
	if not check_params_count(c, 1) then return end
	
	game._HostPlayer:Stand()
end

local timer_id = 0
cmds["superman"] = function (c)
	if not check_params_count(c, 1) then return end

	local CElementData = require "Data.CElementData"
	local attachedProperties = CElementData.GetAllTid("AttachedProperty")
	local count = 1
	local callback = function()
		if count == 2 then
			game:DebugString("c 74 " .. count .. " 5")				
		else
			game:DebugString("c 74 " .. count .. " 999")
		end
		count = count + 1
		if count > #attachedProperties then
			_G.RemoveGlobalTimer(timer_id)
		end
	end
	timer_id = _G.AddGlobalTimer(0.03, false, callback)
end

cmds["testworld"] = function (c)
	if not check_params_count(c, 3) then return end

	local param = tonumber(c[2])
	local param2 = tonumber(c[3])
	_G.TestWorld(param, 1, param2, 2)
end

cmds["stackoverflow"] = function (c)
	if not check_params_count(c, 1) then return end

	_G.OnInputKeyCode(50)  -- 释放2号技能
	warn("castskill 2")
	-- 添加缓冲技能
	local hp = game._HostPlayer
	local hostskillhdl = hp._SkillHdl
	local function TransLogic()
		local CSpecialIdMan = require  "Data.CSpecialIdMan"
		local skill_id = CSpecialIdMan.Get("WorldMapTranform")
		hostskillhdl:CastSkill(skill_id, false)		
		hostskillhdl:RegisterCallback(false, function(ret)
		        if not ret then return end
		        warn("C2SWorldMapTrans", debug.traceback())
		        local C2SWorldMapTrans = require "PB.net".C2SWorldMapTrans
			    local msg = C2SWorldMapTrans()
			    msg.MapID = 110
			    local PBHelper = require "Network.PBHelper"
			    PBHelper.Send(msg)
		    end)
	end

	--do return end

	local function callback()
		warn("AddCachedAction")
		hp:AddCachedAction(TransLogic)
	end
	
	_G.AddGlobalTimer(1, true, callback)

	hostskillhdl:RegisterDebugFunc(TransLogic)
end

local tablePrinted = nil
local function printTableItem(k, v, level) 
    for i = 1, level do 
        io.write("	") 
    end 

    io.write(tostring(k), " = ", tostring(v), "\n") 
    if type(v) == "table" then 
        if not tablePrinted[v] then 
            tablePrinted[v] = true 
            for k, v in pairs(v) do 
                printTableItem(k, v, level + 1) 
            end 
        end 
    end 
end 

local function dumptree(obj, width)
    -- 递归打印函数
    local dump_obj;
    local end_flag = {};

    local function make_indent(layer, is_end)
        local subIndent = string.rep("  ", width)
        local indent = "";
        end_flag[layer] = is_end;
        local subIndent = string.rep("  ", width)
        for index = 1, layer - 1 do
            if end_flag[index] then
                indent = indent.." "..subIndent
            else
                indent = indent.."|"..subIndent
            end
        end

        if is_end then
            return indent.."└"..string.rep("─", width).." "
        else
            return indent.."├"..string.rep("─", width).." "
        end
    end

    local function make_quote(str)
        str = string.gsub(str, "[%c\\\"]", {
            ["\t"] = "\\t",
            ["\r"] = "\\r",
            ["\n"] = "\\n",
            ["\""] = "\\\"",
            ["\\"] = "\\\\",
        })
        return "\""..str.."\""
    end

    local function dump_key(key)
        if type(key) == "number" then
            return key .. "] "
        elseif type(key) == "string" then
            return tostring(key).. ": "
        end
    end

    local function dump_val(val, layer)
        if type(val) == "table" then
            return dump_obj(val, layer)
        elseif type(val) == "string" then
            return make_quote(val)
        else
            return tostring(val)
        end
    end

    local function count_elements(obj)
        local count = 0
        for k,v in pairs(obj) do
        	print(k,v)
        end
        for k, v in pairs(obj) do
            count = count + 1
        end

        return count
    end

    dump_obj = function(obj, layer)
        if type(obj) ~= "table" then return "" end

        layer = layer + 1
        local tokens = {}
        local max_count = count_elements(obj)-- table.nums(obj) 
        local cur_count = 1
        for k, v in pairs(obj) do
            local key_name = dump_key(k)
            if type(v) == "table" then
                key_name = key_name.."\n"
            end
            table.insert(tokens, make_indent(layer, cur_count == max_count) 
                .. key_name .. dump_val(v, layer))
            cur_count = cur_count + 1
        end

        print("max_count = " .. tostring(max_count))
        -- 处理空table
        if max_count == 0 then
            table.insert(tokens, make_indent(layer, true) .. "{ }")
        end

        return table.concat(tokens, "\n")
    end

    if type(obj) ~= "table" then
        return "the params you input is "..type(obj)..
        ", not a table, the value is --> "..tostring(obj)
    end

    width = width or 2
    return "game-->"..tostring(obj).."\n"..dump_obj(obj, 0)
end

cmds["game"] = function(c)
	if not check_params_count(c, 1) then return end

	_G.game:For()

	local path = _G.res_base_path .. "/_G.lua"
	local result = dumptree(_G.game)
	local fout, err = io.open(path, "w")
	if fout then
		fout:write(result)
		fout:close()
	end

	do return end

	local malut = require "Utility.malut"
	local bSucc, err = malut.toCodeToFile(_G, path)
	if not bSucc then
		error(err)
	end
end

cmds["travel"] = function (c)
	require "Tools.LuaTableCacheCheck"
	_G.Hoba_TravelTable()
end

cmds["crossprocess"] = function (c)
	local C2SClientProtocolAck = require "PB.net".C2SClientProtocolAck
	local msg = C2SClientProtocolAck()
	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(msg)
end

return cmds