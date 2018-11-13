#ifndef _7ZREADER_EXPORT_H_
#define _7ZREADER_EXPORT_H_

#include "baseDef.h"
#include <stdbool.h>
#include "compileconfig.h"

class SevenZReader;

HAPI SevenZReader* SevenZReader_Init(const char* archiveName);

HAPI void SevenZReader_Destroy(SevenZReader* reader);

HAPI int SevenZReader_GetFileCount(SevenZReader* reader);

HAPI const char* SevenZReader_GetFileName(SevenZReader* reader, int iFile);

HAPI bool SevenZReader_ExtractFile(SevenZReader* reader, int iFile, const unsigned char** ppData, int* pDataSize);

HAPI bool SevenZReader_IsDir(SevenZReader* reader, int iFile);

#endif
