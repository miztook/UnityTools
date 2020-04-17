#include "stdafx.h"
#include "Pack.h"
#include <io.h>

#define MAJOR_VERSION			1
#define MINOR_VERSION			1

CFilterDlg g_filgerDlg;

DWORD	g_dwTotalFileSize = 0;
char	g_szDestPath[MAX_PATH];
char	g_szPckPath[MAX_PATH];
bool	g_bNoToAll = false;
bool	g_bYesToAll = false;
bool	g_bCopyYesToAll = false;
bool	g_bCopyNoToAll = false;

extern bool g_bAutoPack;

const char * g_szForbidFiles[] =
{
	"thumbs.db",
	"Thumbs.db",
	".svn",
};

const char * g_szInvalidChar[] =
{
	" ",
	"　",
};

void Show_Version()
{
	printf("Element File Pack Tool - V%d.%d\n\n", MAJOR_VERSION, MINOR_VERSION);
}

bool WINAPI IsPathIgnored(const CString filepath, const CString filename, bool bDir)
{

	int i;

	char	szFilePath[MAX_PATH];
	char	szFileName[MAX_PATH];
	char	szRelativePath[MAX_PATH];

	af_GetRelativePath((const char*)filepath, szFilePath);
	af_GetRelativePath((const char*)filename, szFileName);

	strlwr(szFilePath);
	strlwr(szFileName);

	if( bDir )
	{
	}
	else
	{
		char szPath[MAX_PATH];
		af_GetFilePath(szFilePath, szPath, MAX_PATH);
		strcpy(szFilePath, szPath);
	}

	const int count = sizeof(g_szPckDir) / sizeof(const char *) / 2;

	if (g_bAutoPack)			//只显示lua,data
	{
		bool bIgnore = true;
		for (int i = 0; i < count; ++i)
		{
			bool hasPath = HasBasePath(szFilePath, g_szPckDir[i][0]) ||
				(bDir && HasBasePath(g_szPckDir[i][0], szFilePath));

			bIgnore &= (!hasPath);
		}

		if (bIgnore)
			return true;
	}

	for (i = 0; i<count; i++)
	{
		//if( HasBasePath(szFilePath, g_szPckDir[i][1]) )
		if( HasBasePath(szFilePath, g_szPckDir[i][0]) ||
			( bDir && HasBasePath(g_szPckDir[i][0], szFilePath)) )
			return false;
	}

	for (i = 0; i<count; i++)
	{
		if( bDir )
		{
			if( HasBasePath(szFilePath, g_szNoPckDir[i][0]) )
			{
				af_GetRelativePathNoBase(szFilePath, g_szNoPckDir[i][0], szRelativePath);
				if( strlen(szRelativePath) == 0 )
					return false;
				else
				{
					switch(g_szNoPckDir[i][1][0])
					{
					case 'r':
						return false;

					case 's':
						break;

					default:
						break;
					}
				}
			}
			else if( HasBasePath(g_szNoPckDir[i][0], szFilePath) )
			{
				return false;
			}
		}
		else
		{
			if( HasBasePath(szFilePath, g_szNoPckDir[i][0]) && !IsForbidFile(szFileName) && !HasInvalidChar(szFileName) )
			{
				af_GetRelativePathNoBase(szFilePath, g_szNoPckDir[i][0], szRelativePath);
				switch(g_szNoPckDir[i][1][0])
				{
				case 'r':
					return false;

				case 's':
					if( strlen(szRelativePath) == 0 && IsInSepFileList(szFileName) )
						return  false;
					break;

				default:
					if( strlen(szRelativePath) == 0 )
						return  false;
					break;
				}
			}
		}
	}

	return true;
}

bool HasBasePath(const char * path1, const char * path2)
{
	char szPath1[MAX_PATH];
	char szPath2[MAX_PATH];

	strcpy(szPath1, path1);
	strcpy(szPath2, path2);

	strlwr(szPath1);
	strlwr(szPath2);

	if( strlen(szPath2) == 0 )
		return false;

	if( strcmp(szPath2, ".") == 0 )
		return true;

	if( strlen(szPath1) && szPath1[strlen(szPath1) - 1] != '\\' )
		strcat(szPath1, "\\");
	if( strlen(szPath2) && szPath2[strlen(szPath2) - 1] != '\\' )
		strcat(szPath2, "\\");

	if( strstr(szPath1, szPath2) == szPath1 )
		return true;

	return false;
}

bool IsForbidFile(const char * szFileName)
{
	for(int i=0; i<sizeof(g_szForbidFiles) / sizeof(const char *); i++)
	{
		const char * szForbid = g_szForbidFiles[i];
		const char * pszFound = strstr(szFileName, g_szForbidFiles[i]);
		if( pszFound && pszFound + strlen(szForbid) == szFileName + strlen(szFileName) )
			return true;
	}

	return false;
}

bool HasInvalidChar(const char * szFileName)
{
	for(int i=0; i<sizeof(g_szInvalidChar) / sizeof(const char *); i++)
	{
		const char * szInvalidChar = g_szInvalidChar[i];
		const char * pszFound = strstr(szFileName, g_szInvalidChar[i]);
		if( pszFound )
			return true;
	}

	return false;
}

bool IsInSepFileList(const char * szFileName)
{
	for(int i=0; i<sizeof(g_szSepFiles) / sizeof(const char *); i++)
	{
		if( stricmp(szFileName, g_szSepFiles[i]) == 0 )
			return true;
	}
	return false;
}

void MakeDir(const char* dir, int r)
{
	r--;
	while (r > 0 && dir[r] != '/'&&dir[r] != '\\')
		r--;
	if (r == 0)
		return;
	MakeDir(dir, r);
	char t[400];
	strcpy(t, dir);
	t[r] = '\0';
	ASys::CreateDirectory(t);
}

void MakeDir(const char* dir)
{
	MakeDir(dir, int(strlen(dir)));
}

/*
void SafeCreateDir(const char* szDir)
{
	if( _access(szDir, 0) == -1 )
	{
		MakeDir(szDir);
	}
}


int Createdir(const char * szDir)
{
	int     nlen;
	char    full_path[MAX_PATH + 1];
	char    *p_path_to_make;
	char    *pch;

	full_path[MAX_PATH] = '\0';
	pch = p_path_to_make = NULL;
	strncpy(full_path, szDir, MAX_PATH);

	//get rid of the first and the last slash
	nlen = strlen(full_path);
	if(full_path[nlen - 1] == '\\')
		full_path[nlen - 1] = 0;

	pch = p_path_to_make = full_path;
	if(*pch == '\\') pch++;

	//begin mkdir
	while(pch)
	{
		pch = strstr(pch, "\\");
		if( pch )
			*pch = 0;
		if( _access(p_path_to_make, 0) == -1 )
		{
			if( !CreateDirectory(p_path_to_make, NULL) )
			{
				goto FAILURE;
			}
		}
		if( pch )
		{
			*pch = '\\';
			pch++;
		}
	}
	return 0;

FAILURE:
	return -1;
}
*/



bool PackInDir(const char * pszPath, const char * pszDestPath, AFPCK_OPTION * pOption, AFilePackage * pPackage)
{
	char		szSrcFile[MAX_PATH];
	char		szPath[MAX_PATH];
	char		szDestPath[MAX_PATH];

	strcpy(szPath, pszPath);

	if( szPath[0] && szPath[strlen(szPath) - 1] != '\\' )
	{
		strcat(szPath, "\\");
	}

	strcpy(szDestPath, pszDestPath);

	if( szDestPath[0] && szDestPath[strlen(szDestPath) - 1] != '\\' )
	{
		strcat(szDestPath, "\\");
	}

	sprintf(szSrcFile, "%s%s", szPath, pOption->szSrcFile);

	WIN32_FIND_DATA fd;
	// We have to find the source file here;
	HANDLE hFind = FindFirstFile(szSrcFile, &fd);
	if( INVALID_HANDLE_VALUE == hFind )
		return true;

	do
	{
		char szFileName[MAX_PATH];
		//char szDestFileFolder[MAX_PATH];
		char szDestFileName[MAX_PATH];

		sprintf(szFileName, "%s%s", szPath, fd.cFileName);
		strlwr(szFileName);
		sprintf(szDestFileName, "%s%s", szDestPath, fd.cFileName);
		strlwr(szDestFileName);

		if( fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY )
		{
			if( 0 == stricmp(fd.cFileName, ".") ||
				0 == stricmp(fd.cFileName, "..") )
				continue;

			if( IsForbidFile(szFileName) )
				continue;

			AFPCK_OPTION newOption = *pOption;
			strcpy(newOption.szSrcFile, "*.*");
			PackInDir(szFileName, szDestFileName, &newOption, pPackage);
			continue;
		}
		else
		{
			if( 0 == stricmp(szFileName, pOption->szPckFile) )
				continue;
			if( IsForbidFile(szFileName) )
				continue;

			if( g_filgerDlg.IsFiltered(szFileName) )
				continue;

			printf("Packing %s......", szFileName);
			if( HasInvalidChar(szFileName) )
			{
				printf("failed! invalid char encounter!\n");
				g_pAFramework->DevPrintf("文件[%s]中含有非法字符（空格）!", szFileName);
				continue;
			}

			FILE * file = fopen(szFileName, "rb");
			if( NULL == file )
			{
				printf("Error Open");
				continue;
			}
			fseek(file, 0, SEEK_END);
			auint32 dwFileSize = ftell(file);
			auint32 dwCompressedSize = (auint32)(dwFileSize * 1.1f) + 12;		//zlib compress2 要求
			LPBYTE pFileContent = (LPBYTE) malloc(dwFileSize);
			if( NULL == pFileContent )
			{
				printf("Not enough memory!\n\n");
				FindClose(hFind);
				return false;
			}
			LPBYTE pFileCompressed = (LPBYTE) malloc(dwCompressedSize);
			if( NULL == pFileCompressed )
			{
				printf("Not enough memory!\n\n");
				free(pFileContent);
				FindClose(hFind);
				return false;
			}

			fseek(file, 0, SEEK_SET);
			fread(pFileContent, dwFileSize, 1, file);
			fclose(file);

			int nRet = AFilePackage::Compress(pFileContent, dwFileSize, pFileCompressed, &dwCompressedSize);
			if( 0 != nRet )
			{
				dwCompressedSize = dwFileSize;
			}
			if ( -2 == nRet)			//error
			{
				AString str;
				str.Format("AFilePackage::Compress Error!, %s", szFileName);
				MessageBoxA(NULL, str, "Compress Error", 0);
			}

			if( dwCompressedSize < dwFileSize )
			{
				if( !pPackage->AppendFileCompressed(szFileName, pFileCompressed, dwFileSize, dwCompressedSize) )
				{
					FindClose(hFind);
					free(pFileCompressed);
					free(pFileContent);
					return false;
				}

			}
			else
			{
				if( !pPackage->AppendFileCompressed(szFileName, pFileContent, dwFileSize, dwFileSize) )
				{
					FindClose(hFind);
					free(pFileCompressed);
					free(pFileContent);
					return false;
				}

			}

			if( g_szDestPath[0] )
			{
// 				af_GetFilePath(szDestFileName, szDestFileFolder, MAX_PATH);
// 				AString strDir = szDestFileFolder;
// 				strDir.NormalizeDirName();
				MakeDir(szDestFileName);
				file = fopen(szDestFileName, "wb");

				ASSERT(file);
				if( dwCompressedSize < dwFileSize )
				{
					fwrite(&dwFileSize, sizeof(DWORD), 1, file);
					DWORD dwNow = 0;
					while(dwNow < dwCompressedSize)
					{
						// 网络驱动器一次写入不能超过64MB
						DWORD dwWrite = min(dwCompressedSize - dwNow, 50000000);
						fwrite(pFileCompressed + dwNow, 1, dwWrite, file);
						dwNow += dwWrite;
					}
				}
				else
				{
					fwrite(&dwFileSize, sizeof(DWORD), 1, file);
					DWORD dwNow = 0;
					while(dwNow < dwFileSize)
					{
						// 网络驱动器一次写入不能超过64MB
						DWORD dwWrite = min(dwFileSize - dwNow, 50000000);
						fwrite(pFileContent + dwNow, 1, dwWrite, file);
						dwNow += dwWrite;
					}
				}
				fclose(file);
			}

			free(pFileContent);
			free(pFileCompressed);

			g_dwTotalFileSize += dwFileSize;
			printf("Done\n");
		}

	} while( FindNextFile(hFind, &fd) );

	FindClose(hFind);

	return true;
}

bool CopyDir(const char * pszPath, const char * pszOption)
{
	char		szSrcFile[MAX_PATH];
	char		szPath[MAX_PATH];

	strcpy(szPath, pszPath);

	if( szPath[0] && szPath[strlen(szPath) - 1] != '\\' )
	{
		strcat(szPath, "\\");
	}

	sprintf(szSrcFile, "%s%s", szPath, "*.*");

	WIN32_FIND_DATA fd;
	// We have to find the source file here;
	HANDLE hFind = FindFirstFile(szSrcFile, &fd);
	if( INVALID_HANDLE_VALUE == hFind )
		return true;

	do
	{
		char szFileName[MAX_PATH];
		//char szDestFileFolder[MAX_PATH];
		char szDestFileName[MAX_PATH];

		sprintf(szFileName, "%s%s", szPath, fd.cFileName);
		strlwr(szFileName);

		if( fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY )
		{
			if( 0 == stricmp(fd.cFileName, ".") ||
				0 == stricmp(fd.cFileName, "..") )
				continue;

			if( stricmp(pszOption, "r") == 0 )
			{
				CopyDir(szFileName, pszOption);
			}
			continue;
		}
		else
		{
			if( stricmp(pszOption, "s") == 0 )
			{
				// test if the file in sep files list
				if( !IsInSepFileList(fd.cFileName) )
					continue;
			}
			if( IsForbidFile(szFileName) )
				continue;

			if( g_filgerDlg.IsFiltered(szFileName) )
				continue;

			printf("Copying %s......", szFileName);
			if( HasInvalidChar(szFileName) )
			{
				printf("failed! invalid char encounter!\n");
				g_pAFramework->DevPrintf("文件[%s]中含有非法字符（空格）!", szFileName);
				continue;
			}

			FILE * file = fopen(szFileName, "rb");
			if( NULL == file )
			{
				printf("Error Open");
				continue;
			}
			fseek(file, 0, SEEK_END);
			DWORD dwFileSize = ftell(file);
			LPBYTE pFileContent = (LPBYTE) malloc(dwFileSize);
			if( NULL == pFileContent )
			{
				printf("Not enough memory!\n\n");
				return false;
			}

			fseek(file, 0, SEEK_SET);
			fread(pFileContent, dwFileSize, 1, file);
			fclose(file);

			if( g_szPckPath[0] )
			{
				sprintf(szDestFileName, "%s%s", g_szPckPath, szFileName);
// 				af_GetFilePath(szDestFileName, szDestFileFolder, MAX_PATH);
// 
// 				AString strDir = szDestFileFolder;
// 				strDir.NormalizeDirName();
// 				SafeCreateDir(strDir);
				
				MakeDir(szDestFileName);
				file = fopen(szDestFileName, "wb");
				ASSERT(file);

				fwrite(pFileContent, 1, dwFileSize, file);

				fclose(file);
			}

			if( g_szDestPath[0] )
			{
				sprintf(szDestFileName, "%s%s", g_szDestPath, szFileName);
// 				af_GetFilePath(szDestFileName, szDestFileFolder, MAX_PATH);
// 
// 				AString strDir = szDestFileFolder;
// 				strDir.NormalizeDirName();
// 				SafeCreateDir(strDir);
				
				MakeDir(szDestFileName);
				file = fopen(szDestFileName, "wb");
				ASSERT(file);

				// we comopress all files for release
				auint32 dwCompressedSize = dwFileSize;
				LPBYTE pFileCompressed = (LPBYTE) malloc(dwCompressedSize);
				if( NULL == pFileCompressed )
				{
					printf("Not enough memory!\n\n");
					return false;
				}

				if( 0 != AFilePackage::Compress(pFileContent, dwFileSize, pFileCompressed, &dwCompressedSize) )
				{
					dwCompressedSize = dwFileSize;
				}

				if( dwCompressedSize < dwFileSize )
				{
					fwrite(&dwFileSize, 1, sizeof(DWORD), file);
					DWORD dwNow = 0;
					while(dwNow < dwCompressedSize)
					{
						// 网络驱动器一次写入不能超过64MB
						DWORD dwWrite = min(dwCompressedSize - dwNow, 50000000);
						fwrite(pFileCompressed + dwNow, 1, dwWrite, file);
						dwNow += dwWrite;
					}
				}
				else
				{
					fwrite(&dwFileSize, 1, sizeof(DWORD), file);
					DWORD dwNow = 0;
					while(dwNow < dwFileSize)
					{
						// 网络驱动器一次写入不能超过64MB
						DWORD dwWrite = min(dwFileSize - dwNow, 50000000);
						fwrite(pFileContent + dwNow, 1, dwWrite, file);
						dwNow += dwWrite;
					}
				}
				free(pFileCompressed);

				fclose(file);
			}

			free(pFileContent);

			g_dwTotalFileSize += dwFileSize;
			printf("Done\n");
		}

	} while( FindNextFile(hFind, &fd) );

	FindClose(hFind);
	return true;
}
