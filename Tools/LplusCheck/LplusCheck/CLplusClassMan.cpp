#include "CLplusClassMan.h"
#include "function.h"
#include "stringext.h"
#include "AFile.h"

CLplusClassMan::CLplusClassMan(const std::string& strLuaDir)
	: m_strLuaDir(strLuaDir)
{

}

void CLplusClassMan::Collect()
{
	m_mapLuaClass.clear();

	Q_iterateFiles(m_strLuaDir.c_str(),
		[this](const char* filename)
	{
		if (stricmp(filename, "Lplus.lua") == 0 ||
			stricmp(filename, "Enum.lua") == 0 ||
			stricmp(filename, "PBHelper.lua") == 0 ||
			stricmp(filename, "Test.lua") == 0 ||
			strstr(filename, "Utility/") != NULL ||
			strstr(filename, "UnityClass/") != NULL ||
			strstr(filename, "test/") != NULL ||
			strstr(filename, "protobuf/") != NULL)
			return;

		if (!hasFileExtensionA(filename, "lua"))
			return;

		//printf("%s\n", filename);

		std::string strFile = this->m_strLuaDir;
		normalizeDirName(strFile);
		strFile += filename;

		AFile File;
		if (!File.Open("", strFile.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
		{
			printf("Failed to open %s\n", strFile.c_str());
			return;
		}

		BuildLplusClass(&File, filename);

		File.Close();
	},
		m_strLuaDir.c_str());
}

void CLplusClassMan::BuildLplusClass(AFile* pFile, const char* fileName)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;

	char shortFileName[256];
	getFileNameA(fileName, shortFileName, 256);

	SLuaClass* current = NULL;
	char szLine[AFILE_LINEMAXLEN];
	int nLine = 0;
	bool bComment = false;
	while (pFile->ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
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

		if (strstr(szLine, "Lplus.Class(") != NULL)				//类定义
		{
			HandleLine_ClassDefine(fileName, szLine, nLine, current);
		}
		else if (strstr(szLine, "Lplus.Extend(") != NULL)			//类继承
		{
			HandleLine_ClassExtend(fileName, szLine, nLine, current);
		}
		
		if (strstr(szLine, "def.field(") != NULL)		//字段定义
		{
			HandleLine_FieldDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.const(") != NULL)		//类字段定义
		{
			HandleLine_ConstDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.method(") != NULL)		//方法定义
		{
			HandleLine_MethodDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.virtual(") != NULL)		//虚方法定义
		{
			HandleLine_VirtualDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.override(") != NULL)		//重载方法定义
		{
			HandleLine_OverrideDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.final(") != NULL)		//最终重载方法定义
		{
			HandleLine_FinalDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.static(") != NULL)
		{
			HandleLine_StaticDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.") != NULL)
		{
			HandleLine_ErrorDefine(szLine, nLine, current);
		}

		if (current && strstr(szLine, std::string(current->strName + ".Commit()").c_str()) != NULL)			//class结束
		{
			current = NULL;
		}
	}
}

void CLplusClassMan::HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

void CLplusClassMan::HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

void CLplusClassMan::HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

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

		SLuaFieldToken fieldToken(false);
		fieldToken.location.line = nLine;
		fieldToken.location.col = start - szLine;
		fieldToken.token = name;
		fieldToken.className = current->strName;
		fieldToken.typeName = typeName;

		current->fieldDefList.insert(fieldToken);
	}
}

void CLplusClassMan::HandleLine_ConstDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

	const char* pTypeStart;
	const char* pTypeEnd;
	char typeName[128] = { 0 };

	const char* p = strstr(szLine, "def.const(");
	p += strlen("def.const(");

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

		SLuaFieldToken fieldToken(true);
		fieldToken.location.line = nLine;
		fieldToken.location.col = start - szLine;
		fieldToken.token = name;
		fieldToken.className = current->strName;
		fieldToken.typeName = typeName;

		current->fieldDefList.insert(fieldToken);
	}
}

void CLplusClassMan::HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

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

		SLuaFunctionToken usedToken(false, false, false, false);
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = current->strName;
		usedToken.vParams = vParams;
		usedToken.vRets = vRets;
		usedToken.vActParams = vActParams;
		current->functionDefList.insert(usedToken);
	}
}

void CLplusClassMan::HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

	
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

		SLuaFunctionToken usedToken(true, false, false, false);
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = current->strName;
		usedToken.vParams = vParams;
		usedToken.vRets = vRets;
		usedToken.vActParams = vActParams;

		current->functionDefList.insert(usedToken);
	}
}

void CLplusClassMan::HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

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

		SLuaFunctionToken usedToken(false, true, false, false);
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = current->strName;
		usedToken.vParams = vParams;
		usedToken.vActParams = vActParams;
		usedToken.vRets = vRets;

		current->functionDefList.insert(usedToken);
	}
}

void CLplusClassMan::HandleLine_FinalDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

	std::vector<std::string> vParams;
	std::vector<std::string> vRets;
	std::vector<std::string> vActParams;

	const char* p = strstr(szLine, "def.final(");
	p += strlen("def.final(");

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

		SLuaFunctionToken usedToken(false, false, true, false);
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = current->strName;
		usedToken.vParams = vParams;
		usedToken.vActParams = vActParams;
		usedToken.vRets = vRets;

		current->functionDefList.insert(usedToken);
	}
}

void CLplusClassMan::HandleLine_StaticDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

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

		SLuaFunctionToken usedToken(false, false, false, true);
		usedToken.location.line = nLine;
		usedToken.location.col = start - szLine;
		usedToken.token = name;
		usedToken.className = current->strName;
		usedToken.vParams = vParams;
		usedToken.vRets = vRets;
		usedToken.vActParams = vActParams;
		usedToken.bIsStatic = true;

		current->functionDefList.insert(usedToken);
	}
}

void CLplusClassMan::HandleLine_ErrorDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (!current)
		return;

	const char* p = strstr(szLine, "def.");
	p += strlen("def.");

	SLocation location;
	location.line = nLine;
	location.col = p - szLine;

	current->errorDefList.insert(location);
}

SLuaClass* CLplusClassMan::GetLuaClass(const char* szName)
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return nullptr;
}

SLuaClass* CLplusClassMan::AddLuaClass(const char* szName)
{
	m_mapLuaClass[szName] = SLuaClass();
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;
	else
		return NULL;
}

bool CLplusClassMan::ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const
{
	if (*begin == ' ' || *begin == '\t') ++begin;

	if (*begin != '(' || *end != ')')
	{
		assert(false);
		return false;
	}

	vParams.clear();
	vRets.clear();

	const char* p = begin;
	const char* pToken = NULL;
	bool bEqual = false;		//是否已经出现了 =>
	while (p <= end)
	{
		while (*p == ' ' || *p == '\t') ++p;

		if (*p == '(')
		{
			++p;
			continue;
		}

		if (!pToken)
			pToken = p;

		if (*p == ',' || *p == ')')
		{
			if (pToken)
			{
				bool bQuote = false;
				if (*pToken == '\"' || *pToken == '\'')
					bQuote = true;

				char szToken[256];
				assert(p - pToken < 256);
				strncpy(szToken, pToken, p - pToken);
				szToken[p - pToken] = '\0';

				if (p - pToken >= 1)
				{
					char name[1024];
					if (bQuote)
					{
						const char* p1 = strchr(szToken, '\"');
						if (!p1)
							p1 = strchr(szToken, '\'');

						const char* p2 = strrchr(szToken, '\"');
						if (!p2)
							p2 = strrchr(szToken, '\'');

						assert(p1 && p2);
						strncpy(name, p1 + 1, p2 - p1 - 1);
						name[p2 - p1 - 1] = '\0';
					}
					else
					{
						const char* end = p;
						while ((end > pToken) &&
							(*(end - 1) == ' ' || *(end - 1) == '\t'))
							--end;				//去除尾部的空字符

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//取类型.以后的字符串
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//添加参数和返回值定义
					if (strcmp(name, "=>") == 0)
						bEqual = true;
					else
					{
						if (bEqual)
							vRets.push_back(name);
						else
							vParams.push_back(name);
					}
				}

				pToken = NULL;
			}
		}

		++p;
	}

	if (pToken != NULL)
	{
		assert(false);
		return false;
	}

	return true;
}

bool CLplusClassMan::ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const
{
	const char* end = strrchr(begin, ')');
	if (!end)
	{
		assert(false);
		return false;
	}

	while (*begin == ' ' && begin < end) ++begin;

	if (*begin != '(')
	{
		assert(false);
		return false;
	}

	vParams.clear();

	int nParensis = 0;

	const char* p = begin;
	const char* pToken = NULL;
	bool bInBigParensis = false;
	while (p <= end)
	{
		while (*p == ' ' || *p == '\t') ++p;

		if (*p == '(')
		{
			++p;
			++nParensis;
			continue;
		}

		if (!pToken)
			pToken = p;

		if (*p == '{')
			++nParensis;
		else if (*p == '}')
			--nParensis;

		if (*p == ')')
			--nParensis;

		bool bFinish = (*p == ')' && nParensis == 0);

		if (*p == ',' || bFinish)
		{
			if (nParensis > 1)				//skip
			{
			}
			else if (pToken)
			{
				char szToken[256];
				assert(p - pToken < 256);
				strncpy(szToken, pToken, p - pToken);
				szToken[p - pToken] = '\0';

				if (p - pToken >= 1)
				{
					char name[1024];
					{
						const char* end = p;
						while ((end > pToken) &&
							(*(end - 1) == ' ' || *(end - 1) == '\t'))
							--end;				//去除尾部的空字符

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//取类型.以后的字符串
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//添加参数和返回值定义
					vParams.push_back(name);
				}

				pToken = NULL;
			}
		}

		if (bFinish)
			break;

		++p;
	}

	if (pToken != NULL)
	{
		assert(false);
		return false;
	}

	return true;
}

bool CLplusClassMan::ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const
{
	if (strstr(begin, "function"))
	{
		bHasFunction = true;
		return false;					//skip
	}

	bHasFunction = false;

	if (*begin == ' ' || *begin == '\t') ++begin;

	if (*begin != '(')
	{
		return false;
	}

	const char* end = strrchr(begin, ')');
	if (!end)
	{
		return false;
	}

	vParams.clear();

	int nParensis = 0;

	const char* p = begin;
	const char* pToken = NULL;
	bool bInBigParensis = false;
	while (p <= end)
	{
		while (*p == ' ' || *p == '\t') ++p;

		if (*p == '(')
		{
			++p;
			++nParensis;
			continue;
		}

		if (!pToken)
			pToken = p;

		if (*p == '{')
			++nParensis;
		else if (*p == '}')
			--nParensis;

		if (*p == ')')
			--nParensis;

		bool bFinish = (*p == ')' && nParensis == 0);

		if (*p == ',' || bFinish)
		{
			if (nParensis > 1)				//skip
			{
			}
			else if (pToken)
			{
				char szToken[256];
				assert(p - pToken < 256);
				strncpy(szToken, pToken, p - pToken);
				szToken[p - pToken] = '\0';

				if (p - pToken >= 1)
				{
					char name[1024];
					{
						const char* end = p;
						while ((end > pToken) &&
							(*(end - 1) == ' ' || *(end - 1) == '\t'))
							--end;				//去除尾部的空字符

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//取类型.以后的字符串
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//添加参数和返回值定义
					vParams.push_back(name);
				}

				pToken = NULL;
			}
		}

		if (bFinish)
			break;

		++p;
	}

	if (pToken != NULL)
	{
		return false;
	}

	return true;
}

bool CLplusClassMan::GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const
{
	if (strstr(begin, "return") == nullptr)
	{
		return false;					//skip
	}

	begin = strstr(begin, "return") + strlen("return");

	if (*begin == ' ' || *begin == '\t') ++begin;

	vRets.clear();

	const char* end = begin + strlen(begin);

	int nParensis = 0;
	const char* p = begin;
	const char* pToken = NULL;
	while (p <= end)
	{
		while (*p == ' ' || *p == '\t') ++p;

		if (*p == '(')
		{
			++p;
			++nParensis;
			continue;
		}

		if (!pToken)
			pToken = p;

		if (*p == '{')
			++nParensis;
		else if (*p == '}')
			--nParensis;

		if (*p == ')')
			--nParensis;

		if (*p == ',' || p == end)
		{
			if (nParensis > 0)				//skip
			{
			}
			else if (pToken)
			{
				char szToken[256];
				assert(p - pToken < 256);
				strncpy(szToken, pToken, p - pToken);
				szToken[p - pToken] = '\0';

				if (p - pToken >= 1)
				{
					char name[1024];
					const char* end = p;
					if (strstr(pToken, "\tend"))
						end = strstr(pToken, "\tend");
					if (strstr(pToken, " end"))
						end = strstr(pToken, " end");

					strncpy(name, pToken, end - pToken);
					name[end - pToken] = '\0';

					std::string ret = name;
					trim(ret, "\t ");

					//添加参数和返回值定义
					if (ret != "end")
						vRets.emplace_back(ret);
				}

				pToken = NULL;
			}
		}

		++p;
	}

	if (pToken != NULL)
	{
		return false;
	}

	return true;
}
