//-------------------------------------------------------------------------------------------------
//FileName:ASys.h
//Created by liyi 2012,11,22
//-------------------------------------------------------------------------------------------------
#ifndef _A_SYS_H_
#define _A_SYS_H_

#include "compileconfig.h"
#include "ATypes.h"
#include <string>

#include <vector>
#include <ctime>
#include <cstdio>
#include <sys/stat.h>
#include <cfloat>

class ASys
{
public:
	//文件系统
	//判断文件或文件夹是否存在
	static bool IsFileExist(const char* szFileName);
	//删除文件
	static bool DeleteFile(const char* szFile);
	static bool CopyFile(const char* src, const char* des, bool bFailIfExists);
	static bool MoveFile(const char* src, const char* des);
	//删除目录及其内部的所有文件
	static bool DeleteDirectory(const char* szDir);
	//创建目录，不会递归创建，若该目录的上级
	static bool CreateDirectory(const char* szDir);
	static int AccessFile(const char* path, int mode);
	static int SetFileSize(int fd, aint32 size);

	static void AndriodFileClean(const char* szBaseDir, bool bCleanUpdate);
	static bool IOSGetCurLanguage(char* lang, int nSize);

	//遍历目录, 输入文件夹结尾没有斜杠，返回的文件名中不包含路径
	static bool GetFilesInDirectory(std::vector<std::string>& arrFiles, const char* szDir);

	//获取可以写入文档的目录，ios 上并不是所有目录下都能写文件的
	static bool GetDocumentsDirectory(char* szDocumentDir, int nSize);

	static bool GetLibraryDirectory(char* szLibraryDir, int nSize);

	static bool GetTmpDirectory(char* szTmpDir, int nSize);

	//获取文件改动的时间戳
	static auint32 GetFileTimeStamp(const char* szFileName);
	static auint32 GetFileSize(const char* szFileName);
	static auint32 ChangeFileAttributes(const char* szFileName, int mode);

	static auint64 GetFreeDiskSpaceSize();  //Get free DiskSpace size in bytes
	static auint64 GetVirtualMemoryUsedSize();
	static auint64 GetPhysMemoryUsedSize();

	//	Get Milli-second
	static auint32 GetMilliSecond();
	//	Get micro-second
	static auint64 GetMicroSecond();

	//	Make ATIME structure from time value returned by GetTimeSince1970()
	static void GMTime(auint64 _time, ATIME& atm);
	static void LocalTime(auint64 _time, ATIME& atm);

	static auint64 TimeLocal(const ATIME& atm);
	//	Get current time
	//	piMilliSec: can be NULL, used to get millisecond. Not every system support this, and on those
	//		systems -1 will be returned.
	static void GetCurGMTime(ATIME& atm, auint32* piMilliSec);
	static void GetCurLocalTime(ATIME& atm, auint32* piMilliSec);

	//让当前线程睡眠
	static void Sleep(unsigned int nMilliSecond);
	//输出信息到调试窗口
	static void OutputDebug(const char* format, ...);

	static aint64 AtoInt64(const char* szString);
	static int StrCmpNoCase(const char* sz1, const char* sz2);
	static char* Strlwr(char* str);
	static char* Strupr(char* str);
	static int  Fileno(FILE * _File);
};

#ifdef A_PLATFORM_WIN_DESKTOP

#define a_snprintf _snprintf
#define a_isnan _isnan

#define S_IRWXU		_S_IWRITE

#else

#define a_snprintf snprintf
#define a_isnan std::isnan

#endif

#endif //_A_SYS_H_
