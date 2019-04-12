#include "FileOperate.h"
#include "ASys.h"
#include "CMd5Hash.h"
#include "function.h"
#include <errno.h>

#ifdef A_PLATFORM_WIN_DESKTOP
#include <io.h>
#else
#include <dirent.h>
#endif

namespace FileOperate
{
	void MakeDir(const char* dir, int r)
	{
		r--;
		while (r > 0 && dir[r] != '/'&&dir[r] != '\\')
			r--;
		if (r == 0)
			return;
		MakeDir(dir, r);
		char t[400];
		strcpy(t, dir);
		t[r] = '\0';
		ASys::CreateDirectory(t);
	}

	void MakeDir(const char* dir)
	{
		MakeDir(dir, int(strlen(dir)));
	}

	bool DeleteDir(const char* dir)
	{
		return ASys::DeleteDirectory(dir);
	}

	FILE* OpenFile(const char* name, const char* param)
	{
		return fopen(name, param);
	}

	bool ReadFromFile(const char* fileName, char** ppBuffer/*out*/, size_t* pDataSize/*out*/, bool bTextMode/*=false*/)
	{
		*ppBuffer = NULL;
		*pDataSize = 0;

		// read file
		FILE* fin = fopen(fileName, "rb");
		if (fin == NULL)
			return false;

		fseek(fin, 0, SEEK_END);
		long fileLen = ftell(fin);
		fseek(fin, 0, SEEK_SET);
		char* readBuffer = new char[fileLen];
		fread(readBuffer, 1, fileLen, fin);

		fclose(fin);

		*ppBuffer = readBuffer;
		*pDataSize = fileLen;
		return true;
	}

	bool WriteToFile(const char* fileName, const unsigned char* pData, size_t dataSize, bool bTextMode/*=false*/)
	{
		FILE* fout;
		if (bTextMode)
			fout = fopen(fileName, "w");
		else
			fout = fopen(fileName, "wb");
		if (!fout)
			return false;

		fwrite(pData, 1, dataSize, fout);

		fclose(fout);

		return true;
	}

	bool UCopyFile(const char* src, const char* des, bool bFailIfExists)
	{
		ASys::ChangeFileAttributes(des, S_IRWXU);
		if (!ASys::CopyFile(src, des, bFailIfExists))
			return false;

		ASys::ChangeFileAttributes(des, S_IRWXU);
		return true;
	}

	void UDeleteFile(const char* src)
	{
		ASys::ChangeFileAttributes(src, S_IRWXU);
		ASys::DeleteFile(src);
	}

	auint32 GetFileSize(const char* lFileName)
	{
		return ASys::GetFileSize(lFileName);
	}

	std::string GetFileName(const char *tPath)
	{
		std::string c = "";
		int i = (int)strlen(tPath) - 1;
		while (i >= 0 && tPath[i] != '/' &&tPath[i] != '\\')
			i--;
		for (int j = 0; j < (int)(strlen(tPath)) - i - 1; j++)
			if (tPath[i + j + 1] >= 'A' &&tPath[i + j + 1] <= 'Z')
				c += (char)(tPath[i + j + 1] + 32);
			else
				c += tPath[i + j + 1];
		return c;
	}

	bool FileExist(const char* src)
	{
		return ASys::IsFileExist(src);
	}

	namespace
	{
		const int FileSizeOnDraw = 4096;
	}

	bool CalcFileMd5(const char* lName, char md5[64])
	{
		CMd5Hash m;
		unsigned char buf[FileSizeOnDraw + 1];
		unsigned char outbuf[16];
		FILE* f = OpenFile(lName, "rb");
		if (f != NULL)
		{
			int nRead;
			auint32 iReadSize = 0;
			do
			{
				nRead = (int)fread(buf, sizeof(char), FileSizeOnDraw, f);
				m.update(buf, nRead);
				iReadSize += nRead;
			} while (nRead == FileSizeOnDraw);

			fclose(f);
		}
		else
		{
			md5[0] = 0;
			return true;
		}

		auint32 i = 64;
		m.final(outbuf);
		m.getString(outbuf, md5, i);
		return true;
	}

	bool CalcMemMd5(const unsigned char* buf, int size, char md5[64])
	{
		CMd5Hash m;
		int pos = 0;
		unsigned char outbuf[16];
		while (pos + FileSizeOnDraw < size)
		{
			m.update(buf + pos, FileSizeOnDraw);
			pos += FileSizeOnDraw;
		}
		if (pos < size)
			m.update(buf + pos, size - pos);
		m.final(outbuf);
		auint32 i = 64;
		m.getString(outbuf, md5, i);
		return true;
	}

	int Md5Cmp(const char* md5, const char* md5Trunc)
	{
		int md5Len = int(strlen(md5));
		int truncLen = int(strlen(md5Trunc));

		if (md5Len >= truncLen)
			return Q_stricmp(md5 + (md5Len - truncLen), md5Trunc);
		else
			return -1;
	}

	bool GetSubDirectories(const char* dirName, std::vector<std::string>& subDirs)
	{
		std::string strDir = dirName;
		normalizeDirName(strDir);
		strDir += "*.*";

#ifdef A_PLATFORM_WIN_DESKTOP
		_finddata_t finddata;
		intptr_t hfile = _findfirst(strDir.c_str(), &finddata);
		if (hfile == -1)
			return false;

		subDirs.clear();
		do
		{
			if (strcmp(finddata.name, "..") == 0 || strcmp(finddata.name, ".") == 0)
				continue;

			if (finddata.attrib & (_A_HIDDEN | _A_SYSTEM))
				continue;

			if (finddata.attrib & _A_SUBDIR)		//dirname
			{
				subDirs.push_back(finddata.name);
			}
		} while (_findnext(hfile, &finddata) != -1);

		if (errno != ENOENT)
		{
			_findclose(hfile);
			return false;
		}

		_findclose(hfile);
		return true;
#else
		DIR* handle = opendir(strDir.c_str());
		if (NULL == handle)
		{
			perror("directory::open");
			return false;
		}

		while (dirent* pdata = readdir(handle))
		{
			if (strcmp(pdata->d_name, "..") == 0 || strcmp(pdata->d_name, ".") == 0)
				continue;

			if (pdata->d_name[0] == 0)
				continue;

			char subpath[QMAX_PATH];
			Q_strcpy(subpath, QMAX_PATH, dirName);
			normalizeDirName(subpath);
			Q_strcat(subpath, QMAX_PATH, pdata->d_name);

			//»ñÈ¡file state
			struct stat buf;
			if (0 != stat(subpath, &buf))
			{
				perror("stat() failed");
				closedir(handle);
				return false;
			}

			if (S_ISDIR(buf.st_mode))
			{
				subDirs.push_back(pdata->d_name);
			}
		}

		closedir(handle);
		return true;
#endif
	}
};