#ifndef _AFILEPACKGAME_H_
#define _AFILEPACKGAME_H_

#include "AString.h"
#include "AFilePackBase.h"
#include "ASysSync.h"
#include <unordered_map>
#include <vector>

class AFilePackGame : public AFilePackBase
{
public:		//	Types

	enum OPENMODE
	{
		OPENEXIST = 0,
		CREATENEW = 1
	};

	struct FILEENTRY
	{
		char*	szFileName;				//	The file name of this entry; this may contain a path;
		auint32	dwOffset;				//	The offset from the beginning of the package file;
		auint32	dwLength;				//	The length of this file;
		auint32	dwCompressedLength;		//	The compressed data length;
	};

	struct FILEHEADER
	{
		auint32	guardByte0;				//	0xabcdefab
		auint32	dwVersion;				//	Composed by two word version, major part and minor part;
		auint32	dwEntryOffset;			//	The entry list offset from the beginning;
		auint32	dwFlags;				//	package flags. the highest bit means the encrypt state;
		char	szDescription[252];		//	Description
		auint32	guardByte1;				//	0xffeeffee
	};

	//	Share read file item
	struct SHAREDFILE
	{
		auint32	dwFileID;		//	File ID
		bool	bCached;		//	Cached flag
		bool	bTempMem;		//	true, use temporary memory alloctor
		int		iRefCnt;		//	Reference counter
		abyte*	pFileData;		//	File data buffer
		auint32	dwFileLen;		//	File data length

		FILEENTRY*	pFileEntry;	//	Point to file entry
	};

	//	Cache file name
	struct CACHEFILENAME
	{
		AString	strFileName;	//	File name
		auint32	dwFileID;		//	File ID
	};

	//	Safe Header
	struct SAFEFILEHEADER
	{
		auint32	tag1;			//	tag1 of safe header, current it is 0x4DCA23EF
		auint32	offset;			//	offset of real entries
		auint32	tag2;			//	tag2 of safe header, current it is 0x56a089b7
	};

	//	Name buffer info
	struct NAMEBUFFER
	{
		char*	pBuffer;
		auint32	dwLength;		//	Buffer length
		auint32	dwOffset;		//	Current offset
	};

	friend class AFilePackMan;

	typedef std::unordered_map<int, FILEENTRY*> FileEntryTable;

private:

	bool		m_bReadOnly;
	bool		m_bUseShortName;	//	Get rid of m_szFolder in each file name

	FILEHEADER	m_header;
	OPENMODE	m_mode;

	FILEENTRY*				m_aFileEntries;			//	File entries
	int						m_iNumEntry;			//	Number of file entry
	FileEntryTable			m_FileQuickSearchTab;	//	Quick search table when OM_ID_SEARCH is set
	std::vector<FILEENTRY*>	m_aIDCollisionFiles;	//	ID collision file
	std::vector<NAMEBUFFER>		m_aNameBufs;			//	Entry file name buffer

	//FIX ME
	lock_type		m_csFR;					//	File Read lock

	CPackageFile* m_fpPackageFile;
	char		m_szPckFileName[MAX_PATH];	// the package file path
	char		m_szFolder[MAX_PATH];	// the folder path (in lowercase) the package packs.

	bool			m_bHasSafeHeader;	// flag indicates whether the package contains a safe header
	SAFEFILEHEADER	m_safeHeader;		// Safe file header

public:

	AFilePackGame();
	virtual ~AFilePackGame();

	bool Open(const char* szPckPath, OPENMODE mode, bool bEncrypt = false);
	bool Open(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt = false);
	virtual bool Close();

	//	Sort the file entry list;
	bool ResortEntries();

	bool ReadFile(const char* szFileName, unsigned char* pFileBuffer, auint32* pdwBufferLen);
	bool ReadFile(FILEENTRY& fileEntry, unsigned char* pFileBuffer, auint32* pdwBufferLen);
	bool ReadCompressedFile(FILEENTRY& fileEntry, unsigned char* pCompressedBuffer, auint32 * pdwBufferLen);

	// Find a file entry;
	// return true if found, false if not found;
	FILEENTRY* GetFileEntry(const char* szFileName) const;
	const FILEENTRY* GetFileEntryByIndex(int nIndex) const { return &m_aFileEntries[nIndex]; }
	//	Find a file in ID collision candidate array
	FILEENTRY* FindIDCollisionFile(const char* szFileName) const;

	//	Open a shared file
	virtual void* OpenSharedFile(const char* szFileName, abyte** ppFileBuf, auint32* pdwFileLen) override;
	//	Close a shared file
	virtual void CloseSharedFile(void* dwFileHandle) override;

	int GetFileNumber() const { return m_iNumEntry; }
	FILEHEADER GetFileHeader() const { return m_header; }
	virtual const char* GetFolder() const override { return m_szFolder; }
	const char* GetPckFileName() { return m_szPckFileName; }
	virtual bool IsFileExist(const char* szFileName) const override;

	auint32 GetPackageFileSize() { return m_fpPackageFile->GetPackageFileSize(); }

protected:	//	Attributes

protected:	//	Operations

	//	Normalize file name
	bool NormalizeFileName(char* szFileName, bool bUseShortName) const;
	//	Get rid of folder from file
	void GetRidOfFolder(const char* szInName, char* szOutName) const;

	bool LoadPack(const char* szPckPath, bool  bEncrypt, int nFileOffset);
	bool InnerOpen(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt, bool bShortName);

	//	Save file entries
	void Encrypt(unsigned char* pBuffer, auint32 dwLength);
	void Decrypt(unsigned char* pBuffer, auint32 dwLength);
	//	Safe header
	bool LoadSafeHeader();

	//	Allocate new name
	char* AllocFileName(const char* szFile, int iEntryCnt, int iEntryTotalNum);
};

#endif	//	_AFILEPACKGAME_H_
