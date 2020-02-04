#ifndef _CURL_EXPORT_H_
#define _CURL_EXPORT_H_

#include "baseDef.h"
#include "curl/curl.h"
#include <stdint.h>

HAPI int CURL_curl_global_init(int flags);

HAPI void CURL_curl_global_cleanup(void);

HAPI char* CURL_curl_escape(const char *string,
	int length);



HAPI char* CURL_curl_unescape(const char *string,
	int length);

HAPI void CURL_curl_free(void *p);

HAPI char* CURL_curl_version();

HAPI CURL* CURL_curl_easy_init();

HAPI void CURL_curl_easy_cleanup(CURL *curl);

HAPI int CURL_curl_easy_setopt_ptr(CURL *curl, int option, void* ptr);

HAPI int CURL_curl_easy_setopt_int(CURL *curl, int option, int value);

HAPI int CURL_curl_easy_setopt_int64(CURL *curl, int option, int64_t value);

HAPI int CURL_curl_easy_perform(CURL *curl);

HAPI CURL* CURL_curl_easy_duphandle(CURL *curl);

HAPI const char* CURL_curl_easy_strerror(int);

HAPI int CURL_curl_easy_getinfo_ptr(CURL *curl, int info, void** value);

HAPI int CURL_curl_easy_getinfo_int(CURL *curl, int info, int* value);

HAPI int CURL_curl_easy_getinfo_double(CURL *curl, int info, double* value);

HAPI int CURL_curl_easy_getinfo_time(CURL *curl, int info, int* yy, int* mm, int* dd, int* hh,
	int* mn, int* ss);

HAPI void CURL_curl_easy_reset(CURL *curl);

HAPI CURLM* CURL_curl_multi_init();

HAPI int CURL_curl_multi_cleanup(CURLM *multi_handle);

HAPI int CURL_curl_multi_add_handle(CURLM *multi_handle,
	CURL *curl_handle);

HAPI int CURL_curl_multi_remove_handle(CURLM *multi_handle,
	CURL *curl_handle);

HAPI const char* CURL_curl_multi_strerror(int);

HAPI int CURL_curl_multi_perform(CURLM *multi_handle,
	int *running_handles);

HAPI void CURL_curl_formfree(struct curl_httppost *form);

HAPI CURLSH* CURL_curl_share_init();

HAPI int CURL_curl_share_cleanup(CURLSH *);

HAPI const char* CURL_curl_share_strerror(int);

HAPI int CURL_curl_share_setopt(CURLSH *, int option, void* v);

HAPI curl_version_info_data* CURL_curl_version_info(int);

HAPI uint64_t CURL_GetUrlFileSize(const char* url, int timeout);

#endif