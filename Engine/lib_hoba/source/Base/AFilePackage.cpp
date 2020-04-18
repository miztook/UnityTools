#include "AFilePackage.h"
#include "AFramework.h"
#include "ASys.h"
#include "AFI.h"
#include "ATempMemBuffer.h"
#include "function.h"

#ifndef DISABLE_ZLIB

#include <zlib.h>

#endif

extern int	AFPCK_GUARDBYTE0;
extern int	AFPCK_GUARDBYTE1;
extern int	AFPCK_MASKDWORD;
extern int	AFPCK_CHECKMASK;

///////////////////////////////////////////////////////////////////////////
//
//	Local Types and Variables and Global variables
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
//
//	Local functions
//
///////////////////////////////////////////////////////////////////////////

int _CacheFileNameCompare(const void *arg1, const void *arg2)
{
	AFilePackage::CACHEFILENAME* pFile1 = *(AFilePackage::CACHEFILENAME**)arg1;
	AFilePackage::CACHEFILENAME* pFile2 = *(AFilePackage::CACHEFILENAME**)arg2;

	if (pFile1->dwFileID > pFile2->dwFileID)
		return 1;
	else if (pFile1->dwFileID < pFile2->dwFileID)
		return -1;
	else
		return 0;
}

#ifndef DISABLE_ZLIB

void* Zlib_User_Alloc(void* opaque, unsigned int items, unsigned int size)
{
	return malloc(size * items);
}

void Zlib_User_Free(void* opaque, void* ptr)
{
	free(ptr);
}

int Zlib_Compress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen, int level = Z_BEST_SPEED)
{
	z_stream stream;
	int err;

	stream.next_in = (Bytef*)source;
	stream.avail_in = (uInt)sourceLen;
#ifdef MAXSEG_64K
	/* Check for source > 64K on 16-bit machine: */
	if ((uLong)stream.avail_in != sourceLen)
		return Z_BUF_ERROR;
#endif
	stream.next_out = dest;
	stream.avail_out = (uInt)*destLen;
	if ((uLong)stream.avail_out != *destLen)
		return Z_BUF_ERROR;

	stream.zalloc = &Zlib_User_Alloc;	//0;
	stream.zfree = &Zlib_User_Free;		//0;
	stream.opaque = (voidpf)0;

	err = deflateInit(&stream, level);
	if (err != Z_OK) return err;

	err = deflate(&stream, Z_FINISH);
	if (err != Z_STREAM_END) {
		deflateEnd(&stream);
		if (err == Z_OK)
			return Z_BUF_ERROR;
		else
			return err;
	}
	*destLen = stream.total_out;

	err = deflateEnd(&stream);
	return err;
}

int Zlib_UnCompress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen)
{
	z_stream stream;
	int err;

	stream.next_in = (Bytef*)source;
	stream.avail_in = (uInt)sourceLen;
	/* Check for source > 64K on 16-bit machine: */
	if ((uLong)stream.avail_in != sourceLen) return Z_BUF_ERROR;

	stream.next_out = dest;
	stream.avail_out = (uInt)*destLen;
	if ((uLong)stream.avail_out != *destLen) return Z_BUF_ERROR;

	stream.zalloc = &Zlib_User_Alloc;  //0;
	stream.zfree = &Zlib_User_Free;   //0;

	err = inflateInit(&stream);
	if (err != Z_OK) return err;

	err = inflate(&stream, Z_FINISH);
	if (err != Z_STREAM_END) {
		inflateEnd(&stream);
		return err == Z_OK ? Z_BUF_ERROR : err;
	}
	*destLen = stream.total_out;

	err = inflateEnd(&stream);
	return err;
}

#endif

///////////////////////////////////////////////////////////////////////////
//
//	Implement of AFilePackage::directory
//
///////////////////////////////////////////////////////////////////////////

int
AFilePackage::directory::searchItemIndex(const char * name, int * pos) const
{
	int left, right, mid;
	left = 0;
	right = _list.size() - 1;
	mid = 0;
	while (left <= right)
	{
		mid = (left + right) / 2;
		int rst = ASys::StrCmpNoCase(name, _list[mid]->_name);
		if (rst < 0)
		{
			right = mid - 1;
		}
		else if (rst > 0)
		{
			left = mid + 1;
		}
		else
		{
			return mid;
		}
	}
	if (pos) *pos = mid;
	return -1;
}

AFilePackage::entry* AFilePackage::directory::SearchItem(const char * name) const
{
	int idx = searchItemIndex(name, NULL);
	if (idx < 0)
		return NULL;
	else
		return _list[idx];
}

int
AFilePackage::directory::RemoveItem(const char * name)
{
	int rst;
	rst = searchItemIndex(name, NULL);
	if (rst < 0) return -1;
	delete _list[rst];
	_list.erase(_list.begin() + rst);
	return 0;
}

AFilePackage::entry*
AFilePackage::directory::GetItem(int index)
{
	if (index < 0 || index >= (int)(_list.size())) return NULL;
	return _list[index];
}

int
AFilePackage::directory::AppendEntry(entry * item)
{
	int pos;
	if (searchItemIndex(item->_name, &pos) >= 0)
	{
		//???????
		return -1;
	}

	if (pos >= (int)(_list.size()))
	{
		_list.push_back(item);
	}
	else
	{
		int rst = ASys::StrCmpNoCase(item->_name, _list[pos]->_name);
		if (rst < 0)
		{
			_list.insert(_list.begin() + pos, item);
		}
		else
		{
			_list.insert(_list.begin() + (pos + 1), item);
		}
	}
	return 0;
}

int AFilePackage::directory::SearchEntry(const char * filename) const
{
	/*
	char name[MAX_PATH];
	strcpy(name, filename);
	char * tok;
	char *p = NULL;
	tok = Q_strtok(name, "\\", &p);
	entry * ent = this;
	while (tok)
	{
		char * next = Q_strtok(NULL, "\\", &p);
		entry * tmp = ent->SearchItem(tok);
		if (tmp == NULL) return -1;
		if (next)
		{
			if (tmp->IsContainer())
			{
				ent = tmp;
			}
			else
			{
				return -1;
			}
		}
		else
		{
			return tmp->GetIndex();
		}
		tok = next;
	}
	*/

	std::vector<AString> _tmpSplitArray;
	AString name = filename;
	name.Split("\\", _tmpSplitArray);

	const entry * ent = this;
	for (size_t i = 0; i < _tmpSplitArray.size(); ++i)
	{
		const char* tok = _tmpSplitArray[i];
		bool next = (i + 1 < _tmpSplitArray.size());

		const entry * tmp = ent->SearchItem(tok);
		if (tmp == NULL) return -1;
		if (next)
		{
			if (tmp->IsContainer())
			{
				ent = tmp;
			}
			else
			{
				return -1;
			}
		}
		else
		{
			return tmp->GetIndex();
		}
	}

	return -1;
}

int
AFilePackage::directory::clear()
{
	size_t i;
	for (i = 0; i < _list.size(); i++)
	{
		delete _list[i];
	}
	_list.clear();
	return 0;
}

AFilePackage::directory::~directory()
{
	clear();
}

///////////////////////////////////////////////////////////////////////////
//
//	Implement of AFilePackage
//
///////////////////////////////////////////////////////////////////////////

AFilePackage::AFilePackage()
{
	m_bHasChanged = false;
	m_bReadOnly = false;
	m_bUseShortName = false;
	m_fpPackageFile = NULL;
	m_dwSharedSize = 0;
	m_dwCacheSize = 0;
	m_szPckFileName[0] = '\0';

	m_bHasSafeHeader = false;
}

AFilePackage::~AFilePackage()
{
}

bool AFilePackage::LoadPack(const char* szPckPath, int nFileOffset)
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

	m_header.dwEntryOffset ^= AFPCK_MASKDWORD;

	if (m_header.guardByte0 != AFPCK_GUARDBYTE0 ||
		m_header.guardByte1 != AFPCK_GUARDBYTE1)
	{
		// corrput file
		g_pAFramework->DevPrintf("AFilePackage::Open(), GuardBytes corrupted [%s]", szPckPath);
		return false;
	}

	if (dwCompressEntryLen == 0)
	{
		ResortEntries();

		// now we move entry point to the end of the file so to keep old entries here
		if (m_bHasSafeHeader)
			m_header.dwEntryOffset = nFileOffset;

		return true;
	}

	//	Seek to entry list;
	ATempMemBuffer tempBuf1(sizeof(abyte) * dwCompressEntryLen);
	abyte* pEntryCompressBuf = (abyte*)tempBuf1.GetBuffer();
	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);
	m_fpPackageFile->read(pEntryCompressBuf, dwCompressEntryLen, 1);

	//	Create entries
	m_aFileEntries.resize(iNumFile);

	auint32 entryiesLen = iNumFile * sizeof(FILEENTRY);
	auint32 entryuncompresslen = entryiesLen;
	ATempMemBuffer tempBuf2(sizeof(abyte) * entryuncompresslen);
	abyte* pEntryUnCompressBuf = (abyte*)tempBuf2.GetBuffer();

	int ret = Uncompress(pEntryCompressBuf, dwCompressEntryLen, pEntryUnCompressBuf, &entryuncompresslen);
	if (ret != 0)
		return false;

	tempBuf1.Free();

	ASSERT(entryuncompresslen == entryiesLen);
	auint32 entrysize = sizeof(FILEENTRY);
	for (i = 0; i < iNumFile; i++)
	{
		FILEENTRY* pFileEntry = (FILEENTRY*)malloc(sizeof(FILEENTRY));
		memcpy(pFileEntry, &((FILEENTRY*)pEntryUnCompressBuf)[i], entrysize);
		NormalizeFileName(pFileEntry->szFileName, false);
		m_aFileEntries[i] = pFileEntry;
	}

	tempBuf2.Free();

	ResortEntries();

	// now we move entry point to the end of the file so to keep old entries here
	if (m_bHasSafeHeader)
		m_header.dwEntryOffset = nFileOffset;

	return true;
}

bool AFilePackage::InnerOpen(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bShortName)
{
	char szFullPckPath[MAX_PATH];

	strcpy(szFullPckPath, szPckPath);
	m_bUseShortName = bShortName;

	//	Save folder name
	ASSERT(szFolder);
	strncpy(m_szFolder, szFolder, MAX_PATH);
	m_szFolder[MAX_PATH - 1] = '\0';
	ASys::Strlwr(m_szFolder);
	NormalizeFileName(m_szFolder);

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

				g_pAFramework->DevPrintf("AFilePackage::Open(), Can not open file [%s]", szFullPckPath);
				return false;
			}
			m_bReadOnly = true;
		}

		if (m_fpPackageFile->GetPackageFileSize() <= sizeof(auint32))
		{
			g_pAFramework->DevPrintf(("AFilePackage::Open(), Package size < 4, Skip!"));
			return false;
		}

		strncpy(m_szPckFileName, szPckPath, MAX_PATH);
		m_szPckFileName[MAX_PATH - 1] = '\0';

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

		if (dwVersion == 0x00020003)
		{
			if (!LoadPack(szPckPath, nOffset))
			{
				g_pAFramework->DevPrintf(("AFilePackage::LoadPack(), Incorrect version!"));
			}
		}
		else
		{
			g_pAFramework->DevPrintf(("AFilePackage::Open(), Incorrect version!"));
			return false;
		}

		break;

	case CREATENEW:
		m_bReadOnly = false;
		m_fpPackageFile = new CPackageFile();

		if (!m_fpPackageFile->Open(szFullPckPath, "wb"))
		{
			delete m_fpPackageFile;
			m_fpPackageFile = NULL;

			g_pAFramework->DevPrintf("AFilePackage::Open(), Can not create file [%s]", szFullPckPath);
			return false;
		}
		strncpy(m_szPckFileName, szPckPath, MAX_PATH);
		m_szPckFileName[MAX_PATH - 1] = '\0'; 

		CreateSafeHeader();

		// Init header;
		memset(&m_header, 0, sizeof(FILEHEADER));
		m_header.guardByte0 = AFPCK_GUARDBYTE0;
		m_header.dwEntryOffset = sizeof(SAFEFILEHEADER);
		m_header.dwVersion = AFPCK_VERSION;
		m_header.dwFlags = 0;
		m_header.guardByte1 = AFPCK_GUARDBYTE1;
		strncpy(m_header.szDescription, AFPCK_COPYRIGHT_TAG, sizeof(m_header.szDescription));

		m_aFileEntries.clear();
		m_aFileEntryCache.clear();
		break;

	default:

		g_pAFramework->DevPrintf("AFilePackage::Open(), Unknown open mode [%d]!", mode);
		return false;
	}

	m_mode = mode;
	m_bHasChanged = false;
	m_dwSharedSize = 0;
	m_dwCacheSize = 0;

	return true;
}

bool AFilePackage::Open(const char* szPckPath, const char* szFolder, OPENMODE mode)
{
	return InnerOpen(szPckPath, szFolder, mode, true);
}

bool AFilePackage::Open(const char* szPckPath, OPENMODE mode)
{
	char szFolder[MAX_PATH] = { 0 };

	strncpy(szFolder, szPckPath, MAX_PATH);
	szFolder[MAX_PATH - 1] = '\0';

	if (szFolder[0] == '\0')
	{
		g_pAFramework->DevPrintf(("AFilePackage::Open(), can not open a null or empty file name!"));
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
		g_pAFramework->DevPrintf(("AFilePackage::Open(), only file with extension can be opened!"));
		return false;
	}

	*pext++ = '\\';
	*pext = '\0';

	return InnerOpen(szPckPath, szFolder, mode, false);
}

bool AFilePackage::Close()
{
	switch (m_mode)
	{
	case OPENEXIST:

		if (m_bHasChanged)
		{
			auint32 dwFileSize = m_header.dwEntryOffset;

			auint32 dwEntrySize = 0;
			if (!SaveEntries(&dwEntrySize))
				return false;
			dwFileSize += dwEntrySize;

			// Write file header here;
			m_header.dwEntryOffset ^= AFPCK_MASKDWORD;
			m_fpPackageFile->write(&m_header, sizeof(FILEHEADER), 1);
			m_header.dwEntryOffset ^= AFPCK_MASKDWORD;
			dwFileSize += sizeof(FILEHEADER);

			//add new version by linzihan
			auint32 dwEntryCompressLen = dwEntrySize;
			m_fpPackageFile->write(&dwEntryCompressLen, sizeof(auint32), 1);

			int iNumFile = (int)m_aFileEntries.size();
			m_fpPackageFile->write(&iNumFile, sizeof(int), 1);
			dwFileSize += sizeof(int);
			m_fpPackageFile->write(&m_header.dwVersion, sizeof(auint32), 1);
			dwFileSize += sizeof(auint32);

			m_fpPackageFile->SetPackageFileSize(dwFileSize);

			SaveSafeHeader();
			m_bHasChanged = false;
		}

		break;

	case CREATENEW:
	{
		auint32 dwEntrySize = 0;
		if (!SaveEntries(&dwEntrySize))
			return false;

		int iNumFile = (int)m_aFileEntries.size();

		// Write file header here;
		m_header.dwEntryOffset ^= AFPCK_MASKDWORD;
		m_fpPackageFile->write(&m_header, sizeof(FILEHEADER), 1);
		m_header.dwEntryOffset ^= AFPCK_MASKDWORD;

		//add new version by linzihan
		auint32 dwEntryCompressLen = dwEntrySize;
		m_fpPackageFile->write(&dwEntryCompressLen, sizeof(auint32), 1);

		m_fpPackageFile->write(&iNumFile, sizeof(int), 1);
		m_fpPackageFile->write(&m_header.dwVersion, sizeof(auint32), 1);

		SaveSafeHeader();
		break;
	}
	}

	if (m_fpPackageFile)
	{
		m_fpPackageFile->Close();
		delete m_fpPackageFile;
		m_fpPackageFile = NULL;
	}

	int iUnClosed = 0;

	//	Release entries
	for (size_t i = 0; i < m_aFileEntries.size(); i++)
	{
		if (m_aFileEntries[i])
		{
			free(m_aFileEntries[i]);
			m_aFileEntries[i] = NULL;
		}
	}

	//	Release entries cache
	for (size_t i = 0; i < m_aFileEntryCache.size(); i++)
	{
		FILEENTRYCACHE* pCache = m_aFileEntryCache[i];
		if (pCache)
		{
			if (pCache->pEntryCompressed)
			{
				free(pCache->pEntryCompressed);
				pCache->pEntryCompressed = NULL;
			}

			free(pCache);
			m_aFileEntryCache[i] = NULL;
		}
	}

	m_aFileEntries.clear();
	m_aFileEntryCache.clear();

	if (iUnClosed)
		g_pAFramework->DevPrintf("AFilePackage::Close(), %d file in package weren't closed !", iUnClosed);

	return true;
}

bool AFilePackage::Flush()
{
	switch (m_mode)
	{
	case OPENEXIST:

		if (m_bHasChanged)
		{
			m_fpPackageFile->Flush();
		}

		break;

	case CREATENEW:
	{
		m_fpPackageFile->Flush();
		break;
	}
	}

	return true;
}

//	Get rid of folder from file
void AFilePackage::GetRidOfFolder(const char* szInName, char* szOutName) const
{
	af_GetRelativePathNoBase(szInName, m_szFolder, szOutName);
}

bool AFilePackage::NormalizeFileName(char* szFileName)
{
	int i, nLength;

	nLength = strlen(szFileName);

	//	First we should unite the path seperator to '\'
	for (i = 0; i < nLength; i++)
	{
		if (szFileName[i] == '/')
			szFileName[i] = '\\';
	}

	//	Remove multi '\'
	for (i = 0; i < nLength - 1;)
	{
		if (szFileName[i] == '\\' && szFileName[i + 1] == '\\')
		{
			int j;
			for (j = i; j < nLength - 1; j++)
				szFileName[j] = szFileName[j + 1];

			szFileName[j] = '\0';
		}
		else
		{
			i++;
		}
	}

	//	Get rid of the preceding .\ string
	if (nLength > 2 && szFileName[0] == '.' && szFileName[1] == '\\')
	{
		for (i = 0; i < nLength - 2; i++)
			szFileName[i] = szFileName[i + 2];

		szFileName[i] = '\0';
	}

	//	Get rid of extra space at the tail of the string;
	nLength = strlen(szFileName);

	for (i = nLength - 1; i >= 0; i--)
	{
		if (szFileName[i] != ' ')
			break;
		else
			szFileName[i] = '\0';
	}

	return true;
}

//	Normalize file name
bool AFilePackage::NormalizeFileName(char* szFileName, bool bUseShortName) const
{
	if (!NormalizeFileName(szFileName))
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

static bool CheckFileEntryValid(AFilePackage::FILEENTRY* pFileEntry)
{
	if (pFileEntry->dwCompressedLength > MAX_FILE_PACKAGE)
	{
		g_pAFramework->DevPrintf("CheckFileEntryValid, file entry [%s]'s length is not correct!", pFileEntry->szFileName);
		return false;
	}

	return true;
}

bool AFilePackage::IsFileExist(const char* szFileName) const
{
	FILEENTRY FileEntry;
	return GetFileEntry(szFileName, &FileEntry);
}

bool AFilePackage::GetFileEntry(const char* szFileName, FILEENTRY* pFileEntry, int* pnIndex) const
{
	char szFindName[MAX_PATH];

	//	Normalize file name
	strncpy(szFindName, szFileName, MAX_PATH);
	szFindName[MAX_PATH - 1] = '\0';
	NormalizeFileName(szFindName, m_bUseShortName);

	memset(pFileEntry, 0, sizeof(FILEENTRY));

	int iEntry = m_directory.SearchEntry(szFindName);
	if (iEntry < 0)
		return false;

	if (!m_aFileEntries[iEntry])
		return false;

	*pFileEntry = *m_aFileEntries[iEntry];

	if (!CheckFileEntryValid(pFileEntry))
	{
		pFileEntry->dwLength = 0;
		pFileEntry->dwCompressedLength = 0;
	}

	if (pnIndex)
		*pnIndex = iEntry;

	return true;
}

bool AFilePackage::ReadFile(const char* szFileName, unsigned char* pFileBuffer, auint32* pdwBufferLen)
{
	FILEENTRY fileEntry;

	if (!GetFileEntry(szFileName, &fileEntry))
	{
		g_pAFramework->DevPrintf("AFilePackage::ReadFile(), Can not find file entry [%s]!", szFileName);
		return false;
	}

	return ReadFile(fileEntry, pFileBuffer, pdwBufferLen);
}

bool AFilePackage::ReadFile(FILEENTRY& fileEntry, unsigned char* pFileBuffer, auint32 * pdwBufferLen)
{
	if (*pdwBufferLen < fileEntry.dwLength)
	{
		g_pAFramework->DevPrintf(("AFilePackage::ReadFile(), Buffer is too small!"));
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

		m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
		m_fpPackageFile->read(pBuffer, fileEntry.dwCompressedLength, 1);

		if (0 != Uncompress(pBuffer, fileEntry.dwCompressedLength, pFileBuffer, &dwFileLength))
		{
			return false;
		}

		//uncompress(pFileBuffer, &dwFileLength, m_pBuffer, fileEntry.dwCompressedLength);

		*pdwBufferLen = dwFileLength;
	}
	else
	{
		m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
		m_fpPackageFile->read(pFileBuffer, fileEntry.dwLength, 1);

		*pdwBufferLen = fileEntry.dwLength;
	}

	return true;
}

bool AFilePackage::ReadCompressedFile(const char* szFileName, unsigned char* pCompressedBuffer, auint32* pdwBufferLen)
{
	FILEENTRY fileEntry;

	if (!GetFileEntry(szFileName, &fileEntry))
	{
		g_pAFramework->DevPrintf("AFilePackage::ReadCompressedFile(), Can not find file entry [%s]!", szFileName);
		return false;
	}

	return ReadCompressedFile(fileEntry, pCompressedBuffer, pdwBufferLen);
}

bool AFilePackage::ReadCompressedFile(FILEENTRY& fileEntry, unsigned char* pCompressedBuffer, auint32 * pdwBufferLen)
{
	if (*pdwBufferLen < fileEntry.dwCompressedLength)
	{
		g_pAFramework->DevPrintf(("AFilePackage::ReadCompressedFile(), Buffer is too small!"));
		return false;
	}

	m_fpPackageFile->seek(fileEntry.dwOffset, SEEK_SET);
	*pdwBufferLen = m_fpPackageFile->read(pCompressedBuffer, 1, fileEntry.dwCompressedLength);

	return true;
}

bool AFilePackage::AppendFile(const char* szFileName, unsigned char* pFileBuffer, auint32 dwFileLength, bool bCompress)
{
	// We should use a function to check whether szFileName has been added into the package;
	if (m_bReadOnly)
	{
		g_pAFramework->DevPrintf(("AFilePackage::AppendFile(), Read only package, can not append!"));
		return false;
	}

	FILEENTRY fileEntry;
	if (GetFileEntry(szFileName, &fileEntry))
	{
		g_pAFramework->DevPrintf("AFilePackage::AppendFile(), file entry [%s] already exist!", szFileName);
		return false;
	}

	auint32 dwCompressedLength = dwFileLength;
	if (bCompress)
	{
		//	Compress the file
		abyte* pBuffer = (abyte*)malloc(dwFileLength);
		if (!pBuffer)
			return false;

		if (0 != Compress(pFileBuffer, dwFileLength, pBuffer, &dwCompressedLength))
		{
			//compress error, so use uncompressed format
			dwCompressedLength = dwFileLength;
		}

		//compress2(m_pBuffer, &dwCompressedLength, pFileBuffer, dwFileLength, 1);

		if (dwCompressedLength < dwFileLength)
		{
			if (!AppendFileCompressed(szFileName, pBuffer, dwFileLength, dwCompressedLength))
			{
				free(pBuffer);
				return false;
			}
		}
		else
		{
			if (!AppendFileCompressed(szFileName, pFileBuffer, dwFileLength, dwFileLength))
			{
				free(pBuffer);
				return false;
			}
		}

		free(pBuffer);
	}
	else
	{
		if (!AppendFileCompressed(szFileName, pFileBuffer, dwFileLength, dwFileLength))
			return false;
	}

	return true;
}

bool AFilePackage::AppendFileCompressed(const char* szFileName, unsigned char* pCompressedFileBuffer, auint32 dwFileLength, auint32 dwCompressedLength)
{
	FILEENTRY* pEntry = (FILEENTRY*)malloc(sizeof(FILEENTRY));
	if (!pEntry)
	{
		g_pAFramework->DevPrintf(("AFilePackage::AppendFile(), Not enough memory!"));
		return false;
	}

	//	Normalize file name
	char szSavedFileName[MAX_PATH];
	strcpy(szSavedFileName, szFileName);
	NormalizeFileName(szSavedFileName, m_bUseShortName);
	szFileName = szSavedFileName;

	//	Store this file;
	strncpy(pEntry->szFileName, szFileName, MAX_PATH);
	pEntry->szFileName[MAX_PATH - 1] = '\0';
	pEntry->dwOffset = m_header.dwEntryOffset;
	pEntry->dwLength = dwFileLength;
	pEntry->dwCompressedLength = dwCompressedLength;
	pEntry->iAccessCnt = 0;
	if (!CheckFileEntryValid(pEntry))
	{
		free(pEntry);
		g_pAFramework->DevPrintf(("AFilePackage::AppendFile(), Invalid File Entry!"));
		return false;
	}

	m_aFileEntries.push_back(pEntry);

	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);

	//	We write the compressed buffer into the disk;
	m_fpPackageFile->write(pCompressedFileBuffer, dwCompressedLength, 1);
	m_header.dwEntryOffset += dwCompressedLength;

	InsertFileToDir(szFileName, (int)m_aFileEntries.size() - 1);
	m_bHasChanged = true;

	return true;
}

bool AFilePackage::RemoveFile(const char* szFileName)
{
	if (m_bReadOnly)
	{
		g_pAFramework->DevPrintf(("AFilePackage::RemoveFile(), Read only package, can not remove file!"));
		return false;
	}

	FILEENTRY Entry;
	int	nIndex;

	if (!GetFileEntry(szFileName, &Entry, &nIndex))
	{
		g_pAFramework->DevPrintf("AFilePackage::RemoveFile(), Can not find file %s", szFileName);
		return false;
	}

	FILEENTRY* pEntry = m_aFileEntries[nIndex];
	RemoveFileFromDir(pEntry->szFileName);

	//	Added by dyx on 2013.10.14. Now we only delete entry object and leave a NULL at it's position
	//	in m_aFileEntries, this is in order that the entry indices recoreded in file items of m_directory
	//	can still be valid and needn't updating.
	free(pEntry);
	m_aFileEntries[nIndex] = NULL;

	FILEENTRYCACHE* pEntryCache = m_aFileEntryCache[nIndex];
	if (pEntryCache)
	{
		if (pEntryCache->pEntryCompressed)
			free(pEntryCache->pEntryCompressed);

		free(pEntryCache);
		m_aFileEntryCache[nIndex] = NULL;
	}

	//	ResortEntries();

	m_bHasChanged = true;
	return true;
}

bool AFilePackage::ReplaceFile(const char* szFileName, unsigned char* pFileBuffer, auint32 dwFileLength, bool bCompress)
{
	//	We only add a new file copy at the end of the file part, and modify the
	//	file entry point to that file body;
	auint32 dwCompressedLength = dwFileLength;

	if (bCompress)
	{
		//	Try to compress the file
		abyte* pBuffer = (abyte*)malloc(dwFileLength);
		if (!pBuffer)
			return false;

		if (0 != Compress(pFileBuffer, dwFileLength, pBuffer, &dwCompressedLength))
		{
			//compress error, so use uncompressed format
			dwCompressedLength = dwFileLength;
		}

		//compress2(m_pBuffer, &dwCompressedLength, pFileBuffer, dwFileLength, 1);

		if (dwCompressedLength < dwFileLength)
		{
			if (!ReplaceFileCompressed(szFileName, pBuffer, dwFileLength, dwCompressedLength))
			{
				free(pBuffer);
				return false;
			}
		}
		else
		{
			if (!ReplaceFileCompressed(szFileName, pFileBuffer, dwFileLength, dwFileLength))
			{
				free(pBuffer);
				return false;
			}
		}

		free(pBuffer);
	}
	else
	{
		if (!ReplaceFileCompressed(szFileName, pFileBuffer, dwFileLength, dwFileLength))
			return false;
	}

	return true;
}

bool AFilePackage::ReplaceFileCompressed(const char * szFileName, unsigned char* pCompressedBuffer, auint32 dwFileLength, auint32 dwCompressedLength)
{
	if (m_bReadOnly)
	{
		g_pAFramework->DevPrintf(("AFilePackage::ReplaceFileCompressed(), Read only package, can not replace!"));
		return false;
	}

	FILEENTRY Entry;
	int	nIndex;

	if (!GetFileEntry(szFileName, &Entry, &nIndex))
	{
		g_pAFramework->DevPrintf("AFilePackage::ReplaceFile(), Can not find file %s", szFileName);
		return false;
	}

	Entry.dwOffset = m_header.dwEntryOffset;
	Entry.dwLength = dwFileLength;
	Entry.dwCompressedLength = dwCompressedLength;
	if (!CheckFileEntryValid(&Entry))
	{
		//
		g_pAFramework->DevPrintf(("AFilePackage::ReplaceFile(), Invalid File Entry"));
		return false;
	}

	FILEENTRY* pEntry = m_aFileEntries[nIndex];
	ASSERT(pEntry);
	// modify this file entry to point to the new file body;
	pEntry->dwOffset = m_header.dwEntryOffset;
	pEntry->dwLength = dwFileLength;
	pEntry->dwCompressedLength = dwCompressedLength;

	//FILEENTRYCACHE* pEntryCache = m_aFileEntryCache[nIndex];
	//auint32 dwCompressedSize = sizeof(FILEENTRY);
	//abyte * pBuffer = (abyte *)a_malloc(sizeof(FILEENTRY));
	//int nRet = Compress((unsigned char*)pEntry, sizeof(FILEENTRY), pBuffer, &dwCompressedSize);
	//if( nRet != 0 || dwCompressedSize >= sizeof(FILEENTRY) )
	//{
	//	dwCompressedSize = sizeof(FILEENTRY);
	//	memcpy(pBuffer, pEntry, sizeof(FILEENTRY));
	//}
	//pEntryCache->dwCompressedLength = dwCompressedSize;
	//pEntryCache->pEntryCompressed = (abyte *)a_realloc(pEntryCache->pEntryCompressed, dwCompressedSize);
	//memcpy(pEntryCache->pEntryCompressed, pBuffer, dwCompressedSize);
	//a_free(pBuffer);

	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);

	//	We write the compressed buffer into the disk;
	m_fpPackageFile->write(pCompressedBuffer, dwCompressedLength, 1);
	m_header.dwEntryOffset += dwCompressedLength;

	m_bHasChanged = true;
	return true;
}

bool AFilePackage::RemoveFileFromDir(const char * filename)
{
	char szFindName[MAX_PATH];
	size_t nLength, i;
	nLength = strlen(szFindName);
	for (i = 0; i < nLength; i++)
	{
		if (szFindName[i] == '/')
			szFindName[i] = '\\';
	}

	/*
	char *name, *tok, *p;

	strncpy(szFindName, filename, MAX_PATH);
	ASys::Strlwr(szFindName);
	name = szFindName;

	tok = Q_strtok(name, "\\", &p);

	directory * dir = &m_directory;
	while (tok)
	{
		entry * ent = dir->SearchItem(tok);
		if (ent == NULL) return false; //entry not found
		char * next = Q_strtok(NULL, "\\", &p);
		if (next == NULL)
		{
			if (!ent->IsContainer())
			{
				dir->RemoveItem(tok);
				return true;
			}
			return false;
		}
		else
		{
			if (ent->IsContainer())
				dir = (directory *)ent;
			else
				return false;
		}
		tok = next;
	}
	*/

	AString name = szFindName;
	std::vector<AString> _tmpSplitArray;
	name.Split("\\", _tmpSplitArray);

	directory * dir = &m_directory;
	for (size_t i = 0; i < _tmpSplitArray.size(); ++i)
	{
		const char* tok = _tmpSplitArray[i];
		bool next = (i + 1 < _tmpSplitArray.size());

		entry * ent = dir->SearchItem(tok);
		if (ent == NULL)
			return false; //entry not found
		if (!next)
		{
			if (!ent->IsContainer())
			{
				dir->RemoveItem(tok);
				return true;
			}
			return false;
		}
		else
		{
			if (ent->IsContainer())
				dir = (directory *)ent;
			else
				return false;
		}
	}
	return false;
}

AFilePackage::directory * AFilePackage::GetDirEntry(const char * szPath)
{
	char szFindName[MAX_PATH];
	size_t nLength, i;

	strncpy(szFindName, szPath, MAX_PATH);
	ASys::Strlwr(szFindName);
	nLength = strlen(szFindName);
	for (i = 0; i < nLength; i++)
	{
		if (szFindName[i] == '/')
			szFindName[i] = '\\';
	}

	/*
	char *name, *tok, *p;
	name = szFindName;

	tok = Q_strtok(name, "\\", &p);
	directory * dir = &m_directory;
	while (tok && *tok)
	{
		entry * ent = dir->SearchItem(tok);
		if (ent == NULL) return NULL; //entry not found
		if (!ent->IsContainer()) return NULL;
		tok = Q_strtok(NULL, "\\", &p);
		dir = (directory*)ent;
	}
	*/

	AString name = szFindName;
	std::vector<AString> _tmpSplitArray;
	name.Split("\\", _tmpSplitArray);

	directory * dir = &m_directory;
	for (size_t i = 0; i < _tmpSplitArray.size(); ++i)
	{
		const char* tok = _tmpSplitArray[i];

		entry * ent = dir->SearchItem(tok);
		if (ent == NULL)
			return NULL; //entry not found
		if (!ent->IsContainer())
			return NULL;
		dir = (directory*)ent;
	}

	return dir;
}

bool AFilePackage::InsertFileToDir(const char * filename, int index)
{
	char szFindName[MAX_PATH];
	size_t nLength, i;
	strncpy(szFindName, filename, MAX_PATH);
	ASys::Strlwr(szFindName);
	nLength = strlen(szFindName);
	for (i = 0; i < nLength; i++)
	{
		if (szFindName[i] == '/')
			szFindName[i] = '\\';
	}

	/*
	char *name, *tok, *p;
	name = szFindName;

	tok = Q_strtok(name, "\\", &p);
	directory * dir = &m_directory;
	while (tok)
	{
		char * next = Q_strtok(NULL, "\\", &p);
		entry * ent = dir->SearchItem(tok);
		if (next)
		{
			if (ent == NULL)
			{
				directory *tmp = new directory(tok);
				dir->AppendEntry(tmp);
				dir = tmp;
			}
			else
			{
				ASSERT(ent->IsContainer());
				if (!ent->IsContainer())
				{
					g_pAFramework->DevPrintf("AFilePackage::InsertFileToDir(), Directory conflict:%s", filename);
					return false;
				}
				dir = (directory*)ent;
			}
		}
		else
		{
			if (ent == NULL)
			{
				dir->AppendEntry(new file(tok, index));
			}
			else
			{
				ASSERT(!ent->IsContainer());
				if (ent->IsContainer())
					return false;
				else
					((file*)ent)->SetIndex(index);
				break;
			}
		}
		tok = next;
	}
	*/

	AString name = szFindName;
	std::vector<AString> _tmpSplitArray;
	name.Split("\\", _tmpSplitArray);

	directory * dir = &m_directory;
	for (size_t i = 0; i < _tmpSplitArray.size(); ++i)
	{
		const char* tok = _tmpSplitArray[i];
		bool next = (i + 1 < _tmpSplitArray.size());

		entry * ent = dir->SearchItem(tok);
		if (next)
		{
			if (ent == NULL)
			{
				directory *tmp = new directory(tok);
				dir->AppendEntry(tmp);
				dir = tmp;
			}
			else
			{
				ASSERT(ent->IsContainer());
				if (!ent->IsContainer())
				{
					g_pAFramework->DevPrintf("AFilePackage::InsertFileToDir(), Directory conflict:%s", filename);
					return false;
				}
				dir = (directory*)ent;
			}
		}
		else
		{
			if (ent == NULL)
			{
				dir->AppendEntry(new file(tok, index));
			}
			else
			{
				ASSERT(!ent->IsContainer());
				if (ent->IsContainer())
					return false;
				else
					((file*)ent)->SetIndex(index);
				break;
			}
		}
	}

	return true;
}

// ?????????????
bool AFilePackage::ResortEntries()
{
	m_directory.clear();
	for (size_t i = 0; i < m_aFileEntries.size(); i++)
	{
		if (m_aFileEntries[i])
		{
			InsertFileToDir(m_aFileEntries[i]->szFileName, i);
		}
	}
	return true;
}

void* AFilePackage::OpenSharedFile(const char* szFileName, abyte** ppFileBuf, auint32* pdwFileLen)
{
	//	Get file entry
	FILEENTRY FileEntry;
	int iEntryIndex;
	if (!GetFileEntry(szFileName, &FileEntry, &iEntryIndex))
	{
		g_pAFramework->DevPrintf("AFilePackage::OpenSharedFile, Failed to find file [%s] in package !", szFileName);
		return NULL;
	}

	ASSERT(m_aFileEntries[iEntryIndex]);

	//	Allocate file data buffer
	abyte* pFileData = (abyte*)malloc(FileEntry.dwLength);

	if (!pFileData)
	{
		g_pAFramework->DevPrintf(("AFilePackage::OpenSharedFile, Not enough memory!"));
		return NULL;
	}

	//	Read file data
	auint32 dwFileLen = FileEntry.dwLength;
	if (!ReadFile(FileEntry, pFileData, &dwFileLen))
	{
		free(pFileData);

		g_pAFramework->DevPrintf("AFilePackage::OpenSharedFile, Failed to read file data [%s] !", szFileName);
		return NULL;
	}

	//	Add it to shared file arrey
	SHAREDFILE* pFileItem = (SHAREDFILE*)malloc(sizeof(SHAREDFILE));
	if (!pFileItem)
	{
		free(pFileData);

		g_pAFramework->DevPrintf(("AFilePackage::OpenSharedFile, Not enough memory!"));
		return NULL;
	}

	pFileItem->bCached = false;
	pFileItem->bTempMem = false;
	pFileItem->dwFileID = 0;
	pFileItem->dwFileLen = dwFileLen;
	pFileItem->iRefCnt = 1;
	pFileItem->pFileData = pFileData;
	pFileItem->pFileEntry = m_aFileEntries[iEntryIndex];

	//	pFileItem->pFileEntry->iAccessCnt++;

	*ppFileBuf = pFileData;
	*pdwFileLen = dwFileLen;

	return (void*)pFileItem;
}

//	Close a shared file
void AFilePackage::CloseSharedFile(void* dwFileHandle)
{
	SHAREDFILE* pFileItem = (SHAREDFILE*)dwFileHandle;
	ASSERT(pFileItem && pFileItem->iRefCnt > 0);

	//	No cache file, release it
	free(pFileItem->pFileData);

	free(pFileItem);
}

/*
	Compress a data buffer
	pFileBuffer			IN		buffer contains data to be compressed
	dwFileLength		IN		the bytes in buffer to be compressed
	pCompressedBuffer	OUT		the buffer to hold the compressed data
	pdwCompressedLength IN/OUT	the compressed buffer size when used as input
	when out, it contains the real compressed length

	RETURN: 0,		ok
	-1,		dest buffer is too small
	-2,		unknown error
	*/
int AFilePackage::Compress(const unsigned char* pFileBuffer, auint32 dwFileLength, unsigned char* pCompressedBuffer, auint32 * pdwCompressedLength)
{
#ifndef DISABLE_ZLIB
	uLongf dwCompressedLength = dwFileLength;
	//int nRet = compress2(pCompressedBuffer, &dwCompressedLength, pFileBuffer, dwFileLength, 1);
	int nRet = Zlib_Compress(pCompressedBuffer, &dwCompressedLength, pFileBuffer, dwFileLength, 1);
	*pdwCompressedLength = (auint32)dwCompressedLength;
	if (Z_OK == nRet)
		return 0;

	if (Z_BUF_ERROR == nRet)
		return -1;
	else
		return -2;
#else
	auint32 dwCompressedLength = dwFileLength;
	memcpy(pCompressedBuffer, pFileBuffer, dwFileLength);
	*pdwCompressedLength = (auint32)dwCompressedLength;
	return 0;
#endif
}

/*
	Uncompress a data buffer
	pCompressedBuffer	IN		buffer contains compressed data to be uncompressed
	dwCompressedLength	IN		the compressed data size
	pFileBuffer			OUT		the uncompressed data buffer
	pdwFileLength		IN/OUT	the uncompressed data buffer size as input
	when out, it is the real uncompressed data length

	RETURN: 0,		ok
	-1,		dest buffer is too small
	-2,		unknown error
	*/
int AFilePackage::Uncompress(const unsigned char* pCompressedBuffer, auint32 dwCompressedLength, unsigned char* pFileBuffer, auint32* pdwFileLength)
{
#ifndef DISABLE_ZLIB
	uLongf dwFileLength = (*pdwFileLength);
	int nRet = Zlib_UnCompress(pFileBuffer, &dwFileLength, pCompressedBuffer, dwCompressedLength);
	*pdwFileLength = (auint32)dwFileLength;
	if (Z_OK == nRet)
		return 0;

	if (Z_BUF_ERROR == nRet)
		return -1;
	else
		return -2;
#else
	auint32 dwFileLength = dwCompressedLength;
	memcpy(pFileBuffer, pCompressedBuffer, dwFileLength);
	*pdwFileLength = dwFileLength;
	return 0;
#endif
}

/*
	Safe Header section
	*/
bool AFilePackage::LoadSafeHeader()
{
	m_fpPackageFile->seek(0, SEEK_SET);

	m_fpPackageFile->read(&m_safeHeader, sizeof(SAFEFILEHEADER), 1);
	if (m_safeHeader.tag1 == 0x4DCA23EF && m_safeHeader.tag2 == 0x56a089b7)
		m_bHasSafeHeader = true;
	else
		m_bHasSafeHeader = false;

	if (m_bHasSafeHeader)
		m_fpPackageFile->Phase2Open(m_safeHeader.offset);

	m_fpPackageFile->seek(0, SEEK_SET);
	return true;
}

bool AFilePackage::CreateSafeHeader()
{
	m_bHasSafeHeader = true;

	m_safeHeader.tag1 = 0x4DCA23EF;
	m_safeHeader.tag2 = 0x56a089b7;
	m_safeHeader.offset = 0;

	return true;
}

bool AFilePackage::SaveSafeHeader()
{
	if (m_bHasSafeHeader)
	{
		m_fpPackageFile->seek(0, SEEK_END);
		m_safeHeader.offset = m_fpPackageFile->tell();

		m_fpPackageFile->seek(0, SEEK_SET);
		m_fpPackageFile->write(&m_safeHeader, sizeof(SAFEFILEHEADER), 1);
		m_fpPackageFile->seek(0, SEEK_SET);
	}

	return true;
}

#define ENTRY_BUFFER_SIZE		(1024 * 1024)

bool AFilePackage::SaveEntries(auint32 * pdwEntrySize)
{
	int iNumFile = m_aFileEntries.size();
	int i;

	//	Added by dyx, 2013.10.14. Remove nullptr entries at first, see RemoveFile for detail.
	for (int i = iNumFile - 1; i >= 0; i--)
	{
		FILEENTRY* pEntry = m_aFileEntries[i];
		if (!pEntry)
		{
			m_aFileEntries.erase(m_aFileEntries.begin() + i);
			ASSERT(!m_aFileEntryCache[i]);
			m_aFileEntryCache.erase(m_aFileEntryCache.begin() + i);
		}
	}

	iNumFile = m_aFileEntries.size();

	auint32 dwEntitySize = sizeof(FILEENTRY);
	auint32 dwTotalSize = dwEntitySize * iNumFile;
	auint32 dwBufferUsed = 0;
	// Rewrite file entries and file header here;
	m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);
	if (iNumFile == 0)
		return true;

	ATempMemBuffer tempBuf1(sizeof(abyte) * dwTotalSize);
	abyte* pEntryBuffer = (abyte*)tempBuf1.GetBuffer();
	if (NULL == pEntryBuffer)
		return false;

	for (i = 0; i < iNumFile; i++)
	{
		FILEENTRY* pEntry = m_aFileEntries[i];
		memcpy(&pEntryBuffer[dwBufferUsed], pEntry, dwEntitySize);
		dwBufferUsed += dwEntitySize;
	}

	auint32 dwPreCompressBufferLen = dwTotalSize * 2;
	ATempMemBuffer tempBuf2(sizeof(abyte) * dwPreCompressBufferLen);
	abyte * pCompressBuffer = (abyte*)tempBuf2.GetBuffer();
	auint32 prebuflen = dwPreCompressBufferLen;
	int ret = Compress(pEntryBuffer, dwTotalSize, pCompressBuffer, &dwPreCompressBufferLen);
	if (ret != 0)
	{
		g_pAFramework->DevPrintf("compress pack file entry  error");
		return false;
	}

	ASSERT(dwPreCompressBufferLen <= prebuflen);

	// flush entry buffer;
	m_fpPackageFile->write(pCompressBuffer, dwPreCompressBufferLen, 1);
	dwBufferUsed = 0;

	tempBuf1.Free();
	tempBuf2.Free();
	pEntryBuffer = NULL;
	pCompressBuffer = NULL;

	if (pdwEntrySize)
		*pdwEntrySize = dwPreCompressBufferLen;

	return true;

	//auint32 dwTotalSize = 0;

	//int iNumFile = m_aFileEntries.GetSize();
	//int i;

	////	Added by dyx, 2013.10.14. Remove NULL entries at first, see RemoveFile for detail.
	//for (i=iNumFile-1; i >= 0; i--)
	//{
	//	FILEENTRY* pEntry = m_aFileEntries[i];
	//	if (!pEntry)
	//	{
	//		m_aFileEntries.RemoveAt(i);
	//		ASSERT(!m_aFileEntryCache[i]);
	//		m_aFileEntryCache.RemoveAt(i);
	//	}
	//}

	//iNumFile = m_aFileEntries.GetSize();

	//auint32 dwBufferUsed = 0;
	//abyte * pEntryBuffer = new abyte[ENTRY_BUFFER_SIZE];
	//if( NULL == pEntryBuffer )
	//	return false;

	//// Rewrite file entries and file header here;
	//m_fpPackageFile->seek(m_header.dwEntryOffset, SEEK_SET);
	//for(i=0; i < iNumFile; i++)
	//{
	//	//FILEENTRY* pEntry = m_aFileEntries[i];
	//	FILEENTRYCACHE* pEntryCache = m_aFileEntryCache[i];

	//	if( dwBufferUsed + sizeof(FILEENTRY) + sizeof(auint32) + sizeof(auint32) > ENTRY_BUFFER_SIZE )
	//	{
	//		// flush entry buffer;
	//		m_fpPackageFile->write(pEntryBuffer, dwBufferUsed, 1);
	//		dwBufferUsed = 0;
	//	}

	//	auint32 dwCompressedSize = pEntryCache->dwCompressedLength;

	//	dwCompressedSize ^= AFPCK_MASKDWORD;
	//	memcpy(&pEntryBuffer[dwBufferUsed], &dwCompressedSize, sizeof(auint32));
	//	dwBufferUsed += sizeof(auint32);

	//	dwCompressedSize ^= AFPCK_CHECKMASK;
	//	memcpy(&pEntryBuffer[dwBufferUsed], &dwCompressedSize, sizeof(auint32));
	//	dwBufferUsed += sizeof(auint32);

	//	memcpy(&pEntryBuffer[dwBufferUsed], pEntryCache->pEntryCompressed, pEntryCache->dwCompressedLength);
	//	dwBufferUsed += pEntryCache->dwCompressedLength;
	//
	//	dwTotalSize += sizeof(auint32) + sizeof(auint32) + pEntryCache->dwCompressedLength;
	//}

	//if( dwBufferUsed )
	//{
	//	// flush entry buffer;
	//	m_fpPackageFile->write(pEntryBuffer, dwBufferUsed, 1);
	//	dwBufferUsed = 0;
	//}

	//delete [] pEntryBuffer;
	//pEntryBuffer = NULL;

	//if( pdwEntrySize )
	//	*pdwEntrySize = dwTotalSize;
	//return true;
}