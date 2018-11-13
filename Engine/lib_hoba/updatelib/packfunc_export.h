#ifndef _PACKFUNC_EXPORT_H_
#define _PACKFUNC_EXPORT_H_

#include "baseDef.h"
#include <stdbool.h>
#include "compileconfig.h"

HAPI bool PackInitialize(bool bCreate);

HAPI void PackFinalize(bool bForce);

HAPI void FlushWritePack();

HAPI bool SaveAndOpenUpdatePack();

HAPI bool IsFileInPack(const char* filename);

HAPI const char* CalcPackFileMd5(const char* filename);

HAPI const char* CalcFileMd5(const char* filename);

HAPI const char* CalcMemMd5(const unsigned char* pData, int dataSize);

HAPI bool AddCompressedDataToPack(const char* filename, const unsigned char* pData, int dataSize);

HAPI bool UncompressToSepFile(const char* filename, const unsigned char* pData, int dataSize);

HAPI bool MakeCompressedFile(const char* srcFileName, const char* destFileName, bool bNoCompress);

#endif