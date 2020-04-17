// ElementUIPck.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "Pack.h"

CWinApp theApp;

bool Init();

void Release();

extern bool g_bAutoPack = false;

int main(int argc, _TCHAR* argv[])
{
	int nRet = 0;

#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif

	if( argc < 3 )
	{
		printf("usage: elementpck.exe [destdir] [pckdir] [autopack]\n");
		return 0;
	}

	if (argc == 4)
	{
		g_bAutoPack = atoi(argv[3]) != 0;
	}

	if (!Init())
	{
		return 1;
	}

	g_szDestPath[0] = '\0';
	g_szPckPath[0] = '\0';

	strncpy(g_szDestPath, argv[1], MAX_PATH);
	if( g_szDestPath[0] && g_szDestPath[strlen(g_szDestPath) - 1] != '\\' )
		strcat(g_szDestPath, "\\");
	strlwr(g_szDestPath);

	strncpy(g_szPckPath, argv[2], MAX_PATH);
	if( g_szPckPath[0] && g_szPckPath[strlen(g_szPckPath) - 1] != '\\' )
		strcat(g_szPckPath, "\\");
	strlwr(g_szPckPath);

	g_bYesToAll	= false;
	g_bNoToAll = false;

	Show_Version();

	AString strWorkDir = af_GetBaseDir();
	if( strWorkDir[strWorkDir.GetLength() - 1] != '\\' )
		strWorkDir += "\\";
	
	g_filgerDlg.Init(strWorkDir, IsPathIgnored);

	if( IDOK != g_filgerDlg.DoModal() )
	{
		printf("You have canceled the operation!\n");
		nRet = 0;
		goto End;
	}

	// restore current directory, because filter dlg will change current directory.
	SetCurrentDirectory(strWorkDir);

	AFPCK_OPTION option;

	for(int i=0; i<sizeof(g_szPckDir)/ sizeof(const char*)/2; i++)
	{
		sprintf(option.szPckFile, "%s.pck", g_szPckDir[i][1]);
		strcpy(option.szSrcFile, "*.*");
		option.bVerbose = true;
		option.bUseCompress = true;

		char szPckFile[MAX_PATH];
		sprintf(szPckFile, "%s%s", g_szPckPath, option.szPckFile);

// 		char szPckFilePath[MAX_PATH];
// 		af_GetFilePath(szPckFile, szPckFilePath, MAX_PATH);
// 		SafeCreateDir(szPckFilePath);

		MakeDir(szPckFile);

		g_dwTotalFileSize = 0;

		printf("----Creating [%s]----\n", option.szPckFile);
		// First we should create the package file;
		AFilePackage pckFile;

		if( !pckFile.Open(szPckFile, g_szPckDir[i][0], AFilePackage::CREATENEW) )
		{
			printf("Can not create %s\n\n", option.szPckFile);
			nRet = -1;
			goto End;
		}

		char szDestPckDir[MAX_PATH];
		sprintf(szDestPckDir, "%s%s", g_szDestPath, g_szPckDir[i][1]);
		PackInDir(g_szPckDir[i][0], szDestPckDir, &option, &pckFile);

		if( option.bUseCompress )
			printf("\n\nTotal %d files, %d bytes after compressed, with ratio %5.2f%%\n", pckFile.GetFileNumber(), pckFile.GetFileHeader().dwEntryOffset, 100.0f - pckFile.GetFileHeader().dwEntryOffset * 100.0f / g_dwTotalFileSize);
		else
			printf("\n\nTotal %d files, %d bytes\n", pckFile.GetFileNumber(), pckFile.GetFileHeader().dwEntryOffset);

		// Last we close and save the package file.
		pckFile.Close();

		// Succeed!
		printf("----Finished pack [%s]!----\n\n", option.szPckFile);
	}

	printf("now copy unpacked files\n");
	for(int i=0; i<sizeof(g_szNoPckDir) / sizeof(const char *) / 2; i++)
	{
		printf("----Copy dir [%s]----\n", g_szNoPckDir[i][0]);
		// First we should create the package file;

		CopyDir(g_szNoPckDir[i][0], g_szNoPckDir[i][1]);

		// Succeed!
		printf("----Finish copy [%s]!----\n\n", g_szNoPckDir[i][0]);
	}

End:
	Release();

	if (g_bAutoPack)
		return nRet;

	//打开pck目录
	AString strDir = g_szPckPath;

	//shell要求反斜杠
	strDir.Replace('/', '\\');
	ShellExecuteA(
		NULL,
		"open",
		"Explorer.exe",
		strDir,
		NULL,
		SW_NORMAL);


	return nRet;
}

void HOBA_Init(const char* baseDir, const char* docDir);

void HOBA_Release(int* memKB);

bool Init()
{
	// initialize MFC and print and error on failure
	if (!AfxWinInit(::GetModuleHandle(NULL), NULL, ::GetCommandLine(), 0))
	{
		printf(_T("Fatal Error: MFC initialization failed"));
		return false;
	}

	char szCurrentDirectory[ MAX_PATH ];
	GetCurrentDirectoryA(MAX_PATH, szCurrentDirectory);

	HOBA_Init(szCurrentDirectory, szCurrentDirectory);

	return true;
}

void Release()
{
	int nMemKB = 0;
	HOBA_Release(&nMemKB);

	AfxWinTerm();
}

#ifdef A_PLATFORM_WIN_DESKTOP

#include "AWinMemDbg.h"
#include "AWinMiniDump.h"

AWinMemDbg globalDbg;

#endif

void HOBA_Init(const char* baseDir, const char* docDir)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	AWinMiniDump::begin();
	globalDbg.beginCheckPoint();
#endif

	char szCurrentDirectory[MAX_PATH];
	strcpy(szCurrentDirectory, baseDir);

	char szDocumentDir[MAX_PATH];
	strcpy(szDocumentDir, docDir);

	char strTempDirectory[MAX_PATH];
	strcpy(strTempDirectory, szCurrentDirectory);
	strcat(strTempDirectory, "/tmp");

	char strLibDirectory[MAX_PATH];
	strcpy(strLibDirectory, szCurrentDirectory);
	strcat(strLibDirectory, "/Library/Caches/updateres");

	HOBAInitParam param;
	param.pszBaseDir = szCurrentDirectory;
	param.pszDocumentDir = szDocumentDir;
	param.pszLibraryDir = strLibDirectory;
	param.pszTemporaryDir = (const char*)strTempDirectory;

	g_pAFramework->Init(param, false);
}

void HOBA_Release(int* memKB)
{
	g_pAFramework->Release();

#ifdef A_PLATFORM_WIN_DESKTOP
	bool safe = globalDbg.endCheckPoint();
	//ASSERT(safe);

	globalDbg.outputMaxMemoryUsed(memKB);
	AWinMiniDump::end();
#else
	*memKB = 0;
#endif
}