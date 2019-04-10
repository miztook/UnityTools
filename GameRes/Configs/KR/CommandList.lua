local CommandList = {}


local list = {}
function CommandList:GetAllCommandList ()
	return list
end

function CommandList:AddCommandInfo()
	return function (command_info)
		list[#list + 1] = command_info
	end
end


-- TO DO : 1、角色,单位 2、物品 3、生成器 4、调试 5、任务 6、地图 7、掉落 8、公会、CG相关  9、副本
CommandList:AddCommandInfo()
{
	name = "레벨업",
	cmd = "c 22 0 ",
	desc = "C 22 0 레벨 (마이너스는 레벨 하락 표시)",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "자살",
	cmd = "c 41", 
	desc = "C 41",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "능력치",
	cmd = "c 74", 
	desc = "C 74 옵션id 능력치 증가량",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "debug모드",
	cmd = "debugOpen ", 
	desc = "debugOpen 0/1 0닫기, 1열기, debug제어 모드 열기/끄기",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "골드 증감",
	cmd = "c 23 1 ", 
	desc = "C 23 1 수량",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "다이아 증감",
	cmd = "c 23 2 ", 
	desc = "C 23 2 수량",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "귀속다이아 증감",
	cmd = "c 23 3 ", 
	desc = "C 23 3 수량",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "아이템(장비) 추가",
	cmd = "c 31 ", 
	desc = "C 31 아이템ID  수량",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "아이템 (장비) 삭제",
	cmd = "c 32 ", 
	desc = "C 32 인벤토리 칸(0부터 시작) 수",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "아이템 사용",
	cmd = "c 37 ", 
	desc = "c 37 인벤토리 칸(1부터 시작)",
	type = 2,
}

CommandList:AddCommandInfo()
{
	name = "몬스터",
	cmd = "c 1 ", 
	desc = "C 1 몬스터ID 수",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "NPC",
	cmd = "c 2 ", 
	desc = "C 2 NPC_ID 수",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "채집가능 아이템",
	cmd = "c 3 ", 
	desc = "C 3 채집가능 유닛ID 수",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "탈 것",
	cmd = "c 100 ", 
	desc = "C 100 탈 것 유닛ID 수",
	type = 1,
}

CommandList:AddCommandInfo()
{
	name = "시야 스캔",
	cmd = "c 364", 
	desc = "C 364",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "단축키 보기",
	cmd = "c 369 ", 
	desc = "C 369 단축키ID",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "몬스터 순찰 전환 단축키",
	cmd = "c 366 ", 
	desc = "C 366 단축키ID 1 경로ID",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "단축키 활성화",
	cmd = "c 366 ", 
	desc = "C 366 단축키ID 2",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "단축키 비활성화",
	cmd = "c 366 ", 
	desc = "C 366 단축키ID 3",
	type = 3,
}

CommandList:AddCommandInfo()
{
	name = "navmesh",
	cmd = "navmesh ", 
	desc = "navmesh 0/1",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "임시 기능 전체 오픈",
	cmd = "FunOpen 1", 
	desc = "FunOpen 0/1 0닫기, 1열기, 게임 종료 후 리셋됩니다.",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "학습",
	cmd = "GuideOpen 1", 
	desc = "GuideOpen 0/1 0닫기, 1열기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "콘텐츠",
	cmd = "c 103 2 ", 
	desc = "c 103 2 이벤트 id 횟수 증가",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "reg1onset 표시 / 숨기기",
	cmd = "regionset ", 
	desc = "regionset 0/<맵id> (MapInfo GameRes에 복사)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "obstacleset 표시 / 숨기기",
	cmd = "obstacleset ", 
	desc = "obstacleset 0/<맵id> (MapInfo GameRes에 복사)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "C2S 출력",
	cmd = "logc2s ", 
	desc = "logc2s 0/1 1표시, 0숨기기 클라이언트 약정",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "S2C 출력",
	cmd = "logs2c ", 
	desc = "logs2c 0/1 1표시, 0숨기기 서버 약정",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "현재UI 표시 / 숨기기",
	cmd = "showui ", 
	desc = "showui 0/1 1표시, 0숨기기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "Npc 음성 재생",
	cmd = "playvoice ", 
	desc = "playvoice <name>",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "3D 음향효과 재생",
	cmd = "playaudio3d ", 
	desc = "playaudio3d <name> [distance]",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "2D 음향효과 재생",
	cmd = "playaudio2d ", 
	desc = "playaudio2d <name>",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "Camera 권한 허용",
	cmd = "reqcamerapermission", 
	desc = "reqcamerapermission",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "Photo 권한 허용",
	cmd = "reqphotopermission", 
	desc = "reqphotopermission",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "게임 계수",
	cmd = "stats ", 
	desc = "stats (1-7) 0/1 1열기, 0닫기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "게임 성능 디버그",
	cmd = "perfs ", 
	desc = "perfs (1-4) 0/1 1열기, 0닫기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "포스트프로세싱 열기/닫기",
	cmd = "postprocess ", 
	desc = "postprocess 0/1 1열기, 0닫기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "서버 디버그모드",
	cmd = "C 400 ", 
	desc = "c 400 오프라인시간 간격",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "추가상태",
	cmd = "C 83 ", 
	desc = "c 83 상태ID 0/1(0본인 디폴트 값, 1 other)",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "옵션 표시 / 숨기기",
	cmd = "C 500 ", 
	desc = "c 500 플레이어 설정 옵션 표시 / 숨기기",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "event 통계 출력",
	cmd = "logevent", 
	desc = "logevent",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "timer 통계 출력",
	cmd = "logtimer", 
	desc = "logtimer",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "캐릭터 정보 확인",
	cmd = "c 206 ", 
	desc = "c 206 캐릭터ID",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "계정명으로 유저 강제 로그아웃",
	cmd = "c 450 ", 
	desc = "c 450 계정Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "계정명으로 유저 정보 확인",
	cmd = "c 451 ", 
	desc = "c 451 계정Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "캐릭터명으로 유저 정보 확인",
	cmd = "c 452 ", 
	desc = "c 452 캐릭터Name",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "현재 시야 내 유저 정보 확인",
	cmd = "c 453", 
	desc = "c 453 현재 시야 내 유저 정보 확인",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "자동 장비 장착",
	cmd = "c 359", 
	desc = "c 359 장비 레벨",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "1개 우편 추가",
	cmd = "c 90 1 1 1", 
	desc = "c 90 1 1 1",
	type = 4,
}

CommandList:AddCommandInfo()
{
	name = "퀘스트 활성 상태 보기",
	cmd = "c 64 ", 
	desc = "C 64 퀘스트ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "퀘스트 수령",
	cmd = "c 61 ", 
	desc = "C 61 퀘스트ID 1(무조건 수령)",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "퀘스트 포기",
	cmd = "c 62 ", 
	desc = "C 62 퀘스트ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "퀘스트의 모든 목표 완료",
	cmd = "c 63 ", 
	desc = "C 63 퀘스트ID",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "퀘스트 완료 상태",
	cmd = "c 59 ", 
	desc = "c 59 퀘스트id 퀘스트 완료 상태로",
	type = 5,
}

CommandList:AddCommandInfo()
{
	name = "무조건 퀘스트 제출",
	cmd = "c 60 ", 
	desc = "c 60 퀘스트id 무조건 퀘스트 제출",
	type = 5,
}


CommandList:AddCommandInfo()
{
	name = "본 맵의 지정 좌표로 텔레포트",
	cmd = "c 51 ", 
	desc = "c 51 x y",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "이동속도 조정",
	cmd = "c 71 ", 
	desc = "c 71 속도",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "세계",
	cmd = "c 81 ", 
	desc = "c 81 맵id x좌표 z좌표 텔레포트 가능한 월드 정보ID, 리스트에서 선택가능, 확인 후 월드 입장",
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "던전",
	cmd = "c 69 0 ",
	desc = "c 69 0 던전id 텔레포트 가능한 던전 정보ID, 리스트에서 선택 가능, 확인 후 던전 입장" ,
	type = 6,
}

CommandList:AddCommandInfo()
{
	name = "드랍",
	cmd = "c 66 ", 
	desc = "C 66 몬스터 ID 몬스터 수량, 몬스터 수는 해당 몬스터의 드랍 횟수를 의미",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "드랍 보기",
	cmd = "c 66 666 666", 
	desc = "서버 드랍 아이템 생성, 삭제, 줍기 수량 표시",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "드랍 삭제",
	cmd = "c 66 777 777", 
	desc = "본인 드랍 삭제",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "통계 데이터 삭제",
	cmd = "c 66 888 888", 
	desc = "666관련 통계 데이터 삭제",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "통계 데이터 표시",
	cmd = "c 66 -999 ", 
	desc = "c 66 - 999 몬스터 ID 통계 데이터 보이기 몬스터 처치 횟수 및 드랍 통계 데이터",
	type = 7,
}

CommandList:AddCommandInfo()
{
	name = "원터치 만렙",
	cmd = "c 22 0 100", 
	desc = "c 22 0 최대 레벨 달성",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "원터치 즉살",
	cmd = "c 73", 
	desc = "c 73 필드 내 몬스터 원터치 처치",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "인벤토리 전체오픈",
	cmd = "c 358", 
	desc = "c 358 인벤토리 전체오픈",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "길드 기지",
	cmd = "c 110", 
	desc = "c 110 길드 기지",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "길드 창고",
	cmd = "c 111 ", 
	desc = "c 111 아이템ID 수량",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "CG 재생",
	cmd = "c 102 ", 
	desc = "c 102 자원ID",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "문장",
	cmd = "c 200 ", 
	desc = "c 200 문장index",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "미러 생성",
	cmd = "C 121 ", 
	desc = "c 121 캐릭터id",
	type = 8,
}

CommandList:AddCommandInfo()
{
	name = "던전 입장",
	cmd = "C 69 0 ", 
	desc = "C 69 0 던전id 던전 입장",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "던전 나가기",
	cmd = "C 69 1", 
	desc = "C 69 1 현재 던전 나가기",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "던전 횟수 재설정",
	cmd = "C 69 777", 
	desc = "C 69 777 모든 던전 횟수 재설정",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "던전 입장 횟수 증가",
	cmd = "C 69 777 ", 
	desc = "C 69 777 던전 id 횟수",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "현재 던전 Log 유도",
	cmd = "C 69 666", 
	desc = "C 69 666 현재 던전 Log 유도",
	type = 9,
}

CommandList:AddCommandInfo()
{
	name = "결산으로 건너뛰기",
	cmd = "C 69 999", 
	desc = "C 69 999 던전에서 결산으로 건너뛰기",
	type = 9,
}

return CommandList
