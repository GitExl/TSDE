module Enemies.Enemy;

import ElementTypes;
import StatusEffects;
import EnemyTypes;

public enum EnemyFlags : ubyte {
    NONE       = 0x00,
    HIDE_HP    = 0x02,
    BOSS_DEATH = 0x01,
}

public enum TechImmunityFlags : ubyte {
    NONE          = 0x00,
    AIRBORNE      = 0x02,
    PHYSICAL      = 0x04,
    SLURP_CUT     = 0x20,
    ROCK_THROW    = 0x40,
    HP_HALF_DEATH = 0x80,
}

public enum EnemySpriteFlags : ubyte {
    NONE      = 0x00,
    UNKNOWN_1 = 0x04,
    PRIMARY   = 0x08,
    UNKNOWN_3 = 0x10,
    UNKNOWN_4 = 0x20,
    UNKNOWN_5 = 0x40,
    UNKNOWN_6 = 0x80,
}

public struct EnemySprite {
    ubyte packet;
    ubyte assembly;
    ubyte palette;
    ubyte animations;
    ubyte size;
    byte originX;
    byte originY;
    ubyte unknown1;
    ubyte unknown2;
    ubyte unknown3;
    EnemySpriteFlags flags;
}

public struct Enemy {
    string name;
    string key;
    
    EnemyType type;
    ushort health;
    ubyte level;
    StatusEffect[] immunities;
    TechImmunityFlags techImmunities;
    ubyte stamina;
    ubyte speed;
    ubyte magic;
    ubyte hit;
    ubyte magicDefense;
    ubyte attackIndex;
    ubyte defense;
    double[ElementType] affinities;
    ubyte evade;
    EnemyFlags flags;
    ubyte attack2Index;
    bool hideTargetWindow;
    string battleAI;

    ubyte special1;
    ubyte special2;

    ushort xp;
    ushort gold;
    string rewardItem;
    string charmItem;
    ubyte techPoints;

    EnemySprite sprite;
}

