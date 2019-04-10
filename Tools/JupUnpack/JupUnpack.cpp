#include "af.h"
#include "FileOperate.h"
#include "function.h"
#include "stringext.h"
#include "AWinMemDbg.h"
#include <string>

extern "C"
{
#include "7zreader_export.h"
#include "packfunc_export.h"
}


char curDir[1024];
bool doUnpackFrom7z(const char* strFileName);

int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		printf("usage: JupUnpack.exe <JupFileName>");
		getchar();
		return -1;
	}

#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	//_CrtSetBreakAlloc(106);

	AWinMemDbg globalDbg;
	globalDbg.beginCheckPoint();

	GetCurrentDirectoryA(1024, curDir);
	std::string strCurDir = curDir;
	normalizeDirName(strCurDir);

	std::string strFileName = argv[1];
	strFileName = strCurDir + strFileName;

	char tmp[1024];
	getFullFileNameNoExtensionA(argv[1], tmp, 1024);
	std::string strOutputDir = strCurDir + tmp;
	normalizeDirName(strOutputDir);

	af_Initialize(
		strCurDir.c_str(),
		strCurDir.c_str(),
		strOutputDir.c_str(),
		strCurDir.c_str());

	if (!af_IsFileExist(strFileName.c_str()))
	{
		printf("%s is not exist!\n", strFileName.c_str());
		goto FAIL;
	}

	if (!doUnpackFrom7z(strFileName.c_str()))
	{
		printf("doUnpackFrom7z Failed! %s\n", strFileName.c_str());
		goto FAIL;
	}

	af_Finalize();

	bool safe = globalDbg.endCheckPoint();
	//_ASSERT(safe);

	int memKB;
	globalDbg.outputMaxMemoryUsed(&memKB);	  
	printf("maximum memory used : %0.3f M\n", memKB * 0.001f);

	//getchar();
	return 0;

FAIL:
	printf("End JupUnpack, Fail\r\n");

	af_Finalize();
	//getchar();
	return -1;
}	 

bool doUnpackFrom7z(const char* strFileName)
{
	bool bRet = true;
	SevenZReader* reader = SevenZReader_Init(strFileName);

	if (!reader)
	{
		bRet = false;
		printf("SevenZReader_Init Failed! %s\n", strFileName);
		return bRet;
	}

	int fileCount = SevenZReader_GetFileCount(reader);
	for (int i = 0; i < fileCount; ++i)
	{
		if (SevenZReader_IsDir(reader, i))
			continue;

		const char* szName = SevenZReader_GetFileName(reader, i);
		if (szName == NULL)
		{
			bRet = false;
			printf("SevenZReader_GetFileName Failed! %d\n", i);
			break;
		}

		std::string name = szName;
		printf("Process %s\n", name.c_str());

		const unsigned char* pData;
		int nDataSize;
		if (!SevenZReader_ExtractFile(reader, i, &pData, &nDataSize))
		{
			bRet = false;
			printf("SevenZReader_ExtractFile Failed! %d\n", i);
			break;
		}

		if (nDataSize < 4)
		{
			bRet = false;
			printf("SevenZReader_ExtractFile nDataSize<4 Broken! %d\n", i);
			break;
		}

		if (name == "inc")		   //特殊处理
		{
			const char* libDir = af_GetLibraryDir();
			std::string strLib = libDir;
			normalizeDirName(strLib);
			strLib += name;
			FileOperate::MakeDir(strLib.c_str());

			if (!FileOperate::WriteToFile(strLib.c_str(), pData, nDataSize))
			{
				bRet = false;
				printf("FileOperate::WriteToFile Failed! %s\n", strLib.c_str());
				break;
			}
		}
		else	 //解压
		{
			if (!UncompressToSepFile(name.c_str(), pData, nDataSize))
			{
				bRet = false;
				printf("UncompressToSepFile Failed! %s\n", name.c_str());
				break;
			}
		}
	}


	SevenZReader_Destroy(reader);

	return bRet;
}

