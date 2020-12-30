#pragma once

#include "CLplusClassMan.h"
#include "CLplusFileMan.h"
#include "CLplusDef.h"
#include <string>

class CLplusChecker
{
public:
	CLplusChecker(const std::string& strConfigsDir, const std::string& strLuaDir);

public:
	void Init();
	
	void CollectClasses();
	void CollectFiles();
	void CollectGameText();

	void CheckResultToFile(const char* strFileName);

	const std::map<std::string, SLuaClass>& GetLuaClassMap() const;
	const std::map<std::string, SLuaFile>& GetLuaFileMap() const;

	//
	void PrintLuaClasses() const;
	void PrintLuaFiles() const;

	void PrintLuaClassHierachy() const;
	void PrintLuaClassHierachyToFile(FILE* pFile) const;			//�ļ����
	void PrintLuaClassHierachyToCsv(FILE* pFile) const;

private:
	bool IsBuiltInType(const std::string& szType) const;

	//
	void CheckClass_ErrorDefine(FILE* file, const char* checkRule = "def������");		//���def����
	
	//
	void CheckFile_UsedMethodParams(FILE* file, const char* checkRule = "ʹ�÷����Ĳ������");
	void CheckFile_UsedSpecialMethodParams(FILE* file, const char* checkRule = "ʹ��C#�����Ĳ������");

	void PrintLuaClassHierachy(const SLuaClass* luaClass) const;
	void PrintLuaClassHierachyToFile(FILE* pFile, const SLuaClass* luaClass) const;
	void PrintLuaClassHierachyToCsv(FILE* pFile, const SLuaClass* luaClass) const;

private:
	CLplusClassMan	m_ClassMan;
	CLplusFileMan	m_FileMan;

	std::string  m_ConfigDir;
	std::set<int>	m_GameTextKeySet;

	//
	std::list<std::string>		m_BuiltInTypeList;
	std::map<std::string, std::vector<int>> m_CSharpMethodParamMap;
	std::list<std::tuple<std::string, std::string>>	m_GlobalClassList;
	std::list<std::tuple<std::string, int>> m_MethodParamList;
};