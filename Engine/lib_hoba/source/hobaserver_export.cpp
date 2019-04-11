extern "C"
{
#include "hobaserver_export.h"
}

#include "ATypes.h"

#ifdef A_PLATFORM_WIN_DESKTOP

#include "AWinMemDbg.h"
#include "AWinMiniDump.h"
#include <crtdbg.h>

AWinMemDbg globalSvrDbg;

#endif

HAPI void HOBA_BeginWinMiniDump()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	AWinMiniDump::begin();
#endif
}

HAPI void HOBA_EndWinMiniDump()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	AWinMiniDump::end();
#endif
}

HAPI void HOBA_MemBeginCheckPoint()
{
#ifdef A_PLATFORM_WIN_DESKTOP

#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	globalSvrDbg.beginCheckPoint();
#endif
}

HAPI bool HOBA_MemEndCheckPoint()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	return globalSvrDbg.endCheckPoint();
#else
	return true;
#endif
}

HAPI void HOBA_MemSetBreakAlloc(int block)
{
#ifdef A_PLATFORM_WIN_DESKTOP
	_CrtSetBreakAlloc(block);
#endif
}

HAPI void HOBA_MemDumpMemoryLeaks()
{
#ifdef A_PLATFORM_WIN_DESKTOP
	_CrtDumpMemoryLeaks();
#endif
}