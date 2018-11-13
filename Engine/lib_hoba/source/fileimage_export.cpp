extern "C"
{
#include "fileimage_export.h"
}

#include "AFileImage.h"
#include "AFI.h"

HAPI AFileImage* FileImage_Open(const char* filename, bool bText)
{
	AFileImage* pFile = new AFileImage;
	auint32 dwFlags = bText ? (AFILE_OPENEXIST | AFILE_TEXT) : (AFILE_OPENEXIST | AFILE_BINARY);
	if (!pFile->Open("", filename, dwFlags))
	{
		delete pFile;
		return NULL;
	}
	return pFile;
}

HAPI void FileImage_Close(AFileImage* pFile)
{
	if (pFile)
	{
		pFile->Close();
		delete pFile;
	}
}

HAPI bool FileImage_Read(AFileImage* pFile, void* pBuffer, unsigned int bufferLength)
{
	if (!pFile)
		return false;
	auint32 dwRead;
	return pFile->Read(pBuffer, bufferLength, &dwRead);
}

HAPI int FileImage_GetFileLength(AFileImage* pFile)
{
	if (!pFile)
		return 0;
	return pFile->GetFileLength();
}

HAPI bool FileImage_Seek(AFileImage* pFile, int iOffset)
{
	if (!pFile)
		return false;
	return pFile->Seek(iOffset, AFILE_SEEK_SET);
}

HAPI int FileImage_GetPos(AFileImage* pFile)
{
	if (!pFile)
		return 0;
	return pFile->GetPos();
}

HAPI bool FileImage_IsExist(const char* filename)
{
	return af_IsFileExist(filename);
}