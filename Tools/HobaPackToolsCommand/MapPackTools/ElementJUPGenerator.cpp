#include "ElementJUPGenerator.h"
#include "AFramework.h"
#include "FileOperate.h"
#include "AFI.h"
#include "function.h"
#include "AFileImage.h"
#include <algorithm>
#include <map>

extern "C"
{
#include "packfunc_export.h"
}

#define KEEP_TMP_FOLDER 0

CElementJUPGenerator::CElementJUPGenerator()
{
	m_PlatformType = EPlatformType::Windows;
}

bool CElementJUPGenerator::Init(const std::string& strBasePath, const std::string& strJupGeneratePath)
{
	TCHAR szWorkDir[MAX_PATH];
	GetCurrentDirectory(MAX_PATH, szWorkDir);
	m_strWorkDir = szWorkDir;
	normalizeDirName(m_strWorkDir);
	//m_strTmpDir = m_strWorkDir + "tmp/";
	//FileOperate::MakeDir(m_strTmpDir);
	m_strCompressDir = m_strWorkDir + "compress/";
	FileOperate::MakeDir(m_strCompressDir.c_str());

	char szCurrentDir[MAX_PATH];
	GetCurrentDirectory(MAX_PATH, szCurrentDir);

	char szRet[MAX_PATH];
	Q_fullpath(strJupGeneratePath.c_str(), szRet, MAX_PATH);
	m_SConfig.JupGeneratePath = szRet;
	FileOperate::MakeDir(m_SConfig.JupGeneratePath.c_str());

	Q_fullpath(strBasePath.c_str(), szRet, MAX_PATH);
	m_SConfig.BaseVersionPath = szRet;

	return true;
}

void CElementJUPGenerator::SetPlatform(const std::string& strPlatformType)
{
	if (stricmp(strPlatformType.c_str(), "Windows") == 0)
		m_PlatformType = EPlatformType::Windows;
	else if (stricmp(strPlatformType.c_str(), "iOS") == 0)
		m_PlatformType = EPlatformType::iOS;
	else if (stricmp(strPlatformType.c_str(), "Android") == 0)
		m_PlatformType = EPlatformType::Android;
	else
	{
		printf("Unknown Platform! %s\r\n", (const char*)strPlatformType.c_str());
		g_pAFramework->Printf("Unknown Platform! %s\r\n", (const char*)strPlatformType.c_str());
	}
}

void CElementJUPGenerator::SetVersion(const std::string& strBaseVersion)
{
	m_SVersion.BaseVersion = strBaseVersion;
}

bool CElementJUPGenerator::GenerateUpdateList(const SVersion& sversion,
	const std::string& name,
	const std::vector<std::string>& assetbundles,
	const std::vector<std::string>& audios,
	const std::vector<std::string>& videos,
	SJupContent& jupContent) const
{
	jupContent.Name = name;

	ELEMENT_VER verBase;
	if (!verBase.Parse(sversion.BaseVersion))
	{
		ASSERT(false);
		return false;
	}
	
	jupContent.verBase = verBase;
	jupContent.UpdateList.clear();

	std::string strPlatformAssetBundle = "AssetBundles/";
	std::string strPlatformAudio = "Audio/GeneratedSoundBanks/";
	std::string strPlatformVideo = "Video/";
	switch (m_PlatformType)
	{
	case CElementJUPGenerator::Windows:
		strPlatformAssetBundle += "Windows/";
		strPlatformAudio += "Windows/";
		break;
	case CElementJUPGenerator::iOS:
		strPlatformAssetBundle += "iOS/";
		strPlatformAudio += "iOS/";
		break;
	case CElementJUPGenerator::Android:
		strPlatformAssetBundle += "Android/";
		strPlatformAudio += "Android/";
		break;
	default:
		break;
	}

	std::string strBasePath = this->m_SConfig.BaseVersionPath;
	normalizeDirName(strBasePath);

	std::vector<std::string> updateFileList;

	for (const auto& file : assetbundles)
	{
		updateFileList.push_back(strPlatformAssetBundle + file);
	}
	for (const auto& file : audios)
	{
		updateFileList.push_back(strPlatformAudio + file);
	}
	for (const auto& file : videos)
	{
		updateFileList.push_back(strPlatformVideo + file);
	}

	for (const std::string& file : updateFileList)
	{
		std::string strNewFile = strBasePath + file;

		if (!FileOperate::FileExist(strNewFile.c_str()))
		{
			printf("文件不存在！%s\r\n", strNewFile.c_str());
			g_pAFramework->Printf("文件不存在！%s\r\n", strNewFile.c_str());
			ASSERT(false);
		}

		bool bNoCompress = true;
		//添加到更新列表
		{
			int64_t originSize = (int64_t)FileOperate::GetFileSize(strNewFile.c_str());

			const char* tmpFileName = "./tmp.compressed";
			if (!MakeCompressedFile(strNewFile.c_str(), tmpFileName, bNoCompress))
			{
				printf("创建临时压缩文件错误！\r\n");
				g_pAFramework->Printf("创建临时压缩文件错误！\r\n");

				ASSERT(false);
				return false;
			}

			char md5[64];
			if (!FileOperate::CalcFileMd5(tmpFileName, md5))
			{
				ASSERT(false);
				printf("临时文件计算md5错误!\r\n");
				g_pAFramework->Printf("临时文件计算md5错误!\r\n");

				ASSERT(false);
				return false;
			}

			SUpdateFileEntry entry;
			entry.strMd5 = md5;
			entry.strFileName = file;
			entry.nSize = (int64_t)FileOperate::GetFileSize(tmpFileName);
			entry.nOriginSize = originSize;
			
			jupContent.UpdateList.push_back(entry);

			printf("filename: %s, size: %lld, MD5: %s\r\n", entry.strFileName.c_str(), entry.nSize, entry.strMd5.c_str());
			g_pAFramework->Printf("filename: %s, size: %lld, MD5: %s", entry.strFileName.c_str(), entry.nSize, entry.strMd5.c_str());
		}
	}

	std::sort(jupContent.UpdateList.begin(), jupContent.UpdateList.end());

	//inc文件
	GenerateIncFileString(jupContent, jupContent.IncString);

	return true;
}

void CElementJUPGenerator::GenerateIncFileString(const SJupContent& jupContent, std::vector<std::string>& strInc) const
{
	strInc.clear();

	std::string strTmp;
	aint64 nTotalSize = 0;
	for (const auto& entry : jupContent.UpdateList)
	{
		nTotalSize += entry.nSize;
	}

	strTmp = std_string_format(g_incHeader,			//"# %d.%d.%d.%d.%d %d.%d.%d.%d.%d %s %lld"
		jupContent.verBase.iVer0,
		jupContent.verBase.iVer1,
		jupContent.verBase.iVer2,
		jupContent.verBase.iVer3,
		jupContent.verBase.iVer4,
		jupContent.verBase.iVer0,
		jupContent.verBase.iVer1,
		jupContent.verBase.iVer2,
		jupContent.verBase.iVer3,
		jupContent.verBase.iVer4,
		PROJECT_NAME,
		nTotalSize);

	strInc.push_back(strTmp);

	for (const auto& entry : jupContent.UpdateList)
	{
		strTmp = std_string_format("%s %s",
			entry.strMd5.c_str(),
			entry.strFileName.c_str());
		strInc.push_back(strTmp);
	}
}

bool CElementJUPGenerator::GenerateJup(const SJupContent& jupContent)
{
	std::string strJupFile = m_SConfig.JupGeneratePath;
	normalizeDirName(strJupFile);

	std::string strFile = std_string_format("%s.jup", jupContent.Name.c_str());
	strJupFile += strFile;

	printf("GenerateJup %s......\r\n", strJupFile.c_str());
	g_pAFramework->Printf("GenerateJup %s......\r\n", strJupFile.c_str());

	//必须先删掉原来的jup文件
	{
		FileOperate::UDeleteFile(strJupFile.c_str());
	}

	int64_t totalSize = 1;
	std::set<std::string>	 mapFileList;			//排序的文件列表
	mapFileList.insert("inc");
	for (const auto& entry : jupContent.UpdateList)
	{
		mapFileList.insert(entry.strFileName);
		totalSize += entry.nOriginSize;
	}


	//重新生成更新内容到 compress 目录
	if (!ReGenerateJupContentToDir(jupContent, m_strCompressDir.c_str()))
	{
		printf("无法生成更新内容到 %s!\r\n", m_strCompressDir.c_str());
		g_pAFramework->Printf("无法生成更新内容到 %s!\r\n", m_strCompressDir.c_str());

		FileOperate::DeleteDir(m_strCompressDir.c_str());
		return false;
	}

	FileOperate::DeleteDir(m_strCompressDir.c_str());

	return true;

}

bool CElementJUPGenerator::CopyFileContent(const char* srcFileName, const char* destFileName) const
{
	FILE* srcFile = fopen(srcFileName, "rb");
	if (!srcFile)
		return false;
	ASys::ChangeFileAttributes(destFileName, S_IRWXU);

	FILE* destFile = fopen(destFileName, "wb");
	if (!destFile)
	{
		fclose(srcFile);
		return false;
	}

	bool ret = true;

	auint32 nSrcSize = ASys::GetFileSize(srcFileName);
	unsigned char* pSrcBuffer = new unsigned char[nSrcSize];
	fread(pSrcBuffer, 1, nSrcSize, srcFile);
	fclose(srcFile);

	if (nSrcSize != fwrite(pSrcBuffer, 1, nSrcSize, destFile))						//写入压缩后内容
		ret = false;

	fclose(destFile);

	delete[] pSrcBuffer;

	return ret;
}

bool CElementJUPGenerator::ReGenerateJupContentToDir(const SJupContent& jupContent, const char* strDir) const 
{
	FileOperate::DeleteDir(strDir);
	FileOperate::MakeDir(strDir);

	//生成更新内容到 compress 目录
	//重新生成inc文件
	std::string strIncFile = "inc";
	{
		std::string path = std::string(strDir) + strIncFile;
		FILE* file = fopen(path.c_str(), "wt");
		if (!file)
		{
			printf("无法创建inc文件!\r\n");
			g_pAFramework->Printf("无法创建inc文件!\r\n");

			return false;
		}

		for (const auto& str : jupContent.IncString)
		{
			fprintf(file, "%s\n", str.c_str());
		}

		fclose(file);
	}

	//拷贝到本地compress目录
	std::string strUpdateBase = m_SConfig.BaseVersionPath;
	normalizeDirName(strUpdateBase);

	std::string strSrc, strDest;
	for (const auto& entry : jupContent.UpdateList)
	{
		std::string filename = entry.strFileName;

		strSrc = strUpdateBase + filename;
		strDest = std::string(strDir) + filename;

		FileOperate::MakeDir(strDest.c_str());

		if (!CopyFileContent(strSrc.c_str(), strDest.c_str()))
		{
			printf("制作压缩文件失败! 从%s到%s\r\n", strSrc.c_str(), strDest.c_str());
			g_pAFramework->Printf("制作压缩文件失败! 从%s到%s\r\n", strSrc.c_str(), strDest.c_str());

			return false;
		}
	}
	return true;
}

bool CElementJUPGenerator::GenerateVersionTxt(const SVersion& sversion) const
{
	return GenerateVersionTxt(sversion.BaseVersion, m_SConfig.JupGeneratePath);
}

bool CElementJUPGenerator::GenerateVersionTxt(const std::string& baseVersion, const std::string& jupDir)
{
	std::string strJupDir = jupDir;
	normalizeDirName(strJupDir);

	ELEMENT_VER vBase;
	if (!vBase.Parse(baseVersion))
	{
		ASSERT(false);
		return false;
	}

	printf("收集Jup文件: %s\r\n", strJupDir.c_str());
	g_pAFramework->Printf("收集Jup文件: %s\r\n", strJupDir.c_str());

	std::vector<std::string> updateFileList;

	//找所有的jup文件
	Q_iterateFiles(strJupDir.c_str(),
		[&updateFileList, vBase](const char* filename)
	{
		if (!hasFileExtensionA(filename, "jup"))
			return;

		char shortFileName[QMAX_PATH];
		getFileNameNoExtensionA(filename, shortFileName, QMAX_PATH);
		std::string strFileName = shortFileName;

		updateFileList.push_back(shortFileName);

	},
		strJupDir.c_str());

	std::sort(updateFileList.begin(), updateFileList.end());

	//
	std::string strTxtFile = strJupDir + "map.txt";

	FILE* file = fopen(strTxtFile.c_str(), "wt");
	if (!file)
	{
		printf("无法创建version.txt文件!\r\n");
		g_pAFramework->Printf("无法创建version.txt文件!\r\n");
		return false;
	}

	fprintf(file, "Version:\t%s/%s\n", baseVersion.c_str(), baseVersion.c_str());

	fprintf(file, "Project:\t%s\n", PROJECT_NAME);

	for (const std::string& entry : updateFileList)
	{
		std::string strFile = entry + ".jup";
		std::string strJupFile = strJupDir + strFile;

		char md5String[64];
		if (!FileOperate::FileExist(strJupFile.c_str()))
		{
			printf("jup文件不存在, %s!\r\n", strJupFile.c_str());
			g_pAFramework->Printf("jup文件不存在, %s!\r\n", strJupFile.c_str());

			fclose(file);
			return false;
		}

		if (!FileOperate::CalcFileMd5(strJupFile.c_str(), md5String))
		{
			printf("md5计算错误, %s!\r\n", strJupFile.c_str());
			g_pAFramework->Printf("md5计算错误, %s!\r\n", strJupFile.c_str());

			fclose(file);
			return false;
		}

		char filename[MAX_PATH];
		getFileNameNoExtensionA(strJupFile.c_str(), filename, MAX_PATH);
		int nSize = FileOperate::GetFileSize(strJupFile.c_str());

		fprintf(file, "%s\t%s\t%d\n", filename, md5String, nSize);
	}


	fclose(file);

	return true;
}
