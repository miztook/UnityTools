#include "AFI.h"
#include "ALog.h"
#include "ASys.h"
#include "AFilePackMan.h"

char	g_szBaseDir[QMAX_PATH] = "";
// the ios device used this DocumentDir write files by linzihan
char    g_szDocumentDir[QMAX_PATH] = "";
char    g_szLibraryDir[QMAX_PATH] = "";

char    g_szTempDir[QMAX_PATH] = "";

inline void af_RemoveLastDirSlash(char* pszDir)
{
	// Get rid of last '\\'
	const int nLength = (int)strlen(pszDir);
	if (pszDir[0] && (pszDir[nLength - 1] == '\\' || pszDir[nLength - 1] == '/'))
		pszDir[nLength - 1] = '\0';
}

bool af_Initialize(const char* pszBaseDir, const char* pszDocumentDir, const char* pszLibraryDir, const char* pszTempDir)
{
	strncpy(g_szBaseDir, pszBaseDir, QMAX_PATH);
	af_RemoveLastDirSlash(g_szBaseDir);

	strncpy(g_szDocumentDir, pszDocumentDir, QMAX_PATH);
	af_RemoveLastDirSlash(g_szDocumentDir);

	strncpy(g_szLibraryDir, pszLibraryDir, QMAX_PATH);
	af_RemoveLastDirSlash(g_szLibraryDir);

	strncpy(g_szTempDir, pszTempDir, QMAX_PATH);
	af_RemoveLastDirSlash(g_szTempDir);

	return true;
}

void af_SetBaseDir(const char* pszBaseDir)
{
	strncpy(g_szBaseDir, pszBaseDir, QMAX_PATH);
	af_RemoveLastDirSlash(g_szBaseDir);
}

const char* af_GetBaseDir()
{
	return g_szBaseDir;
}

const char* af_GetDocumentDir()
{
	return g_szDocumentDir;
}

const char* af_GetLibraryDir()
{
	return g_szLibraryDir;
}

const char* af_GetTempDir()
{
	return g_szTempDir;
}

bool af_Finalize()
{
	g_szBaseDir[0] = 0;
	g_szDocumentDir[0] = 0;
	g_szLibraryDir[0] = 0;
	g_szTempDir[0] = 0;
	return true;
}

void af_GetRelativePathNoBase(const char* szFullpath, const char* szParentPath, char* szRelativepath)
{
	const char* p1 = szParentPath;
	const char* p2 = szFullpath;

	while (*p1 && *p2 && // Not null
		(
		(*p1 == *p2) || // Character is identical
		(*p1 >= 'A' && *p1 <= 'Z' && *p1 + 0x20 == *p2) || (*p2 >= 'A' && *p2 <= 'Z' && *p1 == *p2 + 0x20) || // Compare English character without regard to case.
		(*p1 == '\\' && (*p2 == '/' || *p2 == '\\')) || (*p1 == '/' && (*p2 == '/' || *p2 == '\\'))		// Both are / or \;
		)
		)
	{
		++p1;
		++p2;
	}

	if (*p1) // not found;
	{
		strcpy(szRelativepath, szFullpath);
		return;
	}

	if ((*p2 == '\\') || (*p2 == '/'))
		p2++;

	strcpy(szRelativepath, p2);
}

void af_GetRelativePathNoBase(const char* szFullpath, const char* szParentPath, AString& strRelativePath)
{
	char szRelativePath[QMAX_PATH];
	af_GetRelativePathNoBase(szFullpath, szParentPath, szRelativePath);
	strRelativePath = szRelativePath;
}

void af_GetFullPathNoBase(char* szFullpath, const char* szBaseDir, const char* szFilename)
{
	szFullpath[0] = '\0';

	int nStrLenName = (int)strlen(szFilename);
	if (nStrLenName == 0)
		return;

	//See if it is a absolute path;
#ifdef  A_PLATFORM_WIN_DESKTOP
	if (nStrLenName > 3)
	{
		if ((szFilename[1] == ':' && (szFilename[2] == '\\' || szFilename[2] == '/')) || (szFilename[0] == '\\' && szFilename[1] == '\\'))
		{
			strcpy(szFullpath, szFilename);
			return;
		}
	}
#else
	if (nStrLenName > 1)
	{
		if (szFilename[0] == '\\' || szFilename[0] == '/')
		{
			strcpy(szFullpath, szFilename);
			return;
		}
	}
#endif

	const char* pszRealfile = szFilename;
	// Get rid of prefix .\, so to make a clean relative file path
	if (nStrLenName > 2 && szFilename[0] == '.' && (szFilename[1] == '\\' || szFilename[1] == '/'))
		pszRealfile = szFilename + 2;

	if (szBaseDir[0] == '\0')
		strcpy(szFullpath, pszRealfile);
	else if ((szBaseDir[strlen(szBaseDir) - 1] == '\\') || (szBaseDir[strlen(szBaseDir) - 1] == '/'))
		sprintf(szFullpath, "%s%s", szBaseDir, pszRealfile);
	else
		sprintf(szFullpath, "%s/%s", szBaseDir, pszRealfile);
	return;
}

void af_GetFullPathNoBase(AString& strFullpath, const char* szBaseDir, const char* szFilename)
{
	char szFullPath[QMAX_PATH];
	af_GetFullPathNoBase(szFullPath, szBaseDir, szFilename);
	strFullpath = szFullPath;
}

void af_GetFullPath(char* szFullPath, const char* szFolderName, const char* szFileName)
{
	char szBaseDir[QMAX_PATH];
	sprintf(szBaseDir, "%s/%s", g_szBaseDir, szFolderName);
	af_GetFullPathNoBase(szFullPath, szBaseDir, szFileName);
}

void af_GetFullPath(char* szFullPath, const char* szFileName)
{
	af_GetFullPathNoBase(szFullPath, g_szBaseDir, szFileName);
}

void af_GetFullPath(AString& strFullPath, const char* szFolderName, const char* szFileName)
{
	char szBaseDir[QMAX_PATH];
	sprintf(szBaseDir, "%s/%s", g_szBaseDir, szFolderName);
	af_GetFullPathNoBase(strFullPath, szBaseDir, szFileName);
}

void af_GetFullPath(AString& strFullPath, const char* szFileName)
{
	af_GetFullPathNoBase(strFullPath, g_szBaseDir, szFileName);
}

void af_GetFullPathWithUpdate(AString& strFullPath, const char* szFileName, bool bNoCheckFileExist)
{
	AString strfilename = szFileName;
	strfilename.NormalizeFileName();
	if (*g_szLibraryDir != '\0')
	{
		af_GetFullPathNoBase(strFullPath, g_szLibraryDir, (const char*)strfilename);
		if (bNoCheckFileExist)
			return;
		if (ASys::IsFileExist(strFullPath))
			return;
	}
	af_GetFullPathNoBase(strFullPath, g_szBaseDir, (const char*)strfilename);
}

void af_GetFullPathWithDocument(AString& strFullPath, const char* szFileName, bool bNoCheckFileExist)
{
	AString strfilename = szFileName;
	strfilename.NormalizeFileName();
	if (*g_szDocumentDir != '\0')
	{
		af_GetFullPathNoBase(strFullPath, g_szDocumentDir, (const char*)strfilename);
		if (bNoCheckFileExist)
			return;
		if (ASys::IsFileExist(strFullPath))
			return;
	}
	af_GetFullPathNoBase(strFullPath, g_szBaseDir, (const char*)strfilename);
}

void af_GetRelativePath(const char* szFullPath, const char* szFolderName, char* szRelativePath)
{
	char szBaseDir[QMAX_PATH];
	sprintf(szBaseDir, "%s/%s", g_szBaseDir, szFolderName);
	af_GetRelativePathNoBase(szFullPath, szBaseDir, szRelativePath);
}

void af_GetRelativePath(const char* szFullPath, char* szRelativePath)
{
	af_GetRelativePathNoBase(szFullPath, g_szBaseDir, szRelativePath);
}

void af_GetRelativePath(const char* szFullPath, const char* szFolderName, AString& strRelativePath)
{
	char szBaseDir[QMAX_PATH];
	sprintf(szBaseDir, "%s/%s", g_szBaseDir, szFolderName);
	af_GetRelativePathNoBase(szFullPath, szBaseDir, strRelativePath);
}

void af_GetRelativePath(const char* szFullPath, AString& strRelativePath)
{
	af_GetRelativePathNoBase(szFullPath, g_szBaseDir, strRelativePath);
}

bool af_GetFileTitle(const char* lpszFile, char* lpszTitle, unsigned short cbBuf)
{
	if (!lpszFile || !lpszTitle)
		return false;

	lpszTitle[0] = '\0';
	if (lpszFile[0] == '\0')
		return true;

	const char* pszTemp = lpszFile + strlen(lpszFile);

	--pszTemp;
	if ('\\' == (*pszTemp) || '/' == (*pszTemp)) return false;
	while (true) {
		if ('\\' == (*pszTemp) || '/' == (*pszTemp))
		{
			++pszTemp;
			break;
		}
		if (pszTemp == lpszFile) break;
		--pszTemp;
	}
	strcpy(lpszTitle, pszTemp);
	return true;
}

bool af_GetFileTitle(const char* lpszFile, AString& strTitle)
{
	char szTitle[QMAX_PATH];
	bool bRet = af_GetFileTitle(lpszFile, szTitle, QMAX_PATH);
	if (bRet)
		strTitle = szTitle;

	return bRet;
}

bool af_GetFilePath(const char* lpszFile, char* lpszPath, unsigned short cbBuf)
{
	if (!lpszFile || !lpszPath)
		return false;

	lpszPath[0] = '\0';
	if (lpszFile[0] == '\0')
		return true;

	strncpy(lpszPath, lpszFile, cbBuf);
	char* pszTemp = (char *)lpszPath + strlen(lpszPath);

	--pszTemp;
	while (true) {
		if ('\\' == (*pszTemp) || '/' == (*pszTemp))
		{
			break;
		}
		if (pszTemp == lpszPath) break;
		--pszTemp;
	}
	*pszTemp = '\0';
	return true;
}

bool af_GetFilePath(const char* lpszFile, AString& strPath)
{
	char szPath[QMAX_PATH];
	bool bRet = af_GetFilePath(lpszFile, szPath, QMAX_PATH);
	if (bRet)
		strPath = szPath;

	return bRet;
}

//	Check file extension
bool af_CheckFileExt(const char* szFileName, const char* szExt, int iExtLen/* -1 */, int iFileNameLen/* -1 */)
{
	ASSERT(szFileName && szExt);

	if (iFileNameLen < 0)
		iFileNameLen = (int)strlen(szFileName);

	if (iExtLen < 0)
		iExtLen = (int)strlen(szExt);

	const char* p1 = szFileName + iFileNameLen - 1;
	const char* p2 = szExt + iExtLen - 1;

	bool bMatch = true;

	while (p2 >= szExt && p1 >= szFileName)
	{
		if (*p1 != *p2 && !(*p1 >= 'A' && *p1 <= 'Z' && *p2 == *p1 + 32) &&
			!(*p1 >= 'a' && *p1 <= 'z' && *p2 == *p1 - 32))
		{
			bMatch = false;
			break;
		}

		p1--;
		p2--;
	}

	return bMatch;
}

//	Change file extension
bool af_ChangeFileExt(char* szFileNameBuf, int iBufLen, const char* szNewExt)
{
	char szFile[QMAX_PATH];
	strcpy(szFile, szFileNameBuf);

	char* pTemp = strrchr(szFile, '.');
	if (pTemp)
		strcpy(pTemp, szNewExt);
	else
		strcat(szFile, szNewExt);

	int iLen = strlen(szFile);
	if (iLen >= iBufLen)
	{
		ASSERT(iLen < iBufLen);
		return false;
	}

	strcpy(szFileNameBuf, szFile);
	return true;
}

bool af_ChangeFileExt(AString& strFileName, const char* szNewExt)
{
	char szFile[QMAX_PATH];
	strcpy(szFile, strFileName);

	char* pTemp = strrchr(szFile, '.');
	if (pTemp)
		strcpy(pTemp, szNewExt);
	else
		strcat(szFile, szNewExt);

	strFileName = szFile;
	return true;
}

// Check if a specified file exist,	gb2312 encode
bool af_IsFileExist(const char * szFileName)
{
	char	szRelativePath[QMAX_PATH];
	af_GetRelativePath(szFileName, szRelativePath);

	AFilePackBase *pPackage = g_AUpdateFilePackMan.GetFilePck(szRelativePath);
	if (pPackage && pPackage->IsFileExist(szRelativePath))
		return true;

	// we must supply a relative path to GetFilePck function
	pPackage = g_AFilePackMan.GetFilePck(szRelativePath);
	if (pPackage && pPackage->IsFileExist(szRelativePath))
		return true;

	// not found in package, so test if exist on the disk, here we must use full path
	char	szFullPath[QMAX_PATH];

	AString filename = szRelativePath;
	filename.NormalizeFileName();
	const char* filestr = (const char*)filename;
	if (*af_GetLibraryDir() != '\0')
	{
		af_GetFullPathNoBase(szFullPath, af_GetLibraryDir(), filestr);
		if (ASys::IsFileExist(szFullPath))
			return true;
	}

	af_GetFullPathNoBase(szFullPath, af_GetBaseDir(), filestr);
	if (ASys::IsFileExist(szFullPath))
		return true;

	return false;
}

void af_RemoveExtName(AString& strFileName)
{
	int iPos = strFileName.ReverseFind('.');
	if (iPos >= 0)
	{
		strFileName = strFileName.Left(iPos);
	}
}

bool af_ContainFilePath(const char* szFileName)
{
	return strchr(szFileName, '\\') || strchr(szFileName, '/');
}