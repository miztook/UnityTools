#pragma once
#pragma once

#include "AFile.h"
#include <vector>
#include <set>
#include <map>
#include <list>
#include <cstring>

struct SLocation
{
	int line;
	int col;

	SLocation() { line = 0; col = 0; }

	bool operator<(const SLocation& rhs) const
	{
		if (line != rhs.line)
			return line < rhs.line;
		else
			return col < rhs.col;
	}

	bool operator==(const SLocation& rhs) const
	{
		return line == rhs.line && col == rhs.col;
	}

	bool operator!=(const SLocation& rhs) const
	{
		return line != rhs.line || col != rhs.col;
	}
};

struct SLuaClass
{
	SLuaClass* parent;

	std::string strFileName;
	std::string strName;

	//
	std::map<std::string, std::set<SLocation>>	templateLocationMap;

	bool IsSelfOrParent(const SLuaClass* parentClass) const
	{
		const SLuaClass* p = this;
		while (p)
		{
			if (p == parentClass)
				return true;
			p = p->parent;
		}
		return false;
	}
};

struct SLuaFile
{
	std::string strFileName;

	//
	std::map<std::string, std::set<SLocation>>	templateLocationMap;
};

class CLuaDataChecker
{
public:
	CLuaDataChecker(const std::string& strConfigsDir, const std::string& strLuaDir);

public:
	bool SearchLuaFiles();

	void PrintLuaClasses();
	void PrintLuaFiles();

private:
	void InitData();

	bool SearchLuaFile(AFile* pFile);

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_SearchElementData(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_SearchElementData(const char* szLine, int nLine, SLuaFile* current);

	const SLuaClass* GetLuaClass(const char* szName) const;
	SLuaClass* GetLuaClass(const char* szName);
	SLuaClass* AddLuaClass(const char* szName);

	SLuaFile* AddLuaFile(const char* szFileName);

private:
	std::string m_strConfigsDir;
	std::string m_strLuaDir;

	std::vector<std::string> m_TemplateNames;
	
	std::map<std::string, SLuaClass>	m_mapLuaClass;
	std::vector<SLuaFile>	m_vecLuaFiles;
};