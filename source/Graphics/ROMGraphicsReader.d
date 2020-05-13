/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Graphics.ROMGraphicsReader;

import std.stdio;
import std.json;
import std.string;

import List.ListReaderInterface;

import Graphics.Graphic;

import Decompress;
import BinaryFile;
import Bitmap;
import BMP;

public class ROMGraphicsReader : ListReaderInterface!Graphic {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public Graphic[] read() {
        Graphic[] graphics;

        foreach (string name, JSONValue group; _config["graphics"].object) {
            graphics ~= readGraphicGroup(name, group);
        }

        return graphics;
    }

    public Graphic[] readGraphicGroup(string name, JSONValue group) {
        Graphic[] graphics;

        const uint count = "count" in group ? cast(uint)group["count"].integer : 1;
        const uint size = "size" in group ? cast(uint)group["size"].integer : 0;
        const ushort width = "width" in group ? cast(ushort)group["width"].integer : 128;
        const ubyte bitplanes = "bitplanes" in group ? cast(ubyte)group["bitplanes"].integer : 0;
        const bool isCompressed = !!("compressed" in group);
        const string pointerType = "pointers" in group ? group["pointers"].str : "";

        uint[] sizes;
        if ("sizes" in group) {
            sizes = new uint[group["sizes"].array.length];
            foreach (int index, JSONValue sizeValue; group["sizes"].array) {
                sizes[index] = cast(uint)sizeValue.integer;
            }
        }

        uint dataSize;
        uint currentAddress;
        uint[] pointers;
        
        _rom.setPosition(cast(uint)group["address"].integer);
        if (pointerType.length) {
            pointers = readGraphicsPointers(_rom, count, pointerType);
        }

        for (int index = 0; index < count; index++) {
            BinaryFile data;
            if (pointers.length) {
                currentAddress = pointers[index];
            } else {
                currentAddress = _rom.getPosition();
            }

            if (isCompressed) {
                ubyte[] decompressed = new ubyte[0x10000];
                const uint length = decompressLZ(_rom.array, decompressed, currentAddress);
                decompressed.length = length;
                data = new BinaryFile(decompressed);
                dataSize = length;
            } else {
                _rom.setPosition(currentAddress);
                data = _rom;
                dataSize = size;
            }

            Graphic graphic;
            if (count > 1) {
                graphic.key = format("%03d_%s", index, name);
                graphic.group = name;
            } else {
                graphic.key = name;
            }

            if (sizes.length) {
                dataSize = sizes[index];
            }
            if (dataSize) {
                graphic.bitmaps = readBitmaps(data, dataSize, bitplanes);
            }
            graphic.bitplanes = bitplanes;
            graphic.width = width;
            
            graphics ~= graphic;
        }

        return graphics;
    }

    private Bitmap[] readBitmaps(BinaryFile data, immutable uint size, immutable ubyte bitplanes) {
        const uint tileCount = size / ((8 * 8 * bitplanes) / 8);

        Bitmap[] bitmaps = new Bitmap[tileCount];
        foreach (ref Bitmap bitmap; bitmaps) {
            bitmap = new Bitmap(data, 8, 8, 2, BitmapType.PLANAR);
            if (bitplanes == 4) {
                bitmap.addPlanarData(data, 2, 2);
            }
        }
        return bitmaps;
    }

    private uint[] readGraphicsPointers(BinaryFile data, immutable uint count, immutable string pointerType) {
        uint[] pointers = new uint[count];

        for (int index = 0; index < count; index++) {
            if (pointerType == "absolute") {
                pointers[index] = _rom.read!ushort();
                pointers[index] += 0x10000 * (_rom.read!ubyte() - 0xC0);
            } else if (pointerType == "local") {
                pointers[index] = _rom.read!ushort() + (_rom.getPosition() & 0xFFFF0000);
            }
        }

        return pointers;
    }
}
