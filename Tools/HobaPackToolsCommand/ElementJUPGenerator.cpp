#include "ElementJUPGenerator.h"
#include "AFramework.h"
#include "FileOperate.h"
#include "AFI.h"
#include "function.h"
#include "VersionMan.h"
#include "windows.h"
#include <shellapi.h>
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

bool CElementJUPGenerator::Init(const AString& strLastPath, const AString& strNextPath, const AString& strJupGeneratePath, bool bSmallPack)
{
	TCHAR szWorkDir[MAX_PATH];
	GetCurrentDirectory(MAX_PATH, szWorkDir);
	m_strWorkDir = szWorkDir;
	m_strWorkDir.NormalizeDirName();
	//m_strTmpDir = m_strWorkDir + "tmp/";
	//FileOperate::MakeDir(m_strTmpDir);
	m_strCompressDir = m_strWorkDir + "compress/";
	FileOperate::MakeDir(m_strCompressDir);

	char szCurrentDir[MAX_PATH];
	GetCurrentDirectory(MAX_PATH, szCurrentDir);

	char szRet[MAX_PATH];
	Q_fullpath(strJupGeneratePath, szRet, MAX_PATH);
	m_SConfig.JupGeneratePath = szRet;

	Q_fullpath(strLastPath, szRet, MAX_PATH);
	m_SConfig.LastVersionPath = szRet;

	Q_fullpath(strNextPath, szRet, MAX_PATH);
	m_SConfig.NextVersionPath = szRet;

	m_SConfig.bSmallPack = bSmallPack;

	return true;
}

void CElementJUPGenerator::SetPlatform(const AString& strPlatformType)
{
	if (strPlatformType.CompareNoCase("Windows") == 0)
		m_PlatformType = EPlatformType::Windows;
	else if (strPlatformType.CompareNoCase("iOS") == 0)
		m_PlatformType = EPlatformType::iOS;
	else if (strPlatformType.CompareNoCase("Android") == 0)
		m_PlatformType = EPlatformType::Android;
	else
	{
		printf("Unknown Platform! %s\r\n", strPlatformType);
		g_pAFramework->Printf("Unknown Platform! %s\r\n", strPlatformType);
	}
}

void CElementJUPGenerator::SetVersion(const AString& strBaseVersion, const AString& strLastVersion, const AString& strNextVersion)
{
	m_SVersion.BaseVersion = strBaseVersion;
	m_SVersion.LastVersion = strLastVersion;
	m_SVersion.NextVersion = strNextVersion;
}

bool CElementJUPGenerator::GenerateUpdateList(const SVersion& sversion, SJupContent& jupContent) const
{
	ELEMENT_VER verOld;
	if (!verOld.Parse(sversion.LastVersion))
	{
		ASSERT(false);
		return false;
	}
	
	ELEMENT_VER verNew;
	if (!verNew.Parse(sversion.NextVersion))
	{
		ASSERT(false);
		return false;
	}

	if (verNew < verOld || verNew == verOld)
	{
		printf("Is not a new version! Check it first!\r\n");
		g_pAFramework->Printf("Is not a new version! Check it first!\r\n");

		return false;
	}

	jupContent.verOld = verOld;
	jupContent.verNew = verNew;
	jupContent.UpdateList.clear();

	AString strPlatformAssetBundle = "AssetBundles/";
	AString strPlatformAudio = "Audio/GeneratedSoundBanks/";
	switch (m_PlatformType)
	{
	case CElementJUPGenerator::Windows:
		strPlatformAssetBundle += "Windows";
		strPlatformAudio += "Windows";
		break;
	case CElementJUPGenerator::iOS:
		strPlatformAssetBundle += "iOS";
		strPlatformAudio += "iOS";
		break;
	case CElementJUPGenerator::Android:
		strPlatformAssetBundle += "Android";
		strPlatformAudio += "Android";
		break;
	default:
		break;
	}

	AString strPlatformUpdateAssetBundle = strPlatformAssetBundle + "/Update";
	AString strNextPath = this->m_SConfig.NextVersionPath;

	Q_iterateFiles(strNextPath, "*.*",
		[strPlatformAssetBundle, strPlatformAudio, strPlatformUpdateAssetBundle, &jupContent, this](const char* filename)
	{
		//platform过滤
		//if (strstr(filename, "AssetBundles/") != 0 && strstr(filename, strPlatformAssetBundle) == 0)
		if (strstr(filename, "AssetBundles/") == (const char*)filename && strstr(filename, strPlatformAssetBundle) != (const char*)filename)
		{
			printf("文件被平台过滤! filename: %s, platform: %s \r\n", filename, strPlatformAssetBundle);
			g_pAFramework->Printf("文件被平台过滤! filename: %s, platform: %s \r\n", filename, strPlatformAssetBundle);

			return;
		}

		if (strstr(filename, "Audio/GeneratedSoundBanks/") == (const char*)filename && strstr(filename, strPlatformAudio) != (const char*)filename)
		{
			printf("文件被平台过滤! filename: %s, platform: %s \r\n", filename, strPlatformAudio);
			g_pAFramework->Printf("文件被平台过滤! filename: %s, platform: %s \r\n", filename, strPlatformAudio);

			return;
		}

		//跳过ReadMe.txt
		if (strstr(filename, "ReadMe.txt") == (const char*)filename)
		{
			return;
		}

		//update过滤
		if (m_SConfig.bSmallPack)	//小包
		{
			if (m_SVersion.BaseVersion != m_SVersion.LastVersion)		 //如果lastVersion和baseVersion不等，则只考虑 AssetBundles/<Platform>/Update 下的文件
			{
				//if (strstr(filename, strPlatformAssetBundle) != 0 && strstr(filename, strPlatformUpdateAssetBundle) == 0)
				if (strstr(filename, strPlatformAssetBundle) == (const char*)filename && strstr(filename, strPlatformUpdateAssetBundle) != (const char*)filename)
					return;
			}
		}
		else	 //大包，只考虑 AssetBundles / <Platform> / Update 下的文件
		{
			if (strstr(filename, strPlatformAssetBundle) == (const char*)filename && strstr(filename, strPlatformUpdateAssetBundle) != (const char*)filename)
				return;
		}

		bool bNoCompress = true;
		//只对Lua, Configs目录下的文件使用zlib压缩，因为在解压时大文件需要额外的大内存，且assetbundle文件压缩率本就不高
// 		if (strstr(filename, "Lua/") == (const char*)filename || strstr(filename, "Configs/") == (const char*)filename)
// 		{
// 			bNoCompress = false;
// 		}

		AString strOldDir = this->m_SConfig.LastVersionPath;
		strOldDir.NormalizeDirName();
		AString strNewDir = this->m_SConfig.NextVersionPath;
		strNewDir.NormalizeDirName();

		AString strNewFile = strNewDir + filename;
		AString strOldFile = strOldDir + filename;

		char md5New[64];
		char md5Old[64];
		if (!FileOperate::CalcFileMd5(strNewFile, md5New))
		{
			ASSERT(false);
			printf("计算md5错误! %s \r\n", strNewFile);
			g_pAFramework->Printf("计算md5错误! %s \r\n", strNewFile);

			return;
		}

		if (FileOperate::FileExist(strOldFile))		//如果同名文件在old目录中存在，比较md5
		{
			bool bAddToUpdateList = false;

/*
			if (m_SVersion.BaseVersion == m_SVersion.LastVersion)		//第一个版本lua和data添加到更新列表
			{
				if (strstr(filename, "Lua/") == (const char*)filename || strstr(filename, "Data/") == (const char*)filename)
				{
					bAddToUpdateList = true;
				}
			}
*/

			if (!FileOperate::CalcFileMd5(strOldFile, md5Old))
			{
				ASSERT(false);
				printf("计算md5错误! %s \r\n", strOldFile);
				g_pAFramework->Printf("计算md5错误! %s \r\n", strOldFile);

				return;
			}

			if (!bAddToUpdateList)
			{
				bAddToUpdateList = FileOperate::Md5Cmp(md5New, md5Old) != 0;
			}

			if (bAddToUpdateList)		//添加到更新列表
			{
				int originSize = FileOperate::GetFileSize(strNewFile);

				const char* tmpFileName = "./tmp.compressed";
				if (!MakeCompressedFile(strNewFile, tmpFileName, bNoCompress))
				{
					printf("创建临时压缩文件错误！\r\n");
					g_pAFramework->Printf("创建临时压缩文件错误！\r\n");

					return;
				}

				char md5[64];
				if (!FileOperate::CalcFileMd5(tmpFileName, md5))
				{
					ASSERT(false);
					printf("临时文件计算md5错误!\r\n");
					g_pAFramework->Printf("临时文件计算md5错误!\r\n");

					return;
				}

				SUpdateFileEntry entry;
				entry.strMd5 = md5;
				entry.strFileName = filename;
				entry.nSize = (int64_t)FileOperate::GetFileSize(tmpFileName);

				jupContent.UpdateList.push_back(entry);

				printf("filename: %s, size: %lld, MD5: %s\r\n", entry.strFileName, entry.nSize, entry.strMd5);
				g_pAFramework->Printf("filename: %s, size: %lld, MD5: %s", entry.strFileName, entry.nSize, entry.strMd5);
			}
		}
		else   //添加到更新列表
		{
			int originSize = FileOperate::GetFileSize(strNewFile);

			const char* tmpFileName = "./tmp.compressed";
			if (!MakeCompressedFile(strNewFile, tmpFileName, bNoCompress))
			{
				printf("创建临时压缩文件错误！\r\n");
				g_pAFramework->Printf("创建临时压缩文件错误！\r\n");

				return;
			}

			char md5[64];
			if (!FileOperate::CalcFileMd5(tmpFileName, md5))
			{
				ASSERT(false);
				printf("临时文件计算md5错误!\r\n");
				g_pAFramework->Printf("临时文件计算md5错误!\r\n");

				return;
			}

			SUpdateFileEntry entry;
			entry.strMd5 = md5;
			entry.strFileName = filename;
			entry.nSize = (int64_t)FileOperate::GetFileSize(tmpFileName);
			
			jupContent.UpdateList.push_back(entry);

			printf("filename: %s, size: %lld, MD5: %s\r\n", entry.strFileName, entry.nSize, entry.strMd5);
			g_pAFramework->Printf("filename: %s, size: %lld, MD5: %s", entry.strFileName, entry.nSize, entry.strMd5);
		}
	},
	strNextPath);

	std::sort(jupContent.UpdateList.begin(), jupContent.UpdateList.end());

	//inc文件
	GenerateIncFileString(jupContent, jupContent.IncString);

	return true;
}

void CElementJUPGenerator::PrintUpdateList(const SJupContent& jupContent) const
{
	for (const auto& entry : jupContent.UpdateList)
	{
		if (strstr(entry.strFileName, "AssetBundles") != 0)
		{
			printf("%s\r\n", entry.strFileName);
			g_pAFramework->Printf("%s\r\n", entry.strFileName);
		}
	}
}

void CElementJUPGenerator::GenerateIncFileString(const SJupContent& jupContent, std::vector<AString>& strInc) const
{
	strInc.clear();

	AString strTmp;
	aint64 nTotalSize = 0;
	for (const auto& entry : jupContent.UpdateList)
	{
		nTotalSize += entry.nSize;
	}

	strTmp.Format(g_incHeader,			//"# %d.%d.%d.%d %d.%d.%d.%d %s %lld"
		jupContent.verOld.iVer0,
		jupContent.verOld.iVer1,
		jupContent.verOld.iVer2,
		jupContent.verOld.iVer3,
		jupContent.verNew.iVer0,
		jupContent.verNew.iVer1,
		jupContent.verNew.iVer2,
		jupContent.verNew.iVer3,
		PROJECT_NAME,
		nTotalSize);

	strInc.push_back(strTmp);

	for (const auto& entry : jupContent.UpdateList)
	{
		strTmp.Format("%s %s",
			entry.strMd5,
			entry.strFileName);
		strInc.push_back(strTmp);
	}
}

bool CElementJUPGenerator::GenerateJup(const SJupContent& jupContent)
{
	AString strJupFile = m_SConfig.JupGeneratePath;
	strJupFile.NormalizeDirName();

	AString strOld, strNew;
	jupContent.verOld.ToString(strOld);
	jupContent.verNew.ToString(strNew);

	AString strFile;
	strFile.Format("%s-%s.jup", strOld, strNew);
	strJupFile += strFile;

	printf("GenerateJup %s......\r\n", (const char*)strJupFile);
	g_pAFramework->Printf("GenerateJup %s......\r\n", (const char*)strJupFile);

	//必须先删掉原来的jup文件
	{
		FileOperate::UDeleteFile(strJupFile);
	}

	if (jupContent.UpdateList.empty())
	{
		printf("要升级的内容为空，不能生成jup文件!\r\n");
		g_pAFramework->Printf("要升级的内容为空，不能生成jup文件!\r\n");

		return false;
	}

	
	std::set<AString>	 mapFileList;			//排序的文件列表
	mapFileList.insert("inc");
	for (SUpdateFileEntry entry : jupContent.UpdateList)
	{
		mapFileList.insert(entry.strFileName);
	}

	//2017.3.2直接清空tmp目录，生成更新内容
	



#if KEEP_TMP_FOLDER
	AString strTmpDirAbs;
	AString strTmpDir;
	//if (!CompareDir(m_strCompressDir, strTmpDirAbs, mapFileList))		//和tmpDir中的内容做md5比较，如果内容变化，则重新生成更新内容到tmp
	{
		strTmpDir.Format("tmp-%s-%s/", strOld, strNew);
		strTmpDirAbs = m_strWorkDir + strTmpDir;

		if (!ReGenerateJupContentToDir(jupContent, strTmpDirAbs))
		{
			printf("无法生成更新内容到 %s!\r\n", strTmpDirAbs);
			g_pAFramework->Printf("无法生成更新内容到 %s!\r\n", strTmpDirAbs);

			return false;
		}
	}

#else

	AString strTmpDir = "compress/";
	//重新生成更新内容到 compress 目录
	if (!ReGenerateJupContentToDir(jupContent, m_strCompressDir))
	{
		printf("无法生成更新内容到 %s!\r\n", m_strCompressDir);
		g_pAFramework->Printf("无法生成更新内容到 %s!\r\n", m_strCompressDir);

		FileOperate::DeleteDir(m_strCompressDir);
		FileOperate::UDeleteFile("./tmp.compressed");
		return false;
	}

#endif

	//生成listfile.txt
	{
		FILE* file = fopen(m_strWorkDir + "listfile.txt", "wt");
		if (!file)
		{
			printf("无法创建listfile.txt文件!\r\n");
			g_pAFramework->Printf("无法创建listfile.txt文件!\r\n");

			FileOperate::DeleteDir(m_strCompressDir);
			FileOperate::UDeleteFile("./tmp.compressed");
			return false;
		}

		for (const auto& entry : mapFileList)
		{
			fprintf(file, "%s\n", entry);
		}

		fclose(file);
	}

	//生成jup7z.bat
	AString strJup7zBat = "jup7z.bat";
	{
		FILE* file = fopen(m_strWorkDir + strJup7zBat, "wt");
		if (!file)
		{
			printf("无法创建jup7z.txt文件!\r\n");
			g_pAFramework->Printf("无法创建jup7z.txt文件!\r\n");

			FileOperate::DeleteDir(m_strCompressDir);
			FileOperate::UDeleteFile("./tmp.compressed");
			return false;
		}

		AString strCommand;
		AString strListFile = "../listfile.txt";

		fprintf(file, "cd %s", strTmpDir);
		fprintf(file, "\n");
		
		strCommand.Format("\"%s7z.exe\" a \"%s\" @\"%s\"", m_strWorkDir, strJupFile, strListFile);
		fprintf(file, strCommand);
		fprintf(file, "\n");

		fprintf(file, "cd ../");
		fprintf(file, "\n");

		fclose(file);
	}

	//调用bat, 生成jup
	{
		printf("Call %s......\r\n", strJup7zBat);
		g_pAFramework->Printf("Call %s......\r\n", strJup7zBat);

		if (system(strJup7zBat) != 0)	//if (RunProcess("7z.exe", strCommand))
		{
			printf("system调用错误! %s\r\n", strJup7zBat);
			g_pAFramework->Printf("system调用错误! %s\r\n", strJup7zBat);

			FileOperate::DeleteDir(m_strCompressDir);
			FileOperate::UDeleteFile("./tmp.compressed");
			return false;
		}
	}

	FileOperate::DeleteDir(m_strCompressDir);
	FileOperate::UDeleteFile("./tmp.compressed");

	return true;

}

bool CElementJUPGenerator::ReGenerateJupContentToDir(const SJupContent& jupContent, const AString& strDir) const 
{
	FileOperate::DeleteDir(strDir);
	FileOperate::MakeDir(strDir);

	//生成更新内容到 compress 目录
	//重新生成inc文件
	AString strIncFile = "inc";
	{
		FILE* file = fopen(strDir + strIncFile, "wt");
		if (!file)
		{
			printf("无法创建inc文件!\r\n");
			g_pAFramework->Printf("无法创建inc文件!\r\n");

			return false;
		}

		for (const auto& str : jupContent.IncString)
		{
			fprintf(file, "%s\n", str);
		}

		fclose(file);
	}

	//拷贝到本地compress目录
	AString strUpdateBase = m_SConfig.NextVersionPath;
	strUpdateBase.NormalizeDirName();

	AString strSrc, strDest;
	for (const auto& entry : jupContent.UpdateList)
	{
		const char* filename = entry.strFileName;
		bool bNoCompress = true;

		//只对Lua, Configs目录下的文件使用zlib压缩，因为在解压时大文件需要额外的大内存，且assetbundle文件压缩率本就不高
// 		if (strstr(filename, "Lua/") == (const char*)filename || strstr(filename, "Configs/") == (const char*) filename) 
// 		{
// 			bNoCompress = false;
// 		}

		strSrc = strUpdateBase + filename;
		strDest = strDir + filename;

		FileOperate::MakeDir(strDest);

		if (!MakeCompressedFile(strSrc, strDest, bNoCompress))
		{
			printf("制作压缩文件失败! 从%s到%s\r\n", strSrc, strDest);
			g_pAFramework->Printf("制作压缩文件失败! 从%s到%s\r\n", strSrc, strDest);

			return false;
		}
	}
	return true;
}


bool CElementJUPGenerator::CompareDir(const AString& leftDir, const AString& rightDir, const std::set<AString>& fileList) const
{
	AString strLeftDir = leftDir;
	strLeftDir.NormalizeDirName();

	AString strRightDir = rightDir;
	strRightDir.NormalizeDirName();

	for (AString strFile : fileList)
	{
		AString strLeftFile = strLeftDir + strFile;
		AString strRightFile = strRightDir + strFile;
		
		char md5Left[64];
		char md5Right[64];

		if (!FileOperate::FileExist(strLeftFile) || !FileOperate::FileExist(strRightFile))		//文件必须存在
			return false;

		if (!FileOperate::CalcFileMd5(strLeftFile, md5Left) || !FileOperate::CalcFileMd5(strRightFile, md5Right))	//生成md5
			return false;

		if (FileOperate::Md5Cmp(md5Left, md5Right) != 0)
			return false;
	}

	return true;
}

bool CElementJUPGenerator::GenerateVersionTxt(const SVersion& sversion) const
{
	AString strJupDir = m_SConfig.JupGeneratePath;
	strJupDir.NormalizeDirName();

	std::set<ELEMENT_VER> versionSet;
	std::vector<SJupFileEntry> updateFileList;

	ELEMENT_VER vBase;
	if (!vBase.Parse(sversion.BaseVersion))
	{
		ASSERT(false);
		return false;
	}
	ELEMENT_VER vLast;
	if (!vLast.Parse(sversion.LastVersion))
	{
		ASSERT(false);
		return false;
	}
	ELEMENT_VER vNext;
	if (!vNext.Parse(sversion.NextVersion))
	{
		ASSERT(false);
		return false;
	}
	
	printf("收集Jup文件: %s\r\n", strJupDir);
	g_pAFramework->Printf("收集Jup文件: %s\r\n", strJupDir);

	//找所有的jup文件
	Q_iterateFiles(strJupDir,
		[&versionSet, &updateFileList, vBase](const char* filename)
	{
		if (!hasFileExtensionA(filename, "jup"))
			return;

// 		if (6 != sscanf(filename, "%d.%d.%d-%d.%d.%d.jup", &verOld[0], &verOld[1], &verOld[2], &verNew[0], &verNew[1], &verNew[2]))
// 			return;
 
		SJupFileEntry entry;
		//解析版本号
		{
			char shortFileName[QMAX_PATH];
			getFileNameNoExtensionA(filename, shortFileName, QMAX_PATH);
			AString strFileName = shortFileName;

			std::vector<AString> arr;
			strFileName.Split('-', arr);
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
		strJupDir);

	std::sort(updateFileList.begin(), updateFileList.end());
	
	if (updateFileList.empty() || versionSet.empty())
	{
		printf("要更新的jup文件数量为0, 生成基础version.txt!\r\n");
		g_pAFramework->Printf("要更新的jup文件数量为0, 生成基础version.txt!\r\n");

		GenerateBaseVersionTxt(sversion.BaseVersion, strJupDir);
		return true;
	}

	for (auto ver : versionSet)
	{
		AString str;
		ver.ToString(str);
		printf("version: %s\r\n", str);
		g_pAFramework->Printf("version: %s\r\n", str);
	}

	//检查Version
	{
		if ((*versionSet.begin()) != vBase)
		{
			AString strBegin;
			AString strBase;
			(*versionSet.begin()).ToString(strBegin);
			vBase.ToString(strBase);

			printf("jup不包括BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin, strBase);
			g_pAFramework->Printf("jup不包括BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin, strBase);
			return false;
		}

		auto itr = std::find(versionSet.begin(), versionSet.end(), vLast);
		if (itr == versionSet.end())
		{
			AString strLast;
			vLast.ToString(strLast);

			printf("jup不包括LastVersion! vLast: %s\r\n", strLast);
			g_pAFramework->Printf("jup不包括LastVersion! vLast: %s\r\n", strLast);
			return false;
		}

		if ((*versionSet.rbegin()) != vNext)
		{
			AString strNext;
			vNext.ToString(strNext);

			printf("jup不包括NextVersion! vNext: %s\r\n", strNext);
			g_pAFramework->Printf("jup不包括NextVersion! vNext: %s\r\n", strNext);
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
					AString strVer;
					curVer.ToString(strVer);
					printf("无法找到版本对应的升级jup! curVer: %s\r\n", (const char*)strVer);
					g_pAFramework->Printf("无法找到版本对应的升级jup! curVer: %s\r\n", (const char*)strVer);
					return false;
				}
				curVer = pair.vNew;
			}
		}
	}

	//
	AString strTxtFile = strJupDir + "version.txt";
	FILE* file = fopen(strTxtFile, "wt");
	if (!file)
	{
		printf("无法创建version.txt文件!\r\n");
		g_pAFramework->Printf("无法创建version.txt文件!\r\n");
		return false;
	}

	fprintf(file, "Version:\t%s/%s\n", sversion.NextVersion, sversion.BaseVersion);

	fprintf(file, "Project:\t%s\n", PROJECT_NAME);

	for (const SJupFileEntry& entry : updateFileList)
	{
		AString strOld, strNew;
		entry.vOld.ToString(strOld);
		entry.vNew.ToString(strNew);
		AString strFile;
		strFile.Format("%s-%s.jup", strOld, strNew);
		AString strJupFile = strJupDir + strFile;

		char md5String[64];
		if (!FileOperate::FileExist(strJupFile))
		{
			printf("jup文件不存在, %s!\r\n", strJupFile);
			g_pAFramework->Printf("jup文件不存在, %s!\r\n", strJupFile);

			fclose(file);
			return false;
		}

		if (!FileOperate::CalcFileMd5(strJupFile, md5String))
		{
			printf("md5计算错误, %s!\r\n", strJupFile);
			g_pAFramework->Printf("md5计算错误, %s!\r\n", strJupFile);

			fclose(file);
			return false;
		}

		char filename[MAX_PATH];
		getFileNameNoExtensionA(strJupFile, filename, MAX_PATH);
		int nSize = FileOperate::GetFileSize(strJupFile);

		fprintf(file, "%s\t%s\t%d\n", filename, md5String, nSize);
	}


	fclose(file);

	return true;
}

void CElementJUPGenerator::OpenJupDir()
{
	AString strJupFile = m_SConfig.JupGeneratePath;
	strJupFile.NormalizeDirName();

	//shell要求反斜杠
	strJupFile.Replace('/', '\\');
	ShellExecute(
		NULL,
		"open",
		"Explorer.exe",
		strJupFile,
		NULL,
		SW_NORMAL);
}



bool CElementJUPGenerator::SplitJup(const SJupContent& jupContent, std::vector<SJupContent>& jupContentSplitList, int64_t nLimitSize) const
{
	ELEMENT_VER vOrigOld = jupContent.verOld;
	ELEMENT_VER vOrigNew = jupContent.verNew;

	jupContentSplitList.clear();
	int64_t nCurrentSize = 0;
	std::vector<SUpdateFileEntry>  updateFileEntries;

	for (const SUpdateFileEntry& entry : jupContent.UpdateList)
	{
		if (nCurrentSize + entry.nSize <= nLimitSize)
		{
			//添加此entry
			updateFileEntries.push_back(entry);
			nCurrentSize += entry.nSize;
		}
		else
		{
			//添加一个jupContent
			ELEMENT_VER vStart;
			ELEMENT_VER vEnd;
			if (jupContentSplitList.size() == 0)
			{
				vStart = vOrigOld;
				vEnd.Set(vStart.iVer0, vStart.iVer1, vStart.iVer2, vStart.iVer3 + 1);
			}
			else
			{
				vStart = jupContentSplitList.back().verNew;
				vEnd.Set(vStart.iVer0, vStart.iVer1, vStart.iVer2, vStart.iVer3 + 1);			   //末位加1
			}

			if (updateFileEntries.size() > 0)			//已有文件列表，结束本split
			{
				SJupContent content;
				content.verOld = vStart;
				content.verNew = vEnd;
				content.UpdateList = updateFileEntries;
				GenerateIncFileString(content, content.IncString);

				jupContentSplitList.emplace_back(content);					//添加到SplitList
			}

			//添加此entry
			{
				nCurrentSize = 0;
				updateFileEntries.clear();

				//添加此entry
				updateFileEntries.push_back(entry);
				nCurrentSize += entry.nSize;
			}

		}
	}

	if (updateFileEntries.size() > 0)		   //最后一个
	{
		//添加一个jupContent
		ELEMENT_VER vStart;
		ELEMENT_VER vEnd;
		if (jupContentSplitList.size() == 0)
		{
			vStart = vOrigOld;
			vEnd = vOrigNew;
		}
		else
		{
			vStart = jupContentSplitList.back().verNew;
			vEnd = vOrigNew;			   //末位加1
		}

		SJupContent content;
		content.verOld = vStart;
		content.verNew = vEnd;
		content.UpdateList = updateFileEntries;
		GenerateIncFileString(content, content.IncString);

		jupContentSplitList.emplace_back(content);					//添加到SplitList
	}

	return true;
}

bool CElementJUPGenerator::GenerateJupUpdateText(const std::vector<SJupContent>& jupContentList)
{
	AString strJupDir = m_SConfig.JupGeneratePath;
	strJupDir.NormalizeDirName();

	ATIME time;
	ASys::GetCurLocalTime(time, NULL);
	AString strDate;
	strDate.Format("%04d-%02d-%02d_%02d_%02d_%02d",
		time.year + 1900, time.month + 1, time.day, time.hour, time.minute, time.second);

	AString strTxtFile = strJupDir + "JupUpdateContent_" + strDate + ".txt";
	FILE* file = fopen(strTxtFile, "wt");
	if (!file)
	{
		printf("无法创建JupUpdateContent.txt文件!\r\n");
		g_pAFramework->Printf("无法创建JupUpdateContent.txt文件!\r\n");

		return false;
	}

	std::map<AString, SUpdateFileEntry> updateEntryList;
	for (const auto& jupContent : jupContentList)
	{
		updateEntryList.clear();

		AString verOld, verNew;
		jupContent.verOld.ToString(verOld);
		jupContent.verNew.ToString(verNew);

		fprintf(file, "[%s-%s.jup]\n", (const char*)verOld, (const char*)verNew);
		
		for (const auto& entry : jupContent.UpdateList)
		{
			updateEntryList[entry.strFileName] = entry;
		}

		for (const auto& kv : updateEntryList)
		{
			const auto& entry = kv.second;
			fprintf(file, "%s\t\t%s\t\t%lld\n", (const char*)entry.strFileName, (const char*)entry.strMd5, entry.nSize);
		}

		fprintf(file, "\n");

		updateEntryList.clear();
	}

	fclose(file);

	return true;
}

bool CElementJUPGenerator::FindVersionPair(const std::vector<SJupFileEntry>& pairList, const ELEMENT_VER& vBase, const ELEMENT_VER& vLatest, const ELEMENT_VER& curVer, SJupFileEntry& verPair) const
{
	if (pairList.empty() || curVer == vLatest || curVer > vLatest || curVer < vBase)
		return false;

	ELEMENT_VER vOld(-1, 0, 0, 0);
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
	for (size_t i = 0; i < pairList.size(); ++i)
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

bool CElementJUPGenerator::GenerateBaseVersionTxt(const AString& strBaseVersion, const AString& strJupGeneratePath)
{
	//
	AString strJupDir = strJupGeneratePath;
	strJupDir.NormalizeDirName();
	AString strTxtFile = strJupDir + "version.txt";
	FILE* file = fopen(strTxtFile, "wt");
	if (!file)
	{
		printf("无法创建version.txt文件!\r\n");
		g_pAFramework->Printf("无法创建version.txt文件!\r\n");

		return false;
	}

	fprintf(file, "Version:\t%s/%s\n", strBaseVersion, strBaseVersion);

	fprintf(file, "Project:\t%s\n", PROJECT_NAME);

	fclose(file);

	return true;
}

bool CElementJUPGenerator::ReadVersionText(const AString& strFileName, std::vector<SUpdateFileEntry>& entries) const
{
	entries.clear();

	AFileImage File;
	if (!File.Open("", strFileName, AFILE_OPENEXIST | AFILE_TEXT))
		return false;
	
	auint32 dwReadLen;

	char szLine[AFILE_LINEMAXLEN];
	char szMd5[256];		//compressed
	char szFileName[256];
	int64_t nSize;			//compressed

	while (File.ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
	{
		if (3 == sscanf(szLine, "%s\t%s\t%lld", szFileName, szMd5, &nSize))
		{
			SUpdateFileEntry entry;
			entry.strFileName = szFileName;
			entry.strMd5 = szMd5;
			entry.nSize = nSize;
			entries.push_back(entry);
		}
	}

	return true;
}
