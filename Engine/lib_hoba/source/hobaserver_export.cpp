extern "C"
{
#include "hobaserver_export.h"
}

#ifdef A_PLATFORM_WIN_DESKTOP

#include "AWinMemDbg.h"
#include "AWinMiniDump.h"

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
