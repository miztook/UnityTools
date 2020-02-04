extern "C"
{
#include "filepackage_export.h"
}

#include "AFilePackage.h"
#include "ASys.h"
#include "FileOperate.h"
#include "stringext.h"

char g_pckFileName[1024];

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
	if (!pPackage || !pPackage->IsFileExist(filename))
		return false;

	auint8* pFileData;
	auint32 nFileLength;
	void* handle = pPackage->OpenSharedFile(filename, &pFileData, &nFileLength);
	if (!handle)
		return false;

	std::string strOutputDir = dirName;
	normalizeDirName(strOutputDir);
	std::string outputFileName = strOutputDir + filename;
	FileOperate::MakeDir(outputFileName.c_str());
	ASys::ChangeFileAttributes(outputFileName.c_str(), S_IRWXU);

	FILE* file = fopen(outputFileName.c_str(), "wb");
	if (file == nullptr)
	{
		pPackage->CloseSharedFile(handle);
		return false;
	}

	fwrite(pFileData, 1, nFileLength, file);
	fclose(file);

	pPackage->CloseSharedFile(handle);

	ASys::ChangeFileAttributes(outputFileName.c_str(), S_IRWXU);

	return true;
}
