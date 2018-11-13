#include "ASys.h"

#include "compileconfig.h"

#ifdef A_PLATFORM_WIN_DESKTOP

#include <io.h>
#include <ShellAPI.h>
#include <psapi.h>

bool ASys::GetDocumentsDirectory(char* szDocumentDir, int nSize)
{
	if (0 == GetCurrentDirectoryA(nSize, szDocumentDir))
		return false;

	return true;
}


bool ASys::GetLibraryDirectory(char* szLibraryDir, int nSize)
{
	char libDir[1024];
	if (0 == GetCurrentDirectoryA(1024, libDir))
		return false;

	strcat(libDir, "/Library/Caches/updateres");
	if (strlen(libDir) + 1 > nSize)
		return false;

	strcpy(szLibraryDir, libDir);
	return true;
}

bool ASys::GetTmpDirectory(char* szTmpDir, int nSize)
{
	char tmpDir[1024];
	if (0 == GetCurrentDirectoryA(1024, tmpDir))
		return false;

	strcat(tmpDir, "/tmp");
	if (strlen(tmpDir) + 1 > nSize)
		return false;

	strcpy(szTmpDir, tmpDir);
	return true;
}


bool ASys::GetFilesInDirectory(std::vector<AString>& arrFiles, const char* szDir)
{
	//FIXME!! 传入的是UTF8，应该转换为wchar_t
	arrFiles.clear();
	AString strPartResult;
	if(szDir == NULL || szDir[0] == 0)
		szDir = ".";
	//if(szSearch == NULL || szSearch[0] == 0)
	const char*	szSearch = "*";
	char szSearchFinal[MAX_PATH];
	strcpy(szSearchFinal, szDir);
	if (szSearchFinal[strlen(szSearchFinal) - 1] != '/' && szSearchFinal[strlen(szSearchFinal) - 1] != '\\')
		strcat(szSearchFinal, "/");
	strcat(szSearchFinal, szSearch);

	WIN32_FIND_DATAA dataFile;
	HANDLE hSearch = ::FindFirstFileA(szSearchFinal, &dataFile);
	if(hSearch != NULL)
	{
		do 
		{
			if(strcmp(dataFile.cFileName, ".") == 0)
				continue;
			if(strcmp(dataFile.cFileName, "..") == 0)
				continue;
			if(dataFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			{ // Dir.
			}
			else
			{ // File.
				strPartResult = dataFile.cFileName;
				arrFiles.push_back(strPartResult);
			}
		} while (::FindNextFileA(hSearch, &dataFile));
		::FindClose(hSearch);
		return arrFiles.size() > 0;
	}
	return false;
}

bool ASys::DeleteDirectory(const char* szDir)
{
	if (!ASys::IsFileExist(szDir))
		return true;
	// This is a complex op.
	char szSearchFinal[MAX_PATH];
	strcpy(szSearchFinal, szDir);
	strcat(szSearchFinal, "/*");
	WIN32_FIND_DATAA dataFile;
	HANDLE hSearch = ::FindFirstFileA(szSearchFinal, &dataFile);
	if (hSearch != NULL)
	{
		do
		{
			if (strcmp(dataFile.cFileName, ".") == 0)
				continue;
			if (strcmp(dataFile.cFileName, "..") == 0)
				continue;
			strcpy(szSearchFinal, szDir);
			strcat(szSearchFinal, "/");
			strcat(szSearchFinal, dataFile.cFileName);
			if (dataFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			{ // Dir.
				ASys::DeleteDirectory(szSearchFinal);
			}
			else
			{ // File.
				ASys::DeleteFile(szSearchFinal);
			}
		} while (::FindNextFileA(hSearch, &dataFile));
		::FindClose(hSearch);
		return ::RemoveDirectoryA(szDir) != FALSE;
	}
	return false;
}

auint64 ASys::GetFreeDiskSpaceSize()
{
	typedef BOOL (WINAPI *PGETDISKFREESPACEEX)(LPCSTR, PULARGE_INTEGER, PULARGE_INTEGER, PULARGE_INTEGER);
	aint64 i64FreeBytesToCaller, i64TotalBytes, i64FreeBytes;
	DWORD dwSectPerClust, dwBytesPerSect, dwFreeClusters, dwTotalClusters;
	PGETDISKFREESPACEEX pGetDiskFreeSpaceEx = (PGETDISKFREESPACEEX) GetProcAddress( GetModuleHandleA("kernel32.dll"), "GetDiskFreeSpaceExA");
	if (pGetDiskFreeSpaceEx)
	{
		BOOL fResult = pGetDiskFreeSpaceEx (NULL,
			(PULARGE_INTEGER)&i64FreeBytesToCaller,
			(PULARGE_INTEGER)&i64TotalBytes,
			(PULARGE_INTEGER)&i64FreeBytes);
		if(fResult) 
		{
			return i64FreeBytes;
		}
	}

	else 
	{
		BOOL fResult = GetDiskFreeSpaceA (NULL, 
			&dwSectPerClust, 
			&dwBytesPerSect,
			&dwFreeClusters, 
			&dwTotalClusters);
		// Process GetDiskFreeSpace results.
		if(fResult) 
		{
			return ((auint64)dwFreeClusters) * dwSectPerClust * dwBytesPerSect;
		}
	}
	return (auint64)0;
}

auint64 ASys::GetVirtualMemoryUsedSize()
{
	PROCESS_MEMORY_COUNTERS_EX pmc;
	GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc));
	SIZE_T virtualMemUsedByMe = pmc.PrivateUsage;
	return (auint64)virtualMemUsedByMe;
}

auint64 ASys::GetPhysMemoryUsedSize()
{
	PROCESS_MEMORY_COUNTERS_EX pmc;
	GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc));
	SIZE_T physMemUsedByMe = pmc.WorkingSetSize;
	return (auint64)physMemUsedByMe;
}

void ASys::OutputDebug(const char* format, ...)
{
	char str[4096];

	va_list va;
	va_start( va, format );
	vsprintf( str, format, va );
	va_end( va );

	strcat(str, "\n");

	//FIXME!! 传入的是UTF8，应该转换为wchar_t
	OutputDebugStringA(str);
}

#endif