module TileSets.ROMTileSetReader;

import std.stdio;
import std.json;
import std.string;

import List.ListReaderInterface;

import TileSets.TileSet;

import Decompress;
import BinaryFile;

public class ROMTileSetReader : ListReaderInterface!TileSet {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public TileSet[] read() {
        TileAssembly[] assemblies12 = readAssemblies("l12");
        TileAssembly[] assemblies3 = readAssemblies("l3");

        immutable uint address = cast(uint)_config["tileSets"]["addressSets"].integer;

        TileSet[] tileSets12 = new TileSet[assemblies12.length];
        _rom.setPosition(address);
        foreach (int index, ref TileSet tileSet; tileSets12) {
            for (int setIndex = 0; setIndex < 8; setIndex++) {
                const ubyte set = _rom.read!ubyte();
                if (set != 0xFF) {
                    tileSet.graphics ~= format("tiles/l12_tiles_%02d", set);
                }
            }

            tileSet.assembly = assemblies12[index];
            tileSet.key = format("l12_%02d_tileset", index);
        }

        TileSet[] tileSets3 = new TileSet[assemblies3.length];
        foreach (int index, ref TileSet tileSet; tileSets3) {
            tileSet.assembly = assemblies3[index];
            tileSet.graphics ~= format("tiles/l3_tiles_%02d", index);
            tileSet.key = format("l3_%02d_tileset", index);
        }

        return tileSets12 ~ tileSets3;
    }

    public TileAssembly[] readAssemblies(string type) {
        immutable uint count = cast(uint)_config["tileSets"]["assemblies"][type]["count"].integer;
        immutable uint address = cast(uint)_config["tileSets"]["assemblies"][type]["address"].integer;

        TileAssembly[] assemblies = new TileAssembly[count];

        _rom.setPosition(address);
        uint[] pointers = new uint[count];
        foreach (const uint index, ref uint pointer; pointers) {
            pointer = _rom.read!ushort();
            const ubyte bank = _rom.read!ubyte();
            if (bank) {
                pointer = 0x10000 * (bank - 0xC0) + pointer;
            }
        }

        foreach (const int index, ref TileAssembly assembly; assemblies) {
            if (pointers[index]) {
                ubyte[] decompressed = new ubyte[0x2000];
                const uint length = decompressLZ(_rom.array, decompressed, pointers[index]);
                if (length) {
                    decompressed.length = length;
                    BinaryFile tileData = new BinaryFile(decompressed);
                    assembly = readAssembly(tileData);
                }
            }
        }

        return assemblies;
    }

    private TileAssembly readAssembly(BinaryFile tileData) {
        TileAssembly assembly;

        int count;
        if (tileData.size == 1) {
            count = 0;
        } else if (tileData.size % 8) {
            throw new Exception("Invalid tile assembly.");
        } else {
            count = tileData.size / 8;
        }
        
        assembly.tiles = new Tile[count];
        foreach (ref Tile tile; assembly.tiles) {
            foreach (ref TileChunk chunk; tile.chunks) {
                const ushort v = tileData.read!ushort();
                chunk.subTile = v & 0x3FF;
                chunk.subPalette = (v >> 10) & 0x7;
                chunk.flags |= (v & 0x2000) ? TileChunkFlags.PRIORITY : 0;
                chunk.flags |= (v & 0x4000) ? TileChunkFlags.FLIP_X : 0;
                chunk.flags |= (v & 0x8000) ? TileChunkFlags.FLIP_Y : 0;
            }
        }

        return assembly;
    }
}
