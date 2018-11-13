#include "AWinMiniDump.h"

#include <DbgHelp.h>
#include <tchar.h>
#include <stdio.h>
#include <stdlib.h>

typedef BOOL(WINAPI *MINIDUMPWRITEDUMP)(HANDLE hProcess, DWORD dwPid, HANDLE hFile, MINIDUMP_TYPE DumpType,
	CONST PMINIDUMP_EXCEPTION_INFORMATION ExceptionParam,
	CONST PMINIDUMP_USER_STREAM_INFORMATION UserStreamParam,
	CONST PMINIDUMP_CALLBACK_INFORMATION CallbackParam
	);

void AWinMiniDump::begin()
{
	::SetUnhandledExceptionFilter(TopLevelFilter);
}

void AWinMiniDump::end()
{
	::SetUnhandledExceptionFilter(NULL);
}

LONG WINAPI AWinMiniDump::TopLevelFilter(struct _EXCEPTION_POINTERS *pExceptionInfo)
{
	LONG retval = EXCEPTION_CONTINUE_SEARCH;

	// firstly see if dbghelp.dll is around and has the function we need
	// look next to the EXE first, as the one in System32 might be old 
	// (e.g. Windows 2000)
	HMODULE hDll = NULL;
	TCHAR szDbgHelpPath[512] = { 0 };

	GetModuleFileName(NULL, szDbgHelpPath, 512);

	TCHAR* pSlash = _tcsrchr(szDbgHelpPath, _T('\\'));
	if (pSlash)
	{
		int len = 512 - (pSlash + 1 - szDbgHelpPath);
		if (len > 0 && *(pSlash + 1))
		{
			_tcscpy_s(pSlash + 1, len, _T("DBGHELP.DLL"));
			hDll = ::LoadLibrary(szDbgHelpPath);
		}
	}

	if (hDll == NULL)
	{
		// load any version we can
		hDll = ::LoadLibrary(_T("DBGHELP.DLL"));
	}

	if (!hDll)
		return retval;

	MINIDUMPWRITEDUMP pDump = (MINIDUMPWRITEDUMP)::GetProcAddress(hDll, "MiniDumpWriteDump");
	if (!pDump)
		return retval;

	TCHAR szDumpPath[512];

	GetModuleFileName(NULL, szDumpPath, 512);

	// work out a good place for the dump file
	pSlash = _tcsrchr(szDumpPath, _T('.'));
	if (pSlash)
	{
		TCHAR timebuf[128];
		SYSTEMTIME time;
		GetLocalTime(&time);
		_stprintf_s(timebuf, 128, _T("-%dm_%dd_%dh_%dm.dmp"), time.wMonth, time.wDay, time.wHour, time.wMinute);

		_tcscpy_s(pSlash, 512 - (pSlash - szDumpPath), timebuf);
	}
	else
		return retval;

	// ask the user if they want to save a dump file

	// create the file
	HANDLE hFile = ::CreateFile(szDumpPath, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS,
		FILE_ATTRIBUTE_NORMAL, NULL);

	if (hFile != INVALID_HANDLE_VALUE)
	{
		_MINIDUMP_EXCEPTION_INFORMATION ExInfo;

		ExInfo.ThreadId = ::GetCurrentThreadId();
		ExInfo.ExceptionPointers = pExceptionInfo;
		ExInfo.ClientPointers = NULL;

		// write the dump
		BOOL bOK = pDump(GetCurrentProcess(), GetCurrentProcessId(), hFile, MiniDumpNormal, &ExInfo, NULL, NULL);
		if (bOK)
		{
			retval = EXCEPTION_EXECUTE_HANDLER;
		}
		::CloseHandle(hFile);
	}

	return retval;
}



