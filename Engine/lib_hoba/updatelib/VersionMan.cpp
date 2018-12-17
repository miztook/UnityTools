#include "VersionMan.h"
#include "function.h"

const char* g_incHeader = "# %d.%d.%d.%d %d.%d.%d.%d %s %lld";

ELEMENT_VER operator- (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2)
{
	ELEMENT_VER tmp;
	tmp.iVer0 = ver1.iVer0 - ver2.iVer0;
	tmp.iVer1 = ver1.iVer1 - ver2.iVer1;
	tmp.iVer2 = ver1.iVer2 - ver2.iVer2;
	tmp.iVer3 = ver1.iVer3 - ver2.iVer3;
	return tmp;
}

bool operator== (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2)
{
	if (ver1.iVer0 == ver2.iVer0 && ver1.iVer1 == ver2.iVer1 && ver1.iVer2 == ver2.iVer2 && ver1.iVer3 == ver2.iVer3)
		return true;
	return false;
}

bool operator!= (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2)
{
	if (ver1.iVer0 != ver2.iVer0 || ver1.iVer1 != ver2.iVer1 || ver1.iVer2 != ver2.iVer2 || ver1.iVer3 != ver2.iVer3)
		return true;
	return false;
}

bool operator< (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2)
{
	if (ver1.iVer0 < ver2.iVer0)
		return true;

	if (ver1.iVer0 == ver2.iVer0)
	{
		if (ver1.iVer1 < ver2.iVer1)
			return true;

		if (ver1.iVer1 == ver2.iVer1)
		{
			if (ver1.iVer2 < ver2.iVer2)
				return true;

			if (ver1.iVer2 == ver2.iVer2)
			{
				if (ver1.iVer3 < ver2.iVer3)
					return true;
			}
		}
	}

	return false;
}

bool operator>(const ELEMENT_VER& ver1, const ELEMENT_VER& ver2)
{
	if (ver1.iVer0 > ver2.iVer0)
		return true;

	if (ver1.iVer0 == ver2.iVer0)
	{
		if (ver1.iVer1 > ver2.iVer1)
			return true;

		if (ver1.iVer1 == ver2.iVer1)
		{
			if (ver1.iVer2 > ver2.iVer2)
				return true;

			if (ver1.iVer2 == ver2.iVer2)
			{
				if (ver1.iVer3 > ver2.iVer3)
					return true;
			}
		}
	}

	return false;
}

VersionMan::VersionMan()
{
	m_bLoaded = false;
}

VersionMan::~VersionMan()
{
}

bool VersionMan::LoadVersions(FILE* fStream)
{
	m_bLoaded = false;

	if (!fStream)
		return false;

	static int const BUFFER_SIZE = 1024;
	char szBuf[BUFFER_SIZE];

	bool success = false;
	const char* split = " \t";

	//第一行
	{
		//	Read the first line: VerLatest/VerSeparate
		//  Version:	1.0.1.0/1.0.0.0
		if (!fgets(szBuf, BUFFER_SIZE, fStream))
			return false;
		
		std::vector<std::string> arr;
		std::string str = szBuf;
		std_string_split(str, split, arr);
		if (arr.size() >= 2 && arr[0] == "Version:")
		{
			std::vector<std::string> arr1;
			std_string_split(arr[1], '/', arr1);
			success = (arr1.size() >= 2 && m_VerLatest.Parse(arr1[0]) && m_VerSeparate.Parse(arr1[1]));
			if (!success)
			{
				ASSERT(false);
				return false;
			}
		}
		else
		{
			ASSERT(false);
			return false;
		}
	}

	//第二行
	{
		//	Read the second line: Project string
		if (!fgets(szBuf, BUFFER_SIZE, fStream))
			return false;

		std::vector<std::string> arr;
		std::string str = szBuf;
		std_string_split(str, split, arr);
		if (arr.size() >= 2 && arr[0] == "Project:")
		{
			m_projectName = arr[1];
		}
		else
		{
			ASSERT(false);
			return false;
		}
	}

	//后续版本
	//1.0.0.0-1.0.1.0	297E9DD6EC4CC92C409295C4B89BBAC2 33697
	{
		//	Read the following version pairs or patch version pairs
		m_VersionPairs.clear();
		//m_patcherVerPairs.clear();

		while (fgets(szBuf, BUFFER_SIZE, fStream))
		{
			std::string str = szBuf;

			std::vector<std::string> arr;
			std_string_split(str, split, arr);
			if (arr.size() < 3)
				continue;

			std::vector<std::string> arr1;
			std_string_split(arr[0], '-', arr1);
			if (arr1.size() < 2)
				continue;
			
			VER_PAIR tmpPair;
			success = tmpPair.VerFrom.Parse(arr1[0]) && tmpPair.VerTo.Parse(arr1[1]);
			if (!success)
				continue;

			strcpy(tmpPair.md5, arr[1].c_str());
			
			uint32_t size;
			sscanf(arr[2].c_str(), "%u", &size);
			tmpPair.size = size;

			m_VersionPairs.push_back(tmpPair);
		}
	}

	m_bLoaded = true;
	return true;
}

const VER_PAIR* VersionMan::FindVersionPair(const ELEMENT_VER& curVer) const
{
	if (m_VersionPairs.empty() || curVer == m_VerLatest || curVer > m_VerLatest || curVer < m_VerSeparate)
		return NULL;

	ELEMENT_VER verOld(-1, 0, 0, 0);
	for (const auto& vpair : m_VersionPairs)
	{
		const ELEMENT_VER& verFrom = vpair.VerFrom;
		if (verFrom == curVer)
		{
			verOld = verFrom;
			break;
		}
		else if (verFrom < curVer && verFrom > verOld)
			verOld = verFrom;
	}
	if (verOld.iVer0 < 0)
		return NULL;		// not found

	int iVer = -1;
	ELEMENT_VER verNew(-1, 0, 0, 0);
	for (size_t i = 0; i < m_VersionPairs.size(); i++)
	{
		if (m_VersionPairs[i].VerFrom != verOld)
			continue;

		const ELEMENT_VER& verTo = m_VersionPairs[i].VerTo;
		if (verTo > verNew)
		{
			iVer = static_cast<int>(i);
			verNew = verTo;
		}
	}

	if (iVer >= 0)
	{
		assert(curVer < m_VersionPairs[iVer].VerTo);
		return &m_VersionPairs[iVer];
	}
	else
	{
		assert(0);
		return NULL;
	}
}

int VersionMan::CalcSize(const ELEMENT_VER& verFrom, const ELEMENT_VER& verTo) const
{
	if (!(verFrom < verTo))
		return 0;

	const VER_PAIR* pNextPair = FindVersionPair(verFrom);
	if (!pNextPair)
		return -1;

	int sizeOverAll = pNextPair->size;
	while (verTo > pNextPair->VerTo && (pNextPair = FindVersionPair(pNextPair->VerTo)))
		sizeOverAll += pNextPair->size;
	return sizeOverAll;
}