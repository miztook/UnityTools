local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local EResourceType = require "PB.data".EResourceType
local MapBasicConfig = require "Data.MapBasicConfig" 
local CTransManage = require "Main.CTransManage"
local CPageReputation = Lplus.Class("CPageReputation")
local def = CPageReputation.define

def.field("userdata")._Panel = nil
def.field("table")._PanelObject = BlankTable

local instance = nil
def.static("=>", CPageReputation).Instance = function()
	if instance == nil then
        instance = CPageReputation()
	end
	return instance
end

def.method("table", "userdata").Show = function(self, linkInfo, root)
	self._Panel = root              --该分解的root 节点
    self._PanelObject = linkInfo    --存储引用的table在上层传递进来
	self:UpdateReputations()
end

def.method().UpdateReputations = function(self)
	local data_id_list = game._CReputationMan:GetAllReputationTIDs()

	local count = game._HostPlayer:GetMoneyCountByType(EResourceType.ResourceTypeGoldReputation)
	GUI.SetText(self._PanelObject._LabGold,tostring(count))

	local v = CElementData.GetTemplate("CountGroup", tonumber(CElementData.GetSpecialIdTemplate(318).Value) )
	local str = StringTable.Get(270)..game._CReputationMan._QuestFinishCount.."/"..v.MaxCount
	GUI.SetText(self._PanelObject._Lab_ReputationQuestCount,str)

	self._PanelObject._List_Reputations:SetItemCount(#data_id_list) 
end

def.method("userdata", "string", "number").InitItem = function(self, item, id, index)
    local idx = index + 1
    if id == 'List_Elements' then
    	--print(index)
        local data = game._CReputationMan:GetAllReputation()
        local data_id_list = game._CReputationMan:GetAllReputationTIDs()
        local template = CElementData.GetTemplate("Reputation", data_id_list[idx])
        -- --是否锁住
        local Img_Lock = item:FindChild("Img_BG/Img_Lock")
        local Img_BG = item:FindChild("Img_BG")
        -- local Lab_LockDes = item:FindChild("Img_BG/Img_Lock/Lab_LockDes")

        local Img_Icon = item:FindChild("Img_BG/Img_Icon")
        local Lab_ReputationLvIcon = item:FindChild("Img_BG/Lab_ReputationLvIcon")
        -- local Img_Finish = item:FindChild("Img_BG/Img_Finish")
        local Lab_Name = item:FindChild("Img_BG/Lab_Name")
        local Lab_ReputationLv = item:FindChild("Img_BG/Lab_ReputationLv")
        local Pro_Loading = item:FindChild("Img_BG/Pro_Loading")
        local Lab_Progress = item:FindChild("Img_BG/Pro_Loading/Lab_Progress")
        local Btn_Buy = item:FindChild("Img_BG/Btn_Buy")
        local Img_Front = item:FindChild("Img_BG/Pro_Loading/Front"):GetComponent(ClassType.Image)


        if data[template.Id] ~= nil  then
        	Img_Lock:SetActive(false)
            GameUtil.SetImageColor(Img_BG, Color.New(1, 1, 1, 1))
        	Lab_Name:SetActive(true)
             GUI.SetText(Lab_Name, template.TextDisplayName )

            Lab_ReputationLv:SetActive(true)
            GUI.SetText(Lab_ReputationLv, StringTable.Get(25000+data[template.Id].Level) )

            local levelExps = { template.ReputationLevelExp1,template.ReputationLevelExp2,template.ReputationLevelExp3,template.ReputationLevelExp4,template.ReputationLevelExp5 }
            Pro_Loading:SetActive(true)
            local str = data[template.Id].Exp.."/"..levelExps[data[template.Id].Level]
            GUI.SetText(Lab_Progress, str )
            Img_Front.fillAmount = data[template.Id].Exp / levelExps[data[template.Id].Level]

            local iconPath = _G.CommonAtlasDir .. "Icon/" .. template.IconAtlasPath..".png"
            Img_Icon:SetActive(true)
            GUITools.SetSprite(Img_Icon, iconPath)

            Btn_Buy:SetActive(true)
            Lab_ReputationLvIcon:SetActive(true)
            GUITools.SetGroupImg(Lab_ReputationLvIcon,data[template.Id].Level-1)
        else
        	Img_Lock:SetActive(true)
            GameUtil.SetImageColor(Img_BG, Color.New(1, 1, 1, 0))
            Lab_Name:SetActive(false)
            Lab_ReputationLv:SetActive(false)
            Img_Icon:SetActive(false)
            Pro_Loading:SetActive(false)
            Btn_Buy:SetActive(false)
            Lab_ReputationLvIcon:SetActive(false)
        end
    end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, item, id, id_btn, index)
	local data_id_list = game._CReputationMan:GetAllReputationTIDs()
    local template = CElementData.GetTemplate("Reputation", data_id_list[index+1])

    --local function DoCallback()
    --end

    local scene_id, dest_pos, idx = MapBasicConfig.GetDestParams("Npc", template.AssociatedNpcTId, {})
    CTransManage.Instance():StartMoveByMapIDAndPos(scene_id, dest_pos, nil, true, true)
    game._GUIMan:Close("CPanelRoleInfo")
end

def.method().Hide = function(self)
    self._Panel = nil  
end

def.method().Destroy = function(self)
    instance = nil 
end

CPageReputation.Commit()
return CPageReputation