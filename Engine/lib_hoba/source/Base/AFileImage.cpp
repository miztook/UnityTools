#include "AFileImage.h"
#include "AFI.h"
#include "AFilePackage.h"
#include "ASys.h"
#include "AFramework.h"
#include "ATempMemBuffer.h"
#include "AFilePackMan.h"

//	Write data to package
bool AFileImage::WriteToPack(const char* szFile, const void* pBuf, auint32 dwBufLen, bool bReplaceOnly)
{
	//char szRelFile[MAX_PATH];
	//af_GetRelativePath(szFile, szRelFile);

	//AFilePackage* pPackage = g_AFilePackMan.GetFilePck(szRelFile);
	//if (pPackage)
	//{
	//	AFilePackage::FILEENTRY Entry;
	//	int	nIndex;
	//	if (!pPackage->GetFileEntry(szRelFile, &Entry, &nIndex))
	//	{
	//		if (bReplaceOnly)
	//			return false;

	//		return pPackage->AppendFile(szRelFile, (unsigned char*)pBuf, dwBufLen, true);
	//	}
	//	else
	//		return pPackage->ReplaceFile(szRelFile, (unsigned char*)pBuf, dwBufLen, true);
	//}
	//else	//	Write to disk
	//{
	//	AFile af;
	//	if (!af.Open("", szFile, AFILE_CREATENEW | AFILE_NOHEAD | AFILE_BINARY))
	//		return false;

	//	auint32 dwWrite;
	//	if (!af.Write((void*)pBuf, dwBufLen, &dwWrite))
	//		return false;

	//	af.Close();
	//}

	return true;
}

AFileImage::AFileImage() : AFile()
{
	m_pPackage = NULL;
	m_pFileImage = NULL;
	m_nCurPtr = 0;
	m_nFileLength = 0;
	m_dwHandle = 0;
}

AFileImage::~AFileImage()
{
	Close();
}

bool AFileImage::Init(const char* szFullName)
{
	strncpy(m_szFileName, szFullName, QMAX_PATH);
	af_GetRelativePath(szFullName, m_szRelativeName);

	//读取library 文件夹下的更新包pack包下有没有相关文件
	m_pPackage = NULL;
	m_pPackage = g_AUpdateFilePackMan.GetFilePck(m_szRelativeName);
	if (m_pPackage)
	{
		if (ReadPackData(m_pPackage) == true)
		{
			return  true;
		}
	}

	//读取library 文件夹下是否有分离文件
	char temp[QMAX_PATH];
	strcpy(temp, m_szRelativeName);
	AString strpath(temp);
	//	AString strpath = A_GB2312_TO_CPPTEXT(m_szRelativeName);
	strpath.NormalizeFileName();
	char pathfile[QMAX_PATH];

	//判断是否为空
	if (*af_GetLibraryDir() != '\0')
	{
		af_GetFullPathNoBase(pathfile, af_GetLibraryDir(), (const char*)strpath);

		if (ReadFileData(pathfile, false) == true)
		{
			m_dwTimeStamp = ASys::GetFileTimeStamp(pathfile);
			m_pPackage = NULL;
			return true;
		}
	}

	//读取app bundle package 包下是否有文件
	m_pPackage = NULL;
	m_pPackage = g_AFilePackMan.GetFilePck(m_szRelativeName);
	if (m_pPackage)
	{
		if (ReadPackData(m_pPackage) == true)
		{
			return true;
		}
	}

	//读取app bundle 是否有分离文件
	strpath = temp;
	strpath.NormalizeFileName();
	af_GetFullPathNoBase(pathfile, af_GetBaseDir(), (const char*)strpath);
	if (ReadFileData(pathfile, false) == true)
	{
		m_dwTimeStamp = ASys::GetFileTimeStamp(pathfile);
		m_pPackage = NULL;
		return true;
	}

	g_pAFramework->DevPrintf("AFileImage::Init, Failed to find file [%s]  !", pathfile);
	return false;
}

bool AFileImage::ReadFileData(const char* pathfile, bool bPrintError)
{
	FILE* pFile;
	if (!(pFile = fopen(pathfile, "rb")))
	{
		if (bPrintError)
			g_pAFramework->DevPrintf("AFileImage::Can not open file [%s] from disk!", pathfile);
		return false;
	}

	fseek(pFile, 0, SEEK_END);
	if (!(m_nFileLength = ftell(pFile)))
	{
		fclose(pFile);
		g_pAFramework->DevPrintf("AFileImage::Init The file [%s] is zero length!", pathfile);
		return false;
	}

	fseek(pFile, 0, SEEK_SET);

	if (!(m_pFileImage = (unsigned char*)malloc(m_nFileLength)))
	{
		fclose(pFile);
		g_pAFramework->DevPrintf("AFileImage::Init Not enough memory! FileName : %s, FileLength : %d", pathfile, m_nFileLength);
		return false;
	}

	fread(m_pFileImage, m_nFileLength, 1, pFile);

	fclose(pFile);

	return true;
}

bool AFileImage::ReadPackData(AFilePackBase* pPackage, bool bPrintError)
{
	auint32 dwFileLen;

	//	Init from a package
	if (!(m_dwHandle = pPackage->OpenSharedFile(m_szRelativeName, &m_pFileImage, &dwFileLen)))
	{
		// can't find it in package, so see if can load from disk.
		return false;
	}

	m_nFileLength = (int)dwFileLen;
	m_dwTimeStamp = 0;
	return true;
}

bool AFileImage::Release()
{
	if (!m_pPackage)
	{
		if (m_pFileImage)
		{
			free(m_pFileImage);

			m_pFileImage = NULL;
		}
	}
	else
	{
		if (m_dwHandle && m_pFileImage)
		{
			m_pPackage->CloseSharedFile(m_dwHandle);
			m_pFileImage = NULL;
			m_dwHandle = 0;
		}
	}

	return true;
}

bool AFileImage::Open(const char* szFolderName, const char * szFileName, auint32 dwFlags)
{
	char szFullPath[QMAX_PATH];

	af_GetFullPath(szFullPath, szFolderName, szFileName);
	return Open(szFullPath, dwFlags);
}

bool AFileImage::OpenWithAbsFullPath(const char* szFullPath, auint32 dwFlags)
{
	if (m_bHasOpened)
		Close();

	if ((dwFlags & AFILE_TEMPMEMORY) &&
		(dwFlags & AFILE_NOTEMPMEMORY))
	{
		ASSERT(0 && "Flags conflicts, AFILE_NOTEMPMEMORY will be used.");
		dwFlags &= ~AFILE_TEMPMEMORY;
	}

	//	Note: AFILE_TEMPMEMORY is default now except AFILE_NOTEMPMEMORY is specified
	//	bool bTempMem = (dwFlags & AFILE_NOTEMPMEMORY) ? false : true;
	AString strfile(szFullPath);
	strfile.Replace('\\', '/');
	if (!ReadFileData((const char*)strfile, false))
	{
		return false;
	}

	m_dwTimeStamp = ASys::GetFileTimeStamp(szFullPath);
	m_pPackage = NULL;

	if (dwFlags & AFILE_OPENEXIST)
	{
	}
	else
	{
		g_pAFramework->DevPrintf("AFileImage::Open Current we only support read flag to operate a file image");
		return false;
	}

	auint32 dwFOURCC;
	int   nRead;

	m_dwFlags = dwFlags;
	m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));
	if (!fimg_read((unsigned char*)&dwFOURCC, 4, &nRead))
		return false;

	if (m_nFileLength > 4)
	{
		auint32 dwFOURCC;
		int   nRead;

		m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));
		if (!fimg_read((unsigned char*)&dwFOURCC, 4, &nRead))
			return false;

		if (dwFOURCC == 0x42584f4d)
			m_dwFlags |= AFILE_BINARY;
		else if (dwFOURCC == 0x54584f4d)
			m_dwFlags |= AFILE_TEXT;
		else
		{
			m_dwFlags = dwFlags;
			fimg_seek(0, AFILE_SEEK_SET);
		}
	}
	else
	{
		m_dwFlags = dwFlags;
		fimg_seek(0, AFILE_SEEK_SET);
	}

	m_bHasOpened = true;
	return true;
}

bool AFileImage::Open(const char* szFullPath, auint32 dwFlags)
{
	// If we have opened it already, we must close it;
	if (m_bHasOpened)
		Close();

	if ((dwFlags & AFILE_TEMPMEMORY) &&
		(dwFlags & AFILE_NOTEMPMEMORY))
	{
		ASSERT(0 && "Flags conflicts, AFILE_NOTEMPMEMORY will be used.");
		dwFlags &= ~AFILE_TEMPMEMORY;
	}

	//	Note: AFILE_TEMPMEMORY is default now except AFILE_NOTEMPMEMORY is specified
	bool bTempMem = (dwFlags & AFILE_NOTEMPMEMORY) ? false : true;

	if (!Init(szFullPath))
	{
		return false;
	}

	if (dwFlags & AFILE_OPENEXIST)
	{
	}
	else
	{
		g_pAFramework->DevPrintf("AFileImage::Open Current we only support read flag to operate a file image");
		return false;
	}

	auint32 dwFOURCC;
	int   nRead;

	m_dwFlags = dwFlags;
	m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));
	if (!fimg_read((unsigned char*)&dwFOURCC, 4, &nRead))
		return false;

	if (m_nFileLength > 4)
	{
		auint32 dwFOURCC;
		int   nRead;

		m_dwFlags = dwFlags & (~(AFILE_BINARY | AFILE_TEXT));
		if (!fimg_read((unsigned char*)&dwFOURCC, 4, &nRead))
			return false;

		if (dwFOURCC == 0x42584f4d)
			m_dwFlags |= AFILE_BINARY;
		else if (dwFOURCC == 0x54584f4d)
			m_dwFlags |= AFILE_TEXT;
		else
		{
			m_dwFlags = dwFlags;
			fimg_seek(0, AFILE_SEEK_SET);
		}
	}
	else
	{
		m_dwFlags = dwFlags;
		fimg_seek(0, AFILE_SEEK_SET);
	}

	m_bHasOpened = true;
	return true;
}

bool AFileImage::Close()
{
	Release();

	m_nCurPtr = 0;
	m_szFileName[0] = '\0';
	return true;
}

bool AFileImage::ResetPointer()
{
	fimg_seek(0, AFILE_SEEK_SET);
	return true;
}

bool AFileImage::fimg_read(unsigned char* pBuffer, int nSize, int * pReadSize)
{
	int nSizeToRead = nSize;

	if (m_nCurPtr + nSizeToRead > m_nFileLength)
		nSizeToRead = m_nFileLength - m_nCurPtr;

	if (nSizeToRead <= 0)
	{
		*pReadSize = 0;
		return nSize == 0 ? true : false;
	}

	memcpy(pBuffer, m_pFileImage + m_nCurPtr, nSizeToRead);
	m_nCurPtr += nSizeToRead;
	*pReadSize = nSizeToRead;
	return true;
}

bool AFileImage::fimg_read_line(char * szLineBuffer, int nMaxLength, int * pReadSize)
{
	int nSizeRead = 0;

	memset(szLineBuffer, 0, nMaxLength);
	while (m_nCurPtr < m_nFileLength)
	{
		unsigned char byteThis = m_pFileImage[m_nCurPtr];

		if (byteThis != 0x0d && byteThis != 0x0a)
		{
			// Not \n or \r, so copy it into the buffer;
			szLineBuffer[nSizeRead++] = m_pFileImage[m_nCurPtr++];
		}
		else
		{
			// We also need to copy \n into the buffer;
			szLineBuffer[nSizeRead++] = m_pFileImage[m_nCurPtr++];
			szLineBuffer[nSizeRead] = '\0';
			if (byteThis == 0x0d)
			{
				// We need to check if next byte is \r, if so, just remove it;
				if (m_nCurPtr < m_nFileLength)
				{
					if (m_pFileImage[m_nCurPtr] == 0x0a)
					{
						m_nCurPtr++;
						nSizeRead++;
					}
				}
			}

			break;
		}
	}

	*pReadSize = nSizeRead;

	if (nSizeRead <= 0)
		return false;
	return true;
}

bool AFileImage::fimg_seek(int nOffset, int startPos)
{
	switch (startPos)
	{
	case AFILE_SEEK_SET:
		m_nCurPtr = nOffset;
		break;
	case AFILE_SEEK_CUR:
		m_nCurPtr += nOffset;
		break;
	case AFILE_SEEK_END:
		m_nCurPtr = m_nFileLength + nOffset;
		break;
	default:
		return false;
	}
	if (m_nCurPtr < 0)
		m_nCurPtr = 0;
	else if (m_nCurPtr > m_nFileLength) // To be compatible with fseek, we have to let the file pointer beyond the last character;
		m_nCurPtr = m_nFileLength;
	return true;
}

bool AFileImage::ReadLine(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength)
{
	int nReadSize;

	if (!fimg_read_line(szLineBuffer, dwBufferLength, &nReadSize))
		return false;

	//chop the \n\r
	if (szLineBuffer[0] && (szLineBuffer[strlen(szLineBuffer) - 1] == '\n' || szLineBuffer[strlen(szLineBuffer) - 1] == '\r'))
		szLineBuffer[strlen(szLineBuffer) - 1] = '\0';

	if (szLineBuffer[0] && (szLineBuffer[strlen(szLineBuffer) - 1] == '\n' || szLineBuffer[strlen(szLineBuffer) - 1] == '\r'))
		szLineBuffer[strlen(szLineBuffer) - 1] = '\0';

	*pdwReadLength = strlen(szLineBuffer) + 1;
	return true;
}

bool AFileImage::Read(void* pBuffer, auint32 dwBufferLength, auint32 * pReadLength)
{
	int nReadSize;
	if (!fimg_read((unsigned char*)pBuffer, dwBufferLength, &nReadSize))
		return false;

	*pReadLength = nReadSize;
	return true;
}

bool AFileImage::Write(const void* pBuffer, auint32 dwBufferLength, auint32 * pWriteLength)
{
	return false;
}

auint32 AFileImage::GetPos() const
{
	return (auint32)m_nCurPtr;
}

bool AFileImage::Seek(int iOffset, AFILE_SEEK origin)
{
	return fimg_seek(iOffset, (int)origin);
}

bool AFileImage::WriteLine(const char* szLineBuffer)
{
	return false;
}

bool AFileImage::ReadString(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength)
{
	char ch;
	auint32 dwReadLength;
	auint32 nStrLen = 0;

	Read(&ch, 1, &dwReadLength);
	while (ch)
	{
		szLineBuffer[nStrLen] = ch;
		nStrLen++;

		if (nStrLen >= dwBufferLength)
			return false;

		Read(&ch, 1, &dwReadLength);
	}

	szLineBuffer[nStrLen] = '\0';

	*pdwReadLength = nStrLen + 1;
	return true;
}

bool AFileImage::WriteString(const AString& str)
{
	return false;
}

bool AFileImage::ReadString(AString& str)
{
	//	Only binary file is supported
	/*	if (m_dwFlags & AFILE_TEXT)
		{
		ASSERT(!(m_dwFlags & AFILE_TEXT));
		return false;
		}
		*/
	int iRead;

	//	Read length of string
	int iLen;
	if (!fimg_read((unsigned char*)&iLen, sizeof(int), &iRead))
		return false;

	//	Read string data
	if (iLen)
	{
		ATempMemBuffer tempBuf(sizeof(char) * (iLen + 1));
		char* szBuf = (char*)tempBuf.GetBuffer();
		if (!szBuf)
			return false;

		if (!fimg_read((unsigned char*)szBuf, iLen, &iRead))
		{
			delete[] szBuf;
			return false;
		}
		szBuf[iLen] = '\0';
		str = szBuf;
	}
	else
		str = "";

	return true;
}