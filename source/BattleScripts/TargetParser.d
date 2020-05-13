/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module BattleScripts.TargetParser;

import std.string;
import std.conv;

public enum TargetType : ubyte {
    NONE = 0x00,
    ALL_PLAYERS = 0x01,
    ALL_ENEMIES = 0x02,
    ENEMY_SELF = 0x03,
    ATTACKING_PLAYER = 0x04,
    RANDOM_PLAYER = 0x05,
    NEAREST_PLAYER = 0x06,
    FARTHEST_PLAYER = 0x07,
    PLAYER_LOWEST_HEALTH = 0x08,
    PLAYERS_ANY_0X1D_SET = 0x09,
    PLAYERS_NEGATIVE_STATUS = 0x0A,
    PLAYERS_ANY_0X1F_SET = 0x0B,
    PLAYERS_POSITIVE_STATUS_SET_1 = 0x0C,
    PLAYERS_POSITIVE_STATUS_SET_2 = 0x0D,
    PLAYERS_ASLEEP = 0x0E,
    PLAYERS_STOPPED = 0x0F,
    PLAYERS_CONFUSED = 0x10,
    PLAYERS_DEFENSE_UP = 0x11,
    PLAYERS_MAGIC_DEFENSE_UP = 0x12,
    PLAYERS_BIT10_POSITIVE_STATUS = 0x13,
    PLAYERS_BIT8_BATTLE_DATA_1 = 0x14,
    OTHER_ENEMIES = 0x15,
    LIVING_ENEMIES = 0x16,
    NEAREST_ENEMY = 0x17,
    FARTHEST_ENEMY = 0x18,
    ENEMY_LOWEST_HEALTH = 0x19,
    OTHER_ENEMIES_BATTLEDATA_0X1D = 0x1A,
    ALL_ENEMIES_BATTLEDATA_0X1D = 0x1B,
    OTHER_ENEMIES_NEGATIVE_STATUS = 0x1C,
    ALL_ENEMIES_NEGATIVE_STATUS = 0x1D,
    OTHER_ENEMIES_BATTLEDATA_0X1F = 0x1E,
    ALL_ENEMIES_BATTLEDATA_0X1F = 0x1F,
    OTHER_ENEMIES_ASLEEP = 0x20,
    OTHER_ENEMIES_STOPPED = 0x21,
    OTHER_ENEMIES_CONFUSED = 0x22,
    OTHER_ENEMIES_MAGIC_DEFENSE_UP = 0x23,
    OTHER_ENEMIES_0X1D_BIT2 = 0x24,
    OTHER_ENEMIES_0X19_BIT1 = 0x25,
    OTHER_ENEMY_LOWEST_HEALTH = 0x26,

    ENEMY_3 = 0x27,
    ENEMY_4 = 0x28,
    ENEMY_5 = 0x29,
    ENEMY_6 = 0x2A,
    ENEMY_7 = 0x2B,
    ENEMY_8 = 0x2C,
    ENEMY_9 = 0x2D,
    ENEMY_10 = 0x2E,

    RANDOM_ENEMY_0X7EAF15_BIT8 = 0x2F,
    PLAYER_1 = 0x30,
    PLAYER_2 = 0x31,
    PLAYER_3 = 0x32,

    ENEMY_3_1 = 0x33,
    ENEMY_4_2 = 0x34,
    ENEMY_5_3 = 0x35,
    ENEMY_6_4 = 0x36,

    PLAYER_MOST_HEALTH = 0x37,
    RANDOM_OTHER_ENEMY = 0x38,
}

public string parseTargetByte(immutable ubyte target) {
    if (target & 0x80) {
        return "COPY_ONLY";
    }
    return to!string(cast(TargetType)(target & 0x7F));
}
