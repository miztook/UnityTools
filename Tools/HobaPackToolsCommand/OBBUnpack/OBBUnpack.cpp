#include "AFramework.h"
#include "af.h"
#include "FileOperate.h"
#include "function.h"
#include "stringext.h"
#include "AWinMemDbg.h"
#include <string>
#include "AFilePackage.h"

char curDir[1024];
bool doUnpack(const std::string& strFileName, const std::string& strOutputDir);

int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		printf("usage: OBBUnpack.exe <JupFileName>");
		getchar();
		return -1;
	}

#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	AWinMemDbg globalDbg;
	globalDbg.beginCheckPoint();

	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);
	HOBAInitParam param;
	param.pszBaseDir = tmp;
	param.pszDocumentDir = tmp;
	param.pszLibraryDir = tmp;
	param.pszTemporaryDir = tmp;

	std::string strWorkDir = tmp;
	normalizeDirName(strWorkDir);

	g_pAFramework->Init(param);

	std::string strFileName = argv[1];
	strFileName = strWorkDir + strFileName;

	getFullFileNameNoExtensionA(argv[1], tmp, 1024);
	std::string strOutputDir = strWorkDir + tmp;
	normalizeDirName(strOutputDir);

	if (!af_IsFileExist(strFileName.c_str()))
	{
		printf("%s is not exist!\n", strFileName.c_str());
		goto FAIL;
	}

	printf("Begin Unpack: %s, To: %s\r\n", strFileName.c_str(), strOutputDir.c_str());
	g_pAFramework->Printf("Begin Unpack: %s, To: %s\r\n", strFileName.c_str(), strOutputDir.c_str());

	if (!doUnpack(strFileName, strOutputDir))
	{
		printf("doUnpack Failed! %s\n", strFileName.c_str());
		goto FAIL;
	}

	printf("End OBBUnpack Success!\r\n");
	g_pAFramework->Printf("End OBBUnpack Success!\r\n");

	g_pAFramework->Release();

	bool safe = globalDbg.endCheckPoint();
	//_ASSERT(safe);

	int memKB;
	globalDbg.outputMaxMemoryUsed(&memKB);
	printf("maximum memory used : %0.3f M\n", memKB * 0.001f);

	//getchar();
	return 0;

FAIL:
	printf("End OBBUnpack, Fail\r\n");
	g_pAFramework->Printf("End OBBUnpack, Fail\r\n");

	g_pAFramework->Release();
	getchar();
	return -1;
}

bool doUnpack(const std::string& strFileName, const std::string& strOutputDir)
{
	AFilePackage pckFile;
	if (!pckFile.Open(strFileName.c_str(), "", AFilePackage::OPENEXIST))
	{
		printf("Open Pck Failed: %s\r\n", strFileName);
		g_pAFramework->Printf("Open Pck Failed: %s\r\n", strFileName);
		return false;
	}
	
	FileOperate::DeleteDir(strOutputDir.c_str());
	FileOperate::MakeDir(strOutputDir.c_str());

	int numFiles = pckFile.GetFileNumber();
	for (int i = 0; i < numFiles; ++i)
	{
		auto entry = pckFile.GetFileEntryByIndex(i);
		
		printf("Unpack file %d, %s\r\n", i, entry->szFileName);
		g_pAFramework->Printf("Unpack file %d, %s\r\n", i, entry->szFileName);

		ASSERT(entry->dwLength == entry->dwCompressedLength);

		auint8* pFileData;
		auint32 nFileLength;
		void* handle = pckFile.OpenSharedFile(entry->szFileName, &pFileData, &nFileLength);
		if (!handle)
		{
			printf("Open File of Pck Failed: %s\r\n", entry->szFileName);
			g_pAFramework->Printf("Open File of Pck Failed: %s\r\n", entry->szFileName);
			return false;
		}

		std::string fileName = strOutputDir + entry->szFileName;

		if (ASys::IsFileExist(fileName.c_str()))
			ASys::ChangeFileAttributes(fileName.c_str(), S_IRWXU);
		else
			FileOperate::MakeDir(fileName.c_str());

		FILE* file = fopen(fileName.c_str(), "wb");
		if (file == nullptr)
		{
			pckFile.CloseSharedFile(handle);

			printf("Open File Failed: %s\r\n", fileName.c_str());
			g_pAFramework->Printf("Open File Failed: %s\r\n", fileName.c_str());
			return false;
		}

		fwrite(pFileData, 1, nFileLength, file);
		fclose(file);

		pckFile.CloseSharedFile(handle);
	}

	pckFile.Close();

	return true;
}