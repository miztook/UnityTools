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
		//platform����
		//if (strstr(filename, "AssetBundles/") != 0 && strstr(filename, strPlatformAssetBundle) == 0)
		if (strstr(filename, "AssetBundles/") == (const char*)filename && strstr(filename, strPlatformAssetBundle) != (const char*)filename)
		{
			printf("�ļ���ƽ̨����! filename: %s, platform: %s \r\n", filename, strPlatformAssetBundle);
			g_pAFramework->Printf("�ļ���ƽ̨����! filename: %s, platform: %s \r\n", filename, strPlatformAssetBundle);

			return;
		}

		if (strstr(filename, "Audio/GeneratedSoundBanks/") == (const char*)filename && strstr(filename, strPlatformAudio) != (const char*)filename)
		{
			printf("�ļ���ƽ̨����! filename: %s, platform: %s \r\n", filename, strPlatformAudio);
			g_pAFramework->Printf("�ļ���ƽ̨����! filename: %s, platform: %s \r\n", filename, strPlatformAudio);

			return;
		}

		//����ReadMe.txt
		if (strstr(filename, "ReadMe.txt") == (const char*)filename)
		{
			return;
		}

		//update����
		if (m_SConfig.bSmallPack)	//С��
		{
			if (m_SVersion.BaseVersion != m_SVersion.LastVersion)		 //���lastVersion��baseVersion���ȣ���ֻ���� AssetBundles/<Platform>/Update �µ��ļ�
			{
				//if (strstr(filename, strPlatformAssetBundle) != 0 && strstr(filename, strPlatformUpdateAssetBundle) == 0)
				if (strstr(filename, strPlatformAssetBundle) == (const char*)filename && strstr(filename, strPlatformUpdateAssetBundle) != (const char*)filename)
					return;
			}
		}
		else	 //�����ֻ���� AssetBundles / <Platform> / Update �µ��ļ�
		{
			if (strstr(filename, strPlatformAssetBundle) == (const char*)filename && strstr(filename, strPlatformUpdateAssetBundle) != (const char*)filename)
				return;
		}

		bool bNoCompress = true;
		//ֻ��Lua, ConfigsĿ¼�µ��ļ�ʹ��zlibѹ������Ϊ�ڽ�ѹʱ���ļ���Ҫ����Ĵ��ڴ棬��assetbundle�ļ�ѹ���ʱ��Ͳ���
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
			printf("����md5����! %s \r\n", strNewFile);
			g_pAFramework->Printf("����md5����! %s \r\n", strNewFile);

			return;
		}

		if (FileOperate::FileExist(strOldFile))		//���ͬ���ļ���oldĿ¼�д��ڣ��Ƚ�md5
		{
			bool bAddToUpdateList = false;

/*
			if (m_SVersion.BaseVersion == m_SVersion.LastVersion)		//��һ���汾lua��data��ӵ������б�
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
				printf("����md5����! %s \r\n", strOldFile);
				g_pAFramework->Printf("����md5����! %s \r\n", strOldFile);

				return;
			}

			if (!bAddToUpdateList)
			{
				bAddToUpdateList = FileOperate::Md5Cmp(md5New, md5Old) != 0;
			}

			if (bAddToUpdateList)		//��ӵ������б�
			{
				int originSize = FileOperate::GetFileSize(strNewFile);

				const char* tmpFileName = "./tmp.compressed";
				if (!MakeCompressedFile(strNewFile, tmpFileName, bNoCompress))
				{
					printf("������ʱѹ���ļ�����\r\n");
					g_pAFramework->Printf("������ʱѹ���ļ�����\r\n");

					return;
				}

				char md5[64];
				if (!FileOperate::CalcFileMd5(tmpFileName, md5))
				{
					ASSERT(false);
					printf("��ʱ�ļ�����md5����!\r\n");
					g_pAFramework->Printf("��ʱ�ļ�����md5����!\r\n");

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
		else   //��ӵ������б�
		{
			int originSize = FileOperate::GetFileSize(strNewFile);

			const char* tmpFileName = "./tmp.compressed";
			if (!MakeCompressedFile(strNewFile, tmpFileName, bNoCompress))
			{
				printf("������ʱѹ���ļ�����\r\n");
				g_pAFramework->Printf("������ʱѹ���ļ�����\r\n");

				return;
			}

			char md5[64];
			if (!FileOperate::CalcFileMd5(tmpFileName, md5))
			{
				ASSERT(false);
				printf("��ʱ�ļ�����md5����!\r\n");
				g_pAFramework->Printf("��ʱ�ļ�����md5����!\r\n");

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

	//inc�ļ�
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

	//������ɾ��ԭ����jup�ļ�
	{
		FileOperate::UDeleteFile(strJupFile);
	}

	if (jupContent.UpdateList.empty())
	{
		printf("Ҫ����������Ϊ�գ���������jup�ļ�!\r\n");
		g_pAFramework->Printf("Ҫ����������Ϊ�գ���������jup�ļ�!\r\n");

		return false;
	}

	
	std::set<AString>	 mapFileList;			//������ļ��б�
	mapFileList.insert("inc");
	for (SUpdateFileEntry entry : jupContent.UpdateList)
	{
		mapFileList.insert(entry.strFileName);
	}

	//2017.3.2ֱ�����tmpĿ¼�����ɸ�������
	



#if KEEP_TMP_FOLDER
	AString strTmpDirAbs;
	AString strTmpDir;
	//if (!CompareDir(m_strCompressDir, strTmpDirAbs, mapFileList))		//��tmpDir�е�������md5�Ƚϣ�������ݱ仯�����������ɸ������ݵ�tmp
	{
		strTmpDir.Format("tmp-%s-%s/", strOld, strNew);
		strTmpDirAbs = m_strWorkDir + strTmpDir;

		if (!ReGenerateJupContentToDir(jupContent, strTmpDirAbs))
		{
			printf("�޷����ɸ������ݵ� %s!\r\n", strTmpDirAbs);
			g_pAFramework->Printf("�޷����ɸ������ݵ� %s!\r\n", strTmpDirAbs);

			return false;
		}
	}

#else

	AString strTmpDir = "compress/";
	//�������ɸ������ݵ� compress Ŀ¼
	if (!ReGenerateJupContentToDir(jupContent, m_strCompressDir))
	{
		printf("�޷����ɸ������ݵ� %s!\r\n", m_strCompressDir);
		g_pAFramework->Printf("�޷����ɸ������ݵ� %s!\r\n", m_strCompressDir);

		FileOperate::DeleteDir(m_strCompressDir);
		FileOperate::UDeleteFile("./tmp.compressed");
		return false;
	}

#endif

	//����listfile.txt
	{
		FILE* file = fopen(m_strWorkDir + "listfile.txt", "wt");
		if (!file)
		{
			printf("�޷�����listfile.txt�ļ�!\r\n");
			g_pAFramework->Printf("�޷�����listfile.txt�ļ�!\r\n");

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

	//����jup7z.bat
	AString strJup7zBat = "jup7z.bat";
	{
		FILE* file = fopen(m_strWorkDir + strJup7zBat, "wt");
		if (!file)
		{
			printf("�޷�����jup7z.txt�ļ�!\r\n");
			g_pAFramework->Printf("�޷�����jup7z.txt�ļ�!\r\n");

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

	//����bat, ����jup
	{
		printf("Call %s......\r\n", strJup7zBat);
		g_pAFramework->Printf("Call %s......\r\n", strJup7zBat);

		if (system(strJup7zBat) != 0)	//if (RunProcess("7z.exe", strCommand))
		{
			printf("system���ô���! %s\r\n", strJup7zBat);
			g_pAFramework->Printf("system���ô���! %s\r\n", strJup7zBat);

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

	//���ɸ������ݵ� compress Ŀ¼
	//��������inc�ļ�
	AString strIncFile = "inc";
	{
		FILE* file = fopen(strDir + strIncFile, "wt");
		if (!file)
		{
			printf("�޷�����inc�ļ�!\r\n");
			g_pAFramework->Printf("�޷�����inc�ļ�!\r\n");

			return false;
		}

		for (const auto& str : jupContent.IncString)
		{
			fprintf(file, "%s\n", str);
		}

		fclose(file);
	}

	//����������compressĿ¼
	AString strUpdateBase = m_SConfig.NextVersionPath;
	strUpdateBase.NormalizeDirName();

	AString strSrc, strDest;
	for (const auto& entry : jupContent.UpdateList)
	{
		const char* filename = entry.strFileName;
		bool bNoCompress = true;

		//ֻ��Lua, ConfigsĿ¼�µ��ļ�ʹ��zlibѹ������Ϊ�ڽ�ѹʱ���ļ���Ҫ����Ĵ��ڴ棬��assetbundle�ļ�ѹ���ʱ��Ͳ���
// 		if (strstr(filename, "Lua/") == (const char*)filename || strstr(filename, "Configs/") == (const char*) filename) 
// 		{
// 			bNoCompress = false;
// 		}

		strSrc = strUpdateBase + filename;
		strDest = strDir + filename;

		FileOperate::MakeDir(strDest);

		if (!MakeCompressedFile(strSrc, strDest, bNoCompress))
		{
			printf("����ѹ���ļ�ʧ��! ��%s��%s\r\n", strSrc, strDest);
			g_pAFramework->Printf("����ѹ���ļ�ʧ��! ��%s��%s\r\n", strSrc, strDest);

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

		if (!FileOperate::FileExist(strLeftFile) || !FileOperate::FileExist(strRightFile))		//�ļ��������
			return false;

		if (!FileOperate::CalcFileMd5(strLeftFile, md5Left) || !FileOperate::CalcFileMd5(strRightFile, md5Right))	//����md5
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
	
	printf("�ռ�Jup�ļ�: %s\r\n", strJupDir);
	g_pAFramework->Printf("�ռ�Jup�ļ�: %s\r\n", strJupDir);

	//�����е�jup�ļ�
	Q_iterateFiles(strJupDir,
		[&versionSet, &updateFileList, vBase](const char* filename)
	{
		if (!hasFileExtensionA(filename, "jup"))
			return;

// 		if (6 != sscanf(filename, "%d.%d.%d-%d.%d.%d.jup", &verOld[0], &verOld[1], &verOld[2], &verNew[0], &verNew[1], &verNew[2]))
// 			return;
 
		SJupFileEntry entry;
		//�����汾��
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
		printf("Ҫ���µ�jup�ļ�����Ϊ0, ���ɻ���version.txt!\r\n");
		g_pAFramework->Printf("Ҫ���µ�jup�ļ�����Ϊ0, ���ɻ���version.txt!\r\n");

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

	//���Version
	{
		if ((*versionSet.begin()) != vBase)
		{
			AString strBegin;
			AString strBase;
			(*versionSet.begin()).ToString(strBegin);
			vBase.ToString(strBase);

			printf("jup������BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin, strBase);
			g_pAFramework->Printf("jup������BaseVersion! versionSetBegin: %s , vBase: %s\r\n", strBegin, strBase);
			return false;
		}

		auto itr = std::find(versionSet.begin(), versionSet.end(), vLast);
		if (itr == versionSet.end())
		{
			AString strLast;
			vLast.ToString(strLast);

			printf("jup������LastVersion! vLast: %s\r\n", strLast);
			g_pAFramework->Printf("jup������LastVersion! vLast: %s\r\n", strLast);
			return false;
		}

		if ((*versionSet.rbegin()) != vNext)
		{
			AString strNext;
			vNext.ToString(strNext);

			printf("jup������NextVersion! vNext: %s\r\n", strNext);
			g_pAFramework->Printf("jup������NextVersion! vNext: %s\r\n", strNext);
			return false;
		}	
	}

	//���VersionPair�������ԣ��Ƿ��ܴ�base������latest
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
					printf("�޷��ҵ��汾��Ӧ������jup! curVer: %s\r\n", (const char*)strVer);
					g_pAFramework->Printf("�޷��ҵ��汾��Ӧ������jup! curVer: %s\r\n", (const char*)strVer);
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
		printf("�޷�����version.txt�ļ�!\r\n");
		g_pAFramework->Printf("�޷�����version.txt�ļ�!\r\n");
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
			printf("jup�ļ�������, %s!\r\n", strJupFile);
			g_pAFramework->Printf("jup�ļ�������, %s!\r\n", strJupFile);

			fclose(file);
			return false;
		}

		if (!FileOperate::CalcFileMd5(strJupFile, md5String))
		{
			printf("md5�������, %s!\r\n", strJupFile);
			g_pAFramework->Printf("md5�������, %s!\r\n", strJupFile);

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

	//shellҪ��б��
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
			//��Ӵ�entry
			updateFileEntries.push_back(entry);
			nCurrentSize += entry.nSize;
		}
		else
		{
			//���һ��jupContent
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
				vEnd.Set(vStart.iVer0, vStart.iVer1, vStart.iVer2, vStart.iVer3 + 1);			   //ĩλ��1
			}

			if (updateFileEntries.size() > 0)			//�����ļ��б�������split
			{
				SJupContent content;
				content.verOld = vStart;
				content.verNew = vEnd;
				content.UpdateList = updateFileEntries;
				GenerateIncFileString(content, content.IncString);

				jupContentSplitList.emplace_back(content);					//��ӵ�SplitList
			}

			//��Ӵ�entry
			{
				nCurrentSize = 0;
				updateFileEntries.clear();

				//��Ӵ�entry
				updateFileEntries.push_back(entry);
				nCurrentSize += entry.nSize;
			}

		}
	}

	if (updateFileEntries.size() > 0)		   //���һ��
	{
		//���һ��jupContent
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
			vEnd = vOrigNew;			   //ĩλ��1
		}

		SJupContent content;
		content.verOld = vStart;
		content.verNew = vEnd;
		content.UpdateList = updateFileEntries;
		GenerateIncFileString(content, content.IncString);

		jupContentSplitList.emplace_back(content);					//��ӵ�SplitList
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
		printf("�޷�����JupUpdateContent.txt�ļ�!\r\n");
		g_pAFramework->Printf("�޷�����JupUpdateContent.txt�ļ�!\r\n");

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

	//����ߵ�Ŀ��汾
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

	if (iVer < 0)	//û���ҵ�
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
		printf("�޷�����version.txt�ļ�!\r\n");
		g_pAFramework->Printf("�޷�����version.txt�ļ�!\r\n");

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
