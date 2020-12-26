# The ARMv7 is significanly faster due to the use of the hardware FPU
//APP_MODULES := libhoba

APP_ABI := armeabi-v7a arm64-v8a x86 
#armeabi x86 x86_64
APP_PLATFORM := android-21
APP_STL := gnustl_static
NDK_TOOLCHAIN_VERSION := clang

APP_CFLAGS := -w
APP_CPPFLAGS += -std=c++11

#APP_CPPFLAGS += -fexceptions		\

APP_OPTIM := release

BUILD_OPENGL := 1


