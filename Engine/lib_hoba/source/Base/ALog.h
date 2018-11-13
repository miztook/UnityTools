#ifndef _ALOG_H_
#define _ALOG_H_

#include "ATypes.h"
#include <cstdio>

//	Default log debug function
typedef void(*LPFNDEFLOGOUTPUT)(const char* szMsg);

//重定向输出到函数
LPFNDEFLOGOUTPUT a_RedirectDefLogOutput(LPFNDEFLOGOUTPUT lpfn);
//默认向调试控制台输出，若调用了a_RedirectDefLogOutput函数，则向通过指定的函数输出。
void a_LogOutput(int iLevel, const char* szMsg, ...);
//同上，行尾没有回车
void a_LogOutputNoReturn(int iLevel, const char* szMsg, ...);

//默认向调试控制台输出，若调用了a_RedirectDefLogOutput函数，则向通过指定的函数输出。
void a_LogOutput(const char* szMsg, ...);
//同上，行尾没有回车
void a_LogOutputNoReturn(const char* szMsg, ...);

class ALog
{
private:
	FILE *			m_pFile;
	static char		m_szLogDir[QMAX_PATH];

protected:
public:
	ALog();
	virtual ~ALog();

	// Init a log file
	//		szLogFile	will be the logs path
	//		szHelloMsg	is the hello message in the log
	//		bAppend		is the flag to append at the end of the log file
	bool Init(const char* szLogFile, const char* szHelloMsg, bool bAppend = false);

	// Release the log file
	//		this call will close the log file pointer and write a finished message
	bool Release();

	// Output a variable arguments log message;
	bool Log(const char* fmt, ...);

	// Output a string as a log message;
	bool LogString(const char* szString);

	static void SetLogDir(const char* szLogDir);
	static const char* GetLogDir() { return m_szLogDir; }
};

#endif
