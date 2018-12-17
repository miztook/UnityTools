#pragma once

#include <vector>
#include "AString.h"
#include "VersionMan.h"
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
	AString strMd5;		//compressed
	AString strFileName;
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
	std::vector<AString>  IncString;

	void ToFileName(AString& str) const
	{
		AString strOld;
		AString strNew;
		verOld.ToString(strOld);
		verNew.ToString(strNew);
		str.Format("%s-%s.jup", strOld, strNew);
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
		AString JupGeneratePath;
		AString LastVersionPath;
		AString NextVersionPath;
		bool bSmallPack;
	} m_SConfig;

	struct SVersion
	{
		AString BaseVersion;
		AString LastVersion;
		AString NextVersion;
	} m_SVersion;

	AString m_strWorkDir;
	AString m_strCompressDir;

public:
	bool Init(const AString& strLastPath,
			  const AString& strNextPath,
			  const AString& strJupGeneratePath,
			  bool bSmallPack);
	void SetPlatform(const AString& strPlatformType);
	void SetVersion(const AString& strBaseVersion,
					const AString& strLastVersion,
					const AString& strNextVersion);

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
	static bool GenerateBaseVersionTxt(const AString& strBaseVersion, const AString& strJupGeneratePath);
	
private:
	void GenerateIncFileString(const SJupContent& jupContent, std::vector<AString>& strInc) const;

	bool ReadVersionText(const AString& strFileName, std::vector<SUpdateFileEntry>& entries) const;	
	bool ReGenerateJupContentToDir(const SJupContent& jupContent, const AString& strDir) const;
	bool CompareDir(const AString& leftDir, const AString& rightDir, const std::set<AString>& fileList) const;
};