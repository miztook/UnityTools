#include "CLuaDataChecker.h"
#include "function.h"
#include <algorithm>
#include "stringext.h"
#include "CLuaDataChecker.h"

std::string g_TemplateNames[] =
{
	"Achievement",
	"Actor",
	"AdventureGuide",
	"Asset",
	"AttachedPropertyGenerator",
	"AttachedPropertyGroupGenerator",
	"AttachedProperty",
	"Banner",
	"CharmItem",
	"CharmPage",
	"CharmField",
	"CharmUpgrade",
	"ColorConfig",
	"Cooldown",
	"CountGroup",
	"CyclicQuest",
	"CyclicQuestReward",
	"Designation",
	"Dialogue",
	"Dress",
	"DressScore",
	"DropLibrary",
	"DropLimit",
	"DropRule",
	"DyeAndEmbroidery",
	"EliminateReward",
	"Email",
	"Enchant",
	"EquipConsumeConfig",
	"EquipInforce",
	"EquipRefine",
	"EquipSuit",
	"ExecutionUnit",
	"Expedition",
	"Faction",
	"FactionRelationship",
	"FightPropertyConfig",
	"FightProperty",
	"Fortress",
	"Fund",
	"Fun",

};

CLuaDataChecker::CLuaDataChecker(const std::string& strConfigsDir, const std::string& strLuaDir)
{
	m_strConfigsDir = strConfigsDir;
	m_strLuaDir = strLuaDir;

	InitData();
}

bool CLuaDataChecker::SearchLuaFiles()
{
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

		SearchLuaFile(&File);

		File.Close();
	},
		m_strLuaDir.c_str());

	return true;
}

void CLuaDataChecker::PrintLuaClasses()
{
	for (auto kv : m_mapLuaClass)
	{
		printf("luaClass: %s\n", kv.first.c_str());
	}
}

void CLuaDataChecker::PrintLuaFiles()
{
	for (auto v : m_vecLuaFiles)
	{
		printf("luaFile: %s\n", v.strFileName.c_str());
	}
}

void CLuaDataChecker::InitData()
{
	for (auto v : g_TemplateNames)
	{
		m_TemplateNames.push_back(v);
	}
}

bool CLuaDataChecker::SearchLuaFile(AFile * pFile)
{
	pFile->Seek(0, AFILE_SEEK_SET);

	auint32 dwReadLen;

	char shortFileName[256];
	getFileNameA(pFile->GetFileName(), shortFileName, 256);

	SLuaFile* luaFile = AddLuaFile(pFile->GetFileName());

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
		else if (strstr(szLine, "CElementData.") != NULL)
		{
			HandleLine_SearchElementData(szLine, nLine, current);
			HandleLine_SearchElementData(szLine, nLine, luaFile);
		}

		if (current && strstr(szLine, std::string(current->strName + ".Commit()").c_str()) != NULL)			//class结束
		{
			current = NULL;
		}
	}
	return false;
}

const SLuaClass* CLuaDataChecker::GetLuaClass(const char* szName) const
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLuaDataChecker::GetLuaClass(const char* szName)
{
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;

	return NULL;
}

SLuaClass* CLuaDataChecker::AddLuaClass(const char* szName)
{
	m_mapLuaClass[szName] = SLuaClass();
	auto itr = m_mapLuaClass.find(szName);
	if (itr != m_mapLuaClass.end())
		return &itr->second;
	else
		return NULL;
}

SLuaFile* CLuaDataChecker::AddLuaFile(const char* szFileName)
{
	SLuaFile luaFile;
	luaFile.strFileName = szFileName;
	m_vecLuaFiles.push_back(luaFile);
	return &m_vecLuaFiles.back();
}

void CLuaDataChecker::HandleLine_ClassDefine(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

void CLuaDataChecker::HandleLine_ClassExtend(const char* szFileName, const char* szLine, int nLine, SLuaClass*& current)
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

void CLuaDataChecker::HandleLine_SearchElementData(const char* szLine, int nLine, SLuaClass* current)
{
}

void CLuaDataChecker::HandleLine_SearchElementData(const char* szLine, int nLine, SLuaFile* current)
{

}
