#ifndef _COMPILE_CONFIG_H_
#define _COMPILE_CONFIG_H_

//宏说明

// #define A_PLATFORM_WIN_DESKTOP
//
// #define A_PLATFORM_ANDROID
//
// #define A_PLATFORM_XOS
//
// #define A_PLATFORM_LINUX

#define DISABLE_ZLIB				//disable package, zlib

//Platform Defines
#if defined(_MSC_VER)

#define A_PLATFORM_WIN_DESKTOP 1

#elif defined(__ANDROID__)
//Attention: "__linux__" is also defined on Android platform.
#define A_PLATFORM_ANDROID 1

#elif defined(__APPLE__)

#define A_PLATFORM_XOS 1

#elif defined(__linux__) || defined(LINUX)

#define A_PLATFORM_LINUX 1

#endif

#endif