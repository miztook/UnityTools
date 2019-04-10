#include "CLplusChecker.h"
#include "function.h"
#include "stringext.h"


bool CLplusChecker::IsBuiltInType(const std::string& szType) const
{
	for (const auto& entry : m_BuiltInTypeList)
	{
		if (szType.compare(entry) == 0)
			return true;
	}
	return false;
}

bool CLplusChecker::IsValidDefine(const std::string& szDef) const
{
	for (const auto& entry : m_ValidDefineList)
	{
		if (strncmp(entry.c_str(), szDef.c_str(), entry.length()) == 0)
			return true;
	}
	return false;
}

bool CLplusChecker::IsSelfOrBaseClass(const std::string& szThisClassName, const std::string& baseClassName) const
{
	const SLuaClass* thisClass = GetLuaClass(szThisClassName.c_str());
	const SLuaClass* baseClass = GetLuaClass(baseClassName.c_str());
	if (!thisClass || !baseClass)
	{
		assert(false);
		return false;
	}

	return thisClass->IsSelfOrParent(baseClass);
}

void CLplusChecker::PrintLuaClasses()
{
	std::set<std::string> strTypeSet;
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		printf("%s : %s %d, %d, %d, %d\n",
			luaClass.strName.c_str(),
			(luaClass.parent ? luaClass.parent->strName.c_str() : "NULL"),
			(int)luaClass.fieldDefList.size(),
			(int)luaClass.fieldUsedList.size(),
			(int)luaClass.functionDefList.size(),
			(int)luaClass.functionUsedList.size());

		for (const auto& kv : luaClass.fieldDefList)
		{
			if (!IsBuiltInType(kv.typeName.c_str()))
			{
				strTypeSet.insert(kv.typeName);
			}

			printf("%s %s\n", kv.token.c_str(), kv.typeName.c_str());
		}
	}

	/*
	for (const auto& entry : m_mapLuaClass)
	{
	const auto& luaClass = entry.second;

	for (const auto& token : luaClass.fieldUsedIndirectList)
	{
	if (IsBuiltInType(token.className))
	{
	int x = 0;
	}

	printf("%s %d %d %s %s\n", luaClass.strName, token.line, token.col, token.token, token.className);
	}
	}
	*/

	/*
	for (const auto& typeName : strTypeSet)
	{
	bool bFound = false;
	for (const auto& entry : m_mapLuaClass)
	{
	if (entry.first == typeName)
	{
	bFound = true;
	break;
	}
	}

	if (!bFound)
	{
	int p = 0;
	}
	}
	*/
}

void CLplusChecker::HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
{
	const char* p = strstr(szLine, "Lplus.Class(\"");
	if (p)
	{
		p += strlen("Lplus.Class(\"");
		const char* start = p;
		const char* end = strstr(start, "\")");
		ASSERT(end);
		if (end)
		{
			char name[1024];
			strncpy(name, start, end - start);
			name[end - start] = '\0';

			SLuaClass* luaClass = GetLuaClass(name);
			if (!luaClass)
			{
				luaClass = AddLuaClass(name);
				luaClass->strFileName = szFileName;
				luaClass->strName = name;
				luaClass->parent = NULL;
			}
			else if (luaClass->strFileName.empty())
			{
				luaClass->strFileName = szFileName;
			}
			current = luaClass;
		}
	}
	else
	{
		p = strstr(szLine, "Lplus.Class('");
		if (p)
		{
			p += strlen("Lplus.Class('");
			const char* start = p;
			const char* end = strstr(start, "')");
			ASSERT(end);
			if (end)
			{
				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				SLuaClass* luaClass = GetLuaClass(name);
				if (!luaClass)
				{
					luaClass = AddLuaClass(name);
					luaClass->strFileName = szFileName;
					luaClass->strName = name;
					luaClass->parent = NULL;
				}
				else if (luaClass->strFileName.empty())
				{
					luaClass->strFileName = szFileName;
				}
				current = luaClass;
			}
		}
	}
}

void CLplusChecker::HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
{
	const char* p = strstr(szLine, "Lplus.Extend(");
	p += strlen("Lplus.Extend(");
	const char* start = p;
	const char* end = strstr(start, ",");
	if (!end)
		return;

	if (strstr(end, "\"") != NULL && strstr(end, "\")") != NULL)					//双引号
	{
		//base
		char basename[1024];
		strncpy(basename, start, end - start);
		basename[end - start] = '\0';

		SLuaClass* baseClass = GetLuaClass(basename);
		if (!baseClass)
		{
			baseClass = AddLuaClass(basename);
			//baseClass->strFileName = szFileName;
			baseClass->strName = basename;
			baseClass->parent = NULL;
		}

		//extend
		start = strstr(end, "\"") + 1;
		end = strstr(start, "\")");

		char extname[1024];
		strncpy(extname, start, end - start);
		extname[end - start] = '\0';

		SLuaClass* luaClass = GetLuaClass(extname);
		if (!luaClass)
		{
			luaClass = AddLuaClass(extname);
			luaClass->strFileName = szFileName;
			luaClass->strName = extname;
		}
		else if (luaClass->strFileName.empty())
		{
			luaClass->strFileName = szFileName;
		}
		luaClass->parent = baseClass;

		current = luaClass;
	}
	else if (strstr(end, "'") != NULL && strstr(end, "')") != NULL)					//单引号
	{
		//base
		char basename[1024];
		strncpy(basename, start, end - start);
		basename[end - start] = '\0';

		SLuaClass* baseClass = GetLuaClass(basename);
		if (!baseClass)
		{
			baseClass = AddLuaClass(basename);
			//baseClass->strFileName = szFileName;
			baseClass->strName = basename;
			baseClass->parent = NULL;
		}

		//extend
		start = strstr(end, "'") + 1;
		end = strstr(start, "')");

		char extname[1024];
		strncpy(extname, start, end - start);
		extname[end - start] = '\0';

		SLuaClass* luaClass = GetLuaClass(extname);
		if (!luaClass)
		{
			luaClass = AddLuaClass(extname);
			luaClass->strFileName = szFileName;
			luaClass->strName = extname;
		}
		else if (luaClass->strFileName.empty())
		{
			luaClass->strFileName = szFileName;
		}
		luaClass->parent = baseClass;

		current = luaClass;
	}
}

std::string CLplusChecker::HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		if (current->strName == "CPanelUIActivity")
		{
			int x = 0;
		}

		const char* pTypeStart;
		const char* pTypeEnd;
		char typeName[128] = { 0 };

		const char* p = strstr(szLine, "def.field(");
		p += strlen("def.field(");

		if (*p == '\"' || *p == '\'')
			pTypeStart = p + 1;
		else
			pTypeStart = p;

		p = strstr(p, ")");
		ASSERT(p);

		if (*(p - 1) == '\"' || *(p - 1) == '\'')
			pTypeEnd = p - 1;
		else
			pTypeEnd = p;

		ASSERT(pTypeEnd > pTypeStart);
		{
			strncpy_s(typeName, 128, pTypeStart, pTypeEnd - pTypeStart);
			typeName[pTypeEnd - pTypeStart] = '\0';

			const char* pt = strrchr(typeName, '.');
			if (pt &&
				*(pt + 1) != '\0')
			{
				char tmp[1024];
				strcpy(tmp, pt + 1);
				strcpy(typeName, tmp);
			}
		}

		p += 1;
		const char* start = strstr(p, ".");
		ASSERT(start);
		start += 1;

		const char* end = strstr_anyof(start, " ", "\t");
		const char* t = strstr(start, "=");
		if (!end)
			end = t;
		else if (t && end > t)
			end = t;

		if (end)
		{
			//field
			char name[1024];
			strncpy_s(name, 128, start, end - start);
			name[end - start] = '\0';

			SLuaFieldToken fieldToken;
			fieldToken.location.line = nLine;
			fieldToken.location.col = start - szLine;
			fieldToken.token = name;
			fieldToken.className = current->strName;
			fieldToken.typeName = typeName;

			//检查重复定义
			for (const auto& e : current->fieldDefList)
			{
				if (e.token == name &&
					//e.typeName == typeName &&
					IsSelfOrBaseClass(fieldToken.className.c_str(), e.className.c_str()))
				{
					m_dupLuaFieldList.insert(fieldToken);
					break;
				}
			}

			current->fieldDefList.insert(fieldToken);

			ret = name;
		}
		else
		{
			int xxx = 0;
		}
	}
	return ret;
}

std::string CLplusChecker::HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;
		std::vector<std::string> vActParams;

		const char* p = strstr(szLine, "def.method(");
		p += strlen("def.method(");

		const char* pStart = p - 1;

		p = strstr(p, ")");
		ASSERT(p);

		ParseFunctionDeclToken(pStart, p, vParams, vRets);				//解析参数，返回值

		{
			const char* func = strrchr(szLine, '(');
			if (func)
				ParseFunctionParamToken(func, vActParams);
		}

		p += 1;
		const char* start = strstr(p, ".");
		ASSERT(start);
		start += 1;

		const char* end = strstr_anyof(start, " ", "\t");
		const char* t = strstr(start, "=");
		if (!end)
			end = t;
		else if (t && end > t)
			end = t;

		if (end)
		{
			//field
			char name[1024];
			strncpy_s(name, 128, start, end - start);
			name[end - start] = '\0';

			SLuaFunctionToken usedToken;
			usedToken.location.line = nLine;
			usedToken.location.col = start - szLine;
			usedToken.token = name;
			usedToken.className = current->strName;
			usedToken.vParams = vParams;
			usedToken.vRets = vRets;
			usedToken.vActParams = vActParams;

			//检查重复定义
			for (const auto& e : current->functionDefList)
			{
				if ((!usedToken.bIsOverride || !e.bIsVirtual) &&
					e.token == usedToken.token &&
					IsSelfOrBaseClass(usedToken.className, e.className))
				{
					m_dupFunctionList.insert(usedToken);
					break;
				}
			}

			current->functionDefList.insert(usedToken);

			SLuaFieldToken fieldToken;
			fieldToken.location.line = nLine;
			fieldToken.location.col = start - szLine;
			fieldToken.token = name;
			fieldToken.className = current->strName;
			fieldToken.typeName = "FUNCTION";
			current->fieldDefList.insert(fieldToken);

			ret = name;
		}
	}

	return ret;
}

std::string CLplusChecker::HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;
		std::vector<std::string> vActParams;

		const char* p = strstr(szLine, "def.virtual(");
		p += strlen("def.virtual(");

		const char* pStart = p - 1;

		p = strstr(p, ")");
		ASSERT(p);

		ParseFunctionDeclToken(pStart, p, vParams, vRets);				//解析参数，返回值

		{
			const char* func = strrchr(szLine, '(');
			if (func)
				ParseFunctionParamToken(func, vActParams);
		}

		p += 1;
		const char* start = strstr(p, ".");
		ASSERT(start);
		start += 1;

		const char* end = strstr_anyof(start, " ", "\t");
		const char* t = strstr(start, "=");
		if (!end)
			end = t;
		else if (t && end > t)
			end = t;

		if (end)
		{
			//field
			char name[1024];
			strncpy_s(name, 128, start, end - start);
			name[end - start] = '\0';

			SLuaFunctionToken usedToken;
			usedToken.location.line = nLine;
			usedToken.location.col = start - szLine;
			usedToken.token = name;
			usedToken.className = current->strName;
			usedToken.vParams = vParams;
			usedToken.vRets = vRets;
			usedToken.vActParams = vActParams;
			usedToken.bIsVirtual = true;

			//检查重复定义
			for (const auto& e : current->functionDefList)
			{
				if ((!usedToken.bIsOverride || !e.bIsVirtual) &&
					e.token == usedToken.token &&
					IsSelfOrBaseClass(usedToken.className, e.className))
				{
					m_dupFunctionList.insert(usedToken);
					break;
				}
			}

			current->functionVirtualDefList.insert(usedToken);
			current->functionDefList.insert(usedToken);
			//current->fieldDefList.insert(name);

			ret = name;
		}
	}

	return ret;
}

std::string CLplusChecker::HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;
		std::vector<std::string> vActParams;

		const char* p = strstr(szLine, "def.override(");
		p += strlen("def.override(");

		const char* pStart = p - 1;

		p = strstr(p, ")");

		ParseFunctionDeclToken(pStart, p, vParams, vRets);				//解析参数，返回值

		{
			const char* func = strrchr(szLine, '(');
			if (func)
				ParseFunctionParamToken(func, vActParams);
		}

		ASSERT(p);
		p += 1;
		const char* start = strstr(p, ".");
		ASSERT(start);
		start += 1;

		const char* end = strstr_anyof(start, " ", "\t");
		const char* t = strstr(start, "=");
		if (!end)
			end = t;
		else if (t && end > t)
			end = t;

		if (end)
		{
			//field
			char name[1024];
			strncpy_s(name, 128, start, end - start);
			name[end - start] = '\0';

			SLuaFunctionToken usedToken;
			usedToken.location.line = nLine;
			usedToken.location.col = start - szLine;
			usedToken.token = name;
			usedToken.className = current->strName;
			usedToken.vParams = vParams;
			usedToken.vActParams = vActParams;
			usedToken.vRets = vRets;
			usedToken.bIsOverride = true;

			//检查重复定义
			for (const auto& e : current->functionDefList)
			{
				if (usedToken.bIsOverride && (e.bIsVirtual || e.bIsOverride))
					continue;

				if (e.token == usedToken.token &&
					IsSelfOrBaseClass(usedToken.className, e.className))
				{
					m_dupFunctionList.insert(usedToken);
					break;
				}
			}

			current->functionOverrideDefList.insert(usedToken);

			current->functionDefList.insert(usedToken);
			//current->fieldDefList.insert(name);

			ret = name;
		}
	}

	return ret;
}

std::string CLplusChecker::HandleLine_StaticDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;
		std::vector<std::string> vActParams;

		const char* p = strstr(szLine, "def.static(");
		p += strlen("def.static(");

		const char* pStart = p - 1;

		p = strstr(p, ")");
		ASSERT(p);

		ParseFunctionDeclToken(pStart, p, vParams, vRets);				//解析参数，返回值

		{
			const char* func = strrchr(szLine, '(');
			if (func)
				ParseFunctionParamToken(func, vActParams);
		}

		p += 1;
		const char* start = strstr(p, ".");
		ASSERT(start);
		start += 1;

		const char* end = strstr_anyof(start, " ", "\t");
		const char* t = strstr(start, "=");
		if (!end)
			end = t;
		else if (t && end > t)
			end = t;

		if (end)
		{
			//field
			char name[1024];
			strncpy_s(name, 128, start, end - start);
			name[end - start] = '\0';

			SLuaFunctionToken usedToken;
			usedToken.location.line = nLine;
			usedToken.location.col = start - szLine;
			usedToken.token = name;
			usedToken.className = current->strName;
			usedToken.vParams = vParams;
			usedToken.vRets = vRets;
			usedToken.vActParams = vActParams;
			usedToken.bIsStatic = true;

			//检查重复定义
			for (const auto& e : current->functionDefList)
			{
				if ((!usedToken.bIsOverride || !e.bIsVirtual) &&
					e.token == usedToken.token &&
					IsSelfOrBaseClass(usedToken.className, e.className))
				{
					m_dupFunctionList.insert(usedToken);
					break;
				}
			}

			current->functionDefList.insert(usedToken);

			SLuaFieldToken fieldToken;
			fieldToken.location.line = nLine;
			fieldToken.location.col = start - szLine;
			fieldToken.token = name;
			fieldToken.className = current->strName;
			fieldToken.typeName = "FUNCTION";
			current->fieldDefList.insert(fieldToken);

			ret = name;
		}
	}

	return ret;
}

void CLplusChecker::HandleLine_AddGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "_G.AddGlobalTimer");
		ASSERT(p);

		SLuaTimerToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		//检查=
		{
			std::string strId;
			char eq = '\0';
			int len = (int)(p - szLine) - 1;
			int end = 0;
			int start = -1;
			for (int n = len; n >= 0; --n)
			{
				if (eq == '\0' && (szLine[n] == ' ' || szLine[n] == '\t'))
					continue;

				if (eq == '\0')			//找 =
				{
					eq = szLine[n];
					if (eq != '=')
						break;
					end = n - 1;
					while (szLine[end] == ' ' || szLine[end] == '\t')
					{
						if (end <= 0)
							break;
						--end;
					}
				}

				if (end > 0 && n < end && start == -1)
				{
					if (szLine[n] == ' ' || szLine[n] == '\t')
					{
						start = n;
						break;
					}
				}
			}

			if (end > 0 && start >= 0)
			{
				char name[256];
				strncpy_s(name, 256, &szLine[start], end + 1 - start);
				name[end + 1 - start] = '\0';

				strId = name;
				trim(strId, "\t ");

				usedToken.id = strId;
			}
		}

		p += strlen("_G.AddGlobalTimer");
		ASSERT(p);

		p = strstr(p, "(");
		ASSERT(p);
		p += 1;

		const char* start = p;

		const char* end1 = strstr(p, ",");
		ASSERT(end1);
		p = end1 + 1;
		if (end1)
		{
			//field
			char name[256];
			strncpy_s(name, 256, start, end1 - start);
			name[end1 - start] = '\0';

			std::string ttl = name;
			trim(ttl, "\t ");

			usedToken.ttl = ttl;
		}

		start = p;
		const char* end2 = strstr(p, ",");
		ASSERT(end2);
		p = end2 + 1;
		if (end2)
		{
			//field
			char name[256];
			strncpy_s(name, 256, start, end2 - start);
			name[end2 - start] = '\0';

			std::string once = name;
			trim(once, "\t ");

			usedToken.runonce = once;
		}

		current->timerAddList.insert(usedToken);
	}
}

void CLplusChecker::HandleLine_RemoveGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "_G.RemoveGlobalTimer");
		ASSERT(p);

		SLuaTimerToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		p += strlen("_G.RemoveGlobalTimer");
		ASSERT(p);

		p = strstr(p, "(");
		ASSERT(p);
		p += 1;

		const char* start = p;

		const char* end = strstr(p, ")");
		ASSERT(end);
		if (end)
		{
			//field
			char name[256];
			strncpy_s(name, 256, start, end - start);
			name[end - start] = '\0';

			std::string strId = name;
			trim(strId, "\t ");

			usedToken.id = strId;
		}

		current->timerRemoveList.insert(usedToken);
	}
}

void CLplusChecker::HandleLine_StringTableUse(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "StringTable.Get(");
		ASSERT(p);

		SStringTableToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		p += strlen("StringTable.Get(");
		const char* start = p;

		const char* end = strstr(p, ")");
		ASSERT(end);
		if (end)
		{
			bool bNumber = true;
			for (const char* k = start; k < end; ++k)
			{
				if (*k != ' ' && *k != '\t' && !isdigit(*k))
				{
					bNumber = false;
					break;
				}
			}

			if (bNumber)
			{
				//field
				char name[256];
				strncpy_s(name, 256, start, end - start);
				name[end - start] = '\0';

				std::string strId = name;
				trim(strId, "\t ");

				usedToken.text_id = atoi(strId.c_str());
				current->stringTableUsedList.insert(usedToken);
			}
		}
	}
}

void CLplusChecker::HandleLine_ErrorToken(const char* szLine, int nLine, const char* filename)
{
	for (const auto& entry : m_errorTokens)
	{
		const char* p = strstr(szLine, entry.c_str());
		if (p)
		{
			SLuaFieldToken fieldToken;
			fieldToken.location.line = nLine;
			fieldToken.location.col = p - szLine;
			fieldToken.token = entry;
			fieldToken.className = filename;
			fieldToken.typeName = "";

			m_errorTokenList.push_back(fieldToken);
		}
	}
}

void CLplusChecker::HandleLine_TableRemoveCheck(const char* szLine, int nLine, const char* filename)
{
	std::string fname = filename;
	if (m_tableCheckMap.find(fname) == m_tableCheckMap.end())
	{
		STableRemoveCheckEntry entry;
		entry.nInverseFor = 0;
		entry.nTableRemove = 0;
		m_tableCheckMap[fname] = entry;
	}

	if (strstr(szLine, "for i=#") || strstr(szLine, "for i= #") || strstr(szLine, "for i =#") || strstr(szLine, "for i = #"))
	{
		STableRemoveCheckEntry& entry = m_tableCheckMap[fname];
		entry.nInverseFor += 1;
	}
	else
	{
		const char* p = strstr(szLine, "table.remove(");
		if (p && strstr(p + strlen("table.remove("), "i)"))
		{
			STableRemoveCheckEntry& entry = m_tableCheckMap[fname];
			entry.nTableRemove += 1;
		}
	}
}

void CLplusChecker::HandleLine_ErrorDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "def.");
		p += strlen("def.");

		if (!IsValidDefine(p))
		{
			SLuaFieldToken fieldToken;
			fieldToken.location.line = nLine;
			fieldToken.location.col = p - szLine;
			fieldToken.token = "";
			fieldToken.className = current->strName;
			fieldToken.typeName = "";

			m_errorDefineList.push_back(fieldToken);
		}
	}
}

void CLplusChecker::Get_SelfFieldUsedDirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current && strstr(szLine, "self.") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		while (p - szLine < len)
		{
			if (strstr(p, "self.") != NULL)
			{
				p = strstr(p, "self.");
				p += strlen("self.");

				while (*p == ' ' || *p == '\t') ++p;			//去掉空格

				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}
				p = end;

				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				SLuaFieldToken usedToken;
				usedToken.location.line = nLine;
				usedToken.location.col = start - szLine;
				usedToken.token = name;
				usedToken.className = current->strName;
				usedToken.typeName = getFieldType(current, name, false);

				current->fieldUsedList.insert(usedToken);
			}
			else
			{
				p += 1;
			}
		}
	}
}

void CLplusChecker::Get_SelfMethodUsedDirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current && strstr(szLine, "self:") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		while (p - szLine < len)
		{
			if (strstr(p, "self:") != NULL)
			{
				p = strstr(p, "self:");
				p += strlen("self:");

				while (*p == ' ' || *p == '\t') ++p;			//去掉空格

				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}

				p = end;

				bool bFunction;
				std::vector<std::string> vParams;
				ParseUseFunctionToken(p, vParams, bFunction);

				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				SLuaFunctionToken usedToken;
				usedToken.location.line = nLine;
				usedToken.location.col = start - szLine;
				usedToken.token = name;
				usedToken.className = current->strName;
				usedToken.vParams = vParams;
				usedToken.bHasFunction = bFunction;

				current->functionUsedList.insert(usedToken);
			}
			else
			{
				p += 1;
			}
		}
	}
}

void CLplusChecker::Get_SelfFieldUsedIndirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current && strstr(szLine, "self.") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		while (p - szLine < len)
		{
			if (strstr(p, "self.") != NULL)
			{
				p = strstr(p, "self.");
				p += strlen("self.");

				while (*p == ' ' || *p == '\t') ++p;			//去掉空格

				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}
				p = end;

				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				std::string strParentName = name;
				std::string strParentType;
				SLuaClass* parentClass = current;

				//现在开始检查直接字段后的间接字段
				while (*end == '.')
				{
					++end;
					while (*end == ' ' || *end == '\t') ++end;		//去掉空格

					strParentType = getFieldType(parentClass, strParentName.c_str(), false);
					parentClass = GetLuaClass(strParentType.c_str());

					if (!parentClass)
						break;

					start = end;

					while ((end == start) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
					{
						++end;
					}

					//field name
					char fieldname[1024];
					strncpy(fieldname, start, end - start);
					fieldname[end - start] = '\0';

					if (IsBuiltInType(getFieldType(parentClass, fieldname, true)))
						break;

					strParentName = fieldname;

					SLuaFieldToken usedToken;
					usedToken.location.line = nLine;
					usedToken.location.col = start - szLine;
					usedToken.token = fieldname;
					usedToken.className = parentClass->strName;
					usedToken.typeName = getFieldType(parentClass, fieldname, true);

					current->fieldUsedIndirectList.insert(usedToken);
				}
			}
			else
			{
				p += 1;
			}
		}
	}
}

void CLplusChecker::Get_SelfMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current && strstr(szLine, "self.") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		while (p - szLine < len)
		{
			if (strstr(p, "self.") != NULL)
			{
				p = strstr(p, "self.");
				p += strlen("self.");

				while (*p == ' ' || *p == '\t') ++p;		//去掉空格

				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}
				p = end;

				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				std::string strParentName = name;
				std::string strParentType;
				SLuaClass* parentClass = current;

				bool bMethod = false;

				//现在开始检查直接字段后的间接字段
				while (*end == '.' ||
					*end == ':')
				{
					bMethod = *end == ':';

					++end;
					while (*end == ' ' || *end == '\t') ++end;		//去掉空格

					strParentType = getFieldType(parentClass, strParentName.c_str(), false);
					parentClass = GetLuaClass(strParentType.c_str());

					if (!parentClass)
						break;

					start = end;

					while ((end == start) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
					{
						++end;
					}

					//field name
					char fieldname[1024];
					strncpy(fieldname, start, end - start);
					fieldname[end - start] = '\0';

					strParentName = fieldname;

					if (bMethod)
					{
						bool bFunction;
						std::vector<std::string> vParams;
						ParseUseFunctionToken(end, vParams, bFunction);

						SLuaFunctionToken usedToken;
						usedToken.location.line = nLine;
						usedToken.location.col = start - szLine;
						usedToken.token = fieldname;
						usedToken.className = parentClass->strName;
						usedToken.vParams = vParams;
						usedToken.bHasFunction = bFunction;

						current->functionUsedIndirectList.insert(usedToken);

						break;
					}
				}
			}
			else
			{
				p += 1;
			}
		}
	}
}

void CLplusChecker::Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current && strstr(szLine, ":") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		const char* end = strstr(szLine, ":");

		for (int i = 0; i < len; ++i)
		{
			if (p[i] < -1 || p[i] > 255)
				return;
		}

		//现在开始检查直接字段后的间接字段
		while (end &&  *end == ':')
		{
			++end;
			while (*end == ' ' || *end == '\t') ++end;		//去掉空格

			const char* start = end;

			while ((end == start) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
			{
				++end;
			}

			//field name
			char fieldname[1024];
			strncpy(fieldname, start, end - start);
			fieldname[end - start] = '\0';

			bool bFunction;
			std::vector<std::string> vParams;
			if (ParseUseFunctionToken(end, vParams, bFunction))

			{
				SLuaFunctionToken usedToken;
				usedToken.location.line = nLine;
				usedToken.location.col = start - szLine;
				usedToken.token = fieldname;
				usedToken.className = "Unknown";
				usedToken.vParams = vParams;
				usedToken.bHasFunction = bFunction;

				current->functionAllUsedIndirectList.insert(usedToken);
			}

			end = strstr(end + 1, ":");
		}
	}

	/*
	if (current && strstr(szLine, ".") != NULL)
	{
		const char* p = szLine;
		int len = strlen(szLine);
		const char* end = strstr(szLine, ".");

		for (int i = 0; i < len; ++i)
		{
			if (p[i] < -1 || p[i] > 255)
				return;
		}

		//现在开始检查直接字段后的间接字段
		while (end &&  *end == '.')
		{
			++end;
			while (*end == ' ') ++end;		//去掉空格

			const char* start = end;

			while ((end == start) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
			{
				++end;
			}

			//field name
			char fieldname[1024];
			strncpy(fieldname, start, end - start);
			fieldname[end - start] = '\0';

			bool bFunction;
			std::vector<std::string> vParams;
			if (ParseUseFunctionToken(end, vParams, bFunction))
			{
				SLuaFunctionToken usedToken;
				usedToken.location.line = nLine;
				usedToken.location.col = start - szLine;
				usedToken.token = fieldname;
				usedToken.className = "Unknown";
				usedToken.vParams = vParams;
				usedToken.bHasFunction = bFunction;
				usedToken.bIsStatic = true;

				current->functionAllUsedIndirectList.insert(usedToken);
			}

			end = strstr(end + 1, ".");
		}
	}
	*/
}

void CLplusChecker::Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		std::string specialToken;
		for (const auto& entry : m_SpecialMethodParamMap)
		{
			const auto& str = entry.first;
			if (strstr(szLine, str.c_str()) != NULL)
			{
				specialToken = str;
				break;
			}
		}

		if (specialToken.empty())
			return;

		const char* p = szLine;
		int len = strlen(szLine);
		const char* end = strstr(szLine, specialToken.c_str());

		//现在开始检查直接字段后的间接字段
		if (end)
		{
			end += specialToken.length();

			bool bFunction;
			std::vector<std::string> vParams;
			if (ParseUseFunctionToken(end, vParams, bFunction))
			{
				SLuaFunctionToken usedToken;
				usedToken.location.line = nLine;
				usedToken.location.col = end - szLine;
				usedToken.token = specialToken;
				usedToken.className = "C#";
				usedToken.vParams = vParams;
				usedToken.bHasFunction = bFunction;

				current->functionSpecialUsedIndirect.insert(usedToken);
			}
		}
	}
}

void CLplusChecker::Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		std::string specialToken;
		std::string typeName;
		for (const auto& entry : m_GlobalClassList)
		{
			std::string str = std::get<0>(entry) + ".";
			if (strstr(szLine, str.c_str()) != NULL)
			{
				specialToken = str;
				typeName = std::get<1>(entry);
				break;
			}
		}

		if (specialToken.empty())
			return;

		const char* p = szLine;
		p = strstr(p, specialToken.c_str());
		p += strlen(specialToken.c_str());
		while (*p == ' ' || *p == '\t') ++p;			//去掉空格

		const char* start = p;
		const char* end = p;

		while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
		{
			++end;
			if (*end < 0 || *end >= 255)
				break;
		}
		p = end;

		char name[1024];
		strncpy(name, start, end - start);
		name[end - start] = '\0';

		SLuaFieldToken usedToken;
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = typeName;
		usedToken.typeName = "table";

		current->fieldUsedGlobalList.insert(usedToken);
	}
}

void CLplusChecker::Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		std::string specialToken;
		std::string typeName;
		for (const auto& entry : m_GlobalClassList)
		{
			std::string str = std::get<0>(entry) + ".";
			if (strstr(szLine, str.c_str()) != NULL)
			{
				specialToken = str;
				typeName = std::get<1>(entry);
				break;
			}
		}

		if (specialToken.empty())
			return;

		const char* p = strstr(szLine, specialToken.c_str());
		p += specialToken.length();

		while (*p == ' ' || *p == '\t') ++p;			//去掉空格
		const char* start = p;
		const char* end = p;
		while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
		{
			++end;
			if (*end < 0 || *end >= 255)
				break;
		}
		p = end;

		bool bFunction;
		std::vector<std::string> vParams;
		if (ParseUseFunctionToken(p, vParams, bFunction))
		{
			char name[1024];
			strncpy(name, start, end - start);
			name[end - start] = '\0';

			SLuaFunctionToken usedToken;
			usedToken.location.line = nLine;
			usedToken.location.col = end - szLine;
			usedToken.token = name;
			usedToken.className = typeName;
			usedToken.vParams = vParams;
			usedToken.bHasFunction = bFunction;

			current->functionUsedGlobalList.insert(usedToken);
		}
	}
}

void CLplusChecker::Check_MethodDefinitionToFile(FILE* pFile, const SLuaClass& luaClass)
{
	const auto& defFunctionList = luaClass.functionDefList;
	//检查参数的数量匹配
	for (const auto& token : defFunctionList)
	{
		if (!token.bIsStatic && (token.vParams.size() + 1 != token.vActParams.size()))
		{
			fprintf(pFile,
				"incorrect defined params number! method: %s, class %s, at line %d, col %d\n",
				token.token.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}
	}

	for (const auto& token : defFunctionList)
	{
		if (token.bIsStatic && token.vParams.size() != token.vActParams.size())
		{
			fprintf(pFile,
				"incorrect defined params number! static method: %s, class %s, at line %d, col %d\n",
				token.token.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}
	}

	//检查参数的class定义
	for (const auto& token : defFunctionList)
	{
		bool bMatch = true;

		std::string strError;
		for (const auto& param : token.vParams)
		{
			if (!GetLuaClass(param.c_str()) && !IsBuiltInType(param))
			{
				strError = param;
				bMatch = false;
				break;
			}
		}

		if (bMatch)
		{
			for (const auto& ret : token.vRets)
			{
				if (!GetLuaClass(ret.c_str()) && !IsBuiltInType(ret))
				{
					strError = ret;
					bMatch = false;
					break;
				}
			}
		}

		if (!bMatch)
		{
			fprintf(pFile,
				"invalid defined token method: %s (%s), class %s, at line %d, col %d\n",
				token.token.c_str(),
				strError.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}
	}
}

void CLplusChecker::Check_DuplicateField(const SLuaClass& luaClass)
{
	//对class的每个字段，检查是否在基类中出现
	const auto& fieldDefList = luaClass.fieldDefList;
	for (const auto& token : fieldDefList)
	{
		SLuaClass* pThisClass = luaClass.parent;
		while (pThisClass)
		{
			for (const auto& e : pThisClass->fieldDefList)
			{
				if (e.token == token.token &&
					//e.typeName == typeName &&
					IsSelfOrBaseClass(token.className, e.className))
				{
					m_dupLuaFieldList.insert(token);
				}
			}
			pThisClass = pThisClass->parent;
		}
	}
}

void CLplusChecker::Check_DuplicateMethod(const SLuaClass& luaClass)
{
	const auto& funcDefList = luaClass.functionDefList;
	for (const auto& token : funcDefList)
	{
		SLuaClass* pThisClass = luaClass.parent;
		while (pThisClass)
		{
			for (const auto& e : pThisClass->functionDefList)
			{
				if (token.bIsOverride && (e.bIsVirtual || e.bIsOverride))
					continue;

				if (e.token == token.token &&
					IsSelfOrBaseClass(token.className, e.className))
				{
					m_dupFunctionList.insert(token);
					break;
				}
			}
			pThisClass = pThisClass->parent;
		}
	}
}

void CLplusChecker::Check_FieldUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass)
{
	const auto& usedFieldList = luaClass.fieldUsedList;
	for (const auto& token : usedFieldList)
	{
		bool bFound = false;
		const SLuaClass* thisClass = &luaClass;
		while (thisClass)
		{
			for (const auto& entry : thisClass->fieldDefList)
			{
				if (token.token == entry.token)
				{
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
			fprintf(pFile,
				"undefined token field used self.%s(%s), class %s, at line %d, col %d\n",
				token.token.c_str(),
				token.className.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}
	}
}

void CLplusChecker::Check_MethodUsedDirectToFile(FILE* pFile, const SLuaClass& luaClass)
{
	const auto& usedFunctionList = luaClass.functionUsedList;
	for (const auto& token : usedFunctionList)
	{
		bool bFound = false;
		const SLuaFunctionToken* pFuncToken = NULL;

		const SLuaClass* thisClass = &luaClass;
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
			fprintf(pFile,
				"undefined token method used self:%s, class %s, at line %d, col %d\n",
				token.token.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}

		if (bFound)			   //检查param类型
		{
			if (!token.bHasFunction)		//跳过function类型
			{
				if (pFuncToken->vParams.size() != token.vParams.size())
				{
					fprintf(pFile,
						"incorrect token method params used self:%s (param count=%d, required=%d), class %s, at line %d, col %d\n",
						token.token.c_str(),
						(int)token.vParams.size(),
						(int)pFuncToken->vParams.size(),
						luaClass.strName.c_str(),
						token.location.line,
						token.location.col);
				}
			}
		}
	}
}

void CLplusChecker::Check_MethodInheritanceToFile(FILE* pFile, const SLuaClass& luaClass)
{
	const auto& overrideFuncionList = luaClass.functionOverrideDefList;
	for (const auto& token : overrideFuncionList)
	{
		bool bFound = false;

		const SLuaClass* thisClass = luaClass.parent ? luaClass.parent : NULL;
		while (thisClass)
		{
			for (const auto& func : thisClass->functionVirtualDefList)
			{
				if (token.token == func.token && token.vParams == func.vParams && token.vRets == func.vRets)
				{
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
			fprintf(pFile,
				"incorrect token override method (no virtual or <param return> mismatch in base) used self:%s, class %s, at line %d, col %d\n",
				token.token.c_str(),
				luaClass.strName.c_str(),
				token.location.line,
				token.location.col);
		}
	}
}

void CLplusChecker::Check_FieldUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet)
{
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		for (const auto& token : luaClass.fieldUsedIndirectList)
		{
			if (token.typeName == "")						//找不到field的类型
			{
				entrySet.insert(SOutputEntry5(
					token.token,
					token.className,
					luaClass.strName,
					token.location.line,
					token.location.col));
			}
			else
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
}

void CLplusChecker::Check_MethodUsedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet)
{
	for (const auto& token : luaClass.functionUsedIndirectList)
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

void CLplusChecker::Check_AllMethodusedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry7>& entryParamSet)
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
			entryParamSet.insert(SOutputEntry7(
				token.token,
				token.className,
				(int)token.vParams.size(),
				0,
				luaClass.strName,
				token.location.line,
				token.location.col));
		}
	}
}

void CLplusChecker::Check_AllStaticMethodusedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry7>& entryParamSet)
{
	for (const auto& token : luaClass.functionAllUsedIndirectList)
	{
		if (token.bHasFunction || !token.bIsStatic)			//static方法
			continue;

		bool skip = false;
		for (const auto& entry : m_StaticMethodParamList)		//特殊的参数匹配,和unity内部函数重名
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
				if (func.token == token.token)		//名字一致，检查类型
				{
					bFound = true;

					if (func.bIsStatic)
						bMatch = (func.vParams.size() == token.vParams.size());
					else
						bMatch = (func.vParams.size() + 1 == token.vParams.size());

					if (bMatch)
						break;
				}
			}

			if (bMatch)
				break;
		}

		if (bFound && !bMatch)
		{
			entryParamSet.insert(SOutputEntry7(
				token.token,
				token.className,
				(int)token.vParams.size(),
				0,
				luaClass.strName,
				token.location.line,
				token.location.col));
		}
	}
}

void CLplusChecker::Check_AllSpecialMethodusedIndirectToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry7>& entryParamSet)
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
			entryParamSet.insert(SOutputEntry7(
				token.token,
				token.className,
				(int)token.vParams.size(),
				0,
				luaClass.strName,
				token.location.line,
				token.location.col));
		}
	}
}

void CLplusChecker::Check_AllGlobalFieldUsedToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet)
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

void CLplusChecker::Check_AllGlobalMethodUsedToFile(FILE* pFile, const SLuaClass& luaClass, std::set<SOutputEntry5>& entrySet, std::set<SOutputEntry7>& entryParamSet)
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

void CLplusChecker::Check_GameTextUsedToFile(const SLuaClass& luaClass, std::set<SStringTableToken>& entrySet)
{
	for (const auto& entry : luaClass.stringTableUsedList)
	{
		if (m_GameTextKeySet.find(entry.text_id) == m_GameTextKeySet.end())
		{
			entrySet.insert(entry);
		}
	}
}

void CLplusChecker::Check_FieldMethodNameStandard(const SLuaClass& luaClass)
{
	if (luaClass.functionDefList.empty())		//忽略
		return;

	//对class的每个字段，检查命名规则
	const auto& fieldDefList = luaClass.fieldDefList;
	for (const auto& token : fieldDefList)
	{
		if (token.className == "Task" || token.className == "GcCallbacks")
			continue;

		if (token.typeName != "FUNCTION")
		{
			if (token.token.length() < 2)
				m_errorNameFieldMap[token.className].insert(token);
			else if (token.token[0] != '_' || (isalpha(token.token[1]) && !isupper(token.token[1])))
				m_errorNameFieldMap[token.className].insert(token);
		}
	}

	const auto& funcDefList = luaClass.functionDefList;
	for (const auto& token : funcDefList)
	{
		if (token.token == "new" || token.className == "Task" || token.className == "GcCallbacks")
			continue;

		if (token.token.length() < 1)
			m_errorNameFunctionMap[token.className].insert(token);
		else if (!isalpha(token.token[0]) || !isupper(token.token[0]))
			m_errorNameFunctionMap[token.className].insert(token);
	}
}

void CLplusChecker::Check_UserDataFieldCleanUp(const SLuaClass& luaClass)
{
	std::set<SLuaFieldToken> userDataSet;
	for (const auto& entry : luaClass.fieldDefList)
	{
		if (entry.typeName != "userdata")
			continue;

		userDataSet.insert(entry);
	}

	if (userDataSet.empty())
		return;

	AFile File;
	if (!File.Open("", luaClass.strFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
	{
		printf("Failed to open %s\n", luaClass.strFileName.c_str());
		return;
	}

	for (const auto& entry : userDataSet)
	{
		std::string strSetNil;
		std_string_format(strSetNil, "self.%s = nil", entry.token);

		bool bContains = false;
		File.Seek(0, AFILE_SEEK_SET);
		auint32 dwReadLen;
		char szLine[AFILE_LINEMAXLEN];
		int nLine = 0;
		bool bComment = false;
		while (File.ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
		{
			++nLine;

			//comment
			if (strstr(szLine, "--[[") != NULL)
			{
				bComment = true;
			}

			if (strstr(szLine, "]]") != NULL)
			{
				bComment = false;
			}

			if (bComment)
				continue;

			char* pComment = strstr(szLine, "--");
			if (pComment)
				*pComment = '\0';

			if (strstr(szLine, strSetNil.c_str()) != NULL)
			{
				bContains = true;
				break;
			}
		}

		if (!bContains)
		{
			m_errorUserDataFieldList.push_back(entry);
		}
	}
}

void CLplusChecker::Check_TimerCleanup(const SLuaClass& luaClass)
{
	std::set<SLuaFieldToken> userDataSet;
	for (const auto& entry : luaClass.timerAddList)
	{
		if (entry.id == "")
		{
			m_errorTimerList.push_back(entry);
		}
		else
		{
			bool bFind = false;
			for (const auto& tm : luaClass.timerRemoveList)
			{
				if (tm.id == entry.id)
				{
					bFind = true;
					break;
				}

				size_t offset = entry.id.find("self.");
				if (offset != std::string::npos)
				{
					std::string str = entry.id;
					str.replace(offset, strlen("self."), "instance.");
					if (tm.id == str)
					{
						bFind = true;
						break;
					}
				}
			}

			if (!bFind)
				m_errorTimerList.push_back(entry);
		}
	}
}