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
		return location == rhs.location && token == rhs.token && className == rhs.className && typeName == rhs.typeName;
	}
};

struct SLuaFunctionToken
{
	SLuaFunctionToken()
	{
		bHasFunction = false;
		bIsVirtual = false;
		bIsOverride = false;
	}

	SLocation location;
	std::string token;
	std::string className;			//token所属的class名
	std::vector<std::string> vParams;
	std::vector<std::string> vRets;
	bool bHasFunction;
	bool bIsVirtual;
	bool bIsOverride;

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
		else if (bHasFunction != rhs.bHasFunction)
			return bHasFunction < rhs.bHasFunction;
		else if (bIsVirtual != rhs.bIsVirtual)
			return bIsVirtual < rhs.bIsVirtual;
		else
			return bIsOverride < rhs.bIsOverride;
	}

	bool operator==(const SLuaFunctionToken& rhs) const
	{
		return location == rhs.location &&
			token == rhs.token && className == rhs.className
			&& vParams == rhs.vParams && vRets == rhs.vRets;
	}
};

struct SLuaEventToken
{
	SLocation location;
	std::string eventName;
	std::string className;			//token所属的class名

	bool operator<(const SLuaEventToken& rhs) const
	{
		if (className != rhs.className)
			return className < rhs.className;
		else if (location != rhs.location)
			return location < rhs.location;
		else 
			return eventName < rhs.eventName;
	}

	bool operator==(const SLuaEventToken& rhs) const
	{
		return className == rhs.className && location == rhs.location && eventName == rhs.eventName;
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
		if (className !=  rhs.className)
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

struct SLuaDotweenToken
{
	SLocation location;
	std::string dotweenName;
	bool hasCallback;
	std::string className;			//token所属的class名

	bool operator<(const SLuaDotweenToken& rhs) const
	{
		if (className != rhs.className)
			return className < rhs.className;
		else if (location != rhs.location)
			return location < rhs.location;
		else if (dotweenName != rhs.dotweenName)
			return dotweenName < rhs.dotweenName;
		else
			return hasCallback < rhs.hasCallback;
	}

	bool operator==(const SLuaDotweenToken& rhs) const
	{
		return className == rhs.className && location == rhs.location && dotweenName == rhs.dotweenName && hasCallback == rhs.hasCallback;
	}
};

struct SLuaStringFormatToken
{
	SLocation location;
	std::string format;
	int strTableNum;
	std::string className;			//token所属的class名

	bool operator<(const SLuaStringFormatToken& rhs) const
	{
		if (className != rhs.className)
			return className < rhs.className;
		else if (location != rhs.location)
			return location < rhs.location;
		else if (format != rhs.format)
			return format < rhs.format;
		else
			return strTableNum < rhs.strTableNum;
	}

	bool operator==(const SLuaStringFormatToken& rhs) const
	{
		return className == rhs.className && location == rhs.location && format == rhs.format && strTableNum == rhs.strTableNum;
	}
};

struct SLuaClass
{
	const SLuaClass* parent;

	std::string strFileName;
	std::string strName;

	std::set<SLuaFieldToken>	fieldDefList;
	std::set<SLuaFunctionToken>	functionDefList;				//所有的方法定义
	std::set<SLuaFunctionToken>	functionVirtualDefList;
	std::set<SLuaFunctionToken>	functionOverrideDefList;

	std::set<SLuaEventToken>	eventAddList;
	std::set<SLuaEventToken>	eventRemoveList;

	std::set<SLuaTimerToken>   timerAddList;
	std::set<SLuaTimerToken>   timerRemoveList;

	std::set<SLuaDotweenToken>   dotweenList;
	std::set<SLuaStringFormatToken>  stringFormatList;
};

class CLuaRulesChecker
{
public:
	explicit CLuaRulesChecker(const std::string& strLuaDir);

public:
	bool BuildLuaClasses();

	bool GetLuaClassUsedMembers();

	bool CheckLuaClassesToFile(const char* strFileName);

	void PrintLuaClasses();

	const SLuaClass* GetLuaClass(const char* szName) const;
	SLuaClass* GetLuaClass(const char* szName);
	SLuaClass* AddLuaClass(const char* szName);

private:
	bool BuildLuaClass(AFile* pFile, std::map<std::string, SLuaClass>& luaClass);

	bool GetLuaClassUsedMembers(AFile* pFile, const std::map<std::string, SLuaClass>& luaClass);

	void HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);
	void HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current);

	std::string HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current);
	std::string HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current);
	
	void HandleLine_AddEventDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_RemoveEventDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_AddGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_RemoveGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_DotweenDefine(const char* szLine, int nLine, SLuaClass* current);
	void HandleLine_StringFormatDefine(const char* szLine, int nLine, SLuaClass* current);

	bool ParseFunctionToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const;

	void Check_UserDataFieldCleanUp(const SLuaClass& luaClass, bool isUIClass);
	void Check_TimerCleanup(const SLuaClass& luaClass, bool isUIClass);
	void Check_EventCleanup(const SLuaClass& luaClass, bool isUIClass);

	bool ContainsTimer(const SLuaClass& luaClass) const;
	bool ContainsDotweenWithCallback(const SLuaClass& luaClass) const;

private:
	std::string m_strLuaDir;
	std::map<std::string, SLuaClass>	m_mapLuaClass;

	std::map<std::string, std::list<SLuaFieldToken>>		m_errorUserDataFieldMap;
	std::vector<SLuaEventToken>     m_errorEventList;
	std::vector<SLuaTimerToken>		m_errorTimerList;

};