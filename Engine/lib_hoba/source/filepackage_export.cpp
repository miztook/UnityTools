extern "C"
{
#include "filepackage_export.h"
}

#include "AFilePackage.h"
#include "ASys.h"
#include "FileOperate.h"
#include "stringext.h"

char g_pckFileName[1024];
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
	AFilePackage::FILEENTRY entry;
	if (!pPackage->GetFileEntry(filename, &entry))
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
	
	auto packageFile = pPackage->GetPackageFile();
	packageFile->seek(entry.dwOffset, SEEK_SET);

	bool bFailed = false;
	void* pBuffer = malloc(BLOCK_SIZE);
	for (auint32 i = 0; i < entry.dwLength / BLOCK_SIZE; ++i)
	{
		if (BLOCK_SIZE != packageFile->read(pBuffer, 1, BLOCK_SIZE))
			bFailed = true;
		if (BLOCK_SIZE != fwrite(pBuffer, 1, BLOCK_SIZE, file))
			bFailed = true;
	}
	auint32 nLeft = entry.dwLength % BLOCK_SIZE;
	{
		if (nLeft != packageFile->read(pBuffer, 1, nLeft))
			bFailed = true;
		if (nLeft != packageFile->write(pBuffer, 1, nLeft))
			bFailed = true;
	}

	fclose(file);
	free(pBuffer);

	ASys::ChangeFileAttributes(outputFileName.c_str(), S_IRWXU);

	return !bFailed;
}
