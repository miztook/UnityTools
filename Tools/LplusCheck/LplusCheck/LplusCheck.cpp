#include "function.h"
#include "CLplusChecker.h"
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

	CLplusChecker lplusChecker(strConfigsDir, strLuaDir);
	lplusChecker.Init();
	
	printf("Start Collect...\n");
	lplusChecker.CollectClasses();
	lplusChecker.CollectFiles();
	lplusChecker.CollectGameText();

	//printf("Start Checking...\n");
	//lplusChecker.CheckResultToFile(strOutFileName.c_str());
	//printf("Checking Complete!");

	lplusChecker.PrintLuaClasses();
	//lplusChecker.PrintLuaFiles();


	//Êä³öÎÄ¼þ
	{
		std::string outputFile = tmp;
		normalizeDirName(outputFile);
		outputFile += "./LuaClass.txt";

		FILE* pFile = fopen(outputFile.c_str(), "wt");
		if (pFile)
		{
			lplusChecker.PrintLuaClassHierachyToFile(pFile);

			fclose(pFile);
		}
	}

	{
		std::string outputFile = tmp;
		normalizeDirName(outputFile);
		outputFile += "./LuaClass.csv";

		FILE* pFile = fopen(outputFile.c_str(), "wt");
		if (pFile)
		{
			lplusChecker.PrintLuaClassHierachyToCsv(pFile);

			fclose(pFile);
		}
	}
	

	getchar();
	return 0;
}