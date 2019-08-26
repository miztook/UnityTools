extern "C"
{
#include "hoba_export.h"
}

#include "ASys.h"
#include "AFI.h"
#include "AFramework.h"
#include "elementpckdir.h"
#include "AFilePackMan.h"
#include "function.h"

#ifdef A_PLATFORM_WIN_DESKTOP

#include "AWinMemDbg.h"
#include "AWinMiniDump.h"

AWinMemDbg globalDbg;

#endif

char g_DocumentDir[512];
char g_LibraryDir[512];
char g_TmpDir[512];
char g_IOSLanguage[128];
char g_AndroidMAC[128];

HAPI const char* HOBA_GetDocumentDir()
{
	bool ret = ASys::GetDocumentsDirectory(g_DocumentDir, 512);
	return ret ? g_DocumentDir : NULL;
}

HAPI const char* HOBA_GetLibraryDir()
{
	bool ret = ASys::GetLibraryDirectory(g_LibraryDir, 512);
	return ret ? g_LibraryDir : NULL;
}

HAPI const char* HOBA_GetTmpDir()
{
	bool ret = ASys::GetTmpDirectory(g_TmpDir, 512);
	return ret ? g_TmpDir : NULL;
}

HAPI const char* HOBA_IOSGetCurLanguage()
{
	bool ret = ASys::IOSGetCurLanguage(g_IOSLanguage, 128);
	return ret ? g_IOSLanguage : NULL;
}

HAPI void HOBA_Init(const char* baseDir, const char* docDir, const char* libDir, const char* tmpDir)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	AWinMiniDump::begin();
	//globalDbg.beginCheckPoint();
	//globalDbg.setAllocHook(true, 0);
#endif

	char szCurrentDirectory[QMAX_PATH];
	strcpy(szCurrentDirectory, baseDir);

	char szDocumentDir[QMAX_PATH];
	strcpy(szDocumentDir, docDir);

	char strTempDirectory[QMAX_PATH];
	strcpy(strTempDirectory, tmpDir);

	char strLibDirectory[QMAX_PATH];
	strcpy(strLibDirectory, libDir);

#if defined(A_PLATFORM_ANDROID) || defined(A_PLATFORM_WIN_DESKTOP)
	ASys::CreateDirectory(szDocumentDir);
	ASys::CreateDirectory(strTempDirectory);
	ASys::CreateDirectory(strLibDirectory);
#endif


	HOBAInitParam param;
	param.pszBaseDir = szCurrentDirectory;
	param.pszDocumentDir = szDocumentDir;
	param.pszLibraryDir = strLibDirectory;
	param.pszTemporaryDir = (const char*)strTempDirectory;

	g_pAFramework->Init(param);
}

HAPI void HOBA_Release()
{
	g_pAFramework->Release();

	g_AUpdateFilePackMan.CloseAllPackages();
	g_AFilePackMan.CloseAllPackages();

#ifdef A_PLATFORM_WIN_DESKTOP
	AWinMiniDump::end();
#endif
}

HAPI void HOBA_GetMemStats(int* peakMemKB, int* curMemKB)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	globalDbg.getMemoryStats(peakMemKB, curMemKB);
#else
	*peakMemKB = 0;
	*curMemKB = 0;
#endif
}

HAPI void HOBA_DumpMemoryStats(const char* msg)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	globalDbg.dumpMemoryStates(msg);
#endif
}

/*
HAPI void HOBA_MemBeginCheckPoint()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	globalDbg.beginCheckPoint();
#endif
}

HAPI bool HOBA_MemEndCheckPoint()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return globalDbg.endCheckPoint();
#else
	return true;
#endif
}
*/

HAPI bool HOBA_InitPackages(const char* resBaseDir)
{
	const char* pszBaseDir = resBaseDir;

	bool bSepFile = true;

	char szPckFile[QMAX_PATH];
	for (size_t i = 0; i < sizeof(g_szPckDir) / sizeof(const char *) / 2; i++)
	{
		// open bundle first
		sprintf(szPckFile, "%s/%s.pck", pszBaseDir, g_szPckDir[i][1]);
		if (!g_AFilePackMan.OpenFilePackageInGame(szPckFile, g_szPckDir[i][0]) && !bSepFile)
		{
			g_pAFramework->DevPrintf("HOBA_InitPackages : Failed to initialize package %s!", szPckFile);

			//ASys::AndriodFileClean(pszBaseDir, false);
			//ASys::MessageBox(("Load game data package fail!"), "error", AMessageStyle_OK);

			return false;
		}

		// then open library
		if (*af_GetLibraryDir() != '\0')
		{
			sprintf(szPckFile, "%s/%s.pck", af_GetLibraryDir(), g_szPckDir[i][1]);
			if (!g_AUpdateFilePackMan.OpenFilePackageInGame(szPckFile, g_szPckDir[i][0]) && !bSepFile)
			{
				g_pAFramework->DevPrintf("HOBA_InitPackages : Failed to initialize Update package %s!", szPckFile);
				//ASys::AndriodFileClean(pszBaseDir, true);
				//ASys::MessageBox(("Load game data package fail!"), "error", AMessageStyle_OK);

				return false;
			}
		}
	}

	g_pAFramework->DevPrintf("HOBA_InitPackages: FilePackages: %d, UpdateFilePackages: %d", g_AFilePackMan.GetNumPackages(), g_AUpdateFilePackMan.GetNumPackages());

	return true;
}

HAPI void HOBA_LogString(const char* strMsg)
{
	g_pAFramework->DevPrintfString(strMsg);
}

HAPI bool HOBA_DeleteFilesInDirectory(const char* strDir)
{
	AString str;
	str.Format("HOBA_DeleteFilesInDirectory: %s", (const char*)strDir);
	HOBA_LogString(str);

	AString strBaseDir = strDir;
	strBaseDir.NormalizeDirName();

	Q_iterateFiles(strBaseDir, 
		[](const char* filename)
		{
			AString str;
			str.Format("Deleting File: %s", filename);
			HOBA_LogString(str);

			ASys::ChangeFileAttributes(filename, S_IRWXU);
			ASys::DeleteFile(filename);
		}
	);

	return true;
}

HAPI bool HOBA_HasFilesInDirectory(const char* strDir)
{
	bool bHasFilesInDir = false;

	AString strBaseDir = strDir;
	strBaseDir.NormalizeDirName();

	Q_iterateFiles(strBaseDir, 
		[&bHasFilesInDir](const char* filename)
		{
			if (!bHasFilesInDir)
				bHasFilesInDir = ASys::GetFileSize(filename) > 0;
		});

	return bHasFilesInDir;
}

HAPI uint64_t HOBA_GetFreeDiskSpace()
{
	return (uint64_t)ASys::GetFreeDiskSpaceSize();
}

HAPI uint64_t HOBA_GetVirtualMemoryUsedSize()
{
	return (uint64_t)ASys::GetVirtualMemoryUsedSize();
}

HAPI uint64_t HOBA_GetPhysMemoryUsedSize()
{
	return (uint64_t)ASys::GetPhysMemoryUsedSize();
}

HAPI uint32_t HOBA_GetMilliSecond()
{
	return (uint32_t)ASys::GetMilliSecond();
}

HAPI uint64_t HOBA_GetMicroSecond()
{
	return (uint64_t)ASys::GetMicroSecond();
}

HAPI void HOBA_Tick()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	globalDbg.registerFrame(ASys::GetMilliSecond());
#endif
}

HAPI float HOBA_GetMPS()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return globalDbg.getMPS();
#else
	return 0.0f;
#endif
}

