#include "ALog.h"
#include "ASys.h"
#include "AFI.h"

//	Default debug output function
static LPFNDEFLOGOUTPUT	l_lpfnDefLogOutput = NULL;

char ALog::m_szLogDir[QMAX_PATH] = "Logs";

static void _DefLogOutput(const char* szMsg)
{
	if (l_lpfnDefLogOutput)
	{
		//	Use user defined log output function
		l_lpfnDefLogOutput(szMsg);
		return;
	}

	//	Use system log output function
	ASys::OutputDebug(szMsg);
}

static void _SafeCreateDir(const char* szDir)
{
	if (ASys::AccessFile(szDir, 0) == -1)
	{
		ASys::CreateDirectory(szDir);
	}
}

/*	Redirect default log ouput function. This function can be used to
	redirect the destination all ACommon's internal logs.

	Return previous function set by user.

	lpfn: used defined log output function.
	*/
LPFNDEFLOGOUTPUT a_RedirectDefLogOutput(LPFNDEFLOGOUTPUT lpfn)
{
	LPFNDEFLOGOUTPUT lpOld = l_lpfnDefLogOutput;
	l_lpfnDefLogOutput = lpfn;
	return lpOld;
}

/*	Output log using default output function. This function adds a return
	character at the end of message automatically.

	iLevel: log level. 0 = log; 1 = error
	szMsg: log message.
	*/
void a_LogOutput(int iLevel, const char* szMsg, ...)
{
	char szBuf[1024];

	if (iLevel)
		strcpy(szBuf, "<!> ");
	else
		strcpy(szBuf, "<-> ");

	va_list vaList;
	va_start(vaList, szMsg);
	vsnprintf(szBuf + 4, sizeof(szBuf) - 4, szMsg, vaList);
	va_end(vaList);

	strcat(szBuf, "\n");
	_DefLogOutput(szBuf);
}

/*	Output log using default output function. This function output message without
	return character appended.

	iLevel: log level. 0 = log; 1 = error
	szMsg: log message.
	*/
void a_LogOutputNoReturn(int iLevel, const char* szMsg, ...)
{
	char szBuf[1024];

	if (iLevel)
		strcpy(szBuf, "<!> ");
	else
		strcpy(szBuf, "<-> ");

	va_list vaList;
	va_start(vaList, szMsg);
	vsnprintf(szBuf + 4, sizeof(szBuf) - 4, szMsg, vaList);
	va_end(vaList);

	_DefLogOutput(szBuf);
}

//
void a_LogOutput(const char* szMsg, ...)
{
	char szBuf[1024];

	strcpy(szBuf, "<-> ");

	va_list vaList;
	va_start(vaList, szMsg);
	vsnprintf(szBuf + 4, sizeof(szBuf) - 4, szMsg, vaList);
	va_end(vaList);

	strcat(szBuf, "\n");
	_DefLogOutput(szBuf);
}
//
void a_LogOutputNoReturn(const char* szMsg, ...)
{
	char szBuf[1024];

	strcpy(szBuf, "<-> ");

	va_list vaList;
	va_start(vaList, szMsg);
	vsnprintf(szBuf + 4, sizeof(szBuf) - 4, szMsg, vaList);
	va_end(vaList);

	_DefLogOutput(szBuf);
}

ALog::ALog()
{
	m_pFile = NULL;
}

ALog::~ALog()
{
}

bool ALog::Init(const char* szLogFile, const char* szHelloMsg, bool bAppend)
{
	char szLogPath[QMAX_PATH];
	char zsLogFullPathDir[QMAX_PATH];
	const char* szDocumentsDir = af_GetDocumentDir();
	sprintf(zsLogFullPathDir, "%s/%s", szDocumentsDir, m_szLogDir);
	_SafeCreateDir(zsLogFullPathDir);
	sprintf(szLogPath, "%s/%s", zsLogFullPathDir, szLogFile);
	if (bAppend)
		m_pFile = fopen(szLogPath, "at");
	else
		m_pFile = fopen(szLogPath, "wt");
	if (NULL == m_pFile)
		return true;

	ATIME time;
	ASys::GetCurLocalTime(time, NULL);
	fprintf(m_pFile, "%s\nCreated(or opened) on %02d/%02d/%04d %02d:%02d:%02d\n\n", szHelloMsg,
		time.day, time.month + 1, time.year + 1900, time.hour, time.minute, time.second);

	fflush(m_pFile);

	return true;
}

bool ALog::Release()
{
	LogString("Log file closed successfully!");

	if (m_pFile)
	{
		fclose(m_pFile);
		m_pFile = NULL;
	}

	return true;
}

bool ALog::Log(const char* fmt, ...)
{
	char szErrorMsg[2048];
	va_list args_list;

	va_start(args_list, fmt);
	vsnprintf(szErrorMsg, sizeof(szErrorMsg), fmt, args_list);
	va_end(args_list);

	return LogString(szErrorMsg);
}

bool ALog::LogString(const char* szString)
{
	if (!m_pFile)
		return true;

	ATIME time;
	auint32 millisec = 0;
	ASys::GetCurLocalTime(time, &millisec);

	fprintf(m_pFile, "[%02d:%02d:%02d.%03d] %s\n", time.hour, time.minute, time.second, millisec, szString);
	fflush(m_pFile);

	return true;
}

void ALog::SetLogDir(const char * szLogDir)
{
	strncpy(m_szLogDir, szLogDir, QMAX_PATH);

	if ((m_szLogDir[strlen(m_szLogDir) - 1] == '\\') || (m_szLogDir[strlen(m_szLogDir) - 1] == '/'))
		m_szLogDir[strlen(m_szLogDir) - 1] = '\0';

	_SafeCreateDir(m_szLogDir);
}