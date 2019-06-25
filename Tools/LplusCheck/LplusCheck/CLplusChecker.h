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

struct SLuaFieldToken
{
	SLocation location;
	std::string token;
	std::string className;			//token������class��
	std::string typeName;

	bool operator<(const SLuaFieldToken& rhs) const
	{
		if (location != rhs.location)
			return location < rhs.location;
		else if (token != rhs.token)
			return token < rhs.token;
		else if (className != rhs.className)
			return className < rhs.className;
		else
			return typeName < rhs.typeName;
	}

	bool operator==(const SLuaFieldToken& rhs) const
	{
		return location == rhs.location && 
			token == rhs.token && 
			className == rhs.className && 
			typeName == rhs.typeName;
	}
};

struct SLuaFunctionToken
{
	SLuaFunctionToken()
	{
		bHasFunction = false;
		bIsVirtual = false;
		bIsOverride = false;
		bIsStatic = false;
	}

	SLocation location;
	std::string token;
	std::string className;			//token������class��
	std::vector<std::string> vParams;			
	std::vector<std::string> vRets;
	std::vector<std::string> vActParams;
	bool bHasFunction;					//�������Ƿ����function
	bool bIsVirtual;
	bool bIsOverride;
	bool bIsStatic;

	bool operator<(const SLuaFunctionToken& rhs) const
	{
		if (location != rhs.location)
			return location < rhs.location;
		else if (token != rhs.token)
			return token < rhs.token;
		else if (className != rhs.className)
			return className < rhs.className;
		else if (vParams != rhs.vParams)
			return vParams < rhs.vParams;
		else if (vRets != rhs.vRets)
			return vRets < rhs.vRets;
		else if (vActParams != rhs.vActParams)
			return vActParams < rhs.vActParams;
		else if (bHasFunction != rhs.bHasFunction)
			return bHasFunction < rhs.bHasFunction;
		else if (bIsVirtual != rhs.bIsVirtual)
			return bIsVirtual < rhs.bIsVirtual;
		else if (bIsOverride < rhs.bIsOverride)
			return bIsOverride < rhs.bIsOverride;
		else
			return bIsStatic < rhs.bIsStatic;
	}

	bool operator==(const SLuaFunctionToken& rhs) const
	{
		return location == rhs.location &&
			token == rhs.token &&
			className == rhs.className &&
			vParams == rhs.vParams &&
			vRets == rhs.vRets && 
			vActParams == rhs.vActParams &&
			bHasFunction == bHasFunction &&
			bIsVirtual == bIsVirtual &&
			bIsOverride == bIsOverride &&
			bIsStatic == bIsStatic;
	}
};

struct SLuaTimerToken
{
	SLocation location;
	std::string id;
	std::string ttl;
	std::string runonce;
	std::string className;			//token������class��

	bool operator<(const SLuaTimerToken& rhs) const
	{
		if (className != rhs.className)
			return className < rhs.className;
		else if (location != rhs.location)
			return location < rhs.location;
		else if (ttl != rhs.ttl)
			return ttl < rhs.ttl;
		else if (runonce != rhs.runonce)
			return runonce < rhs.runonce;
		else
			return id != rhs.id;
	}

	bool operator==(const SLuaTimerToken& rhs) const
	{
		return className == rhs.className && location == rhs.location && ttl == rhs.ttl && runonce == rhs.runonce && id == rhs.id;
	}
};

struct SStringTableToken 
{
	SLocation location;
	int text_id;
	std::string className;

	bool operator<(const SStringTableToken& rhs) const
	{
		if (className != rhs.className)
			return className < rhs.className;
		else if (location != rhs.location)
			return location < rhs.location;
		else
			return text_id < rhs.text_id;
	}

	bool operator==(const SStringTableToken& rhs) const
	{
		return className == rhs.className && location == rhs.location && text_id == rhs.text_id;
	}
};

using SOutputEntry3 = std::tuple<std::string, std::string, int>;
using SOutputEntry4 = std::tuple<std::string, std::string, int, int>;
using SOutputEntry5 = std::tuple<std::string, std::string, std::string, int, int>;
using SOutputEntry7 = std::tuple<std::string, std::string, int, int, std::string, int, int>;

struct STableRemoveCheckEntry
{
	int nInverseFor;
	int nTableRemove;
};

struct SLuaClass
{
	SLuaClass* parent;

	std::string strFileName;
	std::string strName;

	std::set<int>		errorInterfaceLines;		//û��ʹ�ö����Ե�Interfaces
	std::set<int>		errorConfigsLines;			//û��ʹ�ö����Ե�Configs

	std::set<SLuaFieldToken>	fieldDefList;
	std::set<SLuaFunctionToken>	functionDefList;
	std::set<SLuaFunctionToken>	functionVirtualDefList;
	std::set<SLuaFunctionToken>	functionOverrideDefList;

	std::set<SLuaFieldToken>	fieldUsedList;
	std::set<SLuaFunctionToken>	functionUsedList;

	std::set<SStringTableToken>		stringTableUsedList;

	//���ʹ��
	std::set<SLuaFieldToken> fieldUsedIndirectList;
	std::set<SLuaFunctionToken> functionUsedIndirectList;
	std::set<SLuaFunctionToken>	functionAllUsedIndirectList;
	std::set<SLuaFunctionToken> functionSpecialUsedIndirect;

	//�����ȫ��token,���߼����
	std::set<SLuaFieldToken>  fieldUsedGlobalList;
	std::set<SLuaFunctionToken>  functionUsedGlobalList;

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

	std::set<SStringTableToken>		stringTableUsedList;

	//���ʹ��
	std::set<SLuaFunctionToken>	functionAllUsedIndirectList;
	std::set<SLuaFunctionToken> functionSpecialUsedIndirect;

	//�����ȫ��token,���߼����
	std::set<SLuaFieldToken>  fieldUsedGlobalList;
	std::set<SLuaFunctionToken>  functionUsedGlobalList;
};

struct SMessageToken
{
	std::string protoName;
	std::set<std::string> repeatedFieldNameSet;
};

class CLplusChecker
{
public:
	CLplusChecker(const std::string& strConfigsDir, const std::string& strLuaDir);

public:
	bool BuildLuaClasses();
	bool BuildLuaFiles();
	bool ParseGameText();

	bool GetLuaClassUsedMembers();

	bool CheckLuaClassesToFile(const char* strFileName);

	void PrintLuaClasses();

	const SLuaClass* GetLuaClass(const char* szName) const;
	SLuaClass* GetLuaClass(const char* szName);
	SLuaClass* AddLuaClass(const char* szName);

	bool CollectAndCheckNetProto();		//net.proto
	bool CollectAndCheckTemplateProto();	//Template.proto

private:
	void InitData();

private:
	bool BuildLuaClass(AFile* pFile);
	bool BuildLuaFile(AFile* pFile);

	bool GetLuaClassUsedMembers(AFile* pFile, const std::map<std::string, SLuaClass>& luaClass);

	bool CollectAndCheckProto(const std::string& fileName);
	void HandleLine_ProtoFields(const char* szLine, int nLine, SMessageToken*& messageToken);
	void Check_Proto_RepeatedFields(AFile* pFile, const std::set<std::string>& fieldSet);
	void Check_Proto_RepeatedFields(const std::set<std::string>& fieldSet);

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	std::string HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_StaticDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_StringTableUse(const char* szLine, int nLine, SLuaClass* current);

	void HandleLine_ErrorToken(const char* szLine, int nLine, const char* filename);
	void HandleLine_TableRemoveCheck(const char* szLine, int nLine, const char* filename);
	void HandleLine_ErrorDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ErrorInterfaces(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ErrorConfigs(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_InvalidGlobalFields(const char* szLine, int nLine, SLuaClass* current);

	void Get_SelfFieldUsedDirect(const char* szLine, int nLine, SLuaClass* current);		//�Լ���ֱ��ʹ���ֶ�
	void Get_SelfMethodUsedDirect(const char* szLine, int nLine, SLuaClass* current);		//�Լ���ֱ��ʹ�÷���

	void Get_SelfFieldUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//�Լ��ļ��ʹ�÷���
	void Get_SelfMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//�Լ��ļ��ʹ�÷���
	void Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//���еļ��ʹ�÷���
	void Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);

	void Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaClass* current);		//ʹ�õ�ȫ���ֶ�
	void Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaClass* current);

	void Check_MethodDefinitionToFile(FILE* pFile, const SLuaClass& luaClass);				//��鷽�����壬1: ��������ƥ�� 2: �����ͷ���ֵ�Ƿ��Ѿ���������ǻ�������
	void Check_DuplicateField(const SLuaClass& luaClass);
	void Check_DuplicateMethod(const SLuaClass& luaClass);
	void Check_FieldUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass);				//����ֶ�ʹ�ã�1:  �Ƿ��Ѷ���?
	void Check_MethodUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass);				//��鷽������
	void Check_MethodInheritanceToFile(FILE* pFile, const SLuaClass& luaClass);				//��鷽���̳й�ϵ, 1: override�Ƿ��ж�Ӧ��virtual����signature

	void Check_FieldUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet);
	void Check_MethodUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet);
	void Check_AllMethodusedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry7>& entryMethodSet);
	void Check_AllSpecialMethodusedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry7>& entryMethodSet);
	void Check_AllGlobalFieldUsedToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet);
	void Check_AllGlobalMethodUsedToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet);

	void Check_GameTextUsedToFile(const SLuaClass& luaClass, std::set<SStringTableToken>& entrySet);

	void Check_FieldMethodNameStandard(const SLuaClass& luaClass);				//���field��method�����淶
	void Check_MethodReturnNum(const SLuaClass& luaClass);
	void Check_AddEventHandler(const SLuaClass& luaClass);

	bool IsBuiltInType(const std::string& szType) const;
	bool IsValidDefine(const std::string& szDef) const;
	bool IsSelfOrBaseClass(const std::string& szThisClassName, const std::string& baseClassName) const;

	std::string getFieldType(const SLuaClass* luaClass, const char* szField, bool searchDerive) const;		//searchDerive �ڴ�type�в��Ҳ���ʱ���Ƿ����drive��type
	bool ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const;		//���������Ĳ���
	bool ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const;			//����function(��ʵ�ʲ���
	bool ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const;		//���÷����Ĳ���
	bool GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const;

private:
	std::string m_strConfigsDir;
	std::string m_strLuaDir;
	std::string m_strNetProtoFileName;
	std::string m_strTemplateProtoFileName;
	std::map<std::string, SLuaClass>	m_mapLuaClass;
	std::vector<SLuaFile>	m_vecLuaFiles;

	std::vector<SLuaFieldToken>		m_errorTokenList;
	std::vector<SLuaFieldToken>		m_errorDefineList;
	std::set<SLuaFieldToken>  m_dupLuaFieldList;
	std::set<SLuaFunctionToken>  m_dupFunctionList;
	std::map<std::string, std::set<SLuaFieldToken>>		m_errorNameFieldMap;
	std::map<std::string, std::set<SLuaFunctionToken>>		m_errorNameFunctionMap;
	std::vector<SLuaFieldToken>		m_errorUserDataFieldList;
	std::vector<SLuaTimerToken>		m_errorTimerList;
	std::map<std::string, STableRemoveCheckEntry>		m_tableCheckMap;

	std::vector<SOutputEntry4>	m_invalidGlobalFieldList;		//�����ȫ�ֱ���ʹ�ã���ȫ�ֱ����ڱ�����ʹ��
	std::vector<SOutputEntry3>  m_invalidRepeatedFieldList;		//
	std::map<std::string, std::list<std::tuple<std::string, int, int, int>>> m_ErrorMethodNumReturnMap;		//����ĺ�������ֵ
	std::map<std::string, std::list<std::tuple<std::string, int, std::string>>> m_ErrorAddHandlerMap;		//����ĺ�������ֵ

	std::set<int>	m_GameTextKeySet;

	//����
	std::map<std::string, std::string>	m_ClassInvalidTokenMap;
	std::list<std::string> m_BuiltInTypeList;
	std::list<std::string> m_ValidDefineList;
	std::list<std::string> m_errorTokens;
	std::map<std::string, std::vector<int>> m_SpecialMethodParamMap;
	std::list<std::tuple<std::string, std::string>>	m_GlobalClassList;
	std::list<std::tuple<std::string, int>> m_MethodParamList;
	std::list<std::tuple<std::string, int>> m_StaticMethodParamList;
	std::list<std::tuple<std::string, std::string>> m_ClassInvalidTokenList;
	std::list<std::tuple<std::string, int>> m_SpecialMethodReturnList;
};