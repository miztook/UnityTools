local MapRegionList = {}


local regionlist = {}
function MapRegionList:GetAllRegionList ()
	return regionlist
end

function MapRegionList:AddRegionInfo()
	return function (region_info)
		regionlist[region_info.name] = region_info
	end
end

MapRegionList:AddRegionInfo()
{
	name = "grassfield", --草地
	HumanFootPrintPath = "1", --人类脚印
	HUmanFootSoundEffectPath ="1", --人类脚步音效
	CastanicFootPrintPath = "1", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="1", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "1", --艾琳脚印
	AileenFootSoundEffectPath ="1", --艾琳脚步音效
	SpiritFootPrintPath = "1",--精灵脚印
	SpiritFootSoundEffectPath ="1",  --精灵脚步音效
}

MapRegionList:AddRegionInfo()
{
	name = "snowfield",--雪地
	HumanFootPrintPath = "1", --人类脚印
	HUmanFootSoundEffectPath ="1", --人类脚步音效
	CastanicFootPrintPath = "1", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="1", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "1", --艾琳脚印
	AileenFootSoundEffectPath ="1", --艾琳脚步音效
	SpiritFootPrintPath = "1",--精灵脚印
	SpiritFootSoundEffectPath ="1",  --精灵脚步音效
}

MapRegionList:AddRegionInfo()
{
	name = "sandfield",--沙滩
	HumanFootPrintPath = "Assets\Outputs\Sfx\Etc\etc_jiaoyin_L.prefab", --人类脚印
	HUmanFootSoundEffectPath ="Assets\Outputs\Sound\Moving\Moving_Gravel_Land_00.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_01.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_02.wav", --人类脚步音效
	CastanicFootPrintPath = "Assets\Outputs\Sfx\Etc\etc_jiaoyin_L.prefab", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="Assets\Outputs\Sound\Moving\Moving_Gravel_Land_00.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_01.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_02.wav", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "Assets\Outputs\Sfx\Etc\etc_jiaoyin_L.prefab", --艾琳脚印
	AileenFootSoundEffectPath ="Assets\Outputs\Sound\Moving\Moving_Gravel_Land_00.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_01.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_02.wav", --艾琳脚步音效
	SpiritFootPrintPath = "Assets\Outputs\Sfx\Etc\etc_jiaoyin_L.prefab",--精灵脚印
	SpiritFootSoundEffectPath ="Assets\Outputs\Sound\Moving\Moving_Gravel_Land_00.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_01.wav,Assets\Outputs\Sound\Moving\Moving_Gravel_Land_02.wav",  --精灵脚步音效
}

MapRegionList:AddRegionInfo()
{
	name = "waterfield",--浅水
	HumanFootPrintPath = "1", --人类脚印
	HUmanFootSoundEffectPath ="1", --人类脚步音效
	CastanicFootPrintPath = "1", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="1", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "1", --艾琳脚印
	AileenFootSoundEffectPath ="1", --艾琳脚步音效
	SpiritFootPrintPath = "1",--精灵脚印
	SpiritFootSoundEffectPath ="1", --精灵脚步音效
}

MapRegionList:AddRegionInfo()
{
	name = "woodfield",--木板
	HumanFootPrintPath = "1", --人类脚印
	HUmanFootSoundEffectPath ="1", --人类脚步音效
	CastanicFootPrintPath = "1", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="1", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "1", --艾琳脚印
	AileenFootSoundEffectPath ="1", --艾琳脚步音效
	SpiritFootPrintPath = "1",--精灵脚印
	SpiritFootSoundEffectPath ="1",  --精灵脚步音效
}

MapRegionList:AddRegionInfo()
{
	name = "stonefield",--石板
	HumanFootPrintPath = "1", --人类脚印
	HUmanFootSoundEffectPath ="1", --人类脚步音效
	CastanicFootPrintPath = "1", --卡斯塔尼克脚印
	CastanicFootSoundEffectPath ="1", --卡斯塔尼克脚步音效
	AileenFootPrintPath = "1", --艾琳脚印
	AileenFootSoundEffectPath ="1", --艾琳脚步音效
	SpiritFootPrintPath = "1",--精灵脚印
	SpiritFootSoundEffectPath ="1",  --精灵脚步音效
}

return MapRegionList
