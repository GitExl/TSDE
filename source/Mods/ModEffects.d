module Mods.ModEffects;

import std.conv;
import std.string;
import std.json;

import Mods.ModEffectInterface;

import ArrayTools;

import ElementTypes;
import StatusEffects;

public class ModEffectCritFactor : ModEffectInterface {
    private double _factor;

    public this(immutable double factor) {
        _factor = factor;
    }

    public const string name() {
        return "critFactor";
    }

    public const string description() {
        return format("%d%% critical hit factor", cast(int)(_factor * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_factor);
    }
}

public class ModEffectDamageFactor : ModEffectInterface {
    private double _factor;

    public this(immutable double factor) {
        _factor = factor;
    }

    public const string name() {
        return "damageFactor";
    }

    public const string description() {
        return format("%d%% damage factor", cast(int)(_factor * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_factor);
    }
}

public class ModEffectHealthDigit2RandomDamage : ModEffectInterface {
    public const string name() {
        return "healthDigit2RandomDamage";
    }

    public const string description() {
        return "Random damage based on second HP digit";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModEffectMagical : ModEffectInterface {
    public const string name() {
        return "magical";
    }

    public const string description() {
        return "Is magical";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModEffectMagicFactor : ModEffectInterface {
    private double _factor;

    public this(immutable double factor) {
        _factor = factor;
    }

    public const string name() {
        return "magicFactor";
    }

    public const string description() {
        return format("%d%% magic factor", cast(int)(_factor * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_factor);
    }
}

public class ModEffectMagicDamageFactor : ModEffectInterface {
    private double _factor;

    public this(immutable double factor) {
        _factor = factor;
    }

    public const string name() {
        return "magicDamageFactor";
    }

    public const string description() {
        return format("%d%% magic damage factor", cast(int)(_factor * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_factor);
    }
}

public class ModEffectReduceHealthAbsoluteChance : ModEffectInterface {
    private double _chance;
    private uint _health;

    public this(immutable double chance, immutable uint health) {
        _chance = chance;
        _health = health;
    }

    public const string name() {
        return "reduceHealthAbsoluteChance";
    }

    public const string description() {
        return format("%d%% chance to reduce health to %d", cast(int)(_chance * 100), _health);
    }

    public const JSONValue serialize() {
        JSONValue value;
        value["chance"] = _chance;
        value["health"] = _health;
        return value;
    }
}

public class ModEffectCharmChance : ModEffectInterface {
    private double _chance;

    public this(immutable double chance) {
        _chance = chance;
    }

    public const string name() {
        return "charmChance";
    }

    public const string description() {
        return format("%d%% charm chance", cast(int)(_chance * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_chance);
    }
}

public class ModEffectRemoveAllStatuses : ModEffectInterface {
    public const string name() {
        return "removeAllStatuses";
    }

    public const string description() {
        return "Remove all statuses";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModEffectRemoveStatuses : ModEffectInterface {
    private StatusEffect[] _statuses;

    public this(immutable StatusEffect[] statuses) {
        _statuses = statuses.dup;
    }

    public const string name() {
        return "removeStatuses";
    }

    public const string description() {
        string[] parts = enumStringValues!StatusEffect(_statuses);
        return format("Remove statuses: %s", parts.join(", "));
    }

    public const JSONValue serialize() {
        return JSONValue(enumStringKeys!StatusEffect(_statuses));
    }
}

public class ModEffectDeadAllyDamageMultiplier : ModEffectInterface {
    private double _damageFactor;

    public this(immutable double damageFactor) {
        _damageFactor = damageFactor;
    }
    
    public const string name() {
        return "deadAllyDamageMultiplier";
    }

    public const string description() {
        return format("%d%% additional damage per dead ally", cast(int)(_damageFactor * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_damageFactor);
    }
}

public class ModEffectHalfHealthDamageChance : ModEffectInterface {
    private double _chance;

    public this(immutable double chance) {
        _chance = chance;
    }

    public const string name() {
        return "halfHealthDamageChance";
    }

    public const string description() {
        return format("%d%% chance to deal half HP damage", cast(int)(_chance * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_chance);
    }
}

public class ModEffectLastHealthDigitDamageDivisor : ModEffectInterface {
    private uint _divisor;

    public this(immutable uint divisor) {
        _divisor = divisor;
    }

    public const string name() {
        return "lastHealthDigitDamageDivisor";
    }

    public const string description() {
        return format("Last HP digit damage divisor %d", _divisor);
    }

    public const JSONValue serialize() {
        return JSONValue(_divisor);
    }
}

public class ModEffectDeathChance : ModEffectInterface {
    private double _chance;
    private bool _ignoreImmunities;

    public this(immutable double chance, immutable bool ignoreImmunities) {
        _chance = chance;
        _ignoreImmunities = ignoreImmunities;
    }

    public const string name() {
        return "deathChance";
    }

    public const string description() {
        if (_ignoreImmunities) {
            return format("%d%% chance to die, ignoring immunities", cast(int)(_chance * 100));
        } else {
            return format("%d%% chance to die", cast(int)(_chance * 100));
        }
    }

    public const JSONValue serialize() {
        JSONValue value;
        value["chance"] = _chance;
        value["ignoreImmunities"] = _ignoreImmunities;
        return value;
    }
}

public class ModEffectInflictStatusChances : ModEffectInterface {
    private double[StatusEffect] _chances;

    public this(double[StatusEffect] chances) {
        _chances = chances.dup;
    }

    public const string name() {
        return "inflictStatusChances";
    }

    public const string description() {
        string[] parts;
        foreach (StatusEffect effect, double chance; _chances) {
            parts ~= format("%d%% chance to inflict %s", cast(int)(chance * 100), cast(string)effect);
        }

        return parts.join(", ");
    }

    public const JSONValue serialize() {
        double[string] chances;
        foreach (StatusEffect effect, double value; _chances) {
            chances[to!string(effect)] = value;
        }

        return JSONValue(chances);
    }
}

public class ModEffectInflictRandomStatusChance : ModEffectInterface {
    private double _chance;

    public this(double chance) {
        _chance = chance;
    }

    public const string name() {
        return "inflictRandomStatusChance";
    }

    public const string description() {
        return format("%d%% chance to inflict a random status", cast(int)(_chance * 100));
    }

    public const JSONValue serialize() {
        return JSONValue(_chance);
    }
}

public class ModEffectRemoveAllImmunities : ModEffectInterface {
    public const string name() {
        return "removeAllImmunities";
    }

    public const string description() {
        return "Remove all immunities";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModEffectGetAllImmunities : ModEffectInterface {
    public const string name() {
        return "getAllImmunities";
    }

    public const string description() {
        return "Get all immunities";
    }

    public const JSONValue serialize() {
        return JSONValue(true);
    }
}

public class ModEffectGetImmunities : ModEffectInterface {
    private StatusEffect[] _immunities;

    public this(immutable StatusEffect[] immunities) {
        _immunities = immunities.dup;
    }

    public const string name() {
        return "getImmunities";
    }

    public const string description() {
        string[] parts = enumStringValues!StatusEffect(_immunities);
        return format("Get immunities: %s", parts.join(", "));
    }

    public const JSONValue serialize() {
        return JSONValue(enumStringKeys!StatusEffect(_immunities));
    }
}

public class ModEffectRemoveImmunities : ModEffectInterface {
    private StatusEffect[] _immunities;

    public this(immutable StatusEffect[] immunities) {
        _immunities = immunities.dup;
    }

    public const string name() {
        return "removeImmunities";
    }

    public const string description() {
        string[] parts = enumStringValues!StatusEffect(_immunities);
        return format("Remove immunities: %s", parts.join(", "));
    }

    public const JSONValue serialize() {
        return JSONValue(enumStringKeys!StatusEffect(_immunities));
    }
}

public class ModEffectCritDamageAbsolute : ModEffectInterface {
    private uint _damage;

    public this(immutable uint damage) {
        _damage = damage;
    }

    public const string name() {
        return "critDamageAbsolute";
    }

    public const string description() {
        return format("Always crit with %d damage", _damage);
    }

    public const JSONValue serialize() {
        return JSONValue(_damage);
    }
}

public class ModEffectAffinities : ModEffectInterface {
    private double[ElementType] _affinities;

    public this(double[ElementType] affinities) {
        _affinities = affinities.dup;
    }

    public const string name() {
        return "affinities";
    }

    public const string description() {
        string[] parts;
        foreach (ElementType element, double affinity; _affinities) {
            parts ~= format("%d%% %s affinity", cast(int)(affinity * 100), cast(string)element);
        }

        return parts.join(", ");
    }

    public const JSONValue serialize() {
        double[string] affinities;
        foreach (ElementType elementType, double value; _affinities) {
            affinities[to!string(elementType)] = value;
        }

        return JSONValue(affinities);
    }
}

public class ModEffectGetStatuses : ModEffectInterface {
    private StatusEffect[] _statuses;

    public this(immutable StatusEffect[] statuses) {
        _statuses = statuses.dup;
    }

    public const string name() {
        return "getStatuses";
    }

    public const string description() {
        string[] parts = enumStringValues!StatusEffect(_statuses);
        return format("Get statuses: %s", parts.join(", "));
    }

    public const JSONValue serialize() {
        return JSONValue(enumStringKeys!StatusEffect(_statuses));
    }
}

public class ModEffectDamageAbsolute : ModEffectInterface {
    private uint _damage;

    public this(immutable uint damage) {
        _damage = damage;
    }

    public const string name() {
        return "damageAbsolute";
    }

    public const string description() {
        return format("Always do %d damage", _damage);
    }

    public const JSONValue serialize() {
        return JSONValue(_damage);
    }
}
