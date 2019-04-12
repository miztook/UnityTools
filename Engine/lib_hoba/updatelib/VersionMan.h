#pragma once

#include "stringext.h"
#include <stdio.h>
#include <stdlib.h>
#include <vector>

extern const char* g_incHeader;

struct ELEMENT_VER
{
	union
	{
		struct
		{
			int iVer0;
			int iVer1;
			int iVer2;
			int iVer3;
		};

		int aVerNum[4];
	};

	ELEMENT_VER() { Clear(); }
	//ELEMENT_VER(int ver0, int ver1, int ver2) { Set(ver0, ver1, ver2, 0); }
	ELEMENT_VER(int ver0, int ver1, int ver2, int ver3) { Set(ver0, ver1, ver2, ver3); }

	friend ELEMENT_VER operator- (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2);
	friend bool operator== (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2);
	friend bool operator!= (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2);
	friend bool operator< (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2);
	friend bool operator> (const ELEMENT_VER& ver1, const ELEMENT_VER& ver2);

	void Clear() { memset(aVerNum, 0, sizeof(aVerNum)); }
	bool IsValid() const { return iVer0 >= 0 && iVer1 >= 0 && iVer2 >= 0 && iVer3 >= 0; }

	/*
	void Set(int ver0, int ver1, int ver2)
	{
		iVer0 = ver0;
		iVer1 = ver1;
		iVer2 = ver2;
		iVer3 = 0;
	}
	*/

	void Set(int ver0, int ver1, int ver2, int ver3)
	{
		iVer0 = ver0;
		iVer1 = ver1;
		iVer2 = ver2;
		iVer3 = ver3;
	}

	//void ToShortString(AString& str) const { str.Format("%d.%d.%d", iVer0, iVer1, iVer2); }
	void ToString(std::string& str) const { std_string_format(str, "%d.%d.%d.%d", iVer0, iVer1, iVer2, iVer3); }
	bool Parse(const std::string& str)
	{
		std::vector<std::string> arr;
		std_string_split(str, ".", arr);
		if (arr.size() == 3)
		{
			iVer0 = atoi(arr[0].c_str());
			iVer1 = atoi(arr[1].c_str());
			iVer2 = atoi(arr[2].c_str());
			iVer3 = 0;
		}
		else if (arr.size() == 4)
		{
			iVer0 = atoi(arr[0].c_str());
			iVer1 = atoi(arr[1].c_str());
			iVer2 = atoi(arr[2].c_str());
			iVer3 = atoi(arr[3].c_str());
		}
		else
		{
			return false;
		}
		return true;
	}
};

typedef struct
{
	ELEMENT_VER VerFrom;
	ELEMENT_VER VerTo;
	char md5[256];		// md5 of the patch file (could be truncated)
	unsigned size;	// x*10 + 5
} VER_PAIR;

class VersionMan
{
public:
	VersionMan();
	~VersionMan();

public:
	bool IsLoaded() { return m_bLoaded; }

	bool LoadVersions(FILE* fStream);

	const char* GetProjectName() const { return m_projectName.c_str(); }
	const ELEMENT_VER& GetLatestVer() const { return m_VerLatest; }
	const ELEMENT_VER& GetSeparateVer() const { return m_VerSeparate; }
	bool CanAutoUpdate(const ELEMENT_VER& ver) const { return m_VerSeparate < ver; }
	const VER_PAIR* FindVersionPair(const ELEMENT_VER& curVer) const;

	int CalcSize(const ELEMENT_VER& verFrom, const ELEMENT_VER& verTo) const;

private:
	std::string m_projectName;
	ELEMENT_VER m_VerLatest;
	ELEMENT_VER m_VerSeparate;

	bool m_bLoaded;
	std::vector<VER_PAIR> m_VersionPairs;
};