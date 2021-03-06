#pragma once

#include "CLplusDef.h"

class AFile;

//收集lplus class
class CLplusClassMan
{
public:
	explicit CLplusClassMan(const std::string& strLuaDir);

public:
	void Init() 
	{

	}

	void Collect();

	const std::map<std::string, SLuaClass>& GetLuaClassMap() const { return m_mapLuaClass; }
	const std::map<std::string, std::set<std::string>>& GetLuaClassHierachyMap() const { return m_mapLuaClassHierachy; }
	const std::set<std::string>& GetSingleLuaClassSet() const { return m_setSingleLuaClass; }

	const SLuaClass* GetLuaClass(const char* szName) const;

private:
	void BuildLplusClass(AFile* pFile, const char* fileName);
	std::map<std::string, std::set<std::string>> BuildClassHierachy();		//构造继承结构
	std::set<std::string> BuildSingleClassSet();		//构造无父子的类

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);

	void HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ConstDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_FinalDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_StaticDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ErrorDefine(const char* szLine, int nLine, SLuaClass* current);

	SLuaClass* GetLuaClass(const char* szName);
	SLuaClass* AddLuaClass(const char* szName);

	bool ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const;		//方法声明的参数
	bool ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const;			//方法function(的实际参数
	bool ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const;		//调用方法的参数
	bool GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const;

private:
	std::string m_strLuaDir;

	std::map<std::string, SLuaClass>	m_mapLuaClass;
	std::map<std::string, std::set<std::string>>	m_mapLuaClassHierachy;		//有父子关系的类
	std::set<std::string>		m_setSingleLuaClass;			//独立的lua类
};