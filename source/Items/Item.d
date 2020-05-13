/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Items.Item;

import ElementTypes;
import StatusEffects;

public enum ItemFlags : ubyte {
    NONE           = 0x00,
    UNKNOWN_1      = 0x01,
    USABLE_IN_MENU = 0x02,
    CANT_SELL      = 0x04,
    QUEST_ITEM     = 0x08,
    NO_NEWGAMEPLUS = 0x10,
    UNKNOWN_2      = 0x20,
    UNKNOWN_3      = 0x40,
    USE_BATTLE     = 0x80,
}

public enum ItemEquippableFlags : ubyte {
    NONE    = 0x00,
    INVALID = 0x01,
    PC7     = 0x02,
    PC6     = 0x04,
    PC5     = 0x08,
    PC4     = 0x10,
    PC3     = 0x20,
    PC2     = 0x40,
    PC1     = 0x80,
}

public enum ItemType : ubyte {
    WEAPON,
    ARMOR,
    ACCESSORY,
    OTHER,
}

public enum ItemAccessoryFlags : ushort {
    NONE           = 0x0000,
    AFFECT_GOLD    = 0x0001,
    UNKNOWN_01     = 0x0002,
    UNKNOWN_02     = 0x0004,
    UNKNOWN_03     = 0x0008,
    UNKNOWN_04     = 0x0010,
    AFFECT_MP      = 0x0020,
    AFFECT_COUNTER = 0x0040,
    UNKNOWN_05     = 0x0080,
    UNKNOWN_06     = 0x0100,
    UNKNOWN_07     = 0x0200,
    UNKNOWN_08     = 0x0400,
    UNKNOWN_09     = 0x0800,
    AFFECT_HP      = 0x1000,
    UNKNOWN_10     = 0x2000,
    AFFECT_STATS   = 0x4000,
    AFFECT_STATUS  = 0x8000,
}

public enum ItemHealType : string {
    NONE        = "none",
    ABSOLUTE    = "absolute",
    FULL        = "full",
    RANDOM_FULL = "random_full",
}

public enum ItemConsumableFlags : ubyte {
    TARGET_ALL          = 0x01,
    REMOVE_ALL_STATUSES = 0x02,
    REVIVES             = 0x08,
    REQUIRE_SAVE_POINT  = 0x10,
}

public struct ItemWeapon {
    ubyte attack;
    double critChance;
    string mod;
    string palette;
    ubyte sound2;
    ubyte sound1;
}

public struct ItemArmor {
    ubyte defense;
    string mod;
}

public struct ItemAccessory {
    ItemAccessoryFlags flags;
    double counterChance;
    StatusEffect[] statuses;
    StatusEffect[] immunities;
}

public struct ItemConsumable {
    ItemHealType healTypeHealth;
    ItemHealType healTypeMagic;
    uint healHealth;
    uint healMagic;
    StatusEffect[] statuses;
    StatusEffect[] removeStatuses;
    ItemConsumableFlags flags;
}

public struct Item {
    public string key;
    public string name;
    public string description;

    public ItemType type;
    public ItemFlags flags;
    public int price;    
    public ItemEquippableFlags equippable;
    public string statMod;    

    public ElementType[] protection;
    public double protectionFactor;

    union {
        ItemWeapon weapon;
        ItemArmor armor;
        ItemAccessory accessory;
        ItemConsumable consumable;
    }

    public this(immutable ItemType type) {
        this.type = type;
    }
}
