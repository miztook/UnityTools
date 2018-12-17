#pragma once

#include <stdio.h>
#include <string>
#include <vector>
#include "ATypes.h"
#include "stringext.h"

namespace FileOperate
{
	void MakeDir(const char* dir, int r);
	void MakeDir(const char* dir);
	bool DeleteDir(const char* dir);

	FILE* OpenFile(const char* name, const char* param);
	bool ReadFromFile(const char* fileName, char** ppBuffer/*out*/, size_t* pDataSize/*out*/, bool bTextMode = false);
	bool WriteToFile(const char* fileName, const unsigned char* pData, size_t dataSize, bool bTextMode = false);
	bool UCopyFile(const char* src, const char* des, bool bFailIfExists);
	void UDeleteFile(const char* src);
	auint32 GetFileSize(const char* lFileName);
	std::string GetFileName(const char* tPath);
	bool FileExist(const char* src);

	bool CalcFileMd5(const char* lName, char md5[64]);
	bool CalcMemMd5(const unsigned char* buf, int size, char md5[64]);
	int Md5Cmp(const char* md5, const char* md5Trunc);

	bool GetSubDirectories(const char* dirName, std::vector<std::string>& subDirs);
};