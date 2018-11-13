extern "C"
{
#include "7zreader_export.h"
}

#include "7zReader.h"
#include "ASysCodeCvt.h"

char g_7zFileName[1024];

//
HAPI SevenZReader* SevenZReader_Init(const char* archiveName)
{
	SevenZReader* reader = new SevenZReader;
	if (reader->init(archiveName) == 0)
		return reader;

	delete reader;
	return NULL;
}

HAPI void SevenZReader_Destroy(SevenZReader* reader)
{
	delete reader;
}

HAPI int SevenZReader_GetFileCount(SevenZReader* reader)
{
	return reader->getFileCount();
}

HAPI const char* SevenZReader_GetFileName(SevenZReader* reader, int iFile)
{
	auchar* u16name = new auchar[512];
	if (0 != reader->getFileName(iFile, (size_t)512, u16name))
	{
		delete[] u16name;
		return NULL;
	}

	bool ret = ASysCodeCvt::UTF16LEToUTF8(g_7zFileName, u16name) > 0;
	delete[] u16name;
	return ret ? g_7zFileName : NULL;
}

HAPI bool SevenZReader_ExtractFile(SevenZReader* reader, int iFile, const unsigned char** ppData, int* pDataSize)
{
	size_t size;
	if (0 != reader->extractFile(iFile, ppData, &size))
		return false;

	if (pDataSize)
		*pDataSize = (int)size;
	return true;
}

HAPI bool SevenZReader_IsDir(SevenZReader* reader, int iFile)
{
	return reader->isDir(iFile);
}