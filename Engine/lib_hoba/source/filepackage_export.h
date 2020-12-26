#ifndef _FILEPACKAGE_EXPORT_H_
#define _FILEPACKAGE_EXPORT_H_

#include "baseDef.h"

class AFilePackage;

HAPI AFilePackage*	FilePackage_Open(const char* pckFileName);

HAPI void FilePackage_Close(AFilePackage* pPackage);

HAPI int FilePackage_GetFileCount(const AFilePackage* pPackage);

HAPI const char* FilePackage_GetFileName(const AFilePackage* pPackage, int iFile);

HAPI bool FilePackage_IsFileExist(const AFilePackage* pPackage, const char* filename);

HAPI bool FilePackage_UnpackFileToDir(AFilePackage* pPackage, const char* filename, const char* dirName);

HAPI const char* FilePackage_UnpackFileToDestFile(AFilePackage* pPackage, const char* filename, int offset, const char* destFileName);

HAPI bool FilePackage_UnpackFileToData(AFilePackage* pPackage, const char* filename, const unsigned char** ppData, int* pDataSize);

HAPI void FilePackage_ClearData(const unsigned char* pData);

#endif
