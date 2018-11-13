# The ARMv7 is significanly faster due to the use of the hardware FPU
APP_MODULES := libiconv

APP_ABI := armeabi armeabi-v7a x86 arm64-v8a
APP_PLATFORM := android-10
APP_STL := stlport_static
NDK_TOOLCHAIN_VERSION := clang

APP_CFLAGS := -w

ifeq ($(NDK_DEBUG), 1)
APP_OPTIM := debug
else
APP_OPTIM := release
endif


