#include "AFile.h"
#include "AFI.h"
#include "ATempMemBuffer.h"

AFile::AFile()
{
	m_szFileName[0] = '\0';
	m_szRelativeName[0] = '\0';

	m_pFile = NULL;
	m_dwFlags = 0;
	m_dwTimeStamp = 0;
	m_dwLength = 0;

	m_bHasOpened = false;
}

AFile::~AFile()
{
	Close();
}

bool AFile::Open(const char* szFolderName, const char* szFileName, auint32 dwFlags)
{
	char szFullPath[QMAX_PATH];
	af_GetFullPath(szFullPath, szFolderName, szFileName);
	return Open(szFullPath, dwFlags);
}

bool AFile::Open(const char* szFullPath, auint32 dwFlags)
{
	// If already opened, we must first close it!
	if (m_bHasOpened)
		Close();

	// Get a relative path name of this file, may use a little time, but
	// this call is not too often, so this is not matter
	af_GetRelativePath(szFullPath, m_szRelativeName);

	char szOpenFlag[32];

	szOpenFlag[0] = '\0';
	if (dwFlags & AFILE_OPENEXIST)
		strcat(szOpenFlag, "r");

	if (dwFlags & AFILE_CREATENEW)
		strcat(szOpenFlag, "w");

	if (dwFlags & AFILE_OPENAPPEND)
		strcat(szOpenFlag, "a");

	//If there is no binary or text flag, the default is binary;
	if (dwFlags & AFILE_TEXT)
		strcat(szOpenFlag, "t");
	else
		strcat(szOpenFlag, "b");

	//读取library 文件夹下是否有分离文件
	char temp[QMAX_PATH];
	strcpy(temp, m_szRelativeName);
	AString strpath(temp);
	strpath.NormalizeFileName();

	char pathfile[QMAX_PATH];
	//判断是否为空
	if (*af_GetLibraryDir() != '\0')
	{
		af_GetFullPathNoBase(pathfile, af_GetLibraryDir(), (const char*)strpath);
		m_pFile = fopen(pathfile, szOpenFlag);
		if (NULL == m_pFile)
		{
			//读取app bundle 是否有分离文件
			af_GetFullPathNoBase(pathfile, af_GetBaseDir(), (const char*)strpath);
			m_pFile = fopen(pathfile, szOpenFlag);
			if (NULL == m_pFile)
				return false;
		}
	}
	else
	{
		//读取app bundle 是否有分离文件
		af_GetFullPathNoBase(pathfile, af_GetBaseDir(), (const char*)strpath);
		m_pFile = fopen(pathfile, szOpenFlag);
		if (NULL == m_pFile)
		{
			return false;
		}
	}

	strncpy(m_szFileName, pathfile, QMAX_PATH);
	auint32 dwFOURCC;

	if (dwFlags & AFILE_CREATENEW)	//	Create new file
	{
		m_dwFlags = dwFlags;
		if (m_dwFlags & AFILE_TEXT)
		{
			dwFOURCC = 0x54584f4d;
			if (!(m_dwFlags & AFILE_NOHEAD))
				fwrite(&dwFOURCC, 4, 1, m_pFile);
		}
		else
		{
			dwFOURCC = 0x42584f4d;
			if (!(m_dwFlags & AFILE_NOHEAD))
				fwrite(&dwFOURCC, 4, 1, m_pFile);
		}
	}
	else	//	Open a normal file
	{
		m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));

		fread(&dwFOURCC, 4, 1, m_pFile);
		if (dwFOURCC == 0x42584f4d)
			m_dwFlags |= AFILE_BINARY;
		else if (dwFOURCC == 0x54584f4d)
			m_dwFlags |= AFILE_TEXT;
		else
		{
			//Default we use text mode, for we can edit it by hand, and we will not add
			//the shitting FOURCC at the beginning of the file
			//m_dwFlags |= AFILE_TEXT;
			fseek(m_pFile, 0, SEEK_SET);
		}
	}

	//	int idFile = _fileno(m_pFile);
	//	struct _stat fileStat;
	//	_fstat(idFile, &fileStat);
	//	m_dwTimeStamp = (auint32)fileStat.st_mtime;

	m_dwLength = _GetFileLength();

	m_dwTimeStamp = ASys::GetFileTimeStamp(szFullPath);
	m_bHasOpened = true;
	return true;
}

bool AFile::OpenWithAbsFullPath(const char* szFullPath, auint32 dwFlags)
{
	// If already opened, we must first close it!
	if (m_bHasOpened)
		Close();

	char szOpenFlag[32];

	szOpenFlag[0] = '\0';
	if (dwFlags & AFILE_OPENEXIST)
		strcat(szOpenFlag, "r");

	if (dwFlags & AFILE_CREATENEW)
		strcat(szOpenFlag, "w");

	if (dwFlags & AFILE_OPENAPPEND)
		strcat(szOpenFlag, "a");

	//If there is no binary or text flag, the default is binary;
	if (dwFlags & AFILE_TEXT)
		strcat(szOpenFlag, "t");
	else
		strcat(szOpenFlag, "b");

	//读取library 文件夹下是否有分离文件
	AString strpath(szFullPath);
	strpath.NormalizeFileName();
	//判断是否为空

	m_pFile = fopen((const char*)strpath, szOpenFlag);
	if (NULL == m_pFile)
	{
		return false;
	}

	strncpy(m_szFileName, szFullPath, QMAX_PATH);
	auint32 dwFOURCC;

	if (dwFlags & AFILE_CREATENEW)	//	Create new file
	{
		m_dwFlags = dwFlags;
		if (m_dwFlags & AFILE_TEXT)
		{
			dwFOURCC = 0x54584f4d;
			if (!(m_dwFlags & AFILE_NOHEAD))
				fwrite(&dwFOURCC, 4, 1, m_pFile);
		}
		else
		{
			dwFOURCC = 0x42584f4d;
			if (!(m_dwFlags & AFILE_NOHEAD))
				fwrite(&dwFOURCC, 4, 1, m_pFile);
		}
	}
	else	//	Open a normal file
	{
		m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));

		fread(&dwFOURCC, 4, 1, m_pFile);
		if (dwFOURCC == 0x42584f4d)
			m_dwFlags |= AFILE_BINARY;
		else if (dwFOURCC == 0x54584f4d)
			m_dwFlags |= AFILE_TEXT;
		else
		{
			//Default we use text mode, for we can edit it by hand, and we will not add
			//the shitting FOURCC at the beginning of the file
			//m_dwFlags |= AFILE_TEXT;
			fseek(m_pFile, 0, SEEK_SET);
		}
	}

	//	int idFile = _fileno(m_pFile);
	//	struct _stat fileStat;
	//	_fstat(idFile, &fileStat);
	//	m_dwTimeStamp = (auint32)fileStat.st_mtime;

	m_dwTimeStamp = ASys::GetFileTimeStamp(szFullPath);
	m_bHasOpened = true;
	return true;
}

bool AFile::Close()
{
	if (m_pFile)
	{
		fclose(m_pFile);
		m_pFile = NULL;
	}

	m_bHasOpened = false;
	return true;
}

bool AFile::Read(void* pBuffer, auint32 dwBufferLength, auint32 * pReadLength)
{
	*pReadLength = fread(pBuffer, 1, dwBufferLength, m_pFile);
	return true;
}

bool AFile::Write(const void* pBuffer, auint32 dwBufferLength, auint32 * pWriteLength)
{
	*pWriteLength = fwrite(pBuffer, 1, dwBufferLength, m_pFile);
	return true;
}

bool AFile::ReadLine(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength)
{
	if (!fgets(szLineBuffer, dwBufferLength, m_pFile))
		return false;

	//chop the \n\r
	if (szLineBuffer[0] && (szLineBuffer[strlen(szLineBuffer) - 1] == '\n' || szLineBuffer[strlen(szLineBuffer) - 1] == '\r'))
		szLineBuffer[strlen(szLineBuffer) - 1] = '\0';

	if (szLineBuffer[0] && (szLineBuffer[strlen(szLineBuffer) - 1] == '\n' || szLineBuffer[strlen(szLineBuffer) - 1] == '\r'))
		szLineBuffer[strlen(szLineBuffer) - 1] = '\0';

	*pdwReadLength = strlen(szLineBuffer) + 1;
	return true;
}

bool AFile::ReadString(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength)
{
	char ch;
	auint32 nStrLen = 0;

	fread(&ch, 1, 1, m_pFile);
	while (ch)
	{
		szLineBuffer[nStrLen] = ch;
		nStrLen++;

		if (nStrLen >= dwBufferLength)
			return false;

		fread(&ch, 1, 1, m_pFile);
	}

	szLineBuffer[nStrLen] = '\0';

	*pdwReadLength = nStrLen + 1;
	return true;
}

bool AFile::WriteString(const AString& str)
{
	//	Only binary file is supported
	/*	if (m_dwFlags & AFILE_TEXT)
		{
		ASSERT(!(m_dwFlags & AFILE_TEXT));
		return false;
		}
		*/
	//	Write length of string
	int iLen = str.GetLength();
	fwrite(&iLen, 1, sizeof(int), m_pFile);

	//	Write string data
	if (iLen)
		fwrite((const char*)str, 1, iLen, m_pFile);

	return true;
}

bool AFile::ReadString(AString& str)
{
	//	Only binary file is supported
	/*	if (m_dwFlags & AFILE_TEXT)
		{
		ASSERT(!(m_dwFlags & AFILE_TEXT));
		return false;
		}
		*/
	//	Read length of string
	int iLen;
	fread(&iLen, 1, sizeof(int), m_pFile);

	//	Read string data
	if (iLen)
	{
		ATempMemBuffer tempBuf(sizeof(char) * (iLen + 1));
		char* szBuf = (char*)tempBuf.GetBuffer();
		if (!szBuf)
			return false;

		fread(szBuf, 1, iLen, m_pFile);
		szBuf[iLen] = '\0';
		str = szBuf;
	}
	else
		str = "";

	return true;
}

bool AFile::WriteLine(const char* szLineBuffer)
{
	if (fprintf(m_pFile, "%s\n", szLineBuffer) < 0)
		return false;
	return true;
}

auint32 AFile::GetPos() const
{
	auint32 dwPos;

	dwPos = (auint32)ftell(m_pFile);

	return dwPos;
}

bool AFile::Seek(int iOffset, AFILE_SEEK origin)
{
	int iStart = SEEK_SET;

	switch (origin)
	{
	case AFILE_SEEK_SET:	iStart = SEEK_SET;	break;
	case AFILE_SEEK_CUR:	iStart = SEEK_CUR;	break;
	case AFILE_SEEK_END:	iStart = SEEK_END;	break;
	default:
	{
		ASSERT(0);
		return false;
	}
	}

	if (0 != fseek(m_pFile, iOffset, iStart))
		return false;

	return true;
}

bool AFile::ResetPointer()
{
	fseek(m_pFile, 0, SEEK_SET);
	return true;
}

//	Get file length
auint32 AFile::_GetFileLength() const
{
	ASSERT(m_pFile);

	auint32 dwPos, dwEnd;

	dwPos = ftell(m_pFile);
	fseek(m_pFile, 0, SEEK_END);
	dwEnd = ftell(m_pFile);
	fseek(m_pFile, dwPos, SEEK_SET);

	return dwEnd;
}

bool AFile::Flush()
{
	fflush(m_pFile);
	return true;
}