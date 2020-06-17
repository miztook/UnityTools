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
	std::string className;			//token所属的class名
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
	std::string className;			//token所属的class名
	std::vector<std::string> vParams;			
	std::vector<std::string> vRets;
	std::vector<std::string> vActParams;
	bool bHasFunction;					//参数中是否包含function
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
	std::string className;			//token所属的class名

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
	std::string classOrFileName;

	bool operator<(const SStringTableToken& rhs) const
	{
		if (classOrFileName != rhs.classOrFileName)
			return classOrFileName < rhs.classOrFileName;
		else if (location != rhs.location)
			return location < rhs.location;
		else
			return text_id < rhs.text_id;
	}

	bool operator==(const SStringTableToken& rhs) const
	{
		return classOrFileName == rhs.classOrFileName && location == rhs.location && text_id == rhs.text_id;
	}
};

using SOutputEntry3 = std::tuple<std::string, std::string, int>;
using SOutputEntry4 = std::tuple<std::string, std::string, int, int>;
using SOutputEntry5 = std::tuple<std::string, std::string, std::string, int, int>;
using SOutputEntry7 = std::tuple<std::string, std::string, int, int, std::string, int, int>;
using SOutputEntry5_SISII = std::tuple<std::string, int, std::string, int, int>;

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

	std::set<int>		errorInterfaceLines;		//没有使用多语言的Interfaces
	std::set<int>		errorConfigsLines;			//没有使用多语言的Configs

	std::set<SLuaFieldToken>	fieldDefList;
	std::set<SLuaFunctionToken>	functionDefList;
	std::set<SLuaFunctionToken>	functionVirtualDefList;
	std::set<SLuaFunctionToken>	functionOverrideDefList;

	std::set<SLuaFieldToken>	fieldUsedList;
	std::set<SLuaFunctionToken>	functionUsedList;

	std::set<SStringTableToken>		stringTableUsedList;

	//间接使用
	std::set<SLuaFieldToken> fieldUsedIndirectList;
	std::set<SLuaFunctionToken> functionUsedIndirectList;
	std::set<SLuaFunctionToken>	functionAllUsedIndirectList;
	std::set<SLuaFunctionToken> functionSpecialUsedIndirect;

	//特殊的全局token,和逻辑相关
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
	std::string strName;

	std::set<SStringTableToken>		stringTableUsedList;

	//间接使用
	std::set<SLuaFunctionToken>	functionAllUsedIndirectList;
	std::set<SLuaFunctionToken> functionSpecialUsedIndirect;

	//特殊的全局token,和逻辑相关
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

	SLuaFile* GetLuaFile(const char* szName);
	SLuaFile* AddLuaFile(const char* szName);

private:
	void InitData();

private:
	bool BuildLuaClass(AFile* pFile);
	bool BuildLuaFile(AFile* pFile, const char* fileName);

	bool GetLuaClassUsedMembers(AFile* pFile, const std::map<std::string, SLuaClass>& luaClass);

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	std::string HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_StaticDefine(const char* szLine, int nLine, SLuaClass* current);
	
	void HandleLine_ErrorToken(const char* szLine, int nLine, const char* filename);
	void HandleLine_TableRemoveCheck(const char* szLine, int nLine, const char* filename);
	void HandleLine_ErrorDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ErrorInterfaces(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_ErrorConfigs(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_InvalidGlobalFields(const char* szLine, int nLine, SLuaClass* current);

	void Get_SelfFieldUsedDirect(const char* szLine, int nLine, SLuaClass* current);		//自己的直接使用字段
	void Get_SelfMethodUsedDirect(const char* szLine, int nLine, SLuaClass* current);		//自己的直接使用方法

	void Get_SelfFieldUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//自己的间接使用方法
	void Get_SelfMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//自己的间接使用方法
	
	void HandleLine_StringTableUse(const char* szLine, int nLine, SLuaClass* current);
	void Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);		//所有的间接使用方法
	void Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current);
	void Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaClass* current);		//使用的全局字段
	void Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaClass* current);

	//LuaFile
	void HandleLine_StringTableUse(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaFile* luaFile);
	void Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaFile* luaFile);

	//luaClass
	void Check_MethodDefinitionToFile(FILE* pFile, const SLuaClass& luaClass);				//检查方法定义，1: 参数个数匹配 2: 参数和返回值是否已经定义或者是基础类型
	void Check_DuplicateField(const SLuaClass& luaClass);
	void Check_DuplicateMethod(const SLuaClass& luaClass);
	void Check_FieldUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass);				//检查字段使用，1:  是否已定义?
	void Check_MethodUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass);				//检查方法是用
	void Check_MethodInheritanceToFile(FILE* pFile, const SLuaClass& luaClass);				//检查方法继承关系, 1: override是否有对应的virtual而且signature

	void Check_FieldUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet);
	void Check_MethodUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet);
	
	//luaClass & luaFile
	template <class T>
		void Check_AllMethodusedIndirectToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5_SISII>& entryMethodSet);
	
	template <class T>
		void Check_AllSpecialMethodusedIndirectToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5_SISII>& entryMethodSet);
	
	template <class T>	
		void Check_AllGlobalFieldUsedToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5>& entrySet);

	template <class T>
		void Check_AllGlobalMethodUsedToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet);
	
	template <class T>	
		void Check_GameTextUsedToFile(const T& luaClass, std::set<SStringTableToken>& entrySet);

	void Check_FieldMethodNameStandard(const SLuaClass& luaClass);				//检查field和method命名规范
	void Check_MethodReturnNum(const SLuaClass& luaClass);
	void Check_AddEventHandler(const SLuaClass& luaClass);

	bool IsBuiltInType(const std::string& szType) const;
	bool IsValidDefine(const std::string& szDef) const;
	bool IsSelfOrBaseClass(const std::string& szThisClassName, const std::string& baseClassName) const;

	std::string getFieldType(const SLuaClass* luaClass, const char* szField, bool searchDerive) const;		//searchDerive 在此type中查找不到时，是否查找drive的type
	bool ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const;		//方法声明的参数
	bool ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const;			//方法function(的实际参数
	bool ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const;		//调用方法的参数
	bool GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const;

private:
	std::string m_strConfigsDir;
	std::string m_strLuaDir;
	std::string m_strNetProtoFileName;
	std::string m_strTemplateProtoFileName;
	std::map<std::string, SLuaClass>	m_mapLuaClass;
	std::map<std::string, SLuaFile>		m_mapLuaFile;

	std::vector<SLuaFieldToken>		m_errorTokenList;
	std::vector<SLuaFieldToken>		m_errorDefineList;
	std::set<SLuaFieldToken>  m_dupLuaFieldList;
	std::set<SLuaFunctionToken>  m_dupFunctionList;
	std::map<std::string, std::set<SLuaFieldToken>>		m_errorNameFieldMap;
	std::map<std::string, std::set<SLuaFunctionToken>>		m_errorNameFunctionMap;
	std::vector<SLuaFieldToken>		m_errorUserDataFieldList;
	std::vector<SLuaTimerToken>		m_errorTimerList;
	std::map<std::string, STableRemoveCheckEntry>		m_tableCheckMap;

	std::vector<SOutputEntry4>	m_invalidGlobalFieldList;		//错误的全局变量使用，即全局变量在本类中使用
	std::vector<SOutputEntry3>  m_invalidRepeatedFieldList;		//
	std::map<std::string, std::list<std::tuple<std::string, int, int, int>>> m_ErrorMethodNumReturnMap;		//错误的函数返回值
	std::map<std::string, std::list<std::tuple<std::string, int, std::string>>> m_ErrorAddHandlerMap;		//错误的函数返回值

	std::set<int>	m_GameTextKeySet;

	//数据
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

template <class T>
void CLplusChecker::Check_AllMethodusedIndirectToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5_SISII>& entryParamSet)
{
	for (const auto& token : luaClass.functionAllUsedIndirectList)
	{
		if (token.bHasFunction || token.bIsStatic)			//非static方法
			continue;

		bool skip = false;
		for (const auto& entry : m_MethodParamList)		//特殊的参数匹配,和unity内部函数重名
		{
			const auto& name = std::get<0>(entry);
			int numParams = std::get<1>(entry);

			if (name == token.token && numParams == (int)token.vParams.size())
			{
				skip = true;
				break;
			}
		}

		if (skip)
			continue;

		bool bFound = false;		//是否找到匹配的
		bool bMatch = false;
		for (const auto& entry : m_mapLuaClass)				//检查token是否在所有类中有定义
		{
			for (const auto& func : entry.second.functionDefList)
			{
				if (!func.bIsStatic && func.token == token.token)		//名字一致，检查类型
				{
					bFound = true;
					bMatch = func.vParams.size() == token.vParams.size();

					if (bMatch)
						break;
				}
			}

			if (bMatch)
				break;
		}

		if (bFound && !bMatch)
		{
			entryParamSet.insert(SOutputEntry5_SISII(
				token.token,
				(int)token.vParams.size(),
				luaClass.strName,
				token.location.line,
				token.location.col));
		}
	}
}

template <class T>
void CLplusChecker::Check_AllSpecialMethodusedIndirectToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5_SISII>& entryParamSet)
{
	for (const auto& token : luaClass.functionSpecialUsedIndirect)
	{
		if (token.bHasFunction)			//非static方法
			continue;

		bool bFound = false;		//是否找到匹配的
		bool bMatch = false;

		auto itr = m_SpecialMethodParamMap.find(token.token);
		if (itr != m_SpecialMethodParamMap.end())
		{
			bFound = true;

			const std::vector<int>& paramList = itr->second;
			bMatch = std::find(paramList.begin(), paramList.end(), (int)token.vParams.size()) != paramList.end();
		}

		if (bFound && !bMatch)
		{
			entryParamSet.insert(SOutputEntry5_SISII(
				token.token,
				(int)token.vParams.size(),
				luaClass.strName,
				token.location.line,
				token.location.col));
		}
	}
}

template <class T>
void CLplusChecker::Check_AllGlobalFieldUsedToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5>& entrySet)
{
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		for (const auto& token : luaClass.fieldUsedGlobalList)
		{
			const SLuaClass* ownerClass = GetLuaClass(token.className.c_str());
			if (ownerClass)
			{
				bool bFound = false;
				const SLuaFieldToken* pFieldToken = NULL;

				const SLuaClass* thisClass = ownerClass;
				while (thisClass)
				{
					for (const auto& func : thisClass->fieldDefList)
					{
						if (token.token == func.token)
						{
							pFieldToken = &func;
							bFound = true;
							break;
						}
					}

					if (bFound)
						break;

					thisClass = thisClass->parent;
				}

				if (!bFound)
				{
					entrySet.insert(SOutputEntry5(
						token.token,
						token.className,
						luaClass.strName,
						token.location.line,
						token.location.col));
				}
			}
		}
	}
}

template <class T>
void CLplusChecker::Check_AllGlobalMethodUsedToFile(FILE* pFile, const T& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet)
{
	for (const auto& token : luaClass.functionUsedGlobalList)
	{
		const SLuaClass* ownerClass = GetLuaClass(token.className.c_str());

		if (ownerClass)
		{
			bool bFound = false;
			const SLuaFunctionToken* pFuncToken = NULL;

			const SLuaClass* thisClass = ownerClass;
			while (thisClass)
			{
				for (const auto& func : thisClass->functionDefList)
				{
					if (token.token == func.token)
					{
						pFuncToken = &func;
						bFound = true;
						break;
					}
				}

				if (bFound)
					break;

				thisClass = thisClass->parent;
			}

			if (!bFound)
			{
				entrySet.insert(SOutputEntry5(
					token.token,
					token.className,
					luaClass.strName,
					token.location.line,
					token.location.col));
			}

			if (bFound)			   //检查param类型
			{
				if (!token.bHasFunction)		//跳过function类型
				{
					if (pFuncToken->vParams.size() != token.vParams.size())
					{
						entryParamSet.insert(SOutputEntry7(
							token.token,
							token.className,
							(int)token.vParams.size(),
							(int)pFuncToken->vParams.size(),
							luaClass.strName,
							token.location.line,
							token.location.col));
					}
				}
			}
		}
	}
}

template <class T>
void CLplusChecker::Check_GameTextUsedToFile(const T& luaClass, std::set<SStringTableToken>& entrySet)
{
	for (const auto& entry : luaClass.stringTableUsedList)
	{
		if (m_GameTextKeySet.find(entry.text_id) == m_GameTextKeySet.end())
		{
			entrySet.insert(entry);
		}
	}
}

