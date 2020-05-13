module Bitmap;

import std.stdio;
import std.string;

import BinaryFile;
import BMP;

import Palettes.Palette;

public enum BitmapType : ubyte {
    PLANAR,
}

public class Bitmap {
    protected uint _width;
    protected uint _height;
    protected ubyte[] _pixels;

    private Palette _palette;

    public this(const uint width, const uint height) {
        _pixels = new ubyte[width * height];
        _width = width;
        _height = height;
    }

    public this(BinaryFile file, const uint width, const uint height, const ubyte bitPlanes, const BitmapType type) {
        _width = width;
        _height = height;

        _pixels = new ubyte[_width * _height];
        switch (type) {
            case BitmapType.PLANAR: this._readPlanar(file, bitPlanes); break;
            default:
                throw new Exception("Invalid bitmap type.");
        }
    }

    public void blitFrom(Bitmap bitmap, const uint destX, const uint destY) {
        for (uint y = 0; y < bitmap._height; y++) {
            for (uint x = 0; x < bitmap._width; x++) {
                const uint srcIndex = x + y * bitmap._width;
                const uint destIndex = (destX + x) + (destY + y) * _width;
                _pixels[destIndex] = bitmap._pixels[srcIndex];
            }
        }
    }

    private void _readPlanar(BinaryFile file, const ubyte bitPlanes) {
        addPlanarData(file, 0, bitPlanes);
    }

    public void addPlanarData(BinaryFile file, const ubyte startPlane, const ubyte bitPlanes) {
        const int dataSize = (_width * _height * bitPlanes) / 8;
        if (file.getPosition() + dataSize > file.size) {
            throw new Exception(format("Could not read %dx%dx%d planar bitmap because it will read out of bounds.", _width, _height, bitPlanes));
        }

        const ubyte[] data = file.readBytes(dataSize);

        int srcBit = 7;
        int srcByte = 0;
        for (int y = 0; y < _height; y++) {
            for (int plane = 0; plane < bitPlanes; plane++) {
                for (int x = 0; x < _width; x++) {
                    if ((data[srcByte] & (1 << srcBit)) != 0) {
                        _pixels[y * 8 + x] |= (1 << (startPlane + plane));
                    }
                    srcBit--;
                    if (srcBit < 0) {
                        srcBit = 7;
                        srcByte += 1;
                    }
                }
            }
        }
    }

    public void writeToBMP(const string fileName, Palette palette) {
        const uint size = _width * _height;
        ubyte[] data = new ubyte[size];

        for (int y = _height - 1; y >= 0; y--) {
            for (int x = 0; x < _width; x++) {
                const uint srcIndex = x + y * _width;
                const uint destIndex = x + (_height - y - 1) * _width;
                data[destIndex] = _pixels[srcIndex];
            }
        }

        ubyte[] pal = new ubyte[palette.colors.length * 4];
        foreach (int index, Color color; palette.colors) {
            pal[index * 4 + 0] = color.r;
            pal[index * 4 + 1] = color.g;
            pal[index * 4 + 2] = color.b;
            pal[index * 4 + 3] = 0xFF;
        }

        BMP bmp = new BMP(_width, _height, 8, data, pal);
        bmp.writeTo(fileName);
    }

    @property
    public void palette(Palette palette) {
        _palette = palette;
    }
}
