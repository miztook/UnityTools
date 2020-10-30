#pragma once

#include "CLplusDef.h"

class AFile;

//�ռ�lplus class
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

private:
	void BuildLplusClass(AFile* pFile, const char* fileName);

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

	bool ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const;		//���������Ĳ���
	bool ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const;			//����function(��ʵ�ʲ���
	bool ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const;		//���÷����Ĳ���
	bool GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const;

private:
	std::string m_strLuaDir;

	std::map<std::string, SLuaClass>	m_mapLuaClass;
};