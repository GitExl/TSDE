/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module TileSets.JSONTileSetWriter;

import std.base64;
import std.outbuffer;
import std.json;
import std.stdio;
import std.string;
import std.file;

import List.ListWriterInterface;

import TileSets.TileSet;

public class JSONTileSetWriter : ListWriterInterface!TileSet {

    private string _outputPath;

    public this(immutable string outputPath) {
        _outputPath = outputPath;
    }

    public void write(const TileSet[] tileSets) {
        mkdirRecurse(_outputPath);
        foreach (const TileSet tileSet; tileSets) {
            JSONValue json = serialize(tileSet);
            File file = File(format("%s/%s.json", _outputPath, tileSet.key), "w");
            file.writeln(json.toJSON(true));
            file.close();    
        }
    }

    public JSONValue serialize(const TileSet tileSet) {
        JSONValue value;

        JSONValue[] graphics;
        foreach (const string graphic; tileSet.graphics) {
            graphics ~= JSONValue(graphic);
        }
        value["graphics"] = graphics;

        value["assemblies"] = serializeAssemblies(tileSet.assembly);

        return value;
    }

    public JSONValue[] serializeAssemblies(const TileAssembly assembly) {
        JSONValue value;

        OutBuffer buf = new OutBuffer();
        auto bufferLen = Base64.encodeLength(4 * 4);
        char[] buffer = new char[bufferLen];

        JSONValue[] values = new JSONValue[assembly.tiles.length];
        foreach (const int tileIndex, const Tile tile; assembly.tiles) {

            buf.clear();
            foreach (const int chunkIndex, const TileChunk chunk; tile.chunks) {
                buf.write(chunk.subTile);
                buf.write(chunk.subPalette);
                buf.write(cast(ubyte)chunk.flags);
            }

            Base64.encode(buf.toBytes(), buffer);
            values[tileIndex] = buffer;
        }

        return values;
    }
}
