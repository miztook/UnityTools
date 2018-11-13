#pragma once

extern "C"
{
#include "7z.h"
#include "7zAlloc.h"
#include "7zCrc.h"
#include "7zFile.h"
#include "7zVersion.h"
}

#include <string>
#include <unordered_map>
#include "ATypes.h"

class SevenZReader
{
public:
	SevenZReader();
	~SevenZReader();

public:
	int init(const char* archiveName);
	void destroy();

	int getFileCount();
	bool isDir(int iFile);
	int getFileName(int iFile, size_t bufferSize, auchar* buffer/*out*/);
	int extractFile(int iFile, const unsigned char** ppData/*out*/, size_t* pDataSize/*out*/);

private:
	std::string m_archiveName;

	// 7z data
	CFileInStream m_archiveStream;		// file stream
	bool m_bFileValid;
	CLookToRead m_lookStream;			// lookup stream
	CSzArEx m_db;
	bool m_bDbValid;
	bool m_bArValid;
	ISzAlloc m_allocImp;
	ISzAlloc m_allocTempImp;

	// 7z decode state
	UInt32 m_blockIndex; /* it can have any value before first call (if outBuffer = 0) */
	Byte* m_outBuffer; /* it must be 0 before first call for each new archive. */
	size_t m_outBufferSize;  /* it can have any value before first call (if outBuffer = 0) */
};
