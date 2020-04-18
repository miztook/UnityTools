#pragma once

#include <vector>
#include "VersionMan.h"
#include <set>
#include <string>
#include <map>

#define PROJECT_NAME "Tera-M1"


struct SJupFileEntry			  //jup�ļ�
{
	ELEMENT_VER vOld;
	ELEMENT_VER vNew;

	bool operator<(const SJupFileEntry& rhs) const{
		if (vOld != rhs.vOld)
			return vOld < rhs.vOld;
		else
			return vNew < rhs.vNew;
	}
};

struct SUpdateFileEntry			 //һ��jup�ڵ��ļ�
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

struct SJupContent			//һ��jup�ĸ�������
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

	bool GenerateJup(const SJupContent& jupContent, bool bForceMx0);
	bool GenerateVersionTxt(const SVersion& sversion) const;
	
	bool SplitJup(const SJupContent& jupContent, std::vector<SJupContent>& jupContentSplitList, int64_t nLimitSize) const;
	
public:
	static bool GenerateBaseVersionTxt(const std::string& strBaseVersion, const std::string& strJupGeneratePath);
	static bool GenerateVersionTxt(const std::string& baseVersion, const std::string& jupDir);
	static bool FindVersionPair(const std::vector<SJupFileEntry>& pairList, const ELEMENT_VER& vBase, const ELEMENT_VER& vLatest, const ELEMENT_VER& curVer, SJupFileEntry& verPair);

private:
	void GenerateIncFileString(const SJupContent& jupContent, std::vector<std::string>& strInc) const;

	bool ReadVersionText(const char* strFileName, std::vector<SUpdateFileEntry>& entries) const;	
	bool ReGenerateJupContentToDir(const SJupContent& jupContent, const char* strDir) const;
	bool CompareDir(const std::string& leftDir, const std::string& rightDir, const std::set<std::string>& fileList) const;
	bool DoGenerateJup(const char* szJupFile, bool useMx0);

};