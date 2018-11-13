#include "7zReader.h"
#include "ASysCodeCvt.h"
#include "AFramework.h"

SevenZReader::SevenZReader()
	: m_bFileValid(false), m_bDbValid(false), m_bArValid(false)
{
	m_allocImp.Alloc = SzAlloc;
	m_allocImp.Free = SzFree;
	m_allocTempImp.Alloc = SzAllocTemp;
	m_allocTempImp.Free = SzFreeTemp;
}

SevenZReader::~SevenZReader()
{
	destroy();
}

int SevenZReader::init(const char* archiveName)
{
	destroy();
	m_archiveName = archiveName;

	// open 7z
	if (InFile_Open(&m_archiveStream.file, m_archiveName.c_str()))		// open file
	{
		destroy();
		return -1;		// fail to open file
	}

	m_bFileValid = true;

	FileInStream_CreateVTable(&m_archiveStream);
	LookToRead_CreateVTable(&m_lookStream, False);
	m_lookStream.realStream = &m_archiveStream.s;
	LookToRead_Init(&m_lookStream);

	CrcGenerateTable();

	SzArEx_Init(&m_db);
	m_bDbValid = true;

	int retCode = SzArEx_Open(&m_db, &m_lookStream.s, &m_allocImp, &m_allocTempImp);
	if (retCode != SZ_OK)
	{
		destroy();
		return -1;		// fail to open 7z file
	}

	m_bArValid = true;

	// init extract state
	m_blockIndex = 0xFFFFFFFF; /* it can have any value before first call (if outBuffer = 0) */
	m_outBuffer = 0; /* it must be 0 before first call for each new archive. */
	m_outBufferSize = 0;  /* it can have any value before first call (if outBuffer = 0) */

	return 0;
}

int SevenZReader::getFileCount()
{
	if (!m_bDbValid)
		return -1;

	return m_db.NumFiles;
}

bool SevenZReader::isDir(int iFile)
{
 	return m_bDbValid && iFile >= 0 && iFile < (int)m_db.NumFiles
		&& SzArEx_IsDir(&m_db, iFile);
}

int SevenZReader::getFileName(int iFile, size_t bufferSize, auchar* buffer/*out*/)
{
	if (!m_bDbValid)
		return NULL;

	size_t nameLen = SzArEx_GetFileNameUtf16(&m_db, iFile, NULL);
	if (nameLen == 0)
		return -1;		// no such file
	else if (nameLen > bufferSize)
		return -2;		// buffer too small

	SzArEx_GetFileNameUtf16(&m_db, iFile, (UInt16*)buffer);
	return 0;
}

int SevenZReader::extractFile(int iFile, const unsigned char** ppData/*out*/, size_t* pDataSize/*out*/)
{
	if (!m_bDbValid)
		return -1;		// not initialized

	size_t offset;
	size_t outSizeProcessed;

	int res = SzArEx_Extract(&m_db, &m_lookStream.s, iFile,
		&m_blockIndex, &m_outBuffer, &m_outBufferSize,
		&offset, &outSizeProcessed,
		&m_allocImp, &m_allocTempImp);

	if (res != SZ_OK)
	{
		g_pAFramework->DevPrintf("SevenZReader::extractFile Failed! code: %d", res);
		return -1;		// extract error
	}

	if (ppData)
		*ppData = (const unsigned char*)(m_outBuffer + offset);
	if (pDataSize)
		*pDataSize = outSizeProcessed;

	return 0;
}

void SevenZReader::destroy()
{
	if (m_bArValid)
		IAlloc_Free(&m_allocImp, m_outBuffer);
	m_bArValid = false;

	if (m_bFileValid)
		SzArEx_Free(&m_db, &m_allocImp);
	m_bFileValid = false;

	if (m_bDbValid)
		File_Close(&m_archiveStream.file);
	m_bDbValid = false;
}