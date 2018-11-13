﻿#include "AString.h"
#include "function.h"
#include <cwchar>

struct s_EMPTYSTRING
{
	AString::s_STRINGDATA	Data;

	char	szStr[1];

	s_EMPTYSTRING()
	{
		Data.iRefs = 0;
		Data.iDataLen = 0;
		Data.iMaxLen = 0;
		szStr[0] = '\0';
	}
};

//	For an empty string, m_pchData will point here
static s_EMPTYSTRING l_EmptyString;
char* AString::m_pEmptyStr = l_EmptyString.szStr;

/*	Alocate string buffer

iLen: length of data (not including terminator)
*/
char* AString::AllocBuffer(int iLen)
{
	s_STRINGDATA* pData;

	if (iLen < 64)
	{
		pData = (s_STRINGDATA*)malloc(64 + sizeof(s_STRINGDATA));

		pData->iRefs = 1;
		pData->iDataLen = iLen;
		pData->iMaxLen = 63;
	}
	else if (iLen < 128)
	{
		pData = (s_STRINGDATA*)malloc(128 + sizeof(s_STRINGDATA));

		pData->iRefs = 1;
		pData->iDataLen = iLen;
		pData->iMaxLen = 127;
	}
	else if (iLen < 256)
	{
		pData = (s_STRINGDATA*)malloc(256 + sizeof(s_STRINGDATA));

		pData->iRefs = 1;
		pData->iDataLen = iLen;
		pData->iMaxLen = 255;
	}
	else if (iLen < 512)
	{
		pData = (s_STRINGDATA*)malloc(512 + sizeof(s_STRINGDATA));

		pData->iRefs = 1;
		pData->iDataLen = iLen;
		pData->iMaxLen = 511;
	}
	else
	{
		pData = (s_STRINGDATA*)malloc(iLen + 1 + sizeof(s_STRINGDATA));

		pData->iRefs = 1;
		pData->iDataLen = iLen;
		pData->iMaxLen = iLen;
	}

	return (char*)pData + sizeof(s_STRINGDATA);
}

//	Free string data buffer
void AString::FreeBuffer(s_STRINGDATA* pStrData)
{
	switch (pStrData->iRefs)
	{
	case 0:	return;
	case 1:

		free(pStrData);
		break;

	default:

		pStrData->iRefs--;
		break;
	}
}

//	Copy iLen characters from szSrc to szDest and add terminator at the tail of szDest
void AString::StringCopy(char* szDest, const char* szSrc, int iLen)
{
	int i, iSpan = sizeof(aint32);
	const aint32 *p1 = (const aint32*)szSrc;
	aint32 *p2 = (aint32*)szDest;

	for (i = 0; i < iLen / iSpan; i++, p1++, p2++)
		*p2 = *p1;

	for (i *= iSpan; i < iLen; i++)
		szDest[i] = szSrc[i];

	szDest[i] = '\0';
}

//	Judge whether two strings are equal
bool AString::StringEqual(const char* s1, const char* s2, int iLen)
{
	int i, iSpan = sizeof(aint32);
	const aint32 *p1 = (const aint32 *)s1;
	const aint32 *p2 = (const aint32 *)s2;

	for (i = 0; i < iLen / iSpan; i++, p1++, p2++)
	{
		if (*p1 != *p2)
			return false;
	}

	for (i *= iSpan; i < iLen; i++)
	{
		if (s1[i] != s2[i])
			return false;
	}

	return true;
}

//	Allocate memory and copy string
char* AString::AllocThenCopy(const char* szSrc, int iLen)
{
	if (!iLen)
		return m_pEmptyStr;

	char* s = AllocBuffer(iLen);
	StringCopy(s, szSrc, iLen);

	return s;
}

//	Allocate a new string which is merged by szSrc + ch
char* AString::AllocThenCopy(const char* szSrc, char ch, int iLen)
{
	if (!ch)
		return AllocThenCopy(szSrc, iLen - 1);

	char* s = AllocBuffer(iLen);
	StringCopy(s, szSrc, iLen - 1);

	s[iLen - 1] = ch;
	s[iLen] = '\0';

	return s;
}

//	Allocate a new string which is merged by ch + szSrc
char* AString::AllocThenCopy(char ch, const char* szSrc, int iLen)
{
	if (!ch)
		return l_EmptyString.szStr;

	char* s = AllocBuffer(iLen);

	s[0] = ch;
	StringCopy(s + 1, szSrc, iLen - 1);

	return s;
}

//	Allocate a new string which is merged by s1 + s2
char* AString::AllocThenCopy(const char* s1, const char* s2, int iLen1, int iLen2)
{
	if (!iLen2)
		return AllocThenCopy(s1, iLen1);

	int iLen = iLen1 + iLen2;
	char* s = AllocBuffer(iLen);

	StringCopy(s, s1, iLen1);
	StringCopy(s + iLen1, s2, iLen2);

	return s;
}

AString::AString(const AString& str)
{
	if (str.IsEmpty())
	{
		m_pStr = m_pEmptyStr;
		return;
	}

	s_STRINGDATA* pSrcData = str.GetData();

	if (pSrcData->iRefs == -1)	//	Source string is being locked
	{
		//s_STRINGDATA* pData = GetData();
		m_pStr = AllocThenCopy(str.m_pStr, pSrcData->iDataLen);
	}
	else
	{
		pSrcData->iRefs++;
		m_pStr = str.m_pStr;
	}
}

AString::AString(const char* szStr)
{
	int iLen = SafeStrLen(szStr);
	m_pStr = AllocThenCopy(szStr, iLen);
}

AString::AString(const char* szStr, int iLen)
{
	m_pStr = AllocThenCopy(szStr, iLen);
}

AString::AString(char ch, int iRepeat)
{
	m_pStr = AllocBuffer(iRepeat);
	memset(m_pStr, ch, iRepeat);
	m_pStr[iRepeat] = '\0';
}

AString::AString(const AString& str1, const AString& str2)
{
	m_pStr = AllocThenCopy(str1.m_pStr, str2.m_pStr, str1.GetLength(), str2.GetLength());
}

AString::AString(char ch, const AString& str)
{
	m_pStr = AllocThenCopy(ch, str.m_pStr, str.GetLength() + 1);
}

AString::AString(const AString& str, char ch)
{
	m_pStr = AllocThenCopy(str.m_pStr, ch, str.GetLength() + 1);
}

AString::AString(const char* szStr, const AString& str)
{
	m_pStr = AllocThenCopy(szStr, str.m_pStr, SafeStrLen(szStr), str.GetLength());
}

AString::AString(const AString& str, const char* szStr)
{
	m_pStr = AllocThenCopy(str.m_pStr, szStr, str.GetLength(), SafeStrLen(szStr));
}

AString::~AString()
{
	s_STRINGDATA* pData = GetData();

	if (pData->iRefs == -1)	//	Buffer is being locked
		pData->iRefs = 1;

	FreeBuffer(pData);
	m_pStr = m_pEmptyStr;
}

AString& AString::operator = (char ch)
{
	if (!ch)
	{
		Empty();
		return *this;
	}

	s_STRINGDATA* pData = GetData();

	if (IsEmpty())
		m_pStr = AllocBuffer(1);
	else if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocBuffer(1);
	}
	else
		pData->iRefs = 1;

	m_pStr[0] = ch;
	m_pStr[1] = '\0';

	GetData()->iDataLen = 1;

	return *this;
}

AString& AString::operator = (const char* szStr)
{
	int iLen = SafeStrLen(szStr);
	if (!iLen)
	{
		Empty();
		return *this;
	}

	s_STRINGDATA* pData = GetData();

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(szStr, iLen);
	}
	else
	{
		if (iLen <= pData->iMaxLen)
		{
			StringCopy(m_pStr, szStr, iLen);
			pData->iDataLen = iLen;
		}
		else
		{
			FreeBuffer(pData);
			m_pStr = AllocThenCopy(szStr, iLen);
		}
	}

	return *this;
}

AString& AString::operator = (const AString& str)
{
	if (m_pStr == str.m_pStr)
		return *this;

	if (str.IsEmpty())
	{
		Empty();
		return *this;
	}

	s_STRINGDATA* pSrcData = str.GetData();

	if (pSrcData->iRefs == -1)	//	Source string is being locked
	{
		s_STRINGDATA* pData = GetData();

		if (pData->iRefs > 1)
		{
			pData->iRefs--;
			m_pStr = AllocThenCopy(str.m_pStr, pSrcData->iDataLen);
		}
		else
		{
			if (pSrcData->iDataLen <= pData->iMaxLen)
			{
				StringCopy(m_pStr, str.m_pStr, pSrcData->iDataLen);
				pData->iDataLen = pSrcData->iDataLen;
			}
			else
			{
				FreeBuffer(pData);
				m_pStr = AllocThenCopy(str.m_pStr, pSrcData->iDataLen);
			}
		}
	}
	else
	{
		FreeBuffer(GetData());
		pSrcData->iRefs++;
		m_pStr = str.m_pStr;
	}

	return *this;
}

const AString& AString::operator += (char ch)
{
	Append(ch);
	return *this;
}

const AString& AString::operator += (const char* szStr)
{
	Append(szStr);
	return *this;
}

const AString& AString::operator += (const AString& str)
{
	Append(str);
	return *this;
}

void AString::Append(char ch)
{
	if (!ch)
		return;

	s_STRINGDATA* pData = GetData();

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, ch, pData->iDataLen + 1);
		return;
	}

	int iLen = pData->iDataLen + 1;
	if (iLen <= pData->iMaxLen)
	{
		m_pStr[iLen - 1] = ch;
		m_pStr[iLen] = '\0';
		pData->iDataLen++;
	}
	else
	{
		m_pStr = AllocThenCopy(m_pStr, ch, iLen);
		FreeBuffer(pData);
	}
}

void AString::Append(const char* szStr)
{
	int iLen2 = SafeStrLen(szStr);
	if (!iLen2)
		return;

	s_STRINGDATA* pData = GetData();

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, szStr, pData->iDataLen, iLen2);
		return;
	}

	int iLen = pData->iDataLen + iLen2;
	if (iLen <= pData->iDataLen)
	{
		StringCopy(m_pStr + pData->iDataLen, szStr, iLen2);
		pData->iDataLen = iLen;
	}
	else
	{
		m_pStr = AllocThenCopy(m_pStr, szStr, pData->iDataLen, iLen2);
		FreeBuffer(pData);
	}
}

void AString::Append(const AString& str)
{
	int iLen2 = str.GetLength();
	if (!iLen2)
		return;

	s_STRINGDATA* pData = GetData();

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, str.m_pStr, pData->iDataLen, iLen2);
		return;
	}

	int iLen = pData->iDataLen + iLen2;
	if (iLen <= pData->iMaxLen)
	{
		StringCopy(m_pStr + pData->iDataLen, str.m_pStr, iLen2);
		pData->iDataLen = iLen;
	}
	else
	{
		m_pStr = AllocThenCopy(m_pStr, str.m_pStr, pData->iDataLen, iLen2);
		FreeBuffer(pData);
	}
}

int AString::Compare(const char* szStr) const
{
	if (m_pStr == szStr)
		return 0;

	return strcmp(m_pStr, szStr);
}

int AString::CompareNoCase(const char* szStr) const
{
	if (m_pStr == szStr)
		return 0;

	return Q_stricmp(m_pStr, szStr);
}

bool AString::operator == (const char* szStr) const
{
	//	Note: szStr's boundary may be crossed when StringEqual() do
	//		  read operation, if szStr is shorter than 'this'. Now, this
	//		  read operation won't cause problem, but in the future,
	//		  should we check the length of szStr at first, and put the
	//		  shorter one between 'this' and szStr front when we call StringEqual ?
	int iLen = GetLength();
	return StringEqual(m_pStr, szStr, iLen + 1);
}

bool AString::operator == (const AString& str) const
{
	if (m_pStr == str.m_pStr)
		return true;

	int iLen = GetLength();
	if (iLen != str.GetLength())
		return false;

	return StringEqual(m_pStr, str.m_pStr, iLen);
}

char& AString::operator [] (int n)
{
	ASSERT(n >= 0 && n <= GetLength());

	s_STRINGDATA* pData = GetData();
	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, GetLength());
	}

	return m_pStr[n];
}

//	Convert to upper case
void AString::MakeUpper()
{
	int iLen = GetLength();
	if (!iLen)
		return;

	s_STRINGDATA* pData = GetData();
	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, iLen);
	}

	Q_strupr(m_pStr);
}

//	Convert to lower case
void AString::MakeLower()
{
	int iLen = GetLength();
	if (!iLen)
		return;

	s_STRINGDATA* pData = GetData();
	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, iLen);
	}

	Q_strlwr(m_pStr);
}

//	Format string
AString& AString::Format(const char* szFormat, ...)
{
	va_list argList;
	va_start(argList, szFormat);

	int iNumWritten, iMaxLen = GetFormatLen(szFormat, argList) + 1;

	s_STRINGDATA* pData = GetData();

	if (pData->iRefs > 1)
		pData->iRefs--;
	else if (iMaxLen <= pData->iMaxLen)
	{
		vsprintf(m_pStr, szFormat, argList);
		pData->iDataLen = SafeStrLen(m_pStr);
		goto End;
	}
	else	//	iMaxLen > pData->iMaxLen
		FreeBuffer(pData);

	m_pStr = AllocBuffer(iMaxLen);
	iNumWritten = vsprintf(m_pStr, szFormat, argList);
	ASSERT(iNumWritten < iMaxLen);
	GetData()->iDataLen = SafeStrLen(m_pStr);

End:

	va_end(argList);
	return *this;
}

/*	Get buffer. If you have changed content buffer returned by GetBuffer(), you
must call ReleaseBuffer() later. Otherwise, ReleaseBuffer() isn't necessary.

Return buffer's address for success, otherwise return NULL.

iMinSize: number of bytes in string buffer user can changed.
*/
char* AString::GetBuffer(int iMinSize)
{
	if (iMinSize < 0)
	{
		ASSERT(iMinSize >= 0);
		return NULL;
	}

	//	Ensure we won't allocate an empty string when iMinSize == 1
	if (!iMinSize)
		iMinSize = 1;

	s_STRINGDATA* pData = GetData();

	if (IsEmpty())
	{
		m_pStr = AllocBuffer(iMinSize);
		m_pStr[0] = '\0';
		GetData()->iDataLen = 0;
	}
	else if (pData->iRefs > 1)
	{
		pData->iRefs--;

		if (iMinSize <= pData->iDataLen)
		{
			m_pStr = AllocThenCopy(m_pStr, pData->iDataLen);
		}
		else
		{
			char* szOld = m_pStr;
			m_pStr = AllocBuffer(iMinSize);
			StringCopy(m_pStr, szOld, pData->iDataLen);
			GetData()->iDataLen = pData->iDataLen;
		}
	}
	else if (iMinSize > pData->iMaxLen)
	{
		char* szOld = m_pStr;
		m_pStr = AllocBuffer(iMinSize);
		StringCopy(m_pStr, szOld, pData->iDataLen);
		GetData()->iDataLen = pData->iDataLen;
		FreeBuffer(pData);
	}

	return m_pStr;
}

/*	If you have changed content of buffer returned by GetBuffer(), you must call
ReleaseBuffer() later. Otherwise, ReleaseBuffer() isn't necessary.

iNewSize: new size in bytes of string. -1 means string is zero ended and it's
length can be got by strlen().
*/
void AString::ReleaseBuffer(int iNewSize/* -1 */)
{
	s_STRINGDATA* pData = GetData();
	if (pData->iRefs != 1)
	{
		ASSERT(pData->iRefs == 1);	//	Ensure GetBuffer has been called.
		return;
	}

	if (iNewSize == -1)
		iNewSize = SafeStrLen(m_pStr);

	if (iNewSize > pData->iMaxLen)
	{
		ASSERT(iNewSize <= pData->iMaxLen);
		return;
	}

	if (iNewSize == 0)
	{
		Empty();
	}
	else
	{
		pData->iDataLen = iNewSize;
		m_pStr[iNewSize] = '\0';
	}
}

/*	Make a guess at the maximum length of the resulting string.
now this function doesn't support UNICODE string.
I64 modifier used in WIN32's sprintf is now added in 2010.1.10

Return estimated length of resulting string.
*/

#define FORCE_ANSI      0x10000
#define FORCE_UNICODE   0x20000
#define FORCE_INT64     0x40000

int AString::GetFormatLen(const char* szFormat, va_list argList)
{
	if (!szFormat || !szFormat[0])
		return 0;

	char* pszTemp = NULL;
	int iMaxLen = 0, iTempBufLen = 0;

	for (const char* pch = szFormat; *pch != '\0'; pch++)
	{
		//	Handle '%' character, but watch out for '%%'
		if (*pch != '%' || *(++pch) == '%')
		{
			iMaxLen++;
			continue;
		}

		int iItemLen = 0, iWidth = 0;

		//	Handle '%' character with format
		for (; *pch != '\0'; pch++)
		{
			//	Check for valid flags
			if (*pch == '#')
				iMaxLen += 2;   // for '0x'
			else if (*pch == '*')
				iWidth = va_arg(argList, int);
			else if (*pch == '-' || *pch == '+' || *pch == '0' || *pch == ' ')
				;
			else	//	Hit non-flag character
				break;
		}

		//	Get width and skip it
		if (iWidth == 0)
		{
			//	Width indicated by digit
			iWidth = atoi(pch);
			for (; *pch != '\0' && (*pch >= '0' && *pch <= '9'); pch++)
				;
		}

		ASSERT(iWidth >= 0);

		int iPrecision = 0;

		if (*pch == '.')
		{
			//	Skip past '.' separator (width.precision)
			pch++;

			//	Get precision and skip it
			if (*pch == '*')
			{
				iPrecision = va_arg(argList, int);
				pch++;
			}
			else
			{
				iPrecision = atoi(pch);
				for (; *pch != '\0' && (*pch >= '0' && *pch <= '9'); pch++)
					;
			}

			ASSERT(iPrecision >= 0);
		}

		//	Should be on type modifier or specifier
		int nModifier = 0;
		if (strncmp(pch, "ll", 2) == 0)
		{
			//	'll' can be used on windows/linux/iOS for 64-bit int,
			//	for example: '%lld, %llx'
			pch += 2;
			nModifier = FORCE_INT64;
		}
		else if (strncmp(pch, "I64", 3) == 0)
		{
			//	'I64' is only available on windows for 64-bit int
			//	for example: '%I64d, %I64x'
			ASSERT(0 && "I64 is only supported by windows.");
			pch += 3;
			nModifier = FORCE_INT64;
		}
		else
		{
			switch (*pch)
			{
			case 'h':
			case 'l':
			case 'F':
			case 'N':
			case 'L':
				pch++;
				break;
			}
		}

		switch (*pch)
		{
		case 'c':	// Single characters
		case 'C':

			iItemLen = 2;
			va_arg(argList, int);
			break;

		case 's':	// Strings
		{
			const char* pstrNextArg = va_arg(argList, const char*);
			if (!pstrNextArg)
				iItemLen = 6;	//	"(null)"
			else
				iItemLen = pstrNextArg[0] == '\0' ? 1 : strlen(pstrNextArg);

			break;
		}
		case 'S':
		{
			const wchar_t* pstrNextArg = va_arg(argList, const wchar_t*);
			if (!pstrNextArg)
				iItemLen = 6;	//	"(null)"
			else
				iItemLen = pstrNextArg[0] == '\0' ? 1 : wcslen(pstrNextArg);

			break;
		}
		}

		//	Adjust iItemLen for strings
		if (iItemLen != 0)
		{
			if (iPrecision != 0 && iPrecision < iItemLen)
				iItemLen = iPrecision;

			if (iWidth > iItemLen)
				iItemLen = iWidth;
		}
		else
		{
			switch (*pch)
			{
			case 'd':	//	Integers
			case 'i':
			case 'u':
			case 'x':
			case 'X':
			case 'o':

				if (nModifier & FORCE_INT64)
					va_arg(argList, aint64);
				else
					va_arg(argList, int);

				iItemLen = iWidth + iPrecision > 32 ? iWidth + iPrecision : 32;
				break;

			case 'e':
			case 'g':
			case 'G':

				va_arg(argList, s_DOUBLE);	//	For _X86_
				iItemLen = iWidth + iPrecision > 128 ? iWidth + iPrecision : 128;
				break;

			case 'f':
			{
				//	312 == strlen("-1+(309 zeroes).")
				//	309 zeroes == max precision of a double
				//	6 == adjustment in case precision is not specified,
				//		 which means that the precision defaults to 6
				int iSize = 312 + iPrecision + 6;
				if (iWidth > iSize)
					iSize = iWidth;

				if (iTempBufLen < iSize)
				{
					if (!pszTemp)
						pszTemp = (char*)malloc(iSize);
					else
					{
						char* newTemp = (char*)realloc(pszTemp, iSize);
						if (newTemp)
							pszTemp = newTemp;
					}

					iTempBufLen = iSize;
				}

				double f = va_arg(argList, double);
				sprintf(pszTemp, "%*.*f", iWidth, iPrecision + 6, f);
				iItemLen = strlen(pszTemp);

				break;
			}
			case 'p':

				va_arg(argList, void*);
				iItemLen = iWidth + iPrecision > 32 ? iWidth + iPrecision : 32;
				break;

				//	No output
			case 'n':

				va_arg(argList, int*);
				break;

			default:

				ASSERT(0);  //	Unknown formatting option
				break;
			}
		}

		//	Adjust iMaxLen for output iItemLen
		iMaxLen += iItemLen;
	}

	if (pszTemp)
		free(pszTemp);

	return iMaxLen;
}

//	Cut left sub string
void AString::CutLeft(int n)
{
	if (!GetLength() || n <= 0)
		return;

	s_STRINGDATA* pData = GetData();

	if (n >= pData->iDataLen)
	{
		Empty();
		return;
	}

	int iNewLen = pData->iDataLen - n;

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr + n, iNewLen);
		return;
	}

	for (int i = 0; i < iNewLen; i++)
		m_pStr[i] = m_pStr[n + i];

	m_pStr[iNewLen] = '\0';
	pData->iDataLen = iNewLen;
}

//	Cut right sub string
void AString::CutRight(int n)
{
	if (!GetLength() || n <= 0)
		return;

	s_STRINGDATA* pData = GetData();

	if (n >= pData->iDataLen)
	{
		Empty();
		return;
	}

	int iNewLen = pData->iDataLen - n;

	if (pData->iRefs > 1)
	{
		pData->iRefs--;
		m_pStr = AllocThenCopy(m_pStr, iNewLen);
		return;
	}

	m_pStr[iNewLen] = '\0';
	pData->iDataLen = iNewLen;
}

void AString::Split(char split, std::vector<AString>& retVString) const
{
	retVString.clear();

	char* str = new char[GetLength() + 1];
	ASSERT(str);
	strcpy(str, m_pStr);

	char* pchStart = str;
	char* pch = NULL;
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

void AString::Split(const char *split, std::vector<AString>& retVString) const
{
	retVString.clear();

	char* str = new char[GetLength() + 1];
	ASSERT(str);
	strcpy(str, m_pStr);

	char* pchStart = str;
	char* pch = NULL;
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

//	Trim left
void AString::TrimLeft()
{
	if (!GetLength())
		return;

	int i;
	unsigned char* aStr = (unsigned char*)m_pStr;

	for (i = 0; aStr[i]; i++)
	{
		if (aStr[i] > 32)
			break;
	}

	CutLeft(i);
}

//	Trim left
void AString::TrimLeft(char ch)
{
	if (!GetLength())
		return;

	int i;

	for (i = 0; m_pStr[i]; i++)
	{
		if (m_pStr[i] != ch)
			break;
	}

	CutLeft(i);
}

//	Trim left
void AString::TrimLeft(const char* szChars)
{
	if (!GetLength())
		return;

	int i, j;

	for (i = 0; m_pStr[i]; i++)
	{
		for (j = 0; szChars[j]; j++)
		{
			if (m_pStr[i] == szChars[j])
				break;
		}

		if (!szChars[j])
			break;
	}

	CutLeft(i);
}

//	Trim right
void AString::TrimRight()
{
	if (!GetLength())
		return;

	int i, iLen = GetLength();
	unsigned char* aStr = (unsigned char*)m_pStr;

	for (i = iLen - 1; i >= 0; i--)
	{
		if (aStr[i] > 32)
			break;
	}

	CutRight(iLen - 1 - i);
}

//	Trim right
void AString::TrimRight(char ch)
{
	if (!GetLength())
		return;

	int i, iLen = GetLength();

	for (i = iLen - 1; i >= 0; i--)
	{
		if (m_pStr[i] != ch)
			break;
	}

	CutRight(iLen - 1 - i);
}

//	Trim right
void AString::TrimRight(const char* szChars)
{
	if (!GetLength())
		return;

	int i, j, iLen = GetLength();

	for (i = iLen - 1; i >= 0; i--)
	{
		for (j = 0; szChars[j]; j++)
		{
			if (m_pStr[i] == szChars[j])
				break;
		}

		if (!szChars[j])
			break;
	}

	CutRight(iLen - 1 - i);
}

//	Finds a character inside a larger string.
//	Return -1 for failure.
int AString::Find(char ch, int iStart/* 0 */) const
{
	int iLen = GetLength();
	if (!iLen || iStart < 0 || iStart >= iLen)
		return -1;

	for (int i = iStart; i < iLen; i++)
	{
		if (m_pStr[i] == ch)
			return i;
	}

	return -1;
}

//	Finds a substring inside a larger string.
//	Return -1 for failure.
int AString::Find(const char* szSub, int iStart/* 0 */) const
{
	int iLen = GetLength();
	if (!iLen || iStart < 0 || iStart >= iLen)
		return -1;

	char* pTemp = strstr(m_pStr + iStart, szSub);
	if (!pTemp)
		return -1;

	return pTemp - m_pStr;
}

//	Finds a character inside a larger string; starts from the end.
//	Return -1 for failure.
int AString::ReverseFind(char ch) const
{
	if (!GetLength())
		return -1;

	char* pTemp = strrchr(m_pStr, ch);
	if (!pTemp)
		return -1;

	return pTemp - m_pStr;
}

//	Finds the first matching character from a set.
//	Return -1 for failure.
int AString::FindOneOf(const char* szCharSet) const
{
	int iLen = GetLength();
	if (!iLen)
		return -1;

	return ((int)strcspn(m_pStr, szCharSet) == iLen) ? -1 : 0;
}

AString& AString::Replace(const char* szFrom, const char* szTo)
{
	AString* Result = (AString*)this;
	int fromlen = strlen(szFrom);
	int i = Result->Find(szFrom);
	while (i != -1)
	{
		*Result = Result->Left(i) + AString(szTo) + Result->Mid(i + fromlen);
		i = Result->Find(szFrom);
	}

	return *this;
}

AString& AString::Replace(const char cFrom, const char cTo)
{
	AString* Result = (AString*)this;
	int iLen = GetLength();
	if (!iLen)
		return *this;

	for (int i = 0; i < iLen; i++)
	{
		if (m_pStr[i] == cFrom)
			m_pStr[i] = cTo;
	}

	return *this;
}

aint64 AString::ToInt64() const
{
	//	return IsEmpty() ? 0 : _atoi64(m_pStr);
	//add by linzihan xos have not _atoi64
	return IsEmpty() ? 0 : Q_atoi64(m_pStr);
}

bool AString::IsNumeric(const char* szStr)
{
	//is negative?
	if (*szStr == '-')
	{
		szStr++;
	}

	bool bDot = false;
	for (aint32 i = 0; szStr[i]; i++)
	{
		if (!isdigit(szStr[i]))
		{
			if ((szStr[i] == '.') && !bDot)
			{
				bDot = true;
				continue;
			}
			return false;
		}
	}

	return true;
}

aint32	AString::FindChar(const char* szStr, char c)
{
	aint32 nLen = strlen(szStr) - 1;
	for (aint32 i = 0; i <= nLen; i++)
	{
		if (szStr[i] == c)
		{
			return i;
		}
	}
	return -1;
}

void AString::NormalizeFileName()
{
	int len = GetLength();
	for (int i = 0; i < len; ++i)
	{
		if (m_pStr[i] == '\\')
			m_pStr[i] = '/';
	}
}

void AString::NormalizeDirName()
{
	int len = GetLength();
	for (int i = 0; i < len; ++i)
	{
		if (m_pStr[i] == '\\')
			m_pStr[i] = '/';
	}

	if (len > 0)
	{
		char last = m_pStr[len - 1];
		if (last != '/' && last != '\\')
			Append('/');
	}
}