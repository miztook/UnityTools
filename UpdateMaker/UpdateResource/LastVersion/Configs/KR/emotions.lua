
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

emotion_list:addEmotion(1,"미소")
{
	pingyin = "weixiao",
	sprite = "Emotion01_weixiao",
}

emotion_list:addEmotion(2,"폭소")
{
	pingyin = "daxiao",
	sprite = "Emotion02_daxiao",
}

emotion_list:addEmotion(3,"장난")
{
	pingyin = "wanpi",
	sprite = "Emotion03_wanpi",
}
emotion_list:addEmotion(4,"애교")
{
	pingyin = "keai",
	sprite = "Emotion04_keai",
}
emotion_list:addEmotion(5,"화남")
{
	pingyin = "shengqi",
	sprite = "Emotion05_shengqi",
}
emotion_list:addEmotion(6,"분노")
{
	pingyin = "fanu",
	sprite = "Emotion06_fanu",
}
emotion_list:addEmotion(7,"광기")
{
	pingyin = "zhuakuang",
	sprite = "Emotion07_zhuakuang",
}
emotion_list:addEmotion(8,"부끄")
{
	pingyin = "haixiu",
	sprite = "Emotion08_haixiu",
}
emotion_list:addEmotion(9,"걱정")
{
	pingyin = "fachou",
	sprite = "Emotion09_fachou",
}
emotion_list:addEmotion(10,"놀람")
{
	pingyin = "jingya",
	sprite = "Emotion10_jingya",
}
emotion_list:addEmotion(11,"공포")
{
	pingyin = "kongbu",
	sprite = "Emotion11_kongbu",
}
emotion_list:addEmotion(12,"고통")
{
	pingyin = "nanguo",
	sprite = "Emotion12_nanguo",
}
emotion_list:addEmotion(13,"눈물")
{
	pingyin = "daku",
	sprite = "Emotion13_daku",
}
emotion_list:addEmotion(14,"유혹")
{
	pingyin = "se",
	sprite = "Emotion14_se",
}
emotion_list:addEmotion(15,"멍청")
{
	pingyin = "fadai",
	sprite = "Emotion15_fadai",
}
emotion_list:addEmotion(16,"의문")
{
	pingyin = "yiwen",
	sprite = "Emotion16_yiwen",
}
emotion_list:addEmotion(17,"억울")
{
	pingyin = "wugu",
	sprite = "Emotion17_wugu",
}
emotion_list:addEmotion(18,"덜덜")
{
	pingyin = "han",
	sprite = "Emotion18_han",
}
emotion_list:addEmotion(19,"졸림")
{
	pingyin = "kun",
	sprite = "Emotion19_kun",
}
emotion_list:addEmotion(20,"쿨쿨")
{
	pingyin = "shui",
	sprite = "Emotion20_shui",
}
emotion_list:addEmotion(21,"부탁")
{
	pingyin = "qiu",
	sprite = "Emotion21_qiu",
}
emotion_list:addEmotion(22,"무시")
{
	pingyin = "bishi",
	sprite = "Emotion22_bishi",
}
emotion_list:addEmotion(23,"승리")
{
	pingyin = "shengli",
	sprite = "Emotion23_shengli",
}
emotion_list:addEmotion(24,"당당")
{
	pingyin = "deyi",
	sprite = "Emotion24_deyi",
}
emotion_list:addEmotion(25,"실패")
{
	pingyin = "shibai",
	sprite = "Emotion25_shibai",
}
emotion_list:addEmotion(26,"아부")
{
	pingyin = "aida",
	sprite = "Emotion26_aida",
}
emotion_list:addEmotion(27,"우울")
{
	pingyin = "jionga",
	sprite = "Emotion27_jionga",
}
emotion_list:addEmotion(28,"뽀뽀")
{
	pingyin = "qinwen",
	sprite = "Emotion28_qinwen",
}

--配置结束

return emotion_list
