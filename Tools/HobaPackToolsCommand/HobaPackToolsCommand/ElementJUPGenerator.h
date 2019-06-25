#pragma once

#include <vector>
#include <cstring>
#include "VersionMan.h"
#include "stringext.h"
#include <set>


#define PROJECT_NAME "Tera-M1"

struct SJupFileEntry			  //jup文件
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

struct SUpdateFileEntry			 //一个jup内的文件
{
	std::string strMd5;		//compressed
	std::string strFileName;
	int64_t nSize;			//compressed

	bool operator<(const SUpdateFileEntry& rhs) const
	{
		if (nSize != rhs.nSize)
			return nSize > rhs.nSize;
		else if (strFileName != rhs.strFileName)
			return strFileName < rhs.strFileName;
		else
			return strMd5 < rhs.strMd5;
	}
};

struct SJupContent			//一个jup的更新内容
{
	ELEMENT_VER verOld;
	ELEMENT_VER verNew;
	std::vector<SUpdateFileEntry>	UpdateList;
	std::vector<std::string>  IncString;

	void ToFileName(std::string& str) const
	{
		std::string strOld;
		std::string strNew;
		verOld.ToString(strOld);
		verNew.ToString(strNew);
		std_string_format(str, "%s-%s.jup", strOld.c_str(), strNew.c_str());
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
		std::string LastVersionPath;
		std::string NextVersionPath;
		bool bSmallPack;
	} m_SConfig;

	struct SVersion
	{
		std::string BaseVersion;
		std::string LastVersion;
		std::string NextVersion;
	} m_SVersion;

	std::string m_strWorkDir;
	std::string m_strCompressDir;

public:
	bool Init(const std::string& strLastPath,
			  const std::string& strNextPath,
			  const std::string& strJupGeneratePath,
			  bool bSmallPack);
	void SetPlatform(const std::string& strPlatformType);
	void SetVersion(const std::string& strBaseVersion,
					const std::string& strLastVersion,
					const std::string& strNextVersion);

	const SVersion& GetSVersion() const { return m_SVersion; }
	
	bool GenerateUpdateList(const SVersion& sversion, SJupContent& jupContent) const;
	void PrintUpdateList(const SJupContent& jupContent) const;

	bool GenerateJup(const SJupContent& jupContent);
	bool GenerateVersionTxt(const SVersion& sversion) const;
	void OpenJupDir();

	bool SplitJup(const SJupContent& jupContent, std::vector<SJupContent>& jupContentSplitList, int64_t nLimitSize) const;

	bool GenerateJupUpdateText(const std::vector<SJupContent>& jupContentList);

	bool FindVersionPair(const std::vector<SJupFileEntry>& pairList, const ELEMENT_VER& vBase, const ELEMENT_VER& vLatest, const ELEMENT_VER& curVer, SJupFileEntry& verPair) const;

public:
	static bool GenerateBaseVersionTxt(const std::string& strBaseVersion, const std::string& strJupGeneratePath);
	
private:
	void GenerateIncFileString(const SJupContent& jupContent, std::vector<std::string>& strInc) const;

	bool ReadVersionText(const std::string& strFileName, std::vector<SUpdateFileEntry>& entries) const;	
	bool ReGenerateJupContentToDir(const SJupContent& jupContent, const std::string& strDir) const;
	bool CompareDir(const std::string& leftDir, const std::string& rightDir, const std::set<std::string>& fileList) const;
};