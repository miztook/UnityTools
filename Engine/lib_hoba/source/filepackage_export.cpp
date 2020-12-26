extern "C"
{
#include "filepackage_export.h"
}

#include "AFilePackage.h"
#include "ASys.h"
#include "FileOperate.h"
#include "stringext.h"
#include "CMd5Hash.h"

char g_pckFileName[1024];
char g_pckFileMd5[64];
#define BLOCK_SIZE   (2 * 1024 * 1024)

HAPI AFilePackage* FilePackage_Open(const char* pckFileName)
{
	AFilePackage* pFilePackage = new AFilePackage;
	if (!pFilePackage->Open(pckFileName, "", AFilePackage::OPENEXIST))
	{
		delete pFilePackage;
		return NULL;
	}
	//pFilePackage->AllocTempMemory();

	return pFilePackage;
}

HAPI void FilePackage_Close(AFilePackage* pPackage)
{
	if (pPackage)
	{
		//pPackage->FreeTempMemory();

		pPackage->Close();
		delete pPackage;
	}
}

HAPI int FilePackage_GetFileCount(const AFilePackage* pPackage)
{
	if (!pPackage)
		return 0;
	return pPackage->GetFileNumber();
}

HAPI const char* FilePackage_GetFileName(const AFilePackage* pPackage, int iFile)
{
	if (!pPackage)
		return NULL;

	if (iFile < 0 || iFile >= pPackage->GetFileNumber())
		return NULL;
	const AFilePackage::FILEENTRY* pFileEntry = pPackage->GetFileEntryByIndex(iFile);
	if (!pFileEntry)
		return NULL;

	strcpy(g_pckFileName, pFileEntry->szFileName);
	return g_pckFileName;
}

HAPI bool FilePackage_IsFileExist(const AFilePackage* pPackage, const char* filename)
{
	if (!pPackage)
		return false;

	return pPackage->IsFileExist(filename);
}

HAPI bool FilePackage_UnpackFileToDir(AFilePackage* pPackage, const char* filename, const char* dirName)
{
	if (!pPackage)
		return false;

	//	Get file entry
	AFilePackage::FILEENTRY fileEntry;
	if (!pPackage->GetFileEntry(filename, &fileEntry))
		return false;
	
	std::string strOutputDir = dirName;
	normalizeDirName(strOutputDir);
	std::string outputFileName = strOutputDir + filename;
	if (ASys::IsFileExist(outputFileName.c_str()))
		ASys::ChangeFileAttributes(outputFileName.c_str(), S_IRWXU);
	else
		FileOperate::MakeDir(outputFileName.c_str());

	FILE* file = fopen(outputFileName.c_str(), "wb");
	if (file == nullptr)
		return false;
	
	aint64 dwOffset = fileEntry.dwOffset;
	aint64 dwLength = fileEntry.dwLength;

	if (dwLength < 0)
	{
		fclose(file);
		return false;
	}

	auto packageFile = pPackage->GetPackageFile();
	packageFile->seek(dwOffset, SEEK_SET);

	bool bFailed = false;
	void* pBuffer = malloc(BLOCK_SIZE);
	for (auint32 i = 0; i < dwLength / BLOCK_SIZE; ++i)
	{
		if (BLOCK_SIZE != packageFile->read(pBuffer, 1, BLOCK_SIZE))
			bFailed = true;
		if (BLOCK_SIZE != fwrite(pBuffer, 1, BLOCK_SIZE, file))
			bFailed = true;
	}
	auint32 nLeft = dwLength % BLOCK_SIZE;
	{
		if (nLeft != packageFile->read(pBuffer, 1, nLeft))
			bFailed = true;
		if (nLeft != fwrite(pBuffer, 1, nLeft, file))
			bFailed = true;
	}

	fclose(file);
	free(pBuffer);

	return !bFailed;
}

HAPI const char* FilePackage_UnpackFileToDestFile(AFilePackage* pPackage, const char* filename, int offset, const char* destFileName)
{
	if (!pPackage)
		return NULL;

	//	Get file entry
	AFilePackage::FILEENTRY fileEntry;
	if (!pPackage->GetFileEntry(filename, &fileEntry))
		return NULL;

	auto packageFile = pPackage->GetPackageFile();

	std::string outputFileName = destFileName;
	normalizeFileName(outputFileName);
	if (ASys::IsFileExist(outputFileName.c_str()))
		ASys::ChangeFileAttributes(outputFileName.c_str(), S_IRWXU);
	else
		FileOperate::MakeDir(outputFileName.c_str());

	FILE* file = fopen(outputFileName.c_str(), "wb");
	if (file == nullptr)
		return NULL;

	aint64 dwOffset = offset + fileEntry.dwOffset;
	aint64 dwLength = fileEntry.dwLength - offset;

	if (dwLength < 0)
	{
		fclose(file);
		return NULL;
	}

	CMd5Hash m;
	{
		packageFile->seek(fileEntry.dwOffset, SEEK_SET);
		unsigned char buf[4096];
		if (offset > 0)
		{
			int nRead = packageFile->read(buf, 1, offset);
			m.update(buf, nRead);
		}
	}

	packageFile->seek(dwOffset, SEEK_SET);

	bool bFailed = false;
	void* pBuffer = malloc(BLOCK_SIZE);
	for (auint32 i = 0; i < dwLength / BLOCK_SIZE; ++i)
	{
		if (BLOCK_SIZE != packageFile->read(pBuffer, 1, BLOCK_SIZE))
			bFailed = true;

		if (!bFailed)
			m.update((const unsigned char*)pBuffer, BLOCK_SIZE);

		if (BLOCK_SIZE != fwrite(pBuffer, 1, BLOCK_SIZE, file))
			bFailed = true;
	}
	auint32 nLeft = dwLength % BLOCK_SIZE;
	{
		if (nLeft != packageFile->read(pBuffer, 1, nLeft))
			bFailed = true;

		if (!bFailed)
			m.update((const unsigned char*)pBuffer, nLeft);

		if (nLeft != fwrite(pBuffer, 1, nLeft, file))
			bFailed = true;
	}

	fclose(file);
	free(pBuffer);

	if (g_pckFileMd5)
	{
		unsigned char outbuf[16];
		auint32 i = 64;
		m.final(outbuf);
		m.getString(outbuf, g_pckFileMd5, i);
	}

	return bFailed ? NULL : g_pckFileMd5;
}

HAPI bool FilePackage_UnpackFileToData(AFilePackage* pPackage, const char* filename, const unsigned char** ppData, int* pDataSize)
{
	if (!pPackage)
		return false;

	//	Get file entry
	AFilePackage::FILEENTRY fileEntry;
	if (!pPackage->GetFileEntry(filename, &fileEntry))
		return false;

	aint64 dwOffset = fileEntry.dwOffset;
	aint64 dwLength = fileEntry.dwLength;

	if (dwLength < 0)
		return false;

	auto packageFile = pPackage->GetPackageFile();
	packageFile->seek(dwOffset, SEEK_SET);

	void* pBuffer = malloc(dwLength);
	bool bFailed = false;
	if (dwLength != packageFile->read(pBuffer, 1, dwLength))
	{
		free(pBuffer);
		return false;
	}

	*ppData = (const unsigned char*)pBuffer;
	*pDataSize = dwLength;

	return true;
}

HAPI void FilePackage_ClearData(const unsigned char* pData)
{
	free((void*)pData);
}
