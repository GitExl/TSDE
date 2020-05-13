/**
 * Time Switch Data Extractor version 1.0  Copyright (C) 2020
 *
 * This program comes with ABSOLUTELY NO WARRANTY.
 * This is free software, and you are welcome to redistribute it under
 * certain conditions, see the accompanying COPYING file.
 */

module Mods.ROMModReader;

import std.json;
import std.string;

import List.ListReaderInterface;

import Mods.Mod;
import Mods.ModEffects;
import Mods.ModEffectInterface;
import Mods.ModConditions;
import Mods.ModConditionInterface;

import StatusEffects;
import EnemyTypes;
import ElementTypes;
import BinaryFile;

public class ROMModReader : ListReaderInterface!Mod {

    private JSONValue _config;
    private BinaryFile _rom;

    public this (JSONValue config, BinaryFile rom) {
        _config = config;
        _rom = rom;
    }

    public Mod[] read() {
        immutable uint count = cast(uint)_config["mods"]["count"].integer;
        immutable uint address = cast(uint)_config["mods"]["address"].integer;

        Mod[] mods = new Mod[count];

        _rom.setPosition(address);
        foreach (int index, ref Mod mod; mods) {
            immutable ubyte[3] data = _rom.readBytes(3);

            switch (data[0]) {
                case 0: mod.effects ~= new ModEffectCritFactor(cast(double)data[2] / 10.0); break;
                case 2: mod.effects ~= new ModEffectDamageFactor(cast(double)data[1] / cast(double)data[2]); break;
                case 3:
                    mod.conditions = getConditions(data[1]);
                    mod.effects ~= new ModEffectDamageFactor(cast(double)data[2] / 2.0);
                    break;
                case 4: mod.effects ~= new ModEffectDeadAllyDamageMultiplier(1); break;
                case 5: mod.effects ~= new ModEffectHealthDigit2RandomDamage(); break;
                case 6: mod.effects ~= new ModEffectInflictRandomStatusChance(1.0); break;

                case 7:
                    StatusEffect[] effects = getStatusEffects(data[2]);
                    double[StatusEffect] effectChances;
                    foreach (StatusEffect effect; effects) {
                        effectChances[effect] = 0.8;
                    }
                    mod.conditions = getConditions(data[1]);
                    mod.effects ~= new ModEffectInflictStatusChances(effectChances);
                    break;
                case 8:
                    StatusEffect[] effects = getStatusEffects(data[2]);
                    double[StatusEffect] effectChances;
                    foreach (StatusEffect effect; effects) {
                        effectChances[effect] = cast(double)data[1] / 100.0;
                    }
                    mod.effects ~= new ModEffectInflictStatusChances(effectChances);
                    break;

                case 9: mod.effects ~= new ModEffectReduceHealthAbsoluteChance(cast(double)data[1] / 100.0, 1); break;
                case 10: mod.effects ~= new ModEffectMagical(); break;
                case 11: mod.effects ~= new ModEffectMagicDamageFactor(cast(double)data[1] / cast(double)data[2]); break;
                case 12: mod.effects ~= new ModEffectCharmChance(cast(double)data[1] / 100.0); break;
                case 13:
                    if (data[1] & 0x40) {
                        mod.effects ~= new ModEffectRemoveAllStatuses();
                    }
                    if (data[1] & 0x80) {
                        mod.effects ~= new ModEffectDamageAbsolute(9999);
                    }
                    break;
                case 14: mod.effects ~= new ModEffectHalfHealthDamageChance(cast(double)data[1] / 100.0); break;

                case 15:
                    if (data[1] == 30) {
                        mod.effects ~= new ModEffectRemoveStatuses(getStatusEffects(data[2]).idup); break;
                    } else if (data[1] == 32) {
                        mod.effects ~= new ModEffectRemoveStatuses(getStatusEffects2(data[2]).idup); break;
                    } else if (data[1] == 33) {
                        mod.effects ~= new ModEffectRemoveStatuses(getStatusEffects3(data[2]).idup); break;
                    } else if (data[1] == 35) {
                        mod.effects ~= new ModEffectRemoveImmunities(getStatusEffects(data[2]).idup); break;
                    }
                    break;
                case 16: mod.effects ~= new ModEffectLastHealthDigitDamageDivisor(cast(double)data[2]); break;
                case 17: mod.effects ~= new ModEffectDeathChance(1.0, true); break;
                case 18: mod.effects ~= new ModEffectDeathChance(cast(double)data[1] / 100.0, false); break;
                case 19:
                    if (data[2]) {
                        mod.effects ~= new ModEffectCritDamageAbsolute(9999);
                    } else {
                        mod.effects ~= new ModEffectCritFactor(4);
                    }
                     break;

                case 20:
                    if (data[1] == 30) {
                        mod.effects ~= new ModEffectGetStatuses(getStatusEffects(data[2]).idup); break;
                    } else if (data[1] == 32) {
                        mod.effects ~= new ModEffectGetStatuses(getStatusEffects2(data[2]).idup); break;
                    } else if (data[1] == 33) {
                        mod.effects ~= new ModEffectGetStatuses(getStatusEffects3(data[2]).idup); break;
                    } else if (data[1] == 35) {
                        mod.effects ~= new ModEffectGetImmunities(getStatusEffects(data[2]).idup); break;
                    }
                    break;

                case 30: mod.effects ~= new ModEffectGetStatuses(getStatusEffects(data[1]).idup); break;
                case 35: mod.effects ~= new ModEffectGetImmunities(getStatusEffects(data[1]).idup); break;
                case 37: mod.effects ~= new ModEffectGetStatuses(getStatusEffects2(data[1]).idup); break;
                case 38: mod.effects ~= new ModEffectGetStatuses(getStatusEffects3(data[1]).idup); break;

                case 63: mod.effects ~= new ModEffectAffinities([ElementType.LIGHTNING: getAffinityFactor(data[1])]); break;
                case 64: mod.effects ~= new ModEffectAffinities([ElementType.SHADOW: getAffinityFactor(data[1])]); break;
                case 65: mod.effects ~= new ModEffectAffinities([ElementType.WATER: getAffinityFactor(data[1])]); break;
                case 66: mod.effects ~= new ModEffectAffinities([ElementType.FIRE: getAffinityFactor(data[1])]); break;

                default:
                    throw new Exception(format("Unknown mod effect %d.", data[0]));
            }

            mod.key = format("%03d_mod", index);
            if (mod.effects.length) {
                string[] effectParts;
                foreach (ModEffectInterface effect; mod.effects) {
                    effectParts ~= effect.description();
                }

                string[] conditionParts;
                foreach (ModConditionInterface condition; mod.conditions) {
                    conditionParts ~= condition.description();
                }

                if (conditionParts.length) {
                    mod.name = format("%s when %s", effectParts.join(" and "), conditionParts.join(" and "));
                } else {
                    mod.name = effectParts.join(" and ");
                }
            }
        }

        return mods;
    }

    private const StatusEffect[] getStatusEffects(immutable ubyte flags) {
        StatusEffect[] effects;

        if (flags & 0x01) {
          effects ~= StatusEffect.BLIND;
        }
        if (flags & 0x02) {
          effects ~= StatusEffect.SLEEP;
        }
        if (flags & 0x04) {
          effects ~= StatusEffect.CONFUSE;
        }
        if (flags & 0x08) {
          effects ~= StatusEffect.LOCK;
        }
        if (flags & 0x10) {
          effects ~= StatusEffect.HP_DRAIN;
        }
        if (flags & 0x20) {
          effects ~= StatusEffect.SLOW;
        }
        if (flags & 0x40) {
          effects ~= StatusEffect.POISON;
        }
        if (flags & 0x80) {
          effects ~= StatusEffect.STOP;
        }

        return effects;
    }

    private const StatusEffect[] getStatusEffects2(immutable ubyte flags) {
        StatusEffect[] effects;

        if (flags & 0x01) {
            effects ~= StatusEffect.EVADE_2;
        }
        if (flags & 0x40) {
            effects ~= StatusEffect.EVADE_25;
        }
        if (flags & 0x80) {
            effects ~= StatusEffect.HASTE;
        }

        return effects;
    }

    private const StatusEffect[] getStatusEffects3(immutable ubyte flags) {
        StatusEffect[] effects;

        if (flags & 0x02) {
          effects ~= StatusEffect.ATTACK_UP;
        }
        if (flags & 0x04) {
          effects ~= StatusEffect.SHIELD;
        }
        if (flags & 0x08) {
          effects ~= StatusEffect.MAX_ATTACK_UP;
        }
        if (flags & 0x20) {
          effects ~= StatusEffect.MP_REGEN;
        }
        if (flags & 0x40) {
          effects ~= StatusEffect.BARRIER;
        }
        if (flags & 0x80) {
          effects ~= StatusEffect.BERSERK;
        }

        return effects;
    }

    private const double getAffinityFactor(immutable ubyte value) {
        return 2.0 - (cast(int)value & 63 | 4) / 4.0;
    }

    private const ModConditionInterface[] getConditions(immutable ubyte flags) {
        ModConditionInterface[] conditions;

        if (flags & 0x01) {
            conditions ~= new ModConditionBossDeath();
        }
        if (flags & 0x02) {
            conditions ~= new ModConditionSightScopeRelicFail();
        }
        if (flags & 0x08) {
            conditions ~= new ModConditionEnemyType(EnemyType.MAGICAL);
        }
        if (flags & 0x10) {
            conditions ~= new ModConditionEnemyType(EnemyType.AQUATIC);
        }
        if (flags & 0x20) {
            conditions ~= new ModConditionEnemyType(EnemyType.HUMANOID);
        }
        if (flags & 0x40) {
            conditions ~= new ModConditionEnemyType(EnemyType.MECHANICAL);
        }
        if (flags & 0x80) {
            conditions ~= new ModConditionEnemyType(EnemyType.UNDEAD);
        }

        return conditions;
    }
}