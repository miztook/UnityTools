extern "C"
{
	#include "curl_export.h"
}	

#include <stdarg.h>

HAPI int CURL_curl_global_init(int flags)
{
	return (int)curl_global_init((long)flags);
}

HAPI void CURL_curl_global_cleanup(void)
{
	curl_global_cleanup();
}

HAPI char* CURL_curl_escape(const char *string,
	int length)
{
	return curl_escape(string, length);
}

HAPI char* CURL_curl_unescape(const char *string,
	int length)
{
	return curl_unescape(string, length);
}

HAPI void CURL_curl_free(void *p)
{
	curl_free(p);
}

HAPI char* CURL_curl_version()
{
	return curl_version();
}

HAPI CURL* CURL_curl_easy_init()
{
	return curl_easy_init();
}

HAPI void CURL_curl_easy_cleanup(CURL *curl)
{
	curl_easy_cleanup(curl);
}

HAPI int CURL_curl_easy_setopt_ptr(CURL *curl, int option, void* ptr)
{
	return curl_easy_setopt(curl, (CURLoption)option, ptr);
}

HAPI int CURL_curl_easy_setopt_int(CURL *curl, int option, int value)
{
	return curl_easy_setopt(curl, (CURLoption)option, ((long)value));
}

HAPI int CURL_curl_easy_setopt_int64(CURL *curl, int option, int64_t value)
{
	return curl_easy_setopt(curl, (CURLoption)option, value);
}


HAPI int CURL_curl_easy_perform(CURL *curl)
{
	return curl_easy_perform(curl);
}

HAPI CURL* CURL_curl_easy_duphandle(CURL *curl)
{
	return curl_easy_duphandle(curl);
}

HAPI const char* CURL_curl_easy_strerror(int code)
{
	return curl_easy_strerror((CURLcode)code);
}

HAPI int CURL_curl_easy_getinfo_ptr(CURL *curl, int info, void** value)
{
	void* dvalue;
	int ret = curl_easy_getinfo(curl, (CURLINFO)info, &dvalue);
	*value = dvalue;
	return ret;
}

HAPI int CURL_curl_easy_getinfo_int(CURL *curl, int info, int* value)
{
	int ivalue;
	long lvalue;
	int ret = curl_easy_getinfo(curl, (CURLINFO)info, &lvalue);
	ivalue = (int)lvalue;
	*value = ivalue;
	return ret;
}

HAPI int CURL_curl_easy_getinfo_double(CURL *curl, int info, double* value)
{
	double dvalue;
	int ret = curl_easy_getinfo(curl, (CURLINFO)info, &dvalue);
	*value = dvalue;
	return ret;
}

HAPI int CURL_curl_easy_getinfo_time(CURL *curl, int info, int* yy, int* mm, int* dd, int* hh,
	int* mn, int* ss)
{
	long t = 0;
	int ret = curl_easy_getinfo(curl, (CURLINFO)info, &t);

	if (ret == CURLE_OK)
	{
		if (t == 0)
		{
			ret = CURLE_GOT_NOTHING;
		}
		else
		{
			time_t tmt = (time_t)t;
			struct tm* ptm = localtime(&tmt);
			if (!ptm)
			{
				ret = CURLE_GOT_NOTHING;
			}
			else
			{
				*yy = ptm->tm_year + 1900;
				*mm = ptm->tm_mon + 1;
				*dd = ptm->tm_mday;
				*hh = ptm->tm_hour;
				*mn = ptm->tm_min;
				*ss = ptm->tm_sec;
			}
		}
	}
	
	if (ret != CURLE_OK)
	{
		*yy = 0;
		*mm = 0;
		*dd = 0;
		*hh = 0;
		*mn = 0;
		*ss = 0;
	}

	return ret;
}

HAPI void CURL_curl_easy_reset(CURL *curl)
{
	return curl_easy_reset(curl);
}

HAPI CURLM* CURL_curl_multi_init()
{
	return curl_multi_init();
}

HAPI int CURL_curl_multi_cleanup(CURLM *multi_handle)
{
	return (int)curl_multi_cleanup(multi_handle);
}

HAPI int CURL_curl_multi_add_handle(CURLM *multi_handle,
	CURL *curl_handle)
{
	return (int)curl_multi_add_handle(multi_handle, curl_handle);
}

HAPI int CURL_curl_multi_remove_handle(CURLM *multi_handle,
	CURL *curl_handle)
{
	return (int)curl_multi_remove_handle(multi_handle, curl_handle);
}

HAPI const char* CURL_curl_multi_strerror(int code)
{
	return curl_multi_strerror((CURLMcode)code);
}

HAPI int CURL_curl_multi_perform(CURLM *multi_handle,
	int *running_handles)
{
	return (int)curl_multi_perform(multi_handle, running_handles);
}

HAPI void CURL_curl_formfree(struct curl_httppost *form)
{
	curl_formfree(form);
}

HAPI CURLSH* CURL_curl_share_init()
{
	return curl_share_init();
}

HAPI int CURL_curl_share_cleanup(CURLSH * curlsh)
{
	return (int)curl_share_cleanup(curlsh);
}

HAPI const char* CURL_curl_share_strerror(int code)
{
	return curl_share_strerror((CURLSHcode)code);
}

HAPI int CURL_curl_share_setopt(CURLSH *curlsh, int option, void* v)
{
	return curl_share_setopt(curlsh, (CURLSHoption)option, v);
}

HAPI curl_version_info_data* CURL_curl_version_info(int version)
{
	return curl_version_info((CURLversion)version);
}

size_t default_write_callback(char *buffer, size_t  size, size_t  nitems, void *userp)
{
	return size * nitems;
}

HAPI uint64_t CURL_GetUrlFileSize(const char* url, int timeout)
{
	uint64_t size = -1;

	CURL* curl = curl_easy_init();

	curl_easy_setopt(curl, CURLOPT_URL, (const char*)url);
	curl_easy_setopt(curl, CURLOPT_HEADER, 1L);
	curl_easy_setopt(curl, CURLOPT_NOBODY, 1L);
	curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT, timeout);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, default_write_callback);

	long error = 0;
	double downloadFileLength = 0.0f;
	if (curl_easy_perform(curl) == CURLE_OK)
	{
		CURLcode code = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &error);
		if (code == CURLE_OK && error == 200)
		{
			curl_easy_getinfo(curl, CURLINFO_CONTENT_LENGTH_DOWNLOAD, &downloadFileLength);
		}

		if (downloadFileLength >= 0.0f)
			size = (uint64_t)downloadFileLength;
	}
	else
	{
		downloadFileLength = 0.0f;
	}


	curl_easy_cleanup(curl);

	return size;
}

