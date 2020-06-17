#pragma once

#include "CLplusDef.h"

class AFile;

// ’ºØlplus class
class CLplusClassMan
{
public:
	CLplusClassMan(const std::string& strLuaDir);

public:
	void Collect();

private:
	void BuildLplusClass(AFile* pFile, const char* fileName);

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);

	SLuaClass* GetLuaClass(const char* szName);
	SLuaClass* AddLuaClass(const char* szName);

private:
	std::string m_strLuaDir;

	std::map<std::string, SLuaClass>	m_mapLuaClass;
};