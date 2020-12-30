#pragma once

#include <vector>
#include <set>
#include <map>
#include <list>
#include <string>

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
	SLuaFieldToken(bool isConst) : bIsConst(isConst) {}

	SLocation location;
	std::string token;
	std::string className;			//token所属的类名
	std::string typeName;			//字段类型
	bool bIsConst;				//是否是const

	bool operator<(const SLuaFieldToken& rhs) const
	{
		if (location != rhs.location)
			return location < rhs.location;
		else if (token != rhs.token)
			return token < rhs.token;
		else if (className != rhs.className)
			return className < rhs.className;
		else if (typeName != rhs.typeName)
			return typeName < rhs.typeName;
		else
			return bIsConst < rhs.bIsConst;
	}

	bool operator==(const SLuaFieldToken& rhs) const
	{
		return location == rhs.location &&
			token == rhs.token &&
			className == rhs.className &&
			typeName == rhs.typeName &&
			bIsConst == rhs.bIsConst;
	}
};

struct SLuaFunctionToken
{
	SLuaFunctionToken(bool isVirtual, bool isOverride, bool isFinal, bool isStatic)
		: bIsVirtual(isVirtual), bIsOverride(isOverride), bIsFinal(isFinal), bIsStatic(isStatic)
	{
		bHasFunction = false;
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
	bool bIsFinal;
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
		else if (bIsOverride != rhs.bIsOverride)
			return bIsOverride < rhs.bIsOverride;
		else if (bIsFinal != rhs.bIsFinal)
			return bIsFinal < rhs.bIsFinal;
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
			bHasFunction == rhs.bHasFunction &&
			bIsVirtual == rhs.bIsVirtual &&
			bIsOverride == rhs.bIsOverride &&
			bIsFinal == rhs.bIsFinal &&
			bIsStatic == rhs.bIsStatic;
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
	SLuaClass* parent = nullptr;

	std::string strFileName;
	std::string strName;

	int nStartLine = 0;
	int nEndLine = 0;

	std::set<SLuaFieldToken>	fieldDefList;
	std::set<SLuaFunctionToken>	functionDefList;

	std::set<SLocation>		errorDefList;		//错误的def.

	int getHierachyNum() const
	{
		int count = 0;
		SLuaClass* p = parent;
		while (p)
		{
			++count;
			p = p->parent;
		}
		return count;
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

