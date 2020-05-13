module TileSets.TileSet;

public enum TileSetType : ubyte {
    L12,
    L3,
}

public enum TileChunkFlags : ubyte {
    NONE     = 0x00,
    PRIORITY = 0x01,
    FLIP_X   = 0x02,
    FLIP_Y   = 0x04,
}

public struct TileChunk {
    ushort subTile;
    ubyte subPalette;
    TileChunkFlags flags;
}

public struct Tile {
    TileChunk[4] chunks;
}

public struct TileAssembly {
    Tile[] tiles;
}

public struct TileSet {
    string key;

    TileSetType type;
    string[] graphics;
    TileAssembly assembly;
}
