#ifndef _HOBA_EXPORT_H_
#define _HOBA_EXPORT_H_

#include "baseDef.h"
#include <stdbool.h>
#include <stdint.h>

//client use only

HAPI const char* HOBA_GetDocumentDir();

HAPI const char* HOBA_GetLibraryDir();

HAPI const char* HOBA_GetTmpDir();

HAPI const char* HOBA_IOSGetCurLanguage();

HAPI void HOBA_Init(const char* baseDir, const char* docDir, const char* libDir, const char* tmpDir);

HAPI void HOBA_Release(int* memKB);

HAPI void HOBA_Tick();			//为做一些统计

HAPI float HOBA_GetMPS();		//每帧分配多少byte

HAPI void HOBA_GetMemStats(int* peakMemKB, int* curMemKB);

HAPI void HOBA_DumpMemoryStats(const char* msg);

HAPI bool HOBA_InitPackages(const char* resBaseDir);

HAPI void HOBA_LogString(const char* strMsg);

HAPI bool HOBA_DeleteFilesInDirectory(const char* strDir);

HAPI bool HOBA_HasFilesInDirectory(const char* strDir);

HAPI uint64_t HOBA_GetFreeDiskSpace();

HAPI uint64_t HOBA_GetVirtualMemoryUsedSize();

HAPI uint64_t HOBA_GetPhysMemoryUsedSize();

HAPI uint32_t HOBA_GetMilliSecond();

HAPI uint64_t HOBA_GetMicroSecond();

#endif