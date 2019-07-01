#pragma once

#include "compileconfig.h"

#include "ATypes.h"
#include <string>
#include <memory.h>

#ifdef A_PLATFORM_WIN_DESKTOP

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#else
#include <pthread.h>
#endif

class ASysCodeCvt
{
public:

	// 字符编码转换函数。
	// 字符编码转换函数 Part I: 单个字符UTF32 <-> UTF8，自己实现的。
	struct UTF8_EncodedChar
	{
		UTF8_EncodedChar()
		{
			memset(bytes, 0, 8);
		}
		int GetByteCount()
		{
			return len > 6 ? 6 : len;
		}
		union
		{
			char bytes[8];
			struct
			{
				char byte0;
				char byte1;
				char byte2;
				char byte3;
				char byte4;
				char byte5;
				char byte6; // always null
				auint8 len;
			};
		};
	};
	static aint32 ParseUnicodeFromUTF8Str(const char* szUTF8, aint32* pnAdvancedInUtf8Str = 0, auint32 nUtf8StrMaxLen = A_MAX_UINT32);
	static UTF8_EncodedChar EncodeUTF8(aint32 ch);
	static aint32 ParseUnicodeFromUTF8StrEx(const char* szUTF8, aint32 iParsePos = 0, aint32* piParsedHeadPos = 0, aint32* pnUtf8ByteCounts = 0, auint32 nUtf8StrMaxLen = A_MAX_UINT32);
	// 字符编码转换函数 Part II: UTF16LE <-> UTF8，自己实现的。
	static aint32 UTF16Len(const auchar* sz16); // returns the auint16-char count NOT including \0.
	static aint32 UTF8ToUTF16LE(auchar* sz16, const char* sz8); // returns the auint16-char count including \0 of the converted string.
	static aint32 UTF16LEToUTF8(char* sz8, const auchar* sz16); // returns the byte count including \0 of the converted string.
};

//AThreadLocal
#ifdef A_PLATFORM_WIN_DESKTOP

#define AThreadLocal(of_type) __declspec(thread) of_type

#else

#include <pthread.h>
template<typename T>
struct AngelicaThreadLocal
{
	AngelicaThreadLocal()
	{
		pthread_key_create(&key, AngelicaThreadLocal<T>::_ClearStorage);
	}
	AngelicaThreadLocal(const T& other) : AngelicaThreadLocal()
	{
		m_InitData = other;
	}
	AngelicaThreadLocal<T>& operator=(const T& other)
	{
		Data() = other;
		return *this;
	}
	operator const T&() const
	{
		return Data();
	}
	operator T&()
	{
		return Data();
	}

private:
	pthread_key_t key;
	T m_InitData;
	static void _ClearStorage(void* pData)
	{
		if (pData)
			delete (T*)pData;
	}
	T& Data() const
	{
		void* data = pthread_getspecific(key);
		if (!data)
		{
			data = new T(m_InitData);
			pthread_setspecific(key, data);
		}
		return *(T*)data;
	}
};
#define AThreadLocal(of_type) AngelicaThreadLocal<of_type>

#endif

// ## Classes for string convert macros.
class BaseStackStringConverter
{
protected:

	BaseStackStringConverter(void* pAllocaBuffer)
	{
		nBufferLen = nBufferLenTemp;
		szBuffer = pAllocaBuffer;
	}

public:
	operator char*() const { return (char*)szBuffer; }
	operator auchar*() const { return (auchar*)szBuffer; }
	operator void*() const { return szBuffer; }

	static AThreadLocal(size_t) nBufferLenTemp;
	static AThreadLocal(const void*) szConvertSrcTemp;
	static AThreadLocal(size_t) nSrcLenTemp;

	static size_t Prepare(const std::string& rStr)
	{
		szConvertSrcTemp = rStr.c_str();
		nSrcLenTemp = rStr.length();
		return nSrcLenTemp;
	}

	static size_t Prepare(const BaseStackStringConverter& rStr)
	{
		szConvertSrcTemp = (const char*)rStr;
		nSrcLenTemp = rStr.GetLength();
		return nSrcLenTemp;
	}

	static size_t Prepare(const char* rStr)
	{
		szConvertSrcTemp = rStr;
		nSrcLenTemp = strlen(rStr);
		return nSrcLenTemp;
	}

	static size_t PrepareUTF16_UTF8(const auchar* rStr)
	{
		szConvertSrcTemp = (const char*)rStr;
		nSrcLenTemp = ASysCodeCvt::UTF16Len(rStr);
		return nSrcLenTemp * 4 + 1;
	}

	static size_t PrepareUTF8_UTF16(const char* rStr)
	{
		szConvertSrcTemp = rStr;
		nSrcLenTemp = strlen(rStr);
		return nSrcLenTemp * 2 + 2;
	}

	size_t GetLength() const { return nBufferLen; }

protected:

	size_t nBufferLen;
	void* szBuffer;
};

class UTF16ToUTF8Converter : public BaseStackStringConverter
{
public:
	UTF16ToUTF8Converter(void* pAllocaBuffer) : BaseStackStringConverter(pAllocaBuffer) { Convert(szConvertSrcTemp); }
protected:
	void Convert(const void* szSrc) { nBufferLen = ASysCodeCvt::UTF16LEToUTF8((char*)szBuffer, (const auchar*)szSrc); }
};

class UTF8ToUTF16Converter : public BaseStackStringConverter
{
public:
	UTF8ToUTF16Converter(void* pAllocaBuffer) : BaseStackStringConverter(pAllocaBuffer) { Convert(szConvertSrcTemp); }
protected:
	void Convert(const void* szSrc) { nBufferLen = ASysCodeCvt::UTF8ToUTF16LE((auchar*)szBuffer, (const char*)szSrc); }
};
// =# Classes for string convert macros. ^above^

// ## Helper Macro To Convert String To Different Encodings.
// The return values of these macros should NOT be released.

// Convert from UTF-16 to UTF-8. Returned pointer should NOT be released.
#define A_UTF16_TO_UTF8(x) (char*)UTF16ToUTF8Converter(AAlloca16(BaseStackStringConverter::nBufferLenTemp = BaseStackStringConverter::PrepareUTF16_UTF8((const auchar*)(x))))
// Convert from UTF-8 to UTF-16. Returned pointer should NOT be released.
#define A_UTF8_TO_UTF16(x) (auchar*)(void*)UTF8ToUTF16Converter(AAlloca16(BaseStackStringConverter::nBufferLenTemp = BaseStackStringConverter::PrepareUTF8_UTF16(x)))

// Convert from UTF-16 to UTF-8. Returned pointer should NOT be released.
#define ASTR_UTF16_TO_UTF8(x) UTF16ToUTF8Converter(AAlloca16(BaseStackStringConverter::nBufferLenTemp = ASysCodeCvt::UTF16LEToUTF8(0, (const auchar*)(const void*)(BaseStackStringConverter::szConvertSrcTemp = (x)))))
// Convert from UTF-8 to UTF-16. Returned pointer should NOT be released.
#define ASTR_UTF8_TO_UTF16(x) (auchar*)(void*)UTF8ToUTF16Converter(AAlloca16(BaseStackStringConverter::nBufferLenTemp = BaseStackStringConverter::Prepare(x) * 2 + 2))
// =# Helper Macro To Convert String To Different Encodings. ^above^