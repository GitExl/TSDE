/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Maps.Map;

public alias ushort TileIndex;

public enum TileFlags : ushort {
    NONE              = 0x000,
    LAYER1_SET2       = 0x001,
    LAYER2_SET2       = 0x002,
    DOOR              = 0x004,
    UNKNOWN           = 0x008,
    SPRITE_OVER_L1    = 0x010,
    SPRITE_OVER_L2    = 0x020,
    BATTLE_SOLID      = 0x040,
    IGNORE_Z_SOLIDITY = 0x080,
    Z_NEUTRAL         = 0x100,
    NPC_SOLID         = 0x200,
}

public enum ScreenFlags : ubyte {
    NONE     = 0x00,
    L1_MAIN  = 0x01,
    L2_MAIN  = 0x02,
    L3_MAIN  = 0x04,
    SPR_MAIN = 0x08,
    L1_SUB   = 0x10,
    L2_SUB   = 0x20,
    L3_SUB   = 0x40,
    SPR_SUB  = 0x80,
}

public enum SolidityType : ubyte {
    NONE,
    SOLID,
    CORNER,
    QUAD,
    STAIR,
    LADDER,
}

public enum SolidityCorner : ubyte {
    NONE         = 0x00,
    TOP_LEFT     = 0x01,
    TOP_RIGHT    = 0x02,
    BOTTOM_LEFT  = 0x04,
    BOTTOM_RIGHT = 0x08,
    ANGLE_45 = 0x10,
    ANGLE_30 = 0x20,
    ANGLE_22 = 0x40,
    ANGLE_75 = 0x80,
}

public enum SolidityQuad : ubyte {
    NONE         = 0x00,
    TOP_LEFT     = 0x01,
    TOP_RIGHT    = 0x02,
    BOTTOM_LEFT  = 0x04,
    BOTTOM_RIGHT = 0x08,
}

public enum SolidityStairs : ubyte {
    SW_TO_NE,
    SE_TO_NW,
}

public enum MapEffectType : ubyte {
    ADD,
    SUBTRACT,
}

public enum MapEffectFlags : ubyte {
    NONE           = 0x00,
    LAYER1         = 0x01,
    LAYER2         = 0x02,
    LAYER3         = 0x04,
    SPRITES        = 0x08,
    DEFAULT_COLOR  = 0x10,
    HALF_INTENSITY = 0x20,
}

public struct TileProps {
    TileFlags flags;
    ubyte zPlane;

    SolidityType solidity;
    union {
        SolidityCorner corner;
        SolidityQuad quad;
        SolidityStairs stairs;
    }
    ubyte solidityMod;

    ubyte movement;
    ubyte movementSpeed;
}

public struct MapLayer {
    ushort width;
    ushort height;
    ubyte scroll;
    TileIndex[] tiles;
}

public struct Map {
    string key;

    MapLayer[3] layers;
    TileProps[] tileProps;
    bool hasL3;

    ScreenFlags screenFlags;
    MapEffectFlags effectFlags;
    MapEffectType effectType;    
}
