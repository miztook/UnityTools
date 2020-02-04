#include "AFilePackGame.h"
#include "ASys.h"
#include "AFI.h"
#include "AFramework.h"
#include "AFilePackage.h"
#include "ATempMemBuffer.h"
#include "AAssist.h"

#ifndef DISABLE_ZLIB

#include <zlib.h>

#endif

///////////////////////////////////////////////////////////////////////////
//
//	Define and Macro
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Reference to External variables and functions
//
///////////////////////////////////////////////////////////////////////////

extern int	AFPCK_GUARDBYTE0;
extern int	AFPCK_GUARDBYTE1;
extern int	AFPCK_MASKDWORD;
extern int	AFPCK_CHECKMASK;

///////////////////////////////////////////////////////////////////////////
//
//	Local Types and Variables and Global variables
//
///////////////////////////////////////////////////////////////////////////

struct FILEENTRY_INFILE
{
	char	szFileName[MAX_PATH];	//	The file name of this entry; this may contain a path;
	auint32	dwOffset;				//	The offset from the beginning of the package file;
	auint32	dwLength;				//	The length of this file;
	auint32	dwCompressedLength;		//	The compressed data length;
	int		iAccessCnt;				//	Access counter used by OpenSharedFile
};

///////////////////////////////////////////////////////////////////////////
//
//	Local functions
//
///////////////////////////////////////////////////////////////////////////

extern int _CacheFileNameCompare(const void *arg1, const void *arg2);

#ifndef DISABLE_ZLIB

extern void* Zlib_User_Alloc(void* opaque, unsigned int items, unsigned int size);
extern void Zlib_User_Free(void* opaque, void* ptr);
extern int Zlib_Compress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen, int level);
extern int Zlib_UnCompress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);

#endif
///////////////////////////////////////////////////////////////////////////
//
//	Implement of AFilePackGame
//
///////////////////////////////////////////////////////////////////////////

AFilePackGame::AFilePackGame() :
	m_FileQuickSearchTab(2048)
{
	m_aFileEntries = NULL;
	m_iNumEntry = 0;
	m_bReadOnly = false;
	m_bUseShortName = false;
	m_fpPackageFile = NULL;
	m_szPckFileName[0] = '\0';
	m_bHasSafeHeader = false;

	INIT_LOCK(&m_csFR);
}

AFilePackGame::~AFilePackGame()
{
	DESTROY_LOCK(&m_csFR);
}

bool AFilePackGame::LoadOldPack(const char* szPckPath, bool  bEncrypt, int nFileOffset)
{
	int i, iNumFile;

	// Now read file number;
	nFileOffset -= sizeof(int);
	m_fpPackageFile->seek(nFileOffset, SEEK_SET);
	m_fpPackageFile->read(&iNumFile, sizeof(int), 1);
	nFileOffset -= sizeof(FILEHEADER);
	m_fpPackageFile->seek(nFileOffset, SEEK_SET);
	m_fpPackageFile->read(&m_header, sizeof(FILEHEADER), 1);
	if (strstr(m_header.szDescription, "lica File Package") == NULL)
		return false;
	strncpy(m_header.szDescription, AFPCK_COPYRIGHT_TAG, sizeof(m_header.szDescription));

	// if we don't expect one encrypt package, we will let the error come out.
	// make sure the encrypt flag is correct
	bool bPackIsEncrypt = (m_header.dwFlags & PACKFLAG_ENCRYPT) != 0;
	if (bEncrypt != bPackIsEncrypt)
	{
		g_pAFramework->DevPrintf(("AFilePackage::Open(), wrong encrypt flag"));
		return false;
	}

	m_header.dwEntryOffset ^= AFPCK_MASKDWORD;

	if (m_header.guardByte0 != AFPCK_GUARDBYTE0 ||
		m_header.guardByte1 != AFPCK_GUARDBYTE1)
	{
		// corrput file
		g_pAFramework->DevPrintf("AFilePackGame::Open(), GuardBytes corrupted [%s]", szPckPath);
		return false;
	}

	//	Seek to entry list;
	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);

	//	Create entries
	m_aFileEntries = (FILEENTRY*)malloc(sizeof(FILEENTRY) * iNumFile);
	if (!m_aFileEntries)
	{
		g_pAFramework->DevPrintf("AFilePackGame::Open(), Not enough memory for entries [%s]", szPckPath);
		return false;
	}

	memset(m_aFileEntries, 0, sizeof(FILEENTRY) * iNumFile);

	m_iNumEntry = iNumFile;

	for (i = 0; i < iNumFile; i++)
	{
		FILEENTRY* pEntry = &m_aFileEntries[i];

		FILEENTRY_INFILE tempEntry;

		// first read the entry size after compressed
		int nCompressedSize;
		m_fpPackageFile->read(&nCompressedSize, sizeof(int), 1);
		nCompressedSize ^= AFPCK_MASKDWORD;

		int nCheckSize;
		m_fpPackageFile->read(&nCheckSize, sizeof(int), 1);
		nCheckSize = nCheckSize ^ AFPCK_CHECKMASK ^ AFPCK_MASKDWORD;

		if (nCompressedSize != nCheckSize)
		{
			g_pAFramework->DevPrintf(("AFilePackGame::Open(), Check Byte Error!"));
			return false;
		}

		ATempMemBuffer tempBuf(sizeof(abyte) * nCompressedSize);
		abyte* pEntryCompressed = (abyte*)tempBuf.GetBuffer();
		if (!pEntryCompressed)
		{
			g_pAFramework->DevPrintf(("AFilePackGame::Open(), Not enough memory !"));
			return false;
		}

		m_fpPackageFile->read(pEntryCompressed, nCompressedSize, 1);
		auint32 dwEntrySize = sizeof(FILEENTRY_INFILE);

		if (dwEntrySize == nCompressedSize)
		{
			memcpy(&tempEntry, pEntryCompressed, sizeof(FILEENTRY_INFILE));
		}
		else
		{
			if (0 != AFilePackage::Uncompress(pEntryCompressed, nCompressedSize, (unsigned char*)&tempEntry, &dwEntrySize))
			{
				tempBuf.Free();
				g_pAFramework->DevPrintf(("AFilePackGame::Open(), decode file entry fail!"));
				return false;
			}

			ASSERT(dwEntrySize == sizeof(FILEENTRY_INFILE));
		}

		//	Note: A bug existed in AppendFileCompressed() after m_bUseShortName was introduced. The bug
		//		didn't normalize file name when new file is added to package, so that the szFileName of
		//		FILEENTRY may contain '/' character. The bug wasn't fixed until 2013.3.18, many 'new' files
		//		have been added to package, so NormalizeFileName is inserted here to ensure all szFileName
		//		of FILEENTRY uses '\' instead of '/', at least in memory.
		//	NormalizeFileName(tempEntry.szFileName, false);

		//	Duplicate entry info
		pEntry->szFileName = AllocFileName(tempEntry.szFileName, i, iNumFile);
		pEntry->dwLength = tempEntry.dwLength;
		pEntry->dwCompressedLength = tempEntry.dwCompressedLength;
		pEntry->dwOffset = tempEntry.dwOffset;

		tempBuf.Free();
	}

	ResortEntries();

	// now we move entry point to the end of the file so to keep old entries here
	if (m_bHasSafeHeader)
		m_header.dwEntryOffset = nFileOffset;

	return true;
}

bool AFilePackGame::LoadPack(const char* szPckPath, bool  bEncrypt, int nFileOffset)
{
	int i, iNumFile;
	auint32 dwCompressEntryLen = 0;
	// Now read file number;
	nFileOffset -= sizeof(int);
	m_fpPackageFile->seek(nFileOffset, SEEK_SET);
	m_fpPackageFile->read(&iNumFile, sizeof(int), 1);

	//new version
	nFileOffset -= sizeof(auint32);
	m_fpPackageFile->seek(nFileOffset, SEEK_SET);
	m_fpPackageFile->read(&dwCompressEntryLen, sizeof(auint32), 1);

	nFileOffset -= sizeof(FILEHEADER);
	m_fpPackageFile->seek(nFileOffset, SEEK_SET);
	m_fpPackageFile->read(&m_header, sizeof(FILEHEADER), 1);
	if (strstr(m_header.szDescription, "lica File Package") == NULL)
		return false;
	strncpy(m_header.szDescription, AFPCK_COPYRIGHT_TAG, sizeof(m_header.szDescription));

	// if we don't expect one encrypt package, we will let the error come out.
	// make sure the encrypt flag is correct
	bool bPackIsEncrypt = (m_header.dwFlags & PACKFLAG_ENCRYPT) != 0;
	if (bEncrypt != bPackIsEncrypt)
	{
		g_pAFramework->DevPrintf(("AFilePackage::Open(), wrong encrypt flag"));
		return false;
	}

	m_header.dwEntryOffset ^= AFPCK_MASKDWORD;

	if (m_header.guardByte0 != AFPCK_GUARDBYTE0 ||
		m_header.guardByte1 != AFPCK_GUARDBYTE1)
	{
		// corrput file
		g_pAFramework->DevPrintf("AFilePackGame::Open(), GuardBytes corrupted [%s]", szPckPath);
		return false;
	}

	m_iNumEntry = iNumFile;
	if (dwCompressEntryLen == 0)
	{
		ResortEntries();
		// now we move entry point to the end of the file so to keep old entries here
		if (m_bHasSafeHeader)
			m_header.dwEntryOffset = nFileOffset;
		return true;
	}

	//	Seek to entry list;
	ATempMemBuffer tempBuf1(dwCompressEntryLen);
	abyte* pEntryCompressBuf = (abyte*)tempBuf1.GetBuffer();
	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);
	m_fpPackageFile->read(pEntryCompressBuf, dwCompressEntryLen, 1);

	//	Create entries
	m_aFileEntries = (FILEENTRY*)malloc(sizeof(FILEENTRY) * iNumFile);
	if (!m_aFileEntries)
	{
		tempBuf1.Free();
		g_pAFramework->DevPrintf("AFilePackGame::Open(), Not enough memory for entries [%s]", szPckPath);
		return false;
	}

	auint32 entryiesLen = iNumFile * sizeof(FILEENTRY_INFILE);
	auint32 entryuncompresslen = entryiesLen;
	ATempMemBuffer tempBuf2(entryuncompresslen);
	abyte* pEntryUnCompressBuf = (abyte*)tempBuf2.GetBuffer();
	int ret = AFilePackage::Uncompress(pEntryCompressBuf, dwCompressEntryLen, pEntryUnCompressBuf, &entryuncompresslen);
	if (ret != 0)
	{
		tempBuf1.Free();
		tempBuf2.Free();
		return false;
	}

	tempBuf1.Free();
	pEntryCompressBuf = NULL;

	ASSERT(entryuncompresslen == entryiesLen);
	FILEENTRY_INFILE* pInFileList = (FILEENTRY_INFILE*)pEntryUnCompressBuf;
	for (i = 0; i < iNumFile; i++)
	{
		const FILEENTRY_INFILE& src = pInFileList[i];
		FILEENTRY* pFileEntry = &m_aFileEntries[i];

		pFileEntry->szFileName = AllocFileName(src.szFileName, i, iNumFile);
		pFileEntry->dwLength = src.dwLength;
		pFileEntry->dwCompressedLength = src.dwCompressedLength;
		pFileEntry->dwOffset = src.dwOffset;
	}

	tempBuf2.Free();
	pEntryUnCompressBuf = NULL;

	ResortEntries();

	// now we move entry point to the end of the file so to keep old entries here
	if (m_bHasSafeHeader)
		m_header.dwEntryOffset = nFileOffset;

	return true;
}

bool AFilePackGame::InnerOpen(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt, bool bShortName)
{
	char szFullPckPath[MAX_PATH];
	strcpy(szFullPckPath, szPckPath);

	m_bUseShortName = bShortName;

	//	Save folder name
	ASSERT(szFolder);
	strncpy(m_szFolder, szFolder, MAX_PATH);
	ASys::Strlwr(m_szFolder);
	AFilePackage::NormalizeFileName(m_szFolder);

	//	Add '//' at folder tail
	int iFolderLen = strlen(m_szFolder);
	if (m_szFolder[iFolderLen - 1] != '\\')
	{
		m_szFolder[iFolderLen] = '\\';
		m_szFolder[iFolderLen + 1] = '\0';
	}

	switch (mode)
	{
	case OPENEXIST:
		m_bReadOnly = false;
		m_fpPackageFile = new CPackageFile();

		if (!m_fpPackageFile->Open(szFullPckPath, "r+b"))
		{
			if (!m_fpPackageFile->Open(szFullPckPath, "rb"))
			{
				delete m_fpPackageFile;
				m_fpPackageFile = NULL;

				g_pAFramework->DevPrintf("AFilePackGame::Open(), Can not open file [%s]", szFullPckPath);
				return false;
			}
			m_bReadOnly = true;
		}

		if (m_fpPackageFile->GetPackageFileSize() <= sizeof(auint32))
		{
			g_pAFramework->DevPrintf(("AFilePackGame::Open(), Package size < 4, Skip!"));
			return false;
		}

		strncpy(m_szPckFileName, szPckPath, MAX_PATH);

		LoadSafeHeader();

		int nOffset;
		m_fpPackageFile->seek(0, SEEK_END);
		nOffset = m_fpPackageFile->tell();
		m_fpPackageFile->seek(0, SEEK_SET);

		if (m_bHasSafeHeader)
			nOffset = (int)m_safeHeader.offset;

		// Now analyse the file entries of the package;
		auint32 dwVersion;

		// First version;
		nOffset -= sizeof(auint32);
		m_fpPackageFile->seek(nOffset, SEEK_SET);
		m_fpPackageFile->read(&dwVersion, sizeof(auint32), 1);

		if (dwVersion == 0x00020002 || dwVersion == 0x00020001)
		{
			if (!LoadOldPack(szPckPath, bEncrypt, nOffset))
			{
				g_pAFramework->DevPrintf(("AFilePackage::LoadOldPack(), Incorrect version!"));
			}
		}
		else if (dwVersion == 0x00020003)
		{
			if (!LoadPack(szPckPath, bEncrypt, nOffset))
			{
				g_pAFramework->DevPrintf(("AFilePackage::LoadPack(), Incorrect version!"));
			}
		}
		else
		{
			g_pAFramework->DevPrintf(("AFilePackGame::Open(), Incorrect version!"));
			return false;
		}

		break;

	default:

		g_pAFramework->DevPrintf("AFilePackGame::Open(), Unknown open mode [%d]!", mode);
		return false;
	}

	m_mode = mode;

	return true;
}

bool AFilePackGame::Open(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt/* false */)
{
	return InnerOpen(szPckPath, szFolder, mode, bEncrypt, true);
}

bool AFilePackGame::Open(const char* szPckPath, OPENMODE mode, bool bEncrypt)
{
	char szFolder[MAX_PATH];

	strncpy(szFolder, szPckPath, MAX_PATH);
	szFolder[MAX_PATH - 1] = '\0';

	if (szFolder[0] == '\0')
	{
		g_pAFramework->DevPrintf(("AFilePackGame::Open(), can not open a null or empty file name!"));
		return false;
	}
	char* pext = szFolder + strlen(szFolder) - 1;
	while (pext != szFolder)
	{
		if (*pext == '.')
			break;

		pext--;
	}

	if (pext == szFolder)
	{
		g_pAFramework->DevPrintf(("AFilePackGame::Open(), only file with extension can be opened!"));
		return false;
	}

	*pext++ = '\\';
	*pext = '\0';

	return InnerOpen(szPckPath, szFolder, mode, bEncrypt, false);
}

bool AFilePackGame::Close()
{
	if (m_fpPackageFile)
	{
		m_fpPackageFile->Close();
		delete m_fpPackageFile;
		m_fpPackageFile = NULL;
	}

	//	Release entries
	if (m_aFileEntries)
	{
		free(m_aFileEntries);
		m_aFileEntries = NULL;
	}

	m_FileQuickSearchTab.clear();
	m_aIDCollisionFiles.clear();

	//	Release file names
	for (NAMEBUFFER& info : m_aNameBufs)
	{
		free(info.pBuffer);
	}

	m_aNameBufs.clear();

	return true;
}

//	Allocate new name
char* AFilePackGame::AllocFileName(const char* szFile, int iEntryCnt, int iEntryTotalNum)
{
	ASSERT(szFile);

	auint32 dwNameLen = strlen(szFile) + 1;
	ASSERT(dwNameLen < MAX_PATH);

	bool bAllocNewBuffer = false;
	NAMEBUFFER* pBufInfo = NULL;

	if (m_aNameBufs.empty())
	{
		bAllocNewBuffer = true;
	}
	else
	{
		pBufInfo = &m_aNameBufs.back();
		if (pBufInfo->dwOffset + dwNameLen > pBufInfo->dwLength)
			bAllocNewBuffer = true;
	}

	if (bAllocNewBuffer)
	{
		auint32 dwSize = (iEntryTotalNum - iEntryCnt) * 32;
		if (dwSize < dwNameLen)
			dwSize = dwNameLen * 10;

		char* pBuffer = (char*)malloc(dwSize);
		if (!pBuffer)
			return NULL;

		NAMEBUFFER info;
		info.dwLength = dwSize;
		info.pBuffer = pBuffer;
		info.dwOffset = 0;
		m_aNameBufs.push_back(info);

		pBufInfo = &m_aNameBufs.back();
	}

	ASSERT(pBufInfo);

	char* pCurPos = &(pBufInfo->pBuffer[pBufInfo->dwOffset]);
	strncpy(pCurPos, szFile, dwNameLen);
	pCurPos[dwNameLen - 1] = '\0';
	pBufInfo->dwOffset += dwNameLen;

	return pCurPos;
}

//	Get rid of folder from file
void AFilePackGame::GetRidOfFolder(const char* szInName, char* szOutName) const
{
	af_GetRelativePathNoBase(szInName, m_szFolder, szOutName);
}

//	Normalize file name
bool AFilePackGame::NormalizeFileName(char* szFileName, bool bUseShortName) const
{
	if (!AFilePackage::NormalizeFileName(szFileName))
		return false;

	//	Get rid of folder from file name
	if (bUseShortName)
	{
		char szFullName[MAX_PATH];
		strcpy(szFullName, szFileName);
		GetRidOfFolder(szFullName, szFileName);
	}

	return true;
}

static bool CheckFileEntryValid(AFilePackGame::FILEENTRY* pFileEntry)
{
	if (pFileEntry->dwCompressedLength > MAX_FILE_PACKAGE)
	{
		g_pAFramework->DevPrintf("CheckFileEntryValid, file entry [%s]'s length is not correct!", pFileEntry->szFileName);
		return false;
	}

	return true;
}

bool AFilePackGame::IsFileExist(const char* szFileName) const
{
	return GetFileEntry(szFileName) ? true : false;
}

AFilePackGame::FILEENTRY* AFilePackGame::GetFileEntry(const char* szFileName) const
{
	ASSERT((int)m_FileQuickSearchTab.size() + m_aIDCollisionFiles.size() == m_iNumEntry);

	//	Normalize file name
	char szFindName[MAX_PATH];
	strncpy(szFindName, szFileName, MAX_PATH);
	NormalizeFileName(szFindName, m_bUseShortName);

	auint32 idFile = a_MakeIDFromFileName(szFindName);
	if (!idFile)
	{
		ASSERT(idFile && "Failed to generate file id");
		g_pAFramework->DevPrintf("AFilePackGame::GetFileEntry, failed to generate file id for [%s%s] !", m_szFolder, szFindName);
		return 0;
	}

	auto itr = m_FileQuickSearchTab.find((int)idFile);
	if (itr != m_FileQuickSearchTab.end())
	{
		FILEENTRY* pFileEntry = itr->second;

		//	Check file name again to avoid id collision problem
		if (0 != ASys::StrCmpNoCase(szFindName, pFileEntry->szFileName))
		{
			//	There is id collision occurs, search file in candidate array
			//	ASSERT(0 && "file name collision");
			pFileEntry = FindIDCollisionFile(szFindName);
			return pFileEntry;
		}
		else
			return pFileEntry;
	}
	else
		return NULL;
}

//	Find a file in ID collision candidate array
AFilePackGame::FILEENTRY* AFilePackGame::FindIDCollisionFile(const char* szFileName) const
{
	for (FILEENTRY* pFileEntry : m_aIDCollisionFiles)
	{
		if (!ASys::StrCmpNoCase(szFileName, pFileEntry->szFileName))
			return pFileEntry;
	}

	return NULL;
}

void AFilePackGame::Encrypt(unsigned char* pBuffer, auint32 dwLength)
{
	if ((m_header.dwFlags & PACKFLAG_ENCRYPT) == 0)
		return;

	auint32 dwMask = dwLength + 0x739802ab;

	for (auint32 i = 0; i < dwLength; i += 4)
	{
		if (i + 3 < dwLength)
		{
			auint32 data = (pBuffer[i] << 24) | (pBuffer[i + 1] << 16) | (pBuffer[i + 2] << 8) | pBuffer[i + 3];
			data ^= dwMask;
			data = (data << 16) | ((data >> 16) & 0xffff);
			pBuffer[i] = (data >> 24) & 0xff;
			pBuffer[i + 1] = (data >> 16) & 0xff;
			pBuffer[i + 2] = (data >> 8) & 0xff;
			pBuffer[i + 3] = data & 0xff;
		}
	}
}

void AFilePackGame::Decrypt(unsigned char* pBuffer, auint32 dwLength)
{
	if ((m_header.dwFlags & PACKFLAG_ENCRYPT) == 0)
		return;

	auint32 dwMask = dwLength + 0x739802ab;

	for (auint32 i = 0; i < dwLength; i += 4)
	{
		if (i + 3 < dwLength)
		{
			auint32 data = (pBuffer[i] << 24) | (pBuffer[i + 1] << 16) | (pBuffer[i + 2] << 8) | pBuffer[i + 3];
			data = (data << 16) | ((data >> 16) & 0xffff);
			data ^= dwMask;
			pBuffer[i] = (data >> 24) & 0xff;
			pBuffer[i + 1] = (data >> 16) & 0xff;
			pBuffer[i + 2] = (data >> 8) & 0xff;
			pBuffer[i + 3] = data & 0xff;
		}
	}
}

bool AFilePackGame::ReadFile(const char* szFileName, unsigned char* pFileBuffer, auint32* pdwBufferLen)
{
	FILEENTRY* pFileEntry = GetFileEntry(szFileName);
	if (!pFileEntry)
	{
		g_pAFramework->DevPrintf("AFilePackage::ReadFile(), Can not find file entry [%s]!", szFileName);
		return false;
	}

	return ReadFile(*pFileEntry, pFileBuffer, pdwBufferLen);
}

bool AFilePackGame::ReadFile(FILEENTRY& fileEntry, unsigned char* pFileBuffer, auint32 * pdwBufferLen)
{
	if (*pdwBufferLen < fileEntry.dwLength)
	{
		g_pAFramework->DevPrintf(("AFilePackGame::ReadFile(), Buffer is too small!"));
		return false;
	}

	// We can automaticly determine whether compression has been used;
	if (fileEntry.dwLength > fileEntry.dwCompressedLength)
	{
		auint32 dwFileLength = fileEntry.dwLength;

		ATempMemBuffer tempBuf(fileEntry.dwCompressedLength);
		abyte* pBuffer = (abyte*)tempBuf.GetBuffer();
		if (!pBuffer)
			return false;

		BEGIN_LOCK(&m_csFR);
		m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
		m_fpPackageFile->read(pBuffer, fileEntry.dwCompressedLength, 1);
		Decrypt(pBuffer, fileEntry.dwCompressedLength);
		END_LOCK(&m_csFR);

		if (0 != AFilePackage::Uncompress(pBuffer, fileEntry.dwCompressedLength, pFileBuffer, &dwFileLength))
		{
			FILE * fp = fopen("logs\\bad.dat", "wb");
			if (fp)
			{
				fwrite(pBuffer, fileEntry.dwCompressedLength, 1, fp);
				fclose(fp);
			}

			return false;
		}

		//uncompress(pFileBuffer, &dwFileLength, m_pBuffer, fileEntry.dwCompressedLength);

		*pdwBufferLen = dwFileLength;
	}
	else
	{
		BEGIN_LOCK(&m_csFR);
		m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
		m_fpPackageFile->read(pFileBuffer, fileEntry.dwLength, 1);
		Decrypt(pFileBuffer, fileEntry.dwLength);
		END_LOCK(&m_csFR);

		*pdwBufferLen = fileEntry.dwLength;
	}

	return true;
}

bool AFilePackGame::ReadCompressedFile(FILEENTRY& fileEntry, unsigned char* pCompressedBuffer, auint32 * pdwBufferLen)
{
	if (*pdwBufferLen < fileEntry.dwCompressedLength)
	{
		g_pAFramework->DevPrintf(("AFilePackGame::ReadCompressedFile(), Buffer is too small!"));
		return false;
	}

	BEGIN_LOCK(&m_csFR);

	m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
	*pdwBufferLen = m_fpPackageFile->read(pCompressedBuffer, 1, fileEntry.dwCompressedLength);
	Decrypt(pCompressedBuffer, fileEntry.dwCompressedLength);

	END_LOCK(&m_csFR);

	return true;
}

bool AFilePackGame::ResortEntries()
{
	int i;

	//	Build quick search table
	m_FileQuickSearchTab.clear();

	for (i = 0; i < m_iNumEntry; i++)
	{
		FILEENTRY* pFileEntry = &m_aFileEntries[i];
		auint32 idFile = a_MakeIDFromFileName(pFileEntry->szFileName);

		auto itr = m_FileQuickSearchTab.find((int)idFile);
		if (itr == m_FileQuickSearchTab.end())
		{
			m_FileQuickSearchTab[(int)idFile] = pFileEntry;
		}
		else
		{
			//	ID already exist, is there a ID collision ?
			FILEENTRY* pCheckEntry = itr->second;
			if (0 != ASys::StrCmpNoCase(pCheckEntry->szFileName, pFileEntry->szFileName))
			{
				//	id collision, add file to candidate array
				//	ASSERT(0 && "ID collision");
				m_aIDCollisionFiles.push_back(pFileEntry);
			}
			else
			{
				//	Same file was added twice ?!! Shouldn't happen !!
				ASSERT(0 && "Same file was added twice !!");
				return false;
			}
		}
	}

	return true;
}

void* AFilePackGame::OpenSharedFile(const char* szFileName, abyte** ppFileBuf, auint32* pdwFileLen)
{
	//	Get file entry
	FILEENTRY* pFileEntry = GetFileEntry(szFileName);
	if (!pFileEntry)
	{
		//		if( !strstr(szFileName, "Textures") && !strstr(szFileName, "Tex_") )
		//		{
		//			g_pAFramework->DevPrintf("AFilePackGame::OpenSharedFile, Failed to find file [%s] in package !", szFileName);
		//		}

		return NULL;
	}

	//	Allocate file data buffer
	abyte* pFileData = NULL;
	pFileData = (abyte*)malloc(pFileEntry->dwLength);

	if (!pFileData)
	{
		g_pAFramework->DevPrintf(("AFilePackGame::OpenSharedFile, Not enough memory!"));
		return NULL;
	}

	//	Read file data
	auint32 dwFileLen = pFileEntry->dwLength;
	if (!ReadFile(*pFileEntry, pFileData, &dwFileLen))
	{
		free(pFileData);

		g_pAFramework->DevPrintf("AFilePackGame::OpenSharedFile, Failed to read file data [%s] !", szFileName);
		return NULL;
	}

	//	Add it to shared file arrey
	SHAREDFILE* pFileItem = (SHAREDFILE*)malloc(sizeof(SHAREDFILE));
	if (!pFileItem)
	{
		free(pFileData);

		g_pAFramework->DevPrintf(("AFilePackGame::OpenSharedFile, Not enough memory!"));
		return NULL;
	}

	pFileItem->bCached = false;
	pFileItem->bTempMem = false;
	pFileItem->dwFileID = 0;
	pFileItem->dwFileLen = dwFileLen;
	pFileItem->iRefCnt = 1;
	pFileItem->pFileData = pFileData;
	pFileItem->pFileEntry = pFileEntry;

	*ppFileBuf = pFileData;
	*pdwFileLen = dwFileLen;

	return (void*)pFileItem;
}

//	Close a shared file
void AFilePackGame::CloseSharedFile(void* dwFileHandle)
{
	SHAREDFILE* pFileItem = (SHAREDFILE*)dwFileHandle;
	ASSERT(pFileItem && pFileItem->iRefCnt > 0);

	//	No cache file, release it
	if (pFileItem->bTempMem)
		ASSERT(false);
	else
		free(pFileItem->pFileData);

	free(pFileItem);
}

/*
	Safe Header section
	*/
bool AFilePackGame::LoadSafeHeader()
{
	m_fpPackageFile->seek(0, SEEK_SET);

	if (m_fpPackageFile->GetPackageFileSize() < sizeof(SAFEFILEHEADER))
	{
		m_bHasSafeHeader = false;
	}
	else
	{
		m_fpPackageFile->read(&m_safeHeader, sizeof(SAFEFILEHEADER), 1);
		if (m_safeHeader.tag1 == 0x4DCA23EF && m_safeHeader.tag2 == 0x56a089b7)
			m_bHasSafeHeader = true;
		else
			m_bHasSafeHeader = false;

		if (m_bHasSafeHeader)
			m_fpPackageFile->Phase2Open(m_safeHeader.offset);
	}

	m_fpPackageFile->seek(0, SEEK_SET);
	return true;
}