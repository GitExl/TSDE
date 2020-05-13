module BattleScripts.StatParser;

import std.string;

public string parseStatByte(immutable ubyte stat) {
    switch (stat) {
        case 0x12: return "UNKNOWN_1";  // Mother Brain sets this to 6 in it's first idle action.
        case 0x29: return "WEAPON_INDEX";
        case 0x37: return "UNKNOWN_2";  // Maybe some sort of common variable? Used by Golem to remember the last attacked element for example.
        case 0x39: return "UNKNOWN_3";  // "Fire power"
        case 0x3B: return "UNKNOWN_4";  // Defense related (magic defense?)
        case 0x3C: return "DEFENSE_MAGIC";
        case 0x3D: return "ATTACK";
        case 0x3E: return "DEFENSE_PHYSICAL";
        case 0x3F: return "DEFENSE_LIGHTNING";
        case 0x40: return "DEFENSE_SHADOW";
        case 0x41: return "DEFENSE_WATER";
        case 0x42: return "DEFENSE_FIRE";

        default:
            throw new Exception(format("Unknown stat value 0x%02X", stat));
    }
}
