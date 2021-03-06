/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module StatusEffects;

public enum StatusEffect : string {
    SLEEP = "Sleep",
    PROTECT = "Protect",
    POISON = "Poison",
    HP_DRAIN = "HP drain",
    MP_REGEN = "MP regeneration",
    CHAOS = "Chaos",
    SLOW = "Slow",
    BARRIER = "Barrier",
    HASTE = "Haste",
    EVADE_2 = "Evade x2",
    EVADE_25 = "Evade x2.5",
    STOP = "Stop",
    TECH_LOCK = "Tech lock",
    CONFUSE = "Confuse",
    BLIND = "Blind",
    LOCK = "Lock",
    BERSERK = "Berserk",
    ATTACK_UP = "Attack up",
    SHIELD = "Shield",
    MAX_ATTACK_UP = "Max attack up",
    DEAD = "Dead",
    AUTO_REVIVE = "Auto revive",
}
