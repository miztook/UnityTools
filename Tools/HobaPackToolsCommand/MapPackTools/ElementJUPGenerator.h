#pragma once

#include <vector>
#include "VersionMan.h"
#include <set>
#include <string>
#include <map>

#define PROJECT_NAME "Tera-M1"

struct SUpdateFileEntry			 //一个jup内的文件
{
	std::string strMd5;		//compressed
	std::string strFileName;
	int64_t nSize;			//compressed
	int64_t nOriginSize;

	bool operator<(const SUpdateFileEntry& rhs) const
	{
		if (nSize != rhs.nSize)
			return nSize > rhs.nSize;
		else if (strFileName != rhs.strFileName)
			return strFileName < rhs.strFileName;
		else if (nOriginSize != rhs.nOriginSize)
			return nOriginSize > rhs.nOriginSize;
		else
			return strMd5 < rhs.strMd5;
	}
};

struct SJupContent			//一个jup的更新内容
{
	ELEMENT_VER verBase;
	std::string  Name;
	std::vector<SUpdateFileEntry>	UpdateList;
	std::vector<std::string>  IncString;

	int64_t GetTotalOriginSize() const
	{
		int64_t total = 0;
		for (const auto& entry : UpdateList)
		{
			total += entry.nOriginSize;
		}
		return total;
	}

	int64_t GetTotalSize() const
	{
		int64_t total = 0;
		for (const auto& entry : UpdateList)
		{
			total += entry.nSize;
		}
		return total;
	}
};

/*
	Class
*/
class CElementJUPGenerator
{
public:
	CElementJUPGenerator();
	~CElementJUPGenerator(){}

public:
	enum EPlatformType
	{
		Windows = 0,
		iOS,
		Android,
	}m_PlatformType;

	struct SConfig
	{
		std::string JupGeneratePath;
		std::string BaseVersionPath;
	} m_SConfig;

	struct SVersion
	{
		std::string BaseVersion;
	} m_SVersion;

	std::string m_strWorkDir;
	std::string m_strCompressDir;

public:
	bool Init(const std::string& strBasePath, const std::string& strJupGeneratePath);
	void SetPlatform(const std::string& strPlatformType);
	void SetVersion(const std::string& strBaseVersion);

	const SVersion& GetSVersion() const { return m_SVersion; }
	
	bool GenerateUpdateList(const SVersion& sversion,
		const std::string& name,
		const std::vector<std::string>& assetbundles,
		const std::vector<std::string>& audios,
		const std::vector<std::string>& videos,
		SJupContent& jupContent) const;

	bool GeneratePck(const SJupContent& jupContent);
	bool GenerateVersionTxt(const std::string& baseVersion, const std::string& jupDir);

private:
	void GenerateIncFileString(const SJupContent& jupContent, std::vector<std::string>& strInc) const;
	
	bool ReGenerateJupContentToDir(const SJupContent& jupContent, const char* strDir) const;
	bool CopyFileContent(const char* srcFileName, const char* destFileName) const;
	bool GeneratePCKFile(const SJupContent& jupContent, const char* destDir, const char* fileName) const;
};