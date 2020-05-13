module Maps.ROMMapReader;

import std.stdio;
import std.json;
import std.algorithm;
import std.string;

import Maps.Map;

import List.ListReaderInterface;

import BinaryFile;
import Decompress;

public class ROMMapReader : ListReaderInterface!Map {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public Map[] read() {
        immutable uint count = cast(uint)_config["maps"]["count"].integer;
        immutable uint address = cast(uint)_config["maps"]["address"].integer;

        Map[] maps = new Map[count];

        _rom.setPosition(address);
        uint[] pointers = new uint[count];
        foreach (ref uint pointer; pointers) {
            pointer = _rom.read!ushort();
            const ubyte bank = _rom.read!ubyte();
            if (bank) {
                pointer = 0x10000 * (bank - 0xC0) + pointer;
            }
        }

        foreach (const int index, ref Map map; maps) {
            if (pointers[index]) {
                ubyte[] decompressed = new ubyte[0x8888];
                const uint length = decompressLZ(_rom.array, decompressed, pointers[index]);
                if (length) {
                    decompressed.length = length;
                    BinaryFile mapData = new BinaryFile(decompressed);
                    map = readMap(mapData);
                }
            }

            map.key = format("%03d_map", index);
        }

        return maps;
    }

    private Map readMap(BinaryFile data) {
        Map map;

        const ubyte l12 = data.read!ubyte();
        map.layers[0].width  = ((l12 >> 0) & 0x3) * 16 + 16;
        map.layers[0].height = ((l12 >> 2) & 0x3) * 16 + 16;
        map.layers[1].width  = ((l12 >> 4) & 0x3) * 16 + 16;
        map.layers[1].height = ((l12 >> 6) & 0x3) * 16 + 16;

        const ubyte l3 = data.read!ubyte();
        map.layers[2].width  = ((l3 >> 0) & 0x3) * 16 + 16;
        map.layers[2].height = ((l3 >> 2) & 0x3) * 16 + 16;
        map.layers[0].scroll = (l3 & 0x70) >> 4;
        map.hasL3 = cast(bool)(l3 & 0x80);

        map.layers[1].scroll = data.read!ubyte();
        map.layers[2].scroll = data.read!ubyte();

        const ubyte mainSub = data.read!ubyte();
        map.screenFlags |= (mainSub & 0x01) ? ScreenFlags.L1_MAIN : 0;
        map.screenFlags |= (mainSub & 0x02) ? ScreenFlags.L2_MAIN : 0;
        map.screenFlags |= (mainSub & 0x04) ? ScreenFlags.L3_MAIN : 0;
        map.screenFlags |= (mainSub & 0x08) ? ScreenFlags.SPR_MAIN : 0;
        map.screenFlags |= (mainSub & 0x10) ? ScreenFlags.L1_SUB : 0;
        map.screenFlags |= (mainSub & 0x20) ? ScreenFlags.L2_SUB : 0;
        map.screenFlags |= (mainSub & 0x40) ? ScreenFlags.L3_SUB : 0;
        map.screenFlags |= (mainSub & 0x80) ? ScreenFlags.SPR_SUB : 0;

        const ubyte enabled = data.read!ubyte();
        map.effectFlags |= (enabled & 0x01) ? MapEffectFlags.LAYER1 : 0;
        map.effectFlags |= (enabled & 0x02) ? MapEffectFlags.LAYER2 : 0;
        map.effectFlags |= (enabled & 0x04) ? MapEffectFlags.LAYER3 : 0;
        map.effectFlags |= (enabled & 0x10) ? MapEffectFlags.SPRITES : 0;
        map.effectFlags |= (enabled & 0x20) ? MapEffectFlags.DEFAULT_COLOR: 0;
        map.effectFlags |= (enabled & 0x40) ? MapEffectFlags.HALF_INTENSITY: 0;
        map.effectType = cast(MapEffectType)(enabled & 0x80);

        map.layers[0].tiles = readTiles(data, map.layers[0].width, map.layers[0].height);
        map.layers[1].tiles = readTiles(data, map.layers[1].width, map.layers[1].height);
        if (map.hasL3) {
            map.layers[2].tiles = readTiles(data, map.layers[2].width, map.layers[2].height);
        }

        map.tileProps = readTileProps(map, data);

        return map;
    }

    private TileIndex[] readTiles(BinaryFile data, immutable uint width, immutable uint height) {
        TileIndex[] tiles = new TileIndex[width * height];
        foreach (ref TileIndex tile; tiles) {
            tile = data.read!ubyte();
        }
        return tiles;
    }

    private TileProps[] readTileProps(Map map, BinaryFile data) {
        const ushort maxWidth = max(map.layers[0].width, map.layers[1].width, map.layers[2].width);
        const ushort maxHeight = max(map.layers[0].height, map.layers[1].height, map.layers[2].height);
        const uint propSize = 3 * maxWidth * maxHeight;

        ubyte[] decompressed = new ubyte[propSize];
        decompressTileProps(data.array, decompressed, data.getPosition(), propSize);
        BinaryFile propData = new BinaryFile(decompressed);

        TileProps[] tileProps = new TileProps[maxWidth * maxHeight];
        foreach (ref TileProps props; tileProps) {
            const ubyte v0 = propData.read!ubyte();
            props.flags |= (v0 & 0x01) ? TileFlags.LAYER1_SET2 : 0;
            props.flags |= (v0 & 0x02) ? TileFlags.LAYER2_SET2 : 0;
            const ubyte solidity = (v0 >> 2) & 0x3F;

            const ubyte v1 = propData.read!ubyte();
            props.movement = (v1 & 0x3);
            props.movementSpeed = (v1 >> 2) & 0x3;
            props.flags |= (v1 & 0x10) ? TileFlags.DOOR : 0;
            props.flags |= (v1 & 0x20) ? TileFlags.UNKNOWN : 0;
            props.flags |= (v1 & 0x40) ? TileFlags.SPRITE_OVER_L1 : 0;
            props.flags |= (v1 & 0x80) ? TileFlags.BATTLE_SOLID : 0;

            const ubyte v2 = propData.read!ubyte();
            props.zPlane = (v2 & 0x3);
            props.flags |= (v2 & 0x4) ? TileFlags.IGNORE_Z_SOLIDITY : 0;
            props.solidityMod = (v2 >> 3) & 0x3;
            props.flags |= (v2 & 0x20) ? TileFlags.Z_NEUTRAL : 0;
            props.flags |= (v2 & 0x40) ? TileFlags.SPRITE_OVER_L2 : 0;
            props.flags |= (v2 & 0x80) ? TileFlags.NPC_SOLID : 0;

            props = parseSolidity(props, solidity);
        }

        return tileProps;
    }

    private TileProps parseSolidity(TileProps props, const ubyte solidity) {
        
        // 4,      SOLID                          00000100
        //
        // 94,     STAIR SW TO NE                 01011110
        // 95,     STAIR SE TO NW                 01011111
        //
        // 96,     NW, SW                         01100000
        // 100,    NW, NE                         01100100
        // 104,    SW                             01101000
        // 108,    SE                             01101100
        // 112,    NE                             01110000
        // 116,    NW                             01110100
        //
        // 120,    LADDER                         01111000
        //
        // 524384, NE, SE       00001000 00000000 01100000
        // 524388, SW, SE       00001000 00000000 01100100
        // 524392, NW, NE, SE   00001000 00000000 01101000
        // 524396, NW, NE, SW   00001000 00000000 01101100
        // 524400, NW, SW, SE   00001000 00000000 01110000
        // 524404, NE, SW, SE   00001000 00000000 01110100

        if (!solidity) {
            props.solidity = SolidityType.NONE;

        } else if (solidity == 4) {
            props.solidity = SolidityType.SOLID;

        } else if (solidity < 88) {
            props.solidity = SolidityType.CORNER;

            const uint corner = (solidity >> 2) - 2;
            if (props.solidityMod & 0x2) {
                switch (corner & 0x3) {
                    case 0: props.corner |= SolidityCorner.TOP_LEFT; break;
                    case 1: props.corner |= SolidityCorner.TOP_RIGHT; break;
                    case 2: props.corner |= SolidityCorner.BOTTOM_LEFT; break;
                    case 3: props.corner |= SolidityCorner.BOTTOM_RIGHT; break;
                    default:
                        throw new Exception("Invalid tile corner solidity property.");
                }
            } else {
                switch (corner & 0x3) {
                    case 3: props.corner |= SolidityCorner.TOP_LEFT; break;
                    case 2: props.corner |= SolidityCorner.TOP_RIGHT; break;
                    case 1: props.corner |= SolidityCorner.BOTTOM_LEFT; break;
                    case 0: props.corner |= SolidityCorner.BOTTOM_RIGHT; break;
                    default:
                        throw new Exception("Invalid tile corner solidity property.");
                }
            }

            const uint angle = corner >> 2;
            switch (angle & 0x3) {
                case 0: props.corner |= SolidityCorner.ANGLE_45; break;
                case 1: props.corner |= SolidityCorner.ANGLE_30; break;
                case 2: props.corner |= SolidityCorner.ANGLE_22; break;
                case 3: props.corner |= SolidityCorner.ANGLE_75; break;
                default:
                    throw new Exception("Invalid tile angle solidity property.");
            }

        } else if (solidity < 96) {
            props.solidity = SolidityType.STAIR;

            switch ((solidity >> 2) - 22) {
                case 0: props.stairs = SolidityStairs.SW_TO_NE; break;
                case 1: props.stairs = SolidityStairs.SE_TO_NW; break;
                default:
                    throw new Exception("Invalid tile stairs solidity property.");
            }

        } else if (solidity < 120) {
            props.solidity = SolidityType.QUAD;

            switch (solidity) {
                case 96:  props.quad = cast(SolidityQuad)(SolidityQuad.TOP_LEFT | SolidityQuad.BOTTOM_LEFT); break;
                case 100: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_LEFT | SolidityQuad.TOP_RIGHT); break;
                case 104: props.quad = cast(SolidityQuad)(SolidityQuad.BOTTOM_LEFT); break;
                case 108: props.quad = cast(SolidityQuad)(SolidityQuad.BOTTOM_RIGHT); break;
                case 112: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_RIGHT); break;
                case 116: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_LEFT); break;

                case 524384: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_RIGHT   | SolidityQuad.BOTTOM_RIGHT); break;
                case 524388: props.quad = cast(SolidityQuad)(SolidityQuad.BOTTOM_LEFT | SolidityQuad.BOTTOM_RIGHT); break;
                case 524392: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_LEFT    | SolidityQuad.TOP_RIGHT    | SolidityQuad.BOTTOM_LEFT); break;
                case 524396: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_RIGHT   | SolidityQuad.TOP_LEFT     | SolidityQuad.BOTTOM_LEFT); break;
                case 524400: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_RIGHT   | SolidityQuad.BOTTOM_LEFT  | SolidityQuad.BOTTOM_RIGHT); break;
                case 524404: props.quad = cast(SolidityQuad)(SolidityQuad.TOP_LEFT    | SolidityQuad.BOTTOM_LEFT  | SolidityQuad.BOTTOM_RIGHT); break;

                default:
                    throw new Exception("Invalid tile quad solidity property.");
            }

        } else if (solidity == 120) {
            props.solidity = SolidityType.LADDER;

        } else {
            throw new Exception("Invalid tile solidity property.");

        }

        return props;
    }

    private void decompressTileProps(ubyte[] srcBuffer, ubyte[] destBuffer, const uint srcOffset, const uint decompressedSize) {
        uint src = srcOffset;
        uint target = 0;

        while (target < decompressedSize && src < srcBuffer.length) {
            if ((srcBuffer[src] & 128) == 128) {
                ubyte[3] data = srcBuffer[src..src + 3];
                data[0] &= 127;
            
                const uint repeat = srcBuffer[src + 3] ? srcBuffer[src + 3] : 256;
                for (int index = 0; index < repeat; index++) {
                    destBuffer[target..target + 3] = data;
                    target += 3;
                }
                src += 4;

            } else {
                destBuffer[target..target + 3] = srcBuffer[src..src + 3];
                target += 3;
                src += 3;

            }
        }
    }

}
