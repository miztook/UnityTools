LOCAL_PATH:= $(call my-dir)

#lib: libp7zDecode
include $(CLEAR_VARS)

LOCAL_MODULE := p7zDecode

TARGET_OUT := $(LOCAL_PATH)/../../../bin/$(APP_OPTIM)/$(TARGET_ARCH_ABI)/

LOCAL_CFLAGS    := 	-DANDROID_NDK \
					-D__ANDROID__ \

P7ZDECODE_DIR := ../../../../dependency/p7zDecode

LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(P7ZDECODE_DIR)

LOCAL_SRC_FILES := 	\
				$(P7ZDECODE_DIR)/Bcj2.c \
				$(P7ZDECODE_DIR)/7zDec.c \
				$(P7ZDECODE_DIR)/7zBuf.c \
				$(P7ZDECODE_DIR)/7zIn.c \
				$(P7ZDECODE_DIR)/7zAlloc.c  \
				$(P7ZDECODE_DIR)/7zFile.c  \
				$(P7ZDECODE_DIR)/7zBuf2.c  \
				$(P7ZDECODE_DIR)/7zCrc.c  \
				$(P7ZDECODE_DIR)/7zCrcOpt.c  \
				$(P7ZDECODE_DIR)/7zStream.c  \
				$(P7ZDECODE_DIR)/Aes.c  \
				$(P7ZDECODE_DIR)/Alloc.c  \
				$(P7ZDECODE_DIR)/Bra.c  \
				$(P7ZDECODE_DIR)/Bra86.c  \
				$(P7ZDECODE_DIR)/BraIA64.c  \
				$(P7ZDECODE_DIR)/BwtSort.c  \
				$(P7ZDECODE_DIR)/CpuArch.c  \
				$(P7ZDECODE_DIR)/Delta.c  \
				$(P7ZDECODE_DIR)/HuffEnc.c  \
				$(P7ZDECODE_DIR)/LzFind.c  \
				$(P7ZDECODE_DIR)/LzFindMt.c  \
				$(P7ZDECODE_DIR)/Lzma2Dec.c  \
				$(P7ZDECODE_DIR)/Lzma2Enc.c  \
				$(P7ZDECODE_DIR)/LzmaDec.c  \
				$(P7ZDECODE_DIR)/LzmaEnc.c  \
				$(P7ZDECODE_DIR)/MtCoder.c  \
				$(P7ZDECODE_DIR)/Ppmd7.c  \
				$(P7ZDECODE_DIR)/Ppmd7Dec.c  \
				$(P7ZDECODE_DIR)/Ppmd7Enc.c  \
				$(P7ZDECODE_DIR)/Ppmd8.c  \
				$(P7ZDECODE_DIR)/Ppmd8Dec.c  \
				$(P7ZDECODE_DIR)/Ppmd8Enc.c  \
				$(P7ZDECODE_DIR)/Sha256.c  \
				$(P7ZDECODE_DIR)/Sort.c  \
				$(P7ZDECODE_DIR)/Threads.c  \
				$(P7ZDECODE_DIR)/Xz.c  \
				$(P7ZDECODE_DIR)/XzCrc64.c  \
				$(P7ZDECODE_DIR)/XzDec.c  \
				$(P7ZDECODE_DIR)/XzEnc.c  \
				$(P7ZDECODE_DIR)/XzIn.c  \	

include $(BUILD_STATIC_LIBRARY)

