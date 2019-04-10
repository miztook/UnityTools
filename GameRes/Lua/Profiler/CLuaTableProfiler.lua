local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CCharmMan = require "Charm.CCharmMan"
local ChatManager = require "Chat.ChatManager"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local CTokenMoneyMan = require "Data.CTokenMoneyMan"
local UserData = require "Data.UserData"
local CDressMan = require "Dress.CDressMan"
local CBeginnerDungeonMan = require "Dungeon.CBeginnerDungeonMan"
local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
local CEmailMan = require "Email.CEmailMan"
local CGuildSmithyMan = require "Guild.CGuildSmithyMan"
local CExteriorMan = require "Main.CExteriorMan"
local CLoginMan = require "Main.CLoginMan"
local CNotificationMan = require "Main.CNotificationMan"
local CTransManage = require "Main.CTransManage"
local CWorldAutoFight = require "Main.CWorldAutoFight"
local QualitySettingMan = require "Main.QualitySettingMan"
local CMallMan = require "Mall.CMallMan"
local CMallPageFactory = require "Mall.CMallPageFactory"
local CMallUtility = require "Mall.CMallUtility"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CAutoMatch = require "ObjHdl.CAutoMatch"
local CTargetDetector = require "ObjHdl.CTargetDetector"
local CPath = require "Path.CPath"
local CQuest = require "Quest.CQuest"
local CQuestAutoFight = require "Quest.CQuestAutoFight"
local CQuestAutoGather = require "Quest.CQuestAutoGather"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CQuestNavigation = require"Quest.CQuestNavigation"
local CSkillActorMan = require "Skill.CSkillActorMan"
local CTeamMan = require "Team.CTeamMan"
local CTransDataHandler = require "Transfer.CTransDataHandler"
local CWingsMan = require "Wings.CWingsMan"

local CLuaTableProfiler = Lplus.Class("CLuaTableProfiler")
local def = CLuaTableProfiler.define

local function getTypeTable(obj)
	local objmeta = debug.getmetatable(obj)
	if objmeta == nil or rawget(objmeta, "typeTable") == nil then return nil end
	local typemeta = debug.getmetatable(objmeta.typeTable)
	return typemeta
end

_G.typeNameTable = {}

local function getTableName(t)
   local name = _G.typeNameTable[t]
   if name ~= nil then return name end
   return tostring(t)
end

local instanceCheckTable =
{
    { _G.game, "game" },
    { _G.CFlashTipMan, "_G.CFlashTipMan" },
    { _G.CFxMan, "_G.CFxMan" },
    { _G.CSoundMan, "_G.CSoundMan" },
    { _G.CUseDiamondMan, "_G.CUseDiamondMan" },
    { _G.CPlatformSDKMan, "_G.CPlatformSDKMan" },
    { CGame.EventManager, "CGame.EventManager" },
    { CCharmMan.Instance(), "CCharmMan.Instance()" },
    { ChatManager.Instance(), "ChatManager.Instance()" },
    { CScoreCalcMan.Instance(), "CScoreCalcMan.Instance()" },
    { CTokenMoneyMan.Instance(), "CTokenMoneyMan.Instance()" },
    { UserData.Instance(), "UserData.Instance()" },
    { CDressMan.Instance(), "CDressMan.Instance()" },
    { CBeginnerDungeonMan.Instance(), "CBeginnerDungeonMan.Instance()" },
    { CDungeonAutoMan.Instance(), "CDungeonAutoMan.Instance()" },
    { CEmailMan.Instance(), "CEmailMan.Instance()" },
    { CGuildSmithyMan.Instance(), "CGuildSmithyMan.Instance()" },
    { CExteriorMan.Instance(), "CExteriorMan.Instance()" },
    { CLoginMan.Instance(), "CLoginMan.Instance()" },
    { CNotificationMan.Instance(), "CNotificationMan.Instance()" },
    { CTransManage.Instance(), "CTransManage.Instance()" },
    { CWorldAutoFight.Instance(), "CWorldAutoFight.Instance()" },
    { QualitySettingMan.Instance(), "QualitySettingMan.Instance()" },
    { CMallMan.Instance(), "CMallMan.Instance()" },
    { CMallPageFactory.Instance(), "CMallPageFactory.Instance()" },
    { CMallUtility.Instance(), "CMallUtility.Instance()" },
    { CAutoFightMan.Instance(), "CAutoFightMan.Instance()" },
    { CAutoMatch.Instance(), "CAutoMatch.Instance()" },
    { CTargetDetector.Instance(), "CTargetDetector.Instance()" },
    { CPath.Instance(), "CPath.Instance()" },
    { CQuest.Instance(), "CQuest.Instance()" },
    { CQuestAutoFight.Instance(), "CQuestAutoFight.Instance()" },
    { CQuestAutoGather.Instance(), "CQuestAutoGather.Instance()" },
    { CQuestAutoMan.Instance(), "CQuestAutoMan.Instance()" },
    { CQuestNavigation.Instance(), "CQuestNavigation.Instance()" },
    { CSkillActorMan.Instance(), "CSkillActorMan.Instance()" },
    { CTeamMan.Instance(), "CTeamMan.Instance()" },
    { CTransDataHandler.Instance(), "CTransDataHandler.Instance()" },
    { CWingsMan.Instance(), "CWingsMan.Instance()" },

}

local function getMemoryTable()
	local tablecache = {}
    local objtablecache = {}
    local visited = {}


    _G.typeNameTable = {}
    for i = 1, #instanceCheckTable do
        local entry = instanceCheckTable[i]
        _G.typeNameTable[entry[1]] = entry[2]
    end 

    local function StartTravelG(t)
        if t == nil then return end
        if type(t) ~= "table" or visited[t]  then return end
        visited[t] = true
        
    	local typemeta = getTypeTable(t)
        if typemeta == nil then return end
        local typename = typemeta.typeName

        local parentname = getTableName(t)

        for k,v in pairs(typemeta.memberInfoMap) do
        	if type(v) == "table" and v.memberType == "field" then  --table类型的字段，可能是lplus类，也可能是table
        		
        		if type(v.valueType) == "table" then		--lplus类
        			if v.style == "" then
        				local val = t[k]
        				local typeTable = debug.getmetatable(v.valueType)
        				local name = parentname .. "." .. tostring(k)

        				if val ~= nil then
                            objtablecache[val] = {name, typeTable.typeName, 0} 
                            _G.typeNameTable[val] = name

                            StartTravelG(val)
                        end 

        			elseif v.style == "c" then
                        --local name = parentname .. "." .. tostring(k)
        				--warn("Const:", name)
        			else
        				warn("getMemoryTable TODO!!!")
        			end
        		elseif v.valueType == "table" then
       				if v.style == "" then
        				local val = t[k]
        				local name = parentname .. "." .. tostring(k)
        		    	if val ~= nil then
                            tablecache[val] = {name, "table", table.nums(val)} 
                            _G.typeNameTable[val] = name

                            for key, child in pairs(val) do
                                _G.typeNameTable[child] = name .. "[" .. tostring(key) .. "]"

                                StartTravelG(child)
                            end
                        end
        		    elseif v.style == "c" then

        		    else
        		    	warn("getMemoryTable TODO!!!")
        		    end
        		end
        	end
        end

        if objtablecache[t] == nil then
        	objtablecache[t] = {getTableName(t, typename), typename, 0}
        end
    end

    for i = 1, #instanceCheckTable do
        local entry = instanceCheckTable[i]
        StartTravelG(entry[1])
    end

    local tableStats = {}
    for k, v in pairs(tablecache) do
        table.insert(tableStats, v)
    end
    table.sort( tableStats, function(a,b) return a[1] < b[1] end )

    local objTableStats = {}
    for k, v in pairs(objtablecache) do
        table.insert(objTableStats, v)
    end
    table.sort( objTableStats, function(a,b) return a[1] < b[1] end )


    _G.typeNameTable = {}

	return tableStats, objTableStats
end

def.static().LogMemoryStats = function() --记录lua中详细的内存使用信息
	collectgarbage("collect")
    local memSize = collectgarbage("count")

    local tableStats, objTableStats = getMemoryTable()

	local now = os.date("LUA-%m-%d_%H-%M-%S");
	local filename = _G.document_path .. "/" .. now .. ".txt"
    local file = io.open(filename, "w")
    if not file then
        error("can't open file:", filename)
        return
    end

    file:write(string.format("memorySize: %d\n\n", memSize))
    file:write(string.format("table num: %d\n\n", #tableStats))
    for _,v in ipairs(tableStats) do
    	file:write(v[1] .. "\t\t" .. v[3] .. "\n")
	end

    file:write("\n\n\n")

    file:write(string.format("object num: %d\n\n", #objTableStats))
    for _,v in ipairs(objTableStats) do
        print_r(v)
        file:write(v[1] .. "\t\t" .. v[2] .. "\n")
    end

    file:close()

	warn("-----------> LogMemoryStats @ " .. now)
end

CLuaTableProfiler.Commit()

return CLuaTableProfiler
