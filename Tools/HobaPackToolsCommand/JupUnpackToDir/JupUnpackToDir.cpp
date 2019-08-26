#include "af.h"
#include "FileOperate.h"
#include "function.h"
#include "stringext.h"
#include "AWinMemDbg.h"
#include "VersionMan.h"
#include "AFramework.h"
#include <string>

extern "C"
{
#include "7zreader_export.h"
#include "packfunc_export.h"
}

char curDir[1024];
bool doUnpackFrom7z(const char* strFileName);

bool DoUnpackToDir(const char* jupDir, const char* outputDir);

int main(int argc, char* argv[])
{
	if (argc != 3)
	{
		printf("usage: JupUnpackToDir.exe <JupDir> <OutputDir>\r\n");
		getchar();
		return -1;
	}

#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	//_CrtSetBreakAlloc(106);
	std::string strJupDir = argv[1];
	std::string strOutputPath = argv[2];
	normalizeDirName(strOutputPath);

	GetCurrentDirectoryA(1024, curDir);
	std::string strCurDir = curDir;
	normalizeDirName(strCurDir);

	HOBAInitParam param;
	param.pszBaseDir = strCurDir.c_str();
	param.pszDocumentDir = strCurDir.c_str();
	param.pszLibraryDir = strOutputPath.c_str();
	param.pszTemporaryDir = strCurDir.c_str();

	g_pAFramework->Init(param);

	//
	printf("Start JupUnpackToDir: %s to %s\r\n\r\n", strJupDir.c_str(), strOutputPath.c_str());
	g_pAFramework->Printf("Start JupUnpackToDir: %s to %s\r\n\r\n", strJupDir.c_str(), strOutputPath.c_str());
	if (!DoUnpackToDir(strJupDir.c_str(), strOutputPath.c_str()))
	{
		goto FAIL;
	}
	printf("JupUnpackToDir succeed! OutputDir: %s\r\n", strOutputPath.c_str());
	g_pAFramework->Printf("JupUnpackToDir succeed!OutputDir: %s\r\n", strOutputPath.c_str());

	g_pAFramework->Release();

	//getchar();
	return 0;

FAIL:
	printf("End JupUnpackToDir, Fail!\r\n");
	g_pAFramework->Printf("End JupUnpackToDir, Fail!\r\n");

	g_pAFramework->Release();

	//getchar();
	return -1;
}

std::string MakeShortAssetBundlesFileName(const std::string& filename)
{
	if (strstr(filename.c_str(), "AssetBundles/") == filename.c_str())
	{
		char tmp[1024];
		getFileNameA(filename.c_str(), tmp, 1024);
		return std::string("AssetBundles/") + tmp;
	}
	else
	{
		return filename;
	}
}

bool doUnpackFrom7z(const char* strFileName)
{
	bool bRet = true;
	SevenZReader* reader = SevenZReader_Init(strFileName);

	if (!reader)
	{
		bRet = false;
		printf("SevenZReader_Init Failed!\r\n", strFileName);
		g_pAFramework->Printf("SevenZReader_Init Failed!\r\n", strFileName);
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
			printf("SevenZReader_GetFileName Failed! %d\r\n", i);
			g_pAFramework->Printf("SevenZReader_GetFileName Failed! %d\r\n", i);
			break;
		}

		std::string name = szName;
		printf("Process %s\r\n", name.c_str());
		g_pAFramework->Printf("Process %s\r\n", name.c_str());

		const unsigned char* pData;
		int nDataSize;
		if (!SevenZReader_ExtractFile(reader, i, &pData, &nDataSize))
		{
			bRet = false;
			printf("SevenZReader_ExtractFile Failed! %d\r\n", i);
			g_pAFramework->Printf("SevenZReader_ExtractFile Failed! %d\r\n", i);
			break;
		}

		if (nDataSize < 4)
		{
			bRet = false;
			printf("SevenZReader_ExtractFile nDataSize<4 Broken! %d\n", i);
			g_pAFramework->Printf("SevenZReader_ExtractFile nDataSize<4 Broken! %d\n", i);
			break;
		}

		if (name == "inc")		   //跳过inc
			continue;

		
		std::string actualName;
		if (strstr(name.c_str(), "AssetBundles/") == name.c_str())
		{
			actualName = MakeShortAssetBundlesFileName(name);
		}
		else
		{
			actualName = name;
		}

		if (!UncompressToSepFile(actualName.c_str(), pData, nDataSize))
		{
			bRet = false;
			printf("UncompressToSepFile Failed! %s\n", name.c_str());
			g_pAFramework->Printf("UncompressToSepFile Failed! %s\n", name.c_str());
			break;
		}
	}


	SevenZReader_Destroy(reader);

	return bRet;
}

bool DoUnpackToDir(const char* jupDir, const char* outputDir)
{
	std::string strJupDir = jupDir;
	normalizeDirName(strJupDir);
	std::string verionTxt = strJupDir + "version.txt";

	if (!ASys::IsFileExist(verionTxt.c_str()))
	{
		printf("version.txt does not exist! %s\r\n", verionTxt.c_str());
		g_pAFramework->Printf("version.txt does not exist!%s\r\n", verionTxt.c_str());
		return false;
	}

	FILE* pFile = fopen(verionTxt.c_str(), "rt");
	if (!pFile)
	{
		printf("File open failed! %s\r\n", verionTxt.c_str());
		g_pAFramework->Printf("File open failed! %s\r\n", verionTxt.c_str());
		return false;
	}

	VersionMan versionMan;
	if (!versionMan.LoadVersions(pFile))
	{
		printf("Cannot load version.txt! %s\r\n", verionTxt.c_str());
		g_pAFramework->Printf("Cannot load version.txt! %s\r\n", verionTxt.c_str());
	}

	//
	ELEMENT_VER baseVersion = versionMan.GetSeparateVer();
	ELEMENT_VER lastestVersion = versionMan.GetLatestVer();
	std::string strBaseVersion = baseVersion.ToString();
	std::string strLastestVersion = lastestVersion.ToString();

	const VER_PAIR* verPair = NULL;
	verPair = versionMan.FindVersionPair(baseVersion);
	if (!verPair)
	{
		printf("Cannot find baseVersion: %s\r\n", strBaseVersion.c_str());
		g_pAFramework->Printf("Cannot find baseVersion: %s\r\n", strBaseVersion.c_str());
		return false;
	}

	//读取每个versionPair
	while (verPair->VerTo == lastestVersion || verPair->VerTo < lastestVersion)
	{
		std::string strFrom = verPair->VerFrom.ToString();
		std::string strTo = verPair->VerTo.ToString();

		std::string strJup = strFrom + "-" + strTo + ".jup";
		std::string strFileName = strJupDir + strJup;

		printf("doUnpackFrom7z: %s\r\n", strJup.c_str());
		g_pAFramework->Printf("doUnpackFrom7z: %s\r\n", strJup.c_str());
		if (!doUnpackFrom7z(strFileName.c_str()))
		{
			printf("doUnpackForm7z Failed! %s\n", strFileName.c_str());
			g_pAFramework->Printf("doUnpackForm7z Failed! %s\n", strFileName.c_str());
			ASSERT(false);
			continue;
		}

		verPair = versionMan.FindVersionPair(verPair->VerTo);
		if (!verPair)
			break;
	}

	fclose(pFile);
	return true;

FAIL:
	fclose(pFile);
	return false;
}