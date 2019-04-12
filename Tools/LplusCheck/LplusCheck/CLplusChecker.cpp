#include "CLplusChecker.h"
#include "function.h"
#include <algorithm>
#include "stringext.h"

CLplusChecker::CLplusChecker(const std::string& strConfigsDir, const std::string& strLuaDir)
{
	m_strConfigsDir = strConfigsDir;
	m_strLuaDir = strLuaDir;
	
	std::string strDir = strLuaDir;
	normalizeDirName(strDir);
	m_strNetProtoFileName = strDir + "../../Tools/ProtocolBuffers/protos/net.proto";
	m_strTemplateProtoFileName = strDir + "../../Tools/ProtocolBuffers/protos/Template.proto";

	//��ʼ������
	InitData();
}

bool CLplusChecker::BuildLuaClasses()
{
	m_dupLuaFieldList.clear();
	m_dupFunctionList.clear();
	m_errorNameFieldMap.clear();
	m_errorNameFunctionMap.clear();
	m_mapLuaClass.clear();
	m_invalidGlobalFieldList.clear();

	Q_iterateFiles(m_strLuaDir.c_str(),
		[this](const char* filename)
	{
		if (stricmp(filename, "Lplus.lua") == 0 ||
			stricmp(filename, "Enum.lua") == 0 ||
			stricmp(filename, "PBHelper.lua") == 0 ||
			stricmp(filename, "Test.lua") == 0 ||
			stricmp(filename, "Utility/BadWordsFilter.lua") == 0)
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

bool CLplusChecker::ParseGameText()
{
	std::string strFile = this->m_strConfigsDir;
	normalizeDirName(strFile);
	strFile += "game_text.lua";

	AFile File;
	if (!File.Open("", strFile.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
	{
		printf("Failed to open %s\n", strFile.c_str());
		return false;
	}

	bool inStringList = false;
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

		//
		if (strstr(szLine, "string_list ="))
		{
			inStringList = true;
		}

		if (inStringList && strstr(szLine, "}"))
		{
			inStringList = false;
		}

		if (inStringList)
		{
			const char* p0 = strstr(szLine, "[");
			const char* p1 = strstr(szLine, "]");
			const char* eq = strstr(szLine, "=");
			if (p0 && p1 && eq && (p0 + 1 < p1) && (p1 < eq) && (p1 - p0- 1) > 0)
			{
				char tmp[64] = { 0 };
				strncpy(tmp, p0 + 1, p1 - p0 - 1);
				int idx = atoi(tmp);
				m_GameTextKeySet.insert(idx);
			}
		}
	}

	return true;
}

bool CLplusChecker::BuildLuaClass(AFile* pFile, std::map<std::string, SLuaClass>& luaClass)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;

	char shortFileName[256];
	getFileNameA(pFile->GetFileName(), shortFileName, 256);

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

		HandleLine_ErrorToken(szLine, nLine, shortFileName);

		HandleLine_TableRemoveCheck(szLine, nLine, shortFileName);

		if (strstr(szLine, "def.") != NULL)
		{
			HandleLine_ErrorDefine(szLine, nLine, current);
		}

		if (strstr(szLine, "Lplus.Class(") != NULL)				//�ඨ��
		{
			HandleLine_ClassDefine(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "Lplus.Extend(") != NULL)			//��̳�
		{
			HandleLine_ClassExtend(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "def.field(") != NULL)		//�ֶζ���
		{
			HandleLine_FieldDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.method(") != NULL)		//��������
		{
			HandleLine_MethodDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.virtual(") != NULL)		//�鷽������
		{
			HandleLine_VirtualDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.override(") != NULL)		//���ط�������
		{
			HandleLine_OverrideDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "def.static(") != NULL)
		{
			HandleLine_StaticDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "_G.AddGlobalTimer") != NULL)
		{
			HandleLine_AddGlobalTimerDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "_G.RemoveGlobalTimer") != NULL)
		{
			HandleLine_RemoveGlobalTimerDefine(szLine, nLine, current);
		}
		else if (strstr(szLine, "StringTable.Get(") != NULL)
		{
			HandleLine_StringTableUse(szLine, nLine, current);
		}

		if (current && strstr(szLine, std::string(current->strName + ".Commit()").c_str()) != NULL)			//class����
		{
			current = NULL;
		}

		//���init.lua
		if (strstr(pFile->GetFileName(), "init.lua") == NULL)
		{
			HandleLine_ErrorInterfaces(szLine, nLine, current);
			HandleLine_ErrorConfigs(szLine, nLine, current);
		}

		//�������global����ʹ��
		if (current)
		{
			HandleLine_InvalidGlobalFields(szLine, nLine, current);
		}
	}

	return true;
}

bool CLplusChecker::GetLuaClassUsedMembers()
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

bool CLplusChecker::GetLuaClassUsedMembers(AFile* pFile, const std::map<std::string, SLuaClass>& luaClass)
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

		if (strstr(szLine, "Lplus.Class(") != NULL)				//�ඨ��
		{
			HandleLine_ClassDefine(pFile->GetFileName(), szLine, nLine, current);
		}
		else if (strstr(szLine, "Lplus.Extend(") != NULL)			//��̳�
		{
			HandleLine_ClassExtend(pFile->GetFileName(), szLine, nLine, current);
		}

		//�ռ��ֶ�ʹ��
		Get_SelfFieldUsedDirect(szLine, nLine, current);
		
		//�ռ�����ʹ��
		Get_SelfMethodUsedDirect(szLine, nLine, current);
		

		//�ռ�����ֶ�ʹ��
		Get_SelfFieldUsedIndirect(szLine, nLine, current);

		//�ռ���ӷ�������
		Get_SelfMethodUsedIndirect(szLine, nLine, current);

		//�ռ����м�ӷ���ʹ��
		Get_AllMethodUsedIndirect(szLine, nLine, current);

		//�ռ��������ⷽ��ʹ��
		Get_AllSpecialMethodUsedIndirect(szLine, nLine, current);

		//�ռ�ȫ���ֶ�ʹ��
		Get_GlobalFieldUsed(szLine, nLine, current);

		//�ռ�ȫ�ַ���ʹ��
		Get_GlobalMethodUsed(szLine, nLine, current);
	}

	return true;
}

void CLplusChecker::HandleLine_ProtoFields(const char* szLine, int nLine, SMessageToken*& messageToken)
{
	if (messageToken)
	{
		if (strlen(szLine) == 0 || szLine[0] == '}')				//message�������
		{
			messageToken = NULL;
			return;
		}

		const char* p = strstr(szLine, "repeated");
		if (p)
		{
			char type[1024];
			char name[1024];

			p += strlen("repeated");
			while (*p == ' ' || *p == '\t') ++p;			//ȥ���ո�

			//repeated ����
			{
				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}
				ASSERT(end);

				strncpy(type, start, end - start);
				type[end - start] = '\0';

				p = end;
			}
			
			while (*p == ' ' || *p == '\t') ++p;			//ȥ���ո�
		
			//repeated ����
			{
				const char* start = p;
				const char* end = p;

				while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
				{
					++end;
					if (*end < 0 || *end >= 255)
						break;
				}
				ASSERT(end);

				//���token��repeated�ֶ���
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				if (strcmp(type, "int32") == 0 || strcmp(type, "string") == 0 || strcmp(type, "int64") == 0)
					messageToken->repeatedFieldNameSet.insert(name);
			}
		}
	}
	else
	{
		const char* p = strstr(szLine, "message");
		if (p)
		{
			p += strlen("message");

			while (*p == ' ' || *p == '\t') ++p;			//ȥ���ո�

			const char* start = p;
			const char* end = p;

			while ((end == p) ? (*end == '_' || isalpha(*end)) : (*end == '_' || isalpha(*end) || isdigit(*end)))
			{
				++end;
				if (*end < 0 || *end >= 255)
					break;
			}

			if (end)
			{
				char name[1024];
				strncpy(name, start, end - start);
				name[end - start] = '\0';

				//if (strncmp(name, "C2S", 3) == 0)
				{
					messageToken = new SMessageToken;
					messageToken->protoName = name;
				}
			}
		}
	}
}

void CLplusChecker::Check_Proto_RepeatedFields(const std::set<std::string>& fieldSet)
{
	Q_iterateFiles(m_strLuaDir.c_str(),
		[this, &fieldSet](const char* filename)
	{
		if (stricmp(filename, "Lplus.lua") == 0 ||
			stricmp(filename, "Enum.lua") == 0 ||
			stricmp(filename, "PBHelper.lua") == 0 ||
			stricmp(filename, "Test.lua") == 0 ||
			stricmp(filename, "Utility/BadWordsFilter.lua") == 0)
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

		//����Ƿ����repeated�ֶ�
		{
			Check_Proto_RepeatedFields(&File, fieldSet);
		}

		File.Close();
	},
		m_strLuaDir.c_str());
}

void CLplusChecker::Check_Proto_RepeatedFields(AFile* pFile, const std::set<std::string>& fieldSet)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	char shortFileName[256];
	getFileNameA(pFile->GetFileName(), shortFileName, 256);

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
	
		for (const std::string& field : fieldSet)
		{
			std::string strKey = "." + field;
			const char* p = strstr(szLine, strKey.c_str());
			if (p)
			{
				p += strlen(strKey.c_str());
				while (*p == ' ' || *p == '\t') ++p;
					
				//if ((*p == '=' && *(p+1) != '=') || (*p == '[') )
				if (*p == '[')
				{
					const char* end = strstr(p, "]");
					if (end)
					{
						const char* eq = strstr(end, "=");
						if (eq && *(eq-1) != '~' && *(eq + 1) != '=')
						{
							m_invalidRepeatedFieldList.push_back(SOutputEntry3(
								shortFileName,
								strKey.c_str(),
								nLine));
						}
					}
				}
			}
		}
	}
}

void CLplusChecker::HandleLine_ErrorInterfaces(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		{
			const char* p = strstr(szLine, "Assets/Outputs/Interfaces");
			if (p)
				current->errorInterfaceLines.insert(nLine);
		}
		{
			const char* p = strstr(szLine, "_G.InterfacesDir");
			if (p && strstr(szLine, ".png"))
				current->errorInterfaceLines.insert(nLine);
		}
	}
}

void CLplusChecker::HandleLine_ErrorConfigs(const char* szLine, int nLine, SLuaClass* current)
{
	if (current)
	{
		bool bContain = strstr(szLine, "Configs/ActivityTypeCfg") != NULL || 
			strstr(szLine, "Configs/chatcfg") != NULL ||
			strstr(szLine, "Configs/CommandList") != NULL ||
			strstr(szLine, "Configs/debug_text") != NULL ||
			strstr(szLine, "Configs/emotions") != NULL ||
			strstr(szLine, "Configs/game_text") != NULL ||
			(strstr(szLine, "Configs/MapBasicInfo") != NULL && strstr(szLine, "Configs/MapBasicInfo/LinkToScene") == NULL) ||
			strstr(szLine, "Configs/ModuleProfDiffCfg") != NULL ||
			strstr(szLine, "Configs/RandomName") != NULL || 
			strstr(szLine, "Configs/SystemEntranceCfg") != NULL;

		if (bContain)
			current->errorConfigsLines.insert(nLine);
	}
}

void CLplusChecker::HandleLine_InvalidGlobalFields(const char* szLine, int nLine, SLuaClass* current)
{
	for (const auto& entry : m_ClassInvalidTokenList)
	{
		const std::string& token = std::get<0>(entry);
		const std::string& className = std::get<1>(entry);

		if (current->strName != className)
			continue;

		const char* p = strstr(szLine, token.c_str());
		if (p)
		{
			int col = (int)(p - szLine);
			m_invalidGlobalFieldList.push_back(SOutputEntry4(
				token,
				className,
				nLine,
				col));
		}
	}
}


bool CLplusChecker::ParseFunctionDeclToken(const char* begin, const char* end, std::vector<std::string>& vParams, std::vector<std::string>& vRets) const
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
	bool bEqual = false;		//�Ƿ��Ѿ������� =>
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
							--end;				//ȥ��β���Ŀ��ַ�

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//ȡ����.�Ժ���ַ���
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//��Ӳ����ͷ���ֵ����
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

bool CLplusChecker::ParseFunctionParamToken(const char* begin, std::vector<std::string>& vParams) const
{
	const char* end = strrchr(begin, ')');
	if (!end)
	{
		assert(false);
		return false;
	}

	while(*begin == ' ' && begin < end) ++begin;

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
							--end;				//ȥ��β���Ŀ��ַ�

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//ȡ����.�Ժ���ַ���
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//��Ӳ����ͷ���ֵ����
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

bool CLplusChecker::ParseUseFunctionToken(const char* begin, std::vector<std::string>& vParams, bool& bHasFunction) const
{
	if (strstr(begin, "function"))
	{
		bHasFunction = true;
		return true;					//skip
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

	// 	if (strncmp(begin, "(\'Btn_Item\'", strlen("(\'Btn_Item\'")) == 0)
	// 	{
	// 		int x = 0;
	// 	}

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
							--end;				//ȥ��β���Ŀ��ַ�

						strncpy(name, pToken, end - pToken);
						name[end - pToken] = '\0';
					}

					//ȡ����.�Ժ���ַ���
					const char* pt = strrchr(name, '.');
					if (pt &&
						*(pt + 1) != '\0')
					{
						char tmp[1024];
						strcpy(tmp, pt + 1);
						strcpy(name, tmp);
					}

					//��Ӳ����ͷ���ֵ����
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

bool CLplusChecker::GetNumReturnsOfLine(const char* begin, std::vector<std::string>& vRets) const
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

		if (*p == ',' || p == end )
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

					//��Ӳ����ͷ���ֵ����
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


bool CLplusChecker::CheckLuaClassesToFile(const char* strFileName)
{
	FILE* pFile = fopen(strFileName, "wt");
	if (!pFile)
		return false;

	fprintf(pFile, "������ʹ�ü��:\n");
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		for (int nLine : luaClass.errorInterfaceLines)
		{
			fprintf(pFile, "error interfaces, in class %s, at line %d\n", luaClass.strName.c_str(), nLine);
		}

		for (int nLine : luaClass.errorConfigsLines)
		{
			fprintf(pFile, "error configs, in class %s, at line %d\n", luaClass.strName.c_str(), nLine);
		}
	}
	fprintf(pFile, "\n");

	fprintf(pFile, "def������:\n");

	for (const auto& entry : m_errorTokenList)
	{
		fprintf(pFile,
			"invalid token %s, in file %s, at line %d, col %d\n",
			entry.token.c_str(),
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}

	for (const auto& entry : m_errorDefineList)
	{
		fprintf(pFile,
			"invalid define, in class %s, at line %d, col %d\n",
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}
	fprintf(pFile, "\n");

	fprintf(pFile, "����������:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//����������
		Check_MethodDefinitionToFile(pFile, luaClass);
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "�ظ��ֶζ�����:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//����������
		Check_DuplicateField(luaClass);
	}

	for (const auto& entry : m_dupLuaFieldList)
	{
		fprintf(pFile,
			"duplicate field defined %s, in class %s, at line %d, col %d\n",
			entry.token.c_str(),
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}
	fprintf(pFile, "\n");

	fprintf(pFile, "�ظ�����������:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//����������
		Check_DuplicateMethod(luaClass);
	}

	for (const auto& entry : m_dupFunctionList)
	{
		fprintf(pFile,
			"duplicate function defined %s, in class %s, at line %d, col %d\n",
			entry.token.c_str(),
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}
	fprintf(pFile, "\n");

	fprintf(pFile, "�ֶ�ʹ�ü��:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//�ֶ�ʹ�ü��
		Check_FieldUsedDirectToFile(pFile, luaClass);
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "����ʹ�ü��:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//����ʹ�ü��
		Check_MethodUsedDirectToFile(pFile, luaClass);
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "�����̳й�ϵ���:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		//�̳з������
		Check_MethodInheritanceToFile(pFile, luaClass);
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "����ֶ�ʹ�ü��(����������):\n");

	{
		std::set<SOutputEntry5> entrySet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			//����ֶ�ʹ�ü��
			Check_FieldUsedIndirectToFile(pFile, luaClass, entrySet);
		}
		for (const auto& entry : entrySet)
		{
			fprintf(pFile,
				"undefined token indirect field used %s (%s), in class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry).c_str(),
				std::get<3>(entry),
				std::get<4>(entry));
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "��ӷ���ʹ�ü��:\n");

	{
		std::set<SOutputEntry5> entrySet;
		std::set<SOutputEntry7> entryParamSet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			//��ӷ���ʹ�ü��
			Check_MethodUsedIndirectToFile(pFile, luaClass, entrySet, entryParamSet);
		}
		for (const auto& entry : entrySet)
		{
			fprintf(pFile,
				"undefined token indirect method used %s (%s), in class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry).c_str(),
				std::get<3>(entry),
				std::get<4>(entry));
		}

		for (const auto& entry : entryParamSet)
		{
			fprintf(pFile,
				"incorrect token indirect method params used %s (%s) (param count=%d, required=%d), class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry),
				std::get<3>(entry),
				std::get<4>(entry).c_str(),
				std::get<5>(entry),
				std::get<6>(entry));
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "ȫ�������������:\n");

	{
		std::set<SOutputEntry7> entryParamSet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			Check_AllMethodusedIndirectToFile(pFile, luaClass, entryParamSet);
		}

		for (const auto& entry : entryParamSet)
		{
			fprintf(pFile,
				"incorrect method params number used %s (param count=%d), class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<2>(entry),
				std::get<4>(entry).c_str(),
				std::get<5>(entry),
				std::get<6>(entry));
		}
	}

// 	{
// 		std::set<SOutputEntry7> entryParamSet;
// 		for (const auto& entry : m_mapLuaClass)
// 		{
// 			const auto& luaClass = entry.second;
// 
// 			Check_AllStaticMethodusedIndirectToFile(pFile, luaClass, entryParamSet);
// 		}
// 
// 		for (const auto& entry : entryParamSet)
// 		{
// 			fprintf(pFile,
// 				"incorrect static method params number used %s (param count=%d), class %s, at line %d, col %d\n",
// 				std::get<0>(entry).c_str(),
// 				std::get<2>(entry),
// 				std::get<4>(entry).c_str(),
// 				std::get<5>(entry),
// 				std::get<6>(entry));
// 		}
// 	}

	fprintf(pFile, "\n");

	fprintf(pFile, "���ⷽ���������:\n");

	{
		std::set<SOutputEntry7> entryParamSet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			Check_AllSpecialMethodusedIndirectToFile(pFile, luaClass, entryParamSet);
		}

		for (const auto& entry : entryParamSet)
		{
			fprintf(pFile,
				"incorrect special method params number used %s (param count=%d), class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<2>(entry),
				std::get<4>(entry).c_str(),
				std::get<5>(entry),
				std::get<6>(entry));
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "ȫ���ֶ�ʹ�ü��(����������):\n");

	{
		std::set<SOutputEntry5> entrySet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			Check_AllGlobalFieldUsedToFile(pFile, luaClass, entrySet);
		}
		for (const auto& entry : entrySet)
		{
			fprintf(pFile,
				"undefined token global field used %s (%s), in class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry).c_str(),
				std::get<3>(entry),
				std::get<4>(entry));
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "ȫ�ַ���ʹ�ü��:\n");

	{
		std::set<SOutputEntry5> entrySet;
		std::set<SOutputEntry7> entryParamSet;
		for (const auto& entry : m_mapLuaClass)
		{
			const auto& luaClass = entry.second;

			Check_AllGlobalMethodUsedToFile(pFile, luaClass, entrySet, entryParamSet);
		}
		for (const auto& entry : entrySet)
		{
			fprintf(pFile,
				"undefined token global method used %s (%s), in class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry).c_str(),
				std::get<3>(entry),
				std::get<4>(entry));
		}

		for (const auto& entry : entryParamSet)
		{
			fprintf(pFile,
				"incorrect token global method params used %s (%s) (param count=%d, required=%d), class %s, at line %d, col %d\n",
				std::get<0>(entry).c_str(),
				std::get<1>(entry).c_str(),
				std::get<2>(entry),
				std::get<3>(entry),
				std::get<4>(entry).c_str(),
				std::get<5>(entry),
				std::get<6>(entry));
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "��������ֵ���:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		
		Check_MethodReturnNum(luaClass);
	}

	for (const auto& entry : m_ErrorMethodNumReturnMap)
	{
		const auto& classname = entry.first;
		for (const auto& item : entry.second)
		{
			const std::string& methodName = std::get<0>(item);
			int line = std::get<1>(item);
			int nRequire = std::get<2>(item);
			int nReturn = std::get<3>(item);

			fprintf(pFile,
				"����ķ���ֵ����, ��: %s, \t����: %s, \t��: %d, \tҪ�����: %d, \tʵ�ʸ���: %d\n",
				classname.c_str(),
				methodName.c_str(),
				line,
				nRequire,
				nReturn);
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "addHandler���:\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		Check_AddEventHandler(luaClass);
	}

	for (const auto& entry : m_ErrorAddHandlerMap)
	{
		const auto& classname = entry.first;
		for (const auto& item : entry.second)
		{
			const std::string& methodName = std::get<0>(item);
			int line = std::get<1>(item);
			const std::string& funcName = std::get<2>(item);

			fprintf(pFile,
				"�����addHandler, ��: %s, \t����: %s, \t��: %d, \tCALLBACK: %s\n",
				classname.c_str(),
				methodName.c_str(),
				line,
				funcName.c_str());
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "StringTable.Get����id��game_text�Ҳ���:\n");

	std::set<SStringTableToken> stringTableToken;
	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;

		Check_GameTextUsedToFile(luaClass, stringTableToken);
	}

	for (const auto& entry : stringTableToken)
	{
		fprintf(pFile,
			"cannot find CStringTable.Get() %d class %s, at line %d, col %d\n",
			entry.text_id,
			entry.className.c_str(),
			entry.location.line,
			entry.location.col);
	}

	fprintf(pFile, "\n");

	/*
	fprintf(pFile, "RepeatedCompositeFieldContainerֱ�Ӹ�ֵ�Ĵ���:\n");

	for (const auto& entry : m_invalidRepeatedFieldList)
	{
		fprintf(pFile,
			"error [RepeatedCompositeFieldContainer =] field used %s, in class %s, at line %d\n",
			std::get<0>(entry).c_str(),
			std::get<1>(entry).c_str(),
			std::get<2>(entry));
	}

	fprintf(pFile, "\n");
	*/

	fprintf(pFile, "���ܳ��ֵ�table.removeѭ������:\n");

	for (const auto& entry : m_tableCheckMap)
	{
		if (entry.second.nInverseFor < entry.second.nTableRemove)
		{
			fprintf(pFile,
				"%s, InverseFor: %d, table.remove: %d\n",
				entry.first.c_str(),
				entry.second.nInverseFor,
				entry.second.nTableRemove);
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "�ֶκͷ����������(�ֶΣ�ǰ׺��_����ͷ��Ȼ�����д��ĸ, ����: ��д��ĸ��ͷ):\n");

	for (const auto& entry : m_mapLuaClass)
	{
		const auto& luaClass = entry.second;
		if (luaClass.strName == "CQuestObjectiveModel" ||
			luaClass.strName == "CQuestModel" ||
			luaClass.strName == "CQuestData" ||
			luaClass.strName == "ModelParams" ||
			luaClass.strName == "AnonymousEventManager" )
		{
			continue;					//����
		}

		Check_FieldMethodNameStandard(luaClass);
	}

	for (const auto& fieldSet : m_errorNameFieldMap)
	{
		fprintf(pFile, "\n");
		for (const auto& entry : fieldSet.second)
		{
			fprintf(pFile,
				"\t�����Ϲ淶���ֶ� %s, �� %s, �� %d, �� %d\n",
				entry.token.c_str(),
				entry.className.c_str(),
				entry.location.line,
				entry.location.col);
		}
		
	}
	
	fprintf(pFile, "\n");

	for (const auto& functionSet : m_errorNameFunctionMap)
	{
		fprintf(pFile, "\n");
		for (const auto& entry : functionSet.second)
		{
			fprintf(pFile,
				"\t�����Ϲ淶�ķ��� %s, �� %s, �� %d, �� %d\n",
				entry.token.c_str(),
				entry.className.c_str(),
				entry.location.line,
				entry.location.col);
		}
	}

	fprintf(pFile, "\n");

	fprintf(pFile, "�����ȫ�ֱ���ʹ��(ȫ�ֱ����ڶ�������ʹ��):\n");

	for (const auto& entry : m_invalidGlobalFieldList)
	{
		fprintf(pFile,
			"error global field used %s, in class %s, at line %d, col %d\n",
			std::get<0>(entry).c_str(),
			std::get<1>(entry).c_str(),
			std::get<2>(entry),
			std::get<3>(entry));
	}

	fprintf(pFile, "\n");

	fclose(pFile);
	return true;
}
const SLuaClass* CLplusChecker::GetLuaClass(const char* szName) const
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLplusChecker::GetLuaClass(const char* szName)
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLplusChecker::AddLuaClass(const char* szName)
{
	m_mapLuaClass[szName] = SLuaClass();
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;
	else
		return NULL;
}

bool CLplusChecker::CollectAndCheckNetProto()
{
	return CollectAndCheckProto(m_strNetProtoFileName);
}

bool CLplusChecker::CollectAndCheckTemplateProto()
{
	return CollectAndCheckProto(m_strTemplateProtoFileName);
}

bool CLplusChecker::CollectAndCheckProto(const std::string& strFileName)
{
	AFile File;
	if (!File.Open("", strFileName.c_str(), AFILE_OPENEXIST | AFILE_TEXT))
	{
		printf("Failed to open %s\n", strFileName.c_str());
		return false;
	}

	std::vector<SMessageToken*>  messageTokens;

	File.Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;
	char szLine[AFILE_LINEMAXLEN];
	int nLine = 0;
	bool bComment = false;
	SMessageToken* current = NULL;
	while (File.ReadLine(szLine, AFILE_LINEMAXLEN, &dwReadLen))
	{
		++nLine;

		//comment
		char* pComment = strstr(szLine, "//");
		if (pComment)
			*pComment = '\0';

		SMessageToken* last = current;
		HandleLine_ProtoFields(szLine, nLine, current);

		if (!last && current)
			messageTokens.push_back(current);
	}

	for (auto itr = messageTokens.begin(); itr != messageTokens.end();)
	{
		if ((*itr)->repeatedFieldNameSet.empty())
			itr = messageTokens.erase(itr++);
		else
			++itr;
	}

	std::set<std::string> fieldSet;
	for (auto entry : messageTokens)
	{
		for (auto str : entry->repeatedFieldNameSet)
		{
			fieldSet.insert(str);
		}
	}

	for (auto str : fieldSet)
	{
		printf("%s\n", str.c_str());
	}

	Check_Proto_RepeatedFields(fieldSet);

	for (auto entry : messageTokens)
		delete entry;

	return true;
}


std::string CLplusChecker::getFieldType(const SLuaClass* luaClass, const char* szField, bool searchDerive) const
{
	const SLuaClass* thisClass = luaClass;

	//search base
	while (thisClass)
	{
		std::string ret = "";
		bool bFind = false;
		for (const auto& e : thisClass->fieldDefList)
		{
			if (e.token == szField)
			{
				bFind = true;
				ret = e.typeName;
			}
		}

		if (bFind)
			return ret;

		thisClass = thisClass->parent;
	}

	if (searchDerive)
	{
		//search derive
		for (const auto& kv : m_mapLuaClass)
		{
			const SLuaClass* lc = &kv.second;
			if (lc->IsSelfOrParent(luaClass))
			{
				thisClass = lc;
				while (thisClass)
				{
					if (thisClass == luaClass)
						break;

					auto itr = std::find_if(thisClass->fieldDefList.begin(), thisClass->fieldDefList.end(),
						[szField](const SLuaFieldToken& token){
						return token.token == szField; }
					);
					if (itr != thisClass->fieldDefList.end())
						return itr->typeName;

					thisClass = thisClass->parent;
				}
			}
		}
	}

	return "";
}