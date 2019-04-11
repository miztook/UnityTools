#ifndef _HOBASERVER_EXPORT_H_
#define _HOBASERVER_EXPORT_H_

#include "baseDef.h"
#include <stdbool.h>

HAPI void HOBA_BeginWinMiniDump();

HAPI void HOBA_EndWinMiniDump();

HAPI void HOBA_MemBeginCheckPoint();

HAPI bool HOBA_MemEndCheckPoint();

HAPI void HOBA_MemSetBreakAlloc(int block);

HAPI void HOBA_MemDumpMemoryLeaks();

#endif