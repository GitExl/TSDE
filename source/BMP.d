/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BMP;

import std.stdio;

private struct BitmapFileHeader {
    align(1):
    ushort id;
    uint fileSize;
    ushort reserved1;
    ushort reserved2;
    uint dataOffset;
}

private struct BitmapInfoHeader {
    align(1):
    uint size;
    int width;
    int height;
    ushort colorPlanes;
    ushort bitsPerPixel;
    uint compressionType;
    uint bitmapSize;
    int resH;
    int resV;
    uint colorCount;
    uint importantColorCount;
}

public class BMP {
    private ushort _bitsPerPixel;
    private int _width;
    private int _height;
    private ubyte[] _data;
    private ubyte[] _palette;

    public this(const string fileName) {
        BitmapFileHeader header;
        BitmapInfoHeader info;

        File f = File(fileName, "rb");
        fread(&header, header.sizeof, 1, f.getFP());
        if (header.id != 0x4D42) {
            throw new Exception("Invalid BMP file.");
        }

        fread(&info, info.sizeof, 1, f.getFP());

        _width = info.width;
        _height = info.height;
        _bitsPerPixel = info.bitsPerPixel;
        _data = new ubyte[_width * _height * (info.bitsPerPixel / 8)];
        fread(_data.ptr, 1, _data.length, f.getFP());

        f.close();
    }

    public this(const int width, const int height, const ushort bpp, ubyte[] data) {
        _width = width;
        _height = height;
        _bitsPerPixel = bpp;
        _data = data;
    }

    public this(const int width, const int height, const ushort bpp, ubyte[] data, ubyte[] palette) {
        _width = width;
        _height = height;
        _bitsPerPixel = bpp;
        _data = data;
        _palette = palette;
    }

    public this(const int width, const int height, const ushort bpp) {
        const uint size = _width * _height * 4;
        ubyte[] data = new ubyte[size];
        this(width, height, bpp, data);
    }

    public void writeTo(const string fileName) {
        BitmapFileHeader header;
        header.id = 0x4D42;
        header.reserved1 = 1;
        header.reserved2 = 1;
        header.fileSize = BitmapFileHeader.sizeof + BitmapInfoHeader.sizeof + _palette.length + _data.length;
        header.dataOffset = BitmapFileHeader.sizeof + BitmapInfoHeader.sizeof + _palette.length;

        BitmapInfoHeader info;
        info.size = BitmapInfoHeader.sizeof;
        info.width = _width;
        info.height = _height;
        info.colorPlanes = 1;
        info.bitsPerPixel = _bitsPerPixel;
        info.bitmapSize = _data.length;
        info.resH = 96;
        info.resV = 96;
        info.colorCount = _palette.length / 4;

        File f = File(fileName, "wb");
        fwrite(&header, header.sizeof, 1, f.getFP());
        fwrite(&info, info.sizeof, 1, f.getFP());
        if (_palette.length) {
            fwrite(&_palette[0], _palette.length, 1, f.getFP());
        }
        fwrite(_data.ptr, 1, _data.length, f.getFP());
        f.close();
    }

    @property
    public int width() {
        return _width;
    }

    @property
    public int height() {
        return _height;
    }

    @property
    public ubyte[] data() {
        return _data;
    }
}