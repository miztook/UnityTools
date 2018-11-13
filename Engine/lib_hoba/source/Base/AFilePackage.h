#ifndef _AFILEPACKAGE_H_
#define _AFILEPACKAGE_H_

#include "AString.h"
#include "AFilePackBase.h"
#include "ASysSync.h"
#include <vector>

#pragma warning(disable:4996)

class AFilePackage : public AFilePackBase
{
public:

	class entry
	{
	public:
		char *_name;
		entry() :_name(NULL) {}
		explicit entry(const char * name) { _name = (char*)malloc(sizeof(char) * (strlen(name) + 1)); strcpy(_name, name); }
		virtual ~entry() { if (_name) free(_name); }
		virtual bool IsContainer() const = 0;
		virtual int GetIndex() const = 0;
		virtual entry* SearchItem(const char * name) const = 0;
	};
	class directory : public entry
	{
		std::vector<entry *> _list;
		int searchItemIndex(const char * name, int * pos) const;
	public:
		explicit directory(const char* name) : entry(name) {}
		directory() {}
		~directory();
		int clear();
		virtual bool IsContainer() const override { return true; }
		virtual int GetIndex() const override { return -1; }
		virtual entry * SearchItem(const char* name) const override;
	public:
		entry* GetItem(int index);
		int GetEntryCount() const { return (int)_list.size(); }
		int RemoveItem(const char * name);
		int AppendEntry(entry *);
		int SearchEntry(const char * filename) const;
	};
	class file : public entry
	{
		int _index;
	public:
		file(const char * name, int index) :entry(name), _index(index) {}
		virtual bool IsContainer() const override { return false; }
		virtual entry* SearchItem(const char * name) const override { return NULL; }
		virtual int GetIndex() const override { return _index; }
		void SetIndex(int index) { _index = index; }
	};

public:		//	Types

	enum OPENMODE
	{
		OPENEXIST = 0,
		CREATENEW = 1
	};

	struct FILEENTRYCACHE
	{
		auint32		dwCompressedLength;	//	The compressed file entry length
		abyte *		pEntryCompressed;	//	The compressed file entry data
	};

	struct FILEENTRY
	{
		char	szFileName[MAX_PATH];	//	The file name of this entry; this may contain a path;
		auint32		dwOffset;				//	The offset from the beginning of the package file;
		auint32		dwLength;				//	The length of this file;
		auint32		dwCompressedLength;		//	The compressed data length;

		int		iAccessCnt;				//	Access counter used by OpenSharedFile
	};

	struct FILEHEADER
	{
		auint32		guardByte0;				//	0xabcdefab
		auint32		dwVersion;				//	Composed by two word version, major part and minor part;
		auint32		dwEntryOffset;			//	The entry list offset from the beginning;
		auint32		dwFlags;				//	package flags. the highest bit means the encrypt state;
		char	szDescription[252];		//	Description
		auint32		guardByte1;				//	0xffeeffee
	};

	//	Share read file item
	struct SHAREDFILE
	{
		auint32		dwFileID;		//	File ID
		bool		bCached;		//	Cached flag
		bool		bTempMem;		//	true, use temporary memory alloctor
		int			iRefCnt;		//	Reference counter
		abyte*		pFileData;		//	File data buffer
		auint32		dwFileLen;		//	File data length

		FILEENTRY*	pFileEntry;		//	Point to file entry
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

	//typedef abase::hashtab<SHAREDFILE*, int, abase::_hash_function> SharedTable;
	//typedef abase::hashtab<CACHEFILENAME*, int, abase::_hash_function> CachedTable;

	friend class AFilePackMan;
	friend class AFilePackGame;

private:

	bool		m_bHasChanged;
	bool		m_bReadOnly;
	bool		m_bUseShortName;	//	Get rid of m_szFolder in each file name

	FILEHEADER	m_header;
	OPENMODE	m_mode;

	std::vector<FILEENTRY*>	m_aFileEntries;		//	File entries
	std::vector<FILEENTRYCACHE*>	m_aFileEntryCache;	// File entries cache
	lock_type		m_csFR;				//	File Read lock

	CPackageFile* m_fpPackageFile;
	char		m_szPckFileName[MAX_PATH];	// the package file path
	char		m_szFolder[MAX_PATH];	// the folder path (in lowercase) the package packs.

	directory	m_directory;	//	the ROOT of directory tree.
	auint32		m_dwCacheSize;	//	Size counter of all cached files
	auint32		m_dwSharedSize;	//	Size counter of all shared files

	bool			m_bHasSafeHeader;	// flag indicates whether the package contains a safe header
	SAFEFILEHEADER	m_safeHeader;		// Safe file header
public:

	AFilePackage();
	virtual ~AFilePackage();

	bool Open(const char* szPckPath, OPENMODE mode, bool bEncrypt = false);
	bool Open(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt = false);
	virtual bool Close() override;
	virtual bool Flush() override;

	/*	Append a file into the package
		parameter:
		IN: szFileName		file name
		IN: pFileBuffer		the buffer containing file content
		IN: dwFileLength	the length of the buffer
		IN: bCompress		true, compress file
		*/
	bool AppendFile(const char* szFileName, unsigned char* pFileBuffer, auint32 dwFileLength, bool bCompress);
	bool AppendFileCompressed(const char * szFileName, unsigned char* pCompressedBuffer, auint32 dwFileLength, auint32 dwCompressedLength);

	/*
		Remove a file from the package, we will only remove the file entry from the package;
		the file's data will remain in the package
		parameter:
		IN: szFileName		file name
		*/
	bool RemoveFile(const char* szFileName);

	/*
		Replace a file in the package, we will only replace the file entry in the package;
		the old file's data will remain in the package
		parameter:
		IN: szFileName		file name
		IN: pFileBuffer		the buffer containing file content
		IN: dwFileLength	the length of the buffer
		IN: bCompress		true, compress file
		*/
	bool ReplaceFile(const char* szFileName, unsigned char* pFileBuffer, auint32 dwFileLength, bool bCompress);
	bool ReplaceFileCompressed(const char * szFileName, unsigned char* pCompressedBuffer, auint32 dwFileLength, auint32 dwCompressedLength);

	// Sort the file entry list;
	bool ResortEntries();

	bool ReadFile(const char* szFileName, unsigned char* pFileBuffer, auint32* pdwBufferLen);
	bool ReadFile(FILEENTRY& fileEntry, unsigned char* pFileBuffer, auint32* pdwBufferLen);

	bool ReadCompressedFile(const char * szFileName, unsigned char* pCompressedBuffer, auint32 * pdwBufferLen);
	bool ReadCompressedFile(FILEENTRY& fileEntry, unsigned char* pCompressedBuffer, auint32 * pdwBufferLen);

	// Find a file entry;
	// return true if found, false if not found;
	bool GetFileEntry(const char* szFileName, FILEENTRY* pFileEntry, int* pnIndex = NULL) const;
	const FILEENTRY* GetFileEntryByIndex(int nIndex) const { return m_aFileEntries[nIndex]; }

	directory* GetDirEntry(const char* szPath);

	//	Open a shared file
	virtual void* OpenSharedFile(const char* szFileName, abyte** ppFileBuf, auint32* pdwFileLen) override;
	//	Close a shared file
	virtual void CloseSharedFile(void* dwFileHandle) override;

	//	Get current cached file total size
	auint32 GetCachedFileSize() const { return m_dwCacheSize; }
	//	Get current shared file total size
	auint32 GetSharedFileSize() const { return m_dwSharedSize; }

	int GetFileNumber() const { return (int)m_aFileEntries.size(); }
	FILEHEADER GetFileHeader() const { return m_header; }
	virtual const char * GetFolder() const override { return m_szFolder; }
	const char* GetPckFileName() const { return m_szPckFileName; }
	virtual bool IsFileExist(const char* szFileName) const override;

	auint32 GetPackageFileSize() const { return m_fpPackageFile->GetPackageFileSize(); }

public:
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
	static int Compress(const unsigned char* pFileBuffer, auint32 dwFileLength, unsigned char* pCompressedBuffer, auint32 * pdwCompressedLength);

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
	static int Uncompress(const unsigned char* pCompressedBuffer, auint32 dwCompressedLength, unsigned char* pFileBuffer, auint32 * pdwFileLength);

protected:	//	Attributes

protected:	//	Operations

	//	Normalize file name
	static bool NormalizeFileName(char* szFileName);
	bool NormalizeFileName(char* szFileName, bool bUseShortName) const;
	//	Get rid of folder from file
	void GetRidOfFolder(const char* szInName, char* szOutName) const;

	bool InnerOpen(const char* szPckPath, const char* szFolder, OPENMODE mode, bool bEncrypt, bool bShortName);
	bool LoadOldPack(const char* szPckPath, bool  bEncrypt, int nFileOffset);
	bool LoadPack(const char* szPckPath, bool  bEncrypt, int nFileOffset);
	//	Append a file into directroy
	bool RemoveFileFromDir(const char * filename);
	bool InsertFileToDir(const char * filename, int index);

	//	Save file entries
	bool SaveEntries(auint32 * pdwEntrySize = NULL);
	void Encrypt(unsigned char* pBuffer, auint32 dwLength);
	void Decrypt(unsigned char* pBuffer, auint32 dwLength);

	//	Safe header
	bool LoadSafeHeader();
	bool SaveSafeHeader();
	bool CreateSafeHeader();
};

#endif	//	AFILEPACKAGE_H_
