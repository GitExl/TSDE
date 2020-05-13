/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Palettes.ROMPaletteReader;

import std.stdio;
import std.json;
import std.string;

import List.ListReaderInterface;

import Palettes.Palette;

import BinaryFile;
import Decompress;

public class ROMPaletteReader : ListReaderInterface!Palette {

    private JSONValue _config;
    private BinaryFile _rom;

    public this(JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public Palette[] read() {
        Palette[] palettes;

        foreach (string name, JSONValue group; _config["palettes"].object) {
            palettes ~= readPaletteGroup(name, group);
        }

        return palettes;
    }

    private Palette[] readPaletteGroup(string name, JSONValue group) {
        Palette[] palettes;

        const uint count = "count" in group ? cast(uint)group["count"].integer : 1;
        const uint size = "size" in group ? cast(uint)group["size"].integer : 0;
        const bool isCompressed = !!("compressed" in group);

        uint currentSize;
        uint currentAddress;
        uint[] pointers;
        
        if ("pointers" in group) {
            const bool pointersAbsolute = (group["pointerType"].str == "absolute");
            _rom.setPosition(cast(int)group["pointers"].integer);
            pointers = readPalettePointers(_rom, count, pointersAbsolute);
        } else {
            _rom.setPosition(cast(uint)group["address"].integer);
        }

        for (int index = 0; index < count; index++) {
            BinaryFile data;
            if (pointers.length) {
                currentAddress = pointers[index];
            } else {
                currentAddress = _rom.getPosition();
            }

            if (isCompressed) {
                ubyte[] decompressed = new ubyte[0x400];
                const uint length = decompressLZ(_rom.array, decompressed, currentAddress);
                decompressed.length = length;
                currentSize = length / 2;
                data = new BinaryFile(decompressed);
            } else {
                _rom.setPosition(currentAddress);
                currentSize = size;
                data = _rom;
            }

            Palette palette;
            if (count > 1) {
                palette.key = format("%03d_pal_%s", index, name);
                palette.group = name;
            } else {
                palette.key = name;
            }
            palette.colors = readPalette(data, currentSize);
            
            palettes ~= palette;
        }

        return palettes;
    }

    private Color[] readPalette(BinaryFile data, immutable uint size) {
        Color[] colors = new Color[size];

        foreach (ref Color color; colors) {
            const ushort packed = data.read!ushort();
            color.r = ((packed >> 0)  & 0x1F) * 8;
            color.g = ((packed >> 5)  & 0x1F) * 8;
            color.b = ((packed >> 10) & 0x1F) * 8;
        }

        return colors;
    }

    private uint[] readPalettePointers(BinaryFile data, immutable uint count, immutable bool absolute) {
        uint[] pointers = new uint[count];

        for (int index = 0; index < count; index++) {
            if (absolute) {
                immutable ubyte[3] bytes = _rom.readBytes(3);
                pointers[index] = ((bytes[2] << 16) | (bytes[1] << 8) | bytes[0]) & 0x000FFFFF;
            } else {
                pointers[index] = _rom.read!ushort() + (_rom.getPosition() & 0xFFFF0000);
            }
        }

        return pointers;
    }

}
