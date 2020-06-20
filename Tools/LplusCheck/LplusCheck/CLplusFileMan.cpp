#include "CLplusFileMan.h"
#include "function.h"
#include "stringext.h"
#include "AFile.h"

CLplusFileMan::CLplusFileMan(const std::string& strLuaDir)
	: m_strLuaDir(strLuaDir)
{

}

void CLplusFileMan::Collect()
{
	m_mapLuaFile.clear();

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

		BuildLplusFile(&File, filename);

		File.Close();
	},
		m_strLuaDir.c_str());
}

void CLplusFileMan::BuildLplusFile(AFile* pFile, const char* fileName)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	//添加 SLuaFile
	SLuaFile* luaFile = GetLuaFile(fileName);
	if (!luaFile)
	{
		luaFile = AddLuaFile(fileName);
		luaFile->strName = fileName;
	}

	auint32 dwReadLen;
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

		if (strstr(szLine, "StringTable.Get(") != NULL)
		{
			HandleLine_StringTableUse(szLine, nLine, luaFile);
		}

		//收集所有间接方法使用
		Get_AllMethodUsedIndirect(szLine, nLine, luaFile);

		//收集所有特殊方法使用
		Get_AllSpecialMethodUsedIndirect(szLine, nLine, luaFile);

		//收集全局字段使用
		Get_GlobalFieldUsed(szLine, nLine, luaFile);

		//收集全局方法使用
		Get_GlobalMethodUsed(szLine, nLine, luaFile);
	}
}

void CLplusFileMan::HandleLine_StringTableUse(const char* szLine, int nLine, SLuaFile* luaFile)
{
	if (!luaFile)
		return;

	const char* p = strstr(szLine, "StringTable.Get(");
	ASSERT(p);

	SStringTableToken usedToken;
	usedToken.classOrFileName = "<FILE>";
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
			luaFile->stringTableUsedList.insert(usedToken);
		}
	}
}

void CLplusFileMan::Get_AllMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile)
{
	if (!luaFile || strstr(szLine, ":") == NULL)
		return;

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
			SLuaFunctionToken usedToken(false, false, false, false);
			usedToken.location.line = nLine;
			usedToken.location.col = start - szLine;
			usedToken.token = fieldname;
			usedToken.className = "Unknown";
			usedToken.vParams = vParams;
			usedToken.bHasFunction = bFunction;

			luaFile->functionAllUsedIndirectList.insert(usedToken);
		}

		end = strstr(end + 1, ":");
	}
}

void CLplusFileMan::Get_AllSpecialMethodUsedIndirect(const char* szLine, int nLine, SLuaFile* luaFile)
{
	if (!luaFile)
		return;

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
			SLuaFunctionToken usedToken(false, false, false, false);
			usedToken.location.line = nLine;
			usedToken.location.col = end - szLine;
			usedToken.token = specialToken;
			usedToken.className = "C#";
			usedToken.vParams = vParams;
			usedToken.bHasFunction = bFunction;

			luaFile->functionSpecialUsedIndirect.insert(usedToken);
		}
	}
}

void CLplusFileMan::Get_GlobalFieldUsed(const char* szLine, int nLine, SLuaFile* luaFile)
{
	if (!luaFile)
		return;

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

	SLuaFieldToken usedToken(false);
	usedToken.location.line = nLine;
	usedToken.location.col = start - szLine;
	usedToken.token = name;
	usedToken.className = typeName;
	usedToken.typeName = "table";

	luaFile->fieldUsedGlobalList.insert(usedToken);
}

void CLplusFileMan::Get_GlobalMethodUsed(const char* szLine, int nLine, SLuaFile* luaFile)
{
	if (!luaFile)
		return;

	std::string specialToken;
	std::string typeName;
	for (const auto& entry : m_GlobalClassList)
	{
		std::string str = std::get<0>(entry) + ":";
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

		SLuaFunctionToken usedToken(false, false, false, false);
		usedToken.location.line = nLine;
		usedToken.location.col = end - szLine;
		usedToken.token = name;
		usedToken.className = typeName;
		usedToken.vParams = vParams;
		usedToken.bHasFunction = bFunction;

		luaFile->functionUsedGlobalList.insert(usedToken);
	}
}

bool CLplusFileMan::ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const
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

SLuaFile* CLplusFileMan::GetLuaFile(const char* szName)
{
	auto itr = m_mapLuaFile.find(szName);
	if (itr != m_mapLuaFile.end())
		return &itr->second;

	return nullptr;
}

SLuaFile* CLplusFileMan::AddLuaFile(const char* szName)
{
	m_mapLuaFile[szName] = SLuaFile();
	auto itr = m_mapLuaFile.find(szName);
	if (itr != m_mapLuaFile.end())
		return &itr->second;
	else
		return nullptr;
}
