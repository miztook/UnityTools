#ifndef _AFILE_H_
#define _AFILE_H_

#include "ASys.h"
#include "AString.h"

#define AFILE_TYPE_BINARY			0x42584f4d
#define AFILE_TYPE_TEXT				0x54584f4d

#define AFILE_OPENEXIST				0x00000001
#define AFILE_CREATENEW				0x00000002
#define AFILE_OPENAPPEND			0x00000004
#define AFILE_TEXT					0x00000008
#define AFILE_BINARY				0x00000010
#define AFILE_NOHEAD				0x00000020
#define AFILE_TEMPMEMORY			0x00000040	//	Use temporary memory alloctor, used by AFileImage,
//	AFILE_TEMPMEMORY is default flag now except AFILE_NOTEMPMEMORY
//	is specified.
#define AFILE_NOTEMPMEMORY			0x00000080	//	Don't use temporary memory alloctor, used by AFileImage,
//	this flag is excluding with AFILE_TEMPMEMORY

#define AFILE_LINEMAXLEN			2048

enum AFILE_SEEK
{
	AFILE_SEEK_SET = SEEK_SET,
	AFILE_SEEK_CUR = SEEK_CUR,
	AFILE_SEEK_END = SEEK_END,
};

class AFile
{
private:
	FILE *	m_pFile;

protected:
	// An fullpath file name;
	char	m_szFileName[QMAX_PATH];

	// An relative file name that relative to the work dir;
	char	m_szRelativeName[QMAX_PATH];

	auint32		m_dwFlags;
	auint32		m_dwTimeStamp;
	auint32		m_dwLength;

	bool	m_bHasOpened;

public:
	AFile();
	virtual ~AFile();

	bool IsOpen() const { return m_bHasOpened; }

	virtual bool Open(const char* szFullPath, auint32 dwFlags);
	virtual bool Open(const char* szFolderName, const char* szFileName, auint32 dwFlags);
	virtual bool OpenWithAbsFullPath(const char* szFullPath, auint32 dwFlags);
	virtual bool Close();

	virtual bool Read(void* pBuffer, auint32 dwBufferLength, auint32 * pReadLength);
	virtual bool Write(const void* pBuffer, auint32 dwBufferLength, auint32 * pWriteLength);

	virtual bool ReadLine(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength);
	virtual bool ReadString(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength);
	virtual bool WriteLine(const char * szLineBuffer);
	virtual bool WriteString(const AString& str);
	virtual bool ReadString(AString& str);

	virtual auint32 GetPos() const;
	virtual bool Seek(int iOffset, AFILE_SEEK origin);
	virtual bool ResetPointer(); // Reset the file pointer;
	//	Get file length
	virtual auint32 GetFileLength() const { return m_dwLength; }

	bool Flush();

	auint32 GetTimeStamp() const { return m_dwTimeStamp; }
	auint32 GetFlags() const { return m_dwFlags; }
	//Binary first, so if there is no binary or text, it is a binary file;
	bool IsBinary() const { return !IsText(); }
	bool IsText() const { return (m_dwFlags & AFILE_TEXT) ? true : false; }

	const char* GetFileName() const { return m_szFileName; }
	const char* GetRelativeName() const { return m_szRelativeName; }

	auint32 _GetFileLength() const;
};

#endif