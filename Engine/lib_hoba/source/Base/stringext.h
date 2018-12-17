#pragma once

#include "ATypes.h"
#include <string>
#include <clocale>
#include <vector>

inline bool isAbsoluteFileName(const std::string& filename)
{
	unsigned int len = (unsigned int)filename.length();
#ifdef  A_PLATFORM_WIN_DESKTOP
	if (len >= 2)
		return filename[1] == ':';
#else
	if (len >= 1)
		return filename[0] == '/';
#endif

	return false;
}

inline void normalizeFileName(std::string& filename)
{
	unsigned int len = (unsigned int)filename.length();
	for (unsigned int i = 0; i < len; ++i)
	{
		if (filename[i] == '\\')
			filename[i] = '/';
	}
}

inline void normalizeDirName(std::string& dirName)
{
	unsigned int len = (unsigned int)dirName.length();
	for (unsigned int i = 0; i < len; ++i)
	{
		if (dirName[i] == '\\')
			dirName[i] = '/';
	}

	if (len > 0)
	{
		char last = dirName.back();
		if (last != '/' && last != '\\')
			dirName.append("/");
	}
}

inline bool isNormalized(const std::string& filename)
{
	unsigned int len = (unsigned int)filename.length();
	for (unsigned int i = 0; i < len; ++i)
	{
		if (filename[i] == '\\')
			return false;
	}
	return true;
}

inline bool isLowerFileName(const std::string& filename)
{
	unsigned int len = (unsigned int)filename.length();
	for (unsigned int i = 0; i < len; ++i)
	{
		if (isupper(filename[i]))
			return false;
	}
	return true;
}

inline bool isSpace(char ch)
{
	return ch == '\t' || ch == '\r' || ch == ' ';
}

inline bool isComment(const char* p)
{
	auint32 len = (auint32)strlen(p);
	for (auint32 i = 0; i < len; ++i)
	{
		if (isSpace(p[i]))
			continue;

		if (i + 1 < len && p[i] == '/' && p[i + 1] == '/')
			return true;
		else
			return false;
	}
	return false;
}

inline bool isEnclosedStart(const char* p)
{
	auint32 len = (auint32)strlen(p);
	for (auint32 i = 0; i < len; ++i)
	{
		if (isSpace(p[i]))
			continue;

		if (i + 1 < len && p[i] == '/' && p[i + 1] == '*')
			return true;
		else
			return false;
	}
	return false;
}

inline bool isEnclosedEnd(const char* p)
{
	int len = (int)strlen(p);
	for (int i = len - 1; i >= 0; --i)
	{
		if (isSpace(p[i]))
			continue;

		if (i - 1 >= 0 && p[i - 1] == '*' && p[i] == '/')
			return true;
		else
			return false;
	}
	return false;
}

//make multiple #define MACRO, split by #
inline void makeMacroString(std::string& macroString, const char* strMacro)
{
	macroString.clear();
	auint32 len = (auint32)strlen(strMacro);
	if (len == 0)
		return;

	auint32 p = 0;
	for (auint32 i = 0; i < len; ++i)
	{
		if (strMacro[i] == '#')	//split
		{
			if (i - p > 0)
			{
				std::string str(&strMacro[p], i - p);
				macroString.append("#define ");
				macroString.append(str.c_str());
				macroString.append("\n");
			}
			p = i + 1;
		}
	}

	//last
	if (len - p > 0)
	{
		std::string str(&strMacro[p], len - p);
		macroString.append("#define ");
		macroString.append(str.c_str());
		macroString.append("\n");
	}
}

inline void makeMacroStringList(std::vector<std::string>& macroStrings, const char* strMacro)
{
	macroStrings.clear();
	auint32 len = (auint32)strlen(strMacro);
	if (len == 0)
		return;

	auint32 p = 0;
	for (auint32 i = 0; i < len; ++i)
	{
		if (i > 0 && strMacro[i] == '#')	//split
		{
			if (i - p > 0)
			{
				std::string str(&strMacro[p], i - p);
				p = i + 1;
				macroStrings.push_back(str.c_str());
			}
		}
	}

	//last
	if (len - p > 0)
	{
		std::string str(&strMacro[p], len - p);
		macroStrings.push_back(str.c_str());
	}
}

inline bool getToken(const char* pszLine, std::string& strToken)
{
	const char* pChar = pszLine;

	while (isSpace(*pChar))
	{
		++pChar;
	}

	const char* pszTokenStart = pChar;

	// If it starts with ", then it's a string, and we should end searching until found another ".
	if (*pszTokenStart == '\"')
	{
		++pChar;

		while (*pChar != '\"' && *pChar != 0 && *pChar != '\n')
		{
			++pChar;
		}

		if (*pChar == '\"')
		{
			++pChar;
		}
	}
	// If it's not a string.
	else
	{
		while (!isSpace(*pChar) && *pChar != 0 && *pChar != '\n')
		{
			++pChar;
		}
	}

	const char* pszTokenEnd = pChar;

	if (pszTokenEnd == pszTokenStart)
	{
		return false;
	}

	strToken = std::string(pszTokenStart, pszTokenEnd - pszTokenStart);
	return true;
}

inline void trim(std::string& s, const std::string& drop)
{
	// trim right
	s.erase(s.find_last_not_of(drop) + 1);
	// trim left
	s.erase(0, s.find_first_not_of(drop));
}

inline void ltrim(std::string& s, const std::string& drop)
{
	// trim left
	s.erase(0, s.find_first_not_of(drop));
}
inline void rtrim(std::string& s, const std::string& drop)
{
	// trim right
	s.erase(s.find_last_not_of(drop) + 1);
}

inline std::string & std_string_format(std::string& _str, const char* _Format, ...) {
	std::string tmp;

	va_list marker = NULL;
	va_start(marker, _Format);

	size_t num_of_chars = _vscprintf(_Format, marker);

	if (num_of_chars > tmp.capacity()) {
		tmp.resize(num_of_chars + 1);
	}

	vsprintf_s((char *)tmp.data(), tmp.capacity(), _Format, marker);

	va_end(marker);

	_str = tmp.c_str();
	return _str;
}

inline void std_string_split(const std::string& origStr, char split, std::vector<std::string>& retVString)
{
	retVString.clear();

	char* str = new char[origStr.length() + 1];
	assert(str);
	strcpy(str, origStr.data());

	char* pchStart = str;
	char* pch = nullptr;
	while (true)
	{
		pch = strchr(pchStart, split);
		if (pch)
			*pch = '\0';

		if (strlen(pchStart) > 0)
			retVString.push_back(pchStart);

		if (!pch)
			break;

		pchStart = pch + 1;
	}
	delete[] str;
}

inline void std_string_split(const std::string& origStr, const char *split, std::vector<std::string>& retVString)
{
	retVString.clear();

	char* str = new char[origStr.length() + 1];
	ASSERT(str);
	strcpy(str, origStr.data());

	char* pchStart = str;
	char* pch = nullptr;
	while (true)
	{
		pch = strstr(pchStart, split);
		if (pch)
			*pch = '\0';

		if (strlen(pchStart) > 0)
			retVString.push_back(pchStart);

		if (!pch)
			break;

		pchStart = pch + strlen(split);
	}
	delete[] str;
}

inline std::string std_string_left(const std::string& str, int n)
{
	int iLen = (int)str.length();
	return std::string(str.data(), iLen < n ? iLen : n);
}

inline std::string std_string_right(const std::string& str, int n)
{
	int iFrom = (int)str.length() - n;
	return std::string(str.data(), iFrom < 0 ? 0 : n);
}

inline std::string std_string_mid(const std::string& str, int iFrom, int iNum = -1)
{
	int iLen = (int)str.length() - iFrom;
	if (iLen <= 0 || iNum)
		return std::string();
	if (iNum > 0 && iLen > iNum)
		iLen = iNum;
	return std::string(str.data() + iFrom, iLen);
}

inline void std_string_replace(std::string& str, char cFrom, char cTo)
{
	int iLen = (int)str.length();
	if (!iLen)
		return;

	for (int i = 0; i < iLen; i++)
	{
		if (str[i] == cFrom)
			str[i] = cTo;
	}
}

inline void std_string_replace(std::string& str, const char* szFrom, const char* szTo)
{
	int fromlen = (int)strlen(szFrom);
	std::string::size_type i = str.find_first_of(szFrom);
	while (i != std::string::npos)
	{	
		str = std_string_left(str, i) + std::string(szTo) + std_string_mid(str, (int)i + fromlen);
		i = str.find_first_of(szFrom);
	}
}