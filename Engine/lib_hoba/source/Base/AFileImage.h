#ifndef _AFILEIMAGE_H_
#define _AFILEIMAGE_H_

#include "AFile.h"

class AFilePackBase;

class AFileImage : public AFile
{
private:
	AFilePackBase *	m_pPackage;		//	package object this file image open with
	unsigned char*	m_pFileImage;	//	Memory pointer of the file image in memory;
	int				m_nCurPtr;		//	In index into the file image buffer;
	int				m_nFileLength;	//	File length;
	void*			m_dwHandle;		//	Handle in file package

	bool fimg_read(unsigned char* pBuffer, int nSize, int * pReadSize); // read some size of data into a buffer;
	bool fimg_read_line(char * szLineBuffer, int nMaxLength, int * pReadSize); // read a line into a buffer;
	bool fimg_seek(int nOffset, int startPos); // offset current pointer

protected:

	bool Init(const char* szFullPath);
	bool Release();
	bool ReadFileData(const char* szFullPath, bool bPrintError = true);
	bool ReadPackData(AFilePackBase* pPackage, bool bPrintError = true);

public:

	//	Write data to package
	static bool WriteToPack(const char* szFile, const void* pBuf, auint32 dwBufLen, bool bReplaceOnly);

	AFileImage();
	virtual ~AFileImage();

	virtual bool Open(const char* szFullPath, auint32 dwFlags);
	virtual bool Open(const char* szFolderName, const char* szFileName, auint32 dwFlags);
	virtual bool OpenWithAbsFullPath(const char* szFullPath, auint32 dwFlags);
	virtual bool Close();

	virtual bool Read(void* pBuffer, auint32 dwBufferLength, auint32 * pReadLength);
	virtual bool Write(const void* pBuffer, auint32 dwBufferLength, auint32 * pWriteLength);

	virtual bool ReadLine(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength);
	virtual bool ReadString(char * szLineBuffer, auint32 dwBufferLength, auint32 * pdwReadLength);
	virtual bool WriteLine(const char* szLineBuffer);
	virtual bool WriteString(const AString& str);
	virtual bool ReadString(AString& str);

	virtual auint32 GetPos() const;
	virtual bool Seek(int iOffset, AFILE_SEEK origin);
	virtual bool ResetPointer();
	//	Get file length
	virtual auint32 GetFileLength() const { return (auint32)m_nFileLength; }

	unsigned char* GetFileBuffer() { return m_pFileImage; }
};

typedef AFileImage * PAFileImage;

#endif //_AFILEIMAGE_H_
