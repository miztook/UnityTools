package com.meteoritestudio.applauncher;

public class FileInfo {
    public String relativePath;
    public long size = 0;

    public FileInfo(String relativePath, long fsize) {
	this.relativePath = relativePath;
	this.size = fsize;
    }
}