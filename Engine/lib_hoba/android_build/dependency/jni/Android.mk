DEPENDENCY_PATH := $(call my-dir)
LOCAL_PATH := $(DEPENDENCY_PATH)

#include ../makefile/libiconv-1.13.1/jni/Android.mk
#include ../makefile/zlib-1.2.8/jni/Android.mk
#include ../makefile/p7zDecode/jni/Android.mk
include ../makefile/curl/jni/Android.mk

LOCAL_PATH := $(DEPENDENCY_PATH)

include $(CLEAR_VARS)

LOCAL_MODULE    := dependency
LOCAL_SRC_FILES := dependency.cpp

LOCAL_STATIC_LIBRARIES :=  libcurl
#libzlib libp7zDecode 

include $(BUILD_SHARED_LIBRARY)
