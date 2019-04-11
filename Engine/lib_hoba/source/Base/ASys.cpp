#include "ASys.h"
#include "AFI.h"

#ifdef A_PLATFORM_WIN_DESKTOP

#include <io.h>

#else

#include <cstdio>
#include <cstdlib>
#include <cerrno>
#include <cctype>
#include <pthread.h>
#include <cmath>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/time.h>

#endif

void ASys::AndriodFileClean(const char* szBaseDir, bool bCleanUpdate)
{
	if (!szBaseDir || !szBaseDir[0])
		return;

	if (bCleanUpdate)
	{
		ASys::DeleteDirectory(af_GetLibraryDir());
	}

	char buf[512];
	sprintf(buf, "%s/.lock", szBaseDir);
	ASys::DeleteFile(buf);
}

#ifndef A_PLATFORM_XOS

bool ASys::IOSGetCurLanguage(char* szLang, int nSize)
{
	strcpy(szLang, "");
	return false;
}

#endif

char* ASys::Strlwr(char* str)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _strlwr(str);
#else
	char* prt = str;
	while (*prt != '\0') {
		if (isupper(*prt))
		{
			*prt = tolower(*prt);
		}
		prt++;
	}
	return str;
#endif
}

char* ASys::Strupr(char* str)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _strupr(str);
#else
	char* prt = str;
	while (*prt != '\0') {
		if (islower(*prt))
		{
			*prt = toupper(*prt);
		}
		prt++;
	}
	return str;
#endif
}

int  ASys::Fileno(FILE * _File)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _fileno(_File);
#else
	return fileno(_File);
#endif
}

int ASys::AccessFile(const char* path, int mode)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _access(path, mode);
#else
	return access(path, mode);
#endif
}

int ASys::SetFileSize(int fd, aint32 size)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _chsize(fd, size);
#else
	return ftruncate(fd, size);
#endif
}

aint64 ASys::AtoInt64(const char * szString)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _atoi64(szString);
#else
	return atoll(szString);
#endif
}

int ASys::StrCmpNoCase(const char* sz1, const char * sz2)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return _stricmp(sz1, sz2);
#else
	return strcasecmp(sz1, sz2);
#endif
}

auint32 ASys::GetFileTimeStamp(const char* szFileName)
{
	//FIXME!! 传入的是UTF8，应该转换为wchar_t
	struct stat fileStat;
	stat(szFileName, &fileStat);
	return (auint32)(fileStat.st_mtime);
}

auint32 ASys::GetFileSize(const char* szFileName)
{
	struct stat fileStat;
	stat(szFileName, &fileStat);
	return (auint32)(fileStat.st_size);
}

auint32 ASys::ChangeFileAttributes(const char* szFileName, int mode)
{
	return chmod(szFileName, mode);
}

bool ASys::IsFileExist(const char* szFileName)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	if (INVALID_FILE_ATTRIBUTES != GetFileAttributesA(szFileName))
		return true;
	return false;
#else
	if (access(szFileName, 0) == 0)
		return true;
	return false;
#endif
}

bool ASys::DeleteFile(const char* szFile)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return ::DeleteFileA(szFile) != 0;
#else
	return remove(szFile) != -1;
#endif
}

bool ASys::CopyFile(const char* src, const char* des, bool bFailIfExists)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return ::CopyFileA(src, des, bFailIfExists) != 0;
#else
	const int BUF_SIZE = 1024;
	FILE* fromfd = NULL;
	FILE*  tofd = NULL;
	size_t bytes_read = 0;
	size_t bytes_write = 0;
	char buffer[BUF_SIZE];

	/*open source file*/
	if ((fromfd = fopen(src, "r")) == NULL)
	{
		//fprintf(stderr,"Open source file failed:%s\n",strerror(errno));
		return false;
	}
	/*create dest file*/
	if ((tofd = fopen(des, "wb")) == NULL)
	{
		//fprintf(stderr,"Create dest file failed:%s\n",strerror(errno));
		fclose(fromfd);
		return false;
	}

	/*copy file code*/
	while ((bytes_read = fread(buffer, 1, BUF_SIZE, fromfd)))
	{
		if (bytes_read == -1 && errno != EINTR)
			break; /*an important mistake occured*/
		else if (bytes_read == 0)
		{
			break;
		}
		else if (bytes_read > 0)
		{
			bytes_write = fwrite(buffer, 1, bytes_read, tofd);
			ASSERT(bytes_write == bytes_read);
		}
	}
	fclose(fromfd);
	fclose(tofd);
	return true;
#endif
}

bool ASys::MoveFile(const char* src, const char* des)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return ::MoveFileA(src, des) != 0;
#else
	if (!CopyFile(src, des, false))
		return false;
	if (!DeleteFile(src))
		return false;
	return  true;
#endif
}

bool ASys::CreateDirectory(const char* szDir)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return ::CreateDirectoryA(szDir, NULL) != FALSE;
#else
	return mkdir(szDir, S_IRWXU) != -1;
#endif
}

void ASys::Sleep(unsigned int nMilliSecond)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	::Sleep(nMilliSecond);
#else
	::usleep(nMilliSecond * 1000);
#endif
}

auint32 ASys::GetMilliSecond()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return (auint32)(GetMicroSecond() / 1000);
#else
	timeval tp;
	::gettimeofday(&tp, NULL);
	auint64 uiiTime = ((auint64)(tp.tv_sec) * 1000000 + tp.tv_usec) / 1000;
	return (auint32)uiiTime;
#endif
}

auint64 ASys::GetMicroSecond()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	static LARGE_INTEGER liFrequency;
	static bool bFirstTime = true;

	if (bFirstTime)
	{
		bFirstTime = false;
		::QueryPerformanceFrequency(&liFrequency);
	}

	LARGE_INTEGER liCounter;
	::QueryPerformanceCounter(&liCounter);

	auint64 uSecond = liCounter.QuadPart / liFrequency.QuadPart;
	auint64 uRemainder = liCounter.QuadPart % liFrequency.QuadPart;

	return uSecond * 1000000 + uRemainder * 1000000 / liFrequency.QuadPart;
#else
	timeval tp;
	::gettimeofday(&tp, NULL);
	return (auint64)(tp.tv_sec) * 1000000 + tp.tv_usec;
#endif
}

void ASys::GMTime(auint64 _time, ATIME& atm)
{
	time_t t = (time_t)_time;
	tm* ptm = ::gmtime(&t);

	atm.year = ptm->tm_year;
	atm.month = ptm->tm_mon;
	atm.day = ptm->tm_mday;
	atm.hour = ptm->tm_hour;
	atm.minute = ptm->tm_min;
	atm.second = ptm->tm_sec;
	atm.wday = ptm->tm_wday;
}

void ASys::LocalTime(auint64 _time, ATIME& atm)
{
	time_t t = (time_t)_time;
	tm* ptm = ::localtime(&t);

	atm.year = ptm->tm_year;
	atm.month = ptm->tm_mon;
	atm.day = ptm->tm_mday;
	atm.hour = ptm->tm_hour;
	atm.minute = ptm->tm_min;
	atm.second = ptm->tm_sec;
	atm.wday = ptm->tm_wday;
}

auint64 ASys::TimeLocal(const ATIME& atm)
{
	tm _tm;
	_tm.tm_year = atm.year;
	_tm.tm_mon = atm.month;
	_tm.tm_mday = atm.day;
	_tm.tm_hour = atm.hour;
	_tm.tm_min = atm.minute;
	_tm.tm_sec = atm.second;
	_tm.tm_isdst = 0;
	_tm.tm_wday = 0;
	_tm.tm_yday = 0;

	return (auint64)(::mktime(&_tm));
}

void ASys::GetCurGMTime(ATIME& atm, auint32* piMilliSec)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	SYSTEMTIME st;
	::GetSystemTime(&st);

	atm.year = st.wYear - 1900;
	atm.month = st.wMonth - 1;
	atm.day = st.wDay;
	atm.hour = st.wHour;
	atm.minute = st.wMinute;
	atm.second = st.wSecond;
	atm.wday = st.wDayOfWeek;

	if (piMilliSec)
		*piMilliSec = st.wMilliseconds;
#else
	time_t t = ::time(NULL);
	tm* ptm = ::gmtime(&t);

	atm.year = ptm->tm_year;
	atm.month = ptm->tm_mon;
	atm.day = ptm->tm_mday;
	atm.hour = ptm->tm_hour;
	atm.minute = ptm->tm_min;
	atm.second = ptm->tm_sec;
	atm.wday = ptm->tm_wday;

	if (piMilliSec)
		*piMilliSec = (auint32)(-1);
#endif
}

void ASys::GetCurLocalTime(ATIME& atm, auint32* piMilliSec)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	SYSTEMTIME st;
	::GetLocalTime(&st);

	atm.year = st.wYear - 1900;
	atm.month = st.wMonth - 1;
	atm.day = st.wDay;
	atm.hour = st.wHour;
	atm.minute = st.wMinute;
	atm.second = st.wSecond;
	atm.wday = st.wDayOfWeek;

	if (piMilliSec)
		*piMilliSec = st.wMilliseconds;
#else
	time_t t = ::time(NULL);
	tm* ptm = ::localtime(&t);

	atm.year = ptm->tm_year;
	atm.month = ptm->tm_mon;
	atm.day = ptm->tm_mday;
	atm.hour = ptm->tm_hour;
	atm.minute = ptm->tm_min;
	atm.second = ptm->tm_sec;
	atm.wday = ptm->tm_wday;

	if (piMilliSec)
		*piMilliSec = (auint32)(-1);
#endif
}

//linux系统
#ifdef A_PLATFORM_LINUX

#include <sys/statfs.h>

void ASys::OutputDebug(const char* format, ...)
{
}

bool ASys::DeleteDirectory(const char* szDir)
{
	if (!ASys::IsFileExist(szDir))
		return true;

	rmdir(szDir);
	return false;
}

auint64 ASys::GetFreeDiskSpaceSize()
{
	struct statfs buf;
	aint64 freespace = 0;
	if (statfs("/var", &buf) >= 0)
	{
		freespace = (auint64)(buf.f_bsize * buf.f_bfree);
	}
	return freespace;
}

#endif