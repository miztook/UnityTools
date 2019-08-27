#pragma once

#include <vector>
#include "VersionMan.h"
#include <set>
#include <string>

struct SJupFileEntry			  //jupÎÄ¼þ
{
	ELEMENT_VER vOld;
	ELEMENT_VER vNew;

	bool operator<(const SJupFileEntry& rhs) const {
		if (vOld != rhs.vOld)
			return vOld < rhs.vOld;
		else
			return vNew < rhs.vNew;
	}

	std::string ToJupFileName() const
	{
		return std_string_format("%s-%s.jup",
			vOld.ToString().c_str(),
			vNew.ToString().c_str());
	}
};