#pragma once

#include "FilterDlg.h"

#include "elementpckdir.h"

typedef struct _AFPCK_OPTION
{
	char		szSrcFile[MAX_PATH];
	char		szPckFile[MAX_PATH];
	bool		bVerbose;
	bool		bUseCompress;
} AFPCK_OPTION;

extern CFilterDlg g_filgerDlg;

extern DWORD g_dwTotalFileSize;
extern char	g_szDestPath[MAX_PATH];
extern char	g_szPckPath[MAX_PATH];
extern bool	g_bNoToAll;
extern bool	g_bYesToAll;
extern bool	g_bCopyYesToAll;
extern bool	g_bCopyNoToAll;

extern const char * g_szForbidFiles[3];

void Show_Version();

bool WINAPI IsPathIgnored(const CString filepath, const CString filename, bool bDir);

bool HasBasePath(const char * path1, const char * path2);

bool IsForbidFile(const char * szFileName);

bool HasInvalidChar(const char * szFileName);

bool IsInSepFileList(const char * szFileName);

//void SafeCreateDir(const char* szDir);

void MakeDir(const char * szDir);

//´ò°ü
bool PackInDir(const char * pszPath, const char * pszDestPath, AFPCK_OPTION * pOption, AFilePackage * pPackage);

bool CopyDir(const char * pszPath, const char * pszOption);