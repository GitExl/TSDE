/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Palettes.ACTPaletteWriter;

import std.outbuffer;
import std.stdio;
import std.string;
import std.bitmanip;
import std.file;

import List.ListWriterInterface;

import Palettes.Palette;

public class ACTPaletteWriter : ListWriterInterface!Palette {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const Palette[] palettes) {
        foreach (const Palette palette; palettes) {
            string path = palette.group.length ? format("%s/%s", _outputPath, palette.group) : _outputPath;
            mkdirRecurse(path);

            string fileName;
            if (palette.group.length) {
                fileName = format("%s/%s.act", path, palette.key);
            } else {
                fileName = format("%s/%s.act", path, palette.key);
            }
            
            File file = File(fileName, "wb");
            writePalette(palette, file);
            file.close();    
        }
    }

    private void writePalette(const Palette palette, File file) {
        OutBuffer buffer = new OutBuffer();

        ubyte[3] data;
        for (int index = 0; index < 256; index++) {
            if (index < palette.colors.length) {
                data[0] = palette.colors[index].r;
                data[1] = palette.colors[index].g;
                data[2] = palette.colors[index].b;
            } else {
                data[0..3] = 0;
            }
            buffer.write(data);
        }

        buffer.write(nativeToBigEndian!ushort(cast(ushort)(palette.colors.length)));
        buffer.write(nativeToBigEndian!ushort(cast(ushort)(palette.colors.length)));
        
        file.rawWrite(buffer.toBytes());
    }
}
