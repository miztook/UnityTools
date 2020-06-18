#pragma once

#include "CLplusDef.h"

class AFile;

//�ռ� LuaFile 
class CLplusFileMan
{
public:
	explicit CLplusFileMan(const std::string& strLuaDir);

public:
	void Collect();

private:

private:
	std::string m_strLuaDir;

	std::map<std::string, SLuaFile>	m_mapLuaFile;
};
