#include "CLuaRulesChecker.h"
#include "function.h"
#include <algorithm>
#include "stringext.h"

CLuaRulesChecker::CLuaRulesChecker(const std::string& strLuaDir)
{
	m_strLuaDir = strLuaDir;
}

bool CLuaRulesChecker::BuildLuaClasses()
{
	m_mapLuaClass.clear();

	Q_iterateFiles(m_strLuaDir.c_str(),
		[this](const char* filename)
	{
		if (stricmp(filename, "Lplus.lua") == 0 ||
			stricmp(filename, "Enum.lua") == 0 ||
			stricmp(filename, "PBHelper.lua") == 0 ||
			stricmp(filename, "Test.lua") == 0)
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

		BuildLuaClass(&File, m_mapLuaClass);

		File.Close();
	},
		m_strLuaDir.c_str());

	return true;
}

bool CLuaRulesChecker::GetLuaClassUsedMembers()
{
	Q_iterateFiles(m_strLuaDir.c_str(),
		[this](const char* filename)
	{
		if (stricmp(filename, "Lplus.lua") == 0 ||
			stricmp(filename, "Enum.lua") == 0 ||
			stricmp(filename, "PBHelper.lua") == 0 ||
			stricmp(filename, "Test.lua") == 0)
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

		GetLuaClassUsedMembers(&File, m_mapLuaClass);

		File.Close();
	},
		m_strLuaDir.c_str());

	return true;
}

bool CLuaRulesChecker::GetLuaClassUsedMembers(AFile* pFile, const std::map<std::string, SLuaClass>& luaClass)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;

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
			HandleLine_ClassDefine(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "Lplus.Extend(") != NULL)			//类继承
		{
			HandleLine_ClassExtend(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "def.field(") != NULL)		//字段定义
		{
			HandleLine_FieldDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.method(") != NULL)		//方法定义
		{
			HandleLine_MethodDefine(szLine, nLine, current);
		}
		
	}

	return true;
}

bool CLuaRulesChecker::CheckLuaClassesToFile(const char* strFileName)
{
	FILE* pFile = fopen(strFileName, "wt");
	if (!pFile)
		return false;

	fprintf(pFile, "错误检查: Event是否有对应的Remove检查 (CGame.EventManager:addHandler, CGame.EventManager:removeHandler):\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		bool isUIClass = luaClass.parent != NULL && luaClass.parent->strName == "CPanelBase";
		Check_EventCleanup(luaClass, false);
	}

	for (const auto& entry : m_errorEventList)
	{
		fprintf(pFile,
			"\t没有对应的Remove的Event, Name: %s, \t类 %s, 行 %d, 列 %d, \n",
			entry.eventName.c_str(),
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "错误检查: Timer是否有对应的Remove检查 (_G.AddGlobalTimer, _G.RemoveGlobalTimer):\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		bool isUIClass = luaClass.parent != NULL && luaClass.parent->strName == "CPanelBase";
		Check_TimerCleanup(luaClass, false);
	}

	for (const auto& entry : m_errorTimerList)
	{
		fprintf(pFile,
			"\t没有对应的Remove的Timer, ID: %s, \t秒: %s, \t一次: %s, \t类 %s, 行 %d, 列 %d, \n",
			entry.id.c_str(),
			entry.ttl.c_str(),
			entry.runonce.c_str(),
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}

	fprintf(pFile, "\n");

	//fprintf(pFile, "错误检查: UserData字段是否设置为空检查 (self.XXX = nil):\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		if (!ContainsTimer(luaClass) && !ContainsDotweenWithCallback(luaClass))
			continue;

		bool isUIClass = luaClass.parent != NULL && luaClass.parent->strName == "CPanelBase";
		Check_UserDataFieldCleanUp(luaClass, false);
	}

	int nFieldCount = 0;
	for (const auto& entry : m_errorUserDataFieldMap)
	{
		nFieldCount += (int)entry.second.size();
	}

	fprintf(pFile, "错误检查: UserData字段是否设置为空检查 (self.XXX = nil): 类个数: %d， 字段个数: %d\n", (int)m_errorUserDataFieldMap.size(), nFieldCount);

	for (const auto& entry : m_errorUserDataFieldMap)
	{
		auto className = entry.first;
		const auto& tokenList = entry.second;

		fprintf(pFile, "\t类 %s\n", className.c_str());
		for (const auto& token : tokenList)
		{
			/*
			fprintf(pFile,
				"\t\t没有设置为nil的userdata字段 %s, 行 %d, 列 %d\n",
				token.token,
				token.location.line,
				token.location.col);
				*/
			fprintf(pFile, "\t\tself.%s = nil\n", token.token.c_str());
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "使用统计: Event\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		if (!luaClass.eventAddList.empty())
		{
			fprintf(pFile,
				"\tEvent统计: 类 %s, \t个数: %d\n", entry.first.c_str(), (int)luaClass.eventAddList.size());
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "使用统计: Timer\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		int nOnceCount = 0;
		int nAlwaysCount = 0;
		int nUnknownCount = 0;
		for (const auto& tm : luaClass.timerAddList)
		{
			if (tm.runonce == "true")
				++nOnceCount;
			else if (tm.runonce == "false")
				++nAlwaysCount;
			else
				++nUnknownCount;
		}

		if (nOnceCount > 0 || nAlwaysCount > 0 || nUnknownCount > 0)
		{
			if (nUnknownCount == 0)
			{
				fprintf(pFile,
					"\tTimer统计: 类 %s, \t一次： %d, \t多次： %d\n",
					entry.first.c_str(),
					nOnceCount,
					nAlwaysCount);
			}
			else
			{
				fprintf(pFile,
					"\tTimer统计: 类 %s, \t一次： %d, \t多次： %d, 未知: %d\n",
					entry.first.c_str(),
					nOnceCount,
					nAlwaysCount,
					nUnknownCount);
			}
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "使用统计: DoTween\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		
		int nDoMove = 0;
		int nDoMove_callbak = 0;
		int nDoLocalMove = 0;
		int nDoLocalMove_callbak = 0;
		int nDoLocalRotateQuaternion = 0;
		int nDoLocalRotateQuaternion_callbak = 0;
		int nDoAlpha = 0;
		int nDoAlpha_callbak = 0;
		int nDoScale = 0;
		int nDoScale_callbak = 0;
		for (const auto& tm : luaClass.dotweenList)
		{
			if (tm.dotweenName == "GUITools.DoMove")
			{
				++nDoMove;
				if (tm.hasCallback)
					++nDoMove_callbak;
			}
			else if (tm.dotweenName == "GUITools.DoLocalMove")
			{
				++nDoLocalMove;
				if (tm.hasCallback)
					++nDoLocalMove_callbak;
			}
			else if (tm.dotweenName == "GUITools.DoLocalRotateQuaternion")
			{
				++nDoLocalRotateQuaternion;
				if (tm.hasCallback)
					++nDoLocalRotateQuaternion_callbak;
			}
			else if (tm.dotweenName == "GUITools.DoAlpha")
			{
				++nDoAlpha;
				if (tm.hasCallback)
					++nDoAlpha_callbak;
			}
			else if (tm.dotweenName == "GUITools.DoScale")
			{
				++nDoScale;
				if (tm.hasCallback)
					++nDoScale_callbak;
			}
		}

		if (nDoMove > 0 || nDoLocalMove > 0 || nDoLocalRotateQuaternion > 0 ||
			nDoAlpha > 0 || nDoScale > 0)
		{
			AString strMsg;
			AString strTemp;
			strMsg.Format("\tDotween统计: 类 %s, ", entry.first.c_str());
			
			if (nDoMove > 0)
			{
				strTemp.Format("\tDoMove 个数：%d, 有回调: %d,", nDoMove, nDoMove_callbak);
				strMsg += strTemp;
			}

			if (nDoLocalMove > 0)
			{
				strTemp.Format("\tDoLocalMove 个数：%d, 有回调: %d,", nDoLocalMove, nDoLocalMove_callbak);
				strMsg += strTemp;
			}

			if (nDoLocalRotateQuaternion > 0)
			{
				strTemp.Format("\tDoLocalRotateQuaternion 个数：%d, 有回调: %d,", nDoLocalRotateQuaternion, nDoLocalRotateQuaternion_callbak);
				strMsg += strTemp;
			}

			if (nDoAlpha > 0)
			{
				strTemp.Format("\tDoAlpha 个数：%d, 有回调: %d,", nDoAlpha, nDoAlpha_callbak);
				strMsg += strTemp;
			}

			if (nDoScale > 0)
			{
				strTemp.Format("\tDoScale 个数：%d, 有回调: %d,", nDoScale, nDoScale_callbak);
				strMsg += strTemp;
			}

			strMsg += "\n";
			fprintf(pFile, strMsg);
		}
	}

	fprintf(pFile, "\n");

	fclose(pFile);
	return true;
}

void CLuaRulesChecker::HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

void CLuaRulesChecker::HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

std::string CLuaRulesChecker::HandleLine_FieldDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
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

			current->fieldDefList.insert(fieldToken);

			ret = name;
		}
	}
	return ret;
}

std::string CLuaRulesChecker::HandleLine_MethodDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;

		const char* p = strstr(szLine, "def.method(");
		p += strlen("def.method(");

		const char* pStart = p - 1;

		p = strstr(p, ")");
		ASSERT(p);

		ParseFunctionToken(pStart, p, vParams, vRets);				//解析参数，返回值

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

std::string CLuaRulesChecker::HandleLine_VirtualDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;

		const char* p = strstr(szLine, "def.virtual(");
		p += strlen("def.virtual(");

		const char* pStart = p - 1;

		p = strstr(p, ")");
		ASSERT(p);

		ParseFunctionToken(pStart, p, vParams, vRets);				//解析参数，返回值

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
			usedToken.bIsVirtual = true;

			current->functionVirtualDefList.insert(usedToken);
			current->functionDefList.insert(usedToken);
			//current->fieldDefList.insert(name);

			ret = name;
		}
	}

	return ret;
}

std::string CLuaRulesChecker::HandleLine_OverrideDefine(const char* szLine, int nLine, SLuaClass* current)
{
	std::string ret;

	if (current)
	{
		std::vector<std::string> vParams;
		std::vector<std::string> vRets;

		const char* p = strstr(szLine, "def.override(");
		p += strlen("def.override(");

		const char* pStart = p - 1;

		p = strstr(p, ")");

		ParseFunctionToken(pStart, p, vParams, vRets);				//解析参数，返回值

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
			usedToken.vRets = vRets;
			usedToken.bIsOverride = true;

			current->functionOverrideDefList.insert(usedToken);

			current->functionDefList.insert(usedToken);
			//current->fieldDefList.insert(name);

			ret = name;
		}
	}

	return ret;
}

void CLuaRulesChecker::HandleLine_AddEventDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "CGame.EventManager:addHandler");
		ASSERT(p);

		SLuaEventToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		p += strlen("CGame.EventManager:addHandler");
		ASSERT(p);

		p = strstr(p, "(");
		ASSERT(p);
		p += 1;

		const char* tmp = strstr(p, "Events.");
		if (tmp)
			p = tmp += strlen("Events.");

		const char* end = strstr(p, ",");
		ASSERT(end);

		char name[1024];
		strncpy(name, p, end - p);
		name[end - p] = '\0';

		std::string eventName = name;
		trim(eventName, " \t'\"");

		usedToken.eventName = eventName;

		current->eventAddList.insert(usedToken);
	}
}

void CLuaRulesChecker::HandleLine_RemoveEventDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "CGame.EventManager:removeHandler");
		ASSERT(p);

		SLuaEventToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		p += strlen("CGame.EventManager:removeHandler");
		ASSERT(p);

		p = strstr(p, "(");
		ASSERT(p);
		p += 1;

		const char* tmp = strstr(p, "Events.");
		if (tmp)
			p = tmp += strlen("Events.");

		const char* end = strstr(p, ",");
		ASSERT(end);

		char name[1024];
		strncpy(name, p, end - p);
		name[end - p] = '\0';

		std::string eventName = name;
		trim(eventName, " \t'\"");

		usedToken.eventName = eventName;

		current->eventRemoveList.insert(usedToken);
	}
}

void CLuaRulesChecker::HandleLine_AddGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current)
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

void CLuaRulesChecker::HandleLine_RemoveGlobalTimerDefine(const char* szLine, int nLine, SLuaClass* current)
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

void CLuaRulesChecker::HandleLine_DotweenDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		if (strstr(szLine, "GUITools.DoMove") != NULL)
		{
			bool hasCallback = true;

			const char* p = strstr(szLine, "GUITools.DoMove");
			ASSERT(p);

			p += strlen("GUITools.DoMove");
			ASSERT(p);

			p = strstr(p, "(");
			ASSERT(p);
			p += 1;

			for (int i = 0; i < 4; ++i)
			{
				p = strstr(p, ",");
				ASSERT(p);
				p += 1;
			}

			while (*p == ' ' || *p == '\t') ++p;

			if (strlen(p) >= 3 && strncmp(p, "nil", 3) == 0)
				hasCallback = false;

			SLuaDotweenToken usedToken;
			usedToken.className = current->strName;
			usedToken.location.line = nLine;
			usedToken.location.col = p - szLine;
			usedToken.dotweenName = "GUITools.DoMove";
			usedToken.hasCallback = hasCallback;

			current->dotweenList.insert(usedToken);
		}

		if (strstr(szLine, "GUITools.DoLocalMove") != NULL)
		{
			bool hasCallback = true;

			const char* p = strstr(szLine, "GUITools.DoLocalMove");
			ASSERT(p);

			p += strlen("GUITools.DoLocalMove");
			ASSERT(p);

			p = strstr(p, "(");
			ASSERT(p);
			p += 1;

			for (int i = 0; i < 4; ++i)
			{
				p = strstr(p, ",");
				ASSERT(p);
				p += 1;
			}

			while (*p == ' ' || *p == '\t') ++p;

			if (strlen(p) >= 3 && strncmp(p, "nil", 3) == 0)
				hasCallback = false;

			SLuaDotweenToken usedToken;
			usedToken.className = current->strName;
			usedToken.location.line = nLine;
			usedToken.location.col = p - szLine;
			usedToken.dotweenName = "GUITools.DoLocalMove";
			usedToken.hasCallback = hasCallback;

			current->dotweenList.insert(usedToken);
		}

		if (strstr(szLine, "GUITools.DoLocalRotateQuaternion") != NULL)
		{
			bool hasCallback = true;

			const char* p = strstr(szLine, "GUITools.DoLocalRotateQuaternion");
			ASSERT(p);

			p += strlen("GUITools.DoLocalRotateQuaternion");
			ASSERT(p);

			p = strstr(p, "(");
			ASSERT(p);
			p += 1;

			for (int i = 0; i < 4; ++i)
			{
				p = strstr(p, ",");
				ASSERT(p);
				p += 1;
			}

			while (*p == ' ' || *p == '\t') ++p;

			if (strlen(p) >= 3 && strncmp(p, "nil", 3) == 0)
				hasCallback = false;

			SLuaDotweenToken usedToken;
			usedToken.className = current->strName;
			usedToken.location.line = nLine;
			usedToken.location.col = p - szLine;
			usedToken.dotweenName = "GUITools.DoLocalRotateQuaternion";
			usedToken.hasCallback = hasCallback;

			current->dotweenList.insert(usedToken);
		}

		if (strstr(szLine, "GUITools.DoAlpha") != NULL)
		{
			bool hasCallback = true;

			const char* p = strstr(szLine, "GUITools.DoAlpha");
			ASSERT(p);

			p += strlen("GUITools.DoAlpha");
			ASSERT(p);

			p = strstr(p, "(");
			ASSERT(p);
			p += 1;

			for (int i = 0; i < 3; ++i)
			{
				p = strstr(p, ",");
				ASSERT(p);
				p += 1;
			}

			while (*p == ' ' || *p == '\t') ++p;

			if (strlen(p) >= 3 && strncmp(p, "nil", 3) == 0)
				hasCallback = false;

			SLuaDotweenToken usedToken;
			usedToken.className = current->strName;
			usedToken.location.line = nLine;
			usedToken.location.col = p - szLine;
			usedToken.dotweenName = "GUITools.DoAlpha";
			usedToken.hasCallback = hasCallback;

			current->dotweenList.insert(usedToken);
		}

		if (strstr(szLine, "GUITools.DoScale") != NULL)
		{
			bool hasCallback = true;

			const char* p = strstr(szLine, "GUITools.DoScale");
			ASSERT(p);

			p += strlen("GUITools.DoScale");
			ASSERT(p);

			p = strstr(p, "(");
			ASSERT(p);
			p += 1;

			for (int i = 0; i < 3; ++i)
			{
				p = strstr(p, ",");
				ASSERT(p);
				p += 1;
			}

			while (*p == ' ' || *p == '\t') ++p;

			if (strlen(p) >= 3 && strncmp(p, "nil", 3) == 0)
				hasCallback = false;

			SLuaDotweenToken usedToken;
			usedToken.className = current->strName;
			usedToken.location.line = nLine;
			usedToken.location.col = p - szLine;
			usedToken.dotweenName = "GUITools.DoScale";
			usedToken.hasCallback = hasCallback;

			current->dotweenList.insert(usedToken);
		}
	}
}

void CLuaRulesChecker::HandleLine_StringFormatDefine(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		const char* p = strstr(szLine, "string.format");
		ASSERT(p);

		SLuaStringFormatToken usedToken;
		usedToken.className = current->strName;
		usedToken.location.line = nLine;
		usedToken.location.col = p - szLine;

		p += strlen("CGame.EventManager:removeHandler");
		ASSERT(p);

		p = strstr(p, "(");
		ASSERT(p);
		p += 1;

		const char* end = strstr(p, ",");
		ASSERT(end);

		char name[1024];
		strncpy(name, p, end - p);
		name[end - p] = '\0';

		std::string formatName = name;
		trim(formatName, " \t'\"");

		usedToken.format = formatName;

		current->stringFormatList.insert(usedToken);
	}
}

bool CLuaRulesChecker::ParseFunctionToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const
{
	if (*begin == ' ') ++begin;

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

void CLuaRulesChecker::Check_UserDataFieldCleanUp(const SLuaClass& luaClass, bool isUIClass)
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

	bool bFind = luaClass.functionDefList.end() != std::find_if(luaClass.functionDefList.begin(), luaClass.functionDefList.end(), 
		[](const SLuaFunctionToken& token) {
			return token.token == "OnDestroy" || token.token == "OnHide";
		});
	if (isUIClass && !bFind)
	{
		for (const auto& entry : userDataSet)
		{
			auto& list = m_errorUserDataFieldMap[entry.className];
			list.push_back(entry);
		}
		return;
	}

	AFile File;
	if (!File.Open("", luaClass.strFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
	{
		printf("Failed to open %s\n", luaClass.strFileName.c_str());
		return;
	}

	for (const auto& entry : userDataSet)
	{
		AString strSetNil;
		strSetNil.Format("self.%s = nil", entry.token.c_str());

		bool bContains = false;
		File.Seek(0, AFILE_SEEK_SET);
		auint32 dwReadLen;
		char szLine[AFILE_LINEMAXLEN];
		int nLine = 0;
		bool bComment = false;
		bool bInOnDestroy = false;
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

			if (strstr(szLine, ".OnDestroy") != NULL || strstr(szLine, ".OnHide") != NULL)
				bInOnDestroy = true;

			if (bInOnDestroy && strncmp(szLine, "end", 3) == 0)
				bInOnDestroy = false;

			if (!isUIClass || bInOnDestroy)
			{
				if (strstr(szLine, strSetNil) != NULL)
				{
					bContains = true;
					break;
				}
			}
		}

		if (!bContains)
		{
			auto& list = m_errorUserDataFieldMap[entry.className];
			list.push_back(entry);
		}
	}
}

void CLuaRulesChecker::Check_TimerCleanup(const SLuaClass& luaClass, bool isUIClass)
{
	if (luaClass.timerAddList.empty())
		return;

	bool bFind = luaClass.functionDefList.end() != std::find_if(luaClass.functionDefList.begin(), luaClass.functionDefList.end(),
		[](const SLuaFunctionToken& token) {
		return token.token == "OnDestroy" || token.token == "OnHide";
	});
	if (isUIClass && !bFind)			//UI必须有OnDestroy
	{
		for (const auto& entry : luaClass.timerAddList)
		{
			m_errorTimerList.push_back(entry);
		}
		return;
	}

	if (isUIClass)
	{
		AFile File;
		if (!File.Open("", luaClass.strFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
		{
			printf("Failed to open %s\n", luaClass.strFileName.c_str());
			return;
		}

		for (const auto& entry : luaClass.timerAddList)
		{
			bool bContains = false;
			File.Seek(0, AFILE_SEEK_SET);
			auint32 dwReadLen;
			char szLine[AFILE_LINEMAXLEN];
			int nLine = 0;
			bool bComment = false;
			bool bInOnDestroy = false;
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

				if (strstr(szLine, ".OnDestroy") != NULL || strstr(szLine, ".OnHide") != NULL)
					bInOnDestroy = true;

				if (bInOnDestroy && strncmp(szLine, "end", 3) == 0)
					bInOnDestroy = false;

				if (bInOnDestroy)
				{
					if (strstr(szLine, "_G.RemoveGlobalTimer") != NULL && strstr(szLine, entry.id.c_str()) != NULL)
					{
						bContains = true;
						break;
					}

					if ((strstr(szLine, "Remove") != NULL) && strstr(szLine, entry.id.c_str()) != NULL)
					{
						bContains = true;
						break;
					}
				}
			}

			if (!bContains)
			{
				m_errorTimerList.push_back(entry);
			}
		}
	}
	else
	{
		for (const auto& entry : luaClass.timerAddList)
		{
			if (entry.id.empty())
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

					if (entry.id.find("self.") >= 0)
					{
						AString str = entry.id.c_str();
						str.Replace("self.", "instance.");
						if (tm.id == (const char*)str)
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
}

void CLuaRulesChecker::Check_EventCleanup(const SLuaClass& luaClass, bool isUIClass)
{
	if (luaClass.eventAddList.empty())
		return;

	bool bFind = luaClass.functionDefList.end() != std::find_if(luaClass.functionDefList.begin(), luaClass.functionDefList.end(),
		[](const SLuaFunctionToken& token) {
		return token.token == "OnDestroy" || token.token == "OnHide";
	});
	if (isUIClass && !bFind)			//UI必须有OnDestroy
	{
		for (const auto& entry : luaClass.eventAddList)
		{
			m_errorEventList.push_back(entry);
		}
		return;
	}

	if (isUIClass)
	{
		AFile File;
		if (!File.Open("", luaClass.strFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
		{
			printf("Failed to open %s\n", luaClass.strFileName.c_str());
			return;
		}

		for (const auto& entry : luaClass.eventAddList)
		{
			bool bContains = false;
			File.Seek(0, AFILE_SEEK_SET);
			auint32 dwReadLen;
			char szLine[AFILE_LINEMAXLEN];
			int nLine = 0;
			bool bComment = false;
			bool bInOnDestroy = false;
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

				if (strstr(szLine, ".OnDestroy") != NULL || strstr(szLine, ".OnHide") != NULL)
					bInOnDestroy = true;

				if (bInOnDestroy && strncmp(szLine, "end", 3) == 0)
					bInOnDestroy = false;

				if (bInOnDestroy)
				{
					if (strstr(szLine, "CGame.EventManager:removeHandler") != NULL && strstr(szLine, entry.eventName.c_str()) != NULL)
					{
						bContains = true;
						break;
					}

					if ((strstr(szLine, "Unlisten") != NULL || strstr(szLine, "UnListen") != NULL) && strstr(szLine, entry.eventName.c_str()) != NULL)
					{
						bContains = true;
						break;
					}
				}
			}

			if (!bContains)
			{
				m_errorEventList.push_back(entry);
			}
		}
	}
	else
	{ 
		for (const auto& entry : luaClass.eventAddList)
		{
			bool bFind = luaClass.eventRemoveList.end() != std::find_if(luaClass.eventRemoveList.begin(), luaClass.eventRemoveList.end(),
				[&entry](const SLuaEventToken& token) {
				return token.eventName == entry.eventName;
			});
			
			if (!bFind)
				m_errorEventList.push_back(entry);
		}
	}
}

bool CLuaRulesChecker::ContainsTimer(const SLuaClass& luaClass) const
{
	return !luaClass.timerAddList.empty();
}

bool CLuaRulesChecker::ContainsDotweenWithCallback(const SLuaClass& luaClass) const
{
	for (const auto& token : luaClass.dotweenList)
	{
		if (token.hasCallback)
			return true;
	}
	return false;
}

void CLuaRulesChecker::PrintLuaClasses()
{
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		printf("%s\n",
			luaClass.strName.c_str());
	}
}

const SLuaClass* CLuaRulesChecker::GetLuaClass(const char* szName) const
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLuaRulesChecker::GetLuaClass(const char* szName)
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLuaRulesChecker::AddLuaClass(const char* szName)
{
	m_mapLuaClass[szName] = SLuaClass();
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;
	else
		return NULL;
}

bool CLuaRulesChecker::BuildLuaClass(AFile* pFile, std::map<std::string, SLuaClass>& luaClass)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;

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
			HandleLine_ClassDefine(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "Lplus.Extend(") != NULL)			//类继承
		{
			HandleLine_ClassExtend(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "def.field(") != NULL)		//字段定义
		{
			HandleLine_FieldDefine(szLine, nLine, current);
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
		else if (strstr(szLine, "CGame.EventManager:addHandler") != NULL)
		{
			HandleLine_AddEventDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "CGame.EventManager:removeHandler") != NULL)
		{
			HandleLine_RemoveEventDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "_G.AddGlobalTimer") != NULL)
		{
			HandleLine_AddGlobalTimerDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "_G.RemoveGlobalTimer") != NULL)
		{
			HandleLine_RemoveGlobalTimerDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "GUITools.DoMove") != NULL ||
			strstr(szLine, "GUITools.DoLocalMove") != NULL ||
			strstr(szLine, "GUITools.DoLocalRotateQuaternion") != NULL ||
			strstr(szLine, "GUITools.DoAlpha") != NULL ||
			strstr(szLine, "GUITools.DoScale") != NULL)
		{
			HandleLine_DotweenDefine(szLine, nLine, current);
		}

		if (current)			//class结束
		{
			std::string str = current->strName + ".Commit()";
			if (strstr(szLine, str.c_str()) != NULL)
				current = NULL;
		}

	}
	return true;
}
