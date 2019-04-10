
local emotion_list = {}
local l_config = {}

function emotion_list:getConfigs()
	return l_config
end

function emotion_list:addEmotion(id,name)
	return function (config)
		config.name = name
		l_config[id] = config
	end
end

emotion_list:addEmotion(1,"微笑")
{
	pingyin = "weixiao",
	sprite = "Emotion01_weixiao",
}

emotion_list:addEmotion(2,"大笑")
{
	pingyin = "daxiao",
	sprite = "Emotion02_daxiao",
}

emotion_list:addEmotion(3,"顽皮")
{
	pingyin = "wanpi",
	sprite = "Emotion03_wanpi",
}
emotion_list:addEmotion(4,"可爱")
{
	pingyin = "keai",
	sprite = "Emotion04_keai",
}
emotion_list:addEmotion(5,"生气")
{
	pingyin = "shengqi",
	sprite = "Emotion05_shengqi",
}
emotion_list:addEmotion(6,"发怒")
{
	pingyin = "fanu",
	sprite = "Emotion06_fanu",
}
emotion_list:addEmotion(7,"抓狂")
{
	pingyin = "zhuakuang",
	sprite = "Emotion07_zhuakuang",
}
emotion_list:addEmotion(8,"害羞")
{
	pingyin = "haixiu",
	sprite = "Emotion08_haixiu",
}
emotion_list:addEmotion(9,"发愁")
{
	pingyin = "fachou",
	sprite = "Emotion09_fachou",
}
emotion_list:addEmotion(10,"惊讶")
{
	pingyin = "jingya",
	sprite = "Emotion10_jingya",
}
emotion_list:addEmotion(11,"恐怖")
{
	pingyin = "kongbu",
	sprite = "Emotion11_kongbu",
}
emotion_list:addEmotion(12,"难过")
{
	pingyin = "nanguo",
	sprite = "Emotion12_nanguo",
}
emotion_list:addEmotion(13,"大哭")
{
	pingyin = "daku",
	sprite = "Emotion13_daku",
}
emotion_list:addEmotion(14,"色")
{
	pingyin = "se",
	sprite = "Emotion14_se",
}
emotion_list:addEmotion(15,"发呆")
{
	pingyin = "fadai",
	sprite = "Emotion15_fadai",
}
emotion_list:addEmotion(16,"疑问")
{
	pingyin = "yiwen",
	sprite = "Emotion16_yiwen",
}
emotion_list:addEmotion(17,"无辜")
{
	pingyin = "wugu",
	sprite = "Emotion17_wugu",
}
emotion_list:addEmotion(18,"寒")
{
	pingyin = "han",
	sprite = "Emotion18_han",
}
emotion_list:addEmotion(19,"困")
{
	pingyin = "kun",
	sprite = "Emotion19_kun",
}
emotion_list:addEmotion(20,"睡")
{
	pingyin = "shui",
	sprite = "Emotion20_shui",
}
emotion_list:addEmotion(21,"求")
{
	pingyin = "qiu",
	sprite = "Emotion21_qiu",
}
emotion_list:addEmotion(22,"鄙视")
{
	pingyin = "bishi",
	sprite = "Emotion22_bishi",
}
emotion_list:addEmotion(23,"胜利")
{
	pingyin = "shengli",
	sprite = "Emotion23_shengli",
}
emotion_list:addEmotion(24,"得意")
{
	pingyin = "deyi",
	sprite = "Emotion24_deyi",
}
emotion_list:addEmotion(25,"失败")
{
	pingyin = "shibai",
	sprite = "Emotion25_shibai",
}
emotion_list:addEmotion(26,"爱戴")
{
	pingyin = "aida",
	sprite = "Emotion26_aida",
}
emotion_list:addEmotion(27,"囧啊")
{
	pingyin = "jionga",
	sprite = "Emotion27_jionga",
}
emotion_list:addEmotion(28,"亲吻")
{
	pingyin = "qinwen",
	sprite = "Emotion28_qinwen",
}

--配置结束

return emotion_list