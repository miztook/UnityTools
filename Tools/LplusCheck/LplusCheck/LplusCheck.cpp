#include "function.h"
#include "CLplusClassMan.h"
#include <cstring>
#include "stringext.h"

int main(int argc, char* argv[])
{
	if (argc != 4)
	{
		printf("param error!\r\n");
		printf("usage: LplusCheck.exe <configsdir> <luadir> <resultfile>\n");

		getchar();
		return -1;
	}

	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);

	std::string strConfigsDir;
	if (isAbsoluteFileName(argv[1]))
	{
		strConfigsDir = argv[1];
	}
	else
	{
		strConfigsDir = tmp;
		normalizeDirName(strConfigsDir);
		strConfigsDir += argv[1];
	}

	std::string strLuaDir;
	if (isAbsoluteFileName(argv[2]))
	{
		strLuaDir = argv[2];
	}
	else
	{
		strLuaDir = tmp;
		normalizeDirName(strLuaDir);
		strLuaDir += argv[2];
	}

	std::string strOutFileName;
	if (isAbsoluteFileName(argv[3]))
	{
		strOutFileName = argv[3];
	}
	else
	{
		strOutFileName = tmp;
		normalizeDirName(strOutFileName);
		strOutFileName += argv[3];
	}

	CLplusClassMan classMan(strLuaDir);
	classMan.Collect();

	const std::map<std::string, SLuaClass>& mapLuaClass = classMan.GetLuaClassMap();
	for (const auto& itr : mapLuaClass)
	{
		printf("%s\n", itr.first.c_str());
	}

	getchar();
	return 0;

FAIL:

	getchar();
	return -1;
}