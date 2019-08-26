local Lplus = require "Lplus"
local CGuildMsgParser = Lplus.Class("CGuildMsgParser")
local def = CGuildMsgParser.define

-- 解析公会技能信息
def.static("table", "=>", "table").ParseGuildSkillInfo = function(msg)
    local new_skill_info = {}
    new_skill_info.ResCode = msg.ResCode
    new_skill_info._SkillData = {}
    new_skill_info._BuffData = {}
    for _,v in ipairs(msg.SkillDatas) do
        if v ~= nil then
            new_skill_info._SkillData[#new_skill_info._SkillData + 1] = {}
            new_skill_info._SkillData[#new_skill_info._SkillData].SkillId = v.SkillId
            new_skill_info._SkillData[#new_skill_info._SkillData].SkillLevel = v.SkillLevel
        end
    end
    for _,v in ipairs(msg.BuffDatas) do
        if v ~= nil then
            new_skill_info._BuffData[#new_skill_info._BuffData + 1] = {}
            new_skill_info._BuffData[#new_skill_info._BuffData].BuffId = v.BuffId
            new_skill_info._BuffData[#new_skill_info._BuffData].BuffLevel = v.BuffLevel
            new_skill_info._BuffData[#new_skill_info._BuffData].AutoFlag = v.AutoFlag
            new_skill_info._BuffData[#new_skill_info._BuffData].DueTime = v.DueTime
            new_skill_info._BuffData[#new_skill_info._BuffData].ActivityFlag = v.ActivityFlag
        end
    end
    return new_skill_info
end

CGuildMsgParser.Commit()
return CGuildMsgParser