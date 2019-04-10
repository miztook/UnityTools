
--人类男名字
local HumanMaleFirstNames =
{
"지프",
"잭",
"야이크",
"미섈",
"파오라",
"토비오",
"룬",
"라스",
"유리언",
"레이프언",
"나란드",
"에리크",
"프에란",
"트론드",
"제이",
}

--人类男姓氏
local HumanMaleLastNames =
{
"로만",
"신드리",
"헤인즈",
"보드윈",
"드시프",
"레이한",
"에든",
"베르고",
"베린",
"마로",
"에르",
"그레이스",
"존슨",
"카프레이",
"모리슨",
}

--精灵女名字(第一段)
local ElfFemaleFirstNames = 
{
"라스",
"아",
"에",
"비",
"고",
"티",
"웨이",
"길",
"푸",
"이",
"크",
"비",
"오",
"소",
"서",
}

--精灵女名字(第二段)
local ElfFemaleSecondNames = 
{
"나",
"인",
"란",
"사",
"야",
"타",
"안",
"틴",
"카이",
"야",
"리안",
"러트",
"트",
"기",
"크",
}

--精灵女姓氏
local ElfFemaleLastNames = 
{
"사파레은",
"나한",
"쿠벨",
"라페레이트",
"화이트리보",
"인세로드",
"하이윈터",
"리웰마",
"그라니아",
"고드레이크",
}

--卡斯塔尼克姓氏为空的概率(0-1)
local CastanicLastNameNilPro = 0.4
--卡斯塔尼克男名字
local CastanicMaleFirstNames =
{
"르수한",
"카레이라스",
"하칸",
"라인하트",
"나시온",
"두산",
"파베이",
"자크",
"테리언",
"두얼린",
"길라트",
"사이르지에",
"푸란크",
"오카한",
"밀로",
}

--卡斯塔尼克男姓氏
local CastanicMaleLastNames =
{
"마칸",
"리스란",
"에소와라",
"레이스니아",
"시리아",
"시니타",
"티빈",
"알고레이",
"시무스",
"페이룬",
"티판",
"피나미스",
"베르마스",
"리",
"피스크",
}

--艾琳女名字(第一段)
local IreneFemaleFirstNames = 
{
"아이",
"마",
"마리",
"바",
"라",
"카",
"아",
"샤",
"이",
"사",
"리",
"사라",
"유",
"레이오",
"사이",
}

--艾琳女名字(第二段)
local IreneFemaleSecondNames = 
{
"난나",
"린",
"씨야",
"디야",
"라",
"쿠",
"알",
"다",
"바나",
"미야",
"야",
"드야",
"리",
"리야",
"안나",
}

--艾琳女姓氏
local IreneFemaleLastNames = 
{
"엘린",
}

--中缀常用符号 
local InfixSymbols =
{
	"•"
}

return 
{
	HumanMaleFirstNames = HumanMaleFirstNames,
	HumanMaleLastNames = HumanMaleLastNames,
	CastanicLastNameNilPro = CastanicLastNameNilPro,
	CastanicMaleFirstNames = CastanicMaleFirstNames,
	CastanicMaleLastNames = CastanicMaleLastNames,
	IreneFemaleFirstNames = IreneFemaleFirstNames,
	IreneFemaleSecondNames = IreneFemaleSecondNames,
	IreneFemaleLastNames = IreneFemaleLastNames,
	ElfFemaleFirstNames = ElfFemaleFirstNames,
	ElfFemaleSecondNames = ElfFemaleSecondNames,
	ElfFemaleLastNames = ElfFemaleLastNames,
	InfixSymbols = InfixSymbols,
}