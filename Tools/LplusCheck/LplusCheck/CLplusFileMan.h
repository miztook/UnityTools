#pragma once

#include "CLplusDef.h"

class AFile;

//收集 LuaFile 
class CLplusFileMan
{
public:
	explicit CLplusFileMan(const std::string& strLuaDir);

public:
	void Collect();

	const std::map<std::string, SLuaFile>& GetLuaFileMap() const { return m_mapLuaFile; }

private:
	void BuildLplusFile(AFile* pFile, const char* fileName);
	
	void HandleLine_StringTableUse(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaFile* luaFile);

	bool ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const;		//调用方法的参数

	SLuaFile* GetLuaFile(const char* szName);
	SLuaFile* AddLuaFile(const char* szName);

private:
	std::string m_strLuaDir;

	std::map<std::string, SLuaFile>	m_mapLuaFile;

	std::map<std::string, std::vector<int>> m_SpecialMethodParamMap;
	std::list<std::tuple<std::string, std::string>>	m_GlobalClassList;
};
