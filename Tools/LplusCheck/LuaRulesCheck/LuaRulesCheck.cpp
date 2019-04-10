#include "function.h"
#include "CLuaRulesChecker.h"
#include "stringext.h"

int main(int argc, char* argv[])
{
	if (argc != 4)
	{
		printf("param error!\r\n");
		printf("usage: LuaRulesCheck.exe <configsdir> <luadir> <resultfile>\n");

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

	CLuaRulesChecker lpluschecker(strLuaDir);

	if (!lpluschecker.BuildLuaClasses())
	{
		ASSERT(false);
		printf("failed to build luaClasses\n");
		goto FAIL;
	}

	if (!lpluschecker.CheckLuaClassesToFile(strOutFileName.c_str()))
	{
		ASSERT(false);
		printf("failed to check luaClasses\n");
		goto FAIL;
	}

	lpluschecker.PrintLuaClasses();

	//getchar();
	return 0;

FAIL:

	getchar();
	return -1;
}