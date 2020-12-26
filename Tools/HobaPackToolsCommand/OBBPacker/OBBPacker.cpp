#include "OBBPacker.h"
#include "AFramework.h"
#include "stringext.h"
#include "function.h"
#include "FileOperate.h"
#include "ASys.h"
#include <memory>
#include <algorithm>
#include "AFilePackage.h"

#define OBB_SIZE_LIMIT    (2000 * 1024 * 1024)

bool CollectJupFiles(std::vector<SJupFileEntry>& jupFileList, std::vector<SJupFileEntry>& jupFileList2, const char* ext, const std::string& baseVersion, const std::string& nextVersion, const std::string& jupDir);
bool FindVersionPair(const std::vector<SJupFileEntry>& pairList, const ELEMENT_VER& vBase, const ELEMENT_VER& vLatest, const ELEMENT_VER& curVer, SJupFileEntry& verPair);
bool GenerateOBB(const std::vector<SJupFileEntry>& jupFileList, const char* ext, const std::string& strWorkDir, const std::string& strJupDir, const std::string& obbFileName);

//jupdir obbdir expansion-version package-name
//int versionCode = firstVer * 10000 * 1000 + secondVer * 10000 + thirdVer * 10;
int main(int argc, char* argv[])
{
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

	if (argc != 7)
	{
		printf("param error!\r\n");
		g_pAFramework->Printf("param error!\r\n");

		printf("OBBPacker, usage: OBBPacker.exe <JupDir> <OBBDir> <expansion-version> <package-name>\n");
		g_pAFramework->Printf("generate base version.txt, usage: HobaPackToolsCommand.exe\n<BaseVersion> \n<OutputPath>\n");

		return -1;
	}

	std::string baseVer = argv[1];
	std::string nextVer = argv[2];
	std::string jupDir = argv[3];
	std::string obbDir = argv[4];
	std::string expansionVersion = argv[5];
	std::string packageName = argv[6];

	//
	printf("baseVer: %s\r\n", baseVer.c_str());
	g_pAFramework->Printf("baseVer: %s\r\n", baseVer.c_str());
	printf("nextVer: %s\r\n", nextVer.c_str());
	g_pAFramework->Printf("nextVer: %s\r\n", nextVer.c_str());
	printf("jupDir: %s\r\n", jupDir.c_str());
	g_pAFramework->Printf("jupDir: %s\r\n", jupDir.c_str());
	printf("obbDir: %s\r\n", obbDir.c_str());
	g_pAFramework->Printf("obbDir: %s\r\n", obbDir.c_str());
	printf("expansionVersion: %s\r\n", expansionVersion.c_str());
	g_pAFramework->Printf("expansionVersion: %s\r\n", expansionVersion.c_str());
	printf("packageName: %s\r\n", packageName.c_str());
	g_pAFramework->Printf("packageName: %s\r\n", packageName.c_str());


	std::string strFullObbDir = strWorkDir + obbDir;
	normalizeDirName(strFullObbDir);

	//创建obbDir
	{
		FileOperate::DeleteDir(strFullObbDir.c_str());
		FileOperate::MakeDir(strFullObbDir.c_str());
	}

	std::string mainOBBFileName = strFullObbDir + std_string_format("main.%s.%s.obb", expansionVersion.c_str(), packageName.c_str());
	std::string patchOBBFileName = strFullObbDir + std_string_format("patch.%s.%s.obb", expansionVersion.c_str(), packageName.c_str());


	bool useJup = false; //std::string::npos == strOutputPath.find("longtu-trunk");
	printf("useJup? %d\r\n", useJup);
	g_pAFramework->Printf("useJup? %d\r\n", useJup);

	const char* ext = useJup ? "jup" : "pck";

	//收集并检查目录中的jup文件
	std::vector<SJupFileEntry> mainJupFileList, patchJupFileList;
	if (!CollectJupFiles(mainJupFileList, patchJupFileList, ext, baseVer, nextVer, jupDir))
	{
		printf("CollectJupFiles Fail\r\n");
		g_pAFramework->Printf("CollectJupFiles Fail\r\n");

		goto FAIL;
	}

	if (!mainJupFileList.empty())
	{
		printf("Generate Main OBB...\r\n");
		g_pAFramework->Printf("Generate Main OBB...\r\n");
		for (const auto& entry : mainJupFileList)
		{
			std::string fileName = entry.ToFileName(ext);
			printf("Main OBB file: %s\r\n", fileName.c_str());
			g_pAFramework->Printf("Main OBB file : %s\r\n", fileName.c_str());
		}

		if (!GenerateOBB(mainJupFileList, ext, strWorkDir, jupDir, mainOBBFileName))
		{
			printf("GenerateOBB Fail, %s\r\n", mainOBBFileName.c_str());
			g_pAFramework->Printf("GenerateOBB Fail, %s\r\n", mainOBBFileName.c_str());

			goto FAIL;
		}

		printf("Main OBB file generated, %s Size: %u\r\n", mainOBBFileName.c_str(), ASys::GetFileSize(mainOBBFileName.c_str()));
		g_pAFramework->Printf("Main OBB file generated, %s Size: %u\r\n", mainOBBFileName.c_str(), ASys::GetFileSize(mainOBBFileName.c_str()));
	}

	if (!patchJupFileList.empty())
	{
		printf("Generate Patch OBB...\r\n");
		g_pAFramework->Printf("Generate Patch OBB...\r\n");
		for (const auto& entry : patchJupFileList)
		{
			std::string fileName = entry.ToFileName(ext);
			printf("Patch OBB file: %s\r\n", fileName.c_str());
			g_pAFramework->Printf("Patch OBB file : %s\r\n", fileName.c_str());
		}

		if (!GenerateOBB(patchJupFileList, ext, strWorkDir, jupDir, patchOBBFileName))
		{
			printf("GenerateOBB Fail, %s\r\n", patchOBBFileName.c_str());
			g_pAFramework->Printf("GenerateOBB Fail, %s\r\n", patchOBBFileName.c_str());

			goto FAIL;
		}

		printf("Patch OBB file generated, %s Size: %u\r\n", patchOBBFileName.c_str(), ASys::GetFileSize(patchOBBFileName.c_str()));
		g_pAFramework->Printf("Patch OBB file generated, %s Size: %u\r\n", patchOBBFileName.c_str(), ASys::GetFileSize(patchOBBFileName.c_str()));
	}

	printf("OBBPacker Success!\r\n");
	g_pAFramework->Printf("OBBPacker Success!\r\n");

	g_pAFramework->Release();

	return 0;

FAIL:
	printf("End OBBPacker, Fail\r\n");
	g_pAFramework->Printf("End OBBPacker, Fail\r\n");

	g_pAFramework->Release();
	getchar();
	return -1;
}

bool CollectJupFiles(std::vector<SJupFileEntry>& jupFileList, std::vector<SJupFileEntry>& jupFileList2, const char* ext, const std::string& baseVersion, const std::string& nextVersion, const std::string& jupDir)
{
	std::string strJupDir = jupDir;
	normalizeDirName(strJupDir);

	ELEMENT_VER vBase;
	if (!vBase.Parse(baseVersion))
	{
		ASSERT(false);
		return false;
	}

	ELEMENT_VER vNext;
	if (!vNext.Parse(nextVersion))
	{
		ASSERT(false);
		return false;
	}

	printf("收集Jup文件: %s\r\n", strJupDir.c_str());
	g_pAFramework->Printf("收集Jup文件: %s\r\n", strJupDir.c_str());

	std::set<ELEMENT_VER> versionSet;
	std::vector<SJupFileEntry> updateFileList;

	//找所有的jup文件
	Q_iterateFiles(strJupDir.c_str(),
		[&versionSet, &updateFileList, vBase, ext](const char* filename)
	{
		if (!hasFileExtensionA(filename, ext))
			return;

		// 		if (6 != sscanf(filename, "%d.%d.%d-%d.%d.%d.jup", &verOld[0], &verOld[1], &verOld[2], &verNew[0], &verNew[1], &verNew[2]))
		// 			return;

		SJupFileEntry entry;
		//解析版本号
		{
			char shortFileName[QMAX_PATH];
			getFileNameNoExtensionA(filename, shortFileName, QMAX_PATH);
			std::string strFileName = shortFileName;

			std::vector<std::string> arr;
			std_string_split(strFileName, '-', arr);
			if (arr.size() != 2 ||
				!entry.vOld.Parse(arr[0]) ||
				!entry.vNew.Parse(arr[1]))
			{
				ASSERT(false);
				return;
			}
		}

		if (entry.vOld < vBase)
			return;

		versionSet.insert(entry.vOld);
		versionSet.insert(entry.vNew);

		updateFileList.push_back(entry);

	},
		strJupDir.c_str());

	std::sort(updateFileList.begin(), updateFileList.end());

	if (updateFileList.empty() || versionSet.empty())
	{
		printf("要更新的jup文件数量为0!\r\n");
		g_pAFramework->Printf("要更新的jup文件数量为0!\r\n");

		return false;
	}

	for (auto ver : versionSet)
	{
		std::string str = ver.ToString();
		printf("version: %s\r\n", str.c_str());
		g_pAFramework->Printf("version: %s\r\n", str.c_str());
	}

	//检查Version
	{
		if ((*versionSet.begin()) != vBase)
		{
			std::string strBegin = (*versionSet.begin()).ToString();
			std::string strBase = vBase.ToString();

			printf("jup不包括BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin.c_str(), strBase.c_str());
			g_pAFramework->Printf("jup不包括BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin.c_str(), strBase.c_str());
			return false;
		}

		if ((*versionSet.rbegin()) != vNext)
		{
			std::string strNext = vNext.ToString();

			printf("jup不包括NextVersion! vNext: %s\r\n", strNext.c_str());
			g_pAFramework->Printf("jup不包括NextVersion! vNext: %s\r\n", strNext.c_str());
			return false;
		}
	}

	//检查VersionPair的完整性，是否能从base升级到latest
	{
		for (const SJupFileEntry& entry : updateFileList)
		{
			ELEMENT_VER curVer = vBase;
			SJupFileEntry pair;
			pair.vOld = vBase;
			pair.vNew = vBase;

			while (pair.vNew < vNext)
			{
				bool bFound = FindVersionPair(updateFileList, vBase, vNext, curVer, pair);
				if (!bFound)
				{
					std::string strVer = curVer.ToString();
					printf("无法找到版本对应的升级jup! curVer: %s\r\n", strVer.c_str());
					g_pAFramework->Printf("无法找到版本对应的升级jup! curVer: %s\r\n", strVer.c_str());
					return false;
				}
				curVer = pair.vNew;
			}
		}
	}

	//检查文件列表的大小，如果超过2G则断开
	uint64_t totalSize0 = 0;
	uint64_t totalSize1 = 0;
	for (const auto& entry : updateFileList)
	{
		std::string fileName = strJupDir + entry.ToFileName(ext);
		uint64_t fileSize = (uint64_t)ASys::GetFileSize(fileName.c_str());

		if (totalSize0 + fileSize < OBB_SIZE_LIMIT)
		{
			jupFileList.push_back(entry);
			totalSize0 += fileSize;
		}
		else
		{
			totalSize0 = OBB_SIZE_LIMIT;
		}

		if (totalSize0 == OBB_SIZE_LIMIT)
		{
			if (totalSize1 + fileSize < OBB_SIZE_LIMIT)
			{
				jupFileList2.push_back(entry);
				totalSize1 += fileSize;
			}
			else
			{
				totalSize1 = OBB_SIZE_LIMIT;
			}
		}
	}

	return true;
}

bool FindVersionPair(const std::vector<SJupFileEntry>& pairList, const ELEMENT_VER& vBase, const ELEMENT_VER& vLatest, const ELEMENT_VER& curVer, SJupFileEntry& verPair)
{
	if (pairList.empty() || curVer == vLatest || curVer > vLatest || curVer < vBase)
		return false;

	ELEMENT_VER vOld(-1, 0, 0, 0, 0);
	for (const auto& pair : pairList)
	{
		if (curVer == pair.vOld)
		{
			vOld = pair.vOld;
			break;
		}
	}

	if (vOld.iVer0 < 0)
		return false;

	//找最高的目标版本
	int iVer = -1;
	ELEMENT_VER verNew = vBase;
	for (int i = 0; i < (int)pairList.size(); ++i)
	{
		if (pairList[i].vOld != vOld)
			continue;

		if (pairList[i].vNew > verNew)
		{
			iVer = i;
			verNew = pairList[i].vNew;
		}
	}

	if (iVer < 0)	//没有找到
		return false;

	verPair = pairList[iVer];
	return true;
}

bool GenerateOBB(const std::vector<SJupFileEntry>& jupFileList, const char* ext, const std::string& strWorkDir, const std::string& strJupDir, const std::string& obbFileName)
{
	FileOperate::MakeDir(obbFileName.c_str());

	AFilePackage pckFile;
	if (!pckFile.Open(obbFileName.c_str(), "", AFilePackage::CREATENEW))
	{
		printf("Create Pck Failed: %s\r\n", obbFileName.c_str());
		g_pAFramework->Printf("Create Pck Failed: %s\r\n", obbFileName.c_str());
		return false;
	}

	std::string fullJupDir = strWorkDir + strJupDir;
	normalizeDirName(fullJupDir);
	for (const auto& entry : jupFileList)
	{
		std::string shortFileName = entry.ToFileName(ext);
		std::string fileName = fullJupDir + shortFileName;

		FILE* file = fopen(fileName.c_str(), "rb");
		if (file == nullptr)
		{
			printf("Open File Failed: %s\r\n", fileName.c_str());
			g_pAFramework->Printf("Open File Failed: %s\r\n", fileName.c_str());
			return false;
		}

		fseek(file, 0, SEEK_END);
		auint32 dwFileSize = ftell(file);
		auint32 dwCompressedSize = (auint32)(dwFileSize * 1.1f) + 12;

		unsigned char* pFileContent = (unsigned char*)malloc(dwFileSize);
		unsigned char* pFileCompressed = (unsigned char*)malloc(dwCompressedSize);

		fseek(file, 0, SEEK_SET);
		fread(pFileContent, dwFileSize, 1, file);
		fclose(file);

		int nRet = AFilePackage::Compress(pFileContent, dwFileSize, pFileCompressed, &dwCompressedSize);
		if (-2 == nRet)
		{
			printf("Compress File Failed: %s\r\n", fileName.c_str());
			g_pAFramework->Printf("Compress File Failed: %s\r\n", fileName.c_str());
			return false;
		}

		if (0 != nRet)
		{
			dwCompressedSize = dwFileSize;
		}

		if (dwCompressedSize < dwFileSize)
		{
			if (!pckFile.AppendFileCompressed(shortFileName.c_str(), pFileCompressed, dwFileSize, dwCompressedSize))
			{
				printf("AppendFileCompressed Failed: %s\r\n", shortFileName.c_str());
				g_pAFramework->Printf("AppendFileCompressed Failed: %s\r\n", shortFileName.c_str());

				free(pFileCompressed);
				free(pFileContent);
				return false;
			}
		}
		else
		{
			if (!pckFile.AppendFileCompressed(shortFileName.c_str(), pFileContent, dwFileSize, dwFileSize))
			{
				printf("AppendFileCompressed2 Failed: %s\r\n", shortFileName.c_str());
				g_pAFramework->Printf("AppendFileCompressed2 Failed: %s\r\n", shortFileName.c_str());

				free(pFileCompressed);
				free(pFileContent);
				return false;
			}

		}

		free(pFileContent);
		free(pFileCompressed);
	}

	printf("Pck: %s Total %d files, %d bytes\n", obbFileName.c_str(), pckFile.GetFileNumber(), pckFile.GetFileHeader().dwEntryOffset);
	g_pAFramework->Printf("Pck: %s Total %d files, %d bytes\n", obbFileName.c_str(), pckFile.GetFileNumber(), pckFile.GetFileHeader().dwEntryOffset);

	pckFile.Flush();
	pckFile.Close();
	
	return true;
}
