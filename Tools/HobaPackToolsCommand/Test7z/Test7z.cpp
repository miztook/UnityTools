#include "AFramework.h"
#include "function.h"
#include "stringext.h"
#include "FileOperate.h"
#include "AFI.h"
#include "ASys.h"
#include <memory>
#include <map>

extern "C"
{
#include "7zreader_export.h"
#include "packfunc_export.h"
}

struct SFileCompressInfo
{
	std::string filename;
	uint32_t	origSize;
	uint32_t	compressedSize;
	uint32_t	uncompressMs;

	SFileCompressInfo() : origSize(0), compressedSize(0), uncompressMs(0) {}
};


std::map<std::string, SFileCompressInfo*> test7z(const char* szDirToCompress, const char* szDirCompressed, const char* szDirUncompressed, const char* szOptions, bool regenerate);
bool copyFile(const char* srcDirName, const char* srcFileName, const char* destDirName);
bool doUnpackFrom7z(const char* srcFile, const char* destDir, uint32_t& uncompressMs);

int main(int argc, char* argv[])
{
	char tmp[1024];
	GetCurrentDirectoryA(1024, tmp);
	HOBAInitParam param;
	param.pszBaseDir = tmp;
	param.pszDocumentDir = tmp;
	param.pszLibraryDir = tmp;
	param.pszTemporaryDir = tmp;

	g_pAFramework->Init(param);

	if (argc != 7)
	{
		printf("usage: Test7z.exe <FileDirToCompress> <FileDirCompressed> <FileDirUncompressed> <Options> <Recompress> <ReportFile>\n");
		getchar();
		return -1;
	}

	std::string strDirToCompress = argv[1];
	std::string strDirCompressed = argv[2];
	std::string strDirUncompressed = argv[3];
	std::string strOptions = argv[4];
	bool recompress = strcmp(argv[5], "0") != 0;
	std::string strReport = argv[6];

	normalizeDirName(strDirToCompress);
	normalizeDirName(strDirCompressed);
	normalizeDirName(strDirUncompressed);

	if (!FileOperate::FileExist(strDirCompressed.c_str()))
		FileOperate::MakeDir(strDirCompressed.c_str());
	if (!FileOperate::FileExist(strDirUncompressed.c_str()))
		FileOperate::MakeDir(strDirUncompressed.c_str());

	if (recompress)
		FileOperate::DeleteDir(strDirCompressed.c_str());

	//std::string options = "-t7z -m0=LZMA2 -mx=5 -mtm=off -mtr=off";
	//std::string reportName = "Report-LZMA2_Normal.csv";

	std::map<std::string, SFileCompressInfo*> compressInfoMap = test7z(
		strDirToCompress.c_str(), strDirCompressed.c_str(), strDirUncompressed.c_str(), strOptions.c_str(), recompress);

	for (auto itr : compressInfoMap)
	{
		std::string filename = strDirCompressed + itr.first + ".7z";

		uint32_t uncompressMs = 0;
		doUnpackFrom7z(filename.c_str(), strDirUncompressed.c_str(), uncompressMs);
	
		SFileCompressInfo* info = itr.second;
		info->uncompressMs = uncompressMs;
	}

	{
		std::string filename = tmp;
		normalizeDirName(filename);
		filename += strReport;
		FileOperate::UDeleteFile(filename.c_str());
		FILE* file = fopen(filename.c_str(), "wt");
		if (file)
		{
			uint32_t totalOrigSize = 0;
			uint32_t totalCompressSize = 0;
			uint32_t totalUncompressMs = 0;
			for (auto itr : compressInfoMap)
			{
				std::string fname = itr.first;
				uint32_t origSize = itr.second->origSize;
				uint32_t compressSize = itr.second->compressedSize;
				float ratio = (float)itr.second->compressedSize / itr.second->origSize;
				uint32_t uncompressMs = itr.second->uncompressMs;

				totalOrigSize += origSize;
				totalCompressSize += compressSize;
				totalUncompressMs += uncompressMs;

				fprintf(file, "%s,%u,%u,%0.2f,%u\n", fname.c_str(), origSize, compressSize, ratio, uncompressMs);
			}

			float totalRatio = (float)totalCompressSize / totalOrigSize;
			fprintf(file, "%s,%u,%u,%0.2f,%u\n", "TOTAL", totalOrigSize, totalCompressSize, totalRatio, totalUncompressMs);

			fclose(file);
		}
	}

	for (auto itr : compressInfoMap)
	{
		delete itr.second;
	}
	compressInfoMap.clear();

	printf("Test7z Success!\r\n");
	g_pAFramework->Printf("Test7z Success!\r\n");

	g_pAFramework->Release();

	//getchar();
	return 0;
}

std::map<std::string, SFileCompressInfo*> test7z(
	const char* szDirToCompress, const char* szDirCompressed, const char* szDirUncompressed, const char* szOptions, bool regenerate)
{
	std::map<std::string, SFileCompressInfo*> compressFileMap;

	std::string strWorkingDir = af_GetBaseDir();
	normalizeDirName(strWorkingDir);

	std::vector<std::string> fileList;

	Q_iterateFiles(szDirToCompress, "*.*",
		[&fileList](const char* filename)
	{
		char ext[32];
		getFileExtensionA(filename, ext, 32);
		if (strcmp(ext, "") == 0)
			fileList.push_back(filename);
	}, szDirToCompress);

	std::string compressedDir = szDirCompressed;
	normalizeDirName(compressedDir);

	std::string strCommand;
	std::string batFile = strWorkingDir + "test7z.bat";
	std::string listFile = strWorkingDir + "listfile.txt";
	for (const std::string& filename : fileList)
	{
		//printf("file: %s\n", filename.c_str());
		std::string origFile = szDirToCompress + filename;
		std::string compressFile = compressedDir + filename + ".7z";

		if (regenerate)
		{
			//生成listfile.txt
			{
				FILE* file = fopen(listFile.c_str(), "wt");
				ASSERT(file);

				fprintf(file, "%s\n", filename.c_str());

				fclose(file);
			}

			//生成bat文件
			{
				std::string strListFile = "../listfile.txt";

				FILE* file = fopen(batFile.c_str(), "wt");
				ASSERT(file);

				fprintf(file, "cd \"%s\"", szDirToCompress);
				fprintf(file, "\n");

				std::string format = "\"%s7z.exe\" a " + std::string(szOptions) + " \"%s\" @\"%s\"";
				strCommand = std_string_format(format.c_str(), strWorkingDir.c_str(), compressFile.c_str(), strListFile.c_str());

				fprintf(file, strCommand.c_str());
				fprintf(file, "\n");

				fprintf(file, "cd \"%s\"", strWorkingDir.c_str());
				fprintf(file, "\n");

				fclose(file);
			}

			//执行bat文件
			if (system(batFile.c_str()) != 0)	//if (RunProcess("7z.exe", strCommand))
			{
				printf("system调用错误! %s\r\n", batFile.c_str());
				g_pAFramework->Printf("system调用错误! %s\r\n", batFile.c_str());
			}

			FileOperate::UDeleteFile(batFile.c_str());
			FileOperate::UDeleteFile(listFile.c_str());
		}
		
		uint32_t compressedSize = ASys::GetFileSize(compressFile.c_str());
		uint32_t origSize = ASys::GetFileSize(origFile.c_str());

		SFileCompressInfo* pCompressInfo = new SFileCompressInfo;
		pCompressInfo->filename = filename;
		pCompressInfo->origSize = origSize;
		pCompressInfo->compressedSize = compressedSize;

		compressFileMap[filename] = pCompressInfo;
	}

	return compressFileMap;
}

bool copyFile(const char* srcDirName, const char* filename, const char* destDirName)
{
	std::string strSrcDir = srcDirName;
	normalizeDirName(strSrcDir);
	std::string strDestDir = destDirName;
	normalizeDirName(strDestDir);

	std::string strSrcFileName = strSrcDir + filename;
	std::string strDestFileName = strDestDir + filename;

	FileOperate::MakeDir(strDestFileName.c_str());

	FILE* srcFile = fopen(strSrcFileName.c_str(), "rb");
	if (!srcFile)
	{
		ASSERT(false);
		return false;
	}
	FILE* destFile = fopen(strDestFileName.c_str(), "wb");
	if (!destFile)
	{
		fclose(srcFile);
		ASSERT(false);
		return false;
	}

	uint32_t filesize = ASys::GetFileSize(strSrcFileName.c_str());
	auto pBuffer = new unsigned char[filesize];
	fread(pBuffer, 1, filesize, srcFile);
	fclose(srcFile);

	fwrite(pBuffer, 1, filesize, destFile);
	fclose(destFile);

	delete[] pBuffer;
	return true;
}

bool doUnpackFrom7z(const char* srcFile, const char* destDir, uint32_t& uncompressMs)
{
	bool bRet = true;
	SevenZReader* reader = SevenZReader_Init(srcFile);

	if (!reader)
	{
		bRet = false;
		printf("SevenZReader_Init Failed!\r\n", srcFile);
		g_pAFramework->Printf("SevenZReader_Init Failed!\r\n", srcFile);
		return bRet;
	}

	std::string strDestDir = destDir;
	normalizeDirName(strDestDir);

	int fileCount = SevenZReader_GetFileCount(reader);
	for (int i = 0; i < fileCount; ++i)
	{
		if (SevenZReader_IsDir(reader, i))
			continue;

		const char* szName = SevenZReader_GetFileName(reader, i);
		if (szName == NULL)
		{
			bRet = false;
			printf("SevenZReader_GetFileName Failed! %d\r\n", i);
			g_pAFramework->Printf("SevenZReader_GetFileName Failed! %d\r\n", i);
			break;
		}

		std::string name = szName;
		printf("Process %s\r\n", name.c_str());
		g_pAFramework->Printf("Process %s\r\n", name.c_str());

		uint32_t last = ASys::GetMilliSecond();

		const unsigned char* pData;
		int nDataSize;
		if (!SevenZReader_ExtractFile(reader, i, &pData, &nDataSize))
		{
			bRet = false;
			printf("SevenZReader_ExtractFile Failed! %d\r\n", i);
			g_pAFramework->Printf("SevenZReader_ExtractFile Failed! %d\r\n", i);
			break;
		}

		uncompressMs = ASys::GetMilliSecond() - last;

		std::string filename = strDestDir + szName;
		FileOperate::MakeDir(filename.c_str());
		ASys::ChangeFileAttributes(filename.c_str(), S_IRWXU);

		FILE* destFile = fopen(filename.c_str(), "wb");
		if (!destFile)
		{
			fclose(destFile);
			ASSERT(false);
			break;
		}

		fwrite(pData, 1, nDataSize, destFile);
		fclose(destFile);
	}

	SevenZReader_Destroy(reader);

	return bRet;
}
