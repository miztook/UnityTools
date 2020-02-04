# The ARMv7 is significanly faster due to the use of the hardware FPU
//APP_MODULES := libhoba

APP_ABI := armeabi armeabi-v7a x86 
#arm64-v8a x86_64
APP_PLATFORM := android-10
APP_STL := gnustl_static
NDK_TOOLCHAIN_VERSION := clang

APP_CFLAGS := -w
APP_CPPFLAGS += -std=c++11

#APP_CPPFLAGS += -fexceptions		\

APP_OPTIM := release

BUILD_OPENGL := 1


