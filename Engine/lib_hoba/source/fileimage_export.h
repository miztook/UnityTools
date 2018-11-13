#ifndef _FILEIMAGE_EXPORT_H_
#define _FILEIMAGE_EXPORT_H_

#include "baseDef.h"

class AFileImage;

HAPI AFileImage*		FileImage_Open(const char* filename, bool bText);
HAPI void			FileImage_Close(AFileImage* pFile);

HAPI bool FileImage_Read(AFileImage* pFile, void* pBuffer, unsigned int bufferLength);

HAPI int FileImage_GetFileLength(AFileImage* pFile);
HAPI bool FileImage_Seek(AFileImage* pFile, int iOffset);
HAPI int FileImage_GetPos(AFileImage* pFile);

HAPI bool FileImage_IsExist(const char* filename);

#endif